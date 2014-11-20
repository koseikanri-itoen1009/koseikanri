create or replace PACKAGE BODY xxpo940008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940008c(body)
 * Description      : ロット引当情報取込処理
 * MD.050           : 取引先オンライン T_MD050_BPO_940
 * MD.070           : ロット引当情報取込処理 T_MD070_BPO_94H
 * Version          : 1.3
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init_proc                   初期処理(H-1)
 *  check_can_enc_qty           引当数量チェック処理(H-2)
 *  get_data                    対象データ取得処理(H-3)
 *  check_data                  取得データチェック処理(H-4)
 *  get_other_data              関連データ取得処理(H-5)
 *  ins_mov_lot_details         移動ロット詳細(アドオン)登録処理(H-6)
 *  ins_order_lines_all         受注明細(アドオン)登録処理(H-7)
 *  ins_order_headers_all       受注ヘッダ(アドオン)登録処理(H-8)
 *  del_lot_reserve_if          データ削除処理(H-9)
 *  put_dump_msg                データダンプ一括出力処理(H-10)
 *  set_order_header_data_proc  受注ヘッダ更新データ設定処理
 *  set_order_line_data_proc    受注明細更新データ設定処理
 *  set_mov_lot_data_proc       移動ロット詳細登録データ設定処理
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/19    1.0  Oracle 吉田夏樹   初回作成
 *  2008/07/22    1.1  Oracle 吉田夏樹   内部課題#32、#66、内部変更#166対応
 *  2008/07/29    1.2  Oracle 吉田夏樹   ST不具合対応(採番なし)
 *  2008/08/22    1.3  Oracle 山根一浩   T_TE080_BPO_940 指摘4,指摘5,指摘17対応
 *
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  gn_target_cnt    NUMBER;                    -- 対象件数(ロット引当情報IF)
  gn_h_normal_cnt  NUMBER;                    -- 正常件数(受注ヘッダ)
  gn_l_normal_cnt  NUMBER;                    -- 正常件数(受注明細)
  gn_m_normal_cnt  NUMBER;                    -- 正常件数(移動ロット詳細)
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
  -- ロック取得エラー
  check_lock_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  lock_expt                EXCEPTION;  -- ロック取得例外
  proc_err_expt            EXCEPTION;     -- 処理エラー
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ロック取得例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxpo940008c'; -- パッケージ名
--
  -- アプリケーション短縮名
  gv_xxpo                 CONSTANT VARCHAR2(5) := 'XXPO';   -- モジュール名略称:XXPO
  gv_xxcmn                CONSTANT VARCHAR2(5) := 'XXCMN';  -- モジュール名略称:XXCMN
--
  -- メッセージ
  gv_msg_xxcmn10002       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
  gv_msg_xxcmn10019       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- メッセージ:APP-XXCMN-10019 ロックエラー
  gv_msg_xxpo10234        CONSTANT VARCHAR2(100) := 'APP-XXPO-10234';  -- メッセージ:APP-XXPO-10234  存在チェックエラー
  gv_msg_xxcmn00005       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- メッセージ:APP-XXCMN-00005 成功データ（見出し）
  gv_msg_xxpo10252        CONSTANT VARCHAR2(100) := 'APP-XXPO-10252';  -- メッセージ:APP-XXPO-10252  警告データ（見出し）
  gv_msg_xxpo10007        CONSTANT VARCHAR2(100) := 'APP-XXPO-10007';  -- メッセージ:APP-XXPO-10007  データ登録エラー
  gv_msg_xxpo10025        CONSTANT VARCHAR2(100) := 'APP-XXPO-10025';  -- メッセージ:APP-XXPO-10025  コンカレント登録エラー
  gv_msg_xxpo10120        CONSTANT VARCHAR2(100) := 'APP-XXPO-10120';  -- メッセージ:APP-XXPO-10226  積載効率チェックエラー
  gv_msg_xxcmn10109       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10109'; -- メッセージ:APP-XXCMN-10109 引当可能在庫数超過通知ワーニング
  gv_msg_xxcmn10018       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; -- メッセージ:APP-XXCMN-10018 APIエラー
  gv_msg_xxpo10229        CONSTANT VARCHAR2(100) := 'APP-XXPO-10229';  -- メッセージ:APP-XXPO-10229  データ取得エラー
  gv_msg_xxpo10237        CONSTANT VARCHAR2(100) := 'APP-XXPO-10237';  -- メッセージ:APP-XXPO-10237  共通関数エラー
  gv_msg_xxpo10156        CONSTANT VARCHAR2(100) := 'APP-XXPO-10156';  -- メッセージ:APP-XXPO-10156  プロファイル取得エラー
  gv_msg_xxpo10235        CONSTANT VARCHAR2(100) := 'APP-XXPO-10235';  -- メッセージ:APP-XXPO-10235  パラメータ必須エラー
  gv_msg_xxpo10236        CONSTANT VARCHAR2(100) := 'APP-XXPO-10236';  -- メッセージ:APP-XXPO-10236  パラメータ日付エラー
  gv_msg_xxpo10255        CONSTANT VARCHAR2(100) := 'APP-XXPO-10255';  -- メッセージ:APP-XXPO-10255  数値0以下エラー
  gv_msg_xxpo30051        CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';  -- メッセージ:APP-XXPO-30051  入力パラメータ(見出し)
  gv_msg_xxpo10262        CONSTANT VARCHAR2(100) := 'APP-XXPO-10262';  -- メッセージ:APP-XXPO-10262  引当情報不足エラー
  gv_msg_xxcmn10604       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10604'; -- メッセージ:APP-XXCMN-10604 ケース入数エラー
  gv_msg_xxpo10267        CONSTANT VARCHAR2(100) := 'APP-XXPO-10267';  -- メッセージ:APP-XXPO-10267  ロットステータスエラー 2008/08/22 Add
--
  -- トークン
  gv_tkn_ng_profile       CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_location         CONSTANT VARCHAR2(100) := 'LOCATION';
  gv_tkn_item             CONSTANT VARCHAR2(100) := 'ITEM';
  gv_tkn_lot              CONSTANT VARCHAR2(100) := 'LOT';
  gv_tkn_api_name         CONSTANT VARCHAR2(100) := 'API_NAME';
  gv_tkn_common_name      CONSTANT VARCHAR2(100) := 'NG_COMMON';
  gv_tkn_name             CONSTANT VARCHAR2(100) := 'NAME';
  gv_tkn_ship_type        CONSTANT VARCHAR2(100) := 'SHIP_TYPE';
  gv_tkn_ship_to          CONSTANT VARCHAR2(100) := 'SHIP_TO';
  gv_tkn_revdate          CONSTANT VARCHAR2(100) := 'REVDATE';
  gv_tkn_arrival_date     CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
  gv_tkn_standard_date    CONSTANT VARCHAR2(100) := 'STANDARD_DATE';
  gv_tkn_para_name        CONSTANT VARCHAR2(100) := 'PARAM_NAME';
  gv_tkn_date_item1       CONSTANT VARCHAR2(100) := 'ITEM1';
  gv_tkn_date_item2       CONSTANT VARCHAR2(100) := 'ITEM2';
  gv_tkn_request_no       CONSTANT VARCHAR2(100) := 'REQUEST_NO';
  gv_tkn_item_no          CONSTANT VARCHAR2(100) := 'ITEM_NO';
  gv_tkn_lot_no           CONSTANT VARCHAR2(100) := 'LOT_NO';             -- 2008/08/22 Add
-- 
  -- トークン名称
  gv_tkn_prod_class_code     CONSTANT VARCHAR2(100) := 'XXCMN:商品区分(セキュリティ)';
  gv_item_div_id             CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
  gv_tkn_lot_reserve_if      CONSTANT VARCHAR2(100) := 'ロット引当情報インタフェース';
  gv_tkn_xxpo_headers_all    CONSTANT VARCHAR2(100) := '受注ヘッダ(アドオン)';
  gv_tkn_xxpo_lines_all      CONSTANT VARCHAR2(100) := '受注明細(アドオン)';
  gv_tkn_xxinv_mov_lot_details  CONSTANT VARCHAR2(100) := '移動ロット詳細(アドオン)';
  gv_tkn_chk_can_qty         CONSTANT VARCHAR2(100) := '引当可能数算出';
  gv_tkn_calc_total_value    CONSTANT VARCHAR2(100) := '積載効率チェック(合計値算出)';
  gv_tkn_calc_load_ef_we     CONSTANT VARCHAR2(100) := '積載効率チェック(積載効率算出:重量)';
  gv_tkn_calc_load_ef_ca     CONSTANT VARCHAR2(100) := '積載効率チェック(積載効率算出:容積)';
  gv_tkn_cancel_car_sche     CONSTANT VARCHAR2(100) := '配車解除関数';
  gv_tkn_xxcmn_lookup_values2   CONSTANT VARCHAR2(100) := 'クイックコード情報VIEW2';
  gv_tkn_reserve_qty         CONSTANT VARCHAR2(100) := '引当数量';
  gv_tkn_date                CONSTANT VARCHAR2(100) := '対象データ';
--
  gv_max_ship                CONSTANT VARCHAR2(100)  := '最大配送区分算出関数';
  gv_deliver_from            CONSTANT VARCHAR2(100)  := '配送先';
  gv_data_class              CONSTANT VARCHAR2(100)  := 'データ種別';
  gv_deliver_from_s          CONSTANT VARCHAR2(100)  := '倉庫';
  gv_shippe_date_from        CONSTANT VARCHAR2(100)  := '出庫日FROM';
  gv_shippe_date_to          CONSTANT VARCHAR2(100)  := '出庫日TO';
  gv_instruction_dept        CONSTANT VARCHAR2(100)  := '指示部署';
  gv_security_class          CONSTANT VARCHAR2(100)  := 'セキュリティ区分';
--
  -- セキュリティ区分
  gv_security_kbn_in         CONSTANT VARCHAR2(1) := '1'; -- セキュリティ区分 伊藤園ユーザー
  gv_security_kbn_out        CONSTANT VARCHAR2(1) := '4'; -- セキュリティ区分 東洋埠頭ユーザー
--
  -- 日付書式
  gv_yyyymmdd                CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gv_yyyymmddhh24miss        CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- 自動手動引当区分
  gv_am_reserve_class_ma     CONSTANT VARCHAR2(2) := '10'; -- 手動
  gv_am_reserve_class_au     CONSTANT VARCHAR2(2) := '20'; -- 自動
--
  -- 文書タイプ
  gv_document_type_ship_req  CONSTANT VARCHAR2(2) := '30'; -- 支給依頼
--
  -- レコードタイプ
  gv_record_type_inst        CONSTANT VARCHAR2(2) := '10'; -- 指示
--
  -- 処理タイプ
  gv_we               CONSTANT VARCHAR2(1)   := '1';       -- 重量
  gv_ca               CONSTANT VARCHAR2(1)   := '2';       -- 容積
  gv_object           CONSTANT VARCHAR2(1)   := '1';       -- 対象
--
  -- 品目区分
  gv_item_class_code_prod         CONSTANT VARCHAR2(1) := '5'; -- 品目区分:製品
  gv_item_class_code_half_prod    CONSTANT VARCHAR2(1) := '4'; -- 品目区分:半製品
--
  -- 商品区分
  gv_prod_class_code_leaf    CONSTANT VARCHAR2(1) := '1'; -- 商品区分:リーフ
  gv_prod_class_code_drink   CONSTANT VARCHAR2(1) := '2'; -- 商品区分:ドリンク
-- ST不具合対応 modify 2008/07/29 start
  -- 運賃区分
  gv_freight_charge_class_on      CONSTANT VARCHAR2(1) := '1'; -- 運賃区分:対象
  gv_freight_charge_class_off     CONSTANT VARCHAR2(1) := '0'; -- 運賃区分:対象外
-- ST不具合対応 modify 2008/07/29 end
--
  -- APIリターン・コード
  gv_api_ret_cd_normal       CONSTANT VARCHAR2(1) := 'S'; -- APIリターン・コード:正常終了
--
  -- フラグ
  gv_flg_y     CONSTANT VARCHAR2(1) := 'Y';  -- フラグ:Y
  gv_flg_n     CONSTANT VARCHAR2(1) := 'N';  -- フラグ:N
  gv_flg_on    CONSTANT VARCHAR2(1) := '1';  -- フラグ:1
  gv_flg_off   CONSTANT VARCHAR2(1) := '0';  -- フラグ:0
--
  -- 受注ヘッダ/受注明細区分(内部ロジック用)
  gv_header           CONSTANT VARCHAR2(1)   := '0';      -- ヘッダ
  gv_line             CONSTANT VARCHAR2(1)   := '1';      -- 明細
--
  -- ステータス
  gv_transaction_status_04   CONSTANT VARCHAR2(2) := '05';  -- 入力中
  gv_transaction_status_06   CONSTANT VARCHAR2(2) := '06';  -- 入力完了
  gv_transaction_status_07   CONSTANT VARCHAR2(2) := '07';  -- 受領済
  gv_transaction_status_08   CONSTANT VARCHAR2(2) := '08';  -- 出荷実績計上済
  gv_transaction_status_99   CONSTANT VARCHAR2(2) := '99';  -- 取消：99
