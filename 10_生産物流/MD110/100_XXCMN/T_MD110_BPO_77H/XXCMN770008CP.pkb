CREATE OR REPLACE PACKAGE BODY xxcmn770008cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770008cp(body)
 * Description      : 返品原料原価差異表(プロト)
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77H)
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_get_report_data       PROCEDURE : 明細データ取得(H-1)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(H-2)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   T.Ikehara        新規作成
 *  2008/05/15    1.1   T.Ikehara        処理年月パラYYYYM入力対応
 *                                       担当部署、担当者名の最大長処理を修正
 *  2008/06/03    1.2   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/10    1.3   T.Ikehara        投入品と製品のラインタイプを修正
 *  2008/06/13    1.4   T.Ikehara        生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/19    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/26    1.7   A.Shiina         T_TE080_BPO_770 指摘17対応
 *  2008/10/15    1.8   N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/11    1.9   N.Yoshida        移行データ検証時不具合対応
 *  2009/02/13    1.10  A.Shiina         本番#1190対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal          CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn            CONSTANT VARCHAR2(1)  := '1';
  gv_status_error           CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
  gv_haifn                  CONSTANT VARCHAR2(1)  := '-';
  gv_ja                     CONSTANT VARCHAR2(2)  := 'JA';
  gn_po_qty                 CONSTANT NUMBER  := 1;
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
  -- ユーザー定義例外
  -- ===============================
  global_user_expt          EXCEPTION;     -- ユーザーにて定義をした例外
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770008CP';   -- パッケージ名
  gv_print_name           CONSTANT VARCHAR2(20) := '返品原料原価差異表' ;   -- 帳票名
--
  ------------------------------
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN'; -- アプリケーション
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_ym_format       CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  gc_char_ym_jp_format    CONSTANT VARCHAR2(30) := 'YYYY"年"MM"月"';
  gc_d                    CONSTANT VARCHAR2(1) := 'D';
  gc_n                    CONSTANT VARCHAR2(1) := 'N';
  gc_t                    CONSTANT VARCHAR2(1) := 'T';
  gc_z                    CONSTANT VARCHAR2(1) := 'Z';
  gn_one                  CONSTANT NUMBER      := 1  ;
  gc_sla                  CONSTANT VARCHAR2(1) := '/' ;
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(10)                          -- 01 : 処理年月（必須)
     ,goods_class         VARCHAR2(10)                          -- 02 : 商品区分（必須)
     ,item_class          VARCHAR2(10)                          -- 03 : 品目区分（必須)
     ,rcv_pay_div         VARCHAR2(10)                          -- 04 : 受払区分（任意)
    );
--
  -- 受払残高表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
      item_code          xxcmn_lot_each_item_v.item_code%TYPE              -- 返品原料品目コード
     ,item_name          xxcmn_lot_each_item_v.item_short_name%TYPE        -- 返品原料品目名称
     ,product_item_code  xxcmn_lot_each_item_v.item_code%TYPE              -- 製品品目コード
     ,product_item_name  xxcmn_lot_each_item_v.item_short_name%TYPE        -- 製品品目名称
     ,quantity           ic_tran_pnd.trans_qty%TYPE                        -- 受入数量(原料)
-- 2008/11/11 v1.9 UPDATE START
     --,standard_cost      xxcmn_stnd_unit_price_v.stnd_unit_price_gen%TYPE  -- 標準原価(原料)
     ,standard_cost      xxcmn_stnd_unit_price_v.stnd_unit_price%TYPE  -- 標準原価(原料)
-- 2008/11/11 v1.9 UPDATE END
     ,turn_qty           ic_tran_pnd.trans_qty%TYPE                        -- 基準数量(製品)
     ,turn_price         NUMBER                                            -- 基準単価(製品)
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- 製品・原料の複数存在チェック用
  TYPE rec_double_check IS RECORD(
      batch_no           gme_batch_header.batch_no%TYPE  -- バッチＮｏ
     ,cnt                NUMBER                          -- 件数カウント
    );
  TYPE tab_double_check IS TABLE OF rec_double_check INDEX BY BINARY_INTEGER ;
--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  gd_exec_start             DATE;             -- 処理年月の開始日
  gd_exec_end               DATE;             -- 処理年月の終了日
  gv_exec_start             VARCHAR2(20);     -- 処理年月の開始日
  gv_exec_end               VARCHAR2(20);     -- 処理年月の終了日
  ------------------------------
  -- ヘッダ情報取得用
  ------------------------------
-- 帳票種別
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;   -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;        -- 担当者
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12);   -- 帳票ID
  gd_exec_date              DATE;           -- 実施日
--
  gt_body_data              tab_data_type_dtl;       -- 取得レコード表
  gt_check_data             tab_double_check;        -- レコードチェック用
  gt_xml_data_table         XML_DATA;                -- ＸＭＬデータタグ表
--
--
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--###########################  固定部 END   ############################
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_convert_data         VARCHAR2(2000);
--
  BEGIN
