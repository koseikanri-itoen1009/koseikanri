CREATE OR REPLACE PACKAGE BODY XXCOK016A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK016A03C(body)
 * Description      : EDIシステムにてインフォマート社へ送信するワークデータ作成
 * MD.050           : インフォマート用赤黒情報作成 MD050_COK_016_A03
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  ins_debit_fb                赤データ作成（FB後）(A-10)
 *  ins_credit_header           新黒ヘッダー情報作成(A-9)
 *  ins_credit_custom_mon       新黒カスタム明細情報作成３(A-12)
 *  ins_credit_custom           新黒カスタム明細情報作成２(A-8)
 *  difference_check            差分チェック(A-5)
 *                              赤データ作成（組み戻し後）(A-6)
 *                              新黒カスタム明細情報作成１(A-7)
 *  ins_snap_data               販手残高スナップショット作成(A-4)
 *  proc_check                  処理チェック(A-3)
 *  del_work                    ワークテーブルデータ削除(A-2)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/02/01    1.0   H.Futamura       新規作成 E_本稼動_17680 インフォマートの電子帳簿保存法対応
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK016A03C';
  -- アプリケーション短縮名
  cv_appli_short_name_xxcok  CONSTANT VARCHAR2(10)    := 'XXCOK'; -- 個別_アプリケーション短縮名
  cv_appli_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP'; -- 共通_アプリケーション短縮名
  -- ステータス
  cv_status_normal           CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージ
  cv_msg_xxcok1_00003        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90003';  -- 警告件数
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  cv_msg_xxcok1_10814        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10814';  -- 元黒作成件数
  cv_msg_xxcok1_10817        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10817';  -- インフォマート赤黒作成用パラメータ出力
  cv_msg_xxcok1_10818        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10818';  -- おもて備考メッセージFB赤用
  cv_msg_xxcok1_10819        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10819';  -- おもて備考メッセージ新黒用
  cv_msg_xxcok1_10820        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10820';  -- おもて備考メッセージ組み戻し赤用
  cv_msg_xxcok1_10821        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10821';  -- 未処理エラーメッセージ
  cv_msg_xxcok1_10822        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10822';  -- 処理済みエラーメッセージ
  cv_msg_xxcok1_10823        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10823';  -- 差分対象件数メッセージ
  cv_msg_xxcok1_10824        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10824';  -- 赤データ作成件数メッセージ
  cv_msg_xxcok1_10825        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10825';  -- 黒データ作成件数メッセージ
  cv_msg_xxcok1_10826        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10826';  -- 削除処理メッセージ
  -- トークン
  cv_tkn_profile             CONSTANT VARCHAR2(7)     := 'PROFILE';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_proc_div            CONSTANT VARCHAR2(8)     := 'PROC_DIV';
  -- プロファイル
  cv_prof_term_name          CONSTANT VARCHAR2(24)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- デフォルト支払条件
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(41)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- 銀行手数料_振込額基準
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- 銀行手数料_基準額未満
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- 銀行手数料_基準額以上
  cv_prof_bm_tax             CONSTANT VARCHAR2(13)    := 'XXCOK1_BM_TAX';                    -- 販売手数料_消費税率
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: 営業単位
  cv_prof_elec_change_item   CONSTANT VARCHAR2(30)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- 電気料（変動）品目コード
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT 0;                                  -- 対象件数
  gn_dif_cnt                 NUMBER DEFAULT 0;                                  -- 差分対象件数
  gn_debit_cnt               NUMBER DEFAULT 0;                                  -- 赤データ作成件数
  gn_credit_cnt              NUMBER DEFAULT 0;                                  -- 黒データ作成件数
  gn_error_cnt               NUMBER DEFAULT 0;                                  -- エラー件数
  gn_skip_cnt                NUMBER DEFAULT 0;                                  -- スキップ件数
  gd_process_date            DATE   DEFAULT NULL;                               -- 業務処理日付
  gv_process_ym              VARCHAR2(6) DEFAULT NULL;                          -- 業務処理年月
  gv_process_ym_pre          VARCHAR2(6) DEFAULT NULL;                          -- 業務処理前年月
  gd_operating_date          DATE   DEFAULT NULL;                               -- 締め支払日導出元日付
  gd_closing_date            DATE   DEFAULT NULL;                               -- 締め日
  gd_schedule_date           DATE   DEFAULT NULL;                               -- 支払予定日
  gn_org_id                  NUMBER;                                            -- 営業単位ID
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 支払条件
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_振込額基準
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額未満
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額以上
  gv_elec_change_item_code   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 電気料（変動）品目コード
  gn_bm_tax                  NUMBER;                                            -- 販売手数料_消費税率
  gn_tax_include_less        NUMBER;                                            -- 税込銀行手数料_基準額未満
  gn_tax_include_more        NUMBER;                                            -- 税込銀行手数料_基準額以上
--
  gv_remarks_fb_deb          fnd_new_messages.message_text%TYPE;                -- おもて備考FB赤用
  gv_remarks_new_cre         fnd_new_messages.message_text%TYPE;                -- おもて備考新黒用
  gv_remarks_re_deb          fnd_new_messages.message_text%TYPE;                -- おもて備考組み戻し赤用
  gv_line_sum                fnd_new_messages.message_text%TYPE;                -- 明細合計行名
--
  TYPE g_no_dif_rtype        IS RECORD
    (supplier_code           xxcok_bm_balance_snap.supplier_code%TYPE
    ,cust_code               xxcok_bm_balance_snap.cust_code%TYPE
    );
  TYPE g_no_dif_sup_rtype    IS RECORD
    (supplier_code           xxcok_bm_balance_snap.supplier_code%TYPE
    );
--
  TYPE g_no_dif_ttype        IS TABLE OF g_no_dif_rtype        INDEX BY BINARY_INTEGER;
  TYPE g_no_dif_sup_ttype    IS TABLE OF g_no_dif_sup_rtype    INDEX BY BINARY_INTEGER;
--
  g_no_dif_tab               g_no_dif_ttype;
  g_no_dif_sup_tab           g_no_dif_sup_ttype;
--
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
  /**********************************************************************************
   * Procedure Name   : ins_debit_fb
   * Description      : 赤データ作成（FB後）(A-10)
   ***********************************************************************************/
  PROCEDURE ins_debit_fb(
    iv_proc_div      IN  VARCHAR2
   ,i_no_dif_sup_tab IN g_no_dif_sup_ttype
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_debit_fb';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    ln_count        NUMBER;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    INSERT INTO xxcok_info_rev_header(
      snapshot_create_ym      -- スナップショット作成年月
     ,snapshot_timing         -- スナップショットタイミング
     ,rev                     -- REV
     ,check_result            -- 妥当性チェック結果
     ,row_id                  -- 元テーブルレコードID
     ,edi_interface_date      -- 連携日（EDI支払案内書）
     ,vendor_code             -- 送付先コード
     ,set_code                -- 通知書書式設定コード
     ,cust_code               -- 顧客コード
     ,cust_name               -- 会社名
     ,dest_post_code          -- 郵便番号
     ,dest_address1           -- 住所
     ,dest_tel                -- 電話番号
     ,fax                     -- FAX番号
     ,dept_name               -- 部署名
     ,send_post_code          -- 郵便番号（送付元）
     ,send_address1           -- 住所（送付元）
     ,send_tel                -- 電話番号（送付元）
     ,num                     -- 番号
     ,payment_date            -- 支払日
     ,closing_date            -- 締め日
     ,closing_date_min        -- 最小締め日
     ,notifi_amt              -- おもての通知金額
     ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
     ,tax_amt_8               -- 軽減8%消費税額
     ,total_amt_8             -- 軽減8%合計金額（税込）
     ,total_sales_qty         -- 販売本数合計
     ,total_sales_amt         -- 販売金額合計
     ,sales_fee               -- 販売手数料
     ,electric_amt            -- 電気代等合計　税抜
     ,tax_amt                 -- 消費税
     ,transfer_fee            -- 振込手数料 税込
     ,payment_amt             -- お支払金額 税込
     ,remarks                 -- おもて備考
     ,bank_code               -- 銀行コード
     ,bank_name               -- 銀行名
     ,branch_code             -- 支店コード
     ,branch_name             -- 支店名
     ,bank_holder_name_alt    -- 口座名
     ,tax_div                 -- 税区分
     ,target_div              -- 対象区分
     ,created_by              -- 作成者
     ,creation_date           -- 作成日
     ,last_updated_by         -- 最終更新者
     ,last_update_date        -- 最終更新日
     ,last_update_login       -- 最終更新ログイン
     ,request_id              -- 要求ID
     ,program_application_id  -- コンカレント・プログラム・アプリケーションID
     ,program_id              -- コンカレント・プログラムID
     ,program_update_date     -- プログラム更新日
    )
    SELECT
        /*+ INDEX(xirh1 xxcok_info_rev_head_n01)
            INDEX(xirh2 xxcok_info_rev_head_n02) */
        xirh1.snapshot_create_ym                   AS  snapshot_create_ym      -- スナップショット作成年月
       ,iv_proc_div                                AS  snapshot_timing         -- スナップショットタイミング
       ,'2'                                        AS  rev                     -- REV（2:赤（FB）)
       ,'0'                                        AS  check_result            -- 妥当性チェック結果
       ,NULL                                       AS  row_id                  -- 元テーブルレコードID
       ,NULL                                       AS  edi_interface_date      -- 連携日（EDI支払案内書）
       ,xirh1.vendor_code                          AS  vendor_code             -- 送付先コード
       ,xirh1.set_code                             AS  set_code                -- 通知書書式設定コード
       ,xirh1.cust_code                            AS  cust_code               -- 顧客コード
       ,xirh1.cust_name                            AS  cust_name               -- 会社名
       ,xirh1.dest_post_code                       AS  dest_post_code          -- 郵便番号
       ,xirh1.dest_address1                        AS  dest_address1           -- 住所
       ,xirh1.dest_tel                             AS  dest_tel                -- 電話番号
       ,xirh1.fax                                  AS  fax                     -- FAX番号
       ,xirh1.dept_name                            AS  dept_name               -- 部署名
       ,xirh1.send_post_code                       AS  send_post_code          -- 郵便番号（送付元）
       ,xirh1.send_address1                        AS  send_address1           -- 住所（送付元）
       ,xirh1.send_tel                             AS  send_tel                -- 電話番号（送付元）
       ,xirh1.num                                  AS  num                     -- 番号
       ,xirh1.payment_date                         AS  payment_date            -- 支払日
       ,xirh1.closing_date                         AS  closing_date            -- 締め日
       ,xirh1.closing_date_min                     AS  closing_date_min        -- 最小締め日
       ,(xirh1.notifi_amt) * -1                    AS  notifi_amt              -- おもての通知金額
       ,(xirh1.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
       ,(xirh1.tax_amt_8) * -1                     AS  tax_amt_8               -- 軽減8%消費税額
       ,(xirh1.total_amt_8) * -1                   AS  total_amt_8             -- 軽減8%合計金額（税込）
       ,(xirh1.total_sales_qty) * -1               AS  total_sales_qty         -- 販売本数合計
       ,(xirh1.total_sales_amt) * -1               AS  total_sales_amt         -- 販売金額合計
       ,(xirh1.sales_fee) * -1                     AS  sales_fee               -- 販売手数料
       ,(xirh1.electric_amt) * -1                  AS  electric_amt            -- 電気代等合計 税抜
       ,(xirh1.tax_amt) * -1                       AS  tax_amt                 -- 消費税
       ,(xirh1.transfer_fee) * -1                  AS  transfer_fee            -- 振込手数料 税込
       ,(xirh1.payment_amt) * -1                   AS  payment_amt             -- お支払金額 税込
       ,'"'||SUBSTR(gv_remarks_fb_deb,1,500)||'"'  AS  remarks                 -- おもて備考
       ,xirh1.bank_code                            AS  bank_code               -- 銀行コード
       ,xirh1.bank_name                            AS  bank_name               -- 銀行名
       ,xirh1.branch_code                          AS  branch_code             -- 支店コード
       ,xirh1.branch_name                          AS  branch_name             -- 支店名
       ,xirh1.bank_holder_name_alt                 AS  bank_holder_name_alt    -- 口座名
       ,xirh1.tax_div                              AS  tax_div                 -- 税区分
       ,xirh1.target_div                           AS  target_div              -- 対象区分
       ,cn_created_by                              AS  created_by              -- 作成者
       ,SYSDATE                                    AS  creation_date           -- 作成日
       ,cn_last_updated_by                         AS  last_updated_by         -- 最終更新者
       ,SYSDATE                                    AS  last_update_date        -- 最終更新日
       ,cn_last_update_login                       AS  last_update_login       -- 最終更新ログイン
       ,cn_request_id                              AS  request_id              -- 要求ID
       ,cn_program_application_id                  AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
       ,cn_program_id                              AS  program_id              -- コンカレント・プログラムID
       ,SYSDATE                                    AS  program_update_date     -- プログラム更新日
    FROM   xxcok_info_rev_header    xirh1  -- 元黒
          ,xxcok_info_rev_header    xirh2  -- 新黒
    WHERE  xirh2.snapshot_create_ym                =  gv_process_ym
    AND    xirh2.snapshot_timing                   =  iv_proc_div
    AND    xirh2.rev                               =  '3' -- 新黒（FB）
    AND    xirh2.check_result                      =  '0' -- 対象
    AND    xirh2.notifi_amt                        >  0
    AND    xirh1.vendor_code                       =  xirh2.vendor_code
    AND    xirh1.snapshot_create_ym                =  xirh2.snapshot_create_ym
    AND    xirh1.snapshot_timing                   =  '1' -- 2営
    AND    xirh1.rev                               =  '1' -- 元黒（2営）
    AND    xirh1.notifi_amt                        >  0
    ;
--
    -- 赤データ作成件数カウント
    gn_debit_cnt := SQL%ROWCOUNT;
--
    -- 差分があるもので赤が作成されていない仕入先を登録する
    FOR i IN 1..i_no_dif_sup_tab.COUNT LOOP
      -- 赤データが作成されているかチェック
      SELECT COUNT(1)
      INTO   ln_count
      FROM   xxcok_info_rev_header  xirh   -- 新黒
      WHERE  xirh.snapshot_create_ym     = gv_process_ym
      AND    xirh.snapshot_timing        = iv_proc_div
      AND    xirh.rev                    = '2' -- 赤（FB）
      AND    xirh.check_result           = '0' -- 対象
      AND    xirh.vendor_code            = i_no_dif_sup_tab(i).supplier_code
      ;
--
      -- 作成されていない場合作成
      IF ( ln_count = 0 ) THEN
        INSERT INTO xxcok_info_rev_header(
          snapshot_create_ym      -- スナップショット作成年月
         ,snapshot_timing         -- スナップショットタイミング
         ,rev                     -- REV
         ,check_result            -- 妥当性チェック結果
         ,row_id                  -- 元テーブルレコードID
         ,edi_interface_date      -- 連携日（EDI支払案内書）
         ,vendor_code             -- 送付先コード
         ,set_code                -- 通知書書式設定コード
         ,cust_code               -- 顧客コード
         ,cust_name               -- 会社名
         ,dest_post_code          -- 郵便番号
         ,dest_address1           -- 住所
         ,dest_tel                -- 電話番号
         ,fax                     -- FAX番号
         ,dept_name               -- 部署名
         ,send_post_code          -- 郵便番号（送付元）
         ,send_address1           -- 住所（送付元）
         ,send_tel                -- 電話番号（送付元）
         ,num                     -- 番号
         ,payment_date            -- 支払日
         ,closing_date            -- 締め日
         ,closing_date_min        -- 最小締め日
         ,notifi_amt              -- おもての通知金額
         ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
         ,tax_amt_8               -- 軽減8%消費税額
         ,total_amt_8             -- 軽減8%合計金額（税込）
         ,total_sales_qty         -- 販売本数合計
         ,total_sales_amt         -- 販売金額合計
         ,sales_fee               -- 販売手数料
         ,electric_amt            -- 電気代等合計　税抜
         ,tax_amt                 -- 消費税
         ,transfer_fee            -- 振込手数料 税込
         ,payment_amt             -- お支払金額 税込
         ,remarks                 -- おもて備考
         ,bank_code               -- 銀行コード
         ,bank_name               -- 銀行名
         ,branch_code             -- 支店コード
         ,branch_name             -- 支店名
         ,bank_holder_name_alt    -- 口座名
         ,tax_div                 -- 税区分
         ,target_div              -- 対象区分
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,last_update_login       -- 最終更新ログイン
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
         ,program_update_date     -- プログラム更新日
        )
        SELECT
            /*+ INDEX(xirh xxcok_info_rev_head_n03) */
            xirh.snapshot_create_ym                    AS  snapshot_create_ym      -- スナップショット作成年月
           ,iv_proc_div                                AS  snapshot_timing         -- スナップショットタイミング
           ,'2'                                        AS  rev                     -- REV（2:赤（FB）)
           ,'0'                                        AS  check_result            -- 妥当性チェック結果
           ,NULL                                       AS  row_id                  -- 元テーブルレコードID
           ,NULL                                       AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xirh.vendor_code                           AS  vendor_code             -- 送付先コード
           ,xirh.set_code                              AS  set_code                -- 通知書書式設定コード
           ,xirh.cust_code                             AS  cust_code               -- 顧客コード
           ,xirh.cust_name                             AS  cust_name               -- 会社名
           ,xirh.dest_post_code                        AS  dest_post_code          -- 郵便番号
           ,xirh.dest_address1                         AS  dest_address1           -- 住所
           ,xirh.dest_tel                              AS  dest_tel                -- 電話番号
           ,xirh.fax                                   AS  fax                     -- FAX番号
           ,xirh.dept_name                             AS  dept_name               -- 部署名
           ,xirh.send_post_code                        AS  send_post_code          -- 郵便番号（送付元）
           ,xirh.send_address1                         AS  send_address1           -- 住所（送付元）
           ,xirh.send_tel                              AS  send_tel                -- 電話番号（送付元）
           ,xirh.num                                   AS  num                     -- 番号
           ,xirh.payment_date                          AS  payment_date            -- 支払日
           ,xirh.closing_date                          AS  closing_date            -- 締め日
           ,xirh.closing_date_min                      AS  closing_date_min        -- 最小締め日
           ,(xirh.notifi_amt) * -1                     AS  notifi_amt              -- おもての通知金額
           ,(xirh.total_amt_no_tax_8) * -1             AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
           ,(xirh.tax_amt_8) * -1                      AS  tax_amt_8               -- 軽減8%消費税額
           ,(xirh.total_amt_8) * -1                    AS  total_amt_8             -- 軽減8%合計金額（税込）
           ,(xirh.total_sales_qty) * -1                AS  total_sales_qty         -- 販売本数合計
           ,(xirh.total_sales_amt) * -1                AS  total_sales_amt         -- 販売金額合計
           ,(xirh.sales_fee) * -1                      AS  sales_fee               -- 販売手数料
           ,(xirh.electric_amt) * -1                   AS  electric_amt            -- 電気代等合計 税抜
           ,(xirh.tax_amt) * -1                        AS  tax_amt                 -- 消費税
           ,(xirh.transfer_fee) * -1                   AS  transfer_fee            -- 振込手数料 税込
           ,(xirh.payment_amt) * -1                    AS  payment_amt             -- お支払金額 税込
           ,'"'||SUBSTR(gv_remarks_fb_deb,1,500)||'"'  AS  remarks                 -- おもて備考
           ,xirh.bank_code                             AS  bank_code               -- 銀行コード
           ,xirh.bank_name                             AS  bank_name               -- 銀行名
           ,xirh.branch_code                           AS  branch_code             -- 支店コード
           ,xirh.branch_name                           AS  branch_name             -- 支店名
           ,xirh.bank_holder_name_alt                  AS  bank_holder_name_alt    -- 口座名
           ,xirh.tax_div                               AS  tax_div                 -- 税区分
           ,xirh.target_div                            AS  target_div              -- 対象区分
           ,cn_created_by                              AS  created_by              -- 作成者
           ,SYSDATE                                    AS  creation_date           -- 作成日
           ,cn_last_updated_by                         AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                    AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                       AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                              AS  request_id              -- 要求ID
           ,cn_program_application_id                  AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                              AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                    AS  program_update_date     -- プログラム更新日
        FROM   xxcok_info_rev_header    xirh  -- 元黒
        WHERE  xirh.snapshot_create_ym                = gv_process_ym
        AND    xirh.snapshot_timing                   = '1' -- 2営
        AND    xirh.rev                               = '1' -- 元黒（2営）
        AND    xirh.vendor_code                       = i_no_dif_sup_tab(i).supplier_code
        AND    xirh.notifi_amt                        > 0
        ;
