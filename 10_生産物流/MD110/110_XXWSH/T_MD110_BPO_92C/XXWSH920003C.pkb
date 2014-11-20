CREATE OR REPLACE PACKAGE BODY XXWSH920003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920003C(body)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 計画・移動・在庫・販売計画/引取計画 T_MD050_BPO921
 * MD.070           : 計画・移動・在庫・販売計画/引取計画 T_MD070_BPO92E
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 * header_data_save       ヘッダ作成データ保存
 * check_parameter        C-1  パラメータチェック
 * get_profile            C-2  プロファイル値取得
 * purge_table            C-3  パージ処理
 * get_data               C-4  情報抽出
 * get_rule               C-5  ルール取得
 * ins_ints_table         C-6  中間テーブル登録(出荷)
 * ins_intm_table         C-7  中間テーブル登録(移動)
 * get_ints_data          C-8  中間テーブル抽出(出荷)
 * get_intm_data          C-9  中間テーブル抽出(移動)
 * regi_move_data         C-10 移動依頼/指示登録
 * regi_order_data        C-11 発注依頼登録
 * regi_order_detail      C-12 受注明細更新
 * regi_move_detail       C-13 移動指示/指示明細更新
 * insert_tables          C-14 登録更新処理
 * submain                メイン処理プロシージャ
 * main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/23   1.0   Oracle 土田 茂   初回作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gn_status_normal NUMBER := 0;
  gn_status_error  NUMBER := 2;
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
--  lock_expt              EXCEPTION;     -- ロック(ビジー)エラー
  common_warn_expt       EXCEPTION;
--
--  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(15)  := 'XXWSH920003C';       -- パッケージ名
  --プロファイル
  --メッセージ番号
  gv_msg_wsh_13101     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13101';    -- 必須パラメータ
  gv_msg_wsh_13004     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13004';    -- 日付存在
  gv_msg_wsh_13005     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13005';    -- 日付逆転
  gv_msg_wsh_12101     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-12101';    -- プロファイル取得
  gv_msg_wsh_13103     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13103';    -- ロックエラー
  gv_msg_wsh_13006     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13006';    -- データ削除エラー
  gv_msg_wsh_13007     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13007';    -- 在庫補充元取得
  gv_msg_wsh_13008     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13008';    -- 採番関数エラー
  gv_msg_wsh_13009     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13009';    -- 最大配送区分算出エラー
  gv_msg_wsh_13124     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13124';    -- 合計値算出関数エラー
  gv_msg_wsh_13172     CONSTANT VARCHAR2(15)  := 'APP-XXWSH-13172';    -- 積載効率算出関数エラー
  --トークン
  gv_tkn_item          CONSTANT VARCHAR2(15)  := 'ITEM';               -- 入力パラメータ
  gv_tkn_item_from     CONSTANT VARCHAR2(15)  := 'ITEM_FROM';          -- 期間From
  gv_tkn_item_to       CONSTANT VARCHAR2(15)  := 'ITEM_TO';            -- 期間To
  gv_tkn_value         CONSTANT VARCHAR2(15)  := 'VALUE';              -- 入力日付値
  gv_tkn_value_from    CONSTANT VARCHAR2(15)  := 'VALUE_FROM';         -- 入力日付From
  gv_tkn_value_to      CONSTANT VARCHAR2(15)  := 'VALUE_TO';           -- 入力日付To
  gv_tkn_table_name    CONSTANT VARCHAR2(15)  := 'TABLE_NAME';         -- テーブル名
  gv_tkn_prof_name     CONSTANT VARCHAR2(15)  := 'PROF_NAME';          -- プロファイル名
  gv_tkn_param1        CONSTANT VARCHAR2(15)  := 'PARAM1';             -- パラメータ1
  gv_tkn_param2        CONSTANT VARCHAR2(15)  := 'PARAM2';             -- パラメータ2
  gv_tkn_param3        CONSTANT VARCHAR2(15)  := 'PARAM3';             -- パラメータ3
  gv_tkn_param4        CONSTANT VARCHAR2(15)  := 'PARAM4';             -- パラメータ4
  gv_tkn_param5        CONSTANT VARCHAR2(15)  := 'PARAM5';             -- パラメータ5
  gv_tkn_param6        CONSTANT VARCHAR2(15)  := 'PARAM6';             -- パラメータ6
  gv_tkn_param7        CONSTANT VARCHAR2(15)  := 'PARAM7';             -- パラメータ7
  gv_tkn_param8        CONSTANT VARCHAR2(15)  := 'PARAM8';             -- パラメータ8
  gv_tkn_param9        CONSTANT VARCHAR2(15)  := 'PARAM9';             -- パラメータ9
  gv_tkn_param10       CONSTANT VARCHAR2(15)  := 'PARAM10';            -- パラメータ10
  --定数
  gv_cons_input_param  CONSTANT VARCHAR2(100) := '入力パラメータ値';   -- '入力パラメータ値'
  gv_cons_m_org_id     CONSTANT VARCHAR2(50)  := 'XXCMN_MASTER_ORG_ID';-- マスタ組織ID
  gv_cons_m_org_id_tkn CONSTANT VARCHAR2(50)  := 'XXCMN:マスタ組織ID'; -- マスタ組織ID
  gv_cons_msg_kbn_wsh  CONSTANT VARCHAR2(5)   := 'XXWSH';              -- メッセージ区分XXWSH
  gv_cons_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';              -- メッセージ区分XXCMN
  gv_cons_t_deliv      CONSTANT VARCHAR2(1)   := '1';                  -- '出荷依頼'(処理種別)
  gv_cons_t_move       CONSTANT VARCHAR2(1)   := '3';                  -- '移動指示'(処理種別)
  gv_cons_a_type       CONSTANT VARCHAR2(15)  := '処理種別';           -- '処理種別'
  gv_cons_deliv_f_id   CONSTANT VARCHAR2(15)  := '出庫';               -- '出庫'
  gv_cons_deliv_type   CONSTANT VARCHAR2(15)  := '出庫形態';           -- '出庫形態'
  gv_cons_obj_d_from   CONSTANT VARCHAR2(15)  := '対象期間From';       -- '対象期間From'
  gv_cons_obj_d_to     CONSTANT VARCHAR2(15)  := '対象期間To';         -- '対象期間To'
  gv_cons_ship_date    CONSTANT VARCHAR2(15)  := '出庫日指定';         -- '出庫日指定'
  gv_cons_arvl_date    CONSTANT VARCHAR2(15)  := '着日指定';           -- '着日指定'
  gv_cons_inst_p_code  CONSTANT VARCHAR2(15)  := '指示部署指定';       -- '指示部署指定'
  gv_cons_dlv_tmp_jp   CONSTANT VARCHAR2(50)  := '出荷在庫補充元中間テーブル';
  gv_cons_dlv_tmp_tbl  CONSTANT VARCHAR2(50)  := 'xxwsh_shipping_stock_rep_tmp';
                                                                 -- 出荷在庫補充元中間テーブル
  gv_cons_mov_tmp_tbl  CONSTANT VARCHAR2(50)  := 'xxwsh_mov_stock_rep_tmp';
                                                                 -- 移動在庫補充元中間テーブル
  gv_cons_mov_tmp_jp   CONSTANT VARCHAR2(50)  := '移動在庫補充元中間テーブル';
  gv_cons_mov_hdr_tbl  CONSTANT VARCHAR2(50)  := '移動依頼/指示ヘッダテーブル';
  gv_cons_odr_hdr_tbl  CONSTANT VARCHAR2(50)  := '発注依頼ヘッダテーブル';
  gv_cons_odr_cat_ret  CONSTANT VARCHAR2(15)  := 'RETURN';             -- 受注カテゴリ(RETURN)
  gv_cons_status_shime CONSTANT VARCHAR2(2)   := '03';                 -- 「締め済み」
  gv_cons_flg_y        CONSTANT VARCHAR2(1)   := 'Y';                  -- フラグ 'Y'
  gv_cons_flg_n        CONSTANT VARCHAR2(1)   := 'N';                  -- フラグ 'N'
  gv_cons_flg_on       CONSTANT VARCHAR2(1)   := '1';                  -- フラグ '1'=ON
  gv_cons_flg_off      CONSTANT VARCHAR2(1)   := '0';                  -- フラグ '0'=OFF
  gv_cons_id_drink     CONSTANT VARCHAR2(1)   := '2';                  -- 商品区分・ドリンク
  gv_cons_id_leaf      CONSTANT VARCHAR2(1)   := '1';                  -- 商品区分・リーフ
  gv_cons_item_class   CONSTANT VARCHAR2(1)   := '1';                  -- 品目区分
  gv_cons_item_product CONSTANT VARCHAR2(1)   := '5';                  -- 「製品」
  gv_cons_mov_sts_e    CONSTANT VARCHAR2(2)   := '02';                 -- 「依頼済」
  gv_cons_mov_sts_c    CONSTANT VARCHAR2(2)   := '03';                 -- 「調整中」
  gv_cons_move_type    CONSTANT VARCHAR2(1)   := '1';                  -- 「積送あり」
  gv_cons_rule_move    CONSTANT VARCHAR2(1)   := '0';                  -- 「移動」
  gv_cons_rule_order   CONSTANT VARCHAR2(1)   := '1';                  -- 「発注」
  gv_cons_schema_wsh   CONSTANT VARCHAR2(5)   := 'XXWSH';              -- スキーマXXWSH
  gv_cons_seq_move     CONSTANT VARCHAR2(1)   := '1';                  -- 採番区分「移動」
  gv_cons_seq_order    CONSTANT VARCHAR2(1)   := '2';                  -- 採番区分「発注」
  gv_cons_sts_mi       CONSTANT VARCHAR2(2)   := '10';                 -- 通知ステータス「未通知」
  gv_cons_umu_ari      CONSTANT VARCHAR2(1)   := '1';                  -- 有無区分「有」
  gv_cons_wh           CONSTANT VARCHAR2(1)   := '4';                  -- コード区分「倉庫」
  gv_cons_ds_deliv     CONSTANT VARCHAR2(1)   := '2';                  -- 直送倉庫区分「出荷」
  gv_cons_ds_normal    CONSTANT VARCHAR2(1)   := '1';                  -- 直送倉庫区分「通常」
  gv_cons_ds_type_n    CONSTANT VARCHAR2(1)   := '1';                  -- 直送
  gv_cons_ds_type_d    CONSTANT VARCHAR2(1)   := '0';                  -- 直送以外
  gv_cons_wild_card    CONSTANT VARCHAR2(7)   := 'ZZZZZZZ';            -- 品目コード('ZZZZZZZ')
  gv_cons_weight       CONSTANT VARCHAR2(1)   := '1';                  -- 重量容積区分「重量」
  gv_cons_capacity     CONSTANT VARCHAR2(1)   := '2';                  -- 重量容積区分「容積」
  gv_cons_p_flg_prod   CONSTANT VARCHAR2(1)   := '1';                  -- 製品識別区分「製品」
  gv_cons_p_flg_noprod CONSTANT VARCHAR2(1)   := '2';                  -- 製品識別区分「製品以外」
  gv_cons_over_1y      CONSTANT VARCHAR2(1)   := '1';               -- 積載オーバー区分「オーバー」
  gv_cons_over_0n      CONSTANT VARCHAR2(1)   := '0';               -- 積載オーバー区分「正常」
  gv_cons_no_cont_freight   CONSTANT VARCHAR2(1)   := '0';                  -- 契約外運賃区分「対象外」
  gv_cons_po_sts       CONSTANT VARCHAR2(2)   := '10';                 -- 「依頼作成済」
  gv_change_flag_n     CONSTANT VARCHAR2(2)   := 'N';                  -- 変更区分「変更なし」
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_organization_id   NUMBER :=0;       -- マスタ組織ID
  gn_target_cnt_deliv  NUMBER :=0;       -- 対象件数(出荷)
  gn_target_cnt_move   NUMBER :=0;       -- 対象件数(移動)
  gn_upd_data_cnt_ol   NUMBER :=0;       -- 受注明細更新対象件数
  gn_upd_data_cnt_ml   NUMBER :=0;       -- 移動依頼/指示明細更新対象件数
  gn_ins_data_cnt_oh   NUMBER :=0;       -- 受注ヘッダ挿入対象件数
  gn_ins_data_cnt_ol   NUMBER :=0;       -- 受注明細挿入対象件数
  gn_ins_data_cnt_mh   NUMBER :=0;       -- 移動依頼/指示ヘッダ挿入対象件数
  gn_ins_data_cnt_ml   NUMBER :=0;       -- 移動依頼/指示明細挿入対象件数
  gn_login_user        NUMBER;           -- ログインID
  gn_created_by        NUMBER;           -- ログインユーザID
  gn_conc_request_id   NUMBER;           -- 要求ID
  gn_prog_appl_id      NUMBER;           -- アプリケーションID
  gn_conc_program_id   NUMBER;           -- プログラムID
  gv_loading_over_flg  VARCHAR2(1) := gv_cons_flg_n;      -- 最大積載効率100%オーバーフラグ
  gv_mov_hdr_id        xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;              -- 移動ヘッダID
  gv_odr_hdr_id        xxpo_requisition_headers.requisition_header_id%TYPE;      -- 発注ヘッダID
--
-- ヘッダ単位項目保存用(移動)
  gn_stock_rep_origin_m  xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;     -- 在庫補充元
  gv_deliver_from_m      xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE;         -- 出荷元コード
  gv_weight_capacity_class_m xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE;
                                                                                 -- 重量容積区分
  gv_product_flg_m       xxinv_mov_req_instr_headers.product_flg%TYPE;           -- 製品識別区分
  gv_item_class_code_m   xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE;      -- 品目区分
  gv_stock_rep_rule_m    xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE;       --在庫補充ルール
-- ヘッダ単位項目保存用(発注)
  gn_stock_rep_origin_o  xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;     -- 在庫補充元
  gv_deliver_from_o      xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE;         -- 出荷元コード
  gv_deliver_to_o        xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE;           -- 出荷先コード
  gv_weight_capacity_class_o xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE;
                                                                                 -- 重量容積区分
  gv_item_class_code_o   xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE;      -- 品目区分
  gv_stock_rep_rule_o    xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE;       --在庫補充ルール
-- 明細単位項目保存用
  gv_item_code_ml         xxwsh_mov_stock_rep_tmp.item_code%TYPE;           -- 品目コード
  gv_item_code_ol         xxwsh_mov_stock_rep_tmp.item_code%TYPE;          -- 品目コード
  gn_line_number            NUMBER := 0;                                   -- 明細番号(移動)
  gn_order_line_number      NUMBER := 0;                                   -- 明細番号(受注)
--合計保持用
  gn_sum_quantity           NUMBER :=0;                                    -- 合計数量
  gn_sum_small_quantity     NUMBER :=0;                                    -- 合計小口個数
  gn_sum_weight             NUMBER :=0;                                    -- 合計混載重量
  gn_sum_capacity           NUMBER :=0;                                    -- 合計混載容積
  gn_sum_inst_quantity      NUMBER :=0;                                    -- 合計指示数量(移動)
  gn_sum_inst_line_quantity NUMBER :=0;                                    -- 合計指示数量(移動)
  gn_sum_req_quantity       NUMBER :=0;                                    -- 合計依頼数量(発注)
  gn_sum_req_line_quantity  NUMBER :=0;                                    -- 合計依頼数量(発注)
--
  -- C-4, C-8 出荷情報抽出のデータを格納するレコード
  TYPE deliv_data_rec IS RECORD(
    deliver_to_id             xxwsh_shipping_stock_rep_tmp.deliver_to_id%TYPE,    -- 出荷先ID
    deliver_to                xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE,       -- 出荷先コード
    request_no                xxwsh_shipping_stock_rep_tmp.request_no%TYPE,       -- 依頼No
    deliver_from_id           xxwsh_shipping_stock_rep_tmp.deliver_from_id%TYPE,  -- 出荷元ID
    deliver_from              xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE,     -- 出荷元コード
    weight_capacity_class     xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE,
                                                                                  -- 重量容積区分
    shipping_inventory_item_id xxwsh_shipping_stock_rep_tmp.shipping_inventory_item_id%TYPE,
                                                                                  -- 出荷品目ID
    item_id                   xxwsh_shipping_stock_rep_tmp.item_id%TYPE,          -- OPM品目ID
    shipping_item_code        xxwsh_shipping_stock_rep_tmp.shipping_item_code%TYPE, -- 品目コード
    quantity                  xxwsh_shipping_stock_rep_tmp.quantity%TYPE,         -- 数量
    order_type_id             xxwsh_shipping_stock_rep_tmp.order_type_id%TYPE,    -- 受注タイプID
    transaction_type_name     xxwsh_shipping_stock_rep_tmp.transaction_type_name%TYPE,-- 出庫形態
    item_class_code           xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE,  -- 品目区分
    product_flg               xxinv_mov_req_instr_headers.product_flg%TYPE,       -- 製品識別フラグ
    prod_class_code           xxwsh_shipping_stock_rep_tmp.prod_class_code%TYPE,  -- 商品区分
    drop_ship_wsh_div         xxwsh_shipping_stock_rep_tmp.drop_ship_wsh_div%TYPE,-- 直送区分
    num_of_deliver            xxwsh_shipping_stock_rep_tmp.num_of_deliver%TYPE,   -- 出荷入数
    conv_unit                 xxwsh_shipping_stock_rep_tmp.conv_unit%TYPE,        -- 入出庫換算単位
    num_of_cases              xxwsh_shipping_stock_rep_tmp.num_of_cases%TYPE,     -- ケース入数
    item_um                   xxwsh_shipping_stock_rep_tmp.item_um%TYPE,          -- 単位
    frequent_qty              xxwsh_shipping_stock_rep_tmp.frequent_qty%TYPE,     -- 代表入数
    stock_rep_rule            xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE,   -- 在庫補充ルール
    stock_rep_origin          xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE  -- 在庫補充元
  );
  TYPE deliv_data_tbl IS TABLE OF deliv_data_rec INDEX BY PLS_INTEGER;
  gr_deliv_data_tbl deliv_data_tbl;
--
  -- C-4, C-9 移動情報抽出のデータを格納するレコード
  TYPE move_data_rec IS RECORD(
    mov_num                xxwsh_mov_stock_rep_tmp.mov_num%TYPE,              -- 移動No
    shipped_locat_id       xxwsh_mov_stock_rep_tmp.shipped_locat_id%TYPE,     -- 出庫元ID
    shipped_locat_code     xxwsh_mov_stock_rep_tmp.shipped_locat_code%TYPE,   -- 出庫元コード
    ship_to_locat_id       xxwsh_mov_stock_rep_tmp.ship_to_locat_id%TYPE,     -- 入庫先ID
    ship_to_locat_code     xxwsh_mov_stock_rep_tmp.ship_to_locat_code%TYPE,   -- 入庫先コード
    weight_capacity_class  xxwsh_mov_stock_rep_tmp.weight_capacity_class%TYPE,-- 重量容積区分
    item_id                xxwsh_mov_stock_rep_tmp.item_id%TYPE,              -- 品目ID
    inventory_item_id      xxwsh_mov_stock_rep_tmp.inventory_item_id%TYPE,    -- 在庫品目ID
    item_code              xxwsh_mov_stock_rep_tmp.item_code%TYPE,            -- 品目コード
    instruct_qty           xxwsh_mov_stock_rep_tmp.instruct_qty%TYPE,         -- 指示数量
    item_class_code        xxwsh_mov_stock_rep_tmp.item_class_code%TYPE,      -- 品目区分
    product_flg            xxinv_mov_req_instr_headers.product_flg%TYPE,      -- 製品識別フラグ
    prod_class_code        xxwsh_mov_stock_rep_tmp.prod_class_code%TYPE,      -- 商品区分
    num_of_deliver         xxwsh_mov_stock_rep_tmp.num_of_deliver%TYPE,       -- 出荷入数
    conv_unit              xxwsh_mov_stock_rep_tmp.conv_unit%TYPE,            -- 入出庫換算単位
    num_of_cases           xxwsh_mov_stock_rep_tmp.num_of_cases%TYPE,         -- ケース入数
    item_um                xxwsh_mov_stock_rep_tmp.item_um%TYPE,              -- 単位
    frequent_qty           xxwsh_mov_stock_rep_tmp.frequent_qty%TYPE,         -- 代表入数
    stock_rep_rule         xxwsh_mov_stock_rep_tmp.stock_rep_rule%TYPE,       -- 在庫補充ルール
    stock_rep_origin       xxwsh_mov_stock_rep_tmp.stock_rep_origin%TYPE      -- 在庫補充元
  );
  TYPE move_data_tbl IS TABLE OF move_data_rec INDEX BY PLS_INTEGER;
  gr_move_data_tbl move_data_tbl;
--
  -- 出荷情報抽出のデータ(FORALLでのINSERT用)
  TYPE s_deliver_to_id                 -- 出荷先ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_to_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_to                    -- 出荷先コード
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_to%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_request_no                    -- 依頼No
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.request_no%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_from_id               -- 出荷元ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_from_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_deliver_from                  -- 出荷元コード
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.deliver_from%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_weight_capacity_class         -- 重量容積区分
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_shipping_inventory_item_id    -- 出荷品目ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.shipping_inventory_item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_id                       -- 出荷品目ID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_shipping_item_code            -- 品目コード
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.shipping_item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_quantity                      -- 数量
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.quantity%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_order_type_id                 -- 受注タイプID
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.order_type_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_transaction_type_name         -- 出庫形態
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.transaction_type_name%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_class_code               -- 品目区分
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_prod_class_code               -- 商品区分
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.prod_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_drop_ship_wsh_div             -- 直送区分
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.drop_ship_wsh_div%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_num_of_deliver                -- 出荷入数
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.num_of_deliver%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_conv_unit                     -- 入出庫換算単位
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.conv_unit%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_num_of_cases                  -- ケース入数
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.num_of_cases%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_item_um                       -- 単位
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.item_um%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_frequent_qty                  -- 代表入数
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.frequent_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_stock_rep_rule                -- 在庫補充ルール
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.stock_rep_rule%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE s_stock_rep_origin              -- 在庫補充元
    IS TABLE OF xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 移動情報抽出のデータ(FORALLでのINSERT用)
  TYPE i_mov_num                       -- 移動ヘッダID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.mov_num%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_shipped_locat_id              -- 出庫元ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.shipped_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_shipped_locat_code            -- 出庫元コード
    IS TABLE OF xxwsh_mov_stock_rep_tmp.shipped_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_ship_to_locat_id              -- 入庫先ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.ship_to_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_ship_to_locat_code            -- 入庫先コード
    IS TABLE OF xxwsh_mov_stock_rep_tmp.ship_to_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_weight_capacity_class         -- 重量容積区分
    IS TABLE OF xxwsh_mov_stock_rep_tmp.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_id                       -- 品目ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_inventory_item_id             -- 在庫品目ID
    IS TABLE OF xxwsh_mov_stock_rep_tmp.inventory_item_id%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_code                     -- 品目コード
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_instruct_qty                  -- 指示数量
    IS TABLE OF xxwsh_mov_stock_rep_tmp.instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_class_code               -- 品目区分
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_prod_class_code               -- 商品区分
    IS TABLE OF xxwsh_mov_stock_rep_tmp.prod_class_code%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_num_of_deliver                -- 出荷入数
    IS TABLE OF xxwsh_mov_stock_rep_tmp.num_of_deliver%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_conv_unit                     -- 入出庫換算単位
    IS TABLE OF xxwsh_mov_stock_rep_tmp.conv_unit%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_num_of_cases                  -- ケース入数
    IS TABLE OF xxwsh_mov_stock_rep_tmp.num_of_cases%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_item_um                       -- 単位
    IS TABLE OF xxwsh_mov_stock_rep_tmp.item_um%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_frequent_qty                  -- 代表入数
    IS TABLE OF xxwsh_mov_stock_rep_tmp.frequent_qty%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_stock_rep_rule                -- 在庫補充ルール
    IS TABLE OF xxwsh_mov_stock_rep_tmp.stock_rep_rule%TYPE
    INDEX BY BINARY_INTEGER;
  TYPE i_stock_rep_origin              -- 在庫補充元
    IS TABLE OF xxwsh_mov_stock_rep_tmp.stock_rep_origin%TYPE
    INDEX BY BINARY_INTEGER;
--
  -- 出荷情報抽出のデータ(FORALLでのINSERT用)
  gt_s_deliver_to_id              s_deliver_to_id;              -- 出荷先ID
  gt_s_deliver_to                 s_deliver_to;                 -- 出荷先コード
  gt_s_request_no                 s_request_no;                 -- 依頼No
  gt_s_deliver_from_id            s_deliver_from_id;            -- 出荷元ID
  gt_s_deliver_from               s_deliver_from;               -- 出荷元コード
  gt_s_weight_capacity_class      s_weight_capacity_class;      -- 重量容積区分
  gt_s_shipping_inv_item_id       s_shipping_inventory_item_id; -- 出荷品目ID
  gt_s_item_id                    s_item_id;                    -- 出荷品目ID
  gt_s_shipping_item_code         s_shipping_item_code;         -- 品目コード
  gt_s_quantity                   s_quantity;                   -- 数量
  gt_s_order_type_id              s_order_type_id;              -- 受注タイプID
  gt_s_transaction_type_name      s_transaction_type_name;      -- 出庫形態
  gt_s_item_class_code            s_item_class_code;            -- 品目区分
  gt_s_prod_class_code            s_prod_class_code;            -- 商品区分
  gt_s_drop_ship_wsh_div          s_drop_ship_wsh_div;          -- 直送区分
  gt_s_num_of_deliver             s_num_of_deliver;             -- 出荷入数
  gt_s_conv_unit                  s_conv_unit;                  -- 入出庫換算単位
  gt_s_num_of_cases               s_num_of_cases;               -- ケース入数
  gt_s_item_um                    s_item_um;                    -- 単位
  gt_s_frequent_qty               s_frequent_qty;               -- 代表入数
  gt_s_stock_rep_rule             s_stock_rep_rule;             -- 在庫補充ルール
  gt_s_stock_rep_origin           s_stock_rep_origin;           -- 在庫補充元
--
  -- 移動情報抽出のデータ(FORALLでのINSERT用)
  gt_i_mov_num                    i_mov_num;                    -- 移動番号
  gt_i_shipped_locat_id           i_shipped_locat_id;           -- 出庫元ID
  gt_i_shipped_locat_code         i_shipped_locat_code;         -- 出庫元コード
  gt_i_ship_to_locat_id           i_ship_to_locat_id;           -- 入庫先ID
  gt_i_ship_to_locat_code         i_ship_to_locat_code;         -- 入庫先コード
  gt_i_weight_capacity_class      i_weight_capacity_class;      -- 重量容積区分
  gt_i_item_id                    i_item_id;                    -- 品目ID
  gt_i_inventory_item_id          i_inventory_item_id;          -- 在庫品目コード
  gt_i_item_code                  i_item_code;                  -- 品目コード
  gt_i_instruct_qty               i_instruct_qty;               -- 指示数量
  gt_i_item_class_code            i_item_class_code;            -- 品目区分
  gt_i_prod_class_code            i_prod_class_code;            -- 商品区分
  gt_i_num_of_deliver             i_num_of_deliver;             -- 出荷入数
  gt_i_conv_unit                  i_conv_unit;                  -- 入出庫換算単位
  gt_i_num_of_cases               i_num_of_cases;               -- ケース入数
  gt_i_item_um                    i_item_um;                    -- 単位
  gt_i_frequent_qty               i_frequent_qty;               -- 代表入数
  gt_i_stock_rep_rule             i_stock_rep_rule;             -- 在庫補充ルール
  gt_i_stock_rep_origin           i_stock_rep_origin;           -- 在庫補充元
--
  -- C-10 移動依頼/指示ヘッダのデータを格納するレコード
  TYPE move_header_rec IS RECORD(
    mov_hdr_id                  xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,
    -- 移動ヘッダID
    mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE,
    -- 移動番号
    mov_type                    xxinv_mov_req_instr_headers.mov_type%TYPE,
    -- 移動タイプ
    entered_date                xxinv_mov_req_instr_headers.entered_date%TYPE,
    -- 入力日
    instruction_post_code       xxinv_mov_req_instr_headers.instruction_post_code%TYPE,
    -- 指示部署
    status                      xxinv_mov_req_instr_headers.status%TYPE,
    -- ステータス
    notif_status                xxinv_mov_req_instr_headers.notif_status%TYPE,
    -- 通知ステータス
    shipped_locat_id            xxinv_mov_req_instr_headers.shipped_locat_id%TYPE,
    -- 出庫元ID
    shipped_locat_code          xxinv_mov_req_instr_headers.shipped_locat_code%TYPE,
    -- 出庫元保管場所
    ship_to_locat_id            xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE,
    -- 入庫先ID
    ship_to_locat_code          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE,
    -- 入庫先保管場所
    schedule_ship_date          xxinv_mov_req_instr_headers.schedule_ship_date%TYPE,
    -- 出庫予定日
    schedule_arrival_date       xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE,
    -- 入庫予定日
    freight_charge_class        xxinv_mov_req_instr_headers.freight_charge_class%TYPE,
    -- 運賃区分
    collected_pallet_qty        xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE,
    -- パレット回収枚数
    out_pallet_qty              xxinv_mov_req_instr_headers.out_pallet_qty%TYPE,
    -- パレット枚数(出)
    in_pallet_qty               xxinv_mov_req_instr_headers.in_pallet_qty%TYPE,
    -- パレット枚数(入)
    no_cont_freight_class       xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE,
    -- 契約外運賃区分
    delivery_no                 xxinv_mov_req_instr_headers.delivery_no%TYPE,
    -- 配送No
    description                 xxinv_mov_req_instr_headers.description%TYPE,
    -- 摘要
    loading_efficiency_weight   xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE,
    -- 積載率(重量)
    loading_efficiency_capacity xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE,
    -- 積載率(容積)
    organization_id             xxinv_mov_req_instr_headers.organization_id%TYPE,
    -- 組織ID
    career_id                   xxinv_mov_req_instr_headers.career_id%TYPE,
    -- 運送業者ID
    freight_carrier_code        xxinv_mov_req_instr_headers.freight_carrier_code%TYPE,
    -- 運送業者
    shipping_method_code        xxinv_mov_req_instr_headers.shipping_method_code%TYPE,
    -- 配送区分
    actual_career_id            xxinv_mov_req_instr_headers.actual_career_id%TYPE,
    -- 運送業者ID_実績
    actual_freight_carrier_code xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE,
    -- 運送業者_実績
    actual_shipping_method_code xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE,
    -- 配送区分_実績
    arrival_time_from           xxinv_mov_req_instr_headers.arrival_time_from%TYPE,
    -- 着荷時間FROM
    arrival_time_to             xxinv_mov_req_instr_headers.arrival_time_to%TYPE,
    -- 着荷時間TO
    slip_number                 xxinv_mov_req_instr_headers.slip_number%TYPE,
    -- 送り状No
    sum_quantity                xxinv_mov_req_instr_headers.sum_quantity%TYPE,
    -- 合計数量
    small_quantity              xxinv_mov_req_instr_headers.small_quantity%TYPE,
    -- 小口個数
    label_quantity              xxinv_mov_req_instr_headers.label_quantity%TYPE,
    -- ラベル枚数
    based_weight                xxinv_mov_req_instr_headers.based_weight%TYPE,
    -- 基本重量
    based_capacity              xxinv_mov_req_instr_headers.based_capacity%TYPE,
    -- 基本容積
    sum_weight                  xxinv_mov_req_instr_headers.sum_weight%TYPE,
    -- 混載重量合計
    sum_capacity                xxinv_mov_req_instr_headers.sum_capacity%TYPE,
    -- 混載容積合計
    sum_pallet_weight           xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE,
    -- 合計パレット重量
    pallet_sum_quantity         xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE,
    -- パレット合計枚数
    mixed_ratio                 xxinv_mov_req_instr_headers.mixed_ratio%TYPE,
    -- 混載率
    weight_capacity_class       xxinv_mov_req_instr_headers.weight_capacity_class%TYPE,
    -- 重量容積区分
    actual_ship_date            xxinv_mov_req_instr_headers.actual_ship_date%TYPE,
    -- 出庫実績日
    actual_arrival_date         xxinv_mov_req_instr_headers.actual_arrival_date%TYPE,
    -- 入庫実績日
    mixed_sign                  xxinv_mov_req_instr_headers.mixed_sign%TYPE,
    -- 混載記号
    batch_no                    xxinv_mov_req_instr_headers.batch_no%TYPE,
    -- 手配No
    item_class                  xxinv_mov_req_instr_headers.item_class%TYPE,
    -- 商品区分
    product_flg                 xxinv_mov_req_instr_headers.product_flg%TYPE,
    -- 製品識別区分
    no_instr_actual_class       xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE,
    -- 指示なし実績区分
    comp_actual_flg             xxinv_mov_req_instr_headers.comp_actual_flg%TYPE,
    -- 実績計上済フラグ
    correct_actual_flg          xxinv_mov_req_instr_headers.correct_actual_flg%TYPE,
    -- 実績訂正フラグ
    prev_notif_status           xxinv_mov_req_instr_headers.prev_notif_status%TYPE,
    -- 前回通知ステータス
    notif_date                  xxinv_mov_req_instr_headers.notif_date%TYPE,
    -- 確定通知実績日時
    prev_delivery_no            xxinv_mov_req_instr_headers.prev_delivery_no%TYPE,
    -- 前回配送No
    new_modify_flg              xxinv_mov_req_instr_headers.new_modify_flg%TYPE,
    -- 新規修正フラグ
    screen_update_by            xxinv_mov_req_instr_headers.screen_update_by%TYPE,
    -- 画面更新者
    screen_update_date          xxinv_mov_req_instr_headers.screen_update_date%TYPE,
    -- 画面更新日時
    created_by                  xxinv_mov_req_instr_headers.created_by%TYPE,
    -- 作成者
    creation_date               xxinv_mov_req_instr_headers.creation_date%TYPE,
    -- 作成日
    last_updated_by             xxinv_mov_req_instr_headers.last_updated_by%TYPE,
    -- 最終更新者
    last_update_date            xxinv_mov_req_instr_headers.last_update_date%TYPE,
    -- 最終更新日
    last_update_login           xxinv_mov_req_instr_headers.last_update_login%TYPE,
    -- 最終更新ログイン
    request_id                  xxinv_mov_req_instr_headers.request_id%TYPE,
    -- 要求ID
    program_application_id      xxinv_mov_req_instr_headers.program_application_id%TYPE,
    -- コンカレントプログラムアプリケーションID
    program_id                  xxinv_mov_req_instr_headers.program_id%TYPE,
    -- コンカレントプログラムID
    program_update_date         xxinv_mov_req_instr_headers.program_update_date%TYPE,
    -- プログラム更新日
    not_insert_flg              VARCHAR2(1)
  );
  TYPE move_header_tbl IS TABLE OF move_header_rec INDEX BY PLS_INTEGER;
  gr_move_header_tbl  move_header_tbl;
