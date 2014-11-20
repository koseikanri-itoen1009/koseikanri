CREATE OR REPLACE PACKAGE BODY xxpo940006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940006C(body)
 * Description      : 支給依頼取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : 支給依頼取込処理 T_MD070_BPO_94F
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                       Description
 * -------------------------- ------------------------------------------------------------
 *  init_proc                  初期処理 (F-1)
 *  get_header_proc            ヘッダデータ取得処理 (F-2)
 *  get_line_proc              明細データ取得処理 (F-3)
 *  chk_essent_proc            必須チェック処理 (F-4)
 *  chk_exist_mst_proc         マスタ存在チェック処理 (F-5)
 *  get_relation_proc          関連データ取得処理 (F-6)
 *  set_data_proc              登録データ設定処理
 *  calc_load_efficiency_proc  積載効率算出
 *  put_header_proc            受注ヘッダアドオン登録処理 (F-7)
 *  put_line_proc              受注明細アドオン登録処理 (F-8)
 *  delete_proc                データ削除処理 (F-9)
 *  put_dump_msg               データダンプ一括出力処理
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/13    1.0   Oracle 椎名      初回作成
 *  2008/06/30    1.1   Oracle 椎名      運賃区分･指示部署･付帯コード、初期値設定
 *                                       登録ステータス変更
 *  2008/07/08    1.2   Oracle 山根一浩  I_S_192対応
 *  2008/07/17    1.3   Oracle 椎名      MD050指摘事項#13対応
 *  2008/07/24    1.4   Oracle 椎名      内部課題#32,内部変更#166･#173対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_h_target_cnt  NUMBER;                    -- 対象件数(ヘッダ)
  gn_l_target_cnt  NUMBER;                    -- 対象件数(明細)
  gn_h_normal_cnt  NUMBER;                    -- 正常件数(ヘッダ)
  gn_l_normal_cnt  NUMBER;                    -- 正常件数(明細)
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
  check_lock_expt           EXCEPTION;     -- ロック取得エラー
  proc_err_expt             EXCEPTION;     -- 処理エラー
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo940006c';            -- パッケージ名
  gv_msg_kbn_xxpo     CONSTANT VARCHAR2(5)   := 'XXPO';                   -- 仕入・有償支給
-- 2008/07/17 v1.3 Start
  gv_msg_kbn_xxcmn    CONSTANT VARCHAR2(5)   := 'XXCMN';                  -- マスタ・経理・共通
  -- ルックアップ
  gv_lup_weight_capacity  CONSTANT VARCHAR2(100)   := 'XXCMN_WEIGHT_CAPACITY_CLASS'; -- 重量容積区分
  gv_lup_freight_class    CONSTANT VARCHAR2(100)   := 'XXWSH_FREIGHT_CLASS';         -- 運賃区分
  gv_lup_takeback_class   CONSTANT VARCHAR2(100)   := 'XXWSH_TAKEBACK_CLASS';        -- 引取区分
  gv_lup_arrival_time     CONSTANT VARCHAR2(100)   := 'XXWSH_ARRIVAL_TIME';          -- 着荷時間
-- 2008/07/17 v1.3 End
  gv_header           CONSTANT VARCHAR2(1)   := '0';                      -- ヘッダ
  gv_line             CONSTANT VARCHAR2(1)   := '1';                      -- 明細
  gv_object           CONSTANT VARCHAR2(1)   := '1';                      -- 対象
  gv_we               CONSTANT VARCHAR2(1)   := '1';                      -- 重量
  gv_ca               CONSTANT VARCHAR2(1)   := '2';                      -- 容積
  gv_leaf             CONSTANT VARCHAR2(1)   := '1';                      -- リーフ
  gv_drink            CONSTANT VARCHAR2(1)   := '2';                      -- ドリンク
  gv_data_class       CONSTANT VARCHAR2(50)  := 'データ種別';
  gv_trans_type       CONSTANT VARCHAR2(50)  := '発生区分';
  gv_vendor           CONSTANT VARCHAR2(50)  := '取引先';
  gv_arvl_time_from   CONSTANT VARCHAR2(50)  := '入庫日FROM';
  gv_arvl_time_to     CONSTANT VARCHAR2(50)  := '入庫日TO';
  gv_security_class   CONSTANT VARCHAR2(50)  := 'セキュリティ区分';
  gv_opminv_close     CONSTANT VARCHAR2(50)  := 'OPM在庫会計期間CLOSE年月取得関数';
  gv_max_ship         CONSTANT VARCHAR2(50)  := '最大配送区分算出関数';
  gv_unit_price       CONSTANT VARCHAR2(50)  := '支給単価取得関数';
-- 2008/07/24 v1.4 Start
  gv_get_seq_no       CONSTANT VARCHAR2(100) := '採番関数';
  gv_calc_total_value CONSTANT VARCHAR2(100) := '積載効率チェック(合計値算出)';
  gv_tkn_calc_load_ef_we  CONSTANT VARCHAR2(100) := '積載効率チェック(積載効率算出:重量)';
  gv_tkn_calc_load_ef_ca  CONSTANT VARCHAR2(100) := '積載効率チェック(積載効率算出:容積)';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  gv_oprtn_day        CONSTANT VARCHAR2(50)  := '稼働日算出関数';
  gv_msg_comma        CONSTANT VARCHAR2(3)   := ',';
-- 2008/07/17 v1.3 End
--
  -- プロファイル
  gv_master_org_id    CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';     -- マスタ組織
  gv_price_list_id    CONSTANT VARCHAR2(50) := 'XXPO_PRICE_LIST_ID';      -- 代表価格表
  gv_item_div_id      CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV_SECURITY'; -- 商品区分(セキュリティ)
--
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_para_name    CONSTANT VARCHAR2(10) := 'PARAM_NAME';
  gv_tkn_common_name  CONSTANT VARCHAR2(10) := 'NG_COMMON';
  gv_tkn_date_item1   CONSTANT VARCHAR2(10) := 'ITEM1';
  gv_tkn_date_item2   CONSTANT VARCHAR2(10) := 'ITEM2';
  gv_tkn_count        CONSTANT VARCHAR2(10) := 'CNT';
  gv_tkn_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
-- 2008/07/24 v1.4 Start
  gv_tkn_request_no   CONSTANT VARCHAR2(100) := 'REQUEST_NO';
  gv_tkn_item_no      CONSTANT VARCHAR2(100) := 'ITEM_NO';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  gv_tkn_date_item    CONSTANT VARCHAR2(10) := 'ITEM';
-- 2008/07/17 v1.3 End
--
  -- 対象名
  gv_srhi_name        CONSTANT VARCHAR2(100) := '支給依頼情報インタフェーステーブルヘッダ';
  gv_srli_name        CONSTANT VARCHAR2(100) := '支給依頼情報インタフェーステーブル明細';
-- 2008/07/17 v1.3 Start
  gv_weight_capacity      CONSTANT VARCHAR2(100) := '重量容積区分';
  gv_req_department       CONSTANT VARCHAR2(100) := '依頼部署';
  gv_instruction_post     CONSTANT VARCHAR2(100) := '指示部署';
  gv_freight_charge_class CONSTANT VARCHAR2(100) := '運賃区分';
  gv_takeback_class       CONSTANT VARCHAR2(100) := '引取区分';
  gv_arrival_time_from    CONSTANT VARCHAR2(100) := '着荷時間FROM';
  gv_arrival_time_to      CONSTANT VARCHAR2(100) := '着荷時間TO';
  gv_request_qty          CONSTANT VARCHAR2(100) := '依頼数量';
-- 2008/07/17 v1.3 End
--
  -- メッセージ番号
  -- プロファイル取得エラー
  gv_msg_get_prf      CONSTANT VARCHAR2(20) := 'APP-XXPO-10220';
  -- データ取得エラー
  gv_msg_get_data     CONSTANT VARCHAR2(20) := 'APP-XXPO-10229';
  -- ロック取得エラー
  gv_msg_lock         CONSTANT VARCHAR2(20) := 'APP-XXPO-10216';
  -- 必須入力エラー
  gv_msg_essent       CONSTANT VARCHAR2(20) := 'APP-XXPO-10230';
  -- 存在チェックエラー
  gv_msg_exist        CONSTANT VARCHAR2(20) := 'APP-XXPO-10234';
  -- 在庫会計期間クローズチェックエラー
  gv_msg_close_period CONSTANT VARCHAR2(20) := 'APP-XXPO-10231';
  -- 品目重複チェックエラー
  gv_msg_redundant    CONSTANT VARCHAR2(20) := 'APP-XXPO-10232';
  -- 仕入有償時品目チェックエラー
  gv_msg_trans_type   CONSTANT VARCHAR2(20) := 'APP-XXPO-10233';
  -- パラメータ必須エラー
  gv_msg_para_essent  CONSTANT VARCHAR2(20) := 'APP-XXPO-10235';
  -- パラメータ日付エラー
  gv_msg_date         CONSTANT VARCHAR2(20) := 'APP-XXPO-10236';
-- 2008/07/17 v1.3 Start
  -- 日付不正チェックエラー
  gv_msg_ship_date    CONSTANT VARCHAR2(20) := 'APP-XXPO-10258';
  -- 重量容積区分一致チェックエラー
  gv_msg_weight_capacity_agree  CONSTANT VARCHAR2(20) := 'APP-XXPO-10259';
  -- マスタ存在チェックエラー
  gv_msg_mst_exist    CONSTANT VARCHAR2(20) := 'APP-XXPO-10260';
  -- 依頼数量不正エラー
  gv_msg_request_qty  CONSTANT VARCHAR2(20) := 'APP-XXPO-10261';
-- 2008/07/17 v1.3 End
  -- 共通関数エラー
  gv_msg_common       CONSTANT VARCHAR2(20) := 'APP-XXPO-10237';
--
-- 2008/07/24 v1.4 Start
  gv_msg_xxcmn10604   CONSTANT VARCHAR2(20) := 'APP-XXCMN-10604';
  gv_msg_xxpo10120    CONSTANT VARCHAR2(100) := 'APP-XXPO-10120';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  -- メッセージ:APP-XXPO-30051 入力パラメータ(見出し)
  gv_msg_xxpo30051    CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';
  -- メッセージ:APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxcmn00005   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005';
-- 2008/07/17 v1.3 End
  -- 処理件数(ヘッダ)
  gv_msg_h_target_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10239';
  -- 処理件数(明細)
  gv_msg_l_target_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10240';
  -- 成功件数(ヘッダ)
  gv_msg_h_normal_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10241';
  -- 成功件数(明細)
  gv_msg_l_normal_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10242';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  ---------------------------------------------
  -- 支給依頼情報インタフェース取得(ヘッダ)  --
  ---------------------------------------------
  -- 支給依頼情報インタフェースヘッダID
  TYPE supply_req_headers_if_id_tbl IS TABLE OF
    xxpo_supply_req_headers_if.supply_req_headers_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- 発生区分
  TYPE trans_type_tbl IS TABLE OF
    xxpo_supply_req_headers_if.trans_type%TYPE INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE weight_capacity_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼部署コード
  TYPE requested_department_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.requested_department_code%TYPE INDEX BY BINARY_INTEGER;
  -- 指示部署コード
  TYPE instruction_post_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.instruction_post_code%TYPE INDEX BY BINARY_INTEGER;
  -- 取引先コード
  TYPE vendor_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  -- 配送先コード
  TYPE ship_to_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.ship_to_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出庫倉庫コード
  TYPE shipped_locat_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者コード
  TYPE freight_carrier_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出庫日
  TYPE ship_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 入庫日
  TYPE arvl_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arvl_date%TYPE INDEX BY BINARY_INTEGER;
  -- 運賃区分
  TYPE freight_charge_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- 引取区分
  TYPE takeback_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.takeback_class%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間FROM
  TYPE arrival_time_from_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間TO
  TYPE arrival_time_to_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- 製造日
  TYPE product_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.product_date%TYPE INDEX BY BINARY_INTEGER;
  -- 製造品目コード
  TYPE producted_item_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.producted_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 製造番号
  TYPE product_number_tbl IS TABLE OF
    xxpo_supply_req_headers_if.product_number%TYPE INDEX BY BINARY_INTEGER;
  -- ヘッダ摘要
  TYPE header_description_tbl IS TABLE OF
    xxpo_supply_req_headers_if.header_description%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入先ID
  TYPE vendor_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_id%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客番号
  TYPE customer_num_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- パーティID
  TYPE cust_party_id_tbl IS TABLE OF
    xxcmn_cust_accounts_v.party_id%TYPE INDEX BY BINARY_INTEGER;
  -- 価格表
  TYPE spare2_tbl IS TABLE OF
    xxcmn_vendors_v.spare2%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客ID
  TYPE cust_account_id_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- 仕入先サイトID
  TYPE vendor_site_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- 倉庫ID
  TYPE inventory_location_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- リーフ基準カレンダ
  TYPE leaf_calender_tbl IS TABLE OF
    xxcmn_item_locations_v.leaf_calender%TYPE INDEX BY BINARY_INTEGER;
  -- ドリンク基準カレンダ
  TYPE drink_calender_tbl IS TABLE OF
    xxcmn_item_locations_v.drink_calender%TYPE INDEX BY BINARY_INTEGER;
  -- パーティID
  TYPE carriers_party_id_tbl IS TABLE OF
    xxwsh_order_headers_all.career_id%TYPE INDEX BY BINARY_INTEGER;
  -- 品目ID
  TYPE h_item_id_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 小口個数
  TYPE small_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ラベル枚数
  TYPE label_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 合計数量
  TYPE sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 最大配送区分
  TYPE ship_method_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- ドリンク積載重量
  TYPE drink_deadweight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- リーフ積載重量
  TYPE leaf_deadweight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ドリンク積載容積
  TYPE drink_loading_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- リーフ積載容積
  TYPE leaf_loading_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 重量積載効率
  TYPE load_efficiency_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積積載効率
  TYPE load_efficiency_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 合計重量
  TYPE h_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 合計容積
  TYPE h_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷依頼No
  TYPE seq_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 Start
  -- ヘッダデータダンプ
  TYPE lr_h_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 End
--
  ---------------------------------------------
  -- 支給依頼情報インタフェース取得(明細)  --
  ---------------------------------------------
  -- 支給依頼情報インタフェース明細ID
  TYPE supply_req_lines_if_id_tbl IS TABLE OF
    xxpo_supply_req_lines_if.supply_req_lines_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE line_number_tbl IS TABLE OF
    xxpo_supply_req_lines_if.line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE item_code_tbl IS TABLE OF
    xxpo_supply_req_lines_if.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 付帯
  TYPE futai_code_tbl IS TABLE OF
    xxpo_supply_req_lines_if.futai_code%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼数量
  TYPE request_qty_tbl IS TABLE OF
    xxpo_supply_req_lines_if.request_qty%TYPE INDEX BY BINARY_INTEGER;
  -- 明細摘要
  TYPE line_description_tbl IS TABLE OF
    xxpo_supply_req_lines_if.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- ヘッダID
  TYPE line_headers_id_tbl IS TABLE OF
    xxpo_supply_req_lines_if.supply_req_headers_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注明細アドオンID
  TYPE order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 品目ID
  TYPE l_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 単位
  TYPE item_um_tbl IS TABLE OF
    xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷入数
  TYPE num_of_deliver_tbl IS TABLE OF
    xxcmn_item_mst_v.num_of_deliver%TYPE INDEX BY BINARY_INTEGER;
  -- 入出庫換算単位
  TYPE conv_unit_tbl IS TABLE OF
    xxcmn_item_mst_v.conv_unit%TYPE INDEX BY BINARY_INTEGER; 
  -- ケース入数
  TYPE num_of_cases_tbl IS TABLE OF
    xxcmn_item_mst_v.num_of_cases%TYPE INDEX BY BINARY_INTEGER;
  -- INV品目ID
  TYPE inventory_item_id_tbl IS TABLE OF
    xxcmn_item_mst_v.inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 倉庫品目ID
  TYPE whse_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER; 
  -- 倉庫品目コード
  TYPE item_no_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ロット
  TYPE lot_ctl_tbl IS TABLE OF
    xxcmn_item_mst_v.lot_ctl%TYPE INDEX BY BINARY_INTEGER;
  -- 単価
  TYPE unit_price_tbl IS TABLE OF
    xxwsh_order_lines_all.unit_price%TYPE INDEX BY BINARY_INTEGER;
  -- 合計重量
  TYPE l_sum_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- 合計容積
  TYPE l_sum_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 Start
  -- 重量容積区分
  TYPE l_weight_capacity_class IS TABLE OF
    xxcmn_item_mst_v.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- 明細データダンプ
  TYPE lr_l_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 End
