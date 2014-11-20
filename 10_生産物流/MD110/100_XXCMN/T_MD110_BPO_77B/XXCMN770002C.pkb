CREATE OR REPLACE PACKAGE BODY xxcmn770002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770002C(body)
 * Description      : 受払残高表（Ⅰ）製品
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77B)
 * Version          : 1.6
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize              PROCEDURE : 前処理
 *  prc_get_report_data         PROCEDURE : 明細データ取得(B-1)
 *  prc_create_xml_data         PROCEDURE : ＸＭＬデータ作成
 *  submain                     PROCEDURE : メイン処理プロシージャ
 *  main                        PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   T.Hokama         新規作成
 *  2008/05/15    1.1   T.Endou          不具合ID11,13対応
 *                                       11 入力パラ、処理日yyyym対応
 *                                       13 ヘッダー部分の最大文字数制限の変更
 *  2008/05/30    1.2   R.Tomoyose       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *  2008/06/12    1.3   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除。
 *                                       取引区分名 = 仕入先返品は払出だが出力位置は受入の部分に
 *                                       出力する。
 *  2008/06/24    1.4   T.Endou          数量・金額項目がNULLでも0出力する。
 *                                       数量・金額の間を詰める。
 *  2008/06/25    1.5   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/05    1.6   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma02_v」
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770002C' ;           -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '受払残高表（Ⅰ）製品' ;   -- 帳票名
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code           CONSTANT VARCHAR2(2)  := 'JA' ;
  gc_enable_flag             CONSTANT VARCHAR2(2)  := 'Y' ;
  gc_lookup_type_print_class CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE' ; -- 帳票種別
  gc_lookup_type_print_flg   CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';  -- 印刷可否
  gc_lookup_type_crowd_kind  CONSTANT VARCHAR2(50) := 'XXCMN_MC_OUPUT_DIV' ;            -- 群種別
  gc_lookup_type_dealing_div CONSTANT VARCHAR2(50) := 'XXCMN_DEALINGS_DIV' ;            -- 取引区分
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '商品区分' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
--
  ------------------------------
  -- 帳票種別
  ------------------------------
  gc_print_kind_locat     CONSTANT VARCHAR2(1) := '1';    --倉庫別・品目別
  gc_print_kind_item      CONSTANT VARCHAR2(1) := '2';    --品目別
--
   ------------------------------
  -- 群種別
  ------------------------------
  gc_crowd_kind           CONSTANT VARCHAR2(1) := '3';    --群別
  gc_crowd_acct_kind      CONSTANT VARCHAR2(1) := '4';    --経理群別
--
  ------------------------------
  -- 原価管理区分
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0' ;   --実際原価
  gc_cost_st              CONSTANT VARCHAR2(1) := '1' ;   --標準原価
  ------------------------------
  -- ロット管理
  ------------------------------
  gn_lot_ctl_n            CONSTANT NUMBER := 0;  --対象外
  gn_lot_ctl_y            CONSTANT NUMBER := 1;  --対象
--
  ------------------------------
  -- 受払区分
  ------------------------------
  gc_rcv_pay_div_in       CONSTANT VARCHAR2(1) := '1' ;   --受入
  gc_rcv_pay_div_out      CONSTANT VARCHAR2(2) := '-1' ;  --払出
--
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- アプリケーション
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_t_format        CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24MISS' ;
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
--
  gn_one                 CONSTANT NUMBER      := 1   ;
  gn_two                 CONSTANT NUMBER      := 2   ;
--
  ------------------------------
  -- 項目位置判断
  ------------------------------
  -- 項目判定用
  gc_break_col             VARCHAR2(100) DEFAULT '-' ;     -- 項目判定切り替え
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
  ------------------------------
  -- 数値・金額小数点位置
  ------------------------------
  gn_quantity_decml        NUMBER  := 3;
  gn_amount_decml          NUMBER  := 0;
--
  ------------------------------
  -- 文書タイプ
  ------------------------------
  gv_doc_type_xfer           CONSTANT VARCHAR2(5)     := 'XFER';  --
  gv_doc_type_trni           CONSTANT VARCHAR2(5)     := 'TRNI';  --
  gv_doc_type_adji           CONSTANT VARCHAR2(5)     := 'ADJI';  --
  gv_doc_type_prod           CONSTANT VARCHAR2(5)     := 'PROD';  --
  gv_doc_type_porc           CONSTANT VARCHAR2(5)     := 'PORC';  --
  gv_doc_type_omso           CONSTANT VARCHAR2(5)     := 'OMSO';  --
--
  ------------------------------
  -- 事由コード
  ------------------------------
  gv_reason_code_xfer        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_trni        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_adji_po     CONSTANT VARCHAR2(5)   := 'X201';--仕入
  gv_reason_code_adji_hama   CONSTANT VARCHAR2(5)   := 'X988';--浜岡
  gv_reason_code_adji_move   CONSTANT VARCHAR2(5)   := 'X123';--移動
  gv_reason_code_adji_othr   CONSTANT VARCHAR2(5)   := 'X977';--相手先（出力対象外）
  gv_reason_code_adji_itm    CONSTANT VARCHAR2(5)   := 'X942';-- 黙視品目払出
  gv_reason_code_adji_snt    CONSTANT VARCHAR2(5)   := 'X951';-- その他払出
--
  ------------------------------
  -- 取引区分
  ------------------------------
  gv_dealings_div_prod1      CONSTANT VARCHAR2(10)  := '品種振替';
  gv_dealings_div_prod2      CONSTANT VARCHAR2(10)  := '品目振替';
  gv_dealings_name_po        CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '仕入';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(6)                          -- 処理年月
     ,goods_class         mtl_categories_b.segment1%TYPE       -- 商品区分
     ,item_class          mtl_categories_b.segment1%TYPE       -- 品目区分
     ,print_kind          VARCHAR2(1)                          -- 帳票種別
     ,locat_code          ic_tran_pnd.location%TYPE            -- 倉庫コード
     ,crowd_kind          fnd_lookup_values.meaning%TYPE       -- 群種別
     ,crowd_code          mtl_categories_b.segment1%TYPE       -- 群コード
     ,acct_crowd_code     mtl_categories_b.segment1%TYPE       -- 経理群コード
    ) ;
