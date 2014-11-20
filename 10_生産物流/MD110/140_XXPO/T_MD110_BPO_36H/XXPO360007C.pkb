CREATE OR REPLACE PACKAGE BODY xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(body)
 * Description      : 入出庫差異表
 * MD.050/070       : 仕入（帳票）Issue2.0 (T_MD050_BPO_360)
 *                    仕入（帳票）Issue2.0 (T_MD070_BPO_36H)
 * Version          : 1.11
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_get_sai_code          PROCEDURE : 差異コードを取得する。
 *  prc_initialize            PROCEDURE : 前処理(H-1)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(H-2)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/03    1.0   N.Chinen         新規作成
 *  2008/05/19    1.1   Y.Ishikawa       外部ユーザー時に警告終了になる
 *  2008/05/20    1.2   Y.Majikina       セキュリティ外部倉庫の不具合対応
 *  2008/05/22    1.3   Y.Ishikawa       入力パラメータ差異コードがNULLの場合全データ対象にする。
 *  2008/05/22    1.4   Y.Ishikawa       品目コードの表示不正修正
 *                                       指示数を数量→発注数量(DFF11)に変更
 *  2008/06/10    1.5   Y.Ishikawa       ロットマスタに同じロットNoが存在する場合、
 *                                       2明細出力される
 *  2008/06/17    1.6   I.Higa           xxpo_categories_vを使用しないようにする
 *  2008/06/24    1.7   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/04    1.8   Y.Ishikawa       xxcmn_item_categories4_vを使用しないようにする
 *  2008/11/21    1.9   T.Yoshimoto      統合指摘#703
 *  2009/03/30    1.10  A.Shiina         本番#1346対応
 *  2009/09/24    1.11  T.Yoshimoto      本番#1523対応
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXPO360007C' ;   -- パッケージ名
  gv_print_name             CONSTANT VARCHAR2(20) := '入庫予定表' ;   -- 帳票名
--
  ------------------------------
  -- 差異区分
  ------------------------------
  gv_diff_lookup_type CONSTANT VARCHAR2(20) := 'XXPO_DIFF_REASON';
  gc_sai_syutunyuumi  CONSTANT VARCHAR2(1)  := '1';
  gc_sai_syutumi      CONSTANT VARCHAR2(1)  := '2';
  gc_sai_nyuumi       CONSTANT VARCHAR2(1)  := '3';
  gc_sai_saiari       CONSTANT VARCHAR2(1)  := '4';
  gc_sai_all          CONSTANT VARCHAR2(1)  := '5';
--
  ------------------------------
  -- 差異区分取得用定数
  ------------------------------
  gc_true CONSTANT VARCHAR2(1) := 'Y';
  gv_jpn  CONSTANT VARCHAR2(2) := 'JA';
--
  ------------------------------
  -- セキュリティ区分
  ------------------------------
  gc_seqrt_class_itoen      CONSTANT VARCHAR2(1) := '1';     -- 伊藤園
  gc_seqrt_class_vender     CONSTANT VARCHAR2(1) := '2';     -- 取引先（斡旋者）
  gc_seqrt_class_outside    CONSTANT VARCHAR2(1) := '4';     -- 外部倉庫
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '商品区分' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
  gv_language                   CONSTANT VARCHAR2(3)   := 'JA';             -- 言語
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;           -- アプリケーション（XXPO）
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '有償支給セキュリティVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := 'ユーザーID' ;
  gv_vendor_view          CONSTANT VARCHAR2(20) := '仕入先情報VIEW' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  -- ロット管理区分
  gv_lot_n_div            CONSTANT VARCHAR2(1) := '0'; -- ロット管理なし
--
  -- ロットデフォルト名
  gv_lot_default         CONSTANT ic_lots_mst.lot_no%TYPE  := 'DEFAULTLOT'; --デフォルトロット名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD(
      sai_cd           VARCHAR2(1)                          -- 差異事由
     ,subinv_code      po_headers_all.attribute5%TYPE       -- 保管場所コード
     ,goods_class      mtl_categories_b.segment1%TYPE       -- 商品区分
     ,item_class       mtl_categories_b.segment1%TYPE       -- 品目区分
     ,dlv_from         VARCHAR2(10)                         -- 納品日（ＦＲＯＭ）
     ,dlv_to           VARCHAR2(10)                         -- 納品日（ＴＯ）
     ,ship_code_from   po_vendors.segment1%TYPE             -- 出庫元
     ,order_num        VARCHAR2(100)                        -- 発注番号
     ,item_code        ic_item_mst_b.item_no%TYPE           -- 品目コード
     ,position         xxcmn_locations_v.location_code%TYPE -- 担当部署
     ,seqrt_class      VARCHAR2(1)                          -- セキュリティ区分
    );
