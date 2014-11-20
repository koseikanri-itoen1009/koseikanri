CREATE OR REPLACE PACKAGE BODY xxwsh930004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930004C(body)
 * Description      : 入出庫情報差異リスト（入庫基準）
 * MD.050/070       : 生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD050_BPO_930)
 *                    生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD070_BPO_93D)
 * Version          : 1.14
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_out_data         PROCEDURE : ＸＭＬデータ出力処理
 *  prc_ins_temp_data           PROCEDURE : 中間テーブル登録
 *  prc_set_temp_data           PROCEDURE : 中間テーブル登録データ設定
 *  prc_create_move_data        PROCEDURE : 移動データ抽出処理
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/03    1.0   Oracle井澤直也   新規作成
 *  2008/06/23    1.1   Oracle大橋孝郎   不具合ログ対応
 *  2008/06/25    1.2   Oracle大橋孝郎   不具合ログ対応
 *  2008/06/30    1.3   Oracle大橋孝郎   不具合ログ対応
 *  2008/07/08    1.4   Oracle弓場哲士   禁則文字対応
 *  2008/07/09    1.5   Oracle椎名昭圭   変更要求対応#92
 *  2008/07/28    1.6   Oracle椎名昭圭   ST不具合#197、内部課題#32、内部変更要求#180対応
 *  2008/10/09    1.7   Oracle福田直樹   統合テスト障害#338対応
 *  2008/10/17    1.8   Oracle福田直樹   課題T_S_458対応(部署を任意入力パラメータに変更。PACKAGEの修正はなし)
 *  2008/10/17    1.8   Oracle福田直樹   変更要求#210対応
 *  2008/10/20    1.9   Oracle福田直樹   課題T_S_486対応
 *  2008/10/20    1.9   Oracle福田直樹   統合テスト障害#394(1)対応
 *  2008/10/20    1.9   Oracle福田直樹   統合テスト障害#394(2)対応
 *  2008/10/31    1.10  Oracle福田直樹   統合指摘#462対応
 *  2008/11/17    1.11  Oracle福田直樹   統合指摘#651対応(課題T_S_486再対応)
 *  2008/12/17    1.12  Oracle福田直樹   本番障害#764対応
 *  2008/12/25    1.13  Oracle福田直樹   本番障害#831対応
 *  2009/01/06    1.14  Oracle吉田夏樹   本番障害#929対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  check_move_data_expt         EXCEPTION;     -- 移動データ抽出処理での例外
  check_create_xml_expt        EXCEPTION;     -- ＸＭＬデータ編集での例外
--#######################  固定グローバル変数宣言部 START   #######################
--
--################################  固定部 END   ###############################
--
  -- ===============================================================================================
  -- ユーザー宣言部
  -- ===============================================================================================
  -- ==================================================
  -- グローバル定数
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxwsh930004c' ;     -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWSH930004T' ;     -- 帳票ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- データ０件メッセージ
--
  ------------------------------
  -- 参照タイプ
  ------------------------------
  -- 入出庫情報差異リスト出力区分
  gc_lookup_output_type       CONSTANT VARCHAR2(100) := 'XXWSH_930CD_LIST_OUTPUT_CLASS' ;
  -- 配送区分
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD' ;
  -- ロットステータス
  gc_lookup_lot_status        CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS' ;
--
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 品目区分
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- 製品
  -- 入出庫情報差異リスト出力区分
  gc_output_type_nrep     CONSTANT VARCHAR2(1)  := '1' ;  -- 未報告
  gc_output_type_rsrv     CONSTANT VARCHAR2(1)  := '2' ;  -- 保留
  gc_output_type_diff     CONSTANT VARCHAR2(1)  := '3' ;  -- 依頼差
  gc_output_type_ndif     CONSTANT VARCHAR2(1)  := '4' ;  -- 差異無
  gc_output_type_ndel     CONSTANT VARCHAR2(1)  := '5' ;  -- 出庫未
  gc_output_type_nstc     CONSTANT VARCHAR2(1)  := '6' ;  -- 入庫未
  gc_output_type_iodf     CONSTANT VARCHAR2(1)  := '7' ;  -- 出入差
  -- 差異事由
  gc_reason_nrep          CONSTANT VARCHAR2(10) := '未報告' ;
  gc_reason_rsrv          CONSTANT VARCHAR2(10) := '保留' ;
  gc_reason_diff          CONSTANT VARCHAR2(10) := '依頼差' ;
  gc_reason_ndif          CONSTANT VARCHAR2(10) := '差異無' ;
  gc_reason_ndel          CONSTANT VARCHAR2(10) := '出庫未' ;
  gc_reason_nstc          CONSTANT VARCHAR2(10) := '入庫未' ;
  gc_reason_iodf          CONSTANT VARCHAR2(10) := '出入差' ;
  -- 移動タイプ
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- 積送あり
  -- 移動ステータス
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- 依頼済
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- 調整中
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- 出庫報告有
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- 入庫報告有
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- 入出庫報告有
  -- EOSデータタイプ
  gc_eos_type_rpt_move_o  CONSTANT VARCHAR2(3)  := '220' ;  -- 移動出庫確定報告
  gc_eos_type_rpt_move_i  CONSTANT VARCHAR2(3)  := '230' ;  -- 移動入庫確定報告
  -- YesNo区分
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES    2008/11/17 統合指摘#651 Add
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 出荷支給区分
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- 移動（プログラム内限定）
  -- 出荷支給区分（変換）
  gc_sp_class_name_move   CONSTANT VARCHAR2(4)  := '移動' ; -- 移動（プログラム内限定）
  -- 受注カテゴリ
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- ロット管理区分
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ロット管理あり
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ロット管理なし
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- 移動
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- 指示
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- 出庫実績
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- 入庫実績
  -- 出荷依頼ＩＦ：保留ステータス
  gc_reserved_status_y    CONSTANT VARCHAR2(1) := '1' ;     -- 保留
--
  -- 2008/10/10 統合テスト障害#394(1) Add Start --------------------------
  -- 中間テーブル：指示実績区分
  gc_inst_rslt_div_h      CONSTANT VARCHAR2(1) := '0' ;     -- 保留
  gc_inst_rslt_div_i      CONSTANT VARCHAR2(1) := '1' ;     -- 指示
  gc_inst_rslt_div_r      CONSTANT VARCHAR2(1) := '2' ;     -- 実績
  -- 2008/10/10 統合テスト障害#394(1) Add Start --------------------------
--
  ------------------------------
  -- その他
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '9999/12/31' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      prod_div              VARCHAR2(1)         -- 01 : 商品区分
     ,item_div              VARCHAR2(1)         -- 02 : 品目区分
     ,date_from             DATE                -- 03 : 着日From
     ,date_to               DATE                -- 04 : 着日To
     ,dept_code             VARCHAR2(4)         -- 05 : 部署
     ,output_type           VARCHAR2(1)         -- 06 : 出力区分
     ,block_01              VARCHAR2(2)         -- 07 : ブロック１
     ,block_02              VARCHAR2(2)         -- 08 : ブロック２
     ,block_03              VARCHAR2(2)         -- 09 : ブロック３
     ,ship_to_locat_code    VARCHAR2(4)         -- 10 : 入庫先
     ,online_type           VARCHAR2(1)         -- 11 : オンライン対象区分
     ,request_no            VARCHAR2(12)        -- 12 : 移動No
    ) ;
--    
  -- 中間テーブル登録用レコード変数
  TYPE rec_temp_tab_data IS RECORD
    (
      arvl_code             xxwsh_930d_tmp.arvl_code%TYPE           -- 入庫倉庫コード
     ,arvl_name             xxwsh_930d_tmp.arvl_name%TYPE           -- 入庫倉庫名称
     ,location_code         xxwsh_930d_tmp.location_code%TYPE       -- 出庫倉庫コード
     ,location_name         xxwsh_930d_tmp.location_name%TYPE       -- 出庫倉庫名称
     ,ship_date             xxwsh_930d_tmp.ship_date%TYPE           -- 出庫日
     ,arvl_date             xxwsh_930d_tmp.arvl_date%TYPE           -- 入庫日
     ,career_code           xxwsh_930d_tmp.career_code%TYPE         -- 運送業者コード
     ,career_name           xxwsh_930d_tmp.career_name%TYPE         -- 運送業者名称
     ,ship_method_code      xxwsh_930d_tmp.ship_method_code%TYPE    -- 配送区分コード
     ,ship_method_name      xxwsh_930d_tmp.ship_method_name%TYPE    -- 配送区分名称
     ,delivery_no           xxwsh_930d_tmp.delivery_no%TYPE         -- 配送Ｎｏ
     ,request_no            xxwsh_930d_tmp.request_no%TYPE          -- 移動Ｎｏ
     ,item_code             xxwsh_930d_tmp.item_code%TYPE           -- 品目コード
     ,item_name             xxwsh_930d_tmp.item_name%TYPE           -- 品目名称
     ,lot_no                xxwsh_930d_tmp.lot_no%TYPE              -- ロット番号
     ,product_date          xxwsh_930d_tmp.product_date%TYPE        -- 製造日
     ,use_by_date           xxwsh_930d_tmp.use_by_date%TYPE         -- 賞味期限
     ,original_char         xxwsh_930d_tmp.original_char%TYPE       -- 固有記号
     ,lot_status            xxwsh_930d_tmp.lot_status%TYPE          -- 品質
     ,quant_r               xxwsh_930d_tmp.quant_r%TYPE             -- 依頼数
     ,quant_i               xxwsh_930d_tmp.quant_i%TYPE             -- 入庫数
     ,quant_o               xxwsh_930d_tmp.quant_o%TYPE             -- 出庫数
     ,reason                xxwsh_930d_tmp.reason%TYPE              -- 差異事由
     ,inst_rslt_div         xxwsh_930d_tmp.inst_rslt_div%TYPE       -- 指示実績区分(0:保留 1：指示 2：実績) 2008/10/20 統合テスト障害#394(1)
    ) ;
--    
  -- 抽出データ格納用レコード変数
  TYPE rec_get_data IS RECORD
    (
      arvl_code        VARCHAR2(100)  -- 入庫倉庫コード
     ,arvl_name        VARCHAR2(100)  -- 入庫倉庫名称
     ,location_code    VARCHAR2(100)  -- 出庫倉庫コード
     ,location_name    VARCHAR2(100)  -- 出庫倉庫名称
     ,ship_date        DATE           -- 出庫日
     ,arvl_date        DATE           -- 入庫日
     ,career_id        VARCHAR2(100)  -- 検索条件：運送業者
     ,ship_method_code VARCHAR2(100)  -- 検索条件：配送区分
     ,order_type       VARCHAR2(100)  -- 業務種別（コード）     -- 2008/10/18 変更要求#210 Add
     ,delivery_no      VARCHAR2(100)  -- 配送Ｎｏ
     ,request_no       VARCHAR2(100)  -- 移動Ｎｏ
     ,order_line_id    VARCHAR2(100)  -- 検索条件：明細ＩＤ
     ,item_id          VARCHAR2(100)  -- 検索条件：品目ＩＤ
     ,item_code        VARCHAR2(100)  -- 品目コード
     ,item_name        VARCHAR2(100)  -- 品目名称
     ,lot_ctl          VARCHAR2(100)  -- 検索条件：ロット使用
     ,quant_r          NUMBER         -- 依頼数（ロット管理外）
     ,quant_i          NUMBER         -- 入庫数（ロット管理外）
     ,quant_o          NUMBER         -- 出庫数（ロット管理外）
-- 2008/07/28 A.Shiina v1.6 ADD Start
     ,quant_d          NUMBER   -- 内訳数量(インタフェース用)
-- 2008/07/28 A.Shiina v1.6 ADD End
     ,status           VARCHAR2(100)  -- 受注ヘッダステータス
-- add start ver1.1
     ,conv_unit        VARCHAR2(240)  -- 入出庫換算単位
     ,num_of_cases     NUMBER         -- ケース入数
-- add end ver1.1
-- add start ver1.2
     ,lot_id           NUMBER         -- ロットID
-- add end ver1.2
-- add start ver1.3
     ,prod_class_code VARCHAR(100)    -- 商品区分
-- add end ver1.3
-- 2008/07/09 A.Shiina v1.5 Update Start
     ,freight_charge_code   VARCHAR(1)  -- 運賃区分
     ,complusion_output_kbn VARCHAR(1)  -- 強制出力区分
-- 2008/07/09 A.Shiina v1.5 Update Start
-- 2008/11/17 統合指摘#651 Add Start -----------------------------------------------
     ,no_instr_actual  VARCHAR(1)        -- 指示なし実績：'Y' 指示あり実績:'N'
     ,lot_inst_cnt     NUMBER            -- 指示ロットの件数
     ,row_num          NUMBER            -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End -------------------------------------------------
    ) ;
--    
-- 中間テーブル格納用
  TYPE arvl_code_type            IS TABLE OF
    xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE    INDEX BY BINARY_INTEGER;--入庫倉庫コード
--
  TYPE arvl_name_type            IS TABLE OF
    mtl_item_locations.description%TYPE                    INDEX BY BINARY_INTEGER;--入庫倉庫名称
--
  TYPE location_code_type        IS TABLE OF
    mtl_item_locations.segment1%TYPE                       INDEX BY BINARY_INTEGER;--出庫倉庫コード