--
  ---------------------------------------------
  -- 受注ヘッダアドオン登録                  --
  ---------------------------------------------
  -- 受注ヘッダアドオンID
  TYPE ph_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注タイプID
  TYPE ph_order_type_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- 組織ID
  TYPE ph_organization_id_tbl IS TABLE OF
    xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダID
  TYPE ph_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 最新フラグ
  TYPE ph_latest_external_flag_tbl IS TABLE OF
    xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- 受注日
  TYPE ph_ordered_date_tbl IS TABLE OF
    xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客ID
  TYPE ph_customer_id_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客
  TYPE ph_customer_code_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先ID
  TYPE ph_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先
  TYPE ph_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷指示
  TYPE ph_shipping_instructions_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者ID
  TYPE ph_career_id_tbl IS TABLE OF
    xxwsh_order_headers_all.career_id%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者
  TYPE ph_freight_carrier_code_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE ph_shipping_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客発注
  TYPE ph_cust_po_number_tbl IS TABLE OF
    xxwsh_order_headers_all.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- 価格表
  TYPE ph_price_list_id_tbl IS TABLE OF
    xxwsh_order_headers_all.price_list_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE ph_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- 元依頼No
  TYPE ph_base_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.base_request_no%TYPE INDEX BY BINARY_INTEGER;
  -- ステータス
  TYPE ph_req_status_tbl IS TABLE OF
    xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- 配送No
  TYPE ph_delivery_no_tbl IS TABLE OF
    xxwsh_order_headers_all.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- 前回配送No
  TYPE ph_prev_delivery_no_tbl IS TABLE OF
    xxwsh_order_headers_all.prev_delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷予定日
  TYPE ph_schedule_ship_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE ph_schedule_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 混載元No
  TYPE ph_mixed_no_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_no%TYPE INDEX BY BINARY_INTEGER;
  -- パレット回収枚数
  TYPE ph_collected_pallet_qty_tbl IS TABLE OF
    xxwsh_order_headers_all.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER;
  -- 物流担当確認依頼区分
  TYPE ph_confirm_request_class_tbl IS TABLE OF
    xxwsh_order_headers_all.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;
  -- 運賃区分
  TYPE ph_freight_charge_class_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- 支給出庫指示区分
  TYPE ph_shikyu_inst_class_tbl IS TABLE OF
    xxwsh_order_headers_all.shikyu_instruction_class%TYPE INDEX BY BINARY_INTEGER;
  -- 支給指示受領区分
  TYPE ph_shikyu_inst_rcv_class_tbl IS TABLE OF
    xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE INDEX BY BINARY_INTEGER;
  -- 有償金額確定区分
  TYPE ph_amount_fix_class_tbl IS TABLE OF
    xxwsh_order_headers_all.amount_fix_class%TYPE INDEX BY BINARY_INTEGER;
  -- 引取区分
  TYPE ph_takeback_class_tbl IS TABLE OF
    xxwsh_order_headers_all.takeback_class%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元ID
  TYPE ph_deliver_from_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元保管場所
  TYPE ph_deliver_from_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE ph_head_sales_branch_tbl IS TABLE OF
    xxwsh_order_headers_all.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 入力拠点
  TYPE ph_input_sales_branch_tbl IS TABLE OF
    xxwsh_order_headers_all.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 発注No
  TYPE ph_po_no_tbl IS TABLE OF
    xxwsh_order_headers_all.po_no%TYPE INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE ph_prod_class_tbl IS TABLE OF
    xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- 品目区分
  TYPE ph_item_class_tbl IS TABLE OF
    xxwsh_order_headers_all.item_class%TYPE INDEX BY BINARY_INTEGER;
  -- 契約外運賃区分
  TYPE ph_no_cont_freight_class_tbl IS TABLE OF
    xxwsh_order_headers_all.no_cont_freight_class%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間FROM
  TYPE ph_arrival_time_from_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷時間TO
  TYPE ph_arrival_time_to_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- 製造品目ID
  TYPE ph_designated_item_id_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 製造品目
  TYPE ph_designated_item_code_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 製造日
  TYPE ph_designated_prod_date_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_production_date%TYPE INDEX BY BINARY_INTEGER;
  -- 製造枝番
  TYPE ph_designated_branch_no_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_branch_no%TYPE INDEX BY BINARY_INTEGER;
  -- 送り状No
  TYPE ph_slip_number_tbl IS TABLE OF
    xxwsh_order_headers_all.slip_number%TYPE INDEX BY BINARY_INTEGER;
  -- 合計数量
  TYPE ph_sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 小口個数
  TYPE ph_small_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ラベル枚数
  TYPE ph_label_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 重量積載効率
  TYPE ph_loading_efficiency_we_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積積載効率
  TYPE ph_loading_efficiency_ca_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 基本重量
  TYPE ph_based_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 基本容積
  TYPE ph_based_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 積載重量合計
  TYPE ph_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 積載容積合計
  TYPE ph_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 混載率
  TYPE ph_mixed_ratio_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_ratio%TYPE INDEX BY BINARY_INTEGER;
  -- パレット合計枚数
  TYPE ph_pallet_sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- パレット実績枚数
  TYPE ph_real_pallet_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.real_pallet_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 合計パレット重量
  TYPE ph_sum_pallet_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ソース参照
  TYPE ph_order_source_ref_tbl IS TABLE OF
    xxwsh_order_headers_all.order_source_ref%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者_実績ID
  TYPE ph_result_freight_carr_id_tbl IS TABLE OF
    xxwsh_order_headers_all.result_freight_carrier_id%TYPE INDEX BY BINARY_INTEGER;
  -- 運送業者_実績
  TYPE ph_result_fre_carr_code_tbl IS TABLE OF
    xxwsh_order_headers_all.result_freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- 配送区分_実績
  TYPE ph_result_ship_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.result_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先_実績ID
  TYPE ph_result_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.result_deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先_実績
  TYPE ph_result_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.result_deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷日
  TYPE ph_shipped_date_tbl IS TABLE OF
    xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷日
  TYPE ph_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE ph_weight_capacity_class_tbl IS TABLE OF
    xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- 実績計上済区分
  TYPE ph_actual_confirm_class_tbl IS TABLE OF
    xxwsh_order_headers_all.actual_confirm_class%TYPE INDEX BY BINARY_INTEGER;
  -- 通知ステータス
  TYPE ph_notif_status_tbl IS TABLE OF
    xxwsh_order_headers_all.notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- 前回通知ステータス
  TYPE ph_prev_notif_status_tbl IS TABLE OF
    xxwsh_order_headers_all.prev_notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- 確定通知実施日時
  TYPE ph_notif_date_tbl IS TABLE OF
    xxwsh_order_headers_all.notif_date%TYPE INDEX BY BINARY_INTEGER;
  -- 新規修正フラグ
  TYPE ph_new_modify_flg_tbl IS TABLE OF
    xxwsh_order_headers_all.new_modify_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 処理経過ステータス
  TYPE ph_process_status_tbl IS TABLE OF
    xxwsh_order_headers_all.process_status%TYPE INDEX BY BINARY_INTEGER;
  -- 成績管理部署
  TYPE ph_performance_manage_dept_tbl IS TABLE OF
    xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- 指示部署
  TYPE ph_instruction_dept_tbl IS TABLE OF
    xxwsh_order_headers_all.instruction_dept%TYPE INDEX BY BINARY_INTEGER;
  -- 振替先ID
  TYPE ph_transfer_location_id_tbl IS TABLE OF
    xxwsh_order_headers_all.transfer_location_id%TYPE INDEX BY BINARY_INTEGER;
  -- 振替先
  TYPE ph_transfer_location_code_tbl IS TABLE OF
    xxwsh_order_headers_all.transfer_location_code%TYPE INDEX BY BINARY_INTEGER;
  -- 混載記号
  TYPE ph_mixed_sign_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_sign%TYPE INDEX BY BINARY_INTEGER;
  -- 画面更新日時
  TYPE ph_screen_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.screen_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 画面更新者
  TYPE ph_screen_update_by_tbl IS TABLE OF
    xxwsh_order_headers_all.screen_update_by%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷依頼締め日時
  TYPE ph_tightening_date_tbl IS TABLE OF
    xxwsh_order_headers_all.tightening_date%TYPE INDEX BY BINARY_INTEGER;
  -- 取引先ID
  TYPE ph_vendor_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_id%TYPE INDEX BY BINARY_INTEGER;
  -- 取引先
  TYPE ph_vendor_code_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  -- 取引先サイトID
  TYPE ph_vendor_site_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- 取引先サイト
  TYPE ph_vendor_site_code_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- 登録順序
  TYPE ph_registered_sequence_tbl IS TABLE OF
    xxwsh_order_headers_all.registered_sequence%TYPE INDEX BY BINARY_INTEGER;
  -- 締めコンカレントID
  TYPE ph_tightening_program_id_tbl IS TABLE OF
    xxwsh_order_headers_all.tightening_program_id%TYPE INDEX BY BINARY_INTEGER;
  -- 締め後修正区分
  TYPE ph_corrected_tighten_class_tbl IS TABLE OF
    xxwsh_order_headers_all.corrected_tighten_class%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE ph_created_by_tbl IS TABLE OF
    xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE ph_creation_date_tbl IS TABLE OF
    xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE ph_last_updated_by_tbl IS TABLE OF
    xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE ph_last_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE ph_last_update_login_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE ph_request_id_tbl IS TABLE OF
    xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラム・アプリケーションID
  TYPE ph_program_application_id_tbl IS TABLE OF
    xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE ph_program_id_tbl IS TABLE OF
    xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE ph_program_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- 受注明細アドオン登録                    --
  ---------------------------------------------
  -- 受注明細アドオンID
  TYPE pl_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE pl_order_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE pl_order_line_number_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダID
  TYPE pl_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注明細ID
  TYPE pl_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE pl_request_no_tbl IS TABLE OF
    xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目ID
  TYPE pl_ship_inv_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目
  TYPE pl_shipping_item_code_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE pl_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 単位
  TYPE pl_uom_code_tbl IS TABLE OF
    xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- 単価
  TYPE pl_unit_price_tbl IS TABLE OF
    xxwsh_order_lines_all.unit_price%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷実績数量
  TYPE pl_shipped_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.shipped_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 指定製造日
  TYPE pl_designated_prod_date_tbl IS TABLE OF
    xxwsh_order_lines_all.designated_production_date%TYPE INDEX BY BINARY_INTEGER;
  -- 拠点依頼数量
  TYPE pl_based_request_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目ID
  TYPE pl_request_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目
  TYPE pl_request_item_code_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 入庫実績数量
  TYPE pl_ship_to_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.ship_to_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 付帯コード
  TYPE pl_futai_code_tbl IS TABLE OF
    xxwsh_order_lines_all.futai_code%TYPE INDEX BY BINARY_INTEGER;
  -- 指定日付（リーフ）
  TYPE pl_designated_date_tbl IS TABLE OF
    xxwsh_order_lines_all.designated_date%TYPE INDEX BY BINARY_INTEGER;
  -- 移動No
  TYPE pl_move_number_tbl IS TABLE OF
    xxwsh_order_lines_all.move_number%TYPE INDEX BY BINARY_INTEGER;
  -- 発注No
  TYPE pl_po_number_tbl IS TABLE OF
    xxwsh_order_lines_all.po_number%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客発注
  TYPE pl_cust_po_number_tbl IS TABLE OF
    xxwsh_order_lines_all.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- パレット数
  TYPE pl_pallet_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 段数
  TYPE pl_layer_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.layer_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ケース数
  TYPE pl_case_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.case_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 重量
  TYPE pl_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積
  TYPE pl_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- パレット枚数
  TYPE pl_pallet_qty_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_qty%TYPE INDEX BY BINARY_INTEGER;
  -- パレット重量
  TYPE pl_pallet_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 引当数
  TYPE pl_reserved_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 自動手動引当区分
  TYPE pl_auto_reserve_class_tbl IS TABLE OF
    xxwsh_order_lines_all.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- 削除フラグ
  TYPE pl_delete_flag_tbl IS TABLE OF
    xxwsh_order_lines_all.delete_flag%TYPE INDEX BY BINARY_INTEGER;
  -- 警告区分
  TYPE pl_warning_class_tbl IS TABLE OF
    xxwsh_order_lines_all.warning_class%TYPE INDEX BY BINARY_INTEGER;
  -- 警告日付
  TYPE pl_warning_date_tbl IS TABLE OF
    xxwsh_order_lines_all.warning_date%TYPE INDEX BY BINARY_INTEGER;
  -- 摘要
  TYPE pl_line_description_tbl IS TABLE OF
    xxwsh_order_lines_all.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- 倉替返品インタフェース済フラグ
  TYPE pl_rm_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.rm_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷依頼インタフェース済フラグ
  TYPE pl_shipping_request_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_request_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷実績インタフェース済フラグ
  TYPE pl_shipping_result_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_result_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE pl_created_by_tbl IS TABLE OF
    xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE pl_creation_date_tbl IS TABLE OF
    xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE pl_last_updated_by_tbl IS TABLE OF
    xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE pl_last_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE pl_last_update_login_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE pl_request_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラム・アプリケーションID
  TYPE pl_program_application_id_tbl IS TABLE OF
    xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE pl_program_id_tbl IS TABLE OF
    xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE pl_program_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- 2008/07/17 v1.3 Start
  -- ヘッダメッセージPL/SQL表型
  TYPE msg_h_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- 明細メッセージPL/SQL表型
  TYPE msg_l_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
-- 2008/07/17 v1.3 End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
-- 2008/07/17 v1.3 Start
  -- 入力パラメータ
  gv_iv_data_class       VARCHAR2(100);      -- 1.データ種別
  gv_iv_trans_type       VARCHAR2(100);      -- 2.発生区分
  gv_iv_req_dept         VARCHAR2(100);      -- 3.依頼部署
  gv_iv_vendor           VARCHAR2(100);      -- 4.取引先
  gv_iv_ship_to          VARCHAR2(100);      -- 5.配送先
  gv_iv_arvl_time_from   VARCHAR2(100);      -- 6.入庫日FROM
  gv_iv_arvl_time_to     VARCHAR2(100);      -- 7.入庫日TO
  gv_iv_security_class   VARCHAR2(100);      -- 8.セキュリティ区分
--
-- 2008/07/17 v1.3 End
  -- コレクションの定義
  -- 取得用(ヘッダ)
  gt_sup_req_headers_if_id_tbl        supply_req_headers_if_id_tbl;
  gt_trans_type_tbl                   trans_type_tbl;
  gt_weight_capacity_class_tbl        weight_capacity_class_tbl;
  gt_req_department_code_tbl          requested_department_code_tbl;
  gt_instruction_post_code_tbl        instruction_post_code_tbl;
  gt_vendor_code_tbl                  vendor_code_tbl;
  gt_ship_to_code_tbl                 ship_to_code_tbl;
  gt_shipped_locat_code_tbl           shipped_locat_code_tbl;
  gt_freight_carrier_code_tbl         freight_carrier_code_tbl;
  gt_ship_date_tbl                    ship_date_tbl;
  gt_arvl_date_tbl                    arvl_date_tbl;
  gt_freight_charge_class_tbl         freight_charge_class_tbl;
  gt_takeback_class_tbl               takeback_class_tbl;
  gt_arrival_time_from_tbl            arrival_time_from_tbl;
  gt_arrival_time_to_tbl              arrival_time_to_tbl;
  gt_product_date_tbl                 product_date_tbl;
  gt_producted_item_code_tbl          producted_item_code_tbl;
  gt_product_number_tbl               product_number_tbl;
  gt_header_description_tbl           header_description_tbl;
  gt_order_header_id_tbl              order_header_id_tbl;
  gt_vendor_id_tbl                    vendor_id_tbl;
  gt_customer_num_tbl                 customer_num_tbl;
  gt_cust_party_id_tbl                cust_party_id_tbl;
  gt_spare2_tbl                       spare2_tbl;
  gt_cust_account_id_tbl              cust_account_id_tbl;
  gt_vendor_site_id_tbl               vendor_site_id_tbl;
  gt_inventory_location_id_tbl        inventory_location_id_tbl;
  gt_leaf_calender_tbl                leaf_calender_tbl;
  gt_drink_calender_tbl               drink_calender_tbl;
  gt_carriers_party_id_tbl            carriers_party_id_tbl;
  gt_h_item_id_tbl                    h_item_id_tbl;
  gt_small_quantity_tbl               small_quantity_tbl;
  gt_label_quantity_tbl               label_quantity_tbl;
  gt_sum_quantity_tbl                 sum_quantity_tbl;
  gt_ship_method_tbl                  ship_method_tbl;
  gt_drink_deadweight_tbl             drink_deadweight_tbl;
  gt_leaf_deadweight_tbl              leaf_deadweight_tbl;
  gt_drink_loading_capacity_tbl       drink_loading_capacity_tbl;
  gt_leaf_loading_capacity_tbl        leaf_loading_capacity_tbl;
  gt_load_efficiency_we_tbl           load_efficiency_weight_tbl;
  gt_load_efficiency_ca_tbl           load_efficiency_capacity_tbl;
  gt_h_sum_weight_tbl                 h_sum_weight_tbl;
  gt_h_sum_capacity_tbl               h_sum_capacity_tbl;
  gt_seq_no_tbl                       seq_no_tbl;
-- 2008/07/17 v1.3 Start
  gt_lr_h_data_dump_tbl               lr_h_data_dump_tbl;
-- 2008/07/17 v1.3 End
  -- 取得用(明細)
  gt_supply_req_lines_if_id_tbl       supply_req_lines_if_id_tbl;
  gt_line_number_tbl                  line_number_tbl;
  gt_item_code_tbl                    item_code_tbl;
  gt_futai_code_tbl                   futai_code_tbl;
  gt_request_qty_tbl                  request_qty_tbl;
  gt_line_description_tbl             line_description_tbl;
  gt_line_headers_id_tbl              line_headers_id_tbl;
  gt_order_line_id_tbl                order_line_id_tbl;
  gt_l_item_id_tbl                    l_item_id_tbl;
  gt_item_um_tbl                      item_um_tbl;
  gt_num_of_deliver_tbl               num_of_deliver_tbl;
  gt_conv_unit_tbl                    conv_unit_tbl;
  gt_num_of_cases_tbl                 num_of_cases_tbl;
  gt_inventory_item_id_tbl            inventory_item_id_tbl;
  gt_whse_item_id_tbl                 whse_item_id_tbl;
  gt_item_no_tbl                      item_no_tbl;
  gt_lot_ctl_tbl                      lot_ctl_tbl;
  gt_unit_price_tbl                   unit_price_tbl;
  gt_l_sum_weight_tbl                 l_sum_weight_tbl;
  gt_l_sum_capacity_tbl               l_sum_capacity_tbl;
