CREATE OR REPLACE PACKAGE BODY xxwsh930003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930003C(body)
 * Description      : 入出庫情報差異リスト（出庫基準）
 * MD.050/070       : 生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD050_BPO_930)
 *                    生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD070_BPO_93C)
 * Version          : 1.14
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_out_data         PROCEDURE : ＸＭＬデータ出力処理
 *  prc_ins_temp_data           PROCEDURE : 中間テーブル登録
 *  prc_set_temp_data           PROCEDURE : 中間テーブル登録データ設定
 *  prc_create_ship_data        PROCEDURE : 出荷・支給データ抽出処理
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
 *  2008/02/19    1.0   Masayuki Ikeda   新規作成
 *  2008/06/23    1.1   Oohashi  Takao   不具合ログ対応
 *  2008/06/25    1.2   Oohashi  Takao   不具合ログ対応
 *  2008/06/30    1.3   Oohashi  Takao   不具合ログ対応
 *  2008/07/02    1.4   Kawano   Yuko    ST不具合対応#352
 *  2008/07/07    1.5   Akiyoshi Shiina  変更要求対応#92
 *  2008/07/08    1.5   Satoshi  Yunba   禁則文字対応
 *  2008/07/24    1.6   Akiyoshi Shiina  ST不具合#197、内部課題#32、内部変更要求#180対応
 *  2008/10/10    1.7   Naoki    Fukuda  統合テスト障害#338対応
 *  2008/10/17    1.8   Naoki    Fukuda  統合テスト障害#146対応
 *  2008/10/17    1.8   Naoki    Fukuda  課題T_S_458対応(部署を任意入力パラメータに変更。PACKAGEの修正はなし)
 *  2008/10/17    1.8   Naoki    Fukuda  変更要求#210対応
 *  2008/10/20    1.9   Naoki    Fukuda  課題T_S_486対応
 *  2008/10/20    1.9   Naoki    Fukuda  統合テスト障害#394(1)対応
 *  2008/10/20    1.9   Naoki    Fukuda  統合テスト障害#394(2)対応
 *  2008/10/31    1.10  Naoki    Fukuda  統合指摘#461対応
 *  2008/11/13    1.11  Naoki    Fukuda  統合指摘#603対応
 *  2008/11/17    1.12  Naoki    Fukuda  統合指摘#651対応(課題T_S_486再対応)
 *  2008/12/03    1.13  Naoki    Fukuda  本番障害#333対応
 *  2008/12/06    1.14  Miyata           本番障害#516対応
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXWSH930003C' ;     -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXWSH930003T' ;     -- 帳票ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- データ０件メッセージ
--
  ------------------------------
  -- 参照タイプ
  ------------------------------
  -- 出荷業務種別
  gc_lookup_biz_type          CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_BIZ_TYPE' ;
  -- 入出庫情報差異リスト出力区分
  gc_lookup_output_type       CONSTANT VARCHAR2(100) := 'XXWSH_930CD_LIST_OUTPUT_CLASS' ;
  -- 出荷支給区分
  gc_lookup_ship_prov_class   CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_SHIKYU_CLASS' ;
  -- 配送区分
  gc_lookup_ship_method_code  CONSTANT VARCHAR2(100) := 'XXCMN_SHIP_METHOD' ;
  -- 移動ロット詳細アドオン：文書タイプ
  gc_lookup_doc_type          CONSTANT VARCHAR2(100) := 'XXINV_DOCUMENT_TYPE' ;
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_lookup_rec_type          CONSTANT VARCHAR2(100) := 'XXINV_RECORD_TYPE' ;
  -- ロットステータス
  gc_lookup_lot_status        CONSTANT VARCHAR2(100) := 'XXCMN_LOT_STATUS' ;
--
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 品目区分
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- 原料
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- 資材
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- 半製品
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- 製品
  -- 出荷業務種別
  gc_business_type_s      CONSTANT VARCHAR2(1)  := '1' ;  -- 出荷
  gc_business_type_p      CONSTANT VARCHAR2(1)  := '2' ;  -- 支給
  gc_business_type_m      CONSTANT VARCHAR2(1)  := '3' ;  -- 移動
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
  -- ステータス
  gc_req_status_s_inp     CONSTANT VARCHAR2(2)  := '01' ;   -- 入力中
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2)  := '02' ;   -- 拠点確定
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2)  := '03' ;   -- 締め済み
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '04' ;   -- 出荷実績計上済
  gc_req_status_p_inp     CONSTANT VARCHAR2(2)  := '05' ;   -- 入力中
  gc_req_status_p_cmpa    CONSTANT VARCHAR2(2)  := '06' ;   -- 入力完了
  gc_req_status_p_cmpb    CONSTANT VARCHAR2(2)  := '07' ;   -- 受領済
  gc_req_status_p_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- 出荷実績計上済
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- 移動タイプ
  gc_mov_type_y           CONSTANT VARCHAR2(1)  := '1' ;    -- 積送あり
  gc_mov_type_n           CONSTANT VARCHAR2(1)  := '2' ;    -- 積送なし
  -- 移動ステータス
  gc_mov_status_req       CONSTANT VARCHAR2(2)  := '01' ;   -- 依頼中
  gc_mov_status_cmp       CONSTANT VARCHAR2(2)  := '02' ;   -- 依頼済
  gc_mov_status_adj       CONSTANT VARCHAR2(2)  := '03' ;   -- 調整中
  gc_mov_status_del       CONSTANT VARCHAR2(2)  := '04' ;   -- 出庫報告有
  gc_mov_status_stc       CONSTANT VARCHAR2(2)  := '05' ;   -- 入庫報告有
  gc_mov_status_dsr       CONSTANT VARCHAR2(2)  := '06' ;   -- 入出庫報告有
  gc_mov_status_ccl       CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- EOSデータタイプ
  gc_eos_type_req_ship_k  CONSTANT VARCHAR2(3)  := '110' ;  -- 拠点・配送先出荷依頼
  gc_eos_type_req_move_o  CONSTANT VARCHAR2(3)  := '120' ;  -- 移動出庫依頼
  gc_eos_type_req_move_i  CONSTANT VARCHAR2(3)  := '130' ;  -- 移動入庫依頼
  gc_eos_type_req_dliv_k  CONSTANT VARCHAR2(3)  := '140' ;  -- 拠点・配送先配送依頼
  gc_eos_type_req_dliv_o  CONSTANT VARCHAR2(3)  := '150' ;  -- 移動出庫配送依頼
  gc_eos_type_rpt_ship_y  CONSTANT VARCHAR2(3)  := '200' ;  -- 有償出荷報告
  gc_eos_type_rpt_ship_k  CONSTANT VARCHAR2(3)  := '210' ;  -- 拠点出荷確定報告
  gc_eos_type_rpt_ship_n  CONSTANT VARCHAR2(3)  := '215' ;  -- 庭先出荷確定報告
  gc_eos_type_rpt_move_o  CONSTANT VARCHAR2(3)  := '220' ;  -- 移動出庫確定報告
  gc_eos_type_rpt_move_i  CONSTANT VARCHAR2(3)  := '230' ;  -- 移動入庫確定報告
  gc_eos_type_claim_fare  CONSTANT VARCHAR2(3)  := '300' ;  -- 運賃請求
  gc_eos_type_rpt_invent  CONSTANT VARCHAR2(3)  := '400' ;  -- 棚卸確定報告
  gc_eos_type_mnt_master  CONSTANT VARCHAR2(3)  := '900' ;  -- マスタメンテナンス
  -- YesNo区分
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 出荷支給区分
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- 出荷依頼
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- 支給依頼
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- 移動（プログラム内限定）
  -- 出荷支給区分（変換）
  gc_sp_class_name_ship   CONSTANT VARCHAR2(4)  := '出荷' ; -- 出荷依頼
  gc_sp_class_name_prov   CONSTANT VARCHAR2(4)  := '支給' ; -- 支給依頼
  gc_sp_class_name_move   CONSTANT VARCHAR2(4)  := '移動' ; -- 移動（プログラム内限定）
  -- 受注カテゴリ
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  -- ロット管理区分
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ロット管理あり
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ロット管理なし
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_ship        CONSTANT VARCHAR2(2) := '10' ;    -- 出荷指示
  gc_doc_type_move        CONSTANT VARCHAR2(2) := '20' ;    -- 移動
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- 支給指示
  gc_doc_type_prod        CONSTANT VARCHAR2(2) := '40' ;    -- 生産指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- 指示
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- 出庫実績
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- 入庫実績
  gc_rec_type_tron        CONSTANT VARCHAR2(2) := '40' ;    -- 投入済
  -- 出荷依頼ＩＦ：保留ステータス
  gc_reserved_status_y    CONSTANT VARCHAR2(1) := '1' ;     -- 保留
  -- 中間テーブル：指示実績区分
  gc_inst_rslt_div_h      CONSTANT VARCHAR2(1) := '0' ;     -- 保留  2008/10/10 統合テスト障害#394(1) Add
  gc_inst_rslt_div_i      CONSTANT VARCHAR2(1) := '1' ;     -- 指示
  gc_inst_rslt_div_r      CONSTANT VARCHAR2(1) := '2' ;     -- 実績
--
  ------------------------------
  -- その他
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      business_type     VARCHAR2(1)         -- 01 : 業務種別
     ,prod_div          VARCHAR2(1)         -- 02 : 商品区分
     ,item_div          VARCHAR2(1)         -- 03 : 品目区分
     ,date_from         DATE                -- 04 : 出庫日From
     ,date_to           DATE                -- 05 : 出庫日To
     ,dept_code         VARCHAR2(4)         -- 06 : 部署
     ,output_type       VARCHAR2(1)         -- 07 : 出力区分
     ,deliver_type_id   NUMBER              -- 08 : 出庫形態
     ,block_01          VARCHAR2(2)         -- 09 : ブロック１
     ,block_02          VARCHAR2(2)         -- 10 : ブロック２
     ,block_03          VARCHAR2(2)         -- 11 : ブロック３
     ,deliver_from      VARCHAR2(4)         -- 12 : 出庫元
     ,online_type       VARCHAR2(1)         -- 13 : オンライン対象区分
     ,request_no        VARCHAR2(12)        -- 14 : 依頼No／移動No
    ) ;
  -- 中間テーブル登録用レコード変数
  TYPE rec_temp_tab_data IS RECORD 
    (
      location_code     xxwsh_930c_tmp.location_code%TYPE       -- 出庫倉庫コード
     ,location_name     xxwsh_930c_tmp.location_name%TYPE       -- 出庫倉庫名称
     ,ship_date         xxwsh_930c_tmp.ship_date%TYPE           -- 出庫日
     ,arvl_date         xxwsh_930c_tmp.arvl_date%TYPE           -- 入庫日
     ,head_sales_code   xxwsh_930c_tmp.head_sales_code%TYPE     -- 管轄拠点コード
     ,head_sales_name   xxwsh_930c_tmp.head_sales_name%TYPE     -- 管轄拠点名称
     ,deliver_code      xxwsh_930c_tmp.deliver_code%TYPE        -- 配送先又は入庫先コード
     ,deliver_name      xxwsh_930c_tmp.deliver_name%TYPE        -- 配送先又は入庫先名称
     ,career_code       xxwsh_930c_tmp.career_code%TYPE         -- 運送業者コード
     ,career_name       xxwsh_930c_tmp.career_name%TYPE         -- 運送業者名称
     ,ship_method_code  xxwsh_930c_tmp.ship_method_code%TYPE    -- 配送区分コード
     ,ship_method_name  xxwsh_930c_tmp.ship_method_name%TYPE    -- 配送区分名称
     ,ship_type         xxwsh_930c_tmp.ship_type%TYPE           -- 業務種別
     ,delivery_no       xxwsh_930c_tmp.delivery_no%TYPE         -- 配送Ｎｏ
     ,request_no        xxwsh_930c_tmp.request_no%TYPE          -- 依頼Ｎｏ／移動Ｎｏ
     ,item_code         xxwsh_930c_tmp.item_code%TYPE           -- 品目コード
     ,item_name         xxwsh_930c_tmp.item_name%TYPE           -- 品目名称
     ,lot_no            xxwsh_930c_tmp.lot_no%TYPE              -- ロット番号
     ,product_date      xxwsh_930c_tmp.product_date%TYPE        -- 製造日
     ,use_by_date       xxwsh_930c_tmp.use_by_date%TYPE         -- 賞味期限
     ,original_char     xxwsh_930c_tmp.original_char%TYPE       -- 固有記号
     ,lot_status        xxwsh_930c_tmp.lot_status%TYPE          -- 品質
     ,quant_r           xxwsh_930c_tmp.quant_r%TYPE             -- 依頼数
     ,quant_i           xxwsh_930c_tmp.quant_i%TYPE             -- 入庫数
     ,quant_o           xxwsh_930c_tmp.quant_o%TYPE             -- 出庫数
     ,reason            xxwsh_930c_tmp.reason%TYPE              -- 差異事由
     ,inst_rslt_div     xxwsh_930c_tmp.inst_rslt_div%TYPE       -- 指示実績区分（1：指示 2：実績）
    ) ;
