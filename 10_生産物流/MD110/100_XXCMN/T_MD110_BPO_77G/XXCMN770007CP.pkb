CREATE OR REPLACE PACKAGE BODY xxcmn770007cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770007CP(body)
 * Description      : 生産原価差異表(プロト)
 * MD.050           : 有償支給帳票Issue1.0(T_MD050_BPO_770)
 * MD.070           : 有償支給帳票Issue1.0(T_MD070_BPO_77G)
 * Version          : 1.17
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(G-1)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(G-1)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(G-2)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/09    1.0   K.Kamiyoshi      新規作成
 *  2008/05/16    1.1   Y.Majikina       パラメータ：処理年月がYYYYMで入力された時、エラー
 *                                       となる点を修正。
 *                                       担当部署、担当者名の最大長処理を修正。
 *  2008/05/30    1.2   T.Ikehara        原価取得方法修正
 *  2008/06/03    1.3   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/12    1.4   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/24    1.5   T.Ikehara        数量、金額が0の場合に出力されるように修正
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/29    1.7   A.Shiina         T_TE080_BPO_770 指摘20対応
 *  2008/10/08    1.8   A.Shiina         T_S_524対応
 *  2008/10/08    1.9   A.Shiina         T_S_455対応
 *  2008/10/09    1.10  A.Shiina         T_S_422対応
 *  2008/11/11    1.11  N.Yoshida        I_S_511対応、移行データ検証不具合対応
 *  2008/11/19    1.12  N.Yoshida        移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#212対応
 *  2008/12/04    1.14  T.Mitaya         本番#379対応
 *  2009/01/16    1.15  N.Yoshida        本番#1031対応
 *  2009/06/22    1.16  Marushita        本番#1541対応
 *  2009/06/29    1.17  Marushita        本番#1554対応
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxcmn770007' ;   -- パッケージ名
--
  gv_raw_mat_cost_name    CONSTANT VARCHAR2(100) := '原料';
  gv_agein_cost_name      CONSTANT VARCHAR2(100) := '再製費';
  gv_material_cost_name   CONSTANT VARCHAR2(100) := '資材費';
  gv_pack_cost_name       CONSTANT VARCHAR2(100) := '包装費';
  gv_out_order_cost_name  CONSTANT VARCHAR2(100) := '外注加工費';
  gv_safekeep_cost_name   CONSTANT VARCHAR2(100) := '保管費';
  gv_other_cost_name      CONSTANT VARCHAR2(100) := 'その他経費';
  gv_spare1_name          CONSTANT VARCHAR2(100) := '予備１';
  gv_spare2_name          CONSTANT VARCHAR2(100) := '予備２';
  gv_spare3_name          CONSTANT VARCHAR2(100) := '予備３';
  gv_lookup_code          CONSTANT VARCHAR2(1)   := '2';
  gv_product              CONSTANT VARCHAR2(1)   := '5';
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_lang                 CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_y                    CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_new_acnt_div         CONSTANT VARCHAR2(21)  := 'XXCMN_NEW_ACCOUNT_DIV';
  gc_output_flag          CONSTANT VARCHAR2(30)  := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
--
  gv_expense_item_type    CONSTANT VARCHAR2(100) := 'XXPO_EXPENSE_ITEM_TYPE';  -- 費目区分
  gv_cmpntcls_type        CONSTANT VARCHAR2(100) := 'XXCMN_D19';               -- 原価内訳区分
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
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- アプリケーション（XXCMN）
  gc_param_name           CONSTANT VARCHAR2(10) := 'PARAM_NAME' ;
  gc_param_value          CONSTANT VARCHAR2(11) := 'PARAM_VALUE';
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '年' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '月' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '日' ;
  gc_char_y_format        CONSTANT VARCHAR2(20) := 'YYYYMM';
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
  gn_one                 CONSTANT NUMBER      := 1  ;
  gn_thousand            CONSTANT NUMBER      := 1000 ;
--
  ------------------------------
  -- 原価区分
  ------------------------------
  gc_cost_ac             CONSTANT VARCHAR2(1) := '0';--実際原価
  gc_cost_st             CONSTANT VARCHAR2(1) := '1';--標準原価
--
  ------------------------------
  -- ロット管理区分
  ------------------------------
  gc_lot_view            CONSTANT NUMBER      := 0;--ロット管理対象外
  gc_lot_ine             CONSTANT NUMBER      := 1;--ロット管理対象
--
  ------------------------------
  -- カーソル関連
  ------------------------------
  gc_kan                 CONSTANT VARCHAR2(1) := '1' ;
  gc_tou                 CONSTANT VARCHAR2(2) := '-1';
  gc_huku                CONSTANT VARCHAR2(1) := '2' ;
  gc_sizai               CONSTANT NUMBER      := 2   ;
  gc_gun                 CONSTANT VARCHAR2(1) := '3' ;
  gc_sla                 CONSTANT VARCHAR2(1) := '/' ;
  gc_sla_zero_one        CONSTANT VARCHAR2(3) := '/01' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data IS RECORD(
      proc_from            VARCHAR2(6)   -- 処理年月FROM
     ,proc_from_date_ch    VARCHAR2(10)  -- 処理年月FROM(日付文字列)
     ,proc_from_date       DATE          -- 処理年月FROM(日付) - 1(先月の末日)
     ,proc_to              VARCHAR2(6)   -- 処理年月TO
     ,proc_to_date_ch      VARCHAR2(10)  -- 処理年月TO(日付文字列)
     ,proc_to_date         DATE          -- 処理年月TO(日付) - 1(翌月の1日)
     ,prod_div             VARCHAR2(10)  -- 商品区分
     ,item_div             VARCHAR2(10)  -- 品目区分
     ,crowd_type           VARCHAR2(10)  -- 集計種別
     ,crowd_code           VARCHAR2(10)  -- 群コード
     ,acnt_crowd_code      VARCHAR2(10)  -- 経理群コード
    ) ;
--
    gr_param          rec_param_data ;          -- パラメータ受渡し用
--
  --ヘッダ用
  TYPE rec_header     IS RECORD(
      report_id            VARCHAR2(12)     -- 帳票ID
     ,exec_date            DATE             -- 実施日
     ,proc_from_char       VARCHAR2(10)                                 --処理年月FROM(YYYY年MM月)
     ,proc_to_char         VARCHAR2(10)                                 --処理年月TO  (YYYY年MM月)
     ,user_id              xxpo_per_all_people_f_v.person_id%TYPE       --担当者ID
     ,user_name            per_all_people_f.per_information18%TYPE      --担当者
     ,user_dept            xxcmn_locations_all.location_short_name%TYPE --部署
    ) ;
--
  gr_header           rec_header;
