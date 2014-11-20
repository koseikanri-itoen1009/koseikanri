CREATE OR REPLACE PACKAGE BODY XXCOK021A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A05C(body)
 * Description      : APインターフェイス
 * MD.050           : APインターフェース MD050_COK_021_A05
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_csv           データファイル出力(A-8)
 *  change_status        連携ステータス更新(A-7)
 *  amount_chk           金額チェック(A-6)
 *  create_detail_tax    AP請求書明細OIF登録(A-5) 消費税
 *  create_detail_data   AP請求書明細OIF(A-5) 税以外
 *  create_oif_data      AP請求書ヘッダーOIF登録(A-3)
 *  init                 初期処理(A-1)
 *  submain              メイン処理プロシージャ
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   S.Tozawa         新規作成
 *  2009/02/02    1.1   S.Tozawa         [障害COK_006]結合テスト時修正対応
 *  2009/02/12    1.2   K.Iwabuchi       [障害COK_030]結合テスト時修正対応
 *  2009/10/06    1.3   S.Moriyama       [障害E_T3_00632]仕訳伝票入力者を処理実行ユーザーの従業員番号へ変更
 *  2009/10/22    1.4   K.Yamaguchi      [障害E_T4_00070]支払グループを設定しないように変更
 *  2009/11/25    1.5   K.Yamaguchi      [E_本稼動_00021]金額不一致対応
 *                                                       明細レコード取得時にインターフェースステータスを
 *                                                       考慮するように変更
 *                                                       AP_IFヘッダに登録している請求書番号を問屋支払テーブルへ更新
 *  2009/12/09    1.6   K.Yamaguchi      [E_本稼動_00388]連携ステータス更新条件漏れ対応
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK021A05C';
  -- アプリケーション短縮名
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  cv_sqlap_appl_short_name   CONSTANT VARCHAR2(10)  := 'SQLAP';
  -- ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  -- メッセージコード
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_msg_code_00042          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00042';  -- 会計期間チェック警告メッセージ
  cv_msg_code_10189          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10189';  -- 対象データなしメッセージ
  cv_msg_code_10190          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10190';  -- データ登録エラー(ヘッダー)
  cv_msg_code_10191          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10191';  -- データ登録エラー(明細・販売手数料)
  cv_msg_code_10192          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10192';  -- データ登録エラー(明細・販売協賛金)
  cv_msg_code_10193          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10193';  -- データ登録エラー(明細・その他科目)
  cv_msg_code_10194          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10194';  -- 明細金額相違メッセージ
  cv_msg_code_10195          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10195';  -- ロック取得エラー(請求書明細)
  cv_msg_code_10196          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10196';  -- 更新エラー(請求書明細)
  cv_msg_code_10197          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10197';  -- ロック取得エラー(支払テーブル)
  cv_msg_code_10198          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10198';  -- 更新エラー(支払テーブル)
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';  -- 成功件数
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_code_90003          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';  -- スキップ件数
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_code_90005          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  cv_msg_code_90008          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_code_00034          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00034';  -- 勘定科目情報取得エラー
  cv_msg_code_10407          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10407';  -- データ登録エラー(明細・消費税)
  cv_msg_code_10416          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10416';  -- 請求書番号取得エラー
  cv_msg_code_00089          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00089';  -- 消費税取得エラー
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD START
  cv_msg_code_00005          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00005';  -- 従業員取得エラー
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD END
  -- トークン
  cv_token_profile           CONSTANT VARCHAR2(20)  := 'PROFILE';
  cv_token_proc_date         CONSTANT VARCHAR2(20)  := 'PROC_DATE';
  cv_token_payment_date      CONSTANT VARCHAR2(20)  := 'PAYMENT_DATE';
  cv_token_sales_month       CONSTANT VARCHAR2(20)  := 'SALES_MONTH';
  cv_token_vender_code       CONSTANT VARCHAR2(20)  := 'VENDOR_CODE';
  cv_token_base_code         CONSTANT VARCHAR2(20)  := 'BASE_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';
  cv_token_balance_code      CONSTANT VARCHAR2(20)  := 'BALANCE_CODE';
  cv_token_acct_code         CONSTANT VARCHAR2(20)  := 'ACCOUNT_CODE';
  cv_token_assist_code       CONSTANT VARCHAR2(20)  := 'ASSIST_CODE';
  cv_token_count             CONSTANT VARCHAR2(20)  := 'COUNT';
  -- プロファイル
  cv_prof_books_id           CONSTANT VARCHAR2(40)  := 'GL_SET_OF_BKS_ID';               -- 会計帳簿ID
  cv_prof_org_id             CONSTANT VARCHAR2(40)  := 'ORG_ID';                         -- 組織ID
  -- カスタム・プロファイル
  cv_prof_company_code       CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF1_COMPANY_CODE';       -- 会社コード
  cv_prof_dept_act           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_ACT';           -- 部門コード_業務管理部
  cv_prof_detail_type_item   CONSTANT VARCHAR2(40)  := 'XXCOK1_OIF_DETAIL_TYPE_ITEM';    -- OIF明細タイプ_明細
  cv_prof_invoice_source     CONSTANT VARCHAR2(40)  := 'XXCOK1_INVOICE_SOURCE';          -- 請求書ソース
