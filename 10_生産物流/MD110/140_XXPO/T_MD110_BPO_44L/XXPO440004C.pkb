CREATE OR REPLACE PACKAGE BODY xxpo440004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440004(body)
 * Description      : 入出庫差異明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44L)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報 (L-1)
 *  prc_create_sql              PROCEDURE : データ取得ＳＱＬ生成 (L-2)
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集 (L-3)
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/18    1.0   Yusuke Tabata    新規作成
 *  2008/05/20    1.1   Yusuke Tabata    内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/05/28    1.2   Yusuke Tabata    結合不具合対応(出荷実績計上済のコード誤り)
 *  2008/07/01    1.3   Oracle 椎名      内部変更要求142
 *  2009/12/14    1.4   SCS    吉元 強樹 E_本稼動_00430対応
 *  2009/12/15    1.5   SCS    吉元 強樹 E_本稼動_00430対応
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440004C' ;      -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440004T' ;      -- 帳票ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- データ０件メッセージ
  gc_err_code_no_prof     CONSTANT VARCHAR2(15) := 'APP-XXPO-10005' ;   -- プロファイル取得エラー
--
  ------------------------------
  -- プロファイル名
  ------------------------------
  gc_prof_org_id          CONSTANT VARCHAR2(20) := 'ORG_ID' ;   -- 営業単位
  gn_prof_org_id          oe_transaction_types_all.org_id%TYPE ;
--
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 受注カテゴリ：受注カテゴリコード
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ; -- 返品
  -- 受注カテゴリ：出荷支給区分
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;      -- 支給依頼
  -- 受注カテゴリ：出荷支給受払カテゴリ
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;     -- 有償出荷
  -- 受注ヘッダアドオン：最新フラグ（YesNo区分）
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 受注ヘッダアドオン：ステータス
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
-- UPDATE START 2008/5/28 YTabata --
/**
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '04' ;   -- 出荷実績計上済
**/
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- 出荷実績計上済
-- UPDATE END   2008/5/28 YTabata --
  -- 受注ヘッダアドオン：通知ステータス
  gc_notif_status_ok      CONSTANT VARCHAR2(2)  := '40' ;   -- 確定通知済
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_prov        CONSTANT VARCHAR2(2) := '30' ;    -- 支給指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2) := '10' ;    -- 指示
  gc_rec_type_stck        CONSTANT VARCHAR2(2) := '20' ;    -- 出庫実績
  gc_rec_type_dlvr        CONSTANT VARCHAR2(2) := '30' ;    -- 入庫実績
  -- クイックコード：差異事由コード
  gc_diff_reason_nio      CONSTANT VARCHAR2(2) := '1' ;    -- 1.出入未
  gc_diff_reason_no       CONSTANT VARCHAR2(2) := '2' ;    -- 2.出未
  gc_diff_reason_ni       CONSTANT VARCHAR2(2) := '3' ;    -- 3.入未
  gc_diff_reason_diff     CONSTANT VARCHAR2(2) := '4' ;    -- 4.差異有
  gc_diff_reason_all      CONSTANT VARCHAR2(2) := '5' ;    -- 5.全て
  gc_lookup_type_diff_reason CONSTANT VARCHAR2(16) := 'XXPO_DIFF_REASON' ;  -- 差異事由
  -- クイックコード：その他
  gc_language                CONSTANT VARCHAR2(2)  := 'JA' ;
  -- 品目区分
  gc_item_div_prod       CONSTANT VARCHAR2(1) := '5' ;     -- 製品
  -- 日付マスク
  gc_date_mask              CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒マスク
  gc_date_mask_s            CONSTANT VARCHAR2(21) := 'MM/DD' ;                 -- 月日マスク
  gc_date_mask_ja           CONSTANT VARCHAR2(19) := 'YYYY"年"MM"月"DD"日' ;   -- 年月日(JA)マスク
  -- 出力
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
  ------------------------------
  -- その他
  ------------------------------
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      diff_reason_code   VARCHAR2(1)   -- 01 : 差異事由
      ,deliver_from_code VARCHAR2(4)   -- 02 : 出庫倉庫
      ,prod_div          VARCHAR2(1)   -- 03 : 商品区分
      ,item_div          VARCHAR2(1)   -- 04 : 品目区分
      ,date_from         DATE          -- 05 : 出庫日From
      ,date_to           DATE          -- 06 : 出庫日To
      ,dlv_vend_code     VARCHAR2(4)   -- 07 : 配送先
      ,request_no        VARCHAR2(12)  -- 08 : 依頼No
      ,item_code         VARCHAR2(7)   -- 09 : 品目
      ,dept_code         VARCHAR2(4)   -- 10 : 担当部署
      ,security_div      VARCHAR2(1)   -- 11 : 有償セキュリティ区分
    ) ;