--
  -- 抽出データ格納用レコード変数
  TYPE rec_get_data IS RECORD 
    (
      location_code    VARCHAR2(100)  -- 出庫倉庫コード
     ,location_name    VARCHAR2(100)  -- 出庫倉庫名称
     ,ship_date        DATE     -- 出庫日
     ,arvl_date        DATE     -- 入庫日
-- mod start ver1.1
--     ,po_no            VARCHAR2(100)  -- 検索条件：管轄拠点
     ,head_sales_branch VARCHAR2(100)  -- 検索条件：管轄拠点
-- mod end ver1.1
     ,deliver_id       VARCHAR2(100)  -- 検索条件：配送先
     ,career_id        VARCHAR2(100)  -- 検索条件：運送業者
     ,ship_method_code VARCHAR2(100)  -- 検索条件：配送区分
     ,order_type       VARCHAR2(100)  -- 業務種別（コード）
     ,delivery_no      VARCHAR2(100)  -- 配送Ｎｏ
     ,request_no       VARCHAR2(100)  -- 依頼Ｎｏ
     ,order_line_id    VARCHAR2(100)  -- 検索条件：明細ＩＤ
     ,item_id          VARCHAR2(100)  -- 検索条件：品目ＩＤ
     ,item_code        VARCHAR2(100)  -- 品目コード
     ,item_name        VARCHAR2(100)  -- 品目名称
     ,lot_ctl          VARCHAR2(100)  -- 検索条件：ロット使用
     ,quant_r          NUMBER   -- 依頼数（ロット管理外）
     ,quant_i          NUMBER   -- 入庫数（ロット管理外）
     ,quant_o          NUMBER   -- 出庫数（ロット管理外）
-- 2008/07/24 A.Shiina v1.7 ADD Start
     ,quant_d          NUMBER   -- 内訳数量(インタフェース用)
-- 2008/07/24 A.Shiina v1.7 ADD End
     ,status           VARCHAR2(100)  -- 受注ヘッダステータス
-- add start ver1.1
     ,conv_unit        VARCHAR2(240)  -- 入出庫換算単位
     ,num_of_cases     NUMBER         -- ケース入数
-- add end ver1.1
-- add start ver1.2
     ,lot_id           NUMBER         -- ロットID
-- add end ver1.2
-- add start ver1.3
     ,prod_class_code  VARCHAR(100)    -- 商品区分
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 Update Start
     ,freight_charge_code   VARCHAR(1)  -- 運賃区分
     ,complusion_output_kbn VARCHAR(1)  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.5 Update End
-- 2008/11/17 統合指摘#651 Add Start -----------------------------------------------
     ,no_instr_actual  VARCHAR(1)        -- 指示なし実績：'Y' 指示あり実績:'N'
     ,lot_inst_cnt     NUMBER            -- 指示ロットの件数
     ,row_num          NUMBER            -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End -------------------------------------------------
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER := 0 ;         -- 処理データカウンタ
--
  gb_get_flg            BOOLEAN := FALSE ;    -- データ取得判定フラグ
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER  := 0 ;        -- ＸＭＬデータタグ表のインデックス
--
  gn_created_by               NUMBER ;  -- 作成者
  gn_last_updated_by          NUMBER ;  -- 最終更新者
  gn_last_update_login        NUMBER ;  -- 最終更新ログイン
  gn_request_id               NUMBER ;  -- 要求ID
  gn_program_application_id   NUMBER ;  -- コンカレント・プログラム・アプリケーションID
  gn_program_id               NUMBER ;  -- コンカレント・プログラムID
--
  gv_nvl_null_char        VARCHAR2(4) := 'NULL';   -- 2008/10/31 統合指摘#461 Add
  gn_nvl_null_num         NUMBER := 0;             -- 2008/10/31 統合指摘#461 Add
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_user' ; -- プログラム名
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
    lv_sql_dtl        CONSTANT VARCHAR2(32000)
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
      || ' FROM xxwsh_930c_tmp   x9t'
      || ' WHERE NVL( x9t.reason, ''*'' ) = NVL( :V1, NVL( x9t.reason, ''*'' ) )'
-- mod start ver1.1
--      || ' AND   x9t.delivery_no = :V2'
      || ' AND   NVL(x9t.delivery_no,''X'') = NVL(:V2,''X'')'
-- mod end ver1.1
      || ' AND   x9t.request_no  = :V3'
      || ' AND   x9t.inst_rslt_div = :V4'    -- 2008/10/20 統合テスト障害#394(1) Add
      ;
    lv_sql_order_1    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_CHAR( x9t.product_date, ''YYYY/MM/DD'' )'
      || '         ,x9t.original_char'
      ;
    lv_sql_order_2    CONSTANT VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( x9t.item_code )'
      || '         ,TO_NUMBER( x9t.lot_no )'
      ;
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    -- マスタレコード取得カーソル
    CURSOR cu_mst( p_ship_type xxwsh_930c_tmp.ship_type%TYPE  )
    IS
      SELECT mst.location_code
            ,mst.location_name
            ,mst.ship_date
            ,mst.arvl_date
            ,mst.head_sales_code
            ,mst.head_sales_name
            ,mst.deliver_code
            ,mst.deliver_name
            ,mst.career_code
            ,mst.career_name
            ,mst.ship_method_code
            ,mst.ship_method_name
            ,mst.ship_type
            ,mst.delivery_no
            ,mst.request_no
            ,mst.inst_rslt_div   -- 2008/10/20 統合テスト障害#394(1) Add
      FROM
      (
        SELECT DISTINCT
               x9t.location_code     AS location_code
              ,x9t.location_name     AS location_name
              ,TO_CHAR( x9t.ship_date , 'YYYY/MM/DD' ) AS ship_date
              ,TO_CHAR( x9t.arvl_date , 'YYYY/MM/DD' ) AS arvl_date
              ,x9t.head_sales_code   AS head_sales_code
              ,x9t.head_sales_name   AS head_sales_name
              ,x9t.deliver_code      AS deliver_code
              ,x9t.deliver_name      AS deliver_name
              ,x9t.career_code       AS career_code
              ,x9t.career_name       AS career_name
              ,x9t.ship_method_code  AS ship_method_code
              ,x9t.ship_method_name  AS ship_method_name
              ,x9t.ship_type         AS ship_type
              ,x9t.delivery_no       AS delivery_no
              ,x9t.request_no        AS request_no
              ,x9t.inst_rslt_div     AS inst_rslt_div
        FROM xxwsh_930c_tmp   x9t
        WHERE x9t.ship_type = NVL( p_ship_type, x9t.ship_type )
      ) mst
      ORDER BY mst.location_code
              ,mst.ship_date
              ,mst.arvl_date
              ,mst.delivery_no
              ,mst.request_no
              ,mst.inst_rslt_div
    ;
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_sql                  VARCHAR2(32000) ;
    -- ブレイク判断用
    lv_tmp_location_code    VARCHAR2(4)  := '*' ; 
    -- マスタ項目出力用
    lv_ship_date            VARCHAR2(10) ;        -- 出庫日
    lv_arvl_date            VARCHAR2(10) ;        -- 入庫日
    lv_head_sales_code      VARCHAR2(4) ;         -- 管轄拠点コード
    lv_head_sales_name      VARCHAR2(20) ;        -- 管轄拠点名称
    lv_deliver_code         VARCHAR2(9) ;         -- 配送先又は入庫先コード
    lv_deliver_name         VARCHAR2(60) ;        -- 配送先又は入庫先名称
    lv_career_code          VARCHAR2(4) ;         -- 運送業者コード
    lv_career_name          VARCHAR2(20) ;        -- 運送業者名称
    lv_ship_method_code     VARCHAR2(2) ;         -- 配送区分コード
    lv_ship_method_name     VARCHAR2(14) ;        -- 配送区分名称
    lv_ship_type            VARCHAR2(4) ;         -- 業務種別
    lv_delivery_no          VARCHAR2(12) ;        -- 配送Ｎｏ
    lv_request_no           VARCHAR2(12) ;        -- 依頼Ｎｏ／移動Ｎｏ
    lv_param_ship_type      VARCHAR2(4) ;         -- 業務種別（ＳＱＬ実行用）
    lv_param_reason         VARCHAR2(6) ;         -- 差異事由（ＳＱＬ実行用）
-- add start ver1.2
    lv_item_code            VARCHAR2(7) ;         -- 品目コード
    lv_item_name            VARCHAR2(20) ;        -- 品目名称
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
      lv_sql := lv_sql_dtl || lv_sql_order_1 ;
--
    ------------------------------
    -- Ｐ．品目区分が製品以外の場合
    ------------------------------
    ELSE
      lv_sql := lv_sql_dtl || lv_sql_order_2 ;
--
    END IF ;
--
    -- ====================================================
    -- パラメータ変換
    -- ====================================================
    BEGIN
      IF ( gr_param.business_type IS NOT NULL ) THEN
        SELECT xlvv.meaning
        INTO   lv_param_ship_type
        FROM xxcmn_lookup_values_v xlvv
        WHERE xlvv.lookup_type = gc_lookup_biz_type
        AND   xlvv.lookup_code = gr_param.business_type
        ;
      END IF ;
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
    -- リストグループ開始タグ（出庫倉庫）
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lctn_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<mst_data_loop>>
    FOR re_data IN cu_mst( lv_param_ship_type ) LOOP
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
        -- 出庫倉庫ブレイク
        -- ====================================================
        IF ( re_data.location_code <> lv_tmp_location_code ) THEN
          -- ----------------------------------------------------
          -- グループ終了タグ出力
          -- ----------------------------------------------------
          -- 初回レコードの場合は表示しない
          IF ( lv_tmp_location_code <> '*' ) THEN
            -- リストグループ終了タグ（出荷情報）
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- グループ終了タグ（出庫倉庫）
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
          -- 出庫倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'location_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.location_code ;
          -- 出庫倉庫名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'location_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := re_data.location_name ;
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
          lv_tmp_location_code := re_data.location_code ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_spmt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- マスタ項目の退避
        -- ----------------------------------------------------
        lv_ship_date        := re_data.ship_date ;           -- 出庫日
        lv_arvl_date        := re_data.arvl_date ;           -- 入庫日
        lv_head_sales_code  := re_data.head_sales_code ;     -- 管轄拠点コード
        lv_head_sales_name  := re_data.head_sales_name ;     -- 管轄拠点名称
        lv_deliver_code     := re_data.deliver_code ;        -- 配送先又は入庫先コード
        lv_deliver_name     := re_data.deliver_name ;        -- 配送先又は入庫先名称
        lv_career_code      := re_data.career_code ;         -- 運送業者コード
        lv_career_name      := re_data.career_name ;         -- 運送業者名称
        lv_ship_method_code := re_data.ship_method_code ;    -- 配送区分コード
        lv_ship_method_name := re_data.ship_method_name ;    -- 配送区分名称
        lv_ship_type        := re_data.ship_type ;           -- 業務種別
        lv_delivery_no      := re_data.delivery_no ;         -- 配送Ｎｏ
        lv_request_no       := re_data.request_no ;          -- 依頼Ｎｏ／移動Ｎｏ
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
          -- 管轄拠点コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_head_sales_code ;
          -- 管轄拠点名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'head_sales_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_head_sales_name ;
          -- 配送先・入庫先コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_deliver_code ;
          -- 配送先・入庫先名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_deliver_name ;
          -- 運送業者コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'career_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_career_code ;
          -- 運送業者名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'career_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_career_name ;
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
          -- 業務種別
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_ship_type ;
          -- 配送Ｎｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lv_delivery_no ;
          -- 依頼・移動Ｎｏ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
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
-- mod start ver1.2
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
-- mod start ver1.2
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
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.original_char ;
          -- 品質
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_status' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.lot_status ;
          -- 依頼数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_r' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_r ;
          -- 入庫数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_i' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quant_i ;
          -- 出庫数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_o' ;
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
          lv_ship_date        := NULL ;
          lv_arvl_date        := NULL ;
          lv_head_sales_code  := NULL ;
          lv_head_sales_name  := NULL ;
          lv_deliver_code     := NULL ;
          lv_deliver_name     := NULL ;
          lv_career_code      := NULL ;
          lv_career_name      := NULL ;
          lv_ship_method_code := NULL ;
          lv_ship_method_name := NULL ;
          lv_ship_type        := NULL ;
          lv_delivery_no      := NULL ;
          lv_request_no       := NULL ;
--
-- add start ver1.2
          lv_item_code := lr_ref.item_code ;
          lv_item_name := lr_ref.item_name ;
-- add end ver1.2
          FETCH lc_ref INTO lr_ref ;
          EXIT WHEN lc_ref%NOTFOUND ;
--
        END LOOP dtl_data_loop ;
--
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
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_spmt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      ELSE
        -- ====================================================
        -- カーソルクローズ
        -- ====================================================
        CLOSE lc_ref ;
--
      END IF ;
--
    END LOOP mst_data_loop ;
--
    -- ====================================================
    -- グループ終了タグ出力
    -- ====================================================
    -- リストグループ終了タグ（出荷情報）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_spmt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- グループ終了タグ（出庫倉庫）
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lctn' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- リストグループ終了タグ（出庫倉庫）
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
      ir_temp_tab   IN     rec_temp_tab_data    -- 中間テーブル登録データ
     ,ov_errbuf     OUT    VARCHAR2             -- エラー・メッセージ
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
    -- 中間テーブル登録
    -- ====================================================
    INSERT INTO xxwsh_930c_tmp
      (
        location_code                 -- 出庫倉庫コード
       ,location_name                 -- 出庫倉庫名称
       ,ship_date                     -- 出庫日
       ,arvl_date                     -- 入庫日
       ,head_sales_code               -- 管轄拠点コード
       ,head_sales_name               -- 管轄拠点名称
       ,deliver_code                  -- 配送先又は入庫先コード
       ,deliver_name                  -- 配送先又は入庫先名称
       ,career_code                   -- 運送業者コード
       ,career_name                   -- 運送業者名称
       ,ship_method_code              -- 配送区分コード
       ,ship_method_name              -- 配送区分名称
       ,ship_type                     -- 業務種別
       ,delivery_no                   -- 配送Ｎｏ
       ,request_no                    -- 依頼Ｎｏ／移動Ｎｏ
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
       ,inst_rslt_div                 -- 指示実績区分
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
        SUBSTRB( ir_temp_tab.location_code   , 1, 4  )  -- 出庫倉庫コード
       ,SUBSTRB( ir_temp_tab.location_name   , 1, 20 )  -- 出庫倉庫名称
       ,ir_temp_tab.ship_date                           -- 出庫日
       ,ir_temp_tab.arvl_date                           -- 入庫日
       ,SUBSTRB( ir_temp_tab.head_sales_code , 1, 4  )  -- 管轄拠点コード
       ,SUBSTRB( ir_temp_tab.head_sales_name , 1, 20 )  -- 管轄拠点名称
       ,SUBSTRB( ir_temp_tab.deliver_code    , 1, 9  )  -- 配送先又は入庫先コード
       ,SUBSTRB( ir_temp_tab.deliver_name    , 1, 60 )  -- 配送先又は入庫先名称
       ,SUBSTRB( ir_temp_tab.career_code     , 1, 4  )  -- 運送業者コード
       ,SUBSTRB( ir_temp_tab.career_name     , 1, 20 )  -- 運送業者名称
       ,SUBSTRB( ir_temp_tab.ship_method_code, 1, 2  )  -- 配送区分コード
       ,SUBSTRB( ir_temp_tab.ship_method_name, 1, 14 )  -- 配送区分名称
       ,SUBSTRB( ir_temp_tab.ship_type       , 1, 4  )  -- 業務種別
       ,SUBSTRB( ir_temp_tab.delivery_no     , 1, 12 )  -- 配送Ｎｏ
       ,SUBSTRB( ir_temp_tab.request_no      , 1, 12 )  -- 依頼Ｎｏ／移動Ｎｏ
       ,SUBSTRB( ir_temp_tab.item_code       , 1, 7  )  -- 品目コード
       ,SUBSTRB( ir_temp_tab.item_name       , 1, 20 )  -- 品目名称
       ,SUBSTRB( ir_temp_tab.lot_no          , 1, 10 )  -- ロット番号
       ,ir_temp_tab.product_date                        -- 製造日
       ,ir_temp_tab.use_by_date                         -- 賞味期限
       ,SUBSTRB( ir_temp_tab.original_char   , 1, 6  )  -- 固有記号
       ,SUBSTRB( ir_temp_tab.lot_status      , 1, 10 )  -- 品質
       ,SUBSTRB( ir_temp_tab.quant_r         , 1, 12 )  -- 依頼数
       ,SUBSTRB( ir_temp_tab.quant_i         , 1, 12 )  -- 入庫数
       ,SUBSTRB( ir_temp_tab.quant_o         , 1, 12 )  -- 出庫数
       ,SUBSTRB( ir_temp_tab.reason          , 1, 6  )  -- 差異事由
       ,SUBSTRB( ir_temp_tab.inst_rslt_div   , 1, 1  )  -- 指示実績区分
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
-- 2008/07/24 A.Shiina v1.7 ADD Start
    cv_eos_data_cd_200  CONSTANT VARCHAR2(3) := '200';  -- 200 有償出荷報告
    cv_eos_data_cd_210  CONSTANT VARCHAR2(3) := '210';  -- 210 拠点出荷確定報告
    cv_eos_data_cd_215  CONSTANT VARCHAR2(3) := '215';  -- 215 庭先出荷確定報告
    cv_eos_data_cd_220  CONSTANT VARCHAR2(3) := '220';  -- 220 移動出庫確定報告
    cv_eos_data_cd_230  CONSTANT VARCHAR2(3) := '230';  -- 230 移動入庫確定報告
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 本番障害#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 本番障害#333 Add
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_reserved_status  xxwsh_shipping_lines_if.reserved_status%TYPE ;            -- 保留ステータス
-- 2008/07/24 A.Shiina v1.7 ADD Start
    lv_eos_data_type    xxwsh_shipping_headers_if.eos_data_type%TYPE ;  -- EOSデータ種別
    ln_quant_kbn        NUMBER;         -- 数量区分
--
    ln_cnt              NUMBER := 0 ;   -- 存在カウント
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    ln_temp_cnt         NUMBER := 0 ;   -- 取得レコードカウント
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
    --------------------------------------------------
    -- 管轄拠点設定
    --------------------------------------------------
-- mod start ver1.1
--    IF ( ir_get_data.po_no IS NULL ) THEN
    IF ( ir_get_data.head_sales_branch IS NULL ) THEN
-- mod end ver1.1
      or_temp_tab.head_sales_code := NULL ;
      or_temp_tab.head_sales_name := NULL ;
    ELSE
      BEGIN
        -- Del start ver1.1 -------------------------------
        --SELECT xps.base_code
        --      ,xp.party_short_name
        --INTO   or_temp_tab.head_sales_code    -- 管轄拠点コード
        --      ,or_temp_tab.head_sales_name    -- 管轄拠点名称
        --FROM xxcmn_party_sites2_v   xps   -- パーティサイト情報VIEW2
        ---   ,xxcmn_parties2_v       xp    -- パーティ情報VIEW2
        --WHERE gr_param.date_from BETWEEN xp.start_date_active  AND xp.end_date_active
        --AND   xps.party_id       = xp.party_id
        --AND   gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
        --AND   xps.base_code      = ir_get_data.po_no
        --AND   xps.base_code      = ir_get_data.head_sales_branch
        --;
        -- Del start ver1.1 -------------------------------
--
        -- 2008/12/03 本番障害#333 Del Start ------------------------------------------------
        -- Add start ver1.1 -------------------------------
        --SELECT xca.party_number
        --      ,xca.party_short_name
        --INTO   or_temp_tab.head_sales_code    -- 管轄拠点コード
        --      ,or_temp_tab.head_sales_name    -- 管轄拠点名称
        --FROM xxcmn_cust_accounts2_v   xca     -- 顧客情報VIEW2
        --WHERE gr_param.date_from BETWEEN xca.start_date_active  AND xca.end_date_active
        --AND   xca.party_number = ir_get_data.head_sales_branch
        --;
        -- Add End ver1.1 ---------------------------------
        -- 2008/12/03 本番障害#333 Del End -------------------------------------------------
--
        -- 2008/12/03 本番障害#333 Add Start -----------------------------------------------
        SELECT hca.account_number
              ,CASE hca.customer_class_code
                 WHEN '10' THEN xp.party_name
                 ELSE xp.party_short_name
               END
        INTO   or_temp_tab.head_sales_code    -- 管轄拠点コード
              ,or_temp_tab.head_sales_name    -- 管轄拠点名称
        FROM   hz_cust_accounts  hca
              ,xxcmn_parties     xp
        WHERE  hca.party_id = xp.party_id
        AND    hca.account_number = ir_get_data.head_sales_branch
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 本番障害#333 Add End -------------------------------------------------
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          or_temp_tab.head_sales_code := NULL ;
          or_temp_tab.head_sales_name := NULL ;
      END ;
    END IF ;
--
    --------------------------------------------------
    -- 配送先設定
    --------------------------------------------------
    BEGIN
      -- 保留データの場合
      IF ( ir_get_data.status IS NULL ) THEN
--        SELECT xps.party_site_number
--              ,xps.party_site_full_name
--        INTO   or_temp_tab.deliver_code   -- 配送先又は入庫先コード
--              ,or_temp_tab.deliver_name   -- 配送先又は入庫先名称
--        FROM xxcmn_party_sites2_v   xps   -- パーティサイト情報VIEW2
--        WHERE gr_param.date_from    BETWEEN xps.start_date_active AND xps.end_date_active
--        AND   xps.party_site_number = ir_get_data.deliver_id
--        ;
-- add start ver1.1
        -- 出荷依頼の場合
        IF ( ir_get_data.order_type = gc_eos_type_rpt_ship_k ) THEN
--
          -- 2008/12/03 本番障害#333 Del Start ----------------------------------------------
          --SELECT xcas.party_site_number
          --      --,xcas.party_site_short_name  -- 2008/07/02 Del Y.Kawano
          --      ,xcas.party_site_full_name     -- 2008/07/02 Add Y.Kawano
          --INTO   or_temp_tab.deliver_code      -- 配送先又は入庫先コード
          --      ,or_temp_tab.deliver_name      -- 配送先又は入庫先名称
          --FROM xxcmn_cust_acct_sites2_v   xcas -- 顧客サイト情報VIEW2
          --WHERE gr_param.date_from BETWEEN xcas.start_date_active AND xcas.end_date_active
          ----AND   xcas.cust_acct_site_id  = ir_get_data.deliver_id  -- 2008/07/02 Del Y.Kawano
          --AND   xcas.party_site_id  = ir_get_data.deliver_id        -- 2008/07/02 Add Y.Kawano
          --;
          -- 2008/12/03 本番障害#333 Del End -------------------------------------------------
--
          -- 2008/12/03 本番障害#333 Add Start -----------------------------------------------
          SELECT hzl.province
                ,xps.party_site_name
          INTO   or_temp_tab.deliver_code      -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name      -- 配送先又は入庫先名称
          FROM   hz_locations      hzl
                ,xxcmn_party_sites xps
          WHERE  xps.party_site_id = ir_get_data.deliver_id
          AND    xps.location_id = hzl.location_id
          AND    gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 本番障害#333 Add End ----------------------------------
--
        -- 支給依頼の場合
        ELSIF ( ir_get_data.order_type = gc_eos_type_rpt_ship_y ) THEN
          SELECT xvs.vendor_site_code
                ,xvs.vendor_site_name
          INTO   or_temp_tab.deliver_code   -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name   -- 配送先又は入庫先名称
          FROM xxcmn_vendor_sites2_v  xvs   -- 仕入先サイト情報VIEW2
          WHERE gr_param.date_from BETWEEN xvs.start_date_active AND xvs.end_date_active
          AND   xvs.vendor_site_id = ir_get_data.deliver_id
          ;
        -- 移動依頼の場合
        ELSIF ( ir_get_data.order_type IN( gc_eos_type_rpt_move_o
                                          ,gc_eos_type_rpt_move_i ) ) THEN
--
          -- 2008/12/03 本番障害#333 Del Start --------------------------------
          --SELECT xil.segment1
          --      ,xil.description
          --INTO   or_temp_tab.deliver_code     -- 配送先又は入庫先コード
          --      ,or_temp_tab.deliver_name     -- 配送先又は入庫先名称
          --FROM xxcmn_item_locations2_v    xil -- ＯＰＭ保管場所マスタ
          --WHERE xil.inventory_location_id = ir_get_data.deliver_id
          --AND   gr_param.date_from BETWEEN xil.date_from                             -- add ver1.2
          --                         AND     NVL(xil.date_to, gr_param.date_from )     -- add ver1.2
          --;
          -- 2008/12/03 本番障害#333 Del End ----------------------------------
--
          -- 2008/12/03 本番障害#333 Add Start --------------------------------
          SELECT mil.segment1
                ,mil.description
          INTO   or_temp_tab.deliver_code     -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name     -- 配送先又は入庫先名称
          FROM   mtl_item_locations mil
          WHERE  mil.inventory_location_id = ir_get_data.deliver_id
          AND    gr_param.date_from BETWEEN NVL(mil.start_date_active,gr_param.date_from)
                                      AND NVL(mil.end_date_active,gr_param.date_from)
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 本番障害#333 Add End ----------------------------------
--
        END IF ;
-- add end ver1.1
      -- 保留データ以外の場合
      ELSE
        -- 出荷依頼の場合
        IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
--
          -- Del start ver1.1 -------------------------------
          --SELECT xps.party_site_number
          --      ,xps.party_site_full_name
          --INTO   or_temp_tab.deliver_code   -- 配送先又は入庫先コード
          --      ,or_temp_tab.deliver_name   -- 配送先又は入庫先名称
          --FROM xxcmn_party_sites2_v   xps   -- パーティサイト情報VIEW2
          --WHERE gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          --AND   xps.party_site_id  = ir_get_data.deliver_id
          --;
          -- Del End ver1.1 -------------------------------
--
          -- 2008/12/03 本番障害#333 Del Start ----------------------------------------------
          -- Add start ver1.1 -------------------------------
          --SELECT xcas.party_site_number
          --      --,xcas.party_site_short_name  -- 2008/07/02 Del Y.Kawano
          --      ,xcas.party_site_full_name     -- 2008/07/02 Add Y.Kawano
          --INTO   or_temp_tab.deliver_code      -- 配送先又は入庫先コード
          --      ,or_temp_tab.deliver_name      -- 配送先又は入庫先名称
          --FROM xxcmn_cust_acct_sites2_v   xcas -- 顧客サイト情報VIEW2
          --WHERE gr_param.date_from BETWEEN xcas.start_date_active AND xcas.end_date_active
          ----AND   xcas.cust_acct_site_id  = ir_get_data.deliver_id --2008/07/02 Del Y.Kawano
          --AND   xcas.party_site_id  = ir_get_data.deliver_id       --2008/07/02 Add Y.Kawano
          --;
          -- Add End ver1.1 -------------------------------
          -- 2008/12/03 本番障害#333 Del End ------------------------------------------------
--
          -- 2008/12/03 本番障害#333 Add Start -----------------------------------------------
          SELECT hzl.province
                ,xps.party_site_name
          INTO   or_temp_tab.deliver_code      -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name      -- 配送先又は入庫先名称
          FROM   hz_locations      hzl
                ,xxcmn_party_sites xps
          WHERE  xps.party_site_id = ir_get_data.deliver_id
          AND    xps.location_id = hzl.location_id
          AND    gr_param.date_from BETWEEN xps.start_date_active AND xps.end_date_active
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 本番障害#333 Add End -------------------------------------------------
--
        -- 支給依頼の場合
        ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
          SELECT xvs.vendor_site_code
                ,xvs.vendor_site_name
          INTO   or_temp_tab.deliver_code   -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name   -- 配送先又は入庫先名称
          FROM xxcmn_vendor_sites2_v  xvs   -- 仕入先サイト情報VIEW2
          WHERE gr_param.date_from BETWEEN xvs.start_date_active AND xvs.end_date_active
          AND   xvs.vendor_site_id = ir_get_data.deliver_id
          ;
        -- 移動依頼の場合
        ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
--
          -- 2008/12/03 本番障害#333 Del Start --------------------------------
          --SELECT xil.segment1
          --      ,xil.description
          --INTO   or_temp_tab.deliver_code     -- 配送先又は入庫先コード
          --      ,or_temp_tab.deliver_name     -- 配送先又は入庫先名称
          --FROM xxcmn_item_locations2_v    xil -- ＯＰＭ保管場所マスタ
          --WHERE xil.inventory_location_id = ir_get_data.deliver_id
          --AND   gr_param.date_from BETWEEN xil.date_from                            -- add ver1.2
          --                         AND     NVL(xil.date_to, gr_param.date_from )    -- add ver1.2
          --;
          -- 2008/12/03 本番障害#333 Del End ----------------------------------
--
          -- 2008/12/03 本番障害#333 Add Start --------------------------------
          SELECT mil.segment1
                ,mil.description
          INTO   or_temp_tab.deliver_code     -- 配送先又は入庫先コード
                ,or_temp_tab.deliver_name     -- 配送先又は入庫先名称
          FROM   mtl_item_locations mil
          WHERE  mil.inventory_location_id = ir_get_data.deliver_id
          AND    gr_param.date_from BETWEEN NVL(mil.start_date_active,gr_param.date_from)
                                       AND NVL(mil.end_date_active,gr_param.date_from)
          AND    ROWNUM = 1
          ;
          -- 2008/12/03 本番障害#333 Add End ----------------------------------
--
        END IF ;
--
      END IF ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.deliver_code := NULL ;
        or_temp_tab.deliver_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.deliver_code := NULL ;
        or_temp_tab.deliver_name := NULL ;
    END ;
--
-- 2008/07/07 A.Shiina v1.5 Update Start
   IF  ((ir_get_data.freight_charge_code  = '1')
    OR (ir_get_data.complusion_output_kbn = '1')) THEN
-- 2008/07/07 A.Shiina v1.5 Update End
    --------------------------------------------------
    -- 運送業者設定
    --------------------------------------------------
    BEGIN
      -- 保留データの場合
      IF ( ir_get_data.status IS NULL ) THEN
--
        -- 2008/12/03 本番障害#333 Del Start --------------------------------
        --SELECT xc.party_number
        --      ,xc.party_short_name
        --INTO   or_temp_tab.career_code  -- 運送業者コード
        --      ,or_temp_tab.career_name  -- 運送業者名称
        --FROM xxcmn_carriers2_v  xc    -- 運送業者情報VIEW2
        --WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        ----AND   xc.party_number     = ir_get_data.career_id   -- del ver1.1
        ----AND   xc.party_id         = ir_get_data.career_id     -- add ver1.1    -- 2008/07/07 A.Shiina v1.5 Del
        --AND   xc.party_number     = ir_get_data.career_id                        -- 2008/07/07 A.Shiina v1.5 Add
        --;
        -- 2008/12/03 本番障害#333 Del End ----------------------------------
--
        -- 2008/12/03 本番障害#333 Add Start --------------------------------
        SELECT wc.freight_code
              ,xp.party_short_name
        INTO   or_temp_tab.career_code  -- 運送業者コード
              ,or_temp_tab.career_name  -- 運送業者名称
        FROM   wsh_carriers    wc
              ,xxcmn_parties   xp
-- 2008/12/07 T.Miyata Modify Start 本番障害#516 ユーザが入力するのはNoの方なので、結合条件をNoとする。
        --WHERE  wc.carrier_id = ir_get_data.career_id
        WHERE  wc.freight_code = ir_get_data.career_id
-- 2008/12/07 T.Miyata Modify End   本番障害#516
        AND    xp.party_id = wc.carrier_id
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 本番障害#333 Add End ----------------------------------
--
      -- 保留データ以外の場合
      ELSE
--
        -- 2008/12/03 本番障害#333 Del Start --------------------------------
        --SELECT xc.party_number
        --      ,xc.party_short_name
        --INTO   or_temp_tab.career_code  -- 運送業者コード
        --      ,or_temp_tab.career_name  -- 運送業者名称
        --FROM xxcmn_carriers2_v  xc    -- 運送業者情報VIEW2
        --WHERE gr_param.date_from BETWEEN xc.start_date_active AND xc.end_date_active
        --AND   xc.party_id        = ir_get_data.career_id
        --;
        -- 2008/12/03 本番障害#333 Del End ----------------------------------
--
        -- 2008/12/03 本番障害#333 Add Start --------------------------------
        SELECT wc.freight_code
              ,xp.party_short_name
        INTO   or_temp_tab.career_code  -- 運送業者コード
              ,or_temp_tab.career_name  -- 運送業者名称
        FROM   wsh_carriers    wc
              ,xxcmn_parties   xp
        WHERE  wc.carrier_id = ir_get_data.career_id
        AND    xp.party_id = wc.carrier_id
        AND    gr_param.date_from BETWEEN xp.start_date_active AND xp.end_date_active
        AND    ROWNUM = 1
        ;
        -- 2008/12/03 本番障害#333 Add End ----------------------------------
--
      END IF ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.career_code := NULL ;
        or_temp_tab.career_name := NULL ;
    END ;
--
-- 2008/07/07 A.Shiina v1.5 Update Start
   END IF;
-- 2008/07/07 A.Shiina v1.5 Update End
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
    -- 業務種別設定
    --------------------------------------------------
    -- 保留データの場合
    IF ( ir_get_data.status IS NULL ) THEN
--
      -- 出荷依頼の場合
      IF ( ir_get_data.order_type = gc_eos_type_rpt_ship_k ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_ship ;  -- 出荷
--
      -- 支給依頼の場合
      ELSIF ( ir_get_data.order_type = gc_eos_type_rpt_ship_y ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_prov ;  -- 支給
--
      -- 移動データの場合
      ELSIF ( ir_get_data.order_type IN( gc_eos_type_rpt_move_o
                                        ,gc_eos_type_rpt_move_i ) ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_move ;  -- 移動
--
      END IF ;
--
    -- 保留データ以外の場合
    ELSE
--
      -- 出荷依頼の場合
      IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_ship ;  -- 出荷
--
      -- 支給依頼の場合
      ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_prov ;  -- 支給
--
      -- 移動データの場合
      ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
        or_temp_tab.ship_type := gc_sp_class_name_move ;  -- 移動
--
      END IF ;
--
    END IF ;
--
    --------------------------------------------------
    -- 配送Ｎｏ・依頼Ｎｏ設定
    --------------------------------------------------
    or_temp_tab.delivery_no := ir_get_data.delivery_no ;  -- 配送Ｎｏ
    or_temp_tab.request_no  := ir_get_data.request_no ;   -- 依頼Ｎｏ／移動Ｎｏ
--
    --------------------------------------------------
    -- 品目設定
    --------------------------------------------------
    or_temp_tab.item_code := ir_get_data.item_code ;  -- 品目コード
    or_temp_tab.item_name := ir_get_data.item_name ;  -- 品目名称
--
    --------------------------------------------------
    -- 指示・実績区分設定
    --------------------------------------------------
    -- 保留データの場合
    IF ( ir_get_data.status IS NULL ) THEN
--
      --or_temp_tab.inst_rslt_div := gc_inst_rslt_div_i ; -- 指示  2008/10/10 統合テスト障害#394(1) Del
      or_temp_tab.inst_rslt_div := gc_inst_rslt_div_h ; -- 保留    2008/10/10 統合テスト障害#394(1) Add
--
    -- 保留データ以外の場合
    ELSE
--
      -- 出荷・支給の場合
      IF ( ir_get_data.order_type = gc_sp_class_ship ) THEN
        -- 指示レコードであるかを確認する
        SELECT COUNT( xoha.order_header_id )
        INTO   ln_temp_cnt
        FROM   xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
        WHERE xoha.career_id             = ir_get_data.career_id
        AND   xoha.shipping_method_code  = ir_get_data.ship_method_code
        AND   xoha.deliver_to_id         = ir_get_data.deliver_id
        AND   xoha.schedule_ship_date    = ir_get_data.ship_date
        AND   xoha.schedule_arrival_date = ir_get_data.arvl_date
        AND   xoha.latest_external_flag  = gc_yn_div_y             -- 最新
        AND   xoha.request_no            = ir_get_data.request_no  -- 依頼Ｎｏ
        ;
      -- 支給の場合
      ELSIF ( ir_get_data.order_type = gc_sp_class_prov ) THEN
        -- 指示レコードであるかを確認する
        SELECT COUNT( xoha.order_header_id )
        INTO   ln_temp_cnt
        FROM   xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
        WHERE xoha.career_id             = ir_get_data.career_id
        AND   xoha.shipping_method_code  = ir_get_data.ship_method_code
        AND   xoha.vendor_site_id        = ir_get_data.deliver_id
        AND   xoha.schedule_ship_date    = ir_get_data.ship_date
        AND   xoha.schedule_arrival_date = ir_get_data.arvl_date
        AND   xoha.latest_external_flag  = gc_yn_div_y             -- 最新
        AND   xoha.request_no            = ir_get_data.request_no  -- 依頼Ｎｏ
        ;
      -- 移動の場合
      ELSIF ( ir_get_data.order_type = gc_sp_class_move ) THEN
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
      END IF ;

      -- 指示レコードの場合
      IF ln_temp_cnt > 0 THEN
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_i ; -- 指示
--
      -- 指示レコードではない場合
      ELSE
        or_temp_tab.inst_rslt_div := gc_inst_rslt_div_r ; -- 実績
      END IF ;
--
    END IF ;
--
    --------------------------------------------------
    -- ロット情報設定
    --------------------------------------------------
-- del satart ver1.1
    -- ロット管理品以外の場合
--    IF ( ir_get_data.lot_ctl = gc_lot_ctl_n ) THEN
--
--      or_temp_tab.lot_no        := NULL ;   -- ロット番号
--      or_temp_tab.product_date  := NULL ;   -- 製造日
--      or_temp_tab.use_by_date   := NULL ;   -- 賞味期限
--      or_temp_tab.original_char := NULL ;   -- 固有記号
--      or_temp_tab.lot_status    := NULL ;   -- 品質
--      or_temp_tab.quant_r := ir_get_data.quant_r ;  -- 依頼数
--      or_temp_tab.quant_i := ir_get_data.quant_i ;  -- 入庫数
--      or_temp_tab.quant_o := ir_get_data.quant_o ;  -- 出庫数
--
    -- ロット管理品の場合
--    ELSIF ( ir_get_data.lot_ctl = gc_lot_ctl_y ) THEN
-- del end ver1.1
-- 2008/07/24 A.Shiina v1.7 ADD Start
--
    -- 変数初期化
    ln_cnt := 0;
--
    -- 移動ロット詳細アドオン存在チェック
    SELECT  COUNT(1)
    INTO    ln_cnt
    FROM    xxinv_mov_lot_details   xmld    -- 移動ロット詳細アドオン
    WHERE   xmld.document_type_code = DECODE( ir_get_data.order_type
                                            ,gc_sp_class_ship, gc_doc_type_ship
                                            ,gc_sp_class_prov, gc_doc_type_prov
                                            ,gc_sp_class_move, gc_doc_type_move )
    AND   xmld.mov_line_id          = ir_get_data.order_line_id
    AND   xmld.lot_id               = ir_get_data.lot_id
    ;
--
-- 2008/07/24 A.Shiina v1.7 ADD End
    -- ロット情報取得
    BEGIN
-- 2008/07/24 A.Shiina v1.7 ADD Start
    -- 移動ロット詳細アドオンに存在する場合
      IF (ln_cnt > 0) THEN
-- 2008/07/24 A.Shiina v1.7 ADD End
--
        --SELECT                                                             -- 2008/12/03 本番障害#333 Del
        SELECT  /*+ leading(xmld ilm gic mcb) use_nl(xmld ilm gic mcb) */    -- 2008/12/03 本番障害#333 Add
               --ilm.lot_no                                                  -- del ver1.1
               xmld.lot_no                                                   -- add ver1.1
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
              ,ilm.attribute2
              ,FND_DATE.CANONICAL_TO_DATE( ilm.attribute3 )
              ,xlv.meaning
-- mod satart ver1.1
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_inst THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_dlvr THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
--              ,SUM( CASE
--                      WHEN xmld.record_type_code = gc_rec_type_stck THEN xmld.actual_quantity
--                      ELSE 0
--                    END )
              --***************************************************************************
              --*  指示ロット（依頼数）
              --***************************************************************************
              ,SUM( CASE
                 --WHEN (xmld.record_type_code = gc_rec_type_inst) THEN        2008/11/17 統合指摘#651 Del
                 -- 2008/11/17 統合指摘#651 Add Start ------------------------------
                 --********************************
                 --*  指示なし実績
                 --********************************
                 WHEN (xmld.record_type_code = gc_rec_type_inst)
                   AND (ir_get_data.no_instr_actual = gc_yn_div_y) THEN 
                 -- 2008/11/17 統合指摘#651 Add End --------------------------------
-- mod start ver1.3
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- 業務種別が出荷
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')               -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                         -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- 換算する
---- mod start ver1.2
----                              (xmld.actual_quantity/ir_get_data.num_of_cases)
--                                  ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
---- mod end ver1.2
--
                           --ROUND((NVL(xmld.actual_quantity, ir_get_data.quant_r)        -- 2008/10/20 課題T_S_486 Del
                           --        /ir_get_data.num_of_cases),3)                        -- 2008/10/20 課題T_S_486 Del
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)       -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                         ELSE
                           -- 換算しない
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              xmld.actual_quantity
--
                           --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 課題T_S_486 Del
                           ir_get_data.quant_r                              -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- 業務種別が支給
                       -- 換算しない
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                            xmld.actual_quantity
--
                       --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 課題T_S_486 Del
                       ir_get_data.quant_r                              -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                     ELSE   -- 業務種別が出荷・支給以外
                       CASE 
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                               AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- 商品区分がドリンク、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')             -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                       -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- 換算する
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                                  ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                           --ROUND((NVL(xmld.actual_quantity, ir_get_data.quant_r)             -- 2008/10/20 課題T_S_486 Del
                           --  /ir_get_data.num_of_cases),3)                                   -- 2008/10/20 課題T_S_486 Del
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)            -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                         ELSE
                           -- 換算しない
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              xmld.actual_quantity
--
                           --NVL(xmld.actual_quantity, ir_get_data.quant_r) -- 2008/10/20 課題T_S_486 Del
                           ir_get_data.quant_r                              -- 2008/10/20 課題T_S_486 Add
--
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                       END
                   END
-- mod end ver1.3
--
                 -- 2008/11/17 統合指摘#651 Add Start --------------------------------------------------------
                 --****************************************
                 --*  指示あり実績の場合(指示ロットあり)
                 --****************************************
                 WHEN (xmld.record_type_code = gc_rec_type_inst)
                   AND (ir_get_data.no_instr_actual = gc_yn_div_n)
                 THEN
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- 業務種別が出荷
                       CASE
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- 換算する
                           ROUND(xmld.actual_quantity / ir_get_data.num_of_cases, 3)
--
                         ELSE   -- 換算しない
                            xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- 業務種別が支給の場合、換算しない
                       xmld.actual_quantity
--
                     ELSE     -- 業務種別が出荷・支給以外
                       CASE
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- 商品区分がドリンク、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- 換算する
                           ROUND(xmld.actual_quantity / ir_get_data.num_of_cases, 3)
--
                         ELSE  -- 換算しない
                           xmld.actual_quantity
                       END
                   END
--
                 --****************************************
                 --*  指示あり実績の場合(指示ロットなし)
                 --****************************************
                 WHEN (ir_get_data.no_instr_actual = gc_yn_div_n)   -- 指示あり実績
                   AND (ir_get_data.lot_inst_cnt = 0)               -- 指示ロットが０件
                   AND (ir_get_data.row_num = 1)                    -- ロット割れの場合は最初のロットにのみ出力する
                 THEN
                   CASE
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- 業務種別が出荷
                       CASE
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- 換算する
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)
--
                         ELSE  -- 換算しない
                            ir_get_data.quant_r
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- 業務種別が支給の場合、換算しない
                       ir_get_data.quant_r
--
                     ELSE     -- 業務種別が出荷・支給以外
                       CASE
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- 商品区分がドリンク、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
                           -- 換算する
                           ROUND(ir_get_data.quant_r / ir_get_data.num_of_cases, 3)
--
                         ELSE   -- 換算しない
                           ir_get_data.quant_r
                       END
                   END
                   -- 2008/11/17 統合指摘#651 Add End ---------------------------------------------------------
--
                 ELSE 0
              END )
--
              --*********************************************
              --*  入庫実績ロット（入庫数）
              --**********************************************
              ,SUM( CASE
                 WHEN (xmld.record_type_code = gc_rec_type_dlvr) THEN
-- mod start ver1.3
                   CASE 
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- 業務種別が出荷
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- 換算する
                           --(xmld.actual_quantity/ir_get_data.num_of_cases)           -- del ver1.2
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)    -- add ver1.2
--
                         ELSE  -- 換算しない
                           xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- 業務種別が支給の場合、換算しない
                       xmld.actual_quantity
--
                     ELSE
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                               AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- 商品区分がドリンク、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- 換算する
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                         ELSE   -- 換算しない
                           xmld.actual_quantity
                       END
                   END
-- mod end ver1.3
                 ELSE 0
              END )
--
              --*********************************************
              --*  出庫実績ロット（出庫数）
              --**********************************************
              ,SUM( CASE
                 WHEN (xmld.record_type_code = gc_rec_type_stck) THEN
-- mod start ver1.3
                   CASE 
                     WHEN ir_get_data.order_type = gc_sp_class_ship THEN -- 業務種別が出荷
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL THEN -- 入出庫換算単位がNULLでない
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- 換算する
                           --(xmld.actual_quantity/ir_get_data.num_of_cases)          -- del ver1.2
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)   -- Add ver1.2
--
                         ELSE  -- 換算しない
                           xmld.actual_quantity
                       END
--
                     WHEN ir_get_data.order_type = gc_sp_class_prov THEN -- 業務種別が支給の場合、換算しない
                       xmld.actual_quantity
--
                     ELSE
                       CASE
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--                              WHEN xicv.item_class_code = '5'             -- 品目区分が製品
--                               AND ir_get_data.conv_unit IS NOT NULL      -- 入出庫換算単位がNULLでない
--                               AND ir_get_data.prod_class_code = '2' THEN -- 商品区分がドリンク
                         -- 品目区分が製品、かつ
                         -- 入出庫換算単位がNULLでない、かつ
                         -- 商品区分がドリンク、かつ
                         -- ケース入数が1以上の場合
                         --WHEN ((xicv.item_class_code = '5')                   -- 2008/12/03 本番障害#333 Del
                         WHEN ((mcb.segment1 = '5')                             -- 2008/12/03 本番障害#333 Add
                          AND (ir_get_data.conv_unit IS NOT NULL)
                          AND (ir_get_data.prod_class_code = '2')
                          AND (ir_get_data.num_of_cases > 0)) THEN
-- 2008/07/24 A.Shiina v1.7 UPDATE End
                           -- 換算する
                           ROUND((xmld.actual_quantity/ir_get_data.num_of_cases),3)
--
                         ELSE   -- 換算しない
                           xmld.actual_quantity
                       END
                   END
-- mod end ver1.3
                 ELSE 0
              END )
-- mod end ver1.1
        INTO   or_temp_tab.lot_no           -- ロット番号
              ,or_temp_tab.product_date     -- 製造日
              ,or_temp_tab.original_char    -- 固有記号
              ,or_temp_tab.use_by_date      -- 賞味期限
              ,or_temp_tab.lot_status       -- 品質
              ,or_temp_tab.quant_r          -- 依頼数
              ,or_temp_tab.quant_i          -- 入庫数
              ,or_temp_tab.quant_o          -- 出庫数
        FROM ic_lots_mst              ilm     -- OPMロットマスタ
            ,xxinv_mov_lot_details    xmld    -- 移動ロット詳細アドオン
            ,xxcmn_lookup_values_v    xlv     -- クイックコード情報VIEW
            --,xxcmn_item_categories4_v xicv    -- ＯＰＭ品目カテゴリ割当情報VIEW4  -- add ver1.1 -- 2008/12/03 本番障害#333 Del
            ,gmi_item_categories      gic                                                         -- 2008/12/03 本番障害#333 Add
            ,mtl_categories_b         mcb                                                         -- 2008/12/03 本番障害#333 Add
        -- del start ver1.1 ------------------------------------------------------
        --WHERE xlv.lookup_type         = gc_lookup_lot_status
        --AND   ilm.attribute23         = xlv.lookup_code
        --AND   xmld.actual_date        BETWEEN gr_param.date_from
        --                             AND     NVL( gr_param.date_to, xmld.actual_date )
        -- del end ver1.1 --------------------------------------------------------
        -- add start ver1.1 ------------------------------------------------------
        WHERE xlv.lookup_type(+)      = gc_lookup_lot_status
        AND   ilm.attribute23         = xlv.lookup_code(+)
        -- del start ver1.2-------------------------------
        --AND ((xmld.actual_date IS NULL)
        --      OR
        --     ((xmld.actual_date IS NOT NULL)
        --       AND
        --       (xmld.actual_date      BETWEEN gr_param.date_from
        --                              AND     NVL( gr_param.date_to, xmld.actual_date ))))
        -- del end ver1.2---------------------------------
        -- add end ver1.1 --------------------------------------------------------
        AND   xmld.document_type_code = DECODE( ir_get_data.order_type
                                               ,gc_sp_class_ship, gc_doc_type_ship
                                               ,gc_sp_class_prov, gc_doc_type_prov
                                               ,gc_sp_class_move, gc_doc_type_move )
        AND   xmld.mov_line_id        = ir_get_data.order_line_id
        AND   xmld.lot_id             = ir_get_data.lot_id      -- add ver1.2
        AND   ilm.lot_id              = xmld.lot_id
        AND   ilm.item_id             = xmld.item_id
        --AND   ilm.item_id             = xicv.item_id            -- add ver1.1  -- 2008/12/03 本番障害#333 Del
        AND   ilm.item_id             = gic.item_id                              -- 2008/12/03 本番障害#333 Add
        AND   gic.category_set_id     = cn_item_class_id                         -- 2008/12/03 本番障害#333 Add
        AND   gic.category_id         =mcb.category_id                           -- 2008/12/03 本番障害#333 Add
        AND   ilm.item_id             = ir_get_data.item_id
        --GROUP BY ilm.lot_no                                   -- del ver1.1
        GROUP BY xmld.lot_no                                    -- add ver1.1
                ,ilm.attribute1
                ,ilm.attribute2
                ,ilm.attribute3
                ,xlv.meaning
        ;
--
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
        -- 業務種別が出荷
        IF (ir_get_data.order_type = gc_sp_class_ship) THEN
          -- 入出庫換算単位がNULLでない、かつ
          -- ケース入数が1以上の場合
          IF ((ir_get_data.conv_unit IS NOT NULL)
            AND (ir_get_data.num_of_cases > 0)) THEN
            or_temp_tab.quant_r := ROUND((ir_get_data.quant_r/ir_get_data.num_of_cases),3);
          ELSE
            or_temp_tab.quant_r := ir_get_data.quant_r ;
          END IF;
        -- 業務種別が支給
        ELSIF (ir_get_data.order_type = gc_sp_class_prov) THEN
          or_temp_tab.quant_r := ir_get_data.quant_r ;
        ELSE
          -- 入出庫換算単位がNULLでない、かつ
          -- 商品区分がドリンク、かつ
          -- ケース入数が1以上の場合
          IF ((ir_get_data.conv_unit IS NOT NULL)
            AND (ir_get_data.prod_class_code = '2')
            AND (ir_get_data.num_of_cases > 0)) THEN
            or_temp_tab.quant_r := ROUND((ir_get_data.quant_r/ir_get_data.num_of_cases),3);
          ELSE
            or_temp_tab.quant_r := ir_get_data.quant_r ;
          END IF;
        END IF;
--
        --***************************
        --*  入庫数
        --***************************
        or_temp_tab.quant_i := ir_get_data.quant_i ;
--
        --***************************
        --*  出庫数
        --***************************
        or_temp_tab.quant_o := ir_get_data.quant_o ;
--
      END IF;
-- 2008/07/24 A.Shiina v1.7 ADD End
-- 2008/07/24 A.Shiina v1.7 ADD Start
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        or_temp_tab.lot_no        := NULL ;
        or_temp_tab.product_date  := NULL ;
        or_temp_tab.use_by_date   := NULL ;
        or_temp_tab.original_char := NULL ;
        or_temp_tab.lot_status    := NULL ;
        or_temp_tab.quant_r       := 0 ;
        or_temp_tab.quant_i       := 0 ;
        or_temp_tab.quant_o       := 0 ;
      WHEN TOO_MANY_ROWS THEN
        or_temp_tab.lot_no        := NULL ;
        or_temp_tab.product_date  := NULL ;
        or_temp_tab.use_by_date   := NULL ;
        or_temp_tab.original_char := NULL ;
        or_temp_tab.lot_status    := NULL ;
        or_temp_tab.quant_r       := 0 ;
        or_temp_tab.quant_i       := 0 ;
        or_temp_tab.quant_o       := 0 ;
    END ;
--
-- del start ver1.1
--    END IF ;
-- del end ver1.1
--
-- 2008/07/24 A.Shiina v1.7 ADD Start
    -- 変数初期化
    lv_reserved_status := NULL;
-- 2008/07/24 A.Shiina v1.7 ADD End
--
    --------------------------------------------------
    -- 差異事由設定
    --------------------------------------------------
    -- 保留ステータス
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
/*  BEGIN
      SELECT DISTINCT  xsli.reserved_status
      INTO   lv_reserved_status
      FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
          ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
      WHERE xshi.header_id        = xsli.header_id
      AND   xshi.delivery_no      = ir_get_data.delivery_no   -- 配送Ｎｏ
      AND   xshi.order_source_ref = ir_get_data.request_no    -- 依頼Ｎｏ
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
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
             --,xshi.eos_data_type    -- 2008/10/17 変更要求#210対応 Del
      INTO    lv_reserved_status
             --,lv_eos_data_type      -- 2008/10/17 変更要求#210対応 Del
      FROM    xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
             ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
      WHERE  xshi.header_id        = xsli.header_id
      --AND    xshi.delivery_no  = ir_get_data.delivery_no   -- 配送Ｎｏ                                        2008/10/31 統合指摘#461 Del
      AND    NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- 配送Ｎｏ 2008/10/31 統合指摘#461 Add
      AND    xshi.order_source_ref = ir_get_data.request_no    -- 依頼Ｎｏ
      ;
--
      lv_eos_data_type := ir_get_data.order_type;   -- 2008/10/17 変更要求#210対応 Add
--
      IF ((lv_reserved_status = gc_reserved_status_y)
        AND (lv_eos_data_type IN (cv_eos_data_cd_200
                                 ,cv_eos_data_cd_210
                                 ,cv_eos_data_cd_215
                                 ,cv_eos_data_cd_220))) THEN
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
-- 2008/07/24 A.Shiina v1.7 UPDATE End
    ------------------------------
    -- 保留ステータス：「保留」
    ------------------------------
    IF ( lv_reserved_status = gc_reserved_status_y ) THEN
--
      IF ( ir_get_data.status IS NULL ) THEN -- 保留データの場合  2008/10/20 統合テスト障害#394(2) Add
--
        -- 2008/07/24 A.Shiina v1.7 UPDATE Start ----------------------------------------------
        --or_temp_tab.quant_r       := ir_get_data.quant_r ;  -- 依頼数
        --or_temp_tab.quant_i       := ir_get_data.quant_i ;  -- 入庫数
        --or_temp_tab.quant_o       := ir_get_data.quant_o ;  -- 出庫数
--
        or_temp_tab.quant_r       := 0 ;  -- 依頼数
--
        -- 出庫対象の場合
        IF (ln_quant_kbn = 1) THEN
          or_temp_tab.quant_i       := 0 ;                                              -- 入庫数
          or_temp_tab.quant_o       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- 出庫数
        -- 入庫対象の場合
        ELSIF (ln_quant_kbn = 2) THEN
          or_temp_tab.quant_i       := NVL(ir_get_data.quant_d, ir_get_data.quant_r) ;  -- 入庫数
          or_temp_tab.quant_o       := 0 ;                                              -- 出庫数
        END IF;
        -- 2008/07/24 A.Shiina v1.7 UPDATE End -----------------------------------------------
--
        -- ロット情報取得
        BEGIN
          SELECT xsli.lot_no
                ,xsli.designated_production_date
                ,xsli.use_by_date
                ,xsli.original_character
                ,NULL
          INTO   or_temp_tab.lot_no
                ,or_temp_tab.product_date
                ,or_temp_tab.use_by_date
                ,or_temp_tab.original_char
                ,or_temp_tab.lot_status         -- 品質
          FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
              ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
          WHERE xsli.line_id          = ir_get_data.order_line_id
          AND   xshi.header_id        = xsli.header_id
          --AND   xshi.delivery_no = ir_get_data.delivery_no  -- 配送Ｎｏ                                          2008/10/31 統合指摘#461 Del
          AND   NVL(xshi.delivery_no,gv_nvl_null_char) = NVL(ir_get_data.delivery_no,gv_nvl_null_char) -- 配送Ｎｏ 2008/10/31 統合指摘#461 Add
          AND   xshi.order_source_ref = ir_get_data.request_no    -- 依頼Ｎｏ
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            or_temp_tab.lot_no        := NULL ;
            or_temp_tab.product_date  := NULL ;
            or_temp_tab.use_by_date   := NULL ;
            or_temp_tab.original_char := NULL ;
            or_temp_tab.lot_status    := NULL ;
          WHEN TOO_MANY_ROWS THEN
            or_temp_tab.lot_no        := NULL ;
            or_temp_tab.product_date  := NULL ;
            or_temp_tab.use_by_date   := NULL ;
            or_temp_tab.original_char := NULL ;
            or_temp_tab.lot_status    := NULL ;
        END ;
--
      END IF;  -- 2008/10/20 統合テスト障害#394(2) Add
--
      or_temp_tab.reason := gc_reason_rsrv ;  -- 保留
--
    ELSE
      ------------------------------
      -- 出荷・支給の場合
      ------------------------------
      IF ( ir_get_data.order_type IN( gc_sp_class_ship
                                     ,gc_sp_class_prov ) ) THEN
        ------------------------------
        -- 締め済・受領済の場合
        ------------------------------
        IF ( ir_get_data.status IN( gc_req_status_s_cmpb             -- 出荷：締め済
                                   ,gc_req_status_p_cmpb ) ) THEN    -- 支給：受領済
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
        -- 出荷実績計上済の場合
        ------------------------------
        ELSIF ( ir_get_data.status IN( gc_req_status_s_cmpc             -- 出荷：出荷実績計上済
                                      ,gc_req_status_p_cmpc ) ) THEN    -- 支給：出荷実績計上済
          ------------------------------
          -- ヘッダーレベルのチェック
          ------------------------------
          -- 指示と実績の異なるレコードを取得する
          SELECT COUNT( xoha.order_header_id )
          INTO   ln_temp_cnt
          FROM   xxwsh_order_headers_all  xoha    -- 受注ヘッダアドオン
          WHERE (  xoha.career_id             <> xoha.result_freight_carrier_id       -- 運送業者
                OR xoha.shipping_method_code  <> xoha.result_shipping_method_code     -- 配送区分
                OR xoha.deliver_to_id         <> xoha.result_deliver_to_id            -- 出荷先
                OR xoha.schedule_ship_date    <> xoha.shipped_date                    -- 出荷日
                OR xoha.schedule_arrival_date <> xoha.arrival_date                )   -- 着荷日
          AND   xoha.latest_external_flag = gc_yn_div_y             -- 最新
          AND   xoha.request_no           = ir_get_data.request_no  -- 依頼Ｎｏ
          ;
          ------------------------------
          -- 指示と実績が異なる場合
          ------------------------------
          IF ( ln_temp_cnt > 0 ) THEN
--
            or_temp_tab.reason := gc_reason_diff ;  -- 依頼差
--
          ------------------------------
          -- 指示と実績が同一の場合
          ------------------------------
          ELSE
            ------------------------------
            -- 依頼数と出荷数が同一の場合
            ------------------------------
            IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
--
              or_temp_tab.reason        := NULL ;               -- 差異なし
--
            ------------------------------
            -- 依頼数と出荷数が異なる場合
            ------------------------------
            ELSE
--
              or_temp_tab.reason := gc_reason_diff ;  -- 依頼差
--
            END IF ;
--
          END IF ;
--
        END IF ;
--
      ------------------------------
      -- 移動の場合
      ------------------------------
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
              or_temp_tab.reason := gc_reason_ndel ;  -- 出庫未
--
            -- 出庫報告有の場合
            ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
              or_temp_tab.reason := gc_reason_nstc ;  -- 入庫未
--
            -- 入出庫報告有の場合
            ELSIF ( ir_get_data.status = gc_mov_status_dsr ) THEN
              or_temp_tab.reason := gc_reason_diff ;  -- 依頼差
--
            END IF ;
--
          ------------------------------
          -- 指示と実績が同一の場合
          ------------------------------
          ELSE
            ------------------------------
            -- 入庫報告有の場合
            ------------------------------
            IF ( ir_get_data.status = gc_mov_status_stc ) THEN
-- mod start ver1.2
              -- 依頼数と入庫数が同じ場合
--              IF ( or_temp_tab.quant_r = or_temp_tab.quant_i ) THEN
--                or_temp_tab.reason        := NULL ;               -- 差異なし
--
              -- 依頼数と入庫数が異なる場合
--              ELSE
--                or_temp_tab.reason := gc_reason_ndel ;  -- 出庫未
--
--              END IF ;
              or_temp_tab.reason := gc_reason_ndel ;  -- 出庫未
-- mod end ver1.2
--
            ------------------------------
            -- 出庫報告有の場合
            ------------------------------
            ELSIF ( ir_get_data.status = gc_mov_status_del ) THEN
-- mod start ver1.2
              -- 依頼数と出庫数が同じ場合
--              IF ( or_temp_tab.quant_r = or_temp_tab.quant_o ) THEN
--                or_temp_tab.reason        := NULL ;               -- 差異なし
--
              -- 依頼数と出庫数が異なる場合
--              ELSE
--                or_temp_tab.reason := gc_reason_nstc ;  -- 入庫未
--
--              END IF ;
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
   * Procedure Name   : prc_create_ship_data
   * Description      : 出荷・支給データ抽出処理
   ************************************************************************************************/
  PROCEDURE prc_create_ship_data
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'prc_create_ship_data' ; -- プログラム名
--
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 本番障害#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 本番障害#333 Add
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lr_get_data       rec_get_data ;        -- 抽出データ格納用レコード変数
    lr_temp_tab       rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
--
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
    /*
    -- 指示・実績データ取得カーソル
    CURSOR cu_main
    IS
    --***************************************
    --* 指示
    --***************************************
-- mod start ver1.1
--      SELECT xil.segment1                 AS location_code      -- 出庫倉庫コード
      SELECT xoha.deliver_from            AS location_code      -- 出庫倉庫コード
            --,xil.description              AS location_name      -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20) AS location_name      -- 出庫倉庫名称  2008/10/10 統合テスト障害#338 Add
            ,xoha.schedule_ship_date      AS ship_date          -- 出庫日
            ,xoha.schedule_arrival_date   AS arvl_date          -- 入庫日
            ,xoha.head_sales_branch       AS head_sales_branch  -- 検索条件：管轄拠点
--            ,xoha.po_no                   AS po_no              -- 検索条件：管轄拠点
-- mod end ver1.1
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN xoha.deliver_to_id
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                          AS deliver_id         -- 検索条件：配送先
            ,xoha.career_id               AS career_id          -- 検索条件：運送業者
            ,xoha.shipping_method_code    AS ship_method_code   -- 検索条件：配送区分
            ,otta.attribute1              AS order_type         -- 業務種別（コード）
            ,xoha.delivery_no             AS delivery_no        -- 配送Ｎｏ
            ,xoha.request_no              AS request_no         -- 依頼Ｎｏ
            ,xola.order_line_id           AS order_line_id      -- 検索条件：明細ＩＤ
            ,ximv.item_id                 AS item_id            -- 検索条件：品目ＩＤ
            ,ximv.item_no                 AS item_code          -- 品目コード
            ,ximv.item_short_name         AS item_name          -- 品目名称
            ,ximv.lot_ctl                 AS lot_ctl            -- 検索条件：ロット使用
            --,NVL( xola.based_request_quantity, 0 )  AS quant_r  -- 依頼数（ロット管理外）--2008/10/17 統合テスト障害#146 Del
            ,NVL( xola.quantity, 0 )  AS quant_r                -- 依頼数（ロット管理外）  --2008/10/17 統合テスト障害#146 Add
            ,NVL( xola.ship_to_quantity      , 0 )  AS quant_i  -- 入庫数（ロット管理外）
            ,NVL( xola.shipped_quantity      , 0 )  AS quant_o  -- 出庫数（ロット管理外）
            ,xoha.req_status              AS status             -- ヘッダステータス
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ロットID
            ,ximv.conv_unit               AS conv_unit             -- 入出庫換算単位
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- ケース入数
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xoha.freight_charge_class    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code   AS complusion_output_kbn -- 強制出力区分       -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
-- add end ver1.2
-- 2008/11/17 統合指摘#651 Add Start ------------------------------------------------------
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code IN ( gc_doc_type_ship, gc_doc_type_prov)
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xoha.request_no
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num            -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End --------------------------------------------------------
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld       -- 移動ロット詳細アドオン
            WHERE  xmld.document_type_code IN( gc_doc_type_ship, gc_doc_type_prov)
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld
-- add end ver1.2
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxcmn_item_locations2_v    xil       -- ＯＰＭ保管場所マスタ
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
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
      AND   xola.shipping_item_code = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細アドオン
      ----------------------------------------------------------------------------------------------
      AND   NVL( xola.delete_flag, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
      AND   xoha.order_header_id                 = xola.order_header_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xola.order_line_id
      AND   xmld.mov_line_id(+)        = xola.order_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- パラメータ条件．出庫元
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xoha.deliver_from_id  = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      ----------------------------------------------------------------------------------------------
      AND   otta.order_category_code  = gc_order_cat_o
      AND   otta.attribute1          IN( gc_sp_class_ship     -- 出荷依頼
                                        ,gc_sp_class_prov )   -- 支給依頼
      AND   xoha.order_type_id        = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ----------------------------------------------------------------------------------------------
      AND   xoha.req_status IN( gc_req_status_s_cmpb    -- 出荷：締済み
                               ,gc_req_status_s_cmpc    -- 出荷：出荷実績計上済
                               ,gc_req_status_p_cmpb    -- 支給：受領済
                               ,gc_req_status_p_cmpc )  -- 支給：出荷実績計上済
      AND   xoha.latest_external_flag = gc_yn_div_y     -- 最新
      -- パラメータ条件．指示部署
      AND   xoha.instruction_dept = NVL( gr_param.dept_code, xoha.instruction_dept )
      -- パラメータ条件．出庫形態
      AND   xoha.order_type_id    = NVL( gr_param.deliver_type_id, xoha.order_type_id )
      -- パラメータ条件．依頼Ｎｏ
      AND   xoha.request_no       = NVL( gr_param.request_no, xoha.request_no )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND   xoha.deliver_from     = NVL( gr_param.deliver_from, xoha.deliver_from )
-- add end ver1.1
      -- パラメータ条件．出庫日FromTo
      AND   xoha.schedule_ship_date BETWEEN gr_param.date_from
                                    AND     NVL( gr_param.date_to, xoha.schedule_ship_date )
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xoha.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xoha.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xoha.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xoha.career_id,gn_nvl_null_num)  =    xcv.party_id(+)
      AND   xoha.schedule_ship_date             >=    xcv.start_date_active(+)
      AND   xoha.schedule_ship_date             <=    xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
--
      UNION
      --***************************************
      --* 実績
      --***************************************
-- mod start ver1.1
      SELECT xoha.deliver_from                  AS location_code    -- 出庫倉庫コード
--      SELECT xil.segment1                       AS location_code    -- 出庫倉庫コード
            --,xil.description                    AS location_name    -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)      AS location_name    -- 出庫倉庫名称   2008/10/10 統合テスト障害#338 Add
            ,NVL( xoha.shipped_date
                 ,xoha.schedule_ship_date    )  AS ship_date        -- 出庫日
            ,NVL( xoha.arrival_date
                 ,xoha.schedule_arrival_date )  AS arvl_date        -- 入庫日
            ,xoha.head_sales_branch             AS head_sales_branch -- 検索条件：管轄拠点
--            ,xoha.po_no                         AS po_no            -- 検索条件：管轄拠点
-- mod end ver1.1
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                                AS deliver_id       -- 検索条件：配送先
            ,NVL( xoha.result_freight_carrier_id
                 ,xoha.career_id )              AS career_id        -- 検索条件：運送業者
            ,NVL( xoha.result_shipping_method_code
                 ,xoha.shipping_method_code )   AS ship_method_code -- 検索条件：配送区分
            ,otta.attribute1                    AS order_type       -- 業務種別（コード）
            ,xoha.delivery_no                   AS delivery_no      -- 配送Ｎｏ
            ,xoha.request_no                    AS request_no       -- 依頼Ｎｏ
            ,xola.order_line_id                 AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                       AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                       AS item_code        -- 品目コード
            ,ximv.item_short_name               AS item_name        -- 品目名称
            ,ximv.lot_ctl                       AS lot_ctl          -- 検索条件：ロット使用
            --,NVL( xola.based_request_quantity, 0 )  AS quant_r      -- 依頼数（ロット管理外）--2008/10/17 統合テスト障害#146 Del
            ,NVL( xola.quantity, 0 )  AS quant_r                    -- 依頼数（ロット管理外）  --2008/10/17 統合テスト障害#146 Add
            ,NVL( xola.ship_to_quantity      , 0 )  AS quant_i      -- 入庫数（ロット管理外）
            ,NVL( xola.shipped_quantity      , 0 )  AS quant_o      -- 出庫数（ロット管理外）
            ,xoha.req_status                    AS status           -- ヘッダステータス
-- add start ver1.2
            ,xmld.lot_id                        AS lot_id           -- ロットID
            ,ximv.conv_unit                     AS conv_unit        -- 入出庫換算単位
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases  -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases)       AS num_of_cases  -- ケース入数
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xoha.freight_charge_class          AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code         AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分   -- 2008/10/31 統合指摘#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
-- add end ver1.2
-- 2008/11/17 統合指摘#651 Add Start ----------------------------------------------------------------
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code IN ( gc_doc_type_ship, gc_doc_type_prov)
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xoha.request_no
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End -----------------------------------------------------------------
      FROM xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
-- add start ver1.2
          ,(SELECT xmld.lot_id
                  ,xmld.mov_line_id
            FROM   xxinv_mov_lot_details  xmld   -- 移動ロット詳細アドオン
            WHERE  xmld.document_type_code IN( gc_doc_type_ship, gc_doc_type_prov)
            GROUP BY xmld.lot_id,xmld.mov_line_id)  xmld
-- add end ver1.2
          ,xxcmn_item_locations2_v    xil       -- ＯＰＭ保管場所マスタ
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
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
      AND   xola.shipping_item_code = ximv.item_no
      ----------------------------------------------------------------------------------------------
      -- 受注明細アドオン
      ----------------------------------------------------------------------------------------------
      AND   NVL( xola.delete_flag, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
      AND   xoha.order_header_id                 = xola.order_header_id
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xola.order_line_id
      AND   xmld.mov_line_id(+)        = xola.order_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
-- del start ver1.1
      -- パラメータ条件．出庫元
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xoha.deliver_from_id  = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- 受注タイプ
      ----------------------------------------------------------------------------------------------
      AND   otta.order_category_code  = gc_order_cat_o
      AND   otta.attribute1          IN( gc_sp_class_ship     -- 出荷依頼
                                        ,gc_sp_class_prov )   -- 支給依頼
      AND   xoha.order_type_id        = otta.transaction_type_id
      ----------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオン
      ----------------------------------------------------------------------------------------------
      AND   xoha.req_status IN( gc_req_status_s_cmpb    -- 出荷：締済み
                               ,gc_req_status_s_cmpc    -- 出荷：出荷実績計上済
                               ,gc_req_status_p_cmpb    -- 支給：受領済
                               ,gc_req_status_p_cmpc )  -- 支給：出荷実績計上済
      AND   xoha.latest_external_flag = gc_yn_div_y     -- 最新
      -- パラメータ条件．指示部署
      AND   xoha.instruction_dept = NVL( gr_param.dept_code, xoha.instruction_dept )
      -- パラメータ条件．出庫形態
      AND   xoha.order_type_id    = NVL( gr_param.deliver_type_id, xoha.order_type_id )
      -- パラメータ条件．依頼Ｎｏ
      AND   xoha.request_no       = NVL( gr_param.request_no, xoha.request_no )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND   xoha.deliver_from     = NVL( gr_param.deliver_from, xoha.deliver_from )
-- add end ver1.1
--
      -- 2008/11/13 統合指摘#603 Del Start ---------------------------------------------
      ---- パラメータ条件．出庫日FromTo
      --AND   xoha.schedule_ship_date BETWEEN gr_param.date_from
      --                              AND     NVL( gr_param.date_to, xoha.schedule_ship_date )
      -- 2008/11/13 統合指摘#603 Del End ------------------------------------------------
      -- 2008/11/13 統合指摘#603 Add Start ---------------------------------------------
      -- パラメータ条件．出庫日FromTo
      AND   xoha.shipped_date BETWEEN gr_param.date_from
                                    AND     NVL( gr_param.date_to, xoha.shipped_date )
      -- 2008/11/13 統合指摘#603 Add End ------------------------------------------------
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xoha.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xoha.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xoha.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xoha.career_id,gn_nvl_null_num)  =   xcv.party_id(+)
      AND   xoha.shipped_date             >=   xcv.start_date_active(+)
      AND   xoha.shipped_date             <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
    ;
    */
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Del End
    ---------------------------------------------------------------------------------------------------------------------
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Add Start
    ---------------------------------------------------------------------------------------------------------------------
    -- 指示・実績データ取得カーソル
    CURSOR cu_main
    IS
    --***************************************
    --* 指示
    --***************************************
    SELECT trn.location_code             AS location_code         -- 出庫倉庫コード
          ,trn.location_name             AS location_name         -- 出庫倉庫名称
          ,trn.ship_date                 AS ship_date             -- 出庫日
          ,trn.arvl_date                 AS arvl_date             -- 入庫日
          ,trn.head_sales_branch         AS head_sales_branch     -- 検索条件：管轄拠点
          ,trn.deliver_id                AS deliver_id            -- 検索条件：配送先
          ,trn.career_id                 AS career_id             -- 検索条件：運送業者
          ,trn.ship_method_code          AS ship_method_code      -- 検索条件：配送区分
          ,trn.order_type                AS order_type            -- 業務種別（コード）
          ,trn.delivery_no               AS delivery_no           -- 配送Ｎｏ
          ,trn.request_no                AS request_no            -- 依頼Ｎｏ
          ,trn.order_line_id             AS order_line_id         -- 検索条件：明細ＩＤ
          ,trn.item_id                   AS item_id               -- 検索条件：品目ＩＤ
          ,trn.item_code                 AS item_code             -- 品目コード
          ,trn.item_name                 AS item_name             -- 品目名称
          ,trn.lot_ctl                   AS lot_ctl               -- 検索条件：ロット使用
          ,trn.quant_r                   AS quant_r               -- 依頼数
          ,trn.quant_i                   AS quant_i               -- 入庫数
          ,trn.quant_o                   AS quant_o               -- 出庫数
          ,trn.status                    AS status                -- ヘッダステータス
          ,trn.lot_id                    AS lot_id                -- ロットID
          ,trn.conv_unit                 AS conv_unit             -- 入出庫換算単位
          ,trn.num_of_cases              AS num_of_cases          -- ケース入数
          ,trn.freight_charge_code       AS freight_charge_code   -- 運賃区分
          ,trn.complusion_output_kbn     AS complusion_output_kbn -- 強制出力区分
          ,trn.no_instr_actual           AS no_instr_actual       -- 指示なし実績:'Y' 指示あり実績:'N'
          ,trn.lot_inst_cnt              AS lot_inst_cnt          -- 指示ロットの件数
          ,ROW_NUMBER() OVER(PARTITION BY trn.request_no,trn.item_code order by trn.lot_id) AS row_num -- 依頼No・品目ごとにロットID昇順で1から採番
      FROM (
        SELECT /*+ leading (xoha xola otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xoha xola otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xoha.deliver_from             AS location_code      -- 出庫倉庫コード
            ,SUBSTRB(xil.description,1,20) AS location_name      -- 出庫倉庫名称
            ,xoha.schedule_ship_date      AS ship_date          -- 出庫日
            ,xoha.schedule_arrival_date   AS arvl_date          -- 入庫日
            ,xoha.head_sales_branch       AS head_sales_branch  -- 検索条件：管轄拠点
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN xoha.deliver_to_id
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                          AS deliver_id         -- 検索条件：配送先
            ,xoha.career_id               AS career_id          -- 検索条件：運送業者
            ,xoha.shipping_method_code    AS ship_method_code   -- 検索条件：配送区分
            ,otta.attribute1              AS order_type         -- 業務種別（コード）
            ,xoha.delivery_no             AS delivery_no        -- 配送Ｎｏ
            ,xoha.request_no              AS request_no         -- 依頼Ｎｏ
            ,xola.order_line_id           AS order_line_id      -- 検索条件：明細ＩＤ
            ,iimb.item_id                 AS item_id            -- 検索条件：品目ＩＤ
            ,iimb.item_no                 AS item_code          -- 品目コード
            ,ximb.item_short_name         AS item_name          -- 品目名称
            ,iimb.lot_ctl                 AS lot_ctl            -- 検索条件：ロット使用
            ,NVL(xola.quantity, 0)         AS quant_r            -- 依頼数
            ,NVL(xola.ship_to_quantity, 0) AS quant_i            -- 入庫数
            ,NVL(xola.shipped_quantity, 0) AS quant_o            -- 出庫数
            ,xoha.req_status              AS status              -- ヘッダステータス
            ,xmld.lot_id                  AS lot_id              -- ロットID
            ,iimb.attribute24             AS conv_unit           -- 入出庫換算単位
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- ケース入数
            ,xoha.freight_charge_class    AS freight_charge_code -- 運賃区分
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- 指示ロットの件数
        FROM
           xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxinv_mov_lot_details      xmld
          ,ic_item_mst_b              iimb
          ,xxcmn_item_mst_b           ximb
          ,gmi_item_categories        gic1
          ,mtl_categories_b           mcb1
          ,gmi_item_categories        gic2
          ,mtl_categories_b           mcb2
          ,xxcmn_item_locations2_v    xil
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
        WHERE  xoha.schedule_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xoha.schedule_ship_date)   -- パラメータ条件．出庫日FromTo
        AND   xoha.req_status IN( gc_req_status_s_cmpb    -- 出荷：締済み
                               ,gc_req_status_s_cmpc    -- 出荷：出荷実績計上済
                               ,gc_req_status_p_cmpb    -- 支給：受領済
                               ,gc_req_status_p_cmpc )  -- 支給：出荷実績計上済
        AND    xoha.latest_external_flag = gc_yn_div_y
        AND    xoha.instruction_dept     = NVL(gr_param.dept_code, xoha.instruction_dept)    -- パラメータ条件．指示部署
        AND    xoha.order_type_id        = NVL(gr_param.deliver_type_id, xoha.order_type_id) -- パラメータ条件．出庫形態
        AND    xoha.request_no           = NVL(gr_param.request_no,xoha.request_no)          -- パラメータ条件．依頼Ｎｏ
        AND    xoha.deliver_from         = NVL(gr_param.deliver_from,xoha.deliver_from)      -- パラメータ条件．出庫元
        AND    xoha.order_header_id       = xola.order_header_id
        AND    NVL(xola.delete_flag,gc_yn_div_n) = gc_yn_div_n
        AND    xoha.order_type_id        = otta.transaction_type_id
        AND    otta.order_category_code  = gc_order_cat_o
        AND    otta.attribute1          IN (gc_sp_class_ship     -- 出荷依頼
                                           ,gc_sp_class_prov)    -- 支給依頼
        AND    xmld.mov_line_id(+)       = xola.order_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code IN (gc_doc_type_ship
                                            ,gc_doc_type_prov))
               )
        AND    xola.shipping_item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- パラメータ条件．商品区分
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- パラメータ条件．品目区分
        AND    xoha.deliver_from_id       = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND    (
                  ((gr_param.block_01  IS NULL) AND   -- パラメータ条件．ブロック１・２・３が全てNULLの場合
                   (gr_param.block_02  IS NULL) AND
                   (gr_param.block_03  IS NULL)
                  )
              OR  (xil.distribution_block     IN(gr_param.block_01   -- パラメータ条件．ブロック１・２・３の何れかが指定された場合
                                                 ,gr_param.block_02
                                                 ,gr_param.block_03)
                  )
               )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- パラメータ条件．オンライン区分
        AND    NVL(xoha.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xoha.schedule_ship_date >= xcv.start_date_active(+)
        AND    xoha.schedule_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xoha.deliver_from
                ,SUBSTRB(xil.description,1,20)
                ,xoha.schedule_ship_date
                ,xoha.schedule_arrival_date
                ,xoha.head_sales_branch
                ,CASE otta.attribute1
                   WHEN gc_sp_class_ship THEN xoha.deliver_to_id
                   WHEN gc_sp_class_prov THEN xoha.vendor_site_id
                 END
                ,xoha.career_id
                ,xoha.shipping_method_code
                ,otta.attribute1
                ,xoha.delivery_no
                ,xoha.request_no
                ,xola.order_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xola.quantity,0)
                ,NVL(xola.ship_to_quantity, 0)
                ,NVL(xola.shipped_quantity,0)
                ,xoha.req_status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xoha.freight_charge_class
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n)
--
        UNION
        --***************************************
        --* 実績
        --***************************************
        SELECT /*+ leading (xoha xola otta iimb gic1 mcb1 gic2 mcb2) use_nl(xoha xola otta iimb gic1 mcb1 gic2 mcb2) */
             xoha.deliver_from                  AS location_code     -- 出庫倉庫コード
            ,SUBSTRB(xil.description,1,20)      AS location_name     -- 出庫倉庫名称
            ,NVL( xoha.shipped_date
                 ,xoha.schedule_ship_date    )  AS ship_date         -- 出庫日
            ,NVL( xoha.arrival_date
                 ,xoha.schedule_arrival_date )  AS arvl_date         -- 入庫日
            ,xoha.head_sales_branch             AS head_sales_branch -- 検索条件：管轄拠点
            ,CASE otta.attribute1
              WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
              WHEN gc_sp_class_prov THEN xoha.vendor_site_id
             END                                AS deliver_id       -- 検索条件：配送先
            ,NVL( xoha.result_freight_carrier_id
                 ,xoha.career_id )              AS career_id        -- 検索条件：運送業者
            ,NVL( xoha.result_shipping_method_code
                 ,xoha.shipping_method_code )   AS ship_method_code -- 検索条件：配送区分
            ,otta.attribute1                    AS order_type       -- 業務種別（コード）
            ,xoha.delivery_no                   AS delivery_no      -- 配送Ｎｏ
            ,xoha.request_no                    AS request_no       -- 依頼Ｎｏ
            ,xola.order_line_id                 AS order_line_id    -- 検索条件：明細ＩＤ
            ,iimb.item_id                       AS item_id          -- 検索条件：品目ＩＤ
            ,iimb.item_no                       AS item_code        -- 品目コード
            ,ximb.item_short_name               AS item_name        -- 品目名称
            ,iimb.lot_ctl                       AS lot_ctl          -- 検索条件：ロット使用
            ,NVL( xola.quantity, 0 )            AS quant_r          -- 依頼数
            ,NVL( xola.ship_to_quantity , 0 )   AS quant_i          -- 入庫数
            ,NVL( xola.shipped_quantity , 0 )   AS quant_o          -- 出庫数
            ,xoha.req_status                    AS status           -- ヘッダステータス
            ,xmld.lot_id                        AS lot_id           -- ロットID
            ,iimb.attribute24                   AS conv_unit        -- 入出庫換算単位
            ,TO_NUMBER(iimb.attribute11)        AS num_of_cases     -- ケース入数
            ,xoha.freight_charge_class          AS freight_charge_code   -- 運賃区分
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分
            ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,COUNT(xmld.lot_id)                 AS lot_inst_cnt        -- 指示ロットの件数
        FROM
           xxwsh_order_headers_all    xoha      -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola      -- 受注明細アドオン
          ,oe_transaction_types_all   otta      -- 受注タイプ
          ,xxinv_mov_lot_details      xmld
          ,ic_item_mst_b              iimb
          ,xxcmn_item_mst_b           ximb
          ,gmi_item_categories        gic1
          ,mtl_categories_b           mcb1
          ,gmi_item_categories        gic2
          ,mtl_categories_b           mcb2
          ,xxcmn_item_locations2_v    xil
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
        WHERE  xoha.shipped_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xoha.shipped_date)   -- パラメータ条件．出庫日FromTo
        AND   xoha.req_status IN( gc_req_status_s_cmpb    -- 出荷：締済み
                               ,gc_req_status_s_cmpc    -- 出荷：出荷実績計上済
                               ,gc_req_status_p_cmpb    -- 支給：受領済
                               ,gc_req_status_p_cmpc )  -- 支給：出荷実績計上済
        AND    xoha.latest_external_flag = gc_yn_div_y
        AND    xoha.instruction_dept     = NVL(gr_param.dept_code, xoha.instruction_dept)    -- パラメータ条件．指示部署
        AND    xoha.order_type_id        = NVL(gr_param.deliver_type_id, xoha.order_type_id) -- パラメータ条件．出庫形態
        AND    xoha.request_no           = NVL(gr_param.request_no,xoha.request_no)          -- パラメータ条件．依頼Ｎｏ
        AND    xoha.deliver_from         = NVL(gr_param.deliver_from,xoha.deliver_from)      -- パラメータ条件．出庫元
        AND    xoha.order_header_id       = xola.order_header_id
        AND    NVL(xola.delete_flag,gc_yn_div_n) = gc_yn_div_n
        AND    xoha.order_type_id        = otta.transaction_type_id
        AND    otta.order_category_code  = gc_order_cat_o
        AND    otta.attribute1          IN (gc_sp_class_ship     -- 出荷依頼
                                           ,gc_sp_class_prov)    -- 支給依頼
        AND    xmld.mov_line_id(+)       = xola.order_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code IN (gc_doc_type_ship
                                            ,gc_doc_type_prov))
               )
        AND    xola.shipping_item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- パラメータ条件．商品区分
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- パラメータ条件．品目区分
        AND    xoha.deliver_from_id       = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
        AND    (
                  ((gr_param.block_01  IS NULL) AND   -- パラメータ条件．ブロック１・２・３が全てNULLの場合
                   (gr_param.block_02  IS NULL) AND
                   (gr_param.block_03  IS NULL)
                  )
              OR  (xil.distribution_block     IN(gr_param.block_01   -- パラメータ条件．ブロック１・２・３の何れかが指定された場合
                                                 ,gr_param.block_02
                                                 ,gr_param.block_03)
                  )
               )
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- パラメータ条件．オンライン区分
        AND    NVL(xoha.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xoha.shipped_date >= xcv.start_date_active(+)
        AND    xoha.shipped_date <= xcv.end_date_active(+)
--
        GROUP BY xoha.deliver_from
                ,SUBSTRB(xil.description,1,20)
                ,NVL(xoha.shipped_date, xoha.schedule_ship_date)
                ,NVL(xoha.arrival_date, xoha.schedule_arrival_date)
                ,xoha.head_sales_branch
                ,CASE otta.attribute1
                   WHEN gc_sp_class_ship THEN NVL( xoha.result_deliver_to_id, xoha.deliver_to_id )
                   WHEN gc_sp_class_prov THEN xoha.vendor_site_id
                 END
                ,NVL(xoha.result_freight_carrier_id, xoha.career_id )
                ,NVL(xoha.result_shipping_method_code, xoha.shipping_method_code)
                ,otta.attribute1
                ,xoha.delivery_no
                ,xoha.request_no
                ,xola.order_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xola.quantity,0)
                ,NVL(xola.ship_to_quantity, 0)
                ,NVL(xola.shipped_quantity,0)
                ,xoha.req_status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xoha.freight_charge_class
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(xoha.schedule_ship_date,NULL,gc_yn_div_y,gc_yn_div_n)
      ) trn
    ;
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Add End
    ---------------------------------------------------------------------------------------------------------------------