--
  -- 顧客区分
  gv_customer_class_code_1     CONSTANT NUMBER       := 1;    -- 顧客区分:1(拠点)
--
  -- クイックコード
  gv_lookup_type_xsm           CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';  -- 配送区分
--
  -- 業務種別
  gv_supply                    CONSTANT VARCHAR2(1)  := '2';                -- 支給
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- メッセージPL/SQL表型
  TYPE msg_ttype         IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- 受注明細指示数量更新フラグ
  TYPE gt_pl_up_flg_type         IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  -- 受注明ヘッダ指示数量更新フラグ
  TYPE gt_ph_up_flg_type         IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  -- 最大配送区分
  TYPE gt_ship_method_tbl_type   IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
  -- 小口区分
  --TYPE gt_small_amount_class_tbl_type   IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- ロット引当情報インタフェース取得       --
  ---------------------------------------------
  -- ロット引当情報インタフェースヘッダID
  TYPE lr_lot_reserve_if_id_tbl IS TABLE OF
    xxpo_lot_reserve_if.lot_reserve_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No.
  TYPE lr_request_no_tbl IS TABLE OF
    xxpo_lot_reserve_if.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE lr_item_code_tbl IS TABLE OF
    xxpo_lot_reserve_if.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 明細摘要
  TYPE lr_line_description_tbl IS TABLE OF
    xxpo_lot_reserve_if.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- ロットNo.
  TYPE lr_lot_no_tbl IS TABLE OF
    xxpo_lot_reserve_if.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- 引当数量
  TYPE lr_reserved_quantity_tbl IS TABLE OF
    xxpo_lot_reserve_if.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 明細ID
  TYPE lr_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 引当数量合計
  TYPE lr_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ロットID
  TYPE lr_lot_id_tbl IS TABLE OF
    ic_lots_mst.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- 品目ID
  TYPE lr_item_id_tbl IS TABLE OF
    xxcmn_item_mst2_v.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 入出庫換算単位
  TYPE lr_conv_unit_tbl IS TABLE OF
    xxcmn_item_mst2_v.conv_unit%TYPE INDEX BY BINARY_INTEGER;
  -- ケース入り数
  TYPE lr_num_of_cases_tbl IS TABLE OF
    xxcmn_item_mst2_v.num_of_cases%TYPE INDEX BY BINARY_INTEGER;
  -- 配送先ID
  TYPE lr_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- 入力保管倉庫コード
  TYPE lr_deliver_from_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE lr_sche_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷日
  TYPE lr_shipped_date_tbl IS TABLE OF
    xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE lr_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 製造年月日(OPMロットマスタ)
  TYPE lr_lot_date_tbl IS TABLE OF
    ic_lots_mst.attribute1%TYPE INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE lr_prod_class_code_tbl IS TABLE OF
    xxcmn_item_categories4_v.prod_class_code%TYPE INDEX BY BINARY_INTEGER;
  -- 品目区分
  TYPE lr_item_class_code_tbl IS TABLE OF
    xxcmn_item_categories4_v.item_class_code%TYPE INDEX BY BINARY_INTEGER;
  -- 配送先コード
  TYPE lr_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- 重量容積区分
  TYPE lr_we_ca_class_tbl IS TABLE OF
    xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- データダンプ
  TYPE lr_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE lr_shipping_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
-- ST不具合対応 modify 2008/07/29 start
  -- 運賃区分
  TYPE lr_freight_charge_class_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
-- ST不具合対応 modify 2008/07/29 end
-- 2008/08/22 Add ↓
  -- ロット
  TYPE lr_lot_ctl_tbl IS TABLE OF
    xxcmn_item_mst2_v.lot_ctl%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ↑
--
  ---------------------------------------------
  -- 移動ロット詳細アドオン取得              --
  ---------------------------------------------
  -- ロット詳細ID
  TYPE mr_mov_lot_dtl_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- 受注ヘッダアドオン更新                  --
  ---------------------------------------------
  -- 受注ヘッダアドオンID
  TYPE ph_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No.
  TYPE ph_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
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
  TYPE ph_load_efficiency_we_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積積載効率
  TYPE ph_load_efficiency_ca_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 積載重量合計
  TYPE ph_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 積載容積合計
  TYPE ph_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- パレット合計重量
  TYPE ph_sum_pallet_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE ph_last_updated_by_tbl IS TABLE OF
    xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE ph_last_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE ph_last_update_login_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ↓
  -- 基本重量
  TYPE ph_based_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 基本容積
  TYPE ph_based_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- 配送区分
  TYPE ph_shipping_method_cd_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ↑
--
  ---------------------------------------------
  -- 受注明細アドオン更新                    --
  ---------------------------------------------
  -- 受注明細アドオンID
  TYPE pl_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE pl_order_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE pl_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 重量
  TYPE pl_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- 容積
  TYPE pl_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- パレット重量
  TYPE pl_pallet_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- 引当数
  TYPE pl_reserved_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 自動手動引当区分
  TYPE pl_auto_reserve_class_tbl IS TABLE OF
    xxwsh_order_lines_all.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- 摘要
  TYPE pl_line_description_tbl IS TABLE OF
    xxwsh_order_lines_all.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE pl_last_updated_by_tbl IS TABLE OF
    xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE pl_last_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE pl_last_update_login_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- 移動ロット詳細(アドオン)更新                    --
  ---------------------------------------------
  -- ロット詳細ID
  TYPE pm_mov_lot_dtl_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
  -- 詳細ID
  TYPE pm_mov_line_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 文書タイプ
  TYPE pm_document_type_code_tbl IS TABLE OF
    xxinv_mov_lot_details.document_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- レコードタイプ
  TYPE pm_record_type_code_tbl IS TABLE OF
    xxinv_mov_lot_details.record_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- OPM品目ID
  TYPE pm_item_id_tbl IS TABLE OF
    xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 品目コード
  TYPE pm_item_code_tbl IS TABLE OF
    xxinv_mov_lot_details.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ロットID
  TYPE pm_lot_id_tbl IS TABLE OF
    xxinv_mov_lot_details.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- ロットNo.
  TYPE pm_lot_no_tbl IS TABLE OF
    xxinv_mov_lot_details.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- 実績日
  TYPE pm_actual_date_tbl IS TABLE OF
    xxinv_mov_lot_details.actual_date%TYPE INDEX BY BINARY_INTEGER;
  -- 実績数量
  TYPE pm_actual_quantity_tbl IS TABLE OF
    xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 自動手動引当区分
  TYPE pm_auma_reserve_class_tbl IS TABLE OF
    xxinv_mov_lot_details.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE pm_created_by_tbl IS TABLE OF
    xxinv_mov_lot_details.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE pm_creation_date_tbl IS TABLE OF
    xxinv_mov_lot_details.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE pm_last_updated_by_tbl IS TABLE OF
    xxinv_mov_lot_details.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE pm_last_update_date_tbl IS TABLE OF
    xxinv_mov_lot_details.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE pm_last_update_login_tbl IS TABLE OF
    xxinv_mov_lot_details.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE pm_request_id_tbl IS TABLE OF
    xxinv_mov_lot_details.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラム・アプリケーションID
  TYPE pm_program_app_id_tbl IS TABLE OF
    xxinv_mov_lot_details.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE pm_program_id_tbl IS TABLE OF
    xxinv_mov_lot_details.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE pm_program_update_date_tbl IS TABLE OF
    xxinv_mov_lot_details.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
  -- ロット引当情報IF取得用
  gt_lr_lot_reserve_if_id_tbl         lr_lot_reserve_if_id_tbl;
  gt_lr_request_no_tbl                lr_request_no_tbl;
  gt_lr_item_code_tbl                 lr_item_code_tbl;
  gt_lr_line_description_tbl          lr_line_description_tbl;
  gt_lr_lot_no_tbl                    lr_lot_no_tbl;
  gt_lr_reserved_quantity_tbl         lr_reserved_quantity_tbl;
  gt_lr_order_line_id_tbl             lr_order_line_id_tbl;
  gt_lr_quantity_tbl                  lr_quantity_tbl;
  gt_lr_lot_id_tbl                    lr_lot_id_tbl;
  gt_lr_item_id_tbl                   lr_item_id_tbl;
  gt_lr_conv_unit_tbl                 lr_conv_unit_tbl;
  gt_lr_num_of_cases_tbl              lr_num_of_cases_tbl;
  gt_lr_deliver_to_id_tbl             lr_deliver_to_id_tbl;
  gt_lr_deliver_from_tbl              lr_deliver_from_tbl;
  gt_lr_sche_arrival_date_tbl         lr_sche_arrival_date_tbl;
  gt_lr_shipped_date_tbl              lr_shipped_date_tbl;  
  gt_lr_order_header_id_tbl           lr_order_header_id_tbl;
  gt_lr_lot_date_tbl                  lr_lot_date_tbl;
  gt_lr_prod_class_code_tbl           lr_prod_class_code_tbl;
  gt_lr_item_class_code_tbl           lr_item_class_code_tbl;
  gt_lr_deliver_to_tbl                lr_deliver_to_tbl;
  gt_lr_we_ca_class_tbl               lr_we_ca_class_tbl;
  gt_lr_data_dump_tbl                 lr_data_dump_tbl;
  gt_lr_shipping_method_code_tbl      lr_shipping_method_code_tbl;
-- ST不具合対応 modify 2008/07/29 start
  gt_lr_freight_charge_class_tbl      lr_freight_charge_class_tbl;
-- ST不具合対応 modify 2008/07/29 end
-- 2008/08/22 Add ↓
  gt_lr_lot_ctl_tbl                   lr_lot_ctl_tbl;
-- 2008/08/22 Add ↑
--
  -- 移動ロット詳細取得用
  gt_mr_mov_lot_dtl_id_tbl            mr_mov_lot_dtl_id_tbl;
--
  -- 更新用(受注ヘッダアドオン)
  gt_ph_order_header_id_tbl                 ph_order_header_id_tbl;
  gt_ph_request_no_tbl                      ph_request_no_tbl;
  gt_ph_sum_quantity_tbl                    ph_sum_quantity_tbl;
  gt_ph_small_quantity_tbl                  ph_small_quantity_tbl;
  gt_ph_label_quantity_tbl                  ph_label_quantity_tbl;
  gt_ph_load_efficiency_we_tbl              ph_load_efficiency_we_tbl;
  gt_ph_load_efficiency_ca_tbl              ph_load_efficiency_ca_tbl;
  gt_ph_sum_weight_tbl                      ph_sum_weight_tbl;
  gt_ph_sum_capacity_tbl                    ph_sum_capacity_tbl;
  gt_ph_last_updated_by_tbl                 ph_last_updated_by_tbl;
  gt_ph_last_update_date_tbl                ph_last_update_date_tbl;
  gt_ph_last_update_login_tbl               ph_last_update_login_tbl;
  gt_ph_sum_pallet_weight_tbl               ph_sum_pallet_weight_tbl;
  --更新用(受注明細アドオン)
  gt_pl_order_line_id_tbl                   pl_order_line_id_tbl;
  gt_pl_order_header_id_tbl                 pl_order_header_id_tbl;
  gt_pl_quantity_tbl                        pl_quantity_tbl;
  gt_pl_weight_tbl                          pl_weight_tbl;
  gt_pl_capacity_tbl                        pl_capacity_tbl;
  gt_pl_reserved_quantity_tbl               pl_reserved_quantity_tbl;
  gt_pl_auto_reserve_class_tbl              pl_auto_reserve_class_tbl;
  gt_pl_line_description_tbl                pl_line_description_tbl;
  gt_pl_last_updated_by_tbl                 pl_last_updated_by_tbl;
  gt_pl_last_update_date_tbl                pl_last_update_date_tbl;
  gt_pl_last_update_login_tbl               pl_last_update_login_tbl;
  gt_pl_pallet_weight_tbl                   pl_pallet_weight_tbl;
  -- 登録用(移動ロット詳細アドオン)
  gt_pm_mov_lot_dtl_id_tbl                  pm_mov_lot_dtl_id_tbl;
  gt_pm_mov_line_id_tbl                     pm_mov_line_id_tbl;
  gt_pm_document_type_code_tbl              pm_document_type_code_tbl;
  gt_pm_record_type_code_tbl                pm_record_type_code_tbl;
  gt_pm_item_id_tbl                         pm_item_id_tbl;
  gt_pm_item_code_tbl                       pm_item_code_tbl;
  gt_pm_lot_id_tbl                          pm_lot_id_tbl;
  gt_pm_lot_no_tbl                          pm_lot_no_tbl;
  gt_pm_actual_date_tbl                     pm_actual_date_tbl;
  gt_pm_actual_quantity_tbl                 pm_actual_quantity_tbl;
  gt_pm_auma_reserve_class_tbl              pm_auma_reserve_class_tbl;
  gt_pm_created_by_tbl                      pm_created_by_tbl;
  gt_pm_creation_date_tbl                   pm_creation_date_tbl;
  gt_pm_last_updated_by_tbl                 pm_last_updated_by_tbl;
  gt_pm_last_update_date_tbl                pm_last_update_date_tbl;
  gt_pm_last_update_login_tbl               pm_last_update_login_tbl;
  gt_pm_request_id_tbl                      pm_request_id_tbl;
  gt_pm_program_app_id_tbl                  pm_program_app_id_tbl;
  gt_pm_program_id_tbl                      pm_program_id_tbl;
  gt_pm_program_update_date_tbl             pm_program_update_date_tbl;