--
  -- 仕入取引明細表データ格納用レコード変数 --後で
  TYPE rec_data_type_dtl  IS RECORD(
       prod_div          xxcmn_lot_each_item_v.prod_div%TYPE   -- 商品区分
      ,prod_div_name     xxcmn_categories_v.description%TYPE   -- 商品区分名称
      ,item_div          xxcmn_lot_each_item_v.item_div%TYPE   -- 品目区分
      ,item_div_name     xxcmn_categories_v.description%TYPE   -- 品目区分名称
      ,gun_code          xxcmn_lot_each_item_v.crowd_code%TYPE -- 群コード
      ,item_id           ic_tran_pnd.item_id%TYPE              -- 品目ID
      ,item_code         xxcmn_lot_each_item_v.item_code%TYPE  -- 品目コード
      ,item_name         ic_item_mst_b.item_desc1%TYPE         -- 品目名称
-- 2008/11/29 v1.13 UPDATE START
      --,item_net          ic_item_mst_b.attribute12%TYPE        -- NET
-- 2008/11/29 v1.13 UPDATE END
      ,trans_qty         NUMBER                                -- 取引数量
      ,kan_qty           NUMBER                                -- 取引数量(完成品)
      ,tou_qty           NUMBER                                -- 取引数量(投入品)
      ,huku_qty          NUMBER                                -- 取引数量(副産物)
      ,actual_unit_price NUMBER                                -- 実際単価
      ,kan_jitu          NUMBER                                -- 実際単価×取引数量 完成品
      ,tou_jitu          NUMBER                                -- 実際単価×取引数量 投入品
      ,cmpnt_cost        NUMBER                                -- 標準原価(原料費)
      ,cmpnt_huku        NUMBER                                -- 標準原価(原料費)×取引数量 副産物
      ,cmpnt_kin         NUMBER                                -- 標準原価(原料費)×取引数量
      ,tou_kin           NUMBER                                -- 投入金額
      ,uti_kin           NUMBER                                -- 打込金額
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
  gr_rec tab_data_type_dtl;
--
  --キー割れ判断用
  TYPE rec_keybreak  IS RECORD(
       prod_div       VARCHAR2(200)  --商品区分
     , item_div       VARCHAR2(200)  --品目区分
     , crowd_high     VARCHAR2(200)  --大群
     , crowd_mid      VARCHAR2(200)  --中群
     , crowd_low      VARCHAR2(200)  --小群
     , crowd_dtl      VARCHAR2(200)  --詳群
    ) ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;  -- 営業単位
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
  ------------------------------
  -- ルックアップ用
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
--
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
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(G-1)
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
    lv_rowid       VARCHAR2(5000);            --ROWID
    lv_date        VARCHAR2(10);   --日付設定用
    lv_f_date      VARCHAR2(20);
    lv_e_date      VARCHAR2(20);
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
--
    -- 帳票出力値格納
    gr_header.report_id                   := 'XXCMN770007T'  ;     -- 帳票ID
    gr_header.exec_date                   := SYSDATE        ;      -- 実施日
--
    -- ====================================================
    -- 対象年月
    -- ====================================================
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      gr_param.proc_from , gc_char_y_format),gc_char_y_format);
--
    --日付型設定
    gr_param.proc_from_date_ch :=   SUBSTR(gr_param.proc_from,1,4) || gc_sla
                                 || SUBSTR(gr_param.proc_from,5,2) || gc_sla_zero_one;
    gr_param.proc_from_date :=  FND_DATE.STRING_TO_DATE( gr_param.proc_from_date_ch
                                                              , gc_char_d_format) - 1;
    --日付変換
    gr_header.proc_from_char :=   SUBSTR(lv_f_date,1,4) || gc_jp_yy
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
    gr_param.proc_to_date_ch :=   SUBSTR(gr_param.proc_to,1,4) || gc_sla
                               || SUBSTR(gr_param.proc_to,5,2) || gc_sla_zero_one;
    gr_param.proc_to_date   :=  ADD_MONTHS(FND_DATE.STRING_TO_DATE( gr_param.proc_to_date_ch
                                                              , gc_char_d_format), 1);
    -- 日付変換
    gr_header.proc_to_char   :=   SUBSTR(lv_e_date,1,4) || gc_jp_yy
                                      || SUBSTR(lv_e_date,5,2) || gc_jp_mm;
--
    IF (gr_param.proc_to_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              , 'APP-XXCMN-10035'
                                              , gc_param_name
                                              , gc_cap_to
                                              , gc_param_value
                                              , gr_param.proc_to ) ;
      RAISE get_value_expt ;
    END IF;
    gr_param.proc_to_date_ch := TO_CHAR(gr_param.proc_to_date,gc_char_d_format);
--
    -- ====================================================
    -- 営業単位取得
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXPO-00005'    ) ;
      RAISE get_value_expt ;
    END IF ;
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
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(G-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.取得レコード群
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
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));

--
    -- *** ローカル・変数 ***
    lv_date_from       VARCHAR2(10) ;
    lv_date_to         VARCHAR2(10) ;
    lv_syukei_select   VARCHAR2(32000) ;
    lv_syukei_from     VARCHAR2(32000) ;
    lv_syukei_where    VARCHAR2(32000) ;
    lv_syukei_group_by VARCHAR2(32000) ;
    lv_syukei          VARCHAR2(32000) ;
    lv_select          VARCHAR2(32000) ;
    lv_from            VARCHAR2(32000) ;
    lv_where           VARCHAR2(32000) ;
    lv_group_by        VARCHAR2(32000) ;
    lv_order_by        VARCHAR2(32000) ;
    lv_sql             VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    CURSOR get_data_cur01 IS
      SELECT /*+ leading (gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) use_nl(gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) */
             mcb1.segment1                     prod_div 
           , mct1.description                  prod_div_name
           , mcb2.segment1                     item_div 
           , mct2.description                  item_div_name
           , mcb3.segment1                     gun_code
           , gmd1.item_id                      item_id 
           , iimb2.item_no                     item_code 
           , ximb2.item_short_name             item_name 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(iimb2.attribute12,1)          item_net
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(itp.trans_qty , 0) * TO_NUMBER(xrpm.rcv_pay_div))       trans_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))                                            kan_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) tou_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) huku_qty 
-- 2008/11/19 v1.12 UPDATE START
           , SUM(NVL(DECODE(iimb.attribute15
--                           ,gc_cost_st,xcup.stnd_unit_price
                           ,gc_cost_st,xcup2.stnd_unit_price
                           ,gc_cost_ac,DECODE(iimb.lot_ctl
                                             ,gc_lot_ine,xlc.unit_ploce
--                                             ,gc_lot_view,xcup.stnd_unit_price)),0)) actual_unit_price
                                             ,gc_lot_view,xcup2.stnd_unit_price)),0)) actual_unit_price
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                                 * DECODE(iimb.attribute15
--                                                         ,gc_cost_st,xcup.stnd_unit_price
                                                         ,gc_cost_st,xcup2.stnd_unit_price
                                                         ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                           ,gc_lot_ine,xlc.unit_ploce
--                                                                           ,gc_lot_view,xcup.stnd_unit_price)))),0)
                                                                           ,gc_lot_view,xcup2.stnd_unit_price)))),0)
                )   kan_jitu 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                                 * DECODE(iimb.attribute15
--                                                         ,gc_cost_st,xcup.stnd_unit_price
                                                         ,gc_cost_st,xcup2.stnd_unit_price
                                                         ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                           ,gc_lot_ine,xlc.unit_ploce
--                                                                           ,gc_lot_view,xcup.stnd_unit_price)))),0)
                                                                           ,gc_lot_view,xcup2.stnd_unit_price)))),0)
                )   tou_jitu 