--
        -- 赤データ作成件数カウント
        gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
      END IF;
    END LOOP;
--
    INSERT INTO xxcok_info_rev_custom (
      snapshot_create_ym          -- スナップショット作成年月
     ,snapshot_timing             -- スナップショットタイミング 
     ,rev                         -- REV
     ,check_result                -- 妥当性チェック結果
     ,row_id                      -- 元テーブルレコードID
     ,edi_interface_date          -- 連携日（EDI支払案内書）
     ,vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_type                   -- 計算条件
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,contract                    -- ご契約内容
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,bottle_code                 -- 容器区分コード
     ,salling_price               -- 売価金額
     ,REBATE_RATE                 -- 割戻率
     ,REBATE_AMT                  -- 割戻額
     ,tax_code                    -- 税コード
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT
        xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- スナップショット作成年月
       ,iv_proc_div                             AS  snapshot_timing         -- スナップショットタイミング
       ,'2'                                     AS  rev                     -- REV（2:赤（FB）)
       ,'0'                                     AS  check_result            -- 妥当性チェック結果（0:対象）
       ,NULL                                    AS  row_id                  -- 元テーブルレコードID
       ,NULL                                    AS  edi_interface_date      -- 連携日（EDI支払案内書）
       ,xirc.vendor_code                        AS  vendor_code             -- 送付先コード
       ,xirc.cust_code                          AS  cust_code               -- 顧客コード
       ,xirc.inst_dest                          AS  inst_dest               -- 設置場所
       ,xirc.calc_type                          AS  calc_type               -- 計算条件
       ,xirc.calc_sort                          AS  calc_sort               -- 計算条件ソート順
       ,xirc.sell_bottle                        AS  sell_bottle             -- 売価／容器
       ,(xirc.sales_qty) * -1                   AS  sales_qty               -- 販売本数
       ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- 販売金額（税込）
       ,(xirc.sales_amt) * -1                   AS  sales_amt               -- 販売金額（税抜）
       ,xirc.contract                           AS  contract                -- ご契約内容
       ,(xirc.sales_fee) * -1                   AS  sales_fee               -- 販売手数料（税抜）
       ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- 消費税
       ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- 販売手数料（税込）
       ,xirc.bottle_code                        AS  bottle_code             -- 容器区分コード
       ,xirc.salling_price                      AS  salling_price           -- 売価金額
       ,xirc.rebate_rate                        AS  rebate_rate             -- 割戻率
       ,xirc.rebate_amt                         AS  rebate_amt              -- 割戻額
       ,xirc.tax_code                           AS  tax_code                -- 税コード
       ,xirc.tax_div                            AS  tax_div                 -- 税区分
       ,xirc.target_div                         AS  target_div              -- 対象区分
       ,cn_created_by                           AS  created_by              -- 作成者
       ,SYSDATE                                 AS  creation_date           -- 作成日
       ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
       ,SYSDATE                                 AS  last_update_date        -- 最終更新日
       ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
       ,cn_request_id                           AS  request_id              -- 要求ID
       ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
       ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
       ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
    FROM   xxcok_info_rev_header     xirh  -- カスタムヘッダー:元黒
          ,xxcok_info_rev_custom     xirc  -- カスタム明細:元黒
    WHERE  xirh.snapshot_create_ym                 = gv_process_ym
    AND    xirh.snapshot_timing                    = '2' -- FB
    AND    xirh.rev                                = '2' -- 赤（FB）
    AND    xirh.check_result                       = '0' -- 対象
    AND    xirh.vendor_code                        = xirc.vendor_code
    AND    xirh.snapshot_create_ym                 = xirc.snapshot_create_ym
    AND    xirc.snapshot_timing                    = '1'  -- 2営
    AND    xirc.rev                                = '1'  -- 元黒（2営）
    ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_debit_fb;
