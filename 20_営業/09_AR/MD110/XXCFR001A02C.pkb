CREATE OR REPLACE PACKAGE BODY XXCFR001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A02C(body)
 * Description      : 売上実績データ連携
 * MD.050           : MD050_CFR_001_A02_売上実績データ連携
 * MD.070           : MD050_CFR_001_A02_売上実績データ連携
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  get_process_date       p 業務処理日付取得処理                    (A-4)
 *  get_sales_data         p 売上実績データ取得                      (A-5)
 *  put_sales_data         p 売上実績データＣＳＶ作成処理            (A-6)
 *  insert_sales_data_reletes p 売上実績連携済テーブル登録           (A-7)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.00 SCS 中村 博      初回作成
 *  2009/12/13    1.10 SCS 廣瀬 真佐人  障害対応[E_本稼動_00366]
 *  2011/04/19    1.11 SCS 西野 裕介    障害対応[E_本稼動_04976]
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A02C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
--
  cv_msg_001a02_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_001a02_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --ファイル名出力メッセージ
  cv_msg_001a02_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --対象データが0件メッセージ
  cv_msg_001a02_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付取得エラーメッセージ
  cv_msg_001a02_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --ファイルの場所が無効メッセージ
  cv_msg_001a02_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --ファイルをオープンできないメッセージ
  cv_msg_001a02_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; --ファイルに書込みできないメッセー
  cv_msg_001a02_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00050'; --ファイルが存在しているメッセージ
  cv_msg_001a02_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00058'; --商品コード未設定メッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- ファイル名
  cv_tkn_trx_type    CONSTANT VARCHAR2(15) := 'TRX_TYPE';         -- 取引タイプ
--
  --プロファイル
  cv_org_id               CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_sales_data_filename  CONSTANT VARCHAR2(35) := 'XXCFR1_SALES_DATA_FILENAME';
                                                                       -- XXCFR:売上実績データファイル名
  cv_sales_data_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_SALES_DATA_FILEPATH';
                                                                       -- XXCFR:売上実績データファイル格納パス
  cv_sd_sold_return_type  CONSTANT VARCHAR2(35) := 'XXCFR1_SD_SOLD_RETURN_TYPE';
                                                                       -- XXCFR:売上実績データ売上返品区分
  cv_sd_sales_class       CONSTANT VARCHAR2(35) := 'XXCFR1_SD_SALES_CLASS';
                                                                       -- XXCFR:売上実績データ売上区分
  cv_sd_delivery_ptn_class CONSTANT VARCHAR2(35) := 'XXCFR1_SD_DELIVERY_PTN_CLASS';
                                                                       -- XXCFR:売上実績データ納品形態区分
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- フラグ（Ｙ）
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- フラグ（Ｎ）
--
  cv_line_type_l     CONSTANT VARCHAR2(4)  := 'LINE';     -- 明細タイプ(=LINE)
  cn_period_months   CONSTANT NUMBER       := 12;         -- 抽出対象期間（月）
--
  cv_format_date_ymd  CONSTANT VARCHAR2(8)    := 'YYYYMMDD';         -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- 日付フォーマット（年月日時分秒）
--
  cv_object_code        CONSTANT VARCHAR2(10) := '0000000000'; -- 物件コード
  cv_hc_code            CONSTANT VARCHAR2(1)  := '1';          -- Ｈ＆Ｃ（コールド）
  cv_score_member_code  CONSTANT VARCHAR2(5)  := '00000';      -- 成績者コード
  cv_sales_card_type    CONSTANT VARCHAR2(1)  := '0';          -- カード売り区分（現金）
  cv_delivery_base_code CONSTANT VARCHAR2(4)  := '0000';       -- 納品拠点コード
  cv_unit_sales         CONSTANT VARCHAR2(1)  := '0';          -- 売上数量
  cv_column_no          CONSTANT VARCHAR2(2)  := '00';         -- コラムNo
-- Add 2011.04.19 Ver.1.11 Start
  cn_zero               CONSTANT NUMBER       := 0;            -- 基準単価（税込）,売上金額（税込）出力固定値
