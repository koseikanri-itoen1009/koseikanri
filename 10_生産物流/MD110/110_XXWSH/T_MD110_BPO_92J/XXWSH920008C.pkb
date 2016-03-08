create or replace PACKAGE BODY XXWSH920008C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920008C(body)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD050_BPO_920
 * MD.070           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD070_BPO_92J
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_can_enc_in_time_qty2 有効日ベース引当可能数算出API
 *  get_can_enc_qty2         引当可能数算出処理
 *  get_can_enc_qty3         引当可能数算出処理
 *  check_sql_pattern        条件パターンチェック
 *  check_parameter        A-1  入力パラメータチェック
 *  get_item_code_list     A-2  品目リスト取得
 *  fwd_sql_create         A-3  出荷用SQL文作成
 *  get_demand_inf_fwd     A-4  需要情報取得(出荷)
 *  mov_sql_create         A-5  移動用SQL文作成
 *  get_demand_inf_mov     A-6  需要情報取得(移動)
 *  get_supply_inf         A-7  供給情報取得
 *  check_lot_allot        A-8  ロット引当チェック
 *  make_allot_inf         A-9  引当情報作成処理
 *  regist_allot_inf       A-10 引当情報登録処理
 *  make_line_allot        A-11 明細引当数作成処理
 *  update_line_inf        A-12 明細情報更新処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/20   1.0   SCS北寒寺         初回作成
 *  2008/11/28   1.1   SCS北寒寺         本番障害246対応
 *  2008/11/29   1.2   SCS宮田           ロック対応
 *  2008/12/02   1.3   SCS二瓶           本番障害#251対応（条件追加）
 *  2008/12/15   1.4   SCS伊藤           本番障害#645対応（D4需要数 S4供給数 予定日から実績日に変更）
 *  2008/12/19   1.5   SCS伊藤           本番障害#648対応（I5実績未取在庫数 I6 実績未取在庫数 抽出項目を実績数－前回数に変更）
 *  2008/12/25   1.6   SCS北寒寺         本番障害#859対応 (ログのオーバーフローによりコンカレントエラーとなるため余分なログを出力しないように変更)
 *  2009/01/19   1.7   SCS二瓶           本番障害#949対応（PT対応）
 *  2009/01/26   1.8   SCS二瓶           本番障害#936対応（鮮度条件・ロット逆転PT対応）
 *                                       本番障害#332対応（条件：出庫元不備対応）
 *  2009/01/28   1.9   SCS伊藤           本番障害#1028対応（パラメータに指示部署追加）
 *  2009/03/17   1.10  SCS北寒寺         本番障害#1323対応
 *  2009/10/16   1.11  SCS菅原           本番障害#1611対応
 *  2010/01/08   1.12  SCS北寒寺         本番稼働障害#701対応
 *  2010/01/28   1.13  SCS北寒寺         本番稼働障害#1320対応
 *  2010/02/26   1.14  SCS北寒寺         本番稼働障害#1612対応
 *  2016/02/18   1.15  SCSK山下翔太      E_本稼動_13468対応
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
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
-- 2009/01/19 D.Nihei ADD START
  gd_max_date      DATE;                                    -- MAX日付
  gt_dummy_loc     mtl_item_locations.segment1%TYPE;        -- ダミー倉庫
  gt_org_id        mtl_system_items_b.organization_id%TYPE; -- マスタ組織ID
-- 2009/01/19 D.Nihei ADD END
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
  lock_expt              EXCEPTION;     -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'XXWSH920008C';        -- パッケージ名
  --メッセージ番号
  gv_msg_92a_002       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10033';    -- パラメータ未入力
  gv_msg_92a_003       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12857';    -- パラメータ書式
  gv_msg_92a_004       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12953';    -- FromTo逆転
  gv_msg_92a_005       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13306';    -- ロックビジー
  gv_msg_92a_006       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12858';    -- 共通関数エラー
  gv_msg_92a_007       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12854';    -- ロット逆転エラー
  gv_msg_92a_008       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12855';    -- 鮮度不備エラー
  gv_msg_92a_009       CONSTANT VARCHAR2(15)  := 'APP-XXWSH-11222';    -- パラメータ書式
  gv_msg_92a_010       CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10604';    -- ケース入数エラー
-- 2009/01/19 D.Nihei ADD START
  gv_error_10002       CONSTANT VARCHAR2(30)  := 'APP-XXCMN-10002';    -- プロファイル取得エラー
-- 2009/01/19 D.Nihei ADD END
-- 2010/01/08 M.Hokkanji Ver1.12 START
  gv_error_11615       CONSTANT VARCHAR2(30)  := 'APP-XXWSH-11615';    -- クローズ年月取得エラー
-- 2010/01/08 M.Hokkanji Ver1.12 END
  --定数
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- メッセージ区分XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- メッセージ区分XXCMN
  gv_cons_item_class   CONSTANT VARCHAR2(100) := '商品区分';
  gv_cons_deliv_from   CONSTANT VARCHAR2(100) := '出庫日From';
  gv_cons_deliv_to     CONSTANT VARCHAR2(100) := '出庫日To';
  gv_cons_item_no      CONSTANT VARCHAR2(100) := '品目コード';
  gv_cons_t_move       CONSTANT VARCHAR2(1)   := '5';                  -- '移動指示'(処理種別)
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '出荷依頼'
  gv_cons_biz_t_move   CONSTANT VARCHAR2(2)   := '20';                 -- '移動指示'(文書タイプ)
  gv_cons_biz_t_deliv  CONSTANT VARCHAR2(2)   := '10';                 -- '出荷依頼'
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '入力パラメータ値';   -- '入力パラメータ値'
  gv_cons_flg_yes      CONSTANT VARCHAR2(1)   := 'Y';                  -- フラグ 'Y'
  gv_cons_flg_no       CONSTANT VARCHAR2(1)   := 'N';                  -- フラグ 'N'
  gv_cons_notif_status CONSTANT VARCHAR2(3)   := '40';                 -- 「確定通知済」
  gv_cons_status       CONSTANT VARCHAR2(2)   := '03';                 -- 「締め済み」
  gv_cons_lot_ctl      CONSTANT VARCHAR2(1)   := '1';                  -- 「ロット管理品」
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- 「製品」
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- 「積送あり」
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- 「調整中」
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- 「依頼済」
  gv_cons_order_lines  CONSTANT VARCHAR2(50)  := '受注明細アドオン';
  gv_cons_instr_lines  CONSTANT VARCHAR2(50)  := '移動依頼/指示明細(アドオン)';
  gv_cons_wrn_reversal CONSTANT VARCHAR2(2)   := '30';                 -- 「ロット逆転」
  gv_cons_wrn_fresh    CONSTANT VARCHAR2(2)   := '40';                 -- 「鮮度不備」
  gv_cons_error        CONSTANT VARCHAR2(1)   := '1';                  -- 共通関数でのエラー
  gv_cons_no_judge     CONSTANT VARCHAR2(2)   := '10';                 -- 「未判定」
  gv_cons_am_auto      CONSTANT VARCHAR2(2)   := '10';                 -- 「自動引当」
  gv_cons_rec_type     CONSTANT VARCHAR2(2)   := '10';                 -- 「指示」
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- 商品区分・ドリンク
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- 商品区分・リーフ
  gv_cons_deliv_fm     CONSTANT VARCHAR2(50)  := '出荷元';             -- 出荷元
  gv_cons_deliv_tp     CONSTANT VARCHAR2(50)  := '出荷形態';           -- 出荷形態^
  gv_cons_number       CONSTANT VARCHAR2(50)  := '数値';               -- 数値^
  --トークン
  gv_tkn_parm_name     CONSTANT VARCHAR2(15)  := 'PARM_NAME';          -- パラメータ
  gv_tkn_param_name    CONSTANT VARCHAR2(15)  := 'PARAM_NAME';         -- パラメータ
  gv_tkn_parameter     CONSTANT VARCHAR2(15)  := 'PARAMETER';          -- パラメータ名
  gv_tkn_type          CONSTANT VARCHAR2(15)  := 'TYPE';               -- 書式タイプ
  gv_tkn_table         CONSTANT VARCHAR2(15)  := 'TABLE';              -- テーブル
  gv_tkn_err_code      CONSTANT VARCHAR2(15)  := 'ERR_CODE';           -- エラーコード
  gv_tkn_err_msg       CONSTANT VARCHAR2(15)  := 'ERR_MSG';            -- エラーメッセージ
  gv_tkn_ship_type     CONSTANT VARCHAR2(15)  := 'SHIP_TYPE';          -- 配送先
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- 品目
  gv_tkn_lot           CONSTANT VARCHAR2(15)  := 'LOT';                -- ロットNo
  gv_tkn_request_type  CONSTANT VARCHAR2(15)  := 'REQUEST_TYPE';       -- 依頼No/移動番号_区分
  gv_tkn_p_date        CONSTANT VARCHAR2(15)  := 'P_DATE';             -- 製造日
  gv_tkn_use_by_date   CONSTANT VARCHAR2(15)  := 'USE_BY_DATE';        -- 賞味期限
  gv_tkn_fix_no        CONSTANT VARCHAR2(15)  := 'FIX_NO';             -- 固有記号
  gv_tkn_request_no    CONSTANT VARCHAR2(15)  := 'REQUEST_NO';         -- 依頼No
  gv_tkn_item_no       CONSTANT VARCHAR2(15)  := 'ITEM_NO';            -- 品目コード
  gv_tkn_reverse_date  CONSTANT VARCHAR2(15)  := 'REVDATE';            -- 逆転日付
  gv_tkn_arrival_date  CONSTANT VARCHAR2(15)  := 'ARRIVAL_DATE';       -- 着荷日付
  gv_tkn_ship_to       CONSTANT VARCHAR2(15)  := 'SHIP_TO';            -- 配送先
  gv_tkn_standard_date CONSTANT VARCHAR2(15)  := 'STANDARD_DATE';      -- 基準日付
  gv_request_name_ship CONSTANT VARCHAR2(15)  := '依頼No';             -- 依頼No
  gv_request_name_move CONSTANT VARCHAR2(15)  := '移動番号';           -- 移動番号
  gv_ship_name_ship    CONSTANT VARCHAR2(15)  := '配送先';             -- 配送先
  gv_ship_name_move    CONSTANT VARCHAR2(15)  := '入庫先';             -- 入庫先
-- 2009/01/19 D.Nihei ADD START
  gv_tkn_ng_profile    CONSTANT VARCHAR2(30)  := 'NG_PROFILE';         -- トークン
-- 2009/01/19 D.Nihei ADD END
  --プロファイル
  gv_prf_item_div      CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';     -- 商品区分
  gv_prf_article_div   CONSTANT VARCHAR2(100) := 'XXCMN_ARTICLE_DIV';  -- 品目区分
  gv_action_type_ship  CONSTANT VARCHAR2(2)   := '1';                  -- 出荷
  gv_action_type_move  CONSTANT VARCHAR2(2)   := '3';                  -- 移動
  gv_min_default_date  CONSTANT VARCHAR2(10)  := '1900/01/01';         --MINDATE
  gv_base              CONSTANT VARCHAR2(1)   := '1'; -- 拠点
  gv_wzero             CONSTANT VARCHAR2(2)   := '00';
  gv_flg_no            CONSTANT VARCHAR2(1)   := 'N';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_target_cnt_deliv  NUMBER :=0;           -- 対象件数(出荷)
  gn_target_cnt_move   NUMBER :=0;           -- 対象件数(移動)
  gn_target_cnt_total  NUMBER :=0;           -- 対象件数(出荷+移動)
  gd_yyyymmdd_from     DATE;                 -- 入力パラメータ出庫日From
  gd_yyyymmdd_to       DATE;                 -- 入力パラメータ出庫日To
  gv_yyyymmdd_from     VARCHAR2(10);         -- 入力パラメータ出庫日From
  gv_yyyymmdd_to       VARCHAR2(10);         -- 入力パラメータ出庫日To
  gv_item_div          VARCHAR2(10);         -- プロファイルから取得する'商品区分'
  gv_article_div       VARCHAR2(10);         -- プロファイルから取得する'品名区分'
  gn_organization_id   NUMBER;               -- マスタ組織ID
  gn_login_user        NUMBER;               -- ログインID
  gn_created_by        NUMBER;               -- ログインユーザID
  gn_conc_request_id   NUMBER;               -- 要求ID
  gn_prog_appl_id      NUMBER;               -- アプリケーションID
  gn_conc_program_id   NUMBER;               -- プログラムID
  gv_item_class        xxcmn_lot_status_v.prod_class_code%TYPE;  -- 商品区分
--
  gn_move_rec_cnt      NUMBER := 0;          -- 引当情報処理カウンタ
  gn_odr_cnt           NUMBER := 0;          -- 受注明細アドオン変数カウンタ(gr_order_tbl)
  gn_mov_cnt           NUMBER := 0;          -- 受注明細アドオン変数カウンタ(gr_req_tbl)
--
  gv_request_type      VARCHAR2(20);         -- 依頼No/移動番号_区分
--
-- 2010/01/08 M.Hokkanji Ver1.12 START
  gn_lot_cnt             NUMBER;             -- 取得ロット件数(デバッグ用)
  gn_get_can_enc_qty_cnt NUMBER;             -- 引当可能数取得件数(デバッグ用)
-- 2010/01/08 M.Hokkanji Ver1.12 END
-- 2010/01/08 M.Hokkanji Ver1.12 START
  gd_open_date         DATE;                 -- オープン日付
-- 2010/01/08 M.Hokkanji Ver1.12 END
-- 2008/11/13 M.Hokkanji PT START
  gv_item_code_list    VARCHAR2(4000);
-- 2008/11/13 M.Hokkanji PT END
  -- 需要情報の依頼No,移動番号を格納する(処理件数算出のため)
  TYPE number_rec IS RECORD(
    request_no                 xxwsh_order_headers_all.request_no%TYPE
     -- 依頼No or 移動番号
  );
  TYPE number_tbl IS TABLE OF number_rec INDEX BY PLS_INTEGER;
  gr_number_tbl  number_tbl;
--
  -- 需要情報のデータを格納するレコード
  TYPE demand_rec IS RECORD(
    document_type_code         xxinv_mov_lot_details.document_type_code%TYPE,           -- 文書タイプ V
    request_no                 xxwsh_order_headers_all.request_no%TYPE,                 -- 依頼No
    distribution_block         xxcmn_item_locations2_v.distribution_block%TYPE,         -- ブロック V
    deliver_from               xxwsh_order_headers_all.deliver_from%TYPE,               -- 出庫元 V
    deliver_from_id            xxwsh_order_headers_all.deliver_from_id%TYPE,            -- 出庫元ID N
    schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE,         -- 出庫予定日 D
    schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE,      -- 入庫予定日 D
    header_id                  xxwsh_order_headers_all.header_id%TYPE,                  -- ヘッダID N
    deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE,                 -- 配送先 V
    deliver_to_id              xxwsh_order_headers_all.deliver_to_id%TYPE,              -- 配送先ID N
    reserve_order              xxcmn_cust_accounts2_v.reserve_order%TYPE,               -- 拠点引当順 N
    order_line_id              xxwsh_order_lines_all.order_line_id%TYPE,                -- 明細ID N
    shipping_item_code         xxwsh_order_lines_all.shipping_item_code%TYPE,           -- 品目(コード) V
    item_id                    xxcmn_item_mst2_v.item_id%TYPE,                          -- OPM品目ID N
    ordered_quantity           xxwsh_order_lines_all.quantity%TYPE,                     -- 指示数量 N
    rest_quantity              xxwsh_order_lines_all.quantity%TYPE,                     -- 引当残数量 N
    reserved_quantity          xxwsh_order_lines_all.reserved_quantity%TYPE,            -- 引当数量 N
    designated_production_date xxwsh_order_headers_all.designated_production_date%TYPE, -- 指定製造日 D
    frequent_whse_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE,      -- 代表倉庫区分 V
    frequent_whse              xxcmn_item_locations2_v.frequent_whse%TYPE,              -- 代表倉庫 V
    inventory_location_id      xxcmn_item_locations2_v.inventory_location_id%TYPE,      -- 代表保管棚ID
    num_of_cases               xxcmn_item_mst2_v.num_of_cases%TYPE,                     -- ケース入数 N
    conv_unit                  xxcmn_item_mst2_v.conv_unit%TYPE                         -- 入出庫換算単位 V
  );
  TYPE demand_tbl IS TABLE OF demand_rec INDEX BY PLS_INTEGER;
  gr_demand_tbl  demand_tbl;
--
  -- 需要情報のデータを格納するレコード(移動用⇒後にdemand_recに合体する)
  TYPE demand_rec2 IS RECORD(
    document_type_code         xxinv_mov_lot_details.document_type_code%TYPE,           -- 文書タイプ V
    mov_num                    xxinv_mov_req_instr_headers.mov_num%TYPE,                -- 移動番号
    distribution_block         xxcmn_item_locations2_v.distribution_block%TYPE,         -- ブロック V
    deliver_from               xxwsh_order_headers_all.deliver_from%TYPE,               -- 出庫元 V
    deliver_from_id            xxwsh_order_headers_all.deliver_from_id%TYPE,            -- 出庫元ID N
    schedule_ship_date         xxwsh_order_headers_all.schedule_ship_date%TYPE,         -- 出庫予定日 D
    schedule_arrival_date      xxwsh_order_headers_all.schedule_arrival_date%TYPE,      -- 入庫予定日 D
    header_id                  xxwsh_order_headers_all.header_id%TYPE,                  -- ヘッダID N
    deliver_to                 xxwsh_order_headers_all.deliver_to%TYPE,                 -- 配送先 V
    deliver_to_id              xxwsh_order_headers_all.deliver_to_id%TYPE,              -- 配送先ID N
    reserve_order              xxcmn_cust_accounts2_v.reserve_order%TYPE,               -- 拠点引当順 N
    order_line_id              xxwsh_order_lines_all.order_line_id%TYPE,                -- 明細ID N
    shipping_item_code         xxwsh_order_lines_all.shipping_item_code%TYPE,           -- 品目(コード) V
    item_id                    xxcmn_item_mst2_v.item_id%TYPE,                          -- OPM品目ID N
    ordered_quantity           xxwsh_order_lines_all.quantity%TYPE,                     -- 指示数量 N
    rest_quantity              xxwsh_order_lines_all.quantity%TYPE,                     -- 引当残数量 N
    reserved_quantity          xxwsh_order_lines_all.reserved_quantity%TYPE,            -- 引当数量 N
    designated_production_date xxwsh_order_headers_all.designated_production_date%TYPE, -- 指定製造日 D
    frequent_whse_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE,      -- 代表倉庫区分 V
    frequent_whse              xxcmn_item_locations2_v.frequent_whse%TYPE,              -- 代表倉庫 V
    inventory_location_id      xxcmn_item_locations2_v.inventory_location_id%TYPE,      -- 代表保管棚ID
    num_of_cases               xxcmn_item_mst2_v.num_of_cases%TYPE,                     -- ケース入数 N
    conv_unit                  xxcmn_item_mst2_v.conv_unit%TYPE                         -- 入出庫換算単位 V
  );
  TYPE demand_tbl2 IS TABLE OF demand_rec2 INDEX BY PLS_INTEGER;
  gr_demand_tbl2  demand_tbl2;
--
  -- 供給情報のデータを格納するレコード
  TYPE supply_rec IS RECORD(
    lot_id      ic_lots_mst.lot_id%TYPE,                                 -- ロットID
    lot_no      ic_lots_mst.lot_no%TYPE,                                 -- ロットNo
    lot_status  ic_lots_mst.attribute23%TYPE,                            -- ロットステータス
    p_date      ic_lots_mst.attribute1%TYPE,                             -- 製造年月日
    fix_no      ic_lots_mst.attribute2%TYPE,                             -- 固有番号
    use_by_date ic_lots_mst.attribute3%TYPE,                             -- 賞味期限
    r_quantity  xxwsh_order_lines_all.reserved_quantity%TYPE             -- 引当可能数
  );
  TYPE supply_tbl IS TABLE OF supply_rec INDEX BY PLS_INTEGER;
  gr_supply_tbl  supply_tbl;
--
  -- チェック処理結果を格納するレコード
  TYPE check_rec IS RECORD(
    warnning_class VARCHAR2(2),                 -- 警告区分
    warnning_date  DATE,                        -- 警告日付
    lot_no         ic_lots_mst.lot_no%TYPE,     -- ロットNo
    p_date         ic_lots_mst.attribute1%TYPE, -- 製造年月日
    fix_no         ic_lots_mst.attribute2%TYPE, -- 固有番号
    use_by_date    ic_lots_mst.attribute3%TYPE, -- 賞味期限
-- Ver1.01 M.Hokkanji Start
    max_rev_qty    NUMBER,                      -- 最大引当可能数
    max_lot_no     ic_lots_mst.lot_no%TYPE,     -- ロットNo
    rev_qty        NUMBER                       -- 初期引当数量
-- Ver1.01 M.Hokkanji End
  );
  TYPE check_tbl IS TABLE OF check_rec INDEX BY PLS_INTEGER;
  gr_check_tbl  check_tbl;
-- Ver1.01 M.Hokkanji Start
   gv_ship_sql VARCHAR2(8000); --出荷SQL
   gv_move_sql VARCHAR2(8000); --移動SQL
-- Ver1.01 M.Hokkanji End
--
  -- 移動ロット詳細データを格納するレコード
  TYPE move_rec IS RECORD(
    mov_lot_dtl_id           xxinv_mov_lot_details.mov_lot_dtl_id%TYPE,           -- ロット詳細ID
    mov_line_id              xxinv_mov_lot_details.mov_line_id%TYPE,              -- 明細ID
    document_type_code       xxinv_mov_lot_details.document_type_code%TYPE,       -- 文書タイプ
    record_type_code         xxinv_mov_lot_details.record_type_code%TYPE,         -- レコードタイプ
    item_id                  xxinv_mov_lot_details.item_id%TYPE,                  -- OPM品目ID
    item_code                xxinv_mov_lot_details.item_code%TYPE,                -- 品目
    lot_id                   xxinv_mov_lot_details.lot_id%TYPE,                   -- ロットID
    lot_no                   xxinv_mov_lot_details.lot_no%TYPE,                   -- ロットNo
    actual_date              xxinv_mov_lot_details.actual_date%TYPE,              -- 実績日
    actual_quantity          xxinv_mov_lot_details.actual_quantity%TYPE,          -- 実績数量
    automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE, -- 自動手動引当区分
    created_by               xxinv_mov_lot_details.created_by%TYPE,               -- 作成者
    creation_date            xxinv_mov_lot_details.creation_date%TYPE,            -- 作成日
    last_updated_by          xxinv_mov_lot_details.last_updated_by%TYPE,          -- 最終更新者
    last_update_date         xxinv_mov_lot_details.last_update_date%TYPE,         -- 最終更新日
    last_update_login        xxinv_mov_lot_details.last_update_login%TYPE,        -- 最終更新ログイン
    request_id               xxinv_mov_lot_details.request_id%TYPE,               -- 要求ID
    program_application_id   xxinv_mov_lot_details.program_application_id%TYPE,   -- アプリケーションID
    program_id               xxinv_mov_lot_details.program_id%TYPE,               -- プログラムID
    program_update_date      xxinv_mov_lot_details.program_update_date%TYPE       -- プログラム更新日
  );
  TYPE move_tbl IS TABLE OF move_rec INDEX BY PLS_INTEGER;
  gr_move_tbl  move_tbl;
--
  -- 受注明細アドオンデータを格納するレコード
  TYPE order_rec IS RECORD(
    order_line_id            xxwsh_order_lines_all.order_line_id%TYPE,            -- 受注明細アドオンID
    reserved_quantity        xxwsh_order_lines_all.reserved_quantity%TYPE,        -- 引当数
    warning_class            xxwsh_order_lines_all.warning_class%TYPE,            -- 警告区分
    warning_date             xxwsh_order_lines_all.warning_date%TYPE,             -- 警告日付
    automanual_reserve_class xxwsh_order_lines_all.automanual_reserve_class%TYPE, -- 自動手動引当区分
    last_updated_by          xxwsh_order_lines_all.last_updated_by%TYPE,          -- 最終更新者
    last_update_date         xxwsh_order_lines_all.last_update_date%TYPE,         -- 最終更新日
    last_update_login        xxwsh_order_lines_all.last_update_login%TYPE,        -- 最終更新ログイン
    request_id               xxwsh_order_lines_all.request_id%TYPE,               -- 要求ID
    program_application_id   xxwsh_order_lines_all.program_application_id%TYPE,   -- アプリケーションID
    program_id               xxwsh_order_lines_all.program_id%TYPE,               -- プログラムID
    program_update_date      xxwsh_order_lines_all.program_update_date%TYPE       -- プログラム更新日
  );
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  gr_order_tbl  order_tbl;
--
  -- 移動依頼/指示明細アドオンデータを格納するレコード
  TYPE req_rec IS RECORD(
    mov_line_id              xxinv_mov_req_instr_lines.mov_line_id%TYPE,              -- 移動明細ID
    reserved_quantity        xxinv_mov_req_instr_lines.reserved_quantity%TYPE,        -- 引当数量
    warning_class            xxinv_mov_req_instr_lines.warning_class%TYPE,            -- 警告区分
    warning_date             xxinv_mov_req_instr_lines.warning_date%TYPE,             -- 警告日付
    automanual_reserve_class xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE, -- 自動手動引当区分
    last_updated_by          xxinv_mov_req_instr_lines.last_updated_by%TYPE,          -- 最終更新者
    last_update_date         xxinv_mov_req_instr_lines.last_update_date%TYPE,         -- 最終更新日
    last_update_login        xxinv_mov_req_instr_lines.last_update_login%TYPE,        -- 最終更新ログイン
    request_id               xxinv_mov_req_instr_lines.request_id%TYPE,               -- 要求ID
    program_application_id   xxinv_mov_req_instr_lines.program_application_id%TYPE,   -- アプリケーションID
    program_id               xxinv_mov_req_instr_lines.program_id%TYPE,               -- プログラムID
    program_update_date      xxinv_mov_req_instr_lines.program_update_date%TYPE       -- プログラム更新日
  );
  TYPE req_tbl IS TABLE OF req_rec INDEX BY PLS_INTEGER;
  gr_req_tbl  req_tbl;