--
    --データの場合
    IF (ic_type = gc_d) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END fnc_conv_xml;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(H-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data            -- 01.入力パラメータ群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
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
    cv_process_year   CONSTANT VARCHAR2(8)  := '処理年月';
    lc_f_day          CONSTANT VARCHAR2(3)  := '/01';
    lc_f_time         CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time         CONSTANT VARCHAR2(10) := ' 23:59:59';
-- 2008/10/15 v1.8 ADD START
    cn_prod_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id  CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
-- 2008/10/15 v1.8 ADD END
--
    lc_prod           CONSTANT VARCHAR2(5)  := 'PROD';    -- 生産関連
    lc_completed      CONSTANT NUMBER       := 1;         -- 完了フラグ：完了
    lc_material       CONSTANT NUMBER       := -1;        -- 原料
    lc_product        CONSTANT NUMBER       := 1;         -- 製品
--
    -- *** ローカル・変数 ***
-- 2008/10/15 v1.8 UPDATE START
    lv_select         VARCHAR2(10000);   -- 共通SELECT
    --lv_from1          VARCHAR2(1000);   -- 共通FROM
    --lv_order_by       VARCHAR2(100);    -- 共通ORDER BY
    --lv_sql1           VARCHAR2(10000);  -- データ取得用ＳＱＬ（REVERSE_IDがNULL用）
    lv_select_chk     VARCHAR2(10000);    -- エラーチェック用SELECT
    --lv_group_by_chk   VARCHAR2(100);    -- エラーチェック用GROUP BY
    lv_where1         VARCHAR2(1000);   -- 共通WHERE
    lv_order          VARCHAR2(1000);    -- 共通ORDER BY
    lv_group          VARCHAR2(1000);    -- 共通ORDER BY
-- 2008/10/15 v1.8 UPDATE END
--
    lv_err_batch_no   VARCHAR2(3200) DEFAULT NULL;  -- バッチのエラーＮｏ
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR;
    lc_ref ref_cursor;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- ----------------------------------------------------
    -- 日付情報取得
    -- ----------------------------------------------------
    -- 処理年月・開始日
    gd_exec_start := FND_DATE.STRING_TO_DATE(SUBSTR(ir_param.exec_year_month,1,4)
      || gc_sla || SUBSTR(ir_param.exec_year_month,5) || lc_f_day, gc_char_format);
    -- エラー処理
    IF ( gd_exec_start IS NULL ) THEN
      lv_errbuf := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_process_year
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_year_month ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
--
    -- 処理年月・終了日
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
--
--
-- 2008/10/15 v1.8 ADD START
    -- ----------------------------------------------------
    -- ＳＱＬ生成（エラーチェック用）
    -- ----------------------------------------------------
    lv_select_chk :=
       '      SELECT /*+ leading ( itp1 gic1 mcb1 gic2 mcb2 gmd1 gbh1 grb1 ) */ '
    || '             gbh1.batch_no        batch_no ' -- バッチＮｏ
    || '            ,count(gbh1.batch_no) cnt'       -- 同バッチＩＤの件数
    || '      FROM'
    || '             ic_tran_pnd               itp1'  -- 保留在庫トランザクション(原料用)
    || '            ,gmi_item_categories       gic1'
    || '            ,mtl_categories_b          mcb1'
    || '            ,gmi_item_categories       gic2'
    || '            ,mtl_categories_b          mcb2'
    || '            ,gme_material_details      gmd1'
    || '            ,gme_batch_header          gbh1'
    || '            ,gmd_routings_b            grb1'
    || '            ,xxcmn_rcv_pay_mst         xrpm1' -- 受払マスタ
    || '            ,gme_material_details      gmd2'
    || '            ,gme_batch_header          gbh2'
    || '            ,gmd_routings_b            grb2'
    || '            ,xxcmn_rcv_pay_mst         xrpm2' -- 受払マスタ
    || '            ,ic_tran_pnd               itp2'  -- 保留在庫トランザクション(製品用)
    || '      WHERE  itp1.doc_type         = ''' || lc_prod || ''''
    || '      AND    itp1.completed_ind   = ''' || lc_completed || ''''    -- 完了
    || '      AND    itp1.trans_date      >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.trans_date      <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end  || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.line_type       = ''' || lc_product || ''''
    || '      AND    itp1.reverse_id      IS NULL'
    || '      AND    gic1.item_id         = itp1.item_id'
    || '      AND    gic1.category_set_id = ''' || cn_prod_class_id || ''''
    || '      AND    mcb1.category_id     = gic1.category_id'
    || '      AND    mcb1.segment1        = ''' || ir_param.goods_class || ''''
    || '      AND    gic2.item_id         = itp1.item_id'
    || '      AND    gic2.category_set_id = ''' || cn_item_class_id || ''''
    || '      AND    mcb2.category_id     = gic2.category_id'
    || '      AND    mcb2.segment1        = ''' || ir_param.item_class || ''''
    || '      AND    gmd1.batch_id        = itp1.doc_id'
    || '      AND    gmd1.line_no         = itp1.doc_line'
    || '      AND    gbh1.batch_id        = gmd1.batch_id'
    || '      AND    grb1.routing_id      = gbh1.routing_id'
    || '      AND    xrpm1.doc_type       = itp1.doc_type'
    || '      AND    xrpm1.line_type      = itp1.line_type'
    || '      AND    xrpm1.routing_class  = grb1.routing_class'
    || '      AND    xrpm1.line_type      = gmd1.line_type'
    || '      AND    xrpm1.break_col_08 IS NOT NULL'
    || '      AND    (((gmd1.attribute5 IS NULL) AND (xrpm1.hit_in_div IS NULL))'
    || '             OR (xrpm1.hit_in_div = gmd1.attribute5))'
    || '      AND    ((xrpm1.routing_class <> ''70'')'
    || '             OR (xrpm1.routing_class = ''70'''
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd3'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd3.batch_id   = gmd1.batch_id'
    || '                              AND    gmd3.line_no    = gmd1.line_no'
    || '                              AND    gmd3.line_type  = -1'
    || '                              AND    gic.item_id     = gmd3.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm1.item_div_origin))'
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd4'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd4.batch_id   = gmd1.batch_id'
    || '                              AND    gmd4.line_no    = gmd1.line_no'
    || '                              AND    gmd4.line_type  = 1'
    || '                              AND    gic.item_id     = gmd4.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm1.item_div_ahead)))'
    || '             )'
    || '      AND    gmd2.batch_id        = itp2.doc_id'
    || '      AND    gmd2.line_no         = itp2.doc_line'
    || '      AND    gbh2.batch_id        = gmd2.batch_id'
    || '      AND    grb2.routing_id      = gbh2.routing_id'
    || '      AND    xrpm2.doc_type       = itp2.doc_type'
    || '      AND    xrpm2.line_type      = itp2.line_type'
    || '      AND    xrpm2.routing_class  = grb2.routing_class'
    || '      AND    xrpm2.line_type      = gmd2.line_type'
    || '      AND    xrpm2.break_col_08 IS NOT NULL'
    || '      AND    (((gmd2.attribute5 IS NULL) AND (xrpm2.hit_in_div IS NULL))'
    || '             OR (xrpm2.hit_in_div = gmd2.attribute5))'
    || '      AND    ((xrpm2.routing_class <> ''70'')'
    || '             OR (xrpm2.routing_class = ''70'''
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd5'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd5.batch_id   = gmd2.batch_id'
    || '                              AND    gmd5.line_no    = gmd2.line_no'
    || '                              AND    gmd5.line_type  = -1'
    || '                              AND    gic.item_id     = gmd2.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm2.item_div_origin))'
    || '                 AND (EXISTS (SELECT 1'
    || '                              FROM   gme_material_details gmd6'
    || '                                    ,gmi_item_categories  gic'
    || '                                    ,mtl_categories_b     mcb'
    || '                              WHERE  gmd6.batch_id   = gmd2.batch_id'
    || '                              AND    gmd6.line_no    = gmd2.line_no'
    || '                              AND    gmd6.line_type  = 1'
    || '                              AND    gic.item_id     = gmd6.item_id'
    || '                              AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                              AND    gic.category_id = mcb.category_id'
    || '                              AND    mcb.segment1    = xrpm2.item_div_ahead)))'
    || '             )'
    || '      AND    itp1.doc_id          = itp2.doc_id'
    || '      AND    itp2.doc_type        = ''' || lc_prod || ''''
    || '      AND    itp2.completed_ind   = ''' || lc_completed || ''''  -- 完了
    || '      AND    itp2.line_type       = ''' || lc_material || ''''   -- 製品
    || '      AND    itp2.reverse_id      IS NULL';
--
    -- ----------------------------------------------------
    -- ＳＱＬ生成
    -- ----------------------------------------------------
    lv_select :=
       '      SELECT /*+ leading ( itp1 gic1 mcb1 gic2 mcb2 gmd1 gbh1 grb1 ) */'
    || '             iimb1.item_no                           item_code'           -- 返品原料品目コード
    || '            ,ximb1.item_short_name                   item_name'           -- 返品原料品目名称
    || '            ,iimb2.item_no                           product_item_code'   -- 製品品目コード
    || '            ,ximb2.item_short_name                   product_item_name'   -- 製品品目名称
    || '            ,itp1.trans_qty * TO_NUMBER(xrpm1.rcv_pay_div) quantity'      -- 受入数量
-- 2008/11/11 v1.9 UPDATE START
--    || '            ,xsupv1.stnd_unit_price_gen               standard_cost'      -- 標準原価
    || '            ,xsupv1.stnd_unit_price                  standard_cost'      -- 標準原価
-- 2008/11/11 v1.9 UPDATE END
    || '            ,itp2.trans_qty * TO_NUMBER(xrpm1.rcv_pay_div) turn_qty'           -- 基準数量
    || '            ,TO_NUMBER(NVL('
    || '               (SELECT fmd2.attribute5'
    || '                FROM   fm_matl_dtl               fmd2'     -- フォーミュラディテール
-- 2009/02/13 v1.10 UPDATE START
/*
    || '                WHERE  fmd2.formula_id = gbh2.formula_id'  -- 外部結合を解除
    || '                AND    fmd2.line_type  = xrpm2.line_type'  -- 外部結合を解除
    || '                AND    fmd2.line_no    = gmd2.line_no'     -- 外部結合を解除
*/
    || '                WHERE  fmd2.formula_id = gbh1.formula_id'  -- 外部結合を解除
    || '                AND    fmd2.line_type  = xrpm1.line_type'  -- 外部結合を解除
    || '                AND    fmd2.line_no    = gmd1.line_no'     -- 外部結合を解除
-- 2009/02/13 v1.10 UPDATE END
    || '               )'
    || '             ,0))       turn_price'         -- 基準単価
    || '      FROM   ic_tran_pnd              itp1'    -- 保留在庫トランザクション(原料用)
    || '            ,gmi_item_categories      gic1'
    || '            ,mtl_categories_b         mcb1'
    || '            ,gmi_item_categories      gic2'
    || '            ,mtl_categories_b         mcb2'
    || '            ,ic_item_mst_b            iimb1'
    || '            ,xxcmn_item_mst_b         ximb1'
    || '            ,gme_material_details     gmd1'
    || '            ,gme_batch_header         gbh1'
    || '            ,gmd_routings_b           grb1'
    || '            ,gme_material_details     gmd2'
    || '            ,gme_batch_header         gbh2'
    || '            ,gmd_routings_b           grb2'
    || '            ,ic_tran_pnd              itp2'    -- 保留在庫トランザクション(製品用)
    || '            ,ic_item_mst_b            iimb2'
    || '            ,xxcmn_item_mst_b         ximb2'
    || '            ,xxcmn_rcv_pay_mst        xrpm1'  -- 受払マスタ
    || '            ,xxcmn_rcv_pay_mst        xrpm2'  -- 受払マスタ
--    || '            ,xxcmn_lookup_values_v    xlvv1'
    || '            ,xxcmn_stnd_unit_price_v  xsupv1'  -- 標準原価情報VIEW
    || '      WHERE  itp1.doc_type           =  ''' || lc_prod || ''''
    || '      AND    itp1.completed_ind      =  ''' || lc_completed || ''''    -- 完了
    || '      AND    itp1.trans_date         >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',''' || gc_char_dt_format || ''')'
    || '      AND    itp1.trans_date         <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''|| gc_char_dt_format || ''')'
    || '      AND    itp1.line_type          =  ''' || lc_product || ''''
    || '      AND    itp1.reverse_id         IS NULL'
    || '      AND    gic1.item_id            = itp1.item_id'
    || '      AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '      AND    mcb1.category_id        = gic1.category_id'
    || '      AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''    -- リーフ
    || '      AND    gic2.item_id            = itp1.item_id'
    || '      AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '      AND    mcb2.category_id        = gic2.category_id'
    || '      AND    mcb2.segment1           = ''' || ir_param.item_class || ''''     -- 原料
    || '      AND    itp1.doc_id             = gmd1.batch_id'
    || '      AND    itp1.doc_line           = gmd1.line_no'
    || '      AND    gbh1.batch_id           = gmd1.batch_id'
    || '      AND    grb1.routing_id         = gbh1.routing_id'
 /**/
    || '      AND    itp2.doc_id             = gmd2.batch_id'
    || '      AND    itp2.doc_line           = gmd2.line_no'
    || '      AND    gbh2.batch_id           = gmd2.batch_id'
    || '      AND    grb2.routing_id         = gbh2.routing_id'
 /**/
    || '      AND    iimb1.item_id           = itp1.item_id'
    || '      AND    ximb1.item_id           = iimb1.item_id'
    || '      AND    ximb1.start_date_active <= TRUNC(itp1.trans_date)'
    || '      AND    ximb1.end_date_active   >= TRUNC(itp1.trans_date)'
    || '      AND    itp1.item_id            = xsupv1.item_id'
    || '      AND    xsupv1.start_date_active <= TRUNC(itp1.trans_date)'
    || '      AND    xsupv1.end_date_active   >= TRUNC(itp1.trans_date)'
    || '      AND    itp1.doc_type           = xrpm1.doc_type'
    || '      AND    itp1.line_type          = xrpm1.line_type'
    || '      AND    xrpm1.routing_class     = grb1.routing_class'
    || '      AND    xrpm1.line_type         = gmd1.line_type'
    || '      AND    xrpm1.break_col_08 IS NOT NULL'
    || '      AND    (((gmd1.attribute5 IS NULL) AND (xrpm1.hit_in_div IS NULL))'
    || '             OR ( xrpm1.hit_in_div = gmd1.attribute5))'
    || '      AND    ((xrpm1.routing_class <> ''70'')'
    || '             OR (xrpm1.routing_class = ''70'''
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd3'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd3.batch_id   = gmd1.batch_id'
    || '                            AND    gmd3.line_no    = gmd1.line_no'
    || '                            AND    gmd3.line_type  = -1'
    || '                            AND    gic.item_id     = gmd3.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm1.item_div_origin))'
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd4'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd4.batch_id   = gmd1.batch_id'
    || '                            AND    gmd4.line_no    = gmd1.line_no'
    || '                            AND    gmd4.line_type  = 1'
    || '                            AND    gic.item_id     = gmd4.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm1.item_div_ahead))))'
