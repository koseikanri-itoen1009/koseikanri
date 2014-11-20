CREATE OR REPLACE PACKAGE BODY xxcmn770026c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026c(body)
 * Description      : 出庫実績表
 * MD.050/070       : 月次〆処理(経理)Issue1.0 (T_MD050_BPO_770)
 *                    月次〆処理(経理)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(F-1)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(F-1)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(F-2)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Y.Itou           新規作成
 *  2008/05/16    1.1   T.Endou          不具合ID:77F-09,10対応
 *                                       77F-09 処理年月パラYYYYM入力対応
 *                                       77F-10 担当部署、担当者名の最大文字数制限の修正
 *  2008/05/16    1.2   T.Endou          実際原価取得方法の変更
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
  gv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCMN770026C' ; -- パッケージ名
  gv_print_name               CONSTANT VARCHAR2(20) := '出庫実績表' ;   -- 帳票名
--
  ------------------------------
  -- 集計グループ
  ------------------------------
  gc_party_sum_desc           CONSTANT VARCHAR2(16) := '出荷先計';
  gc_whse_sum_desc            CONSTANT VARCHAR2(16) := '倉庫計';
  gc_article_div_sum_name     CONSTANT VARCHAR2(16) := '品目区分総計';
  gc_result_post_sum_name     CONSTANT VARCHAR2(16) := '成績部署計';
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_name_prod_div    CONSTANT VARCHAR2(20) := '商品区分' ;
  gc_cat_set_name_item_div    CONSTANT VARCHAR2(20) := '品目区分' ;
  gc_cat_set_name_crowd       CONSTANT VARCHAR2(20) := '群コード' ;
  gc_cat_set_name_acnt_crowd  CONSTANT VARCHAR2(20) := '経理部用群コード' ;
--
  ------------------------------
  -- 入力パラメータ
  ------------------------------
  gc_param_all_code           CONSTANT VARCHAR2(20) := 'ALL' ;
  gc_param_all_name           CONSTANT VARCHAR2(20) := '集計無し' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application              CONSTANT VARCHAR2(5)  := 'XXCMN' ;       -- アプリケーション
  gc_crowd_type_3             CONSTANT VARCHAR2(1)  := '3' ;           -- 郡種別：郡コード
  gc_crowd_type_4             CONSTANT VARCHAR2(1)  := '4' ;           -- 郡種別：経理郡コード
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_ym_format           CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format            CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- クイックコード・タイプ名
  ------------------------------
  gc_xxcmn_new_acc_div        CONSTANT VARCHAR2(30) := 'XXCMN_NEW_ACCOUNT_DIV';
--
  -- 原価区分
  gc_cost_ac                  CONSTANT VARCHAR2(1) := '0'; --実際原価
  gc_cost_st                  CONSTANT VARCHAR2(1) := '1'; --標準原価
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : 処理年月FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : 処理年月TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : 受払区分
   ,rcv_pay_div_name          VARCHAR2(20)      --    : 受払区分名
   ,prod_div                  VARCHAR2(1)       -- 04 : 商品区分
   ,prod_div_name             VARCHAR2(20)      --    : 商品区分名
   ,item_div                  VARCHAR2(1)       -- 05 : 品目区分
   ,item_div_name             VARCHAR2(20)      --    : 品目区分名
   ,result_post               VARCHAR2(4)       -- 06 : 成績部署
   ,result_post_name          VARCHAR2(20)      --    : 成績部署名
   ,whse_code                 VARCHAR2(4)       -- 07 : 倉庫コード
   ,whse_name                 VARCHAR2(20)      --    : 倉庫名
   ,party_code                VARCHAR2(4)       -- 08 : 出荷先コード
   ,party_name                VARCHAR2(20)      --    : 出荷先名
   ,crowd_type                VARCHAR2(1)       -- 09 : 郡種別
   ,crowd_code                VARCHAR2(4)       -- 10 : 郡コード
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : 経理群コード
   ,output_type               VARCHAR2(20)      -- 12 : 出力種別
  ) ;
--
  -- 出荷実績表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
    group1_code               VARCHAR2(5)                         -- [集計1]コード
   ,group2_code               VARCHAR2(5)                         -- [集計2]コード
   ,group3_code               VARCHAR2(5)                         -- [集計3]コード
   ,group4_code               VARCHAR2(5)                         -- [集計4]コード
   ,group5_code               VARCHAR2(4)                         -- [集計5]集計郡コード
   ,req_item_code             ic_item_mst_b.item_no%TYPE          -- 出荷品目コード
   ,item_code                 ic_item_mst_b.item_no%TYPE          -- 品目コード
   ,req_item_name             xxcmn_item_mst_b.item_name%TYPE     -- 出荷品目名称
   ,item_name                 xxcmn_item_mst_b.item_name%TYPE     -- 品目名称
   ,trans_um                  ic_tran_pnd.trans_um%TYPE           -- 取引単位
   ,trans_qty                 NUMBER                              -- 取引数量
   ,actual_price              NUMBER                              -- 実際金額
   ,stnd_price                NUMBER                              -- 標準金額
   ,price                     NUMBER                              -- 有償金額
   ,tax                       NUMBER                              -- 消費税
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                    fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gv_user_dept                  xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name                  per_all_people_f.per_information18%TYPE;          -- 担当者
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id                  VARCHAR2(12) ;              -- 帳票ID
  gd_exec_date                  DATE ;                      -- 実施日
--
  gt_main_data                  tab_data_type_dtl ;         -- 取得レコード表
  gt_xml_data_table             XML_DATA ;                  -- ＸＭＬデータタグ表
  gl_xml_idx                    NUMBER DEFAULT 0 ;          -- ＸＭＬデータタグ表のインデックス