--
  -- 移動ロット詳細情報(FORALLでのINSERT用)
  TYPE i_mov_lot_dtl_id              -- ロット詳細ID
    IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_mov_line_id                 -- 明細ID
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_document_type_code          -- 文書タイプ
    IS TABLE OF xxinv_mov_lot_details.document_type_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_record_type_code            -- レコードタイプ
    IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_id                     -- OPM品目ID
    IS TABLE OF xxinv_mov_lot_details.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                   -- 品目
    IS TABLE OF xxinv_mov_lot_details.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_lot_id                      -- ロットID
    IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_lot_no                      -- ロットNo
    IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_actual_date                 -- 実績日
    IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_actual_quantity             -- 実績数量
    IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_automanual_reserve_class    -- 自動手動引当区分
    IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_created_by                  -- 作成者
    IS TABLE OF xxinv_mov_lot_details.created_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_creation_date               -- 作成日
    IS TABLE OF xxinv_mov_lot_details.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_updated_by             -- 最終更新者
    IS TABLE OF xxinv_mov_lot_details.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_update_date            -- 最終更新日
    IS TABLE OF xxinv_mov_lot_details.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_last_update_login           -- 最終更新ログイン
    IS TABLE OF xxinv_mov_lot_details.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_request_id                  -- 要求ID
    IS TABLE OF xxinv_mov_lot_details.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_application_id      -- アプリケーションID
    IS TABLE OF xxinv_mov_lot_details.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_id                  -- プログラムID
    IS TABLE OF xxinv_mov_lot_details.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_program_update_date         -- プログラム更新日
    IS TABLE OF xxinv_mov_lot_details.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 受注アドオンデータ情報(FORALLでのINSERT用)
  TYPE j_order_line_id               -- 受注明細アドオンID
    IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_reserved_quantity           -- 引当数
    IS TABLE OF xxwsh_order_lines_all.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_warning_class               -- 警告区分
    IS TABLE OF xxwsh_order_lines_all.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_warning_date                -- 警告日付
    IS TABLE OF xxwsh_order_lines_all.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_automanual_reserve_class    -- 自動手動引当区分
    IS TABLE OF xxwsh_order_lines_all.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_updated_by             -- 最終更新者
    IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_update_date            -- 最終更新日
    IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_last_update_login           -- 最終更新ログイン
    IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_request_id                  -- 要求ID
    IS TABLE OF xxwsh_order_lines_all.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_application_id      -- アプリケーションID
    IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_id                  -- プログラムID
    IS TABLE OF xxwsh_order_lines_all.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE j_program_update_date         -- プログラム更新日
    IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 移動依頼/指示明細アドオンデータ情報(FORALLでのINSERT用)
  TYPE m_mov_line_id                 -- 移動明細ID
    IS TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_reserved_quantity             -- 引当数量
    IS TABLE OF xxinv_mov_req_instr_lines.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_warning_class               -- 警告区分
    IS TABLE OF xxinv_mov_req_instr_lines.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_warning_date                -- 警告日付
    IS TABLE OF xxinv_mov_req_instr_lines.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_automanual_reserve_class    -- 自動手動引当区分
    IS TABLE OF xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_updated_by             -- 最終更新者
    IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_update_date            -- 最終更新日
    IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_last_update_login           -- 最終更新ログイン
    IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_request_id                  -- 要求ID
    IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_application_id      -- アプリケーションID
    IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_id                  -- プログラムID
    IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE m_program_update_date         -- プログラム更新日
    IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 移動ロット詳細情報(FORALLでのINSERT用)
  gt_i_mov_lot_dtl_id           i_mov_lot_dtl_id;             -- ロット詳細ID
  gt_i_mov_line_id              i_mov_line_id;                -- 明細ID
  gt_i_document_type_code       i_document_type_code;         -- 文書タイプ
  gt_i_record_type_code         i_record_type_code;           -- レコードタイプ
  gt_i_item_id                  i_item_id;                    -- OPM品目ID
  gt_i_item_code                i_item_code;                  -- 品目
  gt_i_lot_id                   i_lot_id;                     -- ロットID
  gt_i_lot_no                   i_lot_no;                     -- ロットNo
  gt_i_actual_date              i_actual_date;                -- 実績日
  gt_i_actual_quantity          i_actual_quantity;            -- 実績数量
  gt_i_automanual_reserve_class i_automanual_reserve_class;   -- 自動手動引当区分
  gt_i_created_by               i_created_by;                 -- 作成者
  gt_i_creation_date            i_creation_date;              -- 作成日
  gt_i_last_updated_by          i_last_updated_by;            -- 最終更新者
  gt_i_last_update_date         i_last_update_date;           -- 最終更新日
  gt_i_last_update_login        i_last_update_login;          -- 最終更新ログイン
  gt_i_request_id               i_request_id;                 -- 要求ID
  gt_i_program_application_id   i_program_application_id;     -- アプリケーションID
  gt_i_program_id               i_program_id;                 -- プログラムID
  gt_i_program_update_date      i_program_update_date;        -- プログラム更新日
--
  -- 受注アドオンデータ情報(FORALLでのINSERT用)
  gt_j_order_line_id            j_order_line_id;              -- 受注明細アドオンID
  gt_j_reserved_quantity        j_reserved_quantity;          -- 引当数
  gt_j_warning_class            j_warning_class;              -- 警告区分
  gt_j_warning_date             j_warning_date;               -- 警告日付
  gt_j_automanual_reserve_class j_automanual_reserve_class;   -- 自動手動引当区分
  gt_j_last_updated_by          j_last_updated_by;            -- 最終更新者
  gt_j_last_update_date         j_last_update_date;           -- 最終更新日
  gt_j_last_update_login        j_last_update_login;          -- 最終更新ログイン
  gt_j_request_id               j_request_id;                 -- 要求ID
  gt_j_program_application_id   j_program_application_id;     -- アプリケーションID
  gt_j_program_id               j_program_id;                 -- プログラムID
  gt_j_program_update_date      j_program_update_date;        -- プログラム更新日
--
  -- 移動依頼/指示明細アドオンデータ情報(FORALLでのINSERT用)
  gt_m_mov_line_id              m_mov_line_id;                -- 移動明細ID
  gt_m_reserved_quantity        m_reserved_quantity;          -- 引当数量
  gt_m_warning_class            m_warning_class;              -- 警告区分
  gt_m_warning_date             m_warning_date;               -- 警告日付
  gt_m_automanual_reserve_class m_automanual_reserve_class;   -- 自動手動引当区分
  gt_m_last_updated_by          m_last_updated_by;            -- 最終更新者
  gt_m_last_update_date         m_last_update_date;           -- 最終更新日
  gt_m_last_update_login        m_last_update_login;          -- 最終更新ログイン
  gt_m_request_id               m_request_id;                 -- 要求ID
  gt_m_program_application_id   m_program_application_id;     -- アプリケーションID
  gt_m_program_id               m_program_id;                 -- プログラムID
  gt_m_program_update_date      m_program_update_date;        -- プログラム更新日
--
  /**********************************************************************************
   * Function Name    : check_number_tbl
   * Description      : 移動No配列存在チェック
   * Return           : 0=存在しない、0>存在する(添字)
   ***********************************************************************************/
  FUNCTION check_number_tbl(
    iv_request_no      IN VARCHAR2)       -- 移動番号 or 依頼No
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_number_tbl'; --プログラム名
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
    -- *** ローカル変数 ***
    ln_cnt      NUMBER := 0;
--
  BEGIN
--
    -- 依頼No配列検索ループ
    <<number_loop>>
    FOR ln_cnt IN 1..NVL(gr_number_tbl.LAST, 0) LOOP
      -- 配列に存在した
      IF ( gr_number_tbl(ln_cnt).request_no = iv_request_no ) THEN
        RETURN 0;
      END IF;
    END LOOP number_loop;
--
    -- 処理件数カウントアップ
    gn_target_cnt := gn_target_cnt + 1;
--
    -- 配列に存在しないので格納して添え字を返す
-- Ver1.01 M.Hokkanji Start
-- Ver1.6 M.Hokkanji Start
--   FND_FILE.PUT_LINE(FND_FILE.LOG,'処理依頼NO：' || iv_request_no);
-- Ver1.6 M.Hokkanji End
-- Ver1.01 M.Hokkanji End
    gr_number_tbl(NVL(gr_number_tbl.LAST, 0) + 1).request_no := iv_request_no;
    RETURN ln_cnt;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
       (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_number_tbl;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty2
   * Description      : 有効日ベース引当可能数算出API
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty2(
      in_whse_id          IN NUMBER                    -- OPM保管倉庫ID
    , iv_whse_code        IN VARCHAR2                  -- OPM保管倉庫コード
    , in_item_id          IN NUMBER                    -- OPM品目ID
    , iv_item_code        IN VARCHAR2                  -- OPM品目コード
    , in_lot_id           IN NUMBER DEFAULT NULL       -- ロットID
    , in_active_date      IN DATE   DEFAULT NULL)      -- 有効日
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty2'; --プログラム名
    cv_flag_off       CONSTANT VARCHAR2(1)   := 'N';                        -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)   := 'Y';                        -- ON
    cv_cate_order     CONSTANT VARCHAR2(10)  := 'ORDER';                    -- 受注
    cv_cate_return    CONSTANT VARCHAR2(10)  := 'RETURN';                   -- 返品
    cv_doc_ship       CONSTANT VARCHAR2(2)   := '10';                       -- 文書タイプ「出荷」
    cv_doc_mov        CONSTANT VARCHAR2(2)   := '20';                       -- 文書タイプ「移動」
    cv_doc_prov       CONSTANT VARCHAR2(2)   := '30';                       -- 文書タイプ「支給指示」
    cv_doc_prod       CONSTANT VARCHAR2(2)   := '40';                       -- 文書タイプ「生産指示」
    cv_doc_po         CONSTANT VARCHAR2(2)   := '50';                       -- 文書タイプ「発注」
    cv_rec_instruct   CONSTANT VARCHAR2(2)   := '10';                       -- レコードタイプ「指示」
    cv_rec_shipped    CONSTANT VARCHAR2(2)   := '20';                       -- レコードタイプ「出庫実績」
    cv_rec_ship_to    CONSTANT VARCHAR2(2)   := '30';                       -- レコードタイプ「入庫実績」
    cv_rec_invest     CONSTANT VARCHAR2(2)   := '40';                       -- レコードタイプ「投入済」
    cv_status_02      CONSTANT VARCHAR2(2)   := '02';                       -- 依頼済み
    cv_status_03      CONSTANT VARCHAR2(2)   := '03';                       -- 調整中
    cv_status_04      CONSTANT VARCHAR2(2)   := '04';                       -- 出庫報告有
    cv_status_05      CONSTANT VARCHAR2(2)   := '05';                       -- 入庫報告有
    cv_status_06      CONSTANT VARCHAR2(2)   := '06';                       -- 入出庫報告有
    cv_status_07      CONSTANT VARCHAR2(2)   := '07';                       -- 受領済
    cv_status_08      CONSTANT VARCHAR2(2)   := '08';                       -- 出荷実績計上済
    cv_type_ship      CONSTANT VARCHAR2(1)   := '1';                        -- 出荷依頼
    cv_type_prov      CONSTANT VARCHAR2(1)   := '2';                        -- 支給依頼
    cv_type_whse      CONSTANT VARCHAR2(1)   := '3';                        -- 倉替
    cn_line_material  CONSTANT NUMBER(5,0)   := -1;                         -- 投入品
    cn_status_wip     CONSTANT NUMBER(5,0)   := 2;                          -- WIP
    cn_status_pnd     CONSTANT NUMBER(5,0)   := 1;                          -- 保留
    cv_po_order_fin   CONSTANT VARCHAR2(2)   := '20';                       -- 発注作成済
    cv_po_accept      CONSTANT VARCHAR2(2)   := '25';                       -- 受入あり
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
    ln_whse_id     NUMBER;        -- 保管倉庫ID
    ln_item_id     NUMBER;        -- 品目ID
    ln_lot_id      NUMBER;        -- ロットID
    ln_item_code   VARCHAR2(40);  -- 品目コード
    lv_whse_code   VARCHAR2(40);  -- 保管倉庫コード
    lv_rep_whse    VARCHAR2(150); -- 代表倉庫
    lv_item_code   VARCHAR2(32);  -- 品目コード
    lv_lot_no      VARCHAR2(32);  -- ロットNO
    ld_eff_date    DATE;          -- 有効日
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    -- *** ローカル定数 ***
    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX日付'; --プロファイル名
--
    ln_inv_lot_onhand             NUMBER; -- ロット I0)結果数量
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ロット I1)結果数量
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ロット I2)結果数量
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ロット I3)結果数量
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ロット I4)結果数量
    ln_inv_lot_ship_qty           NUMBER; -- ロット I5)結果数量
    ln_inv_lot_provide_qty        NUMBER; -- ロット I6)結果数量
    ln_inv_lot_in_inout_bef_qty   NUMBER; -- ロット I7)結果数量(訂正前)
    ln_inv_lot_in_inout_cor_qty   NUMBER; -- ロット I7)結果数量(訂正後)
    ln_inv_lot_out_inout_bef_qty  NUMBER; -- ロット I8)結果数量(訂正前)
    ln_inv_lot_out_inout_cor_qty  NUMBER; -- ロット I8)結果数量(訂正後)
    ln_sup_lot_inv_in_qty         NUMBER; -- ロット S1)結果数量
    ln_sup_lot_inv_out_qty        NUMBER; -- ロット S4)結果数量
    ln_dem_lot_ship_qty           NUMBER; -- ロット D1)結果数量
    ln_dem_lot_provide_qty        NUMBER; -- ロット D2)結果数量
    ln_dem_lot_inv_out_qty        NUMBER; -- ロット D3)結果数量
    ln_dem_lot_inv_in_qty         NUMBER; -- ロット D4)結果数量
    ln_dem_lot_produce_qty        NUMBER; -- ロット D5)結果数量
    ln_dem_lot_order_qty          NUMBER; -- ロット D6)結果数量
--
    ln_stock_qty  NUMBER; -- 在庫数
    ln_supply_qty NUMBER; -- 供給数
    ln_demand_qty NUMBER; -- 需要数
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    ln_stock_qty  := 0;
    ln_supply_qty := 0;
    ln_demand_qty := 0;
--
    -- 有効日を取得
    IF ( in_active_date IS NULL ) THEN
        -- MAX日付を取得
      ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD');
      IF ( ld_eff_date IS NULL ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10002',
                                              'NG_PROFILE',
                                              cv_prf_max_date_name);
        RAISE process_exp;
      END IF;
    ELSE
      ld_eff_date := in_active_date;
    END IF;
--
    -- ロット I0 EBS手持在庫
    SELECT NVL(SUM(ili.loct_onhand), 0)
    INTO   ln_inv_lot_onhand
    FROM   ic_loct_inv ili  -- 手持数量
    WHERE  ili.location = iv_whse_code
    AND    ili.item_id  = in_item_id
    AND    ili.lot_id   = in_lot_id
    ;
--
    -- ロット I1 実績未取在庫数  移動入庫（入出庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_in_inout_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ロット I2 実績未取在庫数  移動入庫（入庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_in_in_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_05
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ロット I3 実績未取在庫数  移動出庫（入出庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_out_inout_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ロット I4 実績未取在庫数  移動出庫（出庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_out_out_rpt_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_status_04
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_shipped
    ;
--
    -- ロット I5 実績未取在庫数  出荷
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
-- 2008/12/19 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
-- 2008/12/19 H.Itou Mod End
                      WHEN (otta.order_category_code = cv_cate_return) THEN
-- 2008/12/19 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity * -1
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
-- 2008/12/19 H.Itou Mod End
                    END), 0)
    INTO    ln_inv_lot_ship_qty
    FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
          , xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
          , xxinv_mov_lot_details      mld  -- 移動ロット詳細（アドオン）
          , oe_transaction_types_all   otta -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_04
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_ship
    AND     mld.record_type_code      = cv_rec_shipped
    AND     otta.attribute1           IN (cv_type_ship, cv_type_whse)
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ロット I6 実績未取在庫数  支給
    SELECT  /*+ leading(oha otta ola mld) */
            NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
-- 2008/12/19 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity
                        NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
-- 2008/12/19 H.Itou Mod End
                      WHEN (otta.order_category_code = cv_cate_return) THEN
-- 2008/12/19 H.Itou Mod Start 本番障害#648
--                        mld.actual_quantity * -1
                       (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
-- 2008/12/19 H.Itou Mod End
                    END), 0)
    INTO    ln_inv_lot_provide_qty
    FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
          , xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
          , xxinv_mov_lot_details      mld  -- 移動ロット詳細（アドオン）
          , oe_transaction_types_all   otta -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_08
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_prov
    AND     mld.record_type_code      = cv_rec_shipped
    AND     otta.attribute1           = cv_type_prov
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ロット I7 実績未取在庫数  移動入庫訂正（入出庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity), 0),
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_in_inout_bef_qty,
            ln_inv_lot_in_inout_cor_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
            xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
            xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    AND     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_ship_to
    ;
--
    -- ロット I8 実績未取在庫数  移動出庫訂正（入出庫報告有）
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.before_actual_quantity), 0),
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_inv_lot_out_inout_bef_qty,
            ln_inv_lot_out_inout_cor_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_on
    and     mrih.correct_actual_flg = cv_flag_on
    AND     mrih.status             = cv_status_06
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_mov
    AND     mld.record_type_code    = cv_rec_shipped
    ;
--
    -- ロット S1)供給数  移動入庫予定
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_sup_lot_inv_in_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.ship_to_locat_id        = in_whse_id
    AND     mrih.comp_actual_flg         = cv_flag_off
    AND     mrih.status                 IN (cv_status_02, cv_status_03)
    AND     mrih.schedule_arrival_date  <= ld_eff_date
    AND     mrih.mov_hdr_id              = mril.mov_hdr_id
    AND     mril.mov_line_id             = mld.mov_line_id
    AND     mril.delete_flg              = cv_flag_off
    AND     mld.item_id                  = in_item_id
    AND     mld.lot_id                   = in_lot_id
    AND     mld.document_type_code       = cv_doc_mov
    AND     mld.record_type_code         = cv_rec_instruct
    ;
--
    -- ロット S4)供給数  実績計上済の移動出庫実績
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_sup_lot_inv_out_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.ship_to_locat_id        = in_whse_id
    AND     mrih.comp_actual_flg         = cv_flag_off
    AND     mrih.status                  = cv_status_04
-- 2008/12/15 h.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_arrival_date  <= ld_eff_date
    AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= ld_eff_date
-- 2008/12/15 h.Itou Mod End
    AND     mrih.mov_hdr_id              = mril.mov_hdr_id
    AND     mril.mov_line_id             = mld.mov_line_id
    AND     mril.delete_flg              = cv_flag_off
    AND     mld.item_id                  = in_item_id
    AND     mld.lot_id                   = in_lot_id
    AND     mld.document_type_code       = cv_doc_mov
    AND     mld.record_type_code         = cv_rec_shipped
    ;
--
    -- ロット D1)需要数  実績未計上の出荷依頼
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_ship_qty
    FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
            xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
            xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
            oe_transaction_types_all  otta   -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_03
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= ld_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = iv_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_ship
    AND     mld.record_type_code      = cv_rec_instruct
    AND     otta.attribute1           = cv_type_ship
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ロット D2)需要数  実績未計上の支給指示
    SELECT  /*+ leading(oha otta ola mld) */ 
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_provide_qty
    FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
          , xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
          , xxinv_mov_lot_details      mld  -- 移動ロット詳細（アドオン）
          , oe_transaction_types_all   otta -- 受注タイプ
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_status_07
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= ld_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = iv_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_prov
    AND     mld.record_type_code      = cv_rec_instruct
    AND     otta.attribute1           = cv_type_prov
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    -- ロット D3)需要数  実績未計上の移動指示
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_inv_out_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.shipped_locat_id    = in_whse_id
    AND     mrih.comp_actual_flg     = cv_flag_off
    AND     mrih.status             IN (cv_status_02, cv_status_03)
    AND     mrih.schedule_ship_date <= ld_eff_date
    AND     mrih.mov_hdr_id          = mril.mov_hdr_id
    AND     mril.mov_line_id         = mld.mov_line_id
    AND     mril.delete_flg          = cv_flag_off
    AND     mld.item_id              = in_item_id
    AND     mld.lot_id               = in_lot_id
    AND     mld.document_type_code   = cv_doc_mov
    AND     mld.record_type_code     = cv_rec_instruct
    ;
--
    -- ロット D4)需要数  実績計上済の移動入庫実績
    SELECT  /*+ leading(mrih) use_nl(mrih mril mld) */
            NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_inv_in_qty
    FROM    xxinv_mov_req_instr_headers mrih   -- 移動依頼/指示ヘッダ（アドオン）
          , xxinv_mov_req_instr_lines   mril   -- 移動依頼/指示明細（アドオン）
          , xxinv_mov_lot_details       mld    -- 移動ロット詳細（アドオン）
    WHERE   mrih.shipped_locat_id    = in_whse_id
    AND     mrih.comp_actual_flg     = cv_flag_off
    AND     mrih.status              = cv_status_05
-- 2008/12/15 h.Itou Mod Start 本番障害#645
--    AND     mrih.schedule_ship_date <= ld_eff_date
    AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= ld_eff_date
-- 2008/12/15 h.Itou Mod End
    AND     mrih.mov_hdr_id          = mril.mov_hdr_id
    AND     mril.mov_line_id         = mld.mov_line_id
    AND     mril.delete_flg          = cv_flag_off
    AND     mld.item_id              = in_item_id
    AND     mld.lot_id               = in_lot_id
    AND     mld.document_type_code   = cv_doc_mov
    AND     mld.record_type_code     = cv_rec_ship_to
    ;
--
    -- ロット D5)需要数  実績未計上の生産投入予定
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_produce_qty
    FROM    gme_batch_header      gbh -- 生産バッチ
          , gme_material_details  gmd -- 生産原料詳細
          , xxinv_mov_lot_details mld -- 移動ロット詳細（アドオン）
          , gmd_routings_b        grb -- 工順マスタ
          , ic_tran_pnd           itp -- 保留在庫トランザクション
    WHERE   gbh.batch_status      IN (cn_status_wip, cn_status_pnd)
    AND     gbh.plan_start_date   <= ld_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_material
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- 納品場所
    AND     mld.document_type_code = cv_doc_prod
    AND     mld.record_type_code   = cv_rec_instruct
    AND     itp.doc_type           = 'PROD'
-- add start ver1.3
    AND     itp.delete_mark        = 0
-- add end ver1.3
    AND     itp.line_id            = gmd.material_detail_id 
    AND     itp.item_id            = gmd.item_id
    AND     itp.lot_id             = mld.lot_id
    AND     itp.completed_ind      = 0
    ;
--
    -- ロット D6)需要数  実績未計上の相手先倉庫発注入庫予定
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    ln_dem_lot_order_qty
    FROM    mtl_system_items_b    msib   -- 品目マスタ
          , po_lines_all          pla    -- 発注明細
          , po_headers_all        pha    -- 発注ヘッダ
          , xxinv_mov_lot_details mld    -- 移動ロット詳細（アドオン）
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off  -- 数量確定フラグ
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.attribute12        = iv_whse_code -- 相手先在庫入庫先
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_order_fin, cv_po_accept)
    AND     pha.attribute4        <= TO_CHAR(ld_eff_date, 'YYYY/MM/DD') -- 納入日
    AND     pla.po_line_id         = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     mld.document_type_code = cv_doc_po
    AND     mld.record_type_code   = cv_rec_instruct
    ;
--
    -- ロット管理品在庫数
    ln_stock_qty := ln_inv_lot_onhand 
                  + ln_inv_lot_in_inout_rpt_qty
                  + ln_inv_lot_in_in_rpt_qty
                  - ln_inv_lot_out_inout_rpt_qty
                  - ln_inv_lot_out_out_rpt_qty
                  - ln_inv_lot_ship_qty
                  - ln_inv_lot_provide_qty
                  - ln_inv_lot_in_inout_bef_qty
                  + ln_inv_lot_in_inout_cor_qty
                  + ln_inv_lot_out_inout_bef_qty
                  - ln_inv_lot_out_inout_cor_qty;
--
    -- ロット管理品供給数
    ln_supply_qty := ln_sup_lot_inv_in_qty
                   + ln_sup_lot_inv_out_qty;
--
    -- ロット管理品需要数
    ln_demand_qty := ln_dem_lot_ship_qty
                   + ln_dem_lot_provide_qty
                   + ln_dem_lot_inv_out_qty
                   + ln_dem_lot_inv_in_qty
                   + ln_dem_lot_produce_qty
                   + ln_dem_lot_order_qty;
