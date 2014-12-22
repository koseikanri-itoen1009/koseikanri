create or replace PACKAGE BODY xxcmn770025c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770025C(body)
 * Description      : 仕入実績表作成
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77E)
 * Version          : 1.19
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                     コンカレント実行ファイル登録プロシージャ
 *  fnc_conv_xml             ＸＭＬタグに変換する
 *  prc_create_xml_data_zero ＸＭＬデータ作成(0件)
 *  prc_create_xml_data_sum  ＸＭＬデータ作成(合計)
 *  prc_out_xml              ＸＭＬ出力処理
 *  prc_initialize           前処理
 *  prc_get_report_data      明細データ取得(E-1)
 *  prc_create_xml_data_line ＸＭＬデータ作成(明細)
 *  prc_create_xml_data      ＸＭＬデータ作成
 *  prc_set_param            パラメータの取得
 *  submain                  メイン処理プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   T.Endou          新規作成
 *  2008/05/16    1.1   T.Ikehara        不具合ID:77E-17対応  処理年月パラYYYYM入力対応
 *  2008/05/30    1.2   T.Endou          実際単価取得方法の変更
 *  2008/06/24    1.3   I.Higa           データが無い項目でも０を出力する
 *  2008/06/25    1.4   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/22    1.5   T.Endou          改ページ時、ヘッダが出ないパターン対応
 *  2008/10/14    1.6   A.Shiina         T_S_524対応
 *  2008/10/28    1.7   H.Itou           T_S_524対応(再対応)
 *  2008/11/13    1.8   A.Shiina         移行データ検証不具合対応
 *  2008/11/19    1.9   N.Yoshida        移行データ検証不具合対応
 *  2008/11/28    1.10  N.Yoshida        本番#182対応
 *  2008/12/04    1.11  N.Yoshida        本番#389対応
 *  2008/12/05    1.12  A.Shiina         本番#500対応
 *  2008/12/05    1.13  A.Shiina         本番#473対応
 *  2008/12/12    1.14  A.Shiina         本番#425対応
 *  2009/01/09    1.15  N.Yoshida        本番#986対応
 *  2009/07/09    1.16  Marushita        本番#1574対応
 *  2012/03/23    1.17  Y.Horikawa       E_本稼動_09257対応（E_本稼動_08924対応）
 *  2013/06/27    1.18  S.Niki           E_本稼動_10839対応（消費税増税対応）
 *  2014/10/14    1.19  H.Itou           E_本稼動_12321対応
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770025C'; -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '仕入実績表';   -- 帳票名
  gd_exec_date              CONSTANT DATE         := SYSDATE;        -- 実施日
--
  gv_xxcmn_ctr              CONSTANT VARCHAR2(26) := 'XXCMN_CONSUMPTION_TAX_RATE'; -- 消費税
  gv_cat_set_name_prod_div  CONSTANT VARCHAR2(8)  := '商品区分';
  gv_cat_set_name_item_div  CONSTANT VARCHAR2(8)  := '品目区分';
-- 2008/10/28 H.Itou Add Start T_S_524対応(再対応)
  gv_min_date               CONSTANT VARCHAR2(20) := '1900/01/01 00:00:00';
  gv_max_date               CONSTANT VARCHAR2(20) := '9999/12/31 23:59:59';
-- 2008/10/28 H.Itou Add End
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ; -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;  -- アプリケーション（XXPO）
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_yyyymm_format   CONSTANT VARCHAR2(30) := 'YYYYMM' ;
-- v1.18 ADD START
  gc_char_std_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
-- v1.18 ADD END
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_yyyy_format     CONSTANT VARCHAR2(30) := 'YYYY' ;
  gc_char_mm_format       CONSTANT VARCHAR2(30) := 'MM' ;
--
  gn_zero                 CONSTANT NUMBER := 0;
  gn_one                  CONSTANT NUMBER := 1;
  gn_2                    CONSTANT NUMBER := 2;
  gn_3                    CONSTANT NUMBER := 3;
  gn_4                    CONSTANT NUMBER := 4;
  gn_10                   CONSTANT NUMBER := 10;
  gn_11                   CONSTANT NUMBER := 11;
  gn_14                   CONSTANT NUMBER := 14;
  gn_15                   CONSTANT NUMBER := 15;
  gn_16                   CONSTANT NUMBER := 16;
  gn_20                   CONSTANT NUMBER := 20;
  gn_21                   CONSTANT NUMBER := 21;
  gn_30                   CONSTANT NUMBER := 30;
  gn_100                  CONSTANT NUMBER := 100;
  gv_y                    CONSTANT VARCHAR2(1) := 'Y';
  gv_n                    CONSTANT VARCHAR2(1) := 'N';
  gv_ja                   CONSTANT VARCHAR2(2) := 'JA';
  gv_ja_year              CONSTANT VARCHAR2(2) := '年';
  gv_ja_month             CONSTANT VARCHAR2(2) := '月';
--
  gn_lot_yes              CONSTANT NUMBER := 1; -- ロット管理する
  -- 原価区分
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0'; --実際原価
  gc_cost_st              CONSTANT VARCHAR2(1) := '1'; --標準原価
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
    proc_from       VARCHAR2(6)    -- 01 : 処理年月(FROM)
   ,proc_to         VARCHAR2(6)    -- 02 : 処理年月(TO)
   ,prod_div        VARCHAR2(1)    -- 03 : 商品区分
   ,item_div        VARCHAR2(1)    -- 04 : 品目区分
   ,result_post     VARCHAR2(4)    -- 05 : 成績部署
   ,party_code      VARCHAR2(15)   -- 06 : 仕入先
   ,crowd_type      VARCHAR2(1)    -- 07 : 群種別
   ,crowd_code      VARCHAR2(4)    -- 08 : 群コード
   ,acnt_crowd_code VARCHAR2(4)    -- 09 : 経理群コード
   ) ;
--
  -- 代行請求書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
    result_post      xxcmn_rcv_pay_mst_porc_po_v.result_post%TYPE   -- 成績部署
   ,location_name    xxcmn_locations2_v.location_name%TYPE          -- 事業所名
   ,item_div         xxcmn_lot_each_item_v.item_div%TYPE            -- 品目区分
   ,item_div_name    xxcmn_categories_v.description%TYPE            -- 品目区分名
   ,vendor_code      xxcmn_vendors2_v.segment1%TYPE                 -- 仕入先コード
   ,vendor_name      xxcmn_vendors2_v.vendor_name%TYPE              -- 仕入先名
   ,crowd_code       xxcmn_lot_each_item_v.crowd_code%TYPE          -- 群ｺｰﾄﾞ or 経理群ｺｰﾄﾞ
   ,item_code        xxcmn_lot_each_item_v.item_code%TYPE           -- 品目コード
   ,item_name        xxcmn_lot_each_item_v.item_name%TYPE           -- 品目名称
   ,item_um          xxcmn_lot_each_item_v.item_um%TYPE             -- 単位
   ,item_atr15       xxcmn_lot_each_item_v.item_attribute15%TYPE    -- 原価管理区分
   ,lot_ctl          xxcmn_lot_each_item_v.lot_ctl%TYPE             -- ロット管理区分
   ,trans_qty        NUMBER                                         -- 数量
   ,purchases_price  NUMBER                                         -- 仕入単価(ロット)
   ,powder_price     xxcmn_rcv_pay_mst_porc_po_v.powder_price%TYPE     -- 粉引後単価
   ,commission_price xxcmn_rcv_pay_mst_porc_po_v.commission_price%TYPE -- 口銭単価
   ,c_amt            NUMBER                                         -- 口銭金額 口銭単価 * 数量
   ,assessment       xxcmn_rcv_pay_mst_porc_po_v.assessment%TYPE       -- 賦課金
   ,stnd_unit_price  xxcmn_stnd_unit_price_v.stnd_unit_price%TYPE   -- 標準原価
   ,j_amt            NUMBER                                         -- 実際単価 * 数量
   ,s_amt            NUMBER                                         -- 仕入単価(ロット) * 数量
-- 2008/12/05 v1.13 ADD START
   ,commission_tax   NUMBER                                         -- 消費税等(口銭)
   ,payment_tax      NUMBER                                         -- 消費税等(支払)
-- 2008/12/05 v1.13 ADD END
-- v1.18 DEL START
--   ,c_tax            NUMBER                                         -- 消費税
-- v1.18 DEL END
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- 担当者
  gn_para_vendor_id         NUMBER; -- 入力パラ仕入先ID
