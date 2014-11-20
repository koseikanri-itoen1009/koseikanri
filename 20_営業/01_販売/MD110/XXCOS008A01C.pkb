CREATE OR REPLACE PACKAGE BODY XXCOS008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A01C(body)
 * Description      : 工場直送出荷依頼IF作成を行う
 * MD.050           : 工場直送出荷依頼IF作成 MD050_COS_008_A01
 * Version          : 1.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        初期処理(A-1)
 *  get_order_data              受注データ取得(A-2)
 *  get_ship_subinventory       出荷元保管場所取得(A-3)
 *  get_ship_schedule_date      出荷予定日取得(A-4)
 *  data_check                  データチェック(A-5)
 *  make_normal_order_data      PL/SQL表設定(A-6)
 *  make_request_line_bulk_data 出荷依頼I/F明細バルクバインドデータ作成(A-7)
 *  make_request_head_bulk_data 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
 *  insert_ship_line_data       出荷依頼I/F明細データ作成(A-9)
 *  insert_ship_header_data     出荷依頼I/Fヘッダデータ作成(A-10)
 *  update_order_line           受注明細更新(A-11)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   K.Atsushiba      新規作成
 *  2009/02/05    1.1   K.Atsushiba      COS_035対応  出荷依頼I/Fヘッダーの依頼区分に「4」を設定。
 *  2009/02/18    1.2   K.Atsushiba      get_msgのパッケージ名修正
 *  2009/02/23    1.3   K.Atsushiba      パラメータのログファイル出力対応
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg            VARCHAR2(2000);
  gv_sep_msg            VARCHAR2(2000);
  gv_exec_user          VARCHAR2(100);
  gv_conc_name          VARCHAR2(30);
  gv_conc_status        VARCHAR2(30);
  gn_target_cnt         NUMBER;                    -- 対象件数
  gn_header_normal_cnt  NUMBER;                    -- 正常件数(ヘッダー)
  gn_line_normal_cnt    NUMBER;                    -- 正常件数(明細)
  gn_error_cnt          NUMBER;                    -- エラー件数
  gn_warn_cnt           NUMBER;                    -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCOS008A01C'; -- パッケージ名
  -- アプリケーション短縮名
  cv_xxcos_short_name           CONSTANT VARCHAR2(10) := 'XXCOS';
  -- メッセージ
  cv_msg_lock_error             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    -- ロックエラー
  cv_msg_notfound_profile       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004';    -- プロファイル取得エラー
  cv_msg_notfound_db_data       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003';    -- 対象データ無しエラー
  cv_msg_update_error           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    -- データ更新エラー
  cv_msg_data_extra_error       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    -- データ抽出エラー
  cv_msg_org_id                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00047';    -- 営業単位
  cv_msg_non_business_date      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11601';    -- 業務日付取得エラー
  cv_msg_lead_time_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11602';    -- リードタイム算出エラー
  cv_msg_non_operation_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11603';    -- 稼働日取得エラー
  cv_msg_non_input_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11604';    -- 必須入力エラー
  cv_msg_class_val_error        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11605';    -- 区分値エラー
  cv_msg_operation_date_error   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11606';    -- 稼働日エラー
  cv_msg_ship_schedule_validite CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11607';    -- 出荷予定日妥当性エラー
  cv_msg_ship_schedule_calc     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11608';    -- 出荷予定日導出エラー
  cv_msg_order_date_validite    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11609';    -- 受注日妥当性エラー
  cv_msg_conc_parame            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11610';    -- 入力パラメータ出力
  cv_msg_order_number           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11611';    -- 受注番号
  cv_msg_line_number            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11612';    -- 明細番号
  cv_msg_item_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11613';    -- 品目コード
  cv_msg_send_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11614';    -- 配送先コード
  cv_msg_deli_expect_date       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11615';    -- 納品予定日
  cv_msg_order_table_name       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11616';    -- 受注テーブル
  cv_msg_order_date             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11617';    -- 受注日
  cv_msg_cust_account_id        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11618';    -- 顧客ID
  cv_msg_cust_po_number         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11619';    -- 顧客発注
  cv_msg_ship_schedule_date     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11620';    -- 出荷予定日
  cv_msg_request_date           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11621';    -- 要求日
  cv_msg_ship_subinv            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11622';    -- 出荷元保管場所
  cv_msg_base_code              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11623';    -- 納品拠点コード
  cv_msg_order_table            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11624';    -- 受注テーブル
  cv_msg_order_header_line      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11625';    -- 受注ヘッダ/明細
  cv_msg_ou_mfg                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11626';    -- 生産営業単位
  cv_msg_ship_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11627';    -- 出荷区分
  cv_msg_sales_div              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11628';    -- 売上対象区分
  cv_msg_customer_order_flag    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11629';    -- 顧客受注可能フラグ
  cv_msg_rate_class             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11630';    -- 率区分
  cv_msg_header_nomal_count     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11631';    -- ヘッダ成功件数
  cv_msg_line_nomal_count       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11632';    -- 明細成功件数
  cv_msg_order_line             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11633';    -- 受注明細
  cv_msg_hokan_direct_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11634';    -- 保管場所分類取得エラー
  cv_msg_delivery_base_code     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11635';    -- 拠点コード
  cv_msg_col_name               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11636';    -- 名称
  cv_msg_ou_org_name            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11637';    -- 生産営業単位
  cv_msg_shipping_class         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-11324';    -- 依頼区分取得エラー
  -- プロファイル
  cv_pf_org_id                  CONSTANT VARCHAR2(30) := 'ORG_ID';              -- MO:営業単位
  cv_pf_ou_mfg                  CONSTANT VARCHAR2(30) := 'XXCOS1_ITOE_OU_MFG';  -- 生産営業単位
  -- メッセージトークン
  cv_tkn_profile                CONSTANT VARCHAR2(20) := 'PROFILE';             -- プロファイル名
  cv_tkn_param1                 CONSTANT VARCHAR2(20) := 'PARAM1';              -- パラメータ1(拠点コード)
  cv_tkn_param2                 CONSTANT VARCHAR2(20) := 'PARAM2';              -- パラメータ2(受注番号)
  cv_tkn_table_name             CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- テーブル名
  cv_tkn_key_data               CONSTANT VARCHAR2(20) := 'KEY_DATA';            -- キー情報
  cv_tkn_order_no               CONSTANT VARCHAR2(20) := 'ORDER_NO';            -- 受注番号
  cv_tkn_line_no                CONSTANT VARCHAR2(20) := 'LINE_NO';             -- 明細番号
  cv_tkn_field_name             CONSTANT VARCHAR2(20) := 'FIELD_NAME';          -- 項目名
  cv_tkn_table                  CONSTANT VARCHAR2(20) := 'TABLE';               -- テーブル
  cv_tkn_divide_value           CONSTANT VARCHAR2(20) := 'DIVIDE_VALUE';        -- 区分値
  cv_tkn_val                    CONSTANT VARCHAR2(20) := 'VAL';                 -- 値
  cv_tkn_order_date             CONSTANT VARCHAR2(20) := 'ORDER_DATE';          -- 受注日
  cv_tkn_operation_date         CONSTANT VARCHAR2(20) := 'OPERATION_DATE';      -- 算出受注日
  cv_tkn_code_from              CONSTANT VARCHAR2(20) := 'CODE_FROM';           -- コード区分From
  cv_tkn_stock_from             CONSTANT VARCHAR2(20) := 'STOCK_FROM';          -- 入出庫区分From
  cv_tkn_code_to                CONSTANT VARCHAR2(20) := 'CODE_TO';             -- コード区分To
  cv_tkn_stock_to               CONSTANT VARCHAR2(20) := 'STOCK_TO';            -- 入出庫区分To
  cv_tkn_stock_form_id          CONSTANT VARCHAR2(20) := 'STOCK_FORM_ID';       -- 出庫形態ID
  cv_tkn_base_date              CONSTANT VARCHAR2(20) := 'BASE_DATE';           -- 基準日
  cv_tkn_operate_date           CONSTANT VARCHAR2(20) := 'OPERATE_DATE';        -- 出荷予定日
  cv_tkn_whse_locat             CONSTANT VARCHAR2(20) := 'WHSE_LOCAT';          -- 保管倉庫コード
  cv_tkn_delivery_code          CONSTANT VARCHAR2(20) := 'DELIVERY_CODE';       -- 配送先コード
  cv_tkn_lead_time              CONSTANT VARCHAR2(20) := 'LEAD_TIME';           -- リードタイム
  cv_tkn_commodity_class        CONSTANT VARCHAR2(20) := 'COMMODITY_CLASS';     -- 商品区分
  cv_tkn_type                   CONSTANT VARCHAR2(20) := 'TYPE';                -- 参照タイプ
  cv_tkn_code                   CONSTANT VARCHAR2(20) := 'CODE';                -- 参照コード
  -- 参照タイプ
  cv_hokan_type_mst_t           CONSTANT VARCHAR2(50) := 'XXCOS1_HOKAN_DIRECT_TYPE_MST';        -- 保管場所分類
  cv_hokan_type_mst_c           CONSTANT VARCHAR2(50) := 'XXCOS_DIRECT_11';                     -- 保管場所分類
  cv_tran_type_mst_t            CONSTANT VARCHAR2(50) := 'XXCOS1_TRAN_TYPE_MST_008_A01';        -- 受注タイプ
  cv_non_inv_item_mst_t         CONSTANT VARCHAR2(50) := 'XXCOS1_NO_INV_ITEM_CODE';             -- 非在庫品目
  cv_shipping_class_t           CONSTANT VARCHAR2(50) := 'XXWSH_SHIPPING_CLASS';                -- 出荷区分(タイプ)
  cv_shipping_class_c           CONSTANT VARCHAR2(50) := '02';                                  -- 出荷区分(コード)
  -- 日時フォーマット
  cv_date_fmt_date_time         CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt_no_sep            CONSTANT VARCHAR2(25) := 'YYYYMMDD';
  --データチェックステータス値
  cn_check_status_normal        CONSTANT  NUMBER := 0;                    -- 正常
  cn_check_status_error         CONSTANT  NUMBER := -1;                   -- エラー
  -- 記帳フラグ
  cv_booked_flag_end            CONSTANT VARCHAR2(1) := 'Y';              -- 済み
  -- 有効フラグ
  cv_enabled_flag               CONSTANT VARCHAR2(1) := 'Y';              -- 有効
  --
  cn_customer_div_cust          CONSTANT  VARCHAR2(4)   := '10';          --顧客
  cv_cust_site_use_code         CONSTANT  VARCHAR2(10)  := 'SHIP_TO';     --顧客使用目的：出荷先
  -- 明細ステータス
  cv_flow_status_cancelled      CONSTANT VARCHAR2(10) := 'CANCELLED';     -- 取消
  cv_flow_status_closed         CONSTANT VARCHAR2(10) := 'CLOSED';        -- クローズ
  -- 文字定数
  cv_blank                      CONSTANT VARCHAR2(1) := '';               -- 空文字
  -- リードタイム
  cn_lead_time_non              CONSTANT NUMBER := 0;                     -- リードタイムなし
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_org_id                     fnd_profile_option_values.profile_option_value%TYPE;      -- MO:営業単位
  gt_ou_mfg                     fnd_profile_option_values.profile_option_value%TYPE;      -- 生産営業単位
  gd_business_date              DATE;                                                     -- 業務日付
  gn_prod_ou_id                 NUMBER;                                                   -- 生産営業単位ID
  gv_hokan_direct_class         VARCHAR2(10);                                             -- 保管場所分類(直送倉庫)
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR order_data_cur(
    iv_base_code    IN  VARCHAR2,     -- 拠点コード
    iv_order_number IN  VARCHAR2)     -- 受注番号
  IS
    SELECT ooha.context                              context                 -- 受注タイプ
          ,TRUNC(ooha.ordered_date)                  ordered_date            -- 受注日
          ,ooha.sold_to_org_id                       sold_to_org_id          -- 顧客コード
          ,ooha.shipping_instructions                shipping_instructions   -- 出荷指示
          ,ooha.cust_po_number                       cust_po_number          -- 顧客発注
          ,TRUNC(oola.request_date)                  request_date            -- 要求日
          ,NVL(oola.attribute6, oola.ordered_item)   child_code              -- 受注品目
          ,TRUNC(oola.schedule_ship_date)            schedule_ship_date      -- 予定出荷日
          ,oola.ordered_quantity                     ordered_quantity        -- 受注数量
          ,xca.delivery_base_code                    delivery_base_code      -- 納品拠点コード
          ,hl.province                               province                -- 配送先コード
          ,msib.segment1                             item_code               -- 品目コード
          ,xicv.prod_class_name                      item_div_name           -- 商品区分名
          ,xicv.prod_class_code                      prod_class_code         -- 商品区分コード
          ,ooha.order_number                         order_number            -- 受注番号
          ,oola.line_number                          line_number             -- 明細番号
          ,oola.rowid                                row_id                  -- 行ID
          ,oola.attribute5                           sales_class             -- 売上区分
          ,msib.customer_order_enabled_flag          customer_order_flag     -- 顧客受注可能
          ,msib.inventory_item_id                    inventory_item_id       -- 品目ID
          ,oola.order_quantity_uom                   order_quantity_uom      -- 受注単位
          ,ooha.attribute19                          cust_po_number_att19    -- 顧客発注
          ,oola.line_id                              line_id                 -- 明細ID
          ,oola.ship_from_org_id                     ship_from_org_id        -- 組織ID
          ,NVL(oola.attribute8,ooha.attribute13)     time_from               -- 時間指定FROM
          ,NVL(oola.attribute9,ooha.attribute14)     time_to                 -- 時間指定TO
          ,ooha.header_id                            header_id               -- ヘッダID
          ,NULL                                      ship_to_subinv          -- 出荷元保管場所(A-3で設定)
          ,NULL                                      lead_time               -- リードタイム(生産物流)
          ,NULL                                      delivery_lt             -- リードタイム(配送)
          ,NULL                                      req_header_id           -- 出荷依頼用ヘッダーID
          ,NULL                                      conv_ordered_quantity   -- 換算後受注数量
          ,NULL                                      conv_order_quantity_uom -- 換算後受注単位
          ,NULL                                      sort_key                -- ソートキー
          ,cn_check_status_normal                    check_status            -- チェックステータス
    FROM   oe_order_headers_all                   ooha             -- 受注ヘッダ
          ,oe_order_lines_all                     oola             -- 受注明細
          ,hz_cust_accounts                       hca              -- 顧客マスタ
          ,mtl_system_items_b                     msib             -- 品目マスタ
          ,oe_transaction_types_tl                ottah            -- 受注取引タイプ（受注ヘッダ用）
          ,oe_transaction_types_tl                ottal            -- 受注取引タイプ（受注明細用）
          ,mtl_secondary_inventories              msi              -- 保管場所マスタ
          ,xxcmn_item_categories5_v               xicv             -- 商品区分View
          ,xxcmm_cust_accounts                    xca              -- 顧客追加情報
          ,hz_cust_acct_sites_all                 sites            -- 顧客所在地
          ,hz_cust_site_uses_all                  uses             -- 顧客使用目的
          ,hz_party_sites                         hps              -- パーティサイトマスタ
          ,hz_locations                           hl               -- 顧客事業所マスタ
          ,fnd_lookup_values                      flv_tran         -- LookUp参照テーブル(明細.受注タイプ)
    WHERE ooha.header_id                          = oola.header_id                            -- ヘッダーID
    AND   ooha.booked_flag                        = cv_booked_flag_end                        -- ステータス
    AND   oola.flow_status_code                   NOT IN (cv_flow_status_cancelled
                                                         ,cv_flow_status_closed)              -- ステータス(明細)
    AND   ooha.sold_to_org_id                     = hca.cust_account_id                       -- 顧客ID
    AND   ooha.order_type_id                      = ottah.transaction_type_id                 -- 取引タイプID
    AND   ottah.language                          = USERENV('LANG')
    AND   ottah.name                              = flv_tran.attribute1                       -- 取引名称
    AND   oola.line_type_id                       = ottal.transaction_type_id
    AND   ottal.language                          = USERENV('LANG')
    AND   ottal.name                              = flv_tran.attribute2                       -- 取引名称
    AND   oola.subinventory                       = msi.secondary_inventory_name              -- 保管場所
    AND   msi.attribute13                         = gv_hokan_direct_class                     -- 保管場所区分
    AND   xca.delivery_base_code                  = NVL(iv_base_code, xca.delivery_base_code)  -- 納品拠点コード
    AND   ooha.order_number                       = NVL(iv_order_number, ooha.order_number)    -- 受注ヘッダ番号
    AND   oola.packing_instructions               IS NULL                                     -- 出荷依頼
    AND   xca.customer_id                         = hca.cust_account_id                       -- 顧客ID
    AND   oola.org_id                             = gt_org_id                                 -- 営業単位
    AND   oola.ordered_item                       = msib.segment1                             -- 品目コード
    AND   xicv.item_no                            = msib.segment1                             -- 品目コード
    AND   msib.organization_id                    = oola.ship_from_org_id                     -- 組織ID
    AND   hca.cust_account_id                     = sites.cust_account_id                     -- 顧客ID
    AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- 顧客サイトID
    AND   hca.customer_class_code                 = cn_customer_div_cust                      -- 顧客区分(顧客)
    AND   uses.site_use_code                      = cv_cust_site_use_code                     -- 顧客使用目的(出荷先)
    AND   sites.org_id                            = gn_prod_ou_id                             -- 生産営業単位
    AND   uses.org_id                             = gn_prod_ou_id                             -- 生産営業単位
    AND   sites.party_site_id                     = hps.party_site_id                         -- パーティサイトID
    AND   hps.location_id                         = hl.location_id                            -- 事業所ID
    AND   hca.account_number                      IS NOT NULL                                 -- 顧客番号
    AND   hl.province                             IS NOT NULL                                 -- 配送先コード
    AND   NVL(oola.attribute6,oola.ordered_item) 
              NOT IN ( SELECT flv_non_inv.lookup_code
                       FROM   fnd_lookup_values             flv_non_inv
                       WHERE  flv_non_inv.lookup_type       = cv_non_inv_item_mst_t
                       AND    flv_non_inv.language          = USERENV('LANG')
                       AND    flv_non_inv.enabled_flag      = cv_enabled_flag)
    AND   flv_tran.lookup_type                    = cv_tran_type_mst_t
    AND   flv_tran.language                       = USERENV('LANG')
    AND   flv_tran.enabled_flag                   = cv_enabled_flag
    FOR UPDATE OF  oola.line_id
                  ,ooha.header_id
    NOWAIT
    ;
  -- ===============================
  -- ユーザー定義グローバル
  -- ===============================
  -- 受注情報テーブル
  TYPE g_n_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_cur%ROWTYPE INDEX BY VARCHAR(1000);
