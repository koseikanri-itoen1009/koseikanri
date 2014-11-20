CREATE OR REPLACE PACKAGE BODY xxwsh430001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh430001c(body)
 * Description      : 倉替返品情報インターフェース
 * MD.050           : 倉替返品 T_MD050_BPO_430
 * MD.070           : 倉替返品情報インターフェース T_MD070_BPO_43B
 * Version          : 1.15
 *
 * Program List
 * -------------------------  ----------------------------------------------------------
 *  Name                      Description
 * -------------------------  ----------------------------------------------------------
 *  get_profile               プロファイル取得処理 (A-1)
 *  get_reserve_interface     倉替返品インターファイス情報抽出処理 (A-2)
 *  check_master              マスタ存在チェック処理 (A-3)
 *  check_stock               在庫会計期間チェック処理 (A-4)
 *  get_order_type            関連データ取得処理 (A-5)
 *  get_order_all_tbl         同一依頼No情報抽出処理 (A-6)
 *  set_del_headers           倉替返品打消情報(ヘッダ)作成処理 (A-7)
 *  set_del_lines             倉替返品打消情報(明細)作成処理 (A-8)
 *  set_order_headers         倉替返品情報(ヘッダ)作成処理 (A-9)
 *  set_latest_external_flag  最新フラグ更新情報作成処理 (A-10)
 *  set_order_lines           倉替返品情報(明細)作成処理 (A-11)
 *  set_upd_order_headers     倉替返品更新情報(ヘッダ)作成処理 (A-12)
 *  set_upd_order_lines       倉替返品更新情報(明細)作成処理 (A-13)
 *  ins_order                 倉替返品情報登録処理 (A-14)
 *  sum_lines_quantity        倉替返品抽出合計処理 (A-15)
 *  upd_headers_sum_quantity  倉替返品情報再登録処理 (A-16)
 *  del_reserve_interface     倉替返品インターフェース情報削除処理 (A-17)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0   ORACLE福田直樹   初回作成
 *  2008/05/16    1.1   ORACLE石渡賢和   マスタはView参照するよう変更
 *                                       受注明細アドオンの出荷品目ID／依頼品目IDに
 *                                       inventory_item_idをセットするよう変更
 *  2008/05/20    1.2   ORACLE椎名昭圭   内部変更要求#106対応
 *  2008/06/19    1.3   ORACLE石渡賢和   フラグのデフォルト値をセット
 *  2008/08/07    1.4   ORACLE山根一浩   課題#32,課題#67変更#174対応
 *  2008/10/10    1.5   ORACLE平福正明   T_S_474対応
 *  2008/11/25    1.6   ORACLE吉元強樹   本番問合せ#243対応
 *  2008/12/22    1.7   ORACLE椎名昭圭   本番問合せ#743対応
 *  2009/01/06    1.8   Yuko Kawano      本番問合せ#908対応
 *  2009/01/13    1.9   Hitomi Itou      本番問合せ#981対応
 *  2009/01/15    1.10  Masayoshi Uehara 本番問合せ#1019対応
 *  2009/01/22    1.11  ORACLE山本恭久   本番問合せ#1037対応
 *  2009/04/09    1.12  SCS丸下          本番障害#1346
 *  2009/06/30    1.13  Yuki Kazama      本番障害#1335対応
 *  2009/09/29    1.14  H.Itou           本番障害#1465対応
 *  2009/10/20    1.15  H.Itou           本番障害#1569,1591(営業稼動支援)対応
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
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
--
--################################  固定部 END   ###############################
--
--#####################  固定共通例外宣言部 START   ####################
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
--###########################  固定部 END   ############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  no_data_expt           EXCEPTION;        -- 処理対象データ0件（警告）
  lock_expt              EXCEPTION;        -- ロック取得例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ロック取得例外
-- 2009/10/20 H.Itou Mod Start 本番障害#1569 在庫クローズエラーのときは警告とし、後続処理をスキップする。
  skip_expt              EXCEPTION;        -- スキップ例外
-- 2009/10/20 H.Itou Mod End
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxwsh430001c';            -- パッケージ名
  gv_xxwsh             CONSTANT VARCHAR2(100) := 'XXWSH';                   -- アプリケーション短縮名
  gv_reserve_interface CONSTANT VARCHAR2(100) := 'xxwsh_reserve_interface'; -- 倉替返品インターフェース
  --gv_cate_return       CONSTANT VARCHAR2(10)  := '返品';                    -- 受注カテゴリ 返品
  --gv_cate_order        CONSTANT VARCHAR2(10)  := '倉替';                    -- 受注カテゴリ 受注
  gv_cate_return       CONSTANT VARCHAR2(10)  := 'RETURN';                  -- 受注カテゴリ 返品
  gv_cate_order        CONSTANT VARCHAR2(10)  := 'ORDER';                   -- 受注カテゴリ 受注
  gv_flag_on           CONSTANT VARCHAR2(1)   := 'Y';
  gv_flag_off          CONSTANT VARCHAR2(1)   := 'N';
-- 2009/10/20 H.Itou Add Start 本番障害#1569
  gv_comma             CONSTANT VARCHAR2(1)   := ',';
-- 2009/10/20 H.Itou Add End
--
  -- メッセージ
  -- プロファイル取得エラーメッセージ
  gv_xxwsh_noprof_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11601';
  -- カテゴリエラー
  gv_xxwsh_category_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11602';
  -- マスタチェックエラー
  gv_xxwsh_mst_chk_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11603';
  -- ロックエラー
  gv_xxwsh_table_lock_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11604';
  -- 対象データ無し
  gv_xxwsh_nodata_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11605';
  -- 同一伝票No内ヘッダ相違エラーメッセージ
  gv_xxwsh_invoice_no_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11606';
  -- 在庫会計期間エラーメッセージ
  gv_xxwsh_stock_from_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11607';
  -- 在庫会計期間取得エラーメッセージ
  gv_xxwsh_stock_get_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-11608';
  -- 商品区分取得エラー
  gv_xxwsh_prod_get_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11609';
  -- ヘッダ項目変更エラー
  gv_xxwsh_hd_upd_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11610';
  -- 受注タイプ取得エラーメッセージ
  gv_xxwsh_type_get_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11611';
  -- 正負混在エラーメッセージ
  gv_xxwsh_num_mix_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11612';
  -- 共通関数依頼No変換エラーメッセージ
  gv_xxwsh_request_no_conv_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-11613';
  -- 共通関数テーブル削除エラーメッセージ
  gv_xxwsh_truncate_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11614';
  -- 共通関数OPM在庫会計期間CLOSE年月取得エラーメッセージ
  gv_xxwsh_closeym_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11615';
  -- 入力件数(倉替返品インターフェース）)
  gv_xxwsh_input_reserve_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11616';
  -- 倉替返品情報作成件数(受注ヘッダアドオン単位)
  gv_xxwsh_output_headers_cnt   CONSTANT VARCHAR2(100) := 'APP-XXWSH-11617';
  -- 倉替返品情報作成件数(受注明細アドオン単位)
  gv_xxwsh_output_lines_cnt     CONSTANT VARCHAR2(100) := 'APP-XXWSH-11618';
  -- 倉替返品情報作成件数(移動ロット詳細単位)
  gv_xxwsh_output_lot_cnt       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11623';
  -- 倉替返品打消情報作成件数(受注ヘッダアドオン単位)
  gv_xxwsh_output_del_hd_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11619';
  -- 倉替返品打消情報作成件数(受注明細アドオン単位)
  gv_xxwsh_output_del_ln_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11620';
  -- 倉替返品打消情報作成件数(移動ロット詳細単位)
  gv_xxwsh_output_del_lot_cnt   CONSTANT VARCHAR2(100) := 'APP-XXWSH-11624';
  -- 倉替返品更新情報作成件数(受注ヘッダアドオン単位)
  gv_xxwsh_output_upd_hd_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11621';
  -- 倉替返品更新情報作成件数(受注明細アドオン単位)
  gv_xxwsh_output_upd_ln_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11622';
--
  -- トークン
  gv_tkn_cnt           CONSTANT VARCHAR2(100) := 'CNT';
  gv_tkn_table         CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_colmun        CONSTANT VARCHAR2(100) := 'COLMUN';
  gv_tkn_prof_name     CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_tkn_ctg_name      CONSTANT VARCHAR2(100) := 'CTG_NAME';
  gv_tkn_den_no        CONSTANT VARCHAR2(100) := 'DEN_NO';
  gv_tkn_input_item    CONSTANT VARCHAR2(100) := 'INPUT_ITEM';
  gv_tkn_arrival_date  CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
--
  --プロファイル
  gv_prf_org_id      CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';    -- マスター組織ID
  gv_prf_max_date    CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';         -- MAX日付
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 倉替返品インターフェース情報格納用(A-1)
  TYPE reserve_interface_rec IS RECORD(
    recorded_year      xxwsh_reserve_interface.recorded_year%TYPE,     -- 計上年月
    input_base_code    xxwsh_reserve_interface.input_base_code%TYPE,   -- 入力拠点コード
    receive_base_code  xxwsh_reserve_interface.receive_base_code%TYPE, -- 相手拠点コードo
    invoice_class_1    xxwsh_reserve_interface.invoice_class_1%TYPE,   -- 伝区１
    recorded_date      xxwsh_reserve_interface.recorded_date%TYPE,     -- 計上日付(着日)
    invoice_no         xxwsh_reserve_interface.invoice_no%TYPE,        -- 伝票No
    item_no            ic_item_mst_b.item_no%TYPE,                     -- 品目コード
    quantity_total     xxwsh_reserve_interface.quantity%TYPE           -- 数量
-- 2009/10/20 H.Itou Add Start 本番障害#1569
   ,data_dump          VARCHAR2(5000)                                  -- データダンプ
-- 2009/10/20 H.Itou Add End
  );
--
  TYPE reserve_interface_tbl IS TABLE OF reserve_interface_rec INDEX BY PLS_INTEGER;
--
  -- 受注ヘッダアドオン・受注明細アドオン格納用(A-6)
  TYPE order_all_rec IS RECORD(
     hd_order_header_id       xxwsh_order_headers_all.order_header_id%TYPE,       -- 受注ヘッダアドオンID
     hd_order_type_id         xxwsh_order_headers_all.order_type_id%TYPE,         -- 受注タイプID
     hd_organization_id       xxwsh_order_headers_all.organization_id%TYPE,       -- 組織ID
     hd_latest_external_flag  xxwsh_order_headers_all.latest_external_flag%TYPE,  -- 最新フラグ
     hd_ordered_date          xxwsh_order_headers_all.ordered_date%TYPE,          -- 受注日
     hd_customer_id           xxwsh_order_headers_all.customer_id%TYPE,           -- 顧客ID
     hd_customer_code         xxwsh_order_headers_all.customer_code%TYPE,         -- 顧客
     hd_deliver_to_id         xxwsh_order_headers_all.deliver_to_id%TYPE,         -- 出荷先ID
     hd_deliver_to            xxwsh_order_headers_all.deliver_to%TYPE,            -- 出荷先
     hd_shipping_instructions xxwsh_order_headers_all.shipping_instructions%TYPE, -- 出荷指示
     hd_request_no            xxwsh_order_headers_all.request_no%TYPE,            -- 依頼No
     hd_req_status            xxwsh_order_headers_all.req_status%TYPE,            -- ステータス
     hd_schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE,    -- 出荷予定日
     hd_schedule_arrival_date xxwsh_order_headers_all.schedule_arrival_date%TYPE, -- 着荷予定日
     hd_deliver_from_id       xxwsh_order_headers_all.deliver_from_id%TYPE,       -- 出荷元ID
     hd_deliver_from          xxwsh_order_headers_all.deliver_from%TYPE,          -- 出荷元保管場所
     hd_head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE,     -- 管轄拠点
     hd_prod_class            xxwsh_order_headers_all.prod_class%TYPE,            -- 商品区分
     hd_sum_quantity          xxwsh_order_headers_all.sum_quantity%TYPE,          -- 合計数量
     hd_result_deliver_to_id  xxwsh_order_headers_all.result_deliver_to_id%TYPE,  -- 出荷先_実績ID
     hd_result_deliver_to     xxwsh_order_headers_all.result_deliver_to%TYPE,     -- 出荷先_実績
     hd_shipped_date          xxwsh_order_headers_all.shipped_date%TYPE,          -- 出荷日
     hd_arrival_date          xxwsh_order_headers_all.arrival_date%TYPE,          -- 着荷日
--2008/08/07 Add ↓
     hd_actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE,  -- 実績計上済区分
--2008/08/07 Add ↑
     hd_perform_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE, -- 成績管理部署
     hd_registered_sequence    xxwsh_order_headers_all.registered_sequence%TYPE,  -- 登録順序
     hd_created_by             xxwsh_order_headers_all.created_by%TYPE,           -- 作成者
     hd_creation_date          xxwsh_order_headers_all.creation_date%TYPE,        -- 作成日
     hd_last_updated_by        xxwsh_order_headers_all.last_updated_by%TYPE,      -- 最終更新者
     hd_last_update_date       xxwsh_order_headers_all.last_update_date%TYPE,     -- 最終更新日
     hd_last_update_login      xxwsh_order_headers_all.last_update_login%TYPE,    -- 最終更新ログイン
     hd_request_id             xxwsh_order_headers_all.request_id%TYPE,           -- 要求ID
     hd_program_application_id xxwsh_order_headers_all.program_application_id%TYPE,-- アプリケーションID
     hd_program_id             xxwsh_order_headers_all.program_id%TYPE,           -- コンカレント・プログラムID
     hd_program_update_date    xxwsh_order_headers_all.program_update_date%TYPE,  -- プログラム更新日
--
     ln_order_line_id          xxwsh_order_lines_all.order_line_id%TYPE,          -- 受注明細アドオンID
     ln_order_header_id        xxwsh_order_lines_all.order_header_id%TYPE,        -- 受注ヘッダアドオンID
     ln_order_line_number      xxwsh_order_lines_all.order_line_number%TYPE,      -- 明細番号
     ln_request_no             xxwsh_order_lines_all.request_no%TYPE,             -- 依頼No
     ln_shipping_inventory_item_id xxwsh_order_lines_all.shipping_inventory_item_id%TYPE, -- 出荷品目ID
     ln_shipping_item_code     xxwsh_order_lines_all.shipping_item_code%TYPE,     -- 出荷品目
     ln_quantity               xxwsh_order_lines_all.quantity%TYPE,               -- 数量
     ln_add_quantity           xxwsh_order_lines_all.quantity%TYPE,               -- 加算用数量
     ln_uom_code               xxwsh_order_lines_all.uom_code%TYPE,               -- 単位
     ln_shipped_quantity       xxwsh_order_lines_all.shipped_quantity%TYPE,       -- 出荷実績数量
     ln_based_request_quantity xxwsh_order_lines_all.based_request_quantity%TYPE, -- 拠点依頼数量
     ln_request_item_id        xxwsh_order_lines_all.request_item_id%TYPE,        -- 依頼品目ID
     ln_request_item_code      xxwsh_order_lines_all.request_item_code%TYPE,      -- 依頼品目
     ln_rm_if_flg              xxwsh_order_lines_all.rm_if_flg%TYPE,              -- 倉替返品インタフェース済フラグ
     ln_created_by             xxwsh_order_lines_all.created_by%TYPE,             -- 作成者
     ln_creation_date          xxwsh_order_lines_all.creation_date%TYPE,          -- 作成日
     ln_last_updated_by        xxwsh_order_lines_all.last_updated_by%TYPE,        -- 最終更新者
     ln_last_update_date       xxwsh_order_lines_all.last_update_date%TYPE,       -- 最終更新日
     ln_last_update_login      xxwsh_order_lines_all.last_update_login%TYPE,      -- 最終更新ログイン
     ln_request_id             xxwsh_order_lines_all.request_id%TYPE,             -- 要求ID
     ln_program_application_id xxwsh_order_lines_all.program_application_id%TYPE, -- アプリケーションID
     ln_program_id             xxwsh_order_lines_all.program_id%TYPE,             -- コンカレント・プログラムID
     ln_program_update_date    xxwsh_order_lines_all.program_update_date%TYPE,    -- プログラム更新日
--
     lo_mov_lot_dtl_id           xxinv_mov_lot_details.mov_lot_dtl_id%TYPE,       -- ロット詳細ID
     lo_mov_line_id              xxinv_mov_lot_details.mov_line_id%TYPE,          -- 明細ID
     lo_document_type_code       xxinv_mov_lot_details.document_type_code%TYPE,   -- 文書タイプ
     lo_record_type_code         xxinv_mov_lot_details.record_type_code%TYPE,     -- レコードタイプ
     lo_item_id                  xxinv_mov_lot_details.item_id%TYPE,              -- OPM品目ID
     lo_item_code                xxinv_mov_lot_details.item_code%TYPE,            -- 品目
     lo_lot_id                   xxinv_mov_lot_details.lot_id%TYPE,               -- ロットID
     lo_lot_no                   xxinv_mov_lot_details.lot_no%TYPE,               -- ロットNo
     lo_actual_date              xxinv_mov_lot_details.actual_date%TYPE,          -- 実績日
     lo_actual_quantity          xxinv_mov_lot_details.actual_quantity%TYPE,      -- 実績数量
-- 2009/01/22 Y.Yamamoto #1037 add start
     lo_before_actual_quantity   xxinv_mov_lot_details.before_actual_quantity%TYPE,   -- 訂正前実績数量
-- 2009/01/22 Y.Yamamoto #1037 add end
     lo_automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE, -- 自動手動引当区分
     lo_created_by               xxinv_mov_lot_details.created_by%TYPE,           -- 作成者
     lo_creation_date            xxinv_mov_lot_details.creation_date%TYPE,        -- 作成日
     lo_last_updated_by          xxinv_mov_lot_details.last_updated_by%TYPE,      -- 最終更新者
     lo_last_update_date         xxinv_mov_lot_details.last_update_date%TYPE,     -- 最終更新日
     lo_last_update_login        xxinv_mov_lot_details.last_update_login%TYPE,    -- 最終更新ログイン
     lo_request_id               xxinv_mov_lot_details.request_id%TYPE,           -- 要求ID
     lo_program_application_id   xxinv_mov_lot_details.program_application_id%TYPE, -- アプリケーションID
     lo_program_id               xxinv_mov_lot_details.program_id%TYPE,           -- コンカレント・プログラムID
     lo_program_update_date      xxinv_mov_lot_details.program_update_date%TYPE   -- プログラム更新日
  );
--
  TYPE order_all_tbl IS TABLE OF order_all_rec INDEX BY PLS_INTEGER;
--
  -- 受注ヘッダアドオン
  -- 受注ヘッダアドオンID
  TYPE xoh_order_header_id
    IS TABLE OF xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注タイプID
  TYPE xoh_order_type_id
    IS TABLE OF xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- 組織ID
  TYPE xoh_organization_id
    IS TABLE OF xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- 最新フラグ
  TYPE xoh_latest_external_flag
    IS TABLE OF xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- 受注日
  TYPE xoh_ordered_date
    IS TABLE OF xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客ID
  TYPE xoh_customer_id
    IS TABLE OF xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- 顧客
  TYPE xoh_customer_code
    IS TABLE OF xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先ID
  TYPE xoh_deliver_to_id
    IS TABLE OF xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先
  TYPE xoh_deliver_to
    IS TABLE OF xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷指示
  TYPE xoh_shipping_instructions
    IS TABLE OF xxwsh_order_headers_all.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE xoh_request_no
    IS TABLE OF xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- ステータス
  TYPE xoh_req_status
    IS TABLE OF xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷予定日
  TYPE xoh_schedule_ship_date
    IS TABLE OF xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷予定日
  TYPE xoh_schedule_arrival_date
    IS TABLE OF xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元ID
  TYPE xoh_deliver_from_id
    IS TABLE OF xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷元保管場所
  TYPE xoh_deliver_from
    IS TABLE OF xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- 管轄拠点
  TYPE xoh_head_sales_branch
    IS TABLE OF xxwsh_order_headers_all.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- 商品区分
  TYPE xoh_prod_class
    IS TABLE OF xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- 合計数量
  TYPE xoh_sum_quantity
    IS TABLE OF xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先_実績ID
  TYPE xoh_result_deliver_to_id
    IS TABLE OF xxwsh_order_headers_all.result_deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷先_実績
  TYPE xoh_result_deliver_to
    IS TABLE OF xxwsh_order_headers_all.result_deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷日
  TYPE xoh_shipped_date
    IS TABLE OF xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- 着荷日
  TYPE xoh_arrival_date
    IS TABLE OF xxwsh_order_headers_all.arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- 成績管理部署
  TYPE xoh_perform_management_dept
    IS TABLE OF xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- 登録順序
  TYPE xoh_registered_sequence
    IS TABLE OF xxwsh_order_headers_all.registered_sequence%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE xoh_created_by
    IS TABLE OF xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE xoh_creation_date
    IS TABLE OF xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE xoh_last_updated_by
    IS TABLE OF xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE xoh_last_update_date
    IS TABLE OF xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE xoh_last_update_login
    IS TABLE OF xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE xoh_request_id
    IS TABLE OF xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラム・アプリケーションID
  TYPE xoh_program_application_id
    IS TABLE OF xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE xoh_program_id
    IS TABLE OF xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE xoh_program_update_date
    IS TABLE OF xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- 受注ヘッダアドオン一括登録用
  gt_xoh_order_header_id         xoh_order_header_id;             -- 受注ヘッダアドオンID
  gt_xoh_order_type_id           xoh_order_type_id;               -- 受注タイプID
  gt_xoh_organization_id         xoh_organization_id;             -- 組織ID
  gt_xoh_latest_external_flag    xoh_latest_external_flag;        -- 最新フラグ
  gt_xoh_ordered_date            xoh_ordered_date;                -- 受注日
  gt_xoh_customer_id             xoh_customer_id;                 -- 顧客ID
  gt_xoh_customer_code           xoh_customer_code;               -- 顧客
  gt_xoh_deliver_to_id           xoh_deliver_to_id;               -- 出荷先ID
  gt_xoh_deliver_to              xoh_deliver_to;                  -- 出荷先
  gt_xoh_shipping_instructions   xoh_shipping_instructions;       -- 出荷指示
  gt_xoh_request_no              xoh_request_no;                  -- 依頼No
  gt_xoh_req_status              xoh_req_status;                  -- ステータス
  gt_xoh_schedule_ship_date      xoh_schedule_ship_date;          -- 出荷予定日
  gt_xoh_schedule_arrival_date   xoh_schedule_arrival_date;       -- 着荷予定日
  gt_xoh_deliver_from_id         xoh_deliver_from_id;             -- 出荷元ID
  gt_xoh_deliver_from            xoh_deliver_from;                -- 出荷元保管場所
  gt_xoh_head_sales_branch       xoh_head_sales_branch;           -- 管轄拠点
  gt_xoh_prod_class              xoh_prod_class;                  -- 商品区分
  gt_xoh_sum_quantity            xoh_sum_quantity;                -- 合計数量
  gt_xoh_result_deliver_to_id    xoh_result_deliver_to_id;        -- 出荷先_実績ID
  gt_xoh_result_deliver_to       xoh_result_deliver_to;           -- 出荷先_実績
  gt_xoh_shipped_date            xoh_shipped_date;                -- 出荷日
  gt_xoh_arrival_date            xoh_arrival_date;                -- 着荷日
  gt_xoh_perform_management_dept xoh_perform_management_dept;     -- 成績管理部署
  gt_xoh_registered_sequence     xoh_registered_sequence;         -- 登録順序
  gt_xoh_created_by              xoh_created_by;                  -- 作成者
  gt_xoh_creation_date           xoh_creation_date;               -- 作成日
  gt_xoh_last_updated_by         xoh_last_updated_by;             -- 最終更新者
  gt_xoh_last_update_date        xoh_last_update_date;            -- 最終更新日
  gt_xoh_last_update_login       xoh_last_update_login;           -- 最終更新ログイン
  gt_xoh_request_id              xoh_request_id;                  -- 要求ID
  gt_xoh_program_application_id  xoh_program_application_id;      -- アプリケーションID
  gt_xoh_program_id              xoh_program_id;                  -- コンカレント・プログラムID
  gt_xoh_program_update_date     xoh_program_update_date;         -- プログラム更新日