--
  gt_pl_up_flg                gt_pl_up_flg_type;
  gt_ph_up_flg                gt_ph_up_flg_type;
  gt_ship_method_tbl          gt_ship_method_tbl_type;
  --gt_small_amount_class_tbl   gt_small_amount_class_tbl_type;
--
  -- データダンプ用PL/SQL表
  warn_dump_tab          msg_ttype; -- 警告
  normal_dump_tab        msg_ttype; -- 正常
--
  gv_min_date                 VARCHAR2(10);            -- 最小日付
  gv_max_date                 VARCHAR2(10);            -- 最大日付
--
  -- PL/SQL表カウント
  gn_warn_msg_cnt           NUMBER := 0; -- 警告エラーメッセージPL/SQ表 カウント
  gn_normal_cnt             NUMBER := 0; -- 正常エラーメッセージPL/SQ表 カウント
--
  -- カウント変数
  gn_i                      NUMBER;           -- カウント変数(移動ロット詳細単位)
  gn_j                      NUMBER;           -- カウント変数(受注明細単位)
  gn_k                      NUMBER;           -- カウント変数(受注ヘッダ単位)
  -- 数量合計用変数
  gn_lot_sum                NUMBER;           -- 数量合計用変数(ロット単位)
--
  gd_sysdate                DATE;             -- システム日付
  gn_user_id                NUMBER;           -- ユーザID
  gn_login_id               NUMBER;           -- 最終更新ログイン
  gn_conc_request_id        NUMBER;           -- 要求ID
  gn_prog_appl_id           NUMBER;           -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
--
  -- プロファイル・オプション
  gv_item_div_prf           VARCHAR2(100);    -- プロファイル「商品区分(セキュリティ)」
--
  -- ブレイク用変数
  gv_pre_order_header_id    xxwsh_order_headers_all.order_header_id%TYPE;
--
  -- 明細適用保持用変数
  gv_line_description       xxwsh_order_lines_all.line_description%TYPE;
--
  -- ===================================
  -- ユーザー定義グローバルカーソル
  -- ===================================
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(H-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_max_date_name CONSTANT VARCHAR2(100) := 'MAX日付';
    lv_min_date_name CONSTANT VARCHAR2(100) := 'MIN日付';
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
    -- システム日付取得
    gd_sysdate := SYSDATE;
    -- WHOカラム情報取得
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ユーザID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- 最終更新ログイン
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- ｺﾝｶﾚﾝﾄ・ﾌﾟﾛｸﾞﾗﾑのｱﾌﾟﾘｹｰｼｮﾝID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- コンカレント・プログラムID
--
    -- ===========================
    -- プロファイルオプション取得
    -- ===========================
--
    -- プロファイル「商品区分」取得
    gv_item_div_prf   := FND_PROFILE.VALUE(gv_item_div_id);
--
    -- =========================================
    -- プロファイルオプション取得エラーチェック
    -- =========================================
--
    IF (gv_item_div_prf IS NULL) THEN 
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10002          -- メッセージ:APP-XXCMN-10002 プロファイル取得エラー
                       ,gv_tkn_ng_profile          -- トークン:NGプロファイル名
                       ,gv_tkn_prod_class_code)    -- XXCMN:商品区分
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --最大日付取得
    gv_max_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10156,
                                            gv_tkn_name,
                                            lv_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --最小日付取得
    gv_min_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),1,10);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10156,
                                            gv_tkn_name,
                                            lv_min_date_name);
      lv_errbuf := lv_errmsg;
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
  /**********************************************************************************
   * Procedure Name   : check_can_enc_qty
   * Description      : 引当可能数チェック処理(H-2)
   ***********************************************************************************/
  PROCEDURE check_can_enc_qty(
    iv_data_class        IN         VARCHAR2,      -- 1.データ種別
    iv_deliver_from      IN         VARCHAR2,      -- 2.倉庫
    iv_shipped_date_from IN         VARCHAR2,      -- 3.出庫日FROM
    iv_shipped_date_to   IN         VARCHAR2,      -- 4.出庫日TO
    iv_instruction_dept  IN         VARCHAR2,      -- 5.指示部署
    iv_security_kbn      IN         VARCHAR2,      -- 6.セキュリティ区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_can_enc_qty'; -- プログラム名
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
    ln_can_enc_qty           NUMBER;            -- 引当可能数
    ln_check_qty             NUMBER;            -- チェック用変数
    lv_inventory_location_id   xxcmn_item_locations_v.inventory_location_id%TYPE; -- OPM保管倉庫ID
    lv_whse_name               xxcmn_item_locations_v.whse_name%TYPE;             -- 倉庫コード
    lv_item_id                 ic_lots_mst.item_id%TYPE;                          -- 品目ID
    lv_item_no                 xxcmn_item_mst2_v.item_no%TYPE;                    -- 品目コード
    lv_lot_id                  ic_lots_mst.lot_id%TYPE;                           -- ロットID
    lv_lot_no                  ic_lots_mst.lot_no%TYPE;                           -- ロットNo
    lv_shipped_date            xxwsh_order_headers_all.shipped_date%TYPE;         -- 出庫予定日
    lv_item_class_code         xxcmn_item_categories4_v.item_class_code%TYPE;     -- 品目区分
    lv_prod_class_code         xxcmn_item_categories4_v.prod_class_code%TYPE;     -- 商品区分
    lv_conv_unit               xxcmn_item_mst2_v.conv_unit%TYPE;                  -- 入出庫換算単位
    lv_num_of_cases            xxcmn_item_mst2_v.num_of_cases%TYPE;               -- ケース入り数
    lv_sum_reserved_quantity   xxpo_lot_reserve_if.reserved_quantity%TYPE;        -- 引当数量合計
    lv_sum_quantity            xxwsh_order_lines_all.quantity%TYPE;               -- 指示数量合計
--
    -- *** ローカル・カーソル ***
  -- 引当可能数チェックカーソル
    CURSOR chk_can_enc_qty_cur
    IS
      SELECT ilm.item_id                   item_id                -- 品目ID
            ,ximv2.item_no                 item_no                -- 品目コード
            ,ilm.lot_id                    lot_id                 -- ロットID
            ,ilm.lot_no                    lot_no                 -- ロットNo
            ,xlris.sum_reserved_quantity   sum_reserved_quantity  -- 引当数量合計
            ,xlris.inventory_location_id   inventory_location_id  -- 保管倉庫ID
            ,xlris.whse_name               whse_name              -- 倉庫名(メッセージ出力用)
            ,xlris.shipped_date            shipped_date           -- 出荷日
      FROM  (SELECT xlri.item_code
                   ,xlri.lot_no
                   ,xilv.inventory_location_id
                   ,xilv.whse_name
                   ,NVL(xoha.shipped_date, xoha.schedule_ship_date) shipped_date
                   ,SUM(xlri.reserved_quantity) sum_reserved_quantity
             FROM   xxpo_lot_reserve_if        xlri                  -- ロット引当情報IF
                   ,xxwsh_order_headers_all    xoha                  -- 受注ヘッダアドオン
                   ,xxwsh_order_lines_all      xola                  -- 受注明細アドオン
                   ,xxcmn_item_locations2_v    xilv                  -- OPM保管場所情報VIEW2
                   ,xxcmn_item_locations2_v    xilv2                 -- OPM保管場所情報VIEW2
                   ,xxcmn_item_mst2_v          ximv                  -- OPM品目情報VIEW2
             WHERE  xlri.request_no            = xola.request_no(+)
             AND    xlri.item_code             = xola.shipping_item_code(+)
             AND    xola.order_header_id       = xoha.order_header_id
             AND    xoha.deliver_from          = xilv.segment1
             AND    xilv.frequent_whse         = xilv2.segment1(+)
             AND    xlri.data_class            = iv_data_class
             AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
             AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
               OR   xilv.date_to IS NULL)
             AND    xilv.disable_date IS NULL
             AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
               OR   xilv2.date_to IS NULL)
             AND    xilv2.disable_date IS NULL
             AND    xola.delete_flag           = gv_flg_n
             AND    xoha.latest_external_flag  = gv_flg_y
             AND    xilv.segment1              = iv_deliver_from
             AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
             AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
             AND    xoha.instruction_dept      = iv_instruction_dept
             AND   ((iv_security_kbn        = gv_security_kbn_in)   -- セキュリティ区分 1:伊藤園ユーザー
               OR  (((iv_security_kbn       = gv_security_kbn_out)  -- セキュリティ区分 4:東洋埠頭ユーザー
                 AND ((xilv.segment1 IN (             -- ログインユーザーの保管場所と同じ保管場所
                   SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
                   FROM   fnd_user           fu                           -- ユーザーマスタ
                         ,per_all_people_f   papf                         -- 従業員マスタ
                         ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
                   WHERE  -- ** 結合条件 ** --
                          fu.employee_id   = papf.person_id               -- 従業員ID
                          -- ** 抽出条件 ** --
                   AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
                   AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
                   AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
                   AND  ((fu.end_date               IS NULL)              -- 適用終了日
                     OR  (fu.end_date               >= TRUNC(SYSDATE)))
                   AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
                   AND    papf.attribute4            = xilv3.purchase_code))
                OR (xilv.frequent_whse_code IN (   -- ログインユーザーの保管場所を主管倉庫とする保管場所
                   SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
                   FROM   fnd_user           fu                           -- ユーザーマスタ
                         ,per_all_people_f   papf                         -- 従業員マスタ
                         ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
                   WHERE  -- ** 結合条件 ** --
                          fu.employee_id   = papf.person_id               -- 従業員ID
                          -- ** 抽出条件 ** --
                   AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
                   AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
                   AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
                   AND  ((fu.end_date               IS NULL)              -- 適用終了日
                     OR  (fu.end_date               >= TRUNC(SYSDATE)))
                   AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
                   AND    papf.attribute4            = xilv3.purchase_code)))))) 
             AND    xoha.req_status            >= gv_transaction_status_07
             AND    xoha.req_status            < gv_transaction_status_08
             GROUP BY xlri.item_code, xlri.lot_no, xilv.inventory_location_id, xilv.whse_name, xoha.shipped_date, xoha.schedule_ship_date) xlris
          ,xxcmn_item_mst2_v           ximv2                 -- OPM品目情報VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM品目カテゴリ割当情報VIEW4
          ,ic_lots_mst                 ilm                   -- OPMロットマスタ
    WHERE
           xlris.item_code            = ximv2.item_no(+)
    AND    xlris.lot_no               = ilm.lot_no
    AND    ximv2.item_id              = xicv.item_id
    AND    ilm.item_id                = ximv2.item_id
    AND    ximv2.start_date_active    <= xlris.shipped_date
    AND    ximv2.end_date_active      >= xlris.shipped_date;
--
    -- カーソル用レコード
    chk_cur  chk_can_enc_qty_cur%ROWTYPE;
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
--
    -- =========================================
    -- 引当可能数チェック処理
    -- =========================================
    BEGIN
--
      OPEN chk_can_enc_qty_cur;
      FETCH chk_can_enc_qty_cur INTO chk_cur;
      
      WHILE (chk_can_enc_qty_cur%FOUND)
        LOOP
        lv_inventory_location_id   := chk_cur.inventory_location_id;
        lv_whse_name               := chk_cur.whse_name;
        lv_item_id                 := chk_cur.item_id;
        lv_lot_id                  := chk_cur.lot_id;
        lv_item_no                 := chk_cur.item_no;
        lv_lot_no                  := chk_cur.lot_no;
        lv_shipped_date            := chk_cur.shipped_date;
        lv_sum_reserved_quantity   := chk_cur.sum_reserved_quantity;