-- 2008/11/19 v1.12 UPDATE END
           --, SUM(NVL(xcup.stnd_unit_price , 0))                          cmpnt_cost 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(xcup.stnd_unit_price , 0)     cmpnt_cost
           , NVL(xcup.stnd_unit_price_gen , 0)     cmpnt_cost
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
-- 2008/11/29 v1.13 UPDATE START
-- 2008/11/19 v1.12 UPDATE START
                             -- * xcup2.stnd_unit_price)), 0)) cmpnt_huku 
                             * xcup2.stnd_unit_price_gen)), 0)) cmpnt_huku 
-- 2008/11/19 v1.12 UPDATE END
-- 2008/11/29 v1.13 UPDATE END
-- 2008/11/19 v1.12 UPDATE START
           --, SUM(NVL(xcup.stnd_unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)), 0)
-- 2008/11/29 v1.13 UPDATE START
           --, SUM(NVL(xcup.stnd_unit_price , 0) * NVL(DECODE(xrpm.line_type
           , SUM(NVL(xcup.stnd_unit_price_gen , 0) * NVL(DECODE(xrpm.line_type
-- 2008/11/29 v1.13 UPDATE END
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)
-- 2008/11/19 v1.12 UPDATE END
             ) cmpnt_kin 
           , SUM(NVL(CASE  -- 投入品で資材以外
                     WHEN xrpm.line_type =   gc_tou  
-- 2008/12/04 v1.14 UPDATE START
--                     AND  mcb2.segment1 <>   gc_sizai  
                     AND  mcb4.segment1 <>   gc_sizai  
-- 2008/12/04 v1.14 UPDATE END
-- 2009/06/29 ADD START
                     AND  NVL(xrpm.hit_in_div,'N') <> gc_y 
-- 2009/06/29 ADD END
                     THEN ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                        * DECODE(iimb.attribute15
-- 2008/11/19 v1.12 UPDATE START
--                                                ,gc_cost_st,xcup.stnd_unit_price
                                                ,gc_cost_st,xcup2.stnd_unit_price
                                                ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                  ,gc_lot_ine,xlc.unit_ploce
--                                                                  ,gc_lot_view,xcup.stnd_unit_price)))
                                                                  ,gc_lot_view,xcup2.stnd_unit_price)))
                     END  , 0))                                              tou_kin 
           , SUM(NVL(DECODE(xrpm.hit_in_div
                           ,gc_y, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                                               * DECODE(iimb.attribute15
--                                                       ,gc_cost_st,xcup.stnd_unit_price
                                                       ,gc_cost_st,xcup2.stnd_unit_price
                                                       ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                                         ,gc_lot_ine,xlc.unit_ploce
--                                                                         ,gc_lot_view,xcup.stnd_unit_price))),0),0)
                                                                         ,gc_lot_view,xcup2.stnd_unit_price))),0),0)
-- 2008/11/19 v1.12 UPDATE END
                ) uti_kin 
      FROM
            ic_tran_pnd              itp      --在庫トラン
           ,gmi_item_categories      gic1
           ,mtl_categories_b         mcb1
           ,mtl_categories_tl        mct1
           ,gmi_item_categories      gic2
           ,mtl_categories_b         mcb2
           ,mtl_categories_tl        mct2
           ,gmi_item_categories      gic3
           ,mtl_categories_b         mcb3
           ,ic_item_mst_b            iimb
           ,xxcmn_item_mst_b         ximb
           ,ic_item_mst_b            iimb2
           ,xxcmn_item_mst_b         ximb2
           ,xxcmn_lot_cost           xlc
           ,xxcmn_stnd_unit_price_v  xcup     --標準原価情報View
-- 2008/11/19 v1.12 ADD START
           ,xxcmn_stnd_unit_price_v  xcup2    --標準原価情報View
-- 2008/11/19 v1.12 ADD END
           ,gme_material_details     gmd1     -- 
-- 2009/06/29 ADD START
           ,gme_material_details     gmd4     -- 
-- 2009/06/29 ADD END
           ,gme_batch_header         gbh1     -- 
           ,gmd_routings_b           grb1     -- 
           ,xxcmn_rcv_pay_mst        xrpm
-- 2008/12/04 v1.14 ADD START
           ,gmi_item_categories      gic4
           ,mtl_categories_b         mcb4
-- 2008/12/04 v1.14 ADD END
      WHERE  itp.doc_type          = 'PROD'
      AND    itp.completed_ind     = 1
      AND    gmd1.attribute11     >= gr_param.proc_from_date_ch
      AND    gmd1.attribute11     <  gr_param.proc_to_date_ch
      AND    gic1.item_id          = gmd1.item_id
      AND    gic1.category_set_id  = cn_prod_class_id
      AND    mcb1.category_id      = gic1.category_id
      AND    mcb1.segment1         = gr_param.prod_div  --@@商品区分
      AND    mct1.category_id      = mcb1.category_id
      AND    mct1.language         = 'JA'
      AND    gic2.item_id          = gmd1.item_id
      AND    gic2.category_set_id  = cn_item_class_id
      AND    mcb2.category_id      = gic2.category_id
      AND    mcb2.segment1         = gr_param.item_div  --@@品目区分
      AND    mct2.category_id      = mcb2.category_id
      AND    mct2.language         = 'JA'
      AND    gic3.item_id          = gmd1.item_id
      AND    gic3.category_set_id  = cn_crowd_code_id
      AND    mcb3.category_id      = gic3.category_id
      AND    iimb.item_id          = itp.item_id
      AND    ximb.item_id          = iimb.item_id
      AND    itp.trans_date        BETWEEN ximb.start_date_active AND ximb.end_date_active
      AND    xlc.item_id(+)        = itp.item_id
      AND    xlc.lot_id(+)         = itp.lot_id
