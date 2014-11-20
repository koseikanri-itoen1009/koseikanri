CREATE OR REPLACE PACKAGE BODY XXCOK018A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK018A01C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：ARインターフェイス（AR I/F）販売物流 MD050_COK_018_A01
 * Version          : 1.8
 *
 * Program List
 * ------------------------------       ----------------------------------------------------------
 *  Name                                 Description
 * ------------------------------       ----------------------------------------------------------
 *  init                                 初期処理(A-1)
 *  get_discnt_amount_ar_data_p          AR連携データの取得(入金時値引高)(A-2)
 *  chk_discnt_amount_ar_info_p          妥当性チェックの処理(入金時値引高)(A-3)
 *  get_discnt_amnt_add_ar_data_p        AR連携データ付加情報の取得(入金時値引高)(A-4)
 *  ins_discnt_amount_ar_data_p          AR連携データの登録(入金時値引高)(A-5)
 *  ins_ra_if_lines_all_p                請求取引OIF登録(A-6)
 *  ins_ra_if_distributions_all_p        請求配分OIF登録(A-7)
 *  upd_ coordination_result_p           連携結果の更新(A-8)
 *  submain                              メイン処理プロシージャ
 *  main                                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/7      1.0   K.Suenaga        新規作成
 *  2009/3/17     1.1   M.Hiruta         [障害T1_0073]請求取引OIFへ登録する顧客IDを修正、顧客サイトIDを追加
 *  2009/3/24     1.2   T.Taniguchi      [障害T1_0118]請求取引OIFへ登録する金額を修正、外税・内税を考慮
 *  2009/4/14     1.3   M.Hiruta         [障害T1_0396]請求取引OIFへ登録する仕訳計上日を締め日に変更
 *                                                    AR会計期間有効チェックの処理日を締め日に変更
 *                                       [障害T1_0503]請求取引OIFへ登録する請求先IDと出荷先IDを正確な値に変更
 *  2009/4/15     1.4   M.Hiruta         [障害T1_0554]出荷先顧客サイトID・請求先顧客情報・請求先顧客サイトIDを
 *                                                    取得する際の抽出条件を変更
 *  2009/4/20     1.5   M.Hiruta         [障害T1_0512]請求配分OIFへ登録するデータの勘定科目が未収入金・売掛金の場合、
 *                                                    明細伝票番号に'1'を設定する。
 *  2009/4/24     1.6   M.Hiruta         [障害T1_0736]取引タイプにより請求書保留ステータスを設定
 *  2009/10/05    1.7   K.Yamaguchi      [仕様変更I_E_566] 取引タイプを業態（小分類）毎に設定可能に変更
 *  2009/10/19    1.8   K.Yamaguchi      [障害E_T3_00631] 消費税コード取得方法を変更
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by              CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_creation_date           CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cn_last_updated_by         CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_last_update_date        CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cn_last_update_login       CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cd_program_update_date     CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE  
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  --記号
  cv_msg_part                CONSTANT VARCHAR2(1)  := ':';
  cv_msg_cont                CONSTANT VARCHAR2(1)  := '.';
  --パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(15) := 'XXCOK018A01C';                       --パッケージ名
  --プロファイル
  cv_set_of_bks_id           CONSTANT VARCHAR2(20) := 'GL_SET_OF_BKS_ID';                   --会計帳簿ID
  cv_org_id                  CONSTANT VARCHAR2(10) := 'ORG_ID';                             --組織ID
  cv_aff1_company_code       CONSTANT VARCHAR2(25) := 'XXCOK1_AFF1_COMPANY_CODE';           --会社コード
  cv_aff2_dept_fin           CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_FIN';               --部門コード：財務経理部
  cv_aff5_customer_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';         --ダミー値:顧客コード
  cv_aff6_compuny_dummy      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';          --ダミー値:企業コード
  cv_aff7_preliminary1_dummy CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';     --ダミー値:予備１
  cv_aff8_preliminary2_dummy CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';     --ダミー値:予備２
  cv_aff3_allowance_payment  CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_ALLOWANCE_PAYMENT';      --勘定科目:入金時値引高
  cv_aff3_payment_excise_tax CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_PAYMENT_EXCISE_TAX';     --勘定科目:仮払消費税等
  cv_aff3_receivable         CONSTANT VARCHAR2(22) := 'XXCOK1_AFF3_RECEIVABLE';             --勘定科目:未収入金
  cv_aff3_account_receivable CONSTANT VARCHAR2(30) := 'XXCOK1_AFF3_ACCOUNT_RECEIVABLE';     --勘定科目:売掛金
  cv_aff4_receivable_vd      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_RECEIVABLE_VD';          --補助科目:未収入金VD売上
  cv_aff4_subacct_dummy      CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';          --補助科目:ダミー値
  cv_sales_category          CONSTANT VARCHAR2(21) := 'XXCOK1_GL_CATEGORY_BM';              --販売手数料:仕訳カテゴリ
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--  cv_cust_trx_type_vd        CONSTANT VARCHAR2(35) := 'XXCOK1_CUST_TRX_TYPE_RECEIVABLE_VD'; --取引タイプ:VD未収入金売上
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----  cv_cust_trx_type_elec_cost CONSTANT VARCHAR2(30) := 'XXCOK1_CUST_TRX_TYPE_ELEC_COST';     --取引タイプ:電気料相殺
--  cv_cust_trx_type_gnrl      CONSTANT VARCHAR2(35) := 'XXCOK1_CUST_TRX_TYPE_ALL_PAY';       --取引タイプ:入金値引高
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  cv_ra_trx_type_f_digestion_vd CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_FULL_DIGESTION_VD';  -- 取引タイプ_入金値引_フルサービス（消化）VD
  cv_ra_trx_type_delivery_vd    CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_DELIVERY_VD';        -- 取引タイプ_入金値引_納品VD
  cv_ra_trx_type_digestion_vd   CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_DIGESTION_VD';       -- 取引タイプ_入金値引_消化VD
  cv_ra_trx_type_general        CONSTANT VARCHAR2(50) := 'XXCOK1_RA_TRX_TYPE_GENERAL';            -- 取引タイプ_入金値引_一般店
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
  --メッセージ
  cv_90008_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008'; --入力パラメータなし
  cv_00003_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003'; --プロファイル値取得エラー
  cv_00028_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; --業務処理日付取得エラー
  cv_00029_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00029'; --通貨コード取得エラー
  cv_00042_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00042'; --会計期間チェックエラー
  cv_00025_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00025'; --伝票番号取得エラー
  cv_00035_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00035'; --顧客情報取得エラー
  cv_00090_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00090'; --取引タイプ情報取得エラー
  cv_00032_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032'; --支払条件情報取得エラー
  cv_00034_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034'; --勘定科目情報取得エラー
  cv_10280_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10280'; --AR値引連携データ登録エラー
  cv_00051_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00051'; --AR連携結果更新ロックエラー
  cv_10283_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10283'; --AR連携結果更新エラー
  cv_90000_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; --対象件数メッセージ
  cv_90002_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; --エラー件数メッセージ
  cv_90001_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; --成功件数メッセージ
  cv_90004_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; --正常終了メッセージ
  cv_00058_err_msg           CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00058'; --AR連携情報取得エラー
  cv_90006_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; --全ロールバックメッセージ
  --トークン
  cv_profile_token           CONSTANT VARCHAR2(7)  := 'PROFILE';        --プロファイル
  cv_proc_date_token         CONSTANT VARCHAR2(9)  := 'PROC_DATE';      --処理日
  cv_dept_code_token         CONSTANT VARCHAR2(9)  := 'DEPT_CODE';      --拠点コード
  cv_cust_code_token         CONSTANT VARCHAR2(9)  := 'CUST_CODE';      --顧客コード
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--  cv_vend_code_token         CONSTANT VARCHAR2(9)  := 'VEND_CODE';      --仕入先コード
--  cv_vend_site_code_token    CONSTANT VARCHAR2(14) := 'VEND_SITE_CODE'; --仕入先サイトコード
  cv_ship_cust_code_token    CONSTANT VARCHAR2(16) := 'SHIP_CUST_CODE'; --納品先顧客コード
  cv_bill_cust_code_token    CONSTANT VARCHAR2(16) := 'BILL_CUST_CODE'; --請求先顧客コード
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
  cv_account_date_token      CONSTANT VARCHAR2(12) := 'ACCOUNT_DATE';   --計上日
  cv_cust_trx_type_token     CONSTANT VARCHAR2(13) := 'CUST_TRX_TYPE';  --取引タイプ
  cv_count_token             CONSTANT VARCHAR2(5)  := 'COUNT';          --件数
  --アプリケーション短縮名
  cv_appli_xxccp_name        CONSTANT VARCHAR2(5)  := 'XXCCP';    --XXCCP
  cv_appli_ar_name           CONSTANT VARCHAR2(2)  := 'AR';       --AR
  cv_appli_xxcok_name        CONSTANT VARCHAR2(5)  := 'XXCOK';    --XXCOK
  --ステータス
  cv_untreated_ar_status     CONSTANT VARCHAR2(1)  := '0';       --連携ステータス未処理(AR)
  cv_finished_ar_status      CONSTANT VARCHAR2(1)  := '1';       --連携ステータス処理済(AR)
  cv_hold                    CONSTANT VARCHAR2(4)  := 'HOLD';    --請求書保留ステータス:フルサービスVD
  cv_open                    CONSTANT VARCHAR2(4)  := 'OPEN';    --請求書保留ステータス:フルサービスVD以外
  --言語
  cv_language                CONSTANT VARCHAR2(4)  := 'LANG';    --言語
  --タイプ
  cv_user_type               CONSTANT VARCHAR2(4)  := 'User';    --通貨換算タイプ
  cv_rev_class               CONSTANT VARCHAR2(3)  := 'REV';     --配分タイプ:収益
  cv_tax_class               CONSTANT VARCHAR2(3)  := 'TAX';     --配分タイプ:税金/明細タイプ:税金行
  cv_rec_class               CONSTANT VARCHAR2(3)  := 'REC';     --配分タイプ:債権
  cv_line_type               CONSTANT VARCHAR2(4)  := 'LINE';    --明細タイプ:収益行
  --その他
  cn_quantity                CONSTANT NUMBER       := 1;         --数量:収益行
  cv_rate                    CONSTANT VARCHAR2(1)  := '1';       --換算レート
  cv_waiting                 CONSTANT VARCHAR2(7)  := 'WAITING'; --個別請求書印刷/一括請求書印刷
  cv_percent                 CONSTANT NUMBER       := 100;       --割合
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--  cv_low_type                CONSTANT VARCHAR2(2)  := '24';      --業態（小分類）フルフルベンダー
  cv_low_type_f_digestion_vd CONSTANT VARCHAR2(2)  := '24';      -- フルサービス（消化）
  cv_low_type_delivery_vd    CONSTANT VARCHAR2(2)  := '26';      -- 納品VD
  cv_low_type_digestion_vd   CONSTANT VARCHAR2(2)  := '27';      -- 消化VD
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
  cv_validate_flag           CONSTANT VARCHAR2(1)  := 'N';       --有効フラグ
  cn_no_tax                  CONSTANT NUMBER       := 0;         --消費税率
  cn_rev_num                 CONSTANT NUMBER       := 1;         --明細番号