--
  gv_gr1_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計１名称
  gv_gr2_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計２名称
  gv_gr3_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計３名称
  gv_gr4_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- 集計４名称
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION ;
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
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>' ;
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
   * Description      : 前処理(F-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
    ir_param             IN OUT NOCOPY rec_param_data -- 01.入力パラメータ群
   ,ov_errbuf               OUT    VARCHAR2           -- エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT    VARCHAR2           -- リターン・コード             --# 固定 #
   ,ov_errmsg               OUT    VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- プログラム名
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
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION ;     -- 値取得エラー
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
    -- 担当部署名取得
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- 受入区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlvv.meaning, 1, 20)
        INTO   ir_param.rcv_pay_div_name
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type  = gc_xxcmn_new_acc_div
        AND    xlvv.lookup_code  = ir_param.rcv_pay_div
        AND    ROWNUM            = 1
        ;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 商品区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.prod_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.prod_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_prod_div
        AND    xcv.segment1          = ir_param.prod_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 品目区分名取得
    -- ====================================================
    -- 個人選択の場合、名称を取得する
    IF ( ir_param.item_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.item_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_item_div
        AND    xcv.segment1          = ir_param.item_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 成績部署名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計無し」を設定
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post = gc_param_all_code )
    THEN
      ir_param.result_post_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.result_post IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlv.location_short_name, 1, 20)
        INTO   ir_param.result_post_name
        FROM   xxcmn_locations_v xlv
        WHERE  xlv.location_code = ir_param.result_post
        AND    ROWNUM            = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 倉庫名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計無し」を設定
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code = gc_param_all_code )
    THEN
      ir_param.whse_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( iwm.whse_name, 1, 20)
        INTO   ir_param.whse_name
        FROM   ic_whse_mst iwm
        WHERE  iwm.whse_code = ir_param.whse_code
        AND    ROWNUM        = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- 出荷先名取得
    -- ====================================================
    -- [ALL]の場合、名称に固定値「集計なし」を設定
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code = gc_param_all_code )
    THEN
      ir_param.party_name := gc_param_all_name;