-- 2008/11/19 v1.12 UPDATE START
      AND    xcup.item_id(+)       = gmd1.item_id
      AND    itp.trans_date        BETWEEN NVL(xcup.start_date_active, FND_DATE.STRING_TO_DATE('1900/01/01 00:00:00', 'YYYY/MM/DD HH24:MI:SS'))
                                   AND NVL(xcup.end_date_active, FND_DATE.STRING_TO_DATE('9999/12/31 23:59:59', 'YYYY/MM/DD HH24:MI:SS'))
      AND    xcup2.item_id(+)      = itp.item_id
      AND    itp.trans_date        BETWEEN xcup2.start_date_active(+) AND xcup2.end_date_active(+) 
-- 2008/11/19 v1.12 UPDATE END
      AND    itp.doc_id            = gmd1.batch_id
-- 2009/01/16 v1.15 N.Yoshida mod start
--      AND    itp.doc_line          = gmd1.line_no
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    gbh1.batch_id         = gmd1.batch_id
      AND    grb1.routing_id       = gbh1.routing_id
      AND    xrpm.routing_class    = grb1.routing_class
      AND    gmd1.item_id          = iimb2.item_id
      AND    iimb2.item_id         = ximb2.item_id
      AND    itp.doc_type           = xrpm.doc_type
      AND    itp.line_type          = xrpm.line_type
-- 2008/12/04 v1.14 ADD START
      AND    itp.item_id = gic4.item_id
      AND    gic4.category_id = mcb4.category_id
      AND    gic4.category_set_id = cn_item_class_id
-- 2008/12/04 v1.14 ADD END
      --AND    gmd1.line_type         = xrpm.line_type
      AND    gmd1.line_type         = gc_kan
-- 2009/06/29 MOD START
--      AND    ( ( ( gmd1.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
--             OR ( xrpm.hit_in_div        = gmd1.attribute5 ) )
      AND    itp.doc_id            = gmd4.batch_id
      AND    itp.item_id           = gmd4.item_id
      AND    itp.line_type         = gmd4.line_type
      AND    itp.line_id           = gmd4.material_detail_id
      AND    ( ( ( gmd4.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
             OR ( xrpm.hit_in_div        = gmd4.attribute5 ) )
-- 2009/06/29 MOD END
      AND    xrpm.break_col_07       IS NOT NULL
      AND    ((xrpm.routing_class    <> '70')  --PTN A
             OR (xrpm.routing_class     = '70' --PTN B
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd2
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd2.batch_id   = gmd1.batch_id
                              AND    gmd2.line_no    = gmd1.line_no
                              AND    gmd2.line_type  = -1
                              AND    gic.item_id     = gmd2.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_origin))
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd3
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd3.batch_id   = gmd1.batch_id
                              AND    gmd3.line_no    = gmd1.line_no
                              AND    gmd3.line_type  = 1
                              AND    gic.item_id     = gmd3.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_ahead))
              ))
      GROUP BY 
               mcb1.segment1
             , mct1.description
             , mcb2.segment1
             , mct2.description
             , mcb3.segment1
             , gmd1.item_id
             , iimb2.item_no
             , ximb2.item_short_name
-- 2008/11/29 v1.13 UPDATE START
             --, iimb2.attribute12
-- 2008/11/29 v1.13 UPDATE END
             , xcup.stnd_unit_price_gen
      ORDER BY 
               mcb3.segment1
              ,iimb2.item_no
      ;
--
    CURSOR get_data_cur02 IS
      SELECT /*+ leading (gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) use_nl(gmd1 gic1 mcb1 gic2 mcb2 itp gbh1 grb1 xrpm) */
             mcb1.segment1                     prod_div 
           , mct1.description                  prod_div_name
           , mcb2.segment1                     item_div 
           , mct2.description                  item_div_name
           , mcb3.segment1                     gun_code
           , gmd1.item_id                      item_id 
           , iimb2.item_no                     item_code 
           , ximb2.item_short_name             item_name 
-- 2008/11/29 v1.13 UPDATE START
           --, NVL(iimb2.attribute12,1)          item_net
-- 2008/11/29 v1.13 UPDATE END
           , SUM(NVL(itp.trans_qty , 0) * TO_NUMBER(xrpm.rcv_pay_div))       trans_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))                                            kan_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) tou_qty 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0)) huku_qty 
           , SUM(NVL(DECODE(iimb.attribute15
                           ,gc_cost_st
                           ,(SELECT NVL(SUM(xpl.unit_price),0)
                             FROM   xxpo_price_headers    xph
                                   ,xxpo_price_lines      xpl
                                   ,xxcmn_lookup_values_v xlvv1
                                   ,xxcmn_lookup_values_v xlvv2
                             WHERE  xph.price_header_id   = xpl.price_header_id
                             AND    xpl.expense_item_type = xlvv1.attribute1
                             AND    xlvv1.attribute2      = xlvv2.lookup_code
                             AND    xph.price_type        = gv_lookup_code
                             AND    xph.item_code         = iimb.item_no
                             -- 2009/06/22 ADD START
                             AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                             -- 2009/06/22 ADD END
                             AND    xlvv1.lookup_type     = gv_expense_item_type
                             AND    xlvv2.lookup_type     = gv_cmpntcls_type
                             AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                              ,gv_agein_cost_name
                                                              ,gv_material_cost_name
                                                              ,gv_pack_cost_name
                                                              ,gv_out_order_cost_name
                                                              ,gv_safekeep_cost_name
                                                              ,gv_other_cost_name
                                                              ,gv_spare1_name
                                                              ,gv_spare2_name
                                                              ,gv_spare3_name))
                           ,gc_cost_ac,DECODE(iimb.lot_ctl
                                             ,gc_lot_ine,xlc.unit_ploce
                                             ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                             )),0)) actual_unit_price 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_kan, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                          ,(SELECT NVL(SUM(xpl.unit_price),0)
                                            FROM   xxpo_price_headers    xph
                                                  ,xxpo_price_lines      xpl
                                                  ,xxcmn_lookup_values_v xlvv1
                                                  ,xxcmn_lookup_values_v xlvv2
                                            WHERE  xph.price_header_id   = xpl.price_header_id
                                            AND    xpl.expense_item_type = xlvv1.attribute1
                                            AND    xlvv1.attribute2      = xlvv2.lookup_code
                                            AND    xph.price_type        = gv_lookup_code
                                            AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                            AND    xlvv1.lookup_type     = gv_expense_item_type
                                            AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                            AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                             ,gv_agein_cost_name
                                                                             ,gv_material_cost_name
                                                                             ,gv_pack_cost_name
                                                                             ,gv_out_order_cost_name
                                                                             ,gv_safekeep_cost_name
                                                                             ,gv_other_cost_name
                                                                             ,gv_spare1_name
                                                                             ,gv_spare2_name
                                                                             ,gv_spare3_name))
                                                       )))),0))   kan_jitu 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_tou, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                          ,(SELECT NVL(SUM(xpl.unit_price),0)
                                            FROM   xxpo_price_headers    xph
                                                  ,xxpo_price_lines      xpl
                                                  ,xxcmn_lookup_values_v xlvv1
                                                  ,xxcmn_lookup_values_v xlvv2
                                            WHERE  xph.price_header_id   = xpl.price_header_id
                                            AND    xpl.expense_item_type = xlvv1.attribute1
                                            AND    xlvv1.attribute2      = xlvv2.lookup_code
                                            AND    xph.price_type        = gv_lookup_code
                                            AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                            AND    xlvv1.lookup_type     = gv_expense_item_type
                                            AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                            AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                              ,gv_spare1_name
                                                                              ,gv_spare2_name
                                                                              ,gv_spare3_name))
                                                       )))),0))   tou_jitu 
