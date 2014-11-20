CREATE OR REPLACE PACKAGE BODY xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(body)
 * Description      : 仕入明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 *                  : 有償支給帳票Issue1.0(T_MD070_BPO_36E)
 * Version          : 1.23
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                      Description
 * -------------------------- ------------------------------------------------------------
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返します。(vendor_code)
 *  fnc_get_in_statement      FUNCTION  : IN句の内容を返します。(atr_code)
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(E-2)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(E-3)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(E-4)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/17    1.0   Y.Majikina       新規作成
 *  2008/05/12    1.1   Y.Majikina       受入返品、発注なし返品時の総合計値に
 *                                       マイナスを掛けるよう修正
 *                                       発注なし仕入れ返品の場合、受入返品実績の換算入数を
 *                                       取得するよう修正
 *  2008/05/13    1.2   Y.Majikina       品目ごとに品目計が表示されない点を修正
 *                                       データによって、YY/MM/DD、YY/M/Dのような書式で出力される
 *                                       点を修正
 *  2008/05/14    1.3   Y.Majikina       担当部署、担当者名の最大長処理を追加
 *                                       セキュリティの条件を修正
 *  2008/05/23    1.4   Y.Majikina       数量取得項目の変更。金額計算の不備を修正
 *  2008/05/23    1.5   Y.Majikina       セキュリティ区分２でログインしたときにSQLエラーになる点を
 *                                       修正
 *  2008/05/26    1.6   R.Tomoyose       発注あり仕入先返品時、単価は受入返品実績アドオンより取得
 *  2008/05/29    1.7   T.Ikehara        計の出力ﾌﾗｸﾞを追加、修正(ﾚｲｱｳﾄのｾｯｼｮﾝ修正対応の為)
 *                                        パラメータ：担当部署の際の出力内容を変更
 *  2008/06/13    1.8   Y.Ishikawa        ロットコピーにより作成した発注の仕入帳票を出力すると
 *                                       、１つの明細の情報が２件以上されないよう修正。
 *  2008/06/16    1.9   I.Higa           TEMP領域エラー回避のため、xxpo_categories_vを２つ以上使用
 *                                       しないようにする
 *  2008/06/25    1.10  T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/25    1.11  Y.Ishikawa       総数は、数量(QUANTITY)ではなく受入返品数量
 *                                       (RCV_RTN_QUANTITY)をセットする
 *  2008/07/04    1.12  Y.Majikina       TEMP領域エラー回避のため、xxcmn_categories4_vを使用
 *                                       しないように修正
 *  2008/07/07    1.13  Y.Majikina       仕入金額計算時は、受入返品数量ではなく数量(QUANTITY)
 *                                       に修正
 *  2008/07/15    1.14  I.Higa           「発注なし仕入先返品」以外は、発注ヘッダの部署コードを
 *                                       事業所情報VIEW2と緋付ける
 *                                       受入返品実績アドオンの部署コードとは緋付けない
 *  2008/07/24    1.15  I.Higa           「発注なし仕入先返品」の場合、以下の項目は受入返品実績
 *                                       より取得する
 *                                        「工場」、「納入先」、「摘要」、「付帯コード」
 *  2008/10/21    1.16  T.Ohashi         T_S_456,T_TE080_BPO_300 指摘29対応
 *  2008/11/04    1.17  Y.Yamamoto       統合障害#470
 *  2008/12/08    1.18  H.Itou           本番障害#551
 *  2008/12/09    1.19  T.Yoshimoto      本番障害#579
 *  2008/12/24    1.20  A.Shiina         本番障害#827
 *  2009/03/30    1.21  A.Shiina         本番障害#1346
 *  2009/09/24    1.22  T.Yoshimoto      本番障害#1523
 *  2010/01/06    1.23  H.Itou           本稼動障害#892
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
  gv_pkg_name        CONSTANT VARCHAR2(20) := 'XXPO360004C' ;   -- パッケージ名
  gv_print_name      CONSTANT VARCHAR2(20) := '仕入明細表' ;    -- 帳票名
  gv_dept_cd_all     CONSTANT VARCHAR2(5)  := 'ZZZZ';           -- 担当部署(ALL)
  gn_one             CONSTANT NUMBER  DEFAULT 1;
  gv_language        CONSTANT VARCHAR2(3)  := 'JA';             -- 言語
  gv_lot_n_div       CONSTANT VARCHAR2(1) := '0';               -- ロット管理なし
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;     -- アプリケーション（XXCMN）
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;      -- アプリケーション（XXPO）
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '有償支給セキュリティVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '従業員ID' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'MM/DD' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YY/MM/DD';
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE vendor_code_type IS TABLE OF xxpo_rcv_and_rtn_txns.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE art_code_type    IS TABLE OF xxpo_rcv_and_rtn_txns.item_code%TYPE   INDEX BY BINARY_INTEGER;
--
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
    deliver_from     DATE,                                              -- 納入日FROM
    deliver_to       DATE,                                              -- 納入日TO
    item_division    mtl_categories_b.segment1%TYPE,                    -- 商品区分
    dept_code        po_headers_all.attribute10%TYPE,                   -- 担当部署
    vendor_code      vendor_code_type,                                  -- 取引先1～5
    art_division     mtl_categories_b.segment1%TYPE,                    -- 品目区分
    art_code         art_code_type,                                     -- 品目1
    crowd1           xxpo_categories_v.category_code%TYPE,              -- 群1
    crowd2           xxpo_categories_v.category_code%TYPE,              -- 群2
    crowd3           xxpo_categories_v.category_code%TYPE,              -- 群3
    security_flg     xxpo_security_supply_v.security_class%TYPE         -- セキュリティ区分
  );
