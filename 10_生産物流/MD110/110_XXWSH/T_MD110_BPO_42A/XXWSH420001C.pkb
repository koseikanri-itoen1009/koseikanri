CREATE OR REPLACE PACKAGE BODY xxwsh420001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420001C(spec)
 * Description      : 出荷依頼/出荷実績作成処理
 * MD.050           : 出荷実績 T_MD050_BPO_420
 * MD.070           : 出荷依頼出荷実績作成処理 T_MD070_BPO_42A
 * Version          : 1.18
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *
 *  input_param_check            A1入力パラメータチェック
 *  get_profile                  A2プロファイル値取得
 *  get_new_cust_data            顧客マスタデータ最新取得(配送先番号で取得)
 *  get_new_cust_data            顧客マスタデータ最新取得(顧客番号で取得)
 *  get_new_cust_site_data       顧客サイトマスタデータ最新取得
 *  get_order_info               A3受注アドオン情報取得
 *  get_same_request_number      A4同一依頼No検索処理
 *  get_revised order_info       A5訂正前受注ヘッダアドオン情報取得
 *  create_order_header_info     A6受注ヘッダ情報の登録
 *  create_order_line_info       A7受注明細レコード作成、A8受注明細登録
 *  delivery_action_proc         A9ピックリリースAPI起動
 *  get_lot_details              A10ロット情報取得
 *  set_allocate_opm_order       A11在庫割当API起動
 *  pick_confirm_proc            移動オーダ取引処理
 *  confirm_proc                 A12出荷確認API起動
 *  create_rma_order_header_info A13RMA受注ヘッダ情報の登録
 *  create_rma_order_line_info   A14RMA受注明細レコード作成、A15RMA受注明細登録
 *  create_lot_details           A16ロット情報作成
 *  upd_status                   A17ステータス更新
 *  shipping_process             出荷情報登録処理
 *  return_process               返品情報登録処理
 *  ins_mov_lot_details          A18移動ロット詳細(アドオン)登録
 *  ins_transaction_interface    A19受入取引オープンインタフェーステーブル登録処理
-- Ver1.18 M.Hokkanji Start
 *  upd_mov_lot_details          A21移動ロット詳細(アドオン)更新
-- Ver1.18 M.Hokkanji End
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/24    1.0   Oracle 北寒寺 正夫 初回作成
 *  2008/05/14    1.1   Oracle 宮田 隆史   MD050指摘事項のNo56反映
 *  2008/05/19    1.2   Oracle 宮田 隆史   依頼NoのTO_NUMBER化廃止
 *  2008/05/22    1.3   Oracle 宮田 隆史   受注明細作成時の単価NULL対応
 *  2008/06/12    1.4   Oracle 丸下 博宣   受注ヘッダ、明細更新時の対象WHOカラムを追加
 *  2008/06/27    1.5   Oracle 丸下 博宣   受注明細登録時の削除フラグにNを設定
 *  2008/09/01    1.6   Oracle 山根 一浩   課題#64変更#176対応
 *  2008/10/10    1.7   Oracle 伊藤 ひとみ 統合テスト指摘116対応
 *  2008/12/02    1.8   Oracle 北寒寺正夫  本番障害対応
 *  2008/12/13    1.9   Oracle 二瓶 大輔   本番障害#568対応
 *  2008/12/15    1.10  Oracle 吉元 強樹   検証用ログ設定
 *  2008/12/24    1.11  SCS    菅原 大輔   本番#845
 *  2009/01/15    1.12  SCS    伊藤 ひとみ 本番#981
 *  2009/04/08    1.13  SCS    伊藤 ひとみ 本番#1356
 *  2009/04/14    1.14  SCS    伊藤 ひとみ 本番#1406
 *  2009/04/21    1.15  SCS    伊藤 ひとみ 本番#1356(再対応) 出荷先_指示IDと管轄拠点も最新に洗替する
 *  2009/10/09    1.16  SCS    伊藤 ひとみ 本番#1655 中止客申請フラグを見ない
 *  2009/11/05    1.17  SCS    伊藤 ひとみ 本番#1648 顧客フラグ対応
 *  2010/03/03    1.18  SCS    北寒寺 正夫 本番稼働障害#1612 、#1703
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --正常
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --警告
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --失敗
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --ステータス(正常)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --ステータス(警告)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --ステータス(失敗)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- 区切り文字
  gv_exec_user     VARCHAR2(100);             -- 実行ユーザ名
  gv_conc_name     VARCHAR2(30);              -- 実行コンカレント名
  gv_conc_status   VARCHAR2(30);              -- 実行結果
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 **
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_sub_main_expt         EXCEPTION;     -- サブメインのエラー
  lock_error_expt             EXCEPTION;     -- ロックエラー
  order_error_expt            EXCEPTION;     -- 受注処理エラー（処理経過ステータス更新処理起動のため)
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  gv_msg_kbn             CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxwsh420001c';    -- パッケージ名
--
  --メッセージ番号(固定処理)
  gv_msg_42a_001         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00001';  -- ユーザー名
  gv_msg_42a_002         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00002';  -- コンカレント名
  gv_msg_42a_003         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00003';  -- セパレータ
  gv_msg_42a_004         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00012';  -- 処理ステータス
  gv_msg_42a_005         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-10030';  -- コンカレント定型エラー
  gv_msg_42a_006         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-10118';  -- 起動時間
  --メッセージ番号(現コンカレント専用)
  gv_msg_42a_007         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01551';  -- 入力パラメータ表示(ブロック)
  gv_msg_42a_008         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01552';  -- 入力パラメータ表示(出荷元)
  gv_msg_42a_009         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01553';  -- 入力パラメータ表示(依頼No)
  gv_msg_42a_010         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01554';  -- 入力件数(依頼No)
  gv_msg_42a_011         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01555';  -- 新規受注作成件数
  gv_msg_42a_012         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01556';  -- 訂正受注作成件数
  gv_msg_42a_013         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01557';  -- 取消情報件数
  gv_msg_42a_014         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01558';  -- 異常件数
  gv_msg_42a_015         CONSTANT VARCHAR2(15) 
                         := 'APP-XXWSH-01559';  -- 受入取引処理コンカレント要求ID
  gv_msg_42a_016         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11551';  -- APIエラー
  gv_msg_42a_017         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11552';  -- ブロック取得エラーメッセージ
  gv_msg_42a_018         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11553';  -- プロファイル取得エラー
  gv_msg_42a_019         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11554';  -- ロックエラー
  gv_msg_42a_020         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11555';  -- 受入取引処理エラー
  gv_msg_42a_021         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11556';  -- 出荷元取得エラーメッセージ
  gv_msg_42a_022         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11557';  -- 同一依頼No検索エラー
  gv_msg_42a_023         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11558';  -- 訂正前受注アドオン情報取得エラー
  gv_msg_42a_024         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11559';  -- 使用目的ID取得エラー
-- 2008/09/01 Add
  gv_msg_42a_025         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-13181';  -- 未来日エラーメッセージ
-- Ver1.18 M.Hokkanji Start
  gv_msg_42a_026         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11561';  -- 搬送明細ID取得エラー
  gv_msg_42a_027         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11562';  -- 移動ロット詳細ロックエラー
-- Ver1.18 M.Hokkanji End
--
  --トークン(固定処理)
  gv_tkn_status          CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_conc            CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user            CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time            CONSTANT VARCHAR2(15) := 'TIME';
  --トークン(現コンカレント専用)
  gv_tkn_in_block        CONSTANT VARCHAR2(15) := 'IN_BLOCK';
  gv_tkn_in_shipf        CONSTANT VARCHAR2(15) := 'IN_SHIPF';
  gv_tkn_request_no      CONSTANT VARCHAR2(15) := 'REQUEST_NO';
  gv_tkn_input_cnt       CONSTANT VARCHAR2(15) := 'INPUT_CNT';
  gv_tkn_new_order       CONSTANT VARCHAR2(15) := 'NEW_ORDER';
  gv_tkn_upd_order       CONSTANT VARCHAR2(15) := 'UPD_ORDER';
  gv_tkn_cancell_cnt     CONSTANT VARCHAR2(15) := 'CANCELL_CNT';
  gv_tkn_error_cnt       CONSTANT VARCHAR2(15) := 'ERROR_CNT';
  gv_tkn_error_msg       CONSTANT VARCHAR2(15) := 'ERR_MSG';
  gv_tkn_prof_name       CONSTANT VARCHAR2(15) := 'PROF_NAME';
  gv_tkn_api_name        CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_meaning         CONSTANT VARCHAR2(15) := 'MEANING';
  gv_tkn_lookup_type     CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_request_id      CONSTANT VARCHAR2(15) := 'REQUEST_ID';
  gv_tkn_order_header_id CONSTANT VARCHAR2(15) := 'ORDER_HEADER_ID';
  gv_tkn_header_id       CONSTANT VARCHAR2(15) := 'HEADER_ID';
  gv_tkn_message_tokun   CONSTANT VARCHAR2(15) := 'MESSAGE_TOKUN';
  gv_tkn_search          CONSTANT VARCHAR2(15) := 'SEARCH';
-- 2008/09/01 Add
  gv_tkn_para_date       CONSTANT VARCHAR2(15) := 'PARA_DATE';
  gv_tkn_param1          CONSTANT VARCHAR2(15) := 'PARAM1';
  gv_tkn_param2          CONSTANT VARCHAR2(15) := 'PARAM2';
  gv_tkn_param3          CONSTANT VARCHAR2(15) := 'PARAM3';
  gv_tkn_param4          CONSTANT VARCHAR2(15) := 'PARAM4';
--
  -- トークン表示用
  gv_api_name_1          CONSTANT VARCHAR2(30) := '予約';
  gv_api_name_2          CONSTANT VARCHAR2(30) := 'ピックリリースパッチ作成';
  gv_api_name_3          CONSTANT VARCHAR2(30) := '受注作成';
  gv_api_name_4          CONSTANT VARCHAR2(30) := 'プロセスオーダ取引処理';
  gv_api_name_5          CONSTANT VARCHAR2(30) := '出荷確認の作成';
  gv_api_name_6          CONSTANT VARCHAR2(30) := 'ピックリリースパッチ実行';
  gv_message_tokun1      CONSTANT VARCHAR2(30) := '顧客ID';
  gv_message_tokun2      CONSTANT VARCHAR2(30) := 'パーティサイトID';
  -- 受入取引処理用
  gv_application         CONSTANT VARCHAR2(15) := 'PO';
  gv_program             CONSTANT VARCHAR2(15) := 'RVCTP';
--
  gv_yes                 CONSTANT VARCHAR2(1)
                         := 'Y';                        -- YES_NO区分（YES)
  gv_no                  CONSTANT VARCHAR2(1)
                         := 'N';                        -- YES_NO区分（NO)
  gv_appl_code           CONSTANT VARCHAR2(15)
                         := 'XXCMN';                    -- チェック対象のアプリケーション短縮名
  gv_vappl_code          CONSTANT VARCHAR2(15)
                         := 'AU';                       -- チェック対象のVIEWアプリケーション短縮名
  gv_order_type_order    CONSTANT VARCHAR2(15)
                         := 'ORDER';                    -- 受注カテゴリ(受注)
  gv_order_type_return   CONSTANT VARCHAR2(15)
                         := 'RETURN';                   -- 受注カテゴリ(返品)
  gv_lot_ctl_1           CONSTANT VARCHAR2(1)
                         := '1';                        -- ロット管理品
  gv_new                 CONSTANT VARCHAR2(15)
                         := 'NEW';                      -- 受入取引登録で使用
  gv_pending             CONSTANT VARCHAR2(15)
                         := 'PENDING';                  -- 受入取引登録で使用
  gv_customer            CONSTANT VARCHAR2(15)
                         := 'CUSTOMER';                 -- 受入取引登録で使用
  gv_receive             CONSTANT VARCHAR2(15)
                         := 'RECEIVE';                  -- 受入取引登録で使用
  gv_batch               CONSTANT VARCHAR2(15)
                         := 'BATCH';                    -- 受入取引登録で使用
  gv_deliver             CONSTANT VARCHAR2(15)
                         := 'DELIVER';                  -- 受入取引登録で使用
  gv_rma                 CONSTANT VARCHAR2(15)
                         := 'RMA';                      -- 受入取引登録で使用
  gv_inventory           CONSTANT VARCHAR2(15)
                         := 'INVENTORY';                -- 受入取引登録で使用
  gv_rcv                 CONSTANT VARCHAR2(15)
                         := 'RCV';                      -- 受入取引登録で使用
--
  -- クイックコード取得用(ルックアップタイプ)
  gv_look_up_type_1      CONSTANT VARCHAR2(30)
                         := 'XXCMN_D12';                -- 物流ブロック
  -- クイックコード値
  gv_order_status_04     CONSTANT VARCHAR2(15)
                         := '04';                       -- 出荷実績計上済み(出荷)
  gv_order_status_08     CONSTANT VARCHAR2(15)
                         := '08';                       -- 出荷実績計上済み(支給)
  gv_document_type_10    CONSTANT VARCHAR2(15)
                         := '10';                       -- 出荷依頼
  gv_document_type_30    CONSTANT VARCHAR2(15)
                         := '30';                       -- 支給指示
  gv_record_type_20      CONSTANT VARCHAR2(15)
                         := '20';                       -- 出庫実績
  gv_ship_class_1        CONSTANT VARCHAR2(15)
                         := '1';                        -- 出荷依頼
  gv_ship_class_2        CONSTANT VARCHAR2(15)
                         := '2';                        -- 支給依頼
  gv_ship_class_3        CONSTANT VARCHAR2(15)
                         := '3';                        -- 倉替返品
--
  --プロファイル
  gv_pfr_org_id          CONSTANT VARCHAR2(25) := 'ORG_ID';
  gv_pfr_return_reason   CONSTANT VARCHAR2(20) := 'XXWSH_RETURN_REASON';
--
  --受注ID登録区分
  gv_status_0            CONSTANT VARCHAR2(1)
                         := '0';                         -- 登録しない
  gv_status_1            CONSTANT VARCHAR2(1)
                         := '1';                         -- 登録する
  --ユーザ定義変数
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 受注アドオン情報から取得したデータを格納するレコード
  TYPE order_rec IS RECORD(
    transaction_type_id
        oe_transaction_types_all.transaction_type_id%TYPE,        -- 受注タイプID
    transaction_type_code
        oe_transaction_types_all.transaction_type_code%TYPE,      -- 受注タイプコード
    order_category_code
        oe_transaction_types_all.order_category_code%TYPE,        -- 受注カテゴリ
    shipping_shikyu_class
        oe_transaction_types_all.attribute1%TYPE,                 -- 出荷支給区分
    order_header_id
        xxwsh_order_headers_all.order_header_id%TYPE,             -- 受注ヘッダアドオンID
    header_id
        xxwsh_order_headers_all.header_id%TYPE,                   -- 受注ヘッダID
    organization_id
        xxwsh_order_headers_all.organization_id%TYPE,             -- 組織ID
    ordered_date
        xxwsh_order_headers_all.ordered_date%TYPE,                -- 受注日
    customer_id
        xxwsh_order_headers_all.customer_id%TYPE,                 -- 顧客ID
    customer_code
        xxwsh_order_headers_all.customer_code%TYPE,               -- 顧客
    deliver_to_id
        xxwsh_order_headers_all.deliver_to_id%TYPE,               -- 出荷先ID
    deliver_to
        xxwsh_order_headers_all.deliver_to%TYPE,                  -- 出荷先
    shipping_instructions
        xxwsh_order_headers_all.shipping_instructions%TYPE,       -- 出荷指示
    career_id
        xxwsh_order_headers_all.career_id%TYPE,                   -- 運送業者ID
    freight_carrier_code
        xxwsh_order_headers_all.freight_carrier_code%TYPE,        -- 運送業者
    shipping_method_code
        xxwsh_order_headers_all.shipping_method_code%TYPE,        -- 配送区分
    cust_po_number
        xxwsh_order_headers_all.cust_po_number%TYPE,              -- 顧客発注
    price_list_id
        xxwsh_order_headers_all.price_list_id%TYPE,               -- 価格表
    request_no
        xxwsh_order_headers_all.request_no%TYPE,                  -- 依頼NO
    req_status
        xxwsh_order_headers_all.req_status%TYPE,                  -- ステータス
    delivery_no
        xxwsh_order_headers_all.delivery_no%TYPE,                 -- 配送NO
    prev_delivery_no
        xxwsh_order_headers_all.prev_delivery_no%TYPE,            -- 前回配送NO
    schedule_ship_date
        xxwsh_order_headers_all.schedule_ship_date%TYPE,          -- 出荷予定日
    schedule_arrival_date
        xxwsh_order_headers_all.schedule_arrival_date%TYPE,       -- 着荷予定日
    mixed_no
        xxwsh_order_headers_all.mixed_no%TYPE,                    -- 混載元NO
    collected_pallet_qty
        xxwsh_order_headers_all.collected_pallet_qty%TYPE,        -- パレット回収枚数
    confirm_request_class
        xxwsh_order_headers_all.confirm_request_class%TYPE,       -- 物流担当確認依頼区分
    freight_charge_class
        xxwsh_order_headers_all.freight_charge_class%TYPE,        -- 運賃区分
    shikyu_instruction_class
        xxwsh_order_headers_all.shikyu_instruction_class%TYPE,    -- 支給出庫指示区分
    shikyu_inst_rcv_class
        xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE,       -- 支給指示受領区分
    amount_fix_class
        xxwsh_order_headers_all.amount_fix_class%TYPE,            -- 有償金額確定区分
    takeback_class
        xxwsh_order_headers_all.takeback_class%TYPE,              -- 引取区分
    deliver_from_id
        xxwsh_order_headers_all.deliver_from_id%TYPE,             -- 出荷元ID
    deliver_from
        xxwsh_order_headers_all.deliver_from%TYPE,                -- 出荷元保管場所
    head_sales_branch
        xxwsh_order_headers_all.head_sales_branch%TYPE,           -- 管轄拠点
    input_sales_branch
        xxwsh_order_headers_all.input_sales_branch%TYPE,          -- 入力拠点
    po_no
        xxwsh_order_headers_all.po_no%TYPE,                       -- 発注NO
    prod_class
        xxwsh_order_headers_all.prod_class%TYPE,                  -- 商品区分
    item_class
        xxwsh_order_headers_all.item_class%TYPE,                  -- 品目区分
    no_cont_freight_class
        xxwsh_order_headers_all.no_cont_freight_class%TYPE,       -- 契約外運賃区分
    arrival_time_from
        xxwsh_order_headers_all.arrival_time_from%TYPE,           -- 着荷時間FROM
    arrival_time_to
        xxwsh_order_headers_all.arrival_time_to%TYPE,             -- 着荷時間TO
    designated_item_id
        xxwsh_order_headers_all.designated_item_id%TYPE,          -- 製造品目ID
    designated_item_code
        xxwsh_order_headers_all.designated_item_code%TYPE,        -- 製造品目
    designated_production_date
        xxwsh_order_headers_all.designated_production_date%TYPE,  -- 製造日
    designated_branch_no
        xxwsh_order_headers_all.designated_branch_no%TYPE,        -- 製造枝番
    slip_number
        xxwsh_order_headers_all.slip_number%TYPE,                 -- 送り状NO
    sum_quantity
        xxwsh_order_headers_all.sum_quantity%TYPE,                -- 合計数量
    small_quantity
        xxwsh_order_headers_all.small_quantity%TYPE,              -- 小口個数
    label_quantity
        xxwsh_order_headers_all.label_quantity%TYPE,              -- ラベル枚数
    loading_efficiency_weight
        xxwsh_order_headers_all.loading_efficiency_weight%TYPE,   -- 重量積載効率
    loading_efficiency_capacity
        xxwsh_order_headers_all.loading_efficiency_capacity%TYPE, -- 容積積載効率
    based_weight
        xxwsh_order_headers_all.based_weight%TYPE,                -- 基本重量
    based_capacity
        xxwsh_order_headers_all.based_capacity%TYPE,              -- 基本容積
    sum_weight
        xxwsh_order_headers_all.sum_weight%TYPE,                  -- 積載重量合計
    sum_capacity
        xxwsh_order_headers_all.sum_capacity%TYPE,                -- 積載容積合計
    mixed_ratio
        xxwsh_order_headers_all.mixed_ratio%TYPE,                 -- 混載率
    pallet_sum_quantity
        xxwsh_order_headers_all.pallet_sum_quantity%TYPE,         -- パレット合計枚数
    real_pallet_quantity
        xxwsh_order_headers_all.real_pallet_quantity%TYPE,        -- パレット実績枚数
    sum_pallet_weight
        xxwsh_order_headers_all.sum_pallet_weight%TYPE,           -- 合計パレット重量
    order_source_ref
        xxwsh_order_headers_all.order_source_ref%TYPE,            -- 受注ソース参照
    result_freight_carrier_id
        xxwsh_order_headers_all.result_freight_carrier_id%TYPE,   -- 運送業者_実績ID
    result_freight_carrier_code
        xxwsh_order_headers_all.result_freight_carrier_code%TYPE, -- 運送業者_実績
    result_shipping_method_code
        xxwsh_order_headers_all.result_shipping_method_code%TYPE, -- 配送区分_実績
    result_deliver_to_id
        xxwsh_order_headers_all.result_deliver_to_id%TYPE,        -- 出荷先_実績ID
    result_deliver_to
        xxwsh_order_headers_all.result_deliver_to%TYPE,           -- 出荷先_実績
    shipped_date
        xxwsh_order_headers_all.shipped_date%TYPE,                -- 出荷日
    arrival_date
        xxwsh_order_headers_all.arrival_date%TYPE,                -- 着荷日
    weight_capacity_class
        xxwsh_order_headers_all.weight_capacity_class%TYPE,       -- 重量容積区分
    notif_status
        xxwsh_order_headers_all.notif_status%TYPE,                -- 通知ステータス
    prev_notif_status
        xxwsh_order_headers_all.prev_notif_status%TYPE,           -- 前回通知ステータス
    notif_date
        xxwsh_order_headers_all.notif_date%TYPE,                  -- 確定通知実施日時
    new_modify_flg
        xxwsh_order_headers_all.new_modify_flg%TYPE,              -- 新規修正フラグ
    process_status
        xxwsh_order_headers_all.process_status%TYPE,              -- 処理経過ステータス
    performance_management_dept
        xxwsh_order_headers_all.performance_management_dept%TYPE, -- 成績管理部署
    instruction_dept
        xxwsh_order_headers_all.instruction_dept%TYPE,            -- 指示部署
    transfer_location_id
        xxwsh_order_headers_all.transfer_location_id%TYPE,        -- 振替先ID
    transfer_location_code
        xxwsh_order_headers_all.transfer_location_code%TYPE,      -- 振替先
    mixed_sign
        xxwsh_order_headers_all.mixed_sign%TYPE,                  -- 混載記号
    screen_update_date
        xxwsh_order_headers_all.screen_update_date%TYPE,          -- 画面更新日時
    screen_update_by
        xxwsh_order_headers_all.screen_update_by%TYPE,            -- 画面更新者
    tightening_date
        xxwsh_order_headers_all.tightening_date%TYPE,             -- 出荷依頼締め日時
    vendor_id
        xxwsh_order_headers_all.vendor_id%TYPE,                   -- 取引先ID
    vendor_code
        xxwsh_order_headers_all.vendor_code%TYPE,                 -- 取引先
    vendor_site_id
        xxwsh_order_headers_all.vendor_site_id%TYPE,              -- 取引先サイトID
    vendor_site_code
        xxwsh_order_headers_all.vendor_site_code%TYPE,            -- 取引先サイト
    registered_sequence
        xxwsh_order_headers_all.registered_sequence%TYPE,         -- 登録順序
    tightening_program_id
        xxwsh_order_headers_all.tightening_program_id%TYPE,       -- 締めコンカレントID
    corrected_tighten_class
        xxwsh_order_headers_all.corrected_tighten_class%TYPE,     -- 締め後修正区分
    order_line_id
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- 受注明細アドオンID
    order_line_number
        xxwsh_order_lines_all.order_line_number%TYPE,             -- 明細番号
    line_id
        xxwsh_order_lines_all.line_id%TYPE,                       -- 受注明細ID
    line_request_no
        xxwsh_order_lines_all.request_no%TYPE,                    -- 依頼No
    shipping_inventory_item_id
        xxwsh_order_lines_all.shipping_inventory_item_id%TYPE,    -- 出荷品目ID
    shipping_item_code
        xxwsh_order_lines_all.shipping_item_code%TYPE,            -- 出荷品目
    quantity
        xxwsh_order_lines_all.quantity%TYPE,                      -- 数量
    uom_code
        xxwsh_order_lines_all.uom_code%TYPE,                      -- 単位
    unit_price
        xxwsh_order_lines_all.unit_price%TYPE,                    -- 単価
    shipped_quantity
        xxwsh_order_lines_all.shipped_quantity%TYPE,              -- 出荷実績数量
    line_designated_prod_date
        xxwsh_order_lines_all.designated_production_date%TYPE,    -- 指定製造日
    based_request_quantity
        xxwsh_order_lines_all.based_request_quantity%TYPE,        -- 拠点依頼数量
    request_item_id
        xxwsh_order_lines_all.request_item_id%TYPE,               -- 依頼品目ID
    request_item_code
        xxwsh_order_lines_all.request_item_code%TYPE,             -- 依頼品目
    ship_to_quantity
        xxwsh_order_lines_all.ship_to_quantity%TYPE,              -- 入庫実績数量
    futai_code
        xxwsh_order_lines_all.futai_code%TYPE,                    -- 付帯コード
    designated_date
        xxwsh_order_lines_all.designated_date%TYPE,               -- 指定日付（リーフ）
    move_number
        xxwsh_order_lines_all.move_number%TYPE,                   -- 移動NO
    po_number
        xxwsh_order_lines_all.po_number%TYPE,                     -- 発注NO
    line_cust_po_number
        xxwsh_order_lines_all.cust_po_number%TYPE,                -- 顧客発注
    pallet_quantity
        xxwsh_order_lines_all.pallet_quantity%TYPE,               -- パレット数
    layer_quantity
        xxwsh_order_lines_all.layer_quantity%TYPE,                -- 段数
    case_quantity
        xxwsh_order_lines_all.case_quantity%TYPE,                 -- ケース数
    weight
        xxwsh_order_lines_all.weight%TYPE,                        -- 重量
    capacity
        xxwsh_order_lines_all.capacity%TYPE,                      -- 容積
    pallet_qty
        xxwsh_order_lines_all.pallet_qty%TYPE,                    -- パレット枚数
    pallet_weight
        xxwsh_order_lines_all.pallet_weight%TYPE,                 -- パレット重量
    reserved_quantity
        xxwsh_order_lines_all.reserved_quantity%TYPE,             -- 引当数
    automanual_reserve_class
        xxwsh_order_lines_all.automanual_reserve_class%TYPE,      -- 自動手動引当区分
    warning_class
        xxwsh_order_lines_all.warning_class%TYPE,                 -- 警告区分
    warning_date
        xxwsh_order_lines_all.warning_date%TYPE,                  -- 警告日付
    line_description
        xxwsh_order_lines_all.line_description%TYPE,              -- 摘要
    rm_if_flg
        xxwsh_order_lines_all.rm_if_flg%TYPE,                     -- 倉替返品インタフェース済フラグ
    shipping_request_if_flg
        xxwsh_order_lines_all.shipping_request_if_flg%TYPE,       -- 出荷依頼インタフェース済フラグ
    shipping_result_if_flg
        xxwsh_order_lines_all.shipping_result_if_flg%TYPE,        -- 出荷実績インタフェース済フラグ
    distribution_block
        xxcmn_item_locations_v.distribution_block%TYPE,           -- ブロック
    mtl_organization_id
        xxcmn_item_locations_v.mtl_organization_id%TYPE,          -- 在庫組織ID
    location_id
        xxcmn_item_locations_v.location_id%TYPE,                  -- 事業所ID
    subinventory_code
        xxcmn_item_locations_v.subinventory_code%TYPE,            -- 保管場所コード
    inventory_location_id
        xxcmn_item_locations_v.inventory_location_id%TYPE,        -- 倉庫ID
    cust_account_id
        xxcmn_cust_accounts_v.cust_account_id%TYPE,               -- 顧客ID
    lot_ctl
        xxcmn_item_mst_v.lot_ctl%TYPE                             -- ロット管理
  );
  -- 受注アドオン情報を格納する配列
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  -- API処理で使用する受注明細情報を格納するレコード
  TYPE order_line_rec IS RECORD(
    order_line_id 
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- 受注明細アドオンID
    line_id
        xxwsh_order_lines_all.line_id%TYPE,                       -- 受注明細ID
    shipped_quantity
        xxwsh_order_lines_all.shipped_quantity%TYPE,              -- 出荷実績数量
    uom_code
        xxwsh_order_lines_all.uom_code%TYPE,                      -- 単位
    shipping_inventory_item_id
        xxwsh_order_lines_all.shipping_inventory_item_id%TYPE,    -- 出荷品目ID
    header_id
        xxwsh_order_headers_all.header_id%TYPE,                   -- 受注ヘッダID
    deliver_from
        xxwsh_order_headers_all.deliver_from%TYPE,                -- 出荷元保管場所
    shipped_date
        xxwsh_order_headers_all.shipped_date%TYPE,                -- 出荷日
    location_id
        xxcmn_item_locations_v.location_id%TYPE,                  -- 事業所ID
    subinventory_code
        xxcmn_item_locations_v.subinventory_code%TYPE,            -- 保管場所コード
    mtl_organization_id
        xxcmn_item_locations_v.mtl_organization_id%TYPE,          -- 在庫組織ID
    inventory_location_id
        xxcmn_item_locations_v.inventory_location_id%TYPE,        -- 倉庫ID
    cust_account_id
        xxcmn_cust_accounts_v.cust_account_id%TYPE,               -- 顧客ID
    site_use_id
        hz_cust_site_uses_all.site_use_id%TYPE,                   -- 使用目的ID
    lot_ctl
        xxcmn_item_mst_v.lot_ctl%TYPE                             -- ロット管理
  );
  TYPE revised_line_rec IS RECORD(
    order_line_id 
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- 受注明細アドオンID
    new_order_line_id
        xxwsh_order_lines_all.order_line_id%TYPE                  -- 新受注明細アドオンID
  );
  -- API処理で使用する受注明細情報を格納する配列
  TYPE mov_line_id_type
      IS TABLE OF NUMBER
      INDEX BY PLS_INTEGER;    -- 移動明細格納用配列
  TYPE order_line_type
      IS TABLE OF order_line_rec
      INDEX BY PLS_INTEGER;    -- 受注明細格納用配列
  TYPE revised_line_type
      IS TABLE OF revised_line_rec
      INDEX BY PLS_INTEGER;    -- 訂正用受注明細格納用配列
  -- 在庫割当APIのパラメータを格納する配列
  TYPE ic_tran_rec_type           
      IS TABLE OF GMI_OM_ALLOC_API_PUB.IC_TRAN_REC_TYPE
      INDEX BY PLS_INTEGER;    -- 在庫割当API用配列
  -- 受入取引オープンインタフェースヘッダ登録用
  TYPE hi_header_inf_id_type      
      IS TABLE OF rcv_headers_interface.header_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- ヘッダインタフェースID
  TYPE hi_ex_receipt_date_type    
      IS TABLE OF rcv_headers_interface.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER; -- 受入日
  TYPE hi_ship_to_org_id_type    
      IS TABLE OF rcv_headers_interface.ship_to_organization_id%TYPE
      INDEX BY BINARY_INTEGER; -- 在庫組織ID
  TYPE hi_customer_id_type
      IS TABLE OF rcv_headers_interface.customer_id%TYPE
      INDEX BY BINARY_INTEGER; -- 顧客ID
  TYPE hi_customer_site_id_type
      IS TABLE OF rcv_headers_interface.customer_site_id%TYPE
      INDEX BY BINARY_INTEGER; -- 使用目的ID
  -- 受入取引オープンインタフェース明細登録用
  TYPE ti_header_inf_id_type      
      IS TABLE OF rcv_transactions_interface.header_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- ヘッダインタフェースID
  TYPE ti_ex_receipt_date_type    
      IS TABLE OF rcv_transactions_interface.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER; -- 受入日
  TYPE ti_transaction_date_type   
      IS TABLE OF rcv_transactions_interface.transaction_date%TYPE
      INDEX BY BINARY_INTEGER; -- 受入日
  TYPE ti_int_tran_id_type
      IS TABLE OF rcv_transactions_interface.interface_transaction_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受入取引インタフェースID
  TYPE ti_quantity_type           
      IS TABLE OF rcv_transactions_interface.quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 数量
  TYPE ti_unit_of_measure_type    
      IS TABLE OF rcv_transactions_interface.unit_of_measure%TYPE
      INDEX BY BINARY_INTEGER; -- 単位
  TYPE ti_item_id_type            
      IS TABLE OF rcv_transactions_interface.item_id%TYPE
      INDEX BY BINARY_INTEGER; -- 品目ID
  TYPE ti_subinventory_type       
      IS TABLE OF rcv_transactions_interface.subinventory%TYPE
      INDEX BY BINARY_INTEGER; -- 保管場所コード
  TYPE ti_locator_id_type
      IS TABLE OF rcv_transactions_interface.locator_id%TYPE
      INDEX BY BINARY_INTEGER; -- 倉庫ID
  TYPE ti_oe_order_header_id_type 
      IS TABLE OF rcv_transactions_interface.oe_order_header_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注ヘッダID
  TYPE ti_oe_order_line_id_type   
      IS TABLE OF rcv_transactions_interface.oe_order_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注明細ID
  TYPE ti_ship_to_location_id_type   
      IS TABLE OF rcv_transactions_interface.ship_to_location_id%TYPE
      INDEX BY BINARY_INTEGER; -- 事業所ID
  -- 受入取引オープンインタフェースロット登録用
  TYPE tl_tran_inter_id_type      
      IS TABLE OF mtl_transaction_lots_interface.transaction_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- ロットインタフェースID
  TYPE tl_lot_number_type         
      IS TABLE OF mtl_transaction_lots_interface.lot_number%TYPE
      INDEX BY BINARY_INTEGER; -- ロットNo
  TYPE tl_tran_quantity_type      
      IS TABLE OF mtl_transaction_lots_interface.transaction_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 数量
  TYPE tl_primary_quantity_type   
      IS TABLE OF mtl_transaction_lots_interface.primary_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 数量
  TYPE tl_product_tran_id_type    
      IS TABLE OF mtl_transaction_lots_interface.product_transaction_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受入取引インタフェースID
  -- 移動ロット詳細に登録する情報を格納するレコード(バルク処理用)
  TYPE ld_mov_lot_dtl_id_type     
      IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
      INDEX BY BINARY_INTEGER; -- ロット詳細ID
  TYPE ld_mov_line_id_type        
      IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- 明細ID
  TYPE ld_document_type_code_type 
      IS TABLE OF xxinv_mov_lot_details.document_type_code%TYPE
      INDEX BY BINARY_INTEGER; -- 文書タイプ
  TYPE ld_record_type_code_type   
      IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE
      INDEX BY BINARY_INTEGER; -- レコードタイプ
  TYPE ld_item_id_type            
      IS TABLE OF xxinv_mov_lot_details.item_id%TYPE
      INDEX BY BINARY_INTEGER; -- OPM品目ID
  TYPE ld_item_code_type          
      IS TABLE OF xxinv_mov_lot_details.item_code%TYPE
      INDEX BY BINARY_INTEGER; -- 品目
  TYPE ld_lot_id_type             
      IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE
      INDEX BY BINARY_INTEGER; -- ロットID
  TYPE ld_lot_no_type             
      IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE
      INDEX BY BINARY_INTEGER; -- ロットNo
  TYPE ld_actual_date_type        
      IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE
      INDEX BY BINARY_INTEGER; -- 実績日
  TYPE ld_actual_quantity_type    
      IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 実績数量
  TYPE ld_auto_reserve_class_type 
      IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE
      INDEX BY BINARY_INTEGER; -- 自動手動引当区分
  -- 受注明細アドオンの受注明細ID更新用レコード
  TYPE ol_order_line_id_type      
      IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注明細アドオンID
  TYPE ol_line_id_type            
      IS TABLE OF xxwsh_order_lines_all.line_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注明細ID
  -- 受注明細アドオンの赤登録用レコード(バルク処理用)
  TYPE ol_order_header_id_type    
      IS TABLE OF xxwsh_order_lines_all.order_header_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注ヘッダアドオンID
  TYPE ol_order_line_number_type  
      IS TABLE OF xxwsh_order_lines_all.order_line_number%TYPE
      INDEX BY BINARY_INTEGER; -- 明細番号
  TYPE ol_header_id_type          
      IS TABLE OF xxwsh_order_lines_all.header_id%TYPE
      INDEX BY BINARY_INTEGER; -- 受注ヘッダID
  TYPE ol_request_no_type         
      IS TABLE OF xxwsh_order_lines_all.request_no%TYPE
      INDEX BY BINARY_INTEGER; -- 依頼No
  TYPE ol_ship_inv_item_id_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_inventory_item_id%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷品目ID
  TYPE ol_ship_item_code_type     
      IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷品目
  TYPE ol_quantity_type           
      IS TABLE OF xxwsh_order_lines_all.quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 数量
  TYPE ol_uom_code_type           
      IS TABLE OF xxwsh_order_lines_all.uom_code%TYPE
      INDEX BY BINARY_INTEGER; -- 単位
  TYPE ol_unit_price_type         
      IS TABLE OF xxwsh_order_lines_all.unit_price%TYPE
      INDEX BY BINARY_INTEGER; -- 単価
  TYPE ol_shipped_quantity_type   
      IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷実績数量
  TYPE ol_desi_prod_date_type     
      IS TABLE OF xxwsh_order_lines_all.designated_production_date%TYPE
      INDEX BY BINARY_INTEGER; -- 指定製造日
  TYPE ol_base_req_quantity_type  
      IS TABLE OF xxwsh_order_lines_all.based_request_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 拠点依頼数量
  TYPE ol_request_item_id_type    
      IS TABLE OF xxwsh_order_lines_all.request_item_id%TYPE
      INDEX BY BINARY_INTEGER; -- 依頼品目ID
  TYPE ol_request_item_code_type  
      IS TABLE OF xxwsh_order_lines_all.request_item_code%TYPE
      INDEX BY BINARY_INTEGER; -- 依頼品目
  TYPE ol_ship_to_quantity_type   
      IS TABLE OF xxwsh_order_lines_all.ship_to_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 入庫実績数量
  TYPE ol_futai_code_type         
      IS TABLE OF xxwsh_order_lines_all.futai_code%TYPE
      INDEX BY BINARY_INTEGER; -- 付帯コード
  TYPE ol_designated_date_type    
      IS TABLE OF xxwsh_order_lines_all.designated_date%TYPE
      INDEX BY BINARY_INTEGER; -- 指定日付（リーフ）
  TYPE ol_move_number_type        
      IS TABLE OF xxwsh_order_lines_all.move_number%TYPE
      INDEX BY BINARY_INTEGER; -- 移動No
  TYPE ol_po_number_type          
      IS TABLE OF xxwsh_order_lines_all.po_number%TYPE
      INDEX BY BINARY_INTEGER; -- 発注No
  TYPE ol_cust_po_number_type     
      IS TABLE OF xxwsh_order_lines_all.cust_po_number%TYPE
      INDEX BY BINARY_INTEGER; -- 顧客発注
  TYPE ol_pallet_quantity_type    
      IS TABLE OF xxwsh_order_lines_all.pallet_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- パレット数
  TYPE ol_layer_quantity_type     
      IS TABLE OF xxwsh_order_lines_all.layer_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 段数
  TYPE ol_case_quantity_type      
      IS TABLE OF xxwsh_order_lines_all.case_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ケース数
  TYPE ol_weight_type             
      IS TABLE OF xxwsh_order_lines_all.weight%TYPE
      INDEX BY BINARY_INTEGER; -- 重量
  TYPE ol_capacity_type           
      IS TABLE OF xxwsh_order_lines_all.capacity%TYPE
      INDEX BY BINARY_INTEGER; -- 容積
  TYPE ol_pallet_qty_type         
      IS TABLE OF xxwsh_order_lines_all.pallet_qty%TYPE
      INDEX BY BINARY_INTEGER; -- パレット枚数
  TYPE ol_pallet_weight_type      
      IS TABLE OF xxwsh_order_lines_all.pallet_weight%TYPE
      INDEX BY BINARY_INTEGER; -- パレット重量
  TYPE ol_reserved_quantity_type  
      IS TABLE OF xxwsh_order_lines_all.reserved_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- 引当数
  TYPE ol_auto_rese_class_type    
      IS TABLE OF xxwsh_order_lines_all.automanual_reserve_class%TYPE
      INDEX BY BINARY_INTEGER; -- 自動手動引当区分
  TYPE ol_warning_class_type      
      IS TABLE OF xxwsh_order_lines_all.warning_class%TYPE
      INDEX BY BINARY_INTEGER; -- 警告区分
  TYPE ol_warning_date_type       
      IS TABLE OF xxwsh_order_lines_all.warning_date%TYPE
      INDEX BY BINARY_INTEGER; -- 警告日付
  TYPE ol_line_description_type   
      IS TABLE OF xxwsh_order_lines_all.line_description%TYPE
      INDEX BY BINARY_INTEGER; -- 摘要
  TYPE ol_rm_if_flg_type          
      IS TABLE OF xxwsh_order_lines_all.rm_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- 倉替返品インタフェース済フラグ
  TYPE ol_ship_requ_if_flg_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_request_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷依頼インタフェース済フラグ
  TYPE ol_ship_resu_if_flg_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_result_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷実績インタフェース済フラグ