-- Add 2011.04.19 Ver.1.11 End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id                   NUMBER;            -- 組織ID
  gn_set_of_bks_id            NUMBER;            -- 会計帳簿ID
  gv_sales_data_filename      VARCHAR2(100);     -- 売上実績データファイル名
  gv_sales_data_filepath      VARCHAR2(500);     -- 売上実績データファイル格納パス
  gv_sd_sold_return_type      VARCHAR2(10);      -- 売上実績データ売上返品区分
  gv_sd_sales_class           VARCHAR2(10);      -- 売上実績データ売上区分
  gv_sd_delivery_ptn_class    VARCHAR2(10);      -- 売上実績データ納品形態区分
  gv_period_name              gl_period_statuses.period_name%TYPE;  -- 会計期間名
  gv_start_date_yymm          VARCHAR2(6);       -- 会計期間年月
  gd_process_date             DATE;              -- 業務処理日付
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
    -- 抽出
    CURSOR get_sales_data_cur
    IS
      SELECT rcta.trx_number              trx_number,               -- 納品伝票No（AR取引番号）
             rcta.trx_date                trx_date,                 -- 納品日（売上日）（取引日）
             rcta.customer_trx_id         customer_trx_id,          -- 取引ID
             rctla.line_number            line_number,              -- 納品伝票行No（AR取引明細番号）
             rctla.customer_trx_line_id   customer_trx_line_id,     -- 取引明細ID
             rctla.revenue_amount         rec_amount,               -- 売上金額
             rctla_t.extended_amount      tax_amount,               -- 税金金額
             avtab.tax_code               tax_code,                 -- AR税区分（AR税金マスタ）
             gcc.segment1                 comp_code,                -- 会社コード(AFF1)
             gcc.segment2                 dept_code,                -- 売上拠点コード(AFF2)
             hca_s.account_number         ship_to_account_number,   -- 顧客コード（出荷先顧客コード）
             hca_b.account_number         bill_to_account_number,   -- 請求先顧客コード（請求先顧客コード）
             rctta.attribute3             item_code,                -- 商品コード
             rctlgda.gl_date              gl_date,                  -- GL記帳日
             rctta.name                   trx_type_name             -- 取引タイプ名
      FROM ra_customer_trx_all            rcta,       -- 取引ヘッダ
           ra_cust_trx_types_all          rctta,      -- 取引タイプ
           ra_customer_trx_lines_all      rctla,      -- 取引明細（本体）
           ra_customer_trx_lines_all      rctla_t,    -- 取引明細（税額）
           ra_cust_trx_line_gl_dist_all   rctlgda,    -- 取引配分
           gl_code_combinations           gcc,        -- 勘定科目組合せマスタ
           hz_cust_accounts               hca_s,      -- 顧客マスタ（出荷先）
           hz_cust_accounts               hca_b,      -- 顧客マスタ（請求先）
           ar_vat_tax_all_b               avtab       -- AR税金マスタ
      WHERE rcta.cust_trx_type_id         = rctta.cust_trx_type_id
        AND rctta.attribute2              = cv_flag_yes       -- 情報系連携フラグ（＝Y)
        AND NOT EXISTS ( 
            SELECT ROWNUM
            FROM xxcfr_sales_data_reletes   xsdr
            WHERE xsdr.customer_trx_id = rcta.customer_trx_id
            )
        AND rcta.trx_date                 >= ADD_MONTHS ( gd_process_date, -1 * cn_period_months )
        AND rcta.set_of_books_id          = gn_set_of_bks_id
        AND rcta.org_id                   = gn_org_id
        AND rcta.customer_trx_id          = rctla.customer_trx_id
        AND rctla.line_type               = cv_line_type_l    -- 明細
        AND rctla.customer_trx_line_id    = rctla_t.link_to_cust_trx_line_id(+)
        AND rctla.customer_trx_line_id    = rctlgda.customer_trx_line_id
        AND rctlgda.code_combination_id   = gcc.code_combination_id 
        AND rcta.bill_to_customer_id      = hca_b.cust_account_id
        AND rcta.ship_to_customer_id      = hca_s.cust_account_id(+)
        AND rctla.vat_tax_id              = avtab.vat_tax_id(+)
      ORDER BY
        rcta.trx_number,                  -- 納品伝票No
        rctla.line_number                 -- 納品伝票行No（AR取引明細番号）
    ;