--
  -- 入庫予定表データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD(
      h_vendor_code         xxcmn_item_locations_v.segment1%TYPE           -- 見出し:入庫倉庫コード
     ,h_vendor_name         xxcmn_item_locations_v.description%TYPE         -- 見出し:入庫倉庫名
     ,h_deliver_date        po_headers_all.attribute4%TYPE                  -- 納入日
     ,h_goods_code          xxpo_categories_v.category_code%TYPE            -- 見出し:商品区分
     ,h_goods_name          xxpo_categories_v.category_description%TYPE     -- 見出し:商品名
     ,h_item_code           xxpo_categories_v.category_code%TYPE            -- 見出し:品目区分
     ,h_item_name           xxpo_categories_v.category_description%TYPE     -- 見出し:品目名
     ,vendor_code           xxcmn_vendors_v.segment1%TYPE                   -- 出庫元コード
     ,vendor_name           xxcmn_vendors_v.vendor_short_name%TYPE          -- 出庫元名
     ,po_no                 xxpo_requisition_headers.po_header_number%type  -- 発注番号
     ,item_code             xxcmn_item_mst_v.item_no%type                   -- 品目コード
     ,item_name             xxcmn_item_mst_v.item_short_name%type           -- 品目名称
     ,add_code              po_lines_all.attribute3%type                    -- 付帯コード
     ,lot_no                ic_lots_mst.lot_no%type                         -- ロットno
     ,make_date             ic_lots_mst.attribute1%type                     -- 製造日
     ,period_date           ic_lots_mst.attribute3%type                     -- 賞味期限
     ,prop_mark             xxcmn_lookup_values_v.meaning%type              -- 固有記号
     ,inv_qty               po_lines_all.quantity%type                      -- 指示数
     ,ship_qty              po_lines_all.attribute6%type                    -- 出庫数
     ,stock_qty             po_lines_all.attribute7%type                    -- 入庫数
     ,sai_qty               VARCHAR2(16)                                    -- 差異数
     ,order_qty             po_lines_all.attribute11%type              -- 差異コード取得用:発注数量
  );
--
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
--
  -- 外部倉庫
  TYPE subinv_code_type IS TABLE OF
    xxpo_security_supply_v.segment1%TYPE INDEX BY BINARY_INTEGER; -- 保管倉庫コード
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ユーザーＩＤ
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%TYPE ;            -- 営業単位
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- 担当部署
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- 担当者
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;          -- 仕入先コード
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;          -- 仕入先サイトコード
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                        -- 仕入先ID
  gv_diff_reason_name       fnd_lookup_values.meaning%TYPE;                   -- 差異事由名
  gv_subinv_code            subinv_code_type;                          -- 保管倉庫コード
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
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(whse_code)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      itbl_subinv_code IN subinv_code_type
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
    <<subinv_code_loop>>
    FOR ln_cnt IN 1..itbl_subinv_code.COUNT LOOP
      lv_in := lv_in || '''' || itbl_subinv_code(ln_cnt) || ''',';
    END LOOP subinv_code_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  END fnc_get_in_statement;
--
--
  /**********************************************************************************
   * Procedure Name   : prc_get_sai_code
   * Description      : 「全て」で取得した差異コード、差異事由名を取得する。
   ***********************************************************************************/
  PROCEDURE prc_get_sai_code(
      it_data_rec   IN  tab_data_type_dtl  -- 01.取得レコード群
     ,in_count      IN  NUMBER
     ,on_sai_code   OUT NUMBER
     ,ov_sai_reason OUT VARCHAR2
    )
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_get_sai_code' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_ship_qty         po_lines_all.attribute6%type;
    lv_stock_qty        po_lines_all.attribute7%type;
    lv_order_qty        po_lines_all.attribute11%type;
--
  BEGIN
--
    lv_ship_qty := it_data_rec(in_count).ship_qty;
    lv_stock_qty := it_data_rec(in_count).stock_qty;
    lv_order_qty := it_data_rec(in_count).order_qty;
--
    -- 「出入未」の場合
    IF (    (lv_ship_qty IS NULL)
        AND (lv_stock_qty IS NULL)) THEN
      on_sai_code := gc_sai_syutunyuumi;
    END IF;
    -- 「出未」の場合
    IF (    (lv_ship_qty IS NULL)
        AND (lv_stock_qty >= 0)) THEN
      on_sai_code := gc_sai_syutumi;
    END IF;
    -- 「入未」の場合
    IF (    (lv_ship_qty >= 0)
        AND (lv_stock_qty IS NULL)) THEN
      on_sai_code := gc_sai_nyuumi;
    END IF;
    -- 「差異有」の場合
    IF (    (lv_ship_qty IS NOT NULL)
        AND (lv_stock_qty IS NOT NULL)
        AND (   (lv_order_qty - lv_ship_qty != 0)
             OR (lv_order_qty - lv_stock_qty != 0))) THEN
      on_sai_code := gc_sai_saiari;
    END IF;