-- 2009/01/16 v1.15 N.Yoshida mod start
--           , SUM(NVL((SELECT NVL(SUM(xpl.unit_price),0)
           -- 標準原価を一つだけ取得する為にMAX関数を使用
           , MAX(NVL((SELECT NVL(SUM(xpl.unit_price),0)
-- 2009/01/16 v1.15 N.Yoshida mod end
                      FROM   xxpo_price_headers    xph
                            ,xxpo_price_lines      xpl
                            ,xxcmn_lookup_values_v xlvv1
                            ,xxcmn_lookup_values_v xlvv2
                      WHERE  xph.price_header_id   = xpl.price_header_id
                      AND    xpl.expense_item_type = xlvv1.attribute1
                      AND    xlvv1.attribute2      = xlvv2.lookup_code
                      AND    xph.price_type        = gv_lookup_code
-- 2009/01/16 v1.15 N.Yoshida mod start
--                      AND    xph.item_code         = iimb.item_no
                      AND    xph.item_code         = iimb2.item_no
-- 2009/01/16 v1.15 N.Yoshida mod end
                      -- 2009/06/22 ADD START
                      AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                      -- 2009/06/22 ADD END
                      AND    xlvv1.lookup_type     = gv_expense_item_type
                      AND    xlvv2.lookup_type     = gv_cmpntcls_type
                      AND    xlvv2.meaning         = gv_raw_mat_cost_name)
             , 0))                          cmpnt_cost 
           , SUM(NVL(DECODE(xrpm.line_type
                           ,gc_huku, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * (SELECT NVL(SUM(xpl.unit_price),0)
                                FROM   xxpo_price_headers    xph
                                      ,xxpo_price_lines      xpl
                                      ,xxcmn_lookup_values_v xlvv1
                                      ,xxcmn_lookup_values_v xlvv2
                                WHERE  xph.price_header_id   = xpl.price_header_id
                                AND    xpl.expense_item_type = xlvv1.attribute1
                                AND    xlvv1.attribute2      = xlvv2.lookup_code
                                AND    xph.price_type        = gv_lookup_code
                                AND    xph.item_code         = iimb.item_no
                                -- 2009/06/22 ADD START
                                AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                -- 2009/06/22 ADD END
                                AND    xlvv1.lookup_type     = gv_expense_item_type
                                AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                AND    xlvv2.meaning         = gv_raw_mat_cost_name)
                           )), 0)) cmpnt_huku 
           , SUM(ROUND(NVL((SELECT NVL(SUM(xpl.unit_price),0)
                      FROM   xxpo_price_headers    xph
                            ,xxpo_price_lines      xpl
                            ,xxcmn_lookup_values_v xlvv1
                            ,xxcmn_lookup_values_v xlvv2
                      WHERE  xph.price_header_id   = xpl.price_header_id
                      AND    xpl.expense_item_type = xlvv1.attribute1
                      AND    xlvv1.attribute2      = xlvv2.lookup_code
                      AND    xph.price_type        = gv_lookup_code
-- 2009/01/16 v1.15 N.Yoshida mod start
--                      AND    xph.item_code         = iimb.item_no
                      AND    xph.item_code         = iimb2.item_no
-- 2009/01/16 v1.15 N.Yoshida mod end
                      -- 2009/06/22 ADD START
                      AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                      -- 2009/06/22 ADD END
                      AND    xlvv1.lookup_type     = gv_expense_item_type
                      AND    xlvv2.lookup_type     = gv_cmpntcls_type
                      AND    xlvv2.meaning         = gv_raw_mat_cost_name),0)
             * NVL(DECODE(xrpm.line_type
                           ,gc_kan, itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
                           ), 0))) cmpnt_kin 
           , SUM(NVL(CASE  -- 投入品で資材以外
                     WHEN xrpm.line_type =   gc_tou  
-- 2009/01/16 v1.15 N.Yoshida mod start
--                     AND  mcb2.segment1 <>   gc_sizai  
                     AND  mcb4.segment1 <>   gc_sizai  
-- 2009/01/16 v1.15 N.Yoshida mod end
-- 2009/06/29 ADD START
                     AND  NVL(xrpm.hit_in_div,'N') <> gc_y 
-- 2009/06/29 ADD END
                     THEN ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                       * DECODE(iimb.attribute15
                               ,gc_cost_st
                               ,(SELECT NVL(SUM(xpl.unit_price),0)
                                 FROM   xxpo_price_headers    xph
                                       ,xxpo_price_lines      xpl
                                       ,xxcmn_lookup_values_v xlvv1
                                       ,xxcmn_lookup_values_v xlvv2
                                 WHERE  xph.price_header_id   = xpl.price_header_id
                                 AND    xpl.expense_item_type = xlvv1.attribute1
                                 AND    xlvv1.attribute2      = xlvv2.lookup_code
                                 AND    xph.price_type        = gv_lookup_code
                                 AND    xph.item_code         = iimb.item_no
                                 -- 2009/06/22 ADD START
                                 AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                 -- 2009/06/22 ADD END
                                 AND    xlvv1.lookup_type     = gv_expense_item_type
                                 AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                 AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                  ,gv_agein_cost_name
                                                                  ,gv_material_cost_name
                                                                  ,gv_pack_cost_name
                                                                  ,gv_out_order_cost_name
                                                                  ,gv_safekeep_cost_name
                                                                  ,gv_other_cost_name
                                                                  ,gv_spare1_name
                                                                  ,gv_spare2_name
                                                                  ,gv_spare3_name))
                               ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                 ,gc_lot_ine,xlc.unit_ploce
                                                 ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                                 )))
                     END  , 0))                                              tou_kin 
           , SUM(NVL(DECODE(xrpm.hit_in_div
                           ,gc_y, ROUND((itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))
                             * DECODE(iimb.attribute15
                                     ,gc_cost_st
                                     ,(SELECT NVL(SUM(xpl.unit_price),0)
                                       FROM   xxpo_price_headers    xph
                                             ,xxpo_price_lines      xpl
                                             ,xxcmn_lookup_values_v xlvv1
                                             ,xxcmn_lookup_values_v xlvv2
                                       WHERE  xph.price_header_id   = xpl.price_header_id
                                       AND    xpl.expense_item_type = xlvv1.attribute1
                                       AND    xlvv1.attribute2      = xlvv2.lookup_code
                                       AND    xph.price_type        = gv_lookup_code
                                       AND    xph.item_code         = iimb.item_no
                                       -- 2009/06/22 ADD START
                                       AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                       -- 2009/06/22 ADD END
                                       AND    xlvv1.lookup_type     = gv_expense_item_type
                                       AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                       AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                        ,gv_agein_cost_name
                                                                        ,gv_material_cost_name
                                                                        ,gv_pack_cost_name
                                                                        ,gv_out_order_cost_name
                                                                        ,gv_safekeep_cost_name
                                                                        ,gv_other_cost_name
                                                                        ,gv_spare1_name
                                                                        ,gv_spare2_name
                                                                        ,gv_spare3_name))
                                     ,gc_cost_ac,DECODE(iimb.lot_ctl
                                                       ,gc_lot_ine,xlc.unit_ploce
                                                       ,gc_lot_view
                                         ,(SELECT NVL(SUM(xpl.unit_price),0)
                                           FROM   xxpo_price_headers    xph
                                                 ,xxpo_price_lines      xpl
                                                 ,xxcmn_lookup_values_v xlvv1
                                                 ,xxcmn_lookup_values_v xlvv2
                                           WHERE  xph.price_header_id   = xpl.price_header_id
                                           AND    xpl.expense_item_type = xlvv1.attribute1
                                           AND    xlvv1.attribute2      = xlvv2.lookup_code
                                           AND    xph.price_type        = gv_lookup_code
                                           AND    xph.item_code         = iimb.item_no
                                           -- 2009/06/22 ADD START
                                           AND    itp.trans_date BETWEEN xph.start_date_active AND xph.end_date_active
                                           -- 2009/06/22 ADD END
                                           AND    xlvv1.lookup_type     = gv_expense_item_type
                                           AND    xlvv2.lookup_type     = gv_cmpntcls_type
                                           AND    xlvv2.meaning         IN ( gv_raw_mat_cost_name
                                                                            ,gv_agein_cost_name
                                                                            ,gv_material_cost_name
                                                                            ,gv_pack_cost_name
                                                                            ,gv_out_order_cost_name
                                                                            ,gv_safekeep_cost_name
                                                                            ,gv_other_cost_name
                                                                            ,gv_spare1_name
                                                                            ,gv_spare2_name
                                                                            ,gv_spare3_name))
                                                       ))),0),0)
                ) uti_kin 
      FROM
            ic_tran_pnd              itp      --在庫トラン
           ,gmi_item_categories      gic1
           ,mtl_categories_b         mcb1
           ,mtl_categories_tl        mct1
           ,gmi_item_categories      gic2
           ,mtl_categories_b         mcb2
           ,mtl_categories_tl        mct2
           ,gmi_item_categories      gic3
           ,mtl_categories_b         mcb3