--
  -- 出荷依頼ヘッダ情報テーブル
  -- ヘッダID
  TYPE g_tab_h_header_id
         IS TABLE OF xxwsh_shipping_headers_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注日
  TYPE g_tab_h_ordered_date
         IS TABLE OF xxwsh_shipping_headers_if.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先
  TYPE g_tab_h_party_site_code
         IS TABLE OF xxwsh_shipping_headers_if.party_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷指示
  TYPE g_tab_h_shipping_instructions
         IS TABLE OF xxwsh_shipping_headers_if.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客発注
  TYPE g_tab_h_cust_po_number
         IS TABLE OF xxwsh_shipping_headers_if.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ソース参照
  TYPE g_tab_h_order_source_ref
         IS TABLE OF xxwsh_shipping_headers_if.order_source_ref%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷予定日
  TYPE g_tab_h_schedule_ship_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE g_tab_h_schedule_arrival_date
         IS TABLE OF xxwsh_shipping_headers_if.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元
  TYPE g_tab_h_location_code
         IS TABLE OF xxwsh_shipping_headers_if.location_code%TYPE INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE g_tab_h_head_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 入力拠点
  TYPE g_tab_h_input_sales_branch
         IS TABLE OF xxwsh_shipping_headers_if.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間From
  TYPE g_tab_h_arrival_time_from
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間To
  TYPE g_tab_h_arrival_time_to
         IS TABLE OF xxwsh_shipping_headers_if.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- データタイプ
  TYPE g_tab_h_data_type
         IS TABLE OF xxwsh_shipping_headers_if.data_type%TYPE INDEX BY BINARY_INTEGER;
  -- 受注番号
  TYPE g_tab_h_order_number
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  -- 依頼区分
  TYPE g_tab_h_order_class
         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  -- 出荷依頼明細情報テーブル
  -- ヘッダID
  TYPE g_tab_l_header_id
         IS TABLE OF xxwsh_shipping_lines_if.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE g_tab_l_line_number
         IS TABLE OF xxwsh_shipping_lines_if.line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 明細ID
  TYPE g_tab_l_line_id
         IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注品目
  TYPE g_tab_l_orderd_item_code
         IS TABLE OF xxwsh_shipping_lines_if.orderd_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE g_tab_l_orderd_quantity
         IS TABLE OF xxwsh_shipping_lines_if.orderd_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 組織
  TYPE g_tab_l_ship_from_org_id
         IS TABLE OF oe_order_lines_all.ship_from_org_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 受注明細情報テーブル
  -- ヘッダID
  TYPE g_tab_l_upd_header_id
         IS TABLE OF oe_order_lines_all.header_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- 受注明細更新用レコード変数
  TYPE gr_upd_order_line_rec IS RECORD(
     header_id                NUMBER                                              -- ヘッダーID(受注)
    ,order_source_ref         xxwsh_shipping_headers_if.order_source_ref%TYPE     -- 受注ソース参照(梱包指示)
    ,order_number             oe_order_headers_all.order_number%TYPE              -- 受注番号
    ,line_id                  oe_order_lines_all.line_id%TYPE                     -- 明細ID
    ,line_number              oe_order_lines_all.line_number%TYPE                 -- 明細番号
    ,ship_from_org_id         oe_order_lines_all.ship_from_org_id%TYPE            -- 組織ID
    ,req_header_id            NUMBER                                              -- ヘッダーID(出荷依頼)
  );
  -- 受注明細更新用テーブル
  TYPE gt_upd_order_line_ttype IS TABLE OF gr_upd_order_line_rec INDEX BY BINARY_INTEGER;
  --
  -- (品目)区分値チェック結果用レコード変数
  TYPE gr_item_info_rtype IS RECORD(
     ship_class_flag       NUMBER DEFAULT cn_check_status_normal     -- 出荷区分
    ,sales_div_flag        NUMBER DEFAULT cn_check_status_normal     -- 売上対象区分
    ,rate_class_flag       NUMBER DEFAULT cn_check_status_normal     -- 率区分
    ,cust_order_flag       NUMBER DEFAULT cn_check_status_normal     -- 顧客受注可能フラグ
  );
  -- (品目)区分値チェック結果用テーブル
  TYPE gt_item_info_ttype IS TABLE OF gr_item_info_rtype INDEX BY VARCHAR(50);