--
    -- 保留データ取得
    CURSOR cu_reserv
    IS
      SELECT xil.segment1                     AS location_code    -- 出庫倉庫コード
            --,xil.description                  AS location_name    -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)    AS location_name    -- 出庫倉庫名称   2008/10/10 統合テスト障害#338 Add
            ,xshi.shipped_date                AS ship_date        -- 出庫日
            ,xshi.arrival_date                AS arvl_date        -- 入庫日
      -- 2008/12/06 Modify Start T.Miyata #516 依頼Noに紐付く管轄拠点があれば表示する。配送先を表示する。
-- mod start ver1.1
            , xshi.head_sales_branch            AS head_sales_branch -- 検索条件：管轄拠点
--            ,NULL                             AS po_no            -- 検索条件：管轄拠点
-- mod end ver1.1
--            ,xshi.party_site_code             AS deliver_id       -- 検索条件：配送先
            ,xpsv.party_site_id               AS deliver_id       -- 配送先
      -- 2008/12/06 Modify End T.Miyata #51
            ,xshi.freight_carrier_code        AS career_id        -- 検索条件：運送業者
            ,xshi.shipping_method_code        AS ship_method_code -- 検索条件：配送区分
            ,xshi.eos_data_type               AS order_type       -- 業務種別（コード）
            ,xshi.delivery_no                 AS delivery_no      -- 配送Ｎｏ
            ,xshi.order_source_ref            AS request_no       -- 依頼Ｎｏ
            ,xsli.line_id                     AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                     AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                     AS item_code        -- 品目コード
            ,ximv.item_short_name             AS item_name        -- 品目名称
            ,ximv.lot_ctl                     AS lot_ctl          -- 検索条件：ロット使用
            ,xsli.orderd_quantity             AS quant_r          -- 依頼数
            ,xsli.ship_to_quantity            AS quant_i          -- 入庫数
            ,xsli.shiped_quantity             AS quant_o          -- 出庫数