-- 2009/01/16 v1.15 N.Yoshida mod start
           ,gmi_item_categories      gic4
           ,mtl_categories_b         mcb4
-- 2009/01/16 v1.15 N.Yoshida mod end
           ,ic_item_mst_b            iimb
           ,xxcmn_item_mst_b         ximb
           ,ic_item_mst_b            iimb2
           ,xxcmn_item_mst_b         ximb2
           ,xxcmn_lot_cost           xlc
           ,gme_material_details     gmd1     -- 
-- 2009/06/29 ADD START
           ,gme_material_details     gmd4     -- 
-- 2009/06/29 ADD END
           ,gme_batch_header         gbh1     -- 
           ,gmd_routings_b           grb1     -- 
           ,xxcmn_rcv_pay_mst xrpm
      WHERE  itp.doc_type          = 'PROD'
      AND    itp.completed_ind     = 1
      AND    gmd1.attribute11     >= gr_param.proc_from_date_ch
      AND    gmd1.attribute11     <  gr_param.proc_to_date_ch
      AND    gic1.item_id          = gmd1.item_id
      AND    gic1.category_set_id  = cn_prod_class_id
      AND    mcb1.category_id      = gic1.category_id
      AND    mcb1.segment1         = gr_param.prod_div  --@@商品区分
      AND    mct1.category_id      = mcb1.category_id
      AND    mct1.language         = 'JA'
      AND    gic2.item_id          = gmd1.item_id
      AND    gic2.category_set_id  = cn_item_class_id
      AND    mcb2.category_id      = gic2.category_id
      AND    mcb2.segment1         = gr_param.item_div  --@@品目区分
      AND    mct2.category_id      = mcb2.category_id
      AND    mct2.language         = 'JA'
      AND    gic3.item_id          = gmd1.item_id
      AND    gic3.category_set_id  = cn_crowd_code_id
      AND    mcb3.category_id      = gic3.category_id
-- 2009/01/16 v1.15 N.Yoshida mod start
      AND    gic4.item_id          = itp.item_id
      AND    gic4.category_set_id  = cn_item_class_id
      AND    mcb4.category_id      = gic4.category_id
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    iimb.item_id          = itp.item_id
      AND    ximb.item_id          = iimb.item_id
      AND    itp.trans_date        BETWEEN ximb.start_date_active AND ximb.end_date_active
      AND    xlc.item_id(+)        = itp.item_id
      AND    xlc.lot_id(+)         = itp.lot_id
      AND    itp.doc_id            = gmd1.batch_id
-- 2009/01/16 v1.15 N.Yoshida mod start
--      AND    itp.doc_line          = gmd1.line_no
-- 2009/01/16 v1.15 N.Yoshida mod end
      AND    gbh1.batch_id         = gmd1.batch_id
      AND    grb1.routing_id       = gbh1.routing_id
      AND    xrpm.routing_class    = grb1.routing_class
      AND    itp.doc_type           = xrpm.doc_type
      AND    itp.line_type          = xrpm.line_type
      --AND    gmd1.line_type         = xrpm.line_type
      AND    gmd1.item_id          = iimb2.item_id
      AND    iimb2.item_id         = ximb2.item_id
      AND    gmd1.line_type        = gc_kan