--
  -- 出荷依頼ヘッダのインサート用変数定義
  gt_ins_h_header_id                   g_tab_h_header_id;                 -- ヘッダID
  gt_ins_h_ordered_date                g_tab_h_ordered_date;              -- 受注日
  gt_ins_h_party_site_code             g_tab_h_party_site_code;           -- 出荷先
  gt_ins_h_shipping_instructions       g_tab_h_shipping_instructions;     -- 出荷指示
  gt_ins_h_cust_po_number              g_tab_h_cust_po_number;            -- 顧客発注
  gt_ins_h_order_source_ref            g_tab_h_order_source_ref;          -- 受注ソース参照
  gt_ins_h_schedule_ship_date          g_tab_h_schedule_ship_date;        -- 出荷予定日
  gt_ins_h_schedule_arrival_date       g_tab_h_schedule_arrival_date;     -- 着荷予定日
  gt_ins_h_location_code               g_tab_h_location_code;             -- 出荷元
  gt_ins_h_head_sales_branch           g_tab_h_head_sales_branch;         -- 管轄拠点
  gt_ins_h_input_sales_branch          g_tab_h_input_sales_branch;        -- 入力拠点
  gt_ins_h_arrival_time_from           g_tab_h_arrival_time_from;         -- 着荷時間From
  gt_ins_h_arrival_time_to             g_tab_h_arrival_time_to;           -- 着荷時間To
  gt_ins_h_data_type                   g_tab_h_data_type;                 -- データタイプ
  gt_ins_h_order_number                g_tab_h_order_number;              -- 受注番号
  gt_ins_h_order_class                 g_tab_h_order_class;               -- 依頼区分
--
  -- 出荷依頼明細のインサート用変数定義
  gt_ins_l_header_id                   g_tab_l_header_id;                 -- ヘッダID
  gt_ins_l_line_number                 g_tab_l_line_number;               -- 明細番号
  gt_ins_l_line_id                     g_tab_l_line_id;                   -- 明細ID
  gt_ins_l_orderd_item_code            g_tab_l_orderd_item_code;          -- 受注品目
  gt_ins_l_orderd_quantity             g_tab_l_orderd_quantity;           -- 数量
  gt_ins_l_ship_from_org_id            g_tab_l_ship_from_org_id;          -- 組織
--
  -- 受注用変数定義
  gt_order_extra_tbl                   g_n_order_data_ttype;              -- 受注用抽出データ格納
  gt_order_sort_tbl                    g_v_order_data_ttype;              -- 受注用ソートデータ格納
  gt_upd_order_line_tbl                gt_upd_order_line_ttype;           -- 明細更新用
  gt_upd_header_id                     g_tab_l_upd_header_id;             -- 明細更新用
--
  -- (品目)区分値チェック結果用変数定義
  gt_item_info_tbl                     gt_item_info_ttype;
  gt_item_info_rec                     gr_item_info_rtype;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code     IN  VARCHAR2,            -- 1.拠点コード
    iv_order_number  IN  VARCHAR2,            -- 2.受注番号
    ov_errbuf        OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_profile_name              VARCHAR2(50);   -- プロファイル名
    lv_ou_org_name               VARCHAR2(50);   -- 生産営業単位名
    lv_out_msg                   VARCHAR2(100);  -- 出力用
    lv_key_info                  VARCHAR2(1000); -- キー情報
    lv_col_name                  VARCHAR2(50);   -- カラム名称
--
    -- *** ローカル例外 ***
    notfound_hokan_direct_expt   EXCEPTION;      -- 直送倉庫保管場所区分取得エラー
    notfound_ou_org_id_expt      EXCEPTION;      -- 生産営業単位取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --===================================================
    --コンカレントプログラム入力項目をメッセージ作成
    --===================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
       iv_application  => cv_xxcos_short_name
      ,iv_name         => cv_msg_conc_parame      -- コンカレントパラメータ
      ,iv_token_name1  => cv_tkn_param1           -- 拠点コード
      ,iv_token_value1 => iv_base_code
      ,iv_token_name2  => cv_tkn_param2         -- 受注番号
      ,iv_token_value2 => iv_order_number
    );
    --
    -- ===============================
    --  コンカレント・メッセージ出力
    -- ===============================
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 空行出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    -- ===============================
    --  コンカレント・ログ出力
    -- ===============================
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => NULL 
    ); 
-- 
    -- メッセージ出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => lv_out_msg 
    ); 
-- 
    -- 空行出力 
    FND_FILE.PUT_LINE( 
       which  => FND_FILE.LOG 
      ,buff   => NULL 
    ); 
    --
    -- ===============================
    --  MO:営業単位取得
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE(
      name => cv_pf_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(営業単位)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_org_id                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  業務日付取得
    -- ===============================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_business_date IS NULL ) THEN
      -- 業務日付が取得できない場合
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_non_business_date    -- メッセージ
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    --  生産営業単位取得名称
    -- ===============================
    gt_ou_mfg := FND_PROFILE.VALUE(
      name => cv_pf_ou_mfg);
    --
    IF ( gt_ou_mfg IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(生産営業単位取得名称)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ou_mfg                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  生産営業単位ID取得
    -- ===============================
    BEGIN
      SELECT hou.organization_id    organization_id
      INTO   gn_prod_ou_id
      FROM   hr_operating_units hou
      WHERE  hou.name  = gt_ou_mfg;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 生産営業単位取得エラー
        -- メッセージ用文字列取得
        lv_col_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_col_name                 -- メッセージID
        );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_col_name                     -- 名称
         ,iv_data_value1    => gt_ou_mfg
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE notfound_ou_org_id_expt;
    END;
    --
    -- ===============================
    --  保管場所分類取得(直送倉庫)
    -- ===============================
    BEGIN
      SELECT flv.meaning
      INTO   gv_hokan_direct_class
      FROM   fnd_lookup_values     flv
      WHERE  flv.lookup_type     = cv_hokan_type_mst_t
      AND    flv.lookup_code     = cv_hokan_type_mst_c
      AND    flv.language        = USERENV('LANG')
      AND    flv.enabled_flag    = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 直送倉庫保管場所分類取得エラー
        RAISE notfound_hokan_direct_expt;
    END;
    --
  EXCEPTION
    WHEN notfound_ou_org_id_expt THEN
      -- 生産営業単位取得エラー
      lv_ou_org_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_ou_org_name              -- メッセージID
      );
       -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_ou_org_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => lv_key_info
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #

    WHEN notfound_hokan_direct_expt THEN
      --*** 直送倉庫保管場所分類取得エラー ***
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_hokan_direct_err
       ,iv_token_name1  => cv_tkn_type
       ,iv_token_value1 => cv_hokan_type_mst_t
       ,iv_token_name2  => cv_tkn_code
       ,iv_token_value2 => cv_hokan_type_mst_c
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_data
   * Description      : 受注データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_data(
    iv_base_code      IN  VARCHAR2,            -- 1.拠点コード
    iv_order_number   IN  VARCHAR2,            -- 2.受注番号
    ov_errbuf         OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_table_name               VARCHAR2(50);    -- テーブル名
--
    -- *** ローカル例外 ***
    order_data_extra_expt       EXCEPTION;   -- データ抽出エラー
    notfound_order_data_expt    EXCEPTION;   -- 対象データなし
    lock_expt                   EXCEPTION;   -- ロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- カーソルオープン
      OPEN order_data_cur(
         iv_base_code     => iv_base_code      -- 拠点コード
        ,iv_order_number  => iv_order_number   -- 受注番号
      );
      --
      -- レコード読込み
      FETCH order_data_cur BULK COLLECT INTO gt_order_extra_tbl;
      --
      -- 抽出件数設定
      gn_target_cnt := gt_order_extra_tbl.COUNT;
      --
      -- カーソル・クローズ
      CLOSE order_data_cur;
    EXCEPTION
      -- ロックエラー
      WHEN record_lock_expt THEN
        RAISE lock_expt;
      WHEN OTHERS THEN
        -- 抽出に失敗した場合
        RAISE order_data_extra_expt;
    END;
    --
    -- 抽出件数チェック
    IF ( gt_order_extra_tbl.COUNT = 0 ) THEN
      -- 抽出データが無い場合
      RAISE notfound_order_data_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN
      --*** ロックエラー ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ文字列取得
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_header_line
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_lock_error
       ,iv_token_name1  => cv_tkn_table
       ,iv_token_value1 => lv_table_name
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
    WHEN order_data_extra_expt THEN
      --*** データ抽出エラー ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ文字列取得
      lv_table_name := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_order_table
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_data_extra_error
       ,iv_token_name1  => cv_tkn_table_name
       ,iv_token_value1 => lv_table_name
       ,iv_token_name2  => cv_tkn_key_data
       ,iv_token_value2 => cv_blank
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
    WHEN notfound_order_data_expt THEN
      --*** 抽出データなし ***
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => cv_msg_notfound_db_data
      );
      --
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;                                            --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_data;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_subinventory
   * Description      : 出荷元保管場所取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_ship_subinventory(
    it_order_rec          IN  order_data_cur%ROWTYPE,         -- 1.受注データ
    ov_ship_subinventory  OUT NOCOPY VARCHAR2,                -- 2.出荷保管場所
    ov_errbuf             OUT NOCOPY VARCHAR2,                --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,                --   リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)                --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_subinventory'; -- プログラム名
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
    cv_item_code            CONSTANT VARCHAR2(7) := 'ZZZZZZZ';       -- 品目コード
--
    -- *** ローカル変数 ***
    lv_ship_subinventory    VARCHAR2(50);             -- 出荷元保管場所
    lv_key_info             VARCHAR2(1000);           -- キー情報
    lv_table_name           VARCHAR2(50);             -- テーブル名
    lv_order_number         VARCHAR2(50);             -- 受注番号
    lv_line_number          VARCHAR2(50);             -- 明細番号
    lv_item_code            VARCHAR2(50);             -- 品目コード
    lv_send_code            VARCHAR2(50);             -- 配送先コード
    lv_deli_expect_date     VARCHAR2(50);             -- 納品予定日
    lv_base_code            VARCHAR2(50);             -- 拠点コード
    lv_message              VARCHAR2(500);            -- 出力メッセージ