--
    -- 個人選択の場合、名称を取得する
    ELSIF ( ir_param.party_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xpv.party_short_name, 1, 20)
        INTO   ir_param.party_name
        FROM   xxcmn_parties_v xpv
        WHERE  xpv.party_number = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
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
   * Description      : 明細データ取得(F-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
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
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_get_report_data'; -- プログラム名
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
--
    -- *** ローカル・変数 ***
    lv_select               VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_omso            VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_from_porc            VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_where                VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_group_by             VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_order_by             VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql                  VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
--
    lv_crowd_c_name         VARCHAR2(20) ;        -- 郡コードカラム名(抽出条件用)
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ----------------------------------------------------
    -- 初期処理
    -- ----------------------------------------------------
    -- 郡コードカラム名設定(3：郡コード／4：経理郡コード)
    IF ( ir_param.crowd_type  = gc_crowd_type_3 ) THEN
      lv_crowd_c_name := 'crowd_code';
    ELSE
      lv_crowd_c_name := 'acnt_crowd_code';
    END IF;
--
    -- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
    lv_select := ' SELECT'
              || '  xrpm.request_item_code'     || ' AS request_item_code'  -- 出荷品目コード
              || ' ,ximv.item_short_name'       || ' AS request_item_name'  -- 出荷品目名称
              || ' ,xleiv.item_code'            || ' AS item_code'          -- 品目コード
              || ' ,xleiv.item_short_name'      || ' AS item_name'          -- 品目名称
              || ' ,itp.trans_um'               || ' AS trans_um'           -- 取引単位
--
              || ' ,NVL2(xrpm.item_id, itp.trans_qty'
              ||                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
                                                || ' AS trans_qty'          -- 取引数量
--
              || ' ,('
              || '   (CASE ximv.cost_manage_code'
                       -- 原価管理区分=1:標準 標準原価マスタの実際原価
              || '     WHEN ''' || gc_cost_st || ''' THEN xsupv.stnd_unit_price'
              || '     ELSE'
                       -- 原価管理区分=0:実際
                       -- ロット管理=1:する   ロット別原価テーブルの実際原価
                       -- ロット管理=0:しない 標準原価マスタの実際原価
              || '       DECODE(ximv.lot_ctl,1,'
              || '         (SELECT DECODE('
              || '            SUM(NVL(xlc.trans_qty,0)),0,0,'
              || '            SUM(xlc.trans_qty * xlc.unit_ploce)'
              || '              / SUM(NVL(xlc.trans_qty,0)))'
              || '          FROM  xxcmn_lot_cost xlc'
              || '          WHERE xlc.item_id = ximv.item_id )'
              || '       ,xsupv.stnd_unit_price)'
              || '    END)'
              || '     * NVL2(xrpm.item_id, itp.trans_qty'
              ||                         ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||  ' )'                          || ' AS actual_price'       -- 実際金額
--
              || ' ,(xsupv.stnd_unit_price'
              ||     ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                         ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||  ' )'                          || ' AS stnd_price'         -- 標準金額
--
              || ' ,( CASE xleiv.lot_ctl'
              ||         ' WHEN  0 THEN ( xrpm.unit_price'
              ||                ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||                       ' )'
              ||         ' ELSE'
              ||              ' ( '
              ||                 '(SELECT DECODE('
              ||                                ' SUM(NVL(xlc.trans_qty,0)),0,0,'
              ||                                ' SUM(xlc.trans_qty * xlc.unit_ploce)'
              ||                                 ' / SUM(NVL(xlc.trans_qty,0))'
              ||                              ' )'
              ||                ' FROM  xxcmn_lot_cost xlc'
              ||                ' WHERE xlc.item_id = itp.item_id )'
              ||                ' * NVL2(xrpm.item_id, itp.trans_qty'
              ||                                    ', itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
              ||              ' )'
              ||     ' END )'                   || ' AS price'              -- 有償金額
              || ' ,xlvv2.lookup_code'          || ' AS tax'                -- 消費税率
              ;
--
    -- ----------------------------------------------------
    -- 集計パターン別による、スクリプト生成
    -- ----------------------------------------------------
    -- 集計パターン１設定 (集計：1.成績部署、2.品目区分、3.倉庫、4.出荷先)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- 成績部署
                || ' ,xrpm.item_div'             || ' AS group2_code' -- 品目区分
                || ' ,itp.whse_code'             || ' AS group3_code' -- 倉庫
                || ' ,xpv.party_number'          || ' AS group4_code' -- 出荷先
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- 成績部署計
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr3_sum_desc := gc_whse_sum_desc;                            -- 倉庫計
      gv_gr4_sum_desc := gc_party_sum_desc;                           -- 出荷先計
--
    -- 集計パターン２設定 (集計：1.成績部署、2.品目区分、3.倉庫)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- 成績部署
                || ' ,xrpm.item_div'             || ' AS group2_code' -- 品目区分
                || ' ,itp.whse_code'             || ' AS group3_code' -- 倉庫
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- 成績部署計
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr3_sum_desc := gc_whse_sum_desc;                            -- 倉庫計
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- 集計パターン３設定 (集計：1.成績部署、2.品目区分、3.出荷先)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- 成績部署
                || ' ,xrpm.item_div'             || ' AS group2_code' -- 品目区分
                || ' ,xpv.party_number'          || ' AS group3_code' -- 出荷先
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- 成績部署計
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr3_sum_desc := gc_party_sum_desc;                           -- 出荷先計
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
      -- 集計パターン４設定 (集計：1.成績部署、2.品目区分)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.result_post'          || ' AS group1_code' -- 成績部署
                || ' ,xrpm.item_div'             || ' AS group2_code' -- 品目区分
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_result_post_sum_name;                     -- 成績部署計
      gv_gr2_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- 集計パターン５設定 (集計：1.品目区分、2.倉庫、3.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- 品目区分
                || ' ,itp.whse_code'             || ' AS group2_code' -- 倉庫
                || ' ,xpv.party_number'          || ' AS group3_code' -- 出荷先
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr2_sum_desc := gc_whse_sum_desc;                            -- 倉庫計
      gv_gr3_sum_desc := gc_party_sum_desc;                           -- 出荷先計
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- 集計パターン６設定 (集計：1.品目区分、2.倉庫)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- 品目区分
                || ' ,itp.whse_code'             || ' AS group2_code' -- 倉庫
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr2_sum_desc := gc_whse_sum_desc;                            -- 倉庫計
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- 集計パターン７設定 (集計：1.品目区分、2.出荷先)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- 品目区分
                || ' ,xpv.party_number'          || ' AS group2_code' -- 出荷先
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード or 経理郡コード
                ;
--
      -- 集計名称格納
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr2_sum_desc := gc_party_sum_desc;                           -- 出荷先計
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
--
    -- 集計パターン８設定 (集計：1.品目区分)
    ELSE
--
      lv_select := lv_select
                || ' ,xrpm.item_div'             || ' AS group1_code' -- 品目区分
                || ' ,NULL'                      || ' AS group2_code' -- (NULL)
                || ' ,NULL'                      || ' AS group3_code' -- (NULL)
                || ' ,NULL'                      || ' AS group4_code' -- (NULL)
                || ' ,xrpm.' || lv_crowd_c_name  || ' AS group5_code' -- 郡コード／経理郡コード
                ;
      -- 集計名称格納
      gv_gr1_sum_desc := gc_article_div_sum_name;                     -- 品目区分総計
      gv_gr2_sum_desc := NULL;                                        -- (NULL)
      gv_gr3_sum_desc := NULL;                                        -- (NULL)
      gv_gr4_sum_desc := NULL;                                        -- (NULL)
    END IF;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    -- ＜受払VIEW(購買関連)＞
    lv_from_porc := ' FROM'
                 ||       '  ic_tran_pnd'                  || ' itp'   -- 保留在庫トラン
                 ||       ' ,xxcmn_rcv_pay_mst_porc_rma_v' || ' xrpm'  -- 受払VIEW(購買関連)
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv'  -- クイックコード
                 ||       ' ,xxcmn_lot_each_item_v'        || ' xleiv' -- ロット別品目情報
                 ||       ' ,xxcmn_stnd_unit_price_v'      || ' xsupv' -- 標準原価情報View
                 ||       ' ,xxcmn_item_mst2_v'            || ' ximv'  -- OPM品目情報View2
                 ||       ' ,xxcmn_party_sites2_v'         || ' xpsv'  -- パーティサイト情報View2
                 ||       ' ,xxcmn_parties2_v'             || ' xpv'   -- パーティ情報View2
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv2' -- クイックコード
                 ;
    -- ＜受払VIEW(受注関連)＞
    lv_from_omso := ' FROM'
                 ||       '  ic_tran_pnd'                  || ' itp'   -- 保留在庫トラン
                 ||       ' ,xxcmn_rcv_pay_mst_omso_v'     || ' xrpm'  -- 受払VIEW(受注関連)
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv'  -- クイックコード
                 ||       ' ,xxcmn_lot_each_item_v'        || ' xleiv' -- ロット別品目情報
                 ||       ' ,xxcmn_stnd_unit_price_v'      || ' xsupv' -- 標準原価情報View
                 ||       ' ,xxcmn_item_mst2_v'            || ' ximv'  -- OPM品目情報View2
                 ||       ' ,xxcmn_party_sites2_v'         || ' xpsv'  -- パーティサイト情報View2
                 ||       ' ,xxcmn_parties2_v'             || ' xpv'   -- パーティ情報View2
                 ||       ' ,xxcmn_lookup_values2_v'       || ' xlvv2' -- クイックコード
                 ;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    -- ＜受払VIEW(購買関連)＞
    lv_from_porc := lv_from_porc
                 || ' WHERE'
                 ||           ' itp.doc_type'         || ' = ''PORC'''      -- 文書タイプ(PORC)
                 || ' AND' || ' itp.completed_ind'    || ' = 1'             -- 完了フラグ
                 || ' AND' || ' itp.doc_type'         || ' = xrpm.doc_type' -- 文書タイプ(PORC)
                 || ' AND' || ' itp.doc_id'           || ' = xrpm.doc_id'   -- 文書ID
                 || ' AND' || ' itp.doc_line'         || ' = xrpm.doc_line' -- 取引明細番号
                 ;
    -- ＜受払VIEW(受注関連)＞
    lv_from_omso := lv_from_omso
                 || ' WHERE'
                 ||           ' itp.doc_type'         || ' = ''OMSO'''      -- 文書タイプ(OMSO)
                 || ' AND' || ' itp.completed_ind'    || ' = 1'             -- 完了フラグ
                 || ' AND' || ' itp.doc_type'         || ' = xrpm.doc_type' -- 文書タイプ(OMSO)
                 || ' AND' || ' itp.line_detail_id'   || ' = xrpm.doc_line' -- 取引明細番号
                 ;
--
    -- 「処理年月(自)～(至)」を抽出条件に設定
    lv_where := ' AND itp.trans_date >='
             ||     ' FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from || ''',''yyyymm'')'
             || ' AND itp.trans_date < '
             ||     ' ADD_MONTHS( FND_DATE.STRING_TO_DATE('''
             ||                                      ir_param.proc_to || ''',''yyyymm''),1)'
             ;
--
    -- 「受払区分」を抽出条件に設定
    IF  ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.new_div_account = ''' || ir_param.rcv_pay_div || ''''
               ;
    END IF;
--
    -- 「倉庫コード」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND itp.whse_code = '''        || ir_param.whse_code || ''''
               ;
    END IF;
--
    -- 「成績部署」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND xrpm.result_post = '''     || ir_param.result_post || ''''
               ;
    END IF;
--
    -- クイックコード(xxcmn_lookup_values2_v)連結
    lv_where := lv_where
             || ' AND' || ' xlvv.lookup_type'   || ' = ''XXCMN_MONTH_TRANS_OUTPUT_FLAG'''
             || ' AND' || ' xrpm.dealings_div'  || ' = xlvv.meaning'
             || ' AND' || ' (xlvv.start_date_active IS NULL'
             ||           ' OR xlvv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xlvv.end_date_active IS NULL'
             ||           ' OR xlvv.end_date_active >= TRUNC(itp.trans_date) )'
             || ' AND' || ' xlvv.language'      || ' = ''JA'''
             || ' AND' || ' xlvv.source_lang'   || ' = ''JA'''
             || ' AND' || ' xlvv.attribute6'    || ' IS NOT NULL'
             ;
