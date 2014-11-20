CREATE OR REPLACE PACKAGE BODY XXINV500002C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV500002C(body)
 * Description      : 移動指示情報取込
 * MD.050           : 移動依頼 T_MD050_BPO_500
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      初期処理(B-1)
 *  get_interface_data        移動指示IF情報取得(B-2)
 *  chk_if_header_data        移動指示ヘッダ情報チェック(B-3)
 *  get_max_ship_method       最大配送区分・小口区分取得(B-4,B-5)
 *  get_relating_data         関連データ取得処理(B-6,B-7)
 *  get_item_info             品目情報取得(B-9)
 *  chk_item_mst              品目マスタチェック(B-10)
 *  calc_best_amount          最適数量の算出(B-11,B-12)
 *  calc_instruct_amount      指示数量の算出(B-13,B-14,B-15)
 *  chk_loading_effic         積載効率オーバーチェック(B-16)
 *  chk_sum_palette_sheets    パレット合計枚数チェック(B-17)
 *  chk_operating_day         稼働日チェック(B-19)
 *  set_line_data             移動指示明細情報設定(B-18)
 *  set_header_data           移動指示ヘッダ情報設定(B-20)
 *  make_err_list             エラーリスト作成(B-21)
 *  ins_mov_req_instr_header  移動指示ヘッダ登録処理(B-22)
 *  ins_mov_req_instr_line    移動指示明細登録処理(B-23)
 *  purge_processing          パージ処理(B-24)
 *  put_err_list              エラーリスト出力
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 *  2011/03/04    1.0   SCS Y.Kanami     新規作成
 *
 ******************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal    CONSTANT VARCHAR2(1)  := '0';
  cv_status_warn      CONSTANT VARCHAR2(1)  := '1';
  cv_status_error     CONSTANT VARCHAR2(1)  := '2';
--
  cv_sts_cd_normal    CONSTANT VARCHAR2(1)  := 'C';
  cv_sts_cd_warn      CONSTANT VARCHAR2(1)  := 'G';
  cv_sts_cd_error     CONSTANT VARCHAR2(1)  := 'E';
--
  cv_msg_part         CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont         CONSTANT VARCHAR2(3)  := '.';
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
  lock_error_expt               EXCEPTION;     -- ロック取得エラー8
  no_data_if_expt               EXCEPTION;     -- 対象データなし
  err_header_expt               EXCEPTION;     -- エラーメッセージ作成後判定
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT  VARCHAR2(100)   := 'XXINV500002C';            -- パッケージ名
  cv_appl_short_name          CONSTANT  VARCHAR2(5)     := 'XXINV';                   -- メッセージ
  cv_msg_kbn                  CONSTANT  VARCHAR2(5)     := 'XXCMN';                   -- メッセージ
  cv_prod_cls_drink           CONSTANT  VARCHAR2(8)     := 'ドリンク';
  cv_prod_cls_leaf            CONSTANT  VARCHAR2(6)     := 'リーフ';
  cv_off                      CONSTANT  VARCHAR2(1)     := 'N';                       -- 実績計上フラグ：N

  -- メッセージ
  cv_msg_get_profile          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10025';         -- プロファイル取得エラー
  cv_msg_user_org             CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10083';         -- 部署コード取得エラー
  cv_msg_ng_rock              CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10032';         -- ロックエラー
  cv_msg_no_data_1            CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10009';         -- データ取得エラー1
  cv_msg_no_data_2            CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10211';         -- データ取得エラー2
  cv_msg_get_seq              CONSTANT  VARCHAR2(15)    := 'APP-XXCMN-10029';         -- 採番エラー
  cv_msg_user_org_id          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10193';         -- ユーザ所属部署コード
  cv_msg_shipped_loc          CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10194';         -- 出庫倉庫
  cv_err_msg_1                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10061';         -- 必須チェック
  cv_err_msg_2                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10199';         -- 過去日エラー
  cv_err_msg_3                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10200';         -- 同日エラー
  cv_err_msg_4                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10210';         -- 日付逆転エラー
  cv_err_msg_5                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10120';         -- 在庫期間エラー
  cv_err_msg_6                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10208';         -- 保管倉庫同一エラー
  cv_err_msg_7                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10201';         -- 妥当性エラー
  cv_err_msg_8                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10202';         -- 品目マスタ未設定エラー
  cv_err_msg_9                CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10207';         -- 非稼働日メッセージ
  cv_err_msg_10               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10209';         -- 積載効率オーバーエラー
  cv_err_msg_11               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10023';         -- パレット最大枚数超過メッセージ
  cv_err_msg_12               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10203';         -- 稼働日算出関数エラー
  cv_err_msg_13               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10204';         -- 移動指示_品目重複エラーメッセージ
  cv_err_msg_14               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10205';         -- ドリンク・リーフ混載エラー
  cv_err_msg_15               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10206';         -- 指示総数設定エラー
  cv_err_msg_16               CONSTANT  VARCHAR2(15)    := 'APP-XXINV-10212';         -- 共通関数エラー
--
  -- トークン
  cv_tkn_profile_name         CONSTANT  VARCHAR2(100)   := 'XXCMN:マスタ組織';        -- マスタ組織
  cv_tkn_prf_prod_cls         CONSTANT  VARCHAR2(100)   := 'XXCMN:商品区分';          -- 商品区分(セキュリティ)
  cv_tkn_table                CONSTANT  VARCHAR2(15)    := 'TABLE';
  cv_tkn_mov_num              CONSTANT  VARCHAR2(8)     := '移動番号';
  cv_tkn_value                CONSTANT  VARCHAR2(5)     := 'VALUE';
  cv_tkn_msg                  CONSTANT  VARCHAR2(3)     := 'MSG';
  cv_tkn_item                 CONSTANT  VARCHAR2(4)     := 'ITEM';
  cv_tkv_name                 CONSTANT  VARCHAR2(4)     := 'NAME';
  cv_tkn_shipped_date         CONSTANT  VARCHAR2(9)     := 'SHIP_DATE';
  cv_tkn_ship_to_date         CONSTANT  VARCHAR2(12)    := 'ARRIVAL_DATE';
  cv_tkn_target_date          CONSTANT  VARCHAR2(11)    := 'TARGET_DATE';
  cv_tkn_seq_name             CONSTANT  VARCHAR2(10)    := 'SEQ_NAME';
  cv_tkn_user                 CONSTANT  VARCHAR2(4)     := 'USER';
  cv_tkn_chk                  CONSTANT  VARCHAR2(3)     := 'CHK';
  cv_tkn_err_msg              CONSTANT  VARCHAR2(7)     := 'ERR_MSG';
--
  -- プロファイル
  cv_prf_mst_org_id           CONSTANT  VARCHAR2(25)    := 'XXCMN_MASTER_ORG_ID';     -- XXCMN:マスタ組織ID
  cv_prf_prod_class           CONSTANT  VARCHAR2(25)    := 'XXCMN_ITEM_DIV_SECURITY'; -- XXCMN:商品区分(セキュリティ)
  -- ロック対象
  cv_rock_table               CONSTANT  VARCHAR2(100)   := '移動指示IF情報';
  -- クイックコード
  cv_ship_method              CONSTANT  VARCHAR2(20)    := 'XXCMN_SHIP_METHOD';       -- 最大配送区分
  cv_tab                      CONSTANT  VARCHAR2(2)     :=  CHR(9);                   -- タブ
--
  -- エラーリスト項目名
  cv_kind                     CONSTANT  VARCHAR2(15)    := '種別';
  cv_hdr_mov_if_id            CONSTANT  VARCHAR2(15)    := '移動ヘッダIF_ID';
  cv_hdr_temp_ship_num        CONSTANT  VARCHAR2(15)    := '仮伝票番号';
  cv_hdr_mov_type             CONSTANT  VARCHAR2(15)    := '移動タイプ';
  cv_hdr_instr_post_code      CONSTANT  VARCHAR2(15)    := '指示部署';
  cv_hdr_shipped_code         CONSTANT  VARCHAR2(15)    := '出庫元保管場所';
  cv_hdr_ship_to_code         CONSTANT  VARCHAR2(15)    := '入庫先保管場所';
  cv_hdr_sch_ship_date        CONSTANT  VARCHAR2(15)    := '出庫予定日';
  cv_hdr_sch_arrival_date     CONSTANT  VARCHAR2(15)    := '入庫予定日';
  cv_hdr_freight_charge_cls   CONSTANT  VARCHAR2(15)    := '運賃区分';
  cv_hdr_freight_carrier_cd   CONSTANT  VARCHAR2(15)    := '運送業者';
  cv_hdr_weight_capacity_cls  CONSTANT  VARCHAR2(15)    := '重量容積区分';
  cv_hdr_product_flg          CONSTANT  VARCHAR2(15)    := '製品識別区分';
  cv_hdr_mov_line_if_id       CONSTANT  VARCHAR2(15)    := '移動明細IF_ID';
  cv_hdr_item_code            CONSTANT  VARCHAR2(15)    := '品目';
  cv_hdr_desined_prod_date    CONSTANT  VARCHAR2(15)    := '指定製造日';
  cv_hdr_first_instruct_qty   CONSTANT  VARCHAR2(15)    := '初回指示数量';
  cv_hdr_err_msg              CONSTANT  VARCHAR2(16)    := 'エラーメッセージ';
  cv_hdr_err_clm              CONSTANT  VARCHAR2(16)    := 'エラー項目';
  cv_line                     CONSTANT  VARCHAR2(50)    := '--------------------------------------------------';
--
  -- メッセージ項目
  cv_max_shopped_method       CONSTANT  VARCHAR2(12)    := '最大配送区分';
  cv_small_amount_cls         CONSTANT  VARCHAR2(8)     := '小口区分';
  cv_shpped_loc_id            CONSTANT  VARCHAR2(10)    := '出庫元情報';
  cv_shp_to_loc_id            CONSTANT  VARCHAR2(10)    := '入庫先情報';
  cv_freight_carrier_id       CONSTANT  VARCHAR2(12)    := '運送業者情報';
  cv_max_pallet               CONSTANT  VARCHAR2(16)    := '最大パレット枚数';
  cv_delivery_qty             CONSTANT  VARCHAR2(4)     := '配数';
  cv_max_pallet_steps         CONSTANT  VARCHAR2(20)    := 'パレット当り最大段数';
  cv_num_of_cases             CONSTANT  VARCHAR2(10)    := 'ケース入数';
  cv_over_check_1             CONSTANT  VARCHAR2(30)    := '積載効率チェック(積載効率算出)';
  cv_over_check_2             CONSTANT  VARCHAR2(30)    := '積載効率チェック(合計値算出)';
--
  -- エラーリスト表示内容
  cv_msg_hfn                  CONSTANT  VARCHAR2(2)     := '－';
  cv_msg_err                  CONSTANT  VARCHAR2(6)     := 'エラー';
  cv_msg_war                  CONSTANT  VARCHAR2(4)     := '警告';
--
  -- 共通関数：エラー判定用
  cv_error                    CONSTANT  VARCHAR2(1)     :=  '1';  -- エラー
  cv_normal                   CONSTANT  VARCHAR2(1)     :=  '0';  -- 正常
--
  cn_pre_data_cnt             CONSTANT  NUMBER          :=  1;    -- 1レコード前のデータCNT
  cn_status_error             CONSTANT  NUMBER          :=  1;    -- 共通関数：エラー
  cn_status_normal            CONSTANT  NUMBER          :=  0;    -- 共通関数：正常
  cv_warehouses               CONSTANT  VARCHAR2(1)     :=  '4';  -- 倉庫
  cv_own_warehouse            CONSTANT  VARCHAR2(1)     :=  '0';  -- 自社倉庫
  cv_prod_cls_prod            CONSTANT  VARCHAR2(1)     :=  '1';  -- 製品識別区分：製品
  cv_prod_cls_others          CONSTANT  VARCHAR2(1)     :=  '2';  -- 製品識別区分：製品以外
  cv_product                  CONSTANT  VARCHAR2(1)     :=  '5';  -- 製品
  cv_drink                    CONSTANT  VARCHAR2(1)     :=  '2';  -- 商品区分：ドリンク
  cv_on                       CONSTANT  VARCHAR2(1)     :=  '1';  -- フラグ：ON
  cn_on                       CONSTANT  NUMBER          :=  1;    -- フラグ：ON
  cv_object                   CONSTANT  VARCHAR2(1)     :=  '1';  -- 対象
  cv_not_object               CONSTANT  VARCHAR2(1)     :=  '0';  -- 対象外
  cv_nodata                   CONSTANT  VARCHAR2(1)     :=  '1';  -- 対象データなし
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 移動指示IF取得用
  TYPE mod_instr_rtype IS RECORD (
      mov_hdr_if_id             xxinv_mov_instr_headers_if.mov_hdr_if_id%TYPE                 -- 移動ヘッダIF_ID
    , temp_ship_num             xxinv_mov_instr_headers_if.temp_ship_num%TYPE                 -- 仮伝票番号
    , mov_type                  xxinv_mov_instr_headers_if.mov_type%TYPE                      -- 移動タイプ
    , instr_post_code           xxinv_mov_instr_headers_if.instruction_post_code%TYPE         -- 指示部署
    , shipped_locat_code        xxinv_mov_instr_headers_if.shipped_locat_code%TYPE            -- 出庫元保管場所
    , ship_to_locat_code        xxinv_mov_instr_headers_if.ship_to_locat_code%TYPE            -- 入庫先保管場所
    , schedule_ship_date        xxinv_mov_instr_headers_if.schedule_ship_date%TYPE            -- 出庫予定日
    , schedule_arrival_date     xxinv_mov_instr_headers_if.schedule_arrival_date%TYPE         -- 入庫予定日
    , freight_charge_class      xxinv_mov_instr_headers_if.freight_charge_class%TYPE          -- 運賃区分
    , freight_carrier_code      xxinv_mov_instr_headers_if.freight_carrier_code%TYPE          -- 運送業者
    , weight_capacity_class     xxinv_mov_instr_headers_if.weight_capacity_class%TYPE         -- 重量容積区分
    , product_flg               xxinv_mov_instr_headers_if.product_flg%TYPE                   -- 製品識別区分
    , mov_line_if_id            xxinv_mov_instr_lines_if.mov_line_if_id%TYPE                  -- 移動明細IF_ID
    , item_code                 xxinv_mov_instr_lines_if.item_code%TYPE                       -- 品目
    , designated_prod_date      xxinv_mov_instr_lines_if.designated_production_date%TYPE      -- 指定製造日
    , first_instruct_qty        xxinv_mov_instr_lines_if.first_instruct_qty%TYPE              -- 初回指示数量
  );
