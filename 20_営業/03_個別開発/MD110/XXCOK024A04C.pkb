CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A04C(body)
 * Description      : 控除用実績振替データの作成（振替割合）
 * MD.050           : 控除用実績振替データの作成（振替割合） MD050_COK_024_A04
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  data_delite            控除用実績振替データ削除処理(A-2)
 *  selling_from_loop      売上振替元情報の抽出(A-3)
 *  selling_to_loop        売上振替先情報の抽出(A-4)
 *  insert_xsti            売上実績振替先情報の登録(A-6)
 *  update_xsti            伝票番号更新(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/04/08    1.0   Y.Nakajima       新規作成
 *  2020/06/15    1.1   K.Kanada         後続機能のPT対応で商品区分の編集を追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
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
  -- パッケージ名
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK024A04C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_coi           CONSTANT VARCHAR2(10)    := 'XXCOI';
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
  -- メッセージコード
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';
  cv_msg_cok_00045                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00045';
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';
  cv_msg_cok_10452                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10452';
  cv_msg_cok_10463                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10463';
--
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- エラー件数
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
--
  cv_msg_coi_00006                 CONSTANT VARCHAR2(50)    := 'APP-XXCOI1-00006';
  -- トークン
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_customer_code             CONSTANT VARCHAR2(30)    := 'CUSTOMER_CODE';
  cv_tkn_customer_name             CONSTANT VARCHAR2(30)    := 'CUSTOMER_NAME';
  cv_tkn_dlv_uom_code              CONSTANT VARCHAR2(30)    := 'DLV_UOM_CODE';
  cv_tkn_from_customer_code        CONSTANT VARCHAR2(30)    := 'FROM_CUSTOMER_CODE';
  cv_tkn_from_location_code        CONSTANT VARCHAR2(30)    := 'FROM_LOCATION_CODE';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_tanto_code                CONSTANT VARCHAR2(30)    := 'TANTO_CODE';
  cv_tkn_tanto_loc_code            CONSTANT VARCHAR2(30)    := 'TANTO_LOC_CODE';
  cv_tkn_org_code                  CONSTANT VARCHAR2(30)    := 'ORG_CODE_TOK';
  -- プロファイル・オプション名
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- 会計帳簿ID
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'XXCOS1_PAYMENT_DISCOUNTS_CODE';     -- 入金値引
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOI1_ORGANIZATION_CODE';          -- 在庫組織コード
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_VENDOR_DUMMY_CODE';          -- 仕入先ダミーコード
  -- 入力パラメータ・情報種別
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- 速報
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- 確定
  -- 顧客区分
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- 顧客
  -- 顧客追加情報・売上実績振替
  cv_xca_transfer_div_on           CONSTANT VARCHAR2(1)     := '1';  -- 実績振替あり
  -- 顧客ステータス
  cv_customer_status_30            CONSTANT VARCHAR2(2)     := '30'; -- 承認済
  cv_customer_status_40            CONSTANT VARCHAR2(2)     := '40'; -- 顧客
  cv_customer_status_50            CONSTANT VARCHAR2(2)     := '50'; -- 休止
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
  -- カラムNo
  cv_column_no                     CONSTANT VARCHAR2(2)     := '00'; -- ダミーカラムNO
  -- 顧客マスタ有効ステータス
  cv_cust_status_available         CONSTANT VARCHAR2(1)     := 'A';  -- 有効
  cv_get_period_inv                CONSTANT VARCHAR2(2)     := '01';   --INV会計期間取得
  cv_period_status                 CONSTANT VARCHAR2(4)     := 'OPEN'; -- 会計期間ステータス(オープン)
  cn_dlv_qty                       CONSTANT NUMBER(1)       := 0;      -- 入金値引の数量
  cn_business_cost                 CONSTANT NUMBER(1)       := 0;      -- 入金値引の営業原価
  cn_dlv_unit_price                CONSTANT NUMBER(1)       := 0;      -- 入金値引の納品単価
  --入金値引取得条件
  cv_amt_fix_status                CONSTANT VARCHAR2(1)     := '1';         -- 金額確定済
  cv_ar_interface_status           CONSTANT VARCHAR2(1)     := '1';         -- AR連携済
  --データ判定用
  cn_sales_exp                     CONSTANT NUMBER(1)       := 1;           -- 販売実績
  cn_payment_discounts             CONSTANT NUMBER(1)       := 2;           -- 入金値引
  cv_payment_discounts_code_type   CONSTANT VARCHAR2(50)    := 'XXCMM1_PAYMENT_DISCOUNTS_CODE';     -- 入金値引
  --参照タイプ・有効フラグ
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';         -- 有効
-- 2020/06/15 Add S
  cv_cate_set_name                 CONSTANT VARCHAR2(20)    := '本社商品区分';            -- 品目カテゴリセット名
-- 2020/06/15 Add E
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理取得値
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- 会計帳簿ID
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gd_target_date_from              DATE          DEFAULT NULL;   -- 振替対象期間（From）
  gd_target_date_to                DATE          DEFAULT NULL;   -- 振替対象期間（To）
  gt_item_code                     mtl_system_items_b.segment1%TYPE DEFAULT NULL;                  -- 入金値引コード
  gt_supplier_dummy                xxcok_cond_bm_support.supplier_code%TYPE DEFAULT NULL;          -- 仕入先ダミーコード
  gn_organization_id               NUMBER        DEFAULT NULL;   -- 在庫組織ID
  -- 入力パラメータ
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- 情報種別
  --
  gt_selling_trns_info_id_min      xxcok_dedu_sell_trns_info.selling_trns_info_id%TYPE DEFAULT NULL; -- 売上振替情報登録最小ID
-- 2020/06/15 Add S
  gt_product_class                 xxcok_dedu_sell_trns_info.product_class%TYPE;     -- 商品区分
-- 2020/06/15 Add E
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
  --
  -- 売上振替元情報取得
  CURSOR get_selling_from_cur
  IS
    SELECT /*+
               LEADING(xsfi, ship_hca, ship_hcas)
               INDEX(ship_hca hz_cust_accounts_u2)
            */
           xseh.delivery_date                                           AS selling_date             -- 売上計上日
         , xseh.sales_base_code                                         AS sales_base_code          -- 売上振替元拠点コード
         , xseh.ship_to_customer_code                                   AS ship_cust_code           -- 売上振替元顧客コード
         , ship_hp.party_name                                           AS ship_party_name          -- 売上振替元顧客名
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , xseh.delivery_date
           )                                                            AS sales_staff_code         -- 売上振替元担当営業コード
         , xseh.cust_gyotai_sho                                         AS ship_cust_gyotai_sho     -- 業態（小分類）
         , bill_hca.account_number                                      AS bill_cust_code           -- 請求先顧客コード
         , xsel.item_code                                               AS item_code                -- 品目コード
         , ROUND( SUM( xsel.dlv_qty ), 0 )                              AS dlv_qty_sum              -- 納品数量
         , xsel.dlv_uom_code                                            AS dlv_uom_code             -- 納品単位
         , ROUND( SUM( xsel.sale_amount ), 0 )                          AS sales_amount_sum         -- 売上金額
         , ROUND( SUM( xsel.pure_amount ), 0 )                          AS pure_amount_sum          -- 本体金額
         , xsel.business_cost                                           AS business_cost            -- 営業原価
         , DECODE(xsel.tax_code, NULL, xseh.tax_code, xsel.tax_code )   AS tax_code                 -- 税金コード
         , DECODE(xsel.tax_rate, NULL, xseh.tax_rate, xsel.tax_rate )   AS tax_rate                 -- 消費税率
         , xsel.dlv_unit_price                                          AS dlv_unit_price           -- 納品単価
         , cn_sales_exp                                                 AS data_type                -- データ種別(実績)
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
      AND ship_hcsu.status                  = cv_cust_status_available
      AND bill_hcsu.status                  = cv_cust_status_available
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
                     AND hca.party_id                    = hp.party_id
                     AND hp.duns_number_c               IN (   cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                           )
                     AND ROWNUM                          = 1
          )
  GROUP BY xseh.delivery_date
         , xseh.sales_base_code
         , xseh.ship_to_customer_code
         , ship_hp.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xseh.ship_to_customer_code
           , xseh.delivery_date
           )
         , xseh.cust_gyotai_sho
         , bill_hca.account_number
         , xsel.item_code
         , xsel.dlv_uom_code
         , xsel.business_cost
         , DECODE(xsel.tax_code, NULL, xseh.tax_code, xsel.tax_code )
         , DECODE(xsel.tax_rate, NULL, xseh.tax_rate, xsel.tax_rate )
         , xsel.dlv_unit_price
    UNION ALL
    --入金値引情報
    SELECT /*+
               LEADING( xsfi2 )
               USE_NL( xsfi2 xcbs )
           */
           xcbs.closing_date                                            AS selling_date             -- 売上計上日
         , xsfi2.selling_from_base_code                                 AS sales_base_code          -- 売上振替元拠点コード
         , xsfi2.selling_from_cust_code                                 AS ship_cust_code           -- 売上振替元顧客コード
         , ship_hp2.party_name                                          AS ship_party_name          -- 売上振替元顧客名
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsfi2.selling_from_cust_code
           , xcbs.closing_date
           )                                                            AS sales_staff_code         -- 売上振替元担当営業コード
         , ship_xca2.business_low_type                                  AS ship_cust_gyotai_sho     -- 業態（小分類）
         , xcbs.demand_to_cust_code                                     AS bill_cust_code           -- 請求先顧客コード
         , msib.segment1                                                AS item_code                -- 品目コード
         , cn_dlv_qty                                                   AS dlv_qty_sum              -- 納品数量
         , msib.primary_uom_code                                        AS dlv_uom_code             -- 納品単位
         , SUM( xcbs.csh_rcpt_discount_amt )                            AS sales_amount_sum         -- 売上金額
         , SUM( xcbs.csh_rcpt_discount_amt
                     - xcbs.csh_rcpt_discount_amt_tax )                 AS pure_amount_sum          -- 本体金額
         , cn_business_cost                                             AS business_cost            -- 営業原価
         , xcbs.tax_code                                                AS tax_code                 -- 税金コード
         , xcbs.tax_rate                                                AS tax_rate                 -- 消費税率
         , cn_dlv_unit_price                                            AS dlv_unit_price           -- 納品単価
         , cn_payment_discounts                                         AS data_type                -- データ種別(入金)
    FROM xxcok_selling_from_info   xsfi2            -- 売上振替元情報
       , xxcok_cond_bm_support     xcbs             -- 条件別販手販協テーブル
       , hz_cust_accounts          ship_hca2        -- 【出荷先】顧客マスタ
       , hz_parties                ship_hp2         -- 【出荷先】顧客パーティ
       , xxcmm_cust_accounts       ship_xca2        -- 【出荷先】顧客追加情報
       , xxcmm_system_items_b      xsib             -- DISC品目マスタアドオン
       , mtl_system_items_b        msib             -- DISC品目マスタ
       , xxcos_reduced_tax_rate_v  xrtrv            -- 品目別消費税率VIEW
       , fnd_lookup_values_vl      flvv             -- クイックコード
       , ar_vat_tax_all_b          avtab            -- 税率マスタ
    WHERE gv_param_info_class           = cv_info_class_decision --情報種別が1(確定)
      AND xsfi2.selling_from_base_code  = xcbs.base_code
      AND xsfi2.selling_from_cust_code  = xcbs.delivery_cust_code
      AND xcbs.closing_date       BETWEEN gd_target_date_from
                                      AND LAST_DAY( gd_target_date_from )
      AND xcbs.supplier_code            = gt_supplier_dummy      -- 仕入先CD(ダミー)
      AND xcbs.amt_fix_status           = cv_amt_fix_status      -- 金額確定ステータス：1 確定
      AND xcbs.ar_interface_status      = cv_ar_interface_status -- AR連携ステータス  ：1 連携済
      AND xsfi2.selling_from_cust_code  = ship_hca2.account_number
      AND ship_hca2.customer_class_code = cv_customer_class_customer
      AND ship_hca2.party_id            = ship_hp2.party_id
      AND ship_hp2.duns_number_c       IN (  cv_customer_status_30
                                           , cv_customer_status_40
                                           , cv_customer_status_50
                                         )
      AND ship_hca2.cust_account_id      = ship_xca2.customer_id
      AND ship_xca2.selling_transfer_div = cv_xca_transfer_div_on
      AND msib.organization_id           = gn_organization_id     -- 在庫組織ID
      AND msib.segment1                  = xsib.item_code
      AND xsib.item_code                 = xrtrv.item_code
      AND avtab.tax_code                 = xcbs.tax_code
      AND avtab.enabled_flag             = cv_enable
      AND avtab.set_of_books_id          = gn_set_of_books_id
      AND flvv.lookup_type               = cv_payment_discounts_code_type
      AND flvv.meaning                   = xsib.item_code
      AND flvv.enabled_flag              = cv_enable
      AND xcbs.tax_code                  IN ( xrtrv.tax_class_sales_outside
                                           ,  xrtrv.tax_class_sales_inside
                                         )
      --税率マスタのDFF3がNULL(旧税率)の場合は値引品目コードをプロファイルで取得した値に固定する
      AND ( ( avtab.attribute3 IS NULL
          AND msib.segment1    = gt_item_code 
            )
      --税率マスタのDFF3に値がある(新税率)の場合は税コードから逆引きした値引品目コードを使用
        OR  ( avtab.attribute3 IS NOT NULL
            )
          )
      AND EXISTS ( SELECT 'X'
                   FROM hz_cust_acct_sites   ship_hcas2   -- 【出荷先】顧客所在地
                      , hz_party_sites       ship_hps2    -- 【出荷先】顧客パーティサイト
                      , hz_cust_site_uses    ship_hcsu2   -- 【出荷先】顧客使用目的
                      , hz_cust_site_uses    bill_hcsu2   -- 【請求先】顧客使用目的
                      , hz_cust_acct_sites   bill_hcas2   -- 【請求先】顧客所在地
                      , hz_cust_accounts     bill_hca2    -- 【請求先】顧客マスタ
                   WHERE ship_hcas2.cust_account_id         = ship_hca2.cust_account_id
                     AND ship_hps2.party_id                 = ship_hp2.party_id
                     AND ship_hcas2.party_site_id           = ship_hps2.party_site_id
                     AND ship_hcas2.cust_acct_site_id       = ship_hcsu2.cust_acct_site_id
                     AND ship_hcsu2.site_use_code           = cv_site_use_code_ship
                     AND ship_hcsu2.bill_to_site_use_id     = bill_hcsu2.site_use_id
                     AND bill_hcsu2.site_use_code           = cv_site_use_code_bill
                     AND ship_hcsu2.status                  = cv_cust_status_available
                     AND bill_hcsu2.status                  = cv_cust_status_available
                     AND bill_hcsu2.cust_acct_site_id       = bill_hcas2.cust_acct_site_id
                     AND bill_hcas2.cust_account_id         = bill_hca2.cust_account_id
                     AND ROWNUM                             = 1
                 )
      AND EXISTS ( SELECT 'X'
                   FROM xxcos_sales_exp_headers   xseh2            -- 販売実績ヘッダー
                      , xxcos_sales_exp_lines     xsel2            -- 販売実績明細
                   WHERE 
                         xseh2.sales_base_code              = xsfi2.selling_from_base_code
                     AND xseh2.ship_to_customer_code        = xsfi2.selling_from_cust_code
                     AND xseh2.delivery_date          BETWEEN gd_target_date_from
                                                          AND LAST_DAY( gd_target_date_from )
                     AND xseh2.dlv_invoice_class           IN (  cv_invoice_class_01
                                                               , cv_invoice_class_02
                                                               , cv_invoice_class_03
                                                               , cv_invoice_class_04
                                                              )
                     AND xseh2.sales_exp_header_id          = xsel2.sales_exp_header_id
                     AND xsel2.business_cost               IS NOT NULL
                     AND ROWNUM                             = 1
                 )
      AND EXISTS ( SELECT 'X'
                   FROM xxcok_selling_to_info        xsti2
                      , xxcok_selling_rate_info      xsri2
                      , hz_cust_accounts             hca2
                      , xxcmm_cust_accounts          xca2
                      , hz_parties                   hp2
                   WHERE xsti2.selling_from_info_id       = xsfi2.selling_from_info_id
                     AND xsti2.selling_to_cust_code       = xsri2.selling_to_cust_code
                     AND xsti2.start_month               <= TO_CHAR( gd_process_date, 'RRRRMM' )
                     AND xsti2.invalid_flag               = cv_invalid_flag_valid
                     AND xsri2.selling_from_base_code     = xsfi2.selling_from_base_code
                     AND xsri2.selling_from_cust_code     = ship_hca2.account_number
                     AND xsri2.invalid_flag               = cv_invalid_flag_valid
                     AND xsti2.selling_to_cust_code       = hca2.account_number
                     AND hca2.customer_class_code         = cv_customer_class_customer
                     AND hca2.cust_account_id             = xca2.customer_id
                     AND xca2.selling_transfer_div        = cv_xca_transfer_div_on
                     AND hca2.party_id                    = hp2.party_id
                     AND hp2.duns_number_c               IN (  cv_customer_status_30
                                                             , cv_customer_status_40
                                                             , cv_customer_status_50
                                                            )
                     AND ROWNUM                           = 1
          )
  GROUP BY
           xcbs.closing_date
         , xsfi2.selling_from_base_code
         , xsfi2.selling_from_cust_code
         , ship_hp2.party_name
         , xxcok_common_pkg.get_sales_staff_code_f(
             xsfi2.selling_from_cust_code
           , xcbs.closing_date
           )
         , ship_xca2.business_low_type
         , xcbs.demand_to_cust_code
         , msib.segment1
         , msib.primary_uom_code
         , xcbs.tax_code
         , xcbs.tax_rate
  ;