-- 2008/07/17 v1.3 Start
  gt_l_weight_capacity_class          l_weight_capacity_class;
  gt_lr_l_data_dump_tbl               lr_l_data_dump_tbl;
-- 2008/07/17 v1.3 End
--
  -- 登録用(ヘッダ)
  gt_ph_order_header_id_tbl                 ph_order_header_id_tbl;
  gt_ph_order_type_id_tbl                   ph_order_type_id_tbl;
  gt_ph_organization_id_tbl                 ph_organization_id_tbl;
  gt_ph_header_id_tbl                       ph_header_id_tbl;
  gt_ph_latest_external_flag_tbl            ph_latest_external_flag_tbl;
  gt_ph_ordered_date_tbl                    ph_ordered_date_tbl;
  gt_ph_customer_id_tbl                     ph_customer_id_tbl;
  gt_ph_customer_code_tbl                   ph_customer_code_tbl;
  gt_ph_deliver_to_id_tbl                   ph_deliver_to_id_tbl;
  gt_ph_deliver_to_tbl                      ph_deliver_to_tbl;
  gt_ph_shipping_inst_tbl                   ph_shipping_instructions_tbl;
  gt_ph_career_id_tbl                       ph_career_id_tbl;
  gt_ph_freight_carrier_code_tbl            ph_freight_carrier_code_tbl;
  gt_ph_shipping_method_code_tbl            ph_shipping_method_code_tbl;
  gt_ph_cust_po_number_tbl                  ph_cust_po_number_tbl;
  gt_ph_price_list_id_tbl                   ph_price_list_id_tbl;
  gt_ph_request_no_tbl                      ph_request_no_tbl;
  gt_ph_base_request_no_tbl                 ph_base_request_no_tbl;
  gt_ph_req_status_tbl                      ph_req_status_tbl;
  gt_ph_delivery_no_tbl                     ph_delivery_no_tbl;
  gt_ph_prev_delivery_no_tbl                ph_prev_delivery_no_tbl;
  gt_ph_schedule_ship_date_tbl              ph_schedule_ship_date_tbl;
  gt_ph_schedule_arr_date_tbl               ph_schedule_arrival_date_tbl;
  gt_ph_mixed_no_tbl                        ph_mixed_no_tbl;
  gt_ph_collected_pallet_qty_tbl            ph_collected_pallet_qty_tbl;
  gt_ph_confirm_req_class_tbl               ph_confirm_request_class_tbl;
  gt_ph_freight_charge_class_tbl            ph_freight_charge_class_tbl;
  gt_ph_shikyu_inst_class_tbl               ph_shikyu_inst_class_tbl;
  gt_ph_sk_inst_rcv_class_tbl               ph_shikyu_inst_rcv_class_tbl;
  gt_ph_amount_fix_class_tbl                ph_amount_fix_class_tbl;
  gt_ph_takeback_class_tbl                  ph_takeback_class_tbl;
  gt_ph_deliver_from_id_tbl                 ph_deliver_from_id_tbl;
  gt_ph_deliver_from_tbl                    ph_deliver_from_tbl;
  gt_ph_head_sales_branch_tbl               ph_head_sales_branch_tbl;
  gt_ph_input_sales_branch_tbl              ph_input_sales_branch_tbl;
  gt_ph_po_no_tbl                           ph_po_no_tbl;
  gt_ph_prod_class_tbl                      ph_prod_class_tbl;
  gt_ph_item_class_tbl                      ph_item_class_tbl;
  gt_ph_no_cont_fre_class_tbl               ph_no_cont_freight_class_tbl;
  gt_ph_arrival_time_from_tbl               ph_arrival_time_from_tbl;
  gt_ph_arrival_time_to_tbl                 ph_arrival_time_to_tbl;
  gt_ph_designated_item_id_tbl              ph_designated_item_id_tbl;
  gt_ph_designated_item_code_tbl            ph_designated_item_code_tbl;
  gt_ph_designated_prod_date_tbl            ph_designated_prod_date_tbl;
  gt_ph_designated_branch_no_tbl            ph_designated_branch_no_tbl;
  gt_ph_slip_number_tbl                     ph_slip_number_tbl;
  gt_ph_sum_quantity_tbl                    ph_sum_quantity_tbl;
  gt_ph_small_quantity_tbl                  ph_small_quantity_tbl;
  gt_ph_label_quantity_tbl                  ph_label_quantity_tbl;
  gt_ph_load_efficiency_we_tbl              ph_loading_efficiency_we_tbl;
  gt_ph_load_efficiency_ca_tbl              ph_loading_efficiency_ca_tbl;
  gt_ph_based_weight_tbl                    ph_based_weight_tbl;
  gt_ph_based_capacity_tbl                  ph_based_capacity_tbl;
  gt_ph_sum_weight_tbl                      ph_sum_weight_tbl;
  gt_ph_sum_capacity_tbl                    ph_sum_capacity_tbl;
  gt_ph_mixed_ratio_tbl                     ph_mixed_ratio_tbl;
  gt_ph_pallet_sum_quantity_tbl             ph_pallet_sum_quantity_tbl;
  gt_ph_real_pallet_quantity_tbl            ph_real_pallet_quantity_tbl;
  gt_ph_sum_pallet_weight_tbl               ph_sum_pallet_weight_tbl;
  gt_ph_order_source_ref_tbl                ph_order_source_ref_tbl;
  gt_ph_result_fre_carr_id_tbl              ph_result_freight_carr_id_tbl;
  gt_ph_result_fre_carr_code_tbl            ph_result_fre_carr_code_tbl;
  gt_ph_res_ship_meth_code_tbl              ph_result_ship_method_code_tbl;
  gt_ph_result_deliver_to_id_tbl            ph_result_deliver_to_id_tbl;
  gt_ph_result_deliver_to_tbl               ph_result_deliver_to_tbl;
  gt_ph_shipped_date_tbl                    ph_shipped_date_tbl;
  gt_ph_arrival_date_tbl                    ph_arrival_date_tbl;
  gt_ph_weight_ca_class_tbl                 ph_weight_capacity_class_tbl;
  gt_ph_actual_confirm_class_tbl            ph_actual_confirm_class_tbl;
  gt_ph_notif_status_tbl                    ph_notif_status_tbl;
  gt_ph_prev_notif_status_tbl               ph_prev_notif_status_tbl;
  gt_ph_notif_date_tbl                      ph_notif_date_tbl;
  gt_ph_new_modify_flg_tbl                  ph_new_modify_flg_tbl;
  gt_ph_process_status_tbl                  ph_process_status_tbl;
  gt_ph_perform_manage_dept_tbl             ph_performance_manage_dept_tbl;
  gt_ph_instruction_dept_tbl                ph_instruction_dept_tbl;
  gt_ph_transfer_location_id_tbl            ph_transfer_location_id_tbl;
  gt_ph_trans_location_code_tbl             ph_transfer_location_code_tbl;
  gt_ph_mixed_sign_tbl                      ph_mixed_sign_tbl;
  gt_ph_screen_update_date_tbl              ph_screen_update_date_tbl;
  gt_ph_screen_update_by_tbl                ph_screen_update_by_tbl;
  gt_ph_tightening_date_tbl                 ph_tightening_date_tbl;
  gt_ph_vendor_id_tbl                       ph_vendor_id_tbl;
  gt_ph_vendor_code_tbl                     ph_vendor_code_tbl;
  gt_ph_vendor_site_id_tbl                  ph_vendor_site_id_tbl;
  gt_ph_vendor_site_code_tbl                ph_vendor_site_code_tbl;
  gt_ph_registered_sequence_tbl             ph_registered_sequence_tbl;
  gt_ph_tight_program_id_tbl                ph_tightening_program_id_tbl;
  gt_ph_correct_tight_class_tbl             ph_corrected_tighten_class_tbl;
  gt_ph_created_by_tbl                      ph_created_by_tbl;
  gt_ph_creation_date_tbl                   ph_creation_date_tbl;
  gt_ph_last_updated_by_tbl                 ph_last_updated_by_tbl;
  gt_ph_last_update_date_tbl                ph_last_update_date_tbl;
  gt_ph_last_update_login_tbl               ph_last_update_login_tbl;
  gt_ph_request_id_tbl                      ph_request_id_tbl;
  gt_ph_program_appli_id_tbl                ph_program_application_id_tbl;
  gt_ph_program_id_tbl                      ph_program_id_tbl;
  gt_ph_program_up_date_tbl                 ph_program_update_date_tbl;
  -- 登録用(明細)
  gt_pl_order_line_id_tbl                   pl_order_line_id_tbl;
  gt_pl_order_header_id_tbl                 pl_order_header_id_tbl;
  gt_pl_order_line_number_tbl               pl_order_line_number_tbl;
  gt_pl_header_id_tbl                       pl_header_id_tbl;
  gt_pl_line_id_tbl                         pl_line_id_tbl;
  gt_pl_request_no_tbl                      pl_request_no_tbl;
  gt_pl_ship_inv_item_id_tbl                pl_ship_inv_item_id_tbl;
  gt_pl_shipping_item_code_tbl              pl_shipping_item_code_tbl;
  gt_pl_quantity_tbl                        pl_quantity_tbl;
  gt_pl_uom_code_tbl                        pl_uom_code_tbl;
  gt_pl_unit_price_tbl                      pl_unit_price_tbl;
  gt_pl_shipped_quantity_tbl                pl_shipped_quantity_tbl;
  gt_pl_design_prod_date_tbl                pl_designated_prod_date_tbl;
  gt_pl_based_req_quan_tbl                  pl_based_request_quantity_tbl;
  gt_pl_request_item_id_tbl                 pl_request_item_id_tbl;
  gt_pl_request_item_code_tbl               pl_request_item_code_tbl;
  gt_pl_ship_to_quantity_tbl                pl_ship_to_quantity_tbl;
  gt_pl_futai_code_tbl                      pl_futai_code_tbl;
  gt_pl_designated_date_tbl                 pl_designated_date_tbl;
  gt_pl_move_number_tbl                     pl_move_number_tbl;
  gt_pl_po_number_tbl                       pl_po_number_tbl;
  gt_pl_cust_po_number_tbl                  pl_cust_po_number_tbl;
  gt_pl_pallet_quantity_tbl                 pl_pallet_quantity_tbl;
  gt_pl_layer_quantity_tbl                  pl_layer_quantity_tbl;
  gt_pl_case_quantity_tbl                   pl_case_quantity_tbl;
  gt_pl_weight_tbl                          pl_weight_tbl;
  gt_pl_capacity_tbl                        pl_capacity_tbl;
  gt_pl_pallet_qty_tbl                      pl_pallet_qty_tbl;
  gt_pl_pallet_weight_tbl                   pl_pallet_weight_tbl;
  gt_pl_reserved_quantity_tbl               pl_reserved_quantity_tbl;
  gt_pl_auto_res_class_tbl                  pl_auto_reserve_class_tbl;
  gt_pl_delete_flag_tbl                     pl_delete_flag_tbl;
  gt_pl_warning_class_tbl                   pl_warning_class_tbl;
  gt_pl_warning_date_tbl                    pl_warning_date_tbl;
  gt_pl_line_description_tbl                pl_line_description_tbl;
  gt_pl_rm_if_flg_tbl                       pl_rm_if_flg_tbl;
  gt_pl_ship_req_if_flg_tbl                 pl_shipping_request_if_flg_tbl;
  gt_pl_ship_res_if_flg_tbl                 pl_shipping_result_if_flg_tbl;
  gt_pl_created_by_tbl                      pl_created_by_tbl;
  gt_pl_creation_date_tbl                   pl_creation_date_tbl;
  gt_pl_last_updated_by_tbl                 pl_last_updated_by_tbl;
  gt_pl_last_update_date_tbl                pl_last_update_date_tbl;
  gt_pl_last_update_login_tbl               pl_last_update_login_tbl;
  gt_pl_request_id_tbl                      pl_request_id_tbl;
  gt_pl_program_appli_id_tbl                pl_program_application_id_tbl;
  gt_pl_program_id_tbl                      pl_program_id_tbl;
  gt_pl_program_update_date_tbl             pl_program_update_date_tbl;
--
-- 2008/07/17 v1.3 Start
  -- ヘッダデータダンプ用PL/SQL表
  normal_h_dump_tab           msg_h_ttype;    -- 正常
  -- 明細データダンプ用PL/SQL表
  normal_l_dump_tab           msg_l_ttype;    -- 正常
--
  -- PL/SQL表カウント
  gn_h_cnt                  NUMBER := 0;  -- 正常エラーメッセージPL/SQ表 ヘッダカウント
  gn_l_cnt                  NUMBER := 0;  -- 正常エラーメッセージPL/SQ表 明細カウント
--
-- 2008/07/17 v1.3 End
  gd_sysdate                DATE;             -- システム日付
  gn_user_id                NUMBER;           -- ユーザID
  gn_login_id               NUMBER;           -- 最終更新ログイン
  gn_conc_request_id        NUMBER;           -- 要求ID
  gn_prog_appl_id           NUMBER;           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
  gv_before_item_no         VARCHAR2(7);      -- 前明細品目
  gd_standard_date          DATE;             -- 適用日
--
  -- カウント変数
  gn_i                      NUMBER;           -- ヘッダカウント変数
  gn_j                      NUMBER;           -- 明細カウント変数