-- 2008/07/24 A.Shiina v1.7 ADD Start
            ,xsli.detailed_quantity           AS quant_d          -- 内訳数量(インタフェース用)
-- 2008/07/24 A.Shiina v1.7 ADD End
            ,NULL                             AS status           -- ヘッダステータス
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xshi.filler14                    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code       AS complusion_output_kbn -- 強制出力区分    -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分   -- 2008/10/31 統合指摘#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
          ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
          ,xxcmn_item_locations2_v    xil       -- ＯＰＭ保管場所マスタ
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW4
          -- 2008/12/06 Modify Start T.Miyata #516 依頼Noに紐付く管轄拠点があれば表示する。配送先、入庫先の表示
          ,xxcmn_party_sites_v        xpsv      -- 顧客サイトビュー
          -- 2008/12/06 Modify End T.Miyata #516
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
      WHERE
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ品目
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．商品区分
            xicv.prod_class_code    = NVL( gr_param.prod_div, xicv.prod_class_code )
      -- パラメータ条件．品目区分
      AND   xicv.item_class_code    = gr_param.item_div
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
-- del start ver1.1
      -- パラメータ条件．出庫元
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xshi.location_code    = xil.segment1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- ＩＦヘッダ
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_ship_k      -- 拠点出荷確定報告
                                   ,gc_eos_type_rpt_ship_y )    -- 有償出荷報告
      -- パラメータ条件．依頼Ｎｏ
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND xshi.location_code    = NVL( gr_param.deliver_from, xshi.location_code )
      -- パラメータ条件．指示部署
      AND xshi.report_post_code = NVL( gr_param.dept_code, xshi.report_post_code )
