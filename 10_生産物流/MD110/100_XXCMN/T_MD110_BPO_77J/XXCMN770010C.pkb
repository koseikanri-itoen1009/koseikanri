create or replace PACKAGE BODY xxcmn770010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770010C(body)
 * Description      : 標準原価内訳表
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77J)
 * Version          : 1.27
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_set_xml               PROCEDRUE : ＸＭＬ用配列に格納する。
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理
 *  prc_get_report_data       PROCEDURE : 明細データ取得(J-1)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   N.Chinen         新規作成
 *  2008/05/13    1.1   N.Chinen         着荷日でデータを抽出するよう修正。
 *  2008/05/16    1.2   Y.Majikina       パラメータ：処理年月がYYYYMで入力されるとエラーと
 *                                       なる点を修正。
 *  2008/06/12    1.3   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/19    1.4   Y.Ishikawa       取引区分が廃却、見本に関しては、受払区分を掛けない
 *  2008/06/19    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/23    1.7   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V→XXCMN_ITEM_CATEGORIES6_V変更
 *  2008/08/07    1.8   Y.Majikina       参照するVIEWをXXCMN_RCV_PAY_MST_PORC_RMA_V →
 *                                       XXCMN_RCV_PAY_MST_PORC_RMA10_Vへ変更
 *  2008/08/28    1.9   A.Shiina         T_TE080_BPO_770 指摘19対応
 *  2008/10/23    1.10  N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/14    1.11  N.Yoshida        移行データ検証不具合対応
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#215対応
 *  2008/12/02    1.14  N.Yoshida        本番#345対応(振替入庫、緑営１、緑営２追加対応)
 *                                       本番#385対応
 *  2008/12/06    1.15  T.Miyata         本番#495対応
 *  2008/12/06    1.16  T.Miyata         本番#498対応
 *  2008/12/07    1.17  N.Yoshida        本番#496対応
 *  2008/12/11    1.18  A.Shiina         本番#580対応
 *  2008/12/13    1.19  T.Ohashi         本番#580対応
 *  2008/12/14    1.20  N.Yoshida        本番障害669対応
 *  2008/12/15    1.21  N.Yoshida        本番障害727対応
 *  2008/12/22    1.22  N.Yoshida        本番障害825、828対応
 *  2009/01/15    1.23  N.Yoshida        本番障害1023対応
 *  2009/03/10    1.24  A.Shiina         本番障害1298対応
 *  2009/04/10    1.25  A.Shiina         本番障害1396対応
 *  2009/05/29    1.26  Marushita        本番障害1511対応
 *  2012/01/11    1.27  Y.Horikawa       E_本稼動_08747対応
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770010C' ;     -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '標準原価内訳表' ;   -- 帳票名
  gc_first_date             CONSTANT VARCHAR2(2) := '01'; -- 月初め:01日
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_lookup_type             CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '商品区分' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
--
  ------------------------------
  -- 取引区分名
  ------------------------------
  gv_haiki                   CONSTANT VARCHAR2(100) := '廃却' ;
  gv_mihon                   CONSTANT VARCHAR2(100) := '見本' ;
  gv_d_name_trn_rcv          CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替有償_受入';
  gv_d_name_item_trn_rcv     CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '商品振替有償_受入';
  gv_d_name_trn_ship_rcv_gen CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_原';
  gv_d_name_trn_ship_rcv_han CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_半';
  gc_rcv_pay_div_adj         CONSTANT VARCHAR2(2) := '-1' ;  --調整
--
   ------------------------------
  -- 群種別
  ------------------------------
  gc_crowd_kind           CONSTANT VARCHAR2(1) := '3';    --群別
  gc_crowd_acct_kind      CONSTANT VARCHAR2(1) := '4';    --経理群別
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- アプリケーション
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_ym_format       CONSTANT VARCHAR2(30) := 'YYYY"年"MM"月"';
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  ------------------------------
  -- 数値・金額小数点位置
  ------------------------------
  gn_qty_dec             CONSTANT NUMBER      := 3;
--
  gn_one                 CONSTANT NUMBER      := 1   ;
  gn_two                 CONSTANT NUMBER      := 2   ;
--
  ------------------------------
  -- 項目位置判断
  ------------------------------
  -- 受入
  gc_col_no_po             CONSTANT VARCHAR2(2) := '1';    -- 仕入
  gc_col_no_wrap           CONSTANT VARCHAR2(2) := '2';    -- 包装
  gc_col_no_set            CONSTANT VARCHAR2(2) := '3';    -- セット
  gc_col_no_oki            CONSTANT VARCHAR2(2) := '4';    -- 沖縄
  gc_col_no_trnsfr         CONSTANT VARCHAR2(2) := '5';    -- 振替入庫
  gc_col_no_acct_1         CONSTANT VARCHAR2(2) := '6';    -- 緑営１
  gc_col_no_acct_2         CONSTANT VARCHAR2(2) := '7';    -- 緑営２
  gc_col_no_guift          CONSTANT VARCHAR2(2) := '8';    -- ドリンクギフト
  gc_col_no_locat_chg      CONSTANT VARCHAR2(2) := '9';    -- 倉替
  gc_col_no_ret_goods      CONSTANT VARCHAR2(2) := '10';   -- 返品
  gc_col_no_other          CONSTANT VARCHAR2(2) := '11';   -- その他
  -- 払出
  gc_col_no_out_set        CONSTANT VARCHAR2(2) := '12';   -- セット
  gc_col_no_out_mtrl       CONSTANT VARCHAR2(2) := '13';   -- 返品原料へ
  gc_col_no_out_dismnt     CONSTANT VARCHAR2(2) := '14';   -- 解体半製品へ
  gc_col_no_out_pay        CONSTANT VARCHAR2(2) := '15';   -- 有償
  gc_col_no_out_trnsfr     CONSTANT VARCHAR2(2) := '16';   -- 振替有償
  gc_col_no_out_point      CONSTANT VARCHAR2(2) := '17';   -- 拠点
  gc_col_no_out_guift      CONSTANT VARCHAR2(2) := '18';   -- ドリンクギフト
  gc_col_no_out_other      CONSTANT VARCHAR2(2) := '19';   -- その他
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      exec_date_from      VARCHAR2(6)                              -- 処理年月(from,'YYYYMM'形式)
     ,exec_date_to        VARCHAR2(6)                              -- 処理年月(to,  'YYYYMM'形式)
     ,goods_class         mtl_categories_b.segment1%TYPE           -- 商品区分
     ,item_class          mtl_categories_b.segment1%TYPE           -- 品目区分
     ,rcv_pay_div         xxcmn_rcv_pay_mst_prod_v.rcv_pay_div%TYPE -- 受払区分
     ,crowd_kind          fnd_lookup_values.meaning%TYPE           -- 群種別
     ,crowd_code          mtl_categories_b.segment1%TYPE           -- 群コード
     ,acct_crowd_code     mtl_categories_b.segment1%TYPE           -- 経理群コード
    );
--
  -- 受払残高表データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD(
      item_code             ic_item_mst_b.item_no%TYPE              -- 品目コード
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE   -- 品目名称
     ,unit_price            cm_cmpt_dtl.cmpnt_cost%TYPE             -- 標準原価
     ,raw_material_cost     cm_cmpt_dtl.cmpnt_cost%TYPE             -- 原料費
     ,agein_cost            cm_cmpt_dtl.cmpnt_cost%TYPE             -- 再製費
     ,material_cost         cm_cmpt_dtl.cmpnt_cost%TYPE             -- 資材費
     ,pack_cost             cm_cmpt_dtl.cmpnt_cost%TYPE             -- 包装費
     ,other_expense_cost    cm_cmpt_dtl.cmpnt_cost%TYPE             -- その他経費
     ,crowd_code            mtl_categories_b.segment1%TYPE          -- 群コード
     ,crowd_low             mtl_categories_b.segment1%TYPE          -- 群コード（小）
     ,crowd_mid             mtl_categories_b.segment1%TYPE          -- 群コード（中）
     ,crowd_high            mtl_categories_b.segment1%TYPE          -- 群コード（大）
     ,trans_qty             ic_tran_pnd.trans_qty%TYPE              -- 取引数量
    );
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
--
  ------------------------------
  -- ヘッダ情報取得用
  ------------------------------
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- 担当者
  gv_print_class_name       fnd_lookup_values.meaning%TYPE;               -- 帳票種別名
  gv_goods_class_name       mtl_categories_tl.description%TYPE;           -- 商品区分名
  gv_rcv_pay_div_name       fnd_lookup_values.meaning%TYPE;               -- 受払区分名
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;           -- 群種別名
--
  ------------------------------
  -- 条件取得用
  ------------------------------
  gv_exec_year_month_bef    VARCHAR2(6);       -- 処理年月の前月
  gd_exec_start             DATE;             -- 処理年月の開始日
  gd_exec_end               DATE;             -- 処理年月の終了日
  gv_exec_start             VARCHAR2(20);     -- 処理年月の開始日
  gv_exec_end               VARCHAR2(20);     -- 処理年月の終了日
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- 帳票ID
  gd_exec_date              DATE         ;    -- 実施日
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER DEFAULT 0 ;        -- ＸＭＬデータタグ表のインデックス
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
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    -- プログラム名
    cv_prg_name           CONSTANT VARCHAR2(100) := 'prc_initialize';
    --受払区分
    cv_div_type           CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_NEW_ACCOUNT_DIV';
    --処理年月(FROM)のエラー
    cv_err_exec_date_from CONSTANT VARCHAR2(20) := '処理年月(FROM)';
    --処理年月(TO)のエラー
    cv_err_exec_date_to   CONSTANT VARCHAR2(20) := '処理年月(TO)';
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
    -- *** ローカル定数 ***
    lc_f_time          CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time          CONSTANT VARCHAR2(10) := ' 23:59:59';
    -- *** ローカル変数 ***