-- 2009/06/29 MOD START
--      AND    ( ( ( gmd1.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
--             OR ( xrpm.hit_in_div        = gmd1.attribute5 ) )
      AND    itp.doc_id            = gmd4.batch_id
      AND    itp.item_id           = gmd4.item_id
      AND    itp.line_type         = gmd4.line_type
      AND    itp.line_id           = gmd4.material_detail_id
      AND    ( ( ( gmd4.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )
             OR ( xrpm.hit_in_div        = gmd4.attribute5 ) )
-- 2009/06/29 MOD END
      AND    xrpm.break_col_07       IS NOT NULL
      AND    ((xrpm.routing_class    <> '70')  --PTN A
             OR (xrpm.routing_class     = '70' --PTN B
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd2
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd2.batch_id   = gmd1.batch_id
                              AND    gmd2.line_no    = gmd1.line_no
                              AND    gmd2.line_type  = -1
                              AND    gic.item_id     = gmd2.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_origin))
                 AND (EXISTS (SELECT 1
                              FROM   gme_material_details gmd3
                                    ,gmi_item_categories  gic
                                    ,mtl_categories_b     mcb
                              WHERE  gmd3.batch_id   = gmd1.batch_id
                              AND    gmd3.line_no    = gmd1.line_no
                              AND    gmd3.line_type  = 1
                              AND    gic.item_id     = gmd3.item_id
                              AND    gic.category_set_id = cn_item_class_id
                              AND    gic.category_id = mcb.category_id
                              AND    mcb.segment1    = xrpm.item_div_ahead))
              ))
      GROUP BY 
               mcb1.segment1
             , mct1.description
             , mcb2.segment1
             , mct2.description
             , mcb3.segment1
             , gmd1.item_id
             , iimb2.item_no
             , ximb2.item_short_name
-- 2008/11/29 v1.13 UPDATE START
             --, iimb2.attribute12
-- 2008/11/29 v1.13 UPDATE END
      ORDER BY 
               mcb3.segment1
              ,iimb2.item_no
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--

    -- ====================================================
    -- データ抽出
    -- ====================================================
--
   IF (gr_param.item_div = gv_product) THEN
     OPEN  get_data_cur01;
     FETCH get_data_cur01 BULK COLLECT INTO ot_data_rec;
     CLOSE get_data_cur01;
   ELSE
     OPEN  get_data_cur02;
     FETCH get_data_cur02 BULK COLLECT INTO ot_data_rec;
     CLOSE get_data_cur02;
   END IF;
--
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(G-2)
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
    lc_break                CONSTANT VARCHAR2(100) := '**' ;
--
    lc_depth_crowd_dtl      CONSTANT NUMBER :=  3;  -- 詳群
    lc_depth_crowd_low      CONSTANT NUMBER :=  5;  -- 小群
    lc_depth_crowd_mid      CONSTANT NUMBER :=  7;  -- 中群
    lc_depth_crowd_high     CONSTANT NUMBER :=  9;  -- 大群
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
    ln_std_cost             NUMBER DEFAULT 0;         -- 標準原価(原料費)
    ln_dekikin              NUMBER DEFAULT 0;         -- 出来高金額
    ln_dekitan              NUMBER DEFAULT 0;         -- 出来高単価
    ln_sai_tan              NUMBER DEFAULT 0;         -- 単価差異
    ln_sai_kin              NUMBER DEFAULT 0;         -- 原価差異
    --総合計用
    ln_sum_qty              NUMBER DEFAULT 0;         -- 出来高
    ln_sum_std_cost         NUMBER DEFAULT 0;         -- 標準原価
    ln_sum_std_kin          NUMBER DEFAULT 0;         -- 標準金額
    ln_sum_tou              NUMBER DEFAULT 0;         -- 投入金額
    ln_sum_uti              NUMBER DEFAULT 0;         -- 打込金額
    ln_sum_huku             NUMBER DEFAULT 0;         -- 副産物金額
    ln_sum_dekikin          NUMBER DEFAULT 0;         -- 出来高金額
    ln_sum_dekitan          NUMBER DEFAULT 0;         -- 出来高単価
    ln_sum_sai_tan          NUMBER DEFAULT 0;         -- 単価差異
    ln_sum_sai_kin          NUMBER DEFAULT 0;         -- 原価差異
--
    ln_loop_index           NUMBER DEFAULT 0;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
--
    ---------------------
    -- XMLタグ挿入処理
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       --   タグタイプ  T:タグ
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
      -- *** ローカル変数 ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULLの場合タグを書かない対応(数値項目を想定)
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
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- ヘッダーデータ抽出・出力処理
    -- =====================================================
    -- ヘッダー開始タグ
    prc_set_xml('T', 'user_info');
--
    -- 帳票ＩＤ
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
    -- 抽出from
    prc_set_xml('D', 'process_year_month_from', gr_header.proc_from_char);
--
    -- 抽出to
    prc_set_xml('D', 'process_year_month_to', gr_header.proc_to_char);
--
    -- ヘッダー終了タグ
    prc_set_xml('T','/user_info');
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
    prc_set_xml('D', 'arti_div_code', gt_main_data(1).prod_div);
    prc_set_xml('D', 'arti_div_name', gt_main_data(1).prod_div_name, 20);
    --品目区分
    prc_set_xml('T', 'lg_item_div');
    prc_set_xml('T', 'g_item_div');
    prc_set_xml('D', 'item_div_code', gt_main_data(1).item_div);
    prc_set_xml('D', 'item_div_name', gt_main_data(1).item_div_name, 20);
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      --表示用変数初期化
      ln_std_cost := 0;
      ln_dekikin  := 0;
      ln_dekitan  := 0;
      ln_sai_tan  := 0;
      ln_sai_kin  := 0;
--
      --キー割れ判断用変数初期化
      ln_group_depth     := 0;
      lr_now_key.prod_div    := gt_main_data(ln_loop_index).prod_div;
      lr_now_key.item_div    := lr_now_key.prod_div || gt_main_data(ln_loop_index).item_div;
      lr_now_key.crowd_high  := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1);
      lr_now_key.crowd_mid   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2);
      lr_now_key.crowd_low   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3);
      lr_now_key.crowd_dtl   := SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4);
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
                -- 品目区分
                IF ( NVL(lr_now_key.item_div, lc_break ) <> lr_pre_key.item_div ) THEN
                  prc_set_xml('T', '/lg_crowd_high');
                  ln_group_depth := lc_depth_item_div;
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
      IF (ln_group_depth >= lc_depth_item_div) THEN
        -- 受払区分
        prc_set_xml('T', 'lg_crowd_high');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_high) THEN
        -- 大群
        prc_set_xml('T', 'g_crowd_high');
        prc_set_xml('D', 'crowd_high'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 1));
        prc_set_xml('T', 'lg_crowd_mid');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_mid) THEN
        -- 中群
        prc_set_xml('T', 'g_crowd_mid');
        prc_set_xml('D', 'crowd_mid'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 2));
        prc_set_xml('T', 'lg_crowd_low');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_low) THEN
        -- 小群
        prc_set_xml('T', 'g_crowd_low');
        prc_set_xml('D', 'crowd_low'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 3));
        prc_set_xml('T', 'lg_crowd_dtl');
      END IF;
--
      IF (ln_group_depth >= lc_depth_crowd_dtl) THEN
        -- 詳群
        prc_set_xml('T', 'g_crowd_dtl');
        prc_set_xml('D', 'crowd_dtl'
                                 , SUBSTR(gt_main_data(ln_loop_index).gun_code , 1, 4));
        prc_set_xml('T', 'lg_item');
      END IF;