--
    -- *** ローカル例外 ***
    ship_subinventory_expt  EXCEPTION;                -- 出荷元保管場所取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      -- ===============================
      -- 出荷元保管場所取得①
      -- ===============================
      BEGIN
        SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
        WHERE  xsr.item_code               = it_order_rec.item_code            -- 品目コード
        AND    xsr.ship_to_code            = it_order_rec.province             -- 配送先コード
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                           AND     xsr.end_date_active;        -- 有効日To
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- レコードがない場合
          lv_ship_subinventory := NULL;
      END;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得②
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
          WHERE  xsr.item_code               = it_order_rec.item_code            -- 品目コード
          AND    xsr.base_code               = it_order_rec.delivery_base_code   -- 拠点コード
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                             AND     xsr.end_date_active;        -- 有効日To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- レコードがない場合
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得③
        -- ===============================
        BEGIN
          SELECT xsr.delivery_whse_code            -- 出荷保管倉庫コード
          INTO   lv_ship_subinventory
          FROM   xxcmn_sourcing_rules  xsr         -- 物流構成アドオンマスタ
          WHERE  xsr.item_code               = cv_item_code                      -- 品目コード
          AND    xsr.ship_to_code            = it_order_rec.province             -- 配送先コード
          AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                             AND     xsr.end_date_active;        -- 有効日To
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- レコードがない場合
            lv_ship_subinventory := NULL;
        END;
      END IF;
      --
      IF ( lv_ship_subinventory IS NULL ) THEN
        -- 出荷元保管場所が取得できてない場合
        -- ===============================
        -- 出荷元保管場所取得④
        -- ===============================
        SELECT xsr.delivery_whse_code           -- 出荷保管倉庫コード
        INTO   lv_ship_subinventory
        FROM   xxcmn_sourcing_rules  xsr        -- 物流構成アドオンマスタ
        WHERE  xsr.item_code               = cv_item_code                      -- 品目コード
        AND    xsr.base_code               = it_order_rec.delivery_base_code   -- 拠点コード
        AND    it_order_rec.request_date   BETWEEN xsr.start_date_active       -- 有効日From
                                           AND     xsr.end_date_active;        -- 有効日To
      END IF;
      --
      -- OUTパラメータ設定
      ov_ship_subinventory := lv_ship_subinventory;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- 出荷元保管場所取得④のSQLで抽出データなし、または、予期せぬエラーが発生した場合
        lv_ship_subinventory := NULL;
        --
        -- メッセージ文字列取得(出荷元保管場所)
        lv_table_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ship_subinv              -- メッセージID
        );
        --
        -- メッセージ文字列取得(受注番号)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_order_number             -- メッセージID
        );
        --
        -- メッセージ文字列取得(明細番号)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_line_number              -- メッセージID
        );
        --
        -- メッセージ文字列取得(品目コード)
        lv_item_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_item_code                -- メッセージID
        );
        --
        -- メッセージ文字列取得(配送先コード)
        lv_send_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_send_code                -- メッセージID
        );
        --
        -- メッセージ文字列取得(納品予定日)
        lv_deli_expect_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_deli_expect_date         -- メッセージID
        );
        --
        -- メッセージ文字列取得(拠点コード)
        lv_base_code := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_delivery_base_code      -- メッセージID
        );
        --
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- 受注番号
         ,iv_data_value1    => it_order_rec.order_number
         ,iv_item_name2     => lv_line_number                   -- 明細番号
         ,iv_data_value2    => it_order_rec.line_number
         ,iv_item_name3     => lv_item_code                     -- 品目コード
         ,iv_data_value3    => it_order_rec.item_code
         ,iv_item_name4     => lv_send_code                     -- 配送先コード
         ,iv_data_value4    => it_order_rec.province
         ,iv_item_name5     => lv_base_code                     -- 拠点コード
         ,iv_data_value5    => it_order_rec.delivery_base_code
         ,iv_item_name6     => lv_deli_expect_date              -- 納品予定日
         ,iv_data_value6    => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE ship_subinventory_expt;
    END;
--
  EXCEPTION
    WHEN ship_subinventory_expt THEN
      --***  出荷元保管場所取得エラー ***
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_data_extra_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      ov_retcode := cv_status_warn;                                            --# 任意 #
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
  END get_ship_subinventory;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_schedule_date
   * Description      : 出荷予定日取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_ship_schedule_date(
    it_order_rec     IN  order_data_cur%ROWTYPE,          -- 1.受注データ
    od_oprtn_day     OUT DATE,                            -- 2.出荷予定日
    on_lead_time     OUT NUMBER,                          -- 3,リードタイム(生産物流)
    on_delivery_lt   OUT NUMBER,                          -- 4.リードタイム(配送)
    ov_errbuf        OUT NOCOPY VARCHAR2,                 --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,                 --   リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)                 --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_schedule_date'; -- プログラム名
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
    cv_code_from            CONSTANT VARCHAR2(1) := '4';   -- コード区分From(倉庫)
    cv_code_to              CONSTANT VARCHAR2(1) := '9';   -- コード区分To(配送先)
--
    -- *** ローカル変数 ***
    ln_lead_time             NUMBER;            -- リードタイム
    ln_delivery_lt           NUMBER;            -- 配送LT
    ld_oprtn_day             DATE;              -- 稼働日日付
    lv_msg_operate_date      VARCHAR2(30);      -- 出荷予定日
--
    -- *** ローカル変数 ***
    common_api_expt          EXCEPTION;      -- 共通APIエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- リードタイム算出
    -- ===============================
    xxwsh_common910_pkg.calc_lead_time(
       iv_code_class1                => cv_code_from                     -- コード区分FROM
      ,iv_entering_despatching_code1 => it_order_rec.ship_to_subinv      -- 入出庫場所コードFROM
      ,iv_code_class2                => cv_code_to                       -- コード区分TO
      ,iv_entering_despatching_code2 => it_order_rec.province            -- 入出庫場所コードTO
      ,iv_prod_class                 => it_order_rec.prod_class_code     -- 商品区分
      ,in_transaction_type_id        => NULL                             -- 出庫形態ID
      ,id_standard_date              => it_order_rec.request_date        -- 基準日(適用日基準日)
      ,ov_retcode                    => lv_retcode                       -- リターンコード
      ,ov_errmsg_code                => lv_errbuf                        -- エラーメッセージコード
      ,ov_errmsg                     => lv_errmsg                        -- エラーメッセージ
      ,on_lead_time                  => ln_lead_time                     -- 生産物流LT／引取変更LT
      ,on_delivery_lt                => ln_delivery_lt                   -- 配送LT
    );
    --
    -- API実行結果確認
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- リードタイム取得エラーの場合
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_lead_time_error
        ,iv_token_name1  => cv_tkn_order_no                     -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_code_from                    -- コード区分From
        ,iv_token_value3 => cv_code_from
        ,iv_token_name4  => cv_tkn_stock_from                   -- 入出庫区分From
        ,iv_token_value4 => it_order_rec.ship_to_subinv
        ,iv_token_name5  => cv_tkn_code_to                      -- コード区分To
        ,iv_token_value5 => cv_code_to
        ,iv_token_name6  => cv_tkn_stock_to                     -- 入出庫区分To
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_commodity_class              -- 商品区分
        ,iv_token_value7 => it_order_rec.item_div_name
        ,iv_token_name8  => cv_tkn_stock_form_id                -- 出庫形態ID
        ,iv_token_value8 => cv_blank
        ,iv_token_name9  => cv_tkn_base_date                    -- 基準日
        ,iv_token_value9 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
      );
      RAISE common_api_expt;
    END IF;
    --
    -- アウトパラメータ設定
    on_lead_time := ln_lead_time;
    on_delivery_lt := ln_delivery_lt;
    --
    IF ( it_order_rec.schedule_ship_date IS NULL ) THEN
      -- 出荷予定日がNULLの場合
      -- 要求日(納品予定日)とリードタイム(配送)から出荷予定日を取得する
      -- ===============================
      -- 出荷予定日取得
      -- ===============================
      lv_retcode := xxwsh_common_pkg.get_oprtn_day(
         id_date            => it_order_rec.request_date           -- 納品予定日
        ,iv_whse_code       => NULL                                -- 保管倉庫コード
        ,iv_deliver_to_code => it_order_rec.province               -- 配送先コード
        ,in_lead_time       => ln_lead_time                        -- リードタイム
        ,iv_prod_class      => it_order_rec.prod_class_code        -- 商品区分
        ,od_oprtn_day       => ld_oprtn_day                        -- 稼働日日付(出荷予定日)
      );
      --
      -- API実行結果確認
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 稼働日取得エラーの場合
        -- メッセージ文字列取得(出荷予定日)
        lv_msg_operate_date := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_ship_schedule_date       -- メッセージID
        );
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_non_operation_date
          ,iv_token_name1  => cv_tkn_operate_date                          -- 出荷予定日
          ,iv_token_value1 => lv_msg_operate_date
          ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
          ,iv_token_value3 => it_order_rec.line_number
          ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
          ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
          ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
          ,iv_token_value5 => it_order_rec.ship_to_subinv
          ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
          ,iv_token_value6 => it_order_rec.province
          ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
          ,iv_token_value7 => TO_CHAR(ln_lead_time)
          ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
          ,iv_token_value8 => it_order_rec.item_div_name
        );
        RAISE common_api_expt;
      END IF;
      -- アウトパラメータ設定
      od_oprtn_day := ld_oprtn_day;
    ELSE
      -- アウトパラメータ設定
      od_oprtn_day := it_order_rec.schedule_ship_date;
    END IF;
--
  EXCEPTION
    WHEN common_api_expt THEN
      -- 共通APIエラー
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- ステータス設定(警告)
      ov_retcode := cv_status_warn;
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
  END get_ship_schedule_date;
--
  /**********************************************************************************
   * Procedure Name   : data_check
   * Description      : データチェック(A-5)
   ***********************************************************************************/
  PROCEDURE data_check(
    it_order_rec   IN  order_data_cur%ROWTYPE,         -- 1.受注データ
    ov_errbuf      OUT NOCOPY VARCHAR2,                --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,                --   リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)                --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
    cv_normal_ship_class        CONSTANT VARCHAR2(1) := '1';      -- 出荷区分(正常値)
    cv_normal_sales_div         CONSTANT VARCHAR2(1) := '1';      -- 売上対象区分(正常値)
    cv_normal_rate_class        CONSTANT VARCHAR2(1) := '0';      -- 率区分(正常値)
    cv_normal_cust_order_flag   CONSTANT VARCHAR2(1) := 'Y';      -- 顧客受注可能フラグ(正常値)
    cn_api_normal               CONSTANT NUMBER := 0;             -- 正常
--
    -- *** ローカル変数 ***
    lv_message                  VARCHAR2(1000);       -- 出力メッセージ設定
    lv_item_name                VARCHAR2(50);         -- 項目名
    lv_ship_class               VARCHAR2(10);         -- 出荷区分
    lv_sales_div                VARCHAR2(10);         -- 売上対象区分
    lv_rate_class               VARCHAR2(10);         -- 率区分
    lv_cust_order_flag          VARCHAR2(10);         -- 顧客受注可能フラグ
    ln_result                   NUMBER;               -- API関数用戻り値
    ld_ope_delivery_day         DATE;                 -- 稼動日日付納品予定日
    ld_ope_request_day          DATE;                 -- 稼動日日付受注日
    lv_tmp   varchar2(10);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 必須入力チェック
    -- ===============================
    ----------------------------------
    -- 顧客発注
    ----------------------------------
    IF ( it_order_rec.cust_po_number IS NULL ) THEN
      -- 項目名取得
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_cust_po_number
      );
      -- 出力メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                    -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                     -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                  -- 項目名
        ,iv_token_value3 => lv_item_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