--
  /**********************************************************************************
   * Procedure Name   : ins_credit_header
   * Description      : 新黒ヘッダー情報作成(A-9)
   ***********************************************************************************/
  PROCEDURE ins_credit_header(
    iv_proc_div   IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_credit_header';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 抽出対象外取得
    CURSOR l_check_ex_cur
    IS
      SELECT xirh2.vendor_code        AS  vendor_code
      FROM   xxcok_info_rev_header    xirh1  -- 元黒
            ,xxcok_info_rev_header    xirh2  -- 新黒
      WHERE  xirh2.snapshot_create_ym = gv_process_ym
      AND    xirh2.snapshot_timing    = iv_proc_div
      AND    xirh2.rev                = '3'  -- 新黒（FB）
      AND    xirh2.request_id         = cn_request_id
      AND    xirh2.notifi_amt         <= 0
      AND    xirh1.snapshot_create_ym = xirh2.snapshot_create_ym
      AND    xirh1.snapshot_timing    = '1'  -- 2営
      AND    xirh1.rev                = '1'  -- 元黒（2営）
      AND    xirh1.vendor_code        = xirh2.vendor_code
      AND    xirh1.notifi_amt         <= 0
      ;
--
    l_check_ex_rec    l_check_ex_cur%ROWTYPE;
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ヘッダー情報登録
    -- ===============================================
    INSERT INTO xxcok_info_rev_header(
      snapshot_create_ym      -- スナップショット作成年月
     ,snapshot_timing         -- スナップショットタイミング
     ,rev                     -- REV
     ,check_result            -- 妥当性チェック結果
     ,row_id                  -- 元テーブルレコードID
     ,edi_interface_date      -- 連携日（EDI支払案内書）
     ,set_code                -- 通知書書式設定コード
     ,cust_code               -- 顧客コード
     ,cust_name               -- 会社名
     ,dest_post_code          -- 郵便番号
     ,dest_address1           -- 住所
     ,dest_tel                -- 電話番号
     ,fax                     -- FAX番号
     ,dept_name               -- 部署名
     ,send_post_code          -- 郵便番号（送付元）
     ,send_address1           -- 住所（送付元）
     ,send_tel                -- 電話番号（送付元）
     ,num                     -- 番号
     ,vendor_code             -- 送付先コード
     ,payment_date            -- 支払日
     ,closing_date            -- 締め日
     ,closing_date_min        -- 最小締め日
     ,notifi_amt              -- おもての通知金額
     ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
     ,tax_amt_8               -- 軽減8%消費税額
     ,total_amt_8             -- 軽減8%合計金額（税込）
     ,total_sales_qty         -- 販売本数合計
     ,total_sales_amt         -- 販売金額合計
     ,sales_fee               -- 販売手数料
     ,electric_amt            -- 電気代等合計　税抜
     ,tax_amt                 -- 消費税
     ,transfer_fee            -- 振込手数料　税込
     ,payment_amt             -- お支払金額　税込
     ,remarks                 -- おもて備考
     ,bank_code               -- 銀行コード
     ,bank_name               -- 銀行名
     ,branch_code             -- 支店コード
     ,branch_name             -- 支店名
     ,bank_holder_name_alt    -- 口座名
     ,tax_div                 -- 税区分
     ,target_div              -- 対象区分
     ,created_by              -- 作成者
     ,creation_date           -- 作成日
     ,last_updated_by         -- 最終更新者
     ,last_update_date        -- 最終更新日
     ,last_update_login       -- 最終更新ログイン
     ,request_id              -- 要求ID
     ,program_application_id  -- コンカレント・プログラム・アプリケーションID
     ,program_id              -- コンカレント・プログラムID
     ,program_update_date     -- プログラム更新日
    )
    SELECT  /*+ leading(xirh xbbs xirc sum_t sum_ne sum_e) use_nl(xbbs) use_nl(sum_t) use_nl(sum_ne) use_nl(sum_e) */
            xbbs.snapshot_create_ym               AS  snapshot_create_ym
           ,xbbs.snapshot_timing                  AS  snapshot_timing
           ,'3'                                   AS  rev
           ,'0'                                   AS  check_result
           ,NULL                                  AS  row_id
           ,NULL                                  AS  edi_interface_date
           ,CASE
              WHEN xirh.tax_div = '1' AND NVL(sum_e.sales_fee,0) = 0
              THEN '0'
              WHEN xirh.tax_div = '1' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '1'
              WHEN xirh.tax_div = '2' AND NVL(sum_e.sales_fee,0) = 0
              THEN '2'
              WHEN xirh.tax_div = '2' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '3'
            END                                   AS  set_code                -- 通知書書式設定コード
           ,NULL                                  AS  cust_code               -- 顧客コード
           ,xirh.cust_name                        AS  cust_name               -- 会社名
           ,xirh.dest_post_code                   AS  dest_post_code          -- 郵便番号
           ,xirh.dest_address1                    AS  dest_address1           -- 住所
           ,xirh.dest_tel                         AS  dest_tel                -- 電話番号
           ,xirh.fax                              AS  fax                     -- FAX番号
           ,xirh.dept_name                        AS  dept_name               -- 部署名
           ,xirh.send_post_code                   AS  send_post_code          -- 郵便番号（送付元）
           ,xirh.send_address1                    AS  send_address1           -- 住所（送付元）
           ,xirh.send_tel                         AS  send_tel                -- 電話番号（送付元）
           ,xbbs.supplier_code                    AS  num                     -- 番号
           ,xbbs.supplier_code                    AS  vendor_code             -- 送付先コード
           ,xirh.payment_date                     AS  payment_date            -- 支払日
           ,MAX(xbbs.closing_date)                AS  closing_date            -- 締め日
           ,MIN(xbbs.closing_date)                AS  closing_date_min        -- 最小締め日
           ,CASE
              -- 外税
              WHEN xirh.tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN xbbs.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --内税
              WHEN xirh.tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN xbbs.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  notifi_amt              -- おもての通知金額
           ,NVL(sum_t.sales_amt,0)                AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
           ,NVL(sum_t.sales_tax_amt,0) - NVL(sum_t.sales_amt,0)
                                                  AS  tax_amt_8               -- 軽減8%消費税額
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_amt_8             -- 軽減8%合計金額（税込）
           ,NVL(sum_t.sales_qty,0)                AS  total_sales_qty         -- 販売本数合計
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_sales_amt         -- 販売金額合計
           ,NVL(sum_ne.sales_fee,0)               AS  sales_fee               -- 販売手数料 税抜／販売手数料 税込
           ,NVL(sum_e.sales_fee,0)                AS  electric_amt            -- 電気代等合計 税抜／電気代等合計 税込
           ,NVL(sum_t.tax_amt,0)                  AS  tax_amt                 -- 消費税／内消費税
           ,CASE
              WHEN xbbs.bank_charge_bearer = 'I'
              THEN 0
              -- 外税
              WHEN xirh.tax_div = '1'
                  AND xbbs.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    xirh.tax_div = '1'
                  AND xbbs.bank_charge_bearer <> 'I' 
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
              --内税
              WHEN    xirh.tax_div = '2'
                  AND xbbs.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    xirh.tax_div = '2'
                  AND xbbs.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
            END * -1                              AS  transfer_fee            -- 振込手数料 税込
           ,CASE
              -- 外税
              WHEN xirh.tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN xbbs.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --内税
              WHEN xirh.tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN xbbs.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    xbbs.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  payment_amt             -- お支払金額 税込
           ,SUBSTR( '"' || gv_remarks_new_cre || '"', 1, 500 )
                                                  AS  remarks                 -- おもて備考
           ,NULL                                  AS  bank_code               -- 銀行コード
           ,NULL                                  AS  bank_name               -- 銀行名
           ,NULL                                  AS  branch_code             -- 支店コード
           ,NULL                                  AS  branch_name             -- 支店名
           ,NULL                                  AS  bank_holder_name_alt    -- 口座名
           ,xirh.tax_div                          AS  tax_div                 -- 税区分
           ,xirh.target_div                       AS  target_div              -- 対象区分
           ,cn_created_by                         AS  created_by              -- 作成者
           ,SYSDATE                               AS  creation_date           -- 作成日
           ,cn_last_updated_by                    AS  last_updated_by         -- 最終更新者
           ,SYSDATE                               AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                  AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                         AS  request_id              -- 要求ID
           ,cn_program_application_id             AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                         AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                               AS  program_update_date     -- プログラム更新日
    FROM    xxcok_bm_balance_snap     xbbs        -- 販手残高テーブルスナップショット
           ,xxcok_info_rev_header     xirh        -- インフォマート用赤黒（ヘッダー）
           ,(SELECT SUM(xirc.sales_qty)      AS  sales_qty
                   ,SUM(xirc.sales_tax_amt)  AS  sales_tax_amt
                   ,SUM(xirc.tax_amt)        AS  tax_amt
                   ,SUM(xirc.sales_amt)      AS  sales_amt
                   ,xirc.vendor_code         AS  vendor_code
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort = 6
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- 新黒（FB）
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
            ) sum_t                               -- サマリ（合計）
           ,(SELECT CASE
                      WHEN xirc.tax_div = '1'
                      THEN SUM(xirc.sales_fee)
                      WHEN xirc.tax_div = '2'
                      THEN SUM(xirc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xirc.vendor_code
                   ,xirc.tax_div
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort IN (1,2,3,4) -- 売価別、容器別、一律条件、定額条件
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- 新黒（FB）
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
                     ,xirc.tax_div
            ) sum_ne                              -- サマリ（電気代除く）
           ,(SELECT CASE
                      WHEN xirc.tax_div = '1'
                      THEN SUM(xirc.sales_fee)
                      WHEN xirc.tax_div = '2'
                      THEN SUM(xirc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xirc.vendor_code
             FROM   xxcok_info_rev_custom  xirc
             WHERE  xirc.calc_sort = 5
             AND    xirc.snapshot_create_ym = gv_process_ym
             AND    xirc.snapshot_timing    = iv_proc_div
             AND    xirc.rev                = '3' -- 新黒（FB）
             AND    xirc.request_id         = cn_request_id
             GROUP BY xirc.vendor_code
                     ,xirc.tax_div
            ) sum_e                               -- サマリ（電気代）
    WHERE   xbbs.snapshot_create_ym                = gv_process_ym
    AND     xbbs.snapshot_timing                   = iv_proc_div
    AND EXISTS (
          SELECT 1
          FROM   xxcok_info_rev_custom  xirc
          WHERE  xirc.snapshot_create_ym           = xbbs.snapshot_create_ym
          AND    xirc.snapshot_timing              = xbbs.snapshot_timing
          AND    xirc.rev                          = '3'  -- 新黒（FB）
          AND    xirc.vendor_code                  = xbbs.supplier_code
          AND    xirc.request_id                   = cn_request_id )
    AND     xbbs.supplier_code                     = sum_t.vendor_code(+)
    AND     xbbs.supplier_code                     = sum_ne.vendor_code(+)
    AND     xbbs.supplier_code                     = sum_e.vendor_code(+)
    AND     xirh.vendor_code                       = xbbs.supplier_code
    AND     xirh.snapshot_create_ym                = gv_process_ym
    AND     xirh.snapshot_timing                   = '1'  -- 2営
    AND     xirh.rev                               = '1'  -- 元黒（2営）
    GROUP BY
            xbbs.supplier_code
           ,xbbs.snapshot_create_ym
           ,xbbs.snapshot_timing
           ,xirh.tax_div
           ,xirh.target_div
           ,xirh.cust_name
           ,xirh.dest_post_code
           ,xirh.dest_address1
           ,xirh.dest_tel
           ,xirh.fax
           ,xirh.dept_name
           ,xirh.send_post_code
           ,xirh.send_address1
           ,xirh.send_tel
           ,xirh.payment_date
           ,sum_ne.sales_fee
           ,sum_e.sales_fee
           ,sum_t.tax_amt
           ,sum_t.sales_amt
           ,sum_t.sales_tax_amt
           ,sum_t.sales_qty
           ,xirh.tax_div
           ,xirh.target_div
           ,xbbs.bank_charge_bearer
    ;
--
    -- 新黒データ作成件数カウント
    gn_credit_cnt := SQL%ROWCOUNT;
--
    -- ===============================================
    -- 抽出対象外チェック
    -- ===============================================
    <<check_ex_loop>>
    FOR l_check_ex_rec IN l_check_ex_cur LOOP
      -- ===============================================
      -- インフォマート用赤黒テーブル更新
      -- ===============================================
      UPDATE xxcok_info_rev_header xirh  -- インフォマート用赤黒（ヘッダー）
      SET    xirh.check_result = '1'    -- 対象外
      WHERE  xirh.snapshot_create_ym = gv_process_ym
      AND    xirh.snapshot_timing    = iv_proc_div
      AND    xirh.rev                = '3'  -- 新黒（FB）
      AND    xirh.request_id         = cn_request_id
      AND    xirh.vendor_code        = l_check_ex_rec.vendor_code
      ;
--
      UPDATE xxcok_info_rev_custom xirc  -- インフォマート用赤黒（カスタム明細）
      SET    xirc.check_result = '1'    -- 対象外
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- 新黒（FB）
      AND    xirc.request_id         = cn_request_id
      AND    xirc.vendor_code        = l_check_ex_rec.vendor_code
      ;
    END LOOP check_ex_loop;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_credit_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_credit_custom_mon
   * Description      : 新黒カスタム明細情報作成３(A-12)
   ***********************************************************************************/
  PROCEDURE ins_credit_custom_mon(
    iv_proc_div   IN  VARCHAR2
   ,i_no_dif_tab  IN  g_no_dif_ttype
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(25) := 'ins_credit_custom_mon';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 定額のみデータ取得
    CURSOR l_fixed_amt_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- 新黒（FB）
      AND    xirc.calc_type          = '40' -- 40:定額
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code        = xirc.vendor_code
                      AND    xirc2.cust_code          = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev                = xirc.rev
                      AND    xirc2.request_id         = xirc.request_id
                      AND    xirc2.calc_type          IN ('10','20','30')
                     )
    ;
--
    l_fixed_amt_rec    l_fixed_amt_cur%ROWTYPE;
--
    -- 電気代のみデータ取得
    CURSOR l_electric_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- 新黒（FB）
      AND    xirc.calc_type  = '50'  -- 50:電気代
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code = xirc.vendor_code
                      AND    xirc2.cust_code   = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev         = xirc.rev
                      AND    xirc2.request_id  = xirc.request_id
                      AND    xirc2.calc_type   IN ('10','20','30','40')
                     )
    ;
--
    l_electric_rec    l_electric_cur%ROWTYPE;
--
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 同仕入先・顧客で月跨ぎのデータで差がない顧客を登録
    -- ===============================================
    FOR i IN 1..i_no_dif_tab.COUNT LOOP
--
      INSERT INTO xxcok_info_rev_custom (
        snapshot_create_ym          -- スナップショット作成年月
       ,snapshot_timing             -- スナップショットタイミング 
       ,rev                         -- REV
       ,check_result                -- 妥当性チェック結果
       ,row_id                      -- 元テーブルレコードID
       ,edi_interface_date          -- 連携日（EDI支払案内書）
       ,vendor_code                 -- 送付先コード
       ,cust_code                   -- 顧客コード
       ,inst_dest                   -- 設置場所
       ,calc_type                   -- 計算条件
       ,calc_sort                   -- 計算条件ソート順
       ,sell_bottle                 -- 売価／容器
       ,sales_qty                   -- 販売本数
       ,sales_tax_amt               -- 販売金額（税込）
       ,sales_amt                   -- 販売金額（税抜）
       ,contract                    -- ご契約内容
       ,sales_fee                   -- 販売手数料（税抜）
       ,tax_amt                     -- 消費税
       ,sales_tax_fee               -- 販売手数料（税込）
       ,bottle_code                 -- 容器区分コード
       ,salling_price               -- 売価金額
       ,rebate_rate                 -- 割戻率
       ,rebate_amt                  -- 割戻額
       ,tax_code                    -- 税コード
       ,tax_div                     -- 税区分
       ,target_div                  -- 対象区分
       ,created_by                  -- 作成者
       ,creation_date               -- 作成日
       ,last_updated_by             -- 最終更新者
       ,last_update_date            -- 最終更新日
       ,last_update_login           -- 最終更新ログイン
       ,request_id                  -- 要求ID
       ,program_application_id      -- コンカレント・プログラム・アプリケーションID
       ,program_id                  -- コンカレント・プログラムID
       ,program_update_date         -- プログラム更新日
      )
      SELECT
          xbbs.snapshot_create_ym                 AS  snapshot_create_ym      -- スナップショット作成年月
         ,xbbs.snapshot_timing                    AS  snapshot_timing         -- スナップショットタイミング
         ,'3'                                     AS  rev                     -- REV（3:新黒（FB）)
         ,'0'                                     AS  check_result            -- 妥当性チェック結果（0:対象）
         ,NULL                                    AS  row_id                  -- 元テーブルレコードID
         ,NULL                                    AS  edi_interface_date      -- 連携日（EDI支払案内書）
         ,xbbs.supplier_code                      AS  vendor_code             -- 送付先コード
         ,xcbs.delivery_cust_code                 AS  cust_code               -- 顧客コード
         ,SUBSTR( xbbs.cust_name, 1, 50 )         AS  inst_dest               -- 設置場所
         ,xcbs.calc_type                          AS  calc_type               -- 計算条件
         ,flv2.calc_type_sort                     AS  calc_sort               -- 計算条件ソート順
         ,CASE xcbs.calc_type
            WHEN '10'
            THEN TO_CHAR( xcbs.selling_price )
            WHEN '20'
            THEN SUBSTR( flv1.container_type_name, 1, 10 )
            ELSE flv2.disp
          END                                     AS  sell_bottle             -- 売価／容器
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN NULL
            ELSE SUM( xcbs.delivery_qty )
          END                                     AS  sales_qty               -- 販売本数
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN NULL
            ELSE SUM( xcbs.selling_amt_tax )
          END                                     AS  sales_tax_amt           -- 販売金額（税込）
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN NULL
            ELSE SUM( xcbs.selling_amt_no_tax )
          END                                     AS  sales_amt               -- 販売金額（税抜）
         ,CASE
            WHEN ( xcbs.rebate_rate IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
            THEN xcbs.rebate_rate || '%'
            WHEN ( xcbs.rebate_amt IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
            THEN xcbs.rebate_amt || '円'
          END                                     AS  contract                -- ご契約内容
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN SUM( xcbs.electric_amt_no_tax )
            ELSE SUM( xcbs.cond_bm_amt_no_tax )
          END                                     AS  sales_fee               -- 販売手数料（税抜）
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN SUM( xcbs.electric_tax_amt )
            ELSE SUM( xcbs.cond_tax_amt )
          END                                     AS  tax_amt                 -- 消費税
         ,CASE xcbs.calc_type
            WHEN '50'
            THEN SUM( xcbs.electric_amt_tax )
            ELSE SUM( xcbs.cond_bm_amt_tax )
          END                                     AS  sales_tax_fee           -- 販売手数料（税込）
         ,flv1.container_type_code                AS  bottle_code             -- 容器区分コード
         ,xcbs.selling_price                      AS  salling_price           -- 売価金額
         ,xcbs.rebate_rate                        AS  rebate_rate             -- 割戻率
         ,xcbs.rebate_amt                         AS  rebate_amt              -- 割戻額
         ,xbbs.tax_code                           AS  tax_code                -- 税コード
         ,CASE
            WHEN xbbs.bm_tax_kbn = '1'
            THEN '2'
            WHEN xbbs.bm_tax_kbn IN ('2','3')
            THEN '1'
          END                                     AS  tax_div                 -- 税区分
         ,SUBSTR( xbbs.supplier_code, -1, 1 )     AS  target_div              -- 対象区分
         ,cn_created_by                           AS  created_by              -- 作成者
         ,SYSDATE                                 AS  creation_date           -- 作成日
         ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
         ,SYSDATE                                 AS  last_update_date        -- 最終更新日
         ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
         ,cn_request_id                           AS  request_id              -- 要求ID
         ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
         ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
         ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
      FROM  xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
           ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
           ,(SELECT flv.attribute1 AS container_type_code
                   ,flv.meaning    AS container_type_name
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
             AND flv.language      = USERENV( 'LANG' )
            )                         flv1  -- 参照表（容器）
           ,(SELECT flv.lookup_code AS calc_type
                   ,flv.meaning     AS line_name
                   ,flv.attribute2  AS calc_type_sort
                   ,flv.attribute3  AS disp
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
             AND flv.language      = USERENV( 'LANG' )
            )                         flv2  -- 参照表（販手計算条件）
      WHERE  xbbs.snapshot_create_ym                = gv_process_ym
      AND    xbbs.snapshot_timing                   = iv_proc_div
      AND    xbbs.supplier_code                     = i_no_dif_tab(i).supplier_code
      AND    xbbs.cust_code                         = i_no_dif_tab(i).cust_code
      AND    xbbs.resv_flag                         IS NULL
      AND    xbbs.balance_cancel_date               IS NULL
      AND    xbbs.bm_paymet_kbn                     IN ('1','2')
      AND    xcbs.base_code                         = xbbs.base_code
      AND    xcbs.delivery_cust_code                = xbbs.cust_code
      AND    xcbs.supplier_code                     = xbbs.supplier_code
      AND    xcbs.closing_date                      = xbbs.closing_date
      AND    xcbs.expect_payment_date               = xbbs.expect_payment_date
      AND    xcbs.container_type_code               = flv1.container_type_code(+)
      AND    xcbs.calc_type                         = flv2.calc_type
      GROUP BY
             xbbs.snapshot_create_ym
            ,xbbs.snapshot_timing
            ,xbbs.supplier_code
            ,xcbs.delivery_cust_code
            ,SUBSTR(xbbs.cust_name,1,50)
            ,xcbs.calc_type
            ,flv2.calc_type_sort
            ,flv1.container_type_code
            ,flv1.container_type_name
            ,xcbs.selling_price
            ,xcbs.rebate_rate
            ,xcbs.rebate_amt
            ,xbbs.tax_code
            ,xbbs.bm_tax_kbn
            ,flv2.disp
      ;
--
      -- ===============================================
      -- カスタム明細情報登録(小計行)
      -- ===============================================
      INSERT INTO xxcok_info_rev_custom(
         snapshot_create_ym          -- スナップショット作成年月
        ,snapshot_timing             -- スナップショットタイミング 
        ,rev                         -- REV
        ,check_result                -- 妥当性チェック結果
        ,vendor_code                 -- 送付先コード
        ,cust_code                   -- 顧客コード
        ,inst_dest                   -- 設置場所
        ,calc_sort                   -- 計算条件ソート順
        ,sell_bottle                 -- 売価／容器
        ,sales_qty                   -- 販売本数
        ,sales_tax_amt               -- 販売金額（税込）
        ,sales_amt                   -- 販売金額（税抜）
        ,sales_fee                   -- 販売手数料（税抜）
        ,tax_amt                     -- 消費税
        ,sales_tax_fee               -- 販売手数料（税込）
        ,tax_div                     -- 税区分
        ,target_div                  -- 対象区分
        ,created_by                  -- 作成者
        ,creation_date               -- 作成日
        ,last_updated_by             -- 最終更新者
        ,last_update_date            -- 最終更新日
        ,last_update_login           -- 最終更新ログイン
        ,request_id                  -- 要求ID
        ,program_application_id      -- コンカレント・プログラム・アプリケーションID
        ,program_id                  -- コンカレント・プログラムID
        ,program_update_date         -- プログラム更新日
      )
      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
             ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
             ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
             ,'0'                             AS  check_result            -- 妥当性チェック結果
             ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
             ,xirc.cust_code                  AS  cust_code               -- 顧客コード
             ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
             ,2.5                             AS  calc_sort               -- 計算条件ソート順
             ,'小計'                          AS  sell_bottle             -- 売価／容器
             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
             ,xirc.tax_div                    AS  tax_div                 -- 税区分
             ,xirc.target_div                 AS  target_div              -- 対象区分
             ,cn_created_by                   AS  created_by              -- 作成者
             ,SYSDATE                         AS  creation_date           -- 作成日
             ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
             ,SYSDATE                         AS  last_update_date        -- 最終更新日
             ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
             ,cn_request_id                   AS  request_id              -- 要求ID
             ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
             ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
             ,SYSDATE                         AS  program_update_date     -- プログラム更新日
      FROM    xxcok_info_rev_custom  xirc
      WHERE   xirc.snapshot_create_ym         = gv_process_ym
      AND     xirc.snapshot_timing            = iv_proc_div
      AND     xirc.rev                        = '3' -- 新黒（FB）
      AND     xirc.calc_type                  IN  ('10','20')
      AND     xirc.vendor_code                = i_no_dif_tab(i).supplier_code
      AND     xirc.cust_code                  = i_no_dif_tab(i).cust_code
      AND     xirc.request_id = cn_request_id
      GROUP BY
              xirc.snapshot_create_ym
             ,xirc.snapshot_timing
             ,xirc.vendor_code
             ,xirc.cust_code
             ,xirc.inst_dest
             ,xirc.tax_div
             ,xirc.target_div
      ;
--
      -- ===============================================
      -- カスタム明細情報登録（一律条件明細行）
      -- ===============================================
      INSERT INTO xxcok_info_rev_custom(
         snapshot_create_ym          -- スナップショット作成年月
        ,snapshot_timing             -- スナップショットタイミング 
        ,rev                         -- REV
        ,check_result                -- 妥当性チェック結果
        ,vendor_code                 -- 送付先コード
        ,cust_code                   -- 顧客コード
        ,inst_dest                   -- 設置場所
        ,calc_type                   -- 計算条件
        ,calc_sort                   -- 計算条件ソート順
        ,sell_bottle                 -- 売価／容器
        ,sales_qty                   -- 販売本数
        ,sales_tax_amt               -- 販売金額（税込）
        ,sales_amt                   -- 販売金額（税抜）
        ,contract                    -- ご契約内容
        ,sales_fee                   -- 販売手数料（税抜）
        ,tax_amt                     -- 消費税
        ,sales_tax_fee               -- 販売手数料（税込）
        ,bottle_code                 -- 容器区分コード
        ,salling_price               -- 売価金額
        ,rebate_rate                 -- 割戻率
        ,rebate_amt                  -- 割戻額
        ,tax_code                    -- 税コード
        ,tax_div                     -- 税区分
        ,target_div                  -- 対象区分
        ,created_by                  -- 作成者
        ,creation_date               -- 作成日
        ,last_updated_by             -- 最終更新者
        ,last_update_date            -- 最終更新日
        ,last_update_login           -- 最終更新ログイン
        ,request_id                  -- 要求ID
        ,program_application_id      -- コンカレント・プログラム・アプリケーションID
        ,program_id                  -- コンカレント・プログラムID
        ,program_update_date         -- プログラム更新日
      )
      SELECT  /*+ 
                  LEADING(xbbs_1 xseh xsel flv)
                  USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                  */
              xbbs_1.snapshot_create_ym            AS snapshot_create_ym     -- スナップショット作成年月
             ,xbbs_1.snapshot_timing               AS snapshot_timing        -- スナップショットタイミング
             ,'3'                                  AS rev                    -- REV（3:新黒（FB）)
             ,'0'                                  AS check_result           -- 妥当性チェック結果
             ,xbbs_1.supplier_code                 AS vendor_code            -- 送付先コード
             ,xseh.ship_to_customer_code           AS cust_code              -- 顧客コード
             ,SUBSTR( xbbs_1.cust_name, 1, 50)     AS inst_dest              -- 設置場所
             ,NULL                                 AS calc_type              -- 計算条件
             ,'2.7'                                AS calc_sort              -- 計算条件ソート順
             ,xsel.dlv_unit_price                  AS sell_bottle            -- 売価／容器
             ,SUM( xsel.dlv_qty)                   AS sales_qty              -- 販売本数
             ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                   AS sales_tax_amt          -- 販売金額（税込）
             ,SUM( xsel.pure_amount )              AS sales_amt              -- 販売金額（税抜）
             ,NULL                                 AS contract               -- ご契約内容
             ,NULL                                 AS sales_fee              -- 販売手数料（税抜）
             ,NULL                                 AS tax_amt                -- 消費税
             ,NULL                                 AS sales_tax_fee          -- 販売手数料（税込）
             ,NULL                                 AS bottle_code            -- 容器区分コード
             ,NULL                                 AS salling_price          -- 売価金額
             ,NULL                                 AS rebate_rate            -- 割戻率
             ,NULL                                 AS rebate_amt             -- 割戻額
             ,NULL                                 AS tax_code               -- 税コード
             ,xbbs_1.tax_div                       AS tax_div                -- 税区分
             ,SUBSTR( xbbs_1.supplier_code, -1, 1) AS target_div             -- 対象区分
             ,cn_created_by                        AS created_by             -- 作成者
             ,SYSDATE                              AS creation_date          -- 作成日
             ,cn_last_updated_by                   AS last_updated_by        -- 最終更新者
             ,SYSDATE                              AS last_update_date       -- 最終更新日
             ,cn_last_update_login                 AS last_update_login      -- 最終更新ログイン
             ,cn_request_id                        AS request_id             -- 要求id
             ,cn_program_application_id            AS program_application_id -- コンカレント・プログラム・アプリケーションid
             ,cn_program_id                        AS program_id             -- コンカレント・プログラムid
             ,SYSDATE                              AS program_update_date    -- プログラム更新日
      FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
             ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
             ,fnd_lookup_values         flv   -- 参照表（売上区分）
             ,(
               SELECT  /*+ LEADING(xbbs xcbs) use_nl(xcbs) */
                       xbbs.supplier_code         AS supplier_code
                      ,xbbs.cust_code             AS cust_code
                      ,xbbs.closing_date          AS closing_date
                      ,xbbs.snapshot_create_ym    AS snapshot_create_ym
                      ,xbbs.snapshot_timing       AS snapshot_timing
                      ,xbbs.cust_name             AS cust_name
                      ,CASE WHEN xbbs.bm_tax_kbn = '1'
                            THEN '2'
                            WHEN xbbs.bm_tax_kbn IN ('2','3')
                            THEN '1'
                       END                        AS tax_div
               FROM    xxcok_bm_balance_snap     xbbs   -- 販手残高テーブルスナップショット
                      ,xxcok_cond_bm_support     xcbs   -- 条件別販手販協テーブル
               WHERE   xbbs.snapshot_create_ym           =  gv_process_ym
               AND     xbbs.snapshot_timing              =  iv_proc_div
               AND     xbbs.resv_flag                    IS NULL
               AND     xbbs.balance_cancel_date          IS NULL
               AND     xbbs.bm_paymet_kbn                IN ('1','2')
               AND EXISTS (
                       SELECT 1
                       FROM   xxcok_info_rev_custom    xirc
                       WHERE  xirc.snapshot_create_ym    =  xbbs.snapshot_create_ym
                       AND    xirc.snapshot_timing       =  xbbs.snapshot_timing
                       AND    xirc.rev                   =  '3' -- 新黒（FB）
                       AND    xirc.vendor_code           =  xbbs.supplier_code
                       AND    xirc.cust_code             =  xbbs.cust_code
                       AND    xirc.vendor_code           =  i_no_dif_tab(i).supplier_code
                       AND    xirc.cust_code             =  i_no_dif_tab(i).cust_code
                       AND    xirc.request_id            =  cn_request_id )
               AND     xcbs.base_code                    =  xbbs.base_code
               AND     xcbs.delivery_cust_code           =  xbbs.cust_code
               AND     xcbs.supplier_code                =  xbbs.supplier_code
               AND     xcbs.closing_date                 =  xbbs.closing_date
               AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
               AND     xcbs.calc_type                    =  '30'                -- 30:一律条件
               GROUP BY xbbs.supplier_code
                       ,xbbs.cust_code
                       ,xbbs.closing_date
                       ,xbbs.snapshot_create_ym
                       ,xbbs.snapshot_timing
                       ,xbbs.cust_name
                       ,xbbs.bm_tax_kbn
              ) xbbs_1                        -- 販手情報
      WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
      AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
      AND     xseh.ship_to_customer_code  =  xbbs_1.cust_code
      AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbbs_1.closing_date, -1)) + 1 --月初日
      AND     xseh.delivery_date          <= xbbs_1.closing_date                               --月末日
      AND     flv.lookup_code             =  xsel.sales_class
      AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
      AND     flv.language                =  USERENV( 'LANG' )
      AND     flv.enabled_flag            =  'Y'
      AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                  AND NVL( flv.end_date_active  , gd_process_date )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- 非在庫品目
                       WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = USERENV( 'LANG' )
                         AND flv.enabled_flag        = 'Y'
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
          )
      GROUP BY
              xseh.ship_to_customer_code
             ,SUBSTR( xbbs_1.cust_name, 1, 50)
             ,xbbs_1.supplier_code
             ,SUBSTR( xbbs_1.supplier_code, -1, 1)
             ,xsel.dlv_unit_price
             ,xbbs_1.snapshot_create_ym
             ,xbbs_1.snapshot_timing
             ,xbbs_1.tax_div
      ;
--
      -- ===============================================
      -- カスタム明細情報登録(一律条件小計行)
      -- ===============================================
      INSERT INTO xxcok_info_rev_custom(
         snapshot_create_ym          -- スナップショット作成年月
        ,snapshot_timing             -- スナップショットタイミング 
        ,rev                         -- REV
        ,check_result                -- 妥当性チェック結果
        ,vendor_code                 -- 送付先コード
        ,cust_code                   -- 顧客コード
        ,inst_dest                   -- 設置場所
        ,calc_sort                   -- 計算条件ソート順
        ,sell_bottle                 -- 売価／容器
        ,sales_qty                   -- 販売本数
        ,sales_tax_amt               -- 販売金額（税込）
        ,sales_amt                   -- 販売金額（税抜）
        ,sales_fee                   -- 販売手数料（税抜）
        ,tax_amt                     -- 消費税
        ,sales_tax_fee               -- 販売手数料（税込）
        ,tax_div                     -- 税区分
        ,target_div                  -- 対象区分
        ,created_by                  -- 作成者
        ,creation_date               -- 作成日
        ,last_updated_by             -- 最終更新者
        ,last_update_date            -- 最終更新日
        ,last_update_login           -- 最終更新ログイン
        ,request_id                  -- 要求ID
        ,program_application_id      -- コンカレント・プログラム・アプリケーションID
        ,program_id                  -- コンカレント・プログラムID
        ,program_update_date         -- プログラム更新日
      )
      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
             ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
             ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
             ,'0'                             AS  check_result            -- 妥当性チェック結果
             ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
             ,xirc.cust_code                  AS  cust_code               -- 顧客コード
             ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
             ,3.5                             AS  calc_sort               -- 計算条件ソート順
             ,'小計'                          AS  sell_bottle             -- 売価／容器
             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
             ,xirc.tax_div                    AS  tax_div                 -- 税区分
             ,xirc.target_div                 AS  target_div              -- 対象区分
             ,cn_created_by                   AS  created_by              -- 作成者
             ,SYSDATE                         AS  creation_date           -- 作成日
             ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
             ,SYSDATE                         AS  last_update_date        -- 最終更新日
             ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
             ,cn_request_id                   AS  request_id              -- 要求ID
             ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
             ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
             ,SYSDATE                         AS  program_update_date     -- プログラム更新日
      FROM    xxcok_info_rev_custom  xirc
      WHERE   xirc.snapshot_create_ym = gv_process_ym
      AND     xirc.snapshot_timing    = iv_proc_div
      AND     xirc.rev                = '3' -- 新黒（FB）
      AND     xirc.calc_type  = '30'
      AND     xirc.vendor_code        = i_no_dif_tab(i).supplier_code
      AND     xirc.cust_code          = i_no_dif_tab(i).cust_code
      AND     xirc.request_id         = cn_request_id
      GROUP BY
              xirc.snapshot_create_ym
             ,xirc.snapshot_timing
             ,xirc.vendor_code
             ,xirc.cust_code
             ,xirc.inst_dest
             ,xirc.tax_div
             ,xirc.target_div
      ;
