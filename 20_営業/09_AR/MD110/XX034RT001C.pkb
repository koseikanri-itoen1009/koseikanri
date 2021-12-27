create or replace PACKAGE BODY XX034RT001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name     : XX034RT001C(body)
 * Description      : 承認済部門入力データをARAPI、AR標準I/Fに転送後、部門入力転送日を更新する
 * MD.050           : 部門入力バッチ処理(AR)   OCSJ/BFAFIN/MD050/F702
 * MD.070           : 承認済請求依頼の転送     OCSJ/BFAFIN/MD070/F702
 * Version          : 11.5.10.2.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_approval_slip_data 経理承認済仕入先請求書データの取得 (A-1)
 *  ar_api_for_deposit     ARAPIの更新［前受金］  (A-2)
 *  ins_ar_if_for_cancel   ARAPIの更新［伝票取消］(A-2)
 *  ar_if_invoice_set      IFテーブル型変数へ格納［請求依頼］(A-2)
 *  ar_if_for_invoice      IFテーブルへ挿入      ［請求依頼］(A-2)
 *  upd_slip_data          AR転送済請求依頼データの更新 (A-3)
 *  msg_output             結果出力
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2005/02/18   1.0            main新規作成
 *  2005/03/02   1.1            内税フラグ対応
 *  2005/03/09   1.2            不具合対応
 *  2005/08/26   11.5.10.1.4    伝票入力者にセットする値を従業員番号から
 *                              ユーザー名に変更。
 *  2005/09/29   11.5.10.1.5    部門入力のヘッダーの備考がEBS標準側へ
 *                              連携されていない不具合の対応
 *  2005/12/02   11.5.10.1.6    パフォーマンス対応によりSQL変更
 *  2006/01/19   11.5.10.1.6B   マルチオルグ対応漏れの修正
 *  2006/04/19   11.5.10.2.2    EBS取込時のソート順に対応するように前ゼロ追加
 *  2006/04/28   11.5.10.2.2B   取消伝票時の取消元伝票検索条件の誤り
 *  2006/07/23   11.5.10.2.4    11.5.10.2.2Bにて修正した取消元伝票取得条件変更で
 *                              11.5.10.2.2修正前に転送されている前ゼロ無しデータとの
 *                              判定が考慮されていないことの対応
 *  2007/11/26   11.5.10.2.10   データ転送と転送済フラグ更新タイミングの修正
 *  2021/12/17   11.5.10.2.11   [E_本稼働_17678]対応 電子帳簿保存法改正対応
 *
 *****************************************************************************************/
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  -- *** グローバル定数 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';     -- 結果出力用日付形式1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';                -- 結果出力用日付形式2
  cv_appr_status      CONSTANT  xx03_payment_slips.wf_status%TYPE := '80';  -- 経理承認済ステータス
--
  cv_prof_GL_ID       CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID';         -- 会計帳簿IDの取得用キー値
  cv_prof_ORG_ID      CONSTANT VARCHAR2(20)  := 'ORG_ID';                   -- オルグIDの取得用キー値
  cv_prof_AFF_CAT     CONSTANT VARCHAR2(50)  := 'XX03_AR_INVOICE_ENTRY_CONTEXT';             -- 明細FFコンテキストの取得用キー値
  cv_prof_ATT_1       CONSTANT VARCHAR2(50)  := 'XX03_AR_INVOICE_LINE_ATTRIBUTE1_BLANK_MK';  -- 明細備考欄が空白時の設定値
  cv_prof_ATT_3       CONSTANT VARCHAR2(50)  := 'XX03_AR_INVOICE_LINE_ATTRIBUTE3_BLANK_MK';  -- 明細納品書番号欄が空白時の設定値
  cv_slip_type_INV    CONSTANT VARCHAR2(20)  := 'INV';                      -- 伝票種別：請求伝票
  cv_slip_type_DEP    CONSTANT VARCHAR2(20)  := 'DEP';                      -- 伝票種別：前受伝票
  cv_line_type_LINE   CONSTANT VARCHAR2(20)  := 'LINE';                     -- 明細種別：明細
  cv_line_type_TAX    CONSTANT VARCHAR2(20)  := 'TAX';                      -- 明細種別：税金
  cv_conv_type_USER   CONSTANT VARCHAR2(20)  := 'User';                     -- レートタイプ：ユーザ
  cv_conv_rate_USER   CONSTANT NUMBER        := 1;                          -- レートタイプ＝ユーザの時のレート
  cv_attribute_7      CONSTANT VARCHAR2(20)  := 'OPEN';                     --
  cv_attribute_8      CONSTANT VARCHAR2(20)  := 'WAITING';                  --
  cv_attribute_9      CONSTANT VARCHAR2(20)  := 'WAITING';                  --
  cv_acc_class_REV    CONSTANT VARCHAR2(20)  := 'REV';                      --
  cv_acc_class_TAX    CONSTANT VARCHAR2(20)  := 'TAX';                      --
  cv_acc_class_REC    CONSTANT VARCHAR2(20)  := 'REC';                      --
  cn_percent_100      CONSTANT NUMBER        := 100;                        --
  cv_const_Y          CONSTANT VARCHAR2(1)   := 'Y';                        --
  cv_const_N          CONSTANT VARCHAR2(1)   := 'N';                        --
--
  -- *** グローバル・カーソル ***
  CURSOR get_ar_trance_data_cur(i_org_id XX03_RECEIVABLE_SLIPS.ORG_ID%TYPE)
  IS
    SELECT    XRS.RECEIVABLE_NUM             AS RECEIVABLE_NUM             -- 伝票番号
            , XRS.RECEIVABLE_ID              AS RECEIVABLE_ID              -- 伝票ID
            , XRS.ENTRY_DEPARTMENT           AS ENTRY_DEPARTMENT           -- 起票部門
            -- Ver11.5.10.1.4 2005/08/26 Change Start
            --, XEP.EMPLOYEE_NUMBER            AS EMPLOYEE_NUMBER            -- 伝票入力者
            , XEP.USER_NAME                  AS USER_NAME                  -- 伝票入力者
            -- Ver11.5.10.1.4 2005/08/26 Change End
            , XRS.TRANS_TYPE_ID              AS TRANS_TYPE_ID              -- 取引タイプID
            , XRS.CUSTOMER_ID                AS CUSTOMER_ID                -- 顧客ID
            , XRS.CUSTOMER_OFFICE_ID         AS CUSTOMER_OFFICE_ID         -- 顧客事業所ID
            , HCSU.LOCATION                  AS LOCATION                   -- 顧客Location
            , XRS.INVOICE_DATE               AS INVOICE_DATE               -- 請求書日付
            , XRS.GL_DATE                    AS GL_DATE                    -- 計上日
            , XRS.RECEIPT_METHOD_ID          AS RECEIPT_METHOD_ID          -- 支払方法ID
            , XRS.TERMS_ID                   AS TERMS_ID                   -- 支払条件ID
            , XRS.INVOICE_CURRENCY_CODE      AS INVOICE_CURRENCY_CODE      -- 通貨コード
            , XRS.EXCHANGE_RATE              AS EXCHANGE_RATE              -- レート
            , XRS.EXCHANGE_RATE_TYPE         AS EXCHANGE_RATE_TYPE         -- レートタイプ
            , XRS.COMMITMENT_NUMBER          AS COMMITMENT_NUMBER          -- 前受金充当番号
            , XRS.DESCRIPTION                AS DESCRIPTION                -- 備考
            , XRS.ORIG_INVOICE_NUM           AS ORIG_INVOICE_NUM           -- 修正元伝票番号
            , XRS.INV_AMOUNT                 AS INV_AMOUNT                 -- 請求合計金額
            , XRS.INV_ITEM_AMOUNT            AS INV_ITEM_AMOUNT            -- 請求本体金額
            , XRS.INV_TAX_AMOUNT             AS INV_TAX_AMOUNT             -- 消費税額
            , XRS.COMMITMENT_AMOUNT          AS COMMITMENT_AMOUNT          -- 前受充当金額
            , XRS.ONETIME_CUSTOMER_NAME      AS ONETIME_CUSTOMER_NAME      -- 一見顧客名称
            , XRS.ONETIME_CUSTOMER_KANA_NAME AS ONETIME_CUSTOMER_KANA_NAME -- カナ名
            , XRS.ONETIME_CUSTOMER_ADDRESS_1 AS ONETIME_CUSTOMER_ADDRESS_1 -- 住所１
            , XRS.ONETIME_CUSTOMER_ADDRESS_2 AS ONETIME_CUSTOMER_ADDRESS_2 -- 住所２
            , XRS.ONETIME_CUSTOMER_ADDRESS_3 AS ONETIME_CUSTOMER_ADDRESS_3 -- 住所３
            , XRS.COMMITMENT_NAME            AS COMMITMENT_NAME            -- 摘要
            , XRS.COMMITMENT_ORIGINAL_AMOUNT AS COMMITMENT_ORIGINAL_AMOUNT -- 金額
            , XRS.COMMITMENT_DATE_FROM       AS COMMITMENT_DATE_FROM       -- 有効日（自）
            , XRS.COMMITMENT_DATE_TO         AS COMMITMENT_DATE_TO         -- 有効日（至）
            , XRS.ORG_ID                     AS ORG_ID                     -- オルグID
--Ver11.5.10.2.11 add start
            , XRS.PAYMENT_ELE_DATA_YES       AS PAYMENT_ELE_DATA_YES       -- 支払案内書電子データ受領あり
--Ver11.5.10.2.11 add end
            , SYSDATE                        AS UPD_DATE
            , STV.ATTRIBUTE12                AS ATTRIBUTE12                -- 'INV' OR 'DEP'
            , REC_SEG.REC_SEG1               AS REC_SEG1                  --
            , REC_SEG.REC_SEG2               AS REC_SEG2                  --
            , REC_SEG.REC_SEG3               AS REC_SEG3                  --
            , REC_SEG.REC_SEG4               AS REC_SEG4                  --
            , REC_SEG5.REC_SEG5              AS REC_SEG5                  --
            , REC_SEG.REC_SEG6               AS REC_SEG6                  --
            , REC_SEG.REC_SEG7               AS REC_SEG7                  --
            , REC_SEG.REC_SEG8               AS REC_SEG8                  --
    FROM      XX03_RECEIVABLE_SLIPS     XRS
            , XX03_ENTRY_PERSON_LOV_V   XEP
            , XX03_SLIP_TYPES_V         STV
            , HZ_CUST_ACCT_SITES        CAS
            , HZ_CUST_SITE_USES         HCSU
            , ( SELECT  RCTT.CUST_TRX_TYPE_ID    REC_CUST_TRX_TYPE_ID
                      , GCC.SEGMENT1             REC_SEG1
                      , GCC.SEGMENT2             REC_SEG2
                      , GCC.SEGMENT3             REC_SEG3
                      , GCC.SEGMENT4             REC_SEG4
                      , GCC.SEGMENT6             REC_SEG6
                      , GCC.SEGMENT7             REC_SEG7
                      , GCC.SEGMENT8             REC_SEG8
                FROM    RA_CUST_TRX_TYPES     RCTT
                      , GL_CODE_COMBINATIONS  GCC
                WHERE  RCTT.GL_ID_REC = GCC.CODE_COMBINATION_ID      ) REC_SEG