--
  -- 移動依頼/指示ヘッダのデータ(FORALLでのINSERT用)
  TYPE h_mov_hdr_id
    IS TABLE OF xxinv_mov_req_instr_headers.mov_hdr_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 移動ヘッダID
  TYPE h_mov_num
    IS TABLE OF xxinv_mov_req_instr_headers.mov_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- 移動番号
  TYPE h_mov_type
    IS TABLE OF xxinv_mov_req_instr_headers.mov_type%TYPE
    INDEX BY BINARY_INTEGER;
    -- 移動タイプ
  TYPE h_entered_date
    IS TABLE OF xxinv_mov_req_instr_headers.entered_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入力日
  TYPE h_instruction_post_code
    IS TABLE OF xxinv_mov_req_instr_headers.instruction_post_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 指示部署
  TYPE h_status
    IS TABLE OF xxinv_mov_req_instr_headers.status%TYPE
    INDEX BY BINARY_INTEGER;
    -- ステータス
  TYPE h_notif_status
    IS TABLE OF xxinv_mov_req_instr_headers.notif_status%TYPE
    INDEX BY BINARY_INTEGER;
    -- 通知ステータス
  TYPE h_shipped_locat_id
    IS TABLE OF xxinv_mov_req_instr_headers.shipped_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 出庫元ID
  TYPE h_shipped_locat_code
    IS TABLE OF xxinv_mov_req_instr_headers.shipped_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 出庫元保管場所
  TYPE h_ship_to_locat_id
    IS TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入庫先ID
  TYPE h_ship_to_locat_code
    IS TABLE OF xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入庫先保管場所
  TYPE h_schedule_ship_date
    IS TABLE OF xxinv_mov_req_instr_headers.schedule_ship_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 出庫予定日
  TYPE h_schedule_arrival_date
    IS TABLE OF xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入庫予定日
  TYPE h_freight_charge_class
    IS TABLE OF xxinv_mov_req_instr_headers.freight_charge_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 運賃区分
  TYPE h_collected_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット回収枚数
  TYPE h_out_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.out_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット枚数(出)
  TYPE h_in_pallet_qty
    IS TABLE OF xxinv_mov_req_instr_headers.in_pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット枚数(入)
  TYPE h_no_cont_freight_class
    IS TABLE OF xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 契約外運賃区分
  TYPE h_delivery_no
    IS TABLE OF xxinv_mov_req_instr_headers.delivery_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- 配送No
  TYPE h_description
    IS TABLE OF xxinv_mov_req_instr_headers.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- 摘要
  TYPE h_loading_efficiency_weight
    IS TABLE OF xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- 積載率(重量)
  TYPE h_loading_efficiency_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 積載率(容積)
  TYPE h_organization_id
    IS TABLE OF xxinv_mov_req_instr_headers.organization_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 組織ID
  TYPE h_career_id
    IS TABLE OF xxinv_mov_req_instr_headers.career_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 運送業者ID
  TYPE h_freight_carrier_code
    IS TABLE OF xxinv_mov_req_instr_headers.freight_carrier_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 運送業者
  TYPE h_shipping_method_code
    IS TABLE OF xxinv_mov_req_instr_headers.shipping_method_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 配送区分
  TYPE h_actual_career_id
    IS TABLE OF xxinv_mov_req_instr_headers.actual_career_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 運送業者ID_実績
  TYPE h_actual_freight_carrier_code
    IS TABLE OF xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 運送業者_実績
  TYPE h_actual_shipping_method_code
    IS TABLE OF xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 配送区分_実績
  TYPE h_arrival_time_from
    IS TABLE OF xxinv_mov_req_instr_headers.arrival_time_from%TYPE
    INDEX BY BINARY_INTEGER;
    -- 着荷時間FROM
  TYPE h_arrival_time_to
    IS TABLE OF xxinv_mov_req_instr_headers.arrival_time_to%TYPE
    INDEX BY BINARY_INTEGER;
    -- 着荷時間TO
  TYPE h_slip_number
    IS TABLE OF xxinv_mov_req_instr_headers.slip_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- 送り状No
  TYPE h_sum_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.sum_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 合計数量
  TYPE h_small_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.small_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 小口個数
  TYPE h_label_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.label_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ラベル枚数
  TYPE h_based_weight
    IS TABLE OF xxinv_mov_req_instr_headers.based_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- 基本重量
  TYPE h_based_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.based_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 基本容積
  TYPE h_sum_weight
    IS TABLE OF xxinv_mov_req_instr_headers.sum_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- 混載重量合計
  TYPE h_sum_capacity
    IS TABLE OF xxinv_mov_req_instr_headers.sum_capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 混載容積合計
  TYPE h_sum_pallet_weight
    IS TABLE OF xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- 合計パレット重量
  TYPE h_pallet_sum_quantity
    IS TABLE OF xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット合計枚数
  TYPE h_mixed_ratio
    IS TABLE OF xxinv_mov_req_instr_headers.mixed_ratio%TYPE
    INDEX BY BINARY_INTEGER;
    -- 混載率
  TYPE h_weight_capacity_class
    IS TABLE OF xxinv_mov_req_instr_headers.weight_capacity_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 重量容積区分
  TYPE h_actual_ship_date
    IS TABLE OF xxinv_mov_req_instr_headers.actual_ship_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 出庫実績日
  TYPE h_actual_arrival_date
    IS TABLE OF xxinv_mov_req_instr_headers.actual_arrival_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入庫実績日
  TYPE h_mixed_sign
    IS TABLE OF xxinv_mov_req_instr_headers.mixed_sign%TYPE
    INDEX BY BINARY_INTEGER;
    -- 混載記号
  TYPE h_batch_no
    IS TABLE OF xxinv_mov_req_instr_headers.batch_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- 手配No
  TYPE h_item_class
    IS TABLE OF xxinv_mov_req_instr_headers.item_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 商品区分
  TYPE h_product_flg
    IS TABLE OF xxinv_mov_req_instr_headers.product_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 製品識別区分
  TYPE h_no_instr_actual_class
    IS TABLE OF xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 指示なし実績区分
  TYPE h_comp_actual_flg
    IS TABLE OF xxinv_mov_req_instr_headers.comp_actual_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 実績計上済フラグ
  TYPE h_correct_actual_flg
    IS TABLE OF xxinv_mov_req_instr_headers.correct_actual_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 実績訂正フラグ
  TYPE h_prev_notif_status
    IS TABLE OF xxinv_mov_req_instr_headers.prev_notif_status%TYPE
    INDEX BY BINARY_INTEGER;
    -- 前回通知ステータス
  TYPE h_notif_date
    IS TABLE OF xxinv_mov_req_instr_headers.notif_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 確定通知実績日時
  TYPE h_prev_delivery_no
    IS TABLE OF xxinv_mov_req_instr_headers.prev_delivery_no%TYPE
    INDEX BY BINARY_INTEGER;
    -- 前回配送No
  TYPE h_new_modify_flg
    IS TABLE OF xxinv_mov_req_instr_headers.new_modify_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 新規修正フラグ
  TYPE h_screen_update_by
    IS TABLE OF xxinv_mov_req_instr_headers.screen_update_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 画面更新者
  TYPE h_screen_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.screen_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 画面更新日時
  TYPE h_created_by
    IS TABLE OF xxinv_mov_req_instr_headers.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成者
  TYPE h_creation_date
    IS TABLE OF xxinv_mov_req_instr_headers.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成日
  TYPE h_last_updated_by
    IS TABLE OF xxinv_mov_req_instr_headers.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新者
  TYPE h_last_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新日
  TYPE h_last_update_login
    IS TABLE OF xxinv_mov_req_instr_headers.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新ログイン
  TYPE h_request_id
    IS TABLE OF xxinv_mov_req_instr_headers.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 要求ID
  TYPE h_program_application_id
    IS TABLE OF xxinv_mov_req_instr_headers.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- コンカレントプログラムアプリケーションID
  TYPE h_program_id
    IS TABLE OF xxinv_mov_req_instr_headers.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- コンカレントプログラムID
  TYPE h_program_update_date
    IS TABLE OF xxinv_mov_req_instr_headers.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラム更新日
--
  -- 移動依頼/指示ヘッダのデータ(FORALLでのINSERT用)
  gt_h_mov_hdr_id                  h_mov_hdr_id;                  -- 移動ヘッダID
  gt_h_mov_num                     h_mov_num;                     -- 移動番号
  gt_h_mov_type                    h_mov_type;                    -- 移動タイプ
  gt_h_entered_date                h_entered_date;                -- 入力日
  gt_h_instruction_post_code       h_instruction_post_code;       -- 指示部署
  gt_h_status                      h_status;                      -- ステータス
  gt_h_notif_status                h_notif_status;                -- 通知ステータス
  gt_h_shipped_locat_id            h_shipped_locat_id;            -- 出庫元ID
  gt_h_shipped_locat_code          h_shipped_locat_code;          -- 出庫元保管場所
  gt_h_ship_to_locat_id            h_ship_to_locat_id;            -- 入庫先ID
  gt_h_ship_to_locat_code          h_ship_to_locat_code;          -- 入庫先保管場所
  gt_h_schedule_ship_date          h_schedule_ship_date;          -- 出庫予定日
  gt_h_schedule_arrival_date       h_schedule_arrival_date;       -- 入庫予定日
  gt_h_freight_charge_class        h_freight_charge_class;        -- 運賃区分
  gt_h_collected_pallet_qty        h_collected_pallet_qty;        -- パレット回収枚数
  gt_h_out_pallet_qty              h_out_pallet_qty;              -- パレット枚数(出)
  gt_h_in_pallet_qty               h_in_pallet_qty;               -- パレット枚数(入)
  gt_h_no_cont_freight_class       h_no_cont_freight_class;       -- 契約外運賃区分
  gt_h_delivery_no                 h_delivery_no;                 -- 配送No
  gt_h_description                 h_description;                 -- 摘要
  gt_h_loading_efficiency_weight   h_loading_efficiency_weight;   -- 積載率(重量)
  gt_h_loading_efficiency_capa     h_loading_efficiency_capacity; -- 積載率(容積)
  gt_h_organization_id             h_organization_id;             -- 組織ID
  gt_h_career_id                   h_career_id;                   -- 運送業者ID
  gt_h_freight_carrier_code        h_freight_carrier_code;        -- 運送業者
  gt_h_shipping_method_code        h_shipping_method_code;        -- 配送区分
  gt_h_actual_career_id            h_actual_career_id;            -- 運送業者ID_実績
  gt_h_actual_freight_carrier_cd   h_actual_freight_carrier_code; -- 運送業者_実績
  gt_h_actual_shipping_method_cd   h_actual_shipping_method_code; -- 配送区分_実績
  gt_h_arrival_time_from           h_arrival_time_from;           -- 着荷時間FROM
  gt_h_arrival_time_to             h_arrival_time_to;             -- 着荷時間TO
  gt_h_slip_number                 h_slip_number;                 -- 送り状No
  gt_h_sum_quantity                h_sum_quantity;                -- 合計数量
  gt_h_small_quantity              h_small_quantity;              -- 小口個数
  gt_h_label_quantity              h_label_quantity;              -- ラベル枚数
  gt_h_based_weight                h_based_weight;                -- 基本重量
  gt_h_based_capacity              h_based_capacity;              -- 基本容積
  gt_h_sum_weight                  h_sum_weight;                  -- 混載重量合計
  gt_h_sum_capacity                h_sum_capacity;                -- 混載容積合計
  gt_h_sum_pallet_weight           h_sum_pallet_weight;           -- 合計パレット重量
  gt_h_pallet_sum_quantity         h_pallet_sum_quantity;         -- パレット合計枚数
  gt_h_mixed_ratio                 h_mixed_ratio;                 -- 混載率
  gt_h_weight_capacity_class       h_weight_capacity_class;       -- 重量容積区分
  gt_h_actual_ship_date            h_actual_ship_date;            -- 出庫実績日
  gt_h_actual_arrival_date         h_actual_arrival_date;         -- 入庫実績日
  gt_h_mixed_sign                  h_mixed_sign;                  -- 混載記号
  gt_h_batch_no                    h_batch_no;                    -- 手配No
  gt_h_item_class                  h_item_class;                  -- 商品区分
  gt_h_product_flg                 h_product_flg;                 -- 製品識別区分
  gt_h_no_instr_actual_class       h_no_instr_actual_class;       -- 指示なし実績区分
  gt_h_comp_actual_flg             h_comp_actual_flg;             -- 実績計上済フラグ
  gt_h_correct_actual_flg          h_correct_actual_flg;          -- 実績訂正フラグ
  gt_h_prev_notif_status           h_prev_notif_status;           -- 前回通知ステータス
  gt_h_notif_date                  h_notif_date;                  -- 確定通知実績日時
  gt_h_prev_delivery_no            h_prev_delivery_no;            -- 前回配送No
  gt_h_new_modify_flg              h_new_modify_flg;              -- 新規修正フラグ
  gt_h_screen_update_by            h_screen_update_by;            -- 画面更新者
  gt_h_screen_update_date          h_screen_update_date;          -- 画面更新日時
  gt_h_created_by                  h_created_by;                  -- 作成者
  gt_h_creation_date               h_creation_date;               -- 作成日
  gt_h_last_updated_by             h_last_updated_by;             -- 最終更新者
  gt_h_last_update_date            h_last_update_date;            -- 最終更新日
  gt_h_last_update_login           h_last_update_login;           -- 最終更新ログイン
  gt_h_request_id                  h_request_id;                  -- 要求ID
  gt_h_program_application_id      h_program_application_id;
                                                  -- コンカレントプログラムアプリケーションID
  gt_h_program_id                  h_program_id;                  -- コンカレントプログラムID
  gt_h_program_update_date         h_program_update_date;         -- プログラム更新日
--
  -- C-10 移動依頼/指示明細のデータを格納するレコード
  TYPE move_lines_rec IS RECORD(
    mov_line_id                xxinv_mov_req_instr_lines.mov_line_id%TYPE,
    -- 移動明細ID
    mov_hdr_id                 xxinv_mov_req_instr_lines.mov_hdr_id%TYPE,
    -- 移動ヘッダID
    line_number                xxinv_mov_req_instr_lines.line_number%TYPE,
    -- 明細番号
    organization_id            xxinv_mov_req_instr_lines.organization_id%TYPE,
    -- 組織ID
    item_id                    xxinv_mov_req_instr_lines.item_id%TYPE,
    -- OPM品目ID
    item_code                  xxinv_mov_req_instr_lines.item_code%TYPE,
    -- 品目
    request_qty                xxinv_mov_req_instr_lines.request_qty%TYPE,
    -- 依頼数量
    pallet_quantity            xxinv_mov_req_instr_lines.pallet_quantity%TYPE,
    -- パレット数
    layer_quantity             xxinv_mov_req_instr_lines.layer_quantity%TYPE,
    -- 段数
    case_quantity              xxinv_mov_req_instr_lines.case_quantity%TYPE,
    -- ケース数
    instruct_qty               xxinv_mov_req_instr_lines.instruct_qty%TYPE,
    -- 指示数量
    reserved_quantity          xxinv_mov_req_instr_lines.reserved_quantity%TYPE,
    -- 引当数
    uom_code                   xxinv_mov_req_instr_lines.uom_code%TYPE,
    -- 単位
    designated_production_date xxinv_mov_req_instr_lines.designated_production_date%TYPE,
    -- 指定製造日
    pallet_qty                 xxinv_mov_req_instr_lines.pallet_qty%TYPE,
    -- パレット枚数
    move_num                   xxinv_mov_req_instr_lines.move_num%TYPE,
    -- 参照移動番号
    po_num                     xxinv_mov_req_instr_lines.po_num%TYPE,
    -- 参照発注番号
    first_instruct_qty         xxinv_mov_req_instr_lines.first_instruct_qty%TYPE,
    -- 初回指示数量
    shipped_quantity           xxinv_mov_req_instr_lines.shipped_quantity%TYPE,
    -- 出庫実績数量
    ship_to_quantity           xxinv_mov_req_instr_lines.ship_to_quantity%TYPE,
    -- 入庫実績数量
    weight                     xxinv_mov_req_instr_lines.weight%TYPE,
    -- 重量
    capacity                   xxinv_mov_req_instr_lines.capacity%TYPE,
    -- 容積
    pallet_weight              xxinv_mov_req_instr_lines.pallet_weight%TYPE,
    -- パレット重量
    automanual_reserve_class   xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE,
    -- 自動手動引当区分
    delete_flg                 xxinv_mov_req_instr_lines.delete_flg%TYPE,
    -- 取消フラグ
    warning_date               xxinv_mov_req_instr_lines.warning_date%TYPE,
    -- 警告日付
    warning_class              xxinv_mov_req_instr_lines.warning_class%TYPE,
    -- 警告区分
    created_by                 xxinv_mov_req_instr_lines.created_by%TYPE,
    -- 作成者
    creation_date              xxinv_mov_req_instr_lines.creation_date%TYPE,
    -- 作成日
    last_updated_by            xxinv_mov_req_instr_lines.last_updated_by%TYPE,
    -- 最終更新者
    last_update_date           xxinv_mov_req_instr_lines.last_update_date%TYPE,
    -- 最終更新日
    last_update_login          xxinv_mov_req_instr_lines.last_update_login%TYPE,
    -- 最終更新ログイン
    request_id                 xxinv_mov_req_instr_lines.request_id%TYPE,
    -- 要求ID
    program_application_id     xxinv_mov_req_instr_lines.program_application_id%TYPE,
    -- コンカレントプログラムアプリケーションID
    program_id                 xxinv_mov_req_instr_lines.program_id%TYPE,
    -- コンカレントプログラムID
    program_update_date        xxinv_mov_req_instr_lines.program_update_date%TYPE
    -- プログラム更新日
  );
  TYPE move_lines_tbl IS TABLE OF move_lines_rec INDEX BY PLS_INTEGER;
  gr_move_lines_tbl  move_lines_tbl;
--
  -- 移動依頼/指示明細のデータ(FORALLでのINSERT用)
    TYPE m_mov_line_id
      IS TABLE OF xxinv_mov_req_instr_lines.mov_line_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 移動明細ID
    TYPE m_mov_hdr_id
      IS TABLE OF xxinv_mov_req_instr_lines.mov_hdr_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 移動ヘッダID
    TYPE m_line_number
      IS TABLE OF xxinv_mov_req_instr_lines.line_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- 明細番号
    TYPE m_organization_id
      IS TABLE OF xxinv_mov_req_instr_lines.organization_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 組織ID
    TYPE m_item_id
      IS TABLE OF xxinv_mov_req_instr_lines.item_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- OPM品目ID
    TYPE m_item_code
      IS TABLE OF xxinv_mov_req_instr_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 品目
    TYPE m_request_qty
      IS TABLE OF xxinv_mov_req_instr_lines.request_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼数量
    TYPE m_pallet_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット数
    TYPE m_layer_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.layer_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 段数
    TYPE m_case_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.case_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- ケース数
    TYPE m_instruct_qty
      IS TABLE OF xxinv_mov_req_instr_lines.instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- 指示数量
    TYPE m_reserved_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.reserved_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 引当数
    TYPE m_uom_code
      IS TABLE OF xxinv_mov_req_instr_lines.uom_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 単位
    TYPE m_designated_production_date
      IS TABLE OF xxinv_mov_req_instr_lines.designated_production_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 指定製造日
    TYPE m_pallet_qty
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット枚数
    TYPE m_move_num
      IS TABLE OF xxinv_mov_req_instr_lines.move_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- 参照移動番号
    TYPE m_po_num
      IS TABLE OF xxinv_mov_req_instr_lines.po_num%TYPE
    INDEX BY BINARY_INTEGER;
    -- 参照発注番号
    TYPE m_first_instruct_qty
      IS TABLE OF xxinv_mov_req_instr_lines.first_instruct_qty%TYPE
    INDEX BY BINARY_INTEGER;
    -- 初回指示数量
    TYPE m_shipped_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.shipped_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 出庫実績数量
    TYPE m_ship_to_quantity
      IS TABLE OF xxinv_mov_req_instr_lines.ship_to_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 入庫実績数量
    TYPE m_weight
      IS TABLE OF xxinv_mov_req_instr_lines.weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- 重量
    TYPE m_capacity
      IS TABLE OF xxinv_mov_req_instr_lines.capacity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 容積
    TYPE m_pallet_weight
      IS TABLE OF xxinv_mov_req_instr_lines.pallet_weight%TYPE
    INDEX BY BINARY_INTEGER;
    -- パレット重量
    TYPE m_automanual_reserve_class
      IS TABLE OF xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 自動手動引当区分
    TYPE m_delete_flg
      IS TABLE OF xxinv_mov_req_instr_lines.delete_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 取消フラグ
    TYPE m_warning_date
      IS TABLE OF xxinv_mov_req_instr_lines.warning_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 警告日付
    TYPE m_warning_class
      IS TABLE OF xxinv_mov_req_instr_lines.warning_class%TYPE
    INDEX BY BINARY_INTEGER;
    -- 警告区分
    TYPE m_created_by
      IS TABLE OF xxinv_mov_req_instr_lines.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成者
    TYPE m_creation_date
      IS TABLE OF xxinv_mov_req_instr_lines.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成日
    TYPE m_last_updated_by
      IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新者
    TYPE m_last_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新日
    TYPE m_last_update_login
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新ログイン
    TYPE m_request_id
      IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 要求ID
    TYPE m_program_application_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- コンカレントプログラムアプリケーションID
    TYPE m_program_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- コンカレントプログラムID
    TYPE m_program_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラム更新日
--
  -- 移動依頼/指示明細のデータ(FORALLでのINSERT用)
    gt_m_mov_line_id                 m_mov_line_id;                -- 移動明細ID
    gt_m_mov_hdr_id                  m_mov_hdr_id;                 -- 移動ヘッダID
    gt_m_line_number                 m_line_number;                -- 明細番号
    gt_m_organization_id             m_organization_id;            -- 組織ID
    gt_m_item_id                     m_item_id;                    -- OPM品目ID
    gt_m_item_code                   m_item_code;                  -- 品目
    gt_m_request_qty                 m_request_qty;                -- 依頼数量
    gt_m_pallet_quantity             m_pallet_quantity;            -- パレット数
    gt_m_layer_quantity              m_layer_quantity;             -- 段数
    gt_m_case_quantity               m_case_quantity;              -- ケース数
    gt_m_instruct_qty                m_instruct_qty;               -- 指示数量
    gt_m_reserved_quantity           m_reserved_quantity;          -- 引当数
    gt_m_uom_code                    m_uom_code;                   -- 単位
    gt_m_designated_pdt_date         m_designated_production_date; -- 指定製造日
    gt_m_pallet_qty                  m_pallet_qty;                 -- パレット枚数
    gt_m_move_num                    m_move_num;                   -- 参照移動番号
    gt_m_po_num                      m_po_num;                     -- 参照発注番号
    gt_m_first_instruct_qty          m_first_instruct_qty;         -- 初回指示数量
    gt_m_shipped_quantity            m_shipped_quantity;           -- 出庫実績数量
    gt_m_ship_to_quantity            m_ship_to_quantity;           -- 入庫実績数量
    gt_m_weight                      m_weight;                     -- 重量
    gt_m_capacity                    m_capacity;                   -- 容積
    gt_m_pallet_weight               m_pallet_weight;              -- パレット重量
    gt_m_automanual_reserve_class    m_automanual_reserve_class;   -- 自動手動引当区分
    gt_m_delete_flg                  m_delete_flg;                 -- 取消フラグ
    gt_m_warning_date                m_warning_date;               -- 警告日付
    gt_m_warning_class               m_warning_class;              -- 警告区分
    gt_m_created_by                  m_created_by;                 -- 作成者
    gt_m_creation_date               m_creation_date;              -- 作成日
    gt_m_last_updated_by             m_last_updated_by;            -- 最終更新者
    gt_m_last_update_date            m_last_update_date;           -- 最終更新日
    gt_m_last_update_login           m_last_update_login;          -- 最終更新ログイン
    gt_m_request_id                  m_request_id;                 -- 要求ID
    gt_m_program_application_id      m_program_application_id;
                                                     -- コンカレントプログラムアプリケーションID
    gt_m_program_id                  m_program_id;                 -- コンカレントプログラムID
    gt_m_program_update_date         m_program_update_date;        -- プログラム更新日
--
  -- C-11 発注依頼ヘッダのデータを格納するレコード
  TYPE requisition_header_rec IS RECORD(
    requisition_header_id         xxpo_requisition_headers.requisition_header_id%TYPE,
    -- 発注依頼ヘッダID
    po_header_number              xxpo_requisition_headers.po_header_number%TYPE,
    -- 発注番号
    status                        xxpo_requisition_headers.status%TYPE,
    -- ステータス
    vendor_id                     xxpo_requisition_headers.vendor_id%TYPE,
    -- 仕入先ID
    vendor_code                   xxpo_requisition_headers.vendor_code%TYPE,
    -- 仕入先コード
    vendor_site_id                xxpo_requisition_headers.vendor_site_id%TYPE,
    -- 仕入先サイトID
    promised_date                 xxpo_requisition_headers.promised_date%TYPE,
    -- 納入日
    location_id                   xxpo_requisition_headers.location_id%TYPE,
    -- 納入先ID
    location_code                 xxpo_requisition_headers.location_code%TYPE,
    -- 納入先コード
    drop_ship_type                xxpo_requisition_headers.drop_ship_type%TYPE,
    -- 直送区分
    delivery_code                 xxpo_requisition_headers.delivery_code%TYPE,
    -- 配送先コード
    requested_by_code             xxpo_requisition_headers.requested_by_code%TYPE,
    -- 依頼者コード
    requested_dept_code           xxpo_requisition_headers.requested_dept_code%TYPE,
    -- 依頼者部署コード
    requested_to_department_code  xxpo_requisition_headers.requested_to_department_code%TYPE,
    -- 依頼先部署コード
    description                   xxpo_requisition_headers.description%TYPE,
    -- 摘要
    change_flag                   xxpo_requisition_headers.change_flag%TYPE,
    -- 変更フラグ
    created_by                    xxpo_requisition_headers.created_by%TYPE,
    -- 作成者
    creation_date                 xxpo_requisition_headers.creation_date%TYPE,
    -- 作成日
    last_updated_by               xxpo_requisition_headers.last_updated_by%TYPE,
    -- 最終更新者
    last_update_date              xxpo_requisition_headers.last_update_date%TYPE,
    -- 最終更新日
    last_update_login             xxpo_requisition_headers.last_update_login%TYPE,
    -- 最終更新ログイン
    request_id                    xxpo_requisition_headers.request_id%TYPE,
    -- 要求ID
    program_application_id        xxpo_requisition_headers.program_application_id%TYPE,
    -- アプリケーションID
    program_id                    xxpo_requisition_headers.program_id%TYPE,
    -- プログラムID
    program_update_date           xxpo_requisition_headers.program_update_date%TYPE
    -- プログラム更新日
  );
  TYPE requisition_header_tbl IS TABLE OF requisition_header_rec INDEX BY PLS_INTEGER;
  gr_requisition_header_tbl  requisition_header_tbl;
--
  -- 発注依頼ヘッダのデータ(FORALLでのINSERT用)
    TYPE rh_requisition_header_id
      IS TABLE OF xxpo_requisition_headers.requisition_header_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 発注依頼ヘッダID
    TYPE rh_po_header_number
      IS TABLE OF xxpo_requisition_headers.po_header_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- 発注番号
    TYPE rh_status
      IS TABLE OF xxpo_requisition_headers.status%TYPE
    INDEX BY BINARY_INTEGER;
    -- ステータス
    TYPE rh_vendor_id
      IS TABLE OF xxpo_requisition_headers.vendor_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 仕入先ID
    TYPE rh_vendor_code
      IS TABLE OF xxpo_requisition_headers.vendor_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 仕入先コード
    TYPE rh_vendor_site_id
      IS TABLE OF xxpo_requisition_headers.vendor_site_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 仕入先サイトID
    TYPE rh_promised_date
      IS TABLE OF xxpo_requisition_headers.promised_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 納入日
    TYPE rh_location_id
      IS TABLE OF xxpo_requisition_headers.location_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 納入先ID
    TYPE rh_location_code
      IS TABLE OF xxpo_requisition_headers.location_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 納入先コード
    TYPE rh_drop_ship_type
      IS TABLE OF xxpo_requisition_headers.drop_ship_type%TYPE
    INDEX BY BINARY_INTEGER;
    -- 直送区分
    TYPE rh_delivery_code
      IS TABLE OF xxpo_requisition_headers.delivery_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 配送先コード
    TYPE rh_requested_by_code
      IS TABLE OF xxpo_requisition_headers.requested_by_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼者コード
    TYPE rh_requested_dept_code
      IS TABLE OF xxpo_requisition_headers.requested_dept_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼者部署コード
    TYPE rh_requested_to_dpt_code
      IS TABLE OF xxpo_requisition_headers.requested_to_department_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼先部署コード
    TYPE rh_description
      IS TABLE OF xxpo_requisition_headers.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- 摘要
    TYPE rh_change_flag
      IS TABLE OF xxpo_requisition_headers.change_flag%TYPE
    INDEX BY BINARY_INTEGER;
    -- 変更フラグ
    TYPE rh_created_by
      IS TABLE OF xxpo_requisition_headers.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成者
    TYPE rh_creation_date
      IS TABLE OF xxpo_requisition_headers.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成日
    TYPE rh_last_updated_by
      IS TABLE OF xxpo_requisition_headers.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新者
    TYPE rh_last_update_date
      IS TABLE OF xxpo_requisition_headers.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新日
    TYPE rh_last_update_login
      IS TABLE OF xxpo_requisition_headers.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新ログイン
    TYPE rh_request_id
      IS TABLE OF xxpo_requisition_headers.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 要求ID
    TYPE rh_program_application_id
      IS TABLE OF xxpo_requisition_headers.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- アプリケーションID
    TYPE rh_program_id
      IS TABLE OF xxpo_requisition_headers.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラムID
    TYPE rh_program_update_date
      IS TABLE OF xxpo_requisition_headers.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラム更新日
--
  -- 発注依頼ヘッダのデータ(FORALLでのINSERT用)
    gt_rh_requisition_header_id        rh_requisition_header_id;
    -- 発注依頼ヘッダID
    gt_rh_po_header_number             rh_po_header_number;
    -- 発注番号
    gt_rh_status                       rh_status;
    -- ステータス
    gt_rh_vendor_id                    rh_vendor_id;
    -- 仕入先ID
    gt_rh_vendor_code                  rh_vendor_code;
    -- 仕入先コード
    gt_rh_vendor_site_id               rh_vendor_site_id;
    -- 仕入先サイトID
    gt_rh_promised_date                rh_promised_date;
    -- 納入日
    gt_rh_location_id                  rh_location_id;
    -- 納入先ID
    gt_rh_location_code                rh_location_code;
    -- 納入先コード
    gt_rh_drop_ship_type               rh_drop_ship_type;
    -- 直送区分
    gt_rh_delivery_code                rh_delivery_code;
    -- 配送先コード
    gt_rh_requested_by_code            rh_requested_by_code;
    -- 依頼者コード
    gt_rh_requested_dept_code          rh_requested_dept_code;
    -- 依頼者部署コード
    gt_rh_requested_to_dpt_code        rh_requested_to_dpt_code;
    -- 依頼先部署コード
    gt_rh_description                  rh_description;
    -- 摘要
    gt_rh_change_flag                  rh_change_flag;
    -- 変更フラグ
    gt_rh_created_by                   rh_created_by;
    -- 作成者
    gt_rh_creation_date                rh_creation_date;
    -- 作成日
    gt_rh_last_updated_by              rh_last_updated_by;
    -- 最終更新者
    gt_rh_last_update_date             rh_last_update_date;
    -- 最終更新日
    gt_rh_last_update_login            rh_last_update_login;
    -- 最終更新ログイン
    gt_rh_request_id                   rh_request_id;
    -- 要求ID
    gt_rh_program_application_id       rh_program_application_id;
    -- アプリケーションID
    gt_rh_program_id                   rh_program_id;
    -- プログラムID
    gt_rh_program_update_date          rh_program_update_date;
    -- プログラム更新日
--
  -- C-11 発注依頼明細のデータを格納するレコード
  TYPE requisition_lines_rec IS RECORD(
    requisition_line_id           xxpo_requisition_lines.requisition_line_id%TYPE,
    -- 発注依頼明細ID
    requisition_header_id         xxpo_requisition_lines.requisition_header_id%TYPE,
    -- 発注依頼ヘッダID
    requisition_line_number       xxpo_requisition_lines.requisition_line_number%TYPE,
    -- 明細番号
    item_id                       xxpo_requisition_lines.item_id%TYPE,
    -- 品目ID
    item_code                     xxpo_requisition_lines.item_code%TYPE,
    -- 品目コード
    pack_quantity                 xxpo_requisition_lines.pack_quantity%TYPE,
    -- 在庫入数
    requested_quantity            xxpo_requisition_lines.requested_quantity%TYPE,
    -- 依頼数量
    requested_quantity_uom        xxpo_requisition_lines.requested_quantity_uom%TYPE,
    -- 依頼数量単位コード
    requested_date                xxpo_requisition_lines.requested_date%TYPE,
    -- 日付指定
    ordered_quantity              xxpo_requisition_lines.ordered_quantity%TYPE,
    -- 発注数量
    description                   xxpo_requisition_lines.description%TYPE,
    -- 摘要
    cancelled_flg                 xxpo_requisition_lines.cancelled_flg%TYPE,
    -- 取消フラグ
    created_by                    xxpo_requisition_lines.created_by%TYPE,
    -- 作成者
    creation_date                 xxpo_requisition_lines.creation_date%TYPE,
    -- 作成日
    last_updated_by               xxpo_requisition_lines.last_updated_by%TYPE,
    -- 最終更新者
    last_update_date              xxpo_requisition_lines.last_update_date%TYPE,
    -- 最終更新日
    last_update_login             xxpo_requisition_lines.last_update_login%TYPE,
    -- 最終更新ログイン
    request_id                    xxpo_requisition_lines.request_id%TYPE,
    -- 要求ID
    program_application_id        xxpo_requisition_lines.program_application_id%TYPE,
    -- アプリケーションID
    program_id                    xxpo_requisition_lines.program_id%TYPE,
    -- プログラムID
    program_update_date           xxpo_requisition_lines.program_update_date%TYPE
    -- プログラム更新日
  );
  TYPE requisition_lines_tbl IS TABLE OF requisition_lines_rec INDEX BY PLS_INTEGER;
  gr_requisition_lines_tbl  requisition_lines_tbl;