-- 2009/3/24     ver1.2   T.Taniguchi  ADD STR
  cv_tax_flag_y              CONSTANT VARCHAR2(1)  := 'Y';       --内税フラグ
-- 2009/3/24     ver1.2   T.Taniguchi  ADD END
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
  cv_line_slip_rec           CONSTANT VARCHAR2(1)  := '1';       --明細行伝票番号
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  cv_submit_bill_type_yes    CONSTANT VARCHAR2(1)  := 'Y';       --請求書出力対象：Yes
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt              NUMBER         DEFAULT 0;    --対象件数
  gn_normal_cnt              NUMBER         DEFAULT 0;    --正常件数
  gn_error_cnt               NUMBER         DEFAULT 0;    --エラー件数
  gn_set_of_bks_id           NUMBER         DEFAULT NULL; --会計帳簿ID
  gn_org_id                  VARCHAR2(50)   DEFAULT NULL; --組織ID
  gv_aff1_company_code       VARCHAR2(50)   DEFAULT NULL; --会社コード
  gv_aff2_dept_fin           VARCHAR2(50)   DEFAULT NULL; --部門コード：財務経理部
  gv_aff5_customer_dummy     VARCHAR2(50)   DEFAULT NULL; --ダミー値:顧客コード
  gv_aff6_compuny_dummy      VARCHAR2(50)   DEFAULT NULL; --ダミー値:企業コード
  gv_aff7_preliminary1_dummy VARCHAR2(50)   DEFAULT NULL; --ダミー値:予備１
  gv_aff8_preliminary2_dummy VARCHAR2(50)   DEFAULT NULL; --ダミー値:予備２
  gv_aff3_allowance_payment  VARCHAR2(50)   DEFAULT NULL; --勘定科目:入金時値引高
  gv_aff3_payment_excise_tax VARCHAR2(50)   DEFAULT NULL; --勘定科目:仮払消費税等
  gv_aff3_receivable         VARCHAR2(50)   DEFAULT NULL; --勘定科目:未収入金
  gv_aff3_account_receivable VARCHAR2(50)   DEFAULT NULL; --勘定科目:売掛金
  gv_aff4_receivable_vd      VARCHAR2(50)   DEFAULT NULL; --補助科目:未収入金VD売上
  gv_aff4_subacct_dummy      VARCHAR2(50)   DEFAULT NULL; --補助科目:ダミー値
  gv_sales_category          VARCHAR2(50)   DEFAULT NULL; --販売手数料:仕訳カテゴリ
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--  gv_cust_trx_type_vd        VARCHAR2(50)   DEFAULT NULL; --取引タイプ:VD未収入金売上
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----  gv_cust_trx_type_elec_cost VARCHAR2(50)   DEFAULT NULL; --取引タイプ:電気料相殺
----  gn_vd_trx_type_id          NUMBER         DEFAULT NULL; --取引タイプID:VD未収入金売上
----  gn_cust_trx_elec_id        NUMBER         DEFAULT NULL; --取引タイプID:電気料相殺
--  gv_cust_trx_type_gnrl      VARCHAR2(50)   DEFAULT NULL; --取引タイプ:入金値引高
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  gv_ra_trx_type_f_digestion_vd VARCHAR2(50) DEFAULT NULL; -- 取引タイプ_入金値引_フルサービス（消化）VD
  gv_ra_trx_type_delivery_vd    VARCHAR2(50) DEFAULT NULL; -- 取引タイプ_入金値引_納品VD
  gv_ra_trx_type_digestion_vd   VARCHAR2(50) DEFAULT NULL; -- 取引タイプ_入金値引_消化VD
  gv_ra_trx_type_general        VARCHAR2(50) DEFAULT NULL; -- 取引タイプ_入金値引_一般店
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
  gn_csh_rcpt                NUMBER         DEFAULT NULL; --入金値引額－入金値引消費税額
  gd_operation_date          DATE           DEFAULT NULL; --業務処理日付
  gv_currency_code           VARCHAR2(50)   DEFAULT NULL; --機能通貨コード
  gv_slip_number             VARCHAR2(50)   DEFAULT NULL; --伝票番号
  gv_cash_receiv_base_code   VARCHAR2(50)   DEFAULT NULL; --入金拠点コード
  gv_business_low_type       VARCHAR2(50)   DEFAULT NULL; --業態（小分類）
  gn_term_id                 NUMBER         DEFAULT NULL; --支払条件ID
  gv_language                VARCHAR2(10)   DEFAULT NULL; --言語
  gn_ship_account_id         NUMBER         DEFAULT NULL; --出荷先顧客ID
  gn_ship_address_id         NUMBER         DEFAULT NULL; --出荷先顧客サイトID
  gn_bill_account_id         NUMBER         DEFAULT NULL; --請求先顧客ID
  gn_bill_address_id         NUMBER         DEFAULT NULL; --請求先顧客サイトID
  gv_tax_flag                VARCHAR2(1)    DEFAULT NULL; --消費税税フラグ
  gn_tax_rate                NUMBER         DEFAULT NULL; --消費税率
  gn_tax_amt                 NUMBER         DEFAULT NULL; --消費税額
  -- ===============================
  -- グローバルカーソル：AR連携データの取得(入金時値引高)
  -- ===============================
  CURSOR g_discnt_amount_cur
  IS
    SELECT   xcbs.base_code                      AS base_code                     -- 拠点コード
           , xcbs.supplier_code                  AS supplier_code                 -- 仕入先コード
           , xcbs.supplier_site_code             AS supplier_site_code            -- 仕入先サイトコード
           , xcbs.delivery_cust_code             AS delivery_cust_code            -- 納品顧客コード
           , xcbs.demand_to_cust_code            AS demand_to_cust_code           -- 請求顧客コード
           , xcbs.emp_code                       AS emp_code                      -- 成績計上担当者コード
           , SUM(xcbs.csh_rcpt_discount_amt)     AS sum_csh_rcpt_discount_amt     -- 入金値引額
           , SUM(xcbs.csh_rcpt_discount_amt_tax) AS sum_csh_rcpt_discount_amt_tax -- 入金値引消費税額
           , xcbs.closing_date                   AS closing_date                  -- 締め日
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--           , xcbs.expect_payment_date            AS expect_payment_date           -- 支払予定日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
           , xcbs.tax_code                       AS tax_code                      -- 税金コード
           , xcbs.term_code                      AS term_code                     -- 支払条件
    FROM     xxcok_cond_bm_support               xcbs                             -- 条件別販手販協テーブル
    WHERE    xcbs.ar_interface_status            = cv_untreated_ar_status         -- 連携ステータス(AR) = 未処理
    AND      xcbs.csh_rcpt_discount_amt          IS NOT NULL                      -- 入金値引額あり
    GROUP BY xcbs.base_code                                                       -- 拠点コード
           , xcbs.supplier_code                                                   -- 仕入先コード
           , xcbs.supplier_site_code                                              -- 仕入先サイトコード
           , xcbs.delivery_cust_code                                              -- 納品顧客コード
           , xcbs.demand_to_cust_code                                             -- 請求顧客コード
           , xcbs.emp_code                                                        -- 成績計上担当者コード
           , xcbs.closing_date                                                    -- 締め日
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--           , xcbs.expect_payment_date                                             -- 支払予定日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
           , xcbs.tax_code                                                        -- 税金コード
           , xcbs.term_code;                                                      -- 支払条件