-- Ver11.5.10.1.6 Chg Start
--            , ( SELECT  GCC.SEGMENT5      REC_SEG5
--                      , ACV.CUSTOMER_ID   CUSTOMER_ID
--                      , AAV.ADDRESS_ID    ADDRESS_ID
--                FROM    AR_ADDRESSES_V             AAV
--                      , AR_CUSTOMERS_V             ACV
--                      , AR_CUST_RECEIPT_METHODS_V  ACRMV
--                      , AR_CUSTOMER_PROFILES_V     ACPV
--                      , HZ_SITE_USES_V             HSUV
--                      , GL_CODE_COMBINATIONS       GCC
--                WHERE  ACV.CUSTOMER_ID          = ACRMV.CUSTOMER_ID
--                  AND  ACV.CUSTOMER_ID          = ACPV.CUSTOMER_ID
--                  AND  HSUV.SITE_USE_ID         = ACRMV.SITE_USE_ID
--                  AND  HSUV.SITE_USE_ID         = ACPV.SITE_USE_ID
--                  AND  TRUNC(SYSDATE)           BETWEEN ACRMV.START_DATE
--                                                AND NVL(ACRMV.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
--                  AND  ACRMV.PRIMARY_FLAG       = 'Y'
--                  AND  HSUV.PRIMARY_FLAG        = 'Y'
--                  AND  HSUV.STATUS              = 'A'
--                  AND  HSUV.SITE_USE_CODE       = 'BILL_TO'
--                  AND  ACV.CUSTOMER_ID          = AAV.CUSTOMER_ID
--                  AND  GCC.CODE_COMBINATION_ID  = HSUV.GL_ID_REC     ) REC_SEG5
            , ( SELECT  GCC.SEGMENT5             REC_SEG5
                      , HCA.CUST_ACCOUNT_ID      CUSTOMER_ID
                      , HCAS.CUST_ACCT_SITE_ID   ADDRESS_ID
                FROM    HZ_CUST_ACCOUNTS           HCA
                      , HZ_CUST_ACCT_SITES         HCAS
                      , RA_CUST_RECEIPT_METHODS    RCRM
                      , HZ_CUSTOMER_PROFILES       HCP
                      , HZ_CUST_SITE_USES          HCSU
                      , GL_CODE_COMBINATIONS       GCC
                WHERE  HCA.CUST_ACCOUNT_ID  = HCAS.CUST_ACCOUNT_ID
                  AND  HCA.CUST_ACCOUNT_ID  = RCRM.CUSTOMER_ID
                  AND  HCA.CUST_ACCOUNT_ID  = HCP.CUST_ACCOUNT_ID
                  AND  TRUNC(SYSDATE)       BETWEEN RCRM.START_DATE
                                                AND NVL(RCRM.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
                  AND  RCRM.PRIMARY_FLAG    = 'Y'
                  AND  HCSU.SITE_USE_ID     = RCRM.SITE_USE_ID
                  AND  HCSU.SITE_USE_ID     = HCP.SITE_USE_ID
                  AND  HCSU.PRIMARY_FLAG    = 'Y'
                  AND  HCSU.STATUS          = 'A'
                  AND  HCSU.SITE_USE_CODE   = 'BILL_TO'
                  AND  HCSU.GL_ID_REC       = GCC.CODE_COMBINATION_ID  ) REC_SEG5
-- Ver11.5.10.1.6 Chg End
    WHERE     XRS.WF_STATUS           =  CV_APPR_STATUS                       -- 経理承認済ステータス「80」
      AND     XRS.AR_FORWARD_DATE     IS NULL                                 -- AR転送日が未設定
      AND     XRS.ORG_ID              =  i_org_id                             -- オルグIDがログイン職責に該当
      AND     XRS.ENTRY_PERSON_ID     =  XEP.PERSON_ID                        -- PERSON_ID より USER_NAME 取得
      AND     XRS.SLIP_TYPE           =  STV.LOOKUP_CODE                      -- 伝票種別より'INV','DEP'取得
      AND     CAS.CUST_ACCOUNT_ID     =  XRS.CUSTOMER_ID
      AND     CAS.CUST_ACCT_SITE_ID   =  XRS.CUSTOMER_OFFICE_ID
      AND     HCSU.CUST_ACCT_SITE_ID  =  CAS.CUST_ACCT_SITE_ID
      AND     HCSU.SITE_USE_CODE      =  'BILL_TO'
      AND     HCSU.STATUS             =  'A'
      AND     XRS.TRANS_TYPE_ID       =  REC_SEG.REC_CUST_TRX_TYPE_ID(+)
      AND     XRS.CUSTOMER_ID         =  REC_SEG5.CUSTOMER_ID(+)
      AND     XRS.CUSTOMER_OFFICE_ID  =  REC_SEG5.ADDRESS_ID(+)
    ORDER BY  xrs.RECEIVABLE_ID
    -- ver 11.5.10.2.10 Add Start
    FOR UPDATE OF XRS.RECEIVABLE_ID NOWAIT
    -- ver 11.5.10.2.10 Add End
  ;
-- ver 1.2 Change Start
--
  /**********************************************************************************
   * Procedure Name   : copy_err_data
   * Description      : エラー時エラーテーブルへ退避し、転送済みにする
   ***********************************************************************************/
  PROCEDURE copy_err_data(
    i_receivable_id IN  XX03_RECEIVABLE_SLIPS.RECEIVABLE_ID%TYPE,       -- エラーデータの伝票ID
    id_upd_date     IN  DATE,                                           -- 転送済み時の日時
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_err_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --エラーテーブルへ退避
    INSERT INTO XX03_RECEIVABLE_SLIPS_ERR
        ( SELECT * FROM XX03_RECEIVABLE_SLIPS      WHERE RECEIVABLE_ID = i_receivable_id );
    INSERT INTO XX03_RECEIVABLE_SLIPS_LINE_ERR
        ( SELECT * FROM XX03_RECEIVABLE_SLIPS_LINE WHERE RECEIVABLE_ID = i_receivable_id );
    --エラー退避したレコードは転送済み扱いにする
    UPDATE  xx03_receivable_slips xrs
    SET     xrs.AR_FORWARD_DATE   = id_upd_date                        -- AR転送日
          , xrs.last_update_date  = id_upd_date                        -- 最終更新日
          , xrs.last_updated_by   = xx00_global_pkg.user_id            -- 最終更新者
          , xrs.last_update_login = xx00_global_pkg.last_update_login  -- 最終更新職責
    WHERE   xrs.RECEIVABLE_ID     = i_receivable_id                    -- 処理対象の請求書ID
    ;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END copy_err_data;
-- ver 1.2 Change End
--
  /**********************************************************************************
   * Procedure Name   : ar_api_for_deposit
   * Description      : ARAPIの更新［前受金］ (A-2)
   ***********************************************************************************/
  PROCEDURE ar_api_for_deposit(
    i_ar_rec                     IN  get_ar_trance_data_cur%ROWTYPE,  -- 1.取得データカーソル型(IN)
    in_source_id                 IN  NUMBER,                          -- 2.ソースID(IN)
    in_org_id                    IN  NUMBER,                          -- 3.オルグID(IN)
    in_att_category              IN  VARCHAR2,                        -- 4.明細FFコンテキスト(IN)
    in_base_currency             IN  VARCHAR2,                        -- 5.基本通貨コード(IN)
    in_updated_by                IN  NUMBER,                          -- 6.最終更新者(IN)
    in_update_login              IN  NUMBER,                          -- 7.最終ログイン(IN)
    in_created_by                IN  NUMBER,                          -- 8.作成者(IN)
    on_detail_cnt                OUT NUMBER,                          -- 9.明細件数(OUT)
    ov_errbuf                    OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                    OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ar_api_for_deposit'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_detail_cnt           NUMBER := 0;     -- 明細件数

    l_new_trx_number            ra_customer_trx.trx_number%type;
    l_new_customer_trx_id       ra_customer_trx.customer_trx_id%type;
    l_new_customer_trx_line_id  ra_customer_trx_lines.customer_trx_line_id%type;
    l_new_rowid                 VARCHAR2(240);
--
    l_return_status             VARCHAR2(1);
    l_msg_count                 NUMBER;
    l_msg_data                  VARCHAR2(2000);
    l_count                     NUMBER;
    l_return_code               VARCHAR2(1);
--
    -- *** ローカル・カーソル ***
    CURSOR get_rec_slip_lines_cur(i_receivable_id XX03_RECEIVABLE_SLIPS.RECEIVABLE_ID%TYPE)
    IS
      SELECT  XRSL.SLIP_LINE_TYPE_NAME       AS SLIP_LINE_TYPE_NAME       -- 請求内容
            , XRSL.INCR_DECR_REASON_CODE     AS INCR_DECR_REASON_CODE     -- 増減事由
            , XRSL.RECON_REFERENCE           AS RECON_REFERENCE           -- 消込参照
            , XRSL.ATTRIBUTE1                AS ATTRIBUTE1                -- DFF予備１
            , XRSL.ATTRIBUTE2                AS ATTRIBUTE2                -- DFF予備２
            , XRSL.ATTRIBUTE3                AS ATTRIBUTE3                -- DFF予備３
            , XRSL.ATTRIBUTE4                AS ATTRIBUTE4                -- DFF予備４
            , XRSL.ATTRIBUTE5                AS ATTRIBUTE5                -- DFF予備５
            , XRSL.ATTRIBUTE6                AS ATTRIBUTE6                -- DFF予備６
            , XRSL.ATTRIBUTE7                AS ATTRIBUTE7                -- DFF予備７
            , XRSL.ATTRIBUTE8                AS ATTRIBUTE8                -- DFF予備８
      FROM    XX03_RECEIVABLE_SLIPS_LINE    XRSL
      WHERE   XRSL.RECEIVABLE_ID          =  i_receivable_id
      ORDER BY XRSL.LINE_NUMBER
    ;
--
    -- *** ローカル・レコード ***
    -- AR請求依頼明細カーソルレコード
    l_get_rec_slip_lines_rec  get_rec_slip_lines_cur%ROWTYPE;
--
    l_conv_type       XX03_RECEIVABLE_SLIPS.EXCHANGE_RATE_TYPE%TYPE;     -- レートタイプ
    l_conv_date       XX03_RECEIVABLE_SLIPS.GL_DATE%TYPE;                -- レート日付
    l_conv_rate       XX03_RECEIVABLE_SLIPS.EXCHANGE_RATE%TYPE;          -- レート
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    warning_api_expt          EXCEPTION;              -- API内エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --AR請求依頼明細カーソルオープン
    OPEN get_rec_slip_lines_cur(i_ar_rec.RECEIVABLE_ID);
    <<get_ar_lines_loop>>
    LOOP
      FETCH get_rec_slip_lines_cur INTO l_get_rec_slip_lines_rec;
      -- 0件判定
      IF (get_rec_slip_lines_cur%NOTFOUND) THEN
        EXIT get_ar_lines_loop;
      END IF;
--
    --条件での判定項目
      -- 通貨コードによりレート変換項目を設定する
      IF i_ar_rec.INVOICE_CURRENCY_CODE = in_base_currency THEN
        l_conv_type  := NULL;
        l_conv_date  := NULL;
        l_conv_rate  := NULL;
      ELSE
        l_conv_type  := i_ar_rec.EXCHANGE_RATE_TYPE;
        l_conv_date  := i_ar_rec.GL_DATE;
        -- レートがユーザ以外の場合はレートはNULL
        IF i_ar_rec.EXCHANGE_RATE_TYPE = cv_conv_type_USER THEN
          l_conv_rate  := i_ar_rec.EXCHANGE_RATE;
        ELSE
          l_conv_rate  := NULL;
        END IF;
      END IF;
--
      ar_deposit_api_pub.CREATE_DEPOSIT(
          p_api_version                  => 1.0                                               -- APIバージョン
        , p_init_msg_list                => FND_API.G_TRUE
        , p_commit                       => FND_API.G_FALSE
        , p_validation_level             => FND_API.G_VALID_LEVEL_FULL
        , x_return_status                => l_return_status
        , x_msg_count                    => l_msg_count
        , x_msg_data                     => l_msg_data
        , p_deposit_number               => i_ar_rec.RECEIVABLE_NUM                          -- 伝票番号
        , p_attribute5                   => i_ar_rec.ENTRY_DEPARTMENT                        -- 起票部門
        -- Ver11.5.10.1.4 2005/08/26 Change Start
        --, p_attribute6                   => i_ar_rec.EMPLOYEE_NUMBER                         -- 伝票入力者
        , p_attribute6                   => i_ar_rec.USER_NAME                               -- 伝票入力者
        -- Ver11.5.10.1.4 2005/08/26 Change End
        , p_cust_trx_type_id             => i_ar_rec.TRANS_TYPE_ID                           -- 取引タイプID
        , p_bill_to_customer_id          => i_ar_rec.CUSTOMER_ID                             -- 顧客ID
        , p_bill_to_location             => i_ar_rec.LOCATION                                -- 顧客事業所ID
        , p_deposit_date                 => i_ar_rec.INVOICE_DATE                            -- 請求書日付
        , p_gl_date                      => i_ar_rec.GL_DATE                                 -- 計上日
        , p_receipt_method_id            => i_ar_rec.RECEIPT_METHOD_ID                       -- 支払方法ID
        , p_term_id                      => i_ar_rec.TERMS_ID                                -- 支払条件ID
        , p_currency_code                => i_ar_rec.INVOICE_CURRENCY_CODE                   -- 通貨コード
        , p_exchange_rate                => l_conv_rate                                      -- レート
        , p_exchange_rate_type           => l_conv_type                                      -- レートタイプ
        , p_exchange_rate_date           => l_conv_date                                      -- レート日付
        , p_agreement_id                 => i_ar_rec.COMMITMENT_NUMBER                       -- 前受金充当番号
        , p_comments                     => i_ar_rec.DESCRIPTION                             -- 備考
        , p_attribute1                   => i_ar_rec.ONETIME_CUSTOMER_NAME                   -- 一見顧客名称
        , p_attribute10                  => i_ar_rec.ONETIME_CUSTOMER_KANA_NAME              -- 一見顧客カナ名
        , p_attribute2                   => i_ar_rec.ONETIME_CUSTOMER_ADDRESS_1              -- 一見顧客住所１
        , p_attribute3                   => i_ar_rec.ONETIME_CUSTOMER_ADDRESS_2              -- 一見顧客住所２
        , p_attribute4                   => i_ar_rec.ONETIME_CUSTOMER_ADDRESS_3              -- 一見顧客住所３
        , p_attribute_category           => in_org_id                                        --
        , p_attribute7                   => 'OPEN'                                           --
        , p_attribute8                   => 'WAITING'                                        --
        , p_attribute9                   => 'WAITING'                                        --
        , p_memo_line_name               => l_get_rec_slip_lines_rec.SLIP_LINE_TYPE_NAME     -- 請求内容
        , p_description                  => i_ar_rec.COMMITMENT_NAME                         -- 摘要
        , p_amount                       => i_ar_rec.INV_AMOUNT                              -- 金額
        , p_comm_interface_line_attr1    => l_get_rec_slip_lines_rec.INCR_DECR_REASON_CODE   -- 増減事由
        , p_comm_interface_line_attr2    => l_get_rec_slip_lines_rec.RECON_REFERENCE         -- 消込参照
        , p_comm_interface_line_attr3    => l_get_rec_slip_lines_rec.ATTRIBUTE1              -- DFF予備１
        , p_comm_interface_line_attr4    => l_get_rec_slip_lines_rec.ATTRIBUTE2              -- DFF予備２
        , p_comm_interface_line_attr5    => l_get_rec_slip_lines_rec.ATTRIBUTE3              -- DFF予備３
        , p_comm_interface_line_attr6    => l_get_rec_slip_lines_rec.ATTRIBUTE4              -- DFF予備４
        , p_comm_interface_line_attr7    => l_get_rec_slip_lines_rec.ATTRIBUTE5              -- DFF予備５
        , p_comm_interface_line_attr8    => l_get_rec_slip_lines_rec.ATTRIBUTE6              -- DFF予備６
        , p_comm_interface_line_attr9    => l_get_rec_slip_lines_rec.ATTRIBUTE7              -- DFF予備７
        , p_comm_interface_line_attr10   => l_get_rec_slip_lines_rec.ATTRIBUTE8              -- DFF予備８
        , p_start_date_commitment        => i_ar_rec.COMMITMENT_DATE_FROM                    -- 有効日（自）
        , p_end_date_commitment          => i_ar_rec.COMMITMENT_DATE_TO                      -- 有効日（至）
        , p_batch_source_id              => in_source_id                                     -- ソースID
        , p_class                        => 'DEP'
        , X_new_trx_number               => l_new_trx_number
        , X_new_customer_trx_id          => l_new_customer_trx_id
        , X_new_customer_trx_line_id     => l_new_customer_trx_line_id
        , X_new_rowid                    => l_new_rowid
        );
--
      IF l_return_status = 'S' THEN
--
        --請求依頼を「AR転送済」に更新する。
        UPDATE  xx03_receivable_slips xrs
        SET     xrs.AR_FORWARD_DATE   = i_ar_rec.UPD_DATE,                  -- AR転送日
                xrs.last_update_date  = i_ar_rec.UPD_DATE,                  -- 最終更新日
                xrs.last_updated_by   = xx00_global_pkg.user_id,            -- 最終更新者
                xrs.last_update_login = xx00_global_pkg.last_update_login   -- 最終更新職責
        WHERE   xrs.RECEIVABLE_ID     = i_ar_rec.RECEIVABLE_ID              -- 処理対象の請求書ID
        ;
--
      ELSE
        <<api_log_loop>>
        LOOP
          --ログ出力
          IF nvl(l_count,0) < l_msg_count THEN
            l_count := nvl(l_count,0) +1 ;
            l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
            xx00_file_pkg.log(' ' || l_msg_data);
          ELSE
            EXIT api_log_loop;
          END IF;
        END LOOP api_log_loop;
--
        IF l_return_status = 'E' THEN
          RAISE warning_api_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END IF;
--
      ln_detail_cnt := ln_detail_cnt + 1;
    END LOOP get_ar_lines_loop;
    CLOSE get_rec_slip_lines_cur;
--
    on_detail_cnt := ln_detail_cnt;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_api_expt THEN  --*** APIエラー(←API内部で例外以外のエラー発生) ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END ar_api_for_deposit;
--
  /**********************************************************************************
   * Procedure Name   : ar_if_invoice_set
   * Description      : OPEN_IF_TABLE型変数への格納
   ***********************************************************************************/
  PROCEDURE ar_if_invoice_set(
    i_if_line_rec                OUT trx_if_line_type,                -- 1.RA_IF_レコード LINE(OUT)
    i_if_dist_rec                OUT trx_if_dist_type,                -- 2.RA_IF_レコード DIST(OUT)
    i_ar_tran_rec                IN  get_ar_trance_data_cur%ROWTYPE,  -- 3.ARインターフェースレコード(IN)
    in_source_id                 IN  NUMBER,                          -- 4.ソースID(IN)
    iv_source                    IN  VARCHAR2,                        -- 5.ソース名(IN)
-- ver 1.2 Change Start
    in_source_id2                IN  NUMBER,                          --  .前受金ソースID(IN)
-- ver 1.2 Change End
    in_org_id                    IN  NUMBER,                          -- 6.オルグID(IN)
    in_books_id                  IN  NUMBER,                          -- 7.会計帳簿ID(IN)
    in_att_category              IN  VARCHAR2,                        -- 8.明細FFコンテキスト(IN)
    in_base_currency             IN  VARCHAR2,                        -- 9.基本通貨コード(IN)
    in_nvl_att_1                 IN  VARCHAR2,                        -- 10.空白時明細備考欄(IN)
    in_nvl_att_3                 IN  VARCHAR2,                        -- 11.空白時明細納品書番号(IN)
    in_updated_by                IN  NUMBER,                          -- 12.最終更新者(IN)
    in_update_login              IN  NUMBER,                          -- 13.最終ログイン(IN)
    in_created_by                IN  NUMBER,                          -- 14.作成者(IN)
    on_detail_cnt                OUT NUMBER,                          -- 15.明細件数(OUT)
    ov_errbuf                    OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                    OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ar_if_invoice_set'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_detail_cnt           NUMBER := 0;     -- 明細件数
    ln_rec_cnt              NUMBER := 0;     -- ライン配列件数
--
    l_first_LINE_NUMBER           XX03_RECEIVABLE_SLIPS_LINE.LINE_NUMBER%TYPE;           -- １行目の明細の明細行番号
    l_first_SLIP_DESCRIPTION      XX03_RECEIVABLE_SLIPS_LINE.SLIP_DESCRIPTION%TYPE;      -- １行目の明細の備考（明細）
    l_first_SLIP_LINE_RECIEPT_NO  XX03_RECEIVABLE_SLIPS_LINE.SLIP_LINE_RECIEPT_NO%TYPE;  -- １行目の明細の納品書番号
--
    l_conv_type           XX03_RECEIVABLE_SLIPS.EXCHANGE_RATE_TYPE%TYPE;          -- レートタイプ
    l_conv_date           XX03_RECEIVABLE_SLIPS.GL_DATE%TYPE;                     -- レート日付
    l_conv_rate           XX03_RECEIVABLE_SLIPS.EXCHANGE_RATE%TYPE;               -- レート
    l_receipt_id_tax      XX03_RECEIVABLE_SLIPS.RECEIPT_METHOD_ID%TYPE;           -- 支払方法
    l_term_id             XX03_RECEIVABLE_SLIPS.TERMS_ID%TYPE;                    -- 支払条件
    l_amount              XX03_RECEIVABLE_SLIPS.INV_AMOUNT%TYPE;                  --
    l_inc_tax_flg         RA_INTERFACE_LINES_ALL.AMOUNT_INCLUDES_TAX_FLAG%TYPE;   --
--
    l_ref_line_id_line    RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ID%TYPE;          -- 取消伝票(前受伝票)の元情報
    l_ref_line_id_tax     RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ID%TYPE;          -- 取消伝票の取消元情報
    l_ref_line_con        RA_INTERFACE_LINES_ALL.INTERFACE_LINE_CONTEXT%TYPE;     -- 取消伝票の取消元情報
    l_ref_line_att1       RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE1%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att2       RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE2%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att3       RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE3%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att4       RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE4%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att5       RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE5%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att6_line  RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE6%TYPE;  -- 取消伝票の取消元情報
    l_ref_line_att6_tax   RA_INTERFACE_LINES_ALL.INTERFACE_LINE_ATTRIBUTE6%TYPE;  -- 取消伝票の取消元情報
--
    -- *** ローカル・カーソル ***
    -- 明細レコード
    CURSOR get_rec_slip_lines_cur(  i_rec_id      XX03_RECEIVABLE_SLIPS.RECEIVABLE_ID%TYPE
                                  , i_bat_id      RA_CUSTOMER_TRX.BATCH_SOURCE_ID%TYPE
                                  , i_orig_num    RA_CUSTOMER_TRX.TRX_NUMBER%TYPE
                                  , i_nvl_att_1   XX03_RECEIVABLE_SLIPS_LINE.SLIP_DESCRIPTION%TYPE
                                  , i_nvl_att_3   XX03_RECEIVABLE_SLIPS_LINE.SLIP_LINE_RECIEPT_NO%TYPE
-- ver 1.2 Change Start
                                  , i_commit_bat  RA_CUSTOMER_TRX.BATCH_SOURCE_ID%TYPE
-- 2005/1/19 Ver11.5.10.1.6B Add Start
--                                  , i_commit_num  RA_CUSTOMER_TRX.TRX_NUMBER%TYPE)
                                  , i_commit_num  RA_CUSTOMER_TRX.TRX_NUMBER%TYPE
                                  , i_org_id      XX03_RECEIVABLE_SLIPS.ORG_ID%TYPE)
-- 2005/1/19 Ver11.5.10.1.6B Add End
-- ver 1.2 Change End
    IS
      SELECT  XRSL.RECEIVABLE_ID              AS RECEIVABLE_ID             -- 請求書ID
      -- Ver11.5.10.1.5 2005/09/29 Add Start
            , XRSL.JOURNAL_DESCRIPTION        AS JOURNAL_DESCRIPTION       -- 仕訳備考
      -- Ver11.5.10.1.5 2005/09/29 Add End
            , XRSL.LINE_NUMBER                AS LINE_NUMBER               -- 明細行番号
            , XRSL.SLIP_LINE_TYPE             AS SLIP_LINE_TYPE            -- 請求内容ID
            , XRSL.SLIP_LINE_TYPE_NAME        AS SLIP_LINE_TYPE_NAME       -- 請求内容
            , XRSL.SLIP_LINE_UOM              AS SLIP_LINE_UOM             -- 単位
            , XRSL.SLIP_LINE_UNIT_PRICE       AS SLIP_LINE_UNIT_PRICE      -- 単価
            , XRSL.SLIP_LINE_QUANTITY         AS SLIP_LINE_QUANTITY        -- 数量
            , XRSL.SLIP_LINE_ENTERED_AMOUNT   AS SLIP_LINE_ENTERED_AMOUNT  -- 入力金額
            , XRSL.AMOUNT_INCLUDES_TAX_FLAG   AS AMOUNT_INCLUDES_TAX_FLAG  -- 内税フラグ
            , XRSL.ENTERED_ITEM_AMOUNT        AS ENTERED_ITEM_AMOUNT       -- 明細本体金額
            , XRSL.ENTERED_TAX_AMOUNT         AS ENTERED_TAX_AMOUNT        -- 明細消費税額
            , XRSL.TAX_CODE                   AS TAX_CODE                  -- 税区分コード
            , XRSL.TAX_ID                     AS TAX_ID                    -- 税区分ID
            , XRSL.TAX_NAME                   AS TAX_NAME                  -- 税区分
            , NVL( XRSL.SLIP_LINE_RECIEPT_NO , i_nvl_att_3 )
                                              AS SLIP_LINE_RECIEPT_NO      -- 納品書番号
            , NVL( XRSL.SLIP_DESCRIPTION     , i_nvl_att_1 )
                                              AS SLIP_DESCRIPTION          -- 備考（明細）
            , XRSL.INCR_DECR_REASON_CODE      AS INCR_DECR_REASON_CODE     -- 増減事由
            , XRSL.RECON_REFERENCE            AS RECON_REFERENCE           -- 消込参照
            , XRSL.ATTRIBUTE_CATEGORY         AS ATTRIBUTE_CATEGORY        --
            , XRSL.ATTRIBUTE1                 AS ATTRIBUTE1                -- DFF予備１
            , XRSL.ATTRIBUTE2                 AS ATTRIBUTE2                -- DFF予備２
            , XRSL.ATTRIBUTE3                 AS ATTRIBUTE3                -- DFF予備３
            , XRSL.ATTRIBUTE4                 AS ATTRIBUTE4                -- DFF予備４
            , XRSL.ATTRIBUTE5                 AS ATTRIBUTE5                -- DFF予備５
            , XRSL.ATTRIBUTE6                 AS ATTRIBUTE6                -- DFF予備６
            , XRSL.ATTRIBUTE7                 AS ATTRIBUTE7                -- DFF予備７
            , XRSL.ATTRIBUTE8                 AS ATTRIBUTE8                -- DFF予備８
            , XRSL.SEGMENT1                   AS SEGMENT1                  -- 会社
            , XRSL.SEGMENT2                   AS SEGMENT2                  -- 部門
            , XRSL.SEGMENT3                   AS SEGMENT3                  -- 勘定科目
            , XRSL.SEGMENT4                   AS SEGMENT4                  -- 補助科目
            , XRSL.SEGMENT5                   AS SEGMENT5                  -- 相手先
            , XRSL.SEGMENT6                   AS SEGMENT6                  -- 事業区分
            , XRSL.SEGMENT7                   AS SEGMENT7                  -- プロジェクト
            , XRSL.SEGMENT8                   AS SEGMENT8                  -- 予備１
            , TAX_SEG.TAX_SEG1                AS TAX_SEG1                  --
            , TAX_SEG.TAX_SEG2                AS TAX_SEG2                  --
            , TAX_SEG.TAX_SEG3                AS TAX_SEG3                  --
            , TAX_SEG.TAX_SEG4                AS TAX_SEG4                  --
            , TAX_SEG.TAX_SEG5                AS TAX_SEG5                  --
            , TAX_SEG.TAX_SEG6                AS TAX_SEG6                  --
            , TAX_SEG.TAX_SEG7                AS TAX_SEG7                  --
            , TAX_SEG.TAX_SEG8                AS TAX_SEG8                  --
            , RA_CTL.TRX_LINE_ID_LINE         AS TRX_LINE_ID_LINE          --
            , RA_CTL.TRX_LINE_ID_TAX          AS TRX_LINE_ID_TAX           --
            , ORIG_XRSL.ORIG_SLIP_DESC        AS ORIG_SLIP_DESC            --
            , ORIG_XRSL.ORIG_SLIP_REC_NO      AS ORIG_SLIP_REC_NO          --
-- ver 1.2 Change Start
            , RA_CTL2.TRX_LINE_ID_COM         AS TRX_LINE_ID_COM           --
-- ver 1.2 Change End
--
      FROM    XX03_RECEIVABLE_SLIPS_LINE  XRSL
--
            , ( SELECT  AVTAV.VAT_TAX_ID  TAX_VAT_TAX_ID
                      , GCC.SEGMENT1      TAX_SEG1
                      , GCC.SEGMENT2      TAX_SEG2
                      , GCC.SEGMENT3      TAX_SEG3
                      , GCC.SEGMENT4      TAX_SEG4
                      , GCC.SEGMENT5      TAX_SEG5
                      , GCC.SEGMENT6      TAX_SEG6
                      , GCC.SEGMENT7      TAX_SEG7
                      , GCC.SEGMENT8      TAX_SEG8
                FROM    AR_VAT_TAX_ALL_VL     AVTAV
                      , GL_CODE_COMBINATIONS  GCC
                WHERE  AVTAV.TAX_ACCOUNT_ID  =  GCC.CODE_COMBINATION_ID  ) TAX_SEG
--
            -- ver 11.5.10.2.4 Chg Start
            ---- ver 11.5.10.2.2B Chg Start
            ----, ( SELECT  RCTL.LINE_NUMBER            LINE_NUMBER
            --, ( SELECT  RCTL.INTERFACE_LINE_ATTRIBUTE5  INTERFACE_LINE_ATTRIBUTE5
            ---- ver 11.5.10.2.2B Chg End
            , ( SELECT  lpad(RCTL.INTERFACE_LINE_ATTRIBUTE5 ,15 ,'0') INTERFACE_LINE_ATTRIBUTE5
            -- ver 11.5.10.2.4 Chg End
                      , RCTL.CUSTOMER_TRX_LINE_ID   TRX_LINE_ID_LINE
                      , RCTL2.CUSTOMER_TRX_LINE_ID  TRX_LINE_ID_TAX
                FROM    RA_CUSTOMER_TRX        RCT
                      -- ver 11.5.10.2.2B Chg Start
                      --, (SELECT LINE_NUMBER , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID
                      , (SELECT INTERFACE_LINE_ATTRIBUTE5 , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID
                      -- ver 11.5.10.2.2B Chg End
                         FROM RA_CUSTOMER_TRX_LINES  WHERE  LINE_TYPE  =  cv_line_type_LINE  )  RCTL
                      -- ver 11.5.10.2.2B Chg Start
                      --, (SELECT LINE_NUMBER , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID , LINK_TO_CUST_TRX_LINE_ID
                      , (SELECT INTERFACE_LINE_ATTRIBUTE5 , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID , LINK_TO_CUST_TRX_LINE_ID
                      -- ver 11.5.10.2.2B Chg End
                         FROM RA_CUSTOMER_TRX_LINES  WHERE  LINE_TYPE  =  cv_line_type_TAX   )  RCTL2
                WHERE  RCT.BATCH_SOURCE_ID        =  i_bat_id
                  AND  RCT.TRX_NUMBER             =  i_orig_num
                  AND  RCT.CUSTOMER_TRX_ID        =  RCTL.CUSTOMER_TRX_ID
                  AND  RCT.CUSTOMER_TRX_ID        =  RCTL2.CUSTOMER_TRX_ID
                  AND  RCTL.CUSTOMER_TRX_LINE_ID  =  RCTL2.LINK_TO_CUST_TRX_LINE_ID  ) RA_CTL
--
            , ( SELECT  XRSL.LINE_NUMBER                            LINE_NUMBER
-- ver 1.2 Change Start
--                      , XRSL.SLIP_DESCRIPTION      ORIG_SLIP_DESC
--                      , XRSL.SLIP_LINE_RECIEPT_NO  ORIG_SLIP_REC_NO
                      , NVL(XRSL.SLIP_DESCRIPTION     ,i_nvl_att_1) ORIG_SLIP_DESC
                      , NVL(XRSL.SLIP_LINE_RECIEPT_NO ,i_nvl_att_3) ORIG_SLIP_REC_NO
-- ver 1.2 Change End
                FROM    XX03_RECEIVABLE_SLIPS       XRS
                      , XX03_RECEIVABLE_SLIPS_LINE  XRSL
                WHERE  XRS.RECEIVABLE_NUM  =  i_orig_num
-- 2005/1/19 Ver11.5.10.1.6B Add Start
                  AND  XRS.ORG_ID          =  i_org_id
-- 2005/1/19 Ver11.5.10.1.6B Add End
                  AND  XRS.RECEIVABLE_ID   =  XRSL.RECEIVABLE_ID  ) ORIG_XRSL
--
-- ver 1.2 Change Start
            -- ver 11.5.10.2.4 Chg Start
            ---- ver 11.5.10.2.2B Chg Start
            ----, ( SELECT  RCTL.LINE_NUMBER            LINE_NUMBER
            --, ( SELECT  RCTL.INTERFACE_LINE_ATTRIBUTE5  INTERFACE_LINE_ATTRIBUTE5
            ---- ver 11.5.10.2.2B Chg End
            , ( SELECT  lpad(RCTL.INTERFACE_LINE_ATTRIBUTE5 ,15 ,'0') INTERFACE_LINE_ATTRIBUTE5
            -- ver 11.5.10.2.4 Chg End
                      , RCTL.CUSTOMER_TRX_LINE_ID   TRX_LINE_ID_COM
                FROM    RA_CUSTOMER_TRX        RCT
                      -- ver 11.5.10.2.2B Chg Start
                      --, (SELECT LINE_NUMBER , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID
                      , (SELECT INTERFACE_LINE_ATTRIBUTE5 , CUSTOMER_TRX_ID , CUSTOMER_TRX_LINE_ID
                      -- ver 11.5.10.2.2B Chg End
                         FROM RA_CUSTOMER_TRX_LINES  WHERE  LINE_TYPE  =  cv_line_type_LINE  )  RCTL
                WHERE  RCT.BATCH_SOURCE_ID        =  i_commit_bat
                  AND  RCT.TRX_NUMBER             =  i_commit_num
                  AND  RCT.CUSTOMER_TRX_ID        =  RCTL.CUSTOMER_TRX_ID  ) RA_CTL2
-- ver 1.2 Change End
--
      WHERE  XRSL.RECEIVABLE_ID  =  i_rec_id
        AND  XRSL.TAX_ID         =  TAX_SEG.TAX_VAT_TAX_ID (+)
        -- ver 11.5.10.2.2B Chg Start
        --AND  XRSL.LINE_NUMBER    =  RA_CTL.LINE_NUMBER (+)
        AND  to_char(XRSL.LINE_NUMBER,'FM099999999999999')  =  RA_CTL.INTERFACE_LINE_ATTRIBUTE5 (+)
        -- ver 11.5.10.2.2B Chg End
        AND  XRSL.LINE_NUMBER    =  ORIG_XRSL.LINE_NUMBER (+)
-- ver 1.2 Change Start
        -- ver 11.5.10.2.2B Chg Start
        --AND  XRSL.LINE_NUMBER    =  RA_CTL2.LINE_NUMBER (+)
        AND  to_char(XRSL.LINE_NUMBER,'FM099999999999999')  =  RA_CTL2.INTERFACE_LINE_ATTRIBUTE5 (+)
        -- ver 11.5.10.2.2B Chg End
-- ver 1.2 Change End
--
      ORDER BY  XRSL.LINE_NUMBER
    ;
--
    -- *** ローカル・レコード ***
    -- AR請求依頼明細カーソルレコード
    l_get_rec_slip_lines_rec get_rec_slip_lines_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --AR請求依頼明細カーソルオープン
    OPEN get_rec_slip_lines_cur(  i_ar_tran_rec.RECEIVABLE_ID
                                , in_source_id
                                , i_ar_tran_rec.ORIG_INVOICE_NUM
                                , in_nvl_att_1
                                , in_nvl_att_3
-- ver 1.2 Change Start
                                , in_source_id2
-- 2005/1/19 Ver11.5.10.1.6B Add Start
--                                , i_ar_tran_rec.COMMITMENT_NUMBER);
                                , i_ar_tran_rec.COMMITMENT_NUMBER
                                , in_org_id);
-- 2005/1/19 Ver11.5.10.1.6B Add End
-- ver 1.2 Change End
    <<get_ar_lines_loop>>
    LOOP
      FETCH get_rec_slip_lines_cur INTO l_get_rec_slip_lines_rec;
      -- 0件判定
      IF (get_rec_slip_lines_cur%NOTFOUND) THEN
        EXIT get_ar_lines_loop;
      END IF;
--
      -- 請求依頼明細件数をカウントアップする。
      ln_detail_cnt := ln_detail_cnt + 1;
      ln_rec_cnt    := ln_rec_cnt + 1;
--
      -- 伝票取消（修正元伝票番号がある）の場合
      IF (i_ar_tran_rec.ORIG_INVOICE_NUM Is NOT NULL) THEN
        l_receipt_id_tax  := NULL;
        l_term_id         := NULL;
--
        -- 標準テーブルにあがっているかどうか
        IF l_get_rec_slip_lines_rec.TRX_LINE_ID_LINE IS NOT NULL THEN
          -- 標準テーブルに登録されている場合
          l_ref_line_id_line    :=  l_get_rec_slip_lines_rec.TRX_LINE_ID_LINE;
          l_ref_line_id_tax     :=  l_get_rec_slip_lines_rec.TRX_LINE_ID_TAX;
          l_ref_line_con        :=  NULL;
          l_ref_line_att1       :=  NULL;
          l_ref_line_att2       :=  NULL;
          l_ref_line_att3       :=  NULL;
          l_ref_line_att4       :=  NULL;
          l_ref_line_att5       :=  NULL;
          l_ref_line_att6_line  :=  NULL;
          l_ref_line_att6_tax   :=  NULL;
        ELSE
          -- 標準テーブルに登録されていない場合
          l_ref_line_id_line    :=  NULL;
          l_ref_line_id_tax     :=  NULL;
          l_ref_line_con        :=  in_att_category;
          l_ref_line_att1       :=  l_get_rec_slip_lines_rec.ORIG_SLIP_DESC;
          l_ref_line_att2       :=  NULL;
          l_ref_line_att3       :=  l_get_rec_slip_lines_rec.ORIG_SLIP_REC_NO;
          l_ref_line_att4       :=  i_ar_tran_rec.ORIG_INVOICE_NUM;
          -- ver 11.5.10.2.2 Chg Start
          --l_ref_line_att5       :=  l_get_rec_slip_lines_rec.LINE_NUMBER;
          l_ref_line_att5       :=  to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
          -- ver 11.5.10.2.2 Chg End
          l_ref_line_att6_line  :=  cv_line_type_LINE;
          l_ref_line_att6_tax   :=  cv_line_type_TAX;
        END IF;
--
-- ver 1.2 Change Start
      -- 前受充当（前受金充当番号がある）の場合
      ELSIF (i_ar_tran_rec.COMMITMENT_NUMBER Is NOT NULL) THEN
        l_receipt_id_tax      :=  i_ar_tran_rec.RECEIPT_METHOD_ID;
        l_term_id             :=  i_ar_tran_rec.TERMS_ID;
        l_ref_line_id_line    :=  l_get_rec_slip_lines_rec.TRX_LINE_ID_COM;
        l_ref_line_id_tax     :=  NULL;
        l_ref_line_con        :=  NULL;
        l_ref_line_att1       :=  NULL;
        l_ref_line_att2       :=  NULL;
        l_ref_line_att3       :=  NULL;
        l_ref_line_att4       :=  NULL;
        l_ref_line_att5       :=  NULL;
        l_ref_line_att6_line  :=  NULL;
        l_ref_line_att6_tax   :=  NULL;
-- ver 1.2 Change End
--
      ELSE
        l_receipt_id_tax      :=  i_ar_tran_rec.RECEIPT_METHOD_ID;
        l_term_id             :=  i_ar_tran_rec.TERMS_ID;
        l_ref_line_id_line    :=  NULL;
        l_ref_line_id_tax     :=  NULL;
        l_ref_line_con        :=  NULL;
        l_ref_line_att1       :=  NULL;
        l_ref_line_att2       :=  NULL;
        l_ref_line_att3       :=  NULL;
        l_ref_line_att4       :=  NULL;
        l_ref_line_att5       :=  NULL;
        l_ref_line_att6_line  :=  NULL;
        l_ref_line_att6_tax   :=  NULL;
      END IF;
--
      -- 通貨コードによりレート変換項目を設定する
      IF i_ar_tran_rec.INVOICE_CURRENCY_CODE = in_base_currency THEN
        l_conv_type  := cv_conv_type_USER;
        l_conv_date  := NULL;
        l_conv_rate  := cv_conv_rate_USER;
      ELSE
        l_conv_type  := i_ar_tran_rec.EXCHANGE_RATE_TYPE;
        l_conv_date  := i_ar_tran_rec.GL_DATE;
        -- レートがユーザ以外の場合はレートはNULL
        IF i_ar_tran_rec.EXCHANGE_RATE_TYPE = cv_conv_type_USER THEN
          l_conv_rate  := i_ar_tran_rec.EXCHANGE_RATE;
        ELSE
          l_conv_rate  := NULL;
        END IF;
      END IF;
--
      -- REC行作成時用に１行目のデータ退避
      IF ln_detail_cnt = 1 THEN
        l_first_LINE_NUMBER          := l_get_rec_slip_lines_rec.LINE_NUMBER;
        l_first_SLIP_DESCRIPTION     := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
        l_first_SLIP_LINE_RECIEPT_NO := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
      END IF;
--
      -- 内税フラグによりフラグを Y/NULL 設定する
      IF l_get_rec_slip_lines_rec.AMOUNT_INCLUDES_TAX_FLAG = cv_const_Y THEN
        l_inc_tax_flg  := cv_const_Y;
        l_amount       :=   l_get_rec_slip_lines_rec.ENTERED_ITEM_AMOUNT
                          + l_get_rec_slip_lines_rec.ENTERED_TAX_AMOUNT;
      ELSE
        l_inc_tax_flg  := NULL;
        l_amount       := l_get_rec_slip_lines_rec.ENTERED_ITEM_AMOUNT;
      END IF;
--
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_CONTEXT             := in_att_category;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE1          := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE2          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE3          := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE4          := i_ar_tran_rec.RECEIVABLE_NUM;
      -- ver 11.5.10.2.2 Chg Start
      --i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := l_get_rec_slip_lines_rec.LINE_NUMBER;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
      -- ver 11.5.10.2.2 Chg End
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE6          := cv_line_type_LINE;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE7          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE8          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE9          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE10         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE11         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE12         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE13         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE14         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE15         := NULL;
      i_if_line_rec(ln_rec_cnt).BATCH_SOURCE_NAME                  := iv_source;
      i_if_line_rec(ln_rec_cnt).SET_OF_BOOKS_ID                    := in_books_id;
      i_if_line_rec(ln_rec_cnt).LINE_TYPE                          := cv_line_type_LINE;
      i_if_line_rec(ln_rec_cnt).DESCRIPTION                        := l_get_rec_slip_lines_rec.SLIP_LINE_TYPE_NAME;
      i_if_line_rec(ln_rec_cnt).CURRENCY_CODE                      := i_ar_tran_rec.INVOICE_CURRENCY_CODE;
      i_if_line_rec(ln_rec_cnt).AMOUNT                             := l_amount;
      i_if_line_rec(ln_rec_cnt).CUST_TRX_TYPE_NAME                 := NULL;
      i_if_line_rec(ln_rec_cnt).CUST_TRX_TYPE_ID                   := i_ar_tran_rec.TRANS_TYPE_ID;
      i_if_line_rec(ln_rec_cnt).TERM_NAME                          := NULL;
      i_if_line_rec(ln_rec_cnt).TERM_ID                            := l_term_id;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BATCH_NAME             := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CUSTOMER_ID       := i_ar_tran_rec.CUSTOMER_ID;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_ADDRESS_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_ADDRESS_ID        := i_ar_tran_rec.CUSTOMER_OFFICE_ID;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CONTACT_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CONTACT_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_ID       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_ADDRESS_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_ADDRESS_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CONTACT_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CONTACT_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_ID       := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ID                    := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_CONTEXT               := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE1            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE2            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE3            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE4            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE5            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE6            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE7            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE8            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE9            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE10           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE11           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE12           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE13           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE14           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE15           := NULL;
      i_if_line_rec(ln_rec_cnt).RECEIPT_METHOD_NAME                := NULL;
      i_if_line_rec(ln_rec_cnt).RECEIPT_METHOD_ID                  := i_ar_tran_rec.RECEIPT_METHOD_ID;
      i_if_line_rec(ln_rec_cnt).CONVERSION_TYPE                    := l_conv_type;
      i_if_line_rec(ln_rec_cnt).CONVERSION_DATE                    := l_conv_date;
      i_if_line_rec(ln_rec_cnt).CONVERSION_RATE                    := l_conv_rate;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_TRX_ID                    := NULL;
      i_if_line_rec(ln_rec_cnt).TRX_DATE                           := i_ar_tran_rec.INVOICE_DATE;
      i_if_line_rec(ln_rec_cnt).GL_DATE                            := i_ar_tran_rec.GL_DATE;
      i_if_line_rec(ln_rec_cnt).DOCUMENT_NUMBER                    := NULL;
      i_if_line_rec(ln_rec_cnt).TRX_NUMBER                         := i_ar_tran_rec.RECEIVABLE_NUM;
      i_if_line_rec(ln_rec_cnt).LINE_NUMBER                        := NULL;
      i_if_line_rec(ln_rec_cnt).QUANTITY                           := l_get_rec_slip_lines_rec.SLIP_LINE_QUANTITY;
      i_if_line_rec(ln_rec_cnt).QUANTITY_ORDERED                   := NULL;
      i_if_line_rec(ln_rec_cnt).UNIT_SELLING_PRICE                 := l_get_rec_slip_lines_rec.SLIP_LINE_UNIT_PRICE;
      i_if_line_rec(ln_rec_cnt).UNIT_STANDARD_PRICE                := NULL;
      i_if_line_rec(ln_rec_cnt).PRINTING_OPTION                    := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_STATUS                   := NULL;
      i_if_line_rec(ln_rec_cnt).REQUEST_ID                         := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_BATCH_SOURCE_NAME          := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_TRX_NUMBER                 := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_CUSTOMER_TRX_ID            := NULL;
      i_if_line_rec(ln_rec_cnt).PREVIOUS_CUSTOMER_TRX_ID           := NULL;
      i_if_line_rec(ln_rec_cnt).CREDIT_METHOD_FOR_ACCT_RULE        := NULL;
      i_if_line_rec(ln_rec_cnt).CREDIT_METHOD_FOR_INSTALLMENTS     := NULL;
      i_if_line_rec(ln_rec_cnt).REASON_CODE                        := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_RATE                           := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_CODE                           := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_PRECEDENCE                     := NULL;
      i_if_line_rec(ln_rec_cnt).EXCEPTION_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).EXEMPTION_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).SHIP_DATE_ACTUAL                   := NULL;
      i_if_line_rec(ln_rec_cnt).FOB_POINT                          := NULL;
      i_if_line_rec(ln_rec_cnt).SHIP_VIA                           := NULL;
      i_if_line_rec(ln_rec_cnt).WAYBILL_NUMBER                     := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICING_RULE_NAME                := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICING_RULE_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_NAME               := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_DURATION           := NULL;
      i_if_line_rec(ln_rec_cnt).RULE_START_DATE                    := NULL;
      i_if_line_rec(ln_rec_cnt).PRIMARY_SALESREP_NUMBER            := NULL;
      i_if_line_rec(ln_rec_cnt).PRIMARY_SALESREP_ID                := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER                        := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_LINE                   := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_DATE                   := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_SOURCE                 := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_REVISION               := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER                     := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER_REVISION            := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER_DATE                := NULL;
-- ver 1.2 Change Start
--      i_if_line_rec(ln_rec_cnt).AGREEMENT_NAME                     := i_ar_tran_rec.COMMITMENT_NUMBER;
      i_if_line_rec(ln_rec_cnt).AGREEMENT_NAME                     := NULL;
-- ver 1.2 Change End
      i_if_line_rec(ln_rec_cnt).AGREEMENT_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).MEMO_LINE_NAME                     := NULL;
      i_if_line_rec(ln_rec_cnt).MEMO_LINE_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).INVENTORY_ITEM_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG1              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG2              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG3              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG4              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG5              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG6              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG7              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG8              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG9              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG10             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG11             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG12             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG13             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG14             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG15             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG16             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG17             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG18             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG19             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG20             := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ID                  := l_ref_line_id_line;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_CONTEXT             := l_ref_line_con;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE1          := l_ref_line_att1;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE2          := l_ref_line_att2;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE3          := l_ref_line_att3;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE4          := l_ref_line_att4;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE5          := l_ref_line_att5;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE6          := l_ref_line_att6_line;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE7          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE8          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE9          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE10         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE11         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE12         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE13         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE14         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE15         := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT1                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT2                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT3                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT4                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT5                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT6                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT7                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT8                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT9                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT10                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT11                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT12                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT13                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT14                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT15                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT16                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT17                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT18                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT19                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT20                := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE1                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE2                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE3                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE4                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE5                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE6                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE7                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE8                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE9                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE10                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE11                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE12                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE13                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE14                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE15                        := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE_CATEGORY          := in_org_id;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE1                  := i_ar_tran_rec.ONETIME_CUSTOMER_NAME;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE2                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_1;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE3                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_2;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE4                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_3;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE5                  := i_ar_tran_rec.ENTRY_DEPARTMENT;
      -- Ver11.5.10.1.4 2005/08/26 Change Start
      --i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE6                  := i_ar_tran_rec.EMPLOYEE_NUMBER;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE6                  := i_ar_tran_rec.USER_NAME;
      -- Ver11.5.10.1.4 2005/08/26 Change End
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE7                  := cv_attribute_7;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE8                  := cv_attribute_8;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE9                  := cv_attribute_9;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE10                 := i_ar_tran_rec.ONETIME_CUSTOMER_KANA_NAME;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE11                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE12                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE13                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE14                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE15                 := NULL;
      i_if_line_rec(ln_rec_cnt).COMMENTS                           := NULL;
      i_if_line_rec(ln_rec_cnt).INTERNAL_NOTES                     := NULL;
      i_if_line_rec(ln_rec_cnt).INITIAL_CUSTOMER_TRX_ID            := NULL;
      i_if_line_rec(ln_rec_cnt).USSGL_TRANSACTION_CODE_CONTEXT     := NULL;
      i_if_line_rec(ln_rec_cnt).USSGL_TRANSACTION_CODE             := NULL;
      i_if_line_rec(ln_rec_cnt).ACCTD_AMOUNT                       := NULL;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_BANK_ACCOUNT_ID           := NULL;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_BANK_ACCOUNT_NAME         := NULL;
      i_if_line_rec(ln_rec_cnt).UOM_CODE                           := l_get_rec_slip_lines_rec.SLIP_LINE_UOM;
      i_if_line_rec(ln_rec_cnt).UOM_NAME                           := NULL;
      i_if_line_rec(ln_rec_cnt).DOCUMENT_NUMBER_SEQUENCE_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).VAT_TAX_ID                         := l_get_rec_slip_lines_rec.TAX_ID;
      i_if_line_rec(ln_rec_cnt).REASON_CODE_MEANING                := NULL;
      i_if_line_rec(ln_rec_cnt).LAST_PERIOD_TO_CREDIT              := NULL;
      i_if_line_rec(ln_rec_cnt).PAYING_CUSTOMER_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).PAYING_SITE_USE_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_FLAG                    := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_REASON_CODE             := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_REASON_CODE_MEANING     := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_NUMBER                  := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_TAX_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).CREATED_BY                         := in_updated_by;
      i_if_line_rec(ln_rec_cnt).CREATION_DATE                      := i_ar_tran_rec.UPD_DATE;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATED_BY                    := in_updated_by;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATE_DATE                   := i_ar_tran_rec.UPD_DATE;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATE_LOGIN                  := in_update_login;
      i_if_line_rec(ln_rec_cnt).LOCATION_SEGMENT_ID                := NULL;
      i_if_line_rec(ln_rec_cnt).MOVEMENT_ID                        := NULL;
      i_if_line_rec(ln_rec_cnt).ORG_ID                             := in_org_id;
-- ver 1.1 Change Start
--      i_if_line_rec(ln_rec_cnt).AMOUNT_INCLUDES_TAX_FLAG           := NULL;
      i_if_line_rec(ln_rec_cnt).AMOUNT_INCLUDES_TAX_FLAG           := l_inc_tax_flg;
-- ver 1.1 Change End
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTR_CATEGORY           := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE1              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE2              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE3              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE4              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE5              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE6              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE7              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE8              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE9              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE10             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE11             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE12             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE13             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE14             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE15             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE16             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE17             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE18             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE19             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE20             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE21             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE22             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE23             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE24             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE25             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE26             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE27             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE28             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE29             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE30             := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTR_CATEGORY             := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE1                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE2                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE3                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE4                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE5                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE6                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE7                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE8                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE9                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE10               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE11               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE12               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE13               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE14               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE15               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE16               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE17               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE18               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE19               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE20               := NULL;
      i_if_line_rec(ln_rec_cnt).RESET_TRX_DATE_FLAG                := NULL;
      i_if_line_rec(ln_rec_cnt).PAYMENT_SERVER_ORDER_NUM           := NULL;
      i_if_line_rec(ln_rec_cnt).APPROVAL_CODE                      := NULL;
      i_if_line_rec(ln_rec_cnt).ADDRESS_VERIFICATION_CODE          := NULL;
      i_if_line_rec(ln_rec_cnt).WAREHOUSE_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).TRANSLATED_DESCRIPTION             := NULL;
      i_if_line_rec(ln_rec_cnt).CONS_BILLING_NUMBER                := NULL;
      i_if_line_rec(ln_rec_cnt).PROMISED_COMMITMENT_AMOUNT         := NULL;
      i_if_line_rec(ln_rec_cnt).PAYMENT_SET_ID                     := NULL;
      i_if_line_rec(ln_rec_cnt).ORIGINAL_GL_DATE                   := NULL;
      i_if_line_rec(ln_rec_cnt).CONTRACT_LINE_ID                   := NULL;
      i_if_line_rec(ln_rec_cnt).CONTRACT_ID                        := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY1                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY2                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY3                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY4                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY5                   := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICED_LINE_ACCTG_LEVEL          := NULL;
--
      IF (i_ar_tran_rec.ORIG_INVOICE_NUM Is NULL) THEN
        i_if_dist_rec(ln_rec_cnt).INTERFACE_DISTRIBUTION_ID          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ID                  := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_CONTEXT             := in_att_category;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE1          := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE2          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE3          := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE4          := i_ar_tran_rec.RECEIVABLE_NUM;
        -- ver 11.5.10.2.2 Chg Start
        --i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := l_get_rec_slip_lines_rec.LINE_NUMBER;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
        -- ver 11.5.10.2.2 Chg End
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE6          := cv_line_type_LINE;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE7          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE8          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE9          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE10         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE11         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE12         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE13         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE14         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE15         := NULL;
        i_if_dist_rec(ln_rec_cnt).ACCOUNT_CLASS                      := cv_acc_class_REV;
        i_if_dist_rec(ln_rec_cnt).AMOUNT                             := l_amount;
        i_if_dist_rec(ln_rec_cnt).PERCENT                            := cn_percent_100;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_STATUS                   := NULL;
        i_if_dist_rec(ln_rec_cnt).REQUEST_ID                         := NULL;
        i_if_dist_rec(ln_rec_cnt).CODE_COMBINATION_ID                := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT1                           := l_get_rec_slip_lines_rec.SEGMENT1;
        i_if_dist_rec(ln_rec_cnt).SEGMENT2                           := l_get_rec_slip_lines_rec.SEGMENT2;
        i_if_dist_rec(ln_rec_cnt).SEGMENT3                           := l_get_rec_slip_lines_rec.SEGMENT3;
        i_if_dist_rec(ln_rec_cnt).SEGMENT4                           := l_get_rec_slip_lines_rec.SEGMENT4;
        i_if_dist_rec(ln_rec_cnt).SEGMENT5                           := l_get_rec_slip_lines_rec.SEGMENT5;
        i_if_dist_rec(ln_rec_cnt).SEGMENT6                           := l_get_rec_slip_lines_rec.SEGMENT6;
        i_if_dist_rec(ln_rec_cnt).SEGMENT7                           := l_get_rec_slip_lines_rec.SEGMENT7;
        i_if_dist_rec(ln_rec_cnt).SEGMENT8                           := l_get_rec_slip_lines_rec.SEGMENT8;
        i_if_dist_rec(ln_rec_cnt).SEGMENT9                           := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT10                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT11                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT12                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT13                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT14                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT15                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT16                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT17                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT18                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT19                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT20                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT21                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT22                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT23                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT24                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT25                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT26                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT27                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT28                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT29                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT30                          := NULL;
        -- Ver11.5.10.1.5 2005/09/29 Change Start
        --i_if_dist_rec(ln_rec_cnt).COMMENTS                           := NULL;
        i_if_dist_rec(ln_rec_cnt).COMMENTS                           := l_get_rec_slip_lines_rec.JOURNAL_DESCRIPTION;
        -- Ver11.5.10.1.5 2005/09/29 Change End
-- ver 1.2 Change Start
--        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := l_get_rec_slip_lines_rec.ATTRIBUTE_CATEGORY;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := in_org_id;
-- ver 1.2 Change End
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE1                         := l_get_rec_slip_lines_rec.INCR_DECR_REASON_CODE;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE2                         := l_get_rec_slip_lines_rec.RECON_REFERENCE;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE3                         := l_get_rec_slip_lines_rec.ATTRIBUTE1;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE4                         := l_get_rec_slip_lines_rec.ATTRIBUTE2;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE5                         := l_get_rec_slip_lines_rec.ATTRIBUTE3;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE6                         := l_get_rec_slip_lines_rec.ATTRIBUTE4;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE7                         := l_get_rec_slip_lines_rec.ATTRIBUTE5;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE8                         := l_get_rec_slip_lines_rec.ATTRIBUTE6;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE9                         := l_get_rec_slip_lines_rec.ATTRIBUTE7;
--Ver11.5.10.2.11 mod start
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := i_ar_tran_rec.PAYMENT_ELE_DATA_YES;
--        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := l_get_rec_slip_lines_rec.ATTRIBUTE8;
--Ver11.5.10.2.11 mod end
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE11                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE12                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE13                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE14                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE15                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ACCTD_AMOUNT                       := NULL;
        i_if_dist_rec(ln_rec_cnt).CREATED_BY                         := in_updated_by;
        i_if_dist_rec(ln_rec_cnt).CREATION_DATE                      := i_ar_tran_rec.UPD_DATE;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATED_BY                    := in_updated_by;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_DATE                   := i_ar_tran_rec.UPD_DATE;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_LOGIN                  := in_update_login;
        i_if_dist_rec(ln_rec_cnt).ORG_ID                             := in_org_id;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_CCID                   := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT1               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT2               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT3               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT4               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT5               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT6               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT7               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT8               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT9               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT10              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT11              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT12              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT13              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT14              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT15              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT16              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT17              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT18              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT19              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT20              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT21              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT22              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT23              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT24              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT25              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT26              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT27              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT28              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT29              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT30              := NULL;
      END IF;
--
      ln_rec_cnt := ln_rec_cnt + 1;
--
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_CONTEXT             := in_att_category;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE1          := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE2          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE3          := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE4          := i_ar_tran_rec.RECEIVABLE_NUM;
      -- ver 11.5.10.2.2 Chg Start
      --i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := l_get_rec_slip_lines_rec.LINE_NUMBER;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
      -- ver 11.5.10.2.2 Chg End
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE6          := cv_line_type_TAX;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE7          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE8          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE9          := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE10         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE11         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE12         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE13         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE14         := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE15         := NULL;
      i_if_line_rec(ln_rec_cnt).BATCH_SOURCE_NAME                  := iv_source;
      i_if_line_rec(ln_rec_cnt).SET_OF_BOOKS_ID                    := in_books_id;
      i_if_line_rec(ln_rec_cnt).LINE_TYPE                          := cv_line_type_TAX;
      i_if_line_rec(ln_rec_cnt).DESCRIPTION                        := l_get_rec_slip_lines_rec.SLIP_LINE_TYPE_NAME;
      i_if_line_rec(ln_rec_cnt).CURRENCY_CODE                      := i_ar_tran_rec.INVOICE_CURRENCY_CODE;
      i_if_line_rec(ln_rec_cnt).AMOUNT                             := l_get_rec_slip_lines_rec.ENTERED_TAX_AMOUNT;
      i_if_line_rec(ln_rec_cnt).CUST_TRX_TYPE_NAME                 := NULL;
      i_if_line_rec(ln_rec_cnt).CUST_TRX_TYPE_ID                   := i_ar_tran_rec.TRANS_TYPE_ID;
      i_if_line_rec(ln_rec_cnt).TERM_NAME                          := NULL;
      i_if_line_rec(ln_rec_cnt).TERM_ID                            := l_term_id;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BATCH_NAME             := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CUSTOMER_ID       := i_ar_tran_rec.CUSTOMER_ID;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_ADDRESS_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_ADDRESS_ID        := i_ar_tran_rec.CUSTOMER_OFFICE_ID;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CONTACT_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_BILL_CONTACT_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_ID       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_ADDRESS_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_ADDRESS_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CONTACT_REF       := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SHIP_CONTACT_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_REF      := NULL;
      i_if_line_rec(ln_rec_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_ID       := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ID                    := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_CONTEXT               := in_att_category;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE1            := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE2            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE3            := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE4            := i_ar_tran_rec.RECEIVABLE_NUM;
      -- ver 11.5.10.2.2 Chg Start
      --i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE5            := l_get_rec_slip_lines_rec.LINE_NUMBER;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE5            := to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
      -- ver 11.5.10.2.2 Chg End
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE6            := cv_line_type_LINE;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE7            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE8            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE9            := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE10           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE11           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE12           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE13           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE14           := NULL;
      i_if_line_rec(ln_rec_cnt).LINK_TO_LINE_ATTRIBUTE15           := NULL;
      i_if_line_rec(ln_rec_cnt).RECEIPT_METHOD_NAME                := NULL;
      i_if_line_rec(ln_rec_cnt).RECEIPT_METHOD_ID                  := l_receipt_id_tax;
      i_if_line_rec(ln_rec_cnt).CONVERSION_TYPE                    := l_conv_type;
      i_if_line_rec(ln_rec_cnt).CONVERSION_DATE                    := l_conv_date;
      i_if_line_rec(ln_rec_cnt).CONVERSION_RATE                    := l_conv_rate;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_TRX_ID                    := NULL;
      i_if_line_rec(ln_rec_cnt).TRX_DATE                           := i_ar_tran_rec.INVOICE_DATE;
      i_if_line_rec(ln_rec_cnt).GL_DATE                            := i_ar_tran_rec.GL_DATE;
      i_if_line_rec(ln_rec_cnt).DOCUMENT_NUMBER                    := NULL;
      i_if_line_rec(ln_rec_cnt).TRX_NUMBER                         := i_ar_tran_rec.RECEIVABLE_NUM;
      i_if_line_rec(ln_rec_cnt).LINE_NUMBER                        := NULL;
      i_if_line_rec(ln_rec_cnt).QUANTITY                           := NULL;
      i_if_line_rec(ln_rec_cnt).QUANTITY_ORDERED                   := NULL;
      i_if_line_rec(ln_rec_cnt).UNIT_SELLING_PRICE                 := NULL;
      i_if_line_rec(ln_rec_cnt).UNIT_STANDARD_PRICE                := NULL;
      i_if_line_rec(ln_rec_cnt).PRINTING_OPTION                    := NULL;
      i_if_line_rec(ln_rec_cnt).INTERFACE_STATUS                   := NULL;
      i_if_line_rec(ln_rec_cnt).REQUEST_ID                         := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_BATCH_SOURCE_NAME          := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_TRX_NUMBER                 := NULL;
      i_if_line_rec(ln_rec_cnt).RELATED_CUSTOMER_TRX_ID            := NULL;
      i_if_line_rec(ln_rec_cnt).PREVIOUS_CUSTOMER_TRX_ID           := NULL;
      i_if_line_rec(ln_rec_cnt).CREDIT_METHOD_FOR_ACCT_RULE        := NULL;
      i_if_line_rec(ln_rec_cnt).CREDIT_METHOD_FOR_INSTALLMENTS     := NULL;
      i_if_line_rec(ln_rec_cnt).REASON_CODE                        := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_RATE                           := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_CODE                           := l_get_rec_slip_lines_rec.TAX_CODE;
      i_if_line_rec(ln_rec_cnt).TAX_PRECEDENCE                     := NULL;
      i_if_line_rec(ln_rec_cnt).EXCEPTION_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).EXEMPTION_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).SHIP_DATE_ACTUAL                   := NULL;
      i_if_line_rec(ln_rec_cnt).FOB_POINT                          := NULL;
      i_if_line_rec(ln_rec_cnt).SHIP_VIA                           := NULL;
      i_if_line_rec(ln_rec_cnt).WAYBILL_NUMBER                     := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICING_RULE_NAME                := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICING_RULE_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_NAME               := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).ACCOUNTING_RULE_DURATION           := NULL;
      i_if_line_rec(ln_rec_cnt).RULE_START_DATE                    := NULL;
      i_if_line_rec(ln_rec_cnt).PRIMARY_SALESREP_NUMBER            := NULL;
      i_if_line_rec(ln_rec_cnt).PRIMARY_SALESREP_ID                := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER                        := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_LINE                   := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_DATE                   := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_SOURCE                 := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_ORDER_REVISION               := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER                     := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER_REVISION            := NULL;
      i_if_line_rec(ln_rec_cnt).PURCHASE_ORDER_DATE                := NULL;