--
  -- 受払残高表データ格納用レコード変数
  TYPE rec_data_type_dtl IS RECORD(
      locat_code            ic_whse_mst.whse_code%TYPE              -- 倉庫コード
     ,locat_name            ic_whse_mst.whse_name%TYPE              -- 倉庫名
     ,item_id               xxcmn_item_mst2_v.item_id%TYPE          -- 品目ID
     ,lot_id                ic_tran_pnd.lot_id%TYPE                 -- ロットID
     ,trans_qty             ic_tran_pnd.trans_qty%TYPE              -- 取引数量
     ,cost_kbn              ic_item_mst_b.attribute15%TYPE          -- 原価管理区分
     ,lot_ctl               xxcmn_lot_each_item_v.lot_ctl%TYPE      -- ロット管理
     ,actual_unit_price     xxcmn_lot_cost.unit_ploce%TYPE          -- 実際原価
     ,column_no             fnd_lookup_values.attribute2%TYPE       -- 項目位置
     ,rcv_pay_div           xxcmn_rcv_pay_mst.rcv_pay_div%TYPE      -- 受払区分
     ,trans_date            DATE                                    -- 取引日
     ,crowd_code            mtl_categories_b.segment1%TYPE          -- 群コード
     ,crowd_low             mtl_categories_b.segment1%TYPE          -- 群コード（小）
     ,crowd_mid             mtl_categories_b.segment1%TYPE          -- 群コード（中）
     ,crowd_high            mtl_categories_b.segment1%TYPE          -- 群コード（大）
     ,item_code             xxcmn_item_mst2_v.item_no%TYPE          -- 品目コード
     ,item_name             xxcmn_item_mst2_v.item_name%TYPE        -- 品目名称
    ) ;
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
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- 担当者
  gv_print_class_name       fnd_lookup_values.meaning%TYPE;                   -- 帳票種別名
  gv_goods_class_name       mtl_categories_tl.description%TYPE;               -- 商品区分名
  gv_item_class_name        mtl_categories_tl.description%TYPE;               -- 品目区分名
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;               -- 群種別名
--
  ------------------------------
  -- 条件取得用
  ------------------------------
  gv_exec_year_month_bef    VARCHAR2(6);      -- 処理年月の前月
  gd_exec_start             DATE;             -- 処理年月の開始日
  gd_exec_end               DATE;             -- 処理年月の終了日
  gv_exec_start             VARCHAR2(20);     -- 処理年月の開始日
  gv_exec_end               VARCHAR2(20);     -- 処理年月の終了日
  gv_exec_start_bef         VARCHAR2(20);     -- 処理年月の前月開始日
  gv_exec_end_bef           VARCHAR2(20);     -- 処理年月の前月終了日
  gv_exec_start_aft         VARCHAR2(20);     -- 処理年月の翌月開始日
  gv_exec_end_aft           VARCHAR2(20);     -- 処理年月の翌月終了日
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
    -- *** ローカル定数 ***
    lc_f_day           CONSTANT VARCHAR2(2)  := '01';
    lc_ym              CONSTANT VARCHAR2(6)  := 'YYYYMM';
    lc_f_time          CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time          CONSTANT VARCHAR2(10) := ' 23:59:59';
    -- エラーコード
    lc_err_code        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010';
    -- トークン名
    lc_token_name_01   CONSTANT VARCHAR2(100) := 'PARAMETER';
    lc_token_name_02   CONSTANT VARCHAR2(100) := 'VALUE';
    -- トークン値
    lc_token_value     CONSTANT VARCHAR2(100) := '処理年月';
--
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
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id );
--
    -- ====================================================
    -- 担当者名取得
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id );
--
    -- ====================================================
    -- 帳票種別取得
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_print_class_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.print_kind
      AND    flv.lookup_type   = gc_lookup_type_print_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
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
    -- 品目区分取得
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_item_class_name
      FROM   xxcmn_categories2_v cat
      WHERE  cat.category_set_name = gc_cat_set_item_class
      AND    cat.segment1          = ir_param.item_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 群種別取得
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_crowd_kind_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.crowd_kind
      AND    flv.lookup_type   = gc_lookup_type_crowd_kind
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 処理年月
    -- ====================================================
    -- 日付変換チェック
    gd_exec_start := FND_DATE.STRING_TO_DATE( ir_param.exec_year_month, gc_char_m_format ) ;
    IF ( gd_exec_start IS NULL ) THEN
      -- メッセージセット
      lv_retcode := gv_status_error ;
      lv_errbuf  := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                             ,iv_name          => lc_err_code
                                             ,iv_token_name1   => lc_token_name_01
                                             ,iv_token_name2   => lc_token_name_02
                                             ,iv_token_value1  => lc_token_value
                                             ,iv_token_value2  => ir_param.exec_year_month ) ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 日付情報取得
    -- ====================================================
    -- 処理年月・開始日
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month , gc_char_m_format);
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
    -- 処理年月・終了日
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
    -- 前月・年月
    gv_exec_year_month_bef := TO_CHAR(ADD_MONTHS(gd_exec_start , -1), lc_ym);
    -- 処理年月・前月開始日
    gv_exec_start_bef := TO_CHAR(ADD_MONTHS(gd_exec_start , -1), gc_char_dt_format);
    -- 処理年月・前月終了日
    gv_exec_end_bef   := TO_CHAR(gd_exec_start -1, gc_char_d_format) || lc_e_time;
    -- 処理年月・翌月開始日
    gv_exec_start_aft := TO_CHAR(ADD_MONTHS(gd_exec_start , 1), gc_char_dt_format);
    -- 処理年月・翌月終了日
    gv_exec_end_aft  := TO_CHAR(LAST_DAY(ADD_MONTHS(gd_exec_start, 1))
                                ,gc_char_d_format) || lc_e_time;
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errbuf ;
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
   * Description      : 明細データ取得(B-1)
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
--
    -- *** ローカル・変数 ***
    lv_select1    VARCHAR2(5000) ;
    lv_select2    VARCHAR2(5000) ;
    lv_from       VARCHAR2(5000) ;
    lv_where      VARCHAR2(5000) ;
    lv_order_by   VARCHAR2(5000) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql2       VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
