CREATE OR REPLACE PACKAGE BODY xxpo440003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440003(body)
 * Description      : 入庫予定表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44K)
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_sql              PROCEDURE : データ取得ＳＱＬ生成
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ編集
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/26    1.0   Masayuki Ikeda   新規作成
 *  2008/06/04    1.1 Yasuhisa Yamamoto  結合テスト不具合ログ#440_53
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
--  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo440003C' ;      -- パッケージ名
--  gc_report_id            CONSTANT VARCHAR2(20) := 'xxpo440003T' ;      -- 帳票ID
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXPO440003C' ;      -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXPO440003T' ;      -- 帳票ID
-- 2008/06/04 UPD END Y.Yamamoto
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
  -- パラメータ：使用目的
  gc_use_purpose_irai     CONSTANT VARCHAR2(1) := '1' ;     -- 依頼
  gc_use_purpose_shij     CONSTANT VARCHAR2(1) := '2' ;     -- 指示
  -- パラメータ：有償セキュリティ区分
  gc_security_div_i       CONSTANT VARCHAR2(1) := '1' ;     -- 伊藤園
  gc_security_div_d       CONSTANT VARCHAR2(1) := '2' ;     -- 取引先
  gc_security_div_l       CONSTANT VARCHAR2(1) := '3' ;     -- 出庫倉庫
  -- 受注カテゴリ：受注カテゴリコード
  gc_order_cat_o          CONSTANT VARCHAR2(10) := 'ORDER' ;
  gc_order_cat_r          CONSTANT VARCHAR2(10) := 'RETURN' ;
  -- 受注カテゴリ：出荷支給区分
  gc_sp_class_ship        CONSTANT VARCHAR2(1)  := '1' ;    -- 出荷依頼
  gc_sp_class_prov        CONSTANT VARCHAR2(1)  := '2' ;    -- 支給依頼
  gc_sp_class_move        CONSTANT VARCHAR2(1)  := '3' ;    -- 移動
  -- 受注カテゴリ：出荷支給受払カテゴリ
  gc_sp_rp_cat_miho       CONSTANT VARCHAR2(2)  := '01' ;   -- 見本出庫
  gc_sp_rp_cat_haik       CONSTANT VARCHAR2(2)  := '02' ;   -- 廃棄出庫
  gc_sp_rp_cat_nkur       CONSTANT VARCHAR2(2)  := '03' ;   -- 倉替入庫
  gc_sp_rp_cat_nhen       CONSTANT VARCHAR2(2)  := '04' ;   -- 返品入庫
  gc_sp_rp_cat_ysyu       CONSTANT VARCHAR2(2)  := '05' ;   -- 有償出荷
  gc_sp_rp_cat_yhen       CONSTANT VARCHAR2(2)  := '06' ;   -- 有償返品
  -- 受注ヘッダアドオン：最新フラグ（YesNo区分）
  gc_yn_div_y             CONSTANT VARCHAR2(1)  := 'Y' ;    -- YES
  gc_yn_div_n             CONSTANT VARCHAR2(1)  := 'N' ;    -- NO
  -- 受注ヘッダアドオン：ステータス
  gc_req_status_s_inp     CONSTANT VARCHAR2(2)  := '05' ;   -- 入力中
  gc_req_status_s_cmpa    CONSTANT VARCHAR2(2)  := '06' ;   -- 入力完了
  gc_req_status_s_cmpb    CONSTANT VARCHAR2(2)  := '07' ;   -- 受領済
  gc_req_status_s_cmpc    CONSTANT VARCHAR2(2)  := '08' ;   -- 出荷実績計上済
  gc_req_status_p_ccl     CONSTANT VARCHAR2(2)  := '99' ;   -- 取消
  -- 受注ヘッダアドオン：通知ステータス
  gc_notif_status_no      CONSTANT VARCHAR2(2)  := '10' ;   -- 未通知
  gc_notif_status_re      CONSTANT VARCHAR2(2)  := '20' ;   -- 再通知要
  gc_notif_status_ok      CONSTANT VARCHAR2(2)  := '40' ;   -- 確定通知済
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
  -- ＯＰＭ品目マスタ：ロット管理区分
  gc_lot_ctl_y            CONSTANT VARCHAR2(1) := '1' ;     -- ロット管理あり
  gc_lot_ctl_n            CONSTANT VARCHAR2(1) := '0' ;     -- ロット管理なし
  ------------------------------
  -- その他
  ------------------------------
  -- 品目区分
  gc_item_div_gen         CONSTANT VARCHAR2(1)  := '1' ;  -- 原料
  gc_item_div_shi         CONSTANT VARCHAR2(1)  := '2' ;  -- 資材
  gc_item_div_han         CONSTANT VARCHAR2(1)  := '4' ;  -- 半製品
  gc_item_div_sei         CONSTANT VARCHAR2(1)  := '5' ;  -- 製品
  gc_max_date_char        CONSTANT VARCHAR2(10) := '4712/12/31' ;
  -- 帳票タイトル
  gc_report_name_irai     CONSTANT VARCHAR2(20) := '入庫予定表（依頼）' ;
  gc_report_name_shij     CONSTANT VARCHAR2(20) := '入庫予定表（指示）' ;