-- ver 1.2 Change Start
--      i_if_line_rec(ln_rec_cnt).AGREEMENT_NAME                     := i_ar_tran_rec.COMMITMENT_NUMBER;
      i_if_line_rec(ln_rec_cnt).AGREEMENT_NAME                     := NULL;
-- ver 1.2 Change End
      i_if_line_rec(ln_rec_cnt).AGREEMENT_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).MEMO_LINE_NAME                     := NULL;
      i_if_line_rec(ln_rec_cnt).MEMO_LINE_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).INVENTORY_ITEM_ID                  := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG1              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG2              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG3              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG4              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG5              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG6              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG7              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG8              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG9              := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG10             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG11             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG12             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG13             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG14             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG15             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG16             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG17             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG18             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG19             := NULL;
      i_if_line_rec(ln_rec_cnt).MTL_SYSTEM_ITEMS_SEG20             := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ID                  := l_ref_line_id_tax;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_CONTEXT             := l_ref_line_con;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE1          := l_ref_line_att1;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE2          := l_ref_line_att2;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE3          := l_ref_line_att3;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE4          := l_ref_line_att4;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE5          := l_ref_line_att5;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE6          := l_ref_line_att6_tax;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE7          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE8          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE9          := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE10         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE11         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE12         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE13         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE14         := NULL;
      i_if_line_rec(ln_rec_cnt).REFERENCE_LINE_ATTRIBUTE15         := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT1                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT2                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT3                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT4                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT5                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT6                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT7                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT8                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT9                 := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT10                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT11                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT12                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT13                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT14                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT15                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT16                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT17                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT18                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT19                := NULL;
      i_if_line_rec(ln_rec_cnt).TERRITORY_SEGMENT20                := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE1                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE2                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE3                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE4                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE5                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE6                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE7                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE8                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE9                         := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE10                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE11                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE12                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE13                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE14                        := NULL;
      i_if_line_rec(ln_rec_cnt).ATTRIBUTE15                        := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE_CATEGORY          := in_org_id;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE1                  := i_ar_tran_rec.ONETIME_CUSTOMER_NAME;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE2                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_1;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE3                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_2;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE4                  := i_ar_tran_rec.ONETIME_CUSTOMER_ADDRESS_3;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE5                  := i_ar_tran_rec.ENTRY_DEPARTMENT;
      -- Ver11.5.10.1.4 2005/08/26 Change Start
      --i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE6                  := i_ar_tran_rec.EMPLOYEE_NUMBER;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE6                  := i_ar_tran_rec.USER_NAME;
      -- Ver11.5.10.1.4 2005/08/26 Change End
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE7                  := cv_attribute_7;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE8                  := cv_attribute_8;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE9                  := cv_attribute_9;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE10                 := i_ar_tran_rec.ONETIME_CUSTOMER_KANA_NAME;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE11                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE12                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE13                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE14                 := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_ATTRIBUTE15                 := NULL;
      i_if_line_rec(ln_rec_cnt).COMMENTS                           := NULL;
      i_if_line_rec(ln_rec_cnt).INTERNAL_NOTES                     := NULL;
      i_if_line_rec(ln_rec_cnt).INITIAL_CUSTOMER_TRX_ID            := NULL;
      i_if_line_rec(ln_rec_cnt).USSGL_TRANSACTION_CODE_CONTEXT     := NULL;
      i_if_line_rec(ln_rec_cnt).USSGL_TRANSACTION_CODE             := NULL;
      i_if_line_rec(ln_rec_cnt).ACCTD_AMOUNT                       := NULL;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_BANK_ACCOUNT_ID           := NULL;
      i_if_line_rec(ln_rec_cnt).CUSTOMER_BANK_ACCOUNT_NAME         := NULL;
      i_if_line_rec(ln_rec_cnt).UOM_CODE                           := NULL;
      i_if_line_rec(ln_rec_cnt).UOM_NAME                           := NULL;
      i_if_line_rec(ln_rec_cnt).DOCUMENT_NUMBER_SEQUENCE_ID        := NULL;
      i_if_line_rec(ln_rec_cnt).VAT_TAX_ID                         := l_get_rec_slip_lines_rec.TAX_ID;
      i_if_line_rec(ln_rec_cnt).REASON_CODE_MEANING                := NULL;
      i_if_line_rec(ln_rec_cnt).LAST_PERIOD_TO_CREDIT              := NULL;
      i_if_line_rec(ln_rec_cnt).PAYING_CUSTOMER_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).PAYING_SITE_USE_ID                 := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_FLAG                    := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_REASON_CODE             := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_REASON_CODE_MEANING     := NULL;
      i_if_line_rec(ln_rec_cnt).TAX_EXEMPT_NUMBER                  := NULL;
      i_if_line_rec(ln_rec_cnt).SALES_TAX_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).CREATED_BY                         := in_updated_by;
      i_if_line_rec(ln_rec_cnt).CREATION_DATE                      := i_ar_tran_rec.UPD_DATE;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATED_BY                    := in_updated_by;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATE_DATE                   := i_ar_tran_rec.UPD_DATE;
      i_if_line_rec(ln_rec_cnt).LAST_UPDATE_LOGIN                  := in_update_login;
      i_if_line_rec(ln_rec_cnt).LOCATION_SEGMENT_ID                := NULL;
      i_if_line_rec(ln_rec_cnt).MOVEMENT_ID                        := NULL;
      i_if_line_rec(ln_rec_cnt).ORG_ID                             := in_org_id;
      i_if_line_rec(ln_rec_cnt).AMOUNT_INCLUDES_TAX_FLAG           := l_inc_tax_flg;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTR_CATEGORY           := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE1              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE2              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE3              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE4              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE5              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE6              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE7              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE8              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE9              := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE10             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE11             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE12             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE13             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE14             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE15             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE16             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE17             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE18             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE19             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE20             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE21             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE22             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE23             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE24             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE25             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE26             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE27             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE28             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE29             := NULL;
      i_if_line_rec(ln_rec_cnt).HEADER_GDF_ATTRIBUTE30             := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTR_CATEGORY             := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE1                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE2                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE3                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE4                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE5                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE6                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE7                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE8                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE9                := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE10               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE11               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE12               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE13               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE14               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE15               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE16               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE17               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE18               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE19               := NULL;
      i_if_line_rec(ln_rec_cnt).LINE_GDF_ATTRIBUTE20               := NULL;
      i_if_line_rec(ln_rec_cnt).RESET_TRX_DATE_FLAG                := NULL;
      i_if_line_rec(ln_rec_cnt).PAYMENT_SERVER_ORDER_NUM           := NULL;
      i_if_line_rec(ln_rec_cnt).APPROVAL_CODE                      := NULL;
      i_if_line_rec(ln_rec_cnt).ADDRESS_VERIFICATION_CODE          := NULL;
      i_if_line_rec(ln_rec_cnt).WAREHOUSE_ID                       := NULL;
      i_if_line_rec(ln_rec_cnt).TRANSLATED_DESCRIPTION             := NULL;
      i_if_line_rec(ln_rec_cnt).CONS_BILLING_NUMBER                := NULL;
      i_if_line_rec(ln_rec_cnt).PROMISED_COMMITMENT_AMOUNT         := NULL;
      i_if_line_rec(ln_rec_cnt).PAYMENT_SET_ID                     := NULL;
      i_if_line_rec(ln_rec_cnt).ORIGINAL_GL_DATE                   := NULL;
      i_if_line_rec(ln_rec_cnt).CONTRACT_LINE_ID                   := NULL;
      i_if_line_rec(ln_rec_cnt).CONTRACT_ID                        := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY1                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY2                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY3                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY4                   := NULL;
      i_if_line_rec(ln_rec_cnt).SOURCE_DATA_KEY5                   := NULL;
      i_if_line_rec(ln_rec_cnt).INVOICED_LINE_ACCTG_LEVEL          := NULL;