--
    -- 有効日ベース引当可能数
    RETURN ln_stock_qty + ln_supply_qty - ln_demand_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
       (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_in_time_qty2;
--
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty2
   * Description      : 引当可能数算出API2
   ***********************************************************************************/
  FUNCTION get_can_enc_qty2(
      in_whse_id          IN  NUMBER                    -- OPM保管倉庫ID
    , iv_whse_code        IN  VARCHAR2                  -- OPM保管倉庫コード
    , in_item_id          IN  NUMBER                    -- OPM品目ID
    , iv_item_code        IN  VARCHAR2                  -- OPM品目コード
    , in_lot_id           IN  NUMBER DEFAULT NULL       -- ロットID
    , in_active_date      IN  DATE)                     -- 有効日
    RETURN NUMBER                                       -- 引当可能数
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_can_enc_qty2';           -- プログラム名
    cv_xxcmn                CONSTANT VARCHAR2(10)  := 'XXCMN';
    cv_dummy_frequent_whse  CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';  -- 
    cv_error_10002          CONSTANT VARCHAR2(30)  := 'APP-XXCMN-10002';            -- プロファイル取得エラー
    cv_tkn_ng_profile       CONSTANT VARCHAR2(30)  := 'NG_PROFILE';                 -- トークン
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_whse_id              NUMBER;           -- 保管倉庫ID
    ln_item_id              NUMBER;           -- 品目ID
    ln_lot_id               NUMBER;           -- ロットID
    lv_whse_code            VARCHAR2(40);     -- 保管倉庫コード
    lv_rep_whse             VARCHAR2(150);    -- 代表倉庫
    lv_item_code            VARCHAR2(32);     -- 品目コード
    lv_lot_no               VARCHAR2(32);     -- ロットNO
    ld_eff_date             DATE;             -- 有効日
    lv_errbuf               VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);      -- リターン・コード
    lv_errmsg               VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
    ln_all_enc_qty          NUMBER;           -- 対象の総引当可能数
    ln_in_time_enc_qty      NUMBER;           -- 対象の有効日ベース引当可能数
    ln_enc_qty              NUMBER;           -- 引当可能数
    ln_ref_all_enc_qty      NUMBER;           -- 対象親や子の総引当可能数
    ln_ref_in_time_enc_qty  NUMBER;           -- 対象親や子の有効日ベース引当可能数
--
    ln_inventory_location_id mtl_item_locations.inventory_location_id%TYPE;
    lv_inv_whse_code         mtl_item_locations.segment5%TYPE;
    lt_dummy_frequent_whse   mtl_item_locations.segment1%TYPE; --ダミー代表倉庫
--
    -- *** ローカル・カーソル ***
    CURSOR lc_child_cur  -- 子倉庫の合計を算出する為、共通関数に渡す子倉庫を抽出する
    IS
      SELECT  mil.inventory_location_id  inventory_location_id
            , mil.segment1               whse_code
      FROM    mtl_item_locations  mil    -- 保管場所
      WHERE   mil.attribute5 = lv_rep_whse -- 代表倉庫
        AND   mil.segment1  <> mil.attribute5;
--
    -- 代表倉庫(子)(倉庫・品目単位)の合計取得用カーソル
    CURSOR lc_item_child_cur
    IS
      SELECT  xfil.item_location_id
            , xfil.item_location_code whse_code
      FROM    xxwsh_frq_item_locations xfil
      WHERE   xfil.frq_item_location_code = lv_rep_whse -- 代表倉庫コード
      AND     xfil.item_id                = in_item_id; -- OPM品目ID
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
    PRAGMA EXCEPTION_INIT(profile_exp, -20002);
--
  BEGIN
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 数量の初期化
    ln_all_enc_qty     := 0;
    ln_in_time_enc_qty := 0;
--
    BEGIN
      -- 代表倉庫を取得
      SELECT  mil.segment1               -- 保管倉庫コード
            , mil.attribute5             -- 代表倉庫
      INTO    lv_whse_code
            , lv_rep_whse
      FROM    mtl_item_locations  mil    -- 保管場所
      WHERE   mil.inventory_location_id = in_whse_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- 単体の引当可能数を算出
    ln_all_enc_qty     := get_can_enc_in_time_qty2(in_whse_id
                                                 , iv_whse_code
                                                 , in_item_id
                                                 , iv_item_code
                                                 , in_lot_id
                                                 , NULL);
    ln_in_time_enc_qty := get_can_enc_in_time_qty2(in_whse_id
                                                 , iv_whse_code
                                                 , in_item_id
                                                 , iv_item_code
                                                 , in_lot_id
                                                 , in_active_date);
--
    -- 代表倉庫でない場合
    IF ( lv_rep_whse IS NULL ) THEN
      ln_ref_all_enc_qty      := 0;
      ln_ref_in_time_enc_qty  := 0;
--
    -- 代表倉庫（親）の場合
    ELSIF ( lv_rep_whse = lv_whse_code ) THEN
      -- 代表倉庫（子）の合計を取得
      -- データの取得
      <<get_child_loop>>
      FOR r_location_id IN lc_child_cur LOOP
        ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(r_location_id.inventory_location_id
                                                         , r_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id), 0);
        ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(
                                                           r_location_id.inventory_location_id
                                                         , r_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id
                                                         , in_active_date), 0);
        -- 足し込み
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END LOOP get_child_loop;
      -- 代表倉庫子(倉庫・品目単位)の合計を取得
      -- データの取得
      <<get_item_child_loop>>
      FOR r_item_location_id IN lc_item_child_cur LOOP
        ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(r_item_location_id.item_location_id
                                                         , r_item_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id), 0);
        ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(
                                                           r_item_location_id.item_location_id
                                                         , r_item_location_id.whse_code
                                                         , in_item_id
                                                         , iv_item_code
                                                         , in_lot_id
                                                         , in_active_date), 0);
        -- 足し込み
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END LOOP get_child_loop;
--
    -- 代表倉庫（子）の場合
    ELSE
      -- ダミー代表倉庫を取得
      lt_dummy_frequent_whse := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
      -- 取得に失敗した場合
      IF ( lt_dummy_frequent_whse IS NULL ) THEN
        RAISE profile_exp ;
      END IF ;
      IF ( lv_rep_whse = lt_dummy_frequent_whse ) THEN
        BEGIN
          SELECT  xfil.frq_item_location_id
                , xfil.frq_item_location_code whse_code
          INTO    ln_inventory_location_id
                , lv_inv_whse_code
          FROM    xxwsh_frq_item_locations xfil
          WHERE   xfil.item_location_code = lv_whse_code         -- 元倉庫
          AND     xfil.item_id            = in_item_id           -- OPM品目ID
          ;
--
          ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                           , lv_inv_whse_code
                                                           , in_item_id
                                                           , iv_item_code
                                                           , in_lot_id), 0);
          ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                               , lv_inv_whse_code
                                                               , in_item_id
                                                               , iv_item_code
                                                               , in_lot_id
                                                               , in_active_date), 0);
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty     := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      ELSE
        BEGIN
          SELECT  mil.inventory_location_id
                , mil.segment1 whse_code
          INTO    ln_inventory_location_id
                , lv_inv_whse_code
          FROM    mtl_item_locations  mil      -- 保管場所
          WHERE   mil.attribute5 = lv_rep_whse -- 代表倉庫
          AND     mil.segment1   = mil.attribute5
          ;
  --
          ln_ref_all_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                           , lv_inv_whse_code
                                                           , in_item_id
                                                           , iv_item_code
                                                           , in_lot_id), 0);
          ln_ref_in_time_enc_qty := NVL(get_can_enc_in_time_qty2(ln_inventory_location_id
                                                               , lv_inv_whse_code
                                                               , in_item_id
                                                               , iv_item_code
                                                               , in_lot_id
                                                               , in_active_date), 0);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      END IF;
--
      -- 親単体の引当可能数がマイナスの場合のみ足し込む
      IF ( ln_ref_all_enc_qty < 0 ) THEN
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      END IF;
      IF ( ln_ref_in_time_enc_qty < 0 ) THEN
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END IF;
    END IF;
--
    -- 少ない方が引当可能数
    IF ( ln_all_enc_qty < ln_in_time_enc_qty ) THEN
      ln_enc_qty := ln_all_enc_qty;
    ELSE
      ln_enc_qty := ln_in_time_enc_qty;
    END IF;
--
    -- 引当可能数
    RETURN ln_enc_qty;
--
  EXCEPTION
    WHEN profile_exp THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_xxcmn
                                            ,cv_error_10002
                                            ,cv_tkn_ng_profile
                                            ,cv_dummy_frequent_whse
                                           ) ;
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_can_enc_qty2;
--
-- 2009/01/19 D.Nihei ADD START
  /**********************************************************************************
   * Function Name    : get_can_enc_qty3
   * Description      : 引当可能数算出API3
   ***********************************************************************************/
  FUNCTION get_can_enc_qty3 (it_loc_id    IN mtl_item_locations.inventory_location_id%TYPE
                           , it_loc_code  IN mtl_item_locations.segment1%TYPE
                           , it_item_id   IN ic_item_mst_b.item_id%TYPE
                           , it_lot_id    IN ic_lots_mst.lot_id%TYPE
                           , it_lot_no    IN ic_lots_mst.lot_no%TYPE
                           , id_trn_date  IN DATE
                           , it_head_loc  IN mtl_item_locations.segment1%TYPE) RETURN NUMBER
  AS
--
    cv_doc_type_10 CONSTANT VARCHAR2(2) := '10';
    cv_doc_type_20 CONSTANT VARCHAR2(2) := '20';
    cv_doc_type_30 CONSTANT VARCHAR2(2) := '30';
    cv_doc_type_40 CONSTANT VARCHAR2(2) := '40';
    cv_doc_type_50 CONSTANT VARCHAR2(2) := '50';
    cv_doc_type_pr CONSTANT VARCHAR2(10) := 'PROD';
--
    cv_rec_type_10 CONSTANT VARCHAR2(2) := '10';
    cv_rec_type_20 CONSTANT VARCHAR2(2) := '20';
    cv_rec_type_30 CONSTANT VARCHAR2(2) := '30';
--
    cv_status_02   CONSTANT VARCHAR2(2) := '02';
    cv_status_03   CONSTANT VARCHAR2(2) := '03';
    cv_status_04   CONSTANT VARCHAR2(2) := '04';
    cv_status_05   CONSTANT VARCHAR2(2) := '05';
    cv_status_06   CONSTANT VARCHAR2(2) := '06';
    cv_status_07   CONSTANT VARCHAR2(2) := '07';
    cv_status_08   CONSTANT VARCHAR2(2) := '08';
    cv_status_20   CONSTANT VARCHAR2(2) := '20';
    cv_status_25   CONSTANT VARCHAR2(2) := '25';
--
    cv_flag_y      CONSTANT VARCHAR2(1) := 'Y';
    cv_flag_n      CONSTANT VARCHAR2(1) := 'N';
--
    cv_type_1      CONSTANT VARCHAR2(1) := '1';
    cv_type_2      CONSTANT VARCHAR2(1) := '2';
    cv_type_3      CONSTANT VARCHAR2(1) := '3';
--
    cn_type_m1     CONSTANT NUMBER      := -1;
    cn_type_0      CONSTANT NUMBER      := 0;
    cn_type_1      CONSTANT NUMBER      := 1;
    cn_type_2      CONSTANT NUMBER      := 2;
    -- 戻り値用変数
    ln_ret_qty           NUMBER;
    -- 計算用変数(トランザクション日)
    ln_demsup_self_trn   NUMBER;
    ln_demsup_all_trn    NUMBER;
    ln_demsup_parent_trn NUMBER;
    --計算用変数(最大日)
    ln_demsup_self_max   NUMBER;
    ln_demsup_all_max    NUMBER;
    ln_demsup_parent_max NUMBER;
    --自身以外の在庫数用変数
    ln_stock_other       NUMBER;
    --在庫総数用変数
    ln_stock_qty         NUMBER;
--
    --対象倉庫の需給数を取得するカーソル
    CURSOR get_demsup_self_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.ship_to_locat_id        = it_loc_id
        AND     mrih.comp_actual_flg         = cv_flag_n
        AND     mrih.status                  IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id              = mril.mov_hdr_id
        AND     mril.mov_line_id             = mld.mov_line_id
        AND     mril.delete_flg              = cv_flag_n
        AND     mld.item_id                  = it_item_id
        AND     mld.lot_id                   = it_lot_id
        AND     mld.document_type_code       = cv_doc_type_20
        AND     mld.record_type_code         = cv_rec_type_10
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.ship_to_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.shipped_locat_id     = it_loc_id
        AND     mrih.comp_actual_flg      = cv_flag_n
        AND     mrih.status               IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id           = mril.mov_hdr_id
        AND     mril.mov_line_id          = mld.mov_line_id
        AND     mril.delete_flg           = cv_flag_n
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_20
        AND     mld.record_type_code      = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.shipped_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_doc_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v  mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
        WHERE   gbh.batch_status       IN (cn_type_1, cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     grb.attribute9         = it_loc_code
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = gt_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.attribute12        = it_loc_code
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1         IN (cv_status_20, cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date, 'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の子倉庫の在庫数を取得するカーソル
    CURSOR get_stock_child_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand), 0)
        FROM   ic_loct_inv ili
              ,mtl_item_locations mil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = mil.segment1
        AND    mil.segment1               <> mil.attribute5
        AND    mil.attribute5              = it_head_loc
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             IN (cv_status_05, cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     mil.segment1             <> mil.attribute5
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           IN (cv_type_1, cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     mil.segment1             <> mil.attribute5
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mil.segment1           <> mil.attribute5
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) + 
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand), 0)
        FROM   ic_loct_inv ili
              ,xxwsh_frq_item_locations xfil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = xfil.item_location_code
        AND    xfil.frq_item_location_code = it_head_loc
        AND    xfil.item_id                = it_item_id
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_05,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.shipped_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status            IN (cv_status_04,cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           IN (cv_type_1, cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id              = it_item_id
        AND     oha.deliver_from_id       = xfil.item_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_y
        AND     mrih.correct_actual_flg     = cv_flag_y
        AND     mrih.status                 = cv_status_06
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親と子倉庫の需給数を取得するカーソル(親子別に取得する必要がないため)
    CURSOR get_demsup_all_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5               = it_head_loc
        AND     mrih.ship_to_locat_id        = mil.inventory_location_id
        AND     mrih.comp_actual_flg         = cv_flag_n
        AND     mrih.status                  IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id              = mril.mov_hdr_id
        AND     mril.mov_line_id             = mld.mov_line_id
        AND     mril.delete_flg              = cv_flag_n
        AND     mld.item_id                  = it_item_id
        AND     mld.lot_id                   = it_lot_id
        AND     mld.document_type_code       = cv_doc_type_20
        AND     mld.record_type_code         = cv_rec_type_10
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
-- Ver1.10 M.Hokkanji Start
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
        SELECT  /*+ LEADING(mil,mld,ola,oha,otta) */
                NVL(SUM(mld.actual_quantity), 0)
-- Ver1.10 M.Hokkanji End
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
-- Ver1.10 M.Hokkanji Start
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
        SELECT  /*+ LEADING(mil,mld,ola,oha,otta) */
                NVL(SUM(mld.actual_quantity), 0)
-- Ver1.10 M.Hokkanji End
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.attribute5            = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5            = it_head_loc
        AND     mrih.shipped_locat_id     = mil.inventory_location_id
        AND     mrih.comp_actual_flg      = cv_flag_n
        AND     mrih.status               IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id           = mril.mov_hdr_id
        AND     mril.mov_line_id          = mld.mov_line_id
        AND     mril.delete_flg           = cv_flag_n
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_20
        AND     mld.record_type_code      = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.attribute5          = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status       IN (cn_type_1, cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        AND     grb.attribute9         = mil.segment1
        AND     mil.attribute5         = it_head_loc
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
-- Ver1.10 M.Hokkanji Start
--        SELECT  NVL(SUM(mld.actual_quantity), 0)
        SELECT  /*+ LEADING(iimb,mil,msib,pla,pha) */
                NVL(SUM(mld.actual_quantity), 0)
-- Ver1.10 M.Hokkanji End
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations    mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = gt_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1         IN (cv_status_20, cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date, 'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        AND     pla.attribute12        = mil.segment1
        AND     mil.attribute5         = it_head_loc
        ) + 
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                 = it_item_id
        AND     mrih.ship_to_locat_id        = xfil.item_location_id
        AND     mrih.comp_actual_flg         = cv_flag_n
        AND     mrih.status                  IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id              = mril.mov_hdr_id
        AND     mril.mov_line_id             = mld.mov_line_id
        AND     mril.delete_flg              = cv_flag_n
        AND     mld.item_id                  = it_item_id
        AND     mld.lot_id                   = it_lot_id
        AND     mld.document_type_code       = cv_doc_type_20
        AND     mld.record_type_code         = cv_rec_type_10
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id            = it_item_id
        AND     mrih.ship_to_locat_id   = xfil.item_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.item_location_id
        AND     oha.req_status              = cv_status_03
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.schedule_ship_date     <= id_target_date
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_10
        AND     mld.record_type_code        = cv_rec_type_10
        AND     otta.attribute1             = cv_type_1
        AND     otta.transaction_type_id    = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.item_location_id
        AND     oha.req_status              = cv_status_07
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.schedule_ship_date     <= id_target_date
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_30
        AND     mld.record_type_code        = cv_rec_type_10
        AND     otta.attribute1             = cv_type_2
        AND     otta.transaction_type_id    = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_ship_date    <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status            IN (cn_type_1, cn_type_2)
        AND     gbh.plan_start_date        <= id_target_date
        AND     gbh.batch_id                = gmd.batch_id
        AND     gmd.line_type               = cn_type_m1
        AND     gmd.item_id                 = it_item_id
        AND     gmd.material_detail_id      = mld.mov_line_id
        AND     mld.lot_id                  = it_lot_id
        AND     gbh.routing_id              = grb.routing_id
        AND     mld.document_type_code      = cv_doc_type_40
        AND     mld.record_type_code        = cv_rec_type_10
        AND     itp.line_id                 = gmd.material_detail_id 
        AND     itp.item_id                 = gmd.item_id
        AND     itp.lot_id                  = mld.lot_id
        AND     itp.doc_type                = cv_doc_type_pr
        AND     itp.delete_mark             = cn_type_0
        AND     itp.completed_ind           = cn_type_0
        AND     grb.attribute9              = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id                = it_item_id
        AND     msib.segment1               = iimb.item_no
        AND     msib.organization_id        = gt_org_id
        AND     msib.inventory_item_id      = pla.item_id
        AND     pla.attribute13             = cv_flag_n
        AND     pla.cancel_flag             = cv_flag_n
        AND     pla.po_header_id            = pha.po_header_id
        AND     pha.attribute1              IN (cv_status_20, cv_status_25)
        AND     pha.attribute4             <= TO_CHAR(id_target_date, 'YYYY/MM/DD')
        AND     pla.po_line_id              = mld.mov_line_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_50
        AND     mld.record_type_code        = cv_rec_type_10
        AND     pla.attribute12             = xfil.item_location_code
        AND     xfil.frq_item_location_code = it_head_loc
        AND     xfil.item_id                = it_item_id
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の親倉庫(ダミー)の在庫数を取得するカーソル
    CURSOR get_stock_dummy_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand), 0)
        FROM   ic_loct_inv ili
              ,xxwsh_frq_item_locations xfil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = xfil.frq_item_location_code
        AND    xfil.item_location_code     = it_loc_code
        AND    xfil.item_id                = it_item_id
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.ship_to_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 IN (cv_status_05, cv_status_06)
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 IN (cv_status_04, cv_status_06)
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.frq_item_location_id
        AND     oha.req_status              = cv_status_04
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_10
        AND     mld.record_type_code        = cv_rec_type_20
        AND     otta.attribute1             IN (cv_type_1, cv_type_3)
        AND     otta.transaction_type_id    = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.frq_item_location_id
        AND     oha.req_status              = cv_status_08
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_30
        AND     mld.record_type_code        = cv_rec_type_20
        AND     otta.attribute1             = cv_type_2
        AND     otta.transaction_type_id    = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.ship_to_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_y
        AND     mrih.correct_actual_flg     = cv_flag_y
        AND     mrih.status                 = cv_status_06
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_y
        AND     mrih.correct_actual_flg     = cv_flag_y
        AND     mrih.status                 = cv_status_06
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親倉庫(ダミー)の需給数を取得するカーソル
    CURSOR get_demsup_dummy_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.ship_to_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_arrival_date <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_10
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.ship_to_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld   -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.frq_item_location_id
        AND     oha.req_status              = cv_status_03
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.schedule_ship_date     <= id_target_date
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_10
        AND     mld.record_type_code        = cv_rec_type_10
        AND     otta.attribute1             = cv_type_1
        AND     otta.transaction_type_id    = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,xxwsh_frq_item_locations   xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     oha.deliver_from_id         = xfil.frq_item_location_id
        AND     oha.req_status              = cv_status_07
        AND     oha.actual_confirm_class    = cv_flag_n
        AND     oha.latest_external_flag    = cv_flag_y
        AND     oha.schedule_ship_date     <= id_target_date
        AND     oha.order_header_id         = ola.order_header_id
        AND     ola.delete_flag             = cv_flag_n
        AND     ola.order_line_id           = mld.mov_line_id
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_30
        AND     mld.record_type_code        = cv_rec_type_10
        AND     otta.attribute1             = cv_type_2
        AND     otta.transaction_type_id    = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 IN (cv_status_02,cv_status_03)
        AND     mrih.schedule_ship_date    <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations    xfil
        WHERE   xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        AND     mrih.shipped_locat_id       = xfil.frq_item_location_id
        AND     mrih.comp_actual_flg        = cv_flag_n
        AND     mrih.status                 = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id             = mril.mov_hdr_id
        AND     mril.mov_line_id            = mld.mov_line_id
        AND     mril.delete_flg             = cv_flag_n
        AND     mld.item_id                 = it_item_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_20
        AND     mld.record_type_code        = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,xxwsh_frq_item_locations xfil
        WHERE   gbh.batch_status            IN (cn_type_1, cn_type_2)
        AND     gbh.plan_start_date        <= id_target_date
        AND     gbh.batch_id                = gmd.batch_id
        AND     gmd.line_type               = cn_type_m1
        AND     gmd.item_id                 = it_item_id
        AND     gmd.material_detail_id      = mld.mov_line_id
        AND     mld.lot_id                  = it_lot_id
        AND     gbh.routing_id              = grb.routing_id
        AND     mld.document_type_code      = cv_doc_type_40
        AND     mld.record_type_code        = cv_rec_type_10
        AND     itp.line_id                 = gmd.material_detail_id 
        AND     itp.item_id                 = gmd.item_id
        AND     itp.lot_id                  = mld.lot_id
        AND     itp.doc_type                = cv_doc_type_pr
        AND     itp.delete_mark             = cn_type_0
        AND     itp.completed_ind           = cn_type_0
        AND     grb.attribute9              = xfil.frq_item_location_code
        AND     xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,xxwsh_frq_item_locations xfil
        WHERE   iimb.item_id                = it_item_id
        AND     msib.segment1               = iimb.item_no
        AND     msib.organization_id        = gt_org_id
        AND     msib.inventory_item_id      = pla.item_id
        AND     pla.attribute13             = cv_flag_n
        AND     pla.cancel_flag             = cv_flag_n
        AND     pla.po_header_id            = pha.po_header_id
        AND     pha.attribute1              IN (cv_status_20, cv_status_25)
        AND     pha.attribute4             <= TO_CHAR(id_target_date, 'YYYY/MM/DD')
        AND     pla.po_line_id              = mld.mov_line_id
        AND     mld.lot_id                  = it_lot_id
        AND     mld.document_type_code      = cv_doc_type_50
        AND     mld.record_type_code        = cv_rec_type_10
        AND     pla.attribute12             = xfil.frq_item_location_code
        AND     xfil.item_location_code     = it_loc_code
        AND     xfil.item_id                = it_item_id
        ) demand_supply
      FROM DUAL;
--
    --対象倉庫の親倉庫の在庫数を取得するカーソル
    CURSOR get_stock_parent_cur IS
      SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand), 0)
        FROM   ic_loct_inv ili
              ,mtl_item_locations mil
        WHERE  ili.item_id                 = it_item_id
        AND    ili.lot_id                  = it_lot_id
        AND    ili.location                = mil.segment1
        AND    mil.segment1                = it_head_loc
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             IN (cv_status_05, cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             IN (cv_status_04, cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           IN (cv_type_1, cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
  -- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) stock_qty
      FROM DUAL;
--
    --対象倉庫の親倉庫の需給数を取得するカーソル
    CURSOR get_demsup_parent_cur (id_target_date IN DATE) IS
      SELECT
        ( -- S1)供給数  移動入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1                 = it_head_loc
        AND     mrih.ship_to_locat_id        = mil.inventory_location_id
        AND     mrih.comp_actual_flg         = cv_flag_n
        AND     mrih.status                  IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_arrival_date  <= id_target_date
        AND     mrih.mov_hdr_id              = mril.mov_hdr_id
        AND     mril.mov_line_id             = mld.mov_line_id
        AND     mril.delete_flg              = cv_flag_n
        AND     mld.item_id                  = it_item_id
        AND     mld.lot_id                   = it_lot_id
        AND     mld.document_type_code       = cv_doc_type_20
        AND     mld.record_type_code         = cv_rec_type_10
        ) + 
        ( -- S4)供給数  実績計上済の移動出庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.ship_to_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_04
        AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- D1)需要数  実績未計上の出荷依頼
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v    mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_03
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_1
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D2)需要数  実績未計上の支給指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta  -- 受注タイプ
               ,mtl_item_locations         mil
        WHERE   mil.segment1              = it_head_loc
        AND     oha.deliver_from_id       = mil.inventory_location_id
        AND     oha.req_status            = cv_status_07
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.schedule_ship_date   <= id_target_date
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_10
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- D3)需要数  実績未計上の移動指示
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1              = it_head_loc
        AND     mrih.shipped_locat_id     = mil.inventory_location_id
        AND     mrih.comp_actual_flg      = cv_flag_n
        AND     mrih.status               IN (cv_status_02, cv_status_03)
        AND     mrih.schedule_ship_date  <= id_target_date
        AND     mrih.mov_hdr_id           = mril.mov_hdr_id
        AND     mril.mov_line_id          = mld.mov_line_id
        AND     mril.delete_flg           = cv_flag_n
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_20
        AND     mld.record_type_code      = cv_rec_type_10
        ) - 
        ( -- D4)需要数  実績計上済の移動入庫実績
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations          mil
        WHERE   mil.segment1            = it_head_loc
        AND     mrih.shipped_locat_id   = mil.inventory_location_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             = cv_status_05
        AND     NVL(mrih.actual_ship_date, mrih.schedule_ship_date) <= id_target_date
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- D5)需要数  実績未計上の生産投入予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    gme_batch_header      gbh  -- 生産バッチ
               ,gme_material_details  gmd  -- 生産原料詳細
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,gmd_routings_b        grb  -- 工順マスタ
               ,ic_tran_pnd           itp  -- 保留在庫トランザクション
               ,mtl_item_locations    mil
        WHERE   gbh.batch_status       IN (cn_type_1, cn_type_2)
        AND     gbh.plan_start_date   <= id_target_date
        AND     gbh.batch_id           = gmd.batch_id
        AND     gmd.line_type          = cn_type_m1
        AND     gmd.item_id            = it_item_id
        AND     gmd.material_detail_id = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     gbh.routing_id         = grb.routing_id
        AND     mld.document_type_code = cv_doc_type_40
        AND     mld.record_type_code   = cv_rec_type_10
        AND     itp.line_id            = gmd.material_detail_id 
        AND     itp.item_id            = gmd.item_id
        AND     itp.lot_id             = mld.lot_id
        AND     itp.doc_type           = cv_doc_type_pr
        AND     itp.delete_mark        = cn_type_0
        AND     itp.completed_ind      = cn_type_0
        AND     grb.attribute9         = mil.segment1
        AND     mil.segment1           = it_head_loc
        ) - 
        ( -- D6)需要数  実績未計上の相手先倉庫発注入庫予定
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    ic_item_mst_b         iimb
               ,mtl_system_items_b    msib    -- 品目マスタ
               ,po_lines_all          pla     -- 発注明細
               ,po_headers_all        pha     -- 発注ヘッダ
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,mtl_item_locations    mil
        WHERE   iimb.item_id           = it_item_id
        AND     msib.segment1          = iimb.item_no
        AND     msib.organization_id   = gt_org_id
        AND     msib.inventory_item_id = pla.item_id
        AND     pla.attribute13        = cv_flag_n
        AND     pla.cancel_flag        = cv_flag_n
        AND     pla.po_header_id       = pha.po_header_id
        AND     pha.attribute1         IN (cv_status_20, cv_status_25)
        AND     pha.attribute4        <= TO_CHAR(id_target_date, 'YYYY/MM/DD')
        AND     pla.po_line_id         = mld.mov_line_id
        AND     mld.lot_id             = it_lot_id
        AND     mld.document_type_code = cv_doc_type_50
        AND     mld.record_type_code   = cv_rec_type_10
        AND     pla.attribute12        = mil.segment1
        AND     mil.segment1           = it_head_loc
        ) demand_supply
      FROM DUAL;