--
    -- ロット別品目情報(xxcmn_lot_each_item_v)連結
    lv_where := lv_where
             || ' AND' || ' itp.item_id'        || ' = xleiv.item_id'        -- 品目ID
             || ' AND' || ' itp.lot_id'         || ' = xleiv.lot_id'         -- ロットID
             || ' AND' || ' (xleiv.start_date_active IS NULL'
             ||           ' OR xleiv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xleiv.end_date_active IS NULL'
             ||           ' OR xleiv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- 「郡種別」が「3:郡コード」で、かつ、「郡コード」が入力されている場合、抽出条件に設定
    IF    ( ir_param.crowd_type = gc_crowd_type_3 )
    AND   ( ir_param.crowd_code IS NOT NULL )
    THEN
      lv_where := lv_where
               || ' AND xrpm.crowd_code = '''      || ir_param.crowd_code || ''''
               ;
    -- 「郡種別」が「4:経理郡コード」で、かつ、「経理郡コード」が入力されている場合、抽出条件に設定
    ELSIF ( ir_param.crowd_type =  '4' )
    AND   ( ir_param.acnt_crowd_code IS NOT NULL )
    THEN
      lv_where := lv_where
               || ' AND xrpm.acnt_crowd_code = ''' || ir_param.acnt_crowd_code || ''''
               ;
    END IF;
--
    -- 「品目区分」が個別選択されている場合、抽出条件に設定
    IF  ( ir_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.item_div = '''        || ir_param.item_div || ''''
               ;
    END IF;
--
    -- 「商品区分」が個別選択されている場合、抽出条件に設定
    IF  ( ir_param.prod_div IS NOT NULL ) THEN
      lv_where := lv_where
               || ' AND xrpm.prod_div = '''        || ir_param.prod_div || ''''
               ;
    END IF;
--
    -- 標準原価情報View(xxcmn_stnd_unit_price_v)連結
    lv_where := lv_where
             || ' AND' || ' NVL(xrpm.item_id, itp.item_id)' || ' = xsupv.item_id' -- 品目ID
             || ' AND' || ' (xsupv.start_date_active IS NULL'
             ||           ' OR xsupv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xsupv.end_date_active IS NULL'
             ||           ' OR xsupv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- OPM品目情報View2(xxcmn_item_mst2_v)連結
    lv_where := lv_where
             || ' AND' || ' xrpm.request_item_code' || ' = ximv.item_no(+)'     -- 製品受払品目ID
             || ' AND' || ' (ximv.start_date_active IS NULL'
             ||           ' OR ximv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (ximv.end_date_active IS NULL'
             ||           ' OR ximv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- パーティサイト情報View2(xxcmn_party_sites2_v)連結
    lv_where := lv_where
             || ' AND' || ' xrpm.deliver_to_id'   || ' = xpsv.party_site_id'    -- 出荷先ID
             || ' AND' || ' (xpsv.start_date_active IS NULL'
             ||           ' OR xpsv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xpsv.end_date_active IS NULL'
             ||           ' OR xpsv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- 「出荷先コード」が個別選択されている場合(*ALLを除く)、抽出条件に設定
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code != gc_param_all_code )
    THEN
      lv_where := lv_where
               || ' AND xpv.party_number = '''    || ir_param.party_code || ''''
               ;
    END IF;
--
    -- パーティ情報View2(xxcmn_parties2_v)連結
    lv_where := lv_where
             || ' AND' || ' xpsv.party_id'        || ' = xpv.party_id'          -- パーティID
             || ' AND' || ' (xpv.start_date_active IS NULL'
             ||           ' OR xpv.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xpv.end_date_active IS NULL'
             ||           ' OR xpv.end_date_active >= TRUNC(itp.trans_date) )'
             ;
--
    -- クイックコード(xxcmn_lookup_values2_v)連結－消費税率
    lv_where := lv_where
             || ' AND' || ' xlvv2.lookup_type'    || ' = ''XXCMN_CONSUMPTION_TAX_RATE'''
             || ' AND' || ' (xlvv2.start_date_active IS NULL'
             ||           ' OR xlvv2.start_date_active <= TRUNC(itp.trans_date) )'
             || ' AND' || ' (xlvv2.end_date_active IS NULL'
             ||           ' OR xlvv2.end_date_active >= TRUNC(itp.trans_date) )'
             || ' AND' || ' xlvv2.language'       || ' = ''JA'''
             || ' AND' || ' xlvv2.source_lang'    || ' = ''JA'''
             ;
--
    -- ----------------------------------------------------
    -- ＧＲＯＵＰ ＢＹ句生成
    -- ----------------------------------------------------
    lv_group_by := ' GROUP BY'
                || '  mst.group1_code'           -- [集計1]コード
                || ' ,mst.group2_code'           -- [集計2]コード
                || ' ,mst.group3_code'           -- [集計3]コード
                || ' ,mst.group4_code'           -- [集計4]コード
                || ' ,mst.group5_code'           -- [集計5]コード
                || ' ,mst.request_item_code'     -- 出荷品目コード
                || ' ,mst.item_code'             -- 品目コード
                ;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ ＢＹ句生成
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || '  mst.group1_code'           -- [集計1]コード
                || ' ,mst.group2_code'           -- [集計2]コード
                || ' ,mst.group3_code'           -- [集計3]コード
                || ' ,mst.group4_code'           -- [集計4]コード
                || ' ,mst.group5_code'           -- [集計5]コード
                || ' ,mst.request_item_code'     -- 出荷品目コード
                || ' ,mst.item_code'             -- 品目コード
                ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := 'SELECT'
           ||       ' mst.group1_code'            || ' AS group1_code'        -- [集計1]コード
           ||       ',mst.group2_code'            || ' AS group2_code'        -- [集計2]コード
           ||       ',mst.group3_code'            || ' AS group3_code'        -- [集計3]コード
           ||       ',mst.group4_code'            || ' AS group4_code'        -- [集計4]コード
           ||       ',mst.group5_code'            || ' AS group5_code'        -- [集計5]コード
           ||       ',mst.request_item_code'      || ' AS request_item_code'  -- 出荷品目コード
           ||       ',mst.item_code'              || ' AS item_code'          -- 品目コード
           ||       ',MAX(mst.request_item_name)' || ' AS request_item_name'  -- 出荷品目名称
           ||       ',MAX(mst.item_name)'         || ' AS item_name'          -- 取引単位
           ||       ',MAX(mst.trans_um)'          || ' AS trans_um'           -- 取引数量
           ||       ',SUM(mst.trans_qty)'         || ' AS trans_qty'          -- 取引数量
           ||       ',SUM(mst.actual_price)'      || ' AS actual_price'       -- 実際金額
           ||       ',SUM(mst.stnd_price)'        || ' AS stnd_price'         -- 標準金額
           ||       ',SUM(mst.price)'             || ' AS price'              -- 有償金額
           ||       ',SUM(mst.price * DECODE( NVL(mst.tax,0),0,0,(mst.tax/100) ) )'
           ||                                        ' AS tax'                -- 消費税率
           || ' FROM ('