--
  TYPE location_name_type        IS  TABLE OF
    mtl_item_locations.description%TYPE                    INDEX BY BINARY_INTEGER;--出庫倉庫名称
--
  TYPE ship_date_type            IS  TABLE OF
    xxinv_mov_req_instr_headers.schedule_ship_date%TYPE    INDEX BY BINARY_INTEGER;--出庫日
--
  TYPE arvl_date_type            IS  TABLE OF
    xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;--入庫日
--
  TYPE career_code_type          IS TABLE OF
    xxcmn_carriers2_v.party_number%TYPE                    INDEX BY BINARY_INTEGER;--運送業者コード
--
  TYPE ship_method_code_type     IS TABLE OF
    xxcmn_carriers2_v.party_short_name%TYPE                INDEX BY BINARY_INTEGER; --運送業者名称
--
  TYPE delivery_no_type          IS TABLE OF
    xxcmn_lookup_values_v.lookup_code%TYPE                 INDEX BY BINARY_INTEGER;--配送区分コード
--
  TYPE request_no_type           IS TABLE OF
    xxcmn_lookup_values_v.meaning%TYPE                     INDEX BY BINARY_INTEGER;--配送区分名称
--
  TYPE order_line_id_type        IS TABLE OF
    xxinv_mov_req_instr_headers.delivery_no%TYPE           INDEX BY BINARY_INTEGER;-- 配送Ｎｏ
--
  TYPE item_id_type              IS TABLE OF
    xxinv_mov_req_instr_headers.mov_num%TYPE               INDEX BY BINARY_INTEGER;--移動Ｎｏ
--
  TYPE item_code_type            IS TABLE OF
    xxcmn_item_mst2_v.item_no%TYPE                         INDEX BY BINARY_INTEGER;--品目コード
--
  TYPE item_name_type            IS TABLE OF
    xxcmn_item_mst2_v.item_short_name%TYPE                 INDEX BY BINARY_INTEGER;--品目名称
--
  TYPE lot_ctl_type              IS TABLE OF
    ic_lots_mst.lot_no%TYPE                                INDEX BY BINARY_INTEGER;--ロット番号
--
  TYPE product_date_type         IS TABLE OF
    ic_lots_mst.attribute1%TYPE                            INDEX BY BINARY_INTEGER;--製造日
--
  TYPE use_by_date_type          IS TABLE OF
    ic_lots_mst.attribute3%TYPE                            INDEX BY BINARY_INTEGER;--賞味期限
--
  TYPE original_char_type        IS  TABLE OF
    ic_lots_mst.attribute2%TYPE                            INDEX BY BINARY_INTEGER;--固有記号
--
  TYPE meaning_type              IS TABLE OF
    xxcmn_lookup_values_v.meaning%TYPE                     INDEX BY BINARY_INTEGER;--品質
--
  TYPE quant_r_type              IS TABLE OF
    xxinv_mov_req_instr_lines.instruct_qty%TYPE            INDEX BY BINARY_INTEGER;--依頼数
--
  TYPE quant_i_type              IS TABLE OF
    xxinv_mov_req_instr_lines.ship_to_quantity%TYPE        INDEX BY BINARY_INTEGER;--入庫数
--
  TYPE quant_o_type              IS TABLE OF
    xxinv_mov_req_instr_lines.shipped_quantity%TYPE        INDEX BY BINARY_INTEGER;--出庫数
--
  TYPE reason_type               IS TABLE OF
    xxwsh_930d_tmp.reason%TYPE                             INDEX BY BINARY_INTEGER;--差異事由
--
  TYPE inst_rslt_div             IS TABLE OF                                                      -- 2008/10/20 統合テスト障害#394(1) Add
    xxwsh_930d_tmp.inst_rslt_div%TYPE                      INDEX BY BINARY_INTEGER;--指示実績区分 -- 2008/10/20 統合テスト障害#394(1) Add
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- 処理データカウンタ
--
  gb_get_flg            BOOLEAN DEFAULT FALSE ;-- データ取得判定フラグ
  gt_xml_data_table     XML_DATA ;             -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER DEFAULT 0 ;     -- ＸＭＬデータタグ表のインデックス
--
  gn_created_by               NUMBER ;  -- 作成者
  gn_last_updated_by          NUMBER ;  -- 最終更新者
  gn_last_update_login        NUMBER ;  -- 最終更新ログイン
  gn_request_id               NUMBER ;  -- 要求ID
  gn_program_application_id   NUMBER ;  -- コンカレント・プログラム・アプリケーションID
  gn_program_id               NUMBER ;  -- コンカレント・プログラムID
--
  gv_nvl_null_char        VARCHAR2(4) := 'NULL';   -- 2008/10/31 統合指摘#462 Add
  gn_nvl_null_num         NUMBER := 0;             -- 2008/10/31 統合指摘#462 Add
