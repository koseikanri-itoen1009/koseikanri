CREATE OR REPLACE PACKAGE BODY xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770004C(body)
 * Description      : 受払その他実績リスト
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.9
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(D-1)
 *  prc_get_report_data       PROCEDURE : データ取得(D-2)
 *  fnc_item_unit_pric_get    FUNCTION  : 標準原価の取得
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/09    1.0   C.Kinjo          新規作成
 *  2008/05/12    1.1   M.Hamamoto       着荷日の抽出が行われていない
 *  2008/05/16    1.2   T.Endou          不具合ID:5,6,7,8対応
 *                                       5 YYYYMでも正常に抽出されるように修正
 *                                       6 ヘッダの出力日付と「担当：」を合わせました
 *                                       7 帳票名が＜帳票ID＞の下にしました
 *                                       8 品目区分名称、商品区分名称の文字最大長を考慮しました
 *  2008/05/28    1.3   Y.Ishikawa       ロット管理外の場合、ロット情報はNULLを出力する。
 *  2008/05/30    1.4   Y.Ishikawa       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *  2008/06/13    1.5   T.Endou          着荷日が無い場合は、予定着荷日を使用する
 *                                       生産原料詳細（アドオン）を結合条件から外す
 *  2008/06/19    1.6   Y.Ishikawa       取引区分が廃却、見本に関しては、受払区分を掛けない
 *  2008/06/25    1.7   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/07    1.8   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma04_v」
 *  2008/08/20    1.9   A.Shiina         結合指摘#14対応
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770004C' ;           -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '受払その他実績リスト' ;   -- 帳票名
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- アプリケーション
--
  ------------------------------
  -- 原価管理区分
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0' ;   --実際原価
  gc_cost_st              CONSTANT VARCHAR2(1) := '1' ;   --標準原価
--
  ------------------------------
  -- ロット管理区分
  ------------------------------
  gv_lot_n                CONSTANT xxcmn_lot_each_item_v.lot_ctl%TYPE := 0; -- ロット管理なし
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_goods_class  CONSTANT VARCHAR2(100) := '商品区分' ;
  gc_cat_set_item_class   CONSTANT VARCHAR2(100) := '品目区分' ;
--
  ------------------------------
  -- 取引区分名
  ------------------------------
  gv_haiki                   CONSTANT VARCHAR2(100) := '廃却' ;
  gv_mihon                   CONSTANT VARCHAR2(100) := '見本' ;
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
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
  gn_one                 CONSTANT NUMBER        := 1   ;
  gn_two                 CONSTANT NUMBER        := 2   ;
  gc_ja                  CONSTANT VARCHAR2( 5) := 'JA' ;
  ------------------------------
  -- 数値・金額小数点位置
  ------------------------------
  gn_quantity_decml        NUMBER  := 3;
  gn_amount_decml          NUMBER  := 0;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(7)                             -- 処理年月
     ,goods_class         mtl_categories_b.segment1%TYPE          -- 商品区分
     ,item_class          mtl_categories_b.segment1%TYPE          -- 品目区分
     ,div_type1           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- 受払区分１
     ,div_type2           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- 受払区分２
     ,div_type3           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- 受払区分３
     ,div_type4           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- 受払区分４
     ,div_type5           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- 受払区分５
     ,reason_code         sy_reas_cds_tl.reason_code%TYPE         -- 事由コード
    ) ;
--
  -- 実績リストデータ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
      div_tocode         VARCHAR2(100)                                 -- 受払先コード
     ,div_toname         VARCHAR2(100)                                 -- 受払先名
     ,h_reason_code      gmd_routings_b.attribute14%TYPE               -- 事由コード
     ,h_reason_name      sy_reas_cds_tl.reason_desc1%TYPE              -- 事由コード名
     ,dept_code          oe_order_headers_all.attribute11%TYPE         -- 成績部署コード
     ,dept_name          xxcmn_locations2_v.location_short_name%TYPE   -- 成績部署名
     ,trans_date         DATE                                          -- 取引日
     ,h_div_code         xxcmn_rcv_pay_mst.new_div_account%TYPE        -- 受払区分
     ,h_div_name         fnd_lookup_values.meaning%TYPE                -- 受払区分名
     ,item_id            ic_item_mst_b.item_id%TYPE                    -- 品目ＩＤ
     ,h_item_code        ic_item_mst_b.item_no%TYPE                    -- 品目コード
     ,h_item_name        xxcmn_item_mst_b.item_short_name%TYPE         -- 品目名
     ,locat_code         mtl_item_locations.segment1%TYPE              -- 倉庫コード
     ,locat_name         mtl_item_locations.description%TYPE           -- 倉庫名
     ,wip_date           ic_lots_mst.attribute1%TYPE                   -- 製造日
     ,lot_no             ic_lots_mst.lot_no%TYPE                       -- ロットNo
     ,original_char      ic_lots_mst.attribute2%TYPE                   -- 固有記号
     ,use_by_date        ic_lots_mst.attribute3%TYPE                   -- 賞味期限
     ,cost_kbn           ic_item_mst_b.attribute15%TYPE                -- 原価管理区分
     ,lot_kbn            xxcmn_lot_each_item_v.lot_ctl%TYPE            -- ロット管理区分
     ,actual_unit_price  xxcmn_lot_cost.unit_ploce%TYPE                -- 実際原価
     ,trans_qty          ic_tran_pnd.trans_qty%TYPE                    -- 取引数量
     ,description        ic_lots_mst.attribute18%TYPE                  -- 摘要
   ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ヘッダ情報取得用
  ------------------------------
-- 帳票種別
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- 担当者
  gv_goods_class_name       mtl_categories_tl.description%TYPE;               -- 商品区分名
  gv_item_class_name        mtl_categories_tl.description%TYPE;               -- 品目区分名
  gv_reason_name            sy_reas_cds_tl.reason_desc1%TYPE;                 -- 事由コード名
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
   * Description      : 前処理(D-1)
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
    -- -------------------------------
    -- エラーメッセージ出力用
    -- -------------------------------
    -- エラーコード
    lc_err_code        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010' ;
    -- トークン名
    lc_token_name_01   CONSTANT VARCHAR2(100) := 'PARAMETER' ;
    lc_token_name_02   CONSTANT VARCHAR2(100) := 'VALUE' ;
    -- トークン値
    lc_token_value     CONSTANT VARCHAR2(100) := '処理年月' ;
--
    -- *** ローカル変数 ***
    -- -------------------------------
    -- エラーハンドリング用
    -- -------------------------------
    ln_ret_num                NUMBER ;        -- 共通関数戻り値：数値型
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
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
      FROM   xxcmn_categories_v cat
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
      FROM   xxcmn_categories_v cat
      WHERE  cat.category_set_name = gc_cat_set_item_class
      AND    cat.segment1          = ir_param.item_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 事由コード名取得
    -- ====================================================
    gv_reason_name := NULL;
    IF ( ir_param.reason_code IS NOT NULL ) THEN
      BEGIN
        SELECT sy.reason_desc1
        INTO   gv_reason_name
        FROM   sy_reas_cds_tl sy
        WHERE  sy.reason_code   = ir_param.reason_code
          AND  sy.language = gc_ja
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END ;
    END IF;
--
    -- ====================================================
    -- 処理年月
    -- ====================================================
    -- 日付変換チェック
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.exec_year_month ) ;
    BEGIN
      IF ( ln_ret_num = 1 ) THEN
        RAISE parameter_check_expt ;
      END IF ;
    EXCEPTION
      --*** パラメータチェック例外 ***
      WHEN parameter_check_expt THEN
        -- メッセージセット
        lv_errmsg := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                              ,iv_name          => lc_err_code
                                              ,iv_token_name1   => lc_token_name_01
                                              ,iv_token_name2   => lc_token_name_02
                                              ,iv_token_value1  => lc_token_value
                                              ,iv_token_value2  => ir_param.exec_year_month ) ;
        ov_errmsg  := lv_errmsg ;
        ov_errbuf  := lv_errmsg ;
        ov_retcode := gv_status_error ;
    END;
