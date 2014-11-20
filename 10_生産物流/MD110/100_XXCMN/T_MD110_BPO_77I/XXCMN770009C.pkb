CREATE OR REPLACE PACKAGE BODY xxcmn770009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770009C(body)
 * Description      : 他勘定振替原価差異表
 * MD.050/070       : 月次〆切処理帳票Issue1.0(T_MD050_BPO_770)
 *                  : 月次〆切処理帳票Issue1.0(T_MD070_BPO_77I)
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml               FUNCTION  : ＸＭＬタグに変換する。
 *  prc_set_xml                FUNCTION  : ＸＭＬ用配列に格納する。
 *  prc_initialize             PROCEDURE : 前処理
 *  prc_get_report_data        PROCEDURE : 明細データ取得(I-1)
 *  prc_create_xml_data        PROCEDURE : ＸＭＬデータ作成(I-2)
 *  submain                    PROCEDURE : メイン処理プロシージャ
 *  main                       PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  DATE          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/19    1.0   M.Hamamoto       新規作成
 *  2008/05/16    1.1   M.Hamamoto       パラメータ：処理年月がYYYYMで入力されるとエラーになる
 *                                       点を修正。
 *                                       帳票に出力されているのは、パラメータの処理年月のみで
 *                                       入力パラメータに200804ではなく、20084とすると正常に抽出
 *                                       されるが、ヘッダの処理年月が帳票出力時に書式’YYYY/MM
 *                                       ’へ変換されるよう修正。
 *  2008/05/31    1.2   M.Hamamoto       原価取得方法を修正。
 *  2008/06/19    1.3   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 start   #######################
--
  gv_status_normal        CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn          CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error         CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part             CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont             CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ###############################
--
--#######################  固定グローバル変数宣言部 start   #######################
--
--################################  固定部 END   ###############################
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770009c' ;   -- パッケージ名
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code        CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag          CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_new_acnt_div         CONSTANT VARCHAR2(21)  := 'XXCMN_NEW_ACCOUNT_DIV';
--
  ------------------------------
  -- 全角文字
  ------------------------------
  gc_cat_prod_div         CONSTANT VARCHAR2(8)   := '商品区分' ;
  gc_cat_item_div         CONSTANT VARCHAR2(8)   := '品目区分' ;
  gc_cap_from             CONSTANT VARCHAR2(14)  := '処理年月(FROM)' ;
  gc_cap_to               CONSTANT VARCHAR2(12)  := '処理年月(TO)' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- アプリケーション（xxcmn）
  gc_param_name           CONSTANT VARCHAR2(10) := 'PARAM_NAME' ;
  gc_param_value          CONSTANT VARCHAR2(11) := 'PARAM_VALUE';
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '有償支給セキュリティview' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := 'ユーザーid' ;
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '年' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '月' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '日' ;
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_y                   CONSTANT VARCHAR2(1) := 'Y' ;
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  gn_one                 CONSTANT NUMBER        := 1   ;
  gn_two                 CONSTANT NUMBER        := 2   ;
  gn_one1                CONSTANT NUMBER        := '1' ;
  gc_gun                 CONSTANT VARCHAR2(1) := '3' ;
  gc_sla                 CONSTANT VARCHAR2(1) := '/' ;
  gc_sla_zero_one        CONSTANT VARCHAR2(3) := '/01' ;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data IS RECORD(
      proc_from            VARCHAR2(6)   -- 処理年月FROM
     ,proc_from_date_ch    VARCHAR2(10)  -- 処理年月FROM(日付文字列)
     ,proc_from_date       DATE          -- 処理年月FROM(日付) - 1(先月の末日)
     ,proc_to              VARCHAR2(6)   -- 処理年月to
     ,proc_to_date_ch      VARCHAR2(10)  -- 処理年月to(日付文字列)
     ,proc_to_date         DATE          -- 処理年月to(日付) - 1(翌月の1日)
     ,prod_div             VARCHAR2(10)  -- 商品区分
     ,item_div             VARCHAR2(10)  -- 品目区分
     ,rcv_pay_div          VARCHAR2(10)  -- 受払区分
     ,crowd_type           VARCHAR2(10)  -- 集計種別
     ,crowd_code           VARCHAR2(10)  -- 群コード
     ,acnt_crowd_code      VARCHAR2(10)  -- 経理群コード
    ) ;
--
    gr_param          rec_param_data ;          -- パラメータ受渡し用
--
  --ヘッダ用
  TYPE rec_header  IS RECORD(
      report_id           VARCHAR2(12)     -- 帳票id
     ,exec_date           DATE             -- 実施日
     ,proc_from_char      VARCHAR2(10)                                 --処理年月FROM(yyyy年mm月)
     ,proc_to_char        VARCHAR2(10)                                 --処理年月to  (yyyy年mm月)
     ,user_id             xxpo_per_all_people_f_v.person_id%TYPE       --担当者id
     ,user_name           per_all_people_f.per_information18%TYPE      --担当者
     ,user_dept           xxcmn_locations_all.location_short_name%TYPE --部署
    ) ;