--
  gv_report_id        VARCHAR2(12);                           -- 帳票ID
  gv_prod_div_name    xxcmn_categories_v.description%TYPE;    -- 商品区分
  gv_item_div_name    xxcmn_categories_v.description%TYPE;    -- 品目区分
  gv_result_post_name xxcmn_locations_v.location_name%TYPE;   -- 成績部署
  gv_party_code_name  xxcmn_vendors_v.vendor_name%TYPE;       -- 仕入先
  gv_crowd_type       xxcmn_lookup_values_v.description%TYPE; -- 群種別
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_user_expt       EXCEPTION;        -- ユーザーにて定義をした例外
--
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
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
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
   * Procedure Name   : prc_create_xml_data_zero
   * Description      : ＸＭＬデータ作成(0件)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_zero(
      ov_errbuf                    OUT VARCHAR2       -- ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,ov_retcode                   OUT VARCHAR2       -- ﾘﾀｰﾝ･ｺｰﾄﾞ
     ,ov_errmsg                    OUT VARCHAR2       -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,ir_param                     IN  rec_param_data -- パラメータ
     ,iot_xml_idx                  IN OUT NUMBER      -- ＸＭＬﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
     ,iot_xml_data_table           IN OUT XML_DATA    -- XMLﾃﾞｰﾀ
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_zero' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_errmsg_no_data  VARCHAR2(5000);   -- データなしメッセージ
--
  BEGIN
--
    -- =====================================================
    -- ０件メッセージ出力
    -- =====================================================
    lv_errmsg_no_data := xxcmn_common_pkg.get_msg( gc_application_po
                                                 ,'APP-XXPO-00009' ) ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- 成績部署G開始タグ
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'g_result_post' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- 品目区分LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 品目区分G開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.party_code IS NULL ) THEN
      -- 仕入先LG開始タグ出力
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
      -- 仕入先G開始タグ出力
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'g_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- 大群LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 大群G開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 中群LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd_m' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 中群G開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd_s' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 小群LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 小群G開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 0件メッセージ
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'msg' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := lv_errmsg_no_data;
    -- 小群G終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 小群LG終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 中群G終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd_s' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 中群LG終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd_m' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 大群G終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 大群LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_crowd_l' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.party_code IS NULL ) THEN
      -- 仕入先G終了タグ出力
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/g_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
      -- 仕入先LG終了タグ出力
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_vendor' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
    -- 品目区分G終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 品目区分LG終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_article_div' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- 成績部署G終了タグ
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := '/g_result_post' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    END IF;
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
  END prc_create_xml_data_zero ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_sum
   * Description      : ＸＭＬデータ作成(合計)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_sum(
      ov_errbuf                    OUT VARCHAR2       -- ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,ov_retcode                   OUT VARCHAR2       -- ﾘﾀｰﾝ･ｺｰﾄﾞ
     ,ov_errmsg                    OUT VARCHAR2       -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,iot_xml_idx                  IN OUT NUMBER      -- ＸＭＬﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
     ,iot_xml_data_table           IN OUT XML_DATA    -- XMLﾃﾞｰﾀ
     ,in_sum_quantity              IN  NUMBER         -- 数量計
     ,in_sum_order_amount          IN  NUMBER         -- 仕入金額計
     ,in_sum_commission_price      IN  NUMBER         -- 口銭計
     ,in_sum_commission_tax_amount IN  NUMBER         -- 消費税計(口銭)
     ,in_sum_commission_amount     IN  NUMBER         -- 口銭金額
     ,in_sum_assess_amount         IN  NUMBER         -- 賦課金計
     ,in_sum_payment               IN  NUMBER         -- 支払計
     ,in_sum_payment_amount_tax    IN  NUMBER         -- 消費税計(支払)
     ,in_sum_payment_amount        IN  NUMBER         -- 支払金額計
     ,in_sum_standard_amount       IN  NUMBER         -- 標準金額計
     ,in_sum_difference_amount     IN  NUMBER         -- 差異計
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_sum' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
--
  BEGIN
--
    -- =====================================================
    -- 総合計出力
    -- =====================================================
    -- 総合計LG開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 総合計G開始タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 総合計出力フラグ
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_flag' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := gv_y;
    -- 数量計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_quantity' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_quantity ;
    -- 仕入金額計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_order_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_order_amount;
    -- 口銭計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_price' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_price;
    -- 消費税計(口銭)
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_tax_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_tax_amount;
    -- 口銭金額
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_commission_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_commission_amount;
    -- 賦課金計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_assess_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_assess_amount;
    -- 支払計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment;
    -- 消費税計(支払)
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment_amount_tax' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment_amount_tax;
    -- 支払金額計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_payment_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_payment_amount;
    -- 標準原価計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_standard_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_standard_amount;
    -- 差異計
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'sum_difference_amount' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_sum_difference_amount;
    -- 総合計G終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 総合計LG終了タグ出力
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_sum' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data_sum ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_out_xml
   * Description      : XML出力処理
   ***********************************************************************************/
  PROCEDURE prc_out_xml(
      ov_errbuf         OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param          IN  rec_param_data -- 入力パラメータ群
     ,it_xml_data_table IN  XML_DATA       -- 取得レコード群
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml' ; -- プログラム名
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
    lv_xml_string        VARCHAR2(32000);
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- ＸＭＬヘッダー出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- ＸＭＬデータ部出力
    <<xml_data_table>>
    FOR i IN 1 .. it_xml_data_table.COUNT LOOP
      -- 編集したデータをタグに変換
      lv_xml_string := fnc_conv_xml(
                          iv_name   => it_xml_data_table(i).tag_name    -- タグネーム
                         ,iv_value  => it_xml_data_table(i).tag_value   -- タグデータ
                         ,ic_type   => it_xml_data_table(i).tag_type    -- タグタイプ
                        ) ;
      -- ＸＭＬタグ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
    END LOOP xml_data_table ;
--
    -- ＸＭＬフッダー出力
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ov_errbuf     OUT    VARCHAR2         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param      IN     rec_param_data   -- 入力パラメータ群
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
    cv_x_mov      CONSTANT VARCHAR2(20) := 'XXCMN_MC_OUPUT_DIV';
    cv_t          CONSTANT VARCHAR2(1) := 'T';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・例外処理 ***
    get_value_expt    EXCEPTION ;     -- 値取得エラー
    lv_tax            fnd_lookup_values.lookup_code%TYPE; -- 消費税
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 帳票ID設定
    -- ====================================================
    IF ( (ir_param.result_post IS NULL)
      AND (ir_param.party_code IS NULL) ) THEN
      -- 成績部署・仕入先ともにブランク指定 XXCMN770054
      gv_report_id := xxcmn770015c.program_id_04 || cv_t;
    ELSIF ( ir_param.result_post IS NULL ) THEN
      -- 成績部署のみブランク指定 XXCMN770052
      gv_report_id := xxcmn770015c.program_id_02 || cv_t;
    ELSIF ( ir_param.party_code IS NULL ) THEN
      -- 仕入先のみブランク指定 XXCMN770053
      gv_report_id := xxcmn770015c.program_id_03 || cv_t;
    ELSE
      -- 成績部署・仕入先ともにブランク指定外 XXCMN770051
      gv_report_id := xxcmn770015c.program_id_01 || cv_t;
    END IF;
--
    -- ====================================================
    -- 各パラメータ名称取得
    -- ====================================================
    -- 商品区分
    BEGIN
      SELECT xcv.description
      INTO   gv_prod_div_name
      FROM   xxcmn_categories_v xcv
      WHERE  xcv.category_set_name = gv_cat_set_name_prod_div
        AND  xcv.segment1          = ir_param.prod_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 品目区分
    BEGIN
      SELECT xcv.description
      INTO   gv_item_div_name
      FROM   xxcmn_categories_v xcv
      WHERE  xcv.category_set_name = gv_cat_set_name_item_div
        AND  xcv.segment1          = ir_param.item_div;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 群種別
    BEGIN
      SELECT xlvv.description
      INTO   gv_crowd_type
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  lookup_type      = cv_x_mov
        AND  xlvv.lookup_code = ir_param.crowd_type;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 成績部署
    BEGIN
      SELECT xlv.location_name
      INTO   gv_result_post_name
      FROM   xxcmn_locations_v xlv
      WHERE  xlv.location_code = ir_param.result_post;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- 仕入先
    BEGIN
      SELECT xvv.vendor_name
            ,xvv.vendor_id
      INTO   gv_party_code_name
            ,gn_para_vendor_id
      FROM   xxcmn_vendors_v xvv
      WHERE  xvv.segment1      = ir_param.party_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
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
   * Description      : 明細データ取得(E-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ov_errbuf     OUT VARCHAR2                  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  -- リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param      IN  rec_param_data            -- 入力パラメータ群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 取得レコード群
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
    cv_crowd_type        CONSTANT VARCHAR2( 1) := '3'; -- 群別
    cv_crowd_type_acnt   CONSTANT VARCHAR2( 1) := '4'; -- 経理群別
    cv_deliver           CONSTANT VARCHAR2( 7) := 'DELIVER';          -- 受入
    cv_return_to_vendor  CONSTANT VARCHAR2(16) := 'RETURN TO VENDOR'; -- 返品
    cv_po                CONSTANT VARCHAR2( 2) := 'PO';
    cv_porc              CONSTANT VARCHAR2( 4) := 'PORC';
    cv_adji              CONSTANT VARCHAR2( 4) := 'ADJI';
    cv_x201              CONSTANT VARCHAR2( 4) := 'X201'; -- 仕入先返品
-- 2008/11/13 v1.8 ADD START
    cv_rma               CONSTANT VARCHAR2( 3) := 'RMA';
-- 2008/11/13 v1.8 ADD END
    cv_cat_set_name_mtof CONSTANT VARCHAR2(30) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
-- v1.18 ADD START
    cv_sts_num_3         CONSTANT VARCHAR2( 1) := '3'; -- 実績区分：発注なし仕入先返品
-- v1.18 ADD END
--
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
--
-- 2008/10/14 v1.6 ADD START
    cv_zero              CONSTANT VARCHAR2( 1) := '0';
-- 2008/10/14 v1.6 ADD END
    -- *** ローカル・変数 ***
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_in         VARCHAR2(1000) ;
-- v1.18 DEL START
--    lt_lkup_code  fnd_lookup_values.lookup_code%TYPE;
-- v1.18 DEL END
--
-- 2008/10/14 v1.6 ADD START
    lv_select     VARCHAR2(32000) ;
    lv_porc_po    VARCHAR2(32000) ;
    lv_adji       VARCHAR2(32000) ;
    lv_group      VARCHAR2(32000) ;
    lv_order      VARCHAR2(32000) ;
--
-- 2008/10/14 v1.6 ADD END
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/14 v1.6 DELETE START
/*
--yutsuzuk add
    CURSOR get_cur01 IS
      SELECT mst.result_post           AS result_post
            ,mst.location_name         AS location_name
            ,mst.item_div              AS item_div
            ,mst.item_div_name         AS item_div_name
            ,mst.segment1              AS vendor_code
            ,mst.vendor_name           AS vendor_name
            ,mst.crowd_code            AS crowd_code
            ,mst.item_code             AS item_code
            ,mst.item_s_name           AS item_s_name
            ,mst.item_um               AS item_um
            ,mst.item_atr15            AS item_atr15
            ,mst.lot_ctl               AS lot_ctl
            ,SUM(mst.trans_qty)        AS trans_qty
            ,AVG(mst.purchases_price)  AS purchases_price
            ,AVG(mst.powder_price)     AS powder_price
            ,AVG(mst.commission_price) AS commission_price
            ,SUM(mst.commission_price * mst.trans_qty) AS c_amt
            ,SUM(mst.assessment)       AS assessment
            ,AVG(mst.stnd_unit_price)  AS stnd_unit_price
            ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt
            ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt
            ,lt_lkup_code              AS c_tax
      FROM  (-- 購買関連
             SELECT /*+ leading(itp gic1 mcb1 rsl rt pha pla plla) use_nl(itp gic1 mcb1)*/
/*
                    pha.attribute10         AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,pha.vendor_id           AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itp.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itp.item_id
                    AND    xlc.lot_id  = itp.lot_id)  AS purchases_price
                   ,NVL(plla.attribute2,'0') AS powder_price
                   ,NVL(plla.attribute4,'0') AS commission_price
                   ,NVL(plla.attribute7,'0') AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_pnd              itp
                   ,rcv_shipment_lines       rsl
                   ,rcv_transactions         rt
                   ,po_headers_all           pha
                   ,po_lines_all             pla
                   ,po_line_locations_all    plla
                   ,ic_item_mst_b            iimb
                   ,xxcmn_item_mst_b         ximb
                   ,gmi_item_categories      gic1
                   ,mtl_categories_b         mcb1
                   ,gmi_item_categories      gic2
                   ,mtl_categories_b         mcb2
                   ,mtl_categories_tl        mct2
                   ,gmi_item_categories      gic3
                   ,mtl_categories_b         mcb3
                   ,gmi_item_categories      gic4
                   ,mtl_categories_b         mcb4
                   ,xxcmn_vendors2_v         xvv
                   ,hr_locations_all         hl
                   ,xxcmn_locations_all      xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itp.doc_type                = cv_porc
             AND    itp.completed_ind           = gn_one
             AND    itp.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itp.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iimb.item_id                = itp.item_id
             AND    ximb.item_id                = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
             AND    gic1.item_id                = itp.item_id
             AND    gic1.category_set_id        = cn_prod_class_id
             AND    mcb1.category_id            = gic1.category_id
             AND    mcb1.segment1               = ir_param.prod_div
             AND    gic2.item_id                = itp.item_id
             AND    gic2.category_set_id        = cn_item_class_id
             AND    mcb2.category_id            = gic2.category_id
             AND    mct2.category_id            = mcb2.category_id
             AND    mct2.language               = gv_ja
             AND    gic3.item_id                = itp.item_id
             AND    gic3.category_set_id        = cn_crowd_code_id
             AND    mcb3.category_id            = gic3.category_id
             AND    gic4.item_id                = itp.item_id
             AND    gic4.category_set_id        = cn_acnt_crowd_id
             AND    mcb4.category_id            = gic4.category_id
             AND    rsl.shipment_header_id      = itp.doc_id
             AND    rsl.line_num                = itp.doc_line
             AND    rt.transaction_id           = itp.line_id
             AND    rt.shipment_line_id         = rsl.shipment_line_id
             AND    rsl.po_header_id            = pha.po_header_id
             AND    rsl.po_line_id              = pla.po_line_id
             AND    pla.po_line_id              = plla.po_line_id
             AND    rsl.source_document_code    = cv_po
             AND    rt.transaction_type     IN (cv_deliver
                                               ,cv_return_to_vendor)
             AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itp.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = pha.vendor_id
             AND    hl.location_code            = pha.attribute10
             AND    hl.location_id              = xl.location_id
             AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itp.trans_date)
             AND    xsupv.start_date_active     < (TRUNC(itp.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itp.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id                = itp.item_id
             UNION ALL -- 在庫調整(仕入先返品)
             SELECT /*+ leading(itc gic1 mcb1 iaj ijm xrrt ) use_nl(itc gic1 mcb1) */
/*
                    xrrt.department_code    AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,xrrt.vendor_id          AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itc.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itc.item_id
                    AND    xlc.lot_id  = itc.lot_id) AS purchases_price
                   ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price,0)) AS powder_price
                   ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price,0))  AS commission_price
                   ,TO_CHAR(NVL(xrrt.fukakin_price,0)) AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_cmp               itc
                   ,ic_adjs_jnl               iaj
                   ,ic_jrnl_mst               ijm
                   ,ic_item_mst_b             iimb
                   ,xxpo_rcv_and_rtn_txns     xrrt
                   ,xxcmn_item_mst_b          ximb
                   ,gmi_item_categories       gic1
                   ,mtl_categories_b          mcb1
                   ,gmi_item_categories       gic2
                   ,mtl_categories_b          mcb2
                   ,mtl_categories_tl         mct2
                   ,gmi_item_categories       gic3
                   ,mtl_categories_b          mcb3
                   ,gmi_item_categories       gic4
                   ,mtl_categories_b          mcb4
                   ,xxcmn_vendors2_v          xvv
                   ,hr_locations_all          hl
                   ,xxcmn_locations_all       xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itc.doc_type        = cv_adji
             AND    itc.reason_code     = cv_x201
             AND    itc.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itc.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iaj.trans_type      = itc.doc_type
             AND    iaj.doc_id          = itc.doc_id
             AND    iaj.doc_line        = itc.doc_line
             AND    ijm.journal_id      = iaj.journal_id
             AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1)
             AND    iimb.item_id        = itc.item_id
             AND    ximb.item_id        = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
             AND    gic1.item_id        = itc.item_id
             AND    gic1.category_set_id = cn_prod_class_id
             AND    mcb1.category_id    = gic1.category_id
             AND    mcb1.segment1       = ir_param.prod_div
             AND    gic2.item_id        = itc.item_id
             AND    gic2.category_set_id = cn_item_class_id
             AND    mcb2.category_id    = gic2.category_id
             AND    mct2.category_id    = mcb2.category_id
             AND    mct2.language       = gv_ja
             AND    gic3.item_id        = itc.item_id
             AND    gic3.category_set_id = cn_crowd_code_id
             AND    mcb3.category_id    = gic3.category_id
             AND    gic4.item_id        = itc.item_id
             AND    gic4.category_set_id = cn_acnt_crowd_id
             AND    mcb4.category_id    = gic4.category_id
             AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itc.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = xrrt.vendor_id
             AND    hl.location_code         = xrrt.department_code
             AND    hl.location_id           = xl.location_id
             and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itc.trans_date)
             and    xsupv.start_date_active <(TRUNC(itc.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itc.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id               = itc.item_id
            ) mst
      GROUP BY mst.result_post
              ,mst.location_name
              ,mst.item_div
              ,mst.item_div_name
              ,mst.segment1
              ,mst.vendor_name
              ,mst.crowd_code
              ,mst.item_code
              ,mst.item_s_name
              ,mst.item_um
              ,mst.item_atr15
              ,mst.lot_ctl
      ORDER BY mst.result_post
              ,mst.item_div
              ,mst.segment1
              ,mst.crowd_code
              ,mst.item_code
    ;
--yutsuzuk add
--
--yutsuzuk add
    CURSOR get_cur02 IS
      SELECT mst.result_post           AS result_post
            ,mst.location_name         AS location_name
            ,mst.item_div              AS item_div
            ,mst.item_div_name         AS item_div_name
            ,mst.segment1              AS vendor_code
            ,mst.vendor_name           AS vendor_name
            ,mst.crowd_code            AS crowd_code
            ,mst.item_code             AS item_code
            ,mst.item_s_name           AS item_s_name
            ,mst.item_um               AS item_um
            ,mst.item_atr15            AS item_atr15
            ,mst.lot_ctl               AS lot_ctl
            ,SUM(mst.trans_qty)        AS trans_qty
            ,AVG(mst.purchases_price)  AS purchases_price
            ,AVG(mst.powder_price)     AS powder_price
            ,AVG(mst.commission_price) AS commission_price
            ,SUM(mst.commission_price * mst.trans_qty) AS c_amt
            ,SUM(mst.assessment)       AS assessment
            ,AVG(mst.stnd_unit_price)  AS stnd_unit_price
            ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt
            ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt
            ,lt_lkup_code              AS c_tax
      FROM  (-- 購買関連
             SELECT /*+ leading(itp gic1 mcb1 gic2 mcb2 rsl rt pha pla plla) use_nl(itp gic1 mcb1 gic2 mcb2)*/
/*
                    pha.attribute10         AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,pha.vendor_id           AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itp.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itp.item_id
                    AND    xlc.lot_id  = itp.lot_id)  AS purchases_price
                   ,NVL(plla.attribute2,'0') AS powder_price
                   ,NVL(plla.attribute4,'0') AS commission_price
                   ,NVL(plla.attribute7,'0') AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_pnd              itp
                   ,rcv_shipment_lines       rsl
                   ,rcv_transactions         rt
                   ,po_headers_all           pha
                   ,po_lines_all             pla
                   ,po_line_locations_all    plla
                   ,ic_item_mst_b            iimb
                   ,xxcmn_item_mst_b         ximb
                   ,gmi_item_categories      gic1
                   ,mtl_categories_b         mcb1
                   ,gmi_item_categories      gic2
                   ,mtl_categories_b         mcb2
                   ,mtl_categories_tl        mct2
                   ,gmi_item_categories      gic3
                   ,mtl_categories_b         mcb3
                   ,gmi_item_categories      gic4
                   ,mtl_categories_b         mcb4
                   ,xxcmn_vendors2_v         xvv
                   ,hr_locations_all         hl
                   ,xxcmn_locations_all      xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itp.doc_type                = cv_porc
             AND    itp.completed_ind           = gn_one
             AND    itp.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itp.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iimb.item_id                = itp.item_id
             AND    ximb.item_id                = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itp.trans_date)
             AND    gic1.item_id                = itp.item_id
             AND    gic1.category_set_id        = cn_prod_class_id
             AND    mcb1.category_id            = gic1.category_id
             AND    mcb1.segment1               = ir_param.prod_div
             AND    gic2.item_id                = itp.item_id
             AND    gic2.category_set_id        = cn_item_class_id
             AND    mcb2.category_id            = gic2.category_id
             AND    mct2.category_id            = mcb2.category_id
             AND    mct2.language               = gv_ja
             AND    mcb2.segment1               = ir_param.item_div
             AND    gic3.item_id                = itp.item_id
             AND    gic3.category_set_id        = cn_crowd_code_id
             AND    mcb3.category_id            = gic3.category_id
             AND    gic4.item_id                = itp.item_id
             AND    gic4.category_set_id        = cn_acnt_crowd_id
             AND    mcb4.category_id            = gic4.category_id
             AND    rsl.shipment_header_id      = itp.doc_id
             AND    rsl.line_num                = itp.doc_line
             AND    rt.transaction_id           = itp.line_id
             AND    rt.shipment_line_id         = rsl.shipment_line_id
             AND    rsl.po_header_id            = pha.po_header_id
             AND    rsl.po_line_id              = pla.po_line_id
             AND    pla.po_line_id              = plla.po_line_id
             AND    rsl.source_document_code    = cv_po
             AND    rt.transaction_type     IN (cv_deliver
                                               ,cv_return_to_vendor)
             AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itp.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = pha.vendor_id
             AND    hl.location_code            = pha.attribute10
             AND    hl.location_id              = xl.location_id
             AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itp.trans_date)
             AND    xsupv.start_date_active     < (TRUNC(itp.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itp.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id                = itp.item_id
             UNION ALL -- 在庫調整(仕入先返品)
             SELECT /*+ leading(itc gic1 mcb1 gic2 mcb2 iaj ijm xrrt ) use_nl(itc gic1 mcb1 gic2 mcb2) */
/*
                    xrrt.department_code    AS result_post
                   ,mcb2.segment1           AS item_div
                   ,mct2.description        AS item_div_name
                   ,iimb.item_id            AS item_id
                   ,iimb.item_no            AS item_code
                   ,iimb.item_um            AS item_um
                   ,ximb.item_short_name    AS item_s_name
                   ,iimb.attribute15        AS item_atr15
                   ,iimb.lot_ctl            AS lot_ctl
                   ,xrrt.vendor_id          AS vendor_id
                   ,mcb3.segment1           AS crowd_code
                   ,mcb4.segment1           AS acnt_crowd_code
                   ,itc.trans_qty           AS trans_qty
                   ,(SELECT NVL(
                            DECODE(SUM(NVL(xlc.trans_qty,0))
                            ,0,0
                            ,SUM(xlc.trans_qty * NVL(xlc.unit_ploce,0)) / SUM(NVL(xlc.trans_qty,0))),0
                            ) AS purchases_price
                    FROM   xxcmn_lot_cost xlc
                    WHERE  xlc.item_id = itc.item_id
                    AND    xlc.lot_id  = itc.lot_id) AS purchases_price
                   ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price,0)) AS powder_price
                   ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price,0))  AS commission_price
                   ,TO_CHAR(NVL(xrrt.fukakin_price,0)) AS assessment
                   ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price
                   ,xvv.segment1            AS segment1
                   ,xvv.vendor_short_name   AS vendor_name
                   ,xl.location_short_name  AS location_name
             FROM   ic_tran_cmp               itc
                   ,ic_adjs_jnl               iaj
                   ,ic_jrnl_mst               ijm
                   ,ic_item_mst_b             iimb
                   ,xxpo_rcv_and_rtn_txns     xrrt
                   ,xxcmn_item_mst_b          ximb
                   ,gmi_item_categories       gic1
                   ,mtl_categories_b          mcb1
                   ,gmi_item_categories       gic2
                   ,mtl_categories_b          mcb2
                   ,mtl_categories_tl         mct2
                   ,gmi_item_categories       gic3
                   ,mtl_categories_b          mcb3
                   ,gmi_item_categories       gic4
                   ,mtl_categories_b          mcb4
                   ,xxcmn_vendors2_v          xvv
                   ,hr_locations_all          hl
                   ,xxcmn_locations_all       xl
                   ,xxcmn_stnd_unit_price_v  xsupv
             WHERE  itc.doc_type        = cv_adji
             AND    itc.reason_code     = cv_x201
             AND    itc.trans_date >= FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format)
             AND    itc.trans_date <  ADD_MONTHS(FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format),1)
             AND    iaj.trans_type      = itc.doc_type
             AND    iaj.doc_id          = itc.doc_id
             AND    iaj.doc_line        = itc.doc_line
             AND    ijm.journal_id      = iaj.journal_id
             AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1)
             AND    iimb.item_id        = itc.item_id
             AND    ximb.item_id        = iimb.item_id
             AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ximb.end_date_active   >= TRUNC(itc.trans_date)
             AND    gic1.item_id        = itc.item_id
             AND    gic1.category_set_id = cn_prod_class_id
             AND    mcb1.category_id    = gic1.category_id
             AND    mcb1.segment1       = ir_param.prod_div
             AND    gic2.item_id        = itc.item_id
             AND    gic2.category_set_id = cn_item_class_id
             AND    mcb2.category_id    = gic2.category_id
             AND    mct2.category_id    = mcb2.category_id
             AND    mct2.language       = gv_ja
             AND    mcb2.segment1       = ir_param.item_div
             AND    gic3.item_id        = itc.item_id
             AND    gic3.category_set_id = cn_crowd_code_id
             AND    mcb3.category_id    = gic3.category_id
             AND    gic4.item_id        = itc.item_id
             AND    gic4.category_set_id = cn_acnt_crowd_id
             AND    mcb4.category_id    = gic4.category_id
             AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1)
             AND    ((xvv.end_date_active >= TRUNC(itc.trans_date))
                    OR (xvv.end_date_active IS NULL))
             AND    xvv.vendor_id     = xrrt.vendor_id
             AND    hl.location_code         = xrrt.department_code
             AND    hl.location_id           = xl.location_id
             and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1)
             AND    xl.end_date_active    >= TRUNC(itc.trans_date)
             and    xsupv.start_date_active <(TRUNC(itc.trans_date) + 1)
             AND    ((xsupv.end_date_active     >= TRUNC(itc.trans_date))
                    OR(xsupv.end_date_active       IS NULL))
             AND    xsupv.item_id               = itc.item_id
            ) mst
      GROUP BY mst.result_post
              ,mst.location_name
              ,mst.item_div
              ,mst.item_div_name
              ,mst.segment1
              ,mst.vendor_name
              ,mst.crowd_code
              ,mst.item_code
              ,mst.item_s_name
              ,mst.item_um
              ,mst.item_atr15
              ,mst.lot_ctl
      ORDER BY mst.result_post
              ,mst.item_div
              ,mst.segment1
              ,mst.crowd_code
              ,mst.item_code
    ;
--yutsuzuk add
*/
-- 2008/10/14 v1.6 DELETE END
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;  -- 取得レコードなし
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 2008/10/14 v1.6 ADD START
    -- ----------------------------------------------------
    -- SELECT句生成
    -- ----------------------------------------------------
    lv_select := 'SELECT ';
-- 2008/12/12 v1.14 UPDATE START
/*
    -- 成績部署
    IF ( ir_param.result_post IS NULL ) THEN
      lv_select := lv_select
        || '       mst.result_post           AS result_post '
        || '      ,mst.location_name         AS location_name ';
    ELSE
      lv_select := lv_select
        || '       NULL                      AS result_post '
        || '      ,NULL                      AS location_name ';
    END IF;
--
    lv_select := lv_select
      || '      ,mst.item_div              AS item_div '
      || '      ,mst.item_div_name         AS item_div_name ';
--
    -- 仕入先
    IF ( ir_param.party_code IS NULL ) THEN
      lv_select := lv_select
        || '      ,mst.segment1              AS vendor_code '
        || '      ,mst.vendor_name           AS vendor_name ';
    ELSE
      lv_select := lv_select
        || '      ,NULL                      AS vendor_code '
        || '      ,NULL                      AS vendor_name ';
    END IF;
*/
    -- 成績部署
    lv_select := lv_select
      || '       mst.result_post             AS result_post '
      || '      ,mst.location_name           AS location_name ';
--
    lv_select := lv_select
      || '      ,mst.item_div                AS item_div '
      || '      ,mst.item_div_name           AS item_div_name ';
--
    -- 仕入先
    lv_select := lv_select
      || '      ,mst.segment1                AS vendor_code '
      || '      ,mst.vendor_name             AS vendor_name ';
-- 2008/12/12 v1.14 UPDATE END
--
    -- 群種別
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- 群別
      lv_select := lv_select
        || '      ,mst.crowd_code            AS crowd_code';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- 経理群別
      lv_select := lv_select
        || '      ,mst.acnt_crowd_code       AS crowd_code ';
    END IF;
--
    lv_select := lv_select
      || '      ,mst.item_code             AS item_code '
      || '      ,mst.item_s_name           AS item_s_name '
      || '      ,mst.item_um               AS item_um '
      || '      ,mst.item_atr15            AS item_atr15 '
      || '      ,mst.lot_ctl               AS lot_ctl '
      || '      ,SUM(mst.trans_qty)        AS trans_qty '
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '      ,SUM(mst.purchases_price)   / SUM(mst.trans_qty) AS purchases_price '
--      || '      ,SUM(mst.powder_price)      / SUM(mst.trans_qty) AS powder_price '
--      || '      ,SUM(mst.commission_price)  / SUM(mst.trans_qty) AS commission_price '
      || '      ,SUM(mst.purchases_price)  / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS purchases_price '
      || '      ,SUM(mst.powder_price)     / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS powder_price '
      || '      ,SUM(mst.commission_price) / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS commission_price '
-- 2008/10/28 H.Itou Mod End
-- 2008/12/05 v1.13 UPDATE START
--      || '      ,SUM(mst.commission_price * mst.trans_qty) AS c_amt '
      || '      ,SUM(mst.commission_price) AS c_amt '
-- 2008/12/05 v1.13 UPDATE END
      || '      ,SUM(mst.assessment)       AS assessment '
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '      ,SUM(mst.stnd_unit_price)   / SUM(mst.trans_qty) AS stnd_unit_price '
-- 2008/11/19 N.Yoshida mod start 移行データ検証不具合対応
--      || '      ,SUM(mst.stnd_unit_price) / DECODE(SUM(mst.trans_qty),0,1,SUM(mst.trans_qty)) AS stnd_unit_price '
      || '      ,mst.stnd_unit_price       AS stnd_unit_price '
-- 2008/11/19 N.Yoshida mod end 移行データ検証不具合対応
-- 2008/10/28 H.Itou Mod End
-- 2009/01/09 N.Yoshida Mod Start
--      || '      ,SUM(mst.stnd_unit_price * mst.trans_qty) AS j_amt '
-- 2012/03/23 v1.17 Mod Start
--      || '      ,SUM(ROUND(mst.stnd_unit_price * mst.trans_qty)) AS j_amt '
      || '      ,SUM(mst.j_amt) AS j_amt '
-- 2012/03/23 v1.17 Mod End
-- 2009/01/09 N.Yoshida Mod End
--      || '      ,SUM(mst.purchases_price * mst.trans_qty) AS s_amt '
--      || '      ,SUM(mst.purchases_price) AS s_amt '
      || '      ,SUM(mst.powder_price) AS s_amt '
-- 2012/03/23 v1.17 Mod Start
---- 2008/12/05 v1.13 ADD START
--      || '      ,SUM(ROUND((mst.commission_price * :para_lkup_code) /100)) AS commission_tax '
--      || '      ,SUM( '
--                -- 支払金額消費税
--      || '            ROUND(NVL(mst.powder_price, ''' || gn_zero || ''') * :para_lkup_code / 100)'
--                -- 口銭金額消費税
--      || '          - ROUND(NVL(mst.commission_price, ''' || gn_zero || ''')  * :para_lkup_code / 100) '
--      || '           ) AS payment_tax '
---- 2008/12/05 v1.13 ADD END
      || '      ,SUM(mst.commission_tax) AS commission_tax '
-- v1.18 MOD START
--      || '      ,SUM(mst.payment_tax) AS payment_tax '
---- 2012/03/23 v1.17 Mod End
--      || '      ,:para_lkup_code              AS c_tax ';
      || '      ,SUM(mst.payment_tax) AS payment_tax ';
-- v1.18 MOD END
--
    -- ----------------------------------------------------
    -- 購買関連生成
    -- ----------------------------------------------------
    lv_porc_po := 'FROM '
      || '      ( '
-- 2008/11/13 v1.8 UPDATE START
--      || '       SELECT /*+ leading(itp gic1 mcb1 rsl rt pha pla plla) use_nl(itp gic1 mcb1)*/ '
      || '       SELECT /*+ leading(itp xrpm gic1 mcb1 rsl rt pha pla plla) use_nl(itp xrpm gic1 mcb1)*/ '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/12/12 v1.14 UPDATE START
--      || '              pha.attribute10         AS result_post '
--      || '             ,mcb2.segment1           AS item_div '
      || '              mcb2.segment1           AS item_div '
-- 2008/12/12 v1.14 UPDATE END
      || '             ,mct2.description        AS item_div_name '
      || '             ,iimb.item_id            AS item_id '
      || '             ,iimb.item_no            AS item_code '
      || '             ,iimb.item_um            AS item_um '
      || '             ,ximb.item_short_name    AS item_s_name '
      || '             ,iimb.attribute15        AS item_atr15 '
      || '             ,iimb.lot_ctl            AS lot_ctl '
      || '             ,pha.vendor_id           AS vendor_id '
      || '             ,mcb3.segment1           AS crowd_code '
      || '             ,mcb4.segment1           AS acnt_crowd_code '
-- 2008/11/13 v1.8 UPDATE START
--      || '             ,itp.trans_qty           AS trans_qty '
--      || '             ,NVL(pla.unit_price, 0) * NVL(itp.trans_qty, 0) AS purchases_price '
-- 2012/03/23 v1.17 Mod Start
--      || '             ,NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div) AS trans_qty '
      || '             ,SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) AS trans_qty '
-- 2012/03/23 v1.17 Mod End
-- 2008/11/29 v1.10 UPDATE START
--      || '            ,ROUND(NVL(pla.unit_price, 0) '
-- 2012/03/23 v1.17 Mod Start
--      || '            ,ROUND(NVL(pla.attribute8, 0) '
--      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS purchases_price '
-- v1.19 Mod Start
--      || '            ,SUM(ROUND(NVL(pla.attribute8, 0)'
--      || '              * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS purchases_price '
      || '            ,ROUND(NVL(pla.attribute8, 0)'
      || '              * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS purchases_price '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
-- 2008/11/13 v1.8 UPDATE END
--      || '             ,NVL(plla.attribute2, :para_zero) AS powder_price '
-- 2012/03/23 v1.17 Mod Start
--      || '            ,ROUND(NVL(pla.unit_price, :para_zero) '
--      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS powder_price '
-- v1.19 Mod Start
--      || '            ,SUM(ROUND(NVL(pla.unit_price, :para_zero) '
--      || '             * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS powder_price '
      || '            ,ROUND(NVL(pla.unit_price, :para_zero) '
      || '             * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS powder_price '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
--      || '             ,NVL(plla.attribute4, :para_zero) AS commission_price '
-- 2008/12/06 MOD START
--      || '            ,ROUND(NVL(plla.attribute4, :para_zero) '
--      || '             * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS commission_price '
--      || '             ,NVL(plla.attribute7, :para_zero) AS assessment '
-- 2012/03/23 v1.17 Mod Start
--      || '            ,TO_NUMBER(NVL(plla.attribute5, :para_zero)) AS commission_price '
--      || '            ,TO_NUMBER(NVL(plla.attribute8, :para_zero)) AS assessment '
      || '            ,CASE plla.attribute3 '
      || '               WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(TRUNC( NVL(plla.attribute4, 0) * NVL(itp.trans_qty, 0))) '
      || '                 TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) '
-- v1.19 Mod End
      || '               WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(TRUNC( pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute4, 0) / 100 )) '
      || '                 TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute4, 0) / 100 ) '
-- v1.19 Mod End
      || '               ELSE '
      || '                 0 '
      || '             END AS commission_price '                                -- 口銭金額
      || '            ,CASE plla.attribute6 '
      || '               WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(TRUNC( NVL(plla.attribute7,0) * NVL(itp.trans_qty, 0))) '
      || '                 TRUNC( NVL(plla.attribute7,0) * SUM(NVL(itp.trans_qty, 0))) '
-- v1.19 Mod End
      || '               WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(TRUNC((pla.attribute8 * NVL(itp.trans_qty, 0) '
--      || '                           - pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute1,0) / 100) '
--      || '                           * NVL(plla.attribute7,0) / 100)) '
      || '                 TRUNC((pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) '
      || '                           - pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute1,0) / 100) '
      || '                           * NVL(plla.attribute7,0) / 100) '
-- v1.19 Mod End
      || '               ELSE '
      || '                 0 '
      || '             END AS assessment '                                      -- 賦課金額
      || '            ,CASE plla.attribute3 '
      || '               WHEN ''1'' THEN '
-- v1.19 Mod Start
---- v1.18 MOD START
----      || '                 SUM(ROUND(TRUNC( NVL(plla.attribute4, 0) * NVL(itp.trans_qty, 0)) * :para_lkup_code / 100)) '
--      || '                 SUM(ROUND(TRUNC( NVL(plla.attribute4, 0) * NVL(itp.trans_qty, 0)) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                 ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '               WHEN ''2'' THEN '
-- v1.19 Mod Start
---- v1.18 MOD START
----      || '                 SUM(ROUND(TRUNC( pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute4, 0) / 100 ) * :para_lkup_code / 100)) '
--      || '                 SUM(ROUND(TRUNC( pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                 ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '               ELSE '
      || '                 0 '
      || '             END AS commission_tax '                                  -- 口銭消費税金額
      || '            ,CASE plla.attribute3 '
      || '               WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * :para_lkup_code / 100) '
----      || '                 - ROUND(TRUNC( NVL(plla.attribute4, 0) * NVL(itp.trans_qty, 0)) * :para_lkup_code / 100)) '
--      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * TO_NUMBER(xlv2v.lookup_code) / 100) '
--      || '                 - ROUND(TRUNC( NVL(plla.attribute4, 0) * NVL(itp.trans_qty, 0)) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                 ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
      || '                 * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
      || '                 - ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '               WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                 SUM(ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * :para_lkup_code / 100) '
----      || '                 - ROUND(TRUNC( pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute4, 0) / 100 ) * :para_lkup_code / 100)) '
--      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * TO_NUMBER(xlv2v.lookup_code) / 100) '
--      || '                 - ROUND(TRUNC( pla.attribute8 * NVL(itp.trans_qty, 0) * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                 ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
      || '                 * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
      || '                 - ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '               ELSE '
-- v1.19 Mod Start
--      || '                 SUM(ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * :para_lkup_code / 100)) '
--      || '                 * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                 ROUND(ROUND(NVL(pla.unit_price, :para_zero) '
      || '                 * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '             END AS payment_tax '                                     -- 支払消費税金額
-- v1.19 Mod Start
--      || '            ,SUM(ROUND(NVL(xsupv.stnd_unit_price,0) * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS j_amt '
      || '            ,ROUND(NVL(xsupv.stnd_unit_price,0) * SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))) AS j_amt '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
-- 2008/12/06 MOD END
-- 2008/11/29 v1.10 UPDATE END
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '             ,(NVL((SELECT xsupv.stnd_unit_price '
--      || '                    FROM   xxcmn_stnd_unit_price_v xsupv '
--      || '                    WHERE  xsupv.start_date_active < (TRUNC(itp.trans_date) + 1) '
--      || '                    AND    ((xsupv.end_date_active >= TRUNC(itp.trans_date)) '
--      || '                             OR (xsupv.end_date_active IS NULL)) '
--      || '                    AND    xsupv.item_id = itp.item_id), 0)) AS stnd_unit_price '
-- 2008/12/12 v1.14 UPDATE START
--      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price '
-- 2008/10/28 H.Itou Mod End
--      || '             ,xvv.segment1            AS segment1 '
--      || '             ,xvv.vendor_short_name   AS vendor_name '
--      || '             ,xl.location_short_name  AS location_name '
      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price ';
    -- 成績部署
    IF ( ir_param.result_post IS NULL ) THEN
    lv_porc_po := lv_porc_po
      || '      ,pha.attribute10                AS result_post '
      || '      ,xl.location_short_name         AS location_name ';
    ELSE
    lv_porc_po := lv_porc_po
      || '      ,NULL                           AS result_post '
      || '      ,NULL                           AS location_name ';
    END IF;
    -- 仕入先
    IF ( ir_param.party_code IS NULL ) THEN
    lv_porc_po := lv_porc_po
      || '      ,xvv.segment1                   AS segment1 '
      || '      ,xvv.vendor_short_name          AS vendor_name ';
    ELSE
    lv_porc_po := lv_porc_po
      || '      ,NULL                           AS segment1 '
      || '      ,NULL                           AS vendor_name ';
    END IF;
    lv_porc_po := lv_porc_po
-- 2008/12/12 v1.14 UPDATE END
      || '       FROM   ic_tran_pnd              itp '
      || '             ,rcv_shipment_lines       rsl '
      || '             ,rcv_transactions         rt '
      || '             ,po_headers_all           pha '
      || '             ,po_lines_all             pla '
      || '             ,po_line_locations_all    plla '
      || '             ,ic_item_mst_b            iimb '
      || '             ,xxcmn_item_mst_b         ximb '
      || '             ,gmi_item_categories      gic1 '
      || '             ,mtl_categories_b         mcb1 '
      || '             ,gmi_item_categories      gic2 '
      || '             ,mtl_categories_b         mcb2 '
      || '             ,mtl_categories_tl        mct2 '
      || '             ,gmi_item_categories      gic3 '
      || '             ,mtl_categories_b         mcb3 '
      || '             ,gmi_item_categories      gic4 '
      || '             ,mtl_categories_b         mcb4 '
      || '             ,xxcmn_vendors2_v         xvv '
      || '             ,hr_locations_all         hl '
      || '             ,xxcmn_locations_all      xl '
-- 2008/10/28 H.Itou Add Start T_S_524対応(再対応)
      || '             ,xxcmn_stnd_unit_price_v  xsupv '
-- 2008/10/28 H.Itou Add End
-- 2008/11/13 v1.8 ADD START
      || '             ,xxcmn_rcv_pay_mst        xrpm '
-- 2008/11/13 v1.8 ADD END
-- v1.18 ADD START
      || '             ,xxcmn_lookup_values2_v   xlv2v '  -- 消費税率情報VIEW
-- v1.18 ADD END
      || '       WHERE  itp.doc_type                = :para_porc '
      || '       AND    itp.completed_ind           = :para_one '
      || '       AND    itp.trans_date '
      || '                >=FND_DATE.STRING_TO_DATE(:para_param_proc_from '
      || '                                         ,:para_char_yyyymm_format) '
      || '       AND    itp.trans_date '
      || '                < ADD_MONTHS( '
      || '                  FND_DATE.STRING_TO_DATE(:para_param_proc_to '
      || '                                         ,:para_char_yyyymm_format), 1) '
      || '       AND    iimb.item_id                = itp.item_id '
      || '       AND    ximb.item_id                = iimb.item_id '
      || '       AND    ximb.start_date_active < (TRUNC(itp.trans_date) + 1) '
      || '       AND    ximb.end_date_active   >= TRUNC(itp.trans_date) '
      || '       AND    gic1.item_id                = itp.item_id '
      || '       AND    gic1.category_set_id        = :para_prod_class_id '
      || '       AND    mcb1.category_id            = gic1.category_id '
      || '       AND    mcb1.segment1               = :para_param_prod_div '
      || '       AND    gic2.item_id                = itp.item_id '
      || '       AND    gic2.category_set_id        = :para_item_class_id '
      || '       AND    mcb2.category_id            = gic2.category_id '
      || '       AND    mct2.category_id            = mcb2.category_id '
      || '       AND    mct2.language               = :para_ja '
      || '       AND    gic3.item_id                = itp.item_id '
      || '       AND    gic3.category_set_id        = :para_crowd_code_id '
      || '       AND    mcb3.category_id            = gic3.category_id '
      || '       AND    gic4.item_id                = itp.item_id '
      || '       AND    gic4.category_set_id        = :para_acnt_crowd_id '
      || '       AND    mcb4.category_id            = gic4.category_id '
      || '       AND    rsl.shipment_header_id      = itp.doc_id '
      || '       AND    rsl.line_num                = itp.doc_line '
      || '       AND    rt.transaction_id           = itp.line_id '
      || '       AND    rt.shipment_line_id         = rsl.shipment_line_id '
      || '       AND    rsl.po_header_id            = pha.po_header_id '
      || '       AND    rsl.po_line_id              = pla.po_line_id '
      || '       AND    pla.po_line_id              = plla.po_line_id '
      || '       AND    rsl.source_document_code    = :para_po '
-- 2008/12/04 v1.14 UPDATE START
      || '       AND    rt.transaction_type         = xrpm.transaction_type'
--      || '       AND    rt.transaction_type     IN (:para_deliver '
--      || '                                         ,:para_return_to_vendor) '
-- 2008/12/04 v1.14 UPDATE END
      || '       AND    xvv.start_date_active < (TRUNC(itp.trans_date) + 1) '
      || '       AND    ((xvv.end_date_active >= TRUNC(itp.trans_date)) '
      || '              OR (xvv.end_date_active IS NULL)) '
      || '       AND    xvv.vendor_id               = pha.vendor_id '
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '       AND    hl.location_code            = pha.attribute10 '
--      || '       AND    hl.location_id              = xl.location_id '
--      || '       AND    xl.start_date_active  < (TRUNC(itp.trans_date) + 1) '
--      || '       AND ( '
--      || '             (xl.end_date_active >= TRUNC(itp.trans_date)) '
--      || '             OR '
--      || '             (xl.end_date_active IS NULL) '
--      || '           ) '
      || '       AND hl.location_code(+) = pha.attribute10 '
      || '       AND hl.location_id      = xl.location_id(+) '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itp.trans_date) + 1) '
--      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itp.trans_date) '
      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itp.trans_date) + 1) '
      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itp.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
      || '       AND xsupv.item_id(+)    = itp.item_id '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itp.trans_date) + 1) '
--      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itp.trans_date) '
      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itp.trans_date) + 1) '
      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itp.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/10/28 H.Itou Mod End
-- v1.18 ADD START
      || '       AND    xlv2v.lookup_type         = :para_xxcmn_ctr '  -- 消費税率マスタ(LOOKUP表)
      -- 発注データの納入日基準
      || '       AND    xlv2v.start_date_active  < (FND_DATE.STRING_TO_DATE(pha.attribute4, :para_char_std_format) + 1) '
      || '       AND    xlv2v.end_date_active    >= FND_DATE.STRING_TO_DATE(pha.attribute4, :para_char_std_format) '
-- v1.18 ADD END
-- 2008/11/13 v1.8 ADD START
      || '       AND    xrpm.doc_type             = :para_porc '
      || '       AND    xrpm.source_document_code <> :para_rma '
      || '       AND    rsl.source_document_code  = xrpm.source_document_code '
      || '       AND    rt.transaction_type       = xrpm.transaction_type '
      || '       AND    xrpm.source_document_code = :para_po '
-- 2008/12/04 v1.14 DELETE START
--      || '       AND    xrpm.transaction_type IN (:para_deliver, :para_return_to_vendor) '
-- 2008/12/04 v1.14 DELETE END
      || '       AND    itp.doc_type              = xrpm.doc_type '
      || '       AND    xrpm.break_col_05         IS NOT NULL '
-- 2008/11/13 v1.8 ADD END
      ;
--
    -- 品目区分
    IF ( ir_param.item_div IS NOT NULL ) THEN
      lv_porc_po := lv_porc_po
        || '       AND    mcb2.segment1               = ''' || ir_param.item_div || '''';
    END IF;
--
    -- 成績部署
    IF ( (ir_param.result_post IS NOT NULL)
      AND (ir_param.result_post <> xxcmn770015c.dept_code_all) ) THEN
      lv_porc_po := lv_porc_po
        || '       AND pha.attribute10 = ''' || ir_param.result_post || '''';
    END IF;
--
    -- 仕入先
    IF ( (ir_param.party_code IS NOT NULL)
      AND (ir_param.party_code <> xxcmn770015c.dept_code_all) ) THEN
      lv_porc_po := lv_porc_po
        || '       AND pha.vendor_id = ''' || gn_para_vendor_id || '''';
    END IF;
--
    -- 群種別
    IF ( (ir_param.crowd_type = cv_crowd_type)
      AND (ir_param.crowd_code IS NOT NULL) ) THEN
      -- 群別
      lv_porc_po := lv_porc_po
        || '       AND mcb3.segment1 = ''' || ir_param.crowd_code || '''';
    ELSIF ( (ir_param.crowd_type = cv_crowd_type_acnt)
      AND (ir_param.acnt_crowd_code IS NOT NULL) ) THEN
      -- 経理群別
      lv_porc_po := lv_porc_po
        || '       AND mcb4.segment1 = ''' || ir_param.acnt_crowd_code || '''';
    END IF;
--
-- 2012/03/23 v1.17 Add Start
    lv_porc_po := lv_porc_po
                    || ' GROUP BY mcb2.segment1 '
                    || '         ,mct2.description '
                    || '         ,iimb.item_id '
                    || '         ,iimb.item_no '
                    || '         ,iimb.item_um '
                    || '         ,ximb.item_short_name '
                    || '         ,iimb.attribute15 '
                    || '         ,iimb.lot_ctl '
                    || '         ,pha.vendor_id '
                    || '         ,mcb3.segment1 '
                    || '         ,mcb4.segment1 '
                    || '         ,xrpm.rcv_pay_div '
                    || '         ,pla.attribute8 '
                    || '         ,pla.unit_price '
                    || '         ,plla.attribute5 '
                    || '         ,plla.attribute8 '
                    || '         ,xsupv.stnd_unit_price '
                    || '         ,pha.attribute10 '
                    || '         ,xl.location_short_name '
                    || '         ,xvv.segment1 '
                    || '         ,xvv.vendor_short_name '
                    || '         ,plla.attribute3 '
                    || '         ,plla.attribute4 '
                    || '         ,plla.attribute6 '
                    || '         ,plla.attribute7 '
-- v1.19 Add Start
                    || '         ,rsl.attribute1 '
                    || '         ,xlv2v.lookup_code '
-- v1.19 Add End
                    || '         ,plla.attribute1 ';
-- 2012/03/23 v1.17 Add End
--
    -- ----------------------------------------------------
    -- 在庫調整(仕入先返品)生成
    -- ----------------------------------------------------
    lv_adji := 'UNION ALL '
-- 2008/11/13 v1.8 UPDATE START
--      || '       SELECT /*+ leading(itc gic1 mcb1 iaj ijm xrrt ) use_nl(itc gic1 mcb1) */ '
      || '       SELECT /*+ leading(itc xrpm gic1 mcb1 iaj ijm xrrt ) use_nl(itc xrpm gic1 mcb1) */ '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/12/12 v1.14 UPDATE START
--      || '              xrrt.department_code    AS result_post '
--      || '             ,mcb2.segment1           AS item_div '
      || '              mcb2.segment1           AS item_div '
-- 2008/12/12 v1.14 UPDATE END
      || '             ,mct2.description        AS item_div_name '
      || '             ,iimb.item_id            AS item_id '
      || '             ,iimb.item_no            AS item_code '
      || '             ,iimb.item_um            AS item_um '
      || '             ,ximb.item_short_name    AS item_s_name '
      || '             ,iimb.attribute15        AS item_atr15 '
      || '             ,iimb.lot_ctl            AS lot_ctl '
      || '             ,xrrt.vendor_id          AS vendor_id '
      || '             ,mcb3.segment1           AS crowd_code '
      || '             ,mcb4.segment1           AS acnt_crowd_code '
-- 2008/11/13 v1.8 UPDATE START
--      || '             ,itc.trans_qty           AS trans_qty '
--      || '             ,NVL(xrrt.unit_price, 0) '
--      || '                * NVL(itc.trans_qty, 0) AS purchases_price '
-- 2012/03/23 v1.17 Mod Start
--      || '             ,NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)) AS trans_qty '
--      || '      ,ROUND(NVL(xrrt.unit_price, 0) '
--      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS purchases_price '
      || '             ,SUM(NVL(itc.trans_qty, 0)) * ABS(TO_NUMBER(xrpm.rcv_pay_div)) AS trans_qty '
-- v1.19 Mod Start
--      || '             ,SUM(ROUND(NVL(xrrt.unit_price, 0) '
--      || '                * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS purchases_price '
      || '             ,ROUND(NVL(xrrt.unit_price, 0) '
      || '                * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS purchases_price '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
-- 2008/11/13 v1.8 UPDATE START
-- 2008/11/29 v1.10 UPDATE START
--      || '             ,TO_CHAR(NVL(xrrt.kobki_converted_unit_price, :para_zero)) AS powder_price '
-- 2012/03/23 v1.17 Mod Start
--      || '      ,ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
--      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS powder_price '
-- v1.19 Mod Start
--      || '             ,SUM(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
--      || '                * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS powder_price '
      || '             ,ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
      || '                * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS powder_price '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
--      || '           ,TO_CHAR(NVL(xrrt.kousen_rate_or_unit_price, :para_zero)) AS commission_price '
-- 2012/03/23 v1.17 Mod Start
--      || '      ,ROUND(NVL(xrrt.kousen_rate_or_unit_price, :para_zero) '
--      || '        * (NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS commission_price '
----2009/07/09 MOD START
----      || '             ,NVL(xrrt.fukakin_price, :para_zero) AS assessment '
--      || '             ,(NVL(xrrt.fukakin_price, :para_zero) * -1 ) AS assessment '
----2009/07/09 MOD END
      || '             ,CASE xrrt.kousen_type '
      || '                WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
--      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) '
      || '                  TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
      || '                  * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) '
-- v1.19 Mod End
      || '                WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(TRUNC( xrrt.unit_price * NVL(itc.trans_qty, 0) '
--      || '                  * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) '
      || '                  TRUNC( xrrt.unit_price * SUM(NVL(itc.trans_qty, 0)) '
      || '                  * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) '
-- v1.19 Mod End
      || '                ELSE '
      || '                  0 '
      || '                END AS commission_price '                                       -- 口銭金額
      || '             ,CASE xrrt.fukakin_type '
      || '                WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(TRUNC( NVL(xrrt.fukakin_rate_or_unit_price, 0) * ABS(NVL(itc.trans_qty, 0))) * -1) '
      || '                  TRUNC( NVL(xrrt.fukakin_rate_or_unit_price, 0) * ABS(SUM(NVL(itc.trans_qty, 0)))) * -1 '
-- v1.19 Mod End
      || '                WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(TRUNC((xrrt.unit_price * ABS(NVL(itc.trans_qty, 0)) '
--      || '                            - xrrt.unit_price * ABS(NVL(itc.trans_qty, 0)) * NVL(xrrt.kobiki_rate,0) / 100) '
--      || '                            * NVL(xrrt.fukakin_rate_or_unit_price,0) / 100) * -1) '
      || '                  TRUNC((xrrt.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) '
      || '                            - xrrt.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) * NVL(xrrt.kobiki_rate,0) / 100) '
      || '                            * NVL(xrrt.fukakin_rate_or_unit_price,0) / 100) * -1 '
-- v1.19 Mod End
      || '                ELSE '
      || '                  0 '
      || '              END AS assessment '                                             -- 賦課金額
      || '             ,CASE xrrt.kousen_type '
      || '                WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(ROUND(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
---- v1.18 MOD START
----      || '                    * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100)) '
--      || '                    * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                  ROUND(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
      || '                    * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '                WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(ROUND(TRUNC( xrrt.unit_price * NVL(itc.trans_qty, 0) '
---- v1.18 MOD START
----      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100)) '
--      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                  ROUND(TRUNC( xrrt.unit_price * SUM(NVL(itc.trans_qty, 0)) '
      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '                ELSE '
      || '                  0 '
      || '              END AS commission_tax '                                         -- 口銭消費税金額
      || '             ,CASE xrrt.kousen_type '
      || '                WHEN ''1'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100) '
----      || '                  - ROUND(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
----      || '                    * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100)) '
--      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
--      || '                  - ROUND(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
--      || '                    * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                  ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
      || '                  * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
      || '                  - ROUND(TRUNC(NVL(xrrt.kousen_rate_or_unit_price, 0) '
      || '                    * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '                WHEN ''2'' THEN '
-- v1.19 Mod Start
--      || '                  SUM(ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100) '
----      || '                  - ROUND(TRUNC( xrrt.unit_price * NVL(itc.trans_qty, 0) '
----      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100)) '
--      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
--      || '                  - ROUND(TRUNC( xrrt.unit_price * NVL(itc.trans_qty, 0) '
--      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                  ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
      || '                  * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
      || '                  - ROUND(TRUNC( xrrt.unit_price * SUM(NVL(itc.trans_qty, 0)) '
      || '                    * NVL(xrrt.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '                ELSE '
-- v1.19 Mod Start
--      || '                  SUM(ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
---- v1.18 MOD START
----      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * :para_lkup_code / 100)) '
--      || '                  * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)) '
---- v1.18 MOD END
      || '                  ROUND(ROUND(NVL(xrrt.kobki_converted_unit_price, :para_zero) '
      || '                  * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100) '
-- v1.19 Mod End
      || '              END AS payment_tax '                                            -- 支払消費税金額
-- v1.19 Mod Start
--      || '             ,SUM(ROUND(NVL(xsupv.stnd_unit_price,0) * NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS j_amt '
      || '             ,ROUND(NVL(xsupv.stnd_unit_price,0) * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) AS j_amt '
-- v1.19 Mod End
-- 2012/03/23 v1.17 Mod End
-- 2008/11/29 v1.10 UPDATE END
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '             ,(NVL((SELECT xsupv.stnd_unit_price '
--      || '                    FROM   xxcmn_stnd_unit_price_v xsupv '
--      || '                    WHERE  xsupv.start_date_active < (TRUNC(itc.trans_date) + 1) '
--      || '                    AND    ((xsupv.end_date_active >= TRUNC(itc.trans_date)) '
--      || '                             OR (xsupv.end_date_active IS NULL)) '
--      || '                    AND    xsupv.item_id = itc.item_id), 0)) AS stnd_unit_price '
-- 2008/12/12 v1.14 UPDATE START
--      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price '
-- 2008/10/28 H.Itou Mod End
--      || '             ,xvv.segment1            AS segment1 '
--      || '             ,xvv.vendor_short_name   AS vendor_name '
--      || '             ,xl.location_short_name  AS location_name '
      || '             ,NVL(xsupv.stnd_unit_price,0) AS stnd_unit_price ';
    -- 成績部署
    IF ( ir_param.result_post IS NULL ) THEN
    lv_adji := lv_adji
      || '      ,xrrt.department_code                AS result_post '
      || '      ,xl.location_short_name              AS location_name ';
    ELSE
    lv_adji := lv_adji
      || '      ,NULL                                AS result_post '
      || '      ,NULL                                AS location_name ';
    END IF;
    -- 仕入先
    IF ( ir_param.party_code IS NULL ) THEN
    lv_adji := lv_adji
      || '      ,xvv.segment1                        AS segment1 '
      || '      ,xvv.vendor_short_name               AS vendor_name ';
    ELSE
    lv_adji := lv_adji
      || '      ,NULL                                AS segment1 '
      || '      ,NULL                                AS vendor_name ';
    END IF;
    lv_adji := lv_adji
-- 2008/12/12 v1.14 UPDATE END
      || '       FROM   ic_tran_cmp               itc '
      || '             ,ic_adjs_jnl               iaj '
      || '             ,ic_jrnl_mst               ijm '
      || '             ,ic_item_mst_b             iimb '
      || '             ,xxpo_rcv_and_rtn_txns     xrrt '
      || '             ,xxcmn_item_mst_b          ximb '
      || '             ,gmi_item_categories       gic1 '
      || '             ,mtl_categories_b          mcb1 '
      || '             ,gmi_item_categories       gic2 '
      || '             ,mtl_categories_b          mcb2 '
      || '             ,mtl_categories_tl         mct2 '
      || '             ,gmi_item_categories       gic3 '
      || '             ,mtl_categories_b          mcb3 '
      || '             ,gmi_item_categories       gic4 '
      || '             ,mtl_categories_b          mcb4 '
      || '             ,xxcmn_vendors2_v          xvv '
      || '             ,hr_locations_all          hl '
      || '             ,xxcmn_locations_all       xl '
-- 2008/10/28 H.Itou Add Start T_S_524対応(再対応)
      || '             ,xxcmn_stnd_unit_price_v  xsupv '
-- 2008/10/28 H.Itou Add End
-- 2008/11/13 v1.8 ADD START
      || '             ,xxcmn_rcv_pay_mst        xrpm '
-- 2008/11/13 v1.8 ADD END
-- v1.18 ADD START
      || '             ,xxcmn_lookup_values2_v   xlv2v '  -- 消費税率情報VIEW
      || '             ,(SELECT xrrt2.txns_id                   AS txns_id '
      || '                     ,CASE WHEN xrrt2.txns_type = '|| cv_sts_num_3 ||' THEN TRUNC(xrrt2.txns_date) '
      || '                           ELSE NVL(FND_DATE.STRING_TO_DATE(pha2.attribute4, :para_char_std_format) '
      || '                                  , TRUNC(xrrt2.txns_date)) '
      || '                      END                             AS txns_date '
      || '               FROM   xxpo_rcv_and_rtn_txns  xrrt2 '
      || '                     ,po_headers_all         pha2 '
      || '               WHERE  xrrt2.source_document_number = pha2.segment1(+) '
      || '               )                       pha '    -- 元発注データ情報
-- v1.18 ADD END
      || '       WHERE  itc.doc_type        = :para_adji '
      || '       AND    itc.reason_code     = :para_x201 '
      || '       AND    itc.trans_date '
      || '                >= FND_DATE.STRING_TO_DATE(:para_param_proc_from '
      || '                                          ,:para_char_yyyymm_format) '
      || '       AND    itc.trans_date '
      || '                < ADD_MONTHS( '
      || '                  FND_DATE.STRING_TO_DATE(:para_param_proc_to '
      || '                                         ,:para_char_yyyymm_format), 1) '
      || '       AND    iaj.trans_type      = itc.doc_type '
      || '       AND    iaj.doc_id          = itc.doc_id '
      || '       AND    iaj.doc_line        = itc.doc_line '
      || '       AND    ijm.journal_id      = iaj.journal_id '
      || '       AND    xrrt.txns_id        = TO_NUMBER(ijm.attribute1) '
      || '       AND    iimb.item_id        = itc.item_id '
      || '       AND    ximb.item_id        = iimb.item_id '
      || '       AND    ximb.start_date_active < (TRUNC(itc.trans_date) + 1) '
      || '       AND    ximb.end_date_active   >= TRUNC(itc.trans_date) '
      || '       AND    gic1.item_id        = itc.item_id '
      || '       AND    gic1.category_set_id = :para_prod_class_id '
      || '       AND    mcb1.category_id    = gic1.category_id '
      || '       AND    mcb1.segment1       = :para_param_prod_div '
      || '       AND    gic2.item_id        = itc.item_id '
      || '       AND    gic2.category_set_id = :para_item_class_id '
      || '       AND    mcb2.category_id    = gic2.category_id '
      || '       AND    mct2.category_id    = mcb2.category_id '
      || '       AND    mct2.language       = :para_ja '
      || '       AND    gic3.item_id        = itc.item_id '
      || '       AND    gic3.category_set_id = :para_crowd_code_id '
      || '       AND    mcb3.category_id    = gic3.category_id '
      || '       AND    gic4.item_id        = itc.item_id '
      || '       AND    gic4.category_set_id = :para_acnt_crowd_id '
      || '       AND    mcb4.category_id    = gic4.category_id '
      || '       AND    xvv.start_date_active < (TRUNC(itc.trans_date) + 1) '
      || '       AND    ((xvv.end_date_active >= TRUNC(itc.trans_date)) '
      || '              OR (xvv.end_date_active IS NULL)) '
      || '       AND    xvv.vendor_id     = xrrt.vendor_id '
-- 2008/10/28 H.Itou Mod Start T_S_524対応(再対応)
--      || '       AND    hl.location_code         = xrrt.department_code '
--      || '       AND    hl.location_id           = xl.location_id '
--      || '       and    xl.start_date_active  < (TRUNC(itc.trans_date) + 1) '
--      || '       AND ( '
--      || '             (xl.end_date_active >= TRUNC(itc.trans_date)) '
--      || '             OR '
--      || '             (xl.end_date_active IS NULL) '
--      || '           ) '
      || '       AND hl.location_code(+) = xrrt.department_code '
      || '       AND hl.location_id      = xl.location_id(+) '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itc.trans_date) + 1) '
--      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itc.trans_date) '
      || '       AND NVL(xl.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itc.trans_date) + 1) '
      || '       AND NVL(xl.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itc.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
      || '       AND xsupv.item_id(+)    = itc.item_id '
-- 2008/11/13 v1.8 UPDATE START
--      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE(''' || gv_min_date || ''', ''' || gc_char_dt_format || ''')) < (TRUNC(itc.trans_date) + 1) '
--      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE(''' || gv_max_date || ''', ''' || gc_char_dt_format || ''')) >= TRUNC(itc.trans_date) '
      || '       AND NVL(xsupv.start_date_active, FND_DATE.STRING_TO_DATE( '
      || '         :para_min_date, :para_char_dt_format)) < (TRUNC(itc.trans_date) + 1) '
      || '       AND NVL(xsupv.end_date_active,   FND_DATE.STRING_TO_DATE( '
      || '         :para_max_date, :para_char_dt_format)) >= TRUNC(itc.trans_date) '
-- 2008/11/13 v1.8 UPDATE END
-- 2008/10/28 H.Itou Mod End
-- v1.18 ADD START
      || '       AND    xrrt.txns_id                  =  pha.txns_id '
      || '       AND    xlv2v.lookup_type             =  :para_xxcmn_ctr '      -- 消費税率マスタ(LOOKUP表)
      || '       AND    xlv2v.start_date_active       < (pha.txns_date + 1) '
      || '       AND    xlv2v.end_date_active         >= pha.txns_date '
-- v1.18 ADD END
-- 2008/11/13 v1.8 ADD START
      || '       AND    xrpm.doc_type             = :para_adji '
      || '       AND    itc.doc_type              = xrpm.doc_type '
      || '       AND    itc.reason_code           = xrpm.reason_code '
      || '       AND    xrpm.break_col_05         IS NOT NULL '
-- 2008/11/13 v1.8 ADD END
      ;
--
    -- 品目区分
    IF ( ir_param.item_div IS NOT NULL ) THEN
      lv_adji := lv_adji
        || '       AND    mcb2.segment1               = ''' || ir_param.item_div || '''';
    END IF;
--
    -- 成績部署
    IF ( (ir_param.result_post IS NOT NULL)
      AND (ir_param.result_post <> xxcmn770015c.dept_code_all) ) THEN
      lv_adji := lv_adji
        || '       AND xrrt.department_code = ''' || ir_param.result_post || '''';
    END IF;
--
    -- 仕入先
    IF ( (ir_param.party_code IS NOT NULL)
      AND (ir_param.party_code <> xxcmn770015c.dept_code_all) ) THEN
      lv_adji := lv_adji
        || '       AND xrrt.vendor_id = ''' || gn_para_vendor_id || '''';
    END IF;
--
    -- 群種別
    IF ( (ir_param.crowd_type = cv_crowd_type)
      AND (ir_param.crowd_code IS NOT NULL) ) THEN
      -- 群別
      lv_adji := lv_adji
        || '       AND mcb3.segment1 = ''' || ir_param.crowd_code || '''';
    ELSIF ( (ir_param.crowd_type = cv_crowd_type_acnt)
      AND (ir_param.acnt_crowd_code IS NOT NULL) ) THEN
      -- 経理群別
      lv_adji := lv_adji
        || '       AND mcb4.segment1 = ''' || ir_param.acnt_crowd_code || '''';
    END IF;
--
-- 2012/03/23 v1.17 Add Start
    lv_adji := lv_adji 
                || ' GROUP BY mcb2.segment1 '
                || '         ,mct2.description '
                || '         ,iimb.item_id '
                || '         ,iimb.item_no '
                || '         ,iimb.item_um '
                || '         ,ximb.item_short_name '
                || '         ,iimb.attribute15 '
                || '         ,iimb.lot_ctl '
                || '         ,xrrt.vendor_id '
                || '         ,mcb3.segment1 '
                || '         ,mcb4.segment1 '
                || '         ,xrpm.rcv_pay_div '
                || '         ,xrrt.unit_price '
                || '         ,xrrt.kobki_converted_unit_price '
                || '         ,xrrt.kousen_type '
                || '         ,xrrt.kousen_rate_or_unit_price '
                || '         ,xrrt.fukakin_type '
                || '         ,xrrt.fukakin_rate_or_unit_price '
                || '         ,xrrt.kobiki_rate '
                || '         ,xsupv.stnd_unit_price '
                || '         ,xrrt.department_code '
                || '         ,xl.location_short_name '
                || '         ,xvv.segment1 '
-- v1.19 Add Start
                || '         ,ijm.attribute1 '
                || '         ,xlv2v.lookup_code '
-- v1.19 Add End
                || '         ,xvv.vendor_short_name ';
-- 2012/03/23 v1.17 Add End
--
    lv_adji := lv_adji
      || '      ) mst ';
--
    -- ----------------------------------------------------
    -- GROUP句生成
    -- ----------------------------------------------------
    lv_group := 'GROUP BY '
      || '         mst.result_post '
      || '        ,mst.location_name '
      || '        ,mst.item_div '
      || '        ,mst.item_div_name '
      || '        ,mst.segment1 '
      || '        ,mst.vendor_name ';
--
    -- 群種別
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- 群別
      lv_group := lv_group
        || '        ,mst.crowd_code ';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- 経理群別
      lv_group := lv_group
        || '        ,mst.acnt_crowd_code ';
    END IF;
--
    lv_group := lv_group
      || '        ,mst.item_code '
      || '        ,mst.item_s_name '
      || '        ,mst.item_um '
      || '        ,mst.item_atr15 '
      || '        ,mst.lot_ctl '
-- 2008/11/19 N.Yoshida mod start 移行データ検証不具合対応
      || '        ,mst.stnd_unit_price ';
-- 2008/11/19 N.Yoshida mod end 移行データ検証不具合対応
--
    -- ----------------------------------------------------
    -- ORDER句生成
    -- ----------------------------------------------------
    lv_order := 'ORDER BY ';
    -- 成績部署
    IF ( ir_param.result_post IS NULL ) THEN
      lv_order := lv_order
        || '         mst.result_post '
        || '        ,mst.item_div ';
    ELSE
      lv_order := lv_order
        || '         mst.item_div ';
    END IF;
    -- 仕入先
    IF ( ir_param.party_code IS NULL ) THEN
      lv_order := lv_order
        || '        ,mst.segment1 ';
    END IF;
    -- 群種別
    IF ( ir_param.crowd_type = cv_crowd_type ) THEN
      -- 群別
      lv_order := lv_order
        || '        ,mst.crowd_code ';
    ELSIF ( ir_param.crowd_type = cv_crowd_type_acnt ) THEN
      -- 経理群別
      lv_order := lv_order
        || '        ,mst.acnt_crowd_code ';
    END IF;
    lv_order := lv_order
      || '        ,mst.item_code ';
--
-- 2008/10/14 v1.6 ADD END
--yutsuzuk add
-- v1.18 DEL START
--    SELECT flv.lookup_code
--    INTO   lt_lkup_code
--    FROM   xxcmn_lookup_values_v flv
--    WHERE  flv.lookup_type = gv_xxcmn_ctr
--    AND    ROWNUM          = 1;
-- v1.18 DEL END
--yutsuzuk add
-- 2008/10/14 v1.6 UPDATE START
/*
--yutsuzuk add
    IF  ( ir_param.result_post IS NULL )        -- 成績部署未入力
    AND ( ir_param.party_code IS NULL )         -- 仕入先未入力
    AND ( ir_param.crowd_type = cv_crowd_type ) -- 群別
    AND ( ir_param.prod_div IS NOT NULL )       -- 商品区分入力
    THEN
      IF ( ir_param.item_div IS NULL )           -- 品目区分入力
      THEN
        OPEN  get_cur01;
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec;
        CLOSE get_cur01;
      ELSE
        OPEN  get_cur02;
        FETCH get_cur02 BULK COLLECT INTO ot_data_rec;
        CLOSE get_cur02;
      END IF;
    END IF;
--yutsuzuk add
*/
    OPEN  lc_ref FOR lv_select
                  || lv_porc_po
                  || lv_adji
                  || lv_group
-- v1.18 MOD START
--                  || lv_order   USING  lt_lkup_code
---- 2012/03/23 v1.17 Del Start
------ 2008/12/05 ADD START
----                                      ,lt_lkup_code
----                                      ,lt_lkup_code
----                                      ,lt_lkup_code
------ 2008/12/05 ADD END
---- 2012/03/23 v1.17 Del End
--                                      ,cv_zero
                  || lv_order   USING  cv_zero
-- v1.18 MOD END
-- 2012/03/23 v1.17 Mod Start
--                                      ,cv_zero
--                                      ,cv_zero
-- v1.18 MOD START
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_zero
-- v1.18 MOD END
-- 2012/03/23 v1.17 Mod End
                                      ,cv_porc
                                      ,gn_one
                                      ,ir_param.proc_from
                                      ,gc_char_yyyymm_format
                                      ,ir_param.proc_to
                                      ,gc_char_yyyymm_format
                                      ,cn_prod_class_id
                                      ,ir_param.prod_div
                                      ,cn_item_class_id
                                      ,gv_ja
                                      ,cn_crowd_code_id
                                      ,cn_acnt_crowd_id
                                      ,cv_po
-- 2008/12/04 v1.14 UPDATE START
--                                      ,cv_deliver
--                                      ,cv_return_to_vendor
-- 2008/12/04 v1.14 UPDATE END
-- 2008/11/13 v1.8 ADD START
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
-- v1.18 ADD START
                                      ,gv_xxcmn_ctr       -- 消費税率マスタ(LOOKUP表)
                                      ,gc_char_std_format -- 発注ヘッダ.納入日の日付書式
                                      ,gc_char_std_format -- 発注ヘッダ.納入日の日付書式
-- v1.18 ADD END
                                      ,cv_porc
                                      ,cv_rma
                                      ,cv_po
-- 2008/12/04 v1.14 UPDATE START
--                                      ,cv_deliver
--                                      ,cv_return_to_vendor
-- 2008/12/04 v1.14 UPDATE END
-- 2008/11/13 v1.8 ADD END
                                      ,cv_zero
-- 2012/03/23 v1.17 Mod Start
--                                      ,cv_zero
--                                      ,cv_zero
-- v1.18 MOD START
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
--                                      ,lt_lkup_code
--                                      ,cv_zero
--                                      ,lt_lkup_code
                                      ,cv_zero
                                      ,cv_zero
                                      ,cv_zero
                                      ,gc_char_std_format -- 発注ヘッダ.納入日の日付書式
-- v1.18 MOD END
-- 2012/03/23 v1.17 Mod End
                                      ,cv_adji
                                      ,cv_x201
                                      ,ir_param.proc_from
                                      ,gc_char_yyyymm_format
                                      ,ir_param.proc_to
                                      ,gc_char_yyyymm_format
                                      ,cn_prod_class_id
                                      ,ir_param.prod_div
                                      ,cn_item_class_id
                                      ,gv_ja
                                      ,cn_crowd_code_id
-- 2008/11/13 v1.8 UPDATE START
--                                      ,cn_acnt_crowd_id;
                                      ,cn_acnt_crowd_id
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
                                      ,gv_min_date
                                      ,gc_char_dt_format
                                      ,gv_max_date
                                      ,gc_char_dt_format
-- v1.18 ADD START
                                      ,gv_xxcmn_ctr       -- 消費税率マスタ(LOOKUP表)
-- v1.18 ADD END
                                      ,cv_adji
                                      ;
-- 2008/11/13 v1.8 UPDATE END
--
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    CLOSE lc_ref;
-- 2008/10/14 v1.6 UPDATE END
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF lc_ref%ISOPEN THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF lc_ref%ISOPEN THEN
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
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data_line
   * Description      : ＸＭＬデータ作成(明細)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data_line(
      ov_errbuf                    OUT VARCHAR2          -- ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,ov_retcode                   OUT VARCHAR2          -- ﾘﾀｰﾝ･ｺｰﾄﾞ
     ,ov_errmsg                    OUT VARCHAR2          -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
     ,ir_param                     IN  rec_param_data    -- ﾊﾟﾗﾒｰﾀ
     ,it_data_rec                  IN  rec_data_type_dtl -- 取得ﾚｺｰﾄﾞ
     ,in_i                         IN  NUMBER            -- 連番
     ,iot_xml_idx                  IN OUT NUMBER         -- ＸＭＬﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
     ,iot_xml_data_table           IN OUT XML_DATA       -- XMLﾃﾞｰﾀ
     ,on_sum_quantity              IN OUT NUMBER         -- 数量計
     ,on_sum_order_amount          IN OUT NUMBER         -- 仕入金額計
     ,on_sum_commission_price      IN OUT NUMBER         -- 口銭計
     ,on_sum_commission_tax_amount IN OUT NUMBER         -- 消費税計(口銭)
     ,on_sum_commission_amount     IN OUT NUMBER         -- 口銭金額
     ,on_sum_assess_amount         IN OUT NUMBER         -- 賦課金計
     ,on_sum_payment               IN OUT NUMBER         -- 支払計
     ,on_sum_payment_amount_tax    IN OUT NUMBER         -- 消費税計(支払)
     ,on_sum_payment_amount        IN OUT NUMBER         -- 支払金額計
     ,on_sum_standard_amount       IN OUT NUMBER         -- 標準金額計
     ,on_sum_difference_amount     IN OUT NUMBER         -- 差異計
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data_line' ; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_qty                   NUMBER; -- 数量
    ln_order_price           NUMBER; -- 仕入単価
    ln_order_amount          NUMBER; -- 仕入金額
    ln_commission_tax_amount NUMBER; -- 消費税等(口銭)
    ln_commission_amount     NUMBER; -- 口銭金額
    ln_payment               NUMBER; -- 支払
    ln_payment_amount_tax    NUMBER; -- 消費税等(支払)
    ln_payment_amount        NUMBER; -- 支払金額
    ln_standard_amount       NUMBER; -- 標準金額
    ln_difference_amount     NUMBER; -- 差異
-- v1.18 DEL START
--    ln_tax                   NUMBER; -- 消費税
-- v1.18 DEL END
--
  BEGIN
--
    -- =====================================================
    -- 明細データ出力
    -- =====================================================
    -- 明細クリア
    ln_qty                   := 0; -- 数量
    ln_order_price           := 0; -- 仕入単価
    ln_order_amount          := 0; -- 仕入金額
    ln_commission_tax_amount := 0; -- 消費税等(口銭)
    ln_commission_amount     := 0; -- 口銭金額
    ln_payment               := 0; -- 支払
    ln_payment_amount_tax    := 0; -- 消費税等(支払)
    ln_payment_amount        := 0; -- 支払金額
    ln_standard_amount       := 0; -- 標準金額
    ln_difference_amount     := 0; -- 差異
-- v1.18 DEL START
--    -- 消費税係数
--    ln_tax := TO_NUMBER(NVL(it_data_rec.c_tax,gn_zero)) / gn_100;
-- v1.18 DEL END
    -- -----------------------------------------------------
    -- 品目ＬＧ開始タグ出力
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'lg_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 品目Ｇ開始タグ出力
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'g_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- 品目区分コード
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_code' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.item_code;
    -- 品目区分名称
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_name' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value :=
      SUBSTRB(it_data_rec.item_name,gn_one,gn_20) ;
    -- 単位
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'uom_code' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.item_um;
    -- 数量
    ln_qty := it_data_rec.trans_qty;
    IF ( ln_qty IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'quantity' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_qty;
      on_sum_quantity := on_sum_quantity + ln_qty;
    END IF;
    -- 仕入単価
-- 2008/11/29 v1.10 UPDATE START
    /*IF ( it_data_rec.item_atr15 = gc_cost_st ) THEN
      -- 品目.原価管理区分 = 1:標準原価 (標準原価マスタより、実際単価)
      ln_order_price := it_data_rec.stnd_unit_price; -- 標準単価
    ELSE
      -- 品目.原価管理区分 = 0:実際原価
      IF ( it_data_rec.lot_ctl = gn_lot_yes ) THEN
        -- 品目.ロット管理 = 1:対象 (ロット別原価テーブルより、実際単価)
        ln_order_price := it_data_rec.purchases_price; -- 仕入単価(ロット)※加重平均
      ELSE
        -- 品目.ロット管理 = 0:対象外 (標準原価マスタより、実際単価)
        ln_order_price := it_data_rec.stnd_unit_price; -- 標準単価
      END IF;
    END IF;*/
    ln_order_price := it_data_rec.purchases_price; -- 仕入単価(ロット)※加重平均
-- 2008/11/29 v1.10 UPDATE END
    IF ( ln_order_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'order_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ROUND(ln_order_price,gn_2);
    END IF;
    -- 粉引後単価
    IF ( it_data_rec.powder_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'konahiki_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.powder_price;
    END IF;
-- 2008/11/29 v1.10 UPDATE START
    -- 仕入金額
    /*IF ( it_data_rec.item_atr15 = gc_cost_st ) THEN
      -- 品目.原価管理区分 = 1:標準原価 (標準原価マスタより、実際単価)
      ln_order_amount := ROUND(it_data_rec.j_amt); -- 標準単価 * 数量
    ELSE
      -- 品目.原価管理区分 = 0:実際原価
      IF ( it_data_rec.lot_ctl = gn_lot_yes ) THEN
        -- 品目.ロット管理 = 1:対象 (ロット別原価テーブルより、実際単価)
        ln_order_amount := ROUND(it_data_rec.s_amt); -- 仕入単価(ﾛｯﾄ) * 数量
      ELSE
        -- 品目.ロット管理 = 0:対象外 (標準原価マスタより、実際単価)
        ln_order_amount := ROUND(it_data_rec.j_amt); -- 標準単価 * 数量
      END IF;
    END IF;*/
    ln_order_amount := ROUND(it_data_rec.s_amt); -- 仕入単価(ﾛｯﾄ) * 数量
-- 2008/11/29 v1.10 UPDATE END
    IF ( ln_order_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'order_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_order_amount;
      on_sum_order_amount := on_sum_order_amount + ln_order_amount;
    END IF;
    -- 口銭
    IF ( it_data_rec.commission_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ROUND(it_data_rec.c_amt);
      on_sum_commission_price := on_sum_commission_price + ROUND(it_data_rec.c_amt);
    END IF;
    -- 消費税等(口銭)
-- 2008/12/05 v1.13 UPDATE START
--    ln_commission_tax_amount := ROUND(it_data_rec.c_amt * ln_tax);
    ln_commission_tax_amount := it_data_rec.commission_tax;
-- 2008/12/05 v1.13 UPDATE END
    IF ( ln_commission_tax_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_tax_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_commission_tax_amount;
      on_sum_commission_tax_amount :=
        on_sum_commission_tax_amount + ln_commission_tax_amount;
    END IF;
    -- 口銭金額
    ln_commission_amount := ROUND(it_data_rec.c_amt) + ln_commission_tax_amount;
    IF ( ln_commission_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'commission_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_commission_amount;
      on_sum_commission_amount := on_sum_commission_amount + ln_commission_amount;
    END IF;
    -- 賦課金
    IF ( it_data_rec.assessment IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'assess_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.assessment;
      on_sum_assess_amount := on_sum_assess_amount + it_data_rec.assessment;
    END IF;
    -- 支払
    ln_payment :=
      ln_order_amount - NVL(ROUND(it_data_rec.c_amt),gn_zero) - NVL(it_data_rec.assessment,gn_zero);
    IF ( ln_payment IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment;
      on_sum_payment := on_sum_payment + ln_payment;
    END IF;
    -- 消費税等(支払)
-- 2008/12/05 v1.13 UPDATE START
--    ln_payment_amount_tax := ROUND(ln_payment * ln_tax);
    ln_payment_amount_tax := it_data_rec.payment_tax;
-- 2008/12/05 v1.13 UPDATE END
    IF ( ln_payment_amount_tax IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment_amount_tax' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment_amount_tax;
      on_sum_payment_amount_tax :=
        on_sum_payment_amount_tax + ln_payment_amount_tax;
    END IF;
    -- 支払金額
-- 2008/12/05 v1.12 UPDATE START
--    ln_payment_amount := ln_payment + ln_payment_amount_tax;
    ln_payment_amount := NVL(ln_payment,gn_zero) + NVL(ln_payment_amount_tax,gn_zero);
-- 2008/12/05 v1.12 UPDATE END
    IF ( ln_payment_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'payment_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_payment_amount;
      on_sum_payment_amount := on_sum_payment_amount + ln_payment_amount;
    END IF;
    -- 標準単価
    IF ( it_data_rec.stnd_unit_price IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'standard_price' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := it_data_rec.stnd_unit_price;
    END IF;
    -- 標準金額
-- 2009/01/09 N.Yoshida Mod Start
--    ln_standard_amount := ROUND(it_data_rec.stnd_unit_price * ln_qty);
    ln_standard_amount := it_data_rec.j_amt;
-- 2009/01/09 N.Yoshida Mod End
    IF ( ln_standard_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'standard_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_standard_amount;
      on_sum_standard_amount := on_sum_standard_amount + ln_standard_amount;
    END IF;
    -- 差異
    ln_difference_amount := NVL(ln_order_amount,gn_zero) - NVL(ln_standard_amount,gn_zero);
    IF ( ln_difference_amount IS NOT NULL ) THEN
      iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
      iot_xml_data_table(iot_xml_idx).tag_name  := 'difference_amount' ;
      iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
      iot_xml_data_table(iot_xml_idx).tag_value := ln_difference_amount;
      on_sum_difference_amount := on_sum_difference_amount + ln_difference_amount;
    END IF;
    -- 品目連番
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := 'item_position' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'D' ;
    iot_xml_data_table(iot_xml_idx).tag_value := in_i;
    -- -----------------------------------------------------
    -- 品目Ｇ終了タグ出力
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/g_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 品目ＬＧ終了タグ出力
    -- -----------------------------------------------------
    iot_xml_idx := iot_xml_data_table.COUNT + 1 ;
    iot_xml_data_table(iot_xml_idx).tag_name  := '/lg_item' ;
    iot_xml_data_table(iot_xml_idx).tag_type  := 'T' ;
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
  END prc_create_xml_data_line ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
     ,ir_param          IN  rec_param_data    -- パラメータ
     ,it_data_rec       IN  tab_data_type_dtl -- 取得レコード群
     ,ot_xml_data_table OUT XML_DATA          -- XMLデータ
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
    lc_break_init      VARCHAR2(100) DEFAULT '*' ;    -- 初期値
    lc_break_null      VARCHAR2(100) DEFAULT '****' ; -- ＮＵＬＬ判定
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_result_post  xxcmn_rcv_pay_mst_porc_po_v.result_post%TYPE; -- 成績部署
    lv_item_div     xxcmn_lot_each_item_v.item_div%TYPE;       -- 品目区分
    lv_vendor_code  xxcmn_vendors2_v.segment1%TYPE;            -- 仕入先ID
    lv_crowd_code   xxcmn_lot_each_item_v.crowd_code%TYPE;     -- 詳群ｺｰﾄﾞor経理詳群ｺｰﾄﾞ
    lv_crowd_code_l xxcmn_lot_each_item_v.crowd_code%TYPE;     -- 大群ｺｰﾄﾞor経理大群ｺｰﾄﾞ
    lv_crowd_code_m xxcmn_lot_each_item_v.crowd_code%TYPE;     -- 中群ｺｰﾄﾞor経理中群ｺｰﾄﾞ
    lv_crowd_code_s xxcmn_lot_each_item_v.crowd_code%TYPE;     -- 小群ｺｰﾄﾞor経理小群ｺｰﾄﾞ
--
    -- 合計用
    ln_sum_quantity              NUMBER DEFAULT 0; -- 数量計
    ln_sum_order_amount          NUMBER DEFAULT 0; -- 仕入金額計
    ln_sum_commission_price      NUMBER DEFAULT 0; -- 口銭計
    ln_sum_commission_tax_amount NUMBER DEFAULT 0; -- 消費税計(口銭)
    ln_sum_commission_amount     NUMBER DEFAULT 0; -- 口銭金額
    ln_sum_assess_amount         NUMBER DEFAULT 0; -- 賦課金計
    ln_sum_payment               NUMBER DEFAULT 0; -- 支払計
    ln_sum_payment_amount_tax    NUMBER DEFAULT 0; -- 消費税計(支払)
    ln_sum_payment_amount        NUMBER DEFAULT 0; -- 支払金額計
    ln_sum_standard_amount       NUMBER DEFAULT 0; -- 標準原価計
    ln_sum_difference_amount     NUMBER DEFAULT 0; -- 差異計
--
    lt_xml_idx         NUMBER DEFAULT 0; -- ＸＭＬデータタグ表のインデックス
--
    ld_proc_from       DATE;             -- 処理年月(開始)
    ld_proc_to         DATE;             -- 処理年月(終了)
    ln_i               PLS_INTEGER;      -- IDX
--
    -- *** ローカル・例外処理 ***
    no_data_expt       EXCEPTION ;       -- 取得レコードなし
--
  BEGIN
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    -- -----------------------------------------------------
    -- ユーザーG開始タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ユーザーGデータタグ出力
    -- -----------------------------------------------------
    -- 帳票ＩＤ
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'report_id' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := gv_report_id ;
    -- 実施日
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'exec_date' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- 担当部署
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'charge_dept' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_user_dept,gn_one,gn_10) ;
    -- 担当者
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'agent' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_user_name,gn_one,gn_14) ;
    -- 処理年月(自)
    ld_proc_from := FND_DATE.STRING_TO_DATE(ir_param.proc_from,gc_char_yyyymm_format);
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'process_year_month_from' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value :=
      TO_CHAR(ld_proc_from,gc_char_yyyy_format) || gv_ja_year ||
      TO_CHAR(ld_proc_from,gc_char_mm_format) || gv_ja_month;
    -- 処理年月(至)
    ld_proc_to := FND_DATE.STRING_TO_DATE(ir_param.proc_to,gc_char_yyyymm_format);
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'process_year_month_to' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value :=
      TO_CHAR(ld_proc_to,gc_char_yyyy_format) || gv_ja_year ||
      TO_CHAR(ld_proc_to,gc_char_mm_format) || gv_ja_month;
    -- 商品区分コード
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'arti_div_code' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.prod_div;
    -- 商品区分名称
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'arti_div_name' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_prod_div_name,gn_one,gn_20);
    -- 品目区分コード
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.item_div;
    -- 品目区分名称
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_item_div_name,gn_one,gn_20);
    -- 群種別コード
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_div' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.crowd_type;
    -- 群種別名称
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_div_name' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_crowd_type,gn_one,gn_20);
    -- 成績部署コード
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.result_post;
    -- 成績部署名称
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_result_post_name,gn_one,gn_20);
    -- 仕入先コード
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_code_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := ir_param.party_code;
    -- 仕入先名称
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_name_head' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
    ot_xml_data_table(lt_xml_idx).tag_value := SUBSTRB(gv_party_code_name,gn_one,gn_20);
    -- -----------------------------------------------------
    -- ユーザーG終了タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/user_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- データLG開始タグ出力
    -- -----------------------------------------------------
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := 'data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    IF ( ir_param.result_post IS NULL ) THEN
      -- -----------------------------------------------------
      -- 成績部署LG開始タグ出力
      -- -----------------------------------------------------
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_result_post' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    END IF;
--
    -- 件数確認
    IF (it_data_rec.COUNT = gn_zero) THEN
      -- 0件帳票用XML出力
      prc_create_xml_data_zero(
        ov_errbuf          => lv_errbuf             -- ｴﾗｰ･ﾒｯｾｰｼﾞ
       ,ov_retcode         => lv_retcode            -- ﾘﾀｰﾝ･ｺｰﾄﾞ
       ,ov_errmsg          => lv_errmsg             -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
       ,ir_param           => ir_param              -- パラメータ
       ,iot_xml_idx        => lt_xml_idx            -- XMLﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
       ,iot_xml_data_table => ot_xml_data_table);   -- XMLﾃﾞｰﾀ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    ln_i := 1;
--
    <<main_data_loop>>
    WHILE ( ln_i <= it_data_rec.COUNT ) LOOP
--
      -- =====================================================
      -- 成績部署
      -- =====================================================
      lv_result_post := NVL(it_data_rec(ln_i).result_post,lc_break_null);
      IF ( ir_param.result_post IS NULL ) THEN
        -- 成績部署G開始タグ
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_result_post' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        -- 成績部署コード
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).result_post,gn_one,gn_15) ;
        -- 成績部署名称
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'performance_dept_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).location_name,gn_one,gn_10) ;
      END IF;
      -- 品目区分LG開始タグ出力
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_article_div' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
      <<result_post_loop>>
      WHILE
        (
             (ln_i <= it_data_rec.COUNT)
         AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
        ) LOOP -- 成績部署ループ
--
        -- =====================================================
        -- 品目区分
        -- =====================================================
        lv_item_div := NVL(it_data_rec(ln_i).item_div,lc_break_null);
        -- 品目区分G開始タグ出力
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'g_article_div' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        -- 品目区分コード
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_code' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(ln_i).item_div;
        -- 品目区分名称
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := 'item_div_name' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
        ot_xml_data_table(lt_xml_idx).tag_value :=
          SUBSTRB(it_data_rec(ln_i).item_div_name,gn_one,gn_10) ;
        IF ( ir_param.party_code IS NULL ) THEN
          -- 仕入先LG開始タグ出力
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_vendor' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF;
--
        <<item_div_loop>>
        WHILE
          (
               (ln_i          <= it_data_rec.COUNT)
           AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
           AND (lv_item_div    = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
          ) LOOP -- 品目区分ループ
--
          -- =====================================================
          -- 仕入先
          -- =====================================================
          lv_vendor_code := NVL(it_data_rec(ln_i).vendor_code,lc_break_null);
          IF ( ir_param.party_code IS NULL ) THEN
            -- 仕入先G開始タグ出力
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_vendor' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- 仕入先コード
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_code' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value := it_data_rec(ln_i).vendor_code;
            -- 仕入先名称
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'vendor_name' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value :=
              SUBSTRB(it_data_rec(ln_i).vendor_name,gn_one,gn_10) ;
          END IF;
          -- 大群LG開始タグ出力
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_l' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
          <<vendor_loop>>
          WHILE
            (
                 (ln_i <= it_data_rec.COUNT)
             AND (lv_result_post = NVL(it_data_rec(ln_i).result_post,lc_break_null))
             AND (lv_item_div    = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
             AND (lv_vendor_code = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
            ) LOOP -- 仕入先ループ
            -- -----------------------------------------------------
            -- 大群コード
            -- -----------------------------------------------------
            lv_crowd_code_l := SUBSTR(
              NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_one);
            -- 大群G開始タグ出力
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_l' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- 大群コード
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_lcode' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
            ot_xml_data_table(lt_xml_idx).tag_value :=
              SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_one);
            -- 中群LG開始タグ出力
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_m' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            <<crowd_l_loop>>
            WHILE
              (    (ln_i <= it_data_rec.COUNT)
               AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
               AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
               AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
               AND (lv_crowd_code_l =
                 SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_one))
              ) LOOP -- 大群ループ
              -- -----------------------------------------------------
              -- 中群コード
              -- -----------------------------------------------------
              lv_crowd_code_m := SUBSTR(
                NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_2);
              -- 中群G開始タグ出力
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_m' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
              -- 中群コード
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_mcode' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
              ot_xml_data_table(lt_xml_idx).tag_value :=
                SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_2);
              -- 小群LG開始タグ出力
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd_s' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
              <<crowd_m_loop>>
              WHILE
                (
                     (ln_i <= it_data_rec.COUNT)
                 AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                 AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                 AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                 AND (lv_crowd_code_m =
                   SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_2))
                ) LOOP -- 中群ループ
--
                -- -----------------------------------------------------
                -- 小群コード
                -- -----------------------------------------------------
                lv_crowd_code_s := SUBSTR(
                  NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_3);
                -- 小群Ｇ開始タグ出力
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd_s' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                -- 小群コード
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_scode' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
                ot_xml_data_table(lt_xml_idx).tag_value :=
                  SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_3);
                -- 詳群コードLG開始タグ
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := 'lg_crowd' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
                <<crowd_s_loop>>
                WHILE
                  (
                       (ln_i <= it_data_rec.COUNT)
                   AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                   AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                   AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                   AND (lv_crowd_code_s =
                     SUBSTR(NVL(it_data_rec(ln_i).crowd_code,lc_break_null),gn_one,gn_3))
                  ) LOOP -- 小群ループ
--
                  -- -----------------------------------------------------
                  -- 詳群コード
                  -- -----------------------------------------------------
                  lv_crowd_code   := NVL(it_data_rec(ln_i).crowd_code,lc_break_null);
                  -- 詳群コードG開始タグ
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := 'g_crowd' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                  -- 詳群コード
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := 'crowd_code' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'D' ;
                  ot_xml_data_table(lt_xml_idx).tag_value :=
                    SUBSTR(it_data_rec(ln_i).crowd_code,gn_one,gn_4);
--
                  <<crowd_loop>>
                  WHILE
                    (
                         (ln_i <= it_data_rec.COUNT)
                     AND (lv_result_post  = NVL(it_data_rec(ln_i).result_post,lc_break_null))
                     AND (lv_item_div     = NVL(it_data_rec(ln_i).item_div   ,lc_break_null))
                     AND (lv_vendor_code  = NVL(it_data_rec(ln_i).vendor_code,lc_break_null))
                     AND (lv_crowd_code   = NVL(it_data_rec(ln_i).crowd_code,lc_break_null))
                    ) LOOP -- 詳群ループ
                    -- =====================================================
                    -- 明細データ出力
                    -- =====================================================
                    prc_create_xml_data_line(
                      ov_errbuf          => lv_errbuf             -- ｴﾗｰ･ﾒｯｾｰｼﾞ
                     ,ov_retcode         => lv_retcode            -- ﾘﾀｰﾝ･ｺｰﾄﾞ
                     ,ov_errmsg          => lv_errmsg             -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
                     ,ir_param           => ir_param              -- ﾊﾟﾗﾒｰﾀ
                     ,it_data_rec        => it_data_rec(ln_i)     -- 取得ﾚｺｰﾄﾞ
                     ,in_i               => ln_i                  -- 連番
                     ,iot_xml_idx        => lt_xml_idx            -- XMLﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
                     ,iot_xml_data_table => ot_xml_data_table     -- XMLﾃﾞｰﾀ
                     ,on_sum_quantity           => ln_sum_quantity                 -- 数量計
                     ,on_sum_order_amount       => ln_sum_order_amount             -- 仕入金額計
                     ,on_sum_commission_price   => ln_sum_commission_price         -- 口銭計
                     ,on_sum_commission_tax_amount => ln_sum_commission_tax_amount -- 消費税計(口)
                     ,on_sum_commission_amount  => ln_sum_commission_amount        -- 口銭金額
                     ,on_sum_assess_amount      => ln_sum_assess_amount            -- 賦課金計
                     ,on_sum_payment            => ln_sum_payment                  -- 支払計
                     ,on_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- 消費税計(支)
                     ,on_sum_payment_amount     => ln_sum_payment_amount           -- 支払金額計
                     ,on_sum_standard_amount    => ln_sum_standard_amount          -- 標準金額計
                     ,on_sum_difference_amount  => ln_sum_difference_amount);      -- 差異計
                    IF (lv_retcode = gv_status_error) THEN
                      RAISE global_process_expt ;
                    END IF ;
                    ln_i := ln_i + 1; -- メインカウント
                  END LOOP crowd_loop; -- 詳群ループ
                  -- 詳群コードG終了タグ
                  lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                  ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd' ;
                  ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
                END LOOP crowd_s_loop; -- 小群ループ
                -- 詳群コードLG終了タグ
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
                -- 小群コードG終了タグ
                lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
                ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_s' ;
                ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
              END LOOP crowd_m_loop; -- 中群ループ
              -- 小群コードLG終了タグ
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_s' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
              -- 中群コードG終了タグ
              lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
              ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_m' ;
              ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
            END LOOP crowd_l_loop; -- 大群ループ
            -- 中群コードLG終了タグ
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_m' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
            -- 大群コードG終了タグ
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_crowd_l' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
          END LOOP vendor_loop; -- 仕入先ループ
          -- 大群コードLG終了タグ
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_crowd_l' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
          IF ( ir_param.party_code IS NULL ) THEN
            -- 仕入先G終了タグ
            lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
            ot_xml_data_table(lt_xml_idx).tag_name  := '/g_vendor' ;
            ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
          END IF;
--
        END LOOP item_div_loop; -- 品目区分ループ
--
        IF ( ir_param.party_code IS NULL ) THEN
          -- 仕入先LG終了タグ
          lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
          ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_vendor' ;
          ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
        END IF;
        IF (ir_param.result_post IS NOT NULL)
          AND (ln_i > it_data_rec.COUNT) THEN -- 最終データ
          -- 総合計出力
          prc_create_xml_data_sum(
            ov_errbuf          => lv_errbuf             -- ｴﾗｰ･ﾒｯｾｰｼﾞ
           ,ov_retcode         => lv_retcode            -- ﾘﾀｰﾝ･ｺｰﾄﾞ
           ,ov_errmsg          => lv_errmsg             -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
           ,iot_xml_idx        => lt_xml_idx            -- XMLﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
           ,iot_xml_data_table => ot_xml_data_table     -- XMLﾃﾞｰﾀ
           ,in_sum_quantity           => ln_sum_quantity                 -- 数量計
           ,in_sum_order_amount       => ln_sum_order_amount             -- 仕入金額計
           ,in_sum_commission_price   => ln_sum_commission_price         -- 口銭計
           ,in_sum_commission_tax_amount => ln_sum_commission_tax_amount -- 消費税計(口)
           ,in_sum_commission_amount  => ln_sum_commission_amount        -- 口銭金額
           ,in_sum_assess_amount      => ln_sum_assess_amount            -- 賦課金計
           ,in_sum_payment            => ln_sum_payment                  -- 支払計
           ,in_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- 消費税計(支)
           ,in_sum_payment_amount     => ln_sum_payment_amount           -- 支払金額計
           ,in_sum_standard_amount    => ln_sum_standard_amount          -- 標準金額計
           ,in_sum_difference_amount  => ln_sum_difference_amount);      -- 差異計
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
        END IF;
        -- 品目区分G終了タグ
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_article_div' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
      END LOOP result_post_loop; -- 成績部署ループ
      -- 品目区分LG終了タグ
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_article_div' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      IF ( ir_param.result_post IS NULL ) THEN
        IF (ln_i > it_data_rec.COUNT) THEN -- 最終データ
          -- 総合計出力
          prc_create_xml_data_sum(
            ov_errbuf          => lv_errbuf             -- ｴﾗｰ･ﾒｯｾｰｼﾞ
           ,ov_retcode         => lv_retcode            -- ﾘﾀｰﾝ･ｺｰﾄﾞ
           ,ov_errmsg          => lv_errmsg             -- ﾕｰｻﾞｰ･ｴﾗｰ･ﾒｯｾｰｼﾞ
           ,iot_xml_idx        => lt_xml_idx            -- XMLﾃﾞｰﾀﾀｸﾞ表のｲﾝﾃﾞｯｸｽ
           ,iot_xml_data_table => ot_xml_data_table     -- XMLﾃﾞｰﾀ
           ,in_sum_quantity           => ln_sum_quantity                 -- 数量計
           ,in_sum_order_amount       => ln_sum_order_amount             -- 仕入金額計
           ,in_sum_commission_price   => ln_sum_commission_price         -- 口銭計
           ,in_sum_commission_tax_amount => ln_sum_commission_tax_amount -- 消費税計(口)
           ,in_sum_commission_amount  => ln_sum_commission_amount        -- 口銭金額
           ,in_sum_assess_amount      => ln_sum_assess_amount            -- 賦課金計
           ,in_sum_payment            => ln_sum_payment                  -- 支払計
           ,in_sum_payment_amount_tax => ln_sum_payment_amount_tax       -- 消費税計(支)
           ,in_sum_payment_amount     => ln_sum_payment_amount           -- 支払金額計
           ,in_sum_standard_amount    => ln_sum_standard_amount          -- 標準金額計
           ,in_sum_difference_amount  => ln_sum_difference_amount);      -- 差異計
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
        END IF;
        -- 成績部署G終了タグ
        lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
        ot_xml_data_table(lt_xml_idx).tag_name  := '/g_result_post' ;
        ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    IF ( ir_param.result_post IS NULL ) THEN
      -- 成績部署LG終了タグ
      lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
      ot_xml_data_table(lt_xml_idx).tag_name  := '/lg_result_post' ;
      ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
    END IF;
--
    -- データLG終了タグ
    lt_xml_idx := ot_xml_data_table.COUNT + 1 ;
    ot_xml_data_table(lt_xml_idx).tag_name  := '/data_info' ;
    ot_xml_data_table(lt_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ユーザー定義例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : パラメータの取得
   ***********************************************************************************/
  PROCEDURE prc_set_param(
      ov_errbuf             OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_proc_from          IN  VARCHAR2       -- 01 : 処理年月(FROM)
     ,iv_proc_to            IN  VARCHAR2       -- 02 : 処理年月(TO)
     ,iv_prod_div           IN  VARCHAR2       -- 03 : 商品区分
     ,iv_item_div           IN  VARCHAR2       -- 04 : 品目区分
     ,iv_result_post        IN  VARCHAR2       -- 05 : 成績部署
     ,iv_party_code         IN  VARCHAR2       -- 06 : 仕入先
     ,iv_crowd_type         IN  VARCHAR2       -- 07 : 群種別
     ,iv_crowd_code         IN  VARCHAR2       -- 08 : 群コード
     ,iv_acnt_crowd_code    IN  VARCHAR2       -- 09 : 経理群コード
     ,or_param_rec          OUT rec_param_data -- 入力パラメータ群
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_set_param' ; -- プログラム名
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
    lv_work_date         VARCHAR2(30) ;         -- 変換用
--
    -- *** ローカル・例外処理 ***
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- パラメータ格納
--    or_param_rec.proc_from       := iv_proc_from;       -- 処理年月(FROM)
--    or_param_rec.proc_to         := iv_proc_to;         -- 処理年月(TO)
    -- 処理年月FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE(iv_proc_from, gc_char_yyyymm_format ),gc_char_yyyymm_format);
    IF ( lv_work_date IS NULL ) THEN
      or_param_rec.proc_from     := iv_proc_from;
    ELSE
      or_param_rec.proc_from     := lv_work_date;
    END IF;
    -- 処理年月TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE(iv_proc_to, gc_char_yyyymm_format ), gc_char_yyyymm_format );
    IF ( lv_work_date IS NULL ) THEN
      or_param_rec.proc_to     := iv_proc_to;
    ELSE
      or_param_rec.proc_to     := lv_work_date;
    END IF;
    or_param_rec.prod_div        := iv_prod_div;        -- 商品区分
    or_param_rec.item_div        := iv_item_div;        -- 品目区分
    or_param_rec.result_post     := iv_result_post;     -- 成績部署
    or_param_rec.party_code      := iv_party_code;      -- 仕入先
    or_param_rec.crowd_type      := iv_crowd_type;      -- 群種別
    or_param_rec.crowd_code      := iv_crowd_code;      -- 群コード
    or_param_rec.acnt_crowd_code := iv_acnt_crowd_code; -- 経理群コード
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
  END prc_set_param ;
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf             OUT VARCHAR2        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2        -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_proc_from          IN  VARCHAR2        --   01 : 処理年月(FROM)
     ,iv_proc_to            IN  VARCHAR2        --   02 : 処理年月(TO)
     ,iv_prod_div           IN  VARCHAR2        --   03 : 商品区分
     ,iv_item_div           IN  VARCHAR2        --   04 : 品目区分
     ,iv_result_post        IN  VARCHAR2        --   05 : 成績部署
     ,iv_party_code         IN  VARCHAR2        --   06 : 仕入先
     ,iv_crowd_type         IN  VARCHAR2        --   07 : 群種別
     ,iv_crowd_code         IN  VARCHAR2        --   08 : 群コード
     ,iv_acnt_crowd_code    IN  VARCHAR2        --   09 : 経理群コード
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
    lr_param_rec         rec_param_data ;          -- パラメータ受渡し用
--
    lv_xml_string        VARCHAR2(32000) ;
    ln_retcode           NUMBER ;
--
    ------------------------------
    -- ＸＭＬ用
    ------------------------------
    lt_main_data              tab_data_type_dtl; -- 取得レコード表
    lt_xml_data_table         XML_DATA;          -- ＸＭＬデータタグ表
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
    -- パラメータ格納
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_proc_from          => iv_proc_from        -- 01 : 処理年月(FROM)
       ,iv_proc_to            => iv_proc_to          -- 02 : 処理年月(TO)
       ,iv_prod_div           => iv_prod_div         -- 03 : 商品区分
       ,iv_item_div           => iv_item_div         -- 04 : 品目区分
       ,iv_result_post        => iv_result_post      -- 05 : 成績部署
       ,iv_party_code         => iv_party_code       -- 06 : 仕入先
       ,iv_crowd_type         => iv_crowd_type       -- 07 : 群種別
       ,iv_crowd_code         => iv_crowd_code       -- 08 : 群コード
       ,iv_acnt_crowd_code    => iv_acnt_crowd_code  -- 09 : 経理群コード
       ,or_param_rec          => lr_param_rec        -- 入力パラメータ群
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec       -- 入力パラメータ群
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data(
        ov_errbuf     => lv_errbuf      -- エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     -- リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param      => lr_param_rec   -- 入力パラメータ群
       ,ot_data_rec   => lt_main_data   -- 取得レコード群
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data(
        ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,it_data_rec       => lt_main_data       -- 取得レコード群
       ,ot_xml_data_table => lt_xml_data_table  -- XMLデータ
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    -- XML出力処理
    -- =====================================================
    prc_out_xml(
        ov_errbuf         => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
       ,ir_param          => lr_param_rec      -- 入力パラメータ群
       ,it_xml_data_table => lt_xml_data_table -- 取得レコード群
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF (lt_main_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
    END IF;
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
      errbuf                OUT   VARCHAR2, -- エラーメッセージ
      retcode               OUT   VARCHAR2, -- エラーコード
      iv_proc_from          IN    VARCHAR2, -- 01 : 処理年月(FROM)
      iv_proc_to            IN    VARCHAR2, -- 02 : 処理年月(TO)
      iv_prod_div           IN    VARCHAR2, -- 03 : 商品区分
      iv_item_div           IN    VARCHAR2, -- 04 : 品目区分
      iv_result_post        IN    VARCHAR2, -- 05 : 成績部署
      iv_party_code         IN    VARCHAR2, -- 06 : 仕入先
      iv_crowd_type         IN    VARCHAR2, -- 07 : 群種別
      iv_crowd_code         IN    VARCHAR2, -- 08 : 群コード
      iv_acnt_crowd_code    IN    VARCHAR2  -- 09 : 経理群コード
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
        ov_errbuf             => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_proc_from          => iv_proc_from       -- 01 : 処理年月(FROM)
       ,iv_proc_to            => iv_proc_to         -- 02 : 処理年月(TO)
       ,iv_prod_div           => iv_prod_div        -- 03 : 商品区分
       ,iv_item_div           => iv_item_div        -- 04 : 品目区分
       ,iv_result_post        => iv_result_post     -- 05 : 成績部署
       ,iv_party_code         => iv_party_code      -- 06 : 仕入先
       ,iv_crowd_type         => iv_crowd_type      -- 07 : 群種別
       ,iv_crowd_code         => iv_crowd_code      -- 08 : 群コード
       ,iv_acnt_crowd_code    => iv_acnt_crowd_code -- 09 : 経理群コード
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
END xxcmn770025c ;
/
