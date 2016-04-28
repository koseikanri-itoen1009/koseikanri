CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS009A12C (body)
 * Description      : 納品確定データダウンロード
 * MD.050           : 納品確定データダウンロード <MD050_COS_009_A12>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_parameter        パラメータチェック(A-2)
 *  get_cust               抽出対象顧客取得(A-3)
 *  get_data               対象データ取得(A-4)
 *  output_data            データ出力(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/04/01    1.0   S.Yamashita      新規作成[E_本稼働_13436対応]
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 書式チェック例外 ***
  global_format_chk_expt            EXCEPTION;
  --*** EDI帳票日付指定なし例外 ***
  global_edi_date_chk_expt          EXCEPTION;
  --*** 受信日 日付逆転チェック例外 ***
  global_date_rever_ocd_chk_expt    EXCEPTION;
  --*** 納品日 日付逆転チェック例外 ***
  global_date_rever_odh_chk_expt    EXCEPTION;
  --*** 対象0件例外 ***
  global_no_data_expt               EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOS009A12C';        -- パッケージ名
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- 販物領域短縮アプリ名
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- 共通領域短縮アプリ名
  -- メッセージ
  cv_msg_format_check_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- 日付書式チェックエラーメッセージ
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00003';    -- 対象データなしメッセージ
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  cv_msg_date_rever_err          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- 日付逆転エラーメッセージ
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_inv_org_id_err          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-12318';    -- 在庫組織ID取得エラーメッセージ
  cv_msg_edi_date_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14605';    -- EDI日付指定なしエラー
  cv_msg_parameter               CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14952';    -- パラメータ出力メッセージ
  -- トークン名
  cv_tkn_nm_para_date            CONSTANT  VARCHAR2(100) :=  'PARA_DATE';                     -- 受注日(FROM)または受注日(TO)
  cv_tkn_nm_base_code            CONSTANT  VARCHAR2(100) :=  'DELIVERY_BASE_CODE';            -- 納品拠点コード
  cv_tkn_nm_inv_org_code         CONSTANT  VARCHAR2(100) :=  'ORG_CODE';                      -- 在庫組織コード
  cv_tkn_nm_date_from            CONSTANT  VARCHAR2(100) :=  'DATE_FROM';                     -- (FROM)
  cv_tkn_nm_date_to              CONSTANT  VARCHAR2(100) :=  'DATE_TO';                       -- (TO)
  cv_tkn_nm_s_ordered_date_f_t   CONSTANT  VARCHAR2(100) :=  'SCHEDULE_ORDERED_DATE_FROM_TO'; -- 納品予定日(FROM),(TO)
  cv_tkn_nm_profile              CONSTANT  VARCHAR2(100) :=  'PROFILE';                       -- プロファイル名(販売領域)
  cv_tkn_nm_chain_code           CONSTANT  VARCHAR2(100) :=  'CHAIN_CODE';                    -- チェーン店コード
  cv_tkn_nm_order_c_date_f_t     CONSTANT  VARCHAR2(100) :=  'ORDER_CREATION_DATE_FROM_TO';   -- 受信日(FROM),(TO)
  -- トークン値
  cv_msg_vl_min_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    -- MIN日付
  cv_msg_vl_max_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    -- MAX日付
  cv_msg_vl_org_id               CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00047';    -- MO:営業単位
  cv_msg_vl_inv_org_code         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-12360';    -- 在庫組織コード
  cv_msg_vl_received_date_from   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14601';    -- 受信日(FROM)
  cv_msg_vl_received_date_to     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14602';    -- 受信日(TO)
  cv_msg_vl_delivery_date_from   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14603';    -- 納品日(FROM)
  cv_msg_vl_delivery_date_to     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14604';    -- 納品日(TO)
  cv_msg_flag_out                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14606';    -- EDI納品予定送信済フラグ名称（対象外）
  cv_msg_vl_all_data_enable_flag CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14951';    -- 全拠点出力有効フラグ
  -- 日付フォーマット
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(10)  :=  'YYYY/MM/DD';            -- YYYY/MM/DD型
  cv_yyyy_mm_ddhh24miss          CONSTANT  VARCHAR2(30)  :=  'YYYY/MM/DD HH24:MI:SS'; -- YYYY/MM/DD HH24:MI:SS型
  -- クイックコード参照用
  cv_enabled_flg_y               CONSTANT  VARCHAR2(1)   :=  'Y';                        -- 使用可能
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );          -- 言語
  cv_type_esf                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_SEND_FLAG';     -- EDI送信フラグ
  cv_type_ecl                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_CONTROL_LIST';  -- EDI制御情報
  cv_type_head                   CONSTANT  VARCHAR2(100) :=  'XXCOS1_EXCEL_OUTPUT_HEAD'; -- エクセル出力用見出し
  --プロファイル関連
  cv_prof_org_id                 CONSTANT  VARCHAR2(100) :=  'ORG_ID';                         -- プロファイル名（MO:営業単位）
  cv_prof_inv_org_code           CONSTANT  VARCHAR2(100) :=  'XXCOI1_ORGANIZATION_CODE';       -- プロファイル名(在庫組織コード)
  cv_prof_min_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';                -- プロファイル名(MIN日付)
  cv_prof_max_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';                -- プロファイル名(MAX日付)
  cv_prof_all_data_enable_flag   CONSTANT  VARCHAR2(100) :=  'XXCOS1_ALL_DLV_DATA_ENABLE_FLG'; -- プロファイル名(納品確定データ全拠点出力有効フラグ)
  -- 情報区分
  cv_target_order_01             CONSTANT  VARCHAR2(2)   :=  '01';      -- 受注作成対象01
  -- クイックコード：EDI制御情報の抽出条件
  cv_order_schedule              CONSTANT  VARCHAR2(2)   :=  '21';      -- 納品予定
  -- データ種別
  cv_edi_data_type_code          CONSTANT  VARCHAR2(2)   :=  '31';      -- 納品確定
  -- 受注カテゴリ
  cv_occ_mixed                   CONSTANT  VARCHAR2(5)   :=  'MIXED';   -- MIXED
  cv_occ_order                   CONSTANT  VARCHAR2(5)   :=  'ORDER';   -- ORDER
  -- 出力済フラグ
  cv_n                           CONSTANT  VARCHAR2(1)   :=  'N';       -- 未出力
  cv_y                           CONSTANT  VARCHAR2(1)   :=  'Y';       -- 出力済
  -- 顧客区分
  cv_cust_cls_cd_chain           CONSTANT  VARCHAR2(2)   :=  '18';      -- チェーン店
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 見出し
  TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id                   NUMBER;       -- 営業単位
  gd_proc_date                DATE;         -- 業務日付
  gd_min_date                 DATE;         -- MIN日付
  gd_max_date                 DATE;         -- MAX日付
  gv_all_data_enable_flag     VARCHAR2(1);  -- 全拠点出力有効フラグ
  gv_msg_flag_out             VARCHAR2(10); -- EDI納品予定送信済フラグ：対象外
  gt_inv_org_code             mtl_parameters.organization_code%TYPE;  -- 在庫組織コード
  gt_inv_org_id               mtl_parameters.organization_id%TYPE;    -- 在庫組織ID
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 納品確定データ取得
  CURSOR data_edi_cur(
           icp_chain_code          VARCHAR2 -- チェーン店コード
          ,icp_delivery_base_code  VARCHAR2 -- 納品拠点コード
          ,icp_received_date_from  DATE     -- 受信日(FROM)
          ,icp_received_date_to    DATE     -- 受信日(TO)
          ,icp_delivery_date_from  DATE     -- 納品日(FROM)
          ,icp_delivery_date_to    DATE     -- 納品日(TO)
         )
  IS
    SELECT
      /*+
         LEADING( xtcdlc xeh ooha )
         USE_NL ( xtcdlc xeh)
         INDEX  ( xeh xxcos_edi_headers_n09 )
         INDEX  ( ooha oe_order_headers_n7 )
      */
       xeh.medium_class                      AS medium_class                 -- 媒体区分
      ,xeh.data_type_code                    AS data_type_code               -- データ種コード
      ,xeh.file_no                           AS file_no                      -- ファイルＮｏ
      ,xeh.info_class                        AS info_class                   -- 情報区分
      ,TO_CHAR( xeh.process_date, cv_yyyy_mm_dd )
                                             AS process_date                 -- 処理日
      ,xeh.process_time                      AS process_time                 -- 処理時刻
      ,xtcdlc.delivery_base_code             AS base_code                    -- 拠点（部門）コード
      ,xtcdlc.delivery_base_name             AS base_name                    -- 拠点名（正式名）
      ,xeh.edi_chain_code                    AS edi_chain_code               -- ＥＤＩチェーン店コード
      ,NVL( xeh.edi_chain_name
           ,(SELECT hp.party_name AS edi_chain_name
             FROM   xxcmm_cust_accounts xca -- 顧客追加情報
                   ,hz_cust_accounts    hca -- 顧客マスタ
                   ,hz_parties          hp  -- パーティ
             WHERE  hca.cust_account_id     = xca.customer_id
             AND    hca.party_id            = hp.party_id
             AND    xca.chain_store_code    = xeh.edi_chain_code
             AND    hca.customer_class_code = cv_cust_cls_cd_chain)
          )                                  AS edi_chain_name               -- ＥＤＩチェーン店名（漢字）
      ,xeh.chain_code                        AS chain_code                   -- チェーン店コード
      ,xeh.chain_name                        AS chain_name                   -- チェーン店名（漢字）
      ,xeh.report_code                       AS report_code                  -- 帳票コード
      ,xeh.report_show_name                  AS report_show_name             -- 帳票表示名
      ,xtcdlc.customer_code                  AS customer_code                -- 顧客コード
      ,xtcdlc.customer_name                  AS customer_name                -- 顧客名（漢字）
      ,xeh.company_code                      AS company_code                 -- 社コード
      ,xeh.company_name                      AS company_name                 -- 社名（漢字）
      ,xeh.company_name_alt                  AS company_name_alt             -- 社名（カナ）
      ,xeh.shop_code                         AS shop_code                    -- 店コード
      ,xeh.shop_name                         AS shop_name                    -- 店名（漢字）
      ,xeh.shop_name_alt                     AS shop_name_alt                -- 店名（カナ）
      ,NVL( xeh.delivery_center_code, xtcdlc.deli_center_code )
                                             AS delivery_center_code         -- 納入センターコード
      ,NVL( xeh.delivery_center_name, xtcdlc.deli_center_name )
                                             AS delivery_center_name         -- 納入センター名（漢字）
      ,xeh.delivery_center_name_alt          AS delivery_center_name_alt     -- 納入センター名（カナ）
      ,TO_CHAR( xeh.order_date, cv_yyyy_mm_dd )
                                             AS order_date                   -- 発注日
      ,TO_CHAR( xeh.center_delivery_date, cv_yyyy_mm_dd )
                                             AS center_delivery_date         -- センター納品日
      ,TO_CHAR( xeh.result_delivery_date, cv_yyyy_mm_dd )
                                             AS result_delivery_date         -- 実納品日
      ,TO_CHAR( xeh.shop_delivery_date, cv_yyyy_mm_dd )
                                             AS shop_delivery_date           -- 店舗納品日
      ,xeh.invoice_class                     AS invoice_class                -- 伝票区分
      ,xeh.small_classification_code         AS small_classification_code    -- 小分類コード
      ,xeh.small_classification_name         AS small_classification_name    -- 小分類名
      ,xeh.middle_classification_code        AS middle_classification_code   -- 中分類コード
      ,xeh.middle_classification_name        AS middle_classification_name   -- 中分類名
      ,xeh.big_classification_code           AS big_classification_code      -- 大分類コード
      ,xeh.big_classification_name           AS big_classification_name      -- 大分類名
      ,xeh.other_party_department_code       AS other_party_department_code  -- 相手先部門コード
      ,xeh.other_party_order_number          AS other_party_order_number     -- 相手先発注番号
      ,xeh.invoice_number                    AS invoice_number               -- 伝票番号
      ,xeh.check_digit                       AS check_digit                  -- チェックデジット
      ,ooha.order_number                     AS order_no_ebs                 -- 受注Ｎｏ（ＥＢＳ）
      ,xeh.ar_sale_class                     AS ar_sale_class                -- 特売区分
      ,xeh.delivery_classe                   AS delivery_classe              -- 配送区分
      ,xeh.opportunity_no                    AS opportunity_no               -- 便Ｎｏ
      ,NVL( xeh.area_code, xtcdlc.edi_district_code )
                                             AS area_code                    -- 地区コード
      ,NVL( xeh.area_name, xtcdlc.edi_district_name )
                                             AS area_name                    -- 地区名（漢字）
      ,NVL( xeh.area_name_alt, xtcdlc.edi_district_kana )
                                             AS area_name_alt                -- 地区名（カナ）
      ,xeh.vendor_code                       AS vendor_code                  -- 取引先コード
      ,xeh.vendor_name                       AS vendor_name                  -- 取引先名（漢字）
      ,xeh.vendor_name1_alt                  AS vendor_name1_alt             -- 取引先名１（カナ）
      ,xeh.vendor_name2_alt                  AS vendor_name2_alt             -- 取引先名２（カナ）
      ,xeh.vendor_tel                        AS vendor_tel                   -- 取引先ＴＥＬ
      ,xeh.vendor_charge                     AS vendor_charge                -- 取引先担当者
      ,xeh.vendor_address                    AS vendor_address               -- 取引先住所（漢字）
      ,xeh.sub_distribution_center_code      AS sub_distribution_center_code -- サブ物流センターコード
      ,xeh.sub_distribution_center_name      AS sub_distribution_center_name -- サブ物流センターコード名
      ,xeh.eos_handwriting_class             AS eos_handwriting_class        -- ＥＯＳ・手書区分
      ,xeh.a1_column                         AS a1_column                    -- Ａ－１欄
      ,xeh.b1_column                         AS b1_column                    -- Ｂ－１欄
      ,xeh.c1_column                         AS c1_column                    -- Ｃ－１欄
      ,xeh.d1_column                         AS d1_column                    -- Ｄ－１欄
      ,xeh.e1_column                         AS e1_column                    -- Ｅ－１欄
      ,xeh.a2_column                         AS a2_column                    -- Ａ－２欄
      ,xeh.b2_column                         AS b2_column                    -- Ｂ－２欄
      ,xeh.c2_column                         AS c2_column                    -- Ｃ－２欄
      ,xeh.d2_column                         AS d2_column                    -- Ｄ－２欄
      ,xeh.e2_column                         AS e2_column                    -- Ｅ－２欄
      ,xeh.a3_column                         AS a3_column                    -- Ａ－３欄
      ,xeh.b3_column                         AS b3_column                    -- Ｂ－３欄
      ,xeh.c3_column                         AS c3_column                    -- Ｃ－３欄
      ,xeh.d3_column                         AS d3_column                    -- Ｄ－３欄
      ,xeh.e3_column                         AS e3_column                    -- Ｅ－３欄
      ,xeh.f1_column                         AS f1_column                    -- Ｆ－１欄
      ,xeh.g1_column                         AS g1_column                    -- Ｇ－１欄
      ,xeh.h1_column                         AS h1_column                    -- Ｈ－１欄
      ,xeh.i1_column                         AS i1_column                    -- Ｉ－１欄
      ,xeh.j1_column                         AS j1_column                    -- Ｊ－１欄
      ,xeh.k1_column                         AS k1_column                    -- Ｋ－１欄
      ,xeh.l1_column                         AS l1_column                    -- Ｌ－１欄
      ,xeh.f2_column                         AS f2_column                    -- Ｆ－２欄
      ,xeh.g2_column                         AS g2_column                    -- Ｇ－２欄
      ,xeh.h2_column                         AS h2_column                    -- Ｈ－２欄
      ,xeh.i2_column                         AS i2_column                    -- Ｉ－２欄
      ,xeh.j2_column                         AS j2_column                    -- Ｊ－２欄
      ,xeh.k2_column                         AS k2_column                    -- Ｋ－２欄
      ,xeh.l2_column                         AS l2_column                    -- Ｌ－２欄
      ,xeh.f3_column                         AS f3_column                    -- Ｆ－３欄
      ,xeh.g3_column                         AS g3_column                    -- Ｇ－３欄
      ,xeh.h3_column                         AS h3_column                    -- Ｈ－３欄
      ,xeh.i3_column                         AS i3_column                    -- Ｉ－３欄
      ,xeh.j3_column                         AS j3_column                    -- Ｊ－３欄
      ,xeh.k3_column                         AS k3_column                    -- Ｋ－３欄
      ,xeh.l3_column                         AS l3_column                    -- Ｌ－３欄
      ,xeh.chain_peculiar_area_header        AS chain_peculiar_area_header   -- チェーン店固有エリア（ヘッダー）
      ,xel.line_no                           AS line_no                      -- 行Ｎｏ
      ,xel.stockout_class                    AS stockout_class               -- 欠品区分
      ,xel.stockout_reason                   AS stockout_reason              -- 欠品理由
      ,NVL( oola.ordered_item, xel.item_code )
                                             AS product_code_itouen          -- 商品コード（伊藤園）
      ,xel.product_code1                     AS product_code1                -- 商品コード１
      ,xel.product_code2                     AS product_code2                -- 商品コード２
      ,xel.jan_code                          AS jan_code                     -- ＪＡＮコード
      ,xel.itf_code                          AS itf_code                     -- ＩＴＦコード
      ,xel.extension_itf_code                AS extension_itf_code           -- 内箱ＩＴＦコード
      ,xel.case_product_code                 AS case_product_code            -- ケース商品コード
      ,xel.ball_product_code                 AS ball_product_code            -- ボール商品コード
      ,xel.prod_class                        AS prod_class                   -- 商品区分
      ,(SELECT msib.description AS product_name
        FROM   mtl_system_items_b msib -- DISC品目マスタ
        WHERE  msib.segment1        = NVL( oola.ordered_item, xel.item_code )
        AND    msib.organization_id = gt_inv_org_id)
                                             AS product_name                 -- 商品名（漢字）
      ,xel.product_name1_alt                 AS product_name1_alt            -- 商品名１（カナ）
      ,xel.product_name2_alt                 AS product_name2_alt            -- 商品名２（カナ）
      ,xel.item_standard1                    AS item_standard1               -- 規格１
      ,xel.item_standard2                    AS item_standard2               -- 規格２
      ,xel.qty_in_case                       AS qty_in_case                  -- 入数
      ,xel.num_of_cases                      AS num_of_cases                 -- ケース入数
      ,xel.num_of_ball                       AS num_of_ball                  -- ボール入数
      ,xel.item_color                        AS item_color                   -- 色
      ,xel.item_size                         AS item_size                    -- サイズ
      ,xel.order_uom_qty                     AS order_uom_qty                -- 発注単位数
      ,xel.uom_code                          AS uom_code                     -- 単位
      ,NVL( oola.ordered_quantity, xel.sum_order_qty )
                                             AS ordered_quantity             -- 受注数量
      ,xel.indv_order_qty                    AS indv_order_qty               -- 発注数量（バラ）
      ,xel.case_order_qty                    AS case_order_qty               -- 発注数量（ケース）
      ,xel.ball_order_qty                    AS ball_order_qty               -- 発注数量（ボール）
      ,xel.sum_order_qty                     AS sum_order_qty                -- 発注数量（合計、バラ）
      ,xel.indv_shipping_qty                 AS indv_shipping_qty            -- 出荷数量（バラ）
      ,xel.case_shipping_qty                 AS case_shipping_qty            -- 出荷数量（ケース）
      ,xel.ball_shipping_qty                 AS ball_shipping_qty            -- 出荷数量（ボール）
      ,xel.pallet_shipping_qty               AS pallet_shipping_qty          -- 出荷数量（パレット）
      ,xel.sum_shipping_qty                  AS sum_shipping_qty             -- 出荷数量（合計、バラ）
      ,xel.indv_stockout_qty                 AS indv_stockout_qty            -- 欠品数量（バラ）
      ,xel.case_stockout_qty                 AS case_stockout_qty            -- 欠品数量（ケース）
      ,xel.ball_stockout_qty                 AS ball_stockout_qty            -- 欠品数量（ボール）
      ,xel.sum_stockout_qty                  AS sum_stockout_qty             -- 欠品数量（合計、バラ）
      ,xel.case_qty                          AS case_qty                     -- ケース個口数
      ,xel.fold_container_indv_qty           AS fold_container_indv_qty      -- オリコン（バラ）個口数
      ,xel.order_unit_price                  AS order_unit_price             -- 原単価（発注）
      ,xel.shipping_unit_price               AS shipping_unit_price          -- 原単価（出荷）
      ,xel.order_cost_amt                    AS order_cost_amt               -- 原価金額（発注）
      ,xel.shipping_cost_amt                 AS shipping_cost_amt            -- 原価金額（出荷）
      ,xel.stockout_cost_amt                 AS stockout_cost_amt            -- 原価金額（欠品）
      ,xel.selling_price                     AS selling_price                -- 売単価
      ,xel.order_price_amt                   AS order_price_amt              -- 売価金額（発注）
      ,xel.shipping_price_amt                AS shipping_price_amt           -- 売価金額（出荷）
      ,xel.stockout_price_amt                AS stockout_price_amt           -- 売価金額（欠品）
      ,xel.chain_peculiar_area_line          AS chain_peculiar_area_line     -- チェーン店固有エリア（明細）
      ,CASE xeh.edi_chain_code
         WHEN ecl.chain_code
           THEN esf.meaning
         ELSE gv_msg_flag_out
       END                                   AS edi_delivery_schedule_flag   -- EDI納品予定送信済フラグ
      ,xel.general_succeeded_item1           AS general_succeeded_item1      -- 汎用引継ぎ項目１
      ,xel.general_succeeded_item2           AS general_succeeded_item2      -- 汎用引継ぎ項目２
      ,xel.general_succeeded_item3           AS general_succeeded_item3      -- 汎用引継ぎ項目３
      ,xel.general_succeeded_item4           AS general_succeeded_item4      -- 汎用引継ぎ項目４
      ,xel.general_succeeded_item5           AS general_succeeded_item5      -- 汎用引継ぎ項目５
      ,xel.general_succeeded_item6           AS general_succeeded_item6      -- 汎用引継ぎ項目６
      ,xel.general_succeeded_item7           AS general_succeeded_item7      -- 汎用引継ぎ項目７
      ,xel.general_succeeded_item8           AS general_succeeded_item8      -- 汎用引継ぎ項目８
      ,xel.general_succeeded_item9           AS general_succeeded_item9      -- 汎用引継ぎ項目９
      ,xel.general_succeeded_item10          AS general_succeeded_item10     -- 汎用引継ぎ項目１０
      ,DECODE( oola.global_attribute1
              ,'', cv_n
              ,cv_y
       )                                     AS output_flag                  -- 出力済フラグ
      ,oos.name                              AS order_source_name            -- 受注ソース名
      ,TO_CHAR( xeh.creation_date, cv_yyyy_mm_ddhh24miss )
                                             AS creation_date                -- データ作成日
      ,xeh.order_connection_number           AS order_connection_number      -- 受注関連番号
      ,xtcdlc.tsukagatazaiko_div             AS tsukagatazaiko_div           -- 通過在庫型区分
      ,oola.flow_status_code                 AS flow_status_code             -- 明細ステータス
      ,NVL( oola.subinventory, xtcdlc.subinventory )
                                             AS subinventory                 -- 保管場所
      ,TO_CHAR( ooha.booked_date, cv_yyyy_mm_dd )
                                             AS booked_date                  -- 記帳日
    FROM
       oe_order_headers_all         ooha    -- 受注ヘッダ
      ,oe_order_lines_all           oola    -- 受注明細
      ,oe_order_sources             oos     -- 受注ソース
      ,xxcos_tmp_conf_dlv_list_cust xtcdlc  -- 納品確定データ出力顧客情報一時表
      ,xxcos_edi_headers            xeh     -- EDIヘッダ情報
      ,xxcos_edi_lines              xel     -- EDI明細情報
      ,( SELECT  flv.attribute1 AS chain_code
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_ecl
         AND     flv.attribute2       = cv_order_schedule
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = cv_enabled_flg_y
         GROUP BY flv.attribute1
       )                         ecl     -- クイックコード：EDI制御情報
      ,( SELECT  flv.lookup_code AS lookup_code
                ,flv.meaning     AS meaning
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_esf
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = cv_enabled_flg_y
       )                         esf     -- クイックコード：EDI納品予定フラグ名
    WHERE
        -- 納品確定データ出力顧客情報一時表.顧客コード＝EDIヘッダ.変換後顧客コード
        xtcdlc.customer_code          = xeh.conv_customer_code
        -- 受注ヘッダ.ソースID＝受注ソース.ソースID
    AND ooha.order_source_id          = oos.order_source_id(+)
        -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
    AND ooha.header_id                = oola.header_id(+)
        -- 受注ヘッダ.外部システム受注番号＝EDIヘッダ.受注関連番号
    AND ooha.orig_sys_document_ref(+) = xeh.order_connection_number
        -- EDIヘッダ.EDIヘッダID＝EDI明細.EDIヘッダID
    AND xeh.edi_header_info_id        = xel.edi_header_info_id
        -- データ種＝納品確定
    AND xeh.data_type_code            = cv_edi_data_type_code
    AND (
          -- パラメータ受信日がNLLL
          (
                icp_received_date_from IS NULL
            AND icp_received_date_to   IS NULL
          )
          -- パラメータ受信日に設定あり
          OR
          (
                -- EDIヘッダ情報.EDI受信日≧パラメータ.受信日（FROM）
                TRUNC( xeh.edi_received_date ) >= icp_received_date_from
                -- EDIヘッダ情報.EDI受信日≦パラメータ.受信日（TO）
            AND TRUNC( xeh.edi_received_date ) <= icp_received_date_to
          )
        )
    AND (
           -- パラメータ納品日がNLLL
           (
                 icp_delivery_date_from IS NULL
             AND icp_delivery_date_to   IS NULL
           )
           -- パラメータ納品日に設定あり
           OR
           (
                 -- 納品予定日≧パラメータ.納品日（FROM）
                 TRUNC( NVL( xeh.shop_delivery_date,     -- 店舗納品日
                          NVL( xeh.center_delivery_date, -- センター納品日
                            NVL( xeh.order_date,         -- 発注日
                                   xeh.creation_date ))) -- 作成日
                       ) >= icp_delivery_date_from
                 -- 納品予定日≦パラメータ.納品日（TO）
             AND TRUNC( NVL( xeh.shop_delivery_date,     -- 店舗納品日
                          NVL( xeh.center_delivery_date, -- センター納品日
                            NVL( xeh.order_date,         -- 発注日
                                   xeh.creation_date ))) -- 作成日
                       ) <= icp_delivery_date_to
           )
        )
        -- EDI納品予定送信済フラグの名称取得
    AND xeh.edi_delivery_schedule_flag = esf.lookup_code(+)
        -- EDI制御情報より納品予定を判定
    AND ecl.chain_code(+)              = xeh.edi_chain_code
        -- 受注関連情報
    AND (
             -- 受注情報が存在しない
           ( ooha.header_id IS NULL )
           OR
             -- 受注情報が存在する
           ( ooha.header_id IS NOT NULL
                 -- 組織ID
             AND ooha.org_id            = gn_org_id
                 -- 顧客ID = 納品確定データ出力顧客情報一時表.顧客ID
             AND ooha.sold_to_org_id    = xtcdlc.customer_id
                 -- 受注明細番号＝EDI明細.受注関連明細番号
             AND oola.orig_sys_line_ref = xel.order_connection_line_number
           )
        )
    ORDER BY
       xtcdlc.delivery_base_code -- 納品拠点
      ,xtcdlc.chain_store_code   -- チェーン店コード
      ,xtcdlc.store_code         -- 店舗コード
      ,NVL( xeh.shop_delivery_date,
         NVL( xeh.center_delivery_date,
           NVL( xeh.order_date,
                  xeh.creation_date ))) -- 納品日
      ,ooha.cust_po_number       -- 顧客発注番号
      ,ooha.order_number         -- 受注番号
      ,oola.line_number          -- 受注明細番号
    ;