-- add end ver1.1
      -- パラメータ条件．出庫日FromTo
      AND   xshi.shipped_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.shipped_date )
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xshi.freight_carrier_code         =   xcv.party_number
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xshi.shipped_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xshi.shipped_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xshi.freight_carrier_code,gv_nvl_null_char)  =   xcv.party_number(+)
      AND   xshi.shipped_date                               >=   xcv.start_date_active(+)
      AND   xshi.shipped_date                               <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
      -- 2008/12/06 T.Miyata Modify Start #516 配送先
      AND   xshi.party_site_code  = xpsv.party_site_number(+)
      -- 2008/12/06 T.Miyata Modify End #516
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
--
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
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- mod start ver1.1
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- 検索条件：管轄拠点
--        lr_get_data.po_no            := re_main.po_no ;             -- 検索条件：管轄拠点
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- 検索条件：配送先
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.order_type       := re_main.order_type ;        -- 業務種別（コード）
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 依頼Ｎｏ
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- 検索条件：明細ＩＤ
        lr_get_data.item_id          := re_main.item_id ;           -- 検索条件：品目ＩＤ
        lr_get_data.item_code        := re_main.item_code ;         -- 品目コード
        lr_get_data.item_name        := re_main.item_name ;         -- 品目名称
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- 検索条件：ロット使用
        lr_get_data.quant_r          := re_main.quant_r ;           -- 依頼数（ロット管理外）
        lr_get_data.quant_i          := re_main.quant_i ;           -- 入庫数（ロット管理外）
        lr_get_data.quant_o          := re_main.quant_o ;           -- 出庫数（ロット管理外）
        lr_get_data.status           := re_main.status ;            -- 受注ヘッダステータス