--
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
    -- 商品区分取得
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_goods_class_name
      FROM   xxcmn_categories2_v cat
      WHERE  cat.category_set_name = gc_cat_set_goods_class
      AND    cat.segment1          = ir_param.goods_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 受払区分取得
    -- ====================================================
    BEGIN
      SELECT xlvv.meaning
      INTO   gv_rcv_pay_div_name
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_div_type
      AND    lookup_code = ir_param.rcv_pay_div
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 日付情報取得
    -- ====================================================
    -- 処理年月・開始日
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.exec_date_from, gc_char_y_format);
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
    -- エラー処理
    IF ( gd_exec_start IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_err_exec_date_from
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_date_from ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    -- 処理年月・終了日
    gd_exec_end   := LAST_DAY(FND_DATE.STRING_TO_DATE(ir_param.exec_date_to, gc_char_y_format));
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_f_time;
    -- エラー処理
    IF ( gd_exec_end IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_err_exec_date_to
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_date_to ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(J-1)
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
    -- 各文書タイプ
    cv_doc_type_xfer          CONSTANT VARCHAR2(4) := 'XFER';
    cv_doc_type_trni          CONSTANT VARCHAR2(4) := 'TRNI';
    cv_doc_type_prod          CONSTANT VARCHAR2(4) := 'PROD';
    cv_doc_type_adji          CONSTANT VARCHAR2(4) := 'ADJI';
    cv_doc_type_porc          CONSTANT VARCHAR2(4) := 'PORC';
    cv_doc_type_omso          CONSTANT VARCHAR2(4) := 'OMSO';
    -- 完了フラグ
    cv_completed_ind          CONSTANT VARCHAR2(4) := '1';
    -- 在庫調整事由コード
-- 2008/10/24 v1.10 ADD START
    gv_reason_code_trni       CONSTANT VARCHAR2(4) := 'X122';
    cv_reason_code_mokusi_u   CONSTANT VARCHAR2(4) := 'X943'; -- 黙視品目受入
    cv_reason_code_sonota_u   CONSTANT VARCHAR2(4) := 'X950'; -- その他受入
-- 2008/10/24 v1.10 ADD END
    cv_reason_code_henpin     CONSTANT VARCHAR2(4) := 'X201'; -- 仕入先返品
    cv_reason_code_hamaoka    CONSTANT VARCHAR2(4) := 'X988'; -- 浜岡受入
    cv_reason_code_aitezaiko  CONSTANT VARCHAR2(4) := 'X977'; -- 相手先在庫
    cv_reason_code_idouteisei CONSTANT VARCHAR2(4) := 'X123'; -- 移動実績訂正
    cv_reason_code_mokusi     CONSTANT VARCHAR2(4) := 'X942'; -- 黙視品目受払
    cv_reason_code_sonota     CONSTANT VARCHAR2(4) := 'X951'; -- その他受払
    -- 原価管理区分
    cv_cost_manage_code       CONSTANT VARCHAR2(4) := '1'; -- 標準原価
    -- 日本
    cv_jpn                    CONSTANT VARCHAR2(4) := 'JA';
    -- 受払区分
    cv_rcv_pay_div_plus       CONSTANT VARCHAR2(3) := '1';
    cv_rcv_pay_div_minus      CONSTANT VARCHAR2(3) := '-1';
    -- 取引区分
    cv_dealings_div_hinsyu    CONSTANT VARCHAR2(3) := '308'; -- 品種振替
    cv_dealings_div_hinmoku   CONSTANT VARCHAR2(3) := '309'; -- 品目振替
--
    -- *** ローカル・変数 ***
-- 2008/10/24 v1.10 UPDATE START
    /*lv_from_xfer    VARCHAR2(32000) ; -- 移動積送あり
    lv_from_trni    VARCHAR2(32000) ; -- 移動積送なし
    lv_from_prod_1  VARCHAR2(32000) ; -- 生産関連：reverse_id is null
    lv_from_adji_1  VARCHAR2(32000) ; -- 在庫調整：下記以外のデータ全て
    lv_from_adji_2  VARCHAR2(32000) ; -- 在庫調整：仕入先返品
    lv_from_adji_3  VARCHAR2(32000) ; -- 在庫調整：浜岡受入
    lv_from_adji_4  VARCHAR2(32000) ; -- 在庫調整：相手先在庫
    lv_from_adji_5  VARCHAR2(32000) ; -- 在庫調整：移動実績訂正
    lv_from_porc_1  VARCHAR2(32000) ; -- 購買関連：文書タイプRMA
    lv_from_porc_2  VARCHAR2(32000) ; -- 購買関連：文書タイプPO
    lv_from_omso    VARCHAR2(32000) ; -- 受注関連
--
    -- UNION ALLするSQLの共通部
    lv_select_inner VARCHAR2(32000) ;
    lv_where_inner  VARCHAR2(32000) ;
--
    lv_from         VARCHAR2(32000) ;
    lv_order_by     VARCHAR2(32000) ;
    lv_sql          VARCHAR2(32000) ;     -- データ取得用ＳＱＬ*/
    lv_select101_1    VARCHAR2(32000) ;
    lv_select101_2    VARCHAR2(32000) ;
    lv_select101_3    VARCHAR2(32000) ;
    lv_select101_4    VARCHAR2(32000) ;
    lv_select102_1    VARCHAR2(32000) ;
    lv_select102_2    VARCHAR2(32000) ;
    lv_select102_3    VARCHAR2(32000) ;
    lv_select102_4    VARCHAR2(32000) ;
    lv_select103_1    VARCHAR2(32000) ;
    lv_select103_2    VARCHAR2(32000) ;
    lv_select105_1    VARCHAR2(32000) ;
    lv_select105_2    VARCHAR2(32000) ;
    lv_select106_1    VARCHAR2(32000) ;
    lv_select106_2    VARCHAR2(32000) ;
    lv_select107_1    VARCHAR2(32000) ;
    lv_select107_2    VARCHAR2(32000) ;
    lv_select109_1    VARCHAR2(32000) ;
    lv_select109_2    VARCHAR2(32000) ;
    lv_select111_1    VARCHAR2(32000) ;
    lv_select111_2    VARCHAR2(32000) ;
    lv_select201_1    VARCHAR2(32000) ;
    lv_select201_2    VARCHAR2(32000) ;
    lv_select202_03_1 VARCHAR2(32000) ;
    lv_select202_03_2 VARCHAR2(32000) ;
    lv_select3xx_1    VARCHAR2(32000) ;
-- 2012/01/11 v1.27 DEL START
--    lv_select31x_1    VARCHAR2(32000) ;
-- 2012/01/11 v1.27 DEL END
    lv_select4xx_1    VARCHAR2(32000) ;
    lv_select4xx_2    VARCHAR2(32000) ;
    lv_select4xx_3    VARCHAR2(32000) ;
    lv_select5xx_1    VARCHAR2(32000) ;
-- 2012/01/11 v1.27 DEL START
--    lv_select5xx_2    VARCHAR2(32000) ;
-- 2012/01/11 v1.27 DEL END
    lv_select5xx_3    VARCHAR2(32000) ;
    lv_select504_09_1 VARCHAR2(32000) ;
    lv_select504_09_2 VARCHAR2(32000) ;
    lv_select504_09_3 VARCHAR2(32000) ;
--
    lv_where_category_crowd  VARCHAR2(32000) ;
    lv_where_in_crowd        VARCHAR2(32000) ;
    lv_order_by              VARCHAR2(32000) ;
--
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/24 v1.10 UPDATE END
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    get_data_cur101    ref_cursor;
    get_data_cur102    ref_cursor;
    get_data_cur103    ref_cursor;
    get_data_cur105    ref_cursor;
    get_data_cur106    ref_cursor;
    get_data_cur107    ref_cursor;
    get_data_cur109    ref_cursor;
    get_data_cur111    ref_cursor;
    get_data_cur201    ref_cursor;
    get_data_cur202_03 ref_cursor;
    get_data_cur3xx    ref_cursor;
    get_data_cur31x    ref_cursor;
    get_data_cur4xx    ref_cursor;
    get_data_cur5xx    ref_cursor;
    get_data_cur504_09 ref_cursor;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/10/24 v1.10 ADD START
    --===============================================================
    -- 検索条件.受払区分       ⇒ 101
    -- 対象取引区分(OMSO/PORC) ⇒ 101:資材出荷(対象外)
    --                            102:製品出荷
    --                            112:振替出荷_出荷
    --===============================================================
    lv_select101_1 :=
       -- '  SELECT /*+ leading ( itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm ) use_nl ( itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm ) */ '
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */ '
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '        OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id  = xoha.header_id'
    || '  AND    rsl.oe_order_line_id    = xola.line_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''102'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '        OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select101_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '     OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id  = xoha.header_id'
    || '  AND    rsl.oe_order_line_id    = xola.line_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    xola.request_item_code  <> xola.shipping_item_code'
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
--    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''112'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select101_3 :=
       '  SELECT /*+ leading (xoha xrpm ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha xrpm ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '        OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    ooha.header_id          = wdd.source_header_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xoha.header_id          = wdd.source_header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.line_id            = wdd.source_line_id'
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''102'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '       OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select101_4 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '       OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    xola.request_item_code  <> xola.shipping_item_code'
    || '  AND    ooha.header_id          = wdd.source_header_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xoha.header_id          = wdd.source_header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.line_id            = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
--    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''112'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
      ;
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 102
    -- 対象取引区分(OMSO/PORC) ⇒ 105:振替有償_出荷
    --                            108:商品振替有償_出荷
    --===============================================================
    lv_select102_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''105'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select102_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    gic5.item_id              = itp.item_id'
-- 2009/01/15 v1.23 N.Yoshida mod start
--    || '  AND    gic5.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
-- 2009/01/15 v1.23 N.Yoshida mod end
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''108'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select102_3 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''105'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select102_4 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    gic5.item_id              = itp.item_id'
-- 2009/01/15 v1.23 N.Yoshida mod start
--    || '  AND    gic5.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
-- 2009/01/15 v1.23 N.Yoshida mod end
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''108'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 103
    -- 対象取引区分(OMSO/PORC) ⇒ 105:有償
    --===============================================================
    lv_select103_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = itp.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''103'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '         OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select103_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '             iimb.item_no             item_code'            -- 品目コード
    || '            ,ximb.item_short_name     item_name'            -- 品目名称
    || '            ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '            ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '            ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '            ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '            ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '            ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '            ,mcb3.segment1                  crowd_code'     --群コード
    || '            ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '            ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '            ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '      FROM   ic_tran_pnd               itp'
    || '            ,wsh_delivery_details      wdd'
    || '            ,oe_order_headers_all      ooha'
    || '            ,oe_transaction_types_all  otta'
    || '            ,xxwsh_order_headers_all   xoha'
    || '            ,xxwsh_order_lines_all     xola'
    || '            ,ic_item_mst_b             iimb'
    || '            ,xxcmn_item_mst_b          ximb'
    || '            ,gmi_item_categories       gic1'
    || '            ,mtl_categories_b          mcb1'
    || '            ,gmi_item_categories       gic2'
    || '            ,mtl_categories_b          mcb2'
    || '            ,gmi_item_categories       gic3'
    || '            ,mtl_categories_b          mcb3'
    || '            ,xxcmn_stnd_unit_price_v   xsup'
    || '            ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '      WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '      AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '      AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '      AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '      AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '      AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '      AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '      AND    ooha.header_id            = wdd.source_header_id'
    || '      AND    otta.transaction_type_id  = ooha.order_type_id'
    || '      AND    ((otta.attribute4           <> ''2'')'
    || '             OR  (otta.attribute4       IS NULL))'
--    || '      AND    xoha.header_id            = ooha.header_id'
--    || '      AND    xola.line_id              = wdd.source_line_id'
    || '      AND    ooha.header_id            = wdd.source_header_id'
    || '      AND    xoha.header_id            = ooha.header_id'
    || '      AND    xoha.header_id            = wdd.source_header_id'
    || '      AND    xola.order_header_id      = xoha.order_header_id'
    || '      AND    xola.line_id              = wdd.source_line_id'
    || '      AND    xola.request_item_code    = xola.shipping_item_code'
    || '      AND    iimb.item_id              = itp.item_id'
    || '      AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '      AND    ximb.item_id              = itp.item_id'
    || '      AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '      AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '      AND    gic1.item_id              = itp.item_id'
    || '      AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '      AND    gic1.category_id          = mcb1.category_id'
    || '      AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '      AND    gic2.item_id              = itp.item_id'
    || '      AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '      AND    gic2.category_id          = mcb2.category_id'
    || '      AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '      AND    mcb2.segment1             = ''5'''
    || '      AND    gic3.item_id              = itp.item_id'
    || '      AND    gic3.category_id          = mcb3.category_id'
    || '      AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '      AND    xrpm.doc_type             = itp.doc_type'
    || '      AND    xrpm.doc_type             = ''OMSO'''
    || '      AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '      AND    xrpm.dealings_div         = ''103'''
    || '      AND    xoha.req_status           = ''08'''
    || '      AND    otta.attribute1           = ''2'''
--    || '      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '      AND    xrpm.shipment_provision_div = ''2'''
    || '      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '      AND    xrpm.item_div_origin      IS NOT NULL'
    || '      AND    xrpm.item_div_ahead       IS NOT NULL'
    || '      AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 104(対象外)
    -- 対象取引区分(OMSO/PORC) ⇒ 113:振替出荷_払出
    --===============================================================
--      CURSOR get_data_cur104 IS
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 105
    -- 対象取引区分(OMSO/PORC) ⇒ 107:商品振替有償_受入
    --===============================================================
    lv_select105_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''107'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select105_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''107'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 106
    -- 対象取引区分(OMSO/PORC) ⇒ 109:商品振替有償_払出
    --===============================================================
    lv_select106_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb2.item_no             = xola.request_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_origin      = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = iimb2.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic5.item_id              = iimb2.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_ahead'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select106_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb2.item_no             = xola.request_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_origin      = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = iimb2.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic5.item_id              = iimb2.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_ahead'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
-- 2008/12/02 v1.14 yoshida mod start
    --===============================================================
    -- 検索条件.受払区分       ⇒ 107
    -- 対象取引区分(OMSO/PORC) ⇒ 104:振替有償_受入
    --===============================================================
    lv_select107_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''104'''
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select107_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''104'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
-- 2008/12/02 v1.14 yoshida mod end
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 108(対象外)
    -- 対象取引区分(OMSO/PORC) ⇒ 106:振替有償_払出
    --===============================================================
--      CURSOR get_data_cur108 IS
--
-- 2008/12/02 v1.14 yoshida mod start
    --===============================================================
    -- 検索条件.受払区分       ⇒ 109
    -- 対象取引区分(OMSO/PORC) ⇒ 110:振替出荷_受入_原
    --===============================================================
    lv_select109_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
-- 2008/12/06 v1.16 miyata update start
--    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xrpm.dealings_div         = ''110'''
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/06 v1.16 miyata delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select109_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
-- 2008/12/06 v1.16 miyata update start
--    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xrpm.dealings_div         = ''110'''
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/06 v1.16 miyata delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/06 v1.16 miyata delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分       ⇒ 111
    -- 対象取引区分(OMSO/PORC) ⇒ 111:振替出荷_受入_半
    --===============================================================
    lv_select111_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''111'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/07 v1.17 yoshida delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/07 v1.17 yoshida delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select111_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''111'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/07 v1.17 yoshida delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/07 v1.17 yoshida delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
-- 2008/12/02 v1.14 yoshida mod end
    --===============================================================
    -- 検索条件.受払区分          ⇒ 201
    -- 対象取引区分(ADJI/PORC_PO) ⇒ 202:仕入
    --===============================================================
    lv_select201_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itc.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty'  -- 数量
    || '  FROM   ic_tran_cmp               itc'
--    || '        ,ic_adjs_jnl               iaj'
--    || '        ,ic_jrnl_mst               ijm'
--    || '        ,xxpo_rcv_and_rtn_txns     xrrt'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itc.trans_date         < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
-- 2012/01/11 v1.27 MOD END
--    || '  AND    iaj.trans_type          = itc.doc_type'
--    || '  AND    iaj.doc_id              = itc.doc_id'
--    || '  AND    iaj.doc_line            = itc.doc_line'
--    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_henpin || ''''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select201_2 :=
       '  SELECT /*+ leading ( itp gic1 mcb1 gic2 mcb2 rsl rt xrpm ) use_nl ( itp gic1 mcb1 gic2 mcb2 rsl rt xrpm ) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,rcv_transactions          rt'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    itp.trans_date            >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itp.trans_date            <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
    || '  AND    itp.trans_date            < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| ''')) + 1'
