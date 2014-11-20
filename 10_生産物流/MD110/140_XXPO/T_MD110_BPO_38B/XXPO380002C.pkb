CREATE OR REPLACE PACKAGE BODY xxpo380002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO380002C(body)
 * Description      : 発注依頼書
 * MD.050/070       : 発注依頼作成Issue1.0  (T_MD050_BPO_380)
 *                    発注依頼作成Issue1.0  (T_MD070_BPO_38B)
 * Version          : 1.5
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_initialize            PROCEDURE : 前処理(B-1)
 *  prc_get_report_data       PROCEDURE : データ取得(B-2)
 *  prc_create_xml_data       PROCEDURE : データ出力(B-3)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/06    1.0   Syogo Chinen     新規作成
 *  2008/06/17    1.1   T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/24    1.2   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/27    1.3   T.Ikehara        明細が最大行出力（30行出力）の時に、
 *                                       合計が次ページに表示される現象を修正
 *  2008/07/04    1.4   I.Higa           TEMP領域エラー回避のため、xxcmn_item_categories4_vを
 *                                       使用しないようにする
 *  2010/03/31    1.5   M.Hokkanji       [E_本稼働_02089]対応
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
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo380002c' ;   -- パッケージ名
  gv_sql                  VARCHAR2(32000) ;                          -- データ取得用ＳＱＬ
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := USERENV('LANG') ;
  gc_lookup_type_ship_type      CONSTANT VARCHAR2(100) := 'XXPO_DROP_SHIP_TYPE' ;
--
  ------------------------------
  -- 発注依頼明細アドオン
  ------------------------------
  gc_cancelled_flg              CONSTANT VARCHAR2(1)   := 'N' ;
--
  ------------------------------
  -- 発注依頼ヘッダアドオン
  ------------------------------
  gc_status                     CONSTANT VARCHAR2(30)   := '10' ;
  gc_status2                    CONSTANT VARCHAR2(30)   := '15' ;
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
  ------------------------------
  -- 商品カテゴリ関連
  ------------------------------
  gc_cat_set_prod_class         CONSTANT VARCHAR2(100) := '商品区分' ;
-- Ver1.5 M.Hokkanji Start
  ------------------------------
  -- パーティサイト
  ------------------------------
  gc_status_a                   CONSTANT VARCHAR2(1) := 'A' ;
-- Ver1.5 M.Hokkanji End
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN' ;         -- アプリケーション（XXCMN）
  gc_application_po   CONSTANT VARCHAR2(5)   := 'XXPO' ;          -- アプリケーション（XXPO）
  gv_msg_xxpo00009    CONSTANT VARCHAR2(100) := 'APP-XXPO-00009'; -- 明細0件用メッセージ
  gv_msg_xxpo10026    CONSTANT VARCHAR2(100) := 'APP-XXPO-10026'; -- データ未取得メッセージ
  gv_msg_xxpo10081    CONSTANT VARCHAR2(100) := 'APP-XXPO-10081'; -- 担当者名未取得メッセージ
  gv_msg_xxpo10082    CONSTANT VARCHAR2(100) := 'APP-XXPO-10082'; -- 担当部署名未取得メッセージ
  gv_msg_xxpo30022    CONSTANT VARCHAR2(100) := 'APP-XXPO-30022'; -- パラメータ受取
--
  -- トークン
  gv_tkn_table        CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_param        CONSTANT VARCHAR2(100) := 'PARAM';
  gv_tkn_ng_data      CONSTANT VARCHAR2(100) := 'DATA';
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format   CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
      iv_po_number            xxpo_requisition_headers.po_header_number%TYPE    --   01 :発注番号
     ,iv_division_code        xxcmn_locations_v.location_code%TYPE              --   02 :依頼部署
     ,iv_employee_number      per_all_people_f.employee_number%TYPE             --   03 :担当者
     ,iv_location_code        xxcmn_locations_v.location_code%TYPE              --   04 :発注部署
     ,iv_creation_date_f      VARCHAR2(21)                                      --   05 :作成日FROM
     ,iv_creation_date_t      VARCHAR2(21)                                      --   06 :作成日TO
     ,iv_vendor_code          xxcmn_vendors_v.segment1%TYPE                     --   07 :取引先
     ,iv_promised_date_f      VARCHAR2(20)                                      --   08 :納入日FROM
     ,iv_promised_date_t      VARCHAR2(20)                                      --   09 :納入日TO
     ,iv_whse_code            xxcmn_item_locations_v.segment1%TYPE              --   10 :納入先
     ,iv_prod_class_code      xxpo_categories_v.category_set_id%TYPE            --   11 :商品区分
     ,iv_item_class_code      xxpo_categories_v.category_set_id%TYPE            --   12 :品目区分
    ) ;