/*
    ----------------------------------
    -- 要求日
    ----------------------------------
    IF ( it_order_rec.request_date IS NULL ) THEN
      -- 項目名取得
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_request_date
      );
      -- 出力メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                     -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                      -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                   -- 項目名
        ,iv_token_value3 => lv_item_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
*/
    ----------------------------------
    -- 納品拠点コード
    ----------------------------------
    IF ( it_order_rec.delivery_base_code IS NULL ) THEN
      -- 項目名取得
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_base_code
      );
      -- 出力メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_input_error
        ,iv_token_name1  => cv_tkn_order_no                    -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                     -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                  -- 項目名
        ,iv_token_value3 => lv_item_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ===============================
    -- 区分値チェック
    -- ===============================
    -- 品目データを取得済みかチェック
    IF ( gt_item_info_tbl.EXISTS(it_order_rec.item_code) = TRUE ) THEN
      -- 取得済みの場合、再利用する
      gt_item_info_rec := gt_item_info_tbl(it_order_rec.item_code);
    ELSE
      -- 未取得の場合
      -- 出荷区分、売上対象区分、率区分データ取得
      SELECT  ximv.ship_class                -- 出荷区分
             ,ximv.sales_div                 -- 売上対象区分
             ,ximv.rate_class                -- 率区分
      INTO    lv_ship_class
             ,lv_sales_div
             ,lv_rate_class
      FROM   xxcmn_item_mst2_v   ximv        -- OPM品目情報VIEW2
      WHERE  ximv.item_no       = it_order_rec.item_code             -- 品目コード
      AND    gd_business_date   BETWEEN ximv.start_date_active       -- 有効日From
                                AND     ximv.end_date_active;        -- 有効日To
      --
      -- 顧客受注可能フラグ取得
      SELECT msib.customer_order_enabled_flag         -- 顧客受注可能フラグ
      INTO   lv_cust_order_flag
      FROM   mtl_system_items_b       msib            -- 品目マスタ
      WHERE  msib.inventory_item_id = it_order_rec.inventory_item_id       -- 品目ID
      AND    msib.organization_id   = it_order_rec.ship_from_org_id;       -- 組織ID
      --
      -- 出荷区分チェック
      IF ( ( lv_ship_class IS NULL )
             OR ( lv_ship_class <> cv_normal_ship_class ) )
      THEN
        gt_item_info_rec.ship_class_flag := cn_check_status_error;
      END IF;
      --
      -- 売上対象区分チェック
      IF ( ( lv_sales_div IS NULL )
             OR ( lv_sales_div <> cv_normal_sales_div ) )
      THEN
        gt_item_info_rec.sales_div_flag := cn_check_status_error;
      END IF;
      --
      -- 率区分チェック
      IF ( ( lv_rate_class IS NULL )
            OR ( lv_rate_class <> cv_normal_rate_class ) )
      THEN
        gt_item_info_rec.rate_class_flag := cn_check_status_error;
      END IF;
      --
      -- 顧客受注可能フラグチェック
      IF ( ( lv_cust_order_flag IS NULL )
            OR ( lv_cust_order_flag <> cv_normal_cust_order_flag ) )
      THEN
        gt_item_info_rec.cust_order_flag := cn_check_status_error;
      END IF;
      --
      -- テーブルに設定
      gt_item_info_tbl(it_order_rec.item_code) := gt_item_info_rec;
    END IF;
    --
    ----------------------------------
    -- 出荷区分
    ----------------------------------
    IF (  gt_item_info_rec.ship_class_flag = cn_check_status_error ) THEN
      -- 項目名取得(出荷区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_ship_class
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                 -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name              -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value            -- 項目値
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 売上対象区分
    ----------------------------------
    IF ( gt_item_info_rec.sales_div_flag = cn_check_status_error ) THEN
      -- 項目名取得(売上対象区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_sales_div
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                 -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                  -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name               -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value             -- 項目値
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 率区分
    ----------------------------------
    IF ( gt_item_info_rec.rate_class_flag = cn_check_status_error ) THEN
      -- 項目名取得(率区分)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_rate_class
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no               -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name             -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value           -- 項目値
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    ----------------------------------
    -- 顧客受注可能フラグ
    ----------------------------------
    IF ( gt_item_info_rec.cust_order_flag = cn_check_status_error ) THEN
      -- 項目名取得(顧客受注可能フラグ)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_customer_order_flag
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_class_val_error
        ,iv_token_name1  => cv_tkn_order_no                   -- 受注番号
        ,iv_token_value1 => it_order_rec.order_number
        ,iv_token_name2  => cv_tkn_line_no                    -- 明細番号
        ,iv_token_value2 => it_order_rec.line_number
        ,iv_token_name3  => cv_tkn_field_name                 -- 項目名
        ,iv_token_value3 => lv_item_name
        ,iv_token_name4  => cv_tkn_divide_value               -- 項目値
        ,iv_token_value4 => it_order_rec.item_code
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    END IF;
    --
    -- ==========================================
    -- 要求日(納品予定日)が稼動日かチェック
    -- ==========================================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.request_date         -- 日付
      ,iv_whse_code        => NULL                              -- 保管倉庫コード
      ,iv_deliver_to_code  => it_order_rec.province             -- 配送先コード
      ,in_lead_time        => cn_lead_time_non                  -- リードタイム
      ,iv_prod_class       => it_order_rec.prod_class_code      -- 商品区分
      ,od_oprtn_day        => ld_ope_delivery_day               -- 稼働日日付納品予定日
    );
    --
    IF ( ld_ope_delivery_day IS NULL ) THEN
      -- 稼動日取得エラー
      -- 項目名取得(納品予定日)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_deli_expect_date
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_operation_date
        ,iv_token_name1  => cv_tkn_operate_date                          -- 納品予定日
        ,iv_token_value1 => lv_item_name
        ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
        ,iv_token_value2 => it_order_rec.order_number
        ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
        ,iv_token_value3 => it_order_rec.line_number
        ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
        ,iv_token_value4 => TO_CHAR(it_order_rec.request_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
        ,iv_token_value5 => it_order_rec.ship_to_subinv
        ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
        ,iv_token_value7 => TO_CHAR(cn_lead_time_non)
        ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
        ,iv_token_value8 => it_order_rec.item_div_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
    ELSE
      -- =====================================
      -- 要求日(出荷予定日)の妥当性チェック
      -- =====================================
      IF ( TRUNC(it_order_rec.schedule_ship_date) < TRUNC(gd_business_date) ) THEN
        -- リードタイムを満たしていない場合(出荷予定日が業務日付より過去の場合)
        -- メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_ship_schedule_validite
          ,iv_token_name1  => cv_tkn_val                        -- 出荷予定日
          ,iv_token_value1 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
          ,iv_token_name2  => cv_tkn_order_no                   -- 受注番号
          ,iv_token_value2 => it_order_rec.order_number
          ,iv_token_name3  => cv_tkn_line_no                    -- 明細番号
          ,iv_token_value3 => it_order_rec.line_number
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
        --
      END IF;
    END IF;
    --
    -- ===============================
    -- 受注日チェックが稼動日かチェック
    -- ===============================
    ln_result := xxwsh_common_pkg.get_oprtn_day(
       id_date             => it_order_rec.schedule_ship_date      -- 日付
      ,iv_whse_code        => NULL                                 -- 保管倉庫コード
      ,iv_deliver_to_code  => it_order_rec.province                -- 配送先コード
      ,in_lead_time        => it_order_rec.delivery_lt             -- リードタイム(生産物流)
      ,iv_prod_class       => it_order_rec.prod_class_code         -- 商品区分
      ,od_oprtn_day        => ld_ope_request_day                   -- 稼働日日付
    );
    --
    IF ( ld_ope_request_day IS NULL ) THEN
      -- 稼働日取得エラーの場合
      -- メッセージ文字列取得(受注日)
      lv_item_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
        ,iv_name        => cv_msg_order_date               -- メッセージID
      );
      -- メッセージ作成
      lv_message := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_non_operation_date
        ,iv_token_name1  => cv_tkn_operate_date                          -- 出荷予定日
        ,iv_token_value1 => lv_item_name
        ,iv_token_name2  => cv_tkn_order_no                              -- 受注番号
        ,iv_token_value2 => it_order_rec.order_number
        ,iv_token_name3  => cv_tkn_line_no                               -- 明細番号
        ,iv_token_value3 => it_order_rec.line_number
        ,iv_token_name4  => cv_tkn_base_date                             -- 納品予定日
        ,iv_token_value4 => TO_CHAR(it_order_rec.schedule_ship_date,cv_date_fmt_date_time)
        ,iv_token_name5  => cv_tkn_whse_locat                            -- 出荷元保管場所
        ,iv_token_value5 => it_order_rec.ship_to_subinv
        ,iv_token_name6  => cv_tkn_delivery_code                         -- 配送先コード
        ,iv_token_value6 => it_order_rec.province
        ,iv_token_name7  => cv_tkn_lead_time                             -- リードタイム
        ,iv_token_value7 => it_order_rec.delivery_lt
        ,iv_token_name8  => cv_tkn_commodity_class                       -- 商品区分
        ,iv_token_value8 => it_order_rec.item_div_name
      );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message
      );
      -- 空行出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      -- リターンコード設定(警告)
      ov_retcode := cv_status_warn;
      --
    ELSE
      -- ===============================
      -- 受注日の妥当性チェック
      -- ===============================
      IF ( TRUNC(it_order_rec.ordered_date) > TRUNC(ld_ope_request_day) ) THEN
        -- リードタイムを満たしていない場合(受注日より上記で取得した稼動日が過去の場合)
        -- メッセージ作成
        lv_message := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name
          ,iv_name         => cv_msg_order_date_validite
          ,iv_token_name1  => cv_tkn_order_no                                  -- 受注番号
          ,iv_token_value1 => it_order_rec.order_number
          ,iv_token_name2  => cv_tkn_line_no                                   -- 明細番号
          ,iv_token_value2 => it_order_rec.line_number
          ,iv_token_name3  => cv_tkn_order_date                                -- 抽出受注日
          ,iv_token_value3 => TO_CHAR(it_order_rec.ordered_date,cv_date_fmt_date_time)
          ,iv_token_name4  => cv_tkn_operation_date                            -- 算出受注日
          ,iv_token_value4 => TO_CHAR(ld_ope_request_day,cv_date_fmt_date_time)
        );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_message
        );
        -- 空行出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => NULL
        );
        -- リターンコード設定(警告)
        ov_retcode := cv_status_warn;
      END IF;
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
  END data_check;
--
  /**********************************************************************************
   * Procedure Name   : make_normal_order_data
   * Description      : PL/SQL表設定(A-6)
   ***********************************************************************************/
  PROCEDURE make_normal_order_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_normal_order_data'; -- プログラム名
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
    cv_first_num           CONSTANT VARCHAR2(1) := '0';