-- 2009/10/22 Ver.1.4 [障害E_T4_00070] SCS K.Yamaguchi DELETE START
--  cv_prof_pay_group          CONSTANT VARCHAR2(40)  := 'XXCOK1_PAY_GROUP';               -- 支払グループ
-- 2009/10/22 Ver.1.4 [障害E_T4_00070] SCS K.Yamaguchi DELETE END
  cv_prof_invoice_tax_code   CONSTANT VARCHAR2(40)  := 'XXCOK1_INVOICE_TAX_CODE';        -- 請求書税コード
  cv_prof_dept_fin           CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF2_DEPT_FIN';           -- 部門コード_財務経理部
  cv_prof_customer_dummy     CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF5_CUSTOMER_DUMMY';     -- 顧客コード_ダミー値
  cv_prof_company_dummy      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF6_COMPANY_DUMMY';      -- 企業コード_ダミー値
  cv_prof_pre1_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY'; -- 予備1_ダミー値
  cv_prof_pre2_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY'; -- 予備2_ダミー値
  cv_prof_detail_type_tax    CONSTANT VARCHAR2(40)  := 'XXCOK1_OIF_DETAIL_TYPE_TAX';     -- OIF明細タイプ_税金
  -- プロファイル：勘定科目
  cv_prof_acct_sell_fee      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_SELL_FEE';           -- 販売手数料(問屋)
  cv_prof_acct_sell_support  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_SELL_SUPPORT';       -- 販売協賛金(問屋)
  cv_prof_acct_payable       CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYABLE';            -- 未払金
  cv_prof_acct_excise_tax    CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX'; -- 仮払消費税等
  -- プロファイル：補助科目
  cv_prof_asst_sell_fee      CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SELL_FEE';           -- 販売手数料(問屋)_問屋条件
  cv_prof_asst_sell_support  CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SELL_SUPPORT';       -- 販売協賛金(問屋)_拡売費
  cv_prof_asst_dummy         CONSTANT VARCHAR2(40)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';      -- ダミー値
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- CSVファイル出力用
  cv_lookup_type_ap_column   CONSTANT VARCHAR2(40)  := 'XXCOK1_AP_IF_COLUMN_NAME'; -- APIF項目名(クイックコード参照)
  cv_csv_part                CONSTANT VARCHAR2(3)   := ',';                        -- 区切り用カンマ
  -- 出力区分
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                      -- 出力区分：'LOG'
  -- 数値(改行の指定に使用)
  cn_number_0                CONSTANT NUMBER        := 0;                          -- メッセージ出力後改行なし
  cn_number_1                CONSTANT NUMBER        := 1;                          -- メッセージ出力後空白行1行追加
  -- AP請求書OIF登録用
  cv_invoice_type_standard   CONSTANT VARCHAR(30)   := 'STANDARD';          -- 取引タイプ：標準
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama DEL START
--  cn_slip_input_user         CONSTANT NUMBER        := fnd_global.user_id;  -- ログイン情報：ユーザID
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama DEL END
  -- AP連携ステータス
  cv_payment_uncooperate     CONSTANT VARCHAR2(1)   := '0';                 -- 未連携(問屋支払テーブル)
  cv_payment_cooperate       CONSTANT VARCHAR2(1)   := '1';                 -- 連携済(問屋支払テーブル)
  cv_bill_cooperate          CONSTANT VARCHAR2(1)   := 'P';                 -- 連携済(問屋請求書明細テーブル)
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  -- カウンタ
  gn_target_cnt              NUMBER       DEFAULT 0;      -- 対象件数
  gn_normal_cnt              NUMBER       DEFAULT 0;      -- 正常件数
  gn_skip_cnt                NUMBER       DEFAULT 0;      -- 警告件数(スキップ件数)
  gn_error_cnt               NUMBER       DEFAULT 0;      -- エラー件数
  gn_detail_num              NUMBER       DEFAULT 1;      -- OIFヘッダー内明細連番(ヘッダー毎にリセット)
  gn_sell_detail_num         NUMBER       DEFAULT 0;      -- 問屋支払テーブルで取得した明細用データの件数
  -- 初期処理(A-1) 取得データ格納
  gv_prof_books_id           VARCHAR2(40) DEFAULT NULL;   -- プロファイル：会計帳簿ID
  gv_prof_org_id             VARCHAR2(40) DEFAULT NULL;   -- プロファイル：組織ID
  gv_prof_company_code       VARCHAR2(50) DEFAULT NULL;   -- プロファイル：会社コード
  gv_prof_dept_act           VARCHAR2(50) DEFAULT NULL;   -- プロファイル：部門コード_業務管理部
  gv_prof_detail_type_item   VARCHAR2(50) DEFAULT NULL;   -- プロファイル：OIF明細タイプ_明細
  gv_prof_invoice_source     VARCHAR2(50) DEFAULT NULL;   -- プロファイル：請求書ソース
  gv_prof_pay_group          VARCHAR2(50) DEFAULT NULL;   -- プロファイル：支払グループ
  gv_prof_invoice_tax_code   VARCHAR2(50) DEFAULT NULL;   -- プロファイル：請求書税コード
  gv_prof_dept_fin           VARCHAR2(50) DEFAULT NULL;   -- プロファイル：部門コード_財務経理部
  gv_prof_customer_dummy     VARCHAR2(50) DEFAULT NULL;   -- プロファイル：顧客コード_ダミー値
  gv_prof_company_dummy      VARCHAR2(50) DEFAULT NULL;   -- プロファイル：企業コード_ダミー値
  gv_prof_pre1_dummy         VARCHAR2(50) DEFAULT NULL;   -- プロファイル：予備1_ダミー値
  gv_prof_pre2_dummy         VARCHAR2(50) DEFAULT NULL;   -- プロファイル：予備2_ダミー値
  gv_prof_detail_type_tax    VARCHAR2(50) DEFAULT NULL;   -- プロファイル：OIF明細タイプ_税金
  gv_prof_acct_sell_fee      VARCHAR2(50) DEFAULT NULL;   -- プロファイル：販売手数料(問屋)
  gv_prof_acct_sell_support  VARCHAR2(50) DEFAULT NULL;   -- プロファイル：販売協賛金(問屋)
  gv_prof_acct_payable       VARCHAR2(50) DEFAULT NULL;   -- プロファイル：未払金
  gv_prof_acct_excise_tax    VARCHAR2(50) DEFAULT NULL;   -- プロファイル：仮払消費税等
  gv_prof_asst_sell_fee      VARCHAR2(50) DEFAULT NULL;   -- プロファイル：販売手数料(問屋)_問屋条件
  gv_prof_asst_sell_support  VARCHAR2(50) DEFAULT NULL;   -- プロファイル：販売協賛金(問屋)_拡売費
  gv_prof_asst_dummy         VARCHAR2(50) DEFAULT NULL;   -- プロファイル：ダミー値
  gd_prof_process_date       DATE         DEFAULT NULL;   -- 業務日付格納
  gn_tax_rate                NUMBER       DEFAULT NULL;   -- 税率
  gn_payment_ccid            NUMBER       DEFAULT NULL;   -- 負債勘定科目CCID
  gn_tax_ccid                NUMBER       DEFAULT NULL;   -- 仮払消費税科目CCID
  -- AP請求書OIFヘッダー登録金額
  gn_header_amt              NUMBER       DEFAULT 0;
  -- 出力ファイル初回フラグ
  gb_outfile_first_flag      BOOLEAN      DEFAULT TRUE;
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD START
  gt_employee_number         per_all_people_f.employee_number%TYPE;  -- 従業員番号
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD END
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  -- 問屋支払情報取得カーソル
  CURSOR g_sell_haeder_cur(
    in_org_id    IN  NUMBER                                    -- 営業単位ID(組織ID)
  , id_proc_date IN  DATE                                      -- 業務処理日付
  )
  IS
    SELECT xwp.expect_payment_date AS expect_payment_date      -- 支払予定日
         , xwp.selling_month       AS selling_month            -- 売上対象年月
         , xwp.supplier_code       AS supplier_code            -- 仕入先コード
         , SUM( xwp.payment_amt )  AS payment_amt              -- 支払金額(税抜)(集計)
         , pvsa.vendor_site_code   AS vendor_site_code         -- 仕入先サイトコード
         , xwp.base_code           AS base_code                -- 拠点コード
    FROM   xxcok_wholesale_payment    xwp                      -- 問屋支払テーブル
         , po_vendors                 pv                       -- 仕入先マスタ
         , po_vendor_sites_all        pvsa                     -- 仕入先サイトマスタ
    WHERE  xwp.ap_interface_status = cv_payment_uncooperate    -- APインターフェース連携状況：'0'未連携
    AND    pv.vendor_id            = pvsa.vendor_id
    AND    pv.segment1             = xwp.supplier_code
    AND    pvsa.org_id             = in_org_id                 -- 営業単位ID = A-1.で取得した組織ID
    AND ( 
           ( pvsa.inactive_date    > id_proc_date )            -- 無効日 > 業務処理日付 OR 無効日 IS NULL
      OR   ( pvsa.inactive_date    IS NULL )
    )
    GROUP BY
           xwp.expect_payment_date         -- 支払予定日
         , xwp.selling_month               -- 売上対象年月
         , xwp.supplier_code               -- 仕入先コード
         , pvsa.vendor_site_code           -- 仕入先サイトコード
         , xwp.base_code                   -- 拠点コード
  ;
  -- 問屋請求書明細情報取得カーソル
  CURSOR g_sell_detail_cur(
    id_payment_date   IN DATE                                  -- 支払予定日
  , iv_selling_month  IN VARCHAR2                              -- 売上対象年月
  , iv_supplier_code  IN VARCHAR2                              -- 仕入先コード
  , iv_base_code      IN VARCHAR2                              -- 拠点コード
  )
  IS
    SELECT xwp.cust_code                                                      AS cust_code           -- 顧客コード
         , xwp.sales_outlets_code                                             AS sales_outlets_code  -- 問屋帳合先コード
         , xwp.acct_code                                                      AS acct_code           -- 勘定科目コード
         , xwp.sub_acct_code                                                  AS sub_acct_code       -- 補助科目コード
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi REPAIR START
--         , SUM( NVL( xwp.misc_acct_amt, 0 ) )                                 AS misc_acct_amt       -- その他金額(集計)
--         , SUM( NVL( xwp.backmargin, 0 ) * NVL( xwp.payment_qty, 0 ) )        AS backmargin          -- 販売手数料(集計)
--         , SUM( NVL( xwp.sales_support_amt, 0 ) * NVL( xwp.payment_qty, 0 ) ) AS sales_support_amt   -- 販売協賛金(集計)
         , SUM( NVL( TRUNC( xwp.misc_acct_amt ), 0 ) )                        AS misc_acct_amt       -- その他金額(集計)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 0
               ELSE
                 xwp.payment_amt - TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS backmargin          -- 販売手数料(集計)
         , SUM(
             CASE
               WHEN NVL( TRUNC( xwp.misc_acct_amt ), 0 ) <> 0 THEN
                 0
               WHEN NVL( xwp.sales_support_amt, 0 ) = 0 THEN
                 0
               WHEN NVL( xwp.backmargin, 0 ) = 0 THEN
                 NVL( xwp.payment_amt, 0 )
               ELSE
                 TRUNC( xwp.sales_support_amt * NVL( xwp.payment_qty, 0 ) )
             END
           )                                                                  AS sales_support_amt   -- 販売協賛金(集計)
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi REPAIR END
    FROM   xxcok_wholesale_payment         xwp       -- 問屋支払テーブル
    WHERE  xwp.expect_payment_date = id_payment_date
    AND    xwp.selling_month       = iv_selling_month
    AND    xwp.supplier_code       = iv_supplier_code
    AND    xwp.base_code           = iv_base_code
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD START
    AND    xwp.ap_interface_status = cv_payment_uncooperate    -- APインターフェース連携状況：'0'未連携
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD END
    GROUP BY 
           xwp.cust_code                               -- 顧客コード
         , xwp.sales_outlets_code                      -- 問屋帳合先コード
         , xwp.acct_code                               -- 勘定科目コード
         , xwp.sub_acct_code                           -- 補助科目コード
  ;
  -- ===============================================
  -- グローバルカーソルテーブルタイプ
  -- ===============================================
  -- 問屋支払取得結果格納テーブル型
  TYPE g_sell_header_ttype IS TABLE OF g_sell_haeder_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- 問屋請求書明細取得結果格納テーブル型
  TYPE g_sell_detail_ttype IS TABLE OF g_sell_detail_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================================
  -- グローバル例外
  -- ===============================================
  global_api_expt           EXCEPTION;                 -- 共通関数例外
  global_api_others_expt    EXCEPTION;                 -- 共通関数OTHERS例外
  global_lock_fail_expt     EXCEPTION;                 -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_fail_expt, -54 );