-- 2012/01/11 v1.27 MOD END
    || '  AND    rsl.shipment_header_id    = itp.doc_id'
    || '  AND    rsl.line_num              = itp.doc_line'
    || '  AND    rsl.source_document_code  = ''PO'''
    || '  AND    rt.shipment_line_id       = rsl.shipment_line_id'
    || '  AND    rt.transaction_id         = itp.line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.source_document_code = rsl.source_document_code'
    || '  AND    xrpm.transaction_type     = rt.transaction_type'
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
-- 2009/04/10 v1.25 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/04/10 v1.25 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分          ⇒ 202
    --                            ⇒ 203
    -- 対象取引区分(OMSO/PORC)    ⇒ 201:倉替
    --                            ⇒ 203:返品
    --===============================================================
    lv_select202_03_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_porc || ''''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''201'',''203'')'
    || '  AND    otta.attribute1         = ''3'''
    || '  AND    xrpm.shipment_provision_div = ''3'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select202_03_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_omso || ''''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''201'',''203'')'
    || '  AND    otta.attribute1           = ''3'''
    || '  AND    xrpm.shipment_provision_div = ''3'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分          ⇒ 301
    --                            ⇒ 302
    --                            ⇒ 303
    --                            ⇒ 304
    --                            ⇒ 305
    --                            ⇒ 311
    --                            ⇒ 312
    --                            ⇒ 313
    --                            ⇒ 314
    --                            ⇒ 318
    --                            ⇒ 319
    -- 対象取引区分(PROD)         ⇒ 313:解体半製品
    --                            ⇒ 314:返品原料
    --                            ⇒ 301:沖縄
    --                            ⇒ 309:品目振替
    --                            ⇒ 311:包装
    --                            ⇒ 307:セット
    --===============================================================
    lv_select3xx_1 :=
       '  SELECT /*+ leading (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,gme_material_details      gmd'
    || '        ,gme_batch_header          gbh'
    || '        ,gmd_routings_b            grb'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_prod || ''''
    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
    || '  AND    itp.reverse_id          IS NULL'
    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.trans_date          < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
-- 2012/01/11 v1.27 MOD END
    || '  AND    gmd.batch_id            = itp.doc_id'
    || '  AND    gmd.line_no             = itp.doc_line'
    || '  AND    gbh.batch_id            = gmd.batch_id'
    || '  AND    grb.routing_id          = gbh.routing_id'
    || '  AND    iimb.item_id            = itp.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id            = itp.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itp.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itp.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itp.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type           = itp.doc_type'
    || '  AND    xrpm.line_type          = itp.line_type'
    || '  AND    xrpm.dealings_div       <> ''' || cv_dealings_div_hinsyu || ''''
    || '  AND    xrpm.dealings_div       <> ''' || cv_dealings_div_hinmoku || ''''
    || '  AND    xrpm.routing_class      <> ''70'''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.line_type          = gmd.line_type'
    || '  AND    xrpm.routing_class      = grb.routing_class'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    || '  AND    ( ( ( gmd.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )'
    || '         OR ( xrpm.hit_in_div        = gmd.attribute5 ) )'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
-- 2012/01/11 v1.27 DEL START
-- v1.27対応コメント：利用が無い（対象データが無い）ことが判明した為、削除
--    --===============================================================
--    -- 検索条件.受払区分          ⇒ 313
--    --                            ⇒ 314
--    -- 対象取引区分(PROD)         ⇒ 309:
--    --===============================================================
--    lv_select31x_1 :=
--       '  SELECT /*+ leading (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */'
--    || '         iimb.item_no             item_code'            -- 品目コード
--    || '        ,ximb.item_short_name     item_name'            -- 品目名称
--    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
--    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
--    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
--    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
--    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
--    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
--    || '        ,mcb3.segment1                  crowd_code'     --群コード
--    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
--    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
--    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
--    || '  FROM   ic_tran_pnd               itp'
--    || '        ,gme_material_details      gmd'
--    || '        ,gme_batch_header          gbh'
--    || '        ,gmd_routings_b            grb'
--    || '        ,ic_item_mst_b             iimb'
--    || '        ,xxcmn_item_mst_b          ximb'
--    || '        ,gmi_item_categories       gic1'
--    || '        ,mtl_categories_b          mcb1'
--    || '        ,gmi_item_categories       gic2'
--    || '        ,mtl_categories_b          mcb2'
--    || '        ,gmi_item_categories       gic3'
--    || '        ,mtl_categories_b          mcb3'
--    || '        ,xxcmn_stnd_unit_price_v   xsup'
--    || '        ,xxcmn_rcv_pay_mst         xrpm'
---- 2009/03/10 v1.24 ADD START
--    || '        ,ic_whse_mst               iwm'
---- 2009/03/10 v1.24 ADD END
--    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_prod || ''''
--    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
--    || '  AND    itp.reverse_id          IS NULL'
--    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
---- 2012/01/11 v1.27 MOD START
----    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
--    || '  AND    itp.trans_date          < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
---- 2012/01/11 v1.27 MOD END
--    || '  AND    gmd.batch_id            = itp.doc_id'
--    || '  AND    gmd.line_no             = itp.doc_line'
--    || '  AND    gbh.batch_id            = gmd.batch_id'
--    || '  AND    grb.routing_id          = gbh.routing_id'
--    || '  AND    iimb.item_id            = itp.item_id'
--    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
--    || '  AND    ximb.item_id            = iimb.item_id'
--    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
--    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
--    || '  AND    gic1.item_id            = itp.item_id'
--    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
--    || '  AND    gic1.category_id        = mcb1.category_id'
--    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
--    || '  AND    gic2.item_id            = itp.item_id'
--    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
--    || '  AND    gic2.category_id        = mcb2.category_id'
--    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
--    || '  AND    gic3.item_id            = itp.item_id'
--    || '  AND    gic3.category_id        = mcb3.category_id'
--    || '  AND    xsup.item_id            = itp.item_id'
--    || '  AND    xsup.start_date_active <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active   >= TRUNC(itp.trans_date)'
--    || '  AND    xrpm.doc_type           = itp.doc_type'
--    || '  AND    xrpm.line_type          = itp.line_type'
--    || '  AND    xrpm.routing_class      = ''70'''
--    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
--    || '  AND    xrpm.line_type          = gmd.line_type'
--    || '  AND    xrpm.routing_class      = grb.routing_class'
--    || '  AND    xrpm.break_col_10       IS NOT NULL'
--    || '  AND    ( ( ( gmd.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )'
--    || '         OR ( xrpm.hit_in_div        = gmd.attribute5 ) )'
--    || '  AND    (EXISTS (SELECT 1'
--    || '                  FROM   gme_material_details gmd2'
--    || '                        ,gmi_item_categories  gic'
--    || '                        ,mtl_categories_b     mcb'
--    || '                  WHERE  gmd2.batch_id   = gmd.batch_id'
--    || '                  AND    gmd2.line_no    = gmd.line_no'
--    || '                  AND    gmd2.line_type  = -1'
--    || '                  AND    gic.item_id     = gmd2.item_id'
--    || '                  AND    gic.category_set_id = ''' || cn_item_class_id || ''''
--    || '                  AND    gic.category_id = mcb.category_id'
--    || '                  AND    mcb.segment1    = xrpm.item_div_origin))'
--    || '  AND    (EXISTS (SELECT 1'
--    || '                  FROM   gme_material_details gmd3'
--    || '                        ,gmi_item_categories  gic'
--    || '                        ,mtl_categories_b     mcb'
--    || '                  WHERE  gmd3.batch_id   = gmd.batch_id'
--    || '                  AND    gmd3.line_no    = gmd.line_no'
--    || '                  AND    gmd3.line_type  = 1'
--    || '                  AND    gic.item_id     = gmd3.item_id'
--    || '                  AND    gic.category_set_id = ''' || cn_item_class_id || ''''
--    || '                  AND    gic.category_id = mcb.category_id'
--    || '                  AND    mcb.segment1    = xrpm.item_div_ahead))'
---- 2009/03/10 v1.24 ADD START
--    || '  AND    iwm.whse_code             = itp.whse_code'
--    || '  AND    iwm.attribute1            = ''0'''
---- 2009/03/10 v1.24 ADD END
--    ;
-- 2012/01/11 v1.27 DEL END
--
    --===============================================================
    -- 検索条件.受払区分             ⇒ 401
    --                               ⇒ 402
    -- 対象取引区分(ADJI/TRNI/XFER)  ⇒ 401:倉庫移動_入庫
    --                               ⇒ 402:倉庫移動_出庫
    --===============================================================
    lv_select4xx_1 :=
       '  SELECT /*+ leading (xmrh xmrl ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/11 v1.18 UPDATE START
--    || '        ,ABS(itc.trans_qty) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
-- 2008/12/22 v1.22 UPDATE START
--    || '        ,NVL(itc.trans_qty, 0)          trans_qty'  -- 数量
    || '        ,NVL(itc.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty'  -- 数量
-- 2008/12/22 v1.22 UPDATE START
-- 2008/12/11 v1.18 UPDATE END
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_adjs_jnl               iaj'
    || '        ,ic_jrnl_mst               ijm'
    || '        ,xxinv_mov_req_instr_lines xmrl'
    || '        ,xxinv_mov_req_instr_headers xmrh'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
--    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrh.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id'
    || '  AND    iaj.trans_type          = itc.doc_type'
    || '  AND    iaj.doc_id              = itc.doc_id'
    || '  AND    iaj.doc_line            = itc.doc_line'
    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)'
    || '  AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itc.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itc.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xmrh.actual_arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xmrh.actual_arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_idouteisei || ''''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/12/11 v1.18 UPDATE START
/*
    || '  AND    xrpm.rcv_pay_div       = CASE'
    || '                                    WHEN itc.trans_qty >= 0 THEN'
    || '                                      ''' || cv_rcv_pay_div_plus || ''''
    || '                                    WHEN itc.trans_qty <  0 THEN'
    || '                                      ''' || cv_rcv_pay_div_minus || ''''
    || '                                    ELSE xrpm.rcv_pay_div'
    || '                                  END'
*/
    || '  AND    xrpm.rcv_pay_div       = CASE'
    || '                                    WHEN itc.trans_qty >= 0 THEN'
    || '                                      ''' || cv_rcv_pay_div_minus || ''''
    || '                                    WHEN itc.trans_qty <  0 THEN'
    || '                                      ''' || cv_rcv_pay_div_plus || ''''
    || '                                    ELSE xrpm.rcv_pay_div'
    || '                                  END'
-- 2008/12/11 v1.18 UPDATE END
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select4xx_2 :=
       '  SELECT /*+ leading (xmrih xmril ixm itp xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrih xmril ixm itp xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_pnd               itp'
    || '        ,ic_xfer_mst               ixm'
    || '        ,xxinv_mov_req_instr_lines xmril'
    || '        ,xxinv_mov_req_instr_headers xmrih'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_xfer || ''''
    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrih.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.mov_hdr_id         = xmril.mov_hdr_id'
    || '  AND    ixm.transfer_id         = itp.doc_id'
