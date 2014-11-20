CREATE OR REPLACE PACKAGE BODY xxcmn820021c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn820021c(body)
 * Description      : 原価差異表作成
 * MD.050/070       : 標準原価マスタIssue1.0(T_MD050_BPO_820)
 *                    原価差異表作成Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.6
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_initialize              PROCEDURE : グローバル変数の編集を行う。
 *  prc_create_xml_data_user    PROCEDURE : タグ出力 - ユーザー情報
 *  prc_create_xml_data_param   PROCEDURE : タグ出力 - パラメータ情報
 *  prc_create_xml_data_dtl     PROCEDURE : タグ出力 - 明細情報
 *  prc_create_xml_data_typ     PROCEDURE : タグ出力 - 費目計情報
 *  prc_create_xml_data_itm_dtl PROCEDURE : タグ出力 - 品目情報（明細用）
 *  prc_create_xml_data_vnd_dtl PROCEDURE : タグ出力 - 取引先情報（明細用）
 *  prc_create_xml_data_s_dtl   PROCEDURE : タグ出力 - 項目計情報
 *  prc_create_xml_data_itm     PROCEDURE : タグ出力 - 品目情報
 *  prc_create_xml_data_vnd     PROCEDURE : タグ出力 - 取引先情報
 *  prc_create_xml_data_dpt     PROCEDURE : タグ出力 - 部署情報
 *  convert_into_xml            FUNCTION  : ＸＭＬタグに変換する。
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0   Masayuki Ikeda   新規作成
 *  2008/05/20    1.1   Masayuki Ikeda   内部変更要求#113対応
 *  2008/06/10    1.2   Kazuo Kumamoto   結合テスト障害対応(Null値によるテンプレート式エラー対応)
 *  2008/06/24    1.3   Kazuo Kumamoto   障害対応
 *                                       (1.3.1)システムテスト障害対応(仕入標準単価ヘッダ抽出条件追加)
 *                                       (1.3.2)結合テスト障害対応(ヘッダだけのページが出力される不具合の修正)
 *                                       (1.3.3)結合テスト障害対応(実質原価の算出方法変更)
 *  2008/06/30    1.4   Kazuo Kumamoto   システムテスト障害対応
 *                                       (1.4.1)ケース入り数が1件目しか出力されない不具合対応
 *                                       (1.4.2)「**項目計**」が「項目計」と出力される不具合対応
 *  2008/07/01    1.5   Marushita        ST不具合339対応製造日をロットマスタから取得
 *  2008/07/02    1.6   Satoshi Yunba    禁則文字対応
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
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'XXCMN820021C' ;   -- パッケージ名
  gc_report_id            CONSTANT VARCHAR2(20) := 'XXCMN820021T' ;   -- 帳票ID
--
  gc_language_code        CONSTANT VARCHAR2(2)  := 'JA' ;             -- 共通LANGUAGE_CODE
  -- 仮受金区分
  gc_temp_rcv_div_n       CONSTANT VARCHAR2(1)  := '0' ;              -- 対象外
  gc_temp_rcv_div_y       CONSTANT VARCHAR2(1)  := '1' ;              -- 対象
  -- マスタ区分
  gc_price_type_s         CONSTANT VARCHAR2(1)  := '2' ;              -- 標準
  gc_price_type_r         CONSTANT VARCHAR2(1)  := '1' ;              -- 実際（仕入）
  -- 仕入単価導出日タイプ
  gc_price_day_type_s     CONSTANT VARCHAR2(1)  := '1' ;              -- 製造日
  gc_price_day_type_n     CONSTANT VARCHAR2(1)  := '2' ;              -- 納入日
  -- 参照タイプ
  gc_lookup_item_type     CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE' ;        -- 費目区分
  gc_lookup_item_detail   CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_DETAIL_TYPE' ; -- 項目区分
--
  -- 品目カテゴリ名
  gc_cat_name_prod        CONSTANT VARCHAR2(100) := '商品区分' ;
  gc_cat_name_item        CONSTANT VARCHAR2(100) := '品目区分' ;
  gc_cat_name_crowd       CONSTANT VARCHAR2(100) := '群コード' ;
--
  -- エラーコード
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;  -- データ０件メッセージ
--
  -- ==================================================
  -- ユーザー定義グローバル変数
  -- ==================================================
  gv_sql_cmn_from       VARCHAR2(32000) ;   -- 共通Ｆｒｏｍ句
  gv_sql_cmn_where      VARCHAR2(32000) ;   -- 共通Ｗｈｅｒｅ句
--
--add start 1.3.2
  gv_dept_code          VARCHAR2(1000);
  gv_dept_name          VARCHAR2(1000);
--add end 1.3.2
  -- ==================================================
  -- ユーザー定義グローバル型
  -- ==================================================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      output_type       VARCHAR2(20)    -- 出力形式
     ,fiscal_ym         VARCHAR2(6)     -- 対象年月
     ,prod_div          VARCHAR2(1)     -- 商品区分
     ,item_div          VARCHAR2(1)     -- 品目区分
     ,dept_code         VARCHAR2(4)     -- 部署コード
     ,crowd_code_01     VARCHAR2(4)     -- 群コード１
     ,crowd_code_02     VARCHAR2(4)     -- 群コード２
     ,crowd_code_03     VARCHAR2(4)     -- 群コード３
     ,item_code_01      VARCHAR2(7)     -- 品目コード１
     ,item_code_02      VARCHAR2(7)     -- 品目コード２
     ,item_code_03      VARCHAR2(7)     -- 品目コード３
     ,item_code_04      VARCHAR2(7)     -- 品目コード４
     ,item_code_05      VARCHAR2(7)     -- 品目コード５
     ,vendor_id_01      VARCHAR2(15)    -- 取引先ＩＤ１
     ,vendor_id_02      VARCHAR2(15)    -- 取引先ＩＤ２
     ,vendor_id_03      VARCHAR2(15)    -- 取引先ＩＤ３
     ,vendor_id_04      VARCHAR2(15)    -- 取引先ＩＤ４
     ,vendor_id_05      VARCHAR2(15)    -- 取引先ＩＤ５
    ) ;
--
  TYPE rec_amount_data  IS RECORD 
    (
      s_unit_price   NUMBER   -- 標準原価
     ,r_unit_price   NUMBER   -- 実際原価
     ,d_unit_price   NUMBER   -- 原価差異
     ,s_amount       NUMBER   -- 標準金額
     ,r_amount       NUMBER   -- 実際金額
     ,d_amount       NUMBER   -- 金額差異
    ) ;

--
  TYPE ref_cursor IS REF CURSOR ;       -- REF_CURSOR用
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_param              rec_param_data ;      -- パラメータ
  gd_fiscal_date_from   DATE ;                -- 対象年月From
  gd_fiscal_date_to     DATE ;                -- 対象年月To
  gv_item_code          VARCHAR2(7) ;         -- 品目コード
  gv_item_name          VARCHAR2(20) ;        -- 品目名称
  gv_vendor_code        VARCHAR2(4) ;         -- 取引先コード
  gv_vendor_name        VARCHAR2(20) ;        -- 取引先名称
  gv_type_code          VARCHAR2(4) ;         -- 費目コード
  gv_type_name          VARCHAR2(20) ;        -- 費目名称
  gv_uom                VARCHAR2(10) ;        -- 単位
  gv_case_quant         NUMBER ;              -- 入数
  gv_quant              NUMBER := 0 ;         -- 数量
  gv_quant_disp         NUMBER := 0 ;         -- 数量（表示用）
  gv_quant_dpt          NUMBER := 0 ;         -- 数量（部署計）
--add start 1.4.1
  gv_save_case_quant    NUMBER := 0;