--
    TYPE g_sales_data_ttype IS TABLE OF get_sales_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_sales_data           g_sales_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => ov_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => ov_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => ov_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- 会計帳簿ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:売上実績データファイル名取得
    gv_sales_data_filename := FND_PROFILE.VALUE(cv_sales_data_filename);
    -- 取得エラー時
    IF (gv_sales_data_filename IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sales_data_filename))
                                                       -- XXCFR:売上実績データファイル名
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR: 売上実績データファイル格納パス取得
    gv_sales_data_filepath := FND_PROFILE.VALUE(cv_sales_data_filepath);
    -- 取得エラー時
    IF (gv_sales_data_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sales_data_filepath))
                                                       -- XXCFR:売上実績データファイル格納パス
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:売上実績データ売上返品区分取得
    gv_sd_sold_return_type := FND_PROFILE.VALUE(cv_sd_sold_return_type);
    -- 取得エラー時
    IF (gv_sd_sold_return_type IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_sold_return_type))
                                                       -- XXCFR:売上実績データ売上返品区分
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:売上実績データ売上区分取得
    gv_sd_sales_class := FND_PROFILE.VALUE(cv_sd_sales_class);
    -- 取得エラー時
    IF (gv_sd_sales_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_sales_class))
                                                       -- XXCFR:売上実績データ売上区分
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:売上実績データ納品形態区分取得
    gv_sd_delivery_ptn_class := FND_PROFILE.VALUE(cv_sd_delivery_ptn_class);
    -- 取得エラー時
    IF (gv_sd_delivery_ptn_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_delivery_ptn_class))
                                                       -- XXCFR:売上実績データ納品形態区分
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務処理日付取得処理
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- 取得エラー時
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_013 -- 業務処理日付取得エラー
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_data
   * Description      : 売上実績データ取得 (A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_data(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_data'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN get_sales_data_cur;
--
    -- データの一括取得
    FETCH get_sales_data_cur BULK COLLECT INTO gt_sales_data;
--
    -- 処理件数のセット
    gn_target_cnt := gt_sales_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_sales_data_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : put_sales_data
   * Description      : 売上実績データＣＳＶ作成処理 (A-6)
   ***********************************************************************************/
  PROCEDURE put_sales_data(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_sales_data'; -- プログラム名
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV区切り文字
    cv_enclosed       CONSTANT VARCHAR2(2)  := '"';     -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
    ln_trx_cnt      NUMBER;         -- 取引タイプループカウンタ
    -- 
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;       -- 
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
--
    lv_sales_type       VARCHAR2(2);            -- 売上区分
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_sales_data_filepath,
                      gv_sales_data_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- 前回ファイルが存在している
    IF lb_fexists THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_017 -- ファイルが存在している
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_sales_data_filepath
                       ,gv_sales_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    IF ( gn_target_cnt > 0 ) THEN
      <<out_loop>>
      FOR ln_loop_cnt IN gt_sales_data.FIRST..gt_sales_data.LAST LOOP
--
        -- 出力文字列作成
        lv_csv_text := cv_enclosed || gt_sales_data(ln_loop_cnt).comp_code || cv_enclosed || cv_delimiter
-- Modify 2009.12.13 Ver.1.10 Start
--                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).trx_date, cv_format_date_ymd ) || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).gl_date, cv_format_date_ymd ) || cv_delimiter  -- 納品日(GL記帳日)
-- Modify 2009.12.13 Ver.1.10 End
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).trx_number || cv_enclosed || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).line_number ) || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).ship_to_account_number || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).item_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_object_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_hc_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).dept_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_score_member_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_sales_card_type || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_delivery_base_code || cv_enclosed || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).rec_amount ) || cv_delimiter
                    || cv_unit_sales || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).tax_amount ) || cv_delimiter
                    || cv_enclosed || gv_sd_sold_return_type || cv_enclosed || cv_delimiter
                    || cv_enclosed || gv_sd_sales_class || cv_enclosed || cv_delimiter
                    || cv_enclosed || gv_sd_delivery_ptn_class || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_column_no || cv_enclosed || cv_delimiter
-- Modify 2009.12.13 Ver.1.10 Start
--                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).gl_date, cv_format_date_ymd ) || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).trx_date, cv_format_date_ymd ) || cv_delimiter  -- 検収予定日(取引日)
-- Modify 2009.12.13 Ver.1.10 End
                    || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).tax_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).bill_to_account_number || cv_enclosed || cv_delimiter