--    || '  AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)'
    || '  AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)'
    || '  AND    iimb.item_id            = itp.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id            = itp.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itp.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itp.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xmrh.actual_arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xmrh.actual_arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type           = itp.doc_type'
    || '  AND    xrpm.reason_code        = itp.reason_code'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.rcv_pay_div        = CASE'
    || '                                     WHEN itp.trans_qty >= 0 THEN'
    || '                                          ''' || cv_rcv_pay_div_plus || ''''
    || '                                     ELSE ''' || cv_rcv_pay_div_minus || ''''
    || '                                   END'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select4xx_3 :=
       '  SELECT /*+ leading (xmrih xmril ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrih xmril ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_adjs_jnl               iaj'
    || '        ,ic_jrnl_mst               ijm'
    || '        ,xxinv_mov_req_instr_lines xmril'
    || '        ,xxinv_mov_req_instr_headers xmrih'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = ''' || cv_doc_type_trni || ''''
    || '  AND    itc.reason_code         = ''' || gv_reason_code_trni || ''''
--    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrih.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.mov_hdr_id         = xmril.mov_hdr_id'
    || '  AND    iaj.trans_type          = itc.doc_type'
    || '  AND    iaj.doc_id              = itc.doc_id'
    || '  AND    iaj.doc_line            = itc.doc_line'
    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)'
    || '  AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itc.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itc.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xmrih.actual_arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xmrih.actual_arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type           = itc.doc_type'
    || '  AND    xrpm.rcv_pay_div        = itc.line_type'
    || '  AND    xrpm.reason_code        = itc.reason_code'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.rcv_pay_div        = CASE'
    || '                                     WHEN itc.trans_qty >= 0 THEN'
    || '                                          ''' || cv_rcv_pay_div_plus || ''''
    || '                                     ELSE ''' || cv_rcv_pay_div_minus || ''''
    || '                                   END'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分             ⇒ 501
    --                               ⇒ 502
    --                               ⇒ 504
    --                               ⇒ 506
    --                               ⇒ 508
    --                               ⇒ 507
    --                               ⇒ 509
    --                               ⇒ 511
    --                               ⇒ 503
    -- 対象取引区分(ADJI)            ⇒ 501:相手先在庫
    --                               ⇒ 502:その他
    --                               ⇒ 503:経理払出
    --                               ⇒ 505:総務払出
    --                               ⇒ 506:棚卸減
    --                               ⇒ 507:棚卸増
    --                               ⇒ 508:転売
    --                               ⇒ 510:浜岡
    --                               ⇒ 511:黙視品目払出
    --                               ⇒ 512:黙視品目受入
    --===============================================================
    lv_select5xx_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/14 v1.20 UPDATE START
--    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '        ,CASE WHEN xrpm.reason_code = ''X911'''
    || '              THEN itc.trans_qty'
    || '              ELSE itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END  trans_qty'                                -- 数量
