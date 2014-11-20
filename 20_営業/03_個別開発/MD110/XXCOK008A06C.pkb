CREATE OR REPLACE PACKAGE BODY XXCOK008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A06C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : 売上実績振替情報の作成（振替割合） MD050_COK_008_A06
 * Version          : 2.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 * update_xsti                  伝票番号更新(A-8)
 * insert_xsti                  売上振替情報の登録(A-6)(A-7)
 * selling_to_loop              売上振替先情報ループ(A-4)
 * selling_from_loop            売上振替元情報ループ(A-3)
 * make_correction              振り戻しデータ作成(A-2)
 * init                         初期処理(A-1)
 * submain                      メイン処理プロシージャ
 * main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   M.Hiruta         新規作成
 *  2009/02/18    1.1   T.OSADA          [障害COK_042]振戻データ作成時の情報系I/Fフラグ、仕訳作成フラグ修正
 *  2009/04/02    1.2   M.Hiruta         [障害T1_0089]振替元と先が同じ顧客である場合も、集計処理を行うよう修正
 *                                       [障害T1_0103]担当拠点、担当営業員が変更された場合の情報が
 *                                                    正確に取得できるよう修正
 *                                       [障害T1_0115]販売実績テーブル抽出時の絞込み条件において、
 *                                                    「検収日」を「納品日」に修正
 *                                       [障害T1_0190]基準単位換算失敗時にエラー終了するよう修正
 *                                       [障害T1_0196]販売実績テーブル抽出時の絞込み条件において、
 *                                                    1.A-5集計条件「納品日」の精度を"年月"までに修正
 *                                                    2.A-6、A-11集計条件「売上計上日」でA-5で取得した「納品日」の
 *                                                      の年月を参照するよう修正
 *  2009/04/27    1.3   M.Hiruta         [障害T1_0715]振替元となるデータのうち数量が1のデータにおいて、
 *                                                    1.振替割合が偏っている場合、振替割合の大きいデータへ
 *                                                      金額を寄せるよう修正
 *                                                    2.振替割合が均等である場合、顧客コードの若いレコードへ
 *                                                      金額を寄せるよう修正
 *  2009/06/04    1.4   M.Hiruta         [障害T1_1325]振戻データ作成処理で作成されるデータの日付を、
 *                                                    振戻対象データの日付に基づいて取得するよう変更
 *                                                    1.振戻データが先月データである場合⇒先月末日付
 *                                                    2.振戻データが当月データである場合⇒業務処理日付
 *  2009/07/03    1.5   M.Hiruta         [障害0000422]振戻データ作成処理で作成される業務登録日付を、
 *                                                    業務処理日付へ変更
 *  2009/07/13    1.6   M.Hiruta         [障害0000514]処理対象に顧客ステータス「30:承認済」「50:休止」のデータを追加
 *  2009/08/24    1.7   M.Hiruta         [障害0001152]顧客名を格納する変数の宣言をTYPE型へ変更
 *  2009/08/13    2.0   K.Yamaguchi      [障害0000952]パフォーマンス改善（再作成）
 *  2009/09/28    2.1   K.Yamaguchi      [E_T3_00590]振替割合が100％でない場合の対応
 *                                                   納品数量がゼロの場合の対応
 *  2009/10/15    2.2   S.Moriyama       [E_T3_00632]売上実績振替情報登録時に売上振替元顧客コードを設定するように変更
 *
 *****************************************************************************************/
  --==================================================
  -- グローバル定数
  --==================================================
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK008A06C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- 言語
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';
  cv_msg_cok_00045                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00045';
  cv_msg_cok_10012                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10012';
  cv_msg_cok_10033                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10033';
  cv_msg_cok_10034                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10034';
  cv_msg_cok_10035                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10035';
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';
  cv_msg_cok_10452                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10452';
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
  cv_msg_cok_10463                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10463';
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
  -- トークン
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_customer_code             CONSTANT VARCHAR2(30)    := 'CUSTOMER_CODE';
  cv_tkn_customer_name             CONSTANT VARCHAR2(30)    := 'CUSTOMER_NAME';
  cv_tkn_dlv_uom_code              CONSTANT VARCHAR2(30)    := 'DLV_UOM_CODE';
  cv_tkn_from_customer_code        CONSTANT VARCHAR2(30)    := 'FROM_CUSTOMER_CODE';
  cv_tkn_from_location_code        CONSTANT VARCHAR2(30)    := 'FROM_LOCATION_CODE';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_location_code             CONSTANT VARCHAR2(30)    := 'LOCATION_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_rate                      CONSTANT VARCHAR2(30)    := 'RATE';
  cv_tkn_rate_total                CONSTANT VARCHAR2(30)    := 'RATE_TOTAL';
  cv_tkn_sales_date                CONSTANT VARCHAR2(30)    := 'SALES_DATE';
  cv_tkn_tanto_code                CONSTANT VARCHAR2(30)    := 'TANTO_CODE';
  cv_tkn_tanto_loc_code            CONSTANT VARCHAR2(30)    := 'TANTO_LOC_CODE';
  cv_tkn_to_customer_code          CONSTANT VARCHAR2(30)    := 'TO_CUSTOMER_CODE';
  cv_tkn_to_location_code          CONSTANT VARCHAR2(30)    := 'TO_LOCATION_CODE';
  -- セパレータ
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- 会計帳簿ID
  -- 共通関数メッセージ出力区分
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- 入力パラメータ・情報種別
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- 速報
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- 確定
  -- 顧客区分
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- 顧客
  -- 顧客ステータス
  cv_customer_status_30            CONSTANT VARCHAR2(2)     := '30'; -- 承認済
  cv_customer_status_40            CONSTANT VARCHAR2(2)     := '40'; -- 顧客
  cv_customer_status_50            CONSTANT VARCHAR2(2)     := '50'; -- 休止
  -- 顧客追加情報・売上実績振替
  cv_xca_transfer_div_on           CONSTANT VARCHAR2(1)     := '1';  -- 実績振替あり
  -- 顧客使用目的
  cv_site_use_code_ship            CONSTANT VARCHAR2(10)    := 'SHIP_TO'; -- 出荷先
  cv_site_use_code_bill            CONSTANT VARCHAR2(10)    := 'BILL_TO'; -- 請求先
  -- 販売実績・納品伝票区分
  cv_invoice_class_01              CONSTANT VARCHAR2(1)     := '1';  -- 納品
  cv_invoice_class_02              CONSTANT VARCHAR2(1)     := '2';  -- 返品
  cv_invoice_class_03              CONSTANT VARCHAR2(1)     := '3';  -- 納品訂正
  cv_invoice_class_04              CONSTANT VARCHAR2(1)     := '4';  -- 返品訂正
  -- 売上実績振替情報テーブル・振り戻しフラグ
  cv_xsti_correction_flag_off      CONSTANT VARCHAR2(1)     := '0';  -- オフ
  cv_xsti_correction_flag_on       CONSTANT VARCHAR2(1)     := '1';  -- オン
  -- 売上実績振替情報テーブル・速報確定フラグ
  cv_xsti_decision_flag_news       CONSTANT VARCHAR2(1)     := '0';  -- 速報
  -- 売上実績振替情報テーブル・情報系IFフラグ
  cv_xsti_info_if_flag_no          CONSTANT VARCHAR2(1)     := '0';  -- IF未済
  -- 売上実績振替情報テーブル・仕訳作成フラグ
  cv_xsti_gl_if_flag_no            CONSTANT VARCHAR2(1)     := '0';  -- 仕訳作成未済
  -- 無効フラグ
  cv_invalid_flag_valid            CONSTANT VARCHAR2(1)     := '0';  -- 有効
  -- 実勢振替区分
  cv_selling_trns_type_trns        CONSTANT VARCHAR2(1)     := '0';  -- 振替割合
  -- 売上区分
  cv_selling_type_normal           CONSTANT VARCHAR2(1)     := '1';  -- 通常
  -- 売上返品区分
  cv_selling_return_type_dlv       CONSTANT VARCHAR2(1)     := '1';  -- 納品
  -- 納品伝票区分
  cv_delivery_slip_type_dlv        CONSTANT VARCHAR2(1)     := '1';  -- 納品
  -- 納品携帯区分
  cv_delivery_form_type_trns       CONSTANT VARCHAR2(1)     := '6';  -- 実績振替
  -- 物件コード
  cv_article_code_dummy            CONSTANT VARCHAR2(10)    := '0000000000'; -- ダミー物件コード
  -- カード売り区分
  cv_card_selling_type_cash        CONSTANT VARCHAR2(1)     := '0';  -- 現金
  -- Ｈ＆Ｃ
  cv_hc_cold                       CONSTANT VARCHAR2(1)     := '1';  -- COLD
  -- コラムNo
  cv_column_no                     CONSTANT VARCHAR2(2)     := '00'; -- ダミーコラムNO
  --==================================================
  -- グローバル変数
  --==================================================
  -- カウンタ
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- スキップ件数
  -- 入力パラメータ
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- 情報種別
  -- 初期処理取得値
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- 会計帳簿ID
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gd_target_date_from              DATE          DEFAULT NULL;   -- 振替対象期間（From）
  gd_target_date_to                DATE          DEFAULT NULL;   -- 振替対象期間（To）
  gt_selling_trns_info_id_min      xxcok_selling_trns_info.selling_trns_info_id%TYPE DEFAULT NULL; -- 売上振替情報登録最小ID
  --==================================================
  -- 共通例外
  --==================================================
  --*** 処理部共通例外 ***
  global_process_expt              EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                  EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロック取得エラー ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
  --*** 警告スキップ ***
  warning_skip_expt                EXCEPTION;
  --==================================================
  -- グローバルカーソル
  --==================================================
  -- 売上振替元情報取得
  CURSOR get_selling_from_cur
  IS
    SELECT /*+
               LEADING(xsfi, ship_hca, ship_hcas)
               INDEX(ship_hca hz_cust_accounts_u2)
            */
           CASE
             WHEN   TRUNC( xseh.delivery_date, 'MM' )
                  = TRUNC( gd_process_date   , 'MM' )
             THEN
               gd_target_date_to
             ELSE
               LAST_DAY( gd_target_date_from )
           END                                                          AS selling_date             -- 売上計上日
         , xseh.sales_base_code                                         AS sales_base_code          -- 売上振替元拠点コード
         , xseh.ship_to_customer_code                                   AS ship_cust_code           -- 売上振替元顧客コード
         , ship_hp.party_name                                           AS ship_party_name          -- 売上振替元顧客名
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , CASE
               WHEN   TRUNC( xseh.delivery_date, 'MM' )
                    = TRUNC( gd_process_date   , 'MM' )
               THEN
                 gd_target_date_to
               ELSE
                 LAST_DAY( gd_target_date_from )
             END
           )                                                            AS sales_staff_code         -- 売上振替元担当営業コード
         , xseh.cust_gyotai_sho                                         AS ship_cust_gyotai_sho     -- 業態（小分類）
         , bill_hca.account_number                                      AS bill_cust_code           -- 請求先顧客コード
         , xsel.item_code                                               AS item_code                -- 品目コード
         , ROUND( SUM( xsel.dlv_qty ), 0 )                              AS dlv_qty_sum              -- 納品数量
         , xsel.dlv_uom_code                                            AS dlv_uom_code             -- 納品単位
         , ROUND( SUM( xsel.sale_amount ), 0 )                          AS sales_amount_sum         -- 売上金額
         , ROUND( SUM( xsel.pure_amount ), 0 )                          AS pure_amount_sum          -- 本体金額
         , ROUND( SUM(   xsel.business_cost
                       * xxcok_common_pkg.get_uom_conversion_qty_f(
                           xsel.item_code
                         , xsel.dlv_uom_code
                         , xsel.dlv_qty
                         )
                  )
                , 0
           )                                                            AS sales_cost_sum           -- 売上原価
         , xseh.tax_code                                                AS tax_code                 -- 税金コード
         , xseh.tax_rate                                                AS tax_rate                 -- 消費税率
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
         , xsel.dlv_unit_price                                          AS dlv_unit_price           -- 納品単価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
    FROM xxcok_selling_from_info   xsfi             -- 売上振替元情報
       , hz_cust_accounts          ship_hca         -- 【出荷先】顧客マスタ
       , xxcmm_cust_accounts       ship_xca         -- 【出荷先】顧客追加情報
       , hz_cust_acct_sites        ship_hcas        -- 【出荷先】顧客所在地
       , hz_parties                ship_hp          -- 【出荷先】顧客パーティ
       , hz_party_sites            ship_hps         -- 【出荷先】顧客パーティサイト
       , hz_cust_site_uses         ship_hcsu        -- 【出荷先】顧客使用目的
       , hz_cust_site_uses         bill_hcsu        -- 【請求先】顧客使用目的
       , hz_cust_acct_sites        bill_hcas        -- 【請求先】顧客所在地
       , hz_cust_accounts          bill_hca         -- 【請求先】顧客マスタ
       , xxcos_sales_exp_headers   xseh             -- 販売実績ヘッダー
       , xxcos_sales_exp_lines     xsel             -- 販売実績明細
    WHERE xsfi.selling_from_cust_code       = ship_hca.account_number
      AND ship_hca.customer_class_code      = cv_customer_class_customer
      AND ship_hca.cust_account_id          = ship_xca.customer_id
      AND ship_xca.selling_transfer_div     = cv_xca_transfer_div_on
      AND ship_xca.chain_store_code        IS NULL
      AND ship_hca.cust_account_id          = ship_hcas.cust_account_id
      AND ship_hca.party_id                 = ship_hp.party_id
      AND ship_hp.duns_number_c            IN (   cv_customer_status_30
                                                , cv_customer_status_40
                                                , cv_customer_status_50
                                              )
      AND ship_hp.party_id                  = ship_hps.party_id
      AND ship_hcas.party_site_id           = ship_hps.party_site_id
      AND ship_hcas.cust_acct_site_id       = ship_hcsu.cust_acct_site_id
      AND ship_hcsu.site_use_code           = cv_site_use_code_ship
      AND ship_hcsu.bill_to_site_use_id     = bill_hcsu.site_use_id
      AND bill_hcsu.site_use_code           = cv_site_use_code_bill
      AND bill_hcsu.cust_acct_site_id       = bill_hcas.cust_acct_site_id
      AND bill_hcas.cust_account_id         = bill_hca.cust_account_id
      AND xsfi.selling_from_base_code       = xseh.sales_base_code
      AND xsfi.selling_from_cust_code       = xseh.ship_to_customer_code
      AND xseh.delivery_date          BETWEEN gd_target_date_from
                                          AND gd_target_date_to
      AND xseh.dlv_invoice_class           IN (   cv_invoice_class_01
                                                , cv_invoice_class_02
                                                , cv_invoice_class_03
                                                , cv_invoice_class_04
                                              )
      AND xseh.sales_exp_header_id          = xsel.sales_exp_header_id
      AND xsel.business_cost               IS NOT NULL
      AND EXISTS ( SELECT 'X'
                   FROM xxcok_selling_to_info        xsti
                      , xxcok_selling_rate_info      xsri
                      , hz_cust_accounts             hca
                      , xxcmm_cust_accounts          xca
                      , hz_parties                   hp
                   WHERE xsti.selling_from_info_id       = xsfi.selling_from_info_id
                     AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                     AND xsti.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti.invalid_flag               = cv_invalid_flag_valid
                     AND xsri.selling_from_base_code     = xsfi.selling_from_base_code
                     AND xsri.selling_from_cust_code     = ship_hca.account_number
                     AND xsri.invalid_flag               = cv_invalid_flag_valid
                     AND xsti.selling_to_cust_code       = hca.account_number
                     AND hca.customer_class_code         = cv_customer_class_customer
                     AND hca.cust_account_id             = xca.customer_id
                     AND xca.selling_transfer_div        = cv_xca_transfer_div_on
                     AND xca.chain_store_code           IS NULL
                     AND hca.party_id                    = hp.party_id
                     AND hp.duns_number_c               IN (   cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                           )
                     AND ROWNUM                          = 1
          )
  GROUP BY CASE
             WHEN   TRUNC( xseh.delivery_date, 'MM' )
                  = TRUNC( gd_process_date   , 'MM' )
             THEN
               gd_target_date_to
             ELSE
               LAST_DAY( gd_target_date_from )
           END
         , xseh.sales_base_code
         , xseh.ship_to_customer_code
         , ship_hp.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , CASE
               WHEN   TRUNC( xseh.delivery_date, 'MM' )
                    = TRUNC( gd_process_date   , 'MM' )
               THEN
                 gd_target_date_to
               ELSE
                 LAST_DAY( gd_target_date_from )
             END
           )
         , xseh.cust_gyotai_sho
         , bill_hca.account_number
         , xsel.item_code
         , xsel.dlv_uom_code
         , xseh.tax_code
         , xseh.tax_rate
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--         -- 販売実績明細の売上金額÷販売数量（単価）が違う場合は別レコードとする
--         , ( xsel.sale_amount / xsel.dlv_qty )
         , xsel.dlv_unit_price
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--  HAVING ROUND( SUM( xsel.dlv_qty ), 0 ) <> 0
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
  ;
  -- 売上振替先情報取得
  CURSOR get_selling_to_cur(
    it_base_code              IN  xxcok_selling_rate_info.selling_from_base_code%TYPE
  , it_cust_code              IN  xxcok_selling_rate_info.selling_from_cust_code%TYPE
  , id_selling_date           IN  DATE
  )
  IS
    SELECT CASE
             WHEN   TRUNC( id_selling_date, 'MM' )
                  = TRUNC( gd_process_date, 'MM' )
             THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS selling_to_base_code       -- 売上振替先売上拠点コード
         , xsri.selling_to_cust_code              AS selling_to_cust_code       -- 売上振替先顧客コード
         , hp.party_name                          AS party_name                 -- 売上振替先顧客名
         , xsri.selling_trns_rate                 AS selling_trns_rate          -- 売上振替割合
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsri.selling_to_cust_code
           , id_selling_date
           )                                      AS sales_staff_code           -- 売上振替先担当営業コード
    FROM xxcok_selling_rate_info        xsri
       , hz_cust_accounts               hca
       , xxcmm_cust_accounts            xca
       , hz_parties                     hp
    WHERE xsri.selling_from_base_code   = it_base_code
      AND xsri.selling_from_cust_code   = it_cust_code
      AND xsri.invalid_flag             = cv_invalid_flag_valid
      AND EXISTS ( SELECT /*+ LEADING( xsfi,xsti ) */
                          'X'
                   FROM xxcok_selling_from_info    xsfi
                      , xxcok_selling_to_info      xsti
                   WHERE xsfi.selling_from_base_code     = xsri.selling_from_base_code
                     AND xsfi.selling_from_cust_code     = xsri.selling_from_cust_code
                     AND xsfi.selling_from_info_id       = xsti.selling_from_info_id
                     AND xsti.selling_to_cust_code       = xsri.selling_to_cust_code
                     AND xsti.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti.invalid_flag               = cv_invalid_flag_valid
                     AND ROWNUM                          = 1
          )
      AND hca.account_number            = xsri.selling_to_cust_code
      AND hca.customer_class_code       = cv_customer_class_customer
      AND xca.customer_id               = hca.cust_account_id
      AND xca.chain_store_code         IS NULL
      AND xca.selling_transfer_div      = cv_xca_transfer_div_on
      AND hp.party_id                   = hca.party_id
      AND hp.duns_number_c             IN (   cv_customer_status_30
                                            , cv_customer_status_40
                                            , cv_customer_status_50
                                          )
  ORDER BY xsri.selling_trns_rate       ASC
         , xsri.selling_to_cust_code    DESC
  ;
  TYPE get_selling_to_ttype        IS TABLE OF get_selling_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : update_xsti
   * Description      : 伝票番号更新(A-8)
   ***********************************************************************************/
  PROCEDURE update_xsti(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xsti';             -- プログラム名
    cv_slip_no_prefix              CONSTANT VARCHAR2(1)  := 'J';                       -- 伝票番号接頭語
    cv_slip_no_format              CONSTANT VARCHAR2(10) := 'FM00000000';              -- 伝票番号接頭語以下桁数
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- ブレイク判定用変数
    lt_break_selling_date          xxcok_selling_trns_info.selling_date%TYPE DEFAULT NULL;        -- 
    lt_break_demand_to_cust_code   xxcok_selling_trns_info.demand_to_cust_code%TYPE DEFAULT NULL; -- 振替元顧客コード
    lt_break_base_code             xxcok_selling_trns_info.base_code%TYPE DEFAULT NULL;           -- 拠点コード
    lt_break_cust_code             xxcok_selling_trns_info.cust_code%TYPE DEFAULT NULL;           -- 顧客コード
    lt_break_item_code             xxcok_selling_trns_info.item_code%TYPE DEFAULT NULL;           -- 品目コード
    -- 更新値用変数
    lt_slip_no                     xxcok_selling_trns_info.slip_no  %TYPE DEFAULT NULL; -- 伝票番号
    lt_detail_no                   xxcok_selling_trns_info.detail_no%TYPE DEFAULT NULL; -- 明細番号
    --==================================================
    -- ロック取得カーソル
    --==================================================
    CURSOR update_xsti_cur
    IS
      SELECT xsti.selling_trns_info_id       AS selling_trns_info_id
           , xsti.selling_date               AS selling_date
           , xsti.demand_to_cust_code        AS demand_to_cust_code
           , xsti.base_code                  AS base_code
           , xsti.cust_code                  AS cust_code
           , xsti.item_code                  AS item_code
           , xsti.delivery_unit_price        AS delivery_unit_price
      FROM xxcok_selling_trns_info      xsti
      WHERE xsti.selling_trns_info_id >= gt_selling_trns_info_id_min
        AND xsti.request_id            = cn_request_id
        AND xsti.slip_no              IS NULL
        AND xsti.detail_no            IS NULL
      ORDER BY xsti.selling_date
             , xsti.demand_to_cust_code
             , xsti.base_code
             , xsti.cust_code
             , xsti.item_code
             , xsti.delivery_unit_price
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 売上振替情報の登録
    --==================================================
    << update_xsti_loop >>
    FOR update_xsti_rec IN update_xsti_cur LOOP
      --==================================================
      -- ブレイク判定
      --==================================================
      IF(    ( lt_slip_no IS NULL )
          OR ( update_xsti_rec.selling_date        <> lt_break_selling_date        )
          OR ( update_xsti_rec.demand_to_cust_code <> lt_break_demand_to_cust_code )
          OR ( update_xsti_rec.base_code           <> lt_break_base_code           )
          OR ( update_xsti_rec.cust_code           <> lt_break_cust_code           )
          OR ( update_xsti_rec.item_code           <> lt_break_item_code           )
      ) THEN
        --==================================================
        -- 伝票番号取得
        --==================================================
        SELECT cv_slip_no_prefix || TO_CHAR( xxcok_selling_trns_info_s02.NEXTVAL, cv_slip_no_format )
        INTO lt_slip_no
        FROM DUAL
        ;
        --==================================================
        -- 明細番号初期化
        --==================================================
        lt_detail_no := 0;
        --==================================================
        -- ブレイク判定用項目退避
        --==================================================
        lt_break_selling_date        := update_xsti_rec.selling_date;
        lt_break_demand_to_cust_code := update_xsti_rec.demand_to_cust_code;
        lt_break_base_code           := update_xsti_rec.base_code;
        lt_break_cust_code           := update_xsti_rec.cust_code;
        lt_break_item_code           := update_xsti_rec.item_code;
      END IF;
      --==================================================
      -- 明細番号インクリメント
      --==================================================
      lt_detail_no := lt_detail_no + 1;
      --==================================================
      -- 売上実績振替情報テーブル更新
      --==================================================
      UPDATE xxcok_selling_trns_info    xsti
      SET xsti.slip_no                  = lt_slip_no
        , xsti.detail_no                = lt_detail_no
        , xsti.last_updated_by          = cn_last_updated_by
        , xsti.last_update_date         = SYSDATE
        , xsti.last_update_login        = cn_last_update_login
        , xsti.request_id               = cn_request_id
        , xsti.program_application_id   = cn_program_application_id
        , xsti.program_id               = cn_program_id
        , xsti.program_update_date      = SYSDATE
      WHERE xsti.selling_trns_info_id   = update_xsti_rec.selling_trns_info_id
      ;
    END LOOP update_xsti_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xsti;
--
  /**********************************************************************************
   * Procedure Name   : insert_xsti
   * Description      : 売上振替情報の登録(A-6)(A-7)
   ***********************************************************************************/
  PROCEDURE insert_xsti(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_selling_from_rec             IN  get_selling_from_cur%ROWTYPE -- 売上振替元情報
  , iv_base_code                   IN  VARCHAR2        -- 拠点コード
  , iv_cust_code                   IN  VARCHAR2        -- 顧客コード
  , iv_selling_emp_code            IN  VARCHAR2        -- 担当者営業コード
  , in_dlv_qty                     IN  NUMBER          -- 納品数量
  , in_sales_amount                IN  NUMBER          -- 売上金額
  , in_pure_amount                 IN  NUMBER          -- 本体金額
  , in_sales_cost                  IN  NUMBER          -- 売上原価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--  , in_dlv_unit_price              IN  NUMBER          -- 納品単価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xsti';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 売上振替情報の登録
    --==================================================
    INSERT INTO xxcok_selling_trns_info(
      selling_trns_info_id                        -- 売上実績振替情報ID
    , selling_trns_type                           -- 実績振替区分
    , slip_no                                     -- 伝票番号
    , detail_no                                   -- 明細番号
    , selling_date                                -- 売上計上日
    , selling_type                                -- 売上区分
    , selling_return_type                         -- 売上返品区分
    , delivery_slip_type                          -- 納品伝票区分
    , base_code                                   -- 拠点コード
    , cust_code                                   -- 顧客コード
    , selling_emp_code                            -- 担当者営業コード
    , cust_state_type                             -- 顧客業態区分
    , delivery_form_type                          -- 納品形態区分
    , article_code                                -- 物件コード
    , card_selling_type                           -- カード売り区分
    , checking_date                               -- 検収日
    , demand_to_cust_code                         -- 請求先顧客コード
    , h_c                                         -- Ｈ＆Ｃ
    , column_no                                   -- コラムNO
    , item_code                                   -- 品目コード
    , qty                                         -- 数量
    , unit_type                                   -- 単位
    , delivery_unit_price                         -- 納品単価
    , selling_amt                                 -- 売上金額
    , selling_amt_no_tax                          -- 売上金額(税抜き)
    , trading_cost                                -- 営業原価
    , selling_cost_amt                            -- 売上原価金額
    , tax_code                                    -- 消費税コード
    , tax_rate                                    -- 消費税率
    , delivery_base_code                          -- 納品拠点コード
    , registration_date                           -- 業務登録日付
    , correction_flag                             -- 振戻フラグ
    , report_decision_flag                        -- 速報確定フラグ
    , info_interface_flag                         -- 情報系I/Fフラグ
    , gl_interface_flag                           -- 仕訳作成フラグ
    , org_slip_number                             -- 元伝票番号
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD START
    , selling_from_cust_code                      -- 売上振替元顧客コード
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD END
    , created_by                                  -- 作成者
    , creation_date                               -- 作成日
    , last_updated_by                             -- 最終更新者
    , last_update_date                            -- 最終更新日
    , last_update_login                           -- 最終更新ログイン
    , request_id                                  -- 要求ID
    , program_application_id                      -- コンカレント・プログラム･アプリケーションID
    , program_id                                  -- コンカレント･プログラムID
    , program_update_date                         -- プログラム更新日
    )
    VALUES(
      xxcok_selling_trns_info_s01.NEXTVAL         -- selling_trns_info_id
    , cv_selling_trns_type_trns                   -- selling_trns_type
    , NULL                                        -- slip_no
    , NULL                                        -- detail_no
    , i_selling_from_rec.selling_date             -- selling_date
    , cv_selling_type_normal                      -- selling_type
    , cv_selling_return_type_dlv                  -- selling_return_type
    , cv_delivery_slip_type_dlv                   -- delivery_slip_type
    , iv_base_code                                -- base_code
    , iv_cust_code                                -- cust_code
    , iv_selling_emp_code                         -- selling_emp_code
    , i_selling_from_rec.ship_cust_gyotai_sho     -- cust_state_type
    , cv_delivery_form_type_trns                  -- delivery_form_type
    , cv_article_code_dummy                       -- article_code
    , cv_card_selling_type_cash                   -- card_selling_type
    , NULL                                        -- checking_date
    , i_selling_from_rec.bill_cust_code           -- demand_to_cust_code
    , cv_hc_cold                                  -- h_c
    , cv_column_no                                -- column_no
    , i_selling_from_rec.item_code                -- item_code
    , in_dlv_qty                                  -- qty
    , i_selling_from_rec.dlv_uom_code             -- unit_type
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--    , in_dlv_unit_price                           -- delivery_unit_price
    , i_selling_from_rec.dlv_unit_price           -- delivery_unit_price
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
    , in_sales_amount                             -- selling_amt
    , in_pure_amount                              -- selling_amt_no_tax
    , in_sales_cost                               -- trading_cost
    , NULL                                        -- selling_cost_amt
    , i_selling_from_rec.tax_code                 -- tax_code
    , i_selling_from_rec.tax_rate                 -- tax_rate
    , i_selling_from_rec.sales_base_code          -- delivery_base_code
    , gd_process_date                             -- registration_date
    , cv_xsti_correction_flag_off                 -- correction_flag
    , CASE
        WHEN   TRUNC( i_selling_from_rec.selling_date, 'MM' )
             = TRUNC( gd_process_date                , 'MM' )
        THEN
          cv_xsti_decision_flag_news
        ELSE
          gv_param_info_class
      END                                         -- report_decision_flag
    , cv_xsti_info_if_flag_no                     -- info_interface_flag
    , cv_xsti_gl_if_flag_no                       -- gl_interface_flag
    , NULL                                        -- org_slip_number
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD START
    , i_selling_from_rec.ship_cust_code           -- selling_from_cust_code
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD END
    , cn_created_by                               -- created_by
    , SYSDATE                                     -- creation_date
    , cn_last_updated_by                          -- last_updated_by
    , SYSDATE                                     -- last_update_date
    , cn_last_update_login                        -- last_update_login
    , cn_request_id                               -- request_id
    , cn_program_application_id                   -- program_application_id
    , cn_program_id                               -- program_id
    , SYSDATE                                     -- program_update_date
    );
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 警告終了 ***
    WHEN warning_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xsti;
--
  /**********************************************************************************
   * Procedure Name   : selling_to_loop
   * Description      : 売上振替先情報ループ(A-4)
   ***********************************************************************************/
  PROCEDURE selling_to_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , i_selling_from_rec             IN  get_selling_from_cur%ROWTYPE -- 売上振替元情報
  , on_dlv_qty                     OUT NUMBER          -- 売上振替元納品数量
  , on_sales_amount                OUT NUMBER          -- 売上振替元売上金額
  , on_pure_amount                 OUT NUMBER          -- 売上振替元本体金額
  , on_sales_cost                  OUT NUMBER          -- 売上振替元売上原価
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'selling_to_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    -- OUTパラメータ用変数
    ln_dlv_qty_out                 NUMBER         DEFAULT 0;                    -- 納品数量
    ln_sales_amount_out            NUMBER         DEFAULT 0;                    -- 売上金額
    ln_pure_amount_out             NUMBER         DEFAULT 0;                    -- 本体金額
    ln_sales_cost_out              NUMBER         DEFAULT 0;                    -- 売上原価
    -- 計算結果格納用変数
    ln_dlv_qty                     NUMBER         DEFAULT 0;                    -- 納品数量
    ln_sales_amount                NUMBER         DEFAULT 0;                    -- 売上金額
    ln_pure_amount                 NUMBER         DEFAULT 0;                    -- 本体金額
    ln_sales_cost                  NUMBER         DEFAULT 0;                    -- 売上原価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--    ln_dlv_unit_price              NUMBER         DEFAULT 0;                    -- 納品単価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
    -- 端数計算用集計変数
    ln_dlv_qty_sum                 NUMBER         DEFAULT 0;                    -- 納品数量
    ln_sales_amount_sum            NUMBER         DEFAULT 0;                    -- 売上金額
    ln_pure_amount_sum             NUMBER         DEFAULT 0;                    -- 本体金額
    ln_sales_cost_sum              NUMBER         DEFAULT 0;                    -- 売上原価
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
    -- 振替割合チェック
    ln_selling_trns_rate_total     NUMBER         DEFAULT 0;                    -- 振替割合の合計が100とならない場合はエラー
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
    --==================================================
    -- ローカルコレクション変数
    --==================================================
    l_get_selling_to_tab           get_selling_to_ttype;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 売上振替先情報の抽出
    --==================================================
    OPEN  get_selling_to_cur(
            i_selling_from_rec.sales_base_code
          , i_selling_from_rec.ship_cust_code
          , i_selling_from_rec.selling_date
          );
    FETCH get_selling_to_cur BULK COLLECT INTO l_get_selling_to_tab;
    CLOSE get_selling_to_cur;
    << sub_loop >>
    FOR i IN 1 .. l_get_selling_to_tab.COUNT LOOP
      --==================================================
      -- NULLチェック
      --==================================================
      IF(    ( l_get_selling_to_tab(i).selling_to_base_code IS NULL )
          OR ( l_get_selling_to_tab(i).sales_staff_code     IS NULL )
      ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00045
                      , iv_token_name1          => cv_tkn_customer_code
                      , iv_token_value1         => l_get_selling_to_tab(i).selling_to_cust_code
                      , iv_token_name2          => cv_tkn_customer_name
                      , iv_token_value2         => l_get_selling_to_tab(i).party_name
                      , iv_token_name3          => cv_tkn_tanto_loc_code
                      , iv_token_value3         => l_get_selling_to_tab(i).selling_to_base_code
                      , iv_token_name4          => cv_tkn_tanto_code
                      , iv_token_value4         => l_get_selling_to_tab(i).sales_staff_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE warning_skip_expt;
      END IF;
      --==================================================
      -- 按分計算(A-5)
      --==================================================
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--      -- 納品数量
--      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );"
--      IF( ln_dlv_qty = 0 ) THEN"
--        -- 売上金額"
--        ln_sales_amount  := 0;"
--        -- 本体金額"
--        ln_pure_amount   := 0;"
--        -- 売上原価"
--        ln_sales_cost    := 0;"
--      ELSE
--        -- 売上金額
--        ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--        -- 本体金額
--        ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--        -- 売上原価
--        ln_sales_cost    := ROUND( i_selling_from_rec.sales_cost_sum   * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
--      END IF;
--      -- 端数計算用集計
--      IF( ln_dlv_qty <> 0 ) THEN
--        ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
--        ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
--        ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
--        ln_sales_cost_sum   := ln_sales_cost_sum   + ln_sales_cost;
--      END IF;
      -- 納品数量
      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 売上金額
      ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 本体金額
      ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 売上原価
      ln_sales_cost    := ROUND( i_selling_from_rec.sales_cost_sum   * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 端数計算用集計
      ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
      ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
      ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
      ln_sales_cost_sum   := ln_sales_cost_sum   + ln_sales_cost;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
      -- 端数調整
      IF( i = l_get_selling_to_tab.LAST ) THEN
        -- 納品数量
        ln_dlv_qty      := ln_dlv_qty      + i_selling_from_rec.dlv_qty_sum       - ln_dlv_qty_sum;
        -- 売上金額
        ln_sales_amount := ln_sales_amount + i_selling_from_rec.sales_amount_sum  - ln_sales_amount_sum;
        -- 本体金額
        ln_pure_amount  := ln_pure_amount  + i_selling_from_rec.pure_amount_sum   - ln_pure_amount_sum;
        -- 売上原価
        ln_sales_cost   := ln_sales_cost   + i_selling_from_rec.sales_cost_sum    - ln_sales_cost_sum;
      END IF;
      --==================================================
      -- 売上振替先情報の登録(A-6)
      --==================================================
      IF( l_get_selling_to_tab(i).selling_to_cust_code = i_selling_from_rec.ship_cust_code ) THEN
        --==================================================
        -- OUTパラメータ設定
        --==================================================
        -- 納品数量
        ln_dlv_qty_out      := ln_dlv_qty;
        -- 売上金額
        ln_sales_amount_out := ln_sales_amount;
        -- 本体金額
        ln_pure_amount_out  := ln_pure_amount;
        -- 売上原価
        ln_sales_cost_out   := ln_sales_cost;
      ELSE
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--        IF( ln_dlv_qty <> 0 ) THEN
--          -- 納品単価
--          ln_dlv_unit_price := ROUND( ln_sales_amount / ln_dlv_qty, 1 );
--          insert_xsti(
--            ov_errbuf               => lv_errbuf                                     -- エラー・メッセージ
--          , ov_retcode              => lv_retcode                                    -- リターン・コード
--          , ov_errmsg               => lv_errmsg                                     -- ユーザー・エラー・メッセージ
--          , i_selling_from_rec      => i_selling_from_rec                            -- 売上振替元情報
--          , iv_base_code            => l_get_selling_to_tab(i).selling_to_base_code  -- 売上振替先拠点コード
--          , iv_cust_code            => l_get_selling_to_tab(i).selling_to_cust_code  -- 売上振替先顧客コード
--          , iv_selling_emp_code     => l_get_selling_to_tab(i).sales_staff_code      -- 売上振替先営業担当コード
--          , in_dlv_qty              => ln_dlv_qty                                    -- 売上振替先納品数量
--          , in_sales_amount         => ln_sales_amount                               -- 売上振替先売上金額
--          , in_pure_amount          => ln_pure_amount                                -- 売上振替先本体金額
--          , in_sales_cost           => ln_sales_cost                                 -- 売上振替先売上原価
--          , in_dlv_unit_price       => ln_dlv_unit_price                             -- 売上振替先納品単価
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            lv_end_retcode := cv_status_error;
--            RAISE global_process_expt;
--          ELSIF( lv_retcode = cv_status_warn ) THEN
--            RAISE warning_skip_expt;
--          END IF;
--        END IF;
        insert_xsti(
          ov_errbuf               => lv_errbuf                                     -- エラー・メッセージ
        , ov_retcode              => lv_retcode                                    -- リターン・コード
        , ov_errmsg               => lv_errmsg                                     -- ユーザー・エラー・メッセージ
        , i_selling_from_rec      => i_selling_from_rec                            -- 売上振替元情報
        , iv_base_code            => l_get_selling_to_tab(i).selling_to_base_code  -- 売上振替先拠点コード
        , iv_cust_code            => l_get_selling_to_tab(i).selling_to_cust_code  -- 売上振替先顧客コード
        , iv_selling_emp_code     => l_get_selling_to_tab(i).sales_staff_code      -- 売上振替先営業担当コード
        , in_dlv_qty              => ln_dlv_qty                                    -- 売上振替先納品数量
        , in_sales_amount         => ln_sales_amount                               -- 売上振替先売上金額
        , in_pure_amount          => ln_pure_amount                                -- 売上振替先本体金額
        , in_sales_cost           => ln_sales_cost                                 -- 売上振替先売上原価
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
      END IF;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
      --==================================================
      -- 振替割合チェック用集計
      --==================================================
      ln_selling_trns_rate_total := ln_selling_trns_rate_total + l_get_selling_to_tab(i).selling_trns_rate;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
    END LOOP sub_loop;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD START
    --==================================================
    -- 振替割合チェック
    --==================================================
    IF( ln_selling_trns_rate_total <> 100 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10463
                    , iv_token_name1          => cv_tkn_from_location_code
                    , iv_token_value1         => i_selling_from_rec.sales_base_code
                    , iv_token_name2          => cv_tkn_from_customer_code
                    , iv_token_value2         => i_selling_from_rec.ship_cust_code
                    , iv_token_name3          => cv_tkn_item_code
                    , iv_token_value3         => i_selling_from_rec.item_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE warning_skip_expt;
    END IF;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi ADD END
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    on_dlv_qty           := ln_dlv_qty_out;
    on_sales_amount      := ln_sales_amount_out;
    on_pure_amount       := ln_pure_amount_out;
    on_sales_cost        := ln_sales_cost_out;
    ov_errbuf            := NULL;
    ov_errmsg            := NULL;
    ov_retcode           := lv_end_retcode;
--
  EXCEPTION
    -- *** 警告終了 ***
    WHEN warning_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END selling_to_loop;
--
  /**********************************************************************************
   * Procedure Name   : selling_from_loop
   * Description      : 売上振替元情報ループ(A-3)
   ***********************************************************************************/
  PROCEDURE selling_from_loop(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'selling_from_loop';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ln_dlv_qty_sum                 NUMBER         DEFAULT NULL;                 -- 納品数量
    ln_sales_amount_sum            NUMBER         DEFAULT NULL;                 -- 売上金額
    ln_pure_amount_sum             NUMBER         DEFAULT NULL;                 -- 本体金額
    ln_sales_cost_sum              NUMBER         DEFAULT NULL;                 -- 売上原価
    -- 売上振替元振替按分計算結果格納用
    ln_dlv_qty                     NUMBER         DEFAULT 0;                    -- 納品数量
    ln_sales_amount                NUMBER         DEFAULT 0;                    -- 売上金額
    ln_pure_amount                 NUMBER         DEFAULT 0;                    -- 本体金額
    ln_sales_cost                  NUMBER         DEFAULT 0;                    -- 売上原価
    -- 売上振替相殺レコード作成用変数
    ln_dlv_qty_counter             NUMBER         DEFAULT 0;                    -- 納品数量（相殺）
    ln_sales_amount_counter        NUMBER         DEFAULT 0;                    -- 売上金額（相殺）
    ln_pure_amount_counter         NUMBER         DEFAULT 0;                    -- 本体金額（相殺）
    ln_sales_cost_counter          NUMBER         DEFAULT 0;                    -- 売上原価（相殺）
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE START
--    ln_dlv_unit_price_counter      NUMBER         DEFAULT 0;                    -- 納品単価（相殺）
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi DELETE END
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 売上振替元情報の抽出
    --==================================================
    << main_loop >>
    FOR get_selling_from_rec IN get_selling_from_cur LOOP
      --==================================================
      -- 対象件数カウント
      --==================================================
      gn_target_cnt := gn_target_cnt + 1;
      BEGIN
        --==================================================
        -- セーブポイント設定
        --==================================================
        SAVEPOINT loop_start_save;
        --==================================================
        -- 売上原価チェック
        --==================================================
        IF( get_selling_from_rec.sales_cost_sum IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => get_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => get_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
        --==================================================
        -- 売上振替元担当営業コードチェック
        --==================================================
        IF( get_selling_from_rec.sales_staff_code IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_00045
                        , iv_token_name1          => cv_tkn_customer_code
                        , iv_token_value1         => get_selling_from_rec.ship_cust_code
                        , iv_token_name2          => cv_tkn_customer_name
                        , iv_token_value2         => get_selling_from_rec.ship_party_name
                        , iv_token_name3          => cv_tkn_tanto_loc_code
                        , iv_token_value3         => get_selling_from_rec.sales_base_code
                        , iv_token_name4          => cv_tkn_tanto_code
                        , iv_token_value4         => get_selling_from_rec.sales_staff_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- 売上振替先情報ループ(A-4)
        --==================================================
        selling_to_loop(
          ov_errbuf               => lv_errbuf                   -- エラー・メッセージ
        , ov_retcode              => lv_retcode                  -- リターン・コード
        , ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ
        , i_selling_from_rec      => get_selling_from_rec        -- 売上振替元情報
        , on_dlv_qty              => ln_dlv_qty                  -- 売上振替元納品数量
        , on_sales_amount         => ln_sales_amount             -- 売上振替元売上金額
        , on_pure_amount          => ln_pure_amount              -- 売上振替元本体金額
        , on_sales_cost           => ln_sales_cost               -- 売上振替元売上原価
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- 売上振替元情報の登録(A-7)
        --==================================================
        -- 納品数量（相殺）
        ln_dlv_qty_counter         := get_selling_from_rec.dlv_qty_sum      * -1 + ln_dlv_qty;
        -- 売上金額（相殺）
        ln_sales_amount_counter    := get_selling_from_rec.sales_amount_sum * -1 + ln_sales_amount;
        -- 本体金額（相殺）
        ln_pure_amount_counter     := get_selling_from_rec.pure_amount_sum  * -1 + ln_pure_amount;
        -- 売上原価（相殺）
        ln_sales_cost_counter      := get_selling_from_rec.sales_cost_sum   * -1 + ln_sales_cost;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR START
--        IF( ln_dlv_qty_counter <> 0 ) THEN
--          -- 納品単価（相殺）
--          ln_dlv_unit_price_counter  := ROUND( ln_sales_amount_counter / ln_dlv_qty_counter, 1 );
--          insert_xsti(
--            ov_errbuf               => lv_errbuf                                  -- エラー・メッセージ
--          , ov_retcode              => lv_retcode                                 -- リターン・コード
--          , ov_errmsg               => lv_errmsg                                  -- ユーザー・エラー・メッセージ
--          , i_selling_from_rec      => get_selling_from_rec                       -- 売上振替元情報
--          , iv_base_code            => get_selling_from_rec.sales_base_code       -- 売上振替元拠点コード
--          , iv_cust_code            => get_selling_from_rec.ship_cust_code        -- 売上振替元顧客コード
--          , iv_selling_emp_code     => get_selling_from_rec.sales_staff_code      -- 売上振替元営業担当コード
--          , in_dlv_qty              => ln_dlv_qty_counter                         -- 納品数量（相殺）
--          , in_sales_amount         => ln_sales_amount_counter                    -- 売上金額（相殺）
--          , in_pure_amount          => ln_pure_amount_counter                     -- 本体金額（相殺）
--          , in_sales_cost           => ln_sales_cost_counter                      -- 売上原価（相殺）
--          , in_dlv_unit_price       => ln_dlv_unit_price_counter                  -- 納品単価（相殺）
--          );
--          IF( lv_retcode = cv_status_error ) THEN
--            lv_end_retcode := cv_status_error;
--            RAISE global_process_expt;
--          ELSIF( lv_retcode = cv_status_warn ) THEN
--            RAISE warning_skip_expt;
--          END IF;
--        END IF;
        insert_xsti(
          ov_errbuf               => lv_errbuf                                  -- エラー・メッセージ
        , ov_retcode              => lv_retcode                                 -- リターン・コード
        , ov_errmsg               => lv_errmsg                                  -- ユーザー・エラー・メッセージ
        , i_selling_from_rec      => get_selling_from_rec                       -- 売上振替元情報
        , iv_base_code            => get_selling_from_rec.sales_base_code       -- 売上振替元拠点コード
        , iv_cust_code            => get_selling_from_rec.ship_cust_code        -- 売上振替元顧客コード
        , iv_selling_emp_code     => get_selling_from_rec.sales_staff_code      -- 売上振替元営業担当コード
        , in_dlv_qty              => ln_dlv_qty_counter                         -- 納品数量（相殺）
        , in_sales_amount         => ln_sales_amount_counter                    -- 売上金額（相殺）
        , in_pure_amount          => ln_pure_amount_counter                     -- 本体金額（相殺）
        , in_sales_cost           => ln_sales_cost_counter                      -- 売上原価（相殺）
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
-- 2009/09/28 Ver.2.1 [E_T3_00590] SCS K.Yamaguchi REPAIR END
        --==================================================
        -- 正常件数カウント
        --==================================================
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        --==================================================
        -- 警告スキップ
        --==================================================
        WHEN warning_skip_expt THEN
          ROLLBACK TO SAVEPOINT loop_start_save;
          lv_end_retcode := cv_status_warn;
          gn_error_cnt := gn_error_cnt + 1;
      END;
    END LOOP main_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END selling_from_loop;
--
  /**********************************************************************************
   * Procedure Name   : make_correction
   * Description      : 振り戻しデータ作成(A-2)
   ***********************************************************************************/
  PROCEDURE make_correction(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'make_correction';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    --==================================================
    -- ロック取得カーソル
    --==================================================
    CURSOR get_xsti_lock_cur
    IS
      SELECT xsti.selling_trns_info_id       AS selling_trns_info_id       -- 売上実績振替情報ID
           , xsti.selling_trns_type          AS selling_trns_type          -- 実績振替区分
           , xsti.slip_no                    AS slip_no                    -- 伝票番号
           , xsti.detail_no                  AS detail_no                  -- 明細番号
           , xsti.selling_date               AS selling_date               -- 売上計上日
           , xsti.selling_type               AS selling_type               -- 売上区分
           , xsti.selling_return_type        AS selling_return_type        -- 売上返品区分
           , xsti.delivery_slip_type         AS delivery_slip_type         -- 納品伝票区分
           , xsti.base_code                  AS base_code                  -- 拠点コード
           , xsti.cust_code                  AS cust_code                  -- 顧客コード
           , xsti.selling_emp_code           AS selling_emp_code           -- 担当者営業コード
           , xsti.cust_state_type            AS cust_state_type            -- 顧客業態区分
           , xsti.delivery_form_type         AS delivery_form_type         -- 納品形態区分
           , xsti.article_code               AS article_code               -- 物件コード
           , xsti.card_selling_type          AS card_selling_type          -- カード売り区分
           , xsti.checking_date              AS checking_date              -- 検収日
           , xsti.demand_to_cust_code        AS demand_to_cust_code        -- 請求先顧客コード
           , xsti.h_c                        AS h_c                        -- Ｈ＆Ｃ
           , xsti.column_no                  AS column_no                  -- コラムNO
           , xsti.item_code                  AS item_code                  -- 品目コード
           , xsti.qty                        AS qty                        -- 数量
           , xsti.unit_type                  AS unit_type                  -- 単位
           , xsti.delivery_unit_price        AS delivery_unit_price        -- 納品単価
           , xsti.selling_amt                AS selling_amt                -- 売上金額
           , xsti.selling_amt_no_tax         AS selling_amt_no_tax         -- 売上金額(税抜き)
           , xsti.trading_cost               AS trading_cost               -- 営業原価
           , xsti.selling_cost_amt           AS selling_cost_amt           -- 売上原価金額
           , xsti.tax_code                   AS tax_code                   -- 消費税コード
           , xsti.tax_rate                   AS tax_rate                   -- 消費税率
           , xsti.delivery_base_code         AS delivery_base_code         -- 納品拠点コード
           , xsti.report_decision_flag       AS report_decision_flag       -- 速報確定フラグ
           , xsti.org_slip_number            AS org_slip_number            -- 元伝票番号
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD START
           , xsti.selling_from_cust_code     AS selling_from_cust_code     -- 売上振替元顧客コード
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD END
      FROM xxcok_selling_trns_info      xsti
      WHERE xsti.selling_date     BETWEEN gd_target_date_from
                                      AND gd_target_date_to
        AND xsti.report_decision_flag   = cv_xsti_decision_flag_news
        AND xsti.correction_flag        = cv_xsti_correction_flag_off
      FOR UPDATE OF xsti.selling_trns_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 売上実績振替情報テーブルロック取得
    --==================================================
    << xsti_lock_loop >>
    FOR get_xsti_lock_rec IN get_xsti_lock_cur LOOP
      --==================================================
      -- 売上実績振替情報テーブル登録
      --==================================================
      INSERT INTO xxcok_selling_trns_info(
        selling_trns_info_id                           -- 売上実績振替情報ID
      , selling_trns_type                              -- 実績振替区分
      , slip_no                                        -- 伝票番号
      , detail_no                                      -- 明細番号
      , selling_date                                   -- 売上計上日
      , selling_type                                   -- 売上区分
      , selling_return_type                            -- 売上返品区分
      , delivery_slip_type                             -- 納品伝票区分
      , base_code                                      -- 拠点コード
      , cust_code                                      -- 顧客コード
      , selling_emp_code                               -- 担当者営業コード
      , cust_state_type                                -- 顧客業態区分
      , delivery_form_type                             -- 納品形態区分
      , article_code                                   -- 物件コード
      , card_selling_type                              -- カード売り区分
      , checking_date                                  -- 検収日
      , demand_to_cust_code                            -- 請求先顧客コード
      , h_c                                            -- Ｈ＆Ｃ
      , column_no                                      -- コラムNO
      , item_code                                      -- 品目コード
      , qty                                            -- 数量
      , unit_type                                      -- 単位
      , delivery_unit_price                            -- 納品単価
      , selling_amt                                    -- 売上金額
      , selling_amt_no_tax                             -- 売上金額(税抜き)
      , trading_cost                                   -- 営業原価
      , selling_cost_amt                               -- 売上原価金額
      , tax_code                                       -- 消費税コード
      , tax_rate                                       -- 消費税率
      , delivery_base_code                             -- 納品拠点コード
      , registration_date                              -- 業務登録日付
      , correction_flag                                -- 振戻フラグ
      , report_decision_flag                           -- 速報確定フラグ
      , info_interface_flag                            -- 情報系IFフラグ
      , gl_interface_flag                              -- 仕訳作成フラグ
      , org_slip_number                                -- 元伝票番号
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD START
      , selling_from_cust_code                         -- 売上振替元顧客コード
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD END
      , created_by                                     -- 作成者
      , creation_date                                  -- 作成日
      , last_updated_by                                -- 最終更新者
      , last_update_date                               -- 最終更新日
      , last_update_login                              -- 最終更新ログイン
      , request_id                                     -- 要求ID
      , program_application_id                         -- コンカレント・プログラム･アプリケーションID
      , program_id                                     -- コンカレント･プログラムID
      , program_update_date                            -- プログラム更新日
      )
      VALUES(
        xxcok_selling_trns_info_s01.NEXTVAL            -- selling_trns_info_id
      , get_xsti_lock_rec.selling_trns_type            -- selling_trns_type
      , get_xsti_lock_rec.slip_no                      -- slip_no
      , get_xsti_lock_rec.detail_no                    -- detail_no
      , CASE
          WHEN   TRUNC( gd_process_date               , 'MM' )
               = TRUNC( get_xsti_lock_rec.selling_date, 'MM' )
          THEN
            gd_target_date_to
          ELSE
            LAST_DAY( gd_target_date_from )
        END                                            -- selling_date
      , get_xsti_lock_rec.selling_type                 -- selling_type
      , get_xsti_lock_rec.selling_return_type          -- selling_return_type
      , get_xsti_lock_rec.delivery_slip_type           -- delivery_slip_type
      , get_xsti_lock_rec.base_code                    -- base_code
      , get_xsti_lock_rec.cust_code                    -- cust_code
      , get_xsti_lock_rec.selling_emp_code             -- selling_emp_code
      , get_xsti_lock_rec.cust_state_type              -- cust_state_type
      , get_xsti_lock_rec.delivery_form_type           -- delivery_form_type
      , get_xsti_lock_rec.article_code                 -- article_code
      , get_xsti_lock_rec.card_selling_type            -- card_selling_type
      , get_xsti_lock_rec.checking_date                -- checking_date
      , get_xsti_lock_rec.demand_to_cust_code          -- demand_to_cust_code
      , get_xsti_lock_rec.h_c                          -- h_c
      , get_xsti_lock_rec.column_no                    -- column_no
      , get_xsti_lock_rec.item_code                    -- item_code
      , get_xsti_lock_rec.qty                          -- qty
      , get_xsti_lock_rec.unit_type                    -- unit_type
      , get_xsti_lock_rec.delivery_unit_price          -- delivery_unit_price
      , -1 * get_xsti_lock_rec.selling_amt             -- selling_amt
      , -1 * get_xsti_lock_rec.selling_amt_no_tax      -- selling_amt_no_tax
      , -1 * get_xsti_lock_rec.trading_cost            -- trading_cost
      , get_xsti_lock_rec.selling_cost_amt             -- selling_cost_amt
      , get_xsti_lock_rec.tax_code                     -- tax_code
      , get_xsti_lock_rec.tax_rate                     -- tax_rate
      , get_xsti_lock_rec.delivery_base_code           -- delivery_base_code
      , gd_process_date                                -- registration_date
      , cv_xsti_correction_flag_on                     -- correction_flag
      , get_xsti_lock_rec.report_decision_flag         -- report_decision_flag
      , cv_xsti_info_if_flag_no                        -- info_interface_flag
      , cv_xsti_gl_if_flag_no                          -- gl_interface_flag
      , get_xsti_lock_rec.org_slip_number              -- org_slip_number
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD START
      , get_xsti_lock_rec.selling_from_cust_code       -- selling_from_cust_code
-- 2009/10/15 Ver.2.2 [障害E_T3_00632] SCS S.Moriyama ADD END
      , cn_created_by                                  -- created_by
      , SYSDATE                                        -- creation_date
      , cn_last_updated_by                             -- last_updated_by
      , SYSDATE                                        -- last_update_date
      , cn_last_update_login                           -- last_update_login
      , cn_request_id                                  -- request_id
      , cn_program_application_id                      -- program_application_id
      , cn_program_id                                  -- program_id
      , SYSDATE                                        -- program_update_date
      );
      --==================================================
      -- 売上実績振替情報テーブル更新
      --==================================================
      UPDATE xxcok_selling_trns_info    xsti
      SET xsti.correction_flag        = cv_xsti_correction_flag_on
        , xsti.last_updated_by        = cn_last_updated_by
        , xsti.last_update_date       = SYSDATE
        , xsti.last_update_login      = cn_last_update_login
        , xsti.request_id             = cn_request_id
        , xsti.program_application_id = cn_program_application_id
        , xsti.program_id             = cn_program_id
        , xsti.program_update_date    = SYSDATE
      WHERE xsti.selling_trns_info_id = get_xsti_lock_rec.selling_trns_info_id
      ;
    END LOOP xsti_lock_loop;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10012
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END make_correction;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lb_period_status               BOOLEAN        DEFAULT TRUE;                 -- 会計期間ステータスチェック用戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 情報種別
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00023
                  , iv_token_name1          => cv_tkn_info_class
                  , iv_token_value1         => iv_info_class
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg         -- メッセージ
                  , in_new_line             => 0                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    --==================================================
    -- プログラム入力項目チェック
    --==================================================
    -- 情報種別
    IF( iv_info_class NOT IN ( cv_info_class_news, cv_info_class_decision ) ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10036
                    , iv_token_name1          => cv_tkn_info_class
                    , iv_token_value1         => iv_info_class
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プログラム入力項目をグローバル変数へ格納
    --==================================================
    gv_param_info_class := iv_info_class;
    --==================================================
    -- プロファイル取得(会計帳簿ID)
    --==================================================
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 業務処理日付取得
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 当月会計期間ステータスチェック
    --==================================================
    lb_period_status := xxcok_common_pkg.check_acctg_period_f(
                          in_set_of_books_id           => gn_set_of_books_id         -- IN NUMBER   会計帳簿ID
                        , id_proc_date                 => gd_process_date            -- IN DATE     処理日(対象日)
                        , iv_application_short_name    => cv_appl_short_name_ar      -- IN VARCHAR2 アプリケーション短縮名
                        );
    IF( lb_period_status = TRUE ) THEN
      gd_target_date_from := TRUNC( gd_process_date, 'MM' );
      gd_target_date_to   := gd_process_date;
    ELSE
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_process_date, 'RRRR/MM' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- 前月会計期間ステータスチェック
    --==================================================
    lb_period_status := xxcok_common_pkg.check_acctg_period_f(
                          in_set_of_books_id           => gn_set_of_books_id                 -- IN NUMBER   会計帳簿ID
                        , id_proc_date                 => ADD_MONTHS( gd_process_date, - 1 ) -- IN DATE     処理日(対象日)
                        , iv_application_short_name    => cv_appl_short_name_ar              -- IN VARCHAR2 アプリケーション短縮名
                        );
    IF( lb_period_status = TRUE ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
    --==================================================
    -- 売上振替情報登録最小ID取得
    --==================================================
    SELECT xxcok_selling_trns_info_s01.NEXTVAL
    INTO gt_selling_trns_info_id_min
    FROM DUAL
    ;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
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
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_info_class           => iv_info_class         -- 情報種別
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 振り戻しデータ作成(A-2)
    --==================================================
    make_correction(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 売上振替元情報ループ(A-3)
    --==================================================
    selling_from_loop(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 伝票番号更新(A-8)
    --==================================================
    update_xsti(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
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
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message               => NULL               -- メッセージ
                  , in_new_line              => 1                  -- 改行
                  );
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_info_class           => iv_info_class         -- 情報種別
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- 出力区分
                    , iv_message               => lv_errmsg           -- メッセージ
                    , in_new_line              => 1                   -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- スキップ件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
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
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK008A06C;
/