-- add start ver1.2
        lr_get_data.lot_id           := re_main.lot_id ;            -- ロットID
        lr_get_data.conv_unit        := re_main.conv_unit ;         -- 入出庫換算単位
        lr_get_data.num_of_cases     := re_main.num_of_cases ;      -- ケース入数
-- add end ver1.2
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
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
    END IF ;
--
    -- ====================================================
    -- 保留データ抽出・登録処理
    -- ====================================================
    -- 出力区分が「保留」の場合
    IF ( gr_param.output_type IS NULL )
    OR ( gr_param.output_type = gc_output_type_rsrv ) THEN
      <<reserv_loop>>
      FOR re_main IN cu_reserv LOOP
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- 検索条件：管轄拠点
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- 検索条件：管轄拠点
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- 検索条件：配送先
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.order_type       := re_main.order_type ;        -- 業務種別（コード）
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 依頼Ｎｏ
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- 検索条件：明細ＩＤ
        lr_get_data.item_id          := re_main.item_id ;           -- 検索条件：品目ＩＤ
        lr_get_data.item_code        := re_main.item_code ;         -- 品目コード
        lr_get_data.item_name        := re_main.item_name ;         -- 品目名称
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- 検索条件：ロット使用
        lr_get_data.quant_r          := re_main.quant_r ;           -- 依頼数（ロット管理外）
        lr_get_data.quant_i          := re_main.quant_i ;           -- 入庫数（ロット管理外）
        lr_get_data.quant_o          := re_main.quant_o ;           -- 出庫数（ロット管理外）
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
        lr_get_data.quant_d          := re_main.quant_d  ;          -- 内訳数量(インタフェース用)
-- 2008/07/24 A.Shiina v1.7 UPDATE End
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
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
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
--##### 固定例外処理部 START #######################################################################
--
-- add start ver1.1
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
  END prc_create_ship_data ;
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
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')); -- 2008/12/03 本番障害#333 Add
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')); -- 2008/12/03 本番障害#333 Add
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lr_get_data       rec_get_data ;        -- 抽出データ格納用レコード変数
    lr_temp_tab       rec_temp_tab_data ;   -- 中間テーブル登録用レコード変数