--
  -- 抽出データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD
    (
      deliver_from_code xxcmn_item_locations2_v.segment1%TYPE               -- 出庫倉庫（出庫倉庫コード）
      ,deliver_from_name xxcmn_item_locations2_v.description%TYPE           -- 出庫倉庫（出庫倉庫名）
      ,prod_div_type     xxcmn_item_categories4_v.prod_class_code%TYPE      -- 商品区分（商品区分コード）
      ,prod_div_value    xxcmn_item_categories4_v.prod_class_name%TYPE      -- 商品区分（商品区分名）
      ,item_div_type     xxcmn_item_categories4_v.item_class_code%TYPE      -- 品目区分(品目区分コード)
      ,item_div_value    xxcmn_item_categories4_v.item_class_name%TYPE      -- 品目区分（品目区分名
      ,shipped_date      VARCHAR2(5)                                        -- 出庫日(MM/DD)
      ,arrival_date      VARCHAR2(5)                                        -- 入庫日(MM/DD)
      ,dlv_vend_code     xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- 配送先（配送先コード）
      ,dlv_vend_name     xxcmn_vendor_sites2_v.vendor_site_name%TYPE        -- 配送先（配送先名）
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- 依頼No
      ,item_no           xxcmn_item_mst2_v.item_no%TYPE                     -- 品目（品目コード）
      ,item_name         xxcmn_item_mst2_v.item_desc1%TYPE                  -- 品目（品目名）
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- 付帯
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ロットNo
      ,maked_date        ic_lots_mst.attribute1%TYPE                        -- 製造日
      ,limit_date        ic_lots_mst.attribute3%TYPE                        -- 賞味期限
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- 固有記号
      ,inst_quant        xxinv_mov_lot_details.actual_quantity%TYPE         -- 指示数
      ,sipped_quant      xxinv_mov_lot_details.actual_quantity%TYPE         -- 出庫数
      ,arrv_quant        xxinv_mov_lot_details.actual_quantity%TYPE         -- 入庫数
      ,diff_raeson_code  VARCHAR(1)                                         -- 差異事由（差異事由コード）
      ,diff_reason_name  fnd_lookup_values.meaning%TYPE                     -- 差異事由（差異名）
    ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER := 0 ;         -- 処理データカウンタ
  gv_sql                VARCHAR2(32000);     -- データ取得用ＳＱＬ
--
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER  := 0 ;        -- ＸＭＬデータタグ表のインデックス
--
  -- ログインユーザーＩＤ
  gn_user_id            fnd_user.user_id%TYPE := FND_GLOBAL.USER_ID ;
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
   * Description      : ユーザー情報タグ出力(L-1)
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
    -- ユーザーＧ開始タグ
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
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, gc_date_mask ) ;
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
    -- ログインユーザー：ユーザー名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ユーザーＧ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- パラメータＧ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 出庫日FORM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_from' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_from,gc_date_mask_ja) ;
    -- 出庫日TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'date_to' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(gr_param.date_to,gc_date_mask_ja) ;