--
  -- 発注依頼明細のデータ(FORALLでのINSERT用)
    TYPE rl_requisition_line_id
      IS TABLE OF xxpo_requisition_lines.requisition_line_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 発注依頼明細ID
    TYPE rl_requisition_header_id
      IS TABLE OF xxpo_requisition_lines.requisition_header_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 発注依頼ヘッダID
    TYPE rl_requisition_line_number
      IS TABLE OF xxpo_requisition_lines.requisition_line_number%TYPE
    INDEX BY BINARY_INTEGER;
    -- 明細番号
    TYPE rl_item_id
      IS TABLE OF xxpo_requisition_lines.item_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 品目ID
    TYPE rl_item_code
      IS TABLE OF xxpo_requisition_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;
    -- 品目コード
    TYPE rl_pack_quantity
      IS TABLE OF xxpo_requisition_lines.pack_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 在庫入数
    TYPE rl_requested_quantity
      IS TABLE OF xxpo_requisition_lines.requested_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼数量
    TYPE rl_requested_quantity_uom
      IS TABLE OF xxpo_requisition_lines.requested_quantity_uom%TYPE
    INDEX BY BINARY_INTEGER;
    -- 依頼数量単位コード
    TYPE rl_requested_date
      IS TABLE OF xxpo_requisition_lines.requested_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 日付指定
    TYPE rl_ordered_quantity
      IS TABLE OF xxpo_requisition_lines.ordered_quantity%TYPE
    INDEX BY BINARY_INTEGER;
    -- 発注数量
    TYPE rl_description
      IS TABLE OF xxpo_requisition_lines.description%TYPE
    INDEX BY BINARY_INTEGER;
    -- 摘要
    TYPE rl_cancelled_flg
      IS TABLE OF xxpo_requisition_lines.cancelled_flg%TYPE
    INDEX BY BINARY_INTEGER;
    -- 取消フラグ
    TYPE rl_created_by
      IS TABLE OF xxpo_requisition_lines.created_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成者
    TYPE rl_creation_date
      IS TABLE OF xxpo_requisition_lines.creation_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 作成日
    TYPE rl_last_updated_by
      IS TABLE OF xxpo_requisition_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新者
    TYPE rl_last_update_date
      IS TABLE OF xxpo_requisition_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新日
    TYPE rl_last_update_login
      IS TABLE OF xxpo_requisition_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;
    -- 最終更新ログイン
    TYPE rl_request_id
      IS TABLE OF xxpo_requisition_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- 要求ID
    TYPE rl_program_application_id
      IS TABLE OF xxpo_requisition_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- アプリケーションID
    TYPE rl_program_id
      IS TABLE OF xxpo_requisition_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラムID
    TYPE rl_program_update_date
      IS TABLE OF xxpo_requisition_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;
    -- プログラム更新日
--
  -- 発注依頼明細のデータ(FORALLでのINSERT用)
    gt_rl_requisition_line_id      rl_requisition_line_id;    -- 発注依頼明細ID
    gt_rl_requisition_header_id    rl_requisition_header_id;  -- 発注依頼ヘッダID
    gt_rl_requisition_line_number  rl_requisition_line_number;-- 明細番号
    gt_rl_item_id                  rl_item_id;                -- 品目ID
    gt_rl_item_code                rl_item_code;              -- 品目コード
    gt_rl_pack_quantity            rl_pack_quantity;          -- 在庫入数
    gt_rl_requested_quantity       rl_requested_quantity;     -- 依頼数量
    gt_rl_requested_quantity_uom   rl_requested_quantity_uom; -- 依頼数量単位コード
    gt_rl_requested_date           rl_requested_date;         -- 日付指定
    gt_rl_ordered_quantity         rl_ordered_quantity;       -- 発注数量
    gt_rl_description              rl_description;            -- 摘要
    gt_rl_cancelled_flg            rl_cancelled_flg;          -- 取消フラグ
    gt_rl_created_by               rl_created_by;             -- 作成者
    gt_rl_creation_date            rl_creation_date;          -- 作成日
    gt_rl_last_updated_by          rl_last_updated_by;        -- 最終更新者
    gt_rl_last_update_date         rl_last_update_date;       -- 最終更新日
    gt_rl_last_update_login        rl_last_update_login;      -- 最終更新ログイン
    gt_rl_request_id               rl_request_id;             -- 要求ID
    gt_rl_program_application_id   rl_program_application_id; -- アプリケーションID
    gt_rl_program_id               rl_program_id;             -- プログラムID
    gt_rl_program_update_date      rl_program_update_date;    -- プログラム更新日
--
  -- C-12 受注明細のデータを格納するレコード
  TYPE order_lines_u_rec IS RECORD(
    request_no               xxwsh_order_lines_all.request_no%TYPE,-- 依頼No（キー）
    shipping_item_code       xxwsh_order_lines_all.shipping_item_code%TYPE, -- 品目コード（キー）
    move_number              xxwsh_order_lines_all.move_number%TYPE,
                                                                   -- 移動No
    po_number                xxwsh_order_lines_all.po_number%TYPE,
                                                                   -- 発注No
    last_updated_by          xxwsh_order_lines_all.last_updated_by%TYPE,
                                                                   -- 最終更新者
    last_update_date         xxwsh_order_lines_all.last_update_date%TYPE,
                                                                   -- 最終更新日
    last_update_login        xxwsh_order_lines_all.last_update_login%TYPE,
                                                                   -- 最終更新ログイン
    request_id               xxwsh_order_lines_all.request_id%TYPE,-- 要求ID
    program_application_id   xxwsh_order_lines_all.program_application_id%TYPE,
                                                                   -- アプリケーションID
    program_id               xxwsh_order_lines_all.program_id%TYPE,-- プログラムID
    program_update_date      xxwsh_order_lines_all.program_update_date%TYPE
                                                                   -- プログラム更新日
  );
  TYPE order_lines_u_tbl IS TABLE OF order_lines_u_rec INDEX BY PLS_INTEGER;
  gr_order_lines_u_tbl  order_lines_u_tbl;
--
  -- 受注明細のデータ(FORALLでのUPDATE用)
    TYPE ol_request_no
      IS TABLE OF xxwsh_order_headers_all.request_no%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 依頼No（キー）
    TYPE ol_shipping_item_code
      IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 品目コード（キー）
    TYPE ol_move_number
      IS TABLE OF xxwsh_order_lines_all.move_number%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 移動No
    TYPE ol_po_number
      IS TABLE OF xxwsh_order_lines_all.po_number%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 発注No
    TYPE ol_last_updated_by
      IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 最終更新者
    TYPE ol_last_update_date
      IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 最終更新日
    TYPE ol_last_update_login
      IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 最終更新ログイン
    TYPE ol_request_id
      IS TABLE OF xxwsh_order_lines_all.request_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- 要求ID
    TYPE ol_program_application_id
      IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- アプリケーションID
    TYPE ol_program_id
      IS TABLE OF xxwsh_order_lines_all.program_id%TYPE
    INDEX BY BINARY_INTEGER;                                      -- プログラムID
    TYPE ol_program_update_date
      IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;                                      -- プログラム更新日
--
  -- 受注明細のデータ(FORALLでのUPDATE用)
    gt_ol_request_no             ol_request_no;                   -- 依頼No（キー）
    gt_ol_shipping_item_code     ol_shipping_item_code;           -- 品目コード（キー）
    gt_ol_move_number            ol_move_number;                  -- 移動No
    gt_ol_po_number              ol_po_number;                    -- 発注No
    gt_ol_last_updated_by        ol_last_updated_by;              -- 最終更新者
    gt_ol_last_update_date       ol_last_update_date;             -- 最終更新日
    gt_ol_last_update_login      ol_last_update_login;            -- 最終更新ログイン
    gt_ol_request_id             ol_request_id;                   -- 要求ID
    gt_ol_program_application_id ol_program_application_id;       -- アプリケーションID
    gt_ol_program_id             ol_program_id;                   -- プログラムID
    gt_ol_program_update_date    ol_program_update_date;          -- プログラム更新日
--
  -- C-13 移動依頼/指示明細データを格納するレコード
  TYPE move_lines_u_rec IS RECORD(
    mov_num                  xxinv_mov_req_instr_headers.mov_num%TYPE,-- 移動番号（キー）
    item_code                xxinv_mov_req_instr_lines.item_code%TYPE, -- 品目コード（キー）
    move_num                 xxinv_mov_req_instr_lines.move_num%TYPE,
                                                                   -- 参照移動番号
    po_num                   xxinv_mov_req_instr_lines.po_num%TYPE,
                                                                   -- 参照発注番号
    last_updated_by          xxinv_mov_req_instr_lines.last_updated_by%TYPE,
                                                                   -- 最終更新者
    last_update_date         xxinv_mov_req_instr_lines.last_update_date%TYPE,
                                                                   -- 最終更新日
    last_update_login        xxinv_mov_req_instr_lines.last_update_login%TYPE,
                                                                   -- 最終更新ログイン
    request_id               xxinv_mov_req_instr_lines.request_id%TYPE,-- 要求ID
    program_application_id   xxinv_mov_req_instr_lines.program_application_id%TYPE,
                                                                   -- アプリケーションID
    program_id               xxinv_mov_req_instr_lines.program_id%TYPE,-- プログラムID
    program_update_date      xxinv_mov_req_instr_lines.program_update_date%TYPE
                                                                   -- プログラム更新日
  );
  TYPE move_lines_u_tbl IS TABLE OF move_lines_u_rec INDEX BY PLS_INTEGER;
  gr_move_lines_u_tbl  move_lines_u_tbl;
--
  -- C-13 移動依頼/指示明細データを格納するレコード
    TYPE ml_mov_num
      IS TABLE OF xxinv_mov_req_instr_headers.mov_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- 移動番号（キー）
    TYPE ml_item_code
      IS TABLE OF xxinv_mov_req_instr_lines.item_code%TYPE
    INDEX BY BINARY_INTEGER;                               -- 品目コード（キー）
    TYPE ml_move_num
      IS TABLE OF xxinv_mov_req_instr_lines.move_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- 参照移動番号
    TYPE ml_po_num
      IS TABLE OF xxinv_mov_req_instr_lines.po_num%TYPE
    INDEX BY BINARY_INTEGER;                               -- 参照発注番号
    TYPE ml_last_updated_by
      IS TABLE OF xxinv_mov_req_instr_lines.last_updated_by%TYPE
    INDEX BY BINARY_INTEGER;                               -- 最終更新者
    TYPE ml_last_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_date%TYPE
    INDEX BY BINARY_INTEGER;                               -- 最終更新日
    TYPE ml_last_update_login
      IS TABLE OF xxinv_mov_req_instr_lines.last_update_login%TYPE
    INDEX BY BINARY_INTEGER;                               -- 最終更新ログイン
    TYPE ml_request_id
      IS TABLE OF xxinv_mov_req_instr_lines.request_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- 要求ID
    TYPE ml_program_application_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_application_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- アプリケーションID
    TYPE ml_program_id
      IS TABLE OF xxinv_mov_req_instr_lines.program_id%TYPE
    INDEX BY BINARY_INTEGER;                               -- プログラムID
    TYPE ml_program_update_date
      IS TABLE OF xxinv_mov_req_instr_lines.program_update_date%TYPE
    INDEX BY BINARY_INTEGER;                               -- プログラム更新日
--
  -- C-13 移動依頼/指示明細データを格納するレコード
    gt_ml_mov_num                 ml_mov_num;                 -- 移動番号（キー）
    gt_ml_item_code               ml_item_code;               -- 品目コード（キー）
    gt_ml_move_num                ml_move_num;                -- 参照移動番号
    gt_ml_po_num                  ml_po_num;                  -- 参照発注番号
    gt_ml_last_updated_by         ml_last_updated_by;         -- 最終更新者
    gt_ml_last_update_date        ml_last_update_date;        -- 最終更新日
    gt_ml_last_update_login       ml_last_update_login;       -- 最終更新ログイン
    gt_ml_request_id              ml_request_id;              -- 要求ID
    gt_ml_program_application_id  ml_program_application_id;  -- アプリケーションID
    gt_ml_program_id              ml_program_id;              -- プログラムID
    gt_ml_program_update_date     ml_program_update_date;     -- プログラム更新日
--
  /**********************************************************************************
   * Function Name    : header_data_save
   * Description      : ヘッダ作成データ保存
   * Return           : 0=存在しない、0>存在する(添字)
   ***********************************************************************************/
  FUNCTION header_data_save(
    in_shori_cnt             IN         NUMBER,     -- 処理カウンタ
    iv_action_type           IN         VARCHAR2)   -- 処理種別
    RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'header_data_save'; --プログラム名
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
--
  BEGIN
--
    -- 処理種別が「出荷」
    IF (iv_action_type = gv_cons_t_deliv) THEN
      gn_stock_rep_origin_m      := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                               -- 在庫補充元
      gv_deliver_from_m          := gr_deliv_data_tbl(in_shori_cnt).deliver_from;
                                                                               -- 出荷元コード
      gv_weight_capacity_class_m := gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                               -- 重量容積区分
      gv_item_class_code_m       := gr_deliv_data_tbl(in_shori_cnt).item_class_code;
                                                                               -- 品目区分
      gv_product_flg_m           := gr_deliv_data_tbl(in_shori_cnt).product_flg;
                                                                               -- 製品識別区分
    ELSE
      gn_stock_rep_origin_m      := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                               -- 在庫補充元
      gv_deliver_from_m          := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;
                                                                               -- 出荷元コード
      gv_weight_capacity_class_m := gr_move_data_tbl(in_shori_cnt).weight_capacity_class;
                                                                               -- 重量容積区分
      gv_item_class_code_m       := gr_move_data_tbl(in_shori_cnt).item_class_code;
                                                                               -- 品目区分
      gv_product_flg_m           := gr_move_data_tbl(in_shori_cnt).product_flg;
                                                                               -- 製品識別区分
    END IF;
--
    RETURN 0;
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
  END header_data_save;
--
   /**********************************************************************************
   * Procedure Name   : check_parameter
   * Description      : C-1  パラメータチェック
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_req_mov_no            IN         VARCHAR2,   -- 依頼/移動No
    iv_deliver_from_id       IN         VARCHAR2,   -- 出庫元
    iv_deliver_type          IN         VARCHAR2,   -- 出庫形態
    iv_object_date_from      IN         VARCHAR2,   -- 対象期間From
    iv_object_date_to        IN         VARCHAR2,   -- 対象期間To
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2,   -- 指示部署指定
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
-- DEBUG
-- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-1)in...' || gv_cons_a_type);
-- DEBUG
    -- 処理種別必須チェック
    IF (iv_action_type IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_a_type)  -- '処理種別'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫元必須チェック
    IF (iv_deliver_from_id IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101  -- 必須入力パラメータエラー
                                                    ,gv_tkn_item       -- トークン'ITEM'
                                                    ,gv_cons_deliv_f_id) -- '出庫'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 処理種別が「出荷」の時のみチェックする
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- 出庫形態必須チェック
      IF (iv_deliver_type IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                      ,gv_tkn_item      -- トークン'ITEM'
                                                      ,gv_cons_deliv_type) -- '出庫形態'
                                                      ,1
                                                      ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 対象期間From必須チェック
    IF (iv_object_date_from IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_obj_d_from) -- '対象期間From'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 出庫日指定必須チェック
    IF (iv_shipped_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_ship_date) -- '出庫日指定'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 着日指定必須チェック
    IF (iv_arrival_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_arvl_date) -- '着日指定'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 指示部署指定必須チェック
    IF (iv_instruction_post_code IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13101 -- 必須入力パラメータエラー
                                                    ,gv_tkn_item      -- トークン'ITEM'
                                                    ,gv_cons_inst_p_code) -- '指示部署指定'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 対象期間Fromの存在チェック
    IF (FND_DATE.STRING_TO_DATE(iv_object_date_from, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- 日付存在チェックエラー
                                                    ,gv_tkn_item          -- トークン'ITEM'
                                                    ,gv_cons_obj_d_from   -- '対象期間From'
                                                    ,gv_tkn_value         -- トークン'VALUE'
                                                    ,iv_object_date_from) -- '対象期間From'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 対象期間Toは入力されていたときのみチェックする
    IF (iv_object_date_to IS NOT NULL) THEN
      -- 対象期間Toの存在チェック
      IF (FND_DATE.STRING_TO_DATE(iv_object_date_to, 'YYYY/MM/DD') IS NULL) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13004 -- 日付存在チェックエラー
                                                      ,gv_tkn_item          -- トークン'ITEM'
                                                      ,gv_cons_obj_d_to     -- '対象期間To'
                                                      ,gv_tkn_value         -- トークン'VALUE'
                                                      ,iv_object_date_to)   -- '対象期間To'
                                                      ,1
                                                      ,5000);
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 出庫日指定の存在チェック
    IF (FND_DATE.STRING_TO_DATE(iv_shipped_date, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- 日付存在チェックエラー
                                                    ,gv_tkn_item          -- トークン'ITEM'
                                                    ,gv_cons_ship_date    -- '出庫日指定'
                                                    ,gv_tkn_value         -- トークン'VALUE'
                                                    ,iv_shipped_date)     -- '出庫日指定'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 着日指定の存在チェック
    IF (FND_DATE.STRING_TO_DATE(iv_arrival_date, 'YYYY/MM/DD') IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                    ,gv_msg_wsh_13004 -- 日付存在チェックエラー
                                                    ,gv_tkn_item          -- トークン'ITEM'
                                                    ,gv_cons_arvl_date    -- '着日指定'
                                                    ,gv_tkn_value         -- トークン'VALUE'
                                                    ,iv_arrival_date)     -- '着日指定'
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 対象期間Toは入力されていたときのみ対象期間FromToの逆転エラーチェックする
    IF (iv_object_date_to IS NOT NULL) THEN
      -- 対象期間FromToの逆転エラーチェック
      IF (iv_object_date_from > iv_object_date_to) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh -- 'XXWSH'
                                                      ,gv_msg_wsh_13005 -- 日付逆転エラー
                                                      ,gv_tkn_item_from     -- トークン'ITEM_FROM'
                                                      ,gv_cons_obj_d_from   -- '対象期間From'
                                                      ,gv_tkn_value_from    -- トークン'VALUE_FROM'
                                                      ,iv_object_date_from  -- '対象期間From'
                                                      ,gv_tkn_item_to       -- トークン'ITEM_TO'
                                                      ,gv_cons_obj_d_to     -- '対象期間To'
                                                      ,gv_tkn_value_to      -- トークン'VALUE_TO'
                                                      ,iv_object_date_to)   -- '対象期間To'
                                                      ,1
                                                      ,5000);
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-1)iv_object_date_from = ' || iv_object_date_from);
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-1)iv_object_date_to = ' || iv_object_date_to);
-- DEBUG
        -- エラーリターン＆処理中止
        RAISE global_api_expt;
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
--
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : C-2  プロファイル取得
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- プログラム名
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
    lv_organization_id  VARCHAR2(15);   -- プロファイル(マスタ組織ID)
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
    -- ユーザプロファイルの取得
    lv_organization_id := SUBSTRB(FND_PROFILE.VALUE(gv_cons_m_org_id), 1,15);
--
    -- プロファイルが取得できない場合はエラー
    IF (lv_organization_id IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_wsh_12101     -- プロファイル取得エラー
                                                    ,gv_tkn_prof_name     -- トークン'PROF_NAME'
                                                    ,gv_cons_m_org_id_tkn) -- XXCMN:マスタ組織ID
                                                    ,1
                                                    ,5000);
      -- エラーリターン＆処理中止
      RAISE global_api_expt;
    END IF;
--
    -- 数値型に変換(変換できない場合は例外処理へ＝エラー）
    gn_organization_id := TO_NUMBER(lv_organization_id);
--
  EXCEPTION
    --*** 数値型に変換できなかった場合=TO_NUMBER() ***
    WHEN INVALID_NUMBER THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh   -- 'XXWSH'
                                                    ,gv_msg_wsh_12101  -- プロファイル取得エラー
                                                    ,gv_tkn_prof_name  -- トークン'PROF_NAME'
                                                    ,gv_cons_m_org_id_tkn) -- XXCMN:マスタ組織ID
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# 任意 #
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
   * Procedure Name   : purge_table
   * Description      : C-3  パージ処理
   ***********************************************************************************/
  PROCEDURE purge_table(
    iv_action_type        IN         VARCHAR2,     -- 処理種別
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_table'; -- プログラム名
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
    lb_retcode  BOOLEAN;
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
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)in.....');
-- DEBUG
    -- 処理種別で処理対象テーブルが異なる
    -- 処理種別が「出荷依頼」の場合
    IF (iv_action_type = gv_cons_t_deliv) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)処理種別が「出荷依頼」');
-- DEBUG
      -- 出荷在庫補充元中間テーブルをロックする
      lb_retcode := xxcmn_common_pkg.get_tbl_lock(gv_cons_schema_wsh, gv_cons_dlv_tmp_tbl);
      -- ロックできなかった場合
      IF (lb_retcode = FALSE) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)get_tbl_lock lb_retcode = FALSE');
-- DEBUG
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13103     -- テーブルロックエラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_dlv_tmp_jp) 
                                                                      -- 出荷在庫補充元中間テーブル
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)get_tbl_lock lb_retcode = TRUE');
-- DEBUG
      -- 全テーブルデータを削除する
      lb_retcode := xxcmn_common_pkg.del_all_data(gv_cons_schema_wsh, gv_cons_dlv_tmp_tbl);
      -- データの削除に失敗した場合
      IF (lb_retcode = FALSE) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)del_all_data lb_retcode = FALSE');
-- DEBUG
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13006 -- テーブルデータ削除エラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_dlv_tmp_jp) 
                                                                      -- 出荷在庫補充元中間テーブル
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-3)del_all_data lb_retcode = TRUE');
-- DEBUG
    -- 処理種別が「移動指示」の場合
    ELSE
      -- 移動在庫補充元中間テーブルをロックする
      lb_retcode := xxcmn_common_pkg.get_tbl_lock(gv_cons_schema_wsh, gv_cons_mov_tmp_tbl);
      -- ロックできなかった場合
      IF (lb_retcode = FALSE) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13103     -- テーブルロックエラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_mov_tmp_jp) 
                                                                      -- 移動在庫補充元中間テーブル
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
      END IF;
      -- 全テーブルデータを削除する
      lb_retcode := xxcmn_common_pkg.del_all_data(gv_cons_schema_wsh, gv_cons_mov_tmp_tbl);
      -- データの削除に失敗した場合
      IF (lb_retcode = FALSE) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13006 -- テーブルデータ削除エラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_mov_tmp_jp) 
                                                                      -- 移動在庫補充元中間テーブル
                                                      ,1
                                                      ,5000);
         RAISE global_api_expt;
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
  END purge_table;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : C-4  情報抽出
   ***********************************************************************************/
  PROCEDURE get_data(
      iv_action_type         IN VARCHAR2,            -- 処理種別
      iv_req_mov_no          IN VARCHAR2,            -- 依頼/移動No
      iv_deliver_from        IN VARCHAR2,            -- 出庫元保管場所
      iv_deliver_type        IN VARCHAR2,            -- 出庫形態
      iv_object_date_from    IN VARCHAR2,            -- 対象期間From
      iv_object_date_to      IN VARCHAR2,            -- 対象期間To
      iv_arrival_date        IN VARCHAR2,            -- 着日指定
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- 出荷情報抽出のデータを抽出するカーソル(Fromのみ)
    CURSOR lc_deliv_data_cur_from
    IS
      SELECT
        xoha.deliver_to_id,                 -- 出荷先ID
        xoha.deliver_to,                    -- 出荷先コード
        xoha.request_no,                    -- 依頼No
        xoha.deliver_from_id,               -- 出荷元ID
        xoha.deliver_from,                  -- 出荷元コード
        xoha.weight_capacity_class,         -- 重量容積区分
        xola.shipping_inventory_item_id,    -- 出荷品目ID
        ximv.item_id,                       -- OPM品目ID
        xola.shipping_item_code,            -- 品目コード
        xola.quantity,                      -- 数量
        xottv.transaction_type_id,          -- 受注タイプID
        xottv.transaction_type_code,        -- 出庫形態
        xicv.item_class_code,               -- 品目区分
        NULL,                               -- 製品識別区分
        xicv.prod_class_code,               -- 商品区分
        NVL(xilv.direct_ship_type,gv_cons_ds_type_n),              -- 直送区分
        ximv.num_of_deliver,                -- 出荷入数
        ximv.conv_unit,                     -- 入出庫換算単位
        ximv.num_of_cases,                  -- ケース入数
        ximv.item_um,                       -- 単位
        ximv.frequent_qty,                  -- 代表入数
        NULL,                               -- 在庫補充ルール
        NULL                                -- 在庫補充元
      FROM
        xxwsh_order_headers_all        xoha,   -- 受注ヘッダアドオン
        xxwsh_order_lines_all          xola,   -- 受注明細アドオン
        xxwsh_oe_transaction_types2_v  xottv,  -- 受注タイプ情報View2
        xxcmn_item_categories4_v       xicv,   -- カテゴリ情報View4
        xxcmn_item_locations2_v        xilv,   -- 保管場所情報View2
        xxcmn_item_mst2_v              ximv    -- 品目情報View2
      WHERE
            xoha.order_type_id          = xottv.transaction_type_id  -- 受注タイプID
        AND xottv.shipping_shikyu_class = gv_cons_t_deliv            -- 出荷依頼
        AND xottv.order_category_code   <> gv_cons_odr_cat_ret       -- 受注カテゴリRETURN以外
        AND xoha.req_status             = gv_cons_status_shime       -- ステータス「締め済み」
        AND xoha.request_no            = NVL(iv_req_mov_no, xoha.request_no)
            -- 依頼Noが入力されていたらその値を、未入力ならIS NULLで検索する
        AND xoha.deliver_from           = iv_deliver_from            -- 出荷元保管場所
        AND xottv.transaction_type_id   = iv_deliver_type            -- 出庫形態
        AND xoha.latest_external_flag   = gv_cons_flg_y              -- 最新フラグ 'Y'
        AND xoha.order_header_id        = xola.order_header_id       -- 受注ヘッダアドオンID
        AND NVL(xola.delete_flag,'N')  <> gv_cons_flg_y              -- 削除フラグ
        AND xola.move_number           IS NULL                       -- 移動No
        AND xola.po_number             IS NULL                       -- 発注No
        AND xoha.deliver_from_id        = xilv.inventory_location_id    -- 保管倉庫ID
        AND xola.shipping_inventory_item_id  = ximv.inventory_item_id   -- 出荷品目ID
        AND xoha.schedule_ship_date    >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')-- 出荷予定日
        AND xicv.item_id                = ximv.item_id               -- 品目ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id 
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xola.shipping_item_code,
        xoha.deliver_from
      FOR UPDATE OF xoha.order_header_id,
                    xola.order_line_id;
--
    -- 出荷情報抽出のデータを抽出するカーソル(FromTo)
    CURSOR lc_deliv_data_cur_fromto
    IS
      SELECT
        xoha.deliver_to_id,                 -- 出荷先ID
        xoha.deliver_to,                    -- 出荷先コード
        xoha.request_no,                    -- 依頼No
        xoha.deliver_from_id,               -- 出荷元ID
        xoha.deliver_from,                  -- 出荷元コード
        xoha.weight_capacity_class,         -- 重量容積区分
        xola.shipping_inventory_item_id,    -- 出荷品目ID
        ximv.item_id,                       -- OPM品目ID
        xola.shipping_item_code,            -- 品目コード
        xola.quantity,                      -- 数量
        xottv.transaction_type_id,          -- 受注タイプID
        xottv.transaction_type_code,        -- 出庫形態
        xicv.item_class_code,               -- 品目区分
        NULL,                               -- 製品識別区分
        xicv.prod_class_code,               -- 商品区分
        NVL(xilv.direct_ship_type,gv_cons_ds_type_n),              -- 直送区分
        ximv.num_of_deliver,                -- 出荷入数
        ximv.conv_unit,                     -- 入出庫換算単位
        ximv.num_of_cases,                  -- ケース入数
        ximv.item_um,                       -- 単位
        ximv.frequent_qty,                  -- 代表入数
        NULL,                               -- 在庫補充ルール
        NULL                                -- 在庫補充元
      FROM
        xxwsh_order_headers_all        xoha,   -- 受注ヘッダアドオン
        xxwsh_order_lines_all          xola,   -- 受注明細アドオン
        xxwsh_oe_transaction_types2_v  xottv,   -- 受注タイプ情報View2
        xxcmn_item_categories4_v       xicv,   -- カテゴリ情報View4
        xxcmn_item_locations2_v        xilv,   -- 保管場所情報View2
        xxcmn_item_mst2_v              ximv    -- 品目情報View2
      WHERE
            xoha.order_type_id          = xottv.transaction_type_id  -- 受注タイプID
        AND xottv.shipping_shikyu_class = gv_cons_t_deliv            -- 出荷依頼
        AND xottv.order_category_code   <> gv_cons_odr_cat_ret       -- 受注カテゴリRETURN以外
        AND xoha.req_status             = gv_cons_status_shime       -- ステータス「締め済み」
        AND xoha.request_no            = NVL(iv_req_mov_no, xoha.request_no)
            -- 依頼Noが入力されていたらその値を、未入力ならIS NULLで検索する
        AND xoha.deliver_from           = iv_deliver_from            -- 出荷元保管場所
        AND xottv.transaction_type_id   = iv_deliver_type            -- 出庫形態
        AND xoha.latest_external_flag   = gv_cons_flg_y              -- 最新フラグ 'Y'
        AND xoha.order_header_id        = xola.order_header_id       -- 受注ヘッダアドオンID
        AND NVL(xola.delete_flag,'N')  <> gv_cons_flg_y              -- 削除フラグ
        AND xola.move_number           IS NULL                       -- 移動No
        AND xola.po_number             IS NULL                       -- 発注No
        AND xoha.deliver_from_id        = xilv.inventory_location_id    -- 保管倉庫ID
        AND xola.shipping_inventory_item_id  = ximv.inventory_item_id   -- 出荷品目ID
        AND xoha.schedule_ship_date    >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')-- 出荷予定日
        AND xoha.schedule_ship_date    <= TO_DATE(iv_object_date_to,'YYYY/MM/DD')-- 出荷予定日
        AND xicv.item_id                = ximv.item_id               -- 品目ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id 
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xola.shipping_item_code,
        xoha.deliver_from
      FOR UPDATE OF xoha.order_header_id,
                    xola.order_line_id;
--
    -- 移動情報抽出のデータを抽出するカーソル(From)
    CURSOR lc_move_data_cur_from
    IS
      SELECT
        xmrih.mov_num,                  -- 移動番号
        xmrih.shipped_locat_id,         -- 出庫元ID
        xmrih.shipped_locat_code,       -- 出庫元コード
        xmrih.ship_to_locat_id,         -- 入庫先ID
        xmrih.ship_to_locat_code,       -- 入庫先コード
        xmrih.weight_capacity_class,    -- 重量容積区分
        ximv.item_id,                   -- 品目ID
        ximv.inventory_item_id,         -- 
        xmril.item_code,                -- 品目コード
        xmril.instruct_qty,             -- 指示数量
        xicv.item_class_code,           -- 品目区分
        NULL,                           -- 製品識別区分
        xicv.prod_class_code,           -- 商品区分
        ximv.num_of_deliver,            -- 出荷入数
        ximv.conv_unit,                 -- 入出庫換算単位
        ximv.num_of_cases,              -- ケース入数
        ximv.item_um,                   -- 単位
        ximv.frequent_qty,              -- 代表入数
        NULL,                           -- 在庫補充ルール
        NULL                            -- 在庫補充元
      FROM
        xxinv_mov_req_instr_headers    xmrih,  -- 移動依頼/指示ヘッダ
        xxinv_mov_req_instr_lines      xmril,  -- 移動依頼/指示明細
        xxcmn_item_categories4_v       xicv,   -- カテゴリ情報View4
        xxcmn_item_mst2_v              ximv    -- 品目情報View2
      WHERE
            xmrih.status          IN (gv_cons_mov_sts_e,gv_cons_mov_sts_c) --「依頼済み」「調整中」
        AND xmrih.mov_type           = gv_cons_move_type      -- 「積送あり」
        AND xmrih.mov_num           = NVL(iv_req_mov_no, xmrih.mov_num)
            -- 移動Noが入力されていたらその値を、未入力ならIS NULLで検索する
        AND xmrih.shipped_locat_code = iv_deliver_from        -- 出荷元保管場所
        AND xmrih.mov_hdr_id         = xmril.mov_hdr_id       -- 移動ヘッダID
        AND NVL(xmril.delete_flg,'N') <> gv_cons_flg_y        -- 取消フラグ
        AND xmril.move_num          IS NULL                   -- 参照移動番号
        AND xmril.po_num            IS NULL                   -- 参照発注番号
        AND xmril.item_id            = ximv.item_id           -- 品目ID
        AND xmrih.schedule_ship_date   >= TO_DATE(iv_object_date_from,'YYYY/MM/DD') -- 出荷予定日
        AND xicv.item_id                = ximv.item_id        -- 品目ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id 
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active     <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active IS NULL
             OR ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xmril.item_code,
        xmrih.shipped_locat_code
      FOR UPDATE OF xmrih.mov_num,
                    xmril.mov_line_id;
--
    -- 移動情報抽出のデータを抽出するカーソル(FromTo)
    CURSOR lc_move_data_cur_fromto
    IS
      SELECT
        xmrih.mov_num,                  -- 移動番号
        xmrih.shipped_locat_id,         -- 出庫元ID
        xmrih.shipped_locat_code,       -- 出庫元コード
        xmrih.ship_to_locat_id,         -- 入庫先ID
        xmrih.ship_to_locat_code,       -- 入庫先コード
        xmrih.weight_capacity_class,    -- 重量容積区分
        ximv.item_id,                   -- 品目ID
        ximv.inventory_item_id,         -- 
        xmril.item_code,                -- 品目コード
        xmril.instruct_qty,             -- 指示数量
        xicv.item_class_code,           -- 品目区分
        NULL,                           -- 製品識別区分
        xicv.prod_class_code,           -- 商品区分
        ximv.num_of_deliver,            -- 出荷入数
        ximv.conv_unit,                 -- 入出庫換算単位
        ximv.num_of_cases,              -- ケース入数
        ximv.item_um,                   -- 単位
        ximv.frequent_qty,              -- 代表入数
        NULL,                           -- 在庫補充ルール
        NULL                            -- 在庫補充元
      FROM
        xxinv_mov_req_instr_headers    xmrih,   -- 移動依頼/指示ヘッダ
        xxinv_mov_req_instr_lines      xmril,   -- 移動依頼/指示明細
        xxcmn_item_categories4_v       xicv,    -- カテゴリ情報View4
        xxcmn_item_mst2_v              ximv     -- 品目情報View2
      WHERE
            xmrih.status             IN (gv_cons_mov_sts_e,gv_cons_mov_sts_c)
                                                --「依頼済み」「調整中」
        AND xmrih.mov_type            = gv_cons_move_type      -- 「積送あり」
        AND xmrih.mov_num           = NVL(iv_req_mov_no, xmrih.mov_num)
            -- 移動Noが入力されていたらその値を、未入力ならIS NULLで検索する
        AND xmrih.shipped_locat_code  = iv_deliver_from        -- 出荷元保管場所
        AND xmrih.mov_hdr_id          = xmril.mov_hdr_id       -- 移動ヘッダID
        AND NVL(xmril.delete_flg,'N') <> gv_cons_flg_y          -- 取消フラグ
        AND xmril.move_num           IS NULL                   -- 参照移動番号
        AND xmril.po_num             IS NULL                   -- 参照発注番号
        AND xmril.item_id             = ximv.item_id           -- 品目ID
        AND xmrih.schedule_ship_date >= TO_DATE(iv_object_date_from,'YYYY/MM/DD')    -- 出荷予定日
        AND xmrih.schedule_ship_date <= TO_DATE(iv_object_date_to,'YYYY/MM/DD') --(NULLの場合あり)
        AND xicv.item_id                = ximv.item_id               -- 品目ID
        AND xicv.item_id           NOT IN ( SELECT xicv.item_id 
                                            FROM   xxcmn_item_categories4_v xicv
                                            WHERE  xicv.prod_class_code = gv_cons_id_drink
                                              AND  xicv.item_class_code = gv_cons_item_product)
        AND ximv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')
        AND (ximv.end_date_active     IS NULL
             OR ximv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
      ORDER BY
        xmril.item_code,
        xmrih.shipped_locat_code
      FOR UPDATE OF xmrih.mov_num,
                    xmril.mov_line_id;
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_action_type = ' || iv_action_type);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_req_mov_no = ' || iv_req_mov_no);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_deliver_from = ' || iv_deliver_from);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_deliver_type = ' || iv_deliver_type);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_object_date_from = ' || iv_object_date_from);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_object_date_to = ' || iv_object_date_to);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)iv_arrival_date = ' || iv_arrival_date);
-- DEBUG
--
    -- 処理種別が「出荷」で対象期間TOが入力されていない場合のデータ抽出
    IF ((iv_action_type = gv_cons_t_deliv) AND (iv_object_date_to IS NULL)) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)lc_deliv_from in');