--
           -- ＜受払VIEW(購買関連)＞
           || lv_select || lv_from_porc || lv_where
--
           || ' UNION ALL '
--
           -- ＜受払VIEW(受注関連)＞
             || lv_select || lv_from_omso || lv_where
--
           || ' ) mst'
           || lv_group_by
           || lv_order_by
           ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql ;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE lc_ref ;
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(F-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
    ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
   ,ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
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
    lc_break_init         VARCHAR2(100) DEFAULT '#' ;            -- 初期値
    lc_break_null         VARCHAR2(100) DEFAULT '*' ;            -- ＮＵＬＬ判定
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_gp_cd1             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ１
    lv_gp_cd2             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ２
    lv_gp_cd3             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ３
    lv_gp_cd4             VARCHAR2(5)   DEFAULT lc_break_init ;              -- 集計グループ４
    lv_crowd_l            VARCHAR2(1)   DEFAULT lc_break_init ;              -- 大郡計グループ
    lv_crowd_m            VARCHAR2(2)   DEFAULT lc_break_init ;              -- 中郡計グループ
    lv_crowd_s            VARCHAR2(3)   DEFAULT lc_break_init ;              -- 小郡計グループ
    lv_crowd_cd           VARCHAR2(4)   DEFAULT lc_break_init ;              -- 詳郡計グループ
--
    -- 計算用
    ln_position           NUMBER        DEFAULT 0;               -- 計算用：ポジション
    ln_i                  NUMBER        DEFAULT 0;               -- カウンター用
    lv_trans_qty          NUMBER ;                               -- 取引数量
    lv_tax                NUMBER ;                               -- 消費税率
    lv_tax_price          NUMBER ;                               -- 消費税
    ln_unit_price1        NUMBER ;                               -- 標準原価
    ln_unit_price2        NUMBER ;                               -- 有償原価
    ln_unit_price3        NUMBER ;                               -- 実際単価
    ln_unit_price4        NUMBER ;                               -- 有－標（原価）
    ln_unit_price5        NUMBER ;                               -- 有－実（原価）
    ln_unit_price6        NUMBER ;                               -- 標－実（原価）
    lv_price1             NUMBER ;                               -- 標準金額
    lv_price2             NUMBER ;                               -- 有償金額
    lv_price3             NUMBER ;                               -- 実際金額
    lv_price4             NUMBER ;                               -- 有－標（金額）
    lv_price5             NUMBER ;                               -- 有－実（金額）
    lv_price6             NUMBER ;                               -- 標－実（金額）
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
--
    -- *** ローカル関数 ***
    ----------------------
    --1.ＸＭＬ 1行出力   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   タグネーム
      ,ic_type    IN   CHAR                     --   タグタイプ
      ,iv_data    IN   VARCHAR2 DEFAULT NULL)   --   データ
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --データの場合
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := iv_data;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
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
       ,ot_data_rec   => gt_main_data   -- 02.取得レコード群
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
    -- ＜ヘッダ部＞項目データ抽出・出力処理
    -- =====================================================
--
    -- -----------------------------------------------------
    -- [USER_INFO] データ出力
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
--
    prc_xml_add('exec_date',          'D', TO_CHAR(gd_exec_date, gc_char_dt_format) ); -- 実施日
    prc_xml_add('report_id',          'D', gv_report_id);                    -- 帳票ＩＤ
    prc_xml_add('exec_user_dept',     'D', SUBSTRB(gv_user_dept,1,10) );     -- 担当部署
    prc_xml_add('exec_user_name',     'D', SUBSTRB(gv_user_name,1,14) );     -- 担当者名
    -- パラメータ
    prc_xml_add('p_item_div_code',    'D', ir_param.prod_div );              -- 商品区分
    prc_xml_add('p_item_div_name',    'D', ir_param.prod_div_name );         -- 商品区分名
    prc_xml_add('p_party_code',       'D', ir_param.party_code );            -- 出荷先コード
    prc_xml_add('p_party_name',       'D', ir_param.party_name );            -- 出荷先名
    prc_xml_add('p_locat_code',       'D', ir_param.whse_code );             -- 倉庫コード
    prc_xml_add('p_locat_name',       'D', ir_param.whse_name );             -- 倉庫名
    prc_xml_add('p_rcv_pay_div_code', 'D', ir_param.rcv_pay_div );           -- 受払区分
    prc_xml_add('p_rcv_pay_div_name', 'D', ir_param.rcv_pay_div_name );      -- 受払区分名
    prc_xml_add('p_article_div_code', 'D', ir_param.item_div );              -- 品目区分
    prc_xml_add('p_article_div_name', 'D', ir_param.item_div_name );         -- 品目区分名
    prc_xml_add('p_result_post_code', 'D', ir_param.result_post );           -- 成績部署
    prc_xml_add('p_result_post_name', 'D', ir_param.result_post_name );      -- 成績部署名
    -- 処理年月(自)
    prc_xml_add('p_trans_ym_from','D', SUBSTRB(ir_param.proc_from,1,4) || '年'
                                    || SUBSTRB(ir_param.proc_from,5,2) || '月' );
    -- 処理年月(至)
    prc_xml_add('p_trans_ym_to',  'D', SUBSTRB(ir_param.proc_to,1,4) || '年'
                                    || SUBSTRB(ir_param.proc_to,5,2) || '月' );
--
    prc_xml_add('/user_info', 'T', NULL);
--
    -- =====================================================
    -- ＜明細部＞項目データ抽出・出力処理
    -- =====================================================
    ln_i := 1;
    -- -----------------------------------------------------
    -- [DATA_INFO] 開始タグ出力
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T');
    prc_xml_add('lg_gr1',    'T');