--
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    --取引タイプ情報
    CURSOR g_cust_trx_type_cur(
      iv_cust_trx_type IN VARCHAR2
    )
    IS
      SELECT   rctta.cust_trx_type_id AS cust_trx_type_id      --取引タイプID
             , rctta.attribute1       AS submit_bill_type      --請求書出力対象区分
             , CASE rctta.attribute1
                 WHEN cv_submit_bill_type_yes THEN
                   cv_open
                 ELSE
                   cv_hold
               END                    AS charge_waiting_status --請求書保留ステータス
      FROM     ra_cust_trx_types_all  rctta               --請求取引タイプマスタ
      WHERE    rctta.name         = iv_cust_trx_type  --仕訳ソース名 = 初期処理で取得した取引タイプ
      AND      rctta.org_id       = gn_org_id         --組織ID       = 組織ID
      AND      gd_operation_date  BETWEEN rctta.start_date
                                      AND NVL( rctta.end_date, gd_operation_date )
    ;
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  -- ===============================
  -- グローバルレコードタイプ
  -- ===============================
  g_discnt_amount_rtype g_discnt_amount_cur%ROWTYPE;
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--  g_cust_trx_type_vd    g_cust_trx_type_cur%ROWTYPE;
--  g_cust_trx_type_gnrl  g_cust_trx_type_cur%ROWTYPE;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
  g_ra_trx_type_f_digestion_vd g_cust_trx_type_cur%ROWTYPE; -- 取引タイプ_入金値引_フルサービス（消化）VD
  g_ra_trx_type_delivery_vd    g_cust_trx_type_cur%ROWTYPE; -- 取引タイプ_入金値引_納品VD
  g_ra_trx_type_digestion_vd   g_cust_trx_type_cur%ROWTYPE; -- 取引タイプ_入金値引_消化VD
  g_ra_trx_type_general        g_cust_trx_type_cur%ROWTYPE; -- 取引タイプ_入金値引_一般店
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
  -- ===============================
  -- 共通例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** ロックエラー **
  lock_err_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : upd_ coordination_result_p
   * Description      : 連携結果の更新(A-8)
   ***********************************************************************************/
  PROCEDURE upd_coordination_result_p(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_coordination_result_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lb_retcode BOOLEAN        DEFAULT NULL; -- メッセージ出力変数
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- メッセージ出力変数
    --==============================================================
    --ロック取得用カーソル
    --==============================================================
  CURSOR l_upd_cur
  IS
    SELECT 'X'
    FROM   xxcok_cond_bm_support    xcbs                     -- 条件別販手販協テーブル
    WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- 連携ステータス未処理(AR)
    AND    xcbs.csh_rcpt_discount_amt IS NOT NULL
    FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --カーソルオープン
    --==============================================================
    OPEN  l_upd_cur;
    CLOSE l_upd_cur;
    --==============================================================
    --成功件数のカウント
    --==============================================================
    BEGIN 
--
      SELECT COUNT(*)
      INTO   gn_normal_cnt
      FROM   xxcok_cond_bm_support    xcbs                     -- 条件別販手販協テーブル
      WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- 連携ステータス未処理(AR)
      AND    xcbs.csh_rcpt_discount_amt IS NOT NULL;
    END;
    --==============================================================
    --条件別販手販協テーブルの更新処理
    --==============================================================
    BEGIN
--
      UPDATE xxcok_cond_bm_support xcbs
      SET    xcbs.ar_interface_status = cv_finished_ar_status  -- 連携ステータス（AR）= 1：処理済
           , xcbs.ar_interface_date   = gd_operation_date      -- 連携日(AR) = 業務処理日付
           , xcbs.last_updated_by     = cn_last_updated_by     -- 最終更新者 = WHOカラム情報.ユーザID
           , xcbs.last_update_date    = SYSDATE                -- 最終更新日 = SYSDATE
           , xcbs.last_update_login   = cn_last_update_login   -- 最終更新ログインID=WHOカラム情報. ログインID
      WHERE  xcbs.ar_interface_status = cv_untreated_ar_status -- 連携ステータス (AR) = 0: 未処理
      AND    xcbs.csh_rcpt_discount_amt IS NOT NULL;
--
    EXCEPTION
      -- *** AR連携結果更新エラー ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_10283_err_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- 出力区分
                      , lv_out_msg         -- メッセージ
                      , 0                  -- 改行
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** ロックエラーメッセージ ***
    WHEN lock_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00051_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_coordination_result_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_ra_if_distributions_all_p
   * Description      : 請求配分OIF登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ra_if_distributions_all_p(
    ov_errbuf           OUT VARCHAR2                                                      -- エラー・メッセージ
  , ov_retcode          OUT VARCHAR2                                                      -- リターン・コード
  , ov_errmsg           OUT VARCHAR2                                                      -- ユーザーエラーメッセージ
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE                                   -- レコード引数(入金値引高)
  , it_count            IN  ra_interface_distributions_all.interface_line_attribute2%TYPE -- 明細行伝票番号
  , it_account_class    IN  ra_interface_distributions_all.account_class%TYPE             -- 配分タイプ
  , it_amount           IN  ra_interface_distributions_all.amount%TYPE                    -- 明細金額
  , it_ccid             IN  ra_interface_distributions_all.code_combination_id%TYPE       -- 勘定科目ID
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ra_if_distributions_all_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --請求配分OIF登録
    --==================================================================
    BEGIN
      INSERT INTO ra_interface_distributions_all( 
        interface_line_context    -- 明細コンテキスト
      , interface_line_attribute1 -- 伝票番号
      , interface_line_attribute2 -- 明細行伝票番号
      , account_class             -- 配分タイプ
      , amount                    -- 明細金額
      , percent                   -- 割合
      , code_combination_id       -- 勘定科目ID
      , attribute_category        -- DFFコンテキスト
      , creation_date             -- 新規作成日付
      , org_id                    -- オルグID
      )
      VALUES(
        gv_sales_category         -- 明細コンテキスト:初期処理で取得した仕訳カテゴリ
      , gv_slip_number            -- 伝票番号        :付加情報取得にて取得した伝票番号
      , it_count                  -- 明細行伝票番号  :レコード登録毎に同一伝票内でカウント
      , it_account_class          -- 配分タイプ      :配分タイプ
      , it_amount                 -- 明細金額        :金額
      , cv_percent                -- 割合            :100
      , it_ccid                   -- 勘定科目ID      :上記で取得した勘定科目ID
      , gn_org_id                 -- DFFコンテキスト :初期処理で取得した組織ID
      , SYSDATE                   -- 新規作成日付    :SYSDATE
      , gn_org_id                 -- オルグID        :初期処理で取得した組織ID
      );
    EXCEPTION
      WHEN  OTHERS THEN
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--          -- *** AR入金値引連携データ登録エラー ***
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                          cv_appli_xxcok_name
--                        , cv_10280_err_msg
--                        , cv_dept_code_token
--                        , i_discnt_amount_rec.base_code
--                        , cv_vend_code_token
--                        , i_discnt_amount_rec.supplier_code
--                        , cv_vend_site_code_token
--                        , i_discnt_amount_rec.supplier_site_code
--                        , cv_account_date_token
--                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
--                        );
          -- *** AR入金値引連携データ登録エラー ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_10280_err_msg
                        , cv_dept_code_token
                        , i_discnt_amount_rec.base_code
                        , cv_ship_cust_code_token
                        , i_discnt_amount_rec.delivery_cust_code
                        , cv_bill_cust_code_token
                        , i_discnt_amount_rec.demand_to_cust_code
                        , cv_account_date_token
                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
                        );
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_ra_if_distributions_all_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_ra_if_lines_all_p
   * Description      : 請求取引OIF登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_ra_if_lines_all_p(
    ov_errbuf                  OUT VARCHAR2                                              -- エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2                                              -- リターン・コード
  , ov_errmsg                  OUT VARCHAR2                                              -- ユーザーエラーメッセージ
  , i_discnt_amount_rec        IN  g_discnt_amount_cur%ROWTYPE                           -- レコード引数(入金値引高)
  , it_spare                   IN  ra_interface_lines_all.interface_line_attribute3%TYPE -- カウント
  , it_line_type               IN  ra_interface_lines_all.line_type%TYPE                 -- 明細タイプ
  , it_amont                   IN  ra_interface_lines_all.amount%TYPE                    -- 明細金額
  , it_cust_trx_type_id        IN  ra_interface_lines_all.cust_trx_type_id%TYPE          -- 取引タイプID
  , it_link_to_line_context    IN  ra_interface_lines_all.link_to_line_context%TYPE      -- リンク明細コンテキスト
  , it_link_to_line_attribute1 IN  ra_interface_lines_all.link_to_line_attribute1%TYPE   -- リンク伝票番号
  , it_link_to_line_attribute2 IN  ra_interface_lines_all.link_to_line_attribute2%TYPE   -- リンク明細行番号
  , it_trx_date                IN  ra_interface_lines_all.trx_date%TYPE                  -- 請求書日付（締め日）
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--  , it_gl_date                 IN  ra_interface_lines_all.gl_date%TYPE                   -- 仕訳計上日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
  , it_quantity                IN  ra_interface_lines_all.quantity%TYPE                  -- 数量
  , it_unit_selling_price      IN  ra_interface_lines_all.unit_selling_price%TYPE        -- 単価
  , it_tax_code                IN  ra_interface_lines_all.tax_code%TYPE                  -- 税コード
  , it_form_base               IN  ra_interface_lines_all.header_attribute5%TYPE         -- 起票部門
  , it_form_typist             IN  ra_interface_lines_all.header_attribute6%TYPE         -- 伝票入力者
  , it_charge_waiting_status   IN  ra_interface_lines_all.header_attribute7%TYPE         -- 請求書保留ステータス
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ra_if_lines_all_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    --==================================================================
    --請求取引OIF登録
    --==================================================================
    BEGIN
      INSERT INTO ra_interface_lines_all( 
        interface_line_context       -- 明細コンテキスト
      , interface_line_attribute1    -- 伝票番号
      , interface_line_attribute2    -- 明細行伝票番号
      , batch_source_name            -- ソース
      , set_of_books_id              -- 会計帳簿ID
      , line_type                    -- 明細タイプ
      , description                  -- 請求書明細摘要
      , currency_code                -- 通貨コード
      , amount                       -- 明細金額
      , cust_trx_type_id             -- 取引タイプID
      , term_id                      -- 支払条件ID
      , orig_system_bill_customer_id -- 請求先顧客ID
      , orig_system_bill_address_id  -- 請求先サイトID
      , orig_system_ship_customer_id -- 納品先顧客ID
      , orig_system_ship_address_id  -- 納品先サイトID
      , link_to_line_context         -- リンク明細コンテキスト
      , link_to_line_attribute1      -- リンク伝票番号
      , link_to_line_attribute2      -- リンク明細行番号
      , conversion_type              -- 通貨換算タイプ
      , conversion_rate              -- 換算レート
      , trx_date                     -- 請求書日付
      , gl_date                      -- 仕訳計上日
      , trx_number                   -- 伝票番号
      , quantity                     -- 数量
      , unit_selling_price           -- 単価
      , tax_code                     -- 税区分
      , header_attribute_category    -- DFFコンテキスト
      , header_attribute5            -- 起票部門
      , header_attribute6            -- 伝票入力者
      , header_attribute7            -- 請求書保留ステータス
      , header_attribute8            -- 個別請求書印刷
      , header_attribute9            -- 一括請求書印刷
      , header_attribute11           -- 入金拠点コード
      , creation_date                -- 新規作成日付
      , org_id                       -- オルグID
      , amount_includes_tax_flag     -- 内税フラグ
      )
      VALUES(
        gv_sales_category            -- 明細コンテキスト      :初期処理で取得した仕訳カテゴリ
      , gv_slip_number               -- 伝票番号              :付加情報取得にて取得した伝票番号
      , it_spare                     -- 予備                  :カウント
      , gv_sales_category            -- ソース                :初期処理で取得した仕訳カテゴリ
      , gn_set_of_bks_id             -- 会計帳簿ID            :初期処理で取得した会計帳簿ID
      , it_line_type                 -- 明細タイプ            :収益行：'LINE'税金行：'TAX'
      , gv_sales_category            -- 請求書明細摘要        :初期処理で取得した仕訳カテゴリ
      , gv_currency_code             -- 通貨コード            :初期処理で取得した通貨コード
      , it_amont                     -- 明細金額              :収益行:入金値引額/電気料 税金行:消費税額/消費税額
      , it_cust_trx_type_id          -- 取引タイプID          :初期処理にて取得した勘定科目に対応する取引タイプID
      , gn_term_id                   -- 支払条件ID            :付加情報取得にて取得した支払条件ID
-- Start 2009/04/14 Ver_1.3 T1_0503 M.Hiruta
--      , gn_ship_account_id           -- 請求先顧客ID          :顧客情報２.請求先顧客ID
--      , gn_ship_address_id           -- 請求先顧客サイトID    :顧客情報２.請求先顧客IDに紐づいた顧客サイトID
--      , gn_bill_account_id           -- 出荷先顧客ID          :顧客情報１.出荷先顧客ID
--      , gn_bill_address_id           -- 出荷先顧客サイトID    :顧客情報１.出荷先顧客IDに紐づいた顧客サイトID
      , gn_bill_account_id           -- 請求先顧客ID          :顧客情報２.請求先顧客ID
      , gn_bill_address_id           -- 請求先顧客サイトID    :顧客情報２.請求先顧客IDに紐づいた顧客サイトID
      , gn_ship_account_id           -- 出荷先顧客ID          :顧客情報１.出荷先顧客ID
      , gn_ship_address_id           -- 出荷先顧客サイトID    :顧客情報１.出荷先顧客IDに紐づいた顧客サイトID
-- End   2009/04/14 Ver_1.3 T1_0503 M.Hiruta
      , it_link_to_line_context      -- リンク明細コンテキスト:税金行:収益行にて指定した明細コンテキスト値
      , it_link_to_line_attribute1   -- リンク伝票番号        :税金行:収益行にて指定した伝票番号値
      , it_link_to_line_attribute2   -- リンク明細行番号      :税金行:収益行にて指定した明細行伝票番号値
      , cv_user_type                 -- 通貨換算タイプ        :'User'
      , cv_rate                      -- 換算レート            :'1'
      , it_trx_date                  -- 請求書日付            :締め日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--      , it_gl_date                   -- 仕訳計上日            :支払予定日
      , it_trx_date                  -- 仕訳計上日            :締め日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
      , gv_slip_number               -- 伝票番号              :付加情報取得にて取得した伝票番号
      , it_quantity                  -- 数量                  :収益行：'1' 税金行：NULL
      , it_unit_selling_price        -- 単価                  :明細金額と同じ値
      , it_tax_code                  -- 税区分                :消費税コード
      , gn_org_id                    -- DFFコンテキスト       :初期処理で取得した組織ID
      , it_form_base                 -- 起票部門              :拠点コード
      , it_form_typist               -- 伝票入力者            :成績計上担当者コード
      , it_charge_waiting_status     -- 請求書保留ステータス  :フルVD'HOLD'を設定。以外は'OPEN'を設定
      , cv_waiting                   -- 個別請求書印刷        :'WAITING'
      , cv_waiting                   -- 一括請求書印刷        :'WAITING'
      , gv_cash_receiv_base_code     -- 入金拠点コード        :顧客情報１.入金拠点コード
      , SYSDATE                      -- 新規作成日付          :SYSDATE
      , gn_org_id                    -- オルグID              :初期処理で取得した組織ID
      , gv_tax_flag                  -- 内税フラグ            :AR税金マスタから取得
      );
    EXCEPTION
      WHEN  OTHERS THEN
-- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
--          -- *** AR入金値引連携データ登録エラー ***
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                          cv_appli_xxcok_name
--                        , cv_10280_err_msg
--                        , cv_dept_code_token
--                        , i_discnt_amount_rec.base_code
--                        , cv_vend_code_token
--                        , i_discnt_amount_rec.supplier_code
--                        , cv_vend_site_code_token
--                        , i_discnt_amount_rec.supplier_site_code
--                        , cv_account_date_token
--                        , TO_CHAR(i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
--                        );
          -- *** AR入金値引連携データ登録エラー ***
          lv_out_msg := xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                        , cv_10280_err_msg
                        , cv_dept_code_token
                        , i_discnt_amount_rec.base_code
                        , cv_ship_cust_code_token
                        , i_discnt_amount_rec.delivery_cust_code
                        , cv_bill_cust_code_token
                        , i_discnt_amount_rec.demand_to_cust_code
                        , cv_account_date_token
                        , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYYY/MM/DD' )
                        );
-- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
          lb_retcode := xxcok_common_pkg.put_message_f( 
                          FND_FILE.OUTPUT    -- 出力区分
                        , lv_out_msg         -- メッセージ
                        , 0                  -- 改行
                        );
          ov_errmsg  := NULL;
          ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
          ov_retcode := cv_status_error;
    END;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_ra_if_lines_all_p;
--
  /**********************************************************************************
   * Procedure Name   : ins_discnt_amount_ar_data_p
   * Description      : AR連携データの登録（入金時値引高）(A-5)
   ***********************************************************************************/
  PROCEDURE ins_discnt_amount_ar_data_p(
    ov_errbuf           OUT VARCHAR2                    -- エラー・メッセージ
  , ov_retcode          OUT VARCHAR2                    -- リターン・コード
  , ov_errmsg           OUT VARCHAR2                    -- ユーザー・エラー・メッセージ
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- レコード引数
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_discnt_amount_ar_data_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;                             -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;                             -- リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;                             -- ユーザー・エラー・メッセージ
    lv_out_msg                 VARCHAR2(5000) DEFAULT NULL;                             -- メッセージ変数
    lb_retcode                 BOOLEAN        DEFAULT NULL;                             -- メッセージ出力戻り値
    lt_charge_waiting_status   ra_interface_lines_all.header_attribute7%TYPE;           -- 請求書保留ステータス格納変数
    lt_line_type               ra_interface_lines_all.line_type%TYPE;                   -- 明細タイプ
    lt_line_amount             ra_interface_lines_all.amount%TYPE;                      -- 明細金額
    lt_cust_trx_type_id        ra_interface_lines_all.cust_trx_type_id%TYPE;            -- 取引タイプID
    lt_link_to_line_context    ra_interface_lines_all.link_to_line_context%TYPE;        -- リンク明細コンテキスト
    lt_link_to_line_attribute1 ra_interface_lines_all.link_to_line_attribute1%TYPE;     -- リンク伝票番号
    lt_link_to_line_attribute2 ra_interface_lines_all.link_to_line_attribute2%TYPE;     -- リンク明細行番号
    lt_quantity                ra_interface_lines_all.quantity%TYPE;                    -- 数量
    lt_unit_selling_price      ra_interface_lines_all.unit_selling_price%TYPE;          -- 単価
    lv_segment2                VARCHAR2(100)  DEFAULT NULL;                             -- 部門コード
    lv_segment3                VARCHAR2(100)  DEFAULT NULL;                             -- 勘定科目コード
    lv_segment4                VARCHAR2(100)  DEFAULT NULL;                             -- 補助科目コード
    lt_distributions_amount    ra_interface_distributions_all.amount%TYPE;              -- 明細金額
    lt_ccid                    ra_interface_distributions_all.code_combination_id%TYPE; -- CCIDの戻り値
    lt_account_class           ra_interface_distributions_all.account_class%TYPE;       -- 配分タイプ
    ln_cnt                     NUMBER         DEFAULT NULL;                             -- カウント
    -- ===============================
    -- ローカル・例外
    -- ===============================
    ccid_expt EXCEPTION; -- 勘定科目情報取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
--
-- 2009/3/24     ver1.2   T.Taniguchi  DEL STR
--    gn_csh_rcpt := i_discnt_amount_rec.sum_csh_rcpt_discount_amt - i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax;
-- 2009/3/24     ver1.2   T.Taniguchi  DEL END
--
    <<ins_ra_if_lines_all_loop>>
    FOR ln_cnt IN 1..2 LOOP
--
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/23 Ver_1.6 T1_0736 M.Hiruta
----      IF( gv_business_low_type = cv_low_type ) THEN
----        lt_charge_waiting_status := cv_hold;             -- 小分類の区分HOLD
----        lt_cust_trx_type_id      := gn_vd_trx_type_id;   -- 取引タイプID:VD未収入金売上
----      ELSE
----        lt_charge_waiting_status := cv_open;             -- 小分類の区分OPEN
----        lt_cust_trx_type_id      := gn_cust_trx_elec_id; -- 取引タイプID:電気料相殺
----      END IF;
----
--      IF( gv_business_low_type = cv_low_type ) THEN
--        lt_cust_trx_type_id      := g_cust_trx_type_vd.cust_trx_type_id;        -- VD未収入金売上：取引タイプID
--        lt_charge_waiting_status := g_cust_trx_type_vd.charge_waiting_status;   -- VD未収入金売上：請求書保留ステータス
--      ELSE
--        lt_cust_trx_type_id      := g_cust_trx_type_gnrl.cust_trx_type_id;      -- 入金値引高：取引タイプID
--        lt_charge_waiting_status := g_cust_trx_type_gnrl.charge_waiting_status; -- 入金値引高：請求書保留ステータス
--      END IF;
---- End   2009/04/23 Ver_1.6 T1_0736 M.Hiruta
      -- フルVD（消化）
      IF(    gv_business_low_type = cv_low_type_f_digestion_vd ) THEN
        lt_cust_trx_type_id      := g_ra_trx_type_f_digestion_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_f_digestion_vd.charge_waiting_status;
      -- 納品VD
      ELSIF( gv_business_low_type = cv_low_type_delivery_vd    ) THEN
        lt_cust_trx_type_id      := g_ra_trx_type_delivery_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_delivery_vd.charge_waiting_status;
      -- 消化VD
      ELSIF( gv_business_low_type = cv_low_type_digestion_vd   ) THEN
        lt_cust_trx_type_id      := g_ra_trx_type_digestion_vd.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_digestion_vd.charge_waiting_status;
      -- 一般店
      ELSE
        lt_cust_trx_type_id      := g_ra_trx_type_general.cust_trx_type_id;
        lt_charge_waiting_status := g_ra_trx_type_general.charge_waiting_status;
      END IF;
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
      --================================================================
      --内税フラグの取得する
      --================================================================
      BEGIN
        SELECT amount_includes_tax_flag   AS tax_flag                    -- 内税フラグ
             , tax_rate                   AS tax_rate                    -- 消費税率
        INTO   gv_tax_flag
             , gn_tax_rate
        FROM   ar_vat_tax_all_b           avtab                          -- AR税金マスタ
        WHERE  avtab.set_of_books_id      = gn_set_of_bks_id             -- 会計帳簿ID
        AND    avtab.tax_code             = i_discnt_amount_rec.tax_code -- 税コード
        AND    avtab.validate_flag       <> cv_validate_flag             -- 有効フラグ
        AND    avtab.org_id               = gn_org_id                    -- 営業単位ID
-- 2009/10/19 Ver.1.8 [障害E_T3_00631] SCS K.Yamaguchi REPAIR START
--        AND    gd_operation_date BETWEEN avtab.start_date AND NVL( avtab.end_date, ( gd_operation_date ) )
        AND    i_discnt_amount_rec.closing_date BETWEEN avtab.start_date
                                                    AND NVL( avtab.end_date, i_discnt_amount_rec.closing_date )
-- 2009/10/19 Ver.1.8 [障害E_T3_00631] SCS K.Yamaguchi REPAIR END
        ;
      END;
-- 2009/3/24     ver1.2   T.Taniguchi  ADD STR
      --================================================================
      --金額の設定
      --================================================================
      -- 内税の場合
      IF gv_tax_flag = cv_tax_flag_y THEN
        gn_csh_rcpt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt ) * -1; -- (税込金額) * -1
      -- 外税の場合
      ELSE
        gn_csh_rcpt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt
                        - i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax ) * -1; -- (税込金額 - 消費税額) * -1
      END IF;
      -- 消費税額の設定
      gn_tax_amt := ( i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax ) * -1;