--
  TYPE mod_instr_ttype  IS TABLE OF mod_instr_rtype INDEX BY BINARY_INTEGER;
--
  g_mov_instr_tab   mod_instr_ttype;
--
  -- 移動指示情報登録用
  -- ヘッダ項目
  TYPE mov_hdr_id_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                   INDEX BY BINARY_INTEGER;  -- 移動ヘッダ_ID
  TYPE mov_num_ttype                IS TABLE OF
      xxinv_mov_req_instr_headers.mov_num%TYPE                      INDEX BY BINARY_INTEGER;  -- 移動番号
  TYPE mov_type_ttype               IS TABLE OF
      xxinv_mov_req_instr_headers.mov_type%TYPE                     INDEX BY BINARY_INTEGER;  -- 移動タイプ
  TYPE instruction_post_code_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.instruction_post_code%TYPE        INDEX BY BINARY_INTEGER;  -- 指示部署
  TYPE shipped_locat_code_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.shipped_locat_code%TYPE           INDEX BY BINARY_INTEGER;  -- 出庫元保管場所
  TYPE ship_to_locat_code_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE           INDEX BY BINARY_INTEGER;  -- 入庫先保管場所
  TYPE schedule_ship_date_ttype     IS TABLE OF
      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE           INDEX BY BINARY_INTEGER;  -- 出庫予定日
  TYPE schedule_arrival_date_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE        INDEX BY BINARY_INTEGER;  -- 入庫予定日
  TYPE freight_charge_class_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.freight_charge_class%TYPE         INDEX BY BINARY_INTEGER;  -- 運賃区分
  TYPE freight_carrier_code_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.freight_carrier_code%TYPE         INDEX BY BINARY_INTEGER;  -- 運送業者
  TYPE weight_capacity_class_ttype  IS TABLE OF
      xxinv_mov_req_instr_headers.weight_capacity_class%TYPE        INDEX BY BINARY_INTEGER;  -- 重量容積区分
  TYPE item_class_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.item_class%TYPE                   INDEX BY BINARY_INTEGER;  -- 商品区分
  TYPE product_flg_ttype            IS TABLE OF
      xxinv_mov_req_instr_headers.product_flg%TYPE                  INDEX BY BINARY_INTEGER;  -- 製品識別区分
  TYPE shipped_locat_id_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.shipped_locat_id%TYPE             INDEX BY BINARY_INTEGER;  -- 出庫元ID
  TYPE ship_to_locat_id_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE             INDEX BY BINARY_INTEGER;  -- 入庫先ID
  TYPE loading_weight_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE    INDEX BY BINARY_INTEGER;  -- 積載率(重量)
  TYPE loading_capacity_ttype       IS TABLE OF
      xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE  INDEX BY BINARY_INTEGER;  -- 積載率(容積)
  TYPE career_id_ttype              IS TABLE OF
      xxinv_mov_req_instr_headers.career_id%TYPE                    INDEX BY BINARY_INTEGER;  -- 運送業者ID
  TYPE shipping_method_code_ttype   IS TABLE OF
      xxinv_mov_req_instr_headers.shipping_method_code%TYPE         INDEX BY BINARY_INTEGER;  -- 配送区分
  TYPE sum_quantity_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.sum_quantity%TYPE                 INDEX BY BINARY_INTEGER;  -- 合計数量
  TYPE small_quantity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.small_quantity%TYPE               INDEX BY BINARY_INTEGER;  -- 小口個数
  TYPE label_quantity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.label_quantity%TYPE               INDEX BY BINARY_INTEGER;  -- ラベル枚数
  TYPE based_weight_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.based_weight%TYPE                 INDEX BY BINARY_INTEGER;  -- 基本重量
  TYPE based_capacity_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.based_capacity%TYPE               INDEX BY BINARY_INTEGER;  -- 基本容積
  TYPE sum_weight_ttype             IS TABLE OF
      xxinv_mov_req_instr_headers.sum_weight%TYPE                   INDEX BY BINARY_INTEGER;  -- 積載重量合計
  TYPE sum_capacity_ttype           IS TABLE OF
      xxinv_mov_req_instr_headers.sum_capacity%TYPE                 INDEX BY BINARY_INTEGER;  -- 積載容積合計
  TYPE sum_pallet_weight_ttype      IS TABLE OF
      xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE            INDEX BY BINARY_INTEGER;  -- 合計パレット重量
  TYPE pallet_sum_qty_ttype         IS TABLE OF
      xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE          INDEX BY BINARY_INTEGER;  -- パレット合計枚数
--
  -- 明細項目
  TYPE mov_line_id_ttype            IS TABLE OF
      xxinv_mov_req_instr_lines.mov_line_id%TYPE                    INDEX BY BINARY_INTEGER;  -- 移動指示明細ID
  TYPE mov_line_hdr_id_ttype        IS TABLE OF
      xxinv_mov_req_instr_lines.mov_hdr_id%TYPE                     INDEX BY BINARY_INTEGER;  -- 移動ヘッダID
  TYPE line_number_ttype            IS TABLE OF
      xxinv_mov_req_instr_lines.line_number%TYPE                    INDEX BY BINARY_INTEGER;  -- 明細番号
  TYPE item_code_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.item_code%TYPE                      INDEX BY BINARY_INTEGER;  -- 品目
  TYPE designated_prod_date_ttype   IS TABLE OF
      xxinv_mov_req_instr_lines.designated_production_date%TYPE     INDEX BY BINARY_INTEGER;  -- 指定製造日
  TYPE first_instruct_qty_ttype     IS TABLE OF
      xxinv_mov_req_instr_lines.first_instruct_qty%TYPE             INDEX BY BINARY_INTEGER;  -- 初回指示数量
  TYPE item_id_ttype                IS TABLE OF
      xxinv_mov_req_instr_lines.item_id%TYPE                        INDEX BY BINARY_INTEGER;  -- 品目ID
  TYPE pallet_quantity_ttype        IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_quantity%TYPE                INDEX BY BINARY_INTEGER;  -- パレット数
  TYPE layer_qty_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.layer_quantity%TYPE                 INDEX BY BINARY_INTEGER;  -- 段数
  TYPE case_qty_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.case_quantity%TYPE                  INDEX BY BINARY_INTEGER;  -- ケース数
  TYPE instr_qty_ttype              IS TABLE OF
      xxinv_mov_req_instr_lines.instruct_qty%TYPE                   INDEX BY BINARY_INTEGER;  -- 指示数量
  TYPE uom_code_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.uom_code%TYPE                       INDEX BY BINARY_INTEGER;  -- 単位
  TYPE pallet_qty_ttype             IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_qty%TYPE                     INDEX BY BINARY_INTEGER;  -- パレット枚数
  TYPE weight_ttype                 IS TABLE OF
      xxinv_mov_req_instr_lines.weight%TYPE                         INDEX BY BINARY_INTEGER;  -- 重量
  TYPE capacity_ttype               IS TABLE OF
      xxinv_mov_req_instr_lines.capacity%TYPE                       INDEX BY BINARY_INTEGER;  -- 容積
  TYPE pallet_weight_ttype          IS TABLE OF
      xxinv_mov_req_instr_lines.pallet_weight%TYPE                  INDEX BY BINARY_INTEGER;  -- パレット重量
--
  -- 移動指示情報登録用PL/SQL表
  -- ヘッダ項目
  g_mov_hdr_id_tab                mov_hdr_id_ttype;               -- 移動ヘッダID
  g_mov_type_tab                  mov_type_ttype;                 -- 移動タイプ
  g_mov_num_tab                   mov_num_ttype;                  -- 移動番号
  g_instruction_post_code_tab     instruction_post_code_ttype;    -- 指示部署
  g_shipped_locat_code_tab        shipped_locat_code_ttype;       -- 出庫元保管場所
  g_ship_to_locat_code_tab        ship_to_locat_code_ttype;       -- 入庫先保管場所
  g_schedule_ship_date_tab        schedule_ship_date_ttype;       -- 出庫予定日
  g_schedule_arrival_date_tab     schedule_arrival_date_ttype;    -- 入庫予定日
  g_freight_charge_class_tab      freight_charge_class_ttype;     -- 運賃区分
  g_freight_carrier_code_tab      freight_carrier_code_ttype;     -- 運送業者
  g_weight_capacity_class_tab     weight_capacity_class_ttype;    -- 重量容積区分
  g_product_flg_tab               product_flg_ttype;              -- 製品識別区分
  g_item_class_tab                item_class_ttype;               -- 商品区分
  g_shipped_locat_id_tab          shipped_locat_id_ttype;         -- 出庫元ID
  g_ship_to_locat_id_tab          ship_to_locat_id_ttype;         -- 入庫先ID
  g_loading_weight_tab            loading_weight_ttype;           -- 積載率(重量)
  g_loading_capacity_tab          loading_capacity_ttype;         -- 積載率(容積)
  g_career_id_tab                 career_id_ttype;                -- 運送業者ID
  g_shipping_method_code_tab      shipping_method_code_ttype;     -- 配送区分
  g_sum_qty_tab                   sum_quantity_ttype;             -- 合計数量
  g_small_qty_tab                 small_quantity_ttype;           -- 小口個数
  g_label_qty_tab                 label_quantity_ttype;           -- ラベル枚数
  g_based_weight_tab              based_weight_ttype;             -- 基本重量
  g_based_capacity_tab            based_capacity_ttype;           -- 基本容積
  g_sum_weight_tab                sum_weight_ttype;               -- 積載重量合計
  g_sum_capacity_tab              sum_capacity_ttype;             -- 積載容積合計
  g_sum_pallet_weight_tab         sum_pallet_weight_ttype;        -- 合計パレット重量
  g_sum_pallet_qty                pallet_sum_qty_ttype;           -- パレット合計枚数
--
  -- 明細項目
  g_mov_line_id_tab               mov_line_id_ttype;              -- 移動明細ID
  g_mov_line_hdr_id_tab           mov_line_hdr_id_ttype;          -- 移動ヘッダID
  g_mov_number_tab                line_number_ttype;              -- 明細番号
  g_item_code_tab                 item_code_ttype;                -- 品目
  g_designated_prod_date_tab      designated_prod_date_ttype;     -- 指定製造日
  g_first_instruct_qty_tab        first_instruct_qty_ttype;       -- 初回指示数量
  g_item_id_tab                   item_id_ttype;                  -- 品目ID
  g_pallet_qty_tab                pallet_quantity_ttype;          -- パレット数
  g_layer_qty_tab                 layer_qty_ttype;                -- 段数
  g_case_qty_tab                  case_qty_ttype;                 -- ケース数
  g_instr_qty_tab                 instr_qty_ttype;                -- 指示数量
  g_uom_code_tab                  uom_code_ttype;                 -- 単位
  g_pallet_num_of_sheet_tab       pallet_qty_ttype;               -- パレット枚数
  g_weight_tab                    weight_ttype;                   -- 重量
  g_capacity_tab                  capacity_ttype;                 -- 容積
  g_pallet_weight_tab             pallet_weight_ttype;            -- パレット重量
--
  -- エラーリスト用配列
  TYPE err_list_rtype IS RECORD(
    err_msg VARCHAR2(10000)
  );
--
  TYPE err_list_ttype IS TABLE OF err_list_rtype INDEX BY BINARY_INTEGER;
--
  g_err_list_tab  err_list_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate                DATE;             -- システム日付
  -- WHOカラム
  gn_user_id                NUMBER;           -- ユーザID
  gv_user_name              VARCHAR2(100);    -- ユーザ名
  gn_login_id               NUMBER;           -- 最終更新ログイン
  gn_conc_request_id        NUMBER;           -- 要求ID
  gn_prog_appl_id           NUMBER;           -- コンカレントのアプリケーションID
  gn_conc_program_id        NUMBER;           -- コンカレント・プログラムID
--
  gv_master_org_id          VARCHAR2(100);    -- マスタ組織
  gv_user_dept_id           VARCHAR2(100);    -- ログインユーザ所属部署
  gv_err_status             VARCHAR2(1);      -- 共通エラーメッセージ終了ステータス確認用
  gv_err_line_status        VARCHAR2(1);      -- 明細エラーステータス
--
  gn_if_data_cnt            NUMBER;           -- インタフェース登録用カウンタ
  gn_cnt                    NUMBER;           -- 処理用カウンタ
  gn_err_set_cnt            NUMBER;           -- エラーリスト用カウンタ
  gv_err_report             VARCHAR2(5000);   -- エラーリストヘッダ用
--
  gv_err_flg                VARCHAR2(1);      -- 
--
  gn_header_id              NUMBER;           -- 移動指示ヘッダID
  gn_line_id                NUMBER;           -- 移動指示明細ID
  gn_mov_instr_hdr_cnt      NUMBER;           -- ヘッダ件数
  gn_mov_instr_line_cnt     NUMBER;           -- 明細件数
  gn_line_number_cnt        NUMBER;           -- ヘッダ単位明細件数