--
      IF (i_ar_tran_rec.ORIG_INVOICE_NUM Is NULL) THEN
        i_if_dist_rec(ln_rec_cnt).INTERFACE_DISTRIBUTION_ID          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ID                  := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_CONTEXT             := in_att_category;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE1          := l_get_rec_slip_lines_rec.SLIP_DESCRIPTION;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE2          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE3          := l_get_rec_slip_lines_rec.SLIP_LINE_RECIEPT_NO;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE4          := i_ar_tran_rec.RECEIVABLE_NUM;
        -- ver 11.5.10.2.2 Chg Start
        --i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := l_get_rec_slip_lines_rec.LINE_NUMBER;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := to_char(l_get_rec_slip_lines_rec.LINE_NUMBER,'FM099999999999999');
        -- ver 11.5.10.2.2 Chg End
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE6          := cv_line_type_TAX;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE7          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE8          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE9          := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE10         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE11         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE12         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE13         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE14         := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE15         := NULL;
        i_if_dist_rec(ln_rec_cnt).ACCOUNT_CLASS                      := cv_acc_class_TAX;
        i_if_dist_rec(ln_rec_cnt).AMOUNT                             := l_get_rec_slip_lines_rec.ENTERED_TAX_AMOUNT;
        i_if_dist_rec(ln_rec_cnt).PERCENT                            := cn_percent_100;
        i_if_dist_rec(ln_rec_cnt).INTERFACE_STATUS                   := NULL;
        i_if_dist_rec(ln_rec_cnt).REQUEST_ID                         := NULL;
        i_if_dist_rec(ln_rec_cnt).CODE_COMBINATION_ID                := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT1                           := l_get_rec_slip_lines_rec.TAX_SEG1;
        i_if_dist_rec(ln_rec_cnt).SEGMENT2                           := l_get_rec_slip_lines_rec.TAX_SEG2;
        i_if_dist_rec(ln_rec_cnt).SEGMENT3                           := l_get_rec_slip_lines_rec.TAX_SEG3;
        i_if_dist_rec(ln_rec_cnt).SEGMENT4                           := l_get_rec_slip_lines_rec.TAX_SEG4;
        i_if_dist_rec(ln_rec_cnt).SEGMENT5                           := l_get_rec_slip_lines_rec.TAX_SEG5;
        i_if_dist_rec(ln_rec_cnt).SEGMENT6                           := l_get_rec_slip_lines_rec.TAX_SEG6;
        i_if_dist_rec(ln_rec_cnt).SEGMENT7                           := l_get_rec_slip_lines_rec.TAX_SEG7;
        i_if_dist_rec(ln_rec_cnt).SEGMENT8                           := l_get_rec_slip_lines_rec.TAX_SEG8;
        i_if_dist_rec(ln_rec_cnt).SEGMENT9                           := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT10                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT11                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT12                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT13                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT14                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT15                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT16                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT17                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT18                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT19                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT20                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT21                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT22                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT23                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT24                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT25                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT26                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT27                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT28                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT29                          := NULL;
        i_if_dist_rec(ln_rec_cnt).SEGMENT30                          := NULL;
        i_if_dist_rec(ln_rec_cnt).COMMENTS                           := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE1                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE2                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE3                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE4                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE5                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE6                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE7                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE8                         := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE9                         := NULL;