--
  -- プロファイル
  gv_master_org_prf         VARCHAR2(100);    -- プロファイル「マスタ組織」
  gv_price_list_prf         VARCHAR2(100);    -- プロファイル「代表価格表」
  gv_item_div_prf           VARCHAR2(100);    -- プロファイル「商品区分(セキュリティ)」
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理 (F-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    lv_master_org_prf_name   CONSTANT VARCHAR2(100) := 'マスタ組織';
    lv_price_list_prf_name   CONSTANT VARCHAR2(100) := '代表価格表';
    lv_item_div_prf_name     CONSTANT VARCHAR2(100) := '商品区分';
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- コンカレント・プログラムID
--
    -- プロファイル「マスタ組織」取得
    gv_master_org_prf := FND_PROFILE.VALUE(gv_master_org_id);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_master_org_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_master_org_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル「代表価格表」取得
    gv_price_list_prf := FND_PROFILE.VALUE(gv_price_list_id);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_price_list_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_price_list_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイル「商品区分」取得
    gv_item_div_prf   := FND_PROFILE.VALUE(gv_item_div_id);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_item_div_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_item_div_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_header_proc
   * Description      : ヘッダデータ取得処理 (F-2)
   ***********************************************************************************/
  PROCEDURE get_header_proc(
    iv_data_class     IN         VARCHAR2,      -- 1.データ種別
    iv_trans_type     IN         VARCHAR2,      -- 2.発生区分
    iv_req_dept       IN         VARCHAR2,      -- 3.依頼部署
    iv_vendor         IN         VARCHAR2,      -- 4.取引先
    iv_ship_to        IN         VARCHAR2,      -- 5.配送先
    iv_arvl_time_from IN         VARCHAR2,      -- 6.入庫日FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.入庫日TO
    iv_security_class IN         VARCHAR2,      -- 8.セキュリティ区分
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_header_proc'; -- プログラム名
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
    -- セキュリティ区分
    cv_sec_itoen  CONSTANT VARCHAR2(100) := '1'; -- 伊藤園ユーザータイプ
    cv_sec_vendor CONSTANT VARCHAR2(100) := '2'; -- 取引先ユーザータイプ
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  srhi.supply_req_headers_if_id,    -- 支給依頼情報インタフェースヘッダID
            srhi.trans_type,                  -- 発生区分
            srhi.weight_capacity_class,       -- 重量容積区分
            srhi.requested_department_code,   -- 依頼部署コード
            srhi.instruction_post_code,       -- 指示部署コード
            srhi.vendor_code,                 -- 取引先コード
            srhi.ship_to_code,                -- 配送先コード
            srhi.shipped_locat_code,          -- 出庫倉庫コード
            srhi.freight_carrier_code,        -- 運送業者コード
            srhi.ship_date,                   -- 出庫日
            srhi.arvl_date,                   -- 入庫日
            srhi.freight_charge_class,        -- 運賃区分
            srhi.takeback_class,              -- 引取区分
            srhi.arrival_time_from,           -- 着荷時間FROM
            srhi.arrival_time_to,             -- 着荷時間TO
            srhi.product_date,                -- 製造日
            srhi.producted_item_code,         -- 製造品目コード
            srhi.product_number,              -- 製造番号
            srhi.header_description,          -- ヘッダ摘要
            NULL,                             -- 合計重量
            NULL,                             -- 合計容積
            NULL,                             -- 小口個数
            NULL,                             -- ラベル枚数
-- 2008/07/17 v1.3 Start
--            NULL                              -- 合計数量
            NULL,                             -- 合計数量
            TO_CHAR(srhi.trans_type)                            || gv_msg_comma ||
            srhi.weight_capacity_class                          || gv_msg_comma ||
            srhi.requested_department_code                      || gv_msg_comma ||
            srhi.instruction_post_code                          || gv_msg_comma ||
            srhi.vendor_code                                    || gv_msg_comma ||
            srhi.ship_to_code                                   || gv_msg_comma ||
            srhi.shipped_locat_code                             || gv_msg_comma ||
            srhi.freight_carrier_code                           || gv_msg_comma ||
            TO_CHAR(srhi.ship_date, 'YYYY/MM/DD HH24:MI:SS')    || gv_msg_comma ||
            TO_CHAR(srhi.arvl_date, 'YYYY/MM/DD HH24:MI:SS')    || gv_msg_comma ||
            srhi.freight_charge_class                           || gv_msg_comma ||
            srhi.takeback_class                                 || gv_msg_comma ||
            srhi.arrival_time_from                              || gv_msg_comma ||
            srhi.arrival_time_to                                || gv_msg_comma ||
            TO_CHAR(srhi.product_date, 'YYYY/MM/DD HH24:MI:SS') || gv_msg_comma ||
            srhi.producted_item_code                            || gv_msg_comma ||
            srhi.product_number                                 || gv_msg_comma ||
            srhi.header_description           -- データダンプ
-- 2008/07/17 v1.3 End
    BULK COLLECT INTO
            gt_sup_req_headers_if_id_tbl,
            gt_trans_type_tbl,
            gt_weight_capacity_class_tbl,
            gt_req_department_code_tbl,
            gt_instruction_post_code_tbl,
            gt_vendor_code_tbl,
            gt_ship_to_code_tbl,
            gt_shipped_locat_code_tbl,
            gt_freight_carrier_code_tbl,
            gt_ship_date_tbl,
            gt_arvl_date_tbl,
            gt_freight_charge_class_tbl,
            gt_takeback_class_tbl,
            gt_arrival_time_from_tbl,
            gt_arrival_time_to_tbl,
            gt_product_date_tbl,
            gt_producted_item_code_tbl,
            gt_product_number_tbl,
            gt_header_description_tbl,
            gt_h_sum_weight_tbl,
            gt_h_sum_capacity_tbl,
            gt_small_quantity_tbl,
            gt_label_quantity_tbl,
-- 2008/07/17 v1.3 Start
--            gt_sum_quantity_tbl
            gt_sum_quantity_tbl,
            gt_lr_h_data_dump_tbl
-- 2008/07/17 v1.3 End
    FROM    xxpo_supply_req_headers_if    srhi
    WHERE   srhi.data_class                 =   iv_data_class
    AND     srhi.trans_type                 =   iv_trans_type
    AND     srhi.requested_department_code  =   NVL(iv_req_dept,srhi.requested_department_code)
    AND     srhi.vendor_code                =   iv_vendor
    AND     srhi.ship_to_code               =   NVL(iv_ship_to,srhi.ship_to_code)
    AND     srhi.arvl_date                  >=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_from, 'YYYY/MM/DD HH24:MI:SS')
    AND     srhi.arvl_date                  <=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_to, 'YYYY/MM/DD HH24:MI:SS')
    AND     (
              (iv_security_class            =   cv_sec_itoen)
              OR
              (
                (iv_security_class          =   cv_sec_vendor)
                  AND srhi.vendor_code in
                    (SELECT papf.attribute4   vendor_code             -- 取引先コード(仕入先コード)
                    FROM    fnd_user          fu,                             -- ユーザーマスタ
                            per_all_people_f  papf                            -- 従業員マスタ
                    WHERE   -- ** 結合条件 ** --
                            fu.employee_id   = papf.person_id                 -- 従業員ID
                            -- ** 抽出条件 ** --
                    AND     papf.effective_start_date <= TRUNC(gd_sysdate)    -- 適用開始日
                    AND     papf.effective_end_date   >= TRUNC(gd_sysdate)    -- 適用終了日
                    AND     fu.start_date             <= TRUNC(gd_sysdate)    -- 適用開始日
                    AND     (
                              (fu.end_date            IS NULL)                -- 適用終了日
                              OR
                              (fu.end_date            >= TRUNC(gd_sysdate))
                            )
                    AND     fu.user_id                 = FND_GLOBAL.USER_ID)  -- ユーザーID
              )
            )
    ORDER BY srhi.supply_req_headers_if_id
    FOR UPDATE NOWAIT;
--
    -- 処理件数(ヘッダ)カウント
    gn_h_target_cnt := gt_sup_req_headers_if_id_tbl.COUNT;
--
    -- データ取得エラー
    IF (gt_sup_req_headers_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_data);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロックエラー
    WHEN check_lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_lock,
                                            gv_tkn_table,
                                            gv_srhi_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_line_proc
   * Description      : 明細データ取得処理 (F-3)
   ***********************************************************************************/
  PROCEDURE get_line_proc(
    iv_data_class     IN         VARCHAR2,      -- 1.データ種別
    iv_trans_type     IN         VARCHAR2,      -- 2.発生区分
    iv_req_dept       IN         VARCHAR2,      -- 3.依頼部署
    iv_vendor         IN         VARCHAR2,      -- 4.取引先
    iv_ship_to        IN         VARCHAR2,      -- 5.配送先
    iv_arvl_time_from IN         VARCHAR2,      -- 6.入庫日FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.入庫日TO
    iv_security_class IN         VARCHAR2,      -- 8.セキュリティ区分
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_line_proc'; -- プログラム名
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
    -- セキュリティ区分
    cv_sec_itoen  CONSTANT VARCHAR2(100) := '1'; -- 伊藤園ユーザータイプ
    cv_sec_vendor CONSTANT VARCHAR2(100) := '2'; -- 取引先ユーザータイプ
--
    -- *** ローカル変数 ***
    -- プロファイル
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT  srli.supply_req_lines_if_id,      -- 支給依頼情報インタフェース明細ID
            srli.item_code,                   -- 品目コード
            srli.futai_code,                  -- 付帯
            srli.request_qty,                 -- 依頼数量
            srli.line_description,            -- 明細摘要
-- 2008/07/17 v1.3 Start
--            srli.supply_req_headers_if_id     -- ヘッダID
            srli.supply_req_headers_if_id,    -- ヘッダID
            srli.corporation_name      || gv_msg_comma ||
            srli.data_class            || gv_msg_comma ||
            srli.transfer_branch_no    || gv_msg_comma ||
            TO_CHAR(srli.line_number)  || gv_msg_comma ||
            srli.item_code             || gv_msg_comma ||
            srli.futai_code            || gv_msg_comma ||
            TO_CHAR(srli.request_qty)  || gv_msg_comma ||
            srli.line_description             -- データダンプ
-- 2008/07/17 v1.3 End
    BULK COLLECT INTO
            gt_supply_req_lines_if_id_tbl,
            gt_item_code_tbl,
            gt_futai_code_tbl,
            gt_request_qty_tbl,
            gt_line_description_tbl,
-- 2008/07/17 v1.3 Start
--            gt_line_headers_id_tbl
            gt_line_headers_id_tbl,
            gt_lr_l_data_dump_tbl
-- 2008/07/17 v1.3 End
    FROM    xxpo_supply_req_headers_if  srhi,
            xxpo_supply_req_lines_if    srli
    WHERE   srhi.supply_req_headers_if_id   =   srli.supply_req_headers_if_id
    AND     srhi.data_class                 =   iv_data_class
    AND     srhi.trans_type                 =   iv_trans_type
    AND     srhi.requested_department_code  =   NVL(iv_req_dept,srhi.requested_department_code)
    AND     srhi.vendor_code                =   iv_vendor
    AND     srhi.ship_to_code               =   NVL(iv_ship_to,srhi.ship_to_code)
    AND     srhi.arvl_date                  >=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_from, 'YYYY/MM/DD HH24:MI:SS')
    AND     srhi.arvl_date                  <=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_to, 'YYYY/MM/DD HH24:MI:SS')
    AND     (
              (iv_security_class            =   cv_sec_itoen)
              OR
              (
                (iv_security_class          =   cv_sec_vendor)
                  AND srhi.vendor_code in
                    (SELECT papf.attribute4   vendor_code             -- 取引先コード(仕入先コード)
                    FROM    fnd_user          fu,                             -- ユーザーマスタ
                            per_all_people_f  papf                            -- 従業員マスタ
                    WHERE   -- ** 結合条件 ** --
                            fu.employee_id   = papf.person_id                 -- 従業員ID
                            -- ** 抽出条件 ** --
                    AND     papf.effective_start_date <= TRUNC(gd_sysdate)    -- 適用開始日
                    AND     papf.effective_end_date   >= TRUNC(gd_sysdate)    -- 適用終了日
                    AND     fu.start_date             <= TRUNC(gd_sysdate)    -- 適用開始日
                    AND     (
                              (fu.end_date            IS NULL)                -- 適用終了日
                              OR
                              (fu.end_date            >= TRUNC(gd_sysdate))
                            )
                    AND     fu.user_id                 = FND_GLOBAL.USER_ID)  -- ユーザーID
              )
            )
    ORDER BY srli.supply_req_headers_if_id, srli.item_code
    FOR UPDATE OF srli.supply_req_lines_if_id NOWAIT;
--
    -- 処理件数(明細)カウント
    gn_l_target_cnt := gt_supply_req_lines_if_id_tbl.COUNT;
--
    -- データ取得エラー
    IF (gt_supply_req_lines_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_data);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- ロックエラー
    WHEN check_lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_lock,
                                            gv_tkn_table,
                                            gv_srli_name);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_line_proc;
--
-- 2008/07/17 v1.3 Start
  /**********************************************************************************
   * Procedure Name   : chk_essent_proc
   * Description      : 必須チェック処理 (F-4)
   ***********************************************************************************/
/*  PROCEDURE chk_essent_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   ヘッダ明細区分
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_essent_proc'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ヘッダ項目
    IF (iv_header_line_kbn = gv_header) THEN
      -- 下記項目がNULLの場合、エラー
      IF (
           (gt_trans_type_tbl(gn_i) IS NULL) OR                    -- ヘッダ｢発生区分｣
           (gt_weight_capacity_class_tbl(gn_i) IS NULL) OR         -- ヘッダ｢重量容積区分｣
           (gt_req_department_code_tbl(gn_i) IS NULL) OR           -- ヘッダ｢依頼部署コード｣
           (gt_vendor_code_tbl(gn_i) IS NULL) OR                   -- ヘッダ｢取引先コード｣
           (gt_ship_to_code_tbl(gn_i) IS NULL) OR                  -- ヘッダ｢配送先コード｣
           (gt_shipped_locat_code_tbl(gn_i) IS NULL) OR            -- ヘッダ｢出庫倉庫コード｣
           (gt_arvl_date_tbl(gn_i) IS NULL) OR                     -- ヘッダ｢入庫日｣
           (
             -- 運賃区分が｢対象｣の場合
             (gt_freight_charge_class_tbl(gn_i) = gv_object) AND
               (gt_freight_carrier_code_tbl(gn_i) IS NULL)         -- ヘッダ｢運送業者コード｣
           )
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_essent);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 明細項目
    ELSIF (iv_header_line_kbn = gv_line) THEN
      -- 下記項目がNULLの場合、エラー
      IF (
           (gt_item_code_tbl(gn_j) IS NULL) OR                       -- 明細｢品目コード｣
           (gt_request_qty_tbl(gn_j) IS NULL)                        -- 明細｢依頼数量｣
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_essent);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_essent_proc;
*/--
-- 2008/07/17 v1.3 End
  /**********************************************************************************
   * Procedure Name   : chk_exist_mst_proc
   * Description      : マスタ存在チェック処理 (F-5)
   ***********************************************************************************/
  PROCEDURE chk_exist_mst_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   ヘッダ明細区分
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exist_mst_proc'; -- プログラム名
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
    -- テーブル(ビュー)名
    cv_xvv            CONSTANT VARCHAR2(100) := '仕入先情報VIEW';
    cv_xvsv           CONSTANT VARCHAR2(100) := '仕入先サイト情報VIEW';
    cv_xilv           CONSTANT VARCHAR2(100) := 'OPM保管場所情報VIEW';
    cv_xcv            CONSTANT VARCHAR2(100) := '運送業者情報VIEW';
    cv_ximv           CONSTANT VARCHAR2(100) := 'OPM品目情報VIEW';
--
    cv_trans_pay      CONSTANT VARCHAR2(1)   := '2';                    -- 発生区分｢仕入有償｣
    cn_lot_ctl        CONSTANT NUMBER(5,0)   := 1;                      -- 管理対象
--
    -- *** ローカル変数 ***
    lv_close_period   VARCHAR2(100);              -- 在庫会計期間クローズ日付
    ln_cnt            NUMBER;                     -- 存在カウント
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
    lv_close_period   := NULL;
    ln_cnt            := 0;
--
    -- ヘッダ項目
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- ヘッダ項目存在チェック                  --
      ---------------------------------------------
-- 2008/07/17 v1.3 Start
      -- ｢重量容積区分｣
      --カウント変数初期化
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_weight_capacity
      AND     lookup_code = gt_weight_capacity_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_weight_capacity);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ｢依頼部署コード｣
      --カウント変数初期化
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_locations_v   xlv
      WHERE   xlv.location_code   = gt_req_department_code_tbl(gn_i)
      AND     ROWNUM              = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_req_department);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ｢指示部署コード｣
--
      IF (gt_instruction_post_code_tbl(gn_i) IS NOT NULL) THEN
        --カウント変数初期化
        ln_cnt := 0; 
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_locations_v   xlv
        WHERE   xlv.location_code   = gt_instruction_post_code_tbl(gn_i)
        AND     ROWNUM              = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_instruction_post);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ｢運賃区分｣
      --カウント変数初期化
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_freight_class
      AND     lookup_code = gt_freight_charge_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_freight_charge_class);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ｢着荷時間FROM｣
      IF (gt_arrival_time_from_tbl(gn_i) IS NOT NULL) THEN
        --カウント変数初期化
        ln_cnt := 0; 
--
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_lookup_values_v 
        WHERE   lookup_type = gv_lup_arrival_time
        AND     lookup_code = gt_arrival_time_from_tbl(gn_i)
        AND     ROWNUM      = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_arrival_time_from);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ｢着荷時間TO｣
      IF (gt_arrival_time_to_tbl(gn_i) IS NOT NULL) THEN
        --カウント変数初期化
        ln_cnt := 0; 
--
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_lookup_values_v 
        WHERE   lookup_type = gv_lup_arrival_time
        AND     lookup_code = gt_arrival_time_to_tbl(gn_i)
        AND     ROWNUM      = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_arrival_time_to);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ｢引取区分｣
      --カウント変数初期化
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_takeback_class
      AND     lookup_code = gt_takeback_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_takeback_class);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
-- 2008/07/17 v1.3 End
      -- ｢取引先コード｣
      BEGIN
        SELECT  xvv.vendor_id,                -- 仕入先ID
                xvv.customer_num,             -- 顧客番号
                xcav.party_id,                -- パーティID
                xvv.spare2,                   -- 価格表
                xcav.cust_account_id          -- 顧客ID
        INTO    gt_vendor_id_tbl(gn_i),
                gt_customer_num_tbl(gn_i),
                gt_cust_party_id_tbl(gn_i),
                gt_spare2_tbl(gn_i),
                gt_cust_account_id_tbl(gn_i)
        FROM    xxcmn_vendors2_v        xvv,  -- 仕入先情報VIEW
                xxcmn_cust_accounts2_v  xcav  -- 顧客情報VIEW
        WHERE   xvv.segment1            =  gt_vendor_code_tbl(gn_i)
        AND     xvv.customer_num        =  xcav.account_number
        AND     xvv.start_date_active   <= gd_standard_date
        AND     xvv.end_date_active     >= gd_standard_date
        AND     xcav.start_date_active  <= gd_standard_date
        AND     xcav.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xvv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ｢配送先コード｣
      BEGIN
        SELECT  xvsv.vendor_site_id           -- 仕入先サイトID
        INTO    gt_vendor_site_id_tbl(gn_i)
        FROM    xxcmn_vendor_sites2_v   xvsv  -- 仕入先サイト情報VIEW
        WHERE   xvsv.vendor_site_code   =  gt_ship_to_code_tbl(gn_i)
        AND     xvsv.vendor_id          =  gt_vendor_id_tbl(gn_i)
        AND     xvsv.start_date_active  <= gd_standard_date
        AND     xvsv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xvsv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ｢出庫倉庫コード｣
      BEGIN
        SELECT  xilv.inventory_location_id,   -- 倉庫ID
                xilv.leaf_calender,           -- リーフ基準カレンダ
                xilv.drink_calender           -- ドリンク基準カレンダ
        INTO    gt_inventory_location_id_tbl(gn_i),
                gt_leaf_calender_tbl(gn_i),
                gt_drink_calender_tbl(gn_i)
        FROM    xxcmn_item_locations2_v   xilv  -- OPM保管場所情報VIEW
        WHERE   xilv.segment1             =  gt_shipped_locat_code_tbl(gn_i)
        AND     xilv.date_from            <= gd_standard_date
        AND     (
                  (xilv.date_to >= gd_standard_date)
                  OR
                  (xilv.date_to IS NULL)
                );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xilv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ｢運送業者コード｣
      -- 入力されている場合
      IF (gt_freight_carrier_code_tbl(gn_i) IS NOT NULL) THEN
        BEGIN
          SELECT  xcv.party_id                  -- パーティID
          INTO    gt_carriers_party_id_tbl(gn_i)
          FROM    xxcmn_carriers2_v       xcv   -- 運送業者情報VIEW
          WHERE   xcv.party_number        =  gt_freight_carrier_code_tbl(gn_i)
          AND     xcv.start_date_active   <= gd_standard_date
          AND     xcv.end_date_active     >= gd_standard_date;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                  gv_msg_exist,
                                                  gv_tkn_table,
                                                  cv_xcv);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
        END;