-- Add 2011.04.19 Ver.1.11 Start
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- 注文伝票番号
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- 伝票区分
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- 伝票分類コード
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- つり銭切れ時間100円
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- つり銭切れ時間10円
                    || cn_zero                    || cv_delimiter     -- 基準単価（税込）
                    || cn_zero                    || cv_delimiter     -- 売上金額（税込）
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- 売切区分
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- 売切時間
-- Add 2011.04.19 Ver.1.11 End
                    || TO_CHAR ( cd_last_update_date, cv_format_date_ymdhns)
        ;
--
        -- ====================================================
        -- ファイル書き込み
        -- ====================================================
        UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- 商品コードが未設定の場合、メッセージ出力
        IF gt_sales_data(ln_loop_cnt).item_code IS NULL THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_001a02_018 -- 商品コード未設定メッセージ
                                                        ,cv_tkn_trx_type   -- TRX_TYPE
                                                        ,gt_sales_data(ln_loop_cnt).trx_type_name -- 取引タイプ名
                                                       )
                                                       ,1
                                                       ,5000);
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- ====================================================
        -- 処理件数カウントアップ
        -- ====================================================
        ln_target_cnt := ln_target_cnt + 1 ;
--
      END LOOP out_loop;
--
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_target_cnt;
--
    -- 対象データが０件メッセージ
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_012 -- 対象データが0件
                                                   )
                                                   ,1
                                                   ,5000);
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_014 -- ファイルの場所が無効
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_015 -- ファイルをオープンできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_016 -- ファイルに書込みできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_sales_data_reletes
   * Description      : 売上実績連携済テーブル登録 (A-7)
   ***********************************************************************************/
  PROCEDURE insert_sales_data_reletes(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sales_data_reletes'; -- プログラム名
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
    ln_loop_cnt     NUMBER;           -- ループカウンタ
    ln_target_cnt   NUMBER := 0;      -- 対象件数
    ln_customer_trx_id    ra_customer_trx_all.customer_trx_id%TYPE := 0;   -- 取引ID
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    --  売上実績連携済テーブル登録 (A-7)
    -- =====================================================
    IF ( gn_target_cnt > 0 ) THEN
      <<insert_data_loop>>
      FOR ln_loop_cnt IN gt_sales_data.FIRST..gt_sales_data.LAST LOOP
--
        -- ====================================================
        -- 売上実績連携済テーブル登録
        -- ====================================================
        IF ( ln_customer_trx_id <> gt_sales_data(ln_loop_cnt).customer_trx_id ) THEN
          INSERT INTO xxcfr_sales_data_reletes ( 
             customer_trx_id
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login 
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )
          VALUES ( 
             gt_sales_data(ln_loop_cnt).customer_trx_id
            ,cn_created_by
            ,cd_creation_date
            ,cn_last_updated_by
            ,cd_last_update_date
            ,cn_last_update_login
            ,cn_request_id
            ,cn_program_application_id
            ,cn_program_id
            ,cd_program_update_date
          );
--
          -- ====================================================
          -- 処理件数カウントアップ
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1;
--
        END IF;
--
        -- ====================================================
        -- 変数：取引IDへの格納
        -- ====================================================
        ln_customer_trx_id := gt_sales_data(ln_loop_cnt).customer_trx_id;
--
      END LOOP insert_data_loop;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_sales_data_reletes;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    lv_retcode_out VARCHAR2(1);     -- リターン・コード（売上実績データＣＳＶ作成処理）
    lv_errmsg_out  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ（売上実績データＣＳＶ作成処理）
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  売上実績データファイル情報ログ処理(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_001a02_011 -- ファイル名出力メッセージ
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                  ,gv_sales_data_filename)      -- ファイル名
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
    -- =====================================================
    --  業務処理日付取得処理 (A-4)
    -- =====================================================
    get_process_date(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  売上実績データ取得 (A-5)
    -- =====================================================
    get_sales_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  売上実績データＣＳＶ作成処理 (A-6)
    -- =====================================================
    put_sales_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- 戻り値の格納
    lv_retcode_out := lv_retcode;
    lv_errmsg_out := lv_errmsg;
--
    -- =====================================================
    --  売上実績連携済テーブル登録 (A-7)
    -- =====================================================
    insert_sales_data_reletes(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 戻り値の復元
    ov_retcode := lv_retcode_out;
    ov_errmsg  := lv_errmsg_out;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
    errbuf        OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode       OUT     VARCHAR2          --    エラーコード     #固定#
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR001A02C;
/
