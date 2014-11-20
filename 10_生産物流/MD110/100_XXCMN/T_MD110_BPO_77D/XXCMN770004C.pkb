CREATE OR REPLACE PACKAGE BODY xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770004c_stest(body)
 * Description      : 受払その他実績リスト
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.25
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
 *  2008/10/27    1.10  A.Shiina         T_S_524対応
 *  2008/11/11    1.11  A.Shiina         移行不具合修正
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#210対応
 *  2008/12/03    1.14  H.Itou           本番#384対応
 *  2008/12/04    1.15  T.Miyata         本番#454対応
 *  2008/12/08    1.16  T.Ohashi         本番障害数値あわせ対応
 *  2008/12/11    1.17  N.Yoshida        本番障害580対応
 *  2008/12/13    1.18  T.Ohashi         本番障害580対応
 *  2008/12/14    1.19  N.Yoshida        本番障害669対応
 *  2008/12/19    1.20  A.Shiina         本番障害812対応
 *                                       実際原価の取得先変更 「xxcmn_lot_cost.unit_ploce」⇒
 *                                                            「ic_lots_mst.attribute7」 
 *  2008/12/22    1.21  A.Shiina         本番障害719対応
 *  2008/03/06    1.22  H.Marushita      本番障害1274対応 伊藤園在庫のみ条件追加
 *  2009/05/29    1.23  Marushita        本番障害1511対応
 *  2009/11/09    1.24  Marushita        本番障害1685対応
 *  2011/03/10    1.25  H.Sasaki         [E_本稼動_06267] 原価管理区分「標準原価」時の金額算出方法変更
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
-- 2008/11/11 v1.11 ADD START
  gv_d_name_trn_rcv          CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替有償_受入';
  gv_d_name_item_trn_rcv     CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '商品振替有償_受入';
  gv_d_name_trn_ship_rcv_gen CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_原';
  gv_d_name_trn_ship_rcv_han CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '振替出荷_受入_半';
  gc_rcv_pay_div_adj         CONSTANT VARCHAR2(2) := '-1' ;  --調整
-- 2008/11/11 v1.11 ADD END
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
-- 2008/12/19 v1.20 UPDATE START
--     ,actual_unit_price  xxcmn_lot_cost.unit_ploce%TYPE                -- 実際原価
     ,actual_unit_price  ic_lots_mst.attribute7%TYPE                   -- 実際原価
-- 2008/12/19 v1.20 UPDATE END
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
  ------------------------------
  --  標準原価評価日付
  ------------------------------
  gd_st_unit_date         DATE; -- 2009/05/29 ADD
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
-- 2008/10/27 v1.10 UPDATE START
--      SELECT cat.description
--      INTO   gv_goods_class_name
--      FROM   xxcmn_categories_v cat
--      WHERE  cat.category_set_name = gc_cat_set_goods_class
--      AND    cat.segment1          = ir_param.goods_class
--      ;
--
      SELECT mct.description
      INTO   gv_goods_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'))
      AND    mcb.segment1         = ir_param.goods_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/27 v1.10 UPDATE END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- 品目区分取得
    -- ====================================================
    BEGIN
-- 2008/10/27 v1.10 UPDATE START
--      SELECT cat.description
--      INTO   gv_item_class_name
--      FROM   xxcmn_categories_v cat
--      WHERE  cat.category_set_name = gc_cat_set_item_class
--      AND    cat.segment1          = ir_param.item_class
--      ;
--
      SELECT mct.description
      INTO   gv_item_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
      AND    mcb.segment1         = ir_param.item_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/27 v1.10 UPDATE END
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
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cv_reason_911             CONSTANT VARCHAR2(5) := 'X911';
    cv_reason_912             CONSTANT VARCHAR2(5) := 'X912';
    cv_reason_921             CONSTANT VARCHAR2(5) := 'X921';
    cv_reason_922             CONSTANT VARCHAR2(5) := 'X922';
    cv_reason_941             CONSTANT VARCHAR2(5) := 'X941';
    cv_reason_931             CONSTANT VARCHAR2(5) := 'X931';
    cv_reason_932             CONSTANT VARCHAR2(5) := 'X932';
-- 2008/11/19 v1.12 ADD START
    cv_reason_952             CONSTANT VARCHAR2(5) := 'X952';
    cv_reason_953             CONSTANT VARCHAR2(5) := 'X953';
    cv_reason_954             CONSTANT VARCHAR2(5) := 'X954';
    cv_reason_955             CONSTANT VARCHAR2(5) := 'X955';
    cv_reason_956             CONSTANT VARCHAR2(5) := 'X956';
    cv_reason_957             CONSTANT VARCHAR2(5) := 'X957';
    cv_reason_958             CONSTANT VARCHAR2(5) := 'X958';
    cv_reason_959             CONSTANT VARCHAR2(5) := 'X959';
    cv_reason_960             CONSTANT VARCHAR2(5) := 'X960';
    cv_reason_961             CONSTANT VARCHAR2(5) := 'X961';
    cv_reason_962             CONSTANT VARCHAR2(5) := 'X962';
    cv_reason_963             CONSTANT VARCHAR2(5) := 'X963';
    cv_reason_964             CONSTANT VARCHAR2(5) := 'X964';
    cv_reason_965             CONSTANT VARCHAR2(5) := 'X965';
    cv_reason_966             CONSTANT VARCHAR2(5) := 'X966';