/**/
    || '      AND    itp2.doc_type           = xrpm2.doc_type'
    || '      AND    itp2.line_type          = xrpm2.line_type'
    || '      AND    xrpm2.routing_class     = grb2.routing_class'
    || '      AND    xrpm2.line_type         = gmd2.line_type'
    || '      AND    xrpm2.break_col_08 IS NOT NULL'
    || '      AND    (((gmd2.attribute5 IS NULL) AND (xrpm2.hit_in_div IS NULL))'
    || '             OR ( xrpm2.hit_in_div = gmd2.attribute5))'
    || '      AND    ((xrpm2.routing_class <> ''70'')'
    || '             OR (xrpm2.routing_class = ''70'''
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd5'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd5.batch_id   = gmd2.batch_id'
    || '                            AND    gmd5.line_no    = gmd2.line_no'
    || '                            AND    gmd5.line_type  = -1'
    || '                            AND    gic.item_id     = gmd5.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm2.item_div_origin))'
    || '               AND (EXISTS (SELECT 1'
    || '                            FROM   gme_material_details gmd6'
    || '                                  ,gmi_item_categories  gic'
    || '                                  ,mtl_categories_b     mcb'
    || '                            WHERE  gmd6.batch_id   = gmd2.batch_id'
    || '                            AND    gmd6.line_no    = gmd2.line_no'
    || '                            AND    gmd6.line_type  = 1'
    || '                            AND    gic.item_id     = gmd6.item_id'
    || '                            AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                            AND    gic.category_id = mcb.category_id'
    || '                            AND    mcb.segment1    = xrpm2.item_div_ahead))))'