--
  gv_secur_prod_class       VARCHAR2(1);      -- 商品区分(セキュリティ)
  gv_max_ship_method        VARCHAR2(2);      -- 最大配送区分
  gn_drink_deadweight       NUMBER;           -- ドリンク基本重量
  gn_leaf_deadweight        NUMBER;           -- リーフ基本重量
  gn_drink_loading_capa     NUMBER;           -- ドリンク基本容積
  gn_leaf_loading_capa      NUMBER;           -- リーフ基本容積
  gn_palette_max_qty        NUMBER;           -- パレット最大枚数
  gv_small_amount_cls       VARCHAR2(1);      -- 小口区分
  gv_shipped_id             VARCHAR2(4);      -- 出庫元ID
  gv_ship_to_id             VARCHAR2(4);      -- 入庫先ID
  gn_carrier_id             NUMBER;           -- 運送業者ID
  gn_item_id                NUMBER;           -- 品目ID
  gv_item_desc              VARCHAR2(70);     -- 品目の適用
  gv_item_um                VARCHAR2(4);      -- 単位
  gv_conv_unit              VARCHAR2(240);    -- 入出庫換算単位
  gn_delivery_qty           NUMBER;           -- 配数
  gn_max_palette_steps      NUMBER;           -- パレット当り最大段数
  gn_num_of_cases           NUMBER;           -- ケース入数
  gn_num_of_deliver         NUMBER;           -- 出荷入数
  gv_prod_cls               VARCHAR2(1);      -- 商品区分
  gn_max_case_for_palette   NUMBER;           -- パレット当りの最大ケース数
  gn_best_num_palette       NUMBER;           -- 最適数量：パレット数
  gn_best_num_steps         NUMBER;           -- 最適数量：段数
  gn_best_num_cases         NUMBER;           -- 最適数量：ケース数
  gv_item_mst_chk_sts       VARCHAR2(1);      -- 品目マスタチェックステータス
  gn_palette_num            NUMBER;           -- パレット枚数
  gn_sum_palette_num        NUMBER;           -- パレット合計枚数
  gn_instruct_qty           NUMBER;           -- 指示数量
  gn_ttl_instruct_qty       NUMBER;           -- 指示数量合計
  gn_ttl_weight             NUMBER;           -- 合計重量
  gn_ttl_capacity           NUMBER;           -- 合計容積
  gn_ttl_palette_weight     NUMBER;           -- 合計パレット重量
  gn_sum_ttl_weight         NUMBER;           -- 総合計重量
  gn_sum_ttl_capacity       NUMBER;           -- 総合計容積
  gn_sum_ttl_palette_weight NUMBER;           -- 総合計パレット重量
  gn_sml_amnt_num           NUMBER;           -- 小口個数
  gn_ttl_sml_amnt_num       NUMBER;           -- 小口個数合計
  gn_label_num              NUMBER;           -- ラベル枚数
  gn_ttl_label_num          NUMBER;           -- ラベル枚数合計
  gv_shipped_locat_code     VARCHAR2(4);      -- 出庫元コード[積載効率チェック用]
  gv_ship_to_locat_code     VARCHAR2(4);      -- 入庫先コード[積載効率チェック用]
  gd_schedule_ship_date     DATE;             -- 出庫日[積載効率チェック用]
  gn_we_loading             NUMBER;           -- 積載率(重量)
  gn_ca_loading             NUMBER;           -- 積載率(容積)
  gv_msg_prod_cls           VARCHAR2(8);      -- メッセージ用商品区分
  gv_nodata_error           VARCHAR2(1);      -- 対象データ取得エラー
  gb_get_item_flg           BOOLEAN;          -- 品目取得フラグ(TRUE:取得,FALSE:未取得)
  gv_carrier_code           VARCHAR2(4);      -- 運送業者コード
--
  /**********************************************************************************
   * Procedure Name   : make_err_list
   * Description      : エラーリスト作成(B-21)
   ***********************************************************************************/
  PROCEDURE make_err_list(
      iv_kind       IN  VARCHAR2  --    エラー種別
    , iv_err_info   IN  VARCHAR2  --    エラーメッセージ
    , in_rec_cnt    IN  NUMBER    --    出力対象レコードカウント
    , ov_errbuf     OUT VARCHAR2  --    エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2  --    リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2  --    ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'make_err_list';  -- プログラム名
    cv_dt_fmt_yyyymmdd  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';     -- 日付書式：YYYY/MM/DD
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
    lv_err_list VARCHAR2(10000);
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ------------------------------
    -- 共通エラーメッセージの作成
    ------------------------------
    lv_err_list :=             iv_kind                                                              -- 種別
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_hdr_if_id                            -- 移動指示IF_ID
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).temp_ship_num                            -- 仮伝票番号
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_type                                 -- 移動タイプ
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).instr_post_code                          -- 指示部署
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).shipped_locat_code                       -- 出庫元保管場所
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).ship_to_locat_code                       -- 入庫先保管場所
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).schedule_ship_date, cv_dt_fmt_yyyymmdd)    
                                                                                                    -- 出庫予定日
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).schedule_arrival_date, cv_dt_fmt_yyyymmdd) 
                                                                                                    -- 入庫予定日
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).freight_charge_class                     -- 運賃区分
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).freight_carrier_code                     -- 運送業者
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).weight_capacity_class                    -- 重量容積区分
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).product_flg                              -- 製品識別区分
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).mov_line_if_id                           -- 明細ID
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).item_code                                -- 品目
                  || cv_tab || TO_CHAR(g_mov_instr_tab(in_rec_cnt).designated_prod_date, cv_dt_fmt_yyyymmdd)   
                                                                                                    -- 指定製造日
                  || cv_tab || g_mov_instr_tab(in_rec_cnt).first_instruct_qty                       -- 初回指示数量
                  || cv_tab || iv_err_info                                                          -- エラーメッセージ
    ;
--
    -- エラーセットカウント
    gn_err_set_cnt := gn_err_set_cnt + 1;
--
    -- 共通エラーメッセージ格納
    g_err_list_tab(gn_err_set_cnt).err_msg  := lv_err_list;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END make_err_list;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf     OUT VARCHAR2  --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2  --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2  --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -----------------------
    -- システム日付を取得
    -----------------------
    gd_sysdate := SYSDATE;
--
    -----------------------
    -- WHOカラム取得
    -----------------------
    gn_user_id          :=  fnd_global.user_id;         -- ユーザID
    gv_user_name        :=  fnd_global.user_name;       -- ユーザ名
    gn_login_id         :=  fnd_global.login_id;        -- 最終更新ログイン
    gn_conc_request_id  :=  fnd_global.conc_request_id; -- 要求ID
    gn_prog_appl_id     :=  fnd_global.prog_appl_id;    -- コンカレントのアプリケーションID
    gn_conc_program_id  :=  fnd_global.conc_program_id; -- コンカレント・プログラムID
--
    -----------------------
    -- マスタ組織ID取得
    -----------------------
    gv_master_org_id := FND_PROFILE.VALUE(cv_prf_mst_org_id);
--
    -- マスタ組織IDが取得できない場合
    IF (gv_master_org_id IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_get_profile
                                            , cv_tkv_name
                                            , cv_tkn_profile_name
                                            );
      lv_errbuf := lv_errmsg;
--
      -- 必須項目出力用
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    -------------------------------
    -- 商品区分(セキュリティ)取得
    -------------------------------
    gv_secur_prod_class := FND_PROFILE.VALUE(cv_prf_prod_class);
--
    IF (gv_secur_prod_class IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_get_profile
                                            , cv_tkv_name
                                            , cv_tkn_prf_prod_cls
                                            );
      lv_errbuf := lv_errmsg;
--
      -- 必須項目出力用
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    --------------------------------
    -- ログインユーザ所属部署を取得
    --------------------------------
    gv_user_dept_id  :=  xxcmn_common_pkg.get_user_dept_code(gn_user_id);
    IF (gv_user_dept_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( cv_appl_short_name
                                            , cv_msg_user_org
                                            , cv_tkn_user
                                            , gv_user_name
                                            );
      lv_errbuf := lv_errmsg;
--
      -- 必須項目出力用
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
   * Procedure Name   : get_interface_data
   * Description      : 移動指示IF情報取得(B-2)
   ***********************************************************************************/
  PROCEDURE get_interface_data(
      in_shipped_locat_cd  IN VARCHAR2 DEFAULT NULL  -- 出庫元コード(任意)
    , ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_interface_data'; -- プログラム名
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
    -- 移動指示IF取得カーソル
    CURSOR mov_instr_if_cur IS
      SELECT  xmihi.mov_hdr_if_id                             -- 移動ヘッダIF_ID
            , xmihi.temp_ship_num                             -- 仮伝票番号
            , xmihi.mov_type                                  -- 移動タイプ
            , xmihi.instruction_post_code                     -- 指示部署
            , xmihi.shipped_locat_code                        -- 出庫元保管場所
            , xmihi.ship_to_locat_code                        -- 入庫先保管場所
            , xmihi.schedule_ship_date                        -- 出庫予定日
            , xmihi.schedule_arrival_date                     -- 入庫予定日
            , xmihi.freight_charge_class                      -- 運賃区分
            , xmihi.freight_carrier_code                      -- 運送業者
            , xmihi.weight_capacity_class                     -- 重量容積区分
            , xmihi.product_flg                               -- 製品識別区分
            , xmili.mov_line_if_id                            -- 明細ID
            , xmili.item_code                                 -- 品目
            , xmili.designated_production_date                -- 指定製造日
            , NVL(xmili.first_instruct_qty, 0)                -- 初回指示数量
      FROM    xxinv_mov_instr_headers_if  xmihi               -- 移動指示ヘッダインタフェース(アドオン)
            , xxinv_mov_instr_lines_if    xmili               -- 移動指示明細インタフェース(アドオン)
      WHERE xmihi.mov_hdr_if_id         = xmili.mov_hdr_if_id -- 移動ヘッダIF_ID
      AND   xmihi.instruction_post_code = gv_user_dept_id     -- 移動指示部署コード
      AND   ((in_shipped_locat_cd IS NULL)                    -- 出庫元保管場所
          OR (shipped_locat_code = in_shipped_locat_cd))
      ORDER BY xmihi.mov_hdr_if_id
             , xmili.item_code
      FOR UPDATE OF xmihi.mov_hdr_if_id NOWAIT
      ;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ----------------------------------
    -- 移動指示インタフェース情報取得
    ----------------------------------
    -- カーソルオープン
    OPEN mov_instr_if_cur;
    -- バルクフェッチ
    FETCH mov_instr_if_cur BULK COLLECT INTO g_mov_instr_tab;
    -- カーソルクローズ
    CLOSE mov_instr_if_cur;
--
    -- データが取得出来なかった場合
    IF (g_mov_instr_tab.COUNT = 0) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(  cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_rock_table
                                            );
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
      ov_retcode := cv_status_warn;
--
      -- 必須項目出力用
      gv_nodata_error := cv_nodata;
--
      RETURN;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN lock_error_expt THEN                           --*** ロック取得エラー ***
      -- カーソルオープン時クローズする
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      -- エラーメッセージ取得
      lv_errmsg := xxcmn_common_pkg.get_msg(  cv_appl_short_name
                                            , cv_msg_ng_rock
                                            , cv_tkn_table
                                            , cv_rock_table
                                            );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- *** 任意で例外処理を記述する ****
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルオープン時クローズする
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルオープン時クローズする
      IF (mov_instr_if_cur%ISOPEN) THEN
        CLOSE mov_instr_if_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_interface_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_if_header_data
   * Description      : 移動指示ヘッダ情報チェック(B-3)
   ***********************************************************************************/
  PROCEDURE chk_if_header_data(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_if_header_data'; -- プログラム名
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
    cv_not_inclueded    CONSTANT VARCHAR2(1)  :=  '2';                            -- 積送なし
    cv_mov_type         CONSTANT VARCHAR2(15) :=  'XXINV_MOVE_TYPE';              -- 移動タイプ
    cv_pres_cls         CONSTANT VARCHAR2(20) :=  'XXINV_PRESENCE_CLASS';         -- 運賃区分
    cv_wht_capa_cls     CONSTANT VARCHAR2(27) :=  'XXCMN_WEIGHT_CAPACITY_CLASS';  -- 重量容積区分
    cv_prod_cls         CONSTANT VARCHAR2(20) :=  'XXINV_PRODUCT_CLASS';          -- 製品識別区分
    cv_dt_fmt_yyyymm    CONSTANT VARCHAR2(6)  :=  'YYYYMM';                       -- 日付書式：YYYYMM
--
    -- *** ローカル変数 ***
    lv_mov_type         VARCHAR2(1);    -- 移動タイプ
    lv_pres_cls         VARCHAR2(1);    -- 運賃区分
    lv_wht_capa_cls     VARCHAR2(1);    -- 重量容積区分
    gv_prod_cls         VARCHAR2(1);    -- 製品識別区分
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -----------------------------
    -- 移動タイプ妥当性チェック
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_mov_type
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_mov_type
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).mov_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_mov_type
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -----------------------------
    -- 運賃区分妥当性チェック
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_pres_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_pres_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).freight_charge_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_freight_charge_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
       -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END; 
--
    -----------------------------
    -- 重量容積区分妥当性チェック
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_wht_capa_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_wht_capa_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).weight_capacity_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_weight_capacity_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END; 
--
    -----------------------------
    -- 製品識別区分妥当性チェック
    -----------------------------
    BEGIN
      SELECT xlvv.lookup_code
      INTO   lv_pres_cls
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_prod_cls
      AND    xlvv.lookup_code = g_mov_instr_tab(gn_cnt).weight_capacity_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_7
                                              , cv_tkn_item
                                              , cv_hdr_product_flg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -----------------------------
    -- 過去日チェック
    -----------------------------
    -- 出庫予定日がシステム日付より過去ではないこと
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date < TRUNC(gd_sysdate)) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_2
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- 共通エラーメッセージ終了ステータス
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -----------------------------
    -- 積送なし同日チェック
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).mov_type = cv_not_inclueded) THEN
--
      IF (g_mov_instr_tab(gn_cnt).schedule_ship_date        -- 出庫日
          <> g_mov_instr_tab(gn_cnt).schedule_arrival_date) -- 着日
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_3
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -----------------------------
    -- 日付逆転チェック
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date        -- 出庫日
        > g_mov_instr_tab(gn_cnt).schedule_arrival_date)  -- 着日
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_4
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- 共通エラーメッセージ終了ステータス
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -----------------------------
    -- 在庫期間クローズチェック
    -----------------------------
    -- 出庫日
    IF (TO_CHAR(g_mov_instr_tab(gn_cnt).schedule_ship_date, cv_dt_fmt_yyyymm)   -- 出庫日
        <= xxcmn_common_pkg.get_opminv_close_period)                     -- クローズ最大年月
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_5
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- 着日
    IF (TO_CHAR(g_mov_instr_tab(gn_cnt).schedule_arrival_date, cv_dt_fmt_yyyymm)  -- 出庫日
        <= xxcmn_common_pkg.get_opminv_close_period)                              -- クローズ最大年月
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_5
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    -----------------------------
    -- 出庫元、入庫先同一チェック
    -----------------------------
    IF (g_mov_instr_tab(gn_cnt).shipped_locat_code      -- 出庫元
        = g_mov_instr_tab(gn_cnt).ship_to_locat_code)   -- 入庫先
    THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_6
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END chk_if_header_data;
--
  /**********************************************************************************
   * Procedure Name   : get_max_ship_method
   * Description      : 最大配送区分・小口区分取得(B-4,B-5)
   ***********************************************************************************/
  PROCEDURE get_max_ship_method(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_max_ship_method'; -- プログラム名
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
    ln_result           NUMBER;         -- 共通関数戻り値
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 変数初期化
    ln_result             := 0;           -- 共通関数戻り値
--
    -- ==================================
    --  B-4.最大配送区分取得
    -- ==================================
    -- 共通関数「最大配送区分算出関数」
    ln_result := xxwsh_common_pkg.get_max_ship_method(
                    iv_code_class1                => cv_warehouses                                    -- 4:倉庫
                  , iv_entering_despatching_code1 => g_mov_instr_tab(gn_cnt).shipped_locat_code       -- 出庫元コード
                  , iv_code_class2                => cv_warehouses                                    -- 4:倉庫
                  , iv_entering_despatching_code2 => g_mov_instr_tab(gn_cnt).ship_to_locat_code       -- 入庫先コード
                  , iv_prod_class                 => gv_secur_prod_class                              -- 商品区分
                  , iv_weight_capacity_class      => g_mov_instr_tab(gn_cnt).weight_capacity_class    -- 重量容積区分
                  , iv_auto_process_type          => NULL
                  , id_standard_date              => g_mov_instr_tab(gn_cnt).schedule_ship_date       -- 出庫日
                  , ov_max_ship_methods           => gv_max_ship_method                               -- 最大配送区分
                  , on_drink_deadweight           => gn_drink_deadweight                              -- ドリンク基本重量
                  , on_leaf_deadweight            => gn_leaf_deadweight                               -- リーフ基本重量
                  , on_drink_loading_capacity     => gn_drink_loading_capa                            -- ドリンク基本容積
                  , on_leaf_loading_capacity      => gn_leaf_loading_capa                             -- リーフ基本容積
                  , on_palette_max_qty            => gn_palette_max_qty                               -- パレット最大枚数
                  );
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_max_shopped_method
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- ==================================
    --  B-5.小口区分取得
    -- ==================================
    BEGIN
      SELECT  xlvv.attribute6
      INTO    gv_small_amount_cls   -- 小口区分
      FROM    xxcmn_lookup_values_v xlvv
      WHERE   xlvv.lookup_type = cv_ship_method
      AND     xlvv.lookup_code = gv_max_ship_method
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_small_amount_cls
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END get_max_ship_method;
--
  /**********************************************************************************
   * Procedure Name   : get_relating_data
   * Description      : 関連データ取得処理(B-6,B-7)
   ***********************************************************************************/
  PROCEDURE get_relating_data(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relating_data'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===========================
    -- B-6.出庫元ID/入庫先ID取得
    -- ===========================
    -- 出庫元ID取得
    BEGIN
      SELECT xilv.inventory_location_id   -- 保管倉庫ID
      INTO   gv_shipped_id                -- 出庫元ID
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.customer_stock_whse = cv_own_warehouse  -- 自社倉庫
      AND    xilv.segment1 = g_mov_instr_tab(gn_cnt).shipped_locat_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_2
                                              , cv_tkn_item
                                              , cv_shpped_loc_id
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- 入庫先ID取得
    BEGIN
      SELECT xilv.inventory_location_id   -- 保管倉庫ID
      INTO   gv_ship_to_id                -- 入庫先ID
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.customer_stock_whse = cv_own_warehouse -- 自社倉庫
      AND    xilv.segment1 = g_mov_instr_tab(gn_cnt).ship_to_locat_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN 
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_2
                                              , cv_tkn_item
                                              , cv_shp_to_loc_id
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- 運送業者が設定されている場合
    IF (g_mov_instr_tab(gn_cnt).freight_carrier_code IS NOT NULL) THEN
--
      gv_carrier_code := g_mov_instr_tab(gn_cnt).freight_carrier_code;
--
      -- ===========================
      -- B-7.運送業者ID取得
      -- ===========================
      BEGIN
        SELECT  xpv.party_id
        INTO    gn_carrier_id
        FROM    xxcmn_parties2_v xpv
        WHERE   xpv.freight_code      =   gv_carrier_code
        AND     xpv.start_date_active <=  TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
        AND     xpv.end_date_active   >=  TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN 
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_msg_no_data_2
                                                , cv_tkn_item
                                                , cv_freight_carrier_id
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                        , iv_err_info => gv_out_msg       -- エラーメッセージ
                        , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); 
--
          -- 共通エラーメッセージ終了ステータス
          gv_err_status := cv_status_error;
--
        WHEN OTHERS THEN
--
          RAISE global_api_others_expt;
--
      END;
--
    -- 運賃区分があり、かつ出庫元IDが取得できて運送業者が設定されていない場合
    ELSIF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_on)
      AND (g_mov_instr_tab(gn_cnt).freight_carrier_code IS NULL)
      AND (gv_shipped_id IS NOT NULL)
    THEN