--
      END IF;
--
      -- ｢製造品目コード｣
      BEGIN
        SELECT  ximv.item_id                  -- 品目ID
        INTO    gt_h_item_id_tbl(gn_i)
        FROM    xxcmn_item_mst2_v       ximv  -- OPM品目情報VIEW
        WHERE   ximv.item_no            =  gt_producted_item_code_tbl(gn_i)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      ---------------------------------------------
      -- 在庫会計期間クローズチェック            --
      ---------------------------------------------
      -- 共通関数｢OPM在庫会計期間CLOSE年月取得関数｣呼び出し
      lv_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
      -- 共通関数でエラーの場合
      IF (lv_close_period IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_opminv_close);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 出庫日がクローズした在庫会計期間年月以前の場合
      IF (TO_CHAR(gt_ship_date_tbl(gn_i), 'YYYYMM') <= lv_close_period) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_close_period);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 明細項目
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- 明細項目存在チェック                    --
      ---------------------------------------------
-- 2008/07/17 v1.3 Start
      -- ｢依頼数量｣
      -- 依頼数量が0もしくはマイナス値の場合
      IF (gt_request_qty_tbl(gn_j) <= 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_request_qty);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
-- 2008/07/17 v1.3 End
      -- ｢品目コード｣
      BEGIN
        SELECT  ximv.item_id,                         -- 品目ID
                ximv.item_um,                         -- 単位
                ximv.num_of_deliver,                  -- 出荷入数
                ximv.conv_unit,                       -- 入出庫換算単位
                ximv.num_of_cases,                    -- ケース入数
                ximv.inventory_item_id,               -- INV品目ID
                ximv.whse_item_id,                    -- 倉庫品目ID
-- 2008/07/17 v1.3 Start
--                ximv.lot_ctl                          -- ロット
                ximv.lot_ctl,                         -- ロット
                ximv.weight_capacity_class            -- 重量容積区分
-- 2008/07/17 v1.3 End
        INTO    gt_l_item_id_tbl(gn_j),
                gt_item_um_tbl(gn_j),
                gt_num_of_deliver_tbl(gn_j),
                gt_conv_unit_tbl(gn_j),
                gt_num_of_cases_tbl(gn_j),
                gt_inventory_item_id_tbl(gn_j),
                gt_whse_item_id_tbl(gn_j),
-- 2008/07/17 v1.3 Start
--                gt_lot_ctl_tbl(gn_j)
                gt_lot_ctl_tbl(gn_j),
                gt_l_weight_capacity_class(gn_j)
-- 2008/07/17 v1.3 End
        FROM    xxcmn_item_mst2_v       ximv
        WHERE   ximv.item_no            =  gt_item_code_tbl(gn_j)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
-- 2008/07/17 v1.3 Start
        -- ヘッダと明細の重量容積区分が異なる場合
        IF (gt_weight_capacity_class_tbl(gn_i) <> gt_l_weight_capacity_class(gn_j)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_weight_capacity_agree);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
-- 2008/07/17 v1.3 End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- 倉庫品目IDに紐付く倉庫品目コードを取得
      BEGIN
        SELECT  ximv.item_no                          -- 倉庫品目コード
        INTO    gt_item_no_tbl(gn_j)
        FROM    xxcmn_item_mst2_v       ximv
        WHERE   ximv.item_id            =  gt_whse_item_id_tbl(gn_j)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      ---------------------------------------------
      -- 品目重複チェック                        --
      ---------------------------------------------
      -- 品目が、1ヘッダに紐付く前明細の品目と重複する場合
      IF (gv_before_item_no IS NOT NULL) THEN
        IF (gv_before_item_no = gt_item_code_tbl(gn_j)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_redundant);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        END IF;
--
      ELSE
        gv_before_item_no := gt_item_code_tbl(gn_j);
--
      END IF;
--
      ---------------------------------------------
      -- 仕入有償時品目チェック                  --
      ---------------------------------------------
      -- 発生区分が｢仕入有償｣の場合
      IF (
           (gt_trans_type_tbl(gn_i) = cv_trans_pay) AND
           (NVL(gt_lot_ctl_tbl(gn_j), 0) = cn_lot_ctl)
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_trans_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_exist_mst_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_relation_proc
   * Description      : 関連データ取得処理 (F-6)
   ***********************************************************************************/
  PROCEDURE get_relation_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   ヘッダ明細区分
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_proc'; -- プログラム名
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
    cv_wh         CONSTANT VARCHAR2(2) := '4';   -- 倉庫
    cv_sup        CONSTANT VARCHAR2(2) := '11';  -- 支給先
    cv_request_no CONSTANT VARCHAR2(1) := '6';   -- 出荷依頼No
    cn_lead_time  CONSTANT NUMBER      := 1;     -- リードタイム
--
    -- *** ローカル変数 ***
    ln_result             NUMBER;               -- 「最大配送区分算出関数」返り値
    ln_unit_price         NUMBER;               -- 「支給単価取得関数」返り値
    lv_errmsg_code        VARCHAR2(5000);       -- エラーメッセージコード
    ln_small_quantity     NUMBER;               -- 小口個数
-- 2008/07/17 v1.3 Start
    ld_oprtn_day          DATE;                 -- 稼働日日付
    ln_return             NUMBER;               -- 「稼働日算出関数」返り値
-- 2008/07/17 v1.3 End
    -- 未使用
    ln_palette_max_qty    NUMBER;               -- パレット最大枚数
    ln_sum_pallet_weight  NUMBER;               -- 合計パレット重量
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
    ln_result         := NULL;
    ln_unit_price     := NULL;
    lv_retcode        := NULL;
    lv_errmsg_code    := NULL;
    lv_errmsg         := NULL;
    ln_small_quantity := NULL;
--
    -- ヘッダ項目
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- 最大配送区分取得                        --
      ---------------------------------------------
      -- 運賃区分が｢対象｣の場合
      IF (gt_freight_charge_class_tbl(gn_i) = gv_object) THEN
        -- 共通関数「最大配送区分算出関数」呼び出し
        ln_result := xxwsh_common_pkg.get_max_ship_method
                               (cv_wh,                                      -- 倉庫'4'
                                gt_shipped_locat_code_tbl(gn_i),            -- 出庫倉庫コード
                                cv_sup,                                     -- 支給先'11'
                                gt_ship_to_code_tbl(gn_i),                  -- 配送先コード
                                gv_item_div_prf,                            -- 商品区分
                                gt_weight_capacity_class_tbl(gn_i),         -- 重量容積区分
                                NULL,                                       -- 自動配車対象区分
                                gd_standard_date,                           -- 出庫日
                                gt_ship_method_tbl(gn_i),                   -- 最大配送区分
                                gt_drink_deadweight_tbl(gn_i),              -- ドリンク積載重量
                                gt_leaf_deadweight_tbl(gn_i),               -- リーフ積載重量
                                gt_drink_loading_capacity_tbl(gn_i),        -- ドリンク積載容積
                                gt_leaf_loading_capacity_tbl(gn_i),         -- リーフ積載容積
                                ln_palette_max_qty                          -- パレット最大枚数
                               );
--
        -- 共通関数でエラーの場合
        IF (ln_result = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_common,
                                                gv_tkn_common_name,
                                                gv_max_ship);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      ELSE
        gt_ship_method_tbl(gn_i)              := NULL;
        gt_drink_deadweight_tbl(gn_i)         := NULL;
        gt_leaf_deadweight_tbl(gn_i)          := NULL;
        gt_drink_loading_capacity_tbl(gn_i)   := NULL;
        gt_leaf_loading_capacity_tbl(gn_i)    := NULL;
--
      END IF;
--
-- 2008/07/17 v1.3 Start
      ---------------------------------------------
      -- 出庫日取得                              --
      ---------------------------------------------
      -- 出庫日が未入力の場合
      IF (gt_ship_date_tbl(gn_i) IS NULL) THEN
        -- 共通関数「稼働日算出関数」呼び出し
        ln_return := xxwsh_common_pkg.get_oprtn_day
                      (gt_arvl_date_tbl(gn_i),          -- 入庫日
                       NULL,                            -- 保管倉庫コード
                       gt_ship_to_code_tbl(gn_i),       -- 配送先コード
                       cn_lead_time,                    -- リードタイム｢1｣
                       gv_item_div_prf,                 -- 商品区分
                       ld_oprtn_day                     -- 稼働日日付
                      );
--
        -- 共通関数でエラーの場合
        IF (ln_return = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_common,
                                                gv_tkn_common_name,
                                                gv_oprtn_day);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- 取得した日付を出荷日として保持
        gt_ship_date_tbl(gn_i) := ld_oprtn_day;
--
      -- 出庫日が入力されている場合
      ELSE
        -- 出庫日が入庫日よりも未来日の場合
        IF (gt_ship_date_tbl(gn_i) > gt_arvl_date_tbl(gn_i)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_ship_date);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
-- 2008/07/17 v1.3 End
      ---------------------------------------------
      -- 依頼No取得                              --
      ---------------------------------------------
      -- 共通関数「採番関数」呼び出し
      xxcmn_common_pkg.get_seq_no
                        (cv_request_no,                 -- 採番番号区分
                         gt_seq_no_tbl(gn_i),           -- 出荷依頼No
                         lv_errbuf,                     -- エラー・メッセージ
                         lv_retcode,                    -- リターン・コード
                         lv_errmsg                      -- ユーザー・エラー・メッセージ
                        );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
-- 2008/07/24 v1.4 Start
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_get_seq_no);
        lv_errbuf := lv_errmsg;
-- 2008/07/24 v1.4 End
        RAISE global_api_expt;
      END IF;
--
    -- 明細項目
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- 単価取得                                --
      ---------------------------------------------
      -- 共通関数「支給単価取得関数」呼び出し
      ln_unit_price  := xxpo_common2_pkg.get_unit_price
                               (gt_inventory_item_id_tbl(gn_j),     -- INV品目ID
                                gt_spare2_tbl(gn_i),                -- 取引先別価格表ID
                                gv_price_list_prf,                  -- 代表価格表ID
                                gt_arvl_date_tbl(gn_i)              -- 適用日(入庫日)
                               );
--
      -- 共通関数でエラーの場合
      IF (ln_unit_price IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_unit_price);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        gt_unit_price_tbl(gn_j) := ln_unit_price;
      END IF;
--
      ---------------------------------------------
      -- 合計重量･合計容積取得                   --
      ---------------------------------------------
      -- 「積載効率チェック(合計値算出)」呼び出し
      xxwsh_common910_pkg.calc_total_value
                            (
                             gt_item_code_tbl(gn_j),              -- 品目コード
                             gt_request_qty_tbl(gn_j),            -- 依頼数量
                             lv_retcode,                          -- リターンコード
                             lv_errmsg_code,                      -- エラーメッセージコード
                             lv_errmsg,                           -- エラーメッセージ
                             gt_l_sum_weight_tbl(gn_j),           -- 合計重量
                             gt_l_sum_capacity_tbl(gn_j),         -- 合計容積
                             ln_sum_pallet_weight                 -- 合計パレット重量
                            );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
-- 2008/07/24 v1.4 Start
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_calc_total_value);
        lv_errbuf := lv_errmsg;
-- 2008/07/24 v1.4 End
        RAISE global_api_expt;
      END IF;
--
      -- 総合計重量
      gt_h_sum_weight_tbl(gn_i) :=
        NVL(gt_h_sum_weight_tbl(gn_i), 0) + gt_l_sum_weight_tbl(gn_j);
--
      -- 総合計容積
      gt_h_sum_capacity_tbl(gn_i) :=
        NVL(gt_h_sum_capacity_tbl(gn_i), 0) + gt_l_sum_capacity_tbl(gn_j);
--
      ---------------------------------------------
      -- 配車関連情報の算出                      --
      ---------------------------------------------
      -- 小口個数
-- 2008/07/24 v1.4 Start
/*      -- 入出庫換算単位が設定されていて、ケース入数がNULL若しくは0でない場合
      IF (
           (gt_conv_unit_tbl(gn_j) IS NOT NULL) AND
           (gt_num_of_cases_tbl(gn_j) IS NOT NULL) AND
           (gt_num_of_cases_tbl(gn_j) <> '0')
         ) THEN
        ln_small_quantity :=
          ROUND(TO_NUMBER(gt_request_qty_tbl(gn_j) / gt_num_of_cases_tbl(gn_j)));
      ELSE
        ln_small_quantity := gt_request_qty_tbl(gn_j);
      END IF;
*/--
      -- 入出庫換算単位がNULLでない場合
      IF (gt_conv_unit_tbl(gn_j) IS NOT NULL) THEN
        -- ケース入り数が0より大きい場合
        IF (gt_num_of_cases_tbl(gn_j) > 0) THEN
          -- ケース入り数を加味した換算を行う。
          ln_small_quantity
            := CEIL(TO_NUMBER(gt_request_qty_tbl(gn_j) / gt_num_of_cases_tbl(gn_j)));
        ELSIF ((gt_num_of_cases_tbl(gn_j) = 0)
           OR (gt_num_of_cases_tbl(gn_j) IS NULL)) THEN
          -- エラーメッセージ取得
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_msg_kbn_xxcmn    -- モジュール名略称:XXCMN
                           ,gv_msg_xxcmn10604   -- メッセージ:APP-XXCMN-10604 ケース入数エラー
                           ,gv_tkn_request_no
                           ,gt_seq_no_tbl(gn_i)
                           ,gv_tkn_item_no
                           ,gt_item_code_tbl(gn_j))
                           ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE
        ln_small_quantity := gt_request_qty_tbl(gn_j);
      END IF;
-- 2008/07/24 v1.4 End
      gt_small_quantity_tbl(gn_i) :=
        NVL(gt_small_quantity_tbl(gn_i), 0) + ln_small_quantity;
--
      -- ラベル枚数
      gt_label_quantity_tbl(gn_i) :=
       NVL(gt_label_quantity_tbl(gn_i), 0) + ln_small_quantity;
--
      -- 合計数量
      gt_sum_quantity_tbl(gn_i) :=
       NVL(gt_sum_quantity_tbl(gn_i), 0) + gt_request_qty_tbl(gn_j);
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_relation_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : 登録データ設定処理
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   ヘッダ明細区分
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- プログラム名
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
    cv_yes                CONSTANT VARCHAR2(1) := 'Y';      -- ON
    cv_no                 CONSTANT VARCHAR2(1) := 'N';      -- OFF
    cv_transaction_status CONSTANT VARCHAR2(2) := '06';     -- 入力完了
    cv_notif_status       CONSTANT VARCHAR2(2) := '10';     -- 未通知
-- 2008/07/17 v1.3 Start
--    cv_out_object         CONSTANT VARCHAR2(1) := '2';      -- 対象外
-- 2008/07/17 v1.3 End

--
    -- *** ローカル変数 ***
    lv_trans_type          VARCHAR2(80);           -- 発生区分名
    ln_transaction_type_id NUMBER;                 -- 受注タイプID
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
    lv_trans_type           := NULL;
    ln_transaction_type_id  := NULL;
--
    -- ヘッダ項目
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- ヘッダ設定                              --
      ---------------------------------------------
      BEGIN
        -- クイックコードより発生区分名を取得する。
        SELECT    xlvv.meaning
        INTO      lv_trans_type
        FROM      xxcmn_lookup_values2_v   xlvv
        WHERE     xlvv.lookup_type        = 'XXPO_TRANS_TYPE'
        AND       xlvv.lookup_code        = gt_trans_type_tbl(gn_i)
        AND       (
                    (xlvv.start_date_active <= TRUNC(gd_standard_date))
                    OR
                    (xlvv.start_date_active IS NULL )
                  )
        AND       (
                    (xlvv.end_date_active >= TRUNC(gd_standard_date))
                    OR
                    (xlvv.end_date_active IS NULL )
                  );
--
        -- 受注タイプより受注タイプIDを取得する。
        SELECT    ottv.transaction_type_id
        INTO      ln_transaction_type_id
        FROM      xxwsh_oe_transaction_types2_v   ottv
        WHERE     ottv.transaction_type_name      =  lv_trans_type
        AND       ottv.start_date_active          <= TRUNC(gd_standard_date)
        AND       NVL(ottv.end_date_active, TO_DATE('99991231', 'YYYYMMDD')) >=
                    TRUNC(gd_standard_date);
