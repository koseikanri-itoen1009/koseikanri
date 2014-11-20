CREATE OR REPLACE PACKAGE BODY xxpo440006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440006(spec)
 * Description      : 製造指示書
 * MD.050/070       : 製造指示書(T_MD050_BPO_444)
 *                    製造指示書T_MD070_BPO_44N)
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_sql              PROCEDURE : データ取得ＳＱＬ生成 (N-2)
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集 (N-3)
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/21    1.0   Yusuke Tabata   新規作成
 *  2008/05/20    1.1   Yusuke Tabata   内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/06/03    1.2   Yohei  Takayama 結合テスト不具合ログ#440_47
 *  2008/06/04    1.3 Yasuhisa Yamamoto 結合テスト不具合ログ#440_48,#440_55
 *  2008/06/07    1.4   Yohei  Takayama 結合テスト不具合ログ#440_67
 *  2008/07/02    1.5   Satoshi Yunba   禁則文字対応
 *
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
-- 2008/06/04 UPD START Y.Yamamoto
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440006C' ;      -- パッケージ名
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440006T' ;      -- 帳票ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440006C' ;      -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440006T' ;      -- 帳票ID
-- 2008/06/04 UPD END Y.Yamamoto
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122';   -- データ０件メッセージ
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
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- 支給依頼
  -- 受注カテゴリ：出荷支給受払カテゴリ
  gc_sp_category_s        CONSTANT VARCHAR2(2)  := '05' ;   -- 有償出荷
  -- 受注ヘッダアドオン：最新フラグ（YesNo区分）
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 受注ヘッダアドオン：ステータス
  gc_req_status_s_cmpd    CONSTANT VARCHAR2(2)  := '07';    -- 受領済
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99';    -- 取消
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- 支給指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_inst        CONSTANT VARCHAR2(2)  := '10';    -- 指示
  -- ＯＰＭ品目マスタ：ロット管理区分
  gc_lot_ctl_y            CONSTANT NUMBER(1)    := 1 ;      -- ロット管理あり
  gc_lot_ctl_n            CONSTANT NUMBER(1)    := 0 ;      -- ロット管理なし
  -- ＯＰＭ品目カテゴリ：品目区分
  gc_item_div_prod        CONSTANT VARCHAR2(1)  := '5' ;    -- 製品
  ------------------------------
  -- その他
  ------------------------------
  -- 最大日付
  gc_max_date_char  CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- 日付マスク
  gc_date_mask      CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- 年月日時分秒マスク
  gc_date_mask_m    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD' ;            -- 年月日(YYYY/MM/DD)マスク
  gc_date_mask_s    CONSTANT VARCHAR2(10) := 'MM/DD' ;                 -- 月日(MM/DD)マスク
  -- 出力
  gc_tag_type_t     CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d     CONSTANT VARCHAR2(1)  := 'D' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      vendor_code          VARCHAR2(4)         -- 01 : 取引先
     ,deliver_to_code      VARCHAR2(4)         -- 02 : 配送先
     ,design_item_code_01  VARCHAR2(7)         -- 03 : 製造品目１
     ,design_item_code_02  VARCHAR2(7)         -- 04 : 製造品目２
     ,design_item_code_03  VARCHAR2(7)         -- 05 : 製造品目３
     ,date_from            VARCHAR2(10)        -- 06 : 出庫日From
     ,date_to              VARCHAR2(10)        -- 07 : 出庫日To
     ,design_no            VARCHAR2(10)        -- 08 : 製造番号
     ,security_div         VARCHAR2(1)         -- 09 : 有償セキュリティ区分
    ) ;