--
    --=============================================集計１ループ開始
    <<group1_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT )
    LOOP
      prc_xml_add('g_gr1', 'T');
      prc_xml_add('gr1_code',     'D', gt_main_data(ln_i).group1_code);
      prc_xml_add('gr1_sum_desc', 'D', gv_gr1_sum_desc);
      lv_gp_cd1  :=  NVL(gt_main_data(ln_i).group1_code, lc_break_null);
      --=============================================集計２ループ開始
      prc_xml_add('lg_gr2', 'T');
      <<group2_loop>>
      WHILE ( ln_i  <= gt_main_data.COUNT )
        AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
      LOOP
        prc_xml_add('g_gr2', 'T');
        prc_xml_add('gr2_code',     'D', gt_main_data(ln_i).group2_code);
        prc_xml_add('gr2_sum_desc', 'D', gv_gr2_sum_desc);
        lv_gp_cd2  :=  NVL(gt_main_data(ln_i).group2_code, lc_break_null);
        --===============================================集計３ループ開始
        prc_xml_add('lg_gr3', 'T');
        <<group3_loop>>
        WHILE ( ln_i  <= gt_main_data.COUNT )
          AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
          AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
        LOOP
          prc_xml_add('g_gr3', 'T');
          prc_xml_add('gr3_code',     'D', gt_main_data(ln_i).group3_code);
          prc_xml_add('gr3_sum_desc', 'D', gv_gr3_sum_desc);
          lv_gp_cd3  :=  NVL(gt_main_data(ln_i).group3_code, lc_break_null);
          --================================================集計４ループ開始
          prc_xml_add('lg_gr4', 'T');
          <<group4_loop>>
          WHILE ( ln_i  <= gt_main_data.COUNT )
            AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
            AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
            AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
          LOOP
            prc_xml_add('g_gr4', 'T');
            prc_xml_add('gr4_code',     'D', gt_main_data(ln_i).group4_code);
            prc_xml_add('gr4_sum_desc', 'D', gv_gr4_sum_desc);
            lv_gp_cd4  :=  NVL(gt_main_data(ln_i).group4_code, lc_break_null);
            --================================================大郡計ループ開始
            prc_xml_add('lg_crowd_l', 'T');
            <<crowd_l_loop>>
            WHILE ( ln_i  <= gt_main_data.COUNT )
              AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
              AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
              AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
              AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
            LOOP
              prc_xml_add('g_crowd_l', 'T');
              prc_xml_add('crowd_lcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,1) );
              lv_crowd_l  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1), lc_break_null);
              --================================================中郡計ループ開始
              prc_xml_add('lg_crowd_m', 'T');
              <<crowd_m_loop>>
              WHILE ( ln_i  <= gt_main_data.COUNT )
                AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1),lc_break_null)= lv_crowd_l)
              LOOP
                prc_xml_add('g_crowd_m', 'T');
                prc_xml_add('crowd_mcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,2) );
                lv_crowd_m  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2), lc_break_null);
                --================================================小郡計ループ開始
                prc_xml_add('lg_crowd_s', 'T');
                <<crowd_s_loop>>
                WHILE ( ln_i  <= gt_main_data.COUNT )
                  AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                  AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                  AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                  AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                  AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2),lc_break_null)
                                                                           = lv_crowd_m)
                LOOP
                  prc_xml_add('g_crowd_s', 'T');
                  prc_xml_add('crowd_scode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,3) );
                  lv_crowd_s := NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3), lc_break_null);
                  --================================================詳郡計ループ開始
                  prc_xml_add('lg_crowd', 'T');
                  <<crowd_loop>>
                  WHILE ( ln_i  <= gt_main_data.COUNT )
                    AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                    AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                    AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                    AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                    AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3),lc_break_null)
                                                                             = lv_crowd_s)
                  LOOP
                    prc_xml_add('g_crowd', 'T');
                    prc_xml_add('crowd_code', 'D', gt_main_data(ln_i).group5_code );
                    --================================================品目ループ開始
                    lv_crowd_cd := NVL(gt_main_data(ln_i).group5_code, lc_break_null);
                    prc_xml_add('lg_item', 'T');
                    <<item_loop>>
                    WHILE ( ln_i  <= gt_main_data.COUNT )
                      AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                      AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                      AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                      AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                      AND ( NVL(gt_main_data(ln_i).group5_code, lc_break_null) = lv_crowd_cd)
                    LOOP
                      prc_xml_add('g_item', 'T');
--
                      -- -----------------------------------------------------
                      -- 初期化
                      -- -----------------------------------------------------
                      lv_trans_qty   := NULL;    -- 取引数量
                      lv_tax         := NULL;    -- 消費税率
                      lv_tax_price   := NULL;    -- 消費税
                      ln_unit_price1 := NULL;    -- 標準原価
                      ln_unit_price2 := NULL;    -- 有償原価
                      ln_unit_price3 := NULL;    -- 実際単価
                      ln_unit_price4 := NULL;    -- 有－標（原価）
                      ln_unit_price5 := NULL;    -- 有－実（原価）
                      ln_unit_price6 := NULL;    -- 標－実（原価）
                      lv_price1      := NULL;    -- 標準金額
                      lv_price2      := NULL;    -- 有償金額
                      lv_price3      := NULL;    -- 実際金額
                      lv_price4      := NULL;    -- 有－標（金額）
                      lv_price5      := NULL;    -- 有－実（金額）
                      lv_price6      := NULL;    -- 標－実（金額）
--
                      -- -----------------------------------------------------
                      -- 算出処理＋まるめ処理
                      -- -----------------------------------------------------
                      -- 数量
                      IF  ( NVL(gt_main_data(ln_i).trans_qty,0) != 0 ) THEN
                        lv_trans_qty     := ROUND(gt_main_data(ln_i).trans_qty, 3);
                      END IF;
                      -- 標準金額
                      IF  ( NVL(gt_main_data(ln_i).stnd_price,0) != 0 ) THEN
                        lv_price1        := ROUND(gt_main_data(ln_i).stnd_price);
                        -- 標準原価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price1 := ROUND(gt_main_data(ln_i).stnd_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 有償金額
                      IF  ( NVL(gt_main_data(ln_i).price,0) != 0 ) THEN
                        lv_price2        := ROUND(gt_main_data(ln_i).price);
                        -- 有償単価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price2 := ROUND(gt_main_data(ln_i).price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 消費税
                      IF  ( NVL(gt_main_data(ln_i).tax,0) != 0 ) THEN
                        lv_tax_price     := ROUND(gt_main_data(ln_i).tax);
                      END IF;
                      -- 実際金額
                      IF  ( NVL(gt_main_data(ln_i).actual_price,0) != 0 ) THEN
                        lv_price3        := ROUND(gt_main_data(ln_i).actual_price);
                        -- 実際原価
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price3 := ROUND(gt_main_data(ln_i).actual_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- 有－標(単価)
                      ln_unit_price4   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price1,0), 2);
                      -- 有－標(金額)
                      lv_price4        := ROUND( NVL(lv_price2,0)      - NVL(lv_price1,0) );
                      -- 有－実(単価)
                      ln_unit_price5   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price3,0), 2);
                      -- 有－実(金額)
                      lv_price5        := ROUND( NVL(lv_price2,0)      - NVL(lv_price3,0) );
                      -- 標－実(単価)
                      ln_unit_price6   := ROUND( NVL(ln_unit_price1,0) - NVL(ln_unit_price3,0), 2);
                      -- 標－実(金額)
                      lv_price6        := ROUND( NVL(lv_price1,0)      - NVL(lv_price3,0) );