-- 2009/04/08 H.Itou ADD START 本番障害#1356
  TYPE result_deliver_to_id_type
      IS TABLE OF xxwsh_order_headers_all.result_deliver_to_id%TYPE
      INDEX BY BINARY_INTEGER; -- 出荷先_実績ID
  TYPE customer_code_type
      IS TABLE OF xxwsh_order_headers_all.customer_code%TYPE
      INDEX BY BINARY_INTEGER; -- 顧客
-- 2009/04/08 H.Itou ADD END
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
  TYPE head_sales_branch_type
      IS TABLE OF xxwsh_order_headers_all.head_sales_branch%TYPE
      INDEX BY BINARY_INTEGER; -- 管轄拠点
-- 2009/04/21 H.Itou ADD END
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_new_order_cnt
      NUMBER;                                           -- 新規受注作成件数
  gn_upd_order_cnt
      NUMBER;                                           -- 訂正受注作成件数
  gn_cancell_cnt
      NUMBER;                                           -- 取消情報件数
  gn_input_cnt
      NUMBER;                                           -- 入力件数
  gn_error_cnt
      NUMBER;                                           -- エラー件数
  gn_org_id
      NUMBER;                                           -- 営業単位ID
  gt_return_reason_code
      oe_order_lines_all.return_reason_code%TYPE;       -- 返品事由
  gt_block
      fnd_lookup_values.lookup_code%TYPE;               -- ブロック
  gt_deliver_from
      xxwsh_order_headers_all.deliver_from%TYPE;        -- 出荷元保管場所
  gt_request_no
      xxwsh_order_headers_all.request_no%TYPE;          -- 依頼No
  -- 受入取引オープンインタフェースヘッダ登録用
  gt_header_interface_id
      hi_header_inf_id_type;                            -- ヘッダインタフェースID
  gt_expectied_receipt_date
      hi_ex_receipt_date_type;                          -- 受入日
  gt_ship_to_organization_id
      hi_ship_to_org_id_type;                           -- 在庫組織ID
  gt_customer_id
      hi_customer_id_type;                              -- 顧客ID
  gt_customer_site_id
      hi_customer_site_id_type;                         -- 使用目的ID
  -- 受入取引オープンインタフェース明細登録用
  gt_line_header_interface_id
      ti_header_inf_id_type;                            -- ヘッダインタフェースID
  gt_line_exp_receipt_date
      ti_ex_receipt_date_type;                          -- 受入日
  gt_transaction_date
      ti_transaction_date_type;                         -- 受入日
  gt_interface_transaction_id
      ti_int_tran_id_type;                              -- 受入取引インタフェースID
  gt_quantity
      ti_quantity_type;                                 -- 数量
  gt_unit_of_measure
      ti_unit_of_measure_type;                          -- 単位
  gt_ti_item_id
      ti_item_id_type;                                  -- 品目ID
  gt_subinventory
      ti_subinventory_type;                             -- 保管場所コード
  gt_oe_order_header_id
      ti_oe_order_header_id_type;                       -- 受注ヘッダID
  gt_oe_order_line_id
      ti_oe_order_line_id_type;                         -- 受注明細ID
  gt_ship_to_location_id
      ti_ship_to_location_id_type;                      -- 事業所ID
  gt_locator_id
      ti_locator_id_type;                               -- 倉庫ID
  -- 受入取引オープンインタフェースロット登録用
  gt_transaction_interface_id
      tl_tran_inter_id_type;                            -- ロットインタフェースID
  gt_lot_number
      tl_lot_number_type;                               -- ロットNo
  gt_transaction_quantity
      tl_tran_quantity_type;                            -- 数量
  gt_primary_quantity
      tl_primary_quantity_type;                         -- 数量
  gt_lot_prod_transaction_id
      tl_product_tran_id_type;                          -- 受入取引インタフェースID
  -- 移動ロット詳細(バルクINSERT用変数)
  gt_mov_lot_dtl_id
      ld_mov_lot_dtl_id_type;                           -- ロット詳細ID
  gt_mov_line_id
      ld_mov_line_id_type;                              -- 明細ID
  gt_document_type_code
      ld_document_type_code_type;                       -- 文書タイプ
  gt_record_type_code
      ld_record_type_code_type;                         -- レコードタイプ
  gt_item_id
      ld_item_id_type;                                  -- OPM品目ID
  gt_item_code
      ld_item_code_type;                                -- 品目
  gt_lot_id
      ld_lot_id_type;                                   -- ロットID
  gt_lot_no
      ld_lot_no_type;                                   -- ロットNo
  gt_actual_date
      ld_actual_date_type;                              -- 実績日
  gt_actual_quantity
      ld_actual_quantity_type;                          -- 実績数量
  gt_automanual_reserve_class
      ld_auto_reserve_class_type;                       -- 自動手動引当区分
  -- 受注明細アドオン受注明細ID更新用(バルクUPDATE用変数)
  gt_order_line_id
      ol_order_line_id_type;                            -- 受注明細アドオンID
  gt_line_id
      ol_line_id_type;                                  -- 受注明細ID
  -- 処理用変数
  gn_shori_count
      NUMBER;                                           -- A3取得データ現在位置判断用
  gn_lot_count
      NUMBER;                                           -- 移動ロット登録用件数
  gn_header_if_count
      NUMBER;                                           -- 受入取引オープンインタフェースヘッダ件数
  gn_tran_if_count
      NUMBER;                                           -- 受入取引オープンインタフェース明細件数
  gn_tran_lot_if_count
      NUMBER;                                           -- 受入取引オープンインタフェースロット件数
  gv_shori_kbn
      VARCHAR2(1);                                      -- 処理区分(1:新規登録受注,2:新規登録返品,
                                                        --          3:訂正受注,4:訂正返品)
  gt_gen_request_no
      xxwsh_order_headers_all.request_no%TYPE;          -- A3で取得し対象となっている依頼No
  gt_header_id
      xxwsh_order_headers_all.header_id%TYPE;           -- 受注ヘッダID(更新用)
  gt_gen_order_header_id
      xxwsh_order_headers_all.order_header_id%TYPE;     -- 受注ヘッダアドオンID(処理中)
  -- 標準API値保持用
  gn_req_id
      NUMBER;                                           -- 受入取引処理コンカレントID
  gn_group_id
      NUMBER;                                           -- 受入インターフェースグループID
  gv_error_flag
      VARCHAR2(1);                                      -- エラー判断フラグ
  gv_errbuf
      VARCHAR2(5000);                                   -- エラーメッセージ
  gv_errmsg
      VARCHAR2(5000);                                   -- ユーザー・エラー・メッセージ
  -- WHOカラム用変数
  gn_user_id
      NUMBER;                                           -- ログインしているユーザー
  gn_login_id
      NUMBER;                                           -- 最終更新ログイン
  gn_conc_request_id
      NUMBER;                                           -- 要求ID
  gn_prog_appl_id
      NUMBER;                                           -- プログラム・アプリケーションID
  gn_conc_program_id
      NUMBER;                                           -- コンカレント・プログラムID
-- Ver1.18 M.Hokkanji Start
  gn_upd_mov_lot_cnt
      NUMBER;                                           -- 対象の移動ロット詳細IDの件数
  gn_upd_mov_lot_dtl_id   ld_lot_id_type;               -- 移動ロット詳細更新用移動ロット詳細ID
-- Ver1.18 M.Hokkanji End
--
  /***********************************************************************************
   * Procedure Name   : input_param_check
   * Description      : A1入力パラメータチェック
   ***********************************************************************************/
  PROCEDURE input_param_check(
    iv_block        IN VARCHAR2,             -- ブロック
    iv_deliver_from IN VARCHAR2,             -- 出荷元
    iv_request_no   IN VARCHAR2,             -- 依頼No
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_param_check'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count NUMBER;           -- 存在チェック用件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***        ブロックの存在チェック         ***
    -- *********************************************
    IF (iv_block IS NOT NULL ) THEN
      SELECT COUNT(xlvv.lookup_code)
      INTO   ln_count
      FROM   xxcmn_lookup_values_v xlvv                      -- クイックコードVIEW
      WHERE  xlvv.lookup_type = gv_look_up_type_1
      AND    xlvv.lookup_code = iv_block
      AND    ROWNUM = 1;
      IF ( ln_count = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,  gv_msg_42a_017,
                                              gv_tkn_in_block, iv_block);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      gt_block := iv_block;
    END IF;
    -- *********************************************
    -- ***        出荷元存在チェック             ***
    -- *********************************************
    IF (iv_deliver_from IS NOT NULL ) THEN
      SELECT COUNT(xilv.mtl_organization_id)
      INTO   ln_count
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.segment1 = iv_deliver_from
      AND    ROWNUM = 1;
      IF ( ln_count = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,  gv_msg_42a_021,
                                              gv_tkn_in_shipf, iv_deliver_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      gt_deliver_from := iv_deliver_from;
    END IF;
    gt_request_no := iv_request_no;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END input_param_check;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : A2プロファイル値取得
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_org_id             NUMBER;                                     -- 営業単位ID
    lt_return_reason_code oe_order_lines_all.return_reason_code%TYPE; -- 返品事由
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***       営業単位ID取得            ***
    -- ***************************************
    ln_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_pfr_org_id));