-- DEBUG
      -- カーソルオープン
      OPEN lc_deliv_data_cur_from;
--
      -- データの一括取得
      FETCH lc_deliv_data_cur_from BULK COLLECT INTO gr_deliv_data_tbl;
--
      -- 処理件数のセット
      gn_target_cnt := gr_deliv_data_tbl.COUNT;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)gn_target_cnt(lc_deliv_from) = ' || gn_target_cnt);
-- DEBUG
--
      -- カーソルクローズ
      CLOSE lc_deliv_data_cur_from;
--
    -- 処理種別が「出荷」で対象期間TOが入力されている場合のデータ抽出
    ELSIF ((iv_action_type = gv_cons_t_deliv) AND (iv_object_date_to IS NOT NULL)) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)lc_deliv_fromto in');
-- DEBUG
      -- カーソルオープン
      OPEN lc_deliv_data_cur_fromto;
--
      -- データの一括取得
      FETCH lc_deliv_data_cur_fromto BULK COLLECT INTO gr_deliv_data_tbl;
--
      -- 処理件数のセット
      gn_target_cnt := gr_deliv_data_tbl.COUNT;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)gn_target_cnt(lc_deliv_fromto) = ' || gn_target_cnt);
if (gn_target_cnt>0) then
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)gr_deliv_data_tbl(1).drop_ship_wsh_div = ' || gr_deliv_data_tbl(1).drop_ship_wsh_div);
end if;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)lc_deliv_from in');
-- DEBUG
--
      -- カーソルクローズ
      CLOSE lc_deliv_data_cur_fromto;
--
    -- 処理種別が「移動」で対象期間TOが入力されていない場合のデータ抽出
    ELSIF ((iv_action_type = gv_cons_t_move) AND (iv_object_date_to IS NULL)) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)lc_move_from in');
-- DEBUG
      -- カーソルオープン
      OPEN lc_move_data_cur_from;
--
      -- データの一括取得
      FETCH lc_move_data_cur_from BULK COLLECT INTO gr_move_data_tbl;
--
      -- 処理件数のセット
      gn_target_cnt := gr_move_data_tbl.COUNT;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)gn_target_cnt(lc_move_from) = ' || gn_target_cnt);
-- DEBUG
--
      -- カーソルクローズ
      CLOSE lc_move_data_cur_from;
--
    -- 処理種別が「移動」で対象期間TOが入力されている場合のデータ抽出
    ELSE
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)lc_move_fromto in');
-- DEBUG
      -- カーソルオープン
      OPEN lc_move_data_cur_fromto;
--
      -- データの一括取得
      FETCH lc_move_data_cur_fromto BULK COLLECT INTO gr_move_data_tbl;
--
      -- 処理件数のセット
      gn_target_cnt := gr_move_data_tbl.COUNT;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-4)gn_target_cnt(lc_move_fromto) = ' || gn_target_cnt);
-- DEBUG
--
      -- カーソルクローズ
      CLOSE lc_move_data_cur_fromto;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : get_rule
   * Description      : C-5  ルール取得
   ***********************************************************************************/
  PROCEDURE get_rule(
    in_shori_cnt          IN         NUMBER,       -- 処理カウンタ
    iv_action_type        IN         VARCHAR2,     -- 処理種別
    iv_arrival_date       IN         VARCHAR2,     -- 着日指定
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rule'; -- プログラム名
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
    lv_move_from_whse_code1  xxcmn_sourcing_rules2_v.move_from_whse_code1%TYPE;
    -- 移動元保管倉庫コード1
    lv_move_from_whse_code2  xxcmn_sourcing_rules2_v.move_from_whse_code2%TYPE;
    -- 移動元保管倉庫コード2
    lv_vendor_site_code1     xxcmn_sourcing_rules2_v.vendor_site_code1%TYPE;
    -- 仕入先サイトコード1
    lv_item_code          xxcmn_item_mst2_v.item_no%TYPE;                  -- 品目コード
    lv_delivery_whse_code xxcmn_sourcing_rules2_v.delivery_whse_code%TYPE; -- 出荷元コード
    lv_no                 xxwsh_order_headers_all.request_no%TYPE;         -- 依頼/移動No
    lv_item_name          xxcmn_item_mst2_v.item_name%TYPE;                -- 品目名称
--
    -- *** ローカル・カーソル ***
    CURSOR lc_rule_cur1_1  -- 1-1の条件
    IS
    SELECT
      xsrv.move_from_whse_code1      -- 移動元保管倉庫コード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = lv_item_code            -- 品目コード
      AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- 出荷保管倉庫コード
      AND
      xsrv.move_from_whse_code1 IS NOT NULL               -- 移動元保管倉庫コード1
      AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
      AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.move_from_whse_code1;
 --
    CURSOR lc_rule_cur1_2  -- 1-2の条件
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = lv_item_code            -- 品目コード
      AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- 出荷保管倉庫コード
      AND
       ((xsrv.vendor_site_code1    IS NOT NULL)           -- 仕入先サイトコード1          =
        AND                                               -- 1-2の条件 ====================
        (xsrv.move_from_whse_code1 IS NULL))              -- 移動元保管倉庫コード1        =
      AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
      AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    CURSOR lc_rule_cur2_1  -- 2-1の条件
    IS
    SELECT
      xsrv.move_from_whse_code2      -- 移動元保管倉庫コード2
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code              = lv_item_code            -- 品目コード
      AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- 移動元保管倉庫コード1
      AND
      xsrv.move_from_whse_code2 IS NOT NULL                 -- 移動元保管倉庫コード2
      AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
      AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.move_from_whse_code2;
--
    CURSOR lc_rule_cur2_2  -- 2-2の条件
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code              = lv_item_code            -- 品目コード
      AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- 移動元保管倉庫コード1
      AND
       ((xsrv.vendor_site_code1   IS NOT NULL)              -- 仕入先サイトコード1          =
         AND                                                -- 2-2の条件 ====================
        (xsrv.move_from_whse_code2 IS NULL))                -- 移動元保管倉庫コード2        =
      AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
      AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    CURSOR lc_rule_cur3_1
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code              = lv_item_code              -- 品目コード
    AND
      xsrv.move_from_whse_code2   = lv_delivery_whse_code   -- 移動元保管倉庫コード2
    AND                                                     -- 3-1の条件=====================
      xsrv.vendor_site_code1     IS NOT NULL                -- 仕入先サイトコード1          =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    CURSOR lc_rule_cur1_1_z
    IS
    SELECT
      xsrv.move_from_whse_code1      -- 移動元保管倉庫コード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card       -- 品目コード('ZZZZZZZ')
    AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- 出荷保管倉庫コード
    AND
      xsrv.move_from_whse_code1 IS NOT NULL               -- 移動元保管倉庫コード1
    AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.move_from_whse_code1;
--
    CURSOR lc_rule_cur1_2_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card       -- 品目コード('ZZZZZZZ')
    AND
      xsrv.delivery_whse_code   = lv_delivery_whse_code   -- 出荷保管倉庫コード
    AND
       ((xsrv.vendor_site_code1    IS NOT NULL)           -- 仕入先サイトコード1          =
       AND                                                -- 1-2の条件 ====================
       (xsrv.move_from_whse_code1 IS NULL))               -- 移動元保管倉庫コード1        =
    AND
      xsrv.start_date_active   <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active     >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    CURSOR lc_rule_cur2_1_z
    IS
    SELECT
      xsrv.move_from_whse_code2      -- 移動元保管倉庫コード2
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- 品目コード('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- 移動元保管倉庫コード1
    AND
       xsrv.move_from_whse_code2 IS NOT NULL                -- 移動元保管倉庫コード2
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.move_from_whse_code2;
--
    CURSOR lc_rule_cur2_2_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- 品目コード('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code1   = lv_delivery_whse_code   -- 移動元保管倉庫コード1
    AND
       ((xsrv.vendor_site_code1   IS NOT NULL)              -- 仕入先サイトコード1          =
         AND                                                -- 2-2の条件 ====================
       (xsrv.move_from_whse_code2 IS NULL))                 -- 移動元保管倉庫コード2        =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    CURSOR lc_rule_cur3_1_z
    IS
    SELECT
      xsrv.vendor_site_code1         -- 仕入先サイトコード1
    FROM
      xxcmn_sourcing_rules2_v  xsrv  -- 物流構成情報View2
    WHERE
      xsrv.item_code            = gv_cons_wild_card         -- 品目コード('ZZZZZZZ')
    AND
      xsrv.move_from_whse_code2   = lv_delivery_whse_code   -- 移動元保管倉庫コード2
    AND                                                     -- 3-1の条件=====================
      xsrv.vendor_site_code1    IS NOT NULL                 -- 仕入先サイトコード1          =
    AND
      xsrv.start_date_active      <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
      xsrv.end_date_active        >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    ORDER BY
      xsrv.vendor_site_code1;
--
    -- 品目名称を取得するカーソル
    CURSOR lc_item_name_cur
    IS
    SELECT ximv.item_name
    FROM   xxcmn_item_mst2_v  ximv
    WHERE
           ximv.item_no            = lv_item_code     -- 品目コード
    AND
           ximv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用開始日
    AND
           ximv.end_date_active   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 適用終了日
    AND
    ROWNUM                         = 1;
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)in..........');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)in_shori_cnt =' || in_shori_cnt);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)iv_action_type =' || iv_action_type);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)iv_arrival_date =' || iv_arrival_date);
-- DEBUG
    -- 処理種別により品目コードと出荷保管倉庫コードとNoを切り分ける
    -- 出荷なら
    IF (iv_action_type = gv_cons_t_deliv) THEN
      lv_item_code          := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;  -- 品目コード
      lv_delivery_whse_code := gr_deliv_data_tbl(in_shori_cnt).deliver_from;        -- 出荷元コード
      lv_no                 := gr_deliv_data_tbl(in_shori_cnt).request_no;          -- 依頼No
    ELSE
      lv_item_code          := gr_move_data_tbl(in_shori_cnt).item_code;            -- 品目コード
      lv_delivery_whse_code := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;   -- 出庫元コード
      lv_no                 := gr_move_data_tbl(in_shori_cnt).mov_num;              -- 移動No
    END IF;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)..........');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lv_item_code =' || lv_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lv_delivery_whse_code =' || lv_delivery_whse_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lv_no =' || lv_no);
-- DEBUG
--
    -- 1-1 (移動元保管倉庫コード1を検索)
    FOR r_rule_cur1_1 IN lc_rule_cur1_1 LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_1 Found...');
-- DEBUG
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「移動」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1.move_from_whse_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「移動」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1.move_from_whse_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_1 NotFound...');
-- DEBUG
--
    -- 1-2 (仕入先サイトコード1を検索)
    FOR r_rule_cur1_2 IN lc_rule_cur1_2 LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_2 Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_2 NotFound...');
-- DEBUG
--
    -- 2-1 (移動元保管倉庫コード2を検索)
    FOR r_rule_cur2_1 IN lc_rule_cur2_1 LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_1 Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「移動」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1.move_from_whse_code2;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「移動」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード2
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1.move_from_whse_code2;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_1 NotFound...');
-- DEBUG
--
    -- 2-2 (仕入先サイトコード1を検索)
    FOR r_rule_cur2_2 IN lc_rule_cur2_2 LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_2 Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_2 NotFound...');
-- DEBUG
--
    -- 3-1 (仕入先サイトコード1を検索)
    FOR r_rule_cur3_1 IN lc_rule_cur3_1 LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur3_1 Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur3_1 NotFound...');
-- DEBUG
--
    -- 1-1 Z版(移動元保管倉庫コード1を検索)
    FOR r_rule_cur1_1_z IN lc_rule_cur1_1_z LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_1_z Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「移動」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1_z.move_from_whse_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「移動」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_1_z.move_from_whse_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_1_z NotFound...');
-- DEBUG
--
    -- 1-2 Z版(仕入先サイトコード1を検索)
    FOR r_rule_cur1_2_z IN lc_rule_cur1_2_z LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_2_z Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2_z.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur1_2_z.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur1_2_z NotFound...');
-- DEBUG
--
    -- 2_1 Z版(移動元保管倉庫コード2を検索)
    FOR r_rule_cur2_1_z IN lc_rule_cur2_1_z LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_1_z Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「移動」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1_z.move_from_whse_code2;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「移動」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_move;
        -- 在庫補充元は移動元保管倉庫コード2
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_1_z.move_from_whse_code2;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_1_z NotFound...');
-- DEBUG
--
    -- 2-2 Z版(仕入先サイトコード1を検索)
    FOR r_rule_cur2_2_z IN lc_rule_cur2_2_z LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_2_z Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2_z.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur2_2_z.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur2_2_z NotFound...');
-- DEBUG
--
    -- 3-1 Z版(仕入先サイトコード1を検索)
    FOR r_rule_cur3_1_z IN lc_rule_cur3_1_z LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur3_1_z Found...');
-- DEBUG
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 在庫補充ルールは「発注」
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1_z.vendor_site_code1;
      -- 移動なら
      ELSE
        -- 在庫補充ルールは「発注」
        gr_move_data_tbl(in_shori_cnt).stock_rep_rule   := gv_cons_rule_order;
        -- 在庫補充元は仕入先サイトコード1
        gr_move_data_tbl(in_shori_cnt).stock_rep_origin := r_rule_cur3_1_z.vendor_site_code1;
      END IF;
      RETURN;
    END LOOP;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)lc_rule_cur3_1_z NotFound...');
-- DEBUG
--
    -- カーソル1-1 ～ 3-1、1-1-Z ～ 3-1-Zで検索できなかった場合は「在庫補充元なし」として、
    -- 自動作成しない
    -- 品目名称を検索
    FOR r_item_name_cur IN lc_item_name_cur LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-5)all NotFound lv_item_name = ' || r_item_name_cur.item_name);
-- DEBUG
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                  ,gv_msg_wsh_13007       -- 在庫補充元取得エラー
                                                  ,gv_tkn_param1          -- トークン'PARAM1'
                                                  ,iv_action_type         -- 処理種別
                                                  ,gv_tkn_param2          -- トークン'PARAM2'
                                                  ,lv_no                  -- 依頼/移動No
                                                  ,gv_tkn_param3          -- トークン'PARAM3'
                                                  ,lv_item_code           -- 品目コード
                                                  ,gv_tkn_param4          -- トークン'PARAM4'
                                                  ,r_item_name_cur.item_name     -- 品目名称
                                                  ,gv_tkn_param5          -- トークン'PARAM5'
                                                  ,lv_delivery_whse_code  -- 出荷(庫)元コード
                                                  ) 
                                                  ,1
                                                  ,5000);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END LOOP;
    -- 警告リターンする
    RAISE common_warn_expt;
--
  EXCEPTION
    -- *** 共通関数エラーハンドラ (警告を返す)***
    WHEN common_warn_expt THEN
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
  END get_rule;
--
  /**********************************************************************************
   * Procedure Name   : ins_ints_table
   * Description      : C-6  中間テーブル登録(出荷)
   ***********************************************************************************/
  PROCEDURE ins_ints_table(
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ints_table'; -- プログラム名
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
    ln_tbl_cnt   NUMBER;
    ln_cnt       NUMBER;     -- 代入時の添え字
    ln_loop_cnt  NUMBER;     -- ループカウンタ
    ln_not_cnt   NUMBER :=0; -- 読み飛ばし数
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)in...');
-- DEBUG
    -- レコード変数のレコード数を求める
--    ln_tbl_cnt := NVL(gn_target_cnt_deliv,0);
    ln_tbl_cnt := gr_deliv_data_tbl.COUNT;
    -- FORALLで使用できるようにレコード変数を分割格納する
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)ln_tbl_cnt = ' || ln_tbl_cnt);
-- DEBUG
    ln_cnt := 0;
    <<shipped_loop>>
    FOR ln_loop_cnt IN 1..ln_tbl_cnt LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule = ' || gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin = ' || gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin);
-- DEBUG
      -- ルールは見つからなかったデータは処理対象外とする
      IF ((gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_move)
           OR
           (gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_order))
      THEN
        ln_cnt := ln_cnt + 1;
      gt_s_deliver_to_id(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).deliver_to_id;              -- 出荷先ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)============================');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)出荷先ID = ' || gr_deliv_data_tbl(ln_cnt).deliver_to_id);
-- DEBUG
      gt_s_deliver_to(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).deliver_to;                 -- 出荷先コード
      gt_s_request_no(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).request_no;                 -- 依頼No
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)依頼No = ' || gr_deliv_data_tbl(ln_cnt).request_no);
-- DEBUG
      gt_s_deliver_from_id(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).deliver_from_id;            -- 出荷元ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)出荷元ID = ' || gr_deliv_data_tbl(ln_cnt).deliver_from_id);
-- DEBUG
      gt_s_deliver_from(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).deliver_from;               -- 出荷元コード
      gt_s_weight_capacity_class(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).weight_capacity_class;      -- 重量容積区分
      gt_s_shipping_inv_item_id(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).shipping_inventory_item_id; -- 出荷品目ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)出荷品目ID = ' || gr_deliv_data_tbl(ln_cnt).shipping_inventory_item_id);
-- DEBUG
      gt_s_item_id(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).item_id;                    -- 出荷品目ID
      gt_s_shipping_item_code(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).shipping_item_code;         -- 品目コード
      gt_s_quantity(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).quantity;                   -- 数量
      gt_s_order_type_id(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).order_type_id;              -- 受注タイプID
      gt_s_transaction_type_name(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).transaction_type_name;      -- 出庫形態
      gt_s_item_class_code(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).item_class_code;            -- 品目区分
      gt_s_prod_class_code(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).prod_class_code;            -- 商品区分
      gt_s_drop_ship_wsh_div(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).drop_ship_wsh_div;          -- 直送区分
      gt_s_num_of_deliver(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).num_of_deliver;             -- 出荷入数
      gt_s_conv_unit(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).conv_unit;                  -- 入出庫換算単位
      gt_s_num_of_cases(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).num_of_cases;               -- ケース入数
      gt_s_item_um(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).item_um;                    -- 単位
      gt_s_frequent_qty(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).frequent_qty;               -- 代表入数
      gt_s_stock_rep_rule(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).stock_rep_rule;             -- 在庫補充ルール
      gt_s_stock_rep_origin(ln_cnt) :=
       gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin;           -- 在庫補充元
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)在庫補充元 = ' || gr_deliv_data_tbl(ln_loop_cnt).stock_rep_origin);
-- DEBUG
    -- ルールなしだったら読み飛ばす
    ELSE
      ln_not_cnt := ln_not_cnt + 1;
    END IF;
    END LOOP shipped_loop;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-6)読み飛ばし数 = ' || ln_not_cnt );
-- DEBUG
    -- 読み飛ばし数を引いて調整
    ln_tbl_cnt := ln_tbl_cnt - ln_not_cnt;
    -- 出荷在庫補充元中間テーブル登録
    IF (ln_tbl_cnt > 0) THEN
    FORALL ln_cnt IN 1..ln_tbl_cnt
      INSERT INTO xxwsh_shipping_stock_rep_tmp(
        deliver_to_id,              -- 出荷先ID
        deliver_to,                 -- 出荷先コード
        request_no,                 -- 依頼No
        deliver_from_id,            -- 出荷元ID
        deliver_from,               -- 出荷元コード
        weight_capacity_class,      -- 重量容積区分
        shipping_inventory_item_id, -- 出荷品目ID
        item_id,                    -- 品目ID
        shipping_item_code,         -- 品目コード
        quantity,                   -- 数量
        order_type_id,              -- 受注タイプID
        transaction_type_name,      -- 出庫形態
        item_class_code,            -- 品目区分
        prod_class_code,            -- 商品区分
        drop_ship_wsh_div,          -- 直送区分
        num_of_deliver,             -- 出荷入数
        conv_unit,                  -- 入出庫換算単位
        num_of_cases,               -- ケース入数
        item_um,                    -- 単位
        frequent_qty,               -- 代表入数
        stock_rep_rule,             -- 在庫補充ルール
        stock_rep_origin            -- 在庫補充元
      )VALUES(
        gt_s_deliver_to_id(ln_cnt),              -- 出荷先ID
        gt_s_deliver_to(ln_cnt),                 -- 出荷先コード
        gt_s_request_no(ln_cnt),                 -- 依頼No
        gt_s_deliver_from_id(ln_cnt),            -- 出荷元ID
        gt_s_deliver_from(ln_cnt),               -- 出荷元コード
        gt_s_weight_capacity_class(ln_cnt),      -- 重量容積区分
        gt_s_shipping_inv_item_id(ln_cnt),       -- 出荷品目ID
        gt_s_item_id(ln_cnt),                    -- 品目ID
        gt_s_shipping_item_code(ln_cnt),         -- 品目コード
        gt_s_quantity(ln_cnt),                   -- 数量
        gt_s_order_type_id(ln_cnt),              -- 受注タイプID
        gt_s_transaction_type_name(ln_cnt),      -- 出庫形態
        gt_s_item_class_code(ln_cnt),            -- 品目区分
        gt_s_prod_class_code(ln_cnt),            -- 商品区分
        gt_s_drop_ship_wsh_div(ln_cnt),          -- 直送区分
        gt_s_num_of_deliver(ln_cnt),             -- 出荷入数
        gt_s_conv_unit(ln_cnt),                  -- 入出庫換算単位
        gt_s_num_of_cases(ln_cnt),               -- ケース入数
        gt_s_item_um(ln_cnt),                    -- 単位
        gt_s_frequent_qty(ln_cnt),               -- 代表入数
        gt_s_stock_rep_rule(ln_cnt),             -- 在庫補充ルール
        gt_s_stock_rep_origin(ln_cnt)            -- 在庫補充元
      );
      END IF;
-- DEBUG
--commit;
-- DEBUG
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
  END ins_ints_table;
--
  /**********************************************************************************
   * Procedure Name   : ins_intm_table
   * Description      : C-7  中間テーブル登録(移動)
   ***********************************************************************************/
  PROCEDURE ins_intm_table(
      ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
      ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
      ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_intm_table'; -- プログラム名
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
    ln_tbl_cnt   NUMBER;
    ln_cnt       NUMBER;     -- 代入時の添え字
    ln_loop_cnt  NUMBER;     -- ループカウンタ
    ln_not_cnt   NUMBER :=0; -- 読み飛ばし数
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)in...');
-- DEBUG
    -- レコード変数のレコード数を求める
--    ln_tbl_cnt := NVL(gn_target_cnt_move,0);
    ln_tbl_cnt := gr_move_data_tbl.COUNT;
    -- FORALLで使用できるようにレコード変数を分割格納する
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)ln_tbl_cnt = ' || ln_tbl_cnt);
-- DEBUG
    ln_cnt := 0;
    <<move_loop>>
    FOR ln_loop_cnt IN 1..ln_tbl_cnt LOOP
      -- ルールは見つからなかったデータは処理対象外とする
      IF ((gr_move_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_move)
           OR
           (gr_move_data_tbl(ln_loop_cnt).stock_rep_rule = gv_cons_rule_order))
      THEN
      ln_cnt := ln_cnt + 1;
      gt_i_mov_num(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).mov_num;                    -- 移動番号
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)****************************************************');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)移動番号gt_i_mov_num(ln_cnt) = ' || gt_i_mov_num(ln_cnt));
-- DEBUG
      gt_i_shipped_locat_id(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).shipped_locat_id;           -- 出庫元ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)出庫元IDgt_i_shipped_locat_id(ln_cnt) = ' || gt_i_shipped_locat_id(ln_cnt));
-- DEBUG
      gt_i_shipped_locat_code(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).shipped_locat_code;         -- 出庫元コード
      gt_i_ship_to_locat_id(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).ship_to_locat_id;           -- 入庫先ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)入庫元gt_i_ship_to_locat_id(ln_cnt) = ' || gt_i_ship_to_locat_id(ln_cnt));
-- DEBUG
      gt_i_ship_to_locat_code(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).ship_to_locat_code;         -- 入庫先コード
      gt_i_weight_capacity_class(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).weight_capacity_class;      -- 重量容積区分
      gt_i_item_id(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).item_id;                    -- 品目ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)品目IDgt_i_item_id(ln_cnt) = ' || gt_i_item_id(ln_cnt));
-- DEBUG
      gt_i_inventory_item_id(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).inventory_item_id;          -- 品目ID
      gt_i_item_code(ln_cnt) :=
       gr_move_data_tbl(ln_cnt).item_code;                  -- 品目コード
      gt_i_instruct_qty(ln_loop_cnt) :=
       gr_move_data_tbl(ln_cnt).instruct_qty;               -- 指示数量
      gt_i_item_class_code(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).item_class_code;            -- 品目区分
      gt_i_prod_class_code(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).prod_class_code;            -- 商品区分
      gt_i_num_of_deliver(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).num_of_deliver;             -- 出荷入数
      gt_i_conv_unit(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).conv_unit;                  -- 入出庫換算単位
      gt_i_num_of_cases(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).num_of_cases;               -- ケース入数
      gt_i_item_um(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).item_um;                    -- 単位
      gt_i_frequent_qty(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).frequent_qty;               -- 代表入数
      gt_i_stock_rep_rule(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).stock_rep_rule;             -- 在庫補充ルール
      gt_i_stock_rep_origin(ln_cnt) :=
       gr_move_data_tbl(ln_loop_cnt).stock_rep_origin;           -- 在庫補充元
--
    -- ルールなしだったら読み飛ばす
    ELSE
      ln_not_cnt := ln_not_cnt + 1;
    END IF;
    END LOOP move_loop;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-7)読み飛ばし数 = ' || ln_not_cnt );
-- DEBUG
    -- 読み飛ばし数を引いて調整
    ln_tbl_cnt := ln_tbl_cnt - ln_not_cnt;
--
    -- 移動在庫補充元中間テーブル登録
    IF (ln_tbl_cnt > 0) THEN
    FORALL ln_cnt IN 1..ln_tbl_cnt
      INSERT INTO xxwsh_mov_stock_rep_tmp(
        mov_num,                     -- 移動No
        shipped_locat_id,            -- 出庫元ID
        shipped_locat_code,          -- 出庫元コード
        ship_to_locat_id,            -- 入庫先ID
        ship_to_locat_code,          -- 入庫先コード
        weight_capacity_class,       -- 重量容積区分
        item_id,                     -- 品目ID
        inventory_item_id,           --
        item_code,                   -- 品目コード
        instruct_qty,                -- 指示数量
        item_class_code,             -- 品目区分
        prod_class_code,             -- 商品区分
        num_of_deliver,              -- 出荷入数
        conv_unit,                   -- 入出庫換算単位
        num_of_cases,                -- ケース入数
        item_um,                     -- 単位
        frequent_qty,                -- 代表入数
        stock_rep_rule,              -- 在庫補充ルール
        stock_rep_origin             -- 在庫補充元
      )VALUES(
        gt_i_mov_num(ln_cnt),                     -- 移動No
        gt_i_shipped_locat_id(ln_cnt),            -- 出庫元ID
        gt_i_shipped_locat_code(ln_cnt),          -- 出庫元コード
        gt_i_ship_to_locat_id(ln_cnt),            -- 入庫先ID
        gt_i_ship_to_locat_code(ln_cnt),          -- 入庫先コード
        gt_i_weight_capacity_class(ln_cnt),       -- 重量容積区分
        gt_i_item_id(ln_cnt),                     -- 品目ID
        gt_i_inventory_item_id(ln_cnt),           -- 品目ID
        gt_i_item_code(ln_cnt),                   -- 品目コード
        gt_i_instruct_qty(ln_cnt),                -- 指示数量
        gt_i_item_class_code(ln_cnt),             -- 品目区分
        gt_i_prod_class_code(ln_cnt),             -- 商品区分
        gt_i_num_of_deliver(ln_cnt),              -- 出荷入数
        gt_i_conv_unit(ln_cnt),                   -- 入出庫換算単位
        gt_i_num_of_cases(ln_cnt),                -- ケース入数
        gt_i_item_um(ln_cnt),                     -- 単位
        gt_i_frequent_qty(ln_cnt),                -- 代表入数
        gt_i_stock_rep_rule(ln_cnt),              -- 在庫補充ルール
        gt_i_stock_rep_origin(ln_cnt)             -- 在庫補充元
      );
    END IF;
-- DEBUG
--commit;
-- DEBUG
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
  END ins_intm_table;
--
   /**********************************************************************************
   * Procedure Name   : get_ints_data
   * Description      : C-8  中間テーブル抽出(出荷)
   ***********************************************************************************/
  PROCEDURE get_ints_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ints_data'; -- プログラム名
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
    -- 出荷在庫補充元中間テーブルのデータを抽出するカーソル
    CURSOR lc_deliv_data_cur
    IS
      SELECT
        xssrt.deliver_to_id,                 -- 出荷先ID
        xssrt.deliver_to,                    -- 出荷先コード
        xssrt.request_no,                    -- 依頼No
        xssrt.deliver_from_id,               -- 出荷元ID
        xssrt.deliver_from,                  -- 出荷元コード
        xssrt.weight_capacity_class,         -- 重量容積区分
        xssrt.shipping_inventory_item_id,    -- 出荷品目ID
        xssrt.item_id,                       -- 品目ID
        xssrt.shipping_item_code,            -- 品目コード
        xssrt.quantity,                      -- 数量
        xssrt.order_type_id,                 -- 受注タイプID
        xssrt.transaction_type_name,         -- 出庫形態
        xssrt.item_class_code,               -- 品目区分
       DECODE(xssrt.item_class_code, gv_cons_item_class, gv_cons_p_flg_prod, gv_cons_p_flg_noprod),
        -- 品目区分が'1'なら'1'をその他は'2'をセット→製品識別区分
        xssrt.prod_class_code,               -- 商品区分
        NVL(xssrt.drop_ship_wsh_div,gv_cons_ds_type_n),   -- 直送区分
        xssrt.num_of_deliver,                -- 出荷入数
        xssrt.conv_unit,                     -- 入出庫換算単位
        xssrt.num_of_cases,                  -- ケース入数
        xssrt.item_um,                       -- 単位
        xssrt.frequent_qty,                  -- 代表入数
        xssrt.stock_rep_rule,                -- 在庫補充ルール
        xssrt.stock_rep_origin               -- 在庫補充元
      FROM
        xxwsh_shipping_stock_rep_tmp       xssrt   -- 出荷在庫補充元中間テーブル
      ORDER BY
        xssrt.stock_rep_rule,                -- 在庫補充ルール
        xssrt.stock_rep_origin,              -- 在庫補充元
        xssrt.deliver_from,                  -- 出荷元コード
        xssrt.drop_ship_wsh_div,             -- 直送区分
        xssrt.deliver_to,                    -- 出荷先コード
        xssrt.weight_capacity_class,         -- 重量容積区分
        xssrt.item_class_code DESC,          -- 品目区分
        xssrt.shipping_item_code;            -- 品目コード
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-8)in...............');
-- DEBUG
    -- レコード変数の初期化
    gr_deliv_data_tbl.delete;
--
    -- カーソルオープン
    OPEN lc_deliv_data_cur;
--
    -- データの一括取得
    FETCH lc_deliv_data_cur BULK COLLECT INTO gr_deliv_data_tbl;
--
    -- 処理件数のセット
    gn_target_cnt_deliv := gr_deliv_data_tbl.COUNT;
--
    -- カーソルクローズ
    CLOSE lc_deliv_data_cur;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-8)gn_target_cnt_deliv =' || gn_target_cnt_deliv);
-- DEBUG
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
  END get_ints_data;
--
   /**********************************************************************************
   * Procedure Name   : get_intm_data
   * Description      : C-9  中間テーブル抽出(移動)
   ***********************************************************************************/
  PROCEDURE get_intm_data(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_intm_data'; -- プログラム名
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
    -- 移動在庫補充元中間テーブルのデータを抽出するカーソル
    CURSOR lc_move_data_cur
    IS
      SELECT
        xmsrt.mov_num,                       -- 移動番号
        xmsrt.shipped_locat_id,              -- 出庫元ID
        xmsrt.shipped_locat_code,            -- 出庫元コード
        xmsrt.ship_to_locat_id,              -- 入庫先ID
        xmsrt.ship_to_locat_code,            -- 入庫先コード
        xmsrt.weight_capacity_class,         -- 重量容積区分
        xmsrt.item_id,                       -- 品目ID
        xmsrt.inventory_item_id,             -- 
        xmsrt.item_code,                     -- 品目コード
        xmsrt.instruct_qty,                  -- 指示数量
        xmsrt.item_class_code,               -- 品目区分
       DECODE(xmsrt.item_class_code, gv_cons_item_class, gv_cons_p_flg_prod, gv_cons_p_flg_noprod),
        -- 品目区分が'1'なら'1'をその他は'2'をセット→製品識別区分
        xmsrt.prod_class_code,               -- 商品区分
        xmsrt.num_of_deliver,                -- 出荷入数
        xmsrt.conv_unit,                     -- 入出庫換算単位
        xmsrt.num_of_cases,                  -- ケース入数
        xmsrt.item_um,                       -- 単位
        xmsrt.frequent_qty,                  -- 代表入数
        xmsrt.stock_rep_rule,                -- 在庫補充ルール
        xmsrt.stock_rep_origin               -- 在庫補充元
      FROM
        xxwsh_mov_stock_rep_tmp        xmsrt    -- 移動在庫補充元中間テーブル
      ORDER BY
        xmsrt.stock_rep_rule,                -- 在庫補充ルール
        xmsrt.stock_rep_origin,              -- 在庫補充元
        xmsrt.shipped_locat_code,            -- 出庫元コード
        xmsrt.weight_capacity_class,         -- 重量容積区分
        xmsrt.item_class_code DESC,          -- 品目区分
        xmsrt.item_code;                     -- 品目コード
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-9)in ......................');
-- DEBUG
    -- レコード変数の初期化
    gr_move_data_tbl.delete;
--
    -- カーソルオープン
    OPEN lc_move_data_cur;
--
    -- データの一括取得
    FETCH lc_move_data_cur BULK COLLECT INTO gr_move_data_tbl;
--
    -- 処理件数のセット
    gn_target_cnt_move := gr_move_data_tbl.COUNT;
--
    -- カーソルクローズ
    CLOSE lc_move_data_cur;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-9)gn_target_cnt_move =' || gn_target_cnt_move);
