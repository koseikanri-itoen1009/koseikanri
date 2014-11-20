CREATE OR REPLACE PACKAGE BODY xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(body)
 * Description      : 発注書
 * MD.050/070       : 仕入（帳票）Issue1.0(T_MD050_BPO_360)
 *                    仕入（帳票）Issue1.0(T_MD070_BPO_36B)
 * Version          : 1.11
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  fnc_show_ctl              FUNCTION  : 表示制御。
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_initialize            PROCEDURE : 前処理(A-1)
 *  prc_get_report_data       PROCEDURE : データ取得(A-2)
 *  prc_create_xml_data       PROCEDURE : XMLデータ出力(A-3)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/14    1.0   C.Kinjo          新規作成
 *  2008/05/14    1.1   R.Tomoyose       発注明細と仕入先サイトIDの紐付きを修正
 *                                       数値項目の値が0の場合は値を出力しない(ブランクにする)
 *  2008/05/19    1.2   Y.Ishikawa       斡旋者IDが存在しない場合でも出力するように変更
 *  2008/05/20    1.3   T.Endou          セキュリティ外部倉庫の不具合対応
 *  2008/05/20    1.4   T.Endou          入出庫換算単位がある場合の、仕入金額計算方法ミス修正
 *  2008/06/10    1.5   Y.Ishikawa       ロットマスタに同じロットNoが存在する場合、2明細出力される
 *  2008/06/17    1.6   T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/25    1.7   I.Higa           特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/27    1.8   R.Tomoyose       明細が最大行出力（６行出力）の時に、
 *                                       合計が次ページに表示される現象を修正
 *  2008/10/21    1.9   T.Ohashi         指摘382対応
 *  2008/11/20    1.10  T.Ohashi         指摘664対応
 *  2009/03/30    1.11  A.Shiina         本番#1346対応
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo360001c' ;   -- パッケージ名
  gv_print_name           CONSTANT VARCHAR2(20) := '発注書' ;   -- 帳票名
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
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- アプリケーション
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;           -- アプリケーション（XXPO）
--
  gv_seqrt_view           CONSTANT VARCHAR2(30) := '有償支給セキュリティVIEW' ;
  gv_seqrt_view_key       CONSTANT VARCHAR2(20) := '従業員ID' ;
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- 直送区分
  ------------------------------
  gv_direct_type_u    CONSTANT VARCHAR2( 1) := '1';  -- 直送区分(通常)
  gv_direct_type_p    CONSTANT VARCHAR2( 1) := '2';  -- 直送区分(出荷)
  gv_direct_type_s    CONSTANT VARCHAR2( 1) := '3';  -- 直送区分(支給)
  ------------------------------
  -- 使用目的
  ------------------------------
  gv_use_site_po      CONSTANT VARCHAR2( 1) := '1';  -- 使用目的(発注書)
  gv_use_site_po_inst CONSTANT VARCHAR2( 1) := '2';  -- 使用目的(発注指示書)
--
  -- 商品区分
  gv_goods_classe_drink  CONSTANT VARCHAR2(1) := '2'; -- 商品区分：2(ドリンク)
  -- 製品区分
  gv_item_class_products CONSTANT VARCHAR2(1) := '5'; -- 品目区分：5(製品)
--
  -- ロット管理区分
  gv_lot_n_div           CONSTANT VARCHAR2(1) := '0'; -- ロット管理なし
--
  -- ロットデフォルト名
  gv_lot_default CONSTANT ic_lots_mst.lot_no%TYPE  := 'DEFAULTLOT'; --デフォルトロット名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD (
      site_use            fnd_lookup_values.lookup_code%TYPE             -- 01 : 使用目的
     ,po_number           po_headers_all.segment1%TYPE                   -- 02 : 発注番号
     ,role_department     xxcmn_locations_v.location_code%TYPE           -- 03 : 担当部署
     ,role_people         xxpo_per_all_people_f_v.employee_number%TYPE   -- 04 : 担当者
     ,create_date_from    VARCHAR2(21)                                   -- 05 : 作成日FROM
     ,create_date_to      VARCHAR2(21)                                   -- 06 : 作成日TO
     ,vendor_code         xxcmn_vendors_v.segment1%TYPE                  -- 07 : 取引先
     ,mediation           xxcmn_vendors_v.segment1%TYPE                  -- 08 : 斡旋者
     ,delivery_date_from  VARCHAR2(10)                                   -- 09 : 納入日FROM
     ,delivery_date_to    VARCHAR2(10)                                   -- 10 : 納入日TO
     ,delivery_to         xxcmn_item_locations_v.segment1%TYPE           -- 11 : 納入先
     ,product_type        xxpo_categories_v.category_code%TYPE           -- 12 : 商品区分
     ,item_type           xxpo_categories_v.category_code%TYPE           -- 13 : 品目区分
     ,security_type       VARCHAR2(1)                                    -- 14 : セキュリティ区分
    ) ;