--
        BEGIN
          SELECT NVL(SUM(xmld.actual_quantity), 0)
          INTO  lv_sum_quantity
          FROM   xxpo_lot_reserve_if        xlri                  -- ロット引当情報IF
                ,xxwsh_order_headers_all    xoha                  -- 受注ヘッダアドオン
                ,xxwsh_order_lines_all      xola                  -- 受注明細アドオン
                ,xxcmn_item_locations2_v    xilv                  -- OPM保管場所情報VIEW2
                ,xxcmn_item_locations2_v    xilv2                 -- OPM保管場所情報VIEW2
                ,xxcmn_item_mst2_v          ximv                  -- OPM品目情報VIEW2
                ,xxinv_mov_lot_details      xmld                  -- 移動ロット詳細アドオン
          WHERE  xlri.request_no            = xola.request_no(+)
          AND    xlri.item_code             = xola.shipping_item_code(+)
          AND    xola.order_line_id         = xmld.mov_line_id
          AND    xola.order_header_id       = xoha.order_header_id
          AND    xoha.deliver_from          = xilv.segment1
          AND    xilv.frequent_whse         = xilv2.segment1(+)
          AND    xlri.data_class            = iv_data_class
          AND    xlri.item_code             = lv_item_no
          AND    xlri.lot_no                = lv_lot_no
          AND    xmld.lot_no                = lv_lot_no
          AND    xilv.inventory_location_id = lv_inventory_location_id
          AND    NVL(xoha.shipped_date, xoha.schedule_ship_date) = lv_shipped_date
          AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
          AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
            OR   xilv.date_to IS NULL)
          AND    xilv.disable_date IS NULL
          AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
            OR   xilv2.date_to IS NULL)
          AND    xilv2.disable_date IS NULL
          AND    xola.delete_flag           = gv_flg_n
          AND    xoha.latest_external_flag  = gv_flg_y
          AND    xilv.segment1              = iv_deliver_from
          AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
          AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
          AND    xoha.instruction_dept      = iv_instruction_dept
          AND   ((iv_security_kbn        = gv_security_kbn_in)   -- セキュリティ区分 1:伊藤園ユーザー
            OR  (((iv_security_kbn       = gv_security_kbn_out)  -- セキュリティ区分 4:東洋埠頭ユーザー
              AND ((xilv.segment1 IN (             -- ログインユーザーの保管場所と同じ保管場所
                SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
                FROM   fnd_user           fu                           -- ユーザーマスタ
                      ,per_all_people_f   papf                         -- 従業員マスタ
                      ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
                WHERE  -- ** 結合条件 ** --
                       fu.employee_id   = papf.person_id               -- 従業員ID
                       -- ** 抽出条件 ** --
                AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
                AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
                AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
                AND  ((fu.end_date               IS NULL)              -- 適用終了日
                  OR  (fu.end_date               >= TRUNC(SYSDATE)))
                AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
                AND    papf.attribute4            = xilv3.purchase_code))
             OR (xilv.frequent_whse_code IN (   -- ログインユーザーの保管場所を主管倉庫とする保管場所
                SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
                FROM   fnd_user           fu                           -- ユーザーマスタ
                      ,per_all_people_f   papf                         -- 従業員マスタ
                      ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
                WHERE  -- ** 結合条件 ** --
                       fu.employee_id   = papf.person_id               -- 従業員ID
                       -- ** 抽出条件 ** --
                AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
                AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
                AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
                AND  ((fu.end_date               IS NULL)              -- 適用終了日
                  OR  (fu.end_date               >= TRUNC(SYSDATE)))
                AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
                AND    papf.attribute4            = xilv3.purchase_code)))))) 
          AND    xoha.req_status            >= gv_transaction_status_07
          AND    xoha.req_status            < gv_transaction_status_08
          GROUP BY xlri.item_code, xlri.lot_no, xilv.inventory_location_id, xoha.shipped_date, xoha.schedule_ship_date;
        EXCEPTION
          WHEN OTHERS THEN
            lv_sum_quantity := 0;
        END;
--
        -- 引当可能数算出
        ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(
                                           lv_inventory_location_id,  -- OPM保管倉庫ID
                                           lv_item_id,                -- OPM品目ID
                                           lv_lot_id,                 -- ロットID
                                           lv_shipped_date);          -- 出庫予定日
--
        -- 集計した引当数量と引当可能数(引当解除分を足しこみ)をチェック
        -- (引当解除分とは、今回移動ロット詳細情報の洗い替えを行う為、受注明細の数量も全部更新されるので、
        --  現在の受注明細の指示数量の合計となる)
        IF (lv_sum_reserved_quantity > ln_can_enc_qty + lv_sum_quantity) THEN
          -- 警告メッセージ出力
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn                 -- モジュール名略称:XXCMN
                           ,gv_msg_xxcmn10109        -- メッセージ:APP-XXCMN-10109 引当可能在庫数超過通知ワーニング
                           ,gv_tkn_location          -- トークン:LOCATION
                           ,lv_whse_name             -- 倉庫名
                           ,gv_tkn_item              -- トークン:ITEM
                           ,lv_item_no               -- 品目コード
                           ,gv_tkn_lot               -- トークン:LOT
                           ,lv_lot_no)               -- ロットID
                           ,1,5000);
--
          -- 警告ダンプPL/SQL表に警告メッセージをセット
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
          -- リターン・コードに警告をセット
          ov_retcode := gv_status_warn;
        END IF;
--
        FETCH chk_can_enc_qty_cur INTO chk_cur;
--
      END LOOP;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- モジュール名略称:XXCMN
                         ,gv_msg_xxcmn10018      -- メッセージ:APP-XXCMN-10018 APIエラー
                         ,gv_tkn_api_name        -- トークンAPI_NAME
                         ,gv_tkn_chk_can_qty)    -- 引当可能数算出
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END check_can_enc_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : データ取得処理 (H-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_data_class        IN         VARCHAR2,      -- 1.データ種別
    iv_deliver_from      IN         VARCHAR2,      -- 2.倉庫
    iv_shipped_date_from IN         VARCHAR2,      -- 3.出庫日FROM
    iv_shipped_date_to   IN         VARCHAR2,      -- 4.出庫日TO
    iv_instruction_dept  IN         VARCHAR2,      -- 5.指示部署
    iv_security_kbn      IN         VARCHAR2,      -- 6.セキュリティ区分
    ov_errbuf            OUT NOCOPY VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode           IN OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    SELECT xlri.lot_reserve_if_id            -- ロット引当情報インタフェースID
          ,xlri.request_no                   -- 依頼No.
          ,xlri.item_code                    -- 品目コード
          ,xlri.line_description             -- 明細摘要
          ,xlri.lot_no                       -- ロットNo.
          ,xlri.reserved_quantity            -- 引当数量
          ,xola.order_line_id                -- 明細ID
          ,xola.quantity                     -- 引当数量合計
          ,ilm.lot_id                        -- ロットID
          ,ximv.item_id                      -- 品目ID
          ,ximv.conv_unit                    -- 入出庫換算単位
          ,ximv.num_of_cases                 -- ケース入り数
          ,xoha.vendor_site_id               -- 配送先ID
          ,xoha.deliver_from                 -- 入力保管倉庫コード
          ,xoha.schedule_arrival_date        -- 着荷予定日
          ,NVL(xoha.shipped_date, xoha.schedule_ship_date) -- 出荷日
          ,xoha.order_header_id              -- 受注ヘッダアドオンID
          ,ilm.attribute1                    -- 製造年月日(OPMロットマスタ)
          ,xicv.prod_class_code              -- 商品区分
          ,xicv.item_class_code              -- 品目区分
          ,xoha.vendor_site_code             -- 配送先コード
          ,xoha.weight_capacity_class        -- 重量容積区分
          ,xoha.shipping_method_code         -- 配送区分
-- ST不具合対応 modify 2008/07/29 start
          ,xoha.freight_charge_class         -- 運賃区分
-- ST不具合対応 modify 2008/07/29 end
-- 2008/08/22 Add ↓
          ,ximv.lot_ctl                      -- ロット
-- 2008/08/22 Add ↑
          ,xlri.corporation_name                || gv_msg_comma ||
           xlri.data_class                      || gv_msg_comma ||
           xlri.transfer_branch_no              || gv_msg_comma ||
           xlri.request_no                      || gv_msg_comma ||
           xlri.item_code                       || gv_msg_comma ||
           xlri.line_description                || gv_msg_comma ||
           xlri.lot_no                          || gv_msg_comma ||
           TO_CHAR(xlri.reserved_quantity)     -- データダンプ
    BULK COLLECT INTO
            gt_lr_lot_reserve_if_id_tbl,
            gt_lr_request_no_tbl,
            gt_lr_item_code_tbl,
            gt_lr_line_description_tbl,
            gt_lr_lot_no_tbl,
            gt_lr_reserved_quantity_tbl,
            gt_lr_order_line_id_tbl,
            gt_lr_quantity_tbl,
            gt_lr_lot_id_tbl,
            gt_lr_item_id_tbl,
            gt_lr_conv_unit_tbl,
            gt_lr_num_of_cases_tbl,
            gt_lr_deliver_to_id_tbl,
            gt_lr_deliver_from_tbl,
            gt_lr_sche_arrival_date_tbl,
            gt_lr_shipped_date_tbl,
            gt_lr_order_header_id_tbl,
            gt_lr_lot_date_tbl,
            gt_lr_prod_class_code_tbl,
            gt_lr_item_class_code_tbl,
            gt_lr_deliver_to_tbl,
            gt_lr_we_ca_class_tbl,
            gt_lr_shipping_method_code_tbl,
-- ST不具合対応 modify 2008/07/29 start
            gt_lr_freight_charge_class_tbl,
-- ST不具合対応 modify 2008/07/29 end
-- 2008/08/22 Add ↓
            gt_lr_lot_ctl_tbl,
-- 2008/08/22 Add ↑
            gt_lr_data_dump_tbl
    FROM   xxpo_lot_reserve_if         xlri                  -- ロット引当情報インタフェース
          ,xxwsh_order_headers_all     xoha                  -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all       xola                  -- 受注明細アドオン
          ,xxcmn_item_mst2_v           ximv                  -- OPM品目情報VIEW2
          ,xxcmn_item_mst2_v           ximv2                 -- OPM品目情報VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_locations2_v     xilv                  -- OPM保管場所情報VIEW2
          ,xxcmn_item_locations2_v     xilv2                 -- OPM保管場所情報VIEW2
          ,ic_lots_mst                 ilm                   -- OPMロットマスタ
-- 2008/08/22 Mod ↓
/*
    WHERE
    -- ** 結合条件 ** --
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id
    AND    xoha.deliver_from          = xilv.segment1
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.start_date_active   <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.end_date_active     >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv.date_to IS NULL)
    AND    xilv.disable_date IS NULL
    AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv2.date_to IS NULL)
    AND    xilv2.disable_date IS NULL
    -- ** 抽出条件 ** --
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    xlri.data_class            = iv_data_class
    AND    xilv.segment1              = iv_deliver_from
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
    AND    xoha.instruction_dept      = iv_instruction_dept
    AND   ((iv_security_kbn        = gv_security_kbn_in)   -- セキュリティ区分 1:伊藤園ユーザー
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- セキュリティ区分 4:東洋埠頭ユーザー
        AND ((xilv.segment1 IN (             -- ログインユーザーの保管場所と同じ保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ログインユーザーの保管場所を主管倉庫とする保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code)))))) 
    AND    xoha.req_status            >= gv_transaction_status_07
    AND    xoha.req_status            < gv_transaction_status_08
*/
    WHERE
    -- ** 結合条件 ** --
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id(+)
    AND    xoha.deliver_from          = xilv.segment1(+)
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id(+)
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND   (xola.request_no IS NULL
     OR    (ximv.start_date_active    <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     ximv.end_date_active      >= NVL(xoha.shipped_date, xoha.schedule_ship_date)))
    AND   (xola.request_no IS NULL
     OR    (ximv2.start_date_active   <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     ximv2.end_date_active     >= NVL(xoha.shipped_date, xoha.schedule_ship_date)))
    AND   (xola.request_no IS NULL
     OR    (xilv.date_from            <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     (xilv.date_to             >= NVL(xoha.shipped_date, xoha.schedule_ship_date)
      OR    xilv.date_to IS NULL)
    AND     xilv.disable_date IS NULL))
    AND   (xola.request_no IS NULL
     OR    (xilv2.date_from           <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     (xilv2.date_to            >= NVL(xoha.shipped_date, xoha.schedule_ship_date)
      OR    xilv2.date_to IS NULL)
    AND     xilv2.disable_date IS NULL))
    -- ** 抽出条件 ** --
    AND   (xola.request_no IS NULL
     OR    xola.delete_flag           = gv_flg_n)
    AND   (xola.request_no IS NULL
     OR    xoha.latest_external_flag  = gv_flg_y)
    AND    xlri.data_class            = iv_data_class
    AND   (xola.request_no IS NULL
     OR    xilv.segment1              = iv_deliver_from)
    AND   (xola.request_no IS NULL
     OR    NVL(xoha.shipped_date, xoha.schedule_ship_date) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss))
    AND   (xola.request_no IS NULL
     OR    NVL(xoha.shipped_date, xoha.schedule_ship_date) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss))
    AND   (xola.request_no IS NULL
     OR    xoha.instruction_dept      = iv_instruction_dept)
    AND   (xola.request_no IS NULL
     OR   ((iv_security_kbn        = gv_security_kbn_in)   -- セキュリティ区分 1:伊藤園ユーザー
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- セキュリティ区分 4:東洋埠頭ユーザー
        AND ((xilv.segment1 IN (             -- ログインユーザーの保管場所と同じ保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ログインユーザーの保管場所を主管倉庫とする保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code)))))))
    AND   (xola.request_no IS NULL
     OR    xoha.req_status  >= gv_transaction_status_07)
    AND   (xola.request_no IS NULL
     OR    xoha.req_status  < gv_transaction_status_08)
-- 2008/08/22 Mod ↑
    ORDER BY xoha.order_header_id, xola.order_line_id, xlri.lot_no
    FOR UPDATE OF xoha.order_header_id, xola.order_line_id, xlri.lot_reserve_if_id NOWAIT;
--
    -- 処理件数カウント
    gn_target_cnt := gt_lr_lot_reserve_if_id_tbl.COUNT;
