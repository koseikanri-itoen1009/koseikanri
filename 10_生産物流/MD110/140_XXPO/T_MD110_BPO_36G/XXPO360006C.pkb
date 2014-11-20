CREATE OR REPLACE PACKAGE BODY xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(body)
 * Description      : 仕入取引明細表
 * MD.050           : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 * MD.070           : 有償支給帳票Issue1.0(T_MD070_BPO_36G)
 * Version          : 1.32
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返す。(vendor_type)
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返す。(dept_code_type)
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  fnc_set_xml               FUNCTION  : ＸＭＬ用配列に格納する。
 *  prc_initialize            PROCEDURE : 前処理(G-2)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(G-3)
 *  prc_edit_data             PROCEDURE : 集計用データ編集(G-4-3)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(G-4-1)
 *  prc_create_xml_data2      PROCEDURE : 集計用ＸＭＬデータ作成(G-4-2)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/13    1.0   K.Kamiyoshi      新規作成
 *  2008/05/09    1.1   K.Kamiyoshi      不具合ID5-9対応
 *  2008/05/12    1.2   K.Kamiyoshi      不具合ID10対応
 *  2008/05/13    1.3   K.Kamiyoshi      不具合ID11対応
 *  2008/05/13    1.4   T.Endou         (外部ユーザー)発注なし返品時、セキュリティ要件の対応
 *  2008/05/22    1.5   T.Endou          通常受入時、発注納入明細.口銭区分、賦課金区分を使用する。
 *                                       斡旋者は外部結合とする。
 *                                       納入日の範囲指定は、すべてで受入返品アドオンを使用する。
 *  2008/05/23    1.6   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/24    1.7   Y.Majikina       仕入返品時の符号を修正
 *  2008/05/26    1.8   Y.Majikina       発注あり仕入先返品時、粉引率、粉引後単価、単価、
 *                                       口銭区分、口銭、預り口銭金額、賦課金区分、賦課金、
 *                                       賦課金額は、受入返品実績アドオンより取得する
 *  2008/05/28    1.9   Y.Majikina       リッチテキストの改ページセクションの変更による
 *                                       XML構造の修正
 *  2008/05/29    1.10  T.Endou          納入日の範囲指定は、すべて受入返品アドオンを使用する
 *                                       修正はしてあったが、帳票に表示する部分も修正する。
 *  2008/06/03    1.11  T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/11    1.12  T.Endou          発注なし仕入先返品の場合、返品アドオンの斡旋者IDを使用する
 *  2008/06/17    1.13  T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/24    1.14  T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/23    1.15  Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V→XXCMN_ITEM_CATEGORIES6_V変更
 *  2008/11/06    1.16  Y.Yamamoto       統合指摘#471対応、T_S_430対応
 *  2008/12/02    1.17  H.Marushita      本番障害#348対応
 *  2008/12/03    1.18  H.Marushita      本番障害#374対応
 *  2008/12/05    1.19  A.Shiina         本番障害#499,#506対応
 *  2008/12/07    1.20  N.Yoshida        本番障害#533対応
 *  2009/01/09    1.21  N.Yoshida        本番障害#984対応
 *  2009/03/30    1.22  A.Shiina         本番障害#1346対応
 *  2009/04/02    1.23  A.Shiina         本番障害#1370対応
 *  2009/04/03    1.24  A.Shiina         本番障害#1379対応(v1.22対応取消)
 *  2009/04/23    1.25  A.Shiina         本番障害#1429対応
 *  2009/05/18    1.26  T.Yoshimoto      本番障害#1478対応
 *  2009/06/02    1.27  T.Yoshimoto      本番障害#1515,1516対応
 *  2009/07/03    1.28  T.Yoshimoto      本番障害#1560対応
 *  2009/07/06    1.29  T.Yoshimoto      本番障害#1565対応
 *  2009/08/10    1.30  T.Yoshimoto      本番障害#1596対応
 *  2009/09/24    1.31  T.Yoshimoto      本番障害#1523対応
 *  2010/01/12    1.32  T.Yoshimoto      E_本稼動#892対応
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo360006c' ;   -- パッケージ名
  gv_print_name           CONSTANT VARCHAR2(20) := '仕入取引明細表' ;    -- 帳票名
  gv_lot_n_div            CONSTANT VARCHAR2(1) := '0';               -- ロット管理なし
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag                CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_lookup_type_tax_rate       CONSTANT VARCHAR2(100) := 'XXCMN_CONSUMPTION_TAX_RATE' ;
  gc_lookup_type_kousen         CONSTANT VARCHAR2(100) := 'XXPO_KOUSEN_TYPE' ;
  gc_lookup_type_fukakin        CONSTANT VARCHAR2(100) := 'XXPO_FUKAKIN_TYPE' ;
--
  ------------------------------
  -- 全角文字
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;      -- アプリケーション（XXCMN）
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;       -- アプリケーション（XXPO）
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '有償支給セキュリティVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := 'ユーザーID' ;
--
  ------------------------------
  -- 日付項目編集関連
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '年' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '月' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '日' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_md_format       CONSTANT VARCHAR2(30) := 'MM/DD' ;
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
  gv_out_assen           CONSTANT VARCHAR2(100) := '1' ;               --出力区分 斡旋者別
  gv_out_torihiki        CONSTANT VARCHAR2(100) := '2' ;               --出力区分 取引先別
  gv_out_syukei          CONSTANT VARCHAR2(100) := '3' ;               --出力区分 集計
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE vendor_type    IS TABLE OF xxcmn_vendors2_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE dept_code_type IS TABLE OF po_headers_all.attribute10%TYPE INDEX BY BINARY_INTEGER;
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      out_flg             VARCHAR2(1)    --出力区分    1:斡旋者別(大:部署 中:取引先 小:斡旋者)
                                         --            2:取引先別(大:部署 中:斡旋者 小:取引先)
     ,deliver_from        VARCHAR2(10)   --納入日FROM
     ,deliver_from_date   DATE           --納入日FROM(日付) - 1
     ,deliver_to          VARCHAR2(10)   --納入日TO
     ,deliver_to_date     DATE           --納入日TO(日付) + 1
     ,dept_code           dept_code_type -- 担当部署１～５
     ,vendor_code         vendor_type    -- 取引先１～５
     ,mediator_code       vendor_type    -- 斡旋者１～５
     ,po_num              po_headers_all.segment1%TYPE          -- 発注番号
     ,item_code           xxcmn_item_mst_v.item_no%TYPE         -- 品目コード
     ,security_flg        xxpo_security_supply_v.security_class%TYPE
                                                            -- セキュリティ区分
    ) ;
--
    gr_param_rec
             rec_param_data ;          -- パラメータ受渡し用
--
  -- 仕入取引明細表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
      txns_id         xxpo_rcv_and_rtn_txns.txns_id%TYPE                    --取引ID
     ,break_dtl       VARCHAR2(12)                                          --小ブレークキー
     ,break_mid       VARCHAR2(8)                                           --中ブレークキー
     ,dept_code       xxpo_rcv_and_rtn_txns.department_code%TYPE            --部署コード
     ,dept_name       xxcmn_locations_v.description%TYPE                    --部署名
     ,siire_no        xxcmn_vendors_v.segment1%TYPE                         --仕入先番号
     ,siire_sht       xxcmn_vendors_v.vendor_short_name%TYPE                --略称
     ,assen_no        xxcmn_vendors_v.segment1%TYPE                         --斡旋者仕入先番号
     ,assen_order     xxcmn_vendors_v.segment1%TYPE                         --斡旋者順序
     ,assen_sht       xxcmn_vendors_v.vendor_short_name%TYPE                --略称
     ,po_header_id    po_headers_all.po_header_id%TYPE                      --発注ID
     ,txns_date       VARCHAR2(5)                                           --取引日
     ,txns_type       xxpo_rcv_and_rtn_txns.txns_type%TYPE                  --取引タイプ
     ,po_no           xxpo_rcv_and_rtn_txns.source_document_number%TYPE     --元文書番号
     ,moto_line_no    xxpo_rcv_and_rtn_txns.source_document_line_num%TYPE   --元文書明細番号
     ,rcv_rtn_no      xxpo_rcv_and_rtn_txns.rcv_rtn_number%TYPE             --受入返品番号
     ,item_no         xxcmn_item_mst2_v.item_no%TYPE                        --品目
     ,item_name       xxcmn_item_mst2_v.item_name%TYPE                      --品目名称
     ,item_sht        xxcmn_item_mst2_v.item_short_name%TYPE                --品目略称
     ,futai_code      xxpo_rcv_and_rtn_txns.futai_code%TYPE                 --付帯
     ,kobiki_rate     xxpo_rcv_and_rtn_txns.kobiki_rate%TYPE                --粉引率
-- 2008/12/05 v1.19 UPDATE START
--     ,kobikigo        xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE --粉引後単価
     ,kobikigo        NUMBER                                                --粉引後単価
-- 2008/12/05 v1.19 UPDATE END
-- 2009/01/09 v1.21 UPDATE START
--     ,kousen_price    xxpo_rcv_and_rtn_txns.kousen_price%TYPE               --預り口銭金額
--     ,fukakin_price   xxpo_rcv_and_rtn_txns.fukakin_price%TYPE              --賦課金額
     ,kousen_price    NUMBER                                                --預り口銭金額
     ,fukakin_price   NUMBER                                                --賦課金額
     ,lot_no          ic_lots_mst.lot_no%TYPE                               --ロットno
--     ,quantity        xxpo_rcv_and_rtn_txns.quantity%TYPE           --受入返品数量
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
     ,conv_quantity   xxpo_rcv_and_rtn_txns.quantity%TYPE                   --受入返品数量(換算後)
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
     ,quantity        NUMBER                                                --受入返品数量
-- 2009/01/09 v1.21 UPDATE END
-- 2008/12/05 v1.19 UPDATE START
--     ,unit_price      xxpo_rcv_and_rtn_txns.unit_price%TYPE                 --単価
     ,unit_price      NUMBER                                                --単価
-- 2008/12/05 v1.19 UPDATE END
     ,kousen_type     xxpo_rcv_and_rtn_txns.kousen_type%TYPE                --口銭区分
     ,kousen_name     fnd_lookup_values.meaning%TYPE                        --口銭区分名
-- 2009/01/09 v1.21 UPDATE START
--     ,kousen          xxpo_rcv_and_rtn_txns.kousen_rate_or_unit_price%TYPE  --口銭
     ,kousen          NUMBER                                                --口銭
     ,rcv_rtn_uom     xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE                --受入返品単位
     ,fukakin_type    xxpo_rcv_and_rtn_txns.fukakin_type%TYPE               --賦課金区分
     ,fukakin_name    fnd_lookup_values.meaning%TYPE                        --賦課金区分名
--     ,fukakin         xxpo_rcv_and_rtn_txns.fukakin_rate_or_unit_price%TYPE --賦課金
     ,fukakin         NUMBER                                                --賦課金
-- 2009/01/09 v1.21 UPDATE END
     ,zeiritu         fnd_lookup_values.lookup_code%TYPE                    --税率
     ,order1          fnd_lookup_values.lookup_code%TYPE                    --表示順
     ,gaku            NUMBER                                                --金額(粉引後単価*受入返品数量)
     ,siire_tax       NUMBER                                                --仕入金額（消費税額）
     ,kousen_tax      NUMBER                                                --口銭（消費税額）
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  --ヘッダ用
  TYPE rec_header  IS RECORD(
      deliver_from_date   VARCHAR2(14)                                 --納入日FROM(YYYY年MM月DD日)
     ,deliver_to_date     VARCHAR2(14)                                 --納入日TO  (YYYY年MM月DD日)
     ,user_id             xxpo_per_all_people_f_v.person_id%TYPE       --担当者ID
     ,user_name           per_all_people_f.per_information18%TYPE      --担当者
     ,user_dept           xxcmn_locations_all.location_short_name%TYPE --部署
     ,user_vender         xxpo_per_all_people_f_v.attribute4%TYPE      --取引先コード
     ,user_vender_id      po_vendors.vendor_id%TYPE                    -- 仕入先ID
     ,user_vender_site    po_lines_all.attribute2%TYPE                 --取引先サイトコード
    ) ;
--
  gr_header_rec rec_header;