--
      EXCEPTION
        -- データ取得エラー
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_get_data);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- 受注ヘッダアドオンテーブルへ登録するレコードへ値をセット
      gt_ph_order_header_id_tbl(gn_i)               :=  gt_order_header_id_tbl(gn_i);
      gt_ph_order_type_id_tbl(gn_i)                 :=  ln_transaction_type_id;
      gt_ph_organization_id_tbl(gn_i)               :=  gv_master_org_prf;
      gt_ph_header_id_tbl(gn_i)                     :=  NULL;
      gt_ph_latest_external_flag_tbl(gn_i)          :=  cv_yes;
      gt_ph_ordered_date_tbl(gn_i)                  :=  gd_sysdate;
      gt_ph_customer_id_tbl(gn_i)                   :=  gt_cust_account_id_tbl(gn_i);
      gt_ph_customer_code_tbl(gn_i)                 :=  gt_customer_num_tbl(gn_i);
      gt_ph_deliver_to_id_tbl(gn_i)                 :=  NULL;
      gt_ph_deliver_to_tbl(gn_i)                    :=  NULL;
      gt_ph_shipping_inst_tbl(gn_i)                 :=  gt_header_description_tbl(gn_i);
      gt_ph_career_id_tbl(gn_i)                     :=  gt_carriers_party_id_tbl(gn_i);
      gt_ph_freight_carrier_code_tbl(gn_i)          :=  gt_freight_carrier_code_tbl(gn_i);
      gt_ph_shipping_method_code_tbl(gn_i)          :=  gt_ship_method_tbl(gn_i);
      gt_ph_cust_po_number_tbl(gn_i)                :=  NULL;
      gt_ph_price_list_id_tbl(gn_i)                 :=  NULL;
      gt_ph_request_no_tbl(gn_i)                    :=  gt_seq_no_tbl(gn_i);
      gt_ph_base_request_no_tbl(gn_i)               :=  NULL;
      gt_ph_req_status_tbl(gn_i)                    :=  cv_transaction_status;
      gt_ph_delivery_no_tbl(gn_i)                   :=  NULL;
      gt_ph_prev_delivery_no_tbl(gn_i)              :=  NULL;
      gt_ph_schedule_ship_date_tbl(gn_i)            :=  gt_ship_date_tbl(gn_i);
      gt_ph_schedule_arr_date_tbl(gn_i)             :=  gt_arvl_date_tbl(gn_i);
      gt_ph_mixed_no_tbl(gn_i)                      :=  NULL;
      gt_ph_collected_pallet_qty_tbl(gn_i)          :=  NULL;
      gt_ph_confirm_req_class_tbl(gn_i)             :=  NULL;
-- 2008/07/17 v1.3 Start
--      gt_ph_freight_charge_class_tbl(gn_i)          :=
--        NVL(gt_freight_charge_class_tbl(gn_i), cv_out_object);
      gt_ph_freight_charge_class_tbl(gn_i)          :=  gt_freight_charge_class_tbl(gn_i);
-- 2008/07/17 v1.3 End
      gt_ph_shikyu_inst_class_tbl(gn_i)             :=  NULL;
      gt_ph_sk_inst_rcv_class_tbl(gn_i)             :=  NULL;
      gt_ph_amount_fix_class_tbl(gn_i)              :=  NULL;
      gt_ph_takeback_class_tbl(gn_i)                :=  gt_takeback_class_tbl(gn_i);
      gt_ph_deliver_from_id_tbl(gn_i)               :=  gt_inventory_location_id_tbl(gn_i);
      gt_ph_deliver_from_tbl(gn_i)                  :=  gt_shipped_locat_code_tbl(gn_i);
      gt_ph_head_sales_branch_tbl(gn_i)             :=  NULL;
      gt_ph_input_sales_branch_tbl(gn_i)            :=  NULL;
      gt_ph_po_no_tbl(gn_i)                         :=  NULL;
      gt_ph_prod_class_tbl(gn_i)                    :=  gv_item_div_prf;
      gt_ph_item_class_tbl(gn_i)                    :=  NULL;
      gt_ph_no_cont_fre_class_tbl(gn_i)             :=  NULL;
      gt_ph_arrival_time_from_tbl(gn_i)             :=  gt_arrival_time_from_tbl(gn_i);
      gt_ph_arrival_time_to_tbl(gn_i)               :=  gt_arrival_time_to_tbl(gn_i);
      gt_ph_designated_item_id_tbl(gn_i)            :=  gt_h_item_id_tbl(gn_i);
      gt_ph_designated_item_code_tbl(gn_i)          :=  gt_producted_item_code_tbl(gn_i);
      gt_ph_designated_prod_date_tbl(gn_i)          :=  gt_product_date_tbl(gn_i);
      gt_ph_designated_branch_no_tbl(gn_i)          :=  gt_product_number_tbl(gn_i);
      gt_ph_slip_number_tbl(gn_i)                   :=  NULL;
      gt_ph_sum_quantity_tbl(gn_i)                  :=  gt_sum_quantity_tbl(gn_i);
      gt_ph_small_quantity_tbl(gn_i)                :=  gt_small_quantity_tbl(gn_i);
      gt_ph_label_quantity_tbl(gn_i)                :=  gt_label_quantity_tbl(gn_i);
      gt_ph_load_efficiency_we_tbl(gn_i)            :=  gt_load_efficiency_we_tbl(gn_i);
      gt_ph_load_efficiency_ca_tbl(gn_i)            :=  gt_load_efficiency_ca_tbl(gn_i);
      -- 重量容積区分が｢重量｣の場合
      IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
        -- 商品区分が｢ドリンク｣の場合
        IF (gv_item_div_prf = gv_drink) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  gt_drink_deadweight_tbl(gn_i);
          gt_ph_based_capacity_tbl(gn_i)            :=  NULL;
        -- 商品区分が｢リーフ｣の場合
        ELSIF (gv_item_div_prf = gv_leaf) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  gt_leaf_deadweight_tbl(gn_i);
          gt_ph_based_capacity_tbl(gn_i)            :=  NULL;
        END IF;
      -- 重量容積区分が｢容積｣の場合
      ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
        -- 商品区分が｢ドリンク｣の場合
        IF (gv_item_div_prf = gv_drink) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  NULL;
          gt_ph_based_capacity_tbl(gn_i)            :=  gt_drink_loading_capacity_tbl(gn_i);
        -- 商品区分が｢リーフ｣の場合
        ELSIF (gv_item_div_prf = gv_leaf) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  NULL;
          gt_ph_based_capacity_tbl(gn_i)            :=  gt_leaf_loading_capacity_tbl(gn_i);
        END IF;
      END IF;
      gt_ph_sum_weight_tbl(gn_i)                    :=  gt_drink_deadweight_tbl(gn_i);
      gt_ph_sum_capacity_tbl(gn_i)                  :=  gt_h_sum_capacity_tbl(gn_i);
      gt_ph_mixed_ratio_tbl(gn_i)                   :=  NULL;
      gt_ph_pallet_sum_quantity_tbl(gn_i)           :=  NULL;
      gt_ph_real_pallet_quantity_tbl(gn_i)          :=  NULL;
      gt_ph_sum_pallet_weight_tbl(gn_i)             :=  NULL;
      gt_ph_order_source_ref_tbl(gn_i)              :=  NULL;
      gt_ph_result_fre_carr_id_tbl(gn_i)            :=  NULL;
      gt_ph_result_fre_carr_code_tbl(gn_i)          :=  NULL;
      gt_ph_res_ship_meth_code_tbl(gn_i)            :=  NULL;
      gt_ph_result_deliver_to_id_tbl(gn_i)          :=  NULL;
      gt_ph_result_deliver_to_tbl(gn_i)             :=  NULL;
      gt_ph_shipped_date_tbl(gn_i)                  :=  NULL;
      gt_ph_arrival_date_tbl(gn_i)                  :=  NULL;
      gt_ph_weight_ca_class_tbl(gn_i)               :=  gt_weight_capacity_class_tbl(gn_i);
      gt_ph_actual_confirm_class_tbl(gn_i)          :=  NULL;
      gt_ph_notif_status_tbl(gn_i)                  :=  cv_notif_status;
      gt_ph_prev_notif_status_tbl(gn_i)             :=  NULL;
      gt_ph_notif_date_tbl(gn_i)                    :=  NULL;
      gt_ph_new_modify_flg_tbl(gn_i)                :=  NULL;
      gt_ph_process_status_tbl(gn_i)                :=  NULL;
      gt_ph_perform_manage_dept_tbl(gn_i)           :=  gt_req_department_code_tbl(gn_i);
      gt_ph_instruction_dept_tbl(gn_i)              :=
        NVL(gt_instruction_post_code_tbl(gn_i), gt_req_department_code_tbl(gn_i));
      gt_ph_transfer_location_id_tbl(gn_i)          :=  NULL;
      gt_ph_trans_location_code_tbl(gn_i)           :=  NULL;
      gt_ph_mixed_sign_tbl(gn_i)                    :=  NULL;
      gt_ph_screen_update_date_tbl(gn_i)            :=  NULL;
      gt_ph_screen_update_by_tbl(gn_i)              :=  NULL;
      gt_ph_tightening_date_tbl(gn_i)               :=  NULL;
      gt_ph_vendor_id_tbl(gn_i)                     :=  gt_vendor_id_tbl(gn_i);
      gt_ph_vendor_code_tbl(gn_i)                   :=  gt_vendor_code_tbl(gn_i);
      gt_ph_vendor_site_id_tbl(gn_i)                :=  gt_vendor_site_id_tbl(gn_i);
      gt_ph_vendor_site_code_tbl(gn_i)              :=  gt_ship_to_code_tbl(gn_i);
      gt_ph_registered_sequence_tbl(gn_i)           :=  NULL;
      gt_ph_tight_program_id_tbl(gn_i)              :=  NULL;
      gt_ph_correct_tight_class_tbl(gn_i)           :=  NULL;
      gt_ph_created_by_tbl(gn_i)                    :=  gn_user_id;
      gt_ph_creation_date_tbl(gn_i)                 :=  gd_sysdate;
      gt_ph_last_updated_by_tbl(gn_i)               :=  gn_user_id;
      gt_ph_last_update_date_tbl(gn_i)              :=  gd_sysdate;
      gt_ph_last_update_login_tbl(gn_i)             :=  gn_login_id;
      gt_ph_request_id_tbl(gn_i)                    :=  gn_conc_request_id;
      gt_ph_program_appli_id_tbl(gn_i)              :=  gn_prog_appl_id;
      gt_ph_program_id_tbl(gn_i)                    :=  gn_conc_program_id;
      gt_ph_program_up_date_tbl(gn_i)               :=  gd_sysdate;
--
    -- 明細項目
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- 明細設定                                --
      ---------------------------------------------
      -- 受注明細アドオンテーブルへ登録するレコードへ値をセット
      gt_pl_order_line_id_tbl(gn_j)                 :=  gt_order_line_id_tbl(gn_j);
      gt_pl_order_header_id_tbl(gn_j)               :=  gt_order_header_id_tbl(gn_i);
      gt_pl_order_line_number_tbl(gn_j)             :=  gt_line_number_tbl(gn_j);
      gt_pl_header_id_tbl(gn_j)                     :=  NULL;
      gt_pl_line_id_tbl(gn_j)                       :=  NULL;
      gt_pl_request_no_tbl(gn_j)                    :=  gt_seq_no_tbl(gn_i);
      gt_pl_ship_inv_item_id_tbl(gn_j)              :=  gt_l_item_id_tbl(gn_j);
      gt_pl_shipping_item_code_tbl(gn_j)            :=  gt_item_code_tbl(gn_j);
      gt_pl_quantity_tbl(gn_j)                      :=  gt_request_qty_tbl(gn_j);
      gt_pl_uom_code_tbl(gn_j)                      :=  gt_item_um_tbl(gn_j);
      gt_pl_unit_price_tbl(gn_j)                    :=  gt_unit_price_tbl(gn_j);
      gt_pl_shipped_quantity_tbl(gn_j)              :=  NULL;
      gt_pl_design_prod_date_tbl(gn_j)              :=  NULL;
      gt_pl_based_req_quan_tbl(gn_j)                :=  gt_request_qty_tbl(gn_j);
      gt_pl_request_item_id_tbl(gn_j)               :=  gt_whse_item_id_tbl(gn_j);
      gt_pl_request_item_code_tbl(gn_j)             :=  gt_item_no_tbl(gn_j);
      gt_pl_ship_to_quantity_tbl(gn_j)              :=  NULL;
      gt_pl_futai_code_tbl(gn_j)                    :=  NVL(gt_futai_code_tbl(gn_j), '0');
      gt_pl_designated_date_tbl(gn_j)               :=  NULL;
      gt_pl_move_number_tbl(gn_j)                   :=  NULL;
      gt_pl_po_number_tbl(gn_j)                     :=  NULL;
      gt_pl_cust_po_number_tbl(gn_j)                :=  NULL;
      gt_pl_pallet_quantity_tbl(gn_j)               :=  NULL;
      gt_pl_layer_quantity_tbl(gn_j)                :=  NULL;
      gt_pl_case_quantity_tbl(gn_j)                 :=  NULL;
      gt_pl_weight_tbl(gn_j)                        :=  gt_l_sum_weight_tbl(gn_j);
      gt_pl_capacity_tbl(gn_j)                      :=  gt_l_sum_capacity_tbl(gn_j);
      gt_pl_pallet_qty_tbl(gn_j)                    :=  NULL;
      gt_pl_pallet_weight_tbl(gn_j)                 :=  NULL;
      gt_pl_reserved_quantity_tbl(gn_j)             :=  NULL;
      gt_pl_auto_res_class_tbl(gn_j)                :=  NULL;
      gt_pl_delete_flag_tbl(gn_j)                   :=  cv_no;
      gt_pl_warning_class_tbl(gn_j)                 :=  NULL;
      gt_pl_warning_date_tbl(gn_j)                  :=  NULL;
      gt_pl_line_description_tbl(gn_j)              :=  gt_line_description_tbl(gn_j);
      gt_pl_rm_if_flg_tbl(gn_j)                     :=  NULL;
      gt_pl_ship_req_if_flg_tbl(gn_j)               :=  NULL;
      gt_pl_ship_res_if_flg_tbl(gn_j)               :=  NULL;
      gt_pl_created_by_tbl(gn_j)                    :=  gn_user_id;
      gt_pl_creation_date_tbl(gn_j)                 :=  gd_sysdate;
      gt_pl_last_updated_by_tbl(gn_j)               :=  gn_user_id;
      gt_pl_last_update_date_tbl(gn_j)              :=  gd_sysdate;
      gt_pl_last_update_login_tbl(gn_j)             :=  gn_login_id;
      gt_pl_request_id_tbl(gn_j)                    :=  gn_conc_request_id;
      gt_pl_program_appli_id_tbl(gn_j)              :=  gn_prog_appl_id;
      gt_pl_program_id_tbl(gn_j)                    :=  gn_conc_program_id;
      gt_pl_program_update_date_tbl(gn_j)           :=  gd_sysdate;
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : calc_load_efficiency_proc
   * Description      : 積載効率算出
   ***********************************************************************************/
  PROCEDURE calc_load_efficiency_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_load_efficiency_proc'; -- プログラム名
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
    cv_wh         CONSTANT VARCHAR2(2) := '4';   -- 倉庫
    cv_sup        CONSTANT VARCHAR2(2) := '11';  -- 支給先
    cv_request_no CONSTANT VARCHAR2(1) := '6';   -- 出荷依頼No
--
    -- *** ローカル変数 ***
    lv_errmsg_code        VARCHAR2(5000);       -- エラーメッセージコード
    lv_loading_over_class VARCHAR2(100);        -- 積載オーバー区分
    -- 未使用
    lv_ship_methods       VARCHAR2(100);        -- 出荷方法
    lv_mixed_ship_method  VARCHAR2(100);        -- 混載配送区分
-- 2008/07/24 v1.4 Start
    lv_load_efficiency_we VARCHAR2(100);        -- 重量積載効率
    lv_load_efficiency_ca VARCHAR2(100);        -- 容積積載効率