-- 2008/11/19 v1.12 ADD END
--
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
-- 2008/10/27 v1.10 ADD START
    cv_ovlook_rcv           CONSTANT VARCHAR2(10) := 'X943' ; -- 黙視品目受入
    cv_sonota_rcv           CONSTANT VARCHAR2(10) := 'X950' ; -- その他受入
-- 2008/10/27 v1.10 ADD END
    cv_sonota_pay           CONSTANT VARCHAR2(10) := 'X951' ; -- その他払出
    cv_move_result          CONSTANT VARCHAR2(10) := 'X122' ; -- 移動実績
    cv_vendor_rma           CONSTANT VARCHAR2( 5) := 'X201' ; -- 仕入先返品
    cv_hamaoka_rcv          CONSTANT VARCHAR2( 5) := 'X988' ; -- 浜岡受入
    cv_party_inv            CONSTANT VARCHAR2( 5) := 'X977' ; -- 相手先在庫
    cv_move_correct         CONSTANT VARCHAR2( 5) := 'X123' ; -- 移動実績訂正
-- 2008/11/11 v1.11 ADD START
    cv_prod_use           CONSTANT VARCHAR2(10) := 'X952'; --製造使用
    cv_from_drink         CONSTANT VARCHAR2(10) := 'X953'; -- ドリンクより
    cv_to_drink           CONSTANT VARCHAR2(10) := 'X954'; -- ドリンクへ
    cv_set_arvl           CONSTANT VARCHAR2(10) := 'X955'; -- セット組入庫
    cv_set_ship           CONSTANT VARCHAR2(10) := 'X956'; -- セット組出庫
    cv_dis_arvl           CONSTANT VARCHAR2(10) := 'X957'; -- 解体入庫
    cv_dis_ship           CONSTANT VARCHAR2(10) := 'X958'; -- 解体出庫
    cv_oki_rcv            CONSTANT VARCHAR2(10) := 'X959'; -- 沖縄工場受入
    cv_oki_pay            CONSTANT VARCHAR2(10) := 'X960'; -- 沖縄工場払出
    cv_item_mov_arvl      CONSTANT VARCHAR2(10) := 'X961'; -- 品種移動入庫
    cv_item_mov_ship      CONSTANT VARCHAR2(10) := 'X962'; -- 品種移動出庫
    cv_to_leaf            CONSTANT VARCHAR2(10) := 'X963'; -- リーフへ
    cv_from_leaf          CONSTANT VARCHAR2(10) := 'X964'; -- リーフより
-- 2008/11/11 v1.11 ADD END
    cv_div_pay              CONSTANT VARCHAR2( 2) := '-1' ;
    cv_div_rcv              CONSTANT VARCHAR2( 2) := '1' ;
    lc_f_day                CONSTANT VARCHAR2(2)  := '01';
    lc_f_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    cv_div_kind_transfer    CONSTANT VARCHAR2(10) := '品種振替';   -- 取引区分：品種振替
    cv_div_item_transfer    CONSTANT VARCHAR2(10) := '品目振替';   -- 取引区分：品目振替
    cv_line_type_material   CONSTANT VARCHAR2( 2) := '1';     -- ラインタイプ：原料
    cv_line_type_product    CONSTANT VARCHAR2( 2) := '-1';    -- ラインタイプ：製品
-- 2008/10/24 v1.10 ADD START
    cv_start_date           CONSTANT VARCHAR2(20) := '1900/01/01';
    cv_end_date             CONSTANT VARCHAR2(20) := '9999/12/31';
-- 2008/10/24 v1.10 ADD END
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
    lt_work_rec        tab_data_type_dtl;
    li_cnt             INTEGER;
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/27 v1.10 ADD START
      --対象受払区分取得カーソル
      CURSOR get_div_type_cur IS
        SELECT ir_param.div_type1 div_type
        FROM   DUAL
        WHERE  ir_param.div_type1 IS NOT NULL
        UNION
        SELECT ir_param.div_type2 div_type
        FROM   DUAL
        WHERE  ir_param.div_type2 IS NOT NULL
        UNION
        SELECT ir_param.div_type3 div_type
        FROM   DUAL
        WHERE  ir_param.div_type3 IS NOT NULL
        UNION
        SELECT ir_param.div_type4 div_type
        FROM   DUAL
        WHERE  ir_param.div_type4 IS NOT NULL
        UNION
        SELECT ir_param.div_type5 div_type
        FROM   DUAL
        WHERE  ir_param.div_type5 IS NOT NULL
        ORDER BY div_type
      ;