--
  -- ==============================
  -- 中間テーブル登録用
  -- ==============================
  gt_arvl_code_tbl         arvl_code_type;        -- 入庫倉庫コード
  gt_arvl_name_tbl         arvl_name_type;        -- 入庫倉庫名称
  gt_location_code_tbl     location_code_type;    -- 出庫倉庫コード
  gt_location_name_tbl     location_name_type;    -- 出庫倉庫名称
  gt_ship_date_tbl         ship_date_type;        -- 出庫日
  gt_arvl_date_tbl         arvl_date_type;        -- 入庫日
  gt_career_code_tbl       career_code_type;      -- 運送業者コード
  gt_career_name_tbl       ship_method_code_type; -- 運送業者名称
  gt_ship_method_code_tbl  delivery_no_type;      -- 配送区分コード
  gt_ship_method_name_tbl  request_no_type;       -- 配送区分名称
  gt_delivery_no_tbl       order_line_id_type;    -- 配送Ｎｏ
  gt_request_no_tbl        item_id_type;          -- 移動Ｎｏ
  gt_item_code_tbl         item_code_type;        -- 品目コード
  gt_item_name_tbl         item_name_type;        -- 品目名称
  gt_lot_ctl_tbl           lot_ctl_type;          -- ロット番号
  gt_product_date_tbl      product_date_type;     -- 製造日
  gt_use_by_date_tbl       use_by_date_type;      -- 賞味期限
  gt_original_char_tbl     original_char_type;    -- 固有記号
  gt_meaning_tbl           meaning_type;          -- 品質
  gt_quant_r_tbl           quant_r_type;          -- 依頼数
  gt_quant_i_tbl           quant_i_type;          -- 入庫数
  gt_quant_o_tbl           quant_o_type;          -- 出庫数
  gt_reason_tbl            reason_type;           -- 差異事由
  gt_inst_rslt_div_tbl     inst_rslt_div;         -- 指示実績区分  2008/10/20 統合テスト障害#394(1) Add
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_user
   * Description      : ユーザー情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_user
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_xml_data_user' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
--
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
--
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
--
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ) ;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_xml_data_user ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_out_data
   * Description      : ＸＭＬデータ出力処理
   ************************************************************************************************/
  PROCEDURE prc_create_out_data
    (
      ov_errbuf     OUT    VARCHAR2             -- エラー・メッセージ
     ,ov_retcode    OUT    VARCHAR2             -- リターン・コード
     ,ov_errmsg     OUT    VARCHAR2             -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_out_data' ; -- プログラム名
--
    -- 中間テーブルデータ抽出用
    cv_sql_dtl        CONSTANT VARCHAR2(32000)
      := ' SELECT DISTINCT'
      || '        x9t.item_code         AS item_code'
      || '       ,x9t.item_name         AS item_name'
      || '       ,x9t.lot_no            AS lot_no'
      || '       ,TO_CHAR( x9t.product_date, ''YYYY/MM/DD'' ) AS product_date'
      || '       ,TO_CHAR( x9t.use_by_date , ''YYYY/MM/DD'' ) AS use_by_date'
      || '       ,x9t.original_char     AS original_char'
      || '       ,x9t.lot_status        AS lot_status'
      || '       ,NVL( x9t.quant_r, ''0'' ) AS quant_r'
      || '       ,NVL( x9t.quant_i, ''0'' ) AS quant_i'
      || '       ,NVL( x9t.quant_o, ''0'' ) AS quant_o'
      || '       ,x9t.reason                AS reason'
      || ' FROM xxwsh_930d_tmp   x9t'
      || ' WHERE NVL( x9t.reason, ''*'' ) = NVL( :V1, NVL( x9t.reason, ''*'' ) )'
-- mod start ver1.1
--      || ' AND    x9t.delivery_no  = :V2'
      || ' AND   NVL(x9t.delivery_no,''X'') = NVL(:V2,''X'')'
-- mod end ver1.1
      || ' AND    x9t.request_no   = :V3'
      || ' AND    x9t.inst_rslt_div = :V4'    -- 2008/10/20 統合テスト障害#394(1) Add
      ;
    cv_sql_order_1    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_CHAR(x9t.product_date, ''YYYY/MM/DD'')'
      || '         ,x9t.original_char'
      ;
    cv_sql_order_2    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_NUMBER( x9t.lot_no )'
      ;
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    -- マスタレコード取得カーソル
    CURSOR cu_mst( p_item_code xxwsh_930d_tmp.item_code%TYPE )
    IS
      SELECT mst.arvl_code           -- 入庫倉庫コード
            ,mst.arvl_name           -- 入庫倉庫名称
            ,mst.location_code       -- 出庫倉庫コード
            ,mst.location_name       -- 出庫倉庫名称
            ,mst.ship_date           -- 出庫日
            ,mst.arvl_date           -- 入庫日
            ,mst.career_code         -- 運送業者
            ,mst.career_name         -- 運送業者名称
            ,mst.ship_method_code    -- 配送区分コード
            ,mst.ship_method_name    -- 配送区分名称
            ,mst.delivery_no         -- 配送No
            ,mst.request_no          -- 移動No
            ,mst.inst_rslt_div       -- 指示実績区分        2008/10/20 統合テスト障害#394(1) Add
      FROM
      (
        SELECT DISTINCT
               x9t.arvl_code         AS arvl_code
              ,x9t.arvl_name         AS arvl_name
              ,x9t.location_code     AS location_code
              ,x9t.location_name     AS location_name
              ,TO_CHAR( x9t.ship_date , 'YYYY/MM/DD' ) AS ship_date
              ,TO_CHAR( x9t.arvl_date , 'YYYY/MM/DD' ) AS arvl_date
              ,x9t.career_code       AS career_code
              ,x9t.career_name       AS career_name
              ,x9t.ship_method_code  AS ship_method_code
              ,x9t.ship_method_name  AS ship_method_name
              ,x9t.delivery_no       AS delivery_no
              ,x9t.request_no        AS request_no
              ,x9t.inst_rslt_div     AS inst_rslt_div       -- 2008/10/20 統合テスト障害#394(1) Add
        FROM xxwsh_930d_tmp   x9t
        WHERE x9t.item_code = NVL( p_item_code, x9t.item_code )
      ) mst
-- mod start ver1.2
--      ORDER BY mst.location_code
      ORDER BY mst.arvl_code
-- mod end ver1.2
              ,mst.ship_date
              ,mst.arvl_date
              ,mst.delivery_no
              ,mst.request_no
              ,mst.inst_rslt_div   -- 2008/10/20 統合テスト障害#394(1) Add
    ;    
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- ブレイク判断用
    lv_tmp_arvl_code    VARCHAR2(4) DEFAULT '*' ;
    -- マスタ項目出力用
    lv_ship_to_location_code     VARCHAR2(4) ;        -- 入庫倉庫コード
    lv_ship_to_location_name     VARCHAR2(20);        -- 入庫倉庫名称
    lv_shipped_locat_code        VARCHAR2(4) ;        -- 出庫倉庫コード
    lv_shipped_locat_name        VARCHAR2(20);        -- 出庫倉庫名称
    lv_ship_date                 VARCHAR2(10);        -- 出庫日
    lv_arvl_date                 VARCHAR2(10);        -- 入庫日
    lv_freight_carrier_code      VARCHAR2(4) ;        -- 運送業者コード
    lv_freight_carrier_name      VARCHAR2(20);        -- 運送業者名称
    lv_ship_method_code          VARCHAR2(2) ;        -- 配送区分コード
    lv_ship_method_name          VARCHAR2(14);        -- 配送区分名称
    lv_delivery_no               VARCHAR2(12);        -- 配送Ｎｏ
    lv_request_no                VARCHAR2(12);        -- 移動Ｎｏ
    lv_param_reason              VARCHAR2(6) ;        -- 差異事由（ＳＱＬ実行用）
-- add start ver1.2
    lv_item_code                 VARCHAR2(7) ;        -- 品目コード
    lv_item_name                 VARCHAR2(20) ;       -- 品目名称
-- add end ver1.2
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;             -- REF_CURSOR用
    TYPE ret_value  IS RECORD
      (
        item_code           VARCHAR2(7)         -- 品目コード
       ,item_name           VARCHAR2(20)        -- 品目名称
       ,lot_no              VARCHAR2(10)        -- ロット番号
       ,product_date        VARCHAR2(10)        -- 製造日
       ,use_by_date         VARCHAR2(10)        -- 賞味期限
       ,original_char       VARCHAR2(6)         -- 固有記号
       ,lot_status          VARCHAR2(10)        -- 品質
       ,quant_r             VARCHAR2(12)        -- 依頼数
       ,quant_i             VARCHAR2(12)        -- 入庫数
       ,quant_o             VARCHAR2(12)        -- 出庫数
       ,reason              VARCHAR2(6)         -- 差異事由
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 中間テーブルデータ抽出ＳＱＬ文生成
    -- ====================================================
    ------------------------------
    -- Ｐ．品目区分が製品の場合
    ------------------------------
    IF ( gr_param.item_div = gc_item_div_sei ) THEN
      lv_sql := cv_sql_dtl || cv_sql_order_1 ;
    ------------------------------
    -- Ｐ．品目区分が製品以外の場合
    ------------------------------
    ELSE
      lv_sql := cv_sql_dtl || cv_sql_order_2 ;
--
    END IF ;
--
    -- ====================================================
    -- パラメータ変換
    -- ====================================================
    BEGIN
      -- 出力区分
      IF ( gr_param.output_type IS NOT NULL ) THEN
        SELECT xlvv.meaning
        INTO   lv_param_reason
        FROM xxcmn_lookup_values_v xlvv
        WHERE xlvv.lookup_type = gc_lookup_output_type
        AND   xlvv.lookup_code = gr_param.output_type
        ;
        
      END IF ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_others_expt ;
      WHEN TOO_MANY_ROWS THEN
        RAISE global_api_others_expt ;
    END ;
--
    -- ====================================================
    -- リストグループ開始タグ（入庫倉庫）
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--
    <<mst_data_loop>>
   FOR re_data IN cu_mst( lv_request_no ) LOOP
      -- ----------------------------------------------------
      -- 明細カーソルオープン
      -- ----------------------------------------------------
      OPEN lc_ref FOR lv_sql
      USING lv_param_reason
           ,re_data.delivery_no
           ,re_data.request_no
           ,re_data.inst_rslt_div   -- 2008/10/20 統合テスト障害#394(1) Add
      ;
      FETCH lc_ref INTO lr_ref ;
--
      IF ( lc_ref%FOUND ) THEN
        -- ====================================================
        -- 入庫倉庫ブレイク
        -- ====================================================
        IF ( re_data.arvl_code <> lv_tmp_arvl_code ) THEN
          -- ----------------------------------------------------
          -- グループ終了タグ出力
          -- ----------------------------------------------------
          -- 初回レコードの場合は表示しない
          IF ( lv_tmp_arvl_code <> '*' ) THEN
            -- リストグループ終了タグ（入庫情報）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- グループ終了タグ（入庫倉庫）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
--
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lctn' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- データタグ出力
          -- ----------------------------------------------------
          -- 入庫倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.arvl_code ;
          -- 入庫倉庫名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.arvl_name ;
--
          -- ----------------------------------------------------
          -- リストグループ開始タグ（出荷）
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_spmt_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- ブレイク判断用項目の退避
          -- ----------------------------------------------------
          lv_tmp_arvl_code := re_data.arvl_code ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_spto' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- マスタ項目の退避
        -- ----------------------------------------------------
        lv_shipped_locat_code     := re_data.location_code;        -- 出庫倉庫
        lv_shipped_locat_name     := re_data.location_name;        -- 出庫倉庫名称
        lv_ship_date              := re_data.ship_date ;           -- 出庫日
        lv_arvl_date              := re_data.arvl_date ;           -- 入庫日
        lv_freight_carrier_code   := re_data.career_code ;         -- 運送業者コード
        lv_freight_carrier_name   := re_data.career_name ;         -- 運送業者名称
        lv_ship_method_code       := re_data.ship_method_code ;    -- 配送区分コード
        lv_ship_method_name       := re_data.ship_method_name ;    -- 配送区分名称
        lv_delivery_no            := re_data.delivery_no ;         -- 配送Ｎｏ
        lv_request_no             := re_data.request_no ;          -- 移動Ｎｏ
--
        -- ====================================================
        -- 明細情報出力
        -- ====================================================
        -- ----------------------------------------------------
        -- リストグループ開始タグ（明細）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        <<dtl_data_loop>>
        LOOP
--
          gn_data_cnt := gn_data_cnt + 1 ;
--
          -- ----------------------------------------------------
          -- グループ開始タグ（明細）
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- データタグ出力
          -- ----------------------------------------------------
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_date ;
          -- 入庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'arvl_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_arvl_date ;
          -- 出庫倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value :=  lv_shipped_locat_code;
          -- 出庫倉庫名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_locat_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value :=  lv_shipped_locat_name;
          -- 運送業者コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_carrier_code ;
          -- 運送業者名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'freight_carrier_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_freight_carrier_name ;
          -- 配送区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_code ;
          -- 配送区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_method_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_method_name ;
          -- 配送Ｎｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_delivery_no ;
          -- 移動Ｎｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'mov_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_request_no ;
--
          -- 品目コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.2
--          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          IF ( lv_item_code = lr_ref.item_code AND lv_request_no IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          ELSIF ( lv_item_code IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
          END IF;
-- mod end ver1.2
          -- 品目名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.2
--          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          IF ( lv_item_name = lr_ref.item_name AND lv_request_no IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          ELSIF ( lv_item_name IS NULL ) THEN
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          ELSE
           gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
          END IF;
-- mod end ver1.2
          -- ロットＮｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_no ;
          -- 製造日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.product_date ;
          -- 賞味期限
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.use_by_date ;
          -- 固有記号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_sign' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char ;
          -- 品質
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quality' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_status ;
          -- 依頼数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'actual_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_r ;
          -- 入庫数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_i ;
          -- 出庫数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_o ;
          -- 差異事由
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'reason' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.reason ;
--
          -- ----------------------------------------------------
          -- グループ終了タグ（明細）
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- マスタ項目の初期化
          -- ----------------------------------------------------
          lv_shipped_locat_code    := NULL ;  -- 出庫倉庫
          lv_shipped_locat_name    := NULL ;  -- 出庫倉庫名称
          lv_ship_date             := NULL ;  -- 出庫日
          lv_arvl_date             := NULL ;  -- 入庫日
          lv_freight_carrier_code  := NULL ;  -- 運送業者コード
          lv_freight_carrier_name  := NULL ;  -- 運送業者名称
          lv_ship_method_code      := NULL ;  -- 配送区分コード
          lv_ship_method_name      := NULL ;  -- 配送区分名称
          lv_delivery_no           := NULL ;  -- 配送Ｎｏ
          lv_request_no            := NULL ;  -- 移動Ｎｏ
--
-- add start ver1.2
          lv_item_code := lr_ref.item_code ;
          lv_item_name := lr_ref.item_name ;
-- add end ver1.2
          FETCH lc_ref INTO lr_ref ;
          EXIT WHEN lc_ref%NOTFOUND ;
--
        END LOOP dtl_data_loop ;
        -- ====================================================
        -- カーソルクローズ
        -- ====================================================
        CLOSE lc_ref ;
--
        -- リストグループ終了タグ（明細）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- グループ終了タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_spto' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      ELSE
        -- ====================================================
        -- カーソルクローズ
        -- ====================================================
        CLOSE lc_ref ;
      END IF;
--
    END LOOP mst_data_loop ;
--
    -- ====================================================
    -- グループ終了タグ出力
    -- ====================================================
    -- リストグループ終了タグ（出庫情報）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- グループ終了タグ（入庫倉庫）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- リストグループ終了タグ（入庫倉庫）
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_out_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_ins_temp_data
   * Description      : 中間テーブル登録
   ************************************************************************************************/
  PROCEDURE prc_ins_temp_data
    (
      ov_errbuf     OUT    VARCHAR2             -- エラー・メッセージ
     ,ov_retcode    OUT    VARCHAR2             -- リターン・コード
     ,ov_errmsg     OUT    VARCHAR2             -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_ins_temp_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 中間テーブル初期化
    -- ====================================================
    DELETE FROM xxwsh_930d_tmp;
    --
    -- ====================================================
    -- 中間テーブル登録
    -- ====================================================
    FORALL i IN 1 .. gt_arvl_code_tbl.COUNT
      INSERT INTO xxwsh_930d_tmp
        ( arvl_code                     -- 入庫倉庫コード
         ,arvl_name                     -- 入庫倉庫名称
         ,location_code                 -- 出庫倉庫コード
         ,location_name                 -- 出庫倉庫名称
         ,ship_date                     -- 出庫日
         ,arvl_date                     -- 入庫日
         ,career_code                   -- 運送業者コード
         ,career_name                   -- 運送業者名称
         ,ship_method_code              -- 配送区分コード
         ,ship_method_name              -- 配送区分名称
         ,delivery_no                   -- 配送Ｎｏ
         ,request_no                    -- 移動Ｎｏ
         ,item_code                     -- 品目コード
         ,item_name                     -- 品目名称
         ,lot_no                        -- ロット番号
         ,product_date                  -- 製造日
         ,use_by_date                   -- 賞味期限
         ,original_char                 -- 固有記号
         ,lot_status                    -- 品質
         ,quant_r                       -- 依頼数
         ,quant_i                       -- 入庫数
         ,quant_o                       -- 出庫数
         ,reason                        -- 差異事由
         ,inst_rslt_div                 -- 指示実績区分      2008/10/20 統合テスト障害#394(1) Add
         ,created_by                    -- 作成者
         ,creation_date                 -- 作成日
         ,last_updated_by               -- 最終更新者
         ,last_update_date              -- 最終更新日
         ,last_update_login             -- 最終更新ログイン
         ,request_id                    -- 要求ID
         ,program_application_id        -- コンカレント・プログラム・アプリケーションID
         ,program_id                    -- コンカレント・プログラムID
         ,program_update_date           -- プログラム更新日
        )
      VALUES
        (
          SUBSTRB( gt_arvl_code_tbl(i)        , 1, 4  )  -- 入庫倉庫コード
         ,SUBSTRB( gt_arvl_name_tbl(i)        , 1, 20 )  -- 入庫倉庫名称
         ,SUBSTRB( gt_location_code_tbl(i)    , 1, 4  )  -- 出庫倉庫コード
         ,SUBSTRB( gt_location_name_tbl(i)    , 1, 20 )  -- 出庫倉庫名称
         ,gt_ship_date_tbl(i)                            -- 出庫日
         ,gt_arvl_date_tbl(i)                            -- 入庫日
         ,SUBSTRB( gt_career_code_tbl(i)      , 1, 4  )  -- 運送業者コード
         ,SUBSTRB( gt_career_name_tbl(i) , 1, 20 )       -- 運送業者名称
         ,SUBSTRB( gt_ship_method_code_tbl(i) , 1, 2  )  -- 配送区分コード
         ,SUBSTRB( gt_ship_method_name_tbl(i) , 1, 14 )  -- 配送区分名称
         ,SUBSTRB( gt_delivery_no_tbl(i)      , 1, 12 )  -- 配送Ｎｏ
         ,SUBSTRB( gt_request_no_tbl(i)       , 1, 12 )  -- 移動Ｎｏ
         ,SUBSTRB( gt_item_code_tbl(i)        , 1, 7  )  -- 品目コード
         ,SUBSTRB( gt_item_name_tbl(i)        , 1, 20 )  -- 品目名称
         ,SUBSTRB( gt_lot_ctl_tbl(i)          , 1, 10 )  -- ロット番号
         ,gt_product_date_tbl(i)                         -- 製造日
         ,gt_use_by_date_tbl(i)                          -- 賞味期限
         ,SUBSTRB( gt_original_char_tbl(i)    , 1, 6  )  -- 固有記号
         ,SUBSTRB( gt_meaning_tbl(i)          , 1, 10 )  -- 品質
         ,SUBSTRB( gt_quant_r_tbl(i)          , 1, 12 )  -- 依頼数
         ,SUBSTRB( gt_quant_i_tbl(i)          , 1, 12 )  -- 入庫数
         ,SUBSTRB( gt_quant_o_tbl(i)          , 1, 12 )  -- 出庫数
         ,SUBSTRB( gt_reason_tbl(i)           , 1, 6  )  -- 差異事由
         ,SUBSTRB( gt_inst_rslt_div_tbl(i)    , 1, 1  )  -- 指示実績区分   2008/10/20 統合テスト障害#394(1) Add
         ,gn_created_by               -- 作成者
         ,SYSDATE                     -- 作成日
         ,gn_last_updated_by          -- 最終更新者
         ,SYSDATE                     -- 最終更新日
         ,gn_last_update_login        -- 最終更新ログイン
         ,gn_request_id               -- 要求ID
         ,gn_program_application_id   -- コンカレント・プログラム・アプリケーションID
         ,gn_program_id               -- コンカレント・プログラムID
         ,SYSDATE                     -- プログラム更新日
        ) ;
--
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_ins_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_set_temp_data
   * Description      : 中間テーブル登録データ設定
   ************************************************************************************************/
  PROCEDURE prc_set_temp_data
    (
      ir_get_data   IN    rec_get_data        -- 抽出データ
     ,or_temp_tab   OUT   rec_temp_tab_data   -- 中間テーブル登録データ
     ,ov_errbuf     OUT   VARCHAR2            -- エラー・メッセージ
     ,ov_retcode    OUT   VARCHAR2            -- リターン・コード
     ,ov_errmsg     OUT   VARCHAR2            -- ユーザー・エラー・メッセージ
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'prc_set_temp_data' ; -- プログラム名
-- 2008/07/28 A.Shiina v1.6 ADD Start
    cv_eos_data_cd_220  CONSTANT VARCHAR2(3) := '220';  -- 220 移動出庫確定報告
    cv_eos_data_cd_230  CONSTANT VARCHAR2(3) := '230';  -- 230 移動入庫確定報告
-- 2008/07/28 A.Shiina v1.6 ADD End
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_reserved_status  xxwsh_shipping_lines_if.reserved_status%TYPE ;   -- 保留ステータス
-- 2008/07/28 A.Shiina v1.6 ADD Start
    lv_eos_data_type    xxwsh_shipping_headers_if.eos_data_type%TYPE ;  -- EOSデータ種別
    ln_quant_kbn        NUMBER;         -- 数量区分
--
    ln_cnt              NUMBER := 0 ;   -- 存在カウント
-- 2008/07/28 A.Shiina v1.6 ADD End
--
    ln_temp_cnt         NUMBER DEFAULT 0 ;   -- 取得レコードカウント
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
--
    --------------------------------------------------
    -- 入庫倉庫設定
    --------------------------------------------------
    or_temp_tab.arvl_code := ir_get_data.arvl_code ;  -- 入庫倉庫コード
    or_temp_tab.arvl_name := ir_get_data.arvl_name ;  -- 入庫倉庫名称
    --------------------------------------------------
    -- 出庫倉庫設定
    --------------------------------------------------
    or_temp_tab.location_code := ir_get_data.location_code ;  -- 出庫倉庫コード
    or_temp_tab.location_name := ir_get_data.location_name ;  -- 出庫倉庫名称
--
    --------------------------------------------------
    -- 出庫日・入庫日設定
    --------------------------------------------------
    or_temp_tab.ship_date := ir_get_data.ship_date ;  -- 出庫日
    or_temp_tab.arvl_date := ir_get_data.arvl_date ;  -- 入庫日
--
-- 2008/07/09 A.Shiina v1.5 Update Start
   IF  ((ir_get_data.freight_charge_code  = '1')
    OR (ir_get_data.complusion_output_kbn = '1')) THEN
-- 2008/07/09 A.Shiina v1.5 Update End
    --------------------------------------------------
    -- 運送業者設定
    --------------------------------------------------
    BEGIN
      -- 保留データの場合
      IF ( ir_get_data.status IS NULL ) THEN
        SELECT xc.party_number
              ,xc.party_short_name
        INTO   or_temp_tab.career_code  -- 運送業者コード
              ,or_temp_tab.career_name  -- 運送業者名称
        FROM xxcmn_carriers2_v  xc      -- 運送業者情報VIEW2
        WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
-- 2008/07/09 A.Shiina v1.5 Update Start
---- mod start ver1.1
----        AND   xc.party_number     = ir_get_data.career_id
--        AND   xc.party_id         = ir_get_data.career_id
---- mod end ver1.1
        AND   xc.party_number     = ir_get_data.career_id
-- 2008/07/09 A.Shiina v1.5 Update End
        ;
     -- 保留データ以外の場合
      ELSE
        SELECT xc.party_number
              ,xc.party_short_name
        INTO   or_temp_tab.career_code  -- 運送業者コード
              ,or_temp_tab.career_name  -- 運送業者名称
        FROM xxcmn_carriers2_v  xc      -- 運送業者情報VIEW2
        WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        AND   xc.party_id        = ir_get_data.career_id
        ;
     END IF ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
    END ;
-- 2008/07/09 A.Shiina v1.5 Update Start
   END IF;
-- 2008/07/09 A.Shiina v1.5 Update End
--
    --------------------------------------------------
    -- 配送区分設定
    --------------------------------------------------
    BEGIN
      SELECT xlv.lookup_code
            ,xlv.meaning
      INTO   or_temp_tab.ship_method_code   -- 配送区分コード
            ,or_temp_tab.ship_method_name   -- 配送区分名称
      FROM xxcmn_lookup_values_v   xlv   -- クイックコード情報VIEW
      WHERE xlv.lookup_type = gc_lookup_ship_method_code
      AND   xlv.lookup_code = ir_get_data.ship_method_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.ship_method_code := NULL ;
        or_temp_tab.ship_method_name := NULL ;
    END ;
--
    --------------------------------------------------
    -- 配送Ｎｏ・移動Ｎｏ設定
    --------------------------------------------------
    or_temp_tab.delivery_no := ir_get_data.delivery_no ;  -- 配送Ｎｏ
    or_temp_tab.request_no  := ir_get_data.request_no ;   -- 移動Ｎｏ
--
    --------------------------------------------------
    -- 品目設定
    --------------------------------------------------
    or_temp_tab.item_code := ir_get_data.item_code ;  -- 品目コード
    or_temp_tab.item_name := ir_get_data.item_name ;  -- 品目名称
--
    -- 2008/10/10 統合テスト障害#394(1) Add Start -----------------------------------
    --------------------------------------------------
    -- 指示・実績区分設定
    --------------------------------------------------
    -- 保留データの場合
    IF ( ir_get_data.status IS NULL ) THEN
--
      or_temp_tab.inst_rslt_div := gc_inst_rslt_div_h ; -- 保留
--
    -- 保留データ以外の場合
    ELSE
      -- 指示レコードであるかを確認する
      SELECT COUNT( xmrih.mov_hdr_id )
      INTO   ln_temp_cnt
      FROM   xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
      WHERE xmrih.career_id             = ir_get_data.career_id
      AND   xmrih.shipping_method_code  = ir_get_data.ship_method_code
      AND   xmrih.schedule_ship_date    = ir_get_data.ship_date
      AND   xmrih.schedule_arrival_date = ir_get_data.arvl_date
      AND   xmrih.mov_num               = or_temp_tab.request_no  -- 移動Ｎｏ
      ;
--
      -- 指示レコードの場合
      IF ln_temp_cnt > 0 THEN
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_i ; -- 指示
--
      -- 指示レコードではない場合
      ELSE
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_r ; -- 実績
      END IF ;
--
    END IF;
    -- 2008/10/10 統合テスト障害#394(1) Add End ----------------------------------
--
    --------------------------------------------------
    -- ロット情報設定
    --------------------------------------------------
-- del satart ver1.1
    -- ロット管理品以外の場合
--    IF ( ir_get_data.lot_ctl = gc_lot_ctl_n ) THEN
--
--      or_temp_tab.lot_no        := NULL ;                 -- ロット番号
--      or_temp_tab.product_date  := NULL ;                 -- 製造日
--      or_temp_tab.use_by_date   := NULL ;                 -- 賞味期限
--      or_temp_tab.original_char := NULL ;                 -- 固有記号
--      or_temp_tab.lot_status    := NULL ;                 -- 品質
--      or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- 依頼数
--      or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- 入庫数
--      or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- 出庫数
--
    -- ロット管理品の場合
--    ELSIF ( ir_get_data.lot_ctl = gc_lot_ctl_y ) THEN
-- del end ver1.1
-- 2008/07/28 A.Shiina v1.6 ADD Start
--
    -- 変数初期化
    ln_cnt := 0;
--
    -- 移動ロット詳細アドオン存在チェック
    SELECT  COUNT(1)
    INTO    ln_cnt
    FROM    xxinv_mov_lot_details   xmld    -- 移動ロット詳細アドオン
    WHERE   xmld.document_type_code = gc_doc_type_move
    AND   xmld.mov_line_id          = ir_get_data.order_line_id
    AND   xmld.lot_id               = ir_get_data.lot_id
    ;
--
-- 2008/07/28 A.Shiina v1.6 ADD End
      -- ロット情報取得
      BEGIN
-- 2008/07/28 A.Shiina v1.6 ADD Start
    -- 移動ロット詳細アドオンに存在する場合
      IF (ln_cnt > 0) THEN
-- 2008/07/28 A.Shiina v1.6 ADD End
-- mod satart ver1.1
--        SELECT ilm.lot_no                                    -- ロット番号
        SELECT xmld.lot_no                                   -- ロット番号
-- mod end ver1.1
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )  -- 製造日
              ,ilm.attribute2                                -- 固有記号
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )  -- 賞味期限
              ,xlv.meaning                                   -- 品質
-- mod satart ver1.1
--              ,SUM( CASE
--                      WHEN (xmld.record_type_code = gc_rec_type_inst) THEN xmld.actual_quantity
--                      ELSE 0
--                    END )                                    -- 依頼数
--              ,SUM( CASE
--                      WHEN (xmld.record_type_code = gc_rec_type_dlvr) THEN xmld.actual_quantity
--                      ELSE 0
--                    END )                                    -- 入庫数
--              ,SUM( CASE
--                      WHEN (xmld.record_type_code = gc_rec_type_stck) THEN xmld.actual_quantity
--                      ELSE 0
--                    END )                                    -- 出庫数
              --***************************************************************************
              --*  指示ロット（依頼数）
              --***************************************************************************
              --,SUM( CASE               -- 2008/12/25 本番障害#831 Del
              ,MAX( CASE                 -- 2008/12/25 本番障害#831 Add (SUMを消したいがGroupByと他のSUMのしがらみからMAXを使用。MAXそのもには意味無し)
                      --WHEN (xmld.record_type_code = gc_rec_type_inst) THEN  -- 指示の場合  2008/11/17 統合指摘#651 Del
                      -- 2008/11/17 統合指摘#651 Add Start ------------------------------
                     --********************************
                     --*  指示なし実績     ※明細の依頼数を使用
                     --********************************
                      --WHEN (xmld.record_type_code = gc_rec_type_inst)          -- 2008/12/25 本番障害#831 Del  指示なしなのに指示ロットはないから消しました
                      --  AND (ir_get_data.no_instr_actual = gc_yn_div_y) THEN   -- 2008/12/25 本番障害#831 Del
                      WHEN (ir_get_data.no_instr_actual = gc_yn_div_y) THEN      -- 2008/12/25 本番障害#831 Add
                      -- 2008/11/17 統合指摘#651 Add End --------------------------------
                        CASE 
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--                          WHEN xicv.item_class_code = '5'             -- 品目区分が製品
---- mod start ver1.3
----                           AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
---- mod end ver1.3
                         WHEN ((xicv.item_class_code = '5')               -- 品目区分が製品、かつ
                          AND (ir_get_data.conv_unit IS NOT NULL)         -- 入出庫換算単位がNULLでない、かつ
                          AND (ir_get_data.prod_class_code = '2')         -- 商品区分がドリンク、かつ
                          AND (ir_get_data.num_of_cases > 0))THEN         -- ケース入数が1以上の場合
---- mod start ver1.2
----                              (xmld.actual_quantity/ir_get_data.num_of_cases)
--                              ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                           -- 2008/10/20 課題T_S_486 Del Start ---------------------------
                           --ROUND((NVL(xmld.actual_quantity, ir_get_data.quant_r)
                           --        /ir_get_data.num_of_cases),3)
                           -- 2008/10/20 課題T_S_486 Del End -----------------------------
                           -- 2008/10/20 課題T_S_486 Add Start ---------------------------
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)       -- 換算する
                           -- 2008/10/20 課題T_S_486 Add End -----------------------------
--
-- 2008/07/28 A.Shiina v1.6 UPDATE End
-- mod end ver1.2
                        ELSE
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--                              (xmld.actual_quantity/1)
--
                           --NVL(xmld.actual_quantity, ir_get_data.quant_r)  -- 2008/10/20 課題T_S_486 Del
                           ir_get_data.quant_r    -- 換算しない              -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/28 A.Shiina v1.6 UPDATE End
                        END
                     -- 2008/11/17 統合指摘#651 Add Start -----------------------------------------------------------------
                     --****************************************
                     --*  指示あり実績の場合(指示ロットあり)       ※指示ロットの指示数量を使用
                     --****************************************
                     WHEN (xmld.record_type_code = gc_rec_type_inst)
                       AND (ir_get_data.no_instr_actual = gc_yn_div_n)
                     THEN
                       CASE
                         WHEN ((xicv.item_class_code = '5')            -- 品目区分が製品、かつ
                          AND (ir_get_data.conv_unit IS NOT NULL)      -- 入出庫換算単位がNULLでない、かつ
                          AND (ir_get_data.prod_class_code = '2')      -- 商品区分がドリンク、かつ
                          AND (ir_get_data.num_of_cases > 0))THEN      -- ケース入数が1以上の場合
                           ROUND(xmld.actual_quantity / ir_get_data.num_of_cases, 3)   -- 換算する
                         ELSE
                           xmld.actual_quantity   -- 換算しない
                         END
--
                     --****************************************
                     --*  指示あり実績の場合(指示ロットなし)       ※明細の依頼数を使用
                     --****************************************
                     WHEN (ir_get_data.no_instr_actual = gc_yn_div_n)   -- 指示あり実績
                       AND (ir_get_data.lot_inst_cnt = 0)               -- 指示ロットが０件
                       AND (ir_get_data.row_num = 1)                    -- ロット割れの場合は最初のロットにのみ出力する
                     THEN
                        CASE
                          WHEN ((xicv.item_class_code = '5')              -- 品目区分が製品、かつ
                           AND (ir_get_data.conv_unit IS NOT NULL)        -- 入出庫換算単位がNULLでない、かつ
                           AND (ir_get_data.prod_class_code = '2')        -- 商品区分がドリンク、かつ
                           AND (ir_get_data.num_of_cases > 0))THEN        -- ケース入数が1以上の場合
                            ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)  -- 換算する
                          ELSE
                            ir_get_data.quant_r  -- 換算しない
                          END
                      -- 2008/11/17 統合指摘#651 Add End ------------------------------------------------------------------
--
                      ELSE 0
                    END )
--
              --*********************************************
              --*  入庫実績ロット（入庫数）
              --**********************************************
              ,SUM( CASE
                      WHEN (xmld.record_type_code = gc_rec_type_dlvr) THEN   -- 入庫実績
                        CASE
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--                          WHEN xicv.item_class_code = '5'             -- 品目区分が製品
---- mod start ver1.3
----                           AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
---- mod end ver1.3
                         WHEN ((xicv.item_class_code = '5')             -- 品目区分が製品、かつ
                          AND (ir_get_data.conv_unit IS NOT NULL)       -- 入出庫換算単位がNULLでない、かつ
                          AND (ir_get_data.prod_class_code = '2')       -- 商品区分がドリンク、かつ
                          AND (ir_get_data.num_of_cases > 0)) THEN      -- ケース入数が1以上の場合
-- 2008/07/28 A.Shiina v1.6 UPDATE End
-- mod start ver1.2
--                              (xmld.actual_quantity/ir_get_data.num_of_cases)
                              ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)    -- 換算する
-- mod end ver1.2
                        ELSE
                              (xmld.actual_quantity/1)  -- 換算しない
                        END
                      ELSE 0
                    END )
--
              --*********************************************
              --*  出庫実績ロット（出庫数）
              --**********************************************
              ,SUM( CASE
                      WHEN (xmld.record_type_code = gc_rec_type_stck) THEN  -- 出庫実績
                        CASE
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--                          WHEN xicv.item_class_code = '5'             -- 品目区分が製品
---- mod start ver1.3
----                           AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                           AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
                         WHEN ((xicv.item_class_code = '5')             -- 品目区分が製品、かつ
                          AND (ir_get_data.conv_unit IS NOT NULL)       -- 入出庫換算単位がNULLでない、かつ
                          AND (ir_get_data.prod_class_code = '2')       -- 商品区分がドリンク、かつ
                          AND (ir_get_data.num_of_cases > 0)) THEN      -- ケース入数が1以上の場合
-- 2008/07/28 A.Shiina v1.6 UPDATE End
-- mod end ver1.3
-- mod start ver1.2
--                              (xmld.actual_quantity/ir_get_data.num_of_cases)
                              ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)  -- 換算する
-- mod end ver1.2
                        ELSE
                              (xmld.actual_quantity/1)  -- 換算しない
                        END
                      ELSE 0
                    END )
-- mod end ver1.1
        INTO   or_temp_tab.lot_no                            -- ロット番号
              ,or_temp_tab.product_date                      -- 製造日
              ,or_temp_tab.original_char                     -- 固有記号
              ,or_temp_tab.use_by_date                       -- 賞味期限
              ,or_temp_tab.lot_status                        -- 品質
              ,or_temp_tab.quant_r                           -- 依頼数
              ,or_temp_tab.quant_i                           -- 入庫数
              ,or_temp_tab.quant_o                           -- 出庫数
        FROM ic_lots_mst              ilm                    -- OPMロットマスタ
            ,xxinv_mov_lot_details    xmld                   -- 移動ロット詳細アドオン
            ,xxcmn_lookup_values_v    xlv                    -- クイックコード情報VIEW
-- add start ver1.1
            ,xxcmn_item_categories4_v xicv                   -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- add end ver1.1
-- mod satart ver1.1
--        WHERE xlv.lookup_type         = gc_lookup_lot_status
--        AND   ilm.attribute23         = xlv.lookup_code
--        AND   xmld.actual_date        BETWEEN gr_param.date_from
--                                      AND     NVL( gr_param.date_to, xmld.actual_date )
        WHERE xlv.lookup_type(+)      = gc_lookup_lot_status
        AND   ilm.attribute23         = xlv.lookup_code(+)
-- del start ver1.2
--        AND ((xmld.actual_date IS NULL)
--              OR
--             ((xmld.actual_date IS NOT NULL)
--               AND
--               (xmld.actual_date      BETWEEN gr_param.date_from
--                                      AND     NVL( gr_param.date_to, xmld.actual_date ))))
-- del end ver1.2
-- mod end ver1.1
        AND   xmld.document_type_code = gc_doc_type_move -- 出荷支給区分（移動）
        AND   xmld.mov_line_id        = ir_get_data.order_line_id
-- add start ver1.2
        AND   xmld.lot_id        = ir_get_data.lot_id
-- add end ver1.2
        AND   ilm.lot_id              = xmld.lot_id
        AND   ilm.item_id             = xmld.item_id
-- add start ver1.1
        AND   ilm.item_id             = xicv.item_id
-- add end ver1.1
        AND   ilm.item_id             = ir_get_data.item_id
-- mod start ver1.1
--        GROUP BY ilm.lot_no
-- mod end ver1.1
        GROUP BY xmld.lot_no
                ,ilm.attribute1
                ,ilm.attribute2
                ,ilm.attribute3
                ,xlv.meaning
        ;
--
-- 2008/07/28 A.Shiina v1.6 ADD Start
      -- 移動ロット詳細アドオンに存在しない場合
      ELSE
        or_temp_tab.lot_no        := NULL ;   -- ロット番号
        or_temp_tab.product_date  := NULL ;   -- 製造日
        or_temp_tab.use_by_date   := NULL ;   -- 賞味期限
        or_temp_tab.original_char := NULL ;   -- 固有記号
        or_temp_tab.lot_status    := NULL ;   -- 品質
--
        --***************************
        --*  依頼数
        --***************************
        -- 入出庫換算単位がNULLでない、かつ
        -- 商品区分がドリンク、かつ
        -- ケース入数が1以上の場合
        IF ((ir_get_data.conv_unit IS NOT NULL)
          AND (ir_get_data.prod_class_code = '2')
          AND (ir_get_data.num_of_cases > 0)) THEN
          or_temp_tab.quant_r := ROUND((ir_get_data.quant_r/ir_get_data.num_of_cases),3);
        ELSE
          or_temp_tab.quant_r := ir_get_data.quant_r ;
        END IF;                                         -- 依頼数
--
        --***************************
        --*  入庫数
        --***************************
        or_temp_tab.quant_i := ir_get_data.quant_i ;    -- 入庫数
--
        --***************************
        --*  出庫数
        --***************************
        or_temp_tab.quant_o := ir_get_data.quant_o ;    -- 出庫数
--
      END IF;
-- 2008/07/28 A.Shiina v1.6 ADD End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          or_temp_tab.lot_no        := NULL ;  -- ロット番号
          or_temp_tab.product_date  := NULL ;  -- 製造日
          or_temp_tab.use_by_date   := NULL ;  -- 固有記号
          or_temp_tab.original_char := NULL ;  -- 賞味期限
          or_temp_tab.lot_status    := NULL ;  -- 品質
          or_temp_tab.quant_r       := 0 ;     -- 依頼数
          or_temp_tab.quant_i       := 0 ;     -- 入庫数
          or_temp_tab.quant_o       := 0 ;     -- 出庫数
        WHEN TOO_MANY_ROWS THEN
          or_temp_tab.lot_no        := NULL ;  -- ロット番号
          or_temp_tab.product_date  := NULL ;  -- 製造日
          or_temp_tab.use_by_date   := NULL ;  -- 固有記号
          or_temp_tab.original_char := NULL ;  -- 賞味期限
          or_temp_tab.lot_status    := NULL ;  -- 品質
          or_temp_tab.quant_r       := 0 ;     -- 依頼数
          or_temp_tab.quant_i       := 0 ;     -- 入庫数
          or_temp_tab.quant_o       := 0 ;     -- 出庫数
      END ;
--
-- del start ver1.1
--    END IF ;
-- del end ver1.1
--
-- 2008/07/28 A.Shiina v1.6 ADD Start
    -- 変数初期化
    lv_reserved_status := NULL;
-- 2008/07/28 A.Shiina v1.6 ADD End
--
    --------------------------------------------------
    -- 差異事由設定
    --------------------------------------------------
    -- 保留ステータス
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
/*   BEGIN
      SELECT DISTINCT  xsli.reserved_status
      INTO   lv_reserved_status
      FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
          ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
      WHERE xshi.header_id        = xsli.header_id
      AND   xshi.delivery_no      = ir_get_data.delivery_no   -- 配送Ｎｏ
      AND   xshi.order_source_ref = ir_get_data.request_no    -- 移動Ｎｏ
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       lv_reserved_status := NULL ;
      WHEN TOO_MANY_ROWS THEN
       lv_reserved_status := NULL ;
    END ;
*/--
    -- 変数初期化
    lv_eos_data_type   := NULL;
    lv_reserved_status := NULL;
--
    -- 保留ステータス判定
    -- EOSデータ種別取得
    BEGIN
      SELECT DISTINCT
              xsli.reserved_status
             --,xshi.eos_data_type      -- 2008/10/18 変更要求#210 Del
      INTO    lv_reserved_status
             --,lv_eos_data_type        -- 2008/10/18 変更要求#210 Del
      FROM    xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
             ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
      WHERE  xshi.header_id        = xsli.header_id
      --AND    xshi.delivery_no      = ir_get_data.delivery_no   -- 配送Ｎｏ                                    2008/10/31 統合指摘#462 Del
      AND    NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- 配送Ｎｏ 2008/10/31 統合指摘#462 Add
      AND    xshi.order_source_ref = ir_get_data.request_no    -- 依頼Ｎｏ
      ;
--
      lv_eos_data_type := ir_get_data.order_type;   -- 2008/10/18 変更要求#210 Add
--
      IF ((lv_reserved_status = gc_reserved_status_y)
        AND (lv_eos_data_type = cv_eos_data_cd_220)) THEN
        ln_quant_kbn := 1;    -- 保留かつ出庫対象
      ELSIF ((lv_reserved_status = gc_reserved_status_y)
        AND (lv_eos_data_type = cv_eos_data_cd_230)) THEN
        ln_quant_kbn := 2;    -- 保留かつ入庫対象
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_eos_data_type   := NULL ;
        lv_reserved_status := NULL ;
    END ;
--
-- 2008/07/28 A.Shiina v1.6 UPDATE End
    ------------------------------
    -- 保留ステータス：「保留」
    ------------------------------
    IF ( lv_reserved_status = gc_reserved_status_y ) THEN
--
      IF ( ir_get_data.status IS NULL ) THEN -- 保留データの場合  2008/10/20 統合テスト障害#394(2) Add
--
        -- 2008/07/28 A.Shiina v1.6 UPDATE Start ---------------------------------------------
        --or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- 依頼数
        --or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- 入庫数
        --or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- 出庫数
        --or_temp_tab.quant_r       := 0 ;  -- 依頼数
        -- 出庫対象の場合
        IF (ln_quant_kbn = 1) THEN
          or_temp_tab.quant_i       := 0 ;                                              -- 入庫数
          or_temp_tab.quant_o       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- 出庫数
        -- 入庫対象の場合
        ELSIF (ln_quant_kbn = 2) THEN
          or_temp_tab.quant_i       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- 入庫数
          or_temp_tab.quant_o       := 0 ;                                              -- 出庫数
        END IF;
        -- 2008/07/28 A.Shiina v1.6 UPDATE End ------------------------------------------------
--
        -- ロット情報取得
        BEGIN
          SELECT xsli.lot_no
                ,xsli.designated_production_date
                ,xsli.use_by_date
                ,xsli.original_character
                ,NULL
          INTO   or_temp_tab.lot_no                 -- ロット番号
                ,or_temp_tab.product_date           -- 製造日
                ,or_temp_tab.use_by_date            -- 賞味期限
                ,or_temp_tab.original_char          -- 固有記号
                ,or_temp_tab.lot_status             -- 品質
          FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
              ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
          WHERE xsli.line_id          = ir_get_data.order_line_id
          AND   xshi.header_id        = xsli.header_id
          --AND   xshi.delivery_no      = ir_get_data.delivery_no   -- 配送Ｎｏ                                    2008/10/31 統合指摘#462 Del
          AND   NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- 配送Ｎｏ 2008/10/31 統合指摘#462 Add
          AND   xshi.order_source_ref = ir_get_data.request_no    -- 移動Ｎｏ
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            or_temp_tab.lot_no        := NULL ; -- ロット番号
            or_temp_tab.product_date  := NULL ; -- 製造日
            or_temp_tab.use_by_date   := NULL ; -- 賞味期限
            or_temp_tab.original_char := NULL ; -- 固有記号
            or_temp_tab.lot_status    := NULL ; -- 品質
          WHEN TOO_MANY_ROWS THEN
            or_temp_tab.lot_no        := NULL ; -- ロット番号
            or_temp_tab.product_date  := NULL ; -- 製造日
            or_temp_tab.use_by_date   := NULL ; -- 賞味期限
            or_temp_tab.original_char := NULL ; -- 固有記号
            or_temp_tab.lot_status    := NULL ; -- 品質
        END ;
--
      END IF;   -- 2008/10/20 統合テスト障害#394(2) Add
--
      or_temp_tab.reason := gc_reason_rsrv ;  -- 保留
--
    ELSE
      ------------------------------
      -- 依頼済・調整中の場合
      ------------------------------
      IF ( ir_get_data.status IN( gc_mov_status_cmp             -- 依頼済
                                 ,gc_mov_status_adj ) ) THEN    -- 調整中
        ------------------------------
        -- 指示があり実績が無い場合
        ------------------------------
        IF (   ( or_temp_tab.quant_r > 0 )
           AND ( or_temp_tab.quant_o = 0 ) ) THEN
--
          or_temp_tab.reason        := gc_reason_nrep ;     -- 未報告
--
        END IF ;
--
      ------------------------------
      -- 依頼済・調整中以外の場合
      ------------------------------
      ELSE
        ------------------------------
        -- ヘッダーレベルのチェック
        ------------------------------
        -- 指示と実績の異なるレコードを取得する
        SELECT COUNT( xmrih.mov_hdr_id )
        INTO   ln_temp_cnt
        FROM   xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
        WHERE (  xmrih.career_id             <> xmrih.actual_career_id                -- 運送業者
              OR xmrih.shipping_method_code  <> xmrih.actual_shipping_method_code     -- 配送区分
              OR xmrih.schedule_ship_date    <> xmrih.actual_ship_date                -- 出荷日
              OR xmrih.schedule_arrival_date <> xmrih.actual_arrival_date         )   -- 着荷日
        AND   xmrih.mov_num                   = or_temp_tab.request_no  -- 移動Ｎｏ
        ;
        ------------------------------
        -- 指示と実績が異なる場合
        ------------------------------
        IF ( ln_temp_cnt > 0 ) THEN
--
          -- 入庫報告有の場合
          IF ( ir_get_data.status = gc_mov_status_stc ) THEN
            or_temp_tab.reason := gc_reason_ndel ;  -- 
--
          -- 出庫報告有の場合
          ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
            or_temp_tab.reason := gc_reason_nstc ;  -- 入庫未
--
          -- 入出庫報告有の場合
          ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
            --or_temp_tab.reason := gc_reason_iodf ;  -- 出入差     2008/12/17 本番障害#764 Del
            or_temp_tab.reason := gc_reason_diff ;    -- 依頼差     2008/12/17 本番障害#764 Add
--
          END IF ;
--
        ------------------------------
        -- 指示と実績がの場合
        ------------------------------
        ELSE
          ------------------------------
          -- 入庫報告有の場合
          ------------------------------
          IF ( ir_get_data.status = gc_mov_status_stc ) THEN
-- mod start ver1.2
            -- 依頼数と入庫数が同じ場合
--            IF ( or_temp_tab.quant_r = or_temp_tab.quant_i ) THEN
--              or_temp_tab.reason        := NULL ;               -- 差異なし
--
            -- 依頼数と入庫数が異なる場合
--            ELSE
--              or_temp_tab.reason := gc_reason_ndel ;  -- 出庫未
--
--            END IF ;
            or_temp_tab.reason := gc_reason_ndel ;  -- 出庫未
-- mod end ver1.2
--
          ------------------------------
          -- 出庫報告有の場合
          ------------------------------
          ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
-- mod start ver1.2
            -- 依頼数と出庫数が同じ場合
--            IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
--              or_temp_tab.reason        := NULL ;               -- 差異なし
--
            -- 依頼数と出庫数が異なる場合
--            ELSE
--              or_temp_tab.reason := gc_reason_nstc ;  -- 入庫未
--
--            END IF ;
            or_temp_tab.reason := gc_reason_nstc ;  -- 入庫未
-- mod end ver1.2
--
          ------------------------------
          -- 入出庫報告有の場合
          ------------------------------
          ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
            ------------------------------
            -- 入庫数と出庫数が異なる場合
            ------------------------------
            IF ( or_temp_tab.quant_i <> or_temp_tab.quant_o ) THEN
              or_temp_tab.reason        := gc_reason_iodf ;     -- 出入差
--
            ------------------------------
            -- 入庫数と出庫数が同一の場合
            ------------------------------
            ELSE
              ------------------------------
              -- 依頼数と入庫数が異なる or
              -- 依頼数と出庫数が異なる場合
              ------------------------------
              IF (  ( or_temp_tab.quant_r <> or_temp_tab.quant_i )
                 OR ( or_temp_tab.quant_r <> or_temp_tab.quant_o ) ) THEN
                or_temp_tab.reason := gc_reason_diff ;  -- 依頼差
--
              ------------------------------
              -- 上記以外の場合
              ------------------------------
              ELSE
                or_temp_tab.reason        := NULL ;               -- 差異なし
--
              END IF ;
--
            END IF ;
--
          END IF ;
--
        END IF ;
--
      END IF ;
--
    END IF ;
--
  EXCEPTION
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_set_temp_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_move_data
   * Description      : 移動データ抽出処理
   ************************************************************************************************/
  PROCEDURE prc_create_move_data
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_move_data' ; -- プログラム名
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lr_get_data       rec_get_data ;        -- 抽出データ格納用レコード変数
    lr_temp_tab       rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
    lv_data_count     NUMBER DEFAULT 0 ;    -- カウント用変数
--
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    -- 指示・実績データ取得カーソル
    CURSOR cu_main
    IS
      SELECT xmrih.ship_to_locat_code     AS arvl_code            -- 入庫倉庫コード
            --,xil.description              AS arvl_name            -- 入庫倉庫名称 2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20) AS arvl_name           -- 入庫倉庫名称   2008/10/09 統合テスト障害#338 Add
-- mod start ver1.1
--            ,xil.segment1                 AS location_code        -- 出庫倉庫コード
            ,xmrih.shipped_locat_code     AS location_code        -- 出庫倉庫コード
--            ,xil.description              AS location_name        -- 出庫倉庫名称
            --,xil2.description             AS location_name        -- 出庫倉庫名称 2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil2.description,1,20) AS location_name      -- 出庫倉庫名称   2008/10/09 統合テスト障害#338 Add