--
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
      AND xca.selling_transfer_div      = cv_xca_transfer_div_on
      AND hp.party_id                   = hca.party_id
      AND hp.duns_number_c             IN (   cv_customer_status_30
                                            , cv_customer_status_40
                                            , cv_customer_status_50
                                          )
    ORDER BY xsri.selling_trns_rate       ASC
           , xsri.selling_to_cust_code    DESC
  ;
--
  --==================================================
  -- グローバルタイプ
  --==================================================
--
  TYPE get_selling_to_ttype        IS TABLE OF get_selling_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : update_xsti
   * Description      : 伝票番号更新(A-9)
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
    cv_slip_no_prefix              CONSTANT VARCHAR2(1)  := 'K';                       -- 伝票番号接頭語
    cv_slip_no_format              CONSTANT VARCHAR2(13) := 'FM00000000000';           -- 伝票番号接頭語以下桁数
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    -- ブレイク判定用変数
    lt_break_selling_date          xxcok_dedu_sell_trns_info.selling_date%TYPE DEFAULT NULL;        -- 
    lt_break_demand_to_cust_code   xxcok_dedu_sell_trns_info.demand_to_cust_code%TYPE DEFAULT NULL; -- 振替元顧客コード
    lt_break_base_code             xxcok_dedu_sell_trns_info.base_code%TYPE DEFAULT NULL;           -- 拠点コード
    lt_break_cust_code             xxcok_dedu_sell_trns_info.cust_code%TYPE DEFAULT NULL;           -- 顧客コード
    lt_break_item_code             xxcok_dedu_sell_trns_info.item_code%TYPE DEFAULT NULL;           -- 品目コード
    -- 更新値用変数
    lt_slip_no                     xxcok_dedu_sell_trns_info.slip_no  %TYPE DEFAULT NULL; -- 伝票番号
    lt_detail_no                   xxcok_dedu_sell_trns_info.detail_no%TYPE DEFAULT NULL; -- 明細番号
    --==================================================
    -- ロック取得カーソル
    --==================================================
    CURSOR update_xsti_cur
    IS
      SELECT xdsti.selling_trns_info_id       AS selling_trns_info_id      -- 売上実績振替情報ID
           , xdsti.selling_date               AS selling_date              -- 売上計上日
           , xdsti.demand_to_cust_code        AS demand_to_cust_code       -- 振替元顧客コード
           , xdsti.base_code                  AS base_code                 -- 拠点コード
           , xdsti.cust_code                  AS cust_code                 -- 顧客コード
           , xdsti.item_code                  AS item_code                 -- 品目コード
           , xdsti.delivery_unit_price        AS delivery_unit_price       -- 納品単価
      FROM xxcok_dedu_sell_trns_info      xdsti
      WHERE xdsti.selling_trns_info_id >= gt_selling_trns_info_id_min
        AND xdsti.request_id            = cn_request_id
        AND xdsti.slip_no              IS NULL
        AND xdsti.detail_no            IS NULL
      ORDER BY xdsti.selling_date
             , xdsti.demand_to_cust_code
             , xdsti.base_code
             , xdsti.cust_code
             , xdsti.item_code
             , xdsti.delivery_unit_price
      FOR UPDATE OF xdsti.selling_trns_info_id NOWAIT
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
        SELECT cv_slip_no_prefix || TO_CHAR( xxcok_dedu_sell_trns_info_s02.NEXTVAL, cv_slip_no_format )
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
      UPDATE xxcok_dedu_sell_trns_info    xdsti
      SET xdsti.slip_no                  = lt_slip_no
        , xdsti.detail_no                = lt_detail_no
        , xdsti.last_updated_by          = cn_last_updated_by
        , xdsti.last_update_date         = SYSDATE
        , xdsti.last_update_login        = cn_last_update_login
        , xdsti.request_id               = cn_request_id
        , xdsti.program_application_id   = cn_program_application_id
        , xdsti.program_id               = cn_program_id
        , xdsti.program_update_date      = SYSDATE
      WHERE xdsti.selling_trns_info_id   = update_xsti_rec.selling_trns_info_id
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
   * Description      : 売上振替情報の登録(A-6)(A-8)
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
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lt_sales_amount                xxcok_selling_trns_info.selling_amt%TYPE;
    lt_pure_amount                 xxcok_selling_trns_info.selling_amt_no_tax%TYPE;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