--
    -------------------------------------------------
    -- 事由コード指定なし
    -------------------------------------------------
    --品目区分:製品
    --NDA:101(製品)
    --DD :102/112(OMSO/PORC)
    CURSOR get_data101p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
-- 2008/12/19 v1.20 UPDATE START 以下同様
--            ,xlc.unit_ploce             actual_unit_price
            ,ilm.attribute7             actual_unit_price
-- 2008/12/19 v1.20 UPDATE END
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
--      AND    xola.line_id            = wdd.source_line_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '112'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.16 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd rsl xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.16 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
--      AND    xola.line_id            = rsl.oe_order_line_id
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
--            ,trn.item_id                    item_id
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    xoha.header_id          = ooha.header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(製品)
    --DD :105/108(OMSO/PORC)
    CURSOR get_data102p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11v ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11v ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11v ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11v ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDTE STRAT
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDTE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:103(製品)
    --DD :103(OMSO/PORC)
    CURSOR get_data103p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst  xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:104(製品)
    --対象なし
--
    --NDA:105(製品)
    --DD :107(OMSO/PORC)
    CURSOR get_data105p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 ADD START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 ADD END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:106(製品)
    --DD :109(OMSO/PORC)
    CURSOR get_data106p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:107(製品)
    --DD :104(OMSO/PORC)
    CURSOR get_data107p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE STAET
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:108(製品)
    --対象なし
--
    --NDA:109/111(製品)
    --DD :110/111(OMSO/PORC)
    CURSOR get_data109111p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --品目区分:原料資材半製品
    --NDA:101/103(原料資材半製品)
    --DD :101/103(OMSO/PORC)
    CURSOR get_data1013m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xola.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(原料資材半製品)
    --対象なし
--
    --NDA:104(原料資材半製品)
    --DD :113(OMSO/PORC)
    CURSOR get_data104m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 UPDATE START
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:105(原料資材半製品)
    --対象なし
--
    --NDA:106(原料資材半製品)
    --対象なし
--
    --NDA:107(原料資材半製品)
    --対象なし
--
    --NDA:108(原料資材半製品)
    --DD :106(OMSO/PORC)
    CURSOR get_data108m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:109(原料資材半製品)
    --対象なし
--
    --NDA:111(原料資材半製品)
    --対象なし
--
    --品目区分:全般
    --NDA:201
    --DD :202(ADJI_PO/PORC_PO)
    CURSOR get_data201_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,trn.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_rcv_and_rtn_txns      xrrt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_vendor_rma
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
      SELECT /*+ leading (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) */
             pv.segment1                div_tocode
            ,xv.vendor_short_name       div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,pha.attribute10            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = pha.attribute10
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,rcv_transactions           rt
            ,po_headers_all             pha
            ,po_vendors                 pv
            ,xxcmn_vendors              xv
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    rsl.source_document_code = 'PO'
      AND    rt.transaction_id       = trn.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    pha.po_header_id        = rsl.po_header_id
      AND    pv.vendor_id            = pha.vendor_id
      AND    xv.vendor_id            = pv.vendor_id
      AND    xv.start_date_active   <= TRUNC(trn.trans_date)
      AND    xv.end_date_active     >= TRUNC(trn.trans_date)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:202/203
    --DD :201/203(OMSO/PORC)
    CURSOR get_data2023_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319/503
    --DD :3nn(PROD)/502(ADJI)
    CURSOR get_data3nn_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class      <> '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