--
  -- 取得データ格納変数定義
  TYPE g_out_file_ttype IS TABLE OF data_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_chain_code          IN   VARCHAR2  -- チェーン店コード
   ,iv_delivery_base_code  IN   VARCHAR2  -- 納品拠点コード
   ,iv_received_date_from  IN   VARCHAR2  -- 受信日(FROM)
   ,iv_received_date_to    IN   VARCHAR2  -- 受信日(TO)
   ,iv_delivery_date_from  IN   VARCHAR2  -- 納品日(FROM)
   ,iv_delivery_date_to    IN   VARCHAR2  -- 納品日(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
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
    lv_para_msg            VARCHAR2(5000);             -- パラメータ出力メッセージ
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
    --========================================
    -- パラメータ出力処理
    --========================================
    -- パラメータ出力メッセージ取得
    lv_para_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_parameter
                    ,iv_token_name1  => cv_tkn_nm_chain_code
                    ,iv_token_value1 => iv_chain_code
                    ,iv_token_name2  => cv_tkn_nm_base_code
                    ,iv_token_value2 => iv_delivery_base_code
                    ,iv_token_name3  => cv_tkn_nm_order_c_date_f_t
                    ,iv_token_value3 => iv_received_date_from || ',' || iv_received_date_to
                    ,iv_token_name4  => cv_tkn_nm_s_ordered_date_f_t
                    ,iv_token_value4 => iv_delivery_date_from || ',' || iv_delivery_date_to
                   );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- MO:営業単位
    --========================================
    gn_org_id := FND_PROFILE.VALUE( cv_prof_org_id );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_prof_err   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_nm_profile
                    ,iv_token_value1 => cv_msg_vl_org_id  -- MO:営業単位
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 在庫組織コード
    --========================================
    gt_inv_org_code := FND_PROFILE.VALUE( cv_prof_inv_org_code );
    IF ( gt_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_prof_err        -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_nm_profile
                    ,iv_token_value1 => cv_msg_vl_inv_org_code -- 在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 在庫組織ID
    --========================================
    gt_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gt_inv_org_code
                     );
    IF ( gt_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_inv_org_id_err  -- 在庫組織ID取得エラー
                    ,iv_token_name1  => cv_tkn_nm_inv_org_code
                    ,iv_token_value1 => gt_inv_org_code        -- 在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 業務日付
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name
                    ,iv_name        => cv_msg_proc_date_err -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MIN日付
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_xxcos_short_name
                    ,iv_name         =>  cv_msg_prof_err    -- プロファイル取得エラー
                    ,iv_token_name1  =>  cv_tkn_nm_profile
                    ,iv_token_value1 =>  cv_msg_vl_min_date -- MIN日付
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MAX日付
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_prof_err    -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_nm_profile
                    ,iv_token_value1 => cv_msg_vl_max_date -- MAX日付
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 全拠点出力有効フラグ
    --========================================
    gv_all_data_enable_flag := FND_PROFILE.VALUE( cv_prof_all_data_enable_flag );
    IF ( gv_all_data_enable_flag IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  =>  cv_xxcos_short_name
                    ,iv_name         =>  cv_msg_prof_err                -- プロファイル取得エラー
                    ,iv_token_name1  =>  cv_tkn_nm_profile
                    ,iv_token_value1 =>  cv_msg_vl_all_data_enable_flag -- 納品確定データ全拠点出力有効フラグ
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- EDI納品予定送信済フラグ名称（対象外）
    --========================================
    gv_msg_flag_out := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_name
                        ,iv_name        => cv_msg_flag_out -- EDI納品予定送信済フラグ名称（対象外）
                       );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : check_parameter
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_received_date_from  IN   VARCHAR2  -- 受信日(FROM)
   ,iv_received_date_to    IN   VARCHAR2  -- 受信日(TO)
   ,iv_delivery_date_from  IN   VARCHAR2  -- 納品日(FROM)
   ,iv_delivery_date_to    IN   VARCHAR2  -- 納品日(TO)
   ,od_received_date_from  OUT  DATE      -- 受信日(FROM)
   ,od_received_date_to    OUT  DATE      -- 受信日(TO)
   ,od_delivery_date_from  OUT  DATE      -- 納品日(FROM)
   ,od_delivery_date_to    OUT  DATE      -- 納品日(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    lv_check_item          VARCHAR2(100); -- メッセージ出力用
    ld_received_date_from  DATE;          -- 受信日(FROM)
    ld_received_date_to    DATE;          -- 受信日(TO)
    ld_delivery_date_from  DATE;          -- 納品日(FROM)
    ld_delivery_date_to    DATE;          -- 納品日(TO)
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
    -- 日付指定が無い場合
    IF ( iv_received_date_from IS NULL ) AND ( iv_received_date_to IS NULL )
      AND ( iv_delivery_date_from IS NULL ) AND ( iv_delivery_date_to IS NULL )
    THEN
      RAISE global_edi_date_chk_expt;
    END IF;
    -- 受信日(FROM)必須チェック
    IF ( ( iv_received_date_from IS NULL ) AND ( iv_received_date_to IS NOT NULL ) ) THEN
      lv_check_item := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_name
                        ,iv_name        => cv_msg_vl_received_date_from -- 受信日(FROM)
                       );
      RAISE global_format_chk_expt;
    END IF;
    -- 受信日(TO)必須チェック
    IF ( ( iv_received_date_from IS NOT NULL ) AND ( iv_received_date_to IS NULL ) ) THEN
      lv_check_item := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_name
                        ,iv_name        => cv_msg_vl_received_date_to -- 受信日(TO)
                       );
      RAISE global_format_chk_expt;
    END IF;
    -- 受信日(FROM)、受信日(TO)両方入力された場合
    IF ( ( iv_received_date_from IS NOT NULL ) AND ( iv_received_date_to IS NOT NULL ) ) THEN
      -- 受信日(FROM)書式チェック
      ld_received_date_from := FND_DATE.STRING_TO_DATE( iv_received_date_from, cv_yyyy_mm_dd );
      IF ( ld_received_date_from IS NULL ) THEN
        lv_check_item := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name
                          ,iv_name        => cv_msg_vl_received_date_from -- 受信日(FROM)
                         );
        RAISE global_format_chk_expt;
      END IF;
      -- 受信日(TO)書式チェック
      ld_received_date_to := FND_DATE.STRING_TO_DATE( iv_received_date_to, cv_yyyy_mm_dd );
      IF ( ld_received_date_to IS NULL ) THEN
        lv_check_item := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name
                          ,iv_name        => cv_msg_vl_received_date_to -- 受信日(TO)
                         );
        RAISE global_format_chk_expt;
      END IF;
      -- 受信日(FROM)／受信日(TO)日付逆転チェック
      IF ( ld_received_date_from > ld_received_date_to ) THEN
        RAISE global_date_rever_ocd_chk_expt;
      END IF;
    END IF;