-- DEBUG
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
  END get_intm_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_move_data
   * Description      : C-10 移動依頼/指示登録
   ***********************************************************************************/
  PROCEDURE regi_move_data(
    in_shori_cnt             IN         NUMBER,     -- 処理カウンタ
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2,   -- 指示部署指定
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_move_data'; -- プログラム名
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
    ln_ret_code                    NUMBER;  -- 共通関数のリターン値
    lv_mov_line_id                 xxinv_mov_req_instr_lines.mov_line_id%TYPE;   -- 明細ID
    lv_seq_no                      VARCHAR2(12);
    lv_stock_rep_origin      xxcmn_item_locations2_v.segment1%TYPE;              -- 在庫補充元
    lv_stock_rep_origin_id   xxcmn_item_locations2_v.inventory_location_id%TYPE; -- 在庫補充元ID
    lv_frequent_mover        xxcmn_item_locations2_v.frequent_mover%TYPE;        -- 代表運送業者
    lv_locat_to_code         xxcmn_item_locations2_v.segment1%TYPE;            -- 入庫先(出庫元)
    lv_locat_to_id           xxcmn_item_locations2_v.inventory_location_id%TYPE;
                                                                           -- 入庫先ID(出庫元ID)
    ln_sum_palette_weight          NUMBER;      -- 合計パレット重量
    lv_loading_over_class          VARCHAR2(1); -- 積載オーバー区分
    ln_load_efficiency_weight      NUMBER;      -- 重量積載効率
    ln_load_efficiency_capacity    NUMBER;      -- 容積積載効率
    ln_work_number                 NUMBER;
    lv_ship_methods          xxcmn_ship_methods.ship_method%TYPE;              -- 出荷方法
    lv_mixed_ship_method     xxwsh_ship_method2_v.mixed_ship_method_code%TYPE; -- 混載配送区分
    lv_career_id             xxinv_mov_req_instr_headers.career_id%TYPE;       -- 運送業者ID
    lv_prod_class_code       xxcmn_item_categories_v.segment1%TYPE;            -- 商品区分
    lv_weight_capacity_class xxwsh_shipping_stock_rep_tmp.weight_capacity_class%TYPE;
                                                                               -- 重量容積区分
    lv_max_ship_methods       xxcmn_ship_methods.ship_method%TYPE;             -- 最大配送区分
    ln_drink_deadweight       xxcmn_ship_methods.drink_deadweight%TYPE;        -- ドリンク積載重量
    ln_leaf_deadweight        xxcmn_ship_methods.leaf_deadweight%TYPE;         -- リーフ積載重量
    ln_drink_loading_capacity xxcmn_ship_methods.drink_loading_capacity%TYPE;  -- ドリンク積載容積
    ln_leaf_loading_capacity  xxcmn_ship_methods.leaf_loading_capacity%TYPE;   -- リーフ積載容積
    ln_palette_max_qty        xxcmn_ship_methods.palette_max_qty%TYPE;         -- パレット最大枚数
    lv_item_code              xxwsh_shipping_stock_rep_tmp.shipping_item_code%TYPE; -- 品目コード
    ln_quantity               NUMBER;
    ln_sum_weight             NUMBER;       -- 合計重量 O
    ln_sum_capacity           NUMBER;       -- 合計容積 O
    ln_sum_p_weight           NUMBER;       -- 合計パレット重量 O
--
    lv_header_create_flg      VARCHAR2(1);  -- ヘッダ作成フラグ
    lv_line_create_flg        VARCHAR2(1);  -- 明細作成フラグ
--
    -- *** ローカル・カーソル ***
    CURSOR lc_il_id_cur  -- 保管棚IDを検索する
    IS
      SELECT xilv.inventory_location_id,           -- 保管棚ID(No.8で使用)
             xilv.frequent_mover                   -- 代表運送業者(No.22で使用)
      FROM   xxcmn_item_locations2_v  xilv         -- OPM保管場所情報View2
      WHERE  xilv.segment1   = lv_stock_rep_origin -- 在庫補充元倉庫コード
        AND  xilv.date_from <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')     -- 着日指定
        AND  ((xilv.date_to   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))  --
               OR                                                        --
              (xilv.date_to   IS NULL))                                  -- で範囲内であること
        AND  ROWNUM          = 1;
--
    CURSOR lc_carrier_id_cur  -- 運送業者IDを検索する
    IS
      SELECT xcv.party_id                              -- 運送業者ID(No.21で使用)
      FROM   xxcmn_carriers2_v        xcv              -- 運送業者情報View2
      WHERE  xcv.freight_code    = lv_frequent_mover   -- 代表運送業者コード
        AND  xcv.START_DATE_ACTIVE <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')  -- 着日指定
        AND  ((xcv.END_DATE_ACTIVE >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')) --
               OR                                                            --
              (xcv.END_DATE_ACTIVE   IS NULL))                               -- で範囲内であること
        AND  ROWNUM            = 1;
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)in_shori_cnt = ' || in_shori_cnt || ' ########################');
-- DEBUG
-- ############################################################################################
-- ヘッダデータセット
-- ############################################################################################
    -- ヘッダを作成するかを判断する(在庫補充元、出荷元コード、重量容積区分、
    -- 品目区分のどれがが異なる場合)
    -- 処理種別が「出荷」
    IF (iv_action_type = gv_cons_t_deliv) THEN
      IF ((gn_stock_rep_origin_m IS NULL)                -- 1件目のヘッダ作成時
         OR                                              -- 以下のどれかの項目が異なる
         ((gn_stock_rep_origin_m      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_m        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_m          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)
          OR
          (gv_weight_capacity_class_m <> gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class)
          OR
          (gv_product_flg_m           <> gr_deliv_data_tbl(in_shori_cnt).product_flg)
          OR
          (gv_item_class_code_m       <> gr_deliv_data_tbl(in_shori_cnt).item_class_code)))
      THEN
        lv_header_create_flg := gv_cons_flg_y;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)ヘッダを作ります......................');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_stock_rep_origin_m = ' || gn_stock_rep_origin_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_stock_rep_rule_m = ' || gv_stock_rep_rule_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_deliver_from_m = ' || gv_deliver_from_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_weight_capacity_class_m = ' || gn_stock_rep_origin_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_product_flg_m = ' || gv_product_flg_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_item_class_code_m = ' || gv_item_class_code_m);
-- DEBUG
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
      END IF;
    -- 処理種別が「移動」
    ELSE
      IF ((gn_stock_rep_origin_m IS NULL)                -- 1件目のヘッダ作成時
         OR                                              -- 以下のどれかの項目が異なる
         ((gn_stock_rep_origin_m      <> gr_move_data_tbl(in_shori_cnt).stock_rep_origin)
            OR
          (gv_stock_rep_rule_m        <> gr_move_data_tbl(in_shori_cnt).stock_rep_rule)
            OR
          (gv_deliver_from_m          <> gr_move_data_tbl(in_shori_cnt).shipped_locat_code)
            OR
          (gv_weight_capacity_class_m <> gr_move_data_tbl(in_shori_cnt).weight_capacity_class)
            OR
          (gv_product_flg_m           <> gr_move_data_tbl(in_shori_cnt).product_flg)
            OR
          (gv_item_class_code_m       <> gr_move_data_tbl(in_shori_cnt).item_class_code)))
      THEN
        lv_header_create_flg := gv_cons_flg_y;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)ヘッダを作ります......................');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_stock_rep_origin_m = ' || gn_stock_rep_origin_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_stock_rep_rule_m = ' || gv_stock_rep_rule_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_deliver_from_m = ' || gv_deliver_from_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_weight_capacity_class_m = ' || gn_stock_rep_origin_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_product_flg_m = ' || gv_product_flg_m);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gv_item_class_code_m = ' || gv_item_class_code_m);
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
      END IF;
    END IF;
--
    -- ヘッダ作成要の場合
    IF (lv_header_create_flg = gv_cons_flg_y) THEN
      -- **************************************************
      -- 移動依頼/指示ヘッダ登録用変数にデータをセットする
      -- **************************************************
--
      -- 指示数量合計変数をヘッダ単位で初期化
      gn_sum_inst_quantity  := 0;
      -- 明細番号初期化
      gn_line_number   := 0;
--
      -- シーケンスより移動ヘッダIDを求める
      SELECT xxinv_mov_hdr_s1.NEXTVAL
      INTO   gv_mov_hdr_id
      FROM   DUAL;
--
      -- 採番関数
      xxcmn_common_pkg.get_seq_no( gv_cons_seq_move,
                                   lv_seq_no,
                                   lv_errbuf,
                                   lv_retcode,
                                   lv_errmsg);
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_seq_no - lv_seq_no =' || lv_seq_no);
-- DEBUG
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13008     -- 採番関数エラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                      ,gv_tkn_param1        -- トークン'PARAM1'
                                                      ,gv_cons_seq_move     -- 採番区分「移動」
                                                      ,gv_tkn_param2        -- トークン'PARAM2'
                                                      ,lv_retcode           -- リターンコード
                                                      ,gv_tkn_param3        -- トークン'PARAM3'
                                                      ,lv_errmsg)           -- メッセージ
                                                      ,1
                                                      ,5000);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
         gn_warn_cnt := gn_warn_cnt + 1;
        -- ヘッダ作成単位の項目保持
      ln_ret_code := header_data_save(in_shori_cnt, iv_action_type );
         RAISE common_warn_expt;
      END IF;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_seq_no after.......');
-- DEBUG
--
      -- パラメータの処理種別で在庫補充元、入庫先を切り分ける
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_stock_rep_origin := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin; --出庫元(補充元)
        lv_locat_to_code    := gr_deliv_data_tbl(in_shori_cnt).deliver_from;     --入庫先
        lv_locat_to_id      := gr_deliv_data_tbl(in_shori_cnt).deliver_from_id;  --入庫先ID
      ELSE
        lv_stock_rep_origin := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;  --出庫元(補充元)
        lv_locat_to_code    := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;--入庫先
        lv_locat_to_id      := gr_move_data_tbl(in_shori_cnt).shipped_locat_id;  --入庫先ID
      END IF;
      -- 出庫元ID(保管棚ID)および代表運送業者を検索
      OPEN  lc_il_id_cur;
      FETCH lc_il_id_cur INTO lv_stock_rep_origin_id,
                              lv_frequent_mover;
      CLOSE lc_il_id_cur;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_seq_no after2.......');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_stock_rep_origin = ' || lv_stock_rep_origin);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_stock_rep_origin_id = ' || lv_stock_rep_origin_id);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_locat_to_code = ' || lv_locat_to_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_locat_to_id = ' || lv_locat_to_id);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_frequent_mover = ' || lv_frequent_mover);
-- DEBUG
/*    -- パラメータの処理種別で入庫先IDを切り分ける
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_locat_to_id := gr_deliv_data_tbl(in_shori_cnt).deliver_from_id; -- 入庫先ID(出荷元ID)
      ELSE
        lv_locat_to_id := gr_move_data_tbl(in_shori_cnt).shipped_locat_id; -- 入庫先ID(出庫元ID)
      END IF;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_seq_no after3.......');
-- DEBUG
      -- パラメータの処理種別で在庫補充元を切り分ける
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_locat_code := gr_deliv_data_tbl(in_shori_cnt).deliver_from;      -- 出荷元コード
      ELSE
        lv_locat_code := gr_move_data_tbl(in_shori_cnt).shipped_locat_code; -- 出庫元コード
      END IF;
*/
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_seq_no after4.......');
-- DEBUG
--
      -- パラメータの処理種別でパラメータを切り分ける
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_weight_capacity_class := gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class;
      ELSE
        lv_weight_capacity_class := gr_move_data_tbl(in_shori_cnt).weight_capacity_class;
      END IF;
--
      -- パラメータの処理種別でパラメータを切り分ける
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_prod_class_code := gr_deliv_data_tbl(in_shori_cnt).prod_class_code;
      ELSE
        lv_prod_class_code := gr_move_data_tbl(in_shori_cnt).prod_class_code;
      END IF;
      -- 最大配送区分算出関数
      ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                       gv_cons_wh,                -- 1.コード区分１ I '4'
                                       lv_stock_rep_origin,       -- 2.入出庫場所コード１ I
                                       gv_cons_wh,                -- 3.コード区分２ I '4'
                                       lv_locat_to_code,          -- 4.入出庫場所コード２ I
                                       lv_prod_class_code,        -- 5.商品区分 I
                                       lv_weight_capacity_class,  -- 6.重量容積区分 I
                                       NULL,                      -- 7.自動配車対象区分 I
                           TO_DATE(iv_arrival_date,'YYYY/MM/DD'), -- 8.基準日(適用日基準日) I
                                       lv_max_ship_methods,       -- 9.最大配送区分 O
                                       ln_drink_deadweight,       -- 10.ドリンク積載重量 O
                                       ln_leaf_deadweight,        -- 11.リーフ積載重量 O
                                       ln_drink_loading_capacity, -- 12.ドリンク積載容積 O
                                       ln_leaf_loading_capacity,  -- 13.リーフ積載容積 O
                                       ln_palette_max_qty);       -- 14.パレット最大枚数 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method lv_stock_rep_origin = ' || lv_stock_rep_origin);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method lv_locat_to_code = ' || lv_locat_to_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method lv_prod_class_code = ' || lv_prod_class_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method lv_weight_capacity_class = ' || lv_weight_capacity_class);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method ln_ret_code = ' || ln_ret_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)get_max_ship_method lv_max_ship_methods = ' || lv_max_ship_methods);
-- DEBUG
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (ln_ret_code <> gn_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                    ,gv_msg_wsh_13009     -- 最大配送区分関数エラー
                                                    ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                    ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                    ,gv_tkn_param1        -- トークン'PARAM1'
                                                    ,gv_cons_wh           -- コード区分
                                                    ,gv_tkn_param2        -- トークン'PARAM2'
                                                    ,lv_stock_rep_origin  -- 入出庫場所コード
                                                    ,gv_tkn_param3        -- トークン'PARAM3'
                                                    ,gv_cons_wh           -- コード区分
                                                    ,gv_tkn_param4        -- トークン'PARAM4'
                                                    ,lv_locat_to_code     -- 入出庫場所コード
                                                    ,gv_tkn_param5        -- トークン'PARAM5'
                                                    ,lv_prod_class_code   -- 商品区分
                                                    ,gv_tkn_param6        -- トークン'PARAM6'
                                                    ,lv_weight_capacity_class -- 重量容積区分
                                                    ,gv_tkn_param7        -- トークン'PARAM7'
                                                    ,iv_arrival_date)     -- 基準日
                                                    ,1
                                                    ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        gn_warn_cnt := gn_warn_cnt + 1;
        -- ヘッダ作成単位の項目保持
      ln_ret_code := header_data_save(in_shori_cnt, iv_action_type );
        --最大配送区分算出関数のエラーは当プロシジャからリターンする
        RAISE common_warn_expt;
      END IF;
--
      -- 品目コードの振り分け(出荷なら)
      IF (iv_action_type = gv_cons_t_deliv) THEN
        lv_item_code := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;
        ln_quantity  := gr_deliv_data_tbl(in_shori_cnt).quantity;
      ELSE
        lv_item_code := gr_move_data_tbl(in_shori_cnt).item_code;
        ln_quantity  := gr_move_data_tbl(in_shori_cnt).instruct_qty;
      END IF;
/*      -- 積載効率チェック(合計値算出)
      xxwsh_common910_pkg.calc_total_value(
                                         lv_item_code,        -- 1.品目コード I
                                         ln_quantity,         -- 2.数量 I
                                         lv_retcode,          -- 3.リターンコード O
                                         lv_errbuf,           -- 4.エラーメッセージコード O
                                         lv_errmsg,           -- 5.エラーメッセージ O
                                         ln_sum_weight,       -- 6.合計重量 O
                                         ln_sum_capacity,     -- 7.合計容積 O
                                         ln_sum_p_weight);    -- 8.合計パレット重量 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)---------------------------------------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value in lv_item_code  = ' || lv_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value in ln_quantity = ' || ln_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out ln_sum_weight = ' || ln_sum_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out ln_sum_capacity = ' || ln_sum_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value out ln_sum_p_weight = ' || ln_sum_p_weight);
-- DEBUG
--
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                   ,gv_msg_wsh_13124     -- 積載効率関数エラー
                                                   ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                   ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                   ,gv_tkn_param1        -- トークン'PARAM1'
                                                   ,lv_item_code         -- 品目コード
                                                   ,gv_tkn_param2        -- トークン'PARAM2'
                                                   ,ln_quantity          -- 合計数量
                                                   ,gv_tkn_param3        -- トークン'PARAM3'
                                                   ,lv_errbuf            -- エラーメッセージコード
                                                   ,gv_tkn_param4        -- トークン'PARAM4'
                                                   ,lv_errmsg            -- エラーメッセージ
                                                   )
                                                   ,1
                                                   ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        gn_warn_cnt := gn_warn_cnt + 1;
        -- ヘッダ作成単位の項目保持
      ln_ret_code := header_data_save(in_shori_cnt, iv_action_type );
        --最大配送区分算出関数のエラーは当プロシジャからリターンする
        RAISE common_warn_expt;
      END IF;
*/
--
      -- 運送業者IDを検索
      OPEN  lc_carrier_id_cur;
      FETCH lc_carrier_id_cur INTO lv_career_id;
      CLOSE lc_carrier_id_cur;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)lv_career_id =' || lv_career_id);
-- DEBUG
--
      -- ##########################################################################
      -- 変数に格納する ###########################################################
      -- ##########################################################################
      -- 配列番号を＋１する
      gn_ins_data_cnt_mh := gn_ins_data_cnt_mh + 1;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)ヘッダ変数に格納です gn_ins_data_cnt_mh =' || gn_ins_data_cnt_mh);
-- DEBUG
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_hdr_id := gv_mov_hdr_id;
      -- 移動ヘッダID
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_num := lv_seq_no;-- シーケンスNo
      -- 移動番号
      gr_move_header_tbl(gn_ins_data_cnt_mh).mov_type := gv_cons_move_type; --「積送あり'1'」
      -- 移動タイプ
      gr_move_header_tbl(gn_ins_data_cnt_mh).entered_date := SYSDATE; -- システム日時
      -- 入力日
      gr_move_header_tbl(gn_ins_data_cnt_mh).instruction_post_code := iv_instruction_post_code;
      -- 指示部署                                                  -- パラメータの指示部署指定
      gr_move_header_tbl(gn_ins_data_cnt_mh).status := gv_cons_mov_sts_c; --「調整中'03'」
      -- ステータス
      gr_move_header_tbl(gn_ins_data_cnt_mh).notif_status := gv_cons_sts_mi; --「未通知'10'」
      -- 通知ステータス
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipped_locat_id := lv_stock_rep_origin_id;
      -- 出庫元ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipped_locat_code := lv_stock_rep_origin;
                                                                           -- 在庫補充元
      -- 出庫元保管場所
      gr_move_header_tbl(gn_ins_data_cnt_mh).ship_to_locat_id := lv_locat_to_id;
      -- 入庫先ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).ship_to_locat_code := lv_locat_to_code;
      -- 入庫先保管場所
      gr_move_header_tbl(gn_ins_data_cnt_mh).schedule_ship_date :=
                                    TRUNC(TO_DATE(iv_shipped_date,'YYYY/MM/DD')); --出庫日指定
      -- 出庫予定日
      gr_move_header_tbl(gn_ins_data_cnt_mh).schedule_arrival_date :=
                                    TRUNC(TO_DATE(iv_arrival_date,'YYYY/MM/DD')); -- 着日指定
      -- 入庫予定日
      gr_move_header_tbl(gn_ins_data_cnt_mh).freight_charge_class := gv_cons_umu_ari; -- 「有'1'」
      -- 運賃区分
      gr_move_header_tbl(gn_ins_data_cnt_mh).no_cont_freight_class
                                                              := gv_cons_no_cont_freight; --対象外0
      -- 契約外運賃区分
      gr_move_header_tbl(gn_ins_data_cnt_mh).shipping_method_code := lv_max_ship_methods;
      -- 配送区分
      gr_move_header_tbl(gn_ins_data_cnt_mh).organization_id := gn_organization_id; -- マスタ組織ID
      -- 組織ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).career_id := lv_career_id;
      -- 運送業者ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).freight_carrier_code := lv_frequent_mover;
      -- 運送業者
      gr_move_header_tbl(gn_ins_data_cnt_mh).based_weight := ln_leaf_deadweight; -- リーフ積載重量
      -- 基本重量
      gr_move_header_tbl(gn_ins_data_cnt_mh).based_capacity := ln_leaf_loading_capacity;
      -- 基本容積                                                                -- リーフ積載容積
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gr_move_header_tbl(gn_ins_data_cnt_mh).weight_capacity_class :=
                      gr_deliv_data_tbl(in_shori_cnt).weight_capacity_class;
        -- 重量容積区分
        gr_move_header_tbl(gn_ins_data_cnt_mh).item_class :=
                      gr_deliv_data_tbl(in_shori_cnt).prod_class_code;
        -- 商品区分
      -- 移動なら
      ELSE
        gr_move_header_tbl(gn_ins_data_cnt_mh).weight_capacity_class :=
                      gr_move_data_tbl(in_shori_cnt).weight_capacity_class;
        -- 重量容積区分
        gr_move_header_tbl(gn_ins_data_cnt_mh).item_class :=
                      gr_move_data_tbl(in_shori_cnt).prod_class_code;
        -- 商品区分
      END IF;
--
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 品目区分が製品なら
        IF (gr_deliv_data_tbl(in_shori_cnt).item_class_code = gv_cons_item_product) THEN
          gr_move_header_tbl(gn_ins_data_cnt_mh).product_flg := gv_cons_p_flg_prod; -- '1'をセット
          -- 製品識別区分
        ELSE
          gr_move_header_tbl(gn_ins_data_cnt_mh).product_flg := gv_cons_p_flg_noprod; --'2'をセット
          -- 製品識別区分
        END IF;
      -- 移動なら
      ELSE
        -- 品目区分が製品なら
        IF (gr_move_data_tbl(in_shori_cnt).item_class_code = gv_cons_item_product) THEN
          gr_move_header_tbl(gn_ins_data_cnt_mh).product_flg := gv_cons_p_flg_prod; -- '1'をセット
          -- 製品識別区分
        ELSE
          gr_move_header_tbl(gn_ins_data_cnt_mh).product_flg := gv_cons_p_flg_noprod; --'2'をセット
          -- 製品識別区分
        END IF;
      END IF;
--
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_created_by = ' || gn_created_by);
-- DEBUG
      gr_move_header_tbl(gn_ins_data_cnt_mh).comp_actual_flg := gv_cons_flg_n; --実績未計上'N'
      -- 実績計上済フラグ
      gr_move_header_tbl(gn_ins_data_cnt_mh).correct_actual_flg := gv_cons_flg_n; --実績未訂正'N'
      -- 実績訂正フラグ
      gr_move_header_tbl(gn_ins_data_cnt_mh).screen_update_by := gn_created_by;
      -- 画面更新者
      gr_move_header_tbl(gn_ins_data_cnt_mh).screen_update_date := SYSDATE;
      -- 画面更新日時
      gr_move_header_tbl(gn_ins_data_cnt_mh).created_by := gn_created_by;
      -- 作成者
      gr_move_header_tbl(gn_ins_data_cnt_mh).creation_date :=SYSDATE;
      -- 作成日
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_updated_by := gn_created_by;
      -- 最終更新者
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_update_date := SYSDATE;
      -- 最終更新日
      gr_move_header_tbl(gn_ins_data_cnt_mh).last_update_login := gn_login_user;
      -- 最終更新ログイン
      gr_move_header_tbl(gn_ins_data_cnt_mh).request_id := gn_conc_request_id;
      -- 要求ID
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_application_id := gn_prog_appl_id;
      -- コンカレントプログラムアプリケーションID
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_id := gn_conc_program_id;
      -- コンカレントプログラムID
      gr_move_header_tbl(gn_ins_data_cnt_mh).program_update_date := SYSDATE;
      -- プログラム更新日
--
      -- ヘッダ作成単位の項目保持
      ln_ret_code := header_data_save(in_shori_cnt, iv_action_type );
--
    END IF; -- ヘッダデータセット終了(合計値除く)
--
-- #############################################################################################
-- 明細データセット
-- #############################################################################################
    -- 明細を作成するかを判断する(品目コードが異なる場合)
    -- 処理種別が「出荷」
    IF (iv_action_type = gv_cons_t_deliv) THEN
      IF ((gv_item_code_ml IS NULL)
           OR
          (gv_item_code_ml <> gr_deliv_data_tbl(in_shori_cnt).shipping_item_code)) THEN
--
        -- 指示数量明細合計変数を明細単位で初期化
        gn_sum_inst_line_quantity  := 0;
--
        -- 明細作成フラグ 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- 明細番号インクリメント
        gn_line_number := gn_line_number + 1;
        -- 指示数量算出のため出荷依頼数量の足しこみ(ヘッダ)
        gn_sum_inst_quantity  :=
                gn_sum_inst_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
        -- 指示数量算出のため出荷依頼数量の足しこみ(明細)
        gn_sum_inst_line_quantity  :=
                gn_sum_inst_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
      ELSE
        -- 明細作成フラグ 'N'
        lv_line_create_flg := gv_cons_flg_n;
        -- 指示数量算出のため出荷依頼数量の足しこみ(ヘッダ)
        gn_sum_inst_quantity  :=
                gn_sum_inst_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
        -- 指示数量算出のため出荷依頼数量の足しこみ(明細)
        gn_sum_inst_line_quantity  :=
                gn_sum_inst_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
      END IF;
    -- 処理種別が「移動」
    ELSE
      IF ((gv_item_code_ml IS NULL)
           OR
          (gv_item_code_ml <> gr_move_data_tbl(in_shori_cnt).item_code)) THEN
--
        -- 指示数量明細合計変数を明細単位で初期化
        gn_sum_inst_line_quantity  := 0;
--
        -- 明細作成フラグ 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- 明細番号インクリメント
        gn_line_number := gn_line_number + 1;
        -- 指示数量算出のため移動指示数量の足しこみ(ヘッダ)
        gn_sum_inst_quantity :=
                gn_sum_inst_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
        -- 指示数量算出のため移動指示数量の足しこみ(明細)
        gn_sum_inst_line_quantity :=
                gn_sum_inst_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
      ELSE
        -- 明細作成フラグ 'N'
        lv_line_create_flg := gv_cons_flg_n;
        -- 指示数量算出のため移動指示数量の足しこみ(ヘッダ)
        gn_sum_inst_quantity :=
                gn_sum_inst_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
        -- 指示数量算出のため移動指示数量の足しこみ(明細)
        gn_sum_inst_line_quantity :=
                gn_sum_inst_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
      END IF;
    END IF;
--
    -- 明細データ作成要ならば明細を作成
    IF (lv_line_create_flg = gv_cons_flg_y) THEN
      -- **************************************************
      -- 移動依頼/指示明細登録用変数にデータをセットする
      -- **************************************************
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)明細を作ります gn_ins_data_cnt_ml =' || gn_ins_data_cnt_ml);
-- DEBUG
--
      -- シーケンスより移動明細IDを求める
      SELECT xxinv_mov_line_s1.NEXTVAL
      INTO   lv_mov_line_id
      FROM   DUAL;
--
      -- 品目コードの振り分け(出荷なら)
      IF (iv_action_type = gv_cons_t_deliv) THEN
        lv_item_code := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;
--        ln_quantity  := gr_deliv_data_tbl(in_shori_cnt).quantity;
      ELSE
        lv_item_code := gr_move_data_tbl(in_shori_cnt).item_code;
--        ln_quantity  := gr_move_data_tbl(in_shori_cnt).instruct_qty;
      END IF;
/*      -- 積載効率チェック(合計値算出)
      xxwsh_common910_pkg.calc_total_value(
                                   lv_item_code,                -- 1.品目コード
                                   gn_sum_inst_line_quantity,   -- 2.指示数量
                                   lv_retcode,                  -- 3.リターンコード O
                                   lv_errbuf,                   -- 4.エラーメッセージコード O
                                   lv_errmsg,                   -- 5.エラーメッセージ O
                                   gn_sum_weight,               -- 6.合計重量 O
                                   gn_sum_capacity,             -- 7.合計容積 O
                                   ln_sum_palette_weight);      -- 8.合計パレット重量
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)---------------------------------------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M in lv_item_code  = ' || lv_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M in ln_quantity = ' || ln_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out gn_sum_weight = ' || gn_sum_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out gn_sum_capacity = ' || gn_sum_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_total_value M out ln_sum_palette_weight = ' || ln_sum_palette_weight);
-- DEBUG
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                   ,gv_msg_wsh_13124     -- 積載効率関数エラー
                                                   ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                   ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                   ,gv_tkn_param1        -- トークン'PARAM1'
                                                   ,lv_item_code         -- 品目コード
                                                   ,gv_tkn_param2        -- トークン'PARAM2'
                                                   ,gn_sum_inst_line_quantity -- 指示数量
                                                   ,gv_tkn_param3        -- トークン'PARAM3'
                                                   ,lv_errbuf            -- エラーメッセージコード
                                                   ,gv_tkn_param4        -- トークン'PARAM4'
                                                   ,lv_errmsg            -- エラーメッセージ
                                                   )
                                                   ,1
                                                   ,5000);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
         RAISE common_warn_expt;
      END IF;
*/
--
      -- ##########################################################################
      -- 変数に格納する ###########################################################
      -- ##########################################################################
      -- 配列番号を＋１する
      gn_ins_data_cnt_ml := gn_ins_data_cnt_ml + 1;
      gr_move_lines_tbl(gn_ins_data_cnt_ml).mov_line_id := lv_mov_line_id;
      -- 移動明細ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).mov_hdr_id := gv_mov_hdr_id;
      -- 移動ヘッダID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).line_number := gn_line_number;
      -- 明細番号
      gr_move_lines_tbl(gn_ins_data_cnt_ml).organization_id := gn_organization_id;
      -- 組織ID
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gr_move_lines_tbl(gn_ins_data_cnt_ml).item_id :=
                                   gr_deliv_data_tbl(in_shori_cnt).item_id ;
        -- OPM品目ID
        gr_move_lines_tbl(gn_ins_data_cnt_ml).item_code :=
                                   gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;
        -- 品目コード
--        gr_move_lines_tbl(gn_ins_data_cnt_ml).instruct_qty := gn_sum_inst_quantity;
--        -- 指示数量
--        gr_move_lines_tbl(gn_ins_data_cnt_ml).first_instruct_qty := gn_sum_inst_quantity;
--        -- 初回指示数量
        gr_move_lines_tbl(gn_ins_data_cnt_ml).uom_code :=
                                   gr_deliv_data_tbl(in_shori_cnt).item_um;
        -- 単位
      ELSE
        gr_move_lines_tbl(gn_ins_data_cnt_ml).item_id :=
                                   gr_move_data_tbl(in_shori_cnt).item_id ;
        -- 品目ID
        gr_move_lines_tbl(gn_ins_data_cnt_ml).item_code :=
                                   gr_move_data_tbl(in_shori_cnt).item_code;
        -- 品目コード
--        gr_move_lines_tbl(gn_ins_data_cnt_ml).instruct_qty := gn_sum_inst_quantity;
--        -- 指示数量
--        gr_move_lines_tbl(gn_ins_data_cnt_ml).first_instruct_qty := gn_sum_inst_quantity;
--        -- 初回指示数量
        gr_move_lines_tbl(gn_ins_data_cnt_ml).uom_code :=
                                   gr_move_data_tbl(in_shori_cnt).item_um;
        -- 単位
      END IF;
      gr_move_lines_tbl(gn_ins_data_cnt_ml).weight := gn_sum_weight;
      -- 重量
      gr_move_lines_tbl(gn_ins_data_cnt_ml).capacity := gn_sum_capacity;
      -- 容積
      gr_move_lines_tbl(gn_ins_data_cnt_ml).delete_flg := gv_cons_flg_n; -- 'N'をセット;
      -- 取消フラグ
      gr_move_lines_tbl(gn_ins_data_cnt_ml).created_by := gn_created_by;
      -- 作成者
      gr_move_lines_tbl(gn_ins_data_cnt_ml).creation_date := SYSDATE;
      -- 作成日
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_updated_by := gn_created_by;
      -- 最終更新者
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_update_date := SYSDATE;
      -- 最終更新日
      gr_move_lines_tbl(gn_ins_data_cnt_ml).last_update_login := gn_login_user;
      -- 最終更新ログイン
      gr_move_lines_tbl(gn_ins_data_cnt_ml).request_id := gn_conc_request_id;
      -- 要求ID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_application_id := gn_prog_appl_id;
      -- コンカレントプログラムアプリケーションID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_id := gn_conc_program_id;
      -- コンカレントプログラムID
      gr_move_lines_tbl(gn_ins_data_cnt_ml).program_update_date := SYSDATE;
      -- プログラム更新日
--
      -- 明細作成単位の項目保持
      -- 処理種別が「出荷」
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gv_item_code_ml := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;
      ELSE
        gv_item_code_ml := gr_move_data_tbl(in_shori_cnt).item_code;
      END IF;
    END IF; -- 明細データ作成終了
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)明細データ作成終了');
-- DEBUG
--
-- ############################################################################################
-- 合計数量等のヘッダデータ補完
-- ############################################################################################
    -- パラメータの処理種別でパラメータを切り分ける