--
    -- データ取得エラー
    IF (gt_lr_lot_reserve_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10229);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================
    --移動ロット詳細ロック処理
    --=========================
    SELECT   xmld.mov_lot_dtl_id
    BULK COLLECT INTO
           gt_mr_mov_lot_dtl_id_tbl
    FROM   xxpo_lot_reserve_if         xlri                  -- ロット引当情報インタフェース
          ,xxwsh_order_headers_all     xoha                  -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all       xola                  -- 受注明細アドオン
          ,xxcmn_item_mst2_v           ximv                  -- OPM品目情報VIEW2
          ,xxcmn_item_mst2_v           ximv2                 -- OPM品目情報VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_locations2_v     xilv                  -- OPM保管場所情報VIEW2
          ,xxcmn_item_locations2_v     xilv2                 -- OPM保管場所情報VIEW2
          ,ic_lots_mst                 ilm                   -- OPMロットマスタ
          ,xxinv_mov_lot_details       xmld                  -- 移動ロット詳細アドオン
    WHERE
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id
    AND    xoha.deliver_from          = xilv.segment1
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.start_date_active   <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.end_date_active     >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv.date_to IS NULL)
    AND    xilv.disable_date IS NULL
    AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv2.date_to IS NULL)
    AND    xilv2.disable_date IS NULL
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    xlri.data_class            = iv_data_class
    AND    xilv.segment1              = iv_deliver_from
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
    AND    xoha.instruction_dept      = iv_instruction_dept
    AND   ((iv_security_kbn        = gv_security_kbn_in)   -- セキュリティ区分 1:伊藤園ユーザー
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- セキュリティ区分 4:東洋埠頭ユーザー
        AND ((xilv.segment1 IN (             -- ログインユーザーの保管場所と同じ保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ログインユーザーの保管場所を主管倉庫とする保管場所
              SELECT xilv3.segment1    segment1                      -- 取引先コード(仕入先コード)
              FROM   fnd_user           fu                           -- ユーザーマスタ
                    ,per_all_people_f   papf                         -- 従業員マスタ
                    ,xxcmn_item_locations2_v xilv3                   -- OPM保管場所情報VIEW2
              WHERE  -- ** 結合条件 ** --
                     fu.employee_id   = papf.person_id               -- 従業員ID
                     -- ** 抽出条件 ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- 適用開始日
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- 適用終了日
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- 適用開始日
              AND  ((fu.end_date               IS NULL)              -- 適用終了日
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ユーザーID
              AND    papf.attribute4            = xilv3.purchase_code)))))) 
    AND    xoha.req_status            >= gv_transaction_status_07
    AND    xoha.req_status            < gv_transaction_status_08
    AND    xmld.mov_line_id           = xola.order_line_id
    FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
  EXCEPTION
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
    -- ロックエラー
    WHEN check_lock_expt THEN
      -- エラーメッセージ取得
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- モジュール名略称:XXCMN
                       ,gv_msg_xxcmn10019      -- メッセージ:APP-XXCMN-10019 ロックエラー
                       ,gv_tkn_table           -- トークンTABLE
                       ,gv_tkn_date)           -- "対象データ"
                       ,1,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : 取得データチェック処理(H-4)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- プログラム名    -- テーブル(ビュー)名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_errmsg_code     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ・コード
    on_result          NUMBER;          -- 処理結果
    od_reversal_date   DATE;            -- 逆転日付
    od_standard_date   DATE;            -- 基準日付
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_cnt NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
    ln_cnt     := 0;
--
--###########################  固定部 END   ############################
--
-- 2008/08/22 Del ↓
/*
    -- ===========================
    -- 引当情報不足チェック
    -- ===========================
    -- 本来必須であるロットNoが、依頼No.、品目コードの紐付きでとれなかった場合、
    -- ロット引当情報IFテーブルに受注明細の全ての情報が設定されていないと判断し、エラーとする。
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha
          ,xxwsh_order_lines_all   xola
          ,xxpo_lot_reserve_if     xlri
    WHERE  xoha.request_no         = gt_lr_request_no_tbl(gn_i)  -- 依頼No.
    AND    xoha.order_header_id    = xola.order_header_id        -- 受注ヘッダID
    AND    xola.request_no         = xlri.request_no(+)          -- 依頼No.
    AND    xola.shipping_item_code = xlri.item_code(+)           -- 品目コード
    AND    xlri.lot_no             IS NULL                       -- ロットNo
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    ROWNUM                  = 1
    ;
--
    -- 1件以上の場合、エラー
    IF (ln_cnt > 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10262     -- メッセージ:APP-XXPO-10234 引当情報不足エラー
                       ,gv_tkn_item          -- トークン:ITEM
                       ,gt_lr_request_no_tbl(gn_i))    -- 受注ヘッダアドオン
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
*/
-- 2008/08/22 Del ↑
    -- ===========================
    -- 受注ヘッダアドオン存在チェック
    -- ===========================
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha  -- 受注ヘッダアドオン
    WHERE  xoha.request_no = gt_lr_request_no_tbl(gn_i)          -- 依頼No.
    AND    ROWNUM         = 1
    ;
    -- 0件の場合、エラー
    IF (ln_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10234     -- メッセージ:APP-XXPO-10234 存在チェックエラー
                       ,gv_tkn_table          -- トークン:TABLE
                       ,gv_tkn_xxpo_headers_all)    -- 受注ヘッダアドオン
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- ===========================
    -- 受注明細アドオン存在チェック
    -- ===========================
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_lines_all xola  -- 受注明細アドオン
    WHERE  xola.request_no = gt_lr_request_no_tbl(gn_i)          -- 依頼No.
    AND    xola.shipping_item_code = gt_lr_item_code_tbl(gn_i)           -- 品目コード
    AND    ROWNUM         = 1
    ;
    -- 0件の場合、エラー
    IF (ln_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10234       -- メッセージ:APP-XXPO-10234 存在チェックエラー
                       ,gv_tkn_table           -- トークン:TABLE
                       ,gv_tkn_xxpo_lines_all) -- 受注明細アドオン
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
-- 2008/08/22 Add ↓
    -- ===========================
    -- 引当情報不足チェック
    -- ===========================
    -- 本来必須であるロットNoが、依頼No.、品目コードの紐付きでとれなかった場合、
    -- ロット引当情報IFテーブルに受注明細の全ての情報が設定されていないと判断し、エラーとする。
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha
          ,xxwsh_order_lines_all   xola
          ,xxpo_lot_reserve_if     xlri
    WHERE  xoha.request_no         = gt_lr_request_no_tbl(gn_i)  -- 依頼No.
    AND    xoha.order_header_id    = xola.order_header_id        -- 受注ヘッダID
    AND    xola.request_no         = xlri.request_no(+)          -- 依頼No.
    AND    xola.shipping_item_code = xlri.item_code(+)           -- 品目コード
    AND    xlri.lot_no             IS NULL                       -- ロットNo
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    ROWNUM                  = 1
    ;
--
    -- 1件以上の場合、エラー
    IF (ln_cnt > 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10262     -- メッセージ:APP-XXPO-10234 引当情報不足エラー
                       ,gv_tkn_item          -- トークン:ITEM
                       ,gt_lr_request_no_tbl(gn_i))    -- 受注ヘッダアドオン
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
-- 2008/08/22 Add ↑
--
-- 2008/08/22 Add ↓
    -- ロット管理品の場合
    IF (gt_lr_lot_ctl_tbl(gn_i) = gv_flg_on) THEN
      -- ===========================
      -- ロットステータスチェック
      -- ===========================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   ic_lots_mst           ilm,     -- ロットマスタ
             xxcmn_lot_status_v    xlsv     -- ロットステータスビュー
      WHERE  xlsv.lot_status(+)           = ilm.attribute23
      AND    ilm.lot_id                   = gt_lr_lot_id_tbl(gn_i)
      AND    ilm.attribute1              >= gt_lr_lot_date_tbl(gn_i)   -- 指定製造日
      AND    xlsv.pay_provision_m_reserve = gv_flg_y                   -- 有償支給(手動引当)
      AND    ROWNUM         = 1
      ;
      -- 0件の場合、エラー
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        gv_xxpo                  -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10267         -- メッセージ:APP-XXPO-10267 ロットステータスエラー
                       ,gv_tkn_lot_no            -- トークン:LOT_NO
                       ,gt_lr_lot_no_tbl(gn_i)); -- ロットNo
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      END IF;
    END IF;
-- 2008/08/22 Add ↑
--
    -- ===========================
    -- 引当数量チェック(0、マイナスチェック)
    -- ===========================
    IF (gt_lr_reserved_quantity_tbl(gn_i) <= 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- モジュール名略称:XXPO
                       ,gv_msg_xxpo10255       -- メッセージ:APP-XXPO-10255 数値0以下エラー
                       ,gv_tkn_item            -- トークン:ITEM
                       ,gv_tkn_reserve_qty)    -- 引当数量
                       ,1,5000);
      lv_errbuf := lv_errmsg;
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
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : 関連データ取得処理(H-5)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    iv_type       IN  VARCHAR2,     --   ヘッダ/明細区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- プログラム名
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
    ln_result             NUMBER;               -- 「最大配送区分算出関数」返り値
    lv_errmsg_code        VARCHAR2(5000);       -- エラーメッセージコード
    ln_small_quantity     NUMBER;               -- 小口個数
    ln_sum_quantity       NUMBER;               -- 引当数量合計
    -- 未使用
    ln_palette_max_qty              NUMBER;        -- パレット最大枚数
    ln_drink_deadweight_tbl         NUMBER;        -- ドリンク積載重量
    ln_leaf_deadweight_tbl          NUMBER;        -- リーフ積載重量
    ln_drink_loading_capacity_tbl   NUMBER;        -- ドリンク積載容積
    ln_leaf_loading_capacity_tbl    NUMBER;        -- リーフ積載容積
    ln_sum_pallet_weight            NUMBER;        -- 合計パレット重量
    ln_sum_weight                   NUMBER;        -- 合計重量
    ln_sum_capacity                 NUMBER;        -- 合計容積
    lv_load_efficiency_we           NUMBER;        -- 重量積載効率
    lv_load_efficiency_ca           NUMBER;        -- 容積積載効率
    lv_loading_over_class           VARCHAR2(100); -- 積載オーバー区分
    lv_ship_methods                 VARCHAR2(100); -- 出荷方法
    lv_mixed_ship_method            VARCHAR2(100); -- 混載配送区分
    lv_small_amount_class           VARCHAR2(1);   -- 小口区分
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
    ln_result         := NULL;
    lv_retcode        := NULL;
    lv_errmsg_code    := NULL;
    lv_errmsg         := NULL;
    ln_small_quantity := NULL;
    ln_sum_quantity   := NULL;

--
    IF (iv_type = gv_header) THEN
      -- ST不具合 modify 2008/07/29 start
      -- 運賃区分がONの場合のみ、取得。
      IF (gt_lr_freight_charge_class_tbl(gn_i) = gv_freight_charge_class_on) THEN
        ---------------------------------------------
        -- 最大配送区分取得                        --
        ---------------------------------------------
        -- 共通関数「最大配送区分算出関数」呼び出し
        ln_result := xxwsh_common_pkg.get_max_ship_method
                               (cv_wh,                                      -- 倉庫'4'
                                gt_lr_deliver_from_tbl(gn_i),               -- 入力倉庫コード
                                cv_sup,                                     -- 支給先'11'
                                gt_lr_deliver_to_tbl(gn_i),                 -- 配送先コード
                                gv_item_div_prf,                            -- 商品区分
                                gt_lr_we_ca_class_tbl(gn_i),                -- 重量容積区分
                                NULL,                                       -- 自動配車対象区分
                                gt_lr_shipped_date_tbl(gn_i),               -- 出庫予定日
                                gt_ship_method_tbl(gn_k),                   -- 最大配送区分
                                ln_drink_deadweight_tbl,                    -- ドリンク積載重量
                                ln_leaf_deadweight_tbl,                     -- リーフ積載重量
                                ln_drink_loading_capacity_tbl,              -- ドリンク積載容積
                                ln_leaf_loading_capacity_tbl,               -- リーフ積載容積
                                ln_palette_max_qty                          -- パレット最大枚数
                               );
--
        -- 共通関数でエラーの場合
        IF (ln_result = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                                gv_msg_xxpo10237,
                                                gv_tkn_common_name,
                                                gv_max_ship);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- 不要の為、削除
      /*-- 小口区分の設定
      BEGIN
        SELECT attribute6
        INTO   lv_small_amount_class
        FROM   xxcmn_lookup_values2_v
        WHERE  lookup_type = gv_lookup_type_xsm
        AND    lookup_code = gt_ship_method_tbl(gn_k);
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                                gv_msg_xxpo10234,
                                                gv_tkn_table,
                                                gv_tkn_xxcmn_lookup_values2);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      gt_small_amount_class_tbl(gn_k) := lv_small_amount_class;*/
-- ST不具合対応 modify 2008/07/29 end
--
      -- 変数の初期化(内部ロジック用)
      gt_ph_sum_weight_tbl(gn_k)        := NULL;
      gt_ph_sum_capacity_tbl(gn_k)      := NULL;
      gt_ph_sum_pallet_weight_tbl(gn_k) := NULL;
      gt_ph_small_quantity_tbl(gn_k)    := NULL;
      gt_ph_label_quantity_tbl(gn_k)    := NULL;
      gt_ph_sum_quantity_tbl(gn_k)      := NULL;