--
  /************************************************************************
   * Procedure Name  : create_csv
   * Description     : データファイル出力(A-8)
   ************************************************************************/
  PROCEDURE create_csv(
    ov_errbuf        OUT  VARCHAR2                   -- エラー・メッセージ
  , ov_retcode       OUT  VARCHAR2                   -- リターン・コード
  , ov_errmsg        OUT  VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_haed_data_rec IN   g_sell_haeder_cur%ROWTYPE  -- AP請求書OIFヘッダー情報
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'create_csv';           -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lv_payment_date        VARCHAR2(20)   DEFAULT NULL;             -- 文字列変換後日付格納
    ln_payment_amt         NUMBER         DEFAULT NULL;             -- 支払金額(税込)
    lv_csv_line            VARCHAR2(5000) DEFAULT NULL;             -- CSV出力文字列(1行分)
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 項目名取得カーソル
    CURSOR get_column_name_cur
    IS
      SELECT xlvv.meaning       AS column_name              -- ミーニング(項目名)
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_lookup_type_ap_column    -- クイックコード：APIF項目名
      ORDER BY
             TO_NUMBER( xlvv.lookup_code )                  -- ルックアップコード(出力番号)
    ;
    -- 出力内容取得カーソル
    CURSOR get_csv_data_cur(
      id_payment_date   IN DATE                                  -- 支払予定日
    , iv_selling_month  IN VARCHAR2                              -- 売上対象年月
    , iv_supplier_code  IN VARCHAR2                              -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN VARCHAR2                              -- 拠点
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
    )
    IS
      SELECT xwp.expect_payment_date  AS expect_payment_date     -- 支払予定日
           , xwp.supplier_code        AS supplier_code           -- 仕入先コード
           , xwp.bill_no              AS bill_no                 -- 請求書No
           , xwp.base_code            AS base_code               -- 拠点コード
           , hca_base.account_name    AS base_name               -- 拠点名
           , xwp.cust_code            AS cust_code               -- 顧客コード
           , hca_cust.account_name    AS cust_name               -- 顧客名
           , xwp.sales_outlets_code   AS sales_outlets_code      -- 問屋帳合先コード
           , hca_sale.account_name    AS sales_outlets_name      -- 問屋帳合先名称
           , xwp.acct_code            AS acct_code               -- 勘定科目コード
           , xav.description          AS acct_name               -- 勘定科目名称
           , xwp.sub_acct_code        AS sub_acct_code           -- 補助科目コード
           , xsav.description         AS sub_acct_name           -- 補助科目名称
           , SUM( xwp.payment_amt )   AS payment_amt             -- 支払金額(税抜)(集計)
      FROM   xxcok_wholesale_payment  xwp                        -- 問屋支払テーブル
           , hz_cust_accounts         hca_base                   -- 顧客コード(拠点)
           , hz_cust_accounts         hca_cust                   -- 顧客コード(顧客)
           , hz_cust_accounts         hca_sale                   -- 顧客コード(帳合先コード)
           , xx03_accounts_v          xav                        -- AFF勘定科目
           , xx03_sub_accounts_v      xsav                       -- AFF補助科目
      WHERE  xwp.expect_payment_date  = id_payment_date
      AND    xwp.selling_month        = iv_selling_month
      AND    xwp.supplier_code        = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
      AND    xwp.base_code            = iv_base_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
      AND    xwp.request_id           = cn_request_id
      AND    xwp.ap_interface_status  = cv_payment_cooperate     -- AP連携フラグ：'1'連携済
      AND    xwp.base_code            = hca_base.account_number
      AND    xwp.cust_code            = hca_cust.account_number
      AND    xwp.sales_outlets_code   = hca_sale.account_number(+)
      AND    xwp.acct_code            = xav.flex_value(+)
      AND    xwp.sub_acct_code        = xsav.flex_value(+)
      GROUP BY
             xwp.expect_payment_date                             -- 支払予定日
           , xwp.supplier_code                                   -- 仕入先コード
           , xwp.bill_no                                         -- 請求書No
           , xwp.base_code                                       -- 拠点コード
           , hca_base.account_name                               -- 拠点名
           , xwp.cust_code                                       -- 顧客コード
           , hca_cust.account_name                               -- 顧客名
           , xwp.sales_outlets_code                              -- 問屋帳合先コード
           , hca_sale.account_name                               -- 問屋帳合先名称
           , xwp.acct_code                                       -- 勘定科目コード
           , xav.description                                     -- 勘定科目名称
           , xwp.sub_acct_code                                   -- 補助科目コード
           , xsav.description                                    -- 補助科目名称      
      ORDER BY
             xwp.expect_payment_date                             -- 支払予定日
           , xwp.supplier_code                                   -- 仕入先コード
           , xwp.bill_no                                         -- 請求書No
           , xwp.base_code                                       -- 拠点コード
           , xwp.cust_code                                       -- 顧客コード
           , xwp.sales_outlets_code                              -- 問屋帳合先コード
           , xwp.acct_code                                       -- 勘定科目コード
           , xwp.sub_acct_code                                   -- 補助科目コード
      ;
--
    -- ===============================================
    -- ローカルテーブル型
    -- ===============================================
    TYPE l_column_name_ttype IS TABLE OF get_column_name_cur%ROWTYPE
    INDEX BY BINARY_INTEGER;
    TYPE l_cdv_data_ttype IS TABLE OF get_csv_data_cur%ROWTYPE
    INDEX BY BINARY_INTEGER;
    -- ===============================================
    -- ローカルテーブル型変数
    -- ===============================================
    lt_column_name_tab     l_column_name_ttype;             -- CSV出力項目名称格納
    lt_csv_data_tab        l_cdv_data_ttype;                -- CSV出力データ格納
    lv_step                VARCHAR2(100);
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 出力項目名称を出力
    -- ===============================================
    IF ( gb_outfile_first_flag = TRUE ) THEN
      -- クイックコードから項目名称を取得
      OPEN get_column_name_cur;
      FETCH get_column_name_cur BULK COLLECT INTO lt_column_name_tab;
      CLOSE get_column_name_cur;
      -- CSVファイルに書き込み
      <<output_csv_column_loop>>
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR START
--      FOR i IN lt_column_name_tab.FIRST .. lt_column_name_tab.LAST LOOP
      FOR i IN 1 .. lt_column_name_tab.COUNT LOOP
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR END
        -- 出力行作成
        IF ( i != lt_column_name_tab.COUNT ) THEN
          lv_csv_line := lv_csv_line || lt_column_name_tab( i ).column_name || ',';
        ELSE
          lv_csv_line := lv_csv_line || lt_column_name_tab( i ).column_name;
        END IF;
      END LOOP output_csv_column_loop;
      -- ファイル出力
      FND_FILE.PUT_LINE(
        FND_FILE.OUTPUT
      , lv_csv_line
      );
      -- 初回フラグにFALSEを代入。
      gb_outfile_first_flag := FALSE;
    END IF;
    -- ===============================================
    -- 対象データファイル出力
    -- ===============================================
    -- 対象データ取得
    OPEN get_csv_data_cur(
           id_payment_date   => ir_haed_data_rec.expect_payment_date      -- 支払予定日
         , iv_selling_month  => ir_haed_data_rec.selling_month            -- 売上対象年月
         , iv_supplier_code  => ir_haed_data_rec.supplier_code            -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
         , iv_base_code      => ir_haed_data_rec.base_code                -- 拠点コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
         );
    FETCH get_csv_data_cur BULK COLLECT INTO lt_csv_data_tab;
    CLOSE get_csv_data_cur;
    -- CSVファイルに書き込み
    <<output_csv_data_loop>>
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR START
--    FOR j IN lt_csv_data_tab.FIRST .. lt_csv_data_tab.LAST LOOP
    FOR j IN 1 .. lt_csv_data_tab.COUNT LOOP
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR END
      -- 支払予定日を文字列に変更
      lv_payment_date := TO_CHAR( lt_csv_data_tab( j ).expect_payment_date , 'YYYY/MM/DD' );
      -- 支払金額(税抜)に税を加算
      ln_payment_amt  := lt_csv_data_tab( j ).payment_amt + ( lt_csv_data_tab( j ).payment_amt * gn_tax_rate );
      -- 出力行作成
      lv_step := 'STEP1';
      lv_csv_line := lv_payment_date || ',';                                         -- 支払予定日
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).supplier_code || ',';       -- 仕入先コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).bill_no || ',';             -- 請求書番号
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).base_code || ',';           -- 拠点コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).base_name || ',';           -- 拠点名称
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).cust_code || ',';           -- 顧客コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).cust_name || ',';           -- 顧客名称
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sales_outlets_code || ',';  -- 問屋帳合先コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sales_outlets_name || ',';  -- 問屋帳合先コード名称
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).acct_code || ',';           -- 勘定科目コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).acct_name || ',';           -- 勘定科目名称
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sub_acct_code || ',';       -- 補助科目コード
      lv_csv_line := lv_csv_line || lt_csv_data_tab( j ).sub_acct_name || ',';       -- 補助科目名称
      lv_csv_line := lv_csv_line || TO_CHAR( ln_payment_amt );                       -- 支払金額(税込)
      -- ファイル出力
      FND_FILE.PUT_LINE(
        FND_FILE.OUTPUT
      , lv_csv_line
      );
    END LOOP output_csv_data_loop;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END create_csv;