--
  -- 受注明細アドオン
  -- 受注明細アドオンID
  TYPE xol_order_line_id
    IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 受注ヘッダアドオンID
  TYPE xol_order_header_id
    IS TABLE OF xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細番号
  TYPE xol_order_line_number
    IS TABLE OF xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼No
  TYPE xol_request_no
    IS TABLE OF xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目ID
  TYPE xol_shipping_item_id
    IS TABLE OF xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷品目
  TYPE xol_shipping_item_code
    IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 数量
  TYPE xol_quantity
    IS TABLE OF xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 単位
  TYPE xol_uom_code
    IS TABLE OF xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- 出荷実績数量
  TYPE xol_shipped_quantity
    IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 拠点依頼数量
  TYPE xol_based_request_quantity
    IS TABLE OF xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目ID
  TYPE xol_request_item_id
    IS TABLE OF xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 依頼品目
  TYPE xol_request_item_code
    IS TABLE OF xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- 倉替返品インタフェース済フラグ
  TYPE xol_rm_if_flg
    IS TABLE OF xxwsh_order_lines_all.rm_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE xol_created_by
    IS TABLE OF xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE xol_creation_date
    IS TABLE OF xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE xol_last_updated_by
    IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE xol_last_update_date
    IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE xol_last_update_login
    IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE xol_request_id
    IS TABLE OF xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラム・アプリケーションID
  TYPE xol_program_application_id
    IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE xol_program_id
    IS TABLE OF xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE xol_program_update_date
    IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- 受注明細アドオン一括登録用
  gt_xol_order_line_id           xol_order_line_id;              -- 受注明細アドオンID
  gt_xol_order_header_id         xol_order_header_id;            -- 受注ヘッダアドオンID
  gt_xol_order_line_number       xol_order_line_number;          -- 明細番号
  gt_xol_request_no              xol_request_no;                 -- 依頼No
  gt_xol_shipping_item_id        xol_shipping_item_id;           -- 出荷品目ID
  gt_xol_shipping_item_code      xol_shipping_item_code;         -- 出荷品目
  gt_xol_quantity                xol_quantity;                   -- 数量
  gt_xol_uom_code                xol_uom_code;                   -- 単位
  gt_xol_shipped_quantity        xol_shipped_quantity;           -- 出荷実績数量
  gt_xol_based_request_quantity  xol_based_request_quantity;     -- 拠点依頼数量
  gt_xol_request_item_id         xol_request_item_id;            -- 依頼品目ID
  gt_xol_request_item_code       xol_request_item_code;          -- 依頼品目
  gt_xol_rm_if_flg               xol_rm_if_flg;                  -- 倉替返品インタフェース済フラグ
  gt_xol_created_by              xol_created_by;                 -- 作成者
  gt_xol_creation_date           xol_creation_date;              -- 作成日
  gt_xol_last_updated_by         xol_last_updated_by;            -- 最終更新者
  gt_xol_last_update_date        xol_last_update_date;           -- 最終更新日
  gt_xol_last_update_login       xol_last_update_login;          -- 最終更新ログイン
  gt_xol_request_id              xol_request_id;                 -- 要求ID
  gt_xol_program_application_id  xol_program_application_id;     -- アプリケーションID
  gt_xol_program_id              xol_program_id;                 -- コンカレント・プログラムID
  gt_xol_program_update_date     xol_program_update_date;        -- プログラム更新日
--
  -- 移動ロット詳細
  -- ロット詳細ID
  TYPE xml_mov_lot_dtl_id
    IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
  -- 明細ID
  TYPE xml_mov_line_id
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- 文書タイプ
  TYPE xml_document_type_code
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- レコードタイプ
  TYPE xml_record_type_code
    IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- OPM品目ID
  TYPE xml_item_id
    IS TABLE OF xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- 品目
  TYPE xml_item_code
    IS TABLE OF xxinv_mov_lot_details.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ロットID
  TYPE xml_lot_id
    IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- ロットNo
  TYPE xml_lot_no
    IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- 実績日
  TYPE xml_actual_date
    IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE INDEX BY BINARY_INTEGER;
  -- 実績数量
  TYPE xml_actual_quantity
    IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
-- 2009/01/22 Y.Yamamoto #1037 add start
-- 訂正前実績数量
  TYPE xml_bfr_actual_quantity
    IS TABLE OF xxinv_mov_lot_details.before_actual_quantity%TYPE INDEX BY BINARY_INTEGER;
-- 2009/01/22 Y.Yamamoto #1037 add end
  -- 自動手動引当区分
  TYPE xml_automanual_rsv_class
    IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- 作成者
  TYPE xml_created_by
    IS TABLE OF xxinv_mov_lot_details.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- 作成日
  TYPE xml_creation_date
    IS TABLE OF xxinv_mov_lot_details.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新者
  TYPE xml_last_updated_by
    IS TABLE OF xxinv_mov_lot_details.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新日
  TYPE xml_last_update_date
    IS TABLE OF xxinv_mov_lot_details.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- 最終更新ログイン
  TYPE xml_last_update_login
    IS TABLE OF xxinv_mov_lot_details.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- 要求ID
  TYPE xml_request_id
    IS TABLE OF xxinv_mov_lot_details.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- アプリケーションID
  TYPE xml_program_application_id
    IS TABLE OF xxinv_mov_lot_details.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- コンカレント・プログラムID
  TYPE xml_program_id
    IS TABLE OF xxinv_mov_lot_details.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- プログラム更新日
  TYPE xml_program_update_date
    IS TABLE OF xxinv_mov_lot_details.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- 移動ロット詳細一括登録用
  gt_xml_mov_lot_dtl_id            xml_mov_lot_dtl_id;            -- ロット詳細ID
  gt_xml_mov_line_id               xml_mov_line_id;               -- 明細ID
  gt_xml_document_type_code        xml_document_type_code;        -- 文書タイプ
  gt_xml_record_type_code          xml_record_type_code;          -- レコードタイプ
  gt_xml_item_id                   xml_item_id;                   -- OPM品目ID
  gt_xml_item_code                 xml_item_code;                 -- 品目
  gt_xml_lot_id                    xml_lot_id;                    -- ロットID
  gt_xml_lot_no                    xml_lot_no;                    -- ロットNo
  gt_xml_actual_date               xml_actual_date;               -- 実績日
  gt_xml_actual_quantity           xml_actual_quantity;           -- 実績数量
-- 2009/01/22 Y.Yamamoto #1037 add start
  gt_xml_bfr_actual_quantity       xml_bfr_actual_quantity;       -- 訂正前実績数量
-- 2009/01/22 Y.Yamamoto #1037 add end
  gt_xml_automanual_rsv_class      xml_automanual_rsv_class;      -- 自動手動引当区分
  gt_xml_created_by                xml_created_by;                -- 作成者
  gt_xml_creation_date             xml_creation_date;             -- 作成日
  gt_xml_last_updated_by           xml_last_updated_by;           -- 最終更新者
  gt_xml_last_update_date          xml_last_update_date;          -- 最終更新日
  gt_xml_last_update_login         xml_last_update_login;         -- 最終更新ログイン
  gt_xml_request_id                xml_request_id;                -- 要求ID
  gt_xml_program_application_id    xml_program_application_id;    -- アプリケーションID
  gt_xml_program_id                xml_program_id;                -- コンカレント・プログラムID
  gt_xml_program_update_date       xml_program_update_date;       -- プログラム更新日
--
  -- 受注ヘッダアドオン 最新フラグ 一括更新用
  gt_xoh_a10_order_header_id     xoh_order_header_id;        -- 受注ヘッダアドオンID
  gt_xoh_a10_last_updated_by     xoh_last_updated_by;        -- 最終更新者
  gt_xoh_a10_last_update_date    xoh_last_update_date;       -- 最終更新日
  gt_xoh_a10_last_update_login   xoh_last_update_login;      -- 最終更新ログイン
  gt_xoh_a10_request_id          xoh_request_id;             -- 要求ID
  gt_xoh_a10_program_appli_id    xoh_program_application_id; -- アプリケーションID
  gt_xoh_a10_program_id          xoh_program_id;             -- コンカレント・プログラムID
  gt_xoh_a10_program_update_date xoh_program_update_date;    -- プログラム更新日
--
  -- 受注ヘッダアドオン 受注タイプ・登録順序 一括更新用
  gt_xoh_a12_order_header_id      xoh_order_header_id;        -- 受注ヘッダアドオンID
  gt_xoh_a12_order_type_id        xoh_order_type_id;          -- 受注タイプID
  gt_xoh_a12_last_updated_by      xoh_last_updated_by;        -- 最終更新者
  gt_xoh_a12_last_update_date     xoh_last_update_date;       -- 最終更新日
  gt_xoh_a12_last_update_login    xoh_last_update_login;      -- 最終更新ログイン
  gt_xoh_a12_request_id           xoh_request_id;             -- 要求ID
  gt_xoh_a12_program_appli_id     xoh_program_application_id; -- アプリケーションID
  gt_xoh_a12_program_id           xoh_program_id;             -- コンカレント・プログラムID
  gt_xoh_a12_program_update_date  xoh_program_update_date;    -- プログラム更新日
--
  -- 受注明細アドオン 数量・拠点依頼数量 一括更新用
  gt_xol_a13_order_line_id       xol_order_line_id;           -- 受注明細アドオンID
  gt_xol_a13_order_header_id     xol_order_header_id;         -- 受注ヘッダアドオンID
  gt_xol_a13_order_line_number   xol_order_line_number;       -- 明細番号
  gt_xol_a13_request_no          xol_request_no;              -- 依頼No
  gt_xol_a13_shipping_item_id    xol_shipping_item_id;        -- 出荷品目ID
  gt_xol_a13_shipping_item_code  xol_shipping_item_code;      -- 出荷品目
  gt_xol_a13_quantity            xol_quantity;                -- 数量
  gt_xol_a13_uom_code            xol_uom_code;                -- 単位
  gt_xol_a13_shipped_quantity    xol_shipped_quantity;        -- 出荷実績数量
  gt_xol_a13_based_req_quant     xol_based_request_quantity;  -- 拠点依頼数量
  gt_xol_a13_request_item_id     xol_request_item_id;         -- 依頼品目ID
  gt_xol_a13_request_item_code   xol_request_item_code;       -- 依頼品目
  gt_xol_a13_rm_if_flg           xol_rm_if_flg;               -- 倉替返品インタフェース済フラグ
  gt_xol_a13_created_by          xol_created_by;              -- 作成者
  gt_xol_a13_creation_date       xol_creation_date;           -- 作成日
  gt_xol_a13_last_updated_by     xol_last_updated_by;         -- 最終更新者
  gt_xol_a13_last_update_date    xol_last_update_date;        -- 最終更新日
  gt_xol_a13_last_update_login   xol_last_update_login;       -- 最終更新ログイン
  gt_xol_a13_request_id          xol_request_id;              -- 要求ID
  gt_xol_a13_program_appli_id    xol_program_application_id;  -- アプリケーションID
  gt_xol_a13_program_id          xol_program_id;              -- コンカレント・プログラムID
  gt_xol_a13_program_update_date xol_program_update_date;     -- プログラム更新日
--
  -- 受注ヘッダアドオンID 保存用
  gt_xoh_a7_13_order_header_id         xoh_order_header_id;  -- 受注ヘッダアドオンID
--
  -- 受注ヘッダアドオン 合計数量 一括更新用
  gt_xoh_a15_order_header_id     xoh_order_header_id;        -- 受注ヘッダアドオンID
  gt_xoh_a15_sum_quantity        xoh_sum_quantity;           -- 合計数量
  gt_xoh_a15_last_updated_by     xoh_last_updated_by;        -- 最終更新者
  gt_xoh_a15_last_update_date    xoh_last_update_date;       -- 最終更新日
  gt_xoh_a15_last_update_login   xoh_last_update_login;      -- 最終更新ログイン
  gt_xoh_a15_request_id          xoh_request_id;             -- 要求ID
  gt_xoh_a15_program_appli_id    xoh_program_application_id; -- アプリケーションID
  gt_xoh_a15_program_id          xoh_program_id;             -- コンカレント・プログラムID
  gt_xoh_a15_program_update_date xoh_program_update_date;    -- プログラム更新日
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_input_reserve_cnt  NUMBER; -- 入力件数(倉替返品インターフェース)
--
  gn_output_headers_cnt NUMBER; -- 倉替返品情報作成件数(受注ヘッダアドオン単位)
  gn_output_lines_cnt   NUMBER; -- 倉替返品情報作成件数(受注明細アドオン単位)
  gn_output_lot_cnt     NUMBER; -- 倉替返品情報作成件数(移動ロット詳細)
--
  gn_output_del_hd_cnt  NUMBER; -- 倉替返品打消情報作成件数(受注ヘッダアドオン単位)
  gn_output_del_ln_cnt  NUMBER; -- 倉替返品打消情報作成件数(受注明細アドオン単位)
  gn_output_del_lot_cnt NUMBER; -- 倉替返品打消情報作成件数(移動ロット詳細単位)
--
  gn_output_upd_hd_cnt  NUMBER; -- 倉替返品更新情報作成件数(受注ヘッダアドオン単位)
  gn_output_upd_ln_cnt  NUMBER; -- 倉替返品更新情報作成件数(受注明細アドオン単位)
--
  gt_reserve_interface_tbl reserve_interface_tbl; -- 倉替返品インターフェース格納用
  gt_order_all_tbl         order_all_tbl;  -- 受注ヘッダアドオン・受注明細アドオン・移動ロット詳細格納用
--
  gv_org_id                VARCHAR2(150);         -- マスター組織ID
  gv_max_date              VARCHAR2(150);         -- MAX日付
--
  gt_request_no          xxwsh_order_headers_all.request_no%TYPE;          -- 変換後依頼No
  gt_registered_sequence xxwsh_order_headers_all.registered_sequence%TYPE; -- 登録順序
--
  -- 取引タイプID(返品)
  gt_transact_type_id_return  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- 取引タイプID(受注)
  gt_transact_type_id_order   xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
--
  -- 受注タイプ(新規/訂正).取引タイプID
  gt_new_transaction_type_id  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- 受注タイプ(新規/訂正).受注カテゴリ
  gt_new_transaction_catg_code  xxwsh_oe_transaction_types_v.transaction_type_code%TYPE;
  -- 受注タイプ(打消).取引タイプID
  gt_del_transaction_type_id  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- 受注タイプ(打消).受注カテゴリ
  gt_del_transaction_catg_code  xxwsh_oe_transaction_types_v.transaction_type_code%TYPE;
--
  -- OPM品目情報VIEW.品目ID
  gt_item_id               xxcmn_item_mst_v.item_id%TYPE;
  -- OPM品目情報VIEW.単位
  gt_item_um               xxcmn_item_mst_v.item_um%TYPE;
  -- 倉替返品インターフェース.伝票No
  gt_invoice_no            xxwsh_reserve_interface.invoice_no%TYPE;
  -- 品目カテゴリ情報VIEW3.商品区分
  gt_item_class            xxcmn_item_categories3_v.prod_class_code%TYPE;
  -- OPM保管場所マスタ.保管倉庫ID(出荷元ID)
  gt_inventory_location_id mtl_item_locations.inventory_location_id%TYPE;
  -- パーティサイト情報VIEW.パーティID(拠点ID)
  gt_party_id              xxcmn_party_sites_v.party_id%TYPE;
  -- パーティサイト情報VIEW.パーティサイトID(出荷先ID)
  gt_party_site_id         xxcmn_party_sites_v.party_site_id%TYPE;
  -- パーティサイト情報VIEW.サイト番号(出荷先)
  gt_party_site_number     xxcmn_party_sites_v.party_site_number%TYPE;
--
  gn_idx_hd      NUMBER;  -- 配列インデックス 受注ヘッダアドオン 一括登録用
  gn_idx_ln      NUMBER;  -- 配列インデックス 受注明細アドオン 一括登録用
  gn_idx_lot     NUMBER;  -- 配列インデックス 移動ロット詳細 一括登録用
--
  gn_idx_hd_a10  NUMBER;  -- 配列インデックス 受注ヘッダアドオン 最新フラグ 一括更新用
  gn_idx_hd_a12  NUMBER;  -- 配列インデックス 受注ヘッダアドオン 受注タイプ・登録順序 一括更新用
  gn_idx_ln_a13  NUMBER;  -- 配列インデックス 受注明細アドオン 数量・拠点依頼数量 一括更新用
  gn_idx_hd_a15  NUMBER;  -- 配列インデックス 受注ヘッダアドオン 合計数量 一括更新用
--
  gn_seq_hd      NUMBER;  -- シーケンス(受注ヘッダアドオン.受注ヘッダアドオンID)
  gn_seq_a9      NUMBER;  -- シーケンス A-9で設定した受注ヘッダアドオンID
  gn_seq_a12     NUMBER;  -- A-12で設定した受注ヘッダアドオンID
--
  gt_line_number_a11  xxwsh_order_lines_all.order_line_number%TYPE; -- A-11でセットする明細番号
--
  gt_sum_quantity     xxwsh_reserve_interface.quantity%TYPE;        -- 合算数量
--
  gb_posi_flg  BOOLEAN;   -- 明細数量チェックフラグ 数量>=0の場合TRUE
  gb_nega_flg  BOOLEAN;   -- 明細数量チェックフラグ 数量< 0の場合TRUE
--
  gb_a11_flg   BOOLEAN;    -- A-11-2を行うかどうかを制御するフラグ
--
  gt_user_id         xxwsh_order_headers_all.created_by%TYPE;             -- 作成者(最終更新者)
  gt_sysdate         xxwsh_order_headers_all.creation_date%TYPE;          -- 作成日(最終更新日)
  gt_login_id        xxwsh_order_headers_all.last_update_login%TYPE;      -- 最終更新ログイン
  gt_conc_request_id xxwsh_order_headers_all.request_id%TYPE;             -- 要求ID
  gt_prog_appl_id    xxwsh_order_headers_all.program_application_id%TYPE; -- アプリケーションID
  gt_conc_program_id xxwsh_order_headers_all.program_id%TYPE; -- コンカレント・プログラムID
--
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : プロファイル取得処理 (A-1)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_profile';  -- プログラム名
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
    cv_org_id       CONSTANT VARCHAR2(30) := 'マスター組織ID';
    cv_max_date     CONSTANT VARCHAR2(30) := 'MAX日付';
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
    -- **************************************************
    -- *** プロファイル取得：マスター組織ID
    -- **************************************************
    gv_org_id := TRIM(FND_PROFILE.VALUE(gv_prf_org_id));
--
    IF (gv_org_id IS NULL) THEN  -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_noprof_err,
        gv_tkn_prof_name,
        cv_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** プロファイル取得：MAX日付
    -- **************************************************
    gv_max_date := TRIM(FND_PROFILE.VALUE(gv_prf_max_date));
--
    IF (gv_max_date IS NULL) THEN  -- プロファイルが取得できない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_noprof_err,
        gv_tkn_prof_name,
        cv_max_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_interface
   * Description      : 倉替返品インターフェース情報抽出処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_reserve_interface(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_reserve_interface';  -- プログラム名
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
    cv_xxwsh_reserve_interface CONSTANT VARCHAR2(50) := '倉替返品インターフェース';
--
    -- *** ローカル変数 ***
    lb_rtn_cd      BOOLEAN;                                  -- 共通関数のリターンコード
    lt_invoice_no  xxwsh_reserve_interface.invoice_no%TYPE;  -- 伝票No
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
    -- **************************************************
    -- *** 倉替返品インターフェース テーブルロック
    -- **************************************************
    lb_rtn_cd := xxcmn_common_pkg.get_tbl_lock(gv_xxwsh, gv_reserve_interface);
--
    IF (NOT lb_rtn_cd) THEN         -- 共通関数のリターンコードがエラーの場合
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_table_lock_err,
        gv_tkn_table,
        cv_xxwsh_reserve_interface);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** 倉替返品インターフェース情報存在チェック
    -- **************************************************
    SELECT COUNT(xri.reserve_interface_id) AS cnt  -- 件数
    INTO   gn_input_reserve_cnt                    -- 入力件数(倉替返品インターフェース)
    FROM   xxwsh_reserve_interface  xri;           -- 倉替返品インターフェース
--
    IF (gn_input_reserve_cnt < 1) THEN             -- 1件も存在しない場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_nodata_err);
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    -- **************************************************
    -- *** 同一伝票No内ヘッダ相違チェック
    -- **************************************************
    BEGIN
      SELECT MIN(xri_grp.invoice_no) AS min_invoice_no -- 重複している伝票Noの最も小さいもの
      INTO   lt_invoice_no
      FROM
        (SELECT   xri.invoice_no,                         -- 伝票No
                  xri.recorded_year,                      -- 計上年月
                  xri.input_base_code,                    -- 入力拠点コード
                  xri.receive_base_code,                  -- 相手拠点コード
                  xri.recorded_date                       -- 計上日付（着日）
         FROM     xxwsh_reserve_interface  xri            -- 倉替返品インターフェース
         GROUP BY xri.invoice_no,                         -- 伝票No
                  xri.recorded_year,                      -- 計上年月
                  xri.input_base_code,                    -- 入力拠点コード
                  xri.receive_base_code,                  -- 相手拠点コード
                  xri.recorded_date                       -- 計上日付（着日）
        ) xri_grp
      GROUP BY xri_grp.invoice_no                         -- 伝票Noごとの件数
      HAVING COUNT(xri_grp.invoice_no) >= 2;              -- 伝票Noごとの件数>同一伝票No内2件以上