--
  -- 発注依頼書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
      header_number            xxpo_requisition_headers.po_header_number%TYPE   -- 発注番号
     ,v_segment1               xxcmn_vendors_v.segment1%TYPE                    -- 仕入先番号
     ,vendor_full_name         xxcmn_vendors_v.vendor_full_name%TYPE            -- 取引先：正式名
     ,promised_date            xxpo_requisition_headers.promised_date%TYPE      -- 納入日
     ,i_segment1               xxcmn_item_locations_v.segment1%TYPE             -- 保管倉庫コード
     ,i_description            xxcmn_item_locations_v.description%TYPE          -- 保管倉庫名
     ,f_meaning                fnd_lookup_values.meaning%TYPE                   -- 内容(直送区分)
     ,r_request_code xxpo_requisition_headers.requested_to_department_code%TYPE -- 依頼先部署コード
     ,location_short_name      xxcmn_locations_v.location_short_name%TYPE       -- 略称
     ,r_description            xxpo_requisition_headers.description%TYPE        -- 摘要
     ,item_no                  xxcmn_item_mst_v.item_no%TYPE                    -- 品目
     ,item_name                xxcmn_item_mst_v.item_name%TYPE                  -- 正式名
     ,pack_quantity            xxpo_requisition_lines.pack_quantity%TYPE        -- 入数
     ,requested_quantity       xxpo_requisition_lines.requested_quantity%TYPE   -- 依頼数量
     ,requested_uom   xxpo_requisition_lines.requested_quantity_uom%TYPE      -- 依頼数量単位コード
     ,requested_date           xxpo_requisition_lines.requested_date%TYPE      -- 日付指定
     ,l_description            xxpo_requisition_lines.description%TYPE         -- 摘要
     ,prov_ship_code           VARCHAR2(100)                                   -- 支給/出荷コード
     ,prov_ship_name           VARCHAR2(100)                                   -- 支給/出荷正式名
     ,prov_ship_zip            VARCHAR2(100)                                   -- 支給/出荷郵便番号
     ,prov_ship_address1       VARCHAR2(100)                                   -- 支給/出荷住所１
     ,prov_ship_address2       VARCHAR2(100)                                   -- 支給/出荷住所２
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gn_user_id          fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ; --ログインユーザーＩＤ
  gr_param            rec_param_data ;                                   --パラメータ
  gv_user_dept        xxcmn_locations_all.location_short_name%TYPE DEFAULT NULL; -- 担当部署
  gv_user_name        per_all_people_f.per_information18%TYPE DEFAULT NULL;      -- 担当者