--
  /************************************************************************
   * Procedure Name  : change_status
   * Description     : 連携ステータス更新(A-7)
   ************************************************************************/
  PROCEDURE change_status(
    ov_errbuf         OUT VARCHAR2                   -- エラー・メッセージ
  , ov_retcode        OUT VARCHAR2                   -- リターン・コード
  , ov_errmsg         OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_head_data_rec  IN  g_sell_haeder_cur%ROWTYPE  -- AP請求書OIFヘッダー情報
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD START
  , iv_invoice_num    IN  VARCHAR2                   -- 請求書番号
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD END
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'change_status';        -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ログ出力時リターンコード
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 問屋請求書明細テーブルのロック確認
    CURSOR wholesale_bill_chk(
      id_payment_date   IN  DATE                   -- 支払予定日
    , iv_selling_month  IN  VARCHAR2               -- 売上対象年月
    , iv_supplier_code  IN  VARCHAR2               -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN  VARCHAR2               -- 拠点コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
    )
    IS
      SELECT 'X'
      FROM   xxcok_wholesale_bill_line        xwbl      -- 問屋請求書明細テーブル
      WHERE  EXISTS (
               SELECT 'X'
               FROM   xxcok_wholesale_payment xwp       -- 問屋支払テーブル
               WHERE  xwp.wholesale_bill_detail_id = xwbl.wholesale_bill_detail_id
               AND    xwp.expect_payment_date      = id_payment_date
               AND    xwp.selling_month            = iv_selling_month
               AND    xwp.supplier_code            = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
               AND    xwp.base_code                = iv_base_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
               AND    xwp.ap_interface_status      = cv_payment_uncooperate  -- AP連携ステータス：'0'未連携
             )
    FOR UPDATE NOWAIT;
    -- 問屋支払テーブルのロック確認
    CURSOR wholesale_payment_chk(
      id_payment_date   IN  DATE                   -- 支払予定日
    , iv_selling_month  IN  VARCHAR2               -- 売上対象年月
    , iv_supplier_code  IN  VARCHAR2               -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
    , iv_base_code      IN  VARCHAR2               -- 拠点コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
    )
    IS
       SELECT 'X'
       FROM   xxcok_wholesale_payment xwp          -- 問屋支払テーブル
       WHERE  xwp.expect_payment_date      = id_payment_date
       AND    xwp.selling_month            = iv_selling_month
       AND    xwp.supplier_code            = iv_supplier_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
       AND    xwp.base_code                = iv_base_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
       AND    xwp.ap_interface_status      = cv_payment_uncooperate          -- AP連携ステータス：'0'未連携
     FOR UPDATE NOWAIT;
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    update_err_expt    EXCEPTION;                 -- ステータス更新エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 問屋請求書明細テーブルのステータス更新
    -- ===============================================
    BEGIN
      -- ロック確認
      OPEN wholesale_bill_chk(
        id_payment_date   => ir_head_data_rec.expect_payment_date  -- 支払予定日
      , iv_selling_month  => ir_head_data_rec.selling_month        -- 売上対象年月
      , iv_supplier_code  => ir_head_data_rec.supplier_code        -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
      , iv_base_code      => ir_head_data_rec.base_code            -- 拠点コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
      );
      -- カーソルクローズ
      CLOSE wholesale_bill_chk;
      -- ステータス更新
      BEGIN
        UPDATE xxcok_wholesale_bill_line xwbl                           -- 問屋請求書明細テーブル
        SET    xwbl.status            = cv_bill_cooperate               -- ステータス：更新済
             , xwbl.last_updated_by        = cn_last_updated_by         -- 最終更新者
             , xwbl.last_update_date       = SYSDATE                    -- 最終更新日
             , xwbl.last_update_login      = cn_last_update_login       -- 最終ログインID
             , xwbl.request_id             = cn_request_id              -- リクエストID
             , xwbl.program_application_id = cn_program_application_id  -- プログラムアプリケーションID
             , xwbl.program_id             = cn_program_id              -- プログラムID
             , xwbl.program_update_date    = SYSDATE                    -- プログラム最終更新日
        WHERE  EXISTS (
                 SELECT 'X'
                 FROM   xxcok_wholesale_payment        xwp                                -- 問屋支払テーブル
                 WHERE  xwp.wholesale_bill_detail_id = xwbl.wholesale_bill_detail_id      -- 問屋請求明細ID
                 AND    xwp.expect_payment_date      = ir_head_data_rec.expect_payment_date
                 AND    xwp.selling_month            = ir_head_data_rec.selling_month
                 AND    xwp.supplier_code            = ir_head_data_rec.supplier_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
                 AND    xwp.base_code                = ir_head_data_rec.base_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
                 AND    xwp.ap_interface_status      = cv_payment_uncooperate             -- AP連携ステータス：未連携
               );
      EXCEPTION
        -- *** 更新時エラー ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10196
                        , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- 支払先コード
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                        , iv_token_value4 => ir_head_data_rec.base_code
                        );
          -- 更新に失敗した場合、ステータスをエラーにして返す。
          lv_retcode := cv_status_error;
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
          RAISE update_err_expt;
      END;
--
    EXCEPTION
      -- *** ロック取得エラー ***
      WHEN global_lock_fail_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10195
                      , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- 支払先コード
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- ロックエラーの場合、警告を返す。
        lv_retcode := cv_status_warn;
        lv_errbuf  := NULL;
        RAISE update_err_expt;
    END;
    -- ===============================================
    -- 問屋支払テーブルのステータス更新
    -- ===============================================
    BEGIN
      -- ロック確認
      OPEN wholesale_payment_chk(
        id_payment_date   => ir_head_data_rec.expect_payment_date  -- 支払予定日
      , iv_selling_month  => ir_head_data_rec.selling_month        -- 売上対象年月
      , iv_supplier_code  => ir_head_data_rec.supplier_code        -- 仕入先コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
      , iv_base_code      => ir_head_data_rec.base_code            -- 拠点コード
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
      );
      -- カーソルクローズ
      CLOSE wholesale_payment_chk;
      -- ステータス更新
      BEGIN
        UPDATE xxcok_wholesale_payment                                     -- 問屋支払テーブル
        SET    ap_interface_status    = cv_payment_cooperate               -- AP連携ステータス：更新済
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD START
             , invoice_num            = iv_invoice_num                     -- 請求書番号
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD END
             , last_updated_by        = cn_last_updated_by                 -- 最終更新者
             , last_update_date       = SYSDATE                            -- 最終更新日
             , last_update_login      = cn_last_update_login               -- 最終ログインID
             , request_id             = cn_request_id                      -- リクエストID
             , program_application_id = cn_program_application_id          -- プログラムアプリケーションID
             , program_id             = cn_program_id                      -- プログラムID
             , program_update_date    = SYSDATE                            -- プログラム最終更新日
        WHERE  expect_payment_date    = ir_head_data_rec.expect_payment_date
        AND    selling_month          = ir_head_data_rec.selling_month
        AND    supplier_code          = ir_head_data_rec.supplier_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD START
        AND    base_code              = ir_head_data_rec.base_code
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi ADD END
        AND    ap_interface_status    = cv_payment_uncooperate;            -- AP連携ステータス：未連携
--
      EXCEPTION
        -- *** 更新時エラー ***
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10198
                        , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- 仕入先コード
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                        , iv_token_value4 => ir_head_data_rec.base_code
                        );
          -- 更新に失敗した場合、ステータスをエラーにして返す。
          lv_retcode := cv_status_error;
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
          RAISE update_err_expt;
      END;
--
    EXCEPTION
      -- *** ロック取得エラー ***
      WHEN global_lock_fail_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10197
                      , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                      , iv_token_value1 => TO_CHAR( TRUNC( ir_head_data_rec.expect_payment_date ), 'YYYY/MM/DD')
                      , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- 仕入先コード
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- ロックエラーの場合、警告を返す。
        lv_retcode := cv_status_warn;
        lv_errbuf  := NULL;
        RAISE update_err_expt;
    END;
--
  EXCEPTION
    -- *** ステータス更新エラー ***
    WHEN update_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END change_status;