--
  gr_header           rec_header;
--
  -- 仕入取引明細表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
     item_code_from xxcmn_lot_each_item_v.item_code%TYPE
    ,item_name_from xxcmn_lot_each_item_v.item_short_name%TYPE
    ,item_code_to xxcmn_rcv_pay_mst_porc_rma_v.request_item_code%TYPE
    ,item_name_to xxcmn_item_mst2_v.item_short_name%TYPE
    ,gun_code xxcmn_lot_each_item_v.crowd_code%TYPE
    ,rcv_pay_div xxcmn_rcv_pay_mst_porc_rma_v.rcv_pay_div%TYPE
    ,trans_qty   NUMBER
    ,from_price  NUMBER
    ,from_cost   NUMBER
    ,to_price    NUMBER
    ,to_cost     NUMBER
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  --キー割れ判断用
  TYPE rec_keybreak  IS RECORD(
       prod_div       VARCHAR2(200)  --商品区分
     , item_div       VARCHAR2(200)  --品目区分
     , rcv_pay_div    VARCHAR2(200)  --受払区分
     , crowd_high     VARCHAR2(200)  --大群
     , crowd_mid      VARCHAR2(200)  --中群
     , crowd_low      VARCHAR2(200)  --小群
     , crowd_dtl      VARCHAR2(200)  --詳群
     , item_from      VARCHAR2(200)  --振替元品目
     , item_to        VARCHAR2(200)  --振替先品目
    ) ;
--
  gr_rec tab_data_type_dtl;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ｓｑｌ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;  -- 営業単位
--
  ------------------------------
  -- ｘｍｌ用
  ------------------------------
  gt_xml_data_table         xml_data ;                -- ｘｍｌデータタグ表
  gl_xml_idx                NUMBER ;                  -- ｘｍｌデータタグ表のインデックス
  ------------------------------
  -- ルックアップ用
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
--
--#####################  固定共通例外宣言部 start   ####################
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
--
   /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ｘｍｌタグに変換する。
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
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理
   ***********************************************************************************/
  PROCEDURE prc_initialize(
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
--#####################  固定ローカル変数宣言部 start   ########################
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
    lv_f_date      VARCHAR2(20);
    lv_e_date      VARCHAR2(20);
--
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION ;     -- 値取得エラー
--
  BEGIN
--##################  固定ステータス初期化部 start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- 帳票出力値格納
    gr_header.report_id                   := 'XXCMN770009T' ;     -- 帳票id
    gr_header.exec_date                   := SYSDATE        ;     -- 実施日
--
    -- ====================================================
    -- 対象年月
    -- ====================================================
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_from , gc_char_y_format),gc_char_y_format);
    --日付型設定
    gr_param.proc_from_date_ch := SUBSTR(gr_param.proc_from,1,4) || gc_sla
                               || SUBSTR(gr_param.proc_from,5,2) || gc_sla_zero_one;
    gr_param.proc_from_date    :=  FND_DATE.STRING_TO_DATE( gr_param.proc_from_date_ch
                                                          , gc_char_d_format) - 1;
--
    -- 日付変換
    gr_header.proc_from_char := SUBSTR(lv_f_date,1,4) || gc_jp_yy
                             || SUBSTR(lv_f_date,5,2) || gc_jp_mm;
    IF (gr_param.proc_from_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                           , 'APP-XXCMN-10035'
                                           , gc_param_name
                                           , gc_cap_from
                                           , gc_param_value
                                           , gr_param.proc_from ) ;
      RAISE get_value_expt ;
    END IF;
--
    lv_e_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_to , gc_char_y_format),gc_char_y_format);
--
    gr_param.proc_to_date_ch   := SUBSTR(gr_param.proc_to,1,4) || gc_sla
                               || SUBSTR(gr_param.proc_to,5,2) || gc_sla_zero_one;
    gr_param.proc_to_date      := ADD_MONTHS(FND_DATE.STRING_TO_DATE( gr_param.proc_to_date_ch
                                                         , gc_char_d_format), 1);
    -- 日付変換
    gr_header.proc_to_char   := SUBSTR(lv_e_date,1,4)   || gc_jp_yy
                             || SUBSTR(lv_e_date,5,2)   || gc_jp_mm;
    IF (gr_param.proc_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              , 'APP-XXCMN-10035'
                                              , gc_param_name
                                              , gc_cap_to
                                              , gc_param_value
                                              , gr_param.proc_to ) ;
      RAISE get_value_expt ;
    END IF;
    gr_param.proc_to_date_ch   := TO_CHAR(gr_param.proc_to_date,gc_char_d_format);
--
    -- ====================================================
    -- 担当部署・担当者名
    -- ====================================================
    BEGIN
      gr_header.user_id   := FND_GLOBAL.USER_ID;
      gr_header.user_dept := xxcmn_common_pkg.get_user_dept(gr_header.user_id);
      gr_header.user_name := xxcmn_common_pkg.get_user_name(gr_header.user_id);
    EXCEPTION
      WHEN OTHERS THEN
        NULL ;
    END;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