--
    --入金値引データは符号を逆転する
    IF ( i_selling_from_rec.data_type = cn_payment_discounts ) THEN
      -- 売上金額
      lt_sales_amount := in_sales_amount * -1;
      -- 本体金額
      lt_pure_amount  := in_pure_amount * -1;
    ELSE
      -- 売上金額
      lt_sales_amount := in_sales_amount;
      -- 本体金額
      lt_pure_amount  := in_pure_amount;
    END IF;
    --==================================================
    -- 売上振替情報の登録
    --==================================================
    INSERT INTO xxcok_dedu_sell_trns_info(
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
    , selling_from_cust_code                      -- 売上振替元顧客コード
    , created_by                                  -- 作成者
    , creation_date                               -- 作成日
    , last_updated_by                             -- 最終更新者
    , last_update_date                            -- 最終更新日
    , last_update_login                           -- 最終更新ログイン
    , request_id                                  -- 要求ID
    , program_application_id                      -- コンカレント・プログラム･アプリケーションID
    , program_id                                  -- コンカレント･プログラムID
    , program_update_date                         -- プログラム更新日
-- 2020/06/15 Add S
    , product_class                               -- 商品区分
-- 2020/06/15 Add E
    )
    VALUES(
      xxcok_dedu_sell_trns_info_s01.NEXTVAL       -- selling_trns_info_id
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
    , i_selling_from_rec.dlv_unit_price           -- delivery_unit_price
    , lt_sales_amount                             -- selling_amt
    , lt_pure_amount                              -- selling_amt_no_tax
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
    , i_selling_from_rec.ship_cust_code           -- selling_from_cust_code
    , cn_created_by                               -- created_by
    , SYSDATE                                     -- creation_date
    , cn_last_updated_by                          -- last_updated_by
    , SYSDATE                                     -- last_update_date
    , cn_last_update_login                        -- last_update_login
    , cn_request_id                               -- request_id
    , cn_program_application_id                   -- program_application_id
    , cn_program_id                               -- program_id
    , SYSDATE                                     -- program_update_date
-- 2020/06/15 Add S
    , gt_product_class                            -- product_class
-- 2020/06/15 Add E
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
    -- 端数計算用集計変数
    ln_dlv_qty_sum                 NUMBER         DEFAULT 0;                    -- 納品数量
    ln_sales_amount_sum            NUMBER         DEFAULT 0;                    -- 売上金額
    ln_pure_amount_sum             NUMBER         DEFAULT 0;                    -- 本体金額
    -- 振替割合チェック
    ln_selling_trns_rate_total     NUMBER         DEFAULT 0;                    -- 振替割合の合計が100とならない場合はエラー
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
      -- 納品数量
      ln_dlv_qty       := ROUND( i_selling_from_rec.dlv_qty_sum      * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 売上金額
      ln_sales_amount  := ROUND( i_selling_from_rec.sales_amount_sum * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 本体金額
      ln_pure_amount   := ROUND( i_selling_from_rec.pure_amount_sum  * l_get_selling_to_tab(i).selling_trns_rate / 100, 0 );
      -- 売上原価
      ln_sales_cost    := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                      i_selling_from_rec.item_code
                                                                    , i_selling_from_rec.dlv_uom_code
                                                                    , ln_dlv_qty
                                                                    )
                                 , 0
                          )
      ;
      --==================================================
      -- 売上原価チェック
      --==================================================
      IF( ln_sales_cost IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_10452
                      , iv_token_name1          => cv_tkn_item_code
                      , iv_token_value1         => i_selling_from_rec.item_code
                      , iv_token_name2          => cv_tkn_dlv_uom_code
                      , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- 端数計算用集計
      ln_dlv_qty_sum      := ln_dlv_qty_sum      + ln_dlv_qty;
      ln_sales_amount_sum := ln_sales_amount_sum + ln_sales_amount;
      ln_pure_amount_sum  := ln_pure_amount_sum  + ln_pure_amount;
      -- 端数調整
      IF( i = l_get_selling_to_tab.LAST ) THEN
        -- 納品数量
        ln_dlv_qty      := ln_dlv_qty      + i_selling_from_rec.dlv_qty_sum       - ln_dlv_qty_sum;
        -- 売上金額
        ln_sales_amount := ln_sales_amount + i_selling_from_rec.sales_amount_sum  - ln_sales_amount_sum;
        -- 本体金額
        ln_pure_amount  := ln_pure_amount  + i_selling_from_rec.pure_amount_sum   - ln_pure_amount_sum;
        -- 売上原価
        ln_sales_cost   := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                       i_selling_from_rec.item_code
                                                                     , i_selling_from_rec.dlv_uom_code
                                                                     , ln_dlv_qty
                                                                     )
                                , 0
                           )
        ;
        --==================================================
        -- 売上原価チェック
        --==================================================
        IF( ln_sales_cost_out IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => i_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
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
        ln_sales_cost_out   := ROUND( i_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                           i_selling_from_rec.item_code
                                                                         , i_selling_from_rec.dlv_uom_code
                                                                         , ln_dlv_qty_out
                                                                         )
                                    , 0
                               )
        ;
        --==================================================
        -- 売上原価チェック
        --==================================================
        IF( ln_sales_cost_out IS NULL ) THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10452
                        , iv_token_name1          => cv_tkn_item_code
                        , iv_token_value1         => i_selling_from_rec.item_code
                        , iv_token_name2          => cv_tkn_dlv_uom_code
                        , iv_token_value2         => i_selling_from_rec.dlv_uom_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
        END IF;
      ELSE
        -- 売上振替情報の登録プロシージャ呼び出し
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
      END IF;
      --==================================================
      -- 振替割合チェック用集計
      --==================================================
      ln_selling_trns_rate_total := ln_selling_trns_rate_total + l_get_selling_to_tab(i).selling_trns_rate;
    END LOOP sub_loop;
    --==================================================
    -- 振替割合チェック(A-7)
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
-- 2020/06/15 Add S
        --==================================================
        -- 商品区分の取得
        --==================================================
        BEGIN
          SELECT SUBSTRB(mcv.segment1,1,1)      segment1             -- 商品区分
          INTO   gt_product_class
          FROM   mtl_categories_vl        mcv
                ,gmi_item_categories      gic
                ,mtl_category_sets_vl     mcsv
                ,xxcmm_system_items_b     xsib
          WHERE  mcsv.category_set_name   = cv_cate_set_name
          AND    gic.item_id              = xsib.item_id
          AND    gic.category_set_id      = mcsv.category_set_id
          AND    gic.category_id          = mcv.category_id
          AND    xsib.item_code           = get_selling_from_rec.item_code
          ;
        EXCEPTION
          WHEN OTHERS THEN
            gt_product_class := NULL ;
        END ;