--
      -- 伝票Noが取得できた場合は、同一伝票No内ヘッダ相違エラー
      IF (lt_invoice_no IS NOT NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_invoice_no_err,
          gv_tkn_den_no,
          lt_invoice_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- 取得データなしの場合は重複していないためOK
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;  -- 何もしない
    END;
--
    -- **************************************************
    -- *** 倉替返品インターフェース情報抽出
    -- **************************************************
    SELECT xri2.recorded_year,                     -- 計上年月
           xri2.input_base_code,                   -- 入力拠点コード
           xri2.receive_base_code,                 -- 相手拠点コード
           xri2.invoice_class_1,                   -- 伝区１
           xri2.recorded_date,                     -- 計上日付(着日)
           xri2.invoice_no,                        -- 伝票No
           xri2.item_no,                           -- 品目コード(OPM品目情報VIEW)
           xri2.quantity_total                     -- 数量
-- 2009/10/20 H.Itou Add Start 本番障害#1569
          ,xri2.recorded_year     || gv_comma ||
           xri2.input_base_code   || gv_comma ||
           xri2.receive_base_code || gv_comma ||
           xri2.invoice_class_1   || gv_comma ||
           xri2.invoice_no        || gv_comma ||
           xri2.item_no           || gv_comma ||
           xri2.quantity_total                   data_dump -- データダンプ
-- 2009/10/20 H.Itou Add End
    BULK COLLECT INTO gt_reserve_interface_tbl
    FROM (SELECT xri.recorded_year,                -- 計上年月
                 xri.input_base_code,              -- 入力拠点コード
                 xri.receive_base_code,            -- 相手拠点コード
                 xri.invoice_class_1,              -- 伝区１
                 xri.recorded_date,                -- 計上日付(着日)
                 xri.invoice_no,                   -- 伝票No
                 xim.item_no,                      -- 品目コード(OPM品目情報VIEW)
/* 2008/08/07 Mod ↓
                 SUM(NVL(xri.case_amount_of_content,0) * TO_NUMBER(NVL(xim.num_of_cases,'0'))
2008/08/07 Mod ↑ */
                 SUM(NVL(xri.case_amount_of_content,0)
                   * TO_NUMBER(DECODE(NVL(xim.num_of_cases,'0'),'0','1',xim.num_of_cases))
                   + NVL(xri.quantity,0))
                              OVER (PARTITION BY xri.invoice_no, -- 伝票No
                                                 xri.item_code   -- 品目コードエントリーごとに
                                   ) AS quantity_total,          -- サマリーして数量を求める
                 ROW_NUMBER() OVER (PARTITION BY xri.invoice_no, -- 伝票No
                                                 xri.item_code   -- 品目コードエントリーごとに
                                    ORDER BY     xri.invoice_class_1  -- 伝区１(昇順)
                                   ) AS rank
          FROM   xxwsh_reserve_interface  xri,      -- 倉替返品インターフェース
                 xxcmn_item_mst_v         xim       -- OPM品目情報VIEWを外部結合
          WHERE  xri.item_code = xim.item_no(+)     -- 品目コード
         ) xri2
    WHERE xri2.rank = 1 -- 伝票No・品目コードエントリーごとに伝区１が最小値のレコードを抽出
    ORDER BY xri2.invoice_no,   -- 伝票No
             xri2.item_no;      -- 品目コード(OPM品目情報VIEW)
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
    WHEN no_data_expt THEN     -- 処理対象データ0件（警告）
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
  END get_reserve_interface;
--
--
  /**********************************************************************************
   * Procedure Name   : check_master
   * Description      : マスタ存在チェック処理 (A-3)
   ***********************************************************************************/
  PROCEDURE check_master(
    it_invoice_no         IN  xxwsh_reserve_interface.invoice_no%TYPE,        -- 1.伝票No
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                     -- 2.品目コード
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 3.相手拠点コード
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 4.入力拠点コード
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'check_master'; -- プログラム名
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
    cv_xxwsh_col_item_no           VARCHAR2(50) := '品目';
    cv_xxwsh_tbl_item_no           VARCHAR2(50) := '品目マスタ';
    cv_xxwsh_tbl_item_class        VARCHAR2(50) := '商品区分';
    cv_xxwsh_col_receive_base      VARCHAR2(50) := '納入先（出荷元）';
    cv_xxwsh_tbl_receive_base      VARCHAR2(50) := 'OPM保管場所マスタ';
    cv_xxwsh_col_input_base        VARCHAR2(50) := '入力拠点';
    cv_xxwsh_tbl_input_base        VARCHAR2(50) := '顧客マスタ';
--
    -- *** ローカル変数 ***
    lt_item_class xxcmn_item_categories3_v.prod_class_code%TYPE; -- 品目カテゴリ情報VIEW3.商品区分
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
    -- **************************************************
    -- *** 品目ID・単位の取得
    -- **************************************************
    BEGIN
--      SELECT imv.item_id,                 -- 品目ID
      SELECT imv.inventory_item_id,                 -- 品目ID
             imv.item_um                  -- 単位
      INTO   gt_item_id,
             gt_item_um
      FROM   xxcmn_item_mst_v  imv        -- 品目マスタ情報VIEW
      WHERE  imv.item_no = it_item_no;    -- 品目コード
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN             -- マスタに存在しない場合はエラー(品目存在チェック)
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_item_no,
          gv_tkn_table,
          cv_xxwsh_tbl_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** 商品区分チェック
    -- **************************************************
    BEGIN
      SELECT icv.prod_class_code                  -- 商品区分
      INTO   lt_item_class
      FROM   xxcmn_item_categories5_v  icv        -- 品目カテゴリ情報VIEW5
      WHERE  icv.item_no = it_item_no;            -- 品目コード
--
      IF (lt_item_class IS NULL) THEN             -- 商品区分に値が登録されていない場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_prod_get_err,
          gv_tkn_input_item,
          it_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      IF (gt_invoice_no = it_invoice_no) THEN       -- 伝票Noが同じ場合
        IF (gt_item_class <> lt_item_class) THEN    -- 同一伝票No内で商品区分が異なる場合はエラー
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_category_err,
            gv_tkn_ctg_name,
            cv_xxwsh_tbl_item_class);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE                                           -- 伝票Noが変わった場合
        gt_invoice_no := it_invoice_no;              -- 伝票Noを退避
        gt_item_class := lt_item_class;              -- 商品区分を退避
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                      -- マスタに存在しない場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_prod_get_err,
          gv_tkn_input_item,
          it_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** 納入先（出荷元）チェック
    -- **************************************************
    BEGIN
      SELECT mil.inventory_location_id            -- 保管倉庫ID
      INTO   gt_inventory_location_id
--      FROM   mtl_item_locations  mil              -- OPM保管場所マスタ
      FROM   xxcmn_item_locations_v  mil          -- OPM保管場所情報View
      WHERE  mil.segment1 = it_receive_base_code; -- 保管倉庫コード=相手拠点コード
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                 -- マスタに存在しない場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_receive_base,
          gv_tkn_table,
          cv_xxwsh_tbl_receive_base);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** 入力拠点チェック
    -- **************************************************
    BEGIN
      SELECT xps.party_id,                              -- パーティID（拠点ID）
             xps.party_site_id,                         -- パーティサイトID（出荷先ID）
             xps.party_site_number                      -- サイト番号（出荷先）
      INTO   gt_party_id,
             gt_party_site_id,
             gt_party_site_number
--      FROM   hz_parties           hzp,                  -- パーティマスタ
      FROM   xxcmn_cust_accounts_v    hzp,                  -- 顧客情報View
             xxcmn_cust_acct_sites_v  xps                   -- 顧客サイト情報VIEW
      WHERE  hzp.party_number = it_input_base_code      -- 組織番号=入力拠点コード
-- 2009/04/09 ADD START
        AND  hzp.customer_class_code IN ('1','10')
-- 2009/04/09 ADD END
        AND  hzp.party_id     = xps.party_id            -- パーティID
        AND  xps.primary_flag = 'Y';                    -- 主フラグ
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                       -- マスタに存在しない場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_input_base,
          gv_tkn_table,
          cv_xxwsh_tbl_input_base);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END check_master;
--
--
  /**********************************************************************************
   * Procedure Name   : check_stock
   * Description      : 在庫会計期間チェック処理 (A-4)
   ***********************************************************************************/
  PROCEDURE check_stock(
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,    -- 1.計上日付(着日)
-- 2009/10/20 H.Itou Add Start 本番障害#1569
    iv_data_dump          IN  VARCHAR2,                                      -- 2.データダンプ
-- 2009/10/20 H.Itou Add End
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'check_stock';  -- プログラム名
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
    lv_close_date     VARCHAR2(6);  -- OPM在庫会計期間CLOSE年月(yyyymm)
    lv_recorded_date  VARCHAR2(6);  -- 計上日付（着日）(yyyymm)
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
    -- **************************************************
    -- *** OPM在庫会計期間CLOSE年月取得
    -- **************************************************
    -- 計上日付（着日）を年月に変換
    lv_recorded_date := TO_CHAR(it_recorded_date,'yyyymm');
    -- 共通関数からOPM在庫会計期間CLOSE年月を取得
    lv_close_date := xxcmn_common_pkg.get_opminv_close_period;
--
    IF (lv_close_date IS NULL) THEN             -- CLOSE年月取得エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_closeym_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (lv_close_date >= lv_recorded_date) THEN -- CLOSE年月>=計上日付（着日）の場合はエラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_stock_from_err,
        gv_tkn_arrival_date,
        lv_recorded_date);
-- 2009/10/20 H.Itou Mod Start 本番障害#1569 在庫クローズエラーのときは警告とし、後続処理をスキップする。
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,iv_data_dump); -- データダンプ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);    -- 在庫クローズエラーメッセージ
        ov_retcode := gv_status_warn;
-- 2009/10/20 H.Itou Mod End
    END IF;