/**/
--    || '      AND    xlvv1.lookup_type       = ''XXCMN_DEALINGS_DIV'''
--    || '      AND    xrpm1.dealings_div      = xlvv1.lookup_code'
    || '      AND    itp1.doc_id             = itp2.doc_id'
    || '      AND    itp2.doc_type           = ''' || lc_prod || ''''
    || '      AND    itp2.completed_ind      = ''' || lc_completed || ''''        -- 完了
    || '      AND    itp2.line_type          = ''' || lc_material || ''''         -- 製品
    || '      AND    itp2.reverse_id         IS NULL'
    || '      AND    iimb2.item_id           = itp2.item_id'
    || '      AND    ximb2.item_id           = iimb2.item_id'
    || '      AND    ximb2.start_date_active <= TRUNC(itp2.trans_date)'
    || '      AND    ximb2.end_date_active   >= TRUNC(itp2.trans_date)';
--
    lv_order  := ' ORDER BY item_code, product_item_code';
    lv_group  := ' GROUP BY gbh1.batch_no';
    lv_where1 := ' AND xrpm1.dealings_div  = ''' || ir_param.rcv_pay_div || '''';
--
-- 2008/10/15 v1.8 ADD END
-- 2008/10/15 v1.8 DELETE START
    -- 共通SELECT
/*    lv_select :=
          ' SELECT'
      ||  ' xleiv1.item_code                        item_code'          -- 返品原料品目コード
      ||  ',xleiv1.item_short_name                  item_name'          -- 返品原料品目名称
      ||  ',xleiv2.item_code                        product_item_code'  -- 製品品目コード
      ||  ',xleiv2.item_short_name                  product_item_name'  -- 製品品目名称
-- 2008/08/26 v1.7 UPDATE START
--      ||  ',itp1.trans_qty * (-1)                   quantity'           -- 受入数量
      ||  ',itp1.trans_qty * TO_NUMBER(xrpmpv1.rcv_pay_div) quantity'   -- 受入数量
-- 2008/08/26 v1.7 UPDATE END
      ||  ',xsupv.stnd_unit_price_gen               standard_cost'      -- 標準原価
      ||  ',itp2.trans_qty                          turn_qty'           -- 基準数量
      ||  ',TO_NUMBER(NVL(fmd.attribute5, ''0''))   turn_price'         -- 基準単価
      ;
--
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    -- 共通FROM
    lv_from1 :=
          ' FROM'
      ||  ' ic_tran_pnd               itp1'     -- 保留在庫トランザクション(原料用)
      ||  ',ic_tran_pnd               itp2'     -- 保留在庫トランザクション(製品用)
      ||  ',xxcmn_rcv_pay_mst_prod_v  xrpmpv1'  -- 受払ビュー：生産関連(原料用)
      ||  ',xxcmn_rcv_pay_mst_prod_v  xrpmpv2'  -- 受払ビュー：生産関連(製品用)
      ||  ',xxcmn_lookup_values2_v    xlvv'     -- クイックコード情報VIEW2
      ||  ',xxcmn_lot_each_item_v     xleiv1'   -- ロット別品目情報VIEW(原料用)
      ||  ',xxcmn_lot_each_item_v     xleiv2'   -- ロット別品目情報VIEW(製品用)
      ||  ',xxcmn_stnd_unit_price_v   xsupv'    -- 標準原価情報VIEW
      ||  ',fm_matl_dtl               fmd'      -- フォーミュラディテール
      ;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    -- 共通WHERE
    lv_where1 :=
        ' WHERE itp1.doc_type         = ''' || lc_prod || ''' '
      ||  ' AND itp1.completed_ind    = ' || lc_completed     -- 完了
      ||  ' AND itp1.line_type        = ' || lc_product      -- 原料
      ||  ' AND itp1.trans_date       >= FND_DATE.STRING_TO_DATE('
      ||  '''' || gv_exec_start || ''', ''' || gc_char_dt_format || ''' )'
      ||  ' AND itp1.trans_date       <= FND_DATE.STRING_TO_DATE('
      ||  '''' || gv_exec_end   || ''', ''' || gc_char_dt_format || ''' )'
      ||  ' AND itp1.doc_type         = xrpmpv1.doc_type'
      ||  ' AND itp1.line_type        = xrpmpv1.line_type'
      ||  ' AND itp1.doc_id           = xrpmpv1.doc_id'
      ||  ' AND itp1.doc_line         = xrpmpv1.doc_line'
      ;