--
                      -- -----------------------------------------------------
                      -- XML出力
                      -- -----------------------------------------------------
                      -- 出荷品目コード・出荷品目名称
                      prc_xml_add('req_item_code','D', gt_main_data(ln_i).req_item_code );
                      prc_xml_add('req_item_name','D', gt_main_data(ln_i).req_item_name );
                      -- 品目コード・品目名称
                      prc_xml_add('item_code'    ,'D', gt_main_data(ln_i).item_code );
                      prc_xml_add('item_name'    ,'D', gt_main_data(ln_i).item_name );
                      -- 単位
                      prc_xml_add('item_um'      ,'D', gt_main_data(ln_i).trans_um );
                      -- 数量
                      IF ( lv_trans_qty IS NOT NULL ) THEN
                        prc_xml_add('trans_qty'  ,'D', lv_trans_qty );
                      END IF;
                      -- 消費税
                      IF ( lv_tax_price IS NOT NULL ) THEN
                        prc_xml_add('tax_price'  ,'D', lv_tax_price );
                      END IF;
                      -- 標準原価
                      IF ( ln_unit_price1 IS NOT NULL ) THEN
                        prc_xml_add('unit_price1','D', ln_unit_price1 );
                      END IF;
                      -- 標準金額
                      IF ( lv_price1 IS NOT NULL ) THEN
                        prc_xml_add('price1'     ,'D', lv_price1 );
                      END IF;
                      -- 有償単価
                      IF ( ln_unit_price2 IS NOT NULL ) THEN
                        prc_xml_add('unit_price2','D', ln_unit_price2 );
                      END IF;
                      -- 有償金額
                      IF ( lv_price2 IS NOT NULL ) THEN
                        prc_xml_add('price2'     ,'D', lv_price2 );
                      END IF;
                      -- 実際原価
                      IF ( ln_unit_price3 IS NOT NULL ) THEN
                        prc_xml_add('unit_price3','D', ln_unit_price3 );
                      END IF;
                      -- 実際金額
                      IF ( lv_price3 IS NOT NULL ) THEN
                        prc_xml_add('price3'     ,'D', lv_price3 );
                      END IF;
                      -- 有－標（原価）
                      IF ( ln_unit_price4 IS NOT NULL ) THEN
                        prc_xml_add('unit_price4','D', ln_unit_price4 );
                      END IF;
                      -- 有－標（金額）
                      IF ( lv_price4 IS NOT NULL ) THEN
                        prc_xml_add('price4'     ,'D', lv_price4 );
                      END IF;
                      -- 有－実（原価）
                      IF ( ln_unit_price5 IS NOT NULL ) THEN
                        prc_xml_add('unit_price5','D', ln_unit_price5 );
                      END IF;
                      -- 有－実（金額）
                      IF ( lv_price5 IS NOT NULL ) THEN
                        prc_xml_add('price5'     ,'D', lv_price5 );
                      END IF;
                      -- 標－実（単価）
                      IF ( ln_unit_price6 IS NOT NULL ) THEN
                        prc_xml_add('unit_price6','D', ln_unit_price6 );
                      END IF;
                      -- 標－実（金額）
                      IF ( lv_price6 IS NOT NULL ) THEN
                        prc_xml_add('price6'     ,'D', lv_price6 );
                      END IF;
--
                      ln_i  :=  ln_i  + 1; --次明細位置
                      prc_xml_add('/g_item', 'T');
                    END LOOP  item_loop;
                    prc_xml_add('/lg_item', 'T');
                    --================================================詳郡計ループ終了
                    prc_xml_add('/g_crowd', 'T');
                  END LOOP  crowd_loop;
                  prc_xml_add('/lg_crowd', 'T');
                  --================================================詳郡計ループ終了
                  prc_xml_add('/g_crowd_s', 'T');
                END LOOP  crowd_s_loop;
                prc_xml_add('/lg_crowd_s', 'T');
                --================================================小郡計ループ終了
                prc_xml_add('/g_crowd_m', 'T');
              END LOOP  crowd_m_loop;
              prc_xml_add('/lg_crowd_m', 'T');
              --================================================中郡計ループ終了
              prc_xml_add('/g_crowd_l', 'T');
            END LOOP  crowd_l_loop;
            prc_xml_add('/lg_crowd_l', 'T');
          --================================================大郡計ループ終了
          prc_xml_add('/g_gr4', 'T');
          END LOOP  group4_loop;
          prc_xml_add('/lg_gr4', 'T');
          --================================================集計４ループ終了
          prc_xml_add('/g_gr3', 'T');
        END LOOP  group3_loop;
        prc_xml_add('/lg_gr3', 'T');
        --================================================集計３ループ終了
        prc_xml_add('/g_gr2', 'T');
      END LOOP  group2_loop;
      prc_xml_add('/lg_gr2', 'T');
      --================================================集計２ループ終了
      --最終レコードの場合、総合計行出力フラグをONにする。
      IF (ln_i > gt_main_data.COUNT) THEN
        prc_xml_add('last_recode_flg', 'D', 'Y');
      ELSE
        prc_xml_add('last_recode_flg', 'D', 'N');
      END IF;
      prc_xml_add('/g_gr1', 'T');
    END LOOP  group1_loop;
    prc_xml_add('/lg_gr1', 'T');
    --================================================集計１ループ終了