--
  TYPE rec_data_type_dtl  IS RECORD (
   category_cd    mtl_categories_b.segment1%TYPE,                         -- 商品区分コード
   category_desc  mtl_categories_b.description%TYPE,                      -- 商品区分名
   loc_cd         hr_locations_all.location_code%TYPE,                    -- 部署コード
   loc_name       hr_locations_all.description%TYPE,                      -- 部署名
   xv_seg1        po_vendors.segment1%TYPE,                               -- 取引先コード
   vend_shrt_nm   xxcmn_vendors.vendor_short_name%TYPE,                   -- 取引先名
   category_cd2   mtl_categories_b.segment1%TYPE,                         -- 品目区分コード
   category_desc2 mtl_categories_b.description%TYPE,                      -- 品目区分名
-- 2008/12/24 v1.20 UPDATE START
--   old_crw_cd     ic_item_mst_b.attribute1%TYPE,                          -- 群
   crw_cd         VARCHAR2(240),                                          -- 群
-- 2008/12/24 v1.20 UPDATE END
   item_no        ic_item_mst_b.item_no%TYPE,                             -- 品目(品目コード
   item_sht_nm    xxcmn_item_mst_b.item_short_name%TYPE,                  -- 品目(品目名)
   po_attr3       po_lines_all.attribute3%TYPE,                           -- 付帯
   txns_date      xxpo_rcv_and_rtn_txns.txns_date%TYPE,                   -- 納入日
   lot_no         ic_lots_mst.lot_no%TYPE,                                -- ロットNO
   ic_attr1       ic_lots_mst.attribute1%TYPE,                            -- 製造日
   ic_attr2       ic_lots_mst.attribute2%TYPE,                            -- 固有記号
   ic_attr3       ic_lots_mst.attribute3%TYPE,                            -- 賞味期限
   order_no       xxpo_rcv_and_rtn_txns.source_document_number%TYPE,      -- 発注No
   factry_code    po_vendor_sites_all.vendor_site_code%TYPE,              -- 工場(工場コード)
-- mod start 1.16
--   in_cnt         xxpo_rcv_and_rtn_txns.unit_price%TYPE,                  -- 入数
   in_cnt         xxpo_rcv_and_rtn_txns.conversion_factor%TYPE,           -- 入数
-- mod end 1.16
   total_cnt      xxpo_rcv_and_rtn_txns.quantity%TYPE,                    -- 総数
   rtn_uom        xxpo_rcv_and_rtn_txns.rcv_rtn_uom%TYPE,                 -- 単位
   unit_price     xxpo_rcv_and_rtn_txns.kobki_converted_unit_price%TYPE,  -- 単価
   amount_pay     NUMBER,                                                 -- 仕入金額
   deliver_dist   mtl_categories_b.segment1%TYPE,                         -- 納入先(納入先コード)
   po_attr15      po_lines_all.attribute15%TYPE,                          -- 摘要
   order_loc_cd   hr_locations_all.location_code%TYPE,
   display_1      VARCHAR2(440)
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;           -- 営業単位
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;    -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;         -- 担当者
  gv_user_vendor            xxpo_per_all_people_f_v.attribute4%TYPE;         -- 仕入先コード
  gv_user_vendor_site       xxpo_per_all_people_f_v.attribute6%TYPE;         -- 仕入先サイトコード
--
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  gn_user_vendor_id         po_vendors.vendor_id%TYPE;
--
-- 2008/12/24 v1.20 ADD START
  gv_sysdate                VARCHAR2(240) ;  -- システム現在日付
-- 2008/12/24 v1.20 ADD END
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(15) ;    -- 帳票ID
  gd_exec_date              DATE         ;    -- 実施日
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
  ------------------------------
  -- ルックアップ用
  ------------------------------
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
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(vendor_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_vendor_code IN vendor_code_type
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
    FOR ln_cnt IN 1..itbl_vendor_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_vendor_code(ln_cnt) || ''',';
    END LOOP vendor_code_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(art_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement (
      itbl_art_code IN art_code_type
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
    <<art_code_type_loop>>
    FOR ln_cnt IN 1..itbl_art_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_art_code(ln_cnt) || ''',';
    END LOOP art_code_type_loop;
--
    RETURN(
      SUBSTR(lv_in,gn_one,LENGTH(lv_in) - gn_one));
--
  END fnc_get_in_statement;
--
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
    iv_name              IN        VARCHAR2,   --   タグネーム
    iv_value             IN        VARCHAR2,   --   タグデータ
    ic_type              IN        CHAR       --   タグタイプ
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
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(E-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
      ir_param      IN     rec_param_data,    -- 01.入力パラメータ群
      ov_errbuf     OUT    VARCHAR2,          --    エラー・メッセージ           --# 固定 #
      ov_retcode    OUT    VARCHAR2,          --    リターン・コード             --# 固定 #
      ov_errmsg     OUT    VARCHAR2           --    ユーザー・エラー・メッセージ --# 固定 #
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
    lv_err_code           VARCHAR2(100) ; -- エラーコード格納用
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
      lv_err_code := 'APP-XXPO-00005' ;
      lv_retcode  := gv_status_error ;
      RAISE get_value_expt ;
    END IF ;
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
    -- 仕入先コード・仕入先サイトコード取得
    -- ====================================================
    BEGIN
      SELECT  xssv.vendor_code
             ,xssv.vendor_site_code
             ,vnd.vendor_id
        INTO  gv_user_vendor
             ,gv_user_vendor_site
             ,gn_user_vendor_id
        FROM  xxpo_security_supply_v xssv
             ,xxcmn_vendors2_v       vnd
       WHERE  xssv.vendor_code    = vnd.segment1 (+)
         AND  xssv.user_id        = gn_user_id
         AND  xssv.security_class = ir_param.security_flg
         AND  ir_param.deliver_from BETWEEN vnd.start_date_active(+)
         AND  vnd.end_date_active(+) ;
--
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                              ,'APP-XXCMN-10001'
                                              ,'TABLE'
                                              ,gv_seqrt_view
                                              ,'KEY'
                                              ,gv_seqrt_view_key ) ;
        lv_retcode  := gv_status_error ;
        RAISE get_value_expt ;
    END;
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
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(E-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
    ir_param      IN  rec_param_data,
    ot_data_rec   OUT NOCOPY tab_data_type_dtl,  -- 02.取得レコード群
    ov_errbuf     OUT VARCHAR2,                  --    エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                  --    リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                   --    ユーザー・エラー・メッセージ --# 固定 #
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
    cv_sts_num_1       CONSTANT VARCHAR2(1)  := '1';
    cn_sts_num_zero    CONSTANT NUMBER(1)    :=  0;
    cn_sts_num         CONSTANT NUMBER(2)    := -1;
    cv_sts_num_2       CONSTANT VARCHAR2(1)  := '2';
    cv_sts_num_3       CONSTANT VARCHAR2(1)  := '3';
    cv_sts_num_5       CONSTANT VARCHAR2(1)  := '5';
    cv_sts_var_n       CONSTANT VARCHAR2(1)  := 'N';
    cv_sts_var_y       CONSTANT VARCHAR2(1)  := 'Y';
    cv_sts_athrtn_sts  CONSTANT VARCHAR2(8)  := 'APPROVED';
    cv_money_fix       CONSTANT VARCHAR2(2)  := '35';
    cv_cancel          CONSTANT VARCHAR2(2)  := '99';
    cv_comm_division   CONSTANT VARCHAR2(20) := '商品区分';
    cv_item_division   CONSTANT VARCHAR2(20) := '品目区分';
    cv_crowd_cd        CONSTANT VARCHAR2(20) := '群コード';
    cv_per             CONSTANT VARCHAR2(1)  := '%';
--
    -- *** ローカル・変数 ***
    lv_comm_where VARCHAR2(32000) DEFAULT NULL;
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order      VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
    lv_in         VARCHAR2(1000)  ;
    lv_select_1   VARCHAR2(32000);
    lv_from_1     VARCHAR2(32000);
    lv_where_1    VARCHAR2(32000);
--
    -- *** ローカル・カーソル ***
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
    -- ==================================================================
    -- 共通WHERE
    -- ==================================================================
    -- --------------------------------------
    -- パラメータ：取引先が入力済
    -- --------------------------------------
    IF ( ir_param.vendor_code.COUNT = gn_one ) THEN
      -- 1件のみ
      lv_comm_where := lv_comm_where
               || ' AND rcrt.vendor_id  = ''' || ir_param.vendor_code( gn_one ) || '''';
    ELSIF ( ir_param.vendor_code.COUNT > gn_one ) THEN
      -- 1件以上
      lv_in    := fnc_get_in_statement(ir_param.vendor_code);
      lv_comm_where := lv_comm_where
               || ' AND rcrt.vendor_id IN (' || lv_in || ' ) ';
    ELSE
      NULL;
    END IF;
--
    -- --------------------------------------
    -- パラメータ：品目が入力済
    -- --------------------------------------
    IF (ir_param.art_code.COUNT = gn_one) THEN
      -- 1件のみ
      lv_comm_where := lv_comm_where
               || ' AND rcrt.item_code  = ''' || ir_param.art_code( gn_one ) || '''';
    ELSIF (ir_param.art_code.COUNT > gn_one) THEN
      -- 1件以上
      lv_in    := fnc_get_in_statement( ir_param.art_code );
      lv_comm_where := lv_comm_where
               || ' AND rcrt.item_code IN ( ' || lv_in || ' ) ';
    ELSE
      NULL;
    END IF;
--
    -- ============================================================================================
    -- < 品目カテゴリ(商品区分) > --
    -- ============================================================================================
    -- --------------------------------
    -- パラメータ：商品区分が入力済
    -- ---------------------------------
    IF ( ir_param.item_division IS NOT NULL) THEN
      lv_comm_where := lv_comm_where
               || ' AND ctgg.category_code = ''' || ir_param.item_division || '''';
    END IF;
--
    -- ============================================================================================
    -- < 品目カテゴリ(品目区分) > --
    -- ============================================================================================
    -- ---------------------------------------
    -- パラメータ：品目区分が入力済
    -- ---------------------------------------
    IF ( ir_param.art_division IS NOT NULL) THEN
      lv_comm_where := lv_comm_where
               || ' AND ctgi.category_code = ''' || ir_param.art_division || '''';
    END IF;
--
    -- ============================================================================================
    -- < 品目カテゴリ(群) > --
    -- ===========================================================================================
--
    -- 入力状態
    -- すべて入力済み
    IF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || '''))';
    -- 群1のみ入力済み
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )';
    -- 群2のみ入力済み
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )';
    -- 群3のみ入力済み
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' )';
    -- 群1と群2が入力済
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' ))';
    -- 群1と群3が入力済み
    ELSIF (( ir_param.crowd1 IS NOT NULL ) AND ( ir_param.crowd2 IS NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd1 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' ))';
    -- 群2と群3が入力済み
    ELSIF (( ir_param.crowd1 IS NULL ) AND ( ir_param.crowd2 IS NOT NULL)
     AND   ( ir_param.crowd3 IS NOT NULL )) THEN
       lv_comm_where := lv_comm_where
                || ' AND ((ctgc.category_code LIKE ''' || ir_param.crowd2 || ''' || '''
                || '' || cv_per || ''' )'
                || '  OR  (ctgc.category_code LIKE ''' || ir_param.crowd3 || ''' || '''
                || '' || cv_per || ''' ))';
    END IF;
--
    -- ============================================
    -- SELECT句生成
    -- ============================================
    lv_select := ' SELECT '
              || ' ctgg.category_code         AS  category_cd, '        -- 商品区分コード
              || ' ctgg.category_description  AS  category_desc, ';     -- 商品区分名
--
    -- ------------------------------------------
    -- パラメータ：担当部署がZZZZだった場合
    -- ------------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_select := lv_select
                || ' NULL AS loc_cd, ';
    ELSE
      lv_select := lv_select
-- 2010/01/06 H.Itou Mod Start 本稼動障害#862 常に受入返品の部署コード
--                || ' CASE WHEN ( rcrt.txns_type = ''' || cv_sts_num_3 || ''' ) '
--                || ' THEN rcrt.department_code '
--                || ' ELSE xlv.location_code '
--                || ' END AS loc_cd, ';                     -- 部署コード
                || ' rcrt.department_code AS loc_cd, ';                     -- 部署コード
-- 2010/01/06 Mod End
    END IF;
--
    -- -----------------------------------------
    -- パラメータ：担当部署がZZZZだった場合
    -- -----------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_select := lv_select
                || ' NULL AS loc_name, ';
    ELSE
      lv_select := lv_select
-- 2010/01/06 H.Itou Mod Start 本稼動障害#862 発注あり返品は正式名出力
--                || ' CASE WHEN ( rcrt.txns_type = ''' || cv_sts_num_3 || ''' ) '
                || ' CASE WHEN ( rcrt.txns_type = ''' || cv_sts_num_2 || ''' ) '
-- 2010/01/06 Mod End
                || ' THEN xlv.location_name '
                || ' ELSE xlv.description '
                || ' END AS  loc_name, ';                            -- 部署名
    END IF;
--
    lv_select := lv_select
              || ' xvv.segment1               AS  xv_seg1, '         -- 取引先コード
              || ' xvv.vendor_short_name      AS  vend_shrt_nm, '    -- 取引先名
              || ' ctgi.category_code         AS  category_cd2, '    -- 品目区分コード
              || ' ctgi.category_description  AS  category_desc2,'   -- 品目区分名
-- 2008/12/24 v1.20 UPDATE START
--              || ' ximv.old_crowd_code        AS  old_crw_cd, '      -- 群
              || ' CASE '
              || '   WHEN NVL(ximv.crowd_start_date, ''' || gv_sysdate || ''' ) '
              || '          <= ''' || gv_sysdate || ''' THEN '
              || '     ximv.new_crowd_code ' -- 新・群コード
              || '   ELSE '
              || '     ximv.old_crowd_code ' -- 旧・群コード
              || ' END AS crw_cd, '                                  -- 群
-- 2008/12/24 v1.20 UPDATE END
              || ' ximv.item_no               AS  item_no, '         -- 品目(品目コード
              || ' ximv.item_short_name       AS  item_sht_nm, '     -- 品目(品目名)
              || ' pla.attribute3             AS  po_attr3, '        -- 付帯
              || ' rcrt.txns_date             AS  txns_date, '       -- 納入日
              || ' DECODE(ximv.lot_ctl,'      || gv_lot_n_div
              || '  ,NULL,ilm.lot_no)        AS lot_no, '            -- ロットNO
              || ' ilm.attribute1             AS  ic_attr1, '        -- 製造日
              || ' ilm.attribute2             AS  ic_attr2, '        -- 固有記号
              || ' ilm.attribute3             AS  ic_attr3, '        -- 賞味期限
              || ' CASE WHEN '
              || ' ( rcrt.txns_type = ''' || cv_sts_num_1 || ''' ) '
              || ' THEN rcrt.source_document_number '                -- 元文書番号
              || ' WHEN rcrt.txns_type = ''' || cv_sts_num_2 || ''''
              || ' THEN rcrt.rcv_rtn_number '                        -- 受入返品番号
              || ' ELSE NULL '
              || ' END AS order_no, '                                -- 発注No
              || ' xvsv.vendor_site_code      AS factry_code,'
              || ' TO_NUMBER(pla.attribute4)  AS in_cnt,'            -- 在庫入数
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' (rcrt.rcv_rtn_quantity * '  || cn_sts_num   || ' ),'
              || ' rcrt.rcv_rtn_quantity )    AS   total_cnt,'                  -- 数量
              || ' rcrt.rcv_rtn_uom           AS   rtn_uom, '                   -- 単位
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) AS   unit_price, '                -- 単価
-- 2008/12/08 T.Yoshimoto Mod Start 本番障害#597
-- 2008/12/08 H.Itou Mod Start 本番障害#551
              || ' ROUND(DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , ( rcrt.quantity * ' || cn_sts_num || ' ) '
              || ' , rcrt.quantity ) * '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) , '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
              || ' , ( rcrt.quantity * ' || cn_sts_num || ' ) '
              || ' , rcrt.quantity ) * '
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.kobki_converted_unit_price,'
              || ' pla.unit_price) ), ' || cn_sts_num_zero
--              || ' ROUND(DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
--              || ' , DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
--              || ' , ( rcrt.rcv_rtn_quantity * ' || cn_sts_num || ' ) '
--              || ' , rcrt.rcv_rtn_quantity ) * '
--              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
--              || ' rcrt.kobki_converted_unit_price,'
--              || ' pla.unit_price) , '
--              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''''
--              || ' , ( rcrt.rcv_rtn_quantity * ' || cn_sts_num || ' ) '
--              || ' , rcrt.rcv_rtn_quantity ) * '
--              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
--              || ' rcrt.kobki_converted_unit_price,'
--              || ' pla.unit_price) ), ' || cn_sts_num_zero
-- 2008/12/08 H.Itou Mod End
-- 2008/12/08 T.Yoshimoto Mod End 本番障害#597
              || ' ) AS amount_pay, '                                   -- 仕入金額
              || ' xilv.segment1 AS deliver_dist,'                      -- 保管倉庫コード
-- mod start 1.16
--              || ' pla.attribute15   AS   po_attr15, '                  -- 摘要
              || ' DECODE( rcrt.txns_type, ''' || cv_sts_num_2 || ''','
              || ' rcrt.line_description,'
              || ' pla.attribute15)  AS   po_attr15, '                  -- 摘要
-- mod end 1.16
              || ' xlv.location_code AS   order_loc_cd,';
--
    -- ------------------------------------
    -- パラメータ：品目区分が５の場合
    -- ------------------------------------
    IF ( ir_param.art_division = cv_sts_num_5 ) THEN
      lv_select := lv_select
                || ' ilm.attribute1 || ilm.attribute2 AS display_1 ';
    ELSE
      lv_select := lv_select
                || ' ilm.lot_no AS display_1 ';
    END IF;
--
    -- ===========================================================
    -- FROM句生成
    -- ===========================================================
    lv_from := ' FROM '
            || ' xxpo_rcv_and_rtn_txns     rcrt, '   -- 受入返品実績（アドオン）
            || ' po_lines_all              pla, '    -- 発注明細
            || ' po_headers_all            pha, '    -- 発注ヘッダ
            || ' xxpo_headers_all          xha, '    -- 発注ヘッダ（アドオン）
            || ' po_line_locations_all     plla, '   -- 発注納入明細
            || ' xxcmn_item_mst2_v         ximv, '   -- OPM品目情報VIEW2
            || ' xxcmn_item_locations2_v   xilv, '   -- OPM保管場所情報VIEW2
            || ' xxcmn_vendors2_v          xvv, '    -- 仕入先情報VIEW2
            || ' xxcmn_vendor_sites2_v     xvsv, '   -- 仕入先サイト情報VIEW2
            || ' ic_lots_mst               ilm, '    -- OPMロットマスタ
            || ' xxcmn_locations2_v        xlv, '    -- 事業所情報VIEW2
            -- XXPOカテゴリ情報VIEW（商品）
            || ' ( SELECT  gic.item_id      AS item_id '
            || '          ,mcb.segment1     AS category_code '
            || '          ,mct.description  AS category_description'
            || '     FROM  gmi_item_categories   gic, '
            || '           mtl_category_sets_tl  mcst, '
            || '           mtl_category_sets_b   mcsb, '
            || '           mtl_categories_b      mcb, '
            || '           mtl_categories_tl     mct '
            || '    WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '      AND  mcst.language          = ''' || gv_language || ''''
            || '      AND  mcsb.structure_id      = mcb.structure_id '
            || '      AND  mcb.category_id        = mct.category_id '
            || '      AND  gic.category_id        = mcb.category_id'
            || '      AND  gic.category_set_id    = mcsb.category_set_id'
            || '      AND  mct.language           = ''' || gv_language || ''''
            || '      AND  mcst.category_set_name = ''' || cv_comm_division || '''' || ') ctgg '
            -- XXPOカテゴリ情報VIEW（品目）
            || ' ,( SELECT  gic.item_id      AS item_id '
            || '           ,mcb.segment1     AS category_code '
            || '           ,mct.description  AS category_description'
            || '      FROM  gmi_item_categories   gic, '
            || '            mtl_category_sets_tl  mcst, '
            || '            mtl_category_sets_b   mcsb, '
            || '            mtl_categories_b      mcb, '
            || '            mtl_categories_tl     mct '
            || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '       AND  mcst.language          = ''' || gv_language || ''''
            || '       AND  mcsb.structure_id      = mcb.structure_id '
            || '       AND  mcb.category_id        = mct.category_id '
            || '       AND  gic.category_id        = mcb.category_id'
            || '       AND  gic.category_set_id    = mcsb.category_set_id'
            || '       AND  mct.language           = ''' || gv_language || ''''
            || '       AND  mcst.category_set_name = ''' || cv_item_division || '''' || ') ctgi '
            -- XXPOカテゴリ情報VIEW（群コード）
            || ' ,( SELECT  gic.item_id   AS item_id '
            || '           ,mcb.segment1  AS category_code '
            || '      FROM  gmi_item_categories   gic, '
            || '            mtl_category_sets_tl  mcst, '
            || '            mtl_category_sets_b   mcsb, '
            || '            mtl_categories_b      mcb, '
            || '            mtl_categories_tl     mct '
            || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || '       AND  mcst.language          = ''' || gv_language || ''''
            || '       AND  mcsb.structure_id      = mcb.structure_id '
            || '       AND  mcb.category_id        = mct.category_id '
            || '       AND  gic.category_id        = mcb.category_id'
            || '       AND  gic.category_set_id    = mcsb.category_set_id'
            || '       AND  mct.language           = ''' || gv_language || ''''
            || '       AND  mcst.category_set_name = ''' || cv_crowd_cd || '''' || ') ctgc ';
--
    -- ===========================================================
    -- WHERE句生成
    -- ===========================================================
    lv_where := ' WHERE '
             || '     pha.org_id      =  ' || gn_sales_class
             || ' AND pha.segment1    = rcrt.source_document_number '   -- 元文書番号
             || ' AND pha.segment1    = xha.po_header_number '          -- 発注番号
-- 2009/09/24 v1.22 T.Yoshimoto Del Start 本番#1523
             --|| ' AND pha.authorization_status  = ''' || cv_sts_athrtn_sts || ''''
-- 2009/09/24 v1.22 T.Yoshimoto Del End 本番#1523
             || ' AND pha.attribute1 >= ''' || cv_money_fix || ''''     -- 発注ステータス(DFF)
             || ' AND pha.attribute1 <  ''' || cv_cancel    || ''''
-- 2009/03/30 v1.11 ADD START
             || ' AND pha.org_id      = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.11 ADD END
             || ' AND rcrt.txns_date BETWEEN ''' || ir_param.deliver_from || ''' AND '''
             || ir_param.deliver_to || '''';
--
    -- ---------------------------------------
    -- パラメータ：担当部署が入力済
    -- ---------------------------------------
    IF ( ir_param.dept_code <> gv_dept_cd_all ) THEN
      IF ( ir_param.dept_code IS NOT NULL ) THEN
        lv_where := lv_where
                 || ' AND ((pha.attribute10 = '''       || ir_param.dept_code || ''')'
                 || '  OR  ( rcrt.department_code = ''' || ir_param.dept_code || '''))';
      END IF;
    END IF;
--
    -- ============================================================================================
    -- < 発注明細＆発注納入明細 > --
    -- ============================================================================================
    lv_where := lv_where
             || ' AND pha.po_header_id  =   pla.po_header_id '                -- 発注ヘッダID
             || ' AND pla.line_num      =   rcrt.source_document_line_num '   -- 明細番号
             || ' AND pla.po_line_id    =   plla.po_line_id '                 -- 発注明細ID
             || ' AND pla.cancel_flag   = '''    || cv_sts_var_n || ''''      -- 取消フラグ
             || ' AND pla.attribute14   = '''    || cv_sts_var_y || ''''      -- 金額確定フラグ
             || ' AND (( rcrt.txns_type = '''    || cv_sts_num_1 || ''' ) '
             || '  OR  ( rcrt.txns_type = ''' || cv_sts_num_2 || ''' )'
             || ' AND ( rcrt.quantity > ' || cn_sts_num_zero || ' )) '        -- 数量
    -- ============================================================================================
    -- 適用日管理対象マスタの絞込み
    -- ============================================================================================
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN ximv.start_date_active AND ximv.end_date_active'
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xvv.start_date_active AND xvv.end_date_active'
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xvsv.start_date_active AND xvsv.end_date_active '
             || ' AND ''' || ir_param.deliver_from || ''''
             || ' BETWEEN xlv.start_date_active AND xlv.end_date_active '
             || ' AND xilv.date_from <= ''' || ir_param.deliver_from || ''''
             || ' AND (( xilv.date_to >= ''' || ir_param.deliver_from || ''' )'
             || '  OR ( xilv.date_to IS NULL )) '
    -- ============================================================================================
    -- < ロット＆品目 > --
    -- ============================================================================================
             || ' AND rcrt.item_id      =  ilm.item_id(+) '                  -- 品目ID
             || ' AND rcrt.lot_id       =  ilm.lot_id(+) '                   -- ロットID
             || ' AND rcrt.item_id      =  ximv.item_id '                    -- 品目ID
    -- ============================================================================================
    -- < 部署 > --
    -- ============================================================================================
-- 2010/01/06 H.Itou Mod Start 本稼動障害#892 受入返品の部署コードが最新なので、受入返品で結合する。
--             || ' AND pha.attribute10       =   xlv.location_code '      -- 部署コード:attr10
             || ' AND rcrt.department_code   = xlv.location_code '      -- 部署コード:受入返品の部署コード
-- 2010/01/06 H.Itou Mod End
    -- ============================================================================================
    -- < 取引先 > --
    -- ============================================================================================
             || ' AND rcrt.vendor_id    =   xvv.vendor_id '
    -- ============================================================================================
    -- < 入庫倉庫> --
    -- ============================================================================================
             || ' AND pha.attribute5    =   xilv.segment1(+) '         -- 納入先コード:attr5
    -- ============================================================================================
    -- < 工場 > --
    -- ============================================================================================
             || ' AND pha.vendor_id          = xvv.vendor_id '
             || ' AND xvsv.vendor_site_code  = pla.attribute2 '       -- 工場コード(DFF)
             || ' AND ctgg.item_id           = ximv.item_id'
             || ' AND ctgi.item_id           = ximv.item_id'
             || ' AND ctgc.item_id           = ximv.item_id'
             || ' AND rcrt.item_id           = ctgg.item_id'
             || ' AND rcrt.item_id           = ctgi.item_id'
             || ' AND rcrt.item_id           = ctgc.item_id';
--
    -- ============================================================================================
    -- < セキュリティ > --
    -- ============================================================================================
    IF ( ir_param.security_flg = cv_sts_num_2 ) THEN
      lv_where := lv_where
               || ' AND (( pha.attribute3 = ''' || gn_user_vendor_id || ''' )';
      IF ( gn_user_vendor_id IS NULL ) THEN
        -- 仕入先IDなし
        lv_where := lv_where
                 || ' OR ((pha.vendor_id IS NULL) ';
      ELSIF ( gn_user_vendor_id IS NOT NULL ) THEN
        lv_where := lv_where
                 || '  OR  ((pha.vendor_id  = ''' || gn_user_vendor_id || ''' )'; -- 斡旋
      END IF;
      IF ( gv_user_vendor_site IS NOT NULL) THEN
        lv_where := lv_where
                 || '  AND  NOT EXISTS(SELECT po_line_id '
                 ||                  ' FROM   po_lines_all pl_sub '
                 ||                  ' WHERE  pl_sub.po_header_id = pha.po_header_id '
                 ||                  ' AND  NVL(pl_sub.attribute2,''*'') '
                 ||                  ' <> '''|| gv_user_vendor_site ||''''
                 ||                  ' ))) ';
      ELSE
        lv_where := lv_where
                   || ' )) ';
      END IF;
    END IF;
--
    -- =======================================================================================
    -- 発注なし仕入返品取得SQL
    -- =======================================================================================
    lv_select_1 := ' SELECT '
                || ' ctgg.category_code          AS  category_cd,'
                || ' ctgg.category_description   AS  category_desc,';
--
      IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
        lv_select_1 := lv_select_1
                || ' NULL                       AS  loc_cd, '
                || ' NULL                       AS  loc_name,';
      ELSE
        lv_select_1 := lv_select_1
                || ' rcrt.department_code       AS  loc_cd,'
                || ' xlv.location_name          AS  loc_name,';
      END IF;
--
    lv_select_1 := lv_select_1
                || ' xvv.segment1               AS  xv_seg1,'
                || ' xvv.vendor_short_name      AS  vend_shrt_nm,'
                || ' ctgi.category_code         AS  category_cd2,'
                || ' ctgi.category_description  AS  category_desc2,'
-- 2008/12/24 v1.20 UPDATE START
--                || ' ximv.old_crowd_code        AS  old_crw_cd, '
              || ' CASE '
              || '   WHEN NVL(ximv.crowd_start_date, ''' || gv_sysdate || ''' ) '
              || '          <= ''' || gv_sysdate || ''' THEN '
              || '     ximv.new_crowd_code ' -- 新・群コード
              || '   ELSE '
              || '     ximv.old_crowd_code ' -- 旧・群コード
              || ' END AS crw_cd, '
-- 2008/12/24 v1.20 UPDATE END

                || ' ximv.item_no               AS  item_no,'
                || ' ximv.item_short_name       AS  item_sht_nm,'
                || ' rcrt.futai_code            AS  po_attr3,'
                || ' rcrt.txns_date             AS  txns_date,'
                || ' DECODE(ximv.lot_ctl,'      || gv_lot_n_div
                || '  ,NULL,ilm.lot_no)        AS lot_no, '
                || ' ilm.attribute1             AS  ic_attr1,'
                || ' ilm.attribute2             AS  ic_attr2,'
                || ' ilm.attribute3             AS  ic_attr3,'
                || ' rcrt.rcv_rtn_number        AS  order_no,'
                || ' rcrt.factory_code          AS  factry_code,'
                || ' rcrt.conversion_factor     AS  in_cnt,'
                || ' rcrt.rcv_rtn_quantity * ' || cn_sts_num || ' AS total_cnt,'
                || ' rcrt.rcv_rtn_uom           AS  rtn_uom,'
                || ' rcrt.kobki_converted_unit_price  AS  unit_price,'
-- 2008/12/08 T.Yoshimoto Mod Start 本番障害#597
-- 2008/12/08 H.Itou Mod Start 本番障害#551
                || ' ROUND((( rcrt.quantity * ' || cn_sts_num || ' ) * ( '
                || ' rcrt.kobki_converted_unit_price )),' || cn_sts_num_zero || ' )'
--                || ' ROUND((( rcrt.rcv_rtn_quantity * ' || cn_sts_num || ' ) * ( '
--                || ' rcrt.kobki_converted_unit_price )),' || cn_sts_num_zero || ' )'
-- 2008/12/08 H.Itou Mod End
-- 2008/12/08 T.Yoshimoto Mod End 本番障害#597
                || ' AS amount_pay,'
                || ' rcrt.location_code         AS  deliver_dist,'
                || ' rcrt.line_description      AS  po_attr15,'
                || ' xlv.location_code          AS  order_loc_cd,';
--
    -- ------------------------------------
    -- パラメータ：品目区分が５の場合
    -- ------------------------------------
    IF ( ir_param.art_division = cv_sts_num_5 ) THEN
      lv_select_1 := lv_select_1
                  || ' ilm.attribute1 || ilm.attribute2 AS display_1 ';
    ELSE
      lv_select_1 := lv_select_1
                  || ' ilm.lot_no AS display_1 ';
    END IF;
--
    -- ===========================================================
    -- FROM句生成
    -- ===========================================================
    lv_from_1 := ' FROM '
              || ' xxpo_rcv_and_rtn_txns     rcrt,'
              || ' xxcmn_item_mst2_v         ximv,'
              || ' xxcmn_vendors2_v          xvv,'
              || ' ic_lots_mst               ilm,'
              || ' xxcmn_locations2_v        xlv,'
              -- XXPOカテゴリ情報VIEW（商品）
              || ' ( SELECT  gic.item_id      AS item_id '
              || '          ,mcb.segment1     AS category_code '
              || '          ,mct.description  AS category_description'
              || '     FROM  gmi_item_categories   gic, '
              || '           mtl_category_sets_tl  mcst, '
              || '           mtl_category_sets_b   mcsb, '
              || '           mtl_categories_b      mcb, '
              || '           mtl_categories_tl     mct '
              || '    WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '      AND  mcst.language          = ''' || gv_language || ''''
              || '      AND  mcsb.structure_id      = mcb.structure_id '
              || '      AND  mcb.category_id        = mct.category_id '
              || '      AND  gic.category_id        = mcb.category_id'
              || '      AND  gic.category_set_id    = mcsb.category_set_id'
              || '      AND  mct.language           = ''' || gv_language || ''''
              || '      AND  mcst.category_set_name = ''' || cv_comm_division || '''' || ') ctgg '
               -- XXPOカテゴリ情報VIEW（品目）
              || ' ,( SELECT  gic.item_id      AS item_id '
              || '           ,mcb.segment1     AS category_code '
              || '           ,mct.description  AS category_description'
              || '      FROM  gmi_item_categories   gic, '
              || '            mtl_category_sets_tl  mcst, '
              || '            mtl_category_sets_b   mcsb, '
              || '            mtl_categories_b      mcb, '
              || '            mtl_categories_tl     mct '
              || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '       AND  mcst.language          = ''' || gv_language || ''''
              || '       AND  mcsb.structure_id      = mcb.structure_id '
              || '       AND  mcb.category_id        = mct.category_id '
              || '       AND  gic.category_id        = mcb.category_id'
              || '       AND  gic.category_set_id    = mcsb.category_set_id'
              || '       AND  mct.language           = ''' || gv_language || ''''
              || '       AND  mcst.category_set_name = ''' || cv_item_division || '''' || ') ctgi '
              -- XXPOカテゴリ情報VIEW（群コード）
              || ' ,( SELECT  gic.item_id   AS item_id '
              || '           ,mcb.segment1  AS category_code '
              || '      FROM  gmi_item_categories   gic, '
              || '            mtl_category_sets_tl  mcst, '
              || '            mtl_category_sets_b   mcsb, '
              || '            mtl_categories_b      mcb, '
              || '            mtl_categories_tl     mct '
              || '     WHERE  mcsb.category_set_id   = mcst.category_set_id '
              || '       AND  mcst.language          = ''' || gv_language || ''''
              || '       AND  mcsb.structure_id      = mcb.structure_id '
              || '       AND  mcb.category_id        = mct.category_id '
              || '       AND  gic.category_id        = mcb.category_id'
              || '       AND  gic.category_set_id    = mcsb.category_set_id'
              || '       AND  mct.language           = ''' || gv_language || ''''
              || '       AND  mcst.category_set_name = ''' || cv_crowd_cd || '''' || ') ctgc ';
--
    -- ===========================================================
    -- WHERE句生成
    -- ===========================================================
    lv_where_1 := ' WHERE '
               || '     rcrt.source_document_number IS NULL'
               || ' AND rcrt.txns_date BETWEEN ''' || ir_param.deliver_from || ''' AND '''
               || ir_param.deliver_to || ''''
               || ' AND rcrt.source_document_line_num IS NULL'
               || ' AND  rcrt.quantity > ' || cn_sts_num_zero
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN ximv.start_date_active AND ximv.end_date_active'
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN xvv.start_date_active AND xvv.end_date_active'
               || ' AND ''' || ir_param.deliver_from || ''''
               || ' BETWEEN xlv.start_date_active AND xlv.end_date_active '
               || ' AND rcrt.item_id           = ilm.item_id(+)'
               || ' AND rcrt.lot_id            = ilm.lot_id(+)'
               || ' AND rcrt.item_id           = ximv.item_id'
               || ' AND rcrt.department_code   = xlv.location_code'
               || ' AND rcrt.vendor_id         = xvv.vendor_id'
               || ' AND ctgg.item_id           = ximv.item_id'
               || ' AND ctgi.item_id           = ximv.item_id'
               || ' AND ctgc.item_id           = ximv.item_id'
               || ' AND rcrt.item_id           = ctgg.item_id'
               || ' AND rcrt.item_id           = ctgi.item_id'
               || ' AND rcrt.item_id           = ctgc.item_id';
--
    -- ---------------------------------------
    -- パラメータ：担当部署が入力済
    -- ---------------------------------------
    IF ( ir_param.dept_code <> gv_dept_cd_all ) THEN
      IF ( ir_param.dept_code IS NOT NULL ) THEN
        lv_where_1 := lv_where_1
                 || ' AND  ( rcrt.department_code = ''' || ir_param.dept_code || ''')';
      END IF;
    END IF;
--
    -- ============================================================================================
    -- < セキュリティ > --
    -- ============================================================================================
    IF ( ir_param.security_flg = cv_sts_num_2 ) THEN
      lv_where_1 := lv_where_1
               || ' AND (( rcrt.assen_vendor_id = ''' || gn_user_vendor_id || ''' )';
      IF ( gn_user_vendor_id IS NULL ) THEN
        -- 仕入先IDなし
        lv_where_1 := lv_where_1
                 || ' OR ((rcrt.vendor_id IS NULL) ';
      ELSIF ( gn_user_vendor_id IS NOT NULL ) THEN
        lv_where_1 := lv_where_1
                 || '  OR  ((rcrt.vendor_id  = ''' || gn_user_vendor_id || ''' )'; -- 斡旋
      END IF;
      IF ( gv_user_vendor_site IS NOT NULL) THEN
        lv_where_1 := lv_where_1
                   || '  AND  NOT EXISTS(SELECT xrart_sub.factory_code '
                   ||                  ' FROM   xxpo_rcv_and_rtn_txns xrart_sub '
                   ||                  ' WHERE  xrart_sub.rcv_rtn_number = rcrt.rcv_rtn_number '
                   ||                  ' AND  NVL(xrart_sub.factory_code,''*'') '
                   ||                  ' <> '''|| gv_user_vendor_site ||''''
                   ||                  ' ))) ';
      ELSE
        lv_where_1 := lv_where_1
                 || ' )) ';
      END IF;
    END IF;
--
    -- ===========================================================
    -- ORDER BY句生成
    -- ===========================================================
    lv_order := ' ORDER BY '
             || ' category_cd   ASC, ';        -- 商品区分
--
    -- ----------------------------------------
    -- パラメータ：担当部署がZZZZの場合
    -- ----------------------------------------
    IF ( ir_param.dept_code = gv_dept_cd_all ) THEN
      lv_order := lv_order
               || ' xv_seg1       ASC, '       -- 取引先
               || ' category_cd2  ASC, '       -- 品目区分
-- 2008/12/24 v1.20 UPDATE START
--               || ' old_crw_cd    ASC, '       -- 群
               || ' crw_cd        ASC, '       -- 群
-- 2008/12/24 v1.20 UPDATE END
               || ' item_no       ASC, '       -- 品目コード
               || ' po_attr3      ASC, '       -- 付帯
               || ' txns_date     ASC, '       -- 納入日
               || ' display_1     ASC, '       -- 表示順1
               || ' order_no      ASC  ';
--
    -- -----------------------------------------
    -- パラメータ：担当部署がZZZZ以外の場合
    -- -----------------------------------------
    ELSE
      lv_order := lv_order
               || ' order_loc_cd  ASC, '       -- 部署
               || ' xv_seg1       ASC, '       -- 取引先
               || ' category_cd2  ASC, '       -- 品目区分
-- 2008/12/24 v1.20 UPDATE START
--               || ' old_crw_cd    ASC, '       -- 群
               || ' crw_cd        ASC, '       -- 群
-- 2008/12/24 v1.20 UPDATE END
               || ' item_no       ASC, '       -- 品目コード
               || ' po_attr3      ASC, '       -- 付帯
               || ' txns_date     ASC, '       -- 納入日
               || ' display_1     ASC, '       -- 表示順1
               || ' order_no      ASC  ';
    END IF;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := lv_select || lv_from
           || lv_where  || lv_comm_where
           || ' UNION ALL '
           || lv_select_1 || lv_from_1
           || lv_where_1  || lv_comm_where
           || lv_order ;
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
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( lc_ref%ISOPEN ) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lc_ref%ISOPEN ) THEN
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
--
  /***********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : ＸＭＬデータ作成(E-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
    ir_param          IN  rec_param_data,    -- 01.レコード  ：パラメータ
    ov_errbuf         OUT VARCHAR2,          --    エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,          --    リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2           --    ユーザー・エラー・メッセージ --# 固定 #
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
    lc_break_init           CONSTANT VARCHAR2(100) := '*' ;   -- 初期値
    lc_break_null           CONSTANT VARCHAR2(100) := '**' ;  -- ＮＵＬＬ判定
    lc_flg_y                CONSTANT VARCHAR2(100) := 'Y';
    lc_flg_n                CONSTANT VARCHAR2(100) := 'N';
    lc_num_zero             CONSTANT NUMBER DEFAULT 0;
    lc_num_one              CONSTANT NUMBER DEFAULT 1;
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_good_class           VARCHAR2(100) DEFAULT lc_break_init;   -- 商品区分
    lv_location             VARCHAR2(100) DEFAULT lc_break_init;   -- 部署
    lv_vendor_name          VARCHAR2(100) DEFAULT lc_break_init;   -- 取引先
    lv_item_class           VARCHAR2(100) DEFAULT lc_break_init;   -- 品目区分
    lv_crw_cd               VARCHAR2(100) DEFAULT lc_break_init;   -- 群コード
    lv_futai                VARCHAR2(100) DEFAULT lc_break_init;   -- 付帯コード
    lv_item_no              VARCHAR2(100) DEFAULT lc_break_init;   -- 品目コード
    lv_txns_date            VARCHAR2(100) DEFAULT lc_break_init;   -- 納入日
    lv_flg                  VARCHAR2(1)   DEFAULT lc_break_init;
    ln_total                NUMBER        DEFAULT 0;
    ln_amount               NUMBER        DEFAULT 0;
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
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
    --=====================================================
    prc_get_report_data(
      ir_param      => ir_param,
      ot_data_rec   => gt_main_data,   --    02.取得レコード群
      ov_errbuf     => lv_errbuf,      --    エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,     --    リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg       --    ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- 取得データが０件の場合
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
    END IF ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
--
    -- -----------------------------------------------------
    -- ユーザー開始タグ出力
    -- -----------------------------------------------------
--
-- =====================================================================
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
-- =====================================================================
--
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
--
    -- 実施日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'output_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
--
    -- 担当部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charge_dept';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gv_user_dept, 1, 10);
--
    -- 担当者名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'agent' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gv_user_name, 1, 14);
--
    -- 年月日FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                         SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),1,4);
--
    -- 年月日FROM(月)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),6,2);
--
    -- 年月日FROM(日)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_from,gc_char_d_format),9,2);
--
    -- 年月日TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),1,4);
--
    -- 年月日TO(月)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),6,2);
--
    -- 年月日TO(日)
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value :=
                             SUBSTR(TO_CHAR(ir_param.deliver_to,gc_char_d_format),9,2);
--
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- -----------------------------------------------------
    -- レポートタイトル
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_print_name;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 商品区分ブレイク
      -- =====================================================
      -- 商品区分が切り替わった場合
      IF ( NVL(gt_main_data(i).category_cd, lc_break_null ) <> lv_good_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_good_class <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 群G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 群LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- 担当部署計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- 商品区分計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- 品目区分G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 取引先LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 部署G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 部署LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 商品区分G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品区分LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 商品区分LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 商品区分G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- 商品区分Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 商品区分：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_div_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_cd,1,1);
        -- 商品区分：名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_desc,1,30);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_good_class  := NVL( gt_main_data(i).category_cd, lc_break_null )  ;
        lv_location := lc_break_init ;
      END IF;
--
      -- =====================================================
      -- 部署ブレイク
      -- =====================================================
      -- 部署が切り替わった場合
      IF ( NVL( gt_main_data(i).loc_cd, lc_break_null ) <> lv_location ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_location <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 群G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 群LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
          ------------------------------
          -- 担当部署計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- 品目区分G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 取引先LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 部署G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 部署LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 部署LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_loc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 部署G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_loc' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- 部署Ｇデータタグ出力
        -- -----------------------------------------------------
--
        -- 部署コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).loc_cd,1,4);
--
        -- 部署名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).loc_name,1,20);
--
        -- 部署フラグ(表示判断用)
        IF (ir_param.dept_code = gv_dept_cd_all) THEN
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lc_num_zero;
        ELSE
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'loc_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := lc_num_one;
        END IF;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_location  := NVL( gt_main_data(i).loc_cd, lc_break_null )  ;
        lv_vendor_name := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- 取引先ブレイク
      -- =====================================================
      -- 取引先が切り替わった場合
      IF ( NVL( gt_main_data(i).xv_seg1, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_vendor_name <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 群G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 群LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先計フラグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
          ------------------------------
          -- 品目区分G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 取引先G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 取引先LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 取引先LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vendor' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 取引先G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vendor' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- 取引先Gデータタグ出力
        -- -----------------------------------------------------
--
        -- 取引先：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).xv_seg1,1,4);
--
        -- 取引先：名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).vend_shrt_nm,1,20);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_vendor_name  := NVL( gt_main_data(i).xv_seg1, lc_break_null )  ;
        lv_item_class := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- 品目区分ブレイク
      -- =====================================================
      -- 品目区分が切り替わった場合
      IF ( NVL( gt_main_data(i).category_cd2, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_class <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 群G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 群LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目区分G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 品目区分LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
       -- -----------------------------------------------------
        -- 品目区分G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- 品目区分Gデータタグ出力
        -- -----------------------------------------------------
--
        -- 品目区分：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).category_cd2,1,1);
--
        -- 品目区分：名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR(gt_main_data(i).category_desc2,1,30);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_class  := NVL( gt_main_data(i).category_cd2, lc_break_null )  ;
        lv_crw_cd := lc_break_init ;
--
      END IF;
--
      -- =====================================================
      -- 群コードブレイク
      -- =====================================================
      -- 群コードが切り替わった場合
-- 2008/12/24 v1.20 UPDATE START
--      IF ( NVL( gt_main_data(i).old_crw_cd, lc_break_null ) <> lv_crw_cd ) THEN
      IF ( NVL( gt_main_data(i).crw_cd, lc_break_null ) <> lv_crw_cd ) THEN
-- 2008/12/24 v1.20 UPDATE END
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        lv_flg := lc_flg_n;
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_crw_cd <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 群G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 群LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 群コードLG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_crow' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 群コードG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_crow' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 群コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'crow_id' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2008/12/24 v1.20 UPDATE START
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).old_crw_cd,1,4);
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).crw_cd,1,4);
-- 2008/12/24 v1.20 UPDATE END
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
-- 2008/12/24 v1.20 UPDATE START
--        lv_crw_cd  := NVL( gt_main_data(i).old_crw_cd, lc_break_null )  ;
        lv_crw_cd  := NVL( gt_main_data(i).crw_cd, lc_break_null )  ;
-- 2008/12/24 v1.20 UPDATE END
        lv_item_no := lc_break_init ;
      END IF;
--
      -- =====================================================
      -- 品目コードブレイク
      -- =====================================================
      -- 品目コードが切り替わった場合
      IF ( NVL( gt_main_data(i).item_no, lc_break_null ) <> lv_item_no ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        lv_flg := lc_flg_n;
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_no <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 品目G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 品目LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_goods' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 品目G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_goods' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 品目
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_no,1,7);
--
        -- 品目名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_sht_nm' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_sht_nm,1,20);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_no  := NVL( gt_main_data(i).item_no, lc_break_null )  ;
        lv_futai := lc_break_init ;
      END IF;
--
      -- =====================================================
      --付帯コードブレイク
      -- =====================================================
      -- 付帯コードが切り替わった場合
      IF ( NVL( gt_main_data(i).po_attr3, lc_break_null ) <> lv_futai ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_futai <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          ------------------------------
          -- 付帯G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 付帯LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 付帯LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_futai' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 付帯G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_futai' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 付帯
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_attr3' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).po_attr3,1,1);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_futai  := NVL( gt_main_data(i).po_attr3, lc_break_null )  ;
        lv_txns_date := lc_break_init ;
      END IF;
--
      -- =====================================================
      --納入日ブレイク
      -- =====================================================
      -- 納入日が切り替わった場合
      IF ( TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format) <> lv_txns_date ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_txns_date <> lc_break_init ) THEN
--
          lv_flg := lc_flg_n;
          -- -----------------------------------------------------
          -- 明細LG終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
          ------------------------------
          -- 納入日G終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日LG終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END IF ;
--
        -- -----------------------------------------------------
        -- 納入日LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 納入日G開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
        -- 納入日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'txns_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value :=
                                         TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format);
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_txns_date  := TO_CHAR(gt_main_data(i).txns_date,gc_char_m_format);
      END IF;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
           -- 付帯コードが切り替わった場合
      IF ( lv_flg <> lc_flg_y ) THEN
        -- -----------------------------------------------------
        -- 明細LG開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_line' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
      -- -----------------------------------------------------
      -- 明細G開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- ロットNO
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).lot_no,1,10);
--
     -- 製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'create_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value :=  TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).ic_attr1, gc_char_y_format), gc_char_y_format);
--
      -- 賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'bst_bef_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).ic_attr3, gc_char_y_format), gc_char_y_format);
--
      -- 固有番号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'pucu_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).ic_attr2,1,6);
--
      -- 発注NO
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).order_no,1,12);
--
      -- 工場コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).factry_code,1,4);
--
      -- 入数
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'in_cnt' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).in_cnt;
--
      -- 総数
      IF ( gt_main_data(i).total_cnt IS NOT NULL ) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'total_cnt' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).total_cnt;
      END IF;
--
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'rtn_uom' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).rtn_uom,1,4);
--
      -- 単価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_price;
--
      -- 仕入金額
      IF ( gt_main_data(i).amount_pay IS NOT NULL ) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_pay' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).amount_pay;
      END IF;
--
      -- 納入先(納入先コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_dist' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).deliver_dist,1,4);
--
      -- 摘要
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'recapitulation' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).po_attr15,1,20);
--
      lv_flg := lc_flg_y;
      ln_total := ln_total + gt_main_data(i).total_cnt;
      ln_amount  := ln_amount + gt_main_data(i).amount_pay;
--
      -- -----------------------------------------------------
      -- 明細G終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_line' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    -- -----------------------------------------------------
    -- 明細LG終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_line' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- 納入日G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_txns_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 納入日LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_txns_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 付帯G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_futai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 付帯LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_futai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 品目G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_goods' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_goods' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 群G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_crow' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 群LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_crow' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 取引先計フラグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'vendor_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- 担当部署計フラグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'locations_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- 商品区分計フラグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'goods_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
    ------------------------------
    -- 総合計フラグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_flg' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lc_flg_y;
--
    ------------------------------
    -- 品目区分G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目区分LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 取引先G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vendor' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 取引先LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vendor' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- 部署G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_loc' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 部署LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_loc' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ---------------------------
    -- 総数
    -- ---------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_cnt' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(ln_total,1,19);
    -- ---------------------------
    -- 仕入総合計
    -- ---------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sum_price' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(ln_amount,1,20);
--
    ------------------------------
    -- 商品区分G終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 商品区分LG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- データLG終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-00009' ) ;
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
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain (
      iv_deliver_from      IN    VARCHAR2,  -- 納入日FROM
      iv_deliver_to        IN    VARCHAR2,  -- 納入日TO
      iv_item_division     IN    VARCHAR2,  -- 商品区分
      iv_dept_code         IN    VARCHAR2,  -- 担当部署
      iv_vendor_code1      IN    VARCHAR2,  -- 取引先1
      iv_vendor_code2      IN    VARCHAR2,  -- 取引先2
      iv_vendor_code3      IN    VARCHAR2,  -- 取引先3
      iv_vendor_code4      IN    VARCHAR2,  -- 取引先4
      iv_vendor_code5      IN    VARCHAR2,  -- 取引先5
      iv_art_division      IN    VARCHAR2,  -- 品目区分
      iv_crowd1            IN    VARCHAR2,  -- 群1
      iv_crowd2            IN    VARCHAR2,  -- 群2
      iv_crowd3            IN    VARCHAR2,  -- 群3
      iv_art1              IN    VARCHAR2,  -- 品目1
      iv_art2              IN    VARCHAR2,  -- 品目2
      iv_art3              IN    VARCHAR2,  -- 品目3
      iv_security_flg      IN    VARCHAR2,  -- セキュリティ区分
      ov_errbuf            OUT   VARCHAR2,  -- エラー・メッセージ            # 固定 #
      ov_retcode           OUT   VARCHAR2,  -- リターン・コード              # 固定 #
      ov_errmsg            OUT   VARCHAR2   -- ユーザー・エラー・メッセージ  # 固定 #
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
    lr_param_rec            rec_param_data ;          -- パラメータ受渡し用
    lv_xml_string           VARCHAR2(32000) DEFAULT '*';
    cv_num                  CONSTANT VARCHAR2(1)  := '1';
    ln_vendor_code          NUMBER DEFAULT 0; -- 取引先
    ln_art_code             NUMBER DEFAULT 0; -- 品目
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
-- 2008/12/24 v1.20 ADD START
    -- 群コード適用日付
    gv_sysdate                  := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
-- 2008/12/24 v1.20 ADD END
    -- 帳票出力値格納
    gv_report_id                := 'XXPO360004T';      -- 帳票ID
    gd_exec_date                := SYSDATE;            -- 実施日
--
    -- パラメータ格納
    lr_param_rec.deliver_from   := FND_DATE.STRING_TO_DATE(iv_deliver_from , gc_char_dt_format);
    lr_param_rec.deliver_to     := FND_DATE.STRING_TO_DATE(iv_deliver_to , gc_char_dt_format);
    lr_param_rec.item_division  := iv_item_division;
    lr_param_rec.dept_code      := iv_dept_code;
    lr_param_rec.art_division   := iv_art_division;
    lr_param_rec.crowd1         := iv_crowd1;
    lr_param_rec.crowd2         := iv_crowd2;
    lr_param_rec.crowd3         := iv_crowd3;
    lr_param_rec.security_flg   := iv_security_flg;
--
    -- 取引先１
    IF TRIM(iv_vendor_code1) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code1;
    END IF;
    -- 取引先２
    IF TRIM(iv_vendor_code2) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code2;
    END IF;
    -- 取引先３
    IF TRIM(iv_vendor_code3) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code3;
    END IF;
    -- 取引先４
    IF TRIM(iv_vendor_code4) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code4;
    END IF;
    -- 取引先５
    IF TRIM(iv_vendor_code5) IS NOT NULL THEN
      ln_vendor_code := lr_param_rec.vendor_code.COUNT + 1;
      lr_param_rec.vendor_code(ln_vendor_code) := iv_vendor_code5;
    END IF;
--
    -- 品目１
    IF TRIM(iv_art1) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art1;
    END IF;
    -- 品目２
    IF TRIM(iv_art2) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art2;
    END IF;
    -- 品目３
    IF TRIM(iv_art3) IS NOT NULL THEN
      ln_art_code := lr_param_rec.art_code.COUNT + 1;
      lr_param_rec.art_code(ln_art_code) := iv_art3;
    END IF;
--
    -- =====================================================
    -- 前処理
    -- =====================================================
    prc_initialize (
        ir_param          => lr_param_rec,       -- 入力パラメータ群
        ov_errbuf         => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        ov_retcode        => lv_retcode,         -- リターン・コード             --# 固定 #
        ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data (
       ir_param         => lr_param_rec,       -- 入力パラメータレコード
       ov_errbuf        => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
       ov_retcode       => lv_retcode,         -- リターン・コード             --# 固定 #
       ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <loc_flg>' || cv_num || '</loc_flg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_vendor>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_loc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- ０件メッセージログ出力
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application_po
                                             ,'APP-XXPO-10026'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
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
  PROCEDURE main (
    errbuf                OUT   VARCHAR2,  -- エラーメッセージ
    retcode               OUT   VARCHAR2,  -- エラーコード
    iv_deliver_from       IN    VARCHAR2,  -- 納入日FROM
    iv_deliver_to         IN    VARCHAR2,  -- 納入日TO
    iv_item_division      IN    VARCHAR2,  -- 商品区分
    iv_dept_code          IN    VARCHAR2,  -- 担当部署
    iv_vendor_code1       IN    VARCHAR2,  -- 取引先1
    iv_vendor_code2       IN    VARCHAR2,  -- 取引先2
    iv_vendor_code3       IN    VARCHAR2,  -- 取引先3
    iv_vendor_code4       IN    VARCHAR2,  -- 取引先4
    iv_vendor_code5       IN    VARCHAR2,  -- 取引先5
    iv_art_division       IN    VARCHAR2,  -- 品目区分
    iv_crowd1             IN    VARCHAR2,  -- 群1
    iv_crowd2             IN    VARCHAR2,  -- 群2
    iv_crowd3             IN    VARCHAR2,  -- 群3
    iv_art1               IN    VARCHAR2,  -- 品目1
    iv_art2               IN    VARCHAR2,  -- 品目2
    iv_art3               IN    VARCHAR2,  -- 品目3
    iv_security_flg       IN    VARCHAR2   -- セキュリティ区分
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
    submain (
     iv_deliver_from     =>  iv_deliver_from,   -- 納入日FROM
     iv_deliver_to       =>  iv_deliver_to,     -- 納入日TO
     iv_item_division    =>  iv_item_division,  -- 商品区分
     iv_dept_code        =>  iv_dept_code,      -- 担当部署
     iv_vendor_code1     =>  iv_vendor_code1,   -- 取引先1
     iv_vendor_code2     =>  iv_vendor_code2,   -- 取引先2
     iv_vendor_code3     =>  iv_vendor_code3,   -- 取引先3
     iv_vendor_code4     =>  iv_vendor_code4,   -- 取引先4
     iv_vendor_code5     =>  iv_vendor_code5,   -- 取引先5
     iv_art_division     =>  iv_art_division,   -- 品目区分
     iv_crowd1           =>  iv_crowd1,         -- 群1
     iv_crowd2           =>  iv_crowd2,         -- 群2
     iv_crowd3           =>  iv_crowd3,         -- 群3
     iv_art1             =>  iv_art1,           -- 品目1
     iv_art2             =>  iv_art2,           -- 品目2
     iv_art3             =>  iv_art3,           -- 品目3
     iv_security_flg     =>  iv_security_flg,   -- セキュリティ区分
     ov_errbuf           =>  lv_errbuf,         -- エラー・メッセージ            # 固定 #
     ov_retcode          =>  lv_retcode,        -- リターン・コード              # 固定 #
     ov_errmsg           =>  lv_errmsg          -- ユーザー・エラー・メッセージ  # 固定 #
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
END xxpo360004c ;
/