--
  -- 抽出データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD
    (
       vendor_code       xxcmn_vendors2_v.segment1%TYPE                     -- 取引先（取引先コード）
      ,vendor_name       xxcmn_vendors2_v.vendor_full_name%TYPE             -- 取引先（取引先名）
      ,deliver_to_code   xxcmn_vendor_sites2_v.vendor_site_code%TYPE        -- 配送先（配送先コード）
      ,deliver_to_name   xxcmn_vendor_sites2_v.vendor_site_name%TYPE        -- 配送先（配送先名）
      ,design_item_code  xxcmn_item_mst2_v.item_no%TYPE                     -- 製造品目（製造品目コード）
      ,design_item_name  xxcmn_item_mst2_v.item_short_name%TYPE             -- 製造品目（製造品目名）
      ,design_date       xxcmn_item_categories4_v.item_class_code%TYPE      -- 製造日
      ,design_no         xxcmn_item_categories4_v.item_class_name%TYPE      -- 製造番号
      ,item_code         xxcmn_item_mst2_v.item_no%TYPE                     -- 品目（品目コード）
      ,item_name         xxcmn_item_mst2_v.item_short_name%TYPE             -- 品目（品目名）
      ,futai_code        xxwsh_order_lines_all.futai_code%TYPE              -- 付帯
      ,lot_no            ic_lots_mst.lot_no%TYPE                            -- ロットNo
      ,maked_date        VARCHAR2(10)                                       -- 製造日(YYYY/MM/DD)
      ,limit_date        VARCHAR2(10)                                       -- 賞味期限(YYYY/MM/DD)
      ,orgn_sign         ic_lots_mst.attribute2%TYPE                        -- 固有記号
      ,entry_quant       xxcmn_item_mst2_v.frequent_qty%TYPE                -- 入数
      ,quant             xxinv_mov_lot_details.actual_quantity%TYPE         -- 総数
      ,unit              xxwsh_order_lines_all.uom_code%TYPE                -- 単位
      ,deliver_from_code xxcmn_item_locations2_V.segment1%TYPE              -- 出庫倉庫(出庫倉庫コード)
      ,deliver_from_name xxcmn_item_locations2_V.description%TYPE           -- 出庫倉庫(出庫倉庫名)
      ,dtl_desc          xxwsh_order_lines_all.line_description%TYPE        -- 明細摘要
      ,request_no        xxwsh_order_headers_all.request_no%TYPE            -- 依頼No
      ,arrival_date      VARCHAR2(5)                                        -- 入庫日(MM/DD)
    ) ;
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER DEFAULT  0 ;         -- 処理データカウンタ
  gv_sql                VARCHAR2(32000);     -- データ取得用ＳＱＬ