-- 2009/3/24     ver1.2   T.Taniguchi  ADD END
      --================================================================
      --収益/仕訳パターン：借方
      --================================================================
      IF ( ln_cnt = 1 ) THEN
        lt_line_type               := cv_line_type;                                      -- 明細タイプ:収益行
        lt_line_amount             := gn_csh_rcpt;                                       -- 入金値引額－入金値引消費税額
        lt_link_to_line_context    := NULL;                                              -- リンク明細コンテキスト
        lt_link_to_line_attribute1 := NULL;                                              -- リンク伝票番号
        lt_link_to_line_attribute2 := NULL;                                              -- リンク明細行番号
        lt_quantity                := cn_quantity;                                       -- 数量:収益行1
        lt_unit_selling_price      := gn_csh_rcpt;                                       -- 入金値引額－入金値引消費税額
        --================================================================
        --ins_ra_if_lines_all_pの呼び出し(入金値引額)
        --================================================================
        ins_ra_if_lines_all_p(
          ov_errbuf                  => lv_errbuf
        , ov_retcode                 => lv_retcode
        , ov_errmsg                  => lv_errmsg
        , i_discnt_amount_rec        => i_discnt_amount_rec                     -- レコード引数(入金値引高)
        , it_spare                   => ln_cnt                                  -- カウント
        , it_line_type               => lt_line_type                            -- 明細タイプ
        , it_amont                   => lt_line_amount                          -- 明細金額
        , it_cust_trx_type_id        => lt_cust_trx_type_id                     -- 取引タイプID
        , it_link_to_line_context    => lt_link_to_line_context                 -- リンク明細コンテキスト
        , it_link_to_line_attribute1 => lt_link_to_line_attribute1              -- リンク伝票番号
        , it_link_to_line_attribute2 => lt_link_to_line_attribute2              -- リンク明細行番号
        , it_trx_date                => i_discnt_amount_rec.closing_date        -- 請求書日付
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--        , it_gl_date                 => i_discnt_amount_rec.expect_payment_date -- 仕訳計上日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
        , it_quantity                => lt_quantity                             -- 数量
        , it_unit_selling_price      => lt_unit_selling_price                   -- 単価
        , it_tax_code                => i_discnt_amount_rec.tax_code            -- 税コード
        , it_form_base               => i_discnt_amount_rec.base_code           -- 起票部門
        , it_form_typist             => i_discnt_amount_rec.emp_code            -- 伝票入力者
        , it_charge_waiting_status   => lt_charge_waiting_status                -- 請求書保留ステータス
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --================================================================
      --税金/仕訳パターン：借方
      --================================================================
      ELSIF ( ln_cnt = 2 )
        AND ( gn_tax_rate <> 0 ) THEN
        lt_line_type               := cv_tax_class;                                      -- 明細タイプ:税金行
-- 2009/3/24     ver1.2   T.Taniguchi  MOD STR
--        lt_line_amount             := i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax; -- 入金値引消費税額
        lt_line_amount             := gn_tax_amt;                                          -- 入金値引消費税額
-- 2009/3/24     ver1.2   T.Taniguchi  MOD END
        lt_link_to_line_context    := gv_sales_category;                                 -- 収益行の明細コンテキスト値
        lt_link_to_line_attribute1 := gv_slip_number;                                    -- 収益行の伝票番号値
        lt_link_to_line_attribute2 := cn_rev_num;                                        -- 収益行の明細行伝票番号値
        lt_quantity                := NULL;                                              -- 数量:税金行NULL
        lt_unit_selling_price      := NULL;                                              -- 単価:税金行NULL
        --================================================================
        --ins_ra_if_lines_all_pの呼び出し(入金値引額)
        --================================================================
        ins_ra_if_lines_all_p(
          ov_errbuf                  => lv_errbuf
        , ov_retcode                 => lv_retcode
        , ov_errmsg                  => lv_errmsg
        , i_discnt_amount_rec        => i_discnt_amount_rec                     -- レコード引数(入金値引高)
        , it_spare                   => ln_cnt                                  -- カウント
        , it_line_type               => lt_line_type                            -- 明細タイプ
        , it_amont                   => lt_line_amount                          -- 明細金額
        , it_cust_trx_type_id        => lt_cust_trx_type_id                     -- 取引タイプID
        , it_link_to_line_context    => lt_link_to_line_context                 -- リンク明細コンテキスト
        , it_link_to_line_attribute1 => lt_link_to_line_attribute1              -- リンク伝票番号
        , it_link_to_line_attribute2 => lt_link_to_line_attribute2              -- リンク明細行番号
        , it_trx_date                => i_discnt_amount_rec.closing_date        -- 請求書日付
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--        , it_gl_date                 => i_discnt_amount_rec.expect_payment_date -- 仕訳計上日
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
        , it_quantity                => lt_quantity                             -- 数量
        , it_unit_selling_price      => lt_unit_selling_price                   -- 単価
        , it_tax_code                => i_discnt_amount_rec.tax_code            -- 税コード
        , it_form_base               => i_discnt_amount_rec.base_code           -- 起票部門
        , it_form_typist             => i_discnt_amount_rec.emp_code            -- 伝票入力者
        , it_charge_waiting_status   => lt_charge_waiting_status                -- 請求書保留ステータス
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP ins_ra_if_lines_all_loop;
--
    <<ins_ra_if_distributions_loop>>
    FOR ln_cnt IN 1..3 LOOP
      --================================================================
      --収益/仕訳パターン：借方
      --================================================================
      IF ( ln_cnt = 1 ) THEN
        lv_segment2             := i_discnt_amount_rec.base_code;                     -- 部門コード     :拠点コード
        lv_segment3             := gv_aff3_allowance_payment;                         -- 勘定科目コード :入金時値引高
        lv_segment4             := gv_aff4_subacct_dummy;                             -- 補助科目コード :ダミー値
        lt_account_class        := cv_rev_class;                                      -- 配分タイプ(収益)
        lt_distributions_amount := gn_csh_rcpt;                                       -- 明細金額:入金値引額－入金値引消費税額
        --================================================================
        --CCID取得
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                     i_discnt_amount_rec.closing_date -- 処理日
                   , gv_aff1_company_code             -- 会社コード
                   , lv_segment2                      -- 部門コード
                   , lv_segment3                      -- 勘定科目コード
                   , lv_segment4                      -- 補助科目コード
                   , gv_aff5_customer_dummy           -- 顧客コードダミー値
                   , gv_aff6_compuny_dummy            -- 企業コードダミー値
                   , gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                   , gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                   );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_pの呼び出し
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- レコード引数(入金値引高)
        , it_count            => ln_cnt                  -- 明細行伝票番号
        , it_account_class    => lt_account_class        -- 配分タイプ
        , it_amount           => lt_distributions_amount -- 明細金額
        , it_ccid             => lt_ccid                 -- 勘定科目ID
        );
      --================================================================
      --税金/仕訳パターン：借方
      --================================================================
      ELSIF ( ln_cnt = 2 )
        AND ( gn_tax_rate <> cn_no_tax ) THEN
        lv_segment2             := gv_aff2_dept_fin;                                  -- 部門コード     :財務経理部
        lv_segment3             := gv_aff3_payment_excise_tax;                        -- 勘定科目コード :仮払消費税等
        lv_segment4             := gv_aff4_subacct_dummy;                             -- 補助科目コード :ダミー値
        lt_account_class        := cv_tax_class;                                      -- 配分タイプ(税金)