--    IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
--      gr_move_header_tbl(gn_ins_data_cnt_mh).sum_quantity := gn_sum_req_quantity; -- 合計依頼数量
--    ELSE
--      gr_move_header_tbl(gn_ins_data_cnt_mh).sum_quantity := gn_sum_inst_quantity; -- 合計指示数量
--    END IF;
    gr_move_header_tbl(gn_ins_data_cnt_mh).sum_quantity := gn_sum_inst_quantity; -- 合計指示数量
    gr_move_lines_tbl(gn_ins_data_cnt_ml).instruct_qty
                                                 := gn_sum_inst_line_quantity; -- 指示数量(明細)
    gr_move_lines_tbl(gn_ins_data_cnt_ml).first_instruct_qty
                                                 := gn_sum_inst_line_quantity; -- 初回指示数量(明細)
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)ヘッダデータ補完');
    IF (iv_action_type = gv_cons_t_deliv) THEN
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_sum_inst_quantity = ' || gn_sum_inst_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_sum_inst_line_quantity = ' || gn_sum_inst_line_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_deliv_data_tbl(in_shori_cnt).num_of_deliver = ' || gr_deliv_data_tbl(in_shori_cnt).num_of_deliver);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_deliv_data_tbl(in_shori_cnt).conv_unit = ' || gr_deliv_data_tbl(in_shori_cnt).conv_unit);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_deliv_data_tbl(in_shori_cnt).num_of_cases = ' || gr_deliv_data_tbl(in_shori_cnt).num_of_cases);
else
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_sum_inst_quantity = ' || gn_sum_inst_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_sum_inst_line_quantity = ' || gn_sum_inst_line_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_move_data_tbl(in_shori_cnt).num_of_deliver = ' || gr_move_data_tbl(in_shori_cnt).num_of_deliver);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_move_data_tbl(in_shori_cnt).conv_unit = ' || gr_move_data_tbl(in_shori_cnt).conv_unit);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gr_move_data_tbl(in_shori_cnt).num_of_cases = ' || gr_move_data_tbl(in_shori_cnt).num_of_cases);
end if;
-- DEBUG
    -- パラメータの処理種別で処理を切り分ける
    -- 出荷なら
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- 出荷入数に値がセットされていたら
      IF (gr_deliv_data_tbl(in_shori_cnt).num_of_deliver > 0) THEN
        gn_sum_quantity := gn_sum_inst_quantity /                 -- 合計指示数量 / 出荷入数
                                 gr_deliv_data_tbl(in_shori_cnt).num_of_deliver;
      ELSE
        -- 入出庫換算単位に値がセットされていたら
        IF (gr_deliv_data_tbl(in_shori_cnt).conv_unit IS NOT NULL) THEN
          gn_sum_quantity :=  gn_sum_inst_quantity /              -- 合計指示数量 / ケース入数
                                  NVL(gr_deliv_data_tbl(in_shori_cnt).num_of_cases, 1 );
        ELSE
          gn_sum_quantity := gn_sum_inst_quantity;
        END IF;
      END IF;
    -- 移動なら
    ELSE
      -- 出荷入数に値がセットされていたら
      IF (gr_move_data_tbl(in_shori_cnt).num_of_deliver > 0) THEN
        gn_sum_quantity := gn_sum_inst_quantity /                 -- 合計指示数量 / 出荷入数
                                 gr_move_data_tbl(in_shori_cnt).num_of_deliver;
      ELSE
        -- 入出庫換算単位に値がセットされていたら
        IF (gr_move_data_tbl(in_shori_cnt).conv_unit IS NOT NULL) THEN
          gn_sum_quantity :=  gn_sum_inst_quantity /              -- 合計指示数量 / ケース入数
                                  NVL(gr_move_data_tbl(in_shori_cnt).num_of_cases, 1 );
        ELSE
          gn_sum_quantity := gn_sum_inst_quantity;
        END IF;
      END IF;
    END IF;
    gr_move_header_tbl(gn_ins_data_cnt_mh).small_quantity := gn_sum_quantity;
    -- 小口個数
--
    gr_move_header_tbl(gn_ins_data_cnt_mh).label_quantity := gn_sum_quantity;
    -- ラベル枚数
--
    gr_move_header_tbl(gn_ins_data_cnt_mh).sum_weight := gn_sum_weight; -- 品目単位の合計重量
    -- 混載重量合計
--
    gr_move_header_tbl(gn_ins_data_cnt_mh).sum_capacity := gn_sum_capacity; -- 品目単位の合計容積
    -- 混載容積合計
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)ヘッダデータ補完 終了');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)gn_sum_quantity = ' || gn_sum_quantity);
-- DEBUG
--
  EXCEPTION
    -- *** 共通関数エラーハンドラ (警告を返す)***
    WHEN common_warn_expt THEN
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
  END regi_move_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_order_data
   * Description      : C-11 発注依頼登録
   ***********************************************************************************/
  PROCEDURE regi_order_data(
    in_shori_cnt             IN         NUMBER,     -- 処理カウンタ
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2,   -- 指示部署指定
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_order_data'; -- プログラム名
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
    ln_ret_code                 NUMBER;  -- 共通関数のリターン値
    lv_ord_line_id        xxpo_requisition_lines.requisition_line_id%TYPE;     -- 発注明細ID
    lv_seq_no                   VARCHAR2(12);                                  -- 採番関数でのOUT
    lv_vendor_id          xxcmn_vendors2_v.vendor_id%TYPE;                     -- 仕入先ID
    lv_vendor_no          xxcmn_vendors2_v.segment1%TYPE;                      -- 仕入先番号
    lv_vendor_site_id     xxcmn_vendor_sites2_v.vendor_site_id%TYPE;           -- 仕入先サイトID
    lv_employee_number    per_all_people_f.employee_number%TYPE;               -- 従業員番号
    lv_emp_dept_code      xxcmn_locations2_v.location_code%TYPE;               -- 事業所コード
    ln_odr_line_seq_id          NUMBER;                                        -- 発注明細ID
    ln_odr_line_seq_no          NUMBER;                                        -- 明細番号
    lv_stock_rep_origin   xxwsh_shipping_stock_rep_tmp.stock_rep_origin%TYPE;  -- 仕入先(補充元)
    lv_location_code         xxcmn_item_locations2_v.segment1%TYPE;            -- 入庫先(出庫元)
    lv_inventory_location_id xxcmn_item_locations2_v.inventory_location_id%TYPE; -- 保管棚ID
                                                                           -- 入庫先ID(出庫元ID)
    lv_department         xxcmn_vendors2_v.department%TYPE;                    -- 仕入先管理部署
--
    lv_header_create_flg        VARCHAR2(1);                                   -- ヘッダ作成フラグ
    lv_line_create_flg          VARCHAR2(1);                                   -- 明細作成フラグ
--
    -- *** ローカル・カーソル ***
    CURSOR lc_vendor_cur  -- 仕入先ID,仕入先サイトID,仕入先番号,部署を検索する
    IS
      SELECT xvv.vendor_id,                      -- 仕入先ID(No.4で使用)
             xvsv.vendor_site_id,                -- 仕入先サイトID(No.6で使用)
             xvv.segment1,                       -- 仕入先番号(No.5で使用)
             xvv.department                      -- 部署(No.14で使用)
      FROM   xxcmn_vendor_sites2_v  xvsv,        -- 仕入先サイト情報View2
             xxcmn_vendors2_v       xvv          -- 仕入先情報View2
      WHERE  xvsv.vendor_site_code   = lv_stock_rep_origin -- 在庫補充元=仕入先サイト名
        AND  xvsv.vendor_id          = xvv.vendor_id         -- 仕入先ID
        AND  xvsv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD') -- 着日指定
        AND  ((xvsv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))-- で範囲内であること
              OR
              (xvsv.end_date_active IS NULL))
        AND  xvv.start_date_active  <= TO_DATE(iv_arrival_date,'YYYY/MM/DD') -- 着日指定
        AND  ((xvv.end_date_active  >= TO_DATE(iv_arrival_date,'YYYY/MM/DD')) -- で範囲内であること
             OR
              (xvv.end_date_active  IS NULL))
        AND  ROWNUM        = 1;
--
    CURSOR lc_il_id_cur  -- 保管棚IDを検索する
    IS
      SELECT xilv.inventory_location_id            -- 保管棚ID(No.8で使用)
      FROM   xxcmn_item_locations2_v  xilv         -- OPM保管場所情報View2
      WHERE  xilv.segment1   = lv_location_code    -- 入庫先(出庫元)
        AND  xilv.date_from <= TO_DATE(iv_arrival_date,'YYYY/MM/DD')     -- 着日指定
        AND  ((xilv.date_to   >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))  --
               OR                                                        --
              (xilv.date_to   IS NULL))                                  -- で範囲内であること
        AND  ROWNUM          = 1;
--
    CURSOR lc_user_cur  -- 従業員番号と事業所コードを検索する
    IS
      SELECT papf.employee_number,  -- 従業員番号(No.12で使用)
             xlv.location_code      -- 事業所コード(No.13で使用)
      FROM   fnd_user               fu,     -- ユーザマスタ
             per_all_people_f       papf,   -- 従業員マスタ
             per_all_assignments_f  paaf,   -- 従業員アサイメントマスタ
             xxcmn_locations2_v     xlv     -- 事業所情報VIEW2
      WHERE  fu.user_id           =  gn_created_by
        AND  fu.employee_id       =  papf.person_id
        AND  papf.person_id       =  paaf.person_id
        AND  paaf.location_id     =  xlv.location_id
        AND  xlv.location_id      <> xlv.parent_location_id
        AND  xlv.parent_location_id IS NOT NULL
        AND  ((papf.effective_start_date <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (papf.effective_start_date IS NULL))
        AND  ((papf.effective_end_date >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (papf.effective_end_date IS NULL))
        AND  ((paaf.effective_start_date <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (paaf.effective_start_date IS NULL))
        AND  ((paaf.effective_end_date >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (paaf.effective_end_date IS NULL))
        AND  ((xlv.start_date_active <= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (xlv.start_date_active IS NULL))
        AND  ((xlv.end_date_active >= TO_DATE(iv_arrival_date,'YYYY/MM/DD'))
               OR
              (xlv.end_date_active IS NULL))
        AND  ROWNUM           = 1;
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
-- ############################################################################################
-- ヘッダデータセット
-- ############################################################################################
--
    -- ヘッダを作成するかを判断する(在庫補充元、出荷元コードのどれがが異なる場合)
    -- 処理種別が「出荷」
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)in_shori_cnt = ' || in_shori_cnt || ' レコード目処理開始');FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)iv_action_type = ' || iv_action_type);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gn_stock_rep_origin_o = ' || gn_stock_rep_origin_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_stock_rep_rule_o = ' || gv_stock_rep_rule_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_from_o = ' || gv_deliver_from_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_to_o = ' || gv_deliver_to_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)+++++++++++++++++++++++++++++++++++++++++++++++++++++');
-- DEBUG
    IF ((iv_action_type = gv_cons_t_deliv)
         AND 
        (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div = gv_cons_ds_type_d)) THEN
      IF ((gn_stock_rep_origin_o IS NULL)                 -- 1件目のヘッダ作成時
         OR                                              -- 以下のどれかの項目が異なる
         ((gn_stock_rep_origin_o      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_o        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_o          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)
          OR
          (gv_deliver_to_o            <> gr_deliv_data_tbl(in_shori_cnt).deliver_to)))
      THEN
        lv_stock_rep_origin  := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
        lv_header_create_flg := gv_cons_flg_y;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - header_creat - 直送');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gn_stock_rep_origin_o = ' || gn_stock_rep_origin_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_stock_rep_rule_o = ' || gv_stock_rep_rule_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_from_o = ' || gv_deliver_from_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).deliver_from = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_to_o = ' || gv_deliver_to_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).deliver_to = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_to);
-- DEBUG
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - header_not_creat - 直送');
-- DEBUG
      END IF;
    ELSIF ((iv_action_type = gv_cons_t_deliv) 
         AND 
        (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div <> gv_cons_ds_type_d)) THEN
      IF ((gn_stock_rep_origin_o IS NULL)                 -- 1件目のヘッダ作成時
          OR                                              -- 以下のどれかの項目が異なる
         ((gn_stock_rep_origin_o      <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin)
          OR
          (gv_stock_rep_rule_o        <> gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule)
          OR
          (gv_deliver_from_o          <> gr_deliv_data_tbl(in_shori_cnt).deliver_from)))
      THEN
        lv_stock_rep_origin  := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
        lv_header_create_flg := gv_cons_flg_y;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - header_creat - 直送以外');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gn_stock_rep_origin_o = ' || gn_stock_rep_origin_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_stock_rep_rule_o = ' || gv_stock_rep_rule_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule = ' || gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_from_o = ' || gv_deliver_from_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).deliver_from = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
-- DEBUG
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - header_not_creat- 直送以外');
-- DEBUG
      END IF;
    -- 処理種別が「移動」
    ELSE
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)ELSE............');
      IF ((gn_stock_rep_origin_o IS NULL)                -- 1件目のヘッダ作成時
         OR                                              -- 以下のどれかの項目が異なる
         ((gn_stock_rep_origin_o      <> gr_move_data_tbl(in_shori_cnt).stock_rep_origin)
           OR
          (gv_stock_rep_rule_o        <> gr_move_data_tbl(in_shori_cnt).stock_rep_rule)
           OR
          (gv_deliver_from_o          <> gr_move_data_tbl(in_shori_cnt).shipped_locat_code)))
      THEN
        lv_stock_rep_origin  := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
        lv_header_create_flg := gv_cons_flg_y;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_move - header_creat - 移動');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gn_stock_rep_origin_o = ' || gn_stock_rep_origin_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_move_data_tbl(in_shori_cnt).stock_rep_origin = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_origin);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_stock_rep_rule_o = ' || gv_stock_rep_rule_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_move_data_tbl(in_shori_cnt).stock_rep_rule = ' || gr_move_data_tbl(in_shori_cnt).stock_rep_rule);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_deliver_from_o = ' || gv_deliver_from_o);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_move_data_tbl(in_shori_cnt).shipped_locat_code = ' || gr_move_data_tbl(in_shori_cnt).shipped_locat_code);
-- DEBUG
      ELSE
        lv_header_create_flg := gv_cons_flg_n;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_move - header_not_creat - 移動');
-- DEBUG
      END IF;
    END IF;
--
    -- ヘッダ作成要の場合
    IF (lv_header_create_flg = gv_cons_flg_y) THEN
      -- **************************************************
      -- 発注依頼ヘッダ登録用変数にデータをセットする
      -- **************************************************
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)header(Y) - gn_ins_data_cnt_oh = ' || gn_ins_data_cnt_oh);
-- DEBUG
--
      -- 指示数量合計変数をヘッダ単位で初期化
      gn_sum_req_quantity  := 0;
      -- 明細番号初期化
      gn_line_number      := 0;
--
      -- シーケンスより発注ヘッダIDを求める
      SELECT xxpo_requisition_headers_s1.NEXTVAL
      INTO   gv_odr_hdr_id
      FROM   DUAL;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - gv_odr_hdr_id = ' || gv_odr_hdr_id);
-- DEBUG
      -- 採番関数
      xxcmn_common_pkg.get_seq_no( gv_cons_seq_order,
                                   lv_seq_no,
                                   lv_errbuf,
                                   lv_retcode,
                                   lv_errmsg);
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_cons_t_deliv - get_seq_no = ' || lv_seq_no);
-- DEBUG
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                      ,gv_msg_wsh_13008     -- 採番関数エラー
                                                      ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,gv_cons_odr_hdr_tbl  -- 発注依頼ヘッダ
                                                      ,gv_tkn_param1        -- トークン'PARAM1'
                                                      ,gv_cons_seq_move     -- 採番区分「移動」
                                                      ,gv_tkn_param2        -- トークン'PARAM2'
                                                      ,lv_retcode           -- リターンコード
                                                      ,gv_tkn_param3        -- トークン'PARAM3'
                                                      ,lv_errmsg)           -- メッセージ
                                                      ,1
                                                      ,5000);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
         RAISE common_warn_expt;
      END IF;
--
      -- キーの在庫補充元を処理種別により切り分ける
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        lv_stock_rep_origin := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
      ELSE
        lv_stock_rep_origin := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
      END IF;
--
      -- 仕入先ID, 仕入先サイトID, 仕入先番号, 部署を検索する
      OPEN  lc_vendor_cur;
      FETCH lc_vendor_cur INTO lv_vendor_id, lv_vendor_site_id, lv_vendor_no, lv_department;
      CLOSE lc_vendor_cur;
--
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################lv_location_code = ' || lv_location_code);
      IF (iv_action_type = gv_cons_t_deliv) THEN -- 出荷なら
        lv_location_code    := gr_deliv_data_tbl(in_shori_cnt).deliver_from;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################gr_deliv_data_tbl(in_shori_cnt).deliver_from = ' || gr_deliv_data_tbl(in_shori_cnt).deliver_from);
      ELSE
        lv_location_code    := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################gr_move_data_tbl(in_shori_cnt).shipped_locat_code = ' || gr_move_data_tbl(in_shori_cnt).shipped_locat_code);
      END IF;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)##################lv_location_code = ' || lv_location_code);
-- DEBUG
      -- 保管棚IDを検索
      OPEN  lc_il_id_cur;
      FETCH lc_il_id_cur INTO lv_inventory_location_id;
      CLOSE lc_il_id_cur;
--
      -- 従業員番号と事業所コードを検索
      OPEN  lc_user_cur;
      FETCH lc_user_cur INTO lv_employee_number, lv_emp_dept_code;
      CLOSE lc_user_cur;
--
      -- ##########################################################################
      -- 変数に格納する ###########################################################
      -- ##########################################################################
      -- 配列番号を＋１する
      gn_ins_data_cnt_oh := gn_ins_data_cnt_oh + 1;
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).requisition_header_id := gv_odr_hdr_id;
      -- 発注依頼ヘッダID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).po_header_number := lv_seq_no;
      -- 発注番号
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).status := gv_cons_po_sts; --依頼作成済'10'
      -- ステータス
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).vendor_id := lv_vendor_id;
      -- 仕入先ID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).vendor_code := lv_vendor_no;
      -- 仕入先コード
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).vendor_site_id := lv_vendor_site_id;
      -- 仕入先サイトID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).promised_date :=
                                            TO_DATE(iv_arrival_date,'YYYY/MM/DD'); -- 着日指定
      -- 納入日
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).location_id := lv_inventory_location_id;
      -- 納入先ID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).location_code := lv_location_code;
      -- 納入先コード
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        -- 直送区分が「直送」だったら「出荷」をセット
        IF (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div = gv_cons_ds_type_d) THEN
          gr_requisition_header_tbl(gn_ins_data_cnt_oh).drop_ship_type := gv_cons_ds_deliv;
          gr_requisition_header_tbl(gn_ins_data_cnt_oh).delivery_code :=
                                gr_deliv_data_tbl(in_shori_cnt).deliver_to; -- 出荷先コード
          -- 配送先コード
        END IF;
        -- 直送区分が「直送以外」かNULLならば「通常」をセット
        IF (gr_deliv_data_tbl(in_shori_cnt).drop_ship_wsh_div = gv_cons_ds_type_n) THEN
          gr_requisition_header_tbl(gn_ins_data_cnt_oh).drop_ship_type := gv_cons_ds_normal;
        END IF;
      ELSE
        -- 「通常」をセット
        gr_requisition_header_tbl(gn_ins_data_cnt_oh).drop_ship_type := gv_cons_ds_normal;
      END IF;
      -- 直送区分
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).requested_by_code := lv_employee_number;
      -- 依頼者コード
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).requested_dept_code := lv_emp_dept_code;
      -- 依頼者部署コード
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).requested_to_department_code := lv_department;
      -- 依頼先部署コード
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).change_flag := gv_change_flag_n;
      -- 変更フラグ
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).created_by := gn_created_by;
      -- 作成者
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).creation_date := SYSDATE;
      -- 作成日
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).last_updated_by := gn_created_by;
      -- 最終更新者
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).last_update_date := SYSDATE;
      -- 最終更新日
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).last_update_login := gn_login_user;
      -- 最終更新ログイン
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).request_id := gn_conc_request_id;
      -- 要求ID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).program_application_id := gn_prog_appl_id;
      -- アプリケーションID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).program_id := gn_conc_program_id;
      -- プログラムID
      gr_requisition_header_tbl(gn_ins_data_cnt_oh).program_update_date := SYSDATE;
      -- プログラム更新日
      -- ヘッダ作成単位の項目保持
      -- 処理種別が「出荷」
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gn_stock_rep_origin_o      := gr_deliv_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                                 -- 在庫補充元
        gv_deliver_from_o          := gr_deliv_data_tbl(in_shori_cnt).deliver_from;
                                                                                 -- 出荷元コード
        gv_deliver_to_o            := gr_deliv_data_tbl(in_shori_cnt).deliver_to;
                                                                                 -- 出荷先コード
        gv_stock_rep_rule_o        := gr_deliv_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                                 -- 在庫補充ルール
      ELSE
        gn_stock_rep_origin_o      := gr_move_data_tbl(in_shori_cnt).stock_rep_origin;
                                                                                 -- 在庫補充元
        gv_deliver_from_o          := gr_move_data_tbl(in_shori_cnt).shipped_locat_code;
                                                                                 -- 出荷元コード
        gv_deliver_to_o            := gr_move_data_tbl(in_shori_cnt).ship_to_locat_code;
                                                                                 -- 出荷先コード
        gv_stock_rep_rule_o        := gr_move_data_tbl(in_shori_cnt).stock_rep_rule;
                                                                                 -- 在庫補充ルール
      END IF;
--
    END IF;  -- ヘッダデータセット終了
--
-- #############################################################################################
-- 明細データセット
-- #############################################################################################
    -- 明細を作成するかを判断する(品目コードが異なる場合)
    -- 処理種別が「出荷」
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gv_item_code_ol = ' || gv_item_code_ol);
-- DEBUG
    IF (iv_action_type = gv_cons_t_deliv) THEN
      IF (((gv_item_code_ol IS NULL) OR (lv_header_create_flg = gv_cons_flg_y))
           OR
           (gv_item_code_ol <> gr_deliv_data_tbl(in_shori_cnt).shipping_item_code))
      THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line_deliv_Y = ' || gv_item_code_ol);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_deliv_data_tbl(in_shori_cnt).shipping_item_code = ' || gr_deliv_data_tbl(in_shori_cnt).shipping_item_code);
-- DEBUG
--
        -- 依頼数量明細合計変数を明細単位で初期化
        gn_sum_req_line_quantity  := 0;
--
        -- 明細作成フラグ 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- 明細番号インクリメント
        gn_line_number := gn_line_number + 1;
        -- 依頼数量の足しこみ(ヘッダ)
        gn_sum_req_quantity :=
                gn_sum_req_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
        -- 依頼数量の足しこみ(明細)
        gn_sum_req_line_quantity :=
                gn_sum_req_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
--        gn_sum_inst_quantity :=
--                gn_sum_req_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
      ELSE
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line_deliv_N = ' || gv_item_code_ol);
-- DEBUG
        -- 明細作成フラグ 'N'
        lv_line_create_flg := gv_cons_flg_n;
--
        -- 依頼数量の足しこみ(ヘッダ)
        gn_sum_req_quantity  :=
                gn_sum_req_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
        -- 依頼数量の足しこみ(明細)
        gn_sum_req_line_quantity  :=
                gn_sum_req_line_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
--        gn_sum_inst_quantity  :=
--                gn_sum_req_quantity  + gr_deliv_data_tbl(in_shori_cnt).quantity;
      END IF;
    -- 処理種別が「移動」
    ELSE
      IF (((gv_item_code_ol IS NULL) OR (lv_header_create_flg = gv_cons_flg_y))
           OR
           (gv_item_code_ol <> gr_move_data_tbl(in_shori_cnt).item_code))
      THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line_move_Y = ' || gv_item_code_ol);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)gr_move_data_tbl(in_shori_cnt).item_code = ' || gr_move_data_tbl(in_shori_cnt).item_code);
-- DEBUG
        -- 依頼数量明細合計変数を明細単位で初期化
        gn_sum_req_line_quantity  := 0;
--
        -- 明細作成フラグ 'Y'
        lv_line_create_flg := gv_cons_flg_y;
        -- 明細番号インクリメント
        gn_line_number := gn_line_number + 1;
        -- 依頼数量の足しこみ(ヘッダ)
        gn_sum_req_quantity :=
                gn_sum_req_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
        -- 依頼数量の足しこみ(明細)
        gn_sum_req_line_quantity :=
                gn_sum_req_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
--        gn_sum_inst_quantity :=
--                gn_sum_inst_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
      ELSE
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line_move_N = ' || gv_item_code_ol);
-- DEBUG
        -- 明細作成フラグ 'N'
        lv_line_create_flg := gv_cons_flg_n;
        -- 依頼数量の足しこみ(ヘッダ)
        gn_sum_req_quantity :=
                gn_sum_req_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
        -- 依頼数量の足しこみ(明細)
        gn_sum_req_line_quantity :=
                gn_sum_req_line_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
--        gn_sum_inst_quantity :=
--                gn_sum_inst_quantity + gr_move_data_tbl(in_shori_cnt).instruct_qty;
      END IF;
    END IF;
--
    -- 明細データ作成要ならば明細を作成
    IF (lv_line_create_flg = gv_cons_flg_y) THEN
--
      -- 配列番号を＋１する
      gn_ins_data_cnt_ol := gn_ins_data_cnt_ol + 1;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line(Y) - gn_ins_data_cnt_ol = ' || gn_ins_data_cnt_ol);
-- DEBUG
--
      -- シーケンスより発注依頼明細IDを求める
      SELECT xxpo_requisition_lines_s1.NEXTVAL
      INTO   lv_ord_line_id
      FROM   DUAL;
--
      -- 明細番号(明細ごとに振られるシーケンス番号)をインクリメントする
      gn_order_line_number := gn_order_line_number + 1;
--
      -- 発注依頼明細登録用変数にデータをセットする
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requisition_line_id := lv_ord_line_id;
      -- 発注依頼明細ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requisition_header_id := gv_odr_hdr_id;
      -- 発注依頼ヘッダID
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requisition_line_number := gn_line_number;
      -- 明細番号
      -- 出荷なら
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).item_id :=
                         gr_deliv_data_tbl(in_shori_cnt).item_id ;
        -- 品目ID
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).item_code :=
                         gr_deliv_data_tbl(in_shori_cnt).shipping_item_code ;
        -- 品目コード
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).pack_quantity :=
                         gr_deliv_data_tbl(in_shori_cnt).frequent_qty ;
        -- 在庫入数
--        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity := gn_sum_inst_quantity;
--        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity := gn_sum_req_quantity;
--        -- 依頼数量
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity_uom :=
                         gr_deliv_data_tbl(in_shori_cnt).item_um;
        -- 依頼数量単位コード
      ELSE
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).item_id :=
                         gr_move_data_tbl(in_shori_cnt).item_id ;
        -- 品目ID
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).item_code :=
                         gr_move_data_tbl(in_shori_cnt).item_code ;
        -- 品目コード
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).pack_quantity :=
                         gr_move_data_tbl(in_shori_cnt).frequent_qty ;
        -- 在庫入数
--        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity := gn_sum_inst_quantity;
--        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity := gn_sum_req_quantity;
--        -- 依頼数量
        gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity_uom :=
                         gr_move_data_tbl(in_shori_cnt).item_um;
        -- 依頼数量単位コード
      END IF;
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line(Y) - gn_sum_inst_quantity = ' || gn_sum_inst_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line(Y) - gn_sum_req_quantity = ' || gn_sum_req_quantity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)line(Y) - gn_sum_req_line_quantity = ' || gn_sum_req_line_quantity);
-- DEBUG
--
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).cancelled_flg := gv_cons_flg_n; -- 'N'をセット
      -- 取消フラグ
--
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).created_by := gn_created_by;
      -- 作成者
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).creation_date := SYSDATE;
      -- 作成日
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).last_updated_by := gn_created_by;
      -- 最終更新者
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).last_update_date := SYSDATE;
      -- 最終更新日
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).last_update_login := gn_login_user;
      -- 最終更新ログイン
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).request_id := gn_conc_request_id;
      -- 要求ID
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).program_application_id := gn_prog_appl_id;
      -- アプリケーションID
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).program_id := gn_conc_program_id;
      -- プログラムID
      gr_requisition_lines_tbl(gn_ins_data_cnt_ol).program_update_date := SYSDATE;
      -- プログラム更新日
--
      -- 明細作成単位の項目保持
      -- 処理種別が「出荷」
      IF (iv_action_type = gv_cons_t_deliv) THEN
        gv_item_code_ol := gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;
      ELSE
        gv_item_code_ol := gr_move_data_tbl(in_shori_cnt).item_code;
      END IF;
    END IF;   -- 明細データ作成終了
--
-- ############################################################################################
-- 明細単位の合計数量を補完
-- ############################################################################################
    gr_requisition_lines_tbl(gn_ins_data_cnt_ol).requested_quantity := gn_sum_req_line_quantity;
                                                                                         -- 明細数量
--
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-11)明細データ作成終了');
-- DEBUG
--
  EXCEPTION
    -- *** 共通関数エラーハンドラ (警告を返す)***
    WHEN common_warn_expt THEN
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
  END regi_order_data;
--
   /**********************************************************************************
   * Procedure Name   : regi_order_detail
   * Description      : C-12 受注明細更新
   ***********************************************************************************/
  PROCEDURE regi_order_detail(
    in_shori_cnt           IN         NUMBER,     -- 処理カウンタ
    iv_move_number         IN        VARCHAR2,     -- 移動番号
    iv_po_number           IN        VARCHAR2,     -- 発注番号
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_order_detail'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 受注明細更新対象件数を＋１する
    gn_upd_data_cnt_ol := gn_upd_data_cnt_ol + 1;
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-12)gn_upd_data_cnt_ol = ' || gn_upd_data_cnt_ol);
-- DEBUG
--
    -- 各レコード変数にデータをセットする
    -- キー項目をセットする
    gt_ol_request_no(gn_upd_data_cnt_ol) :=
                       gr_deliv_data_tbl(in_shori_cnt).request_no;          -- 依頼No（キー）
    gt_ol_shipping_item_code(gn_upd_data_cnt_ol) :=
                       gr_deliv_data_tbl(in_shori_cnt).shipping_item_code;  -- 品目コード（キー）
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-12)gt_ol_request_no(gn_upd_data_cnt_ol) = ' || gt_ol_request_no(gn_upd_data_cnt_ol));
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-12)gt_ol_shipping_item_code(gn_upd_data_cnt_ol) = ' || gt_ol_shipping_item_code(gn_upd_data_cnt_ol));
-- DEBUG
    gt_ol_move_number(gn_upd_data_cnt_ol)            := iv_move_number;     -- 移動No
    gt_ol_po_number(gn_upd_data_cnt_ol)              := iv_po_number;       -- 発注No
    gt_ol_last_updated_by(gn_upd_data_cnt_ol)        := gn_created_by;      -- 最終更新者
    gt_ol_last_update_date(gn_upd_data_cnt_ol)       := SYSDATE;            -- 最終更新日
    gt_ol_last_update_login(gn_upd_data_cnt_ol)      := gn_login_user;      -- 最終更新ログイン
    gt_ol_request_id(gn_upd_data_cnt_ol)             := gn_conc_request_id; -- 要求ID
    gt_ol_program_application_id(gn_upd_data_cnt_ol) := gn_prog_appl_id;    -- アプリケーションID
    gt_ol_program_id(gn_upd_data_cnt_ol)             := gn_conc_program_id; -- プログラムID
    gt_ol_program_update_date(gn_upd_data_cnt_ol)    := SYSDATE;            -- プログラム更新日
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
  END regi_order_detail;
--
   /**********************************************************************************
   * Procedure Name   : regi_move_detail
   * Description      : C-13 移動指示/指示明細更新
   ***********************************************************************************/
  PROCEDURE regi_move_detail(
    in_shori_cnt           IN         NUMBER,     -- 処理カウンタ
    iv_move_number         IN        VARCHAR2,     -- 移動番号
    iv_po_number           IN        VARCHAR2,     -- 発注番号
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regi_move_detail'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 移動依頼/指示明細更新対象件数を＋１する
    gn_upd_data_cnt_ml := gn_upd_data_cnt_ml + 1;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-13)gn_upd_data_cnt_ml = ' || gn_upd_data_cnt_ml);
-- DEBUG
    -- 各レコード変数にデータをセットする
    -- キー項目をセットする
    gt_ml_mov_num(gn_upd_data_cnt_ml) :=
                       gr_move_data_tbl(in_shori_cnt).mov_num;  -- 移動番号（キー）
    gt_ml_item_code(gn_upd_data_cnt_ml) :=
                       gr_move_data_tbl(in_shori_cnt).item_code;  -- 品目コード（キー）
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-13)gt_ml_mov_num(gn_upd_data_cnt_ml) = ' || gt_ml_mov_num(gn_upd_data_cnt_ml));
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-13)gt_ml_item_code(gn_upd_data_cnt_ml) = ' || gt_ml_item_code(gn_upd_data_cnt_ml));
-- DEBUG
--
    gt_ml_move_num(gn_upd_data_cnt_ml)               := iv_move_number;     -- 参照移動番号
    gt_ml_po_num(gn_upd_data_cnt_ml)                 := iv_po_number;       -- 参照発注番号
    gt_ml_last_updated_by(gn_upd_data_cnt_ml)        := gn_created_by;      -- 最終更新者
    gt_ml_last_update_date(gn_upd_data_cnt_ml)       := SYSDATE;            -- 最終更新日
    gt_ml_last_update_login(gn_upd_data_cnt_ml)      := gn_login_user;      -- 最終更新ログイン
    gt_ml_request_id(gn_upd_data_cnt_ml)             := gn_conc_request_id; -- 要求ID
    gt_ml_program_application_id(gn_upd_data_cnt_ml) := gn_prog_appl_id;    -- アプリケーションID
    gt_ml_program_id(gn_upd_data_cnt_ml)             := gn_conc_program_id; -- プログラムID
    gt_ml_program_update_date(gn_upd_data_cnt_ml)    := SYSDATE;            -- プログラム更新日
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
  END regi_move_detail;
--
   /**********************************************************************************
   * Procedure Name   : insert_tables
   * Description      : C-14 登録更新処理
   ***********************************************************************************/
  PROCEDURE insert_tables(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tables'; -- プログラム名
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
    ln_data_cnt    NUMBER;
    ln_search_cnt  NUMBER;
    lv_line_ins_flg VARCHAR2(1);
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
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gn_ins_data_cnt_mh = ' || gn_ins_data_cnt_mh);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gn_ins_data_cnt_ml = ' || gn_ins_data_cnt_ml);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gn_ins_data_cnt_oh = ' || gn_ins_data_cnt_oh);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gn_ins_data_cnt_ol = ' || gn_ins_data_cnt_ol);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gn_upd_data_cnt_ml = ' || gn_upd_data_cnt_ml);
-- DEBUG
    -- FORALLで使用できるようにレコード変数を分割格納する
    <<ln_ins_cnt_loop>>
    FOR ln_data_cnt IN 1..gn_ins_data_cnt_mh LOOP
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_move_header_tbl(ln_data_cnt).not_insert_flg = ' || gr_move_header_tbl(ln_data_cnt).not_insert_flg);
-- DEBUG
      IF (gr_move_header_tbl(ln_data_cnt).not_insert_flg <> gv_cons_flg_on) THEN
      gt_h_mov_hdr_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).mov_hdr_id;                  -- 移動ヘッダID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)ln_data_cnt(mh) = ' || ln_data_cnt);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_move_header_tbl(ln_data_cnt).mov_hdr_id = ' || gr_move_header_tbl(ln_data_cnt).mov_hdr_id);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_move_header_tbl(ln_data_cnt).created_by = ' || gr_move_header_tbl(ln_data_cnt).created_by);