-- 2008/07/17 v1.3 End
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
-- 2008/07/24 v1.4 Start
/*    -- 重量の積載効率を取得する
    IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
      -- 「積載効率チェック(積載効率算出)」呼び出し
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            gt_h_sum_weight_tbl(gn_i),              -- 合計重量
                            NULL,                                   -- 合計容積
                            cv_wh,                                  -- 倉庫'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                            cv_sup,                                 -- 支給先'11'
                            gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                            gt_ship_method_tbl(gn_i),               -- 配送区分
                            gv_item_div_prf,                        -- 商品区分
                            NULL,                                   -- 自動配車対象区分
                            gd_standard_date,                       -- 基準日
                            lv_retcode,                             -- リターンコード
                            lv_errmsg_code,                         -- エラーメッセージコード
                            lv_errmsg,                              -- エラーメッセージ
                            lv_loading_over_class,                  -- 積載オーバー区分
                            lv_ship_methods,                        -- 出荷方法
                            gt_load_efficiency_we_tbl(gn_i),        -- 重量積載効率
                            gt_load_efficiency_ca_tbl(gn_i),        -- 容積積載効率
                            lv_mixed_ship_method                    -- 混載配送区分
                          );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
        RAISE global_api_expt;
      END IF;
--
    -- 容積の積載効率を取得する
    ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
      -- 「積載効率チェック(積載効率算出)」呼び出し
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            NULL,                                   -- 合計重量
                            gt_h_sum_capacity_tbl(gn_i),            -- 合計容積
                            cv_wh,                                  -- 倉庫'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                            cv_sup,                                 -- 支給先'11'
                            gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                            gt_ship_method_tbl(gn_i),               -- 配送区分
                            gv_item_div_prf,                        -- 商品区分
                            NULL,                                   -- 自動配車対象区分
                            gd_standard_date,                       -- 基準日
                            lv_retcode,                             -- リターンコード
                            lv_errmsg_code,                         -- エラーメッセージコード
                            lv_errmsg,                              -- エラーメッセージ
                            lv_loading_over_class,                  -- 積載オーバー区分
                            lv_ship_methods,                        -- 出荷方法
                            gt_load_efficiency_we_tbl(gn_i),        -- 重量積載効率
                            gt_load_efficiency_ca_tbl(gn_i),        -- 容積積載効率
                            lv_mixed_ship_method                    -- 混載配送区分
                          );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
*/--
    -- 重量の積載効率をチェックする
    IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
      -- 「積載効率チェック(積載効率算出)」呼び出し
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            gt_h_sum_weight_tbl(gn_i),              -- 合計重量
                            NULL,                                   -- 合計容積
                            cv_wh,                                  -- 倉庫'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                            cv_sup,                                 -- 支給先'11'
                            gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                            gt_ship_method_tbl(gn_i),               -- 配送区分
                            gv_item_div_prf,                        -- 商品区分
                            NULL,                                   -- 自動配車対象区分
                            gd_standard_date,                       -- 基準日
                            lv_retcode,                             -- リターンコード
                            lv_errmsg_code,                         -- エラーメッセージコード
                            lv_errmsg,                              -- エラーメッセージ
                            lv_loading_over_class,                  -- 積載オーバー区分
                            lv_ship_methods,                        -- 出荷方法
                            lv_load_efficiency_we,                  -- 重量積載効率
                            lv_load_efficiency_ca,                  -- 容積積載効率
                            lv_mixed_ship_method                    -- 混載配送区分
                          );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo            -- モジュール名略称:XXPO
                          ,gv_msg_common             -- メッセージ:APP-XXPO-10237 共通関数エラー
                          ,gv_tkn_common_name        -- トークンNG_NAME
                          ,gv_tkn_calc_load_ef_we)   -- 積載効率チェック(積載効率算出:重量)
                          ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 積載オーバーの場合
      IF (lv_loading_over_class = '1') THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo      -- モジュール名略称:XXPO
                        ,gv_msg_xxpo10120)     -- メッセージ:APP-XXPO-10120 積載効率チェックエラー
                        ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 容積の積載効率をチェックする
    ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
      -- 「積載効率チェック(積載効率算出)」呼び出し
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            NULL,                                   -- 合計重量
                            gt_h_sum_capacity_tbl(gn_i),            -- 合計容積
                            cv_wh,                                  -- 倉庫'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                            cv_sup,                                 -- 支給先'11'
                            gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                            gt_ship_method_tbl(gn_i),               -- 配送区分
                            gv_item_div_prf,                        -- 商品区分
                            NULL,                                   -- 自動配車対象区分
                            gd_standard_date,                       -- 基準日
                            lv_retcode,                             -- リターンコード
                            lv_errmsg_code,                         -- エラーメッセージコード
                            lv_errmsg,                              -- エラーメッセージ
                            lv_loading_over_class,                  -- 積載オーバー区分
                            lv_ship_methods,                        -- 出荷方法
                            lv_load_efficiency_we,                  -- 重量積載効率
                            lv_load_efficiency_ca,                  -- 容積積載効率
                            lv_mixed_ship_method                    -- 混載配送区分
                          );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo            -- モジュール名略称:XXPO
                          ,gv_msg_common             -- メッセージ:APP-XXPO-10237 共通関数エラー
                          ,gv_tkn_common_name        -- トークンNG_NAME
                          ,gv_tkn_calc_load_ef_ca)   -- 積載効率チェック(積載効率算出:重量)
                          ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 積載オーバーの場合
      IF (lv_loading_over_class = '1') THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo      -- モジュール名略称:XXPO
                        ,gv_msg_xxpo10120)     -- メッセージ:APP-XXPO-10120 積載効率チェックエラー
                        ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- 重量の積載効率を取得する
    -- 「積載効率チェック(積載効率算出)」呼び出し
    xxwsh_common910_pkg.calc_load_efficiency
                        (
                          gt_h_sum_weight_tbl(gn_i),              -- 合計重量
                          NULL,                                   -- 合計容積
                          cv_wh,                                  -- 倉庫'4'
                          gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                          cv_sup,                                 -- 支給先'11'
                          gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                          gt_ship_method_tbl(gn_i),               -- 配送区分
                          gv_item_div_prf,                        -- 商品区分
                          NULL,                                   -- 自動配車対象区分
                          gd_standard_date,                       -- 基準日
                          lv_retcode,                             -- リターンコード
                          lv_errmsg_code,                         -- エラーメッセージコード
                          lv_errmsg,                              -- エラーメッセージ
                          lv_loading_over_class,                  -- 積載オーバー区分
                          lv_ship_methods,                        -- 出荷方法
                          gt_load_efficiency_we_tbl(gn_i),        -- 重量積載効率
                          lv_load_efficiency_ca,                  -- 容積積載効率
                          lv_mixed_ship_method                    -- 混載配送区分
                        );
--
    -- 共通関数でエラーの場合
    IF (lv_retcode = '1') THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_msg_kbn_xxpo            -- モジュール名略称:XXPO
                        ,gv_msg_common             -- メッセージ:APP-XXPO-10237 共通関数エラー
                        ,gv_tkn_common_name        -- トークンNG_NAME
                        ,gv_tkn_calc_load_ef_we)   -- 積載効率チェック(積載効率算出:重量)
                        ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 容積の積載効率を取得する
    -- 「積載効率チェック(積載効率算出)」呼び出し
    xxwsh_common910_pkg.calc_load_efficiency
                        (
                          NULL,                                   -- 合計重量
                          gt_h_sum_capacity_tbl(gn_i),            -- 合計容積
                          cv_wh,                                  -- 倉庫'4'
                          gt_shipped_locat_code_tbl(gn_i),        -- 出庫倉庫コード
                          cv_sup,                                 -- 支給先'11'
                          gt_ship_to_code_tbl(gn_i),              -- 配送先コード
                          gt_ship_method_tbl(gn_i),               -- 配送区分
                          gv_item_div_prf,                        -- 商品区分
                          NULL,                                   -- 自動配車対象区分
                          gd_standard_date,                       -- 基準日
                          lv_retcode,                             -- リターンコード
                          lv_errmsg_code,                         -- エラーメッセージコード
                          lv_errmsg,                              -- エラーメッセージ
                          lv_loading_over_class,                  -- 積載オーバー区分
                          lv_ship_methods,                        -- 出荷方法
                          lv_load_efficiency_we,                  -- 重量積載効率
                          gt_load_efficiency_ca_tbl(gn_i),        -- 容積積載効率
                          lv_mixed_ship_method                    -- 混載配送区分
                        );
--
    -- 共通関数でエラーの場合
    IF (lv_retcode = '1') THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_msg_kbn_xxpo            -- モジュール名略称:XXPO
                        ,gv_msg_common             -- メッセージ:APP-XXPO-10237 共通関数エラー
                        ,gv_tkn_common_name        -- トークンNG_NAME
                        ,gv_tkn_calc_load_ef_ca)   -- 積載効率チェック(積載効率算出:重量)
                        ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2008/07/17 v1.3 End
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END calc_load_efficiency_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_header_proc
   * Description      : 受注ヘッダアドオン登録処理 (F-7)
   ***********************************************************************************/
  PROCEDURE put_header_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_header_proc'; -- プログラム名
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
    ln_h_cont   NUMBER;         -- ヘッダカウント変数
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    FORALL ln_h_cont IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST
      INSERT INTO xxwsh_order_headers_all
                 (order_header_id,
                  order_type_id,
                  organization_id,
                  header_id,
                  latest_external_flag,
                  ordered_date,
                  customer_id,
                  customer_code,
                  deliver_to_id,
                  deliver_to,
                  shipping_instructions,
                  career_id,
                  freight_carrier_code,
                  shipping_method_code,
                  cust_po_number,
                  price_list_id,
                  request_no,
                  base_request_no,
                  req_status,
                  delivery_no,
                  prev_delivery_no,
                  schedule_ship_date,
                  schedule_arrival_date,
                  mixed_no,
                  collected_pallet_qty,
                  confirm_request_class,
                  freight_charge_class,
                  shikyu_instruction_class,
                  shikyu_inst_rcv_class,
                  amount_fix_class,
                  takeback_class,
                  deliver_from_id,
                  deliver_from,
                  head_sales_branch,
                  input_sales_branch,
                  po_no,
                  prod_class,
                  item_class,
                  no_cont_freight_class,
                  arrival_time_from,
                  arrival_time_to,
                  designated_item_id,
                  designated_item_code,
                  designated_production_date,
                  designated_branch_no,
                  slip_number,
                  sum_quantity,
                  small_quantity,
                  label_quantity,
                  loading_efficiency_weight,
                  loading_efficiency_capacity,
                  based_weight,
                  based_capacity,
                  sum_weight,
                  sum_capacity,
                  mixed_ratio,
                  pallet_sum_quantity,
                  real_pallet_quantity,
                  sum_pallet_weight,
                  order_source_ref,
                  result_freight_carrier_id,
                  result_freight_carrier_code,
                  result_shipping_method_code,
                  result_deliver_to_id,
                  result_deliver_to,
                  shipped_date,
                  arrival_date,
                  weight_capacity_class,
                  actual_confirm_class,
                  notif_status,
                  prev_notif_status,
                  notif_date,
                  new_modify_flg,
                  process_status,
                  performance_management_dept,
                  instruction_dept,
                  transfer_location_id,
                  transfer_location_code,
                  mixed_sign,
                  screen_update_date,
                  screen_update_by,
                  tightening_date,
                  vendor_id,
                  vendor_code,
                  vendor_site_id,
                  vendor_site_code,
                  registered_sequence,
                  tightening_program_id,
                  corrected_tighten_class,
                  created_by,
                  creation_date,
                  last_updated_by,
                  last_update_date,
                  last_update_login,
                  request_id,
                  program_application_id,
                  program_id,
                  program_update_date)
      VALUES     (gt_ph_order_header_id_tbl(ln_h_cont),
                  gt_ph_order_type_id_tbl(ln_h_cont),
                  gt_ph_organization_id_tbl(ln_h_cont),
                  gt_ph_header_id_tbl(ln_h_cont),
                  gt_ph_latest_external_flag_tbl(ln_h_cont),
                  gt_ph_ordered_date_tbl(ln_h_cont),
                  gt_ph_customer_id_tbl(ln_h_cont),
                  gt_ph_customer_code_tbl(ln_h_cont),
                  gt_ph_deliver_to_id_tbl(ln_h_cont),
                  gt_ph_deliver_to_tbl(ln_h_cont),
                  gt_ph_shipping_inst_tbl(ln_h_cont),
                  gt_ph_career_id_tbl(ln_h_cont),
                  gt_ph_freight_carrier_code_tbl(ln_h_cont),
                  gt_ph_shipping_method_code_tbl(ln_h_cont),
                  gt_ph_cust_po_number_tbl(ln_h_cont),
                  gt_ph_price_list_id_tbl(ln_h_cont),
                  gt_ph_request_no_tbl(ln_h_cont),
                  gt_ph_base_request_no_tbl(ln_h_cont),
                  gt_ph_req_status_tbl(ln_h_cont),
                  gt_ph_delivery_no_tbl(ln_h_cont),
                  gt_ph_prev_delivery_no_tbl(ln_h_cont),
                  gt_ph_schedule_ship_date_tbl(ln_h_cont),
                  gt_ph_schedule_arr_date_tbl(ln_h_cont),
                  gt_ph_mixed_no_tbl(ln_h_cont),
                  gt_ph_collected_pallet_qty_tbl(ln_h_cont),
                  gt_ph_confirm_req_class_tbl(ln_h_cont),
                  gt_ph_freight_charge_class_tbl(ln_h_cont),
                  gt_ph_shikyu_inst_class_tbl(ln_h_cont),
                  gt_ph_sk_inst_rcv_class_tbl(ln_h_cont),
                  gt_ph_amount_fix_class_tbl(ln_h_cont),
                  gt_ph_takeback_class_tbl(ln_h_cont),
                  gt_ph_deliver_from_id_tbl(ln_h_cont),
                  gt_ph_deliver_from_tbl(ln_h_cont),
                  gt_ph_head_sales_branch_tbl(ln_h_cont),
                  gt_ph_input_sales_branch_tbl(ln_h_cont),
                  gt_ph_po_no_tbl(ln_h_cont),
                  gt_ph_prod_class_tbl(ln_h_cont),
                  gt_ph_item_class_tbl(ln_h_cont),
                  gt_ph_no_cont_fre_class_tbl(ln_h_cont),
                  gt_ph_arrival_time_from_tbl(ln_h_cont),
                  gt_ph_arrival_time_to_tbl(ln_h_cont),
                  gt_ph_designated_item_id_tbl(ln_h_cont),
                  gt_ph_designated_item_code_tbl(ln_h_cont),
                  gt_ph_designated_prod_date_tbl(ln_h_cont),
                  gt_ph_designated_branch_no_tbl(ln_h_cont),
                  gt_ph_slip_number_tbl(ln_h_cont),
                  gt_ph_sum_quantity_tbl(ln_h_cont),
                  gt_ph_small_quantity_tbl(ln_h_cont),
                  gt_ph_label_quantity_tbl(ln_h_cont),
                  gt_ph_load_efficiency_we_tbl(ln_h_cont),
                  gt_ph_load_efficiency_ca_tbl(ln_h_cont),
                  gt_ph_based_weight_tbl(ln_h_cont),
                  gt_ph_based_capacity_tbl(ln_h_cont),
                  gt_ph_sum_weight_tbl(ln_h_cont),
                  gt_ph_sum_capacity_tbl(ln_h_cont),
                  gt_ph_mixed_ratio_tbl(ln_h_cont),
                  gt_ph_pallet_sum_quantity_tbl(ln_h_cont),
                  gt_ph_real_pallet_quantity_tbl(ln_h_cont),
                  gt_ph_sum_pallet_weight_tbl(ln_h_cont),
                  gt_ph_order_source_ref_tbl(ln_h_cont),
                  gt_ph_result_fre_carr_id_tbl(ln_h_cont),
                  gt_ph_result_fre_carr_code_tbl(ln_h_cont),
                  gt_ph_res_ship_meth_code_tbl(ln_h_cont),
                  gt_ph_result_deliver_to_id_tbl(ln_h_cont),
                  gt_ph_result_deliver_to_tbl(ln_h_cont),
                  gt_ph_shipped_date_tbl(ln_h_cont),
                  gt_ph_arrival_date_tbl(ln_h_cont),
                  gt_ph_weight_ca_class_tbl(ln_h_cont),
                  gt_ph_actual_confirm_class_tbl(ln_h_cont),
                  gt_ph_notif_status_tbl(ln_h_cont),
                  gt_ph_prev_notif_status_tbl(ln_h_cont),
                  gt_ph_notif_date_tbl(ln_h_cont),
                  gt_ph_new_modify_flg_tbl(ln_h_cont),
                  gt_ph_process_status_tbl(ln_h_cont),
                  gt_ph_perform_manage_dept_tbl(ln_h_cont),
                  gt_ph_instruction_dept_tbl(ln_h_cont),
                  gt_ph_transfer_location_id_tbl(ln_h_cont),
                  gt_ph_trans_location_code_tbl(ln_h_cont),
                  gt_ph_mixed_sign_tbl(ln_h_cont),
                  gt_ph_screen_update_date_tbl(ln_h_cont),
                  gt_ph_screen_update_by_tbl(ln_h_cont),
                  gt_ph_tightening_date_tbl(ln_h_cont),
                  gt_ph_vendor_id_tbl(ln_h_cont),
                  gt_ph_vendor_code_tbl(ln_h_cont),
                  gt_ph_vendor_site_id_tbl(ln_h_cont),
                  gt_ph_vendor_site_code_tbl(ln_h_cont),
                  gt_ph_registered_sequence_tbl(ln_h_cont),
                  gt_ph_tight_program_id_tbl(ln_h_cont),
                  gt_ph_correct_tight_class_tbl(ln_h_cont),
                  gt_ph_created_by_tbl(ln_h_cont),
                  gt_ph_creation_date_tbl(ln_h_cont),
                  gt_ph_last_updated_by_tbl(ln_h_cont),
                  gt_ph_last_update_date_tbl(ln_h_cont),
                  gt_ph_last_update_login_tbl(ln_h_cont),
                  gt_ph_request_id_tbl(ln_h_cont),
                  gt_ph_program_appli_id_tbl(ln_h_cont),
                  gt_ph_program_id_tbl(ln_h_cont),
                  gt_ph_program_up_date_tbl(ln_h_cont));