--
    -- パラメータ、受払区分が入力されているときに追加
    IF (ir_param.rcv_pay_div IS NOT NULL)THEN
      lv_where1 := lv_where1
        ||  ' AND xrpmpv1.dealings_div  = ''' || ir_param.rcv_pay_div || ''' '  -- 返品原料
        ;
    END IF;
--
    -- 共通WHERE続き
    lv_where1 := lv_where1
      ||  ' AND itp1.item_id          = xleiv1.item_id'
      ||  ' AND itp1.lot_id           = xleiv1.lot_id'
      ||  ' AND (  (xleiv1.start_date_active IS NULL)'
      ||  '     OR (xleiv1.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xleiv1.end_date_active   IS NULL)'
      ||  '     OR (xleiv1.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND xleiv1.item_div       = ''' || ir_param.goods_class || ''' ' -- リーフ
      ||  ' AND xleiv1.prod_div       = ''' || ir_param.item_class || ''' '  -- 原料
      ||  ' AND xlvv.lookup_type      = ''XXCMN_MONTH_TRANS_OUTPUT_FLAG'' '
      ||  ' AND xrpmpv1.dealings_div  = xlvv.meaning'
      ||  ' AND (  (xlvv.start_date_active IS NULL)'
      ||  '     OR (xlvv.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xlvv.end_date_active   IS NULL)'
      ||  '     OR (xlvv.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND xlvv.language         = ''' || gv_ja || ''' '
      ||  ' AND xlvv.source_lang      = ''' || gv_ja || ''' '
      ||  ' AND xlvv.attribute8       IS NOT NULL'
      ||  ' AND itp1.item_id          = xsupv.item_id'
      ||  ' AND (  (xsupv.start_date_active IS NULL)'
      ||  '     OR (xsupv.start_date_active <= TRUNC(itp1.trans_date)) )'
      ||  ' AND (  (xsupv.end_date_active   IS NULL)'
      ||  '     OR (xsupv.end_date_active   >= TRUNC(itp1.trans_date)) )'
      ||  ' AND itp1.doc_id           = itp2.doc_id'
      ||  ' AND itp2.doc_type         = ''' || lc_prod || ''' '
      ||  ' AND itp2.completed_ind    = ' || lc_completed     -- 完了
      ||  ' AND itp2.line_type        = ' || lc_material       -- 製品
      ||  ' AND itp2.item_id          = xleiv2.item_id'
      ||  ' AND itp2.lot_id           = xleiv2.lot_id'
      ||  ' AND itp2.reverse_id       IS NULL'
      ||  ' AND (  (xleiv2.start_date_active IS NULL)'
      ||  '     OR (xleiv2.start_date_active <= TRUNC(itp2.trans_date)) )'
      ||  ' AND (  (xleiv2.end_date_active   IS NULL)'
      ||  '     OR (xleiv2.end_date_active   >= TRUNC(itp2.trans_date)) )'
      ||  ' AND itp2.doc_type         = xrpmpv2.doc_type'
      ||  ' AND itp2.line_type        = xrpmpv2.line_type'
      ||  ' AND itp2.doc_id           = xrpmpv2.doc_id'
      ||  ' AND itp2.doc_line         = xrpmpv2.doc_line'
      ||  ' AND xrpmpv2.formula_id    = fmd.formula_id(+)'
      ||  ' AND xrpmpv2.line_type     = fmd.line_type(+)'
      ||  ' AND xrpmpv2.doc_line      = fmd.line_no(+)'
      ||  ' AND itp1.reverse_id       IS NULL'
      ;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ ＢＹ句生成
    -- ----------------------------------------------------
    -- 共通ORDER BY
    lv_order_by := ' ORDER BY'
                || ' item_code'
                || ',product_item_code'
                ;
--
    -- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成（エラーチェック用）
    -- ----------------------------------------------------
    lv_select_chk :=
          ' SELECT'
      ||  ' xrpmpv1.batch_no        batch_no' -- バッチＮｏ
      ||  ',count(xrpmpv1.batch_no) cnt'      -- 同バッチＩＤの件数
      ;
--
    -- ----------------------------------------------------
    -- ＧＲＯＵＰ ＢＹ句生成（エラーチェック用）
    -- ----------------------------------------------------
    lv_group_by_chk := ' GROUP BY xrpmpv1.batch_no';
--
    -- ----------------------------------------------------
    -- ＳＱＬ生成（エラーチェック用）
    -- ----------------------------------------------------
--
    lv_sql1 := lv_select_chk || lv_from1 || lv_where1 || lv_group_by_chk;*/
-- 2008/10/15 v1.8 DELETE END
--
    -- ----------------------------------------------------
    -- 製品・原料が複数存在する場合はエラー
    -- (製品と原料のどちらかが複数存在する場合は、同じバッチＩＤが複数ある)
    -- ----------------------------------------------------
--
-- 2008/10/15 v1.8 UPDATE START
    -- パラメータ、受払区分が入力されているときに追加
    IF (ir_param.rcv_pay_div IS NOT NULL) THEN
      lv_select_chk := lv_select_chk || lv_where1;
    END IF;
--
    -- GROUP BY句の追加
    lv_select_chk := lv_select_chk || lv_group;
--
    -- オープン
    --OPEN lc_ref FOR  lv_sql1;
    OPEN lc_ref FOR  lv_select_chk;
-- 2008/10/15 v1.8 UPDATE END
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO gt_check_data;
    -- カーソルクローズ
    CLOSE lc_ref;
--
    <<check_loop>>
    FOR i IN 1..gt_check_data.COUNT LOOP
      -- 製品・原料が複数存在する場合はエラー
      IF (gt_check_data(i).cnt > 1) THEN
        -- エラーの場合バッチＮｏを保持
        IF (lv_err_batch_no IS NULL) THEN
          lv_err_batch_no := gt_check_data(i).batch_no;
        ELSIF (gt_check_data(i).batch_no != gt_check_data(i -1).batch_no) THEN
          lv_err_batch_no := lv_err_batch_no || ' ,' || gt_check_data(i).batch_no;
        END IF;
      END IF;
--
    END LOOP check_loop;
--
    -- エラー処理
    IF ( lv_err_batch_no IS NOT NULL ) THEN
      lv_errbuf := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10156'
                                             ,'BATCH_NO'
                                             ,lv_err_batch_no ) ;
      ov_retcode  := gv_status_warn;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
--
--
    -- ----------------------------------------------------
    -- ＳＱＬ生成
    -- ----------------------------------------------------
-- 2008/10/15 v1.8 UPDATE START
    /*lv_sql1 := lv_select || lv_from1 || lv_where1;
    IF (lv_err_batch_no IS NOT NULL) THEN
        lv_sql1 := lv_sql1 ||  '  AND xrpmpv1.batch_no not in (' || lv_err_batch_no || ')';
    END IF;
    lv_sql1 := lv_sql1 || lv_order_by;*/
--
    -- パラメータ、受払区分が入力されているときに追加
    IF (ir_param.rcv_pay_div IS NOT NULL) THEN
      lv_select := lv_select || lv_where1;
    END IF;
--
    -- エラー時のバッチNoが存在する場合に追加
    IF (lv_err_batch_no IS NOT NULL) THEN
        lv_select := lv_select || '  AND xrpm1.batch_no not in (' || lv_err_batch_no || ')';
    END IF;
--
    -- ORDER BY句の追加
    lv_select := lv_select || lv_order;
--
    -- ----------------------------------------------------
    -- データ抽出
    -- ----------------------------------------------------
    -- オープン
    --OPEN lc_ref FOR  lv_sql1;
    OPEN lc_ref FOR  lv_select;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- カーソルクローズ
    CLOSE lc_ref;
-- 2008/10/15 v1.8 UPDATE END
--
--
  EXCEPTION

--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(H-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
     ,ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル定数 ***
    -- キーブレイク判断用
    lc_break_init           VARCHAR2(100) DEFAULT '*';            -- 初期値
    lc_break_null           VARCHAR2(100) DEFAULT '**';           -- ＮＵＬＬ判定
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_item_code            VARCHAR2(30) DEFAULT lc_break_init;   -- 品目コード
--
    -- 明細データ計算用
    ln_standard_amount      NUMBER;                               -- 標準金額(原料)
    ln_turn_amount          NUMBER;                               -- 基準金額(原料)
    ln_difference_price     NUMBER;                               -- 単価差異
    ln_differense_cost      NUMBER;                               -- 原価差異
--
    -- 処理年月用
    lv_ship_to_date         VARCHAR2(20);
    ld_ship_to_date         DATE;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION;             -- 取得レコードなし
--
    ---------------------
    -- XMLタグ挿入処理
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR     --   タグタイプ  T:タグ
                                                              -- D:データ
                                                              -- N:データ(NULLの場合タグを書かない)
                                                              -- Z:データ(NULLの場合0表示)
       ,iv_name              IN        VARCHAR2               --   タグ名
       ,iv_value             IN        VARCHAR2  DEFAULT NULL --   タグデータ(省略可
       ,in_lengthb           IN        NUMBER    DEFAULT NULL --   文字長（バイト）(省略可
       ,iv_index             IN        NUMBER    DEFAULT NULL --   インデックス(省略可
      )
    IS
      -- *** ローカル変数 ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULLの場合タグを書かない対応
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      --インデックス
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      lv_work := iv_value;
--
      --タグセット
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<タグ名>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<タグのみ>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<タグ ＆ データ>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(lv_work, 0) ; --Nullの場合０表示
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := lv_work ;         --Nullでもそのまま表示
        END IF;
      END IF;
--
      --文字切り
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,ot_data_rec   => gt_body_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- 取得データが０件の場合
    ELSIF ( gt_body_data.COUNT = 0 ) THEN
      RAISE no_data_expt;
--
    END IF;
--
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'user_info');
--
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
    -- 帳票ＩＤ
    prc_set_xml(gc_d, 'report_id', gv_report_id);
--
    -- 実施日
    prc_set_xml(gc_d, 'exec_date', TO_CHAR(gd_exec_date, gc_char_dt_format));
--
    -- 担当部署名
    prc_set_xml(gc_d, 'exec_user_dept', gv_user_dept, 10);
--
    -- 担当者名
    prc_set_xml(gc_d, 'exec_user_name', gv_user_name, 14);
--
    -- パラメータ・処理年月
    ld_ship_to_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month, gc_char_ym_format);
    lv_ship_to_date := TO_CHAR(ld_ship_to_date, gc_char_ym_jp_format);
    prc_set_xml(gc_d, 'ship_to_date', lv_ship_to_date);
--
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_set_xml(gc_t, '/user_info');
--
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'data_info');
--
    -- -----------------------------------------------------
    -- 品目LＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml(gc_t, 'lg_item');
--
    -- =====================================================
    -- 明細データ出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_body_data.COUNT LOOP
--
      -- =====================================================
      -- 原料品目コードブレイク
      -- =====================================================
      -- 原料品目コードが切り替わった場合
      IF ( NVL( gt_body_data(i).item_code, lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_code <> lc_break_init ) THEN
          ------------------------------
          -- 原料品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml(gc_t, '/lg_line');
--
          ------------------------------
          -- 原料品目コードＧ終了タグ
          ------------------------------
          prc_set_xml(gc_t, '/g_item');
--
        END IF ;
--
        ------------------------------
        -- 原料品目コードＧ開始タグ
        ------------------------------
        prc_set_xml(gc_t, 'g_item');
--
        -- -----------------------------------------------------
        -- 原料品目コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 原料品目コード
        prc_set_xml(gc_d, 'item_code', gt_body_data(i).item_code);
--
        -- 原料品目名称
        prc_set_xml(gc_d, 'item_name', gt_body_data(i).item_name, 20);
--
        ------------------------------
        -- 明細ラインＬＧ開始タグ
        ------------------------------
        prc_set_xml(gc_t, 'lg_line');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_code  := NVL( gt_body_data(i).item_code, lc_break_null );
--
      END IF;
--
      ------------------------------
      -- 明細ラインＬＧ開始タグ
      ------------------------------
      prc_set_xml(gc_t, 'g_line');
--
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 製品品目コード
      prc_set_xml(gc_d, 'product_item_code', gt_body_data(i).product_item_code);
--
      -- 製品品目名称
      prc_set_xml(gc_d, 'product_item_name', gt_body_data(i).product_item_name, 20);
--
      -- 受入数量(原料)
      prc_set_xml(gc_z, 'quantity', gt_body_data(i).quantity);
--
      -- 標準原価(原料)
      prc_set_xml(gc_z, 'standard_cost', gt_body_data(i).standard_cost);
--
      -- 標準金額(原料) ：受入数量(原料)×標準原価(原料)
-- 2008/11/11 v1.9 UPDATE START
      --ln_standard_amount  := gt_body_data(i).quantity * gt_body_data(i).standard_cost;
      ln_standard_amount  := ROUND(gt_body_data(i).quantity * gt_body_data(i).standard_cost);
-- 2008/11/11 v1.9 UPDATE END
      prc_set_xml(gc_z, 'standard_amount', ln_standard_amount);
--
      -- 基準単価(製品)
      prc_set_xml(gc_z, 'turn_price', gt_body_data(i).turn_price);
--
      -- 基準金額(原料)
-- 2008/11/11 v1.9 UPDATE START
      --ln_turn_amount  := gt_body_data(i).turn_price * gt_body_data(i).turn_qty;
      ln_turn_amount  := ROUND(gt_body_data(i).turn_price * gt_body_data(i).turn_qty);
-- 2008/11/11 v1.9 UPDATE END
      prc_set_xml(gc_z, 'turn_amount', ln_turn_amount);
--
      -- 単価差異
      ln_difference_price := gt_body_data(i).turn_price - gt_body_data(i).standard_cost;
      prc_set_xml(gc_z, 'difference_price', ln_difference_price);
--
      -- 原価差異
      ln_differense_cost  := ln_turn_amount - ln_standard_amount;
      prc_set_xml(gc_z, 'difference_cost', ln_differense_cost);
--
--
      ------------------------------
      -- 明細ラインＧ終了タグ
      ------------------------------
      prc_set_xml(gc_t, '/g_line');
--
    END LOOP main_data_loop;
--
    ------------------------------
    -- 明細ラインＬＧ終了タグ
    ------------------------------
    prc_set_xml(gc_t, '/lg_line');
--
    ------------------------------
    -- 品目Ｇ終了タグ
    ------------------------------
    prc_set_xml(gc_t, '/g_item');
--
    ------------------------------
    -- 品目ＬＧ終了タグ
    ------------------------------
    prc_set_xml(gc_t, '/lg_item');
--
    ------------------------------
    -- データＬＧ終了タグ
    ------------------------------
    prc_set_xml(gc_t, '/data_info');
--
--
    IF ( lv_retcode = gv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_date            IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class        IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class           IN     VARCHAR2    -- 03 : 品目区分
     ,iv_rcv_pay_div          IN     VARCHAR2    -- 04 : 受払区分
     ,ov_errbuf               OUT    VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              OUT    VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg               OUT    VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'submain'; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   エラー・メッセージ
    lv_retcode VARCHAR2(1);                      --   リターン・コード
    lv_errmsg  VARCHAR2(5000);                   --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec            rec_param_data;          -- パラメータ受渡し用
--
    lv_xml_string           VARCHAR2(32000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 初期処理
    -- =====================================================
    -- 帳票出力値格納
    gv_report_id  := 'XXCMN770008T';                              -- 帳票ID
    gd_exec_date  := SYSDATE;                                     -- 実施日
    gv_user_dept  := xxcmn_common_pkg.get_user_dept(gn_user_id);  -- 担当部署名
    gv_user_name  := xxcmn_common_pkg.get_user_name(gn_user_id);  -- 担当者名
--
    lr_param_rec.exec_year_month := iv_proc_date;           -- 01 : 処理年月（必須)
    lr_param_rec.goods_class     := iv_product_class;       -- 02 : 商品区分（必須)
    lr_param_rec.item_class      := iv_item_class;          -- 03 : 品目区分（必須)
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;         -- 04 : 受払区分（任意)
--
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' );
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>');
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ＸＭＬヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' );
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
                          );
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string );
      END LOOP xml_data_table;
--
      -- ＸＭＬフッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' );
--
    END IF;
--
    -- ==================================================
    -- 終了ステータス設定
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf              OUT    VARCHAR2    -- エラーメッセージ
     ,retcode             OUT    VARCHAR2    -- エラーコード
     ,iv_proc_date        IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class    IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class       IN     VARCHAR2    -- 03 : 品目区分
     ,iv_rcv_pay_div      IN     VARCHAR2    -- 04 : 受払区分
    )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ======================================================
    -- 固定ローカル定数
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   エラー・メッセージ
    lv_retcode              VARCHAR2(1);         --   リターン・コード
    lv_errmsg               VARCHAR2(5000);      --   ユーザー・エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 END   #############################
--
    -- ======================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ======================================================
    submain(
        iv_proc_date            => iv_proc_date           -- 01 : 処理年月
       ,iv_product_class        => iv_product_class       -- 02 : 商品区分
       ,iv_item_class           => iv_item_class          -- 03 : 品目区分
       ,iv_rcv_pay_div          => iv_rcv_pay_div         -- 04 : 受払区分
       ,ov_errbuf               => lv_errbuf              -- エラー・メッセージ
       ,ov_retcode              => lv_retcode             -- リターン・コード#
       ,ov_errmsg               => lv_errmsg);            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
--
    --ステータスセット
    retcode := lv_retcode;
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
END xxcmn770008cp;
/