-- DEBUG
      gt_h_mov_num(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).mov_num;                     -- 移動番号
      gt_h_mov_type(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).mov_type;                    -- 移動タイプ
      gt_h_entered_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).entered_date;                -- 入力日
      gt_h_instruction_post_code(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).instruction_post_code;       -- 指示部署
      gt_h_status(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).status;                      -- ステータス
      gt_h_notif_status(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).notif_status;                -- 通知ステータス
      gt_h_shipped_locat_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).shipped_locat_id;            -- 出庫元ID
      gt_h_shipped_locat_code(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).shipped_locat_code;          -- 出庫元保管場所
      gt_h_ship_to_locat_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).ship_to_locat_id;            -- 入庫先ID
      gt_h_ship_to_locat_code(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).ship_to_locat_code;          -- 入庫先保管場所
      gt_h_schedule_ship_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).schedule_ship_date;          -- 出庫予定日
      gt_h_schedule_arrival_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).schedule_arrival_date;       -- 入庫予定日
      gt_h_freight_charge_class(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).freight_charge_class;        -- 運賃区分
      gt_h_collected_pallet_qty(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).collected_pallet_qty;        -- パレット回収枚数
      gt_h_out_pallet_qty(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).out_pallet_qty;              -- パレット枚数(出)
      gt_h_in_pallet_qty(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).in_pallet_qty;               -- パレット枚数(入)
      gt_h_no_cont_freight_class(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).no_cont_freight_class;       -- 契約外運賃区分
      gt_h_delivery_no(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).delivery_no;                 -- 配送No
      gt_h_description(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).description;                 -- 摘要
      gt_h_loading_efficiency_weight(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).loading_efficiency_weight;   -- 積載率(重量)
      gt_h_loading_efficiency_capa(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).loading_efficiency_capacity; -- 積載率(容積)
      gt_h_organization_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).organization_id;             -- 組織ID
      gt_h_career_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).career_id;                   -- 運送業者ID
      gt_h_freight_carrier_code(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).freight_carrier_code;        -- 運送業者
      gt_h_shipping_method_code(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).shipping_method_code;        -- 配送区分
      gt_h_actual_career_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).actual_career_id;            -- 運送業者ID_実績
      gt_h_actual_freight_carrier_cd(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).actual_freight_carrier_code; -- 運送業者_実績
      gt_h_actual_shipping_method_cd(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).actual_shipping_method_code; -- 配送区分_実績
      gt_h_arrival_time_from(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).arrival_time_from;           -- 着荷時間FROM
      gt_h_arrival_time_to(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).arrival_time_to;             -- 着荷時間TO
      gt_h_slip_number(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).slip_number;                 -- 送り状No
      gt_h_sum_quantity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).sum_quantity;                -- 合計数量
      gt_h_small_quantity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).small_quantity;              -- 小口個数
      gt_h_label_quantity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).label_quantity;              -- ラベル枚数
      gt_h_based_weight(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).based_weight;                -- 基本重量
      gt_h_based_capacity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).based_capacity;              -- 基本容積
      gt_h_sum_weight(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).sum_weight;                  -- 混載重量合計
      gt_h_sum_capacity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).sum_capacity;                -- 混載容積合計
      gt_h_sum_pallet_weight(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).sum_pallet_weight;           -- 合計パレット重量
      gt_h_pallet_sum_quantity(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).pallet_sum_quantity;         -- パレット合計枚数
      gt_h_mixed_ratio(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).mixed_ratio;                 -- 混載率
      gt_h_weight_capacity_class(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).weight_capacity_class;       -- 重量容積区分
      gt_h_actual_ship_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).actual_ship_date;            -- 出庫実績日
      gt_h_actual_arrival_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).actual_arrival_date;         -- 入庫実績日
      gt_h_mixed_sign(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).mixed_sign;                  -- 混載記号
      gt_h_batch_no(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).batch_no;                    -- 手配No
      gt_h_item_class(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).item_class;                  -- 商品区分
      gt_h_product_flg(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).product_flg;                 -- 製品識別区分
      gt_h_no_instr_actual_class(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).no_instr_actual_class;       -- 指示なし実績区分
      gt_h_comp_actual_flg(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).comp_actual_flg;             -- 実績計上済フラグ
      gt_h_correct_actual_flg(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).correct_actual_flg;          -- 実績訂正フラグ
      gt_h_prev_notif_status(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).prev_notif_status;           -- 前回通知ステータス
      gt_h_notif_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).notif_date;                  -- 確定通知実績日時
      gt_h_prev_delivery_no(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).prev_delivery_no;            -- 前回配送No
      gt_h_new_modify_flg(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).new_modify_flg;              -- 新規修正フラグ
      gt_h_screen_update_by(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).screen_update_by;            -- 画面更新者
      gt_h_screen_update_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).screen_update_date;          -- 画面更新日時
      gt_h_created_by(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).created_by;                  -- 作成者
      gt_h_creation_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).creation_date;               -- 作成日
      gt_h_last_updated_by(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).last_updated_by;             -- 最終更新者
      gt_h_last_update_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).last_update_date;            -- 最終更新日
      gt_h_last_update_login(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).last_update_login;           -- 最終更新ログイン
      gt_h_request_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).request_id;                  -- 要求ID
      gt_h_program_application_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).program_application_id;
                                                       -- コンカレントプログラムアプリケーションID
      gt_h_program_id(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).program_id;                  -- コンカレントプログラムID
      gt_h_program_update_date(ln_data_cnt) :=
          gr_move_header_tbl(ln_data_cnt).program_update_date;         -- プログラム更新日
    END IF;
    END LOOP ln_ins_cnt_loop;
--
    -- ヘッダを読み飛ばす部分があるので計算しなおす
    gn_ins_data_cnt_mh := gt_h_mov_hdr_id.COUNT;
    -- FORALLにて移動依頼/指示ヘッダをINSERTする
    FORALL ln_data_cnt IN 1..gn_ins_data_cnt_mh
      INSERT INTO xxinv_mov_req_instr_headers(
        mov_hdr_id,                  -- 移動ヘッダID
        mov_num,                     -- 移動番号
        mov_type,                    -- 移動タイプ
        entered_date,                -- 入力日
        instruction_post_code,       -- 指示部署
        status,                      -- ステータス
        notif_status,                -- 通知ステータス
        shipped_locat_id,            -- 出庫元ID
        shipped_locat_code,          -- 出庫元保管場所
        ship_to_locat_id,            -- 入庫先ID
        ship_to_locat_code,          -- 入庫先保管場所
        schedule_ship_date,          -- 出庫予定日
        schedule_arrival_date,       -- 入庫予定日
        freight_charge_class,        -- 運賃区分
        collected_pallet_qty,        -- パレット回収枚数
        out_pallet_qty,              -- パレット枚数(出)
        in_pallet_qty,               -- パレット枚数(入)
        no_cont_freight_class,       -- 契約外運賃区分
        delivery_no,                 -- 配送No
        description,                 -- 摘要
        loading_efficiency_weight,   -- 積載率(重量)
        loading_efficiency_capacity, -- 積載率(容積)
        organization_id,             -- 組織ID
        career_id,                   -- 運送業者ID
        freight_carrier_code,        -- 運送業者
        shipping_method_code,        -- 配送区分
        actual_career_id,            -- 運送業者ID_実績
        actual_freight_carrier_code, -- 運送業者_実績
        actual_shipping_method_code, -- 配送区分_実績
        arrival_time_from,           -- 着荷時間FROM
        arrival_time_to,             -- 着荷時間TO
        slip_number,                 -- 送り状No
        sum_quantity,                -- 合計数量
        small_quantity,              -- 小口個数
        label_quantity,              -- ラベル枚数
        based_weight,                -- 基本重量
        based_capacity,              -- 基本容積
        sum_weight,                  -- 混載重量合計
        sum_capacity,                -- 混載容積合計
        sum_pallet_weight,           -- 合計パレット重量
        pallet_sum_quantity,         -- パレット合計枚数
        mixed_ratio,                 -- 混載率
        weight_capacity_class,       -- 重量容積区分
        actual_ship_date,            -- 出庫実績日
        actual_arrival_date,         -- 入庫実績日
        mixed_sign,                  -- 混載記号
        batch_no,                    -- 手配No
        item_class,                  -- 商品区分
        product_flg,                 -- 製品識別区分
        no_instr_actual_class,       -- 指示なし実績区分
        comp_actual_flg,             -- 実績計上済フラグ
        correct_actual_flg,          -- 実績訂正フラグ
        prev_notif_status,           -- 前回通知ステータス
        notif_date,                  -- 確定通知実績日時
        prev_delivery_no,            -- 前回配送No
        new_modify_flg,              -- 新規修正フラグ
        screen_update_by,            -- 画面更新者
        screen_update_date,          -- 画面更新日時
        created_by,                  -- 作成者
        creation_date,               -- 作成日
        last_updated_by,             -- 最終更新者
        last_update_date,            -- 最終更新日
        last_update_login,           -- 最終更新ログイン
        request_id,                  -- 要求ID
        program_application_id,      -- コンカレントプログラムアプリケーションID
        program_id,                  -- コンカレントプログラムID
        program_update_date          -- プログラム更新日
      )VALUES(
        gt_h_mov_hdr_id(ln_data_cnt),                  -- 移動ヘッダID
        gt_h_mov_num(ln_data_cnt),                     -- 移動番号
        gt_h_mov_type(ln_data_cnt),                    -- 移動タイプ
        gt_h_entered_date(ln_data_cnt),                -- 入力日
        gt_h_instruction_post_code(ln_data_cnt),       -- 指示部署
        gt_h_status(ln_data_cnt),                      -- ステータス
        gt_h_notif_status(ln_data_cnt),                -- 通知ステータス
        gt_h_shipped_locat_id(ln_data_cnt),            -- 出庫元ID
        gt_h_shipped_locat_code(ln_data_cnt),          -- 出庫元保管場所
        gt_h_ship_to_locat_id(ln_data_cnt),            -- 入庫先ID
        gt_h_ship_to_locat_code(ln_data_cnt),          -- 入庫先保管場所
        gt_h_schedule_ship_date(ln_data_cnt),          -- 出庫予定日
        gt_h_schedule_arrival_date(ln_data_cnt),       -- 入庫予定日
        gt_h_freight_charge_class(ln_data_cnt),        -- 運賃区分
        gt_h_collected_pallet_qty(ln_data_cnt),        -- パレット回収枚数
        gt_h_out_pallet_qty(ln_data_cnt),              -- パレット枚数(出)
        gt_h_in_pallet_qty(ln_data_cnt),               -- パレット枚数(入)
        gt_h_no_cont_freight_class(ln_data_cnt),       -- 契約外運賃区分
        gt_h_delivery_no(ln_data_cnt),                 -- 配送No
        gt_h_description(ln_data_cnt),                 -- 摘要
        gt_h_loading_efficiency_weight(ln_data_cnt),   -- 積載率(重量)
        gt_h_loading_efficiency_capa(ln_data_cnt),     -- 積載率(容積)
        gt_h_organization_id(ln_data_cnt),             -- 組織ID
        gt_h_career_id(ln_data_cnt),                   -- 運送業者ID
        gt_h_freight_carrier_code(ln_data_cnt),        -- 運送業者
        gt_h_shipping_method_code(ln_data_cnt),        -- 配送区分
        gt_h_actual_career_id(ln_data_cnt),            -- 運送業者ID_実績
        gt_h_actual_freight_carrier_cd(ln_data_cnt),   -- 運送業者_実績
        gt_h_actual_shipping_method_cd(ln_data_cnt),   -- 配送区分_実績
        gt_h_arrival_time_from(ln_data_cnt),           -- 着荷時間FROM
        gt_h_arrival_time_to(ln_data_cnt),             -- 着荷時間TO
        gt_h_slip_number(ln_data_cnt),                 -- 送り状No
        gt_h_sum_quantity(ln_data_cnt),                -- 合計数量
        gt_h_small_quantity(ln_data_cnt),              -- 小口個数
        gt_h_label_quantity(ln_data_cnt),              -- ラベル枚数
        gt_h_based_weight(ln_data_cnt),                -- 基本重量
        gt_h_based_capacity(ln_data_cnt),              -- 基本容積
        gt_h_sum_weight(ln_data_cnt),                  -- 混載重量合計
        gt_h_sum_capacity(ln_data_cnt),                -- 混載容積合計
        gt_h_sum_pallet_weight(ln_data_cnt),           -- 合計パレット重量
        gt_h_pallet_sum_quantity(ln_data_cnt),         -- パレット合計枚数
        gt_h_mixed_ratio(ln_data_cnt),                 -- 混載率
        gt_h_weight_capacity_class(ln_data_cnt),       -- 重量容積区分
        gt_h_actual_ship_date(ln_data_cnt),            -- 出庫実績日
        gt_h_actual_arrival_date(ln_data_cnt),         -- 入庫実績日
        gt_h_mixed_sign(ln_data_cnt),                  -- 混載記号
        gt_h_batch_no(ln_data_cnt),                    -- 手配No
        gt_h_item_class(ln_data_cnt),                  -- 商品区分
        gt_h_product_flg(ln_data_cnt),                 -- 製品識別区分
        gt_h_no_instr_actual_class(ln_data_cnt),       -- 指示なし実績区分
        gt_h_comp_actual_flg(ln_data_cnt),             -- 実績計上済フラグ
        gt_h_correct_actual_flg(ln_data_cnt),          -- 実績訂正フラグ
        gt_h_prev_notif_status(ln_data_cnt),           -- 前回通知ステータス
        gt_h_notif_date(ln_data_cnt),                  -- 確定通知実績日時
        gt_h_prev_delivery_no(ln_data_cnt),            -- 前回配送No
        gt_h_new_modify_flg(ln_data_cnt),              -- 新規修正フラグ
        gt_h_screen_update_by(ln_data_cnt),            -- 画面更新者
        gt_h_screen_update_date(ln_data_cnt),          -- 画面更新日時
        gt_h_created_by(ln_data_cnt),                  -- 作成者
        gt_h_creation_date(ln_data_cnt),               -- 作成日
        gt_h_last_updated_by(ln_data_cnt),             -- 最終更新者
        gt_h_last_update_date(ln_data_cnt),            -- 最終更新日
        gt_h_last_update_login(ln_data_cnt),           -- 最終更新ログイン
        gt_h_request_id(ln_data_cnt),                  -- 要求ID
        gt_h_program_application_id(ln_data_cnt),      -- コンカレントプログラムアプリケーションID
        gt_h_program_id(ln_data_cnt),                  -- コンカレントプログラムID
        gt_h_program_update_date(ln_data_cnt)          -- プログラム更新日
      );
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    <<ln_ins_cnt_loop>>
    FOR ln_data_cnt IN 1..gn_ins_data_cnt_ml LOOP
      -- ヘッダ用変数にあるかどうか検索＝あればそのまま、なければ作成しない明細とする
      <<search_loop>>
      FOR ln_search_cnt IN 1..gn_ins_data_cnt_mh LOOP
        IF (gr_move_lines_tbl(ln_data_cnt).mov_hdr_id = gt_h_mov_hdr_id(ln_search_cnt)) THEN
          lv_line_ins_flg := gv_cons_flg_on;
          EXIT;
        END IF;
      END LOOP search_loop;
      IF (lv_line_ins_flg = gv_cons_flg_on ) THEN
      gt_m_mov_line_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).mov_line_id;                -- 移動明細ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)ln_data_cnt(ml) = ' || ln_data_cnt);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_move_lines_tbl(ln_data_cnt).mov_line_id = ' || gr_move_lines_tbl(ln_data_cnt).mov_line_id);
-- DEBUG
      gt_m_mov_hdr_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).mov_hdr_id;                 -- 移動ヘッダID
      gt_m_line_number(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).line_number;                -- 明細番号
      gt_m_organization_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).organization_id;            -- 組織ID
      gt_m_item_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).item_id;                    -- OPM品目ID
      gt_m_item_code(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).item_code;                  -- 品目
      gt_m_request_qty(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).request_qty;                -- 依頼数量
      gt_m_pallet_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).pallet_quantity;            -- パレット数
      gt_m_layer_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).layer_quantity;             -- 段数
      gt_m_case_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).case_quantity;              -- ケース数
      gt_m_instruct_qty(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).instruct_qty;               -- 指示数量
      gt_m_reserved_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).reserved_quantity;          -- 引当数
      gt_m_uom_code(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).uom_code;                   -- 単位
      gt_m_designated_pdt_date(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).designated_production_date; -- 指定製造日
      gt_m_pallet_qty(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).pallet_qty;                 -- パレット枚数
      gt_m_move_num(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).move_num;                   -- 参照移動番号
      gt_m_po_num(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).po_num;                     -- 参照発注番号
      gt_m_first_instruct_qty(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).first_instruct_qty;         -- 初回指示数量
      gt_m_shipped_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).shipped_quantity;           -- 出庫実績数量
      gt_m_ship_to_quantity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).ship_to_quantity;           -- 入庫実績数量
      gt_m_weight(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).weight;                     -- 重量
      gt_m_capacity(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).capacity;                   -- 容積
      gt_m_pallet_weight(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).pallet_weight;              -- パレット重量
      gt_m_automanual_reserve_class(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).automanual_reserve_class;   -- 自動手動引当区分
      gt_m_delete_flg(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).delete_flg;                 -- 取消フラグ
      gt_m_warning_date(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).warning_date;               -- 警告日付
      gt_m_warning_class(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).warning_class;              -- 警告区分
      gt_m_created_by(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).created_by;                 -- 作成者
      gt_m_creation_date(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).creation_date;              -- 作成日
      gt_m_last_updated_by(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).last_updated_by;            -- 最終更新者
      gt_m_last_update_date(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).last_update_date;           -- 最終更新日
      gt_m_last_update_login(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).last_update_login;          -- 最終更新ログイン
      gt_m_request_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).request_id;                 -- 要求ID
      gt_m_program_application_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).program_application_id;
                                                     -- コンカレントプログラムアプリケーションID
      gt_m_program_id(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).program_id;                -- コンカレントプログラムID
      gt_m_program_update_date(ln_data_cnt) :=
              gr_move_lines_tbl(ln_data_cnt).program_update_date;       -- プログラム更新日
    ELSE
      lv_line_ins_flg := gv_cons_flg_off;
    END IF;
    END LOOP ln_ins_cnt_loop;
--
    -- FORALLにて移動依頼/指示明細をINSERTする
    FORALL ln_data_cnt IN 1..gn_ins_data_cnt_ml
      INSERT INTO xxinv_mov_req_instr_lines(
        mov_line_id,                -- 移動明細ID
        mov_hdr_id,                 -- 移動ヘッダID
        line_number,                -- 明細番号
        organization_id,            -- 組織ID
        item_id,                    -- OPM品目ID
        item_code,                  -- 品目
        request_qty,                -- 依頼数量
        pallet_quantity,            -- パレット数
        layer_quantity,             -- 段数
        case_quantity,              -- ケース数
        instruct_qty,               -- 指示数量
        reserved_quantity,          -- 引当数
        uom_code,                   -- 単位
        designated_production_date, -- 指定製造日
        pallet_qty,                 -- パレット枚数
        move_num,                   -- 参照移動番号
        po_num,                     -- 参照発注番号
        first_instruct_qty,         -- 初回指示数量
        shipped_quantity,           -- 出庫実績数量
        ship_to_quantity,           -- 入庫実績数量
        weight,                     -- 重量
        capacity,                   -- 容積
        pallet_weight,              -- パレット重量
        automanual_reserve_class,   -- 自動手動引当区分
        delete_flg,                 -- 取消フラグ
        warning_date,               -- 警告日付
        warning_class,              -- 警告区分
        created_by,                 -- 作成者
        creation_date,              -- 作成日
        last_updated_by,            -- 最終更新者
        last_update_date,           -- 最終更新日
        last_update_login,          -- 最終更新ログイン
        request_id,                 -- 要求ID
        program_application_id,     -- コンカレントプログラムアプリケーションID
        program_id,                 -- コンカレントプログラムID
        program_update_date         -- プログラム更新日
      )VALUES(
        gt_m_mov_line_id(ln_data_cnt),                -- 移動明細ID
        gt_m_mov_hdr_id(ln_data_cnt),                 -- 移動ヘッダID
        gt_m_line_number(ln_data_cnt),                -- 明細番号
        gt_m_organization_id(ln_data_cnt),            -- 組織ID
        gt_m_item_id(ln_data_cnt),                    -- OPM品目ID
        gt_m_item_code(ln_data_cnt),                  -- 品目
        gt_m_request_qty(ln_data_cnt),                -- 依頼数量
        gt_m_pallet_quantity(ln_data_cnt),            -- パレット数
        gt_m_layer_quantity(ln_data_cnt),             -- 段数
        gt_m_case_quantity(ln_data_cnt),              -- ケース数
        gt_m_instruct_qty(ln_data_cnt),               -- 指示数量
        gt_m_reserved_quantity(ln_data_cnt),          -- 引当数
        gt_m_uom_code(ln_data_cnt),                   -- 単位
        gt_m_designated_pdt_date(ln_data_cnt),        -- 指定製造日
        gt_m_pallet_qty(ln_data_cnt),                 -- パレット枚数
        gt_m_move_num(ln_data_cnt),                   -- 参照移動番号
        gt_m_po_num(ln_data_cnt),                     -- 参照発注番号
        gt_m_first_instruct_qty(ln_data_cnt),         -- 初回指示数量
        gt_m_shipped_quantity(ln_data_cnt),           -- 出庫実績数量
        gt_m_ship_to_quantity(ln_data_cnt),           -- 入庫実績数量
        gt_m_weight(ln_data_cnt),                     -- 重量
        gt_m_capacity(ln_data_cnt),                   -- 容積
        gt_m_pallet_weight(ln_data_cnt),              -- パレット重量
        gt_m_automanual_reserve_class(ln_data_cnt),   -- 自動手動引当区分
        gt_m_delete_flg(ln_data_cnt),                 -- 取消フラグ
        gt_m_warning_date(ln_data_cnt),               -- 警告日付
        gt_m_warning_class(ln_data_cnt),              -- 警告区分
        gt_m_created_by(ln_data_cnt),                 -- 作成者
        gt_m_creation_date(ln_data_cnt),              -- 作成日
        gt_m_last_updated_by(ln_data_cnt),            -- 最終更新者
        gt_m_last_update_date(ln_data_cnt),           -- 最終更新日
        gt_m_last_update_login(ln_data_cnt),          -- 最終更新ログイン
        gt_m_request_id(ln_data_cnt),                 -- 要求ID
        gt_m_program_application_id(ln_data_cnt),     -- コンカレントプログラムアプリケーションID
        gt_m_program_id(ln_data_cnt),                 -- コンカレントプログラムID
        gt_m_program_update_date(ln_data_cnt)         -- プログラム更新日
      );
--
    -- FORALLで使用できるようにレコード変数を分割格納する
    <<ln_ins_cnt_loop>>
    FOR ln_data_cnt IN 1..gn_ins_data_cnt_oh LOOP
      gt_rh_requisition_header_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).requisition_header_id;-- 発注依頼ヘッダID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)ln_data_cnt(oh) = ' || ln_data_cnt);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_requisition_header_tbl(ln_data_cnt).requisition_header_id = ' || gr_requisition_header_tbl(ln_data_cnt).requisition_header_id);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_requisition_header_tbl(ln_data_cnt).created_by = ' || gr_requisition_header_tbl(ln_data_cnt).created_by);
-- DEBUG
      gt_rh_po_header_number(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).po_header_number;     -- 発注番号
      gt_rh_status(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).status;               -- ステータス
      gt_rh_vendor_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).vendor_id;            -- 仕入先ID
      gt_rh_vendor_code(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).vendor_code;          -- 仕入先コード
      gt_rh_vendor_site_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).vendor_site_id;       -- 仕入先サイトID
      gt_rh_promised_date(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).promised_date;        -- 納入日
      gt_rh_location_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).location_id;          -- 納入先ID
      gt_rh_location_code(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).location_code;        -- 納入先コード
      gt_rh_drop_ship_type(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).drop_ship_type;       -- 直送区分
      gt_rh_delivery_code(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).delivery_code;        -- 配送先コード
      gt_rh_requested_by_code(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).requested_by_code;    -- 依頼者コード
      gt_rh_requested_dept_code(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).requested_dept_code;  -- 依頼者部署コード
      gt_rh_requested_to_dpt_code(ln_data_cnt) :=
           gr_requisition_header_tbl(ln_data_cnt).requested_to_department_code;-- 依頼先部署コード
      gt_rh_description(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).description;          -- 摘要
      gt_rh_change_flag(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).change_flag;          -- 変更フラグ
      gt_rh_created_by(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).created_by;            -- 作成者
      gt_rh_creation_date(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).creation_date;         -- 作成日
      gt_rh_last_updated_by(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).last_updated_by;       -- 最終更新者
      gt_rh_last_update_date(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).last_update_date;      -- 最終更新日
      gt_rh_last_update_login(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).last_update_login;     -- 最終更新ログイン
      gt_rh_request_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).request_id;            -- 要求ID
      gt_rh_program_application_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).program_application_id;-- アプリケーションID
      gt_rh_program_id(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).program_id;            -- プログラムID
      gt_rh_program_update_date(ln_data_cnt) :=
                gr_requisition_header_tbl(ln_data_cnt).program_update_date;   -- プログラム更新日
    END LOOP ln_ins_cnt_loop;
--
    -- FORALLにて発注依頼ヘッダをINSERTする
    FORALL ln_data_cnt IN 1..gn_ins_data_cnt_oh
      INSERT INTO xxpo_requisition_headers(
        requisition_header_id,         -- 発注依頼ヘッダID
        po_header_number,              -- 発注番号
        status,                        -- ステータス
        vendor_id,                     -- 仕入先ID
        vendor_code,                   -- 仕入先コード
        vendor_site_id,                -- 仕入先サイトID
        promised_date,                 -- 納入日
        location_id,                   -- 納入先ID
        location_code,                 -- 納入先コード
        drop_ship_type,                -- 直送区分
        delivery_code,                 -- 配送先コード
        requested_by_code,             -- 依頼者コード
        requested_dept_code,           -- 依頼者部署コード
        requested_to_department_code,  -- 依頼先部署コード
        description,                   -- 摘要
        change_flag,                   -- 変更フラグ
        created_by,                    -- 作成者
        creation_date,                 -- 作成日
        last_updated_by,               -- 最終更新者
        last_update_date,              -- 最終更新日
        last_update_login,             -- 最終更新ログイン
        request_id,                    -- 要求ID
        program_application_id,        -- アプリケーションID
        program_id,                    -- プログラムID
        program_update_date            -- プログラム更新日
      )VALUES(
        gt_rh_requisition_header_id(ln_data_cnt),         -- 発注依頼ヘッダID
        gt_rh_po_header_number(ln_data_cnt),              -- 発注番号
        gt_rh_status(ln_data_cnt),                        -- ステータス
        gt_rh_vendor_id(ln_data_cnt),                     -- 仕入先ID
        gt_rh_vendor_code(ln_data_cnt),                   -- 仕入先コード
        gt_rh_vendor_site_id(ln_data_cnt),                -- 仕入先サイトID
        gt_rh_promised_date(ln_data_cnt),                 -- 納入日
        gt_rh_location_id(ln_data_cnt),                   -- 納入先ID
        gt_rh_location_code(ln_data_cnt),                 -- 納入先コード
        gt_rh_drop_ship_type(ln_data_cnt),                -- 直送区分
        gt_rh_delivery_code(ln_data_cnt),                 -- 配送先コード
        gt_rh_requested_by_code(ln_data_cnt),             -- 依頼者コード
        gt_rh_requested_dept_code(ln_data_cnt),           -- 依頼者部署コード
        gt_rh_requested_to_dpt_code(ln_data_cnt),         -- 依頼先部署コード
        gt_rh_description(ln_data_cnt),                   -- 摘要
        gt_rh_change_flag(ln_data_cnt),                   -- 変更フラグ
        gt_rh_created_by(ln_data_cnt),                    -- 作成者
        gt_rh_creation_date(ln_data_cnt),                 -- 作成日
        gt_rh_last_updated_by(ln_data_cnt),               -- 最終更新者
        gt_rh_last_update_date(ln_data_cnt),              -- 最終更新日
        gt_rh_last_update_login(ln_data_cnt),             -- 最終更新ログイン
        gt_rh_request_id(ln_data_cnt),                    -- 要求ID
        gt_rh_program_application_id(ln_data_cnt),        -- アプリケーションID
        gt_rh_program_id(ln_data_cnt),                    -- プログラムID
        gt_rh_program_update_date(ln_data_cnt)            -- プログラム更新日
      );
--
    -- FORALLで使用できるようにレコード変数を分割格納する 
    <<ln_ins_cnt_loop>>
    FOR ln_data_cnt IN 1..gn_ins_data_cnt_ol LOOP
      gt_rl_requisition_line_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requisition_line_id;    -- 発注依頼明細ID
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)ln_data_cnt(ol) = ' || ln_data_cnt);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)gr_requisition_lines_tbl(ln_data_cnt).requisition_line_id = ' || gr_requisition_lines_tbl(ln_data_cnt).requisition_line_id);
-- DEBUG
      gt_rl_requisition_header_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requisition_header_id;  -- 発注依頼ヘッダID
      gt_rl_requisition_line_number(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requisition_line_number;-- 明細番号
      gt_rl_item_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).item_id;                -- 品目ID
      gt_rl_item_code(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).item_code;              -- 品目コード
      gt_rl_pack_quantity(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).pack_quantity;          -- 在庫入数
      gt_rl_requested_quantity(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requested_quantity;     -- 依頼数量
      gt_rl_requested_quantity_uom(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requested_quantity_uom; -- 依頼数量単位コード
      gt_rl_requested_date(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).requested_date;         -- 日付指定
      gt_rl_ordered_quantity(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).ordered_quantity;       -- 発注数量
      gt_rl_description(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).description;            -- 摘要
      gt_rl_cancelled_flg(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).cancelled_flg;          -- 取消フラグ
      gt_rl_created_by(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).created_by;             -- 作成者
      gt_rl_creation_date(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).creation_date;          -- 作成日
      gt_rl_last_updated_by(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).last_updated_by;        -- 最終更新者
      gt_rl_last_update_date(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).last_update_date;       -- 最終更新日
      gt_rl_last_update_login(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).last_update_login;      -- 最終更新ログイン
      gt_rl_request_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).request_id;             -- 要求ID
      gt_rl_program_application_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).program_application_id; -- アプリケーションID
      gt_rl_program_id(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).program_id;             -- プログラムID
      gt_rl_program_update_date(ln_data_cnt) :=
              gr_requisition_lines_tbl(ln_data_cnt).program_update_date;    -- プログラム更新日
    END LOOP ln_ins_cnt_loop;
--
    -- FORALLにて発注依頼明細をINSERTする
    FORALL ln_data_cnt IN 1..gn_ins_data_cnt_ol
      INSERT INTO xxpo_requisition_lines(
        requisition_line_id,    -- 発注依頼明細ID
        requisition_header_id,  -- 発注依頼ヘッダID
        requisition_line_number,-- 明細番号
        item_id,                -- 品目ID
        item_code,              -- 品目コード
        pack_quantity,          -- 在庫入数
        requested_quantity,     -- 依頼数量
        requested_quantity_uom, -- 依頼数量単位コード
        requested_date,         -- 日付指定
        ordered_quantity,       -- 発注数量
        description,            -- 摘要
        cancelled_flg,          -- 取消フラグ
        created_by,             -- 作成者
        creation_date,          -- 作成日
        last_updated_by,        -- 最終更新者
        last_update_date,       -- 最終更新日
        last_update_login,      -- 最終更新ログイン
        request_id,             -- 要求ID
        program_application_id, -- アプリケーションID
        program_id,             -- プログラムID
        program_update_date     -- プログラム更新日
      )VALUES(
        gt_rl_requisition_line_id(ln_data_cnt),    -- 発注依頼明細ID
        gt_rl_requisition_header_id(ln_data_cnt),  -- 発注依頼ヘッダID
        gt_rl_requisition_line_number(ln_data_cnt),-- 明細番号
        gt_rl_item_id(ln_data_cnt),                -- 品目ID
        gt_rl_item_code(ln_data_cnt),              -- 品目コード
        gt_rl_pack_quantity(ln_data_cnt),          -- 在庫入数
        gt_rl_requested_quantity(ln_data_cnt),     -- 依頼数量
        gt_rl_requested_quantity_uom(ln_data_cnt), -- 依頼数量単位コード
        gt_rl_requested_date(ln_data_cnt),         -- 日付指定
        gt_rl_ordered_quantity(ln_data_cnt),       -- 発注数量
        gt_rl_description(ln_data_cnt),            -- 摘要
        gt_rl_cancelled_flg(ln_data_cnt),          -- 取消フラグ
        gt_rl_created_by(ln_data_cnt),             -- 作成者
        gt_rl_creation_date(ln_data_cnt),          -- 作成日
        gt_rl_last_updated_by(ln_data_cnt),        -- 最終更新者
        gt_rl_last_update_date(ln_data_cnt),       -- 最終更新日
        gt_rl_last_update_login(ln_data_cnt),      -- 最終更新ログイン
        gt_rl_request_id(ln_data_cnt),             -- 要求ID
        gt_rl_program_application_id(ln_data_cnt), -- アプリケーションID
        gt_rl_program_id(ln_data_cnt),             -- プログラムID
        gt_rl_program_update_date(ln_data_cnt)     -- プログラム更新日
      );
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-14)upd gn_upd_data_cnt_ol = ' || gn_upd_data_cnt_ol);
-- DEBUG
    -- FORALLにて受注明細をUPDATEする
    FORALL ln_data_cnt IN 1..gn_upd_data_cnt_ol
      UPDATE xxwsh_order_lines_all xola
      SET   xola.move_number            = gt_ol_move_number(ln_data_cnt),       -- 移動No
            xola.po_number              = gt_ol_po_number(ln_data_cnt),         -- 発注No
            xola.last_updated_by        = gt_ol_last_updated_by(ln_data_cnt),   -- 最終更新者
            xola.last_update_date       = gt_ol_last_update_date(ln_data_cnt),  -- 最終更新日
            xola.last_update_login      = gt_ol_last_update_login(ln_data_cnt), -- 最終更新ログイン
            xola.request_id             = gt_ol_request_id(ln_data_cnt),        -- 要求ID
            xola.program_application_id = gt_ol_program_application_id(ln_data_cnt),
                                                                              --アプリケーションID
            xola.program_id             = gt_ol_program_id(ln_data_cnt),        -- プログラムID
            xola.program_update_date    = gt_ol_program_update_date(ln_data_cnt)-- プログラム更新日
      WHERE xola.shipping_item_code   = gt_ol_shipping_item_code(ln_data_cnt)   -- 品目コード
        AND EXISTS
            (SELECT 'REQUEST_NO'
             FROM  xxwsh_order_headers_all xoha
             WHERE xoha.order_header_id = xola.order_header_id
               AND xoha.latest_external_flag   = gv_cons_flg_y                  -- 最新フラグ 'Y'
               AND xoha.request_no = gt_ol_request_no(ln_data_cnt));            -- 依頼No