--
      -- ===============================================
      -- 定額のみデータ取得
      -- ===============================================
      <<fixed_amt_loop>>
      FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
        -- ===============================================
        -- 定額のみデータ更新
        -- ===============================================
        UPDATE xxcok_info_rev_custom xirc
        SET    ( sales_qty
                ,sales_amt
               ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
                           ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                    FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                           ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                           ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                           ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
                           ,fnd_lookup_values         flv   -- 参照表（売上区分）
                    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                    AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                    AND     flv.lookup_code             =  xsel.sales_class
                    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                    AND     flv.language                =  USERENV( 'LANG' )
                    AND     flv.enabled_flag            =  'Y'
                    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                  AND NVL( flv.end_date_active  , gd_process_date )
                    AND NOT EXISTS ( SELECT '1'
                                     FROM  fnd_lookup_values flv -- 非在庫品目
                                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = USERENV( 'LANG' )
                                       AND flv.enabled_flag        = 'Y'
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                        )
                    AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                    AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --月初日
                    AND     xseh.delivery_date                <= xbbs.closing_date --月末日
                    AND     xcbs.base_code                    =  xbbs.base_code
                    AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                    AND     xcbs.supplier_code                =  xbbs.supplier_code
                    AND     xcbs.closing_date                 =  xbbs.closing_date
                    AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                    AND     xcbs.calc_type                    =  '40' -- 40:定額
                    AND     xbbs.supplier_code                = l_fixed_amt_rec.vendor_code
                    AND     xbbs.cust_code                    = l_fixed_amt_rec.cust_code
                    AND     xbbs.snapshot_create_ym           = gv_process_ym
                    AND     xbbs.snapshot_timing              = iv_proc_div
                    AND     xbbs.resv_flag                    IS NULL
                    AND     xbbs.balance_cancel_date          IS NULL
                    AND     xbbs.bm_paymet_kbn                IN ('1','2')
                    AND EXISTS ( SELECT 1
                                 FROM  xxcok_info_rev_custom xirc1
                                 WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                                 AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                                 AND   xirc1.rev                = '3' -- 新黒（FB）
                                 AND   xirc1.vendor_code        = xbbs.supplier_code
                                 AND   xirc1.cust_code          = xbbs.cust_code
                                 AND   xirc1.vendor_code        = i_no_dif_tab(i).supplier_code
                                 AND   xirc1.cust_code          = i_no_dif_tab(i).cust_code
                                 AND   xirc1.request_id         = cn_request_id )
                    GROUP BY
                            xbbs.cust_code
                           ,xbbs.supplier_code
                   )
        WHERE xirc.rowid       = l_fixed_amt_rec.row_id
        ;
--
      END LOOP fixed_amt_loop;
--
      -- ===============================================
      -- 電気代のみデータ取得
      -- ===============================================
      <<elctric_loop>>
      FOR l_electric_rec IN l_electric_cur LOOP
        -- ===============================================
        -- 電気代データ更新
        -- ===============================================
        UPDATE xxcok_info_rev_custom xirc
        SET    ( sales_qty
                ,sales_tax_amt
                ,sales_amt
               ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
                           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- 販売金額（税込）
                           ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                    FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                           ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                           ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                           ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
                           ,fnd_lookup_values         flv   -- 参照表（売上区分）
                    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                    AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                    AND     flv.lookup_code             =  xsel.sales_class
                    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                    AND     flv.language                =  USERENV( 'LANG' )
                    AND     flv.enabled_flag            =  'Y'
                    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                  AND NVL( flv.end_date_active  , gd_process_date )
                    AND NOT EXISTS ( SELECT '1'
                                     FROM  fnd_lookup_values flv -- 非在庫品目
                                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = USERENV( 'LANG' )
                                       AND flv.enabled_flag        = 'Y'
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                        )
                    AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                    AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --月初日
                    AND     xseh.delivery_date                <= xbbs.closing_date                     --月末日
                    AND     xcbs.base_code                    =  xbbs.base_code
                    AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                    AND     xcbs.supplier_code                =  xbbs.supplier_code
                    AND     xcbs.closing_date                 =  xbbs.closing_date
                    AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                    AND     xcbs.calc_type                    =  '50'                 -- 50:電気代
                    AND     xbbs.supplier_code                = l_electric_rec.vendor_code
                    AND     xbbs.cust_code                    = l_electric_rec.cust_code
                    AND     xbbs.snapshot_create_ym           = gv_process_ym
                    AND     xbbs.snapshot_timing              = iv_proc_div
                    AND     xbbs.resv_flag                    IS NULL
                    AND     xbbs.balance_cancel_date          IS NULL
                    AND     xbbs.bm_paymet_kbn                IN ('1','2')
                    AND EXISTS ( SELECT 1
                                 FROM  xxcok_info_rev_custom xirc1
                                 WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                                 AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                                 AND   xirc1.rev                = '3' -- 新黒（FB）
                                 AND   xirc1.vendor_code        = xbbs.supplier_code
                                 AND   xirc1.cust_code          = xbbs.cust_code
                                 AND   xirc1.vendor_code        = i_no_dif_tab(i).supplier_code
                                 AND   xirc1.cust_code          = i_no_dif_tab(i).cust_code
                                 AND   xirc1.request_id         = cn_request_id )
                    GROUP BY
                            xbbs.cust_code
                           ,xbbs.supplier_code
                )
        WHERE xirc.rowid       = l_electric_rec.row_id
        ;
      END LOOP elctric_loop;
--
      -- ===============================================
      -- カスタム明細情報登録(合計行)
      -- ===============================================
      INSERT INTO xxcok_info_rev_custom(
         snapshot_create_ym          -- スナップショット作成年月
        ,snapshot_timing             -- スナップショットタイミング
        ,rev                         -- REV
        ,check_result                -- 妥当性チェック結果
        ,vendor_code                 -- 送付先コード
        ,cust_code                   -- 顧客コード
        ,inst_dest                   -- 設置場所
        ,calc_sort                   -- 計算条件ソート順
        ,sell_bottle                 -- 売価／容器
        ,sales_qty                   -- 販売本数
        ,sales_tax_amt               -- 販売金額（税込）
        ,sales_amt                   -- 販売金額（税抜）
        ,sales_fee                   -- 販売手数料（税抜）
        ,tax_amt                     -- 消費税
        ,sales_tax_fee               -- 販売手数料（税込）
        ,tax_div                     -- 税区分
        ,target_div                  -- 対象区分
        ,created_by                  -- 作成者
        ,creation_date               -- 作成日
        ,last_updated_by             -- 最終更新者
        ,last_update_date            -- 最終更新日
        ,last_update_login           -- 最終更新ログイン
        ,request_id                  -- 要求ID
        ,program_application_id      -- コンカレント・プログラム・アプリケーションID
        ,program_id                  -- コンカレント・プログラムID
        ,program_update_date         -- プログラム更新日
      )
      SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
             ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
             ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
             ,'0'                             AS  check_result            -- 妥当性チェック結果
             ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
             ,xirc.cust_code                  AS  cust_code               -- 顧客コード
             ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
             ,6                               AS  calc_sort               -- 計算条件ソート順
             ,'合計'                          AS  sell_bottle             -- 売価／容器
             ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
             ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
             ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
             ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
             ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
             ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
             ,xirc.tax_div                    AS  tax_div                 -- 税区分
             ,xirc.target_div                 AS  target_div              -- 対象区分
             ,cn_created_by                   AS  created_by              -- 作成者
             ,SYSDATE                         AS  creation_date           -- 作成日
             ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
             ,SYSDATE                         AS  last_update_date        -- 最終更新日
             ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
             ,cn_request_id                   AS  request_id              -- 要求ID
             ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
             ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
             ,SYSDATE                         AS  program_update_date     -- プログラム更新日
      FROM    xxcok_info_rev_custom  xirc
      WHERE   xirc.snapshot_create_ym = gv_process_ym
      AND     xirc.snapshot_timing    = iv_proc_div
      AND     xirc.rev                = '3' -- 新黒（FB）
      AND     xirc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
      AND     xirc.vendor_code        = i_no_dif_tab(i).supplier_code
      AND     xirc.cust_code          = i_no_dif_tab(i).cust_code
      AND     xirc.request_id = cn_request_id
      GROUP BY
              xirc.vendor_code
             ,xirc.cust_code
             ,xirc.inst_dest
             ,xirc.tax_div
             ,xirc.target_div
             ,xirc.snapshot_create_ym
             ,xirc.snapshot_timing
      ;
    END LOOP;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_credit_custom_mon;
--
  /**********************************************************************************
   * Procedure Name   : ins_credit_custom
   * Description      : 新黒カスタム明細情報作成２(A-8)
   ***********************************************************************************/
  PROCEDURE ins_credit_custom(
    iv_proc_div   IN  VARCHAR2
   ,i_no_dif_tab  IN  g_no_dif_ttype
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_credit_custom';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 定額のみデータ取得
    CURSOR l_fixed_amt_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- 新黒（FB）
      AND    xirc.calc_type          = '40' -- 40:定額
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code        = xirc.vendor_code
                      AND    xirc2.cust_code          = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev                = xirc.rev
                      AND    xirc2.request_id         = xirc.request_id
                      AND    xirc2.calc_type          IN ('10','20','30')
                     )
    ;
--
    l_fixed_amt_rec    l_fixed_amt_cur%ROWTYPE;
--
    -- 電気代のみデータ取得
    CURSOR l_electric_cur
    IS
      SELECT xirc.rowid       AS  row_id
            ,xirc.vendor_code AS  vendor_code
            ,xirc.cust_code   AS  cust_code
      FROM   xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = iv_proc_div
      AND    xirc.rev                = '3'  -- 新黒（FB）
      AND    xirc.calc_type  = '50'  -- 50:電気代
      AND    xirc.request_id         = cn_request_id
      AND NOT EXISTS (SELECT '1'
                      FROM   xxcok_info_rev_custom xirc2
                      WHERE  xirc2.vendor_code = xirc.vendor_code
                      AND    xirc2.cust_code   = xirc.cust_code
                      AND    xirc2.snapshot_create_ym = xirc.snapshot_create_ym
                      AND    xirc2.snapshot_timing    = xirc.snapshot_timing
                      AND    xirc2.rev         = xirc.rev
                      AND    xirc2.request_id  = xirc.request_id
                      AND    xirc2.calc_type   IN ('10','20','30','40')
                     )
    ;
--
    l_electric_rec    l_electric_cur%ROWTYPE;
--
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- カスタム明細情報登録(小計行)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- スナップショット作成年月
      ,snapshot_timing             -- スナップショットタイミング 
      ,rev                         -- REV
      ,check_result                -- 妥当性チェック結果
      ,vendor_code                 -- 送付先コード
      ,cust_code                   -- 顧客コード
      ,inst_dest                   -- 設置場所
      ,calc_sort                   -- 計算条件ソート順
      ,sell_bottle                 -- 売価／容器
      ,sales_qty                   -- 販売本数
      ,sales_tax_amt               -- 販売金額（税込）
      ,sales_amt                   -- 販売金額（税抜）
      ,sales_fee                   -- 販売手数料（税抜）
      ,tax_amt                     -- 消費税
      ,sales_tax_fee               -- 販売手数料（税込）
      ,tax_div                     -- 税区分
      ,target_div                  -- 対象区分
      ,created_by                  -- 作成者
      ,creation_date               -- 作成日
      ,last_updated_by             -- 最終更新者
      ,last_update_date            -- 最終更新日
      ,last_update_login           -- 最終更新ログイン
      ,request_id                  -- 要求ID
      ,program_application_id      -- コンカレント・プログラム・アプリケーションID
      ,program_id                  -- コンカレント・プログラムID
      ,program_update_date         -- プログラム更新日
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
           ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
           ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
           ,'0'                             AS  check_result            -- 妥当性チェック結果
           ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xirc.cust_code                  AS  cust_code               -- 顧客コード
           ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
           ,2.5                             AS  calc_sort               -- 計算条件ソート順
           ,'小計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xirc.tax_div                    AS  tax_div                 -- 税区分
           ,xirc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym         = gv_process_ym
    AND     xirc.snapshot_timing            = iv_proc_div
    AND     xirc.rev                        = '3' -- 新黒（FB）
    AND     xirc.calc_type                  IN  ('10','20')
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.snapshot_create_ym
           ,xirc.snapshot_timing
           ,xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
    ;
--
    -- ===============================================
    -- カスタム明細情報登録（一律条件明細行）
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- スナップショット作成年月
      ,snapshot_timing             -- スナップショットタイミング 
      ,rev                         -- REV
      ,check_result                -- 妥当性チェック結果
      ,vendor_code                 -- 送付先コード
      ,cust_code                   -- 顧客コード
      ,inst_dest                   -- 設置場所
      ,calc_type                   -- 計算条件
      ,calc_sort                   -- 計算条件ソート順
      ,sell_bottle                 -- 売価／容器
      ,sales_qty                   -- 販売本数
      ,sales_tax_amt               -- 販売金額（税込）
      ,sales_amt                   -- 販売金額（税抜）
      ,contract                    -- ご契約内容
      ,sales_fee                   -- 販売手数料（税抜）
      ,tax_amt                     -- 消費税
      ,sales_tax_fee               -- 販売手数料（税込）
      ,bottle_code                 -- 容器区分コード
      ,salling_price               -- 売価金額
      ,rebate_rate                 -- 割戻率
      ,rebate_amt                  -- 割戻額
      ,tax_code                    -- 税コード
      ,tax_div                     -- 税区分
      ,target_div                  -- 対象区分
      ,created_by                  -- 作成者
      ,creation_date               -- 作成日
      ,last_updated_by             -- 最終更新者
      ,last_update_date            -- 最終更新日
      ,last_update_login           -- 最終更新ログイン
      ,request_id                  -- 要求ID
      ,program_application_id      -- コンカレント・プログラム・アプリケーションID
      ,program_id                  -- コンカレント・プログラムID
      ,program_update_date         -- プログラム更新日
    )
    SELECT  /*+ 
                LEADING(xbbs_1 xseh xsel flv)
                USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                */
            xbbs_1.snapshot_create_ym            AS snapshot_create_ym     -- スナップショット作成年月
           ,xbbs_1.snapshot_timing               AS snapshot_timing        -- スナップショットタイミング
           ,'3'                                  AS rev                    -- REV（3:新黒（FB）)
           ,'0'                                  AS check_result           -- 妥当性チェック結果
           ,xbbs_1.supplier_code                 AS vendor_code            -- 送付先コード
           ,xseh.ship_to_customer_code           AS cust_code              -- 顧客コード
           ,SUBSTR( xbbs_1.cust_name, 1, 50)     AS inst_dest              -- 設置場所
           ,NULL                                 AS calc_type              -- 計算条件
           ,'2.7'                                AS calc_sort              -- 計算条件ソート順
           ,xsel.dlv_unit_price                  AS sell_bottle            -- 売価／容器
           ,SUM( xsel.dlv_qty)                   AS sales_qty              -- 販売本数
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                 AS sales_tax_amt          -- 販売金額（税込）
           ,SUM( xsel.pure_amount )              AS sales_amt              -- 販売金額（税抜）
           ,NULL                                 AS contract               -- ご契約内容
           ,NULL                                 AS sales_fee              -- 販売手数料（税抜）
           ,NULL                                 AS tax_amt                -- 消費税
           ,NULL                                 AS sales_tax_fee          -- 販売手数料（税込）
           ,NULL                                 AS bottle_code            -- 容器区分コード
           ,NULL                                 AS salling_price          -- 売価金額
           ,NULL                                 AS rebate_rate            -- 割戻率
           ,NULL                                 AS rebate_amt             -- 割戻額
           ,NULL                                 AS tax_code               -- 税コード
           ,xbbs_1.tax_div                       AS tax_div                -- 税区分
           ,SUBSTR( xbbs_1.supplier_code, -1, 1) AS target_div             -- 対象区分
           ,cn_created_by                        AS created_by             -- 作成者
           ,SYSDATE                              AS creation_date          -- 作成日
           ,cn_last_updated_by                   AS last_updated_by        -- 最終更新者
           ,SYSDATE                              AS last_update_date       -- 最終更新日
           ,cn_last_update_login                 AS last_update_login      -- 最終更新ログイン
           ,cn_request_id                        AS request_id             -- 要求id
           ,cn_program_application_id            AS program_application_id -- コンカレント・プログラム・アプリケーションid
           ,cn_program_id                        AS program_id             -- コンカレント・プログラムid
           ,SYSDATE                              AS program_update_date    -- プログラム更新日
    FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
           ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
           ,fnd_lookup_values         flv   -- 参照表（売上区分）
           ,(
             SELECT  /*+ LEADING(xbbs xcbs) use_nl(xcbs) */
                     xbbs.supplier_code         AS supplier_code
                    ,xbbs.cust_code             AS cust_code
                    ,xbbs.closing_date          AS closing_date
                    ,xbbs.snapshot_create_ym    AS snapshot_create_ym
                    ,xbbs.snapshot_timing       AS snapshot_timing
                    ,xbbs.cust_name             AS cust_name
                    ,CASE WHEN xbbs.bm_tax_kbn = '1'
                          THEN '2'
                          WHEN xbbs.bm_tax_kbn IN ('2','3')
                          THEN '1'
                     END                        AS tax_div
             FROM    xxcok_bm_balance_snap     xbbs   -- 販手残高テーブルスナップショット
                    ,xxcok_cond_bm_support     xcbs   -- 条件別販手販協テーブル
             WHERE   xbbs.snapshot_create_ym           =  gv_process_ym
             AND     xbbs.snapshot_timing              =  iv_proc_div
             AND EXISTS (
                     SELECT 1
                     FROM   xxcok_info_rev_custom    xirc
                     WHERE  xirc.snapshot_create_ym    =  xbbs.snapshot_create_ym
                     AND    xirc.snapshot_timing       =  xbbs.snapshot_timing
                     AND    xirc.rev                   =  '3' -- 新黒（FB）
                     AND    xirc.vendor_code           =  xbbs.supplier_code
                     AND    xirc.cust_code             =  xbbs.cust_code
                     AND    xirc.request_id            =  cn_request_id )
             AND     xcbs.base_code                    =  xbbs.base_code
             AND     xcbs.delivery_cust_code           =  xbbs.cust_code
             AND     xcbs.supplier_code                =  xbbs.supplier_code
             AND     xcbs.closing_date                 =  xbbs.closing_date
             AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
             AND     xcbs.calc_type                    =  '30'                -- 30:一律条件
             GROUP BY xbbs.supplier_code
                     ,xbbs.cust_code
                     ,xbbs.closing_date
                     ,xbbs.snapshot_create_ym
                     ,xbbs.snapshot_timing
                     ,xbbs.cust_name
                     ,xbbs.bm_tax_kbn
            ) xbbs_1                        -- 販手情報
    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
    AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
    AND     xseh.ship_to_customer_code  =  xbbs_1.cust_code
    AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbbs_1.closing_date, -1)) + 1 --月初日
    AND     xseh.delivery_date          <= xbbs_1.closing_date                               --月末日
    AND     flv.lookup_code             =  xsel.sales_class
    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
    AND     flv.language                =  USERENV( 'LANG' )
    AND     flv.enabled_flag            =  'Y'
    AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                AND NVL( flv.end_date_active  , gd_process_date )
    AND NOT EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values flv -- 非在庫品目
                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                       AND flv.lookup_code         = xsel.item_code
                       AND flv.language            = USERENV( 'LANG' )
                       AND flv.enabled_flag        = 'Y'
                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND NVL( flv.end_date_active  , gd_process_date )
        )
    GROUP BY
            xseh.ship_to_customer_code
           ,SUBSTR( xbbs_1.cust_name, 1, 50)
           ,xbbs_1.supplier_code
           ,SUBSTR( xbbs_1.supplier_code, -1, 1)
           ,xsel.dlv_unit_price
           ,xbbs_1.snapshot_create_ym
           ,xbbs_1.snapshot_timing
           ,xbbs_1.tax_div
    ;