--
      -- 指示数量更新フラグの初期設定(ヘッダ用)
      gt_ph_up_flg(gn_k) := gv_flg_off;
--
    ELSIF (iv_type = gv_line) THEN
      -- 指示数量更新フラグの設定
      IF (gn_lot_sum <> gt_lr_quantity_tbl(gn_i)) THEN
        gt_ph_up_flg(gn_k) := gv_flg_on;
        gt_pl_up_flg(gn_j) := gv_flg_on;
        -- 指示数量の設定
        ln_sum_quantity    := gn_lot_sum;
      ELSE
        gt_pl_up_flg(gn_j) := gv_flg_off;
        -- 指示数量の設定
        ln_sum_quantity    := gt_lr_quantity_tbl(gn_i);
      END IF;
--
      ---------------------------------------------
      -- 合計重量･合計容積取得                   --
      ---------------------------------------------
      -- 「積載効率チェック(合計値算出)」呼び出し
      xxwsh_common910_pkg.calc_total_value
                            (
                             gt_lr_item_code_tbl(gn_i),            -- 品目コード
                             ln_sum_quantity,                      -- 引当数量合計
                             lv_retcode,                           -- リターンコード
                             lv_errmsg_code,                       -- エラーメッセージコード
                             lv_errmsg,                            -- エラーメッセージ
                             gt_pl_weight_tbl(gn_j),               -- 合計重量
                             gt_pl_capacity_tbl(gn_j),             -- 合計容積
                             gt_pl_pallet_weight_tbl(gn_j)         -- 合計パレット重量
                            );
--
      -- 共通関数でエラーの場合
      IF (lv_retcode = '1') THEN
        -- エラーログ出力
        xxcmn_common_pkg.put_api_log(
          lv_errbuf     -- エラー・メッセージ
         ,lv_retcode    -- リターン・コード
         ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
        -- エラーメッセージ取得
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                     -- モジュール名略称:XXPO
                         ,gv_msg_xxpo10237            -- メッセージ:APP-XXPO-10237 共通関数エラー
                         ,gv_tkn_common_name          -- トークンNG_NAME
                         ,gv_tkn_calc_total_value)    -- 積載効率チェック(合計値算出)
                         ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- 総合計重量
      gt_ph_sum_weight_tbl(gn_k) :=
        NVL(gt_ph_sum_weight_tbl(gn_k), 0) + NVL(gt_pl_weight_tbl(gn_j), 0);
--
      -- 総合計容積
      gt_ph_sum_capacity_tbl(gn_k) :=
        NVL(gt_ph_sum_capacity_tbl(gn_k), 0) + NVL(gt_pl_capacity_tbl(gn_j), 0);
--
      -- 総パレット重量
      gt_ph_sum_pallet_weight_tbl(gn_k) :=
        NVL(gt_ph_sum_pallet_weight_tbl(gn_k), 0) + NVL(gt_pl_pallet_weight_tbl(gn_j), 0);
--
      ---------------------------------------------
      -- 配車関連情報の算出                      --
      ---------------------------------------------
      -- 小口個数
      -- 入出庫換算単位が設定されていて、ケース入数がNULL若しくは0でない場合
      -- 内部課題#32,66 2008/07/22 modify start
      --IF (
      --     (gt_lr_conv_unit_tbl(gn_i) IS NOT NULL) AND
      --     (gt_lr_num_of_cases_tbl(gn_i) IS NOT NULL) AND
      --     (gt_lr_num_of_cases_tbl(gn_i) <> '0')
      --   ) THEN
      --  ln_small_quantity :=
      --    ROUND(TO_NUMBER(ln_sum_quantity / gt_lr_num_of_cases_tbl(gn_i)));
      --ELSE
      --  ln_small_quantity := ln_sum_quantity;
      --END IF;
      -- 入出庫換算単位がNULLでない場合
      IF (gt_lr_conv_unit_tbl(gn_i) IS NOT NULL) THEN
        -- ケース入り数が0より大きい場合
        IF (gt_lr_num_of_cases_tbl(gn_i) > 0) THEN
          -- ケース入り数を加味した換算を行う。
          ln_small_quantity := CEIL(TO_NUMBER(ln_sum_quantity / gt_lr_num_of_cases_tbl(gn_i)));
        ELSIF (gt_lr_num_of_cases_tbl(gn_i) = 0
            OR gt_lr_num_of_cases_tbl(gn_i) IS NULL) THEN
          -- エラーメッセージ取得
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn                   -- モジュール名略称:XXCMN
                           ,gv_msg_xxcmn10604          -- メッセージ:APP-XXCMN-10604 ケース入数エラー
                           ,gv_tkn_request_no
                           ,gt_lr_request_no_tbl(gn_i)
                           ,gv_tkn_item_no
                           ,gt_lr_item_code_tbl(gn_i))
                           ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE
        ln_small_quantity := ln_sum_quantity;
      END IF;
      -- 内部課題#32,66 2008/07/22 modify end
--
      gt_ph_small_quantity_tbl(gn_k) :=
        NVL(gt_ph_small_quantity_tbl(gn_k), 0) + ln_small_quantity;
--
      -- ラベル枚数
      gt_ph_label_quantity_tbl(gn_k) :=
       NVL(gt_ph_label_quantity_tbl(gn_k), 0) + ln_small_quantity;
--
      -- 合計数量
      gt_pl_quantity_tbl(gn_j)          := NVL(ln_sum_quantity, 0);
      gt_pl_reserved_quantity_tbl(gn_j) := NVL(ln_sum_quantity, 0);
      gt_ph_sum_quantity_tbl(gn_k)      :=
       NVL(gt_ph_sum_quantity_tbl(gn_k), 0) +  NVL(ln_sum_quantity, 0);
--
      -- 明細が最終レコードか、同一ヘッダIDの最終レコードの場合実行する。
      IF (
           (gt_lr_lot_reserve_if_id_tbl.COUNT  = gn_i) OR
           (gt_lr_order_header_id_tbl(gn_i) <> gt_lr_order_header_id_tbl(gn_i + 1))
         ) THEN
--
        -- ST不具合 modify 2008/07/29 start
        -- 運賃区分がONの場合のみ、取得。
        IF (gt_lr_freight_charge_class_tbl(gn_i) = gv_freight_charge_class_on) THEN
          ---------------------------------------------
          -- 積載効率算出                            --
          ---------------------------------------------
          -- 積載重量合計
          ln_sum_weight := gt_ph_sum_weight_tbl(gn_k);
          -- 積載容積合計
          ln_sum_capacity := gt_ph_sum_capacity_tbl(gn_k);
--
        -- 内部変更#166 2008/07/22 modify start
          -- 重量の積載効率を取得する
          IF (gt_lr_we_ca_class_tbl(gn_i) = gv_we) THEN