--
    -- *** ローカル変数 ***
    lv_idx_key                VARCHAR2(1000);    -- PL/SQL表ソート用インデックス文字列
    lv_idx_sort               VARCHAR2(1000);    -- PL/SQL表ソート用ソート文字列
    ln_val                    NUMBER;            -- 番号生成用
    lv_sort_key               VARCHAR2(1000);    -- ソートキー
    lv_item_code              VARCHAR2(50);      -- 品目コード
    ln_header_id              NUMBER;            -- ヘッダーIDシーケンス用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- 正常データのみのPL/SQL表作成
    -- ===============================
    <<loop_make_sort_data>>
    FOR ln_idx IN 1..gt_order_extra_tbl.COUNT LOOP
      IF ( gt_order_extra_tbl(ln_idx).check_status = cn_check_status_normal ) THEN
        -- ソートキー
        lv_idx_sort := TO_CHAR(gt_order_extra_tbl(ln_idx).header_id)                                -- 受注ヘッダID
                      || gt_order_extra_tbl(ln_idx).ship_to_subinv                                  -- 出荷元保管場所
                      || TO_CHAR(gt_order_extra_tbl(ln_idx).schedule_ship_date,cv_date_fmt_no_sep)  -- 出荷予定日
                      || TO_CHAR(gt_order_extra_tbl(ln_idx).request_date,cv_date_fmt_no_sep)        -- 納品予定日
                      || gt_order_extra_tbl(ln_idx).time_from                                       -- 時間指定From
                      || gt_order_extra_tbl(ln_idx).time_to                                         -- 時間指定To
                      || gt_order_extra_tbl(ln_idx).item_div_name;                                  -- 商品区分
        -- インデックス
        lv_idx_key := lv_idx_sort
                      || gt_order_extra_tbl(ln_idx).item_code                                       -- 品目コード
                      || cv_first_num;
        --
        -- インデックス(同一注文品)のデータが存在しているかチェック
        IF ( gt_order_sort_tbl.EXISTS(lv_idx_key) = TRUE ) THEN
          -- 存在する場合
          ln_val := 1;
          <<loop_make_next_val>>
          LOOP
            lv_idx_key := lv_idx_sort
                      || gt_order_extra_tbl(ln_idx).item_code                                       -- 品目コード
                      || TO_CHAR(ln_val);
            -- 存在しない場合、ループを抜ける
            EXIT WHEN gt_order_sort_tbl.EXISTS(lv_idx_key) = FALSE;
            -- カウントアップ
            ln_val := ln_val + 1;
          END LOOP loop_make_next_val;
        END IF;
        -- ソートキー設定
        gt_order_extra_tbl(ln_idx).sort_key := lv_idx_sort;
        gt_order_sort_tbl(lv_idx_key) := gt_order_extra_tbl(ln_idx);
      END IF;
    END LOOP loop_make_sort_data;
    --
    -- ===============================
    -- 出荷依頼用ヘッダーID採番
    -- ===============================
    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
      lv_idx_key := gt_order_sort_tbl.FIRST;
      --
      -- ヘッダーID用シーケンス採番
      SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
      INTO   ln_header_id
      FROM   dual;
      --
      <<loop_make_header_id>>
      WHILE lv_idx_key IS NOT NULL LOOP
        -- 出荷依頼用ヘッダーIDを採番するかチェック
        IF ( ( lv_sort_key <> gt_order_sort_tbl(lv_idx_key).sort_key )
             OR ( ( lv_sort_key = gt_order_sort_tbl(lv_idx_key).sort_key )
                AND ( lv_item_code = gt_order_sort_tbl(lv_idx_key).item_code ) ) )
        THEN
          -- ソートキーがブレイク、または、ソートキーと品目が同一の場合
          -- ヘッダーID用シーケンス採番
          SELECT xxwsh_shipping_headers_if_s1.NEXTVAL
          INTO   ln_header_id
          FROM   dual;
          --
        END IF;
        --
        -- ヘッダーIDを設定
        gt_order_sort_tbl(lv_idx_key).req_header_id := ln_header_id;
        --
        -- ソートキーと品目コードを取得
        lv_sort_key :=  gt_order_sort_tbl(lv_idx_key).sort_key;
        lv_item_code := gt_order_sort_tbl(lv_idx_key).item_code;
        --
        -- 次のインデックスを取得
        lv_idx_key := gt_order_sort_tbl.NEXT(lv_idx_key);
        --
      END LOOP loop_make_header_id;
    END IF;
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
  END make_normal_order_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_line_bulk_data
   * Description      : 出荷依頼I/F明細バルクバインドデータ作成(A-7)
   ***********************************************************************************/
  PROCEDURE make_request_line_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_line_bulk_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_index                  VARCHAR2(1000);               -- PL/SQL表用インデックス文字列
    lv_organization_code      VARCHAR(100);                 --  在庫組織コード
    lt_item_id                ic_item_mst_b.item_id%TYPE;   --  品目ID
    ln_organization_id        NUMBER;                       --  在庫組織ID
    ln_content                NUMBER;                       --  入数
    ln_count                  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_line_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
      --==================================
      -- 基準数量算出
      --==================================
      xxcos_common_pkg.get_uom_cnv(
         iv_before_uom_code    => gt_order_sort_tbl(lv_index).order_quantity_uom       -- 換算前単位コード = 受注単位
        ,in_before_quantity    => gt_order_sort_tbl(lv_index).ordered_quantity         -- 換算前数量       = 受注数量
        ,iov_item_code         => gt_order_sort_tbl(lv_index).item_code                -- 品目コード
        ,iov_organization_code => lv_organization_code                                 -- 在庫組織コード   =NULL
        ,ion_inventory_item_id => lt_item_id                                           -- 品目ＩＤ         =NULL
        ,ion_organization_id   => ln_organization_id                                   -- 在庫組織ＩＤ     =NULL
        ,iov_after_uom_code    => gt_order_sort_tbl(lv_index).conv_order_quantity_uom  --換算後単位コード =>基準単位
        ,on_after_quantity     => gt_order_sort_tbl(lv_index).conv_ordered_quantity    --換算後数量       =>基準数量
        ,on_content            => ln_content                                           --入数
        ,ov_errbuf             => lv_errbuf                         --エラー・メッセージエラー       #固定#
        ,ov_retcode            => lv_retcode                        --リターン・コード               #固定#
        ,ov_errmsg             => lv_errmsg                         --ユーザー・エラー・メッセージ   #固定#
      );
      -- API実行結果チェック
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --
      gt_ins_l_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;                -- ヘッダーID
      gt_ins_l_line_number(ln_count) := gt_order_sort_tbl(lv_index).line_number;                -- 明細番号
      gt_ins_l_orderd_item_code(ln_count) := gt_order_sort_tbl(lv_index).child_code;            -- 受注品目
      gt_ins_l_orderd_quantity(ln_count) := gt_order_sort_tbl(lv_index).conv_ordered_quantity;  -- 数量
      gt_ins_l_line_id(ln_count) := gt_order_sort_tbl(lv_index).line_id;                        -- 明細ID
      gt_ins_l_ship_from_org_id(ln_count) := gt_order_sort_tbl(lv_index).ship_from_org_id;      -- 組織ID
      --
      gt_upd_header_id(ln_count) := gt_order_sort_tbl(lv_index).header_id;                      -- ヘッダーID
      --
      -- カウントアップ
      ln_count := ln_count + 1;
      --
      -- 次のインデックスを取得する
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_line_bulk_data;
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
  END make_request_line_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : make_request_head_bulk_data
   * Description      : 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
   ***********************************************************************************/
  PROCEDURE make_request_head_bulk_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_request_head_bulk_data'; -- プログラム名
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
    cv_data_type                CONSTANT VARCHAR2(2) := '10';    -- データタイプ
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- 顧客発注の先頭文字
    cv_order_source             CONSTANT VARCHAR2(1) := '9';     -- 受注ソース参照の先頭文字
    cv_pad_char                 CONSTANT VARCHAR2(1) := '0';     -- PAD関数で埋め込む文字
    cn_pad_num_char             CONSTANT NUMBER := 11;           -- PAD関数で埋め込む文字数
--
    -- *** ローカル変数 ***
    lv_index                    VARCHAR2(1000);                        -- PL/SQL表用インデックス文字列
    lt_cust_po_number           VARCHAR2(100);                         -- 顧客発注
    lv_order_source             VARCHAR2(12);                          -- 受注ソース
    ln_req_header_id            NUMBER;                                -- ヘッダーID
    ln_count                    NUMBER;                                -- カウンタ
    ln_order_source_ref         NUMBER;                                -- シーケンス設定用
    lt_shipping_class           fnd_lookup_values.attribute2%TYPE;     -- 出荷依頼区分
--
    -- *** ローカル例外 ***
    non_lookup_value_expt       EXCEPTION;                             -- クイックコード取得エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------
    -- 出荷依頼区分の取得
    -----------------------------
    BEGIN
      SELECT flv.attribute2     flv_attribute2
      INTO   lt_shipping_class
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   = cv_shipping_class_t
      AND    flv.lookup_code   = cv_shipping_class_c
      AND    flv.language      = USERENV('LANG')
      AND    flv.enabled_flag  = cv_enabled_flag;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE non_lookup_value_expt;
    END;
    --
    IF ( lt_shipping_class IS NULL ) THEN
       RAISE non_lookup_value_expt;
    END IF;
    --
    ln_count := 0;
    lv_index := gt_order_sort_tbl.FIRST;
    --
    <<make_header_bulk_data>>
    WHILE lv_index IS NOT NULL LOOP
      -- 最初の1件、または、ヘッダーIDがブレイクしたらデータを作成する
      IF ( ( lv_index = gt_order_sort_tbl.FIRST )
         OR( ln_req_header_id <> gt_order_sort_tbl(lv_index).req_header_id ) ) THEN
        -----------------------------
        -- 顧客発注の設定
        -----------------------------
        IF ( ( gt_order_sort_tbl(lv_index).cust_po_number_att19 IS NOT NULL ) 
           AND ( SUBSTR(gt_order_sort_tbl(lv_index).cust_po_number,1,1) = cv_cust_po_number_first ) )
        THEN
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number_att19;
        ELSE
          --
          lt_cust_po_number := gt_order_sort_tbl(lv_index).cust_po_number;
        END IF;
        --
        -----------------------------
        -- 受注ソース参照設定
        -----------------------------
        -- シーケンス採番
        SELECT xxcos_order_source_ref_s01.NEXTVAL
        INTO   ln_order_source_ref
        FROM   dual;
        --
        lv_order_source := cv_order_source || LPAD(TO_CHAR(ln_order_source_ref)
                                                   ,cn_pad_num_char
                                                   ,cv_pad_char);
        --
        -- ヘッダID
        gt_ins_h_header_id(ln_count) := gt_order_sort_tbl(lv_index).req_header_id;
        -- 受注日
        gt_ins_h_ordered_date(ln_count) := gt_order_sort_tbl(lv_index).ordered_date;
        -- 出荷先
        gt_ins_h_party_site_code(ln_count) := gt_order_sort_tbl(lv_index).province;
        -- 出荷指示
        gt_ins_h_shipping_instructions(ln_count) := gt_order_sort_tbl(lv_index).shipping_instructions;
        -- 顧客発注
        gt_ins_h_cust_po_number(ln_count) := lt_cust_po_number;
        -- 受注ソース参照
        gt_ins_h_order_source_ref(ln_count) := lv_order_source;
        -- 出荷予定日
        gt_ins_h_schedule_ship_date(ln_count) := gt_order_sort_tbl(lv_index).schedule_ship_date;
        -- 着荷予定日
        gt_ins_h_schedule_arrival_date(ln_count) := gt_order_sort_tbl(lv_index).request_date;
        -- 出荷元
        gt_ins_h_location_code(ln_count) := gt_order_sort_tbl(lv_index).ship_to_subinv;
        -- 管轄拠点
        gt_ins_h_head_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
        -- 入力拠点
        gt_ins_h_input_sales_branch(ln_count) := gt_order_sort_tbl(lv_index).delivery_base_code;
        -- 着荷時間From
        gt_ins_h_arrival_time_from(ln_count) := gt_order_sort_tbl(lv_index).time_from;
        -- 着荷時間To
        gt_ins_h_arrival_time_to(ln_count) := gt_order_sort_tbl(lv_index).time_to;
        -- データタイプ
        gt_ins_h_data_type(ln_count) := cv_data_type;
        -- 受注番号
        gt_ins_h_order_number(ln_count) := gt_order_sort_tbl(lv_index).order_number;
        -- 依頼区分
        gt_ins_h_order_number(ln_count) := lt_shipping_class;
        --
        -- カウントアップ
        ln_count := ln_count + 1;
        --
      END IF;
      --
      -- ヘッダーID設定
      ln_req_header_id := gt_order_sort_tbl(lv_index).req_header_id;
      --
      -- 次のインデックスを取得する
      lv_index := gt_order_sort_tbl.NEXT(lv_index);
      --
    END LOOP make_header_bulk_data;