--
--#################################  固定例外処理部 start   ####################################
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
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(I-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_data_rec   OUT nocopy tab_data_type_dtl  -- 02.取得レコード群
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
--#####################  固定ローカル変数宣言部 start   ########################
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
    cv_yes            CONSTANT VARCHAR2(1)  := 'Y';
    cv_lang           CONSTANT VARCHAR2(2)  := 'JA';
    cv_lookup         CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cn_one            CONSTANT NUMBER       := 1;
    -- 文書タイプ
    cv_porc           CONSTANT VARCHAR2(4)  := 'PORC';
    cv_omso           CONSTANT VARCHAR2(4)  := 'OMSO';
--
    -- *** ローカル・変数 ***
    lv_date_from  VARCHAR2(10) ;
    lv_date_to    VARCHAR2(10) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ｓｑｌ
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    lv_date_from := TO_CHAR(gr_param.proc_from_date , gc_char_d_format);
    lv_date_to   := TO_CHAR(gr_param.proc_to_date   , gc_char_d_format);
--
    -- ====================================================
    -- ｓｑｌ生成
    -- ====================================================
--
    lv_sql := 'SELECT '
      || '  xlei.item_code item_code_from,         '     --品目コード
      || '  xlei.item_short_name item_name_from,   '     --品目名称
      || '  xrpmpr.request_item_code item_code_to, '     --製品受払品目コード
      || '  ximv.item_short_name item_name_to,     '     --製品受払品目名称
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code                 gun_code ,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code            gun_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmpr.new_div_account rcv_pay_div,                    ' --取引区分
      || '  SUM(itp.trans_qty) trans_qty,                          ' --数量
      || '  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      || '    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      || '    xsup_m.stnd_unit_price)) '
      || '       )                      AS from_price ,'         --実際単価
      || '  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      || '    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      || '    xsup_m.stnd_unit_price)) * itp.trans_qty '
      || '     )    AS from_cost ,'     --実際原価
      || '  SUM(xsup.stnd_unit_price_gen) to_price,                ' --原料費
      || '  SUM(xsup.stnd_unit_price_gen * itp.trans_qty)  to_cost ' --振替先標準原価金額
      || 'FROM xxcmn_rcv_pay_mst_porc_rma_v xrpmpr '   --経理受払区分情報view_購買関連
      || '   , ic_tran_pnd              itp'           --在庫トラン
      || '   , xxcmn_lot_each_item_v    xlei '
      || '   , xxcmn_stnd_unit_price_v  xsup '
      || '   , xxcmn_stnd_unit_price_v  xsup_m '
      || '   , xxcmn_item_mst2_v        ximv '
      || '   , xxcmn_item_categories3_v xicv '
      || '   , xxcmn_lookup_values2_v   xlvv '
      || 'WHERE itp.doc_type            = ''' || cv_porc || ''''
      || '  AND itp.completed_ind       = '   || TO_CHAR(cn_one)
      || '  AND itp.trans_date BETWEEN xlei.start_date_active AND xlei.end_date_active'
      || '  AND xrpmpr.doc_type         = itp.doc_type'
      || '  AND xrpmpr.doc_id           = itp.doc_id'
      || '  AND xrpmpr.doc_line         = itp.doc_line'
      || '  AND xlei.item_id            = itp.item_id'
      || '  AND xlei.lot_id             = itp.lot_id'
      || '  AND xlei.item_id             = xsup_m.item_id'
      || '  AND xrpmpr.request_item_code = ximv.item_no(+)'
      || '  AND ximv.item_id            = xicv.item_id'
      || '  AND xsup.item_id            = ximv.item_id'
      || '  AND itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active'
      || '  AND xlvv.lookup_type        = ''' || cv_lookup || ''''
      || '  AND xrpmpr.dealings_div     = xlvv.meaning'
      || '  AND (xlvv.start_date_active IS NULL OR xlvv.start_date_active '
      ||                                               ' <= TRUNC(itp.trans_date))'
      || '  AND (xlvv.end_date_active   IS NULL OR xlvv.end_date_active '
      ||                                               ' >= TRUNC(itp.trans_date))'
      || '  AND xlvv.language           = ''' || cv_lang || ''''
      || '  AND xlvv.source_lang        = ''' || cv_lang || ''''
      || '  AND xlvv.enabled_flag       = ''' || cv_yes || ''''
      || '  AND xlvv.attribute9         IS NOT NULL   '-- 帳票フラグ
      || '  AND itp.trans_date          >= FND_DATE.STRING_TO_DATE('
      ||                                   ''''|| gr_param.proc_from_date_ch || ''''
      ||                                   ','''|| gc_char_d_format || ''')'
      || '  AND itp.trans_date          <  FND_DATE.STRING_TO_DATE('
      ||                                   ''''|| gr_param.proc_to_date_ch || ''''
      ||                                   ','''|| gc_char_d_format || ''')'
      || '  AND xicv.prod_class_code    = ''' || gr_param.prod_div || ''''
      || '  AND xicv.item_class_code    = ''' || gr_param.item_div || ''''
      ;
    IF (gr_param.rcv_pay_div IS NOT NULL) THEN
      lv_sql := lv_sql
        || '  AND xrpmpr.new_div_account  = ''' || gr_param.rcv_pay_div || '''';
    END IF
    ;
    IF (gr_param.crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.crowd_code   = ''' || gr_param.crowd_code || '''';
    END IF
    ;
    IF (gr_param.acnt_crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.acnt_crowd_code   = ''' || gr_param.acnt_crowd_code || '''';
    END IF
    ;
    lv_sql := lv_sql
      || 'GROUP BY '
      || '  xlei.item_code, '          -- 品目コード
      || '  xlei.item_short_name,'     -- 品目名称
      || '  xrpmpr.request_item_code,' -- 製品受払品目コード
      || '  ximv.item_short_name,    ' -- 製品受払品目名称
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code ,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmpr.new_div_account                            ' -- 取引区分
      || 'UNION ALL '
      || 'SELECT '
      || '  xlei.item_code          item_code_from,           ' -- 品目コード
      || '  xlei.item_short_name    item_name_from,           ' -- 品目名称
      || '  xrpmo.request_item_code item_code_to,             ' -- 製品受払品目コード
      || '  ximv.item_short_name    item_name_to,             ' -- 製品受払品目名称
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code      gun_code,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code gun_code,';
    END IF
    ;
    lv_sql := lv_sql
      ||'  xrpmo.new_div_account rcv_pay_div,                         ' -- 取引区分
      ||'  SUM(itp.trans_qty) trans_qty,                          ' -- 数量
      ||'  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      ||'    DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      ||'    xsup_m.stnd_unit_price)) '
      ||'       )                       AS from_price ,'                --実際単価
      ||'  SUM(DECODE(xlei.item_attribute15,'''|| gn_one ||''',xsup_m.stnd_unit_price,'
      ||'  DECODE(xlei.lot_ctl,'''|| gn_one1 ||''',xlei.actual_unit_price,'
      ||'  xsup_m.stnd_unit_price)) * itp.trans_qty '
      ||'  )    AS from_cost ,'    --実際原価
      ||'  SUM(xsup.stnd_unit_price_gen) to_price,                ' -- 原料費
      ||'  SUM(xsup.stnd_unit_price_gen * itp.trans_qty)  to_cost ' -- 振替先標準原価金額
      ||'FROM xxcmn_rcv_pay_mst_omso_v xrpmo '                     -- 経理受払区分情報view_受注関連
      ||'   , ic_tran_pnd              itp  '   --在庫トラン
      ||'   , xxcmn_lot_each_item_v    xlei '
      ||'   , xxcmn_stnd_unit_price_v  xsup '    --標準原価情報view
      || '   , xxcmn_stnd_unit_price_v  xsup_m '
      ||'   , xxcmn_lookup_values2_v   xlvv '
      ||'   , xxcmn_item_mst2_v        ximv '
      ||'   , xxcmn_item_categories3_v xicv '
      ||'WHERE itp.doc_type            = ''' || cv_omso || ''''
      ||'  AND itp.completed_ind       = '   || TO_CHAR(cn_one)
      ||'  AND xrpmo.doc_type          = itp.doc_type'
      ||'  AND xrpmo.doc_line          = itp.line_detail_id'
      ||'  AND xlei.item_id            = itp.item_id'
      ||'  AND xlei.lot_id             = itp.lot_id'
      || ' AND xlei.item_id             = xsup_m.item_id'
      ||'  AND itp.trans_date BETWEEN xlei.start_date_active AND xlei.end_date_active'
      ||'  AND xsup.item_id            = ximv.item_id'
      ||'  AND itp.trans_date BETWEEN xsup.start_date_active AND xsup.end_date_active'
      ||'  AND xrpmo.request_item_code = ximv.item_no(+)'
      ||'  AND ximv.item_id            = xicv.item_id'
      ||'  AND xlvv.lookup_type        = ''' || cv_lookup || ''''
      ||'  AND xrpmo.dealings_div      = xlvv.meaning'
      ||'  AND (xlvv.start_date_active IS NULL OR xlvv.start_date_active  <= TRUNC(itp.trans_date))'
      ||'  AND (xlvv.end_date_active   IS NULL OR xlvv.end_date_active    >= TRUNC(itp.trans_date))'
      ||'  AND xlvv.language           = ''' || cv_lang || ''''
      ||'  AND xlvv.source_lang        = ''' || cv_lang || ''''
      ||'  AND xlvv.enabled_flag       = ''' || cv_yes || ''''
      ||'  AND xlvv.attribute9         IS NOT NULL   ' -- 帳票フラグ
      ||'  AND itp.trans_date          >= FND_DATE.STRING_TO_DATE('
      ||                                  ''''|| gr_param.proc_from_date_ch || ''''
      ||                                  ','''|| gc_char_d_format || ''')'
      ||'  AND itp.trans_date          <  FND_DATE.STRING_TO_DATE('
      ||                                  ''''|| gr_param.proc_to_date_ch || ''''
      ||                                  ','''|| gc_char_d_format || ''')'
      ||'  AND xicv.prod_class_code    = ''' || gr_param.prod_div || ''''
      ||'  AND xicv.item_class_code    = ''' || gr_param.item_div || ''''
      ;
    IF (gr_param.rcv_pay_div IS NOT NULL) THEN
      lv_sql := lv_sql
        || '  AND xrpmo.new_div_account  = ''' || gr_param.rcv_pay_div || '''';
    END IF
    ;
    IF (gr_param.crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.crowd_code   = ''' || gr_param.crowd_code || '''';
    END IF
    ;
    IF (gr_param.acnt_crowd_code IS NOT NULL ) THEN
      lv_sql := lv_sql
        || ' AND xicv.acnt_crowd_code   = ''' || gr_param.acnt_crowd_code || '''';
    END IF
    ;
    lv_sql := lv_sql
      ||'GROUP BY  xlei.item_code , '           --品目コード
      ||'          xlei.item_short_name , '     --品目名称
      ||'          xrpmo.request_item_code ,  ' --製品受払品目コード
      ||'          ximv.item_short_name,'       --製品受払品目名称
      ;
    IF (gr_param.crowd_type = gc_gun) THEN
      lv_sql := lv_sql
        || '  xicv.crowd_code,';
    ELSE
      lv_sql := lv_sql
        || '  xicv.acnt_crowd_code ,';
    END IF
    ;
    lv_sql := lv_sql
      || '  xrpmo.new_div_account ' --取引区分
    ;
    lv_sql := lv_sql
      || 'ORDER BY  rcv_pay_div '
      ||         ', gun_code '
      ||         ', item_code_to '
      ||         ', item_code_from '
    ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
--
    -- オープン
    OPEN lc_ref FOR lv_sql ;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  固定例外処理部 start   ####################################
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
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ｘｍｌデータ作成(I-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- プログラム名
--
--#####################  固定ローカル変数宣言部 start   ########################
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
    lc_break                CONSTANT VARCHAR2(100) := '**' ;
--
    lc_depth_crowd_dtl      CONSTANT NUMBER :=  3;  -- 詳群
    lc_depth_crowd_low      CONSTANT NUMBER :=  5;  -- 小群
    lc_depth_crowd_mid      CONSTANT NUMBER :=  7;  -- 中群
    lc_depth_crowd_high     CONSTANT NUMBER :=  9;  -- 大群
    lc_depth_rcv_pay_div    CONSTANT NUMBER := 11;  -- 受払区分
    lc_depth_item_div       CONSTANT NUMBER := 13;  -- 品目区分
    lc_depth_prod_div       CONSTANT NUMBER := 15;  -- 商品区分
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- 改行深度(開始タグ出力用
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- 金額計算用
    ln_qty                  NUMBER DEFAULT 0;         -- 出来高
    ln_to_price             NUMBER DEFAULT 0;         -- 先標準原価
    ln_to_gen               NUMBER DEFAULT 0;         -- 先標準金額
    ln_from_price           NUMBER DEFAULT 0;         -- 元実際単価
    ln_from_gen             NUMBER DEFAULT 0;         -- 元実際金額
    ln_sai_tan              NUMBER DEFAULT 0;         -- 単価差異
    ln_sai_gen              NUMBER DEFAULT 0;         -- 原価差異
    --総合計用
    ln_sum_qty              NUMBER DEFAULT 0;         -- 出来高
    ln_sum_to_price         NUMBER DEFAULT 0;         -- 先標準原価
    ln_sum_to_gen           NUMBER DEFAULT 0;         -- 先標準金額
    ln_sum_from_price       NUMBER DEFAULT 0;         -- 元実際単価
    ln_sum_from_gen         NUMBER DEFAULT 0;         -- 元実際金額
    ln_sum_sai_tan          NUMBER DEFAULT 0;         -- 単価差異
    ln_sum_sai_gen          NUMBER DEFAULT 0;         -- 原価差異
--
    lb_ret                  BOOLEAN;
    ln_loop_index           NUMBER DEFAULT 0;
    lv_prod_div_name        VARCHAR2(20);
    lv_rcv_pay_div_name     VARCHAR2(20);
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
--
    ---------------------
    --  xml項目セット
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR    --  タグタイプ  T:タグ
                                                            -- D:データ
                                                            -- N:データ(NULLの場合タグを書かない)
                                                            -- Y:データ(NULL,0の場合タグを書かない)
                                                            -- Z:データ(NULLの場合0表示)
       ,iv_name              IN        VARCHAR2                --   タグ名
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   タグデータ(省略可
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   文字長（バイト）(省略可
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   インデックス(省略可
      )
    IS
      ln_xml_idx NUMBER;
      ln_work    NUMBER;
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
      ELSIF (ic_type = gc_y) THEN
        --NULL,0の場合タグを書かない対応(数値項目を想定)
        IF (NVL(iv_value, 0) = 0) THEN
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
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      --タグセット
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<タグ名>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<タグのみ>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<タグ ＆ データ>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --NULLの場合０表示
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --NULLでもそのまま表示
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
--##################  固定ステータス初期化部 start   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    --商品区分名取得
    BEGIN
      SELECT SUBSTRB(xcat_prod.description, 1 ,20)
      INTO   lv_prod_div_name
      FROM   xxcmn_categories_v xcat_prod
      WHERE  xcat_prod.category_set_name = gc_cat_prod_div
        AND  xcat_prod.segment1          = gr_param.prod_div
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --受払区分名取得
    IF (gr_param.rcv_pay_div IS NOT NULL)THEN
      BEGIN
        SELECT SUBSTRB(xlv_rcv_pay.meaning, 1 ,20)
        INTO   lv_rcv_pay_div_name
        FROM   xxcmn_lookup_values2_v xlv_rcv_pay
        WHERE  xlv_rcv_pay.lookup_type = gc_new_acnt_div
          AND  xlv_rcv_pay.lookup_code = gr_param.rcv_pay_div
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- =====================================================
    -- ヘッダーデータ抽出・出力処理
    -- =====================================================
    -- ヘッダー開始タグ
    prc_set_xml('T', 'user_info');
--
    -- 帳票ｉｄ
    prc_set_xml('D', 'report_id', gr_header.report_id);
--
    -- 担当者部署
    prc_set_xml('D', 'charge_dept', gr_header.user_dept, 10);
--
    -- 担当者名
    prc_set_xml('D', 'agent', gr_header.user_name, 14);
--
    -- 出力日
    prc_set_xml('D', 'exec_date', TO_CHAR(gr_header.exec_date,gc_char_dt_format));
--
    -- 抽出FROM
    prc_set_xml('D', 'p_trans_ym_from', gr_header.proc_from_char);
--
    -- 抽出to
    prc_set_xml('D', 'p_trans_ym_to', gr_header.proc_to_char);
--
    --商品区分
    prc_set_xml('D', 'p_item_div_code', gr_param.prod_div);
    prc_set_xml('D', 'p_item_div_name', lv_prod_div_name, 20);
--
    --受払区分
    prc_set_xml('D', 'p_rcv_pay_div_code', gr_param.rcv_pay_div);
    prc_set_xml('D', 'p_rcv_pay_div_name', lv_rcv_pay_div_name, 20);

--
    -- ヘッダー終了タグ
    prc_set_xml('T', '/user_info');
--
    -- =====================================================
    -- 項目データ抽出処理
    --=====================================================
    prc_get_report_data(
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
    -- データ部開始タグ
    prc_set_xml('T', 'data_info');
    --商品区分
    prc_set_xml('T', 'lg_prod_div');
    prc_set_xml('T', 'g_prod_div');
    --品目区分
    prc_set_xml('T', 'lg_item_div');
    prc_set_xml('T', 'g_item_div');
    --受払区分
    prc_set_xml('T', 'lg_rcv_pay_div');
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      --キー割れ判断用変数初期化
      ln_group_depth     := 0;
      lr_now_key.rcv_pay_div := gt_main_data(ln_loop_index).rcv_pay_div;
      lr_now_key.crowd_high  := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1);
      lr_now_key.crowd_mid   := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2);
      lr_now_key.crowd_low   := lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3);
      lr_now_key.crowd_dtl   :=   lr_now_key.rcv_pay_div
                             || SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4);
      lr_now_key.item_from   :=   gt_main_data(ln_loop_index).item_code_from;
      lr_now_key.item_to     :=   gt_main_data(ln_loop_index).item_code_to;
--
      -- =====================================================
      -- 終了タグ作成
      -- =====================================================
      -- 初回レコードの場合は終了タグを出力しない。
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_prod_div; --開始タグ表示用
        lb_isfirst := FALSE;
      ELSE
        --キー割れ判断　細かい順に判断
        -- 詳群
        IF ( NVL(lr_now_key.crowd_dtl, lc_break ) <> lr_pre_key.crowd_dtl ) THEN
          prc_set_xml('T', '/lg_item');
          prc_set_xml('T', '/g_crowd_dtl');
          ln_group_depth := lc_depth_crowd_dtl;
--
          -- 小群
          IF ( NVL(lr_now_key.crowd_low, lc_break ) <> lr_pre_key.crowd_low ) THEN
            prc_set_xml('T', '/lg_crowd_dtl');
            prc_set_xml('T', '/g_crowd_low');
            ln_group_depth := lc_depth_crowd_low;
--
            -- 中群
            IF ( NVL(lr_now_key.crowd_mid, lc_break ) <> lr_pre_key.crowd_mid ) THEN
              prc_set_xml('T', '/lg_crowd_low');
              prc_set_xml('T', '/g_crowd_mid');
              ln_group_depth := lc_depth_crowd_mid;
--
              -- 大群
              IF ( NVL(lr_now_key.crowd_high, lc_break ) <> lr_pre_key.crowd_high ) THEN
                prc_set_xml('T', '/lg_crowd_mid');
                prc_set_xml('T', '/g_crowd_high');
                ln_group_depth := lc_depth_crowd_high;
--
                -- 受払区分
                IF ( NVL(lr_now_key.rcv_pay_div, lc_break ) <> lr_pre_key.rcv_pay_div ) THEN
                  prc_set_xml('T', '/lg_crowd_high');
                  prc_set_xml('T', '/g_rcv_pay_div');
                  ln_group_depth := lc_depth_rcv_pay_div;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- =====================================================
      -- 開始タグ作成(大きい順
      -- =====================================================
      IF (ln_group_depth >= lc_depth_rcv_pay_div) THEN
        -- 受払区分
        prc_set_xml('T', 'g_rcv_pay_div');
        prc_set_xml('D', 'rcv_pay_div_code', gt_main_data(ln_loop_index).rcv_pay_div);
        prc_set_xml('T', 'lg_crowd_high');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_high) THEN
        -- 大群
        prc_set_xml('T', 'g_crowd_high');
        prc_set_xml('D', 'crowd_lcode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1));
        prc_set_xml('T', 'lg_crowd_mid');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_mid) THEN
        -- 中群
        prc_set_xml('T', 'g_crowd_mid');
        prc_set_xml('D', 'crowd_mcode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2));
        prc_set_xml('T', 'lg_crowd_low');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_low) THEN
        -- 小群
        prc_set_xml('T', 'g_crowd_low');
        prc_set_xml('D', 'crowd_scode'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3));
        prc_set_xml('T', 'lg_crowd_dtl');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_dtl) THEN
        -- 詳群
        prc_set_xml('T', 'g_crowd_dtl');
        prc_set_xml('D', 'crowd_code'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4));
        prc_set_xml('T', 'lg_item');
      END IF;
--
      -- 出来高
      ln_qty         := ln_qty        + NVL(gt_main_data(ln_loop_index).trans_qty, 0);
      -- 先標準金額
      ln_to_gen      := ln_to_gen     + NVL(gt_main_data(ln_loop_index).to_cost, 0);
      -- 元実際金額
      ln_from_gen    := ln_from_gen   + NVL(gt_main_data(ln_loop_index).from_cost, 0);
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
      IF (  (ln_loop_index = gt_main_data.COUNT)
         OR (gt_main_data(ln_loop_index + 1).rcv_pay_div
             || SUBSTR(gt_main_data(ln_loop_index + 1).gun_code , 1, 4)
             <> lr_now_key.crowd_dtl)
         OR (gt_main_data(ln_loop_index + 1).item_code_from <> lr_now_key.item_from )
         OR (gt_main_data(ln_loop_index + 1).item_code_to   <> lr_now_key.item_to   )
         ) THEN
--
        --明細開始
        prc_set_xml('T', 'g_item');
--
        --先品目
        prc_set_xml('D', 'item_code_to', gt_main_data(ln_loop_index).item_code_to);
        prc_set_xml('D', 'item_name_to', gt_main_data(ln_loop_index).item_name_to, 20);
--
        --元品目
        prc_set_xml('D', 'item_code_from', gt_main_data(ln_loop_index).item_code_from);
        prc_set_xml('D', 'item_name_from', gt_main_data(ln_loop_index).item_name_from, 20);
--
        --振替数量
        prc_set_xml('Z', 'quantity', ln_qty);
--
        --標準単価
        IF (ln_qty != 0) THEN
          ln_to_price := ln_to_gen / ln_qty;
        END IF;
        prc_set_xml('Z', 'standard_price', ln_to_price);
--
        --標準原価
        prc_set_xml('Z', 'standard_cost', ln_to_gen);
--
        --振替元実際単価
        IF (ln_qty != 0 ) THEN
          ln_from_price := ln_from_gen / ln_qty ;
        END IF;
        prc_set_xml('Z', 'actual_price', ln_from_price);
--
        --振替元実際原価
        prc_set_xml('Z', 'actual_cost', ln_from_gen);
--
        --単価差異
        ln_sai_tan := ln_to_price - ln_from_price;
        prc_set_xml('Z', 'difference_price', ln_sai_tan);
--
        --原価差異
        ln_sai_gen := ln_to_gen - ln_from_gen;
        prc_set_xml('Z', 'difference_cost', ln_sai_gen);
--
        -- 明細１行終了
        prc_set_xml('T', '/g_item');
--
        --合計加算
        ln_sum_qty        := ln_sum_qty        + ln_qty;
        ln_sum_to_gen     := ln_sum_to_gen     + ln_to_gen;
        ln_sum_from_gen   := ln_sum_from_gen   + ln_from_gen;
        ln_sum_sai_gen    := ln_sum_sai_gen    + ln_sai_gen;
--
        -- 初期化
        ln_qty         := 0;         -- 出来高
        ln_to_price    := 0;         -- 先標準原価
        ln_to_gen      := 0;         -- 先標準金額
        ln_from_price  := 0;         -- 元実際単価
        ln_from_gen    := 0;         -- 元実際金額
        ln_sai_tan     := 0;         -- 単価差異
        ln_sai_gen     := 0;         -- 原価差異
      END IF;
--
      --事後処理
      lr_pre_key := lr_now_key;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了タグ
    -- =====================================================
    prc_set_xml('T', '/lg_item');
    prc_set_xml('T', '/g_crowd_dtl');
    prc_set_xml('T', '/lg_crowd_dtl');
    prc_set_xml('T', '/g_crowd_low');
    prc_set_xml('T', '/lg_crowd_low');
    prc_set_xml('T', '/g_crowd_mid');
    prc_set_xml('T', '/lg_crowd_mid');
    prc_set_xml('T', '/g_crowd_high');
    prc_set_xml('T', '/lg_crowd_high');
--
    --受払グループ内に合計を表示
    -- 単価計算
    IF (ln_sum_qty != 0) THEN
      ln_sum_to_price   := ln_sum_to_gen   / ln_sum_qty;
      ln_sum_from_price := ln_sum_from_gen / ln_sum_qty;
      ln_sum_sai_tan    := ln_sum_to_price - ln_sum_from_price;
    END IF;
--
    --合計表示フラグ
    prc_set_xml('D', 'switch', 1);
    --出来高計
    prc_set_xml('Z', 'sum_quantity',         ln_sum_qty);
    --先単価平均
    prc_set_xml('Z', 'sum_standard_price',   ln_sum_to_price);
    --先原価計
    prc_set_xml('Z', 'sum_standard_cost',    ln_sum_to_gen);
    --元単価平均
    prc_set_xml('Z', 'sum_actual_price',     ln_sum_from_price);
    --元原価
    prc_set_xml('Z', 'sum_actual_cost',      ln_sum_from_gen);
    --単価差異
    prc_set_xml('Z', 'sum_difference_price', ln_sum_sai_tan);
    --原価差異
    prc_set_xml('Z', 'sum_difference_cost',  ln_sum_sai_gen);
--
    prc_set_xml('T', '/g_rcv_pay_div');
    prc_set_xml('T', '/lg_rcv_pay_div');
    prc_set_xml('T', '/g_item_div');
    prc_set_xml('T', '/lg_item_div');
    prc_set_xml('T', '/g_prod_div');
    prc_set_xml('T', '/lg_prod_div');
--
    -- データ部終了タグ
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,'app-xxcmn-10122'  ) ;
--
--#################################  固定例外処理部 start   ####################################
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
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月to
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_rcv_pay_div     IN    VARCHAR2  -- 受払区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
     ,ov_errbuf          OUT   VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         OUT   VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg          OUT   VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
--#####################  固定ローカル定数変数宣言部 start   ####################
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
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  固定ステータス初期化部 start   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
--
    -- 入力パラメータ保持
    gr_param.proc_from       := iv_proc_from      ; -- 処理年月FROM
    gr_param.proc_to         := iv_proc_to        ; -- 処理年月to
    gr_param.prod_div        := iv_prod_div       ; -- 商品区分
    gr_param.item_div        := iv_item_div       ; -- 品目区分
    gr_param.rcv_pay_div     := iv_rcv_pay_div    ; -- 受払区分
    gr_param.crowd_type      := iv_crowd_type     ; -- 集計種別
    gr_param.crowd_code      := iv_crowd_code     ; -- 群コード
    gr_param.acnt_crowd_code := iv_acnt_crowd_code; -- 経理群コード
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ｘｍｌ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '     <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '       <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '               <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                     </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                   </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '               </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </g_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '           </lg_rcv_pay_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '     </lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '   </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' </root>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      -- ｘｍｌヘッダー出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUt, '<root>' ) ;
--
      -- ｘｍｌデータ部出力
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := fnc_conv_xml (
                            iv_name   => gt_xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- タグタイプ
                          ) ;
        -- ｘｍｌタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- ｘｍｌフッダー出力
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
--#################################  固定例外処理部 start   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
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
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月to
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_rcv_pay_div     IN    VARCHAR2  -- 受払区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
    )
--
--###########################  固定部 start   ###########################
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
    submain(
        iv_proc_from       => iv_proc_from         -- 処理年月FROM
       ,iv_proc_to         => iv_proc_to           -- 処理年月to
       ,iv_prod_div        => iv_prod_div          -- 商品区分
       ,iv_item_div        => iv_item_div          -- 品目区分
       ,iv_rcv_pay_div     => iv_rcv_pay_div       -- 受払区分
       ,iv_crowd_type      => iv_crowd_type        -- 集計種別
       ,iv_crowd_code      => iv_crowd_code       -- 群コード
       ,iv_acnt_crowd_code => iv_acnt_crowd_code  -- 経理群コード
       ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 start   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxcmn770009c ;
/