--
    -- ===============================================
    -- カスタム明細情報登録(一律条件小計行)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- スナップショット作成年月
      ,snapshot_timing             -- スナップショットタイミング 
      ,rev                         -- REV
      ,check_result                -- 妥当性チェック結果
      ,vendor_code                 -- 送付先コード
      ,cust_code                   -- 顧客コード
      ,inst_dest                   -- 設置場所
      ,calc_sort                   -- 計算条件ソート順
      ,sell_bottle                 -- 売価／容器
      ,sales_qty                   -- 販売本数
      ,sales_tax_amt               -- 販売金額（税込）
      ,sales_amt                   -- 販売金額（税抜）
      ,sales_fee                   -- 販売手数料（税抜）
      ,tax_amt                     -- 消費税
      ,sales_tax_fee               -- 販売手数料（税込）
      ,tax_div                     -- 税区分
      ,target_div                  -- 対象区分
      ,created_by                  -- 作成者
      ,creation_date               -- 作成日
      ,last_updated_by             -- 最終更新者
      ,last_update_date            -- 最終更新日
      ,last_update_login           -- 最終更新ログイン
      ,request_id                  -- 要求ID
      ,program_application_id      -- コンカレント・プログラム・アプリケーションID
      ,program_id                  -- コンカレント・プログラムID
      ,program_update_date         -- プログラム更新日
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
           ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
           ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
           ,'0'                             AS  check_result            -- 妥当性チェック結果
           ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xirc.cust_code                  AS  cust_code               -- 顧客コード
           ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
           ,3.5                             AS  calc_sort               -- 計算条件ソート順
           ,'小計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xirc.tax_div                    AS  tax_div                 -- 税区分
           ,xirc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym = gv_process_ym
    AND     xirc.snapshot_timing    = iv_proc_div
    AND     xirc.rev                = '3' -- 新黒（FB）
    AND     xirc.calc_type  = '30'
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.snapshot_create_ym
           ,xirc.snapshot_timing
           ,xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
    ;
--
    -- ===============================================
    -- 定額のみデータ取得
    -- ===============================================
    <<fixed_amt_loop>>
    FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
      -- ===============================================
      -- 定額のみデータ更新
      -- ===============================================
      UPDATE xxcok_info_rev_custom xirc
      SET    ( sales_qty
              ,sales_amt
             ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                  FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                         ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                         ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                         ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
                         ,fnd_lookup_values         flv   -- 参照表（売上区分）
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT '1'
                                   FROM  fnd_lookup_values flv -- 非在庫品目
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --月初日
                  AND     xseh.delivery_date                <= xbbs.closing_date --月末日
                  AND     xcbs.base_code                    =  xbbs.base_code
                  AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                  AND     xcbs.supplier_code                =  xbbs.supplier_code
                  AND     xcbs.closing_date                 =  xbbs.closing_date
                  AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                  AND     xcbs.calc_type                    =  '40' -- 40:定額
                  AND     xbbs.supplier_code                = l_fixed_amt_rec.vendor_code
                  AND     xbbs.cust_code                    = l_fixed_amt_rec.cust_code
                  AND     xbbs.snapshot_create_ym           = gv_process_ym
                  AND     xbbs.snapshot_timing              = iv_proc_div
                  AND EXISTS ( SELECT 1
                               FROM  xxcok_info_rev_custom xirc1
                               WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                               AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                               AND   xirc1.rev                = '3' -- 新黒（FB）
                               AND   xirc1.vendor_code        = xbbs.supplier_code
                               AND   xirc1.cust_code          = xbbs.cust_code
                               AND   xirc1.request_id         = cn_request_id )
                  GROUP BY
                          xbbs.cust_code
                         ,xbbs.supplier_code
                 )
      WHERE xirc.rowid       = l_fixed_amt_rec.row_id
      ;
--
    END LOOP fixed_amt_loop;
--
    -- ===============================================
    -- 電気代のみデータ取得
    -- ===============================================
    <<elctric_loop>>
    FOR l_electric_rec IN l_electric_cur LOOP
      -- ===============================================
      -- 電気代データ更新
      -- ===============================================
      UPDATE xxcok_info_rev_custom xirc
      SET    ( sales_qty
              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- 販売金額（税込）
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                  FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                         ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                         ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                         ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
                         ,fnd_lookup_values         flv   -- 参照表（売上区分）
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT '1'
                                   FROM  fnd_lookup_values flv -- 非在庫品目
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbbs.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbbs.closing_date, -1)) + 1 --月初日
                  AND     xseh.delivery_date                <= xbbs.closing_date                     --月末日
                  AND     xcbs.base_code                    =  xbbs.base_code
                  AND     xcbs.delivery_cust_code           =  xbbs.cust_code
                  AND     xcbs.supplier_code                =  xbbs.supplier_code
                  AND     xcbs.closing_date                 =  xbbs.closing_date
                  AND     xcbs.expect_payment_date          =  xbbs.expect_payment_date
                  AND     xcbs.calc_type                    =  '50'                 -- 50:電気代
                  AND     xbbs.supplier_code                = l_electric_rec.vendor_code
                  AND     xbbs.cust_code                    = l_electric_rec.cust_code
                  AND     xbbs.snapshot_create_ym           = gv_process_ym
                  AND     xbbs.snapshot_timing              = iv_proc_div
                  AND EXISTS ( SELECT 1
                               FROM  xxcok_info_rev_custom xirc1
                               WHERE xirc1.snapshot_create_ym = xbbs.snapshot_create_ym
                               AND   xirc1.snapshot_timing    = xbbs.snapshot_timing
                               AND   xirc1.rev                = '3' -- 新黒（FB）
                               AND   xirc1.vendor_code        = xbbs.supplier_code
                               AND   xirc1.cust_code          = xbbs.cust_code
                               AND   xirc1.request_id         = cn_request_id )
                  GROUP BY
                          xbbs.cust_code
                         ,xbbs.supplier_code
              )
      WHERE xirc.rowid       = l_electric_rec.row_id
      ;
--
    END LOOP elctric_loop;
    -- ===============================================
    -- カスタム明細情報登録(合計行)
    -- ===============================================
    INSERT INTO xxcok_info_rev_custom(
       snapshot_create_ym          -- スナップショット作成年月
      ,snapshot_timing             -- スナップショットタイミング
      ,rev                         -- REV
      ,check_result                -- 妥当性チェック結果
      ,vendor_code                 -- 送付先コード
      ,cust_code                   -- 顧客コード
      ,inst_dest                   -- 設置場所
      ,calc_sort                   -- 計算条件ソート順
      ,sell_bottle                 -- 売価／容器
      ,sales_qty                   -- 販売本数
      ,sales_tax_amt               -- 販売金額（税込）
      ,sales_amt                   -- 販売金額（税抜）
      ,sales_fee                   -- 販売手数料（税抜）
      ,tax_amt                     -- 消費税
      ,sales_tax_fee               -- 販売手数料（税込）
      ,tax_div                     -- 税区分
      ,target_div                  -- 対象区分
      ,created_by                  -- 作成者
      ,creation_date               -- 作成日
      ,last_updated_by             -- 最終更新者
      ,last_update_date            -- 最終更新日
      ,last_update_login           -- 最終更新ログイン
      ,request_id                  -- 要求ID
      ,program_application_id      -- コンカレント・プログラム・アプリケーションID
      ,program_id                  -- コンカレント・プログラムID
      ,program_update_date         -- プログラム更新日
    )
    SELECT  xirc.snapshot_create_ym         AS  snapshot_create_ym      -- スナップショット作成年月
           ,xirc.snapshot_timing            AS  snapshot_timing         -- スナップショットタイミング
           ,'3'                             AS  rev                     -- REV（3:新黒（FB）)
           ,'0'                             AS  check_result            -- 妥当性チェック結果
           ,xirc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xirc.cust_code                  AS  cust_code               -- 顧客コード
           ,xirc.inst_dest                  AS  inst_dest               -- 設置場所
           ,6                               AS  calc_sort               -- 計算条件ソート順
           ,'合計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xirc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xirc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xirc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xirc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xirc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xirc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xirc.tax_div                    AS  tax_div                 -- 税区分
           ,xirc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym = gv_process_ym
    AND     xirc.snapshot_timing    = iv_proc_div
    AND     xirc.rev                = '3' -- 新黒（FB）
    AND     xirc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
    AND     xirc.request_id = cn_request_id
    GROUP BY
            xirc.vendor_code
           ,xirc.cust_code
           ,xirc.inst_dest
           ,xirc.tax_div
           ,xirc.target_div
           ,xirc.snapshot_create_ym
           ,xirc.snapshot_timing
    ;