-- 2020/06/15 Add E
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
        -- 売上振替元情報の登録(A-8)
        --==================================================
        -- 納品数量（相殺）
        ln_dlv_qty_counter         := get_selling_from_rec.dlv_qty_sum      * -1 + ln_dlv_qty;
        -- 売上金額（相殺）
        ln_sales_amount_counter    := get_selling_from_rec.sales_amount_sum * -1 + ln_sales_amount;
        -- 本体金額（相殺）
        ln_pure_amount_counter     := get_selling_from_rec.pure_amount_sum  * -1 + ln_pure_amount;
        -- 売上原価（相殺）
        ln_sales_cost_counter      := ROUND( get_selling_from_rec.business_cost * xxcok_common_pkg.get_uom_conversion_qty_f(
                                                                                  get_selling_from_rec.item_code
                                                                                , get_selling_from_rec.dlv_uom_code
                                                                                , ln_dlv_qty_counter
                                                                                )
                                           , 0
                                      )
        ;
        --==================================================
        -- 基準数量取得エラーチェック
        --==================================================
        IF( ln_sales_cost_counter IS NULL ) THEN
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
          gn_skip_cnt := gn_skip_cnt + 1;
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
   * Procedure Name   : data_delite
   * Description      : 控除用実績振替データ削除処理(A-2)
   ***********************************************************************************/
  PROCEDURE data_delite(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_delite';                         -- プログラム名
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
  BEGIN
--
    -- 削除処理
    DELETE
    FROM  xxcok_dedu_sell_trns_info    xdsi
    WHERE xdsi.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xdsi.report_decision_flag ）
    AND   xdsi.selling_date            >= gd_target_date_from
    AND   xdsi.selling_date            <= gd_target_date_to
    ;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_delite;
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
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_period_status               VARCHAR2(10)   DEFAULT NULL;                 -- 会計期間ステータスチェック用戻り値
    ld_target_date_from            DATE           DEFAULT NULL;                 -- 会計期間関数OUT取得用(ダミー)
    ld_target_date_to              DATE           DEFAULT NULL;                 -- 会計期間関数OUT取得用(ダミー)
    lv_organization_code           VARCHAR2(50)   DEFAULT NULL;                 -- 在庫組織コード
    ln_organization_id             NUMBER         DEFAULT NULL;                 -- 在庫組織ID
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
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
    --==============================================================
    -- 1.情報種別チェック
    --==============================================================
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
--
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
    --==============================================================
    -- 2.業務日付取得
    --==============================================================
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
--
    --==============================================================
    -- 3.会計期間状態チェック
    --==============================================================
    -- 当月会計期間チェック
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv       -- IN  VARCHAR2 '01'(会計期間INV)
    , id_base_date        => gd_process_date         -- IN  DATE     処理日(対象日)
    , ov_status           => lv_period_status        -- OUT VARCHAR2 ステータス
    , od_start_date       => ld_target_date_from     -- OUT DATE     会計期間(FROM)
    , od_end_date         => ld_target_date_to       -- OUT DATE     会計期間(TO)
    , ov_errbuf           => lv_errbuf               -- OUT VARCHAR2 エラー・メッセージエラー
    , ov_retcode          => lv_retcode              -- OUT VARCHAR2 リターン・コード
    , ov_errmsg           => lv_errmsg               -- OUT VARCHAR2 ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
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
--
    -- 前月会計期間チェック
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv                  -- IN  VARCHAR2 '01'(会計期間INV)
    , id_base_date        => ADD_MONTHS( gd_process_date, - 1 ) -- IN  DATE     処理日(対象日)
    , ov_status           => lv_period_status                   -- OUT VARCHAR2 ステータス
    , od_start_date       => ld_target_date_from                -- OUT DATE     会計期間(FROM)
    , od_end_date         => ld_target_date_to                  -- OUT DATE     会計期間(TO)
    , ov_errbuf           => lv_errbuf                          -- OUT VARCHAR2 エラー・メッセージエラー
    , ov_retcode          => lv_retcode                         -- OUT VARCHAR2 リターン・コード
    , ov_errmsg           => lv_errmsg                          -- OUT VARCHAR2 ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
--
    --==================================================
    -- 売上振替情報登録最小ID取得
    --==================================================
    SELECT xxcok_dedu_sell_trns_info_s01.NEXTVAL
    INTO gt_selling_trns_info_id_min
    FROM DUAL
    ;
--
    --==============================================================
    -- 4.情報種別が確定時処理
    --==============================================================
    -- 情報種別が"1"(確定）の場合
    IF ( gv_param_info_class = cv_info_class_decision ) THEN
      -- プロファイル(入金値引取得)
      gt_item_code := FND_PROFILE.VALUE( cv_profile_name_02 );
      IF( gt_item_code IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_02
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- プロファイル(在庫組織コード)
      lv_organization_code := FND_PROFILE.VALUE( cv_profile_name_03 );
      IF( lv_organization_code IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_03
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      -- 在庫組織ID
      ln_organization_id := xxcoi_common_pkg.get_organization_id( lv_organization_code );
      IF ( ln_organization_id IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_coi
                      , iv_name                 => cv_msg_coi_00006
                      , iv_token_name1          => cv_tkn_org_code
                      , iv_token_value1         => lv_organization_code
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
      --
      gn_organization_id := ln_organization_id;
      --
      -- プロファイル(仕入先ダミーコード)
      gt_supplier_dummy := FND_PROFILE.VALUE( cv_profile_name_04 );
      IF( gt_supplier_dummy IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00003
                      , iv_token_name1          => cv_tkn_profile
                      , iv_token_value1         => cv_profile_name_04
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
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
    -- 控除用実績振替データ削除処理(A-2)
    --==================================================  
    data_delite(
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
    -- 伝票番号更新(A-9)
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
--
END XXCOK024A04C;
/