--
            -- 「積載効率チェック(積載効率算出)」呼び出し
            xxwsh_common910_pkg.calc_load_efficiency
                                (
                                  ln_sum_weight,                          -- 合計重量
                                  NULL,                                   -- 合計容積
                                  cv_wh,                                  -- 倉庫'4'
                                  gt_lr_deliver_from_tbl(gn_i),           -- 出庫倉庫コード
                                  cv_sup,                                 -- 支給先'11'
                                  gt_lr_deliver_to_tbl(gn_i),             -- 配送先コード
                                  gt_ship_method_tbl(gn_k),               -- 配送区分
                                  gv_item_div_prf,                        -- 商品区分
                                  NULL,                                   -- 自動配車対象区分
                                  TRUNC(SYSDATE),                         -- 基準日
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
               -- エラーログ出力
               xxcmn_common_pkg.put_api_log(
                 lv_errbuf     -- エラー・メッセージ
                ,lv_retcode    -- リターン・コード
                ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
              -- エラーメッセージ取得
              lv_errmsg  := SUBSTRB(
                              xxcmn_common_pkg.get_msg(
                                gv_xxpo                   -- モジュール名略称:XXPO
                               ,gv_msg_xxpo10237          -- メッセージ:APP-XXPO-10237 共通関数エラー
                               ,gv_tkn_common_name        -- トークンNG_NAME
                               ,gv_tkn_calc_load_ef_we)   -- 積載効率チェック(積載効率算出:重量)
                               ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
            -- 積載オーバーの場合
            IF (lv_loading_over_class = gv_flg_on) THEN
              -- エラーログ出力
              xxcmn_common_pkg.put_api_log(
               ov_errbuf     => lv_errbuf     -- エラー・メッセージ
              ,ov_retcode    => lv_retcode    -- リターン・コード
              ,ov_errmsg     => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
              -- エラーメッセージ取得
              lv_errmsg  := SUBSTRB(
                             xxcmn_common_pkg.get_msg(
                               gv_xxpo               -- モジュール名略称:XXPO
                              ,gv_msg_xxpo10120)     -- メッセージ:APP-XXPO-10120 積載効率チェックエラー
                              ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
          -- 容積の積載効率を取得する
          ELSIF (gt_lr_we_ca_class_tbl(gn_i) = gv_ca) THEN
--
            -- 「積載効率チェック(積載効率算出)」呼び出し
            xxwsh_common910_pkg.calc_load_efficiency
                                (
                                  NULL,                                   -- 合計重量
                                  ln_sum_capacity,                        -- 合計容積
                                  cv_wh,                                  -- 倉庫'4'
                                  gt_lr_deliver_from_tbl(gn_i),           -- 出庫倉庫コード
                                  cv_sup,                                 -- 支給先'11'
                                  gt_lr_deliver_to_tbl(gn_i),             -- 配送先コード
                                  gt_ship_method_tbl(gn_k),               -- 配送区分
                                  gv_item_div_prf,                        -- 商品区分
                                  NULL,                                   -- 自動配車対象区分
                                  TRUNC(SYSDATE),                         -- 基準日
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
              -- エラーログ出力
              xxcmn_common_pkg.put_api_log(
                lv_errbuf     -- エラー・メッセージ
               ,lv_retcode    -- リターン・コード
               ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
              -- エラーメッセージ取得
              lv_errmsg  := SUBSTRB(
                              xxcmn_common_pkg.get_msg(
                                gv_xxpo                   -- モジュール名略称:XXPO
                               ,gv_msg_xxpo10237          -- メッセージ::APP-XXPO-10237 共通関数エラー
                               ,gv_tkn_common_name        -- トークンNG_NAME
                               ,gv_tkn_calc_load_ef_ca)   -- 積載効率チェック(積載効率算出:容積)
                               ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
            -- 積載オーバーの場合
            IF (lv_loading_over_class = gv_flg_on) THEN
              -- エラーログ出力
              xxcmn_common_pkg.put_api_log(
               ov_errbuf     => lv_errbuf     -- エラー・メッセージ
              ,ov_retcode    => lv_retcode    -- リターン・コード
              ,ov_errmsg     => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
              -- エラーメッセージ取得
              lv_errmsg  := SUBSTRB(
                             xxcmn_common_pkg.get_msg(
                               gv_xxpo               -- モジュール名略称:XXPO
                              ,gv_msg_xxpo10120)     -- メッセージ:APP-XXPO-10120 積載効率チェックエラー
                              ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
          END IF;
--
          -- 「積載効率チェック(積載効率算出)」呼び出し
          xxwsh_common910_pkg.calc_load_efficiency
                              (
                                ln_sum_weight,                        -- 合計重量
                                NULL,                                 -- 合計容積
                                cv_wh,                                -- 倉庫'4'
                                gt_lr_deliver_from_tbl(gn_i),         -- 出庫倉庫コード
                                cv_sup,                               -- 支給先'11'
                                gt_lr_deliver_to_tbl(gn_i),           -- 配送先コード
                                gt_lr_shipping_method_code_tbl(gn_i), -- 配送区分
                                gv_item_div_prf,                      -- 商品区分
                                NULL,                                 -- 自動配車対象区分
                                TRUNC(SYSDATE),                       -- 基準日
                                lv_retcode,                           -- リターンコード
                                lv_errmsg_code,                       -- エラーメッセージコード
                                lv_errmsg,                            -- エラーメッセージ
                                lv_loading_over_class,                -- 積載オーバー区分
                                lv_ship_methods,                      -- 出荷方法
                                gt_ph_load_efficiency_we_tbl(gn_k),   -- 重量積載効率
                                lv_load_efficiency_ca,                -- 容積積載効率
                                lv_mixed_ship_method                  -- 混載配送区分
                              );
--
          -- 共通関数でエラーの場合
          IF (lv_retcode = '1') THEN
            -- エラーログ出力
            xxcmn_common_pkg.put_api_log(
              lv_errbuf     -- エラー・メッセージ
             ,lv_retcode    -- リターン・コード
             ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
            -- エラーメッセージ取得
            lv_errmsg  := SUBSTRB(
                            xxcmn_common_pkg.get_msg(
                              gv_xxpo                   -- モジュール名略称:XXPO
                             ,gv_msg_xxpo10237          -- メッセージ::APP-XXPO-10237 共通関数エラー
                             ,gv_tkn_common_name        -- トークンNG_NAME
                             ,gv_tkn_calc_load_ef_we)   -- 積載効率チェック(積載効率算出:重量)
                             ,1,5000);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- 「積載効率チェック(積載効率算出)」呼び出し
          xxwsh_common910_pkg.calc_load_efficiency
                              (
                                NULL,                                 -- 合計重量
                                ln_sum_capacity,                      -- 合計容積
                                cv_wh,                                -- 倉庫'4'
                                gt_lr_deliver_from_tbl(gn_i),         -- 出庫倉庫コード
                                cv_sup,                               -- 支給先'11'
                                gt_lr_deliver_to_tbl(gn_i),           -- 配送先コード
                                gt_lr_shipping_method_code_tbl(gn_i), -- 配送区分
                                gv_item_div_prf,                      -- 商品区分
                                NULL,                                 -- 自動配車対象区分
                                TRUNC(SYSDATE),                       -- 基準日
                                lv_retcode,                           -- リターンコード
                                lv_errmsg_code,                       -- エラーメッセージコード
                                lv_errmsg,                            -- エラーメッセージ
                                lv_loading_over_class,                -- 積載オーバー区分
                                lv_ship_methods,                      -- 出荷方法
                                lv_load_efficiency_we,                -- 重量積載効率
                                gt_ph_load_efficiency_ca_tbl(gn_k),   -- 容積積載効率
                                lv_mixed_ship_method                  -- 混載配送区分
                              );
--
          -- 共通関数でエラーの場合
          IF (lv_retcode = '1') THEN
            -- エラーログ出力
            xxcmn_common_pkg.put_api_log(
              lv_errbuf     -- エラー・メッセージ
             ,lv_retcode    -- リターン・コード
             ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
            -- エラーメッセージ取得
            lv_errmsg  := SUBSTRB(
                            xxcmn_common_pkg.get_msg(
                              gv_xxpo                   -- モジュール名略称:XXPO
                             ,gv_msg_xxpo10237          -- メッセージ:APP-XXPO-10237 共通関数エラー
                             ,gv_tkn_common_name        -- トークンNG_NAME
                             ,gv_tkn_calc_load_ef_ca)   -- 積載効率チェック(積載効率算出:容積)
                             ,1,5000);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        -- 内部変更#166 2008/07/22 modify end
--
        ELSE
          -- 運賃区分OFFの場合、積載効率にNULLを設定する。
          gt_ph_load_efficiency_we_tbl(gn_k) := NULL;
          gt_ph_load_efficiency_ca_tbl(gn_k) := NULL;
--
        END IF;
        -- ST不具合 modify 2008/07/29 end
--
      END IF;
--
    END IF;
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
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_lot_details
   * Description      : 移動ロット詳細(アドオン)登録処理(H-6)
   ***********************************************************************************/
  PROCEDURE ins_mov_lot_details(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,     --   リターン・コード          --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_lot_details'; -- プログラム名
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
    ln_count   NUMBER;           -- カウント変数
    ln_pm_cont   NUMBER;         -- カウント変数
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象データを洗い替えする為、削除する。
    FORALL ln_count IN gt_pm_mov_lot_dtl_id_tbl.FIRST .. gt_pm_mov_lot_dtl_id_tbl.LAST
      DELETE xxinv_mov_lot_details xmld      -- 移動ロット詳細
      WHERE  xmld.mov_line_id = gt_pm_mov_line_id_tbl(ln_count)
      AND    xmld.document_type_code = gt_pm_document_type_code_tbl(ln_count)
      AND    xmld.record_type_code = gt_pm_record_type_code_tbl(ln_count);
--
    ---------------------------------------------
    -- 移動ロット詳細登録処理                  --
    ---------------------------------------------
    -- 移動ロット詳細アドオンテーブルへ登録するレコードへ値をセット
    FORALL ln_pm_cont IN gt_pm_mov_lot_dtl_id_tbl.FIRST .. gt_pm_mov_lot_dtl_id_tbl.LAST
      INSERT INTO xxinv_mov_lot_details
                 (mov_lot_dtl_id,
                  mov_line_id,
                  document_type_code,
                  record_type_code,
                  item_id,
                  item_code,
                  lot_id,
                  lot_no,
                  actual_date,
                  actual_quantity,
                  automanual_reserve_class,
                  created_by,
                  creation_date,
                  last_updated_by,
                  last_update_date,
                  last_update_login,
                  request_id,
                  program_application_id,
                  program_id,
                  program_update_date)
      VALUES     (
                  gt_pm_mov_lot_dtl_id_tbl(ln_pm_cont),
                  gt_pm_mov_line_id_tbl(ln_pm_cont),
                  gt_pm_document_type_code_tbl(ln_pm_cont),
                  gt_pm_record_type_code_tbl(ln_pm_cont),
                  gt_pm_item_id_tbl(ln_pm_cont),
                  gt_pm_item_code_tbl(ln_pm_cont),
                  gt_pm_lot_id_tbl(ln_pm_cont),
                  gt_pm_lot_no_tbl(ln_pm_cont),
                  gt_pm_actual_date_tbl(ln_pm_cont),
                  gt_pm_actual_quantity_tbl(ln_pm_cont),
                  gt_pm_auma_reserve_class_tbl(ln_pm_cont),
                  gt_pm_created_by_tbl(ln_pm_cont),
                  gt_pm_creation_date_tbl(ln_pm_cont),
                  gt_pm_last_updated_by_tbl(ln_pm_cont),
                  gt_pm_last_update_date_tbl(ln_pm_cont),
                  gt_pm_last_update_login_tbl(ln_pm_cont),
                  gt_pm_request_id_tbl(ln_pm_cont),
                  gt_pm_program_app_id_tbl(ln_pm_cont),
                  gt_pm_program_id_tbl(ln_pm_cont),
                  gt_pm_program_update_date_tbl(ln_pm_cont));
--
      -- 成功件数(移動ロット詳細)カウント
      gn_m_normal_cnt := gt_pm_mov_lot_dtl_id_tbl.COUNT;
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
  END ins_mov_lot_details;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_lines_all
   * Description      : 受注明細アドオン(アドオン)登録処理(H-7)
   ***********************************************************************************/
  PROCEDURE ins_order_lines_all(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_lines_all'; -- プログラム名
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
    ln_pl_cont   NUMBER;         -- カウント変数
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ---------------------------------------------
    -- 受注明細更新処理                        --
    ---------------------------------------------
    FORALL ln_pl_cont IN gt_pl_order_line_id_tbl.FIRST .. gt_pl_order_line_id_tbl.LAST
      UPDATE xxwsh_order_lines_all
      SET    reserved_quantity           = gt_pl_reserved_quantity_tbl(ln_pl_cont),
             weight                      = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_weight_tbl(ln_pl_cont)
                                                 ,weight),
             capacity                    = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_capacity_tbl(ln_pl_cont)
                                                 ,capacity),
             quantity                    = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_quantity_tbl(ln_pl_cont)
                                                 ,quantity),
             automanual_reserve_class    = gt_pl_auto_reserve_class_tbl(ln_pl_cont),
             line_description            = NVL(gt_pl_line_description_tbl(ln_pl_cont)
                                              ,line_description),
             last_updated_by             = gt_pl_last_updated_by_tbl(ln_pl_cont),
             last_update_date            = gt_pl_last_update_date_tbl(ln_pl_cont),
             last_update_login           = gt_pl_last_update_login_tbl(ln_pl_cont)
      WHERE  order_line_id = gt_pl_order_line_id_tbl(ln_pl_cont);
--
      -- 成功件数(受注明細)カウント
      gn_l_normal_cnt := gt_pl_order_line_id_tbl.COUNT;
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
  END ins_order_lines_all;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_headers_all
   * Description      : 受注ヘッダアドオン(アドオン)登録処理(H-8)
   ***********************************************************************************/
  PROCEDURE ins_order_headers_all(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_headers_all'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(2);     -- リターン・コード
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
    ln_ph_cont   NUMBER;         -- カウント変数
    i            NUMBER;         -- カウント変数
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    ---------------------------------------------
    -- 配車解除処理                            --
    ---------------------------------------------
    <<data_loop>>
    FOR i IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST LOOP
      -- 指示数量更新フラグがONの場合のみ、配車解除を行う。
      IF (gt_ph_up_flg(i) = gv_flg_on) THEN
        -- 「配車解除関数」呼び出し
        lv_retcode := xxwsh_common_pkg.cancel_careers_schedule
                                   (
                                    gv_supply,                -- 業務種別("支給")
                                    gt_ph_request_no_tbl(i),  -- 依頼No.
                                    lv_errmsg                 -- エラーメッセージ
                                   );
--
        -- 共通関数でエラーの場合
        IF (lv_retcode <> '0') THEN
          -- エラーログ出力
          xxcmn_common_pkg.put_api_log(
            lv_errbuf     -- エラー・メッセージ
           ,lv_retcode    -- リターン・コード
           ,lv_errmsg);   -- ユーザー・エラー・メッセージ
--
          -- エラーメッセージ取得
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                                 gv_xxpo                   -- モジュール名略称:XXPO
                                 ,gv_msg_xxpo10237          -- メッセージ:APP-XXPO-10237 共通関数エラー
                                 ,gv_tkn_common_name        -- トークンNG_NAME
                                 ,gv_tkn_cancel_car_sche)   -- 配車解除関数
                                 ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
    END LOOP data_loop;
--
    ---------------------------------------------
    -- 受注ヘッダ更新処理                      --
    ---------------------------------------------
    FORALL ln_ph_cont IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST
      UPDATE xxwsh_order_headers_all
      SET    sum_quantity                = gt_ph_sum_quantity_tbl(ln_ph_cont),
             small_quantity              = gt_ph_small_quantity_tbl(ln_ph_cont),
             label_quantity              = gt_ph_label_quantity_tbl(ln_ph_cont),
             loading_efficiency_weight   = gt_ph_load_efficiency_we_tbl(ln_ph_cont),
             loading_efficiency_capacity = gt_ph_load_efficiency_ca_tbl(ln_ph_cont),
             sum_weight                  = gt_ph_sum_weight_tbl(ln_ph_cont),
             sum_capacity                = gt_ph_sum_capacity_tbl(ln_ph_cont),
             last_updated_by             = gt_ph_last_updated_by_tbl(ln_ph_cont),
             last_update_date            = gt_ph_last_update_date_tbl(ln_ph_cont),
             last_update_login           = gt_ph_last_update_login_tbl(ln_ph_cont)
      WHERE  order_header_id = gt_ph_order_header_id_tbl(ln_ph_cont)
      AND    gt_ph_up_flg(ln_ph_cont) = gv_flg_on;
--
      -- 成功件数(受注ヘッダ)カウント
      gn_h_normal_cnt := gt_ph_order_header_id_tbl.COUNT;
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
  END ins_order_headers_all;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_reserve_if
   * Description      : データ削除処理(H-9)
   ***********************************************************************************/
  PROCEDURE del_lot_reserve_if(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lot_reserve_if'; -- プログラム名
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
--###########################  固定部 END   ############################
--
    FORALL ln_count IN 1..gt_lr_lot_reserve_if_id_tbl.COUNT
      DELETE xxpo_lot_reserve_if xlri      -- ロット引当情報インタフェース
      WHERE  xlri.lot_reserve_if_id = gt_lr_lot_reserve_if_id_tbl(ln_count);
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
  END del_lot_reserve_if;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : データダンプ一括出力処理(H-10)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    IN OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
                   gv_xxcmn               -- モジュール名略称：XXCMN
                  ,gv_msg_xxcmn00005)     -- メッセージ：APP-XXCMN-00005 成功データ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 正常データダンプ
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- 警告データデータ（見出し）
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo               -- モジュール名略称：XXCMN
                  ,gv_msg_xxpo10252)     -- メッセージ：APP-XXPO-10252 警告データ（見出し）
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- 警告データダンプ
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  /**********************************************************************************
   * Procedure Name   : set_order_header_data_proc
   * Description      : 受注ヘッダ更新データ設定処理
   ***********************************************************************************/
  PROCEDURE set_order_header_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_header_data_proc'; -- プログラム名
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
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化-
    -- 受注ヘッダアドオンテーブルへ登録するレコードへ値をセット
    gt_ph_order_header_id_tbl(gn_k)               :=  gt_lr_order_header_id_tbl(gn_i);
    gt_ph_request_no_tbl(gn_k)                    :=  gt_lr_request_no_tbl(gn_i);
    /* 数量などは関連データ取得で取得する。 */
    gt_ph_last_updated_by_tbl(gn_k)               :=  gn_user_id;
    gt_ph_last_update_date_tbl(gn_k)              :=  gd_sysdate;
    gt_ph_last_update_login_tbl(gn_k)             :=  gn_login_id;
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
  END set_order_header_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_order_line_data_proc
   * Description      : 受注明細更新データ設定処理
   ***********************************************************************************/
  PROCEDURE set_order_line_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_line_data_proc'; -- プログラム名
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
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
--
    -- 受注明細アドオンテーブルへ登録するレコードへ値をセット
    gt_pl_order_line_id_tbl(gn_j)               :=  gt_lr_order_line_id_tbl(gn_i);
    gt_pl_auto_reserve_class_tbl(gn_j)          :=  gv_am_reserve_class_au;
    /* 数量などは関連データ取得で取得する。 */
    gt_pl_line_description_tbl(gn_j)            :=  gt_lr_line_description_tbl(gn_i);
    gt_pl_last_updated_by_tbl(gn_j)             :=  gn_user_id;
    gt_pl_last_update_date_tbl(gn_j)            :=  gd_sysdate;
    gt_pl_last_update_login_tbl(gn_j)           :=  gn_login_id;
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
  END set_order_line_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_mov_lot_data_proc
   * Description      : 移動ロット詳細登録データ設定処理
   ***********************************************************************************/
  PROCEDURE set_mov_lot_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mov_lot_data_proc'; -- プログラム名
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
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    -- ローカル変数の初期化
--
    -- ロット詳細ID採番
    SELECT xxinv_mov_lot_s1.NEXTVAL 
    INTO gt_pm_mov_lot_dtl_id_tbl(gn_i)
    FROM dual;
--
    -- 移動ロット詳細アドオンテーブルへ登録するレコードへ値をセット
    gt_pm_mov_line_id_tbl(gn_i)                     :=  gt_lr_order_line_id_tbl(gn_i);
    gt_pm_document_type_code_tbl(gn_i)              :=  gv_document_type_ship_req;
    gt_pm_record_type_code_tbl(gn_i)                :=  gv_record_type_inst;
    gt_pm_item_id_tbl(gn_i)                         :=  gt_lr_item_id_tbl(gn_i);
    gt_pm_item_code_tbl(gn_i)                       :=  gt_lr_item_code_tbl(gn_i);
    gt_pm_lot_id_tbl(gn_i)                          :=  gt_lr_lot_id_tbl(gn_i);
    gt_pm_lot_no_tbl(gn_i)                          :=  gt_lr_lot_no_tbl(gn_i);
    gt_pm_actual_date_tbl(gn_i)                     :=  gt_lr_shipped_date_tbl(gn_i);
    gt_pm_actual_quantity_tbl(gn_i)                 :=  gt_lr_reserved_quantity_tbl(gn_i);
    gt_pm_auma_reserve_class_tbl(gn_i)              :=  gv_am_reserve_class_au;
    gt_pm_created_by_tbl(gn_i)                      :=  gn_user_id;
    gt_pm_creation_date_tbl(gn_i)                   :=  gd_sysdate;
    gt_pm_last_updated_by_tbl(gn_i)                 :=  gn_user_id;
    gt_pm_last_update_date_tbl(gn_i)                :=  gd_sysdate;
    gt_pm_last_update_login_tbl(gn_i)               :=  gn_login_id;
    gt_pm_request_id_tbl(gn_i)                      :=  gn_conc_request_id;
    gt_pm_program_app_id_tbl(gn_i)                  :=  gn_prog_appl_id;
    gt_pm_program_id_tbl(gn_i)                      :=  gn_conc_program_id;
    gt_pm_program_update_date_tbl(gn_i)             :=  gd_sysdate;
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
  END set_mov_lot_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2,    --   ユーザー・エラー・メッセージ --# 固定 #
    iv_data_class             IN  VARCHAR2,    --   データ種別
    iv_deliver_from           IN  VARCHAR2,    --   倉庫
    iv_shipped_date_from      IN  VARCHAR2,    --   出庫日FROM
    iv_shipped_date_to        IN  VARCHAR2,    --   出庫日TO
    iv_instruction_dept       IN  VARCHAR2,    --   指示部署
    iv_security_kbn           IN  VARCHAR2)    --   セキュリティ区分
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
    lvv_retcode VARCHAR2(1);    -- リターン・コード
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    gn_target_cnt          := 0;          -- 対象件数(ロット引当情報IF)
    gn_h_normal_cnt        := 0;          -- 正常件数(受注ヘッダ)
    gn_l_normal_cnt        := 0;          -- 正常件数(受注明細)
    gn_m_normal_cnt        := 0;          -- 正常件数(移動ロット詳細)
    gn_warn_msg_cnt        := 0;
    gn_normal_cnt          := 0;
    
    gn_i                   := 0;
    gn_j                   := 0;
    gn_k                   := 0;
    gn_lot_sum             := 0;
    gv_line_description    := NULL;
--
    -- ブレイク用変数
    gv_pre_order_header_id       := 0;
--
    ------------------------------------------
    -- パラメータ必須チェック               --
    ------------------------------------------
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    -- 倉庫
    ELSIF (iv_deliver_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_deliver_from_s);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    -- 出庫日FROM
    ELSIF (iv_shipped_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_shippe_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- 出庫日TO
    ELSIF (iv_shipped_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_shippe_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- 指示部署
    ELSIF (iv_instruction_dept IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_instruction_dept);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- セキュリティ区分
    ELSIF (iv_security_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_security_class);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    ------------------------------------------
    -- パラメータ日付チェック               --
    ------------------------------------------
    -- ｢出庫日TO｣が｢出庫日FROM｣より以前の場合
    IF (iv_shipped_date_from > iv_shipped_date_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10236,
                                            gv_tkn_date_item1,
                                            gv_shippe_date_from,
                                            gv_tkn_date_item2,
                                            gv_shippe_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    -- =========================================
    -- 初期処理(H-1)
    -- =========================================
    init_proc(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 引当可能数チェック処理(H-2)
    -- =========================================
    check_can_enc_qty(
      iv_data_class,           -- 1.データ種別
      iv_deliver_from,         -- 2.倉庫
      iv_shipped_date_from,    -- 3.出庫日FROM
      iv_shipped_date_to,      -- 4.出庫日TO
      iv_instruction_dept,     -- 5.指示部署
      iv_security_kbn,         -- 6.セキュリティ区分
      lv_errbuf,               -- エラー・メッセージ           --# 固定 #
      lv_retcode,              -- リターン・コード             --# 固定 #
      lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 対象データ取得処理(H-3)
    -- =========================================
    get_data(
      iv_data_class,           -- 1.データ種別
      iv_deliver_from,         -- 2.倉庫
      iv_shipped_date_from,    -- 3.出庫日FROM
      iv_shipped_date_to,      -- 4.出庫日TO
      iv_instruction_dept,     -- 5.指示部署
      iv_security_kbn,         -- 6.セキュリティ区分
      lv_errbuf,               -- エラー・メッセージ           --# 固定 #
      lv_retcode,              -- リターン・コード             --# 固定 #
      lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
--
      IF (gn_target_cnt = 0) THEN
        ov_retcode := gv_status_warn;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        RETURN;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
    <<data_loop>>
    FOR i IN gt_lr_lot_reserve_if_id_tbl.FIRST .. gt_lr_lot_reserve_if_id_tbl.LAST LOOP
--
      -- 移動ロット詳細登録数のカウント
      gn_i := gn_i + 1;
--
      -- =========================================
      -- 取得データチェック処理(H-4)
      -- =========================================
      check_data(
        lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,lv_retcode         -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- エラーの場合、処理終了
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
--
      -- 正常/警告の場合
      ELSE
--
        -- 数量合計用変数に引当数量(ロット引当情報IF)を設定
        gn_lot_sum := gn_lot_sum + gt_lr_reserved_quantity_tbl(gn_i);
--
        -- 受注ヘッダアドオンIDが前回レコードと異なる場合、受注ヘッダアドオン情報をセットする。
        IF ( gt_lr_order_header_id_tbl(gn_i) <> gv_pre_order_header_id) THEN
--
          -- 受注ヘッダ登録数のカウント。
          gn_k := gn_k + 1 ;
--
          -- =========================================
          -- 関連データ取得処理(H-5)
          -- =========================================
          get_other_data(
            gv_header                           -- ヘッダ区分
           ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,lv_retcode         -- リターン・コード             --# 固定 #
           ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
          
          -- =========================================
          -- 受注ヘッダアドオン登録データ設定処理
          -- =========================================
          set_order_header_data_proc(
            lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,lv_retcode         -- リターン・コード             --# 固定 #
           ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- 受注ヘッダアドオンIDを再設定する。
          gv_pre_order_header_id := gt_lr_order_header_id_tbl(gn_i);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- 明細摘要保持内容の更新
        IF (gt_lr_line_description_tbl(gn_i) IS NOT NULL) THEN
          gv_line_description := gt_lr_line_description_tbl(gn_i);
        END IF;
--
        -- 明細が最終レコードか、同一明細IDの最終レコードの場合実行する。
        IF ((gt_lr_order_line_id_tbl.COUNT  = gn_i) OR
             (gt_lr_order_line_id_tbl(gn_i) <> gt_lr_order_line_id_tbl(gn_i + 1))
           ) THEN
--
--
          -- 受注明細登録数のカウント。
          gn_j := gn_j + 1 ;
--
          -- =========================================
          -- 関連データ取得処理(H-5)
          -- =========================================
          get_other_data(
            gv_line                             -- 明細区分
           ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,lv_retcode         -- リターン・コード             --# 固定 #
           ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合、処理終了
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
          
          -- =========================================
          -- 受注明細アドオン登録データ設定処理
          -- =========================================
          set_order_line_data_proc(
            lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,lv_retcode         -- リターン・コード             --# 固定 #
           ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- 数量合計用変数をクリアする。
          gn_lot_sum           := 0;
--
          -- 明細摘要保持内容をクリアする。
          gv_line_description  := NULL;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
--
        END IF;
--
        -- =========================================
        -- 移動ロット詳細アドオン登録データ設定処理
        -- =========================================
        set_mov_lot_data_proc(
          lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,lv_retcode         -- リターン・コード             --# 固定 #
         ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- 正常データダンプPL/SQL表投入
        gn_normal_cnt := gn_normal_cnt + 1;
        normal_dump_tab(gn_normal_cnt) := gt_lr_data_dump_tbl(gn_i);
--
      END IF;
--
    END LOOP data_loop;
--
    -- =========================================
    -- 移動ロット詳細(アドオン)登録処理(H-6)
    -- =========================================
    ins_mov_lot_details(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- 受注明細(アドオン)登録処理(H-7)
    -- =========================================
    ins_order_lines_all(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- 受注ヘッダ(アドオン)登録処理(H-8)
    -- =========================================
    ins_order_headers_all(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- データ削除処理(H-9)
    -- =========================================
    del_lot_reserve_if(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合、処理終了
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- データダンプ一括出力処理(H-10)
    -- =========================================
    put_dump_msg(
      lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- 各処理でエラーが発生した場合
    WHEN proc_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      lvv_retcode := gv_status_normal;
--
      -- =========================================
      -- データ削除処理(H-9)
      -- =========================================
      del_lot_reserve_if(
        lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,lvv_retcode        -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lvv_retcode <> gv_status_error) THEN
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
    errbuf                    OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_data_class             IN  VARCHAR2,      --   データ種別
    iv_deliver_from           IN  VARCHAR2,      --   倉庫
    iv_shipped_date_from      IN  VARCHAR2,      --   出庫日FROM
    iv_shipped_date_to        IN  VARCHAR2,      --   出庫日TO
    iv_instruction_dept       IN  VARCHAR2,      --   指示部署
    iv_security_kbn           IN  VARCHAR2       --   セキュリティ区分
  )
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
    lv_msg     VARCHAR2(5000);  -- パラメータ出力用
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- 固定出力用変数セット
    -- ======================
    --実行ユーザ名取得
    gv_exec_user := fnd_global.user_name;
--
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
    -- ===============================
    -- 入力パラメータ出力
    -- ===============================
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- 入力パラメータ(見出し)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo              -- モジュール名略称：XXPO
                  ,gv_msg_xxpo30051)    -- メッセージ:APP-XXPO-30051 入力パラメータ(見出し)
                ,1,5000);
--
    -- 入力パラメータ見出し出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 入力パラメータ(カンマ区切り)
    lv_msg := iv_data_class             || gv_msg_comma || -- データ種別
              iv_deliver_from           || gv_msg_comma || -- 倉庫
              iv_shipped_date_from      || gv_msg_comma || -- 出庫日FROM
              iv_shipped_date_to        || gv_msg_comma || -- 出庫日TO
              iv_instruction_dept       || gv_msg_comma || -- 指示部署
              iv_security_kbn;                             -- セキュリティ区分
--
    -- 入力パラメータ出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- 区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,                  -- エラー・メッセージ           --# 固定 #
      lv_retcode,                 -- リターン・コード             --# 固定 #
      lv_errmsg,                  -- ユーザー・エラー・メッセージ --# 固定 #
      iv_data_class,              -- データ種別
      iv_deliver_from,            -- 倉庫
      iv_shipped_date_from,       -- 出庫日FROM
      iv_shipped_date_to,         -- 出庫日TO
      iv_instruction_dept,        -- 指示部署
      iv_security_kbn             -- セキュリティ区分
      );
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
    --処理件数(ロット引当情報IF)出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-30027','COUNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数(受注ヘッダ)出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10246','CNT',TO_CHAR(gn_h_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    --成功件数(受注明細)出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10247','CNT',TO_CHAR(gn_l_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    --成功件数(移動ロット詳細)出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10248','CNT',TO_CHAR(gn_m_normal_cnt));
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
END xxpo940008c;
/