--
  EXCEPTION
    WHEN non_lookup_value_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name
                       ,iv_name         => cv_msg_shipping_class
                       ,iv_token_name1  => cv_tkn_type
                       ,iv_token_value1 => cv_shipping_class_t
                       ,iv_token_name2  => cv_tkn_code
                       ,iv_token_value2 => cv_shipping_class_c);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END make_request_head_bulk_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_line_data
   * Description      : 出荷依頼I/F明細データ作成(A-9)
   ***********************************************************************************/
  PROCEDURE insert_ship_line_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_line_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FORALL ln_idx IN 0..gt_ins_l_header_id.LAST
      INSERT INTO xxwsh_shipping_lines_if(
         line_id                        -- 明細ID
        ,header_id                      -- ヘッダID
        ,line_number                    -- 明細番号
        ,orderd_item_code               -- 受注品目
        ,case_quantity                  -- ケース数
        ,orderd_quantity                -- 数量
        ,shiped_quantity                -- 出荷実績数量
        ,designated_production_date     -- 製造日(インタフェース用)
        ,original_character             -- 固有記号(インタフェース用)
        ,use_by_date                    -- 賞味期限(インタフェース用)
        ,detailed_quantity              -- 内訳数量(インタフェース用)
        ,ship_to_quantity               -- 入庫実績数量
        ,reserved_status                -- 保留ステータス
        ,lot_no                         -- ロットNo
        ,filler01                       -- 予備01
        ,filler02                       -- 予備02
        ,filler03                       -- 予備03
        ,filler04                       -- 予備04
        ,filler05                       -- 予備05
        ,filler06                       -- 予備06
        ,filler07                       -- 予備07
        ,filler08                       -- 予備08
        ,filler09                       -- 予備09
        ,filler10                       -- 予備10
        ,created_by                     -- 作成者
        ,creation_date                  -- 作成日
        ,last_updated_by                -- 最終更新者
        ,last_update_date               -- 最終更新日
        ,last_update_login              -- 最終更新ログイン
        ,request_id                     -- 要求ID
        ,program_application_id         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date            -- プログラム更新日
      ) VALUES (
         xxwsh_shipping_lines_if_s1.NEXTVAL      -- 明細ID
        ,gt_ins_l_header_id(ln_idx)              -- ヘッダID
        ,gt_ins_l_line_number(ln_idx)            -- 明細番号
        ,gt_ins_l_orderd_item_code(ln_idx)       -- 受注品目
        ,NULL                                    -- ケース数
        ,gt_ins_l_orderd_quantity(ln_idx)        -- 数量
        ,NULL                                    -- 出荷実績数量
        ,NULL                                    -- 製造日(インタフェース用)
        ,NULL                                    -- 固有記号(インタフェース用)
        ,NULL                                    -- 賞味期限(インタフェース用)
        ,NULL                                    -- 内訳数量(インタフェース用)
        ,NULL                                    -- 入庫実績数量
        ,NULL                                    -- 保留ステータス
        ,NULL                                    -- ロットNo
        ,NULL                                    -- 予備01
        ,NULL                                    -- 予備02
        ,NULL                                    -- 予備03
        ,NULL                                    -- 予備04
        ,NULL                                    -- 予備05
        ,NULL                                    -- 予備06
        ,NULL                                    -- 予備07
        ,NULL                                    -- 予備08
        ,NULL                                    -- 予備09
        ,NULL                                    -- 予備10
        ,cn_created_by                           -- 作成者
        ,cd_creation_date                        -- 作成日
        ,cn_last_updated_by                      -- 最終更新者
        ,cd_last_update_date                     -- 最終更新日
        ,cn_last_update_login                    -- 最終更新ログイン
        ,cn_request_id                           -- 要求ID
        ,cn_program_application_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                           -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                  -- プログラム更新日
      );
      --
      -- 登録件数
      gn_line_normal_cnt := gt_ins_l_header_id.COUNT;
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
  END insert_ship_line_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_ship_header_data
   * Description      : 出荷依頼I/Fヘッダデータ作成(A-10)
   ***********************************************************************************/
  PROCEDURE insert_ship_header_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_ship_header_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FORALL ln_idx IN 0..gt_ins_h_header_id.LAST
      INSERT INTO xxwsh_shipping_headers_if(
         header_id                -- ヘッダID
        ,ordered_date             -- 受注日
        ,party_site_code          -- 出荷先
        ,shipping_instructions    -- 出荷指示
        ,cust_po_number           -- 顧客発注
        ,order_source_ref         -- 受注ソース参照
        ,schedule_ship_date       -- 出荷予定日
        ,schedule_arrival_date    -- 着荷予定日
        ,used_pallet_qty          -- パレット使用枚数
        ,collected_pallet_qty     -- パレット回収枚数
        ,location_code            -- 出荷元
        ,head_sales_branch        -- 管轄拠点
        ,input_sales_branch       -- 入力拠点
        ,arrival_time_from        -- 着荷時間From
        ,arrival_time_to          -- 着荷時間To
        ,data_type                -- データタイプ
        ,freight_carrier_code     -- 運送業者
        ,shipping_method_code     -- 配送区分
        ,delivery_no              -- 配送No
        ,shipped_date             -- 出荷日
        ,arrival_date             -- 着荷日
        ,eos_data_type            -- EOSデータ種別
        ,tranceration_number      -- 伝送用枝番
        ,ship_to_location         -- 入庫倉庫
        ,rm_class                 -- 倉替返品区分
        ,ordered_class            -- 依頼区分
        ,report_post_code         -- 報告部署
        ,line_number              -- 制御番号
        ,filler01                 -- 予備01
        ,filler02                 -- 予備02
        ,filler03                 -- 予備03
        ,filler04                 -- 予備04
        ,filler05                 -- 予備05
        ,filler06                 -- 予備06
        ,filler07                 -- 予備07 
        ,filler08                 -- 予備08
        ,filler09                 -- 予備09
        ,filler10                 -- 予備10
        ,filler11                 -- 予備11
        ,filler12                 -- 予備12
        ,filler13                 -- 予備13
        ,filler14                 -- 予備14
        ,filler15                 -- 予備15
        ,filler16                 -- 予備16
        ,filler17                 -- 予備17
        ,filler18                 -- 予備18
        ,created_by               -- 作成者
        ,creation_date            -- 作成日
        ,last_updated_by          -- 最終更新者
        ,last_update_date         -- 最終更新日
        ,last_update_login        -- 最終更新ログイン
        ,request_id               -- 要求ID
        ,program_application_id   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,program_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,program_update_date      -- プログラム更新日
      ) VALUES (
         gt_ins_h_header_id(ln_idx)                -- ヘッダID
        ,gt_ins_h_ordered_date(ln_idx)             -- 受注日
        ,gt_ins_h_party_site_code(ln_idx)          -- 出荷先
        ,gt_ins_h_shipping_instructions(ln_idx)    -- 出荷指示
        ,gt_ins_h_cust_po_number(ln_idx)           -- 顧客発注
        ,gt_ins_h_order_source_ref(ln_idx)         -- 受注ソース参照
        ,gt_ins_h_schedule_ship_date(ln_idx)       -- 出荷予定日
        ,gt_ins_h_schedule_arrival_date(ln_idx)    -- 着荷予定日
        ,NULL                                      -- パレット使用枚数
        ,NULL                                      -- パレット回収枚数
        ,gt_ins_h_location_code(ln_idx)            -- 出荷元
        ,gt_ins_h_head_sales_branch(ln_idx)        -- 管轄拠点
        ,gt_ins_h_input_sales_branch(ln_idx)       -- 入力拠点
        ,gt_ins_h_arrival_time_from(ln_idx)        -- 着荷時間From
        ,gt_ins_h_arrival_time_to(ln_idx)          -- 着荷時間To
        ,gt_ins_h_data_type(ln_idx)                -- データタイプ
        ,NULL                                      -- 運送業者
        ,NULL                                      -- 配送区分
        ,NULL                                      -- 配送No
        ,NULL                                      -- 出荷日
        ,NULL                                      -- 着荷日
        ,NULL                                      -- EOSデータ種別
        ,NULL                                      -- 伝送用枝番
        ,NULL                                      -- 入庫倉庫
        ,NULL                                      -- 倉替返品区分
        ,gt_ins_h_order_number(ln_idx)             -- 依頼区分
        ,NULL                                      -- 報告部署
        ,NULL                                      -- 制御番号
        ,NULL                                      -- 予備01
        ,NULL                                      -- 予備02
        ,NULL                                      -- 予備03
        ,NULL                                      -- 予備04
        ,NULL                                      -- 予備05
        ,NULL                                      -- 予備06
        ,NULL                                      -- 予備07
        ,NULL                                      -- 予備08
        ,NULL                                      -- 予備09
        ,NULL                                      -- 予備10
        ,NULL                                      -- 予備11
        ,NULL                                      -- 予備12
        ,NULL                                      -- 予備13
        ,NULL                                      -- 予備14
        ,NULL                                      -- 予備15
        ,NULL                                      -- 予備16
        ,NULL                                      -- 予備17
        ,NULL                                      -- 予備18
        ,cn_created_by                             -- 作成者
        ,cd_creation_date                          -- 作成日
        ,cn_last_updated_by                        -- 最終更新者
        ,cd_last_update_date                       -- 最終更新日
        ,cn_last_update_login                      -- 最終更新ログイン
        ,cn_request_id                             -- 要求ID
        ,cn_program_application_id                 -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        ,cn_program_id                             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        ,cd_program_update_date                    -- プログラム更新日
      );
      --
      -- 登録件数
      gn_header_normal_cnt := gt_ins_h_header_id.COUNT;
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
  END insert_ship_header_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line
   * Description      : 受注明細更新(A-11)
   ***********************************************************************************/
  PROCEDURE update_order_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line'; -- プログラム名
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
    cn_index                   CONSTANT NUMBER := 1;    -- インデックス
    cn_version                 CONSTANT NUMBER := 1.0;  -- APIのバージョン
    --
    -- *** ローカル変数 ***
    ln_cnt                     NUMBER;                  -- カウンタ
    lv_key_info                VARCHAR2(1000);          -- キー情報
    lv_order_number            VARCHAR2(100);           -- 受注番号
    lv_line_number             VARCHAR2(100);           -- 明細番号
    lv_table_name              VARCHAR2(100);           -- テーブル名
    ln_header_key              NUMBER;                  -- PL/SQL表のキー
    -- 受注明細更新API用
    lt_header_rec              OE_ORDER_PUB.Header_Rec_Type;
    lt_header_val_rec          OE_ORDER_PUB.Header_Val_Rec_Type;
    lt_header_adj_tbl          OE_ORDER_PUB.Header_Adj_Tbl_Type;
    lt_header_adj_val_tbl      OE_ORDER_PUB.Header_Adj_Val_Tbl_Type;
    lt_header_price_att_tbl    OE_ORDER_PUB.Header_Price_Att_Tbl_Type;
    lt_header_adj_att_tbl      OE_ORDER_PUB.Header_Adj_Att_Tbl_Type;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.Header_Adj_Assoc_Tbl_Type;
    lt_header_scredit_tbl      OE_ORDER_PUB.Header_Scredit_Tbl_Type;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.Header_Scredit_Val_Tbl_Type;
    lt_line_tbl                OE_ORDER_PUB.Line_Tbl_Type;
    lt_line_val_tbl            OE_ORDER_PUB.Line_Val_Tbl_Type;
    lt_line_adj_tbl            OE_ORDER_PUB.Line_Adj_Tbl_Type;
    lt_line_adj_val_tbl        OE_ORDER_PUB.Line_Adj_Val_Tbl_Type;
    lt_line_price_att_tbl      OE_ORDER_PUB.Line_Price_Att_Tbl_Type;
    lt_line_adj_att_tbl        OE_ORDER_PUB.Line_Adj_Att_Tbl_Type;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.Line_Adj_Assoc_Tbl_Type;
    lt_line_scredit_tbl        OE_ORDER_PUB.Line_Scredit_Tbl_Type;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.Line_Scredit_Val_Tbl_Type;
    lt_lot_serial_tbl          OE_ORDER_PUB.Lot_Serial_Tbl_Type;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.Lot_Serial_Val_Tbl_Type;
    lt_action_request_tbl      OE_ORDER_PUB.Request_Tbl_Type;
    lv_return_status           VARCHAR2(2);
    ln_msg_count               NUMBER := 0;
    lv_msg_data                VARCHAR2(2000);
    ln_count                   NUMBER;
    --
    l_count  number;
    -- *** ローカル例外 ***
    order_line_update_expt      EXCEPTION;    -- 受注明細更新エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    -- ===============================
    -- 明細更新データ作成
    -- ===============================
    ------------------------------
    -- 明細データ設定
    ------------------------------
    <<make_line_data>>
    FOR ln_idx IN 0..gt_ins_l_header_id.LAST LOOP
      gt_upd_order_line_tbl(ln_idx).header_id := gt_upd_header_id(ln_idx);                   -- ヘッダID(受注)
      gt_upd_order_line_tbl(ln_idx).line_id := gt_ins_l_line_id(ln_idx);                     -- 明細ID
      gt_upd_order_line_tbl(ln_idx).line_number := gt_ins_l_line_number(ln_idx);             -- 明細番号
      gt_upd_order_line_tbl(ln_idx).ship_from_org_id := gt_ins_l_ship_from_org_id(ln_idx);   -- 組織
      gt_upd_order_line_tbl(ln_idx).req_header_id := gt_ins_l_header_id(ln_idx);              -- ヘッダID(依頼)
    END LOOP make_line_data;
    --
    ------------------------------
    -- 梱包指示設定
    ------------------------------
    <<loop_line_data>>
    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
      <<set_packing_inst>>
      FOR ln_cnt IN 0..gt_ins_h_header_id.LAST LOOP
        ln_header_key := ln_cnt;
        EXIT WHEN gt_upd_order_line_tbl(ln_idx).req_header_id = gt_ins_h_header_id(ln_cnt);
      END LOOP set_packing_inst;
      --
      -- 梱包指示に出荷依頼番号を設定
      gt_upd_order_line_tbl(ln_idx).order_source_ref := gt_ins_h_order_source_ref(ln_header_key);
      gt_upd_order_line_tbl(ln_idx).order_number := gt_ins_h_order_number(ln_header_key);
    END LOOP loop_line_data;
    --
    -- OMメッセージリストの初期化
    OE_MSG_PUB.INITIALIZE;
    --
    -- ===============================
    -- 明細更新
    -- ===============================
    <<update_line_data>>
    FOR ln_idx IN 0..gt_upd_order_line_tbl.LAST LOOP
      lt_line_tbl(cn_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_line_tbl(cn_index).operation := OE_GLOBALS.G_OPR_UPDATE;                                     -- 処理モード
      lt_line_tbl(cn_index).line_id := gt_upd_order_line_tbl(ln_idx).line_id;                         -- 明細ID
      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- 組織ID
      lt_line_tbl(cn_index).packing_instructions := gt_upd_order_line_tbl(ln_idx).order_source_ref;   -- 梱包指示
      lt_line_tbl(cn_index).ship_from_org_id := gt_upd_order_line_tbl(ln_idx).ship_from_org_id;       -- 組織ID
      lt_line_tbl(cn_index).program_application_id := cn_program_application_id;
      lt_line_tbl(cn_index).program_id := cn_program_id;
      lt_line_tbl(cn_index).program_update_date := cd_program_update_date;
      lt_line_tbl(cn_index).request_id := cn_request_id;
      --
      --================================================================--
      -- Process Order API
      --================================================================--
      OE_ORDER_PUB.PROCESS_ORDER(
         -- IN Variables
         p_api_version_number      => cn_version
        ,p_line_tbl                => lt_line_tbl
         -- OUT Variables
        ,x_header_rec              => lt_header_rec
        ,x_header_val_rec          => lt_header_val_rec
        ,x_header_adj_tbl          => lt_header_adj_tbl
        ,x_header_adj_val_tbl      => lt_header_adj_val_tbl
        ,x_header_price_att_tbl    => lt_header_price_att_tbl
        ,x_header_adj_att_tbl      => lt_header_adj_att_tbl
        ,x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
        ,x_header_scredit_tbl      => lt_header_scredit_tbl
        ,x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
        ,x_line_tbl                => lt_line_tbl
        ,x_line_val_tbl            => lt_line_val_tbl
        ,x_line_adj_tbl            => lt_line_adj_tbl
        ,x_line_adj_val_tbl        => lt_line_adj_val_tbl
        ,x_line_price_att_tbl      => lt_line_price_att_tbl
        ,x_line_adj_att_tbl        => lt_line_adj_att_tbl
        ,x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
        ,x_line_scredit_tbl        => lt_line_scredit_tbl
        ,x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
        ,x_lot_serial_tbl          => lt_lot_serial_tbl
        ,x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
        ,x_action_request_tbl      => lt_action_request_tbl
        ,x_return_status           => lv_return_status
        ,x_msg_count               => ln_msg_count
        ,x_msg_data                => lv_msg_data
      );
      --
      -- API実行結果確認
      IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
        -- 明細更新エラー
        -- メッセージ文字列取得(受注番号)
        lv_order_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_order_number             -- メッセージID
        );
        --
        -- メッセージ文字列取得(明細番号)
        lv_line_number := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
          ,iv_name        => cv_msg_line_number              -- メッセージID
        );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1     => lv_order_number                  -- 受注番号
         ,iv_data_value1    => gt_upd_order_line_tbl(ln_idx).order_number
         ,iv_item_name2     => lv_line_number                   -- 明細番号
         ,iv_data_value2    => gt_upd_order_line_tbl(ln_idx).line_number
         ,ov_key_info       => lv_key_info                      -- 編集後キー情報
         ,ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
         ,ov_retcode        => lv_retcode                       -- リターンコード
         ,ov_errmsg         => lv_errmsg                        -- ユーザ・エラー・メッセージ
        );
        RAISE order_line_update_expt;
      END IF;
    END LOOP update_line_data;