--
    -- FORALLにて移動依頼/指示明細をUPDATEする
    FORALL ln_data_cnt IN 1..gn_upd_data_cnt_ml
      UPDATE xxinv_mov_req_instr_lines xmril
      SET   xmril.move_num               = gt_ml_move_num(ln_data_cnt),          -- 参照移動番号
            xmril.po_num                 = gt_ml_po_num(ln_data_cnt),            -- 参照発注番号
            xmril.last_updated_by        = gt_ml_last_updated_by(ln_data_cnt),   -- 最終更新者
            xmril.last_update_date       = gt_ml_last_update_date(ln_data_cnt),  -- 最終更新日
            xmril.last_update_login      = gt_ml_last_update_login(ln_data_cnt), -- 最終更新ログイン
            xmril.request_id             = gt_ml_request_id(ln_data_cnt),        -- 要求ID
            xmril.program_application_id = gt_ml_program_application_id(ln_data_cnt),
                                                                              --アプリケーションID
            xmril.program_id             = gt_ml_program_id(ln_data_cnt),        -- プログラムID
            xmril.program_update_date    = gt_ml_program_update_date(ln_data_cnt)-- プログラム更新日
      WHERE xmril.item_code   = gt_ml_item_code(ln_data_cnt)                     -- 品目コード
        AND EXISTS
            (SELECT 'MOV_NUM'
             FROM  xxinv_mov_req_instr_headers xmrih
             WHERE xmrih.mov_hdr_id = xmril.mov_hdr_id
               AND xmrih.mov_num = gt_ml_mov_num(ln_data_cnt));                  -- 移動番号
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
  END insert_tables;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_req_mov_no            IN         VARCHAR2,   -- 依頼/移動No
    iv_deliver_from          IN         VARCHAR2,   -- 出庫元保管場所
    iv_deliver_type          IN         VARCHAR2,   -- 出庫形態
    iv_object_date_from      IN         VARCHAR2,   -- 対象期間From
    iv_object_date_to        IN         VARCHAR2,   -- 対象期間To
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2,   -- 指示部署指定
    ov_errbuf               OUT NOCOPY  VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY  VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY  VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_ret_code VARCHAR2(1);     -- リターン・コード
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
    lc_out_param            VARCHAR2(1000);   -- 入力パラメータの処理結果レポート出力用
    ln_get_data_loop_cnt    NUMBER := 0;      -- C-4データループカウンタ
    ln_get_zaiko_loop_cnt   NUMBER := 0;      -- 在庫補充元取得ループカウンタ
    ln_max_cnt              NUMBER := 0;      -- ループ最大カウント
    lv_move_number          xxwsh_order_lines_all.move_number%TYPE;
    lv_po_number            xxwsh_order_lines_all.po_number%TYPE;
    ln_tmp_tbl_cnt          NUMBER := 0;      -- 中間テーブルデータ件数
    ln_cnt                  NUMBER := 0;
    ln_line_cnt             NUMBER := 0;
    ln_mov_hdr_id           xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
    ln_weight               NUMBER := 0;       --明細重量合計集計用
    ln_p_weight             NUMBER := 0;       --明細パレット重量集計用
    ln_sum_weight           NUMBER := 0;       --ヘッダ重量集計用
    ln_sum_p_weight         NUMBER := 0;       --ヘッダパレット重量集計用
    ln_capacity             NUMBER := 0;       --明細容積集計用
    ln_sum_capacity         NUMBER := 0;       --ヘッダ容積集計用
    lv_item_code            xxinv_mov_req_instr_lines.item_code%TYPE; --重量合計算出対象品目
    ln_instruct_qty         xxinv_mov_req_instr_lines.instruct_qty%TYPE; --重量合計算出対象数量
--
    lv_loading_over_class          VARCHAR2(1); -- 積載オーバー区分
    lv_ship_methods                xxcmn_ship_methods.ship_method%TYPE;        -- 出荷方法
    ln_load_efficiency_weight      NUMBER;      -- 重量積載効率
    ln_load_efficiency_capacity    NUMBER;      -- 容積積載効率
    lv_mixed_ship_method     xxwsh_ship_method2_v.mixed_ship_method_code%TYPE; -- 混載配送区分
--DEBUG
    i                       NUMBER;
--DEBUG
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- 入力パラメータを合体して出力
    lc_out_param := gv_cons_input_param || gv_msg_part ||
                    iv_action_type      || gv_msg_pnt || iv_req_mov_no     || gv_msg_pnt ||
                    iv_deliver_from     || gv_msg_pnt || iv_deliver_type   || gv_msg_pnt ||
                    iv_object_date_from || gv_msg_pnt || iv_object_date_to || gv_msg_pnt ||
                    iv_shipped_date     || gv_msg_pnt || iv_arrival_date   || gv_msg_pnt ||
                    iv_instruction_post_code;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_param);
--
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)check_parameter call...');
-- DEBUG
    -- ===============================================
    -- C-1  パラメータチェック check_parameter
    -- ===============================================
    check_parameter(iv_action_type,           -- 処理種別
                    iv_req_mov_no,            -- 依頼/移動No
                    iv_deliver_from,          -- 出庫元保管場所
                    iv_deliver_type,          -- 出庫形態
                    iv_object_date_from,      -- 対象期間From
                    iv_object_date_to,        -- 対象期間To
                    iv_shipped_date,          -- 出庫日指定
                    iv_arrival_date,          -- 着日指定
                    iv_instruction_post_code, -- 指示部署指定
                    lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                    lv_retcode,            -- リターン・コード             --# 固定 #
                    lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理 
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- C-2  プロファイル値取得 get_profile
    -- ===============================================
    get_profile(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                lv_retcode,            -- リターン・コード             --# 固定 #
                lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- C-3   パージ処理 purge_table
    -- ===============================================
    purge_table(iv_action_type,        -- 処理種別
                lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                lv_retcode,            -- リターン・コード             --# 固定 #
                lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理 
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- C-4   情報抽出 get_data
    -- ===============================================
    get_data( iv_action_type,        -- 処理種別
              iv_req_mov_no,         -- 依頼/移動No
              iv_deliver_from,       -- 出庫元保管場所
              iv_deliver_type,       -- 出庫形態
              iv_object_date_from,   -- 対象期間From
              iv_object_date_to,     -- 対象期間To
              iv_arrival_date,       -- 着日指定
              lv_errbuf,             -- エラー・メッセージ           --# 固定 #
              lv_retcode,            -- リターン・コード             --# 固定 #
              lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理 
    IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
    END IF;
--
    <<get_data_loop>> -- 抽出ループ
    FOR ln_get_data_loop_cnt IN 1..gn_target_cnt LOOP
      -- ===============================================
      -- C-5   ルール取得 get_rule
      -- ===============================================
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)get_data_loop_in____' || to_char(ln_get_data_loop_cnt));
-- DEBUG
      get_rule(ln_get_data_loop_cnt,      -- 処理カウンタ
               iv_action_type,            -- 処理種別
               iv_arrival_date,           -- 着日指定
               lv_errbuf,                 -- エラー・メッセージ           --# 固定 #
               lv_retcode,                -- リターン・コード             --# 固定 #
               lv_errmsg);                -- ユーザー・エラー・メッセージ --# 固定 #
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)get_data_loop_out___' || to_char(ln_get_data_loop_cnt));
-- DEBUG
      -- エラー処理 
      IF (lv_retcode = gv_status_error) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)get_data_loop_out_and_err' || to_char(ln_get_data_loop_cnt));
-- DEBUG
          RAISE global_process_expt;
      END IF;
--
    END LOOP get_data_loop;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'#####before ins_ints_table' || to_char(ln_get_data_loop_cnt));
-- DEBUG
    -- 処理種別が「出荷」の場合
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- ===============================================
      -- C-6   中間テーブル登録(出荷) ins_ints_table
      -- ===============================================
      ins_ints_table(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                     lv_retcode,            -- リターン・コード             --# 固定 #
                     lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラー処理 
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
      END IF;
--
    -- 処理種別が「移動」の場合
    ELSIF (iv_action_type = gv_cons_t_move) THEN
      -- ===============================================
      -- C-7   中間テーブル登録(移動) ins_intm_table
      -- ===============================================
      ins_intm_table(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                     lv_retcode,            -- リターン・コード             --# 固定 #
                     lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラー処理 
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
      END IF;
--
    END IF;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)get_data_loop out !');
-- DEBUG
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)C-8 or C-9 にて中間テーブル抽出....');
-- DEBUG
    -- 処理種別が「出荷」の場合
    IF (iv_action_type = gv_cons_t_deliv) THEN
      -- ===============================================
      -- C-8   中間テーブル抽出(出荷) get_ints_data
      -- ===============================================
      get_ints_data(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                    lv_retcode,            -- リターン・コード             --# 固定 #
                    lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラー処理 
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
      END IF;
      ln_max_cnt := gn_target_cnt_deliv;
--
-- DEBUG
for i IN 1..ln_max_cnt LOOP
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)======================================');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)deliv_tbl(' || i || ').request_no = ' || gr_deliv_data_tbl(i).request_no);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)deliv_tbl(' || i || ').shipping_item_code = ' || gr_deliv_data_tbl(i).shipping_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)deliv_tbl(' || i || ').quantity = ' || gr_deliv_data_tbl(i).quantity);
end loop;
-- DEBUG
--
    -- 処理種別が「移動」の場合
    ELSE
      -- ===============================================
      -- C-9   中間テーブル抽出(移動) get_intm_data
      -- ===============================================
      get_intm_data(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                    lv_retcode,            -- リターン・コード             --# 固定 #
                    lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      -- エラー処理 
      IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
      END IF;
      ln_max_cnt := gn_target_cnt_move;
--
-- DEBUG
for i IN 1..ln_max_cnt LOOP
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)======================================');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)move_tbl(' || i || ').mov_num = ' || gr_move_data_tbl(i).mov_num);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)move_tbl(' || i || ').item_code = ' || gr_move_data_tbl(i).item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)move_tbl(' || i || ').instruct_qty = ' || gr_move_data_tbl(i).instruct_qty);
end loop;
-- DEBUG
--
    END IF;
--
    <<get_zaiko_loop>> -- 在庫補充元取得ループ
    FOR ln_get_zaiko_loop_cnt IN 1..ln_max_cnt LOOP
--
      -- 移動番号、発注番号の初期化
      lv_move_number := NULL;
      lv_po_number   := NULL;
--
      -- 在庫補充ルールが「移動」であり、処理種別が「出荷」または「移動」
      IF (((iv_action_type = gv_cons_t_deliv)
           AND
          (gr_deliv_data_tbl(ln_get_zaiko_loop_cnt).stock_rep_rule = gv_cons_rule_move))
        OR
         ((iv_action_type = gv_cons_t_move)
           AND
          (gr_move_data_tbl(ln_get_zaiko_loop_cnt).stock_rep_rule = gv_cons_rule_move)))
      THEN
        -- ===============================================
        -- C-10  移動依頼/指示登録 regi_move_data
        -- ===============================================
        regi_move_data(ln_get_zaiko_loop_cnt,     -- 処理カウンタ
                       iv_action_type,            -- 処理種別
                       iv_shipped_date,           -- 出庫日指定
                       iv_arrival_date,           -- 着日指定
                       iv_instruction_post_code,  -- 指示部署指定
                       lv_errbuf,                 -- エラー・メッセージ           --# 固定 #
                       lv_ret_code,                -- リターン・コード             --# 固定 #
                       lv_errmsg);                -- ユーザー・エラー・メッセージ --# 固定 #
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)C-10 after .... ' || lv_ret_code);
-- DEBUG
        -- エラー処理 
        IF (lv_ret_code = gv_status_error) THEN
            RAISE global_process_expt;
        END IF;
        -- 警告リターンしてきたら警告有をリターン用変数にセットしておく
        -- エラーになったら例外にて上書きされるのでそのままでOK
        IF (lv_ret_code = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        ELSE
          lv_move_number := gr_move_header_tbl(gn_ins_data_cnt_mh).mov_num;
        END IF;
--
      -- 在庫補充ルールが「発注」
      ELSE
        -- ===============================================
        -- C-11  発注依頼登録 regi_order_data
        -- ===============================================
        regi_order_data(ln_get_zaiko_loop_cnt,     -- 処理カウンタ
                        iv_action_type,            -- 処理種別
                        iv_shipped_date,           -- 出庫日指定
                        iv_arrival_date,           -- 着日指定
                        iv_instruction_post_code,  -- 指示部署指定
                        lv_errbuf,                 -- エラー・メッセージ           --# 固定 #
                        lv_ret_code,               -- リターン・コード             --# 固定 #
                        lv_errmsg);                -- ユーザー・エラー・メッセージ --# 固定 #
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)C-11 after .... ' || lv_ret_code);
-- DEBUG
        -- エラー処理 
        IF (lv_ret_code = gv_status_error) THEN
            RAISE global_process_expt;
        END IF;
        -- 警告リターンしてきたら警告有をリターン用変数にセットしておく
        -- エラーになったら例外にて上書きされるのでそのままでOK
        IF (lv_ret_code = gv_status_warn) THEN
          ov_retcode := gv_status_warn;
        ELSE
          lv_po_number := gr_requisition_header_tbl(gn_ins_data_cnt_oh).po_header_number;
        END IF;
      END IF;
--
      -- 処理種別が「出荷」の場合
      IF ((iv_action_type = gv_cons_t_deliv) AND (lv_ret_code = gv_status_normal)) THEN
        -- ===============================================
        -- C-12  受注明細更新 regi_order_detail
        -- ===============================================
        regi_order_detail(ln_get_zaiko_loop_cnt, -- 処理カウンタ
                          lv_move_number,        -- 移動番号
                          lv_po_number,          -- 発注番号
                          lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                          lv_retcode,            -- リターン・コード             --# 固定 #
                          lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
        -- エラー処理 
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- 処理種別が「移動」の場合
      IF ((iv_action_type = gv_cons_t_move) AND (lv_ret_code = gv_status_normal)) THEN
        -- ===============================================
        -- C-13  移動指示/指示明細更新 regi_move_detail
        -- ===============================================
        regi_move_detail(ln_get_zaiko_loop_cnt, -- 処理カウンタ
                        lv_move_number,         -- 移動番号
                        lv_po_number,           -- 発注番号
                        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                        lv_retcode,             -- リターン・コード             --# 固定 #
                        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
        -- エラー処理 
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      -- 移動番号、発注番号の初期化
--      lv_move_number := NULL;
--      lv_po_number   := NULL;
--
    END LOOP get_zaiko_loop;
--
-- ############################################################################################
-- 移動明細重量補完ループ
-- ############################################################################################
    <<move_line_weight_loop>>
    FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
      ln_weight := 0;
      ln_capacity := 0;
      ln_p_weight := 0;
--
      --各明細の重量算出対象の品目コードを格納
      lv_item_code := gr_move_lines_tbl(ln_line_cnt).item_code;
      --各明細の重量算出対象の数量を格納
      ln_instruct_qty := gr_move_lines_tbl(ln_line_cnt).instruct_qty;
--
      -- 積載効率チェック(合計値算出)
      xxwsh_common910_pkg.calc_total_value(
                                         lv_item_code,        -- 1.品目コード I
                                         ln_instruct_qty,     -- 2.数量 I
                                         lv_retcode,          -- 3.リターンコード O
                                         lv_errbuf,           -- 4.エラーメッセージコード O
                                         lv_errmsg,           -- 5.エラーメッセージ O
                                         ln_weight,           -- 6.合計重量 O
                                         ln_capacity,         -- 7.合計容積 O
                                         ln_p_weight);        -- 8.合計パレット重量 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()---------------------------------------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value in lv_item_code  = ' || lv_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value in ln_instruct_qty = ' || ln_instruct_qty);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_weight = ' || ln_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_capacity = ' || ln_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_p_weight = ' || ln_p_weight);
-- DEBUG
--
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                   ,gv_msg_wsh_13124     -- 積載効率関数エラー
                                                   ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                   ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                   ,gv_tkn_param1        -- トークン'PARAM1'
                                                   ,lv_item_code         -- 品目コード
                                                   ,gv_tkn_param2        -- トークン'PARAM2'
                                                   ,ln_instruct_qty          -- 合計数量
                                                   ,gv_tkn_param3        -- トークン'PARAM3'
                                                   ,lv_errbuf            -- エラーメッセージコード
                                                   ,gv_tkn_param4        -- トークン'PARAM4'
                                                   ,lv_errmsg            -- エラーメッセージ
                                                   )
                                                   ,1
                                                   ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        -- 警告件数のカウント
        gn_warn_cnt := gn_warn_cnt + 1;
        --積載効率チェック(合計値算出)関数のエラーのリターン
        RAISE common_warn_expt;
      END IF;
--
      --明細毎の重量をセット
      gr_move_lines_tbl(ln_line_cnt).weight := ln_weight;
      --明細毎のパレット重量をセット
      gr_move_lines_tbl(ln_line_cnt).pallet_weight := ln_p_weight;
--
    END LOOP;
--
-- ############################################################################################
-- 移動明細容積補完ループ
-- ############################################################################################
    <<move_line_weight_loop>>
    FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
      ln_weight := 0;
      ln_capacity := 0;
      ln_p_weight := 0;
--
      --各明細の容積算出対象の品目コードを格納
      lv_item_code := gr_move_lines_tbl(ln_line_cnt).item_code;
      --各明細の容積算出対象の数量を格納
      ln_instruct_qty := gr_move_lines_tbl(ln_line_cnt).instruct_qty;
--
      -- 積載効率チェック(合計値算出)
      xxwsh_common910_pkg.calc_total_value(
                                         lv_item_code,        -- 1.品目コード I
                                         ln_instruct_qty,     -- 2.数量 I
                                         lv_retcode,          -- 3.リターンコード O
                                         lv_errbuf,           -- 4.エラーメッセージコード O
                                         lv_errmsg,           -- 5.エラーメッセージ O
                                         ln_weight,           -- 6.合計重量 O
                                         ln_capacity,         -- 7.合計容積 O
                                         ln_p_weight);        -- 8.合計パレット重量 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()---------------------------------------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value in lv_item_code  = ' || lv_item_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value in ln_instruct_qty = ' || ln_instruct_qty);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_weight = ' || ln_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_capacity = ' || ln_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'()calc_total_value out ln_p_weight = ' || ln_p_weight);
-- DEBUG
--
      -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
      IF (lv_retcode <> gv_status_normal) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                                                   ,gv_msg_wsh_13124     -- 積載効率関数エラー
                                                   ,gv_tkn_table_name    -- トークン'TABLE_NAME'
                                                   ,gv_cons_mov_hdr_tbl  -- 移動依頼/指示ヘッダ
                                                   ,gv_tkn_param1        -- トークン'PARAM1'
                                                   ,lv_item_code         -- 品目コード
                                                   ,gv_tkn_param2        -- トークン'PARAM2'
                                                   ,ln_instruct_qty          -- 合計数量
                                                   ,gv_tkn_param3        -- トークン'PARAM3'
                                                   ,lv_errbuf            -- エラーメッセージコード
                                                   ,gv_tkn_param4        -- トークン'PARAM4'
                                                   ,lv_errmsg            -- エラーメッセージ
                                                   )
                                                   ,1
                                                   ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
        -- 警告件数のカウント
        gn_warn_cnt := gn_warn_cnt + 1;
        --積載効率チェック(合計値算出)関数のエラーのリターン
        RAISE common_warn_expt;
      END IF;
--
      --明細毎の容積をセット
      gr_move_lines_tbl(ln_line_cnt).capacity := ln_capacity;
--
    END LOOP;
--
--
-- ############################################################################################
-- 移動ヘッダ重量補完ループ
-- ############################################################################################
    <<move_header_weight_loop>>
    FOR ln_hdr_cnt IN 1..gr_move_header_tbl.COUNT LOOP
      ln_sum_weight := 0;
      ln_sum_p_weight := 0;
      FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
        -- 同じヘッダIDならば合算する
        IF (gr_move_header_tbl(ln_hdr_cnt).mov_hdr_id =
            gr_move_lines_tbl(ln_line_cnt).mov_hdr_id) 
        THEN
          ln_sum_weight := ln_sum_weight + gr_move_lines_tbl(ln_line_cnt).weight;
          ln_sum_p_weight := ln_sum_p_weight + gr_move_lines_tbl(ln_line_cnt).pallet_weight;
        END IF;
      END LOOP;
      gr_move_header_tbl(ln_hdr_cnt).sum_weight := ln_sum_weight;
      gr_move_header_tbl(ln_hdr_cnt).sum_pallet_weight := ln_sum_p_weight;
    END LOOP;
--
-- ############################################################################################
-- 移動ヘッダ容積補完ループ
-- ############################################################################################
    <<move_header_capacity_loop>>
    FOR ln_hdr_cnt IN 1..gr_move_header_tbl.COUNT LOOP
      ln_sum_capacity := 0;
      FOR ln_line_cnt IN 1..gr_move_lines_tbl.COUNT LOOP
        -- 同じヘッダIDならば合算する
        IF (gr_move_header_tbl(ln_hdr_cnt).mov_hdr_id =
            gr_move_lines_tbl(ln_line_cnt).mov_hdr_id) 
        THEN
          ln_sum_capacity := ln_sum_capacity + gr_move_lines_tbl(ln_line_cnt).capacity;
        END IF;
      END LOOP;
      gr_move_header_tbl(ln_hdr_cnt).sum_capacity := ln_sum_capacity;
    END LOOP;
--
-- ############################################################################################
-- 移動ヘッダ積載効率補完ループ
-- ############################################################################################
    ln_mov_hdr_id := NULL;
    <<move_header_le_loop>>
    FOR ln_hdr_cnt IN 1..gr_move_header_tbl.COUNT LOOP
--
      ln_sum_weight := 0;
      ln_sum_capacity := 0;
      ln_load_efficiency_weight := 0;
      ln_load_efficiency_capacity := 0;
--
      -- 重量容積区分=重量の場合に、重量積載効率を算出する
      IF gr_move_header_tbl(ln_hdr_cnt).weight_capacity_class = gv_cons_weight THEN
--
        --重量算出のため、合計重量にパレット重量を加算する
        ln_sum_weight := NVL(gr_move_header_tbl(ln_hdr_cnt).sum_weight,0) +
                         NVL(gr_move_header_tbl(ln_hdr_cnt).sum_pallet_weight,0);
--
        -- １ヘッダあたりの積載効率を算出してヘッダにセットする
        -- 積載効率チェック(積載効率算出)
        xxwsh_common910_pkg.calc_load_efficiency(
             ln_sum_weight,                                       -- 1.合計重量 I
             NULL,                                                -- 2.合計容積 I
             gv_cons_wh,                                          -- 3.コード区分１ I '4'
             gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code,   -- 4.入出庫場所コード１ I
               gv_cons_wh,                                          -- 5.コード区分２ I '4'
             gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code,   -- 6.入出庫場所コード２ I
             gr_move_header_tbl(ln_hdr_cnt).shipping_method_code, -- 7.出荷方法 I
             gr_move_header_tbl(ln_hdr_cnt).item_class,           -- 8.商品区分 I
             NULL,                                                -- 9.自動配車対象区分 I
             TO_DATE(iv_arrival_date,'YYYY/MM/DD'),               -- 10.基準日(適用日基準日) I
             lv_retcode,                                          -- 11.リターンコード O
             lv_errbuf,                                           -- 12.エラーメッセージコード O
             lv_errmsg,                                           -- 13.エラーメッセージ O
             lv_loading_over_class,                               -- 14.積載オーバー区分 O
             lv_ship_methods,                                     -- 15.出荷方法 O
             ln_load_efficiency_weight,                           -- 16.重量積載効率 O
             ln_load_efficiency_capacity,                         -- 17.容積積載効率 O
             lv_mixed_ship_method);                               -- 18.混載配送区分 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)----移動ヘッダ積載効率補完ループ----------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).sum_weight = ' || gr_move_header_tbl(ln_hdr_cnt).sum_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code = ' || gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code = ' || gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).shipping_method_code = ' || gr_move_header_tbl(ln_hdr_cnt).shipping_method_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in  gr_move_header_tbl(ln_hdr_cnt)item_class = ' ||  gr_move_header_tbl(ln_hdr_cnt).item_class);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_loading_over_class = ' || lv_loading_over_class);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_ship_methods = ' || lv_ship_methods);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out ln_load_efficiency_weight = ' || ln_load_efficiency_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out ln_load_efficiency_capacity = ' || ln_load_efficiency_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_mixed_ship_method = ' || lv_mixed_ship_method);
-- DEBUG
        -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                        ,gv_msg_wsh_13172                                   -- 積載効率関数エラー
                        ,gv_tkn_table_name                                  -- トークン'TABLE_NAME'
                        ,gv_cons_mov_hdr_tbl                                -- 移動依頼/指示ヘッダ
                        ,gv_tkn_param1                                      -- トークン'PARAM1'
                        ,gr_move_header_tbl(ln_hdr_cnt).sum_weight          -- 合計重量
                        ,gv_tkn_param2                                      -- トークン'PARAM2'
                        ,gv_cons_wh                                         -- コード区分
                        ,gv_tkn_param3                                      -- トークン'PARAM3'
                        ,gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code  -- 入出庫場所コード
                        ,gv_tkn_param4                                      -- トークン'PARAM4'
                        ,gv_cons_wh                                         -- コード区分
                        ,gv_tkn_param5                                      -- トークン'PARAM5'
                        ,gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code  -- 入出庫場所コード
                        ,gv_tkn_param6                                      -- トークン'PARAM6'
                        ,gr_move_header_tbl(ln_hdr_cnt).shipping_method_code -- 出荷方法
                        ,gv_tkn_param7                                      -- トークン'PARAM7'
                        ,gr_move_header_tbl(ln_hdr_cnt).item_class          -- 商品区分
                        ,gv_tkn_param8                                      -- トークン'PARAM8'
                        ,lv_errbuf                                    -- エラーメッセージコード
                        ,gv_tkn_param9                                      -- トークン'PARAM9'
                        ,lv_errmsg                                          -- エラーメッセージ
                        )
                        ,1
                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
/*          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
          -- そのヘッダはinsertしないフラグをONする→Forall前の分割格納時に読み飛ばす
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_on;
        ELSE
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_off;
        END IF;
        -- 積載オーバー区分が'1'だったら
        IF (lv_loading_over_class = gv_cons_over_1y) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)積載オーバー(header合計重量)');
-- DEBUG
          -- 最大積載効率100%オーバーフラグをON
          gv_loading_over_flg := gv_cons_flg_y;
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
        END IF;
*/
--
          --警告終了する場合
          IF (lv_retcode = gv_status_warn) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := gv_status_warn;
--
          --異常終了の場合
          ELSIF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ov_retcode := gv_status_error;
--
--          エラーの場合にRAISE する必要あり。
--
          END IF;
          -- そのヘッダはinsertしないフラグをONする→Forall前の分割格納時に読み飛ばす
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_on;
        ELSE
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_off;
        END IF;
        -- 積載オーバー区分が'1'だったら
        IF (lv_loading_over_class = gv_cons_over_1y) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)積載オーバー(header合計重量)');
-- DEBUG
          -- 最大積載効率100%オーバーフラグをON
          gv_loading_over_flg := gv_cons_flg_y;
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
        END IF;
--
      -- 重量容積区分=容積の場合に、容積積載効率を算出する
      ELSIF gr_move_header_tbl(ln_hdr_cnt).weight_capacity_class = gv_cons_capacity THEN
--
        --容積の取得
        ln_sum_capacity := NVL(gr_move_header_tbl(ln_hdr_cnt).sum_capacity,0);
--
        -- １ヘッダあたりの積載効率を算出してヘッダにセットする
        -- 積載効率チェック(積載効率算出)
        xxwsh_common910_pkg.calc_load_efficiency(
             NULL,                                                -- 1.合計重量 I
             ln_sum_capacity,                                     -- 2.合計容積 I
             gv_cons_wh,                                          -- 3.コード区分１ I '4'
             gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code,   -- 4.入出庫場所コード１ I
             gv_cons_wh,                                          -- 5.コード区分２ I '4'
             gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code,   -- 6.入出庫場所コード２ I
             gr_move_header_tbl(ln_hdr_cnt).shipping_method_code, -- 7.出荷方法 I
             gr_move_header_tbl(ln_hdr_cnt).item_class,           -- 8.商品区分 I
             NULL,                                                -- 9.自動配車対象区分 I
             TO_DATE(iv_arrival_date,'YYYY/MM/DD'),               -- 10.基準日(適用日基準日) I
             lv_retcode,                                          -- 11.リターンコード O
             lv_errbuf,                                           -- 12.エラーメッセージコード O
             lv_errmsg,                                           -- 13.エラーメッセージ O
             lv_loading_over_class,                               -- 14.積載オーバー区分 O
             lv_ship_methods,                                     -- 15.出荷方法 O
             ln_load_efficiency_weight,                           -- 16.重量積載効率 O
             ln_load_efficiency_capacity,                         -- 17.容積積載効率 O
             lv_mixed_ship_method);                               -- 18.混載配送区分 O
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)----移動ヘッダ積載効率補完ループ----------------');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).sum_capacity = ' || gr_move_header_tbl(ln_hdr_cnt).sum_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code = ' || gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code = ' || gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in gr_move_header_tbl(ln_hdr_cnt).shipping_method_code = ' || gr_move_header_tbl(ln_hdr_cnt).shipping_method_code);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency in  gr_move_header_tbl(ln_hdr_cnt)item_class = ' ||  gr_move_header_tbl(ln_hdr_cnt).item_class);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_retcode = ' || lv_retcode);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_errbuf = ' || lv_errbuf);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_errmsg = ' || lv_errmsg);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_loading_over_class = ' || lv_loading_over_class);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_ship_methods = ' || lv_ship_methods);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out ln_load_efficiency_weight = ' || ln_load_efficiency_weight);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out ln_load_efficiency_capacity = ' || ln_load_efficiency_capacity);
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)calc_load_efficiency out lv_mixed_ship_method = ' || lv_mixed_ship_method);
-- DEBUG
        -- エラーの場合  ただし処理は継続し、警告終了となる #######################3
        IF (lv_retcode <> gv_status_normal) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_cons_msg_kbn_wsh  -- 'XXWSH'
                          ,gv_msg_wsh_13172                                   -- 積載効率関数エラー
                          ,gv_tkn_table_name                                  -- トークン'TABLE_NAME'
                          ,gv_cons_mov_hdr_tbl                                -- 移動依頼/指示ヘッダ
                          ,gv_tkn_param1                                      -- トークン'PARAM1'
                          ,gr_move_header_tbl(ln_hdr_cnt).sum_capacity        -- 合計容積
                          ,gv_tkn_param2                                      -- トークン'PARAM2'
                          ,gv_cons_wh                                         -- コード区分
                          ,gv_tkn_param3                                      -- トークン'PARAM3'
                          ,gr_move_header_tbl(ln_hdr_cnt).shipped_locat_code  -- 入出庫場所コード
                          ,gv_tkn_param4                                      -- トークン'PARAM4'
                          ,gv_cons_wh                                         -- コード区分
                          ,gv_tkn_param5                                      -- トークン'PARAM5'
                          ,gr_move_header_tbl(ln_hdr_cnt).ship_to_locat_code  -- 入出庫場所コード
                          ,gv_tkn_param6                                      -- トークン'PARAM6'
                          ,gr_move_header_tbl(ln_hdr_cnt).shipping_method_code -- 出荷方法
                          ,gv_tkn_param7                                      -- トークン'PARAM7'
                          ,gr_move_header_tbl(ln_hdr_cnt).item_class          -- 商品区分
                          ,gv_tkn_param8                                      -- トークン'PARAM8'
                          ,lv_errbuf                                    -- エラーメッセージコード
                          ,gv_tkn_param9                                      -- トークン'PARAM9'
                          ,lv_errmsg                                          -- エラーメッセージ
                          )
                          ,1
                          ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
          --警告終了する場合
          IF (lv_retcode = gv_status_warn) THEN
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := gv_status_warn;
--
          --異常終了の場合
          ELSIF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ov_retcode := gv_status_error;
--
--          エラーの場合にRAISE する必要あり。
--
          END IF;
          -- そのヘッダはinsertしないフラグをONする→Forall前の分割格納時に読み飛ばす
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_on;
        ELSE
          gr_move_header_tbl(ln_hdr_cnt).not_insert_flg := gv_cons_flg_off;
        END IF;
        -- 積載オーバー区分が'1'だったら
        IF (lv_loading_over_class = gv_cons_over_1y) THEN
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(C-10)積載オーバー(header合計重量)');
-- DEBUG
          -- 最大積載効率100%オーバーフラグをON
          gv_loading_over_flg := gv_cons_flg_y;
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := gv_status_warn;
        END IF;
      END IF;
--
      -- ヘッダにセット
      gr_move_header_tbl(ln_hdr_cnt).loading_efficiency_weight := ln_load_efficiency_weight;
      gr_move_header_tbl(ln_hdr_cnt).loading_efficiency_capacity := ln_load_efficiency_capacity;
--
    END LOOP;
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(submain)C-14 call.......!');
-- DEBUG
    -- ===============================================
    -- C-14  登録更新処理 insert_tables
    -- ===============================================
    insert_tables(lv_errbuf,             -- エラー・メッセージ           --# 固定 #
                  lv_retcode,            -- リターン・コード             --# 固定 #
                  lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- エラー処理 
    IF (lv_retcode = gv_status_error) THEN
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
    errbuf                   OUT NOCOPY VARCHAR2,   -- エラー・メッセージ  --# 固定 #
    retcode                  OUT NOCOPY VARCHAR2,   -- リターン・コード    --# 固定 #
    iv_action_type           IN         VARCHAR2,   -- 処理種別
    iv_req_mov_no            IN         VARCHAR2,   -- 依頼/移動No
    iv_deliver_from_id       IN         VARCHAR2,   -- 出庫元
    iv_deliver_type          IN         VARCHAR2,   -- 出庫形態
    iv_object_date_from      IN         VARCHAR2,   -- 対象期間From
    iv_object_date_to        IN         VARCHAR2,   -- 対象期間To
    iv_shipped_date          IN         VARCHAR2,   -- 出庫日指定
    iv_arrival_date          IN         VARCHAR2,   -- 着日指定
    iv_instruction_post_code IN         VARCHAR2    -- 指示部署指定
  )
--
--###########################  固定部 START   ###########################
--
  IS
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
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(main)START...');
-- DEBUG
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
    -- WHOカラム情報の取得
    gn_login_user       := FND_GLOBAL.LOGIN_ID;         -- ログインID
    gn_created_by       := FND_GLOBAL.USER_ID;          -- ログインユーザID
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- 要求ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID; -- コンカレント・プログラム・アプリケーションID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- コンカレント・プログラムID
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_warn_cnt   := 0;   -- 警告件数
    gn_error_cnt  := 0;   -- エラー件数
--
-- DEBUG
--FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(main)submain call...');
-- DEBUG
    submain(
      iv_action_type,           -- 処理種別
      iv_req_mov_no,            -- 依頼/移動No
      iv_deliver_from_id,       -- 出庫元
      iv_deliver_type,          -- 出庫形態
      iv_object_date_from,      -- 対象期間From
      iv_object_date_to,        -- 対象期間To
      iv_shipped_date,          -- 出庫日指定
      iv_arrival_date,          -- 着日指定
      iv_instruction_post_code, -- 指示部署指定
      lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      lv_retcode,               -- リターン・コード             --# 固定 #
      lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
-- DEBUG
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'######(main)submain after0....');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'(main)submain after....');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'######(main)submain after2....');
-- DEBUG
    -- 処理件数のセット
    -- 処理件数は中間テーブルの総件数
    IF (iv_action_type = gv_cons_t_deliv) THEN
      gn_target_cnt := gn_target_cnt_deliv;
    ELSE
      gn_target_cnt := gn_target_cnt_move;
    END IF;
    -- 成功件数はヘッダテーブルの出力件数
    IF (lv_retcode = gv_status_error) THEN
      gn_normal_cnt := 0;
    ELSE
      gn_normal_cnt   := gn_ins_data_cnt_ml + gn_ins_data_cnt_oh;
    END IF;
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
      gn_error_cnt  := gn_error_cnt + 1;
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
    -- 積載効率オーバーフラグがONだったら
    IF ((lv_retcode <> gv_status_error) AND (gv_loading_over_flg = gv_cons_flg_y)) THEN
      lv_retcode := gv_status_warn;
    END IF;

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
END XXWSH920003C;
/