--
    -- 納品日(FROM)必須チェック
    IF ( ( iv_delivery_date_from IS NULL ) AND ( iv_delivery_date_to IS NOT NULL ) ) THEN
      lv_check_item := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_name
                        ,iv_name        => cv_msg_vl_delivery_date_from -- 納品日(FROM)
                       );
      RAISE global_format_chk_expt;
    END IF;
    -- 納品日(TO)必須チェック
    IF ( ( iv_delivery_date_from IS NOT NULL ) AND ( iv_delivery_date_to IS NULL ) ) THEN
      lv_check_item := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_name
                        ,iv_name        => cv_msg_vl_delivery_date_to -- 納品日(TO)
                       );
      RAISE global_format_chk_expt;
    END IF;
    -- 納品日(FROM)、納品日(TO)両方入力された場合
    IF ( ( iv_delivery_date_from IS NOT NULL ) AND ( iv_delivery_date_to IS NOT NULL ) ) THEN
      -- 納品日(FROM)書式チェック
      ld_delivery_date_from := FND_DATE.STRING_TO_DATE( iv_delivery_date_from, cv_yyyy_mm_dd );
      IF ( ld_delivery_date_from IS NULL ) THEN
        lv_check_item := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name
                          ,iv_name        => cv_msg_vl_delivery_date_from -- 納品日(FROM)
                         );
        RAISE global_format_chk_expt;
      END IF;
      -- 納品日(TO)書式チェック
      ld_delivery_date_to := FND_DATE.STRING_TO_DATE( iv_delivery_date_to, cv_yyyy_mm_dd );
      IF ( ld_delivery_date_to IS NULL ) THEN
        lv_check_item := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_short_name
                          ,iv_name        => cv_msg_vl_delivery_date_to -- 納品日(TO)
                         );
        RAISE global_format_chk_expt;
      END IF;
      -- 納品日(FROM)／納品日(TO)日付逆転チェック
      IF ( ld_delivery_date_from > ld_delivery_date_to ) THEN
        RAISE global_date_rever_odh_chk_expt;
      END IF;
    END IF;