--
  EXCEPTION
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
   * Description      : 明細データ取得(D-2)
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
    cv_div_type    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_NEW_ACCOUNT_DIV';
    cv_out_flag    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cv_line_type   CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_LINE_TYPE';
    cv_deal_div    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_DEALINGS_DIV';
    cv_yes                  CONSTANT VARCHAR2( 1) := 'Y' ;
    cv_doc_type_porc        CONSTANT VARCHAR2(10) := 'PORC' ;
    cv_doc_type_omso        CONSTANT VARCHAR2(10) := 'OMSO' ;
    cv_doc_type_prod        CONSTANT VARCHAR2(10) := 'PROD' ;
    cv_doc_type_xfer        CONSTANT VARCHAR2(10) := 'XFER' ;
    cv_doc_type_trni        CONSTANT VARCHAR2(10) := 'TRNI' ;
    cv_doc_type_adji        CONSTANT VARCHAR2(10) := 'ADJI' ;
    cv_po                   CONSTANT VARCHAR2(10) := 'PO' ;
    cv_ship_type            CONSTANT VARCHAR2( 2) := '1' ;
    cv_pay_type             CONSTANT VARCHAR2( 2) := '2' ;
    cv_comp_flg             CONSTANT VARCHAR2( 2) := '1' ;
    cv_ovlook_pay           CONSTANT VARCHAR2(10) := 'X942' ; -- 黙視品目払出
    cv_sonota_pay           CONSTANT VARCHAR2(10) := 'X951' ; -- その他払出
    cv_move_result          CONSTANT VARCHAR2(10) := 'X122' ; -- 移動実績
    cv_vendor_rma           CONSTANT VARCHAR2( 5) := 'X201' ; -- 仕入先返品
    cv_hamaoka_rcv          CONSTANT VARCHAR2( 5) := 'X988' ; -- 浜岡受入
    cv_party_inv            CONSTANT VARCHAR2( 5) := 'X977' ; -- 相手先在庫
    cv_move_correct         CONSTANT VARCHAR2( 5) := 'X123' ; -- 移動実績訂正
    cv_div_pay              CONSTANT VARCHAR2( 2) := '-1' ;
    cv_div_rcv              CONSTANT VARCHAR2( 2) := '1' ;
    lc_f_day                CONSTANT VARCHAR2(2)  := '01';
    lc_f_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    cv_div_kind_transfer    CONSTANT VARCHAR2(10) := '品種振替';   -- 取引区分：品種振替
    cv_div_item_transfer    CONSTANT VARCHAR2(10) := '品目振替';   -- 取引区分：品目振替
    cv_line_type_material   CONSTANT VARCHAR2( 2) := '1';     -- ラインタイプ：原料
    cv_line_type_product    CONSTANT VARCHAR2( 2) := '-1';    -- ラインタイプ：製品
--
    -- *** ローカル・変数 ***
    lv_sql1        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_sql2        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    -- 受払View
    lv_sql_xfer        VARCHAR2(9000);
    lv_sql_trni        VARCHAR2(9000);
    lv_sql_adji1       VARCHAR2(9000);
    lv_sql_adji2       VARCHAR2(9000);
    lv_sql_adji_x201   VARCHAR2(9000);
    lv_sql_adji_x988   VARCHAR2(9000);
    lv_sql_adji_x123   VARCHAR2(9000);
    lv_sql_prod1       VARCHAR2(9000);
    lv_sql_prod2       VARCHAR2(9000);
    lv_sql_porc1       VARCHAR2(9000);
    lv_sql_porc2       VARCHAR2(9000);
    lv_sql_omso        VARCHAR2(9000);
    lv_sql_para        VARCHAR2(2000);
    lv_select          VARCHAR2(2000);
    lv_from            VARCHAR2(2000);
    lv_where           VARCHAR2(2000);
    lv_order_by        VARCHAR2(2000);
    --積送あり(xfer)
    lv_select_xfer     VARCHAR2(3000);
    lv_from_xfer       VARCHAR2(3000);
    lv_where_xfer      VARCHAR2(3000);
    --積送なし(trni)
    lv_select_trni     VARCHAR2(3000);
    lv_from_trni       VARCHAR2(3000);
    lv_where_trni      VARCHAR2(3000);
    --生産関連(adji)
    lv_select_adji     VARCHAR2(3000);
    lv_from_adji       VARCHAR2(3000);
    lv_where_adji      VARCHAR2(3000);
    --在庫関連(prod)
    lv_select_prod     VARCHAR2(3000);
    lv_from_prod       VARCHAR2(3000);
    lv_where_prod      VARCHAR2(5000);
    --購買関連(porc)
    lv_select_porc     VARCHAR2(3000);
    lv_from_porc       VARCHAR2(3000);
    lv_where_porc      VARCHAR2(3000);
    --受注関連(omso)
    lv_select_omso     VARCHAR2(3000);
    lv_from_omso       VARCHAR2(3000);
    lv_where_omso      VARCHAR2(3000);
--  抽出用開始終了日付
    ld_start_date      DATE;
    ld_end_date        DATE;
    lv_start_date      VARCHAR2(20);
    lv_end_date        VARCHAR2(20);
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
    -- 集計期間設定
    ld_start_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month ||
                                             lc_f_day, gc_char_d_format);
    lv_start_date := TO_CHAR(ld_start_date, gc_char_d_format) || lc_f_time ;
    ld_end_date   := LAST_DAY(ld_start_date);
    lv_end_date   := TO_CHAR(ld_end_date, gc_char_d_format) || lc_e_time ;