--add end 1.4.1
--
  gb_get_flg            BOOLEAN := FALSE ;    -- データ取得判定フラグ
  gt_xml_data_table     XML_DATA ;            -- ＸＭＬデータタグ表
  gl_xml_idx            NUMBER ;              -- ＸＭＬデータタグ表のインデックス
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
   * Procedure Name   : prc_initialize
   * Description      : グローバル変数の編集を行う。
   ************************************************************************************************/
  PROCEDURE prc_initialize
    (
      ov_errbuf             OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定数宣言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
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
  -- ==================================================
  -- 処理年月の編集
  -- ==================================================
  gd_fiscal_date_from   := FND_DATE.CANONICAL_TO_DATE( gr_param.fiscal_ym || '01' ) ;
  gd_fiscal_date_to     := LAST_DAY( gd_fiscal_date_from ) ;
--
  -- ==================================================
  -- 共通ＳＱＬ文の編集
  -- ==================================================
  gv_sql_cmn_from
    := '  ,xxpo_rcv_and_rtn_txns    xrart'
    || '  ,xxcmn_item_categories4_v xicv'
    ;
  gv_sql_cmn_where
    := ' AND   xrart.txns_date       BETWEEN :v1 AND :v2'
    || ' AND   xicv.item_id          = xrart.item_id'
    || ' AND   xicv.prod_class_code  = ''' || gr_param.prod_div || ''''
    || ' AND   xicv.item_class_code  = ''' || gr_param.item_div || ''''
    ;
  -- パラメータ．部署に入力がある場合
  IF  ( gr_param.dept_code IS NOT NULL )
  AND ( gr_param.dept_code <> xxcmn820011c.dept_code_all ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND   xrart.department_code = ''' || gr_param.dept_code || '''' ;
  END IF ;
  -- パラメータ．群コードのいずれかに入力がある場合
  IF ( gr_param.crowd_code_01 IS NOT NULL )
  OR ( gr_param.crowd_code_02 IS NOT NULL )
  OR ( gr_param.crowd_code_03 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xicv.crowd_code IN( ''' || gr_param.crowd_code_01 || ''''
                            || '  ,''' || gr_param.crowd_code_02 || ''''
                            || '  ,''' || gr_param.crowd_code_03 || ''' )'
      ;
  END IF ;
  -- パラメータ．品目コードのいずれかに入力がある場合
  IF ( gr_param.item_code_01 IS NOT NULL )
  OR ( gr_param.item_code_02 IS NOT NULL )
  OR ( gr_param.item_code_03 IS NOT NULL )
  OR ( gr_param.item_code_04 IS NOT NULL )
  OR ( gr_param.item_code_05 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xrart.item_code IN( ''' || gr_param.item_code_01 || ''''
                            || '  ,''' || gr_param.item_code_02 || ''''
                            || '  ,''' || gr_param.item_code_03 || ''''
                            || '  ,''' || gr_param.item_code_04 || ''''
                            || '  ,''' || gr_param.item_code_05 || ''' )'
      ;
  END IF ;
  -- パラメータ．取引先ＩＤのいずれかに入力がある場合
  IF ( gr_param.vendor_id_01 IS NOT NULL )
  OR ( gr_param.vendor_id_02 IS NOT NULL )
  OR ( gr_param.vendor_id_03 IS NOT NULL )
  OR ( gr_param.vendor_id_04 IS NOT NULL )
  OR ( gr_param.vendor_id_05 IS NOT NULL ) THEN
    gv_sql_cmn_where
      := gv_sql_cmn_where
      || ' AND xrart.vendor_id IN( ' || NVL( gr_param.vendor_id_01, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_02, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_03, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_04, 'NULL' )
                            || '  ,' || NVL( gr_param.vendor_id_05, 'NULL' ) || ' )'
      ;
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
  END prc_initialize ;
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
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.output_type || 'T' ;
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
   * Procedure Name   : prc_create_xml_data_param
   * Description      : パラメータ情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_param
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 固定ローカル定数
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_param' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- ユーザー宣言部
    -- ==================================================
    -- *** ローカル定数 ***
    lc_char_y       CONSTANT VARCHAR2(1200) := '年' ;
    lc_char_m       CONSTANT VARCHAR2(1200) := '月度' ;
    lc_sql          CONSTANT VARCHAR2(1200)
      := ' SELECT mct.description'
      || ' FROM mtl_category_sets_tl   mcst'
      ||     ' ,mtl_category_sets_b    mcsb'
      ||     ' ,mtl_categories_b       mcb'
      ||     ' ,mtl_categories_tl      mct'
      || ' WHERE mct.source_lang        = ''' || gc_language_code || ''''
      || ' AND   mct.language           = ''' || gc_language_code || ''''
      || ' AND   mcb.category_id        = mct.category_id'
      || ' AND   mcb.segment1           = :v1'
      || ' AND   mcsb.structure_id      = mcb.structure_id'
      || ' AND   mcst.category_set_id   = mcsb.category_set_id'
      || ' AND   mcst.source_lang       = ''' || gc_language_code || ''''
      || ' AND   mcst.language          = ''' || gc_language_code || ''''
      || ' AND   mcst.category_set_name = :v2'
      ;
--
    -- *** ローカル変数 ***
    lv_prod_div_name        VARCHAR2(20) ;    -- 商品区分名称
    lv_item_div_name        VARCHAR2(20) ;    -- 品目区分名称
--
    ex_no_data              EXCEPTION ;
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
    -- 商品区分名称取得
    BEGIN
      EXECUTE IMMEDIATE lc_sql
      INTO  lv_prod_div_name
      USING gr_param.prod_div
           ,gc_cat_name_prod
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE ex_no_data ;
    END ;
--
    -- 品目区分名称取得
    BEGIN
      EXECUTE IMMEDIATE lc_sql
      INTO  lv_item_div_name
      USING gr_param.item_div
           ,gc_cat_name_item
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE ex_no_data ;
    END ;
--
    -- ====================================================
    -- 開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- データタグ
    -- ====================================================
    -- 対象年月
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_01' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gr_param.fiscal_ym, 1, 4 ) || lc_char_y
                                            || SUBSTRB( gr_param.fiscal_ym, 5, 2 ) || lc_char_m ;
    -- 商品区分
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_02' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.prod_div ;
--
    -- 商品区分名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_remarks_02' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_prod_div_name ;
--
    -- 品目区分
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_03' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_param.item_div ;
--
    -- 品目区分名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'param_remarks_03' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_item_div_name ;
--
    -- ====================================================
    -- 終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/param_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN ex_no_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
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
  END prc_create_xml_data_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_dtl
   * Description      : 明細情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,iv_item_id    IN    VARCHAR2    -- 品目ＩＤ
     ,iv_vendor_id  IN    VARCHAR2    -- 取引先ＩＤ
     ,iv_item_type  IN    VARCHAR2    -- 費目ＩＤ
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dtl' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    -- 算出項目
    lr_amount               rec_amount_data ;
    -- 明細出力用項目
    lv_item_code          VARCHAR2(7) ;         -- 品目コード
    lv_item_name          VARCHAR2(20) ;        -- 品目名称
    lv_vendor_code        VARCHAR2(4) ;         -- 取引先コード
    lv_vendor_name        VARCHAR2(20) ;        -- 取引先名称
    lv_uom                VARCHAR2(10) ;        -- 単位
    lv_case_quant         NUMBER ;              -- 入数
    lv_type_code          VARCHAR2(4) ;         -- 費目コード
    lv_type_name          VARCHAR2(20) ;        -- 費目名称
    lv_quant              NUMBER ;              -- 数量
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_main
      (
        p_type_id     xxpo_price_lines.expense_item_type%TYPE
       ,p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT detail_code
            ,detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1         AS detail_code
                ,flv.meaning            AS detail_name
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type               = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xpl.expense_item_type = p_type_id
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT flv.attribute1         AS detail_code
                ,flv.meaning            AS detail_name
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type               = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xpl.expense_item_type = p_type_id
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY detail_code
              ,detail_name
      ORDER BY detail_code
    ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- 明細出力用項目を退避
    -- ====================================================
--
    -- ====================================================
    -- リストグループ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR re_main IN cu_main
      (
        p_type_id     => iv_item_type
       ,p_item_id     => iv_item_id
       ,p_vendor_id   => iv_vendor_id
       ,p_dept_code   => iv_dept_code
      )
    LOOP
      -- ----------------------------------------------------
      -- 原価差異を算出
      -- ----------------------------------------------------
      IF ( gv_quant = 0 ) THEN
        lr_amount.s_unit_price := 0 ;
        lr_amount.r_unit_price := 0 ; 
        lr_amount.d_unit_price := 0 ;
      ELSE
        lr_amount.s_unit_price := ROUND( re_main.s_amount / gv_quant, 2 ) ;
        lr_amount.r_unit_price := ROUND( re_main.r_amount / gv_quant, 2 ) ; 
        lr_amount.d_unit_price := lr_amount.s_unit_price - lr_amount.r_unit_price ;
      END IF ;
      lr_amount.s_amount     := re_main.s_amount ;
      lr_amount.r_amount     := re_main.r_amount ;
      lr_amount.d_amount     := re_main.s_amount - re_main.r_amount ;
--
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- データタグ出力
      -- ----------------------------------------------------
      -- 品目別取引先別表の場合
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                   ,xxcmn820011c.program_id_03 ) ) THEN   -- 明細：品目別
--
        -- 取引先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_vendor_code ;
        -- 取引先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_vendor_name ;
--
      -- 取引先別品目別表の場合
      ELSE
--
        -- 取引先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_item_code ;
        -- 取引先名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_item_name ;
--
      END IF ;
--
      -- 取引数量
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_disp ;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'uom' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_uom ;
      -- ケース入り数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'case_quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_case_quant ;
      -- 費目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_type_code ;
      -- 費目名
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_type_name ;
      -- 項目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := re_main.detail_code ;
      -- 項目名
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dtl_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := re_main.detail_name ;
--
      -- 標準原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.s_unit_price ;
      -- 実際原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.r_unit_price,0) ;
--mod end 1.2
      -- 原価差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'd_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.d_unit_price,0) ;
--mod end 1.2
      -- 標準金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 's_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.s_amount,0) ;
--mod end 1.2
      -- 実際金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.r_amount,0) ;
--mod end 1.2
      -- 金額差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'd_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount.d_amount,0) ;
--mod end 1.2
--
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- グローバル変数クリア
      -- ----------------------------------------------------
      -- 最初の１件のみ出力する項目をクリアする。
      gv_item_code   := NULL ;    -- 品目コード
      gv_item_name   := NULL ;    -- 品目名称
      gv_vendor_code := NULL ;    -- 取引先コード
      gv_vendor_name := NULL ;    -- 取引先名称
      gv_uom         := NULL ;    -- 単位
      gv_case_quant  := NULL ;    -- 入数
      gv_type_code   := NULL ;    -- 費目コード
      gv_type_name   := NULL ;    -- 費目名称
      gv_quant_disp  := NULL ;    -- 数量（表示用）
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- リストグループ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl_info' ;
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
  END prc_create_xml_data_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_typ
   * Description      : 費目計情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_typ
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,iv_item_id    IN    VARCHAR2    -- 品目ＩＤ
     ,iv_vendor_id  IN    VARCHAR2    -- 取引先ＩＤ
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_typ' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_main
      (
        p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT type_id
            ,type_code
            ,type_name
      FROM
        (
          SELECT xpl.expense_item_type  AS type_id
                ,flv.attribute1         AS type_code
                ,flv.meaning            AS type_name
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_type = flv.lookup_code
          AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT xpl.expense_item_type  AS type_id
                ,flv.attribute1         AS type_code
                ,flv.meaning            AS type_name
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type      = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_type = flv.lookup_code
          AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY type_id
              ,type_code
              ,type_name
      ORDER BY type_code
    ;
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- リストグループ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_typ' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    FOR re_main IN cu_main
      (
        p_item_id     => iv_item_id
       ,p_vendor_id   => iv_vendor_id
       ,p_dept_code   => iv_dept_code
      )
    LOOP
--
        -- ----------------------------------------------------
        -- 開始タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_typ' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- コード・名称を退避
        -- ----------------------------------------------------
        gv_type_code := re_main.type_code ;
        gv_type_name := re_main.type_name ;
--
        -- ====================================================
        -- 明細情報出力
        -- ====================================================
        prc_create_xml_data_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_item_id        => iv_item_id
           ,iv_vendor_id      => iv_vendor_id
           ,iv_item_type      => re_main.type_id
           ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
        -- ----------------------------------------------------
        -- 終了タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_typ' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- リストグループ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_typ' ;
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
  END prc_create_xml_data_typ ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_itm_dtl
   * Description      : 品目情報タグ出力（明細用）
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_itm_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,iv_vendor_id  IN    VARCHAR2    -- 取引先ＩＤ
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_itm_dtl' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    -- ＳＱＬ生成用
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    TYPE ret_value IS RECORD 
      (
        item_id         ic_item_mst_b.item_id%TYPE            -- 品目ＩＤ
       ,item_code       ic_item_mst_b.item_no%TYPE            -- 品目コード
       ,item_name       xxcmn_item_mst_b.item_short_name%TYPE -- 品目名称
       ,uom             xxpo_rcv_and_rtn_txns.uom%TYPE        -- 取引単位
       ,case_quant      ic_item_mst_b.attribute11%TYPE        -- 入数
       ,quant           xxpo_rcv_and_rtn_txns.quantity%TYPE   -- 取引数量
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＱＬ編集
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   iimc.item_id           AS item_id'     -- 品目ＩＤ
      || '  ,iimc.item_no           AS item_code'   -- 品目コード
      || '  ,ximc.item_short_name   AS item_name'   -- 品目名称
      || '  ,xrart.uom              AS uom'         -- 単位
      || '  ,iimc.attribute11       AS case_quant'  -- ケース入数
      || '  ,SUM( xrart.quantity )  AS quant'       -- 取引数量
      ;
    lv_sql_from
      := ' FROM'
      || '   ic_item_mst_b          iimc'           -- ＯＰＭ品目マスタ
      || '  ,xxcmn_item_mst_b       ximc'           -- ＯＰＭアドオン品目マスタ
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN ximc.start_date_active'
      || '                       AND     NVL( ximc.end_date_active, xrart.txns_date )'
      || ' AND iimc.item_id             = ximc.item_id'
      || ' AND xrart.item_id            = iimc.item_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || ' AND xrart.vendor_id          = :v4'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   xicv.crowd_code'
      || '  ,iimc.item_id'
      || '  ,iimc.item_no'
      || '  ,ximc.item_short_name'
      || '  ,xrart.uom'
      || '  ,iimc.attribute11'
      || ' ORDER BY'
      || '   xicv.crowd_code'   -- 群コード
      || '  ,iimc.item_no'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,iv_vendor_id
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
    -- ====================================================
    -- リストグループ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- 明細用項目を退避
      -- ----------------------------------------------------
      gv_item_code  := lr_ref.item_code ;         -- 品目コード
      gv_item_name  := lr_ref.item_name ;         -- 品目名称
      gv_uom        := lr_ref.uom ;               -- 単位
      gv_case_quant := lr_ref.case_quant ;        -- ケース入数
      gv_quant      := lr_ref.quant ;             -- 数量
      gv_quant_disp := lr_ref.quant ;             -- 数量（表示用）
--
      -- ====================================================
      -- 費目情報出力
      -- ====================================================
      prc_create_xml_data_typ
        (
          iv_dept_code      => iv_dept_code
         ,iv_item_id        => lr_ref.item_id
         ,iv_vendor_id      => iv_vendor_id
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- リストグループ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
  END prc_create_xml_data_itm_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_vnd_dtl
   * Description      : 取引先情報タグ出力（明細用）
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_vnd_dtl
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,iv_item_id    IN    VARCHAR2    -- 品目ＩＤ
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_vnd_dtl' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    -- ＳＱＬ生成用
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    TYPE ret_value IS RECORD 
      (
        vendor_id       po_vendors.vendor_id%TYPE             -- 取引先ＩＤ
       ,vendor_code     po_vendors.segment1%TYPE              -- 取引先コード
       ,vendor_name     po_vendors.vendor_name%TYPE           -- 取引先名称
       ,uom             xxpo_rcv_and_rtn_txns.uom%TYPE        -- 単位
       ,quant           xxpo_rcv_and_rtn_txns.quantity%TYPE   -- 取引数量
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＱＬ編集
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   pv.vendor_id           AS vendor_id'     -- 取引先ＩＤ
      || '  ,pv.segment1            AS vendor_code'   -- 取引先コード
      || '  ,xv.vendor_short_name   AS vendor_name'   -- 取引先名称
      || '  ,xrart.uom              AS uom'           -- 単位
      || '  ,SUM( xrart.quantity )  AS quant'         -- 取引数量
      ;
    lv_sql_from
      := ' FROM'
      || '   po_vendors    pv'    -- 仕入先マスタ
      || '  ,xxcmn_vendors xv'    -- 仕入先アドオンマスタ
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN xv.start_date_active'
      || '                       AND     NVL( xv.end_date_active, xrart.txns_date )'
      || ' AND pv.vendor_id             = xv.vendor_id'
      || ' AND xrart.vendor_id          = pv.vendor_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || ' AND xrart.item_id            = :v4'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   pv.vendor_id'
      || '  ,pv.segment1'
      || '  ,xv.vendor_short_name'
      || '  ,xrart.uom'
      || ' ORDER BY'
      || '   pv.segment1'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,iv_item_id
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
    -- ====================================================
    -- リストグループ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- 明細用項目を退避
      -- ----------------------------------------------------
      gv_vendor_code := lr_ref.vendor_code ;      -- 取引先コード
      gv_vendor_name := lr_ref.vendor_name ;      -- 取引先名称
      gv_uom         := lr_ref.uom ;              -- 単位
      gv_quant       := lr_ref.quant ;            -- 数量
      gv_quant_disp  := lr_ref.quant ;            -- 数量（表示用）
--
      -- ====================================================
      -- 費目情報出力
      -- ====================================================
--add start 1.4.1
      gv_case_quant := gv_save_case_quant;
--add end 1.4.1
      prc_create_xml_data_typ
        (
          iv_dept_code      => iv_dept_code
         ,iv_item_id        => iv_item_id
         ,iv_vendor_id      => lr_ref.vendor_id
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- リストグループ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
  END prc_create_xml_data_vnd_dtl ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_itm
   * Description      : 品目情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_itm
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_itm' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
--mod start 1.4.2
--    lc_s_dtl_sct_name VARCHAR2(10) := '項目計' ;
    lc_s_dtl_sct_name VARCHAR2(14) := '＊＊項目計＊＊' ;
--mod end 1.4.2
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    -- ＳＱＬ生成用
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
    -- 算出項目
    lr_amount_dif           rec_amount_data ;   -- 算出項目：原価差異合計
    lr_amount_rcv           rec_amount_data ;   -- 算出項目：仮受金合計
    lr_amount_dtl           rec_amount_data ;   -- 算出項目：項目計
--mod start 1.4.2
--    lv_s_dtl_sct_name       VARCHAR2(10) ;
    lv_s_dtl_sct_name       VARCHAR2(14) ;
--mod end 1.4.2
--add start 1.3.2
    lb_s_dtl                BOOLEAN; -- 取引先情報取得判定
    lb_item_info            BOOLEAN;
--add end 1.3.2
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    -- 品目別取引先別表用
    TYPE ret_value IS RECORD 
      (
        item_id         ic_item_mst_b.item_id%TYPE            -- 品目ＩＤ
       ,item_code       ic_item_mst_b.item_no%TYPE            -- 品目コード
       ,item_name       xxcmn_item_mst_b.item_short_name%TYPE -- 品目名称
       ,case_quant      ic_item_mst_b.attribute11%TYPE        -- ケース入数
       ,quant           NUMBER                                -- 取引数量
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_sum_dtl
      (
        p_item_id     xxpo_rcv_and_rtn_txns.item_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT attribute1       AS item_detail
            ,meaning          AS item_detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1
                ,flv.meaning
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          UNION ALL
          SELECT flv.attribute1
                ,flv.meaning
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.item_id         = p_item_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY attribute1
              ,meaning
      ORDER BY attribute1
    ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＱＬ編集
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   iimc.item_id           AS item_id'     -- 品目ＩＤ
      || '  ,iimc.item_no           AS item_code'   -- 品目コード
      || '  ,ximc.item_short_name   AS item_name'   -- 品目名称
      || '  ,iimc.attribute11       AS case_quant'  -- ケース入数
      || '  ,SUM( xrart.quantity )  AS quant'       -- 取引数量
      ;
    lv_sql_from
      := ' FROM'
      || '   ic_item_mst_b          iimc'           -- ＯＰＭ品目マスタ
      || '  ,xxcmn_item_mst_b       ximc'           -- ＯＰＭアドオン品目マスタ
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN ximc.start_date_active'
      || '                       AND     NVL( ximc.end_date_active, xrart.txns_date )'
      || ' AND iimc.item_id             = ximc.item_id'
      || ' AND xrart.item_id            = iimc.item_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   xicv.crowd_code'
      || '  ,iimc.item_id'
      || '  ,iimc.item_no'
      || '  ,ximc.item_short_name'
      || '  ,iimc.attribute11'
      || ' ORDER BY'
      || '   xicv.crowd_code'   -- 群コード
      || '  ,iimc.item_no'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
--
--del start 1.3.2 ※明細カーソルの下に移動
--    -- ====================================================
--    -- リストグループ開始タグ
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
--add start 1.3.2
    lb_item_info := false;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--add start 1.3.2
      lb_s_dtl := FALSE;
      <<sum_dtl_data_loop>>
      FOR re_sum_dtl IN cu_sum_dtl
        (
          p_item_id    => lr_ref.item_id
         ,p_dept_code  => iv_dept_code
        )
      LOOP
--add end 1.3.2
      gb_get_flg := TRUE ;
--add start 1.3.2
      IF (cu_sum_dtl%ROWCOUNT = 1) THEN
--add end 1.3.2
--add start 1.3.2
        IF (lc_ref%ROWCOUNT = 1 AND cu_sum_dtl%ROWCOUNT = 1) THEN
          IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                      ,xxcmn820011c.program_id_02            -- 合計：部門別品目別
                                      ,xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                      ,xxcmn820011c.program_id_06) ) THEN    -- 合計：部門別取引先別
            -- ====================================================
            -- 開始タグ
            -- ====================================================
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      --
            -- ====================================================
            -- データタグ
            -- ====================================================
            -- 所属部署コード
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_code ;
--mod end 1.3.2
            -- 所属部署名称
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_name ;
--mod end 1.3.2
          END IF;
          -- ====================================================
          -- リストグループ開始タグ
          -- ====================================================
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          lb_item_info := TRUE;
        END IF;
--add end 1.3.2
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_itm' ;
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
--
      -- ----------------------------------------------------
      -- 入数を退避
      -- ----------------------------------------------------
      gv_case_quant := lr_ref.case_quant ;
--
      -- ----------------------------------------------------
      -- 品目計を取得
      -- ----------------------------------------------------
      BEGIN
        SELECT SUM( s_dif_amount )  AS s_dif_amount
              ,SUM( s_rcv_amount )  AS s_rcv_amount
              ,SUM( r_dif_amount )  AS r_dif_amount
              ,SUM( r_rcv_amount )  AS r_rcv_amount
        INTO   lr_amount_dif.s_amount
              ,lr_amount_rcv.s_amount
              ,lr_amount_dif.r_amount
              ,lr_amount_rcv.r_amount
        FROM
          (
            SELECT CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_rcv_amount
                  ,0  AS r_dif_amount
                  ,0  AS r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns  xrart
                ,xxpo_price_headers     xph
                ,xxpo_price_lines       xpl
                ,xxcmn_lookup_values_v  flv
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_s
            AND   xrart.item_id         = xph.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.item_id         = lr_ref.item_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            UNION ALL
            SELECT 0  AS s_dif_amount
                  ,0  AS s_rcv_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns  xrart
                ,ic_item_mst_b          iimc
                ,po_headers_all         pha
                ,po_lines_all           pla
                ,xxpo_price_headers     xph
                ,xxpo_price_lines       xpl
                ,xxcmn_lookup_values_v  flv
                ,ic_lots_mst            ilm
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   DECODE( iimc.attribute20
                         ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                             , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                        )               BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
            AND   xph.supply_to_id IS NULL
--add end 1.3.1
            AND   xrart.item_id         = xph.item_id
            AND   pla.attribute3        = xph.futai_code
            AND   pla.attribute2        = xph.factory_code
            AND   xrart.source_document_line_num = pla.line_num
            AND   pha.po_header_id               = pla.po_header_id
            AND   xrart.source_document_number   = pha.segment1
            AND   xrart.item_id         = iimc.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.item_id         = lr_ref.item_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xrart.item_id         = ilm.item_id(+)
            AND   xrart.lot_number      = ilm.lot_no(+)
          )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_amount_dif.s_amount := 0 ;
          lr_amount_dif.r_amount := 0 ;
          lr_amount_rcv.s_amount := 0 ;
          lr_amount_rcv.r_amount := 0 ;
      END ;
--
      -- ----------------------------------------------------
      -- 原価差異を算出
      -- ----------------------------------------------------
      IF ( lr_ref.quant = 0 ) THEN
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.d_unit_price := 0 ;
        lr_amount_rcv.d_unit_price := 0 ;
      ELSE
        lr_amount_dif.s_unit_price := ROUND( lr_amount_dif.s_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.s_unit_price := ROUND( lr_amount_rcv.s_amount / lr_ref.quant, 2 ) ; 
        lr_amount_dif.r_unit_price := ROUND( lr_amount_dif.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.r_unit_price := ROUND( lr_amount_rcv.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_dif.d_unit_price := lr_amount_dif.s_unit_price - lr_amount_dif.r_unit_price ;
        lr_amount_rcv.d_unit_price := lr_amount_rcv.s_unit_price - lr_amount_rcv.r_unit_price ;
      END IF ;
      lr_amount_dif.d_amount     := lr_amount_dif.s_amount     - lr_amount_dif.r_amount ;
      lr_amount_rcv.d_amount     := lr_amount_rcv.s_amount     - lr_amount_rcv.r_amount ;
--
      gv_quant_dpt  := gv_quant_dpt + lr_ref.quant ;  -- 数量（部署計）
--
      -- ----------------------------------------------------
      -- 品目計項目を出力
      -- ----------------------------------------------------
      -- 原価差異合計：標準原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：実際原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：原価差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：標準金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_amount,0) ;
--mod end 1.2
      -- 原価差異合計：実際金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_amount,0) ;
--mod end 1.2
      -- 原価差異合計：金額差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_amount,0) ;
--mod end 1.2
--
      -- 仮受金合計：標準原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：実際原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：原価差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：標準金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_amount,0) ;
--mod end 1.2
      -- 仮受金合計：実際金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_amount,0) ;
--mod end 1.2
      -- 仮受金合計：金額差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_amount,0) ;
--mod end 1.2
--
      -- ====================================================
      -- 項目計出力
      -- ====================================================
      lv_s_dtl_sct_name := lc_s_dtl_sct_name ;
--
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
--
      lb_s_dtl := TRUE;
      END IF;
--add end 1.3.2
--
--del start 1.3.2 ※メインカーソルの下へ移動
--      <<sum_dtl_data_loop>>
--      FOR re_sum_dtl IN cu_sum_dtl
--        (
--          p_item_id    => lr_ref.item_id
--         ,p_dept_code  => iv_dept_code
--        )
--      LOOP
--del end 1.3.2
        -- ----------------------------------------------------
        -- 開始タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- 原価差異を算出
        -- ----------------------------------------------------
        IF ( lr_ref.quant = 0 ) THEN
          lr_amount_dtl.s_unit_price := 0 ;
          lr_amount_dtl.r_unit_price := 0 ;
          lr_amount_dtl.d_unit_price := 0 ;
        ELSE
          lr_amount_dtl.s_unit_price := ROUND( re_sum_dtl.s_amount / lr_ref.quant, 2 ) ;
          lr_amount_dtl.r_unit_price := ROUND( re_sum_dtl.r_amount / lr_ref.quant, 2 ) ; 
          lr_amount_dtl.d_unit_price := lr_amount_dtl.s_unit_price - lr_amount_dtl.r_unit_price ;
        END IF ;
        lr_amount_dtl.s_amount     := re_sum_dtl.s_amount ;
        lr_amount_dtl.r_amount     := re_sum_dtl.r_amount ;
        lr_amount_dtl.d_amount     := re_sum_dtl.s_amount - re_sum_dtl.r_amount ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- ヘッダ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_sct_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_s_dtl_sct_name ;
        -- 項目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail ;
        -- 項目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail_name ;
--
        -- 標準原価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_unit_price,0) ;
--mod end 1.2
        -- 実際原価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_unit_price,0) ;
--mod end 1.2
        -- 原価差異
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_unit_price,0) ;
--mod end 1.2
        -- 標準金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_amount,0) ;
--mod end 1.2
        -- 実際金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_amount,0) ;
--mod end 1.2
        -- 金額差異
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_amount,0) ;
--mod end 1.2
--
        -- ヘッダを出力するのは、最初の１件のみなので、１件目登録後にクリアする。
        lv_s_dtl_sct_name := NULL ;
--
        -- ----------------------------------------------------
        -- 終了タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      END LOOP sum_dtl_data_loop ;
--
--add start 1.3.2
      IF (lb_s_dtl) THEN
--add end 1.3.2
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ====================================================
      -- 取引先情報出力
      -- ====================================================
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                   ,xxcmn820011c.program_id_03 ) ) THEN   -- 明細：品目別
--add start 1.4.1
        gv_save_case_quant := lr_ref.case_quant ;
--add end 1.4.1
        prc_create_xml_data_vnd_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_item_id        => lr_ref.item_id
           ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
      END IF ;
--
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_itm' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
      END IF;
--add end 1.3.2
--
    END LOOP main_data_loop ;
--
--mod start 1.3.2
--    -- ====================================================
--    -- リストグループ終了タグ
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    IF (lb_item_info) THEN
      -- ====================================================
      -- リストグループ終了タグ
      -- ====================================================
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                  ,xxcmn820011c.program_id_02            -- 合計：部門別品目別
                                  ,xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                  ,xxcmn820011c.program_id_06) ) THEN    -- 合計：部門別取引先別
--
        -- 数量（部署計）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
        gv_quant_dpt := 0 ;
--
        -- ====================================================
        -- 終了タグ
        -- ====================================================
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      END IF;
    END IF;
--mod end 1.3.2
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
  END prc_create_xml_data_itm ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_vnd
   * Description      : 取引先情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_vnd
    (
      iv_dept_code  IN    VARCHAR2    -- 所属部署コード
     ,ov_errbuf     OUT   VARCHAR2    -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT   VARCHAR2    -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT   VARCHAR2    -- ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_vnd' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
--mod start 1.4.2
--    lc_s_dtl_sct_name VARCHAR2(10) := '項目計' ;
    lc_s_dtl_sct_name VARCHAR2(14) := '＊＊項目計＊＊' ;
--mod end 1.4.2
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    -- ＳＱＬ生成用
    lv_sql_select           VARCHAR2(1200) ;
    lv_sql_from             VARCHAR2(1200) ;
    lv_sql_where            VARCHAR2(1200) ;
    lv_sql_other            VARCHAR2(1200) ;
    lv_sql                  VARCHAR2(32000) ;
    -- 算出項目
    lr_amount_dif           rec_amount_data ;   -- 算出項目：原価差異合計
    lr_amount_rcv           rec_amount_data ;   -- 算出項目：仮受金合計
    lr_amount_dtl           rec_amount_data ;   -- 算出項目：項目計
--mod start 1.4.2
--    lv_s_dtl_sct_name       VARCHAR2(10) ;
    lv_s_dtl_sct_name       VARCHAR2(14) ;
--mod end 1.4.2
--add start 1.3.2
    lb_s_dtl                BOOLEAN;
    lb_vnd_info             BOOLEAN;
--add end 1.3.2
--
    -- ==================================================
    -- Ｒｅｆカーソル宣言
    -- ==================================================
    -- 取引先別品目別表用
    TYPE ret_value IS RECORD 
      (
        vendor_id       po_vendors.vendor_id%TYPE       -- 取引先ＩＤ
       ,vendor_code     po_vendors.segment1%TYPE        -- 取引先コード
       ,vendor_name     po_vendors.vendor_name%TYPE     -- 取引先名称
       ,quant           NUMBER                          -- 取引数量
      ) ;
    lc_ref    ref_cursor ;
    lr_ref    ret_value ;
--
    -- ==================================================
    -- カーソル宣言
    -- ==================================================
    CURSOR cu_sum_dtl
      (
        p_vendor_id   xxpo_rcv_and_rtn_txns.vendor_id%TYPE
       ,p_dept_code   xxpo_rcv_and_rtn_txns.department_code%TYPE
      )
    IS
      SELECT attribute1       AS item_detail
            ,meaning          AS item_detail_name
            ,SUM( s_amount )  AS s_amount
            ,SUM( r_amount )  AS r_amount
      FROM
        (
          SELECT flv.attribute1
                ,flv.meaning
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS s_amount
                ,xrart.quantity * xpl.unit_price AS s_amount
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                ,0                                              AS r_amount
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxcmn_item_categories4_v xicv
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id   = xpl.price_header_id
          AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_s
          AND   xrart.item_id         = xph.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xicv.item_id          = xrart.item_id
          AND   xicv.prod_class_code  = gr_param.prod_div
          AND   xicv.item_class_code  = gr_param.item_div
          AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
          UNION ALL
          SELECT flv.attribute1
                ,flv.meaning
                ,0                                              AS s_amount
--mod start 1.3.3
--                ,xrart.quantity * xpl.unit_price * xpl.quantity AS r_amount
                ,xrart.quantity * xpl.unit_price AS r_amount
--mod end 1.3.3
          FROM xxpo_rcv_and_rtn_txns    xrart
              ,xxcmn_item_categories4_v xicv
              ,ic_item_mst_b            iimc
              ,po_headers_all           pha
              ,po_lines_all             pla
              ,xxpo_price_headers       xph
              ,xxpo_price_lines         xpl
              ,xxcmn_lookup_values_v    flv
              ,ic_lots_mst              ilm
          WHERE flv.lookup_type              = gc_lookup_item_detail
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--          AND   xpl.expense_item_detail_type  = flv.lookup_code
          AND   xpl.expense_item_detail_type  = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
          AND   xph.price_header_id          = xpl.price_header_id
          AND   DECODE( iimc.attribute20
                       ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                           , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                      )               BETWEEN xph.start_date_active AND xph.end_date_active
          AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
          AND   xph.supply_to_id IS NULL
--add end 1.3.1
          AND   xrart.item_id         = xph.item_id
          AND   pla.attribute3        = xph.futai_code
          AND   pla.attribute2        = xph.factory_code
          AND   xrart.source_document_line_num = pla.line_num
          AND   pha.po_header_id               = pla.po_header_id
          AND   xrart.source_document_number   = pha.segment1
          AND   xrart.item_id         = iimc.item_id
          AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
          AND   xrart.vendor_id       = p_vendor_id
          AND   xrart.department_code = NVL( p_dept_code, department_code )
          AND   xicv.item_id          = xrart.item_id
          AND   xicv.prod_class_code  = gr_param.prod_div
          AND   xicv.item_class_code  = gr_param.item_div
          AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                   ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
          AND   xrart.item_id         = ilm.item_id(+)
          AND   xrart.lot_number      = ilm.lot_no(+)
        )
      GROUP BY attribute1
              ,meaning
      ORDER BY attribute1
    ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＱＬ編集
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   pv.vendor_id           AS vendor_id'     -- 取引先ＩＤ
      || '  ,pv.segment1            AS vendor_code'   -- 取引先コード
      || '  ,xv.vendor_short_name   AS vendor_name'   -- 取引先名称
      || '  ,SUM( xrart.quantity )  AS quant'         -- 取引数量
      ;
    lv_sql_from
      := ' FROM'
      || '   po_vendors    pv'    -- 仕入先マスタ
      || '  ,xxcmn_vendors xv'    -- 仕入先アドオンマスタ
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date   BETWEEN xv.start_date_active'
      || '                       AND     NVL( xv.end_date_active, xrart.txns_date )'
      || ' AND pv.vendor_id             = xv.vendor_id'
      || ' AND xrart.vendor_id          = pv.vendor_id'
      || ' AND xrart.department_code    = NVL( :v3, xrart.department_code )'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   pv.vendor_id'
      || '  ,pv.segment1'
      || '  ,xv.vendor_short_name'
      || ' ORDER BY'
      || '   pv.segment1'
      ;
--
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING iv_dept_code
         ,gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
-- 
--del start 1.3.2 ※明細カーソルの下に移動
--    -- ====================================================
--    -- リストグループ開始タグ
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
--add start 1.3.2
    lb_vnd_info := FALSE;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--add start 1.3.2
      lb_s_dtl := FALSE;
      <<sum_dtl_data_loop>>
      FOR re_sum_dtl IN cu_sum_dtl
        (
          p_vendor_id   => lr_ref.vendor_id
         ,p_dept_code   => iv_dept_code
        )
      LOOP
--add end 1.3.2
      gb_get_flg := TRUE ;
--add start 1.3.2
      IF (cu_sum_dtl%ROWCOUNT = 1) THEN
--add end 1.3.2
--add start 1.3.2
        IF (lc_ref%ROWCOUNT = 1 AND cu_sum_dtl%ROWCOUNT = 1) THEN
          IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                      ,xxcmn820011c.program_id_02            -- 合計：部門別品目別
                                      ,xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                      ,xxcmn820011c.program_id_06) ) THEN    -- 合計：部門別取引先別
            -- ====================================================
            -- 開始タグ
            -- ====================================================
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      --
            -- ====================================================
            -- データタグ
            -- ====================================================
            -- 所属部署コード
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_code ;
--mod end 1.3.2
            -- 所属部署名称
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.3.2
--            gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
            gt_xml_data_table(gl_xml_idx).tag_value := gv_dept_name ;
--mod end 1.3.2
          END IF;
          -- ====================================================
          -- リストグループ開始タグ
          -- ====================================================
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vnd_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          lb_vnd_info := TRUE;
        END IF;
--add end 1.3.2
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ----------------------------------------------------
      -- データタグ出力
      -- ----------------------------------------------------
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_code ;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.vendor_name ;
--
      -- ----------------------------------------------------
      -- 取引先計を取得
      -- ----------------------------------------------------
      BEGIN
        SELECT SUM( s_dif_amount ) AS s_dif_amount
              ,SUM( s_rcv_amount ) AS s_rcv_amount
              ,SUM( r_dif_amount ) AS r_dif_amount
              ,SUM( r_rcv_amount ) AS r_rcv_amount
        INTO   lr_amount_dif.s_amount
              ,lr_amount_rcv.s_amount
              ,lr_amount_dif.r_amount
              ,lr_amount_rcv.r_amount
        FROM
          (
            SELECT CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                          ELSE 0
                   END s_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
                     ELSE 0
                   END s_rcv_amount
                  ,0  AS r_dif_amount
                  ,0  AS r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns    xrart
                ,xxcmn_item_categories4_v xicv
                ,xxpo_price_headers       xph
                ,xxpo_price_lines         xpl
                ,xxcmn_lookup_values_v    flv
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   xrart.txns_date       BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_s
            AND   xrart.item_id         = xph.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.vendor_id       = lr_ref.vendor_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xicv.item_id          = xrart.item_id
            AND   xicv.prod_class_code  = gr_param.prod_div
            AND   xicv.item_class_code  = gr_param.item_div
            AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
            UNION ALL
            SELECT 0  AS s_dif_amount
                  ,0  AS s_rcv_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_n THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_dif_amount
                  ,CASE
                     WHEN flv.attribute3 = gc_temp_rcv_div_y THEN 
--mod start 1.3.3
--                          xrart.quantity * xpl.unit_price * xpl.quantity
                          xrart.quantity * xpl.unit_price
--mod end 1.3.3
                     ELSE 0
                   END r_rcv_amount
            FROM xxpo_rcv_and_rtn_txns    xrart
                ,xxcmn_item_categories4_v xicv
                ,ic_item_mst_b            iimc
                ,po_headers_all           pha
                ,po_lines_all             pla
                ,xxpo_price_headers       xph
                ,xxpo_price_lines         xpl
                ,xxcmn_lookup_values_v    flv
                ,ic_lots_mst              ilm
            WHERE flv.lookup_type       = gc_lookup_item_type
-- S 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ S --
--            AND   xpl.expense_item_type = flv.lookup_code
            AND   xpl.expense_item_type = flv.attribute1
-- E 2008/05/21 1.1 MOD BY M.Ikeda ------------------------------------------------------------ E --
            AND   xph.price_header_id   = xpl.price_header_id
            AND   DECODE( iimc.attribute20
                         ,gc_price_day_type_s, FND_DATE.CANONICAL_TO_DATE( ilm.attribute1 )
                                             , FND_DATE.CANONICAL_TO_DATE( pha.attribute4 )
                        )               BETWEEN xph.start_date_active AND xph.end_date_active
            AND   xph.price_type        = gc_price_type_r
--add start 1.3.1
            AND   xph.supply_to_id IS NULL
--add end 1.3.1
            AND   xrart.item_id         = xph.item_id
            AND   pla.attribute3        = xph.futai_code
            AND   pla.attribute2        = xph.factory_code
            AND   xrart.source_document_line_num = pla.line_num
            AND   pha.po_header_id               = pla.po_header_id
            AND   xrart.source_document_number   = pha.segment1
            AND   xrart.item_id         = iimc.item_id
            AND   xrart.txns_date       BETWEEN gd_fiscal_date_from AND gd_fiscal_date_to
            AND   xrart.vendor_id       = lr_ref.vendor_id
            AND   xrart.department_code = NVL( iv_dept_code, department_code )
            AND   xicv.item_id          = xrart.item_id
            AND   xicv.prod_class_code  = gr_param.prod_div
            AND   xicv.item_class_code  = gr_param.item_div
            AND   xicv.crowd_code IN( NVL( gr_param.crowd_code_01, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_02, xicv.crowd_code )
                                     ,NVL( gr_param.crowd_code_03, xicv.crowd_code ) )
            AND   xrart.item_id         = ilm.item_id(+)
            AND   xrart.lot_number      = ilm.lot_no(+)
          )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lr_amount_dif.s_amount      := 0 ;
          lr_amount_dif.r_amount      := 0 ;
          lr_amount_rcv.s_amount      := 0 ;
          lr_amount_rcv.r_amount      := 0 ;
      END ;
      -- ----------------------------------------------------
      -- 原価差異を算出
      -- ----------------------------------------------------
      IF ( lr_ref.quant = 0 ) THEN
        lr_amount_dif.s_unit_price := 0 ;
        lr_amount_rcv.s_unit_price := 0 ;
        lr_amount_dif.r_unit_price := 0 ;
        lr_amount_rcv.r_unit_price := 0 ;
        lr_amount_dif.d_unit_price := 0 ;
        lr_amount_rcv.d_unit_price := 0 ;
      ELSE
        lr_amount_dif.s_unit_price := ROUND( lr_amount_dif.s_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.s_unit_price := ROUND( lr_amount_rcv.s_amount / lr_ref.quant, 2 ) ; 
        lr_amount_dif.r_unit_price := ROUND( lr_amount_dif.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_rcv.r_unit_price := ROUND( lr_amount_rcv.r_amount / lr_ref.quant, 2 ) ;
        lr_amount_dif.d_unit_price := lr_amount_dif.s_unit_price - lr_amount_dif.r_unit_price ;
        lr_amount_rcv.d_unit_price := lr_amount_rcv.s_unit_price - lr_amount_rcv.r_unit_price ;
      END IF ;
      lr_amount_dif.d_amount     := lr_amount_dif.s_amount     - lr_amount_dif.r_amount ;
      lr_amount_rcv.d_amount     := lr_amount_rcv.s_amount     - lr_amount_rcv.r_amount ;
--
      gv_quant_dpt  := gv_quant_dpt + lr_ref.quant ;  -- 数量（部署計）
--
      -- 原価差異合計：標準原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：実際原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：原価差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_unit_price,0) ;
--mod end 1.2
      -- 原価差異合計：標準金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.s_amount,0) ;
--mod end 1.2
      -- 原価差異合計：実際金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.r_amount,0) ;
--mod end 1.2
      -- 原価差異合計：金額差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'dif_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dif.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dif.d_amount,0) ;
--mod end 1.2
--
      -- 仮受金合計：標準原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：実際原価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：原価差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_unit_price ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_unit_price,0) ;
--mod end 1.2
      -- 仮受金合計：標準金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_s_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.s_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.s_amount,0) ;
--mod end 1.2
      -- 仮受金合計：実際金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_r_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.r_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.r_amount,0) ;
--mod end 1.2
      -- 仮受金合計：金額差異
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rcv_d_amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_rcv.d_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_rcv.d_amount,0) ;
--mod end 1.2
--
      -- ====================================================
      -- 項目計出力
      -- ====================================================
      lv_s_dtl_sct_name := lc_s_dtl_sct_name ;
--
      -- ----------------------------------------------------
      -- 開始タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
--
      lb_s_dtl := TRUE;
      END IF;
--add end 1.3.2
--
--del start 1.3.2 ※メインカーソルの下へ移動
--      <<sum_dtl_data_loop>>
--      FOR re_sum_dtl IN cu_sum_dtl
--        (
--          p_vendor_id   => lr_ref.vendor_id
--         ,p_dept_code   => iv_dept_code
--        )
--      LOOP
--del end 1.3.2
        -- ----------------------------------------------------
        -- 開始タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- ----------------------------------------------------
        -- 原価差異を算出
        -- ----------------------------------------------------
        IF ( lr_ref.quant = 0 ) THEN
          lr_amount_dtl.s_unit_price := 0 ;
          lr_amount_dtl.r_unit_price := 0 ;
          lr_amount_dtl.d_unit_price := 0 ;
        ELSE
          lr_amount_dtl.s_unit_price := ROUND( re_sum_dtl.s_amount / lr_ref.quant, 2 ) ;
          lr_amount_dtl.r_unit_price := ROUND( re_sum_dtl.r_amount / lr_ref.quant, 2 ) ; 
          lr_amount_dtl.d_unit_price := lr_amount_dtl.s_unit_price - lr_amount_dtl.r_unit_price ;
        END IF ;
        lr_amount_dtl.s_amount     := re_sum_dtl.s_amount ;
        lr_amount_dtl.r_amount     := re_sum_dtl.r_amount ;
        lr_amount_dtl.d_amount     := re_sum_dtl.s_amount - re_sum_dtl.r_amount ;
--
        -- ----------------------------------------------------
        -- データタグ出力
        -- ----------------------------------------------------
        -- ヘッダ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_sct_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_s_dtl_sct_name ;
        -- 項目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail ;
        -- 項目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_dtl_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := re_sum_dtl.item_detail_name ;
--
        -- 標準原価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_unit_price,0) ;
--mod end 1.2
        -- 実際原価
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_unit_price,0) ;
--mod end 1.2
        -- 原価差異
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_unit_price ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_unit_price,0) ;
--mod end 1.2
        -- 標準金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_s_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.s_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.s_amount,0) ;
--mod end 1.2
        -- 実際金額
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_r_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.r_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.r_amount,0) ;
--mod end 1.2
        -- 金額差異
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 's_dtl_d_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--mod start 1.2
--        gt_xml_data_table(gl_xml_idx).tag_value := lr_amount_dtl.d_amount ;
        gt_xml_data_table(gl_xml_idx).tag_value := NVL(lr_amount_dtl.d_amount,0) ;
--mod end 1.2
--
        -- ヘッダを出力するのは、最初の１件のみなので、１件目登録後にクリアする。
        lv_s_dtl_sct_name := NULL ;
--
        -- ----------------------------------------------------
        -- 終了タグ
        -- ----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_s_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      END LOOP sum_dtl_data_loop ;
--
--add start 1.3.2
      IF (lb_s_dtl) THEN
--add end 1.3.2
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_s_dtl' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
      -- ====================================================
      -- 品目情報出力（明細表のみ）
      -- ====================================================
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                   ,xxcmn820011c.program_id_07 ) ) THEN   -- 明細：取引先別
--
        prc_create_xml_data_itm_dtl
          (
            iv_dept_code      => iv_dept_code
           ,iv_vendor_id      => lr_ref.vendor_id
           ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
            RAISE global_process_expt ;
        END IF ;
--
      END IF ;
--
      -- ----------------------------------------------------
      -- 終了タグ
      -- ----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vnd' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--add start 1.3.2
      END IF;
--add end 1.3.2
--
    END LOOP main_data_loop ;
--
--mod start 1.3.2
--    -- ====================================================
--    -- リストグループ終了タグ
--    -- ====================================================
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    IF (lb_vnd_info) THEN
      -- ====================================================
      -- リストグループ終了タグ
      -- ====================================================
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vnd_info' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      IF (gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                  ,xxcmn820011c.program_id_02            -- 合計：部門別品目別
                                  ,xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                  ,xxcmn820011c.program_id_06) ) THEN    -- 合計：部門別取引先別
--
        -- 数量（部署計）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
        gv_quant_dpt := 0 ;
--
        -- ====================================================
        -- 終了タグ
        -- ====================================================
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      END IF;
    END IF;
--mod end 1.3.2
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
  END prc_create_xml_data_vnd ;
--
  /************************************************************************************************
   * Procedure Name   : prc_create_xml_data_dpt
   * Description      : 部署情報タグ出力
   ************************************************************************************************/
  PROCEDURE prc_create_xml_data_dpt
    (
      ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ==================================================
    -- 定  数  宣  言
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data_dpt' ; -- プログラム名
--
--##### 固定ローカル変数宣言部 START #################################
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--##### 固定ローカル変数宣言部 END   #################################
--
    -- ==================================================
    -- 変  数  宣  言
    -- ==================================================
    lv_sql_select   VARCHAR2(1200) ;
    lv_sql_from     VARCHAR2(1200) ;
    lv_sql_where    VARCHAR2(1200) ;
    lv_sql_other    VARCHAR2(1200) ;
    lv_sql          VARCHAR2(32000) ;
--
    lc_ref      ref_cursor ;
--
    TYPE ret_value IS RECORD 
      (
        dept_code       hr_locations_all.location_code%TYPE   -- 所属部署コード
       ,dept_name       hr_locations_all.description%TYPE     -- 所属部署名称
      ) ;
    lr_ref    ret_value ;
--
  BEGIN
--
--##### 固定ステータス初期化部 START #################################
    ov_retcode := gv_status_normal;
--##### 固定ステータス初期化部 END   #################################
--
    -- ====================================================
    -- ＳＱＬ編集
    -- ====================================================
    lv_sql_select
      := ' SELECT'
      || '   hla.location_code       AS dept_code' -- 所属部署コード
      || '  ,xla.location_short_name AS dept_name' -- 所属部署名称
      ;
    lv_sql_from
      := ' FROM'
      || '   hr_locations_all         hla'
      || '  ,xxcmn_locations_all      xla'
      || gv_sql_cmn_from
      ;
    lv_sql_where
      := ' WHERE'
      || '     xrart.txns_date       BETWEEN xla.start_date_active'
                                || ' AND     NVL( xla.end_date_active, xrart.txns_date )'
      || ' AND hla.location_id       = xla.location_id'
      || ' AND xrart.department_code = hla.location_code'
      || gv_sql_cmn_where
      ;
    lv_sql_other
      := ' GROUP BY'
      || '   hla.location_code'
      || '  ,xla.location_short_name'
      || ' ORDER BY'
      || '   hla.location_code'
      ;
    lv_sql := lv_sql_select || lv_sql_from || lv_sql_where || lv_sql_other ;
--
    -- ====================================================
    -- カーソルオープン
    -- ====================================================
    OPEN lc_ref FOR lv_sql
    USING gd_fiscal_date_from
         ,gd_fiscal_date_to
    ;
    -- ====================================================
    -- リストグループ開始タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dpt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
--add start 1.3.2
      gb_get_flg := FALSE ;
--add end 1.3.2
    <<main_data_loop>>
    LOOP
--
      FETCH lc_ref INTO lr_ref ;
      EXIT WHEN lc_ref%NOTFOUND ;
--
--del start 1.3.2
--      gb_get_flg := TRUE ;
--del end 1.3.2
--del start 1.3.2 ※prc_create_xml_data_itmとprc_create_xml_data_vndへ移動
--      -- ====================================================
--      -- 開始タグ
--      -- ====================================================
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
----
--      -- ====================================================
--      -- データタグ
--      -- ====================================================
--      -- 所属部署コード
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_code' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_code ;
--      -- 所属部署名称
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'dept_name' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := lr_ref.dept_name ;
--del end 1.3.2
--
--add start 1.3.2
      gv_dept_code := lr_ref.dept_code;
      gv_dept_name := lr_ref.dept_name;
--add end 1.3.2
      ------------------------------
      -- 品目別取引先別表の場合
      ------------------------------
      IF ( gr_param.output_type IN( xxcmn820011c.program_id_01              -- 明細：部署別品目別
                                   ,xxcmn820011c.program_id_02 ) ) THEN     -- 合計：部署別品目別
--
        -- 品目情報出力処理を呼び出す。
        prc_create_xml_data_itm
          (
            iv_dept_code      => lr_ref.dept_code
           ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      ------------------------------
      -- 取引先別品目別表の場合
      ------------------------------
      ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_05           -- 明細：部署別取引先別
                                      ,xxcmn820011c.program_id_06 ) ) THEN  -- 合計：部署別取引先別
--
        -- 取引先情報出力処理を呼び出す。
        prc_create_xml_data_vnd
          (
            iv_dept_code      => lr_ref.dept_code
           ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
           ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
           ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
          ) ;
        IF ( lv_retcode = gv_status_error ) THEN
          RAISE global_process_expt ;
        END IF ;
--
      END IF ;
--
--del start 1.3.2 ※prc_create_xml_data_itmとprc_create_xml_data_vndへ移動
--      -- 数量（部署計）
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--      gt_xml_data_table(gl_xml_idx).tag_value := gv_quant_dpt;
--
--      gv_quant_dpt := 0 ;
----
--      -- ====================================================
--      -- 終了タグ
--      -- ====================================================
--      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dpt' ;
--      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--del end 1.3.2
--
    END LOOP main_data_loop ;
--
    -- ====================================================
    -- リストグループ終了タグ
    -- ====================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dpt_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ====================================================
    -- カーソルクローズ
    -- ====================================================
    CLOSE lc_ref ;
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
  END prc_create_xml_data_dpt ;
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
      iv_output_type        IN     VARCHAR2         -- 01 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : 対象年月
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 04 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         -- 05 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : 取引先ＩＤ５
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
    gr_param.output_type        := iv_output_type ;       -- 出力形式
    gr_param.fiscal_ym          := iv_fiscal_ym ;         -- 対象年月
    gr_param.prod_div           := iv_prod_div ;          -- 商品区分
    gr_param.item_div           := iv_item_div ;          -- 品目区分
    gr_param.dept_code          := iv_dept_code ;         -- 所属部署
    gr_param.crowd_code_01      := iv_crowd_code_01 ;     -- 群コード１
    gr_param.crowd_code_02      := iv_crowd_code_02 ;     -- 群コード２
    gr_param.crowd_code_03      := iv_crowd_code_03 ;     -- 群コード３
    gr_param.item_code_01       := iv_item_code_01 ;      -- 品目コード１
    gr_param.item_code_02       := iv_item_code_02 ;      -- 品目コード２
    gr_param.item_code_03       := iv_item_code_03 ;      -- 品目コード３
    gr_param.item_code_04       := iv_item_code_04 ;      -- 品目コード４
    gr_param.item_code_05       := iv_item_code_05 ;      -- 品目コード５
    gr_param.vendor_id_01       := iv_vendor_id_01 ;      -- 取引先ＩＤ１
    gr_param.vendor_id_02       := iv_vendor_id_02 ;      -- 取引先ＩＤ２
    gr_param.vendor_id_03       := iv_vendor_id_03 ;      -- 取引先ＩＤ３
    gr_param.vendor_id_04       := iv_vendor_id_04 ;      -- 取引先ＩＤ４
    gr_param.vendor_id_05       := iv_vendor_id_05 ;      -- 取引先ＩＤ５
--
    -- =====================================================
    -- グローバル変数編集
    -- =====================================================
    prc_initialize
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
    -- パラメータ情報出力
    -- =====================================================
    prc_create_xml_data_param
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
    ------------------------------
    -- 部署別表の場合
    ------------------------------
    IF ( gr_param.output_type IN( xxcmn820011c.program_id_01            -- 明細：部門別品目別
                                 ,xxcmn820011c.program_id_02            -- 合計：部門別品目別
                                 ,xxcmn820011c.program_id_05            -- 明細：部門別取引先別
                                 ,xxcmn820011c.program_id_06 ) ) THEN   -- 合計：部門別取引先別
--
      -- 部署情報出力処理を呼び出す。
      prc_create_xml_data_dpt
        (
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
    ------------------------------
    -- 品目別取引先別表の場合
    ------------------------------
    ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_03                -- 明細：品目別
                                    ,xxcmn820011c.program_id_04 ) ) THEN       -- 合計：品目別
--
      -- 品目情報出力処理を呼び出す。
      prc_create_xml_data_itm
        (
          iv_dept_code      => NULL
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
    ------------------------------
    -- 取引先別品目別表の場合
    ------------------------------
    ELSIF ( gr_param.output_type IN( xxcmn820011c.program_id_07             -- 明細：取引先別
                                    ,xxcmn820011c.program_id_08 ) ) THEN    -- 合計：取引先別
--
      -- 取引先情報出力処理を呼び出す。
      prc_create_xml_data_vnd
        (
          iv_dept_code      => NULL
         ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
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
    IF ( gb_get_flg = FALSE ) THEN
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
      -- 明細：部門別品目別
      IF ( gr_param.output_type = xxcmn820011c.program_id_01 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_02 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_03 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_04 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_05 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                  <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_06 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_dpt>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_dpt_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_07 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        <g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          <lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            <g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '            </g_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '          </lg_typ>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '        </g_itm>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      </lg_item_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      ELSIF ( gr_param.output_type = xxcmn820011c.program_id_08 ) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<data_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '      <msg>' || lv_errmsg || '</msg>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    </g_vnd>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </lg_vnd_info>' ) ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '</data_info>' ) ;
--
      END IF ;
--
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
     ,iv_output_type        IN     VARCHAR2         -- 01 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : 対象年月
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 04 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         -- 05 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : 取引先ＩＤ５
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
        iv_output_type    => iv_output_type           -- 01 : 出力形式
       ,iv_fiscal_ym      => iv_fiscal_ym             -- 02 : 対象年月
       ,iv_prod_div       => iv_prod_div              -- 03 : 商品区分
       ,iv_item_div       => iv_item_div              -- 04 : 品目区分
       ,iv_dept_code      => iv_dept_code             -- 05 : 所属部署
       ,iv_crowd_code_01  => iv_crowd_code_01         -- 06 : 群コード１
       ,iv_crowd_code_02  => iv_crowd_code_02         -- 07 : 群コード２
       ,iv_crowd_code_03  => iv_crowd_code_03         -- 08 : 群コード３
       ,iv_item_code_01   => iv_item_code_01          -- 09 : 品目コード１
       ,iv_item_code_02   => iv_item_code_02          -- 10 : 品目コード２
       ,iv_item_code_03   => iv_item_code_03          -- 11 : 品目コード３
       ,iv_item_code_04   => iv_item_code_04          -- 12 : 品目コード４
       ,iv_item_code_05   => iv_item_code_05          -- 13 : 品目コード５
       ,iv_vendor_id_01   => iv_vendor_id_01          -- 09 : 品目コード１
       ,iv_vendor_id_02   => iv_vendor_id_02          -- 10 : 品目コード２
       ,iv_vendor_id_03   => iv_vendor_id_03          -- 11 : 品目コード３
       ,iv_vendor_id_04   => iv_vendor_id_04          -- 12 : 品目コード４
       ,iv_vendor_id_05   => iv_vendor_id_05          -- 13 : 品目コード５
       ,ov_errbuf         => lv_errbuf                -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode               -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxcmn820021c ;
/