--
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12) ;            -- 帳票ID
  gd_exec_date              DATE         ;            -- 実施日
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
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
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- プログラム名
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
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(B-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_err_flg            NUMBER DEFAULT 0 ;
--
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION ;     -- 値取得エラー
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 担当部署名取得
    -- ====================================================
    gv_user_dept := substrb(xxcmn_common_pkg.get_user_dept( gn_user_id ),0,10) ;
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := substrb(xxcmn_common_pkg.get_user_name( gn_user_id ),0,14) ;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn ;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : データ取得(B-2)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
      ot_data_rec          OUT  NOCOPY tab_data_type_dtl -- 取得レコード群
     ,ov_errbuf            OUT  VARCHAR2                 -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT  VARCHAR2                 -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT  VARCHAR2                 -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
    cv_table_name CONSTANT VARCHAR2(15) := '発注依頼';             -- テーブル名
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
    -- *** ローカル・定数 ***
    lc_drop_ship_type1      VARCHAR2(30) := '通常' ;     -- 直送区分
    lc_drop_ship_type2      VARCHAR2(30) := '出荷' ;     -- 直送区分
    lc_drop_ship_type3      VARCHAR2(30) := '支給' ;     -- 直送区分
--
    cv_ja          CONSTANT VARCHAR2(10) := 'JA' ;       -- 日本語
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＥＬＥＣＴ句生成
    -- ====================================================
    lv_select := ' SELECT'
      || ' xrh.po_header_number                 AS header_number'            -- 発注番号
      || ',xv.segment1                          AS v_segment1'               -- 仕入先番号
      || ',substrb(xv.vendor_full_name,0,60)    AS vendor_full_name'         -- 取引先：正式名
      || ',xrh.promised_date                    AS promised_date'            -- 納入日
      || ',xilv.segment1                        AS i_segment1'               -- 保管倉庫コード
      || ',substrb(xilv.description,0,60)       AS i_description'            -- 保管倉庫名
      || ',flv.meaning                          AS f_meaning'                -- 内容(直送区分)
      || ',xrh.requested_to_department_code     AS r_request_code'           -- 依頼先部署コード
      || ',substrb(xl.location_short_name,0,60) AS location_short_name'      -- 略称
      || ',substrb(xrh.description,0,60)        AS r_description'            -- 摘要
      || ',ximv.item_no                         AS item_no'                  -- 品目
      || ',substrb(ximv.item_name,0,40)         AS item_name'                -- 正式名
      || ',xrl.pack_quantity                    AS pack_quantity'            -- 入数
      || ',xrl.requested_quantity               AS requested_quantity'       -- 依頼数量
      || ',xrl.requested_quantity_uom           AS requested_uom'            -- 依頼数量単位コード
      || ',xrl.requested_date                   AS requested_date'           -- 日付指定
      || ',substrb(xrl.description,0,40)        AS l_description'            -- 摘要
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2 || ''',xpsv.party_site_number,'
      || '                     ''' || lc_drop_ship_type3 || ''',xvsv.vendor_site_code,'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_code'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.party_site_full_name,0,60),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.vendor_site_name,0,60),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_name'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2 || ''',xpsv.zip,'
      || '                     ''' || lc_drop_ship_type3 || ''',xvsv.zip,'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_zip'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.address_line1,0,30),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.address_line1,0,30),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_address1'
      || ',DECODE(flv.meaning, ''' || lc_drop_ship_type2
      || ''',substrb(xpsv.address_line2,0,30),'
      || '                     ''' || lc_drop_ship_type3
      || ''',substrb(xvsv.address_line2,0,30),'
      || '                     ''' || lc_drop_ship_type1 || ''',NULL,NULL)  AS prov_ship_address2'
      ;
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from := ' FROM'
      || ' xxpo_requisition_headers             xrh'                -- 発注依頼ヘッダアドオン
      || ',xxpo_requisition_lines               xrl'                -- 発注依頼明細アドオン
      || ',xxcmn_vendors2_v                     xv'                 -- 仕入先情報VIEW
      || ',xxcmn_item_mst2_v                    ximv'               -- OPM品目情報VIEW
      || ',xxcmn_locations2_v                   xl'                 -- 事業所情報VIEW
      || ',xxcmn_item_locations2_v              xilv'               -- OPM保管場所情報VIEW
      || ',(SELECT mcb.segment1  AS category_code '    -- XXPOカテゴリ情報VIEW（商品
      || ',        mcst.category_set_name '
      || ',        gic.item_id '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb, '
      || '   gmi_item_categories    gic '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || cv_ja || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   gic.category_set_id   = mcsb.category_set_id '
      || '  AND   gic.category_id       = mcb.category_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_prod_class || '''' || ') ctgg'
      || ',(SELECT mcb.segment1  AS category_code '    -- XXPOカテゴリ情報VIEW（品目
      || ',        mcst.category_set_name '
      || ',        gic.item_id '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb, '
      || '   gmi_item_categories    gic '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || cv_ja || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   gic.category_set_id   = mcsb.category_set_id '
      || '  AND   gic.category_id       = mcb.category_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') ctgi'
      || ',fnd_lookup_values                    flv '               -- クイックコード
      || ',xxcmn_party_sites2_v                 xpsv'               -- パーティサイト情報VIEW
      || ',xxcmn_vendor_sites2_v                xvsv'               -- 仕入先サイト情報VIEW
      ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := ' WHERE'
      || '     xrh.requisition_header_id          = xrl.requisition_header_id'
      || ' AND xrh.vendor_id                      = xv.vendor_id(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xv.start_date_active(+) AND xv.end_date_active(+)'
      || ' AND xrh.location_code                  = xilv.segment1'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format  || ''') >= xilv.date_from'
      || ' AND (   ( xilv.date_to IS NULL)'
      || '      OR (    (xilv.date_to IS NOT NULL)'
      || '          AND (xilv.date_to >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f
                                                  || ''',''' || gc_char_dt_format  || '''))))'
      || ' AND xrl.item_id                        = ximv.item_id'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN ximv.start_date_active AND ximv.end_date_active'
      || ' AND   (  xrh.status =  ''' || gc_status || ''''
      ||       ' OR xrh.status = ''' || gc_status2 || ''')'
      || ' AND xrl.cancelled_flg = ''' || gc_cancelled_flg || ''''
      || ' AND xrh.requested_to_department_code   = xl.location_code'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xl.start_date_active AND xl.end_date_active'
      || ' AND flv.language                    = ''' || gc_language_code || ''''
      || ' AND flv.lookup_type                 = ''' || gc_lookup_type_ship_type || ''''
      || ' AND flv.lookup_code                 = xrh.drop_ship_type'
      || ' AND xrh.promised_date >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f
      || ''' , ''' || gc_char_dt_format || ''')'
      || ' AND xrh.delivery_code                  = xpsv.party_site_number(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xpsv.start_date_active(+) AND xpsv.end_date_active(+)'