-- 2009/3/24     ver1.2   T.Taniguchi  MOD STR
--        lt_distributions_amount := i_discnt_amount_rec.sum_csh_rcpt_discount_amt_tax; -- 明細金額:入金値引消費税額
        lt_distributions_amount := gn_tax_amt;                                       -- (明細金額:入金値引消費税額) * -1
-- 2009/3/24     ver1.2   T.Taniguchi  MOD END
        --================================================================
        --CCID取得
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- 処理日
                 , gv_aff1_company_code             -- 会社コード
                 , lv_segment2                      -- 部門コード
                 , lv_segment3                      -- 勘定科目コード
                 , lv_segment4                      -- 補助科目コード
                 , gv_aff5_customer_dummy           -- 顧客コードダミー値
                 , gv_aff6_compuny_dummy            -- 企業コードダミー値
                 , gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                 , gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_pの呼び出し
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- レコード引数(入金値引高)
        , it_count            => ln_cnt                  -- 明細行伝票番号
        , it_account_class    => lt_account_class        -- 配分タイプ
        , it_amount           => lt_distributions_amount -- 明細金額
        , it_ccid             => lt_ccid                 -- 勘定科目ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      --================================================================
      --収益/仕訳パターン：貸方(フルベンダー(消化))
      --================================================================
      ELSIF ( ln_cnt = 3 )
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--        AND ( gv_business_low_type = cv_low_type ) THEN
        AND ( gv_business_low_type = cv_low_type_f_digestion_vd ) THEN
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
        lv_segment2             := gv_aff2_dept_fin;                                  -- 部門コード     :財務経理部
        lv_segment3             := gv_aff3_receivable;                                -- 勘定科目コード :未収入金
        lv_segment4             := gv_aff4_receivable_vd;                             -- 補助科目コード :未収入金VD売上
        lt_account_class        := cv_rec_class;                                      -- 配分タイプ(債権)
        lt_distributions_amount := NULL;                                              -- 明細金額:NULL
        --================================================================
        --CCID取得
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- 処理日
                 , gv_aff1_company_code             -- 会社コード
                 , lv_segment2                      -- 部門コード
                 , lv_segment3                      -- 勘定科目コード
                 , lv_segment4                      -- 補助科目コード
                 , gv_aff5_customer_dummy           -- 顧客コードダミー値
                 , gv_aff6_compuny_dummy            -- 企業コードダミー値
                 , gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                 , gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_pの呼び出し
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- レコード引数(入金値引高)
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
--        , it_count            => ln_cnt                  -- 明細行伝票番号
        , it_count            => cv_line_slip_rec        -- 明細行伝票番号
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
        , it_account_class    => lt_account_class        -- 配分タイプ
        , it_amount           => lt_distributions_amount -- 明細金額
        , it_ccid             => lt_ccid                 -- 勘定科目ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      --================================================================
      --収益/仕訳パターン：貸方(一般)
      --================================================================
      ELSIF ( ln_cnt = 3 )
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--        AND  ( gv_business_low_type <> cv_low_type ) THEN
        AND  ( gv_business_low_type <> cv_low_type_f_digestion_vd ) THEN
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
        lv_segment2             := gv_aff2_dept_fin;                                  -- 部門コード     :財務経理部
        lv_segment3             := gv_aff3_account_receivable;                        -- 勘定科目コード :売掛金
        lv_segment4             := gv_aff4_subacct_dummy;                             -- 補助科目コード :ダミー値
        lt_account_class        := cv_rec_class;                                      -- 配分タイプ(債権)
        lt_distributions_amount := NULL;                                              -- 明細金額:NULL
        --================================================================
        --CCID取得
        --================================================================
        lt_ccid := xxcok_common_pkg.get_code_combination_id_f( 
                   i_discnt_amount_rec.closing_date -- 処理日
                 , gv_aff1_company_code             -- 会社コード
                 , lv_segment2                      -- 部門コード
                 , lv_segment3                      -- 勘定科目コード
                 , lv_segment4                      -- 補助科目コード
                 , gv_aff5_customer_dummy           -- 顧客コードダミー値
                 , gv_aff6_compuny_dummy            -- 企業コードダミー値
                 , gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                 , gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                 );
--
        IF lt_ccid IS NULL THEN
          RAISE ccid_expt;
        END IF;
        --================================================================
        --ins_ra_if_distributions_all_pの呼び出し
        --================================================================
        ins_ra_if_distributions_all_p(
          ov_errbuf           => lv_errbuf
        , ov_retcode          => lv_retcode
        , ov_errmsg           => lv_errmsg
        , i_discnt_amount_rec => i_discnt_amount_rec     -- レコード引数(入金値引高)
-- Start 2009/04/20 Ver_1.5 T1_0512 M.Hiruta
--        , it_count            => ln_cnt                  -- 明細行伝票番号
        , it_count            => cv_line_slip_rec        -- 明細行伝票番号
-- End   2009/04/20 Ver_1.5 T1_0512 M.Hiruta
        , it_account_class    => lt_account_class        -- 配分タイプ
        , it_amount           => lt_distributions_amount -- 明細金額
        , it_ccid             => lt_ccid                 -- 勘定科目ID
        );