--
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      --明細開始
      prc_set_xml('T', 'g_item');
--
      --品目
      prc_set_xml('D', 'item_code', gt_main_data(ln_loop_index).item_code);
      prc_set_xml('D', 'item_name', gt_main_data(ln_loop_index).item_name, 20);
--
      --出来高
      --prc_set_xml('D', 'quantity', gt_main_data(ln_loop_index).trans_qty);
      prc_set_xml('D', 'quantity', gt_main_data(ln_loop_index).kan_qty);
--
      --標準原価
      IF (gt_main_data(ln_loop_index).trans_qty != 0) THEN
-- 2008/11/19 v1.12 UPDATE START
--        ln_std_cost :=  gt_main_data(ln_loop_index).cmpnt_kin
--                      / gt_main_data(ln_loop_index).trans_qty;
          ln_std_cost :=  gt_main_data(ln_loop_index).cmpnt_cost;
-- 2008/11/19 v1.12 UPDATE END
      END IF;
      prc_set_xml('D', 'standard_cost', ln_std_cost);
--
      --標準金額
      prc_set_xml('D', 'standard_amount', gt_main_data(ln_loop_index).cmpnt_kin);
--
      --投入金額
      prc_set_xml('D', 'turn_amount', gt_main_data(ln_loop_index).tou_kin);
--
      --打込金額
      prc_set_xml('D', 'hit_amount', gt_main_data(ln_loop_index).uti_kin);
--
      --副産物金額
      prc_set_xml('D', 'by_product_amount', gt_main_data(ln_loop_index).cmpnt_huku);
--
      --出来高金額
      ln_dekikin :=  gt_main_data(ln_loop_index).tou_kin
-- 2008/12/04 v1.14 DELETE START
--                   + gt_main_data(ln_loop_index).uti_kin
-- 2008/12/04 v1.14 DELETE END
-- 2009/01/16 v1.15 ADD START
                   + gt_main_data(ln_loop_index).uti_kin
-- 2009/01/16 v1.15 ADD END
                   - gt_main_data(ln_loop_index).cmpnt_huku;
      prc_set_xml('D', 'piece_amount', ln_dekikin);
--
      --出来高単価
      IF (gt_main_data(ln_loop_index).trans_qty != 0 ) THEN
        --ln_dekitan := ln_dekikin / gt_main_data(ln_loop_index).trans_qty ;
-- 2008/11/29 v1.13 UPDATE START
        --ln_dekitan := ln_dekikin / (gt_main_data(ln_loop_index).kan_qty * gt_main_data(ln_loop_index).item_net / gn_thousand) ;
        ln_dekitan := ln_dekikin / gt_main_data(ln_loop_index).kan_qty ;
-- 2008/11/29 v1.13 UPDATE END
      END IF;
      prc_set_xml('D', 'piece_price', ln_dekitan);
--
      --単価差異
      ln_sai_tan := ln_std_cost - ln_dekitan;
      prc_set_xml('D', 'difference_price', ln_sai_tan);
--
      --原価差異
      ln_sai_kin :=  gt_main_data(ln_loop_index).cmpnt_kin - ln_dekikin;
      prc_set_xml('D', 'difference_amount', ln_sai_kin);
--
      -- 明細１行終了
      prc_set_xml('T', '/g_item');
--
--
      --事後処理
      lr_pre_key := lr_now_key;
--
      --合計加算
-- 2008/11/19 v1.12 UPDATE START
--      ln_sum_qty      := ln_sum_qty      + gt_main_data(ln_loop_index).trans_qty;
      ln_sum_qty      := ln_sum_qty      + gt_main_data(ln_loop_index).kan_qty;
-- 2008/11/19 v1.12 UPDATE END
      ln_sum_std_cost := ln_sum_std_cost + ln_std_cost;
      ln_sum_std_kin  := ln_sum_std_kin  + gt_main_data(ln_loop_index).cmpnt_kin;
      ln_sum_tou      := ln_sum_tou      + gt_main_data(ln_loop_index).tou_kin;
      ln_sum_uti      := ln_sum_uti      + gt_main_data(ln_loop_index).uti_kin;
      ln_sum_huku     := ln_sum_huku     + gt_main_data(ln_loop_index).cmpnt_huku;
      ln_sum_dekikin  := ln_sum_dekikin  + ln_dekikin;
      ln_sum_dekitan  := ln_sum_dekitan  + ln_dekitan;
      ln_sum_sai_tan  := ln_sum_sai_tan  + ln_sai_tan;
      ln_sum_sai_kin  := ln_sum_sai_kin  + ln_sai_kin;
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
    prc_set_xml('D', 'switch', 1);
    prc_set_xml('N', 'sum_quantity', ln_sum_qty);
    prc_set_xml('N', 'sum_standard_cost', ln_sum_std_cost);
    prc_set_xml('N', 'sum_standard_amount', ln_sum_std_kin);
    prc_set_xml('N', 'sum_turn_amount', ln_sum_tou);
    prc_set_xml('N', 'sum_hit_amount', ln_sum_uti);
    prc_set_xml('N', 'sum_by_product_amount', ln_sum_huku);
    prc_set_xml('N', 'sum_piece_amount', ln_sum_dekikin);
    prc_set_xml('N', 'sum_piece_price', ln_sum_dekitan);
    prc_set_xml('N', 'sum_difference_price', ln_sum_sai_tan);
    prc_set_xml('N', 'sum_difference_amount', ln_sum_sai_kin);
--
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
                                             ,'APP-XXCMN-10122'  ) ;
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
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月TO
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
     ,ov_errbuf          OUT   VARCHAR2   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         OUT   VARCHAR2   -- リターン・コード             --# 固定 #
     ,ov_errmsg          OUT   VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  固定部 END   ############################
--
--
    -- 入力パラメータ保持
    gr_param.proc_from       := iv_proc_from      ;-- 処理年月FROM
    gr_param.proc_to         := iv_proc_to        ;-- 処理年月TO
    gr_param.prod_div        := iv_prod_div       ;-- 商品区分
    gr_param.item_div        := iv_item_div       ;-- 品目区分
    gr_param.crowd_type      := iv_crowd_type     ;-- 集計種別
    gr_param.crowd_code      := iv_crowd_code     ;-- 群コード
    gr_param.acnt_crowd_code := iv_acnt_crowd_code;-- 経理群コード
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
    -- ＸＭＬ出力
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月TO
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
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
    submain(
        iv_proc_from       => iv_proc_from
       ,iv_proc_to         => iv_proc_to
       ,iv_prod_div        => iv_prod_div
       ,iv_item_div        => iv_item_div
       ,iv_crowd_type      => iv_crowd_type
       ,iv_crowd_code      => iv_crowd_code
       ,iv_acnt_crowd_code => iv_acnt_crowd_code
       ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxcmn770007cp ;
/