--
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD
    (
      use_purpose       VARCHAR2(1)   -- 01 : 使用目的
     ,deliver_to_code   VARCHAR2(4)   -- 02 : 配送先
     ,date_from         VARCHAR2(10)  -- 03 : 出庫日From
     ,date_to           VARCHAR2(10)  -- 04 : 出庫日To
     ,prod_div          VARCHAR2(1)   -- 05 : 商品区分
     ,item_div          VARCHAR2(1)   -- 06 : 品目区分
     ,item_code         VARCHAR2(7)   -- 07 : 品目
     ,locat_code        VARCHAR2(4)   -- 08 : 出庫倉庫
     ,security_div      VARCHAR2(1)   -- 09 : 有償セキュリティ区分
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- 処理データカウンタ
  gv_sql                VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
--
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER DEFAULT 0 ;    -- ＸＭＬデータタグ表のインデックス
--
  gn_user_id            fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID ;   -- ログインユーザーＩＤ
  gv_report_name        VARCHAR2(20)  ;       -- 帳票タイトル
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
    -- 実行日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( SYSDATE, 'YYYY/MM/DD HH24:MI:SS' ) ;
    -- ログインユーザー：所属部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
        := xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ) ;
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
   * Procedure Name   : prc_create_sql
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
      || ' xvs.vendor_site_code         AS deliver_to_code'   -- 配送先コード
      || ',xvs.vendor_site_short_name   AS deliver_to_name'   -- 配送先名称
      || ',TO_CHAR( xoha.schedule_arrival_date,''YYYY/MM/DD'' ) AS ship_in_date'  -- 入庫日
      || ',xic.prod_class_code          AS prod_div'          -- 商品区分
      || ',xic.prod_class_name          AS prod_div_name'     -- 商品区分名称
      || ',xic.item_class_code          AS item_div'          -- 品目区分
      || ',xic.item_class_name          AS item_div_name'     -- 品目区分名称
      || ',xim.item_id                  AS item_id'           -- 品目ＩＤ
      || ',xim.item_no                  AS item_code'         -- 品目コード
      || ',xim.item_short_name          AS item_name'         -- 品目名称
      || ',xim.lot_ctl                  AS lot_ctl'           -- ロット使用
      || ',xola.uom_code                AS uom_code'          -- 単位
      || ',xola.order_line_id           AS order_line_id'     -- 受注明細ＩＤ
      || ',xola.futai_code              AS futai_code'        -- 付帯
      || ',xil.segment1                 AS locat_code'        -- 出庫倉庫コード
      || ',xil.description              AS locat_name'        -- 出庫倉庫名称
      || ',TO_CHAR( xoha.schedule_ship_date ,''MM/DD'' ) AS ship_to_date'  -- 出庫日
      || ',xoha.request_no              AS request_no'        -- 依頼Ｎｏ
      || ',xoha.po_no                   AS order_no'          -- 発注Ｎｏ
      || ',xola.line_description        AS description'       -- 明細摘要
      || ',xim.frequent_qty             AS frequent_qty'      -- 入数
      ;
--
    -- 依頼の場合
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      lv_select := lv_select
        || ',xola.based_request_quantity  AS quantity' ;    -- 拠点依頼数量
    ELSE
      lv_select := lv_select
        || ',xola.quantity                AS quantity' ;    -- 数量
    END IF ;