--
    lv_sql_xfer      VARCHAR2(5000);
    lv_sql_trni      VARCHAR2(5000);
    lv_sql_adji      VARCHAR2(5000);
    lv_sql_adji_po   VARCHAR2(5000);
    lv_sql_adji_hm   VARCHAR2(5000);
    lv_sql_adji_mv   VARCHAR2(5000);
    lv_sql_adji_snt  VARCHAR2(5000);
    lv_sql_prod      VARCHAR2(5000);
    lv_sql_prod_rv   VARCHAR2(5000);
    lv_sql_porc      VARCHAR2(5000);
    lv_sql_porc_po   VARCHAR2(5000);
    lv_sql_omsso     VARCHAR2(5000);
    --xfer
    lv_from_xfer         VARCHAR2(5000);
    lv_where_xfer        VARCHAR2(5000);
    --trni
    lv_from_trni         VARCHAR2(5000);
    lv_where_trni        VARCHAR2(5000);
    --adji（仕入）
    lv_from_adji_po      VARCHAR2(5000);
    lv_where_adji_po     VARCHAR2(5000);
    --adji（浜岡）
    lv_from_adji_hm      VARCHAR2(5000);
    lv_where_adji_hm     VARCHAR2(5000);
    --adji（移動）
    lv_from_adji_mv      VARCHAR2(5000);
    lv_where_adji_mv     VARCHAR2(5000);
    --adji（その他払出）
    lv_from_adji_snt     VARCHAR2(5000);
    lv_where_adji_snt    VARCHAR2(5000);
    --adji（上記以外）
    lv_from_adji         VARCHAR2(5000);
    lv_where_adji        VARCHAR2(5000);
    --prod（Reverse_idなし）品種・品目振替以外
    lv_from_prod         VARCHAR2(5000);
    lv_where_prod        VARCHAR2(5000);
    --porc
    lv_select_porc       VARCHAR2(5000);
    lv_from_porc         VARCHAR2(5000);
    lv_where_porc        VARCHAR2(5000);
    --porc（仕入）
    lv_from_porc_po      VARCHAR2(5000);
    lv_where_porc_po     VARCHAR2(5000);
    --omsso
    lv_select_omsso      VARCHAR2(5000);
    lv_from_omsso        VARCHAR2(5000);
    lv_where_omsso       VARCHAR2(5000);
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
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
--
    lv_select1 := '  SELECT';
    --倉庫別を選択した場合は倉庫コードを取得する。
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_select1 := lv_select1
              || ' iwm.whse_code            h_whse_code'            -- ヘッダ：倉庫コード
              || ',iwm.whse_name            h_whse_name'            -- ヘッダ：倉庫名称
             ;
    ELSE
      lv_select1 := lv_select1
              || ' NULL                     h_whse_code'            -- ヘッダ：倉庫コード
              || ',NULL                     h_whse_name'            -- ヘッダ：倉庫名称
             ;
    END IF;
    lv_select1 := lv_select1
              || ',trn.item_id              item_id'           -- 品目ID
              || ',trn.lot_id               lot_id'            -- ロットID
              || ',trn.trans_qty            trans_qty'         -- 取引数量
              || ',xleiv.item_attribute15   cost_mng_clss'     -- 原価管理区分
              || ',xleiv.lot_ctl            lot_ctl'           -- ロット管理
              || ',xleiv.actual_unit_price  actual_unit_price' -- 実際単価
              || ',CASE WHEN INSTR(xlvv.attribute2,''' || gc_break_col || ''') = 0'
              || '           THEN '''''
              || '      WHEN xrpmxv.rcv_pay_div = ' || gc_rcv_pay_div_in
              || '           THEN SUBSTR(xlvv.attribute2,1,'
              || '                INSTR(xlvv.attribute2,''' || gc_break_col || ''') -1)'
              || '      WHEN xrpmxv.dealings_div_name = ''' || gv_dealings_name_po || ''''
              || '           THEN SUBSTR(xlvv.attribute2,1,'
              || '                INSTR(xlvv.attribute2,''' || gc_break_col || ''') -1)'
              || '      ELSE'
              || '                SUBSTR(xlvv.attribute2,INSTR(xlvv.attribute2,'''
              ||                                         gc_break_col || ''') +1)'
              || ' END  column_no'                             -- 項目位置
              || ',xrpmxv.rcv_pay_div       rcv_pay_div'       -- 受払区分
              || ',trn.trans_date           trans_date'        -- 取引日
              ;
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- 群種別＝「3：郡別」が指定されている場合
      lv_select1 := lv_select1 || ',xleiv.crowd_code                crowd_code'      --群コード
                               || ',SUBSTR(xleiv.crowd_code, 1, 3)  crowd_low'       --小群
                               || ',SUBSTR(xleiv.crowd_code, 1, 2)  crowd_mid'       --中群
                               || ',SUBSTR(xleiv.crowd_code, 1, 1)  crowd_high'      --大群
                                ;
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- 群種別＝「4：経理郡別」が指定されている場合
      lv_select1 := lv_select1 || ',xleiv.acnt_crowd_code  crowd_code'               --経理群コード
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 3)  crowd_low'  --小群
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 2)  crowd_mid'  --中群
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 1)  crowd_high' --大群
                               ;
    END IF;
    lv_select2 := ''
              || ',xleiv.item_code          item_code'         -- 品目コード
              || ',xleiv.item_short_name    item_name'         -- 品目名称
               ;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
--
    lv_from :=  ' FROM '
            || ' xxcmn_lot_each_item_v     xleiv'    -- ロット別品目情報
            || ',xxcmn_lookup_values2_v    xlvv'     -- クイックコード情報view2
            ;
    --倉庫別を選択した場合は倉庫マスタを結合する。
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_from :=  lv_from
              || ',ic_whse_mst             iwm'      -- OPM倉庫マスタ
              ;
    END IF;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || ' trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',  '''
             ||                                             gc_char_dt_format || ''')'--取引日
             || ' AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''',  '''
             ||                                                 gc_char_dt_format || ''')'--取引日
             || ' AND ((xleiv.start_date_active IS NULL)'
             || '      OR (xleiv.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND ((xleiv.end_date_active IS NULL)'
             || '      OR (xleiv.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND xleiv.item_id    = trn.item_id'
             || ' AND xleiv.lot_id     = trn.lot_id'
             || ' AND xlvv.attribute2 IS NOT NULL'
             ;
    ---------------------------------------------------------------------------------------------
    --  ルックアップ（対象帳票）
    lv_where :=  lv_where
      || ' AND xlvv.lookup_type       = ''' || gc_lookup_type_print_flg || ''''
      || ' AND xrpmxv.dealings_div    = xlvv.meaning'
      || ' AND xlvv.enabled_flag      = ''Y'''
      || ' AND (xlvv.start_date_active IS NULL OR'
      || ' xlvv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlvv.end_date_active   IS NULL OR'
      || ' xlvv.end_date_active    >= TRUNC(trn.trans_date))'
      ;
    ---------------------------------------------------------------------------------------------
    -- 帳票種別＝１：倉庫別・品目別の場合
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_where := lv_where
               || ' AND iwm.whse_code  = trn.whse_code'
               ;
      -- 倉庫コードが指定されている場合
      IF (ir_param.locat_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND iwm.whse_code = ''' || ir_param.locat_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 群種別＝「3：郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- 群コードが入力されている場合
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.crowd_code  = ''' || ir_param.crowd_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 群種別＝「4：経理郡別」が指定されている場合
    IF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- 経理群コードが入力されている場合
       IF (ir_param.acct_crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.acnt_crowd_code  = ''' || ir_param.acct_crowd_code || ''''
                 ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- SQL生成( XFER :経理受払区分情報ＶＩＷ移動積送あり）
    -- ----------------------------------------------------
    lv_from_xfer := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_xfer_v  xrpmxv'   --  受払VIW
      || ',ic_xfer_mst               ixm'      -- ＯＰＭ在庫転送マスタ
      || ',xxinv_mov_req_instr_lines xmril'    -- 移動依頼／指示明細（アドオン）
       ;
--
    lv_where_xfer :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_xfer    || '''' --文書タイプ
      || ' AND trn.reason_code         = ''' || gv_reason_code_xfer || '''' --事由コード
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND trn.doc_id              = ixm.transfer_id'
      || ' AND ixm.attribute1          = xmril.mov_line_id'
       ;
    -- ＳＱＬ生成(XFER)
    lv_sql_xfer := lv_select1 || lv_select2 || lv_from || lv_from_xfer
                || lv_where || lv_where_xfer;
--
    -- ----------------------------------------------------
    -- SQL生成( TRNI :経理受払区分情報ＶＩＷ移動積送なし）
    -- ----------------------------------------------------
    lv_from_trni := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_trni_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- ＯＰＭ在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- ＯＰＭジャーナルマスタ
      || ',xxinv_mov_req_instr_lines xmril'    -- 移動依頼／指示明細（アドオン）
       ;
--
    lv_where_trni :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_trni    || '''' --文書タイプ
      || ' AND trn.reason_code         = ''' || gv_reason_code_trni || '''' --事由コード
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_type           = xrpmxv.rcv_pay_div'                --ラインタイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND trn.doc_type            = iaj.trans_type'
      || ' AND trn.doc_id              = iaj.doc_id'
      || ' AND trn.doc_line            = iaj.doc_line'
      || ' AND iaj.journal_id          = ijm.journal_id'
      || ' AND ijm.attribute1          = xmril.mov_line_id'
       ;
    -- ＳＱＬ生成(TRNI)
    lv_sql_trni := lv_select1 || lv_select2 || lv_from || lv_from_trni
                || lv_where || lv_where_trni;
--
    -- ----------------------------------------------------
    -- SQL生成( ADJI :経理受払区分情報ＶＩＷ在庫調整(他)
    -- ----------------------------------------------------
    lv_from_adji := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
       ;
--
    lv_where_adji :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_po || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_hama || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_move || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_othr || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_itm || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_snt || ''''
       ;
    -- ＳＱＬ生成(adji)他
    lv_sql_adji := lv_select1 || lv_select2 || lv_from || lv_from_adji
                || lv_where || lv_where_adji;
--
    -- ----------------------------------------------------
    -- SQL生成( ADJI :経理受払区分情報ＶＩＷ在庫調整(仕入)
    -- ----------------------------------------------------
--
    lv_from_adji_po := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_rcv_and_rtn_txns     xrrt'     -- 受入返品実績アドオン
       ;
--
    lv_where_adji_po :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_po || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xrrt.txns_id            = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)仕入
    lv_sql_adji_po := lv_select1 || lv_select2 || lv_from || lv_from_adji_po
                   || lv_where || lv_where_adji_po;
--
    -- ----------------------------------------------------
    -- SQL生成( ADJI :経理受払区分情報ＶＩＷ在庫調整(浜岡)
    -- ----------------------------------------------------
    lv_from_adji_hm := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_namaha_prod_txns     xnpt'     -- 精算実績アドオン
       ;
--
    lv_where_adji_hm :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_hama || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xnpt.entry_number       = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)仕入
    lv_sql_adji_hm := lv_select1 || lv_select2 || lv_from || lv_from_adji_hm
                   || lv_where || lv_where_adji_hm;
--
    -- ----------------------------------------------------
    -- SQL生成( ADJI :経理受払区分情報ＶＩＷ在庫調整(移動)
    -- ----------------------------------------------------
    lv_from_adji_mv := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
      || ',ic_adjs_jnl               iaj'      -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst               ijm'      -- OPMジャーナルマスタ
      || ',xxpo_vendor_supply_txns   xvst'     -- 外注出来高実績
       ;
--
    lv_where_adji_mv :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_move || ''''
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xvst.txns_id            = ijm.attribute1'
       ;
    -- ＳＱＬ生成(adji)
    lv_sql_adji_mv := lv_select1 || lv_select2 || lv_from || lv_from_adji_mv
                   || lv_where || lv_where_adji_mv;
--
    -- ----------------------------------------------------
    -- SQL生成( ADJI :経理受払区分情報ＶＩＷ在庫調整(その他払出)
    -- ----------------------------------------------------
    lv_from_adji_snt := ''
      || ',ic_tran_cmp               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  受払VIW
       ;
--
    lv_where_adji_snt :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --文書タイプ
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --事由コード
      || ' AND ((trn.reason_code       = ''' || gv_reason_code_adji_itm || ''')'
      || '  OR  (trn.reason_code       = ''' || gv_reason_code_adji_snt || '''))'
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
       ;
    -- ＳＱＬ生成(adji)
    lv_sql_adji_snt := lv_select1 || lv_select2 || lv_from || lv_from_adji_snt
                    || lv_where || lv_where_adji_snt;
--
    -- ----------------------------------------------------
    -- SQL生成( PROD :経理受払区分情報ＶＩＷ生産関連（Reverse_idなし）品種・品目振替なし
    -- ----------------------------------------------------
    lv_from_prod := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_prod_v  xrpmxv'   --  受払VIW
      || ',xxcmn_lookup_values2_v    xlvv2'    -- クイックコード情報view2
       ;
--
    lv_where_prod :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_prod    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.reverse_id          IS NULL'
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_type           = xrpmxv.line_type'                  --ラインタイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_type           = xrpmxv.gmd_line_type'              --
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod1 || ''''   -- 品種振替
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod2 || ''''   -- 品目振替
      || ' AND xlvv2.lookup_type       = ''' || gc_lookup_type_dealing_div || ''''
      || ' AND xrpmxv.dealings_div     = xlvv2.lookup_code'
      || ' AND xlvv2.enabled_flag      = ''Y'''
      || ' AND (xlvv2.start_date_active IS NULL OR'
      || ' xlvv2.start_date_active    <= TRUNC(trn.trans_date))'
      || ' AND (xlvv2.end_date_active   IS NULL OR'
      || ' xlvv2.end_date_active      >= TRUNC(trn.trans_date))'
       ;
    -- ＳＱＬ生成(prod)Reverse_idなし
    lv_sql_prod := lv_select1 || lv_select2 || lv_from || lv_from_prod
                || lv_where || lv_where_prod;
--
    -- ----------------------------------------------------
    -- SQL生成( PORC :経理受払区分情報ＶＩＷ購買関連
    -- ----------------------------------------------------
    lv_select_porc := ''
                   || ',xitem.item_no            item_code'         -- 品目コード
                   || ',xitem.item_short_name    item_name'         -- 品目名称
                    ;
--
    lv_from_porc := ''
      || ',ic_tran_pnd                     trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_porc_rma02_v  xrpmxv'   --  受払VIW（RMA）
      || ',xxcmn_item_mst2_v               xitem'    -- 品目マスタVIEW
       ;
--
    lv_where_porc :=  ''
      || ' AND xrpmxv.prod_div         = ''' || ir_param.goods_class || ''''
      || ' AND xrpmxv.item_div         = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND xitem.item_id           = NVL(xrpmxv.item_id, trn.item_id)'
      || ' AND ((xitem.start_date_active IS NULL)'
      || '      OR (xitem.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
      || '          TRUNC(trn.trans_date)))'
      || ' AND ((xitem.end_date_active IS NULL)'
      || '      OR (xitem.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
      || '          TRUNC(trn.trans_date)))'
       ;
    -- ＳＱＬ生成(porc)
    lv_sql_porc := lv_select1 || lv_select_porc || lv_from || lv_from_porc
                || lv_where || lv_where_porc;
--
    -- ----------------------------------------------------
    -- SQL生成( PORC :経理受払区分情報ＶＩＷ購買関連（仕入）
    -- ----------------------------------------------------
    lv_from_porc_po := ''
      || ',ic_tran_pnd                  trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_porc_po_v  xrpmxv'   --  受払VIW（PO）
       ;
--
    lv_where_porc_po :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --文書タイプ
      || ' AND trn.completed_ind       = 1'                                 --完了区分
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --バッチID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_id             = xrpmxv.line_id'
       ;
    -- ＳＱＬ生成(porc)仕入
    lv_sql_porc_po := lv_select1 || lv_select2 || lv_from || lv_from_porc_po
                   || lv_where || lv_where_porc_po;
--
    -- ----------------------------------------------------
    -- SQL生成( OMSO :経理受払区分情報ＶＩＷ受注関連
    -- ----------------------------------------------------
    lv_select_omsso := ''
                    || ',xitem.item_no            item_code'         -- 品目コード
                    || ',xitem.item_short_name    item_name'         -- 品目名称
                     ;
--
    lv_from_omsso := ''
      || ',ic_tran_pnd               trn'      -- 保留在庫トラン
      || ',xxcmn_rcv_pay_mst_omso_v  xrpmxv'   --  受払VIW
      || ',xxcmn_item_mst2_v         xitem'    -- 品目マスタVIEW
       ;
--
    lv_where_omsso :=  ''
      || ' AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''','''
      ||                                                      gc_char_dt_format || ''')' -- 着荷日
      || ' AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''
      ||                                                      gc_char_dt_format || ''')' -- 着荷日
      || ' AND trn.doc_type         = ''' || gv_doc_type_omso    || '''' --文書タイプ
      || ' AND trn.completed_ind    = 1'                                 --完了区分
      || ' AND trn.doc_type         = xrpmxv.doc_type'                   --文書タイプ
      || ' AND trn.line_detail_id   = xrpmxv.doc_line'                   --
      || ' AND xrpmxv.prod_div      = ''' || ir_param.goods_class || ''''
      || ' AND xrpmxv.item_div      = ''' || ir_param.item_class || ''''
      || ' AND xitem.item_id        = NVL(xrpmxv.item_id, trn.item_id)'
      || ' AND ((xitem.start_date_active IS NULL)'
      || '      OR (xitem.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
      || '          TRUNC(trn.trans_date)))'
      || ' AND ((xitem.end_date_active IS NULL)'
      || '      OR (xitem.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
      || '          TRUNC(trn.trans_date)))'
       ;
    -- ＳＱＬ生成(OMSO)
    lv_sql_omsso := lv_select1 || lv_select_omsso || lv_from || lv_from_omsso
                 || lv_where || lv_where_omsso;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    -- 帳票種別＝１：倉庫別・品目別の場合
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_order_by := ' ORDER BY'
                  || ' h_whse_code'     -- ヘッダ：倉庫コード
                  || ',crowd_code'      -- 群コード
                  || ',item_code'       -- 品目コード
                  || ',column_no'       -- 項目位置
                  || ',rcv_pay_div'     -- 受払区分
                  ;
    ELSE
      lv_order_by := ' ORDER BY'
                  || ' crowd_code'      -- 群コード
                  || ',item_code'       -- 品目コード
                  || ',column_no'       -- 項目位置
                  || ',rcv_pay_div'     -- 受払区分
                  ;
    END IF;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := ''
      ||  lv_sql_xfer
      ||  ' UNION ALL '
      ||  lv_sql_trni
      ||  ' UNION ALL '
      ||  lv_sql_adji
      ||  ' UNION ALL '
      ||  lv_sql_adji_po
      ||  ' UNION ALL '
      ||  lv_sql_adji_hm
      ||  ' UNION ALL '
      ||  lv_sql_adji_mv
      ||  ' UNION ALL '
      ||  lv_sql_adji_snt
      ||  ' UNION ALL '
      ||  lv_sql_prod
       ;
    lv_sql2 := ''
      ||  ' UNION ALL '
      ||  lv_sql_porc
      ||  ' UNION ALL '
      ||  lv_sql_porc_po
      ||  ' UNION ALL '
      ||  lv_sql_omsso
      ||  ' '
       ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql || lv_sql2 || lv_order_by;
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
    lv_column_no            VARCHAR2(100) DEFAULT lc_break_init ;  -- 項目位置
    lv_col_name             VARCHAR2(100) DEFAULT lc_break_init ;  -- 項目タグ
--
    -- 値取得用用
    ln_unit_price           NUMBER        DEFAULT 0;               -- 単価
    ln_inv_qty              NUMBER        DEFAULT 0;               -- 在庫数量
    ln_inv_amt              NUMBER        DEFAULT 0;               -- 在庫金額
    ln_first_inv_qty        NUMBER        DEFAULT 0;               -- 在庫数量（月首）
    ln_first_inv_amt        NUMBER        DEFAULT 0;               -- 在庫金額（月首）
    ln_end_inv_qty          NUMBER        DEFAULT 0;               -- 在庫数量（月末）
    ln_end_inv_amt          NUMBER        DEFAULT 0;               -- 在庫金額（月末）
--
    -- 計算用
    ln_quantity             NUMBER        DEFAULT 0;               -- 数量
    ln_qty_in               NUMBER        DEFAULT 0;               -- 数量（受入）
    ln_qty_out              NUMBER        DEFAULT 0;               -- 数量（払出）
    ln_amount               NUMBER        DEFAULT 0;               -- 金額
    ln_amt_in               NUMBER        DEFAULT 0;               -- 金額（受入）
    ln_amt_out              NUMBER        DEFAULT 0;               -- 金額（払出）
    ln_position             NUMBER        DEFAULT 0;               -- ポジション
    ln_instr                NUMBER        DEFAULT 0;               -- 項目判定切替位置
--
    -- 項目判定用
    lb_trnsfr               BOOLEAN       DEFAULT FALSE;           -- 振替項目
    lb_payout               BOOLEAN       DEFAULT FALSE;           -- 払出項目
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
--
    ---------------------
    -- XMLタグ挿入処理
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR    --   タグタイプ  T:タグ
                                                             -- D:データ
                                                             -- N:データ(NULLの場合タグを書かない)
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
      -- 項目タグ名が「*_qty」または「*_amt」の場合、出力しない
      IF (iv_name = '*_qty') OR (TRIM(iv_name) = '*_amt') THEN
        RETURN;
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
    ---------------------
    -- 標準単価取得
    ---------------------
    FUNCTION fnc_get_item_unit_price(
        in_pos   IN   NUMBER    --レコード配列位置
      ) RETURN NUMBER
    IS
--
    -- *** ローカル変数 ***
    ln_unit_price NUMBER DEFAULT 0;    --原価戻り値
--
    BEGIN
--
      --原価区分＝標準原価、原価区分＝実際原価andロット管理＝対象外のとき
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- 標準原価マスタより標準単価を取得
        BEGIN
          SELECT prc.stnd_unit_price as price
          INTO   ln_unit_price
          FROM   xxcmn_stnd_unit_price_v prc
          WHERE  prc.item_id    = gt_main_data(in_pos).item_id
            AND (prc.start_date_active IS NULL OR
                 prc.start_date_active  <= TRUNC(gt_main_data(in_pos).trans_date))
            AND (prc.end_date_active   IS NULL OR
                 prc.end_date_active    >= TRUNC(gt_main_data(in_pos).trans_date));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_unit_price :=  0;
        END;
        RETURN  ln_unit_price;
--
      --原価区分＝標準原価以外の場合、Zeroを設定
      ELSE
        RETURN  0;
      END IF;
--
    END fnc_get_item_unit_price;
--
    --------------------------------------
    -- 品目の在庫・金額（実際単価）を取得
    --------------------------------------
    PROCEDURE prc_get_inv_qty_amt(
        ir_param      IN     rec_param_data                     -- 入力パラメータ群
       ,in_pos        IN     NUMBER                             -- レコード配列位置
       ,iv_year_month IN     VARCHAR2                           -- 取引日対象年月
       ,on_inv_qty    OUT    NUMBER                             -- 数量
       ,on_inv_amt    OUT    NUMBER                             -- 金額（実際単価）
    )
    IS
      -- *** ローカル変数 ***
      ln_idx              NUMBER;           -- 対象インデックス
      ld_trn_start        VARCHAR2(20);     -- 取引日対象開始日
      ld_trn_end          VARCHAR2(20);     -- 取引日対象開始日
      ld_alv_start        VARCHAR2(20);     -- 着荷日対象開始日
      ld_alv_end          VARCHAR2(20);     -- 着荷日対象開始日
--
    BEGIN
--
      --取引日が前月（月首）
      ln_idx := in_pos;  -- 初期値
      IF (iv_year_month < ir_param.exec_year_month) THEN
        ld_trn_start := gv_exec_start_bef;
        ld_trn_end   := gv_exec_end_bef;
        ld_alv_start := gv_exec_start;
        ld_alv_end   := gv_exec_end;
      --取引日が当月（月末）
      ELSE
        IF (gt_main_data.COUNT > in_pos) THEN
          ln_idx := in_pos - 1;
        END IF;
        ld_trn_start := gv_exec_start;
        ld_trn_end   := gv_exec_end;
        ld_alv_start := gv_exec_start_aft;
        ld_alv_end   := gv_exec_end_aft;
      END IF;
--
      --原価区分＝標準原価、原価区分＝実際原価andロット管理＝対象外のとき
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- 受払VIEW(OMSO)より数量を取得
        -- ※原価区分＝標準原価のため、金額を算出しない
        BEGIN
          SELECT
                 NVL(SUM(NVL(trn.trans_qty, 0)),0) as stock   -- 取引数量
                ,0                                 as price   -- 実際単価
          INTO   on_inv_qty
                ,on_inv_amt
          FROM  ic_tran_pnd               trn      -- 保留在庫トラン
               ,xxcmn_rcv_pay_mst_omso_v  xrpmxv   --  受払VIW
          WHERE trn.trans_date >= FND_DATE.STRING_TO_DATE(ld_trn_start, gc_char_dt_format )
            AND trn.trans_date <= FND_DATE.STRING_TO_DATE(ld_trn_end,  gc_char_dt_format )
            AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(ld_alv_start, gc_char_dt_format )
            AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(ld_alv_end,  gc_char_dt_format )
            AND trn.doc_type            = gv_doc_type_omso                  --文書タイプ
            AND trn.completed_ind       = 1                                 --完了区分
            AND trn.doc_type            = xrpmxv.doc_type                   --文書タイプ
            AND trn.line_detail_id      = xrpmxv.doc_line
            AND trn.item_id             = gt_main_data(ln_idx).item_id
            AND ( (ir_param.print_kind <> gc_print_kind_locat)
               OR ( (ir_param.print_kind = gc_print_kind_locat)
                AND (trn.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
--
      --原価区分＝標準原価以外の場合
      ELSE
        -- 受払VIEW(OMSO)より数量・金額を取得
        BEGIN
          SELECT
                 NVL(SUM(NVL(trn.trans_qty, 0)),0) as stock       -- 取引数量
                ,NVL(SUM(NVL(trn.trans_qty, 0) * NVL(xleiv.actual_unit_price, 0)),0)
                                                 as price          -- 実際単価
          INTO   on_inv_qty
                ,on_inv_amt
          FROM ic_tran_pnd               trn      -- 保留在庫トラン
              ,xxcmn_rcv_pay_mst_omso_v  xrpmxv   --  受払VIW
              ,xxcmn_lot_each_item_v     xleiv    -- ロット別品目情報
          WHERE trn.trans_date >= FND_DATE.STRING_TO_DATE(ld_trn_start, gc_char_dt_format )
            AND trn.trans_date <= FND_DATE.STRING_TO_DATE(ld_trn_end,  gc_char_dt_format )
            AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(ld_alv_start, gc_char_dt_format )
            AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(ld_alv_end,  gc_char_dt_format )
            AND trn.doc_type            = gv_doc_type_omso                  --文書タイプ
            AND trn.completed_ind       = 1                                 --完了区分
            AND trn.doc_type            = xrpmxv.doc_type                   --文書タイプ
            AND trn.line_detail_id      = xrpmxv.doc_line
            AND trn.item_id             = gt_main_data(ln_idx).item_id
            AND trn.item_id             = xleiv.item_id
            AND trn.lot_id              = xleiv.lot_id
            AND ( (ir_param.print_kind <> gc_print_kind_locat)
               OR ( (ir_param.print_kind = gc_print_kind_locat)
                AND (trn.whse_code       = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
      END IF;
--
    END prc_get_inv_qty_amt;
--
    ------------------------------------------------
    -- 品目の月首・月末在庫・金額（実際単価）を取得
    ------------------------------------------------
    PROCEDURE prc_get_fst_end_inv_qty_amt(
        ir_param      IN   rec_param_data    -- 入力パラメータ群
       ,in_pos        IN   NUMBER            -- レコード配列位置
       ,iv_year_month IN   VARCHAR2          -- 対象年月
       ,on_inv_qty    OUT  NUMBER            -- 数量
       ,on_inv_amt    OUT  NUMBER            -- 金額（実際単価）
      )
    IS
      -- *** ローカル変数 ***
      ln_idx  NUMBER;
--
    BEGIN
--
      -- 対象インデックスを取得
      ln_idx := in_pos;  -- 初期値
      IF (iv_year_month = ir_param.exec_year_month) AND (gt_main_data.COUNT > in_pos) THEN
        -- 月末
        ln_idx := in_pos - 1;
      END IF;
--
      --原価区分＝標準原価、原価区分＝実際原価andロット管理＝対象外のとき
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- 月末在庫より数量を取得
        BEGIN
          SELECT NVL(SUM(NVL(stc.monthly_stock, 0)),0) as stock
                ,0                                     as price
          INTO   on_inv_qty
                ,on_inv_amt
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.item_id   = gt_main_data(ln_idx).item_id
          AND    stc.invent_ym = iv_year_month
          AND ( (ir_param.print_kind <> gc_print_kind_locat)
             OR ( (ir_param.print_kind = gc_print_kind_locat)
              AND (stc.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
--
        -- ※原価区分＝標準原価のため、金額を算出しない
--
      --原価区分＝標準原価以外の場合
      ELSE
        -- 月末在庫より数量・金額を取得
        BEGIN
          SELECT NVL(SUM(NVL(stc.monthly_stock, 0)),0) as stock
                ,NVL(SUM(NVL(stc.monthly_stock, 0) * NVL(xleiv.actual_unit_price, 0)),0)
                                                       as price
          INTO   on_inv_qty
                ,on_inv_amt
          FROM   xxinv_stc_inventory_month_stck stc
                ,xxcmn_lot_each_item_v          xleiv    -- ロット別品目情報
          WHERE  stc.item_id   = gt_main_data(ln_idx).item_id
          AND    stc.invent_ym = iv_year_month
          AND    stc.item_id   = xleiv.item_id
          AND    stc.lot_id    = xleiv.lot_id
          AND ( (ir_param.print_kind <> gc_print_kind_locat)
             OR ( (ir_param.print_kind = gc_print_kind_locat)
              AND (stc.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
      END IF;
--
    END prc_get_fst_end_inv_qty_amt;
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
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
    -- 帳票種別
    prc_set_xml('D', 'out_div', ir_param.print_kind);
    prc_set_xml('D', 'out_div_name', gv_print_class_name, 20);
    -- 処理年月
    prc_set_xml('D', 'exec_year', SUBSTR(ir_param.exec_year_month, 1, 4) );
    prc_set_xml('D', 'exec_month', TO_CHAR(SUBSTR(ir_param.exec_year_month, 5, 2),'00') );
    -- 商品区分
    prc_set_xml('D', 'prod_div', ir_param.goods_class);
    prc_set_xml('D', 'prod_div_name', gv_goods_class_name, 20);
    -- 品目区分
    prc_set_xml('D', 'item_div', ir_param.item_class);
    prc_set_xml('D', 'item_div_name', gv_item_class_name, 20);
    -- 群種別
    prc_set_xml('D', 'crowd_div', ir_param.crowd_kind);
    prc_set_xml('D', 'crowd_div_name', gv_crowd_kind_name, 20);
--
    -- 帳票ＩＤ
    prc_set_xml('D', 'report_id', gv_report_id);
    -- 実施日
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- 担当部署
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- 担当者名
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
--
    -- 倉庫コードが指定されている場合
    IF (ir_param.locat_code  IS NOT NULL) THEN
      -- 倉庫計出力なし
      prc_set_xml('D', 'locat_sum', '1');
    END IF;
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- 倉庫ＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_locat');
    -- 帳票区分が「品目別」の場合
    IF (ir_param.print_kind = gc_print_kind_item) THEN
      -- -----------------------------------------------------
      -- 倉庫Ｇ開始タグ出力
      -- -----------------------------------------------------
      prc_set_xml('T', 'g_locat');
      -- ポジション
      ln_position := ln_position + 1;
      prc_set_xml('D', 'position', TO_CHAR(ln_position));
--
      -- -----------------------------------------------------
      -- キーブレイク時の初期処理
      -- -----------------------------------------------------
      -- キーブレイク用変数退避
      lv_locat_code := lc_break_null ;
      lv_crowd_high := lc_break_init ;
      -- -----------------------------------------------------
      -- 大群コードＬＧ開始タグ出力
      -- -----------------------------------------------------
      prc_set_xml('T', 'lg_crowd_high');
    END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 倉庫コードブレイク
      -- =====================================================
      -- 帳票種別が「倉庫・品目別」で倉庫コードが切り替わった場合
      IF   ( ir_param.print_kind = gc_print_kind_locat )
       AND ( NVL( gt_main_data(i).locat_code, lc_break_null ) <> lv_locat_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_locat_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- 小群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- 中群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
          ------------------------------
          -- 中群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_mid');
          ------------------------------
          -- 大群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_high');
          ------------------------------
          -- 大群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_high');
          ------------------------------
          -- 倉庫コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_locat');
        END IF ;
--
        -- -----------------------------------------------------
        -- 倉庫コードＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_locat');
        -- -----------------------------------------------------
        -- 倉庫コードＧデータタグ出力
        -- -----------------------------------------------------
        -- ポジション
        ln_position := ln_position + 1;
        prc_set_xml('D', 'position', TO_CHAR(ln_position));
        -- 倉庫コード
        prc_set_xml('D', 'locat_code', gt_main_data(i).locat_code);
        -- 倉庫名
        prc_set_xml('D', 'locat_name', gt_main_data(i).locat_name, 20);
        -- -----------------------------------------------------
        -- 大群コードＬＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'lg_crowd_high');
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_locat_code := NVL( gt_main_data(i).locat_code, lc_break_null )  ;
        lv_crowd_high := lc_break_init ;
--
      END IF ;
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
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- 小群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- 中群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
          ------------------------------
          -- 中群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_mid');
          ------------------------------
          -- 大群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_high');
        END IF ;
--
        ------------------------------
        -- 大群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_high');
        -- -----------------------------------------------------
        -- 大群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 大群コード
        prc_set_xml('D', 'crowd_high', gt_main_data(i).crowd_high);
        ------------------------------
        -- 中群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd_mid');
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
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- 小群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- 中群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
        END IF ;
--
        ------------------------------
        -- 中群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_mid');
        -- -----------------------------------------------------
        -- 中群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 中群コード
        prc_set_xml('D', 'crowd_mid', gt_main_data(i).crowd_mid);
        ------------------------------
        -- 小群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd_low');
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
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- 群コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- 小群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
        END IF ;
--
        ------------------------------
        -- 小群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_low');
        -- -----------------------------------------------------
        -- 小群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 小群コード
        prc_set_xml('D', 'crowd_low', gt_main_data(i).crowd_low);
        ------------------------------
        -- 群コードＬＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'lg_crowd_dtl');
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
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 群コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
        END IF ;
--
        ------------------------------
        -- 群コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_crowd_dtl');
        -- -----------------------------------------------------
        -- 群コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 群コード
        prc_set_xml('D', 'crowd_dtl', gt_main_data(i).crowd_code);
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
        lv_item_code  := lc_break_init ;
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
      -- =====================================================
      -- 品目コードブレイク
      -- =====================================================
      -- 品目コードが切り替わった場合
      IF ( NVL( gt_main_data(i).item_code, lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合はタグを出力しない。
        IF ( lv_item_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- 月末データタグ出力
          -- -----------------------------------------------------
          -- 数量
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- 受払VIEWより取得
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- 棚卸・差異データタグ出力
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- 在庫数量が確定していない場合
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- 在庫数量が確定している場合
            -- 棚卸数量
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- 棚卸金額
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- 原価管理区分が「標準原価」の場合
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- 原価管理区分が「実際原価」の場合
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- 差異数量
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- 差異金額
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- 品目コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
        END IF ;
--
        ------------------------------
        -- 品目コードＧ開始タグ
        ------------------------------
        prc_set_xml('T', 'g_item');
        -- -----------------------------------------------------
        -- 品目コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 品目コード
        prc_set_xml('D', 'item_code', gt_main_data(i).item_code);
        -- 品目名称
        prc_set_xml('D', 'item_name', gt_main_data(i).item_name, 20);
--
        -- -----------------------------------------------------
        -- 品目単位での項目取得
        -- -----------------------------------------------------
        -- 単価
        ln_unit_price := fnc_get_item_unit_price(i) ;
--
        -- -----------------
        -- 受払VIEWより取得
        -- -----------------
        prc_get_inv_qty_amt(ir_param, i, gv_exec_year_month_bef, ln_inv_qty, ln_inv_amt);
--
        -- -----------------------------------------------------
        -- 月首データタグ出力
        -- -----------------------------------------------------
        prc_get_fst_end_inv_qty_amt(ir_param, i, gv_exec_year_month_bef,
                                              ln_first_inv_qty, ln_first_inv_amt);
        -- 数量
        ln_first_inv_qty := ln_first_inv_qty + ln_inv_qty;
        prc_set_xml('Z', 'first_inv_qty' , TO_CHAR(ln_first_inv_qty) );
        -- 金額
        IF (NVL( gt_main_data(i).cost_kbn, lc_break_null ) = gc_cost_st ) THEN
          -- 原価管理区分が「標準原価」の場合
          ln_first_inv_amt := (ln_first_inv_qty + ln_inv_qty) * ln_unit_price;
        ELSE
          -- 原価管理区分が「実際原価」の場合
          IF (gt_main_data(i).lot_ctl = gn_lot_ctl_y) THEN
            ln_first_inv_amt := ln_first_inv_amt + ln_inv_amt;
          ELSE
            ln_first_inv_amt := (ln_first_inv_qty + ln_inv_qty) * ln_unit_price;
          END IF;
        END IF;
        prc_set_xml('Z', 'first_inv_amt' , TO_CHAR(ln_first_inv_amt) );
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_code   := NVL( gt_main_data(i).item_code, lc_break_null ) ;
        lv_cost_kbn    := NVL( gt_main_data(i).cost_kbn, lc_break_null ) ;
        IF ( (lv_cost_kbn = gc_cost_ac) AND (gt_main_data(i).lot_ctl = gn_lot_ctl_n) ) THEN
          lv_cost_kbn  := gc_cost_st;
        END IF;
        lv_column_no   := lc_break_init ;
--
        -- 計算項目初期化
        ln_quantity := 0;
        ln_amount   := 0;
        ln_qty_in   := 0;
        ln_qty_out  := 0;
        ln_amt_in   := 0;
        ln_amt_out  := 0;
--
      END IF ;
--
      -- =====================================================
      -- 項目位置ブレイク
      -- =====================================================
      -- 項目位置が切り替わった場合
      IF (NVL( gt_main_data(i).column_no, lc_break_null ) <> lv_column_no ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は明細タグを出力しない。
        IF ( lv_column_no <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- 明細データタグ出力
          -- -----------------------------------------------------
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- 払出項目の場合
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- 数量
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 金額
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- 数量・金額を集計（品目単位）
          IF (lb_payout = FALSE) THEN
            -- 受入
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- 払出
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
        END IF ;
--
        -- キーブレイク用変数退避
        lv_column_no   := NVL( gt_main_data(i).column_no, lc_break_null ) ;
--
        -- 計算項目初期化
        ln_quantity := 0;
        ln_amount   := 0;
        lv_col_name := lc_break_init;
--
        -- 項目判定初期化
        lb_trnsfr   := FALSE;
        lb_payout   := FALSE;
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
      CASE lv_column_no
        -- **【受入】**
        -- 仕入
        WHEN gc_col_no_po THEN
          lv_col_name := 'po';
        -- 包装
        WHEN gc_col_no_wrap THEN
          lv_col_name := 'wrap';
        -- セット
        WHEN gc_col_no_set THEN
          lv_col_name := 'set';
        -- 沖縄
        WHEN gc_col_no_oki THEN
          lv_col_name := 'okinawa';
        -- 振替入庫
        WHEN gc_col_no_trnsfr THEN
          lv_col_name := 'trnsfr';
          lb_trnsfr   := TRUE;
        -- 緑営１
        WHEN gc_col_no_acct_1 THEN
          lv_col_name := 'acct_1';
          lb_trnsfr   := TRUE;
        -- 緑営２
        WHEN gc_col_no_acct_2 THEN
          lv_col_name := 'acct_2';
          lb_trnsfr   := TRUE;
        -- ドリンクギフト
        WHEN gc_col_no_guift THEN
          lv_col_name := 'guift';
          lb_trnsfr   := TRUE;
        -- 倉替
        WHEN gc_col_no_locat_chg THEN
          lv_col_name := 'locat_chg';
        -- 返品
        WHEN gc_col_no_ret_goods THEN
          lv_col_name := 'ret_goods';
        -- その他
        WHEN gc_col_no_other THEN
          lv_col_name := 'other';
        -- **【払出】**
        -- セット
        WHEN gc_col_no_out_set THEN
          lv_col_name := 'out_set';
          lb_payout   := TRUE;
        -- 返品原料へ
        WHEN gc_col_no_out_mtrl THEN
          lv_col_name := 'out_mtrl';
          lb_payout   := TRUE;
        -- 解体半製品へ
        WHEN gc_col_no_out_dismnt THEN
          lv_col_name := 'out_dismnt';
          lb_payout   := TRUE;
        -- 有償
        WHEN gc_col_no_out_pay THEN
          lv_col_name := 'out_pay';
          lb_payout   := TRUE;
        -- 振替有償
        WHEN gc_col_no_out_trnsfr THEN
          lv_col_name := 'out_trnsfr';
          lb_payout   := TRUE;
          lb_trnsfr   := TRUE;
        -- 拠点
        WHEN gc_col_no_out_point THEN
          lv_col_name := 'out_point';
          lb_payout   := TRUE;
        -- ドリンクギフト
        WHEN gc_col_no_out_guift THEN
          lv_col_name := 'out_guift';
          lb_payout   := TRUE;
          lb_trnsfr   := TRUE;
        -- その他
        WHEN gc_col_no_out_other THEN
          lv_col_name := 'out_other';
          lb_payout   := TRUE;
        ELSE
          lv_col_name := lc_break_init;
      END CASE;
--
      -- 項目名が初期値以外
      IF (lv_col_name <> lc_break_init) THEN
        -- 振替項目の場合
        IF (lb_trnsfr = TRUE) THEN
          -- 数量加算
          ln_quantity := ln_quantity + (NVL( gt_main_data(i).trans_qty, 0 )
                                        * NVL( gt_main_data(i).rcv_pay_div, 0));
          -- 金額加算（原価管理区分が「実際原価」の場合）
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            ln_amount := ln_amount + (NVL(gt_main_data(i).trans_qty,0)
                                      * NVL(gt_main_data(i).actual_unit_price,0)
                                      * NVL( gt_main_data(i).rcv_pay_div, 0));
          END IF;
        ELSE
          -- 数量加算
          ln_quantity := ln_quantity + NVL( gt_main_data(i).trans_qty, 0 );
          -- 金額加算（原価管理区分が「実際原価」の場合）
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            ln_amount := ln_amount + (NVL(gt_main_data(i).trans_qty,0)
                                      * NVL(gt_main_data(i).actual_unit_price,0));
          END IF;
        END IF;
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
--
    -- 金額算出（原価管理区分が「標準原価」の場合）
    IF (lv_cost_kbn = gc_cost_st ) THEN
      ln_amount := ln_unit_price * ln_quantity;
    END IF;
    -- 払出項目の場合
    IF (lb_payout = TRUE) THEN
      ln_quantity := ln_quantity * -1;
      ln_amount   := ln_amount * -1;
    END IF;
    -- 数量
    prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
    -- 金額
    prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
    -- 数量・金額を集計（品目単位）
    IF (lb_payout = FALSE) THEN
      -- 受入
      ln_qty_in := ln_qty_in + ln_quantity;
      ln_amt_in := ln_amt_in + ln_amount;
    ELSE
      -- 払出
      ln_qty_out := ln_qty_out + ln_quantity;
      ln_amt_out := ln_amt_out + ln_amount;
    END IF;
--
    -- -----------------------------------------------------
    -- 月末データタグ出力
    -- -----------------------------------------------------
    -- 数量
    ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
    prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
    -- 金額
    ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
    prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
    -- -----------------
    -- 受払VIEWより取得
    -- -----------------
    prc_get_inv_qty_amt(ir_param, gt_main_data.COUNT, ir_param.exec_year_month,
                        ln_inv_qty, ln_inv_amt);
--
    -- -----------------------------------------------------
    -- 棚卸・差異データタグ出力
    -- -----------------------------------------------------
    prc_get_fst_end_inv_qty_amt(ir_param, gt_main_data.COUNT, ir_param.exec_year_month,
                                          ln_end_inv_qty, ln_end_inv_amt);
    IF (ln_end_inv_qty = 0) THEN
      -- 在庫数量が確定していない場合
      prc_set_xml('N', 'inv_qty'  , '0');
      prc_set_xml('N', 'inv_amt'  , '0');
      prc_set_xml('N', 'quantity' , '0');
      prc_set_xml('N', 'amount'   , '0');
    ELSE
      -- 在庫数量が確定している場合
      -- 棚卸数量
      ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
      prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
      -- 棚卸金額
      IF (lv_cost_kbn = gc_cost_st ) THEN
        -- 原価管理区分が「標準原価」の場合
        ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
      ELSE
        -- 原価管理区分が「実際原価」の場合
        ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
      END IF;
      prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
      -- 差異数量
      ln_quantity := ln_quantity - ln_end_inv_qty;
      prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
      -- 差異金額
      ln_amount := ln_amount - ln_end_inv_amt ;
      prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
    END IF;
    ------------------------------
    -- 品目コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_item');
    ------------------------------
    -- 品目コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- 群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_dtl');
    ------------------------------
    -- 群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_dtl');
    ------------------------------
    -- 小群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_low');
    ------------------------------
    -- 小群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_low');
    ------------------------------
    -- 中群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_mid');
    ------------------------------
    -- 中群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_mid');
    ------------------------------
    -- 大群コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_crowd_high');
    ------------------------------
    -- 大群コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_crowd_high');
    ------------------------------
    -- 倉庫コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_locat');
    ------------------------------
    -- 倉庫コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_locat');
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
      iv_exec_year_month    IN     VARCHAR2         --   01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         --   02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   03 : 品目区分
     ,iv_print_kind         IN     VARCHAR2         --   04 : 帳票種別
     ,iv_locat_code         IN     VARCHAR2         --   05 : 倉庫コード
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 群種別
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
    gv_report_id                    := 'XXCMN770002T' ;      -- 帳票ID
    gd_exec_date                    := SYSDATE ;             -- 実施日
    -- パラメータ格納
    lr_param_rec.exec_year_month    := iv_exec_year_month;   -- 処理年月
    lr_param_rec.goods_class        := iv_goods_class ;      -- 商品区分
    lr_param_rec.item_class         := iv_item_class ;       -- 品目区分
    lr_param_rec.print_kind         := iv_print_kind;        -- 帳票区分
    lr_param_rec.locat_code         := iv_locat_code;        -- 倉庫コード
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
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
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         --   02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   03 : 品目区分
     ,iv_print_kind         IN     VARCHAR2         --   04 : 帳票種別
     ,iv_locat_code         IN     VARCHAR2         --   05 : 倉庫コード
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 群種別
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
        iv_exec_year_month   => iv_exec_year_month   --   01 : 処理年月
       ,iv_goods_class       => iv_goods_class       --   02 : 商品区分
       ,iv_item_class        => iv_item_class        --   03 : 品目区分
       ,iv_print_kind        => iv_print_kind        --   04 : 帳票種別
       ,iv_locat_code        => iv_locat_code        --   05 : 倉庫コード
       ,iv_crowd_kind        => iv_crowd_kind        --   06 : 群種別
       ,iv_crowd_code        => iv_crowd_code        --   07 : 群コード
       ,iv_acct_crowd_code   => iv_acct_crowd_code   --   08 : 経理群コード
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
END xxcmn770002c ;
/