-- mod end ver1.1
            ,xmrih.schedule_ship_date     AS ship_date            -- 出庫日
            ,xmrih.schedule_arrival_date  AS arvl_date            -- 入庫日
            ,xmrih.career_id              AS career_id            -- 検索条件：運送業者
            ,xmrih.shipping_method_code   AS ship_method_code     -- 検索条件：配送区分
            ,xmrih.delivery_no            AS delivery_no          -- 配送Ｎｏ
            ,xmrih.mov_num                AS request_no           -- 移動Ｎｏ
            ,xmril.mov_line_id            AS order_line_id        -- 検索条件：明細ＩＤ
            ,ximv.item_id                 AS item_id              -- 検索条件：品目ＩＤ
            ,ximv.item_no                 AS item_code            -- 品目コード
            ,ximv.item_short_name         AS item_name            -- 品目名称
            ,ximv.lot_ctl                 AS lot_ctl              -- 検索条件：ロット使用
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r        -- 依頼数（ロット管理外）
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i        -- 入庫数（ロット管理外）
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o        -- 出庫数（ロット管理外）
            ,xmrih.status                 AS status               -- ヘッダステータス
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- 入出庫換算単位
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- ケース入数
-- 2008/07/28 A.Shiina v1.6 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ロットID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- 商品区分
-- add end ver1.3
-- 2008/07/09 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class   AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code   AS complusion_output_kbn -- 強制出力区分       -- 2008/10/31 統合指摘#462 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#462 Add
-- 2008/11/17 統合指摘#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
          -- 2009/01/06 本番障害#929 del Start ------------------------------