--
    -- 差異事由名取得
    BEGIN
      SELECT flv.meaning
      INTO   ov_sai_reason
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = gv_diff_lookup_type
      AND    flv.enabled_flag = gc_true
      AND    flv.language = USERENV('LANG')
      AND    flv.source_lang = USERENV('LANG')
      AND    (   (flv.start_date_active IS NULL)
              OR (gd_exec_date >= flv.start_date_active))
      AND    (   (flv.end_date_active IS NULL)
              OR (gd_exec_date <= flv.end_date_active))
      AND    flv.lookup_code = on_sai_code;
    EXCEPTION
      -- データなし
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  END prc_get_sai_code ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : 前処理(H-1)
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
    -- 営業単位取得
    -- ====================================================
    gn_sales_class := FND_PROFILE.VALUE( 'ORG_ID' ) ;
    IF ( gn_sales_class IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
                                            ,'APP-XXPO-00005' ) ;
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
    -- 差異事由名取得
    -- ====================================================
    IF ((ir_param.sai_cd IS NOT NULL ) AND (ir_param.sai_cd <> gc_sai_all)) THEN
      SELECT flv.meaning
      INTO   gv_diff_reason_name
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type = gv_diff_lookup_type
      AND    flv.enabled_flag = gc_true
      AND    flv.language = USERENV('LANG')
      AND    flv.source_lang = USERENV('LANG')
      AND    (   (flv.start_date_active IS NULL)
              OR (gd_exec_date >= flv.start_date_active))
      AND    (   (flv.end_date_active IS NULL)
              OR (gd_exec_date <= flv.end_date_active))
      AND    flv.lookup_code = ir_param.sai_cd;
    END IF;
--
    IF ( ir_param.seqrt_class = gc_seqrt_class_outside ) THEN
      -- ====================================================
      -- 保管倉庫コード取得(複数の場合有)
      -- ====================================================
      BEGIN
        SELECT xssv.segment1
          BULK COLLECT INTO gv_subinv_code
        FROM  xxpo_security_supply_v xssv
        WHERE xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.seqrt_class;
--
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key  ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
      END;
    ELSE
      -- ====================================================
      -- 仕入先コード・仕入先サイトコード取得
      -- ====================================================
      BEGIN
        SELECT xssv.vendor_code
              ,xssv.vendor_site_code
              ,vnd.vendor_id
          INTO gv_user_vender
              ,gv_user_vender_site
              ,gn_user_vender_id
        FROM  xxpo_security_supply_v xssv
             ,xxcmn_vendors2_v       vnd
        WHERE xssv.vendor_code    = vnd.segment1 (+)
          AND xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.seqrt_class
          AND FND_DATE.STRING_TO_DATE( ir_param.dlv_from, gc_char_d_format )
              BETWEEN vnd.start_date_active (+) AND vnd.end_date_active (+) ;
--
      EXCEPTION
        -- データなし
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg( gc_application
                                                ,'APP-XXCMN-10001'
                                                ,'TABLE'
                                                ,gv_seqrt_view
                                                ,'KEY'
                                                ,gv_seqrt_view_key  ) ;
          lv_retcode  := gv_status_error ;
          RAISE get_value_expt ;
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
   * Description      : 明細データ取得(H-2)
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
    cv_item_class       CONSTANT VARCHAR2( 1) := '5';          -- 品目区分（製品）
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';          -- 取消フラグ（取消）
    cv_poh_status       CONSTANT VARCHAR2(10) := 'APPROVED';   -- 発注ステータス（承認済み）
    cv_poh_make         CONSTANT VARCHAR2( 2) := '20';         -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(発注作成済)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';         -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(取消)
--
    -- *** ローカル・変数 ***
    lv_select     VARCHAR2(32000) ;
    lv_from       VARCHAR2(32000) ;
    lv_where      VARCHAR2(32000) ;
    lv_order_by   VARCHAR2(32000) ;
    lv_sql        VARCHAR2(32000) ;     -- データ取得用ＳＱＬ
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
    lv_select := ' SELECT '
              || ' itmv.segment1                AS h_vendor_code'   -- ヘッダ：入庫倉庫コード
              || ',itmv.description             AS h_vendor_name'   -- ヘッダ：入庫倉庫名
              || ',substr(poh.attribute4, 6, 5) AS h_deliver_date'  -- ヘッダ：納入予定日
              || ',ctgg.category_code           AS h_goods_code'  -- ヘッダ：カテゴリコード（商品）
              || ',ctgg.category_description    AS h_goods_name'    -- ヘッダ：カテゴリ摘要（商品）
              || ',ctgi.category_code           AS h_item_code'   -- ヘッダ：カテゴリコード（品目）
              || ',ctgi.category_description    AS h_item_name'     -- ヘッダ：カテゴリ摘要（品目）
              || ',vnd.segment1                   AS vendor_code'      -- 出庫倉庫コード
              || ',vnd.vendor_short_name          AS vendor_name'      -- 出庫倉庫名
              || ',poh.segment1                   AS po_no'            -- 発注番号
              || ',itm.item_no                    AS item_code'        -- 品目コード
              || ',itm.item_short_name            AS item_name'        -- 品目名
              || ',pln.attribute3                 AS add_code'         -- 付帯コード
              || ',DECODE(itm.lot_ctl,'           || gv_lot_n_div
              || '  ,NULL,lot.lot_no)             AS lot_no'          -- ロットＮｏ
              || ',lot.attribute1                 AS make_date'        -- 製造年月日
              || ',lot.attribute3                 AS period_date'      -- 賞味期限
              || ',lot.attribute2                 AS prop_mark'        -- 固有記号
              || ',pln.QUANTITY                   AS inv_qty'          -- 在庫入数
              || ',pln.ATTRIBUTE6                 as ship_qty'         -- 出庫数
              || ',pln.ATTRIBUTE7                 as stock_qty'        -- 入庫数