--
  /************************************************************************
   * Procedure Name  : amount_chk
   * Description     : 金額チェック(A-6)
   ************************************************************************/
  PROCEDURE amount_chk(
    ov_errbuf        OUT VARCHAR2                   -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2                   -- リターン・コード
  , ov_errmsg        OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_head_data_rec IN  g_sell_haeder_cur%ROWTYPE  -- AP請求書OIFヘッダー
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'amount_chk';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;
    ln_current_seq         NUMBER         DEFAULT NULL;             -- シーケンス現在値取得
    ln_get_row             NUMBER         DEFAULT NULL;             -- ROWNUM取得用
    -- ===============================================
    -- ローカル例外
    -- ===============================================
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 現在のシーケンスを取得
    -- ===============================================
    SELECT ap_invoices_interface_s.CURRVAL  -- 直前に作成したヘッダーID
    INTO   ln_current_seq
    FROM   dual;
    -- ===============================================
    -- 金額チェック
    -- ===============================================
    BEGIN
      SELECT ROWNUM
      INTO   ln_get_row
      FROM   (
               SELECT SUM( aili.amount )       AS amount  -- 明細金額合計
               FROM   ap_invoice_lines_interface  aili    -- AP請求書明細OIFテーブル
               WHERE  aili.invoice_id = ln_current_seq    -- 直前に作成したヘッダーID
             ) detail_amount
      WHERE  detail_amount.amount = gn_header_amt;     -- 支払金額
--
    EXCEPTION
      -- *** データが取得されない場合 ***
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10194
                      , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                    -- 仕入先コード
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        -- リターンコードを警告にして返す。
        ov_retcode := cv_status_warn;
        ov_errbuf  := NULL;
        ov_errmsg  := lv_errmsg;
    END;
-- 
  EXCEPTION
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END amount_chk;
--
  /************************************************************************
   * Procedure Name  : create_detail_tax
   * Description     : AP請求書明細OIF登録(A-5) 消費税レコード挿入
   ************************************************************************/
  PROCEDURE create_detail_tax(
    ov_errbuf          OUT VARCHAR2                   -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2                   -- リターン・コード
  , ov_errmsg          OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_head_data_rec   IN  g_sell_haeder_cur%ROWTYPE  -- AP請求書OIFヘッダー情報
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'create_detail_tax';    -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    -- 消費税
    ln_tax                 NUMBER         DEFAULT 0;
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    create_data_err_expt   EXCEPTION;                               -- データ作成エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 税金計算(端数切捨て)
    -- ===============================================
    ln_tax := TRUNC(
                ir_head_data_rec.payment_amt * gn_tax_rate
              , 0
              );
    -- ===============================================
    -- 消費税挿入
    -- ===============================================
    BEGIN
      INSERT INTO ap_invoice_lines_interface (
        invoice_id                            -- 請求書ID
      , invoice_line_id                       -- 請求書明細ID
      , line_number                           -- 明細行番号
      , line_type_lookup_code                 -- 明細タイプ
      , amount                                -- 明細金額
      , tax_code                              -- 税区分
      , dist_code_combination_id              -- CCID
      , last_updated_by                       -- 最終更新者
      , last_update_date                      -- 最終更新日
      , last_update_login                     -- 最終ログインID
      , created_by                            -- 作成者
      , creation_date                         -- 作成日
      , attribute_category                    -- DFFコンテキスト
      , org_id                                -- 組織ID
      )
      VALUES (
        ap_invoices_interface_s.CURRVAL       -- 直前に作成したAP請求書OIFヘッダーの請求ID
      , ap_invoice_lines_interface_s.NEXTVAL  -- AP請求書OIF明細の一意ID
      , gn_detail_num                         -- ヘッダー内での連番
      , gv_prof_detail_type_tax               -- 明細タイプ：税金
      , ln_tax                                -- 金額：税金
      , gv_prof_invoice_tax_code              -- 請求書税コード
      , gn_tax_ccid                           -- 仮払消費税CCID
      , cn_last_updated_by                    -- 最終更新者
      , SYSDATE                               -- 最終更新日
      , cn_last_update_login                  -- 最終ログインID
      , cn_created_by                         -- 作成者
      , SYSDATE                               -- 作成日
      , gv_prof_org_id                        -- DFFコンテキスト：組織ID
      , TO_NUMBER( gv_prof_org_id )           -- 組織ID
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_10407
                      , iv_token_name1  => cv_token_payment_date                     -- 支払予定日
                      , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                      , iv_token_name2  => cv_token_sales_month                      -- 売上対象年月
                      , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                      , iv_token_name3  => cv_token_vender_code                      -- 支払先コード
                      , iv_token_value3 => ir_head_data_rec.supplier_code
                      , iv_token_name4  => cv_token_base_code                        -- 拠点コード
                      , iv_token_value4 => ir_head_data_rec.base_code
                      );
        RAISE create_data_err_expt;
    END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      gn_detail_num := gn_detail_num + 1;
--
  EXCEPTION
    -- *** データ作成エラー ***
    WHEN create_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_detail_tax;
--
  /************************************************************************
   * Procedure Name  : create_detail_data
   * Description     : AP請求書明細OIF(A-5) 税以外
   ************************************************************************/
  PROCEDURE create_detail_data(
    ov_errbuf          OUT VARCHAR2                   -- エラー・メッセージ
  , ov_retcode         OUT VARCHAR2                   -- リターン・コード
  , ov_errmsg          OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_detail_data_rec IN  g_sell_detail_cur%ROWTYPE  -- AP請求書OIF明細情報
  , ir_head_data_rec   IN  g_sell_haeder_cur%ROWTYPE  -- AP請求書OIFヘッダー情報
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'create_detail_data';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ログファイル出力時リターンコード
    lv_company_code        VARCHAR2(20)   DEFAULT NULL;             -- 企業コード
    ln_backmargin_ccid     NUMBER         DEFAULT NULL;             -- 販売手数料CCID
    ln_support_amt_ccid    NUMBER         DEFAULT NULL;             -- 販売協賛金CCID
    ln_misc_acct_amt_ccid  NUMBER         DEFAULT NULL;             -- その他科目CCID
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    create_data_err_expt   EXCEPTION;                               -- データ作成エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 企業コード作成(取得した企業コードがNULLの場合、ダミーを入れる)
    -- ===============================================
    lv_company_code := NVL(
                         xxcok_common_pkg.get_companies_code_f(
                           ir_detail_data_rec.sales_outlets_code
                         )
                       , gv_prof_company_dummy 
                       );
    -- ===============================================
    -- 「販売手数料」明細作成
    -- ===============================================
    IF ( ir_detail_data_rec.backmargin <> 0 ) THEN
      -- 販売手数料CCID取得
      ln_backmargin_ccid := xxcok_common_pkg.get_code_combination_id_f(
                              id_proc_date => gd_prof_process_date         -- 処理日
                            , iv_segment1  => gv_prof_company_code         -- 会社コード
                            , iv_segment2  => ir_head_data_rec.base_code   -- 部門コード
                            , iv_segment3  => gv_prof_acct_sell_fee        -- 勘定科目コード
                            , iv_segment4  => gv_prof_asst_sell_fee        -- 補助科目コード
                            , iv_segment5  => ir_detail_data_rec.cust_code -- 顧客コード
                            , iv_segment6  => lv_company_code              -- 企業コード
                            , iv_segment7  => gv_prof_pre1_dummy           -- 予備１コード
                            , iv_segment8  => gv_prof_pre2_dummy           -- 予備２コード
                            );
      IF ( ln_backmargin_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- 「販売手数料」挿入
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- 請求書ID
        , invoice_line_id                                   -- 請求書明細ID
        , line_number                                       -- 明細行番号
        , line_type_lookup_code                             -- 明細タイプ
        , amount                                            -- 明細金額
        , tax_code                                          -- 税区分
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終ログインID
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , attribute_category                                -- DFFコンテキスト
        , org_id                                            -- 組織ID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
        , gn_detail_num                                     -- ヘッダー内での連番
        , gv_prof_detail_type_item                          -- 明細タイプ：明細
        , ir_detail_data_rec.backmargin                     -- 金額：販売手数料
        , gv_prof_invoice_tax_code                          -- 請求書税コード
        , ln_backmargin_ccid                                -- 販売手数料CCID
        , cn_last_updated_by                                -- 最終更新者
        , SYSDATE                                           -- 最終更新日
        , cn_last_update_login                              -- 最終ログインID
        , cn_created_by                                     -- 作成者
        , SYSDATE                                           -- 作成日
        , gv_prof_org_id                                    -- DFFコンテキスト：組織ID
        , TO_NUMBER( gv_prof_org_id )                       -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10191
                        , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- 支払先コード
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- 顧客コード
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- 問屋帳合先コード
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                        );
          RAISE create_data_err_expt;
      END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      gn_detail_num := gn_detail_num + 1;
    END IF;
    -- ===============================================
    -- 「販売協賛金」明細作成
    -- ===============================================
    IF ( ir_detail_data_rec.sales_support_amt <> 0 ) THEN
      -- 販売協賛金CCID取得
      ln_support_amt_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_prof_process_date             -- 処理日
                             , iv_segment1  => gv_prof_company_code             -- 会社コード
                             , iv_segment2  => ir_head_data_rec.base_code       -- 部門コード
                             , iv_segment3  => gv_prof_acct_sell_support        -- 勘定科目コード(販売協賛金)
                             , iv_segment4  => gv_prof_asst_sell_support        -- 補助科目コード(拡売費)
                             , iv_segment5  => ir_detail_data_rec.cust_code     -- 顧客コード
                             , iv_segment6  => lv_company_code                  -- 企業コード
                             , iv_segment7  => gv_prof_pre1_dummy               -- 予備１コード
                             , iv_segment8  => gv_prof_pre2_dummy               -- 予備２コード
                             );
      IF ( ln_support_amt_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- 「販売協賛金」明細挿入
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- 請求書ID
        , invoice_line_id                                   -- 請求書明細ID
        , line_number                                       -- 明細行番号
        , line_type_lookup_code                             -- 明細タイプ
        , amount                                            -- 明細金額
        , tax_code                                          -- 税区分
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終ログインID
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , attribute_category                                -- DFFコンテキスト
        , org_id                                            -- 組織ID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
        , gn_detail_num                                     -- ヘッダー内での連番
        , gv_prof_detail_type_item                          -- 明細タイプ：明細
        , ir_detail_data_rec.sales_support_amt              -- 金額：販売協賛金
        , gv_prof_invoice_tax_code                          -- 請求書税コード
        , ln_support_amt_ccid                               -- 販売手数料CCID
        , cn_last_updated_by                                -- 最終更新者
        , SYSDATE                                           -- 最終更新日
        , cn_last_update_login                              -- 最終ログインID
        , cn_created_by                                     -- 作成者
        , SYSDATE                                           -- 作成日
        , gv_prof_org_id                                    -- DFFコンテキスト：組織ID
        , TO_NUMBER( gv_prof_org_id )                       -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10192
                        , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- 支払先コード
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- 顧客コード
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- 問屋帳合先コード
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                          );
          RAISE create_data_err_expt;
      END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      gn_detail_num := gn_detail_num + 1;
    END IF;
    -- ===============================================
    -- 「その他科目」明細作成
    -- ===============================================
    IF ( ir_detail_data_rec.misc_acct_amt <> 0 ) THEN
      -- その他科目CCID取得
      ln_misc_acct_amt_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_prof_process_date             -- 処理日
                             , iv_segment1  => gv_prof_company_code             -- 会社コード
                             , iv_segment2  => ir_head_data_rec.base_code       -- 部門コード
                             , iv_segment3  => ir_detail_data_rec.acct_code     -- 勘定科目コード
                             , iv_segment4  => ir_detail_data_rec.sub_acct_code -- 補助科目コード
                             , iv_segment5  => ir_detail_data_rec.cust_code     -- 顧客コード
                             , iv_segment6  => lv_company_code                  -- 企業コード
                             , iv_segment7  => gv_prof_pre1_dummy               -- 予備１コード
                             , iv_segment8  => gv_prof_pre2_dummy               -- 予備２コード
                             );
      IF ( ln_misc_acct_amt_ccid IS NULL ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00034
                      );
        RAISE create_data_err_expt;
      END IF;
      -- ===============================================
      -- 「その他科目」明細挿入
      -- ===============================================
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                          -- 請求書ID
        , invoice_line_id                                     -- 請求書明細ID
        , line_number                                         -- 明細行番号
        , line_type_lookup_code                               -- 明細タイプ
        , amount                                              -- 明細金額
        , tax_code                                            -- 税区分
        , dist_code_combination_id                            -- CCID
        , last_updated_by                                     -- 最終更新者
        , last_update_date                                    -- 最終更新日
        , last_update_login                                   -- 最終ログインID
        , created_by                                          -- 作成者
        , creation_date                                       -- 作成日
        , attribute_category                                  -- DFFコンテキスト
        , org_id                                              -- 組織ID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                     -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL                -- AP請求書OIF明細の一意ID
        , gn_detail_num                                       -- ヘッダー内での連番
        , gv_prof_detail_type_item                            -- 明細タイプ：明細
        , ir_detail_data_rec.misc_acct_amt                    -- 金額：その他金額
        , gv_prof_invoice_tax_code                            -- 請求書税コード
        , ln_misc_acct_amt_ccid                               -- 販売手数料CCID
        , cn_last_updated_by                                  -- 最終更新者
        , SYSDATE                                             -- 最終更新日
        , cn_last_update_login                                -- 最終ログインID
        , cn_created_by                                       -- 作成者
        , SYSDATE                                             -- 作成日
        , gv_prof_org_id                                      -- DFFコンテキスト：組織ID
        , TO_NUMBER( gv_prof_org_id )                         -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10193
                        , iv_token_name1  => cv_token_payment_date                   -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                    -- 支払先コード
                        , iv_token_value3 => ir_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                      -- 拠点コード
                        , iv_token_value4 => ir_head_data_rec.base_code
                        , iv_token_name5  => cv_token_cust_code                      -- 顧客コード
                        , iv_token_value5 => ir_detail_data_rec.cust_code
                        , iv_token_name6  => cv_token_balance_code                   -- 問屋帳合先コード
                        , iv_token_value6 => ir_detail_data_rec.sales_outlets_code
                        , iv_token_name7  => cv_token_acct_code                      -- 勘定科目コード
                        , iv_token_value7 => ir_detail_data_rec.acct_code
                        , iv_token_name8  => cv_token_assist_code                    -- 補助科目コード
                        , iv_token_value8 => ir_detail_data_rec.sub_acct_code
                          );
          RAISE create_data_err_expt;
      END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      gn_detail_num := gn_detail_num + 1;
    END IF;