--
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP ins_ra_if_distributions_loop;
--
  EXCEPTION
    -- *** 勘定科目情報取得エラー ****
    WHEN ccid_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00034_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_discnt_amount_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discnt_amnt_add_ar_data_p
   * Description      : AR連携データ付加情報の取得(入金時値引高)(A-4)
   ***********************************************************************************/
  PROCEDURE get_discnt_amnt_add_ar_data_p(
    ov_errbuf           OUT VARCHAR2                    -- エラー・メッセージ
  , ov_retcode          OUT VARCHAR2                    -- リターン・コード
  , ov_errmsg           OUT VARCHAR2                    -- ユーザー・エラー・メッセージ
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- レコード引数
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_discnt_amnt_add_ar_data_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg          VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg         VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode         BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
    -- ===============================
    -- ローカル・例外
    -- ===============================
    get_slip_number_expt EXCEPTION; -- 伝票番号取得エラー
    get_cust_info_expt   EXCEPTION; -- 顧客情報取得エラー
    get_term_info_expt   EXCEPTION; -- 支払条件情報取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==================================================================
    --登録付加情報取得
    --==================================================================
    gv_slip_number := xxcok_common_pkg.get_slip_number_f(
                        cv_pkg_name -- 本機能のパッケージ名
                      );
    IF( gv_slip_number IS NULL ) THEN
      RAISE get_slip_number_expt;
    END IF;
    --==================================================================
    --納品顧客コードに紐づく顧客情報を取得
    --==================================================================
    BEGIN
      SELECT xhv.ship_account_id       AS ship_account_id                       -- 出荷先顧客ID
           , xhv.cash_receiv_base_code AS cash_receiv_base_code                 -- 入金拠点コード
           , xca.business_low_type     AS business_low_type                     -- 業態（小分類）
      INTO   gn_ship_account_id
           , gv_cash_receiv_base_code
           , gv_business_low_type
      FROM   xxcfr_cust_hierarchy_v    xhv                                      -- 顧客階層ビュー
           , hz_cust_accounts          hca                                      -- 顧客マスタ
           , xxcmm_cust_accounts       xca                                      -- 請求先顧客追加情報
      WHERE  hca.cust_account_id       = xca.customer_id                        -- 顧客ID = 顧客ID
      AND    xhv.ship_account_number   = i_discnt_amount_rec.delivery_cust_code -- 顧客コード = 納品顧客コード
      AND    xhv.ship_account_number   = xca.customer_code;                     -- 顧客コード = 顧客コード
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_cust_info_expt;
    END;
    --==================================================================
    --出荷先顧客IDに紐づく顧客サイトIDを取得
    --==================================================================
    BEGIN
      SELECT hcasa.cust_acct_site_id AS cust_acct_site_id                       -- 顧客サイトID
      INTO   gn_ship_address_id
      FROM   hz_cust_acct_sites_all  hcasa                                      -- 顧客サイトマスタ
      WHERE  hcasa.cust_account_id   = gn_ship_account_id                       -- 出荷先顧客ID
-- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
      AND    hcasa.org_id            = gn_org_id;                               -- 組織ID
-- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_cust_info_expt;
    END;
    --==================================================================
    --請求顧客コードに紐づく顧客情報を取得
    --==================================================================
    BEGIN
      SELECT xhv.bill_account_id     AS bill_account_id                         -- 請求先顧客ID
      INTO   gn_bill_account_id
      FROM   xxcfr_cust_hierarchy_v  xhv                                        -- 顧客階層ビュー
      WHERE  xhv.bill_account_number = i_discnt_amount_rec.demand_to_cust_code  -- 請求顧客コード
-- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
      AND    xhv.ship_account_number = i_discnt_amount_rec.delivery_cust_code;  -- 納品顧客コード
-- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_cust_info_expt;
    END;
    --==================================================================
    --請求先顧客IDに紐づく顧客サイトIDを取得
    --==================================================================
    BEGIN
      SELECT hcasa.cust_acct_site_id AS cust_acct_site_id                       -- 顧客サイトID
      INTO   gn_bill_address_id
      FROM   hz_cust_acct_sites_all  hcasa                                      -- 顧客サイトマスタ
      WHERE  hcasa.cust_account_id   = gn_bill_account_id                       -- 請求先顧客ID
-- Start 2009/04/15 Ver_1.4 T1_0554 M.Hiruta
      AND    hcasa.org_id            = gn_org_id;                               -- 組織ID
-- End   2009/04/15 Ver_1.4 T1_0554 M.Hiruta
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_cust_info_expt;
    END;
    --==================================================================
    --支払条件に紐づく支払条件情報を取得
    --==================================================================
    BEGIN
      SELECT rtt.term_id  AS term_id                      -- 支払条件ID
      INTO   gn_term_id
      FROM   ra_terms_tl  rtt                             -- 支払条件テーブル
      WHERE  rtt.name     = i_discnt_amount_rec.term_code -- 支払条件名 = 支払条件
      AND    rtt.language = gv_language;                  -- 言語 = 'JA'
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_term_info_expt;
    END;
--
  EXCEPTION
    -- *** 伝票番号取得エラー ***
    WHEN get_slip_number_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00025_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 顧客情報取得エラー ***
    WHEN get_cust_info_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00035_err_msg
                    , cv_cust_code_token
                    , i_discnt_amount_rec.delivery_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 支払条件情報取得エラー ***
    WHEN get_term_info_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00032_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_discnt_amnt_add_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : chk_discnt_amount_ar_info_p
   * Description      : 妥当性チェックの処理(入金時値引高)(A-3)
   ***********************************************************************************/
  PROCEDURE chk_discnt_amount_ar_info_p(
    ov_errbuf           OUT VARCHAR2                    -- エラー・メッセージ
  , ov_retcode          OUT VARCHAR2                    -- リターン・コード
  , ov_errmsg           OUT VARCHAR2                    -- ユーザー・エラー・メッセージ
  , i_discnt_amount_rec IN  g_discnt_amount_cur%ROWTYPE -- レコード引数
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_discnt_amount_ar_info_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg    VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode    BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
    lb_set_of_bks BOOLEAN        DEFAULT NULL; -- 会計期間チェック戻り値
    -- ===============================
    -- ローカル例外
    -- ===============================
    chk_acctg_period_expt EXCEPTION; -- 会計期間チェックエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --会計期間チェック
    --==============================================================
    lb_set_of_bks := xxcok_common_pkg.check_acctg_period_f(
                       gn_set_of_bks_id                        -- 会計帳簿ID
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--                     , i_discnt_amount_rec.expect_payment_date -- 処理日(支払予定日)
                     , i_discnt_amount_rec.closing_date        -- 処理日(締め日)
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
                     , cv_appli_ar_name                        -- アプリケーション短縮名
                     );
    IF( lb_set_of_bks = FALSE ) THEN
      RAISE chk_acctg_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間チェックエラー ****
    WHEN chk_acctg_period_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00042_err_msg
                    , cv_proc_date_token
-- Start 2009/04/14 Ver_1.3 T1_0396 M.Hiruta
--                    , TO_CHAR( i_discnt_amount_rec.expect_payment_date, 'YYYY/MM/DD' )
                    , TO_CHAR( i_discnt_amount_rec.closing_date, 'YYYY/MM/DD' )
-- End   2009/04/14 Ver_1.3 T1_0396 M.Hiruta
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_discnt_amount_ar_info_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discnt_amount_ar_data_p
   * Description      : AR連携データの取得(入金時値引高)(A-2)
   ***********************************************************************************/
  PROCEDURE get_discnt_amount_ar_data_p(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_discnt_amount_ar_data_p'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    <<ar_coordination_data_loop>>
    FOR g_discnt_amount_rec IN g_discnt_amount_cur LOOP
      --================================================================
      --入金時値引の抽出件数
      --================================================================
      gn_target_cnt :=  gn_target_cnt + 1;
      --================================================================
      --chk_discnt_amount_ar_info_pの呼び出し(A-3)
      --================================================================
      chk_discnt_amount_ar_info_p(
        ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
      , i_discnt_amount_rec    => g_discnt_amount_rec
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --================================================================
      --get_discnt_amnt_add_ar_data_pの呼び出し(A-4)
      --================================================================
      get_discnt_amnt_add_ar_data_p(
        ov_errbuf              => lv_errbuf
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg
      , i_discnt_amount_rec    => g_discnt_amount_rec
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --================================================================
      --ins_discnt_amount_ar_data_pの呼び出し(A-5)
      --================================================================
      ins_discnt_amount_ar_data_p(
        ov_errbuf              => lv_errbuf 
      , ov_retcode             => lv_retcode
      , ov_errmsg              => lv_errmsg 
      , i_discnt_amount_rec    => g_discnt_amount_rec 
      );
--
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP ar_coordination_data_loop;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_discnt_amount_ar_data_p;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode     BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
    lv_token_value VARCHAR2(5000) DEFAULT NULL; -- トークンバリュー
    -- ===============================
    -- ローカル例外
    -- ===============================
    profile_expt        EXCEPTION; -- プロファイル取得エラー
    operation_date_expt EXCEPTION; -- 業務処理日付取得エラー
    get_trx_type_expt   EXCEPTION; -- 取引タイプ情報取得エラー
    currency_code_expt  EXCEPTION; -- 通貨コード取得エラー
-- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    CURSOR l_cust_trx_type_cur(
--      iv_cust_trx_type IN VARCHAR2
--    )
--    IS
--      SELECT rctta.cust_trx_type_id AS cust_trx_type_id --取引タイプID
--      FROM   ra_cust_trx_types_all  rctta               --請求取引タイプマスタ
--      WHERE  rctta.name             = iv_cust_trx_type  --仕訳ソース名 = 初期処理で取得した取引タイプ
--      AND    rctta.org_id           = gn_org_id         --組織ID       = 組織ID
--      AND    gd_operation_date  BETWEEN rctta.start_date AND NVL( rctta.end_date, gd_operation_date );
-- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --コンカレント入力パラメータなし項目をメッセージ出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90008_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    --==============================================================
    --業務処理日付を取得
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
    --==============================================================
    --プロファイルを取得
    --==============================================================
    gn_set_of_bks_id           := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id )); -- 会計帳簿ID
    gn_org_id                  := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id        )); -- 組織ID
    gv_aff1_company_code       := FND_PROFILE.VALUE( cv_aff1_company_code       );  -- 会社コード
    gv_aff2_dept_fin           := FND_PROFILE.VALUE( cv_aff2_dept_fin           );  -- 部門コード：財務経理部
    gv_aff5_customer_dummy     := FND_PROFILE.VALUE( cv_aff5_customer_dummy     );  -- ダミー値:顧客コード
    gv_aff6_compuny_dummy      := FND_PROFILE.VALUE( cv_aff6_compuny_dummy      );  -- ダミー値:企業コード
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );  -- ダミー値:予備１
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );  -- ダミー値:予備２
    gv_aff3_allowance_payment  := FND_PROFILE.VALUE( cv_aff3_allowance_payment  );  -- 勘定科目:入金時値引高
    gv_aff3_payment_excise_tax := FND_PROFILE.VALUE( cv_aff3_payment_excise_tax );  -- 勘定科目:仮払消費税等
    gv_aff3_receivable         := FND_PROFILE.VALUE( cv_aff3_receivable         );  -- 勘定科目:未収入金
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );  -- 勘定科目:売掛金
    gv_aff4_receivable_vd      := FND_PROFILE.VALUE( cv_aff4_receivable_vd      );  -- 補助科目:未収入金VD売上
    gv_aff4_subacct_dummy      := FND_PROFILE.VALUE( cv_aff4_subacct_dummy      );  -- 補助科目:ダミー値
    gv_sales_category          := FND_PROFILE.VALUE( cv_sales_category          );  -- 販売手数料:仕訳カテゴリ
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--    gv_cust_trx_type_vd        := FND_PROFILE.VALUE( cv_cust_trx_type_vd        );  -- 取引タイプ:VD未収入金売上
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    gv_cust_trx_type_elec_cost := FND_PROFILE.VALUE( cv_cust_trx_type_elec_cost );  -- 取引タイプ:電気料相殺
--    gv_cust_trx_type_gnrl      := FND_PROFILE.VALUE( cv_cust_trx_type_gnrl      );  -- 取引タイプ:入金値引高
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    gv_ra_trx_type_f_digestion_vd := FND_PROFILE.VALUE( cv_ra_trx_type_f_digestion_vd  );  -- 取引タイプ_入金値引_フルVD（消化）
    gv_ra_trx_type_delivery_vd    := FND_PROFILE.VALUE( cv_ra_trx_type_delivery_vd     );  -- 取引タイプ_入金値引_納品VD
    gv_ra_trx_type_digestion_vd   := FND_PROFILE.VALUE( cv_ra_trx_type_digestion_vd    );  -- 取引タイプ_入金値引_消化VD
    gv_ra_trx_type_general        := FND_PROFILE.VALUE( cv_ra_trx_type_general         );  -- 取引タイプ_入金値引_一般店
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
--
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := cv_set_of_bks_id;
      RAISE profile_expt;
--
    ELSIF( gn_org_id IS NULL ) THEN
      lv_token_value := cv_org_id;
      RAISE profile_expt;
--
    ELSIF( gv_aff1_company_code IS NULL ) THEN
      lv_token_value := cv_aff1_company_code;
      RAISE profile_expt;
--
    ELSIF( gv_aff2_dept_fin IS NULL ) THEN
      lv_token_value := cv_aff2_dept_fin;
      RAISE profile_expt;