--Ver11.5.10.2.11 mod start
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := i_ar_tran_rec.PAYMENT_ELE_DATA_YES;
--        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := NULL;
--Ver11.5.10.2.11 mod end
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE11                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE12                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE13                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE14                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ATTRIBUTE15                        := NULL;
        i_if_dist_rec(ln_rec_cnt).ACCTD_AMOUNT                       := NULL;
        i_if_dist_rec(ln_rec_cnt).CREATED_BY                         := in_updated_by;
        i_if_dist_rec(ln_rec_cnt).CREATION_DATE                      := i_ar_tran_rec.UPD_DATE;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATED_BY                    := in_updated_by;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_DATE                   := i_ar_tran_rec.UPD_DATE;
        i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_LOGIN                  := in_update_login;
        i_if_dist_rec(ln_rec_cnt).ORG_ID                             := in_org_id;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_CCID                   := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT1               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT2               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT3               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT4               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT5               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT6               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT7               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT8               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT9               := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT10              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT11              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT12              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT13              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT14              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT15              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT16              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT17              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT18              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT19              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT20              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT21              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT22              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT23              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT24              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT25              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT26              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT27              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT28              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT29              := NULL;
        i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT30              := NULL;
      END IF;
    END LOOP get_ar_lines_loop;
    CLOSE get_rec_slip_lines_cur;