--
  EXCEPTION
    -- *** データ作成エラー ***
    WHEN create_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_detail_data;
--
  /************************************************************************
   * Procedure Name  : create_oif_data
   * Description     : AP請求書ヘッダーOIF登録(A-3)
   ************************************************************************/
  PROCEDURE create_oif_data(
    ov_errbuf              OUT VARCHAR2                   -- エラー・メッセージ
  , ov_retcode             OUT VARCHAR2                   -- リターン・コード
  , ov_errmsg              OUT VARCHAR2                   -- ユーザー・エラー・メッセージ
  , ir_sell_head_data_rec  IN  g_sell_haeder_cur%ROWTYPE  -- AP請求書OIF作成用データレコード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'create_oif_data';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode                   BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    lv_invoice_num               VARCHAR2(50)   DEFAULT NULL;             -- 請求書番号格納
    ld_selling_month_first_date  DATE           DEFAULT NULL;             -- 売上対象年月の初日
    -- ===============================================
    -- ローカルテーブル型変数
    -- ===============================================
    lt_detail_tab                g_sell_detail_ttype;                     -- 明細取得カーソルレコード型
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    ap_oif_create_expt           EXCEPTION;                               -- ヘッダー登録エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- 明細連番初期化
    gn_detail_num := 1;
    -- ===============================================
    -- セーブポイント設定
    -- ===============================================
    SAVEPOINT before_create_data;
    -- ===============================================
    -- AP請求書OIFヘッダーデータ作成(A-3)
    -- ===============================================
    -- 請求書番号取得
    lv_invoice_num := xxcok_common_pkg.get_slip_number_f(
                        iv_package_name => cv_pkg_name              -- パッケージ名
                      );
    IF ( lv_invoice_num IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10416
                      );
      RAISE ap_oif_create_expt;
    END IF;
    -- 税込み金額を計算 税抜金額＋税抜金額*税率(端数切捨て)
    gn_header_amt := TRUNC(
                       ir_sell_head_data_rec.payment_amt + ir_sell_head_data_rec.payment_amt * gn_tax_rate
                     , 0
                     );
    -- 売上対象年月の初日を取得
    ld_selling_month_first_date := TO_DATE(
                                     ir_sell_head_data_rec.selling_month
                                   , 'YYYYMM'
                                   );
    -- AP請求書OIFヘッダー登録
    BEGIN
      INSERT INTO ap_invoices_interface (
        invoice_id                              -- シーケンス
      , invoice_num                             -- 請求書番号
      , invoice_type_lookup_code                -- 請求書の種類
      , invoice_date                            -- 請求日付
      , vendor_num                              -- 仕入先番号
      , vendor_site_code                        -- 仕入先場所番号
      , invoice_amount                          -- 請求金額
      , description                             -- 摘要
      , last_update_date                        -- 最終更新日
      , last_updated_by                         -- 最終更新者
      , last_update_login                       -- 最終ログインID
      , creation_date                           -- 作成者
      , created_by                              -- 作成日
      , attribute_category                      -- DFFコンテキスト
      , attribute2                              -- 請求書番号
      , attribute3                              -- 起票部門
      , attribute4                              -- 伝票入力者
      , source                                  -- ソース
      , pay_group_lookup_code                   -- 支払グループ
      , gl_date                                 -- 仕訳計上日
      , accts_pay_code_combination_id           -- 負債勘定CCID
      , org_id                                  -- 組織ID
      , terms_date                              -- 支払起算日
      )
      VALUES (
        ap_invoices_interface_s.NEXTVAL         -- AP請求書OIFヘッダー用シーケンス番号(一意)
      , lv_invoice_num                          -- 請求書番号(直前で取得)
      , cv_invoice_type_standard                -- 取引タイプ：標準(固定)
      , gd_prof_process_date                    -- 業務処理日付(initで取得)
      , ir_sell_head_data_rec.supplier_code     -- 仕入先コード()
      , ir_sell_head_data_rec.vendor_site_code  -- 仕入先サイトコード
      , gn_header_amt                           -- 税込み金額
      , gv_prof_invoice_source                  -- 請求書ソース(initで取得)
      , SYSDATE                                 -- 最終更新日
      , cn_last_updated_by                      -- 最終更新者
      , cn_last_update_login                    -- 最終ログインID
      , SYSDATE                                 -- 作成日
      , cn_created_by                           -- 作成者
      , gv_prof_org_id                          -- 組織ID(initで取得)
      , lv_invoice_num                          -- 請求書番号(直前で取得)
      , ir_sell_head_data_rec.base_code         -- 拠点コード
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD START
--      , cn_slip_input_user                      -- 伝票入力者(ログインユーザID)
      , gt_employee_number                      -- 伝票入力者(従業員No)
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD END
      , gv_prof_invoice_source                  -- 請求書ソース(initで取得)
      , gv_prof_pay_group                       -- 支払グループ
      , gd_prof_process_date                    -- 業務処理日付(initで取得)
      , gn_payment_ccid                         -- 負債勘定科目CCID(initで取得)
      , TO_NUMBER( gv_prof_org_id )             -- 組織ID(initで取得)
      , ld_selling_month_first_date             -- 売上対象年月の初日
      );
    EXCEPTION
      WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_10190
                        , iv_token_name1  => cv_token_payment_date                      -- 支払予定日
                        , iv_token_value1 => TO_CHAR( ir_sell_head_data_rec.expect_payment_date , 'YYYY/MM/DD' )
                        , iv_token_name2  => cv_token_sales_month                    -- 売上対象年月
                        , iv_token_value2 => TO_CHAR( TO_DATE( ir_sell_head_data_rec.selling_month, 'YYYY/MM' ), 'YYYY/MM' )
                        , iv_token_name3  => cv_token_vender_code                       -- 支払先コード
                        , iv_token_value3 => ir_sell_head_data_rec.supplier_code
                        , iv_token_name4  => cv_token_base_code                         -- 拠点コード
                        , iv_token_value4 => ir_sell_head_data_rec.base_code
                        );
          RAISE ap_oif_create_expt;
    END;
    -- ===============================================
    -- 問屋支払明細集計抽出(A-4)
    -- ===============================================
    OPEN g_sell_detail_cur(
           id_payment_date   => ir_sell_head_data_rec.expect_payment_date   -- 支払予定日
         , iv_selling_month  => ir_sell_head_data_rec.selling_month         -- 売上対象年月
         , iv_supplier_code  => ir_sell_head_data_rec.supplier_code         -- 仕入先コード
         , iv_base_code      => ir_sell_head_data_rec.base_code             -- 拠点コード
         );
    -- フェッチ
    FETCH g_sell_detail_cur BULK COLLECT INTO lt_detail_tab;
    -- カーソルクローズ
    CLOSE g_sell_detail_cur;
    -- ===============================================
    -- 取得件数を退避して、対象件数に加える。
    -- ===============================================
    gn_sell_detail_num := lt_detail_tab.COUNT;
    -- 対象件数に追加
    gn_target_cnt := gn_target_cnt + gn_sell_detail_num;
    -- ===============================================
    -- AP請求書OIF明細登録(A-5)
    -- ===============================================
    -- 消費税レコードの登録
    create_detail_tax(
      ov_errbuf          => lv_errbuf              -- エラー・メッセージ
    , ov_retcode         => lv_retcode             -- リターン・コード
    , ov_errmsg          => lv_errmsg              -- ユーザー・エラー・メッセージ
    , ir_head_data_rec   => ir_sell_head_data_rec  -- AP請求書OIFヘッダー情報
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ループ開始
    <<ap_oif_detail_loop>>
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR START
--    FOR i IN lt_detail_tab.FIRST .. lt_detail_tab.LAST LOOP
    FOR i IN 1 .. lt_detail_tab.COUNT LOOP
-- 2009/12/09 Ver.1.6 [E_本稼動_00388] SCS K.Yamaguchi REPAIR END
    -- 販売手数料・販売協賛金・その他科目レコードの登録
      create_detail_data(
        ov_errbuf           => lv_errbuf               -- エラー・メッセージ
      , ov_retcode          => lv_retcode              -- リターン・コード
      , ov_errmsg           => lv_errmsg               -- ユーザー・エラー・メッセージ
      , ir_detail_data_rec  => lt_detail_tab( i )      -- AP請求書OIF明細情報
      , ir_head_data_rec    => ir_sell_head_data_rec   -- AP請求書OIFヘッダー情報
      );
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
    END LOOP ap_oif_detail_loop;
    -- ===============================================
    -- 金額チェック(A-6)
    -- ===============================================
    amount_chk(
      ov_errbuf        => lv_errbuf                         -- エラー・メッセージ
    , ov_retcode       => lv_retcode                        -- リターン・コード
    , ov_errmsg        => lv_errmsg                         -- ユーザー・エラー・メッセージ
    , ir_head_data_rec => ir_sell_head_data_rec             -- AP請求書OIFヘッダー情報
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- 連携ステータス更新(A-7)
    -- ===============================================
    change_status(
      ov_errbuf        => lv_errbuf               -- エラー・メッセージ
    , ov_retcode       => lv_retcode              -- リターン・コード
    , ov_errmsg        => lv_errmsg               -- ユーザー・エラー・メッセージ
    , ir_head_data_rec => ir_sell_head_data_rec   -- AP請求書OIFヘッダー情報
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD START
    , iv_invoice_num   => lv_invoice_num          -- 請求書番号
-- 2009/11/25 Ver.1.5 [E_本稼動_00021] SCS K.Yamaguchi ADD END
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- データファイル出力(A-8)
    -- ===============================================
    create_csv(
      ov_errbuf        => lv_errbuf               -- エラー・メッセージ
    , ov_retcode       => lv_retcode              -- リターン・コード
    , ov_errmsg        => lv_errmsg               -- ユーザー・エラー・メッセージ
    , ir_haed_data_rec => ir_sell_head_data_rec   -- AP請求書OIFヘッダー情報
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ヘッダー登録エラー ***
    WHEN ap_oif_create_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      -- セーブポイントまでロールバック
      ROLLBACK TO before_create_data;
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END create_oif_data;
--
  /************************************************************************
   * Procedure Name  : init
   * Description     : 初期処理(A-1)
   ************************************************************************/
  PROCEDURE init(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'init';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    lb_period_chk          BOOLEAN        DEFAULT NULL;             -- 会計期間ステータスチェック用
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    get_data_err_expt      EXCEPTION;                               -- プロファイル取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- コンカレント入力パラメータの表示(入力パラメータなし)
    -- ===============================================
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name
                  , iv_name         => cv_msg_code_90008
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      -- 出力区分
                  , iv_message  => lv_errmsg         -- メッセージ
                  , in_new_line => cn_number_1       -- 改行
                  );
    -- ===============================================
    -- プロファイルの取得
    -- ===============================================
    -- プロファイル：会計帳簿IDの取得
    gv_prof_books_id := FND_PROFILE.VALUE(
                          cv_prof_books_id
                        );
    IF ( gv_prof_books_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_books_id             -- 会計帳簿ID
                    );
      RAISE get_data_err_expt;
    END IF;
    -- プロファイル：組織IDの取得
    gv_prof_org_id := FND_PROFILE.VALUE(
                        cv_prof_org_id
                      );
    IF ( gv_prof_org_id IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_org_id               -- 組織ID
                    );
      RAISE get_data_err_expt;
    END IF;
    -- カスタム・プロファイル：会社コードの取得
    gv_prof_company_code := FND_PROFILE.VALUE(
                              cv_prof_company_code
                            );
    IF ( gv_prof_company_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_company_code         -- 会社コード
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：勘定科目_販売手数料の取得
    gv_prof_acct_sell_fee := FND_PROFILE.VALUE(
                               cv_prof_acct_sell_fee
                             );
    IF ( gv_prof_acct_sell_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_acct_sell_fee        -- 勘定科目_販売手数料
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：勘定科目_販売協賛金の取得
    gv_prof_acct_sell_support := FND_PROFILE.VALUE(
                                   cv_prof_acct_sell_support
                                 );
    IF ( gv_prof_acct_sell_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_acct_sell_support    -- 勘定科目_販売協賛金
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：補助科目_販売手数料_問屋条件の取得
    gv_prof_asst_sell_fee := FND_PROFILE.VALUE(
                               cv_prof_asst_sell_fee
                             );
    IF ( gv_prof_asst_sell_fee IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_asst_sell_fee        -- 補助科目_販売手数料_問屋条件
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：補助科目_販売協賛金_拡売費の取得
    gv_prof_asst_sell_support := FND_PROFILE.VALUE(
                                   cv_prof_asst_sell_support
                                 );
    IF ( gv_prof_asst_sell_support IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_asst_sell_support    -- 補助科目_販売協賛金_拡売費
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：明細タイプ_明細の取得
    gv_prof_detail_type_item := FND_PROFILE.VALUE(
                                  cv_prof_detail_type_item
                                );
    IF ( gv_prof_detail_type_item IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_detail_type_item     -- 明細タイプ_明細
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：請求書ソースの取得
    gv_prof_invoice_source := FND_PROFILE.VALUE(
                                cv_prof_invoice_source
                              );
    IF ( gv_prof_invoice_source IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_invoice_source       -- 請求書ソース
                    );
      RAISE get_data_err_expt;
    END IF;    
-- 2009/10/22 Ver.1.4 [障害E_T4_00070] SCS K.Yamaguchi REPAIR START
--    -- カスタム・プロファイル：支払グループの取得
--    gv_prof_pay_group := FND_PROFILE.VALUE(
--                           cv_prof_pay_group
--                         );
--    IF ( gv_prof_pay_group IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_short_name
--                    , iv_name         => cv_msg_code_00003
--                    , iv_token_name1  => cv_token_profile             -- プロファイル名
--                    , iv_token_value1 => cv_prof_pay_group            -- 支払グループ
--                    );
--      RAISE get_data_err_expt;
--    END IF;    
    gv_prof_pay_group := NULL;
-- 2009/10/22 Ver.1.4 [障害E_T4_00070] SCS K.Yamaguchi REPAIR END
    -- カスタム・プロファイル：勘定科目_未払金の取得
    gv_prof_acct_payable := FND_PROFILE.VALUE(
                              cv_prof_acct_payable
                            );
    IF ( gv_prof_acct_payable IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_acct_payable         -- 勘定科目_未払金
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：請求書税区分の取得
    gv_prof_invoice_tax_code := FND_PROFILE.VALUE(
                                  cv_prof_invoice_tax_code
                                );
    IF ( gv_prof_invoice_tax_code IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_invoice_tax_code     -- 請求書税区分
                    );
      RAISE get_data_err_expt;
    END IF;
    -- カスタム・プロファイル：部門コード_財務経理部の取得
    gv_prof_dept_fin := FND_PROFILE.VALUE(
                          cv_prof_dept_fin
                        );
    IF ( gv_prof_dept_fin IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_dept_fin             -- 部門コード_財務経理部
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：補助科目_ダミー値の取得
    gv_prof_asst_dummy := FND_PROFILE.VALUE(
                            cv_prof_asst_dummy
                          );
    IF ( gv_prof_asst_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_asst_dummy           -- 補助科目_ダミー値
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：顧客コード_ダミー値の取得
    gv_prof_customer_dummy := FND_PROFILE.VALUE(
                                cv_prof_customer_dummy
                              );
    IF ( gv_prof_customer_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_customer_dummy       -- 顧客コード_ダミー値
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：企業コード_ダミー値の取得
    gv_prof_company_dummy := FND_PROFILE.VALUE(
                               cv_prof_company_dummy
                             );
    IF ( gv_prof_company_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_company_dummy        -- 企業コード_ダミー値
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：予備1_ダミー値の取得
    gv_prof_pre1_dummy := FND_PROFILE.VALUE(
                            cv_prof_pre1_dummy
                          );
    IF ( gv_prof_pre1_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_pre1_dummy           -- 予備1_ダミー値
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：予備2_ダミー値の取得
    gv_prof_pre2_dummy := FND_PROFILE.VALUE(
                               cv_prof_pre2_dummy
                             );
    IF ( gv_prof_pre2_dummy IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_pre2_dummy           -- 予備2_ダミー値
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：勘定科目_仮払消費税等の取得
    gv_prof_acct_excise_tax := FND_PROFILE.VALUE(
                                 cv_prof_acct_excise_tax
                               );
    IF ( gv_prof_acct_excise_tax IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_acct_excise_tax      -- 勘定科目_仮払消費税等
                    );
      RAISE get_data_err_expt;
    END IF;    
    -- カスタム・プロファイル：OIF明細タイプ_税金の取得
    gv_prof_detail_type_tax := FND_PROFILE.VALUE(
                                 cv_prof_detail_type_tax
                               );
    IF ( gv_prof_detail_type_tax IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile             -- プロファイル名
                    , iv_token_value1 => cv_prof_detail_type_tax      -- OIF明細タイプ_税金
                    );
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- 業務処理日付の取得
    -- ===============================================
    gd_prof_process_date := xxccp_common_pkg2.get_process_date;
    -- 戻り値がNULLの場合、エラー終了する。
    IF ( gd_prof_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- 会計期間ステータスの確認
    -- ===============================================
    lb_period_chk := xxcok_common_pkg.check_acctg_period_f(
                       in_set_of_books_id         => TO_NUMBER( gv_prof_books_id )   -- 会計帳簿ID
                     , id_proc_date               => gd_prof_process_date            -- 処理日(対象日)
                     , iv_application_short_name  => cv_sqlap_appl_short_name        -- アプリケーション短縮名
                     );
    -- オープン(戻り値がTRUE)以外の場合、エラー終了する。
    IF ( lb_period_chk = FALSE ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00042
                    , iv_token_name1  => cv_token_proc_date           -- 業務処理日付
                    , iv_token_value1 => TO_CHAR( gd_prof_process_date , 'YYYY/MM/DD' )
                    );
                    
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- 消費税率の取得
    -- ===============================================
    BEGIN
      SELECT ( atc.tax_rate / 100 ) AS tax_rate              -- ( 消費税率/100 )
      INTO   gn_tax_rate
      FROM   ap_tax_codes              atc                   -- 税金コード
      WHERE  atc.name            = gv_prof_invoice_tax_code     -- 請求書税コード
      AND    atc.set_of_books_id = TO_NUMBER(gv_prof_books_id)  -- 会計帳簿ID
      AND    atc.enabled_flag    = 'Y'
      AND    atc.start_date     <= TRUNC( gd_prof_process_date )
      AND    NVL( atc.inactive_date , TRUNC( gd_prof_process_date ) ) >= TRUNC( gd_prof_process_date );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00089
                      );
        RAISE get_data_err_expt;
    END;
    -- ===============================================
    -- 負債勘定CCIDの取得
    -- ===============================================
    gn_payment_ccid := xxcok_common_pkg.get_code_combination_id_f(
                         id_proc_date => gd_prof_process_date         -- 処理日
                       , iv_segment1  => gv_prof_company_code         -- 会社コード
                       , iv_segment2  => gv_prof_dept_fin             -- 部門コード
                       , iv_segment3  => gv_prof_acct_payable         -- 勘定科目コード
                       , iv_segment4  => gv_prof_asst_dummy           -- 補助科目コード
                       , iv_segment5  => gv_prof_customer_dummy       -- 顧客コード
                       , iv_segment6  => gv_prof_company_dummy        -- 企業コード
                       , iv_segment7  => gv_prof_pre1_dummy           -- 予備１コード
                       , iv_segment8  => gv_prof_pre2_dummy           -- 予備２コード
                       );
    IF ( gn_payment_ccid IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00034
                    );
      RAISE get_data_err_expt;
    END IF;
    -- ===============================================
    -- 仮払消費税科目CCIDの取得
    -- ===============================================
    gn_tax_ccid := xxcok_common_pkg.get_code_combination_id_f(
                     id_proc_date => gd_prof_process_date         -- 処理日
                   , iv_segment1  => gv_prof_company_code         -- 会社コード
                   , iv_segment2  => gv_prof_dept_fin             -- 部門コード
                   , iv_segment3  => gv_prof_acct_excise_tax      -- 勘定科目コード
                   , iv_segment4  => gv_prof_asst_dummy           -- 補助科目コード
                   , iv_segment5  => gv_prof_customer_dummy       -- 顧客コード
                   , iv_segment6  => gv_prof_company_dummy        -- 企業コード
                   , iv_segment7  => gv_prof_pre1_dummy           -- 予備１コード
                   , iv_segment8  => gv_prof_pre2_dummy           -- 予備２コード
                   );
    IF ( gn_tax_ccid IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00034
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD START
    -- ===============================================
    -- 仕訳伝票入力者の取得
    -- ===============================================
    BEGIN
      SELECT  papf.employee_number AS employee_number     -- 従業員No
        INTO  gt_employee_number
        FROM  fnd_user         fu    -- ユーザーマスタ
            , per_all_people_f papf  -- 従業員マスタ
       WHERE  fu.user_id           = fnd_global.user_id
         AND  papf.person_id       = fu.employee_id
         AND  gd_prof_process_date BETWEEN NVL( TRUNC( papf.effective_start_date ), gd_prof_process_date )
                                       AND NVL( TRUNC( papf.effective_end_date   ), gd_prof_process_date )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl_short_name
                      , iv_name         => cv_msg_code_00005
                      );
        RAISE get_data_err_expt;
    END;
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD END
--
  EXCEPTION
    -- *** 取得データエラー例外 ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END init;
--
  /************************************************************************
   * Procedure Name  : submain
   * Description     : メイン処理プロシージャ
   ************************************************************************/
  PROCEDURE submain(
    ov_errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode       OUT VARCHAR2  -- リターン・コード
  , ov_errmsg        OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'submain';     -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    -- ===============================================
    -- ローカルテーブル型変数
    -- ===============================================
    lt_header_tab          g_sell_header_ttype;                     -- 問屋支払ヘッダー情報取得カーソルレコード型
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    no_oif_data_expt       EXCEPTION;                               -- 該当データ0件例外
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf    => lv_errbuf         -- エラー・メッセージ
    , ov_retcode   => lv_retcode        -- リターン・コード
    , ov_errmsg    => lv_errmsg         -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- 問屋支払ヘッダー集計抽出(A-2)
    -- ===============================================
    OPEN g_sell_haeder_cur(
      in_org_id    => TO_NUMBER( gv_prof_org_id )
    , id_proc_date => gd_prof_process_date
    );
    -- フェッチ
    FETCH g_sell_haeder_cur BULK COLLECT INTO lt_header_tab;
    -- カーソルクローズ
    CLOSE g_sell_haeder_cur;
    -- 取得件数が0件のとき、エラー終了
    IF ( lt_header_tab.COUNT = 0 ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_10189
                    );
      RAISE no_oif_data_expt;
    END IF;
    -- ===============================================
    -- AP請求書OIF登録(A-3, A-4, A-5, A-6, A-7, A-8)
    -- ===============================================
    -- ループ処理
    <<ap_oif_header_loop>>
    FOR i IN lt_header_tab.FIRST .. lt_header_tab.LAST LOOP
      create_oif_data(
        ov_errbuf              => lv_errbuf             -- エラー・メッセージ
      , ov_retcode             => lv_retcode            -- リターン・コード
      , ov_errmsg              => lv_errmsg             -- ユーザー・エラー・メッセージ
      , ir_sell_head_data_rec  => lt_header_tab( i )    -- AP請求書OIF作成用データレコード
      );
      -- ===============================================
      -- 終了ステータスによって、件数処理を変更する。
      -- ===============================================
      -- 正常終了時
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 明細件数を正常終了件数に追加する。
        gn_normal_cnt := gn_normal_cnt + gn_sell_detail_num;
      -- 警告終了時
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- 明細件数を正常終了件数に追加する。
        gn_skip_cnt   := gn_skip_cnt   + gn_sell_detail_num;
        -- lv_errmsgをログに出力する。
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      -- 出力区分
                      , iv_message  => lv_errmsg         -- メッセージ
                      , in_new_line => cn_number_0       -- 改行
                      );
      -- エラー終了時
      ELSIF ( lv_retcode = cv_status_error ) THEN
        -- 共通関数例外に飛ぶ
        RAISE global_api_expt;
      END IF;
    END LOOP ap_oif_header_loop;
    -- 警告(スキップ)件数件数が0件以外の場合、リターンコードに警告を代入する。
    IF ( gn_skip_cnt != 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 該当データ0件例外 ***
    WHEN no_oif_data_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** 共通関数OTHERS例外 ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END submain;
--
  /************************************************************************
   * Procedure Name  : main
   * Description     : コンカレント実行ファイル登録プロシージャ
   ************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2  -- エラー・メッセージ
  , retcode       OUT VARCHAR2  -- リターン・コード
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'main';    -- プロシージャ名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- エラー・メッセージ
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- リターン・コード
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ユーザ・エラー･メッセージ
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- メッセージ出力時リターンコード
    lv_message_code        VARCHAR2(100)  DEFAULT NULL;             -- 終了メッセージコード格納
--
  BEGIN
    retcode := cv_status_normal;
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_errbuf     => lv_errbuf             -- エラー・メッセージ
    , ov_retcode    => lv_retcode            -- リターン・コード
    , ov_errmsg     => lv_errmsg             -- ユーザ・エラー・メッセージ
    , iv_which      => cv_which              -- 出力区分
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain呼出し
    -- ===============================================
    submain(
      ov_errbuf     => lv_errbuf             -- エラー・メッセージ
    , ov_retcode    => lv_retcode            -- リターン・コード
    , ov_errmsg     => lv_errmsg             -- ユーザ・エラー・メッセージ
    );
    -- submainが警告終了の場合、空白行を1行追加する。
    If ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                    , iv_message  => NULL              -- メッセージ
                    , in_new_line => cn_number_1       -- 改行
                    );
    -- submainがエラー終了の場合、lv_errbufとlv_errmsgをログ出力する。
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- lv_errmsg出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                    , iv_message  => lv_errmsg         -- メッセージ
                    , in_new_line => cn_number_0       -- 改行
                    );
      -- lv_errbuf出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- 出力区分
                    , iv_message  => lv_errbuf         -- メッセージ
                    , in_new_line => cn_number_1       -- 改行
                    );
    END IF;
    -- ===============================================
    -- 終了処理(A-9)
    -- ===============================================
    -- 対象件数出力
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90000         -- 成功件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )  -- 明細テーブルの対象件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  -- 出力区分
                  , iv_message  => lv_errmsg                     -- メッセージ
                  , in_new_line => cn_number_0                   -- 改行
                  );
    -- エラー発生時、成功件数:0件 スキップ件数:0件 エラー件数:1件
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_skip_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
    -- 成功件数出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90001         -- 成功件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )  -- 明細テーブル登録件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_errmsg                     --メッセージ
                  , in_new_line => cn_number_0                   --改行
                  );
    -- スキップ件数出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90003         -- 成功件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_skip_cnt )    -- スキップ件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_errmsg                     --メッセージ
                  , in_new_line => cn_number_0                   --改行
                  );
    -- エラー件数出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90002         -- エラー件数出力メッセージ
                  , iv_token_name1  => cv_token_count            -- トークン('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )   -- エラー件数
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --出力区分
                  , iv_message  => lv_errmsg                     --メッセージ
                  , in_new_line => cn_number_1                   --改行
                  );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    -- 正常終了
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    -- 警告終了
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    -- エラー終了
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- XXCCP'
                  , iv_name         => lv_message_code           -- 終了メッセージ
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --出力区分
                  , iv_message  => lv_errmsg        --メッセージ
                  , in_new_line => cn_number_0      --改行
                  );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- 終了ステータスエラー時、ロールバック
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := lv_errbuf;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ROLLBACK;
      retcode := cv_status_error;
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END main;
--
END XXCOK021A05C;
/