--
      -- 成功件数(ヘッダ)カウント
      gn_h_normal_cnt := gt_ph_order_header_id_tbl.COUNT;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_line_proc
   * Description      : 受注明細アドオン登録処理 (F-8)
   ***********************************************************************************/
  PROCEDURE put_line_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_line_proc'; -- プログラム名
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
    ln_l_cont   NUMBER;         -- 明細カウント変数
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    FORALL ln_l_cont IN gt_pl_order_line_id_tbl.FIRST .. gt_pl_order_line_id_tbl.LAST
      INSERT INTO xxwsh_order_lines_all
                 (order_line_id,
                  order_header_id,
                  order_line_number,
                  header_id,
                  line_id,
                  request_no,
                  shipping_inventory_item_id,
                  shipping_item_code,
                  quantity,
                  uom_code,
                  unit_price,
                  shipped_quantity,
                  designated_production_date,
                  based_request_quantity,
                  request_item_id,
                  request_item_code,
                  ship_to_quantity,
                  futai_code,
                  designated_date,
                  move_number,
                  po_number,
                  cust_po_number,
                  pallet_quantity,
                  layer_quantity,
                  case_quantity,
                  weight,
                  capacity,
                  pallet_qty,
                  pallet_weight,
                  reserved_quantity,
                  automanual_reserve_class,
                  delete_flag,
                  warning_class,
                  warning_date,
                  line_description,
                  rm_if_flg,
                  shipping_request_if_flg,
                  shipping_result_if_flg,
                  created_by,
                  creation_date,
                  last_updated_by,
                  last_update_date,
                  last_update_login,
                  request_id,
                  program_application_id,
                  program_id,
                  program_update_date)
      VALUES     (gt_pl_order_line_id_tbl(ln_l_cont),
                  gt_pl_order_header_id_tbl(ln_l_cont),
                  gt_pl_order_line_number_tbl(ln_l_cont),
                  gt_pl_header_id_tbl(ln_l_cont),
                  gt_pl_line_id_tbl(ln_l_cont),
                  gt_pl_request_no_tbl(ln_l_cont),
                  gt_pl_ship_inv_item_id_tbl(ln_l_cont),
                  gt_pl_shipping_item_code_tbl(ln_l_cont),
                  gt_pl_quantity_tbl(ln_l_cont),
                  gt_pl_uom_code_tbl(ln_l_cont),
                  gt_pl_unit_price_tbl(ln_l_cont),
                  gt_pl_shipped_quantity_tbl(ln_l_cont),
                  gt_pl_design_prod_date_tbl(ln_l_cont),
                  gt_pl_based_req_quan_tbl(ln_l_cont),
                  gt_pl_request_item_id_tbl(ln_l_cont),
                  gt_pl_request_item_code_tbl(ln_l_cont),
                  gt_pl_ship_to_quantity_tbl(ln_l_cont),
                  gt_pl_futai_code_tbl(ln_l_cont),
                  gt_pl_designated_date_tbl(ln_l_cont),
                  gt_pl_move_number_tbl(ln_l_cont),
                  gt_pl_po_number_tbl(ln_l_cont),
                  gt_pl_cust_po_number_tbl(ln_l_cont),
                  gt_pl_pallet_quantity_tbl(ln_l_cont),
                  gt_pl_layer_quantity_tbl(ln_l_cont),
                  gt_pl_case_quantity_tbl(ln_l_cont),
                  gt_pl_weight_tbl(ln_l_cont),
                  gt_pl_capacity_tbl(ln_l_cont),
                  gt_pl_pallet_qty_tbl(ln_l_cont),
                  gt_pl_pallet_weight_tbl(ln_l_cont),
                  gt_pl_reserved_quantity_tbl(ln_l_cont),
                  gt_pl_auto_res_class_tbl(ln_l_cont),
                  gt_pl_delete_flag_tbl(ln_l_cont),
                  gt_pl_warning_class_tbl(ln_l_cont),
                  gt_pl_warning_date_tbl(ln_l_cont),
                  gt_pl_line_description_tbl(ln_l_cont),
                  gt_pl_rm_if_flg_tbl(ln_l_cont),
                  gt_pl_ship_req_if_flg_tbl(ln_l_cont),
                  gt_pl_ship_res_if_flg_tbl(ln_l_cont),
                  gt_pl_created_by_tbl(ln_l_cont),
                  gt_pl_creation_date_tbl(ln_l_cont),
                  gt_pl_last_updated_by_tbl(ln_l_cont),
                  gt_pl_last_update_date_tbl(ln_l_cont),
                  gt_pl_last_update_login_tbl(ln_l_cont),
                  gt_pl_request_id_tbl(ln_l_cont),
                  gt_pl_program_appli_id_tbl(ln_l_cont),
                  gt_pl_program_id_tbl(ln_l_cont),
                  gt_pl_program_update_date_tbl(ln_l_cont));
--
      -- 成功件数(明細)カウント
      gn_l_normal_cnt := gt_pl_order_line_id_tbl.COUNT;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_line_proc;
--
  /**********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : データ削除処理 (F-9)
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- プログラム名
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
    ln_dh_cont   NUMBER;         -- 削除用ヘッダカウント変数
    ln_dl_cont   NUMBER;         -- 削除用明細カウント変数
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --------------------------------------------------
    -- 支給依頼情報インタフェーステーブルヘッダ削除 --
    --------------------------------------------------
    FORALL ln_dh_cont IN gt_sup_req_headers_if_id_tbl.FIRST .. gt_sup_req_headers_if_id_tbl.LAST
      DELETE xxpo_supply_req_headers_if   srhi
      WHERE  srhi.supply_req_headers_if_id = gt_sup_req_headers_if_id_tbl(ln_dh_cont);
--
    --------------------------------------------------
    -- 支給依頼情報インタフェーステーブル明細削除 --
    --------------------------------------------------
    FORALL ln_dl_cont IN gt_supply_req_lines_if_id_tbl.FIRST .. gt_supply_req_lines_if_id_tbl.LAST
      DELETE xxpo_supply_req_lines_if   srli
      WHERE  srli.supply_req_lines_if_id  = gt_supply_req_lines_if_id_tbl(ln_dl_cont);
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_proc;
--
-- 2008/07/17 v1.3 Start
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- プログラム名
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
    cv_header   CONSTANT VARCHAR2(10)   := '(ヘッダ)';
    cv_line     CONSTANT VARCHAR2(10)   := '(明細)';
--
    -- *** ローカル変数 ***
    lv_msg  VARCHAR2(5000);  -- メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- データダンプ一括出力
    -- ===============================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 成功データ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxcmn       -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00005)     -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ,1,5000);
--
    lv_msg  := lv_msg || cv_header;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- ヘッダ正常データダンプ
    <<normal_h_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_h_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_h_dump_tab(ln_cnt_loop));
    END LOOP normal_h_dump_loop;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 成功データ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxcmn       -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00005)     -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ,1,5000);
--
    lv_msg  := lv_msg || cv_line;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 明細正常データダンプ
    <<normal_l_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_l_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_l_dump_tab(ln_cnt_loop));
    END LOOP normal_l_dump_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_dump_msg;
--
-- 2008/07/17 v1.3 End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_data_class     IN         VARCHAR2,      -- 1.データ種別
    iv_trans_type     IN         VARCHAR2,      -- 2.発生区分
    iv_req_dept       IN         VARCHAR2,      -- 3.依頼部署
    iv_vendor         IN         VARCHAR2,      -- 4.取引先
    iv_ship_to        IN         VARCHAR2,      -- 5.配送先
    iv_arvl_time_from IN         VARCHAR2,      -- 6.入庫日FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.入庫日TO
    iv_security_class IN         VARCHAR2,      -- 8.セキュリティ区分
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_line_number  NUMBER; -- 明細番号
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_h_target_cnt := 0;
    gn_l_target_cnt := 0;
    gn_h_cnt        := 0;
    gn_l_cnt        := 0;
--
-- 2008/07/17 v1.3 Start
    gn_h_cnt        := 0;
    gn_l_cnt        := 0;
--
-- 2008/07/17 v1.3 End
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    ------------------------------------------
    -- パラメータ必須チェック               --
    ------------------------------------------
    -- データ種別
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
    -- 発生区分
    ELSIF (iv_trans_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_trans_type);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
    -- 取引先
    ELSIF (iv_vendor IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_vendor);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- 入庫日FROM
    ELSIF (iv_arvl_time_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_arvl_time_from);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- 入庫日TO
    ELSIF (iv_arvl_time_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_arvl_time_to);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- セキュリティ区分
    ELSIF (iv_security_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_security_class);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    END IF;
--
    ------------------------------------------
    -- パラメータ日付チェック               --
    ------------------------------------------
    -- ｢入庫日TO｣が｢入庫日FROM｣より以前の場合
    IF (iv_arvl_time_from > iv_arvl_time_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_date,
                                            gv_tkn_date_item1,
                                            gv_arvl_time_from,
                                            gv_tkn_date_item2,
                                            gv_arvl_time_to);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    END IF;
--
    -- ===============================
    -- 初期処理 (F-1)
    -- ===============================
    init_proc(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- ヘッダデータ取得処理 (F-2)
    -- ===============================
    get_header_proc(
      iv_data_class,      -- 1.データ種別
      iv_trans_type,      -- 2.発生区分
      iv_req_dept,        -- 3.依頼部署
      iv_vendor,          -- 4.取引先
      iv_ship_to,         -- 5.配送先
      iv_arvl_time_from,  -- 6.入庫日FROM
      iv_arvl_time_to,    -- 7.入庫日TO
      iv_security_class,  -- 8.セキュリティ区分
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
--
      -- 2008/07/08 Mod ↓
      IF (gn_h_target_cnt = 0) THEN
        ov_retcode := gv_status_warn;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        RETURN;
      ELSE
        RAISE proc_err_expt;
      END IF;
      -- 2008/07/08 Mod ↑
--
    -- ロックエラーの場合は処理終了
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 明細データ取得処理 (F-3)
    -- ===============================
    get_line_proc(
      iv_data_class,      -- 1.データ種別
      iv_trans_type,      -- 2.発生区分
      iv_req_dept,        -- 3.依頼部署
      iv_vendor,          -- 4.取引先
      iv_ship_to,         -- 5.配送先
      iv_arvl_time_from,  -- 6.入庫日FROM
      iv_arvl_time_to,    -- 7.入庫日TO
      iv_security_class,  -- 8.セキュリティ区分
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    -- ロックエラーの場合は処理終了
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt;
    END IF;
--
    -- カウント変数初期化
    gn_i := 1;
    gn_j := 1;
--
    <<header_loop>>
    FOR i IN gt_sup_req_headers_if_id_tbl.FIRST .. gt_sup_req_headers_if_id_tbl.LAST LOOP
--
      -- ヘッダカウント変数
      gn_i := i;
--
      -- ヘッダID採番
      SELECT xxwsh_order_headers_all_s1.NEXTVAL 
      INTO gt_order_header_id_tbl(gn_i)
      FROM dual;
--
      -- 適用日設定
      gd_standard_date  := NVL(gt_ship_date_tbl(gn_i), gt_arvl_date_tbl(gn_i));
--
-- 2008/07/17 v1.3 Start
/*      -- ===============================
      -- 必須チェック処理 (F-4)(ヘッダ)
      -- ===============================
      chk_essent_proc(
        gv_header,          -- ヘッダ明細区分
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
*/--
-- 2008/07/17 v1.3 End
      -- ===============================
      -- マスタ存在チェック処理 (F-5)(ヘッダ)
      -- ===============================
      chk_exist_mst_proc(
        gv_header,          -- ヘッダ明細区分
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- ===============================
      -- 関連データ取得処理 (F-6)(ヘッダ)
      -- ===============================
      get_relation_proc(
        gv_header,          -- ヘッダ明細区分
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- 変数の初期化
      ln_line_number    := 0;
      gv_before_item_no := NULL;
--
      <<line_loop>>
      -- 明細が存在し、同一ヘッダIDの間実行する。
      WHILE (
              (gt_supply_req_lines_if_id_tbl.COUNT >= gn_j) AND
                (gt_sup_req_headers_if_id_tbl(gn_i)  = gt_line_headers_id_tbl(gn_j))
            ) LOOP
--
        -- 明細ID採番
        SELECT xxwsh_order_lines_all_s1.NEXTVAL 
        INTO gt_order_line_id_tbl(gn_j) 
        FROM dual;
--
        -- 明細番号の採番
        IF (ln_line_number = 0) THEN
          -- 同一ヘッダのMAX(明細番号) + 1を取得
          SELECT NVL( MAX(order_line_number), 0 ) + 1
          INTO   ln_line_number
          FROM   xxwsh_order_lines_all xola
          WHERE  xola.order_header_id   = gt_order_header_id_tbl(gn_i);   --受注ヘッダID
--
        ELSE
          ln_line_number := ln_line_number + 1;
--
        END IF;
--
        -- 明細番号の設定
        gt_line_number_tbl(gn_j) := ln_line_number;
--
-- 2008/07/17 v1.3 Start
/*        -- ===============================
        -- 必須チェック処理 (F-4)(明細)
        -- ===============================
        chk_essent_proc(
          gv_line,            -- ヘッダ明細区分
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
*/--
-- 2008/07/17 v1.3 End
        -- ===============================
        -- マスタ存在チェック処理 (F-5)(明細)
        -- ===============================
        chk_exist_mst_proc(
          gv_line,            -- ヘッダ明細区分
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- ===============================
        -- 関連データ取得処理 (F-6)(明細)
        -- ===============================
        get_relation_proc(
          gv_line,            -- ヘッダ明細区分
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- ===============================
        -- 登録データ設定処理 (明細)
        -- ===============================
        set_data_proc(
          gv_line,            -- ヘッダ明細区分
          lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          lv_retcode,         -- リターン・コード             --# 固定 #
          lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
-- 2008/07/17 v1.3 Start
        -- 正常明細データダンプPL/SQL表投入
        gn_l_cnt := gn_l_cnt + 1;
        normal_l_dump_tab(gn_l_cnt) := gt_lr_l_data_dump_tbl(gn_j);
--
-- 2008/07/17 v1.3 End
        -- 明細カウント変数インクリメント
        gn_j := gn_j + 1;
--
      END LOOP line_loop;
--
--      -- カウント変数を初期化
--      gn_j := 1;
--
      -- ===============================
      -- 積載効率算出
      -- ===============================
      calc_load_efficiency_proc(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- ===============================
      -- 登録データ設定処理 (ヘッダ)
      -- ===============================
      set_data_proc(
        gv_header,          -- ヘッダ明細区分
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
-- 2008/07/17 v1.3 Start
      -- 正常ヘッダデータダンプPL/SQL表投入
      gn_h_cnt := gn_h_cnt + 1;
      normal_h_dump_tab(gn_h_cnt) := gt_lr_h_data_dump_tbl(gn_i);
--
-- 2008/07/17 v1.3 End
    END LOOP header_loop;
--
    -- ===============================
    -- 受注ヘッダアドオン登録処理 (F-7)
    -- ===============================
    put_header_proc(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- 受注明細アドオン登録処理 (F-8)
    -- ===============================
    put_line_proc(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- データ削除処理 (F-9)
    -- ===============================
    delete_proc(
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/07/17 v1.3 Start
    -- =========================================
    -- データダンプ一括出力処理
    -- =========================================
    put_dump_msg(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/07/17 v1.3 End
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- 各処理でエラーが発生した場合
    WHEN proc_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
      -- ===============================
      -- データ削除処理 (F-9)
      -- ===============================
      delete_proc(
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> gv_status_error) THEN
        COMMIT;
      END IF;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf            OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode           OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_data_class     IN         VARCHAR2,      -- 1.データ種別
    iv_trans_type     IN         VARCHAR2,      -- 2.発生区分
    iv_req_dept       IN         VARCHAR2,      -- 3.依頼部署
    iv_vendor         IN         VARCHAR2,      -- 4.取引先
    iv_ship_to        IN         VARCHAR2,      -- 5.配送先
    iv_arvl_time_from IN         VARCHAR2,      -- 6.入庫日FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.入庫日TO
    iv_security_class IN         VARCHAR2       -- 8.セキュリティ区分
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- 2008/07/17 v1.3 Start
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_msg  VARCHAR2(5000);  -- メッセージ
--
-- 2008/07/17 v1.3 Start
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
    --実行コンカレント名取得
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- 固定出力
    -- ======================
    --実行ユーザ名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  固定部 END   #############################
--
-- 2008/07/17 v1.3 Start
    -- 入力パラメータ取得
    gv_iv_data_class       := iv_data_class;      -- 1.データ種別
    gv_iv_trans_type       := iv_trans_type;      -- 2.発生区分
    gv_iv_req_dept         := iv_req_dept;        -- 3.依頼部署
    gv_iv_vendor           := iv_vendor;          -- 4.取引先
    gv_iv_ship_to          := iv_ship_to;         -- 5.配送先
    gv_iv_arvl_time_from   := iv_arvl_time_from;  -- 6.入庫日FROM
    gv_iv_arvl_time_to     := iv_arvl_time_to;    -- 7.入庫日TO
    gv_iv_security_class   := iv_security_class;  -- 8.セキュリティ区分
--
    -- ===============================
    -- 入力パラメータ出力
    -- ===============================
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 入力パラメータ(見出し)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxpo      -- モジュール名略称：XXPO
                  ,gv_msg_xxpo30051)    -- メッセージ:APP-XXPO-30051 入力パラメータ(見出し)
                ,1,5000);
--
    -- 入力パラメータ見出し出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 入力パラメータ(カンマ区切り)
    lv_msg := gv_iv_data_class     || gv_msg_comma || -- 1.データ種別
              gv_iv_trans_type     || gv_msg_comma || -- 2.発生区分
              gv_iv_req_dept       || gv_msg_comma || -- 3.依頼部署
              gv_iv_vendor         || gv_msg_comma || -- 4.取引先
              gv_iv_ship_to        || gv_msg_comma || -- 5.配送先
              gv_iv_arvl_time_from || gv_msg_comma || -- 6.入庫日FROM
              gv_iv_arvl_time_to   || gv_msg_comma || -- 7.入庫日TO
              gv_iv_security_class;                   -- 8.セキュリティ区分
--
    -- 入力パラメータ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
-- 2008/07/17 v1.3 End
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_data_class,      -- 1.データ種別
      iv_trans_type,      -- 2.発生区分
      iv_req_dept,        -- 3.依頼部署
      iv_vendor,          -- 4.取引先
      iv_ship_to,         -- 5.配送先
      iv_arvl_time_from,  -- 6.入庫日FROM
      iv_arvl_time_to,    -- 7.入庫日TO
      iv_security_class,  -- 8.セキュリティ区分
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    ------------------------------------------
    -- ヘッダと明細を分けて出力             --
    ------------------------------------------
    --処理件数出力(ヘッダ)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_h_target_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_h_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(明細)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_l_target_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_l_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力(ヘッダ)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_h_normal_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_h_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力(明細)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_l_normal_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_l_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxpo940006c;
/