--
    IF (i_ar_tran_rec.ORIG_INVOICE_NUM Is NULL) THEN
      ln_rec_cnt := ln_rec_cnt + 1;
--
      i_if_dist_rec(ln_rec_cnt).INTERFACE_DISTRIBUTION_ID          := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ID                  := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_CONTEXT             := in_att_category;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE1          := l_first_SLIP_DESCRIPTION;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE2          := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE3          := l_first_SLIP_LINE_RECIEPT_NO;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE4          := i_ar_tran_rec.RECEIVABLE_NUM;
      -- ver 11.5.10.2.2 Chg Start
      --i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := l_first_LINE_NUMBER;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE5          := to_char(l_first_LINE_NUMBER,'FM099999999999999');
      -- ver 11.5.10.2.2 Chg End
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE6          := cv_line_type_LINE;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE7          := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE8          := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE9          := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE10         := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE11         := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE12         := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE13         := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE14         := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_LINE_ATTRIBUTE15         := NULL;
      i_if_dist_rec(ln_rec_cnt).ACCOUNT_CLASS                      := cv_acc_class_REC;
      i_if_dist_rec(ln_rec_cnt).AMOUNT                             := NULL;
      i_if_dist_rec(ln_rec_cnt).PERCENT                            := cn_percent_100;
      i_if_dist_rec(ln_rec_cnt).INTERFACE_STATUS                   := NULL;
      i_if_dist_rec(ln_rec_cnt).REQUEST_ID                         := NULL;
      i_if_dist_rec(ln_rec_cnt).CODE_COMBINATION_ID                := NULL; --i_ar_tran_rec.REC_CODE_COMB_ID;
      i_if_dist_rec(ln_rec_cnt).SEGMENT1                           := i_ar_tran_rec.REC_SEG1;
      i_if_dist_rec(ln_rec_cnt).SEGMENT2                           := i_ar_tran_rec.REC_SEG2;
      i_if_dist_rec(ln_rec_cnt).SEGMENT3                           := i_ar_tran_rec.REC_SEG3;
      i_if_dist_rec(ln_rec_cnt).SEGMENT4                           := i_ar_tran_rec.REC_SEG4;
      i_if_dist_rec(ln_rec_cnt).SEGMENT5                           := i_ar_tran_rec.REC_SEG5;
      i_if_dist_rec(ln_rec_cnt).SEGMENT6                           := i_ar_tran_rec.REC_SEG6;
      i_if_dist_rec(ln_rec_cnt).SEGMENT7                           := i_ar_tran_rec.REC_SEG7;
      i_if_dist_rec(ln_rec_cnt).SEGMENT8                           := i_ar_tran_rec.REC_SEG8;
      i_if_dist_rec(ln_rec_cnt).SEGMENT9                           := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT10                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT11                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT12                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT13                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT14                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT15                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT16                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT17                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT18                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT19                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT20                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT21                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT22                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT23                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT24                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT25                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT26                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT27                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT28                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT29                          := NULL;
      i_if_dist_rec(ln_rec_cnt).SEGMENT30                          := NULL;
      -- Ver11.5.10.1.5 2005/09/29 Change Start
      --i_if_dist_rec(ln_rec_cnt).COMMENTS                           := NULL;
      i_if_dist_rec(ln_rec_cnt).COMMENTS                           := i_ar_tran_rec.DESCRIPTION;      --備考
      -- Ver11.5.10.1.5 2005/09/29 Change End
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE_CATEGORY                 := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE1                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE2                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE3                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE4                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE5                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE6                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE7                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE8                         := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE9                         := NULL;
--Ver11.5.10.2.11 mod start
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := i_ar_tran_rec.PAYMENT_ELE_DATA_YES;
--      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE10                        := NULL;
--Ver11.5.10.2.11 mod end
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE11                        := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE12                        := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE13                        := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE14                        := NULL;
      i_if_dist_rec(ln_rec_cnt).ATTRIBUTE15                        := NULL;
      i_if_dist_rec(ln_rec_cnt).ACCTD_AMOUNT                       := NULL;
      i_if_dist_rec(ln_rec_cnt).CREATED_BY                         := in_updated_by;
      i_if_dist_rec(ln_rec_cnt).CREATION_DATE                      := i_ar_tran_rec.UPD_DATE;
      i_if_dist_rec(ln_rec_cnt).LAST_UPDATED_BY                    := in_updated_by;
      i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_DATE                   := i_ar_tran_rec.UPD_DATE;
      i_if_dist_rec(ln_rec_cnt).LAST_UPDATE_LOGIN                  := in_update_login;
      i_if_dist_rec(ln_rec_cnt).ORG_ID                             := in_org_id;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_CCID                   := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT1               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT2               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT3               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT4               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT5               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT6               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT7               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT8               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT9               := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT10              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT11              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT12              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT13              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT14              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT15              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT16              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT17              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT18              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT19              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT20              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT21              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT22              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT23              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT24              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT25              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT26              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT27              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT28              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT29              := NULL;
      i_if_dist_rec(ln_rec_cnt).INTERIM_TAX_SEGMENT30              := NULL;
    END IF;
--
    on_detail_cnt := ln_detail_cnt;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END ar_if_invoice_set;