--
  --キー割れ用
  TYPE rec_keybreak  IS RECORD(
      lot       VARCHAR2(200)
     ,hutai     VARCHAR2(200)
     ,item      VARCHAR2(200)
     ,deliver   VARCHAR2(200)
     ,detail    VARCHAR2(200)
     ,middle    VARCHAR2(200)
     ,dept      VARCHAR2(200)
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
  gv_report_id              VARCHAR2(12) ;    -- 帳票ID
  gd_exec_date              DATE         ;    -- 実施日
--
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
  ------------------------------
  -- ルックアップ用
  ------------------------------
  gv_tax_class              fnd_lookup_values.lookup_code%TYPE ;
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
  gt_main_data2             tab_data_type_dtl ;       -- 取得レコード表
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
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
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(vendor_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_type IN vendor_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vendor_code_loop>>
    FOR ln_cnt IN 1..itbl_vendor_type.COUNT LOOP
      lv_in := lv_in || ',''' || itbl_vendor_type(ln_cnt) || '''';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in, gn_two));
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(dept_code_type)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_dept_code_type IN dept_code_type
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<dept_code_type_loop>>
    FOR ln_cnt IN 1..itbl_dept_code_type.COUNT LOOP
      lv_in := lv_in || ',''' || itbl_dept_code_type(ln_cnt) || '''';
    END LOOP dept_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_two));
--
  END fnc_get_in_statement;
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
  /**********************************************************************************
   * Procedure Name   : prc_set_xml
   * Description      : xml項目セット
   ***********************************************************************************/
  FUNCTION fnc_set_xml(
      ic_type              IN        CHAR       --   タグタイプ  T:タグ
                                                              -- D:データ
                                                              -- N:データ(NULLの場合タグを書かない)
                                                              -- Z:データ(NULLの場合0表示)
     ,iv_name              IN        VARCHAR2                --   タグ名
     ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   タグデータ(省略可
     ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   文字長（バイト）(省略可
     ,iv_index             IN        NUMBER    DEFAULT NULL  --   インデックス(省略可
    )  RETURN BOOLEAN
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_set_xml' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    ln_xml_idx NUMBER;
    ln_work    NUMBER;
--
  BEGIN
--
    IF (ic_type = gc_n) THEN
      --NULLの場合タグを書かない対応
      IF (iv_value IS NULL) THEN
        RETURN TRUE;
      END IF;
--
      BEGIN
        ln_work := TO_NUMBER(iv_value);
      EXCEPTION
        WHEN OTHERS THEN
          RETURN TRUE;
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
--
    RETURN TRUE;
  EXCEPTION
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RETURN FALSE;
  END fnc_set_xml ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_set_param
   * Description      : パラメータの取得
   ***********************************************************************************/
  PROCEDURE prc_set_param
    (
      ov_errbuf             OUT VARCHAR2       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode            OUT VARCHAR2       -- リターン・コード             --# 固定 #
     ,ov_errmsg             OUT VARCHAR2       -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_out_flg            IN  VARCHAR2       -- 出力区分
     ,iv_deliver_from       IN  VARCHAR2       -- 納入日FROM
     ,iv_deliver_to         IN  VARCHAR2       -- 納入日TO
     ,iv_vendor_code1       IN  VARCHAR2       -- 取引先１
     ,iv_vendor_code2       IN  VARCHAR2       -- 取引先２
     ,iv_vendor_code3       IN  VARCHAR2       -- 取引先３
     ,iv_vendor_code4       IN  VARCHAR2       -- 取引先４
     ,iv_vendor_code5       IN  VARCHAR2       -- 取引先５
     ,iv_mediator_code1     IN  VARCHAR2       -- 斡旋者１
     ,iv_mediator_code2     IN  VARCHAR2       -- 斡旋者２
     ,iv_mediator_code3     IN  VARCHAR2       -- 斡旋者３
     ,iv_mediator_code4     IN  VARCHAR2       -- 斡旋者４
     ,iv_mediator_code5     IN  VARCHAR2       -- 斡旋者５
     ,iv_dept_code1         IN  VARCHAR2       -- 担当部署１
     ,iv_dept_code2         IN  VARCHAR2       -- 担当部署２
     ,iv_dept_code3         IN  VARCHAR2       -- 担当部署３
     ,iv_dept_code4         IN  VARCHAR2       -- 担当部署４
     ,iv_dept_code5         IN  VARCHAR2       -- 担当部署５
     ,iv_po_num             IN  VARCHAR2       -- 発注番号
     ,iv_item_code          IN  VARCHAR2       -- 品目コード
     ,iv_security_flg       IN  VARCHAR2       -- セキュリティ区分
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
    ln_vendor_code       NUMBER DEFAULT 0; -- 取引先
    ln_mediator_code NUMBER DEFAULT 0; -- 斡旋者
    ln_dept_code         NUMBER DEFAULT 0; -- 担当部署
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
    -- 帳票出力値格納
    gv_report_id                   := 'XXPO360006T'  ;      -- 帳票ID
    gd_exec_date                   := SYSDATE        ;      -- 実施日
--
    -- 出力区分
    gr_param_rec.out_flg           := iv_out_flg     ;
    -- 納入日(FROM)
    gr_param_rec.deliver_from      := SUBSTR(TO_CHAR(iv_deliver_from), 1, 10) ;
    -- 納入日(TO)
    gr_param_rec.deliver_to        := SUBSTR(TO_CHAR(iv_deliver_to), 1, 10)   ;
    -- 発注番号
    gr_param_rec.po_num            := iv_po_num      ;
    -- 品目コード
    gr_param_rec.item_code         := iv_item_code   ;
    -- セキュリティ区分
    gr_param_rec.security_flg      := iv_security_flg;
--
    -- 取引先１
    IF TRIM(iv_vendor_code1) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- 取引先２
    IF TRIM(iv_vendor_code2) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- 取引先３
    IF TRIM(iv_vendor_code3) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- 取引先４
    IF TRIM(iv_vendor_code4) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- 取引先５
    IF TRIM(iv_vendor_code5) IS NOT NULL THEN
      ln_vendor_code := gr_param_rec.vendor_code.COUNT + 1;
      gr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- 斡旋者１
    IF TRIM(iv_mediator_code1) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code1;
    END IF;
    -- 斡旋者２
    IF TRIM(iv_mediator_code2) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code2;
    END IF;
    -- 斡旋者３
    IF TRIM(iv_mediator_code3) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code3;
    END IF;
    -- 斡旋者４
    IF TRIM(iv_mediator_code4) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code4;
    END IF;
    -- 斡旋者５
    IF TRIM(iv_mediator_code5) IS NOT NULL THEN
      ln_mediator_code := gr_param_rec.mediator_code.COUNT + 1;
      gr_param_rec.mediator_code(ln_mediator_code) := iv_mediator_code5;
    END IF;
--
    -- 担当部署１
    IF TRIM(iv_dept_code1) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code1;
    END IF;
    -- 担当部署２
    IF TRIM(iv_dept_code2) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code2;
    END IF;
    -- 担当部署３
    IF TRIM(iv_dept_code3) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code3;
    END IF;
    -- 担当部署４
    IF TRIM(iv_dept_code4) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code4;
    END IF;
    -- 担当部署５
    IF TRIM(iv_dept_code5) IS NOT NULL THEN
      ln_dept_code := gr_param_rec.dept_code.COUNT + 1;
      gr_param_rec.dept_code(ln_dept_code) := iv_dept_code5;
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
  END prc_set_param ;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(G-2)
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
    -- ====================================================
    -- 営業単位取得
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005'    ) ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 対象年月
    -- ====================================================
    -- 日付変換
    gr_header_rec.deliver_from_date :=   SUBSTR(gr_param_rec.deliver_from,1,4) || gc_jp_yy
                                      || SUBSTR(gr_param_rec.deliver_from,6,2) || gc_jp_mm
                                      || SUBSTR(gr_param_rec.deliver_from,9,2) || gc_jp_dd ;
    gr_header_rec.deliver_to_date   :=   SUBSTR(gr_param_rec.deliver_to,1,4) || gc_jp_yy
                                      || SUBSTR(gr_param_rec.deliver_to,6,2) || gc_jp_mm
                                      || SUBSTR(gr_param_rec.deliver_to,9,2) || gc_jp_dd ;
--
    --日付型設定
    gr_param_rec.deliver_from_date :=  FND_DATE.STRING_TO_DATE( gr_param_rec.deliver_from
                                                              , gc_char_d_format) - 1;
    gr_param_rec.deliver_to_date   :=  FND_DATE.STRING_TO_DATE( gr_param_rec.deliver_to
                                                              , gc_char_d_format) + 1;
--
    -- ====================================================
    -- 担当部署・担当者名
    -- ====================================================
    BEGIN
      gr_header_rec.user_id   := FND_GLOBAL.USER_ID;
      gr_header_rec.user_dept := xxcmn_common_pkg.get_user_dept(gr_header_rec.user_id);
      gr_header_rec.user_name := xxcmn_common_pkg.get_user_name(gr_header_rec.user_id);
    EXCEPTION
      WHEN OTHERS THEN
        ov_retcode := gv_status_warn ;
    END;
--
    -- ====================================================
    -- ログインユーザーの取引先取得
    -- ====================================================
    BEGIN
      SELECT xssv.vendor_code
            ,xssv.vendor_site_code
            ,vnd.vendor_id
        INTO gr_header_rec.user_vender
            ,gr_header_rec.user_vender_site
            ,gr_header_rec.user_vender_id
      FROM  xxpo_security_supply_v xssv
           ,xxcmn_vendors2_v       vnd
      WHERE xssv.vendor_code    = vnd.segment1 (+)
        AND xssv.user_id        = gr_header_rec.user_id
        AND xssv.security_class = gr_param_rec.security_flg
        AND gr_param_rec.deliver_from_date + 1  --上で-1しているため
            BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+)
        ;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key  ) ;
        RAISE get_value_expt ;
    END;
--
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
   * Description      : 明細データ取得(G-3)
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
    cv_item_class          CONSTANT VARCHAR2(  5) := '''5''';        -- 品目区分（製品）
    cv_crlf                CONSTANT VARCHAR2( 10) := CHR(13) || CHR(10); -- 改行コード
    cv_type_uke            CONSTANT VARCHAR2(  5) := '''1''';        --受入返品     引用符付
    cv_type_hen            CONSTANT VARCHAR2(  5) := '''2''';        --仕入返品     引用符付
    cv_type_nasi           CONSTANT VARCHAR2(  5) := '''3''';        --仕入なし返品 引用符付
    cv_approved            CONSTANT VARCHAR2( 10) := '''APPROVED'''; --承認済み     引用符付
    cv_kakutei             CONSTANT VARCHAR2(  5) := '''35''';       --金額確定     引用符付
    cv_torikesi            CONSTANT VARCHAR2(  5) := '''99''';       --取消         引用符付
    cv_type_tax_rate       CONSTANT VARCHAR2(100) := '''XXCMN_CONSUMPTION_TAX_RATE''' ;
                                                                     --消費税
    cv_type_kousen         CONSTANT VARCHAR2(100) := '''XXPO_KOUSEN_TYPE''' ;     --口銭区分
    cv_type_fukakin        CONSTANT VARCHAR2(100) := '''XXPO_FUKAKIN_TYPE''' ;    --賦課金区分
    cv_ja                  CONSTANT VARCHAR2(100) := '''JA''' ;                   --日本語
    cv_code_format         CONSTANT VARCHAR2(100) := '''9999''' ;        --グループ用フォーマット
    cv_zero                CONSTANT VARCHAR2(100) := '''0''' ;           --グループ用フォーマット
    cv_seq_gaibu           CONSTANT NUMBER        := '2' ;                 --セキュリティ 外部倉庫
    cv_sts_var_n           CONSTANT VARCHAR2(  1) := 'N' ;                 --'N' 取り消しフラグ用
    cv_sts_var_y           CONSTANT VARCHAR2(  1) := 'Y' ;                 --'Y' 金額確定フラグ用
--
    -- *** ローカル・変数 ***
    lv_date_from  VARCHAR2(10) ;
    lv_date_to    VARCHAR2(10) ;
    lv_dept       VARCHAR2(100) ;
    lv_assen      VARCHAR2(100) ;
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_group_by   VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_in         VARCHAR2(32000) ;
--
    -- *** ローカル・カーソル ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
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
    lv_date_from := TO_CHAR(gr_param_rec.deliver_from_date , gc_char_d_format);
    lv_date_to   := TO_CHAR(gr_param_rec.deliver_to_date   , gc_char_d_format);
    -- ----------------------------------------------------
    -- ＳＥＬＥＣＴ句生成
    -- ----------------------------------------------------
-- 2010/01/12 v1.32 T.Yoshimoto Mod Start E_本稼動#892
--    lv_dept := 'DECODE( xrart.txns_type ,' || cv_type_nasi
--      ||            ' , xrart.department_code, ph.attribute10)';
    lv_dept := 'xrart.department_code';
-- 2010/01/12 v1.32 T.Yoshimoto Mod End E_本稼動#892
--
    lv_assen := 'DECODE( xrart.txns_type , ' || cv_type_nasi
      ||             ' , xvv_assen.segment1 , xvv_med.segment1) ';
--
-- 2009/05/20 v1.26 T.Yoshimoto Del Start 本番#1478
/*
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      --入力パラメータ＝3.集計
      lv_select := 'SELECT '
        ||   ' NULL txns_id '
        || ' , ' || lv_dept || ' break_dtl '
        || ' , ' || lv_dept || ' break_mid '
        || ' , ' || lv_dept || ' dept_code '
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xlv.location_name '
        ||                           ' , xlv_p.location_name) dept_name '
        || ' , xvv_part.segment1                 siire_no '
        || ' , xvv_part.vendor_short_name        siire_sht '
        || ' , ' || lv_assen || ' assen_no '
        || ' , LPAD(NVL(' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        ||                                                                       ' assen_order '
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xvv_assen.vendor_short_name '
        ||                           ' , xvv_med.vendor_short_name) assen_sht '
        || ' , NULL po_header_id '
        || ' , NULL txns_date '
        || ' , NULL txns_type '
        || ' , NULL po_no '
        || ' , NULL moto_line_no '
        || ' , NULL rcv_rtn_no '
        || ' , NULL item_no '
        || ' , NULL item_name '
        || ' , NULL item_sht '
        || ' , NULL futai_code '
        || ' , NULL kobiki_rate '
        -- 2008/12/02 MOD START 
--        || ' , AVG(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi
--        ||                                  ' , xrart.kobki_converted_unit_price'
--        ||                                  ' , ' || cv_type_hen
--        ||                                  ' , xrart.kobki_converted_unit_price'
--        ||                                  ' , pll.attribute2), 0)) kobikigo'
        || ' , ROUND(SUM(ROUND(NVL(DECODE(xrart.txns_type , ' 
        ||                 cv_type_nasi || ' , xrart.kobki_converted_unit_price , ' 
-- 2008/12/05 v1.19 UPDATE START
--        ||                 cv_type_hen  || ' , xrart.kobki_converted_unit_price , pll.attribute2), 0) '
        ||                 cv_type_hen  || ' , xrart.kobki_converted_unit_price , pl.unit_price), 0) '
-- 2008/12/05 v1.19 UPDATE END
        || '          *  NVL(DECODE(xrart.txns_type , ' 
        ||                 cv_type_nasi ||' ,xrart.quantity * -1, ' 
        ||                 cv_type_hen  ||' ,xrart.quantity * -1, xrart.quantity) , 0),0) ) '
-- 2008/12/07 v1.20 UPDATE START
--        || '      /  SUM(NVL(DECODE(xrart.txns_type , ' 
        || '      /  DECODE(SUM(NVL(DECODE(xrart.txns_type , ' 
        ||                 cv_type_nasi ||' ,xrart.quantity * -1, '
        ||                 cv_type_hen  ||' ,xrart.quantity * -1, xrart.quantity) , 0)),0,1, '
        || '                SUM(NVL(DECODE(xrart.txns_type , ' 
        ||                 cv_type_nasi ||' ,xrart.quantity * -1, '
        ||                 cv_type_hen  ||' ,xrart.quantity * -1, xrart.quantity) , 0))),2) kobikigo '
-- 2008/12/07 v1.20 UPDATE END
        -- 2008/12/02 MOD END
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.kousen_price * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.kousen_price * -1'
        ||                                  ' , pll.attribute5) , 0)) kousen_price '
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.fukakin_price * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.fukakin_price * -1'
        ||                                  ' , pll.attribute8) , 0)) fukakin_price '
        || ' , NULL lot_no '
-- 2008/12/03 MOD START
--        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.quantity * -1'
--        ||                                  ' , ' || cv_type_hen  ||' ,xrart.quantity * -1'
--        ||                                  ' , xrart.quantity) , 0)) quantity '
        || ' , SUM(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.rcv_rtn_quantity * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.rcv_rtn_quantity * -1'
        ||                                  ' , xrart.rcv_rtn_quantity) , 0)) quantity '
-- 2008/12/03 MOD END
        || ' , NULL unit_price '
        || ' , NULL kousen_type '
        || ' , NULL kousen_name '
        || ' , NULL kousen '
        || ' , xrart.rcv_rtn_uom rcv_rtn_uom '
        || ' , NULL fukakin_type '
        || ' , NULL fukakin_name '
        || ' , NULL fukakin '
        || ' , MAX(NVL(DECODE(xrart.txns_type,' || cv_type_nasi || ',NVL(flv_u_tax.lookup_code,0) '
        ||                               ' , flv_p_tax.lookup_code) , 0))  zeiritu '
        || ' , NULL  order1 '
        -- 2008/12/02 ADD START 金額算出追加
        || ' , SUM(ROUND(NVL(DECODE(xrart.txns_type , ' 
        ||           cv_type_nasi || ' , xrart.kobki_converted_unit_price , ' 
-- 2008/12/05 v1.19 UPDATE START
--        ||           cv_type_hen  || ' , xrart.kobki_converted_unit_price , pll.attribute2), 0) '
        ||           cv_type_hen  || ' , xrart.kobki_converted_unit_price , pl.unit_price), 0) '
-- 2008/12/05 v1.19 UPDATE END
        || '    *  NVL(DECODE(xrart.txns_type , ' 
        ||           cv_type_nasi ||' ,xrart.quantity * -1,' 
        ||           cv_type_hen  ||' ,xrart.quantity * -1, xrart.quantity) , 0),0) ) gaku '
        -- 2008/12/02 ADD END
        -- 2008/12/02 ADD START 消費税計算追加
        || ' , SUM(ROUND(ROUND(NVL(DECODE(xrart.txns_type , ' 
        ||           cv_type_nasi || ' , xrart.kobki_converted_unit_price , ' 
-- 2008/12/05 v1.19 UPDATE START
--        ||           cv_type_hen  || ' , xrart.kobki_converted_unit_price , pll.attribute2), 0) '
        ||           cv_type_hen  || ' , xrart.kobki_converted_unit_price , pl.unit_price), 0) '
-- 2008/12/05 v1.19 UPDATE END
        || '    *  NVL(DECODE(xrart.txns_type , ' 
        ||           cv_type_nasi ||' ,xrart.quantity * -1,' 
        ||           cv_type_hen  ||' ,xrart.quantity * -1, xrart.quantity) , 0),0)  '
        || '    *  NVL(DECODE(xrart.txns_type,' || cv_type_nasi || ',NVL(flv_u_tax.lookup_code,0) '
        ||           ' , flv_p_tax.lookup_code) , 0) / 100 ,0) ) siire_tax '
        || ' , SUM(ROUND(NVL(DECODE(xrart.txns_type , ' || cv_type_nasi ||' ,xrart.kousen_price * -1'
        ||                                  ' , ' || cv_type_hen  ||' ,xrart.kousen_price * -1'
        ||                                  ' , pll.attribute5) , 0) '
        || '    *  NVL(DECODE(xrart.txns_type,' || cv_type_nasi || ',NVL(flv_u_tax.lookup_code,0) '
        ||           ' , flv_p_tax.lookup_code) , 0) / 100 ,0) ) kousen_tax '
        -- 2008/12/02 ADD END
        ;
    ELSE
*/
-- 2009/05/20 v1.26 T.Yoshimoto Del End 本番#1478
      lv_select := 'SELECT ';
-- 2009/06/02 v1.27 T.Yoshimoto Add Start 本番#1515
      --入力パラメータ＝3.集計の場合
      IF (gr_param_rec.out_flg = gv_out_syukei) THEN
        lv_select := lv_select
          ||   ' NULL txns_id '
          || ' , ' || lv_dept || ' break_dtl '
          || ' , ' || lv_dept || ' break_mid '
          ;
--
      --入力パラメータ＝3.集計以外の場合
      ELSE
-- 2009/06/02 v1.27 T.Yoshimoto Add End 本番#1515
        lv_select := lv_select
          ||   ' xrart.txns_id txns_id '
          ||  ', LPAD(NVL( '|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          || '|| LPAD(NVL(xvv_part.segment1 , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          || '|| LPAD(NVL( ' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
          ||                                                        ' break_dtl ' --小ブレイクキー
          ;
--
        IF (gr_param_rec.out_flg = gv_out_assen) THEN
          lv_select := lv_select
            || ',  LPAD(NVL( '|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
            || '|| LPAD(NVL( ' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
            ||                                                      ' break_mid ' --中ブレイクキー
            ;
        ELSE
          lv_select := lv_select
            || ',  LPAD(NVL('|| lv_dept ||  ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
            || '|| LPAD(NVL(xvv_part.segment1 , '|| cv_code_format||'), 4, '|| cv_zero ||')'
            ||                                                      ' break_mid ' --中ブレイクキー
            ;
        END IF;
--
-- 2009/06/02 v1.27 T.Yoshimoto Add Start 本番#1515
      END IF;
-- 2009/06/02 v1.27 T.Yoshimoto Add End 本番#1515
--
      --見出し
      lv_select := lv_select
        || ', ' || lv_dept ||                ' dept_code'                       --大キー部署コード
-- 2010/01/12 v1.32 T.Yoshimoto Mod Start E_本稼動#892
--        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xlv.location_name'
--        ||       ' , xlv_p.location_name)        dept_name '                    --部署名
        || ',xlv.location_name                 dept_name'                       --部署名
-- 2010/01/12 v1.32 T.Yoshimoto Mod End E_本稼動#892
        || ',xvv_part.segment1                 siire_no'                        --取引先仕入先番号
        || ',xvv_part.vendor_short_name        siire_sht'                       --略称
        || ' , ' || lv_assen || ' assen_no '                                    --斡旋者仕入先番号
        || ' , LPAD(NVL(' || lv_assen || ' , '|| cv_code_format||'), 4, '|| cv_zero ||')'
        ||                                                     ' assen_order '  --斡旋者順序
        || ' , DECODE( xrart.txns_type , ' || cv_type_nasi || ' , xvv_assen.vendor_short_name '
        ||                           ' , xvv_med.vendor_short_name) assen_sht '
        ;
      --明細
      lv_select := lv_select
        || ',ph.po_header_id po_header_id '                  --発注ID
        || ',TO_CHAR( xrart.txns_date ,''' || gc_char_md_format || ''') txns_date' --取引日
        || ',xrart.txns_type                   txns_type'    --取引タイプ
        || ',CASE '
        || ' WHEN xrart.txns_type = '|| cv_type_uke ||' THEN '
        ||   ' xrart.source_document_number '                -- 受入の場合,元文書明細番号
        || ' WHEN xrart.txns_type IN('|| cv_type_hen || ',' || cv_type_nasi|| ') THEN '
        ||   ' xrart.rcv_rtn_number '                        --仕入先返品の場合,受入返品番号
        || ' END  po_no '                                    --発注番号
        || ',xrart.source_document_line_num   moto_line_no ' --元文書明細番号
        || ',xrart.rcv_rtn_number             rcv_rtn_no '   --受入返品番号
        || ',ximv.item_no                     item_no '
        || ',ximv.item_name                   item_name '
        || ',ximv.item_short_name             item_sht '
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||',xrart.futai_code '
        ||       ' , pl.attribute3)           futai_code '   --付帯
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobiki_rate '
        ||                          ','|| cv_type_hen  ||', xrart.kobiki_rate '
        ||       ' , pll.attribute1)          kobiki_rate '  --粉引率
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobki_converted_unit_price '
        ||                          ','|| cv_type_hen  ||', xrart.kobki_converted_unit_price '
-- 2008/12/05 v1.19 UPDATE START
--        ||       ' , pll.attribute2)          kobikigo '     --粉引後単価
        ||       ' , pl.unit_price)          kobikigo '     --粉引後単価
-- 2008/12/05 v1.19 UPDATE END
        || ',DECODE( xrart.txns_type ,' || cv_type_nasi  || ', xrart.kousen_price * -1 '
        ||                          ',' || cv_type_hen   || ', xrart.kousen_price * -1 '
        ||       ' , pll.attribute5)          kousen_price ' --預り口銭金額
        || ',DECODE( xrart.txns_type ,' || cv_type_nasi  || ', xrart.fukakin_price * -1 '
        ||                          ',' || cv_type_hen   || ', xrart.fukakin_price * -1 '
        ||       ', pll.attribute8)           fukakin_price ' --賦課金額
        || ',DECODE(ximv.lot_ctl,'   || gv_lot_n_div || ',NULL,ilm.lot_no) AS lot_no '-- ロットNO
-- 2008/12/02 MOD START
--        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 '
--        || ',DECODE(xrart.txns_type,'  || cv_type_hen  || ', xrart.quantity * -1 '
--        || ', xrart.quantity))  quantity '  --受入返品数量
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 '
        || ',DECODE(xrart.txns_type,'  || cv_type_hen  || ', xrart.quantity * -1 '
        || ', xrart.quantity))  conv_quantity '     --受入返品数量(換算後)
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.rcv_rtn_quantity * -1 '
        || ',DECODE(xrart.txns_type,'  || cv_type_hen  || ', xrart.rcv_rtn_quantity * -1 '
        || ', xrart.rcv_rtn_quantity))  quantity '  --受入返品数量
-- 2008/12/02 MOD END
-- 2009/04/02 v1.23 UPDATE START
/*
-- 2008/12/05 v1.19 UPDATE START
--        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.unit_price '
--        ||                          ','|| cv_type_hen  || ', xrart.unit_price '
--        ||       ' , pl.attribute8)           unit_price '   --単価'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.kobki_converted_price '
        ||                          ','|| cv_type_hen  || ', xrart.kobki_converted_price '
        ||       ' , pl.unit_price)           unit_price '   --単価'
-- 2008/12/05 v1.19 UPDATE END
*/
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.unit_price '
        ||       ' , pl.attribute8)           unit_price '   --単価'
-- 2009/04/02 v1.23 UPDATE END
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_kosen.lookup_code '
        ||                          ','|| cv_type_hen  || ', flv_u_kosen.lookup_code '
-- 2009/05/18 v1.26 T.Yoshimoto Mod Start 本番#1478
--        ||       ' , flv_p_kosen.lookup_code) kousen_name '  --口銭区分
        ||       ' , flv_p_kosen.lookup_code) kousen_type '  --口銭区分
-- 2009/05/18 v1.26 T.Yoshimoto Mod End 本番#1478
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_kosen.meaning '
        ||                          ','|| cv_type_hen  || ', flv_u_kosen.meaning '
        ||       ' , flv_p_kosen.meaning)     kousen_name '  --口銭区分名
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.kousen_rate_or_unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.kousen_rate_or_unit_price '
        ||       ' , pll.attribute4)          kousen '       --口銭'
        || ',xrart.rcv_rtn_uom                 rcv_rtn_uom ' --受入返品単位'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_fuka.lookup_code '
        ||                          ','|| cv_type_hen  || ', flv_u_fuka.lookup_code '
-- 2009/05/18 v1.26 T.Yoshimoto Mod Start 本番#1478
--        ||       ' , flv_p_fuka.lookup_code)  fukakin_name ' --賦課金区分'
        ||       ' , flv_p_fuka.lookup_code)  fukakin_type ' --賦課金区分'
-- 2009/05/18 v1.26 T.Yoshimoto Mod End 本番#1478
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', flv_u_fuka.meaning '
        ||                          ','|| cv_type_hen  || ', flv_u_fuka.meaning '
        ||       ' , flv_p_fuka.meaning)      fukakin_name ' --賦課金区分名'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.fukakin_rate_or_unit_price '
        ||                          ','|| cv_type_hen  || ', xrart.fukakin_rate_or_unit_price '
        ||       ' , pll.attribute7)          fukakin '      --賦課金'
        || ',DECODE( xrart.txns_type ,'|| cv_type_nasi ||', NVL(flv_u_tax.lookup_code, 0) '
        ||       ' , NVL(flv_p_tax.lookup_code, 0))   zeiritu '      --税率'
        || ',DECODE( xic6.item_class_code '
        ||       ' , '|| cv_item_class || ', ilm.attribute1||ilm.attribute2 '
        ||       ' ,ilm.lot_no )              order1 '       --表示順'
        -- 2008/12/02 ADD START
        -- 受入返品数量×単価=金額
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596(四捨五入化)
-- 2009/7/3 v1.28 T.Yoshimoto Mod Start
        || ',ROUND(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 ,'
--        || ',TRUNC(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 ,'
-- 2009/7/3 v1.28 T.Yoshimoto Mod End
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596(四捨五入化)
        ||                                cv_type_hen  || ', xrart.quantity * -1  '
        ||                                                ', xrart.quantity)  *  '
        || ' DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobki_converted_unit_price '
        ||                          ','|| cv_type_hen  ||', xrart.kobki_converted_unit_price '
-- 2008/12/05 v1.19 UPDATE START
--        ||       ' , pll.attribute2),0) gaku '
        ||       ' , pl.unit_price),0) gaku '
-- 2008/12/05 v1.19 UPDATE END
        -- 消費税額計算
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596(四捨五入化)
-- 2009/7/3 v1.28 T.Yoshimoto Mod End
        || ',ROUND(ROUND(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 ,'
--        || ',ROUND(TRUNC(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.quantity * -1 ,'
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596(四捨五入化)
-- 2009/7/3 v1.28 T.Yoshimoto Mod End
        ||                                cv_type_hen  || ', xrart.quantity * -1  '
        ||                                                ', xrart.quantity)  *  '
        || ' DECODE( xrart.txns_type ,'|| cv_type_nasi ||', xrart.kobki_converted_unit_price '
        ||                          ','|| cv_type_hen  ||', xrart.kobki_converted_unit_price '
-- 2008/12/05 v1.19 UPDATE START
--        ||       ' , pll.attribute2),0)  * '
        ||       ' , pl.unit_price),0)  * '
-- 2008/12/05 v1.19 UPDATE END
        || ' DECODE( xrart.txns_type ,'|| cv_type_nasi ||', NVL(flv_u_tax.lookup_code, 0) '
        || '   , NVL(flv_p_tax.lookup_code, 0)) / 100,0)   siire_tax '
-- 2009/04/23 v1.25 UPDATE START
--        || ',ROUND(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.kousen_rate_or_unit_price '
--        ||                          ','|| cv_type_hen  || ', xrart.kousen_rate_or_unit_price '
        || ',ROUND(DECODE( xrart.txns_type ,'|| cv_type_nasi || ', xrart.kousen_price * -1'
        ||                          ','|| cv_type_hen  || ', xrart.kousen_price * -1'
-- 2009/04/23 v1.25 UPDATE END
        ||       ' , pll.attribute5) * '
        || ' DECODE( xrart.txns_type ,'|| cv_type_nasi ||', NVL(flv_u_tax.lookup_code, 0) '
        || '   , NVL(flv_p_tax.lookup_code, 0)) / 100,0)   kousen_tax '
        -- 2008/12/02 ADD END
        ;
-- 2009/05/26 v1.26 T.Yoshimoto Del Start 本番#1478
    --END IF;
-- 2009/05/26 v1.26 T.Yoshimoto Del End 本番#1478
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_from := ' FROM '
      || '    xxpo_rcv_and_rtn_txns xrart '                       --受入返品アドオン
      || 'LEFT JOIN ic_lots_mst ilm '                            --opmロットマスタ
      ||  ' ON (  ilm.lot_id = xrart.lot_id '
      ||    ' AND ilm.item_id = xrart.item_id ) '
      || 'INNER JOIN xxcmn_item_mst2_v ximv '                     --opm品目情報view
      ||  ' ON (  ximv.item_id = xrart.item_id '
      ||    ' AND ximv.start_date_active <= xrart.txns_date '
      ||    ' AND ximv.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN xxcmn_item_categories2_v gic '               --品目カテゴリ割当
      ||  ' ON (  gic.item_id  = ximv.item_id ) '
      || 'INNER JOIN xxcmn_item_categories6_v xic6 '              --品目カテゴリ割当6
      ||  ' ON (  xic6.item_id   = gic.item_id ) '
      || 'INNER JOIN (SELECT mcb.segment1  AS category_code '
      || ',  mcb.category_id AS category_id '
      || ',  mcst.category_set_id AS category_set_id '
      || ',  mcst.category_set_name '
      || '  FROM   mtl_category_sets_tl  mcst, '
      || '   mtl_category_sets_b   mcsb, '
      || '   mtl_categories_b      mcb '
      || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
      || '  AND   mcst.language         = ''' || gc_language_code || ''''
      || '  AND   mcsb.structure_id     = mcb.structure_id '
      || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') xgcv'
      ||  ' ON (  xgcv.category_set_id   = gic.category_set_id '
      ||    ' AND xgcv.category_id       = gic.category_id ) '
      || 'INNER JOIN xxcmn_locations2_v xlv '                     --事業所情報view
      ||  ' ON (  xlv.location_code = xrart.department_code '
      ||    ' AND xlv.start_date_active <= xrart.txns_date '
      ||    ' AND xlv.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN xxcmn_vendors2_v xvv_part '                  --仕入先情報(取引先)
      ||  ' ON (  xvv_part.vendor_id = xrart.vendor_id '
      ||    ' AND xvv_part.start_date_active <= xrart.txns_date '
      ||    ' AND xvv_part.end_date_active   >= xrart.txns_date ) '
      || 'LEFT JOIN xxcmn_vendors2_v xvv_assen '                  --仕入先情報(斡旋先)
      ||  ' ON (  xvv_assen.vendor_id = xrart.assen_vendor_id '
      ||    ' AND xvv_assen.start_date_active <= xrart.txns_date '
      ||    ' AND xvv_assen.end_date_active   >= xrart.txns_date ) '
      || 'INNER JOIN fnd_lookup_values flv_u_tax '                --クイックコード(消費税)
      ||  ' ON (  flv_u_tax.lookup_type = ' || cv_type_tax_rate
      ||    ' AND flv_u_tax.language = ' || cv_ja
      ||    ' AND flv_u_tax.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_tax.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN fnd_lookup_values flv_u_kosen '              --クイックコード(口銭区分)
      ||  ' ON (  flv_u_kosen.lookup_type = '||cv_type_kousen
      ||    ' AND flv_u_kosen.language = ' || cv_ja
      ||    ' AND flv_u_kosen.lookup_code = xrart.kousen_type  '
      ||    ' AND flv_u_kosen.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_kosen.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN fnd_lookup_values flv_u_fuka '               --クイックコード(賦課金区分)
      ||  ' ON (  flv_u_fuka.lookup_type = '|| cv_type_fukakin
      ||    ' AND flv_u_fuka.language = ' || cv_ja
      ||    ' AND flv_u_fuka.lookup_code = xrart.fukakin_type  '
      ||    ' AND flv_u_fuka.start_date_active <= xrart.txns_date '
      ||    ' AND NVL(flv_u_fuka.end_date_active, xrart.txns_date)  >= xrart.txns_date ) '
      || 'LEFT JOIN (          po_headers_all ph '               --発注ヘッダ
      || '          INNER JOIN xxpo_headers_all xpha '           --発注ヘッダ(アドオン)
      ||            ' ON (  xpha.po_header_number = ph.segment1 ) '
      || '          INNER JOIN po_lines_all pl '                 --発注明細
      ||            ' ON (  pl.po_header_id = ph.po_header_id ) '
-- 2010/01/12 v1.32 T.Yoshimoto Del Start E_本稼動#892
--      || '          INNER JOIN xxcmn_locations2_v xlv_p '        --事業所情報view
--      ||            ' ON (  xlv_p.location_code = ph.attribute10 '
--      ||              ' AND TO_CHAR(xlv_p.start_date_active,'''||gc_char_d_format||''')'
--      ||                  ' <= ph.attribute4 '
--      ||              ' AND TO_CHAR(xlv_p.end_date_active,  '''||gc_char_d_format||''')'
--      ||                  ' >= ph.attribute4 )'
-- 2010/01/12 v1.32 T.Yoshimoto Del End E_本稼動#892
      || '          INNER JOIN po_line_locations_all pll '       --納入明細
      ||            ' ON (  pll.po_line_id = pl.po_line_id ) '
      || '          LEFT JOIN xxcmn_vendors2_v xvv_med '        --仕入先情報(斡旋者)
      ||            ' ON (  xvv_med.vendor_id = ph.attribute3 '
      ||              ' AND TO_CHAR(xvv_med.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND TO_CHAR(xvv_med.end_date_active,  '''||gc_char_d_format||''')'
      ||                  ' >= ph.attribute4 ) '
      || '          INNER JOIN fnd_lookup_values flv_p_tax '     --クイックコード(消費税)
      ||            ' ON (  flv_p_tax.lookup_type = ' || cv_type_tax_rate
      ||              ' AND flv_p_tax.language = '|| cv_ja
      ||              ' AND TO_CHAR(flv_p_tax.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_tax.end_date_active, '''||gc_char_d_format||'''),'
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          LEFT JOIN fnd_lookup_values flv_p_kosen '   --クイックコード(口銭区分)
      ||            ' ON (  flv_p_kosen.lookup_type = '|| cv_type_kousen
      ||              ' AND flv_p_kosen.language = '|| cv_ja
      ||              ' AND flv_p_kosen.lookup_code = pll.attribute3 '
      ||              ' AND TO_CHAR(flv_p_kosen.start_date_active, '''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_kosen.end_date_active, '''||gc_char_d_format||'''), '
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          LEFT JOIN fnd_lookup_values flv_p_fuka '    --クイックコード(賦課金区分)
      ||            ' ON (  flv_p_fuka.lookup_type = '||cv_type_fukakin
      ||              ' AND flv_p_fuka.language = '|| cv_ja
      ||              ' AND flv_p_fuka.lookup_code = pll.attribute6 '
      ||              ' AND TO_CHAR(flv_p_tax.start_date_active,'''||gc_char_d_format||''')'
      ||                  ' <= ph.attribute4 '
      ||              ' AND NVL(TO_CHAR(flv_p_tax.end_date_active, '''||gc_char_d_format||'''), '
      ||                  ' ph.attribute4) >= ph.attribute4 )'
      || '          ) ' ----left joinの括り終了
      || '  ON (  xrart.source_document_number = ph.segment1 '
      ||    ' AND xrart.source_document_line_num = pl.line_num )'
      ;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_where := ' WHERE '
     || '     xrart.txns_date > FND_DATE.STRING_TO_DATE('''|| lv_date_from ||''''
     ||                          ', '''||gc_char_d_format||''')'
     || ' AND xrart.txns_date < FND_DATE.STRING_TO_DATE('''|| lv_date_to ||''''
     ||                                        ', '''||gc_char_d_format||''')'
     || ' AND ('
     ||        ' (    xrart.txns_type IN('|| cv_type_hen ||',' || cv_type_nasi|| ')'
     ||        '  AND xrart.quantity > 0 '
     ||        ' )'
     ||        ' OR '
     ||        ' (xrart.txns_type NOT IN('|| cv_type_hen ||',' || cv_type_nasi|| '))'
     ||     ' ) '
-- 2009/04/03 v1.24 DELETE START
/*
-- 2009/03/30 v1.22 ADD START
     || ' AND ph.org_id = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.22 ADD END
*/
-- 2009/04/03 v1.24 DELETE END
     ;
--
      lv_where := lv_where
        || ' AND DECODE(ph.po_header_id, NULL, ''' || gn_sales_class || ''',ph.org_id)'
        ||     ' = '''|| gn_sales_class || ''''
-- 2009/09/24 v1.31 T.Yoshimoto Del Start 本番#1523
        --|| ' AND DECODE(ph.po_header_id, NULL, ' || cv_approved || ' , ph.authorization_status) '
        --||     ' = ' || cv_approved
-- 2009/09/24 v1.31 T.Yoshimoto Del End 本番#1523
        || ' AND DECODE(ph.po_header_id, NULL, ' || cv_kakutei || ', ph.attribute1)'
        ||     ' >= ' || cv_kakutei
        || ' AND DECODE(ph.po_header_id, NULL, '|| cv_kakutei ||', ph.attribute1)'
        ||     ' <  ' || cv_torikesi
        || ' AND DECODE(ph.po_header_id, NULL, '''|| cv_sts_var_n ||''', pl.cancel_flag)'
        ||     ' =  ''' || cv_sts_var_n || ''''      -- 取消フラグ
        || ' AND DECODE(ph.po_header_id, NULL, '''|| cv_sts_var_y ||''', pl.attribute14)'
        ||     ' =  ''' || cv_sts_var_y || ''''      -- 金額確定フラグ
       ;
--
    --担当部署
    IF (gr_param_rec.dept_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_where := lv_where
        || '     AND ' || lv_dept || ' = ''' || gr_param_rec.dept_code(gn_one) || '''';
    ELSIF (gr_param_rec.dept_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(gr_param_rec.dept_code);
      lv_where := lv_where
        || '     AND ' || lv_dept || ' IN(' || lv_in || ')';
    END IF;
--
    --取引先
    IF (gr_param_rec.vendor_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_where := lv_where
        || '     AND xvv_part.segment1 = ''' || gr_param_rec.vendor_code(gn_one) || '''';
    ELSIF (gr_param_rec.vendor_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(gr_param_rec.vendor_code);
      lv_where := lv_where
        || '     AND xvv_part.segment1 IN(' || lv_in || ') ';
    END IF;
--
    --斡旋者
    IF (gr_param_rec.mediator_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_where := lv_where
        || '     AND ' || lv_assen || ' = ''' || gr_param_rec.mediator_code(gn_one) || '''';
    ELSIF (gr_param_rec.mediator_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in := fnc_get_in_statement(gr_param_rec.mediator_code);
      lv_where := lv_where
        || '     AND ' || lv_assen || ' IN(' || lv_in || ') ';
    END IF;
--
    --発注番号
    IF(gr_param_rec.po_num IS NOT NULL) THEN
      lv_where := lv_where
        || ' AND ph.segment1 = '''|| gr_param_rec.po_num ||''''
        ;
    END IF;
--
    --品目
    IF(gr_param_rec.item_code IS NOT NULL) THEN
      lv_where := lv_where
        || ' AND ximv.item_no = '''|| gr_param_rec.item_code ||''''
        ;
    END IF;
--
    --セキュリティ
    IF (gr_param_rec.security_flg = cv_seq_gaibu) THEN
      lv_where := lv_where
        || ' AND (((DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.assen_vendor_id '
        || '   , ph.attribute3) = '''|| gr_header_rec.user_vender_id ||'''';--1.
--
      IF (gr_header_rec.user_vender_id IS NULL) THEN
        -- 仕入先IDなし
        lv_where := lv_where
          || '      OR (( '
          || '            DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.vendor_id '
          || '              , ph.vendor_id) IS NULL)))';
      ELSE
        -- 仕入先IDあり
        lv_where := lv_where
          || '      OR (( '
          || '            DECODE( xrart.txns_type  , '|| cv_type_nasi ||', xrart.vendor_id '
          || '              , ph.vendor_id) = ' || gr_header_rec.user_vender_id || ')))';
      END IF;                                                                  --2.
--
      IF (gr_header_rec.user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
          ||      '  AND ((xrart.txns_type IN( '|| cv_type_uke ||','|| cv_type_hen ||'))'
          ||      '    AND  NOT EXISTS(SELECT po_line_id '
          ||                         ' FROM   po_lines_all pl_sub '
          ||                         ' WHERE  pl_sub.po_header_id = ph.po_header_id '
          ||                         ' AND  NVL(pl_sub.attribute2,''*'') '
          ||                            ' <> '''|| gr_header_rec.user_vender_site ||''''
          ||                        ' )) '
          ||      '  OR ((xrart.txns_type = '|| cv_type_nasi ||')'
          ||      '    AND  NOT EXISTS(SELECT xrart_sub.factory_code '
          ||                         ' FROM   xxpo_rcv_and_rtn_txns xrart_sub '
          ||                         ' WHERE  xrart_sub.rcv_rtn_number = xrart.rcv_rtn_number '
          ||                         ' AND  NVL(xrart_sub.factory_code,''*'') '
          ||                            ' <> '''|| gr_header_rec.user_vender_site ||''''
          ||                        ' )) '
          ;
      END IF;
      lv_where := lv_where
        ||        ' )'                                                         --2.の閉じ
        ||     ' )'                                                            --1.の閉じ
        ;
    END IF;
--
-- 2009/05/20 v1.26 T.Yoshimoto Del Start 本番#1478
/*
    -- ----------------------------------------------------
    -- ＧＲＯＵＰ  ＢＹ句生成
    -- ----------------------------------------------------
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      lv_group_by := ' GROUP BY '
        ||   ' DECODE( xrart.txns_type ,' || cv_type_nasi
        ||                            ', xrart.department_code , ph.attribute10) '
        || ', DECODE( xrart.txns_type , ' || cv_type_nasi
        ||                           ' , xlv.location_name  , xlv_p.location_name)'
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi
        ||                            ', xlv.description       , xlv_p.description) '
        || ' , xvv_part.segment1 '
        || ' , xvv_part.vendor_short_name '
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi || ','
        || '     xvv_assen.segment1,xvv_med.segment1) '
        || ' , DECODE( xrart.txns_type ,' || cv_type_nasi || ',xvv_assen.vendor_short_name,'
        || '     xvv_med.vendor_short_name) '
        || ' , xrart.rcv_rtn_uom '
        ;
    END IF;
*/
-- 2009/05/20 v1.26 T.Yoshimoto Del End 本番#1478
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY dept_code';
    IF (gr_param_rec.out_flg = gv_out_syukei) THEN
      lv_order_by := lv_order_by || ' , siire_no '   --取引先コード
                                 || ' , assen_order '     --斡旋者コード(Nullを先頭にする）
      ;
    ELSE
      IF (gr_param_rec.out_flg = gv_out_assen) THEN
        lv_order_by := lv_order_by || ' , assen_order '  --斡旋者コード
                                   || ' , xvv_part.segment1' --取引先コード
        ;
      ELSE
        lv_order_by := lv_order_by || ' , xvv_part.segment1' --取引先コード
                                   || ' , assen_order '  --斡旋者コード
        ;
      END IF;
      lv_order_by := lv_order_by || ' , txns_date'           -- 納入日
                                 || ' , po_no'               -- 発注番号
                                 || ' , item_no'             -- 品目コード
                                 || ' , futai_code'          -- 付帯コード
                                 || ' , order1'              -- 表示順序１
      ;
    END IF;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_group_by || lv_order_by ;
--    FND_FILE.PUT_LINE(FND_FILE.LOG,lv_sql) ;
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
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
  /**********************************************************************************
   * Procedure Name   : prc_edit_data
   * Description      : 集計用データ編集(G-4-3)
   ***********************************************************************************/
  PROCEDURE prc_edit_data(
      it_data_rec   IN  tab_data_type_dtl         --    編集前レコード群
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  --    編集後レコード群
     ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_edit_data'; -- プログラム名
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
    ln_count      NUMBER DEFAULT 1;
    ln_loop_index NUMBER DEFAULT 0;
--
    lv_dept_code     VARCHAR2(4);
    lv_assen_no      VARCHAR2(4);
    lv_siire_no      VARCHAR2(4);
    lv_rcv_rtn_uom   VARCHAR2(4);
--
    -- 金額計算用
    ln_siire                NUMBER DEFAULT 0;         -- 仕入金額
    ln_kousen               NUMBER DEFAULT 0;         -- 口銭金額
    ln_kobiki_gaku          NUMBER DEFAULT 0;         -- 粉引額
    ln_fuka                 NUMBER DEFAULT 0;         -- 賦課金額
--
    ln_sum_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_conv_qty         NUMBER DEFAULT 0;         -- 入庫総数(換算後)
    ln_kobikigo_tanka       NUMBER DEFAULT 0;         -- 粉引後単価
    ln_sum_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_fuka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    --  ブレイク用変数初期化
    -- ==========================
    lv_dept_code   := it_data_rec(1).dept_code;               -- 部署コード
    lv_assen_no    := NVL(it_data_rec(1).assen_no, 'NULL');   -- 斡旋者コード
    lv_siire_no    := it_data_rec(1).siire_no;                -- 仕入先コード
    lv_rcv_rtn_uom := it_data_rec(1).rcv_rtn_uom;             -- 単位
--
    <<main_data_loop>>
    FOR ln_loop_index IN 1..it_data_rec.COUNT LOOP
--
      -- ==========================
      --  レコードをブレイク
      -- ==========================
      -- 部署コード/仕入先/斡旋者/単位が変更した場合
      IF ( ( lv_dept_code <> it_data_rec(ln_loop_index).dept_code )
        OR ( lv_assen_no <> NVL(it_data_rec(ln_loop_index).assen_no, 'NULL') )
        OR ( lv_siire_no <> it_data_rec(ln_loop_index).siire_no )
        OR ( lv_rcv_rtn_uom <> it_data_rec(ln_loop_index).rcv_rtn_uom) ) THEN
--
-- 2009/6/2 v1.27 T.Yoshimoto Add Start 本番#1516
        IF ( ln_sum_conv_qty = 0 ) THEN
          --単価
          ln_kobikigo_tanka   := 0;
        ELSE
-- 2009/6/2 v1.27 T.Yoshimoto Add End 本番#1516
          --単価
          ln_kobikigo_tanka   := ROUND(( ln_sum_siire/ln_sum_conv_qty ), 2);
-- 2009/6/2 v1.27 T.Yoshimoto Add Start 本番#1516
        END IF;
-- 2009/6/2 v1.27 T.Yoshimoto Add End 本番#1516
--
        --差引金額
        ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
-- 2009/07/06 v1.29 T.Yoshimoto Del Start 本番#1565
/*
        --消費税(仕入金額)
        ln_sum_tax_siire    := ROUND(NVL(ln_sum_siire, 0) * NVL(it_data_rec(ln_loop_index-1).zeiritu , 0) / 100 ,0);
        --消費税(口銭金額)
        ln_sum_tax_kousen   := ROUND(NVL(ln_sum_kosen, 0) * NVL(it_data_rec(ln_loop_index-1).zeiritu , 0) / 100 ,0);
*/
-- 2009/07/06 v1.29 T.Yoshimoto Del End 本番#1565
--
        --消費税(差引金額)
        ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
        --純仕入金額
        ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
        --純口銭金額
        ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
        --純差引金額
        ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
        -- ==========================
        --  編集後レコードとして格納
        -- ==========================
        ot_data_rec(ln_count).txns_id       := NULL;                                      --取引ID
        ot_data_rec(ln_count).break_dtl     := it_data_rec(ln_loop_index-1).break_dtl;    --小ブレークキー
        ot_data_rec(ln_count).break_mid     := it_data_rec(ln_loop_index-1).break_mid;    --中ブレークキー
        ot_data_rec(ln_count).dept_code     := it_data_rec(ln_loop_index-1).dept_code;    --部署コード
        ot_data_rec(ln_count).dept_name     := it_data_rec(ln_loop_index-1).dept_name;    --部署名
        ot_data_rec(ln_count).siire_no      := it_data_rec(ln_loop_index-1).siire_no;     --仕入先番号
        ot_data_rec(ln_count).siire_sht     := it_data_rec(ln_loop_index-1).siire_sht;    --略称
        ot_data_rec(ln_count).assen_no      := it_data_rec(ln_loop_index-1).assen_no;     --斡旋者仕入先番号
        ot_data_rec(ln_count).assen_order   := it_data_rec(ln_loop_index-1).assen_order;  --斡旋者順序
        ot_data_rec(ln_count).assen_sht     := it_data_rec(ln_loop_index-1).assen_sht;    --略称
        ot_data_rec(ln_count).po_header_id  := NULL;                                      --発注ID
        ot_data_rec(ln_count).txns_date     := NULL;                                      --取引日
        ot_data_rec(ln_count).txns_type     := NULL;                                      --取引タイプ
        ot_data_rec(ln_count).po_no         := NULL;                                      --元文書番号
        ot_data_rec(ln_count).moto_line_no  := NULL;                                      --元文書明細番号
        ot_data_rec(ln_count).rcv_rtn_no    := NULL;                                      --受入返品番号
        ot_data_rec(ln_count).item_no       := NULL;                                      --品目
        ot_data_rec(ln_count).item_name     := NULL;                                      --品目名称
        ot_data_rec(ln_count).item_sht      := NULL;                                      --品目略称
        ot_data_rec(ln_count).futai_code    := NULL;                                      --付帯
        ot_data_rec(ln_count).kobiki_rate   := NULL;                                      --粉引率
        ot_data_rec(ln_count).kobikigo      := ln_kobikigo_tanka;                         --粉引後単価
        ot_data_rec(ln_count).kousen_price  := ln_sum_kosen;                              --預り口銭金額
        ot_data_rec(ln_count).fukakin_price := ln_sum_fuka;                               --賦課金額
        ot_data_rec(ln_count).lot_no        := NULL;                                      --ロットno
        ot_data_rec(ln_count).quantity      := ln_sum_qty;                                --受入返品数量
        ot_data_rec(ln_count).unit_price    := NULL;                                      --単価
        ot_data_rec(ln_count).kousen_type   := NULL;                                      --口銭区分
        ot_data_rec(ln_count).kousen_name   := NULL;                                      --口銭区分名
        ot_data_rec(ln_count).kousen        := NULL;                                      --口銭
        ot_data_rec(ln_count).rcv_rtn_uom   := it_data_rec(ln_loop_index-1).rcv_rtn_uom;  --受入返品単位
        ot_data_rec(ln_count).fukakin_type  := NULL;                                      --賦課金区分
        ot_data_rec(ln_count).fukakin_name  := NULL;                                      --賦課金区分名
        ot_data_rec(ln_count).fukakin       := NULL;                                      --賦課金
        ot_data_rec(ln_count).zeiritu       := it_data_rec(ln_loop_index-1).zeiritu;      --税率
        ot_data_rec(ln_count).order1        := NULL;                                      --表示順
        ot_data_rec(ln_count).gaku          := ln_sum_siire;                              --金額(粉引後単価*受入返品数量)
        ot_data_rec(ln_count).siire_tax     := ln_sum_tax_siire;                          --仕入金額（消費税額）
        ot_data_rec(ln_count).kousen_tax    := ln_sum_tax_kousen;                         --口銭（消費税額）
--
        -- ブレイク用変数へ代入
        lv_dept_code   := it_data_rec(ln_loop_index).dept_code;
        lv_assen_no    := NVL(it_data_rec(ln_loop_index).assen_no, 'NULL');
        lv_siire_no    := it_data_rec(ln_loop_index).siire_no;
        lv_rcv_rtn_uom := it_data_rec(ln_loop_index).rcv_rtn_uom;
--
        -- 金額計算用変数の初期化
        ln_siire             := 0;  -- 仕入金額
        ln_kousen            := 0;  -- 口銭金額
        ln_kobiki_gaku       := 0;  -- 粉引額
        ln_fuka              := 0;  -- 賦課金額
        ln_sum_qty           := 0;  -- 入庫総数
        ln_sum_conv_qty      := 0;  -- 入庫総数(換算後)
        ln_kobikigo_tanka    := 0;  -- 粉引後単価
        ln_sum_siire         := 0;  -- 仕入金額
        ln_sum_kosen         := 0;  -- 口銭金額
        ln_sum_fuka          := 0;  -- 賦課金額
        ln_sum_sasihiki      := 0;  -- 差引金額
        ln_sum_tax_siire     := 0;  -- 消費税(仕入金額)
        ln_sum_tax_kousen    := 0;  -- 消費税(口銭金額)
        ln_sum_tax_sasihiki  := 0;  -- 消費税(差引金額)
        ln_sum_jun_siire     := 0;  -- 純仕入金額
        ln_sum_jun_kosen     := 0;  -- 純口銭金額
        ln_sum_jun_sasihiki  := 0;  -- 純差引金額
--
        -- カウントアップ
        ln_count := ln_count + 1;
      END IF;
--
      -- ==========================
      --  出力項目を計算
      -- ==========================
      -- 受入実績の場合
      IF (it_data_rec(ln_loop_index).txns_type = '1') THEN
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596
/*
        -- 仕入金額(切捨て)
        ln_siire :=  TRUNC( NVL(it_data_rec(ln_loop_index).conv_quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).kobikigo, 0) );
*/
        -- 仕入金額(四捨五入)
        ln_siire :=  ROUND( NVL(it_data_rec(ln_loop_index).conv_quantity, 0) *
                            NVL(it_data_rec(ln_loop_index).kobikigo, 0), 0);
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596
--
        -- 口銭金額
        -- 口銭区分が「率」の場合
        IF ( it_data_rec(ln_loop_index).kousen_type = '2' ) THEN
          -- 預かり口銭金額＝単価*数量*口銭/100
          ln_kousen := TRUNC( it_data_rec(ln_loop_index).unit_price * 
                              NVL(it_data_rec(ln_loop_index).conv_quantity, 0) * NVL(it_data_rec(ln_loop_index).kousen, 0) / 100 );
        -- 口銭区分が「円」の場合
        ELSIF ( it_data_rec(ln_loop_index).kousen_type = '1' ) THEN
          -- 預り口銭金額＝口銭*数量
          ln_kousen := TRUNC( NVL(it_data_rec(ln_loop_index).kousen, 0) * 
                              NVL(it_data_rec(ln_loop_index).conv_quantity, 0));
        ELSE
          ln_kousen := 0;
        END IF;
--
        -- 賦課金額
        -- 賦課金区分が「率」の場合
        IF ( it_data_rec(ln_loop_index).fukakin_type = '2' ) THEN
--
          -- 粉引額＝単価 * 数量 * 粉引率 / 100
          ln_kobiki_gaku := it_data_rec(ln_loop_index).unit_price * NVL(it_data_rec(ln_loop_index).conv_quantity, 0) * 
                              NVL(it_data_rec(ln_loop_index).kobiki_rate,0) / 100;
          -- 賦課金額＝（単価 * 数量 - 粉引額）* 賦課率 / 100
          ln_fuka := TRUNC(( it_data_rec(ln_loop_index).unit_price * 
                             NVL(it_data_rec(ln_loop_index).conv_quantity, 0) - ln_kobiki_gaku) * 
                             NVL(it_data_rec(ln_loop_index).fukakin,0) / 100);
--
        -- 賦課金区分が「円」の場合
        ELSIF ( it_data_rec(ln_loop_index).fukakin_type = '1' ) THEN
          -- 賦課金額＝賦課金*数量
          ln_fuka := TRUNC( NVL(it_data_rec(ln_loop_index).fukakin,0) * NVL(it_data_rec(ln_loop_index).conv_quantity, 0) );
        ELSE
          ln_fuka := 0;
        END IF;
--
      -- 発注あり返品/発注なし返品の場合
      ELSE
--
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596
/*
        --仕入金額(切捨て)
        ln_siire  :=  TRUNC( NVL(it_data_rec(ln_loop_index).gaku, 0));
*/
        --仕入金額(四捨五入)
        ln_siire  :=  ROUND( NVL(it_data_rec(ln_loop_index).gaku, 0), 0);
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596
--
        --口銭金額
        ln_kousen := it_data_rec(ln_loop_index).kousen_price;
--
        --賦課金額
        ln_fuka   := it_data_rec(ln_loop_index).fukakin_price;
--
      END IF;
--
      -- ==========================
      --  必要項目をサマリー
      -- ==========================
      --消費税(仕入金額)
      ln_sum_tax_siire    := ln_sum_tax_siire + (ROUND(NVL(ln_siire, 0) * NVL(it_data_rec(ln_loop_index).zeiritu , 0) / 100 ,0));
      --消費税(口銭金額)
      ln_sum_tax_kousen   := ln_sum_tax_kousen + (ROUND(NVL(ln_kousen, 0) * NVL(it_data_rec(ln_loop_index).zeiritu , 0) / 100 ,0));
      -- 入庫総数を加算
      ln_sum_qty   := ln_sum_qty + it_data_rec(ln_loop_index).quantity;
      ln_sum_conv_qty := ln_sum_conv_qty + it_data_rec(ln_loop_index).conv_quantity;
      -- 仕入金額を加算
      ln_sum_siire := ln_sum_siire + ln_siire;
      -- 口銭金額を加算
      ln_sum_kosen := ln_sum_kosen + ln_kousen;
      -- 賦課金額を加算
      ln_sum_fuka  := ln_sum_fuka + ln_fuka;
--
    END LOOP main_data_loop ;
--
--
    IF ( it_data_rec.COUNT > 0 ) THEN
--
      ln_loop_index := it_data_rec.COUNT;
--
-- 2009/6/2 v1.27 T.Yoshimoto Add Start 本番#1516
      IF ( ln_sum_conv_qty = 0 ) THEN
        --単価
        ln_kobikigo_tanka   := 0;
      ELSE
-- 2009/6/2 v1.27 T.Yoshimoto Add End 本番#1516
        --単価
        ln_kobikigo_tanka   := ROUND(( ln_sum_siire/ln_sum_conv_qty ), 2);
-- 2009/6/2 v1.27 T.Yoshimoto Add Start 本番#1516
      END IF;
-- 2009/6/2 v1.27 T.Yoshimoto Add End 本番#1516
--
      --差引金額
      ln_sum_sasihiki     := ln_sum_siire - ln_sum_kosen - ln_sum_fuka;
--
      --消費税(差引金額)
      ln_sum_tax_sasihiki := ln_sum_tax_siire - ln_sum_tax_kousen;
--
      --純仕入金額
      ln_sum_jun_siire    := ln_sum_siire + ln_sum_tax_siire;
      --純口銭金額
      ln_sum_jun_kosen    := ln_sum_kosen + ln_sum_tax_kousen;
      --純差引金額
      ln_sum_jun_sasihiki := ln_sum_sasihiki + ln_sum_tax_sasihiki;
--
      -- ==========================
      --  編集後レコードとして格納
      -- ==========================
      ot_data_rec(ln_count).txns_id       := NULL;                                      --取引ID
      ot_data_rec(ln_count).break_dtl     := it_data_rec(ln_loop_index).break_dtl;      --小ブレークキー
      ot_data_rec(ln_count).break_mid     := it_data_rec(ln_loop_index).break_mid;      --中ブレークキー
      ot_data_rec(ln_count).dept_code     := it_data_rec(ln_loop_index).dept_code;      --部署コード
      ot_data_rec(ln_count).dept_name     := it_data_rec(ln_loop_index).dept_name;      --部署名
      ot_data_rec(ln_count).siire_no      := it_data_rec(ln_loop_index).siire_no;       --仕入先番号
      ot_data_rec(ln_count).siire_sht     := it_data_rec(ln_loop_index).siire_sht;      --略称
      ot_data_rec(ln_count).assen_no      := it_data_rec(ln_loop_index).assen_no;       --斡旋者仕入先番号
      ot_data_rec(ln_count).assen_order   := it_data_rec(ln_loop_index).assen_order;    --斡旋者順序
      ot_data_rec(ln_count).assen_sht     := it_data_rec(ln_loop_index).assen_sht;      --略称
      ot_data_rec(ln_count).po_header_id  := NULL;                                      --発注ID
      ot_data_rec(ln_count).txns_date     := NULL;                                      --取引日
      ot_data_rec(ln_count).txns_type     := NULL;                                      --取引タイプ
      ot_data_rec(ln_count).po_no         := NULL;                                      --元文書番号
      ot_data_rec(ln_count).moto_line_no  := NULL;                                      --元文書明細番号
      ot_data_rec(ln_count).rcv_rtn_no    := NULL;                                      --受入返品番号
      ot_data_rec(ln_count).item_no       := NULL;                                      --品目
      ot_data_rec(ln_count).item_name     := NULL;                                      --品目名称
      ot_data_rec(ln_count).item_sht      := NULL;                                      --品目略称
      ot_data_rec(ln_count).futai_code    := NULL;                                      --付帯
      ot_data_rec(ln_count).kobiki_rate   := NULL;                                      --粉引率
      ot_data_rec(ln_count).kobikigo      := ln_kobikigo_tanka;                         --粉引後単価
      ot_data_rec(ln_count).kousen_price  := ln_sum_kosen;                              --預り口銭金額
      ot_data_rec(ln_count).fukakin_price := ln_sum_fuka;                               --賦課金額
      ot_data_rec(ln_count).lot_no        := NULL;                                      --ロットno
      ot_data_rec(ln_count).quantity      := ln_sum_qty;                                --受入返品数量
      ot_data_rec(ln_count).unit_price    := NULL;                                      --単価
      ot_data_rec(ln_count).kousen_type   := NULL;                                      --口銭区分
      ot_data_rec(ln_count).kousen_name   := NULL;                                      --口銭区分名
      ot_data_rec(ln_count).kousen        := NULL;                                      --口銭
      ot_data_rec(ln_count).rcv_rtn_uom   := it_data_rec(ln_loop_index).rcv_rtn_uom;    --受入返品単位
      ot_data_rec(ln_count).fukakin_type  := NULL;                                      --賦課金区分
      ot_data_rec(ln_count).fukakin_name  := NULL;                                      --賦課金区分名
      ot_data_rec(ln_count).fukakin       := NULL;                                      --賦課金
      ot_data_rec(ln_count).zeiritu       := it_data_rec(ln_loop_index).zeiritu;        --税率
      ot_data_rec(ln_count).order1        := NULL;                                      --表示順
      ot_data_rec(ln_count).gaku          := ln_sum_siire;                              --金額(粉引後単価*受入返品数量)
      ot_data_rec(ln_count).siire_tax     := ln_sum_tax_siire;                          --仕入金額（消費税額）
      ot_data_rec(ln_count).kousen_tax    := ln_sum_tax_kousen;                         --口銭（消費税額）
--
    END IF;
--
  EXCEPTION
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
  END prc_edit_data;
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(G-4-1)
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
    lc_break_init            CONSTANT VARCHAR2(100) := '*' ;  -- 取引先名
    lc_break_null            CONSTANT VARCHAR2(100) := '**' ;  -- 品目区分
--
    lc_sum_assensya          CONSTANT VARCHAR2(100) :='【斡旋者計】';
    lc_sum_torihikisaki      CONSTANT VARCHAR2(100) :='【取引先計】';
    lc_report_name           CONSTANT VARCHAR2(100) :='仕入取引明細表';
    lc_caption_assen         CONSTANT VARCHAR2(100) := '斡旋者別' ;
    lc_caption_torihiki      CONSTANT VARCHAR2(100) := '取引先別' ;
    lc_caption_sum           CONSTANT VARCHAR2(100) := '集計' ;
--
    lc_out_assen             CONSTANT VARCHAR2(1)  :='1';
    lc_out_torihiki          CONSTANT VARCHAR2(1)  :='2';
    lc_out_syukei            CONSTANT VARCHAR2(1)  :='3';
    lc_flg_y                 CONSTANT VARCHAR2(1)  := 'Y';
    lc_flg_n                 CONSTANT VARCHAR2(1)  := 'N';
--
    lc_depth_g_lot           CONSTANT NUMBER :=  1;  -- ロット
    lc_depth_g_hutai         CONSTANT NUMBER :=  3;  -- 付帯
    lc_depth_g_item          CONSTANT NUMBER :=  5;  -- 品目
    lc_depth_g_deliver_date  CONSTANT NUMBER :=  7;  -- 納入日
    lc_depth_g_detail        CONSTANT NUMBER :=  9;  -- 斡旋者・取引先
    lc_depth_g_middle        CONSTANT NUMBER := 11;  -- 斡旋者か取引先
    lc_depth_g_dept          CONSTANT NUMBER := 13;  -- 部署
    lc_zero                  CONSTANT NUMBER := 0;
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- 改行深度(開始タグ出力用
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- 金額計算用
    ln_siire                NUMBER DEFAULT 0;         -- 仕入金額
    ln_sasihiki             NUMBER DEFAULT 0;         -- 差引金額
-- 2009/05/18 v1.26 T.Yoshimoto Add Start 本番#1478
    ln_kousen               NUMBER DEFAULT 0;         -- 口銭金額
    ln_kobiki_gaku          NUMBER DEFAULT 0;         -- 粉引額
    ln_fuka                 NUMBER DEFAULT 0;         -- 賦課金額
-- 2009/05/18 v1.26 T.Yoshimoto Add End 本番#1478
    ln_tax_siire            NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_tax_kousen           NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_tax_sasihiki         NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_jun_siire            NUMBER DEFAULT 0;         -- 純仕入金額
    ln_jun_kosen            NUMBER DEFAULT 0;         -- 純口銭金額
    ln_jun_sasihiki         NUMBER DEFAULT 0;         -- 純差引金額
    -- 部署小計用
    ln_sum_post_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_post_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_post_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_post_huka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_post_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_post_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_post_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_post_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_post_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_post_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_post_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
    --総合計用
    ln_sum_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_huka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
--
    lb_ret                  BOOLEAN;
    ln_loop_index           NUMBER DEFAULT 0;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
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
    lb_ret := fnc_set_xml('T', 'user_info');
--
    -- 帳票ＩＤ
    lb_ret := fnc_set_xml('D', 'report_id', gv_report_id);
--
    -- 担当者部署
    lb_ret := fnc_set_xml('D', 'exec_user_dept', gr_header_rec.user_dept, 10);
--
    -- 担当者名
    lb_ret := fnc_set_xml('D', 'exec_user_name', gr_header_rec.user_name, 14);
--
    -- 出力日
    lb_ret := fnc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
--
    -- 抽出from
    lb_ret := fnc_set_xml('D', 'deliver_from', gr_header_rec.deliver_from_date);
--
    -- 抽出to
    lb_ret := fnc_set_xml('D', 'deliver_to', gr_header_rec.deliver_to_date);
--
    -- 出力区分
    lb_ret := fnc_set_xml('D', 'out_flg', gr_param_rec.out_flg);
--
    -- 合計の名称
    IF    (gr_param_rec.out_flg = lc_out_torihiki) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_torihiki);
    ELSIF (gr_param_rec.out_flg = lc_out_assen) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_assen);
    ELSE
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_sum);
    END IF;
--
    -- ヘッダー終了タグ
    lb_ret := fnc_set_xml('T','/user_info');
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
    lb_ret := fnc_set_xml('T', 'data_info');
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- キーブレイク
      -- =====================================================
      --キー割れ判断用変数初期化
      ln_group_depth     := 0;
      lr_now_key.dept    := gt_main_data(ln_loop_index).dept_code;
      lr_now_key.middle  := gt_main_data(ln_loop_index).break_mid;
      lr_now_key.detail  := gt_main_data(ln_loop_index).break_dtl;
      lr_now_key.deliver := lr_now_key.detail||'-'||gt_main_data(ln_loop_index).txns_date;
      lr_now_key.item    := lr_now_key.deliver||'-'||gt_main_data(ln_loop_index).item_no;
      lr_now_key.hutai   := lr_now_key.item||'-'||gt_main_data(ln_loop_index).futai_code;
      lr_now_key.lot     := lr_now_key.hutai||'-'||gt_main_data(ln_loop_index).lot_no;
--
      -- 初回レコードの場合は終了タグを出力しない。
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_g_dept; --開始タグ表示用
        lb_isfirst := FALSE;
      ELSE
        --キー割れ判断　細かい順に判断
        -- ロット
        IF ( NVL(lr_now_key.lot, lc_break_null ) <> lr_pre_key.lot ) THEN
          lb_ret := fnc_set_xml('T', '/g_lot');
          ln_group_depth := lc_depth_g_lot;
--
          -- 付帯
          IF ( NVL(lr_now_key.hutai, lc_break_null ) <> lr_pre_key.hutai ) THEN
            lb_ret := fnc_set_xml('T', '/lg_lot');
            lb_ret := fnc_set_xml('T', '/g_hutai');
            ln_group_depth := lc_depth_g_hutai;
--
            -- 品目
            IF ( NVL(lr_now_key.item, lc_break_null ) <> lr_pre_key.item ) THEN
              lb_ret := fnc_set_xml('T', '/lg_hutai');
              lb_ret := fnc_set_xml('T', '/g_item');
              ln_group_depth := lc_depth_g_item;
--
              -- 納入日
              IF ( NVL(lr_now_key.deliver, lc_break_null ) <> lr_pre_key.deliver ) THEN
                lb_ret := fnc_set_xml('T', '/lg_item');
                lb_ret := fnc_set_xml('T', '/g_deliver_date');
                ln_group_depth := lc_depth_g_deliver_date;
--
                -- 詳細合計(斡旋者＆取引先
                IF ( NVL(lr_now_key.detail, lc_break_null ) <> lr_pre_key.detail ) THEN
                  lb_ret := fnc_set_xml('T', '/lg_deliver_date');
                  lb_ret := fnc_set_xml('T', '/g_detail');
                  ln_group_depth := lc_depth_g_detail;
--
                  -- 中合計(斡旋者 or 取引先
                  IF ( NVL(lr_now_key.middle, lc_break_null ) <> lr_pre_key.middle ) THEN
                    lb_ret := fnc_set_xml('T', '/lg_detail');
                    IF (NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      -- 集計別の場合は出力しない
                      IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
                        -- 部署小計出力する場合
                        lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);
                                                                                        --入庫総数
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                                        --仕入金額
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                                              ln_sum_post_kosen);       --口銭金額
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                                              ln_sum_post_huka);        --賦課金額
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal',
                                                              ln_sum_post_sasihiki);
                                                                                        --差引金額
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                                              ln_sum_post_tax_siire);   --税仕入
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                                              ln_sum_post_tax_kousen);  --税口銭
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                                              ln_sum_post_tax_sasihiki);--税差引
                        lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                                               ln_sum_post_jun_siire);  --純仕入
                        lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                                              ln_sum_post_jun_kosen);   --純口銭
                        lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                                              ln_sum_post_jun_sasihiki);--純差引
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                                              ln_sum_post_huka);        --賦課金額
                        lb_ret := fnc_set_xml('D', 'flg' , lc_flg_y);     -- 出力フラグ
                        -- 部署小計用変数初期化
                        ln_sum_post_qty           := lc_zero;
                        ln_sum_post_siire         := lc_zero;
                        ln_sum_post_kosen         := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                        ln_sum_post_sasihiki      := lc_zero;
                        ln_sum_post_tax_siire     := lc_zero;
                        ln_sum_post_tax_kousen    := lc_zero;
                        ln_sum_post_tax_sasihiki  := lc_zero;
                        ln_sum_post_jun_siire     := lc_zero;
                        ln_sum_post_jun_kosen     := lc_zero;
                        ln_sum_post_jun_sasihiki  := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                      END IF;
                    ELSE
                      lb_ret := fnc_set_xml('D', 'flg' , lc_flg_n);     -- 出力フラグ
                    END IF;
                    lb_ret := fnc_set_xml('D', 'total_flg' , lc_flg_n); -- 総計出力フラグ
                    lb_ret := fnc_set_xml('T', '/g_middle');
                    ln_group_depth := lc_depth_g_middle;
--
                    -- 部署
                    IF ( NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      lb_ret := fnc_set_xml('T', '/lg_middle');
                      lb_ret := fnc_set_xml('T', '/g_dept');
                      ln_group_depth := lc_depth_g_dept;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
        --------------------------------------
        -- 開始タグ
        --------------------------------------
      IF (ln_group_depth >= lc_depth_g_dept) THEN
        -- 部署
        lb_ret := fnc_set_xml('T', 'g_dept');
        lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
        lb_ret := fnc_set_xml('D', 'dept_name', gt_main_data(ln_loop_index).dept_name, 20);
        lb_ret := fnc_set_xml('T', 'lg_middle');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_middle) THEN
        -- 中合計(斡旋者 or 取引先
        lb_ret := fnc_set_xml('T', 'g_middle');
        lb_ret := fnc_set_xml('D', 'mid_code', gt_main_data(ln_loop_index).break_mid);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).assen_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).siire_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_detail');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_detail) THEN
        -- 詳細合計(斡旋者＆取引先
        lb_ret := fnc_set_xml('T', 'g_detail');
        lb_ret := fnc_set_xml('D', 'dtl_code', gt_main_data(ln_loop_index).break_dtl);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).siire_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).assen_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_deliver_date');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_deliver_date) THEN
        -- 納入日
        lb_ret := fnc_set_xml('T', 'g_deliver_date');
        lb_ret := fnc_set_xml('D', 'deliver_date', gt_main_data(ln_loop_index).txns_date);
        lb_ret := fnc_set_xml('T', 'lg_item');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_item) THEN
        -- 品目
        lb_ret := fnc_set_xml('T', 'g_item');
        lb_ret := fnc_set_xml('D', 'item_code', gt_main_data(ln_loop_index).item_no);
        lb_ret := fnc_set_xml('D', 'item_name', gt_main_data(ln_loop_index).item_sht, 20);
        lb_ret := fnc_set_xml('T', 'lg_hutai');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_hutai) THEN
        -- 付帯
        lb_ret := fnc_set_xml('T', 'g_hutai');
        lb_ret := fnc_set_xml('D', 'hutai', gt_main_data(ln_loop_index).futai_code, 1);
        lb_ret := fnc_set_xml('T', 'lg_lot');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_lot) THEN
        -- ロット
        lb_ret := fnc_set_xml('T', 'g_lot');
        lb_ret := fnc_set_xml('D', 'lot_no', gt_main_data(ln_loop_index).lot_no);
      END IF;
--
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      --明細開始
      lb_ret := fnc_set_xml('T', 'line');
--
      --部署コード
      lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
--
      --部署名
      lb_ret := fnc_set_xml('D','dept_name',gt_main_data(ln_loop_index).dept_name, 20);
--
      IF (gr_param_rec.out_flg != gv_out_torihiki) THEN
        --取引先コード（仕入先番号）
        lb_ret := fnc_set_xml('D', 'part_code', gt_main_data(ln_loop_index).siire_no);
--
        --取引先名
        lb_ret := fnc_set_xml('D', 'part_name', gt_main_data(ln_loop_index).siire_sht, 20);
      END IF;
--
      IF (gr_param_rec.out_flg != gv_out_assen) THEN
        --斡旋者コード
        lb_ret := fnc_set_xml('D', 'med_code', gt_main_data(ln_loop_index).assen_no);
--
        --斡旋者名
        lb_ret := fnc_set_xml('D', 'med_name', gt_main_data(ln_loop_index).assen_sht, 20);
      END IF;
--
      --発注No.
      lb_ret := fnc_set_xml('D', 'po_number', gt_main_data(ln_loop_index).po_no);
--
      --粉引率
      lb_ret := fnc_set_xml('N', 'Powder_influence_rate', gt_main_data(ln_loop_index).kobiki_rate);
--
      --粉引後単価
      lb_ret := fnc_set_xml('N', 'Powder_influence_unit_price'
                               , gt_main_data(ln_loop_index).kobikigo);
--
-- 2009/05/18 v1.26 T.Yoshimoto Add Start 本番#1478
      IF (gt_main_data(ln_loop_index).txns_type = '1') THEN
--
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596
/*
        --仕入金額(切捨て)
        ln_siire :=  TRUNC( NVL(gt_main_data(ln_loop_index).conv_quantity, 0)
                          * NVL(gt_main_data(ln_loop_index).kobikigo, 0) );
*/
        --仕入金額(四捨五入)
        ln_siire :=  ROUND( NVL(gt_main_data(ln_loop_index).conv_quantity, 0)
                          * NVL(gt_main_data(ln_loop_index).kobikigo, 0), 0);
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596
--
        lb_ret := fnc_set_xml('Z', 'purchase_amount', ln_siire);
--
        --口銭金額
        -- 口銭区分が「率」の場合
        IF ( gt_main_data(ln_loop_index).kousen_type = '2' ) THEN
          -- 預かり口銭金額＝単価*数量*口銭/100
          ln_kousen := TRUNC( gt_main_data(ln_loop_index).unit_price * 
                              NVL(gt_main_data(ln_loop_index).conv_quantity, 0) * NVL(gt_main_data(ln_loop_index).kousen, 0) / 100 );
        -- 口銭区分が「円」の場合
        ELSIF ( gt_main_data(ln_loop_index).kousen_type = '1' ) THEN
          -- 預り口銭金額＝口銭*数量
          ln_kousen := TRUNC( NVL(gt_main_data(ln_loop_index).kousen, 0) * 
                              NVL(gt_main_data(ln_loop_index).conv_quantity, 0));
        ELSE
          ln_kousen := 0;
        END IF;
--
        lb_ret := fnc_set_xml(  'Z'
                              , 'commission_unit_price_rate'
                              , ln_kousen);
--
        --賦課金額
        -- 賦課金区分が「率」の場合
        IF ( gt_main_data(ln_loop_index).fukakin_type = '2' ) THEN
--
          -- 粉引額＝単価 * 数量 * 粉引率 / 100
          ln_kobiki_gaku := gt_main_data(ln_loop_index).unit_price * NVL(gt_main_data(ln_loop_index).conv_quantity, 0) * 
                              NVL(gt_main_data(ln_loop_index).kobiki_rate,0) / 100;
          -- 賦課金額＝（単価 * 数量 - 粉引額）* 賦課率 / 100
          ln_fuka := TRUNC(( gt_main_data(ln_loop_index).unit_price * 
                             NVL(gt_main_data(ln_loop_index).conv_quantity, 0) - ln_kobiki_gaku) * 
                             NVL(gt_main_data(ln_loop_index).fukakin,0) / 100);
--
        -- 賦課金区分が「円」の場合
        ELSIF ( gt_main_data(ln_loop_index).fukakin_type = '1' ) THEN
          -- 賦課金額＝賦課金*数量
          ln_fuka := TRUNC( NVL(gt_main_data(ln_loop_index).fukakin,0) * NVL(gt_main_data(ln_loop_index).conv_quantity, 0) );
        ELSE
          ln_fuka := 0;
        END IF;
--
        lb_ret := fnc_set_xml(  'Z'
                              , 'levy_unit_price_rate1'
                              , ln_fuka);
--
        --差引金額
        ln_sasihiki :=  ln_siire - NVL(ln_kousen, 0) - NVL(ln_fuka, 0);
        lb_ret := fnc_set_xml('Z', 'deduction_amount', ln_sasihiki);
--
        --入庫総数
        lb_ret := fnc_set_xml('N', 'Warehousing_total', gt_main_data(ln_loop_index).quantity);
--
        --単価
        lb_ret := fnc_set_xml('N', 'unit_price',gt_main_data(ln_loop_index).unit_price);
--
        --口銭区分
        lb_ret := fnc_set_xml('D', 'commission_division', gt_main_data(ln_loop_index).kousen_name, 2);
--
        --口銭
        lb_ret := fnc_set_xml('N', 'commission', gt_main_data(ln_loop_index).kousen);
--
        --消費税(仕入金額)
        ln_tax_siire := NVL(gt_main_data(ln_loop_index).siire_tax,0);
        lb_ret := fnc_set_xml('Z', 'purchase_amount_tax', ln_tax_siire);
--
        --消費税(口銭金額)
        ln_tax_kousen := ROUND(ln_kousen * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100, 0);
        lb_ret := fnc_set_xml('Z', 'commission_unit_price_rate_tax', ln_tax_kousen);
--
        --消費税(差引金額)
        ln_tax_sasihiki := ln_tax_siire - ln_tax_kousen;
        lb_ret := fnc_set_xml('Z', 'deduction_amount_tax', ln_tax_sasihiki);
--
        --単位
        lb_ret := fnc_set_xml(  'D'
                              , 'Warehousing_total_uom'
                              , gt_main_data(ln_loop_index).rcv_rtn_uom, 4);
--
        --賦課金区分
        lb_ret := fnc_set_xml('D', 'levy_division', gt_main_data(ln_loop_index).fukakin_name, 2);
--
        --賦課金
        lb_ret := fnc_set_xml('N', 'levy_unit_price_rate2', gt_main_data(ln_loop_index).fukakin);
--
        --純仕入金額
        ln_jun_siire := ln_siire + ln_tax_siire;
        lb_ret := fnc_set_xml('Z', 'pure_purchase_amount', ln_jun_siire);
--
        --純口銭金額
        ln_jun_kosen := ln_kousen + ln_tax_kousen;
        lb_ret := fnc_set_xml('Z', 'pure_commission_unit_price_rate', ln_jun_kosen);
--
        --賦課金額(3段目)
        lb_ret := fnc_set_xml(  'Z'
                              , 'levy_unit_price_rate3'
                              , ln_fuka);
--
        --純差引金額
        ln_jun_sasihiki := NVL(ln_jun_siire,0) - NVL(ln_jun_kosen,0) - NVL(ln_fuka,0);
        lb_ret := fnc_set_xml('Z', 'pure_deduction_amount', ln_jun_sasihiki);
--
      ELSE
-- 2009/05/18 v1.26 T.Yoshimoto Add End 本番#1478
      --仕入金額
-- 2008/12/02 MOD START
-- 2008/11/06 v1.16 Y.Yamamoto update start
--      ln_siire :=  NVL(gt_main_data(ln_loop_index).quantity, 0)
--                 * NVL(gt_main_data(ln_loop_index).kobikigo, 0);
--      ln_siire :=  TRUNC( NVL(gt_main_data(ln_loop_index).quantity, 0)
--                        * NVL(gt_main_data(ln_loop_index).kobikigo, 0) );
-- 2008/11/06 v1.16 Y.Yamamoto update end
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596
--        ln_siire :=  TRUNC( NVL(gt_main_data(ln_loop_index).gaku, 0));
        ln_siire :=  ROUND( NVL(gt_main_data(ln_loop_index).gaku, 0), 0);
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596
-- 2008/12/02 MOD END
      lb_ret := fnc_set_xml('Z', 'purchase_amount', ln_siire);
--
      --口銭金額
      lb_ret := fnc_set_xml(  'Z'
                            , 'commission_unit_price_rate'
                            , gt_main_data(ln_loop_index).kousen_price);
--
-- 2009/05/18 v1.26 T.Yoshimoto Add Start 本番#1478
      ln_kousen := gt_main_data(ln_loop_index).kousen_price;
-- 2009/05/18 v1.26 T.Yoshimoto Add End 本番#1478
--
      --賦課金額
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate1'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
-- 2009/05/18 v1.26 T.Yoshimoto Add Start 本番#1478
      ln_fuka := gt_main_data(ln_loop_index).fukakin_price;
-- 2009/05/18 v1.26 T.Yoshimoto Add End 本番#1478
--
      --差引金額
      ln_sasihiki :=  ln_siire
                    - NVL(gt_main_data(ln_loop_index).kousen_price,0)
                    - NVL(gt_main_data(ln_loop_index).fukakin_price,0);
      lb_ret := fnc_set_xml('Z', 'deduction_amount', ln_sasihiki);
--
      --入庫総数
      lb_ret := fnc_set_xml('N', 'Warehousing_total', gt_main_data(ln_loop_index).quantity);
--
      --単価
      lb_ret := fnc_set_xml('N', 'unit_price',gt_main_data(ln_loop_index).unit_price);
--
      --口銭区分
      lb_ret := fnc_set_xml('D', 'commission_division', gt_main_data(ln_loop_index).kousen_name, 2);
--
      --口銭
      lb_ret := fnc_set_xml('N', 'commission', gt_main_data(ln_loop_index).kousen);
--
      --消費税(仕入金額)
-- 2008/12/02 MOD START
---- 2008/11/06 v1.16 Y.Yamamoto update start
----      ln_tax_siire := ln_siire * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100;
      --ln_tax_siire := ROUND((ln_siire * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100),0);
---- 2008/11/06 v1.16 Y.Yamamoto update start
      ln_tax_siire := NVL(gt_main_data(ln_loop_index).siire_tax,0);
-- 2008/12/02 MOD END
      lb_ret := fnc_set_xml('Z', 'purchase_amount_tax', ln_tax_siire);
--
      --消費税(口銭金額)
-- 2008/12/02 MOD START
--      ln_tax_kousen :=  gt_main_data(ln_loop_index).kousen_price
--                      * NVL(gt_main_data(ln_loop_index).zeiritu, 0) / 100;
      ln_tax_kousen := NVL(gt_main_data(ln_loop_index).kousen_tax,0);
-- 2008/12/02 MOD END
      lb_ret := fnc_set_xml('Z', 'commission_unit_price_rate_tax', ln_tax_kousen);
--
      --消費税(差引金額)
      ln_tax_sasihiki := ln_tax_siire - ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'deduction_amount_tax', ln_tax_sasihiki);
--
      --単位
      lb_ret := fnc_set_xml(  'D'
                            , 'Warehousing_total_uom'
                            , gt_main_data(ln_loop_index).rcv_rtn_uom, 4);
--
      --賦課金区分
      lb_ret := fnc_set_xml('D', 'levy_division', gt_main_data(ln_loop_index).fukakin_name, 2);
--
      --賦課金
      lb_ret := fnc_set_xml('N', 'levy_unit_price_rate2', gt_main_data(ln_loop_index).fukakin);
--
      --純仕入金額
      ln_jun_siire := ln_siire + ln_tax_siire;
      lb_ret := fnc_set_xml('Z', 'pure_purchase_amount', ln_jun_siire);
--
      --純口銭金額
      ln_jun_kosen := gt_main_data(ln_loop_index).kousen_price + ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'pure_commission_unit_price_rate', ln_jun_kosen);
--
      --賦課金額(3段目)
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate3'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
      --純差引金額
      ln_jun_sasihiki := NVL(ln_jun_siire,0) - NVL(ln_jun_kosen,0) - NVL(gt_main_data(ln_loop_index).fukakin_price,0);
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amount', ln_jun_sasihiki);
-- 2009/05/18 v1.26 T.Yoshimoto Add Start 本番#1478
      END IF;
-- 2009/05/18 v1.26 T.Yoshimoto Add End 本番#1478
--
      -- 明細１行終了
      lb_ret := fnc_set_xml('T', '/line');
--
      --事後処理
      lr_pre_key := lr_now_key;
--
      -- 集計別の場合は出力しない
      IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
        -- 部署合計加算
        ln_sum_post_qty          := ln_sum_post_qty
                                          + NVL(gt_main_data(ln_loop_index).quantity, 0);
        ln_sum_post_siire        := ln_sum_post_siire
                                          + NVL(ln_siire, 0);
        ln_sum_post_kosen        := ln_sum_post_kosen
-- 2009/05/18 v1.26 T.Yoshimoto Mod Start 本番#1478
--                                          + NVL(gt_main_data(ln_loop_index).kousen_price, 0);
                                          + NVL(ln_kousen, 0);
-- 2009/05/18 v1.26 T.Yoshimoto Mod End 本番#1478
        ln_sum_post_huka         := ln_sum_post_huka
-- 2009/05/18 v1.26 T.Yoshimoto Mod Start 本番#1478
--                                          + NVL(gt_main_data(ln_loop_index).fukakin_price, 0);
                                          + NVL(ln_fuka, 0);
-- 2009/05/18 v1.26 T.Yoshimoto Mod End 本番#1478
        ln_sum_post_sasihiki     := ln_sum_post_sasihiki
                                          + NVL(ln_sasihiki, 0);
        ln_sum_post_tax_siire    := ln_sum_post_tax_siire
                                          + NVL(ln_tax_siire, 0);
        ln_sum_post_tax_kousen   := ln_sum_post_tax_kousen
                                          + NVL(ln_tax_kousen, 0);
        ln_sum_post_tax_sasihiki := ln_sum_post_tax_sasihiki
                                          + NVL(ln_tax_sasihiki, 0);
        ln_sum_post_jun_siire    := ln_sum_post_jun_siire
                                          + NVL(ln_jun_siire, 0);
        ln_sum_post_jun_kosen    := ln_sum_post_jun_kosen
                                          + NVL(ln_jun_kosen, 0);
        ln_sum_post_jun_sasihiki := ln_sum_post_jun_sasihiki
                                          + NVL(ln_jun_sasihiki, 0);
      END IF;
--
      --総合計加算
      ln_sum_qty          := ln_sum_qty        + NVL(gt_main_data(ln_loop_index).quantity, 0);
      ln_sum_siire        := ln_sum_siire      + NVL(ln_siire, 0);
-- 2009/05/18 v1.26 T.Yoshimoto Mod Start 本番#1478
      --ln_sum_kosen        := ln_sum_kosen      + NVL(gt_main_data(ln_loop_index).kousen_price, 0);
      --ln_sum_huka         := ln_sum_huka       + NVL(gt_main_data(ln_loop_index).fukakin_price, 0);
      ln_sum_kosen        := ln_sum_kosen      + NVL(ln_kousen, 0);
      ln_sum_huka         := ln_sum_huka       + NVL(ln_fuka, 0);
-- 2009/05/18 v1.26 T.Yoshimoto Mod End 本番#1478
      ln_sum_sasihiki     := ln_sum_sasihiki   + NVL(ln_sasihiki, 0);
      ln_sum_tax_siire    := ln_sum_tax_siire  + NVL(ln_tax_siire, 0);
      ln_sum_tax_kousen   := ln_sum_tax_kousen + NVL(ln_tax_kousen, 0);
      ln_sum_tax_sasihiki := ln_sum_tax_sasihiki + NVL(ln_tax_sasihiki, 0);
      ln_sum_jun_siire    := ln_sum_jun_siire    + NVL(ln_jun_siire, 0);
      ln_sum_jun_kosen    := ln_sum_jun_kosen    + NVL(ln_jun_kosen, 0);
      ln_sum_jun_sasihiki := ln_sum_jun_sasihiki + NVL(ln_jun_sasihiki, 0);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了タグ
    -- =====================================================
    -- ロット
    lb_ret := fnc_set_xml('T', '/g_lot');
    lb_ret := fnc_set_xml('T', '/lg_lot');
--
    -- 付帯
    lb_ret := fnc_set_xml('T', '/g_hutai');
    lb_ret := fnc_set_xml('T', '/lg_hutai');
--
    -- 品目
    lb_ret := fnc_set_xml('T', '/g_item');
    lb_ret := fnc_set_xml('T', '/lg_item');
--
    -- 納入日
    lb_ret := fnc_set_xml('T', '/g_deliver_date');
    lb_ret := fnc_set_xml('T', '/lg_deliver_date');
--
    -- 詳細合計(斡旋者＆取引先
    lb_ret := fnc_set_xml('T', '/g_detail');
    lb_ret := fnc_set_xml('T', '/lg_detail');
--
    -- 中合計(斡旋者 or 取引先
    -- 部署小計出力
    IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
      lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);     --入庫総数
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                        --仕入金額
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                              ln_sum_post_kosen);       --口銭金額
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                              ln_sum_post_huka);        --賦課金額
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal', ln_sum_post_sasihiki);
                                                                        --差引金額
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                              ln_sum_post_tax_siire);   --税仕入
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                              ln_sum_post_tax_kousen);  --税口銭
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                              ln_sum_post_tax_sasihiki);--税差引
      lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                              ln_sum_post_jun_siire);   --純仕入
      lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                              ln_sum_post_jun_kosen);   --純口銭
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                              ln_sum_post_jun_sasihiki);--純差引
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                              ln_sum_post_huka);        --賦課金額
    END IF;
    IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
      lb_ret := fnc_set_xml('D', 'flg');
    END IF;
    lb_ret := fnc_set_xml('D', 'total_flg' ,lc_flg_y);
--
    lb_ret := fnc_set_xml('T', '/g_middle');
    lb_ret := fnc_set_xml('T', '/lg_middle');
--
    -- 総合計表示
    lb_ret := fnc_set_xml('Z', 'sum_Warehousing_total', ln_sum_qty);                    --入庫総数
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount', ln_sum_siire);                    --仕入金額
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate', ln_sum_kosen);         --口銭金額
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate1', ln_sum_huka);               --賦課金額
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount', ln_sum_sasihiki);                --差引金額
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount_tax', ln_sum_tax_siire);            --税仕入
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate_tax', ln_sum_tax_kousen);--税口銭
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount_tax', ln_sum_tax_sasihiki);        --税差引
    lb_ret := fnc_set_xml('Z', 'sum_pure_purchase_amount', ln_sum_jun_siire);           --純仕入
    lb_ret := fnc_set_xml('Z', 'sum_pure_commission_unit_price_rate', ln_sum_jun_kosen);--純口銭
    lb_ret := fnc_set_xml('Z', 'sum_pure_deduction_amount', ln_sum_jun_sasihiki);       --純差引
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate3', ln_sum_huka);               --賦課金額
--
    lb_ret := fnc_set_xml('T', '/g_dept');
--
    -- データ部終了タグ
    lb_ret := fnc_set_xml('T', '/data_info');
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
  END prc_create_xml_data;
--
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data2
   * Description      : ＸＭＬデータ作成2(G-4-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data2(
      ov_errbuf         OUT VARCHAR2          --    エラー・メッセージ           --# 固定 #
     ,ov_retcode        OUT VARCHAR2          --    リターン・コード             --# 固定 #
     ,ov_errmsg         OUT VARCHAR2          --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
--
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data2' ; -- プログラム名
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
    lc_break_init            CONSTANT VARCHAR2(100) := '*' ;  -- 取引先名
    lc_break_null            CONSTANT VARCHAR2(100) := '**' ;  -- 品目区分
--
    lc_sum_assensya          CONSTANT VARCHAR2(100) :='【斡旋者計】';
    lc_sum_torihikisaki      CONSTANT VARCHAR2(100) :='【取引先計】';
    lc_report_name           CONSTANT VARCHAR2(100) :='仕入取引明細表';
    lc_caption_assen         CONSTANT VARCHAR2(100) := '斡旋者別' ;
    lc_caption_torihiki      CONSTANT VARCHAR2(100) := '取引先別' ;
    lc_caption_sum           CONSTANT VARCHAR2(100) := '集計' ;
--
    lc_out_assen             CONSTANT VARCHAR2(1)  :='1';
    lc_out_torihiki          CONSTANT VARCHAR2(1)  :='2';
    lc_out_syukei            CONSTANT VARCHAR2(1)  :='3';
    lc_flg_y                 CONSTANT VARCHAR2(1)  := 'Y';
    lc_flg_n                 CONSTANT VARCHAR2(1)  := 'N';
--
    lc_depth_g_lot           CONSTANT NUMBER :=  1;  -- ロット
    lc_depth_g_hutai         CONSTANT NUMBER :=  3;  -- 付帯
    lc_depth_g_item          CONSTANT NUMBER :=  5;  -- 品目
    lc_depth_g_deliver_date  CONSTANT NUMBER :=  7;  -- 納入日
    lc_depth_g_detail        CONSTANT NUMBER :=  9;  -- 斡旋者・取引先
    lc_depth_g_middle        CONSTANT NUMBER := 11;  -- 斡旋者か取引先
    lc_depth_g_dept          CONSTANT NUMBER := 13;  -- 部署
    lc_zero                  CONSTANT NUMBER := 0;
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lb_isfirst              BOOLEAN       DEFAULT TRUE ;
    ln_group_depth          NUMBER;        -- 改行深度(開始タグ出力用
    lr_now_key              rec_keybreak;
    lr_pre_key              rec_keybreak;
--
    -- 金額計算用
    ln_siire                NUMBER DEFAULT 0;         -- 仕入金額
    ln_sasihiki             NUMBER DEFAULT 0;         -- 差引金額
    ln_kousen               NUMBER DEFAULT 0;         -- 口銭金額
    ln_kobiki_gaku          NUMBER DEFAULT 0;         -- 粉引額
    ln_fuka                 NUMBER DEFAULT 0;         -- 賦課金額
    ln_tax_siire            NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_tax_kousen           NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_tax_sasihiki         NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_jun_siire            NUMBER DEFAULT 0;         -- 純仕入金額
    ln_jun_kosen            NUMBER DEFAULT 0;         -- 純口銭金額
    ln_jun_sasihiki         NUMBER DEFAULT 0;         -- 純差引金額
    -- 部署小計用
    ln_sum_post_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_post_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_post_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_post_huka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_post_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_post_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_post_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_post_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_post_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_post_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_post_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
    --総合計用
    ln_sum_qty              NUMBER DEFAULT 0;         -- 入庫総数
    ln_sum_siire            NUMBER DEFAULT 0;         -- 仕入金額
    ln_sum_kosen            NUMBER DEFAULT 0;         -- 口銭金額
    ln_sum_huka             NUMBER DEFAULT 0;         -- 賦課金額
    ln_sum_sasihiki         NUMBER DEFAULT 0;         -- 差引金額
    ln_sum_tax_siire        NUMBER DEFAULT 0;         -- 消費税(仕入金額)
    ln_sum_tax_kousen       NUMBER DEFAULT 0;         -- 消費税(口銭金額)
    ln_sum_tax_sasihiki     NUMBER DEFAULT 0;         -- 消費税(差引金額)
    ln_sum_jun_siire        NUMBER DEFAULT 0;         -- 純仕入金額
    ln_sum_jun_kosen        NUMBER DEFAULT 0;         -- 純口銭金額
    ln_sum_jun_sasihiki     NUMBER DEFAULT 0;         -- 純差引金額
--
    lb_ret                  BOOLEAN;
    ln_loop_index           NUMBER DEFAULT 0;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
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
    lb_ret := fnc_set_xml('T', 'user_info');
--
    -- 帳票ＩＤ
    lb_ret := fnc_set_xml('D', 'report_id', gv_report_id);
--
    -- 担当者部署
    lb_ret := fnc_set_xml('D', 'exec_user_dept', gr_header_rec.user_dept, 10);
--
    -- 担当者名
    lb_ret := fnc_set_xml('D', 'exec_user_name', gr_header_rec.user_name, 14);
--
    -- 出力日
    lb_ret := fnc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
--
    -- 抽出from
    lb_ret := fnc_set_xml('D', 'deliver_from', gr_header_rec.deliver_from_date);
--
    -- 抽出to
    lb_ret := fnc_set_xml('D', 'deliver_to', gr_header_rec.deliver_to_date);
--
    -- 出力区分
    lb_ret := fnc_set_xml('D', 'out_flg', gr_param_rec.out_flg);
--
    -- 合計の名称
    IF    (gr_param_rec.out_flg = lc_out_torihiki) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_torihiki);
    ELSIF (gr_param_rec.out_flg = lc_out_assen) THEN
      lb_ret := fnc_set_xml('D', 'detail_sum_name', lc_sum_torihikisaki);
      lb_ret := fnc_set_xml('D', 'middle_sum_name', lc_sum_assensya);
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_assen);
    ELSE
      lb_ret := fnc_set_xml('D', 'caption', lc_caption_sum);
    END IF;
--
    -- ヘッダー終了タグ
    lb_ret := fnc_set_xml('T','/user_info');
--
    -- =====================================================
    -- 項目データ抽出処理
    --=====================================================
    prc_get_report_data(
        ot_data_rec   => gt_main_data2  --    取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( gt_main_data2.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- データ部開始タグ
    lb_ret := fnc_set_xml('T', 'data_info');
--
    -- =====================================================
    -- 取得データを集計用に編集
    --=====================================================
    prc_edit_data(
        it_data_rec   => gt_main_data2  --    編集前レコード群
       ,ot_data_rec   => gt_main_data   --    編集後レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR ln_loop_index IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- キーブレイク
      -- =====================================================
      --キー割れ判断用変数初期化
      ln_group_depth     := 0;
      lr_now_key.dept    := gt_main_data(ln_loop_index).dept_code;
      lr_now_key.middle  := gt_main_data(ln_loop_index).break_mid;
      lr_now_key.detail  := gt_main_data(ln_loop_index).break_dtl;
      lr_now_key.deliver := lr_now_key.detail||'-'||gt_main_data(ln_loop_index).txns_date;
      lr_now_key.item    := lr_now_key.deliver||'-'||gt_main_data(ln_loop_index).item_no;
      lr_now_key.hutai   := lr_now_key.item||'-'||gt_main_data(ln_loop_index).futai_code;
      lr_now_key.lot     := lr_now_key.hutai||'-'||gt_main_data(ln_loop_index).lot_no;
--
      -- 初回レコードの場合は終了タグを出力しない。
      IF ( lb_isfirst ) THEN
        ln_group_depth := lc_depth_g_dept; --開始タグ表示用
        lb_isfirst := FALSE;
      ELSE
        --キー割れ判断　細かい順に判断
        -- ロット
        IF ( NVL(lr_now_key.lot, lc_break_null ) <> lr_pre_key.lot ) THEN
          lb_ret := fnc_set_xml('T', '/g_lot');
          ln_group_depth := lc_depth_g_lot;
--
          -- 付帯
          IF ( NVL(lr_now_key.hutai, lc_break_null ) <> lr_pre_key.hutai ) THEN
            lb_ret := fnc_set_xml('T', '/lg_lot');
            lb_ret := fnc_set_xml('T', '/g_hutai');
            ln_group_depth := lc_depth_g_hutai;
--
            -- 品目
            IF ( NVL(lr_now_key.item, lc_break_null ) <> lr_pre_key.item ) THEN
              lb_ret := fnc_set_xml('T', '/lg_hutai');
              lb_ret := fnc_set_xml('T', '/g_item');
              ln_group_depth := lc_depth_g_item;
--
              -- 納入日
              IF ( NVL(lr_now_key.deliver, lc_break_null ) <> lr_pre_key.deliver ) THEN
                lb_ret := fnc_set_xml('T', '/lg_item');
                lb_ret := fnc_set_xml('T', '/g_deliver_date');
                ln_group_depth := lc_depth_g_deliver_date;
--
                -- 詳細合計(斡旋者＆取引先
                IF ( NVL(lr_now_key.detail, lc_break_null ) <> lr_pre_key.detail ) THEN
                  lb_ret := fnc_set_xml('T', '/lg_deliver_date');
                  lb_ret := fnc_set_xml('T', '/g_detail');
                  ln_group_depth := lc_depth_g_detail;
--
                  -- 中合計(斡旋者 or 取引先
                  IF ( NVL(lr_now_key.middle, lc_break_null ) <> lr_pre_key.middle ) THEN
                    lb_ret := fnc_set_xml('T', '/lg_detail');
                    IF (NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      -- 集計別の場合は出力しない
                      IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
                        -- 部署小計出力する場合
                        lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);
                                                                                        --入庫総数
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                                        --仕入金額
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                                              ln_sum_post_kosen);       --口銭金額
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                                              ln_sum_post_huka);        --賦課金額
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal',
                                                              ln_sum_post_sasihiki);
                                                                                        --差引金額
                        lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                                              ln_sum_post_tax_siire);   --税仕入
                        lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                                              ln_sum_post_tax_kousen);  --税口銭
                        lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                                              ln_sum_post_tax_sasihiki);--税差引
                        lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                                               ln_sum_post_jun_siire);  --純仕入
                        lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                                              ln_sum_post_jun_kosen);   --純口銭
                        lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                                              ln_sum_post_jun_sasihiki);--純差引
                        lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                                              ln_sum_post_huka);        --賦課金額
                        lb_ret := fnc_set_xml('D', 'flg' , lc_flg_y);     -- 出力フラグ
                        -- 部署小計用変数初期化
                        ln_sum_post_qty           := lc_zero;
                        ln_sum_post_siire         := lc_zero;
                        ln_sum_post_kosen         := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                        ln_sum_post_sasihiki      := lc_zero;
                        ln_sum_post_tax_siire     := lc_zero;
                        ln_sum_post_tax_kousen    := lc_zero;
                        ln_sum_post_tax_sasihiki  := lc_zero;
                        ln_sum_post_jun_siire     := lc_zero;
                        ln_sum_post_jun_kosen     := lc_zero;
                        ln_sum_post_jun_sasihiki  := lc_zero;
                        ln_sum_post_huka          := lc_zero;
                      END IF;
                    ELSE
                      lb_ret := fnc_set_xml('D', 'flg' , lc_flg_n);     -- 出力フラグ
                    END IF;
                    lb_ret := fnc_set_xml('D', 'total_flg' , lc_flg_n); -- 総計出力フラグ
                    lb_ret := fnc_set_xml('T', '/g_middle');
                    ln_group_depth := lc_depth_g_middle;
--
                    -- 部署
                    IF ( NVL(lr_now_key.dept, lc_break_null ) <> lr_pre_key.dept ) THEN
                      lb_ret := fnc_set_xml('T', '/lg_middle');
                      lb_ret := fnc_set_xml('T', '/g_dept');
                      ln_group_depth := lc_depth_g_dept;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
--
        --------------------------------------
        -- 開始タグ
        --------------------------------------
      IF (ln_group_depth >= lc_depth_g_dept) THEN
        -- 部署
        lb_ret := fnc_set_xml('T', 'g_dept');
        lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
        lb_ret := fnc_set_xml('D', 'dept_name', gt_main_data(ln_loop_index).dept_name, 20);
        lb_ret := fnc_set_xml('T', 'lg_middle');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_middle) THEN
        -- 中合計(斡旋者 or 取引先
        lb_ret := fnc_set_xml('T', 'g_middle');
        lb_ret := fnc_set_xml('D', 'mid_code', gt_main_data(ln_loop_index).break_mid);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).assen_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'middle_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'middle_name', gt_main_data(ln_loop_index).siire_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_detail');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_detail) THEN
        -- 詳細合計(斡旋者＆取引先
        lb_ret := fnc_set_xml('T', 'g_detail');
        lb_ret := fnc_set_xml('D', 'dtl_code', gt_main_data(ln_loop_index).break_dtl);
        IF (gr_param_rec.out_flg = '1') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).siire_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).siire_sht, 20);
        ELSIF (gr_param_rec.out_flg = '2') THEN
          lb_ret := fnc_set_xml('D', 'detail_code', gt_main_data(ln_loop_index).assen_no);
          lb_ret := fnc_set_xml('D', 'detail_name', gt_main_data(ln_loop_index).assen_sht, 20);
        END IF;
        lb_ret := fnc_set_xml('T', 'lg_deliver_date');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_deliver_date) THEN
        -- 納入日
        lb_ret := fnc_set_xml('T', 'g_deliver_date');
        lb_ret := fnc_set_xml('D', 'deliver_date', gt_main_data(ln_loop_index).txns_date);
        lb_ret := fnc_set_xml('T', 'lg_item');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_item) THEN
        -- 品目
        lb_ret := fnc_set_xml('T', 'g_item');
        lb_ret := fnc_set_xml('D', 'item_code', gt_main_data(ln_loop_index).item_no);
        lb_ret := fnc_set_xml('D', 'item_name', gt_main_data(ln_loop_index).item_sht, 20);
        lb_ret := fnc_set_xml('T', 'lg_hutai');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_hutai) THEN
        -- 付帯
        lb_ret := fnc_set_xml('T', 'g_hutai');
        lb_ret := fnc_set_xml('D', 'hutai', gt_main_data(ln_loop_index).futai_code, 1);
        lb_ret := fnc_set_xml('T', 'lg_lot');
      END IF;
--
      IF (ln_group_depth >= lc_depth_g_lot) THEN
        -- ロット
        lb_ret := fnc_set_xml('T', 'g_lot');
        lb_ret := fnc_set_xml('D', 'lot_no', gt_main_data(ln_loop_index).lot_no);
      END IF;
--
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      --明細開始
      lb_ret := fnc_set_xml('T', 'line');
--
      --部署コード
      lb_ret := fnc_set_xml('D', 'dept_code', gt_main_data(ln_loop_index).dept_code);
--
      --部署名
      lb_ret := fnc_set_xml('D','dept_name',gt_main_data(ln_loop_index).dept_name, 20);
--
      IF (gr_param_rec.out_flg != gv_out_torihiki) THEN
        --取引先コード（仕入先番号）
        lb_ret := fnc_set_xml('D', 'part_code', gt_main_data(ln_loop_index).siire_no);
--
        --取引先名
        lb_ret := fnc_set_xml('D', 'part_name', gt_main_data(ln_loop_index).siire_sht, 20);
      END IF;
--
      IF (gr_param_rec.out_flg != gv_out_assen) THEN
        --斡旋者コード
        lb_ret := fnc_set_xml('D', 'med_code', gt_main_data(ln_loop_index).assen_no);
--
        --斡旋者名
        lb_ret := fnc_set_xml('D', 'med_name', gt_main_data(ln_loop_index).assen_sht, 20);
      END IF;
--
      --発注No.
      lb_ret := fnc_set_xml('D', 'po_number', gt_main_data(ln_loop_index).po_no);
--
      --粉引率
      lb_ret := fnc_set_xml('N', 'Powder_influence_rate', gt_main_data(ln_loop_index).kobiki_rate);
--
      --粉引後単価
      lb_ret := fnc_set_xml('N', 'Powder_influence_unit_price'
                               , gt_main_data(ln_loop_index).kobikigo);
--
      --仕入金額
-- 2009/08/10 v1.30 T.Yoshimoto Mod Start 本番#1596
--      ln_siire :=  TRUNC( NVL(gt_main_data(ln_loop_index).gaku, 0));
      ln_siire :=  ROUND( NVL(gt_main_data(ln_loop_index).gaku, 0), 0);
-- 2009/08/10 v1.30 T.Yoshimoto Mod End 本番#1596
      lb_ret := fnc_set_xml('Z', 'purchase_amount', ln_siire);
--
      --口銭金額
      lb_ret := fnc_set_xml(  'Z'
                            , 'commission_unit_price_rate'
                            , gt_main_data(ln_loop_index).kousen_price);
--
      ln_kousen := gt_main_data(ln_loop_index).kousen_price;
--
      --賦課金額
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate1'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
      ln_fuka := gt_main_data(ln_loop_index).fukakin_price;
--
      --差引金額
      ln_sasihiki :=  ln_siire
                    - NVL(gt_main_data(ln_loop_index).kousen_price,0)
                    - NVL(gt_main_data(ln_loop_index).fukakin_price,0);
      lb_ret := fnc_set_xml('Z', 'deduction_amount', ln_sasihiki);
--
      --入庫総数
      lb_ret := fnc_set_xml('N', 'Warehousing_total', gt_main_data(ln_loop_index).quantity);
--
      --単価
      lb_ret := fnc_set_xml('N', 'unit_price',gt_main_data(ln_loop_index).unit_price);
--
      --口銭区分
      lb_ret := fnc_set_xml('D', 'commission_division', gt_main_data(ln_loop_index).kousen_name, 2);
--
      --口銭
      lb_ret := fnc_set_xml('N', 'commission', gt_main_data(ln_loop_index).kousen);
--
      --消費税(仕入金額)
      ln_tax_siire := NVL(gt_main_data(ln_loop_index).siire_tax,0);
      lb_ret := fnc_set_xml('Z', 'purchase_amount_tax', ln_tax_siire);
--
      --消費税(口銭金額)
      ln_tax_kousen := NVL(gt_main_data(ln_loop_index).kousen_tax,0);
      lb_ret := fnc_set_xml('Z', 'commission_unit_price_rate_tax', ln_tax_kousen);
--
      --消費税(差引金額)
      ln_tax_sasihiki := ln_tax_siire - ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'deduction_amount_tax', ln_tax_sasihiki);
--
      --単位
      lb_ret := fnc_set_xml(  'D'
                            , 'Warehousing_total_uom'
                            , gt_main_data(ln_loop_index).rcv_rtn_uom, 4);
--
      --賦課金区分
      lb_ret := fnc_set_xml('D', 'levy_division', gt_main_data(ln_loop_index).fukakin_name, 2);
--
      --賦課金
      lb_ret := fnc_set_xml('N', 'levy_unit_price_rate2', gt_main_data(ln_loop_index).fukakin);
--
      --純仕入金額
      ln_jun_siire := ln_siire + ln_tax_siire;
      lb_ret := fnc_set_xml('Z', 'pure_purchase_amount', ln_jun_siire);
--
      --純口銭金額
      ln_jun_kosen := gt_main_data(ln_loop_index).kousen_price + ln_tax_kousen;
      lb_ret := fnc_set_xml('Z', 'pure_commission_unit_price_rate', ln_jun_kosen);
--
      --賦課金額(3段目)
      lb_ret := fnc_set_xml(  'Z'
                            , 'levy_unit_price_rate3'
                            , gt_main_data(ln_loop_index).fukakin_price);
--
      --純差引金額
      ln_jun_sasihiki := NVL(ln_jun_siire,0) - NVL(ln_jun_kosen,0) - NVL(gt_main_data(ln_loop_index).fukakin_price,0);
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amount', ln_jun_sasihiki);
--
      -- 明細１行終了
      lb_ret := fnc_set_xml('T', '/line');
--
      --事後処理
      lr_pre_key := lr_now_key;
--
      --総合計加算
      ln_sum_qty          := ln_sum_qty        + NVL(gt_main_data(ln_loop_index).quantity, 0);
      ln_sum_siire        := ln_sum_siire      + NVL(ln_siire, 0);
      ln_sum_kosen        := ln_sum_kosen      + NVL(ln_kousen, 0);
      ln_sum_huka         := ln_sum_huka       + NVL(ln_fuka, 0);
      ln_sum_sasihiki     := ln_sum_sasihiki   + NVL(ln_sasihiki, 0);
      ln_sum_tax_siire    := ln_sum_tax_siire  + NVL(ln_tax_siire, 0);
      ln_sum_tax_kousen   := ln_sum_tax_kousen + NVL(ln_tax_kousen, 0);
      ln_sum_tax_sasihiki := ln_sum_tax_sasihiki + NVL(ln_tax_sasihiki, 0);
      ln_sum_jun_siire    := ln_sum_jun_siire    + NVL(ln_jun_siire, 0);
      ln_sum_jun_kosen    := ln_sum_jun_kosen    + NVL(ln_jun_kosen, 0);
      ln_sum_jun_sasihiki := ln_sum_jun_sasihiki + NVL(ln_jun_sasihiki, 0);
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了タグ
    -- =====================================================
    -- ロット
    lb_ret := fnc_set_xml('T', '/g_lot');
    lb_ret := fnc_set_xml('T', '/lg_lot');
--
    -- 付帯
    lb_ret := fnc_set_xml('T', '/g_hutai');
    lb_ret := fnc_set_xml('T', '/lg_hutai');
--
    -- 品目
    lb_ret := fnc_set_xml('T', '/g_item');
    lb_ret := fnc_set_xml('T', '/lg_item');
--
    -- 納入日
    lb_ret := fnc_set_xml('T', '/g_deliver_date');
    lb_ret := fnc_set_xml('T', '/lg_deliver_date');
--
    -- 詳細合計(斡旋者＆取引先
    lb_ret := fnc_set_xml('T', '/g_detail');
    lb_ret := fnc_set_xml('T', '/lg_detail');
--
    -- 中合計(斡旋者 or 取引先
    -- 部署小計出力
    IF ( gr_param_rec.out_flg <> lc_out_syukei) THEN
      lb_ret := fnc_set_xml('Z', 'whse_subtotal', ln_sum_post_qty);     --入庫総数
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_subtotal', ln_sum_post_siire);
                                                                        --仕入金額
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_subtotal',
                                              ln_sum_post_kosen);       --口銭金額
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate1_subtotal',
                                              ln_sum_post_huka);        --賦課金額
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_subtotal', ln_sum_post_sasihiki);
                                                                        --差引金額
      lb_ret := fnc_set_xml('Z', 'purchs_amnt_tax_subtotal',
                                              ln_sum_post_tax_siire);   --税仕入
      lb_ret := fnc_set_xml('Z', 'commi_unt_price_rate_tax_subtotal',
                                              ln_sum_post_tax_kousen);  --税口銭
      lb_ret := fnc_set_xml('Z', 'deduction_amnt_tax_subtotal',
                                              ln_sum_post_tax_sasihiki);--税差引
      lb_ret := fnc_set_xml('Z', 'pure_purchs_amnt_subtotal',
                                              ln_sum_post_jun_siire);   --純仕入
      lb_ret := fnc_set_xml('Z', 'pure_commi_unt_price_rate_subtotal',
                                              ln_sum_post_jun_kosen);   --純口銭
      lb_ret := fnc_set_xml('Z', 'pure_deduction_amnt_subtotal',
                                              ln_sum_post_jun_sasihiki);--純差引
      lb_ret := fnc_set_xml('Z', 'levy_unt_price_rate3_subtotal',
                                              ln_sum_post_huka);        --賦課金額
    END IF;
--
    lb_ret := fnc_set_xml('D', 'total_flg' ,lc_flg_y);
--
    lb_ret := fnc_set_xml('T', '/g_middle');
    lb_ret := fnc_set_xml('T', '/lg_middle');
--
    -- 総合計表示
    lb_ret := fnc_set_xml('Z', 'sum_Warehousing_total', ln_sum_qty);                      --入庫総数
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount', ln_sum_siire);                      --仕入金額
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate', ln_sum_kosen);           --口銭金額
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate1', ln_sum_huka);                 --賦課金額
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount', ln_sum_sasihiki);                  --差引金額
    lb_ret := fnc_set_xml('Z', 'sum_purchase_amount_tax', ln_sum_tax_siire);              --税仕入
    lb_ret := fnc_set_xml('Z', 'sum_commission_unit_price_rate_tax', ln_sum_tax_kousen);  --税口銭
    lb_ret := fnc_set_xml('Z', 'sum_deduction_amount_tax', ln_sum_tax_sasihiki);          --税差引
    lb_ret := fnc_set_xml('Z', 'sum_pure_purchase_amount', ln_sum_jun_siire);             --純仕入
    lb_ret := fnc_set_xml('Z', 'sum_pure_commission_unit_price_rate', ln_sum_jun_kosen);  --純口銭
    lb_ret := fnc_set_xml('Z', 'sum_pure_deduction_amount', ln_sum_jun_sasihiki);         --純差引
    lb_ret := fnc_set_xml('Z', 'sum_levy_unit_price_rate3', ln_sum_huka);                 --賦課金額
--
    lb_ret := fnc_set_xml('T', '/g_dept');
--
    -- データ部終了タグ
    lb_ret := fnc_set_xml('T', '/data_info');
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
  END prc_create_xml_data2;
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_out_flg           IN     VARCHAR2   --出力区分
     ,iv_deliver_from      IN     VARCHAR2   --納入日FROM
     ,iv_deliver_to        IN     VARCHAR2   --納入日TO
     ,iv_dept_code1        IN     VARCHAR2   --担当部署１
     ,iv_dept_code2        IN     VARCHAR2   --担当部署２
     ,iv_dept_code3        IN     VARCHAR2   --担当部署３
     ,iv_dept_code4        IN     VARCHAR2   --担当部署４
     ,iv_dept_code5        IN     VARCHAR2   --担当部署５
     ,iv_vendor_code1      IN     VARCHAR2   -- 取引先1
     ,iv_vendor_code2      IN     VARCHAR2   -- 取引先2
     ,iv_vendor_code3      IN     VARCHAR2   -- 取引先3
     ,iv_vendor_code4      IN     VARCHAR2   -- 取引先4
     ,iv_vendor_code5      IN     VARCHAR2   -- 取引先5
     ,iv_mediator_code1    IN     VARCHAR2   -- 斡旋者1
     ,iv_mediator_code2    IN     VARCHAR2   -- 斡旋者2
     ,iv_mediator_code3    IN     VARCHAR2   -- 斡旋者3
     ,iv_mediator_code4    IN     VARCHAR2   -- 斡旋者4
     ,iv_mediator_code5    IN     VARCHAR2   -- 斡旋者5
     ,iv_po_num            IN     VARCHAR2   -- 発注番号
     ,iv_item_code         IN     VARCHAR2   -- 品目コード
     ,iv_security_flg      IN     VARCHAR2   -- セキュリティ区分
     ,ov_errbuf            OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           OUT    VARCHAR2   -- リターン・コード             --# 固定 #
     ,ov_errmsg            OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- =====================================================
    -- 初期処理
    -- =====================================================
    prc_set_param(
        ov_errbuf             => lv_errbuf             -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode            -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
       ,iv_out_flg            => iv_out_flg            -- 出力区分
       ,iv_deliver_from       => iv_deliver_from       -- 納入日FROM
       ,iv_deliver_to         => iv_deliver_to         -- 納入日TO
       ,iv_vendor_code1       => iv_vendor_code1       -- 取引先１
       ,iv_vendor_code2       => iv_vendor_code2       -- 取引先２
       ,iv_vendor_code3       => iv_vendor_code3       -- 取引先３
       ,iv_vendor_code4       => iv_vendor_code4       -- 取引先４
       ,iv_vendor_code5       => iv_vendor_code5       -- 取引先５
       ,iv_mediator_code1     => iv_mediator_code1     -- 斡旋者１
       ,iv_mediator_code2     => iv_mediator_code2     -- 斡旋者２
       ,iv_mediator_code3     => iv_mediator_code3     -- 斡旋者３
       ,iv_mediator_code4     => iv_mediator_code4     -- 斡旋者４
       ,iv_mediator_code5     => iv_mediator_code5     -- 斡旋者５
       ,iv_dept_code1         => iv_dept_code1         -- 担当部署１
       ,iv_dept_code2         => iv_dept_code2         -- 担当部署２
       ,iv_dept_code3         => iv_dept_code3         -- 担当部署３
       ,iv_dept_code4         => iv_dept_code4         -- 担当部署４
       ,iv_dept_code5         => iv_dept_code5         -- 担当部署５
       ,iv_po_num             => iv_po_num             -- 発注番号
       ,iv_item_code          => iv_item_code          -- 品目コード
       ,iv_security_flg       => iv_security_flg       -- セキュリティ区分
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
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
    -- 取引先別・斡旋者別の場合
    IF ( iv_out_flg <> gv_out_syukei) THEN
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
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
-- 2009/05/20 v1.26 T.Yoshimoto Add Start 本番#1478
    -- 集計の場合
    ELSE
      -- =====================================================
      -- 帳票データ出力(集計用)
      -- =====================================================
      prc_create_xml_data2(
          ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
        ) ;
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
    END IF;
-- 2009/05/20 v1.26 T.Yoshimoto Add End 本番#1478
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <g_dept>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_detail>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_middle>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </g_dept>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
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
      errbuf                OUT   VARCHAR2  -- エラーメッセージ
     ,retcode               OUT   VARCHAR2  -- エラーコード
     ,iv_out_flg            IN    VARCHAR2  --出力区分
     ,iv_deliver_from       IN    VARCHAR2  --納入日FROM
     ,iv_deliver_to         IN    VARCHAR2  --納入日TO
     ,iv_dept_code1         IN    VARCHAR2  --担当部署１
     ,iv_dept_code2         IN    VARCHAR2  --担当部署２
     ,iv_dept_code3         IN    VARCHAR2  --担当部署３
     ,iv_dept_code4         IN    VARCHAR2  --担当部署４
     ,iv_dept_code5         IN    VARCHAR2  --担当部署５
     ,iv_vendor_code1       IN    VARCHAR2  -- 取引先1
     ,iv_vendor_code2       IN    VARCHAR2  -- 取引先2
     ,iv_vendor_code3       IN    VARCHAR2  -- 取引先3
     ,iv_vendor_code4       IN    VARCHAR2  -- 取引先4
     ,iv_vendor_code5       IN    VARCHAR2  -- 取引先5
     ,iv_mediator_code1     IN    VARCHAR2  -- 斡旋者1
     ,iv_mediator_code2     IN    VARCHAR2  -- 斡旋者2
     ,iv_mediator_code3     IN    VARCHAR2  -- 斡旋者3
     ,iv_mediator_code4     IN    VARCHAR2  -- 斡旋者4
     ,iv_mediator_code5     IN    VARCHAR2  -- 斡旋者5
     ,iv_po_num             IN    VARCHAR2  -- 発注番号
     ,iv_item_code          IN    VARCHAR2  -- 品目コード
     ,iv_security_flg       IN    VARCHAR2  -- セキュリティ区分
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
        iv_out_flg         =>  iv_out_flg        --出力区分
       ,iv_deliver_from    =>  iv_deliver_from   --納入日FROM
       ,iv_deliver_to      =>  iv_deliver_to     --納入日TO
       ,iv_dept_code1      =>  iv_dept_code1     --担当部署１
       ,iv_dept_code2      =>  iv_dept_code2     --担当部署２
       ,iv_dept_code3      =>  iv_dept_code3     --担当部署３
       ,iv_dept_code4      =>  iv_dept_code4     --担当部署４
       ,iv_dept_code5      =>  iv_dept_code5     --担当部署５
       ,iv_vendor_code1    =>  iv_vendor_code1   -- 取引先1
       ,iv_vendor_code2    =>  iv_vendor_code2   -- 取引先2
       ,iv_vendor_code3    =>  iv_vendor_code3   -- 取引先3
       ,iv_vendor_code4    =>  iv_vendor_code4   -- 取引先4
       ,iv_vendor_code5    =>  iv_vendor_code5   -- 取引先5
       ,iv_mediator_code1  =>  iv_mediator_code1 -- 斡旋者1
       ,iv_mediator_code2  =>  iv_mediator_code2 -- 斡旋者2
       ,iv_mediator_code3  =>  iv_mediator_code3 -- 斡旋者3
       ,iv_mediator_code4  =>  iv_mediator_code4 -- 斡旋者4
       ,iv_mediator_code5  =>  iv_mediator_code5 -- 斡旋者5
       ,iv_po_num          =>  iv_po_num         -- 発注番号
       ,iv_item_code       =>  iv_item_code      -- 品目コード
       ,iv_security_flg    =>  iv_security_flg   -- セキュリティ区分
       ,ov_errbuf          =>  lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         =>  lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg          =>  lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF (( lv_retcode = gv_status_error )
      OR ( lv_retcode = gv_status_warn )) THEN
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
END xxpo360006c ;
/