--
    -- チェックOK
    od_received_date_from   := ld_received_date_from; -- 受信日(FROM)
    od_received_date_to     := ld_received_date_to;   -- 受信日(TO)
    od_delivery_date_from   := ld_delivery_date_from; -- 納品日(FROM)
    od_delivery_date_to     := ld_delivery_date_to;   -- 納品日(TO)
--
  EXCEPTION
    -- ***EDI日付指定なし例外ハンドラ ***
    WHEN global_edi_date_chk_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name,
                     iv_name        => cv_msg_edi_date_err -- EDI日付指定なしエラー
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 書式チェック例外ハンドラ ***
    WHEN global_format_chk_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_format_check_err -- 日付書式チェックエラー
                    ,iv_token_name1  => cv_tkn_nm_para_date
                    ,iv_token_value1 => lv_check_item
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***受信日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_ocd_chk_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_date_rever_err -- 日付逆転エラー
                    ,iv_token_name1  => cv_tkn_nm_date_from
                    ,iv_token_value1 => cv_msg_vl_received_date_from
                    ,iv_token_name2  => cv_tkn_nm_date_to
                    ,iv_token_value2 => cv_msg_vl_received_date_to
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***納品日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_odh_chk_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_date_rever_err -- 日付逆転エラー
                    ,iv_token_name1  => cv_tkn_nm_date_from
                    ,iv_token_value1 => cv_msg_vl_delivery_date_from
                    ,iv_token_name2  => cv_tkn_nm_date_to
                    ,iv_token_value2 => cv_msg_vl_delivery_date_to
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_cust
   * Description      : 抽出対象顧客取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust(
    iv_delivery_base_code  IN   VARCHAR2  --  納品拠点コード
   ,iv_chain_code          IN   VARCHAR2  --  チェーン店コード
   ,ov_errbuf              OUT  VARCHAR2  --  エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  --  リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust'; -- プログラム名
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
    cv_all_data_enable        CONSTANT VARCHAR2(1) := 'Y'; -- 全拠点出力有効フラグ：'Y'（有効）
--
    -- *** ローカル変数 ***
    ln_dummy       NUMBER;
    lv_target_flag VARCHAR2(1); -- ターゲットフラグ
    ln_cust_cnt    NUMBER;      -- 抽出対象顧客件数
--
    -- *** ローカル・カーソル ***
    CURSOR cust_cur(
             icp_delivery_base_code  VARCHAR2 -- 納品拠点コード
            ,icp_chain_code          VARCHAR2 -- チェーン店コード
           )
    IS
      SELECT  xca.customer_id        AS customer_id        -- 顧客ID
             ,xca.customer_code      AS customer_code      -- 顧客コード
             ,hp2.party_name         AS customer_name      -- 顧客名
             ,xca.deli_center_code   AS deli_center_code   -- EDI納品センターコード
             ,xca.deli_center_name   AS deli_center_name   -- EDI納品センター名
             ,xca.edi_district_code  AS edi_district_code  -- EDI地区コード（EDI)
             ,xca.edi_district_name  AS edi_district_name  -- EDI地区名（EDI)
             ,xca.edi_district_kana  AS edi_district_kana  -- EDI地区名カナ（EDI)
             ,xca.delivery_base_code AS delivery_base_code -- 納品拠点コード
             ,hp1.party_name         AS delivery_base_name -- 拠点名
             ,xca.chain_store_code   AS chain_store_code   -- チェーン店コード（EDI）
             ,xca.store_code         AS store_code         -- 店舗コード
             ,xca.tsukagatazaiko_div AS tsukagatazaiko_div -- 通過型在庫区分
             ,xca.ship_storage_code  AS subinventory       -- 保管場所
      FROM   xxcmm_cust_accounts xca   -- 顧客追加情報
            ,hz_cust_accounts    hca1  -- 顧客マスタ1
            ,hz_cust_accounts    hca2  -- 顧客マスタ2
            ,hz_parties          hp1   -- パーティ1
            ,hz_parties          hp2   -- パーティ2
      WHERE  xca.delivery_base_code = icp_delivery_base_code
      AND    xca.chain_store_code   = icp_chain_code
      AND    xca.delivery_base_code = hca1.account_number
      AND    hca1.party_id          = hp1.party_id
      AND    xca.customer_id        = hca2.cust_account_id
      AND    hca2.party_id          = hp2.party_id
      ;