--
    -- 差がある仕入先に紐づく顧客を新黒カスタム明細へ登録
    INSERT INTO xxcok_info_rev_custom (
      snapshot_create_ym          -- スナップショット作成年月
     ,snapshot_timing             -- スナップショットタイミング 
     ,rev                         -- REV
     ,check_result                -- 妥当性チェック結果
     ,row_id                      -- 元テーブルレコードID
     ,edi_interface_date          -- 連携日（EDI支払案内書）
     ,vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_type                   -- 計算条件
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,contract                    -- ご契約内容
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,bottle_code                 -- 容器区分コード
     ,salling_price               -- 売価金額
     ,rebate_rate                 -- 割戻率
     ,rebate_amt                  -- 割戻額
     ,tax_code                    -- 税コード
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT /*+ INDEX(xirc1 xxcok_info_rev_custom_n02) */
      xirc.snapshot_create_ym            AS  snapshot_create_ym      -- スナップショット作成年月
     ,iv_proc_div                        AS  snapshot_timing         -- スナップショットタイミング 
     ,'3'                                AS  rev                     -- REV
     ,'0'                                AS  check_result            -- 妥当性チェック結果
     ,NULL                               AS  row_id                  -- 元テーブルレコードID
     ,NULL                               AS  edi_interface_date      -- 連携日（EDI支払案内書）
     ,xirc.vendor_code                   AS  vendor_code             -- 送付先コード
     ,xirc.cust_code                     AS  cust_code               -- 顧客コード
     ,xirc.inst_dest                     AS  inst_dest               -- 設置場所
     ,xirc.calc_type                     AS  calc_type               -- 計算条件
     ,xirc.calc_sort                     AS  calc_sort               -- 計算条件ソート順
     ,xirc.sell_bottle                   AS  sell_bottle             -- 売価／容器
     ,xirc.sales_qty                     AS  sales_qty               -- 販売本数
     ,xirc.sales_tax_amt                 AS  sales_tax_amt           -- 販売金額（税込）
     ,xirc.sales_amt                     AS  sales_amt               -- 販売金額（税抜）
     ,xirc.contract                      AS  contract                -- ご契約内容
     ,xirc.sales_fee                     AS  sales_fee               -- 販売手数料（税抜）
     ,xirc.tax_amt                       AS  tax_amt                 -- 消費税
     ,xirc.sales_tax_fee                 AS  sales_tax_fee           -- 販売手数料（税込）
     ,xirc.bottle_code                   AS  bottle_code             -- 容器区分コード
     ,xirc.salling_price                 AS  salling_price           -- 売価金額
     ,xirc.rebate_rate                   AS  rebate_rate             -- 割戻率
     ,xirc.rebate_amt                    AS  rebate_amt              -- 割戻額
     ,xirc.tax_code                      AS  tax_code                -- 税コード
     ,xirc.tax_div                       AS  tax_div                 -- 税区分
     ,xirc.target_div                    AS  target_div              -- 対象区分
     ,cn_created_by                      AS  created_by              -- 作成者
     ,SYSDATE                            AS  creation_date           -- 作成日
     ,cn_last_updated_by                 AS  last_updated_by         -- 最終更新者
     ,SYSDATE                            AS  last_update_date        -- 最終更新日
     ,cn_last_update_login               AS  last_update_login       -- 最終更新ログイン
     ,cn_request_id                      AS  request_id              -- 要求ID
     ,cn_program_application_id          AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
     ,cn_program_id                      AS  program_id              -- コンカレント・プログラムID
     ,SYSDATE                            AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_rev_custom  xirc
    WHERE   xirc.snapshot_create_ym = gv_process_ym
    AND     xirc.snapshot_timing    = '1' -- 2営
    AND     xirc.rev                = '1' -- 元黒
    AND     xirc.vendor_code IN  (
              SELECT /*+ INDEX(xirc1 xxcok_info_rev_custom_n02) */
                     xirc1.vendor_code
              FROM   xxcok_info_rev_custom  xirc1
              WHERE  xirc1.snapshot_create_ym = gv_process_ym
              AND    xirc1.snapshot_timing    = '2' -- FB
              AND    xirc1.rev                = '3' -- 新黒
              GROUP BY 
                xirc1.snapshot_create_ym
               ,xirc1.snapshot_timing
               ,xirc1.rev
               ,xirc1.vendor_code
              )
    AND NOT EXISTS  (
              SELECT /*+ INDEX(xirc2 xxcok_info_rev_custom_n02) */
                     1
              FROM   xxcok_info_rev_custom  xirc2
              WHERE  xirc.snapshot_create_ym = xirc2.snapshot_create_ym
              AND    xirc.vendor_code = xirc2.vendor_code
              AND    xirc.cust_code = xirc2.cust_code
              AND    xirc2.snapshot_timing    = '2' -- FB
              AND    xirc2.rev                = '3' -- 新黒
              )
    ;
    -- 差はあるが、新黒を作成しない顧客を削除
    FOR i IN 1..i_no_dif_tab.COUNT LOOP
--
      DELETE FROM xxcok_info_rev_custom xirc
      WHERE  xirc.snapshot_create_ym = gv_process_ym
      AND    xirc.snapshot_timing    = '2' -- FB
      AND    xirc.rev                = '3' -- 新黒
      AND    xirc.vendor_code        = i_no_dif_tab(i).supplier_code
      AND    xirc.cust_code          = i_no_dif_tab(i).cust_code
      ;
--
    END LOOP;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_credit_custom;
--
  /**********************************************************************************
   * Procedure Name   : difference_check
   * Description      : 差分チェック(A-5)
   ***********************************************************************************/
  PROCEDURE difference_check(
    iv_proc_div      IN  VARCHAR2    --  1.処理タイミング
   ,o_no_dif_tab     OUT g_no_dif_ttype
   ,o_no_dif_sup_tab OUT g_no_dif_sup_ttype
   ,ov_errbuf        OUT VARCHAR2
   ,ov_retcode       OUT VARCHAR2
   ,ov_errmsg        OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'difference_check';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_supplier_code_fb_bk  xxcok_bm_balance_snap.supplier_code%TYPE; -- 前仕入先コード（FB）
    lv_supplier_code_rec_bk xxcok_bm_balance_snap.supplier_code%TYPE; -- 前仕入先コード（組み戻し）
    ln_count        NUMBER;
    ln_count_sup    NUMBER;
--
    -- ===============================================
    -- FB後差分チェックカーソル
    -- ===============================================
    CURSOR l_bm_balance_snap_fb_cur (
             iv_proc_div  IN VARCHAR2
    )
    IS
      SELECT  xbbs_fb.snapshot_create_ym       AS snapshot_create_ym       -- スナップショット作成年月
             ,xbbs_fb.snapshot_timing          AS snapshot_timing          -- スナップショットタイミング
             ,xbbs_fb.bm_paymet_kbn            AS bm_paymet_kbn            -- BM支払区分
             ,xbbs_fb.bm_tax_kbn               AS bm_tax_kbn               -- BM税区分
             ,xbbs_fb.bank_charge_bearer       AS bank_charge_bearer       -- 振込手数料負担者
             ,xbbs_fb.cust_name                AS cust_name                -- 設置先名
             ,xbbs_fb.bm_balance_id            AS bm_balance_id            -- 販手残高ID
             ,xbbs_fb.base_code                AS base_code                -- 拠点コード
             ,xbbs_fb.supplier_code            AS supplier_code            -- 仕入先コード
             ,xbbs_fb.cust_code                AS cust_code                -- 顧客コード
             ,xbbs_fb.closing_date             AS closing_date             -- 締め日
             ,xbbs_fb.expect_payment_date      AS expect_payment_date      -- 支払予定日
             ,xbbs_fb.payment_amt_tax          AS payment_amt_tax          -- 支払額（税込）
             ,xbbs_fb.resv_flag                AS resv_flag                -- 保留フラグ
             ,xbbs_fb.balance_cancel_date      AS balance_cancel_date      -- 残高取消日
             ,xbbs_sec.expect_payment_amt_tax  AS expect_payment_amt_tax   -- 元金額
             ,xbbs_sec.bank_charge_bearer      AS bank_charge_bearer_pre   -- 振込手数料負担者（元）
      FROM
        ( SELECT  /*+ INDEX(xbbs1 xxcok_bm_balance_snap_n01) */
                  xbbs1.bm_balance_id       AS bm_balance_id
                 ,CASE WHEN  xbbs1.closing_date <= gd_closing_date
                         AND xbbs1.expect_payment_date <= gd_schedule_date
                         AND xbbs1.resv_flag IS NULL
                         AND xbbs1.edi_interface_status = '0' -- 未連携
                         AND xbbs1.fb_interface_status  = '0' -- 未連携
                         AND xbbs1.gl_interface_status  = '0' -- 未連携
                         AND xbbs1.amt_fix_status       = '1' -- 金額確定済
                       THEN  xbbs1.expect_payment_amt_tax
                       ELSE  0
                  END                       AS expect_payment_amt_tax  -- 支払予定額（税込）
                 ,xbbs1.bank_charge_bearer  AS bank_charge_bearer      -- 振込手数料負担者
          FROM  xxcok_bm_balance_snap xbbs1
          WHERE xbbs1.snapshot_create_ym = gv_process_ym
          AND   xbbs1.snapshot_timing    = '1' -- 2営
        ) xbbs_sec                          -- 販手残高スナップショット（2営）
       ,( SELECT  /*+ INDEX(xbbs2 xxcok_bm_balance_snap_n01) */
                  xbbs2.snapshot_create_ym  AS snapshot_create_ym      -- スナップショット作成年月
                 ,xbbs2.snapshot_timing     AS snapshot_timing         -- スナップショットタイミング
                 ,xbbs2.bm_paymet_kbn       AS bm_paymet_kbn           -- BM支払区分
                 ,xbbs2.bm_tax_kbn          AS bm_tax_kbn              -- BM税区分
                 ,xbbs2.bank_charge_bearer  AS bank_charge_bearer      -- 振込手数料負担者
                 ,xbbs2.cust_name           AS cust_name               -- 設置先名
                 ,xbbs2.bm_balance_id       AS bm_balance_id           -- 販手残高ID
                 ,xbbs2.base_code           AS base_code               -- 拠点コード
                 ,xbbs2.supplier_code       AS supplier_code           -- 仕入先コード
                 ,xbbs2.cust_code           AS cust_code               -- 顧客コード
                 ,xbbs2.closing_date        AS closing_date            -- 締め日
                 ,xbbs2.expect_payment_date AS expect_payment_date     -- 支払予定日
                 ,CASE WHEN xbbs2.closing_date <= gd_closing_date
                         AND xbbs2.expect_payment_date <= gd_schedule_date
                         AND xbbs2.fb_interface_status  = '1' -- 連携済
                         AND xbbs2.balance_cancel_date  IS NULL
                         AND xbbs2.bm_paymet_kbn IN ('1','2') -- '1'(本振(案内書あり),'2'(本振(案内書なし))
                       THEN  xbbs2.payment_amt_tax
                       ELSE 0
                  END                       AS payment_amt_tax         -- 支払額（税込）
                 ,xbbs2.resv_flag           AS resv_flag               -- 保留フラグ
                 ,xbbs2.balance_cancel_date AS balance_cancel_date     -- 残高取消日
          FROM  xxcok_bm_balance_snap xbbs2
          WHERE xbbs2.snapshot_create_ym = gv_process_ym
          AND   xbbs2.snapshot_timing    = iv_proc_div -- FB
        ) xbbs_fb                           -- 販手残高スナップショット（FB）
      WHERE   xbbs_sec.bm_balance_id = xbbs_fb.bm_balance_id
      AND     ( xbbs_sec.bank_charge_bearer <> xbbs_fb.bank_charge_bearer
        OR      xbbs_sec.expect_payment_amt_tax <> xbbs_fb.payment_amt_tax )
      ORDER BY  xbbs_fb.supplier_code
               ,xbbs_fb.bm_balance_id
      ;
--
      l_bm_balance_snap_fb_rec    l_bm_balance_snap_fb_cur%ROWTYPE;
--
    -- ===============================================
    -- 組み戻し後差分チェックカーソル
    -- ===============================================
    CURSOR l_bm_balance_snap_re_cur (
             iv_proc_div  IN VARCHAR2
    )
    IS
      SELECT  xbbs_rec.snapshot_create_ym      AS snapshot_create_ym      -- スナップショット作成年月
             ,xbbs_rec.snapshot_timing         AS snapshot_timing         -- スナップショットタイミング
             ,xbbs_rec.bm_paymet_kbn           AS bm_paymet_kbn           -- BM支払区分
             ,xbbs_rec.bm_tax_kbn              AS bm_tax_kbn              -- BM税区分
             ,xbbs_rec.bank_charge_bearer      AS bank_charge_bearer      -- 振込手数料負担者
             ,xbbs_rec.cust_name               AS cust_name               -- 設置先名
             ,xbbs_rec.bm_balance_id           AS bm_balance_id           -- 販手残高ID
             ,xbbs_rec.base_code               AS base_code               -- 拠点コード
             ,xbbs_rec.supplier_code           AS supplier_code           -- 仕入先コード
             ,xbbs_rec.cust_code               AS cust_code               -- 顧客コード
             ,xbbs_rec.closing_date            AS closing_date            -- 締め日
             ,xbbs_rec.expect_payment_date     AS expect_payment_date     -- 支払予定日
             ,xbbs_rec.payment_amt_tax         AS payment_amt_tax         -- 支払額（税込）
             ,xbbs_rec.resv_flag               AS resv_flag               -- 保留フラグ
             ,xbbs_rec.balance_cancel_date     AS balance_cancel_date     -- 残高取消日
             ,xbbs_fb.payment_amt_tax          AS payment_amt_tax_pre     -- 元金額
             ,xbbs_fb.bank_charge_bearer       AS bank_charge_bearer_pre  -- 振込手数料負担者（元）
      FROM
        ( SELECT  xbbs3.bm_balance_id       AS bm_balance_id
                 ,CASE WHEN  xbbs3.closing_date <= gd_closing_date
                         AND xbbs3.expect_payment_date <= gd_schedule_date
                         AND xbbs3.fb_interface_status  = '1'
                         AND xbbs3.balance_cancel_date  IS NULL
                         AND xbbs3.bm_paymet_kbn IN ('1','2')
                       THEN  xbbs3.payment_amt_tax
                       ELSE 0
                  END                       AS payment_amt_tax
                 ,xbbs3.bank_charge_bearer  AS bank_charge_bearer
          FROM  xxcok_bm_balance_snap xbbs3
          WHERE xbbs3.snapshot_create_ym = gv_process_ym
          AND   xbbs3.snapshot_timing    = '2' -- FB
        ) xbbs_fb                           -- 販手残高スナップショット（FB）
       ,( SELECT  xbbs4.snapshot_create_ym  AS snapshot_create_ym         -- スナップショット作成年月
                 ,xbbs4.snapshot_timing     AS snapshot_timing            -- スナップショットタイミング
                 ,xbbs4.bm_paymet_kbn       AS bm_paymet_kbn              -- BM支払区分
                 ,xbbs4.bm_tax_kbn          AS bm_tax_kbn                 -- BM税区分
                 ,xbbs4.bank_charge_bearer  AS bank_charge_bearer         -- 振込手数料負担者
                 ,xbbs4.cust_name           AS cust_name                  -- 設置先名
                 ,xbbs4.bm_balance_id       AS bm_balance_id              -- 販手残高ID
                 ,xbbs4.base_code           AS base_code                  -- 拠点コード
                 ,xbbs4.supplier_code       AS supplier_code              -- 仕入先コード
                 ,xbbs4.cust_code           AS cust_code                  -- 顧客コード
                 ,xbbs4.closing_date        AS closing_date               -- 締め日
                 ,xbbs4.expect_payment_date AS expect_payment_date        -- 支払予定日
                 ,CASE WHEN  xbbs4.closing_date <= gd_closing_date
                         AND xbbs4.expect_payment_date <= gd_schedule_date
                         AND xbbs4.fb_interface_status  = '1'
                         AND xbbs4.balance_cancel_date  IS NULL
                         AND xbbs4.bm_paymet_kbn IN ('1','2')
                       THEN  xbbs4.payment_amt_tax
                       ELSE 0
                  END                       AS payment_amt_tax            -- 支払額（税込）
                 ,xbbs4.resv_flag           AS resv_flag                  -- 保留フラグ
                 ,xbbs4.balance_cancel_date AS balance_cancel_date        -- 残高取消日
          FROM  xxcok_bm_balance_snap xbbs4
          WHERE xbbs4.snapshot_create_ym = gv_process_ym
          AND   xbbs4.snapshot_timing    = iv_proc_div -- 組み戻し
        ) xbbs_rec                          -- 販手残高スナップショット（組み戻し）
      WHERE   xbbs_fb.bm_balance_id = xbbs_rec.bm_balance_id
      AND     xbbs_fb.payment_amt_tax <> xbbs_rec.payment_amt_tax
      ORDER BY  xbbs_rec.supplier_code
               ,xbbs_rec.bm_balance_id
      ;
--
      l_bm_balance_snap_re_rec    l_bm_balance_snap_re_cur%ROWTYPE;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 初期化
    -- ===============================================
    lv_supplier_code_fb_bk  := 'X';
    lv_supplier_code_rec_bk := 'X';
    ln_count     := 0;
    ln_count_sup := 0;
    o_no_dif_tab.delete;
    o_no_dif_sup_tab.delete;
--
    -- ===============================================
    -- 処理タイミングがFB後の場合
    -- ===============================================
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- A-7.新黒カスタム明細情報作成１
      -- ===============================================
      OPEN l_bm_balance_snap_fb_cur (
             iv_proc_div
           );
      << snap_fb_loop >>
      LOOP
        FETCH l_bm_balance_snap_fb_cur INTO l_bm_balance_snap_fb_rec;
        EXIT WHEN l_bm_balance_snap_fb_cur%NOTFOUND;
--
        /* 支払額（税込）が0より大きいかつ保留フラグが'Y'ではないまたは残高取消日が設定されていない場合、
        またはBM支払区分が1:本振（案内書あり）、2:本振（案内書なし）の場合、作成する。*/
        IF ( l_bm_balance_snap_fb_rec.payment_amt_tax > 0
             AND ( NVL(l_bm_balance_snap_fb_rec.resv_flag,'N') <> 'Y'
                   OR l_bm_balance_snap_fb_rec.balance_cancel_date IS NULL
                   OR l_bm_balance_snap_fb_rec.bm_paymet_kbn IN ('1','2') )) THEN
          NULL;
        ELSE
          -- カウントアップ
          ln_count := ln_count + 1;
          o_no_dif_tab(ln_count).supplier_code := l_bm_balance_snap_fb_rec.supplier_code;
          o_no_dif_tab(ln_count).cust_code     := l_bm_balance_snap_fb_rec.cust_code;
          -- 仕入先カウントアップ
          IF ( l_bm_balance_snap_fb_rec.supplier_code <> lv_supplier_code_fb_bk ) THEN
            ln_count_sup := ln_count_sup + 1;
            o_no_dif_sup_tab(ln_count_sup).supplier_code := l_bm_balance_snap_fb_rec.supplier_code;
          END IF;
        END IF;
--
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- スナップショット作成年月
         ,snapshot_timing             -- スナップショットタイミング 
         ,rev                         -- REV
         ,check_result                -- 妥当性チェック結果
         ,row_id                      -- 元テーブルレコードID
         ,edi_interface_date          -- 連携日（EDI支払案内書）
         ,vendor_code                 -- 送付先コード
         ,cust_code                   -- 顧客コード
         ,inst_dest                   -- 設置場所
         ,calc_type                   -- 計算条件
         ,calc_sort                   -- 計算条件ソート順
         ,sell_bottle                 -- 売価／容器
         ,sales_qty                   -- 販売本数
         ,sales_tax_amt               -- 販売金額（税込）
         ,sales_amt                   -- 販売金額（税抜）
         ,contract                    -- ご契約内容
         ,sales_fee                   -- 販売手数料（税抜）
         ,tax_amt                     -- 消費税
         ,sales_tax_fee               -- 販売手数料（税込）
         ,bottle_code                 -- 容器区分コード
         ,salling_price               -- 売価金額
         ,rebate_rate                 -- 割戻率
         ,rebate_amt                  -- 割戻額
         ,tax_code                    -- 税コード
         ,tax_div                     -- 税区分
         ,target_div                  -- 対象区分
         ,created_by                  -- 作成者
         ,creation_date               -- 作成日
         ,last_updated_by             -- 最終更新者
         ,last_update_date            -- 最終更新日
         ,last_update_login           -- 最終更新ログイン
         ,request_id                  -- 要求ID
         ,program_application_id      -- コンカレント・プログラム・アプリケーションID
         ,program_id                  -- コンカレント・プログラムID
         ,program_update_date         -- プログラム更新日
        )
        SELECT
            xbbs.snapshot_create_ym                 AS  snapshot_create_ym      -- スナップショット作成年月
           ,xbbs.snapshot_timing                    AS  snapshot_timing         -- スナップショットタイミング
           ,'3'                                     AS  rev                     -- REV（3:新黒（FB）)
           ,'0'                                     AS  check_result            -- 妥当性チェック結果（0:対象）
           ,NULL                                    AS  row_id                  -- 元テーブルレコードID
           ,NULL                                    AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xbbs.supplier_code                      AS  vendor_code             -- 送付先コード
           ,xcbs.delivery_cust_code                 AS  cust_code               -- 顧客コード
           ,SUBSTR( xbbs.cust_name, 1, 50 )         AS  inst_dest               -- 設置場所
           ,xcbs.calc_type                          AS  calc_type               -- 計算条件
           ,flv2.calc_type_sort                     AS  calc_sort               -- 計算条件ソート順
           ,CASE xcbs.calc_type
              WHEN '10'
              THEN TO_CHAR( xcbs.selling_price )
              WHEN '20'
              THEN SUBSTR( flv1.container_type_name, 1, 10 )
              ELSE flv2.disp
            END                                     AS  sell_bottle             -- 売価／容器
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.delivery_qty )
            END                                     AS  sales_qty               -- 販売本数
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_tax )
            END                                     AS  sales_tax_amt           -- 販売金額（税込）
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_no_tax )
            END                                     AS  sales_amt               -- 販売金額（税抜）
           ,CASE
              WHEN ( xcbs.rebate_rate IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_rate || '%'
              WHEN ( xcbs.rebate_amt IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_amt || '円'
            END                                     AS  contract                -- ご契約内容
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_no_tax )
              ELSE SUM( xcbs.cond_bm_amt_no_tax )
            END                                     AS  sales_fee               -- 販売手数料（税抜）
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_tax_amt )
              ELSE SUM( xcbs.cond_tax_amt )
            END                                     AS  tax_amt                 -- 消費税
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_tax )
              ELSE SUM( xcbs.cond_bm_amt_tax )
            END                                     AS  sales_tax_fee           -- 販売手数料（税込）
           ,flv1.container_type_code                AS  bottle_code             -- 容器区分コード
           ,xcbs.selling_price                      AS  salling_price           -- 売価金額
           ,xcbs.rebate_rate                        AS  rebate_rate             -- 割戻率
           ,xcbs.rebate_amt                         AS  rebate_amt              -- 割戻額
           ,xbbs.tax_code                           AS  tax_code                -- 税コード
           ,CASE
              WHEN xbbs.bm_tax_kbn = '1'
              THEN '2'
              WHEN xbbs.bm_tax_kbn IN ('2','3')
              THEN '1'
            END                                     AS  tax_div                 -- 税区分
           ,SUBSTR( xbbs.supplier_code, -1, 1 )     AS  target_div              -- 対象区分
           ,cn_created_by                           AS  created_by              -- 作成者
           ,SYSDATE                                 AS  creation_date           -- 作成日
           ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                 AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                           AS  request_id              -- 要求ID
           ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
        FROM  xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
             ,xxcok_bm_balance_snap     xbbs  -- 販手残高テーブルスナップショット
             ,(SELECT flv.attribute1 AS container_type_code
                     ,flv.meaning    AS container_type_name
               FROM fnd_lookup_values flv
               WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
               AND flv.language      = USERENV( 'LANG' )
              )                         flv1  -- 参照表（容器）
             ,(SELECT flv.lookup_code AS calc_type
                     ,flv.meaning     AS line_name
                     ,flv.attribute2  AS calc_type_sort
                     ,flv.attribute3  AS disp
               FROM fnd_lookup_values flv
               WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
               AND flv.language      = USERENV( 'LANG' )
              )                         flv2  -- 参照表（販手計算条件）
        WHERE  xbbs.bm_balance_id                     = l_bm_balance_snap_fb_rec.bm_balance_id
        AND    xbbs.snapshot_create_ym                = gv_process_ym
        AND    xbbs.snapshot_timing                   = iv_proc_div
        AND    xcbs.base_code                         = xbbs.base_code
        AND    xcbs.delivery_cust_code                = xbbs.cust_code
        AND    xcbs.supplier_code                     = xbbs.supplier_code
        AND    xcbs.closing_date                      = xbbs.closing_date
        AND    xcbs.expect_payment_date               = xbbs.expect_payment_date
        AND    xcbs.container_type_code               = flv1.container_type_code(+)
        AND    xcbs.calc_type                         = flv2.calc_type
        GROUP BY
               xbbs.snapshot_create_ym
              ,xbbs.snapshot_timing
              ,xbbs.supplier_code
              ,xcbs.delivery_cust_code
              ,SUBSTR(xbbs.cust_name,1,50)
              ,xcbs.calc_type
              ,flv2.calc_type_sort
              ,flv1.container_type_code
              ,flv1.container_type_name
              ,xcbs.selling_price
              ,xcbs.rebate_rate
              ,xcbs.rebate_amt
              ,xbbs.tax_code
              ,xbbs.bm_tax_kbn
              ,flv2.disp
        ;
--
        -- 仕入先コードが前仕入先コードと異なる場合、差分対象カウントアップ
        IF ( l_bm_balance_snap_fb_rec.supplier_code <> lv_supplier_code_fb_bk ) THEN
          -- 差分対象カウント
          gn_dif_cnt := gn_dif_cnt + 1;
        END IF;
        -- 仕入先コード保持
        lv_supplier_code_fb_bk := l_bm_balance_snap_fb_rec.supplier_code;
      END LOOP snap_fb_loop;
--
    END IF;
--
    -- ===============================================
    -- 処理タイミングが組み戻し後の場合
    -- ===============================================
    IF ( iv_proc_div = '3' ) THEN
      -- ===============================================
      -- A-6.赤データ作成（組み戻し後）
      -- ===============================================
      OPEN l_bm_balance_snap_re_cur (
             iv_proc_div
           );
      << snap_re_loop >>
      LOOP
        FETCH l_bm_balance_snap_re_cur INTO l_bm_balance_snap_re_rec;
        EXIT WHEN l_bm_balance_snap_re_cur%NOTFOUND;
--
        -- 仕入先コードが前仕入先コードと異なる場合、差分対象カウントアップ
        IF ( l_bm_balance_snap_re_rec.supplier_code <> lv_supplier_code_rec_bk ) THEN
          -- 差分対象カウント
          gn_dif_cnt := gn_dif_cnt + 1;
        -- 仕入先コードが前仕入先コードと同じ場合、スキップする
        ELSE
          CONTINUE;
        END IF;