--
    -- ==================================================
    -- カ  ー  ソ  ル  宣  言
    -- ==================================================
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
    /*
    -- 指示・実績データ取得カーソル
    CURSOR cu_main
    IS
    --***************************************
    --* 指示
    --***************************************
      SELECT xil.segment1                 AS location_code    -- 出庫倉庫コード
            --,xil.description              AS location_name    -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20) AS location_name    -- 出庫倉庫名称  2008/10/10 統合テスト障害#338 Add
            ,xmrih.schedule_ship_date     AS ship_date        -- 出庫日
            ,xmrih.schedule_arrival_date  AS arvl_date        -- 入庫日
-- mod start ver1.1
--            ,NULL                         AS po_no            -- 検索条件：管轄拠点
            ,NULL                         AS head_sales_branch -- 検索条件：管轄拠点
-- mod end ver1.1
            ,xmrih.ship_to_locat_id       AS deliver_id       -- 検索条件：入庫先
            ,xmrih.career_id              AS career_id        -- 検索条件：運送業者
            ,xmrih.shipping_method_code   AS ship_method_code -- 検索条件：配送区分
            ,gc_sp_class_move             AS order_type       -- 業務種別（コード）
            ,xmrih.delivery_no            AS delivery_no      -- 配送Ｎｏ
            ,xmrih.mov_num                AS request_no       -- 依頼Ｎｏ
            ,xmril.mov_line_id            AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                 AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                 AS item_code        -- 品目コード
            ,ximv.item_short_name         AS item_name        -- 品目名称
            ,ximv.lot_ctl                 AS lot_ctl          -- 検索条件：ロット使用
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r    -- 依頼数（ロット管理外）
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i    -- 入庫数（ロット管理外）
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o    -- 出庫数（ロット管理外）
            ,xmrih.status                 AS status           -- ヘッダステータス
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- 入出庫換算単位
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- ケース入数
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ロットID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- 商品区分
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class   AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code   AS complusion_output_kbn -- 強制出力区分       -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#461 Add
-- 2008/11/17 統合指摘#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End --------------------------------------------------------
-- 2008/07/07 A.Shiina v1.5 ADD End
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
          ,xxcmn_item_mst2_v              ximv    -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v       xicv    -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
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
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．出庫元
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.deliver_from, xil.segment1 )
      AND   xil.segment1            = xmrih.shipped_locat_code
-- mod end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
--      AND   (  gr_param.block_01   IS NULL
--            OR xil.distribution_block = gr_param.block_01 )
--      AND   (  gr_param.block_02   IS NULL
--            OR xil.distribution_block = gr_param.block_02 )
--      AND   (  gr_param.block_03   IS NULL
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
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
      -- パラメータ条件．依頼Ｎｏ
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )
-- add end ver1.1
      -- パラメータ条件．出庫日FromTo
      AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num)  =   xcv.party_id(+)
      AND   xmrih.schedule_ship_date   >=   xcv.start_date_active(+)
      AND   xmrih.schedule_ship_date   <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
--
      UNION
      --***************************************
      --* 実績
      --***************************************
      SELECT xil.segment1                       AS location_code    -- 出庫倉庫コード
            --,xil.description                    AS location_name    -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)      AS location_name    -- 出庫倉庫名称   2008/10/10 統合テスト障害#338 Add
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date        -- 出庫日
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date        -- 入庫日
-- mod start ver1.1
--            ,NULL                               AS po_no            -- 検索条件：管轄拠点
            ,NULL                               AS head_sales_branch -- 検索条件：管轄拠点
-- mod end ver1.1
            ,xmrih.ship_to_locat_id             AS deliver_id       -- 検索条件：入庫先
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id        -- 検索条件：運送業者
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code -- 検索条件：配送区分
            ,gc_sp_class_move                   AS order_type       -- 業務種別（コード）
            ,xmrih.delivery_no                  AS delivery_no      -- 配送Ｎｏ
            ,xmrih.mov_num                      AS request_no       -- 依頼Ｎｏ
            ,xmril.mov_line_id                  AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                       AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                       AS item_code        -- 品目コード
            ,ximv.item_short_name               AS item_name        -- 品目名称
            ,ximv.lot_ctl                       AS lot_ctl          -- 検索条件：ロット使用
            ,NVL( xmril.instruct_qty    , 0 )   AS quant_r          -- 依頼数（ロット管理外）
            ,NVL( xmril.ship_to_quantity, 0 )   AS quant_i          -- 入庫数（ロット管理外）
            ,NVL( xmril.shipped_quantity, 0 )   AS quant_o          -- 出庫数（ロット管理外）
            ,xmrih.status                       AS status           -- ヘッダステータス
-- add start ver1.1
            ,ximv.conv_unit               AS conv_unit             -- 入出庫換算単位
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
--            ,TO_NUMBER(NVL(ximv.num_of_cases,'1')) AS num_of_cases -- ケース入数
            ,TO_NUMBER(ximv.num_of_cases) AS num_of_cases -- ケース入数
-- 2008/07/24 A.Shiina v1.7 UPDATE End
-- add end ver1.1
-- add start ver1.2
            ,xmld.lot_id                  AS lot_id                -- ロットID
-- add end ver1.2
-- add start ver1.3
            ,xicv.prod_class_code         AS prod_class_code       -- 商品区分
-- add end ver1.3
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xmrih.freight_charge_class    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code    AS complusion_output_kbn -- 強制出力区分      -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#461 Add
-- 2008/11/17 統合指摘#651 Add Start ------------------------------------------------------
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,(
                SELECT COUNT(*)
                FROM xxinv_mov_lot_details  xmld2
                WHERE xmld2.document_type_code = gc_doc_type_move
                AND xmld2.record_type_code = gc_rec_type_inst  -- 指示ロット
                AND xmld2.lot_id = xmld.lot_id
                AND xmld2.mov_line_id = xmld.mov_line_id
             ) AS lot_inst_cnt    -- 指示ロットの件数
            ,ROW_NUMBER() OVER (PARTITION BY xmrih.mov_num
                                            ,ximv.item_no
                                ORDER BY     xmld.lot_id) AS row_num  -- 依頼No・品目ごとにロットID昇順で1から採番
-- 2008/11/17 統合指摘#651 Add End --------------------------------------------------------
-- 2008/07/07 A.Shiina v1.5 ADD End
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
          ,xxcmn_item_mst2_v              ximv    -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v       xicv    -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v              xcv     -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
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
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
-- add start ver1.2
--      AND   xmld.mov_line_id        = xmril.mov_line_id
      AND   xmld.mov_line_id(+)        = xmril.mov_line_id
-- add end ver1.2
-- 2008/07/24 A.Shiina v1.7 UPDATE End
      ----------------------------------------------------------------------------------------------
      -- ＯＰＭ保管場所
      ----------------------------------------------------------------------------------------------
      -- パラメータ条件．出庫元
-- mod start ver1.1
--      AND   xil.segment1            = NVL( gr_param.deliver_from, xil.segment1 )
      AND   xil.segment1            = xmrih.shipped_locat_code
-- mod end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type   = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xmrih.shipped_locat_id = xil.inventory_location_id
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
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
      -- パラメータ条件．依頼Ｎｏ
      AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )
-- add end ver1.1
--
      -- 2008/11/13 統合指摘#603 Del Start ---------------------------------------------
      ---- パラメータ条件．出庫日FromTo
      --AND   xmrih.schedule_ship_date    BETWEEN gr_param.date_from
      --                                  AND     NVL( gr_param.date_to, xmrih.schedule_ship_date )
      -- 2008/11/13 統合指摘#603 Del End -----------------------------------------------
      -- 2008/11/13 統合指摘#603 Add Start ---------------------------------------------
      -- パラメータ条件．出庫日FromTo
      AND   xmrih.actual_ship_date    BETWEEN gr_param.date_from
                                        AND     NVL( gr_param.date_to, xmrih.actual_ship_date )
      -- 2008/11/13 統合指摘#603 Add End -----------------------------------------------
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xmrih.career_id                    =   xcv.party_id
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xmrih.schedule_ship_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xmrih.schedule_ship_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xmrih.career_id,gn_nvl_null_num) =   xcv.party_id(+)
      AND   xmrih.actual_ship_date    >=   xcv.start_date_active(+)
      AND   xmrih.actual_ship_date    <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
    ;
    */
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Del Start
    ---------------------------------------------------------------------------------------------------------------------
--
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Add Start
    ---------------------------------------------------------------------------------------------------------------------
    -- 指示・実績データ取得カーソル
    CURSOR cu_main
    IS
    --***************************************
    --* 指示
    --***************************************
    SELECT trn.location_code             AS location_code         -- 出庫倉庫コード
          ,trn.location_name             AS location_name         -- 出庫倉庫名称
          ,trn.ship_date                 AS ship_date             -- 出庫日
          ,trn.arvl_date                 AS arvl_date             -- 入庫日
          ,trn.head_sales_branch         AS head_sales_branch     -- 検索条件：管轄拠点
          ,trn.deliver_id                AS deliver_id            -- 検索条件：配送先
          ,trn.career_id                 AS career_id             -- 検索条件：運送業者
          ,trn.ship_method_code          AS ship_method_code      -- 検索条件：配送区分
          ,trn.order_type                AS order_type            -- 業務種別（コード）
          ,trn.delivery_no               AS delivery_no           -- 配送Ｎｏ
          ,trn.request_no                AS request_no            -- 依頼Ｎｏ
          ,trn.order_line_id             AS order_line_id         -- 検索条件：明細ＩＤ
          ,trn.item_id                   AS item_id               -- 検索条件：品目ＩＤ
          ,trn.item_code                 AS item_code             -- 品目コード
          ,trn.item_name                 AS item_name             -- 品目名称
          ,trn.lot_ctl                   AS lot_ctl               -- 検索条件：ロット使用
          ,trn.quant_r                   AS quant_r               -- 依頼数
          ,trn.quant_i                   AS quant_i               -- 入庫数
          ,trn.quant_o                   AS quant_o               -- 出庫数
          ,trn.status                    AS status                -- ヘッダステータス
          ,trn.lot_id                    AS lot_id                -- ロットID
          ,trn.conv_unit                 AS conv_unit             -- 入出庫換算単位
          ,trn.num_of_cases              AS num_of_cases          -- ケース入数
          ,trn.freight_charge_code       AS freight_charge_code   -- 運賃区分
          ,trn.prod_class_code           AS prod_class_code       -- 商品区分
          ,trn.complusion_output_kbn     AS complusion_output_kbn -- 強制出力区分
          ,trn.no_instr_actual           AS no_instr_actual       -- 指示なし実績:'Y' 指示あり実績:'N'
          ,trn.lot_inst_cnt              AS lot_inst_cnt          -- 指示ロットの件数
          ,ROW_NUMBER() OVER(PARTITION BY trn.request_no,trn.item_code order by trn.lot_id) AS row_num -- 依頼No・品目ごとにロットID昇順で1から採番
      FROM (
        SELECT /*+ leading (xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xil.segment1             AS location_code      -- 出庫倉庫コード
            ,SUBSTRB(xil.description,1,20) AS location_name      -- 出庫倉庫名称
            ,xmrih.schedule_ship_date      AS ship_date          -- 出庫日
            ,xmrih.schedule_arrival_date   AS arvl_date          -- 入庫日
            ,NULL                          AS head_sales_branch  -- 検索条件：管轄拠点
            ,xmrih.ship_to_locat_id       AS deliver_id       -- 検索条件：入庫先
            ,xmrih.career_id               AS career_id          -- 検索条件：運送業者
            ,xmrih.shipping_method_code    AS ship_method_code   -- 検索条件：配送区分
            ,gc_sp_class_move              AS order_type         -- 業務種別（コード）
            ,xmrih.delivery_no             AS delivery_no        -- 配送Ｎｏ
            ,xmrih.mov_num                 AS request_no         -- 依頼Ｎｏ
            ,xmril.mov_line_id           AS order_line_id      -- 検索条件：明細ＩＤ
            ,iimb.item_id                 AS item_id            -- 検索条件：品目ＩＤ
            ,iimb.item_no                 AS item_code          -- 品目コード
            ,ximb.item_short_name         AS item_name          -- 品目名称
            ,iimb.lot_ctl                 AS lot_ctl            -- 検索条件：ロット使用
            ,NVL(xmril.instruct_qty, 0)         AS quant_r            -- 依頼数
            ,NVL(xmril.ship_to_quantity, 0) AS quant_i            -- 入庫数
            ,NVL(xmril.shipped_quantity, 0) AS quant_o            -- 出庫数
            ,xmrih.status                 AS status              -- ヘッダステータス
            ,xmld.lot_id                  AS lot_id              -- ロットID
            ,iimb.attribute24             AS conv_unit           -- 入出庫換算単位
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- ケース入数
            ,xmrih.freight_charge_class    AS freight_charge_code -- 運賃区分
            ,mcb1.segment1                 AS prod_class_code       -- 商品区分
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- 指示ロットの件数
        FROM
           xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril   -- 移動依頼/指示明細アドオン
          ,xxinv_mov_lot_details          xmld
          ,ic_item_mst_b                  iimb
          ,xxcmn_item_mst_b               ximb
          ,gmi_item_categories            gic1
          ,mtl_categories_b               mcb1
          ,gmi_item_categories            gic2
          ,mtl_categories_b               mcb2
          ,xxcmn_item_locations2_v        xil
          ,xxcmn_carriers2_v              xcv       -- 運送業者情報VIEW2
        WHERE  xmrih.schedule_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xmrih.schedule_ship_date)   -- パラメータ条件．出庫日FromTo
        AND   xmrih.status              IN( gc_mov_status_cmp       -- 依頼済
                                           ,gc_mov_status_adj       -- 調整中
                                           ,gc_mov_status_del       -- 出庫報告有
                                           ,gc_mov_status_stc       -- 入庫報告有
                                           ,gc_mov_status_dsr )     -- 入出庫報告有
        AND   xmrih.mov_type              = gc_mov_type_y
        AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )  -- パラメータ条件．指示部署
        AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )  -- パラメータ条件．依頼Ｎｏ
        AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )  -- パラメータ条件．出庫元
        AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
        AND   xmrih.mov_hdr_id          = xmril.mov_hdr_id
        AND   xmld.mov_line_id(+)        = xmril.mov_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code = gc_doc_type_move)
               )
        AND    xmril.item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- パラメータ条件．商品区分
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- パラメータ条件．品目区分
        AND    xmrih.shipped_locat_id    = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
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
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- パラメータ条件．オンライン区分
        AND    NVL(xmrih.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xmrih.schedule_ship_date >= xcv.start_date_active(+)
        AND    xmrih.schedule_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xil.segment1
                ,SUBSTRB(xil.description,1,20)
                ,xmrih.schedule_ship_date
                ,xmrih.schedule_arrival_date
                ,NULL
                ,xmrih.ship_to_locat_id
                ,xmrih.career_id
                ,xmrih.shipping_method_code
                ,gc_sp_class_move
                ,xmrih.delivery_no
                ,xmrih.mov_num
                ,xmril.mov_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xmril.instruct_qty,0)
                ,NVL(xmril.ship_to_quantity, 0)
                ,NVL(xmril.shipped_quantity,0)
                ,xmrih.status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xmrih.freight_charge_class
                ,mcb1.segment1
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n)
--
        UNION
        --***************************************
        --* 実績
        --***************************************
        SELECT /*+ leading (xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) use_nl(xmrih xmril otta xmld iimb gic1 mcb1 gic2 mcb2) */
             xil.segment1             AS location_code      -- 出庫倉庫コード
            ,SUBSTRB(xil.description,1,20) AS location_name      -- 出庫倉庫名称
            ,NVL( xmrih.actual_ship_date
                 ,xmrih.schedule_ship_date )    AS ship_date        -- 出庫日
            ,NVL( xmrih.actual_arrival_date
                 ,xmrih.schedule_arrival_date ) AS arvl_date        -- 入庫日
            ,NULL                               AS head_sales_branch -- 検索条件：管轄拠点
            ,xmrih.ship_to_locat_id       AS deliver_id       -- 検索条件：入庫先
            ,NVL( xmrih.actual_career_id
                 ,xmrih.career_id )             AS career_id        -- 検索条件：運送業者
            ,NVL( xmrih.actual_shipping_method_code
                 ,xmrih.shipping_method_code )  AS ship_method_code -- 検索条件：配送区分
            ,gc_sp_class_move              AS order_type         -- 業務種別（コード）
            ,xmrih.delivery_no             AS delivery_no        -- 配送Ｎｏ
            ,xmrih.mov_num                 AS request_no         -- 依頼Ｎｏ
            ,xmril.mov_line_id           AS order_line_id      -- 検索条件：明細ＩＤ
            ,iimb.item_id                 AS item_id            -- 検索条件：品目ＩＤ
            ,iimb.item_no                 AS item_code          -- 品目コード
            ,ximb.item_short_name         AS item_name          -- 品目名称
            ,iimb.lot_ctl                 AS lot_ctl            -- 検索条件：ロット使用
            ,NVL(xmril.instruct_qty, 0)         AS quant_r            -- 依頼数
            ,NVL(xmril.ship_to_quantity, 0) AS quant_i            -- 入庫数
            ,NVL(xmril.shipped_quantity, 0) AS quant_o            -- 出庫数
            ,xmrih.status                 AS status              -- ヘッダステータス
            ,xmld.lot_id                  AS lot_id              -- ロットID
            ,iimb.attribute24             AS conv_unit           -- 入出庫換算単位
            ,TO_NUMBER(iimb.attribute11)  AS num_of_cases        -- ケース入数
            ,xmrih.freight_charge_class    AS freight_charge_code -- 運賃区分
            ,mcb1.segment1                 AS prod_class_code       -- 商品区分
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分
            ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n) AS no_instr_actual  -- 指示なし実績:'Y' 指示あり実績:'N'
            ,COUNT(xmld.lot_id)           AS lot_inst_cnt        -- 指示ロットの件数
        FROM
           xxinv_mov_req_instr_headers    xmrih   -- 移動依頼/指示ヘッダアドオン
          ,xxinv_mov_req_instr_lines      xmril   -- 移動依頼/指示明細アドオン
          ,oe_transaction_types_all       otta      -- 受注タイプ
          ,xxinv_mov_lot_details          xmld
          ,ic_item_mst_b                  iimb
          ,xxcmn_item_mst_b               ximb
          ,gmi_item_categories            gic1
          ,mtl_categories_b               mcb1
          ,gmi_item_categories            gic2
          ,mtl_categories_b               mcb2
          ,xxcmn_item_locations2_v        xil
          ,xxcmn_carriers2_v              xcv       -- 運送業者情報VIEW2
        WHERE  xmrih.actual_ship_date BETWEEN gr_param.date_from
                                        AND NVL(gr_param.date_to,xmrih.actual_ship_date)   -- パラメータ条件．出庫日FromTo
        AND   xmrih.status              IN( gc_mov_status_cmp       -- 依頼済
                                           ,gc_mov_status_adj       -- 調整中
                                           ,gc_mov_status_del       -- 出庫報告有
                                           ,gc_mov_status_stc       -- 入庫報告有
                                           ,gc_mov_status_dsr )     -- 入出庫報告有
        AND   xmrih.mov_type              = gc_mov_type_y
        AND   xmrih.instruction_post_code = NVL( gr_param.dept_code, xmrih.instruction_post_code )  -- パラメータ条件．指示部署
        AND   xmrih.mov_num               = NVL( gr_param.request_no, xmrih.mov_num )  -- パラメータ条件．依頼Ｎｏ
        AND   xmrih.shipped_locat_code    = NVL( gr_param.deliver_from, xmrih.shipped_locat_code )  -- パラメータ条件．出庫元
        AND   NVL( xmril.delete_flg, gc_yn_div_n ) = gc_yn_div_n          -- 未削除
        AND   xmrih.mov_hdr_id        = xmril.mov_hdr_id
        AND   xmld.mov_line_id(+)        = xmril.mov_line_id
        AND    ((xmld.document_type_code IS NULL) OR
                (xmld.document_type_code = gc_doc_type_move)
               )
        AND    xmril.item_code   = iimb.item_no
        AND    ximb.item_id              = iimb.item_id
        AND    gr_param.date_from BETWEEN ximb.start_date_active AND NVL(ximb.end_date_active,gr_param.date_from)
        AND    iimb.item_id              = gic1.item_id
        AND    gic1.category_set_id      = cn_prod_class_id
        AND    gic1.category_id          = mcb1.category_id
        AND    mcb1.segment1             = NVL(gr_param.prod_div,mcb1.segment1)  -- パラメータ条件．商品区分
        AND    iimb.item_id              = gic2.item_id
        AND    gic2.category_set_id      = cn_item_class_id
        AND    gic2.category_id          = mcb2.category_id
        AND    mcb2.segment1             = gr_param.item_div  -- パラメータ条件．品目区分
        AND    xmrih.shipped_locat_id    = xil.inventory_location_id
        AND    gr_param.date_from BETWEEN xil.date_from AND NVL(xil.date_to,gr_param.date_from)
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
        AND    xil.eos_control_type       = NVL(gr_param.online_type,xil.eos_control_type)  -- パラメータ条件．オンライン区分
        AND    NVL(xmrih.career_id,gn_nvl_null_num)  = xcv.party_id(+)
        AND    xmrih.actual_ship_date >= xcv.start_date_active(+)
        AND    xmrih.actual_ship_date <= xcv.end_date_active(+)