-- 2008/12/14 v1.20 UPDATE END
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itc.trans_date         < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
-- 2012/01/11 v1.27 MOD END
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code       IN (''X911'''
    || '                                   ,''X912'''
    || '                                   ,''X921'''
    || '                                   ,''X922'''
    || '                                   ,''X931'''
    || '                                   ,''X932'''
    || '                                   ,''X941'''
    || '                                   ,''X952'''
    || '                                   ,''X953'''
    || '                                   ,''X954'''
    || '                                   ,''X955'''
    || '                                   ,''X956'''
    || '                                   ,''X957'''
    || '                                   ,''X958'''
    || '                                   ,''X959'''
    || '                                   ,''X960'''
    || '                                   ,''X961'''
    || '                                   ,''X962'''
    || '                                   ,''X963'''
-- 2008/11/19 v1.12 UPDATE START
--    || '                                   ,''X964'')'
    || '                                   ,''X964'''
    || '                                   ,''X965'''
    || '                                   ,''X966'')'
-- 2008/11/19 v1.12 UPDATE END
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
-- 2012/01/11 v1.27 DEL START
-- v1.27対応コメント：利用が無い(対象データが無い)ことが判明した為、削除
--    lv_select5xx_2 :=
--       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
--    || '         iimb.item_no             item_code'            -- 品目コード
--    || '        ,ximb.item_short_name     item_name'            -- 品目名称
--    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
--    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
--    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
--    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
--    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
--    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
--    || '        ,mcb3.segment1                  crowd_code'     --群コード
--    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
--    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
--    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
--    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
--    || '  FROM   ic_tran_cmp               itc'
----    || '        ,ic_adjs_jnl               iaj'
----    || '        ,ic_jrnl_mst               ijm'
----    || '        ,xxpo_namaha_prod_txns     xnpt'
--    || '        ,ic_item_mst_b             iimb'
--    || '        ,xxcmn_item_mst_b          ximb'
--    || '        ,gmi_item_categories       gic1'
--    || '        ,mtl_categories_b          mcb1'
--    || '        ,gmi_item_categories       gic2'
--    || '        ,mtl_categories_b          mcb2'
--    || '        ,gmi_item_categories       gic3'
--    || '        ,mtl_categories_b          mcb3'
--    || '        ,xxcmn_stnd_unit_price_v   xsup'
--    || '        ,xxcmn_rcv_pay_mst         xrpm'
---- 2009/03/10 v1.24 ADD START
--    || '        ,ic_whse_mst               iwm'
---- 2009/03/10 v1.24 ADD END
--    || '  WHERE  itc.doc_type            = xrpm.doc_type'
--    || '  AND    itc.reason_code         = xrpm.reason_code'
--    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
---- 2012/01/11 v1.27 MOD START
----    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
--    || '  AND    itc.trans_date         < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
---- 2012/01/11 v1.27 MOD END
----    || '  AND    iaj.trans_type          = itc.doc_type'
----    || '  AND    iaj.doc_id              = itc.doc_id'
----    || '  AND    iaj.doc_line            = itc.doc_line'
----    || '  AND    ijm.journal_id          = iaj.journal_id'
----    || '  AND    xnpt.entry_number       = TO_NUMBER(ijm.attribute1)'
--    || '  AND    iimb.item_id            = itc.item_id'
--    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
--    || '  AND    ximb.item_id            = iimb.item_id'
--    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
--    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
--    || '  AND    gic1.item_id            = itc.item_id'
--    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
--    || '  AND    gic1.category_id        = mcb1.category_id'
--    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
--    || '  AND    gic2.item_id            = itc.item_id'
--    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
--    || '  AND    gic2.category_id        = mcb2.category_id'
--    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
--    || '  AND    gic3.item_id            = itc.item_id'
--    || '  AND    gic3.category_id        = mcb3.category_id'
--    || '  AND    xsup.item_id            = itc.item_id'
--    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
--    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
--    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
--    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_hamaoka || ''''
--    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
--    || '  AND    xrpm.break_col_10       IS NOT NULL'
---- 2009/03/10 v1.24 ADD START
--    || '  AND    iwm.whse_code             = itc.whse_code'
--    || '  AND    iwm.attribute1            = ''0'''
---- 2009/03/10 v1.24 ADD END
--    ;
-- 2012/01/11 v1.27 DEL END
--
    lv_select5xx_3 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- 数量
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itc.trans_date         < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
-- 2012/01/11 v1.27 MOD END
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        IN (''' || cv_reason_code_mokusi || ''',''' || cv_reason_code_sonota || ''',''' || cv_reason_code_mokusi_u || ''',''' || cv_reason_code_sonota_u || ''')'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/11/19 v1.12 DELETE START
--    || '  AND    xrpm.rcv_pay_div       = CASE'
--    || '                                    WHEN itc.trans_qty >= 0 THEN'
--    || '                                         ''' || cv_rcv_pay_div_plus || ''''
--    || '                                    ELSE ''' || cv_rcv_pay_div_minus || ''''
--    || '                                  END'
-- 2008/11/19 v1.12 DELETE END
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    --===============================================================
    -- 検索条件.受払区分             ⇒ 505
    --                               ⇒ 510
    -- 対象取引区分(ADJI/OMSO/PORC)  ⇒ 504:見本
    --                               ⇒ 509:廃却
    --===============================================================
    lv_select504_09_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty' -- 数量
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
-- 2012/01/11 v1.27 MOD START
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itc.trans_date         < LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || ''')) + 1'
-- 2012/01/11 v1.27 MOD END
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        IN (''X931'''
    || '                                    ,''X932'')'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '  AND    xrpm.rcv_pay_div       = CASE'
--    || '                                    WHEN itc.trans_qty >= 0 THEN'
--    || '                                         ''' || cv_rcv_pay_div_plus || ''''
--    || '                                    ELSE ''' || cv_rcv_pay_div_minus || ''''
--    || '                                  END'
-- 2008/12/13 v1.19 T.Ohashi mod end
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itc.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select504_09_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '        ,itp.trans_qty            trans_qty'            -- 数量
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'            -- 数量
-- 2008/12/13 v1.19 T.Ohashi mod end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_porc || ''''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''504'',''509'')'
    || '  AND    xrpm.stock_adjustment_div = otta.attribute4'
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
--
    lv_select504_09_3 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */'
    || '         iimb.item_no             item_code'            -- 品目コード
    || '        ,ximb.item_short_name     item_name'            -- 品目名称
    || '        ,xsup.stnd_unit_price     unit_price'           -- 原価：標準原価
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- 原価：原料費
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- 原価：再製費
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- 原価：資材費
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- 原価：包装費
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- 原価：その他経費
    || '        ,mcb3.segment1                  crowd_code'     --群コード
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --小群
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --中群
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --大群
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '        ,itp.trans_qty            trans_qty'            -- 数量
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'            -- 数量
-- 2008/12/13 v1.19 T.Ohashi mod end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
-- 2009/03/10 v1.24 ADD START
    || '        ,ic_whse_mst               iwm'
-- 2009/03/10 v1.24 ADD END
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
-- 2008/12/15 v1.21 N.Yoshida add start
    || '  AND    xoha.latest_external_flag = ''Y'''
-- 2008/12/15 v1.21 N.Yoshida add end
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
-- 2009/05/29 MOD START
--    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
--    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xsup.start_date_active   <= TRUNC(xoha.arrival_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(xoha.arrival_date)'
-- 2009/05/29 MOD END
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_omso || ''''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''504'',''509'')'
    || '  AND    xrpm.stock_adjustment_div = otta.attribute4'
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
-- 2009/03/10 v1.24 ADD START
    || '  AND    iwm.whse_code             = itp.whse_code'
    || '  AND    iwm.attribute1            = ''0'''
-- 2009/03/10 v1.24 ADD END
    ;
-- 2008/10/24 v1.10 ADD END
-- 2008/10/24 v1.10 DELETE START
    /*-- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
    -- INNER_SQLのSELECT部
    lv_select_inner := ' SELECT '
                    || ' ximv.item_no             item_code,          ' -- 品目コード
                    || ' ximv.item_short_name     item_name,          ' -- 品目名称
                    || ' xsup.stnd_unit_price     unit_price,         ' -- 原価：標準原価
                    || ' xsup.stnd_unit_price_gen raw_material_cost,  ' -- 原価：原料費
                    || ' xsup.stnd_unit_price_sai agein_cost,         ' -- 原価：再製費
                    || ' xsup.stnd_unit_price_shi material_cost,      ' -- 原価：資材費
                    || ' xsup.stnd_unit_price_hou pack_cost,          ' -- 原価：包装費
                    || ' xsup.stnd_unit_price_kei other_expense_cost, ' -- 原価：その他経費
                    ;
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- 群種別＝「3：郡別」が指定されている場合
      lv_select_inner := lv_select_inner
                      || 'xicv.crowd_code                crowd_code, '        --群コード
                      || 'SUBSTR(xicv.crowd_code, 1, 3)  crowd_low,  '         --小群
                      || 'SUBSTR(xicv.crowd_code, 1, 2)  crowd_mid,  '         --中群
                      || 'SUBSTR(xicv.crowd_code, 1, 1)  crowd_high,  '         --大群
                      ;
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- 群種別＝「4：経理郡別」が指定されている場合
      lv_select_inner := lv_select_inner
                      || 'xicv.acnt_crowd_code                crowd_code, '    --経理群コード
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 3)  crowd_low,  '     --小群
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 2)  crowd_mid,  '     --中群
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 1)  crowd_high,  '     --大群
                      ;
    END IF;
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    -- INNER_SQLのWHERE部
    lv_where_inner := ' AND it.trans_date '
                   || ' BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from
                                                            || gc_first_date
                                                            || ''', '''
                                                            || gc_char_format
                                                            || ''')'
                   || ' AND LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to
                                                                 || gc_first_date
                                                                 || ''', '''
                                                                 || gc_char_format
                                                                 || '''))'
                   || ' AND xlvv.lookup_type            = ''' || gc_lookup_type || ''' '
                   || ' AND xlvv.language               = ''' || cv_jpn || ''' '
                   || ' AND xlvv.source_lang            = ''' || cv_jpn || ''' '
                   || ' AND xlvv.attribute10            IS NOT NULL '
                   || ' AND (   (xlvv.start_date_active IS NULL) '
                   || '      OR (xlvv.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (xlvv.end_date_active   IS NULL) '
                   || '      OR (xlvv.end_date_active   >= TRUNC(it.trans_date))) '
                   || ' AND (   (ximv.start_date_active IS NULL) '
                   || '      OR (ximv.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (ximv.end_date_active   IS NULL) '
                   || '      OR (ximv.end_date_active   >= TRUNC(it.trans_date))) '
                   || ' AND ximv.cost_manage_code       = ''' || cv_cost_manage_code || ''' '
                   || ' AND ximv.item_id                = xicv.item_id '
                   || ' AND xicv.prod_class_code        = ''' || ir_param.goods_class || ''' '
                   || ' AND xicv.item_class_code        = ''' || ir_param.item_class || ''''
                   || ' AND (   (xsup.start_date_active IS NULL) '
                   || '      OR (xsup.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (xsup.end_date_active   IS NULL) '
                   || '      OR (xsup.end_date_active   >= TRUNC(it.trans_date))) '
                   ;
--
    -- ----------------------------------------------------
    -- パラメータで抽出が変わるwhere項目の生成
    -- ----------------------------------------------------
    -- 群種別＝「3：郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- 群コードが入力されている場合
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where_inner := lv_where_inner
                       || ' AND xicv.crowd_code = ''' || ir_param.crowd_code || ''''
                       ;
      END IF;
    END IF;
--
    -- 群種別＝「4：経理郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- 経理群コードが入力されている場合
       IF (ir_param.acct_crowd_code  IS NOT NULL) THEN
        lv_where_inner := lv_where_inner
                       || ' AND xicv.acnt_crowd_code = ''' || ir_param.acct_crowd_code || ''''
                       ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    -- 1:移動積送あり
    lv_from_xfer := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- 数量
                 || ' it.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                 -- from
                 || ' FROM '
                 || ' ic_tran_pnd               it,     '
                 || ' xxcmn_rcv_pay_mst_xfer_v  xrpmxv, '
                 || ' ic_xfer_mst               ixm,    ' -- ＯＰＭ在庫転送マスタ
                 || ' xxinv_mov_req_instr_lines xmril,  ' -- 移動依頼／指示明細（アドオン）
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報VIEW2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                 || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報VIEW
                 || ' WHERE '
                 || '     it.doc_type             = ''' || cv_doc_type_xfer || ''' '
                 || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                 || ' AND it.doc_type             = xrpmxv.doc_type '
                 || ' AND it.reason_code          = xrpmxv.reason_code '
                 || ' AND xrpmxv.rcv_pay_div      = CASE '
                 || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                               || cv_rcv_pay_div_plus  || ''' '
                 || '                                 ELSE ''' || cv_rcv_pay_div_minus || ''' '
                 || '                               END '
                 || ' AND it.doc_id               = ixm.transfer_id '
                 || ' AND ixm.attribute1          = xmril.mov_line_id '
                 || ' AND xrpmxv.dealings_div     = xlvv.meaning '
                 || ' AND xrpmxv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND it.item_id              = ximv.item_id '
                 || ' AND it.item_id              = xsup.item_id '
                 || lv_where_inner
                 ;
    -- 2:移動積送なし
    lv_from_trni := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- 数量
                 || ' it.trans_qty * TO_NUMBER(xrpmtv.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                 || ' FROM '
                 || ' ic_tran_cmp               it, '
                 || ' xxcmn_rcv_pay_mst_trni_v  xrpmtv, '
                 || ' ic_adjs_jnl               iaj, '    -- ＯＰＭ在庫調整ジャーナル
                 || ' ic_jrnl_mst               ijm, '    -- ＯＰＭジャーナルマスタ
                 || ' xxinv_mov_req_instr_lines xmril, '  -- 移動依頼／指示明細（アドオン）
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                 || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                 || ' WHERE '
                 || ' it.doc_type                 = ''' || cv_doc_type_trni || ''' '
                 || ' AND it.doc_type             = xrpmtv.doc_type '
                 || ' AND it.line_type            = xrpmtv.rcv_pay_div '
                 || ' AND it.reason_code          = xrpmtv.reason_code '
                 || ' AND xrpmtv.rcv_pay_div      = CASE '
                 || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                               || cv_rcv_pay_div_plus  || ''' '
                 || '                                 ELSE ''' || cv_rcv_pay_div_minus || ''' '
                 || '                               END '
                 || ' AND it.doc_type             = iaj.trans_type '
                 || ' AND it.doc_id               = iaj.doc_id '
                 || ' AND it.doc_line             = iaj.doc_line '
                 || ' AND iaj.journal_id          = ijm.journal_id '
                 || ' AND ijm.attribute1          = xmril.mov_line_id '
                 || ' AND xrpmtv.dealings_div     = xlvv.meaning '
                 || ' AND xrpmtv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND it.item_id              = ximv.item_id '
                 || ' AND it.item_id              = xsup.item_id '
                 || lv_where_inner
                 ;
    -- 3:生産関連：reverse_id is null
    lv_from_prod_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmpv.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                 it, '
                   || ' xxcmn_rcv_pay_mst_prod_v    xrpmpv, '
                   || ' xxcmn_lookup_values2_v      xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v           ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v    xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v     xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_prod || ''' '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND it.reverse_id           IS NULL '
                   || ' AND it.doc_type             = xrpmpv.doc_type '
                   || ' AND it.line_type            = xrpmpv.line_type '
                   || ' AND it.doc_id               = xrpmpv.doc_id '
                   || ' AND it.doc_line             = xrpmpv.doc_line '
                   || ' AND xrpmpv.dealings_div     <> ''' || cv_dealings_div_hinsyu || ''' '
                   || ' AND xrpmpv.dealings_div     <> ''' || cv_dealings_div_hinmoku || ''' '
                   || ' AND xrpmpv.dealings_div     = xlvv.meaning '
                   || ' AND xrpmpv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 4:在庫調整：(仕入先返品、浜岡受入、相手先在庫、移動実績訂正、黙視品目受払、その他受払以外)
    lv_from_adji_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it, '
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_henpin     || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_hamaoka    || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_aitezaiko  || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_idouteisei || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_mokusi     || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_sonota     || ''' '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 5:在庫調整：仕入先返品
    lv_from_adji_2 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it, '         -- opm完了在庫トラン
                   || ' ic_adjs_jnl               iaj, '        -- opm在庫調整ジャーナル
                   || ' ic_jrnl_mst               ijm, '        -- opmジャーナルマスタ
                   || ' xxpo_rcv_and_rtn_txns     xrrt, '       -- 受入返品実績アドオン
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_henpin || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xrrt.txns_id            = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 6:在庫調整：浜岡受入
    lv_from_adji_3 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   -- from
                   || ' FROM '
                   || ' ic_tran_cmp               it, '         -- opm完了在庫トラン
                   || ' ic_adjs_jnl               iaj, '        -- opm在庫調整ジャーナル
                   || ' ic_jrnl_mst               ijm, '        -- opmジャーナルマスタ
                   || ' xxpo_namaha_prod_txns     xnpt, '       -- 精算実績アドオン
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_hamaoka || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xnpt.entry_number       = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 7:在庫調整(黙視品目払出、その他払出)
    lv_from_adji_4 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it,     '
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   '
                   || ' xxcmn_item_mst2_v         ximv,   '
                   || ' xxcmn_item_categories6_v  xicv,   '
                   || ' xxcmn_stnd_unit_price_v   xsup    '
                   || ' WHERE '
                   || ' it.doc_type                = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type            = xrpmav.doc_type '
                   || ' AND (   it.reason_code     = ''' || cv_reason_code_mokusi || ''' '
                   || '      OR it.reason_code     = ''' || cv_reason_code_sonota || ''') '
                   || ' AND it.reason_code         = xrpmav.reason_code '
                   || ' AND xrpmav.rcv_pay_div     = CASE '
                   || '                                WHEN it.trans_qty >= 0 then '''
                                                                || cv_rcv_pay_div_plus  || ''' '
                   || '                                ELSE ''' || cv_rcv_pay_div_minus || ''' '
                   || '                              END '
                   || ' AND xrpmav.dealings_div    = xlvv.meaning '
                   || ' AND xrpmav.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id             = ximv.item_id '
                   || ' AND it.item_id             = xsup.item_id '
                   || lv_where_inner
                   ;
     -- 8:在庫調整：移動実績訂正
    lv_from_adji_5 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- 数量
                 || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it,     ' -- opm完了在庫トラン
                   || ' ic_adjs_jnl               iaj,    ' -- opm在庫調整ジャーナル
                   || ' ic_jrnl_mst               ijm,    ' -- opmジャーナルマスタ
                   || ' xxinv_mov_req_instr_lines xmrl,   ' -- 移動依頼/支持明細
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_idouteisei || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xmrl.mov_line_id        = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.rcv_pay_div      = CASE '
                   || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                        || cv_rcv_pay_div_minus || ''' '
                   || '                                 WHEN it.trans_qty <  0 THEN '''
                                                        || cv_rcv_pay_div_plus || ''' '
                   || '                                 ELSE xrpmav.rcv_pay_div '
                   || '                               END '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 9:購買関連：文書タイプRMA
    lv_from_porc_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START

                   || ' NVL2(xrpmprv.item_id, '
                   ||      ' it.trans_qty, '
                   ||      ' DECODE(xrpmprv.dealings_div_name,''' || gv_haiki || ''' '
                   ||      '       ,it.trans_qty '
                   ||      '       , ''' || gv_mihon || ''' '
                   ||      '       ,it.trans_qty '
                   ||      ',it.trans_qty * TO_NUMBER(xrpmprv.rcv_pay_div))) trans_qty ' -- 数量

                   || ' DECODE(xrpmprv.dealings_div_name,''' || gv_haiki || ''' '
                   || '       ,it.trans_qty '
                   || '       , ''' || gv_mihon || ''' '
                   || '       ,it.trans_qty '
                   || ',it.trans_qty * TO_NUMBER(xrpmprv.rcv_pay_div)) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                    it,      '
                   || ' xxcmn_rcv_pay_mst_porc_rma10_v xrpmprv, '
                   || ' xxcmn_lookup_values2_v         xlvv,    ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v              ximv,    ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v       xicv,    ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v        xsup     ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_porc || ''' '
                   || ' AND it.doc_id               = xrpmprv.doc_id '
                   || ' AND it.doc_line             = xrpmprv.doc_line '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND xrpmprv.dealings_div    = xlvv.meaning '
                   || ' AND xrpmprv.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND ximv.item_id            = NVL(xrpmprv.item_id,it.item_id) '
                   || ' AND xsup.item_id            = NVL(xrpmprv.item_id,it.item_id) '
                   || lv_where_inner
                   ;
    -- 10:購買関連：文書タイプPO
    lv_from_porc_2 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- 数量
                   || ' it.trans_qty * TO_NUMBER(xrpmppv.rcv_pay_div) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                 it, '
                   || ' xxcmn_rcv_pay_mst_porc_po_v xrpmppv, '
                   || ' xxcmn_lookup_values2_v      xlvv,   ' -- クイックコード情報view2
                   || ' xxcmn_item_mst2_v           ximv,   ' -- 品目情報ビュー
                   || ' xxcmn_item_categories6_v    xicv,   ' -- 品目カテゴリービュー
                   || ' xxcmn_stnd_unit_price_v     xsup    ' -- 標準原価情報view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_porc || ''' '
                   || ' AND it.doc_id               = xrpmppv.doc_id '
                   || ' AND it.doc_line             = xrpmppv.doc_line '
                   || ' AND it.line_id              = xrpmppv.line_id '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND xrpmppv.dealings_div    = xlvv.meaning '
                   || ' AND xrpmppv.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 11:受注関連
    lv_from_omso := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START

                 || ' NVL2(xrpmov.item_id, '
                 ||      ' it.trans_qty, '
                 ||      ' DECODE(xrpmov.dealings_div_name,''' || gv_haiki || ''' '
                 ||      '       ,it.trans_qty '
                 ||      '       , ''' || gv_mihon || ''' '
                 ||      '       ,it.trans_qty '
                 ||      ',it.trans_qty * TO_NUMBER(xrpmov.rcv_pay_div))) trans_qty ' -- 数量

                 || ' DECODE(xrpmov.dealings_div_name,''' || gv_haiki || ''' '
                 || '       ,it.trans_qty '
                 || '       , ''' || gv_mihon || ''' '
                 || '       ,it.trans_qty '
                 || ',it.trans_qty * TO_NUMBER(xrpmov.rcv_pay_div)) trans_qty ' -- 数量
-- 2008/08/28 v1.9 UPDATE END
                 || ' FROM '
                 || ' ic_tran_pnd               it, '
                 || ' xxcmn_rcv_pay_mst_omso_v  xrpmov, '
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- クイックコード情報view2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- 品目情報ビュー
                 || ' xxcmn_item_categories6_v  xicv,   ' -- 品目カテゴリービュー
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- 標準原価情報view
                 || ' WHERE '
                 || ' it.doc_type                 = ''' || cv_doc_type_omso || ''' '
                 || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                 || ' AND it.doc_type             = xrpmov.doc_type '
                 || ' AND it.line_detail_id       = xrpmov.doc_line '
                 || ' AND xrpmov.dealings_div     = xlvv.meaning '
                 || ' AND xrpmov.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND xrpmov.arrival_date >= '
                 || '     FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''','''
                                                      || gc_char_dt_format || ''')' -- 着荷日
                 || ' AND xrpmov.arrival_date <= '
                 || '     FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''
                                                      || gc_char_dt_format || ''')' -- 着荷日
                 || ' AND ximv.item_id            = NVL(xrpmov.item_id,it.item_id) '
                 || ' AND xsup.item_id            = NVL(xrpmov.item_id,it.item_id) '
                 || lv_where_inner
                 ;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_from := lv_from_xfer
            || ' UNION ALL '
            || lv_from_trni
            || ' UNION ALL '
            || lv_from_prod_1
            || ' UNION ALL '
            || lv_from_adji_1
            || ' UNION ALL '
            || lv_from_adji_2
            || ' UNION ALL '
            || lv_from_adji_3
            || ' UNION ALL '
            || lv_from_adji_4
            || ' UNION ALL '
            || lv_from_adji_5
            || ' UNION ALL '
            || lv_from_porc_1
            || ' UNION ALL '
            || lv_from_porc_2
            || ' UNION ALL '
            || lv_from_omso
            ;
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    -- 群種別＝「3：郡別」が指定されている場合
    lv_order_by := ' ORDER BY'
                || ' crowd_code'      -- 群コード
                || ',item_code'       -- 品目コード
                ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := lv_from || lv_order_by ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql ;
    -- バルクフェッチ
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE lc_ref ;*/
-- 2008/10/24 v1.10 DELETE END
-- 2008/10/24 v1.10 ADD START
   -- 追加条件の初期化
   lv_where_category_crowd := '';
   lv_where_in_crowd       := '';
--
   -- 追加条件の設定
   -- カテゴリ（群別）
   IF (ir_param.crowd_kind = gc_crowd_kind) THEN
     lv_where_category_crowd := '  AND    gic3.category_set_id      = ''' || cn_crowd_code_id || '''';
--
     -- 群コード
     IF (ir_param.crowd_code IS NOT NULL) THEN
       lv_where_in_crowd     := '  AND    mcb3.segment1          = ''' || ir_param.crowd_code || '''';
     END IF;
   -- カテゴリ（経理群別）
   ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
     lv_where_category_crowd := '  AND    gic3.category_set_id      = ''' || cn_acnt_crowd_code_id || '''';
--
     -- 経理群コード
     IF (ir_param.acct_crowd_code IS NOT NULL) THEN
       lv_where_in_crowd     := '  AND    mcb3.segment1           = ''' || ir_param.acct_crowd_code || '''';
     END IF;
   END IF;
--
   -- ＯＲＤＥＲ  ＢＹ句生成
   lv_order_by := ' ORDER BY'
                || ' crowd_code'      -- 群コード
                || ',item_code'       -- 品目コード
                ;
--
    -- 群別
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- 群コード未入力
      IF (ir_param.crowd_code  IS NULL) THEN
        --===============================================================
        -- 検索条件.受払区分       ⇒ 101
        -- 対象取引区分(OMSO/PORC) ⇒ 101:資材出荷(対象外)
        --                            102:製品出荷
        --                            112:振替出荷_出荷
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- オープン
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur101;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 102
        -- 対象取引区分(OMSO/PORC) ⇒ 105:振替有償_出荷
        --                            108:商品振替有償_出荷
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- オープン
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur102;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 103
        -- 対象取引区分(OMSO/PORC) ⇒ 105:有償
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- オープン
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur103;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 104(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 113:振替出荷_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur104;
--          -- バルクフェッチ
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur104;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 105
        -- 対象取引区分(OMSO/PORC) ⇒ 107:商品振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- オープン
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur105;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 106
        -- 対象取引区分(OMSO/PORC) ⇒ 109:商品振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- オープン
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur106;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 107
        -- 対象取引区分(OMSO/PORC) ⇒ 104:振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '107') THEN
          -- オープン
          OPEN  get_data_cur107 FOR lv_select107_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select107_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur107 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur107;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 108(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 106:振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur108;
--          -- バルクフェッチ
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur108;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 109
        -- 対象取引区分(OMSO/PORC) ⇒ 110:振替出荷_受入_原
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '109') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'受払区分：109') ;
          -- オープン
          OPEN  get_data_cur109 FOR lv_select109_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select109_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur109 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur109;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 111
        -- 対象取引区分(OMSO/PORC) ⇒ 111:振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '111') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'受払区分：111') ;
          -- オープン
          OPEN  get_data_cur111 FOR lv_select111_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select111_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur111 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur111;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 201
        -- 対象取引区分(ADJI/PORC_PO) ⇒ 202:仕入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- オープン
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur201;
    --===============================================================
    -- 検索条件.受払区分          ⇒ 202
    --                            ⇒ 203
    -- 対象取引区分(OMSO/PORC)    ⇒ 201:倉替
    --                            ⇒ 203:返品
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- オープン
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur202_03;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 301
        --                            ⇒ 302
        --                            ⇒ 303
        --                            ⇒ 304
        --                            ⇒ 305
        --                            ⇒ 311
        --                            ⇒ 312
        --                            ⇒ 318
        --                            ⇒ 319
        -- 対象取引区分(PROD)         ⇒ 313:解体半製品
        --                            ⇒ 314:返品原料
        --                            ⇒ 301:沖縄
        --                            ⇒ 309:品目振替
        --                            ⇒ 311:包装
        --                            ⇒ 307:セット
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- オープン
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur3xx;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 313
        --                            ⇒ 314
        --                            ⇒ 315
        --                            ⇒ 316
        -- 対象取引区分(PROD)         ⇒ 309:
        --                            ⇒ 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
-- 2012/01/11 v1.27 MOD START
--          -- オープン
--          OPEN  get_data_cur31x FOR lv_select31x_1
--                                 || lv_where_category_crowd
--                                 || lv_order_by;
--          -- バルクフェッチ
--          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur31x;
          NULL;
-- 2012/01/11 v1.27 MOD END
        --===============================================================
        -- 検索条件.受払区分             ⇒ 401
        --                               ⇒ 402
        -- 対象取引区分(ADJI/TRNI/XFER)  ⇒ 401:倉庫移動_入庫
        --                               ⇒ 402:倉庫移動_出庫
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- オープン
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur4xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 501
        --                               ⇒ 502
        --                               ⇒ 504
        --                               ⇒ 506
        --                               ⇒ 508
        --                               ⇒ 507
        --                               ⇒ 509
        --                               ⇒ 511
        --                               ⇒ 503
        -- 対象取引区分(ADJI)            ⇒ 501:相手先在庫
        --                               ⇒ 502:その他
        --                               ⇒ 503:経理払出
        --                               ⇒ 505:総務払出
        --                               ⇒ 506:棚卸減
        --                               ⇒ 507:棚卸増
        --                               ⇒ 508:転売
        --                               ⇒ 510:浜岡
        --                               ⇒ 511:黙視品目払出
        --                               ⇒ 512:黙視品目受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- オープン
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
-- 2012/01/11 v1.27 DEL START
--                                 || ' UNION ALL '
--                                 || lv_select5xx_2
--                                 || lv_where_category_crowd
-- 2012/01/11 v1.27 DEL END
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur5xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 505
        --                               ⇒ 510
        -- 対象取引区分(ADJI/OMSO/PORC)  ⇒ 504:見本
        --                               ⇒ 509:廃却
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- オープン
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur504_09;
        END IF;
      ELSE
        --===============================================================
        -- 検索条件.受払区分       ⇒ 101
        -- 対象取引区分(OMSO/PORC) ⇒ 101:資材出荷(対象外)
        --                            102:製品出荷
        --                            112:振替出荷_出荷
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- オープン
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur101;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 102
        -- 対象取引区分(OMSO/PORC) ⇒ 105:振替有償_出荷
        --                            108:商品振替有償_出荷
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- オープン
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur102;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 103
        -- 対象取引区分(OMSO/PORC) ⇒ 105:有償
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- オープン
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur103;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 104(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 113:振替出荷_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur104;
--          -- バルクフェッチ
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur104;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 105
        -- 対象取引区分(OMSO/PORC) ⇒ 107:商品振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- オープン
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur105;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 106
        -- 対象取引区分(OMSO/PORC) ⇒ 109:商品振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- オープン
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur106;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 107
        -- 対象取引区分(OMSO/PORC) ⇒ 104:振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '107') THEN
          -- オープン
          OPEN  get_data_cur107 FOR lv_select107_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select107_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur107 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur107;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 108(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 106:振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur108;
--          -- バルクフェッチ
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur108;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 109
        -- 対象取引区分(OMSO/PORC) ⇒ 110:振替出荷_受入_原
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '109') THEN
          -- オープン
          OPEN  get_data_cur109 FOR lv_select109_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select109_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur109 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur109;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 111
        -- 対象取引区分(OMSO/PORC) ⇒ 111:振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '111') THEN
          -- オープン
          OPEN  get_data_cur111 FOR lv_select111_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select111_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur111 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur111;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 201
        -- 対象取引区分(ADJI/PORC_PO) ⇒ 202:仕入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- オープン
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur201;
    --===============================================================
    -- 検索条件.受払区分          ⇒ 202
    --                            ⇒ 203
    -- 対象取引区分(OMSO/PORC)    ⇒ 201:倉替
    --                            ⇒ 203:返品
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- オープン
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur202_03;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 301
        --                            ⇒ 302
        --                            ⇒ 303
        --                            ⇒ 304
        --                            ⇒ 305
        --                            ⇒ 311
        --                            ⇒ 312
        --                            ⇒ 318
        --                            ⇒ 319
        -- 対象取引区分(PROD)         ⇒ 313:解体半製品
        --                            ⇒ 314:返品原料
        --                            ⇒ 301:沖縄
        --                            ⇒ 311:包装
        --                            ⇒ 307:セット
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- オープン
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur3xx;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 313
        --                            ⇒ 314
        --                            ⇒ 315
        --                            ⇒ 316
        -- 対象取引区分(PROD)         ⇒ 309:
        --                            ⇒ 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
-- 2012/01/11 v1.27 MOD START
--          -- オープン
--          OPEN  get_data_cur31x FOR lv_select31x_1
--                                 || lv_where_category_crowd
--                                 || lv_where_in_crowd
--                                 || lv_order_by;
--          -- バルクフェッチ
--          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur31x;
          NULL;
-- 2012/01/11 v1.27 MOD END
        --===============================================================
        -- 検索条件.受払区分             ⇒ 401
        --                               ⇒ 402
        -- 対象取引区分(ADJI/TRNI/XFER)  ⇒ 401:倉庫移動_入庫
        --                               ⇒ 402:倉庫移動_出庫
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- オープン
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur4xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 501
        --                               ⇒ 502
        --                               ⇒ 504
        --                               ⇒ 506
        --                               ⇒ 508
        --                               ⇒ 507
        --                               ⇒ 509
        --                               ⇒ 511
        --                               ⇒ 503
        -- 対象取引区分(ADJI)            ⇒ 501:相手先在庫
        --                               ⇒ 502:その他
        --                               ⇒ 503:経理払出
        --                               ⇒ 505:総務払出
        --                               ⇒ 506:棚卸減
        --                               ⇒ 507:棚卸増
        --                               ⇒ 508:転売
        --                               ⇒ 510:浜岡
        --                               ⇒ 511:黙視品目払出
        --                               ⇒ 512:黙視品目受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- オープン
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
-- 2012/01/11 v1.27 DEL START
--                                 || ' UNION ALL '
--                                 || lv_select5xx_2
--                                 || lv_where_category_crowd
--                                 || lv_where_in_crowd
-- 2012/01/11 v1.27 DEL END
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur5xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 505
        --                               ⇒ 510
        -- 対象取引区分(ADJI/OMSO/PORC)  ⇒ 504:見本
        --                               ⇒ 509:廃却
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- オープン
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur504_09;
        END IF;
      END IF;
    -- 経理群別
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- 経理群コード未入力
      IF (ir_param.acct_crowd_code  IS NULL) THEN
        --===============================================================
        -- 検索条件.受払区分       ⇒ 101
        -- 対象取引区分(OMSO/PORC) ⇒ 101:資材出荷(対象外)
        --                            102:製品出荷
        --                            112:振替出荷_出荷
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- オープン
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur101;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 102
        -- 対象取引区分(OMSO/PORC) ⇒ 105:振替有償_出荷
        --                            108:商品振替有償_出荷
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- オープン
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur102;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 103
        -- 対象取引区分(OMSO/PORC) ⇒ 105:有償
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- オープン
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur103;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 104(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 113:振替出荷_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur104;
--          -- バルクフェッチ
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur104;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 105
        -- 対象取引区分(OMSO/PORC) ⇒ 107:商品振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- オープン
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur105;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 106
        -- 対象取引区分(OMSO/PORC) ⇒ 109:商品振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- オープン
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur106;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 108(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 106:振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur108;
--          -- バルクフェッチ
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur108;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 201
        -- 対象取引区分(ADJI/PORC_PO) ⇒ 202:仕入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- オープン
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur201;
    --===============================================================
    -- 検索条件.受払区分          ⇒ 202
    --                            ⇒ 203
    -- 対象取引区分(OMSO/PORC)    ⇒ 201:倉替
    --                            ⇒ 203:返品
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- オープン
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur202_03;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 301
        --                            ⇒ 302
        --                            ⇒ 303
        --                            ⇒ 304
        --                            ⇒ 305
        --                            ⇒ 311
        --                            ⇒ 312
        --                            ⇒ 318
        --                            ⇒ 319
        -- 対象取引区分(PROD)         ⇒ 313:解体半製品
        --                            ⇒ 314:返品原料
        --                            ⇒ 301:沖縄
        --                            ⇒ 311:包装
        --                            ⇒ 307:セット
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- オープン
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur3xx;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 313
        --                            ⇒ 314
        --                            ⇒ 315
        --                            ⇒ 316
        -- 対象取引区分(PROD)         ⇒ 309:
        --                            ⇒ 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
-- 2012/01/11 v1.27 MOD START
--          -- オープン
--          OPEN  get_data_cur31x FOR lv_select31x_1
--                                 || lv_where_category_crowd
--                                 || lv_order_by;
--          -- バルクフェッチ
--          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur31x;
          NULL;
-- 2012/01/11 v1.27 MOD END
        --===============================================================
        -- 検索条件.受払区分             ⇒ 401
        --                               ⇒ 402
        -- 対象取引区分(ADJI/TRNI/XFER)  ⇒ 401:倉庫移動_入庫
        --                               ⇒ 402:倉庫移動_出庫
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- オープン
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur4xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 501
        --                               ⇒ 502
        --                               ⇒ 504
        --                               ⇒ 506
        --                               ⇒ 508
        --                               ⇒ 507
        --                               ⇒ 509
        --                               ⇒ 511
        --                               ⇒ 503
        -- 対象取引区分(ADJI)            ⇒ 501:相手先在庫
        --                               ⇒ 502:その他
        --                               ⇒ 503:経理払出
        --                               ⇒ 505:総務払出
        --                               ⇒ 506:棚卸減
        --                               ⇒ 507:棚卸増
        --                               ⇒ 508:転売
        --                               ⇒ 510:浜岡
        --                               ⇒ 511:黙視品目払出
        --                               ⇒ 512:黙視品目受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- オープン
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
-- 2012/01/11 v1.27 DEL START
--                                 || ' UNION ALL '
--                                 || lv_select5xx_2
--                                 || lv_where_category_crowd
-- 2012/01/11 v1.27 DEL END
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur5xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 505
        --                               ⇒ 510
        -- 対象取引区分(ADJI/OMSO/PORC)  ⇒ 504:見本
        --                               ⇒ 509:廃却
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- オープン
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur504_09;
        END IF;
      ELSE
        --===============================================================
        -- 検索条件.受払区分       ⇒ 101
        -- 対象取引区分(OMSO/PORC) ⇒ 101:資材出荷(対象外)
        --                            102:製品出荷
        --                            112:振替出荷_出荷
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- オープン
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur101;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 102
        -- 対象取引区分(OMSO/PORC) ⇒ 105:振替有償_出荷
        --                            108:商品振替有償_出荷
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- オープン
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur102;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 103
        -- 対象取引区分(OMSO/PORC) ⇒ 105:有償
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- オープン
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur103;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 104(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 113:振替出荷_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur104;
--          -- バルクフェッチ
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur104;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 105
        -- 対象取引区分(OMSO/PORC) ⇒ 107:商品振替有償_受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- オープン
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur105;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 106
        -- 対象取引区分(OMSO/PORC) ⇒ 109:商品振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- オープン
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur106;
        --===============================================================
        -- 検索条件.受払区分       ⇒ 108(対象外)
        -- 対象取引区分(OMSO/PORC) ⇒ 106:振替有償_払出
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- オープン
--          OPEN  get_data_cur108;
--          -- バルクフェッチ
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur108;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 201
        -- 対象取引区分(ADJI/PORC_PO) ⇒ 202:仕入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- オープン
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur201;
    --===============================================================
    -- 検索条件.受払区分          ⇒ 202
    --                            ⇒ 203
    -- 対象取引区分(OMSO/PORC)    ⇒ 201:倉替
    --                            ⇒ 203:返品
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- オープン
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur202_03;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 301
        --                            ⇒ 302
        --                            ⇒ 303
        --                            ⇒ 304
        --                            ⇒ 305
        --                            ⇒ 311
        --                            ⇒ 312
        --                            ⇒ 318
        --                            ⇒ 319
        -- 対象取引区分(PROD)         ⇒ 313:解体半製品
        --                            ⇒ 314:返品原料
        --                            ⇒ 301:沖縄
        --                            ⇒ 311:包装
        --                            ⇒ 307:セット
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- オープン
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur3xx;
        --===============================================================
        -- 検索条件.受払区分          ⇒ 313
        --                            ⇒ 314
        --                            ⇒ 315
        --                            ⇒ 316
        -- 対象取引区分(PROD)         ⇒ 309:
        --                            ⇒ 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
-- 2012/01/11 v1.27 MOD START
--          -- オープン
--          OPEN  get_data_cur31x FOR lv_select31x_1
--                                 || lv_where_category_crowd
--                                 || lv_where_in_crowd
--                                 || lv_order_by;
--          -- バルクフェッチ
--          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
--          -- カーソルクローズ
--          CLOSE get_data_cur31x;
          NULL;
-- 2012/01/11 v1.27 MOD END
        --===============================================================
        -- 検索条件.受払区分             ⇒ 401
        --                               ⇒ 402
        -- 対象取引区分(ADJI/TRNI/XFER)  ⇒ 401:倉庫移動_入庫
        --                               ⇒ 402:倉庫移動_出庫
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- オープン
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur4xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 501
        --                               ⇒ 502
        --                               ⇒ 504
        --                               ⇒ 506
        --                               ⇒ 508
        --                               ⇒ 507
        --                               ⇒ 509
        --                               ⇒ 511
        --                               ⇒ 503
        -- 対象取引区分(ADJI)            ⇒ 501:相手先在庫
        --                               ⇒ 502:その他
        --                               ⇒ 503:経理払出
        --                               ⇒ 505:総務払出
        --                               ⇒ 506:棚卸減
        --                               ⇒ 507:棚卸増
        --                               ⇒ 508:転売
        --                               ⇒ 510:浜岡
        --                               ⇒ 511:黙視品目払出
        --                               ⇒ 512:黙視品目受入
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- オープン
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
-- 2012/01/11 v1.27 DEL START
--                                 || ' UNION ALL '
--                                 || lv_select5xx_2
--                                 || lv_where_category_crowd
--                                 || lv_where_in_crowd
-- 2012/01/11 v1.27 DEL END
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur5xx;
        --===============================================================
        -- 検索条件.受払区分             ⇒ 505
        --                               ⇒ 510
        -- 対象取引区分(ADJI/OMSO/PORC)  ⇒ 504:見本
        --                               ⇒ 509:廃却
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- オープン
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- バルクフェッチ
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- カーソルクローズ
          CLOSE get_data_cur504_09;
        END IF;
      END IF;
    END IF;
-- 2008/10/24 v1.10 ADD START
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
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
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
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- 初期値
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- ＮＵＬＬ判定
    -- 項目判定用
    lc_break_col            VARCHAR2(100) DEFAULT '-' ;            -- 項目判定切り替え
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_locat_code           VARCHAR2(100) DEFAULT lc_break_init ;  -- 倉庫コード
    lv_crowd_code           VARCHAR2(100) DEFAULT lc_break_init ;  -- 群コード
    lv_crowd_low            VARCHAR2(100) DEFAULT lc_break_init ;  -- 群コード（小）
    lv_crowd_mid            VARCHAR2(100) DEFAULT lc_break_init ;  -- 群コード（中）
    lv_crowd_high           VARCHAR2(100) DEFAULT lc_break_init ;  -- 群コード（大）
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- 品目コード
    lv_cost_kbn             VARCHAR2(100) DEFAULT lc_break_init ;  -- 原価管理区分
    lv_rcv_pay_div          VARCHAR2(100) DEFAULT lc_break_init ;  -- 受払区分
    lv_col_idx              VARCHAR2(100) DEFAULT lc_break_init ;  -- 項目位置
    lv_col_name             VARCHAR2(100) DEFAULT lc_break_init ;  -- 項目タグ
--
    -- 値取得用用
    ln_unit_price           xxcmn_lot_cost.unit_ploce%TYPE ;                   -- 単価
    ln_inv_qty              ic_tran_pnd.trans_qty%TYPE;                        -- 在庫数量
    ln_inv_amt              xxcmn_lot_cost.unit_ploce%TYPE;                    -- 在庫金額
    ln_first_inv_qty        xxinv_stc_inventory_month_stck.monthly_stock%TYPE; -- 在庫数量（月首）
    ln_first_inv_amt        xxcmn_lot_cost.unit_ploce%TYPE;                    -- 在庫金額（月首）
    ln_end_inv_qty          xxinv_stc_inventory_result.loose_amt%TYPE;         -- 在庫数量（月末）
    ln_end_inv_amt          xxcmn_lot_cost.unit_ploce%TYPE;                    -- 在庫金額（月末）
--
    -- 計算用
    ln_quantity             ic_tran_pnd.trans_qty%TYPE ;                       -- 数量
    ln_qty_in               ic_tran_pnd.trans_qty%TYPE ;                       -- 数量（受入）
    ln_qty_out              ic_tran_pnd.trans_qty%TYPE ;                       -- 数量（払出）
    ln_amount               xxcmn_lot_cost.unit_ploce%TYPE ;                   -- 金額
    ln_amt_in               xxcmn_lot_cost.unit_ploce%TYPE ;                   -- 金額（受入）
    ln_amt_out              xxcmn_lot_cost.unit_ploce%TYPE ;                   -- 金額（払出）
    ln_position             NUMBER        DEFAULT 0 ;                          -- ポジション
    ln_instr                NUMBER        DEFAULT 0 ;                          -- 項目判定切替位置
-- 2008/12/22 v1.22 yoshida update start
    ln_unit_price_cost      NUMBER        DEFAULT 0;
    ln_raw_material_cost    NUMBER        DEFAULT 0;
    ln_agein_cost           NUMBER        DEFAULT 0;
    ln_material_cost        NUMBER        DEFAULT 0;
    ln_pack_cost            NUMBER        DEFAULT 0;
-- 2008/12/22 v1.22 yoshida update end
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
--
    ------------------
    -- xmlタグ登録処理
    ------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       -- タグタイプ T:タグ
                                                  --            D:データ
                                                  --            N:データ(NULLの場合タグを書かない)
                                                  --            Z:データ(NULLの場合0表示)
       ,iv_name              IN        VARCHAR2                --   タグ名
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   タグデータ(省略可
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   文字長（バイト）(省略可
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   インデックス(省略可
      )
    IS
      -- ----------------
      -- 固定ローカル定数
      -- ----------------
      cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_set_xml' ;   -- プログラム名
--
      -- --------------
      -- ユーザー宣言部
      -- --------------
      -- *** ローカル変数 ***
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
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --Nullの場合０表示
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --Nullでもそのまま表示
        END IF;
      END IF;
--
      --文字切り
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
    END prc_set_xml;
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
    ln_quantity := 0;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
--
    -- 帳票ＩＤ
    prc_set_xml('D', 'report_id', gv_report_id);
    -- 実施日
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- 担当部署
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- 担当者名
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
    -- 処理年月(from)
    prc_set_xml('D', 'p_trans_ym_from',
                TO_CHAR(TO_DATE(ir_param.exec_date_from||gc_first_date, gc_char_format),
                        gc_char_ym_format));
    -- 処理年月(to)
    prc_set_xml('D', 'p_trans_ym_to',
                TO_CHAR(TO_DATE(ir_param.exec_date_to||gc_first_date, gc_char_format),
                        gc_char_ym_format));
    -- 商品区分
    prc_set_xml('D', 'p_item_div_code', ir_param.goods_class);
    prc_set_xml('D', 'p_item_div_name', gv_goods_class_name, 20);
    -- 受払区分
    prc_set_xml('D', 'p_rcv_pay_div_code', ir_param.rcv_pay_div);
    prc_set_xml('D', 'p_rcv_pay_div_name', gv_rcv_pay_div_name, 20);
    --
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- 受払区分データタグ出力
    -- -----------------------------------------------------
    prc_set_xml('D', 'rcv_pay_div_code_sum', ir_param.rcv_pay_div);
    -- -----------------------------------------------------
    -- 群コード(大)ＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_crowd_l');
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- =====================================================
      -- 大群コードブレイク
      -- =====================================================
      -- 大群コードが切り替わった場合
      IF ( NVL( gt_main_data(i).crowd_high, lc_break_null ) <> lv_crowd_high ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_crowd_high <> lc_break_init ) THEN
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
          ------------------------------
          -- 小群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_s');
          ------------------------------
          -- 中群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_m');
          ------------------------------
          -- 中群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_m');
          ------------------------------
          -- 大群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_l');
        END IF ;
--
        ------------------------------
        -- 大群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_l');
        -- -----------------------------------------------------
        -- 大群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 大群コード
        prc_set_xml('D', 'crowd_code_large_sum', gt_main_data(i).crowd_high);
        ------------------------------
        -- 中群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd_m');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_crowd_high := NVL( gt_main_data(i).crowd_high, lc_break_null ) ;
        lv_crowd_mid  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 中群コードブレイク
      -- =====================================================
      -- 中群コードが切り替わった場合
      IF ( NVL( gt_main_data(i).crowd_mid, lc_break_null ) <> lv_crowd_mid ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_crowd_mid <> lc_break_init ) THEN
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
          ------------------------------
          -- 小群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_s');
          ------------------------------
          -- 中群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_m');
        END IF ;
--
        ------------------------------
        -- 中群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_m');
        -- -----------------------------------------------------
        -- 中群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 中群コード
        prc_set_xml('D', 'crowd_code_middle_sum', gt_main_data(i).crowd_mid);
        ------------------------------
        -- 小群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd_s');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_crowd_mid := NVL( gt_main_data(i).crowd_mid, lc_break_null ) ;
        lv_crowd_low  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 小群コードブレイク
      -- =====================================================
      -- 小群コードが切り替わった場合
      IF ( NVL( gt_main_data(i).crowd_low, lc_break_null ) <> lv_crowd_low ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_crowd_low <> lc_break_init ) THEN
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
        END IF ;
--
        ------------------------------
        -- 小群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_s');
        -- -----------------------------------------------------
        -- 小群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 小群コード
        prc_set_xml('D', 'crowd_code_small_sum', gt_main_data(i).crowd_low);
        ------------------------------
        -- 群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_crowd_low  := NVL( gt_main_data(i).crowd_low, lc_break_null ) ;
        lv_crowd_code := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 群コードブレイク
      -- =====================================================
      -- 群コードが切り替わった場合
      IF ( NVL( gt_main_data(i).crowd_code, lc_break_null ) <> lv_crowd_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_crowd_code <> lc_break_init ) THEN
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd');
        END IF ;
--
        ------------------------------
        -- 群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd');
        -- -----------------------------------------------------
        -- 群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 群コード
        prc_set_xml('D', 'crowd_code_sum', gt_main_data(i).crowd_code);
        ------------------------------
        -- 商品コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_item');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_crowd_code := NVL( gt_main_data(i).crowd_code, lc_break_null ) ;
        lv_item_code  := NVL( gt_main_data(i).item_code, lc_break_null ) ;
        lv_cost_kbn   := lc_break_init ;
--
        -- 計算項目初期化
        ln_unit_price    := 0;
        ln_inv_qty       := 0;
        ln_inv_amt       := 0;
        ln_first_inv_qty := 0;
        ln_first_inv_amt := 0;
        ln_end_inv_qty   := 0;
        ln_end_inv_amt   := 0;
--
      END IF ;
--
      ln_quantity := ln_quantity + NVL(gt_main_data(i).trans_qty, 0);
-- 2008/12/22 v1.22 yoshida update start
      ln_unit_price_cost   := ln_unit_price_cost + ROUND(NVL(gt_main_data(i).unit_price, 0)
                                                           * NVL(gt_main_data(i).trans_qty, 0));
      ln_raw_material_cost := ln_raw_material_cost + ROUND(NVL(gt_main_data(i).raw_material_cost, 0)
                                                           * NVL(gt_main_data(i).trans_qty, 0));
      ln_agein_cost        := ln_agein_cost + ROUND(NVL(gt_main_data(i).agein_cost, 0)
                                                           * NVL(gt_main_data(i).trans_qty, 0));
      ln_material_cost     := ln_material_cost + ROUND(NVL(gt_main_data(i).material_cost, 0)
                                                           * NVL(gt_main_data(i).trans_qty, 0));
      ln_pack_cost         := ln_pack_cost + ROUND(NVL(gt_main_data(i).pack_cost, 0)
                                                           * NVL(gt_main_data(i).trans_qty, 0));
-- 2008/12/22 v1.22 yoshida update end
--
      IF (   (gt_main_data.COUNT = i)
          OR (NVL(gt_main_data(i+1).item_code, lc_break_null) <> lv_item_code)) THEN
        ------------------------------
        -- 品目コードＧ開始タグ
        ------------------------------
        prc_set_xml('T','g_item');
        -- 品目コード
        prc_set_xml('D','item_code', gt_main_data(i).item_code);
        -- 品目名
        prc_set_xml('D','item_name', gt_main_data(i).item_name);
        -- 取引数量
        prc_set_xml('Z','quantity', ln_quantity);
-- 2008/11/29 v1.13 yoshida update start
        -- 標準原価
        /*prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price, gn_qty_dec));
        -- 原価費
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost,gn_qty_dec));
        -- 再製費
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost, gn_qty_dec));
        -- 資材費
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost, gn_qty_dec));
        -- 包装費
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost, gn_qty_dec));
        -- その他経費
        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost,
                      gn_qty_dec));*/
-- 2008/12/03 v1.14 yoshida update start
        /*-- 標準原価
        prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price * ln_quantity, gn_qty_dec));
        -- 原価費
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost * ln_quantity,gn_qty_dec));
        -- 再製費
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost * ln_quantity, gn_qty_dec));
        -- 資材費
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost * ln_quantity, gn_qty_dec));
        -- 包装費
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost * ln_quantity, gn_qty_dec));
        -- その他経費
        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost * ln_quantity,
                      gn_qty_dec));*/
-- 2008/12/22 v1.22 yoshida update start
        -- 標準原価
        /*prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price * ln_quantity));
        -- 原価費
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost * ln_quantity));
        -- 再製費
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost * ln_quantity));
        -- 資材費
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost * ln_quantity));
        -- 包装費
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost * ln_quantity));
        -- その他経費
-- 2008/12/06 v1.15 miyata update start
--        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost * ln_quantity));
        prc_set_xml('Z','other_expense_cost', ( round(gt_main_data(i).unit_price * ln_quantity)
                                               - round(gt_main_data(i).raw_material_cost * ln_quantity)
                                               - round(gt_main_data(i).agein_cost * ln_quantity)
                                               - round(gt_main_data(i).material_cost * ln_quantity)
                                               - round(gt_main_data(i).pack_cost * ln_quantity)));
        -- 標準原価
        /*prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price * ln_quantity));
        -- 原価費
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost * ln_quantity));
        -- 再製費
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost * ln_quantity));
        -- 資材費
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost * ln_quantity));
        -- 包装費
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost * ln_quantity));
        -- その他経費
-- 2008/12/06 v1.15 miyata update start
--        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost * ln_quantity));
        prc_set_xml('Z','other_expense_cost', ( round(gt_main_data(i).unit_price * ln_quantity)
                                               - round(gt_main_data(i).raw_material_cost * ln_quantity)
                                               - round(gt_main_data(i).agein_cost * ln_quantity)
                                               - round(gt_main_data(i).material_cost * ln_quantity)
                                               - round(gt_main_data(i).pack_cost * ln_quantity)));*/
        -- 標準原価
        prc_set_xml('Z','standard_cost', ln_unit_price_cost);
        -- 原価費
        prc_set_xml('Z','raw_material_cost',ln_raw_material_cost);
        -- 再製費
        prc_set_xml('Z','agein_cost', ln_agein_cost);
        -- 資材費
        prc_set_xml('Z','material_cost', ln_material_cost);
        -- 包装費
        prc_set_xml('Z','pack_cost', ln_pack_cost);
        -- その他経費
        prc_set_xml('Z','other_expense_cost',  ln_unit_price_cost
                                             - ln_raw_material_cost
                                             - ln_agein_cost
                                             - ln_material_cost
                                             - ln_pack_cost);
-- 2008/12/06 v1.15 miyata update end
-- 2008/12/03 v1.14 yoshida update end
-- 2008/11/29 v1.13 yoshida update end
-- 2008/12/22 v1.22 yoshida update end
        -- 品目コードＧ終了タグ
        prc_set_xml('T','/g_item');
--
        IF (gt_main_data.COUNT <> i) THEN
          lv_item_code := NVL( gt_main_data(i+1).item_code, lc_break_null );
        END IF;
--
        -- 集計値初期化
        ln_quantity           := 0;
-- 2008/12/06 v1.15 miyata update start
        ln_unit_price_cost    := 0;
        ln_raw_material_cost  := 0;
        ln_agein_cost         := 0;
        ln_material_cost      := 0;
        ln_pack_cost          := 0;
-- 2008/12/06 v1.15 miyata update end
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 品目コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- 群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd');
    ------------------------------
    -- 群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd');
    ------------------------------
    -- 小群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_s');
    ------------------------------
    -- 小群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_s');
    ------------------------------
    -- 中群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_m');
    ------------------------------
    -- 中群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_m');
    ------------------------------
    -- 大群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_l');
    ------------------------------
    -- 大群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_l');
    ------------------------------
    -- データＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/data_info');
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
  PROCEDURE submain(
      iv_exec_date_from     IN     VARCHAR2         --   01 : 処理年月(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : 処理年月(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : 受払区分
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 集計種別
     ,iv_crowd_code         IN     VARCHAR2         --   07 : 群コード
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : 経理群コード
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
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
    lv_f_date               VARCHAR2(20);
    lv_e_date               VARCHAR2(20);
--
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
    -- 帳票出力値格納
    gv_report_id                    := 'XXCMN770010T' ;      -- 帳票ID
    gd_exec_date                    := SYSDATE ;             -- 実施日
    -- パラメータ格納
    --
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      iv_exec_date_from , gc_char_y_format),gc_char_y_format);
    IF (lv_f_date IS NULL) THEN
      lr_param_rec.exec_date_from := iv_exec_date_from;
    ELSE
      lr_param_rec.exec_date_from := lv_f_date;
    END IF;                                                  -- 処理年月FROM
--
    lv_e_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      iv_exec_date_to , gc_char_y_format),gc_char_y_format);
    IF (lv_e_date IS NULL) THEN
      lr_param_rec.exec_date_to := iv_exec_date_to;
    ELSE
      lr_param_rec.exec_date_to := lv_e_date;
    END IF;                                                  -- 処理年月TO
--
    lr_param_rec.goods_class        := iv_goods_class ;      -- 商品区分
    lr_param_rec.item_class         := iv_item_class ;       -- 商品区分
    lr_param_rec.rcv_pay_div        := iv_rcv_pay_div;       -- 受払区分
    lr_param_rec.crowd_kind         := iv_crowd_kind;        -- 群種別
    lr_param_rec.crowd_code         := iv_crowd_code;        -- 群コード
    lr_param_rec.acct_crowd_code    := iv_acct_crowd_code;   -- 経理郡コード
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
    IF  (lv_retcode = gv_status_error)
     OR (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- 入力パラメータレコード
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                   <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_exec_date_from     IN     VARCHAR2         --   01 : 処理年月(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : 処理年月(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : 受払区分
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 集計種別
     ,iv_crowd_code         IN     VARCHAR2         --   07 : 群コード
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : 経理群コード
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
        iv_exec_date_from     =>     iv_exec_date_from      --   01 : 処理年月(from)
       ,iv_exec_date_to       =>     iv_exec_date_to        --   02 : 処理年月(to)
       ,iv_goods_class        =>     iv_goods_class         --   03 : 商品区分
       ,iv_item_class         =>     iv_item_class          --   04 : 品目区分
       ,iv_rcv_pay_div        =>     iv_rcv_pay_div         --   05 : 受払区分
       ,iv_crowd_kind         =>     iv_crowd_kind          --   06 : 集計種別
       ,iv_crowd_code         =>     iv_crowd_code          --   07 : 群コード
       ,iv_acct_crowd_code    =>     iv_acct_crowd_code     --   08 : 経理群コード
       ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
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
END XXCMN770010C ;
/