--                AND xmld2.lot_id = xmld.lot_id
          -- 2009/01/06 本番障害#929 del End ------------------------------
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End --------------------------------------------------------
-- 2008/07/09 A.Shiina v1.5 ADD End
      FROM xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril   -- 移動依頼/指示明細アドオン
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld 
            WHERE  xmld.document_type_code = gc_doc_type_move
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld    -- 移動ロット詳細アドオン
-- add end ver1.2
          ,xxcmn_item_locations2_v        xil     -- ＯＰＭ保管場所マスタ
-- add start ver1.1
          ,xxcmn_item_locations2_v        xil2    -- ＯＰＭ保管場所マスタ2
-- add end ver1.1
          ,xxcmn_item_mst2_v              ximv    -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v       xicv    -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/09 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- 運送業者情報VIEW2
-- 2008/07/09 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．商品区分
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- パラメータ条件．品目区分
      AND   xicv.item_class_code    = gr_param.item_div
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示明細アドオン
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
---- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
---- add end ver1.2
-- 2008/07/28 A.Shiina v1.6 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．入庫先
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      AND   xil.segment1            = xmrih.ship_to_locat_code
-- mod end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/28 A.Shiina v1.6 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- パラメータ条件．ブロック１・２・３が全てNULLの場合
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- パラメータ条件．ブロック１・２・３の何れかが指定された場合
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/28 A.Shiina v1.6 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
-- mod start ver1.1
--      AND   xmrih.shipped_locat_id = xil.inventory_location_id
      AND   xil2.segment1            = xmrih.shipped_locat_code