--
  /**********************************************************************************
   * Procedure Name   : ar_if_for_invoice
   * Description      : OPEN_IF_TABLEへの登録［請求依頼］ (A-2)
   ***********************************************************************************/
  PROCEDURE ar_if_for_invoice(
    i_if_line_rec                IN  trx_if_line_type,                -- 1.RA_IF_レコード LINE(IN)
    i_if_dist_rec                IN  trx_if_dist_type,                -- 2.RA_IF_レコード DIST(IN)
    ov_errbuf                    OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode                   OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg                    OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ar_if_for_invoice'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_loop_cnt  NUMBER := 0;     -- ループカウント
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- IF_LINEテーブル型変数を実テーブルへ挿入
    FOR ln_loop_cnt IN 1..i_if_line_rec.COUNT LOOP
--
      INSERT INTO RA_INTERFACE_LINES_ALL (
          INTERFACE_LINE_ID
        , INTERFACE_LINE_CONTEXT
        , INTERFACE_LINE_ATTRIBUTE1
        , INTERFACE_LINE_ATTRIBUTE2
        , INTERFACE_LINE_ATTRIBUTE3
        , INTERFACE_LINE_ATTRIBUTE4
        , INTERFACE_LINE_ATTRIBUTE5
        , INTERFACE_LINE_ATTRIBUTE6
        , INTERFACE_LINE_ATTRIBUTE7
        , INTERFACE_LINE_ATTRIBUTE8
        , INTERFACE_LINE_ATTRIBUTE9
        , INTERFACE_LINE_ATTRIBUTE10
        , INTERFACE_LINE_ATTRIBUTE11
        , INTERFACE_LINE_ATTRIBUTE12
        , INTERFACE_LINE_ATTRIBUTE13
        , INTERFACE_LINE_ATTRIBUTE14
        , INTERFACE_LINE_ATTRIBUTE15
        , BATCH_SOURCE_NAME
        , SET_OF_BOOKS_ID
        , LINE_TYPE
        , DESCRIPTION
        , CURRENCY_CODE
        , AMOUNT
        , CUST_TRX_TYPE_NAME
        , CUST_TRX_TYPE_ID
        , TERM_NAME
        , TERM_ID
        , ORIG_SYSTEM_BATCH_NAME
        , ORIG_SYSTEM_BILL_CUSTOMER_REF
        , ORIG_SYSTEM_BILL_CUSTOMER_ID
        , ORIG_SYSTEM_BILL_ADDRESS_REF
        , ORIG_SYSTEM_BILL_ADDRESS_ID
        , ORIG_SYSTEM_BILL_CONTACT_REF
        , ORIG_SYSTEM_BILL_CONTACT_ID
        , ORIG_SYSTEM_SHIP_CUSTOMER_REF
        , ORIG_SYSTEM_SHIP_CUSTOMER_ID
        , ORIG_SYSTEM_SHIP_ADDRESS_REF
        , ORIG_SYSTEM_SHIP_ADDRESS_ID
        , ORIG_SYSTEM_SHIP_CONTACT_REF
        , ORIG_SYSTEM_SHIP_CONTACT_ID
        , ORIG_SYSTEM_SOLD_CUSTOMER_REF
        , ORIG_SYSTEM_SOLD_CUSTOMER_ID
        , LINK_TO_LINE_ID
        , LINK_TO_LINE_CONTEXT
        , LINK_TO_LINE_ATTRIBUTE1
        , LINK_TO_LINE_ATTRIBUTE2
        , LINK_TO_LINE_ATTRIBUTE3
        , LINK_TO_LINE_ATTRIBUTE4
        , LINK_TO_LINE_ATTRIBUTE5
        , LINK_TO_LINE_ATTRIBUTE6
        , LINK_TO_LINE_ATTRIBUTE7
        , LINK_TO_LINE_ATTRIBUTE8
        , LINK_TO_LINE_ATTRIBUTE9
        , LINK_TO_LINE_ATTRIBUTE10
        , LINK_TO_LINE_ATTRIBUTE11
        , LINK_TO_LINE_ATTRIBUTE12
        , LINK_TO_LINE_ATTRIBUTE13
        , LINK_TO_LINE_ATTRIBUTE14
        , LINK_TO_LINE_ATTRIBUTE15
        , RECEIPT_METHOD_NAME
        , RECEIPT_METHOD_ID
        , CONVERSION_TYPE
        , CONVERSION_DATE
        , CONVERSION_RATE
        , CUSTOMER_TRX_ID
        , TRX_DATE
        , GL_DATE
        , DOCUMENT_NUMBER
        , TRX_NUMBER
        , LINE_NUMBER
        , QUANTITY
        , QUANTITY_ORDERED
        , UNIT_SELLING_PRICE
        , UNIT_STANDARD_PRICE
        , PRINTING_OPTION
        , INTERFACE_STATUS
        , REQUEST_ID
        , RELATED_BATCH_SOURCE_NAME
        , RELATED_TRX_NUMBER
        , RELATED_CUSTOMER_TRX_ID
        , PREVIOUS_CUSTOMER_TRX_ID
        , CREDIT_METHOD_FOR_ACCT_RULE
        , CREDIT_METHOD_FOR_INSTALLMENTS
        , REASON_CODE
        , TAX_RATE
        , TAX_CODE
        , TAX_PRECEDENCE
        , EXCEPTION_ID
        , EXEMPTION_ID
        , SHIP_DATE_ACTUAL
        , FOB_POINT
        , SHIP_VIA
        , WAYBILL_NUMBER
        , INVOICING_RULE_NAME
        , INVOICING_RULE_ID
        , ACCOUNTING_RULE_NAME
        , ACCOUNTING_RULE_ID
        , ACCOUNTING_RULE_DURATION
        , RULE_START_DATE
        , PRIMARY_SALESREP_NUMBER
        , PRIMARY_SALESREP_ID
        , SALES_ORDER
        , SALES_ORDER_LINE
        , SALES_ORDER_DATE
        , SALES_ORDER_SOURCE
        , SALES_ORDER_REVISION
        , PURCHASE_ORDER
        , PURCHASE_ORDER_REVISION
        , PURCHASE_ORDER_DATE
        , AGREEMENT_NAME
        , AGREEMENT_ID
        , MEMO_LINE_NAME
        , MEMO_LINE_ID
        , INVENTORY_ITEM_ID
        , MTL_SYSTEM_ITEMS_SEG1
        , MTL_SYSTEM_ITEMS_SEG2
        , MTL_SYSTEM_ITEMS_SEG3
        , MTL_SYSTEM_ITEMS_SEG4
        , MTL_SYSTEM_ITEMS_SEG5
        , MTL_SYSTEM_ITEMS_SEG6
        , MTL_SYSTEM_ITEMS_SEG7
        , MTL_SYSTEM_ITEMS_SEG8
        , MTL_SYSTEM_ITEMS_SEG9
        , MTL_SYSTEM_ITEMS_SEG10
        , MTL_SYSTEM_ITEMS_SEG11
        , MTL_SYSTEM_ITEMS_SEG12
        , MTL_SYSTEM_ITEMS_SEG13
        , MTL_SYSTEM_ITEMS_SEG14
        , MTL_SYSTEM_ITEMS_SEG15
        , MTL_SYSTEM_ITEMS_SEG16
        , MTL_SYSTEM_ITEMS_SEG17
        , MTL_SYSTEM_ITEMS_SEG18
        , MTL_SYSTEM_ITEMS_SEG19
        , MTL_SYSTEM_ITEMS_SEG20
        , REFERENCE_LINE_ID
        , REFERENCE_LINE_CONTEXT
        , REFERENCE_LINE_ATTRIBUTE1
        , REFERENCE_LINE_ATTRIBUTE2
        , REFERENCE_LINE_ATTRIBUTE3
        , REFERENCE_LINE_ATTRIBUTE4
        , REFERENCE_LINE_ATTRIBUTE5
        , REFERENCE_LINE_ATTRIBUTE6
        , REFERENCE_LINE_ATTRIBUTE7
        , REFERENCE_LINE_ATTRIBUTE8
        , REFERENCE_LINE_ATTRIBUTE9
        , REFERENCE_LINE_ATTRIBUTE10
        , REFERENCE_LINE_ATTRIBUTE11
        , REFERENCE_LINE_ATTRIBUTE12
        , REFERENCE_LINE_ATTRIBUTE13
        , REFERENCE_LINE_ATTRIBUTE14
        , REFERENCE_LINE_ATTRIBUTE15
        , TERRITORY_ID
        , TERRITORY_SEGMENT1
        , TERRITORY_SEGMENT2
        , TERRITORY_SEGMENT3
        , TERRITORY_SEGMENT4
        , TERRITORY_SEGMENT5
        , TERRITORY_SEGMENT6
        , TERRITORY_SEGMENT7
        , TERRITORY_SEGMENT8
        , TERRITORY_SEGMENT9
        , TERRITORY_SEGMENT10
        , TERRITORY_SEGMENT11
        , TERRITORY_SEGMENT12
        , TERRITORY_SEGMENT13
        , TERRITORY_SEGMENT14
        , TERRITORY_SEGMENT15
        , TERRITORY_SEGMENT16
        , TERRITORY_SEGMENT17
        , TERRITORY_SEGMENT18
        , TERRITORY_SEGMENT19
        , TERRITORY_SEGMENT20
        , ATTRIBUTE_CATEGORY
        , ATTRIBUTE1
        , ATTRIBUTE2
        , ATTRIBUTE3
        , ATTRIBUTE4
        , ATTRIBUTE5
        , ATTRIBUTE6
        , ATTRIBUTE7
        , ATTRIBUTE8
        , ATTRIBUTE9
        , ATTRIBUTE10
        , ATTRIBUTE11
        , ATTRIBUTE12
        , ATTRIBUTE13
        , ATTRIBUTE14
        , ATTRIBUTE15
        , HEADER_ATTRIBUTE_CATEGORY
        , HEADER_ATTRIBUTE1
        , HEADER_ATTRIBUTE2
        , HEADER_ATTRIBUTE3
        , HEADER_ATTRIBUTE4
        , HEADER_ATTRIBUTE5
        , HEADER_ATTRIBUTE6
        , HEADER_ATTRIBUTE7
        , HEADER_ATTRIBUTE8
        , HEADER_ATTRIBUTE9
        , HEADER_ATTRIBUTE10
        , HEADER_ATTRIBUTE11
        , HEADER_ATTRIBUTE12
        , HEADER_ATTRIBUTE13
        , HEADER_ATTRIBUTE14
        , HEADER_ATTRIBUTE15
        , COMMENTS
        , INTERNAL_NOTES
        , INITIAL_CUSTOMER_TRX_ID
        , USSGL_TRANSACTION_CODE_CONTEXT
        , USSGL_TRANSACTION_CODE
        , ACCTD_AMOUNT
        , CUSTOMER_BANK_ACCOUNT_ID
        , CUSTOMER_BANK_ACCOUNT_NAME
        , UOM_CODE
        , UOM_NAME
        , DOCUMENT_NUMBER_SEQUENCE_ID
        , VAT_TAX_ID
        , REASON_CODE_MEANING
        , LAST_PERIOD_TO_CREDIT
        , PAYING_CUSTOMER_ID
        , PAYING_SITE_USE_ID
        , TAX_EXEMPT_FLAG
        , TAX_EXEMPT_REASON_CODE
        , TAX_EXEMPT_REASON_CODE_MEANING
        , TAX_EXEMPT_NUMBER
        , SALES_TAX_ID
        , CREATED_BY
        , CREATION_DATE
        , LAST_UPDATED_BY
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , LOCATION_SEGMENT_ID
        , MOVEMENT_ID
        , ORG_ID
        , AMOUNT_INCLUDES_TAX_FLAG
        , HEADER_GDF_ATTR_CATEGORY
        , HEADER_GDF_ATTRIBUTE1
        , HEADER_GDF_ATTRIBUTE2
        , HEADER_GDF_ATTRIBUTE3
        , HEADER_GDF_ATTRIBUTE4
        , HEADER_GDF_ATTRIBUTE5
        , HEADER_GDF_ATTRIBUTE6
        , HEADER_GDF_ATTRIBUTE7
        , HEADER_GDF_ATTRIBUTE8
        , HEADER_GDF_ATTRIBUTE9
        , HEADER_GDF_ATTRIBUTE10
        , HEADER_GDF_ATTRIBUTE11
        , HEADER_GDF_ATTRIBUTE12
        , HEADER_GDF_ATTRIBUTE13
        , HEADER_GDF_ATTRIBUTE14
        , HEADER_GDF_ATTRIBUTE15
        , HEADER_GDF_ATTRIBUTE16
        , HEADER_GDF_ATTRIBUTE17
        , HEADER_GDF_ATTRIBUTE18
        , HEADER_GDF_ATTRIBUTE19
        , HEADER_GDF_ATTRIBUTE20
        , HEADER_GDF_ATTRIBUTE21
        , HEADER_GDF_ATTRIBUTE22
        , HEADER_GDF_ATTRIBUTE23
        , HEADER_GDF_ATTRIBUTE24
        , HEADER_GDF_ATTRIBUTE25
        , HEADER_GDF_ATTRIBUTE26
        , HEADER_GDF_ATTRIBUTE27
        , HEADER_GDF_ATTRIBUTE28
        , HEADER_GDF_ATTRIBUTE29
        , HEADER_GDF_ATTRIBUTE30
        , LINE_GDF_ATTR_CATEGORY
        , LINE_GDF_ATTRIBUTE1
        , LINE_GDF_ATTRIBUTE2
        , LINE_GDF_ATTRIBUTE3
        , LINE_GDF_ATTRIBUTE4
        , LINE_GDF_ATTRIBUTE5
        , LINE_GDF_ATTRIBUTE6
        , LINE_GDF_ATTRIBUTE7
        , LINE_GDF_ATTRIBUTE8
        , LINE_GDF_ATTRIBUTE9
        , LINE_GDF_ATTRIBUTE10
        , LINE_GDF_ATTRIBUTE11
        , LINE_GDF_ATTRIBUTE12
        , LINE_GDF_ATTRIBUTE13
        , LINE_GDF_ATTRIBUTE14
        , LINE_GDF_ATTRIBUTE15
        , LINE_GDF_ATTRIBUTE16
        , LINE_GDF_ATTRIBUTE17
        , LINE_GDF_ATTRIBUTE18
        , LINE_GDF_ATTRIBUTE19
        , LINE_GDF_ATTRIBUTE20
        , RESET_TRX_DATE_FLAG
        , PAYMENT_SERVER_ORDER_NUM
        , APPROVAL_CODE
        , ADDRESS_VERIFICATION_CODE
        , WAREHOUSE_ID
        , TRANSLATED_DESCRIPTION
        , CONS_BILLING_NUMBER
        , PROMISED_COMMITMENT_AMOUNT
        , PAYMENT_SET_ID
        , ORIGINAL_GL_DATE
        , CONTRACT_LINE_ID
        , CONTRACT_ID
        , SOURCE_DATA_KEY1
        , SOURCE_DATA_KEY2
        , SOURCE_DATA_KEY3
        , SOURCE_DATA_KEY4
        , SOURCE_DATA_KEY5
        , INVOICED_LINE_ACCTG_LEVEL
      )VALUES(
          i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ID
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_CONTEXT
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).BATCH_SOURCE_NAME
        , i_if_line_rec(ln_loop_cnt).SET_OF_BOOKS_ID
        , i_if_line_rec(ln_loop_cnt).LINE_TYPE
        , i_if_line_rec(ln_loop_cnt).DESCRIPTION
        , i_if_line_rec(ln_loop_cnt).CURRENCY_CODE
        , i_if_line_rec(ln_loop_cnt).AMOUNT
        , i_if_line_rec(ln_loop_cnt).CUST_TRX_TYPE_NAME
        , i_if_line_rec(ln_loop_cnt).CUST_TRX_TYPE_ID
        , i_if_line_rec(ln_loop_cnt).TERM_NAME
        , i_if_line_rec(ln_loop_cnt).TERM_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BATCH_NAME
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_CUSTOMER_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_CUSTOMER_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_ADDRESS_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_ADDRESS_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_CONTACT_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_BILL_CONTACT_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_CUSTOMER_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_ADDRESS_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_ADDRESS_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_CONTACT_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SHIP_CONTACT_ID
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_REF
        , i_if_line_rec(ln_loop_cnt).ORIG_SYSTEM_SOLD_CUSTOMER_ID
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ID
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_CONTEXT
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).LINK_TO_LINE_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).RECEIPT_METHOD_NAME
        , i_if_line_rec(ln_loop_cnt).RECEIPT_METHOD_ID
        , i_if_line_rec(ln_loop_cnt).CONVERSION_TYPE
        , i_if_line_rec(ln_loop_cnt).CONVERSION_DATE
        , i_if_line_rec(ln_loop_cnt).CONVERSION_RATE
        , i_if_line_rec(ln_loop_cnt).CUSTOMER_TRX_ID
        , i_if_line_rec(ln_loop_cnt).TRX_DATE
        , i_if_line_rec(ln_loop_cnt).GL_DATE
        , i_if_line_rec(ln_loop_cnt).DOCUMENT_NUMBER
        , i_if_line_rec(ln_loop_cnt).TRX_NUMBER
        , i_if_line_rec(ln_loop_cnt).LINE_NUMBER
        , i_if_line_rec(ln_loop_cnt).QUANTITY
        , i_if_line_rec(ln_loop_cnt).QUANTITY_ORDERED
        , i_if_line_rec(ln_loop_cnt).UNIT_SELLING_PRICE
        , i_if_line_rec(ln_loop_cnt).UNIT_STANDARD_PRICE
        , i_if_line_rec(ln_loop_cnt).PRINTING_OPTION
        , i_if_line_rec(ln_loop_cnt).INTERFACE_STATUS
        , i_if_line_rec(ln_loop_cnt).REQUEST_ID
        , i_if_line_rec(ln_loop_cnt).RELATED_BATCH_SOURCE_NAME
        , i_if_line_rec(ln_loop_cnt).RELATED_TRX_NUMBER
        , i_if_line_rec(ln_loop_cnt).RELATED_CUSTOMER_TRX_ID
        , i_if_line_rec(ln_loop_cnt).PREVIOUS_CUSTOMER_TRX_ID
        , i_if_line_rec(ln_loop_cnt).CREDIT_METHOD_FOR_ACCT_RULE
        , i_if_line_rec(ln_loop_cnt).CREDIT_METHOD_FOR_INSTALLMENTS
        , i_if_line_rec(ln_loop_cnt).REASON_CODE
        , i_if_line_rec(ln_loop_cnt).TAX_RATE
        , i_if_line_rec(ln_loop_cnt).TAX_CODE
        , i_if_line_rec(ln_loop_cnt).TAX_PRECEDENCE
        , i_if_line_rec(ln_loop_cnt).EXCEPTION_ID
        , i_if_line_rec(ln_loop_cnt).EXEMPTION_ID
        , i_if_line_rec(ln_loop_cnt).SHIP_DATE_ACTUAL
        , i_if_line_rec(ln_loop_cnt).FOB_POINT
        , i_if_line_rec(ln_loop_cnt).SHIP_VIA
        , i_if_line_rec(ln_loop_cnt).WAYBILL_NUMBER
        , i_if_line_rec(ln_loop_cnt).INVOICING_RULE_NAME
        , i_if_line_rec(ln_loop_cnt).INVOICING_RULE_ID
        , i_if_line_rec(ln_loop_cnt).ACCOUNTING_RULE_NAME
        , i_if_line_rec(ln_loop_cnt).ACCOUNTING_RULE_ID
        , i_if_line_rec(ln_loop_cnt).ACCOUNTING_RULE_DURATION
        , i_if_line_rec(ln_loop_cnt).RULE_START_DATE
        , i_if_line_rec(ln_loop_cnt).PRIMARY_SALESREP_NUMBER
        , i_if_line_rec(ln_loop_cnt).PRIMARY_SALESREP_ID
        , i_if_line_rec(ln_loop_cnt).SALES_ORDER
        , i_if_line_rec(ln_loop_cnt).SALES_ORDER_LINE
        , i_if_line_rec(ln_loop_cnt).SALES_ORDER_DATE
        , i_if_line_rec(ln_loop_cnt).SALES_ORDER_SOURCE
        , i_if_line_rec(ln_loop_cnt).SALES_ORDER_REVISION
        , i_if_line_rec(ln_loop_cnt).PURCHASE_ORDER
        , i_if_line_rec(ln_loop_cnt).PURCHASE_ORDER_REVISION
        , i_if_line_rec(ln_loop_cnt).PURCHASE_ORDER_DATE
        , i_if_line_rec(ln_loop_cnt).AGREEMENT_NAME
        , i_if_line_rec(ln_loop_cnt).AGREEMENT_ID
        , i_if_line_rec(ln_loop_cnt).MEMO_LINE_NAME
        , i_if_line_rec(ln_loop_cnt).MEMO_LINE_ID
        , i_if_line_rec(ln_loop_cnt).INVENTORY_ITEM_ID
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG1
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG2
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG3
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG4
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG5
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG6
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG7
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG8
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG9
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG10
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG11
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG12
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG13
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG14
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG15
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG16
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG17
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG18
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG19
        , i_if_line_rec(ln_loop_cnt).MTL_SYSTEM_ITEMS_SEG20
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ID
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_CONTEXT
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).REFERENCE_LINE_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).TERRITORY_ID
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT1
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT2
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT3
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT4
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT5
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT6
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT7
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT8
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT9
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT10
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT11
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT12
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT13
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT14
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT15
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT16
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT17
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT18
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT19
        , i_if_line_rec(ln_loop_cnt).TERRITORY_SEGMENT20
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE_CATEGORY
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE_CATEGORY
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).HEADER_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).COMMENTS
        , i_if_line_rec(ln_loop_cnt).INTERNAL_NOTES
        , i_if_line_rec(ln_loop_cnt).INITIAL_CUSTOMER_TRX_ID
        , i_if_line_rec(ln_loop_cnt).USSGL_TRANSACTION_CODE_CONTEXT
        , i_if_line_rec(ln_loop_cnt).USSGL_TRANSACTION_CODE
        , i_if_line_rec(ln_loop_cnt).ACCTD_AMOUNT
        , i_if_line_rec(ln_loop_cnt).CUSTOMER_BANK_ACCOUNT_ID
        , i_if_line_rec(ln_loop_cnt).CUSTOMER_BANK_ACCOUNT_NAME
        , i_if_line_rec(ln_loop_cnt).UOM_CODE
        , i_if_line_rec(ln_loop_cnt).UOM_NAME
        , i_if_line_rec(ln_loop_cnt).DOCUMENT_NUMBER_SEQUENCE_ID
        , i_if_line_rec(ln_loop_cnt).VAT_TAX_ID
        , i_if_line_rec(ln_loop_cnt).REASON_CODE_MEANING
        , i_if_line_rec(ln_loop_cnt).LAST_PERIOD_TO_CREDIT
        , i_if_line_rec(ln_loop_cnt).PAYING_CUSTOMER_ID
        , i_if_line_rec(ln_loop_cnt).PAYING_SITE_USE_ID
        , i_if_line_rec(ln_loop_cnt).TAX_EXEMPT_FLAG
        , i_if_line_rec(ln_loop_cnt).TAX_EXEMPT_REASON_CODE
        , i_if_line_rec(ln_loop_cnt).TAX_EXEMPT_REASON_CODE_MEANING
        , i_if_line_rec(ln_loop_cnt).TAX_EXEMPT_NUMBER
        , i_if_line_rec(ln_loop_cnt).SALES_TAX_ID
        , i_if_line_rec(ln_loop_cnt).CREATED_BY
        , i_if_line_rec(ln_loop_cnt).CREATION_DATE
        , i_if_line_rec(ln_loop_cnt).LAST_UPDATED_BY
        , i_if_line_rec(ln_loop_cnt).LAST_UPDATE_DATE
        , i_if_line_rec(ln_loop_cnt).LAST_UPDATE_LOGIN
        , i_if_line_rec(ln_loop_cnt).LOCATION_SEGMENT_ID
        , i_if_line_rec(ln_loop_cnt).MOVEMENT_ID
        , i_if_line_rec(ln_loop_cnt).ORG_ID
        , i_if_line_rec(ln_loop_cnt).AMOUNT_INCLUDES_TAX_FLAG
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTR_CATEGORY
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE16
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE17
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE18
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE19
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE20
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE21
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE22
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE23
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE24
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE25
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE26
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE27
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE28
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE29
        , i_if_line_rec(ln_loop_cnt).HEADER_GDF_ATTRIBUTE30
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTR_CATEGORY
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE1
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE2
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE3
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE4
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE5
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE6
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE7
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE8
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE9
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE10
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE11
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE12
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE13
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE14
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE15
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE16
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE17
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE18
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE19
        , i_if_line_rec(ln_loop_cnt).LINE_GDF_ATTRIBUTE20
        , i_if_line_rec(ln_loop_cnt).RESET_TRX_DATE_FLAG
        , i_if_line_rec(ln_loop_cnt).PAYMENT_SERVER_ORDER_NUM
        , i_if_line_rec(ln_loop_cnt).APPROVAL_CODE
        , i_if_line_rec(ln_loop_cnt).ADDRESS_VERIFICATION_CODE
        , i_if_line_rec(ln_loop_cnt).WAREHOUSE_ID
        , i_if_line_rec(ln_loop_cnt).TRANSLATED_DESCRIPTION
        , i_if_line_rec(ln_loop_cnt).CONS_BILLING_NUMBER
        , i_if_line_rec(ln_loop_cnt).PROMISED_COMMITMENT_AMOUNT
        , i_if_line_rec(ln_loop_cnt).PAYMENT_SET_ID
        , i_if_line_rec(ln_loop_cnt).ORIGINAL_GL_DATE
        , i_if_line_rec(ln_loop_cnt).CONTRACT_LINE_ID
        , i_if_line_rec(ln_loop_cnt).CONTRACT_ID
        , i_if_line_rec(ln_loop_cnt).SOURCE_DATA_KEY1
        , i_if_line_rec(ln_loop_cnt).SOURCE_DATA_KEY2
        , i_if_line_rec(ln_loop_cnt).SOURCE_DATA_KEY3
        , i_if_line_rec(ln_loop_cnt).SOURCE_DATA_KEY4
        , i_if_line_rec(ln_loop_cnt).SOURCE_DATA_KEY5
        , i_if_line_rec(ln_loop_cnt).INVOICED_LINE_ACCTG_LEVEL
      );
--
    END LOOP;
--
    -- IF_DISTテーブル型変数を実テーブルへ挿入(伝票取消ではDIST無し)
    IF i_if_dist_rec.COUNT != 0 THEN
      FOR ln_loop_cnt IN 1..i_if_dist_rec.COUNT LOOP
--
        INSERT INTO RA_INTERFACE_DISTRIBUTIONS_ALL (
            INTERFACE_DISTRIBUTION_ID
          , INTERFACE_LINE_ID
          , INTERFACE_LINE_CONTEXT
          , INTERFACE_LINE_ATTRIBUTE1
          , INTERFACE_LINE_ATTRIBUTE2
          , INTERFACE_LINE_ATTRIBUTE3
          , INTERFACE_LINE_ATTRIBUTE4
          , INTERFACE_LINE_ATTRIBUTE5
          , INTERFACE_LINE_ATTRIBUTE6
          , INTERFACE_LINE_ATTRIBUTE7
          , INTERFACE_LINE_ATTRIBUTE8
          , INTERFACE_LINE_ATTRIBUTE9
          , INTERFACE_LINE_ATTRIBUTE10
          , INTERFACE_LINE_ATTRIBUTE11
          , INTERFACE_LINE_ATTRIBUTE12
          , INTERFACE_LINE_ATTRIBUTE13
          , INTERFACE_LINE_ATTRIBUTE14
          , INTERFACE_LINE_ATTRIBUTE15
          , ACCOUNT_CLASS
          , AMOUNT
          , PERCENT
          , INTERFACE_STATUS
          , REQUEST_ID
          , CODE_COMBINATION_ID
          , SEGMENT1
          , SEGMENT2
          , SEGMENT3
          , SEGMENT4
          , SEGMENT5
          , SEGMENT6
          , SEGMENT7
          , SEGMENT8
          , SEGMENT9
          , SEGMENT10
          , SEGMENT11
          , SEGMENT12
          , SEGMENT13
          , SEGMENT14
          , SEGMENT15
          , SEGMENT16
          , SEGMENT17
          , SEGMENT18
          , SEGMENT19
          , SEGMENT20
          , SEGMENT21
          , SEGMENT22
          , SEGMENT23
          , SEGMENT24
          , SEGMENT25
          , SEGMENT26
          , SEGMENT27
          , SEGMENT28
          , SEGMENT29
          , SEGMENT30
          , COMMENTS
          , ATTRIBUTE_CATEGORY
          , ATTRIBUTE1
          , ATTRIBUTE2
          , ATTRIBUTE3
          , ATTRIBUTE4
          , ATTRIBUTE5
          , ATTRIBUTE6
          , ATTRIBUTE7
          , ATTRIBUTE8
          , ATTRIBUTE9
          , ATTRIBUTE10
          , ATTRIBUTE11
          , ATTRIBUTE12
          , ATTRIBUTE13
          , ATTRIBUTE14
          , ATTRIBUTE15
          , ACCTD_AMOUNT
          , CREATED_BY
          , CREATION_DATE
          , LAST_UPDATED_BY
          , LAST_UPDATE_DATE
          , LAST_UPDATE_LOGIN
          , ORG_ID
          , INTERIM_TAX_CCID
          , INTERIM_TAX_SEGMENT1
          , INTERIM_TAX_SEGMENT2
          , INTERIM_TAX_SEGMENT3
          , INTERIM_TAX_SEGMENT4
          , INTERIM_TAX_SEGMENT5
          , INTERIM_TAX_SEGMENT6
          , INTERIM_TAX_SEGMENT7
          , INTERIM_TAX_SEGMENT8
          , INTERIM_TAX_SEGMENT9
          , INTERIM_TAX_SEGMENT10
          , INTERIM_TAX_SEGMENT11
          , INTERIM_TAX_SEGMENT12
          , INTERIM_TAX_SEGMENT13
          , INTERIM_TAX_SEGMENT14
          , INTERIM_TAX_SEGMENT15
          , INTERIM_TAX_SEGMENT16
          , INTERIM_TAX_SEGMENT17
          , INTERIM_TAX_SEGMENT18
          , INTERIM_TAX_SEGMENT19
          , INTERIM_TAX_SEGMENT20
          , INTERIM_TAX_SEGMENT21
          , INTERIM_TAX_SEGMENT22
          , INTERIM_TAX_SEGMENT23
          , INTERIM_TAX_SEGMENT24
          , INTERIM_TAX_SEGMENT25
          , INTERIM_TAX_SEGMENT26
          , INTERIM_TAX_SEGMENT27
          , INTERIM_TAX_SEGMENT28
          , INTERIM_TAX_SEGMENT29
          , INTERIM_TAX_SEGMENT30
        )VALUES(
            i_if_dist_rec(ln_loop_cnt).INTERFACE_DISTRIBUTION_ID
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ID
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_CONTEXT
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE1
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE2
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE3
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE4
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE5
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE6
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE7
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE8
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE9
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE10
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE11
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE12
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE13
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE14
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_LINE_ATTRIBUTE15
          , i_if_dist_rec(ln_loop_cnt).ACCOUNT_CLASS
          , i_if_dist_rec(ln_loop_cnt).AMOUNT
          , i_if_dist_rec(ln_loop_cnt).PERCENT
          , i_if_dist_rec(ln_loop_cnt).INTERFACE_STATUS
          , i_if_dist_rec(ln_loop_cnt).REQUEST_ID
          , i_if_dist_rec(ln_loop_cnt).CODE_COMBINATION_ID
          , i_if_dist_rec(ln_loop_cnt).SEGMENT1
          , i_if_dist_rec(ln_loop_cnt).SEGMENT2
          , i_if_dist_rec(ln_loop_cnt).SEGMENT3
          , i_if_dist_rec(ln_loop_cnt).SEGMENT4
          , i_if_dist_rec(ln_loop_cnt).SEGMENT5
          , i_if_dist_rec(ln_loop_cnt).SEGMENT6
          , i_if_dist_rec(ln_loop_cnt).SEGMENT7
          , i_if_dist_rec(ln_loop_cnt).SEGMENT8
          , i_if_dist_rec(ln_loop_cnt).SEGMENT9
          , i_if_dist_rec(ln_loop_cnt).SEGMENT10
          , i_if_dist_rec(ln_loop_cnt).SEGMENT11
          , i_if_dist_rec(ln_loop_cnt).SEGMENT12
          , i_if_dist_rec(ln_loop_cnt).SEGMENT13
          , i_if_dist_rec(ln_loop_cnt).SEGMENT14
          , i_if_dist_rec(ln_loop_cnt).SEGMENT15
          , i_if_dist_rec(ln_loop_cnt).SEGMENT16
          , i_if_dist_rec(ln_loop_cnt).SEGMENT17
          , i_if_dist_rec(ln_loop_cnt).SEGMENT18
          , i_if_dist_rec(ln_loop_cnt).SEGMENT19
          , i_if_dist_rec(ln_loop_cnt).SEGMENT20
          , i_if_dist_rec(ln_loop_cnt).SEGMENT21
          , i_if_dist_rec(ln_loop_cnt).SEGMENT22
          , i_if_dist_rec(ln_loop_cnt).SEGMENT23
          , i_if_dist_rec(ln_loop_cnt).SEGMENT24
          , i_if_dist_rec(ln_loop_cnt).SEGMENT25
          , i_if_dist_rec(ln_loop_cnt).SEGMENT26
          , i_if_dist_rec(ln_loop_cnt).SEGMENT27
          , i_if_dist_rec(ln_loop_cnt).SEGMENT28
          , i_if_dist_rec(ln_loop_cnt).SEGMENT29
          , i_if_dist_rec(ln_loop_cnt).SEGMENT30
          , i_if_dist_rec(ln_loop_cnt).COMMENTS
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE_CATEGORY
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE1
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE2
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE3
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE4
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE5
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE6
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE7
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE8
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE9
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE10
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE11
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE12
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE13
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE14
          , i_if_dist_rec(ln_loop_cnt).ATTRIBUTE15
          , i_if_dist_rec(ln_loop_cnt).ACCTD_AMOUNT
          , i_if_dist_rec(ln_loop_cnt).CREATED_BY
          , i_if_dist_rec(ln_loop_cnt).CREATION_DATE
          , i_if_dist_rec(ln_loop_cnt).LAST_UPDATED_BY
          , i_if_dist_rec(ln_loop_cnt).LAST_UPDATE_DATE
          , i_if_dist_rec(ln_loop_cnt).LAST_UPDATE_LOGIN
          , i_if_dist_rec(ln_loop_cnt).ORG_ID
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_CCID
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT1
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT2
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT3
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT4
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT5
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT6
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT7
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT8
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT9
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT10
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT11
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT12
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT13
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT14
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT15
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT16
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT17
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT18
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT19
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT20
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT21
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT22
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT23
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT24
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT25
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT26
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT27
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT28
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT29
          , i_if_dist_rec(ln_loop_cnt).INTERIM_TAX_SEGMENT30
        );
      END LOOP;
    END IF;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END ar_if_for_invoice;