--
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER DEFAULT  0 ;        -- ＸＭＬデータタグ表のインデックス
--
  -- ログインユーザーＩＤ
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;
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
--
    -- ====================================================
    -- ユーザーＧ終了タグ
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
   * Procedure Name   : prc_create_sql(N-2)
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
    lv_work_str   VARCHAR2(1500)  ;
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
    lv_date_from :=  'FND_DATE.STRING_TO_DATE('
    || ''''  || gr_param.date_from  ||''''
    || ',''' || gc_date_mask ||''''
    || ')'
    ;
    -- ====================================================
    -- ＳＥＬＥＣＴ句生成
    -- ====================================================
    lv_select := ' SELECT'
    || ' xvv.segment1                    AS vendor_code'       -- 取引先（取引先コード）
    || ',xvv.vendor_full_name            AS vendor_name'       -- 取引先（取引先名）
    || ',xvsv.vendor_site_code           AS deliver_to_code'   -- 配送先（配送先コード）
    || ',xvsv.vendor_site_name           AS deliver_to_name'   -- 配送先（配送先名）
    || ',xim1.item_no                    AS design_item_code'  -- 製造品目（製造品目コード）
    -- 2008/06/30 UPD START Y.Takayama
    --|| ',xim1.item_desc1                 AS design_item_name'  -- 製造品目（製造品目名）
    || ',xim1.item_short_name            AS design_item_name'  -- 製造品目（製造品目名）
    -- 2008/06/30 UPD END   Y.Takayama
    || ',TO_CHAR(xoha.designated_production_date,'
    || '''' || gc_date_mask_m || ''' )   AS design_date'       -- 製造日
    || ',xoha.designated_branch_no       AS design_no'         -- 製造番号
    || ',xim2.item_no                    AS item_code'         -- 品目（品目コード）
    -- 2008/06/30 UPD START Y.Takayama
    --|| ',xim2.item_desc1                 AS item_name'         -- 品目（品目名）
    || ',xim2.item_short_name            AS item_name'         -- 品目（品目名）
    -- 2008/06/30 UPD END   Y.Takayama
    || ',xola.futai_code                 AS futai_code'        -- 付帯
    -- ロット情報出力:ロット管理品判定
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.lot_no'
    || '   ELSE '
    || '     NULL'
    || ' END                           AS lot_no'             -- ロットNo
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute1)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS maked_date'         -- 製造日
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     TO_CHAR(FND_DATE.CANONICAL_TO_DATE(ilm.attribute3)'
    || '             ,''' || gc_date_mask_m || ''')'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS limit_date'         -- 賞味期限
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute2'
    || '   ELSE'
    || '     NULL'
    || ' END                           AS orgn_sign'          -- 固有記号
    -- 入数出力:ロット管理品判定
    || ',CASE xim2.lot_ctl'
    || '   WHEN '  || gc_lot_ctl_y || ' THEN'
    || '     ilm.attribute6'
    || '   ELSE'
    || '     xim2.frequent_qty'
    || ' END                           AS entry_quant'        -- 入数
    || ' ,xmld.actual_quantity         AS quant'              -- 総数
    || ',xola.uom_code                 AS unit'               -- 単位
    || ',xilv.segment1                 AS deliver_from_code'  -- 出庫倉庫(出庫倉庫コード)
    || ',xilv.description              AS deliver_from_name'  -- 出庫倉庫(出庫倉庫名)
    || ',xola.line_description         AS dtl_desc'           -- 明細摘要
    || ',xoha.request_no               AS request_no'         -- 依頼No
    || ',TO_CHAR(xoha.schedule_arrival_date,'
    || '''' || gc_date_mask_s || ''' ) AS arrival_date'       -- 入庫日(MM/DD)
    ;
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from := ' FROM'
    || ' xxwsh_order_headers_all    xoha'   -- 受注ヘッダアドオン
    || ',oe_transaction_types_all   otta'   -- 受注タイプ
    || ',xxwsh_order_lines_all      xola'   -- 受注明細アドオン
    || ',xxinv_mov_lot_details      xmld'   -- 移動ロット詳細アドオン
    || ',ic_lots_mst                 ilm'   -- OPMロットマスタ
    || ',xxcmn_item_mst2_v          xim1'   -- OPM品目情報View(製造品目)
    || ',xxcmn_item_mst2_v          xim2'   -- OPM品目情報View(品目)
    || ',xxcmn_item_categories4_v    xic'   -- OPM品目カテゴリ割当View
    || ',xxcmn_vendors2_v            xvv'   -- 仕入先情報View
    || ',xxcmn_vendor_sites2_v      xvsv'   -- 仕入先サイト情報View
    || ',xxcmn_item_locations2_v    xilv'   -- OPM保管場所情報View
    || ',xxpo_security_supply_v     xssv'   -- 有償支給セキュリティView
    ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := ' WHERE'
    -- 受注ヘッダアドオン絞込
    || '     xoha.latest_external_flag        = ''' || gc_yn_div_y          || ''''
    || ' AND xoha.req_status                 < '''  || gc_req_status_p_ccl  || ''''
    || ' AND xoha.req_status                 >= ''' || gc_req_status_s_cmpd || ''''
    || ' AND xoha.designated_production_date >=  '  || lv_date_from
     -- 受注タイプ結合
    || ' AND otta.org_id                   = '   || gn_prof_org_id
    || ' AND otta.attribute1               = ''' || gc_sp_class_prov || ''''
    || ' AND otta.order_category_code     <> ''' || gc_order_cat_r   || ''''
    || ' AND otta.attribute11              = ''' || gc_sp_category_s || ''''
    || ' AND xoha.order_type_id            = otta.transaction_type_id'
    -- 受注明細アドオン結合
    || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
    ||                                '    = ''' || gc_yn_div_n || ''''
    || ' AND xoha.order_header_id          = xola.order_header_id'
    -- 移動ロット詳細アドオン結合
    || ' AND xmld.document_type_code       = ''' || gc_doc_type_prov || ''''
    || ' AND xmld.record_type_code         = ''' || gc_rec_type_inst || ''''
    || ' AND xola.order_line_id            = xmld.mov_line_id'
    -- OPMロットマスタ結合
    || ' AND xmld.item_id                  = ilm.item_id'
    || ' AND xmld.lot_id                   = ilm.lot_id'
    -- OPM品目情報VIEW(製造品目)結合
    || ' AND ' || lv_date_from || ' BETWEEN xim1.start_date_active'
    || '                            AND NVL(xim1.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    -- 2008/06/07 UPD START Y.Takayama
    --|| ' AND xoha.designated_item_id = xim1.item_id'
    || ' AND xoha.designated_item_id = xim1.inventory_item_id'
    -- 2008/06/07 UPD END   Y.Takayama
    -- OPM品目情報VIEW(品目)結合
    || ' AND ' || lv_date_from || ' BETWEEN xim2.start_date_active'
    || '                            AND NVL(xim2.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xola.shipping_inventory_item_id = xim2.inventory_item_id'
    -- OPM品目カテゴリ割当情報VIEW結合
    || ' AND xim2.item_id                   = xic.item_id'
    -- 仕入先情報VIEW結合
    || ' AND ' || lv_date_from || '  BETWEEN xvv.start_date_active'
    || '                             AND NVL(xvv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_id                = xvv.vendor_id'
    -- 仕入先サイト情報VIEW結合
    || ' AND ' || lv_date_from || '  BETWEEN xvsv.start_date_active'
    || '                             AND NVL(xvsv.end_date_active'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.vendor_site_id                = xvsv.vendor_site_id'
    -- OPM保管場所VIEW結合
    || ' AND ' || lv_date_from || '  BETWEEN xilv.date_from'
    || '                             AND NVL(xilv.date_to'
    || ',FND_DATE.CANONICAL_TO_DATE(''' || gc_max_date_char || '''))'
    || ' AND xoha.deliver_from_id = xilv.inventory_location_id'
    -- 有償支給セキュリティVIEW結合
    || ' AND xssv.user_id                  = ''' || gn_user_id || ''''
    || ' AND xssv.security_class           = ''' || gr_param.security_div || ''''
    || ' AND xoha.vendor_code              = NVL(xssv.vendor_code,xoha.vendor_code)'
    || ' AND xoha.vendor_site_code         = NVL(xssv.vendor_site_code,xoha.vendor_site_code)'
    ;
--
    -- ----------------------------------------------------
    -- 任意パラメータによる条件
    -- ----------------------------------------------------
--
    -- 取引先
    IF (gr_param.vendor_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_code = ''' || gr_param.vendor_code || ''''
      ;
    END IF ;
--
    -- 配送先
    IF (gr_param.deliver_to_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.vendor_site_code = ''' || gr_param.deliver_to_code || ''''
      ;
    END IF ;
--
    -- 製造品目01
    IF (gr_param.design_item_code_01 IS NOT NULL) THEN
      lv_work_str := gr_param.design_item_code_01;
    END IF;
    -- 製造品目02
    IF (gr_param.design_item_code_02 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.design_item_code_02 ;
    END IF;
    -- 製造品目03
    IF (gr_param.design_item_code_03 IS NOT NULL) THEN
      IF (lv_work_str IS NOT NULL) THEN
        lv_work_str := lv_work_str || ',' ;
      END IF ;
      lv_work_str := lv_work_str  || gr_param.design_item_code_03 ;
    END IF;
    IF (lv_work_str IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xim1.item_no IN('||lv_work_str || ')';
      lv_work_str := NULL ;
    END IF ;
--
    -- 製造番号
    IF (gr_param.design_no IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.designated_branch_no = ''' || gr_param.design_no || ''''
      ;
    END IF ;
--
    -- 製造日TO
    IF (gr_param.date_to IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND xoha.designated_production_date'
      || '     <= FND_DATE.STRING_TO_DATE(''' || gr_param.date_to || '''' || ',''' || gc_date_mask || ''')'
      ;
    END IF ;
--
    -- ====================================================
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
    || ' xoha.vendor_code'
    || ',xoha.vendor_site_code'
    || ',xim1.item_no'
    || ',xoha.designated_production_date'
    || ',xoha.designated_branch_no'
    || ',xic.item_class_code DESC'
    || ',xola.shipping_item_code'
    -- 品目区分が製品の場合は「製造年月日+固有記号」それ以外「ロットNo」
    || ',DECODE(xic.item_class_code,''' || gc_item_div_prod || ''''
    || '       ,CONCAT(ilm.attribute1,ilm.attribute2),ilm.lot_no)'
    || ',xoha.deliver_from'
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
   * Description      : ＸＭＬデータ作成(N-3)
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
    -- *** ローカル定数 ***
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
    -- *** ローカル変数 ***
    lt_data_rec        tab_data_type_dtl ;
    -- ブレイク判断用変数
    lv_vendor_code       VARCHAR2(4)  DEFAULT lc_init ;
    lv_deliver_to_code   VARCHAR2(4)  DEFAULT lc_init ;
    lv_design_item_code  VARCHAR2(7)  DEFAULT lc_init ;
    lv_design_date       VARCHAR2(10) DEFAULT lc_init ;
    lv_design_no         VARCHAR2(10) DEFAULT lc_init ;
--
  BEGIN
--
    EXECUTE IMMEDIATE gv_sql BULK COLLECT INTO lt_data_rec ;
    gn_data_cnt := lt_data_rec.count ;
--
    IF ( gn_data_cnt >= 1 ) THEN
      -- ==================================
      -- 初期処理
      -- ==================================
      -- 取引先リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      <<main_data_loop>>
      FOR i IN 1..lt_data_rec.count LOOP
        -- ====================================================
        -- ブレイク判定：取引先グループ
        -- ====================================================
        IF ( lt_data_rec(i).vendor_code <> lv_vendor_code ) THEN
          IF ( lv_vendor_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- 下層グループ終了タグ出力
            -- ----------------------------------------------------
            -- 明細リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造品目グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造品目リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 配送先グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 配送先リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_to_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 取引先グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          -- 取引先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vendor';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 取引先コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_code;
          -- 取引先名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).vendor_name;
          -- 配送先リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver_to_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
  --
          -- TMP取引先：セット
          lv_vendor_code       := lt_data_rec(i).vendor_code ;
          -- 下層G：ブレイク判定条件セット
          lv_deliver_to_code   := lc_init ;
          lv_design_item_code  := lc_init ;
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- ブレイク判定：配送先グループ
        -- ====================================================
        IF ( lt_data_rec(i).deliver_to_code <> lv_deliver_to_code ) THEN
          IF ( lv_deliver_to_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- 下層グループ終了タグ出力
            -- ----------------------------------------------------
            -- 明細リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造品目グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造品目リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 配送先グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          -- 配送先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver_to';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 配送先コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to_code;
          -- 配送先名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_to_name;
          -- 製造品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_item_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP配送先：セット
          lv_deliver_to_code   := lt_data_rec(i).deliver_to_code ;
          -- 下層G：ブレイク判定条件セット
          lv_design_item_code  := lc_init ;
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- ブレイク判定：製造品目グループ
        -- ====================================================
        IF ( lt_data_rec(i).design_item_code <> lv_design_item_code ) THEN
          IF ( lv_design_item_code <> lc_init ) THEN
            -- ----------------------------------------------------
            -- 下層グループ終了タグ出力
            -- ----------------------------------------------------
            -- 明細リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造品目グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          -- 製造品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_item';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 製造品目コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_item_code';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_item_code;
          -- 製造品目名
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_item_name';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_item_name;
          -- 製造日リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_date_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP製造品目：セット
          lv_design_item_code   := lt_data_rec(i).design_item_code ;
          -- 下層G：ブレイク判定条件セット
          lv_design_date       := lc_init ;
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- ブレイク判定：製造日グループ
        -- ====================================================
        IF ( lt_data_rec(i).design_date <> lv_design_date ) THEN
          IF ( lv_design_date <> lc_init ) THEN
            -- ----------------------------------------------------
            -- 下層グループ終了タグ出力
            -- ----------------------------------------------------
            -- 明細リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造日グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          -- 製造日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_date';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 製造日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_date';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_date;
          -- 製造日リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_design_no_info';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP製造品目：セット
          lv_design_date   := lt_data_rec(i).design_date ;
          -- 下層G：ブレイク判定条件セット
          lv_design_no         := lc_init ;
--
        END IF ;
--
        -- ====================================================
        -- ブレイク判定：製造番号グループ
        -- ====================================================
    -- 2008/06/04 UPD START Y.Yamamoto
--        IF ( lt_data_rec(i).design_no <> lv_design_no ) THEN
        IF ( NVL(lt_data_rec(i).design_no,'@') <> lv_design_no ) THEN
          IF ( lv_design_no <> lc_init ) THEN
    -- 2008/06/04 UPD END Y.Yamamoto
            -- ----------------------------------------------------
            -- 下層グループ終了タグ出力
            -- ----------------------------------------------------
            -- 明細リストグループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
            -- 製造番号グループ
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          END IF ;
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          -- 製造番号グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_design_no';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 製造番号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'design_no';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).design_no;
          -- 製造番号リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          -- TMP製造品目：セット
    -- 2008/06/04 UPD START Y.Yamamoto
--          lv_design_no   := lt_data_rec(i).design_no ;
          lv_design_no   := NVL(lt_data_rec(i).design_no,'@') ;
    -- 2008/06/04 UPD END Y.Yamamoto
--
        END IF ;
--
        -- ==================================
        -- 明細出力：明細グループ
        -- ==================================
        -- 明細グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_code;
        -- 品目名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).item_name;
        -- 付帯
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).futai_code;
        -- ロットNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).lot_no;
        -- 製造日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'maked_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).maked_date;
        -- 賞味期限
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'limit_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).limit_date;
        -- 固有記号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'orgn_sign' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).orgn_sign;
        -- 入数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'entry_quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).entry_quant;
        -- 総数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).quant;
        -- 単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).unit;
        -- 出庫倉庫コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_code;
        -- 出庫倉庫名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_from_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).deliver_from_name;
        -- 明細摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_desc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).dtl_desc;
        -- 依頼No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).request_no;
        -- 入庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lt_data_rec(i).arrival_date;
        -- 明細グループ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := gc_tag_type_t ;
--
      END LOOP main_data_loop ;
--
      -- ==================================
      -- 終了処理
      -- ==================================
      -- 明細リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造番号グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_no';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造番号リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_no_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造日グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造日リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_date_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造品目グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_design_item';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 製造品目リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_design_item_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 配送先グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver_to';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 配送先リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver_to_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 取引先グループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- 取引先リストグループ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor_info';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
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
      iv_vendor_code         IN   VARCHAR2  -- 01 : 取引先
     ,iv_deliver_to_code     IN   VARCHAR2  -- 02 : 配送先
     ,iv_design_item_code_01 IN   VARCHAR2  -- 03 : 製造品目１
     ,iv_design_item_code_02 IN   VARCHAR2  -- 04 : 製造品目２
     ,iv_design_item_code_03 IN   VARCHAR2  -- 05 : 製造品目３
     ,iv_date_from           IN   VARCHAR2  -- 06 : 出庫日From
     ,iv_date_to             IN   VARCHAR2  -- 07 : 出庫日To
     ,iv_design_no           IN   VARCHAR2  -- 08 : 製造番号
     ,iv_security_div        IN   VARCHAR2  -- 09 : 有償セキュリティ区分
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
    gr_param.vendor_code         :=  iv_vendor_code;         -- 01 : 取引先
    gr_param.deliver_to_code     :=  iv_deliver_to_code;     -- 02 : 配送先
    gr_param.design_item_code_01 :=  iv_design_item_code_01; -- 03 : 製造品目１
    gr_param.design_item_code_02 :=  iv_design_item_code_02; -- 04 : 製造品目２
    gr_param.design_item_code_03 :=  iv_design_item_code_03; -- 05 : 製造品目３
-- UPDATE START 2008/5/20 YTabata --
    gr_param.date_from                                   -- 06 : 出庫日From
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_from ),'YYYY/MM/DD');
    gr_param.date_to                                     -- 07 : 出庫日To
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_date_to ),'YYYY/MM/DD');
/**
    gr_param.date_from           :=  iv_date_from;           -- 06 : 出庫日From
    gr_param.date_to             :=  iv_date_to;             -- 07 : 出庫日To
**/
-- UPDATE END 2008/5/20 YTabata --
    gr_param.design_no           :=  iv_design_no;           -- 08 : 製造番号
    gr_param.security_div        :=  iv_security_div;        -- 09 : 有償セキュリティ区分
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_deliver_to_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_deliver_to>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_design_item_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_design_item>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <lg_design_date_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <g_design_date>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                      <lg_design_no_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                        <g_design_no>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                          <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                        </g_design_no>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                      </lg_design_no_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    </g_design_date>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </lg_design_date_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_design_item>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_design_item_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_deliver_to>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_deliver_to_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vendor>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vendor_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </data_info>' ) ;
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
      errbuf                 OUT    VARCHAR2         -- エラーメッセージ
     ,retcode                OUT    VARCHAR2         -- エラーコード
     ,iv_vendor_code         IN     VARCHAR2         -- 01 : 取引先
     ,iv_deliver_to_code     IN     VARCHAR2         -- 02 : 配送先
     ,iv_design_item_code_01 IN     VARCHAR2         -- 03 : 製造品目１
     ,iv_design_item_code_02 IN     VARCHAR2         -- 04 : 製造品目２
     ,iv_design_item_code_03 IN     VARCHAR2         -- 05 : 製造品目３
     ,iv_date_from           IN     VARCHAR2         -- 06 : 出庫日From
     ,iv_date_to             IN     VARCHAR2         -- 07 : 出庫日To
     ,iv_design_no           IN     VARCHAR2         -- 08 : 製造番号
     ,iv_security_div        IN     VARCHAR2         -- 09 : 有償セキュリティ区分
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
        iv_vendor_code         -- 01 : 取引先
       ,iv_deliver_to_code     -- 02 : 配送先
       ,iv_design_item_code_01 -- 03 : 製造品目１
       ,iv_design_item_code_02 -- 04 : 製造品目２
       ,iv_design_item_code_03 -- 05 : 製造品目３
       ,iv_date_from           -- 06 : 出庫日From
       ,iv_date_to             -- 07 : 出庫日To
       ,iv_design_no           -- 08 : 製造番号
       ,iv_security_div        -- 09 : 有償セキュリティ区分
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
END xxpo440006c ;
/