--
    -- ====================================================
    -- ＦＲＯＭ句生成
    -- ====================================================
    lv_from := ' FROM'
      || ' oe_transaction_types_all   otta'   -- 受注タイプ
      || ',xxwsh_order_headers_all    xoha'   -- 受注ヘッダアドオン
      || ',xxwsh_order_lines_all      xola'   -- 受注明細アドオン
      || ',xxcmn_item_locations2_v    xil'    -- OPM保管場所マスタ
      || ',xxcmn_vendor_sites2_v      xvs'    -- 仕入先サイトView
      || ',xxcmn_item_mst2_v          xim'    -- OPM品目情報View
      || ',xxcmn_item_categories4_v   xic'    -- OPM品目カテゴリ割当View
      || ',xxpo_security_supply_v     xss'    -- 有償セキュリティView
      ;
--
    -- ====================================================
    -- ＷＨＥＲＥ句生成
    -- ====================================================
    lv_where := ' WHERE'
      || '     xss.user_id           = ' || gn_user_id
      || ' AND xss.security_class    = ' || gr_param.security_div
      || ' AND xil.segment1          = NVL( xss.segment1        , xil.segment1)'
      || ' AND xoha.vendor_code      = NVL( xss.vendor_code     , xoha.vendor_code )'
      || ' AND xoha.vendor_site_code = NVL( xss.vendor_site_code, xoha.vendor_site_code )'
      || ' AND xim.item_id                = xic.item_id'                  -- OPM品目カテゴリ割当結合
      || ' AND xoha.schedule_ship_date BETWEEN xim.start_date_active'
      ||                             ' AND     NVL( xim.end_date_active, xoha.schedule_ship_date )'
      || ' AND xola.shipping_item_code    = xim.item_no'                  -- OPM品目マスタ結合
      || ' AND NVL( xola.delete_flag, ''' || gc_yn_div_n || ''')'
      ||                                ' = ''' || gc_yn_div_n || ''''
      || ' AND xoha.order_header_id       = xola.order_header_id'         -- 受注明細アドオン結合
      || ' AND otta.org_id                = '   || gn_prof_org_id
      || ' AND otta.attribute1            = ''' || gc_sp_class_prov  || ''''
      || ' AND otta.attribute11           = ''' || gc_sp_rp_cat_ysyu || ''''
      || ' AND otta.order_category_code  <> ''' || gc_order_cat_r    || ''''
      || ' AND xoha.order_type_id         = otta.transaction_type_id'     -- 受注タイプ結合
      || ' AND xoha.schedule_ship_date BETWEEN xvs.start_date_active'
      ||                             ' AND     NVL( xvs.end_date_active, xoha.schedule_ship_date )'
      || ' AND xoha.vendor_site_id        = xvs.vendor_site_id'           -- 仕入先マスタ結合
      || ' AND xoha.deliver_from_id       = xil.inventory_location_id'    -- OPM保管場所マスタ結合
      || ' AND xoha.req_status           IN(''' || gc_req_status_s_cmpb || ''''
      ||                                  ',''' || gc_req_status_s_cmpc || ''')'
      || ' AND xoha.latest_external_flag  = ''' || gc_yn_div_y || ''''
      || ' AND xoha.schedule_arrival_date'
      ||          ' BETWEEN FND_DATE.CANONICAL_TO_DATE(''' || gr_param.date_from || ''')'
      ||          ' AND     FND_DATE.CANONICAL_TO_DATE(''' || gr_param.date_to   || ''')'
      ;
--
    -- ----------------------------------------------------
    -- 有償セキュリティ区分による条件
    -- ----------------------------------------------------
    -- パラメータ．使用目的が「指示」の場合
    IF ( gr_param.use_purpose = gc_use_purpose_shij ) THEN
      -- セキュリティ区分が「1（伊藤園）」の場合
      IF ( gr_param.security_div = gc_security_div_i ) THEN
        lv_where := lv_where
          || ' AND xola.quantity = xola.reserved_quantity'
          ;
      -- セキュリティ区分が「2（取引先）」の場合
      ELSIF ( gr_param.security_div = gc_security_div_d ) THEN
        lv_where := lv_where
          || ' AND xoha.notif_status = ''' || gc_notif_status_ok || ''''
          ;
      -- セキュリティ区分が「3（出庫倉庫）」の場合
      ELSE
        lv_where := lv_where
          || ' AND xoha.notif_status = ''' || gc_notif_status_ok || ''''
          ;
      END IF ;
    END IF ;
    -- ----------------------------------------------------
    -- パラメータ指定による条件
    -- ----------------------------------------------------
    -- 配送先
    IF ( gr_param.deliver_to_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xvs.vendor_site_code = ''' || gr_param.deliver_to_code || ''''
        ;
    END IF ;
    -- 商品区分
    IF ( gr_param.prod_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xic.prod_class_code = ''' || gr_param.prod_div || ''''
        ;
    END IF ;
    -- 品目区分
    IF ( gr_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xic.item_class_code = ''' || gr_param.item_div || ''''
        ;
    END IF ;
    -- 品目
    IF ( gr_param.item_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xim.item_no = ''' || gr_param.item_code || ''''
        ;
    END IF ;
    -- 出庫倉庫
    IF ( gr_param.locat_code IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xil.segment1 = ''' || gr_param.locat_code || ''''
        ;
    END IF ;
--
    -- ====================================================
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
      || ' xvs.vendor_site_code'
      || ',xoha.schedule_arrival_date'
      || ',xic.prod_class_code'
      || ',xic.item_class_code'
      || ',TO_NUMBER( xim.item_no )'
      || ',xola.futai_code'
      || ',xil.segment1'
      || ',xoha.schedule_ship_date'
      || ',xoha.request_no'
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
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    lc_init                 CONSTANT  VARCHAR2(1) := '*' ;
--
    -- ==================================================
    -- 変数宣言
    -- ==================================================
    -- ブレイク判断用変数
    lv_deliver_to_code      VARCHAR2(4)  DEFAULT lc_init ;
    lv_ship_in_date         VARCHAR2(10) DEFAULT lc_init ;
    lv_prod_div             VARCHAR2(1)  DEFAULT lc_init ;
    lv_item_div             VARCHAR2(1)  DEFAULT lc_init ;
    lv_item_code            VARCHAR2(7)  DEFAULT lc_init ;
    lv_futai_code           VARCHAR2(1)  DEFAULT lc_init ;
    lv_locat_code           VARCHAR2(4)  DEFAULT lc_init ;
    lv_ship_to_date         VARCHAR2(10) DEFAULT lc_init ;
    lv_request_no           VARCHAR2(12) DEFAULT lc_init ;
--
    --商品区分連番
    ln_position             NUMBER DEFAULT 0 ;
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    TYPE ref_cursor IS REF CURSOR ;
    TYPE ret_value  IS RECORD
      (
        deliver_to_code     xxcmn_vendor_sites2_v.vendor_site_code%TYPE         -- 配送先コード
       ,deliver_to_name     xxcmn_vendor_sites2_v.vendor_site_name%TYPE         -- 配送先名称
       ,ship_in_date        VARCHAR2(10)                                        -- 入庫日
       ,prod_div            xxcmn_item_categories4_v.prod_class_code%TYPE       -- 商品区分
       ,prod_div_name       xxcmn_item_categories4_v.prod_class_name%TYPE       -- 商品区分名称
       ,item_div            xxcmn_item_categories4_v.item_class_code%TYPE       -- 品目区分
       ,item_div_name       xxcmn_item_categories4_v.item_class_name%TYPE       -- 品目区分名称
       ,item_id             xxcmn_item_mst2_v.item_id%TYPE                      -- 品目ＩＤ
       ,item_code           xxcmn_item_mst2_v.item_no%TYPE                      -- 品目コード
       ,item_name           xxcmn_item_mst2_v.item_short_name%TYPE              -- 品目名称
       ,lot_ctl             xxcmn_item_mst2_v.lot_ctl%TYPE                      -- ロット使用
       ,uom_code            xxwsh_order_lines_all.uom_code%TYPE                 -- 単位
       ,order_line_id       xxwsh_order_lines_all.order_line_id%TYPE            -- 受注明細ＩＤ
       ,futai_code          xxwsh_order_lines_all.futai_code%TYPE               -- 付帯
       ,locat_code          mtl_item_locations.segment1%TYPE                    -- 出庫倉庫コード
       ,locat_name          mtl_item_locations.description%TYPE                 -- 出庫倉庫名称
       ,ship_to_date        VARCHAR2(10)                                        -- 出庫日
       ,request_no          xxwsh_order_headers_all.request_no%TYPE             -- 依頼Ｎｏ
       ,order_no            xxwsh_order_headers_all.po_no%TYPE                  -- 発注Ｎｏ
       ,description         xxwsh_order_lines_all.line_description%TYPE         -- 明細摘要
       ,frequent_qty        xxcmn_item_mst2_v.frequent_qty%TYPE                 -- 入数
       ,quantity            xxwsh_order_lines_all.based_request_quantity%TYPE   -- 数量
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    lc_sql_lot  VARCHAR2(32000)
      := ' SELECT ilm.lot_no             AS lot_no'
      || '       ,ilm.attribute1         AS product_date'
      || '       ,ilm.attribute3         AS use_by_date'
      || '       ,ilm.attribute2         AS original_char'
      || '       ,ilm.attribute6         AS frequent_qty'
      || '       ,xmld.actual_quantity   AS quantity'
      || ' FROM ic_lots_mst            ilm'
      || '     ,xxinv_mov_lot_details  xmld'
      || ' WHERE xmld.lot_id             = ilm.lot_id'
      || ' AND   xmld.item_id            = ilm.item_id'
      || ' AND   xmld.record_type_code   = ''' || gc_rec_type_inst || ''''    -- 10（指示）
      || ' AND   xmld.document_type_code = ''' || gc_doc_type_prov || ''''    -- 30（支給指示）
      || ' AND   xmld.mov_line_id        = :v1'
      || ' AND   xmld.item_id            = :v2'
      ;
    -- ORDER BY（製品）
    lc_sql_order_by_1     VARCHAR2(32000)
      := ' ORDER BY FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )'
      ||         ' ,ilm.attribute2'
      ;
    -- ORDER BY（製品以外）
    lc_sql_order_by_2     VARCHAR2(32000)
      := ' ORDER BY TO_NUMBER( ilm.lot_no )'
      ;
    -- ロット情報取得
    TYPE ret_value_lot  IS RECORD
      (
        lot_no            VARCHAR2(10)    -- ロットＮｏ
       ,product_date      VARCHAR2(10)    -- 製造年月日
       ,use_by_date       VARCHAR2(10)    -- 賞味期限
       ,original_char     VARCHAR2(6)     -- 固有記号
       ,frequent_qty      VARCHAR2(10)    -- 入数
       ,quantity          VARCHAR2(15)    -- 数量
      ) ;
    lc_ref_lot    ref_cursor ;
    lr_ref_lot    ret_value_lot ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR gv_sql ;
--
    -- ----------------------------------------------------
    -- 出庫倉庫グループ
    -- ----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      gn_data_cnt := gn_data_cnt + 1 ;
--
      -- ====================================================
      -- ブレイク判定：配送先グループ
      -- ====================================================
      IF ( lr_ref.deliver_to_code <> lv_deliver_to_code ) THEN
        -- ----------------------------------------------------
        -- 下層グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_deliver_to_code <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 入庫日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 入庫日リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 配送先グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 配送先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_code ;
        -- 配送先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.deliver_to_name ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（出庫日）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_deliver_to_code := lr_ref.deliver_to_code ;
        lv_ship_in_date    := lc_init ;
        lv_prod_div        := lc_init ;
        ln_position        := 0 ;
        lv_item_div        := lc_init ;
        lv_item_code       := lc_init ;
        lv_futai_code      := lc_init ;
        lv_locat_code      := lc_init ;
        lv_ship_to_date    := lc_init ;
        lv_request_no      := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：入庫日グループ
      -- ====================================================
      IF ( lr_ref.ship_in_date <> lv_ship_in_date ) THEN
        -- ----------------------------------------------------
        -- 下層グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_ship_in_date <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 入庫日グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_ship' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 入庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_in_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.ship_in_date ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（商品区分）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_ship_in_date := lr_ref.ship_in_date ;
        lv_prod_div     := lc_init ;
        ln_position     := 0 ;
        lv_item_div     := lc_init ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：商品区分グループ
      -- ====================================================
      IF ( lr_ref.prod_div <> lv_prod_div ) THEN
        -- ----------------------------------------------------
        -- 下層グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_prod_div <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 商品区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        ln_position := ln_position + 1 ;
        -- ポジション
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'position' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ln_position ;
        -- 商品区分ード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.prod_div ;
        -- 商品区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.prod_div_name ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（品目区分）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_prod_div     := lr_ref.prod_div ;
        lv_item_div     := lc_init ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：品目区分グループ
      -- ====================================================
      IF ( lr_ref.item_div <> lv_item_div ) THEN
        -- ----------------------------------------------------
        -- 下層グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_item_div <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目区分グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 品目区分ード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_div ;
        -- 品目区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_div_name ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（品目）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_item_div     := lr_ref.item_div ;
        lv_item_code    := lc_init ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：品目グループ
      -- ====================================================
      IF ( lr_ref.item_code <> lv_item_code ) THEN
        -- ----------------------------------------------------
        -- 下層グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_item_code <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細リストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 品目グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_code ;
        -- 品目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.item_name ;
        -- 単位
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'uom_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.uom_code ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（受注明細）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_item_code    := lr_ref.item_code ;
        lv_futai_code   := lc_init ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：受注明細グループ
      -- ====================================================
      IF ( lr_ref.futai_code <> lv_futai_code ) THEN
        -- ----------------------------------------------------
        -- グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_futai_code <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注ヘッダリストグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- 受注明細グループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 付帯
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.futai_code ;
--
        -- ----------------------------------------------------
        -- リストグループ開始タグ（受注ヘッダ）
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_futai_code   := lr_ref.futai_code ;
        lv_locat_code   := lc_init ;
        lv_ship_to_date := lc_init ;
        lv_request_no   := lc_init ;
--
      END IF ;
--
      -- ====================================================
      -- ブレイク判定：受注ヘッダグループ
      -- ====================================================
      IF (   ( lr_ref.locat_code   <> lv_locat_code   )
          OR ( lr_ref.ship_to_date <> lv_ship_to_date )
          OR ( lr_ref.request_no   <> lv_request_no   ) ) THEN
        -- ----------------------------------------------------
        -- グループ終了タグ出力
        -- ----------------------------------------------------
        IF ( lv_locat_code <> lc_init ) THEN
--
          -- 受注ヘッダグループ
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- 出庫倉庫コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.locat_code ;
        -- 出庫倉庫名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.locat_name ;
        -- 出庫日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_to_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.ship_to_date ;
        -- 依頼Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'request_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.request_no ;
        -- 発注Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.order_no ;
        -- 明細摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.description ;
--
        -- ----------------------------------------------------
        -- ブレイク判断用項目の退避
        -- ----------------------------------------------------
        lv_locat_code   := lr_ref.locat_code ;
        lv_ship_to_date := lr_ref.ship_to_date ;
        lv_request_no   := lr_ref.request_no ;
--
      END IF ;
--
      -- ====================================================
      -- ロットグループ
      -- ====================================================
      -- ----------------------------------------------------
      -- リストグループ開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- 依頼帳票orロット管理対象外の場合
      -- ----------------------------------------------------
      IF (  ( gr_param.use_purpose = gc_use_purpose_irai )
         OR ( lr_ref.lot_ctl       = gc_lot_ctl_n        ) ) THEN
--
        -- ----------------------------------------------------
        -- グループ開始タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- ロット番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- 製造年月日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- 賞味期限
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- 固有記号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := NULL ;
        -- 入数
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.frequent_qty ;
        -- 数量
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.quantity ;
--
        -- ----------------------------------------------------
        -- グループ終了タグ出力
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- 指示帳票orロット管理対象の場合
      -- ----------------------------------------------------
      ELSE
--
        -- ====================================================
        -- カーソルオープン
        -- ====================================================
        -- 対象品目が「製品」の場合
        IF ( lr_ref.item_div = gc_item_div_sei ) THEN
          -- 製品用に並び変えて抽出
          OPEN lc_ref_lot FOR lc_sql_lot || lc_sql_order_by_1
          USING lr_ref.order_line_id
               ,lr_ref.item_id
          ;
        -- 対象品目が「製品」以外の場合
        ELSE
          -- 製品以外用に並び変えて抽出
          OPEN lc_ref_lot FOR lc_sql_lot || lc_sql_order_by_2
          USING lr_ref.order_line_id
               ,lr_ref.item_id
          ;
        END IF ;
--
        <<lot_data_loop>>
        LOOP
--
          FETCH lc_ref_lot INTO lr_ref_lot ;
          EXIT WHEN lc_ref_lot%NOTFOUND ;
--
          -- ----------------------------------------------------
          -- グループ開始タグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- ----------------------------------------------------
          -- データタグ出力
          -- ----------------------------------------------------
          -- ロット番号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.lot_no ;
          -- 製造年月日
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.product_date ;
          -- 賞味期限
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.use_by_date ;
          -- 固有記号
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.original_char ;
          -- 入数
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.frequent_qty ;
          -- 数量
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lr_ref_lot.quantity ;
--
          -- ----------------------------------------------------
          -- グループ終了タグ出力
          -- ----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP lot_data_loop ;
--
      END IF ;
--
      -- ----------------------------------------------------
      -- リストグループ開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ----------------------------------------------------
    -- グループ終了タグ
    -- ----------------------------------------------------
    -- 受注ヘッダグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 受注ヘッダリストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 受注明細グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 受注明細リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目区分グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 品目区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 商品区分グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 商品区分リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 入庫日グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 入庫日リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_ship' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 配送先グループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- 配送先リストグループ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
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
      iv_use_purpose        IN     VARCHAR2         -- 01 : 使用目的
     ,iv_locat_code         IN     VARCHAR2         -- 02 : 出庫倉庫
     ,iv_date_from          IN     VARCHAR2         -- 03 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 04 : 出庫日To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 06 : 品目区分
     ,iv_item_code          IN     VARCHAR2         -- 07 : 品目
     ,iv_deliver_to_code    IN     VARCHAR2         -- 08 : 配送先
     ,iv_security_div       IN     VARCHAR2         -- 09 : 有償セキュリティ区分
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
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              NUMBER ;
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
    gr_param.use_purpose      := iv_use_purpose ;                     -- 01 : 使用目的
    gr_param.deliver_to_code  := iv_deliver_to_code ;                 -- 02 : 配送先
    gr_param.date_from        := SUBSTR( iv_date_from, 1, 10 ) ;      -- 03 : 出庫日From
    gr_param.date_to          := SUBSTR( iv_date_to  , 1, 10 ) ;      -- 04 : 出庫日To
    gr_param.prod_div         := iv_prod_div ;                        -- 05 : 商品区分
    gr_param.item_div         := iv_item_div ;                        -- 06 : 品目区分
    gr_param.item_code        := iv_item_code ;                       -- 07 : 品目
    gr_param.locat_code       := iv_locat_code ;                      -- 08 : 出庫倉庫
    gr_param.security_div     := iv_security_div ;                    -- 09 : 有償セキュリティ区分
--
    IF gr_param.date_to IS NULL THEN
      gr_param.date_to := gc_max_date_char ;
    END IF ;
--
    -- -----------------------------------------------------
    -- 帳票タイトル設定
    -- -----------------------------------------------------
    -- 依頼の場合
    IF ( gr_param.use_purpose = gc_use_purpose_irai ) THEN
      gv_report_name := gc_report_name_irai ;
    ELSE
      gv_report_name := gc_report_name_shij ;
    END IF ;
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
    -- 帳票タイトル
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_name ;
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <report_name>' || gv_report_name || '</report_name>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <lg_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <g_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <position>1</position>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <lg_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </lg_item_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </g_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </g_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </lg_ship>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </g_deliver>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </lg_deliver>' ) ;
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
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : 使用目的
     ,iv_deliver_to_code    IN     VARCHAR2         -- 02 : 配送先
     ,iv_date_from          IN     VARCHAR2         -- 03 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 04 : 出庫日To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 06 : 品目区分
     ,iv_item_code          IN     VARCHAR2         -- 07 : 品目
     ,iv_locat_code         IN     VARCHAR2         -- 08 : 出庫倉庫
     ,iv_security_div       IN     VARCHAR2         -- 09 : 有償セキュリティ区分
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
        iv_use_purpose        => iv_use_purpose       -- 01 : 使用目的
       ,iv_deliver_to_code    => iv_deliver_to_code   -- 02 : 配送先
       ,iv_date_from          => iv_date_from         -- 03 : 出庫日From
       ,iv_date_to            => iv_date_to           -- 04 : 出庫日To
       ,iv_prod_div           => iv_prod_div          -- 05 : 商品区分
       ,iv_item_div           => iv_item_div          -- 06 : 品目区分
       ,iv_item_code          => iv_item_code         -- 07 : 品目
       ,iv_locat_code         => iv_locat_code        -- 08 : 出庫倉庫
       ,iv_security_div       => iv_security_div      -- 09 : 有償セキュリティ区分
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
END xxpo440003c ;
/