--
      -- OPM保管場所から代表運送業者を取得
      BEGIN
        SELECT  xcv.party_number      -- 運送業者コード
              , xcv.party_id          -- 運送業者ID
        INTO    gv_carrier_code       -- 運送業者コード
              , gn_carrier_id         -- 運送業者ID
        FROM    xxcmn_carriers_v        xcv   -- 運送業者情報View
              , xxcmn_item_locations_v  xilv  -- OPM保管場所マスタ
        WHERE xilv.frequent_mover         = xcv.party_number
        AND   xilv.inventory_location_id  = gv_shipped_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
--
          gv_carrier_code :=  NULL;   -- 運送業者コード
          gn_carrier_id   :=  NULL;   -- 運送業者ID
--
        WHEN OTHERS THEN
--
          RAISE global_api_others_expt;
--
      END;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END get_relating_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目情報取得(B-9)
   ***********************************************************************************/
  PROCEDURE get_item_info(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_info'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 品目取得フラグ設定
    gb_get_item_flg := TRUE;
--
    -- 取得用変数初期化
    gn_item_id            := NULL;
    gv_item_desc          := NULL;
    gv_item_um            := NULL;
    gv_conv_unit          := NULL;
    gn_delivery_qty       := NULL;
    gn_max_palette_steps  := NULL;
    gn_num_of_cases       := NULL;
    gn_num_of_deliver     := NULL;
    gv_prod_cls           := NULL;
--
    -- ===========================
    -- B-9.品目情報取得
    -- ===========================
    BEGIN
      SELECT  ximv.item_id                              -- 品目ID
            , ximv.item_desc1                           -- 適用
            , ximv.item_um                              -- 単位
            , ximv.conv_unit                            -- 入出庫換算単位
            , NVL(ximv.delivery_qty, 0)                 -- 配数
            , NVL(TO_NUMBER(ximv.max_palette_steps), 0) -- パレット当り最大段数
            , NVL(TO_NUMBER(ximv.num_of_cases), 0)      -- ケース入数
            , NVL(ximv.num_of_deliver, 0)               -- 出荷入数
            , xicv.prod_class_code                      -- 商品区分
      INTO    gn_item_id                                -- 品目ID
            , gv_item_desc                              -- 適用
            , gv_item_um                                -- 単位
            , gv_conv_unit                              -- 入出庫換算単位
            , gn_delivery_qty                           -- 配数
            , gn_max_palette_steps                      -- パレット当り最大段数
            , gn_num_of_cases                           -- ケース入数
            , gn_num_of_deliver                         -- 出荷入数
            , gv_prod_cls                               -- 商品区分
      FROM    xxcmn_item_categories5_v  xicv            -- OPM品目カテゴリ割当情報VIEW5
            , xxcmn_item_mst2_v         ximv            -- OPM品目マスタ2
      WHERE   xicv.item_id = ximv.item_id 
      AND     ximv.weight_capacity_class          = g_mov_instr_tab(gn_cnt).weight_capacity_class   -- 重量容積区分
      AND     xicv.item_no                        = g_mov_instr_tab(gn_cnt).item_code               -- 品目
      AND     ximv.start_date_active              <= TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
      AND     ximv.end_date_active                >= TRUNC(g_mov_instr_tab(gn_cnt).schedule_ship_date)
      AND     (((g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod)        -- 製品識別区分(1:製品)
              AND (xicv.item_class_code           = cv_product))
          OR  ((g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_others)       -- 製品識別区分(2:製品以外)
              AND (xicv.item_class_code           <> cv_product)))
      AND     ximv.inactive_ind                   <> cn_on                      -- 無効フラグ
      AND     ximv.obsolete_class                 <> cv_on                      -- 廃止区分
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_hdr_item_code
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        gb_get_item_flg := FALSE;
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END get_item_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item_mst
   * Description      : 品目マスタチェック(B-10)
   ***********************************************************************************/
  PROCEDURE chk_item_mst(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item_mst'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===========================
    -- B-10.品目マスタチェック
    -- ===========================
    -- 入出庫換算単位が設定済みの場合
    IF (gv_conv_unit IS NOT NULL) THEN
--
      -- 配数チェック
      IF (gn_delivery_qty IS NULL) 
        OR (gn_delivery_qty = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_delivery_qty
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
        -- 品目マスタチェックステータス
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
      -- パレット当り最大段数チェック
      IF (gn_max_palette_steps IS NULL) 
        OR (gn_max_palette_steps = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_max_pallet_steps
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
        -- 品目マスタチェックステータス
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
      -- ケース入数チェック
      IF (gn_num_of_cases IS NULL) 
        OR (gn_num_of_cases = 0)
      THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_8
                                              , cv_tkn_item
                                              , cv_num_of_cases
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
        -- 品目マスタチェックステータス
        gv_item_mst_chk_sts := cv_status_error;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END chk_item_mst;
--
  /**********************************************************************************
   * Procedure Name   : calc_best_amount
   * Description      : 最適数量の算出(B-11, B-12)
   ***********************************************************************************/
  PROCEDURE calc_best_amount(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_best_amount'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===========================
    -- B-11.最適数量の算出
    -- ===========================
--
    -- 入出庫換算単位が設定済みの場合のみ
    IF (gv_conv_unit IS NOT NULL) THEN
--
      -- パレット当りの最大ケース数を算出
      gn_max_case_for_palette := gn_max_palette_steps * gn_delivery_qty;          -- パレット当り最大段数 * 配数
--
      -- 最適数量を算出
      -- 1.パレット数
      gn_best_num_palette := TRUNC(g_mov_instr_tab(gn_cnt).first_instruct_qty     -- 指示総数
                                    / gn_max_case_for_palette                     -- パレット当り最大ケース数
                             );
--
      -- 2.段数
      gn_best_num_steps   := TRUNC(MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty -- 指示総数
                                , gn_max_case_for_palette)                        -- パレット当り最大ケース数
                                / gn_delivery_qty)                                -- 配数
                             ;
--
      -- 3.ケース数
      gn_best_num_cases   := MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty       -- 指示総数
                                , gn_delivery_qty)                                -- 配数
                             ;
--
    END IF;
--
    -- ===========================
    -- B-12.パレット枚数の算出
    -- ===========================
    -- パレット枚数
    IF (MOD(g_mov_instr_tab(gn_cnt).first_instruct_qty, gn_max_case_for_palette) = 0) THEN
--
      gn_palette_num := gn_best_num_palette;
--
    ELSE
--
      gn_palette_num := gn_best_num_palette + 1;
--
    END IF;
--
    -- パレット合計枚数
    gn_sum_palette_num := gn_sum_palette_num + gn_palette_num;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END calc_best_amount;
--
  /**********************************************************************************
   * Procedure Name   : calc_instruct_amount
   * Description      : 指示数量の算出(B-13,B-14,B-15)
   ***********************************************************************************/
  PROCEDURE calc_instruct_amount(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_instruct_amount'; -- プログラム名
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
    lv_errmsg_code  VARCHAR2(30);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ===========================
    -- B-13.指示数量の算出
    -- ===========================
    IF ((gv_prod_cls = cv_drink)                                      -- 商品区分：ドリンク
      AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod)    -- 製品識別区分：製品
      AND (gv_conv_unit IS NOT NULL))                                 -- 入出庫換算単位設定済み
    THEN
      -- 指示数量
      gn_instruct_qty := g_mov_instr_tab(gn_cnt).first_instruct_qty   -- 指示総数
                          * gn_num_of_cases                           -- ケース入数
                         ;
--
    ELSE
--
      -- 指示数量
      gn_instruct_qty := g_mov_instr_tab(gn_cnt).first_instruct_qty;  -- 指示総数
--
    END IF;
--
    -- 指示数量合計(ヘッダ単位)
    gn_ttl_instruct_qty := gn_ttl_instruct_qty + gn_instruct_qty;
--
    -- ===========================
    -- B-14.合計重量・容積の算出
    -- ===========================
    xxwsh_common910_pkg.calc_total_value(
          g_mov_instr_tab(gn_cnt).item_code           -- 品目
        , gn_instruct_qty                             -- 指示数量
        , lv_retcode                                  -- リターンコード
        , lv_errmsg_code                              -- エラーメッセージコード
        , lv_errmsg                                   -- エラーメッセージ
        , gn_ttl_weight                               -- 合計重量
        , gn_ttl_capacity                             -- 合計容積
        , gn_ttl_palette_weight                       -- 合計パレット重量
        , g_mov_instr_tab(gn_cnt).schedule_ship_date  -- 出庫日
    );
    IF (lv_retcode = cv_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_16
                                            , cv_tkn_chk
                                            , cv_over_check_2
                                            , cv_tkn_err_msg
                                            , lv_errmsg
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
    END IF;
--
    -- 小口区分対象の場合
    IF ((gv_small_amount_cls = cv_object)   -- 小口区分対象
      OR (gv_max_ship_method IS NULL))      -- 最大配送区分設定なし
    THEN
      NULL;
    ELSE
--
      -- パレット重量を加算
      gn_ttl_weight := gn_ttl_weight + gn_ttl_palette_weight;
--
    END IF;
--
    -- 総合計重量
    gn_sum_ttl_weight     := gn_sum_ttl_weight + gn_ttl_weight;
--
    -- 総合計容積
    gn_sum_ttl_capacity   := gn_sum_ttl_capacity + gn_ttl_capacity;
    
    -- 総合計パレット重量
    gn_sum_ttl_palette_weight := gn_sum_ttl_palette_weight + gn_ttl_palette_weight;
--
    -- ================================
    -- B-15.小口個数・ラベル枚数の算出
    -- ================================
    -- 小口個数の算出
    IF (gn_num_of_deliver > 0) THEN -- 出荷入数が0以上の場合
--
      gn_sml_amnt_num := CEIL(gn_instruct_qty       -- 指示数量
                            / gn_num_of_deliver     -- 出荷入数
                             );
--
    ELSIF ((gn_num_of_deliver = 0)          -- 出荷入数が未設定
        AND (gv_conv_unit IS NOT NULL))     -- 入出庫換算単位が設定済
    THEN
--
      gn_sml_amnt_num := CEIL(gn_instruct_qty       -- 指示数量
                            / gn_num_of_cases       -- ケース入数
                            );
--
    ELSIF ((gn_num_of_deliver = 0)          -- 出荷入数が未設定
        AND (gv_conv_unit IS NULL))         -- 入出庫換算単位が未設定
    THEN
--
      gn_sml_amnt_num := gn_instruct_qty;           -- 指示数量
--
    END IF;
--
    -- ラベル枚数設定
    gn_label_num := gn_sml_amnt_num;
--
    -- ヘッダ単位の小口個数合計
    gn_ttl_sml_amnt_num := gn_ttl_sml_amnt_num + gn_sml_amnt_num;
--
    -- ヘッダ単位のラベル枚数合計
    gn_ttl_label_num    := gn_ttl_label_num + gn_label_num;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END calc_instruct_amount;
--
  /**********************************************************************************
   * Procedure Name   : chk_loading_effic
   * Description      : 積載効率オーバーチェック(B-16)
   ***********************************************************************************/
  PROCEDURE chk_loading_effic(
      in_object_cnt   IN  NUMBER    -- 対象データカウンタ
    , ov_errbuf       OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_loading_effic'; -- プログラム名
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
    cv_loading_over         CONSTANT VARCHAR2(1)  := '1';         -- 積載オーバー
--
    -- *** ローカル変数 ***
    lv_over_kbn             VARCHAR2(1);                          -- 積載オーバー区分
    lv_ship_way             xxcmn_ship_methods.ship_method%TYPE;  -- 出荷方法
    lv_mix_ship             VARCHAR2(2);                          -- 混載配送区分
    lv_errmsg_code          VARCHAR2(30);                         -- エラー・メッセージ・コード
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 重量：ドリンク
    IF (gv_prod_cls = cv_drink) THEN
--
      xxwsh_common910_pkg.calc_load_efficiency(
              gn_sum_ttl_weight           -- 合計重量
            , NULL                        -- 合計容積
            , cv_warehouses               -- 倉庫:4
            , gv_shipped_locat_code       -- 出庫元コード
            , cv_warehouses               -- 倉庫:4
            , gv_ship_to_locat_code       -- 入庫先コード
            , gv_max_ship_method          -- 最大配送区分
            , gv_prod_cls                 -- 商品区分
            , NULL                        -- 自動配車対象区分
            , gd_schedule_ship_date       -- 出庫日
            , lv_retcode                  -- リターン・コード
            , lv_errmsg_code              -- エラー・メッセージ・コード
            , lv_errmsg                   -- ユーザー・エラー・メッセージ
            , lv_over_kbn                 -- 積載オーバー区分 0:正常,1:オーバー
            , lv_ship_way                 -- 出荷方法
            , gn_we_loading               -- 重量積載効率
            , gn_ca_loading               -- 容積積載効率
            , lv_mix_ship                 -- 混載配送区分
      );
      IF (lv_retcode = cv_error) THEN           
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_16
                                              , cv_tkn_chk
                                              , cv_over_check_1
                                              , cv_tkn_err_msg
                                              , lv_errmsg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err     -- エラー種別
                      , iv_err_info => gv_out_msg     -- エラーメッセージ
                      , in_rec_cnt  => in_object_cnt  -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      END IF;
--
    -- 容積：リーフ
    ELSE
      xxwsh_common910_pkg.calc_load_efficiency(
              NULL                        -- 合計重量
            , gn_sum_ttl_capacity         -- 合計容積
            , cv_warehouses               -- 倉庫:4
            , gv_shipped_locat_code       -- 出庫元コード
            , cv_warehouses               -- 倉庫:4
            , gv_ship_to_locat_code       -- 入庫先コード
            , gv_max_ship_method          -- 最大配送区分
            , gv_prod_cls                 -- 商品区分
            , NULL                        -- 自動配車対象区分
            , gd_schedule_ship_date       -- 出庫日
            , lv_retcode                  -- リターン・コード
            , lv_errmsg_code              -- エラー・メッセージ・コード
            , lv_errmsg                   -- ユーザー・エラー・メッセージ
            , lv_over_kbn                 -- 積載オーバー区分 0:正常,1:オーバー
            , lv_ship_way                 -- 出荷方法
            , gn_we_loading               -- 重量積載効率
            , gn_ca_loading               -- 容積積載効率
            , lv_mix_ship                 -- 混載配送区分
      );
      IF (lv_retcode = cv_error) THEN           
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_16
                                              , cv_tkn_chk
                                              , cv_over_check_1
                                              , cv_tkn_err_msg
                                              , lv_errmsg
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err     -- エラー種別
                      , iv_err_info => gv_out_msg     -- エラーメッセージ
                      , in_rec_cnt  => in_object_cnt  -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -- 積載オーバー区分がオーバーの場合
    IF (lv_over_kbn = cv_loading_over) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_10
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- エラー種別
                    , iv_err_info => gv_out_msg     -- エラーメッセージ
                    , in_rec_cnt  => in_object_cnt  -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス(normalの場合のみ上書き)
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END chk_loading_effic;
--
  /**********************************************************************************
   * Procedure Name   : chk_sum_palette_sheets
   * Description      : パレット合計枚数チェック(B-17)
   ***********************************************************************************/
  PROCEDURE chk_sum_palette_sheets(
      in_object_cnt   IN  NUMBER    -- 対象データカウンタ
    , ov_errbuf       OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode      OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg       OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_sum_palette_sheets'; -- プログラム名
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
    ln_result     NUMBER;   -- 共通関数戻り値
    ln_drink_we   NUMBER;   -- ドリンク積載重量
    ln_leaf_we    NUMBER;   -- リーフ積載重量
    ln_drink_ca   NUMBER;   -- ドリンク積載容積
    ln_leaf_ca    NUMBER;   -- リーフ積載容積
    ln_prt_max    NUMBER;   -- パレット最大枚数
--
    -- *** ローカル・カーソル ***
    lv_max_ship_method    VARCHAR2(2);
    ln_drink_deadweight   NUMBER;
    ln_leaf_deadweight    NUMBER;
    ln_drink_loading_capa NUMBER;
    ln_leaf_loading_capa  NUMBER;
    ln_palette_max_qty    NUMBER;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 最大配送区分がNULLの場合、共通関数「最大配送区分算出関数」にて『最大配送区分』算出
    IF (gv_max_ship_method IS NOT NULL) THEN
--
      lv_max_ship_method  := gv_max_ship_method;
--
    ELSE
--
      -- 共通関数「最大配送区分算出関数」
      ln_result := xxwsh_common_pkg.get_max_ship_method(
                      iv_code_class1                => cv_warehouses                                        -- 4:倉庫
                    , iv_entering_despatching_code1 => g_mov_instr_tab(in_object_cnt).shipped_locat_code    -- 出庫元コード
                    , iv_code_class2                => cv_warehouses                                        -- 4:倉庫
                    , iv_entering_despatching_code2 => g_mov_instr_tab(in_object_cnt).ship_to_locat_code    -- 入庫先コード
                    , iv_prod_class                 => gv_prod_cls                                          -- 商品区分
                    , iv_weight_capacity_class      => g_mov_instr_tab(in_object_cnt).weight_capacity_class -- 重量容積区分
                    , iv_auto_process_type          => NULL
                    , id_standard_date              => g_mov_instr_tab(in_object_cnt).schedule_ship_date    -- 出庫日
                    , ov_max_ship_methods           => lv_max_ship_method                                   -- 最大配送区分
                    , on_drink_deadweight           => ln_drink_deadweight                                  -- ドリンク基本重量
                    , on_leaf_deadweight            => ln_leaf_deadweight                                   -- リーフ基本重量
                    , on_drink_loading_capacity     => ln_drink_loading_capa                                -- ドリンク基本容積
                    , on_leaf_loading_capacity      => ln_leaf_loading_capa                                 -- リーフ基本容積
                    , on_palette_max_qty            => ln_palette_max_qty                                   -- パレット最大枚数
                    );
      IF (ln_result = cn_status_error) THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_msg_no_data_1
                                              , cv_tkn_msg
                                              , cv_max_shopped_method
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => in_object_cnt    -- エラー対象レコードカウント
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); 
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      END IF;
--
    END IF;
--
    -- 共通関数「最大パレット枚数算出関数」
    ln_result := xxwsh_common_pkg.get_max_pallet_qty(
                      cv_warehouses               -- 倉庫：4
                    , gv_shipped_locat_code       -- 出庫元コード
                    , cv_warehouses               -- 倉庫：4
                    , gv_ship_to_locat_code       -- 入庫先コード
                    , gd_schedule_ship_date       -- 出庫日
                    , lv_max_ship_method          -- 最大配送区分
                    , ln_drink_we                 -- ドリンク積載重量 out ドリンク積載重量
                    , ln_leaf_we                  -- リーフ積載重量   out リーフ積載重量
                    , ln_drink_ca                 -- ドリンク積載容積 out ドリンク積載容積
                    , ln_leaf_ca                  -- リーフ積載容積   out リーフ積載容積
                    , ln_prt_max                  -- パレット最大枚数 out パレット最大枚数
                   );
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_no_data_1
                                            , cv_tkn_msg
                                            , cv_max_pallet
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- エラー種別
                    , iv_err_info => gv_out_msg     -- エラーメッセージ
                    , in_rec_cnt  => in_object_cnt  -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
    -- パレット合計枚数がパレット最大枚数を超えた場合は警告
    IF (gn_sum_palette_num > ln_prt_max) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_11
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err     -- エラー種別
                    , iv_err_info => gv_out_msg     -- エラーメッセージ
                    , in_rec_cnt  => in_object_cnt  -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      gv_err_status := cv_status_error;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END chk_sum_palette_sheets;
--
  /**********************************************************************************
   * Procedure Name   : chk_operating_day
   * Description      : 稼働日チェック(B-19)
   ***********************************************************************************/
  PROCEDURE chk_operating_day(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_operating_day'; -- プログラム名
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
    ln_result       NUMBER;       -- 共通関数戻り値
    ld_work_day     DATE;         -- 稼働日日付
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 稼働日チェック 共通関数「稼働日算出関数」
    -- 出庫日
    ln_result := xxwsh_common_pkg.get_oprtn_day(
                                  g_mov_instr_tab(gn_cnt).schedule_ship_date  -- 出庫日
                                 ,g_mov_instr_tab(gn_cnt).shipped_locat_code  -- 出庫元
                                 ,NULL                                        -- 配送先コード
                                 ,0                                           -- リードタイム
                                 ,gv_secur_prod_class                         -- 商品区分
                                 ,ld_work_day                                 -- 稼働日日付
                                );
--
    -- 共通関数エラー
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_12
                                            , cv_tkn_item
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- 出庫日と稼働日日付が一致しない場合
    IF (g_mov_instr_tab(gn_cnt).schedule_ship_date <> ld_work_day) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_9
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_ship_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス(normalの場合のみ上書き)
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- 着日
    ln_result := xxwsh_common_pkg.get_oprtn_day(
                                  g_mov_instr_tab(gn_cnt).schedule_arrival_date -- 着日
                                 ,g_mov_instr_tab(gn_cnt).ship_to_locat_code    -- 入庫先
                                 ,NULL                                          -- 配送先コード
                                 ,0                                             -- リードタイム
                                 ,gv_secur_prod_class                           -- 商品区分
                                 ,ld_work_day                                   -- 稼働日日付
                                );
--
    -- 共通関数エラー
    IF (ln_result = cn_status_error) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_12
                                            , cv_tkn_item
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); 
--
      -- 共通エラーメッセージ終了ステータス
      gv_err_status := cv_status_error;
--
    END IF;
--
    -- 着日と稼働日日付が一致しない場合
    IF (g_mov_instr_tab(gn_cnt).schedule_arrival_date <> ld_work_day) THEN
--
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_err_msg_9
                                            , cv_tkn_target_date
                                            , cv_hdr_sch_arrival_date
                                            );
--
      make_err_list(  iv_kind     => cv_msg_war       -- エラー種別
                    , iv_err_info => gv_out_msg       -- エラーメッセージ
                    , in_rec_cnt  => gn_cnt           -- エラー対象レコードカウント
                    , ov_errbuf   => lv_errbuf        
                    , ov_retcode  => lv_retcode       
                    , ov_errmsg   => lv_errmsg        
                   ); --
      -- 共通エラーメッセージ終了ステータス(normalの場合のみ上書き)
      IF (gv_err_status <> cv_status_error) THEN
        gv_err_status := cv_status_warn;
      END IF;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END chk_operating_day;
--
  /**********************************************************************************
   * Procedure Name   : set_line_data
   * Description      : 移動指示明細情報設定(B-18)
   ***********************************************************************************/
  PROCEDURE set_line_data(
      ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_data'; -- プログラム名
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
    ln_first_data   CONSTANT NUMBER := 1;   -- 1レコード目
--
    -- *** ローカル変数 ***
    ln_line_seq     NUMBER;     -- 移動指示明細ID
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ---------------------------
    -- 移動指示明細を設定
    ---------------------------
--
    -- 移動指示明細IDを取得
    BEGIN
      SELECT  xxinv_mov_line_s1.NEXTVAL
      INTO    ln_line_seq
      FROM    dual
      ;
    EXCEPTION
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
--
    END;
--
    -- 登録用変数に格納
    g_mov_line_id_tab(gn_mov_instr_line_cnt)          := ln_line_seq;                                   -- 移動指示明細ID
    g_mov_line_hdr_id_tab(gn_mov_instr_line_cnt)      := gn_header_id;                                  -- 移動ヘッダID
    g_mov_number_tab(gn_mov_instr_line_cnt)           := gn_line_number_cnt;                            -- ヘッダ単位明細件数
    g_item_code_tab(gn_mov_instr_line_cnt)            := g_mov_instr_tab(gn_cnt).item_code;             -- 品目
    g_designated_prod_date_tab(gn_mov_instr_line_cnt) := g_mov_instr_tab(gn_cnt).designated_prod_date;  -- 指定製造日
    g_first_instruct_qty_tab(gn_mov_instr_line_cnt)   := g_mov_instr_tab(gn_cnt).first_instruct_qty;    -- 初回指示数量
    g_item_id_tab(gn_mov_instr_line_cnt)              := gn_item_id;                                    -- 品目ID
    g_pallet_qty_tab(gn_mov_instr_line_cnt)           := gn_best_num_palette;                           -- パレット数
    g_layer_qty_tab(gn_mov_instr_line_cnt)            := gn_best_num_steps;                             -- 段数
    g_case_qty_tab(gn_mov_instr_line_cnt)             := gn_best_num_cases;                             -- ケース数
    g_instr_qty_tab(gn_mov_instr_line_cnt)            := gn_instruct_qty;                               -- 指示数量
--
    IF ((gv_prod_cls = cv_drink)                                    -- 商品区分：ドリンク
       AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod) -- 製品識別区分：製品
       AND (gv_conv_unit IS NOT NULL))                              -- 入出庫換算単位設定済
    THEN
--
      g_uom_code_tab(gn_mov_instr_line_cnt)           := gv_conv_unit;                                  -- 入出庫換算単位
--
    ELSE
      g_uom_code_tab(gn_mov_instr_line_cnt)           := gv_item_um;                                    -- 単位
    END IF;
--
    g_pallet_num_of_sheet_tab(gn_mov_instr_line_cnt)  := gn_palette_num;                                -- パレット枚数
    g_weight_tab(gn_mov_instr_line_cnt)               := gn_ttl_weight;                                 -- 重量
    g_capacity_tab(gn_mov_instr_line_cnt)             := gn_ttl_capacity;                               -- 容積
    g_pallet_weight_tab(gn_mov_instr_line_cnt)        := gn_ttl_palette_weight;                         -- パレット重量
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END set_line_data;
--
  /**********************************************************************************
   * Procedure Name   : set_header_data
   * Description      : 移動指示ヘッダ情報作成(B-20)
   ***********************************************************************************/
  PROCEDURE set_header_data(
      in_object_cnt           IN  NUMBER                -- 登録対象カウンタ
    , ov_errbuf               OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header_data'; -- プログラム名
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
    cv_req_no_cls   CONSTANT VARCHAR2(1) := '4';    -- 依頼No
--
    -- *** ローカル変数 ***
    ln_line_seq     NUMBER;         -- 移動指示明細ID
    lv_mov_num      VARCHAR2(12);   -- 移動番号
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -------------------------
    -- 移動番号取得関数
    -------------------------
    xxcmn_common_pkg.get_seq_no( 
                                  cv_req_no_cls     -- 採番番号区分
                                , lv_mov_num        -- 採番したNo
                                , lv_errbuf         -- エラー・メッセージ
                                , lv_retcode        -- リターン・コード
                                , lv_errmsg         -- ユーザー・エラー・メッセージ
                                );
    IF (lv_retcode = cv_status_error) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                            , cv_msg_get_seq
                                            , cv_tkn_seq_name
                                            , cv_tkn_mov_num
                                            );
--
      lv_errbuf := lv_errmsg;
--
      -- 共通エラーメッセージ終了ステータス
      gv_nodata_error := cv_nodata;
--
      RAISE global_api_expt;
--
    END IF;
--
    ---------------------------
    -- 移動指示ヘッダを設定
    ---------------------------
--
    -- 登録用変数に格納
    g_mov_hdr_id_tab(gn_mov_instr_hdr_cnt)              := gn_header_id;                                          -- 移動ヘッダID
    g_mov_num_tab(gn_mov_instr_hdr_cnt)                 := lv_mov_num;                                            -- 移動番号
    g_mov_type_tab(gn_mov_instr_hdr_cnt)                := g_mov_instr_tab(in_object_cnt).mov_type;               -- 移動タイプ
    g_instruction_post_code_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).instr_post_code;        -- 指示部署
    g_shipped_locat_code_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).shipped_locat_code;     -- 出庫元保管場所
    g_ship_to_locat_code_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).ship_to_locat_code;     -- 入庫先保管場所
    g_schedule_ship_date_tab(gn_mov_instr_hdr_cnt)      := g_mov_instr_tab(in_object_cnt).schedule_ship_date;     -- 出庫予定日
    g_schedule_arrival_date_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).schedule_arrival_date;  -- 入庫予定日
    g_freight_charge_class_tab(gn_mov_instr_hdr_cnt)    := g_mov_instr_tab(in_object_cnt).freight_charge_class;   -- 運賃区分
    g_freight_carrier_code_tab(gn_mov_instr_hdr_cnt)    := gv_carrier_code;                                       -- 運送業者
    g_weight_capacity_class_tab(gn_mov_instr_hdr_cnt)   := g_mov_instr_tab(in_object_cnt).weight_capacity_class;  -- 重量容積区分
    g_item_class_tab(gn_mov_instr_hdr_cnt)              := gv_secur_prod_class;                                   -- 商品区分
    g_product_flg_tab(gn_mov_instr_hdr_cnt)             := g_mov_instr_tab(in_object_cnt).product_flg;            -- 製品識別区分
    g_shipped_locat_id_tab(gn_mov_instr_hdr_cnt)        := gv_shipped_id;                                         -- 出庫元ID
    g_ship_to_locat_id_tab(gn_mov_instr_hdr_cnt)        := gv_ship_to_id;                                         -- 入庫先ID
    g_loading_weight_tab(gn_mov_instr_hdr_cnt)          := gn_we_loading;                                         -- 積載率(重量)
    g_loading_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_ca_loading;                                         -- 積載率(容積)
    g_career_id_tab(gn_mov_instr_hdr_cnt)               := gn_carrier_id;                                         -- 運送業者ID
    g_shipping_method_code_tab(gn_mov_instr_hdr_cnt)    := gv_max_ship_method;                                    -- 最大配送区分
    g_sum_qty_tab(gn_mov_instr_hdr_cnt)                 := gn_ttl_instruct_qty;                                   -- 合計数量
    g_small_qty_tab(gn_mov_instr_hdr_cnt)               := gn_ttl_sml_amnt_num;                                   -- 小口個数
    g_label_qty_tab(gn_mov_instr_hdr_cnt)               := gn_ttl_label_num;                                      -- ラベル枚数