--
  BEGIN
--
    -- *********************
    -- 在庫総数取得
    -- *********************
    SELECT
        ( -- I0)EBS手持在庫取得
        SELECT NVL(SUM(ili.loct_onhand), 0)
        FROM   ic_loct_inv ili
              ,mtl_item_locations mil
        WHERE  ili.item_id               = it_item_id
        AND    ili.lot_id                = it_lot_id
        AND    ili.location              = mil.segment1
        AND    mil.inventory_location_id = it_loc_id
        ) + 
        ( -- I1)実績未取在庫数  移動入庫（入出庫報告有）
          -- I2)実績未取在庫数  移動入庫（入庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.ship_to_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             IN (cv_status_05, cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) - 
        ( -- I3)実績未取在庫数  移動出庫（入出庫報告有）
          -- I4)実績未取在庫数  移動出庫（出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.shipped_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_n
        AND     mrih.status             IN (cv_status_04, cv_status_06)
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) - 
        ( -- I5)実績未取在庫数  出荷
        SELECT  NVL(SUM(CASE ( otta.order_category_code ) 
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            ( NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_04
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_10
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           IN (cv_type_1, cv_type_3)
        AND     otta.transaction_type_id  = oha.order_type_id
        ) - 
        ( -- I6)実績未取在庫数  支給
        SELECT  NVL(SUM(CASE ( otta.order_category_code )
                          WHEN 'ORDER' THEN
                            NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                          WHEN 'RETURN' THEN
                            ( NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0) ) * -1
                        END), 0)
        FROM    xxwsh_order_headers_all    oha   -- 受注ヘッダ（アドオン）
               ,xxwsh_order_lines_all      ola   -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
               ,oe_transaction_types_all   otta   -- 受注タイプ
        WHERE   oha.deliver_from_id       = it_loc_id
        AND     oha.req_status            = cv_status_08
        AND     oha.actual_confirm_class  = cv_flag_n
        AND     oha.latest_external_flag  = cv_flag_y
        AND     oha.order_header_id       = ola.order_header_id
        AND     ola.delete_flag           = cv_flag_n
        AND     ola.order_line_id         = mld.mov_line_id
        AND     mld.item_id               = it_item_id
        AND     mld.lot_id                = it_lot_id
        AND     mld.document_type_code    = cv_doc_type_30
        AND     mld.record_type_code      = cv_rec_type_20
        AND     otta.attribute1           = cv_type_2
        AND     otta.transaction_type_id  = oha.order_type_id
        ) + 
        ( -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.ship_to_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_30
        ) + 
        ( -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有）
        SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
        FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
               ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--               ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
               ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細
-- Ver1.14 M.Hokkanji Mod End
        WHERE   mrih.shipped_locat_id   = it_loc_id
        AND     mrih.comp_actual_flg    = cv_flag_y
        AND     mrih.correct_actual_flg = cv_flag_y
        AND     mrih.status             = cv_status_06
        AND     mrih.mov_hdr_id         = mril.mov_hdr_id
        AND     mril.mov_line_id        = mld.mov_line_id
        AND     mril.delete_flg         = cv_flag_n
        AND     mld.item_id             = it_item_id
        AND     mld.lot_id              = it_lot_id
        AND     mld.document_type_code  = cv_doc_type_20
        AND     mld.record_type_code    = cv_rec_type_20
        ) stock_qty
    INTO   ln_stock_qty
    FROM   DUAL
    ;
--
    -- *********************
    -- 代表倉庫がない場合
    -- *********************
    IF ( it_head_loc IS NULL ) THEN
--
      -- 自分の需給数[b] (get_demsup_self_cur IN id_trn_date)
      OPEN  get_demsup_self_cur(id_trn_date);
      FETCH get_demsup_self_cur INTO ln_demsup_self_trn;
      CLOSE get_demsup_self_cur;