-- Ver1.5 M.Hokkanji Start
      || ' AND xpsv.party_site_status(+) = ''' || gc_status_a || ''''
      || ' AND xpsv.cust_acct_site_status(+) = ''' || gc_status_a || ''''
      || ' AND xpsv.cust_site_uses_status(+) = ''' || gc_status_a || ''''
-- Ver1.5 M.Hokkanji End
      || ' AND xrh.delivery_code                  = xvsv.vendor_site_code(+)'
      || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_f || ''','''
                                           || gc_char_dt_format || ''')'
      || '     BETWEEN xvsv.start_date_active(+) AND xvsv.end_date_active(+)'
      ;
    -- ----------------------------------------------------
    -- パラメータ指定による条件
    -- ----------------------------------------------------
    -- 発注番号
    IF ( gr_param.iv_po_number IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.po_header_number = ''' || gr_param.iv_po_number || ''''
        ;
    END IF ;
    -- 依頼部署
    IF ( gr_param.iv_division_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_dept_code = ''' || gr_param.iv_division_code || ''''
        ;
    END IF ;
    -- 担当者
    IF ( gr_param.iv_employee_number IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_by_code = ''' || gr_param.iv_employee_number || ''''
        ;
    END IF ;
    -- 発注部署
    IF ( gr_param.iv_location_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.requested_to_department_code = ''' || gr_param.iv_location_code || ''''
        ;
    END IF ;
    -- 作成日from
    IF ( gr_param.iv_creation_date_f IS NOT NULL ) THEN
      lv_where := lv_where
        || 'AND xrh.creation_date >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_creation_date_f
        || ''',''' || gc_char_dt_format || ''')'
        ;
    END IF ;
    -- 作成日to
    IF ( gr_param.iv_creation_date_t IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.creation_date <= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_creation_date_t
        || ''',''' || gc_char_dt_format || ''')'
        ;
    END IF ;
    -- 取引先
    IF ( gr_param.iv_vendor_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.vendor_code = ''' || gr_param.iv_vendor_code || ''''
        ;
    END IF ;
    -- 納入先
    IF ( gr_param.iv_whse_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.location_code = ''' || gr_param.iv_whse_code || ''''
        ;
    END IF ;
    -- 納入日to
    IF ( gr_param.iv_promised_date_t IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrh.promised_date <= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t
        || ''',''' || gc_char_dt_format || ''')'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xl.start_date_active AND xl.end_date_active'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xv.start_date_active(+) AND xv.end_date_active(+)'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN ximv.start_date_active AND ximv.end_date_active'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format  || ''') >= xilv.date_from'
        || ' AND (   ( xilv.date_to IS NULL)'
        || '      OR (    (xilv.date_to IS NOT NULL)'
        || '        AND (xilv.date_to >= FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t
                                                  || ''',''' || gc_char_dt_format  || '''))))'
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xpsv.start_date_active(+) AND xpsv.end_date_active(+) '
        || ' AND FND_DATE.STRING_TO_DATE(''' || gr_param.iv_promised_date_t || ''','''
                                             || gc_char_dt_format || ''')'
        || '     BETWEEN xvsv.start_date_active(+) AND xvsv.end_date_active(+) '
        ;
    END IF ;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ（商品区分）の絞込み条件
    lv_where := lv_where
      || ' AND ximv.item_id                          = ctgg.item_id'
      ;
    -- 商品区分が入力されている場合
    IF (gr_param.iv_prod_class_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND ctgg.category_code   = ''' || gr_param.iv_prod_class_code || ''''
      ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ（品目区分）の絞込み条件
    lv_where := lv_where
      || ' AND ximv.item_id                          = ctgi.item_id'
      ;
    -- 品目区分が入力されている場合
    IF (gr_param.iv_item_class_code IS NOT NULL) THEN
      lv_where := lv_where
      || ' AND ctgi.category_code   = ''' || gr_param.iv_item_class_code || ''''
      ;
    END IF;
--
    -- ====================================================
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xrh.po_header_number'
      || ',xv.segment1'
      || ',xrh.promised_date'
      || ',xrh.location_code'
      || ',xrl.requisition_line_number'
      ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    gv_sql := lv_select || lv_from || lv_where || lv_order_by ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR gv_sql ;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE lc_ref ;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
      ov_errbuf             OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT    VARCHAR2         --   リターン・コード             --# 固定 #
     ,ov_errmsg             OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
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
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init          VARCHAR2(100) := '*' ;       -- 取引先名
    lc_break_null          VARCHAR2(100) := '**' ;      -- 品目区分
    lc_max_cnt             NUMBER        := 30 ;        -- 明細MAX行数
    lc_drop_ship_type1     VARCHAR2(30) := '通常' ;     -- 直送区分
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_po_header_no        VARCHAR2(100) DEFAULT '*' ;  -- 発注番号
    lv_key_break           VARCHAR2(100) DEFAULT '*' ;  -- キーブレイク
    ln_cnt                 NUMBER DEFAULT 0;            -- 明細件数
    ln_total               NUMBER DEFAULT 0;            -- 合計数
--
    -- *** ローカル・例外処理 ***
    no_data_expt                 EXCEPTION ;            -- 取得レコードなし
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data (
        ot_data_rec   => gt_main_data   --    取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
--
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
    -- 実施日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'output_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- 担当部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charge_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_user_dept ;
    -- 担当者名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'agent' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_user_name ;
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 発注依頼ＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- =====================================================
      -- 発注番号ブレイク
      -- =====================================================
      -- 発注番号が切り替わった場合
      IF ( NVL( gt_main_data(i).header_number, lc_break_null ) <> lv_po_header_no ) THEN
--
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_key_break <> lc_break_init ) THEN
--
          IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
            AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
            IF ((ln_cnt MOD lc_max_cnt) <> 0) THEN
              -- 空行の作成
              <<blank_loop>>
              FOR i IN 1 .. lc_max_cnt - (ln_cnt MOD lc_max_cnt) LOOP
--
                -- -----------------------------------------------------
                -- 明細LＧ開始タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- 明細Ｇ開始タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- 明細Ｇデータタグ出力
                -- -----------------------------------------------------
                -- 品目コード
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
                gt_xml_data_table(gl_xml_idx).tag_value := NULL;
                -- -----------------------------------------------------
                -- 明細Ｇ終了タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- 明細LＧ終了タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
              END LOOP blank_loop;
--
            END IF;
          END IF;
--
          -- -----------------------------------------------------
          -- 合計LＧ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 合計Ｇ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 明細Ｇデータタグ出力
          -- -----------------------------------------------------
          -- 合計
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_total;
          -- -----------------------------------------------------
          -- 合計Ｇ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 合計LＧ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- 件数、合計クリア
          ln_cnt   := 0;
          ln_total := 0;
--
          -- -----------------------------------------------------
          -- 発注依頼Ｇ終了タグ
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_order_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- 発注依頼Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_order_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- 注文No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).header_number ;
        -- 取引先：取引先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_segment1 ;
        -- 取引先：取引先名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_full_name ;
        -- 納入日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=
          TO_CHAR(gt_main_data(i).promised_date, gc_char_d_format ) ;
        -- 納入先：納入先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_segment1 ;
        -- 納入先：納入先名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).i_description ;
--
        -- ====================================================
        -- 支給/出荷
        -- ====================================================
        IF (lc_drop_ship_type1 <> gt_main_data(i).f_meaning ) THEN
          -- 見出
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_title' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).f_meaning ;
        ELSE
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_title' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := '' ;
        END IF ;
--
        IF (gt_main_data(i).prov_ship_code IS NOT NULL )
          OR (gt_main_data(i).prov_ship_name IS NOT NULL) THEN
          -- コロン
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision1' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ':' ;
        END IF ;
--
        -- 支給/出荷コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_code ;
        -- 支給/出荷正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_name ;
--
        IF (gt_main_data(i).prov_ship_zip IS NOT NULL )
          OR (gt_main_data(i).prov_ship_address1 IS NOT NULL)
          OR (gt_main_data(i).prov_ship_address2 IS NOT NULL) THEN
          -- コロン
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision2' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ':' ;
        END IF ;
--
        -- 支給/出荷郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_zip' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_zip ;
        -- 支給/出荷住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_address1 ;
        -- 支給/出荷住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_provision_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prov_ship_address2 ;
--
        -- 発注部署コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_dept_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).r_request_code ;
        -- 発注部署名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_dept_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).location_short_name ;
        -- 摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).r_description ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_po_header_no  := NVL( gt_main_data(i).header_number, lc_break_null )  ;
        lv_key_break   := lc_break_null ;
--
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      -- -----------------------------------------------------
      -- 明細LＧ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_no ;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_name ;
      -- 入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).pack_quantity ;
      -- 依頼数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'request_quantity' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).requested_quantity ;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_of_measure' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).requested_uom ;
      -- 日付指定
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'specify_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).requested_date, gc_char_d_format ) ;
      -- 明細摘要
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'line_description' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_description ;
      -- -----------------------------------------------------
      -- 明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細LＧ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- 依頼数合計
      ln_total := ln_total + gt_main_data(i).requested_quantity ;
--
      IF ln_cnt = lc_max_cnt THEN
         ln_cnt := 0;
      END IF;
--
      -- 明細件数カウント
      ln_cnt := ln_cnt + 1;
    END LOOP main_data_loop ;
--
    IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
      AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
      IF ((ln_cnt MOD lc_max_cnt) <> 0) THEN
        -- 空行の作成
        <<blank_loop>>
        FOR i IN 1 .. lc_max_cnt - ln_cnt LOOP
--
          -- -----------------------------------------------------
          -- 明細LＧ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 明細Ｇ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 明細Ｇデータタグ出力
          -- -----------------------------------------------------
          -- 品目コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- -----------------------------------------------------
          -- 明細Ｇ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 明細LＧ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP blank_loop;
--
      END IF;
    END IF;
--
    -- -----------------------------------------------------
    -- 合計LＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 合計Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 明細Ｇデータタグ出力
    -- -----------------------------------------------------
    -- 合計
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_total;
    -- -----------------------------------------------------
    -- 合計Ｇ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 合計LＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 発注依頼Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 発注依頼ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_order_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- データＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg := xxcmn_common_pkg.get_msg(gc_application_po,gv_msg_xxpo00009);
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain (
      ov_errbuf            OUT     VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT     VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT     VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_po_number         IN      VARCHAR2         --   01 : 発注番号
     ,iv_division_code     IN      VARCHAR2         --   02 : 依頼部署
     ,iv_employee_number   IN      VARCHAR2         --   03 : 担当者
     ,iv_location_code     IN      VARCHAR2         --   04 : 発注部署
     ,iv_creation_date_f   IN      VARCHAR2         --   05 : 作成日FROM
     ,iv_creation_date_t   IN      VARCHAR2         --   06 : 作成日TO
     ,iv_vendor_code       IN      VARCHAR2         --   07 : 取引先
     ,iv_promised_date_f   IN      VARCHAR2         --   08 : 納入日FROM
     ,iv_promised_date_t   IN      VARCHAR2         --   09 : 納入日TO
     ,iv_whse_code         IN      VARCHAR2         --   10 : 納入先
     ,iv_prod_class_code   IN      VARCHAR2         --   11 : 商品区分
     ,iv_item_class_code   IN      VARCHAR2         --   12 : 品目区分
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    cv_table_name  CONSTANT VARCHAR2(15) := '発注依頼';  -- テーブル名
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
--
    lv_xml_string           VARCHAR2(32000) ;
    lv_worn_msg             VARCHAR2(5000) DEFAULT NULL;  --   ユーザー・エラー・メッセージ
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
    -- 帳票出力値格納
    gv_report_id              := 'XXPO380002T' ;      -- 帳票ID
    gd_exec_date              := SYSDATE ;            -- 実施日
    -- パラメータ格納
    gr_param.iv_po_number        := iv_po_number ;       --   01 : 発注番号
    gr_param.iv_division_code    := iv_division_code ;   --   02 : 依頼部署
    gr_param.iv_employee_number  := iv_employee_number ; --   03 : 担当者
    gr_param.iv_location_code    := iv_location_code ;   --   04 : 発注部署
    gr_param.iv_creation_date_f  := iv_creation_date_f ; --   05 : 作成日FR
    gr_param.iv_creation_date_t  := iv_creation_date_t ; --   06 : 作成日TO
    gr_param.iv_vendor_code      := iv_vendor_code ;     --   07 : 取引先
    gr_param.iv_promised_date_f  := iv_promised_date_f ; --   08 : 納入日FR
    gr_param.iv_promised_date_t  := iv_promised_date_t ; --   09 : 納入日TO
    gr_param.iv_whse_code        := iv_whse_code ;       --   10 : 納入先
    gr_param.iv_prod_class_code  := iv_prod_class_code ; --   11 : 商品区分
    gr_param.iv_item_class_code  := iv_item_class_code ; --   12 : 品目区分
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize (
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- データ取得
    -- =====================================================
    prc_create_xml_data (
        ov_errbuf         =>     lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        =>     lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg         =>     lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
      AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_order_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,gv_msg_xxpo10026
                                             ,gv_tkn_table
                                             ,cv_table_name ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ＸＭＬヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- ＸＭＬデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- ＸＭＬフッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
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
  PROCEDURE main (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_po_number          IN     VARCHAR2         --   01 : 発注番号
     ,iv_division_code      IN     VARCHAR2         --   02 : 依頼部署
     ,iv_employee_number    IN     VARCHAR2         --   03 : 担当者
     ,iv_location_code      IN     VARCHAR2         --   04 : 発注部署
     ,iv_creation_date_f    IN     VARCHAR2         --   05 : 作成日FROM
     ,iv_creation_date_t    IN     VARCHAR2         --   06 : 作成日TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : 取引先
     ,iv_promised_date_f    IN     VARCHAR2         --   08 : 納入日FROM
     ,iv_promised_date_t    IN     VARCHAR2         --   09 : 納入日TO
     ,iv_whse_code          IN     VARCHAR2         --   10 : 納入先
     ,iv_prod_class_code    IN     VARCHAR2         --   11 : 商品区分
     ,iv_item_class_code    IN     VARCHAR2         --   12 : 品目区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- プログラム名
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
    submain (
        ov_errbuf             =>     lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            =>     lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg             =>     lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_po_number          =>     iv_po_number        -- 01 : 発注番号
       ,iv_division_code      =>     iv_division_code    -- 02 : 依頼部署
       ,iv_employee_number    =>     iv_employee_number  -- 03 : 担当者
       ,iv_location_code      =>     iv_location_code    -- 04 : 発注部署
       ,iv_creation_date_f    =>     iv_creation_date_f  -- 05 : 作成日FROM
       ,iv_creation_date_t    =>     iv_creation_date_t  -- 06 : 作成日TO
       ,iv_vendor_code        =>     iv_vendor_code      -- 07 : 取引先
       ,iv_promised_date_f    =>     iv_promised_date_f  -- 08 : 納入日FROM
       ,iv_promised_date_t    =>     iv_promised_date_t  -- 09 : 納入日TO
       ,iv_whse_code          =>     iv_whse_code        -- 10 : 納入先
       ,iv_prod_class_code    =>     iv_prod_class_code  -- 11 : 商品区分
       ,iv_item_class_code    =>     iv_item_class_code  -- 12 : 品目区分
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --ステータスセット
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  固定部 END   #######################################################
--
END xxpo380002c ;
/