--
    -- ====================================================
    -- パラメータＧ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
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
   * Procedure Name   : prc_create_sql(L-2)
   * Description      : データ取得ＳＱＬ生成
   ************************************************************************************************/
  PROCEDURE prc_create_sql
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_sql' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_date_from  VARCHAR2(150)   ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    
    -- ====================================================
    -- 初期処理
    -- ====================================================
    -- パラメータDATE_FROM部成形
    lv_date_from :=  'FND_DATE.STRING_TO_DATE(' ;
    lv_date_from :=  lv_date_from || '''' || TO_CHAR(gr_param.date_from,gc_date_mask) ||'''' || ',' ;
    lv_date_from :=  lv_date_from || '''' || gc_date_mask ||'''' || ')';
    -- ====================================================
    -- ＳＥＬＥＣＴ句生成
    -- ====================================================
    lv_select := ' SELECT'
    || ' xil.segment1                 AS deliver_from_code'       -- 出庫倉庫コード
    || ',xil.description              AS deliver_from_name'       -- 出庫倉庫名称
    || ',xic.prod_class_code          AS prod_div_type'           -- 商品区分
    || ',xic.prod_class_name          AS prod_div_value'          -- 商品区分名称
    || ',xic.item_class_code          AS item_div_type'           -- 品目区分
    || ',xic.item_class_name          AS item_div_value'          -- 品目区分名称
    -- 実績有：実績日／無：予定日
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',TO_CHAR(NVL(xoha.shipped_date'
--    || '            ,xoha.schedule_ship_date) '
    || ',TO_CHAR(NVL(xmldiv.shipped_date'
    || '            ,xmldiv.schedule_ship_date) '
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    || '         ,''' || gc_date_mask_s || ''' ) AS shipped_date' -- 出庫日
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',TO_CHAR(NVL(xoha.arrival_date'	
--    || '            ,xoha.schedule_arrival_date) '
    || ',TO_CHAR(NVL(xmldiv.arrival_date'	
    || '            ,xmldiv.schedule_arrival_date) '
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    || '         ,''' || gc_date_mask_s || ''' ) AS arrival_date' -- 入庫日
    || ',xvs.vendor_site_code         AS dlv_vend_code'           -- 配送先コード
    || ',xvs.vendor_site_short_name   AS dlv_vend_name'           -- 配送先名称
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',xoha.request_no              AS request_no'              -- 依頼Ｎｏ
    || ',xmldiv.request_no              AS request_no'              -- 依頼Ｎｏ
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    || ',xim.item_no                  AS item_code'               -- 品目コード
    || ',xim.item_short_name          AS item_name'               -- 品目名称
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',xola.futai_code              AS futai_code'              -- 付帯
    || ',xmldiv.futai_code              AS futai_code'              -- 付帯
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    -- ロット情報出力:ロット管理品判定
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.lot_no'
    || ' END                          AS lot_no'                  -- ロットNo
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute1'
    || ' END                          AS maked_date'              -- 製造日
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute3'
    || ' END                          AS limit_date'              -- 賞味期限
    || ',CASE xim.lot_ctl'
    || '   WHEN 0 THEN NULL'
    || '   ELSE ilm.attribute2'
    || ' END                          AS orgn_sign'               -- 固有記号
    || ',NVL(xmldiv.inst_quant,0)     AS inst_quant'              -- 支持数
    -- ステータス：出荷実績計上済以外はNULL
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',CASE xoha.req_status'
    || ',CASE xmldiv.req_status'
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    || '   WHEN ''' || gc_req_status_s_cmpc || ''' THEN '
    || '     xmldiv.sipped_quant'
    || '   ELSE NULL'
    || ' END                          AS sipped_quant'            -- 出庫数
    || ',xmldiv.arrv_quant            AS arrv_quant'              -- 入庫数
    || ',xmldiv.diff_reason_code      AS diff_raeson_code'        -- 差異事由コード
    || ',flv.meaning                  AS diff_reason_name'        -- 差異名
    ;
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from := ' FROM'
-- 2009/12/15 v1.5 T.Yoshimoto Del Start E_本稼動_00430対応
--    || ' oe_transaction_types_all   otta'   -- 受注タイプ
--    || ',xxwsh_order_headers_all    xoha'   -- 受注ヘッダアドオン
--    || ',xxwsh_order_lines_all      xola'   -- 受注明細アドオン
-- 2009/12/15 v1.5 T.Yoshimoto Del End E_本稼動_00430対応
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430対応
--    || ',xxcmn_item_locations2_v    xil'    -- OPM保管場所情報VIEW
    || ' xxcmn_item_locations2_v    xil'    -- OPM保管場所情報VIEW
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430対応
    || ',xxcmn_vendor_sites2_v      xvs'    -- 仕入先サイトView
    || ',xxcmn_item_mst2_v          xim'    -- OPM品目情報View
    || ',xxcmn_item_categories4_v   xic'    -- OPM品目カテゴリ割当View
    || ',ic_lots_mst                ilm'    -- OPMロットマスタ
    || ',fnd_lookup_values          flv'    -- クイックコード(差異事由)
    -- ----------------------------------------------------
    -- 移動ロット詳細情報取得インラインVIEW
    -- ----------------------------------------------------
    || ',('	
    || '  SELECT'
    || '   xmld1.mov_line_id'
    || '  ,xmld1.item_id'
    || '  ,xmld1.lot_id'
    || '  ,xmld2.actual_quantity               AS inst_quant'       -- 指示数量
    || '  ,DECODE( xmld1.req_status,''' || gc_req_status_s_cmpc || ''''
    || '          ,xmld3.actual_quantity,NULL) AS sipped_quant'     -- 出庫数量
    || '  ,xmld4.actual_quantity               AS arrv_quant'       -- 入庫数量
    -- 差異事由コード
    -- 出荷実績計上済の場合のみ出庫有
    || '  ,CASE '
    || '    WHEN xmld1.req_status = ''' || gc_req_status_s_cmpc || ''' THEN '
    || '      CASE '
                -- 出庫数無/入庫数無
    || '        WHEN ((xmld3.actual_quantity IS NULL) AND (xmld4.actual_quantity IS NULL)) THEN'
    || '          ''' || gc_diff_reason_nio  || ''''
                -- 出庫数無/入庫数有
    || '        WHEN ((xmld3.actual_quantity IS NULL) AND (xmld4.actual_quantity >= 0)) THEN'
    || '          ''' || gc_diff_reason_no  || ''''
                -- 出庫数有/入庫数無
    || '        WHEN ((xmld4.actual_quantity IS NULL) AND (xmld3.actual_quantity >= 0)) THEN'
    || '          ''' || gc_diff_reason_ni  || ''''
                -- 支持数：入出庫数との差異有
    || '        WHEN ((xmld3.actual_quantity >= 0) AND (xmld4.actual_quantity >= 0)'
    || '        AND  ((xmld2.actual_quantity - xmld3.actual_quantity <> 0)'
    || '          OR (xmld2.actual_quantity - xmld4.actual_quantity <> 0)))'
    || '        THEN'
    || '          ''' || gc_diff_reason_diff  || ''''
                -- 差異無
    || '        ELSE' 
    || '          NULL' 
    || '      END'
    || '  ELSE'
    || '      CASE '
                -- 出庫数無/入庫数無
    || '        WHEN (xmld4.actual_quantity IS NULL) THEN'
    || '          ''' || gc_diff_reason_nio  || ''''
                -- 出庫数無/入庫数有
    || '        WHEN (xmld4.actual_quantity >= 0) THEN'
    || '          ''' || gc_diff_reason_no  || ''''
    || '      END '
    || '  END AS diff_reason_code'
-- 2009/12/15 v1.5 T.Yoshimoto Add Start E_本稼動_00430
    || '  ,xmld1.request_no'
    || '  ,xmld1.req_status'
    || '  ,xmld1.instruction_dept'
    || '  ,xmld1.vendor_code'
    || '  ,xmld1.vendor_site_code'
    || '  ,xmld1.vendor_site_id'
    || '  ,xmld1.deliver_from'
    || '  ,xmld1.deliver_from_id'
    || '  ,xmld1.shipped_date'
    || '  ,xmld1.arrival_date'
    || '  ,xmld1.schedule_ship_date'
    || '  ,xmld1.schedule_arrival_date'
    || '  ,xmld1.order_line_id'
    || '  ,xmld1.shipping_inventory_item_id'
    || '  ,xmld1.shipping_item_code'
    || '  ,xmld1.futai_code'
-- 2009/12/15 v1.5 T.Yoshimoto Add End E_本稼動_00430
    || '  FROM'
    || '  ('
    || '    SELECT'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
-- 2009/12/15 v1.5 T.Yoshimoto Add Start E_本稼動_00430
    || '    ,xohas.request_no'
    || '    ,xohas.instruction_dept'
    || '    ,xohas.vendor_code'
    || '    ,xohas.vendor_site_code'
    || '    ,xohas.vendor_site_id'
    || '    ,xohas.deliver_from'
    || '    ,xohas.deliver_from_id'
    || '    ,xohas.shipped_date'
    || '    ,xohas.arrival_date'
    || '    ,xohas.schedule_ship_date'
    || '    ,xohas.schedule_arrival_date'
    || '    ,xolas.order_line_id'
    || '    ,xolas.shipping_inventory_item_id'
    || '    ,xolas.shipping_item_code'
    || '    ,xolas.futai_code'
-- 2009/12/15 v1.5 T.Yoshimoto Add End E_本稼動_00430
    || '    FROM'
    || '     xxinv_mov_lot_details   xmlds'
    || '    ,xxwsh_order_headers_all xohas'   -- 受注ヘッダアドオン
    || '    ,xxwsh_order_lines_all   xolas'   -- 受注明細アドオン
-- 2009/12/11 v1.4 T.Yoshimoto Add Start E_本稼動_00430
    || '    ,oe_transaction_types_all ottas'  -- 受注タイプ
-- 2009/12/11 v1.4 T.Yoshimoto Add End E_本稼動_00430
    || '    WHERE'
    || '    xmlds.document_type_code   = '''  || gc_doc_type_prov || ''''
    || '    AND xohas.order_header_id  = xolas.order_header_id'
    || '    AND xolas.order_line_id    = xmlds.mov_line_id' 
-- 2009/12/11 v1.4 T.Yoshimoto Add Start E_本稼動_00430
-- 2009/12/11 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || '    AND NVL(xohas.shipped_date,xohas.schedule_ship_date) >=  ' || lv_date_from
    || '    AND xohas.shipped_date    IS NOT NULL' 
    || '    AND xohas.shipped_date    >=  ' || lv_date_from
-- 2009/12/11 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
    ;
--
    -- 出庫日TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_from := lv_from
        || ' AND xohas.shipped_date <= FND_DATE.STRING_TO_DATE(NVL(''' 
        ||     TO_CHAR(gr_param.date_to ,gc_date_mask) || ''''
        || '                            ,''' || gc_max_date_char || ''')'
        || '                            ,''' || gc_date_mask     || ''')'
        ;
    END IF ;
--
lv_from := lv_from
    || '    AND xohas.latest_external_flag     = ''' || gc_yn_div_y         || ''''
    || '    AND xohas.notif_status             = ''' || gc_notif_status_ok  || ''''
    || '    AND xohas.req_status              IN (''07'',''08'')'
    || '    AND NVL( xolas.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
--
    || '    AND ottas.org_id                   = '   || gn_prof_org_id
    || '    AND ottas.attribute1               = ''' || gc_sp_class_prov || ''''
    || '    AND ottas.order_category_code     <> ''' || gc_order_cat_r   || ''''
    || '    AND ottas.attribute11              = ''' || gc_sp_category_s || ''''
    || '    AND xohas.order_type_id            = ottas.transaction_type_id'  -- 受注タイプ結合
-- 2009/12/11 v1.4 T.Yoshimoto Add End E_本稼動_00430
-- 2009/12/15 v1.5 T.Yoshimoto Add Start E_本稼動_00430
    ;
    -- 出庫倉庫
    IF (gr_param.deliver_from_code IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.deliver_from = ''' || gr_param.deliver_from_code || '''';
    END IF ;
--
    -- 配送先
    IF (gr_param.dlv_vend_code IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.vendor_site_code = ''' || gr_param.dlv_vend_code || '''' ;
    END IF ;
--
    -- 依頼No
    IF (gr_param.request_no IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.request_no = ''' || gr_param.request_no || '''' ;
    END IF ;
--
    -- 担当部署
    IF (gr_param.dept_code IS NOT NULL) THEN
      lv_where := lv_where 
        || ' AND xohas.instruction_dept = ''' || gr_param.dept_code || '''';
    END IF ;
--
    -- 品目
    IF (gr_param.item_code IS NOT NULL) THEN
      lv_from := lv_from 
      || ' AND xolas.shipping_item_code = ''' || gr_param.item_code || '''';
    END IF ;
--
    lv_from := lv_from 
-- 2009/12/15 v1.5 T.Yoshimoto Add End E_本稼動_00430
--
    || '    GROUP BY'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
-- 2009/12/15 v1.5 T.Yoshimoto Add Start E_本稼動_00430
    || '    ,xohas.request_no'
    || '    ,xohas.instruction_dept'
    || '    ,xohas.vendor_code'
    || '    ,xohas.vendor_site_code'
    || '    ,xohas.vendor_site_id'
    || '    ,xohas.deliver_from'
    || '    ,xohas.deliver_from_id'
    || '    ,xohas.shipped_date'
    || '    ,xohas.arrival_date'
    || '    ,xohas.schedule_ship_date'
    || '    ,xohas.schedule_arrival_date'
    || '    ,xolas.order_line_id'
    || '    ,xolas.shipping_inventory_item_id'
    || '    ,xolas.shipping_item_code'
    || '    ,xolas.futai_code'
-- 2009/12/15 v1.5 T.Yoshimoto Add End E_本稼動_00430
-- 2009/12/15 v1.5 T.Yoshimoto Add Start E_本稼動_00430
    || '  UNION ALL '
    || '    SELECT'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
    || '    ,xohas.request_no'
    || '    ,xohas.instruction_dept'
    || '    ,xohas.vendor_code'
    || '    ,xohas.vendor_site_code'
    || '    ,xohas.vendor_site_id'
    || '    ,xohas.deliver_from'
    || '    ,xohas.deliver_from_id'
    || '    ,xohas.shipped_date'
    || '    ,xohas.arrival_date'
    || '    ,xohas.schedule_ship_date'
    || '    ,xohas.schedule_arrival_date'
    || '    ,xolas.order_line_id'
    || '    ,xolas.shipping_inventory_item_id'
    || '    ,xolas.shipping_item_code'
    || '    ,xolas.futai_code'
    || '    FROM'
    || '     xxinv_mov_lot_details   xmlds'
    || '    ,xxwsh_order_headers_all xohas'   -- 受注ヘッダアドオン
    || '    ,xxwsh_order_lines_all   xolas'   -- 受注明細アドオン
    || '    ,oe_transaction_types_all ottas'  -- 受注タイプ
    || '    WHERE'
    || '    xmlds.document_type_code   = '''  || gc_doc_type_prov || ''''
    || '    AND xohas.order_header_id  = xolas.order_header_id'
    || '    AND xolas.order_line_id    = xmlds.mov_line_id' 
    || '    AND xohas.shipped_date    IS NULL' 
    || '    AND xohas.schedule_ship_date    >=  ' || lv_date_from
    ;
--
    -- 出庫日TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_from := lv_from
        || ' AND xohas.schedule_ship_date <= FND_DATE.STRING_TO_DATE(NVL(''' 
        ||     TO_CHAR(gr_param.date_to ,gc_date_mask) || ''''
        || '       ,''' || gc_max_date_char || ''')'
        || '       ,''' || gc_date_mask     || ''')'
        ;
    END IF ;
--
    lv_from := lv_from
    || '    AND xohas.latest_external_flag     = ''' || gc_yn_div_y         || ''''
    || '    AND xohas.notif_status             = ''' || gc_notif_status_ok  || ''''
    || '    AND xohas.req_status               = ''07'''
    || '    AND NVL( xolas.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