--
  /**********************************************************************************
   * Procedure Name   : get_approval_slip_data
   * Description      : 経理承認済請求依頼データの取得(A-1,A-2)
   ***********************************************************************************/
  PROCEDURE get_approval_slip_data(
    iv_source         IN VARCHAR2,      -- 1.請求先取引ソース名(IN)
    iv_source2        IN VARCHAR2,      -- 2.前受金取引ソース名(IN)
    on_org_id         OUT NUMBER,       -- 3.オルグID(OUT)
    on_books_id       OUT NUMBER,       -- 4.会計帳簿ID(OUT)
    on_header_cnt     OUT NUMBER,       -- 5.ヘッダ件数(OUT)
    on_detail_cnt     OUT NUMBER,       -- 6.明細件数(OUT)
    od_upd_date       OUT DATE,         -- 7.更新日付(OUT)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_approval_slip_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_us_rate_type     CONSTANT VARCHAR2(10) := 'User';
    cv_pay_lookup_type  CONSTANT xx03_ap_pay_groups_v.lookup_type%TYPE := 'PAY GROUP';
--
    -- *** ローカル変数 ***
    ln_updated_by     NUMBER;         -- 最終更新者退避用
    ln_update_login   NUMBER;         -- 最終ログイン退避用
    ln_created_by     NUMBER;         -- 作成者退避用
    lv_cur_lang       VARCHAR2(4);    -- 現在の言語コード
    ln_detail_cnt     NUMBER;         -- 明細件数
--
    ln_source_id      NUMBER;         -- 請求先取引ソースID
    ln_source_id2     NUMBER;         -- 前受金取引ソースID
    lv_att_category   VARCHAR2(255);  -- 明細FFコンテキスト値
    lv_base_currency  VARCHAR2(15);   -- 基本通貨コード
    lv_nvl_att_1      VARCHAR2(255);  -- 空白時明細備考
    lv_nvl_att_3      VARCHAR2(255);  -- 空白時明細納品書番号
--
    -- *** ローカル・レコード ***
    -- AP仕入先請求書転送カーソルレコード
    l_get_ar_trance_data_rec  get_ar_trance_data_cur%ROWTYPE;  -- ARレコード IF用カーソル
    l_if_line_rec             trx_if_line_type;                -- RA_IF_レコード LINE
    l_if_dist_rec             trx_if_dist_type;                -- RA_IF_レコード DIST
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    chk_data_none_expt        EXCEPTION;              -- AR転送データ未取得エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- オルグIDの取得
    on_org_id := TO_NUMBER(xx00_profile_pkg.value(cv_prof_ORG_ID));
    -- 会計帳簿IDの取得
    on_books_id := xx00_profile_pkg.value(cv_prof_GL_ID);
    -- 空白時明細備考欄の取得
    lv_nvl_att_1 := xx00_profile_pkg.value(cv_prof_ATT_1);
    -- 空白時明細納品書番号欄の取得
    lv_nvl_att_3 := xx00_profile_pkg.value(cv_prof_ATT_3);
--
    -- 請求書取引ソース名からソースIDを取得する。
    SELECT   BATCH_SOURCE_ID
    INTO     ln_source_id
    FROM     RA_BATCH_SOURCES
    WHERE    NAME = iv_source
    ;
--
    -- 前受金取引ソース名からソースIDを取得する。
    SELECT   BATCH_SOURCE_ID
    INTO     ln_source_id2
    FROM     RA_BATCH_SOURCES
    WHERE    NAME = iv_source2
    ;
--
    -- 明細FFコンテキスト
    lv_att_category := xx00_profile_pkg.value(cv_prof_AFF_CAT);
--
    -- 基本通貨取得
    SELECT   CURRENCY_CODE
    INTO     lv_base_currency
    FROM     GL_SETS_OF_BOOKS
    WHERE    SET_OF_BOOKS_ID = on_books_id
    ;

--
    -- AR請求依頼転送カーソルオープン
    OPEN get_ar_trance_data_cur(on_org_id);
    -- 変数初期化
    on_header_cnt   := 0;                                      -- ヘッダー件数
    on_detail_cnt   := 0;                                      -- 明細件数
    ln_updated_by   := xx00_global_pkg.last_updated_by;        -- 最終更新者
    ln_update_login := xx00_global_pkg.last_update_login;      -- 最終更新職責
    ln_created_by   := xx00_global_pkg.created_by;             -- 作成者
    lv_cur_lang     := xx00_global_pkg.current_language;       -- 言語
    <<get_ar_trance_loop>>
    LOOP
--
      FETCH get_ar_trance_data_cur INTO l_get_ar_trance_data_rec;
      -- 0件判定
      IF (get_ar_trance_data_cur%NOTFOUND) THEN
        -- 件数判定
        IF on_header_cnt < 1 THEN
          RAISE chk_data_none_expt;
        END IF;
        EXIT get_ar_trance_loop;
      END IF;
      IF on_header_cnt = 0 THEN
        od_upd_date := l_get_ar_trance_data_rec.upd_date;
      END IF;
--
      -- 伝票種別が前受金の場合
      IF l_get_ar_trance_data_rec.ATTRIBUTE12 = cv_slip_type_DEP AND
         l_get_ar_trance_data_rec.ORIG_INVOICE_NUM IS NULL THEN
--
        -- =======================================
        -- ARAPIの更新［前受金］(A-2)
        -- =======================================
        ar_api_for_deposit(
          l_get_ar_trance_data_rec,                          -- 1.取得データカーソル型(IN)
          ln_source_id2,                                     -- 2.前受金ソースID(IN)
          on_org_id,                                         -- 3.オルグID(IN)
          lv_att_category,                                   -- 4.明細FFコンテキスト(IN)
          lv_base_currency,                                  -- 5.基本通貨コード(IN)
          ln_updated_by,                                     -- 6.最終更新者(IN)
          ln_update_login,                                   -- 7.最終ログイン(IN)
          ln_created_by,                                     -- 8.作成者(IN)
          ln_detail_cnt,                                     -- 9.明細件数(OUT)
          lv_errbuf,      -- エラー・メッセージ              --# 固定 #
          lv_retcode,     -- リターン・コード                --# 固定 #
          lv_errmsg);     -- ユーザー・エラー・メッセージ    --# 固定 #
--
      -- 通常の請求依頼・取消伝票の場合
      ELSE
--
        -- =======================================
        -- ARAPIの更新［請求依頼］(A-2)
        -- =======================================
        l_if_line_rec.DELETE;
        l_if_dist_rec.DELETE;
--
        ar_if_invoice_set(
          l_if_line_rec,                                     -- 1.RA_IF_レコード LINE(OUT)
          l_if_dist_rec,                                     -- 2.RA_IF_レコード DIST(OUT)
          l_get_ar_trance_data_rec,                          -- 3.取得データカーソル型(IN)
          ln_source_id,                                      -- 4.前受金ソースID(IN)
          iv_source,                                         -- 5.ソース名(IN)
-- ver 1.2 Change Start
          ln_source_id2,                                     --  .前受金ソースID(IN)
-- ver 1.2 Change End
          on_org_id,                                         -- 6.オルグID(IN)
          on_books_id,                                       -- 7.帳簿ID(IN)
          lv_att_category,                                   -- 8.明細FFコンテキスト(IN)
          lv_base_currency,                                  -- 9.基本通貨コード(IN)
          lv_nvl_att_1,                                      -- 10.明細備考欄(IN)
          lv_nvl_att_3,                                      -- 11.明細納品書番号(IN)
          ln_updated_by,                                     -- 12.最終更新者(IN)
          ln_update_login,                                   -- 13.最終ログイン(IN)
          ln_created_by,                                     -- 14.作成者(IN)
          ln_detail_cnt,                                     -- 15.明細件数(OUT)
          lv_errbuf,      -- エラー・メッセージ              --# 固定 #
          lv_retcode,     -- リターン・コード                --# 固定 #
          lv_errmsg);     -- ユーザー・エラー・メッセージ    --# 固定 #
--
        -- 正常時処理
        IF (lv_retcode != xx00_common_pkg.set_status_error_f) AND
           (lv_retcode != xx00_common_pkg.set_status_warn_f)  THEN
--
          ar_if_for_invoice(
            l_if_line_rec,                                     -- 1.RA_IF_レコード LINE(IN)
            l_if_dist_rec,                                     -- 2.RA_IF_レコード DIST(IN)
            lv_errbuf,      -- エラー・メッセージ              --# 固定 #
            lv_retcode,     -- リターン・コード                --# 固定 #
            lv_errmsg);     -- ユーザー・エラー・メッセージ    --# 固定 #
--
        -- 正常時処理
          IF (lv_retcode != xx00_common_pkg.set_status_error_f) AND
             (lv_retcode != xx00_common_pkg.set_status_warn_f)  THEN
--
            --請求依頼を「AR転送済」に更新する。
            UPDATE  xx03_receivable_slips xrs
            SET     xrs.AR_FORWARD_DATE   = l_get_ar_trance_data_rec.UPD_DATE       -- AR転送日
                  , xrs.last_update_date  = l_get_ar_trance_data_rec.UPD_DATE       -- 最終更新日
                  , xrs.last_updated_by   = xx00_global_pkg.user_id                 -- 最終更新者
                  , xrs.last_update_login = xx00_global_pkg.last_update_login       -- 最終更新職責
            WHERE   xrs.RECEIVABLE_ID     = l_get_ar_trance_data_rec.RECEIVABLE_ID  -- 処理対象の請求書ID
            ;
--
          END IF;
        END IF;
      END IF;
--
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      ElSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
-- ver 1.2 Change Start
        --エラーテーブルへ退避＆転送済みにする
        copy_err_data(l_get_ar_trance_data_rec.RECEIVABLE_ID,            -- 請求書ID
                      l_get_ar_trance_data_rec.UPD_DATE,                 -- AR転送日
                      lv_errbuf,      -- エラー・メッセージ              --# 固定 #
                      lv_retcode,     -- リターン・コード                --# 固定 #
                      lv_errmsg);     -- ユーザー・エラー・メッセージ    --# 固定 #
	IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --(エラー処理)
          RAISE global_process_expt;
	END IF;
-- ver 1.2 Change End
        ov_retcode := xx00_common_pkg.set_status_warn_f;
      END IF;
      -- 件数のカウント
      on_header_cnt := on_header_cnt + 1;
      on_detail_cnt := on_detail_cnt + ln_detail_cnt;
    END LOOP get_ar_trance_loop;
    CLOSE get_ar_trance_data_cur;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_data_none_expt THEN        --*** 転送処理対象データ未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08003'));           -- 転送処理対象データ未取得エラーメッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_approval_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : 結果出力
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id     IN  NUMBER,       --  1.チェックID(IN)
    in_books_id   IN  NUMBER,       --  2.会計帳簿ID(IN)
    in_header_cnt IN  NUMBER,       --  3.ヘッダ件数(IN)
    in_detail_cnt IN  NUMBER,       --  4.明細件数(IN)
    iv_source     IN  VARCHAR2,     --  5.請求書取引先ソース名(IN)
    iv_source2    IN  VARCHAR2,     --  6.前受金取引先ソース名(IN)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_output'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- ヘッダー出力
    xx03_header_line_output_pkg.header_line_output_p('GL',    -- 会計帳簿名を表示する
      xx00_global_pkg.prog_appl_id,
      in_books_id,                                            -- 会計帳簿ID
      in_org_id,                                              -- オルグID
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
--
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- パラメータのログ出力
    xx00_file_pkg.output(' ');
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' || iv_source );
    xx00_file_pkg.output(l_conc_para_rec(2).param_prompt ||
      ':' || iv_source2);
    xx00_file_pkg.output(' ');
--
    -- 件数出力
    xx00_file_pkg.output(
    xx00_message_pkg.get_msg(
      'XX03',
      'APP-XX03-04004',             -- 承認済仕入先請求書転送結果出力
      'XX03_TOK_HEAD_CNT',
      in_header_cnt,                -- AP転送件数(ヘッダ)
      'XX03_TOK_DETAIL_CNT',
      in_detail_cnt));              -- AP転送件数(配分)
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END msg_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.請求書取引ソース名
    iv_source2    IN  VARCHAR2,     -- 2.前受金取引ソース名
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_org_id         NUMBER(15,0);                           -- オルグID
    ln_books_id       gl_sets_of_books.set_of_books_id%TYPE;  -- 会計帳簿ID
    ln_header_cnt     NUMBER;                                 -- ヘッダ件数
    ln_detail_cnt     NUMBER;                                 -- 明細件数
    ld_upd_date       DATE;                                   -- 更新日付
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =======================================
    -- 経理承認済請求依頼データの取得(A-1, A-2, A-3)
    -- =======================================
    get_approval_slip_data(
      iv_source,          -- 1.請求書取引ソース名(IN)
      iv_source2,         -- 2.前受金取引ソース名(IN)
      ln_org_id,          -- 3.オルグID(OUT)
      ln_books_id,        -- 4.会計帳簿ID(OUT)
      ln_header_cnt,      -- 5.ヘッダ件数(OUT)
      ln_detail_cnt,      -- 6.明細件数(OUT)
      ld_upd_date,        -- 7.更新日付(OUT)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSE
--
      -- =======================================
      -- 結果出力
      -- =======================================
      msg_output(
        ln_org_id,          --  1.チェックID(IN)
        ln_books_id,        --  2.会計帳簿ID(IN)
        ln_header_cnt,      --  3.ヘッダ件数(IN)
        ln_detail_cnt,      --  4.明細件数(IN)
        iv_source,          --  5.請求書取引ソース名(IN)
        iv_source2,         --  6.前受金取引ソース名(IN)
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_source     IN  VARCHAR2,      -- 1.請求書ソース名(IN)
    iv_source2    IN  VARCHAR2)      -- 2.前受金ソース名(IN)
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================
    -- ログヘッダの出力
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_source,   -- 1.請求書取引ソース名(IN)
      iv_source2,  -- 2.前受金取引ソース名(IN)
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ログフッタの出力
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** 共通関数OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XX034RT001C;
/