--
  -- 発注書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD (
      po_number                   po_headers_all.segment1%TYPE            -- 発注番号
     ,business_partner_num        xxcmn_vendors2_v.segment1%TYPE          -- 取引先コード
     ,business_partner_name       xxcmn_vendors2_v.vendor_full_name%TYPE  -- 取引先名
     ,mediator_num                xxcmn_vendors2_v.segment1%TYPE          -- 斡旋者コード
     ,mediator_name               xxcmn_vendors2_v.vendor_full_name%TYPE  -- 斡旋者名
     ,delivery_date               po_headers_all.attribute4%TYPE          -- 納入日
     ,delivery_to_num             xxcmn_item_locations_v.segment1%TYPE    -- 納入先コード
     ,delivery_to_name            xxcmn_item_locations_v.description%TYPE -- 納入先名
     ,direct_type                 po_headers_all.attribute6%TYPE          -- 直送区分
     ,description                 po_headers_all.attribute15%TYPE         -- 発注ヘッダ/摘要
     ,incident                    po_lines_all.attribute3%TYPE            -- 付帯コード
     ,inventory_quantity          po_lines_all.attribute4%TYPE            -- 在庫入数
     ,quantity                    po_lines_all.attribute11%TYPE           -- 発注数量
     ,unit_of_measure             po_lines_all.attribute10%TYPE           -- 発注単位
     ,unit_price                  po_lines_all.attribute8%TYPE            -- 仕入定価
     ,factory_code                po_lines_all.attribute2%TYPE            -- 工場コード
     ,division                    po_line_locations_all.attribute1%TYPE   -- 粉引率
     ,unit_price_rate             po_line_locations_all.attribute2%TYPE   -- 粉引後単価
     ,amount                      po_line_locations_all.attribute9%TYPE   -- 粉引後金額
     ,commission_unit_price_rate  po_line_locations_all.attribute4%TYPE   -- 口銭
     ,commission_amount           po_line_locations_all.attribute5%TYPE   -- 預り口銭金額
     ,description2                po_lines_all.attribute15%TYPE           -- 発注明細/摘要
     ,levy_unit_price_rate        po_line_locations_all.attribute7%TYPE   -- 賦課金
     ,levy_amount                 po_line_locations_all.attribute8%TYPE   -- 賦課金額
     ,item_code                   xxcmn_item_mst2_v.item_no%TYPE          -- 品目コード
     ,item_name                   xxcmn_item_mst2_v.item_name%TYPE        -- 品目名称
     ,lot_number                  ic_lots_mst.lot_no%TYPE                 -- ロットＮｏ
     ,wip_date                    ic_lots_mst.attribute1%TYPE             -- 製造年月日
     ,best_before_date            ic_lots_mst.attribute3%TYPE             -- 賞味期限
     ,peculiar_mark               ic_lots_mst.attribute2%TYPE             -- 固有記号
     ,year                        ic_lots_mst.attribute11%TYPE            -- 年度
     ,lank1                       ic_lots_mst.attribute14%TYPE            -- ランク1
     ,lank2                       ic_lots_mst.attribute15%TYPE            -- ランク2
     ,lank3                       ic_lots_mst.attribute19%TYPE            -- ランク3
     ,direct_name                 fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(見出)
     ,vender_form                 fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(仕入形態)
     ,tea_time_division           fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(茶期区分)
     ,Place_of_production         fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(産地)
     ,l_type                      fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(タイプ)
     ,commission_division         fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(口銭区分)
     ,levy_amount_division        fnd_lookup_values.meaning%TYPE          -- ｸｲｯｸｺｰﾄﾞ(賦課金区分)
     ,drop_code                   VARCHAR2(9)                             -- 支給/出荷コード
     ,drop_name                   VARCHAR2(60)                            -- 支給/出荷正式名
     ,drop_zip                    VARCHAR2(8)                             -- 支給/出荷郵便番号
     ,drop_address1               VARCHAR2(30)                            -- 支給/出荷住所１
     ,drop_address2               VARCHAR2(30)                            -- 支給/出荷住所２
-- add start ver1.10
     ,phone                       VARCHAR2(30)                            -- 支給/出荷電話番号
-- add end ver1.10
     ,factory_name                xxcmn_vendor_sites_v.vendor_site_name%TYPE -- 工場名
     ,dept_code                   po_headers_all.attribute10%TYPE            -- 部署コード
     ,vendor_id                   xxcmn_vendors2_v.vendor_id%TYPE            -- 仕入先ＩＤ
     ,product_type                xxpo_categories_v.category_code%TYPE       -- 商品区分
     ,item_type                   xxpo_categories_v.category_code%TYPE       -- 品目区分
     ,base_uom                    po_lines_all.unit_meas_lookup_code%TYPE    -- 発注基準単位
     ,num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE        -- ケース入数
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
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
  gn_sales_class            oe_transaction_types_all.org_id%type ;     -- 営業単位
  gv_user_vender            xxpo_per_all_people_f_v.attribute4%TYPE;   -- 仕入先コード
  gv_user_vender_site       xxpo_per_all_people_f_v.attribute6%TYPE;   -- 仕入先サイトコード
  gn_user_vender_id         po_vendors.vendor_id%TYPE;                 -- 仕入先ID
  gv_subinv_code            subinv_code_type;                          -- 保管倉庫コード
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- 帳票ID
  gd_exec_date              DATE         ;    -- 実施日
--
  gt_main_data              tab_data_type_dtl ;  -- 取得レコード表
  gt_xml_data_table         XML_DATA ;           -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;             -- ＸＭＬデータタグ表のインデックス
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
   * Function Name    : fnc_get_in_statement
   * Description      : IN句の内容を返します。(subinv_code_type)
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
   * Function Name    : fnc_show_ctl
   * Description      : 表示制御
   ***********************************************************************************/
  FUNCTION fnc_show_ctl (
      iv_value             IN        VARCHAR2   -- 出力データ
     ,ic_type              IN        CHAR       -- 使用目的
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_show_ctl' ;   -- プログラム名
--
    -- =====================================================
    -- ユーザー宣言部
    -- =====================================================
    -- *** ローカル変数 ***
    lv_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --使用目的 =「発注書」の場合
    IF (ic_type = gv_use_site_po) THEN
      lv_data := iv_value;
    --使用目的 =「発注指示書」の場合
    ELSIF (ic_type = gv_use_site_po_inst) THEN
      lv_data := ' ';
    END IF ;
--
    RETURN(lv_data) ;
--
  END fnc_show_ctl ;
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
   * Description      : 前処理(A-1)
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
    IF ( ir_param.security_type = gc_seqrt_class_outside ) THEN
      -- ====================================================
      -- 保管倉庫コード取得(複数の場合有)
      -- ====================================================
      BEGIN
        SELECT xssv.segment1
          BULK COLLECT INTO gv_subinv_code
        FROM  xxpo_security_supply_v xssv
        WHERE xssv.user_id        = gn_user_id
          AND xssv.security_class = ir_param.security_type;
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
          AND xssv.user_id = gn_user_id
          AND xssv.security_class = ir_param.security_type
          AND FND_DATE.STRING_TO_DATE( ir_param.delivery_date_from, gc_char_d_format )
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
   * Description      : データ取得(A-2)
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
    cv_pln_cancel_flag  CONSTANT VARCHAR2( 1) := 'Y';          -- 取消フラグ（取消）
    cv_poh_status       CONSTANT VARCHAR2(10) := 'APPROVED';   -- 発注ステータス（承認済み）
    cv_poh_make         CONSTANT VARCHAR2( 2) := '20';         -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(発注作成済)
    cv_poh_cancel       CONSTANT VARCHAR2( 2) := '99';         -- 発注ｱﾄﾞｵﾝｽﾃｰﾀｽ(取消)
    cv_lookup_type_drop_ship  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_DROP_SHIP_TYPE';
    cv_lookup_type_l05        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L05';
    cv_lookup_type_l06        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L06';
    cv_lookup_type_l07        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L07';
    cv_lookup_type_l08        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_L08';
    cv_lookup_type_kousen_type  CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_KOUSEN_TYPE';
    cv_lookup_type_gukakin_type CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXPO_FUKAKIN_TYPE';
    cv_ja               CONSTANT VARCHAR2(100) := 'JA' ;
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
    lv_select := '  SELECT'
              || ' poh.segment1          AS po_number'                  -- 発注番号
              || ',xve1.segment1         AS cust_cd'                    -- 取引先コード
              || ',xve1.vendor_full_name AS cust_nm'                    -- 取引先名
              || ',xve2.segment1         AS med_cd'                     -- 斡旋者コード
              || ',xve2.vendor_full_name AS med_nm'                     -- 斡旋者名
              || ',poh.attribute4        AS deli_date'                  -- 納入日
              || ',xil.segment1          AS deli_cd'                    -- 納入先コード
              || ',xil.description       AS deli_nm'                    -- 納入先名
              || ',poh.attribute6        AS direct_type'                -- 直送区分
              || ',poh.attribute15       AS poh_description'            -- 発注ヘッダ/摘要
              || ',pol.attribute3        AS hutai_cd'                   -- 付帯コード
              || ',pol.attribute4        AS inv_incnt'                  -- 在庫入数
              || ',pol.attribute11       AS po_cnt'                     -- 発注数量
              || ',pol.attribute10       AS po_units'                   -- 発注単位
              || ',pol.attribute8        AS buy_price'                  -- 仕入定価
              || ',pol.attribute2        AS factory_code'               -- 工場コード
              || ',polo.attribute1       AS division'                   -- 粉引率
              || ',polo.attribute2       AS unit_price_rate'            -- 粉引後単価
              || ',polo.attribute9       AS amount'                     -- 粉引後金額
              || ',polo.attribute4       AS commission_unit_price_rate' -- 口銭
              || ',polo.attribute5       AS commission_amount'          -- 預り口銭金額
              || ',pol.attribute15       AS pol_description'            -- 発注明細/摘要
              || ',polo.attribute7       AS levy_unit_price_rate'       -- 賦課金
              || ',polo.attribute8       AS levy_amount'                -- 賦課金額
              || ',xim.item_no           AS item_no'                    -- 品目コード
              || ',xim.item_name         AS item_nm'                    -- 品目名称
              || ',DECODE(xim.lot_ctl,'  || gv_lot_n_div
              || '  ,NULL,iclt.lot_no)   AS lot_no'                     -- ロットＮｏ
              || ',iclt.attribute1       AS manu_date'                  -- 製造年月日
              || ',iclt.attribute3       AS use_by_date'                -- 賞味期限
              || ',iclt.attribute2       AS peculiar_mark'              -- 固有記号
              || ',iclt.attribute11      AS year'                       -- 年度
              || ',iclt.attribute14      AS lank1'                      -- ランク1
              || ',iclt.attribute15      AS lank2'                      -- ランク2
              || ',iclt.attribute19      AS lank3'                      -- ランク3
              || ',flv1.meaning          AS direct_name'                -- ｸｲｯｸｺｰﾄﾞ(見出)
              || ',flv2.meaning          AS vender_form'                -- ｸｲｯｸｺｰﾄﾞ(仕入形態)
              || ',flv3.meaning          AS tea_time_division'          -- ｸｲｯｸｺｰﾄﾞ(茶期区分)
              || ',flv4.meaning          AS Place_of_production'        -- ｸｲｯｸｺｰﾄﾞ(産地)
              || ',flv5.meaning          AS l_type'                     -- ｸｲｯｸｺｰﾄﾞ(タイプ)
              || ',flv6.meaning          AS commission_division'        -- ｸｲｯｸｺｰﾄﾞ(口銭区分)
              || ',flv7.meaning          AS levy_amount_division'       -- ｸｲｯｸｺｰﾄﾞ(賦課金区分)
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.party_site_number '    -- パーティサイト番号
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.vendor_site_code '   -- 仕入先サイト名
              || ' END  AS drop_code '             -- 支給/出荷コード
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.party_site_full_name ' -- パーティサイト正式名
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.vendor_site_name '   -- 仕入先サイト正式名
              || ' END  AS drop_name '             -- 支給/出荷正式名
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.zip '                  -- パーティサイト郵便番号
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.zip '                -- 仕入先サイト郵便番号
              || ' END  AS drop_zip  '             -- 支給/出荷郵便番号
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.address_line1 '        -- パーティサイト住所１
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.address_line1 '      -- 仕入先サイト住所１
              || ' END  AS drop_address1 '         -- 支給/出荷住所１
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.address_line2 '        -- パーティサイト住所２
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.address_line2 '      -- 仕入先サイト住所２
              || ' END  AS drop_address2 '         -- 支給/出荷住所２
-- add start ver1.10
              || ',CASE '
              || ' WHEN poh.attribute6 = '|| gv_direct_type_p ||' THEN ' -- 出荷の場合
              || '      xps.phone '                -- パーティサイト電話番号
              || ' WHEN poh.attribute6 = '|| gv_direct_type_s ||' THEN ' -- 支給の場合
              || '      xves2.phone '              -- 仕入先サイト電話番号
              || ' END  AS phone '                 -- 支給/出荷電話番号
-- add end ver1.10
              || ',xves3.vendor_site_name AS factory_name'           -- 工場名
              || ',poh.attribute10        AS dept_code'              -- 部署コード
              || ',xve1.vendor_id         AS vendor_id'              -- 仕入先ＩＤ
              || ',xpoc1.category_code       AS product_type' -- 商品区分
              || ',xpoc2.category_code       AS item_type'    -- 品目区分
              || ',pol.unit_meas_lookup_code AS base_uom'     -- 発注基準単位
              || ',xim.num_of_cases          AS num_of_cases' -- ケース入数
              ;
--
    -- ----------------------------------------------------
    -- ＦＲＯＭ句生成
    -- ----------------------------------------------------
    lv_from := ' FROM'
            || ' po_headers_all             poh'   -- 発注ヘッダ
            || ',xxpo_headers_all           xpoh'  -- 発注ヘッダ(アドオン)
            || ',po_lines_all               pol'   -- 発注明細
            || ',po_line_locations_all      polo'  -- 納入明細
            || ',ic_lots_mst                iclt'  -- opmロットマスタ
            || ',xxcmn_item_mst2_v          xim'   -- opm品目情報view
            || ',(SELECT mcb.segment1  AS category_code '
            || ',  mcb.category_id AS category_id '
            || ',  mcst.category_set_id AS category_set_id '
            || '  FROM   mtl_category_sets_tl  mcst, '
            || '   mtl_category_sets_b   mcsb, '
            || '   mtl_categories_b      mcb '
            || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
            || '  AND   mcst.language         = ''' || cv_ja || ''''
            || '  AND   mcsb.structure_id     = mcb.structure_id '
            || '  AND  mcst.category_set_name = '''|| gc_cat_set_goods_class || '''' || ') xpoc1'
            || ',(SELECT mcb.segment1  AS category_code '
            || ',  mcb.category_id AS category_id '
            || ',  mcst.category_set_id AS category_set_id '
            || '  FROM   mtl_category_sets_tl  mcst, '
            || '   mtl_category_sets_b   mcsb, '
            || '   mtl_categories_b      mcb '
            || '  WHERE mcsb.category_set_id  = mcst.category_set_id '
            || '  AND   mcst.language         = ''' || cv_ja || ''''
            || '  AND   mcsb.structure_id     = mcb.structure_id '
            || '  AND   mcst.category_set_name = ''' || gc_cat_set_item_class || '''' || ') xpoc2'
            || ',xxcmn_item_categories2_v   xic1'  -- opm品目カテゴリ割当view(商品区分)
            || ',xxcmn_item_categories2_v   xic2'  -- opm品目カテゴリ割当view(品目区分)
            || ',xxcmn_vendors2_v           xve1'  -- 仕入先情報view(取引)
            || ',xxcmn_vendors2_v           xve2'  -- 仕入先情報view(斡旋)
            || ',xxcmn_vendor_sites2_v      xves1' -- 仕入先サイト情報view(取引)
            || ',xxcmn_item_locations2_v    xil'   -- opm保管場所情報view(納入先)
            || ',xxcmn_party_sites2_v       xps'   -- パーティサイト情報view(出荷)
            || ',xxcmn_vendor_sites2_v      xves2' -- 仕入先サイト情報view(支給)
            || ',xxcmn_vendor_sites2_v      xves3' -- 仕入先サイト情報view(工場/配送先)
            || ',fnd_lookup_values          flv1'  -- クイックコード(見出)
            || ',fnd_lookup_values          flv2'  -- クイックコード(仕入形態)
            || ',fnd_lookup_values          flv3'  -- クイックコード(茶期区分)
            || ',fnd_lookup_values          flv4'  -- クイックコード(産地)
            || ',fnd_lookup_values          flv5'  -- クイックコード(タイプ)
            || ',fnd_lookup_values          flv6'  -- クイックコード(口銭区分)
            || ',fnd_lookup_values          flv7'  -- クイックコード(賦課金区分)
            ;
--
    -- ----------------------------------------------------
    -- ＷＨＥＲＥ句生成
    -- ----------------------------------------------------
    lv_where := ' WHERE'
             || '     poh.org_id               = ' || gn_sales_class
             || ' AND poh.segment1             = xpoh.po_header_number'
             || ' AND poh.po_header_id         = pol.po_header_id'
             || ' AND pol.po_line_id           = polo.po_line_id'
             || ' AND poh.authorization_status = ''' || cv_poh_status  || ''''
             || ' AND poh.attribute1          >= ''' || cv_poh_make    || ''''
             || ' AND poh.attribute1           < ''' || cv_poh_cancel  || ''''
             || ' AND pol.cancel_flag         <> ''' || cv_pln_cancel_flag   || ''''
             || ' AND poh.attribute4          >= ''' || ir_param.delivery_date_from || ''''
-- 2009/03/30 v1.11 ADD START
             || ' AND poh.org_id               = FND_PROFILE.VALUE(''ORG_ID'') '
-- 2009/03/30 v1.11 ADD END
             ;
    -- 発注番号が入力されている場合
    IF (ir_param.po_number IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.segment1      = ''' || ir_param.po_number || ''''
               ;
    END IF;
    -- 担当部署が入力されている場合
    IF (ir_param.role_department IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute10      = ''' || ir_param.role_department || ''''
               ;
    END IF;
    -- 担当者が入力されている場合
    IF (ir_param.role_people IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_by_code      = ''' || ir_param.role_people || ''''
               ;
    END IF;
    -- 作成日時FROMが入力されている場合
    IF (ir_param.create_date_from IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_date      >= '
               || '     FND_DATE.STRING_TO_DATE(''' || ir_param.create_date_from || ''','''
                                                    || gc_char_dt_format  || ''')'
               ;
    END IF;
    -- 作成日時TOが入力されている場合
    IF (ir_param.create_date_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoh.order_created_date      <= '
               || '     FND_DATE.STRING_TO_DATE(''' || ir_param.create_date_to || ''','''
                                                    || gc_char_dt_format  || ''')'
               ;
    END IF;
    -- 納入先が入力されている場合
    IF (ir_param.delivery_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute5      = ''' || ir_param.delivery_to || ''''
               ;
    END IF;
    -- 納入日ＴＯが入力されている場合
    IF (ir_param.delivery_date_to IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute4      <= ''' || ir_param.delivery_date_to || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- ロット＆品目の絞込み条件
    lv_where := lv_where
             || ' AND pol.item_id            = xim.inventory_item_id'
             || ' AND xim.item_id            = iclt.item_id'
             || ' AND DECODE(xim.lot_ctl,' || gv_lot_n_div   || ','''
                                           || gv_lot_default || ''''
                                           || ',pol.attribute1) = iclt.lot_no '
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xim.start_date_active AND xim.end_date_active'
             ;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ(商品区分)の絞込み条件
    lv_where := lv_where
             || ' AND xim.item_id                          = xic1.item_id'
             || ' AND xic1.category_set_id                 = xpoc1.category_set_id'
             || ' AND xic1.category_id                     = xpoc1.category_id'
             ;
    -- 商品区分が入力されている場合
    IF (ir_param.product_type IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoc1.category_code   = ''' || ir_param.product_type || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 品目カテゴリ(品目区分)の絞込み条件
    lv_where := lv_where
             || ' AND xim.item_id                          = xic2.item_id'
             || ' AND xic2.category_set_id                 = xpoc2.category_set_id'
             || ' AND xic2.category_id                     = xpoc2.category_id'
             ;
    -- 品目区分が入力されている場合
    IF (ir_param.item_type IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xpoc2.category_code   = ''' || ir_param.item_type || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 取引先の絞込み条件
    lv_where := lv_where
             || ' AND xve1.vendor_id       = xves1.vendor_id'
             || ' AND poh.vendor_id        = xve1.vendor_id'
             || ' AND poh.vendor_site_id   = xves1.vendor_site_id'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xve1.start_date_active AND xve1.end_date_active'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves1.start_date_active AND xves1.end_date_active'
             ;
    -- 取引先が入力されている場合
    IF (ir_param.vendor_code IS NOT NULL) THEN
      lv_where := lv_where
               || ' AND xve1.segment1   = ''' || ir_param.vendor_code || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 斡旋者の絞込み条件
    -- 斡旋者が入力されていない場合
    IF (ir_param.mediation IS NULL) THEN
      lv_where := lv_where
               || ' AND poh.attribute3       = xve2.vendor_id(+)'
               || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
               || '     BETWEEN xve2.start_date_active(+) AND xve2.end_date_active(+)'
               ;
    ELSE
      -- 斡旋者が入力されている場合
      lv_where := lv_where
               || ' AND poh.attribute3       = xve2.vendor_id'
               || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
               || '     BETWEEN xve2.start_date_active AND xve2.end_date_active'
               || ' AND xve2.segment1   = ''' || ir_param.mediation || ''''
               ;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- 納入先の絞込み条件
    lv_where := lv_where
             || ' AND poh.attribute5       = xil.segment1'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''') >= xil.date_from'
             || ' AND (  (xil.date_to IS NULL)'
             || '   OR ( (xil.date_to IS NOT NULL)'
             || '    AND (xil.date_to >= FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from
                                                  || ''',''' || gc_char_d_format  || '''))))'
             || ' AND xil.disable_date IS NULL'
             ;
    ---------------------------------------------------------------------------------------------
    -- 支給/出荷の絞込み条件
    lv_where := lv_where
             || ' AND poh.attribute7 = xps.party_site_number(+)'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xps.start_date_active(+) AND xps.end_date_active(+)'
             || ' AND poh.attribute7 = xves2.vendor_site_code(+)'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves2.start_date_active(+) AND xves2.end_date_active(+)'
             ;
    ---------------------------------------------------------------------------------------------
    -- 工場/配送先の絞込み条件
    lv_where := lv_where
             || ' AND pol.attribute2 = xves3.vendor_site_code'
             || ' AND FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                  || gc_char_d_format  || ''')'
             || '     BETWEEN xves3.start_date_active AND xves3.end_date_active'
             ;
    ---------------------------------------------------------------------------------------------
    -- セキュリティ区分の絞込み条件
    -- 「取引先」の場合
    IF (ir_param.security_type = gc_seqrt_class_vender) THEN
      lv_where := lv_where
               || ' AND (   ( poh.attribute3  = ''' || gn_user_vender_id || ''')'
               || '      OR ((poh.vendor_id   = ''' || gn_user_vender_id || ''')'
               ;
      -- ログインユーザーの仕入先サイトコードが設定されている場合
      IF (gv_user_vender_site IS NOT NULL) THEN
        lv_where := lv_where
                 || '        AND  NOT EXISTS(SELECT po_line_id '
                 ||                        ' FROM   po_lines_all pol '
                 ||                        ' WHERE  pol.po_header_id = poh.po_header_id '
                 ||                        ' AND  NVL(pol.attribute2,''*'') '
                 ||                        ' <> ''' || gv_user_vender_site || ''')'
                 ;
      END IF;
      lv_where := lv_where
               || '))'
               ;
    END IF;
    -- 「外部倉庫」の場合
    IF (ir_param.security_type = gc_seqrt_class_outside) THEN
      IF ( gv_subinv_code.COUNT = 1 ) THEN
        lv_where := lv_where
          || ' AND xil.segment1 = ''' || gv_subinv_code(1) || '''';
      ELSIF ( gv_subinv_code.COUNT > 1 ) THEN
        lv_where := lv_where
          || ' AND xil.segment1 IN(' || fnc_get_in_statement(gv_subinv_code) || ')';
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- クイックコードの絞込み条件
    -- <見出し>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv1.start_date_active(+) '
             || '       AND      NVL(flv1.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                     || ir_param.delivery_date_from || ''','''
                                                     || gc_char_d_format  || '''))'
             || ' AND   flv1.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv1.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv1.lookup_type(+)        = ''' || cv_lookup_type_drop_ship || ''''
             || ' AND   flv1.lookup_code(+)        = poh.attribute6'
             ;
    -- <仕入形態>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv2.start_date_active(+) '
             || '       AND      NVL(flv2.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv2.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv2.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv2.lookup_type(+)        = ''' || cv_lookup_type_l05 || ''''
             || ' AND   flv2.lookup_code(+)        = iclt.attribute9'
             ;
    -- <茶期区分>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv3.start_date_active(+) '
             || '       AND      NVL(flv3.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv3.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv3.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv3.lookup_type(+)        = ''' || cv_lookup_type_l06 || ''''
             || ' AND   flv3.lookup_code(+)        = iclt.attribute10'
             ;
    -- <産地>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv4.start_date_active(+) '
             || '       AND      NVL(flv4.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv4.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv4.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv4.lookup_type(+)        = ''' || cv_lookup_type_l07 || ''''
             || ' AND   flv4.lookup_code(+)        = iclt.attribute12'
             ;
    -- <タイプ>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv5.start_date_active(+) '
             || '       AND      NVL(flv5.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv5.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv5.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv5.lookup_type(+)        = ''' || cv_lookup_type_l08 || ''''
             || ' AND   flv5.lookup_code(+)        = iclt.attribute13'
             ;
    -- <口銭区分>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv6.start_date_active(+) '
             || '       AND      NVL(flv6.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv6.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv6.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv6.lookup_type(+)        = ''' || cv_lookup_type_kousen_type || ''''
             || ' AND   flv6.lookup_code(+)        = polo.attribute3'
             ;
    -- <賦課金区分>
    lv_where := lv_where
             || ' AND   FND_DATE.STRING_TO_DATE(''' || ir_param.delivery_date_from || ''','''
                                                    || gc_char_d_format  || ''')'
             || '       BETWEEN  flv7.start_date_active(+) '
             || '       AND      NVL(flv7.end_date_active(+)  , '
             || '                    FND_DATE.STRING_TO_DATE('''
                                                      || ir_param.delivery_date_from || ''','''
                                                      || gc_char_d_format  || '''))'
             || ' AND   flv7.language(+)           = ''' || cv_ja || ''''
             || ' AND   flv7.source_lang(+)        = ''' || cv_ja || ''''
             || ' AND   flv7.lookup_type(+)        = ''' || cv_lookup_type_gukakin_type || ''''
             || ' AND   flv7.lookup_code(+)        = polo.attribute6'
             ;
--
    -- ----------------------------------------------------
    -- ＯＲＤＥＲ  ＢＹ句生成
    -- ----------------------------------------------------
    lv_order_by := ' ORDER BY'
                || ' poh.segment1'      -- 発注番号
                || ',xve1.segment1'     -- 取引先
                || ',xve2.segment1'     -- 斡旋者
                || ',poh.attribute4'    -- 納入日
                || ',xil.segment1'      -- 納入先
                || ',pol.line_num'      -- 明細番号
                ;
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
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XMLデータ出力
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
    lc_break_init     VARCHAR2(100) := '*' ;            -- 初期値
    lc_break_null     VARCHAR2(100) := '**' ;           -- ＮＵＬＬ判定
    lc_max_cnt        NUMBER        := 6 ;              -- 明細MAX行数
    lc_report_name1   VARCHAR2(10)  := '発注書' ;       -- 帳票名称
    lc_report_name2   VARCHAR2(20)  := '発注指示書' ;   -- 帳票名称
    lc_price_text1    VARCHAR2(50)  := '（万一納期が遅れる場合は必ず事前にご連絡下さい。）' ;
    lc_price_text2    VARCHAR2(100) := '本注文書の単価は、消費税等抜きの単価です。支払期日' ||
                                       'には、現行法定税率の消費税等を加算して支払います。' ;
    lc_zero           NUMBER        := 0 ;
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_po_number            VARCHAR2(100) DEFAULT lc_break_init ;  -- 発注番号
    ln_cnt                  NUMBER DEFAULT 0;                      -- 明細件数
    ln_ctotal               NUMBER DEFAULT 0;                      -- 合計数
    ln_mtotal               NUMBER DEFAULT 0;                      -- 合計金額
    ld_appl_date            DATE DEFAULT NULL;
    -- 部署情報取得プロシージャにて使用
    lv_postal_code          VARCHAR2( 10) DEFAULT NULL ; -- 郵便番号
    lv_address              VARCHAR2(100) DEFAULT NULL ; -- 住所
    lv_tel_num              VARCHAR2( 30) DEFAULT NULL ; -- 電話番号
    lv_fax_num              VARCHAR2( 30) DEFAULT NULL ; -- FAX番号
    lv_dept_formal_name     VARCHAR2(100) DEFAULT NULL ; -- 部署正式名
    lv_term_str             VARCHAR2(100) DEFAULT NULL ; -- 支払条件文言
--
    ln_purchase_amount      NUMBER;                      -- 仕入金額計算用
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;             -- 取得レコードなし
--
  BEGIN
--
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
    prc_get_report_data (
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
    -- データＬＧデータタグ出力
    -- -----------------------------------------------------
    -- 帳票名称
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'report_name' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    IF ( ir_param.site_use = gv_use_site_po ) THEN
      gt_xml_data_table(gl_xml_idx).tag_value := lc_report_name1; -- 発注書
    ELSE
      gt_xml_data_table(gl_xml_idx).tag_value := lc_report_name2; -- 発注指示書
    END IF;
    -- 単価消費税文言１
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_tax_text1' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lc_price_text1,
                                                            ir_param.site_use) ;
    -- 単価消費税文言２
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_tax_text2' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lc_price_text2,
                                                            ir_param.site_use) ;
    -- -----------------------------------------------------
    -- 発注番号ＬＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_po_num' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
--
      -- =====================================================
      -- 発注番号ブレイク
      -- =====================================================
      -- 発注番号が切り替わった場合
      IF ( NVL( gt_main_data(i).po_number, lc_break_null ) <> lv_po_number ) THEN
--
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_po_number <> lc_break_init ) THEN
--
          IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
            AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
            IF ((ln_cnt MOD lc_max_cnt) <> lc_zero) THEN
--
              -- 空行の作成
              <<blank_loop>>
              FOR i IN 1 .. lc_max_cnt - ( ln_cnt MOD lc_max_cnt ) LOOP
--
                -- -----------------------------------------------------
                -- ロットLＧ開始タグ出力
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
                -- ロットＧデータタグ出力
                -- -----------------------------------------------------
                -- 品目コード
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
                gt_xml_data_table(gl_xml_idx).tag_value := NULL;
                -- -----------------------------------------------------
                -- ロットＧ終了タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
                -- -----------------------------------------------------
                -- ロットLＧ終了タグ出力
                -- -----------------------------------------------------
                gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
                gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
                gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
              END LOOP blank_loop;
--
            END IF;
--
          END IF;
--
          -- -----------------------------------------------------
          -- 合計LＧ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 合計Ｇ開始タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 明細Ｇデータタグ出力
          -- -----------------------------------------------------
          -- 合計数
          IF (ln_ctotal <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'cnt_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := ln_ctotal;
          END IF;
          -- 合計金額
          IF (ln_mtotal <> 0) THEN
            gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
            gt_xml_data_table(gl_xml_idx).tag_name  := 'money_total' ;
            gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
            gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(TO_CHAR(ln_mtotal),
                                                                    ir_param.site_use);
          END IF;
          -- -----------------------------------------------------
          -- 合計Ｇ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- 合計LＧ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
          -- 件数、合計０クリア
          ln_cnt   := 0;
          ln_ctotal := 0;
          ln_mtotal := 0;
--
          ------------------------------
          -- 発注番号Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_po_num' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- -----------------------------------------------------
        -- 発注番号Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_po_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 発注番号Ｇデータタグ出力
        -- -----------------------------------------------------
        ld_appl_date := FND_DATE.STRING_TO_DATE(ir_param.delivery_date_from,gc_char_d_format);
        -- 部署情報取得プロシージャより取得
        xxcmn_common_pkg.get_dept_info(
           iv_dept_cd          => gt_main_data(i).dept_code -- 部署コード(事業所CD)
          ,id_appl_date        => ld_appl_date              -- 基準日
          ,ov_postal_code      => lv_postal_code            -- 郵便番号
          ,ov_address          => lv_address                -- 住所
          ,ov_tel_num          => lv_tel_num                -- 電話番号
          ,ov_fax_num          => lv_fax_num                -- FAX番号
          ,ov_dept_formal_name => lv_dept_formal_name       -- 部署正式名
          ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ           --# 固定 #
          ,ov_retcode          => lv_retcode           -- リターン・コード             --# 固定 #
          ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
         ) ;
--
        -- 送付元住所
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'address' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_address,1,30) ;
        -- 送付元電話番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'telephone_number_1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_tel_num ;
        -- 送付元FAX番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'telephone_number_2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := lv_fax_num ;
        -- 送付元部署名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dept' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(lv_dept_formal_name,1,30) ;
        -- 発注番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'po_number' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).po_number ;
        -- 取引先：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).business_partner_num ;
        -- 取引先：正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'business_partner_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).business_partner_name,
                                                           1,60) ;
        -- 斡旋者：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mediator_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).mediator_num ;
        -- 斡旋者：正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'mediator_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).mediator_name,
                                                           1,60) ;
        -- 納入日
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_date' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_date ;
        -- 納入先：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).delivery_to_num ;
        -- 納入先：正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'delivery_to_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).delivery_to_name,
                                                           1,20) ;
        -- 支給/出荷：見出し
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_caption' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        IF ( gt_main_data(i).direct_type <> gv_direct_type_u ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).direct_name ;
        ELSIF (( gt_main_data(i).direct_type = gv_direct_type_u )
           OR  ( gt_main_data(i).direct_type = NULL )) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := '' ;
        END IF ;
        -- 支給/出荷：コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).drop_code ;
        -- 支給/出荷：正式名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_name,
                                                           1,60) ;
        -- 支給/出荷：郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_postno' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).drop_zip ;
        -- 支給/出荷：住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_address1,
                                                           1,30) ;
        -- 支給/出荷：住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'pay_ship_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).drop_address2,
                                                           1,30) ;
-- add start ver1.10
        -- 支給/出荷：電話番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'phone_no' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).phone,
                                                           1,30) ;
-- add end ver1.10
--
        -- 支払条件文言取得関数により
        lv_term_str := xxcmn_common_pkg.get_term_of_payment(
                         in_vendor_id        => gt_main_data(i).vendor_id -- 仕入先ＩＤ
                        ,id_appl_date        => ld_appl_date              -- 基準日
                       ) ;
--
        -- 支払条件
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'term' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(lv_term_str,
                                                                ir_param.site_use) ;
        -- 発注ヘッダ：摘要
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'description' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).description,
                                                           1,60) ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_po_number  := NVL( gt_main_data(i).po_number, lc_break_null )  ;
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
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
      -- 付帯コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'incident' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).incident ;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).item_name,
                                                         1,40) ;
      -- 在庫入数
      IF (gt_main_data(i).inventory_quantity IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'inventory_quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).inventory_quantity ;
      END IF;
      -- 数量
      IF (gt_main_data(i).quantity IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'quantity' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).quantity ;
      END IF;
      -- 単位
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_of_measure' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_of_measure ;
      -- 単価
      IF (gt_main_data(i).unit_price IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).unit_price,
                                                                ir_param.site_use) ;
      END IF;
      -- 仕入金額
-- mod start 1.9
--      IF ( (gt_main_data(i).product_type = gv_goods_classe_drink)         -- ドリンク かつ
--        AND (gt_main_data(i).item_type = gv_item_class_products)          -- 製品 かつ
--        AND (gt_main_data(i).base_uom <> gt_main_data(i).unit_of_measure) -- 入出庫換算単位あり
--        ) THEN
          --［数量×在庫入数×単価］
--          ln_purchase_amount := ROUND((NVL(gt_main_data(i).quantity , 0) *
--                                  TO_NUMBER(NVL(gt_main_data(i).inventory_quantity , 0))) *
--                                  NVL(gt_main_data(i).unit_price , 0));
          -- ［数量×在庫入数×単価］
--      ELSE
--          ln_purchase_amount := ROUND(NVL(gt_main_data(i).quantity , 0) *
--                                  NVL(gt_main_data(i).unit_price , 0));
--      END IF;
      -- ［粉引後金額-預り口銭金額-賦課金額］
      ln_purchase_amount := TRUNC(gt_main_data(i).amount - 
                              gt_main_data(i).commission_amount - 
                              gt_main_data(i).levy_amount);
-- mod end 1.9
      IF (ln_purchase_amount <> 0) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'purchase_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(ln_purchase_amount,
                                                                ir_param.site_use) ;
      END IF;
      -- ロットＮｏ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_number' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).lot_number ;
      -- 製造日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'wip_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).wip_date ;
      -- 賞味期限
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'best_before_date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).best_before_date ;
      -- 固有記号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'peculiar_mark' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).peculiar_mark ;
      -- 工場コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).factory_code ;
      -- 工場名
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'factory_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).factory_name,
                                                         1,20) ;
      -- 粉引率
      IF (gt_main_data(i).division IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'division' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).division,
                                                                ir_param.site_use) ;
      END IF;
      -- 粉引後単価
      IF (gt_main_data(i).unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).unit_price_rate,
                                                                ir_param.site_use) ;
      END IF;
      -- 粉引後金額
      IF (gt_main_data(i).amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(NVL(gt_main_data(i).amount , 0),
                                                                ir_param.site_use) ;
      END IF;
      -- 仕入形態
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'vender_form' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).vender_form,
                                                              ir_param.site_use) ;
      -- 年度
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'year' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).year,
                                                              ir_param.site_use) ;
      -- 茶期区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tea_time_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).tea_time_division,
                                                              ir_param.site_use) ;
      -- 産地
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'Place_of_production' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).Place_of_production,
                                                              ir_param.site_use) ;
      -- タイプ
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'type' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_type ;
      -- ランク
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'lank' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).lank1 || '-' ||
                                                              gt_main_data(i).lank2 || '-' ||
                                                              gt_main_data(i).lank3,
                                                              ir_param.site_use) ;
      -- 口銭区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).commission_division,
                                                              ir_param.site_use) ;
      -- 口銭
      IF (gt_main_data(i).commission_unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                                   gt_main_data(i).commission_unit_price_rate,
                                                   ir_param.site_use) ;
      END IF;
      -- 預り口銭金額
      IF (gt_main_data(i).commission_amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'commission_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                                        NVL(gt_main_data(i).commission_amount,0),
                                                        ir_param.site_use) ;
      END IF;
      -- 明細：摘要
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'description2' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB(gt_main_data(i).description2,
                                                         1,40) ;
      -- 賦課金区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_amount_division' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(gt_main_data(i).levy_amount_division,
                                                              ir_param.site_use) ;
      -- 賦課金
      IF (gt_main_data(i).levy_unit_price_rate IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_unit_price_rate' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(
                                         gt_main_data(i).levy_unit_price_rate,ir_param.site_use) ;
      END IF;
      -- 賦課金額
      IF (gt_main_data(i).levy_amount IS NOT NULL) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'levy_amount' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(NVL(gt_main_data(i).levy_amount,0),
                                                                ir_param.site_use) ;
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
      -- 合計数(集計)
      ln_ctotal := ln_ctotal + NVL(gt_main_data(i).quantity,0) ;
      -- 合計金額(集計)
      ln_mtotal := ln_mtotal + NVL(gt_main_data(i).amount,0) ;
      -- 明細件数カウント
      ln_cnt := ln_cnt + 1;
--
    END LOOP main_data_loop ;
--
    IF ((ln_cnt <= lc_max_cnt ) OR ( (ln_cnt > lc_max_cnt)
         AND (ln_cnt MOD lc_max_cnt <= lc_max_cnt))) THEN
--
      IF ((ln_cnt MOD lc_max_cnt) <> lc_zero) THEN
--
        -- 空行の作成
        <<blank_loop>>
        FOR i IN 1 .. lc_max_cnt - ( ln_cnt MOD lc_max_cnt ) LOOP
--
          -- -----------------------------------------------------
          -- ロットLＧ開始タグ出力
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
          -- ロットＧデータタグ出力
          -- -----------------------------------------------------
          -- 品目コード
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := NULL;
          -- -----------------------------------------------------
          -- ロットＧ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          -- -----------------------------------------------------
          -- ロットLＧ終了タグ出力
          -- -----------------------------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_lot' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        END LOOP blank_loop;
--
      END IF;
--
    END IF;
--
    -- -----------------------------------------------------
    -- 合計LＧ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 合計Ｇ開始タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 明細Ｇデータタグ出力
    -- -----------------------------------------------------
    -- 合計数
    IF (ln_ctotal <> 0) THEN
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'cnt_total' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_ctotal;
    END IF;
    -- 合計金額
    IF (ln_mtotal <> 0) THEN
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'money_total' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := fnc_show_ctl(TO_CHAR(ln_mtotal),
                                                              ir_param.site_use);
    END IF;
    -- -----------------------------------------------------
    -- 合計Ｇ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- 合計LＧ終了タグ出力
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_total' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 発注番号Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_po_num' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 発注番号ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_po_num' ;
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
      iv_site_use           IN     VARCHAR2         -- 01 : 使用目的
     ,iv_po_number          IN     VARCHAR2         -- 02 : 発注番号
     ,iv_role_department    IN     VARCHAR2         -- 03 : 担当部署
     ,iv_role_people        IN     VARCHAR2         -- 04 : 担当者
     ,iv_create_date_from   IN     VARCHAR2         -- 05 : 作成日FROM
     ,iv_create_date_to     IN     VARCHAR2         -- 06 : 作成日TO
     ,iv_vendor_code        IN     VARCHAR2         -- 07 : 取引先
     ,iv_mediation          IN     VARCHAR2         -- 08 : 斡旋者
     ,iv_delivery_date_from IN     VARCHAR2         -- 09 : 納入日FROM
     ,iv_delivery_date_to   IN     VARCHAR2         -- 10 : 納入日TO
     ,iv_delivery_to        IN     VARCHAR2         -- 11 : 納入先
     ,iv_product_type       IN     VARCHAR2         -- 12 : 商品区分
     ,iv_item_type          IN     VARCHAR2         -- 13 : 品目区分
     ,iv_security_type      IN     VARCHAR2         -- 14 : セキュリティ区分
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
    ln_retcode              NUMBER := 0 ;
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
    gv_report_id              := 'XXPO360001T' ;      -- 帳票ID
    gd_exec_date              := SYSDATE ;            -- 実施日
    -- パラメータ格納
    lr_param_rec.site_use           := iv_site_use;           -- 使用目的
    lr_param_rec.po_number          := iv_po_number;          -- 発注番号
    lr_param_rec.role_department    := iv_role_department;    -- 担当部署
    lr_param_rec.role_people        := iv_role_people;        -- 担当者
    lr_param_rec.create_date_from   := iv_create_date_from;   -- 作成日FROM
    lr_param_rec.create_date_to     := iv_create_date_to;     -- 作成日TO
    lr_param_rec.vendor_code        := iv_vendor_code;        -- 取引先
    lr_param_rec.mediation          := iv_mediation;          -- 斡旋者
    lr_param_rec.delivery_date_from := TO_CHAR(FND_DATE.STRING_TO_DATE(  -- 納入日FROM
                                       iv_delivery_date_from,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.delivery_date_to   := TO_CHAR(FND_DATE.STRING_TO_DATE(  -- 納入日TO
                                       iv_delivery_date_to,gc_char_dt_format) ,gc_char_d_format);
    lr_param_rec.delivery_to        := iv_delivery_to;        -- 納入先
    lr_param_rec.product_type       := iv_product_type;       -- 商品区分
    lr_param_rec.item_type          := iv_item_type;          -- 品目区分
    lr_param_rec.security_type      := iv_security_type;      -- セキュリティ区分
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
    -- --------------------------------------------------
    -- 抽出データが０件の場合
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- ０件メッセージ出力
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_po_num>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_po_num>' ) ;
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
        lv_xml_string := fnc_conv_xml (
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
     ,iv_site_use           IN     VARCHAR2         -- 01 : 使用目的
     ,iv_po_number          IN     VARCHAR2         -- 02 : 発注番号
     ,iv_role_department    IN     VARCHAR2         -- 03 : 担当部署
     ,iv_role_people        IN     VARCHAR2         -- 04 : 担当者
     ,iv_create_date_from   IN     VARCHAR2         -- 05 : 作成日FROM
     ,iv_create_date_to     IN     VARCHAR2         -- 06 : 作成日TO
     ,iv_vendor_code        IN     VARCHAR2         -- 07 : 取引先
     ,iv_mediation          IN     VARCHAR2         -- 08 : 斡旋者
     ,iv_delivery_date_from IN     VARCHAR2         -- 09 : 納入日FROM
     ,iv_delivery_date_to   IN     VARCHAR2         -- 10 : 納入日TO
     ,iv_delivery_to        IN     VARCHAR2         -- 11 : 納入先
     ,iv_product_type       IN     VARCHAR2         -- 12 : 商品区分
     ,iv_item_type          IN     VARCHAR2         -- 13 : 品目区分
     ,iv_security_type      IN     VARCHAR2         -- 14 : セキュリティ区分
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
        iv_site_use           => iv_site_use            -- 01 : 使用目的
       ,iv_po_number          => iv_po_number           -- 02 : 発注番号
       ,iv_role_department    => iv_role_department     -- 03 : 担当部署
       ,iv_role_people        => iv_role_people         -- 04 : 担当者
       ,iv_create_date_from   => iv_create_date_from    -- 05 : 作成日FROM
       ,iv_create_date_to     => iv_create_date_to      -- 06 : 作成日TO
       ,iv_vendor_code        => iv_vendor_code         -- 07 : 取引先
       ,iv_mediation          => iv_mediation           -- 08 : 斡旋者
       ,iv_delivery_date_from => iv_delivery_date_from  -- 09 : 納入日FROM
       ,iv_delivery_date_to   => iv_delivery_date_to    -- 10 : 納入日TO
       ,iv_delivery_to        => iv_delivery_to         -- 11 : 納入先
       ,iv_product_type       => iv_product_type        -- 12 : 商品区分
       ,iv_item_type          => iv_item_type           -- 13 : 品目区分
       ,iv_security_type      => iv_security_type       -- 14 : セキュリティ区分
       ,ov_errbuf             => lv_errbuf              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode             -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxpo360001c ;
/