-- 2008/12/22 v1.21 ADD START
      UNION ALL -- ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_reason_952
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
-- 2008/12/22 v1.21 ADD END
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:313/314/315/316
    --DD :3nn70(PROD_70)
    CURSOR get_data3nn70_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class       = '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:401/402
    --DD :401/402(ADJI_MV/TRNI/XFER)
    CURSOR get_data4nn_cur (iv_div_type IN VARCHAR2) IS --ADJI_MV
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/13 v1.18 T.Ohashi mod start
-- 2008/12/11 v1.17 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,ABS(trn.trans_qty) * TO_NUMBER(gc_rcv_pay_div_adj) trans_qty
--            ,NVL(trn.trans_qty,0)       trans_qty
            ,NVL(trn.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/12/11 v1.17 UPDATE END
-- 2008/12/13 v1.18 T.Ohashi mod end
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmrl
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_move_correct
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
-- 2008/11/11 v1.16 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
--                                         WHEN trn.trans_qty < 0 THEN cv_div_rcv
--                                         ELSE xrpm.rcv_pay_div
-- 2008/12/11 v1.17 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
                                         ELSE cv_div_rcv
-- 2008/12/11 v1.17 UPDATE END
-- 2008/11/11 v1.16 UPDATE END
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --XFER
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
      --SELECT /*+ leading (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) */
      SELECT /*+ leading (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,ic_xfer_mst                ixm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_xfer
      AND    xrpm.reason_code        = cv_move_result
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_id              = ixm.transfer_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --TRNI
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
      SELECT /*+ leading (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_trni
      AND    xrpm.reason_code        = cv_move_result
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_type            = iaj.trans_type
      AND    trn.doc_id              = iaj.doc_id
      AND    trn.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.doc_type           = trn.doc_type
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.rcv_pay_div        = trn.line_type
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:501/504/506/507/508
    --DD :5nn(ADJI)
    CURSOR get_data5nn_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/14 v1.18 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:502/503
    --DD :5nn(ADJI/ADJI_SNT)
    CURSOR get_data5023_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --ADJI_SNT
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_ovlook_pay
-- 2008/10/27 v1.10 ADD START
                                      ,cv_ovlook_rcv
                                      ,cv_sonota_rcv
-- 2008/10/27 v1.10 ADD END
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--                                      ,cv_sonota_pay)
                                      ,cv_sonota_pay)
--                                      ,cv_sonota_pay
--                                      ,cv_prod_use
--                                      ,cv_from_drink
--                                      ,cv_to_drink
--                                      ,cv_set_arvl
--                                      ,cv_set_ship
--                                      ,cv_dis_arvl
--                                      ,cv_dis_ship
--                                      ,cv_oki_rcv
--                                      ,cv_oki_pay
--                                      ,cv_item_mov_arvl
--                                      ,cv_item_mov_ship
--                                      ,cv_to_leaf
--                                      ,cv_from_leaf)
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:505/509
    --DD :504/509(ADJI/OMSO/PORC)
    CURSOR get_data5059_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --OMSO
      --SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/03 H.Itou Mod Start 本番障害#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = wdd.source_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --PORC
      --SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/03 H.Itou Mod Start 本番障害#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:511
    --DD :511(ADJI_HM)
    CURSOR get_data511_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_namaha_prod_txns      xnpt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2009/11/09 MOD START
--      AND    xnpt.entry_number       = ijm.attribute1
      AND    xnpt.txns_id            = ijm.attribute1
-- 2009/11/09 MOD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_hamaoka_rcv
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    -------------------------------------------------
    -- 事由コード指定あり
    -------------------------------------------------
    --品目区分:製品
    --NDA:101(製品)
    --DD :102/112(OMSO/PORC)
    CURSOR get_data101p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
--      AND    xola.line_id            = wdd.source_line_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.16 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd rsl xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.16 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
--      AND    xola.line_id            = rsl.oe_order_line_id
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
--            ,trn.item_id                    item_id
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    xoha.header_id          = ooha.header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(製品)
    --DD :105/108(OMSO/PORC)
    CURSOR get_data102p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11v ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11v ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11v ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11v ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDTE STRAT
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDTE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:103(製品)
    --DD :103(OMSO/PORC)
    CURSOR get_data103p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst  xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:104(製品)
    --対象なし
--
    --NDA:105(製品)
    --DD :107(OMSO/PORC)
    CURSOR get_data105p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 ADD START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 ADD END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:106(製品)
    --DD :109(OMSO/PORC)
    CURSOR get_data106p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:107(製品)
    --DD :104(OMSO/PORC)
    CURSOR get_data107p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE STAET
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:108(製品)
    --対象なし
--
    --NDA:109/111(製品)
    --DD :110/111(OMSO/PORC)
    CURSOR get_data109111p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --品目区分:原料資材半製品
    --NDA:101/103(原料資材半製品)
    --DD :101/103(OMSO/PORC)
    CURSOR get_data1013m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xola.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(原料資材半製品)
    --対象なし
--
    --NDA:104(原料資材半製品)
    --DD :113(OMSO/PORC)
    CURSOR get_data104m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 UPDATE START
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '113'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:105(原料資材半製品)
    --対象なし
--
    --NDA:106(原料資材半製品)
    --対象なし
--
    --NDA:107(原料資材半製品)
    --対象なし
--
    --NDA:108(原料資材半製品)
    --DD :106(OMSO/PORC)
    CURSOR get_data108m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:109(原料資材半製品)
    --対象なし
--
    --NDA:111(原料資材半製品)
    --対象なし
--
    --品目区分:全般
    --NDA:201
    --DD :202(ADJI_PO/PORC_PO)
    CURSOR get_data201_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,trn.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_rcv_and_rtn_txns      xrrt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_vendor_rma
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
      SELECT /*+ leading (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) */
             pv.segment1                div_tocode
            ,xv.vendor_short_name       div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,pha.attribute10            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = pha.attribute10
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,rcv_transactions           rt
            ,po_headers_all             pha
            ,po_vendors                 pv
            ,xxcmn_vendors              xv
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    rsl.source_document_code = 'PO'
      AND    rt.transaction_id       = trn.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    pha.po_header_id        = rsl.po_header_id
      AND    pv.vendor_id            = pha.vendor_id
      AND    xv.vendor_id            = pv.vendor_id
      AND    xv.start_date_active   <= TRUNC(trn.trans_date)
      AND    xv.end_date_active     >= TRUNC(trn.trans_date)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:202/203
    --DD :201/203(OMSO/PORC)
    CURSOR get_data2023_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319/503
    --DD :3nn(PROD)/502(ADJI)
    CURSOR get_data3nn_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class      <> '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
-- 2008/12/22 v1.21 ADD START
      UNION ALL -- ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_reason_952
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
-- 2008/12/22 v1.21 ADD END
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:313/314/315/316
    --DD :3nn70(PROD_70)
    CURSOR get_data3nn70_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class       = '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:401/402
    --DD :401/402(ADJI_MV/TRNI/XFER)
    CURSOR get_data4nn_r_cur (iv_div_type IN VARCHAR2) IS --ADJI_MV
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/13 v1.18 T.Ohashi mod start
-- 2008/12/11 v1.17 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,ABS(trn.trans_qty) * TO_NUMBER(gc_rcv_pay_div_adj) trans_qty
--            ,NVL(trn.trans_qty,0)       trans_qty
            ,NVL(trn.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/12/11 v1.17 UPDATE END
-- 2008/12/13 v1.18 T.Ohashi mod end
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmrl
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_move_correct
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
-- 2008/11/11 v1.16 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
--                                         WHEN trn.trans_qty < 0 THEN cv_div_rcv
--                                         ELSE xrpm.rcv_pay_div
-- 2008/12/11 v1.17 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
                                         ELSE cv_div_rcv
-- 2008/12/11 v1.17 UPDATE END
-- 2008/11/11 v1.16 UPDATE END
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --XFER
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) */
      SELECT /*+ leading (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,ic_xfer_mst                ixm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_xfer
      AND    xrpm.reason_code        = cv_move_result
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_id              = ixm.transfer_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --TRNI
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
      SELECT /*+ leading (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_trni
      AND    xrpm.reason_code        = cv_move_result
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_type            = iaj.trans_type
      AND    trn.doc_id              = iaj.doc_id
      AND    trn.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.doc_type           = trn.doc_type
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.rcv_pay_div        = trn.line_type
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:501/504/506/507/508
    --DD :5nn(ADJI)
    CURSOR get_data5nn_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/14 v1.18 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:502/503
    --DD :5nn(ADJI/ADJI_SNT)
    CURSOR get_data5023_r_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --ADJI_SNT
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_ovlook_pay
-- 2008/10/27 v1.10 ADD START
                                      ,cv_ovlook_rcv
                                      ,cv_sonota_rcv
-- 2008/10/27 v1.10 ADD END
-- 2008/10/27 v1.10 ADD START
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--                                      ,cv_sonota_pay)
                                      ,cv_sonota_pay)
--                                      ,cv_sonota_pay
--                                      ,cv_prod_use
--                                      ,cv_from_drink
--                                      ,cv_to_drink
--                                      ,cv_set_arvl
--                                      ,cv_set_ship
--                                      ,cv_dis_arvl
--                                      ,cv_dis_ship
--                                      ,cv_oki_rcv
--                                      ,cv_oki_pay
--                                      ,cv_item_mov_arvl
--                                      ,cv_item_mov_ship
--                                      ,cv_to_leaf
--                                      ,cv_from_leaf)
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:505/509
    --DD :504/509(ADJI/OMSO/PORC)
    CURSOR get_data5059_r_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
-- 2008/12/22 v1.21 DELETE START
--                                      ,cv_reason_952
-- 2008/12/22 v1.21 DELETE END
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --OMSO
      --SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/03 H.Itou Mod Start 本番障害#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = wdd.source_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --PORC
      --SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
-- 2008/12/03 H.Itou Mod Start 本番障害#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:511
    --DD :511(ADJI_HM)
    CURSOR get_data511_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,ilm.attribute7             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_namaha_prod_txns      xnpt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xnpt.entry_number       = ijm.attribute1
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_hamaoka_rcv
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    iwm.attribute1          = '0'
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
-- 2008/10/27 v1.10 ADD END
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
-- 2008/10/27 v1.10 ADD START
--
    -- 事由コード指定なしの場合
    IF ( ir_param.reason_code IS NULL ) THEN
--
      <<div_type_loop>>
      FOR get_div_type_rec IN get_div_type_cur LOOP
--
        --製品の場合
        IF ( ir_param.item_class = '5' ) THEN
          --受払区分:101
          IF (get_div_type_rec.div_type = '101') THEN
            OPEN  get_data101p_cur(get_div_type_rec.div_type);
            FETCH get_data101p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data101p_cur;
          --受払区分:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            OPEN  get_data102p_cur(get_div_type_rec.div_type);
            FETCH get_data102p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data102p_cur;
          --受払区分:103
          ELSIF (get_div_type_rec.div_type = '103') THEN
            OPEN  get_data103p_cur(get_div_type_rec.div_type);
            FETCH get_data103p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data103p_cur;
          --受払区分:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            NULL; --対象外
          --受払区分:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            OPEN  get_data105p_cur(get_div_type_rec.div_type);
            FETCH get_data105p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data105p_cur;
          --受払区分:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            OPEN  get_data106p_cur(get_div_type_rec.div_type);
            FETCH get_data106p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data106p_cur;
          --受払区分:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            OPEN  get_data107p_cur(get_div_type_rec.div_type);
            FETCH get_data107p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data107p_cur;
          --受払区分:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            NULL; --対象外
          --受払区分:109/111
          ELSIF (get_div_type_rec.div_type IN ('109','111')) THEN
            OPEN  get_data109111p_cur(get_div_type_rec.div_type);
            FETCH get_data109111p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data109111p_cur;
          END IF;
        --原料資材半製品の場合
        ELSE
          --受払区分:101/103
          IF (get_div_type_rec.div_type IN ('101','103')) THEN
            OPEN  get_data1013m_cur(get_div_type_rec.div_type);
            FETCH get_data1013m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data1013m_cur;
          --受払区分:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            NULL; --対象外
          --受払区分:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            OPEN  get_data104m_cur(get_div_type_rec.div_type);
            FETCH get_data104m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data104m_cur;
          --受払区分:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            NULL; --対象外
          --受払区分:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            NULL; --対象外
          --受払区分:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            NULL; --対象外
          --受払区分:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            OPEN  get_data108m_cur(get_div_type_rec.div_type);
            FETCH get_data108m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data108m_cur;
          --受払区分:109
          ELSIF (get_div_type_rec.div_type = '109') THEN
            NULL; --対象外
          --受払区分:111
          ELSIF (get_div_type_rec.div_type = '111') THEN
            NULL; --対象外
          END IF;
        END IF;
--
        --共通
        --受払区分:201
        IF (get_div_type_rec.div_type = '201') THEN
          OPEN  get_data201_cur(get_div_type_rec.div_type);
          FETCH get_data201_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data201_cur;
        --受払区分:202/203
        ELSIF (get_div_type_rec.div_type IN ('202','203')) THEN
          OPEN  get_data2023_cur(get_div_type_rec.div_type);
          FETCH get_data2023_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data2023_cur;
        --受払区分:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
        ELSIF (get_div_type_rec.div_type IN ('301','302','303'
                                            ,'304','305','306'
                                            ,'307','308','309'
                                            ,'310','311','312'
                                            ,'317','318','319')) THEN
          OPEN  get_data3nn_cur(get_div_type_rec.div_type);
          FETCH get_data3nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn_cur;
        --受払区分:313/314/315/316
        ELSIF (get_div_type_rec.div_type IN ('313','314','315','316')) THEN
          OPEN  get_data3nn70_cur(get_div_type_rec.div_type);
          FETCH get_data3nn70_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn70_cur;
        --受払区分:401/402
        ELSIF (get_div_type_rec.div_type IN ('401','402')) THEN
          OPEN  get_data4nn_cur(get_div_type_rec.div_type);
          FETCH get_data4nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data4nn_cur;
        --受払区分:501/504/506/507/508
-- 2008/12/04 v1.15 UPDATE START
--        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508')) THEN
        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508','509')) THEN
-- 2008/12/04 v1.15 UPDATE END
          OPEN  get_data5nn_cur(get_div_type_rec.div_type);
          FETCH get_data5nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5nn_cur;
        --受払区分:502/503
        ELSIF (get_div_type_rec.div_type IN ('502','503')) THEN
          OPEN  get_data5023_cur(get_div_type_rec.div_type);
          FETCH get_data5023_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5023_cur;
        --受払区分:505/510
-- 2008/11/29 v1.13 yoshida UPDATE start
        --ELSIF (get_div_type_rec.div_type IN ('505','509')) THEN
        ELSIF (get_div_type_rec.div_type IN ('505','510')) THEN
-- 2008/11/29 v1.13 yoshida UPDATE end
          OPEN  get_data5059_cur(get_div_type_rec.div_type);
          FETCH get_data5059_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5059_cur;
        --受払区分:511
        ELSIF (get_div_type_rec.div_type = '511') THEN
          OPEN  get_data511_cur(get_div_type_rec.div_type);
          FETCH get_data511_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data511_cur;
        END IF;
--
        li_cnt := ot_data_rec.COUNT;
--
        IF  (li_cnt = 0)
        AND (lt_work_rec.COUNT > 0) THEN
          ot_data_rec := lt_work_rec;
        ELSIF (li_cnt > 0)
        AND   (lt_work_rec.COUNT > 0) THEN
          <<set_data_loop>>
          FOR i IN 1..lt_work_rec.COUNT LOOP
            ot_data_rec(li_cnt + i) := lt_work_rec(i);
          END LOOP set_data_loop;
        END IF;
--
        lt_work_rec.DELETE;
--
      END LOOP div_type_loop;
--
    -- 事由コード指定ありの場合
    ELSE
--
      <<div_type_r_loop>>
      FOR get_div_type_rec IN get_div_type_cur LOOP
--
        --製品の場合
        IF ( ir_param.item_class = '5' ) THEN
          --受払区分:101
          IF (get_div_type_rec.div_type = '101') THEN
            OPEN  get_data101p_r_cur(get_div_type_rec.div_type);
            FETCH get_data101p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data101p_r_cur;
          --受払区分:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            OPEN  get_data102p_r_cur(get_div_type_rec.div_type);
            FETCH get_data102p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data102p_r_cur;
          --受払区分:103
          ELSIF (get_div_type_rec.div_type = '103') THEN
            OPEN  get_data103p_r_cur(get_div_type_rec.div_type);
            FETCH get_data103p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data103p_r_cur;
          --受払区分:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            NULL; --対象外
          --受払区分:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            OPEN  get_data105p_r_cur(get_div_type_rec.div_type);
            FETCH get_data105p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data105p_r_cur;
          --受払区分:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            OPEN  get_data106p_r_cur(get_div_type_rec.div_type);
            FETCH get_data106p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data106p_r_cur;
          --受払区分:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            OPEN  get_data107p_r_cur(get_div_type_rec.div_type);
            FETCH get_data107p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data107p_r_cur;
          --受払区分:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            NULL; --対象外
          --受払区分:109/111
          ELSIF (get_div_type_rec.div_type IN ('109','111')) THEN
            OPEN  get_data109111p_r_cur(get_div_type_rec.div_type);
            FETCH get_data109111p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data109111p_r_cur;
          END IF;
        --原料資材半製品の場合
        ELSE
          --受払区分:101/103
          IF (get_div_type_rec.div_type IN ('101','103')) THEN
            OPEN  get_data1013m_r_cur(get_div_type_rec.div_type);
            FETCH get_data1013m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data1013m_r_cur;
          --受払区分:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            NULL; --対象外
          --受払区分:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            OPEN  get_data104m_r_cur(get_div_type_rec.div_type);
            FETCH get_data104m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data104m_r_cur;
          --受払区分:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            NULL; --対象外
          --受払区分:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            NULL; --対象外
          --受払区分:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            NULL; --対象外
          --受払区分:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            OPEN  get_data108m_r_cur(get_div_type_rec.div_type);
            FETCH get_data108m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data108m_r_cur;
          --受払区分:109
          ELSIF (get_div_type_rec.div_type = '109') THEN
            NULL; --対象外
          --受払区分:111
          ELSIF (get_div_type_rec.div_type = '111') THEN
            NULL; --対象外
          END IF;
        END IF;
--
        --共通
        --受払区分:201
        IF (get_div_type_rec.div_type = '201') THEN
          OPEN  get_data201_r_cur(get_div_type_rec.div_type);
          FETCH get_data201_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data201_r_cur;
        --受払区分:202/203
        ELSIF (get_div_type_rec.div_type IN ('202','203')) THEN
          OPEN  get_data2023_r_cur(get_div_type_rec.div_type);
          FETCH get_data2023_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data2023_r_cur;
        --受払区分:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
        ELSIF (get_div_type_rec.div_type IN ('301','302','303'
                                            ,'304','305','306'
                                            ,'307','308','309'
                                            ,'310','311','312'
                                            ,'317','318','319')) THEN
          OPEN  get_data3nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data3nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn_r_cur;
        --受払区分:313/314/315/316
        ELSIF (get_div_type_rec.div_type IN ('313','314','315','316')) THEN
          OPEN  get_data3nn70_r_cur(get_div_type_rec.div_type);
          FETCH get_data3nn70_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn70_r_cur;
        --受払区分:401/402
        ELSIF (get_div_type_rec.div_type IN ('401','402')) THEN
          OPEN  get_data4nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data4nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data4nn_r_cur;
        --受払区分:501/504/506/507/508/509
-- 2008/12/04 v1.15 UPDATE START
--        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508')) THEN
        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508','509')) THEN
-- 2008/12/04 v1.15 UPDATE END
          OPEN  get_data5nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data5nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5nn_r_cur;
        --受払区分:502/503
        ELSIF (get_div_type_rec.div_type IN ('502','503')) THEN
          OPEN  get_data5023_r_cur(get_div_type_rec.div_type);
          FETCH get_data5023_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5023_r_cur;
        --受払区分:505/510
-- 2008/11/29 v1.13 yoshida UPDATE start
        --ELSIF (get_div_type_rec.div_type IN ('505','509')) THEN
        ELSIF (get_div_type_rec.div_type IN ('505','510')) THEN
-- 2008/11/29 v1.13 yoshida UPDATE end
          OPEN  get_data5059_r_cur(get_div_type_rec.div_type);
          FETCH get_data5059_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5059_r_cur;
        --受払区分:511
        ELSIF (get_div_type_rec.div_type = '511') THEN
          OPEN  get_data511_r_cur(get_div_type_rec.div_type);
          FETCH get_data511_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data511_r_cur;
        END IF;
--
        li_cnt := ot_data_rec.COUNT;
--
        IF  (li_cnt = 0)
        AND (lt_work_rec.COUNT > 0) THEN
          ot_data_rec := lt_work_rec;
        ELSIF (li_cnt > 0)
        AND   (lt_work_rec.COUNT > 0) THEN
          <<set_data_loop>>
          FOR i IN 1..lt_work_rec.COUNT LOOP
            ot_data_rec(li_cnt + i) := lt_work_rec(i);
          END LOOP set_data_loop;
        END IF;
--
        lt_work_rec.DELETE;
--
      END LOOP div_type_r_loop;
--
    END IF;
--
-- 2008/10/27 v1.10 ADD END
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
-- 2009/05/29 MOD START
      SELECT stnd_unit_price as price
      INTO   on_unit_price
      FROM   xxcmn_stnd_unit_price_v xsup
      WHERE  xsup.item_id    = iv_item_id
        AND xsup.start_date_active  <= gd_st_unit_date
        AND xsup.end_date_active    >= gd_st_unit_date;
--
--      SELECT stnd_unit_price as price
--      INTO   on_unit_price
--      FROM   xxcmn_stnd_unit_price_v xsup
--      WHERE  xsup.item_id    = iv_item_id
--        AND (xsup.start_date_active IS NULL OR
--             xsup.start_date_active  <= TRUNC(id_trans_date))
--        AND (xsup.end_date_active   IS NULL OR
--             xsup.end_date_active    >= TRUNC(id_trans_date));
-- 2009/05/29 MOD END
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
-- 2011/03/10 v1.25 Deleted START
--        -- 金額算出（原価管理区分が「標準原価」の場合）
--        IF (lv_cost_kbn = gc_cost_st ) THEN
--          ln_amount := ln_stand_unit_price * ln_quantity;
--        END IF;
-- 2011/03/10 v1.25 Deleted END
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
-- 2011/03/10 v1.25 Deleted START
--          -- 金額算出（原価管理区分が「標準原価」の場合）
--          IF (lv_cost_kbn = gc_cost_st ) THEN
---- 2008/11/11 v1.11 UPDATE START
----            ln_amount := ln_stand_unit_price * ln_quantity;
--            ln_amount := ROUND(ln_stand_unit_price * ln_quantity);
---- 2008/11/11 v1.11 UPDATE END
--          END IF;
-- 2011/03/10 v1.25 Deleted END
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
-- 2008/11/11 v1.11 UPDATE START
--                  + (NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
               + ROUND(NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
-- 2008/11/11 v1.11 UPDATE END
        -- ロット管理区分が「ロット管理無し」の場合
        ELSE
          ln_amount := ln_amount
-- 2008/11/11 v1.11 UPDATE START
--                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
                   + ROUND(NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
-- 2008/11/11 v1.11 UPDATE END
        END IF;
-- 2011/03/10 v1.25 Added START
      ELSE
        --  原価管理区分が「標準原価」の場合
        ln_amount :=  ln_amount
                        +   ROUND(NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
-- 2011/03/10 v1.25 Added END
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
-- 2011/03/10 v1.25 Deleted START
--        -- 金額算出（原価管理区分が「標準原価」の場合）
--        IF (lv_cost_kbn = gc_cost_st ) THEN
---- 2008/11/11 v1.11 UPDATE START
----          ln_amount := ln_stand_unit_price * ln_quantity;
--          ln_amount := ROUND(ln_stand_unit_price * ln_quantity);
---- 2008/11/11 v1.11 UPDATE END
--        END IF;
-- 2011/03/10 v1.25 Deleted END
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
    -- 2009/05/29 ADD START
    gd_st_unit_date := FND_DATE.STRING_TO_DATE(iv_exec_year_month , gc_char_m_format);
    -- 2009/05/29 ADD END
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