--
        -- ===============================================
        -- 赤ヘッダーの作成
        -- ===============================================
        -- 新黒が存在する場合
        INSERT INTO xxcok_info_rev_header(
          snapshot_create_ym      -- スナップショット作成年月
         ,snapshot_timing         -- スナップショットタイミング
         ,rev                     -- REV
         ,check_result            -- 妥当性チェック結果
         ,row_id                  -- 元テーブルレコードID
         ,edi_interface_date      -- 連携日（EDI支払案内書）
         ,vendor_code             -- 送付先コード
         ,set_code                -- 通知書書式設定コード
         ,cust_code               -- 顧客コード
         ,cust_name               -- 会社名
         ,dest_post_code          -- 郵便番号
         ,dest_address1           -- 住所
         ,dest_tel                -- 電話番号
         ,fax                     -- FAX番号
         ,dept_name               -- 部署名
         ,send_post_code          -- 郵便番号（送付元）
         ,send_address1           -- 住所（送付元）
         ,send_tel                -- 電話番号（送付元）
         ,num                     -- 番号
         ,payment_date            -- 支払日
         ,closing_date            -- 締め日
         ,closing_date_min        -- 最小締め日
         ,notifi_amt              -- おもての通知金額
         ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
         ,tax_amt_8               -- 軽減8%消費税額
         ,total_amt_8             -- 軽減8%合計金額（税込）
         ,total_sales_qty         -- 販売本数合計
         ,total_sales_amt         -- 販売金額合計
         ,sales_fee               -- 販売手数料
         ,electric_amt            -- 電気代等合計　税抜
         ,tax_amt                 -- 消費税
         ,transfer_fee            -- 振込手数料 税込
         ,payment_amt             -- お支払金額 税込
         ,remarks                 -- おもて備考
         ,bank_code               -- 銀行コード
         ,bank_name               -- 銀行名
         ,branch_code             -- 支店コード
         ,branch_name             -- 支店名
         ,bank_holder_name_alt    -- 口座名
         ,tax_div                 -- 税区分
         ,target_div              -- 対象区分
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,last_update_login       -- 最終更新ログイン
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
         ,program_update_date     -- プログラム更新日
        )
        SELECT
            xirh.snapshot_create_ym                   AS  snapshot_create_ym      -- スナップショット作成年月
           ,iv_proc_div                               AS  snapshot_timing         -- スナップショットタイミング
           ,'4'                                       AS  rev                     -- REV 4：赤（組み戻し）
           ,'0'                                       AS  check_result            -- 妥当性チェック結果
           ,NULL                                      AS  row_id                  -- 元テーブルレコードID
           ,NULL                                      AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xirh.vendor_code                          AS  vendor_code             -- 送付先コード
           ,xirh.set_code                             AS  set_code                -- 通知書書式設定コード
           ,xirh.cust_code                            AS  cust_code               -- 顧客コード
           ,xirh.cust_name                            AS  cust_name               -- 会社名
           ,xirh.dest_post_code                       AS  dest_post_code          -- 郵便番号
           ,xirh.dest_address1                        AS  dest_address1           -- 住所
           ,xirh.dest_tel                             AS  dest_tel                -- 電話番号
           ,xirh.fax                                  AS  fax                     -- FAX番号
           ,xirh.dept_name                            AS  dept_name               -- 部署名
           ,xirh.send_post_code                       AS  send_post_code          -- 郵便番号（送付元）
           ,xirh.send_address1                        AS  send_address1           -- 住所（送付元）
           ,xirh.send_tel                             AS  send_tel                -- 電話番号（送付元）
           ,xirh.num                                  AS  num                     -- 番号
           ,xirh.payment_date                         AS  payment_date            -- 支払日
           ,xirh.closing_date                         AS  closing_date            -- 締め日
           ,xirh.closing_date_min                     AS  closing_date_min        -- 最小締め日
           ,(xirh.notifi_amt) * -1                    AS  notifi_amt              -- おもての通知金額
           ,(xirh.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
           ,(xirh.tax_amt_8) * -1                     AS  tax_amt_8               -- 軽減8%消費税額
           ,(xirh.total_amt_8) * -1                   AS  total_amt_8             -- 軽減8%合計金額（税込）
           ,(xirh.total_sales_qty) * -1               AS  total_sales_qty         -- 販売本数合計
           ,(xirh.total_sales_amt) * -1               AS  total_sales_amt         -- 販売金額合計
           ,(xirh.sales_fee) * -1                     AS  sales_fee               -- 販売手数料
           ,(xirh.electric_amt) * -1                  AS  electric_amt            -- 電気代等合計 税抜
           ,(xirh.tax_amt) * -1                       AS  tax_amt                 -- 消費税
           ,(xirh.transfer_fee) * -1                  AS  transfer_fee            -- 振込手数料 税込
           ,(xirh.payment_amt) * -1                   AS  payment_amt             -- お支払金額 税込
           ,'"'||SUBSTR(gv_remarks_re_deb,1,500)||'"' AS  remarks                 -- おもて備考
           ,xirh.bank_code                            AS  bank_code               -- 銀行コード
           ,xirh.bank_name                            AS  bank_name               -- 銀行名
           ,xirh.branch_code                          AS  branch_code             -- 支店コード
           ,xirh.branch_name                          AS  branch_name             -- 支店名
           ,xirh.bank_holder_name_alt                 AS  bank_holder_name_alt    -- 口座名
           ,xirh.tax_div                              AS  tax_div                 -- 税区分
           ,xirh.target_div                           AS  target_div              -- 対象区分
           ,cn_created_by                             AS  created_by              -- 作成者
           ,SYSDATE                                   AS  creation_date           -- 作成日
           ,cn_last_updated_by                        AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                   AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                      AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                             AS  request_id              -- 要求ID
           ,cn_program_application_id                 AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                             AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                   AS  program_update_date     -- プログラム更新日
        FROM   xxcok_info_rev_header    xirh  -- インフォマート用赤黒（ヘッダー）
        WHERE  xirh.vendor_code                       = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym                = gv_process_ym
        AND    xirh.snapshot_timing                   = '2' -- FB
        AND    xirh.rev                               = '3' -- 新黒（FB）
        AND    xirh.check_result                      = '0' -- 対象
        AND    xirh.notifi_amt                        > 0
        ;
--
        -- 赤データ作成件数カウントアップ
        gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
--
        -- 新黒が存在しない場合
        INSERT INTO xxcok_info_rev_header(
          snapshot_create_ym      -- スナップショット作成年月
         ,snapshot_timing         -- スナップショットタイミング
         ,rev                     -- REV
         ,check_result            -- 妥当性チェック結果
         ,row_id                  -- 元テーブルレコードID
         ,edi_interface_date      -- 連携日（EDI支払案内書）
         ,vendor_code             -- 送付先コード
         ,set_code                -- 通知書書式設定コード
         ,cust_code               -- 顧客コード
         ,cust_name               -- 会社名
         ,dest_post_code          -- 郵便番号
         ,dest_address1           -- 住所
         ,dest_tel                -- 電話番号
         ,fax                     -- FAX番号
         ,dept_name               -- 部署名
         ,send_post_code          -- 郵便番号（送付元）
         ,send_address1           -- 住所（送付元）
         ,send_tel                -- 電話番号（送付元）
         ,num                     -- 番号
         ,payment_date            -- 支払日
         ,closing_date            -- 締め日
         ,closing_date_min        -- 最小締め日
         ,notifi_amt              -- おもての通知金額
         ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
         ,tax_amt_8               -- 軽減8%消費税額
         ,total_amt_8             -- 軽減8%合計金額（税込）
         ,total_sales_qty         -- 販売本数合計
         ,total_sales_amt         -- 販売金額合計
         ,sales_fee               -- 販売手数料
         ,electric_amt            -- 電気代等合計　税抜
         ,tax_amt                 -- 消費税
         ,transfer_fee            -- 振込手数料　税込
         ,payment_amt             -- お支払金額　税込
         ,remarks                 -- おもて備考
         ,bank_code               -- 銀行コード
         ,bank_name               -- 銀行名
         ,branch_code             -- 支店コード
         ,branch_name             -- 支店名
         ,bank_holder_name_alt    -- 口座名
         ,tax_div                 -- 税区分
         ,target_div              -- 対象区分
         ,created_by              -- 作成者
         ,creation_date           -- 作成日
         ,last_updated_by         -- 最終更新者
         ,last_update_date        -- 最終更新日
         ,last_update_login       -- 最終更新ログイン
         ,request_id              -- 要求ID
         ,program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,program_id              -- コンカレント・プログラムID
         ,program_update_date     -- プログラム更新日
        )
        SELECT
            xirh.snapshot_create_ym                   AS  snapshot_create_ym      -- スナップショット作成年月
           ,iv_proc_div                               AS  snapshot_timing         -- スナップショットタイミング
           ,'4'                                       AS  rev                     -- REV 4：赤（組み戻し）
           ,'0'                                       AS  check_result            -- 妥当性チェック結果
           ,NULL                                      AS  row_id                  -- 元テーブルレコードID
           ,NULL                                      AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xirh.vendor_code                          AS  vendor_code             -- 送付先コード
           ,xirh.set_code                             AS  set_code                -- 通知書書式設定コード
           ,xirh.cust_code                            AS  cust_code               -- 顧客コード
           ,xirh.cust_name                            AS  cust_name               -- 会社名
           ,xirh.dest_post_code                       AS  dest_post_code          -- 郵便番号
           ,xirh.dest_address1                        AS  dest_address1           -- 住所
           ,xirh.dest_tel                             AS  dest_tel                -- 電話番号
           ,xirh.fax                                  AS  fax                     -- FAX番号
           ,xirh.dept_name                            AS  dept_name               -- 部署名
           ,xirh.send_post_code                       AS  send_post_code          -- 郵便番号（送付元）
           ,xirh.send_address1                        AS  send_address1           -- 住所（送付元）
           ,xirh.send_tel                             AS  send_tel                -- 電話番号（送付元）
           ,xirh.num                                  AS  num                     -- 番号
           ,xirh.payment_date                         AS  payment_date            -- 支払日
           ,xirh.closing_date                         AS  closing_date            -- 締め日
           ,xirh.closing_date_min                     AS  closing_date_min        -- 最小締め日
           ,(xirh.notifi_amt) * -1                    AS  notifi_amt              -- おもての通知金額
           ,(xirh.total_amt_no_tax_8) * -1            AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
           ,(xirh.tax_amt_8) * -1                     AS  tax_amt_8               -- 軽減8%消費税額
           ,(xirh.total_amt_8) * -1                   AS  total_amt_8             -- 軽減8%合計金額（税込）
           ,(xirh.total_sales_qty) * -1               AS  total_sales_qty         -- 販売本数合計
           ,(xirh.total_sales_amt) * -1               AS  total_sales_amt         -- 販売金額合計
           ,(xirh.sales_fee) * -1                     AS  sales_fee               -- 販売手数料
           ,(xirh.electric_amt) * -1                  AS  electric_amt            -- 電気代等合計 税抜
           ,(xirh.tax_amt) * -1                       AS  tax_amt                 -- 消費税
           ,(xirh.transfer_fee) * -1                  AS  transfer_fee            -- 振込手数料 税込
           ,(xirh.payment_amt) * -1                   AS  payment_amt             -- お支払金額 税込
           ,'"'||SUBSTR(gv_remarks_re_deb,1,500)||'"' AS  remarks                 -- おもて備考
           ,xirh.bank_code                            AS  bank_code               -- 銀行コード
           ,xirh.bank_name                            AS  bank_name               -- 銀行名
           ,xirh.branch_code                          AS  branch_code             -- 支店コード
           ,xirh.branch_name                          AS  branch_name             -- 支店名
           ,xirh.bank_holder_name_alt                 AS  bank_holder_name_alt    -- 口座名
           ,xirh.tax_div                              AS  tax_div                 -- 税区分
           ,xirh.target_div                           AS  target_div              -- 対象区分
           ,cn_created_by                             AS  created_by              -- 作成者
           ,SYSDATE                                   AS  creation_date           -- 作成日
           ,cn_last_updated_by                        AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                   AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                      AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                             AS  request_id              -- 要求ID
           ,cn_program_application_id                 AS  program_application_id  -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                             AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                   AS  program_update_date     -- プログラム更新日
        FROM   xxcok_info_rev_header    xirh  -- インフォマート用赤黒（ヘッダー）
        WHERE  xirh.vendor_code                       = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym                = gv_process_ym
        AND    xirh.snapshot_timing                   = '1' -- 2営
        AND    xirh.rev                               = '1' -- 元黒（2営）
        AND    xirh.notifi_amt                        > 0
        AND NOT EXISTS (
               SELECT 1
               FROM  xxcok_info_rev_header    xirh_new  -- インフォマート用赤黒（ヘッダー）
               WHERE xirh_new.snapshot_create_ym = xirh.snapshot_create_ym
               AND   xirh_new.snapshot_timing    = '2' -- FB
               AND   xirh_new.rev                = '3' -- 新黒（FB）
               AND   xirh_new.check_result       = '0' -- 対象
               AND   xirh_new.notifi_amt         > 0
               AND   xirh_new.vendor_code        = xirh.vendor_code 
            )
        ;
--
        -- 赤データ作成件数カウントアップ
        gn_debit_cnt := gn_debit_cnt + SQL%ROWCOUNT;
--
        -- ===============================================
        -- 赤カスタム明細の作成
        -- ===============================================
        -- 新黒が存在する場合
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- スナップショット作成年月
         ,snapshot_timing             -- スナップショットタイミング 
         ,rev                         -- REV
         ,check_result                -- 妥当性チェック結果
         ,row_id                      -- 元テーブルレコードID
         ,edi_interface_date          -- 連携日（EDI支払案内書）
         ,vendor_code                 -- 送付先コード
         ,cust_code                   -- 顧客コード
         ,inst_dest                   -- 設置場所
         ,calc_type                   -- 計算条件
         ,calc_sort                   -- 計算条件ソート順
         ,sell_bottle                 -- 売価／容器
         ,sales_qty                   -- 販売本数
         ,sales_tax_amt               -- 販売金額（税込）
         ,sales_amt                   -- 販売金額（税抜）
         ,contract                    -- ご契約内容
         ,sales_fee                   -- 販売手数料（税抜）
         ,tax_amt                     -- 消費税
         ,sales_tax_fee               -- 販売手数料（税込）
         ,bottle_code                 -- 容器区分コード
         ,salling_price               -- 売価金額
         ,REBATE_RATE                 -- 割戻率
         ,REBATE_AMT                  -- 割戻額
         ,tax_code                    -- 税コード
         ,tax_div                     -- 税区分
         ,target_div                  -- 対象区分
         ,created_by                  -- 作成者
         ,creation_date               -- 作成日
         ,last_updated_by             -- 最終更新者
         ,last_update_date            -- 最終更新日
         ,last_update_login           -- 最終更新ログイン
         ,request_id                  -- 要求ID
         ,program_application_id      -- コンカレント・プログラム・アプリケーションID
         ,program_id                  -- コンカレント・プログラムID
         ,program_update_date         -- プログラム更新日
        )
        SELECT
            xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- スナップショット作成年月
           ,iv_proc_div                             AS  snapshot_timing         -- スナップショットタイミング
           ,'4'                                     AS  rev                     -- REV（4:赤（組み戻し）)
           ,'0'                                     AS  check_result            -- 妥当性チェック結果（0:対象）
           ,NULL                                    AS  row_id                  -- 元テーブルレコードID
           ,NULL                                    AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xirc.vendor_code                        AS  vendor_code             -- 送付先コード
           ,xirc.cust_code                          AS  cust_code               -- 顧客コード
           ,xirc.inst_dest                          AS  inst_dest               -- 設置場所
           ,xirc.calc_type                          AS  calc_type               -- 計算条件
           ,xirc.calc_sort                          AS  calc_sort               -- 計算条件ソート順
           ,xirc.sell_bottle                        AS  sell_bottle             -- 売価／容器
           ,(xirc.sales_qty) * -1                   AS  sales_qty               -- 販売本数
           ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- 販売金額（税込）
           ,(xirc.sales_amt) * -1                   AS  sales_amt               -- 販売金額（税抜）
           ,xirc.contract                           AS  contract                -- ご契約内容
           ,(xirc.sales_fee) * -1                   AS  sales_fee               -- 販売手数料（税抜）
           ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- 消費税
           ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- 販売手数料（税込）
           ,xirc.bottle_code                        AS  bottle_code             -- 容器区分コード
           ,xirc.salling_price                      AS  salling_price           -- 売価金額
           ,xirc.rebate_rate                        AS  rebate_rate             -- 割戻率
           ,xirc.rebate_amt                         AS  rebate_amt              -- 割戻額
           ,xirc.tax_code                           AS  tax_code                -- 税コード
           ,xirc.tax_div                            AS  tax_div                 -- 税区分
           ,xirc.target_div                         AS  target_div              -- 対象区分
           ,cn_created_by                           AS  created_by              -- 作成者
           ,SYSDATE                                 AS  creation_date           -- 作成日
           ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                 AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                           AS  request_id              -- 要求ID
           ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
        FROM   xxcok_info_rev_header     xirh  -- インフォマート用赤黒（ヘッダー）
              ,xxcok_info_rev_custom     xirc  -- インフォマート用赤黒（カスタム明細）
        WHERE  xirh.vendor_code                     = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym              = gv_process_ym
        AND    xirh.snapshot_timing                 = '2' -- FB
        AND    xirh.rev                             = '3' -- 新黒（FB）
        AND    xirh.check_result                    = '0' -- 対象
        AND    xirh.notifi_amt                      > 0
        AND    xirh.snapshot_create_ym              = xirc.snapshot_create_ym
        AND    xirh.snapshot_timing                 = xirc.snapshot_timing
        AND    xirh.rev                             = xirc.rev
        AND    xirh.vendor_code                     = xirc.vendor_code
        ;
--
        -- 新黒が存在しない場合
        INSERT INTO xxcok_info_rev_custom (
          snapshot_create_ym          -- スナップショット作成年月
         ,snapshot_timing             -- スナップショットタイミング 
         ,rev                         -- REV
         ,check_result                -- 妥当性チェック結果
         ,row_id                      -- 元テーブルレコードID
         ,edi_interface_date          -- 連携日（EDI支払案内書）
         ,vendor_code                 -- 送付先コード
         ,cust_code                   -- 顧客コード
         ,inst_dest                   -- 設置場所
         ,calc_type                   -- 計算条件
         ,calc_sort                   -- 計算条件ソート順
         ,sell_bottle                 -- 売価／容器
         ,sales_qty                   -- 販売本数
         ,sales_tax_amt               -- 販売金額（税込）
         ,sales_amt                   -- 販売金額（税抜）
         ,contract                    -- ご契約内容
         ,sales_fee                   -- 販売手数料（税抜）
         ,tax_amt                     -- 消費税
         ,sales_tax_fee               -- 販売手数料（税込）
         ,bottle_code                 -- 容器区分コード
         ,salling_price               -- 売価金額
         ,REBATE_RATE                 -- 割戻率
         ,REBATE_AMT                  -- 割戻額
         ,tax_code                    -- 税コード
         ,tax_div                     -- 税区分
         ,target_div                  -- 対象区分
         ,created_by                  -- 作成者
         ,creation_date               -- 作成日
         ,last_updated_by             -- 最終更新者
         ,last_update_date            -- 最終更新日
         ,last_update_login           -- 最終更新ログイン
         ,request_id                  -- 要求ID
         ,program_application_id      -- コンカレント・プログラム・アプリケーションID
         ,program_id                  -- コンカレント・プログラムID
         ,program_update_date         -- プログラム更新日
        )
        SELECT
            xirc.snapshot_create_ym                 AS  snapshot_create_ym      -- スナップショット作成年月
           ,iv_proc_div                             AS  snapshot_timing         -- スナップショットタイミング
           ,'4'                                     AS  rev                     -- REV（4:赤（組み戻し）)
           ,'0'                                     AS  check_result            -- 妥当性チェック結果（0:対象）
           ,NULL                                    AS  row_id                  -- 元テーブルレコードID
           ,NULL                                    AS  edi_interface_date      -- 連携日（EDI支払案内書）
           ,xirc.vendor_code                        AS  vendor_code             -- 送付先コード
           ,xirc.cust_code                          AS  cust_code               -- 顧客コード
           ,xirc.inst_dest                          AS  inst_dest               -- 設置場所
           ,xirc.calc_type                          AS  calc_type               -- 計算条件
           ,xirc.calc_sort                          AS  calc_sort               -- 計算条件ソート順
           ,xirc.sell_bottle                        AS  sell_bottle             -- 売価／容器
           ,(xirc.sales_qty) * -1                   AS  sales_qty               -- 販売本数
           ,(xirc.sales_tax_amt) * -1               AS  sales_tax_amt           -- 販売金額（税込）
           ,(xirc.sales_amt) * -1                   AS  sales_amt               -- 販売金額（税抜）
           ,xirc.contract                           AS  contract                -- ご契約内容
           ,(xirc.sales_fee) * -1                   AS  sales_fee               -- 販売手数料（税抜）
           ,(xirc.tax_amt) * -1                     AS  tax_amt                 -- 消費税
           ,(xirc.sales_tax_fee) * -1               AS  sales_tax_fee           -- 販売手数料（税込）
           ,xirc.bottle_code                        AS  bottle_code             -- 容器区分コード
           ,xirc.salling_price                      AS  salling_price           -- 売価金額
           ,xirc.rebate_rate                        AS  rebate_rate             -- 割戻率
           ,xirc.rebate_amt                         AS  rebate_amt              -- 割戻額
           ,xirc.tax_code                           AS  tax_code                -- 税コード
           ,xirc.tax_div                            AS  tax_div                 -- 税区分
           ,xirc.target_div                         AS  target_div              -- 対象区分
           ,cn_created_by                           AS  created_by              -- 作成者
           ,SYSDATE                                 AS  creation_date           -- 作成日
           ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                 AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                           AS  request_id              -- 要求ID
           ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
        FROM   xxcok_info_rev_header     xirh  -- インフォマート用赤黒（ヘッダー）
              ,xxcok_info_rev_custom     xirc  -- インフォマート用赤黒（カスタム明細）
        WHERE  xirh.vendor_code                     = l_bm_balance_snap_re_rec.supplier_code
        AND    xirh.snapshot_create_ym              = gv_process_ym
        AND    xirh.snapshot_timing                 = '1' -- 2営
        AND    xirh.rev                             = '1' -- 元黒（2営ファイル作成）
        AND    xirh.notifi_amt                      > 0
        AND NOT EXISTS (
               SELECT 1
               FROM  xxcok_info_rev_header    xirh_new  -- インフォマート用赤黒（ヘッダー）
               WHERE xirh_new.snapshot_create_ym = xirh.snapshot_create_ym
               AND   xirh_new.snapshot_timing    = '2' -- FB
               AND   xirh_new.rev                = '3' -- 新黒（FB）
               AND   xirh_new.check_result       = '0' -- 対象
               AND   xirh_new.notifi_amt         > 0
               AND   xirh_new.vendor_code        = xirh.vendor_code 
            )
        AND    xirh.snapshot_create_ym              = xirc.snapshot_create_ym
        AND    xirh.snapshot_timing                 = xirc.snapshot_timing
        AND    xirh.rev                             = xirc.rev
        AND    xirh.vendor_code                     = xirc.vendor_code
        ;