--
    -- *** ローカル・レコード ***
    -- 納品確定データ出力顧客情報一時表
    TYPE l_tmp_cust_ttype IS TABLE OF xxcos_tmp_conf_dlv_list_cust%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_tmp_cust_tab       l_tmp_cust_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数：ターゲットフラグを初期化
    lv_target_flag := cv_n;
--
    -- 納品拠点コードが入力されている場合
    IF ( iv_delivery_base_code IS NOT NULL ) THEN
      -- 納品拠点・チェーン店単位の顧客取得
      OPEN  cust_cur(
              iv_delivery_base_code -- 納品拠点コード
             ,iv_chain_code         -- チェーン店コード
            );
      FETCH cust_cur BULK COLLECT INTO lt_tmp_cust_tab;
      CLOSE cust_cur;
--
      ln_cust_cnt := lt_tmp_cust_tab.COUNT;
--
      IF ( ln_cust_cnt > 0 ) THEN
        <<data_tem_cust_output>>
        FOR i IN 1..lt_tmp_cust_tab.COUNT LOOP
          -- 納品確定データ出力顧客情報一時表
          INSERT INTO xxcos_tmp_conf_dlv_list_cust(
            customer_id         -- 顧客ID
           ,customer_code       -- 顧客コード
           ,customer_name       -- 顧客名
           ,deli_center_code    -- EDI納品センターコード
           ,deli_center_name    -- EDI納品センター名
           ,edi_district_code   -- EDI地区コード（EDI)
           ,edi_district_name   -- EDI地区名（EDI)
           ,edi_district_kana   -- EDI地区名カナ（EDI)
           ,delivery_base_code  -- 納品拠点コード
           ,delivery_base_name  -- 拠点名
           ,chain_store_code    -- チェーン店コード（EDI）
           ,store_code          -- 店舗コード
           ,tsukagatazaiko_div  -- 通過型在庫区分
           ,subinventory        -- 保管場所
          )
          VALUES(
            lt_tmp_cust_tab(i).customer_id         -- 顧客ID
           ,lt_tmp_cust_tab(i).customer_code       -- 顧客コード
           ,lt_tmp_cust_tab(i).customer_name       -- 顧客名
           ,lt_tmp_cust_tab(i).deli_center_code    -- EDI納品センターコード
           ,lt_tmp_cust_tab(i).deli_center_name    -- EDI納品センター名
           ,lt_tmp_cust_tab(i).edi_district_code   -- EDI地区コード（EDI)
           ,lt_tmp_cust_tab(i).edi_district_name   -- EDI地区名（EDI)
           ,lt_tmp_cust_tab(i).edi_district_kana   -- EDI地区名カナ（EDI)
           ,lt_tmp_cust_tab(i).delivery_base_code  -- 納品拠点コード
           ,lt_tmp_cust_tab(i).delivery_base_name  -- 拠点名
           ,lt_tmp_cust_tab(i).chain_store_code    -- チェーン店コード（EDI）
           ,lt_tmp_cust_tab(i).store_code          -- 店舗コード
           ,lt_tmp_cust_tab(i).tsukagatazaiko_div  -- 通過型在庫区分
           ,lt_tmp_cust_tab(i).subinventory        -- 保管場所
          );
        END LOOP data_tem_cust_output;
      ELSE
        -- 顧客が取得できなかった場合、警告終了
        RAISE global_no_data_expt;
      END IF;
    ELSE
    -- 納品拠点コードが入力されていない場合
      ------------------------------------------------
      -- 実行職責が全拠点出力対象であるかチェック
      ------------------------------------------------
      IF ( gv_all_data_enable_flag = cv_all_data_enable ) THEN
        lv_target_flag := cv_y;
      END IF;
--
      ------------------------------------------------------------------------------------------------------------
      -- ユーザーの所属拠点またはその配下拠点が、対象チェーン店の売上拠点・納品拠点・請求拠点・入金拠点のいずれかであるかチェック
      ------------------------------------------------------------------------------------------------------------
      IF ( lv_target_flag = cv_n ) THEN
        BEGIN
          -- 納品拠点
          SELECT /*+
                   NO_MERGE ( xlbiv )
                   LEADING  ( xlbiv )
                   USE_NL   ( xlbiv xca )
                 */
                 1 AS dummy
          INTO   ln_dummy
          FROM   xxcmm_cust_accounts      xca    -- 顧客追加情報
                ,xxcos_login_base_info_v  xlbiv  -- ログインユーザ拠点ビュー
          WHERE  xca.delivery_base_code   = xlbiv.base_code
          AND    xca.chain_store_code     = iv_chain_code
          AND    ROWNUM = 1
          ;
          lv_target_flag := cv_y;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
      END IF;