--
      -- 自分の需給数[b'](get_demsup_self_cur IN gd_max_date)
      OPEN  get_demsup_self_cur(gd_max_date);
      FETCH get_demsup_self_cur INTO ln_demsup_self_max;
      CLOSE get_demsup_self_cur;
--
      -- 少ない方が引当可能数( b <= b' ==> b を採用)
      IF ( ln_demsup_self_trn <= ln_demsup_self_max ) THEN
        ln_ret_qty := ln_demsup_self_trn;
      -- 少ない方が引当可能数( b > b' ==> b' を採用)
      ELSE
        ln_ret_qty := ln_demsup_self_max;
      END IF;
--
    -- *********************
    -- 代表倉庫:親の場合
    -- *********************
    ELSIF ( it_loc_code = it_head_loc ) THEN
--
      -- 代表倉庫親以外の在庫数[c]
      OPEN  get_stock_child_cur;
      FETCH get_stock_child_cur INTO ln_stock_other;
      CLOSE get_stock_child_cur;
--
      -- 代表倉庫配下の需給数[d] (get_demsup_all_cur IN id_trn_date)
      OPEN  get_demsup_all_cur(id_trn_date);
      FETCH get_demsup_all_cur INTO ln_demsup_all_trn;
      CLOSE get_demsup_all_cur;
--
      -- 代表倉庫配下の需給数[d'](get_demsup_all_cur IN gd_max_date)
      OPEN  get_demsup_all_cur(gd_max_date);
      FETCH get_demsup_all_cur INTO ln_demsup_all_max;
      CLOSE get_demsup_all_cur;
--
      -- 少ない方が引当可能数( d <= d' ==> d を採用)
      IF ( ln_demsup_all_trn <= ln_demsup_all_max ) THEN
        ln_ret_qty := ln_stock_other + ln_demsup_all_trn;
      -- 少ない方が引当可能数( d > d' ==> d' を採用)
      ELSE
        ln_ret_qty := ln_stock_other + ln_demsup_all_max;
      END IF;
--
    -- *********************
    -- 代表倉庫:子の場合
    -- *********************
    ELSE
--
      -- 自分の需給数[b] (get_demsup_self_cur IN id_trn_date)
      OPEN  get_demsup_self_cur(id_trn_date);
      FETCH get_demsup_self_cur INTO ln_demsup_self_trn;
      CLOSE get_demsup_self_cur;
--
      -- 自分の需給数[b'](get_demsup_self_cur IN gd_max_date)
      OPEN  get_demsup_self_cur(gd_max_date);
      FETCH get_demsup_self_cur INTO ln_demsup_self_max;
      CLOSE get_demsup_self_cur;
--
      -- 代表倉庫がダミーの場合、倉庫品目マスタ参照
      IF ( it_head_loc = gt_dummy_loc ) THEN
--
        -- 在庫数
        OPEN  get_stock_dummy_cur;
        FETCH get_stock_dummy_cur INTO ln_stock_other;
        CLOSE get_stock_dummy_cur;
--
        -- 需給数
        OPEN  get_demsup_dummy_cur(id_trn_date);
        FETCH get_demsup_dummy_cur INTO ln_demsup_parent_trn;
        CLOSE get_demsup_dummy_cur;
--
        -- 需給数
        OPEN  get_demsup_dummy_cur(gd_max_date);
        FETCH get_demsup_dummy_cur INTO ln_demsup_parent_max;
        CLOSE get_demsup_dummy_cur;
--
      ELSE
--
        -- 在庫数
        OPEN  get_stock_parent_cur;
        FETCH get_stock_parent_cur INTO ln_stock_other;
        CLOSE get_stock_parent_cur;
--
        -- 需給数
        OPEN  get_demsup_parent_cur(id_trn_date);
        FETCH get_demsup_parent_cur INTO ln_demsup_parent_trn;
        CLOSE get_demsup_parent_cur;
--
        -- 需給数
        OPEN  get_demsup_parent_cur(gd_max_date);
        FETCH get_demsup_parent_cur INTO ln_demsup_parent_max;
        CLOSE get_demsup_parent_cur;
--
      END IF;
--
      IF ( ( ln_demsup_parent_trn + ln_stock_other ) < 0 ) THEN
        ln_demsup_self_trn := ln_demsup_self_trn + ln_stock_other + ln_demsup_parent_trn;
      END IF;
--
      IF ( ( ln_demsup_parent_max + ln_stock_other) < 0 ) THEN
        ln_demsup_self_max := ln_demsup_self_max + ln_stock_other + ln_demsup_parent_max;
      END IF;
--
      -- 少ない方が引当可能数
      IF ( ln_demsup_self_trn <= ln_demsup_self_max ) THEN
        ln_ret_qty := ln_demsup_self_trn;
      -- 少ない方が引当可能数
      ELSE
        ln_ret_qty := ln_demsup_self_max;
      END IF;
--
    END IF;
--
    -- ****************
    -- 在庫総数をサマリ
    -- ****************
    ln_ret_qty := ln_ret_qty + ln_stock_qty;
--
    RETURN ln_ret_qty;
--
  EXCEPTION
    WHEN OTHERS THEN
      IF ( get_demsup_self_cur%ISOPEN ) THEN
        CLOSE get_demsup_self_cur;
      END IF;
      IF ( get_stock_child_cur%ISOPEN ) THEN
        CLOSE get_stock_child_cur;
      END IF;
      IF ( get_demsup_all_cur%ISOPEN ) THEN
        CLOSE get_demsup_all_cur;
      END IF;
      IF ( get_stock_dummy_cur%ISOPEN ) THEN
        CLOSE get_stock_dummy_cur;
      END IF;
      IF ( get_demsup_dummy_cur%ISOPEN ) THEN
        CLOSE get_demsup_dummy_cur;
      END IF;
      IF ( get_stock_parent_cur%ISOPEN ) THEN
        CLOSE get_stock_parent_cur;
      END IF;
      IF ( get_demsup_parent_cur%ISOPEN ) THEN
        CLOSE get_demsup_parent_cur;
      END IF;
  END get_can_enc_qty3;
--
-- 2009/01/19 D.Nihei ADD END
--
  /**********************************************************************************
  * Function Name    : check_sql_pattern
  * Description      : SQL条件パターンチェック関数
  ***********************************************************************************/
  FUNCTION check_sql_pattern(iv_kubun           IN  VARCHAR2               -- 出荷・移動区分
                           , iv_block1          IN  VARCHAR2 DEFAULT NULL  -- ブロック１
                           , iv_block2          IN  VARCHAR2 DEFAULT NULL  -- ブロック２
                           , iv_block3          IN  VARCHAR2 DEFAULT NULL  -- ブロック３
                           , in_deliver_from_id IN  NUMBER   DEFAULT NULL  -- 出庫元
                           , in_deliver_type    IN  NUMBER   DEFAULT NULL) -- 出庫形態
                             RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sql_pattern'; --プログラム名
--
    -- *** ローカル変数 ***
    ln_pattern1         NUMBER := 0;
    ln_return_pattern   NUMBER := 0;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
    --==============================================================
    -- 任意入力を判断(出荷の場合）
    --   1 = ブロック1～3 が全部NULL
    --   2 = 出荷元 がNULL
    --   3 = 受注タイプ がNULL
    -- これらの組み合わせでの条件およびリターン値は下記のようになる
    --   1<>, 2<>, 3<> → (1 or 2) and 3 ＝ 1
    --   1= , 2= , 3<> → 3              ＝ 2
    --   1= , 2<>, 3<> → 2 and 3        ＝ 3
    --   1<>, 2= , 3<> → 1 and 3        ＝ 4
    --   1<>, 2<>, 3=  → 1 or 2         ＝ 5
    --   1= , 2= , 3=  → なし           ＝ 6
    --   1= , 2<>, 3=  → 2              ＝ 7
    --   1<>, 2= , 3=  → 1              ＝ 8
    -- 任意入力を判断(移動の場合）===================================
    --   1 = ブロック1～3 が全部NULL
    --   2 = 出荷元 がNULL
    -- これらの組み合わせでの条件およびリターン値は下記のようになる
    --   1<>, 2<>      → (1 or 2)       ＝ 5
    --   1= , 2=       → なし           ＝ 6
    --   1= , 2<>      → 2              ＝ 7
    --   1<>, 2=       → 1              ＝ 8
    --==============================================================
--
    -- ブロック１～３全てがNULLか？
    IF ((iv_block1 IS NULL) AND (iv_block2 IS NULL) AND (iv_block3 IS NULL)) THEN
      ln_pattern1 := 1;
    END IF;
--
    -- 「出荷」の場合
    IF( iv_kubun = gv_cons_biz_t_deliv) THEN
      -- パターン１
      IF ((ln_pattern1 <> 1 ) AND
          (in_deliver_from_id IS NOT NULL) AND
          (in_deliver_type IS NOT NULL))
      THEN
        RETURN 1;
      END IF;
--
      -- パターン２
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 2;
      END IF;
--
      -- パターン３
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 3;
      END IF;
--
      -- パターン４
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NOT NULL ) )
      THEN
        RETURN 4;
      END IF;
--
      -- パターン５
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 5;
      END IF;
--
      -- パターン６
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 6;
      END IF;
--
      -- パターン７
      IF ( ( ln_pattern1 = 1) AND ( in_deliver_from_id IS NOT NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 7;
      END IF;
--
      -- パターン８
      IF ( (ln_pattern1 <> 1) AND ( in_deliver_from_id IS NULL ) AND ( in_deliver_type IS NULL ) )
      THEN
        RETURN 8;
      END IF;
--
    -- 「移動」の場合
    ELSE
      -- パターン５
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NOT NULL ) )
      THEN
        RETURN 5;
      END IF;
--
      -- パターン６
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NULL ) )
      THEN
        RETURN 6;
      END IF;
--
      -- パターン７
      IF ( ( ln_pattern1 = 1 ) AND ( in_deliver_from_id IS NOT NULL ) )
      THEN
        RETURN 7;
      END IF;
--
      -- パターン８
      IF ( ( ln_pattern1 <> 1 ) AND ( in_deliver_from_id IS NULL ) )
      THEN
        RETURN 8;
      END IF;
    END IF;
    RAISE process_exp;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_sql_pattern;
--
  /**********************************************************************************
  * Function Name    : fwd_sql_create
  * Description      : A-3  出荷用SQL文作成関数
  ***********************************************************************************/
  FUNCTION fwd_sql_create(iv_block1          IN  VARCHAR2 DEFAULT NULL -- ブロック１
                        , iv_block2          IN  VARCHAR2 DEFAULT NULL -- ブロック２
                        , iv_block3          IN  VARCHAR2 DEFAULT NULL -- ブロック３
                        , in_deliver_from_id IN  NUMBER   DEFAULT NULL -- 出庫元
                        , in_deliver_type    IN  NUMBER   DEFAULT NULL -- 出庫形態
                        , iv_item_code       IN  VARCHAR2              -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                        , iv_instruction_dept IN VARCHAR2)             -- 指示部署
-- 2009/01/28 H.Itou Add End
                          RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fwd_sql_create'; --プログラム名
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- 
    -- *** ローカル変数 ***
    ln_pattern     NUMBER := 0;
    lv_fwd_sql     VARCHAR2(5000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql1    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql2    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql3    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql4    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql5    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql6    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql7    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql8    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql9    VARCHAR2(2000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql10   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql11   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql12   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_fwd_sql13   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
--
  BEGIN
    -- SQL条件パターンチェック
    ln_pattern := check_sql_pattern(gv_cons_biz_t_deliv
                                  , iv_block1
                                  , iv_block2
                                  , iv_block3
                                  , in_deliver_from_id
                                  , in_deliver_type);
    -- SQL文組み立て(1～10までが固定部分)
    lv_fwd_sql1 := 'SELECT ' || ' :para_cons_biz_t_deliv, ' || -- 「出荷依頼」
                          'oh.request_no, '                 || -- 依頼No
                          'il.distribution_block, '         || -- 物流ブロック
                          'oh.deliver_from, '               || -- 出庫元
                          'oh.deliver_from_id, '            || -- 出庫元ID
                          'oh.schedule_ship_date,';            -- 出庫予定日
    lv_fwd_sql2 :=        'oh.schedule_arrival_date, '      || -- 入庫予定日
                          'oh.order_header_id, '            || -- ヘッダアドオンID
                          'oh.deliver_to, '                 || -- 配送先
                          'oh.deliver_to_id, '              || -- 配送先ID
                          'p.reserve_order, ';                 -- 拠点引当順
    lv_fwd_sql3 :=        'ol.order_line_id,         '      || -- 受注明細アドオンID
                          'ol.shipping_item_code, '         || -- 品目(コード)
                          ' im.item_id, '                   || -- OPM品目ID
                          'ol.quantity, '                   || -- 指示数量
                          'ol.quantity - NVL(ol.reserved_quantity, 0), '; -- 引当残数量
    lv_fwd_sql4 :=        'NVL(ol.reserved_quantity, 0), '          || -- 引当数量
                          'ol.designated_production_date, ' || -- 指定製造日
                          'NULL, '                          || -- 代表倉庫区分
-- 2009/01/19 D.Nihei MOD START
--                          'NULL, '                          || -- 代表倉庫
                          'il.frequent_whse, '              || -- 代表倉庫
-- 2009/01/19 D.Nihei MOD END
                          'NULL, ';                            -- 代表保管棚ID
    lv_fwd_sql5 :=        'im.num_of_cases, '               || -- ケース入数
                          'im.conv_unit '                   || -- 入出庫換算単位
                   'FROM   xxcmn_item_locations2_v       il, ' || -- OPM保管場所マスタ
                          'xxwsh_order_headers_all       oh, ' || -- 受注ヘッダアドオン
                          'xxcmn_cust_accounts2_v        p,  ';
                                                        -- パーティアドオンマスタ , パーティマスタ
    lv_fwd_sql6 :=        'xxwsh_oe_transaction_types2_v tt, ' || -- 受注タイプ
                          'xxwsh_order_lines_all         ol, ' || -- 受注明細アドオン
                          'xxcmn_item_mst2_v             im, ' || -- OPM品目マスタ
                          'xxcmn_item_categories5_v      ic ';
          -- 品目カテゴリセット , 品目カテゴリマスタ , OPM品目カテゴリ割当 , OPM品目カテゴリマスタ
    lv_fwd_sql7 := 'WHERE  il.inventory_location_id = oh.deliver_from_id ' ||
                     'AND  oh.schedule_ship_date >= TO_DATE('
                        || ' :para_yyyymmdd_from, ''YYYY/MM/DD'') ' ||
                     'AND  oh.schedule_ship_date <= TO_DATE('
                        || ' :para_yyyymmdd_to, ''YYYY/MM/DD'') ' ||
                     'AND  p.party_number = oh.head_sales_branch '   ||
                     'AND  p.start_date_active <= oh.schedule_ship_date ';
    lv_fwd_sql8 :=   'AND  p.end_date_active >= oh.schedule_ship_date '  ||
                     'AND  p.customer_class_code = :para_base ' ||
                     'AND  oh.order_type_id = tt.transaction_type_id ' ||
                     'AND  tt.shipping_shikyu_class = :para_cons_t_deliv ' ||
                     'AND  oh.req_status = :para_cons_status ' ||
                     'AND  NVL(oh.notif_status, :para_wzero ) <> :para_cons_notif_status ';
    lv_fwd_sql9 :=   'AND  oh.latest_external_flag = :para_cons_flg_yes ' ||
                     'AND  ol.order_header_id = oh.order_header_id '     ||
                     'AND  ol.shipping_item_code IN (' || gv_item_code_list || ')' ||
                     'AND NVL(ol.delete_flag, :para_flg_no ) <> :para_cons_flg_yes ' ||
                     'AND  il.date_from             <= oh.schedule_ship_date ' ||
          'AND ((il.date_to >= oh.schedule_ship_date) OR (il.date_to IS NULL)) ' ||
                     'AND  tt.start_date_active     <= oh.schedule_ship_date ' ||
          'AND ((tt.end_date_active >= oh.schedule_ship_date) OR (tt.end_date_active IS NULL)) ' ||
                     'AND  im.start_date_active     <= oh.schedule_ship_date ' ||
          'AND ((im.end_date_active >= oh.schedule_ship_date) OR (im.end_date_active IS NULL)) ' ||
                     'AND  ol.automanual_reserve_class IS NULL '               ||
                     'AND  im.item_id = ic.item_id '                           ||
                     'AND  im.item_no = ol.shipping_item_code ';
    lv_fwd_sql10 :=  'AND  im.lot_ctl = :para_cons_lot_ctl ' ||
                     'AND  ic.item_class_code = :para_cons_item_product ' ||
                     'AND  ic.prod_class_code = :para_item_class ';
    -- sql変数の合体1
    lv_fwd_sql := lv_fwd_sql1 || lv_fwd_sql2 || lv_fwd_sql3 || lv_fwd_sql4 || lv_fwd_sql5  ||
                  lv_fwd_sql6 || lv_fwd_sql7 || lv_fwd_sql8 || lv_fwd_sql9 || lv_fwd_sql10;
    -- SQL文組み立て(11～13までが変動部分)
    CASE ln_pattern
      WHEN 1 THEN
        lv_fwd_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
        lv_fwd_sql12 := '  OR (oh.deliver_from = ' || in_deliver_from_id || ')) ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql12 || lv_fwd_sql13;
      WHEN 2 THEN
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql13;
      WHEN 3 THEN
        lv_fwd_sql12 := 'AND oh.deliver_from   = ' || in_deliver_from_id || ' ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql12 || lv_fwd_sql13;
      WHEN 4 THEN
        lv_fwd_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        lv_fwd_sql13 := 'AND oh.order_type_id  = ' || in_deliver_type ;
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql13;
      WHEN 5 THEN
        lv_fwd_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
-- 2009/01/26 D.Nihei Mod Start 本番#332対応
--        lv_fwd_sql12 := '  OR (oh.deliver_from = ' || in_deliver_from_id || ')) ';
        lv_fwd_sql12 := '  OR (oh.deliver_from = ''' || in_deliver_from_id || ''')) ';
-- 2009/01/26 D.Nihei Mod End
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11 || lv_fwd_sql12;
      --WHEN 6 は条件追加なし
      WHEN 7 THEN
-- 2009/01/26 D.Nihei Mod Start 本番#332対応
--        lv_fwd_sql12 := 'AND oh.deliver_from   = ' || in_deliver_from_id ;
        lv_fwd_sql12 := 'AND oh.deliver_from   = ''' || in_deliver_from_id || '''';
-- 2009/01/26 D.Nihei Mod End
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql12;
      WHEN 8 THEN
        lv_fwd_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        -- sql変数の合体2
        lv_fwd_sql := lv_fwd_sql || lv_fwd_sql11;
      ELSE NULL;
    END CASE;
--
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    IF (iv_instruction_dept IS NOT NULL) THEN
      lv_fwd_sql := lv_fwd_sql || ' AND oh.instruction_dept = '''|| iv_instruction_dept ||'''';
    END IF;
-- 2009/01/28 H.Itou Add End
    -- ORDER句の合体3
    lv_fwd_sql := lv_fwd_sql || ' ORDER BY ol.shipping_item_code'    ||
                                '        , oh.schedule_ship_date'    ||
                                '        , oh.schedule_arrival_date' ||
                                '        , il.distribution_block'    ||
                                '        , oh.deliver_from'          ||
                                '        , NVL(ol.designated_production_date, TO_DATE(''' || gv_min_default_date || ''', ''YYYY/MM/DD'')) DESC' ||
                                '        , p.reserve_order'          ||
                                '        , oh.head_sales_branch'     ||
                                '        , oh.deliver_to'            ||
                                '        , oh.arrival_time_from'     ||
                                '        , oh.request_no ';
    -- FOR句の合体4
-- 2008/11/29 v1.2 mod start
--    lv_fwd_sql := lv_fwd_sql || ' FOR UPDATE OF ol.order_line_id NOWAIT';
    lv_fwd_sql := lv_fwd_sql || ' FOR UPDATE OF ol.order_line_id ';
-- 2008/11/29 v1.2 mod end
--
    -- 作成したSQL文を返す
    RETURN lv_fwd_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END fwd_sql_create;
--
  /**********************************************************************************
  * Function Name    : mov_sql_create
  * Description      : A-5  移動用SQL文作成関数
  ***********************************************************************************/
  FUNCTION mov_sql_create(iv_block1          IN  VARCHAR2 DEFAULT NULL -- ブロック１
                        , iv_block2          IN  VARCHAR2 DEFAULT NULL -- ブロック２
                        , iv_block3          IN  VARCHAR2 DEFAULT NULL -- ブロック３
                        , in_deliver_from_id IN  NUMBER   DEFAULT NULL -- 出庫元
                        , in_deliver_type    IN  NUMBER   DEFAULT NULL -- 出庫形態
                        , iv_item_code       IN  VARCHAR2              -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                        , iv_instruction_dept IN VARCHAR2)             -- 指示部署
-- 2009/01/28 H.Itou Add End
                          RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_sql_create'; --プログラム名
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
    -- *** ローカル変数 ***
    ln_pattern     NUMBER := 0;
    lv_mov_sql     VARCHAR2(5000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql1    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql2    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql3    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql4    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql5    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql6    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql7    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql8    VARCHAR2(2000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql9    VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql11   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql12   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
    lv_mov_sql13   VARCHAR2(1000);    -- 出荷用SQL文格納バッファ
--
  BEGIN
    -- SQL条件パターンチェック
    ln_pattern := check_sql_pattern(gv_cons_biz_t_move
                                  , iv_block1
                                  , iv_block2
                                  , iv_block3
                                  , in_deliver_from_id
                                  , in_deliver_type);
    -- SQL文組み立て(1～10までが固定部分)
    lv_mov_sql1 := 'SELECT ' || ' :para_cons_biz_t_move, '  || -- 「移動指示」
                          'ih.mov_num, '                    || -- 移動番号
                          'il.distribution_block, '         || -- 物流ブロック
                          'ih.shipped_locat_code, '         || -- 出庫元
                          'ih.shipped_locat_id, '           || -- 出庫元ID
                          'ih.schedule_ship_date,';            -- 出庫予定日
    lv_mov_sql2 :=        'ih.schedule_arrival_date, '      || -- 入庫予定日
                          'ih.mov_hdr_id, '                 || -- 移動ヘッダID
                          'ih.ship_to_locat_code, '         || -- 入庫先
                          'ih.ship_to_locat_id, '           || -- 入庫先ID
                          'NULL, ';                            -- 拠点引当順
    lv_mov_sql3 :=        'ml.mov_line_id, '                || -- 移動明細ID
                          'ml.item_code, '                  || -- 品目(コード)
                          'im.item_id, '                    || -- OPM品目ID
                          'ml.instruct_qty, '               || -- 指示数量
                          'ml.instruct_qty - NVL(ml.reserved_quantity, 0), '; -- 引当残数量
    lv_mov_sql4 :=        'NVL(ml.reserved_quantity, 0), '          || -- 引当数量
                          'ml.designated_production_date, ' || -- 指定製造日
                          'NULL, '                          || -- 代表倉庫区分
-- 2009/01/19 D.Nihei MOD START
--                          'NULL, '                          || -- 代表倉庫
                          'il.frequent_whse, '              || -- 代表倉庫
-- 2009/01/19 D.Nihei MOD END
                          'NULL, ';                            -- 代表保管棚ID
    lv_mov_sql5 :=        'im.num_of_cases, '               || -- ケース入数
                          'im.conv_unit '                   || -- 入出庫換算単位
                   'FROM   xxcmn_item_locations2_v       il, ' || -- OPM保管場所マスタ
                          'xxinv_mov_req_instr_headers   ih, ';   -- 移動依頼/指示ヘッダアドオン
    lv_mov_sql6 :=        'xxinv_mov_req_instr_lines     ml, ' || -- 移動依頼/指示明細アドオン
                          'xxcmn_item_mst2_v             im, ' || -- OPM品目マスタ
                          'xxcmn_item_categories5_v      ic ';
    lv_mov_sql7 := 'WHERE  il.inventory_location_id = ih.shipped_locat_id ' ||
                     'AND  ih.mov_type = :para_cons_move_type ' ||
                     'AND  ih.schedule_ship_date >= TO_DATE('
                        || ' :para_yyyymmdd_from, ''YYYY/MM/DD'') ' ||
                     'AND  ih.schedule_ship_date <= TO_DATE('
                        || ' :para_yyyymmdd_to, ''YYYY/MM/DD'') ' ||
                     'AND  ((ih.status = :para_cons_mov_sts_c ) ';
    lv_mov_sql8 :=   '   OR (ih.status = :para_cons_mov_sts_e )) ' ||
                     'AND  NVL(ih.notif_status, :para_wzero ) <> :para_cons_notif_status ' ||
                     'AND  ml.mov_hdr_id = ih.mov_hdr_id '         ||
                     'AND  ml.item_code IN (' || gv_item_code_list || ')' ||
                     'AND NVL(ml.delete_flg, :para_flg_no ) <> :para_cons_flg_yes ' ||
                     'AND  il.date_from             <= ih.schedule_ship_date ' ||
          'AND ((il.date_to >= ih.schedule_ship_date) OR (il.date_to IS NULL)) ' ||
                     'AND  im.start_date_active     <= ih.schedule_ship_date ' ||
          'AND ((im.end_date_active >= ih.schedule_ship_date) OR (im.end_date_active IS NULL)) ' ||
                     'AND  ml.automanual_reserve_class IS NULL ';
    lv_mov_sql9 :=   'AND  im.item_no         = ml.item_code '          ||
                     'AND  im.item_id = ic.item_id '                           ||
                     'AND  im.lot_ctl         = :para_cons_lot_ctl ' ||
                     'AND  ic.item_class_code = :para_cons_item_product ' ||
                     'AND  ic.prod_class_code = :para_item_class ';
    -- sql変数の合体1
    lv_mov_sql := lv_mov_sql1 || lv_mov_sql2 || lv_mov_sql3 || lv_mov_sql4 || lv_mov_sql5  ||
                  lv_mov_sql6 || lv_mov_sql7 || lv_mov_sql8 || lv_mov_sql9;
    -- SQL文組み立て(11～13までが変動部分)
    CASE ln_pattern
      WHEN 5 THEN
        lv_mov_sql11 := 'AND ((il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                               '''' || iv_block2 || '''' || ',' ||
                                                               '''' || iv_block3 || '''' || '))';
-- 2009/01/26 D.Nihei Mod Start 本番#332対応
--        lv_mov_sql12 := '  OR (ih.shipped_locat_id = ' || in_deliver_from_id || ')) ';
        lv_mov_sql12 := '  OR (ih.shipped_locat_code = ''' || in_deliver_from_id || ''')) ';
-- 2009/01/26 D.Nihei Mod End
        -- sql変数の合体2
        lv_mov_sql := lv_mov_sql || lv_mov_sql11 || lv_mov_sql12;
      --WHEN 6 は条件追加なし
      WHEN 7 THEN
-- 2009/01/26 D.Nihei Mod Start 本番#332対応
--         lv_mov_sql12 := 'AND ih.shipped_locat_code   = ' || in_deliver_from_id ;
         lv_mov_sql12 := 'AND ih.shipped_locat_code   = ''' || in_deliver_from_id || '''';
-- 2009/01/26 D.Nihei Mod End
        -- sql変数の合体2
        lv_mov_sql := lv_mov_sql || lv_mov_sql12;
      WHEN 8 THEN
        lv_mov_sql11 := 'AND il.distribution_block IN ( ' || '''' || iv_block1 || '''' || ',' ||
                                                             '''' || iv_block2 || '''' || ',' ||
                                                             '''' || iv_block3 || '''' || ') ';
        -- sql変数の合体2
        lv_mov_sql := lv_mov_sql || lv_mov_sql11;
      ELSE NULL;
    END CASE;
--
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    IF (iv_instruction_dept IS NOT NULL) THEN
      lv_mov_sql := lv_mov_sql || ' AND ih.instruction_post_code = '''|| iv_instruction_dept ||'''';
    END IF;
-- 2009/01/28 H.Itou Add End
    lv_mov_sql := lv_mov_sql || ' ORDER BY ml.item_code'             ||
                                '        , ih.schedule_ship_date'    ||
                                '        , ih.schedule_arrival_date' ||
                                '        , il.distribution_block'    ||
                                '        , ih.shipped_locat_code'    ||
                                '        , NVL(ml.designated_production_date, TO_DATE(''' || gv_min_default_date || ''', ''YYYY/MM/DD'')) DESC' ||
                                '        , ih.arrival_time_from'     ||
                                '        , ih.mov_num ';
    -- FOR句の合体4
-- 2008/11/29 v1.2 mod start
--    lv_mov_sql := lv_mov_sql || ' FOR UPDATE OF ml.mov_line_id NOWAIT';
    lv_mov_sql := lv_mov_sql || ' FOR UPDATE OF ml.mov_line_id ';
-- 2008/11/29 v1.2 mod end
--
    -- 作成したSQL文を返す
    RETURN lv_mov_sql;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END mov_sql_create;
--
  /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : A-1  入力パラメータチェック
   ***********************************************************************************/
  PROCEDURE check_parameter(
      iv_item_class         IN         VARCHAR2     -- 商品区分
    , iv_deliver_date_from  IN         VARCHAR2     -- 出庫日From
    , iv_deliver_date_to    IN         VARCHAR2     -- 出庫日To
    , iv_item_code          IN         VARCHAR2     -- 品目コード
    , ov_errbuf             OUT NOCOPY VARCHAR2     -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT NOCOPY VARCHAR2     -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
--
-- 2010/01/08 M.Hokkanji Ver1.12 START
   lv_open_date VARCHAR2(10);
-- 2010/01/08 M.Hokkanji Ver1.12 END
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
-- 2009/01/19 D.Nihei ADD START
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    profile_exp               EXCEPTION;     -- プロファイル取得失敗
    PRAGMA EXCEPTION_INIT(profile_exp, -20002);
-- 2009/01/19 D.Nihei ADD END
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
    -- ************************************
    -- ***  入力パラメータ必須チェック  ***
    -- ************************************
    -- 商品区分の入力がない場合はエラーとする
    IF ( iv_item_class IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- 必須入力パラメータエラー
                                                   , gv_tkn_param_name    -- トークン'PARAM_NAME'
                                                   , gv_cons_item_class) -- '商品区分'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日Fromの入力がない場合はエラーとする
    IF ( iv_deliver_date_from IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- 必須入力パラメータエラー
                                                   , gv_tkn_param_name    -- トークン'PARAM_NAME'
                                                   , gv_cons_deliv_from) -- '出庫日From'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日Toの入力がない場合はエラーとする
    IF ( iv_deliver_date_to IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- 必須入力パラメータエラー
                                                   , gv_tkn_param_name  -- トークン'PARAM_NAME'
                                                   , gv_cons_deliv_to) -- '出庫日To'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
    -- 品目コードの入力がない場合はエラーとする
    IF ( iv_item_code IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn -- 'XXCMN'
                                                   , gv_msg_92a_002    -- 必須入力パラメータエラー
                                                   , gv_tkn_param_name  -- トークン'PARAM_NAME'
                                                   , gv_cons_item_no) -- '品目コード'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  対象期間書式チェック  ***
    -- ******************************
    -- 出庫日FromをYYYY/MM/DDの型に変換(NULLが帰ってきたらエラー）
    gv_yyyymmdd_from := iv_deliver_date_from;
    gd_yyyymmdd_from := FND_DATE.STRING_TO_DATE(iv_deliver_date_from, 'YYYY/MM/DD');
    IF ( gd_yyyymmdd_from IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_003    -- 入力パラメータ書式エラー
                                                   , gv_tkn_parm_name  -- トークン'PARM_NAME'
                                                   , gv_cons_deliv_from) -- '出庫日From'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日FromをYYYY/MM/DDの型に変換(NULLが帰ってきたらエラー）
    gv_yyyymmdd_to := iv_deliver_date_to;
    gd_yyyymmdd_to := FND_DATE.STRING_TO_DATE(iv_deliver_date_to, 'YYYY/MM/DD');
    IF ( gd_yyyymmdd_to IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_003    -- 入力パラメータ書式エラー
                                                   , gv_tkn_parm_name  -- トークン'PARM_NAME'
                                                   , gv_cons_deliv_to)   -- '出庫日To'
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- ******************************
    -- ***  対象期間逆転チェック  ***
    -- ******************************
    -- 出庫日Fromと出庫日Toが逆転していたらエラー
    IF ( gd_yyyymmdd_from > gd_yyyymmdd_to ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                   , gv_msg_92a_004)    -- 入力パラメータ書式エラー
                                                   , 1
                                                   , 5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
-- 2009/01/19 D.Nihei ADD START
    -- ******************************
    -- ***  プロファイル取得      ***
    -- ******************************
    -- ダミー倉庫を取得
    gt_dummy_loc := FND_PROFILE.VALUE('XXCMN_DUMMY_FREQUENT_WHSE');
--
    -- MAX日付を取得
    gd_max_date  := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD');
    IF ( gd_max_date IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_cmn
                                            ,gv_error_10002
                                            ,gv_tkn_ng_profile
                                            ,'XXCMN_MAX_DATE'
                                           ) ;
      RAISE profile_exp;
    END IF;
--
    -- マスタ組織IDを取得
    gt_org_id    := FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID');
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_cmn
                                            ,gv_error_10002
                                            ,gv_tkn_ng_profile
                                            ,'XXCMN_MASTER_ORG_ID'
                                           ) ;
      RAISE profile_exp;
    END IF;
--
-- 2009/01/19 D.Nihei ADD END
-- 2010/01/08 M.Hokkanji Ver1.12 START
   gd_open_date := NULL;
   lv_open_date := NULL;
   lv_open_date := xxcmn_common_pkg.get_opminv_close_period;
   IF ( lv_open_date IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gv_cons_msg_kbn_wsh
                                            ,gv_error_11615
                                           ) ;
      RAISE global_api_expt;
   END IF;
   gd_open_date := ADD_MONTHS(TO_DATE(lv_open_date,'YYYYMM'), 1);
-- 2010/01/08 M.Hokkanji Ver1.12 END
--
  EXCEPTION
-- 2009/01/19 D.Nihei ADD START
    WHEN profile_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
-- 2009/01/19 D.Nihei ADD END
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
  END check_parameter;
-- 2008/11/13 M.Hokkanji START
--
  /**********************************************************************************
   * Procedure Name   : get_item_code_list
   * Description      : A-2  品目リスト取得
   ***********************************************************************************/
  PROCEDURE get_item_code_list(
    iv_item_code       IN  VARCHAR2,            -- 品目コード
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_code_list'; -- プログラム名
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
    cn_max_cnt  CONSTANT NUMBER := 100; -- MAXCOUNT
    cn_cnt_0    CONSTANT NUMBER := 0;   -- 対象品目件数0
--
    -- *** ローカル変数 ***
    ln_cnt      NUMBER := 0;            -- 件数カウント用
--
    -- *** ローカル・カーソル ***
    CURSOR cur_item_list IS
--20091016 V1.11 Mod Start --    
--      SELECT ximv.item_no
--      FROM   xxcmn_item_mst_v ximv
--      WHERE  LEVEL <= 2
--      START WITH ximv.item_no = iv_item_code
--     CONNECT BY NOCYCLE PRIOR ximv.item_id = ximv.parent_item_id;
      SELECT ximv1.item_no
      FROM   xxcmn_item_mst_v         ximv1,                          -- OPM品目情報VIEW2(子)
             xxcmn_item_mst_v         ximv2                           -- OPM品目情報VIEW2(親)
      WHERE  ximv2.item_no             =  iv_item_code                   -- 品目コード
        AND  ximv2.item_id             =  ximv1.parent_item_id;         -- 親品目ID
--20091016 V1.11 Mod Start --
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
    gv_item_code_list := NULL;
    FOR rec_item_list IN cur_item_list LOOP
      ln_cnt := ln_cnt + 1;
      IF ( gv_item_code_list IS NULL ) THEN
        gv_item_code_list := '''' || rec_item_list.item_no || '''';
      ELSE
        gv_item_code_list := gv_item_code_list || ',' || '''' || rec_item_list.item_no || '''';
      END IF;
    END LOOP;
--
    -- 対象品目が0件
    IF ( ln_cnt = cn_cnt_0 ) THEN
      -- TODO エラーメッセージ定義
      lv_errmsg := '対象件数が0件です。';
      RAISE global_api_expt;
--
    -- 対象品目が100件より大きい場合
    ELSIF ( ln_cnt > cn_max_cnt ) THEN
      -- TODO エラーメッセージ定義
      lv_errmsg := '対象件数が100件を超えています。';
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
  END get_item_code_list;
--
-- 2008/11/13 M.Hokkanji End
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_fwd
   * Description      : A-4  需要情報取得(出荷)
   ***********************************************************************************/
  PROCEDURE get_demand_inf_fwd(
    iv_fwd_sql    IN  VARCHAR2,     -- 出荷用SQL文
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_fwd'; -- プログラム名
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
    lr_demand_tbl  demand_tbl;
--
    -- *** ローカル・カーソル ***
    TYPE cursor_type IS REF CURSOR;
    fwd_cur cursor_type;
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
--
-- Ver1.01 M.Hokkanji Start
-- Ver1.6 M.Hokkanji Start
--    FND_FILE.PUT_LINE(FND_FILE.LOG,iv_fwd_sql);
-- Ver1.6 M.Hokkanji End
-- Ver1.01 M.Hokkanji End
    -- カーソルオープン
    OPEN fwd_cur FOR iv_fwd_sql USING gv_cons_biz_t_deliv
                                    , gv_yyyymmdd_from
                                    , gv_yyyymmdd_to
                                    , gv_base
                                    , gv_cons_t_deliv
                                    , gv_cons_status
                                    , gv_wzero
                                    , gv_cons_notif_status
                                    , gv_cons_flg_yes
                                    , gv_flg_no
                                    , gv_cons_flg_yes
                                    , gv_cons_lot_ctl
                                    , gv_cons_item_product
                                    , gv_item_class
                                      ;
    -- データの一括取得
    FETCH fwd_cur BULK COLLECT INTO gr_demand_tbl;
--
    -- 処理件数のセット
    gn_target_cnt_deliv := gr_demand_tbl.COUNT;
--
    -- カーソルクローズ
    CLOSE fwd_cur;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ロックビジー ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh        -- 'XXWSH'
                                                   , gv_msg_92a_005       -- テーブルロックエラー
                                                   , gv_tkn_table         -- トークン'TABLE'
                                                   , gv_cons_order_lines) -- 受注明細アドオン
                                                   , 1
                                                   , 5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      CLOSE fwd_cur;  -- カーソルクローズ
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE fwd_cur;  -- カーソルクローズ
--
--#####################################  固定部 END   ##########################################
--
  END get_demand_inf_fwd;
--
  /**********************************************************************************
   * Procedure Name   : get_demand_inf_mov
   * Description      : A-4  需要情報取得(移動)
   ***********************************************************************************/
  PROCEDURE get_demand_inf_mov(
    iv_mov_sql    IN  VARCHAR2,     -- 移動用SQL文
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_demand_inf_mov'; -- プログラム名
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
    lr_demand_tbl  demand_tbl2;
--
    -- *** ローカル・カーソル ***
    TYPE cursor_type IS REF CURSOR;
    mov_cur cursor_type;
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
--
-- Ver1.01 M.Hokkanji Start
-- Ver1.6 M.Hokkanji Start
--    FND_FILE.PUT_LINE(FND_FILE.LOG,iv_mov_sql);
-- Ver1.6 M.Hokkanji End
-- Ver1.01 M.Hokkanji End
    -- カーソルオープン
    OPEN mov_cur FOR iv_mov_sql USING gv_cons_biz_t_move
                                    , gv_cons_move_type
                                    , gv_yyyymmdd_from
                                    , gv_yyyymmdd_to
                                    , gv_cons_mov_sts_c
                                    , gv_cons_mov_sts_e
                                    , gv_wzero
                                    , gv_cons_notif_status
                                    , gv_flg_no
                                    , gv_cons_flg_yes
                                    , gv_cons_lot_ctl
                                    , gv_cons_item_product
                                    , gv_item_class
                                      ;
--
    -- 出荷の情報があった場合は一旦gr_demand_tbl2にデータを格納して
    -- 後でgr_demand_tblに合体する。
    -- データの一括取得
    FETCH mov_cur BULK COLLECT INTO gr_demand_tbl2;
    -- 処理件数のセット
    gn_target_cnt_move := gr_demand_tbl2.COUNT;
--
    -- カーソルクローズ
    CLOSE mov_cur;
--
  EXCEPTION
    WHEN lock_expt THEN                           --*** ロックビジー ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_92a_005       -- テーブルロックエラー
                                                    ,gv_tkn_table         -- トークン'TABLE'
                                                    ,gv_cons_instr_lines) -- 移動依頼/指示明細アドオン
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
      CLOSE mov_cur;  -- カーソルクローズ
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- カーソルクローズ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- カーソルクローズ
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE mov_cur;  -- カーソルクローズ
--
--#####################################  固定部 END   ##########################################
--
  END get_demand_inf_mov;
--
  /**********************************************************************************
   * Procedure Name   : get_supply_inf
   * Description      : A-5  供給情報取得
   ***********************************************************************************/
  PROCEDURE get_supply_inf(
    in_opm_whse_id   IN  NUMBER,       -- OPM保管倉庫ID
    iv_whse_code     IN  VARCHAR2,     -- OPM保管倉庫コード
    in_opm_item_id   IN  NUMBER,       -- OPM品目ID
    iv_item_code     IN  VARCHAR2,     -- OPM品目コード
    in_lot_id        IN  NUMBER,       -- ロットID
    id_active_date   IN  DATE,         -- 有効日
-- 2016/02/18 S.Yamashita Ver1.15 START
    id_schedule_arrival_date IN  DATE, -- 着荷予定日
-- 2016/02/18 S.Yamashita Ver1.15 END
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_supply_inf'; -- プログラム名
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
-- 2010/01/08 M.Hokkanji Ver1.12 START
    cv_status_02             CONSTANT VARCHAR2(2) := '02';
    cv_status_03             CONSTANT VARCHAR2(2) := '03';
    cv_status_04             CONSTANT VARCHAR2(2) := '04';
    cv_status_05             CONSTANT VARCHAR2(2) := '05';
    cv_status_06             CONSTANT VARCHAR2(2) := '06';
    cv_status_08             CONSTANT VARCHAR2(2) := '08';
    cv_document_type_code_10 CONSTANT VARCHAR2(2) := '10';
    cv_document_type_code_20 CONSTANT VARCHAR2(2) := '20';
    cv_document_type_code_30 CONSTANT VARCHAR2(2) := '30';
    cv_record_type_code_10   CONSTANT VARCHAR2(2) := '10';
    cv_record_type_code_20   CONSTANT VARCHAR2(2) := '20';
    cv_record_type_code_30   CONSTANT VARCHAR2(2) := '30';
    cn_zero                  CONSTANT NUMBER      := 0;
-- 2010/01/08 M.Hokkanji Ver1.12 END
-- 2010/01/28 M.Hokkanji Ver1.13 Start
    cv_ship_shikyu_class_1 CONSTANT VARCHAR2(1) := '1';
    cv_ship_shikyu_class_2 CONSTANT VARCHAR2(1) := '2';
    cv_ship_shikyu_class_3 CONSTANT VARCHAR2(1) := '3';
-- 2010/01/28 M.Hokkanji Ver1.13 End
    -- *** ローカル変数 ***
    ln_cnt         NUMBER := 0;
    ln_supply_cnt  NUMBER := 0;
--
    -- *** ローカル・カーソル ***
    CURSOR lc_supply_cur
    IS
      SELECT lm.lot_id               -- ロットID
           , lm.lot_no               -- ロットNo
           , lm.attribute23          -- ロットステータス
           , lm.attribute1           -- 製造年月日
           , lm.attribute2           -- 固有記号
           , lm.attribute3           -- 賞味期限
           , NULL                    -- 引当可能数(後でセットする)
      FROM   ic_lots_mst         lm  -- ロットマスタ
           , xxcmn_lot_status_v  ls  -- ロットステータスView
-- 2010/01/08 M.Hokkanji Ver1.12 START
           -- 引当済ロットか、全倉庫で手持在庫・入庫予定・入庫実績があるロットのみ抽出。(出庫のみ取得できても、画面表示しないため抽出不要)
           ,( -- 手持在庫が0より多いロット
              SELECT ili.lot_id   lot_id
                    ,ili.item_id  item_id
              FROM   ic_loct_inv  ili
              WHERE  ili.item_id = in_opm_item_id
              AND    ili.loct_onhand > cn_zero
              UNION
              -- S1)供給数  移動入庫予定
              SELECT  mld.lot_id   lot_id
                     ,mld.item_id  item_id
              FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                     ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--                   ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                     ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細ビュー
-- Ver1.14 M.Hokkanji Mod End
              WHERE   mrih.comp_actual_flg        = 'N'
              AND     mrih.status                IN (cv_status_02,cv_status_03)
              AND     mrih.schedule_arrival_date >= gd_open_date -- 予定なのでOPEN日付のデータのみ対象。
              AND     mrih.mov_hdr_id             = mril.mov_hdr_id
              AND     mril.mov_line_id            = mld.mov_line_id
              AND     mril.delete_flg             = gv_cons_flg_no
              AND     mld.item_id                 = in_opm_item_id
              AND     mld.document_type_code      = cv_document_type_code_20
              AND     mld.record_type_code        = cv_record_type_code_10
              UNION
              -- S4)供給数  実績計上済の移動出庫実績
              SELECT  mld.lot_id   lot_id
                     ,mld.item_id  item_id
              FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                     ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--                   ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                     ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細ビュー
-- Ver1.14 M.Hokkanji Mod End
              WHERE   mrih.comp_actual_flg    = gv_cons_flg_no
              AND     mrih.status             = cv_status_04
              AND     NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date) >= gd_open_date  -- 予定なのでOPEN日付のデータのみ対象。
              AND     mrih.mov_hdr_id         = mril.mov_hdr_id
              AND     mril.mov_line_id        = mld.mov_line_id
              AND     mril.delete_flg         = gv_cons_flg_no
              AND     mld.item_id             = in_opm_item_id
              AND     mld.document_type_code  = cv_document_type_code_20
              AND     mld.record_type_code    = cv_record_type_code_20
              AND     mld.actual_quantity     > cn_zero
              UNION
              -- I1)実績未取在庫数  移動入庫（入出庫報告有）
              -- I2)実績未取在庫数  移動入庫（入庫報告有）
              -- I7)実績未取在庫数  移動入庫訂正（入出庫報告有）
              -- I8)実績未取在庫数  移動出庫訂正（入出庫報告有)
              SELECT  mld.lot_id   lot_id
                     ,mld.item_id  item_id
              FROM    xxinv_mov_req_instr_headers mrih    -- 移動依頼/指示ヘッダ（アドオン）
                     ,xxinv_mov_req_instr_lines   mril    -- 移動依頼/指示明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--                   ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                     ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細ビュー
-- Ver1.14 M.Hokkanji Mod End
              WHERE (((mrih.comp_actual_flg    = gv_cons_flg_no)
                  AND (mld.record_type_code    = cv_record_type_code_30)
                  AND (mld.actual_quantity     > cn_zero)) 
                OR   ((mrih.comp_actual_flg    = gv_cons_flg_yes)
                  AND (mrih.correct_actual_flg = gv_cons_flg_yes)
                  AND (mld.record_type_code    = cv_record_type_code_30)
                  AND (mld.actual_quantity - NVL(mld.before_actual_quantity, cn_zero) > cn_zero))
                OR   ((mrih.comp_actual_flg    = gv_cons_flg_yes)
                  AND (mrih.correct_actual_flg = gv_cons_flg_yes)
                  AND (mld.record_type_code    = cv_record_type_code_20)
                  AND (NVL(mld.before_actual_quantity, cn_zero) - mld.actual_quantity > cn_zero)))
              AND     mrih.status            IN (cv_status_05,cv_status_06)
              AND     mrih.actual_arrival_date >= gd_open_date
              AND     mrih.mov_hdr_id         = mril.mov_hdr_id
              AND     mril.mov_line_id        = mld.mov_line_id
              AND     mril.delete_flg         = gv_cons_flg_no
              AND     mld.item_id             = in_opm_item_id
              AND     mld.document_type_code  = cv_document_type_code_20
              AND     mld.record_type_code   IN (cv_record_type_code_20,cv_record_type_code_30)
              UNION
              -- I5)実績未取在庫数  出荷
              -- I6)実績未取在庫数  支給
              SELECT  mld.lot_id   lot_id
                     ,mld.item_id  item_id
              FROM    xxwsh_order_headers_all    oha  -- 受注ヘッダ（アドオン）
                     ,xxwsh_order_lines_all      ola  -- 受注明細（アドオン）
-- Ver1.14 M.Hokkanji Mod Start
--                   ,xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
                     ,xxinv_mov_lot_details_v     mld     -- 移動ロット詳細ビュー
-- Ver1.14 M.Hokkanji Mod End
-- 2010/01/28 M.Hokkanji Ver1.13 Start
                     ,oe_transaction_types_all   otta   -- 受注タイプ
-- 2010/01/28 M.Hokkanji Ver1.13 End
              WHERE   oha.req_status           IN (cv_status_04,cv_status_08)
              AND     oha.actual_confirm_class  = gv_cons_flg_no
              AND     oha.latest_external_flag  = gv_cons_flg_yes
              AND     oha.shipped_date          >= gd_open_date
              AND     oha.order_header_id       = ola.order_header_id
              AND     ola.delete_flag           = gv_cons_flg_no
              AND     ola.order_line_id         = mld.mov_line_id
              AND     mld.item_id               = in_opm_item_id
              AND     mld.document_type_code   IN (cv_document_type_code_10,cv_document_type_code_30)
              AND     mld.record_type_code      = cv_record_type_code_20
-- 2010/01/28 M.Hokkanji Ver1.13 Start
              AND     otta.transaction_type_id  = oha.order_type_id  
              AND     otta.attribute1           IN (cv_ship_shikyu_class_1
                                                   ,cv_ship_shikyu_class_2
                                                   ,cv_ship_shikyu_class_3)
              --AND     NVL(mld.before_actual_quantity, cn_zero) - mld.actual_quantity > cn_zero
              AND     (
                        (otta.order_category_code = 'ORDER'
                          AND NVL(mld.before_actual_quantity, cn_zero) - mld.actual_quantity > cn_zero -- 出庫訂正はマイナス訂正のみ取得
                        ) OR
                        (otta.order_category_code = 'RETURN'
                          AND mld.actual_quantity - NVL(mld.before_actual_quantity, cn_zero) > cn_zero
                        )
                      )
-- 2010/01/28 M.Hokkanji Ver1.13 End
            ) enable_lot
-- 2010/01/08 M.Hokkanji Ver1.12 END
      WHERE  lm.item_id           = in_opm_item_id          -- 需要情報.OPM品目ID
        AND  lm.attribute23       = ls.lot_status           -- ロットステータス
        AND  ls.prod_class_code   = gv_item_class           -- 入力パラメータ.商品区分
        AND  ((ls.move_inst_a_reserve = 'Y') OR (ls.ship_req_a_reserve = 'Y')) -- 出荷(自動)か移動(自動)が'Y'
-- 2010/01/08 M.Hokkanji Ver1.12 START
        AND  lm.item_id           = enable_lot.item_id
        AND  lm.lot_id            = enable_lot.lot_id
-- 2010/01/08 M.Hokkanji Ver1.12 END
-- 2016/02/18 S.Yamashita Ver1.15 START
--      ORDER BY lm.attribute1 ASC,
        AND  TO_DATE( lm.attribute3, 'YYYY/MM/DD' ) > id_schedule_arrival_date
      ORDER BY lm.attribute3 ASC, -- 賞味期限
               lm.attribute1 ASC, -- 製造日
-- 2016/02/18 S.Yamashita Ver1.15 END
               lm.attribute2 ASC; -- 固有記号
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
    -- カーソルオープン
    OPEN lc_supply_cur;
--
    -- データの一括取得
    FETCH lc_supply_cur BULK COLLECT INTO gr_supply_tbl;
--
    -- カーソルクローズ
    CLOSE lc_supply_cur;
-- 2010/01/08 M.Hokkanji Ver1.12 START
    gn_lot_cnt := gn_lot_cnt + NVL(gr_supply_tbl.COUNT,0);
-- 2010/01/08 M.Hokkanji Ver1.12 END
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
      CLOSE lc_supply_cur;  -- カーソルクローズ
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE lc_supply_cur;  -- カーソルクローズ
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      CLOSE lc_supply_cur;  -- カーソルクローズ
--
--#####################################  固定部 END   ##########################################
--
  END get_supply_inf;
--
  /**********************************************************************************
   * Function Name   : check_lot_allot
   * Description     : A-6  ロット引当チェック
   **********************************************************************************/
  FUNCTION check_lot_allot(in_d_cnt   IN  NUMBER,    -- 需要情報処理カウンタ
                           in_s_cnt   IN  NUMBER)    -- 供給情報処理カウンタ
           RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_lot_allot'; --プログラム名
--
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_case_num  NUMBER := 0;
    lv_ship_req   xxcmn_lot_status_v.ship_req_a_reserve%TYPE;
    lv_move_inst  xxcmn_lot_status_v.move_inst_a_reserve%TYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    process_exp               EXCEPTION;     -- 各処理でエラーが発生した場合
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
--
  BEGIN
--
-- Ver1.01 M.Hokkanji Start
    -- 指示数量が0の場合
    IF (gr_demand_tbl(in_d_cnt).ordered_quantity = 0)THEN
      -- 引当はおこなわない
      RETURN 1;
    END IF;
-- Ver1.01 M.Hokkanji End
    BEGIN
      -- 出荷指示(自動)、移動指示(自動)を検索する
      SELECT ls.ship_req_a_reserve
           , ls.move_inst_a_reserve
      INTO   lv_ship_req,
             lv_move_inst
      FROM   xxcmn_lot_status_v  ls
      WHERE  ls.lot_status      = gr_supply_tbl(in_s_cnt).lot_status  -- ロットステータス
      AND    ls.prod_class_code = gv_item_class                       -- 商品区分
      ;  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- 需要情報が出荷の場合
    IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
      -- 'Y'以外の場合
      IF ( lv_ship_req <> gv_cons_flg_yes ) THEN
        -- 引当はおこなわない
        RETURN 1;
      END IF;
    -- 需要情報が移動の場合
    ELSIF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) THEN
      -- 'Y'以外の場合
      IF ( lv_move_inst <> gv_cons_flg_yes ) THEN
        -- 引当はおこなわない
        RETURN 1;
      END IF;
    END IF;
--
    -- ロットの「指定製造日」が需要の「指定製造日」より前の日付の場合
    IF ( TO_DATE(gr_supply_tbl(in_s_cnt).p_date,'YYYY/MM/DD') < 
           gr_demand_tbl(in_d_cnt).designated_production_date )
    THEN
      -- 引当はおこなわない
      RETURN 1;
    END IF;
--
    IF ( gr_supply_tbl(in_s_cnt).r_quantity IS NULL ) THEN
      -- 引当可能数を取得する
-- 2009/01/19 D.Nihei MOD START
--      gr_supply_tbl(in_s_cnt).r_quantity := get_can_enc_qty2(gr_demand_tbl(in_d_cnt).deliver_from_id      -- OPM保管倉庫ID
--                                                           , gr_demand_tbl(in_d_cnt).deliver_from         -- OPM保管倉庫コード
--                                                           , gr_demand_tbl(in_d_cnt).item_id              -- OPM品目ID
--                                                           , gr_demand_tbl(in_d_cnt).shipping_item_code   -- OPM品目コード
--                                                           , gr_supply_tbl(in_s_cnt).lot_id               -- ロットID
--                                                           , gr_demand_tbl(in_d_cnt).schedule_ship_date); -- 有効日
      gr_supply_tbl(in_s_cnt).r_quantity := get_can_enc_qty3(gr_demand_tbl(in_d_cnt).deliver_from_id      -- OPM保管倉庫ID
                                                           , gr_demand_tbl(in_d_cnt).deliver_from         -- OPM保管倉庫コード
                                                           , gr_demand_tbl(in_d_cnt).item_id              -- OPM品目ID
                                                           , gr_supply_tbl(in_s_cnt).lot_id               -- ロットID
                                                           , gr_supply_tbl(in_s_cnt).lot_no               -- ロットNo
                                                           , gr_demand_tbl(in_d_cnt).schedule_ship_date   -- 有効日
                                                           , gr_demand_tbl(in_d_cnt).frequent_whse        -- 代表倉庫
                                                            );
-- 2010/01/08 M.Hokkanji Ver1.12 START
      gn_get_can_enc_qty_cnt := gn_get_can_enc_qty_cnt + 1;
-- 2010/01/08 M.Hokkanji Ver1.12 END
-- 2009/01/19 D.Nihei MOD END
    END IF;
-- Ver1.01 M.Hokkanji Start
    -- 暫定今保持している引当数量より大きい場合に最大引当可能数を渡す
    IF (NVL(gr_check_tbl(1).max_rev_qty, 0) < NVL(gr_supply_tbl(in_s_cnt).r_quantity, 0)) THEN
      gr_check_tbl(1).max_rev_qty := gr_supply_tbl(in_s_cnt).r_quantity;
      gr_check_tbl(1).max_lot_no  :=  gr_supply_tbl(in_s_cnt).lot_no;
    END IF;
-- Ver1.01 M.Hokkanji End
    -- 引当可能数が０以下の場合
    IF ( gr_supply_tbl(in_s_cnt).r_quantity <= 0 ) THEN
      -- 引当はおこなわない
      RETURN 1;
    END IF;
--
    -- 最初にケース扱いのものはケース単位引当できるかを判断する
    -- 引当残が24で引当可能が25の場合は24のみ引き当てる
    -- 引当残が24で引当可能が5の場合はこのロットでの引当は行わないので
    -- 移動ロット詳細にもデータをセットしないでリターンする
    -- 需要情報「引当残数量」>= 供給情報「引当可能数」の場合
    IF ( gr_demand_tbl(in_d_cnt).rest_quantity >= gr_supply_tbl(in_s_cnt).r_quantity ) 
    THEN
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL )
       AND ( ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv )   -- 出荷依頼
          OR ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move  ) ) -- 移動指示
       AND ( gv_item_class = gv_cons_id_drink ) )
      THEN
        ln_case_num := 
          (FLOOR(gr_supply_tbl(in_s_cnt).r_quantity / gr_demand_tbl(in_d_cnt).num_of_cases))
            * gr_demand_tbl(in_d_cnt).num_of_cases;                            -- 実績数量
        IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL ) AND ( ln_case_num = 0 ) ) THEN
          RETURN 1;
        END IF;
      END IF;
    END IF;
--
    RETURN 0;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_lot_allot;
--
  /**********************************************************************************
   * Procedure Name   : make_allot_inf
   * Description      : A-9  引当情報作成処理
   ***********************************************************************************/
  PROCEDURE make_allot_inf(
               iv_item_class IN  VARCHAR2,         -- 入力パラメータの商品区分
               in_d_cnt      IN  NUMBER,           -- 需要情報処理カウンタ
               in_s_cnt      IN  NUMBER,           -- 供給情報処理カウンタ
               ov_exit_flg   OUT NOCOPY VARCHAR2,  -- 引当終了フラグ
               ov_errbuf     OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
               ov_retcode    OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
               ov_errmsg     OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_allot_inf'; -- プログラム名
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
    -- <カーソル名>
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
    -- 引当情報処理カウンタのカウントアップ
    gn_move_rec_cnt := gn_move_rec_cnt + 1;
--
    -- 移動ロット詳細情報セット
    SELECT xxinv_mov_lot_s1.NEXTVAL
    INTO   gr_move_tbl(gn_move_rec_cnt).mov_lot_dtl_id
    FROM   dual;                                    --ロット詳細ID
    gr_move_tbl(gn_move_rec_cnt).mov_line_id              := gr_demand_tbl(in_d_cnt).order_line_id;      -- 明細ID
    gr_move_tbl(gn_move_rec_cnt).document_type_code       := gr_demand_tbl(in_d_cnt).document_type_code; -- 文書タイプ
    gr_move_tbl(gn_move_rec_cnt).record_type_code         := gv_cons_rec_type;                           -- レコードタイプ(指示)
    gr_move_tbl(gn_move_rec_cnt).item_id                  := gr_demand_tbl(in_d_cnt).item_id;            -- OPM品目ID
    gr_move_tbl(gn_move_rec_cnt).item_code                := gr_demand_tbl(in_d_cnt).shipping_item_code; -- 品目
    gr_move_tbl(gn_move_rec_cnt).lot_id                   := gr_supply_tbl(in_s_cnt).lot_id;             -- ロットID
    gr_move_tbl(gn_move_rec_cnt).lot_no                   := gr_supply_tbl(in_s_cnt).lot_no;             -- ロットNo
    gr_move_tbl(gn_move_rec_cnt).actual_date              := NULL;                                       -- 実績日
    gr_move_tbl(gn_move_rec_cnt).automanual_reserve_class := gv_cons_am_auto;                            -- 自動手動引当区分(自動)
    -- 需要情報「引当残数量」>= 供給情報「引当可能数」の場合
    IF ( gr_demand_tbl(in_d_cnt).rest_quantity >= gr_supply_tbl(in_s_cnt).r_quantity ) 
    THEN
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NOT NULL )
       AND ( ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv )   -- 出荷依頼
-- 2009/01/26 D.Nihei Mod Start 本番#936対応
--          OR ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move  ) ) -- 移動指示
--       AND ( iv_item_class = gv_cons_id_drink) )
          OR (  ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move )   -- 移動指示
            AND ( iv_item_class = gv_cons_id_drink) ) ) )
-- 2009/01/26 D.Nihei Mod End
      THEN
        gr_move_tbl(gn_move_rec_cnt).actual_quantity :=
          (FLOOR(gr_supply_tbl(in_s_cnt).r_quantity / gr_demand_tbl(in_d_cnt).num_of_cases))
            * gr_demand_tbl(in_d_cnt).num_of_cases;                               -- 実績数量
      END IF;
      IF ( ( gr_demand_tbl(in_d_cnt).conv_unit IS NULL )
        OR (  ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) -- 移動指示
          AND (iv_item_class <> gv_cons_id_drink ) ) )
      THEN
        gr_move_tbl(gn_move_rec_cnt).actual_quantity := gr_supply_tbl(in_s_cnt).r_quantity; 
                                                                                  -- 実績数量
      END IF;
    -- 需要情報「引当残数量」< 供給情報「引当可能数」の場合
    ELSE
      gr_move_tbl(gn_move_rec_cnt).actual_quantity := gr_demand_tbl(in_d_cnt).rest_quantity;
                                                                                  -- 実績数量
    END IF;
--
    -- WHOカラム情報のセット
    gr_move_tbl(gn_move_rec_cnt).created_by             := gn_created_by;      -- 作成者
    gr_move_tbl(gn_move_rec_cnt).creation_date          := SYSDATE;            -- 作成日
    gr_move_tbl(gn_move_rec_cnt).last_updated_by        := gn_created_by;      -- 最終更新者
    gr_move_tbl(gn_move_rec_cnt).last_update_date       := SYSDATE;            -- 最終更新日
    gr_move_tbl(gn_move_rec_cnt).last_update_login      := gn_login_user;      -- 最終更新ログイン
    gr_move_tbl(gn_move_rec_cnt).request_id             := gn_conc_request_id; -- 要求ID
    gr_move_tbl(gn_move_rec_cnt).program_application_id := gn_prog_appl_id;    -- アプリケーションID
    gr_move_tbl(gn_move_rec_cnt).program_id             := gn_conc_program_id; -- プログラムID
    gr_move_tbl(gn_move_rec_cnt).program_update_date    := SYSDATE;            -- プログラム更新日
--
    -- 需要情報、供給情報の調整
    gr_demand_tbl(in_d_cnt).reserved_quantity :=
          NVL(gr_demand_tbl(in_d_cnt).reserved_quantity, 0) +
              gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    gr_supply_tbl(in_s_cnt).r_quantity        :=
          NVL(gr_supply_tbl(in_s_cnt).r_quantity, 0) -
              gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    -- 引当残数量 = 引当残数量 - 実績数量（今回引当数)
    gr_demand_tbl(in_d_cnt).rest_quantity     := NVL(gr_demand_tbl(in_d_cnt).rest_quantity, 0) -
                                                 gr_move_tbl(gn_move_rec_cnt).actual_quantity;
    -- 指示数量が引当数(合計)より大きい場合
    IF ( gr_demand_tbl(in_d_cnt).ordered_quantity > gr_demand_tbl(in_d_cnt).reserved_quantity) THEN
      ov_exit_flg := gv_cons_flg_no;
    -- 今回のロットで全部引き当てられた場合、供給情報のループを抜ける
    ELSE
--
      ov_exit_flg := gv_cons_flg_yes;
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
  END make_allot_inf;
--
  /**********************************************************************************
   * Procedure Name   : regist_allot_inf
   * Description      : A-10 引当情報登録処理
   ***********************************************************************************/
  PROCEDURE regist_allot_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_allot_inf'; -- プログラム名
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
    ln_move_cnt  NUMBER;
    ln_cnt       NUMBER;
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
--
    -- 移動ロット詳細情報をテーブルに登録する
    -- FORALLでgr_move_tbl.FIRST、gr_move_tbl.LASTが制限で使用できない
    ln_cnt := NVL(gr_move_tbl.LAST, 0);
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    <<ln_move_cnt_loop>>
    FOR ln_move_cnt IN 1..ln_cnt LOOP
      gt_i_mov_lot_dtl_id(ln_move_cnt)                      -- ロット詳細ID
        := gr_move_tbl(ln_move_cnt).mov_lot_dtl_id;
      gt_i_mov_line_id(ln_move_cnt)                         -- 明細ID
        := gr_move_tbl(ln_move_cnt).mov_line_id;
      gt_i_document_type_code(ln_move_cnt)                  -- 文書タイプ
        := gr_move_tbl(ln_move_cnt).document_type_code;
      gt_i_record_type_code(ln_move_cnt)                    -- レコードタイプ
        := gr_move_tbl(ln_move_cnt).record_type_code;
      gt_i_item_id(ln_move_cnt)                             -- OPM品目ID
        := gr_move_tbl(ln_move_cnt).item_id;
      gt_i_item_code(ln_move_cnt)                           -- 品目
        := gr_move_tbl(ln_move_cnt).item_code;
      gt_i_lot_id(ln_move_cnt)                              -- ロットID
        := gr_move_tbl(ln_move_cnt).lot_id;
      gt_i_lot_no(ln_move_cnt)                              -- ロットNo
        := gr_move_tbl(ln_move_cnt).lot_no;
      gt_i_actual_date(ln_move_cnt)                         -- 実績日
        := gr_move_tbl(ln_move_cnt).actual_date;
      gt_i_actual_quantity(ln_move_cnt)                     -- 実績数量
        := gr_move_tbl(ln_move_cnt).actual_quantity;
      gt_i_automanual_reserve_class(ln_move_cnt)            -- 自動手動引当区分
        := gr_move_tbl(ln_move_cnt).automanual_reserve_class;
      gt_i_created_by(ln_move_cnt)                          -- 作成者
        := gr_move_tbl(ln_move_cnt).created_by;
      gt_i_creation_date(ln_move_cnt)                       -- 作成日
        := gr_move_tbl(ln_move_cnt).creation_date;
      gt_i_last_updated_by(ln_move_cnt)                     -- 最終更新者
        := gr_move_tbl(ln_move_cnt).last_updated_by;
      gt_i_last_update_date(ln_move_cnt)                    -- 最終更新日
        := gr_move_tbl(ln_move_cnt).last_update_date;
      gt_i_last_update_login(ln_move_cnt)                   -- 最終更新ログイン
        := gr_move_tbl(ln_move_cnt).last_update_login;
      gt_i_request_id(ln_move_cnt)                          -- 要求ID
        := gr_move_tbl(ln_move_cnt).request_id;
      gt_i_program_application_id(ln_move_cnt)              -- アプリケーションID
        := gr_move_tbl(ln_move_cnt).program_application_id;
      gt_i_program_id(ln_move_cnt)                          -- プログラムID
        := gr_move_tbl(ln_move_cnt).program_id;
      gt_i_program_update_date(ln_move_cnt)                 -- プログラム更新日
        := gr_move_tbl(ln_move_cnt).program_update_date;
    END LOOP ln_move_cnt_loop;
--
    FORALL ln_move_cnt IN 1..ln_cnt
      INSERT INTO xxinv_mov_lot_details(
        mov_lot_dtl_id,            -- ロット詳細ID
        mov_line_id,               -- 明細ID
        document_type_code,        -- 文書タイプ
        record_type_code,          -- レコードタイプ
        item_id,                   -- OPM品目ID
        item_code,                 -- 品目
        lot_id,                    -- ロットID
        lot_no,                    -- ロットNo
        actual_date,               -- 実績日
        actual_quantity,           -- 実績数量
        automanual_reserve_class,  -- 自動手動引当区分
        created_by,                -- 作成者
        creation_date,             -- 作成日
        last_updated_by,           -- 最終更新者
        last_update_date,          -- 最終更新日
        last_update_login,         -- 最終更新ログイン
        request_id,                -- 要求ID
        program_application_id,    -- アプリケーションID
        program_id,                -- プログラムID
        program_update_date        -- プログラム更新日
      )VALUES(
        gt_i_mov_lot_dtl_id(ln_move_cnt),          -- ロット詳細ID
        gt_i_mov_line_id(ln_move_cnt),             -- 明細ID
        gt_i_document_type_code(ln_move_cnt),      -- 文書タイプ
        gt_i_record_type_code(ln_move_cnt),        -- レコードタイプ
        gt_i_item_id(ln_move_cnt),                 -- OPM品目ID
        gt_i_item_code(ln_move_cnt),               -- 品目
        gt_i_lot_id(ln_move_cnt),                  -- ロットID
        gt_i_lot_no(ln_move_cnt),                  -- ロットNo
        gt_i_actual_date(ln_move_cnt),             -- 実績日
        gt_i_actual_quantity(ln_move_cnt),         -- 実績数量
        gt_i_automanual_reserve_class(ln_move_cnt),-- 自動手動引当区分
        gt_i_created_by(ln_move_cnt),              -- 作成者
        gt_i_creation_date(ln_move_cnt),           -- 作成日
        gt_i_last_updated_by(ln_move_cnt),         -- 最終更新者
        gt_i_last_update_date(ln_move_cnt),        -- 最終更新日
        gt_i_last_update_login(ln_move_cnt),       -- 最終更新ログイン
        gt_i_request_id(ln_move_cnt),              -- 要求ID
        gt_i_program_application_id(ln_move_cnt),  -- アプリケーションID
        gt_i_program_id(ln_move_cnt),              -- プログラムID
        gt_i_program_update_date(ln_move_cnt)      -- プログラム更新日
      );
    gn_move_rec_cnt := 0;
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
  END regist_allot_inf;
--
  /**********************************************************************************
   * Procedure Name   : make_line_allot
   * Description      : A-11 明細引当数作成処理
   ***********************************************************************************/
  PROCEDURE make_line_allot(
               in_d_cnt      IN  NUMBER,           -- 需要情報処理カウンタ
               ov_errbuf     OUT NOCOPY VARCHAR2,  -- エラー・メッセージ           --# 固定 #
               ov_retcode    OUT NOCOPY VARCHAR2,  -- リターン・コード             --# 固定 #
               ov_errmsg     OUT NOCOPY VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_line_allot'; -- プログラム名
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
    lv_msgbuf    VARCHAR2(5000);  -- エラー・メッセージ
    ln_cnt       NUMBER := 0;
    lv_ship_type VARCHAR2(20);    -- 出荷先タイプ
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
--
    -- 1.「ロット逆転」エラーメッセージ、「鮮度不備」エラーメッセージ表示
    -- 引当数量が指示数量と一致しないで警告がある場合
-- Ver1.01 M.Hokkanji Start
--    IF ( ( gr_demand_tbl(in_d_cnt).reserved_quantity = 0 )
--     AND ( gr_check_tbl(1).warnning_class IS NOT NULL    ) )
     IF  ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity, 0) <> NVL(gr_demand_tbl(in_d_cnt).ordered_quantity, 0))
     AND (NVL(gr_demand_tbl(in_d_cnt).ordered_quantity, 0) > 0)
     THEN
-- Ver1.01 M.Hokkanji End
--
      -- 警告区分が「ロット逆転」の場合
      IF ( gr_check_tbl(1).warnning_class = gv_cons_wrn_reversal ) THEN
        -- 文書タイプが「出荷依頼」だった場合
        IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
          lv_ship_type := gv_ship_name_ship;
          gv_request_type := gv_request_name_ship;
        ELSE
          lv_ship_type := gv_ship_name_move;
          gv_request_type := gv_request_name_move;
        END IF;
        -- 「ロット逆転」エラーメッセージ表示
        lv_msgbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                     , gv_msg_92a_007       -- ロット逆転エラー
                                                     , gv_tkn_request_type  -- トークン'REQUEST_TYPE'
                                                     , gv_request_type
                                                     , gv_tkn_request_no    -- トークン'REQUEST_NO'
                                                     , gr_demand_tbl(in_d_cnt).request_no
                                                     , gv_tkn_ship_type     -- トークン'SHIP_TYPE'
                                                     , lv_ship_type
                                                     , gv_tkn_ship_to       -- トークン'SHIP_TO'
                                                     , gr_demand_tbl(in_d_cnt).deliver_to
                                                     , gv_tkn_item          -- トークン'ITEM'
                                                     , gr_demand_tbl(in_d_cnt).shipping_item_code
                                                     , gv_tkn_lot           -- トークン'LOT'
                                                     , gr_check_tbl(1).lot_no
                                                     , gv_tkn_p_date        -- トークン'P_DATE'
                                                     , gr_check_tbl(1).p_date
                                                     , gv_tkn_use_by_date   -- トークン'USE_BY_DATE'
                                                     , gr_check_tbl(1).use_by_date
                                                     , gv_tkn_fix_no        -- トークン'FIX_NO'
                                                     , gr_check_tbl(1).fix_no
                                                     , gv_tkn_reverse_date  -- トークン'REVDATE'
                                                     , TO_CHAR(gr_check_tbl(1).warnning_date,'YYYY/MM/DD'))
                                                     , 1
                                                     , 5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msgbuf);
      -- 警告区分が「鮮度不備」の場合
      ELSIF( gr_check_tbl(1).warnning_class = gv_cons_wrn_fresh ) THEN
        -- 「鮮度不備」エラーメッセージ表示
        lv_msgbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                                     , gv_msg_92a_008        -- 鮮度不備エラー
                                                     , gv_tkn_request_no     -- トークン'REQUEST_NO'
                                                     , gr_demand_tbl(in_d_cnt).request_no
                                                     , gv_tkn_ship_to        -- トークン'SHIP_TO'
                                                     , gr_demand_tbl(in_d_cnt).deliver_to
                                                     , gv_tkn_lot            -- トークン'LOT'
                                                     , gr_check_tbl(1).lot_no
                                                     , gv_tkn_p_date         -- トークン'P_DATE'
                                                     , gr_check_tbl(1).p_date
                                                     , gv_tkn_use_by_date    -- トークン'USE_BY_DATE'
                                                     , gr_check_tbl(1).use_by_date
                                                     , gv_tkn_fix_no         -- トークン'FIX_NO'
                                                     , gr_check_tbl(1).fix_no
                                                     , gv_tkn_arrival_date   -- トークン'ARRIVAL_DATE'
                                                     , TO_CHAR(gr_demand_tbl(in_d_cnt).schedule_arrival_date, 'YYYY/MM/DD')
                                                     , gv_tkn_standard_date  --トークン'STANDARD_DATE'
                                                     , TO_CHAR(gr_check_tbl(1).warnning_date,'YYYY/MM/DD'))
                                                     , 1
                                                     , 5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msgbuf);
-- Ver1.01 M.Hokkanji Start
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'引当数量を引当できませんでした'
                                       || ' 依頼No:' || gr_demand_tbl(in_d_cnt).request_no
                                       || ' 出荷品目:' || gr_demand_tbl(in_d_cnt).shipping_item_code
                                       || ' 引当数量：' || TO_CHAR(NVL(gr_demand_tbl(in_d_cnt).reserved_quantity, 0))
                                       || ' 1ロット最大引当可能数:' || NVL(TO_CHAR(gr_check_tbl(1).max_rev_qty), 0)
                                       || ' 1ロット最大引当ロットNo:' || gr_check_tbl(1).max_lot_no
                                       || ' 必要指示数量:' ||  gr_demand_tbl(in_d_cnt).ordered_quantity);
-- Ver1.01 M.Hokkanji End
      END IF;
-- 2008/11/13 M.Hokkanji START
      ov_retcode := gv_status_warn;
-- 2008/11/13 M.Hokkanji END
    END IF;
--
    -- 需要情報の文書タイプにより登録する変数を判断する
    -- 文書タイプが「出荷依頼」だった場合
    IF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
--
      -- 2.受注明細アドオン変数登録
      gn_odr_cnt := gn_odr_cnt + 1;
      gr_order_tbl(gn_odr_cnt).order_line_id            :=
                            gr_demand_tbl(in_d_cnt).order_line_id;       -- 受注明細アドオンID
      gr_order_tbl(gn_odr_cnt).reserved_quantity        :=
                            gr_demand_tbl(in_d_cnt).reserved_quantity;   -- 引当数
      -- 需要情報の引当数量が０より大きい
      IF  ( gr_demand_tbl(in_d_cnt).reserved_quantity > 0 ) THEN
        gr_order_tbl(gn_odr_cnt).warning_class            :=
                            NULL;                                        -- 警告区分
        gr_order_tbl(gn_odr_cnt).warning_date             :=
                            NULL;                                        -- 警告日付
        gr_order_tbl(gn_odr_cnt).automanual_reserve_class :=
                            gv_cons_am_auto;                             -- 自動手動引当区分
      -- 需要情報の引当数量が０
-- Ver1.01 M.Hokkanji Start
      ELSIF ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity, 0) = 0 ) THEN
-- Ver1.01 M.Hokkanji End
        gr_order_tbl(gn_odr_cnt).warning_class            :=
                            gr_check_tbl(1).warnning_class;              -- 警告区分
        gr_order_tbl(gn_odr_cnt).warning_date             :=
                            gr_check_tbl(1).warnning_date;               -- 警告日付
        gr_order_tbl(gn_odr_cnt).automanual_reserve_class :=
                            NULL;                                        -- 自動手動引当区分
        gr_order_tbl(gn_odr_cnt).reserved_quantity        := NULL;       -- 引当数
      END IF;
--
      -- WHOカラム情報のセット
      gr_order_tbl(gn_odr_cnt).last_updated_by     := gn_created_by;      -- 最終更新者
      gr_order_tbl(gn_odr_cnt).last_update_date    := SYSDATE;            -- 最終更新日
      gr_order_tbl(gn_odr_cnt).last_update_login   := gn_login_user;      -- 最終更新ログイン
      gr_order_tbl(gn_odr_cnt).request_id          := gn_conc_request_id; -- 要求ID
      gr_order_tbl(gn_odr_cnt).program_application_id := gn_prog_appl_id; -- アプリケーションID
      gr_order_tbl(gn_odr_cnt).program_id          := gn_conc_program_id; -- プログラムID
      gr_order_tbl(gn_odr_cnt).program_update_date := SYSDATE;            -- プログラム更新日
--
    -- 文書タイプが「移動」だった場合
    ELSIF ( gr_demand_tbl(in_d_cnt).document_type_code = gv_cons_biz_t_move ) THEN
--
      -- 3.移動依頼/指示明細アドオン変数登録
      gn_mov_cnt := gn_mov_cnt + 1;
      gr_req_tbl(gn_mov_cnt).mov_line_id       := gr_demand_tbl(in_d_cnt).order_line_id;     -- 移動明細ID
      gr_req_tbl(gn_mov_cnt).reserved_quantity := gr_demand_tbl(in_d_cnt).reserved_quantity; -- 引当数量
      -- 需要情報の引当数量が０より大きい
      IF ( gr_demand_tbl(in_d_cnt).reserved_quantity > 0 ) THEN
        gr_req_tbl(gn_mov_cnt).warning_class            := NULL;                -- 警告区分
        gr_req_tbl(gn_mov_cnt).warning_date             := NULL;                -- 警告日付
        gr_req_tbl(gn_mov_cnt).automanual_reserve_class := gv_cons_am_auto;     -- 自動手動引当区分
      -- 需要情報の引当数量が０
-- Ver1.01 M.Hokkanji Start
      ELSIF ( NVL(gr_demand_tbl(in_d_cnt).reserved_quantity, 0) = 0 ) THEN
--      ELSIF ( gr_demand_tbl(in_d_cnt).reserved_quantity = 0 ) THEN
-- Ver1.01 M.Hokkanji End
        gr_req_tbl(gn_mov_cnt).warning_class := gr_check_tbl(1).warnning_class; -- 警告区分
        gr_req_tbl(gn_mov_cnt).warning_date  := gr_check_tbl(1).warnning_date;  -- 警告日付
        gr_req_tbl(gn_mov_cnt).automanual_reserve_class := NULL;                -- 自動手動引当区分
        gr_req_tbl(gn_mov_cnt).reserved_quantity        := NULL;                -- 引当数量
      END IF;
--
      -- WHOカラム情報のセット
      gr_req_tbl(gn_mov_cnt).last_updated_by        := gn_created_by;      -- 最終更新者
      gr_req_tbl(gn_mov_cnt).last_update_date       := SYSDATE;            -- 最終更新日
      gr_req_tbl(gn_mov_cnt).last_update_login      := gn_login_user;      -- 最終更新ログイン
      gr_req_tbl(gn_mov_cnt).request_id             := gn_conc_request_id; -- 要求ID
      gr_req_tbl(gn_mov_cnt).program_application_id := gn_prog_appl_id;    -- アプリケーションID
      gr_req_tbl(gn_mov_cnt).program_id             := gn_conc_program_id; -- プログラムID
      gr_req_tbl(gn_mov_cnt).program_update_date    := SYSDATE;            -- プログラム更新日
    END IF;
--
    -- 処理結果件数カウント
    ln_cnt := check_number_tbl( gr_demand_tbl(in_d_cnt).request_no );
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
  END make_line_allot;
--
  /**********************************************************************************
   * Procedure Name   : update_line_inf
   * Description      : A-12 明細情報更新処理
   ***********************************************************************************/
  PROCEDURE update_line_inf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_line_inf'; -- プログラム名
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
    ln_ins_cnt  NUMBER;
    ln_cnt      NUMBER;
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
--
    -- 受注明細アドオンデータをテーブルに登録する
    ln_cnt := NVL(gr_order_tbl.LAST, 0);
    -- FORALLでgr_move_tbl.FIRST、gr_move_tbl.LASTが制限で使用できない
    -- FORALLで使用できるようにレコード変数を分割格納する
--
    <<ln_ins_cnt_loop1>>
    FOR ln_ins_cnt IN 1..ln_cnt LOOP
--
      gt_j_order_line_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).order_line_id;              -- 受注明細アドオンID
      gt_j_reserved_quantity(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).reserved_quantity;          -- 引当数
      gt_j_warning_class(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).warning_class;              -- 警告区分
      gt_j_warning_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).warning_date;               -- 警告日付
      gt_j_automanual_reserve_class(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).automanual_reserve_class;   -- 自動手動引当区分
      gt_j_last_updated_by(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_updated_by;            -- 最終更新者
      gt_j_last_update_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_update_date;           -- 最終更新日
      gt_j_last_update_login(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).last_update_login;          -- 最終更新ログイン
      gt_j_request_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).request_id;                 -- 要求ID
      gt_j_program_application_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_application_id;     -- アプリケーションID
      gt_j_program_id(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_id;                 -- プログラムID
      gt_j_program_update_date(ln_ins_cnt)
              := gr_order_tbl(ln_ins_cnt).program_update_date;        -- プログラム更新日
    END LOOP ln_ins_cnt_loop1;
--
    FORALL ln_ins_cnt IN 1..ln_cnt
      UPDATE xxwsh_order_lines_all
      SET reserved_quantity        = gt_j_reserved_quantity(ln_ins_cnt),        -- 引当数
          warning_class            = gt_j_warning_class(ln_ins_cnt),            -- 警告区分
          warning_date             = gt_j_warning_date(ln_ins_cnt),             -- 警告日付
          automanual_reserve_class = gt_j_automanual_reserve_class(ln_ins_cnt), -- 自動手動引当区分
          last_updated_by          = gt_j_last_updated_by(ln_ins_cnt),          -- 最終更新者
          last_update_date         = gt_j_last_update_date(ln_ins_cnt),         -- 最終更新日
          last_update_login        = gt_j_last_update_login(ln_ins_cnt),        -- 最終更新ログイン
          request_id               = gt_j_request_id(ln_ins_cnt),               -- 要求ID
          program_application_id   = gt_j_program_application_id(ln_ins_cnt),   -- アプリケーションID
          program_id               = gt_j_program_id(ln_ins_cnt),               -- プログラムID
          program_update_date      = gt_j_program_update_date(ln_ins_cnt)       -- プログラム更新日
      WHERE  order_line_id = gt_j_order_line_id(ln_ins_cnt)
      ;
--
    -- 移動依頼/指示明細アドオンデータをテーブルに登録する
    -- FORALLでgr_move_tbl.FIRST、gr_move_tbl.LASTが制限で使用できない
    ln_cnt :=  NVL(gr_req_tbl.LAST, 0);
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    <<ln_ins_cnt_loop2>>
    FOR ln_ins_cnt IN 1..ln_cnt LOOP
--
      gt_m_mov_line_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).mov_line_id;                -- 移動明細ID
      gt_m_reserved_quantity(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).reserved_quantity;          -- 引当数量
      gt_m_warning_class(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).warning_class;              -- 警告区分
      gt_m_warning_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).warning_date;               -- 警告日付
      gt_m_automanual_reserve_class(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).automanual_reserve_class;   -- 自動手動引当区分
      gt_m_last_updated_by(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_updated_by;            -- 最終更新者
      gt_m_last_update_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_update_date;           -- 最終更新日
      gt_m_last_update_login(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).last_update_login;          -- 最終更新ログイン
      gt_m_request_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).request_id;                 -- 要求ID
      gt_m_program_application_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_application_id;     -- アプリケーションID
      gt_m_program_id(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_id;                 -- プログラムID
      gt_m_program_update_date(ln_ins_cnt)
              := gr_req_tbl(ln_ins_cnt).program_update_date;        -- プログラム更新日
    END LOOP ln_ins_cnt_loop2;
--
    FORALL ln_ins_cnt IN 1..ln_cnt
      UPDATE xxinv_mov_req_instr_lines
      SET reserved_quantity        = gt_m_reserved_quantity(ln_ins_cnt),        -- 引当数量
          warning_class            = gt_m_warning_class(ln_ins_cnt),            -- 警告区分
          warning_date             = gt_m_warning_date(ln_ins_cnt),             -- 警告日付
          automanual_reserve_class = gt_m_automanual_reserve_class(ln_ins_cnt), -- 自動手動引当区分
          last_updated_by          = gt_m_last_updated_by(ln_ins_cnt),          -- 最終更新者
          last_update_date         = gt_m_last_update_date(ln_ins_cnt),         -- 最終更新日
          last_update_login        = gt_m_last_update_login(ln_ins_cnt),        -- 最終更新ログイン
          request_id               = gt_m_request_id(ln_ins_cnt),               -- 要求ID
          program_application_id   = gt_m_program_application_id(ln_ins_cnt),   -- アプリケーションID
          program_id               = gt_m_program_id(ln_ins_cnt),               -- プログラムID
          program_update_date      = gt_m_program_update_date(ln_ins_cnt)       -- プログラム更新日
      WHERE mov_line_id = gt_m_mov_line_id(ln_ins_cnt)
      ;
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
  END update_line_inf;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_item_class         IN     VARCHAR2,     -- 商品区分
    iv_action_type        IN     VARCHAR2,     -- 処理種別
    iv_block1             IN     VARCHAR2,     -- ブロック１
    iv_block2             IN     VARCHAR2,     -- ブロック２
    iv_block3             IN     VARCHAR2,     -- ブロック３
    in_deliver_from_id    IN     NUMBER,       -- 出庫元
    in_deliver_type       IN     NUMBER,       -- 出庫形態
    iv_deliver_date_from  IN     VARCHAR2,     -- 出庫日From
    iv_deliver_date_to    IN     VARCHAR2,     -- 出庫日To
    iv_item_code          IN     VARCHAR2,     -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    iv_instruction_dept   IN     VARCHAR2,     -- 指示部署
-- 2009/01/28 H.Itou Add End
    ov_errbuf             OUT  NOCOPY   VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT  NOCOPY   VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT  NOCOPY   VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lc_out_param     VARCHAR2(1000);   -- 入力パラメータの処理結果レポート出力用
    lv_fwd_sql       VARCHAR2(5000);   -- 出荷用SQL文格納バッファ
    lv_mov_sql       VARCHAR2(5000);   -- 移動用SQL文格納バッファ
--
    ln_d_cnt         NUMBER := 0;      -- 需要情報ループカウンタ
    ln_s_cnt         NUMBER := 0;      -- 供給情報ループカウンタ
    ln_k_cnt         NUMBER := 0;
    lv_exit_flg      VARCHAR2(1);      -- 引当終了フラグ
    lv_no_check_flg  VARCHAR2(1);      -- チェックなしフラグ('Y'で後続のチェックはしない)
    lv_no_meisai_flg VARCHAR2(1);      -- A-10コールフラグ
    ln_s_max         NUMBER := 0;
    ln_i_cnt         NUMBER := 0;      -- 需要情報合体用カウンタ
--
    lv_lot_biz_class VARCHAR2(1);      -- ロット逆転処理種別
    ld_reversal_date DATE;             -- 逆転日付
    ln_result        NUMBER;           -- 処理結果(0:正常、1:異常)
    ld_standard_date DATE;             -- 基準日付
    ln_cnt           NUMBER := 0;
--
    -- 供給情報取得の判断に使用する
    lv_item_code   xxwsh_order_lines_all.shipping_item_code%TYPE;      -- 品目(コード)
    ld_ship_date   xxwsh_order_headers_all.schedule_ship_date%TYPE;    -- 出庫予定日
    ld_ariv_date   xxwsh_order_headers_all.schedule_arrival_date%TYPE; -- 入庫予定日
    lv_dist_block  xxcmn_item_locations2_v.distribution_block%TYPE;    -- ブロック
    lv_delv_from   xxwsh_order_headers_all.deliver_from%TYPE;          -- 出庫元
    lv_delv_to     xxwsh_order_headers_all.deliver_to%TYPE;            -- 配送先
-- 2009/01/26 D.Nihei Mod Start 本番#936対応
    lv_fresh_retcode     VARCHAR2(1);      -- 鮮度条件チェック用リターン・コード
    ld_manufacture_date  DATE;             -- 鮮度条件合格製造日
-- 2009/01/26 D.Nihei Mod End
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gv_item_class := iv_item_class;
-- 2010/01/08 M.Hokkanji Ver1.12 START
    gn_lot_cnt             := 0;
    gn_get_can_enc_qty_cnt := 0;
-- 2010/01/08 M.Hokkanji Ver1.12 END
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- A-1  入力パラメータチェック check_parameter
    -- ===============================================
    check_parameter(iv_item_class         -- 入力パラメータ商品区分
                  , iv_deliver_date_from  -- 入力パラメータ出庫日From
                  , iv_deliver_date_to    -- 入力パラメータ出庫日To
                  , iv_item_code          -- 入力パラメータ品目コード
                  , lv_errbuf             -- エラー・メッセージ           --# 固定 #
                  , lv_retcode            -- リターン・コード             --# 固定 #
                  , lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                    );
    -- エラー処理
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
-- 2008/11/13 M.Hokkanji START
    -- ===============================================
    -- A-2  品目リスト取得 get_item_code_list
    -- ===============================================
    get_item_code_list(iv_item_code          -- 入力パラメータ品目コード
                     , lv_errbuf             -- エラー・メッセージ           --# 固定 #
                     , lv_retcode            -- リターン・コード             --# 固定 #
                     , lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                       );
    -- エラー処理
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
-- 2008/11/13 M.Hokkanji END
--
    -- 入力パラメータの「処理種別」により需要情報の取得を振り分ける(指定なしは両方)
    -- 「出荷」または「指定なし」の場合
    IF ( ( iv_action_type = gv_action_type_ship ) OR ( iv_action_type IS NULL ) ) THEN
      -- ===============================================
      -- A-3  出荷用SQL作成 fwd_sql_create
      -- ===============================================
      lv_fwd_sql := fwd_sql_create(iv_block1          -- ブロック１
                                 , iv_block2          -- ブロック２
                                 , iv_block3          -- ブロック３
                                 , in_deliver_from_id -- 出庫元
                                 , in_deliver_type    -- 出庫形態
                                 , iv_item_code       -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                                 , iv_instruction_dept  -- 指示部署
-- 2009/01/28 H.Itou Add End
                                   );   
      -- ===============================================
      -- A-4  需要情報取得(出荷) get_demand_inf_fwd
      -- ===============================================
      get_demand_inf_fwd(lv_fwd_sql     -- 出荷用SQL文
                       , lv_errbuf      -- エラー・メッセージ           --# 固定 #
                       , lv_retcode     -- リターン・コード             --# 固定 #
                       , lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
                         );
      -- エラー処理
      IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 「移動」または「指定なし」の場合
    IF ( ( iv_action_type = gv_action_type_move ) OR ( iv_action_type IS NULL ) ) THEN
      -- ===============================================
      -- A-5  移動用SQL作成 mov_sql_create
      -- ===============================================
      lv_mov_sql := mov_sql_create(iv_block1          -- ブロック１
                                 , iv_block2          -- ブロック２
                                 , iv_block3          -- ブロック３
                                 , in_deliver_from_id -- 出庫元
                                 , in_deliver_type    -- 出庫形態
                                 , iv_item_code       -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
                                 , iv_instruction_dept  -- 指示部署
-- 2009/01/28 H.Itou Add End
                                   );
      -- ===============================================
      -- A-6  需要情報取得(移動) get_demand_inf_mov
      -- ===============================================
      get_demand_inf_mov(lv_mov_sql     -- 移動用SQL文
                       , lv_errbuf      -- エラー・メッセージ           --# 固定 #
                       , lv_retcode     -- リターン・コード             --# 固定 #
                       , lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
                         );
      -- エラー処理
      IF ( lv_retcode = gv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --需要情報を合体する
    <<deliv_plus_move_loop>>
    FOR ln_i_cnt IN 1..gn_target_cnt_move LOOP
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).document_type_code :=
                    gr_demand_tbl2(ln_i_cnt).document_type_code;    -- 文書タイプ V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).request_no :=
                    gr_demand_tbl2(ln_i_cnt).mov_num;               -- 移動番号 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).distribution_block :=
                    gr_demand_tbl2(ln_i_cnt).distribution_block;    -- ブロック V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_from :=
                    gr_demand_tbl2(ln_i_cnt).deliver_from;          -- 出庫元 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_from_id :=
                    gr_demand_tbl2(ln_i_cnt).deliver_from_id;       -- 出庫元ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).schedule_ship_date :=
                    gr_demand_tbl2(ln_i_cnt).schedule_ship_date;    -- 出庫予定日 D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).schedule_arrival_date :=
                    gr_demand_tbl2(ln_i_cnt).schedule_arrival_date; -- 入庫予定日 D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).header_id :=
                    gr_demand_tbl2(ln_i_cnt).header_id;             -- ヘッダID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_to :=
                    gr_demand_tbl2(ln_i_cnt).deliver_to;            -- 配送先 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).deliver_to_id :=
                    gr_demand_tbl2(ln_i_cnt).deliver_to_id;         -- 配送先ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).reserve_order :=
                    gr_demand_tbl2(ln_i_cnt).reserve_order;         -- 拠点引当順 N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).order_line_id :=
                    gr_demand_tbl2(ln_i_cnt).order_line_id;         -- 明細ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).shipping_item_code :=
                    gr_demand_tbl2(ln_i_cnt).shipping_item_code;    -- 品目(コード) V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).item_id :=
                    gr_demand_tbl2(ln_i_cnt).item_id;               -- OPM品目ID N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).ordered_quantity :=
                    gr_demand_tbl2(ln_i_cnt).ordered_quantity;      -- 指示数量 N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).rest_quantity :=
                    gr_demand_tbl2(ln_i_cnt).rest_quantity;         -- 引当残数量 N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).reserved_quantity :=
                    gr_demand_tbl2(ln_i_cnt).reserved_quantity;     -- 引当数量 N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).designated_production_date :=
                    gr_demand_tbl2(ln_i_cnt).designated_production_date;    -- 指定製造日 D
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).frequent_whse_class :=
                    gr_demand_tbl2(ln_i_cnt).frequent_whse_class;   -- 代表倉庫区分 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).frequent_whse :=
                    gr_demand_tbl2(ln_i_cnt).frequent_whse;         -- 代表倉庫 V
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).inventory_location_id :=
                    gr_demand_tbl2(ln_i_cnt).inventory_location_id; -- 代表保管棚ID
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).num_of_cases :=
                    gr_demand_tbl2(ln_i_cnt).num_of_cases;          -- ケース入数 N
      gr_demand_tbl(gn_target_cnt_deliv+ln_i_cnt).conv_unit :=
                    gr_demand_tbl2(ln_i_cnt).conv_unit;             -- 入出庫換算単位 V
    END LOOP deliv_plus_move_loop;
--
    -- 需要情報ループ
    gn_target_cnt_total := gn_target_cnt_deliv + gn_target_cnt_move;
    <<demand_inf_loop>>
    FOR ln_d_cnt IN 1..gn_target_cnt_total LOOP
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '【依頼No】' || gr_demand_tbl(ln_d_cnt).request_no || '【経過時間】' || TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      -- ケース入数チェック以下の条件を全て満たしている場合はエラー
      -- 入出庫換算単位が設定されている
      -- 出荷依頼もしくは移動指示で商品区分がドリンク
      -- ケース入数が0もしくはNULL
      IF (  (gr_demand_tbl(ln_d_cnt).conv_unit IS NOT NULL )
        AND ( ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv ) -- 出荷依頼
             OR (  ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_move ) -- 移動指示
               AND ( gv_item_class = gv_cons_id_drink ) ) )
        AND ( NVL(gr_demand_tbl(ln_d_cnt).num_of_cases, 0) = 0 ) ) THEN
        -- ケース入数エラーを出力
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_cmn  -- 'XXCMN'
                                                     , gv_msg_92a_010       -- ケース入数エラー
                                                     , gv_tkn_request_no    -- トークン'REQUEST_NO'
                                                     , gr_demand_tbl(ln_d_cnt).request_no
                                                     , gv_tkn_item_no       -- トークン'ITEM_NO'
                                                     , gr_demand_tbl(ln_d_cnt).shipping_item_code) -- 依頼NO/移動番号
                                                     , 1
                                                     , 5000
                                                       );
        RAISE global_process_expt;
      END IF;
      -- 品目コード、出庫予定日、入庫予定日、ブロック、出庫元のどれかが異なったら
      -- 供給情報を検索する
      IF ( ( gr_demand_tbl(ln_d_cnt).shipping_item_code    <> lv_item_code  )   -- 品目コード
        OR ( gr_demand_tbl(ln_d_cnt).schedule_ship_date    <> ld_ship_date  )   -- 出庫予定日
        OR ( gr_demand_tbl(ln_d_cnt).schedule_arrival_date <> ld_ariv_date  )   -- 入庫予定日
        OR ( gr_demand_tbl(ln_d_cnt).distribution_block    <> lv_dist_block )   -- ブロック
        OR ( gr_demand_tbl(ln_d_cnt).deliver_from          <> lv_delv_from  )   -- 出庫元
        OR ( lv_item_code IS NULL ) ) 
      THEN
        -- 比較用変数に保存する
        lv_item_code  := gr_demand_tbl(ln_d_cnt).shipping_item_code;      -- 品目(コード)
        ld_ship_date  := gr_demand_tbl(ln_d_cnt).schedule_ship_date;      -- 出庫予定日
        ld_ariv_date  := gr_demand_tbl(ln_d_cnt).schedule_arrival_date;   -- 入庫予定日
        lv_dist_block := gr_demand_tbl(ln_d_cnt).distribution_block;      -- ブロック
        lv_delv_from  := gr_demand_tbl(ln_d_cnt).deliver_from;            -- 出庫元
        lv_delv_to    := gr_demand_tbl(ln_d_cnt).deliver_to;              -- 出庫元
--
        -- ===============================================
        -- A-7  供給情報取得 get_supply_inf
        -- ===============================================
        -- 供給情報変数の初期化
        gr_supply_tbl.delete;
        ln_cnt := ln_cnt + 1;
        get_supply_inf(gr_demand_tbl(ln_d_cnt).deliver_from_id    -- OPM保管倉庫ID
                     , gr_demand_tbl(ln_d_cnt).deliver_from       -- OPM保管倉庫コード
                     , gr_demand_tbl(ln_d_cnt).item_id            -- OPM品目ID
                     , gr_demand_tbl(ln_d_cnt).shipping_item_code -- OPM品目コード
                     , NULL                                       -- ロットID
                     , gr_demand_tbl(ln_d_cnt).schedule_ship_date -- 有効日
-- 2016/02/18 S.Yamashita Ver1.15 START
                     , gr_demand_tbl(ln_d_cnt).schedule_arrival_date -- 着荷予定日
-- 2016/02/18 S.Yamashita Ver1.15 END
                     , lv_errbuf                                  -- エラー・メッセージ           
                     , lv_retcode                                 -- リターン・コード             
                     , lv_errmsg                                  -- ユーザー・エラー・メッセージ 
                       );
        -- エラー処理
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- A-11処理しない為のフラグ初期化
      lv_no_meisai_flg := gv_cons_flg_no;
      ln_s_max := NVL(gr_supply_tbl.LAST, 0);
      ln_s_cnt := 0;
      -- 移動ロット詳細登録用変数及び件数を初期化
      gr_move_tbl.DELETE;
      gn_move_rec_cnt := 0;
      -- 警告チェック用の変数を初期化
      gr_check_tbl(1).warnning_class := NULL;
      gr_check_tbl(1).warnning_date  := NULL;
      gr_check_tbl(1).lot_no         := NULL;
-- Ver1.01 M.Hokkanji Start
      gr_check_tbl(1).max_rev_qty    := NULL;
      gr_check_tbl(1).max_lot_no     := NULL;
-- Ver1.01 M.Hokkanji End
      lv_no_meisai_flg               := gv_cons_flg_yes;
-- 2009/01/26 D.Nihei Add Start 本番#936対応
      ld_reversal_date               := NULL;
      lv_fresh_retcode               := NULL;      -- 鮮度条件チェック用リターン・コード
-- 2009/01/26 D.Nihei Add End
      -- 供給情報ループ
      <<supply_inf_loop>>
      FOR ln_s_cnt IN 1..ln_s_max LOOP
        -- チェックなしフラグの初期化
        lv_no_check_flg := gv_cons_flg_no;
-- 2010/01/08 M.Hokkanji Ver1.12 START
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/*
FND_FILE.PUT_LINE( FND_FILE.LOG, '【依頼/移動No】' || gr_demand_tbl(ln_d_cnt).request_no
                              || '【品目コード】' || gr_demand_tbl(ln_d_cnt).shipping_item_code
                              || '【保管倉庫】' || gr_demand_tbl(ln_d_cnt).deliver_from
                              || '【出庫日】 ' || TO_CHAR(gr_demand_tbl(ln_d_cnt).schedule_ship_date,'YYYY/MM/DD')
                              || '【ロットNo】' || gr_supply_tbl(ln_s_cnt).lot_no
                              );
*/
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- 2010/01/08 M.Hokkanji Ver1.12 END
        -- ===============================================
        -- A-8  ロット引当チェック check_lot_allot
        -- ===============================================
        ln_result := check_lot_allot(ln_d_cnt
                                   , ln_s_cnt
                                     );
--
        -- このロットでは引当をしない
        IF (ln_result = 1) THEN
          -- 後続の他のチェックをパスするためにフラグON
          lv_no_check_flg := gv_cons_flg_yes;
        END IF;
--
        IF ( lv_no_check_flg = gv_cons_flg_no ) THEN
--
          -- 需要情報が「出荷」で、入力パラメータの商品区分が「リーフ」か「ドリンク」の場合、
          -- または
          -- 需要情報が「移動」で、入力パラメータの商品区分が「ドリンク」の場合
          -- に、ロット逆転防止チェックをコールする
          IF ( ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv )
           AND ( ( iv_item_class = gv_cons_id_leaf ) OR ( iv_item_class = gv_cons_id_drink ) )
           OR  ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_move )
           AND ( iv_item_class = gv_cons_id_drink ) )
          THEN
--
            -- パラメータ(ロット逆転処理種別)生成
            -- 需要の文書タイプが「出荷依頼」
            IF ( gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv ) THEN
              lv_lot_biz_class := gv_cons_t_deliv;
              gv_request_type  := gv_request_name_ship;
            -- それ以外は「移動指示」
            ELSE
              lv_lot_biz_class := gv_cons_t_move;
              gv_request_type  := gv_request_name_move;
            END IF;
-- 2009/01/26 D.Nihei Add Start 本番#936対応
            IF ( ld_reversal_date IS NULL ) THEN
-- 2009/01/26 D.Nihei Add End
              -- =========================================
              -- ロット逆転防止チェック 共通関数
              -- =========================================
              xxwsh_common910_pkg.check_lot_reversal(
                             lv_lot_biz_class                              -- 1.ロット逆転処理種別
                           , gr_demand_tbl(ln_d_cnt).shipping_item_code    -- 2.品目コード
                           , gr_supply_tbl(ln_s_cnt).lot_no                -- 3.ロットNo
                           , gr_demand_tbl(ln_d_cnt).deliver_to_id         -- 4.配送先ID/取引先サイトID/入庫先ID
                           , gr_demand_tbl(ln_d_cnt).schedule_arrival_date -- 5.着日
                           , gr_demand_tbl(ln_d_cnt).schedule_ship_date    -- 6.基準日(適用日基準日)
                           , lv_retcode                                    -- 7.リターン・コード
                           , lv_errbuf                                     -- 8.エラー・メッセージ
                           , lv_errmsg                                     -- 9.ユーザー・エラー・メッセージ 
                           , ln_result                                     -- 10.処理結果
                           , ld_reversal_date                              -- 11.逆転日付
                             );
              -- 共通関数のエラー
              IF (lv_retcode = gv_cons_error) THEN
                -- メッセージのセット
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                       , gv_msg_92a_006    -- 共通関数エラー
                                       , gv_tkn_request_type -- トークン'REQUEST_TYPE'
                                       , gv_request_type
                                       , gv_tkn_request_no   -- トークン'REQUEST_NO'
                                       , gr_demand_tbl(ln_d_cnt).request_no
                                       , gv_tkn_p_date       -- トークン'P_DATE'
                                       , gr_supply_tbl(ln_s_cnt).p_date
                                       , gv_tkn_use_by_date  -- トークン'USE_BY_DATE'
                                       , gr_supply_tbl(ln_s_cnt).use_by_date
                                       , gv_tkn_fix_no       -- トークン'FIX_NO'
                                       , gr_supply_tbl(ln_s_cnt).fix_no
                                       , gv_tkn_err_code   -- トークン'ERR_CODE'
                                       , lv_errbuf         -- エラーメッセージ
                                       , gv_tkn_err_msg    -- トークン'ERR_MSG'
                                       , lv_errmsg)        -- ユーザー・エラー・メッセージ
                                       , 1
                                       , 5000
                                         );
                -- 後続処理は中止する
                gn_error_cnt := 1;
                RAISE global_process_expt;
              END IF;
-- 2009/01/26 D.Nihei Add Start 本番#936対応
            END IF;
-- 2009/01/26 D.Nihei Add End
--
-- 2009/01/26 D.Nihei Add Start 本番#936対応
--            -- ロットの逆転があった場合
--            IF (ln_result = 1) THEN
--              -- チェック処理結果を格納する
--              IF ( (gr_check_tbl(1).warnning_date IS NULL)
--                OR (gr_check_tbl(1).warnning_date <= ld_reversal_date ))
--              THEN
-- 2016/02/18 S.Yamashita Ver1.15 START
--            -- ロット製造日 < 逆転日付の場合
--            IF ( FND_DATE.STRING_TO_DATE(gr_supply_tbl(ln_s_cnt).p_date, 'YYYY/MM/DD') < ld_reversal_date ) THEN
            -- ロット賞味期限 < 逆転日付の場合
            IF ( FND_DATE.STRING_TO_DATE(gr_supply_tbl(ln_s_cnt).use_by_date, 'YYYY/MM/DD') < ld_reversal_date ) THEN
-- 2016/02/18 S.Yamashita Ver1.15 END
              -- チェック処理結果を格納する
              IF ( ( gr_check_tbl(1).warnning_date IS NULL )
                OR ( gr_check_tbl(1).warnning_date <= ld_reversal_date ) ) THEN
-- 2009/01/26 D.Nihei Add End
                ln_k_cnt := ln_k_cnt + 1;
                gr_check_tbl(1).warnning_class := gv_cons_wrn_reversal;           -- 警告区分
                gr_check_tbl(1).warnning_date  := ld_reversal_date;               -- 警告日付
                gr_check_tbl(1).lot_no         := gr_supply_tbl(ln_s_cnt).lot_no; -- ロットNo
                gr_check_tbl(1).p_date         := gr_supply_tbl(ln_s_cnt).p_date;      -- 製造年月日
                gr_check_tbl(1).fix_no         := gr_supply_tbl(ln_s_cnt).fix_no;      -- 固有番号
                gr_check_tbl(1).use_by_date    := gr_supply_tbl(ln_s_cnt).use_by_date; -- 賞味期限
              END IF;
--
              -- 後続の他のチェックをパスするためにフラグON
              lv_no_check_flg := gv_cons_flg_yes;
              -- 警告終了
            END IF;
            -- ループの間一度でもここを通ればA-11はコールする
            lv_no_meisai_flg := gv_cons_flg_yes;
--
          END IF;
--
          -- 処理対象の需要が「出荷」の場合
          IF (gr_demand_tbl(ln_d_cnt).document_type_code = gv_cons_biz_t_deliv)
          THEN
-- 2009/01/26 D.Nihei Mod Start 本番#936対応
--            -- =======================================
--            -- 鮮度条件チェック 共通関数
--            -- =======================================
--            xxwsh_common910_pkg.check_fresh_condition(
--                gr_demand_tbl(ln_d_cnt).deliver_to_id          -- 1.配送先ID
--              , gr_supply_tbl(ln_s_cnt).lot_id                 -- 2.ロットID
--              , gr_demand_tbl(ln_d_cnt).schedule_arrival_date  -- 3.着荷日
--              , gr_demand_tbl(ln_d_cnt).schedule_ship_date     -- 4.出庫予定日
--              , lv_retcode                                     -- 5.リターン・コード
--              , lv_errbuf                                      -- 6.エラー・メッセージ
--              , lv_errmsg                                      -- 7.ユーザー・エラー・メッセージ
--              , ln_result                                      -- 8.処理結果
--              , ld_standard_date                               -- 9.基準日付
--                );
--            -- 共通関数のエラー
--            IF (lv_retcode = gv_cons_error) THEN
            IF ( lv_fresh_retcode IS NULL ) THEN
              -- =======================================
              -- 鮮度条件合格製造日取得 共通関数
              -- =======================================
              xxwsh_common910_pkg.get_fresh_pass_date(
                 gr_demand_tbl(ln_d_cnt).deliver_to_id          -- 1.配送先ID
               , gr_demand_tbl(ln_d_cnt).shipping_item_code     -- 2.品目コード
               , gr_demand_tbl(ln_d_cnt).schedule_arrival_date  -- 3.着荷日
               , gr_demand_tbl(ln_d_cnt).schedule_ship_date     -- 4.出庫予定日
               , ld_manufacture_date                            -- 5.鮮度条件合格製造日
               , lv_fresh_retcode                               -- 6.リターン・コード
               , lv_errbuf                                      -- 7.エラー・メッセージ
              );
              -- 共通関数のエラー
              IF ( lv_fresh_retcode = gv_cons_error ) THEN
-- 2009/01/26 D.Nihei Mod End
                -- メッセージのセット
                lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                                         gv_cons_msg_kbn_wsh    -- 'XXWSH'
                                       , gv_msg_92a_006         -- 共通関数エラー
                                       , gv_tkn_request_type    -- トークン'REQUEST_TYPE'
                                       , gv_request_name_ship
                                       , gv_tkn_request_no      -- トークン'REQUEST_NO'
                                       , gr_demand_tbl(ln_d_cnt).request_no
                                       , gv_tkn_p_date          -- トークン'P_DATE'
                                       , gr_supply_tbl(ln_s_cnt).p_date
                                       , gv_tkn_use_by_date     -- トークン'USE_BY_DATE'
                                       , gr_supply_tbl(ln_s_cnt).use_by_date
                                       , gv_tkn_fix_no          -- トークン'FIX_NO'
                                       , gr_supply_tbl(ln_s_cnt).fix_no
                                       , gv_tkn_err_code        -- トークン'ERR_CODE'
                                       , lv_errbuf              -- エラーメッセージ
                                       , gv_tkn_err_msg         -- トークン'ERR_MSG'
                                       , lv_errmsg)             -- ユーザー・エラー・メッセージ
                                       , 1
                                       , 5000
                                         );
                -- 後続処理は中止する
                gn_error_cnt := 1;
                RAISE global_process_expt;
              END IF;
-- 2009/01/26 D.Nihei Add Start 本番#936対応
            END IF;
-- 2009/01/26 D.Nihei Add End
--
-- 2009/01/26 D.Nihei Mod Start 本番#936対応
--            -- 鮮度条件異常の場合
--            IF ( ln_result = 1 ) THEN
--              -- チェック処理結果を格納する
--              IF ( ( gr_check_tbl(1).warnning_date IS NULL )
--                OR ( gr_check_tbl(1).warnning_date <= ld_standard_date ))
--                THEN
            -- 正常の場合
            IF ( lv_fresh_retcode = gv_status_normal ) THEN
              -- ロット製造日 < 鮮度条件合格製造日の場合
              IF ( FND_DATE.STRING_TO_DATE(gr_supply_tbl(ln_s_cnt).p_date, 'YYYY/MM/DD') < ld_manufacture_date ) THEN
                -- チェック処理結果を格納する
                IF ( ( gr_check_tbl(1).warnning_date IS NULL )
                  OR ( gr_check_tbl(1).warnning_date <= ld_manufacture_date ) ) THEN
-- 2009/01/26 D.Nihei Mod End
                  gr_check_tbl(1).warnning_class := gv_cons_wrn_fresh;                   -- 警告区分
-- 2009/01/26 D.Nihei Mod Start 本番#936対応
--                  gr_check_tbl(1).warnning_date  := ld_standard_date;                    -- 警告日付
                  gr_check_tbl(1).warnning_date  := ld_manufacture_date;                 -- 警告日付
-- 2009/01/26 D.Nihei Mod End
                  gr_check_tbl(1).lot_no         := gr_supply_tbl(ln_s_cnt).lot_no;      -- ロットNo
                  gr_check_tbl(1).p_date         := gr_supply_tbl(ln_s_cnt).p_date;      -- 製造年月日
                  gr_check_tbl(1).fix_no         := gr_supply_tbl(ln_s_cnt).fix_no;      -- 固有番号
                  gr_check_tbl(1).use_by_date    := gr_supply_tbl(ln_s_cnt).use_by_date; -- 賞味期限
                END IF;
--
                -- 後続の他のチェックをパスするためにフラグON
                lv_no_check_flg := gv_cons_flg_yes;
                -- 警告終了
              END IF;
              -- ループの間一度でもここを通ればA-11はコールする
              lv_no_meisai_flg := gv_cons_flg_yes;
--
-- 2009/01/26 D.Nihei Add Start 本番#936対応
            END IF;
-- 2009/01/26 D.Nihei Add End
          END IF;
--
          IF ( lv_no_check_flg = gv_cons_flg_no ) THEN
            -- ===============================================
            -- A-9  引当情報作成処理 make_allot_inf
            -- ===============================================
            make_allot_inf(iv_item_class        -- 入力パラメータの商品区分
                         , ln_d_cnt
                         , ln_s_cnt
                         , lv_exit_flg
                         , lv_errbuf            -- エラー・メッセージ           --# 固定 #
                         , lv_retcode           -- リターン・コード             --# 固定 #
                         , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
                           );
            -- エラー処理
            IF ( lv_retcode = gv_status_error ) THEN
              gn_error_cnt := 1;
              RAISE global_process_expt;
            END IF;
--
            -- 全部引当できた場合は供給情報のループを抜ける
            IF ( lv_exit_flg = gv_cons_flg_yes ) THEN
              EXIT;
            END IF;
          END IF;
--
        END IF;
-- 
      END LOOP supply_inf_loop; -- 供給情報ループ終わり
--
      -- ===============================================
      -- A-10 引当情報登録処理 regist_allot_inf
      -- ===============================================
      IF (ln_s_max > 0) THEN
        regist_allot_inf(lv_errbuf            -- エラー・メッセージ           --# 固定 #
                       , lv_retcode           -- リターン・コード             --# 固定 #
                       , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
                         );
        -- エラー処理
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF ( lv_no_meisai_flg = gv_cons_flg_yes ) THEN
        -- ===============================================
        -- A-11 明細引当数作成処理 make_line_allot
        -- ===============================================
        make_line_allot(ln_d_cnt             -- 需要情報の処理カウンタ
                      , lv_errbuf            -- エラー・メッセージ           --# 固定 #
                      , lv_retcode           -- リターン・コード             --# 固定 #
                      , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
                        );
        -- エラー処理
        IF ( lv_retcode = gv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ov_retcode := gv_status_warn;
        END IF;
      END IF;
--
    END LOOP demand_inf_loop; -- 需要情報ループ終わり
--
    -- ===============================================
    -- A-12 明細情報更新処理 update_line_inf
    -- ===============================================
    update_line_inf(lv_errbuf            -- エラー・メッセージ           --# 固定 #
                  , lv_retcode           -- リターン・コード             --# 固定 #
                  , lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
                    );
    -- エラー処理
    IF ( lv_retcode = gv_status_error ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf                OUT NOCOPY   VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode               OUT NOCOPY   VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_item_class         IN           VARCHAR2,      -- 商品区分
    iv_action_type        IN           VARCHAR2,      -- 処理種別
    iv_block1             IN           VARCHAR2,      -- ブロック１
    iv_block2             IN           VARCHAR2,      -- ブロック２
    iv_block3             IN           VARCHAR2,      -- ブロック３
    iv_deliver_from_id    IN           VARCHAR2,      -- 出庫元
    iv_deliver_type       IN           VARCHAR2,      -- 出庫形態
    iv_deliver_date_from  IN           VARCHAR2,      -- 出庫日From
    iv_deliver_date_to    IN           VARCHAR2,      -- 出庫日To
    iv_item_code          IN           VARCHAR2,      -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    iv_instruction_dept   IN           VARCHAR2       -- 指示部署
-- 2009/01/28 H.Itou Add End
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
    ln_deliver_from_id   NUMBER; -- 出庫元
    ln_deliver_type      NUMBER; -- 出庫形態
--
  BEGIN
--
    -- 数値型に変換する
    lv_retcode := gv_cons_flg_yes;
    ln_deliver_from_id := TO_NUMBER(iv_deliver_from_id);
    lv_retcode := gv_cons_flg_no;
    ln_deliver_type    := TO_NUMBER(iv_deliver_type);
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
    -----------------------------------------------
    -- 入力パラメータ出力                        --
    -----------------------------------------------
    -- 入力パラメータ「商品区分」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02851','ITEM',iv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「処理種別」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02852','AC_TYPE',iv_action_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック1」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02853','IN_BLOCK1',iv_block1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック2」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02854','IN_BLOCK2',iv_block2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「ブロック3」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02855','IN_BLOCK3',iv_block3);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫元」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02856','FROM_ID',iv_deliver_from_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫形態」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02857','TYPE',iv_deliver_type);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日From」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02858','D_FROM',iv_deliver_date_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫日To」出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXWSH','APP-XXWSH-02859','D_TO',iv_deliver_date_to);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
--暫定START
    -- 入力パラメータ「品目コード」出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'品目コード： ' || iv_item_code);
--暫定END
--
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
    -- 入力パラメータ「指示部署」出力
    gv_out_msg := '指示部署：' || iv_instruction_dept;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
-- 2009/01/28 H.Itou Add End
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    -- WHOカラム情報の取得
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ログインID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ログインユーザID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- コンカレント・プログラム・アプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- コンカレント・プログラムID
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_warn_cnt   := 0;   -- 警告件数
    gn_error_cnt  := 0;   -- エラー件数
--
    submain(
      iv_item_class,        -- 商品区分
      iv_action_type,       -- 処理種別
      iv_block1,            -- ブロック１
      iv_block2,            -- ブロック２
      iv_block3,            -- ブロック３
      ln_deliver_from_id,   -- 出庫元
      ln_deliver_type,      -- 出庫形態
      iv_deliver_date_from, -- 出庫日From
      iv_deliver_date_to,   -- 出庫日To
      iv_item_code,         -- 品目コード
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
      iv_instruction_dept,  -- 指示部署
-- 2009/01/28 H.Itou Add End
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
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
    --処理件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --成功件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --エラー件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --スキップ件数出力
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
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
--
-- 2010/01/08 M.Hokkanji Ver1.12 START
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--FND_FILE.PUT_LINE( FND_FILE.LOG, '【ロット取得件数：】' || gn_lot_cnt || '【引当可能数取得件数：】' || gn_get_can_enc_qty_cnt);
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- 2010/01/08 M.Hokkanji Ver1.12 END
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    WHEN INVALID_NUMBER THEN
      -- メッセージのセット
      -- 出荷元に不正データあり
      IF (lv_retcode = gv_cons_flg_yes) THEN
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                     , gv_msg_92a_009      -- パラメータ書式エラー
                                                     , gv_tkn_parameter    -- トークン'PARAMETER'
                                                     , gv_cons_deliv_fm    -- '出荷元'
                                                     , gv_tkn_type         -- トークン'TYPE'
                                                     , gv_cons_number)     -- '数値'
                                                     , 1
                                                     , 5000);
      -- 出荷形態に不正データあり
      ELSE
        lv_errbuf := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                     , gv_msg_92a_009      -- パラメータ書式エラー
                                                     , gv_tkn_parameter    -- トークン'PARAMETER'
                                                     , gv_cons_deliv_tp    -- '出荷形態'
                                                     , gv_tkn_type         -- トークン'TYPE'
                                                     , gv_cons_number)     -- '数値'
                                                     , 1
                                                     , 5000);
      END IF;
      errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      retcode := gv_status_error;                                            --# 任意 #
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
END XXWSH920008C;
/