--
    || '    AND ottas.org_id                   = '   || gn_prof_org_id
    || '    AND ottas.attribute1               = ''' || gc_sp_class_prov || ''''
    || '    AND ottas.order_category_code     <> ''' || gc_order_cat_r   || ''''
    || '    AND ottas.attribute11              = ''' || gc_sp_category_s || ''''
    || '    AND xohas.order_type_id            = ottas.transaction_type_id'  -- 受注タイプ結合
    ;
    -- 出庫倉庫
    IF (gr_param.deliver_from_code IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.deliver_from = ''' || gr_param.deliver_from_code || '''';
    END IF ;
--
    -- 配送先
    IF (gr_param.dlv_vend_code IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.vendor_site_code = ''' || gr_param.dlv_vend_code || '''' ;
    END IF ;
--
    -- 依頼No
    IF (gr_param.request_no IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xohas.request_no = ''' || gr_param.request_no || '''' ;
    END IF ;
--
    -- 担当部署
    IF (gr_param.dept_code IS NOT NULL) THEN
      lv_where := lv_where 
        || ' AND xohas.instruction_dept = ''' || gr_param.dept_code || '''';
    END IF ;
--
    -- 品目
    IF (gr_param.item_code IS NOT NULL) THEN
      lv_from := lv_from 
        || ' AND xolas.shipping_item_code = ''' || gr_param.item_code || '''';
    END IF ;
--
    lv_from := lv_from 
    || '    GROUP BY'
    || '     xohas.req_status'
    || '    ,xmlds.mov_line_id'
    || '    ,xmlds.item_id'
    || '    ,xmlds.lot_id'
    || '    ,xohas.request_no'
    || '    ,xohas.instruction_dept'
    || '    ,xohas.vendor_code'
    || '    ,xohas.vendor_site_code'
    || '    ,xohas.vendor_site_id'
    || '    ,xohas.deliver_from'
    || '    ,xohas.deliver_from_id'
    || '    ,xohas.shipped_date'
    || '    ,xohas.arrival_date'
    || '    ,xohas.schedule_ship_date'
    || '    ,xohas.schedule_arrival_date'
    || '    ,xolas.order_line_id'
    || '    ,xolas.shipping_inventory_item_id'
    || '    ,xolas.shipping_item_code'
    || '    ,xolas.futai_code'
-- 2009/12/15 v1.5 T.Yoshimoto Add End E_本稼動_00430
    || '  )                     xmld1,' -- 移動ロット詳細( メイン )結合用
    || '  xxinv_mov_lot_details xmld2,' -- 移動ロット詳細(指示数量)外部結合
    || '  xxinv_mov_lot_details xmld3,' -- 移動ロット詳細(出庫数量)外部結合
    || '  xxinv_mov_lot_details xmld4'  -- 移動ロット詳細(入庫数量)外部結合
    || '  WHERE'
    || '  xmld2.document_type_code(+)     = ''' || gc_doc_type_prov || ''''
    || '  AND xmld2.record_type_code(+)   = ''' || gc_rec_type_inst || ''''
    || '  AND xmld1.mov_line_id           = xmld2.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld2.item_id(+)'
    || '  AND xmld1.lot_id                = xmld2.lot_id(+) '   
    || '  AND xmld3.document_type_code(+) = ''' || gc_doc_type_prov || ''''
    || '  AND xmld3.record_type_code(+)   = ''' || gc_rec_type_stck || ''''
    || '  AND xmld1.mov_line_id           = xmld3.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld3.item_id(+) '
    || '  AND xmld1.lot_id                = xmld3.lot_id(+) '
    || '  AND xmld4.document_type_code(+) = ''' || gc_doc_type_prov || ''''
    || '  AND xmld4.record_type_code(+)   = ''' || gc_rec_type_dlvr || ''''
    || '  AND xmld1.mov_line_id           = xmld4.mov_line_id(+) '
    || '  AND xmld1.item_id               = xmld4.item_id(+) '
    || '  AND xmld1.lot_id                = xmld4.lot_id(+) '
    || ')                          xmldiv'  -- 移動ロット詳細情報取得インラインVIEW
    || ',xxpo_security_supply_v    xssv'    -- 有償支給セキュリティVIEW
    ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := ' WHERE'
    || ' xim.item_id                         = xic.item_id'             -- OPM品目カテゴリ割当結合
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ' AND xola.shipping_inventory_item_id = xim.inventory_item_id'   -- OPM品目情報VIEW結合
    || ' AND xmldiv.shipping_inventory_item_id = xim.inventory_item_id'   -- OPM品目情報VIEW結合
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    || ' AND ' || lv_date_from || ' BETWEEN xim.start_date_active'
    || '                            AND     NVL( xim.end_date_active'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
-- 2009/12/15 v1.5 T.Yoshimoto Del Start E_本稼動_00430
--    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
--    ||                                '    = ''' || gc_yn_div_n || ''''
--    || ' AND xoha.order_header_id          = xola.order_header_id'      -- 受注明細アドオン結合
--    || ' AND otta.org_id                   = '   || gn_prof_org_id
--    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
--    || ' AND otta.order_category_code     <> ''' || gc_order_cat_r   || ''''
--    || ' AND otta.attribute11              = ''' || gc_sp_category_s || ''''
--    || ' AND xoha.order_type_id            = otta.transaction_type_id'  -- 受注タイプ結合
-- 2009/12/15 v1.5 T.Yoshimoto Del End E_本稼動_00430
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ' AND xoha.vendor_site_id           = xvs.vendor_site_id'        -- 仕入先マスタ結合
    || ' AND xmldiv.vendor_site_id           = xvs.vendor_site_id'        -- 仕入先マスタ結合
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    || ' AND ' || lv_date_from || ' BETWEEN xvs.start_date_active'
    || '                            AND     NVL( xvs.end_date_active'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ' AND xoha.deliver_from_id          = xil.inventory_location_id' -- OPM保管場所情報VIEW結合
    || ' AND xmldiv.deliver_from_id          = xil.inventory_location_id' -- OPM保管場所情報VIEW結合
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    || ' AND ' || lv_date_from || ' BETWEEN xil.date_from'
    || '                            AND     NVL( xil.date_to'
    || '                                    ,FND_DATE.STRING_TO_DATE(''' || gc_max_date_char || ''''
    || '                                                            ,''' || gc_date_mask     || '''))'
-- 2009/12/15 v1.5 T.Yoshimoto Del Start E_本稼動_00430
--    || ' AND xoha.latest_external_flag     = ''' || gc_yn_div_y         || ''''
--    || ' AND xoha.notif_status             = ''' || gc_notif_status_ok  || ''''
--    || ' AND xoha.req_status              <> ''' || gc_req_status_p_ccl || ''''
--    || ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date) >=  ' || lv_date_from
--    || ' AND xola.order_line_id            = xmldiv.mov_line_id'  -- 移動ロット詳細アドオン結合
-- 2009/12/15 v1.5 T.Yoshimoto Del End E_本稼動_00430
    || ' AND xmldiv.item_id                = ilm.item_id'
    || ' AND xmldiv.lot_id                 = ilm.lot_id'          -- OPMロットマスタ結合
    -- 有償支給セキュリティVIEW結合
    || ' AND xssv.user_id                  = ''' || gn_user_id || ''''
    || ' AND xssv.security_class           ='''  || gr_param.security_div || ''''
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ' AND xoha.vendor_code              = NVL(xssv.vendor_code,xoha.vendor_code)'
--    || ' AND xoha.vendor_site_code         = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'
--    || ' AND xoha.deliver_from             = NVL(xssv.segment1,xoha.deliver_from)'
    || ' AND xmldiv.vendor_code              = NVL(xssv.vendor_code,xmldiv.vendor_code)'
    || ' AND xmldiv.vendor_site_code         = NVL(xssv.vendor_site_code,xmldiv.vendor_site_code)'
    || ' AND xmldiv.deliver_from             = NVL(xssv.segment1,xmldiv.deliver_from)'
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    || ' AND flv.lookup_type(+)            = ''' || gc_lookup_type_diff_reason || '''' 
    || ' AND flv.language(+)               = ''' || gc_language || '''' 
    || ' AND xmldiv.diff_reason_code       = flv.lookup_code(+)' -- クイックコード(差異事由)外部結合
    ;
--
      -- ----------------------------------------------------
      -- 任意パラメータによる条件
      -- ----------------------------------------------------
--
      -- 差異事由
      IF (gr_param.diff_reason_code IS NOT NULL) THEN
        -- パラメータ差異事由：「5：全て」の場合　差異事由（1～4）のレコードを抽出
        IF (gr_param.diff_reason_code = gc_diff_reason_all) THEN
          lv_where := lv_where 
          || ' AND xmldiv.diff_reason_code IN ('''  || gc_diff_reason_nio  || '''' 
          || '                                 ,''' || gc_diff_reason_ni   || ''''
          || '                                 ,''' || gc_diff_reason_no   || ''''
          || '                                 ,''' || gc_diff_reason_diff || ''')'
          ;
        -- 1～4の場合は、該当レコードを抽出
        ELSE
          lv_where := lv_where 
          || ' AND xmldiv.diff_reason_code =  ''' || gr_param.diff_reason_code || '''' 
          ;
        END IF;
      END IF ;
--
-- 2009/12/15 v1.5 T.Yoshimoto Del Start E_本稼動_00430
/*
      -- 出庫倉庫
      IF (gr_param.deliver_from_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.deliver_from = ''' || gr_param.deliver_from_code || '''' 
        ;
      END IF ;
*/
-- 2009/12/15 v1.5 T.Yoshimoto Del End E_本稼動_00430
--
      -- 商品区分
      IF (gr_param.prod_div IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xic.prod_class_code = ''' || gr_param.prod_div || '''' 
        ;
      END IF ;
--
      -- 品目区分
      IF (gr_param.item_div IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xic.item_class_code = ''' || gr_param.item_div || '''' 
        ;
      END IF ;
--
-- 2009/12/15 v1.5 T.Yoshimoto Del Start E_本稼動_00430
/*
      -- 配送先
      IF (gr_param.dlv_vend_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.vendor_site_code = ''' || gr_param.dlv_vend_code || '''' 
        ;
      END IF ;
--
      -- 依頼No
      IF (gr_param.request_no IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.request_no = ''' || gr_param.request_no || '''' ;
      END IF ;
--
      -- 品目
      IF (gr_param.item_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xola.shipping_item_code = ''' || gr_param.item_code || ''''
        ;
      END IF ;
--
      -- 担当部署
      IF (gr_param.dept_code IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND xoha.instruction_dept = ''' || gr_param.dept_code || '''' 
        ;
      END IF ;
--
      -- 出庫日TO
      IF (gr_param.date_to IS NOT NULL) THEN
        lv_where := lv_where 
        || ' AND NVL(xoha.shipped_date,xoha.schedule_ship_date)'
        || '       <= FND_DATE.STRING_TO_DATE(NVL(''' || TO_CHAR(gr_param.date_to 
                                                                 ,gc_date_mask) || ''''
        || '                                  ,''' || gc_max_date_char || ''')'
        || '          ,''' || gc_date_mask     || ''')'
        ;
      END IF ;
*/
-- 2009/12/15 v1.5 T.Yoshimoto Del End E_本稼動_00430
--
    -- ====================================================
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ' xoha.deliver_from'
    || ' xmldiv.deliver_from'
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    || ',xic.prod_class_code'
    || ',xic.item_class_code'
    -- 実績有：実績日／無：予定日
-- 2009/12/15 v1.5 T.Yoshimoto Mod Start E_本稼動_00430
--    || ',NVL(xoha.shipped_date,xoha.schedule_ship_date)'
--    || ',xoha.vendor_site_code'
--    || ',xoha.request_no'
--    || ',TO_NUMBER(xola.shipping_item_code)'
--    || ',xola.futai_code'
    || ',NVL(xmldiv.shipped_date,xmldiv.schedule_ship_date)'
    || ',xmldiv.vendor_site_code'
    || ',xmldiv.request_no'
    || ',TO_NUMBER(xmldiv.shipping_item_code)'
    || ',xmldiv.futai_code'
-- 2009/12/15 v1.5 T.Yoshimoto Mod End E_本稼動_00430
    -- 品目区分が製品の場合は「製造年月日+固有記号」それ以外「ロットNo」
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
    ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
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
  END prc_create_sql ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(L-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- エラー・メッセージ
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- リターン・コード
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1) ;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) ;  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル・例外処理 ***
    dtldata_notfound_expt      EXCEPTION ;     -- 対象データ0件例外
    -- *** ローカル変数 ***
    lt_data_rec        tab_data_type_dtl ;
    ln_sum_sipped_quant    NUMBER :=0 ;
    ln_sum_inst_quant      NUMBER :=0 ;
    ln_sum_arrv_quant      NUMBER :=0;
--
  BEGIN
--

    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    IF ( gn_data_cnt > 0 ) THEN
      <<main_data_loop>>
      FOR i IN 1..lt_data_rec.count LOOP
        -- 初期処理
        IF ( i = 1 ) THEN
          ------------------------------
          -- 出庫倉庫LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver_from_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫倉庫Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
          -- 出庫倉庫名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
          ------------------------------
          -- 商品区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 商品区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type ;
          -- 商品区分名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value ;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- 出庫日LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- カレントレコードと前レコードの出庫日が不一致
        ELSIF ((lt_data_rec(i-1).shipped_date       <> lt_data_rec(i).shipped_date)
        AND   (lt_data_rec(i-1).item_div_type      = lt_data_rec(i).item_div_type)
        AND   (lt_data_rec(i-1).prod_div_type      = lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code))
        THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- 出庫日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日計初期化
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
        -- カレントレコードと前レコードの品目区分が不一致
        ELSIF ((lt_data_rec(i-1).item_div_type     <> lt_data_rec(i).item_div_type)
        AND   (lt_data_rec(i-1).prod_div_type      = lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code)) 
        THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- 出庫日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- 出庫日LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日計初期化
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
--
        -- カレントレコードと前レコードの商品区分が不一致
        ELSIF ((lt_data_rec(i-1).prod_div_type     <> lt_data_rec(i).prod_div_type)
        AND   (lt_data_rec(i-1).deliver_from_code  = lt_data_rec(i).deliver_from_code))
        THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- 出庫日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 商品区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
          -- 商品区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- 出庫日LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日計初期化
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
--
        -- カレントレコードと前レコードの出庫倉庫が不一致
        ELSIF (lt_data_rec(i-1).deliver_from_code  <> lt_data_rec(i).deliver_from_code)  THEN
          ------------------------------
          -- 明細LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
          -- 出庫数量計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
          ------------------------------
          -- 出庫日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分LＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫倉庫Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫倉庫Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_from' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫倉庫コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
          -- 出庫倉庫名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
          ------------------------------
          -- 商品区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 商品区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 商品区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_type;
          -- 商品区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).prod_div_value;
          ------------------------------
          -- 品目区分LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 品目区分Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 品目区分コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_type' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_type;
          -- 品目区分名称
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_value' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_div_value;
          ------------------------------
          -- 出庫日LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship_date_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          ------------------------------
          -- 出庫日Ｇ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_shiped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'shipped_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).shipped_date ;
          ------------------------------
          -- 明細LＧ開始タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
          -- 出庫日計初期化
          ln_sum_sipped_quant := 0 ;
          ln_sum_inst_quant   := 0 ;
          ln_sum_arrv_quant   := 0 ;
        END IF ;
--
        ------------------------------
        -- 明細Ｇ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- 入庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date ;
        -- 配送先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dlv_vend_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dlv_vend_code;
        -- 配送先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dlv_vend_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dlv_vend_name;
        -- 依頼No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_no;
        -- 品目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- 付帯コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
        -- ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).lot_no;
        -- 作成日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'maked_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).maked_date;
        -- 賞味期限
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).limit_date;
        -- 固有記号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'orgn_sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).orgn_sign;
        -- 指示数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'inst_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).inst_quant;
        -- 出庫数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sipped_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).sipped_quant;
        -- 入庫数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrv_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrv_quant;
        -- 差異数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value 
              := NVL(lt_data_rec(i).sipped_quant,0) - NVL(lt_data_rec(i).arrv_quant,0);
        -- 差異事由コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_raeson_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).diff_raeson_code;
        -- 差異事由名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'diff_reason_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).diff_reason_name;
        ------------------------------
        -- 明細Ｇ終了タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
        -- 出庫日計項目足込
        ln_sum_sipped_quant := ln_sum_sipped_quant + NVL(lt_data_rec(i).sipped_quant,0) ;
        ln_sum_inst_quant   := ln_sum_inst_quant   + NVL(lt_data_rec(i).inst_quant,0)   ;
        ln_sum_arrv_quant   := ln_sum_arrv_quant   + NVL(lt_data_rec(i).arrv_quant,0)   ;
--
      END LOOP main_data_loop ;
--
      -- ======================================
      -- 終了処理
      -- ======================================
      ------------------------------
      -- 明細LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      -- 出庫数量計
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_sipped_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_sipped_quant ;
      -- 出庫数量計
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_inst_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_inst_quant ;
      -- 出庫数量計
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_arrv_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_d ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_sum_arrv_quant ;
      ------------------------------
      -- 出庫日Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_shiped_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 出庫日LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship_date_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 品目区分Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 品目区分LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 商品区分Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 商品区分LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 出庫倉庫Ｇ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_from' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
      ------------------------------
      -- 出庫倉庫LＧ終了タグ
      ------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_from_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
    END IF ;
--
  EXCEPTION
--
    -- *** 対象データ0件例外ハンドラ ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  固定例外処理部 START   ####################################
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
--#####################################  固定部 END   ##########################################
--
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
      iv_diff_reason_code    IN   VARCHAR2  -- 01 : 差異事由
     ,iv_deliver_from_code   IN   VARCHAR2  -- 02 : 出庫倉庫
     ,iv_prod_div            IN   VARCHAR2  -- 03 : 商品区分
     ,iv_item_div            IN   VARCHAR2  -- 04 : 品目区分
     ,iv_date_from           IN   VARCHAR2  -- 05 : 出庫日From
     ,iv_date_to             IN   VARCHAR2  -- 06 : 出庫日To
     ,iv_dlv_vend_code       IN   VARCHAR2  -- 07 : 配送先
     ,iv_request_no          IN   VARCHAR2  -- 08 : 依頼No
     ,iv_item_code           IN   VARCHAR2  -- 09 : 品目
     ,iv_dept_code           IN   VARCHAR2  -- 10 : 担当部署
     ,iv_security_div        IN   VARCHAR2  -- 11 : 有償セキュリティ区分
     ,ov_errbuf              OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode             OUT  VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg              OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              VARCHAR2(1) ;
--
    get_value_expt        EXCEPTION ;     -- 値取得エラー
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
    gr_param.diff_reason_code  := iv_diff_reason_code ;    -- 01 : 差異事由
    gr_param.deliver_from_code := iv_deliver_from_code ;   -- 02 : 出庫倉庫
    gr_param.prod_div          := iv_prod_div ;            -- 03 : 商品区分
    gr_param.item_div          := iv_item_div ;            -- 04 : 品目区分
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                     -- 05 : 出庫日From
        := FND_DATE.CANONICAL_TO_DATE(iv_date_from) ;
    gr_param.date_to                                       -- 06 : 出庫日To
        := FND_DATE.CANONICAL_TO_DATE(iv_date_to) ;
/**
    gr_param.date_from
        := FND_DATE.STRING_TO_DATE(iv_date_from,gc_date_mask) ; -- 05 : 出庫日From
    gr_param.date_to
        := FND_DATE.STRING_TO_DATE(iv_date_to,gc_date_mask) ;   -- 06 : 出庫日To
**/
-- UPDATE END 2008/5/20 YTabata --

    gr_param.dlv_vend_code     := iv_dlv_vend_code ;       -- 07 : 配送先
    gr_param.request_no        := iv_request_no ;          -- 08 : 依頼No
    gr_param.item_code         := iv_item_code ;           -- 09 : 品目
    gr_param.dept_code         := iv_dept_code ;           -- 10 : 担当部署
    gr_param.security_div      := iv_security_div ;        -- 11 : 有償セキュリティ区分
--
    -- -----------------------------------------------------
    -- 営業単位取得
    -- -----------------------------------------------------
    gn_prof_org_id := FND_PROFILE.VALUE( gc_prof_org_id ) ;	
    IF ( gn_prof_org_id IS NULL ) THEN
      lv_err_code := gc_err_code_no_prof ;
      RAISE get_value_expt ;
    END IF ;
--
    -- =====================================================
    -- データ取得ＳＱＬ生成
    -- =====================================================
    prc_create_sql
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_deliver_from_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_deliver_from>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_item_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_prod_div_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_deliver_from>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_deliver_from_info>' ) ;
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
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
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
     ,iv_diff_reason_code   IN     VARCHAR2         -- 01 : 差異事由
     ,iv_deliver_from_code  IN     VARCHAR2         -- 02 : 出庫倉庫
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 04 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 05 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 06 : 出庫日To
     ,iv_dlv_vend_code      IN     VARCHAR2         -- 07 : 配送先
     ,iv_request_no         IN     VARCHAR2         -- 08 : 依頼No
     ,iv_item_code          IN     VARCHAR2         -- 09 : 品目
     ,iv_dept_code          IN     VARCHAR2         -- 10 : 担当部署
     ,iv_security_div       IN     VARCHAR2         -- 11 : 有償セキュリティ区分
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
        iv_diff_reason_code   -- 01 : 差異事由
       ,iv_deliver_from_code  -- 02 : 出庫倉庫
       ,iv_prod_div           -- 03 : 商品区分
       ,iv_item_div           -- 04 : 品目区分
       ,iv_date_from          -- 05 : 出庫日From
       ,iv_date_to            -- 06 : 出庫日To
       ,iv_dlv_vend_code      -- 07 : 配送先
       ,iv_request_no         -- 08 : 依頼No
       ,iv_item_code          -- 09 : 品目
       ,iv_dept_code          -- 10 : 担当部署
       ,iv_security_div       -- 11 : 有償セキュリティ区分
       ,lv_errbuf              -- エラー・メッセージ
       ,lv_retcode             -- リターン・コード
       ,lv_errmsg              -- ユーザー・エラー・メッセージ
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxpo440004c ;
/