--
    ELSIF( gv_aff5_customer_dummy IS NULL ) THEN
      lv_token_value := cv_aff5_customer_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff6_compuny_dummy IS NULL ) THEN
      lv_token_value := cv_aff6_compuny_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff7_preliminary1_dummy IS NULL ) THEN
      lv_token_value := cv_aff7_preliminary1_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff8_preliminary2_dummy IS NULL ) THEN
      lv_token_value := cv_aff8_preliminary2_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_allowance_payment IS NULL ) THEN
      lv_token_value := cv_aff3_allowance_payment;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_payment_excise_tax IS NULL ) THEN
      lv_token_value := cv_aff3_payment_excise_tax;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_receivable IS NULL ) THEN
      lv_token_value := cv_aff3_receivable;
      RAISE profile_expt;
--
    ELSIF( gv_aff3_account_receivable IS NULL ) THEN
      lv_token_value := cv_aff3_account_receivable;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_subacct_dummy IS NULL ) THEN
      lv_token_value := cv_aff4_subacct_dummy;
      RAISE profile_expt;
--
    ELSIF( gv_aff4_receivable_vd IS NULL ) THEN
      lv_token_value := cv_aff4_receivable_vd;
      RAISE profile_expt;
--
    ELSIF( gv_sales_category IS NULL ) THEN
      lv_token_value := cv_sales_category;
      RAISE profile_expt;
--
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
--    ELSIF( gv_cust_trx_type_vd IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_vd;
--      RAISE profile_expt;
----      
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    ELSIF( gv_cust_trx_type_elec_cost IS NULL ) THEN
----      lv_token_value := cv_cust_trx_type_elec_cost;
----      RAISE profile_expt;
--    ELSIF( gv_cust_trx_type_gnrl IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_gnrl;
--      RAISE profile_expt;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----
    -- 取引タイプ_入金値引_フルVD（消化）
    ELSIF( gv_ra_trx_type_f_digestion_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_f_digestion_vd;
      RAISE profile_expt;
    -- 取引タイプ_入金値引_納品VD
    ELSIF( gv_ra_trx_type_delivery_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_delivery_vd;
      RAISE profile_expt;
    -- 取引タイプ_入金値引_消化VD
    ELSIF( gv_ra_trx_type_digestion_vd IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_digestion_vd;
      RAISE profile_expt;
    -- 取引タイプ_入金値引_一般店
    ELSIF( gv_ra_trx_type_general IS NULL ) THEN
      lv_token_value := cv_ra_trx_type_general;
      RAISE profile_expt;
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
    END IF;
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR START
---- Start 2009/04/24 Ver_1.6 T1_0736 M.Hiruta
----    --==============================================================
----    --VD未収入金売上の取引タイプIDを取得
----    --==============================================================    
----    OPEN l_cust_trx_type_cur(
----           gv_cust_trx_type_vd -- VD未収入金売上の取引タイプ
----         );
----    FETCH l_cust_trx_type_cur INTO gn_vd_trx_type_id;
----    CLOSE l_cust_trx_type_cur;
----    IF( gn_vd_trx_type_id IS NULL ) THEN
----      lv_token_value := gv_cust_trx_type_vd;
----      RAISE get_trx_type_expt;
----    END IF;
----    --==============================================================
----    --電気料相殺の取引タイプIDを取得
----    --==============================================================    
----    OPEN l_cust_trx_type_cur(
----           gv_cust_trx_type_elec_cost -- 電気料相殺の取引タイプ
----         );
----    FETCH l_cust_trx_type_cur INTO gn_cust_trx_elec_id;
----    CLOSE l_cust_trx_type_cur;
----    IF( gn_cust_trx_elec_id IS NULL ) THEN
----      lv_token_value := gv_cust_trx_type_elec_cost;
----      RAISE get_trx_type_expt;
----    END IF;
--    --==============================================================
--    --VD未収入金売上の取引タイプ情報を取得
--    --==============================================================
--    OPEN g_cust_trx_type_cur(
--           gv_cust_trx_type_vd -- VD未収入金売上の取引タイプ
--         );
--    FETCH g_cust_trx_type_cur INTO g_cust_trx_type_vd;
--    CLOSE g_cust_trx_type_cur;
--    IF( g_cust_trx_type_vd.cust_trx_type_id IS NULL ) THEN
--      lv_token_value := gv_cust_trx_type_vd;
--      RAISE get_trx_type_expt;
--    END IF;
--    --==============================================================
--    --入金値引高の取引タイプ情報を取得
--    --==============================================================
--    OPEN g_cust_trx_type_cur(
--           gv_cust_trx_type_gnrl -- 入金値引高の取引タイプ
--         );
--    FETCH g_cust_trx_type_cur INTO g_cust_trx_type_gnrl;
--    CLOSE g_cust_trx_type_cur;
--    IF( g_cust_trx_type_gnrl.cust_trx_type_id IS NULL ) THEN
--      lv_token_value := cv_cust_trx_type_gnrl;
--      RAISE get_trx_type_expt;
--    END IF;
---- End   2009/04/24 Ver_1.6 T1_0736 M.Hiruta
    --==============================================================
    -- 取引タイプ情報を取得（フルVD（消化））
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_f_digestion_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_f_digestion_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_f_digestion_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_f_digestion_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- 取引タイプ情報を取得（納品VD）
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_delivery_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_delivery_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_delivery_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_delivery_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- 取引タイプ情報を取得（消化VD）
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_digestion_vd
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_digestion_vd;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_digestion_vd.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_digestion_vd;
      RAISE get_trx_type_expt;
    END IF;
    --==============================================================
    -- 取引タイプ情報を取得（一般店）
    --==============================================================
    OPEN g_cust_trx_type_cur(
           gv_ra_trx_type_general
         );
    FETCH g_cust_trx_type_cur INTO g_ra_trx_type_general;
    CLOSE g_cust_trx_type_cur;
    IF( g_ra_trx_type_general.cust_trx_type_id IS NULL ) THEN
      lv_token_value := gv_ra_trx_type_general;
      RAISE get_trx_type_expt;
    END IF;
-- 2009/10/05 Ver.1.7 [仕様変更I_E_566] SCS K.Yamaguchi REPAIR END
    --==============================================================
    --通貨コードの取得
    --==============================================================
    BEGIN
      SELECT gsob.currency_code   AS currency_code    -- 機能通貨コード
      INTO   gv_currency_code
      FROM   gl_sets_of_books     gsob                -- 会計帳簿マスタ
      WHERE  gsob.set_of_books_id = gn_set_of_bks_id; -- 会計帳簿ID = 上記で取得した帳簿ID
--
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RAISE currency_code_expt;
    END;
    --==============================================================
    --言語を取得
    --==============================================================
    gv_language := USERENV( cv_language );
--
  EXCEPTION
    -- *** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00003_err_msg
                    , cv_profile_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 業務処理日付取得エラー ***
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00028_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 取引タイプ情報取得エラー ***
    WHEN get_trx_type_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00090_err_msg
                    , cv_cust_trx_type_token
                    , lv_token_value
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 通貨コード取得エラー ***
    WHEN currency_code_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00029_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(5000) DEFAULT NULL; -- メッセージ変数
    lb_retcode BOOLEAN        DEFAULT NULL; -- メッセージ出力戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    --==============================================================
    --init(初期処理(A-1))の呼び出し
    --==============================================================
    init(
      ov_errbuf  => lv_errbuf      -- エラー・メッセージ
    , ov_retcode => lv_retcode     -- リターン・コード
    , ov_errmsg  => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --get_discnt_amount_ar_data_p(AR連携データの取得(入金時値引高)(A-2))の呼び出し
    --==============================================================
    get_discnt_amount_ar_data_p(
      ov_errbuf  => lv_errbuf      -- エラー・メッセージ
    , ov_retcode => lv_retcode     -- リターン・コード
    , ov_errmsg  => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --upd_ coordination_result_p(連携結果の更新(A-8))の呼び出し
    --==============================================================
    upd_coordination_result_p(
      ov_errbuf  => lv_errbuf      -- エラー・メッセージ
    , ov_retcode => lv_retcode     -- リターン・コード
    , ov_errmsg  => lv_errmsg      -- ユーザー・エラー・メッセージ
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT VARCHAR2 --エラー・メッセージ
  , retcode OUT VARCHAR2 --リターン・コード
  )
  IS
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100)  DEFAULT NULL; -- メッセージコード
    lv_out_msg      VARCHAR2(5000) DEFAULT NULL; -- メッセージ出力変数
    lb_retcode      BOOLEAN        DEFAULT NULL; -- メッセージ出力変数
--
  BEGIN
    --================================================================
    --コンカレントヘッダメッセージ出力関数の呼び出し
    --================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
    ,  ov_retcode => lv_retcode -- リターン・コード
    ,  ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
    --================================================================
    --エラー出力
    --================================================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_errmsg          -- メッセージ
                    , 1                  -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.LOG       -- 出力区分
                    , lv_errbuf          -- メッセージ
                    , 0                  -- 改行
                    );
    END IF;
    --================================================================
    --対象件数出力
    --================================================================
    IF( gn_target_cnt = 0 )
      AND ( lv_retcode = cv_status_normal ) THEN
      -- *** AR連携情報取得エラーメッセージ ***
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                    , cv_00058_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
    END IF;
--
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_90000_msg
                    , cv_count_token
                    , TO_CHAR( gn_target_cnt )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
    -- ===============================================
    --成功件数出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90001_msg
                  , cv_count_token
                  , TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , cv_90002_msg
                  , cv_count_token
                  , TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    -- ===============================================
    -- 終了メッセージ
    -- ===============================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_90004_msg;
      retcode         := cv_status_normal;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_90006_msg;
      retcode         := cv_status_error;
    END IF;
    --
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appli_xxccp_name
                  , lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 0                  -- 改行
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf     := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode    := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK018A01C;
/