--
        GROUP BY xil.segment1
                ,SUBSTRB(xil.description,1,20)
                ,NVL( xmrih.actual_ship_date,xmrih.schedule_ship_date )
                ,NVL( xmrih.actual_arrival_date,xmrih.schedule_arrival_date )
                ,NULL
                ,xmrih.ship_to_locat_id
                ,NVL( xmrih.actual_career_id,xmrih.career_id )
                ,NVL( xmrih.actual_shipping_method_code,xmrih.shipping_method_code )
                ,gc_sp_class_move
                ,xmrih.delivery_no
                ,xmrih.mov_num
                ,xmril.mov_line_id
                ,iimb.item_id
                ,iimb.item_no
                ,ximb.item_short_name
                ,iimb.lot_ctl
                ,NVL(xmril.instruct_qty,0)
                ,NVL(xmril.ship_to_quantity, 0)
                ,NVL(xmril.shipped_quantity,0)
                ,xmrih.status
                ,xmld.lot_id
                ,iimb.attribute24
                ,TO_NUMBER(iimb.attribute11)
                ,xmrih.freight_charge_class
                ,mcb1.segment1
                ,NVL(xcv.complusion_output_code,'0')
                ,DECODE(NVL(xmrih.no_instr_actual_class,gc_yn_div_n)
                          ,gc_yn_div_y,gc_yn_div_y,gc_yn_div_n)
      ) trn
    ;
    ---------------------------------------------------------------------------------------------------------------------
    -- 2008/12/03 本番障害#333 Add End
    ---------------------------------------------------------------------------------------------------------------------
--
    -- 保留データ取得
    CURSOR cu_reserv
    IS
      SELECT xil.segment1                     AS location_code    -- 出庫倉庫コード
            --,xil.description                  AS location_name    -- 出庫倉庫名称 2008/10/10 統合テスト障害#338 Del
            ,SUBSTRB(xil.description,1,20)    AS location_name    -- 出庫倉庫名称   2008/10/10 統合テスト障害#338 Add
            ,xshi.shipped_date                AS ship_date        -- 出庫日
            ,xshi.arrival_date                AS arvl_date        -- 入庫日
-- mod start ver1.1
--            ,NULL                             AS po_no            -- 検索条件：管轄拠点
            ,NULL                             AS head_sales_branch -- 検索条件：管轄拠点
-- mod end ver1.1
            -- 2008/12/06 Modify T.Miyata Start #516 依頼Noに紐付く入庫先があれば表示する。
            , xilv.inventory_location_id        AS deliver_id
            -- 2008/12/06 Modify T.Miyata End #516
            ,xshi.freight_carrier_code        AS career_id        -- 検索条件：運送業者
            ,xshi.shipping_method_code        AS ship_method_code -- 検索条件：配送区分
            ,xshi.eos_data_type               AS order_type       -- 業務種別（コード）
            ,xshi.delivery_no                 AS delivery_no      -- 配送Ｎｏ
            ,xshi.order_source_ref            AS request_no       -- 依頼Ｎｏ
            ,xsli.line_id                     AS order_line_id    -- 検索条件：明細ＩＤ
            ,ximv.item_id                     AS item_id          -- 検索条件：品目ＩＤ
            ,ximv.item_no                     AS item_code        -- 品目コード
            ,ximv.item_short_name             AS item_name        -- 品目名称
            ,ximv.lot_ctl                     AS lot_ctl          -- 検索条件：ロット使用
            ,xsli.orderd_quantity             AS quant_r          -- 依頼数
            ,xsli.ship_to_quantity            AS quant_i          -- 入庫数
            ,xsli.shiped_quantity             AS quant_o          -- 出庫数
-- 2008/07/24 A.Shiina v1.7 ADD Start
            ,xsli.detailed_quantity           AS quant_d          -- 内訳数量(インタフェース用)
-- 2008/07/24 A.Shiina v1.7 ADD End
            ,NULL                             AS status           -- ヘッダステータス
-- 2008/07/07 A.Shiina v1.5 ADD Start
            ,xshi.filler14                    AS freight_charge_code   -- 運賃区分
            --,xcv.complusion_output_code       AS complusion_output_kbn -- 強制出力区分  -- 2008/10/31 統合指摘#461 Del
            ,NVL(xcv.complusion_output_code,'0') AS complusion_output_kbn -- 強制出力区分 -- 2008/10/31 統合指摘#461 Add
-- 2008/07/07 A.Shiina v1.5 ADD End
      FROM xxwsh_shipping_headers_if  xshi      -- 出荷依頼インタフェースヘッダアドオン
          ,xxwsh_shipping_lines_if    xsli      -- 出荷依頼インタフェース明細アドオン
          ,xxcmn_item_locations2_v    xil       -- ＯＰＭ保管場所マスタ
          ,xxcmn_item_mst2_v          ximv      -- ＯＰＭ品目情報VIEW2
          ,xxcmn_item_categories4_v   xicv      -- ＯＰＭ品目カテゴリ割当情報VIEW4
-- 2008/07/07 A.Shiina v1.5 ADD Start
          ,xxcmn_carriers2_v          xcv       -- 運送業者情報VIEW2
-- 2008/07/07 A.Shiina v1.5 ADD End
          -- 2008/12/06 Modify T.Miyata Start #516 依頼Noに紐付く入庫先があれば表示する。
          ,xxcmn_item_locations_v        xilv
          -- 2008/12/06 Modify T.Miyata End #516
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
-- del start ver1.1
      -- パラメータ条件．出庫元
--      AND   xil.segment1          = NVL( gr_param.deliver_from, xil.segment1 )
-- del end ver1.1
      -- パラメータ条件．ブロック１・２・３
-- 2008/07/24 A.Shiina v1.7 ADD Start
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
-- 2008/07/24 A.Shiina v1.7 ADD End
      -- パラメータ条件．オンライン区分
      AND   xil.eos_control_type  = NVL( gr_param.online_type, xil.eos_control_type )
      AND   xshi.location_code    = xil.segment1
-- add start ver1.2
      AND   gr_param.date_from      BETWEEN xil.date_from
                                    AND     NVL( xil.date_to, gr_param.date_from )
-- add end ver1.2
      ----------------------------------------------------------------------------------------------
      -- ＩＦヘッダ
      ----------------------------------------------------------------------------------------------
      AND   xshi.eos_data_type  IN( gc_eos_type_rpt_move_o      -- 移動出庫確定報告
                                   ,gc_eos_type_rpt_move_i )    -- 移動入庫確定報告
      -- パラメータ条件．依頼Ｎｏ
      AND   xshi.order_source_ref = NVL( gr_param.request_no, xshi.order_source_ref )
-- add start ver1.1
      -- パラメータ条件．出庫元
      AND xshi.location_code    = NVL( gr_param.deliver_from, xshi.location_code )
      -- パラメータ条件．指示部署
      AND xshi.report_post_code = NVL( gr_param.dept_code, xshi.report_post_code )
-- add end ver1.1
      -- パラメータ条件．出庫日FromTo
      AND   xshi.shipped_date     BETWEEN gr_param.date_from
                                  AND     NVL( gr_param.date_to, xshi.shipped_date )
--
      -- 2008/10/31 統合指摘#461 Del Start -------------------------------------
      -- 2008/07/07 A.Shiina v1.5 ADD Start ------------------------------------
      --AND   xshi.freight_carrier_code         =   xcv.party_number
      --AND   ((xcv.start_date_active IS NULL)
      --  OR    (xcv.start_date_active         <=  xshi.shipped_date))
      --AND   ((xcv.end_date_active IS NULL)
      --  OR    (xcv.end_date_active           >=  xshi.shipped_date))
      -- 2008/07/07 A.Shiina v1.5 ADD End --------------------------------------
      -- 2008/10/31 統合指摘#461 Del End ---------------------------------------
--
      -- 2008/10/31 統合指摘#461 Add Start -------------------------------------
      AND   NVL(xshi.freight_carrier_code,gv_nvl_null_char) =   xcv.party_number(+)
      AND   xshi.shipped_date            >=   xcv.start_date_active(+)
      AND   xshi.shipped_date            <=   xcv.end_date_active(+)
      -- 2008/10/31 統合指摘#461 Add End ---------------------------------------
      -- 2008/12/06 Modify T.Miyata Start #516 依頼Noに紐付く入庫先があれば表示する。
      AND   xshi.ship_to_location  = xilv.segment1(+)
      -- 2008/12/06 Modify T.Miyata End #516
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
--
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
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- 検索条件：管轄拠点
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- 検索条件：管轄拠点
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- 検索条件：配送先
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.order_type       := re_main.order_type ;        -- 業務種別（コード）
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 依頼Ｎｏ
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
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
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
        --------------------------------------------------
        -- 抽出データ格納
        --------------------------------------------------
        lr_get_data.location_code    := re_main.location_code ;     -- 出庫倉庫コード
        lr_get_data.location_name    := re_main.location_name ;     -- 出庫倉庫名称
        lr_get_data.ship_date        := re_main.ship_date ;         -- 出庫日
        lr_get_data.arvl_date        := re_main.arvl_date ;         -- 入庫日
-- mod start ver1.1
--        lr_get_data.po_no            := re_main.po_no ;             -- 検索条件：管轄拠点
        lr_get_data.head_sales_branch := re_main.head_sales_branch ; -- 検索条件：管轄拠点
-- mod end ver1.1
        lr_get_data.deliver_id       := re_main.deliver_id ;        -- 検索条件：配送先
-- 2008/07/07 A.Shiina v1.5 Update Start
        lr_get_data.freight_charge_code   := re_main.freight_charge_code ;    -- 運賃区分
        lr_get_data.complusion_output_kbn := re_main.complusion_output_kbn ;  -- 強制出力区分
-- 2008/07/07 A.Shiina v1.5 Update End
        lr_get_data.career_id        := re_main.career_id ;         -- 検索条件：運送業者
        lr_get_data.ship_method_code := re_main.ship_method_code ;  -- 検索条件：配送区分
        lr_get_data.order_type       := re_main.order_type ;        -- 業務種別（コード）
        lr_get_data.delivery_no      := re_main.delivery_no ;       -- 配送Ｎｏ
        lr_get_data.request_no       := re_main.request_no ;        -- 依頼Ｎｏ
        lr_get_data.order_line_id    := re_main.order_line_id ;     -- 検索条件：明細ＩＤ
        lr_get_data.item_id          := re_main.item_id ;           -- 検索条件：品目ＩＤ
        lr_get_data.item_code        := re_main.item_code ;         -- 品目コード
        lr_get_data.item_name        := re_main.item_name ;         -- 品目名称
        lr_get_data.lot_ctl          := re_main.lot_ctl ;           -- 検索条件：ロット使用
        lr_get_data.quant_r          := re_main.quant_r ;           -- 依頼数（ロット管理外）
        lr_get_data.quant_i          := re_main.quant_i ;           -- 入庫数（ロット管理外）
        lr_get_data.quant_o          := re_main.quant_o ;           -- 出庫数（ロット管理外）
-- 2008/07/24 A.Shiina v1.7 UPDATE Start
        lr_get_data.quant_d          := re_main.quant_d  ;          -- 内訳数量(インタフェース用)
-- 2008/07/24 A.Shiina v1.7 UPDATE End
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
          RAISE global_process_expt ;
        END IF ;
--
        --------------------------------------------------
        -- 中間テーブル登録
        --------------------------------------------------
        prc_ins_temp_data
          (
            ir_temp_tab   => lr_temp_tab
           ,ov_errbuf     => lv_errbuf 
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg 
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END LOOP main_loop ;
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
--##### 固定例外処理部 START #######################################################################
--
-- add start ver1.1
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
-- add start ver1.1
    -- ====================================================
    -- 中間テーブル初期化
    -- ====================================================
    DELETE FROM xxwsh_930c_tmp;
-- add end ver1.1
    -- ====================================================
    -- 出荷・支給データ抽出処理
    -- ====================================================
    -- 業務種別が「出荷」・「支給」の場合
    IF (  ( gr_param.business_type IS NULL )
       OR ( gr_param.business_type = gc_business_type_s ) 
       OR ( gr_param.business_type = gc_business_type_p ) ) THEN
      prc_create_ship_data
        (
          ov_errbuf     => lv_errbuf 
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg 
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 移動データ抽出処理
    -- ====================================================
    -- 業務種別が「移動」の場合
    IF (  ( gr_param.business_type IS NULL )
       OR ( gr_param.business_type = gc_business_type_m ) ) THEN
      prc_create_move_data
        (
          ov_errbuf     => lv_errbuf 
         ,ov_retcode    => lv_retcode
         ,ov_errmsg     => lv_errmsg 
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
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
      RAISE global_process_expt ;
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
--##### 固定例外処理部 START #######################################################################
--
-- add start ver1.1
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
-- add end   ver1.1
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
    --データの場合
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
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
      iv_business_type      IN     VARCHAR2         -- 01 : 業務種別
     ,iv_prod_div           IN     VARCHAR2         -- 02 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 03 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 04 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 05 : 出庫日To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : 部署
     ,iv_output_type        IN     VARCHAR2         -- 07 : 出力区分
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : 出庫形態
     ,iv_block_01           IN     VARCHAR2         -- 09 : ブロック１
     ,iv_block_02           IN     VARCHAR2         -- 10 : ブロック２
     ,iv_block_03           IN     VARCHAR2         -- 11 : ブロック３
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : 出庫元
     ,iv_online_type        IN     VARCHAR2         -- 13 : オンライン対象区分
     ,iv_request_no         IN     VARCHAR2         -- 14 : 依頼No／移動No
     ,ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
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
    gr_param.business_type    := iv_business_type ;                           -- 業務種別
    gr_param.prod_div         := iv_prod_div ;                                -- 商品区分
    gr_param.item_div         := iv_item_div ;                                -- 品目区分
    gr_param.date_from        := FND_DATE.CANONICAL_TO_DATE( iv_date_from ) ; -- 出庫日From
    gr_param.date_to          := FND_DATE.CANONICAL_TO_DATE( iv_date_to   ) ; -- 出庫日To
    gr_param.dept_code        := iv_dept_code ;                               -- 部署
    gr_param.output_type      := iv_output_type ;                             -- 出力区分
    gr_param.deliver_type_id  := iv_deliver_type ;                            -- 出庫形態
    gr_param.block_01         := iv_block_01 ;                                -- ブロック１
    gr_param.block_02         := iv_block_02 ;                                -- ブロック２
    gr_param.block_03         := iv_block_03 ;                                -- ブロック３
    gr_param.deliver_from     := iv_deliver_from ;                            -- 出庫元
    gr_param.online_type      := iv_online_type ;                             -- オンライン対象区分
    gr_param.request_no       := iv_request_no ;                              -- 依頼No／移動No
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
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
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
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_business_type      IN     VARCHAR2         -- 01 : 業務種別
     ,iv_prod_div           IN     VARCHAR2         -- 02 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 03 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 04 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 05 : 出庫日To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : 部署
     ,iv_output_type        IN     VARCHAR2         -- 07 : 出力区分
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : 出庫形態
     ,iv_block_01           IN     VARCHAR2         -- 09 : ブロック１
     ,iv_block_02           IN     VARCHAR2         -- 10 : ブロック２
     ,iv_block_03           IN     VARCHAR2         -- 11 : ブロック３
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : 出庫元
     ,iv_online_type        IN     VARCHAR2         -- 13 : オンライン対象区分
     ,iv_request_no         IN     VARCHAR2         -- 14 : 依頼No／移動No
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxcmn820004c.main' ;  -- プログラム名
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
        iv_business_type  => iv_business_type                     -- 01 : 業務種別
       ,iv_prod_div       => iv_prod_div                          -- 02 : 商品区分
       ,iv_item_div       => iv_item_div                          -- 03 : 品目区分
       ,iv_date_from      => iv_date_from                         -- 04 : 出庫日From
       ,iv_date_to        => NVL( iv_date_to, gc_max_date_char )  -- 05 : 出庫日To
       ,iv_dept_code      => iv_dept_code                         -- 06 : 部署
       ,iv_output_type    => iv_output_type                       -- 07 : 出力区分
       ,iv_deliver_type   => iv_deliver_type                      -- 08 : 出庫形態
       ,iv_block_01       => iv_block_01                          -- 09 : ブロック１
       ,iv_block_02       => iv_block_02                          -- 10 : ブロック２
       ,iv_block_03       => iv_block_03                          -- 11 : ブロック３
       ,iv_deliver_from   => iv_deliver_from                      -- 12 : 出庫元
       ,iv_online_type    => iv_online_type                       -- 13 : オンライン対象区分
       ,iv_request_no     => iv_request_no                        -- 14 : 依頼No／移動No
       ,ov_errbuf         => lv_errbuf                            -- エラー・メッセージ
       ,ov_retcode        => lv_retcode                           -- リターン・コード
       ,ov_errmsg         => lv_errmsg                            -- ユーザー・エラー・メッセージ
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
END xxwsh930003c ;
/