-- mod end ver1.1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
      AND   gr_param.date_from      BETWEEN xil2.date_from
                                    AND     NVL( xil2.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示ヘッダアドオン
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- 依頼済
                                         ,gc_mov_status_adj       -- 調整中
                                         ,gc_mov_status_del       -- 出庫報告有
                                         ,gc_mov_status_stc       -- 入庫報告有
                                         ,gc_mov_status_dsr )     -- 入出庫報告有
      AND   xmrih.mov_type              = gc_mov_type_y           -- 積送あり
      -- パラメータ条件．指示部署
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- パラメータ条件．移動Ｎｏ
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
      -- パラメータ条件．出庫日FromTo
-- mod start ver1.1
--      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
--                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
      AND   xmrih.ship_to_locat_code    = NVL( gr_param.ship_to_locat_code, xmrih.ship_to_locat_code )
      AND   xmrih.schedule_arrival_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.schedule_arrival_date )
-- mod end ver1.1
--
      -- 2008/10/31 統合指摘#462 Del Start -------------------------------------
      -- 2008/07/09 A.Shiina v1.5 ADD Start -----------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/09 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#462 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#462 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num)  =   xcv.party_id(+)
      AND   xmrih.schedule_arrival_date    >=   xcv.start_date_active(+)
      AND   xmrih.schedule_arrival_date    <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#462 Add End ---------------------------------------
--
      UNION
      SELECT xmrih.ship_to_locat_code           AS arvl_code            -- 入庫倉庫コード
            --,xil.description                    AS arvl_name            -- 入庫倉庫名称 2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)      AS arvl_name            -- 入庫倉庫名称   2008/10/09 統合テスト障害#338 Add
-- mod start ver1.1
--            ,xil.segment1                       AS location_code        -- 出庫倉庫コード
            ,xmrih.shipped_locat_code           AS location_code        -- 出庫倉庫コード
--            ,xil.description              AS location_name        -- 出庫倉庫名称
            --,xil2.description             AS location_name        -- 出庫倉庫名称     2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil2.description,1,20)     AS location_name        -- 出庫倉庫名称 2008/10/09 統合テスト障害#338 Add
-- mod end ver1.1
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date            -- 出庫日
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date            -- 入庫日
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id            -- 検索条件：運送業者
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code     -- 検索条件：配送区分
            ,xmrih.delivery_no                  AS delivery_no          -- 配送Ｎｏ
            ,xmrih.mov_num                      AS request_no           -- 移動Ｎｏ
            ,xmril.mov_line_id                  AS order_line_id        -- 検索条件：明細ＩＤ
            ,ximv.item_id                       AS item_id              -- 検索条件：品目ＩＤ
            ,ximv.item_no                       AS item_code            -- 品目コード
            ,ximv.item_short_name               AS item_name            -- 品目名称
            ,ximv.lot_ctl                       AS lot_ctl              -- 検索条件：ロット使用
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r              -- 依頼数（ロット管理外）
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i              -- 入庫数（ロット管理外）
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o              -- 出庫数（ロット管理外）
            ,xmrih.status                       AS status               -- ヘッダステータス
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- 入出庫換算単位
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- ケース入数
-- 2008/07/28 A.Shiina v1.6 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ロットID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- 商品区分
-- add end ver1.3
-- 2008/07/09 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code    AS complusion_output_kbn -- 強制出力区分      -- 2008/10/31 統合指摘#462 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#462 Add
-- 2008/11/17 統合指摘#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
          -- 2009/01/06 本番障害#929 del Start ------------------------------
--                AND xmld2.lot_id = xmld.lot_id
          -- 2009/01/06 本番障害#929 del End ------------------------------
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End --------------------------------------------------------
-- 2008/07/09 A.Shiina v1.5 ADD End
      FROM xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril   -- 移動依頼/指示明細アドオン
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld 
            WHERE  xmld.document_type_code = gc_doc_type_move
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld    -- 移動ロット詳細アドオン
-- add end ver1.2
          ,xxcmn_item_locations2_v        xil-- ＯＰＭ保管場所マスタ
-- add start ver1.1
          ,xxcmn_item_locations2_v        xil2    -- ＯＰＭ保管場所マスタ2