-- 2008/11/21 v1.9 T.Yoshimoto Mod Start
--              || ',NVL(pln.quantity, 0) - NVL(pln.attribute7, 0)  as sai_qty'   -- 差異数
              || ',NVL(pln.attribute11, 0) - NVL(pln.attribute7, 0)  as sai_qty'   -- 差異数
-- 2008/11/21 v1.9 T.Yoshimoto Mod End
              || ',pln.attribute11                as order_qty'        -- 差異コード取得用:発注数量
              ;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_from := ' FROM '
            || ' po_headers_all                poh'     -- 発注ヘッダ
            || ',po_lines_all                  pln'     -- 発注明細
            || ',ic_lots_mst                   lot'     -- OPMロットマスタ
            || ',xxcmn_vendors2_v              vnd'     -- 仕入先情報VIEW
            || ',xxcmn_item_mst2_v             itm'     -- OPM品目情報VIEW
            || ',xxcmn_item_locations2_v       itmv'    -- OPM保管場所情報VIEW
             -- XXPOカテゴリ情報VIEW（商品）
            || ' ,(SELECT gic.item_id AS item_id '
            || ' ,mcb.segment1  AS category_code '
            || ' ,mct.description  AS category_description'
            || '  FROM   gmi_item_categories    gic, '
            || ' mtl_category_sets_tl  mcst, '
            || ' mtl_category_sets_b   mcsb, '
            || ' mtl_categories_b      mcb, '
            || ' mtl_categories_tl     mct '
            || ' WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || ' AND    mcst.language          = ''' || gv_language || ''''
            || ' AND    mcsb.structure_id      = mcb.structure_id '
            || ' AND    mcb.category_id        = mct.category_id '
            || ' AND    gic.category_id        = mcb.category_id'
            || ' AND    gic.category_set_id    = mcsb.category_set_id'
            || ' AND    mct.language           = ''' || gv_language || ''''
            || ' AND    mcst.category_set_name = ''' || gc_cat_set_goods_class || '''' || ') ctgg '
             -- XXPOカテゴリ情報VIEW（品目）
            || ' ,(SELECT gic.item_id AS item_id '
            || ' ,mcb.segment1  AS category_code '
            || ' ,mct.description  AS category_description'
            || '  FROM   gmi_item_categories    gic, '
            || ' mtl_category_sets_tl  mcst, '
            || ' mtl_category_sets_b   mcsb, '
            || ' mtl_categories_b      mcb, '
            || ' mtl_categories_tl     mct '
            || ' WHERE  mcsb.category_set_id   = mcst.category_set_id '
            || ' AND    mcst.language          = ''' || gv_language || ''''
            || ' AND    mcsb.structure_id      = mcb.structure_id '
            || ' AND    mcb.category_id        = mct.category_id '
            || ' AND    gic.category_id        = mcb.category_id'
            || ' AND    gic.category_set_id    = mcsb.category_set_id'
            || ' AND    mct.language           = ''' || gv_language || ''''
            || ' AND    mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') ctgi '
            ;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || '     poh.org_id               = ' || gn_sales_class
             || ' AND poh.po_header_id         = pln.po_header_id'
-- 2009/09/24 v1.11 T.Yoshimoto Del Start 本番#1523
             --|| ' AND poh.authorization_status = ''' || cv_poh_status  || ''''
-- 2009/09/24 v1.11 T.Yoshimoto Del End 本番#1523
             || ' AND poh.attribute1          >= ''' || cv_poh_make    || ''''
             || ' AND poh.attribute1           < ''' || cv_poh_cancel  || ''''
             || ' AND pln.cancel_flag         <> ''' || cv_pln_cancel_flag   || ''''
             || ' AND poh.attribute4          >= ''' || ir_param.dlv_from    || ''''
-- 2009/03/30 v1.11 ADD START
             || ' AND poh.org_id               = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.11 ADD END
             ;
--
    -- 入庫倉庫が入力されている場合
    IF (ir_param.subinv_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute5           = ''' || ir_param.subinv_code || ''''
               ;
    END IF;
--
    -- 発注番号が入力されている場合
    IF (ir_param.order_num IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.segment1 = ''' || ir_param.order_num || ''''
               ;
    END IF;
--
    -- 担当部署が入力されている場合
    IF (ir_param.position IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.ATTRIBUTE10 = ''' || ir_param.position || ''''
               ;
    END IF;
--
    -- 納入日ＴＯが入力されている場合
    IF (ir_param.dlv_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute4      <= ''' || ir_param.dlv_to || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ロット＆品目の絞込み条件
    lv_where := lv_where
             || ' AND pln.item_id            = itm.inventory_item_id'
             || ' AND itm.item_id            = lot.item_id'
             || ' AND DECODE(itm.lot_ctl,' || gv_lot_n_div   || ','''
                                           || gv_lot_default || ''''
                                           || ',pln.attribute1) = lot.lot_no '
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN itm.start_date_active AND itm.end_date_active'
             ;
    -- 品目が入力されている場合
    IF (ir_param.item_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND itm.item_no          = ''' || ir_param.item_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ（商品区分）の絞込み条件
    lv_where := lv_where
             || ' AND itm.item_id                          = ctgg.item_id'
             ;
    -- 商品区分が入力されている場合
    IF (ir_param.goods_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgg.category_code   = ''' || ir_param.goods_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ（品目区分）の絞込み条件
    lv_where := lv_where
             || ' AND itm.item_id                          = ctgi.item_id'
             ;
    -- 品目区分が入力されている場合
    IF (ir_param.item_class IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND ctgi.category_code   = ''' || ir_param.item_class || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 出庫元の絞込み条件
    lv_where := lv_where
             || ' AND poh.vendor_id          = vnd.vendor_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN vnd.start_date_active AND vnd.end_date_active'
             ;
    -- 出庫元が入力されている場合
    IF (ir_param.ship_code_from IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND vnd.segment1         = ''' || ir_param.ship_code_from || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 入庫倉庫の絞込み条件
    lv_where := lv_where
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from || ''','''
                                                  || gc_char_d_format  || ''') >= itmv.date_from'
             || ' AND (   ( itmv.date_to IS NULL)'
             || '      OR (    (itmv.date_to IS NOT NULL)'
             || '          AND (itmv.date_to >= FND_DATE.STRING_TO_DATE(''' || ir_param.dlv_from
                                                  || ''',''' || gc_char_d_format  || '''))))'
             || ' AND itmv.disable_date IS NULL'
             || ' AND poh.attribute5    = itmv.segment1'
             ;
    ---------------------------------------------------------------------------------------------
    -- 差異事由の絞込み条件
    -- 「出入未」の場合
    IF (ir_param.sai_cd = gc_sai_syutunyuumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NULL '
               || ' AND pln.attribute7 IS NULL '
               ;
    END IF;
--
    -- 「出」の場合
    IF (ir_param.sai_cd = gc_sai_syutumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NULL '
               || ' AND pln.attribute7 >= 0 '
               ;
    END IF;
--
    -- 「入未」の場合
    IF (ir_param.sai_cd =   gc_sai_nyuumi) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 >= 0 '
               || ' AND pln.attribute7 IS NULL '
               ;
    END IF;
--
    -- 「差異有」の場合
    IF (ir_param.sai_cd =   gc_sai_saiari) THEN
      lv_where := lv_where
               || ' AND pln.attribute6 IS NOT NULL '
               || ' AND pln.attribute7 IS NOT NULL '
               || ' AND (   pln.attribute11 - pln.attribute6 != 0 '
               || '      OR pln.attribute11 - pln.attribute7 != 0 ) '
               ;
    END IF;
--
    -- 「全て」の場合
    -- 上記のデータ全てを抽出
    IF (ir_param.sai_cd =   gc_sai_all) THEN
      lv_where := lv_where
               || ' AND (   (    pln.attribute6 IS NULL '
               || '          AND pln.attribute7 IS NULL ) '
               || '      OR (    pln.attribute6 IS NULL '
               || '          AND pln.attribute7 >= 0 ) '
               || '      OR (    pln.attribute6 >= 0 '
               || '          AND pln.attribute7 IS NULL ) '
               || '      OR (    pln.attribute6 IS NOT NULL '
               || '          AND pln.attribute7 IS NOT NULL '
               || '          AND (   (pln.attribute11 - pln.attribute6 != 0) '
               || '               OR (pln.attribute11 - pln.attribute7 != 0)))) '
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- セキュリティ区分の絞込み条件
    -- 「取引先」の場合
    IF (ir_param.seqrt_class = gc_seqrt_class_vender) THEN
      lv_where := lv_where
               || ' AND (   ( poh.attribute3 = ''' || gn_user_vender_id || ''')'
               ;
      -- ログインユーザーの仕入先IDがNULLの場合、発注.仕入先とのチェックを行わない
      IF (gn_user_vender_id IS NULL) THEN
        lv_where := lv_where
                 || '      OR ((poh.vendor_id IS NULL)'
                 ;
      ELSE
        lv_where := lv_where
                 || '      OR ((poh.vendor_id = ' || gn_user_vender_id || ')'
                 ;
      END IF;
      -- ログインユーザーの仕入先サイトコードが設定されている場合
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND NOT EXISTS(SELECT po_line_id '
                 || '                FROM   po_lines_all pl_sub '
                 || '                WHERE  pl_sub.po_header_id = poh.po_header_id '
                 || '                AND    NVL(pl_sub.attribute2, ''*'') <> '''
                                            || gv_user_vender_site || ''''
                 || '                ) '
                 ;
      END IF;
      lv_where := lv_where
               || '))'
               ;
    END IF;
    -- 「外部倉庫」の場合
    IF (ir_param.seqrt_class = gc_seqrt_class_outside) THEN
      IF ( gv_subinv_code.COUNT = 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 = ''' || gv_subinv_code(1) || '''';
      ELSIF ( gv_subinv_code.COUNT > 1 ) THEN
        lv_where := lv_where
          || ' AND itmv.segment1 IN(' || fnc_get_in_statement(gv_subinv_code) || ')';
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || ' itmv.segment1'          -- ヘッダ：入庫倉庫コード
                || ',ctgg.category_code'     -- ヘッダ：カテゴリコード（商品）
                || ',ctgi.category_code'     -- ヘッダ：カテゴリコード（品目）
                || ',poh.attribute4'         -- ヘッダ：納入予定日
                || ',vnd.segment1'           -- 出庫元コード
                || ',poh.segment1'           -- 発注番号
                || ',itm.item_no'            -- 品目コード
                || ',pln.attribute3'         -- 付帯コード
                ;
    -- 品目区分が「製品」の場合、製造年月日||固有記号でソート
    IF ir_param.item_class = cv_item_class THEN
      lv_order_by := lv_order_by
                  || ',lot.attribute1||lot.attribute2'
                  ;
    ELSE
      lv_order_by := lv_order_by
                  || ',lot.lot_no'
                  ;
    END IF;
--
    -- ====================================================
    -- ＳＱＬ生成
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where || lv_order_by ;
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
    -- 日付年月日取得Format
    lc_dlv_y                VARCHAR2(4) DEFAULT 'YYYY' ;           -- 年取得
    lc_dlv_m                VARCHAR2(2) DEFAULT 'MM' ;             -- 月取得
    lc_dlv_d                VARCHAR2(2) DEFAULT 'DD' ;             -- 日取得
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_vendor_name          VARCHAR2(100) DEFAULT lc_break_init ;  -- 取引先名
    lv_goods_class          VARCHAR2(100) DEFAULT lc_break_init ;  -- 商品区分
    lv_item_class           VARCHAR2(100) DEFAULT lc_break_init ;  -- 品目区分
    lv_deliver_date         VARCHAR2(100) DEFAULT lc_break_init ;  -- 納入日
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- 品目コード
    lv_futai                VARCHAR2(100) DEFAULT lc_break_init ;  -- 付帯
    lv_ship_from_code       VARCHAR2(100) DEFAULT lc_break_init ;  -- 出庫元
    lv_po_no                VARCHAR2(100) DEFAULT lc_break_init ;  -- 発注Ｎｏ
    lv_sai_code             VARCHAR2(100);
    lv_sai_reason           VARCHAR2(100);
--
    -- 計算用
    ln_position             NUMBER        DEFAULT 0 ;              -- 計算用：ポジション
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
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
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- ユーザーＧデータタグ出力
    -- -----------------------------------------------------
--
    -- 帳票ＩＤ
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_id' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id ;
    -- 実施日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format ) ;
    -- 担当部署
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_dept' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_dept, 1, 10) ;
    -- 担当者名
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_user_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_user_name, 1, 14) ;
    -- -----------------------------------------------------
    -- 納入日Ｇ FROM年データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_y);
    -- -----------------------------------------------------
    -- 納入日Ｇ FROM月データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_m);
    -- -----------------------------------------------------
    -- 納入日Ｇ FROM日データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'from_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_from,gc_char_dt_format) ,lc_dlv_d);
    -- -----------------------------------------------------
    -- 納入日Ｇ TO年データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_year' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_y);
    -- -----------------------------------------------------
    -- 納入日Ｇ TO月データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_month' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_m);
    -- -----------------------------------------------------
    -- 納入日Ｇ TO日データタグ出力
    -- -----------------------------------------------------
    -- 納入日
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'to_date' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                      ir_param.dlv_to,gc_char_dt_format) ,lc_dlv_d);
    -- -----------------------------------------------------
    -- ユーザーＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/user_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- データＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 取引先ＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 取引先名称ブレイク
      -- =====================================================
      -- 取引先名称が切り替わった場合
      IF ( NVL( gt_main_data(i).h_vendor_name, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_vendor_name <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品区分ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 取引先Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 取引先Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_locat' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 取引先Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 入庫倉庫：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_vendor_code ;
        -- 入庫倉庫：略称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'locat_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_vendor_name, 1, 20 );
        ------------------------------
        -- 商品区分ＬＧ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_vendor_name  := NVL( gt_main_data(i).h_vendor_name, lc_break_null )  ;
        lv_goods_class  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 商品区分ブレイク
      -- =====================================================
      -- 商品区が切り替わった場合
      IF ( NVL( gt_main_data(i).h_goods_code, lc_break_null ) <> lv_goods_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_goods_class <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 商品区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        ------------------------------
        -- 商品区分Ｇ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 商品区分データタグ出力
        -- -----------------------------------------------------
        -- 商品区分コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_goods_code ;
        -- 商品区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'prod_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_goods_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- 品目区分ＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_goods_class  := NVL( gt_main_data(i).h_goods_code, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 品目区分ブレイク
      -- =====================================================
      -- 品目区分が切り替わった場合
      IF ( NVL( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 品目区分Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 品目区分データタグ出力
        -- -----------------------------------------------------
        -- 品目区分コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_item_code ;
        -- 品目区分名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_div_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).h_item_name, 1, 30 ) ;
        -- -----------------------------------------------------
        -- 品目ＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_class   := NVL( gt_main_data(i).h_item_code, lc_break_null )  ;
        lv_deliver_date := lc_break_init;
--
      END IF ;
--
      -- =====================================================
      -- 納入日ブレイク
      -- =====================================================
      -- 納入日が切り替わった場合
      IF ( NVL( TO_CHAR(gt_main_data(i).h_deliver_date), lc_break_null ) <> lv_deliver_date ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_deliver_date <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 納入日Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 納入日Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_deliver' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 納入日タグ出力
        -- -----------------------------------------------------
        -- 納入日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'deliver_to_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).h_deliver_date ;
        -- -----------------------------------------------------
        -- 出庫明細ＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_deliver_date := NVL( TO_CHAR(gt_main_data(i).h_deliver_date), lc_break_null )  ;
        lv_item_code    := lc_break_init ;
        -- 集計変数０クリア
        ln_position     := 0 ;  -- 計算用：ポジション
--
      END IF ;
--
      -- =====================================================
      -- 品目ブレイク
      -- =====================================================
      -- 品目が切り替わった場合
      IF ( NVL( TO_CHAR(gt_main_data(i).item_code), lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_code <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 品目Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 品目データタグ出力
        -- -----------------------------------------------------
        -- ポジション
        ln_position := ln_position + 1;
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'position' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( ln_position ) ;
        -- 品目コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
        -- 品目名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_name, 1, 20 ) ;
        -- -----------------------------------------------------
        -- 出庫明細ＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_code    := NVL( TO_CHAR(gt_main_data(i).item_code), lc_break_null )  ;
        lv_futai        := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 付帯ブレイク
      -- =====================================================
      -- 付帯が切り替わった場合
      IF ( NVL( gt_main_data(i).add_code, lc_break_null ) <> lv_futai ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_futai <> lc_break_init ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫ヘッダＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 出庫明細Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 出庫明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_dtl' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 明細データタグ出力
        -- -----------------------------------------------------
        -- 付帯コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'futai_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).add_code ;
        -- -----------------------------------------------------
        -- 出庫ヘッダＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_futai          := NVL( gt_main_data(i).add_code, lc_break_null )  ;
        lv_ship_from_code := lc_break_init ;
        lv_po_no          := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- 出庫ヘッダブレイク
      -- =====================================================
      -- 出庫元または発注ＮＯが切り替わった場合
      IF  ((NVL(gt_main_data(i).vendor_code, lc_break_null ) <> lv_ship_from_code )
        OR (NVL(gt_main_data(i).po_no      , lc_break_null ) <> lv_po_no          ) ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF   (( lv_ship_from_code <> lc_break_init )
          AND ( lv_po_no          <> lc_break_init ) ) THEN
          ------------------------------
          -- 出庫ヘッダＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 出庫ヘッダＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_head' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 明細データタグ出力
        -- -----------------------------------------------------
        -- 発注Ｎｏ
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'order_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_no ;
        -- 出庫倉庫コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_code ;
        -- 出庫倉庫名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_from_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gt_main_data(i).vendor_name, 1, 20) ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_ship_from_code := NVL( gt_main_data(i).vendor_code, lc_break_null ) ;
        lv_po_no          := NVL( gt_main_data(i).po_no      , lc_break_null ) ;
--
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
--
      -- -----------------------------------------------------
      -- ロットＬＧ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ロットＧ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- ロットＮｏ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_no ;
      -- 製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'product_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).make_date, gc_char_d_format), gc_char_d_format);
      -- 賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'use_by_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(
        FND_DATE.STRING_TO_DATE(gt_main_data(i).period_date, gc_char_d_format), gc_char_d_format);
      -- 固有記号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'original_char' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).prop_mark ;
      -- 入数
      IF ( gt_main_data(i).order_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'frequent_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).order_qty ;
      END IF;
      -- 出庫数
      IF ( gt_main_data(i).ship_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ship_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).ship_qty ;
      END IF;
      -- 入庫数
      IF ( gt_main_data(i).stock_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).stock_qty ;
      END IF;
      -- 差異数
      IF ( gt_main_data(i).sai_qty IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_qty' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).sai_qty ;
      END IF;
      --差異列「全て」
      IF (( ir_param.sai_cd IS NULL) OR ( ir_param.sai_cd = gc_sai_all)) THEN
        -- 差異コード、差異事由取得
        prc_get_sai_code(gt_main_data, i, lv_sai_code, lv_sai_reason);
        -- 差異コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_sai_code;
        -- 差異事由
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_reason' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_sai_reason;
      --差異列「全て」以外
      ELSIF ( ir_param.sai_cd IS NOT NULL) THEN
        -- 差異コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_cd' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ir_param.sai_cd ;
        -- 差異事由
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sai_reason' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_diff_reason_name;
      END IF;
      -- -----------------------------------------------------
      -- ロットＧ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- ロットＬＧ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 出庫ヘッダＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 出庫ヘッダＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_head' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 出庫明細Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 出庫明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_dtl' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 納入日Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 納入日ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_deliver' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目区分Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目区分ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 商品区分Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 商品区分ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_prod_div' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 取引先Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 取引先ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_locat' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- データＬＧ終了タグ
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      iv_sai_cd           IN  VARCHAR2  -- 差異事由
     ,iv_rcpt_subinv_code IN  VARCHAR2  -- 入庫倉庫
     ,iv_goods_class      IN  VARCHAR2  -- 商品区分
     ,iv_item_class       IN  VARCHAR2  -- 品目区分
     ,iv_dlv_from         IN  VARCHAR2  -- 納入日from
     ,iv_dlv_to           IN  VARCHAR2  -- 納入日to
     ,iv_ship_code_from   IN  VARCHAR2  -- 出庫元
     ,iv_order_num        IN  VARCHAR2  -- 発注番号
     ,iv_item_code        IN  VARCHAR2  -- 品目
     ,iv_position         IN  VARCHAR2  -- 担当部署
     ,iv_seqrt_class      IN  VARCHAR2  -- セキュリティ区分
     ,ov_errbuf          OUT  VARCHAR2  -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         OUT  VARCHAR2  -- リターン・コード             --# 固定 #
     ,ov_errmsg          OUT  VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
    gv_report_id                := 'XXPO360007T' ;    -- 帳票ID
    gd_exec_date                := SYSDATE ;          -- 実施日
    -- パラメータ格納
    lr_param_rec.sai_cd         := iv_sai_cd ;                -- 差異事由
    lr_param_rec.subinv_code    := iv_rcpt_subinv_code ;      -- 入庫保管場所
    lr_param_rec.goods_class    := iv_goods_class ;           -- 商品区分
    lr_param_rec.item_class     := iv_item_class ;            -- 品目区分
                                                             -- 納品日（ＦＲＯＭ）
    lr_param_rec.dlv_from       := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                          iv_dlv_from,gc_char_dt_format) ,gc_char_d_format);
                                                             -- 納品日（ＴＯ）
    lr_param_rec.dlv_to         := TO_CHAR(FND_DATE.STRING_TO_DATE(
                                          iv_dlv_to,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.ship_code_from := iv_ship_code_from ;        -- 出庫元
    lr_param_rec.order_num      := iv_order_num ;             -- 発注番号
    lr_param_rec.item_code      := iv_item_code ;             -- 品目コード
    lr_param_rec.position       := iv_position ;              -- 担当部署
    lr_param_rec.seqrt_class    := iv_seqrt_class ;           -- セキュリティ区分
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_head>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_deliver>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_item_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_prod_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_prod_div>' ) ;
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
      errbuf                OUT   VARCHAR2,  -- エラーメッセージ
      retcode               OUT   VARCHAR2,  -- エラーコード
      iv_sai_cd             IN    VARCHAR2,  -- 差異事由
      iv_rcpt_subinv_code   IN    VARCHAR2,  -- 入庫倉庫
      iv_goods_class        IN    VARCHAR2,  -- 商品区分
      iv_item_class         IN    VARCHAR2,  -- 品目区分
      iv_dlv_from           IN    VARCHAR2,  -- 納入日from
      iv_dlv_to             IN    VARCHAR2,  -- 納入日to
      iv_ship_code_from     IN    VARCHAR2,  -- 出庫元
      iv_order_num          IN    VARCHAR2,  -- 発注番号
      iv_item_code          IN    VARCHAR2,  -- 品目
      iv_position           IN    VARCHAR2,  -- 担当部署
      iv_seqrt_class        IN    VARCHAR2   -- セキュリティ区分
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
      iv_sai_cd           => iv_sai_cd
     ,iv_rcpt_subinv_code => iv_rcpt_subinv_code
     ,iv_goods_class      => iv_goods_class
     ,iv_item_class       => iv_item_class
     ,iv_dlv_from         => iv_dlv_from
     ,iv_dlv_to           => iv_dlv_to
     ,iv_ship_code_from   => iv_ship_code_from
     ,iv_order_num        => iv_order_num
     ,iv_item_code        => iv_item_code
     ,iv_position         => iv_position
     ,iv_seqrt_class      => iv_seqrt_class
     ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
     );
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error )
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
END xxpo360007c ;
/