--
  EXCEPTION
    WHEN order_line_update_expt THEN
      --*** 受注明細更新エラー ***
      -- メッセージ文字列取得(受注明細)
      lv_table_name := xxccp_common_pkg.get_msg(
             iv_application => cv_xxcos_short_name             -- アプリケーション短縮名
            ,iv_name        => cv_msg_line_number              -- メッセージID
          );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name
        ,iv_name         => cv_msg_update_error
        ,iv_token_name1  => cv_tkn_table_name
        ,iv_token_value1 => lv_table_name
        ,iv_token_name2  => cv_tkn_key_data
        ,iv_token_value2 => lv_key_info);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END update_order_line;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code     IN  VARCHAR2,     -- 1.拠点コード
    iv_order_number  IN  VARCHAR2,     -- 2.受注番号
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_retcode_a3           VARCHAR2(1);    -- A-3のリターンコード格納
    lv_retcode_a5           VARCHAR2(1);    -- A-5のリターンコード格納
--
    -- *** ローカル例外 ***
    no_data_found_expt      EXCEPTION;      -- 抽出データ無し
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
    gn_target_cnt        := 0;
    gn_header_normal_cnt := 0;
    gn_line_normal_cnt   := 0;
    gn_error_cnt         := 0;
    gn_warn_cnt          := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_base_code     => iv_base_code        -- 拠点コード
      ,iv_order_number  => iv_order_number     -- 受注番号
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 受注データ取得(A-2)
    -- ===============================
    get_order_data(
       iv_base_code     => iv_base_code        -- 拠点コード
      ,iv_order_number  => iv_order_number     -- 受注番号
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE no_data_found_expt;
    END IF;
--
    lv_retcode_a3 := cv_status_normal;
    lv_retcode_a5 := cv_status_normal;
    --
    <<make_ship_data>>
    FOR ln_idx IN gt_order_extra_tbl.FIRST..gt_order_extra_tbl.LAST LOOP
      -- ===============================
      -- 出荷元保管場所取得(A-3)
      -- ===============================
      get_ship_subinventory(
         it_order_rec          => gt_order_extra_tbl(ln_idx)                 -- 受注データ
        ,ov_ship_subinventory  => gt_order_extra_tbl(ln_idx).ship_to_subinv  -- 出荷元保管場所
        ,ov_errbuf             => lv_errbuf                                  -- エラー・メッセージ
        ,ov_retcode            => lv_retcode                                 -- リターン・コード
        ,ov_errmsg             => lv_errmsg                                  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a3 := cv_status_warn;
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 出荷予定日取得(A-4)
      -- ===============================
      IF ( lv_retcode = cv_status_normal ) THEN
        get_ship_schedule_date(
           it_order_rec   => gt_order_extra_tbl(ln_idx)                       -- 受注データ
          ,od_oprtn_day   => gt_order_extra_tbl(ln_idx).schedule_ship_date    -- 出荷予定日
          ,on_lead_time   => gt_order_extra_tbl(ln_idx).lead_time             -- リードタイム(生産物流)
          ,on_delivery_lt => gt_order_extra_tbl(ln_idx).delivery_lt           -- リードタイム(配送)
          ,ov_errbuf      => lv_errbuf                                        -- エラー・メッセージ
          ,ov_retcode     => lv_retcode                                       -- リターン・コード
          ,ov_errmsg      => lv_errmsg                                        -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      --
      -- ===============================
      -- データチェック(A-5)
      -- ===============================
      data_check(
         it_order_rec  => gt_order_extra_tbl(ln_idx)                 -- 受注データ
        ,ov_errbuf     => lv_errbuf                                  -- エラー・メッセージ
        ,ov_retcode    => lv_retcode                                 -- リターン・コード
        ,ov_errmsg     => lv_errmsg                                  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        lv_retcode_a5 := cv_status_warn;
      END IF;
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      IF ( ( lv_retcode <> cv_status_normal ) 
           OR ( lv_retcode_a3 = cv_status_warn ) )
      THEN
        -- 正常でない場合、エラーフラグを設定
        gt_order_extra_tbl(ln_idx).check_status := cn_check_status_error;
        --
        -- スキップ件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END LOOP make_ship_data;
    --
    -- ===============================
    -- PL/SQL表設定(A-6)
    -- ===============================
    make_normal_order_data(
       ov_errbuf        => lv_errbuf           -- エラー・メッセージ
      ,ov_retcode       => lv_retcode          -- リターン・コード
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( gt_order_sort_tbl.COUNT > 0 ) THEN
      -- 正常データがある場合
      -- ====================================================
      -- 出荷依頼I/F明細バルクバインドデータ作成(A-7)
      -- ====================================================
      make_request_line_bulk_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/Fヘッダバルクバインドデータ作成(A-8)
      -- ====================================================
      make_request_head_bulk_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/F明細データ作成(A-9)
      -- ====================================================
      insert_ship_line_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 出荷依頼I/Fヘッダデータ作成(A-10)
      -- ====================================================
      insert_ship_header_data(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ====================================================
      -- 受注明細更新(A-11)
      -- ====================================================
      update_order_line(
         ov_errbuf        => lv_errbuf           -- エラー・メッセージ
        ,ov_retcode       => lv_retcode          -- リターン・コード
        ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- submainのリターンコード判定
    IF ( cv_status_warn IN ( lv_retcode_a3
                            ,lv_retcode_a5 ) )
    THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN no_data_found_expt THEN
      -- 抽出データなし
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( order_data_cur%ISOPEN ) THEN
        CLOSE order_data_cur;
      END IF;
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
    errbuf           OUT VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode          OUT VARCHAR2,         --   リターン・コード    --# 固定 #
    iv_base_code     IN  VARCHAR2,         -- 1.拠点コード
    iv_order_number  IN  VARCHAR2          -- 2.受注番号
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
       iv_base_code       -- 拠点コード
      ,iv_order_number    -- 受注番号
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
    --成功件数出力(ヘッダー)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_header_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_header_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力(明細)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_line_nomal_count
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_line_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
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
    FND_FILE.PUT_LINE(
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
END XXCOS008A01C;
/