--
    -- CLOSE年月=プロファイルから取得したMAX日付の場合はエラー
    IF (lv_close_date = SUBSTRB(gv_max_date,1,4) || SUBSTRB(gv_max_date,6,2)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_stock_get_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END check_stock;
--
--
  /**********************************************************************************
   * Procedure Name   : get_order_type
   * Description      : 関連データ取得処理 (A-5)
   ***********************************************************************************/
  PROCEDURE get_order_type(
    it_invoice_class_1    IN  xxwsh_reserve_interface.invoice_class_1%TYPE,        -- 1.伝区１
    it_invoice_no         IN  xxwsh_reserve_interface.invoice_no%TYPE,             -- 2.伝票No
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,          -- 3.計上日付（着日）2008/10/10 v1.5 M.Hirafuku ADD
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                          -- 4.品目コード      2008/10/10 v1.5 M.Hirafuku ADD
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,               -- 5.数量            2008/10/10 v1.5 M.Hirafuku ADD
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_order_type';  -- プログラム名
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
    cv_status_normal  CONSTANT NUMBER := 0;         -- 正常終了
    cv_inbound        CONSTANT VARCHAR2(1) := '1';  -- 変換区分：拠点からのInBound用
    -- 2008/10/10 v1.5 M.Hirafuku ADD ST
    cv_lot_no       CONSTANT VARCHAR2(10) := '9999999999';                 -- ロットNo
-- 2008/11/25 v1.6 T.Yoshimoto Mod Start 本番#243
    --cv_attribute1   CONSTANT VARCHAR2(10) := '2000/01/01';                 -- 製造年月日
    cv_attribute1   CONSTANT VARCHAR2(10) := '1900/01/01';                 -- 製造年月日
-- 2008/11/25 v1.6 T.Yoshimoto Mod End 本番#243
    cv_attribute2   CONSTANT VARCHAR2(4)  := 'ZZZZ';                       -- 固有記号
    cv_attribute3   CONSTANT VARCHAR2(10) := '2099/12/31';                 -- 賞味期限
    cv_attribute23  CONSTANT VARCHAR2(2)  := '50';                         -- ロットステータス
    cv_cons_lot_ctl CONSTANT VARCHAR2(1)  := '1';                          -- 「ロット管理品」
    cv_errmsg       CONSTANT VARCHAR2(30) := 'ロット作成に失敗しました。'; -- APIエラーメッセージ
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
--
    -- *** ローカル変数 ***
    ln_rtn_cd     NUMBER;        -- 共通関数のリターンコード
    ln_dummy      NUMBER;
--
    -- 2008/10/10 v1.5 M.Hirafuku ADD ST
--    lt_item_no       ic_item_mst_b.item_no%TYPE;
    lb_return_status BOOLEAN;
    lr_create_lot    GMIGAPI.lot_rec_typ;
    lt_dm_cnt        NUMBER := 0;
    lt_lot_chk       NUMBER := 0;
    or_lot_mst       ic_lots_mst%ROWTYPE;
    or_lot_cpg       ic_lots_cpg%ROWTYPE;
    or_return        VARCHAR2(1);                             -- リターンステータス
    or_msg_cnt       NUMBER;                                  -- メッセージ件数
    or_msg_data      VARCHAR2(10000);                         -- メッセージ
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
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
    -- **************************************************
    -- *** 受注タイプID導出処理
    -- **************************************************
    BEGIN
      gt_transact_type_id_return := NULL;    -- 取引タイプID(返品)
      gt_transact_type_id_order  := NULL;    -- 取引タイプID(受注)
--
      -- 在庫受入用(受注カテゴリ=返品)の取引タイプIDを取得
      SELECT xtv.transaction_type_id         -- 取引タイプID
      INTO   gt_transact_type_id_return
      FROM   xxwsh_oe_transaction_types_v  xtv,  -- 受注タイプView
             xxwsh_shipping_class_v        xsv   -- 出荷区分View
      WHERE  xtv.transaction_type_name = xsv.order_transaction_type_name  -- 取引タイプ名で結合
        AND  xtv.order_category_code   = gv_cate_return                   -- 取引タイプ名=返品
        AND  xsv.invoice_class_1       = it_invoice_class_1;
--
      -- 在庫払出用(受注カテゴリ=受注)の取引タイプIDを取得
      SELECT xtv.transaction_type_id         -- 取引タイプID
      INTO   gt_transact_type_id_order
      FROM   xxwsh_oe_transaction_types_v  xtv,  -- 受注タイプView
             xxwsh_shipping_class_v        xsv   -- 出荷区分View
      WHERE  xtv.cancel_order_type     = xsv.order_transaction_type_name  -- 取引タイプ名で結合
        AND  xtv.order_category_code   = gv_cate_order                    -- 取引タイプ名=受注
        AND  xsv.invoice_class_1       = it_invoice_class_1;
--
      -- 値が設定されていない場合はエラー
      IF ((gt_transact_type_id_return IS NULL)
--      OR  (gt_transact_type_id_order IS NULL)) THEN
      AND  (gt_transact_type_id_order IS NULL)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_type_get_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      -- 取得できなかった場合はエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_type_get_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
-- 2009/10/20 H.Itou Mod Start 本番障害#1591
--    -- **************************************************
--    -- *** 依頼No導出処理
--    -- **************************************************
--    gt_request_no := NULL;     -- 共通関数で伝票No(9桁)を依頼No(12桁)に変換する
--    ln_rtn_cd := xxwsh_common_pkg.convert_request_number(
--      cv_inbound,              -- 変換区分
--      it_invoice_no,           -- 変換前伝票No
--      gt_request_no);          -- 変換後依頼No
----
--    IF ((ln_rtn_cd <> cv_status_normal)        -- 共通関数のリターンコードがエラーの場合
--    OR  (gt_request_no IS NULL)) THEN          -- 変換後依頼NoがNULLの場合はエラー
--      lv_errmsg := xxcmn_common_pkg.get_msg(
--        gv_xxwsh,
--        gv_xxwsh_request_no_conv_err);
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
    gt_request_no := it_invoice_no;
-- 2009/10/20 H.Itou Mod End
--
    -- **************************************************
    -- *** ダミーロット設定処理 2008/10/10 v1.5 M.Hirafuku ADD ST
    -- **************************************************
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    -- 「返品」A-2で取得した数量>=0(正)の場合
    IF (it_quantity_total >= 0) THEN
--
      -- ダミーロット存在チェック
      SELECT COUNT(*)
      INTO   lt_dm_cnt
      FROM   ic_lots_mst ilm        -- OPMロットマスタ
            ,xxcmn_item_mst2_v ximv -- OPM品目情報VIEW2
      WHERE ilm.lot_no              = cv_lot_no
      AND   ilm.item_id             = ximv.item_id
      AND   ximv.lot_ctl            = cv_cons_lot_ctl
      AND   ximv.inventory_item_id  = gt_item_id
      AND   ximv.start_date_active <= TRUNC(it_recorded_date)
      AND   ximv.end_date_active   >= TRUNC(it_recorded_date);
--
      -- ダミーロット作成
      IF (lt_dm_cnt <= 0) THEN
--
        -- ロット管理品チェック
        SELECT COUNT(*)
        INTO   lt_lot_chk
        FROM   xxcmn_item_mst2_v ximv -- OPM品目情報VIEW2
        WHERE ximv.lot_ctl            = cv_cons_lot_ctl
        AND   ximv.inventory_item_id  = gt_item_id
        AND   ximv.start_date_active <= TRUNC(it_recorded_date)
        AND   ximv.end_date_active   >= TRUNC(it_recorded_date);
--
        -- ロット管理の場合
        IF (lt_lot_chk > 0) THEN
--
          -- 設定値
          lr_create_lot.item_no     := it_item_no;           -- 品目No
          lr_create_lot.lot_no      := cv_lot_no;            -- ロットNo
          lr_create_lot.attribute1  := cv_attribute1;        -- 製造年月日
          lr_create_lot.attribute2  := cv_attribute2;        -- 固有記号
          lr_create_lot.attribute3  := cv_attribute3;        -- 賞味期限
          lr_create_lot.attribute23 := cv_attribute23;       -- ロットステータス
          lr_create_lot.user_name   := FND_GLOBAL.USER_NAME; -- ユーザ
          lr_create_lot.lot_created := SYSDATE;              -- 作成年月日
-- 2008/12/22 v1.7 ADD START
          lr_create_lot.expaction_date := TO_DATE('2099/12/31', 'YYYY/MM/DD');
          lr_create_lot.expire_date    := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 v1.7 ADD END
--
          --ロット作成API
          GMIPAPI.CREATE_LOT(
             p_api_version      => 3.0                          -- IN  NUMBER
            ,p_init_msg_list    => FND_API.G_FALSE              -- IN  VARCHAR2 default fnd_api.g_false
            ,p_commit           => FND_API.G_FALSE              -- IN  VARCHAR2 default fnd_api.g_false
            ,p_validation_level => FND_API.G_VALID_LEVEL_FULL   -- IN  NUMBER   default fnd_api.g_valid_level_full
            ,p_lot_rec          => lr_create_lot                -- IN  GMIGAPI.lot_rec_typ
            ,x_ic_lots_mst_row  => or_lot_mst                   -- OUT ic_lots_mst%ROWTYPE
            ,x_ic_lots_cpg_row  => or_lot_cpg                   -- OUT ic_lots_cpg%ROWTYPE
            ,x_return_status    => or_return                    -- OUT VARCHAR2
            ,x_msg_count        => or_msg_cnt                   -- OUT NUMBER
            ,x_msg_data         => or_msg_data                  -- OUT VARCHAR2
          );
--
          -- APIエラー
          IF (or_return <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_errbuf  := or_msg_data;
            lv_errmsg  := ov_errmsg || cv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        END IF;
--
      END IF;
    END IF;
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END get_order_type;
--
--
  /**********************************************************************************
   * Procedure Name   : get_order_all_tbl
   * Description      : 同一依頼No抽出処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_order_all_tbl(
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,     -- 1.計上日付（着日）
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 2.相手拠点コード
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 3.入力拠点コード
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_all_tbl';  -- プログラム名
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
    cv_xxwsh_reserve_interface CONSTANT VARCHAR2(50) := '倉替返品インターフェース';
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
    -- ***********************************************************
    -- *** 同一依頼Noの受注ヘッダアドオン・受注明細アドオン抽出
    -- ***********************************************************
    gt_order_all_tbl.DELETE;
--
    SELECT  xoh.order_header_id            AS xoh_order_header_id,            -- 受注ヘッダアドオンID
            xoh.order_type_id              AS xoh_order_type_id,              -- 受注タイプID
            xoh.organization_id            AS xoh_organization_id,            -- 組織ID
            xoh.latest_external_flag       AS xoh_latest_external_flag,       -- 最新フラグ
            xoh.ordered_date               AS xoh_ordered_date,               -- 受注日
            xoh.customer_id                AS xoh_customer_id,                -- 顧客ID
            xoh.customer_code              AS xoh_customer_code,              -- 顧客
            xoh.deliver_to_id              AS xoh_deliver_to_id,              -- 出荷先ID
            xoh.deliver_to                 AS xoh_deliver_to,                 -- 出荷先
            xoh.shipping_instructions      AS xoh_shipping_instructions,      -- 出荷指示
            xoh.request_no                 AS xoh_request_no,                 -- 依頼No
            xoh.req_status                 AS xoh_req_status,                 -- ステータス
            xoh.schedule_ship_date         AS xoh_schedule_ship_date,         -- 出荷予定日
            xoh.schedule_arrival_date      AS xoh_schedule_arrival_date,      -- 着荷予定日
            xoh.deliver_from_id            AS xoh_deliver_from_id,            -- 出荷元ID
            xoh.deliver_from               AS xoh_deliver_from,               -- 出荷元保管場所
            xoh.head_sales_branch          AS xoh_head_sales_branch,          -- 管轄拠点
            xoh.prod_class                 AS xoh_prod_class,                 -- 商品区分
            xoh.sum_quantity               AS xoh_sum_quantity,               -- 合計数量
            xoh.result_deliver_to_id       AS xoh_result_deliver_to_id,       -- 出荷先_実績ID
            xoh.result_deliver_to          AS xoh_result_deliver_to,          -- 出荷先_実績
            xoh.shipped_date               AS xoh_shipped_date,               -- 出荷日
            xoh.arrival_date               AS xoh_arrival_date,               -- 着荷日
--2008/08/07 Add ↓
            xoh.actual_confirm_class       AS xoh_actual_confirm_class,       -- 実績計上済区分
--2008/08/07 Add ↑
            xoh.perform_managerment_dept   AS xoh_perform_managerment_dept,   -- 成績管理部署
            xoh.registered_sequence        AS xoh_registered_sequence,        -- 登録順序
            xoh.created_by                 AS xoh_created_by,                 -- 作成者
            xoh.creation_date              AS xoh_creation_date,              -- 作成日
            xoh.last_updated_by            AS xoh_last_updated_by,            -- 最終更新者
            xoh.last_update_date           AS xoh_last_update_date,           -- 最終更新日
            xoh.last_update_login          AS xoh_last_update_login,          -- 最終更新ログイン
            xoh.request_id                 AS xoh_request_id,                 -- 要求ID
            xoh.program_application_id     AS xoh_program_application_id,     -- アプリケーションID
            xoh.program_id                 AS xoh_program_id,                 -- コンカレント・プログラムID
            xoh.program_update_date        AS xoh_program_update_date,        -- プログラム更新日
--
            xol.order_line_id              AS xol_order_line_id,              -- 受注明細アドオンID
            xol.order_header_id            AS xol_order_header_id,            -- 受注ヘッダアドオンID
            xol.order_line_number          AS xol_order_line_number,          -- 明細番号
            xol.request_no                 AS xol_request_no,                 -- 依頼No
            xol.shipping_inventory_item_id AS xol_shipping_inventory_item_id, -- 出荷品目ID
            xol.shipping_item_code         AS xol_shipping_item_code,         -- 出荷品目
            xol.quantity                   AS xol_quantity,                   -- 数量
            CASE
              --WHEN (xoh.transaction_type_name = gv_cate_return)  -- 受注タイプ名=返品の場合
              WHEN (xoh.order_category_code = gv_cate_return)  -- 受注カテゴリ=返品の場合
                THEN xol.quantity
              --WHEN (xoh.transaction_type_name = gv_cate_order )  -- 受注タイプ名=受注の場合
--2009/01/06 Y.Kawano Mod Start #908
--              WHEN (xoh.order_category_code = gv_cate_return)  -- 受注カテゴリ=受注の場合
              WHEN (xoh.order_category_code = gv_cate_order)  -- 受注カテゴリ=受注の場合
--2009/01/06 Y.Kawano Mod End   #908
                THEN xol.quantity * -1
              ELSE 0
            END                          AS add_quantity,                 -- 加算用数量
            xol.uom_code                 AS xol_uom_code,                 -- 単位
            xol.shipped_quantity         AS xol_shipped_quantity,         -- 出荷実績数量
            xol.based_request_quantity   AS xol_based_request_quantity,   -- 拠点依頼数量
            xol.request_item_id          AS xol_request_item_id,          -- 依頼品目ID
            xol.request_item_code        AS xol_request_item_code,        -- 依頼品目
            xol.rm_if_flg                AS xol_rm_if_flg,                -- 倉替返品インタフェース済フラグ
            xol.created_by               AS xol_created_by,               -- 作成者
            xol.creation_date            AS xol_creation_date,            -- 作成日
            xol.last_updated_by          AS xol_last_updated_by,          -- 最終更新者
            xol.last_update_date         AS xol_last_update_date,         -- 最終更新日
            xol.last_update_login        AS xol_last_update_login,        -- 最終更新ログイン
            xol.request_id               AS xol_request_id,               -- 要求ID
            xol.program_application_id   AS xol_program_application_id,   -- アプリケーションID
            xol.program_id               AS xol_program_id,               -- コンカレント・プログラムID
            xol.program_update_date      AS xol_program_update_date,      -- プログラム更新日
--
            xml.mov_lot_dtl_id           AS xml_mov_lot_dtl_id,           -- ロット詳細ID
            xml.mov_line_id              AS xml_mov_line_id,              -- 明細ID
            xml.document_type_code       AS xml_document_type_code,       -- 文書タイプ
            xml.record_type_code         AS xml_record_type_code,         -- レコードタイプ
            xml.item_id                  AS xml_item_id,                  -- OPM品目ID
            xml.item_code                AS xml_item_code,                -- 品目
            xml.lot_id                   AS xml_lot_id,                   -- ロットID
            xml.lot_no                   AS xml_lot_no,                   -- ロットNo
            xml.actual_date              AS xml_actual_date,              -- 実績日
            xml.actual_quantity          AS xml_actual_quantity,          -- 実績数量
-- 2009/01/22 Y.Yamamoto #1037 add start
            xml.before_actual_quantity   AS xml_bfr_actual_quantity,      -- 訂正前実績数量
-- 2009/01/22 Y.Yamamoto #1037 add end
            xml.automanual_reserve_class AS xml_automanual_rsv_class,     -- 自動手動引当区分
            xml.created_by               AS xml_created_by,               -- 作成者
            xml.creation_date            AS xml_creation_date,            -- 作成日
            xml.last_updated_by          AS xml_last_updated_by,          -- 最終更新者
            xml.last_update_date         AS xml_last_update_date,         -- 最終更新日
            xml.last_update_login        AS xml_last_update_login,        -- 最終更新ログイン
            xml.request_id               AS xml_request_id,               -- 要求ID
            xml.program_application_id   AS xml_program_application_id,   -- アプリケーションID
            xml.program_id               AS xml_program_id,               -- コンカレント・プログラムID
            xml.program_update_date      AS xml_program_update_date       -- プログラム更新日
    BULK COLLECT INTO gt_order_all_tbl
    FROM
      (
      SELECT oha.order_header_id             AS order_header_id,          -- 受注ヘッダアドオンID
             oha.header_id                   AS header_id,                -- 受注ヘッダID
             oha.order_type_id               AS order_type_id,            -- 受注タイプID
             oha.organization_id             AS organization_id,          -- 組織ID
             oha.latest_external_flag        AS latest_external_flag,     -- 最新フラグ
             oha.ordered_date                AS ordered_date,             -- 受注日
             oha.customer_id                 AS customer_id,              -- 顧客ID
             oha.customer_code               AS customer_code,            -- 顧客
             oha.deliver_to_id               AS deliver_to_id,            -- 出荷先ID
             oha.deliver_to                  AS deliver_to,               -- 出荷先
             oha.shipping_instructions       AS shipping_instructions,    -- 出荷指示
             oha.request_no                  AS request_no,               -- 依頼No
             oha.req_status                  AS req_status,               -- ステータス
             oha.schedule_ship_date          AS schedule_ship_date,       -- 出荷予定日
             oha.schedule_arrival_date       AS schedule_arrival_date,    -- 着荷予定日
             oha.deliver_from_id             AS deliver_from_id,          -- 出荷元ID
             oha.deliver_from                AS deliver_from,             -- 出荷元保管場所
             oha.head_sales_branch           AS head_sales_branch,        -- 管轄拠点
             oha.prod_class                  AS prod_class,               -- 商品区分
             oha.sum_quantity                AS sum_quantity,             -- 合計数量
             oha.result_deliver_to_id        AS result_deliver_to_id,     -- 出荷先_実績ID
             oha.result_deliver_to           AS result_deliver_to,        -- 出荷先_実績
             oha.shipped_date                AS shipped_date,             -- 出荷日
             oha.arrival_date                AS arrival_date,             -- 着荷日
--2008/08/07 Add ↓
             oha.actual_confirm_class        AS actual_confirm_class,     -- 実績計上済区分
--2008/08/07 Add ↑
             oha.performance_management_dept AS perform_managerment_dept, -- 成績管理部署
             oha.registered_sequence         AS registered_sequence,      -- 登録順序
             oha.created_by                  AS created_by,               -- 作成者
             oha.creation_date               AS creation_date,            -- 作成日
             oha.last_updated_by             AS last_updated_by,          -- 最終更新者
             oha.last_update_date            AS last_update_date,         -- 最終更新日
             oha.last_update_login           AS last_update_login,        -- 最終更新ログイン
             oha.request_id                  AS request_id,               -- 要求ID
             oha.program_application_id      AS program_application_id,   -- アプリケーションID
             oha.program_id                  AS program_id,               -- コンカレント・プログラムID
             oha.program_update_date         AS program_update_date,      -- プログラム更新日
             ROW_NUMBER() OVER (PARTITION BY oha.request_no               -- 依頼Noごとに
                                ORDER BY     oha.registered_sequence DESC -- 登録順序(降順)
                               ) AS rank,
             ott.order_category_code         AS order_category_code       -- 受注カテゴリ
      FROM   xxwsh_order_headers_all       oha,                  -- 受注ヘッダアドオン
             xxwsh_oe_transaction_types_v  ott                   -- 受注タイプVIEW
      WHERE  oha.request_no           = gt_request_no            -- 依頼No=A-5で取得した変換後依頼No
        AND  oha.latest_external_flag = gv_flag_on               -- 最新フラグ='Y'
        AND  oha.order_type_id        = ott.transaction_type_id  -- 受注タイプID=取引タイプID
      )  xoh,
      xxwsh_order_lines_all  xol,                                -- 受注明細アドオン
      xxinv_mov_lot_details  xml                                 -- 移動ロット詳細
    WHERE xoh.rank      = 1                                      -- 登録順序が最大のレコードを抽出
      AND xoh.order_header_id = xol.order_header_id              -- 受注ヘッダアドオンID=受注ヘッダアドオンID
      AND xol.order_line_id   = xml.mov_line_id(+)               -- 受注明細アドオンID=明細ID
    ORDER BY xol.shipping_item_code;                             -- 出荷品目(昇順)
--
    -- 同一依頼Noの依頼が登録されている場合(未登録であってもエラーにはしない)
    IF (gt_order_all_tbl.COUNT > 0) THEN    -- 抽出できた場合
--
      -- *****************************************************************************
      -- *** 倉替返品インターフェースと抽出した受注ヘッダアドオンの項目比較チェック
      -- *****************************************************************************
      --計上日付(着日)と出荷予定日、相手拠点と出荷元保管場所、入力拠点と管轄拠点
      IF ((it_recorded_date     <> gt_order_all_tbl(1).hd_schedule_ship_date)
      OR  (it_receive_base_code <> gt_order_all_tbl(1).hd_deliver_from)
      OR  (it_input_base_code   <> gt_order_all_tbl(1).hd_head_sales_branch)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(           -- 値が異なっている場合はエラー
            gv_xxwsh,
            gv_xxwsh_hd_upd_err);
          lv_errbuf :=  lv_errmsg;
          RAISE global_api_expt;
      END IF;
--
      -- *************************************************
      -- *** 受注タイプの補正
      -- *************************************************
      BEGIN
        gt_new_transaction_type_id := NULL;
        --gt_new_transaction_type_name := NULL;
        gt_del_transaction_type_id := NULL;
        --gt_del_transaction_type_name := NULL;
        --
        gt_new_transaction_catg_code := NULL;
        gt_del_transaction_catg_code := NULL;
--
        SELECT otnew.transaction_type_id,           -- 受注タイプ(新規/訂正).取引タイプID
               --otnew.transaction_type_name,         -- 受注タイプ(新規/訂正).受注カテゴリ
               otnew.order_category_code,
               otdel.transaction_type_id,           -- 受注タイプ(打消).取引タイプID
               --otdel.transaction_type_name,          -- 受注タイプ(打消).受注カテゴリ
               otdel.order_category_code
        INTO   gt_new_transaction_type_id,
               --gt_new_transaction_type_name,
               gt_new_transaction_catg_code,
               gt_del_transaction_type_id,
               --gt_del_transaction_type_name,
               gt_del_transaction_catg_code
        FROM   xxwsh_oe_transaction_types_v  otnew,     -- 受注タイプ(新規/訂正)
               xxwsh_oe_transaction_types_v  otdel      -- 受注タイプ(打消)
               -- 受注タイプ(新規/訂正).取引タイプID=A-6で取得した受注タイプID
        WHERE  otnew.transaction_type_id   = gt_order_all_tbl(1).hd_order_type_id
               -- 受注タイプ(打消).取引タイプ=受注タイプ(新規/訂正).取消受注タイプ(DFF5)
          AND  otdel.transaction_type_name = otnew.cancel_order_type;
--
        IF ((gt_new_transaction_type_id IS NULL)
--        OR  (gt_new_transaction_type_name IS NULL)
        OR  (gt_new_transaction_catg_code IS NULL)
        OR  (gt_del_transaction_type_id IS NULL)
--        OR  (gt_del_transaction_type_name IS NULL)) THEN  -- 取得できなかった場合はエラー
        OR  (gt_del_transaction_catg_code IS NULL)) THEN  -- 取得できなかった場合はエラー
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_type_get_err);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN           -- 受注タイプが存在しない場合はエラー
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_type_get_err);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
--
    WHEN lock_expt THEN       -- ロック取得エラー
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_table_lock_err,
        gv_tkn_table,
        cv_xxwsh_reserve_interface);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_order_all_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : set_del_headers
   * Description      : 倉替返品打消情報(ヘッダ)作成処理 (A-7)
   ***********************************************************************************/
  PROCEDURE set_del_headers(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_del_headers';  -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 倉替返品打消情報作成件数(受注ヘッダアドオン単位)
    gn_output_del_hd_cnt := gn_output_del_hd_cnt + 1;
--
    SELECT xxwsh_order_headers_all_s1.NEXTVAL          -- シーケンス取得
    INTO   gn_seq_hd                                   -- 受注ヘッダアドオンID
    FROM   dual;
--
    gn_idx_hd := gn_idx_hd + 1;  -- 配列インデックス 受注ヘッダアドオン 一括登録用
--
    -- 受注ヘッダアドオンID<--シーケンス
    gt_xoh_order_header_id(gn_idx_hd)         := gn_seq_hd;
    -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
    gt_xoh_order_type_id(gn_idx_hd)           := gt_del_transaction_type_id;
    -- 組織ID
    gt_xoh_organization_id(gn_idx_hd)         := gt_order_all_tbl(1).hd_organization_id;
    -- 最新フラグ<--'N'
    gt_xoh_latest_external_flag(gn_idx_hd)    := gv_flag_off;
    -- 受注日
    gt_xoh_ordered_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_ordered_date;
    -- 顧客ID
    gt_xoh_customer_id(gn_idx_hd)             := gt_order_all_tbl(1).hd_customer_id;
    -- 顧客
    gt_xoh_customer_code(gn_idx_hd)           := gt_order_all_tbl(1).hd_customer_code;
    -- 出荷先ID
    gt_xoh_deliver_to_id(gn_idx_hd)           := gt_order_all_tbl(1).hd_deliver_to_id;
    -- 出荷先
    gt_xoh_deliver_to(gn_idx_hd)              := gt_order_all_tbl(1).hd_deliver_to;
    -- 出荷指示
    gt_xoh_shipping_instructions(gn_idx_hd)   := gt_order_all_tbl(1).hd_shipping_instructions;
    -- 依頼No
    gt_xoh_request_no(gn_idx_hd)              := gt_order_all_tbl(1).hd_request_no;
    -- ステータス
    gt_xoh_req_status(gn_idx_hd)              := gt_order_all_tbl(1).hd_req_status;
    -- 出荷予定日
    gt_xoh_schedule_ship_date(gn_idx_hd)      := gt_order_all_tbl(1).hd_schedule_ship_date;
    -- 着荷予定日
    gt_xoh_schedule_arrival_date(gn_idx_hd)   := gt_order_all_tbl(1).hd_schedule_arrival_date;
    -- 出荷元ID
    gt_xoh_deliver_from_id(gn_idx_hd)         := gt_order_all_tbl(1).hd_deliver_from_id;
    -- 出荷元保管場所
    gt_xoh_deliver_from(gn_idx_hd)            := gt_order_all_tbl(1).hd_deliver_from;
    -- 管轄拠点
    gt_xoh_head_sales_branch(gn_idx_hd)       := gt_order_all_tbl(1).hd_head_sales_branch;
    -- 商品区分
    gt_xoh_prod_class(gn_idx_hd)              := gt_order_all_tbl(1).hd_prod_class;
    -- 合計数量
    gt_xoh_sum_quantity(gn_idx_hd)            := gt_order_all_tbl(1).hd_sum_quantity;
    -- 出荷先_実績ID
    gt_xoh_result_deliver_to_id(gn_idx_hd)    := gt_order_all_tbl(1).hd_result_deliver_to_id;
    -- 出荷先_実績
    gt_xoh_result_deliver_to(gn_idx_hd)       := gt_order_all_tbl(1).hd_result_deliver_to;
    -- 出荷日
    gt_xoh_shipped_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_shipped_date;
    -- 着荷日
    gt_xoh_arrival_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_arrival_date;
    -- 成績管理部署
    gt_xoh_perform_management_dept(gn_idx_hd) := gt_order_all_tbl(1).hd_perform_management_dept;
--
    gt_registered_sequence                    := gt_order_all_tbl(1).hd_registered_sequence + 1;
    -- 登録順序<--A-6で取得した登録順序 + 1
    gt_xoh_registered_sequence(gn_idx_hd)     := gt_registered_sequence;
--
    gt_xoh_created_by(gn_idx_hd)              := gt_user_id;           -- 作成者
    gt_xoh_creation_date(gn_idx_hd)           := gt_sysdate;           -- 作成日
    gt_xoh_last_updated_by(gn_idx_hd)         := gt_user_id;           -- 最終更新者
    gt_xoh_last_update_date(gn_idx_hd)        := gt_sysdate;           -- 最終更新日
    gt_xoh_last_update_login(gn_idx_hd)       := gt_login_id;          -- 最終更新ログイン
    gt_xoh_request_id(gn_idx_hd)              := gt_conc_request_id;   -- 要求ID
    gt_xoh_program_application_id(gn_idx_hd)  := gt_prog_appl_id;      -- アプリケーションID
    gt_xoh_program_id(gn_idx_hd)              := gt_conc_program_id;   -- コンカレント・プログラムID
    gt_xoh_program_update_date(gn_idx_hd)     := gt_sysdate;           -- プログラム更新日
--
    -- A-15において受注ヘッダアドオンの合計数量を再計算して更新するためにここで受注ヘッダアドオンIDを退避する
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_hd; -- 受注ヘッダアドオンID
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_del_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_del_lines
   * Description      : 倉替返品打消情報(明細)作成処理 (A-8)
   ***********************************************************************************/
  PROCEDURE set_del_lines(
    in_idx                IN  NUMBER,              -- 1.配列インデックス
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_del_lines';  -- プログラム名
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
    ln_seq      NUMBER;            --シーケンス（受注明細）
    ln_seq_lot  NUMBER;            --シーケンス（移動ロット詳細）
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
--  ---------- 受注明細 ---------------------------------------------
--
    -- 倉替返品打消情報作成件数(受注明細アドオン単位)
    gn_output_del_ln_cnt := gn_output_del_ln_cnt + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL              -- シーケンス取得
    INTO   ln_seq                                        -- 受注明細アドオンID
    FROM   dual;
--
    -- 配列インデックス 受注明細アドオン 一括登録用
    gn_idx_ln := gn_idx_ln + 1;
--
    -- 受注明細アドオンID<--シーケンス
    gt_xol_order_line_id(gn_idx_ln)       := ln_seq;
    -- 受注ヘッダアドオンID<--A-7で取得したシーケンス
    gt_xol_order_header_id(gn_idx_ln)     := gn_seq_hd;
    -- 明細番号
    gt_xol_order_line_number(gn_idx_ln)   := gt_order_all_tbl(in_idx).ln_order_line_number;
    -- 依頼No
    gt_xol_request_no(gn_idx_ln)          := gt_order_all_tbl(in_idx).ln_request_no;
    -- 出荷品目ID
    gt_xol_shipping_item_id(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_inventory_item_id;
    -- 出荷品目
    gt_xol_shipping_item_code(gn_idx_ln)  := gt_order_all_tbl(in_idx).ln_shipping_item_code;
    -- 数量
    gt_xol_quantity(gn_idx_ln)            := gt_order_all_tbl(in_idx).ln_quantity;
    -- 単位
    gt_xol_uom_code(gn_idx_ln)            := gt_order_all_tbl(in_idx).ln_uom_code;
    -- 出荷実績数量
    gt_xol_shipped_quantity(gn_idx_ln)    := gt_order_all_tbl(in_idx).ln_shipped_quantity;
     -- 拠点依頼数量
    gt_xol_based_request_quantity(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_based_request_quantity;
    -- 依頼品目ID
    gt_xol_request_item_id(gn_idx_ln)   := gt_order_all_tbl(in_idx).ln_request_item_id;
    -- 依頼品目
    gt_xol_request_item_code(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_request_item_code;
    -- 倉替返品インタフェース済フラグ
    gt_xol_rm_if_flg(gn_idx_ln)               := gt_order_all_tbl(in_idx).ln_rm_if_flg;
--
    gt_xol_created_by(gn_idx_ln)              := gt_user_id;          -- 作成者
    gt_xol_creation_date(gn_idx_ln)           := gt_sysdate;          -- 作成日
    gt_xol_last_updated_by(gn_idx_ln)         := gt_user_id;          -- 最終更新者
    gt_xol_last_update_date(gn_idx_ln)        := gt_sysdate;          -- 最終更新日
    gt_xol_last_update_login(gn_idx_ln)       := gt_login_id;         -- 最終更新ログイン
    gt_xol_request_id(gn_idx_ln)              := gt_conc_request_id;  -- 要求ID
    gt_xol_program_application_id(gn_idx_ln)  := gt_prog_appl_id;     -- アプリケーションID
    gt_xol_program_id(gn_idx_ln)              := gt_conc_program_id;  -- コンカレント・プログラムID
    gt_xol_program_update_date(gn_idx_ln)     := gt_sysdate;          -- プログラム更新日
--
--  ---------- 移動ロット詳細 -------------------------------------------------------
--
    -- 倉替返品打消情報作成件数(移動ロット詳細単位)
    gn_output_del_lot_cnt := gn_output_del_lot_cnt + 1;
--
    SELECT xxinv_mov_lot_s1.NEXTVAL              -- シーケンス取得
    INTO   ln_seq_lot                            -- ロット詳細ID
    FROM   dual;
--
    -- 配列インデックス 移動ロット詳細 一括登録用
    gn_idx_lot := gn_idx_lot + 1;
--
    -- ロット詳細ID
    gt_xml_mov_lot_dtl_id(gn_idx_lot)       := ln_seq_lot; -- シーケンスで取得した値
    -- 明細ID
    gt_xml_mov_line_id(gn_idx_lot)          := ln_seq;    -- 受注明細アドオンIDにセットした値
    -- 文書タイプ
    gt_xml_document_type_code(gn_idx_lot)   := gt_order_all_tbl(in_idx).lo_document_type_code;
    -- レコードタイプ
    gt_xml_record_type_code(gn_idx_lot)     := gt_order_all_tbl(in_idx).lo_record_type_code;
    -- OPM品目ID
    gt_xml_item_id(gn_idx_lot)              := gt_order_all_tbl(in_idx).lo_item_id;
    -- 品目
    gt_xml_item_code(gn_idx_lot)            := gt_order_all_tbl(in_idx).lo_item_code;
    -- ロットID
    gt_xml_lot_id(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_id;
    -- ロットNo
    gt_xml_lot_no(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_no;
    -- 実績日
    gt_xml_actual_date(gn_idx_lot)          := gt_order_all_tbl(in_idx).lo_actual_date;
    -- 実績数量
    gt_xml_actual_quantity(gn_idx_lot)      := gt_order_all_tbl(in_idx).lo_actual_quantity;
-- 2009/01/22 Y.Yamamoto #1037 add start
    -- 訂正前実績数量
    gt_xml_bfr_actual_quantity(gn_idx_lot)  := gt_order_all_tbl(in_idx).lo_before_actual_quantity;
-- 2009/01/22 Y.Yamamoto #1037 add end
    -- 自動手動引当区分
    gt_xml_automanual_rsv_class(gn_idx_lot) := gt_order_all_tbl(in_idx).lo_automanual_reserve_class;
--
    gt_xml_created_by(gn_idx_lot)              := gt_user_id;          -- 作成者
    gt_xml_creation_date(gn_idx_lot)           := gt_sysdate;          -- 作成日
    gt_xml_last_updated_by(gn_idx_lot)         := gt_user_id;          -- 最終更新者
    gt_xml_last_update_date(gn_idx_lot)        := gt_sysdate;          -- 最終更新日
    gt_xml_last_update_login(gn_idx_lot)       := gt_login_id;         -- 最終更新ログイン
    gt_xml_request_id(gn_idx_lot)              := gt_conc_request_id;  -- 要求ID
    gt_xml_program_application_id(gn_idx_lot)  := gt_prog_appl_id;     -- アプリケーションID
    gt_xml_program_id(gn_idx_lot)              := gt_conc_program_id;  -- コンカレント・プログラムID
    gt_xml_program_update_date(gn_idx_lot)     := gt_sysdate;          -- プログラム更新日
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
  END set_del_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_headers
   * Description      : 倉替返品情報(ヘッダ)作成処理 (A-9)
   ***********************************************************************************/
  PROCEDURE set_order_headers(
    in_idx                IN  NUMBER,                                         -- 1.配列インデックス
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,          -- 2.数量
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,     -- 3.計上日付(着日)
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 4.相手拠点コード
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 5.入力拠点コード
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_headers';  -- プログラム名
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
    cv_req_status_tightening  CONSTANT VARCHAR2(2) := '03';      -- 締め済み
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
    -- 倉替返品情報作成件数(受注ヘッダアドオン単位)
    gn_output_headers_cnt := gn_output_headers_cnt + 1;
--
    -- 配列インデックス 受注ヘッダアドオン 一括登録用
    gn_idx_hd := gn_idx_hd + 1;
--
    SELECT xxwsh_order_headers_all_s1.NEXTVAL      -- シーケンス取得
    INTO   gn_seq_a9                               -- 受注ヘッダアドオンID
    FROM   dual;
--
    --A-6で同一依頼Noが抽出できなかった場合
    IF (gt_order_all_tbl.COUNT = 0) THEN
      -- 受注ヘッダアドオンID<--シーケンス
      gt_xoh_order_header_id(gn_idx_hd) := gn_seq_a9;
--
      -- A-2で取得した数量>=0(正)の場合
      IF (it_quantity_total >= 0) THEN
        -- 受注タイプID<--A-5で取得した取引(受注)タイプID(返品)
        gt_xoh_order_type_id(gn_idx_hd) := gt_transact_type_id_return;
        -- A-2で取得した数量<0(負)の場合
      ELSE
        -- 受注タイプID<--A-5で取得した取引(受注)タイプID(受注)
        gt_xoh_order_type_id(gn_idx_hd) := gt_transact_type_id_order;
      END IF;
--
      -- 組織ID<--A-1で取得したプロファイル.マスタ組織ID
      gt_xoh_organization_id(gn_idx_hd)         := gv_org_id;
      -- 最新フラグ
      gt_xoh_latest_external_flag(gn_idx_hd)    := gv_flag_on;
      -- 受注日<--A-2で取得した計上日付(着日)
      gt_xoh_ordered_date(gn_idx_hd)            := it_recorded_date;
      -- 顧客ID<--A-3で取得した拠点ID
      gt_xoh_customer_id(gn_idx_hd)             := gt_party_id;
      -- 顧客<--A-2で取得した入力拠点コード
      gt_xoh_customer_code(gn_idx_hd)           := it_input_base_code;
      -- 出荷先ID<--A-3で取得した出荷先ID
      gt_xoh_deliver_to_id(gn_idx_hd)           := gt_party_site_id;
      -- 出荷先<--A-3で取得した出荷先
      gt_xoh_deliver_to(gn_idx_hd)              := gt_party_site_number;
      -- 出荷指示<--NULL
      gt_xoh_shipping_instructions(gn_idx_hd)   := NULL;
      -- 依頼No<--A-5で変換した変換後依頼No
      gt_xoh_request_no(gn_idx_hd)              := gt_request_no;
      -- ステータス<--締め済み
      gt_xoh_req_status(gn_idx_hd)              := cv_req_status_tightening;
      -- 出荷予定日<--A-2で取得した計上日付(着日)
      gt_xoh_schedule_ship_date(gn_idx_hd)      := it_recorded_date;
      -- 着荷予定日<--A-2で取得した計上日付(着日)
      gt_xoh_schedule_arrival_date(gn_idx_hd)   := it_recorded_date;
      -- 出荷元ID<--A-3で取得した出荷元ID(保管倉庫ID)
      gt_xoh_deliver_from_id(gn_idx_hd)         := gt_inventory_location_id;
      -- 出荷元保管場所<--A-2で取得した相手拠点コード
      gt_xoh_deliver_from(gn_idx_hd)            := it_receive_base_code;
      -- 管轄拠点<--A-2で取得した入力拠点コード
      gt_xoh_head_sales_branch(gn_idx_hd)       := it_input_base_code;
      -- 商品区分<--A-3で取得した商品区分
      gt_xoh_prod_class(gn_idx_hd)              := gt_item_class;
      gt_xoh_sum_quantity(gn_idx_hd)            := NULL;   -- 合計数量<--NULL
      gt_xoh_result_deliver_to_id(gn_idx_hd)    := NULL;   -- 出荷先_実績ID<--NULL
      gt_xoh_result_deliver_to(gn_idx_hd)       := NULL;   -- 出荷先_実績<--NULL
      gt_xoh_shipped_date(gn_idx_hd)            := NULL;   -- 出荷日<--NULL
      gt_xoh_arrival_date(gn_idx_hd)            := NULL;   -- 着荷日<--NULL
      gt_xoh_perform_management_dept(gn_idx_hd) := NULL;   -- 成績管理部署<--NULL
      gt_xoh_registered_sequence(gn_idx_hd)     := 1;      -- 登録順序<--1
--
    --A-6で同一依頼Noが抽出できた場合
    ELSE
      -- 受注ヘッダアドオンID<--シーケンス
      gt_xoh_order_header_id(gn_idx_hd) := gn_seq_a9;
--
      -- 合算数量>=0(正)の場合
      IF (gt_sum_quantity >= 0) THEN
        -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
--        IF (gt_new_transaction_type_name = gv_cate_return) THEN
        IF (gt_new_transaction_catg_code = gv_cate_return) THEN
          -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
          gt_xoh_order_type_id(gn_idx_hd) := gt_new_transaction_type_id;
        -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
--        ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
        ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
          -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
          gt_xoh_order_type_id(gn_idx_hd) := gt_del_transaction_type_id;
        END IF;
      -- 合算数量<0(負)の場合
      ELSE
        -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
--        IF (gt_new_transaction_type_name = gv_cate_return) THEN
        IF (gt_new_transaction_catg_code = gv_cate_return) THEN
          -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
          gt_xoh_order_type_id(gn_idx_hd) := gt_del_transaction_type_id;
        -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
--        ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
        ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
          -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
          gt_xoh_order_type_id(gn_idx_hd) := gt_new_transaction_type_id;
        END IF;
      END IF;
--
      -- 組織ID
      gt_xoh_organization_id(gn_idx_hd)       := gt_order_all_tbl(in_idx).hd_organization_id;
      -- 最新フラグ
      gt_xoh_latest_external_flag(gn_idx_hd)  := gv_flag_on;
      -- 受注日
      gt_xoh_ordered_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_ordered_date;
      -- 顧客ID
      gt_xoh_customer_id(gn_idx_hd)           := gt_order_all_tbl(in_idx).hd_customer_id;
      -- 顧客
      gt_xoh_customer_code(gn_idx_hd)         := gt_order_all_tbl(in_idx).hd_customer_code;
      -- 出荷先ID
      gt_xoh_deliver_to_id(gn_idx_hd)         := gt_order_all_tbl(in_idx).hd_deliver_to_id;
      -- 出荷先
      gt_xoh_deliver_to(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_deliver_to;
      -- 出荷指示
      gt_xoh_shipping_instructions(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_shipping_instructions;
      -- 依頼No
      gt_xoh_request_no(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_request_no;
      -- ステータス
      gt_xoh_req_status(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_req_status;
      -- 出荷予定日
      gt_xoh_schedule_ship_date(gn_idx_hd)    := gt_order_all_tbl(in_idx).hd_schedule_ship_date;
      -- 着荷予定日
      gt_xoh_schedule_arrival_date(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_schedule_arrival_date;
      -- 出荷元ID
      gt_xoh_deliver_from_id(gn_idx_hd)       := gt_order_all_tbl(in_idx).hd_deliver_from_id;
      -- 出荷元保管場所
      gt_xoh_deliver_from(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_deliver_from;
      -- 管轄拠点
      gt_xoh_head_sales_branch(gn_idx_hd)     := gt_order_all_tbl(in_idx).hd_head_sales_branch;
      -- 商品区分
      gt_xoh_prod_class(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_prod_class;
      -- 合計数量<--NULL
      gt_xoh_sum_quantity(gn_idx_hd)          := NULL;
      -- 出荷先_実績ID
      gt_xoh_result_deliver_to_id(gn_idx_hd)  := gt_order_all_tbl(in_idx).hd_result_deliver_to_id;
      -- 出荷先_実績
      gt_xoh_result_deliver_to(gn_idx_hd)     := gt_order_all_tbl(in_idx).hd_result_deliver_to;
      -- 出荷日
      gt_xoh_shipped_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_shipped_date;
      -- 着荷日
      gt_xoh_arrival_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_arrival_date;
      -- 成績管理部署
      gt_xoh_perform_management_dept(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_perform_management_dept;
      gt_registered_sequence                    := gt_registered_sequence + 1;
      -- 登録順序<--A-7で作成した登録順序 + 1
      gt_xoh_registered_sequence(gn_idx_hd)     := gt_registered_sequence;
    END IF;
--
    gt_xoh_created_by(gn_idx_hd)             := gt_user_id;         -- 作成者
    gt_xoh_creation_date(gn_idx_hd)          := gt_sysdate;         -- 作成日
    gt_xoh_last_updated_by(gn_idx_hd)        := gt_user_id;         -- 最終更新者
    gt_xoh_last_update_date(gn_idx_hd)       := gt_sysdate;         -- 最終更新日
    gt_xoh_last_update_login(gn_idx_hd)      := gt_login_id;        -- 最終更新ログイン
    gt_xoh_request_id(gn_idx_hd)             := gt_conc_request_id; -- 要求ID
    gt_xoh_program_application_id(gn_idx_hd) := gt_prog_appl_id;    -- アプリケーションID
    gt_xoh_program_id(gn_idx_hd)             := gt_conc_program_id; -- コンカレント・プログラムID
    gt_xoh_program_update_date(gn_idx_hd)    := gt_sysdate;         -- プログラム更新日
--
    -- A-15において受注ヘッダアドオンの合計数量を再計算して更新するためにここで受注ヘッダアドオンIDを退避する
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_a9; -- 受注ヘッダアドオンID
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_order_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_latest_external_flag
   * Description      : 最新フラグ更新情報作成処理 (A-10)
   ***********************************************************************************/
  PROCEDURE set_latest_external_flag(
    in_idx                IN  NUMBER,              -- 1.配列インデックス
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_latest_external_flag';  -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 配列インデックス 受注ヘッダアドオン 最新フラグ 一括更新用
    gn_idx_hd_a10 := gn_idx_hd_a10 + 1;
--
    -- 受注ヘッダアドオンID
    gt_xoh_a10_order_header_id(gn_idx_hd_a10) := gt_order_all_tbl(in_idx).hd_order_header_id;
    gt_xoh_a10_last_updated_by(gn_idx_hd_a10) := gt_user_id;         -- 最終更新者
    gt_xoh_a10_last_update_date(gn_idx_hd_a10)  := gt_sysdate;         -- 最終更新日
    gt_xoh_a10_last_update_login(gn_idx_hd_a10) := gt_login_id;        -- 最終更新ログイン
    gt_xoh_a10_request_id(gn_idx_hd_a10)        := gt_conc_request_id; -- 要求ID
    gt_xoh_a10_program_appli_id(gn_idx_hd_a10)  := gt_prog_appl_id;    -- アプリケーションID
    gt_xoh_a10_program_id(gn_idx_hd_a10)        := gt_conc_program_id; -- プログラムID
    gt_xoh_a10_program_update_date(gn_idx_hd_a10) := gt_sysdate;         -- プログラム更新日
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_latest_external_flag;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_lines
   * Description      : 倉替返品情報(明細)作成処理 (A-11)
   ***********************************************************************************/
  PROCEDURE set_order_lines(
    in_idx                IN  NUMBER,                                     -- 1.配列インデックス
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 2.品目コード
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 3.数量
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_lines';  -- プログラム名
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
    ln_seq         NUMBER;  -- シーケンス（受注明細）
    ln_seq_lot     NUMBER;  -- シーケンス（移動ロット詳細）
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
    ln_max_order_line_number  xxwsh_order_lines_all.order_line_number%TYPE;
    ln_order_line_number      xxwsh_order_lines_all.order_line_number%TYPE;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
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
    -- 倉替返品情報作成件数(受注明細アドオン単位)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- シーケンス取得
    INTO   ln_seq                                   -- 受注明細アドオンID
    FROM   dual;
--
    --A-6で同一依頼Noが抽出できなかった場合
    IF (gt_order_all_tbl.COUNT = 0) THEN
--
      -- 配列インデックス 受注明細アドオン 一括登録用
      gn_idx_ln := gn_idx_ln + 1;
--
      -- 受注明細アドオンID<--シーケンス
      gt_xol_order_line_id(gn_idx_ln)           := ln_seq;
      -- 受注ヘッダアドオンID<--A-9で設定した受注ヘッダアドオンID
      gt_xol_order_header_id(gn_idx_ln)         := gn_seq_a9;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod Start
      -- 受注アドオンに品目が存在した場合は明細番号を使用
      BEGIN
        SELECT MAX(xola.order_line_number)
        INTO   ln_order_line_number
        FROM   xxwsh_order_lines_all  xola
        WHERE  xola.request_no         = gt_request_no
        AND    xola.shipping_item_code = it_item_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_order_line_number := NULL;
      END;
      -- 受注アドオンに品目が存在しなかった場合は最大明細番号+1より採番
      IF ln_order_line_number IS NULL THEN
        IF NVL(gt_line_number_a11,0) = 0 THEN
          BEGIN
            SELECT NVL(MAX(xola.order_line_number),0)
            INTO   ln_max_order_line_number
            FROM   xxwsh_order_lines_all  xola
            WHERE  xola.request_no = gt_request_no
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_max_order_line_number := 0;
          END;
--
          gt_line_number_a11 := ln_max_order_line_number +1;
        ELSE
          gt_line_number_a11 := gt_line_number_a11 +1;
        END IF;
      END IF;
--
      IF ln_order_line_number IS NOT NULL THEN
        gt_xol_order_line_number(gn_idx_ln)       := ln_order_line_number;
      ELSE
        gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
      END IF;
--      -- 明細番号<--ヘッダ単位に1から採番
--      gt_line_number_a11                        := gt_line_number_a11 + 1;
--      gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod End
      -- 依頼No<--A-5で変換した変換後依頼No
      gt_xol_request_no(gn_idx_ln)              := gt_request_no;
      -- 出荷品目ID<--A-3で取得した品目ID
      gt_xol_shipping_item_id(gn_idx_ln)        := gt_item_id;
      -- 出荷品目<--A-2で取得した品目コード
      gt_xol_shipping_item_code(gn_idx_ln)      := it_item_no;
      -- 数量<--A-2で取得した数量の絶対値
      gt_xol_quantity(gn_idx_ln)                := ABS(it_quantity_total);
      -- 単位<--A-3で取得した単位
      gt_xol_uom_code(gn_idx_ln)                := gt_item_um;
      -- 出荷実績数量<--NULL
      gt_xol_shipped_quantity(gn_idx_ln)        := NULL;
      -- 拠点依頼数量<--A-2で取得した数量の絶対値
      gt_xol_based_request_quantity(gn_idx_ln)  := ABS(it_quantity_total);
      -- 依頼品目ID<--A-3で取得した品目ID
      gt_xol_request_item_id(gn_idx_ln)         := gt_item_id;
      -- 依頼品目<--A-2で取得した品目コード
      gt_xol_request_item_code(gn_idx_ln)       := it_item_no;
      -- 倉替返品インタフェース済フラグ<--NULL
      gt_xol_rm_if_flg(gn_idx_ln)               := NULL;
--
      gt_xol_created_by(gn_idx_ln)             := gt_user_id;         -- 作成者
      gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;         -- 作成日
      gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;         -- 最終更新者
      gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;         -- 最終更新日
      gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;        -- 最終更新ログイン
      gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id; -- 要求ID
      gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;    -- アプリケーションID
      gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id; -- コンカレント・プログラムID
      gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;         -- プログラム更新日
--
      --明細数量チェック
-- mod start 2009/01/15 ver1.10 by M.Uehara
--      IF (it_quantity_total >= 0) THEN   -- A-2で取得した数量>=0の場合
--        gb_posi_flg := TRUE;
--      ELSE                               -- A-2で取得した数量<0の場合
--        gb_nega_flg := TRUE;
--      END IF;
      IF (it_quantity_total > 0) THEN   -- A-2で取得した数量>0の場合
        gb_posi_flg := TRUE;
      ELSIF (it_quantity_total < 0) THEN   -- A-2で取得した数量<0の場合
        gb_nega_flg := TRUE;
      END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --***************************************************************************************
    --A-6で同一依頼Noが抽出できた場合
    ELSE
--
      -------------受注明細---------------------------------------------------------------
--
      -- 配列インデックス 受注明細アドオン 一括登録用
      gn_idx_ln := gn_idx_ln + 1;
--
      -- 受注明細アドオンID<--シーケンス
      gt_xol_order_line_id(gn_idx_ln) := ln_seq;
--
      -- 受注ヘッダアドオンID<--A-9で設定した受注ヘッダアドオンID
      gt_xol_order_header_id(gn_idx_ln)        := gn_seq_a9;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod Start
      -- 受注アドオンに品目が存在した場合明細番号を使用
      BEGIN
        SELECT MAX(xola.order_line_number)
        INTO   ln_order_line_number
        FROM   xxwsh_order_lines_all  xola
        WHERE  xola.request_no         = gt_request_no
        AND    xola.shipping_item_code = gt_order_all_tbl(in_idx).ln_shipping_item_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_order_line_number := NULL;
      END;
      -- 受注アドオンに品目が存在しなかった場合最大明細番号+1より採番
      IF ln_order_line_number IS NULL THEN
        IF NVL(gt_line_number_a11,0) = 0 THEN
          BEGIN
            SELECT NVL(MAX(xola.order_line_number),0)
            INTO   ln_max_order_line_number
            FROM   xxwsh_order_lines_all  xola
            WHERE  xola.request_no = gt_request_no
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_max_order_line_number := 0;
          END;
--
          gt_line_number_a11 := ln_max_order_line_number +1;
        ELSE
          gt_line_number_a11 := gt_line_number_a11 +1;
        END IF;
      END IF;
--
      IF ln_order_line_number IS NOT NULL THEN
        gt_xol_order_line_number(gn_idx_ln)       := ln_order_line_number;
      ELSE
        gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
      END IF;
--      -- 明細番号<--ヘッダ単位に1から採番
--      gt_line_number_a11                       := gt_line_number_a11 + 1;
--      gt_xol_order_line_number(gn_idx_ln)      := gt_line_number_a11;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod End
      -- 依頼No<--A-5で変換した変換後依頼No
      gt_xol_request_no(gn_idx_ln)             := gt_request_no;
      -- 出荷品目ID<--A-6で取得した出荷品目ID
      gt_xol_shipping_item_id(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_inventory_item_id;
      -- 出荷品目<--A-6で取得した品目コード
      gt_xol_shipping_item_code(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_item_code;
      -- 数量<--A-18で算出した合算数量の絶対値
      gt_xol_quantity(gn_idx_ln)               := ABS(gt_sum_quantity);
      -- 単位<--A-6で取得した単位
      gt_xol_uom_code(gn_idx_ln)               := gt_order_all_tbl(in_idx).ln_uom_code;
      -- 出荷実績数量<--A-6で取得した出荷実績数量
      gt_xol_shipped_quantity(gn_idx_ln)       := gt_order_all_tbl(in_idx).ln_shipped_quantity;
      -- 拠点依頼数量<--A-18で算出した合算数量の絶対値
      gt_xol_based_request_quantity(gn_idx_ln) := ABS(gt_sum_quantity);
      -- 依頼品目ID<--A-6で取得した依頼品目ID
      gt_xol_request_item_id(gn_idx_ln)        := gt_order_all_tbl(in_idx).ln_request_item_id;
      -- 依頼品目<--A-6で取得した依頼品目
      gt_xol_request_item_code(gn_idx_ln)      := gt_order_all_tbl(in_idx).ln_request_item_code;
      -- 倉替返品インタフェース済フラグ<--NULL
      gt_xol_rm_if_flg(gn_idx_ln)              := NULL;
--
      gt_xol_created_by(gn_idx_ln)             := gt_user_id;          -- 作成者
      gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;          -- 作成日
      gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;          -- 最終更新者
      gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;          -- 最終更新日
      gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;         -- 最終更新ログイン
      gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id;  -- 要求ID
      gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;     -- アプリケーションID
      gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id;  -- コンカレント・プログラムID
      gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;          -- プログラム更新日
--
      --明細数量チェック
-- mod start 2009/01/15 ver1.10 by M.Uehara
--      IF (gt_sum_quantity >= 0) THEN     -- A-18で算出した合算数量>=0の場合
--        gb_posi_flg := TRUE;
--      ELSE                               -- A-18で算出した合算数量<0の場合
--        gb_nega_flg := TRUE;
--      END IF;
      IF (gt_sum_quantity > 0) THEN     -- A-18で算出した合算数量>=の場合
        gb_posi_flg := TRUE;
      ELSIF (gt_sum_quantity < 0) THEN   -- A-18で算出した合算数量<0の場合
        gb_nega_flg := TRUE;
      END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
      -------------移動ロット詳細-------------------------------------------------------
--
    -- 倉替返品情報作成件数(移動ロット詳細単位)
    gn_output_lot_cnt := gn_output_lot_cnt + 1;
--
      SELECT xxinv_mov_lot_s1.NEXTVAL              -- シーケンス取得
      INTO   ln_seq_lot                            -- ロット詳細ID
      FROM   dual;
--
      -- 配列インデックス 移動ロット詳細 一括登録用
      gn_idx_lot := gn_idx_lot + 1;
--
      -- ロット詳細ID
      gt_xml_mov_lot_dtl_id(gn_idx_lot)       := ln_seq_lot; -- シーケンスで取得した値
      -- 明細ID
      gt_xml_mov_line_id(gn_idx_lot)          := ln_seq;    -- 受注明細アドオンIDにセットした値
      -- 文書タイプ
      gt_xml_document_type_code(gn_idx_lot)   := gt_order_all_tbl(in_idx).lo_document_type_code;
      -- レコードタイプ
      gt_xml_record_type_code(gn_idx_lot)     := gt_order_all_tbl(in_idx).lo_record_type_code;
      -- OPM品目ID
      gt_xml_item_id(gn_idx_lot)              := gt_order_all_tbl(in_idx).lo_item_id;
      -- 品目
      gt_xml_item_code(gn_idx_lot)            := gt_order_all_tbl(in_idx).lo_item_code;
      -- ロットID
      gt_xml_lot_id(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_id;
      -- ロットNo
      gt_xml_lot_no(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_no;
      -- 実績日
      gt_xml_actual_date(gn_idx_lot)          := gt_order_all_tbl(in_idx).lo_actual_date;
      -- 実績数量
      gt_xml_actual_quantity(gn_idx_lot)      := gt_order_all_tbl(in_idx).lo_actual_quantity;
-- 2009/01/22 Y.Yamamoto #1037 add start
    -- 訂正前実績数量
      gt_xml_bfr_actual_quantity(gn_idx_lot)  := gt_order_all_tbl(in_idx).ln_shipped_quantity;
-- 2009/01/22 Y.Yamamoto #1037 add end
      -- 自動手動引当区分
      gt_xml_automanual_rsv_class(gn_idx_lot) := gt_order_all_tbl(in_idx).lo_automanual_reserve_class;
--
      gt_xml_created_by(gn_idx_lot)              := gt_user_id;          -- 作成者
      gt_xml_creation_date(gn_idx_lot)           := gt_sysdate;          -- 作成日
      gt_xml_last_updated_by(gn_idx_lot)         := gt_user_id;          -- 最終更新者
      gt_xml_last_update_date(gn_idx_lot)        := gt_sysdate;          -- 最終更新日
      gt_xml_last_update_login(gn_idx_lot)       := gt_login_id;         -- 最終更新ログイン
      gt_xml_request_id(gn_idx_lot)              := gt_conc_request_id;  -- 要求ID
      gt_xml_program_application_id(gn_idx_lot)  := gt_prog_appl_id;     -- アプリケーションID
      gt_xml_program_id(gn_idx_lot)              := gt_conc_program_id;  -- コンカレント・プログラムID
      gt_xml_program_update_date(gn_idx_lot)     := gt_sysdate;          -- プログラム更新日
--
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_order_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_lines_2
   * Description      : 倉替返品情報(明細)作成処理 (A-11-2)
   ***********************************************************************************/
  PROCEDURE set_order_lines_2(
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 1.品目コード
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.数量
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_lines_2';  -- プログラム名
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
    ln_seq          NUMBER;  -- シーケンス（受注明細）
    ln_seq_lot      NUMBER;  -- シーケンス（移動ロット詳細）
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
    ln_max_order_line_number  xxwsh_order_lines_all.order_line_number%TYPE;
    ln_order_line_number      xxwsh_order_lines_all.order_line_number%TYPE;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
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
    -- 倉替返品情報作成件数(受注明細アドオン単位)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    -- 配列インデックス 受注明細アドオン 一括登録用
    gn_idx_ln := gn_idx_ln + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- シーケンス取得
    INTO   ln_seq                                   -- 受注明細アドオンID
    FROM   dual;
--
    -- 受注明細アドオンID<--シーケンス
    gt_xol_order_line_id(gn_idx_ln)           := ln_seq;
    -- 受注ヘッダアドオンID<--A-9で設定した受注ヘッダアドオンID
    gt_xol_order_header_id(gn_idx_ln)         := gn_seq_a9;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod Start
    -- 受注アドオンに品目が存在した場合明細番号を使用
    BEGIN
      SELECT MAX(xola.order_line_number)
      INTO   ln_order_line_number
      FROM   xxwsh_order_lines_all  xola
      WHERE  xola.request_no         = gt_request_no
      AND    xola.shipping_item_code = it_item_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_order_line_number := NULL;
    END;
    -- 受注アドオンに品目が存在しなかった場合最大明細番号+1より採番
    IF ln_order_line_number IS NULL THEN
      IF NVL(gt_line_number_a11,0) = 0 THEN
        BEGIN
          SELECT NVL(MAX(xola.order_line_number),0)
          INTO   ln_max_order_line_number
          FROM   xxwsh_order_lines_all  xola
          WHERE  xola.request_no = gt_request_no
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_max_order_line_number := 0;
        END;
--
        gt_line_number_a11 := ln_max_order_line_number +1;
      ELSE
        gt_line_number_a11 := gt_line_number_a11 +1;
      END IF;
    END IF;
--
    IF ln_order_line_number IS NOT NULL THEN
      gt_xol_order_line_number(gn_idx_ln) := ln_order_line_number;
    ELSE
      gt_xol_order_line_number(gn_idx_ln) := gt_line_number_a11;
    END IF;
--    -- 明細番号<--ヘッダ単位に1から採番
--    gt_line_number_a11                        := gt_line_number_a11 + 1;
--    gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod End
    -- 依頼No<--A-5で変換した変換後依頼No
    gt_xol_request_no(gn_idx_ln)              := gt_request_no;
    -- 出荷品目ID<--A-3で取得した品目ID
    gt_xol_shipping_item_id(gn_idx_ln)        := gt_item_id;
    -- 出荷品目<--A-2で取得した品目コード
    gt_xol_shipping_item_code(gn_idx_ln)      := it_item_no;
    -- 数量<--A-2で取得した数量の絶対値
    gt_xol_quantity(gn_idx_ln)                := ABS(it_quantity_total);
    -- 単位<--A-3で取得した単位
    gt_xol_uom_code(gn_idx_ln)                := gt_item_um;
    -- 出荷実績数量<--NULL
    gt_xol_shipped_quantity(gn_idx_ln)        := NULL;
    -- 拠点依頼数量<--A-2で取得した数量の絶対値
    gt_xol_based_request_quantity(gn_idx_ln)  := ABS(it_quantity_total);
    -- 依頼品目ID<--A-3で取得した品目ID
    gt_xol_request_item_id(gn_idx_ln)         := gt_item_id;
    -- 依頼品目<--A-2で取得した品目コード
    gt_xol_request_item_code(gn_idx_ln)       := it_item_no;
    -- 倉替返品インタフェース済フラグ<--NULL
    gt_xol_rm_if_flg(gn_idx_ln)               := NULL;
--
    gt_xol_created_by(gn_idx_ln)             := gt_user_id;         -- 作成者
    gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;         -- 作成日
    gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;         -- 最終更新者
    gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;         -- 最終更新日
    gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;        -- 最終更新ログイン
    gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id; -- 要求ID
    gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;    -- アプリケーションID
    gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id; -- コンカレント・プログラムID
    gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;         -- プログラム更新日
--
    --明細数量チェック
-- mod start 2009/01/15 ver1.10 by M.Uehara
--    IF (it_quantity_total >= 0) THEN   -- A-2で取得した数量>=0の場合
--      gb_posi_flg := TRUE;
--    ELSE                               -- A-2で取得した数量<0の場合
--      gb_nega_flg := TRUE;
--    END IF;
    IF (it_quantity_total > 0) THEN   -- A-2で取得した数量>0の場合
      gb_posi_flg := TRUE;
    ELSIF (it_quantity_total < 0) THEN  -- A-2で取得した数量<0の場合
      gb_nega_flg := TRUE;
    END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_order_lines_2;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_headers
   * Description      : 倉替返品更新情報(ヘッダ)作成処理 (A-12)
   ***********************************************************************************/
  PROCEDURE set_upd_order_headers(
    in_idx                IN  NUMBER,                                     -- 1.配列インデックス
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.数量
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_headers';  -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 倉替返品更新情報作成件数(受注ヘッダアドオン単位)
    gn_output_upd_hd_cnt := gn_output_upd_hd_cnt + 1;
--
    -- 配列インデックス 受注ヘッダアドオン 一括登録用
    gn_idx_hd_a12 := gn_idx_hd_a12 + 1;
--
    -- 受注ヘッダアドオンID
    gn_seq_a12 := gt_order_all_tbl(in_idx).hd_order_header_id;  -- A-13②で使用するためワークに退避
    gt_xoh_a12_order_header_id(gn_idx_hd_a12) := gn_seq_a12;
--
    -- 合算数量>=0(正)の場合
    IF (gt_sum_quantity >= 0) THEN
      -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
--      IF (gt_new_transaction_type_name = gv_cate_return) THEN
      IF (gt_new_transaction_catg_code = gv_cate_return) THEN
        -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_new_transaction_type_id;
      -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
--      ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
      ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
        -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_del_transaction_type_id;
      END IF;
    ELSE      -- 合算数量<0(負)の場合
      -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
--      IF (gt_new_transaction_type_name = gv_cate_return) THEN
      IF (gt_new_transaction_catg_code = gv_cate_return) THEN
        -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_del_transaction_type_id;
      -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
--      ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
      ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
        -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_new_transaction_type_id;
      END IF;
    END IF;
--
    gt_xoh_a12_last_updated_by(gn_idx_hd_a12)     := gt_user_id;         -- 最終更新者
    gt_xoh_a12_last_update_date(gn_idx_hd_a12)    := gt_sysdate;         -- 最終更新日
    gt_xoh_a12_last_update_login(gn_idx_hd_a12)   := gt_user_id;         -- 最終更新ログイン
    gt_xoh_a12_request_id(gn_idx_hd_a12)          := gt_conc_request_id; -- 要求ID
    gt_xoh_a12_program_appli_id(gn_idx_hd_a12)    := gt_prog_appl_id;    -- アプリケーションID
    gt_xoh_a12_program_id(gn_idx_hd_a12)          := gt_conc_program_id; -- コンカレント・プログラムID
    gt_xoh_a12_program_update_date(gn_idx_hd_a12) := gt_sysdate;         -- プログラム更新日
--
    -- A-15において受注ヘッダアドオンの合計数量を再計算して更新するためにここで受注ヘッダアドオンIDを退避する
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_a12; -- 受注ヘッダアドオンID
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_upd_order_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_lines_upd
   * Description      : 倉替返品更新情報(明細)作成処理 (A-13①)  同一品目の明細更新
   ***********************************************************************************/
  PROCEDURE set_upd_order_lines_upd(
    in_idx                IN  NUMBER,                                     -- 1.配列インデックス
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.数量
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_lines_upd';  -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 倉替返品更新情報作成件数(受注明細アドオン単位)
    gn_output_upd_ln_cnt := gn_output_upd_ln_cnt + 1;
--
    -- 配列インデックス 受注明細アドオン 数量・拠点依頼数量 一括更新用
    gn_idx_ln_a13 := gn_idx_ln_a13 + 1;
--
    -- 受注ヘッダアドオンID<--A-12で退避した受注ヘッダアドオンID
    gt_xol_a13_order_header_id(gn_idx_ln_a13)     := gn_seq_a12;
    -- 受注明細アドオンID<--A-6で取得した受注明細アドオンID
    gt_xol_a13_order_line_id(gn_idx_ln_a13)       := gt_order_all_tbl(in_idx).ln_order_line_id;
    -- 数量<--A-18で算出した合算数量の絶対値
    gt_xol_a13_quantity(gn_idx_ln_a13)            := ABS(gt_sum_quantity);
    -- 拠点依頼数量<--A-18で算出した合算数量の絶対値
    gt_xol_a13_based_req_quant(gn_idx_ln_a13)     := ABS(gt_sum_quantity);
    gt_xol_a13_last_updated_by(gn_idx_ln_a13)     := gt_user_id;         -- 最終更新者
    gt_xol_a13_last_update_date(gn_idx_ln_a13)    := gt_sysdate;         -- 最終更新日
    gt_xol_a13_last_update_login(gn_idx_ln_a13)   := gt_login_id;        -- 最終更新ログイン
    gt_xol_a13_request_id(gn_idx_ln_a13)          := gt_conc_request_id; -- 要求ID
    gt_xol_a13_program_appli_id(gn_idx_ln_a13)    := gt_prog_appl_id;    -- アプリケーションID
    gt_xol_a13_program_id(gn_idx_ln_a13)          := gt_conc_program_id; -- コンカレント・プログラムID
    gt_xol_a13_program_update_date(gn_idx_ln_a13) := gt_sysdate;         -- プログラム更新日
--
    --明細数量チェック
-- mod start 2009/01/15 ver1.10 by M.Uehara
--    IF (gt_sum_quantity >= 0) THEN  -- A-18で算出した合算数量>=0の場合
--      gb_posi_flg := TRUE;
--    ELSE                            -- A-18で算出した合算数量<0の場合
--      gb_nega_flg := TRUE;
--    END IF;
    IF (gt_sum_quantity > 0) THEN  -- A-18で算出した合算数量>0の場合
      gb_posi_flg := TRUE;
    ELSIF (gt_sum_quantity < 0) THEN -- A-18で算出した合算数量<0の場合
      gb_nega_flg := TRUE;
    END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_upd_order_lines_upd;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_lines_ins
   * Description      : 倉替返品更新情報(明細)作成処理 (A-13②) 同一品目がないので明細の新規作成
   ***********************************************************************************/
  PROCEDURE set_upd_order_lines_ins(
    in_idx                IN  NUMBER,                                     -- 1.配列インデックス
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.数量
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 3.品目コード
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_lines_ins';  -- プログラム名
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
    ln_seq           NUMBER;     -- シーケンス（受注明細）
    ln_seq_lot       NUMBER;     -- シーケンス（移動ロット詳細）
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
    ln_max_order_line_number  xxwsh_order_lines_all.order_line_number%TYPE;
    ln_order_line_number      xxwsh_order_lines_all.order_line_number%TYPE;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
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
    -- 倉替返品情報作成件数(受注明細アドオン単位)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    -- 配列インデックス 受注明細アドオン 一括登録用
    gn_idx_ln := gn_idx_ln + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- シーケンス取得
    INTO   ln_seq                                   -- 受注明細アドオンID
    FROM   dual;
--
    -- 受注明細アドオンID<--シーケンス
    gt_xol_order_line_id(gn_idx_ln)       := ln_seq;
    -- 受注ヘッダアドオンID<--A-12で退避した受注ヘッダアドオンID
    gt_xol_order_header_id(gn_idx_ln)     := gn_seq_a12;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod Start
    -- 受注アドオンに品目が存在した場合明細番号を使用
    BEGIN
      SELECT MAX(xola.order_line_number)
      INTO   ln_order_line_number
      FROM   xxwsh_order_lines_all  xola
      WHERE  xola.request_no         = gt_request_no
      AND    xola.shipping_item_code = it_item_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_order_line_number := NULL;
    END;
    -- 受注アドオンに品目が存在しなかった場合最大明細番号+1より採番
    IF ln_order_line_number IS NULL THEN
      IF NVL(gt_line_number_a11,0) = 0 THEN
        BEGIN
          SELECT NVL(MAX(xola.order_line_number),0)
          INTO   ln_max_order_line_number
          FROM   xxwsh_order_lines_all  xola
          WHERE  xola.request_no = gt_request_no
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_max_order_line_number := 0;
        END;
--
        gt_line_number_a11 := ln_max_order_line_number +1;
      ELSE
        gt_line_number_a11 := gt_line_number_a11 +1;
      END IF;
    END IF;
--
    IF ln_order_line_number IS NOT NULL THEN
      gt_xol_order_line_number(gn_idx_ln) := ln_order_line_number;
    ELSE
      gt_xol_order_line_number(gn_idx_ln) := gt_line_number_a11;
    END IF;
--    -- 明細番号<--ヘッダ単位に1から採番
--    gt_line_number_a11 := gt_line_number_a11 + 1;
--    gt_xol_order_line_number(gn_idx_ln) := gt_line_number_a11;
-- ver1.13 Y.Kazama 本番障害#1335対応 Mod End
    -- 依頼No<--A-5で変換した変換後依頼No
    gt_xol_request_no(gn_idx_ln)          := gt_request_no;
    -- 出荷品目ID<--A-3で取得した出荷品目ID
    gt_xol_shipping_item_id(gn_idx_ln)    := gt_item_id;
    -- 出荷品目<--A-2で取得した品目コード
    gt_xol_shipping_item_code(gn_idx_ln)  := it_item_no;
    -- 数量<--A-12で取得した数量の絶対値
    gt_xol_quantity(gn_idx_ln)            := ABS(it_quantity_total);
    -- 単位<--A-3で取得した単位
    gt_xol_uom_code(gn_idx_ln)            := gt_item_um;
    -- 出荷実績数量<--NULL
    gt_xol_shipped_quantity(gn_idx_ln)    := NULL;
    -- 拠点依頼数量<--A-2で取得した数量の絶対値
    gt_xol_based_request_quantity(gn_idx_ln) := ABS(it_quantity_total);
    -- 依頼品目ID<--A-3で取得した依頼品目ID
    gt_xol_request_item_id(gn_idx_ln)     := gt_item_id;
    -- 依頼品目<--A-2で取得した依頼品目
    gt_xol_request_item_code(gn_idx_ln)   := it_item_no;
    -- 倉替返品インタフェース済フラグ<--NULL
    gt_xol_rm_if_flg(gn_idx_ln)           := NULL;
    gt_xol_created_by(gn_idx_ln)          := gt_user_id;           -- 作成者
    gt_xol_creation_date(gn_idx_ln)       := gt_sysdate;           -- 作成日
    gt_xol_last_updated_by(gn_idx_ln)     := gt_user_id;           -- 最終更新者
    gt_xol_last_update_date(gn_idx_ln)    := gt_sysdate;           -- 最終更新日
    gt_xol_last_update_login(gn_idx_ln)   := gt_login_id;          -- 最終更新ログイン
    gt_xol_request_id(gn_idx_ln)          := gt_conc_request_id;   -- 要求ID
    gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;   -- アプリケーションID
    gt_xol_program_id(gn_idx_ln)          := gt_conc_program_id;   -- コンカレント・プログラムID
    gt_xol_program_update_date(gn_idx_ln) := gt_sysdate;           -- プログラム更新日
--
    --明細数量チェック
    IF (it_quantity_total >= 0) THEN   -- A-2で取得した数量>=0の場合
      gb_posi_flg := TRUE;
    ELSE                               -- A-2で取得した数量<0の場合
      gb_nega_flg := TRUE;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END set_upd_order_lines_ins;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_order
   * Description      : 倉替返品情報登録処理 (A-14)
   ***********************************************************************************/
  PROCEDURE ins_order(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'ins_order';  -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- **************************************************
    -- *** 受注ヘッダアドオン 一括登録
    -- **************************************************
    <<ins_headers_loop>>
    FORALL i IN 1 .. gt_xoh_order_header_id.COUNT
      INSERT INTO xxwsh_order_headers_all              -- 受注ヘッダアドオン
        (order_header_id                               -- 受注ヘッダアドオンID
        ,order_type_id                                 -- 受注タイプID
        ,organization_id                               -- 組織ID
        ,latest_external_flag                          -- 最新フラグ
        ,ordered_date                                  -- 受注日
        ,customer_id                                   -- 顧客ID
        ,customer_code                                 -- 顧客
        ,deliver_to_id                                 -- 出荷先ID
        ,deliver_to                                    -- 出荷先
        ,shipping_instructions                         -- 出荷指示
        ,request_no                                    -- 依頼No
        ,req_status                                    -- ステータス
        ,schedule_ship_date                            -- 出荷予定日
        ,schedule_arrival_date                         -- 着荷予定日
        ,deliver_from_id                               -- 出荷元ID
        ,deliver_from                                  -- 出荷元保管場所
        ,head_sales_branch                             -- 管轄拠点
        ,prod_class                                    -- 商品区分
        ,sum_quantity                                  -- 合計数量
        ,result_deliver_to_id                          -- 出荷先_実績ID
        ,result_deliver_to                             -- 出荷先_実績
        ,shipped_date                                  -- 出荷日
        ,arrival_date                                  -- 着荷日
-- 2009/01/13 H.Itou Add Start 本番障害#981対応
        ,actual_confirm_class                          -- 実績計上済区分
-- 2009/01/13 H.Itou Add End
        ,performance_management_dept                   -- 成績管理部署
        ,registered_sequence                           -- 登録順序
        ,created_by                                    -- 作成者
        ,creation_date                                 -- 作成日
        ,last_updated_by                               -- 最終更新者
        ,last_update_date                              -- 最終更新日
        ,last_update_login                             -- 最終更新ログイン
        ,request_id                                    -- 要求ID
        ,program_application_id                        -- アプリケーションID
        ,program_id                                    -- コンカレント・プログラムID
        ,program_update_date                           -- プログラム更新日
        )
      VALUES
        (gt_xoh_order_header_id(i)                     -- 受注ヘッダアドオンID
        ,gt_xoh_order_type_id(i)                       -- 受注タイプID
        ,gt_xoh_organization_id(i)                     -- 組織ID
        ,gt_xoh_latest_external_flag(i)                -- 最新フラグ
        ,gt_xoh_ordered_date(i)                        -- 受注日
        ,gt_xoh_customer_id(i)                         -- 顧客ID
        ,gt_xoh_customer_code(i)                       -- 顧客
        ,gt_xoh_deliver_to_id(i)                       -- 出荷先ID
        ,gt_xoh_deliver_to(i)                          -- 出荷先
        ,gt_xoh_shipping_instructions(i)               -- 出荷指示
        ,gt_xoh_request_no(i)                          -- 依頼No
        ,gt_xoh_req_status(i)                          -- ステータス
        ,gt_xoh_schedule_ship_date(i)                  -- 出荷予定日
        ,gt_xoh_schedule_arrival_date(i)               -- 着荷予定日
        ,gt_xoh_deliver_from_id(i)                     -- 出荷元ID
        ,gt_xoh_deliver_from(i)                        -- 出荷元保管場所
        ,gt_xoh_head_sales_branch(i)                   -- 管轄拠点
        ,gt_xoh_prod_class(i)                          -- 商品区分
        ,gt_xoh_sum_quantity(i)                        -- 合計数量
        ,gt_xoh_result_deliver_to_id(i)                -- 出荷先_実績ID
        ,gt_xoh_result_deliver_to(i)                   -- 出荷先_実績
        ,gt_xoh_shipped_date(i)                        -- 出荷日
        ,gt_xoh_arrival_date(i)                        -- 着荷日
-- 2009/01/13 H.Itou Add Start 本番障害#981対応
        ,gv_flag_off                                   -- 実績計上済区分
-- 2009/01/13 H.Itou Add End
        ,gt_xoh_perform_management_dept(i)             -- 成績管理部署
        ,gt_xoh_registered_sequence(i)                 -- 登録順序
        ,gt_xoh_created_by(i)                          -- 作成者
        ,gt_xoh_creation_date(i)                       -- 作成日
        ,gt_xoh_last_updated_by(i)                     -- 最終更新者
        ,gt_xoh_last_update_date(i)                    -- 最終更新日
        ,gt_xoh_last_update_login(i)                   -- 最終更新ログイン
        ,gt_xoh_request_id(i)                          -- 要求ID
        ,gt_xoh_program_application_id(i)              -- アプリケーションID
        ,gt_xoh_program_id(i)                          -- コンカレント・プログラムID
        ,gt_xoh_program_update_date(i)                 -- プログラム更新日
      );
--
    -- **************************************************
    -- *** 受注明細アドオン 一括登録
    -- **************************************************
    <<ins_lines_loop>>
    FORALL i IN 1 .. gt_xol_order_line_id.COUNT
      INSERT INTO xxwsh_order_lines_all                 -- 受注明細アドオン
        (order_line_id                                  -- 受注明細アドオンID
        ,order_header_id                                -- 受注ヘッダアドオンID
        ,order_line_number                              -- 明細番号
        ,request_no                                     -- 依頼No
        ,shipping_inventory_item_id                     -- 出荷品目ID
        ,shipping_item_code                             -- 出荷品目
        ,quantity                                       -- 数量
        ,uom_code                                       -- 単位
        ,shipped_quantity                               -- 出荷実績数量
        ,based_request_quantity                         -- 拠点依頼数量
        ,request_item_id                                -- 依頼品目ID
        ,request_item_code                              -- 依頼品目
        ,delete_flag                                    -- 削除フラグ
        ,rm_if_flg                                      -- 倉替返品インタフェース済フラグ
        ,created_by                                     -- 作成者
        ,creation_date                                  -- 作成日
        ,last_updated_by                                -- 最終更新者
        ,last_update_date                               -- 最終更新日
        ,last_update_login                              -- 最終更新ログイン
        ,request_id                                     -- 要求ID
        ,program_application_id                         -- アプリケーションID
        ,program_id                                     -- コンカレント・プログラムID
        ,program_update_date                            -- プログラム更新日
        )
      VALUES
        (gt_xol_order_line_id(i)                        -- 受注明細アドオンID
        ,gt_xol_order_header_id(i)                      -- 受注ヘッダアドオンID
        ,gt_xol_order_line_number(i)                    -- 明細番号
        ,gt_xol_request_no(i)                           -- 依頼No
        ,gt_xol_shipping_item_id(i)                     -- 出荷品目ID
        ,gt_xol_shipping_item_code(i)                   -- 出荷品目
        ,gt_xol_quantity(i)                             -- 数量
        ,gt_xol_uom_code(i)                             -- 単位
        ,gt_xol_shipped_quantity(i)                     -- 出荷実績数量
        ,gt_xol_based_request_quantity(i)               -- 拠点依頼数量
        ,gt_xol_request_item_id(i)                      -- 依頼品目ID
        ,gt_xol_request_item_code(i)                    -- 依頼品目
        ,gv_flag_off                                    -- 削除フラグ
        ,gv_flag_off                                    -- 倉替返品インタフェース済フラグ
        --,gt_xol_rm_if_flg(i)                            -- 倉替返品インタフェース済フラグ
        ,gt_xol_created_by(i)                           -- 作成者
        ,gt_xol_creation_date(i)                        -- 作成日
        ,gt_xol_last_updated_by(i)                      -- 最終更新者
        ,gt_xol_last_update_date(i)                     -- 最終更新日
        ,gt_xol_last_update_login(i)                    -- 最終更新ログイン
        ,gt_xol_request_id(i)                           -- 要求ID
        ,gt_xol_program_application_id(i)               -- アプリケーションID
        ,gt_xol_program_id(i)                           -- コンカレント・プログラムID
        ,gt_xol_program_update_date(i)                  -- プログラム更新日
       );
--
    -- **************************************************
    -- *** 移動ロット詳細 一括登録
    -- **************************************************
    <<ins_lot_loop>>
    FORALL i IN 1 .. gt_xml_mov_lot_dtl_id.COUNT
      INSERT INTO xxinv_mov_lot_details                 -- 移動ロット詳細
        (mov_lot_dtl_id                                 -- ロット詳細ID
        ,mov_line_id                                    -- 明細ID
        ,document_type_code                             -- 文書タイプ
        ,record_type_code                               -- レコードタイプ
        ,item_id                                        -- OPM品目ID
        ,item_code                                      -- 品目
        ,lot_id                                         -- ロットID
        ,lot_no                                         -- ロットNo
        ,actual_date                                    -- 実績日
        ,actual_quantity                                -- 実績数量
-- 2009/01/22 Y.Yamamoto #1037 add start
        ,before_actual_quantity                         -- 訂正前実績数量
-- 2009/01/22 Y.Yamamoto #1037 add end
        ,automanual_reserve_class                       -- 自動手動引当区分
        ,created_by                                     -- 作成者
        ,creation_date                                  -- 作成日
        ,last_updated_by                                -- 最終更新者
        ,last_update_date                               -- 最終更新日
        ,last_update_login                              -- 最終更新ログイン
        ,request_id                                     -- 要求ID
        ,program_application_id                         -- アプリケーションID
        ,program_id                                     -- コンカレント・プログラムID
        ,program_update_date                            -- プログラム更新日
        )
      VALUES
        (gt_xml_mov_lot_dtl_id(i)                       -- ロット詳細ID
        ,gt_xml_mov_line_id(i)                          -- 明細ID
        ,gt_xml_document_type_code(i)                   -- 文書タイプ
        ,gt_xml_record_type_code(i)                     -- レコードタイプ
        ,gt_xml_item_id(i)                              -- OPM品目ID
        ,gt_xml_item_code(i)                            -- 品目
        ,gt_xml_lot_id(i)                               -- ロットID
        ,gt_xml_lot_no(i)                               -- ロットNo
        ,gt_xml_actual_date(i)                          -- 実績日
        ,gt_xml_actual_quantity(i)                      -- 実績数量
-- 2009/01/22 Y.Yamamoto #1037 add start
        ,gt_xml_bfr_actual_quantity(i)                  -- 訂正前実績数量
-- 2009/01/22 Y.Yamamoto #1037 add end
        ,gt_xml_automanual_rsv_class(i)                 -- 自動手動引当区分
        ,gt_xml_created_by(i)                           -- 作成者
        ,gt_xml_creation_date(i)                        -- 作成日
        ,gt_xml_last_updated_by(i)                      -- 最終更新者
        ,gt_xml_last_update_date(i)                     -- 最終更新日
        ,gt_xml_last_update_login(i)                    -- 最終更新ログイン
        ,gt_xml_request_id(i)                           -- 要求ID
        ,gt_xml_program_application_id(i)               -- アプリケーションID
        ,gt_xml_program_id(i)                           -- コンカレント・プログラムID
        ,gt_xml_program_update_date(i)                  -- プログラム更新日
       );
--
    -- **************************************************
    -- *** 受注ヘッダアドオン 最新フラグ 一括更新
    -- **************************************************
    <<upd_headers_a10_loop>>
    FORALL i IN 1 .. gt_xoh_a10_order_header_id.COUNT
      UPDATE
        xxwsh_order_headers_all  xoh                                   -- 受注ヘッダアドオン
      SET
        xoh.latest_external_flag   = gv_flag_off                       -- 最新フラグ<--'N'
       ,xoh.last_updated_by        = gt_xoh_a10_last_updated_by(i)     -- 最終更新者
       ,xoh.last_update_date       = gt_xoh_a10_last_update_date(i)    -- 最終更新日
       ,xoh.last_update_login      = gt_xoh_a10_last_update_login(i)   -- 最終更新ログイン
       ,xoh.request_id             = gt_xoh_a10_request_id(i)          -- 要求ID
       ,xoh.program_application_id = gt_xoh_a10_program_appli_id(i)    -- アプリケーションID
       ,xoh.program_id             = gt_xoh_a10_program_id(i)          -- コンカレント・プログラムID
       ,xoh.program_update_date    = gt_xoh_a10_program_update_date(i) -- プログラム更新日
      WHERE
        xoh.order_header_id = gt_xoh_a10_order_header_id(i);           -- 受注ヘッダアドオンID
--
    -- *********************************************************
    -- *** 受注ヘッダアドオン 受注タイプ・登録順序 一括更新
    -- *********************************************************
    <<upd_headers_a12_loop>>
    FORALL i IN 1 .. gt_xoh_a12_order_header_id.COUNT
      UPDATE
          xxwsh_order_headers_all  xoh    -- 受注ヘッダアドオン
      SET
         xoh.order_type_id          = gt_xoh_a12_order_type_id(i)       -- 受注タイプID
        ,xoh.last_updated_by        = gt_xoh_a12_last_updated_by(i)     -- 最終更新者
        ,xoh.last_update_date       = gt_xoh_a12_last_update_date(i)    -- 最終更新日
        ,xoh.last_update_login      = gt_xoh_a12_last_update_login(i)   -- 最終更新ログイン
        ,xoh.request_id             = gt_xoh_a12_request_id(i)          -- 要求ID
        ,xoh.program_application_id = gt_xoh_a12_program_appli_id(i)    -- アプリケーションID
        ,xoh.program_id             = gt_xoh_a12_program_id(i)          -- コンカレント・プログラムID
        ,xoh.program_update_date    = gt_xoh_a12_program_update_date(i) -- プログラム更新日
      WHERE
        xoh.order_header_id = gt_xoh_a12_order_header_id(i);            -- 受注ヘッダアドオンID
--
    -- *********************************************************
    -- *** 受注明細アドオン 数量・拠点依頼数量 一括更新
    -- *********************************************************
    <<upd_lines_a13_loop>>
    FORALL i IN 1 .. gt_xol_a13_order_line_id.COUNT
      UPDATE
        xxwsh_order_lines_all  xol     -- 受注明細アドオン
      SET
         xol.quantity               = gt_xol_a13_quantity(i)             -- 数量
        ,xol.based_request_quantity = gt_xol_a13_based_req_quant(i)      -- 拠点依頼数量
        ,xol.last_updated_by        = gt_xol_a13_last_updated_by(i)      -- 最終更新者
        ,xol.last_update_date       = gt_xol_a13_last_update_date(i)     -- 最終更新日
        ,xol.last_update_login      = gt_xol_a13_last_update_login(i)    -- 最終更新ログイン
        ,xol.request_id             = gt_xol_a13_request_id(i)           -- 要求ID
        ,xol.program_application_id = gt_xol_a13_program_appli_id(i)     -- アプリケーションID
        ,xol.program_id             = gt_xol_a13_program_id(i)           -- コンカレント・プログラムID
        ,xol.program_update_date    = gt_xol_a13_program_update_date(i)  -- プログラム更新日
      WHERE
            xol.order_header_id = gt_xol_a13_order_header_id(i)          -- 受注ヘッダアドオンID
        AND xol.order_line_id   = gt_xol_a13_order_line_id(i);           -- 受注明細アドオンID
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_order;
--
--
  /**********************************************************************************
   * Procedure Name   : sum_lines_quantity
   * Description      : 倉替返品抽出・合計処理 (A-15)
   ***********************************************************************************/
  PROCEDURE sum_lines_quantity(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'sum_lines_quantity';  -- プログラム名
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
    lt_sum_quantity  xxwsh_order_headers_all.sum_quantity%TYPE; -- 受注ヘッダアドオン.合計数量
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
    -- **************************************************
    -- *** 受注ヘッダアドオンの合計数量を求める
    -- **************************************************
    <<sum_quantity_loop>>
    FOR i IN 1 .. gt_xoh_a7_13_order_header_id.COUNT
    LOOP
      SELECT SUM(xol.quantity) AS quantity  -- 受注明細アドオンの数量を合計
      INTO   lt_sum_quantity
      FROM   xxwsh_order_headers_all  xoh,                          -- 受注ヘッダアドオン
             xxwsh_order_lines_all    xol                           -- 受注明細アドオン
      WHERE  xoh.order_header_id = gt_xoh_a7_13_order_header_id(i)  -- 受注ヘッダアドオンID
        AND  xoh.order_header_id = xol.order_header_id;              -- 受注ヘッダID
--
      gt_xoh_a15_order_header_id(i) := gt_xoh_a7_13_order_header_id(i); -- 受注ヘッダアドオンID
      gt_xoh_a15_sum_quantity(i)        := lt_sum_quantity;    -- 合計数量
      gt_xoh_a15_last_updated_by(i)     := gt_user_id;         -- 最終更新者
      gt_xoh_a15_last_update_date(i)    := gt_sysdate;         -- 最終更新日
      gt_xoh_a15_last_update_login(i)   := gt_login_id;        -- 最終更新ログイン
      gt_xoh_a15_request_id(i)          := gt_conc_request_id; -- 要求ID
      gt_xoh_a15_program_appli_id(i)    := gt_prog_appl_id;    -- アプリケーションID
      gt_xoh_a15_program_id(i)          := gt_conc_program_id; -- コンカレント・プログラムID
      gt_xoh_a15_program_update_date(i) := gt_sysdate;         -- プログラム更新日
--
    END LOOP sum_quantity_loop;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END sum_lines_quantity;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_headers_sum_quantity
   * Description      : 倉替返品情報再登録処理 (A-16)
   ***********************************************************************************/
  PROCEDURE upd_headers_sum_quantity(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'upd_headers_sum_quantity'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- **************************************************
    -- *** 受注ヘッダアドオン 合計数量 一括更新
    -- **************************************************
    <<upd_headers_loop>>
    FORALL i IN 1 .. gt_xoh_a15_order_header_id.COUNT
      UPDATE
        xxwsh_order_headers_all  xoh                                   -- 受注ヘッダアドオン
      SET
        xoh.sum_quantity           = gt_xoh_a15_sum_quantity(i),       -- 合計数量
        xoh.last_updated_by        = gt_xoh_a15_last_updated_by(i),    -- 最終更新者
        xoh.last_update_date       = gt_xoh_a15_last_update_date(i),   -- 最終更新日
        xoh.last_update_login      = gt_xoh_a15_last_update_login(i),  -- 最終更新ログイン
        xoh.request_id             = gt_xoh_a15_request_id(i),         -- 要求ID
        xoh.program_application_id = gt_xoh_a15_program_appli_id(i),   -- アプリケーションID
        xoh.program_id             = gt_xoh_a15_program_id(i),         -- コンカレント・プログラムID
        xoh.program_update_date    = gt_xoh_a15_program_update_date(i) -- プログラム更新日
      WHERE
        xoh.order_header_id = gt_xoh_a15_order_header_id(i);           -- 受注ヘッダアドオンID
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END upd_headers_sum_quantity;
--
--
  /**********************************************************************************
   * Procedure Name   : del_reserve_interface
   * Description      : 倉替返品インターフェース情報削除処理 (A-17)
   ***********************************************************************************/
  PROCEDURE del_reserve_interface(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'del_reserve_interface';  -- プログラム名
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
    lb_rtn_cd      BOOLEAN;         -- 共通関数のリターンコード
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
    -- **************************************************
    -- *** 倉替返品インターフェース情報削除
    -- **************************************************
    lb_rtn_cd := xxcmn_common_pkg.del_all_data(gv_xxwsh, gv_reserve_interface);
--
    IF (NOT lb_rtn_cd) THEN          -- 共通関数のリターンコードがエラーの場合
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_truncate_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力（エラー以外）をする必要がある場合は処理を記述
    --==============================================================
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
  END del_reserve_interface;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_req_status_confirm  CONSTANT VARCHAR2(2) := '04';    -- 出荷実績計上済
--
    -- *** ローカル変数 ***
    lv_cntmsg              VARCHAR2(5000);     -- 件数出力用メッセージ
--
    lt_req_statu           xxwsh_order_headers_all.req_status%TYPE;   -- ステータス
--
    lt_invoice_no_a2       xxwsh_reserve_interface.invoice_no%TYPE;   -- 前回A-2伝票No
    lt_invoice_no_a6       xxwsh_order_headers_all.request_no%TYPE;   -- 前回A-6伝票No
--
    ln_idx_a6              NUMBER;
--
    lb_break_flg_a2        BOOLEAN;       -- A-2伝票Noがブレイクした場合はTRUE
    lb_break_flg_a6        BOOLEAN;       -- A-6伝票Noがブレイクした場合はTRUE
--
    lb_a13upd_flg          BOOLEAN;       -- A-13①で明細をUPDATEした場合(同一品目があった場合)はTRUE
--
--2008/08/07 Add ↓
    lt_actual_class        xxwsh_order_headers_all.actual_confirm_class%TYPE;
--2008/08/07 Add ↑
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
-- 2009/09/29 H.Itou Del Start 本番障害#1465 IF品目に関係なくデータを作成する必要があるのでコメントアウト
--    lt_bk_reserve_if_item_code      xxwsh_reserve_interface.item_code%TYPE;        -- 退避品目コード
-- 2009/09/29 H.Itou Del End
    lt_bk_order_type_id             xxwsh_order_headers_all.order_type_id%TYPE;    -- 受注タイプID
    lt_bk_confirm_item_code         xxwsh_order_lines_all.shipping_item_code%TYPE; -- 実績計上済データ投入品目コード
    ln_cnt_line_item_no             NUMBER;
    ln_line_cnt                     NUMBER;
--
    -- 倉替返品IFに存在しない,受注アドオンに存在するデータを抽出
    CURSOR cur_get_order_minus_reserve(
      pi_request_no  IN  xxwsh_order_headers_all.request_no%TYPE
     ,pi_invoice_no  IN  xxwsh_reserve_interface.invoice_no%TYPE
    )
    IS
      SELECT xola.shipping_item_code          -- 出荷品目
            ,CASE
               WHEN xott.order_category_code = gv_cate_return THEN  -- 受注カテゴリ=返品の場合
                 xola.quantity
               WHEN xott.order_category_code = gv_cate_order  THEN  -- 受注カテゴリ=受注の場合
                 xola.quantity * -1
               ELSE
                 0
             END AS quantity                  -- 加算用数量
      FROM   xxwsh_order_headers_all       xoha
            ,xxwsh_order_lines_all         xola
            ,xxwsh_oe_transaction_types_v  xott
      WHERE  xoha.order_header_id      = xola.order_header_id
      AND    xoha.order_type_id        = xott.transaction_type_id  -- 受注タイプID=取引タイプID
      AND    xoha.latest_external_flag = gv_flag_on
      AND    xola.delete_flag          = gv_flag_off   -- 削除フラグ
      AND    xoha.request_no           = pi_request_no
      AND    NOT EXISTS( SELECT 1
                         FROM   xxwsh_order_lines_all    sxola
                               ,xxwsh_reserve_interface  sxri
                         WHERE  sxri.invoice_no          = pi_invoice_no
                         AND    sxola.request_no         = pi_request_no
                         AND    sxola.shipping_item_code = sxri.item_code
                         AND    sxola.shipping_item_code = xola.shipping_item_code
                       )
      ;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
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
    -- グローバル変数の初期化
    gn_input_reserve_cnt  := 0;  -- 入力件数(倉替返品インターフェース)
--
    gn_output_headers_cnt := 0;  -- 倉替返品情報作成件数(受注ヘッダアドオン単位)
    gn_output_lines_cnt   := 0;  -- 倉替返品情報作成件数(受注明細アドオン単位)
    gn_output_lot_cnt     := 0;  -- 倉替返品情報作成件数(移動ロット詳細)
--
    gn_output_del_hd_cnt  := 0;  -- 倉替返品打消情報作成件数(受注ヘッダアドオン単位)
    gn_output_del_ln_cnt  := 0;  -- 倉替返品打消情報作成件数(受注明細アドオン単位)
    gn_output_del_lot_cnt := 0;  -- 倉替返品打消情報作成件数(移動ロット詳細単位)
--
    gn_output_upd_hd_cnt  := 0;  -- 倉替返品更新情報作成件数(受注ヘッダアドオン単位)
    gn_output_upd_ln_cnt  := 0;  -- 倉替返品更新情報作成件数(受注明細アドオン単位)
--
    gn_idx_hd     := 0;  -- 配列インデックス 受注ヘッダアドオン 一括登録用
    gn_idx_ln     := 0;  -- 配列インデックス 受注明細アドオン 一括登録用
    gn_idx_lot    := 0;  -- 配列インデックス 移動ロット詳細 一括登録用
--
    gn_idx_hd_a10 := 0;  -- 配列インデックス 受注ヘッダアドオン 最新フラグ 一括更新用
    gn_idx_hd_a12 := 0;  -- 配列インデックス 受注ヘッダアドオン 受注タイプ・登録順序 一括更新用
    gn_idx_ln_a13 := 0;  -- 配列インデックス 受注明細アドオン 数量・拠点依頼数量 一括更新用
    gn_idx_hd_a15 := 0;  -- 配列インデックス 受注ヘッダアドオン 合計数量 一括更新用
--
    gt_registered_sequence := 0; -- 登録順序
    gt_line_number_a11     := 0; -- A-11でセットする明細番号
    gt_sum_quantity        := 0; -- 合算数量
--
    -- ローカル変数の初期化
    lt_invoice_no_a2 := ' ';       -- 前回A-2伝票No初期化
    lt_invoice_no_a6 := ' ';       -- 前回A-6伝票No初期化
--
    -- WHOカラムの設定
    gt_user_id          := FND_GLOBAL.USER_ID;         -- 作成者(最終更新者)
    gt_sysdate          := SYSDATE;                    -- 作成日(最終更新日)
    gt_login_id         := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- アプリケーションID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
--
--------------------------------------------------------------------------------------
--  A-7、A-8、A-9、A-10、A-11、A-11-2を通る処理(MD050フローでいう③の処理)の懸念点
--  以下の実行例のようになるように作成しました
-- I/F            受注                        受注
-- #10 30001    #10 30001                    #10 30001
-- #10 30003    #10 30002    --(実行後)--->  #10 30002
-- #20 30001    #10 30004                    #10 30003
--              #20 30002                    #10 30004
--                                           #20 30001
--                                           #20 30002
--
-- ※I/Fの#10 30003、#20 30001をどうやって受注に出力するかが問題でした(A-11-2で出力するようにしました)
-- ※I/Fの#10 30001、#10 30003で#10が連続しているパターンが問題でした(ブレイクしたら出力するようにしました)
--
-- A-11、A-11-2をどのように通すかがポイントと思われます
-- lb_break_flg_a6、gb_a11_flgの２つのフラグで制御していますので
-- 上記フラグがいつON/OFFされるのかを中心に追っていけばよいと思います
--
--------------------------------------------------------------------------------------
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- プロファイル取得処理 (A-1)
    -- ===============================
    get_profile(
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- 倉替返品インターファイス情報抽出処理 (A-2)
    -- ==============================================
    get_reserve_interface(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_warn)                     -- 警告
    OR (lv_retcode = gv_status_error) THEN               -- エラー
      RAISE global_process_expt;
    END IF;
--
    <<gt_reserve_interface_tbl_loop>>
    FOR i IN gt_reserve_interface_tbl.FIRST .. gt_reserve_interface_tbl.LAST LOOP
--
-- 2009/10/20 H.Itou Add Start 本番障害#1569
      -- 在庫クローズチェックで警告の場合、処理をスキップさせるためにスキップ例外作成
      BEGIN
-- 2009/10/20 H.Itou Add End
      -- ===============================
      -- 変数・フラグの初期化
      -- ===============================
       lb_a13upd_flg := FALSE;
--
      -- ===============================
      -- 前回A-2伝票Noとのブレイク判定
      -- ===============================
      --前回A-2伝票Noと異なる場合
      -- A-2伝票Noがブレイクした場合
      IF (gt_reserve_interface_tbl(i).invoice_no <> lt_invoice_no_a2) THEN
        lb_break_flg_a2 := TRUE;
        lb_break_flg_a6 := TRUE;
-- del start 2009/01/15 ver1.10 by M.Uehara
--
--        -- 読み込んだA-2伝票Noを前回A-2伝票Noとして退避
--        lt_invoice_no_a2 := gt_reserve_interface_tbl(i).invoice_no;
-- del start 2009/01/15 ver1.10 by M.Uehara
--
        -- 明細数量チェック
        IF  (gb_posi_flg)
        AND (gb_nega_flg) THEN -- 同一A-2伝票No内で明細の数量に正数負数が混在している場合はエラー
-- mod start 2009/01/15 ver1.10 by M.Uehara
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_xxwsh_num_mix_err);
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_xxwsh_num_mix_err,'invoice_no',lt_invoice_no_a2);
-- mod end 2009/01/15 ver1.10 by M.Uehara
          lv_errbuf := lv_errmsg;
          lv_retcode := gv_status_error;
          RAISE global_process_expt;
        ELSE                            -- エラーがなければ明細チェックフラグを初期化
          gb_posi_flg := FALSE;         -- 正数用フラグ
          gb_nega_flg := FALSE;         -- 負数用フラグ
        END IF;
-- add start 2009/01/15 ver1.10 by M.Uehara
--
        -- 読み込んだA-2伝票Noを前回A-2伝票Noとして退避
        lt_invoice_no_a2 := gt_reserve_interface_tbl(i).invoice_no;
-- add end 2009/01/15 ver1.10 by M.Uehara
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
        -- 退避品目コード初期化
-- 2009/09/29 H.Itou Del Start 本番障害#1465 IF品目に関係なくデータを作成する必要があるのでコメントアウト
--        lt_bk_reserve_if_item_code := NULL;
-- 2009/09/29 H.Itou Del End
        lt_bk_confirm_item_code    := NULL;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
      --前回A-2伝票Noと同じ場合
      ELSE
        lb_break_flg_a2 := FALSE;
        lb_break_flg_a6 := FALSE;
      END IF;
--
      -- ===============================
      -- マスタ存在チェック処理 (A-3)
      -- ===============================
      check_master(
        gt_reserve_interface_tbl(i).invoice_no,            -- 1.A-2伝票No
        gt_reserve_interface_tbl(i).item_no,               -- 2.品目コード
        gt_reserve_interface_tbl(i).receive_base_code,     -- 3.相手拠点コード
        gt_reserve_interface_tbl(i).input_base_code,       -- 4.入力拠点コード
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 在庫会計期間チェック処理 (A-4)
      -- ===============================
      check_stock(
        gt_reserve_interface_tbl(i).recorded_date,         -- 1.計上日付(着日)
-- 2009/10/20 H.Itou Add Start 本番障害#1569
        gt_reserve_interface_tbl(i).data_dump,             -- 2.データダンプ
-- 2009/10/20 H.Itou Add End
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
-- 2009/10/20 H.Itou Mod Start 本番障害#1569 在庫クローズエラーのときは警告とし、後続処理をスキップする。
      ELSIF (lv_retcode = gv_status_warn) THEN
        RAISE skip_expt;
-- 2009/10/20 H.Itou Mod End
      END IF;
--
      -- ===============================
      -- 関連データ取得処理 (A-5)
      -- ===============================
      get_order_type(
        gt_reserve_interface_tbl(i).invoice_class_1,       -- 1.伝区１
        gt_reserve_interface_tbl(i).invoice_no,            -- 2.A-2伝票No
        gt_reserve_interface_tbl(i).recorded_date,         -- 3.計上日付(着日) 2008/10/10 v1.5 M.Hirafuku ADD
        gt_reserve_interface_tbl(i).item_no,               -- 4.品目コード     2008/10/10 v1.5 M.Hirafuku ADD
        gt_reserve_interface_tbl(i).quantity_total,        -- 5.数量           2008/10/10 v1.5 M.Hirafuku ADD
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 同一依頼No情報抽出処理 (A-6)
      -- ===============================
      get_order_all_tbl(
        gt_reserve_interface_tbl(i).recorded_date,         -- 1.計上日付（着日）
        gt_reserve_interface_tbl(i).receive_base_code,     -- 2.相手拠点コード
        gt_reserve_interface_tbl(i).input_base_code,       -- 3.入力拠点コード
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 同一依頼No情報が抽出できた場合
      IF (gt_order_all_tbl.COUNT > 0) THEN
--
        gb_a11_flg := FALSE;  -- フラグ初期化
--
        <<gt_order_all_tbl_loop>>
        FOR j IN gt_order_all_tbl.FIRST .. gt_order_all_tbl.LAST LOOP
--
          ln_idx_a6 := j;      -- LOOPの外のA-13②でindexの値を使用するため変数に退避
--
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
          -- 出荷実績計上済の場合
          -- LOOPを抜けた直後で出荷実績計上済か否かの判定が必要なのでここで変数に退避しておく
          lt_req_statu    := gt_order_all_tbl(ln_idx_a6).hd_req_status;
          lt_actual_class := gt_order_all_tbl(ln_idx_a6).hd_actual_confirm_class;
--
          -- 出荷実績計上済且つ実績計上済区分='Y'の場合
          IF ((lt_req_statu = cv_req_status_confirm) AND (lt_actual_class = gv_flag_on)) THEN
--
            IF (lb_break_flg_a2) THEN  -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
              -- ここではA-2伝票Noブレイクフラグを初期化しないで下さい
              -- ===========================================
              -- 倉替返品打消情報(ヘッダ)作成処理 (A-7)
              -- ===========================================
              IF (ln_idx_a6 = 1) THEN
                set_del_headers(
                  lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                  lv_retcode,        -- リターン・コード             --# 固定 #
                  lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END IF;
--
            IF (lb_break_flg_a6) THEN  -- A-6伝票Noがブレイクした場合(前回A-6伝票Noと異なる場合)
--
              -- ここではA-6伝票Noブレイクフラグを初期化しないで下さい
              -- ===========================================
              -- 倉替返品打消情報(明細)作成処理 (A-8)
              -- ===========================================
              set_del_lines(
                ln_idx_a6,                                         -- 1.配列インデックス
                lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                lv_retcode,        -- リターン・コード             --# 固定 #
                lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
--
          -- ===========================================
          -- 合算数量の算出 (A-18)
          -- ===========================================
-- 2009/09/29 H.Itou Del Start 本番障害#1465 IF品目に関係なくデータを作成する必要があるのでコメントアウト
--          -- 「倉替IF・受注アドオンの合計数量を比較した品目コード」以上の品目コードの場合のみLOOPに入る
--          IF (  lt_bk_reserve_if_item_code IS NULL
--             OR lt_bk_reserve_if_item_code <= gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code
--             )
--          THEN
-- 2009/09/29 H.Itou Del End
--
            -- 実績計上済で、アドオンにあるが倉替IFにない場合は明細を挿入する
            IF ((lt_req_statu = cv_req_status_confirm) AND (lt_actual_class = gv_flag_on)) THEN
            
              SELECT COUNT(xola.order_line_id)
              INTO   ln_line_cnt
              FROM   xxwsh_order_lines_all  xola
              WHERE  xola.request_no         = gt_order_all_tbl(ln_idx_a6).hd_request_no
              AND    xola.shipping_item_code = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code
              AND    NOT EXISTS( SELECT 1
                                 FROM   xxwsh_reserve_interface  xri
                                 WHERE  xri.invoice_no = gt_reserve_interface_tbl(i).invoice_no
                                 AND    xri.item_code  = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code
                                )
              ;
--
              -- 倉替返品IFにない受注アドオンの品目で,挿入していない品目のみ登録する
              IF (   ln_line_cnt > 0
                 AND (  lt_bk_confirm_item_code IS NULL
                     OR lt_bk_confirm_item_code < gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code
                     )
                 )
              THEN
                lt_bk_confirm_item_code := gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code;
--
                -- 合算数量<--A-6で取得した加算用数量
                gt_sum_quantity := gt_order_all_tbl(ln_idx_a6).ln_add_quantity;
--
                IF (lb_break_flg_a2) THEN      -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--
                  lb_break_flg_a2 := FALSE;   -- A-2伝票Noブレイクフラグ初期化
                  gt_line_number_a11 := 0;    -- A-11でセットする明細番号(ヘッダ単位に1から採番)
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
                  -- ===========================================
                  -- 倉替返品情報(ヘッダ)作成処理 (A-9)
                  -- ===========================================
                  set_order_headers(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
                    gt_reserve_interface_tbl(i).recorded_date,         -- 3.計上日付(着日)
                    gt_reserve_interface_tbl(i).receive_base_code,     -- 4.相手拠点コード
                    gt_reserve_interface_tbl(i).input_base_code,       -- 5.入力拠点コード
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
                  -- ===========================================
                  -- 最新フラグ更新情報作成処理 (A-10)
                  -- ===========================================
                  set_latest_external_flag(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
                END IF;
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
                IF (lb_break_flg_a6) THEN  -- A-6伝票Noがブレイクした場合(前回A-6伝票Noと異なる場合)
                  -- ここではA-6伝票Noブレイクフラグを初期化しないで下さい
                  -- ===========================================
                  -- 倉替返品情報(明細)作成処理 (A-11)
                  -- ===========================================
                  set_order_lines(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).item_no,               -- 2.品目コード
                    gt_reserve_interface_tbl(i).quantity_total,        -- 3.数量
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
                END IF;
              END IF;
            END IF;
-- 2009/09/29 H.Itou Del Start 本番障害#1465 IF品目に関係なくデータを作成する必要があるのでコメントアウト
--            -- 倉替IFの品目コードを退避する
--            IF lt_bk_reserve_if_item_code > gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code THEN
--              lt_bk_reserve_if_item_code := NULL;
--            ELSE
--              lt_bk_reserve_if_item_code := gt_reserve_interface_tbl(i).item_no;
--            END IF;
-- 2009/09/29 H.Itou Del End
            -- 同品目の場合のみ、受注アドオンの数量にIFの数量を加算する
            IF gt_reserve_interface_tbl(i).item_no = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code THEN
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
--
              -- 合算数量<--A-2で取得した数量 + A-6で取得した加算用数量
              gt_sum_quantity := gt_reserve_interface_tbl(i).quantity_total
                               + gt_order_all_tbl(ln_idx_a6).ln_add_quantity;
-- ver1.13 Y.Kazama 本番障害#1335対応 Del Start
--              -- 出荷実績計上済の場合
--              -- LOOPを抜けた直後で出荷実績計上済か否かの判定が必要なのでここで変数に退避しておく
--              lt_req_statu := gt_order_all_tbl(ln_idx_a6).hd_req_status;
----2008/08/07 Add ↓
--              lt_actual_class := gt_order_all_tbl(ln_idx_a6).hd_actual_confirm_class;
----2008/08/07 Add ↑
-- ver1.13 Y.Kazama 本番障害#1335対応 Del End
/* 2008/08/07 Mod ↓
          IF (lt_req_statu = cv_req_status_confirm) THEN
2008/08/07 Mod ↑ */
              -- 出荷実績計上済且つ実績計上済区分='Y'の場合
              IF ((lt_req_statu = cv_req_status_confirm) AND (lt_actual_class = gv_flag_on)) THEN
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Del Start
--                IF (lb_break_flg_a2) THEN  -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--                  -- ここではA-2伝票Noブレイクフラグを初期化しないで下さい
--                  -- ===========================================
--                  -- 倉替返品打消情報(ヘッダ)作成処理 (A-7)
--                  -- ===========================================
--                  IF (ln_idx_a6 = 1) THEN
--                    set_del_headers(
--                      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--                      lv_retcode,        -- リターン・コード             --# 固定 #
--                      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
--                    IF (lv_retcode = gv_status_error) THEN
--                      RAISE global_process_expt;
--                    END IF;
--                  END IF;
--                END IF;
--
--                IF (lb_break_flg_a6) THEN  -- A-6伝票Noがブレイクした場合(前回A-6伝票Noと異なる場合)
--
--                  -- ここではA-6伝票Noブレイクフラグを初期化しないで下さい
--                  -- ===========================================
--                  -- 倉替返品打消情報(明細)作成処理 (A-8)
--                  -- ===========================================
--                  set_del_lines(
--                    ln_idx_a6,                                         -- 1.配列インデックス
--                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--                    lv_retcode,        -- リターン・コード             --# 固定 #
--                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
--                  IF (lv_retcode = gv_status_error) THEN
--                    RAISE global_process_expt;
--                  END IF;
--                END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Del End
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
                -- 既に倉替返品更新ヘッダをコールしている場合
                IF ( NOT lb_break_flg_a2 ) THEN
                  -- 退避変数初期化
                  lt_bk_order_type_id := NULL;
--
                  -- 合算数量>0(正)の場合
                  IF (gt_sum_quantity > 0) THEN
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
                    IF (gt_new_transaction_catg_code = gv_cate_return) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
                      lt_bk_order_type_id := gt_new_transaction_type_id;
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
                    ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
                      lt_bk_order_type_id := gt_del_transaction_type_id;
                    END IF;
                  ELSIF( gt_sum_quantity < 0 ) THEN      -- 合算数量<0(負)の場合
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
                    IF (gt_new_transaction_catg_code = gv_cate_return) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
                      lt_bk_order_type_id := gt_del_transaction_type_id;
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
                    ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
                      lt_bk_order_type_id := gt_new_transaction_type_id;
                    END IF;
                  END IF;
--
                  -- 前品目で設定した受注タイプと異なる場合は上書き
                  IF (   lt_bk_order_type_id IS NOT NULL
                     AND gt_xoh_order_type_id(gn_idx_hd) <> lt_bk_order_type_id
                     )
                  THEN
--
                    gt_xoh_order_type_id(gn_idx_hd) := lt_bk_order_type_id;
                  END IF;
                END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
                IF (lb_break_flg_a2) THEN      -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--
                  lb_break_flg_a2 := FALSE;   -- A-2伝票Noブレイクフラグ初期化
                  gt_line_number_a11 := 0;    -- A-11でセットする明細番号(ヘッダ単位に1から採番)
--
                  -- ===========================================
                  -- 倉替返品情報(ヘッダ)作成処理 (A-9)
                  -- ===========================================
                  set_order_headers(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
                    gt_reserve_interface_tbl(i).recorded_date,         -- 3.計上日付(着日)
                    gt_reserve_interface_tbl(i).receive_base_code,     -- 4.相手拠点コード
                    gt_reserve_interface_tbl(i).input_base_code,       -- 5.入力拠点コード
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
--
                  -- ===========================================
                  -- 最新フラグ更新情報作成処理 (A-10)
                  -- ===========================================
                  set_latest_external_flag(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
                END IF;
--
                -- A-2で取得した品目コード=A-6で取得した出荷品目の場合
                IF (gt_reserve_interface_tbl(i).item_no = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code) THEN
                  -- A-2で取得した品目がA-6で取得した品目にない場合A-2で取得した品目を作成するためのフラグ
                  gb_a11_flg := TRUE;    -- A-11-2を行うかどうかを制御するフラグ
                END IF;
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Del Start
--                IF (lb_break_flg_a6) THEN  -- A-6伝票Noがブレイクした場合(前回A-6伝票Noと異なる場合)
-- ver1.13 Y.Kazama 本番障害#1335対応 Del End
                  -- ここではA-6伝票Noブレイクフラグを初期化しないで下さい
                  -- ===========================================
                  -- 倉替返品情報(明細)作成処理 (A-11)
                  -- ===========================================
                  set_order_lines(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).item_no,               -- 2.品目コード
                    gt_reserve_interface_tbl(i).quantity_total,        -- 3.数量
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Del Start
--                END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Del End
--
                -- A-2で取得した品目がA-6で取得した品目にない場合A-2で取得した品目を作成する
                IF (j = gt_order_all_tbl.LAST) THEN
                  IF (gb_a11_flg = FALSE) THEN         -- A-2で取得した品目がA-6で取得した品目にない場合
--
                    set_order_lines_2(
                      gt_reserve_interface_tbl(i).item_no,               -- 1.品目コード
                      gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
                      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                      lv_retcode,        -- リターン・コード             --# 固定 #
                      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_process_expt;
                    END IF;
--
                  END IF;
                END IF;
--
              -- =======================================================================================
              -- 出荷実績計上済でない場合
              ELSE
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
                -- 既に倉替返品更新ヘッダをコールしている場合
                IF NOT lb_break_flg_a2 THEN
--
                  -- 退避変数初期化
                  lt_bk_order_type_id := NULL;
--
                  -- 合算数量>0(正)の場合
                  IF (gt_sum_quantity > 0) THEN
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
                    IF (gt_new_transaction_catg_code = gv_cate_return) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
                      lt_bk_order_type_id := gt_new_transaction_type_id;
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
                    ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
                      lt_bk_order_type_id := gt_del_transaction_type_id;
                    END IF;
                  ELSIF( gt_sum_quantity < 0 ) THEN      -- 合算数量<0(負)の場合
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=返品の場合
                    IF (gt_new_transaction_catg_code = gv_cate_return) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(打消).取引タイプID
                      lt_bk_order_type_id := gt_del_transaction_type_id;
                    -- A-6で取得した受注タイプ(新規/訂正).受注カテゴリ=受注の場合
                    ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
                      -- 受注タイプID<--A-6で取得した受注タイプ(新規/訂正).取引タイプID
                      lt_bk_order_type_id := gt_new_transaction_type_id;
                    END IF;
                  END IF;
--
                  -- 前品目で設定した受注タイプと異なる場合は上書き
                  IF (   lt_bk_order_type_id IS NOT NULL
                     AND gt_xoh_a12_order_type_id(gn_idx_hd_a12) <> lt_bk_order_type_id
                     )
                  THEN
--
                    gt_xoh_a12_order_type_id(gn_idx_hd_a12) := lt_bk_order_type_id;
                  END IF;
                END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
--
                IF (lb_break_flg_a2) THEN   -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--
                  lb_break_flg_a2 := FALSE;    -- A-2伝票Noブレイクフラグ初期化
--
                  -- ===========================================
                  -- 倉替返品更新情報(ヘッダ)作成処理 (A-12)
                  -- ===========================================
                  set_upd_order_headers(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
                END IF;
--
                -- ===========================================
                -- 倉替返品更新情報(明細)作成処理 (A-13①)
                -- ===========================================
                -- A-2で取得した品目コード=A-6で取得した出荷品目の場合は更新
                -- 同じ品目がなければここでは何もしない
                IF (gt_reserve_interface_tbl(i).item_no = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code) THEN
--
                  set_upd_order_lines_upd(
                    ln_idx_a6,                                         -- 1.配列インデックス
                    gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
                    lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                    lv_retcode,        -- リターン・コード             --# 固定 #
                    lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
                    lb_a13upd_flg := TRUE;  -- 同じ品目があればフラグをONにする
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_process_expt;
                  END IF;
                END IF;
              END IF;
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
            END IF;
-- 2009/09/29 H.Itou Del Start 本番障害#1465 IF品目に関係なくデータを作成する必要があるのでコメントアウト
--          END IF;
-- 2009/09/29 H.Itou Del End
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
        END LOOP gt_order_all_tbl_loop;
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
        <<get_order_minus_reserve>>
        FOR rec_get_order_minus_reserve IN cur_get_order_minus_reserve( pi_request_no => gt_request_no
                                                                       ,pi_invoice_no => gt_reserve_interface_tbl(i).invoice_no ) LOOP
--
          IF rec_get_order_minus_reserve.quantity > 0 THEN
            gb_posi_flg := TRUE;
          ELSE
            gb_nega_flg := TRUE;
          END IF;
--
        END LOOP get_order_minus_reserve;

--
        IF (   lt_req_statu <> cv_req_status_confirm ) THEN
          IF (lb_break_flg_a2) THEN   -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
            -- 合算数量<--A-2で取得した数量 + A-6で取得した加算用数量
            gt_sum_quantity := gt_reserve_interface_tbl(i).quantity_total;

            -- ===========================================
            -- 倉替返品更新情報(ヘッダ)作成処理 (A-12)
            -- ===========================================
            set_upd_order_headers(
              ln_idx_a6,                                         -- 1.配列インデックス
              gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
            lb_break_flg_a2 := FALSE;    -- A-2伝票Noブレイクフラグ初期化
          END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
          -- ===========================================
          -- 倉替返品更新情報(明細)作成処理 (A-13②)
          -- ===========================================
          -- 出荷実績計上済でない場合で、A-2で取得した品目がA-6で取得した品目になかった場合
          -- 同じ品目がないのでここで新規に明細を作成する
          IF (lt_req_statu <> cv_req_status_confirm) AND
             (NOT lb_a13upd_flg) THEN
--
            set_upd_order_lines_ins( -- ここで渡すものはA-6ではなくA-2で取得したほうなので注意！
              ln_idx_a6,                                         -- 1.配列インデックス
              gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
              gt_reserve_interface_tbl(i).item_no,               -- 3.品目コード
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
        END IF;
        -- A-2で取得した品目がA-6で取得した品目にない場合A-2で取得した品目を作成する
        IF (   lt_req_statu = cv_req_status_confirm ) THEN
          IF (lb_break_flg_a2) THEN      -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--
            lb_break_flg_a2 := FALSE;   -- A-2伝票Noブレイクフラグ初期化
            gt_line_number_a11 := 0;    -- A-11でセットする明細番号(ヘッダ単位に1から採番)
--
            -- ===========================================
            -- 倉替返品情報(ヘッダ)作成処理 (A-9)
            -- ===========================================
            set_order_headers(
              ln_idx_a6,                                         -- 1.配列インデックス
              gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
              gt_reserve_interface_tbl(i).recorded_date,         -- 3.計上日付(着日)
              gt_reserve_interface_tbl(i).receive_base_code,     -- 4.相手拠点コード
              gt_reserve_interface_tbl(i).input_base_code,       -- 5.入力拠点コード
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ===========================================
            -- 最新フラグ更新情報作成処理 (A-10)
            -- ===========================================
            set_latest_external_flag(
              ln_idx_a6,                                         -- 1.配列インデックス
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
        
          IF gb_a11_flg = FALSE THEN  -- A-2で取得した品目がA-6で取得した品目にない場合
--
            set_order_lines_2(
              gt_reserve_interface_tbl(i).item_no,               -- 1.品目コード
              gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
        END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
--
      -- ===========================================================================================
      -- 同一依頼No情報が抽出できなかった場合
      ELSE
        IF (lb_break_flg_a2) THEN      -- A-2伝票Noがブレイクした場合(前回A-2伝票Noと異なる場合)
--
          lb_break_flg_a2 := FALSE;    -- A-2伝票Noブレイクフラグ初期化
          gt_line_number_a11 := 0;  -- A-11でセットする明細番号(ヘッダ単位に1から採番)
--
          -- ===========================================
          -- 倉替返品情報(ヘッダ)作成処理 (A-9)
          -- ===========================================
          set_order_headers(
            ln_idx_a6,                                         -- 1.配列インデックス
            gt_reserve_interface_tbl(i).quantity_total,        -- 2.数量
            gt_reserve_interface_tbl(i).recorded_date,         -- 3.計上日付(着日)
            gt_reserve_interface_tbl(i).receive_base_code,     -- 4.相手拠点コード
            gt_reserve_interface_tbl(i).input_base_code,       -- 5.入力拠点コード
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===========================================
        -- 倉替返品情報(明細)作成処理 (A-11)
        -- ===========================================
        set_order_lines(
          ln_idx_a6,                                         -- 1.配列インデックス
          gt_reserve_interface_tbl(i).item_no,               -- 2.品目コード
          gt_reserve_interface_tbl(i).quantity_total,        -- 3.数量
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
-- 2009/10/20 H.Itou Add Start 本番障害#1569
      -- 在庫クローズチェックで警告の場合、処理をスキップさせるためにスキップ例外作成
      EXCEPTION
        WHEN skip_expt THEN
          ov_retcode := gv_status_warn; -- 終了ステータスに警告をセット
      END;
-- 2009/10/20 H.Itou Add End
--
    END LOOP gt_reserve_interface_tbl_loop;
--
-- ver1.13 Y.Kazama 本番障害#1335対応 Add Start
    --------------------------------------
    -- 最終伝票Noの明細数量正負チェック
    --------------------------------------
    -- 同一伝票No内で明細の数量が正負混在している場合はエラー
    IF ( gb_posi_flg AND gb_nega_flg ) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg( gv_xxwsh,gv_xxwsh_num_mix_err ,'invoice_no' ,lt_invoice_no_a2);
      lv_errbuf  := lv_errmsg;
      lv_retcode := gv_status_error;
      RAISE global_process_expt;
    END IF;
-- ver1.13 Y.Kazama 本番障害#1335対応 Add End
--
    -- ===============================
    -- 倉替返品情報登録処理 (A-14)
    -- ===============================
    ins_order(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 倉替返品抽出合計処理 (A-15)
    -- ===============================
    sum_lines_quantity(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 倉替返品情報再登録処理 (A-16)
    -- ===============================
    upd_headers_sum_quantity(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 倉替返品インターフェース情報削除処理 (A-17)
    -- =============================================
    del_reserve_interface(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
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
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- エラー・メッセージ  --# 固定 #
    retcode             OUT NOCOPY VARCHAR2      -- リターン・コード    --# 固定 #
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf,             -- エラー・メッセージ           --# 固定 #
      lv_retcode,            -- リターン・コード             --# 固定 #
      lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = gv_status_error)
-- 2009/10/20 H.Itou Mod Start 本番障害#1569
--    OR (lv_retcode = gv_status_warn) THEN
    THEN
-- 2009/10/20 H.Itou Mod End
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
-- 2009/10/20 H.Itou Add Start 本番障害#1569
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
-- 2009/10/20 H.Itou Add End
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
    --処理件数出力
--
    -- 入力件数(倉替返品インターフェース)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_input_reserve_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_input_reserve_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品情報作成件数(受注ヘッダアドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_headers_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_headers_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品情報作成件数(受注明細アドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_lines_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_lines_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品情報作成件数(移動ロット詳細単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_lot_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_lot_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品打消情報作成件数(受注ヘッダアドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_hd_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_hd_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品打消情報作成件数(受注明細アドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_ln_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_ln_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品打消情報作成件数(移動ロット詳細単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_lot_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_lot_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品更新情報作成件数(受注ヘッダアドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_upd_hd_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_upd_hd_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 倉替返品更新情報作成件数(受注明細アドオン単位)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_upd_ln_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_upd_ln_cnt));
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
END xxwsh430001c;
/