--
      IF ( lv_target_flag = cv_n ) THEN
        -- 売上拠点
        BEGIN
          SELECT /*+
                   NO_MERGE ( xlbiv )
                   LEADING  ( xlbiv )
                   USE_NL   ( xlbiv xca )
                 */
                 1 AS dummy
          INTO   ln_dummy
          FROM   xxcmm_cust_accounts      xca    -- 顧客追加情報
                ,xxcos_login_base_info_v  xlbiv  -- ログインユーザ拠点ビュー
          WHERE  xca.sale_base_code       = xlbiv.base_code
          AND    xca.chain_store_code     = iv_chain_code
          AND    ROWNUM = 1
          ;
          lv_target_flag := cv_y;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
      END IF;
--
      IF ( lv_target_flag = cv_n ) THEN
        -- 請求拠点
        BEGIN
          SELECT /*+
                   NO_MERGE ( xlbiv )
                   LEADING  ( xlbiv )
                   USE_NL   ( xlbiv xca )
                 */
                 1 AS dummy
          INTO   ln_dummy
          FROM   xxcmm_cust_accounts      xca    -- 顧客追加情報
                ,xxcos_login_base_info_v  xlbiv  -- ログインユーザ拠点ビュー
          WHERE  xca.bill_base_code       = xlbiv.base_code
          AND    xca.chain_store_code     = iv_chain_code
          AND    ROWNUM = 1
          ;
          lv_target_flag := cv_y;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
      END IF;
--
      IF ( lv_target_flag = cv_n ) THEN
        -- 入金拠点
        BEGIN
          SELECT /*+
                   NO_MERGE ( xlbiv )
                   LEADING  ( xlbiv )
                   USE_NL   ( xlbiv xca )
                 */
                 1 AS dummy
          INTO   ln_dummy
          FROM   xxcmm_cust_accounts      xca    -- 顧客追加情報
                ,xxcos_login_base_info_v  xlbiv  -- ログインユーザ拠点ビュー
          WHERE  xca.receiv_base_code     = xlbiv.base_code
          AND    xca.chain_store_code     = iv_chain_code
          AND    ROWNUM = 1
          ;
          lv_target_flag := cv_y;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
      END IF;
--
      -- 変数：ターゲットフラグが'Y'の場合(拠点セキュリティを満たす場合)
      IF ( lv_target_flag = cv_y ) THEN
        -- 納品確定データ出力顧客情報一時表
        INSERT INTO xxcos_tmp_conf_dlv_list_cust(
           customer_id         -- 顧客ID
          ,customer_code       -- 顧客コード
          ,customer_name       -- 顧客名
          ,deli_center_code    -- EDI納品センターコード
          ,deli_center_name    -- EDI納品センター名
          ,edi_district_code   -- EDI地区コード（EDI)
          ,edi_district_name   -- EDI地区名（EDI)
          ,edi_district_kana   -- EDI地区名カナ（EDI)
          ,delivery_base_code  -- 納品拠点コード
          ,delivery_base_name  -- 拠点名
          ,chain_store_code    -- チェーン店コード（EDI）
          ,store_code          -- 店舗コード
          ,tsukagatazaiko_div  -- 通過型在庫区分
          ,subinventory        -- 保管場所
        )
        -- 対象チェーン店の顧客全てを取得
        SELECT  xca.customer_id        AS customer_id        -- 顧客ID
               ,xca.customer_code      AS customer_code      -- 顧客コード
               ,hp2.party_name         AS customer_name      -- 顧客名
               ,xca.deli_center_code   AS deli_center_code   -- EDI納品センターコード
               ,xca.deli_center_name   AS deli_center_name   -- EDI納品センター名
               ,xca.edi_district_code  AS edi_district_code  -- EDI地区コード（EDI)
               ,xca.edi_district_name  AS edi_district_name  -- EDI地区名（EDI)
               ,xca.edi_district_kana  AS edi_district_kana  -- EDI地区名カナ（EDI)
               ,xca.delivery_base_code AS delivery_base_code -- 納品拠点コード
               ,hp1.party_name         AS delivery_base_name -- 拠点名名
               ,xca.chain_store_code   AS chain_store_code   -- チェーン店コード（EDI）
               ,xca.store_code         AS store_code         -- 店舗コード
               ,xca.tsukagatazaiko_div AS tsukagatazaiko_div -- 通過型在庫区分
               ,xca.ship_storage_code  AS subinventory       -- 保管場所
        FROM    xxcmm_cust_accounts xca  -- 顧客追加情報
               ,hz_cust_accounts    hca1 -- 顧客マスタ1
               ,hz_cust_accounts    hca2 -- 顧客マスタ2
               ,hz_parties          hp1  -- パーティ1
               ,hz_parties          hp2  -- パーティ2
        WHERE   xca.chain_store_code   = iv_chain_code
        AND     xca.delivery_base_code = hca1.account_number
        AND     hca1.party_id          = hp1.party_id
        AND     xca.customer_id        = hca2.cust_account_id
        AND     hca2.party_id          = hp2.party_id
        ;
      ELSE
        -- 変数：ターゲットフラグが'N'の場合(拠点セキュリティを満たさない場合)、警告終了
        RAISE global_no_data_expt;
      END IF;
--
    END IF;
--
    -- 一時表用配列を削除
    lt_tmp_cust_tab.DELETE;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( cust_cur%ISOPEN ) THEN
        CLOSE cust_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cust;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_chain_code          IN  VARCHAR2  -- チェーン店コード
   ,iv_delivery_base_code  IN  VARCHAR2  -- 納品拠点コード
   ,id_received_date_from  IN  DATE      -- 受信日(FROM)
   ,id_received_date_to    IN  DATE      -- 受信日(TO)
   ,id_delivery_date_from  IN  DATE      -- 納品日(FROM)
   ,id_delivery_date_to    IN  DATE      -- 納品日(TO)
   ,ov_errbuf              OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    -- 対象データ取得
    OPEN data_edi_cur(
           iv_chain_code          -- チェーン店コード
          ,iv_delivery_base_code  -- 納品拠点コード
          ,id_received_date_from  -- 受信日(FROM)
          ,id_received_date_to    -- 受信日(TO)
          ,id_delivery_date_from  -- 納品日(FROM)
          ,id_delivery_date_to    -- 納品日(TO)
         );
--
    FETCH data_edi_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE data_edi_cur;