--
    -- 受払区分(新経理受払区分)ﾊﾟﾗﾒｰﾀ値設定
    lv_sql_para :=
           '   AND rpmv.new_div_account in (''' || ir_param.div_type1 || ''''     -- 受払区分１
      ;
    -- 受払区分２が入力されている場合
    IF ( ir_param.div_type2 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type2 || ''' '
             ;
    END IF;
    -- 受払区分３が入力されている場合
    IF ( ir_param.div_type3 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type3 || ''' '
             ;
    END IF;
    -- 受払区分４が入力されている場合
    IF ( ir_param.div_type4 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type4 || ''' '
             ;
    END IF;
    -- 受払区分５が入力されている場合
    IF ( ir_param.div_type5 IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' , ''' || ir_param.div_type5 || ''' '
             ;
    END IF;
    lv_sql_para := lv_sql_para
           || ')'
           ;
    -- 事由コードが入力されている場合
    IF ( ir_param.reason_code IS NOT NULL ) THEN
      lv_sql_para := lv_sql_para
             || ' AND rpmv.reason_code  = ''' || ir_param.reason_code || ''''
             ;
    END IF;
    -- ====================================================
    -- 共通SELECT句
    -- ====================================================
    lv_select := '  ,trn.trans_date           AS trans_date'        -- 取引日
              || '  ,rpmv.new_div_account     AS new_div_account'   -- 受払区分
              || '  ,xlv1.meaning             AS div_name'          -- 受払区分名
              || '  ,trn.item_id              AS item_id'           -- 品目ＩＤ
              || '  ,xlei.item_code           AS item_code'         -- 品目コード
              || '  ,xlei.item_short_name     AS item_name'         -- 品目名称
              || '  ,trn.whse_code            AS whse_code'         -- 倉庫コード
              || '  ,iwm.whse_name            AS whse_name'         -- 倉庫名称
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute1)     AS wip_date'          -- 製造日
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_no)             AS lot_no'            -- ロット
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute2)     AS original_char'     -- 固有記号
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute3)     AS use_by_date'       -- 賞味期限
              || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- 原価管理区分
              || '  ,xlei.lot_ctl             AS lot_ctl'           -- ロット管理区分
              || '  ,xlei.actual_unit_price   AS actual_unit_price' -- 実際単価
-- 2008/08/20 v1.9 UPDATE START
--              || '  ,trn.trans_qty            AS trans_qty'         -- 数量
              || '  ,trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div) AS trans_qty' -- 数量
-- 2008/08/20 v1.9 UPDATE END
              || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
              || '  ,xlei.lot_attribute18)    AS lot_desc'          -- 摘要
              ;
    -- ====================================================
    -- 共通FROM句
    -- ====================================================
    lv_from := ',xxcmn_lot_each_item_v     xlei'    -- ロット別品目情報
            || ',ic_whse_mst               iwm'     -- OPM倉庫マスタ
            || ',xxcmn_lookup_values2_v    xlv1'    -- クイックコード(受払区分)
            || ',xxcmn_lookup_values2_v    xlv2'    -- クイックコード(帳票別)
            ;
    -- ====================================================
    -- 共通WHERE句
    -- ====================================================
    lv_where := ' AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--取引日
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--取引日
      || '   AND xlei.prod_div   = ''' || ir_param.goods_class || ''''  -- ﾊﾟﾗﾒｰﾀ：商品区分
      || '   AND xlei.item_div   = ''' || ir_param.item_class || ''''   -- ﾊﾟﾗﾒｰﾀ：品目区分
      || lv_sql_para   -- ﾊﾟﾗﾒｰﾀ設定
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- ロット別品目情報VIEWの絞込み条件
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM倉庫マスタの絞込み条件
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- クイックコードIEWの絞込み条件
      -- 受払区分
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- 帳票別
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- 帳票フラグ（770Dの場合）
      ;
    -- ----------------------------------------------------
    -- ＸＦＥＲ部分_生成
    -- ----------------------------------------------------
--
    lv_select_xfer := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_xfer := ' FROM'
      || ' xxcmn_rcv_pay_mst_xfer_v  rpmv'    -- 受払View_XFER
      || ',ic_tran_pnd               trn'     -- OPM保留在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_xfer_mst               ixm'     -- ＯＰＭ在庫転送マスタ
      || ',xxinv_mov_req_instr_lines xmril'   -- 移動依頼／指示明細（アドオン）
      ;
--
    lv_where_xfer := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_xfer || ''''
      || '   AND trn.reason_code         = ''' || cv_move_result || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
      || '   AND trn.doc_id              = ixm.transfer_id'
      || '   AND ixm.attribute1          = xmril.mov_line_id'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_xfer := lv_select_xfer || lv_select ||
                   lv_from_xfer   || lv_from   ||
                   lv_where_xfer  || lv_where;
--
    -- ----------------------------------------------------
    -- ＴＲＮＩ部分_生成
    -- ----------------------------------------------------
--
    lv_select_trni := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_trni := ' FROM'
      || ' xxcmn_rcv_pay_mst_trni_v    rpmv'  -- 受払View_TRNI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- ＯＰＭ在庫調整ジャーナル
      || ',ic_jrnl_mst                 ijm'   -- ＯＰＭジャーナルマスタ
      || ',xxinv_mov_req_instr_lines   xmril' -- 移動依頼／指示明細（アドオン）
      ;
--
    lv_where_trni := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_trni || ''''
      || '   AND trn.reason_code         = ''' || cv_move_result || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.rcv_pay_div'
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
      || '   AND trn.doc_type            = iaj.trans_type'
      || '   AND trn.doc_id              = iaj.doc_id'
      || '   AND trn.doc_line            = iaj.doc_line'
      || '   AND iaj.journal_id          = ijm.journal_id'
      || '   AND ijm.attribute1          = xmril.mov_line_id'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_trni := lv_select_trni || lv_select ||
                   lv_from_trni   || lv_from   ||
                   lv_where_trni  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- ＡＤＪＩ部分_生成(黙視品目払出、その他払出、仕入先返品、浜岡受入、
    --                   相手先在庫、移動実績訂正以外)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- 受払View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         <> ''' || cv_ovlook_pay || ''''   -- 黙視品目払出
      || '   AND trn.reason_code         <> ''' || cv_sonota_pay || ''''   -- その他払出
      || '   AND trn.reason_code         <> ''' || cv_vendor_rma || ''''   -- 仕入先返品
      || '   AND trn.reason_code         <> ''' || cv_hamaoka_rcv || ''''  -- 浜岡受入
      || '   AND trn.reason_code         <> ''' || cv_party_inv || ''''    -- 相手先在庫
      || '   AND trn.reason_code         <> ''' || cv_move_correct || '''' -- 移動実績訂正
      || '   AND trn.reason_code         = rpmv.reason_code'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_adji1 := lv_select_adji || lv_select ||
                    lv_from_adji   || lv_from   ||
                    lv_where_adji  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- ＡＤＪＩ部分_生成(黙視品目払出、その他払出)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- 受払View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND (trn.reason_code         = ''' || cv_ovlook_pay || ''''   -- 黙視品目払出
      || '    OR trn.reason_code         = ''' || cv_sonota_pay || ''')'   -- その他払出
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE ''' || cv_div_pay || ''''
                                     || '  END'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_adji2 := lv_select_adji || lv_select ||
                    lv_from_adji   || lv_from   ||
                    lv_where_adji  || lv_where;
--
    -- ------------------------------------------------------------------------
    -- ＡＤＪＩ部分_生成(仕入先返品)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- 受払View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst                 ijm'   -- OPMジャーナルマスタ
      || ',xxpo_rcv_and_rtn_txns       xrrt'  -- 受入返品実績アドオン
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_vendor_rma || ''''   -- 仕入先返品
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xrrt.txns_id            = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_adji_x201 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- 初期化
    lv_select_adji   := '';
    lv_from_adji     := '';
    lv_where_adji    := '';
    -- ------------------------------------------------------------------------
    -- ＡＤＪＩ部分_生成(浜岡受入)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- 受払View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst                 ijm'   -- OPMジャーナルマスタ
      || ',xxpo_namaha_prod_txns       xnpt'  -- 生葉実績アドオン
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_hamaoka_rcv || ''''   -- 浜岡受入
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xnpt.entry_number       = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_adji_x988 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- 初期化
    lv_select_adji   := '';
    lv_from_adji     := '';
    lv_where_adji    := '';
    -- ------------------------------------------------------------------------
    -- ＡＤＪＩ部分_生成(移動実績訂正)
    -- ------------------------------------------------------------------------
--
    lv_select_adji := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,rpmv.reason_code         AS reason_code'       -- 事由コード
      || '  ,srct.reason_desc1        AS reason_name'       -- 事由名称
      || '  ,NULL                     AS post_code'         -- 部署コード
      || '  ,NULL                     AS post_name'         -- 部署名
      ;
--
    lv_from_adji := ' FROM'
      || ' xxcmn_rcv_pay_mst_adji_v    rpmv'  -- 受払View_ADJI
      || ',ic_tran_cmp                 trn'   -- OPM在庫トラン
      || ',(SELECT    reason_code'            -- 事由コード
      || '           ,reason_desc1'
      || '    FROM   sy_reas_cds_tl'
      || '    WHERE  language = ''' || gc_ja || ''') srct'
      || ',ic_adjs_jnl                 iaj'   -- OPM在庫調整ジャーナル
      || ',ic_jrnl_mst                 ijm'   -- OPMジャーナルマスタ
      || ',xxinv_mov_req_instr_lines   xmrl'  -- 移動依頼/支持明細
      ;
--
    lv_where_adji := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_adji || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.reason_code         = ''' || cv_move_correct || ''''   -- 移動実績訂正
      || '   AND trn.reason_code         = rpmv.reason_code'
      || '   AND rpmv.rcv_pay_div        = CASE'
                                     || '    WHEN trn.trans_qty >= 0 THEN ''' || cv_div_pay || ''''
                                     || '    WHEN trn.trans_qty < 0 THEN ''' || cv_div_rcv || ''''
                                     || '    ELSE rpmv.rcv_pay_div'
                                     || '  END'
      || '   AND iaj.trans_type          = trn.doc_type'
      || '   AND iaj.doc_id              = trn.doc_id'
      || '   AND iaj.doc_line            = trn.doc_line'
      || '   AND ijm.journal_id          = iaj.journal_id'
      || '   AND xmrl.mov_line_id        = ijm.attribute1'
    ---------------------------------------------------------------------------------------------
    -- 事由コードの絞込み条件
      || ' AND rpmv.reason_code = srct.reason_code(+)'
      ;
--
    -- ＳＱＬ生成
    lv_sql_adji_x123 := lv_select_adji || lv_select ||
                        lv_from_adji   || lv_from   ||
                        lv_where_adji  || lv_where;
--
    -- ----------------------------------------------------
    -- ＰＲＯＤ部分_生成(ＮＵＬＬ)_品種・品目振替以外
    -- ----------------------------------------------------
--
    lv_select_prod := ' SELECT '
      || '   TO_CHAR(rpmv.line_type)  AS div_tocode'        -- 受払先コード
      || '  ,xlv3.meaning             AS div_toname'        -- 受払先名称
      || '  ,NULL                     AS reason_code'       -- 事由コード
      || '  ,NULL                     AS reason_name'       -- 事由名称
      || '  ,rpmv.result_post         AS post_code'         -- 部署コード
      || '  ,loca.location_short_name AS post_name'         -- 部署名
      ;
--
    lv_from_prod := ' FROM'
      || ' xxcmn_rcv_pay_mst_prod_v    rpmv'  -- 受払View_PROD
      || ',ic_tran_pnd                 trn'   -- OPM保留在庫トラン
      -- マスタ情報
      || ',xxcmn_locations2_v        loca'    -- 事業所情報VIEW
      || ',xxcmn_lookup_values2_v    xlv3'    -- クイックコード(ラインタイプ)
      || ',xxcmn_lookup_values2_v    xlv4'    -- クイックコード(取引区分)
      ;
--
    lv_where_prod := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_prod || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.reverse_id          IS NULL'
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.line_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- 事業所情報VIEWの絞込み条件
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- クイックコードIEWの絞込み条件
      -- ラインタイプ
      || ' AND xlv3.lookup_type(+)     = ''' || cv_line_type || ''''
      || ' AND rpmv.line_type          = xlv3.lookup_code(+)'
      || ' AND (xlv3.start_date_active IS NULL OR'
      || ' xlv3.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv3.end_date_active   IS NULL OR'
      || ' xlv3.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv3.language(+)        = ''' || gc_ja || ''''
      || ' AND xlv3.source_lang(+)     = ''' || gc_ja || ''''
      || ' AND xlv3.enabled_flag(+)    = ''' || cv_yes || ''''
      -- 取引区分
      || ' AND xlv4.lookup_type     = ''' || cv_deal_div || ''''
      || ' AND rpmv.dealings_div    = xlv4.lookup_code'
      || ' AND (xlv4.start_date_active IS NULL OR'
      || ' xlv4.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv4.end_date_active   IS NULL OR'
      || ' xlv4.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv4.language        = ''' || gc_ja || ''''
      || ' AND xlv4.source_lang     = ''' || gc_ja || ''''
      || ' AND xlv4.enabled_flag    = ''' || cv_yes || ''''
      || ' AND xlv4.meaning        <> ''' || cv_div_kind_transfer || ''''   -- 品種振替
      || ' AND xlv4.meaning        <> ''' || cv_div_item_transfer || ''''   -- 品目振替
      ;
--
    -- ＳＱＬ生成
    lv_sql_prod1 := lv_select_prod || lv_select ||
                    lv_from_prod   || lv_from   ||
                    lv_where_prod  || lv_where;
--
    -- 初期化
    lv_select_prod := '';
    lv_from_prod   := '';
    lv_where_prod  := '';
--
    -- ----------------------------------------------------
    -- ＰＲＯＤ部分_生成(ＮＵＬＬ)_品種・品目振替
    -- ----------------------------------------------------
--
    lv_select_prod := ' SELECT '
      || '   TO_CHAR(rpmv.line_type)  AS div_tocode'        -- 受払先コード
      || '  ,xlv3.meaning             AS div_toname'        -- 受払先名称
      || '  ,NULL                     AS reason_code'       -- 事由コード
      || '  ,NULL                     AS reason_name'       -- 事由名称
      || '  ,rpmv.result_post         AS post_code'         -- 部署コード
      || '  ,loca.location_short_name AS post_name'         -- 部署名
      || '  ,trn.trans_date           AS trans_date'        -- 取引日
      || '  ,rpmv.new_div_account     AS new_div_account'   -- 受払区分
      || '  ,xlv1.meaning             AS div_name'          -- 受払区分名
      || '  ,trn.item_id              AS item_id'           -- 品目ＩＤ
      || '  ,xlei.item_code           AS item_code'         -- 品目コード
      || '  ,xlei.item_short_name     AS item_name'         -- 品目名称
      || '  ,trn.whse_code            AS whse_code'         -- 倉庫コード
      || '  ,iwm.whse_name            AS whse_name'         -- 倉庫名称
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- 製造日
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ロット
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- 固有記号
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- 賞味期限
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- 原価管理区分
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ロット管理区分
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- 実際単価
      || '  ,trn.trans_qty            AS trans_qty'         -- 数量
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- 摘要
      ;
--
    lv_from_prod := ' FROM'
      || ' xxcmn_rcv_pay_mst_prod_v    rpmv'  -- 受払View_PROD
      || ',ic_tran_pnd                 trn'   -- OPM保留在庫トラン
      || ',ic_tran_pnd                 trn2'  -- OPM保留在庫トラン
      || ',xxcmn_lot_each_item_v       xlei'  -- ロット別品目情報
      || ',xxcmn_lot_each_item_v       xlei2' -- ロット別品目情報
      -- マスタ情報
      || ',ic_whse_mst               iwm'     -- OPM倉庫マスタ
      || ',xxcmn_locations2_v        loca'    -- 事業所情報VIEW
      || ',xxcmn_lookup_values2_v    xlv1'    -- クイックコード(受払区分)
      || ',xxcmn_lookup_values2_v    xlv2'    -- クイックコード(帳票別)
      || ',xxcmn_lookup_values2_v    xlv3'    -- クイックコード(ラインタイプ)
      || ',xxcmn_lookup_values2_v    xlv4'    -- クイックコード(取引区分)
      ;
--
    lv_where_prod := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_prod || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.reverse_id          IS NULL'
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_type           = rpmv.line_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn2.line_type  = CASE'
                        || '   WHEN trn.line_type = ''' || cv_line_type_product || ''''
                        || '        THEN ''' || cv_line_type_material || ''''
                        || '   WHEN trn.line_type = ''' || cv_line_type_material || ''''
                        || '        THEN ''' || cv_line_type_product || ''''
                        || '   END'
      || '   AND trn2.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn2.reverse_id          IS NULL'
      || '   AND trn.doc_id               = trn2.doc_id'
      || '   AND trn.doc_line             = trn2.doc_line'
    -- パラメータ
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--取引日
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--取引日
      || '   AND trn2.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--取引日
      || '   AND trn2.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--取引日
      || '   AND xlei.prod_div = ''' || ir_param.goods_class || ''''
      || '   AND xlei.item_div = ''' || ir_param.item_class || ''''
      || lv_sql_para   -- ﾊﾟﾗﾒｰﾀ設定
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- ロット別品目情報VIEWの絞込み条件
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND trn2.item_id             = xlei2.item_id'
      || ' AND trn2.lot_id              = xlei2.lot_id'
      || ' AND (xlei2.start_date_active IS NULL OR'
      || ' xlei2.start_date_active  <= TRUNC(trn2.trans_date))'
      || ' AND (xlei2.end_date_active   IS NULL OR'
      || ' xlei2.end_date_active    >= TRUNC(trn2.trans_date))'
      || ' AND xlei.item_div = CASE'
                            || '   WHEN trn.line_type = ''' || cv_line_type_product || ''' THEN '
                            || '        rpmv.item_div_origin '
                            || '   WHEN trn.line_type = ''' || cv_line_type_material || '''  THEN'
                            || '        rpmv.item_div_ahead '
                            || ' END'
      || ' AND xlei2.item_div = CASE'
                            || '   WHEN trn.line_type = ''' || cv_line_type_material || ''' THEN'
                            || '        rpmv.item_div_origin'
                            || '   WHEN trn.line_type = ''' || cv_line_type_product || ''' THEN'
                            || '        rpmv.item_div_ahead'
                            || ' END'
      || ' AND rpmv.item_id  = trn.item_id'
    ---------------------------------------------------------------------------------------------
    -- OPM倉庫マスタの絞込み条件
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- 事業所情報VIEWの絞込み条件
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- クイックコードIEWの絞込み条件
      -- 受払区分
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- 帳票別
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- 帳票フラグ（770Dの場合）
      -- ラインタイプ
      || ' AND xlv3.lookup_type(+)     = ''' || cv_line_type || ''''
      || ' AND rpmv.line_type          = xlv3.lookup_code(+)'
      || ' AND (xlv3.start_date_active IS NULL OR'
      || ' xlv3.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv3.end_date_active   IS NULL OR'
      || ' xlv3.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv3.language(+)        = ''' || gc_ja || ''''
      || ' AND xlv3.source_lang(+)     = ''' || gc_ja || ''''
      || ' AND xlv3.enabled_flag(+)    = ''' || cv_yes || ''''
      -- 取引区分
      || ' AND xlv4.lookup_type     = ''' || cv_deal_div || ''''
      || ' AND rpmv.dealings_div    = xlv4.lookup_code'
      || ' AND (xlv4.start_date_active IS NULL OR'
      || ' xlv4.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv4.end_date_active   IS NULL OR'
      || ' xlv4.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv4.language        = ''' || gc_ja || ''''
      || ' AND xlv4.source_lang     = ''' || gc_ja || ''''
      || ' AND xlv4.enabled_flag    = ''' || cv_yes || ''''
      || ' AND xlv4.meaning      in (''' || cv_div_kind_transfer || ''','
                                 || '''' || cv_div_item_transfer || ''')'   -- 品種振替,品目振替
      ;
--
    -- ＳＱＬ生成
    lv_sql_prod2 := lv_select_prod ||
                    lv_from_prod   ||
                    lv_where_prod;
--
    -- ----------------------------------------------------
    -- ＰＯＲＣ部分_生成(PO)
    -- ----------------------------------------------------
--
    lv_select_porc := ' SELECT '
      || '   CASE'
      || '    WHEN rpmv.source_document_code = ''' || cv_po || ''' THEN xvv1.segment1'
      || '    ELSE NULL'
      || '   END AS div_tocode'    -- 受払先コード
      || '  ,CASE'
      || '    WHEN rpmv.source_document_code = ''' || cv_po || ''' THEN xvv1.vendor_short_name'
      || '    ELSE NULL'
      || '   END AS div_toname'    -- 受払先名称
      || '  ,NULL                     AS reason_code'       -- 事由コード
      || '  ,NULL                     AS reason_name'       -- 事由名称
      || '  ,rpmv.result_post         AS post_code'         -- 部署コード
      || '  ,loca.location_short_name AS post_name'         -- 部署名
      ;
--
    lv_from_porc := ' FROM'
      || ' xxcmn_rcv_pay_mst_porc_po_v rpmv'  -- 受払View_PORC
      || ',ic_tran_pnd                 trn'   -- OPM保留在庫トラン
      -- マスタ情報
      || ',xxcmn_vendors2_v          xvv1'    -- 仕入先情報view2
      || ',xxcmn_locations2_v        loca'    -- 事業所情報VIEW
      ;
--
    lv_where_porc := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_porc || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn.line_id             = rpmv.line_id '
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- 事業所情報VIEWの絞込み条件
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- 仕入先情報VIEWの絞込み条件
      || ' AND rpmv.vendor_id          = xvv1.vendor_id(+)'
      || ' AND (xvv1.start_date_active IS NULL OR'
      || ' xvv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xvv1.end_date_active   IS NULL OR'
      || ' xvv1.end_date_active    >= TRUNC(trn.trans_date))'
      ;
--
    -- ＳＱＬ生成
    lv_sql_porc1 := lv_select_porc || lv_select ||
                    lv_from_porc   || lv_from   ||
                    lv_where_porc  || lv_where;
--
    -- 初期化
    lv_select_porc := '';
    lv_from_porc   := '';
    lv_where_porc  := '';
    -- ----------------------------------------------------
    -- ＰＯＲＣ部分_生成(RMA)
    -- ----------------------------------------------------
--
    lv_select_porc := ' SELECT '
      || '   NULL                     AS div_tocode'        -- 受払先コード
      || '  ,NULL                     AS div_toname'        -- 受払先名称
      || '  ,NULL                     AS reason_code'       -- 事由コード
      || '  ,NULL                     AS reason_name'       -- 事由名称
      || '  ,rpmv.result_post         AS post_code'         -- 部署コード
      || '  ,loca.location_short_name AS post_name'         -- 部署名
      || '  ,trn.trans_date           AS trans_date'        -- 取引日
      || '  ,rpmv.new_div_account     AS new_div_account'   -- 受払区分
      || '  ,xlv1.meaning             AS div_name'          -- 受払区分名
      || '  ,NVL(rpmv.item_id,trn.item_id) AS item_id'      -- 品目ＩＤ
      || '  ,ximv.item_no             AS item_code'         -- 品目コード
      || '  ,ximv.item_short_name     AS item_name'         -- 品目名称
      || '  ,trn.whse_code            AS whse_code'         -- 倉庫コード
      || '  ,iwm.whse_name            AS whse_name'         -- 倉庫名称
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- 製造日
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ロット
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- 固有記号
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- 賞味期限
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- 原価管理区分
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ロット管理区分
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- 実際単価
-- 2008/08/20 v1.9 UPDATE START
/*
      || '  ,NVL2(rpmv.item_id, '
      ||      ' trn.trans_qty, '
      ||      ' DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div))) trans_qty ' -- 数量
*/
      ||      ',DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div)) trans_qty ' -- 数量
-- 2008/08/20 v1.9 UPDATE END
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- 摘要
      ;
--
    lv_from_porc := ' FROM'
      || ' xxcmn_rcv_pay_mst_porc_rma04_v rpmv'  -- 受払View_PORC
      || ',ic_tran_pnd                  trn'   -- OPM保留在庫トラン
      || ',xxcmn_item_mst2_v            ximv'  -- 品目マスタVIEW
      || ',xxcmn_locations2_v           loca'  -- 事業所情報VIEW
      ;
--
    lv_where_porc := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_porc || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.doc_id              = rpmv.doc_id'
      || '   AND trn.doc_line            = rpmv.doc_line'
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--取引日
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--取引日
      || '   AND rpmv.prod_div   = ''' || ir_param.goods_class || ''''  -- ﾊﾟﾗﾒｰﾀ：商品区分
      || '   AND rpmv.item_div   = ''' || ir_param.item_class || ''''   -- ﾊﾟﾗﾒｰﾀ：品目区分
      || lv_sql_para   -- ﾊﾟﾗﾒｰﾀ設定
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- ロット別品目情報VIEWの絞込み条件
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- 品目マスタ情報VIEWの絞込み条件
      || ' AND ximv.item_id           = NVL(rpmv.item_id, trn.item_id)'
      || ' AND (ximv.start_date_active IS NULL OR'
      || ' ximv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (ximv.end_date_active   IS NULL OR'
      || ' ximv.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM倉庫マスタの絞込み条件
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- 事業所情報VIEWの絞込み条件
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- クイックコードIEWの絞込み条件
      -- 受払区分
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- 帳票別
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- 帳票フラグ（770Dの場合）
      ;
--
    -- ＳＱＬ生成
    lv_sql_porc2 := lv_select_porc ||
                    lv_from_porc   || lv_from   ||
                    lv_where_porc  ;
--
    -- ----------------------------------------------------
    -- ＯＭＳＯ部分_生成
    -- ----------------------------------------------------
--
    lv_select_omso := ' SELECT '
      || '   CASE'
      || '    WHEN rpmv.shipment_provision_div = ''' || cv_ship_type || ''''
      || '      OR rpmv.shipment_provision_div = ''' || cv_pay_type  || ''''
      || '    THEN xpv.party_number'
      || '    ELSE NULL'
      || '   END AS div_tocode'    -- 受払先コード
      || '  ,CASE'
      || '    WHEN rpmv.shipment_provision_div = ''' || cv_ship_type || ''''
      || '      OR rpmv.shipment_provision_div = ''' || cv_pay_type || ''''
      || '    THEN xpv.party_short_name'
      || '    ELSE NULL'
      || '   END AS div_toname'    -- 受払先名称
      || '  ,NULL                     AS reason_code'       -- 事由コード
      || '  ,NULL                     AS reason_name'       -- 事由名称
      || '  ,rpmv.result_post         AS post_code'         -- 部署コード
      || '  ,loca.location_short_name AS post_name'         -- 部署名
      || '  ,trn.trans_date           AS trans_date'        -- 取引日
      || '  ,rpmv.new_div_account     AS new_div_account'   -- 受払区分
      || '  ,xlv1.meaning             AS div_name'          -- 受払区分名
      || '  ,NVL(rpmv.item_id,trn.item_id) AS item_id'      -- 品目ＩＤ
      || '  ,ximv.item_no             AS item_code'         -- 品目コード
      || '  ,ximv.item_short_name     AS item_name'         -- 品目名称
      || '  ,trn.whse_code            AS whse_code'         -- 倉庫コード
      || '  ,iwm.whse_name            AS whse_name'         -- 倉庫名称
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute1)     AS wip_date'          -- 製造日
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_no)             AS lot_no'            -- ロット
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute2)     AS original_char'     -- 固有記号
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute3)     AS use_by_date'       -- 賞味期限
      || '  ,xlei.item_attribute15    AS cost_mng_clss'     -- 原価管理区分
      || '  ,xlei.lot_ctl             AS lot_ctl'           -- ロット管理区分
      || '  ,xlei.actual_unit_price   AS actual_unit_price' -- 実際単価
-- 2008/08/20 v1.9 UPDATE START
/*
      || '  ,NVL2(rpmv.item_id, '
      ||      ' trn.trans_qty, '
      ||      ' DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div))) trans_qty ' -- 数量
*/
      ||      ',DECODE(rpmv.dealings_div_name,''' || gv_haiki || ''' '
      ||      '       ,trn.trans_qty '
      ||      '       , ''' || gv_mihon || ''' '
      ||      '       ,trn.trans_qty '
      ||      ',trn.trans_qty * TO_NUMBER(rpmv.rcv_pay_div)) trans_qty ' -- 数量
-- 2008/08/20 v1.9 UPDATE END
      || '  ,DECODE(xlei.lot_ctl,'    || gv_lot_n || ',NULL'
      || '  ,xlei.lot_attribute18)    AS lot_desc'          -- 摘要
      ;
--
    lv_from_omso := ' FROM'
      || ' xxcmn_rcv_pay_mst_omso_v    rpmv'  -- 受払View_OMSO
      || ',ic_tran_pnd                 trn'   -- OPM保留在庫トラン
      -- マスタ情報
      || ',xxcmn_party_sites2_v      xpsv'    -- パーティサイト情報View
      || ',xxcmn_parties2_v          xpv'     -- パーティ情報View
      || ',xxcmn_locations2_v        loca'    -- 事業所情報VIEW
      || ',xxcmn_item_mst2_v         ximv'  -- 品目マスタVIEW
      ;
--
    lv_where_omso := ' WHERE'
      || '       trn.doc_type            = ''' || cv_doc_type_omso || ''''
      || '   AND trn.completed_ind       = ''' || cv_comp_flg || ''''
      || '   AND trn.doc_type            = rpmv.doc_type'
      || '   AND trn.line_detail_id      = rpmv.doc_line'
      || '   AND trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--取引日
      || '   AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--取引日
      || '   AND rpmv.prod_div   = ''' || ir_param.goods_class || ''''  -- ﾊﾟﾗﾒｰﾀ：商品区分
      || '   AND rpmv.item_div   = ''' || ir_param.item_class || ''''   -- ﾊﾟﾗﾒｰﾀ：品目区分
      || '   AND DECODE(rpmv.arrival_date,NULL,rpmv.schedule_arrival_date,rpmv.arrival_date)'
      || '     >= FND_DATE.STRING_TO_DATE(''' || lv_start_date || ''',  '''
      ||                                               gc_char_dt_format || ''')'--着荷日
      || '   AND DECODE(rpmv.arrival_date,NULL,rpmv.schedule_arrival_date,rpmv.arrival_date)'
      || '   <= FND_DATE.STRING_TO_DATE(''' || lv_end_date || ''',  '''
      ||                                                   gc_char_dt_format || ''')'--着荷日
      || lv_sql_para   -- ﾊﾟﾗﾒｰﾀ設定
    --マスタ関連
    ---------------------------------------------------------------------------------------------
    -- ロット別品目情報VIEWの絞込み条件
      || ' AND trn.item_id             = xlei.item_id'
      || ' AND trn.lot_id              = xlei.lot_id'
      || ' AND (xlei.start_date_active IS NULL OR'
      || ' xlei.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlei.end_date_active   IS NULL OR'
      || ' xlei.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- 品目マスタ情報VIEWの絞込み条件
      || ' AND ximv.item_id           = NVL(rpmv.item_id, trn.item_id)'
      || ' AND (ximv.start_date_active IS NULL OR'
      || ' ximv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (ximv.end_date_active   IS NULL OR'
      || ' ximv.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- OPM倉庫マスタの絞込み条件
      || ' AND trn.whse_code           = iwm.whse_code'
    ---------------------------------------------------------------------------------------------
    -- 事業所情報VIEWの絞込み条件
      || ' AND rpmv.result_post     = loca.location_code(+)'
      || ' AND (loca.start_date_active IS NULL OR'
      || ' loca.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (loca.end_date_active   IS NULL OR'
      || ' loca.end_date_active    >= TRUNC(trn.trans_date))'
    ---------------------------------------------------------------------------------------------
    -- クイックコードIEWの絞込み条件
      -- 受払区分
      || ' AND xlv1.lookup_type         = ''' || cv_div_type || ''''
      || ' AND rpmv.new_div_account     = xlv1.lookup_code'
      || ' AND (xlv1.start_date_active IS NULL OR'
      || ' xlv1.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv1.end_date_active   IS NULL OR'
      || ' xlv1.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv1.language           = ''' || gc_ja || ''''
      || ' AND xlv1.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv1.enabled_flag       = ''' || cv_yes || ''''
      -- 帳票別
      || ' AND xlv2.lookup_type        = ''' || cv_out_flag || ''''
      || ' AND rpmv.dealings_div       = xlv2.meaning'
      || ' AND (xlv2.start_date_active IS NULL OR'
      || ' xlv2.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlv2.end_date_active   IS NULL OR'
      || ' xlv2.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND xlv2.language           = ''' || gc_ja || ''''
      || ' AND xlv2.source_lang        = ''' || gc_ja || ''''
      || ' AND xlv2.enabled_flag       = ''' || cv_yes || ''''
      || ' AND xlv2.attribute4         IS NOT NULL'   -- 帳票フラグ（770Dの場合）
    ---------------------------------------------------------------------------------------------
    -- パーティ情報VIEWの絞込み条件
      || ' AND xpsv.party_site_id(+) = rpmv.deliver_to_id'
      || ' AND xpsv.party_id = xpv.party_id(+)'
      || ' AND (xpsv.start_date_active IS NULL OR'
      || ' xpsv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xpsv.end_date_active   IS NULL OR'
      || ' xpsv.end_date_active    >= TRUNC(trn.trans_date))'
      || ' AND (xpv.start_date_active IS NULL OR'
      || ' xpv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xpv.end_date_active   IS NULL OR'
      || ' xpv.end_date_active    >= TRUNC(trn.trans_date))'
      ;
--
    -- ＳＱＬ生成
    lv_sql_omso := lv_select_omso ||
                   lv_from_omso   || lv_from   ||
                   lv_where_omso  ;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_order_by := ' ORDER BY'
                || ' new_div_account'   -- 受払区分
                || ',reason_code'       -- 事由コード
                || ',item_code'         -- 品目コード
                || ',whse_code'         -- 倉庫コード
                || ',lot_no'            -- ロットNo
                ;
    lv_sql1 :=  lv_sql_xfer
            ||  ' UNION ALL '
            ||  lv_sql_trni
            ||  ' UNION ALL '
            ||  lv_sql_adji1
            ||  ' UNION ALL '
            ||  lv_sql_adji2
            ||  ' UNION ALL '
            ||  lv_sql_adji_x201
            ||  ' UNION ALL '
            ||  lv_sql_adji_x988
            ||  ' UNION ALL '
            ;
    lv_sql2 :=  lv_sql_adji_x123
            ||  ' UNION ALL '
            ||  lv_sql_prod1
            ||  ' UNION ALL '
            ||  lv_sql_prod2
            ||  ' UNION ALL '
            ||  lv_sql_porc1
            ||  ' UNION ALL '
            ||  lv_sql_porc2
            ||  ' UNION ALL '
            ||  lv_sql_omso
            ||  lv_order_by
            ;
--
    -- ====================================================
    -- データ抽出
    -- ====================================================
    -- オープン
    OPEN lc_ref FOR lv_sql1 || lv_sql2 ;
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
   * Procedure Name   : fnc_item_unit_pric_get
   * Description      : 標準原価の取得
   ***********************************************************************************/
  FUNCTION fnc_item_unit_pric_get(
       iv_item_id    IN   VARCHAR2  -- 品目ＩＤ
      ,id_trans_date IN   DATE)     -- 取引日
      RETURN NUMBER
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_item_unit_pric_get' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    -- 原価戻り値
    on_unit_price NUMBER DEFAULT 0;
--
  BEGIN
    -- =========================================
    -- 標準原価マスタより標準単価を取得します。=
    -- =========================================
    BEGIN
      SELECT stnd_unit_price as price
      INTO   on_unit_price
      FROM   xxcmn_stnd_unit_price_v xsup
      WHERE  xsup.item_id    = iv_item_id
        AND (xsup.start_date_active IS NULL OR
             xsup.start_date_active  <= TRUNC(id_trans_date))
        AND (xsup.end_date_active   IS NULL OR
             xsup.end_date_active    >= TRUNC(id_trans_date));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_unit_price :=  0;
    END;
    RETURN  on_unit_price;
--
  END fnc_item_unit_pric_get;
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
    lc_flg_y                CONSTANT VARCHAR2(1) := 'Y';
    lc_flg_n                CONSTANT VARCHAR2(1) := 'N';
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_div_code         VARCHAR2(100) DEFAULT lc_break_init ;  -- 受払区分
    lv_reason_code      VARCHAR2(100) DEFAULT lc_break_init ;  -- 事由コード
    lv_item_code        VARCHAR2(100) DEFAULT lc_break_init ;  -- 品目コード
    lv_cost_kbn         VARCHAR2(100) DEFAULT lc_break_init ;  -- 原価管理区分
    lv_locat_code       VARCHAR2(100) DEFAULT lc_break_init ;  -- 倉庫コード
    lv_lot_no           VARCHAR2(100) DEFAULT lc_break_init ;  -- ロットNo
    lv_flg              VARCHAR2(1)   DEFAULT lc_break_init;
--
    -- 計算用
    ln_quantity         NUMBER DEFAULT 0 ;      -- 数量
    ln_amount           NUMBER DEFAULT 0 ;      -- 金額
    ln_stand_unit_price NUMBER DEFAULT 0 ;      -- 標準原価
--
    lr_data_dtl         rec_data_type_dtl;      -- 構造体
--
    lb_ret                  BOOLEAN;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
    ---------------------
    -- XMLタグ挿入処理
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       -- タグタイプ  T:タグ
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
--
    -- 帳票ＩＤ
    prc_set_xml('D', 'report_id', gv_report_id);
    -- 実施日
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- 担当部署
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- 担当者名
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
    -- 処理年月
    prc_set_xml('D', 'exec_year', SUBSTR(ir_param.exec_year_month, 1, 4) );
    prc_set_xml('D', 'exec_month', TO_CHAR( SUBSTR(ir_param.exec_year_month, 5, 2), '00') );
    -- 商品区分
    prc_set_xml('D', 'prod_div', ir_param.goods_class);
    prc_set_xml('D', 'prod_div_name', gv_goods_class_name, 20);
    -- 品目区分
    prc_set_xml('D', 'item_div', ir_param.item_class);
    prc_set_xml('D', 'item_div_name', gv_item_class_name, 20);
    -- 事由コード(パラメータ)
    prc_set_xml('D', 'p_reason_code', ir_param.reason_code);
    prc_set_xml('D', 'p_reason_name', gv_reason_name, 20);
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- 受払区分ＬＧ開始タグ出力
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_div');
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 明細出力(改頁時)
      -- =====================================================
      IF  (( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code )
           OR  ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code )
           OR  ( NVL( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ))
      AND (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
--
        -- 金額算出（原価管理区分が「標準原価」の場合）
        IF (lv_cost_kbn = gc_cost_st ) THEN
          ln_amount := ln_stand_unit_price * ln_quantity;
        END IF;
        -- -----------------------------------------------------
        -- ロットＬＧ開始タグ出力
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ロットＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- 明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 倉庫
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- 製造日
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ロットＮｏ
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- 固有記号
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- 賞味期限
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- 数量
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- 単価
        -- 原価管理区分が「実際原価」の場合
        IF (lv_cost_kbn = gc_cost_ac ) THEN
           -- ロット管理区分が「ロット管理有り」の場合
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
           -- ロット管理区分が「ロット管理無し」の場合
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- 原価管理区分が「標準原価」の場合
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- それ以外
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- 入出庫金額
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- 受払先
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- 成績部署
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- 摘要
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ロットＧ終了タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
        -- 計算項目初期化
        ln_quantity := 0;
        ln_amount   := 0;
      END IF;
--
      -- =====================================================
      -- 受払区分ブレイク
      -- =====================================================
      -- 受払区分が切り替わった場合
      IF ( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_div_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ロットＬＧ終了タグ出力
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 事由コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_reason');
          ------------------------------
          -- 事由コードＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_reason');
          ------------------------------
          -- 受払区分Ｇ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_div');
        END IF ;
--
        -- -----------------------------------------------------
        -- 受払区分Ｇ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_div');
        -- -----------------------------------------------------
        -- 受払区分Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 受払区分
        prc_set_xml('D', 'div_code', gt_main_data(i).h_div_code);
        prc_set_xml('D', 'div_name', gt_main_data(i).h_div_name, 20);
        -- -----------------------------------------------------
        -- 事由コードＬＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'lg_reason');
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_div_code := NVL( gt_main_data(i).h_div_code, lc_break_null )  ;
        lv_reason_code  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 事由コードブレイク
      -- =====================================================
      -- 事由コードが切り替わった場合
      IF ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_reason_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ロットＬＧ終了タグ出力
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- 事由コードＧ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_reason');
        END IF ;
--
        -- -----------------------------------------------------
        -- 事由コードＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_reason');
        -- -----------------------------------------------------
        -- 事由コードＧデータタグ出力
        -- -----------------------------------------------------
        -- 事由
        prc_set_xml('D', 'reason_code', gt_main_data(i).h_reason_code);
        prc_set_xml('D', 'reason_name', gt_main_data(i).h_reason_name, 20);
        ------------------------------
        -- 品目ＬＧ開始タグ
        ------------------------------
          prc_set_xml('T', 'lg_item');
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_reason_code := NVL( gt_main_data(i).h_reason_code, lc_break_null ) ;
        lv_item_code   := lc_break_init ;
        lv_cost_kbn    := lc_break_init ;
--
      END IF ;
      -- =====================================================
      -- 品目ブレイク
      -- =====================================================
      -- 品目が切り替わった場合
      IF  (NVL(gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ) THEN
--
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF  ( lv_item_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ロットＬＧ終了タグ出力
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          prc_set_xml('T', '/g_item');
        END IF ;
--
        -- -----------------------------------------------------
        -- 品目Ｇ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_item');
        -- -----------------------------------------------------
        -- 品目Ｇタグ出力
        -- -----------------------------------------------------
        -- 品目
        prc_set_xml('D', 'item_code', gt_main_data(i).h_item_code);
        prc_set_xml('D', 'item_name', gt_main_data(i).h_item_name, 20);
--
        -- 標準原価を取得
        ln_stand_unit_price := fnc_item_unit_pric_get( gt_main_data(i).item_id,
                                                       gt_main_data(i).trans_date);
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_code  := NVL( gt_main_data(i).h_item_code, lc_break_null ) ;
        lv_cost_kbn   := NVL( gt_main_data(i).cost_kbn, lc_break_null ) ;
        lv_locat_code := lc_break_init ;
        lv_lot_no     := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
      IF (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
        IF   (( lr_data_dtl.locat_code <> gt_main_data(i).locat_code )    -- 倉庫コード
           OR ( lr_data_dtl.lot_no     <> gt_main_data(i).lot_no )) THEN   -- ロットNo
--
          -- 金額算出（原価管理区分が「標準原価」の場合）
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_stand_unit_price * ln_quantity;
          END IF;
          -- -----------------------------------------------------
          -- ロットＬＧ開始タグ出力
          -- -----------------------------------------------------
          IF ( lv_flg <> lc_flg_y ) THEN
            prc_set_xml('T', 'lg_lot');
          END IF;
          -- -----------------------------------------------------
          -- ロットＧ開始タグ出力
          -- -----------------------------------------------------
          prc_set_xml('T', 'g_lot');
          -- -----------------------------------------------------
          -- 明細Ｇデータタグ出力
          -- -----------------------------------------------------
          -- 倉庫
          prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
          prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
          -- 製造日
          prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
          -- ロットＮｏ
          prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
          -- 固有記号
          prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
          -- 賞味期限
          prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
          -- 数量
          prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- 単価
          -- 原価管理区分が「実際原価」の場合
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            -- ロット管理区分が「ロット管理有り」の場合
            IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
              prc_set_xml('D', 'unit_price',
                                    TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
            -- ロット管理区分が「ロット管理無し」の場合
            ELSE
              prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
            END IF;
          -- 原価管理区分が「標準原価」の場合
          ELSIF (lv_cost_kbn = gc_cost_st ) THEN
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          -- それ以外
          ELSE
            prc_set_xml('D', 'unit_price', '0');
          END IF;
          -- 入出庫金額
          prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
          -- 受払先
          prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
          prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
          -- 成績部署
          prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
          prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
          -- 摘要
          prc_set_xml('D', 'description', lr_data_dtl.description, 20);
          lv_flg := lc_flg_y;
          -- -----------------------------------------------------
          -- ロットＧ終了タグ出力
          -- -----------------------------------------------------
          prc_set_xml('T', '/g_lot');
          -- 計算項目初期化
          ln_quantity := 0;
          ln_amount   := 0;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- 集計処理
      -- -----------------------------------------------------
      -- 数量加算
      ln_quantity := ln_quantity + NVL(gt_main_data(i).trans_qty, 0);
      -- 金額加算（原価管理区分が「実際原価」の場合）
      IF (lv_cost_kbn = gc_cost_ac ) THEN
        -- ロット管理区分が「ロット管理有り」の場合
        IF (gt_main_data(i).lot_kbn <> gv_lot_n) THEN
          ln_amount := ln_amount
                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
        -- ロット管理区分が「ロット管理無し」の場合
        ELSE
          ln_amount := ln_amount
                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
        END IF;
      END IF;
--
      -- 値を退避
      lv_locat_code := NVL(gt_main_data(i).locat_code, lc_break_null );
      lv_lot_no     := NVL(gt_main_data(i).lot_no, lc_break_null );
      lr_data_dtl   := gt_main_data(i);
--
      -- 最後の明細を出力
      IF ( gt_main_data.LAST = i ) THEN
--
        -- 金額算出（原価管理区分が「標準原価」の場合）
        IF (lv_cost_kbn = gc_cost_st ) THEN
          ln_amount := ln_stand_unit_price * ln_quantity;
        END IF;
        -- -----------------------------------------------------
        -- ロットＬＧ開始タグ出力
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ロットＧ開始タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- 明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 倉庫
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- 製造日
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ロットＮｏ
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- 固有記号
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- 賞味期限
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- 数量
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- 単価
        -- 原価管理区分が「実際原価」の場合
        IF (lv_cost_kbn = gc_cost_ac ) THEN
          -- ロット管理区分が「ロット管理有り」の場合
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
          -- ロット管理区分が「ロット管理無し」の場合
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- 原価管理区分が「標準原価」の場合
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- それ以外
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- 入出庫金額
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- 受払先
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- 成績部署
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- 摘要
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ロットＧ終了タグ出力
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    -- ---------------------------
    -- ロットＬＧ終了タグ出力
    -- ---------------------------
    prc_set_xml('T', '/lg_lot');
    ------------------------------
    -- 品目Ｇ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_item');
    ------------------------------
    -- 品目ＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- 事由コードＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_reason');
    ------------------------------
    -- 事由コードＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_reason');
   ------------------------------
    -- 受払区分Ｇ終了タグ
    ------------------------------
    prc_set_xml('T', '/g_div');
   ------------------------------
    -- 受払区分ＬＧ終了タグ
    ------------------------------
    prc_set_xml('T', '/lg_div');
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
      iv_exec_year_month    IN     VARCHAR2         -- 01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         -- 02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         -- 03 : 品目区分
     ,iv_div_type1          IN     VARCHAR2         -- 04 : 受払区分１
     ,iv_div_type2          IN     VARCHAR2         -- 05 : 受払区分２
     ,iv_div_type3          IN     VARCHAR2         -- 06 : 受払区分３
     ,iv_div_type4          IN     VARCHAR2         -- 07 : 受払区分４
     ,iv_div_type5          IN     VARCHAR2         -- 08 : 受払区分５
     ,iv_reason_code        IN     VARCHAR2         -- 09 : 事由コード
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
    gv_report_id               := 'XXCMN770004T' ;           -- 帳票ID
    gd_exec_date               := SYSDATE ;                  -- 実施日
    -- パラメータ格納
    -- 処理年月
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_exec_year_month, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.exec_year_month     := iv_exec_year_month;
    ELSE
      lr_param_rec.exec_year_month     := lv_work_date;
    END IF;
    lr_param_rec.goods_class      := iv_goods_class;       -- 商品区分
    lr_param_rec.item_class       := iv_item_class;        -- 品目区分
    lr_param_rec.div_type1        := iv_div_type1;         -- 受払区分１
    lr_param_rec.div_type2        := iv_div_type2;         -- 受払区分２
    lr_param_rec.div_type3        := iv_div_type3;         -- 受払区分３
    lr_param_rec.div_type4        := iv_div_type4;         -- 受払区分４
    lr_param_rec.div_type5        := iv_div_type5;         -- 受払区分５
    lr_param_rec.reason_code      := iv_reason_code;       -- 事由コード
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_div>' ) ;
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
     ,iv_div_type1          IN     VARCHAR2         --   04 : 受払区分１
     ,iv_div_type2          IN     VARCHAR2         --   05 : 受払区分２
     ,iv_div_type3          IN     VARCHAR2         --   06 : 受払区分３
     ,iv_div_type4          IN     VARCHAR2         --   07 : 受払区分４
     ,iv_div_type5          IN     VARCHAR2         --   08 : 受払区分５
     ,iv_reason_code        IN     VARCHAR2         --   09 : 事由コード
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
       ,iv_div_type1         => iv_div_type1         --   04 : 受払区分１
       ,iv_div_type2         => iv_div_type2         --   05 : 受払区分２
       ,iv_div_type3         => iv_div_type3         --   06 : 受払区分３
       ,iv_div_type4         => iv_div_type4         --   07 : 受払区分４
       ,iv_div_type5         => iv_div_type5         --   08 : 受払区分５
       ,iv_reason_code       => iv_reason_code       --   09 : 事由コード
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
END xxcmn770004c ;
/