--
    IF (gv_secur_prod_class = cv_drink) THEN
      g_based_weight_tab(gn_mov_instr_hdr_cnt)          := gn_drink_deadweight;         -- ドリンク基本重量
      g_based_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_drink_loading_capa;       -- ドリンク基本容積
    ELSE
      g_based_weight_tab(gn_mov_instr_hdr_cnt)          := gn_leaf_deadweight;          -- リーフ基本重量
      g_based_capacity_tab(gn_mov_instr_hdr_cnt)        := gn_leaf_loading_capa;        -- リーフ基本容積
    END IF;
--
    g_sum_weight_tab(gn_mov_instr_hdr_cnt)              := gn_sum_ttl_weight;           -- 積載重量合計
    g_sum_capacity_tab(gn_mov_instr_hdr_cnt)            := gn_sum_ttl_capacity;         -- 積載容積合計
    g_sum_pallet_weight_tab(gn_mov_instr_hdr_cnt)       := gn_sum_ttl_palette_weight;   -- 合計パレット重量
    g_sum_pallet_qty(gn_mov_instr_hdr_cnt)              := gn_sum_palette_num;          -- パレット合計枚数
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END set_header_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_req_instr_header
   * Description      : 移動指示ヘッダ情報登録(B-22)
   ***********************************************************************************/
  PROCEDURE ins_mov_req_instr_header(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_req_instr_header'; -- プログラム名
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
    cv_status_adjusting   CONSTANT VARCHAR2(2)  :=  '03';   -- ステータス：調整中
    cv_status_un_notif    CONSTANT VARCHAR2(2)  :=  '10';   -- 通知ステータス：未通知
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --移動依頼・指示ヘッダ(アドオン)登録処理
    FORALL rec_cnt IN 1..g_mov_hdr_id_tab.COUNT
      INSERT INTO xxinv_mov_req_instr_headers(
          mov_hdr_id	                              -- 移動ヘッダID
        , mov_num	                                  -- 移動番号
        , mov_type	                                -- 移動タイプ
        , entered_date	                            -- 入力日
        , instruction_post_code                     -- 指示部署
        , status	                                  -- ステータス
        , notif_status	                            -- 通知ステータス
        , shipped_locat_id	                        -- 出庫元ID
        , shipped_locat_code	                      -- 出庫元保管場所
        , ship_to_locat_id	                        -- 入庫先ID
        , ship_to_locat_code	                      -- 入庫先保管場所
        , schedule_ship_date	                      -- 出庫予定日
        , schedule_arrival_date	                    -- 入庫予定日
        , freight_charge_class	                    -- 運賃区分
        , collected_pallet_qty	                    -- パレット回収枚数
        , no_cont_freight_class	                    -- 契約外運賃区分
        , description	                              -- 摘要
        , loading_efficiency_weight	                -- 積載率（重量）
        , loading_efficiency_capacity	              -- 積載率（容積）
        , organization_id	                          -- 組織ID
        , career_id	                                -- 運送業者_ID
        , freight_carrier_code	                    -- 運送業者
        , shipping_method_code	                    -- 配送区分
        , sum_quantity	                            -- 合計数量
        , small_quantity	                          -- 小口個数
        , label_quantity	                          -- ラベル枚数
        , based_weight	                            -- 基本重量
        , based_capacity	                          -- 基本容積
        , sum_weight	                              -- 積載重量合計
        , sum_capacity	                            -- 積載容積合計
        , sum_pallet_weight	                        -- 合計パレット重量
        , pallet_sum_quantity	                      -- パレット合計枚数
        , weight_capacity_class	                    -- 重量容積区分
        , item_class	                              -- 商品区分
        , product_flg	                              -- 製品識別区分
        , comp_actual_flg                           -- 実績計上済フラグ
        , correct_actual_flg                        -- 実績訂正フラグ
        , new_modify_flg                            -- 新規修正フラグ
        , created_by                                -- 作成者
        , creation_date                             -- 作成日
        , last_updated_by                           -- 最終更新者
        , last_update_date                          -- 最終更新日
        , last_update_login                         -- 最終更新ログイン
        , request_id                                -- 要求ID
        , program_application_id                    -- コンカレント・アプリケーションID
        , program_id                                -- コンカレント・プログラムID
        , program_update_date                       -- プログラム更新日
      ) VALUES (
          g_mov_hdr_id_tab(rec_cnt)                 -- 移動ヘッダID
        , g_mov_num_tab(rec_cnt)                    -- 移動番号
        , g_mov_type_tab(rec_cnt)                   -- 移動タイプ
        , gd_sysdate                                -- 入力日
        , g_instruction_post_code_tab(rec_cnt)      -- 指示部署
        , cv_status_adjusting                       -- ステータス
        , cv_status_un_notif                        -- 通知ステータス
        , g_shipped_locat_id_tab(rec_cnt)           -- 出庫元ID
        , g_shipped_locat_code_tab(rec_cnt)         -- 出庫元保管場所
        , g_ship_to_locat_id_tab(rec_cnt)           -- 入庫先ID
        , g_ship_to_locat_code_tab(rec_cnt)         -- 入庫先保管場所
        , g_schedule_ship_date_tab(rec_cnt)         -- 出庫予定日
        , g_schedule_arrival_date_tab(rec_cnt)      -- 入庫予定日
        , g_freight_charge_class_tab(rec_cnt)       -- 運賃区分
        , NULL                                      -- パレット回収枚数
        , cv_not_object                             -- 契約外運賃区分
        , NULL                                      -- 摘要
        , g_loading_weight_tab(rec_cnt)             -- 積載率（重量）
        , g_loading_capacity_tab(rec_cnt)           -- 積載率（容積）
        , gv_master_org_id                          -- 組織ID
        , g_career_id_tab(rec_cnt)                  -- 運送業者_ID
        , g_freight_carrier_code_tab(rec_cnt)       -- 運送業者
        , g_shipping_method_code_tab(rec_cnt)       -- 配送区分
        , g_sum_qty_tab(rec_cnt)                    -- 合計数量
        , g_small_qty_tab(rec_cnt)                  -- 小口個数
        , g_label_qty_tab(rec_cnt)                  -- ラベル枚数
        , g_based_weight_tab(rec_cnt)               -- 基本重量
        , g_based_capacity_tab(rec_cnt)             -- 基本容積
        , g_sum_weight_tab(rec_cnt)                 -- 積載重量合計
        , g_sum_capacity_tab(rec_cnt)               -- 積載容積合計
        , g_sum_pallet_weight_tab(rec_cnt)          -- 合計パレット重量
        , g_sum_pallet_qty(rec_cnt)                 -- パレット合計枚数
        , g_weight_capacity_class_tab(rec_cnt)      -- 重量容積区分
        , g_item_class_tab(rec_cnt)                 -- 商品区分
        , g_product_flg_tab(rec_cnt)                -- 製品識別区分
        , cv_off                                    -- 実績計上済フラグ
        , cv_off                                    -- 実績訂正フラグ
        , cv_off                                    -- 新規修正フラグ
        , gn_user_id                                -- 作成者
        , gd_sysdate                                -- 作成日
        , gn_user_id                                -- 最終更新者
        , gd_sysdate                                -- 最終更新日
        , gn_login_id                               -- 最終更新ログイン
        , gn_conc_request_id                        -- 要求ID
        , gn_prog_appl_id                           -- コンカレント・アプリケーションID
        , gn_conc_program_id                        -- コンカレント・プログラムID
        , gd_sysdate                                -- プログラム更新日
      );
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END ins_mov_req_instr_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_req_instr_line
   * Description      : 移動指示明細情報登録(B-23)
   ***********************************************************************************/
  PROCEDURE ins_mov_req_instr_line(
      ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
    , ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
    , ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_req_instr_line'; -- プログラム名
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
    cv_no     CONSTANT VARCHAR2(1)  :=  'N';    -- 取消フラグ：N
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --移動依頼・指示明細(アドオン)登録処理
    FORALL rec_cnt IN 1..g_mov_line_id_tab.COUNT
      INSERT INTO xxinv_mov_req_instr_lines(
          mov_line_id	                              -- 移動明細ID
        , mov_hdr_id	                              -- 移動ヘッダID
        , line_number	                              -- 明細番号
        , organization_id	                          -- 組織ID
        , item_id	                                  -- OPM品目ID
        , item_code	                                -- 品目
        , pallet_quantity	                          -- パレット数
        , layer_quantity	                          -- 段数
        , case_quantity	                            -- ケース数
        , instruct_qty	                            -- 指示数量
        , uom_code	                                -- 単位
        , designated_production_date	              -- 指定製造日
        , pallet_qty	                              -- パレット枚数
        , first_instruct_qty	                      -- 初回指示数量
        , weight	                                  -- 重量
        , capacity	                                -- 容積
        , pallet_weight	                            -- パレット重量
        , delete_flg	                              -- 取消フラグ
        , created_by                                -- 作成者
        , creation_date                             -- 作成日
        , last_updated_by                           -- 最終更新者
        , last_update_date                          -- 最終更新日
        , last_update_login                         -- 最終更新ログイン
        , request_id                                -- 要求ID
        , program_application_id                    -- コンカレント・アプリケーションID
        , program_id                                -- コンカレント・プログラムID
        , program_update_date                       -- プログラム更新日
      ) VALUES (
          g_mov_line_id_tab(rec_cnt)                -- 移動明細ID
        , g_mov_line_hdr_id_tab(rec_cnt)            -- 移動ヘッダID
        , g_mov_number_tab(rec_cnt)                 -- 明細番号
        , gv_master_org_id                          -- 組織ID
        , g_item_id_tab(rec_cnt)                    -- OPM品目ID
        , g_item_code_tab(rec_cnt)                  -- 品目
        , g_pallet_qty_tab(rec_cnt)                 -- パレット数
        , g_layer_qty_tab(rec_cnt)                  -- 段数
        , g_case_qty_tab(rec_cnt)                   -- ケース数
        , g_instr_qty_tab(rec_cnt)                  -- 指示数量
        , g_uom_code_tab(rec_cnt)                   -- 単位
        , g_designated_prod_date_tab(rec_cnt)       -- 指定製造日
        , g_pallet_num_of_sheet_tab(rec_cnt)        -- パレット枚数
        , g_first_instruct_qty_tab(rec_cnt)         -- 初回指示数量
        , g_weight_tab(rec_cnt)                     -- 重量
        , g_capacity_tab(rec_cnt)                   -- 容積
        , g_pallet_weight_tab(rec_cnt)              -- パレット重量
        , cv_no                                     -- 取消フラグ
        , gn_user_id                                -- 作成者
        , gd_sysdate                                -- 作成日
        , gn_user_id                                -- 最終更新者
        , gd_sysdate                                -- 最終更新日
        , gn_login_id                               -- 最終更新ログイン
        , gn_conc_request_id                        -- 要求ID
        , gn_prog_appl_id                           -- コンカレント・アプリケーションID
        , gn_conc_program_id                        -- コンカレント・プログラムID
        , gd_sysdate                                -- プログラム更新日
      );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END ins_mov_req_instr_line;
--
  /**********************************************************************************
   * Procedure Name   : purge_processing
   * Description      : パージ処理(B-24)
   ***********************************************************************************/
  PROCEDURE purge_processing(
      in_shipped_locat_cd     IN  VARCHAR2  -- 出庫元コード
    , ov_errbuf               OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode              OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg               OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_processing'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    ----------------------------------
    -- 移動指示明細インタフェース削除
    ----------------------------------
    BEGIN
      DELETE FROM xxinv_mov_instr_lines_if xmili
      WHERE xmili.mov_hdr_if_id IN ( 
              SELECT xmihi.mov_hdr_if_id
              FROM   xxinv_mov_instr_headers_if xmihi
              WHERE  xmihi.instruction_post_code = gv_user_dept_id    -- 移動指示部署コード
              AND   ((in_shipped_locat_cd IS NULL)                    -- 出庫元保管場所
                     OR (shipped_locat_code = in_shipped_locat_cd))
            )
      ;
    EXCEPTION
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
    END;
--
    ----------------------------------
    -- 移動指示ヘッダインタフェース削除
    ----------------------------------
    BEGIN
      DELETE FROM xxinv_mov_instr_headers_if xmihi
      WHERE  xmihi.instruction_post_code = gv_user_dept_id    -- 移動指示部署コード
      AND   ((in_shipped_locat_cd IS NULL)                    -- 出庫元保管場所
          OR (shipped_locat_code = in_shipped_locat_cd))
      ;
--
    EXCEPTION
--
      WHEN OTHERS THEN
--
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
--
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
  END purge_processing;
--
  /**********************************************************************************
   * Procedure Name   : put_err_list
   * Description      : エラーリスト出力
   ***********************************************************************************/
  PROCEDURE put_err_list(
      in_shipped_locat_cd   IN  VARCHAR2  -- 出庫元コード
    , ov_errbuf             OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT VARCHAR2  -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_err_list'; -- プログラム名
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
    lv_err_list VARCHAR2(10000);
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -------------------------------------
    -- 出力項目                        --
    -------------------------------------
    -- ログインユーザの所属部署コード
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_user_org_id
                                          , cv_tkn_value
                                          , gv_user_dept_id
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- 入力パラメータ「出庫倉庫」
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_shipped_loc
                                          , cv_tkn_value
                                          , in_shipped_locat_cd
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- エラーが有る場合はエラー出力
    IF (g_err_list_tab.COUNT > 0) THEN
--
          --区切り文字列出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
      -- エラーリストヘッダ出力
      gv_err_report :=             cv_kind                      -- 種別
                      || cv_tab || cv_hdr_mov_if_id             -- 移動ヘッダIF_ID
                      || cv_tab || cv_hdr_temp_ship_num         -- 仮伝票番号
                      || cv_tab || cv_hdr_mov_type              -- 移動タイプ
                      || cv_tab || cv_hdr_instr_post_code       -- 指示部署
                      || cv_tab || cv_hdr_shipped_code          -- 出庫元保管場所
                      || cv_tab || cv_hdr_ship_to_code          -- 入庫先保管場所
                      || cv_tab || cv_hdr_sch_ship_date         -- 出庫予定日
                      || cv_tab || cv_hdr_sch_arrival_date      -- 入庫予定日
                      || cv_tab || cv_hdr_freight_charge_cls    -- 運賃区分
                      || cv_tab || cv_hdr_freight_carrier_cd    -- 運送業者
                      || cv_tab || cv_hdr_weight_capacity_cls   -- 重量容積区分
                      || cv_tab || cv_hdr_product_flg           -- 製品識別区分
                      || cv_tab || cv_hdr_mov_line_if_id        -- 移動明細IF_ID
                      || cv_tab || cv_hdr_item_code             -- 品目
                      || cv_tab || cv_hdr_desined_prod_date     -- 定製造日
                      || cv_tab || cv_hdr_first_instruct_qty    -- 初回指示数量
                      || cv_tab || cv_hdr_err_msg               -- エラーメッセージ
      ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- 項目区切り線出力
      gv_err_report := cv_line || cv_line || cv_line || cv_line || cv_line || cv_line;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_err_report);
--
      -- エラーリスト内容出力
      <<err_list_loop>>
      FOR i IN 1..g_err_list_tab.COUNT LOOP
        -- ダミーエラーメッセージは出力しない
        IF (g_err_list_tab(i).err_msg IS NOT NULL) THEN
--
          FND_FILE.PUT_LINE(  FND_FILE.OUTPUT
                            , g_err_list_tab(i).err_msg
                            );
        END IF;
--
      END LOOP err_list_loop;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** <例外コメント> ***
      -- *** 任意で例外処理を記述する ****
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
  END put_err_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      in_shipped_locat_cd   IN  VARCHAR2 DEFAULT NULL -- 出庫元コード（任意）
    , ov_errbuf             OUT VARCHAR2              -- エラー・メッセージ           --# 固定 #
    , ov_retcode            OUT VARCHAR2              -- リターン・コード             --# 固定 #
    , ov_errmsg             OUT VARCHAR2              -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'submain'; -- プログラム名
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
    lv_pre_tmp_ship_num     xxinv_mov_instr_headers_if.temp_ship_num%TYPE;  -- 前回処理：仮伝票番号
    lv_pre_item_code        xxinv_mov_instr_lines_if.item_code%TYPE;        -- 前回処理：品目コード
    lv_pre_prod_cls         VARCHAR2(1);                                    -- 前回処理：商品区分
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    ln_object_cnt           NUMBER;     -- 登録対象カウンタ
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
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    gv_nodata_error           := 0;           -- 対象データ取得エラー
    gv_err_status             := cv_normal;   -- 共通エラーメッセージ 終了ST
    gn_cnt                    := 0;           -- 処理用カウンタ
    gn_err_set_cnt            := 0;           -- エラーリスト用カウンタ
    gn_mov_instr_hdr_cnt      := 0;           -- ヘッダ件数
    gn_mov_instr_line_cnt     := 0;           -- ライン件数
    gn_header_id              := 0;           -- 移動指示ヘッダID
    gn_line_id                := 0;           -- 移動指示明細ID
    gn_line_number_cnt        := 0;           -- ヘッダ単位明細件数
--
    gv_max_ship_method        := NULL;        -- 最大配送区分
    gn_drink_deadweight       := 0;           -- ドリンク基本重量
    gn_leaf_deadweight        := 0;           -- リーフ基本重量
    gn_drink_loading_capa     := 0;           -- ドリンク基本容積
    gn_leaf_loading_capa      := 0;           -- リーフ基本容積
    gn_palette_max_qty        := 0;           -- パレット最大枚数
    gn_carrier_id             := NULL;        -- 運送業者ID
    gn_item_id                := 0;           -- 品目ID
    gv_item_um                := 0;           -- 単位
    gv_conv_unit              := 0;           -- 入出庫換算単位
    gn_delivery_qty           := 0;           -- 配数
    gn_max_palette_steps      := 0;           -- パレット当り最大段数
    gn_num_of_cases           := 0;           -- ケース入数
    gn_num_of_deliver         := 0;           -- 出荷入数
    gn_max_case_for_palette   := 0;           -- パレット当りの最大ケース数
    gn_best_num_palette       := 0;           -- 最適数量：パレット数
    gn_best_num_steps         := 0;           -- 最適数量：段数
    gn_best_num_cases         := 0;           -- 最適数量：ケース数
    gn_palette_num            := 0;           -- パレット枚数
    gn_sum_palette_num        := 0;           -- パレット合計枚数
    gn_instruct_qty           := 0;           -- 指示数量
    gn_ttl_instruct_qty       := 0;           -- 指示数量合計
    gn_ttl_weight             := 0;           -- 合計重量
    gn_ttl_capacity           := 0;           -- 合計容積
    gn_ttl_palette_weight     := 0;           -- 合計パレット重量
    gn_sum_ttl_palette_weight := 0;           -- 総合計パレット重量
    gn_sum_ttl_weight         := 0;           -- 総合計重量
    gn_sum_ttl_capacity       := 0;           -- 総合計容積
    gn_sml_amnt_num           := 0;           -- 小口個数
    gn_ttl_sml_amnt_num       := 0;           -- 小口個数合計
    gn_label_num              := 0;           -- ラベル枚数
    gn_ttl_label_num          := 0;           -- ラベル枚数合計
    ln_object_cnt             := 0;           -- 登録対象カウンタ
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    --  B-1.初期処理
    -- ===============================
    init(
        lv_errbuf     -- エラー・メッセージ           --# 固定 #
      , lv_retcode    -- リターン・コード             --# 固定 #
      , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    --  B-2.移動指示IF情報取得
    -- ===============================
    get_interface_data(
        in_shipped_locat_cd -- 出庫元コード
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data_if_expt;
    END IF;
--
    <<header_data_loop>>
    FOR i IN 1..g_mov_instr_tab.LAST LOOP
--
      -- 品目マスタチェックステータス初期化
      gv_item_mst_chk_sts := cv_status_normal;
--
      -- LOOPカウントインクリメント
      gn_cnt := gn_cnt + 1;
--
      -- 最初のレコードまたは仮伝票番号がブレイクした場合、ヘッダ項目のチェックを行う
      IF ((lv_pre_tmp_ship_num IS NULL)
        OR  (lv_pre_tmp_ship_num <> g_mov_instr_tab(gn_cnt).temp_ship_num))
      THEN
--
        -- ヘッダ単位明細件数初期化
        gn_line_number_cnt := 0;
--
        -- 前回処理分のチェック及びヘッダ登録を行う
        IF (lv_pre_tmp_ship_num IS NOT NULL) THEN
--
          -- 前回処理のカウンタをセット
          ln_object_cnt := gn_cnt - 1;
--
          -- 運賃区分設定あり且つ最大配送区分がある場合のみ
          IF (g_mov_instr_tab(ln_object_cnt).freight_charge_class = cv_object) 
            AND (gv_max_ship_method IS NOT NULL)
          THEN
--
            -- ================================
            --  積載効率オーバーチェック(B-16)
            -- ================================
            chk_loading_effic(
                in_object_cnt   => ln_object_cnt  -- 対象データカウンタ
              , ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
              , ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
              , ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- 商品区分：ドリンク、製品識別区分：製品の場合のみ
          IF ((gv_prod_cls = cv_drink)                                      -- 商品区分：ドリンク
            AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- 製品識別区分：製品
          THEN
--
            -- ================================
            --  パレット合計枚数チェック(B-17)
            -- ================================
            chk_sum_palette_sheets(
                in_object_cnt  => ln_object_cnt -- 対象データカウンタ
              , ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
              , ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
              , ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- エラーが無い場合、前回処理分の登録を行う
          IF (gv_err_status <> cv_status_error) THEN
--
            -- =============================
            -- 移動指示ヘッダ情報設定(B-20)
            -- =============================
            set_header_data(
                in_object_cnt => ln_object_cnt  -- 登録対象カウンタ
              , ov_errbuf     => lv_errbuf      -- エラー・メッセージ           --# 固定 #
              , ov_retcode    => lv_retcode     -- リターン・コード             --# 固定 #
              , ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
          -- ヘッダ情報用の変数初期化を行う
          gn_we_loading             :=  0;    -- 積載率(重量)
          gn_ca_loading             :=  0;    -- 積載率(容積)
          gn_ttl_weight             :=  0;    -- 合計重量
          gn_ttl_sml_amnt_num       :=  0;    -- 小口個数
          gn_ttl_label_num          :=  0;    -- ラベル枚数
          gn_drink_deadweight       :=  0;    -- ドリンク基本重量
          gn_drink_loading_capa     :=  0;    -- ドリンク基本容積
          gn_leaf_deadweight        :=  0;    -- リーフ基本重量
          gn_leaf_loading_capa      :=  0;    -- リーフ基本容積
          gn_sum_ttl_weight         :=  0;    -- 積載重量合計
          gn_sum_ttl_capacity       :=  0;    -- 積載容積合計
          gn_sum_ttl_palette_weight :=  0;    -- 総合計パレット重量
          gn_ttl_palette_weight     :=  0;    -- 合計パレット重量
          gn_sum_palette_num        :=  0;    -- パレット合計枚数
          gn_ttl_instruct_qty       :=  0;    -- 指示数量合計
          gv_carrier_code           :=  NULL; -- 運送業者
          gn_carrier_id             :=  NULL; -- 運送業者ID
          gv_max_ship_method        :=  NULL; -- 最大配送区分
          lv_pre_item_code          :=  NULL; -- 品目コード
--
        END IF;
--
        -- 積載効率チェック用にヘッダ項目を確保
        gv_shipped_locat_code :=  g_mov_instr_tab(gn_cnt).shipped_locat_code; -- 出庫元コード
        gv_ship_to_locat_code :=  g_mov_instr_tab(gn_cnt).ship_to_locat_code; -- 入庫先コード
        gd_schedule_ship_date :=  g_mov_instr_tab(gn_cnt).schedule_ship_date; -- 出庫日
--
        -- ==================================
        --  B-3.移動指示ヘッダIF情報チェック
        -- ==================================
        chk_if_header_data(
            lv_errbuf     -- エラー・メッセージ           --# 固定 #
          , lv_retcode    -- リターン・コード             --# 固定 #
          , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 運賃区分：有りの場合のみ
        IF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_on) THEN
--
          -- =====================================
          --  最大配送区分・小口区分取得(B-4,B-5)
          -- =====================================
          get_max_ship_method(
              lv_errbuf     -- エラー・メッセージ           --# 固定 #
            , lv_retcode    -- リターン・コード             --# 固定 #
            , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ==================================
        --  稼働日チェック(B-19)
        -- ==================================
        chk_operating_day(
            lv_errbuf     -- エラー・メッセージ           --# 固定 #
          , lv_retcode    -- リターン・コード             --# 固定 #
          , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================
        -- 関連データ取得処理(B-6, B-7)
        -- =============================
        get_relating_data(
              lv_errbuf     -- エラー・メッセージ           --# 固定 #
            , lv_retcode    -- リターン・コード             --# 固定 #
            , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        ------------------------------
        -- 移動指示ヘッダＩＤ取得
        ------------------------------
        BEGIN
          SELECT xxinv_mov_hdr_s1.NEXTVAL
          INTO   gn_header_id
          FROM   dual
          ;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- ヘッダ件数カウント
        gn_mov_instr_hdr_cnt  := gn_mov_instr_hdr_cnt + 1;
--
      END IF; -- ヘッダ項目チェック終了
--
      -- ============================================
      -- B-8.移動指示明細インタフェース情報チェック
      -- ============================================
      -- 明細件数カウンタ インクリメント
      gn_mov_instr_line_cnt := gn_mov_instr_line_cnt + 1;
--
      -- ヘッダ単位明細件数 インクリメント
      gn_line_number_cnt := gn_line_number_cnt + 1;
--
      -- 指示総数チェック
      IF (g_mov_instr_tab(gn_cnt).first_instruct_qty = 0) THEN
--
        gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                              , cv_err_msg_15
                                              );
--
        make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                      , iv_err_info => gv_out_msg       -- エラーメッセージ
                      , in_rec_cnt  => gn_cnt
                      , ov_errbuf   => lv_errbuf        
                      , ov_retcode  => lv_retcode       
                      , ov_errmsg   => lv_errmsg        
                     ); --
--
        -- 共通エラーメッセージ終了ステータス
        gv_err_status := cv_status_error;
--
      END IF;
--
      -- ===========================
      -- B-9.品目情報取得
      -- ===========================
      get_item_info(
          lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , lv_retcode    -- リターン・コード             --# 固定 #
        , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF (gb_get_item_flg) THEN
--
        ---------------------------------
        -- ドリンク・リーフ混載チェック
        ---------------------------------
        IF (gv_secur_prod_class <> gv_prod_cls) THEN
--
          IF (gv_secur_prod_class = cv_drink) THEN
--
            gv_msg_prod_cls := cv_prod_cls_drink; -- ドリンク
--
          ELSE
--
            gv_msg_prod_cls := cv_prod_cls_leaf;  -- リーフ
--
          END IF;
--
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_err_msg_14
                                                , cv_tkn_item
                                                , gv_msg_prod_cls
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                        , iv_err_info => gv_out_msg       -- エラーメッセージ
                        , in_rec_cnt  => gn_cnt
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); --
--
          -- 共通エラーメッセージ終了ステータス
          gv_err_status := cv_status_error;
--
        END IF;
--
        ---------------------
        -- 品目重複チェック
        ---------------------
        IF (lv_pre_item_code = g_mov_instr_tab(gn_cnt).item_code) THEN
--
          gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                                , cv_err_msg_13
                                                );
--
          make_err_list(  iv_kind     => cv_msg_err       -- エラー種別
                        , iv_err_info => gv_out_msg       -- エラーメッセージ
                        , in_rec_cnt  => gn_cnt
                        , ov_errbuf   => lv_errbuf        
                        , ov_retcode  => lv_retcode       
                        , ov_errmsg   => lv_errmsg        
                       ); --
--
          -- 共通エラーメッセージ終了ステータス
          gv_err_status := cv_status_error;
--
        END IF;
--
        -- 商品区分：ドリンク、製品識別区分：製品の場合のみ
        IF ((gv_prod_cls = cv_drink)                                      -- 商品区分：ドリンク
          AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- 製品識別区分：製品
        THEN
          -- ===========================
          -- B-10.品目マスタチェック
          -- ===========================
          chk_item_mst(
              lv_errbuf     -- エラー・メッセージ           --# 固定 #
            , lv_retcode    -- リターン・コード             --# 固定 #
            , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- 品目マスタチェックが正常の場合
          IF (gv_item_mst_chk_sts = cv_status_normal) THEN
--
            -- ===========================
            -- 最適数量の算出(B-11,B-12)
            -- ===========================
            calc_best_amount(
                lv_errbuf     -- エラー・メッセージ           --# 固定 #
              , lv_retcode    -- リターン・コード             --# 固定 #
              , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
--
        END IF;
--
        -- =================================
        --  指示数量の算出(B-13,B-14,B-15)
        -- =================================
        calc_instruct_amount(
            lv_errbuf     -- エラー・メッセージ           --# 固定 #
          , lv_retcode    -- リターン・コード             --# 固定 #
          , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- エラーがない場合のみ
      IF (gv_err_status <> cv_status_error) THEN
--
        -- ===========================
        -- 移動指示明細情報設定
        -- ===========================
        set_line_data(
            lv_errbuf     -- エラー・メッセージ           --# 固定 #
          , lv_retcode    -- リターン・コード             --# 固定 #
          , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
--
          RAISE global_process_expt;
--
        END IF;
--
      END IF;
--
      -- 明細用の変数初期化
      gn_best_num_palette   := 0;   -- 品目ID
      gn_item_id            := 0;   -- パレット数
      gn_best_num_steps     := 0;   -- 段数
      gn_best_num_cases     := 0;   -- ケース数
      gn_instruct_qty       := 0;   -- 指示数量
      gv_conv_unit          := 0;   -- 単位
      gn_palette_num        := 0;   -- パレット枚数
      gn_ttl_weight         := 0;   -- 重量
      gn_ttl_capacity       := 0;   -- 容積
      gn_ttl_palette_weight := 0;   -- パレット重量
--
      -- 処理済みの仮伝票番号をセット
      lv_pre_tmp_ship_num := g_mov_instr_tab(gn_cnt).temp_ship_num;
      -- 処理済みの品目コードをセット
      lv_pre_item_code    := g_mov_instr_tab(gn_cnt).item_code;
      -- 処理済みの商品区分をセット
      lv_pre_prod_cls     := gv_prod_cls;
--
    END LOOP header_data_loop;
--
    --最後に処理したヘッダデータを登録用テーブルに格納する。
    -- 運賃区X分設定ありの場合のみ
    IF (g_mov_instr_tab(gn_cnt).freight_charge_class = cv_object) 
      AND (gv_max_ship_method IS NOT NULL)
    THEN
      -- ================================
      --  積載効率オーバーチェック(B-16)
      -- ================================
      chk_loading_effic(
          in_object_cnt   => gn_cnt     -- 対象データカウンタ
        , ov_errbuf       => lv_errbuf  -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- 商品区分：ドリンク、製品識別区分：製品の場合のみ
    IF ((gv_prod_cls = cv_drink)                                      -- 商品区分：ドリンク
      AND (g_mov_instr_tab(gn_cnt).product_flg = cv_prod_cls_prod))   -- 製品識別区分：製品
    THEN
--
      -- ================================
      --  パレット合計枚数チェック(B-17)
      -- ================================
      chk_sum_palette_sheets(
          in_object_cnt => gn_cnt   -- 対象データカウンタ
          , ov_errbuf       => lv_errbuf      -- エラー・メッセージ           --# 固定 #
          , ov_retcode      => lv_retcode     -- リターン・コード             --# 固定 #
          , ov_errmsg       => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- エラーが無い場合、前回処理分の登録を行う
    IF (gv_err_status <> cv_status_error) THEN
--
      ln_object_cnt := gn_cnt;
--
      -- =============================
      -- 移動指示ヘッダ情報設定(B-20)
      -- =============================
      set_header_data(
          in_object_cnt   => gn_cnt     -- 対象データカウンタ
        , ov_errbuf       => lv_errbuf  -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
       );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =================================
      --  移動指示ヘッダ登録処理(B-22)
      -- =================================
      ins_mov_req_instr_header(
          lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , lv_retcode    -- リターン・コード             --# 固定 #
        , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =================================
      --  移動指示明細登録処理(B-23)
      -- =================================
      ins_mov_req_instr_line(
          lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , lv_retcode    -- リターン・コード             --# 固定 #
        , lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ステータス設定
    IF (gv_err_status = cv_status_error)    -- エラー
      OR (gv_err_status = cv_status_warn)   -- 警告
    THEN
--
      ov_retcode := gv_err_status;
--
    END IF;
--
    -- ステータスがエラーの場合はロールバックする
    IF (ov_retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
    -- ==============================
    --  パージ処理(B-24)
    -- ==============================
    purge_processing(
        in_shipped_locat_cd   -- 出庫元コード
      , lv_errbuf             -- エラー・メッセージ           --# 固定 #
      , lv_retcode            -- リターン・コード             --# 固定 #
      , lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    ---------------------
    -- エラーリスト出力
    ---------------------
    put_err_list(
       in_shipped_locat_cd  -- 出庫元コード
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN no_data_if_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
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
      errbuf              OUT VARCHAR2              -- エラー・メッセージ  --# 固定 #
    , retcode             OUT VARCHAR2              -- リターン・コード    --# 固定 #
    , in_shipped_locat_cd IN  VARCHAR2 DEFAULT NULL -- 出庫元コード
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
    cv_prg_name           CONSTANT  VARCHAR2(100) :=  'main';             -- プログラム名
    cv_userenv            CONSTANT  VARCHAR2(4)   :=  userenv('LANG');    -- USERENV
    cv_appl_id            CONSTANT  NUMBER        :=  0;                  -- アプリケーションID
    cv_status_code        CONSTANT  VARCHAR2(14)  :=  'CP_STATUS_CODE';   -- ステータスコード
--
    cv_msg_user_name      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00001';  -- ユーザ名
    cv_msg_conc_name      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00002';  -- コンカレント名
    cv_msg_start_time     CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10118';  -- 起動時間
    cv_msg_separater      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00003';  -- セパレータ
    cv_msg_standard       CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-10030';  -- コンカレント定型メッセージ
    cv_msg_process_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00008';  -- 処理件数
    cv_msg_success_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00009';  -- 成功件数
    cv_msg_error_cnt      CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00010';  -- エラー件数
    cv_msg_skip_cnt       CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00011';  -- スキップ件数
    cv_msg_proc_status    CONSTANT  VARCHAR2(15)  :=  'APP-XXCMN-00012';  -- 処理ステータス
    cv_msg_header_cnt     CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10195';  -- 移動指示ヘッダ件数
    cv_msg_line_cnt       CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10196';  -- 移動指示明細件数
    cv_msg_header_if_cnt  CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10197';  -- 移動指示ヘッダIF件数
    cv_msg_line_if_cnt    CONSTANT  VARCHAR2(15)  :=  'APP-XXINV-10198';  -- 移動指示明細IF件数
--
    -- トークン
    cv_tkn_user           CONSTANT  VARCHAR2(4)   :=  'USER';
    cv_tkn_conc           CONSTANT  VARCHAR2(4)   :=  'CONC';
    cv_tkn_count          CONSTANT  VARCHAR2(3)   :=  'CNT';
    cv_tkn_status         CONSTANT  VARCHAR2(6)   :=  'STATUS';
    cv_tkn_time           CONSTANT  VARCHAR2(4)   :=  'TIME';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    ln_ins_hdr_cnt     NUMBER;          -- ヘッダ登録件数
    ln_ins_line_cnt    NUMBER;          -- 明細登録件数
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
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_user_name
                                          , cv_tkn_user
                                          , gv_exec_user
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --実行コンカレント名出力
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_conc_name
                                          , cv_tkn_conc
                                          , gv_conc_name
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字出力
    gv_sep_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_separater
                                          );
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_shipped_locat_cd  -- 出庫元コード
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
--
    -- エラーリストを出力しない場合、以下の項目を出力
    IF (gv_nodata_error = cv_nodata) THEN
--
      -------------------------------------
      -- 出力項目                        --
      -------------------------------------
      -- ログインユーザの所属部署コード
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_user_org_id
                                            , cv_tkn_value
                                            , gv_user_dept_id
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
      -- 入力パラメータ「出庫倉庫」
      gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                            , cv_msg_shipped_loc
                                            , cv_tkn_value
                                            , in_shipped_locat_cd
                                            );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    END IF;
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --処理件数出力(移動指示IFヘッダ件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_header_if_cnt
                                          , cv_tkn_count
                                          , TO_CHAR(gn_mov_instr_hdr_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(移動指示IF明細件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_line_if_cnt
                                          , cv_tkn_count
                                          , TO_CHAR(gn_mov_instr_line_cnt)
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    IF (gv_err_status = cv_status_error) 
      OR (lv_retcode = cv_status_error)
    THEN
--
      ln_ins_hdr_cnt  := 0;
      ln_ins_line_cnt := 0;
--
    ELSE
--
      ln_ins_hdr_cnt  := TO_CHAR(g_mov_hdr_id_tab.COUNT);
      ln_ins_line_cnt := TO_CHAR(g_mov_line_id_tab.COUNT);
--
    END IF;
--
    --処理件数出力(移動指示ヘッダ件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_header_cnt
                                          , cv_tkn_count
                                          , ln_ins_hdr_cnt
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --処理件数出力(移動指示明細件数)
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_appl_short_name
                                          , cv_msg_line_cnt
                                          , cv_tkn_count
                                          , ln_ins_line_cnt
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --区切り文字列出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --ステータス出力
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = cv_userenv
    AND    flv.view_application_id = cv_appl_id
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = cv_status_code
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            cv_status_normal,cv_sts_cd_normal,
                                            cv_status_warn,cv_sts_cd_warn,
                                            cv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --処理ステータス出力
    gv_out_msg := xxcmn_common_pkg.get_msg( cv_msg_kbn
                                          , cv_msg_proc_status
                                          , cv_tkn_status,gv_conc_status
                                          );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --ステータスセット
    retcode := lv_retcode;

   --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
END XXINV500002C;
/