--
    -- 処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( data_edi_cur%ISOPEN ) THEN
        CLOSE data_edi_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-5)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_chain_code          IN   VARCHAR2  -- チェーン店コード
   ,iv_delivery_base_code  IN   VARCHAR2  -- 納品拠点コード
   ,iv_received_date_from  IN   VARCHAR2  -- 受信日(FROM)
   ,iv_received_date_to    IN   VARCHAR2  -- 受信日(TO)
   ,iv_delivery_date_from  IN   VARCHAR2  -- 納品日(FROM)
   ,iv_delivery_date_to    IN   VARCHAR2  -- 納品日(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
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
    lv_delimit          CONSTANT  VARCHAR2(10) := '	';       -- 区切り文字
    lv_colon            CONSTANT  VARCHAR2(1)  := ':';       -- 処理時刻の区切り文字
    lv_code_ost_009A07  CONSTANT  VARCHAR2(10) := '009A07%'; -- 対象のエクセル出力用見出しのキー
--
    -- *** ローカル変数 ***
    lv_line_data        VARCHAR2(5000); -- OUTPUTデータ編集用
    lv_out_process_time VARCHAR2(10);   -- 編集後の処理時刻
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR head_cur
    IS
      SELECT  flv.description AS head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_lang
      AND     flv.lookup_type   = cv_type_head
      AND     gd_proc_date     >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date     <= NVL( flv.end_date_active,   gd_max_date )
      AND     flv.enabled_flag  = cv_enabled_flg_y
      AND     flv.meaning       LIKE lv_code_ost_009A07
      ORDER BY
              flv.meaning
      ;
--
    -- *** ローカル・レコード ***
--
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ----------------------
    -- データ見出し出力
    ----------------------
    -- データの見出しを取得
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    -- データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || lv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    -- データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ----------------------
    -- データ出力
    ----------------------
    -- データを取得
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      -- 初期化
      lv_line_data        := NULL;
      lv_out_process_time := NULL;
      -- 処理時刻の編集
      IF( gt_out_file_tab(i).process_time IS NULL) THEN
        NULL;
      ELSE
        lv_out_process_time := SUBSTR( gt_out_file_tab(i).process_time, 1, 2 ) || lv_colon ||   -- 時
                               SUBSTR( gt_out_file_tab(i).process_time, 3, 2 ) || lv_colon ||   -- 分
                               SUBSTR( gt_out_file_tab(i).process_time, 5, 2 );                 -- 秒
      END IF;
      -- データを編集
      lv_line_data :=                  gt_out_file_tab(i).medium_class                 -- 媒体区分
                      || lv_delimit || gt_out_file_tab(i).data_type_code               -- データ種コード
                      || lv_delimit || gt_out_file_tab(i).file_no                      -- ファイルＮｏ
                      || lv_delimit || gt_out_file_tab(i).info_class                   -- 情報区分
                      || lv_delimit || gt_out_file_tab(i).process_date                 -- 処理日
                      || lv_delimit || lv_out_process_time                             -- 処理時刻
                      || lv_delimit || gt_out_file_tab(i).base_code                    -- 拠点（部門）コード
                      || lv_delimit || gt_out_file_tab(i).base_name                    -- 拠点名（正式名）
                      || lv_delimit || gt_out_file_tab(i).edi_chain_code               -- ＥＤＩチェーン店コード
                      || lv_delimit || gt_out_file_tab(i).edi_chain_name               -- ＥＤＩチェーン店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).chain_code                   -- チェーン店コード
                      || lv_delimit || gt_out_file_tab(i).chain_name                   -- チェーン店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).report_code                  -- 帳票コード
                      || lv_delimit || gt_out_file_tab(i).report_show_name             -- 帳票表示名
                      || lv_delimit || gt_out_file_tab(i).customer_code                -- 顧客コード
                      || lv_delimit || gt_out_file_tab(i).customer_name                -- 顧客名（漢字）
                      || lv_delimit || gt_out_file_tab(i).company_code                 -- 社コード
                      || lv_delimit || gt_out_file_tab(i).company_name                 -- 社名（漢字）
                      || lv_delimit || gt_out_file_tab(i).company_name_alt             -- 社名（カナ）
                      || lv_delimit || gt_out_file_tab(i).shop_code                    -- 店コード
                      || lv_delimit || gt_out_file_tab(i).shop_name                    -- 店名（漢字）
                      || lv_delimit || gt_out_file_tab(i).shop_name_alt                -- 店名（カナ）
                      || lv_delimit || gt_out_file_tab(i).delivery_center_code         -- 納入センターコード
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name         -- 納入センター名（漢字）
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name_alt     -- 納入センター名（カナ）
                      || lv_delimit || gt_out_file_tab(i).order_date                   -- 発注日
                      || lv_delimit || gt_out_file_tab(i).center_delivery_date         -- センター納品日
                      || lv_delimit || gt_out_file_tab(i).result_delivery_date         -- 実納品日
                      || lv_delimit || gt_out_file_tab(i).shop_delivery_date           -- 店舗納品日
                      || lv_delimit || gt_out_file_tab(i).invoice_class                -- 伝票区分
                      || lv_delimit || gt_out_file_tab(i).small_classification_code    -- 小分類コード
                      || lv_delimit || gt_out_file_tab(i).small_classification_name    -- 小分類名
                      || lv_delimit || gt_out_file_tab(i).middle_classification_code   -- 中分類コード
                      || lv_delimit || gt_out_file_tab(i).middle_classification_name   -- 中分類名
                      || lv_delimit || gt_out_file_tab(i).big_classification_code      -- 大分類コード
                      || lv_delimit || gt_out_file_tab(i).big_classification_name      -- 大分類名
                      || lv_delimit || gt_out_file_tab(i).other_party_department_code  -- 相手先部門コード
                      || lv_delimit || gt_out_file_tab(i).other_party_order_number     -- 相手先発注番号
                      || lv_delimit || gt_out_file_tab(i).invoice_number               -- 伝票番号
                      || lv_delimit || gt_out_file_tab(i).check_digit                  -- チェックデジット
                      || lv_delimit || gt_out_file_tab(i).order_no_ebs                 -- 受注Ｎｏ（ＥＢＳ）
                      || lv_delimit || gt_out_file_tab(i).ar_sale_class                -- 特売区分
                      || lv_delimit || gt_out_file_tab(i).delivery_classe              -- 配送区分
                      || lv_delimit || gt_out_file_tab(i).opportunity_no               -- 便Ｎｏ
                      || lv_delimit || gt_out_file_tab(i).area_code                    -- 地区コード
                      || lv_delimit || gt_out_file_tab(i).area_name                    -- 地区名（漢字）
                      || lv_delimit || gt_out_file_tab(i).area_name_alt                -- 地区名（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_code                  -- 取引先コード
                      || lv_delimit || gt_out_file_tab(i).vendor_name                  -- 取引先名（漢字）
                      || lv_delimit || gt_out_file_tab(i).vendor_name1_alt             -- 取引先名１（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_name2_alt             -- 取引先名２（カナ）
                      || lv_delimit || gt_out_file_tab(i).vendor_tel                   -- 取引先ＴＥＬ
                      || lv_delimit || gt_out_file_tab(i).vendor_charge                -- 取引先担当者
                      || lv_delimit || gt_out_file_tab(i).vendor_address               -- 取引先住所（漢字）
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_code -- サブ物流センターコード
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_name -- サブ物流センターコード名
                      || lv_delimit || gt_out_file_tab(i).eos_handwriting_class        -- ＥＯＳ・手書区分
                      || lv_delimit || gt_out_file_tab(i).a1_column                    -- Ａ－１欄
                      || lv_delimit || gt_out_file_tab(i).b1_column                    -- Ｂ－１欄
                      || lv_delimit || gt_out_file_tab(i).c1_column                    -- Ｃ－１欄
                      || lv_delimit || gt_out_file_tab(i).d1_column                    -- Ｄ－１欄
                      || lv_delimit || gt_out_file_tab(i).e1_column                    -- Ｅ－１欄
                      || lv_delimit || gt_out_file_tab(i).a2_column                    -- Ａ－２欄
                      || lv_delimit || gt_out_file_tab(i).b2_column                    -- Ｂ－２欄
                      || lv_delimit || gt_out_file_tab(i).c2_column                    -- Ｃ－２欄
                      || lv_delimit || gt_out_file_tab(i).d2_column                    -- Ｄ－２欄
                      || lv_delimit || gt_out_file_tab(i).e2_column                    -- Ｅ－２欄
                      || lv_delimit || gt_out_file_tab(i).a3_column                    -- Ａ－３欄
                      || lv_delimit || gt_out_file_tab(i).b3_column                    -- Ｂ－３欄
                      || lv_delimit || gt_out_file_tab(i).c3_column                    -- Ｃ－３欄
                      || lv_delimit || gt_out_file_tab(i).d3_column                    -- Ｄ－３欄
                      || lv_delimit || gt_out_file_tab(i).e3_column                    -- Ｅ－３欄
                      || lv_delimit || gt_out_file_tab(i).f1_column                    -- Ｆ－１欄
                      || lv_delimit || gt_out_file_tab(i).g1_column                    -- Ｇ－１欄
                      || lv_delimit || gt_out_file_tab(i).h1_column                    -- Ｈ－１欄
                      || lv_delimit || gt_out_file_tab(i).i1_column                    -- Ｉ－１欄
                      || lv_delimit || gt_out_file_tab(i).j1_column                    -- Ｊ－１欄
                      || lv_delimit || gt_out_file_tab(i).k1_column                    -- Ｋ－１欄
                      || lv_delimit || gt_out_file_tab(i).l1_column                    -- Ｌ－１欄
                      || lv_delimit || gt_out_file_tab(i).f2_column                    -- Ｆ－２欄
                      || lv_delimit || gt_out_file_tab(i).g2_column                    -- Ｇ－２欄
                      || lv_delimit || gt_out_file_tab(i).h2_column                    -- Ｈ－２欄
                      || lv_delimit || gt_out_file_tab(i).i2_column                    -- Ｉ－２欄
                      || lv_delimit || gt_out_file_tab(i).j2_column                    -- Ｊ－２欄
                      || lv_delimit || gt_out_file_tab(i).k2_column                    -- Ｋ－２欄
                      || lv_delimit || gt_out_file_tab(i).l2_column                    -- Ｌ－２欄
                      || lv_delimit || gt_out_file_tab(i).f3_column                    -- Ｆ－３欄
                      || lv_delimit || gt_out_file_tab(i).g3_column                    -- Ｇ－３欄
                      || lv_delimit || gt_out_file_tab(i).h3_column                    -- Ｈ－３欄
                      || lv_delimit || gt_out_file_tab(i).i3_column                    -- Ｉ－３欄
                      || lv_delimit || gt_out_file_tab(i).j3_column                    -- Ｊ－３欄
                      || lv_delimit || gt_out_file_tab(i).k3_column                    -- Ｋ－３欄
                      || lv_delimit || gt_out_file_tab(i).l3_column                    -- Ｌ－３欄
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_header   -- チェーン店固有エリア（ヘッダー）
                      || lv_delimit || gt_out_file_tab(i).line_no                      -- 行Ｎｏ
                      || lv_delimit || gt_out_file_tab(i).stockout_class               -- 欠品区分
                      || lv_delimit || gt_out_file_tab(i).stockout_reason              -- 欠品理由
                      || lv_delimit || gt_out_file_tab(i).product_code_itouen          -- 商品コード（伊藤園）
                      || lv_delimit || gt_out_file_tab(i).product_code1                -- 商品コード１
                      || lv_delimit || gt_out_file_tab(i).product_code2                -- 商品コード２
                      || lv_delimit || gt_out_file_tab(i).jan_code                     -- ＪＡＮコード
                      || lv_delimit || gt_out_file_tab(i).itf_code                     -- ＩＴＦコード
                      || lv_delimit || gt_out_file_tab(i).extension_itf_code           -- 内箱ＩＴＦコード
                      || lv_delimit || gt_out_file_tab(i).case_product_code            -- ケース商品コード
                      || lv_delimit || gt_out_file_tab(i).ball_product_code            -- ボール商品コード
                      || lv_delimit || gt_out_file_tab(i).prod_class                   -- 商品区分
                      || lv_delimit || gt_out_file_tab(i).product_name                 -- 商品名（漢字）
                      || lv_delimit || gt_out_file_tab(i).product_name1_alt            -- 商品名１（カナ）
                      || lv_delimit || gt_out_file_tab(i).product_name2_alt            -- 商品名２（カナ）
                      || lv_delimit || gt_out_file_tab(i).item_standard1               -- 規格１
                      || lv_delimit || gt_out_file_tab(i).item_standard2               -- 規格２
                      || lv_delimit || gt_out_file_tab(i).qty_in_case                  -- 入数
                      || lv_delimit || gt_out_file_tab(i).num_of_cases                 -- ケース入数
                      || lv_delimit || gt_out_file_tab(i).num_of_ball                  -- ボール入数
                      || lv_delimit || gt_out_file_tab(i).item_color                   -- 色
                      || lv_delimit || gt_out_file_tab(i).item_size                    -- サイズ
                      || lv_delimit || gt_out_file_tab(i).order_uom_qty                -- 発注単位数
                      || lv_delimit || gt_out_file_tab(i).uom_code                     -- 単位
                      || lv_delimit || gt_out_file_tab(i).ordered_quantity             -- 受注数量
                      || lv_delimit || gt_out_file_tab(i).indv_order_qty               -- 発注数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_order_qty               -- 発注数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_order_qty               -- 発注数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).sum_order_qty                -- 発注数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).indv_shipping_qty            -- 出荷数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_shipping_qty            -- 出荷数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_shipping_qty            -- 出荷数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).pallet_shipping_qty          -- 出荷数量（パレット）
                      || lv_delimit || gt_out_file_tab(i).sum_shipping_qty             -- 出荷数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).indv_stockout_qty            -- 欠品数量（バラ）
                      || lv_delimit || gt_out_file_tab(i).case_stockout_qty            -- 欠品数量（ケース）
                      || lv_delimit || gt_out_file_tab(i).ball_stockout_qty            -- 欠品数量（ボール）
                      || lv_delimit || gt_out_file_tab(i).sum_stockout_qty             -- 欠品数量（合計、バラ）
                      || lv_delimit || gt_out_file_tab(i).case_qty                     -- ケース個口数
                      || lv_delimit || gt_out_file_tab(i).fold_container_indv_qty      -- オリコン（バラ）個口数
                      || lv_delimit || gt_out_file_tab(i).order_unit_price             -- 原単価（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_unit_price          -- 原単価（出荷）
                      || lv_delimit || gt_out_file_tab(i).order_cost_amt               -- 原価金額（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_cost_amt            -- 原価金額（出荷）
                      || lv_delimit || gt_out_file_tab(i).stockout_cost_amt            -- 原価金額（欠品）
                      || lv_delimit || gt_out_file_tab(i).selling_price                -- 売単価
                      || lv_delimit || gt_out_file_tab(i).order_price_amt              -- 売価金額（発注）
                      || lv_delimit || gt_out_file_tab(i).shipping_price_amt           -- 売価金額（出荷）
                      || lv_delimit || gt_out_file_tab(i).stockout_price_amt           -- 売価金額（欠品）
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_line     -- チェーン店固有エリア（明細）
                      || lv_delimit || gt_out_file_tab(i).edi_delivery_schedule_flag   -- EDI納品予定送信済フラグ
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item1      -- 汎用引継ぎ項目１
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item2      -- 汎用引継ぎ項目２
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item3      -- 汎用引継ぎ項目３
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item4      -- 汎用引継ぎ項目４
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item5      -- 汎用引継ぎ項目５
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item6      -- 汎用引継ぎ項目６
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item7      -- 汎用引継ぎ項目７
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item8      -- 汎用引継ぎ項目８
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item9      -- 汎用引継ぎ項目９
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item10     -- 汎用引継ぎ項目１０
                      || lv_delimit || gt_out_file_tab(i).output_flag                  -- 出力済フラグ
                      || lv_delimit || gt_out_file_tab(i).order_source_name            -- 受注ソース名
                      || lv_delimit || gt_out_file_tab(i).creation_date                -- データ作成日
                      || lv_delimit || gt_out_file_tab(i).order_connection_number      -- 受注関連番号
                      || lv_delimit || gt_out_file_tab(i).tsukagatazaiko_div           -- 通過在庫型区分
                      || lv_delimit || gt_out_file_tab(i).flow_status_code             -- 明細ステータス
                      || lv_delimit || gt_out_file_tab(i).subinventory                 -- 保管場所
                      || lv_delimit || gt_out_file_tab(i).booked_date                  -- 記帳日
                      ;