--
    IF (ln_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42a_018,
                                            gv_tkn_prof_name, gv_pfr_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_org_id := ln_org_id; -- 営業単位IDをセット
--
    -- ***************************************
    -- ***       返品事由取得            ***
    -- ***************************************
    lt_return_reason_code := FND_PROFILE.VALUE(gv_pfr_return_reason);
--
    IF (lt_return_reason_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42a_018,
                                            gv_tkn_prof_name, gv_pfr_return_reason);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gt_return_reason_code := lt_return_reason_code; -- 返品事由をセット
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_profile;
-- 2009/04/08 H.Itou ADD START 本番障害#1356
  /***********************************************************************************
   * Procedure Name   : get_new_cust_data
   * Description      : 顧客マスタデータ最新取得(配送先番号で取得)
   ***********************************************************************************/
  PROCEDURE get_new_cust_data(
    it_party_site_number IN         xxcmn_cust_acct_sites_v.party_site_number%TYPE,   -- IN. 配送先番号
    ot_party_id          OUT NOCOPY xxcmn_cust_accounts_v.party_id           %TYPE,   -- OUT.パーティーID
    ot_cust_account_id   OUT NOCOPY xxcmn_cust_accounts_v.cust_account_id    %TYPE,   -- OUT.顧客ID
    ot_party_number      OUT NOCOPY xxcmn_cust_accounts_v.party_number       %TYPE,   -- OUT.顧客番号
    ot_party_site_id     OUT NOCOPY xxcmn_cust_acct_sites_v.party_site_id    %TYPE,   -- OUT.パーティーサイトID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
    ot_base_code         OUT NOCOPY xxcmn_cust_acct_sites_v.base_code        %TYPE,   -- OUT.拠点コード
-- 2009/04/21 H.Itou ADD END
    ov_errbuf            OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_new_cust_data(配送先番号で取得)'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    SELECT  xcav.party_id             party_id        -- 01.パーティーID
           ,xcav.cust_account_id      cust_account_id -- 02.顧客ID
           ,xcav.party_number         party_number    -- 03.顧客番号
           ,xcasv.party_site_id       party_site_id   -- 04.パーティーサイトID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
           ,xcasv.base_code           base_code       -- 05.拠点コード
-- 2009/04/21 H.Itou ADD END
    INTO    ot_party_id                               -- 01.party_id
           ,ot_cust_account_id                        -- 02.cust_account_id
           ,ot_party_number                           -- 03.party_number
           ,ot_party_site_id                          -- 04.party_site_id
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
           ,ot_base_code                              -- 05.base_code
-- 2009/04/21 H.Itou ADD END
-- 2009/11/05 H.Itou MOD START 本番障害#1648 顧客ステータスを見ずにデータを取得し、無効顧客の場合はAPIエラーとする。
--    FROM   xxcmn_cust_accounts_v      xcav            -- 顧客情報VIEW
    FROM   xxcmn_cust_accounts3_v     xcav            -- 顧客情報VIEW3
-- 2009/11/05 H.Itou MOD END
          ,xxcmn_cust_acct_sites_v    xcasv           -- 顧客サイト情報VIEW
    WHERE  xcav.party_id            = xcasv.party_id  -- 結合条件
    AND    xcasv.party_site_number  = it_party_site_number   -- 配送先番号
    AND    xcav.customer_class_code IN ('1','10')     -- 顧客区分
-- 2009/10/09 H.Itou Del Start 本番障害#1655 実績なので中止客でもエラーとしない。
--    AND    xcav.cust_enable_flag    = '0'             -- 中止客申請フラグ
-- 2009/10/09 H.Itou Del End
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_new_cust_data;
--
  /***********************************************************************************
   * Procedure Name   : get_new_cust_data
   * Description      : 顧客マスタデータ最新取得(顧客番号で取得)
   ***********************************************************************************/
  PROCEDURE get_new_cust_data(
    it_party_number    IN         xxcmn_cust_accounts_v.party_number   %TYPE,   -- IN. 顧客番号
    ot_party_id        OUT NOCOPY xxcmn_cust_accounts_v.party_id       %TYPE,   -- OUT.パーティーID
    ot_cust_account_id OUT NOCOPY xxcmn_cust_accounts_v.cust_account_id%TYPE,   -- OUT.顧客ID
    ot_party_number    OUT NOCOPY xxcmn_cust_accounts_v.party_number   %TYPE,   -- OUT.顧客番号
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_new_cust_data(顧客番号で取得)'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    SELECT  xcav.party_id             party_id        -- 01.パーティーID
           ,xcav.cust_account_id      cust_account_id -- 02.顧客ID
           ,xcav.party_number         party_number    -- 03.顧客番号
    INTO    ot_party_id                               -- 01.party_id
           ,ot_cust_account_id                        -- 02.cust_account_id
           ,ot_party_number                           -- 03.party_number
-- 2009/11/05 H.Itou MOD START 本番障害#1648 顧客ステータスを見ずにデータを取得し、無効顧客の場合はAPIエラーとする。
--    FROM   xxcmn_cust_accounts_v      xcav            -- 顧客情報VIEW
    FROM   xxcmn_cust_accounts3_v     xcav            -- 顧客情報VIEW3
-- 2009/11/05 H.Itou MOD END
    WHERE  xcav.party_number        = it_party_number -- 顧客番号
    AND    xcav.customer_class_code IN ('1','10')     -- 顧客区分
                                                      -- (中止客申請フラグは、ダミー顧客9999に設定がないので、条件に入れない)
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_new_cust_data;
-- 2009/04/08 H.Itou ADD END
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
  /***********************************************************************************
   * Procedure Name   : get_new_cust_site_data
   * Description      : 顧客サイトマスタデータ最新取得
   ***********************************************************************************/
  PROCEDURE get_new_cust_site_data(
    it_party_site_number IN         xxcmn_cust_acct_sites_v.party_site_number%TYPE,   -- IN. 配送先番号
    ot_party_site_id     OUT NOCOPY xxcmn_cust_acct_sites_v.party_site_id    %TYPE,   -- OUT.パーティーサイトID
    ov_errbuf            OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_new_cust_site_data'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    SELECT  xcasv.party_site_id        party_site_id   -- 01.パーティーサイトID
    INTO    ot_party_site_id                           -- 01.party_site_id
    FROM    xxcmn_cust_acct_sites_v    xcasv           -- 顧客サイト情報VIEW
    WHERE   xcasv.party_site_number  = it_party_site_number  -- 配送先番号
    ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_new_cust_site_data;
-- 2009/04/21 H.Itou ADD END
  /***********************************************************************************
   * Procedure Name   : get_order_info
   * Description      : A3受注アドオン情報取得
   ***********************************************************************************/
  PROCEDURE get_order_info(
    or_order_info_tbl  OUT NOCOPY order_tbl,    -- 受注アドオン情報格納用配列
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2008/09/01 Add ↓
    lv_select1          VARCHAR2(32000) DEFAULT NULL;
    lv_select2          VARCHAR2(32000) DEFAULT NULL;
    lv_select_where     VARCHAR2(32000) DEFAULT NULL;
    lv_select_lock      VARCHAR2(32000) DEFAULT NULL;
    lv_select_order     VARCHAR2(32000) DEFAULT NULL;
-- 2008/09/01 Add ↑
-- 2009/04/08 H.Itou ADD START 本番障害#1356
    lt_customer_id           xxcmn_cust_accounts_v.party_id       %TYPE;       -- 顧客ID(party_id)
    lt_cust_account_id       xxcmn_cust_accounts_v.cust_account_id%TYPE;       -- 顧客ID(cust_account_id)
    lt_customer_code         xxcmn_cust_accounts_v.party_number   %TYPE;       -- 顧客
    lt_result_deliver_to_id  xxcmn_cust_acct_sites_v.party_site_id%TYPE;       -- 出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
    lt_head_sales_branch     xxcmn_cust_acct_sites_v.base_code    %TYPE;       -- 管轄拠点
    lt_deliver_to_id         xxcmn_cust_acct_sites_v.party_site_id%TYPE;       -- 出荷先ID
-- 2009/04/21 H.Itou ADD END
--
    lr_new_customer_id           hi_customer_id_type;         -- 最新顧客ID
    lr_new_result_deliver_to_id  result_deliver_to_id_type;   -- 最新出荷先_実績ID
    lr_new_customer_code         customer_code_type;          -- 最新顧客
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
    lr_new_head_sales_branch     head_sales_branch_type;      -- 管轄拠点
    lr_new_deliver_to_id         result_deliver_to_id_type;   -- 最新出荷先ID
-- 2009/04/21 H.Itou ADD END
    lr_request_no                ol_request_no_type;          -- 依頼No
-- 2009/04/08 H.Itou ADD END
--
    -- *** ローカル・カーソル ***
-- 2008/09/01 Mod ↓
    TYPE   ref_cursor IS REF CURSOR ;
    cur_order_data ref_cursor ;
/*
--
    CURSOR cur_order_data IS
      SELECT xottv1.transaction_type_id,                                -- 受注タイプID
             xottv1.transaction_type_code,                              -- 受注タイプコード
             xottv1.order_category_code,                                -- 受注カテゴリ
             xottv1.shipping_shikyu_class,                              -- 出荷支給区分
             xoha.order_header_id,                                      -- 受注ヘッダアドオンID
             xoha.header_id,                                            -- 受注ヘッダID
             xoha.organization_id,                                      -- 組織ID
             xoha.ordered_date,                                         -- 受注日
             xoha.customer_id,                                          -- 顧客ID
             xoha.customer_code,                                        -- 顧客
             xoha.deliver_to_id,                                        -- 出荷先ID
             xoha.deliver_to,                                           -- 出荷先
             xoha.shipping_instructions,                                -- 出荷指示
             xoha.career_id,                                            -- 運送業者ID
             xoha.freight_carrier_code,                                 -- 運送業者
             xoha.shipping_method_code,                                 -- 配送区分
             xoha.cust_po_number,                                       -- 顧客発注
             xoha.price_list_id,                                        -- 価格表
             xoha.request_no,                                           -- 依頼NO
             xoha.req_status,                                           -- ステータス
             xoha.delivery_no,                                          -- 配送NO
             xoha.prev_delivery_no,                                     -- 前回配送NO
             xoha.schedule_ship_date,                                   -- 出荷予定日
             xoha.schedule_arrival_date,                                -- 着荷予定日
             xoha.mixed_no,                                             -- 混載元NO
             xoha.collected_pallet_qty,                                 -- パレット回収枚数
             xoha.confirm_request_class,                                -- 物流担当確認依頼区分
             xoha.freight_charge_class,                                 -- 運賃区分
             xoha.shikyu_instruction_class,                             -- 支給出庫指示区分
             xoha.shikyu_inst_rcv_class,                                -- 支給指示受領区分
             xoha.amount_fix_class,                                     -- 有償金額確定区分
             xoha.takeback_class,                                       -- 引取区分
             xoha.deliver_from_id,                                      -- 出荷元ID
             xoha.deliver_from,                                         -- 出荷元保管場所
             xoha.head_sales_branch,                                    -- 管轄拠点
             xoha.input_sales_branch,                                   -- 入力拠点
             xoha.po_no,                                                -- 発注NO
             xoha.prod_class,                                           -- 商品区分
             xoha.item_class,                                           -- 品目区分
             xoha.no_cont_freight_class,                                -- 契約外運賃区分
             xoha.arrival_time_from,                                    -- 着荷時間FROM
             xoha.arrival_time_to,                                      -- 着荷時間TO
             xoha.designated_item_id,                                   -- 製造品目ID
             xoha.designated_item_code,                                 -- 製造品目
             xoha.designated_production_date,                           -- 製造日
             xoha.designated_branch_no,                                 -- 製造枝番
             xoha.slip_number,                                          -- 送り状NO
             xoha.sum_quantity,                                         -- 合計数量
             xoha.small_quantity,                                       -- 小口個数
             xoha.label_quantity,                                       -- ラベル枚数
             xoha.loading_efficiency_weight,                            -- 重量積載効率
             xoha.loading_efficiency_capacity,                          -- 容積積載効率
             xoha.based_weight,                                         -- 基本重量
             xoha.based_capacity,                                       -- 基本容積
             xoha.sum_weight,                                           -- 積載重量合計
             xoha.sum_capacity,                                         -- 積載容積合計
             xoha.mixed_ratio,                                          -- 混載率
             xoha.pallet_sum_quantity,                                  -- パレット合計枚数
             xoha.real_pallet_quantity,                                 -- パレット実績枚数
             xoha.sum_pallet_weight,                                    -- 合計パレット重量
             xoha.order_source_ref,                                     -- 受注ソース参照
             xoha.result_freight_carrier_id,                            -- 運送業者_実績ID
             xoha.result_freight_carrier_code,                          -- 運送業者_実績
             xoha.result_shipping_method_code,                          -- 配送区分_実績
             xoha.result_deliver_to_id,                                 -- 出荷先_実績ID
             xoha.result_deliver_to,                                    -- 出荷先_実績
             xoha.shipped_date,                                         -- 出荷日
             xoha.arrival_date,                                         -- 着荷日
             xoha.weight_capacity_class,                                -- 重量容積区分
             xoha.notif_status,                                         -- 通知ステータス
             xoha.prev_notif_status,                                    -- 前回通知ステータス
             xoha.notif_date,                                           -- 確定通知実施日時
             xoha.new_modify_flg,                                       -- 新規修正フラグ
             xoha.process_status,                                       -- 処理経過ステータス
             xoha.performance_management_dept,                          -- 成績管理部署
             xoha.instruction_dept,                                     -- 指示部署
             xoha.transfer_location_id,                                 -- 振替先ID
             xoha.transfer_location_code,                               -- 振替先
             xoha.mixed_sign,                                           -- 混載記号
             xoha.screen_update_date,                                   -- 画面更新日時
             xoha.screen_update_by,                                     -- 画面更新者
             xoha.tightening_date,                                      -- 出荷依頼締め日時
             xoha.vendor_id,                                            -- 取引先ID
             xoha.vendor_code,                                          -- 取引先
             xoha.vendor_site_id,                                       -- 取引先サイトID
             xoha.vendor_site_code,                                     -- 取引先サイト
             xoha.registered_sequence,                                  -- 登録順序
             xoha.tightening_program_id,                                -- 締めコンカレントID
             xoha.corrected_tighten_class,                              -- 締め後修正区分
             xola.order_line_id,                                        -- 受注明細アドオンID
             xola.order_line_number,                                    -- 明細番号
             xola.line_id,                                              -- 受注明細ID
             xola.request_no line_request_no,                           -- 依頼No
             xola.shipping_inventory_item_id,                           -- 出荷品目ID
             xola.shipping_item_code,                                   -- 出荷品目
             xola.quantity,                                             -- 数量
             xola.uom_code,                                             -- 単位
             xola.unit_price,                                           -- 単価
             xola.shipped_quantity,                                     -- 出荷実績数量
             xola.designated_production_date line_designated_prod_date, -- 指定製造日
             xola.based_request_quantity,                               -- 拠点依頼数量
             xola.request_item_id,                                      -- 依頼品目ID
             xola.request_item_code,                                    -- 依頼品目
             xola.ship_to_quantity,                                     -- 入庫実績数量
             xola.futai_code,                                           -- 付帯コード
             xola.designated_date,                                      -- 指定日付（リーフ）
             xola.move_number,                                          -- 移動NO
             xola.po_number,                                            -- 発注NO
             xola.cust_po_number line_cust_po_number,                   -- 顧客発注
             xola.pallet_quantity,                                      -- パレット数
             xola.layer_quantity,                                       -- 段数
             xola.case_quantity,                                        -- ケース数
             xola.weight,                                               -- 重量
             xola.capacity,                                             -- 容積
             xola.pallet_qty,                                           -- パレット枚数
             xola.pallet_weight,                                        -- パレット重量
             xola.reserved_quantity,                                    -- 引当数
             xola.automanual_reserve_class,                             -- 自動手動引当区分
             xola.warning_class,                                        -- 警告区分
             xola.warning_date,                                         -- 警告日付
             xola.line_description,                                     -- 摘要
             xola.rm_if_flg,                                            -- 倉替返品IF済フラグ
             xola.shipping_request_if_flg,                              -- 出荷依頼IF済フラグ
             xola.shipping_result_if_flg,                               -- 出荷実績IF済フラグ
             xilv.distribution_block,                                   -- ブロック
             xilv.mtl_organization_id,                                  -- 在庫組織ID
             xilv.location_id,                                          -- 事業所ID
             xilv.subinventory_code,                                    -- 保管場所コード
             xilv.inventory_location_id,                                -- 倉庫ID
             xcav.cust_account_id,                                      -- 顧客ID
             ximv.lot_ctl                                               -- ロット管理
      FROM   xxwsh_order_headers_all xoha,                              -- 受注ヘッダアドオン
             xxwsh_order_lines_all xola,                                -- 受注明細アドオン
             xxwsh_oe_transaction_types_v xottv1,                       -- 受注タイプVIEW1
             xxcmn_item_locations_v xilv,                               -- OPM保管場所情報VIEW
             xxcmn_cust_accounts_v xcav,                                -- 顧客情報VIEW
             xxcmn_item_mst_v ximv                                      -- OPM品目情報VIEW
      WHERE  xoha.req_status IN (gv_order_status_04,gv_order_status_08)
      AND    xoha.request_no = NVL(gt_request_no,xoha.request_no)
      AND    xoha.deliver_from =  NVL(gt_deliver_from,xoha.deliver_from)
      AND    xilv.segment1 = xoha.deliver_from
      AND    xilv.distribution_block = NVL(gt_block,xilv.distribution_block)
      AND    NVL(xoha.actual_confirm_class,gv_no) = gv_no
      AND    (  (xoha.latest_external_flag = gv_yes)
              OR(xottv1.shipping_shikyu_class = gv_ship_class_3)
             )
      AND    xottv1.transaction_type_id = xoha.order_type_id
      AND    xcav.party_id = xoha.customer_id
      AND    xola.order_header_id = xoha.order_header_id
      AND    NVL(xola.delete_flag,gv_no) = gv_no
      AND    ximv.item_no  = xola.shipping_item_code
      FOR UPDATE OF xoha.order_header_id,xola.order_line_id NOWAIT
      ORDER BY xoha.request_no,xoha.order_header_id,xola.order_line_id;
*/
-- 2008/09/01 Mod ↑
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***       受注アドオン情報取得      ***
    -- ***************************************
-- 2008/09/01 Add ↓
    -- カーソル作成
    lv_select1 := 'SELECT xottv1.transaction_type_id,'                     -- 受注タイプID
        ||   ' xottv1.transaction_type_code,'                              -- 受注タイプコード
        ||   ' xottv1.order_category_code,'                                -- 受注カテゴリ
        ||   ' xottv1.shipping_shikyu_class,'                              -- 出荷支給区分
        ||   ' xoha.order_header_id,'                                      -- 受注ヘッダアドオンID
        ||   ' xoha.header_id,'                                            -- 受注ヘッダID
        ||   ' xoha.organization_id,'                                      -- 組織ID
        ||   ' xoha.ordered_date,'                                         -- 受注日
        ||   ' xoha.customer_id,'                                          -- 顧客ID
        ||   ' xoha.customer_code,'                                        -- 顧客
        ||   ' xoha.deliver_to_id,'                                        -- 出荷先ID
        ||   ' xoha.deliver_to,'                                           -- 出荷先
        ||   ' xoha.shipping_instructions,'                                -- 出荷指示
        ||   ' xoha.career_id,'                                            -- 運送業者ID
        ||   ' xoha.freight_carrier_code,'                                 -- 運送業者
        ||   ' xoha.shipping_method_code,'                                 -- 配送区分
        ||   ' xoha.cust_po_number,'                                       -- 顧客発注
        ||   ' xoha.price_list_id,'                                        -- 価格表
        ||   ' xoha.request_no,'                                           -- 依頼NO
        ||   ' xoha.req_status,'                                           -- ステータス
        ||   ' xoha.delivery_no,'                                          -- 配送NO
        ||   ' xoha.prev_delivery_no,'                                     -- 前回配送NO
        ||   ' xoha.schedule_ship_date,'                                   -- 出荷予定日
        ||   ' xoha.schedule_arrival_date,'                                -- 着荷予定日
        ||   ' xoha.mixed_no,'                                             -- 混載元NO
        ||   ' xoha.collected_pallet_qty,'                                 -- パレット回収枚数
        ||   ' xoha.confirm_request_class,'                                -- 物流担当確認依頼区分
        ||   ' xoha.freight_charge_class,'                                 -- 運賃区分
        ||   ' xoha.shikyu_instruction_class,'                             -- 支給出庫指示区分
        ||   ' xoha.shikyu_inst_rcv_class,'                                -- 支給指示受領区分
        ||   ' xoha.amount_fix_class,'                                     -- 有償金額確定区分
        ||   ' xoha.takeback_class,'                                       -- 引取区分
        ||   ' xoha.deliver_from_id,'                                      -- 出荷元ID
        ||   ' xoha.deliver_from,'                                         -- 出荷元保管場所
        ||   ' xoha.head_sales_branch,'                                    -- 管轄拠点
        ||   ' xoha.input_sales_branch,'                                   -- 入力拠点
        ||   ' xoha.po_no,'                                                -- 発注NO
        ||   ' xoha.prod_class,'                                           -- 商品区分
        ||   ' xoha.item_class,'                                           -- 品目区分
        ||   ' xoha.no_cont_freight_class,'                                -- 契約外運賃区分
        ||   ' xoha.arrival_time_from,'                                    -- 着荷時間FROM
        ||   ' xoha.arrival_time_to,'                                      -- 着荷時間TO
        ||   ' xoha.designated_item_id,'                                   -- 製造品目ID
        ||   ' xoha.designated_item_code,'                                 -- 製造品目
        ||   ' xoha.designated_production_date,'                           -- 製造日
        ||   ' xoha.designated_branch_no,'                                 -- 製造枝番
        ||   ' xoha.slip_number,'                                          -- 送り状NO
        ||   ' xoha.sum_quantity,'                                         -- 合計数量
        ||   ' xoha.small_quantity,'                                       -- 小口個数
        ||   ' xoha.label_quantity,'                                       -- ラベル枚数
        ||   ' xoha.loading_efficiency_weight,'                            -- 重量積載効率
        ||   ' xoha.loading_efficiency_capacity,'                          -- 容積積載効率
        ||   ' xoha.based_weight,'                                         -- 基本重量
        ||   ' xoha.based_capacity,'                                       -- 基本容積
        ||   ' xoha.sum_weight,'                                           -- 積載重量合計
        ||   ' xoha.sum_capacity,'                                         -- 積載容積合計
        ||   ' xoha.mixed_ratio,'                                          -- 混載率
        ||   ' xoha.pallet_sum_quantity,'                                  -- パレット合計枚数
        ||   ' xoha.real_pallet_quantity,'                                 -- パレット実績枚数
        ||   ' xoha.sum_pallet_weight,'                                    -- 合計パレット重量
        ||   ' xoha.order_source_ref,'                                     -- 受注ソース参照
        ||   ' xoha.result_freight_carrier_id,'                            -- 運送業者_実績ID
        ||   ' xoha.result_freight_carrier_code,'                          -- 運送業者_実績
        ||   ' xoha.result_shipping_method_code,'                          -- 配送区分_実績
        ||   ' xoha.result_deliver_to_id,'                                 -- 出荷先_実績ID
        ||   ' xoha.result_deliver_to,'                                    -- 出荷先_実績
        ||   ' xoha.shipped_date,'                                         -- 出荷日
        ||   ' xoha.arrival_date,'                                         -- 着荷日
        ||   ' xoha.weight_capacity_class,'                                -- 重量容積区分
        ||   ' xoha.notif_status,'                                         -- 通知ステータス
        ||   ' xoha.prev_notif_status,'                                    -- 前回通知ステータス
        ||   ' xoha.notif_date,'                                           -- 確定通知実施日時
        ||   ' xoha.new_modify_flg,'                                       -- 新規修正フラグ
        ||   ' xoha.process_status,'                                       -- 処理経過ステータス
        ||   ' xoha.performance_management_dept,'                          -- 成績管理部署
        ||   ' xoha.instruction_dept,'                                     -- 指示部署
        ||   ' xoha.transfer_location_id,'                                 -- 振替先ID
        ||   ' xoha.transfer_location_code,'                               -- 振替先
        ||   ' xoha.mixed_sign,'                                           -- 混載記号
        ||   ' xoha.screen_update_date,'                                   -- 画面更新日時
        ||   ' xoha.screen_update_by,'                                     -- 画面更新者
        ||   ' xoha.tightening_date,'                                      -- 出荷依頼締め日時
        ||   ' xoha.vendor_id,'                                            -- 取引先ID
        ||   ' xoha.vendor_code,'                                          -- 取引先
        ||   ' xoha.vendor_site_id,'                                       -- 取引先サイトID
        ||   ' xoha.vendor_site_code,'                                     -- 取引先サイト
        ||   ' xoha.registered_sequence,'                                  -- 登録順序
        ||   ' xoha.tightening_program_id,'                                -- 締めコンカレントID
        ||   ' xoha.corrected_tighten_class,'                              -- 締め後修正区分
        ||   ' xola.order_line_id,'                                        -- 受注明細アドオンID
        ||   ' xola.order_line_number,'                                    -- 明細番号
        ||   ' xola.line_id,'                                              -- 受注明細ID
        ||   ' xola.request_no line_request_no,'                           -- 依頼No
        ||   ' xola.shipping_inventory_item_id,'                           -- 出荷品目ID
        ||   ' xola.shipping_item_code,'                                   -- 出荷品目
        ||   ' xola.quantity,'                                             -- 数量
        ||   ' xola.uom_code,'                                             -- 単位
        ||   ' xola.unit_price,'                                           -- 単価
        ||   ' xola.shipped_quantity,'                                     -- 出荷実績数量
        ||   ' xola.designated_production_date line_designated_prod_date,' -- 指定製造日
        ||   ' xola.based_request_quantity,'                               -- 拠点依頼数量
        ||   ' xola.request_item_id,'                                      -- 依頼品目ID
        ||   ' xola.request_item_code,'                                    -- 依頼品目
        ||   ' xola.ship_to_quantity,'                                     -- 入庫実績数量
        ||   ' xola.futai_code,'                                           -- 付帯コード
        ||   ' xola.designated_date,'                                      -- 指定日付（リーフ）
        ||   ' xola.move_number,'                                          -- 移動NO
        ||   ' xola.po_number,'                                            -- 発注NO
        ||   ' xola.cust_po_number line_cust_po_number,'                   -- 顧客発注
        ||   ' xola.pallet_quantity,'                                      -- パレット数
        ||   ' xola.layer_quantity,'                                       -- 段数
        ||   ' xola.case_quantity,'                                        -- ケース数
        ||   ' xola.weight,'                                               -- 重量
        ||   ' xola.capacity,'                                             -- 容積
        ||   ' xola.pallet_qty,'                                           -- パレット枚数
        ||   ' xola.pallet_weight,'                                        -- パレット重量
        ||   ' xola.reserved_quantity,'                                    -- 引当数
        ||   ' xola.automanual_reserve_class,'                             -- 自動手動引当区分
        ||   ' xola.warning_class,'                                        -- 警告区分
        ||   ' xola.warning_date,'                                         -- 警告日付
        ||   ' xola.line_description,'                                     -- 摘要
        ||   ' xola.rm_if_flg,'                                            -- 倉替返品IF済フラグ
        ||   ' xola.shipping_request_if_flg,'                              -- 出荷依頼IF済フラグ
        ||   ' xola.shipping_result_if_flg,'                               -- 出荷実績IF済フラグ
        ||   ' xilv.distribution_block,'                                   -- ブロック
        ||   ' xilv.mtl_organization_id,'                                  -- 在庫組織ID
        ||   ' xilv.location_id,'                                          -- 事業所ID
        ||   ' xilv.subinventory_code,'                                    -- 保管場所コード
        ||   ' xilv.inventory_location_id,'                                -- 倉庫ID
-- 2009/11/05 H.Itou MOD START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは取得しない。
--        ||   ' xcav.cust_account_id,'                                      -- 顧客ID
        ||   ' NULL cust_account_id,'
-- 2009/11/05 H.Itou MOD END
        ||   ' ximv.lot_ctl'                                               -- ロット管理
        ||' FROM   xxwsh_order_headers_all     xoha,'                      -- 受注ヘッダアドオン
        ||   '       xxwsh_order_lines_all        xola,'                   -- 受注明細アドオン
        ||   '       xxwsh_oe_transaction_types_v xottv1,'                 -- 受注タイプVIEW1
        ||   '       xxcmn_item_locations_v       xilv,'                   -- OPM保管場所情報VIEW
-- 2009/11/05 H.Itou DEL START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは結合不要。
--        ||   '       xxcmn_cust_accounts_v        xcav,'                   -- 顧客情報VIEW
-- 2009/11/05 H.Itou DEL END
        ||   '       xxcmn_item_mst_v             ximv';                   -- OPM品目情報VIEW
--
    lv_select_where := ' WHERE  xottv1.transaction_type_id = xoha.order_type_id'
-- 2009/11/05 H.Itou DEL START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは結合不要。
--        ||   ' AND    xcav.party_id = xoha.customer_id'
-- 2009/11/05 H.Itou DEL END
        ||   ' AND    xola.order_header_id = xoha.order_header_id'
        ||   ' AND    xilv.segment1 = xoha.deliver_from'
        ||   ' AND    ximv.item_no  = xola.shipping_item_code'
        ||   ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||   ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||   ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))'
        ||   ' AND    NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||   ' AND    xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')';
--
    -- 依頼No
    IF (gt_request_no IS NOT NULL) THEN
      lv_select_where := lv_select_where
          || ' AND    xoha.request_no = ''' || gt_request_no || '''';
    END IF;
--
    -- 出荷元保管場所
    IF (gt_deliver_from IS NOT NULL) THEN
      lv_select_where := lv_select_where
--2008/12/24 D.Sugahara Mod Start
--          || ' AND    xoha.deliver_from =  ''' || gt_deliver_from || '''';
          || ' AND    xoha.deliver_from_id = xilv.inventory_location_id '
          || ' AND    xilv.segment1        =  ''' || gt_deliver_from || '''';
    END IF;
--2008/12/24 D.Sugahara Mod End    
--
    -- ブロック
    IF (gt_block IS NOT NULL) THEN
      lv_select_where := lv_select_where
          || ' AND    xilv.distribution_block = ''' || gt_block || '''';
    END IF;
--
    lv_select_lock  := ' FOR UPDATE OF xoha.order_header_id,xola.order_line_id NOWAIT';
    lv_select_order := ' ORDER BY xoha.request_no,xoha.order_header_id,xola.order_line_id';
-- 2008/09/01 Add ↑
    -- カーソルオープン
    BEGIN
-- 2008/09/01 Mod ↓
/*
      OPEN cur_order_data;
*/
      OPEN cur_order_data FOR lv_select1 || lv_select_where || lv_select_lock || lv_select_order;
-- 2008/09/01 Mod ↑
      -- バルクフェッチ
      FETCH cur_order_data BULK COLLECT INTO or_order_info_tbl ;
      -- カーソルクローズ
      CLOSE cur_order_data ;
    EXCEPTION
      WHEN lock_error_expt THEN -- ロックエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_019
        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2008/09/01 Mod ↓
/*
    -- 依頼No単位の件数を取得(A3の件数は明細単位のため)
    SELECT COUNT(xoha.request_no)
    INTO   gn_input_cnt
    FROM   xxwsh_order_headers_all xoha,                              -- 受注ヘッダアドオン
           xxwsh_oe_transaction_types_v xottv1,                       -- 受注タイプVIEW1
           xxcmn_item_locations_v xilv                                -- OPM保管場所情報VIEW
    WHERE  xoha.req_status IN (gv_order_status_04,gv_order_status_08)
    AND    xoha.request_no = NVL(gt_request_no,xoha.request_no)
    AND    xoha.deliver_from = NVL(gt_deliver_from,xoha.deliver_from)
    AND    xilv.segment1 = xoha.deliver_from
    AND    xilv.distribution_block = NVL(gt_block,xilv.distribution_block)
    AND    NVL(xoha.actual_confirm_class,gv_no) = gv_no
    AND    (  (xoha.latest_external_flag = gv_yes)
            OR(xottv1.shipping_shikyu_class = gv_ship_class_3)
           )
    AND    xottv1.transaction_type_id = xoha.order_type_id
    AND EXISTS (
        SELECT xola.order_header_id
        FROM   xxwsh_order_lines_all xola,                                -- 受注明細アドオン
               xxcmn_item_mst_v ximv                                      -- OPM品目情報VIEW
        WHERE xola.order_header_id = xoha.order_header_id
        AND   NVL(xola.delete_flag,gv_no) = gv_no
        AND   ximv.item_no  = xola.shipping_item_code
    );
*/
    lv_select2 := 'SELECT COUNT(xoha.request_no)'
        ||       ' FROM   xxwsh_order_headers_all      xoha,'
        ||       '       xxwsh_oe_transaction_types_v  xottv1,'
        ||       '       xxcmn_item_locations_v        xilv'
        ||       ' WHERE  xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')'
        ||       ' AND    xilv.segment1 = xoha.deliver_from'
        ||       ' AND    xottv1.transaction_type_id = xoha.order_type_id'
        ||       ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||       ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))';
--
    -- 依頼No
    IF (gt_request_no IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xoha.request_no = ''' || gt_request_no || '''';
    END IF;
--
    -- 出荷元保管場所
    IF (gt_deliver_from IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xoha.deliver_from = ''' || gt_deliver_from || '''';
    END IF;
--
    -- ブロック
    IF (gt_block IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xilv.distribution_block = ''' || gt_block || '''';
    END IF;
--
    lv_select2 := lv_select2 
        ||       ' AND EXISTS ('
        ||       ' SELECT xola.order_header_id'
        ||       ' FROM   xxwsh_order_lines_all xola,'
        ||       '        xxcmn_item_mst_v      ximv'
        ||       ' WHERE xola.order_header_id = xoha.order_header_id'
        ||       ' AND   NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND   ximv.item_no  = xola.shipping_item_code )';
--
    EXECUTE IMMEDIATE lv_select2 INTO gn_input_cnt;
-- 2008/09/01 Mod ↑
-- 2009/04/08 H.Itou ADD START 本番障害#1356 最新の顧客データでないと、標準APIでエラーになるので、最新マスタデータを取得
    <<change_new_cust_loop>>
-- 2009/04/14 MOD START 本番障害#1406 データが0件のときに落ちるので修正
--    FOR i IN or_order_info_tbl.FIRST..or_order_info_tbl.LAST LOOP
    FOR i IN 1..or_order_info_tbl.COUNT LOOP
-- 2009/04/14 MOD END
      -- ======================================
      -- 顧客情報洗い替え処理
      -- ======================================
      -- 依頼Noがブレイクした時に、顧客マスタを検索
      IF  ((or_order_info_tbl.FIRST = i)
        OR (or_order_info_tbl(i-1).request_no <> or_order_info_tbl(i).request_no)) THEN
--
        -- 変数初期化
        lt_customer_id          := NULL;   -- 顧客ID(party_id)
        lt_cust_account_id      := NULL;   -- 顧客ID(cust_account_id)
        lt_customer_code        := NULL;   -- 顧客
        lt_result_deliver_to_id := NULL;   -- 出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
        lt_head_sales_branch    := NULL;   -- 管轄拠点
        lt_deliver_to_id        := NULL;   -- 出荷先ID
-- 2009/04/21 H.Itou ADD END
--
        -- 支給の場合
        IF (or_order_info_tbl(i).shipping_shikyu_class = gv_ship_class_2) THEN
--
          -- 顧客番号で最新顧客データ取得
          get_new_cust_data(
            it_party_number    => or_order_info_tbl(i).customer_code,     -- IN. 顧客
            ot_party_id        => lt_customer_id,                         -- OUT.顧客ID(party_id)
            ot_cust_account_id => lt_cust_account_id,                     -- OUT.顧客ID(cust_account_id)
            ot_party_number    => lt_customer_code,                       -- OUT.顧客
            ov_errbuf          => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
            ov_retcode         => lv_retcode,   -- リターン・コード             --# 固定 #
            ov_errmsg          => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
           );
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- エラー終了
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 支給では以下の項目はNULLなので、最新取得なしなので、DBの値(NULL)をセット
          lt_result_deliver_to_id := or_order_info_tbl(i).result_deliver_to_id; -- 最新出荷先_実績ID
          lt_deliver_to_id        := or_order_info_tbl(i).deliver_to_id;        -- 最新出荷先_指示ID
          lt_head_sales_branch    := or_order_info_tbl(i).head_sales_branch;    -- 管轄拠点
-- 2009/04/21 H.Itou ADD END
--
        -- 出荷・倉替返品の場合
        ELSE
--
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- 指示ありの場合
          IF (or_order_info_tbl(i).deliver_to IS NOT NULL) THEN
            -- 出荷先_指示コードで出荷先_指示IDを取得
            get_new_cust_site_data(
              it_party_site_number => or_order_info_tbl(i).deliver_to,        -- IN. 出荷先_指示
              ot_party_site_id     => lt_deliver_to_id,                       -- OUT.出荷先_指示ID
              ov_errbuf            => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
              ov_retcode           => lv_retcode,   -- リターン・コード             --# 固定 #
              ov_errmsg            => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
             );
--
            -- エラー終了
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
--
-- 2009/04/21 H.Itou ADD END
          -- 出荷先_実績コードで最新顧客、出荷先_実績ID、管轄拠点を取得
          get_new_cust_data(
            it_party_site_number => or_order_info_tbl(i).result_deliver_to, -- IN. 出荷先_実績
            ot_party_id          => lt_customer_id,                         -- OUT.顧客ID(party_id)
            ot_cust_account_id   => lt_cust_account_id,                     -- OUT.顧客ID(cust_account_id)
            ot_party_number      => lt_customer_code,                       -- OUT.顧客
            ot_party_site_id     => lt_result_deliver_to_id,                -- OUT.出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
            ot_base_code         => lt_head_sales_branch,                   -- OUT.管轄拠点
-- 2009/04/21 H.Itou ADD END
            ov_errbuf            => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
            ov_retcode           => lv_retcode,   -- リターン・コード             --# 固定 #
            ov_errmsg            => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
           );
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- エラー終了
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
-- 2009/04/21 H.Itou ADD END
--
        END IF;
--
-- 2009/04/21 H.Itou DEL START 本番障害#1356(再対応)
--        -- エラー終了
--        IF (lv_retcode <> gv_status_normal) THEN
--          RAISE check_sub_main_expt;
--        END IF;
-- 2009/04/21 H.Itou DEL END
--
        -- 更新用にデータを保持
        lr_new_customer_id         (lr_request_no.COUNT + 1) := lt_customer_id;                  -- 最新顧客ID
        lr_new_result_deliver_to_id(lr_request_no.COUNT + 1) := lt_result_deliver_to_id;         -- 最新出荷先_実績ID
        lr_new_customer_code       (lr_request_no.COUNT + 1) := lt_customer_code;                -- 最新顧客
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
        lr_new_head_sales_branch   (lr_request_no.COUNT + 1) := lt_head_sales_branch;            -- 最新管轄拠点
        lr_new_deliver_to_id       (lr_request_no.COUNT + 1) := lt_deliver_to_id;                -- 最新出荷先_指示ID
-- 2009/04/21 H.Itou ADD END
        lr_request_no              (lr_request_no.COUNT + 1) := or_order_info_tbl(i).request_no; -- 依頼No
--
      END IF;
--
      -- 最新情報に洗い替え
      or_order_info_tbl(i).customer_id          := lt_customer_id;          -- 顧客ID(party_id)
      or_order_info_tbl(i).cust_account_id      := lt_cust_account_id;      -- 顧客ID(cust_account_id)
      or_order_info_tbl(i).customer_code        := lt_customer_code;        -- 顧客
      or_order_info_tbl(i).result_deliver_to_id := lt_result_deliver_to_id; -- 出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
      or_order_info_tbl(i).head_sales_branch    := lt_head_sales_branch;    -- 最新管轄拠点
      or_order_info_tbl(i).deliver_to_id        := lt_deliver_to_id;        -- 最新出荷先_指示ID
-- 2009/04/21 H.Itou ADD END
    END LOOP change_new_cust_loop;
--
    -- 受注ヘッダの顧客を最新に更新
    FORALL i IN 1 .. lr_request_no.COUNT
      UPDATE xxwsh_order_headers_all xoha
      SET    xoha.customer_id            = lr_new_customer_id(i)           -- 顧客ID(party_id)
            ,xoha.customer_code          = lr_new_customer_code(i)         -- 顧客
            ,xoha.result_deliver_to_id   = lr_new_result_deliver_to_id(i)  -- 出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
            ,xoha.head_sales_branch      = lr_new_head_sales_branch(i)     -- 管轄拠点
            ,xoha.deliver_to_id          = lr_new_deliver_to_id(i)         -- 出荷先_指示ID
-- 2009/04/21 H.Itou ADD END
            ,xoha.last_updated_by        = gn_user_id                      -- 最終更新者
            ,xoha.last_update_date       = SYSDATE                         -- 最終更新日
            ,xoha.last_update_login      = gn_login_id                     -- 最終更新ログイン
            ,xoha.request_id             = gn_conc_request_id              -- 要求ID
            ,xoha.program_application_id = gn_prog_appl_id                 -- コンカレント・プログラム・アプリケーションID
            ,xoha.program_id             = gn_conc_program_id              -- コンカレント・プログラムID
            ,xoha.program_update_date    = SYSDATE                         -- プログラム更新日
      WHERE  xoha.request_no                     = lr_request_no(i)        -- 依頼No
      AND    NVL(xoha.actual_confirm_class, 'N') = 'N'                     -- 実績計上済フラグがNのデータの顧客を変更する。
      ;
-- 2009/04/08 H.Itou ADD END
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_order_info;
  /***********************************************************************************
   * Procedure Name   : get_same_request_number
   * Description      : A4同一依頼No検索処理
   ***********************************************************************************/
  PROCEDURE get_same_request_number(
    it_request_no
        IN  xxwsh_order_headers_all.request_no%TYPE,            -- 同一依頼No
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    it_order_type_id
        IN  xxwsh_order_headers_all.order_type_id%TYPE,         -- 受注タイプID
-- 2008/12/13 v1.8 D.Nihei Add End
    on_same_request_no
        OUT NOCOPY NUMBER,                                      -- 同一依頼No件数
    ot_old_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE,-- 受注ヘッダアドオンID(OLD)
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                    -- エラー・メッセージ --# 固定 #
    ov_retcode
        OUT NOCOPY VARCHAR2,                                    -- リターン・コード   --# 固定 #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                    -- ユーザエラーメッセージ--# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_same_request_number'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    cv_cancel               CONSTANT VARCHAR2(2)   := '99';                    --取消
    cv_get_err              CONSTANT VARCHAR2(100) := 'APP-XXWSH-10013';     -- 取得エラー
    cv_msg_kbn              CONSTANT VARCHAR2(5)   := 'XXWSH';               -- 出荷
    cv_tkn_table            CONSTANT VARCHAR2(20)  := 'TABLE';               -- TABLE
    cv_xoha                 CONSTANT VARCHAR2(100) := '受注ヘッダアドオン';
    cv_tkn_type             CONSTANT VARCHAR2(20)  := 'TYPE';                -- TYPE
    cv_tkn_no_type          CONSTANT VARCHAR2(20)  := 'NO_TYPE';             -- NO_TYPE
    cv_request_no           CONSTANT VARCHAR2(10)  := '依頼No';
    cv_tkn_request_no       CONSTANT VARCHAR2(20)  := 'REQUEST_NO';          -- REQUEST_NO
    cv_log_level            CONSTANT VARCHAR2(1)   := '6';                   -- ログレベル
    cv_colon                CONSTANT VARCHAR2(1)   := ':';                   -- コロン
-- 2008/12/13 v1.8 D.Nihei Add End
--
    -- *** ローカル変数 ***
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    lv_except_msg          VARCHAR2(200);                               -- エラーメッセージ
-- 2008/12/13 v1.8 D.Nihei Add End
    ln_return_code         NUMBER;                                      -- 関数戻り値
    ln_same_request_no     NUMBER;                                      -- 同一依頼No件数
    lt_old_order_header_id xxwsh_order_headers_all.order_header_id%TYPE;-- ヘッダアドオンID(OLD)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    user_expt             EXCEPTION;     -- ユーザ定義エラー
-- 2008/12/13 v1.8 D.Nihei Add End
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
-- 2008/12/13 v1.8 D.Nihei Del Start 本番障害#568対応
--    ln_return_code := xxwsh_common_pkg.get_same_request_number(
--                        it_request_no,
--                        ln_same_request_no,    -- 同一依頼No件数
--                        lt_old_order_header_id -- 受注ヘッダアドオンID(OLD)
--    );
--    IF (ln_return_code <> gv_status_normal) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg(
--                     gv_msg_kbn_wsh,
--                     gv_msg_42a_022,
--                     gv_tkn_request_no,
--                     it_request_no
--      );
--      RAISE global_api_expt;
--    END IF;
--    on_same_request_no     := ln_same_request_no;     -- 同一依頼No件数
--    ot_old_order_header_id := lt_old_order_header_id; -- 受注ヘッダアドオンID(OLD)
-- 2008/12/13 v1.8 D.Nihei Del End
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    -- 入力パラメータチェック
    IF ( it_request_no IS NULL ) THEN
      RAISE user_expt;
    END IF;
--
    -- 同一依頼Noの件数カウント
    SELECT COUNT(1)
    INTO   on_same_request_no
    FROM   xxwsh_order_headers_all  xoha
    WHERE  xoha.req_status  <> cv_cancel
    AND    xoha.order_type_id = it_order_type_id
    AND    xoha.request_no  =  it_request_no
    ;
--
    IF ( on_same_request_no > 1 ) THEN
--
      BEGIN
        -- 同一依頼Noの受注ヘッダアドオンID取得
        SELECT MAX(xoha.order_header_id)
        INTO   ot_old_order_header_id
        FROM   xxwsh_order_headers_all  xoha
        WHERE  xoha.order_type_id = it_order_type_id
        AND    xoha.request_no    = it_request_no
        AND    xoha.req_status    IN('04', '08')  --出荷(04)と支給(08)実績計上済
        AND    NVL(xoha.latest_external_flag, 'N')   <> 'Y'
        AND    NVL(xoha.actual_confirm_class, 'N')   =  'Y'
        ;
--
        IF ( ot_old_order_header_id IS NULL ) THEN
          RAISE user_expt;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE user_expt;
--
      END;
--
    ELSIF ( on_same_request_no = 1 ) THEN
--
      BEGIN
--
        SELECT xoha.order_header_id
        INTO   ot_old_order_header_id
        FROM   xxwsh_order_headers_all  xoha
        WHERE  xoha.req_status    <> cv_cancel
        AND    xoha.order_type_id  = it_order_type_id
        AND    xoha.request_no     =  it_request_no
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_except_msg := xxcmn_common_pkg.get_msg(cv_msg_kbn        , cv_get_err,
                                                    cv_tkn_table      , cv_xoha,
                                                    cv_tkn_type       , NULL,
                                                    cv_tkn_no_type    , NULL,
                                                    cv_tkn_request_no , it_request_no);
          FND_LOG.STRING(cv_log_level, gv_pkg_name
                        || cv_colon
                        || cv_prg_name, lv_except_msg);
          RAISE global_api_expt;
      END;
--
    ELSE
      -- 指定した依頼Noは存在しません。
      RAISE user_expt;
    END IF;
-- 2008/12/13 v1.8 D.Nihei Add End
  EXCEPTION
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
    WHEN user_expt THEN -- ユーザ定義エラー
      ov_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh
                                          , gv_msg_42a_022
                                          , gv_tkn_request_no
                                          , it_request_no);
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
-- 2008/12/13 v1.8 D.Nihei Add End
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_same_request_number;
  /***********************************************************************************
   * Procedure Name   : get_revised order_info
   * Description      : A5訂正前受注ヘッダアドオン情報取得
   ***********************************************************************************/
  PROCEDURE get_revised_order_info(
    it_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- 訂正前受注ヘッダアドオンID
    or_order_info_tbl
        OUT NOCOPY order_tbl,                            -- 受注アドオン情報格納用配列
    ov_errbuf
        OUT NOCOPY VARCHAR2,                             -- エラー・メッセージ           --# 固定 #
    ov_retcode
        OUT NOCOPY VARCHAR2,                             -- リターン・コード             --# 固定 #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_revised_order_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
-- 2009/04/08 H.Itou ADD START 本番障害#1356
    lt_customer_id           xxcmn_cust_accounts_v.party_id       %TYPE;       -- 顧客ID(party_id)
    lt_cust_account_id       xxcmn_cust_accounts_v.cust_account_id%TYPE;       -- 顧客ID(cust_account_id)
    lt_customer_code         xxcmn_cust_accounts_v.party_number   %TYPE;       -- 顧客
    lt_result_deliver_to_id  xxcmn_cust_acct_sites_v.party_site_id%TYPE;       -- 出荷先_実績ID
-- 2009/04/08 H.Itou ADD END
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
    lt_head_sales_branch     xxcmn_cust_acct_sites_v.base_code    %TYPE;       -- 管轄拠点
    lt_deliver_to_id         xxcmn_cust_acct_sites_v.party_site_id%TYPE;       -- 出荷先ID
-- 2009/04/21 H.Itou ADD END
--
    -- *** ローカル・カーソル ***
--
    CURSOR cur_order_data IS
      SELECT xottv2.transaction_type_id,                                -- 受注タイプID
             xottv2.transaction_type_code,                              -- 受注タイプコード
             xottv2.order_category_code,                                -- 受注カテゴリ
             xottv2.shipping_shikyu_class,                              -- 出荷支給区分
             xoha.order_header_id,                                      -- 受注ヘッダアドオンID
             xoha.header_id,                                            -- 受注ヘッダID
             xoha.organization_id,                                      -- 組織ID
             xoha.ordered_date,                                         -- 受注日
             xoha.customer_id,                                          -- 顧客ID
             xoha.customer_code,                                        -- 顧客
             xoha.deliver_to_id,                                        -- 出荷先ID
             xoha.deliver_to,                                           -- 出荷先
             xoha.shipping_instructions,                                -- 出荷指示
             xoha.career_id,                                            -- 運送業者ID
             xoha.freight_carrier_code,                                 -- 運送業者
             xoha.shipping_method_code,                                 -- 配送区分
             xoha.cust_po_number,                                       -- 顧客発注
             xoha.price_list_id,                                        -- 価格表
             xoha.request_no,                                           -- 依頼NO
             xoha.req_status,                                           -- ステータス
             xoha.delivery_no,                                          -- 配送NO
             xoha.prev_delivery_no,                                     -- 前回配送NO
             xoha.schedule_ship_date,                                   -- 出荷予定日
             xoha.schedule_arrival_date,                                -- 着荷予定日
             xoha.mixed_no,                                             -- 混載元NO
             xoha.collected_pallet_qty,                                 -- パレット回収枚数
             xoha.confirm_request_class,                                -- 物流担当確認依頼区分
             xoha.freight_charge_class,                                 -- 運賃区分
             xoha.shikyu_instruction_class,                             -- 支給出庫指示区分
             xoha.shikyu_inst_rcv_class,                                -- 支給指示受領区分
             xoha.amount_fix_class,                                     -- 有償金額確定区分
             xoha.takeback_class,                                       -- 引取区分
             xoha.deliver_from_id,                                      -- 出荷元ID
             xoha.deliver_from,                                         -- 出荷元保管場所
             xoha.head_sales_branch,                                    -- 管轄拠点
             xoha.input_sales_branch,                                   -- 入力拠点
             xoha.po_no,                                                -- 発注NO
             xoha.prod_class,                                           -- 商品区分
             xoha.item_class,                                           -- 品目区分
             xoha.no_cont_freight_class,                                -- 契約外運賃区分
             xoha.arrival_time_from,                                    -- 着荷時間FROM
             xoha.arrival_time_to,                                      -- 着荷時間TO
             xoha.designated_item_id,                                   -- 製造品目ID
             xoha.designated_item_code,                                 -- 製造品目
             xoha.designated_production_date,                           -- 製造日
             xoha.designated_branch_no,                                 -- 製造枝番
             xoha.slip_number,                                          -- 送り状NO
             xoha.sum_quantity,                                         -- 合計数量
             xoha.small_quantity,                                       -- 小口個数
             xoha.label_quantity,                                       -- ラベル枚数
             xoha.loading_efficiency_weight,                            -- 重量積載効率
             xoha.loading_efficiency_capacity,                          -- 容積積載効率
             xoha.based_weight,                                         -- 基本重量
             xoha.based_capacity,                                       -- 基本容積
             xoha.sum_weight,                                           -- 積載重量合計
             xoha.sum_capacity,                                         -- 積載容積合計
             xoha.mixed_ratio,                                          -- 混載率
             xoha.pallet_sum_quantity,                                  -- パレット合計枚数
             xoha.real_pallet_quantity,                                 -- パレット実績枚数
             xoha.sum_pallet_weight,                                    -- 合計パレット重量
             xoha.order_source_ref,                                     -- 受注ソース参照
             xoha.result_freight_carrier_id,                            -- 運送業者_実績ID
             xoha.result_freight_carrier_code,                          -- 運送業者_実績
             xoha.result_shipping_method_code,                          -- 配送区分_実績
             xoha.result_deliver_to_id,                                 -- 出荷先_実績ID
             xoha.result_deliver_to,                                    -- 出荷先_実績
             xoha.shipped_date,                                         -- 出荷日
             xoha.arrival_date,                                         -- 着荷日
             xoha.weight_capacity_class,                                -- 重量容積区分
             xoha.notif_status,                                         -- 通知ステータス
             xoha.prev_notif_status,                                    -- 前回通知ステータス
             xoha.notif_date,                                           -- 確定通知実施日時
             xoha.new_modify_flg,                                       -- 新規修正フラグ
             xoha.process_status,                                       -- 処理経過ステータス
             xoha.performance_management_dept,                          -- 成績管理部署
             xoha.instruction_dept,                                     -- 指示部署
             xoha.transfer_location_id,                                 -- 振替先ID
             xoha.transfer_location_code,                               -- 振替先
             xoha.mixed_sign,                                           -- 混載記号
             xoha.screen_update_date,                                   -- 画面更新日時
             xoha.screen_update_by,                                     -- 画面更新者
             xoha.tightening_date,                                      -- 出荷依頼締め日時
             xoha.vendor_id,                                            -- 取引先ID
             xoha.vendor_code,                                          -- 取引先
             xoha.vendor_site_id,                                       -- 取引先サイトID
             xoha.vendor_site_code,                                     -- 取引先サイト
             xoha.registered_sequence,                                  -- 登録順序
             xoha.tightening_program_id,                                -- 締めコンカレントID
             xoha.corrected_tighten_class,                              -- 締め後修正区分
             xola.order_line_id,                                        -- 受注明細アドオンID
             xola.order_line_number,                                    -- 明細番号
             xola.line_id,                                              -- 受注明細ID
             xola.request_no line_request_no,                           -- 依頼No
             xola.shipping_inventory_item_id,                           -- 出荷品目ID
             xola.shipping_item_code,                                   -- 出荷品目
             xola.quantity,                                             -- 数量
             xola.uom_code,                                             -- 単位
             xola.unit_price,                                           -- 単価
             xola.shipped_quantity,                                     -- 出荷実績数量
             xola.designated_production_date line_designated_prod_date, -- 指定製造日
             xola.based_request_quantity,                               -- 拠点依頼数量
             xola.request_item_id,                                      -- 依頼品目ID
             xola.request_item_code,                                    -- 依頼品目
             xola.ship_to_quantity,                                     -- 入庫実績数量
             xola.futai_code,                                           -- 付帯コード
             xola.designated_date,                                      -- 指定日付（リーフ）
             xola.move_number,                                          -- 移動NO
             xola.po_number,                                            -- 発注NO
             xola.cust_po_number line_cust_po_number,                   -- 顧客発注
             xola.pallet_quantity,                                      -- パレット数
             xola.layer_quantity,                                       -- 段数
             xola.case_quantity,                                        -- ケース数
             xola.weight,                                               -- 重量
             xola.capacity,                                             -- 容積
             xola.pallet_qty,                                           -- パレット枚数
             xola.pallet_weight,                                        -- パレット重量
             xola.reserved_quantity,                                    -- 引当数
             xola.automanual_reserve_class,                             -- 自動手動引当区分
             xola.warning_class,                                        -- 警告区分
             xola.warning_date,                                         -- 警告日付
             xola.line_description,                                     -- 摘要
             xola.rm_if_flg,                                            -- 倉替返品IF済フラグ
             xola.shipping_request_if_flg,                              -- 出荷依頼IF済フラグ
             xola.shipping_result_if_flg,                               -- 出荷実績IF済フラグ
             xilv.distribution_block,                                   -- ブロック
             xilv.mtl_organization_id,                                  -- 在庫組織ID
             xilv.location_id,                                          -- 事業所ID
             xilv.subinventory_code,                                    -- 保管場所コード
             xilv.inventory_location_id,                                -- 倉庫ID
-- 2009/11/05 H.Itou MOD START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは取得しない。
--             xcav.cust_account_id,                                      -- 顧客ID
             NULL cust_account_id,                                      -- 顧客ID
-- 2009/11/05 H.Itou MOD END
             ximv.lot_ctl                                               -- ロット管理
      FROM   xxwsh_order_headers_all xoha,                              -- 受注ヘッダアドオン
             xxwsh_order_lines_all xola,                                -- 受注明細アドオン
             xxwsh_oe_transaction_types_v xottv1,                       -- 受注タイプVIEW1
             xxwsh_oe_transaction_types_v xottv2,                       -- 受注タイプVIEW2
-- 2009/11/05 H.Itou DEL START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは結合不要。
--             xxcmn_cust_accounts_v xcav,                                -- 顧客情報VIEW
-- 2009/11/05 H.Itou DEL END
             xxcmn_item_locations_v xilv,                               -- OPM保管場所情報VIEW
             xxcmn_item_mst_v ximv                                      -- OPM品目情報VIEW
      WHERE  xoha.order_header_id = it_order_header_id
      AND    NVL(xoha.latest_external_flag,gv_no) = gv_no
      AND    xilv.segment1 = xoha.deliver_from
      AND    xottv1.transaction_type_id = xoha.order_type_id
      AND    xottv2.transaction_type_name = xottv1.cancel_order_type
-- 2009/11/05 H.Itou DEL START 本番障害#1648 顧客IDは対象データ抽出後、洗い替えで取得するので、ここでは結合不要。
--      AND    xcav.party_id = xoha.customer_id
-- 2009/11/05 H.Itou DEL END
      AND    xola.order_header_id = xoha.order_header_id
      AND    NVL(xola.delete_flag,gv_no) = gv_no
      AND    ximv.item_no  = xola.shipping_item_code;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***       取消受注アドオン情報取得  ***
    -- ***************************************
    -- カーソルオープン
    OPEN cur_order_data;
    -- バルクフェッチ
    FETCH cur_order_data BULK COLLECT INTO or_order_info_tbl ;
    -- カーソルクローズ
    CLOSE cur_order_data ;
-- 2009/04/08 H.Itou ADD START 本番障害#1356 最新の顧客データでないと、標準APIでエラーになるので、最新マスタデータを取得
    <<change_new_cust_loop>>
-- 2009/04/14 MOD START 本番障害#1406 データが0件のときに落ちるので修正
--    FOR i IN or_order_info_tbl.FIRST..or_order_info_tbl.LAST LOOP
    FOR i IN 1..or_order_info_tbl.COUNT LOOP
-- 2009/04/14 MOD END
      -- ======================================
      -- 顧客情報洗い替え処理
      -- ======================================
      -- 依頼Noがブレイクした時に、顧客マスタを検索
      IF  ((or_order_info_tbl.FIRST = i)
        OR (or_order_info_tbl(i-1).request_no <> or_order_info_tbl(i).request_no)) THEN
--
        -- 変数初期化
        lt_customer_id          := NULL;   -- 顧客ID(party_id)
        lt_cust_account_id      := NULL;   -- 顧客ID(cust_account_id)
        lt_customer_code        := NULL;   -- 顧客
        lt_result_deliver_to_id := NULL;   -- 出荷先_実績ID
--
        -- 支給の場合
        IF (or_order_info_tbl(i).shipping_shikyu_class = gv_ship_class_2) THEN
--
          -- 顧客番号で最新顧客データ取得
          get_new_cust_data(
            it_party_number    => or_order_info_tbl(i).customer_code,     -- IN. 顧客
            ot_party_id        => lt_customer_id,                         -- OUT.顧客ID(party_id)
            ot_cust_account_id => lt_cust_account_id,                     -- OUT.顧客ID(cust_account_id)
            ot_party_number    => lt_customer_code,                       -- OUT.顧客
            ov_errbuf          => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
            ov_retcode         => lv_retcode,   -- リターン・コード             --# 固定 #
            ov_errmsg          => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
           );
--
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- エラー終了
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
--
          -- 支給では以下の項目はNULLなので、最新取得なしなので、DBの値(NULL)をセット
          lt_result_deliver_to_id := or_order_info_tbl(i).result_deliver_to_id; -- 最新出荷先_実績ID
          lt_deliver_to_id        := or_order_info_tbl(i).deliver_to_id;        -- 最新出荷先_指示ID
          lt_head_sales_branch    := or_order_info_tbl(i).head_sales_branch;    -- 管轄拠点
-- 2009/04/21 H.Itou ADD END
        -- 出荷・倉替返品の場合
        ELSE
--
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- 指示ありの場合
          IF (or_order_info_tbl(i).deliver_to IS NOT NULL) THEN
            -- 出荷先_指示コードで出荷先_指示IDを取得
            get_new_cust_site_data(
              it_party_site_number => or_order_info_tbl(i).deliver_to,        -- IN. 出荷先_指示
              ot_party_site_id     => lt_deliver_to_id,                       -- OUT.出荷先_指示ID
              ov_errbuf            => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
              ov_retcode           => lv_retcode,   -- リターン・コード             --# 固定 #
              ov_errmsg            => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
             );
--
            -- エラー終了
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
--
-- 2009/04/21 H.Itou ADD END
          -- 出荷先_実績コードで最新顧客、出荷先_実績ID、管轄拠点を取得
          get_new_cust_data(
            it_party_site_number => or_order_info_tbl(i).result_deliver_to, -- IN. 出荷先_実績
            ot_party_id          => lt_customer_id,                         -- OUT.顧客ID(party_id)
            ot_cust_account_id   => lt_cust_account_id,                     -- OUT.顧客ID(cust_account_id)
            ot_party_number      => lt_customer_code,                       -- OUT.顧客
            ot_party_site_id     => lt_result_deliver_to_id,                -- OUT.出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
            ot_base_code         => lt_head_sales_branch,                   -- OUT.管轄拠点
-- 2009/04/21 H.Itou ADD END
            ov_errbuf            => lv_errbuf,    -- エラー・メッセージ           --# 固定 #
            ov_retcode           => lv_retcode,   -- リターン・コード             --# 固定 #
            ov_errmsg            => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
           );
--
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
          -- エラー終了
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE global_api_expt;
          END IF;
-- 2009/04/21 H.Itou ADD END
        END IF;
--
-- 2009/04/21 H.Itou DEL START 本番障害#1356(再対応)
--        -- エラー終了
--        IF (lv_retcode <> gv_status_normal) THEN
--          RAISE global_api_expt;
--        END IF;
-- 2009/04/21 H.Itou DEL END
      END IF;
--
      -- 最新情報に洗い替え
      or_order_info_tbl(i).customer_id          := lt_customer_id;          -- 顧客ID(party_id)
      or_order_info_tbl(i).cust_account_id      := lt_cust_account_id;      -- 顧客ID(cust_account_id)
      or_order_info_tbl(i).customer_code        := lt_customer_code;        -- 顧客
      or_order_info_tbl(i).result_deliver_to_id := lt_result_deliver_to_id; -- 出荷先_実績ID
-- 2009/04/21 H.Itou ADD START 本番障害#1356(再対応)
      or_order_info_tbl(i).head_sales_branch    := lt_head_sales_branch;    -- 最新管轄拠点
      or_order_info_tbl(i).deliver_to_id        := lt_deliver_to_id;        -- 最新出荷先_指示ID
-- 2009/04/21 H.Itou ADD END
    END LOOP change_new_cust_loop;
-- 2009/04/08 H.Itou ADD END
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_revised_order_info;
  /***********************************************************************************
   * Procedure Name   : create_order_header_info
   * Description      : A6受注ヘッダ情報の登録
   ***********************************************************************************/
  PROCEDURE create_order_header_info(
    iot_order_tbl
        IN OUT order_tbl,                                        -- 受注情報格納配列
    ot_new_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE, -- 赤用新受注ヘッダアドオンID
    ot_new_header_id
        OUT NOCOPY xxwsh_order_headers_all.header_id%TYPE,       -- 赤用新受注ヘッダID
    ot_shipped_date
        OUT NOCOPY xxwsh_order_headers_all.shipped_date%TYPE,    -- 出荷日
    ov_standard_api_flag
        OUT NOCOPY NUMBER,                                       -- 標準API実行フラグ
    on_gen_count
        OUT NOCOPY NUMBER,                                       -- 現在のデータの位置を保持
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                     -- エラー・メッセージ--# 固定 #
    ov_retcode
        OUT NOCOPY VARCHAR2,                                     -- リターン・コード--# 固定 #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                     -- ユーザエラーメッセージ--#固定#
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_order_header_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status
        VARCHAR2(1) ;                                 -- APIの処理ステータス
    ln_msg_count
        NUMBER;                                       -- APIのエラーメッセージ件数
    lv_msg_data
        VARCHAR2(2000) ;                              -- APIのエラーメッセージ
    lv_msg_buf
        VARCHAR2(2000);                               -- APIメッセージ統合用
    lt_new_order_header_id
        xxwsh_order_headers_all.order_header_id%TYPE; -- 新受注ヘッダアドオンID
    ln_shori_count
        NUMBER;                                       -- 処理位置件数
    ln_line_count
        NUMBER;                                       -- 明細件数(実績数量が0以上)
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_header_rec              OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec          OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl          OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl      OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl    OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl      OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl      OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_tbl                OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_val_tbl            OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl            OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl        OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl      OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl        OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl        OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl          OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl      OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    --A3で取得したデータかA5で取得したデータかによりレコードの基準値が異なる
    IF (gv_shori_kbn IN ('1','3') ) THEN
      ln_shori_count := gn_shori_count;
    ELSE
      ln_shori_count := 1;
    END IF;
--
    on_gen_count     := ln_shori_count; -- 明細作成処理に現在の位置を渡すため
    ot_shipped_date  := iot_order_tbl(ln_shori_count).shipped_date; --出荷日
--
    -- 受注明細作成対象件数を調査
    SELECT count(xola.order_line_id)
    INTO   ln_line_count
    FROM   xxwsh_order_lines_all xola
    WHERE  xola.order_header_id = iot_order_tbl(ln_shori_count).order_header_id
    AND    NVL(xola.delete_flag,gv_no) = gv_no
    AND    NVL(xola.shipped_quantity,0) <> 0;
--
    IF (ln_line_count > 0 ) THEN
--
      ov_standard_api_flag := '1';--標準API実行フラグに1(実行)をセット
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
      -- API用変数に初期値をセット
      lt_header_rec                         := OE_ORDER_PUB.G_MISS_HEADER_REC;
      lt_line_tbl(1)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_header_rec.operation               := OE_GLOBALS.G_OPR_CREATE;                                                -- [CREATE]
      lt_header_rec.sold_to_org_id          := iot_order_tbl(ln_shori_count).cust_account_id;                          -- 顧客
      lt_header_rec.org_id                  := gn_org_id;                                                              -- 営業単位
      lt_header_rec.order_type_id           := iot_order_tbl(ln_shori_count).transaction_type_id;                      -- 受注タイプをセット
      lt_header_rec.ordered_date            := iot_order_tbl(ln_shori_count).ordered_date;                             -- 受注日
--
      IF (iot_order_tbl(ln_shori_count).shipping_shikyu_class <> gv_ship_class_2) THEN
         --出荷支給区分が支給依頼以外の場合
        lt_header_rec.ship_to_party_site_id := iot_order_tbl(ln_shori_count).result_deliver_to_id;                     -- 出荷先ID
      END IF;
--
      lt_header_rec.shipping_instructions   := iot_order_tbl(ln_shori_count).shipping_instructions;                       -- 出荷指示
      lt_header_rec.cust_po_number          := iot_order_tbl(ln_shori_count).cust_po_number;                              -- 顧客発注
      lt_header_rec.ship_from_org_id        := iot_order_tbl(ln_shori_count).mtl_organization_id;                         -- 在庫組織ID
      lt_header_rec.attribute1              := iot_order_tbl(ln_shori_count).request_no;                                  -- 依頼No
      lt_header_rec.attribute2              := iot_order_tbl(ln_shori_count).delivery_no;                                 -- 配送No
      lt_header_rec.attribute3              := iot_order_tbl(ln_shori_count).result_freight_carrier_code;                 -- 運送業者_実績
      lt_header_rec.attribute4              := iot_order_tbl(ln_shori_count).result_shipping_method_code;                 -- 配送区分_実績
      lt_header_rec.attribute6              := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_ship_date,'YYYY/MM/DD');    -- 出荷予定日
      lt_header_rec.attribute7              := iot_order_tbl(ln_shori_count).head_sales_branch;                           -- 管轄拠点
      lt_header_rec.attribute8              := iot_order_tbl(ln_shori_count).deliver_from;                                -- 出荷元
      lt_header_rec.attribute9              := TO_CHAR(iot_order_tbl(ln_shori_count).shipped_date,'YYYY/MM/DD');          -- 出荷日
      lt_header_rec.attribute10             := TO_CHAR(iot_order_tbl(ln_shori_count).arrival_date,'YYYY/MM/DD');          -- 着荷日
      lt_header_rec.attribute11             := iot_order_tbl(ln_shori_count).performance_management_dept;                 -- 成績管理部署
      lt_header_rec.attribute12             := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_arrival_date,'YYYY/MM/DD'); -- 着荷予定日
      -- ***************************************
      -- ***       A6-受注作成API起動        ***
      -- ***************************************
--
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
--
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
--
      ot_new_header_id := lt_header_rec.header_id;       -- 受注ヘッダID
--
      IF (gv_shori_kbn IN ('1','3') ) THEN
        -- 受注ヘッダID更新用のデータに登録する
        gt_header_id := lt_header_rec.header_id;       -- 受注ヘッダID
      END IF;
--
    ELSE
      ov_standard_api_flag := '0';--標準API実行フラグに0(実行しない)をセット
    END IF;
--
    ot_new_order_header_id := iot_order_tbl(ln_shori_count).order_header_id; -- 受注ヘッダアドオンID
--
    IF (gv_shori_kbn = '4') THEN
      --訂正返品で受注ヘッダ登録以前の場合受注ヘッダアドオンにデータを登録
      SELECT xxwsh_order_headers_all_s1.NEXTVAL
      INTO   lt_new_order_header_id
      FROM   dual;
--
      ot_new_order_header_id       := lt_new_order_header_id;
--
      INSERT INTO xxwsh_order_headers_all
        (order_header_id,             -- 受注ヘッダアドオンID
         order_type_id,               -- 受注タイプID
         organization_id,             -- 組織ID
         header_id,                   -- 受注ヘッダID
         latest_external_flag,        -- 最新フラグ
         ordered_date,                -- 受注日
         customer_id,                 -- 顧客ID
         customer_code,               -- 顧客
         deliver_to_id,               -- 出荷先ID
         deliver_to,                  -- 出荷先
         shipping_instructions,       -- 出荷指示
         career_id,                   -- 運送業者ID
         freight_carrier_code,        -- 運送業者
         shipping_method_code,        -- 配送区分
         cust_po_number,              -- 顧客発注
         price_list_id,               -- 価格表
         request_no,                  -- 依頼No
         req_status,                  -- ステータス
         delivery_no,                 -- 配送No
         prev_delivery_no,            -- 前回配送No
         schedule_ship_date,          -- 出荷予定日
         schedule_arrival_date,       -- 着荷予定日
         mixed_no,                    -- 混載元No
         collected_pallet_qty,        -- パレット回収枚数
         confirm_request_class,       -- 物流担当確認依頼区分
         freight_charge_class,        -- 運賃区分
         shikyu_instruction_class,    -- 支給出庫指示区分
         shikyu_inst_rcv_class,       -- 支給指示受領区分
         amount_fix_class,            -- 有償金額確定区分
         takeback_class,              -- 引取区分
         deliver_from_id,             -- 出荷元ID
         deliver_from,                -- 出荷元保管場所
         head_sales_branch,           -- 管轄拠点
         input_sales_branch,          -- 入力拠点
         po_no,                       -- 発注No
         prod_class,                  -- 商品区分
         item_class,                  -- 品目区分
         no_cont_freight_class,       -- 契約外運賃区分
         arrival_time_from,           -- 着荷時間FROM
         arrival_time_to,             -- 着荷時間TO
         designated_item_id,          -- 製造品目ID
         designated_item_code,        -- 製造品目
         designated_production_date,  -- 製造日
         designated_branch_no,        -- 製造枝番
         slip_number,                 -- 送り状No
         sum_quantity,                -- 合計数量
         small_quantity,              -- 小口個数
         label_quantity,              -- ラベル枚数
         loading_efficiency_weight,   -- 重量積載効率
         loading_efficiency_capacity, -- 容積積載効率
         based_weight,                -- 基本重量
         based_capacity,              -- 基本容積
         sum_weight,                  -- 積載重量合計
         sum_capacity,                -- 積載容積合計
         mixed_ratio,                 -- 混載率
         pallet_sum_quantity,         -- パレット合計枚数
         real_pallet_quantity,        -- パレット実績枚数
         sum_pallet_weight,           -- 合計パレット重量
         order_source_ref,            -- 受注ソース参照
         result_freight_carrier_id,   -- 運送業者_実績ID
         result_freight_carrier_code, -- 運送業者_実績
         result_shipping_method_code, -- 配送区分_実績
         result_deliver_to_id,        -- 出荷先_実績ID
         result_deliver_to,           -- 出荷先_実績
         shipped_date,                -- 出荷日
         arrival_date,                -- 着荷日
         weight_capacity_class,       -- 重量容積区分
         actual_confirm_class,        -- 実績計上済区分
         notif_status,                -- 通知ステータス
         prev_notif_status,           -- 前回通知ステータス
         notif_date,                  -- 確定通知実施日時
         new_modify_flg,              -- 新規修正フラグ
         process_status,              -- 処理経過ステータス
         performance_management_dept, -- 成績管理部署
         instruction_dept,            -- 指示部署
         transfer_location_id,        -- 振替先ID
         transfer_location_code,      -- 振替先
         mixed_sign,                  -- 混載記号
         screen_update_date,          -- 画面更新日時
         screen_update_by,            -- 画面更新者
         tightening_date,             -- 出荷依頼締め日時
         vendor_id,                   -- 取引先ID
         vendor_code,                 -- 取引先
         vendor_site_id,              -- 取引先サイトID
         vendor_site_code,            -- 取引先サイト
         registered_sequence,         -- 登録順序
         tightening_program_id,       -- 締めコンカレントID
         corrected_tighten_class,     -- 締め後修正区分
         created_by,                  -- 作成者
         creation_date,               -- 作成日
         last_updated_by,             -- 最終更新者
         last_update_date,            -- 最終更新日
         last_update_login,           -- 最終更新ログイン
         request_id,                  -- 要求ID
         program_application_id,      -- コンカレント・プログラム・アプリケーションID
         program_id,                  -- コンカレント・プログラムID
         program_update_date          -- プログラム更新日
        )VALUES
        (lt_new_order_header_id,
         iot_order_tbl(ln_shori_count).transaction_type_id,
         iot_order_tbl(ln_shori_count).organization_id,
         lt_header_rec.header_id,
         gv_no,
         iot_order_tbl(ln_shori_count).ordered_date,
         iot_order_tbl(ln_shori_count).customer_id,
         iot_order_tbl(ln_shori_count).customer_code,
         iot_order_tbl(ln_shori_count).deliver_to_id,
         iot_order_tbl(ln_shori_count).deliver_to,
         iot_order_tbl(ln_shori_count).shipping_instructions,
         iot_order_tbl(ln_shori_count).career_id,
         iot_order_tbl(ln_shori_count).freight_carrier_code,
         iot_order_tbl(ln_shori_count).shipping_method_code,
         iot_order_tbl(ln_shori_count).cust_po_number,
         iot_order_tbl(ln_shori_count).price_list_id,
         iot_order_tbl(ln_shori_count).request_no,
         iot_order_tbl(ln_shori_count).req_status,
         iot_order_tbl(ln_shori_count).delivery_no,
         iot_order_tbl(ln_shori_count).prev_delivery_no,
         iot_order_tbl(ln_shori_count).schedule_ship_date,
         iot_order_tbl(ln_shori_count).schedule_arrival_date,
         iot_order_tbl(ln_shori_count).mixed_no,
         iot_order_tbl(ln_shori_count).collected_pallet_qty,
         iot_order_tbl(ln_shori_count).confirm_request_class,
         iot_order_tbl(ln_shori_count).freight_charge_class,
         iot_order_tbl(ln_shori_count).shikyu_instruction_class,
         iot_order_tbl(ln_shori_count).shikyu_inst_rcv_class,
         iot_order_tbl(ln_shori_count).amount_fix_class,
         iot_order_tbl(ln_shori_count).takeback_class,
         iot_order_tbl(ln_shori_count).deliver_from_id,
         iot_order_tbl(ln_shori_count).deliver_from,
         iot_order_tbl(ln_shori_count).head_sales_branch,
         iot_order_tbl(ln_shori_count).input_sales_branch,
         iot_order_tbl(ln_shori_count).po_no,
         iot_order_tbl(ln_shori_count).prod_class,
         iot_order_tbl(ln_shori_count).item_class,
         iot_order_tbl(ln_shori_count).no_cont_freight_class,
         iot_order_tbl(ln_shori_count).arrival_time_from,
         iot_order_tbl(ln_shori_count).arrival_time_to,
         iot_order_tbl(ln_shori_count).designated_item_id,
         iot_order_tbl(ln_shori_count).designated_item_code,
         iot_order_tbl(ln_shori_count).designated_production_date,
         iot_order_tbl(ln_shori_count).designated_branch_no,
         iot_order_tbl(ln_shori_count).slip_number,
         iot_order_tbl(ln_shori_count).sum_quantity,
         iot_order_tbl(ln_shori_count).small_quantity,
         iot_order_tbl(ln_shori_count).label_quantity,
         iot_order_tbl(ln_shori_count).loading_efficiency_weight,
         iot_order_tbl(ln_shori_count).loading_efficiency_capacity,
         iot_order_tbl(ln_shori_count).based_weight,
         iot_order_tbl(ln_shori_count).based_capacity,
         iot_order_tbl(ln_shori_count).sum_weight,
         iot_order_tbl(ln_shori_count).sum_capacity,
         iot_order_tbl(ln_shori_count).mixed_ratio,
         iot_order_tbl(ln_shori_count).pallet_sum_quantity,
         iot_order_tbl(ln_shori_count).real_pallet_quantity,
         iot_order_tbl(ln_shori_count).sum_pallet_weight,
         iot_order_tbl(ln_shori_count).order_source_ref,
         iot_order_tbl(ln_shori_count).result_freight_carrier_id,
         iot_order_tbl(ln_shori_count).result_freight_carrier_code,
         iot_order_tbl(ln_shori_count).result_shipping_method_code,
         iot_order_tbl(ln_shori_count).result_deliver_to_id,
         iot_order_tbl(ln_shori_count).result_deliver_to,
         iot_order_tbl(ln_shori_count).shipped_date,
         iot_order_tbl(ln_shori_count).arrival_date,
         iot_order_tbl(ln_shori_count).weight_capacity_class,
         gv_yes,
         iot_order_tbl(ln_shori_count).notif_status,
         iot_order_tbl(ln_shori_count).prev_notif_status,
         iot_order_tbl(ln_shori_count).notif_date,
         iot_order_tbl(ln_shori_count).new_modify_flg,
         iot_order_tbl(ln_shori_count).process_status,
         iot_order_tbl(ln_shori_count).performance_management_dept,
         iot_order_tbl(ln_shori_count).instruction_dept,
         iot_order_tbl(ln_shori_count).transfer_location_id,
         iot_order_tbl(ln_shori_count).transfer_location_code,
         iot_order_tbl(ln_shori_count).mixed_sign,
         iot_order_tbl(ln_shori_count).screen_update_date,
         iot_order_tbl(ln_shori_count).screen_update_by,
         iot_order_tbl(ln_shori_count).tightening_date,
         iot_order_tbl(ln_shori_count).vendor_id,
         iot_order_tbl(ln_shori_count).vendor_code,
         iot_order_tbl(ln_shori_count).vendor_site_id,
         iot_order_tbl(ln_shori_count).vendor_site_code,
         iot_order_tbl(ln_shori_count).registered_sequence,
         iot_order_tbl(ln_shori_count).tightening_program_id,
         iot_order_tbl(ln_shori_count).corrected_tighten_class,
         gn_user_id,
         SYSDATE,
         gn_user_id,
         SYSDATE,
         gn_login_id,
         gn_conc_request_id,
         gn_prog_appl_id,
         gn_conc_program_id,
         SYSDATE
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_order_header_info;
  /***********************************************************************************
   * Procedure Name   : create_order_line_info
   * Description      : A7受注明細レコード作成、A8受注明細登録
   ***********************************************************************************/
  PROCEDURE create_order_line_info(
    it_bef_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- 前処理受注ヘッダアドオンID
    it_new_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- 赤用新受注ヘッダアドオンID
    it_new_header_id
        IN xxwsh_order_headers_all.header_id%TYPE,       -- 赤用新受注ヘッダID
    in_gen_count
        IN NUMBER,                                       -- 受注情報格納配列の現在の位置
    iot_order_tbl
        IN OUT order_tbl,                                -- 受注情報格納配列
    ot_order_line_tbl
        OUT NOCOPY order_line_type,                      -- 受注明細情報格納配列
    ot_revised_line_tbl
        OUT NOCOPY revised_line_type,                    -- 訂正受注明細情報格納配列
    ov_errbuf
        OUT NOCOPY VARCHAR2,                             -- エラー・メッセージ --# 固定 #
    ov_retcode
        OUT NOCOPY VARCHAR2,                             -- リターン・コード --# 固定 #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_order_line_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_line_count                 NUMBER;                               -- 明細件数
    lv_return_status              VARCHAR2(1) ;                         -- APIの処理ステータス
    ln_msg_count                  NUMBER;                               -- APIのエラーメッセージ件数
    lv_msg_data                   VARCHAR2(2000) ;                      -- APIのエラーメッセージ
    lv_msg_buf                    VARCHAR2(2000);                       -- APIメッセージ統合用
    ln_shori_count                NUMBER;                               -- 受注情報の処理件数
    lt_input_line_id              oe_order_lines_all.line_id%TYPE;      -- 登録用受注明細ID
    ln_order_line_count           NUMBER;                               -- 受注明細登録件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- *** アドオン登録用 ***
    lt_order_line_id              ol_order_line_id_type;                -- 受注明細アドオンID
    lt_order_header_id            ol_order_header_id_type;              -- 受注ヘッダアドオンID
    lt_order_line_number          ol_order_line_number_type;            -- 明細番号
    lt_header_id                  ol_header_id_type;                    -- 受注ヘッダID
    lt_line_id                    ol_line_id_type;                      -- 受注明細ID
    lt_request_no                 ol_request_no_type;                   -- 依頼No
    lt_shipping_inventory_item_id ol_ship_inv_item_id_type;             -- 出荷品目ID
    lt_shipping_item_code         ol_ship_item_code_type;               -- 出荷品目
    lt_quantity                   ol_quantity_type;                     -- 数量
    lt_uom_code                   ol_uom_code_type;                     -- 単位
    lt_unit_price                 ol_unit_price_type;                   -- 単価
    lt_shippied_quantity          ol_shipped_quantity_type;             -- 出荷実績数量
    lt_designated_production_date ol_desi_prod_date_type;               -- 指定製造日
    lt_based_request_quantity     ol_base_req_quantity_type;            -- 拠点依頼数量
    lt_request_item_id            ol_request_item_id_type;              -- 依頼品目ID
    lt_request_item_code          ol_request_item_code_type;            -- 依頼品目コード
    lt_ship_to_quantity           ol_ship_to_quantity_type;             -- 入庫実績数量
    lt_futai_code                 ol_futai_code_type;                   -- 付帯コード
    lt_designated_date            ol_designated_date_type;              -- 指定日付(リーフ)
    lt_move_number                ol_move_number_type;                  -- 移動No
    lt_po_number                  ol_po_number_type;                    -- 発注No
    lt_cust_po_number             ol_cust_po_number_type;               -- 顧客発注
    lt_pallet_quantity            ol_pallet_quantity_type;              -- パレット数
    lt_layer_quantity             ol_layer_quantity_type;               -- 段数
    lt_case_quantity              ol_case_quantity_type;                -- ケース数
    lt_weight                     ol_weight_type;                       -- 重量
    lt_capacity                   ol_capacity_type;                     -- 容積
    lt_pallet_qty                 ol_pallet_qty_type;                   -- パレット枚数
    lt_pallet_weight              ol_pallet_weight_type;                -- パレット重量
    lt_reserved_quantity          ol_reserved_quantity_type;            -- 引当数
    lt_automanual_reserve_class   ol_auto_rese_class_type;              -- 自動手動引当区分
    lt_warning_class              ol_warning_class_type;                -- 警告区分
    lt_warning_date               ol_warning_date_type;                 -- 警告日付
    lt_line_description           ol_line_description_type;             -- 摘要
    lt_rm_if_flg                  ol_rm_if_flg_type;                    -- 倉替返品IF済フラグ
    lt_shipping_request_if_flg    ol_ship_requ_if_flg_type;             -- 出荷依頼IF済フラグ
    lt_shipping_result_if_flg     ol_ship_resu_if_flg_type;             -- 出荷実績IF済フラグ
    -- 受注明細登録用配列
    lt_order_line_tbl             OE_ORDER_PUB.LINE_TBL_TYPE;           -- 受注明細登録用レコード
    lt_header_rec                 OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec             OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl             OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl         OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl       OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl         OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl       OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl         OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl     OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_val_tbl               OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl               OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl           OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl         OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl           OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl         OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl           OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl       OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl             OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl         OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl         OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    ln_line_count       := 0;             -- 明細件数を初期化
    ln_order_line_count := 0;
    ln_shori_count := in_gen_count;
    <<order_line_data>> --受注作成情報ループ処理
    LOOP
      IF ((ln_shori_count > iot_order_tbl.LAST)
       OR
          (iot_order_tbl(ln_shori_count).order_header_id <> it_bef_order_header_id)) THEN
        EXIT;
      END IF;
--
      lt_input_line_id := NULL;   -- セット用受注明細IDを初期化
      IF (NVL(iot_order_tbl(ln_shori_count).shipped_quantity,0) <> 0 )THEN
        ln_order_line_count := ln_order_line_count + 1;
        -- 受注明細登録API用データ
        lt_order_line_tbl(ln_order_line_count)                      := OE_ORDER_PUB.G_MISS_LINE_REC;                             -- 受注明細変数の初期化
        SELECT oe_order_lines_s.NEXTVAL
        INTO   lt_order_line_tbl(ln_order_line_count).line_id
        FROM   DUAL;
        lt_input_line_id                                            := lt_order_line_tbl(ln_order_line_count).line_id;
        lt_order_line_tbl(ln_order_line_count).operation            := OE_GLOBALS.G_OPR_CREATE;
        lt_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- 受注ヘッダID
        lt_order_line_tbl(ln_order_line_count).inventory_item_id    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- 出荷品目ID
        lt_order_line_tbl(ln_order_line_count).ordered_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- 出荷実績数量
        lt_order_line_tbl(ln_order_line_count).unit_selling_price   := NVL(iot_order_tbl(ln_shori_count).unit_price,0);                 -- 単価
        lt_order_line_tbl(ln_order_line_count).unit_list_price      := NVL(iot_order_tbl(ln_shori_count).unit_price,0);                 -- 単価
        lt_order_line_tbl(ln_order_line_count).schedule_ship_date   := iot_order_tbl(ln_shori_count).schedule_ship_date;         -- 出荷予定日
        lt_order_line_tbl(ln_order_line_count).request_date         := SYSDATE;                                                  -- 要求日
        lt_order_line_tbl(ln_order_line_count).calculate_price_flag := gv_no;                                                    -- 凍結価格計算フラグ
        lt_order_line_tbl(ln_order_line_count).attribute1           := iot_order_tbl(ln_shori_count).quantity;                   -- 数量
        lt_order_line_tbl(ln_order_line_count).attribute2           := iot_order_tbl(ln_shori_count).based_request_quantity;     -- 拠点依頼数量
        lt_order_line_tbl(ln_order_line_count).attribute3           := iot_order_tbl(ln_shori_count).request_item_code;          -- 依頼品目
        ot_order_line_tbl(ln_order_line_count).order_line_id        := iot_order_tbl(ln_shori_count).order_line_id;              -- 受注明細アドオンID
        ot_order_line_tbl(ln_order_line_count).line_id              := lt_input_line_id;                                         -- 受注明細ID
        ot_order_line_tbl(ln_order_line_count).shipped_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- 実績数量
        ot_order_line_tbl(ln_order_line_count).deliver_from         := iot_order_tbl(ln_shori_count).deliver_from;               -- 出庫元保管場所
        ot_order_line_tbl(ln_order_line_count).shipped_date         := iot_order_tbl(ln_shori_count).shipped_date;               -- 出荷日
        ot_order_line_tbl(ln_order_line_count).uom_code             := iot_order_tbl(ln_shori_count).uom_code;                   -- 単位
        ot_order_line_tbl(ln_order_line_count).lot_ctl              := iot_order_tbl(ln_shori_count).lot_ctl;                    -- ロット管理
      END IF;
--
      -- 明細件数を+1
      ln_line_count := ln_line_count + 1;
--
      IF (gv_shori_kbn IN ('1','3') ) THEN 
        -- 受注明細ID更新用変数に値をセット
        gt_order_line_id(ln_line_count)   := iot_order_tbl(ln_shori_count).order_line_id;                              -- 受注明細アドオンID
        gt_line_id(ln_line_count)         := lt_input_line_id;                                                         -- 受注明細ID
      END IF;
--
      IF (gv_shori_kbn = '4') THEN 
--
        --訂正返品で受注明細登録以前の場合受注明細アドオン登録用データを作成
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   lt_order_line_id(ln_line_count)
        FROM   dual;
--
        ot_revised_line_tbl(ln_line_count).order_line_id
                                                           := iot_order_tbl(ln_shori_count).order_line_id;
        ot_revised_line_tbl(ln_line_count).new_order_line_id
                                                           := lt_order_line_id(ln_line_count); -- 新受注明細アドオンIDをセット
        lt_order_header_id(ln_line_count)                  := it_new_order_header_id;
        lt_order_line_number(ln_line_count)                := iot_order_tbl(ln_shori_count).order_line_number;
        lt_header_id(ln_line_count)                        := it_new_header_id;
        lt_line_id(ln_line_count)                          := lt_input_line_id;
        lt_request_no(ln_line_count)                       := iot_order_tbl(ln_shori_count).line_request_no;
        lt_shipping_inventory_item_id(ln_line_count)       := iot_order_tbl(ln_shori_count).shipping_inventory_item_id;
        lt_shipping_item_code(ln_line_count)               := iot_order_tbl(ln_shori_count).shipping_item_code;
        lt_quantity(ln_line_count)                         := iot_order_tbl(ln_shori_count).quantity;
        lt_uom_code(ln_line_count)                         := iot_order_tbl(ln_shori_count).uom_code;
        lt_unit_price(ln_line_count)                       := iot_order_tbl(ln_shori_count).unit_price;
        lt_shippied_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).shipped_quantity;
        lt_designated_production_date(ln_line_count)       := iot_order_tbl(ln_shori_count).line_designated_prod_date;
        lt_based_request_quantity(ln_line_count)           := iot_order_tbl(ln_shori_count).based_request_quantity;
        lt_request_item_id(ln_line_count)                  := iot_order_tbl(ln_shori_count).request_item_id;
        lt_request_item_code(ln_line_count)                := iot_order_tbl(ln_shori_count).request_item_code;
        lt_ship_to_quantity(ln_line_count)                 := iot_order_tbl(ln_shori_count).ship_to_quantity;
        lt_futai_code(ln_line_count)                       := iot_order_tbl(ln_shori_count).futai_code;
        lt_designated_date(ln_line_count)                  := iot_order_tbl(ln_shori_count).designated_date;
        lt_move_number(ln_line_count)                      := iot_order_tbl(ln_shori_count).move_number;
        lt_po_number(ln_line_count)                        := iot_order_tbl(ln_shori_count).po_number;
        lt_cust_po_number(ln_line_count)                   := iot_order_tbl(ln_shori_count).line_cust_po_number;
        lt_pallet_quantity(ln_line_count)                  := iot_order_tbl(ln_shori_count).pallet_quantity;
        lt_layer_quantity(ln_line_count)                   := iot_order_tbl(ln_shori_count).layer_quantity;
        lt_case_quantity(ln_line_count)                    := iot_order_tbl(ln_shori_count).case_quantity;
        lt_weight(ln_line_count)                           := iot_order_tbl(ln_shori_count).weight;
        lt_capacity(ln_line_count)                         := iot_order_tbl(ln_shori_count).capacity;
        lt_pallet_qty(ln_line_count)                       := iot_order_tbl(ln_shori_count).pallet_qty;
        lt_pallet_weight(ln_line_count)                    := iot_order_tbl(ln_shori_count).pallet_weight;
        lt_reserved_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).reserved_quantity;
        lt_automanual_reserve_class(ln_line_count)         := iot_order_tbl(ln_shori_count).automanual_reserve_class;
        lt_warning_class(ln_line_count)                    := iot_order_tbl(ln_shori_count).warning_class;
        lt_warning_date(ln_line_count)                     := iot_order_tbl(ln_shori_count).warning_date;
        lt_line_description(ln_line_count)                 := iot_order_tbl(ln_shori_count).line_description;
-- Ver1.8 M.Hokkanji Start
        lt_rm_if_flg(ln_line_count)                        := gv_no;
        lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
        lt_shipping_result_if_flg(ln_line_count)           := gv_no;
--        lt_rm_if_flg(ln_line_count)                        := iot_order_tbl(ln_shori_count).rm_if_flg;
--        lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
--        lt_shipping_result_if_flg(ln_line_count)           := iot_order_tbl(ln_shori_count).shipping_result_if_flg;
-- Ver1.8 M.Hokkanji End
      END IF;
      -- 受注アドオンループ件数を+1
      ln_shori_count := ln_shori_count + 1;
    END LOOP order_line_data;
    --A3で取得したデータの場合現在のレコード番号を返す
    IF (gv_shori_kbn IN ('1','3') ) THEN
      gn_shori_count := ln_shori_count;
    END IF;
--
    IF (ln_order_line_count > 0) THEN --明細対象件数が0件以上の場合
      -- ***************************************
      -- ***       A8-受注作成API起動        ***
      -- ***************************************
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
      lt_action_request_tbl(1)                := OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    := OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).entity_id      := it_new_header_id;
      lt_action_request_tbl(1).request_type   := OE_GLOBALS.G_BOOK_ORDER;
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_order_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_order_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
  --
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (gv_shori_kbn = '4') THEN
      -- ********************************************************
      -- ***      訂正返品時受注明細アドオンに訂正データを登録***
      -- ********************************************************
      FORALL i IN 1..lt_order_line_id.COUNT
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
        VALUES (
           lt_order_line_id(i),              -- 受注明細アドオンID
           lt_order_header_id(i),            -- 受注ヘッダアドオンID
           lt_order_line_number(i),          -- 明細番号
           lt_header_id(i),                  -- 受注ヘッダID
           lt_line_id(i),                    -- 受注明細ID
           lt_request_no(i),                 -- 依頼No
           lt_shipping_inventory_item_id(i), -- 出荷品目ID
           lt_shipping_item_code(i),         -- 出荷品目
           lt_quantity(i),                   -- 数量
           lt_uom_code(i),                   -- 単位
           lt_unit_price(i),                 -- 単価
           lt_shippied_quantity(i),          -- 出荷実績数量
           lt_designated_production_date(i), -- 指定製造日
           lt_based_request_quantity(i),     -- 拠点依頼数量
           lt_request_item_id(i),            -- 依頼品目ID
           lt_request_item_code(i),          -- 依頼品目コード
           lt_ship_to_quantity(i),           -- 入庫実績数量
           lt_futai_code(i),                 -- 付帯コード
           lt_designated_date(i),            -- 指定日付(リーフ)
           lt_move_number(i),                -- 移動No
           lt_po_number(i),                  -- 発注No
           lt_cust_po_number(i),             -- 顧客発注
           lt_pallet_quantity(i),            -- パレット数
           lt_layer_quantity(i),             -- 段数
           lt_case_quantity(i),              -- ケース数
           lt_weight(i),                     -- 重量
           lt_capacity(i),                   -- 容積
           lt_pallet_qty(i),                 -- パレット枚数
           lt_pallet_weight(i),              -- パレット重量
           lt_reserved_quantity(i),          -- 引当数
           lt_automanual_reserve_class(i),   -- 自動手動引当区分
           'N',                              -- 削除フラグ
           lt_warning_class(i),              -- 警告区分
           lt_warning_date(i),               -- 警告日付
           lt_line_description(i),           -- 摘要
           lt_rm_if_flg(i),                  -- 倉替返品インタフェース済フラグ
           lt_shipping_request_if_flg(i),    -- 出荷依頼インタフェース済フラグ
           lt_shipping_result_if_flg(i),     -- 出荷実績インタフェース済フラグ
           gn_user_id,                       -- 作成者
           SYSDATE,                          -- 作成日
           gn_user_id,                       -- 最終更新者
           SYSDATE,                          -- 最終更新日
           gn_login_id,                      -- 最終更新ログイン
           gn_conc_request_id,               -- 要求ID
           gn_prog_appl_id,                  -- コンカレント・プログラム・アプリケーションID
           gn_conc_program_id,               -- コンカレント・プログラムID
           SYSDATE                           -- プログラム更新日
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_order_line_info;
  /***********************************************************************************
   * Procedure Name   : delivery_action_proc
   * Description      : A9ピックリリースAPI起動
   ***********************************************************************************/
  PROCEDURE delivery_action_proc(
    it_header_id    IN xxwsh_order_headers_all.header_id%TYPE, -- 受注ヘッダID
    ot_del_rows_tbl OUT NOCOPY WSH_UTIL_CORE.ID_TAB_TYPE,      -- 搬送ID Table
    ov_errbuf       OUT NOCOPY VARCHAR2,                       -- エラー・メッセージ--# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,                       -- リターン・コード--# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)                       -- ユーザーエラーメッセージ--# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delivery_action_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_release_mode                   CONSTANT VARCHAR2(15) := 'ONLINE';    -- ピックリリース実行パラメータ
    -- *** ローカル変数 ***
--
    lv_return_status                  VARCHAR2(1);                          -- APIの処理ステータス
    ln_msg_count                      NUMBER;                               -- APIのエラーメッセージ件数
    lv_msg_data                       VARCHAR2(2000);                       -- APIのエラーメッセージ
    lv_msg_buf                        VARCHAR2(2000);                       -- APIメッセージ統合用
    ln_msg_index_out                  NUMBER;                               -- APIのエラーメッセージ(INDEX)
    ln_count                          NUMBER;                               -- 件数カウント用
    ln_batch_id                       NUMBER;                               -- パッチID
    ln_request_id                     NUMBER;                               -- リクエストID
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_batch_info_rec                 WSH_PICKING_BATCHES_PUB.BATCH_INFO_REC;  -- ピックリリース用
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***       A9ピックリリースパッチ作成      ***
    -- *********************************************
    lt_batch_info_rec.order_header_id := it_header_id; -- 受注ヘッダIDを指定
    WSH_PICKING_BATCHES_PUB.CREATE_BATCH(
      p_api_version         => 1.0
    , p_init_msg_list       => FND_API.G_TRUE
    , x_return_status       => lv_return_status
    , x_msg_count           => ln_msg_count
    , x_msg_data            => lv_msg_data
    , p_batch_rec           => lt_batch_info_rec
    , x_batch_id            => ln_batch_id
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- エラーの場合
      IF (ln_msg_count > 0 ) THEN
        -- メッセージ件数が0より大きい場合エラーメッセージを出力
        <<message_loop>>
        FOR cnt IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --メッセージを出力し処理を強制終了する
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_2,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
    -- *********************************************
    -- ***       A9ピックリリースパッチ実行      ***
    -- *********************************************
    WSH_PICKING_BATCHES_PUB.RELEASE_BATCH(
      p_api_version         => 1.0
    , p_init_msg_list       => FND_API.G_TRUE
    , x_return_status       => lv_return_status
    , x_msg_count           => ln_msg_count
    , x_msg_data            => lv_msg_data
    , p_batch_id            => ln_batch_id
    , p_release_mode        => cv_release_mode
    , x_request_id          => ln_request_id
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- エラーの場合
      IF (ln_msg_count > 0 ) THEN
        -- メッセージ件数が0より大きい場合エラーメッセージを出力
        <<message_loop>>
        FOR cnt2 IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt2 ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --メッセージを出力し処理を強制終了する
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_6,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
    -- 搬送IDの取得
    SELECT wda.delivery_id
    INTO   ot_del_rows_tbl(1)
    FROM   wsh_delivery_details wdd,
           wsh_delivery_assignments wda
    WHERE  wdd.org_id = gn_org_id
    AND    wdd.batch_id = ln_batch_id
    AND    wdd.delivery_detail_id = wda.delivery_detail_id
    AND    ROWNUM = 1;
-- Ver1.18 M.Hokkanji Start
    IF (ot_del_rows_tbl(1) IS NULL ) THEN
      --メッセージを出力し処理を強制終了する
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh
                                           ,gv_msg_42a_026
                                           ,gv_tkn_request_no
                                           ,gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
-- Ver1.18 M.Hokkanji END
--
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END delivery_action_proc;
  /***********************************************************************************
   * Procedure Name   : get_lot_details
   * Description      : A10ロット情報取得
   ***********************************************************************************/
  PROCEDURE get_lot_details(
    it_order_line_tbl    IN order_line_type,          -- 受注明細情報格納配列
    it_revised_line_tbl  IN revised_line_type,        -- 訂正受注明細情報格納配列
    iv_standard_api_flag IN VARCHAR2,                 -- 標準API実行フラグ
    ot_ic_tran_rec_tbl   OUT NOCOPY ic_tran_rec_type, -- 在庫割当API用データ一時保存用配列
    ot_mov_line_id_tbl   OUT NOCOPY mov_line_id_type, -- 移動明細IDデータ一時保存用配列
    ov_errbuf            OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_details'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    cv_action_code_ins    CONSTANT VARCHAR2(6) := 'INSERT';
    -- *** ローカル変数 ***
    ln_count              NUMBER;                                -- 在庫割当API用データ一時保存用COUNT
    ln_mov_count          NUMBER;                                -- 移動明細ID一時保存用COUNT
--
    -- *** ローカル・カーソル ***
    CURSOR cur_move_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- 文書タイプ
                xmld.record_type_code,        -- レコードタイプ
                xmld.item_id,                 -- OPM品目ID
                xmld.item_code,               -- 品目
                xmld.lot_no,                  -- ロットNo
                xmld.lot_id,                  -- ロットID
                xmld.actual_date,             -- 実績日
                xmld.actual_quantity,         -- 実績数量
                xmld.automanual_reserve_class -- 自動手動引当区分
         FROM   xxinv_mov_lot_details xmld    -- 移動ロット詳細(アドオン)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20
         AND    xmld.actual_quantity <> 0;
    -- *** ローカル・カーソル ***
    CURSOR cur_revised_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- 文書タイプ
                xmld.record_type_code,        -- レコードタイプ
                xmld.item_id,                 -- OPM品目ID
                xmld.item_code,               -- 品目
                xmld.lot_no,                  -- ロットNo
                xmld.lot_id,                  -- ロットID
                xmld.actual_date,             -- 実績日
                xmld.actual_quantity,         -- 実績数量
                xmld.automanual_reserve_class -- 自動手動引当区分
         FROM   xxinv_mov_lot_details xmld    -- 移動ロット詳細(アドオン)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***       明細ごとにロット情報を取得      ***
    -- *********************************************
--
    ln_count     := 0;
    ln_mov_count := 0;
--
    IF (iv_standard_api_flag = '1') THEN
      <<order_line_data>>
      FOR i IN 1..it_order_line_tbl.COUNT LOOP  -- 明細の件数ループ
--
        <<move_lot_details_data>>
        FOR rec_move_lot_details IN cur_move_lot_details(it_order_line_tbl(i).order_line_id) LOOP
--
          ln_count := ln_count + 1;
--
          ot_ic_tran_rec_tbl(ln_count).action_code   := cv_action_code_ins;                  -- 予約動作コード;
          ot_ic_tran_rec_tbl(ln_count).line_id       := it_order_line_tbl(i).line_id;        -- 受注明細ID
          ot_ic_tran_rec_tbl(ln_count).lot_id        := rec_move_lot_details.lot_id;         -- ロットID
          ot_ic_tran_rec_tbl(ln_count).trans_qty     := rec_move_lot_details.actual_quantity;-- 実績数量
          ot_ic_tran_rec_tbl(ln_count).location      := it_order_line_tbl(i).deliver_from;   -- 出庫元保管場所
          ot_ic_tran_rec_tbl(ln_count).trans_um      := it_order_line_tbl(i).uom_code;       -- 単位
        END LOOP move_lot_details_data;
--
        -- 移動明細ID取得
        ln_mov_count := ln_mov_count + 1;
        SELECT wdv.move_order_line_id
        INTO   ot_mov_line_id_tbl(ln_mov_count)
        FROM   wsh_deliverables_v wdv
        WHERE  wdv.org_id = gn_org_id
        AND    wdv.source_line_id = it_order_line_tbl(i).line_id;
--
      END LOOP order_line_data;
    END IF;
--
    IF (gv_shori_kbn = '4') THEN
--
    -- 処理区分が訂正受注の場合返品用移動ロット詳細登録データを作成する
      <<revised_line_data>>
      FOR cnt IN 1..it_revised_line_tbl.COUNT LOOP  --明細の件数ループ
        <<revised_lot_details_data>>
        FOR revised_lot_details IN cur_revised_lot_details(it_revised_line_tbl(cnt).order_line_id) LOOP
          -- 処理区分が訂正返品の場合返品用移動ロット詳細登録データを作成する
          gn_lot_count                              := gn_lot_count +1;
--
          SELECT xxinv_mov_lot_s1.NEXTVAL  --ロット詳細ID
          INTO   gt_mov_lot_dtl_id(gn_lot_count)
          FROM   dual;
--
          gt_mov_line_id(gn_lot_count)              := it_revised_line_tbl(cnt).new_order_line_id;   -- 明細ID
          gt_document_type_code(gn_lot_count)       := revised_lot_details.document_type_code;       -- 文書タイプ
          gt_record_type_code(gn_lot_count)         := revised_lot_details.record_type_code;         -- レコードタイプ
          gt_item_id(gn_lot_count)                  := revised_lot_details.item_id;                  -- OPM品目ID
          gt_item_code(gn_lot_count)                := revised_lot_details.item_code;                -- 品目
          gt_lot_id(gn_lot_count)                   := revised_lot_details.lot_id;                   -- ロットID
          gt_lot_no(gn_lot_count)                   := revised_lot_details.lot_no;                   -- ロットNo
          gt_actual_date(gn_lot_count)              := revised_lot_details.actual_date;              -- 実績日
          gt_actual_quantity(gn_lot_count)          := revised_lot_details.actual_quantity;          -- 実績数量
          gt_automanual_reserve_class(gn_lot_count) := revised_lot_details.automanual_reserve_class; -- 自動手動引当区分
        END LOOP revised_lot_details_data;
--
      END LOOP revised_line_data;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END get_lot_details;
  /***********************************************************************************
   * Procedure Name   : set_allocate_opm_order
   * Description      : A11 在庫割当API起動
   ***********************************************************************************/
  PROCEDURE set_allocate_opm_order(
    it_ic_tran_rec_tbl IN  ic_tran_rec_type,        -- 在庫割当API用データ一時保存用配列
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_allocate_opm_order'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status      VARCHAR2(1);                           -- APIの処理ステータス
    ln_msg_count          NUMBER;                                -- APIのエラーメッセージ件数
    lv_msg_data           VARCHAR2(2000);                        -- APIのエラーメッセージ
    lv_msg_buf            VARCHAR2(2000);                        -- APIのエラーメッセージ(BUF)
    ln_msg_index_out      NUMBER;                                -- APIのエラーメッセージ(INDEX)
--
    -- *** ローカル・レコード ***
    lt_ic_tran_rec_type   GMI_OM_ALLOC_API_PUB.IC_TRAN_REC_TYPE; -- 在庫割当API用セット変数
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***     在庫割当API起動                   ***
    -- *********************************************
    <<allocate_opm_orders>>
    FOR om_cnt IN 1..it_ic_tran_rec_tbl.COUNT LOOP
      ln_msg_count := 0; --メッセージ件数を0に初期化
      --配列でパラメータを渡せないためそれぞれ値をセット
--
      lt_ic_tran_rec_type.action_code := it_ic_tran_rec_tbl(om_cnt).action_code; -- 予約動作コード
      lt_ic_tran_rec_type.line_id     := it_ic_tran_rec_tbl(om_cnt).line_id;     -- 受注明細ID
      lt_ic_tran_rec_type.lot_id      := it_ic_tran_rec_tbl(om_cnt).lot_id;      -- ロットID
      lt_ic_tran_rec_type.trans_qty   := it_ic_tran_rec_tbl(om_cnt).trans_qty;   -- 実績数量
      lt_ic_tran_rec_type.location    := it_ic_tran_rec_tbl(om_cnt).location;    -- 出庫元保管場所
      lt_ic_tran_rec_type.trans_um    := it_ic_tran_rec_tbl(om_cnt).trans_um;    -- 単位
--
      GMI_OM_ALLOC_API_PUB.ALLOCATE_OPM_ORDERS (
          p_api_version         => 1.0
        , p_init_msg_list       => FND_API.G_TRUE
        , p_commit              => FND_API.G_FALSE
        , p_tran_rec            => lt_ic_tran_rec_type
        , x_return_status       => lv_return_status
        , x_msg_count           => ln_msg_count
        , x_msg_data            => lv_msg_data
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            FND_MSG_PUB.GET( 
              p_msg_index      => cnt ,
              p_encoded        => 'F' ,
              p_data           => lv_msg_buf , 
              p_msg_index_out  => ln_msg_index_out
            );
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_1,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END LOOP allocate_opm_orders;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END set_allocate_opm_order;
  /***********************************************************************************
   * Procedure Name   : pick_confirm_proc
   * Description      : 移動オーダ取引処理
   ***********************************************************************************/
  PROCEDURE pick_confirm_proc(
    it_mov_line_id_tbl IN  mov_line_id_type,        -- 移動明細IDデータ一時保存用配列
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pick_confirm_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status      VARCHAR2(1);        -- APIの処理ステータス
    ln_msg_count          NUMBER;             -- APIのエラーメッセージ件数
    lv_msg_data           VARCHAR2(2000);     -- APIのエラーメッセージ
    lv_msg_buf            VARCHAR2(2000);     -- APIのエラーメッセージ(バッファ)
    ln_msg_index_out      NUMBER;             -- APIのエラーメッセージインデックス
    lt_mov_line_id        NUMBER;             -- 移動明細ID
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***     移動オーダ取引処理                ***
    -- *********************************************
    <<pick_confirm>>
    FOR pick_cnt IN 1..it_mov_line_id_tbl.COUNT LOOP
      ln_msg_count := 0; --メッセージ件数を0に初期化
--
      lt_mov_line_id := it_mov_line_id_tbl(pick_cnt);
--
      GMI_PICK_CONFIRM_PUB.PICK_CONFIRM (
          p_api_version         => 1.0
        , p_init_msg_list       => FND_API.G_TRUE
        , p_commit              => FND_API.G_FALSE
        , p_mo_line_id          => lt_mov_line_id
        , p_delivery_detail_id  => NULL
        , p_bk_ordr_if_no_alloc => gv_yes
        , x_return_status       => lv_return_status
        , x_msg_count           => ln_msg_count
        , x_msg_data            => lv_msg_data
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            FND_MSG_PUB.GET( 
              p_msg_index      => cnt ,
              p_encoded        => 'F' ,
              p_data           => lv_msg_buf , 
              p_msg_index_out  => ln_msg_index_out
            );
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_4,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END LOOP pick_confirm;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END pick_confirm_proc;
  /***********************************************************************************
   * Procedure Name   : confirm_proc
   * Description      : A12出荷確認API起動
   ***********************************************************************************/
  PROCEDURE confirm_proc(
    it_del_rows_tbl IN  WSH_UTIL_CORE.ID_TAB_TYPE,                -- 搬送ID Table
    it_shipped_date IN xxwsh_order_headers_all.shipped_date%TYPE, -- 出荷日
    ov_errbuf       OUT NOCOPY VARCHAR2,                          -- エラー・メッセージ
    ov_retcode      OUT NOCOPY VARCHAR2,                          -- リターン・コード
    ov_errmsg       OUT NOCOPY VARCHAR2)                          -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'confirm_proc'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_action_code CONSTANT VARCHAR2(15) := 'CONFIRM';   -- 出荷確認パラメータ
    cv_action_flag CONSTANT VARCHAR2(15) := 'S';         -- 全て出荷
--
    -- *** ローカル変数 ***
--
    lv_return_status              VARCHAR2(1);           -- APIの処理ステータス
    ln_msg_count                  NUMBER;                -- APIのエラーメッセージ件数
    lv_msg_data                   VARCHAR2(2000);        -- APIのエラーメッセージ
    lv_msg_buf                    VARCHAR2(2000);        -- APIメッセージ統合用
    ln_msg_index_out              NUMBER;                -- APIのエラーメッセージ・インデックス
    lt_trip_name                  wsh_trips.name%TYPE;
    ln_trip_id                    NUMBER;
-- 2008/10/10 H.Itou Add Start 統合テスト指摘116
    lv_sc_defer_interface_flag    VARCHAR2(1);           -- 出荷確認APIのINパラメータ.インターフェースTRIPSTOPの遅延
-- 2008/10/10 H.Itou Add End
    -- *** ローカル・カーソル ***
--
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
-- 2008/10/10 H.Itou Add Start 統合テスト指摘116
    -- 入力パラメータ.依頼NoがNULLの場合、コンカレント起動
    IF (gt_request_no IS NULL) THEN
      -- 出荷確認APIのINパラメータ.インターフェースTRIPSTOPの遅延に「Y」を渡す。
      lv_sc_defer_interface_flag := gv_yes;
--
    -- 入力パラメータ.依頼NoがNULLでない場合、画面からの起動
    ELSE
      -- 出荷確認APIのINパラメータ.インターフェースTRIPSTOPの遅延に「N」を渡す。
      lv_sc_defer_interface_flag := gv_no;
    END IF;
-- 2008/10/10 H.Itou Add End
--
    -- *********************************************
    -- ***       A12出荷確認API起動         ***
    -- *********************************************
    WSH_DELIVERIES_PUB.DELIVERY_ACTION(
      p_api_version_number      => 1.0
    , p_init_msg_list           => FND_API.G_TRUE
    , x_return_status           => lv_return_status
    , x_msg_count               => ln_msg_count
    , x_msg_data                => lv_msg_data
    , p_action_code             => cv_action_code   -- 出荷確認
    , p_delivery_id             => it_del_rows_tbl(1)
    , p_sc_action_flag          => cv_action_flag   -- すべて出荷
    , p_sc_intransit_flag       => gv_yes           -- 輸送行程のステータスを輸送中に
    , p_sc_close_trip_flag      => gv_yes           -- 輸送行程をクローズ
    , p_sc_stage_del_flag       => gv_no
-- 2008/10/10 H.Itou Mod Start 統合テスト指摘116
--    , p_sc_defer_interface_flag => gv_no            -- インターフェースTRIPSTOPの遅延
    , p_sc_defer_interface_flag => lv_sc_defer_interface_flag -- インターフェースTRIPSTOPの遅延
-- 2008/10/10 H.Itou Mod End
    , p_sc_actual_dep_date      => it_shipped_date  -- 出発日
    , x_trip_id                 => ln_trip_id
    , x_trip_name               => lt_trip_name
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- エラーの場合
      IF (ln_msg_count > 0 ) THEN
        -- メッセージ件数が0より大きい場合エラーメッセージを出力
        <<message_loop>>
        FOR cnt IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --メッセージを出力し処理を強制終了する
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_5,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END confirm_proc;
--
  /***********************************************************************************
   * Procedure Name   : create_rma_order_header_info
   * Description      : A13RMA受注ヘッダ情報の登録
   ***********************************************************************************/
  PROCEDURE create_rma_order_header_info(
    iot_order_tbl          
        IN OUT order_tbl,                                        -- 受注情報格納配列
    ot_new_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE, -- 赤用新受注ヘッダアドオンID
    ot_new_header_id
        OUT NOCOPY xxwsh_order_headers_all.header_id%TYPE,       -- 赤用新受注ヘッダID
    ot_site_use_id
        OUT NOCOPY hz_cust_site_uses_all.site_use_id%TYPE,       -- 受入取引処理用使用目的ID
    ov_standard_api_flag
        OUT NOCOPY NUMBER,                                       -- 標準API実行フラグ
    on_gen_count
        OUT NOCOPY NUMBER,                                       -- 現在のデータの位置を保持
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                     -- エラー・メッセージ
    ov_retcode
        OUT NOCOPY VARCHAR2,                                     -- リターン・コード
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                     -- ユーザー・エラー・メッセージ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_rma_order_header_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- 2008/12/15 v1.10 T.Yoshimoto Add Start
    lv_log                          VARCHAR2(32767); -- ログ出力用変数
    -- WHOカラム
    ln_user_id                      NUMBER;          -- ログインしているユーザーのID取得
    ln_login_id                     NUMBER;          -- 最終更新ログイン
    ln_conc_request_id              NUMBER;          -- 要求ID
    ln_prog_appl_id                 NUMBER;          -- プログラム・アプリケーションID
    ln_conc_program_id              NUMBER;          -- プログラムID
    ld_sysdate                      DATE;            -- システム現在日付
-- 2008/12/15 v1.10 T.Yoshimoto Add End
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status           VARCHAR2(1) ;                                 -- APIの処理ステータス
    ln_msg_count               NUMBER;                                       -- APIのエラーメッセージ件数
    lv_msg_data                VARCHAR2(2000) ;                              -- APIのエラーメッセージ
    lv_msg_buf                 VARCHAR2(2000);                               -- APIメッセージ統合用
    lt_new_order_header_id     xxwsh_order_headers_all.order_header_id%TYPE; -- 新受注ヘッダアドオンID
    lt_site_use_id             hz_cust_site_uses_all.site_use_id%TYPE;       -- 使用目的ID
    ln_shori_count             NUMBER;                                       -- 処理位置件数
    ln_line_count              NUMBER;                                       -- 明細件数(実績数量が0以上)
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_header_rec              OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec          OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl          OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl      OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl    OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl      OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl      OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_tbl                OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_val_tbl            OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl            OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl        OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl      OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl        OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl        OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl          OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl      OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    --A3で取得したデータかA5で取得したデータかによりレコードの基準値が異なる
    IF (gv_shori_kbn IN ('2','4') ) THEN
      ln_shori_count := gn_shori_count;
    ELSE
      ln_shori_count := 1;
    END IF;
--
    on_gen_count := ln_shori_count; -- 明細作成処理に現在の位置を渡すため
    -- 受注明細作成対象件数を調査
    SELECT count(xola.order_line_id)
    INTO   ln_line_count
    FROM   xxwsh_order_lines_all xola
    WHERE  xola.order_header_id = iot_order_tbl(ln_shori_count).order_header_id
    AND    NVL(xola.delete_flag,gv_no) = gv_no
    AND    NVL(xola.shipped_quantity,0) <> 0;
--
    IF (ln_line_count > 0 ) THEN
      ov_standard_api_flag := '1';--標準API実行フラグに1(実行)をセット
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
      -- API用変数に初期値をセット
      lt_header_rec                         := OE_ORDER_PUB.G_MISS_HEADER_REC;
      lt_line_tbl(1)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_header_rec.operation               := OE_GLOBALS.G_OPR_CREATE;                                    --[CREATE]
      lt_header_rec.sold_to_org_id          := iot_order_tbl(ln_shori_count).cust_account_id;              -- 顧客
      lt_header_rec.org_id                  := gn_org_id;                                                  -- 営業単位
      lt_header_rec.order_type_id           := iot_order_tbl(ln_shori_count).transaction_type_id;          -- 受注タイプをセット
      lt_header_rec.ordered_date            := iot_order_tbl(ln_shori_count).ordered_date;                 -- 受注日
  --
      IF (iot_order_tbl(ln_shori_count).shipping_shikyu_class <> gv_ship_class_2) THEN 
        -- 出荷支給区分が支給依頼以外の場合
        lt_header_rec.ship_to_party_site_id := iot_order_tbl(ln_shori_count).result_deliver_to_id;         -- 出荷先ID
  --
        -- 使用目的IDを取得
        BEGIN
  --
          SELECT xcasv.site_use_id
          INTO   lt_site_use_id
          FROM   xxcmn_cust_acct_sites_v xcasv
          WHERE  xcasv.party_site_id = iot_order_tbl(ln_shori_count).result_deliver_to_id;
  --
          ot_site_use_id := lt_site_use_id;
  --
        EXCEPTION
          WHEN OTHERS THEN
            --メッセージを出力し処理を強制終了する
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_024,
                                                  gv_tkn_message_tokun,
                                                  gv_message_tokun2,
                                                  gv_tkn_search,
                                                  iot_order_tbl(ln_shori_count).result_deliver_to_id
            );
            RAISE global_api_expt;
        END;
  --
      ELSE
  --
        -- 出荷支給区分が支給依頼の場合主フラグが'Y'のデータを取得
        BEGIN
  --
          SELECT xcasv.site_use_id
          INTO   lt_site_use_id
          FROM   xxcmn_cust_acct_sites_v xcasv
          WHERE  xcasv.cust_account_id = iot_order_tbl(ln_shori_count).cust_account_id
          AND    xcasv.primary_flag = gv_yes;
  --
          ot_site_use_id := lt_site_use_id;
  --
        EXCEPTION
          WHEN OTHERS THEN
            --メッセージを出力し処理を強制終了する
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_024,
                                                  gv_tkn_message_tokun,
                                                  gv_message_tokun1,
                                                  gv_tkn_search,
                                                  iot_order_tbl(ln_shori_count).cust_account_id
            );
            RAISE global_api_expt;
        END;
  --
      END IF;
  --
      lt_header_rec.shipping_instructions   := iot_order_tbl(ln_shori_count).shipping_instructions;                       -- 出荷指示
      lt_header_rec.cust_po_number          := iot_order_tbl(ln_shori_count).cust_po_number;                              -- 顧客発注
      lt_header_rec.ship_from_org_id        := iot_order_tbl(ln_shori_count).mtl_organization_id;                         -- 在庫組織ID
      lt_header_rec.attribute1              := iot_order_tbl(ln_shori_count).request_no;                                  -- 依頼No
      lt_header_rec.attribute2              := iot_order_tbl(ln_shori_count).delivery_no;                                 -- 配送No
      lt_header_rec.attribute3              := iot_order_tbl(ln_shori_count).result_freight_carrier_code;                 -- 運送業者_実績
      lt_header_rec.attribute4              := iot_order_tbl(ln_shori_count).result_shipping_method_code;                 -- 配送区分_実績
      lt_header_rec.attribute6              := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_ship_date,'YYYY/MM/DD');    -- 出荷予定日
      lt_header_rec.attribute7              := iot_order_tbl(ln_shori_count).head_sales_branch;                           -- 管轄拠点
      lt_header_rec.attribute8              := iot_order_tbl(ln_shori_count).deliver_from;                                -- 出荷元
      lt_header_rec.attribute9              := TO_CHAR(iot_order_tbl(ln_shori_count).shipped_date,'YYYY/MM/DD');          -- 出荷日
      lt_header_rec.attribute10             := TO_CHAR(iot_order_tbl(ln_shori_count).arrival_date,'YYYY/MM/DD');          -- 着荷日
      lt_header_rec.attribute11             := iot_order_tbl(ln_shori_count).performance_management_dept;                 -- 成績管理部署
      lt_header_rec.attribute12             := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_arrival_date,'YYYY/MM/DD'); -- 着荷予定日
--
-- 2008/12/15 v1.10 T.Yoshimoto Add Start 検証用
      --==============================================================
      -- 検証用ログ
      --==============================================================
      -- WHOカラム情報取得
      ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
      ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
      ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
      ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
      ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
      ld_sysdate           := SYSDATE;                      -- システム現在日付
--
      BEGIN
        lv_log := '【XXWSH42A-A13RMA(標準API_PARAMETER)】'
               || ' ユーザID/'        || ln_user_id
               || ' 要求ID/'          || ln_conc_request_id
               || ' プログラムID/'    || ln_conc_program_id;
--
        lv_log :=  lv_log || CHR(10)
               || '　【出荷指示】'      || lt_header_rec.shipping_instructions || CHR(10)        -- 出荷指示
               || '　【顧客発注】'      || lt_header_rec.cust_po_number        || CHR(10)        -- 顧客発注
               || '　【在庫組織ID】'    || lt_header_rec.ship_from_org_id      || CHR(10)        -- 在庫組織ID
               || '　【依頼No】'        || lt_header_rec.attribute1            || CHR(10)        -- 依頼No
               || '　【配送No】'        || lt_header_rec.attribute2            || CHR(10)        -- 配送No
               || '　【運送業者_実績】' || lt_header_rec.attribute3            || CHR(10)        -- 運送業者_実績
               || '　【配送区分_実績】' || lt_header_rec.attribute4            || CHR(10)        -- 配送区分_実績
               || '　【出荷予定日】'    || lt_header_rec.attribute6            || CHR(10)        -- 出荷予定日
               || '　【管轄拠点】'      || lt_header_rec.attribute7            || CHR(10)        -- 管轄拠点
               || '　【出荷元】'        || lt_header_rec.attribute8            || CHR(10)        -- 出荷元
               || '　【出荷日】'        || lt_header_rec.attribute9            || CHR(10)        -- 出荷日
               || '　【着荷日】'        || lt_header_rec.attribute10           || CHR(10)        -- 着荷日
               || '　【成績管理部署】'  || lt_header_rec.attribute11           || CHR(10)        -- 成績管理部署
               || '　【着荷予定日】'    || lt_header_rec.attribute12;                            -- 着荷予定日
--
       FND_LOG.STRING('6', gv_pkg_name || '.' || cv_prg_name, SUBSTRB(lv_log, 1, 4000));
--
      EXCEPTION
        WHEN  OTHERS THEN
          NULL;
      END;
  --
-- 2008/12/15 v1.10 T.Yoshimoto Add End 検証用
--
      -- ***************************************
      -- ***       A13-RMA受注作成API起動        ***
      -- ***************************************
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
  --
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
--
      ot_new_header_id := lt_header_rec.header_id;     -- 受注ヘッダID
      IF (gv_shori_kbn IN ('2','4') ) THEN
        -- 受注ヘッダID更新用のデータに登録する
        gt_header_id := lt_header_rec.header_id;       -- 受注ヘッダID
      END IF;
    ELSE
      ov_standard_api_flag := '0'; --標準API実行フラグに0(実行しない)をセット
    END IF;
--
    ot_new_order_header_id := iot_order_tbl(ln_shori_count).order_header_id; -- 受注ヘッダアドオンID
--
    IF (gv_shori_kbn = '3') THEN
      --訂正受注で受注ヘッダ登録以前の場合受注ヘッダアドオンにデータを登録
--
      SELECT xxwsh_order_headers_all_s1.NEXTVAL
      INTO   lt_new_order_header_id
      FROM   dual;
--
      ot_new_order_header_id       := lt_new_order_header_id;
--
-- 2008/12/15 v1.10 T.Yoshimoto Add Start 検証用
      --==============================================================
      -- 検証用ログ
      --==============================================================
      -- WHOカラム情報取得
      ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
      ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
      ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
      ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
      ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
      ld_sysdate           := SYSDATE;                      -- システム現在日付
--
      BEGIN
        lv_log := '【XXWSH42A-A13RMA(受注ﾍｯﾀﾞｱﾄﾞｵﾝ_PARAMETER)】'
            || ' ユーザID/'        || ln_user_id
            || ' 要求ID/'          || ln_conc_request_id
            || ' プログラムID/'    || ln_conc_program_id;
--
        lv_log :=  lv_log || CHR(10)
            || '【受注ﾍｯﾀﾞｱﾄﾞｵﾝID】' || lt_new_order_header_id                            || CHR(10)        -- 受注明細ID
            || '【受注ﾀｲﾌﾟID】'      || iot_order_tbl(ln_shori_count).transaction_type_id || CHR(10)        -- CREATE
            || '【受注ﾍｯﾀﾞID】'      || lt_header_rec.header_id                           || CHR(10)        -- 受注ヘッダID
            || '【出荷日】'          || iot_order_tbl(ln_shori_count).shipped_date        || CHR(10)        -- 出荷品目ID
            || '【着荷日】'          || iot_order_tbl(ln_shori_count).arrival_date;                         -- 出荷実績数量
--
       FND_LOG.STRING('6', gv_pkg_name || '.' || cv_prg_name, SUBSTRB(lv_log, 1, 4000));
--
      EXCEPTION
        WHEN  OTHERS THEN
          NULL;
      END;
--
-- 2008/12/15 v1.10 T.Yoshimoto Add End 検証用
--
      INSERT INTO xxwsh_order_headers_all
        (order_header_id,                -- 受注ヘッダアドオンID
         order_type_id,                  -- 受注タイプID
         organization_id,                -- 組織ID
         header_id,                      -- 受注ヘッダID
         latest_external_flag,           -- 最新フラグ
         ordered_date,                   -- 受注日
         customer_id,                    -- 顧客ID
         customer_code,                  -- 顧客
         deliver_to_id,                  -- 出荷先ID
         deliver_to,                     -- 出荷先
         shipping_instructions,          -- 出荷指示
         career_id,                      -- 運送業者ID
         freight_carrier_code,           -- 運送業者
         shipping_method_code,           -- 配送区分
         cust_po_number,                 -- 顧客発注
         price_list_id,                  -- 価格表
         request_no,                     -- 依頼No
         req_status,                     -- ステータス
         delivery_no,                    -- 配送No
         prev_delivery_no,               -- 前回配送No
         schedule_ship_date,             -- 出荷予定日
         schedule_arrival_date,          -- 着荷予定日
         mixed_no,                       -- 混載元No
         collected_pallet_qty,           -- パレット回収枚数
         confirm_request_class,          -- 物流担当確認依頼区分
         freight_charge_class,           -- 運賃区分
         shikyu_instruction_class,       -- 支給出庫指示区分
         shikyu_inst_rcv_class,          -- 支給指示受領区分
         amount_fix_class,               -- 有償金額確定区分
         takeback_class,                 -- 引取区分
         deliver_from_id,                -- 出荷元ID
         deliver_from,                   -- 出荷元保管場所
         head_sales_branch,              -- 管轄拠点
         input_sales_branch,             -- 入力拠点
         po_no,                          -- 発注No
         prod_class,                     -- 商品区分
         item_class,                     -- 品目区分
         no_cont_freight_class,          -- 契約外運賃区分
         arrival_time_from,              -- 着荷時間FROM
         arrival_time_to,                -- 着荷時間TO
         designated_item_id,             -- 製造品目ID
         designated_item_code,           -- 製造品目
         designated_production_date,     -- 製造日
         designated_branch_no,           -- 製造枝番
         slip_number,                    -- 送り状No
         sum_quantity,                   -- 合計数量
         small_quantity,                 -- 小口個数
         label_quantity,                 -- ラベル枚数
         loading_efficiency_weight,      -- 重量積載効率
         loading_efficiency_capacity,    -- 容積積載効率
         based_weight,                   -- 基本重量
         based_capacity,                 -- 基本容積
         sum_weight,                     -- 積載重量合計
         sum_capacity,                   -- 積載容積合計
         mixed_ratio,                    -- 混載率
         pallet_sum_quantity,            -- パレット合計枚数
         real_pallet_quantity,           -- パレット実績枚数
         sum_pallet_weight,              -- 合計パレット重量
         order_source_ref,               -- 受注ソース参照
         result_freight_carrier_id,      -- 運送業者_実績ID
         result_freight_carrier_code,    -- 運送業者_実績
         result_shipping_method_code,    -- 配送区分_実績
         result_deliver_to_id,           -- 出荷先_実績ID
         result_deliver_to,              -- 出荷先_実績
         shipped_date,                   -- 出荷日
         arrival_date,                   -- 着荷日
         weight_capacity_class,          -- 重量容積区分
         actual_confirm_class,           -- 実績計上済区分
         notif_status,                   -- 通知ステータス
         prev_notif_status,              -- 前回通知ステータス
         notif_date,                     -- 確定通知実施日時
         new_modify_flg,                 -- 新規修正フラグ
         process_status,                 -- 処理経過ステータス
         performance_management_dept,    -- 成績管理部署
         instruction_dept,               -- 指示部署
         transfer_location_id,           -- 振替先ID
         transfer_location_code,         -- 振替先
         mixed_sign,                     -- 混載記号
         screen_update_date,             -- 画面更新日時
         screen_update_by,               -- 画面更新者
         tightening_date,                -- 出荷依頼締め日時
         vendor_id,                      -- 取引先ID
         vendor_code,                    -- 取引先
         vendor_site_id,                 -- 取引先サイトID
         vendor_site_code,               -- 取引先サイト
         registered_sequence,            -- 登録順序
         tightening_program_id,          -- 締めコンカレントID
         corrected_tighten_class,        -- 締め後修正区分
         created_by,                     -- 作成者
         creation_date,                  -- 作成日
         last_updated_by,                -- 最終更新者
         last_update_date,               -- 最終更新日
         last_update_login,              -- 最終更新ログイン
         request_id,                     -- 要求ID
         program_application_id,         -- コンカレント・プログラム・アプリケーションID
         program_id,                     -- コンカレント・プログラムID
         program_update_date             -- プログラム更新日
        )VALUES
        (lt_new_order_header_id,
         iot_order_tbl(ln_shori_count).transaction_type_id,
         iot_order_tbl(ln_shori_count).organization_id,
         lt_header_rec.header_id,
         gv_no,
         iot_order_tbl(ln_shori_count).ordered_date,
         iot_order_tbl(ln_shori_count).customer_id,
         iot_order_tbl(ln_shori_count).customer_code,
         iot_order_tbl(ln_shori_count).deliver_to_id,
         iot_order_tbl(ln_shori_count).deliver_to,
         iot_order_tbl(ln_shori_count).shipping_instructions,
         iot_order_tbl(ln_shori_count).career_id,
         iot_order_tbl(ln_shori_count).freight_carrier_code,
         iot_order_tbl(ln_shori_count).shipping_method_code,
         iot_order_tbl(ln_shori_count).cust_po_number,
         iot_order_tbl(ln_shori_count).price_list_id,
         iot_order_tbl(ln_shori_count).request_no,
         iot_order_tbl(ln_shori_count).req_status,
         iot_order_tbl(ln_shori_count).delivery_no,
         iot_order_tbl(ln_shori_count).prev_delivery_no,
         iot_order_tbl(ln_shori_count).schedule_ship_date,
         iot_order_tbl(ln_shori_count).schedule_arrival_date,
         iot_order_tbl(ln_shori_count).mixed_no,
         iot_order_tbl(ln_shori_count).collected_pallet_qty,
         iot_order_tbl(ln_shori_count).confirm_request_class,
         iot_order_tbl(ln_shori_count).freight_charge_class,
         iot_order_tbl(ln_shori_count).shikyu_instruction_class,
         iot_order_tbl(ln_shori_count).shikyu_inst_rcv_class,
         iot_order_tbl(ln_shori_count).amount_fix_class,
         iot_order_tbl(ln_shori_count).takeback_class,
         iot_order_tbl(ln_shori_count).deliver_from_id,
         iot_order_tbl(ln_shori_count).deliver_from,
         iot_order_tbl(ln_shori_count).head_sales_branch,
         iot_order_tbl(ln_shori_count).input_sales_branch,
         iot_order_tbl(ln_shori_count).po_no,
         iot_order_tbl(ln_shori_count).prod_class,
         iot_order_tbl(ln_shori_count).item_class,
         iot_order_tbl(ln_shori_count).no_cont_freight_class,
         iot_order_tbl(ln_shori_count).arrival_time_from,
         iot_order_tbl(ln_shori_count).arrival_time_to,
         iot_order_tbl(ln_shori_count).designated_item_id,
         iot_order_tbl(ln_shori_count).designated_item_code,
         iot_order_tbl(ln_shori_count).designated_production_date,
         iot_order_tbl(ln_shori_count).designated_branch_no,
         iot_order_tbl(ln_shori_count).slip_number,
         iot_order_tbl(ln_shori_count).sum_quantity,
         iot_order_tbl(ln_shori_count).small_quantity,
         iot_order_tbl(ln_shori_count).label_quantity,
         iot_order_tbl(ln_shori_count).loading_efficiency_weight,
         iot_order_tbl(ln_shori_count).loading_efficiency_capacity,
         iot_order_tbl(ln_shori_count).based_weight,
         iot_order_tbl(ln_shori_count).based_capacity,
         iot_order_tbl(ln_shori_count).sum_weight,
         iot_order_tbl(ln_shori_count).sum_capacity,
         iot_order_tbl(ln_shori_count).mixed_ratio,
         iot_order_tbl(ln_shori_count).pallet_sum_quantity,
         iot_order_tbl(ln_shori_count).real_pallet_quantity,
         iot_order_tbl(ln_shori_count).sum_pallet_weight,
         iot_order_tbl(ln_shori_count).order_source_ref,
         iot_order_tbl(ln_shori_count).result_freight_carrier_id,
         iot_order_tbl(ln_shori_count).result_freight_carrier_code,
         iot_order_tbl(ln_shori_count).result_shipping_method_code,
         iot_order_tbl(ln_shori_count).result_deliver_to_id,
         iot_order_tbl(ln_shori_count).result_deliver_to,
         iot_order_tbl(ln_shori_count).shipped_date,
         iot_order_tbl(ln_shori_count).arrival_date,
         iot_order_tbl(ln_shori_count).weight_capacity_class,
         gv_yes,
         iot_order_tbl(ln_shori_count).notif_status,
         iot_order_tbl(ln_shori_count).prev_notif_status,
         iot_order_tbl(ln_shori_count).notif_date,
         iot_order_tbl(ln_shori_count).new_modify_flg,
         iot_order_tbl(ln_shori_count).process_status,
         iot_order_tbl(ln_shori_count).performance_management_dept,
         iot_order_tbl(ln_shori_count).instruction_dept,
         iot_order_tbl(ln_shori_count).transfer_location_id,
         iot_order_tbl(ln_shori_count).transfer_location_code,
         iot_order_tbl(ln_shori_count).mixed_sign,
         iot_order_tbl(ln_shori_count).screen_update_date,
         iot_order_tbl(ln_shori_count).screen_update_by,
         iot_order_tbl(ln_shori_count).tightening_date,
         iot_order_tbl(ln_shori_count).vendor_id,
         iot_order_tbl(ln_shori_count).vendor_code,
         iot_order_tbl(ln_shori_count).vendor_site_id,
         iot_order_tbl(ln_shori_count).vendor_site_code,
         iot_order_tbl(ln_shori_count).registered_sequence,
         iot_order_tbl(ln_shori_count).tightening_program_id,
         iot_order_tbl(ln_shori_count).corrected_tighten_class,
         gn_user_id,
         SYSDATE,
         gn_user_id,
         SYSDATE,
         gn_login_id,
         gn_conc_request_id,
         gn_prog_appl_id,
         gn_conc_program_id,
         SYSDATE
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_rma_order_header_info;
  /***********************************************************************************
   * Procedure Name   : create_rma_order_line_info
   * Description      : A14RMA受注明細レコード作成、A15RMA受注明細登録
   ***********************************************************************************/
  PROCEDURE create_rma_order_line_info(
    it_bef_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE,   -- 前処理受注ヘッダアドオンID
    it_new_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE,   -- 赤用新受注ヘッダアドオンID
    it_new_header_id
        IN xxwsh_order_headers_all.header_id%TYPE,         -- 赤用新受注ヘッダID
    it_site_use_id
        IN hz_cust_site_uses_all.site_use_id%TYPE,         -- 受入取引処理用使用目的ID
    in_gen_count
        IN NUMBER,                                         -- 受注情報格納配列の現在の位置
    iot_order_tbl
        IN OUT order_tbl,                                  -- 受注情報格納配列
    ot_order_line_tbl
        OUT NOCOPY order_line_type,                        -- 受注明細情報格納配列
    ot_revised_line_tbl
        OUT NOCOPY revised_line_type,                      -- 訂正受注明細情報格納配列
    ov_errbuf
        OUT NOCOPY VARCHAR2,                               -- エラー・メッセージ      --# 固定 #
    ov_retcode
        OUT NOCOPY VARCHAR2,                               -- リターン・コード        --# 固定 #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                               -- ユーザーエラーメッセージ--# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_rma_order_line_info'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- 2008/12/15 v1.10 T.Yoshimoto Add Start
    lv_log                          VARCHAR2(32767); -- ログ出力用変数
    -- WHOカラム
    ln_user_id                      NUMBER;          -- ログインしているユーザーのID取得
    ln_login_id                     NUMBER;          -- 最終更新ログイン
    ln_conc_request_id              NUMBER;          -- 要求ID
    ln_prog_appl_id                 NUMBER;          -- プログラム・アプリケーションID
    ln_conc_program_id              NUMBER;          -- プログラムID
    ld_sysdate                      DATE;            -- システム現在日付
-- 2008/12/15 v1.10 T.Yoshimoto Add End
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    ln_line_count                 NUMBER;                               -- 明細件数
    lv_return_status              VARCHAR2(1) ;                         -- APIの処理ステータス
    ln_msg_count                  NUMBER;                               -- APIのエラーメッセージ件数
    lv_msg_data                   VARCHAR2(2000) ;                      -- APIのエラーメッセージ
    lv_msg_buf                    VARCHAR2(2000);                       -- APIメッセージ統合用
    ln_shori_count                NUMBER;                               -- 受注情報の処理件数
    lt_input_line_id              oe_order_lines_all.line_id%TYPE;      -- 登録用受注明細ID
    ln_order_line_count           NUMBER;                               -- 受注明細登録件数
    -- *** アドオン登録用 ***
    lt_order_line_id              ol_order_line_id_type;                -- 受注明細アドオンID
    lt_order_header_id            ol_order_header_id_type;              -- 受注ヘッダアドオンID
    lt_order_line_number          ol_order_line_number_type;            -- 明細番号
    lt_header_id                  ol_header_id_type;                    -- 受注ヘッダID
    lt_line_id                    ol_line_id_type;                      -- 受注明細ID
    lt_request_no                 ol_request_no_type;                   -- 依頼No
    lt_shipping_inventory_item_id ol_ship_inv_item_id_type;             -- 出荷品目ID
    lt_shipping_item_code         ol_ship_item_code_type;               -- 出荷品目
    lt_quantity                   ol_quantity_type;                     -- 数量
    lt_uom_code                   ol_uom_code_type;                     -- 単位
    lt_unit_price                 ol_unit_price_type;                   -- 単価
    lt_shippied_quantity          ol_shipped_quantity_type;             -- 出荷実績数量
    lt_designated_production_date ol_desi_prod_date_type;               -- 指定製造日
    lt_based_request_quantity     ol_base_req_quantity_type;            -- 拠点依頼数量
    lt_request_item_id            ol_request_item_id_type;              -- 依頼品目ID
    lt_request_item_code          ol_request_item_code_type;            -- 依頼品目コード
    lt_ship_to_quantity           ol_ship_to_quantity_type;             -- 入庫実績数量
    lt_futai_code                 ol_futai_code_type;                   -- 付帯コード
    lt_designated_date            ol_designated_date_type;              -- 指定日付(リーフ)
    lt_move_number                ol_move_number_type;                  -- 移動No
    lt_po_number                  ol_po_number_type;                    -- 発注No
    lt_cust_po_number             ol_cust_po_number_type;               -- 顧客発注
    lt_pallet_quantity            ol_pallet_quantity_type;              -- パレット数
    lt_layer_quantity             ol_layer_quantity_type;               -- 段数
    lt_case_quantity              ol_case_quantity_type;                -- ケース数
    lt_weight                     ol_weight_type;                       -- 重量
    lt_capacity                   ol_capacity_type;                     -- 容積
    lt_pallet_qty                 ol_pallet_qty_type;                   -- パレット枚数
    lt_pallet_weight              ol_pallet_weight_type;                -- パレット重量
    lt_reserved_quantity          ol_reserved_quantity_type;            -- 引当数
    lt_automanual_reserve_class   ol_auto_rese_class_type;              -- 自動手動引当区分
    lt_warning_class              ol_warning_class_type;                -- 警告区分
    lt_warning_date               ol_warning_date_type;                 -- 警告日付
    lt_line_description           ol_line_description_type;             -- 摘要
    lt_rm_if_flg                  ol_rm_if_flg_type;                    -- 倉替返品IF済フラグ
    lt_shipping_request_if_flg    ol_ship_requ_if_flg_type;             -- 出荷依頼IF済フラグ
    lt_shipping_result_if_flg     ol_ship_resu_if_flg_type;             -- 出荷実績IF済フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- 受注明細登録用配列
    lt_order_line_tbl             OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_header_rec                 OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec             OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl             OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl         OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl       OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl         OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl       OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl         OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl     OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_val_tbl               OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl               OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl           OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl         OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl           OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl         OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl           OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl       OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl             OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl         OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl         OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ***************************************
    -- ***       RMA受注アドオン情報取得   ***
    -- ***************************************
    ln_line_count := 0;             -- 明細件数を初期化
    ln_order_line_count := 0;
    ln_shori_count := in_gen_count;
    <<order_line_data>> --受注作成情報ループ処理
    LOOP
      IF ((ln_shori_count > iot_order_tbl.LAST) OR
          (iot_order_tbl(ln_shori_count).order_header_id <> it_bef_order_header_id)) THEN
        EXIT; -- 現在のループのデータが存在しない場合もしくは前のヘッダIDと現在のヘッダIDが異なる場合ループを抜ける
      END IF;
      lt_input_line_id := NULL;   -- セット用受注明細IDを初期化
      IF (iot_order_tbl(ln_shori_count).shipped_quantity <> 0 )THEN
        ln_order_line_count := ln_order_line_count + 1;
--
        -- 受注明細登録API用データ
        lt_order_line_tbl(ln_order_line_count)                      := OE_ORDER_PUB.G_MISS_LINE_REC;                             -- 受注明細変数の初期化
        lt_order_line_tbl(ln_order_line_count).operation            := OE_GLOBALS.G_OPR_CREATE;
        -- 受注明細登録API用データ
        SELECT oe_order_lines_s.NEXTVAL
        INTO   lt_order_line_tbl(ln_order_line_count).line_id
        FROM   DUAL;
        lt_input_line_id                                            := lt_order_line_tbl(ln_order_line_count).line_id;
        lt_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- 受注ヘッダID
        lt_order_line_tbl(ln_order_line_count).inventory_item_id    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- 出荷品目ID
        lt_order_line_tbl(ln_order_line_count).ordered_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- 出荷実績数量
        lt_order_line_tbl(ln_order_line_count).schedule_ship_date   := iot_order_tbl(ln_shori_count).schedule_ship_date;         -- 出荷予定日
        lt_order_line_tbl(ln_order_line_count).unit_selling_price   := NVL(iot_order_tbl(ln_shori_count).unit_price,0);          -- 単価
        lt_order_line_tbl(ln_order_line_count).unit_list_price      := NVL(iot_order_tbl(ln_shori_count).unit_price,0);          -- 単価
        lt_order_line_tbl(ln_order_line_count).request_date         := SYSDATE;                                                  -- 要求日
        lt_order_line_tbl(ln_order_line_count).attribute1           := iot_order_tbl(ln_shori_count).quantity;                   -- 数量
        lt_order_line_tbl(ln_order_line_count).attribute2           := iot_order_tbl(ln_shori_count).based_request_quantity;     -- 拠点依頼数量
        lt_order_line_tbl(ln_order_line_count).attribute3           := iot_order_tbl(ln_shori_count).request_item_code;          -- 依頼品目
        lt_order_line_tbl(ln_order_line_count).return_reason_code   := gt_return_reason_code;                                    -- 返品事由
        lt_order_line_tbl(ln_order_line_count).calculate_price_flag := gv_no;                                                    -- 凍結価格計算フラグ
        -- 標準API処理用受注データ
        ot_order_line_tbl(ln_order_line_count).order_line_id        := iot_order_tbl(ln_shori_count).order_line_id;              -- 受注明細アドオンID
        ot_order_line_tbl(ln_order_line_count).line_id              := lt_input_line_id;                                         -- 受注明細ID
        ot_order_line_tbl(ln_order_line_count).lot_ctl              := iot_order_tbl(ln_shori_count).lot_ctl;                    -- ロット管理
        ot_order_line_tbl(ln_order_line_count).shipped_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- 実績数量
        ot_order_line_tbl(ln_order_line_count).uom_code             := iot_order_tbl(ln_shori_count).uom_code;                   -- 単位
        ot_order_line_tbl(ln_order_line_count).shipping_inventory_item_id 
                                                                    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- 出荷品目ID
        ot_order_line_tbl(ln_order_line_count).shipped_date         := iot_order_tbl(ln_shori_count).shipped_date;               -- 出荷日
        ot_order_line_tbl(ln_order_line_count).mtl_organization_id
                                                                    := iot_order_tbl(ln_shori_count).mtl_organization_id;        -- 在庫組織
        ot_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- 受注ヘッダID
        ot_order_line_tbl(ln_order_line_count).site_use_id          := it_site_use_id;                                           -- 使用目的ID
        ot_order_line_tbl(ln_order_line_count).location_id          := iot_order_tbl(ln_shori_count).location_id;                -- 事業所ID
        ot_order_line_tbl(ln_order_line_count).subinventory_code    := iot_order_tbl(ln_shori_count).subinventory_code;          -- 保管場所コード
        ot_order_line_tbl(ln_order_line_count).inventory_location_id
                                                                    := iot_order_tbl(ln_shori_count).inventory_location_id;      -- 倉庫ID
        ot_order_line_tbl(ln_order_line_count).cust_account_id      := iot_order_tbl(ln_shori_count).cust_account_id;            -- 顧客ID
      END IF;
--
      -- 明細件数を+1
      ln_line_count := ln_line_count + 1;
--
      IF (gv_shori_kbn IN ('2','4') ) THEN 
        -- 受注明細ID更新用変数に値をセット(明細IDはAPI実行後に別途セットする)
        gt_order_line_id(ln_line_count) := iot_order_tbl(ln_shori_count).order_line_id;
        gt_line_id(ln_line_count)       := lt_input_line_id;
      END IF;
      IF (gv_shori_kbn = '3') THEN
        --訂正受注の場合受注明細アドオン登録用データを作成
--
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   lt_order_line_id(ln_line_count)
        FROM   dual;
--
        ot_revised_line_tbl(ln_line_count).order_line_id
                                                           := iot_order_tbl(ln_shori_count).order_line_id;
        ot_revised_line_tbl(ln_line_count).new_order_line_id
                                                           := lt_order_line_id(ln_line_count); -- 新受注明細アドオンIDをセット
        lt_order_header_id(ln_line_count)                  := it_new_order_header_id;
        lt_order_line_number(ln_line_count)                := iot_order_tbl(ln_shori_count).order_line_number;
        lt_header_id(ln_line_count)                        := it_new_header_id;
        lt_line_id(ln_line_count)                          := lt_input_line_id;
        lt_request_no(ln_line_count)                       := iot_order_tbl(ln_shori_count).line_request_no;
        lt_shipping_inventory_item_id(ln_line_count)       := iot_order_tbl(ln_shori_count).shipping_inventory_item_id;
        lt_shipping_item_code(ln_line_count)               := iot_order_tbl(ln_shori_count).shipping_item_code;
        lt_quantity(ln_line_count)                         := iot_order_tbl(ln_shori_count).quantity;
        lt_uom_code(ln_line_count)                         := iot_order_tbl(ln_shori_count).uom_code;
        lt_unit_price(ln_line_count)                       := iot_order_tbl(ln_shori_count).unit_price;
        lt_shippied_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).shipped_quantity;
        lt_designated_production_date(ln_line_count)       := iot_order_tbl(ln_shori_count).line_designated_prod_date;
        lt_based_request_quantity(ln_line_count)           := iot_order_tbl(ln_shori_count).based_request_quantity;
        lt_request_item_id(ln_line_count)                  := iot_order_tbl(ln_shori_count).request_item_id;
        lt_request_item_code(ln_line_count)                := iot_order_tbl(ln_shori_count).request_item_code;
        lt_ship_to_quantity(ln_line_count)                 := iot_order_tbl(ln_shori_count).ship_to_quantity;
        lt_futai_code(ln_line_count)                       := iot_order_tbl(ln_shori_count).futai_code;
        lt_designated_date(ln_line_count)                  := iot_order_tbl(ln_shori_count).designated_date;
        lt_move_number(ln_line_count)                      := iot_order_tbl(ln_shori_count).move_number;
        lt_po_number(ln_line_count)                        := iot_order_tbl(ln_shori_count).po_number;
        lt_cust_po_number(ln_line_count)                   := iot_order_tbl(ln_shori_count).line_cust_po_number;
        lt_pallet_quantity(ln_line_count)                  := iot_order_tbl(ln_shori_count).pallet_quantity;
        lt_layer_quantity(ln_line_count)                   := iot_order_tbl(ln_shori_count).layer_quantity;
        lt_case_quantity(ln_line_count)                    := iot_order_tbl(ln_shori_count).case_quantity;
        lt_weight(ln_line_count)                           := iot_order_tbl(ln_shori_count).weight;
        lt_capacity(ln_line_count)                         := iot_order_tbl(ln_shori_count).capacity;
        lt_pallet_qty(ln_line_count)                       := iot_order_tbl(ln_shori_count).pallet_qty;
        lt_pallet_weight(ln_line_count)                    := iot_order_tbl(ln_shori_count).pallet_weight;
        lt_reserved_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).reserved_quantity;
        lt_automanual_reserve_class(ln_line_count)         := iot_order_tbl(ln_shori_count).automanual_reserve_class;
        lt_warning_class(ln_line_count)                    := iot_order_tbl(ln_shori_count).warning_class;
        lt_warning_date(ln_line_count)                     := iot_order_tbl(ln_shori_count).warning_date;
        lt_line_description(ln_line_count)                 := iot_order_tbl(ln_shori_count).line_description;
-- Ver1.8 M.Hokkanji Start
        lt_rm_if_flg(ln_line_count)                        := gv_no;
        lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
        lt_shipping_result_if_flg(ln_line_count)           := gv_no;
        --lt_rm_if_flg(ln_line_count)                        := iot_order_tbl(ln_shori_count).rm_if_flg;
        --lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
        --lt_shipping_result_if_flg(ln_line_count)           := iot_order_tbl(ln_shori_count).shipping_result_if_flg;
-- Ver1.8 M.Hokkanji End
--
      END IF;
      -- 受注アドオンループ件数を+1
      ln_shori_count := ln_shori_count + 1;
    END LOOP order_line_data;
--
    --A3で取得したデータの場合現在のレコード番号を返す
    IF (gv_shori_kbn IN ('2','4') ) THEN
      gn_shori_count := ln_shori_count;
    END IF;
--
    IF (ln_order_line_count > 0) THEN --明細の対象件数が0件より大きい場合に後続の処理を行う。
-- 2008/12/15 v1.10 T.Yoshimoto Add Start 検証用
      --==============================================================
      -- 検証用ログ
      --==============================================================
      -- WHOカラム情報取得
      ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
      ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
      ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
      ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
      ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
      ld_sysdate           := SYSDATE;                      -- システム現在日付
--
      BEGIN
        lv_log := '【XXWSH42A-A15RMA(標準API_PARAMETER)】'
               || ' ユーザID/'        || ln_user_id
               || ' 要求ID/'          || ln_conc_request_id
               || ' プログラムID/'    || ln_conc_program_id;
--
        lv_log :=  lv_log || CHR(10)
               || '　【受注明細ID】'         || lt_input_line_id                                             || CHR(10)        -- 受注明細ID
               || '　【受注ヘッダID】'       || lt_order_line_tbl(ln_order_line_count).header_id             || CHR(10)        -- 受注ヘッダID
               || '　【出荷品目ID】'         || lt_order_line_tbl(ln_order_line_count).inventory_item_id     || CHR(10)        -- 出荷品目ID
               || '　【出荷実績数量】'       || lt_order_line_tbl(ln_order_line_count).ordered_quantity      || CHR(10)        -- 出荷実績数量
               || '　【出荷予定日】'         || lt_order_line_tbl(ln_order_line_count).schedule_ship_date    || CHR(10)        -- 出荷予定日
               || '　【単価】'               || lt_order_line_tbl(ln_order_line_count).unit_selling_price    || CHR(10)        -- 単価
               || '　【単価】'               || lt_order_line_tbl(ln_order_line_count).unit_list_price       || CHR(10)        -- 単価
               || '　【要求日】'             || lt_order_line_tbl(ln_order_line_count).request_date          || CHR(10)        -- 要求日
               || '　【数量】'               || lt_order_line_tbl(ln_order_line_count).attribute1            || CHR(10)        -- 数量
               || '　【拠点依頼数量】'       || lt_order_line_tbl(ln_order_line_count).attribute2            || CHR(10)        -- 拠点依頼数量
               || '　【依頼品目】'           || lt_order_line_tbl(ln_order_line_count).attribute3            || CHR(10)        -- 依頼品目
               || '　【返品事由】'           || lt_order_line_tbl(ln_order_line_count).return_reason_code    || CHR(10)        -- 返品事由
               || '　【凍結価格計算フラグ】' || lt_order_line_tbl(ln_order_line_count).calculate_price_flag;                   -- 凍結価格計算フラグ
--
       FND_LOG.STRING('6', gv_pkg_name || '.' || cv_prg_name, SUBSTRB(lv_log, 1, 4000));
--
      EXCEPTION
        WHEN  OTHERS THEN
          NULL;
      END;
--
-- 2008/12/15 v1.10 T.Yoshimoto Add End 検証用
--
      -- ***************************************
      -- ***       A15-RMA受注作成API起動    ***
      -- ***************************************
      -- OMメッセージリストの初期化
      OE_MSG_PUB.INITIALIZE;
      lt_action_request_tbl(1)                := OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    := OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).entity_id      := it_new_header_id;
      lt_action_request_tbl(1).request_type   := OE_GLOBALS.G_BOOK_ORDER; --記帳
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_order_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_order_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- メッセージ件数が0より大きい場合エラーメッセージを出力
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --メッセージを出力し処理を強制終了する
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (gv_shori_kbn = '3') THEN
      -- ********************************************************
      -- ***      訂正受注時受注明細アドオンに訂正データを登録***
      -- ********************************************************
--
-- 2008/12/15 v1.10 T.Yoshimoto Add Start 検証用
      <<log_loop>>
      FOR i IN 1..lt_order_line_id.COUNT LOOP
        --==============================================================
        -- 検証用ログ
        --==============================================================
        -- WHOカラム情報取得
        ln_user_id           := FND_GLOBAL.USER_ID;           -- ログインしているユーザーのID取得
        ln_login_id          := FND_GLOBAL.LOGIN_ID;          -- 最終更新ログイン
        ln_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID;   -- 要求ID
        ln_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;      -- プログラム・アプリケーションID
        ln_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID;   -- プログラムID
        ld_sysdate           := SYSDATE;                      -- システム現在日付
--
        BEGIN
          lv_log := '【XXWSH42A-A15RMA(受注明細ｱﾄﾞｵﾝ_PARAMETER)】'
                || ' ユーザID/'        || ln_user_id
                || ' 要求ID/'          || ln_conc_request_id
                || ' プログラムID/'    || ln_conc_program_id;
--
          lv_log :=  lv_log || CHR(10)
                || '　【受注明細ｱﾄﾞｵﾝID】' || lt_order_line_id(i)              || CHR(10)        -- 受注明細アドオンID
                || '　【受注ﾍｯﾀﾞｱﾄﾞｵﾝID】' || lt_order_header_id(i)            || CHR(10)        -- 受注ヘッダアドオンID
                || '　【明細番号】'        || lt_order_line_number(i)          || CHR(10)        -- 明細番号
                || '　【受注ﾍｯﾀﾞID】'      || lt_header_id(i)                  || CHR(10)        -- 受注ヘッダID
                || '　【受注明細ID】'      || lt_line_id(i)                    || CHR(10)        -- 受注明細ID
                || '　【依頼No】'          || lt_request_no(i)                 || CHR(10)        -- 依頼No
                || '　【出荷品目ID】'      || lt_shipping_inventory_item_id(i) || CHR(10)        -- 出荷品目ID
                || '　【出荷品目】'        || lt_shipping_item_code(i)         || CHR(10)        -- 出荷品目
                || '　【数量】'            || lt_quantity(i)                   || CHR(10)        -- 数量
                || '　【依頼品目ID】'      || lt_request_item_id(i)            || CHR(10)        -- 依頼品目ID
                || '　【依頼品目ｺｰﾄﾞ】'    || lt_request_item_code(i)          || CHR(10)        -- 依頼品目コード
                || '　【入庫実績数量】'    || lt_ship_to_quantity(i);                            -- 入庫実績数量
--
         FND_LOG.STRING('6', gv_pkg_name || '.' || cv_prg_name, SUBSTRB(lv_log, 1, 4000));
--
        EXCEPTION
          WHEN  OTHERS THEN
            NULL;
        END;
      END LOOP log_loop;
--
-- 2008/12/15 v1.10 T.Yoshimoto Add End 検証用
--
      FORALL i IN 1..lt_order_line_id.COUNT
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
        VALUES (
           lt_order_line_id(i),              -- 受注明細アドオンID
           lt_order_header_id(i),            -- 受注ヘッダアドオンID
           lt_order_line_number(i),          -- 明細番号
           lt_header_id(i),                  -- 受注ヘッダID
           lt_line_id(i),                    -- 受注明細ID
           lt_request_no(i),                 -- 依頼No
           lt_shipping_inventory_item_id(i), -- 出荷品目ID
           lt_shipping_item_code(i),         -- 出荷品目
           lt_quantity(i),                   -- 数量
           lt_uom_code(i),                   -- 単位
           lt_unit_price(i),                 -- 単価
           lt_shippied_quantity(i),          -- 出荷実績数量
           lt_designated_production_date(i), -- 指定製造日
           lt_based_request_quantity(i),     -- 拠点依頼数量
           lt_request_item_id(i),            -- 依頼品目ID
           lt_request_item_code(i),          -- 依頼品目コード
           lt_ship_to_quantity(i),           -- 入庫実績数量
           lt_futai_code(i),                 -- 付帯コード
           lt_designated_date(i),            -- 指定日付(リーフ)
           lt_move_number(i),                -- 移動No
           lt_po_number(i),                  -- 発注No
           lt_cust_po_number(i),             -- 顧客発注
           lt_pallet_quantity(i),            -- パレット数
           lt_layer_quantity(i),             -- 段数
           lt_case_quantity(i),              -- ケース数
           lt_weight(i),                     -- 重量
           lt_capacity(i),                   -- 容積
           lt_pallet_qty(i),                 -- パレット枚数
           lt_pallet_weight(i),              -- パレット重量
           lt_reserved_quantity(i),          -- 引当数
           lt_automanual_reserve_class(i),   -- 自動手動引当区分
           'N',                             -- 削除フラグ
           lt_warning_class(i),              -- 警告区分
           lt_warning_date(i),               -- 警告日付
           lt_line_description(i),           -- 摘要
           lt_rm_if_flg(i),                  -- 倉替返品インタフェース済フラグ
           lt_shipping_request_if_flg(i),    -- 出荷依頼インタフェース済フラグ
           lt_shipping_result_if_flg(i),     -- 出荷実績インタフェース済フラグ
           gn_user_id,                       -- 作成者
           SYSDATE,                          -- 作成日
           gn_user_id,                       -- 最終更新者
           SYSDATE,                          -- 最終更新日
           gn_login_id,                      -- 最終更新ログイン
           gn_conc_request_id,               -- 要求ID
           gn_prog_appl_id,                  -- コンカレント・プログラム・アプリケーションID
           gn_conc_program_id,               -- コンカレント・プログラムID
           SYSDATE                           -- プログラム更新日
        );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_rma_order_line_info;
  /***********************************************************************************
   * Procedure Name   : create_lot_details
   * Description      : A16ロット情報作成
   ***********************************************************************************/
  PROCEDURE create_lot_details(
    it_order_line_tbl    IN order_line_type,    -- 受注明細情報格納配列
    it_revised_line_tbl  IN revised_line_type,  -- 訂正受注明細情報格納配列
    iv_standard_api_flag IN VARCHAR2,           -- 標準API実行フラグ
    ov_errbuf            OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg            OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_lot_details'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_count              NUMBER;           -- 移動ロット詳細登録用件数
--
    -- *** ローカル・カーソル ***
    CURSOR cur_mov_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- 文書タイプ
                xmld.record_type_code,        -- レコードタイプ
                xmld.item_id,                 -- OPM品目ID
                xmld.item_code,               -- 品目
                xmld.lot_no,                  -- ロットNo
                xmld.lot_id,                  -- ロットID
                xmld.actual_date,             -- 実績日
                xmld.actual_quantity,         -- 実績数量
                xmld.automanual_reserve_class -- 自動手動引当区分
         FROM   xxinv_mov_lot_details xmld    -- 移動ロット詳細(アドオン)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20
         AND    xmld.actual_quantity <> 0;
--
    CURSOR cur_revised_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- 文書タイプ
                xmld.record_type_code,        -- レコードタイプ
                xmld.item_id,                 -- OPM品目ID
                xmld.item_code,               -- 品目
                xmld.lot_no,                  -- ロットNo
                xmld.lot_id,                  -- ロットID
                xmld.actual_date,             -- 実績日
                xmld.actual_quantity,         -- 実績数量
                xmld.automanual_reserve_class -- 自動手動引当区分
         FROM   xxinv_mov_lot_details xmld    -- 移動ロット詳細(アドオン)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- *********************************************
    -- ***       明細ごとにロット情報を取得      ***
    -- *********************************************
--
    IF (iv_standard_api_flag = '1') THEN
      -- 受入取引オープンインタフェースヘッダ登録用データ
      gn_header_if_count :=  gn_header_if_count + 1;
--
      SELECT rcv_headers_interface_s.NEXTVAL
      INTO   gt_header_interface_id(gn_header_if_count)
      FROM   dual;
--
      gt_expectied_receipt_date(gn_header_if_count)   := it_order_line_tbl(1).shipped_date;               -- 出荷日
      gt_ship_to_organization_id(gn_header_if_count)  := it_order_line_tbl(1).mtl_organization_id;        -- 在庫組織ID
      gt_customer_id(gn_header_if_count)              := it_order_line_tbl(1).cust_account_id;            -- 顧客ID
      gt_customer_site_id(gn_header_if_count)         := it_order_line_tbl(1).site_use_id;                -- 使用目的ID
      <<order_line_data>>
      FOR i IN 1..it_order_line_tbl.COUNT LOOP  --明細の件数ループ
        -- 受入取引オープンインタフェース明細のデータを作成
        gn_tran_if_count := gn_tran_if_count + 1;
        gt_line_header_interface_id(gn_tran_if_count) := gt_header_interface_id(gn_header_if_count);      -- ヘッダインタフェースID
        gt_line_exp_receipt_date(gn_tran_if_count)    := it_order_line_tbl(i).shipped_date;               -- 出荷日
        gt_transaction_date(gn_tran_if_count)         := it_order_line_tbl(i).shipped_date;               -- 出荷日
--
        SELECT rcv_transactions_interface_s.NEXTVAL  -- 受入取引インタフェースID
        INTO   gt_interface_transaction_id(gn_tran_if_count)
        FROM   dual;
--
        gt_quantity(gn_tran_if_count)                 := it_order_line_tbl(i).shipped_quantity;           -- 数量
        gt_unit_of_measure(gn_tran_if_count)          := it_order_line_tbl(i).uom_code;                   -- 単位
        gt_ti_item_id(gn_tran_if_count)               := it_order_line_tbl(i).shipping_inventory_item_id; -- 品目ID
        gt_ship_to_location_id(gn_tran_if_count)      := it_order_line_tbl(i).location_id;                -- 事業所ID
        gt_subinventory(gn_tran_if_count)             := it_order_line_tbl(i).subinventory_code;          -- 保管場所コード
        gt_locator_id(gn_tran_if_count)               := it_order_line_tbl(i).inventory_location_id;      -- 倉庫ID
        gt_oe_order_header_id(gn_tran_if_count)       := it_order_line_tbl(i).header_id;                  -- 受注ヘッダID
        gt_oe_order_line_id(gn_tran_if_count)         := it_order_line_tbl(i).line_id;                    -- 受注明細ID
--
        -- 明細ごとに移動ロット詳細を呼び出す
--
        <<move_lot_details_data>>
        FOR rec_move_lot_details IN cur_mov_lot_details(it_order_line_tbl(i).order_line_id) LOOP
--
          IF (it_order_line_tbl(i).lot_ctl =gv_lot_ctl_1) THEN --ロット管理品の場合
--
            -- 受入取引オープンインタフェースロットのデータを作成
            gn_tran_lot_if_count                             := gn_tran_lot_if_count + 1;
--
            SELECT mtl_material_transactions_s.NEXTVAL  -- ロットインタフェースID
            INTO   gt_transaction_interface_id(gn_tran_lot_if_count)
            FROM   dual;
--
            gt_lot_number(gn_tran_lot_if_count)              := rec_move_lot_details.lot_no;                   -- ロットNo
            gt_transaction_quantity(gn_tran_lot_if_count)    := rec_move_lot_details.actual_quantity;          -- 数量
            gt_primary_quantity(gn_tran_lot_if_count)        := rec_move_lot_details.actual_quantity;          -- 数量
            gt_lot_prod_transaction_id(gn_tran_lot_if_count) := gt_interface_transaction_id(gn_tran_if_count); -- 受入取引インタフェースID
--
          END IF;
        END LOOP move_lot_details_data;
--
      END LOOP order_line_data;
    END IF;
--
    IF (gv_shori_kbn = '3') THEN
    -- 処理区分が訂正受注の場合返品用移動ロット詳細登録データを作成する
      <<revised_line_data>>
      FOR cnt IN 1..it_revised_line_tbl.COUNT LOOP  --明細の件数ループ
        <<revised_lot_details_data>>
        FOR revised_lot_details IN cur_revised_lot_details(it_revised_line_tbl(cnt).order_line_id) LOOP
          gn_lot_count                              := gn_lot_count +1;
--
          SELECT xxinv_mov_lot_s1.NEXTVAL  -- ロット詳細ID
          INTO   gt_mov_lot_dtl_id(gn_lot_count)
          FROM   dual;
--
          gt_mov_line_id(gn_lot_count)              := it_revised_line_tbl(cnt).new_order_line_id;   -- 明細ID
          gt_document_type_code(gn_lot_count)       := revised_lot_details.document_type_code;       -- 文書タイプ
          gt_record_type_code(gn_lot_count)         := revised_lot_details.record_type_code;         -- レコードタイプ
          gt_item_id(gn_lot_count)                  := revised_lot_details.item_id;                  -- OPM品目ID
          gt_item_code(gn_lot_count)                := revised_lot_details.item_code;                -- 品目
          gt_lot_id(gn_lot_count)                   := revised_lot_details.lot_id;                   -- ロットID
          gt_lot_no(gn_lot_count)                   := revised_lot_details.lot_no;                   -- ロットNo
          gt_actual_date(gn_lot_count)              := revised_lot_details.actual_date;              -- 実績日
          gt_actual_quantity(gn_lot_count)          := revised_lot_details.actual_quantity;          -- 実績数量
          gt_automanual_reserve_class(gn_lot_count) := revised_lot_details.automanual_reserve_class; -- 自動手動引当区分
        END LOOP revised_lot_details_data;
--
      END LOOP revised_line_data;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END create_lot_details;
  /***********************************************************************************
   * Procedure Name   : upd_status
   * Description      : A17ステータス更新
   ***********************************************************************************/
  PROCEDURE upd_status(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_status'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
-- Ver1.18 M.Hokkanji Start
    CURSOR mov_lot_cur IS
      SELECT xmld.mov_lot_dtl_id
        FROM xxwsh_order_lines_all xola
            ,xxinv_mov_lot_details xmld
       WHERE xola.order_header_id = gt_gen_order_header_id
         AND NVL(xola.delete_flag,gv_no) = gv_no
         AND xmld.mov_line_id = xola.order_line_id
         AND xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
-- Ver1.18 M.Hokkanji End
    -- *** ローカル・レコード ***
-- Ver1.18 M.Hokkanji End
    ln_upd_mov_lot_dtl_id   ld_lot_id_type;   -- 移動ロット詳細更新用移動ロット詳細ID
-- Ver1.18 M.Hokkanji Start
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 受注ヘッダアドオンを更新
    UPDATE xxwsh_order_headers_all
    SET    actual_confirm_class    = gv_yes,             -- 実績計上済区分
           header_id               = gt_header_id,       -- 受注ヘッダID
           last_updated_by         = gn_user_id,         -- 最終更新者
           last_update_date        = SYSDATE,            -- 最終更新日
           last_update_login       = gn_login_id,        -- 最終更新ログイン
           request_id              = gn_conc_request_id, -- 要求ID
           program_application_id  = gn_prog_appl_id,    -- コンカレント・プログラム・アプリケーションID
           program_id              = gn_conc_program_id, -- コンカレント・プログラムID
           program_update_date     = SYSDATE             -- プログラム更新日
    WHERE  order_header_id      = gt_gen_order_header_id;
    -- 受注明細アドオンを更新
    FORALL i IN 1 .. gt_order_line_id.COUNT
      UPDATE xxwsh_order_lines_all
      SET  header_id               = gt_header_id,        -- 受注ヘッダID
           line_id                 = gt_line_id(i),       -- 受注明細ID
           last_updated_by         = gn_user_id,          -- 最終更新者
           last_update_date        = SYSDATE,             -- 最終更新日
           last_update_login       = gn_login_id,         -- 最終更新ログイン
           request_id              = gn_conc_request_id,  -- 要求ID
           program_application_id  = gn_prog_appl_id,     -- コンカレント・プログラム・アプリケーションID
           program_id              = gn_conc_program_id,  -- コンカレント・プログラムID
           program_update_date     = SYSDATE              -- プログラム更新日
      WHERE  order_line_id     = gt_order_line_id(i);
-- Ver1.18 M.Hokkanji Start
    BEGIN
      OPEN  mov_lot_cur;
      -- バルクフェッチ
      FETCH mov_lot_cur BULK COLLECT INTO ln_upd_mov_lot_dtl_id ;
--
      -- カーソルクローズ
      CLOSE mov_lot_cur;
      FOR i  IN 1..ln_upd_mov_lot_dtl_id.COUNT LOOP
        gn_upd_mov_lot_cnt := gn_upd_mov_lot_cnt + 1;
        -- 纏めて更新するために変数にデータを格納
        gn_upd_mov_lot_dtl_id(gn_upd_mov_lot_cnt) := ln_upd_mov_lot_dtl_id(i);
      END LOOP;
    EXCEPTION
      WHEN lock_error_expt THEN -- ロックエラー
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_027,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- Ver1.18 M.Hokkanji End
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END upd_status;
--
  /***********************************************************************************
   * Procedure Name   : shipping_process
   * Description      : 出荷情報登録処理
   ***********************************************************************************/
  PROCEDURE shipping_process(
    iot_order_tbl  IN OUT order_tbl,        -- 処理情報レコード変数
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipping_process'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_gen_count            NUMBER;                                        -- 受注情報格納配列の現在の位置
    lt_new_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;  -- 新受注ヘッダアドオンID
    lt_new_header_id        xxwsh_order_headers_all.header_id%TYPE;        -- 新受注ヘッダID
    lt_shipped_date         xxwsh_order_headers_all.shipped_date%TYPE;     -- 出荷日
    lv_standard_api_flag    VARCHAR2(1);                                   -- 標準API実行フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_order_line_tbl       order_line_type;                               -- 受注明細情報格納配列
    lt_del_rows_tbl         WSH_UTIL_CORE.ID_TAB_TYPE;                     -- 搬送ID
    lt_ic_tran_rec_tbl      ic_tran_rec_type;                              -- 在庫割当API用データ一時保存用配列
    lt_mov_line_id_tbl      mov_line_id_type;                              -- 移動明細IDデータ一時保存用配列
    lt_revised_line_tbl     revised_line_type;                             -- 訂正受注明細情報格納配列
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- ******************************************
    -- ***  A6 受注作成API起動(受注ヘッダ登録 ***
    -- ******************************************
    create_order_header_info(iot_order_tbl,
                             lt_new_order_header_id,
                             lt_new_header_id,
                             lt_shipped_date,
                             lv_standard_api_flag,
                             ln_gen_count,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
    );
    IF (lv_retcode  = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ************************************************
    -- ***  A7,8 受注作成API起動(受注明細作成、登録 ***
    -- ************************************************
    create_order_line_info(iot_order_tbl(ln_gen_count).order_header_id,
                           lt_new_order_header_id,
                           lt_new_header_id,
                           ln_gen_count,
                           iot_order_tbl,
                           lt_order_line_tbl,
                           lt_revised_line_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (lv_standard_api_flag = '1') THEN
      -- ************************************************
      -- ***  A9 ピックリリースAPI起動                ***
      -- ************************************************
      delivery_action_proc(lt_new_header_id,
                           lt_del_rows_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ************************************************
    -- ***  A10ロット情報取得                       ***
    -- ************************************************
    get_lot_details(lt_order_line_tbl,
                    lt_revised_line_tbl,
                    lv_standard_api_flag,
                    lt_ic_tran_rec_tbl,
                    lt_mov_line_id_tbl,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (lv_standard_api_flag = '1') THEN
      -- ************************************************
      -- ***  A11在庫割当API起動                      ***
      -- ************************************************
      set_allocate_opm_order(lt_ic_tran_rec_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
  --
      -- ************************************************
      -- ***  移動オーダ取引処理                      ***
      -- ************************************************
      pick_confirm_proc(lt_mov_line_id_tbl,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
  --
      -- ************************************************
      -- ***  A12 出荷確認API起動                     ***
      -- ************************************************
      confirm_proc(lt_del_rows_tbl,
                   lt_shipped_date,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END shipping_process;
  /***********************************************************************************
   * Procedure Name   : return_process
   * Description      : 返品情報登録処理
   ***********************************************************************************/
  PROCEDURE return_process(
    iot_order_tbl IN OUT  order_tbl,       -- 処理情報レコード変数
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'return_process'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_gen_count            NUMBER;                                        -- 受注情報格納配列の現在の位置
    lt_new_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;  -- 新受注ヘッダアドオンID
    lt_new_header_id        xxwsh_order_headers_all.header_id%TYPE;        -- 新受注ヘッダID
    lt_site_use_id          hz_cust_site_uses_all.site_use_id%TYPE;        -- 使用目的ID
    lv_standard_api_flag    VARCHAR2(1);                                   -- 標準API実行フラグ
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    lt_order_line_tbl       order_line_type;                               -- 受注明細情報格納配列
    lt_revised_line_tbl     revised_line_type;                             -- 訂正受注明細情報格納配列
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- **********************************************
    -- ***  A13 RMA受注作成API起動(受注ヘッダ登録 ***
    -- **********************************************
    create_rma_order_header_info(iot_order_tbl,
                                 lt_new_order_header_id,
                                 lt_new_header_id,
                                 lt_site_use_id,
                                 lv_standard_api_flag,
                                 ln_gen_count,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- *****************************************************
    -- ***  A14,15 RMA受注作成API起動(受注明細作成、登録 ***
    -- *****************************************************
    create_rma_order_line_info(iot_order_tbl(ln_gen_count).order_header_id,
                           lt_new_order_header_id,
                           lt_new_header_id,
                           lt_site_use_id,
                           ln_gen_count,
                           iot_order_tbl,
                           lt_order_line_tbl,
                           lt_revised_line_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ************************************************
    -- ***  ロット情報作成A-16                      ***
    -- ************************************************
    create_lot_details(lt_order_line_tbl,
                       lt_revised_line_tbl,
                       lv_standard_api_flag,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END return_process;
--
  /***********************************************************************************
   * Procedure Name   : ins_mov_lot_details
   * Description      : A18移動ロット詳細(アドオン)登録
   ***********************************************************************************/
  PROCEDURE ins_mov_lot_details(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_lot_details'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 移動ロット詳細(アドオン)を登録
    FORALL i IN 1 .. gn_lot_count
      INSERT INTO xxinv_mov_lot_details(
        mov_lot_dtl_id,
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
        program_update_date
-- Ver1.18 M.Hokkanji Start
       ,actual_confirm_class
-- Ver1.18 M.Hokkanji End
      )VALUES(
        gt_mov_lot_dtl_id(i),           -- ロット詳細ID
        gt_mov_line_id(i),              -- 明細ID
        gt_document_type_code(i),       -- 文書タイプ
        gt_record_type_code(i),         -- レコードタイプ
        gt_item_id(i),                  -- OPM品目ID
        gt_item_code(i),                -- 品目
        gt_lot_id(i),                   -- ロットID
        gt_lot_no(i),                   -- ロットNo
        gt_actual_date(i),              -- 実績日
        gt_actual_quantity(i),          -- 実績数量
        gt_automanual_reserve_class(i), -- 自動手動引当区分
        gn_user_id,                     -- 作成者
        SYSDATE,                        -- 作成日
        gn_user_id,                     -- 最終更新者
        SYSDATE,                        -- 最終更新日
        gn_login_id,                    -- 最終更新ログイン
        gn_conc_request_id,             -- 要求ID
        gn_prog_appl_id,                -- コンカレント・プログラム・アプリケーションID
        gn_conc_program_id,             -- コンカレント・プログラムID
        SYSDATE                         -- プログラム更新日
-- Ver1.18 M.Hokkanji Start
       ,gv_yes                          -- 実績計上済区分(Y)
-- Ver1.18 M.Hokkanji End
      );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END ins_mov_lot_details;
--
  /***********************************************************************************
   * Procedure Name   : ins_transaction_interface
   * Description      : A19受入取引オープンインタフェーステーブル登録処理
   ***********************************************************************************/
  PROCEDURE ins_transaction_interface(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_transaction_interface'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
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
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    -- 受入取引オープンインタフェースヘッダに登録
    FORALL h_cnt IN 1 .. gn_header_if_count
      INSERT INTO rcv_headers_interface(
        header_interface_id,
        group_id,
        processing_status_code,
        receipt_source_code,
        transaction_type,
        ship_to_organization_id,
        customer_id,
        customer_site_id,
        last_update_date,
        last_updated_by,
        creation_date,
        created_by,
        validation_flag,
        expected_receipt_date,
        last_update_login
      )VALUES(
        gt_header_interface_id(h_cnt),      -- header_interface_id
        gn_group_id,                        -- group_id
        gv_pending,                         -- processing_status_code
        gv_customer,                        -- receipt_source_code
        gv_new,                             -- transaction_type
        gt_ship_to_organization_id(h_cnt),         -- ship_to_organization_id
        gt_customer_id(h_cnt),                     -- customer_id
        gt_customer_site_id(h_cnt),                -- customer_site_id
        SYSDATE,                            -- last_update_date
        gn_user_id,                         -- last_updated_by
        SYSDATE,                            -- creation_date
        gn_user_id,                         -- created_by
        gv_yes,                             -- validation_flag
        gt_expectied_receipt_date(h_cnt),   -- expected_receipt_date
        gn_login_id                         -- last_update_login
      );
    -- 受入取引オープンインタフェース明細に登録
    FORALL l_cnt IN 1 .. gn_tran_if_count
      INSERT INTO rcv_transactions_interface(
        interface_transaction_id,
        group_id,
        transaction_type,
        transaction_date,
        processing_status_code,
        processing_mode_code,
        transaction_status_code,
        quantity,
        unit_of_measure,
        uom_code,
        auto_transact_code,
        receipt_source_code,
        source_document_code,
        header_interface_id,
        validation_flag,
        item_id,
        subinventory,
        locator_id,
        ship_to_location_id,
        destination_type_code,
        expected_receipt_date,
        oe_order_header_id,
        oe_order_line_id,
        creation_date,
        created_by,
        last_update_date,
        last_updated_by,
        last_update_login
      )VALUES(
        gt_interface_transaction_id(l_cnt), -- interface_transaction_id
        gn_group_id,                        -- group_id
        gv_receive,                         -- transaction_type
        gt_transaction_date(l_cnt),         -- transaction_date
        gv_pending,                         -- processing_status_code
        gv_batch,                           -- processing_mode_code
        gv_pending,                         -- transaction_status_code
        gt_quantity(l_cnt),                 -- quantity
        gt_unit_of_measure(l_cnt),          -- unit_of_measure
        gt_unit_of_measure(l_cnt),          -- uom_code
        gv_deliver,                         -- auto_transact_code
        gv_customer,                        -- receipt_source_code
        gv_rma,                             -- source_document_code
        gt_line_header_interface_id(l_cnt), -- header_interface_id
        gv_yes,                             -- validation_flag
        gt_ti_item_id(l_cnt),               -- item_id
        gt_subinventory(l_cnt),             -- subinventory
        gt_locator_id(l_cnt),               -- locator_id
        gt_ship_to_location_id(l_cnt),      -- ship_to_location_id
        gv_inventory,                       -- destination_type_code
        gt_line_exp_receipt_date(l_cnt),    -- expected_receipt_date
        gt_oe_order_header_id(l_cnt),       -- oe_order_header_id
        gt_oe_order_line_id(l_cnt),         -- oe_order_line_id
        SYSDATE,                            -- creation_date
        gn_user_id,                         -- created_by
        SYSDATE,                            -- last_update_date
        gn_user_id,                         -- last_updated_by
        gn_login_id                         -- last_update_login
      );
    -- 受入取引オープンインタフェースロットに登録
    FORALL lot_cnt IN 1 .. gn_tran_lot_if_count
      INSERT INTO mtl_transaction_lots_interface(
        transaction_interface_id,
        lot_number,
        transaction_quantity,
        primary_quantity,
        product_code,
        product_transaction_id,
        creation_date,
        created_by,
        last_update_date,
        last_updated_by,
        last_update_login
      )VALUES(
        gt_transaction_interface_id(lot_cnt), -- transaction_interface_id
        gt_lot_number(lot_cnt),               -- lot_number
        gt_transaction_quantity(lot_cnt),     -- transaction_quantity
        gt_primary_quantity(lot_cnt),         -- primary_quantity
        gv_rcv,                               -- product_code
        gt_lot_prod_transaction_id(lot_cnt),  -- product_transaction_id
        SYSDATE,                              -- creation_date
        gn_user_id,                           -- created_by
        SYSDATE,                              -- last_update_date
        gn_user_id,                           -- last_updated_by
        gn_login_id                           -- last_update_login
      );
    gn_cancell_cnt := gn_header_if_count; --正常に処理が終わった場合件数をセット
--
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END ins_transaction_interface;
-- Ver1.18 M.Hokkanji Start
--
  /***********************************************************************************
   * Procedure Name   : upd_mov_lot_details
   * Description      : A21移動ロット詳細(アドオン)更新
   ***********************************************************************************/
  PROCEDURE upd_mov_lot_details(
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mov_lot_details'; -- プログラム名
--
--##############################  固定ローカル変数宣言部 START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END   #############################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--################################  固定ステータス初期化部 START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  固定部 END   #############################################
--
    FORALL i IN 1 ..  gn_upd_mov_lot_cnt
    UPDATE xxinv_mov_lot_details
         SET actual_confirm_class = gv_yes
            ,last_updated_by         = gn_user_id         -- 最終更新者
            ,last_update_date        = SYSDATE            -- 最終更新日
            ,last_update_login       = gn_login_id        -- 最終更新ログイン
            ,request_id              = gn_conc_request_id -- 要求ID
            ,program_application_id  = gn_prog_appl_id    -- コンカレント・プログラム・アプリケーションID
            ,program_id              = gn_conc_program_id -- コンカレント・プログラムID
            ,program_update_date     = SYSDATE             -- プログラム更新日
       WHERE mov_lot_dtl_id = gn_upd_mov_lot_dtl_id(i);
  EXCEPTION
--
--#################################  固定例外処理部 START   #######################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   #############################################
--
  END upd_mov_lot_details;
-- Ver1.18 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_block        IN VARCHAR2,             --   ブロック
    iv_deliver_from IN VARCHAR2,             --   出荷元
    iv_request_no   IN VARCHAR2,             --   依頼No
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_param_name   CONSTANT VARCHAR2(100) := '出荷日';       -- 2008/09/01 Add
--
    -- *** ローカル変数 ***
     ln_same_request_no_count NUMBER;                                           -- 同一依頼No件数
     lt_old_order_header_id   xxwsh_order_headers_all.order_header_id%TYPE;     -- 受注ヘッダアドオンID(OLD)
--
     lt_order_tbl             order_tbl;                                        -- 受注データ格納配列
     lt_revised_order_tbl     order_tbl;                                        -- 訂正前受注アドオン情報格納配列
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
    -- グローバル変数の初期化
    gn_new_order_cnt     := 0;                          -- 新規受注作成件数
    gn_upd_order_cnt     := 0;                          -- 訂正受注作成件数
    gn_cancell_cnt       := 0;                          -- 取消情報件数
    gn_input_cnt         := 0;                          -- 入力件数
    gn_error_cnt         := 0;                          -- エラー件数
    gn_shori_count       := 0;                          -- A3取得データ現在位置判断用
    gn_lot_count         := 0;                          -- 移動ロット登録用件数
    gn_header_if_count   := 0;                          -- 受入取引オープンインタフェースヘッダ件数
    gn_tran_if_count     := 0;                          -- 受入取引オープンインタフェース明細件数
    gn_tran_lot_if_count := 0;                          -- 受入取引オープンインタフェースロット件数
-- Ver1.18 M.Hokkanji Start
    gn_upd_mov_lot_cnt   := 0;                          -- 対象の移動ロット詳細IDの更新対象件数
    gn_upd_mov_lot_dtl_id.DELETE;                       -- 移動ロット詳細更新用受注ヘッダIDの初期化
-- Ver1.18 M.Hokkanji End
    -- WHOカラム情報取得
    gn_user_id           := FND_GLOBAL.USER_ID;         -- ログインしているユーザーのID取得
    gn_login_id          := FND_GLOBAL.LOGIN_ID;        -- 最終更新ログイン
    gn_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID; -- 要求ID
    gn_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;    -- コンカレント・プログラム・アプリケーションID
    gn_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID; -- コンカレント・プログラムID
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-1入力パラメータのチェック
    -- ===============================
    input_param_check(iv_block,
                      iv_deliver_from,
                      iv_request_no,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg
    );
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- A-2プロファイルの取得
    -- ===============================
    get_profile(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- A-3受注アドオン情報抽出
    -- ===============================
    get_order_info(lt_order_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg
    );
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- 入力件数が0件より大きい場合に処理を行う
    IF (gn_input_cnt > 0) THEN
--2008/09/01 Add ↓
      -- ===============================
      -- 出荷日が未来日かどうかのチェック
      -- ===============================
      <<chk_tbl_loop>>
      FOR i IN lt_order_tbl.FIRST .. lt_order_tbl.LAST LOOP
        -- 出荷日がシステム日付より未来日の場合エラー
        IF (lt_order_tbl(i).shipped_date > TRUNC(SYSDATE)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                gv_msg_42a_025,
                                                gv_tkn_para_date,
                                                lv_param_name,
                                                gv_tkn_param1,
                                                lt_order_tbl(i).delivery_no,
                                                gv_tkn_param2,
                                                lt_order_tbl(i).request_no,
                                                gv_tkn_param3,
                                                TO_CHAR(lt_order_tbl(i).shipped_date,'YYYY/MM/DD'),
                                                gv_tkn_param4,
                                                TO_CHAR(lt_order_tbl(i).arrival_date,'YYYY/MM/DD'));
          RAISE check_sub_main_expt;
        END IF;
      END LOOP chk_tbl_loop;
--2008/09/01 Add ↑
--
      -- 受入インターフェースで使用するグループIDを取得
      SELECT rcv_interface_groups_s.NEXTVAL
      INTO   gn_group_id
      FROM   dual;

      gn_shori_count := 1; -- ループの開始位置を指定

      <<order_data_table>> --受注ヘッダ情報ループ処理
      LOOP
        -- ヘッダ単位で登録する項目を初期化
        gt_order_line_id.DELETE;                                                -- 受注明細アドオンID
        gt_line_id.DELETE;                                                      -- 受注明細ID
        gt_header_id := NULL;
        gt_gen_request_no      := lt_order_tbl(gn_shori_count).request_no;      -- 依頼No
        gt_gen_order_header_id := lt_order_tbl(gn_shori_count).order_header_id; -- 受注ヘッダアドオンID
--
-- 2009/01/15 H.Itou Add Start 本番#981 倉替返品は42Aで複写処理を行わないので、同一依頼Noを取得しない。
        -- 倉替返品以外の場合
        IF (lt_order_tbl(gn_shori_count).shipping_shikyu_class <> gv_ship_class_3) THEN
-- 2009/01/15 H.Itou Add End 本番#981
          -- ===============================
          -- A-4同一依頼No検索処理
          -- ===============================
          get_same_request_number(lt_order_tbl(gn_shori_count).request_no,         -- 依頼No
-- 2008/12/13 v1.8 D.Nihei Add Start 本番障害#568対応
                                  lt_order_tbl(gn_shori_count).transaction_type_id,-- 受注タイプID
-- 2008/12/13 v1.8 D.Nihei Add End
                                  ln_same_request_no_count,                        -- 同一依頼No件数
                                  lt_old_order_header_id,                          -- 受注ヘッダアドオンID(OLD)
                                  lv_errbuf,                                       -- エラー・メッセージ --# 固定 #
                                  lv_retcode,                                      -- リターン・コード   --# 固定 #
                                  lv_errmsg                                        -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode <> gv_status_normal) THEN
            RAISE check_sub_main_expt;
          END IF;
-- 2009/01/15 H.Itou Add Start 本番#981
        -- 倉替返品の場合
        ELSE
          lt_old_order_header_id := lt_order_tbl(gn_shori_count).order_header_id;
        END IF;
-- 2009/01/15 H.Itou Add End 本番#981
        
--
        IF ( (lt_old_order_header_id = lt_order_tbl(gn_shori_count).order_header_id)
           OR(lt_order_tbl(gn_shori_count).shipping_shikyu_class = gv_ship_class_3)) THEN
--
          --新規登録の場合もしくは出荷支給区分が倉替返品の場合
          IF (lt_order_tbl(gn_shori_count).order_category_code = gv_order_type_order ) THEN
            --受注の場合
            gv_shori_kbn := '1'; --新規登録受注
--
            --出荷登録処理
            shipping_process(lt_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          ELSE
            --返品の場合
            gv_shori_kbn := '2'; --新規登録返品
--
            --返品登録処理
            return_process(lt_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          END IF;
          gn_new_order_cnt := gn_new_order_cnt + 1;
        ELSE
          --訂正処理の場合
--
          -- ===================================
          -- A-5訂正前受注ヘッダアドオン情報取得
          -- ===================================
          get_revised_order_info(lt_old_order_header_id,
                                 lt_revised_order_tbl,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg
          );
          IF (lv_retcode <> gv_status_normal) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_023,
                                                  gv_tkn_order_header_id,
                                                  lt_old_order_header_id
            );
            RAISE check_sub_main_expt;
          END IF;
--
          IF (lt_order_tbl(gn_shori_count).order_category_code = gv_order_type_order ) THEN
            gv_shori_kbn := '3'; --訂正登録受注
--
            --受注の場合返品登録後出荷登録
            return_process(lt_revised_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            shipping_process(lt_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          ELSE
            gv_shori_kbn := '4'; --訂正登録返品
--
            --返品の場合出荷登録後返品登録
            shipping_process(lt_revised_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            return_process(lt_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          END IF;
          gn_upd_order_cnt := gn_upd_order_cnt + 1;
        END IF;
--
        -- ===================================
        -- A-17ステータス更新
        -- ===================================
        upd_status(lv_errbuf,
                   lv_retcode,
                   lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ループ抜ける判断
        IF (gn_shori_count > lt_order_tbl.LAST ) THEN
          EXIT;
        END IF;
      END LOOP order_data_table;
--
      -- ===================================
      -- A-18移動ロット詳細(アドオン)登録
      -- ===================================
      ins_mov_lot_details(lv_errbuf,
                          lv_retcode,
                          lv_errmsg
      );
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (gn_header_if_count > 0 ) THEN
        -- ==================================================
        -- A-19受入取引オープンインタフェーステーブル登録処理
        -- ==================================================
        ins_transaction_interface(
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
-- Ver1.18 M.Hokkanji Start
     -- ==================================================
     -- A21移動ロット詳細(アドオン)更新
     -- ==================================================
      upd_mov_lot_details(lv_errbuf,
                          lv_retcode,
                          lv_errmsg
      );
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
-- Ver1.18 M.Hokkanji End
      COMMIT;
      IF (gn_cancell_cnt > 0 ) THEN
        -- =====================================
        -- A-20受入取引処理起動
        -- =====================================
        gn_req_id := FND_REQUEST.SUBMIT_REQUEST(
                      application       => gv_application     -- アプリケーション短縮名
                     ,program           => gv_program         -- プログラム名
                     ,argument1         => gv_batch           -- 処理ステータス
                     ,argument2         => gn_group_id        -- パラメータ０２
                    ) ;
        IF (gn_req_id = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                gv_msg_42a_020);
          RAISE check_sub_main_expt;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# 任意 #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      gn_error_cnt := gn_error_cnt + 1;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      -- カーソルが開いていればクローズ処理
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
    errbuf          OUT NOCOPY VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT NOCOPY VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_block        IN VARCHAR2,              --   ブロック
    iv_deliver_from IN VARCHAR2,              --   出荷元
    iv_request_no   IN VARCHAR2               --   依頼No
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --起動時間出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_006,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MM:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --区切り文字取得
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42a_003);
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(iv_block,        -- ブロック
            iv_deliver_from, --出荷元
            iv_request_no,   --依頼No
            lv_errbuf,       -- エラー・メッセージ           --# 固定 #
            lv_retcode,      -- リターン・コード             --# 固定 #
            lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
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
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42a_005);
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
    --入力パラメータ(ブロック)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_007, gv_tkn_in_block,
                                           iv_block);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --入力パラメータ(出荷元)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_008, gv_tkn_in_shipf,
                                           iv_deliver_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --入力パラメータ(依頼No)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_009,gv_tkn_request_no,
                                           iv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --入力件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_010, gv_tkn_input_cnt,
                                           TO_CHAR(gn_input_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --新規受注作成件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_011, gv_tkn_new_order,
                                           TO_CHAR(gn_new_order_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --訂正受注作成件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_012, gv_tkn_upd_order,
                                           TO_CHAR(gn_upd_order_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --取消情報件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_013, gv_tkn_cancell_cnt,
                                           TO_CHAR(gn_cancell_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --異常件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_014, gv_tkn_error_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --受入取引処理コンカレント要求ID
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_015, gv_tkn_request_id,
                                           TO_CHAR(gn_req_id));
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_42a_004,
                                           gv_tkn_status, gv_conc_status);
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END xxwsh420001c;
/