-- add end ver1.1
          ,xxcmn_item_mst2_v              ximv    -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v       xicv    -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/09 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- 運送業者情報VIEW2
-- 2008/07/09 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．商品区分
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- パラメータ条件．品目区分
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id            = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xmril.item_id           = ximv.item_id
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示明細アドオン
      ----------------------------------------------------------------------------------------------
      AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
      AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
---- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
---- add end ver1.2
-- 2008/07/28 A.Shiina v1.6 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．入庫先
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      AND   xil.segment1            = xmrih.ship_to_locat_code
-- mod end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/28 A.Shiina v1.6 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- パラメータ条件．ブロック１・２・３が全てNULLの場合
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- パラメータ条件．ブロック１・２・３の何れかが指定された場合
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/28 A.Shiina v1.6 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
-- mod start ver1.1
--      AND   xmrih.shipped_locat_id = xil.inventory_location_id
      AND   xil2.segment1          = xmrih.shipped_locat_code
-- mod end ver1.1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
      AND   gr_param.date_from      BETWEEN xil2.date_from
                                    AND     NVL( xil2.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- 移動依頼指示ヘッダアドオン
      ----------------------------------------------------------------------------------------------
      AND   xmrih.status              IN( gc_mov_status_cmp       -- 依頼済
                                         ,gc_mov_status_adj       -- 調整中
                                         ,gc_mov_status_del       -- 出庫報告有
                                         ,gc_mov_status_stc       -- 入庫報告有
                                         ,gc_mov_status_dsr )     -- 入出庫報告有
      AND   xmrih.mov_type              = gc_mov_type_y
      -- パラメータ条件．指示部署
      AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )
      -- パラメータ条件．移動Ｎｏ
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
      -- パラメータ条件．出庫日FromTo
-- mod start ver1.1
--      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
--                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
      AND   xmrih.ship_to_locat_code    = NVL( gr_param.ship_to_locat_code, xmrih.ship_to_locat_code )
      AND   NVL( xmrih.actual_arrival_date,xmrih.schedule_arrival_date ) BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, NVL( xmrih.actual_arrival_date,xmrih.schedule_arrival_date ) )
-- mod end ver1.1
--
      -- 2008/10/31 統合指摘#462 Del Start -------------------------------------
      -- 2008/07/09 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/09 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#462 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#462 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num) =   xcv.party_id(+)
      AND   xmrih.actual_ship_date     >=   xcv.start_date_active(+)
      AND   xmrih.actual_ship_date     <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#462 Add End ---------------------------------------
--
    ;
    -- 保留データ取得
    CURSOR cu_reserv
    IS
-- mod start ver1.1
--      SELECT xshi.party_site_code             AS arvl_code        -- 入庫倉庫コード
      SELECT xshi.ship_to_location            AS arvl_code        -- 入庫倉庫コード
-- mod end ver1.1
            --,xil.description                  AS arvl_name        -- 入庫倉庫名称 2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)    AS arvl_name        -- 入庫倉庫名称   2008/10/09 統合テスト障害#338 Add
-- mod start ver1.1
--            ,xil.segment1                     AS location_code    -- 出庫倉庫コード
            ,xshi.location_code               AS location_code    -- 出庫倉庫コード
--            ,xil.description                  AS location_name    -- 出庫倉庫名称 
            --,xil2.description                 AS location_name    -- 出庫倉庫名称 2008/10/09 統合テスト障害#338 Del
            ,SUBSTRB(xil2.description,1,20)   AS location_name    -- 出庫倉庫名称   2008/10/09 統合テスト障害#338 Add
-- mod end ver1.1
            ,xshi.shipped_date                AS ship_date        -- 出庫日
            ,xshi.arrival_date                AS arvl_date        -- 入庫日
            ,xshi.freight_carrier_code        AS career_id        -- 検索条件：運送業者
            ,xshi.shipping_method_code        AS ship_method_code -- 検索条件：配送区分
            ,xshi.eos_data_type               AS order_type       -- 業務種別（コード）   2008/10/18 変更要求#210 Add
            ,xshi.delivery_no                 AS delivery_no      -- 配送Ｎｏ
            ,xshi.order_source_ref            AS request_no       -- 移動Ｎｏ
            ,xsli.line_id                     AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                     AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                     AS item_code        -- 品目コード
            ,ximv.item_short_name             AS item_name        -- 品目名称
            ,ximv.lot_ctl                     AS lot_ctl          -- 検索条件：ロット使用
            ,xsli.orderd_quantity             AS quant_r          -- 依頼数
            ,xsli.ship_to_quantity            AS quant_i          -- 入庫数
            ,xsli.shiped_quantity             AS quant_o          -- 出庫数
-- 2008/07/28 A.Shiina v1.6 ADD Start
            ,xsli.detailed_quantity           AS quant_d          -- 内訳数量(インタフェース用)
-- 2008/07/28 A.Shiina v1.6 ADD End
            ,NULL                             AS status           -- ヘッダステータス
-- 2008/07/09 A.Shiina v1.5 ADD Start
            ,xshi.filler14                    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code       AS complusion_output_kbn -- 強制出力区分   -- 2008/10/31 統合指摘#462 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#462 Add
-- 2008/07/09 A.Shiina v1.5 ADD End
      FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
          ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
          ,xxcmn_item_locations2_v    xil       -- ＯＰＭ保管場所マスタ
-- add start ver1.1
          ,xxcmn_item_locations2_v    xil2      -- ＯＰＭ保管場所マスタ2
-- add end ver1.1
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/09 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
-- 2008/07/09 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．商品区分
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- パラメータ条件．品目区分
      AND   xicv.item_class_code    = NVL( gr_param.item_div, xicv.prod_class_code )
      AND   ximv.item_id                = xicv.item_id
      AND   gr_param.date_from      BETWEEN ximv.start_date_active
                                    AND     NVL( ximv.end_date_active, gr_param.date_from )
      AND   xsli.orderd_item_code       = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- ＩＦ明細
      ----------------------------------------------------------------------------------------------
      AND   xsli.reserved_status  = gc_reserved_status_y        -- 保留ステータス = 保留
      AND   xshi.header_id        = xsli.header_id
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．入庫先
-- mod start ver1.1
--      AND   xil.segment1          = NVL( gr_param.ship_to_locat_code, xil.segment1 )
      AND   xil.segment1          = xshi.ship_to_location
-- mod end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/28 A.Shiina v1.6 ADD Start
--      AND   (  gr_param.block_01      IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02      IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03      IS NULL
--            OR xil.distribution_block = gr_param.block_03 )
      AND   (
              -- パラメータ条件．ブロック１・２・３が全てNULLの場合
              (
                (gr_param.block_01 IS NULL)
                  AND  (gr_param.block_02 IS NULL)
                    AND  (gr_param.block_03 IS NULL)
              )
              OR
              -- パラメータ条件．ブロック１・２・３の何れかが指定された場合
              (xil.distribution_block IN (gr_param.block_01,
                                          gr_param.block_02,
                                          gr_param.block_03)
              )
            )
-- 2008/07/28 A.Shiina v1.6 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
-- mod start ver1.1
--      AND   xshi.location_code    = xil.segment1
      AND   xil2.segment1    = NVL(xshi.location_code,xil2.segment1)
-- mod end ver1.1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
      AND   gr_param.date_from      BETWEEN xil2.date_from
                                    AND     NVL( xil2.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- ＩＦヘッダ
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_move_o      -- 移動出庫確定報告
                                   ,gc_eos_type_rpt_move_i )    -- 移動入庫確定報告
      -- パラメータ条件．移動Ｎｏ
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
-- add start ver1.1
      -- パラメータ条件．入庫先
-- 2008/07/09 A.Shiina v1.5 ADD Start
--      AND   xshi.ship_to_location = NVL( gr_param.ship_to_locat_code, xshi.party_site_code )
      AND   xshi.ship_to_location = NVL( gr_param.ship_to_locat_code, xshi.ship_to_location )
-- 2008/07/09 A.Shiina v1.5 ADD End
      -- パラメータ条件．指示部署
      AND   xshi.report_post_code = NVL( gr_param.dept_code, xshi.report_post_code )
-- add end ver1.1

      -- 2008/10/31 統合指摘#462 Del Start -------------------------------------
      ---- パラメータ条件．出庫日FromTo
      --AND   xshi.shipped_date     BETWEEN gr_param.date_from
      --                            AND     NVL( gr_param.date_to, xshi.shipped_date )
      -- 2008/10/31 統合指摘#462 Del End ---------------------------------------
      -- 2008/10/31 統合指摘#462 Add Start -------------------------------------
      -- パラメータ条件．入庫日FromTo
      AND   xshi.arrival_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.arrival_date )
      -- 2008/10/31 統合指摘#462 Add End ---------------------------------------
--
      -- 2008/10/31 統合指摘#462 Del Start -------------------------------------
      -- 2008/07/09 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xshi.freight_carrier_code         =   xcv.party_number
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xshi.shipped_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xshi.shipped_date))
      -- 2008/07/09 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#462 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#462 Add Start -------------------------------------
      AND   NVL(xshi.freight_carrier_code,gv_nvl_null_char) =   xcv.party_number(+)
      AND   xshi.arrival_date          >=   xcv.start_date_active(+)
      AND   xshi.arrival_date          <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#462 Add End ---------------------------------------
--
    ;
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN

--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 指示実績データ抽出・登録処理
    -- ====================================================
    -- 出力区分が「保留」以外の場合
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type <> gc_output_type_rsrv ) ) THEN
     <<main_loop>>
      FOR re_main IN cu_main LOOP
       lv_data_count := lv_data_count + 1;
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.arvl_code        := re_main.arvl_code;          -- 入庫倉庫コード
        lr_get_data.arvl_name        := re_main.arvl_name;          -- 入庫倉庫名称
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- 2008/07/09 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/09 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 移動Ｎｏ
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- 検索条件：明細ＩＤ
        lr_get_data.item_id          := re_main.item_id ;           -- 検索条件：品目ＩＤ
        lr_get_data.item_code        := re_main.item_code ;         -- 品目コード
        lr_get_data.item_name        := re_main.item_name ;         -- 品目名称
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- 検索条件：ロット使用
        lr_get_data.quant_r          := re_main.quant_r ;           -- 依頼数（ロット管理外）
        lr_get_data.quant_i          := re_main.quant_i ;           -- 入庫数（ロット管理外）
        lr_get_data.quant_o          := re_main.quant_o ;           -- 出庫数（ロット管理外）
        lr_get_data.status           := re_main.status ;            -- 受注ヘッダステータス
-- add start ver1.1
        lr_get_data.conv_unit        := re_main.conv_unit ;         -- 入出庫換算単位
        lr_get_data.num_of_cases     := re_main.num_of_cases ;      -- ケース入数
-- add end ver1.1
-- add start ver1.2
        lr_get_data.lot_id           := re_main.lot_id ;            -- ロットID
-- add end ver1.2
-- add start ver1.3
        lr_get_data.prod_class_code  := re_main.prod_class_code ;   -- 商品区分
-- add end ver1.3
-- 2008/11/17 統合指摘#651 Add Start ---------------------------------------
        lr_get_data.no_instr_actual  := re_main.no_instr_actual ;
        lr_get_data.lot_inst_cnt     := re_main.lot_inst_cnt ;
        lr_get_data.row_num          := re_main.row_num ;
-- 2008/11/17 統合指摘#651 Add End -----------------------------------------
--
        --------------------------------------------------
        -- 中間テーブル登録データ設定
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE check_move_data_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブルデータ格納用
        --------------------------------------------------
        gt_arvl_code_tbl(lv_data_count)          := lr_temp_tab.arvl_code;        -- 入庫倉庫コード
        gt_arvl_name_tbl(lv_data_count)          := lr_temp_tab.arvl_name;        -- 入庫倉庫名称
        gt_location_code_tbl(lv_data_count)      := lr_temp_tab.location_code;    -- 出庫倉庫コード
        gt_location_name_tbl(lv_data_count)      := lr_temp_tab.location_name;    -- 出庫倉庫名称
        gt_ship_date_tbl(lv_data_count)          := lr_temp_tab.ship_date;        -- 出庫日
        gt_arvl_date_tbl(lv_data_count)          := lr_temp_tab.arvl_date;        -- 入庫日
        gt_career_code_tbl(lv_data_count)        := lr_temp_tab.career_code;      -- 運送業者コード
        gt_career_name_tbl(lv_data_count)        := lr_temp_tab.career_name;      -- 運送業者名称
        gt_ship_method_code_tbl(lv_data_count)   := lr_temp_tab.ship_method_code; -- 配送区分コード
        gt_ship_method_name_tbl(lv_data_count)   := lr_temp_tab.ship_method_name; -- 配送区分名称
        gt_delivery_no_tbl(lv_data_count)        := lr_temp_tab.delivery_no;      -- 配送Ｎｏ
        gt_request_no_tbl(lv_data_count)         := lr_temp_tab.request_no;       -- 移動Ｎｏ
        gt_item_code_tbl(lv_data_count)          := lr_temp_tab.item_code;        -- 品目コード
        gt_item_name_tbl(lv_data_count)          := lr_temp_tab.item_name;        -- 品目名称
        gt_lot_ctl_tbl(lv_data_count)            := lr_temp_tab.lot_no;           -- ロット番号
        gt_product_date_tbl(lv_data_count)       := lr_temp_tab.product_date;     -- 製造日
        gt_use_by_date_tbl(lv_data_count)        := lr_temp_tab.use_by_date;      -- 賞味期限
        gt_original_char_tbl(lv_data_count)      := lr_temp_tab.original_char;    -- 固有記号
        gt_meaning_tbl(lv_data_count)            := lr_temp_tab.lot_status;       -- 品質
        gt_quant_r_tbl(lv_data_count)            := lr_temp_tab.quant_r;          -- 依頼数
        gt_quant_i_tbl(lv_data_count)            := lr_temp_tab.quant_i;          -- 入庫数
        gt_quant_o_tbl(lv_data_count)            := lr_temp_tab.quant_o;          -- 出庫数
        gt_reason_tbl(lv_data_count)             := lr_temp_tab.reason;           -- 差異事由
        gt_inst_rslt_div_tbl(lv_data_count)      := lr_temp_tab.inst_rslt_div;    -- 指示実績区分  2008/10/20 統合テスト障害#394(1) Add