--
      -- データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( head_cur%ISOPEN ) THEN
        CLOSE head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_chain_code          IN   VARCHAR2  -- チェーン店コード
   ,iv_delivery_base_code  IN   VARCHAR2  -- 納品拠点コード
   ,iv_received_date_from  IN   VARCHAR2  -- 受信日(FROM)
   ,iv_received_date_to    IN   VARCHAR2  -- 受信日(TO)
   ,iv_delivery_date_from  IN   VARCHAR2  -- 納品日(FROM)
   ,iv_delivery_date_to    IN   VARCHAR2  -- 納品日(TO)
   ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ld_received_date_from  DATE;  -- 受信日(FROM)
    ld_received_date_to    DATE;  -- 受信日(TO)
    ld_delivery_date_from  DATE;  -- 納品日(FROM)
    ld_delivery_date_to    DATE;  -- 納品日(TO)
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
--
    -- ===============================
    -- A-1  初期処理（プロファイル取得）
    -- ===============================
    init(
      iv_chain_code         => iv_chain_code          -- チェーン店コード
     ,iv_delivery_base_code => iv_delivery_base_code  -- 納品拠点コード
     ,iv_received_date_from => iv_received_date_from  -- 受信日(FROM)
     ,iv_received_date_to   => iv_received_date_to    -- 受信日(TO)
     ,iv_delivery_date_from => iv_delivery_date_from  -- 納品日(FROM)
     ,iv_delivery_date_to   => iv_delivery_date_to    -- 納品日(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  パラメータチェック
    -- ===============================
    check_parameter(
      iv_received_date_from => iv_received_date_from  -- 受信日(FROM)
     ,iv_received_date_to   => iv_received_date_to    -- 受信日(TO)
     ,iv_delivery_date_from => iv_delivery_date_from  -- 納品日(FROM)
     ,iv_delivery_date_to   => iv_delivery_date_to    -- 納品日(TO)
     ,od_received_date_from => ld_received_date_from  -- 受信日(FROM)
     ,od_received_date_to   => ld_received_date_to    -- 受信日(TO)
     ,od_delivery_date_from => ld_delivery_date_from  -- 納品日(FROM)
     ,od_delivery_date_to   => ld_delivery_date_to    -- 納品日(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  抽出対象顧客取得(A-3)
    -- ===============================
    get_cust(
      iv_delivery_base_code => iv_delivery_base_code  -- 納品拠点コード
     ,iv_chain_code         => iv_chain_code          -- チェーン店コード
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- 警告の場合、終了する
      RAISE global_no_data_expt;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  対象データ取得
    -- ===============================
    get_data(
      iv_chain_code         => iv_chain_code          -- チェーン店コード
     ,iv_delivery_base_code => iv_delivery_base_code  -- 納品拠点コード
     ,id_received_date_from => ld_received_date_from  -- 受信日(FROM)
     ,id_received_date_to   => ld_received_date_to    -- 受信日(TO)
     ,id_delivery_date_from => ld_delivery_date_from  -- 納品日(FROM)
     ,id_delivery_date_to   => ld_delivery_date_to    -- 納品日(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      -- 警告の場合、終了する
      RAISE global_no_data_expt;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数が0件
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- ===============================
    -- A-5  データ出力
    -- ===============================
    output_data(
       iv_chain_code          => iv_chain_code          -- チェーン店コード
      ,iv_delivery_base_code  => iv_delivery_base_code  -- 納品拠点コード
      ,iv_received_date_from  => ld_received_date_from  -- 受信日(FROM)
      ,iv_received_date_to    => ld_received_date_to    -- 受信日(TO)
      ,iv_delivery_date_from  => ld_delivery_date_from  -- 納品日(FROM)
      ,iv_delivery_date_to    => ld_delivery_date_to    -- 納品日(TO)
      ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_short_name
                    ,iv_name        => cv_msg_no_data
                   );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                 OUT  VARCHAR2  -- エラー・メッセージ  --# 固定 #
   ,retcode                OUT  VARCHAR2  -- リターン・コード    --# 固定 #
   ,iv_chain_code          IN   VARCHAR2  -- チェーン店コード
   ,iv_delivery_base_code  IN   VARCHAR2  -- 納品拠点コード
   ,iv_received_date_from  IN   VARCHAR2  -- 受信日(FROM)
   ,iv_received_date_to    IN   VARCHAR2  -- 受信日(TO)
   ,iv_delivery_date_from  IN   VARCHAR2  -- 納品日(FROM)
   ,iv_delivery_date_to    IN   VARCHAR2  -- 納品日(TO)
  )
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_chain_code         => iv_chain_code          -- チェーン店コード
     ,iv_delivery_base_code => iv_delivery_base_code  -- 納品拠点コード
     ,iv_received_date_from => iv_received_date_from  -- 受信日(FROM)
     ,iv_received_date_to   => iv_received_date_to    -- 受信日(TO)
     ,iv_delivery_date_from => iv_delivery_date_from  -- 納品日(FROM)
     ,iv_delivery_date_to   => iv_delivery_date_to    -- 納品日(TO)
     ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
     ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF ( lv_retcode = cv_status_warn ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    -- エラー出力
    ELSIF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 件数クリア、エラー件数セット
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    --
    END IF;
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                  ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A12C;
/