--
        -- 仕入先コード保持
        lv_supplier_code_rec_bk := l_bm_balance_snap_re_rec.supplier_code;
      END LOOP snap_re_loop;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END difference_check;
--
  /**********************************************************************************
   * Procedure Name   : ins_snap_data
   * Description      : 販手残高スナップショット作成(A-4)
   ***********************************************************************************/
  PROCEDURE ins_snap_data(
    iv_proc_div    IN  VARCHAR2    --  1.処理タイミング
   ,ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_snap_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    -- ===============================================
    -- 販手残高カーソル
    -- ===============================================
    CURSOR l_bm_balance_snap_cur
    IS
      SELECT  /*+ LEADING(xbbs_sec xbb pv pvsa) */
         CASE iv_proc_div
           WHEN '2' THEN pvsa.attribute4
           WHEN '3' THEN xbbs_fb.bm_paymet_kbn
         END                             AS bm_paymet_kbn                       -- BM支払区分
        ,xbbs_sec.bm_tax_kbn             AS bm_tax_kbn                          -- BM税区分
        ,CASE iv_proc_div
           WHEN '2' THEN pvsa.bank_charge_bearer
           WHEN '3' THEN xbbs_fb.bank_charge_bearer
         END                             AS bank_charge_bearer                  -- 振込手数料負担者
        ,xbbs_sec.cust_name              AS cust_name                           -- 設置先名
        ,xbb.bm_balance_id               AS bm_balance_id                       -- 販手残高ID
        ,xbb.base_code                   AS base_code                           -- 拠点コード
        ,xbb.supplier_code               AS supplier_code                       -- 仕入先コード
        ,xbb.supplier_site_code          AS supplier_site_code                  -- 仕入先サイトコード
        ,xbb.cust_code                   AS cust_code                           -- 顧客コード
        ,xbb.closing_date                AS closing_date                        -- 締め日
        ,xbb.selling_amt_tax             AS selling_amt_tax                     -- 販売金額（税込）
        ,xbb.backmargin                  AS backmargin                          -- 販売手数料
        ,xbb.backmargin_tax              AS backmargin_tax                      -- 販売手数料（消費税額）
        ,xbb.electric_amt                AS electric_amt                        -- 電気料
        ,xbb.electric_amt_tax            AS electric_amt_tax                    -- 電気料（消費税額）
        ,xbb.tax_code                    AS tax_code                            -- 税金コード
        ,xbb.expect_payment_date         AS expect_payment_date                 -- 支払予定日
        ,xbb.expect_payment_amt_tax      AS expect_payment_amt_tax              -- 支払予定額（税込）
        ,xbb.payment_amt_tax             AS payment_amt_tax                     -- 支払額（税込）
        ,xbb.balance_cancel_date         AS balance_cancel_date                 -- 残高取消日
        ,xbb.resv_flag                   AS resv_flag                           -- 保留フラグ
        ,xbb.return_flag                 AS return_flag                         -- 組み戻しフラグ
        ,xbb.publication_date            AS publication_date                    -- 案内書発効日
        ,xbb.fb_interface_status         AS fb_interface_status                 -- 連携ステータス（本振用FB）
        ,xbb.fb_interface_date           AS fb_interface_date                   -- 連携日（本振用FB）
        ,xbb.edi_interface_status        AS edi_interface_status                -- 連携ステータス（EDI支払案内書）
        ,xbb.edi_interface_date          AS edi_interface_date                  -- 連携日（EDI支払案内書）
        ,xbb.gl_interface_status         AS gl_interface_status                 -- 連携ステータス（GL）
        ,xbb.gl_interface_date           AS gl_interface_date                   -- 連携日（GL）
        ,xbb.amt_fix_status              AS amt_fix_status                      -- 金額確定ステータス
        ,xbb.org_slip_number             AS org_slip_number                     -- 元伝票番号
        ,xbb.proc_type                   AS proc_type                           -- 処理区分
      FROM    xxcok_backmargin_balance  xbb      -- 販手残高テーブル
             ,xxcok_bm_balance_snap     xbbs_sec -- 販手残高テーブルスナップショット2営
             ,xxcok_bm_balance_snap     xbbs_fb  -- 販手残高テーブルスナップショットFB
             ,po_vendors                pv       -- 仕入先マスタ
             ,po_vendor_sites_all       pvsa     -- 仕入先サイト
      WHERE   xbbs_sec.bm_balance_id        = xbb.bm_balance_id
      AND     xbbs_sec.snapshot_create_ym   = gv_process_ym
      AND     xbbs_sec.snapshot_timing      = '1' -- 2営
      AND     xbb.supplier_code             = pv.segment1
      AND     pv.vendor_id                  = pvsa.vendor_id
      AND     ( pvsa.inactive_date          > gd_process_date
      OR      pvsa.inactive_date            IS NULL )
      AND     pvsa.org_id                   = gn_org_id
      AND     xbbs_fb.bm_balance_id(+)      = xbbs_sec.bm_balance_id
      AND     xbbs_fb.snapshot_create_ym(+) = gv_process_ym
      AND     xbbs_fb.snapshot_timing(+)    = '2'
      ;
--
    l_bm_balance_snap_rec    l_bm_balance_snap_cur%ROWTYPE;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 第2営業日時点での販手残高スナップショットの仕入先件数を取得
    -- ===============================================
    SELECT COUNT(DISTINCT supplier_code)
    INTO   gn_target_cnt
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing = '1' -- 2営
    ;
    << bm_balance_snap_loop >>
    FOR l_bm_balance_snap_rec IN l_bm_balance_snap_cur LOOP
      -- ===============================================
      -- 販手残高スナップショット登録
      -- ===============================================
      INSERT INTO xxcok_bm_balance_snap(
         snapshot_create_ym                      -- スナップショット作成年月
        ,snapshot_timing                         -- スナップショットタイミング
        ,bm_paymet_kbn                           -- BM支払区分
        ,bm_tax_kbn                              -- BM税区分
        ,bank_charge_bearer                      -- 振込手数料負担者
        ,cust_name                               -- 設置先名
        ,bm_balance_id                           -- 販手残高ID
        ,base_code                               -- 拠点コード
        ,supplier_code                           -- 仕入先コード
        ,supplier_site_code                      -- 仕入先サイトコード
        ,cust_code                               -- 顧客コード
        ,closing_date                            -- 締め日
        ,selling_amt_tax                         -- 販売金額（税込）
        ,backmargin                              -- 販売手数料
        ,backmargin_tax                          -- 販売手数料（消費税額）
        ,electric_amt                            -- 電気料
        ,electric_amt_tax                        -- 電気料（消費税額）
        ,tax_code                                -- 税金コード
        ,expect_payment_date                     -- 支払予定日
        ,expect_payment_amt_tax                  -- 支払予定額（税込）
        ,payment_amt_tax                         -- 支払額（税込）
        ,balance_cancel_date                     -- 残高取消日
        ,resv_flag                               -- 保留フラグ
        ,return_flag                             -- 組み戻しフラグ
        ,publication_date                        -- 案内書発効日
        ,fb_interface_status                     -- 連携ステータス（本振用FB）
        ,fb_interface_date                       -- 連携日（本振用FB）
        ,edi_interface_status                    -- 連携ステータス（EDI支払案内書）
        ,edi_interface_date                      -- 連携日（EDI支払案内書）
        ,gl_interface_status                     -- 連携ステータス（GL）
        ,gl_interface_date                       -- 連携日（GL）
        ,amt_fix_status                          -- 金額確定ステータス
        ,org_slip_number                         -- 元伝票番号
        ,proc_type                               -- 処理区分
        ,created_by                              -- 作成者
        ,creation_date                           -- 作成日
        ,last_updated_by                         -- 最終更新者
        ,last_update_date                        -- 最終更新日
        ,last_update_login                       -- 最終更新ログイン
        ,request_id                              -- 要求ID
        ,program_application_id                  -- コンカレント・プログラム・アプリケーションID
        ,program_id                              -- コンカレント・プログラムID
        ,program_update_date                     -- プログラム更新日      
        )
      VALUES (
         gv_process_ym                                                 -- スナップショット作成年月
        ,iv_proc_div                                                   -- スナップショットタイミング
        ,l_bm_balance_snap_rec.bm_paymet_kbn                           -- BM支払区分
        ,l_bm_balance_snap_rec.bm_tax_kbn                              -- BM税区分
        ,l_bm_balance_snap_rec.bank_charge_bearer                      -- 振込手数料負担者
        ,l_bm_balance_snap_rec.cust_name                               -- 設置先名
        ,l_bm_balance_snap_rec.bm_balance_id                           -- 販手残高ID
        ,l_bm_balance_snap_rec.base_code                               -- 拠点コード
        ,l_bm_balance_snap_rec.supplier_code                           -- 仕入先コード
        ,l_bm_balance_snap_rec.supplier_site_code                      -- 仕入先サイトコード
        ,l_bm_balance_snap_rec.cust_code                               -- 顧客コード
        ,l_bm_balance_snap_rec.closing_date                            -- 締め日
        ,l_bm_balance_snap_rec.selling_amt_tax                         -- 販売金額（税込）
        ,l_bm_balance_snap_rec.backmargin                              -- 販売手数料
        ,l_bm_balance_snap_rec.backmargin_tax                          -- 販売手数料（消費税額）
        ,l_bm_balance_snap_rec.electric_amt                            -- 電気料
        ,l_bm_balance_snap_rec.electric_amt_tax                        -- 電気料（消費税額）
        ,l_bm_balance_snap_rec.tax_code                                -- 税金コード
        ,l_bm_balance_snap_rec.expect_payment_date                     -- 支払予定日
        ,l_bm_balance_snap_rec.expect_payment_amt_tax                  -- 支払予定額（税込）
        ,l_bm_balance_snap_rec.payment_amt_tax                         -- 支払額（税込）
        ,l_bm_balance_snap_rec.balance_cancel_date                     -- 残高取消日
        ,l_bm_balance_snap_rec.resv_flag                               -- 保留フラグ
        ,l_bm_balance_snap_rec.return_flag                             -- 組み戻しフラグ
        ,l_bm_balance_snap_rec.publication_date                        -- 案内書発効日
        ,l_bm_balance_snap_rec.fb_interface_status                     -- 連携ステータス（本振用FB）
        ,l_bm_balance_snap_rec.fb_interface_date                       -- 連携日（本振用FB）
        ,l_bm_balance_snap_rec.edi_interface_status                    -- 連携ステータス（EDI支払案内書）
        ,l_bm_balance_snap_rec.edi_interface_date                      -- 連携日（EDI支払案内書）
        ,l_bm_balance_snap_rec.gl_interface_status                     -- 連携ステータス（GL）
        ,l_bm_balance_snap_rec.gl_interface_date                       -- 連携日（GL）
        ,l_bm_balance_snap_rec.amt_fix_status                          -- 金額確定ステータス
        ,l_bm_balance_snap_rec.org_slip_number                         -- 元伝票番号
        ,l_bm_balance_snap_rec.proc_type                               -- 処理区分
        ,cn_created_by                                                 -- 作成者
        ,SYSDATE                                                       -- 作成日
        ,cn_last_updated_by                                            -- 最終更新者
        ,SYSDATE                                                       -- 最終更新日
        ,cn_last_update_login                                          -- 最終更新ログイン
        ,cn_request_id                                                 -- 要求ID
        ,cn_program_application_id                                     -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                                                 -- コンカレント・プログラムID
        ,SYSDATE                                                       -- プログラム更新日
        );
--
    END LOOP bm_balance_snap_loop;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_snap_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_check
   * Description      : 処理チェック(A-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'proc_check';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    ln_count_fb     NUMBER;                                   -- FB実施確認件数
    ln_count_re     NUMBER;                                   -- 組み戻し実施確認件数
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 処理チェックエラー ***
    proc_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- FB後の実行前に組み戻し後を実行した場合、エラー
    SELECT COUNT(1) count_fb
    INTO   ln_count_fb
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing    = '2' -- FB後
    ;
--
    IF ( ln_count_fb = 0 ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10821
                       );
      RAISE proc_expt;
    END IF;
--
    -- 既に組み戻しを実行している場合、警告
    SELECT COUNT(1) count_re
    INTO   ln_count_re
    FROM   xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym
    AND    xbbs.snapshot_timing    = '3' -- 組み戻し後
    ;
    IF ( ln_count_re > 0 ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10822
                       );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode    := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END proc_check;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : 前月データ削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_work(
    ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'del_work';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルスナップショット
    DELETE FROM xxcok_bm_balance_snap xbbs
    WHERE  xbbs.snapshot_create_ym = gv_process_ym_pre
    ;
--
    -- インフォマート用赤黒（ヘッダー）
    DELETE FROM xxcok_info_rev_header xirh
    WHERE  xirh.snapshot_create_ym = gv_process_ym_pre
    ;
--
    -- インフォマート用赤黒（カスタム明細）
    DELETE FROM xxcok_info_rev_custom xirc
    WHERE  xirc.snapshot_create_ym = gv_process_ym_pre
    ;
--
    COMMIT ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_div   IN  VARCHAR2    --  1.処理タイミング
   ,ov_errbuf     OUT VARCHAR2    --  エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2    --  リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2    --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'init';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
    lv_head_item    fnd_new_messages.message_text%TYPE;
    lv_custom_item  fnd_new_messages.message_text%TYPE;
    ln_cnt          NUMBER;
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- グローバル変数初期化
    -- ===============================================
    g_no_dif_tab.delete ;
    g_no_dif_sup_tab.delete;
    -- ===============================================
    -- コンカレント入力パラメータを出力
    -- ===============================================
    lv_errmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxcok
                      ,iv_name         => cv_msg_xxcok1_10817
                      ,iv_token_name1  => cv_tkn_proc_div
                      ,iv_token_value1 => iv_proc_div
                     );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 1.業務日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_00028
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.業務日付年月取得
    -- ===============================================
    gv_process_ym   := TO_CHAR( gd_process_date,'YYYYMM' );
    -- ===============================================
    -- 3.前月年月取得
    -- ===============================================
    gv_process_ym_pre := TO_CHAR( ADD_MONTHS(gd_process_date,-1),'YYYYMM' );
--
    -- ===============================================
    -- 4.プロファイル取得(銀行手数料_振込額基準)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_errmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                           ,iv_name          => cv_msg_xxcok1_00003
                           ,iv_token_name1   => cv_tkn_profile
                           ,iv_token_value1  => cv_prof_bank_fee_trans
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(銀行手数料_基準額未満)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_less
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(銀行手数料_基準額以上)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_more
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(販売手数料_消費税率)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bm_tax
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(支払条件_デフォルト)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_errmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_term_name
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(組織ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 4.プロファイル取得(電気料（変動）品目コード)
    -- ===============================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_prof_elec_change_item ) ;
    IF ( gv_elec_change_item_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_elec_change_item
                    );
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 5.メッセージ取得(おもて備考FB赤用)
    -- ===============================================
    gv_remarks_fb_deb  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10818
                          );
    -- ===============================================
    -- 5.メッセージ取得(おもて備考新黒用)
    -- ===============================================
    gv_remarks_new_cre := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10819
                          );
    -- ===============================================
    -- 5.メッセージ取得(おもて備考組み戻し赤用)
    -- ===============================================
    gv_remarks_re_deb  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appli_short_name_xxcok
                           ,iv_name         => cv_msg_xxcok1_10820
                          );
--
    -- ===============================================
    -- 6.締め日,支払日予定日取得
    -- ===============================================
    -- 業務日付 -1ヶ月の締め日、支払予定日を取得
    gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
    xxcok_common_pkg.get_close_date_p(
        ov_errbuf         => lv_errbuf
       ,ov_retcode        => lv_retcode
       ,ov_errmsg         => lv_errmsg
       ,id_proc_date      => gd_operating_date
       ,iv_pay_cond       => gv_term_name
       ,od_close_date     => gd_closing_date   -- 締め日
       ,od_pay_date       => gd_schedule_date  -- 支払予定日
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 7.税込手数料取得
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( 1 + gn_bm_tax / 100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( 1 + gn_bm_tax / 100 );
--
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_div   IN  VARCHAR2    --  1.処理タイミング
   ,ov_errbuf     OUT VARCHAR2    --  エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2    --  リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2    --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================================
    -- 固定ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'submain';
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      iv_proc_div   =>  iv_proc_div     --  1.処理タイミング
     ,ov_errbuf     =>  lv_errbuf       --  エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --  リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理タイミング = 2：FBデータ作成後の場合
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- 前月データ削除(A-2)
      -- ===============================================
      del_work(
        ov_errbuf     => lv_errbuf      --  エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --  リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 処理タイミング = 3：組み戻し後の場合
    IF ( iv_proc_div = '3' ) THEN
      -- ===============================================
      -- 処理チェック(A-3)
      -- ===============================================
      proc_check(
        ov_errbuf     => lv_errbuf      --  エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --  リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode    := cv_status_warn;
      END IF;
    END IF;
--
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================================
      -- 販手残高スナップショット作成(A-4)
      -- ===============================================
      ins_snap_data(
        iv_proc_div     => iv_proc_div   --  1.処理タイミング
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 差分チェック(A-5),赤データ作成（組み戻し後）(A-6),新黒カスタム明細情報作成１(A-7)
      -- ===============================================
      difference_check(
        iv_proc_div      => iv_proc_div      --  1.処理タイミング
       ,o_no_dif_tab     => g_no_dif_tab     --  スキップする顧客テーブル
       ,o_no_dif_sup_tab => g_no_dif_sup_tab --  スキップする仕入先テーブル
       ,ov_errbuf        => lv_errbuf
       ,ov_retcode       => lv_retcode
       ,ov_errmsg        => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 処理タイミング = 2：FBデータ作成後の場合
      IF ( iv_proc_div = '2' ) THEN
        -- ===============================================
        -- 新黒カスタム明細情報作成２(A-8)
        -- ===============================================
        ins_credit_custom(
          iv_proc_div   => iv_proc_div  --  1.処理タイミング
         ,i_no_dif_tab  => g_no_dif_tab --  スキップする顧客テーブル
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================================
        -- 新黒カスタム明細情報作成３(A-12)
        -- ===============================================
        ins_credit_custom_mon(
          iv_proc_div   => iv_proc_div  --  1.処理タイミング
         ,i_no_dif_tab  => g_no_dif_tab --  スキップする顧客テーブル
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================================
        -- 新黒ヘッダー情報作成(A-9)
        -- ===============================================
        ins_credit_header(
          iv_proc_div   => iv_proc_div   --  1.処理タイミング
         ,ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================================
        -- 赤データ作成（FB後）(A-10)
        -- ===============================================
        ins_debit_fb(
          iv_proc_div      => iv_proc_div      --  1.処理タイミング
         ,i_no_dif_sup_tab => g_no_dif_sup_tab --  スキップする仕入先テーブル
         ,ov_errbuf        => lv_errbuf
         ,ov_retcode       => lv_retcode
         ,ov_errmsg        => lv_errmsg
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_proc_div     IN  VARCHAR2          -- 1.処理タイミング
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20)  := 'main';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラーメッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターンコード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザーエラーメッセージ
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- メッセージコード
--
  BEGIN
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_proc_div   => iv_proc_div      -- 1.処理タイミング
     ,ov_errbuf     => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => cv_msg_xxccp1_90000
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 差分対象件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_dif_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10823
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_dif_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 赤データ作成件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_debit_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10824
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_debit_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 黒データ作成件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_credit_cnt := 0;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10825
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_credit_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => cv_msg_xxccp1_90002
                     ,iv_token_name1  => cv_tkn_count
                     ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- 削除メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appli_short_name_xxcok
                       ,iv_name         => cv_msg_xxcok1_10826
                      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_errmsg    := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxccp
                     ,iv_name         => lv_message_code
                    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK016A03C;
/