--
    prc_xml_add('/data_info', 'T'); --データ終了
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
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
    iv_proc_from          IN    VARCHAR2  --   01 : 処理年月FROM
   ,iv_proc_to            IN    VARCHAR2  --   02 : 処理年月TO
   ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : 受払区分
   ,iv_prod_div           IN    VARCHAR2  --   04 : 商品区分
   ,iv_item_div           IN    VARCHAR2  --   05 : 品目区分
   ,iv_result_post        IN    VARCHAR2  --   06 : 成績部署
   ,iv_whse_code          IN    VARCHAR2  --   07 : 倉庫コード
   ,iv_party_code         IN    VARCHAR2  --   08 : 出荷先コード
   ,iv_crowd_type         IN    VARCHAR2  --   09 : 郡種別
   ,iv_crowd_code         IN    VARCHAR2  --   10 : 郡コード
   ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : 経理群コード
   ,iv_output_type        IN    VARCHAR2  --   12 : 出力種別
   ,ov_errbuf            OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode           OUT    VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg            OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
    lv_work_date            VARCHAR2(30); -- 変換用
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
    gv_report_id                 := iv_output_type || 'T' ;-- 帳票ID
    gd_exec_date                 := SYSDATE ;              -- 実施日
    -- パラメータ格納
    -- 処理年月FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_from, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_from     := iv_proc_from;
    ELSE
      lr_param_rec.proc_from     := lv_work_date;
    END IF;
    -- 処理年月TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_to, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_to     := iv_proc_to;
    ELSE
      lr_param_rec.proc_to     := lv_work_date;
    END IF;
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- 受払区分
    lr_param_rec.prod_div        := iv_prod_div;           -- 商品区分
    lr_param_rec.item_div        := iv_item_div;           -- 品目区分
    lr_param_rec.result_post     := iv_result_post;        -- 成績部署
    lr_param_rec.whse_code       := iv_whse_code;          -- 倉庫コード
    lr_param_rec.party_code      := iv_party_code;         -- 出荷先コード
    lr_param_rec.crowd_type      := iv_crowd_type;         -- 郡種別
    lr_param_rec.crowd_code      := iv_crowd_code;         -- 郡コード
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- 経理群コード
    lr_param_rec.output_type     := iv_output_type;        -- 出力種別
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
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
        ir_param          => lr_param_rec       -- 入力パラメータ群
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>') ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <user_info>') ;
      -- ＸＭＬタグ出力 ＞ 実施日
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_date>'
                                       ||    TO_CHAR(gd_exec_date, gc_char_dt_format)
                                       || '</exec_date>'
                       );
      -- ＸＭＬタグ出力 ＞ 帳票ＩＤ
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<report_id>'
                                       ||    gv_report_id
                                       || '</report_id>'
                       );
      -- ＸＭＬタグ出力 ＞ 担当部署
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_dept>'
                                       ||    SUBSTRB(gv_user_dept,1,20)
                                       || '</exec_user_dept>'
                       );
      -- ＸＭＬタグ出力 ＞ 担当者名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_name>'
                                       ||    SUBSTRB(gv_user_name,1,20)
                                       || '</exec_user_name>'
                       );
      -- ＸＭＬタグ出力：商品区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_code>'
                                       ||    lr_param_rec.prod_div
                                       || '</p_item_div_code>'
                       );
      -- ＸＭＬタグ出力：商品区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_name>'
                                       ||    lr_param_rec.prod_div_name
                                       || '</p_item_div_name>'
                       );
      -- ＸＭＬタグ出力 出荷先コード
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_code>'
                                       ||    lr_param_rec.party_code
                                       || '</p_party_code>'
                       );
      -- ＸＭＬタグ出力 出荷先名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_name>'
                                       ||    lr_param_rec.party_name
                                       || '</p_party_name>'
                       );
      -- ＸＭＬタグ出力 倉庫コード
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_code>'
                                       ||    lr_param_rec.whse_code
                                       || '</p_locat_code>'
                       );
      -- ＸＭＬタグ出力 倉庫名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_name>'
                                       ||    lr_param_rec.whse_name
                                       || '</p_locat_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 受払区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_code>'
                                       ||    lr_param_rec.rcv_pay_div
                                       || '</p_rcv_pay_div_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 受払区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_name>'
                                       ||    lr_param_rec.rcv_pay_div_name
                                       || '</p_rcv_pay_div_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 品目区分
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_code>'
                                       ||    lr_param_rec.item_div
                                       || '</p_article_div_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 品目区分名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_name>'
                                       ||    lr_param_rec.item_div_name
                                       || '</p_article_div_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 成績部署
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_code>'
                                       ||    lr_param_rec.result_post
                                       || '</p_result_post_code>'
                       );
      -- ＸＭＬタグ出力 ＞ 成績部署名
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_name>'
                                       ||    lr_param_rec.result_post_name
                                       || '</p_result_post_name>'
                       );
      -- ＸＭＬタグ出力 ＞ 処理年月(自)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_from>'
                                       ||    SUBSTRB(lr_param_rec.proc_from,1,4) || '年'
                                       ||    SUBSTRB(lr_param_rec.proc_from,5,2) || '月'
                                       || '</p_trans_ym_from>'
                       );
      -- ＸＭＬタグ出力 ＞ 処理年月(自)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_to>'
                                       ||    SUBSTRB(lr_param_rec.proc_to,1,4) || '年'
                                       ||    SUBSTRB(lr_param_rec.proc_to,5,2) || '月'
                                       || '</p_trans_ym_to>'
                       );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </user_info>') ;
--
      -- ＜data_info＞
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                <lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  <g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  </g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                </lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>') ;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  --   01 : 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : 処理年月TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : 受払区分
     ,iv_prod_div        IN    VARCHAR2  --   04 : 商品区分
     ,iv_item_div        IN    VARCHAR2  --   05 : 品目区分
     ,iv_result_post     IN    VARCHAR2  --   06 : 成績部署
     ,iv_whse_code       IN    VARCHAR2  --   07 : 倉庫コード
     ,iv_party_code      IN    VARCHAR2  --   08 : 出荷先コード
     ,iv_crowd_type      IN    VARCHAR2  --   09 : 郡種別
     ,iv_crowd_code      IN    VARCHAR2  --   10 : 郡コード
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : 経理群コード
     ,iv_output_type     IN    VARCHAR2  --   12 : 出力種別
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
        iv_proc_from        => iv_proc_from         --   01 : 処理年月FROM
       ,iv_proc_to          => iv_proc_to           --   02 : 処理年月TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : 受払区分
       ,iv_prod_div         => iv_prod_div          --   04 : 商品区分
       ,iv_item_div         => iv_item_div          --   05 : 品目区分
       ,iv_result_post      => iv_result_post       --   06 : 成績部署
       ,iv_whse_code        => iv_whse_code         --   07 : 倉庫コード
       ,iv_party_code       => iv_party_code        --   08 : 出荷先コード
       ,iv_crowd_type       => iv_crowd_type        --   09 : 郡種別
       ,iv_crowd_code       => iv_crowd_code        --   10 : 郡コード
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : 経理群コード
       ,iv_output_type      => iv_output_type       --   12 : 出力種別
       ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode          => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
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
END xxcmn770026c ;
/