--
      END LOOP main_loop ;
      --------------------------------------------------
      -- 中間テーブル登録
      --------------------------------------------------
      prc_ins_temp_data
        (
          ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE check_move_data_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 保留データ抽出・登録処理
    -- ====================================================
    -- 出力区分が「保留」の場合
    IF (  ( gr_param.output_type IS NULL )
       OR ( gr_param.output_type = gc_output_type_rsrv ) ) THEN
     <<reserv_loop>>
      FOR re_main IN cu_reserv LOOP
        -- カウント
        lv_data_count := lv_data_count + 1;
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.arvl_code        := re_main.arvl_code;          -- 入庫倉庫コード
        lr_get_data.arvl_name        := re_main.arvl_name;          -- 入庫倉庫名称
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- 2008/07/09 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/09 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.order_type       := re_main.order_type ;        -- 業務種別（コード）    2008/10/18 変更要求#210 Add
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 移動Ｎｏ
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- 検索条件：明細ＩＤ
        lr_get_data.item_id          := re_main.item_id ;           -- 検索条件：品目ＩＤ
        lr_get_data.item_code        := re_main.item_code ;         -- 品目コード
        lr_get_data.item_name        := re_main.item_name ;         -- 品目名称
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- 検索条件：ロット使用
        lr_get_data.quant_r          := re_main.quant_r ;           -- 依頼数（ロット管理外）
        lr_get_data.quant_i          := re_main.quant_i ;           -- 入庫数（ロット管理外）
        lr_get_data.quant_o          := re_main.quant_o ;           -- 出庫数（ロット管理外）
-- 2008/07/28 A.Shiina v1.6 UPDATE Start
        lr_get_data.quant_d          := re_main.quant_d  ;          -- 内訳数量(インタフェース用)
-- 2008/07/28 A.Shiina v1.6 UPDATE End
        lr_get_data.status           := re_main.status ;            -- ヘッダステータス
--
       --------------------------------------------------
        -- 中間テーブル登録データ設定
        --------------------------------------------------
        prc_set_temp_data
          (
            ir_get_data   => lr_get_data
           ,or_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE check_move_data_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブルデータ格納用
        --------------------------------------------------
        gt_arvl_code_tbl(lv_data_count)          := lr_temp_tab.arvl_code;        -- 入庫倉庫コード
        gt_arvl_name_tbl(lv_data_count)          := lr_temp_tab.arvl_name;        -- 入庫倉庫名称
        --gt_location_code_tbl(lv_data_count)      := lr_temp_tab.arvl_name;        -- 出庫倉庫コード 2008/10/09 統合テスト障害#338 Del
        gt_location_code_tbl(lv_data_count)      := lr_temp_tab.location_code;    -- 出庫倉庫コード   2008/10/09 統合テスト障害#338 Add
        gt_location_name_tbl(lv_data_count)      := lr_temp_tab.location_name;    -- 出庫倉庫名称
        gt_ship_date_tbl(lv_data_count)          := lr_temp_tab.ship_date;        -- 出庫日
        gt_arvl_date_tbl(lv_data_count)          := lr_temp_tab.arvl_date;        -- 入庫日
        gt_career_code_tbl(lv_data_count)        := lr_temp_tab.career_code;      -- 運送業者コード
        gt_career_name_tbl(lv_data_count)        := lr_temp_tab.career_name;      -- 運送業者名称
        gt_ship_method_code_tbl(lv_data_count)   := lr_temp_tab.ship_method_code; -- 配送区分コード
        gt_ship_method_name_tbl(lv_data_count)   := lr_temp_tab.ship_method_name; -- 配送区分名称
        gt_delivery_no_tbl(lv_data_count)        := lr_temp_tab.delivery_no;      -- 配送Ｎｏ
        gt_request_no_tbl(lv_data_count)         := lr_temp_tab.request_no;       -- 移動Ｎｏ
        gt_item_code_tbl(lv_data_count)          := lr_temp_tab.item_code;        -- 品目コード
        gt_item_name_tbl(lv_data_count)          := lr_temp_tab.item_name;        -- 品目名称
        gt_lot_ctl_tbl(lv_data_count)            := lr_temp_tab.lot_no;           -- ロット番号
        gt_product_date_tbl(lv_data_count)       := lr_temp_tab.product_date;     -- 製造日
        gt_use_by_date_tbl(lv_data_count)        := lr_temp_tab.use_by_date;      -- 賞味期限
        gt_original_char_tbl(lv_data_count)      := lr_temp_tab.original_char;    -- 固有記号
        gt_meaning_tbl(lv_data_count)            := lr_temp_tab.lot_status;       -- 品質
        gt_quant_r_tbl(lv_data_count)            := lr_temp_tab.quant_r;          -- 依頼数
        gt_quant_i_tbl(lv_data_count)            := lr_temp_tab.quant_i;          -- 入庫数
        gt_quant_o_tbl(lv_data_count)            := lr_temp_tab.quant_o;          -- 出庫数
        gt_reason_tbl(lv_data_count)             := lr_temp_tab.reason;           -- 差異事由
        gt_inst_rslt_div_tbl(lv_data_count)      := lr_temp_tab.inst_rslt_div;    -- 指示実績区分   2008/10/20 統合テスト障害#394(1) Add
      END LOOP main_loop ;
--
      --------------------------------------------------
      -- 中間テーブル登録
      --------------------------------------------------
      prc_ins_temp_data
        (
          ov_errbuf     => lv_errbuf
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE check_move_data_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
    -- 移動データ抽出処理の例外
    WHEN check_move_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_move_data ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ編集
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 移動データ抽出処理
    -- ====================================================
    prc_create_move_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- ＸＭＬデータ出力処理
    -- ====================================================
    prc_create_out_data
      (
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE check_create_xml_expt ;
    END IF ;
--
    -- ====================================================
    -- アウトパラメータセット
    -- ====================================================
    ov_errbuf  := lv_errbuf ;     --    エラー・メッセージ           --# 固定 #
    ov_retcode := lv_retcode ;    --    リターン・コード             --# 固定 #
    ov_errmsg  := lv_errmsg ;     --    ユーザー・エラー・メッセージ --# 固定 #
--
  EXCEPTION
    -- ＸＭＬデータ編集の例外
    WHEN check_create_xml_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--##### 固定例外処理部 START #######################################################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### 固定例外処理部 END   #######################################################################
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_prod_div             IN     VARCHAR2         -- 01 : 商品区分
     ,iv_item_div             IN     VARCHAR2         -- 02 : 品目区分
     ,iv_date_from            IN     VARCHAR2         -- 03 : 着日From
     ,iv_date_to              IN     VARCHAR2         -- 04 : 着日To
     ,iv_dept_code            IN     VARCHAR2         -- 05 : 部署
     ,iv_output_type          IN     VARCHAR2         -- 06 : 出力区分
     ,iv_block_01             IN     VARCHAR2         -- 07 : ブロック１
     ,iv_block_02             IN     VARCHAR2         -- 08 : ブロック２
     ,iv_block_03             IN     VARCHAR2         -- 09 : ブロック３
     ,iv_ship_to_locat_code   IN     VARCHAR2         -- 10 : 入庫先
     ,iv_online_type          IN     VARCHAR2         -- 11 : オンライン対象区分
     ,iv_request_no           IN     VARCHAR2         -- 12 : 移動No
     ,ov_errbuf              OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1) ;                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000) ;                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- -----------------------------------------------------
    -- パラメータ格納
    -- -----------------------------------------------------
    gr_param.prod_div           := iv_prod_div ;                                          -- 商品区分
    gr_param.item_div           := iv_item_div ;                                          -- 品目区分
    gr_param.date_from          := FND_DATE.CANONICAL_TO_DATE( iv_date_from ) ;           -- 着日From
    gr_param.date_to            := FND_DATE.CANONICAL_TO_DATE( iv_date_to   ) ;           -- 着日To
    gr_param.dept_code          := iv_dept_code ;                                         -- 部署
    gr_param.output_type        := iv_output_type ;                                       -- 出力区分
    gr_param.block_01           := iv_block_01 ;                                          -- ブロック１
    gr_param.block_02           := iv_block_02 ;                                          -- ブロック２
    gr_param.block_03           := iv_block_03 ;                                          -- ブロック３
    gr_param.ship_to_locat_code := iv_ship_to_locat_code ;                                -- 入庫先
    gr_param.online_type        := iv_online_type ;                                       -- オンライン対象区分
    gr_param.request_no         := iv_request_no ;                                        -- 移動No
    -- -----------------------------------------------------
    -- ログイン情報退避（ＷＨＯカラム用）
    -- -----------------------------------------------------
    gn_created_by             := FND_GLOBAL.USER_ID ;           -- 作成者
    gn_last_updated_by        := FND_GLOBAL.USER_ID ;           -- 最終更新者
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID ;          -- 最終更新ログイン
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID ;   -- 要求ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID ;      -- ＣＰ・アプリケーションID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID ;   -- コンカレント・プログラムID
--
    -- =====================================================
    -- ログインユーザー情報出力
    -- =====================================================
    prc_create_xml_data_user
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ＸＭＬファイルデータ編集
    -- =====================================================
    -- --------------------------------------------------
    -- リストグループ開始タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- ＸＭＬデータ編集処理を呼び出す。
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- リストグループ終了タグ
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- 帳票出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- ０件メッセージの取得
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- メッセージの設定
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_lctn>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_lctn_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- ＸＭＬ出力
      -- --------------------------------------------------
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
        -- 編集したデータをタグに変換
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
    -- ==================================================
    -- 中間テーブルロールバック
    -- ==================================================
    ROLLBACK ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
      -- ==================================================
      -- 中間テーブルロールバック
      -- ==================================================
      ROLLBACK ;
--
--####################################  固定部 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf                 OUT    VARCHAR2         -- エラーメッセージ
     ,retcode                OUT    VARCHAR2         -- エラーコード
     ,iv_prod_div            IN     VARCHAR2         -- 01 : 商品区分
     ,iv_item_div            IN     VARCHAR2         -- 02 : 品目区分
     ,iv_date_from           IN     VARCHAR2         -- 03 : 着日From
     ,iv_date_to             IN     VARCHAR2         -- 04 : 着日To
     ,iv_dept_code           IN     VARCHAR2         -- 05 : 部署
     ,iv_output_type         IN     VARCHAR2         -- 06 : 出力区分
     ,iv_block_01            IN     VARCHAR2         -- 07 : ブロック１
     ,iv_block_02            IN     VARCHAR2         -- 08 : ブロック２
     ,iv_block_03            IN     VARCHAR2         -- 09 : ブロック３
     ,iv_ship_to_locat_code  IN     VARCHAR2         -- 10 : 入庫先
     ,iv_online_type         IN     VARCHAR2         -- 11 : オンライン対象区分
     ,iv_request_no          IN     VARCHAR2         -- 12 : 移動No
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ;  -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1) ;         --   リターン・コード
    lv_errmsg               VARCHAR2(5000) ;      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain
      (
        iv_prod_div           => iv_prod_div                         -- 01 : 商品区分
       ,iv_item_div           => iv_item_div                         -- 02 : 品目区分
       ,iv_date_from          => iv_date_from                        -- 03 : 着日From
       ,iv_date_to            => NVL(iv_date_to , gc_max_date_char)  -- 04 : 着日To
       ,iv_dept_code          => iv_dept_code                        -- 05 : 部署
       ,iv_output_type        => iv_output_type                      -- 06 : 出力区分
       ,iv_block_01           => iv_block_01                         -- 07 : ブロック１
       ,iv_block_02           => iv_block_02                         -- 08 : ブロック２
       ,iv_block_03           => iv_block_03                         -- 09 : ブロック３
       ,iv_ship_to_locat_code => iv_ship_to_locat_code               -- 10 : 入庫先
       ,iv_online_type        => iv_online_type                      -- 11 : オンライン対象区分
       ,iv_request_no         => iv_request_no                       -- 12 : 移動No
       ,ov_errbuf             => lv_errbuf                           -- エラー・メッセージ
       ,ov_retcode            => lv_retcode                          -- リターン・コード
       ,ov_errmsg             => lv_errmsg                           -- ユーザー・エラー・メッセージ
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxwsh930004c ;
/
