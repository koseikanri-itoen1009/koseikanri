CREATE OR REPLACE PACKAGE BODY xxinv550001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550001c(body)
 * Description      : 在庫（帳票）
 * MD.050/070       : 在庫（帳票）Issue1.0  (T_MD050_BPO_550)
 *                    受払残高リスト        (T_MD070_BPO_55A)
 * Version          : 1.14
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  convert_into_xml          XMLデータ変換
 *  insert_xml_plsql_table    XMLデータ格納
 *  prc_check_param_info      パラメータチェック(A-1)
 *  prc_call_xxinv550004c     棚卸スナップショット作成プログラム呼出(A-2)
 *  prc_get_report_data       明細データ取得(A-3)
 *  prc_create_xml_data       ＸＭＬデータ作成(A-4)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/02/01    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/07    1.1   Yasuhisa Yamamoto  変更要求対応(Seq83)
 *  2008/05/09    1.2   Yasuhisa Yamamoto  結合テスト障害対応(抽出データ有差異データ無対応)
 *  2008/05/09    1.3   Yasuhisa Yamamoto  結合テスト障害対応(棚卸結果テーブルLotID NULL対応)
 *  2008/05/20    1.4   Yusuke   Tabata    内部変更要求(Seq95)日付型パラメータ型変換対応
 *  2008/05/20    1.5   Kazuo Kumamoto     結合テスト障害対応(品目原価マスタ未登録対応)
 *  2008/05/20    1.6   Kazuo Kumamoto     結合テスト障害対応(棚卸スナップショット例外キャッチ)
 *  2008/05/21    1.7   Kazuo Kumamoto     結合テスト障害対応(合計数量ALL0は除外)
 *  2008/05/21    1.8   Kazuo Kumamoto     結合テスト障害対応(実棚月末在庫数の算出不具合)
 *  2008/05/26    1.9   Kazuo Kumamoto     結合テスト障害対応(単位出力のズレ)
 *  2008/05/26    1.10  Kazuo Kumamoto     結合テスト障害対応(品目計出力条件変更)
 *  2008/06/07    1.11  Yasuhisa Yamamoto  結合テスト障害対応(抽出データ不正対応)
 *  2008/06/20    1.12  Kazuo Kumamoto     システムテスト障害対応(パラメータ条件指定の不具合)
 *  2008/07/02    1.13  Satoshi Yunba      禁則文字対応
 *  2008/07/08    1.14  Yasuhisa Yamamoto  結合テスト障害対応(ADJI文書IDのNULL対応、入出庫数量0の出力対応)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  gv_status_normal             CONSTANT VARCHAR2(1)   := '0' ;
  gv_status_warn               CONSTANT VARCHAR2(1)   := '1' ;
  gv_status_error              CONSTANT VARCHAR2(1)   := '2' ;
  gv_msg_part                  CONSTANT VARCHAR2(3)   := ' : ' ;
  gv_msg_cont                  CONSTANT VARCHAR2(3)   := '.';
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
  gv_pkg_name                  CONSTANT VARCHAR2(20)  := 'xxinv550001c' ;         -- パッケージ名
  gc_report_id                 CONSTANT VARCHAR2(12)  := 'XXINV550001T';          -- 帳票ID
  gc_tag_type_tag              CONSTANT VARCHAR2(1)   := 'T' ;                    -- 出力タグタイプ（T：タグ）
  gc_tag_type_data             CONSTANT VARCHAR2(1)   := 'D' ;                    -- 出力タグタイプ（D：データ）
  gc_tag_value_type_char       CONSTANT VARCHAR2(1)   := 'C' ;                    -- 出力タイプ（C：Char）
  gc_first_day                 CONSTANT VARCHAR2(2)   := '01' ;                   -- 月初日
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code             CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_completed_ind_1           CONSTANT NUMBER        := 1 ;
  gc_enabled_flag_y            CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_use_div_invent_y          CONSTANT VARCHAR2(1)   := 'Y' ;
  gc_inactive_ind_mukou        CONSTANT NUMBER        := 1 ;
  gc_cat_item_class_shohin     CONSTANT VARCHAR2(8)   := '商品区分';              -- カテゴリセット名（商品区分）
  gc_cat_item_class_hinmoku    CONSTANT VARCHAR2(8)   := '品目区分';              -- カテゴリセット名（品目区分）
  gc_rcv_pay_div_uke           CONSTANT VARCHAR2(2)   := '1';                     -- 受払区分（受入）
  gc_rcv_pay_div_harai         CONSTANT VARCHAR2(2)   := '-1';                    -- 受払区分（払出）
  gc_item_div_genryo           CONSTANT VARCHAR2(1)   := '1';                     -- 品目区分（原料）
  gc_item_div_sizai            CONSTANT VARCHAR2(1)   := '2';                     -- 品目区分（資材）
  gc_item_div_hanseihin        CONSTANT VARCHAR2(1)   := '4';                     -- 品目区分（半製品）
  gc_item_div_seihin           CONSTANT VARCHAR2(1)   := '5';                     -- 品目区分（製品）
  gc_um_class_honsu            CONSTANT VARCHAR2(1)   := '0';                     -- 単位区分（本数）
  gc_um_class_case             CONSTANT VARCHAR2(1)   := '1';                     -- 単位区分（ケース）
  gc_cost_manage_code_hyozyun  CONSTANT VARCHAR2(1)   := '1';                     -- 原価管理区分（標準）
  gc_cost_manage_code_jissei   CONSTANT VARCHAR2(1)   := '0';                     -- 原価管理区分（実勢）
  gc_output_ctl_all            CONSTANT VARCHAR2(1)   := '0';                     -- 差異区分（ALL）
  gc_output_ctl_sel            CONSTANT VARCHAR2(1)   := '1';                     -- 差異区分（差異があるもの）
  gc_employee_div_out          CONSTANT VARCHAR2(1)   := '2';                     -- 従業員区分（外部）
  gc_reason_div_1              CONSTANT VARCHAR2(1)   := '1';                     -- 受払区分マスタ数量＋値
  gc_reason_div_0              CONSTANT VARCHAR2(1)   := '0';                     -- 受払区分マスタ数量－値
  gc_lot_ctl_1                 CONSTANT NUMBER        := 1;                       -- ロット管理区分（有）
  gc_xvst_txns_type_1          CONSTANT VARCHAR2(1)   := '1';                     -- 処理タイプ（相手先在庫）
--
  gc_doc_type_xfer             CONSTANT VARCHAR2(4)   := 'XFER' ;                 -- 在庫トラン文書タイプ（XFER）
  gc_doc_type_omso             CONSTANT VARCHAR2(4)   := 'OMSO' ;                 -- 在庫トラン文書タイプ（OMSO）
  gc_doc_type_prod             CONSTANT VARCHAR2(4)   := 'PROD' ;                 -- 在庫トラン文書タイプ（PROD）
  gc_doc_type_porc             CONSTANT VARCHAR2(4)   := 'PORC' ;                 -- 在庫トラン文書タイプ（PORC）
  gc_doc_type_adji             CONSTANT VARCHAR2(4)   := 'ADJI' ;                 -- 在庫トラン文書タイプ（ADJI）
  gc_doc_type_trni             CONSTANT VARCHAR2(4)   := 'TRNI' ;                 -- 在庫トラン文書タイプ（TRNI）
  gc_src_doc_rma               CONSTANT VARCHAR2(3)   := 'RMA' ;                  -- 在庫トランソース文書（RMA）
  gc_reason_adji_xrart         CONSTANT VARCHAR2(4)   := 'X201' ;                 -- 受払返品実績   仕入先返品X201
  gc_reason_adji_xnpt          CONSTANT VARCHAR2(4)   := 'X988' ;                 -- 生葉実績       浜岡受入X988
  gc_reason_adji_xvst          CONSTANT VARCHAR2(4)   := 'X977' ;                 -- 外注出来高実績 相手先在庫X977
  gc_reason_adji_xmril         CONSTANT VARCHAR2(4)   := 'X123' ;                 -- 移動明細       移動実績訂正X123
--
  -- プロファイル
  gc_cost_div                  CONSTANT VARCHAR2(14)  := 'XXCMN_COST_DIV';
  gc_cost_whse_code            CONSTANT VARCHAR2(26)  := 'XXCMN_COST_PRICE_WHSE_CODE';
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn           CONSTANT VARCHAR2(5)   := 'XXCMN' ;                -- アプリケーション（XXCMN）
  gc_application_inv           CONSTANT VARCHAR2(5)   := 'XXINV' ;                -- アプリケーション（XXINV）
  gc_xxinv_10111               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10111' ;      -- 品目チェックエラー
  gc_xxinv_10112               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10112' ;      -- 倉庫チェックエラー
  gc_xxinv_10113               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10113' ;      -- ブロックチェックエラー
  gc_xxinv_10114               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10114' ;      -- 倉庫管理部署チェックエラー
  gc_xxinv_10115               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10115' ;      -- 日付型エラー
  gc_xxinv_10116               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10116' ;      -- 未来月エラー
  gc_xxinv_10117               CONSTANT VARCHAR2(15)  := 'APP-XXINV-10117' ;      -- 棚卸スナップショット作成エラー
  gc_xxcmn_10122               CONSTANT VARCHAR2(15)  := 'APP-XXCMN-10122' ;      -- 明細0件用メッセージ
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_char_ym_format            CONSTANT VARCHAR2(6)   := 'YYYYMM' ;
  gc_char_ym_out_format        CONSTANT VARCHAR2(16)  := 'YYYY"年"MM"月度"' ;
  gc_char_d_format             CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD' ;
  gc_char_dt_format            CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_max_date_d                CONSTANT VARCHAR2(10)  := '4712/12/31';
  gc_min_date_d                CONSTANT VARCHAR2(10)  := '1900/01/01';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      iv_date_ym               VARCHAR2(6)                                        -- 01 : 対象年月
     ,iv_whse_dept1            mtl_item_locations.attribute3%TYPE                 -- 02 : 倉庫管理部署1
     ,iv_whse_dept2            mtl_item_locations.attribute3%TYPE                 -- 03 : 倉庫管理部署2
     ,iv_whse_dept3            mtl_item_locations.attribute3%TYPE                 -- 04 : 倉庫管理部署3
     ,iv_whse_code1            ic_whse_mst.whse_code%TYPE                         -- 05 : 倉庫コード1
     ,iv_whse_code2            ic_whse_mst.whse_code%TYPE                         -- 06 : 倉庫コード2
     ,iv_whse_code3            ic_whse_mst.whse_code%TYPE                         -- 07 : 倉庫コード3
     ,iv_block_code1           fnd_lookup_values.lookup_code%TYPE                 -- 08 : ブロック1
     ,iv_block_code2           fnd_lookup_values.lookup_code%TYPE                 -- 09 : ブロック2
     ,iv_block_code3           fnd_lookup_values.lookup_code%TYPE                 -- 10 : ブロック3
     ,iv_item_class            mtl_categories_b.segment1%TYPE                     -- 11 : 商品区分
     ,iv_um_class              fnd_lookup_values.lookup_code%TYPE                 -- 12 : 単位区分
     ,iv_item_div              mtl_categories_b.segment1%TYPE                     -- 13 : 品目区分
     ,iv_item_no1              ic_item_mst_b.item_no%TYPE                         -- 14 : 品目コード1
     ,iv_item_no2              ic_item_mst_b.item_no%TYPE                         -- 15 : 品目コード2
     ,iv_item_no3              ic_item_mst_b.item_no%TYPE                         -- 16 : 品目コード3
     ,iv_create_date1          VARCHAR2(10)                                       -- 17 : 製造年月日1
     ,iv_create_date2          VARCHAR2(10)                                       -- 18 : 製造年月日2
     ,iv_create_date3          VARCHAR2(10)                                       -- 19 : 製造年月日3
     ,iv_lot_no1               ic_lots_mst.lot_no%TYPE                            -- 20 : ロットNo1
     ,iv_lot_no2               ic_lots_mst.lot_no%TYPE                            -- 21 : ロットNo2
     ,iv_lot_no3               ic_lots_mst.lot_no%TYPE                            -- 22 : ロットNo3
     ,iv_output_ctl            fnd_lookup_values.lookup_code%TYPE                 -- 23 : 差異データ区分
    ) ;
--
  -- 受払残高リストデータ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
     whse_code                 mtl_item_locations.segment1%TYPE                   -- 倉庫コード
    ,item_id                   ic_item_mst_b.item_id%TYPE                         -- 品目ID
    ,item_no                   ic_item_mst_b.item_no%TYPE                         -- 品目コード
    ,lot_no                    ic_lots_mst.lot_no%TYPE                            -- ロットNo
    ,lot_id                    ic_lots_mst.lot_id%TYPE                            -- ロットid
    ,stock_quantity            NUMBER                                             -- 取引数量（入庫数）
    ,leaving_quantity          NUMBER                                             -- 取引数量（出庫数）
    ,manufacture_date          ic_lots_mst.attribute1%TYPE                        -- 製造年月日
    ,expiration_date           ic_lots_mst.attribute3%TYPE                        -- 賞味期限
    ,uniqe_sign                ic_lots_mst.attribute2%TYPE                        -- 固有記号
    ,item_um                   ic_item_mst_b.attribute24%TYPE                     -- 単位
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
    ,month_stock_be            xxinv_stc_inventory_month_stck.monthly_stock%TYPE  -- 前月末在庫
    ,cargo_stock_be            xxinv_stc_inventory_month_stck.cargo_stock%TYPE    -- 前月末積送中在庫
    ,month_stock_nw            xxinv_stc_inventory_month_stck.monthly_stock%TYPE  -- 当月末在庫
    ,cargo_stock_nw            xxinv_stc_inventory_month_stck.cargo_stock%TYPE    -- 当月末積送中在庫
    ,case_amt                  xxinv_stc_inventory_result.case_amt%TYPE           -- 棚卸ケース数
    ,loose_amt                 xxinv_stc_inventory_result.loose_amt%TYPE          -- 棚卸バラ
-- 08/07/16 Y.Yamamoto ADD v1.14 Start
    ,trans_cnt                 NUMBER                                             -- トランザクション系データの抽出件数
-- 08/07/16 Y.Yamamoto ADD v1.14 End
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gd_exec_date                 DATE ;                                             -- 実施日
  gd_max_date                  DATE ;                                             -- 最大日チェック用
  gd_date_ym_first             DATE ;                                             -- パラメータの対象年月の月初日
  gd_date_ym_last              DATE ;                                             -- パラメータの対象年月の月末日
  gv_date_ym_before            VARCHAR2(6) ;                                      -- パラメータの対象年月の前月
  gv_department_code           VARCHAR2(10) ;                                     -- 担当部署
  gv_department_name           VARCHAR2(14) ;                                     -- 担当者
  gv_employee_div              per_all_people_f.attribute3%TYPE ;                 -- 従業員区分
--
  gt_main_data                 tab_data_type_dtl ;                                -- 取得レコード表
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt          EXCEPTION ;
  --*** 共通関数例外 ***
  global_api_expt              EXCEPTION ;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt       EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  固定部 END   ############################
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : ＸＭＬタグに変換する。
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   タグネーム
     ,iv_value             IN        VARCHAR2   --   タグデータ
     ,ic_type              IN        CHAR       --   タグタイプ
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- 固定ローカル定数
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- プログラム名
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
    IF (ic_type = gc_tag_type_data) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : insert_xml_plsql_table
   * Description      : XMLデータ格納
   ***********************************************************************************/
  PROCEDURE insert_xml_plsql_table(
    iox_xml_data      IN OUT NOCOPY XML_DATA,
    iv_tag_name       IN     VARCHAR2,
    iv_tag_value      IN     VARCHAR2,
    ic_tag_type       IN     CHAR,
    ic_tag_value_type IN     CHAR)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_xml_plsql_table'; -- プログラム名
--
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
--
    -- *** ローカル変数 ***
    i NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
    i:= iox_xml_data.COUNT + 1 ;
    iox_xml_data(i).TAG_NAME  := iv_tag_name;
--
    IF (ic_tag_value_type = 'P') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'FM99990.900');
    ELSIF (ic_tag_value_type = 'B') THEN
      iox_xml_data(i).TAG_VALUE := TO_CHAR(TO_NUMBER(iv_tag_value),'FM9999990.90');
    ELSE
      iox_xml_data(i).TAG_VALUE := iv_tag_value;
    END IF;
    iox_xml_data(i).TAG_TYPE  := ic_tag_type;
--
  END insert_xml_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_info
   * Description      : パラメータチェック(A-1)
   ***********************************************************************************/
  PROCEDURE prc_check_param_info
    (
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_param_info' ; -- プログラム名
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
    ln_cnt                    NUMBER ;        -- 存在チェック用カウンタ
    ln_ret_num                NUMBER ;        -- 共通関数戻り値：数値型
    lv_err_code               VARCHAR2(100) ; -- エラーコード格納用
--
    -- *** ローカル・例外処理 ***
    parameter_check_expt      EXCEPTION ;     -- パラメータチェック例外
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 対象年月チェック
    -- ====================================================
    -- 日付変換チェック
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.iv_date_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_err_code := gc_xxinv_10115 ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- 未来日チェック
-- 08/07/16 Y.Yamamoto Update v1.14 Start
--    IF ( ir_param.iv_date_ym > TO_CHAR( SYSDATE, gc_char_ym_format ) ) THEN
    IF ( ir_param.iv_date_ym > TO_CHAR( TRUNC( SYSDATE ), gc_char_ym_format ) ) THEN
-- 08/07/16 Y.Yamamoto Update v1.14 End
      lv_err_code := gc_xxinv_10116 ;
      RAISE parameter_check_expt ;
    END IF ;
--
    -- 対象年月の月初日の設定
    gd_date_ym_first  := FND_DATE.STRING_TO_DATE( ir_param.iv_date_ym || gc_first_day, gc_char_d_format );
    -- 対象年月の月末日の設定
    gd_date_ym_last   := LAST_DAY( gd_date_ym_first );
    -- 対象年月の前月
    gv_date_ym_before := TO_CHAR( ADD_MONTHS( gd_date_ym_first, -1 ), gc_char_ym_format );
--
    -- ====================================================
    -- 品目コードチェック
    -- ====================================================
    -- 品目コード1
    IF ( ir_param.iv_item_no1 IS NOT NULL ) THEN
      -- 品目コード1と商品区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no1
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- 品目コード1と品目区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no1
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 品目コード2
    IF ( ir_param.iv_item_no2 IS NOT NULL ) THEN
      -- 品目コード2と商品区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no2
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- 品目コード2と品目区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no2
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 品目コード3
    IF ( ir_param.iv_item_no3 IS NOT NULL ) THEN
      -- 品目コード3と商品区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_class
      AND    xicv.category_set_name = gc_cat_item_class_shohin
      AND    xicv.item_no           = ir_param.iv_item_no3
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
--
      -- 品目コード3と品目区分
      SELECT COUNT( xicv.item_id )
      INTO   ln_cnt
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.segment1          = ir_param.iv_item_div
      AND    xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.item_no           = ir_param.iv_item_no3
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      AND    ROWNUM                 = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10111 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 倉庫コードチェック
    -- ====================================================
    -- 倉庫コード1
    IF ( ir_param.iv_whse_code1 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code1
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM             = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫コード2
    IF ( ir_param.iv_whse_code2 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code2
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM        = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫コード3
    IF ( ir_param.iv_whse_code3 IS NOT NULL ) THEN
      SELECT COUNT( xilv.whse_code )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_code     = ir_param.iv_whse_code3
      AND    xilv.disable_date IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM        = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10112 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- ブロックチェック
    -- ====================================================
    -- ブロックコード1
    IF ( ir_param.iv_block_code1 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code1
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM                  = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ブロックコード2
    IF ( ir_param.iv_block_code2 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code2
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ブロックコード3
    IF ( ir_param.iv_block_code3 IS NOT NULL ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.distribution_block = ir_param.iv_block_code3
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10113 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 倉庫管理部署とブロックチェック
    -- ====================================================
    -- 倉庫管理部署1とブロックコード1
    IF ( ( ir_param.iv_whse_dept1 IS NOT NULL ) AND ( ir_param.iv_block_code1 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept1
      AND    xilv.distribution_block = ir_param.iv_block_code1
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫管理部署2とブロックコード2
    IF ( ( ir_param.iv_whse_dept2 IS NOT NULL ) AND ( ir_param.iv_block_code2 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept2
      AND    xilv.distribution_block = ir_param.iv_block_code2
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫管理部署3とブロックコード3
    IF ( ( ir_param.iv_whse_dept3 IS NOT NULL ) AND ( ir_param.iv_block_code3 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department    = ir_param.iv_whse_dept3
      AND    xilv.distribution_block = ir_param.iv_block_code3
      AND    xilv.disable_date      IS NULL
      AND    gd_date_ym_first  BETWEEN xilv.date_from
                                   AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM         = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- ====================================================
    -- 倉庫管理部署と倉庫コードチェック
    -- ====================================================
    -- 倉庫管理部署1と倉庫コード1
    IF ( ( ir_param.iv_whse_dept1 IS NOT NULL ) AND ( ir_param.iv_whse_code1 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept1
      AND    xilv.whse_code       = ir_param.iv_whse_code1
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫管理部署2と倉庫コード2
    IF ( ( ir_param.iv_whse_dept2 IS NOT NULL ) AND ( ir_param.iv_whse_code2 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept2
      AND    xilv.whse_code       = ir_param.iv_whse_code2
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
    -- 倉庫管理部署3と倉庫コード3
    IF ( ( ir_param.iv_whse_dept3 IS NOT NULL ) AND ( ir_param.iv_whse_code3 IS NOT NULL ) ) THEN
      SELECT COUNT( xilv.segment1 )
      INTO   ln_cnt
      FROM   xxcmn_item_locations2_v xilv
      WHERE  xilv.whse_department = ir_param.iv_whse_dept3
      AND    xilv.whse_code       = ir_param.iv_whse_code3
      AND    xilv.disable_date   IS NULL
      AND    gd_date_ym_first    BETWEEN xilv.date_from
                                     AND NVL( xilv.date_to, gd_max_date )
      AND    ROWNUM               = 1
      ;
      IF ( ln_cnt = 0 ) THEN
        lv_err_code := gc_xxinv_10114 ;
        RAISE parameter_check_expt ;
      END IF ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
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
  END prc_check_param_info ;
--
  /**********************************************************************************
   * Procedure Name   : prc_call_xxinv550004c
   * Description      : 棚卸スナップショット作成プログラム呼出(A-2)
   ***********************************************************************************/
  PROCEDURE prc_call_xxinv550004c
    (
      ir_param      IN     rec_param_data   -- 01.入力パラメータ群
     ,ov_errbuf     OUT    VARCHAR2         --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT    VARCHAR2         --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT    VARCHAR2         --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_call_xxinv550004c' ; -- プログラム名
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
    ln_ret_num        NUMBER ;        -- 関数戻り値：数値型
    lv_err_code       VARCHAR2(100) ; -- エラーコード格納用
--
    -- *** ローカル・例外処理 ***
    create_snap_expt  EXCEPTION ;     -- 棚卸スナップショット作成エラー
--
--mod start 1.6
    PRAGMA EXCEPTION_INIT(create_snap_expt,-20001);
--mod end 1.6
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 棚卸スナップショット作成プログラム呼出
    -- ====================================================
    ln_ret_num := xxinv550004c.create_snapshot( ir_param.iv_date_ym     -- 対象年月
                                               ,ir_param.iv_whse_code1  -- 倉庫コード1
                                               ,ir_param.iv_whse_code2  -- 倉庫コード2
                                               ,ir_param.iv_whse_code3  -- 倉庫コード3
                                               ,ir_param.iv_whse_dept1  -- 倉庫管理部署1
                                               ,ir_param.iv_whse_dept2  -- 倉庫管理部署2
                                               ,ir_param.iv_whse_dept3  -- 倉庫管理部署3
                                               ,ir_param.iv_block_code1 -- ブロック1
                                               ,ir_param.iv_block_code2 -- ブロック2
                                               ,ir_param.iv_block_code3 -- ブロック3
                                               ,ir_param.iv_item_class  -- 商品区分
                                               ,ir_param.iv_item_div    -- 品目区分
                                              )
    ;
    IF ( ln_ret_num <> 0 ) THEN
      lv_err_code := gc_xxinv_10117 ;
      RAISE create_snap_expt ;
    END IF ;
--
  EXCEPTION
    --*** 棚卸スナップショット作成エラー例外 ***
    WHEN create_snap_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_inv
                                            ,lv_err_code    ) ;
      ov_errmsg  := lv_errmsg ;
--mod start 1.6
--      ov_errbuf  := lv_errmsg ;
      ov_errbuf := sqlerrm;
--mod end 1.6
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
  END prc_call_xxinv550004c ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : 明細データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data
    (
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
    -- *** ローカル・カーソル（品目区分（製品）） ***
    CURSOR cur_main_data_seihin
      (
           in_whse_dept1   mtl_item_locations.attribute3%TYPE   -- 02 : 倉庫管理部署1
          ,in_whse_dept2   mtl_item_locations.attribute3%TYPE   -- 03 : 倉庫管理部署2
          ,in_whse_dept3   mtl_item_locations.attribute3%TYPE   -- 04 : 倉庫管理部署3
          ,in_whse_code1   ic_whse_mst.whse_code%TYPE           -- 05 : 倉庫コード1
          ,in_whse_code2   ic_whse_mst.whse_code%TYPE           -- 06 : 倉庫コード2
          ,in_whse_code3   ic_whse_mst.whse_code%TYPE           -- 07 : 倉庫コード3
          ,in_block_code1  fnd_lookup_values.lookup_code%TYPE   -- 08 : ブロック1
          ,in_block_code2  fnd_lookup_values.lookup_code%TYPE   -- 09 : ブロック2
          ,in_block_code3  fnd_lookup_values.lookup_code%TYPE   -- 10 : ブロック3
          ,in_item_class   fnd_lookup_values.lookup_code%TYPE   -- 11 : 商品区分
          ,in_um_class     fnd_lookup_values.lookup_code%TYPE   -- 12 : 単位
          ,in_item_div     fnd_lookup_values.lookup_code%TYPE   -- 13 : 品目区分
          ,in_item_no1     ic_item_mst_b.item_no%TYPE           -- 14 : 品目コード1
          ,in_item_no2     ic_item_mst_b.item_no%TYPE           -- 15 : 品目コード2
          ,in_item_no3     ic_item_mst_b.item_no%TYPE           -- 16 : 品目コード3
          ,in_create_date1 VARCHAR2                             -- 17 : 製造年月日1
          ,in_create_date2 VARCHAR2                             -- 18 : 製造年月日2
          ,in_create_date3 VARCHAR2                             -- 19 : 製造年月日3
          ,in_lot_no1      ic_lots_mst.lot_no%TYPE              -- 20 : ロットNo1
          ,in_lot_no2      ic_lots_mst.lot_no%TYPE              -- 21 : ロットNo2
          ,in_lot_no3      ic_lots_mst.lot_no%TYPE              -- 22 : ロットNo3
      )
    IS
    SELECT xilv.whse_code                                       -- 倉庫コード
          ,ximv.item_id                                         -- 品目ID
          ,ximv.item_no                                         -- 品目コード
          ,ilm.lot_no                                           -- ロットNo
          ,ilm.lot_id                                           -- ロットID
          ,SUM( NVL( xrpm.stock_quantity,   0 ) )
                                           AS stock_quantity    -- 取引数量（入庫数）
          ,SUM( NVL( xrpm.leaving_quantity, 0 ) )
                                           AS leaving_quantity  -- 取引数量（出庫数）
          ,ilm.attribute1  AS manufacture_date                  -- 製造年月日
          ,ilm.attribute3  AS expiration_date                   -- 賞味期限
          ,ilm.attribute2  AS uniqe_sign                        -- 固有記号
          ,CASE
            WHEN ( in_um_class = gc_um_class_honsu ) THEN
              ximv.item_um                                      -- 単位区分（本数）のときは単位を取得
            WHEN ( in_um_class = gc_um_class_case  ) THEN
              ximv.conv_unit                                    -- 単位区分（ケース）のときは入出庫換算単位を取得
           END                                       item_um
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
          ,SUM( NVL(xrpm.month_stock_be,0 )) AS month_stock_be  -- 前月末在庫数
          ,SUM( NVL(xrpm.cargo_stock_be,0 )) AS cargo_stock_be  -- 前月積送中在庫数
          ,SUM( NVL(xrpm.month_stock_nw,0 )) AS month_stock_nw  -- 当月末在庫数
          ,SUM( NVL(xrpm.cargo_stock_nw,0 )) AS cargo_stock_nw  -- 当月積送中在庫数
          ,SUM( NVL(xrpm.case_amt,0  ))      AS case_amt        -- 棚卸ケース数
          ,SUM( NVL(xrpm.loose_amt,0 ))      AS loose_amt       -- 棚卸バラ
          ,SUM( NVL(xrpm.trans_cnt,0 ))      AS trans_cnt       -- トランザクション系データの抽出確認用
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    FROM   xxcmn_item_locations2_v                   xilv       -- OPM保管場所情報VIEW2
          ,xxcmn_item_mst2_v                         ximv       -- OPM品目情報VIEW2
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
-- パフォーマンス対応のため、参照するカテゴリ割当情報VIEWを４→５に変更
--          ,xxcmn_item_categories4_v                  xicv       -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_categories5_v                  xicv       -- OPM品目カテゴリ割当情報VIEW5
-- 08/07/23 Y.Yamamoto ADD v1.14 End
          ,ic_lots_mst                               ilm        -- OPMロットマスタ
          ,(SELECT  xrpmv.whse_code                             -- 倉庫コード
                   ,xrpmv.location                              -- 保管倉庫コード
                   ,xrpmv.item_id                               -- 品目ID
                   ,xrpmv.lot_id                                -- ロットID
                   ,TRUNC( xrpmv.trans_date ) AS trans_date     -- トランザクション日付
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_uke ) THEN
                       xrpmv.trans_qty                          -- 受払区分（受入）
                    END                       stock_quantity    -- 取引数量（入庫数）
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_harai ) THEN
                       xrpmv.trans_qty                          -- 受払区分（払出）
                    END                       leaving_quantity  -- 取引数量（出庫数）
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                   ,xrpmv.month_stock_be                        -- 前月末在庫数
                   ,xrpmv.cargo_stock_be                        -- 前月積送中在庫数
                   ,xrpmv.month_stock_nw                        -- 当月末在庫数
                   ,xrpmv.cargo_stock_nw                        -- 当月積送中在庫数
                   ,xrpmv.case_amt                              -- 棚卸ケース数
                   ,xrpmv.loose_amt                             -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                   ,xrpmv.trans_cnt                             -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                           -- 文書タイプ"ADJI"（在庫調整）の抽出
            FROM ( SELECT  itc_adji.whse_code
                          ,itc_adji.location
                          ,itc_adji.item_id
                          ,itc_adji.lot_id
                          ,itc_adji.trans_date
                          ,itc_adji.trans_qty
                          ,xrpm6v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst6_v      xrpm6v     -- 受払区分情報VIEW_ADJI
                          ,ic_tran_cmp               itc_adji   -- OPM完了在庫トランザクション
                          ,ic_adjs_jnl               iaj_adji   -- OPM在庫調整ジャーナル
                          ,ic_jrnl_mst               ijm_adji   -- OPMジャーナルマスタ
                          ,(SELECT gc_reason_adji_xrart as reason_code
                                  ,ijm_x201.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x201
                                  ,xxpo_rcv_and_rtn_txns     xrart_adji -- 受入返品実績（アドオン）
                            WHERE  TO_NUMBER( ijm_x201.attribute1 ) = xrart_adji.txns_id
                            UNION
                            SELECT gc_reason_adji_xnpt  as reason_code
                                  ,ijm_x988.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x988
                                  ,xxpo_namaha_prod_txns     xnpt_adji  -- 生葉実績（アドオン）
                            WHERE  ijm_x988.attribute1              = xnpt_adji.entry_number
-- 08/07/22 Y.Yamamoto Delete v1.14 Start
--                            UNION
--                            SELECT gc_reason_adji_xvst  as reason_code
--                                  ,ijm_x977.attribute1  as attribute1
--                            FROM   ic_jrnl_mst               ijm_x977
--                                  ,xxpo_vendor_supply_txns   xvst_adji  -- 外注出来高実績（アドオン）
--                            WHERE  TO_NUMBER( ijm_x977.attribute1 ) = xvst_adji.txns_id
--                            AND    xvst_adji.txns_type              = gc_xvst_txns_type_1
-- 08/07/22 Y.Yamamoto Delete v1.14 End
                            UNION
                            SELECT gc_reason_adji_xmril as reason_code
                                  ,ijm_x123.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x123
                                  ,xxinv_mov_req_instr_lines xmril_adji -- 移動依頼/指示明細（アドオン）
                            WHERE  TO_NUMBER( ijm_x123.attribute1 ) = xmril_adji.mov_line_id 
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                            UNION -- 重複防止のためのダミーデータ
                            SELECT gc_doc_type_adji     as reason_code
                                  ,NULL                 as attribute1
                            FROM   DUAL
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                           ) xx_data                                    -- 各アドオンに存在するデータ
                    WHERE  itc_adji.doc_type                 = gc_doc_type_adji
                    AND    xrpm6v.use_div_invent             = gc_use_div_invent_y
                    AND    iaj_adji.journal_id               = ijm_adji.journal_id
-- 08/07/22 Y.Yamamoto Update v1.14 Start
--                    AND    itc_adji.reason_code              = xx_data.reason_code
--                    AND    ijm_adji.attribute1               = xx_data.attribute1
                    AND (((ijm_adji.attribute1               IS NULL)
                      AND (xx_data.reason_code               = gc_doc_type_adji))
                     OR  ((ijm_adji.attribute1               IS NOT NULL)
                      AND ((itc_adji.reason_code             = xx_data.reason_code)
                      AND  (ijm_adji.attribute1              = xx_data.attribute1))
                      OR  ((itc_adji.reason_code             = gc_reason_adji_xvst)
                      AND  (xx_data.reason_code              = gc_doc_type_adji))))
-- 08/07/22 Y.Yamamoto Update v1.14 End
                    AND    itc_adji.doc_type                 = iaj_adji.trans_type
                    AND    itc_adji.doc_id                   = iaj_adji.doc_id
                    AND    itc_adji.doc_line                 = iaj_adji.doc_line
                    AND    xrpm6v.doc_type                   = itc_adji.doc_type
                    AND    xrpm6v.reason_code                = itc_adji.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm6v.rcv_pay_div                = SIGN( itc_adji.trans_qty )
                    AND    xrpm6v.rcv_pay_div                = TO_CHAR( SIGN( itc_adji.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"TRNI"（積送なし移動）の抽出
                    UNION ALL  -- 文書タイプ"TRNI"（積送なし移動）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itc_trni.whse_code
                          ,itc_trni.location
                          ,itc_trni.item_id
                          ,itc_trni.lot_id
                          ,itc_trni.trans_date
                          ,itc_trni.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- 受払区分情報VIEW_倉庫関連
                          ,ic_tran_cmp               itc_trni   -- OPM完了在庫トランザクション
                          ,ic_adjs_jnl               iaj_trni   -- OPM在庫調整ジャーナル
                          ,ic_jrnl_mst               ijm_trni   -- OPMジャーナルマスタ
                          ,xxinv_mov_req_instr_lines xmril_trni -- 移動依頼/指示明細（アドオン）
                          ,( SELECT itc_b.whse_code
                                   ,itc_b.doc_id
                                   ,COUNT(*)      AS itc_cnt
                             FROM   ic_tran_cmp      itc_b      -- OPM完了在庫トランザクション
                             WHERE  itc_b.doc_type          = gc_doc_type_trni
                             GROUP BY itc_b.whse_code
                                     ,itc_b.doc_id
                           )                         itc_trni_cnt
                    WHERE  itc_trni.doc_type                = gc_doc_type_trni
                    AND    xrpm9v.doc_type                  = gc_doc_type_trni
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    iaj_trni.journal_id              = ijm_trni.journal_id
                    AND    TO_NUMBER( ijm_trni.attribute1 ) = xmril_trni.mov_line_id
                    AND    itc_trni.doc_type                = iaj_trni.trans_type
                    AND    itc_trni.doc_id                  = iaj_trni.doc_id
                    AND    itc_trni.doc_line                = iaj_trni.doc_line
                    AND    xrpm9v.doc_type                  = itc_trni.doc_type
                    AND    xrpm9v.reason_code               = itc_trni.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itc_trni.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itc_trni.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itc_trni_cnt.whse_code           = itc_trni.whse_code
                    AND    itc_trni_cnt.doc_id              = itc_trni.doc_id
                    AND    itc_trni_cnt.itc_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"XFER"（積送あり移動）の抽出
                    UNION ALL  -- 文書タイプ"XFER"（積送あり移動）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_xfer.whse_code
                          ,itp_xfer.location
                          ,itp_xfer.item_id
                          ,itp_xfer.lot_id
                          ,itp_xfer.trans_date
                          ,itp_xfer.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- 受払区分情報VIEW_倉庫関連
                          ,ic_tran_pnd               itp_xfer   -- OPM保留在庫トランザクション
                          ,ic_xfer_mst               ixm_xfer   -- OPM在庫転送マスタ
                          ,xxinv_mov_req_instr_lines xmril_xfer -- 移動依頼/指示明細（アドオン）
                          ,( SELECT itp_b.whse_code
                                   ,itp_b.doc_id
                                   ,COUNT(*)      AS itp_cnt
                             FROM   ic_tran_pnd      itp_b      -- OPM保留在庫トランザクション
                             WHERE  itp_b.doc_type          = gc_doc_type_xfer
                             AND    itp_b.completed_ind     = gc_completed_ind_1
                             GROUP BY itp_b.whse_code
                                     ,itp_b.doc_id
                           )                         itp_xfer_cnt
                    WHERE  itp_xfer.doc_type                = gc_doc_type_xfer
                    AND    itp_xfer.completed_ind           = gc_completed_ind_1
                    AND    xrpm9v.doc_type                  = gc_doc_type_xfer
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    TO_NUMBER( ixm_xfer.attribute1 ) = xmril_xfer.mov_line_id
                    AND    itp_xfer.doc_id                  = ixm_xfer.transfer_id
                    AND    xrpm9v.doc_type                  = itp_xfer.doc_type
                    AND    xrpm9v.reason_code               = itp_xfer.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itp_xfer.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itp_xfer.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itp_xfer_cnt.whse_code           = itp_xfer.whse_code
                    AND    itp_xfer_cnt.doc_id              = itp_xfer.doc_id
                    AND    itp_xfer_cnt.itp_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"OMSO"（受注）の抽出
                    UNION ALL  -- 文書タイプ"OMSO"（受注）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_omso.whse_code
                          ,itp_omso.location
                          ,itp_omso.item_id
                          ,itp_omso.lot_id
                          ,itp_omso.trans_date
                          ,itp_omso.trans_qty
                          ,xrpm7v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst7_v      xrpm7v     -- 受払区分情報VIEW_OMSO
                          ,ic_tran_pnd               itp_omso   -- OPM保留在庫トランザクション
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                          ,ic_lots_mst               ilm_omso   -- OPMロットマスタ
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                    WHERE  itp_omso.doc_type                = gc_doc_type_omso
                    AND    itp_omso.completed_ind           = gc_completed_ind_1
                    AND    xrpm7v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm7v.doc_type                  = itp_omso.doc_type
                    AND    xrpm7v.line_id                   = itp_omso.line_id
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                    AND    xrpm7v.lot_number                = ilm_omso.lot_no
                    AND    itp_omso.item_id                 = ilm_omso.item_id
                    AND    itp_omso.lot_id                  = ilm_omso.lot_id
-- 08/07/08 Y.Yamamoto ADD v1.14 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"PROD"（生産）の抽出
                    UNION ALL  -- 文書タイプ"PROD"（生産）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_prod.whse_code
                          ,itp_prod.location
                          ,itp_prod.item_id
                          ,itp_prod.lot_id
                          ,itp_prod.trans_date
                          ,itp_prod.trans_qty
                          ,xrpm2v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst2_v      xrpm2v     -- 受払区分情報VIEW生産
                          ,ic_tran_pnd               itp_prod   -- OPM保留在庫トランザクション
                    WHERE  itp_prod.doc_type                = gc_doc_type_prod
                    AND    itp_prod.completed_ind           = gc_completed_ind_1
                    AND    xrpm2v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm2v.doc_type                  = itp_prod.doc_type
                    AND    xrpm2v.doc_id                    = itp_prod.doc_id
                    AND    xrpm2v.doc_line                  = itp_prod.doc_line
                    AND    xrpm2v.line_type                 = itp_prod.line_type
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"PORC"（発注）の抽出
                    UNION ALL  -- 文書タイプ"PORC"（発注）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_porc.whse_code
                          ,itp_porc.location
                          ,itp_porc.item_id
                          ,itp_porc.lot_id
                          ,itp_porc.trans_date
                          ,itp_porc.trans_qty
                          ,xrpm8v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst8_v      xrpm8v     -- 受払区分情報VIEW_PORC
                          ,ic_tran_pnd               itp_porc   -- OPM保留在庫トランザクション
                    WHERE  itp_porc.doc_type                = gc_doc_type_porc
                    AND    itp_porc.completed_ind           = gc_completed_ind_1
                    AND    xrpm8v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm8v.doc_type                  = itp_porc.doc_type
                    AND    xrpm8v.doc_id                    = itp_porc.doc_id
                    AND    xrpm8v.doc_line                  = itp_porc.doc_line
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 前月末在庫の抽出
                    UNION ALL  -- 前月末在庫の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_be.whse_code
                          ,xilv_be.segment1                        AS location
                          ,xsims_be.item_id
                          ,xsims_be.lot_id
                          ,gd_date_ym_first      AS trans_date       -- 前月のデータなので結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,SUM( NVL( xsims_be.monthly_stock, 0 ) ) AS month_stock_be  -- 月末在庫数
                          ,SUM( NVL( xsims_be.cargo_stock,   0 ) ) AS cargo_stock_be  -- 積送中在庫数
                          ,0                     AS month_stock_nw   -- 当月末在庫数
                          ,0                     AS cargo_stock_nw   -- 当月積送中在庫数
                          ,0                     AS case_amt         -- 棚卸ケース数
                          ,0                     AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_be   -- 棚卸月末在庫テーブル
                          ,xxcmn_item_locations_v xilv_be
                    WHERE  xsims_be.invent_ym = gv_date_ym_before    -- 棚卸年月前月のもの
                    AND    xilv_be.whse_code = xsims_be.whse_code
                    AND    xilv_be.segment1 = ( SELECT MIN( x.segment1 )
                                                FROM   xxcmn_item_locations_v x
                                                WHERE  x.whse_code = xsims_be.whse_code )
                    GROUP BY xsims_be.whse_code                      -- 倉庫コード
                            ,xilv_be.segment1
                            ,xsims_be.item_id                        -- 品目ID
                            ,xsims_be.lot_id                         -- ロットID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 月末在庫の抽出
                    UNION ALL  -- 月末在庫の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_nw.whse_code
                          ,xilv_nw.segment1                        AS location
                          ,xsims_nw.item_id
                          ,xsims_nw.lot_id
                          ,gd_date_ym_first      AS trans_date       -- 結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- 月末在庫数
                          ,0                     AS cargo_stock_be   -- 積送中在庫数
                          ,SUM( NVL( xsims_nw.monthly_stock, 0 ) ) AS month_stock_nw  -- 当月末在庫数
                          ,SUM( NVL( xsims_nw.cargo_stock,   0 ) ) AS cargo_stock_nw  -- 当月積送中在庫数
                          ,0                     AS case_amt         -- 棚卸ケース数
                          ,0                     AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_nw   -- 棚卸月末在庫テーブル
                          ,xxcmn_item_locations_v xilv_nw
                    WHERE  xsims_nw.invent_ym = TO_CHAR( gd_date_ym_first, gc_char_ym_format ) -- 棚卸年月当月のもの
                    AND    xilv_nw.whse_code = xsims_nw.whse_code
                    AND    xilv_nw.segment1 = ( SELECT MIN( y.segment1 )
                                                FROM   xxcmn_item_locations_v y
                                                WHERE  y.whse_code = xsims_nw.whse_code )
                    GROUP BY xsims_nw.whse_code                      -- 倉庫コード
                            ,xilv_nw.segment1
                            ,xsims_nw.item_id                        -- 品目ID
                            ,xsims_nw.lot_id                         -- ロットID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 棚卸結果情報の抽出
                    UNION ALL  -- 棚卸結果情報の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsir.invent_whse_code AS whse_code
                          ,xilv_sir.segment1                       AS location
                          ,xsir.item_id
-- 08/05/09 Y.Yamamoto Update v1.3 Start
--                          ,xsir.lot_id
                          ,NVL( xsir.lot_id, 0 ) AS lot_id
-- 08/05/09 Y.Yamamoto Update v1.3 End
                          ,gd_date_ym_first      AS trans_date       -- 結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- 月末在庫数
                          ,0                     AS cargo_stock_be   -- 積送中在庫数
                          ,0                     AS month_stock_nw   -- 当月末在庫数
                          ,0                     AS cargo_stock_nw   -- 当月積送中在庫数
                          ,SUM( xsir.case_amt )  AS case_amt         -- 棚卸ケース数
                          ,SUM( xsir.loose_amt ) AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_result xsir                     -- 棚卸結果テーブル
                          ,xxcmn_item_locations_v xilv_sir
                    WHERE  xsir.invent_date      BETWEEN gd_date_ym_first      -- パラメータの対象年月の１日から
                                                 AND     gd_date_ym_last       -- 月末日で取得
                    AND    xilv_sir.whse_code = xsir.invent_whse_code
                    AND    xilv_sir.segment1 = ( SELECT MIN( z.segment1 )
                                                 FROM   xxcmn_item_locations_v z
                                                 WHERE  z.whse_code = xsir.invent_whse_code )
                    GROUP BY xsir.invent_whse_code                             -- 棚卸倉庫
                            ,xilv_sir.segment1
                            ,xsir.item_id                                      -- 品目ID
                            ,xsir.lot_id                                       -- ロットID
-- 08/05/07 Y.Yamamoto ADD v1.1 End
                  ) xrpmv
           )                                         xrpm       -- 在庫トラン情報
-- 08/05/20 mod v1.5 start
--          ,( SELECT DISTINCT    ccd.item_id
--             FROM   cm_cmpt_dtl ccd
           ,(SELECT distinct item_id,cost_manage_code
             FROM (
               --標準
               SELECT ccd.item_id,gc_cost_manage_code_hyozyun cost_manage_code
               FROM   cm_cmpt_dtl ccd
                     ,xxcmn_item_mst2_v ximv
               WHERE nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) = gc_cost_manage_code_hyozyun
               AND ccd.item_id = ximv.item_id
               --標準以外
               union all
               SELECT ximv.item_id,gc_cost_manage_code_jissei cost_manage_code
               FROM   xxcmn_item_mst2_v ximv
               WHERE  nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) != gc_cost_manage_code_hyozyun
             )
-- 08/05/20 mod v1.5 end
           )                                         ccd_item        -- 品目原価マスタ
    WHERE  ccd_item.item_id             = ximv.item_id
-- 08/05/20 add v1.5 start
    AND    DECODE(ximv.cost_manage_code
                   ,gc_cost_manage_code_hyozyun,gc_cost_manage_code_hyozyun
                                               ,gc_cost_manage_code_jissei) = ccd_item.cost_manage_code
-- 08/05/20 add v1.5 end
    AND    xicv.item_id                 = ximv.item_id
    AND    ilm.item_id                  = ximv.item_id
    AND    gd_date_ym_first       BETWEEN ximv.start_date_active
                                      AND ximv.end_date_active
    AND    xicv.prod_class_code         = in_item_class
    AND    xicv.item_class_code         = in_item_div
    AND    gd_date_ym_first       BETWEEN xilv.date_from
                                      AND NVL( xilv.date_to, gd_max_date )
    -- ここから在庫トランとの結合
    AND    xrpm.whse_code               = xilv.whse_code
    AND  ( xrpm.location                = xilv.segment1
-- 08/05/08 Y.Yamamoto Update v1.1 Start
--        OR xrpm.lot_id                  = 0 )
        OR (ximv.lot_ctl                = 0
          AND xilv.segment1 = ( SELECT MIN( zz.segment1 )
                                FROM   xxcmn_item_locations_v zz
                                WHERE  zz.whse_code = xilv.whse_code ) ) )
-- 08/05/08 Y.Yamamoto Update v1.1 End
    AND    xrpm.item_id                 = ximv.item_id
    AND    xrpm.lot_id                  = ilm.lot_id
    AND    xrpm.trans_date        BETWEEN gd_date_ym_first
                                      AND gd_date_ym_last
    -- ここからパラメータ条件との結合
--mod start 2.2
/*
    AND (((( xilv.whse_code             = in_whse_code1  )
      OR  (  xilv.whse_code             = in_whse_code2  )
      OR  (  xilv.whse_code             = in_whse_code3  ) )
     OR  ((  xilv.distribution_block    = in_block_code1 )
      OR  (  xilv.distribution_block    = in_block_code2 )
      OR  (  xilv.distribution_block    = in_block_code3 ) ) )
     OR   (  in_whse_code1  IS NULL AND in_whse_code2  IS NULL AND in_whse_code3  IS NULL
         AND in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL ) )
-- 08/05/09 Y.Yamamoto Update v1.2 Start
--    AND  ((( in_whse_dept1             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept1 ) )
--     AND ( ( in_whse_dept2             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept2 ) )
--     AND ( ( in_whse_dept3             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
--    AND  ((( in_item_no1               IS NULL )
--        OR ( ximv.item_no               = in_item_no1 ) )
--     AND ( ( in_item_no2               IS NULL )
--        OR ( ximv.item_no               = in_item_no2 ) )
--     AND ( ( in_item_no3               IS NULL )
--        OR ( ximv.item_no               = in_item_no3 ) ) )
--    AND  ((( in_lot_no1                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no1 ) )
--     AND ( ( in_lot_no2                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no2 ) )
--     AND ( ( in_lot_no3                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
--    AND  ((( in_create_date1           IS NULL )
--        OR ( ilm.attribute1             = in_create_date1 ) )
--     AND ( ( in_create_date2           IS NULL )
--        OR ( ilm.attribute1             = in_create_date2 ) )
--     AND ( ( in_create_date3           IS NULL )
--        OR ( ilm.attribute1             = in_create_date3 ) ) )
    AND  ((( in_whse_dept1             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept1 ) )
     OR  ( ( in_whse_dept2             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept2 ) )
     OR  ( ( in_whse_dept3             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
    AND  ((( in_item_no1               IS NULL )
        OR ( ximv.item_no               = in_item_no1 ) )
     OR  ( ( in_item_no2               IS NULL )
        OR ( ximv.item_no               = in_item_no2 ) )
     OR  ( ( in_item_no3               IS NULL )
        OR ( ximv.item_no               = in_item_no3 ) ) )
    AND  ((( in_lot_no1                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no1 ) )
     OR  ( ( in_lot_no2                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no2 ) )
     OR  ( ( in_lot_no3                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
    AND  ((( in_create_date1           IS NULL )
        OR ( ilm.attribute1             = in_create_date1 ) )
     OR  ( ( in_create_date2           IS NULL )
        OR ( ilm.attribute1             = in_create_date2 ) )
     OR  ( ( in_create_date3           IS NULL )
        OR ( ilm.attribute1             = in_create_date3 ) ) )
-- 08/05/09 Y.Yamamoto Update v1.2 End
*/
    --倉庫管理部署による絞込み
    AND (in_whse_dept1 IS NULL AND in_whse_dept2 IS NULL AND in_whse_dept3 IS NULL
      OR xilv.whse_department IN (in_whse_dept1,in_whse_dept2,in_whse_dept3)
    )
    --倉庫コードによる絞込み
    AND (in_whse_code1 IS NULL AND in_whse_code2 IS NULL AND in_whse_code3 IS NULL
      OR xilv.whse_code IN (in_whse_code1,in_whse_code2,in_whse_code3)
    )
    --物流ブロックによる絞込み
    AND (in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL
      OR xilv.distribution_block IN (in_block_code1,in_block_code2,in_block_code3)
    )
    --品目コードによる絞込み
    AND (in_item_no1 IS NULL AND in_item_no2 IS NULL AND in_item_no3 IS NULL
      OR ximv.item_no IN (in_item_no1,in_item_no2,in_item_no3)
    )
    --製造年月日による絞込み
    AND (in_create_date1 IS NULL AND in_create_date2 IS NULL AND in_create_date3 IS NULL
      OR ilm.attribute1 IN (in_create_date1,in_create_date2,in_create_date3)
    )
    --ロットNoによる絞込み
    AND (in_lot_no1 IS NULL AND in_lot_no2 IS NULL AND in_lot_no3 IS NULL
      OR ilm.lot_no IN (in_lot_no1,in_lot_no2,in_lot_no3)
    )
--mod end 2.2
    GROUP BY  xilv.whse_code                                                 -- 倉庫コード
             ,ximv.item_id                                                   -- 品目ID
             ,ximv.item_no                                                   -- 品目コード
             ,ilm.lot_no                                                     -- ロットNo
             ,ilm.lot_id                                                     -- ロットID
             ,ilm.attribute1                                                 -- 製造年月日
             ,ilm.attribute3                                                 -- 賞味期限
             ,ilm.attribute2                                                 -- 固有記号
             ,ximv.item_um                                                   -- 単位
             ,ximv.conv_unit                                                 -- 入出庫換算単位
-- 08/05/21 v1.7 start
    HAVING NOT (     SUM( NVL(xrpm.month_stock_be,0 )) = 0                   -- 前月末在庫数
                 AND SUM( NVL(xrpm.cargo_stock_be,0 )) = 0                   -- 前月積送中在庫数
                 AND SUM( NVL(xrpm.month_stock_nw,0 )) = 0                   -- 当月末在庫数
                 AND SUM( NVL(xrpm.cargo_stock_nw,0 )) = 0                   -- 当月積送中在庫数
                 AND SUM( NVL(xrpm.case_amt,0  )) = 0                        -- 棚卸ケース数
                 AND SUM( NVL(xrpm.loose_amt,0 )) = 0                        -- 棚卸バラ
-- 08/07/08 Y.Yamamoto Update v1.14 Start
--                 AND SUM( NVL(xrpm.stock_quantity,0)) = 0                    -- 取引数量（入庫数）
--                 AND SUM( NVL(xrpm.leaving_quantity,0)) = 0                  -- 取引数量（出庫数）
--               )
               )
               OR SUM( NVL(xrpm.trans_cnt,0)) > 0                            -- トラン系のデータがあるときは0より大
-- 08/07/08 Y.Yamamoto Update v1.14 End
-- 08/05/21 v1.7 end
    ORDER BY xilv.whse_code                                                  -- 倉庫コード
             ,ximv.item_no                                                   -- 品目コード
             ,ilm.attribute1                                                 -- 製造年月日
             ,ilm.attribute2                                                 -- 固有記号
    ;
--
    -- *** ローカル・カーソル（品目区分（製品以外）） ***
    CURSOR cur_main_data_etc
      (
           in_whse_dept1   mtl_item_locations.attribute3%TYPE  -- 02 : 倉庫管理部署1
          ,in_whse_dept2   mtl_item_locations.attribute3%TYPE  -- 03 : 倉庫管理部署2
          ,in_whse_dept3   mtl_item_locations.attribute3%TYPE  -- 04 : 倉庫管理部署3
          ,in_whse_code1   ic_whse_mst.whse_code%TYPE          -- 05 : 倉庫コード1
          ,in_whse_code2   ic_whse_mst.whse_code%TYPE          -- 06 : 倉庫コード2
          ,in_whse_code3   ic_whse_mst.whse_code%TYPE          -- 07 : 倉庫コード3
          ,in_block_code1  fnd_lookup_values.lookup_code%TYPE  -- 08 : ブロック1
          ,in_block_code2  fnd_lookup_values.lookup_code%TYPE  -- 09 : ブロック2
          ,in_block_code3  fnd_lookup_values.lookup_code%TYPE  -- 10 : ブロック3
          ,in_item_class   fnd_lookup_values.lookup_code%TYPE  -- 11 : 商品区分
          ,in_um_class     fnd_lookup_values.lookup_code%TYPE  -- 12 : 単位
          ,in_item_div     fnd_lookup_values.lookup_code%TYPE  -- 13 : 品目区分
          ,in_item_no1     ic_item_mst_b.item_no%TYPE          -- 14 : 品目コード1
          ,in_item_no2     ic_item_mst_b.item_no%TYPE          -- 15 : 品目コード2
          ,in_item_no3     ic_item_mst_b.item_no%TYPE          -- 16 : 品目コード3
          ,in_create_date1 VARCHAR2                            -- 17 : 製造年月日1
          ,in_create_date2 VARCHAR2                            -- 18 : 製造年月日2
          ,in_create_date3 VARCHAR2                            -- 19 : 製造年月日3
          ,in_lot_no1      ic_lots_mst.lot_no%TYPE             -- 20 : ロットNo1
          ,in_lot_no2      ic_lots_mst.lot_no%TYPE             -- 21 : ロットNo2
          ,in_lot_no3      ic_lots_mst.lot_no%TYPE             -- 22 : ロットNo3
      )
    IS
    SELECT xilv.whse_code                                       -- 倉庫コード
          ,ximv.item_id                                         -- 品目ID
          ,ximv.item_no                                         -- 品目コード
          ,ilm.lot_no                                           -- ロットNo
          ,ilm.lot_id                                           -- ロットID
          ,SUM( NVL( xrpm.stock_quantity,   0 ) )
                                           AS stock_quantity    -- 取引数量（入庫数）
          ,SUM( NVL( xrpm.leaving_quantity, 0 ) )
                                           AS leaving_quantity  -- 取引数量（出庫数）
          ,ilm.attribute1  AS manufacture_date                  -- 製造年月日
          ,ilm.attribute3  AS expiration_date                   -- 賞味期限
          ,ilm.attribute2  AS uniqe_sign                        -- 固有記号
          ,CASE
            WHEN ( in_um_class = gc_um_class_honsu ) THEN
              ximv.item_um                                      -- 単位区分（本数）のときは単位を取得
            WHEN ( in_um_class = gc_um_class_case  ) THEN
              ximv.conv_unit                                    -- 単位区分（ケース）のときは入出庫換算単位を取得
           END                                       item_um
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
          ,SUM( NVL(xrpm.month_stock_be,0 )) AS month_stock_be  -- 前月末在庫数
          ,SUM( NVL(xrpm.cargo_stock_be,0 )) AS cargo_stock_be  -- 前月積送中在庫数
          ,SUM( NVL(xrpm.month_stock_nw,0 )) AS month_stock_nw  -- 当月末在庫数
          ,SUM( NVL(xrpm.cargo_stock_nw,0 )) AS cargo_stock_nw  -- 当月積送中在庫数
          ,SUM( NVL(xrpm.case_amt,0  ))      AS case_amt        -- 棚卸ケース数
          ,SUM( NVL(xrpm.loose_amt,0 ))      AS loose_amt       -- 棚卸バラ
          ,SUM( NVL(xrpm.trans_cnt,0 ))      AS trans_cnt       -- トランザクション系データの抽出確認用
-- 08/05/07 Y.Yamamoto ADD v1.1 End
    FROM   xxcmn_item_locations2_v                   xilv       -- OPM保管場所情報VIEW2
          ,xxcmn_item_mst2_v                         ximv       -- OPM品目情報VIEW2
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
-- パフォーマンス対応のため、参照するカテゴリ割当情報VIEWを４→５に変更
--          ,xxcmn_item_categories4_v                  xicv       -- OPM品目カテゴリ割当情報VIEW4
          ,xxcmn_item_categories5_v                  xicv       -- OPM品目カテゴリ割当情報VIEW5
-- 08/07/23 Y.Yamamoto ADD v1.14 Start
          ,ic_lots_mst                               ilm        -- OPMロットマスタ
          ,(SELECT  xrpmv.whse_code                             -- 倉庫コード
                   ,xrpmv.location                              -- 保管倉庫コード
                   ,xrpmv.item_id                               -- 品目ID
                   ,xrpmv.lot_id                                -- ロットID
                   ,TRUNC( xrpmv.trans_date ) AS trans_date     -- トランザクション日付
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_uke ) THEN
                       xrpmv.trans_qty                          -- 受払区分（受入）
                    END                       stock_quantity    -- 取引数量（入庫数）
                   ,CASE
                     WHEN ( xrpmv.rcv_pay_div = gc_rcv_pay_div_harai ) THEN
                       xrpmv.trans_qty                          -- 受払区分（払出）
                    END                       leaving_quantity  -- 取引数量（出庫数）
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                   ,xrpmv.month_stock_be                        -- 前月末在庫数
                   ,xrpmv.cargo_stock_be                        -- 前月積送中在庫数
                   ,xrpmv.month_stock_nw                        -- 当月末在庫数
                   ,xrpmv.cargo_stock_nw                        -- 当月積送中在庫数
                   ,xrpmv.case_amt                              -- 棚卸ケース数
                   ,xrpmv.loose_amt                             -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                   ,xrpmv.trans_cnt                             -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                           -- 文書タイプ"ADJI"（在庫調整）の抽出
            FROM ( SELECT  itc_adji.whse_code
                          ,itc_adji.location
                          ,itc_adji.item_id
                          ,itc_adji.lot_id
                          ,itc_adji.trans_date
                          ,itc_adji.trans_qty
                          ,xrpm6v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst6_v      xrpm6v     -- 受払区分情報VIEW_ADJI
                          ,ic_tran_cmp               itc_adji   -- OPM完了在庫トランザクション
                          ,ic_adjs_jnl               iaj_adji   -- OPM在庫調整ジャーナル
                          ,ic_jrnl_mst               ijm_adji   -- OPMジャーナルマスタ
                          ,(SELECT gc_reason_adji_xrart as reason_code
                                  ,ijm_x201.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x201
                                  ,xxpo_rcv_and_rtn_txns     xrart_adji -- 受入返品実績（アドオン）
                            WHERE  TO_NUMBER( ijm_x201.attribute1 ) = xrart_adji.txns_id
                            UNION
                            SELECT gc_reason_adji_xnpt  as reason_code
                                  ,ijm_x988.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x988
                                  ,xxpo_namaha_prod_txns     xnpt_adji  -- 生葉実績（アドオン）
                            WHERE  ijm_x988.attribute1              = xnpt_adji.entry_number
-- 08/07/22 Y.Yamamoto ADD v1.14 Start
--                            UNION
--                            SELECT gc_reason_adji_xvst  as reason_code
--                                  ,ijm_x977.attribute1  as attribute1
--                            FROM   ic_jrnl_mst               ijm_x977
--                                  ,xxpo_vendor_supply_txns   xvst_adji  -- 外注出来高実績（アドオン）
--                            WHERE  TO_NUMBER( ijm_x977.attribute1 ) = xvst_adji.txns_id
--                            AND    xvst_adji.txns_type              = gc_xvst_txns_type_1
-- 08/07/22 Y.Yamamoto ADD v1.14 End
                            UNION
                            SELECT gc_reason_adji_xmril as reason_code
                                  ,ijm_x123.attribute1  as attribute1
                            FROM   ic_jrnl_mst               ijm_x123
                                  ,xxinv_mov_req_instr_lines xmril_adji -- 移動依頼/指示明細（アドオン）
                            WHERE  TO_NUMBER( ijm_x123.attribute1 ) = xmril_adji.mov_line_id 
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                            UNION -- 重複防止のためのダミーデータ
                            SELECT gc_doc_type_adji     as reason_code
                                  ,NULL                 as attribute1
                            FROM   DUAL
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                           ) xx_data                                    -- 各アドオンに存在するデータ
                    WHERE  itc_adji.doc_type                 = gc_doc_type_adji
                    AND    xrpm6v.use_div_invent             = gc_use_div_invent_y
                    AND    iaj_adji.journal_id               = ijm_adji.journal_id
-- 08/07/22 Y.Yamamoto Update v1.14 Start
--                    AND    itc_adji.reason_code              = xx_data.reason_code
--                    AND    ijm_adji.attribute1               = xx_data.attribute1
                    AND (((ijm_adji.attribute1               IS NULL)
                      AND (xx_data.reason_code               = gc_doc_type_adji))
                     OR  ((ijm_adji.attribute1               IS NOT NULL)
                      AND ((itc_adji.reason_code             = xx_data.reason_code)
                      AND  (ijm_adji.attribute1              = xx_data.attribute1))
                      OR  ((itc_adji.reason_code             = gc_reason_adji_xvst)
                      AND  (xx_data.reason_code              = gc_doc_type_adji))))
-- 08/07/22 Y.Yamamoto Update v1.14 End
                    AND    itc_adji.doc_type                 = iaj_adji.trans_type
                    AND    itc_adji.doc_id                   = iaj_adji.doc_id
                    AND    itc_adji.doc_line                 = iaj_adji.doc_line
                    AND    xrpm6v.doc_type                   = itc_adji.doc_type
                    AND    xrpm6v.reason_code                = itc_adji.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm6v.rcv_pay_div                = SIGN( itc_adji.trans_qty )
                    AND    xrpm6v.rcv_pay_div                = TO_CHAR( SIGN( itc_adji.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"TRNI"（積送なし移動）の抽出
                    UNION ALL  -- 文書タイプ"TRNI"（積送なし移動）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itc_trni.whse_code
                          ,itc_trni.location
                          ,itc_trni.item_id
                          ,itc_trni.lot_id
                          ,itc_trni.trans_date
                          ,itc_trni.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- 受払区分情報VIEW_倉庫関連
                          ,ic_tran_cmp               itc_trni   -- OPM完了在庫トランザクション
                          ,ic_adjs_jnl               iaj_trni   -- OPM在庫調整ジャーナル
                          ,ic_jrnl_mst               ijm_trni   -- OPMジャーナルマスタ
                          ,xxinv_mov_req_instr_lines xmril_trni -- 移動依頼/指示明細（アドオン）
                          ,( SELECT itc_b.whse_code
                                   ,itc_b.doc_id
                                   ,COUNT(*)      AS itc_cnt
                             FROM   ic_tran_cmp      itc_b      -- OPM完了在庫トランザクション
                             WHERE  itc_b.doc_type          = gc_doc_type_trni
                             GROUP BY itc_b.whse_code
                                     ,itc_b.doc_id
                           )                         itc_trni_cnt
                    WHERE  itc_trni.doc_type                = gc_doc_type_trni
                    AND    xrpm9v.doc_type                  = gc_doc_type_trni
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    iaj_trni.journal_id              = ijm_trni.journal_id
                    AND    TO_NUMBER( ijm_trni.attribute1 ) = xmril_trni.mov_line_id
                    AND    itc_trni.doc_type                = iaj_trni.trans_type
                    AND    itc_trni.doc_id                  = iaj_trni.doc_id
                    AND    itc_trni.doc_line                = iaj_trni.doc_line
                    AND    xrpm9v.doc_type                  = itc_trni.doc_type
                    AND    xrpm9v.reason_code               = itc_trni.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itc_trni.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itc_trni.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itc_trni_cnt.whse_code           = itc_trni.whse_code
                    AND    itc_trni_cnt.doc_id              = itc_trni.doc_id
                    AND    itc_trni_cnt.itc_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"XFER"（積送あり移動）の抽出
                    UNION ALL  -- 文書タイプ"XFER"（積送あり移動）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_xfer.whse_code
                          ,itp_xfer.location
                          ,itp_xfer.item_id
                          ,itp_xfer.lot_id
                          ,itp_xfer.trans_date
                          ,itp_xfer.trans_qty
                          ,xrpm9v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst9_v      xrpm9v     -- 受払区分情報VIEW_倉庫関連
                          ,ic_tran_pnd               itp_xfer   -- OPM保留在庫トランザクション
                          ,ic_xfer_mst               ixm_xfer   -- OPM在庫転送マスタ
                          ,xxinv_mov_req_instr_lines xmril_xfer -- 移動依頼/指示明細（アドオン）
                          ,( SELECT itp_b.whse_code
                                   ,itp_b.doc_id
                                   ,COUNT(*)      AS itp_cnt
                             FROM   ic_tran_pnd      itp_b      -- OPM保留在庫トランザクション
                             WHERE  itp_b.doc_type          = gc_doc_type_xfer
                             AND    itp_b.completed_ind     = gc_completed_ind_1
                             GROUP BY itp_b.whse_code
                                     ,itp_b.doc_id
                           )                         itp_xfer_cnt
                    WHERE  itp_xfer.doc_type                = gc_doc_type_xfer
                    AND    itp_xfer.completed_ind           = gc_completed_ind_1
                    AND    xrpm9v.doc_type                  = gc_doc_type_xfer
                    AND    xrpm9v.use_div_invent            = gc_use_div_invent_y
                    AND    TO_NUMBER( ixm_xfer.attribute1 ) = xmril_xfer.mov_line_id
                    AND    itp_xfer.doc_id                  = ixm_xfer.transfer_id
                    AND    xrpm9v.doc_type                  = itp_xfer.doc_type
                    AND    xrpm9v.reason_code               = itp_xfer.reason_code
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--                    AND    xrpm9v.rcv_pay_div               = SIGN( itp_xfer.trans_qty )
                    AND    xrpm9v.rcv_pay_div               = TO_CHAR( SIGN( itp_xfer.trans_qty ) )
-- 08/05/07 Y.Yamamoto Update v1.1 End
                    AND    itp_xfer_cnt.whse_code           = itp_xfer.whse_code
                    AND    itp_xfer_cnt.doc_id              = itp_xfer.doc_id
                    AND    itp_xfer_cnt.itp_cnt             = 1
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"OMSO"（受注）の抽出
                    UNION ALL  -- 文書タイプ"OMSO"（受注）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_omso.whse_code
                          ,itp_omso.location
                          ,itp_omso.item_id
                          ,itp_omso.lot_id
                          ,itp_omso.trans_date
                          ,itp_omso.trans_qty
                          ,xrpm7v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst7_v      xrpm7v     -- 受払区分情報VIEW_OMSO
                          ,ic_tran_pnd               itp_omso   -- OPM保留在庫トランザクション
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                          ,ic_lots_mst               ilm_omso   -- OPMロットマスタ
-- 08/07/08 Y.Yamamoto ADD v1.14 End
                    WHERE  itp_omso.doc_type                = gc_doc_type_omso
                    AND    itp_omso.completed_ind           = gc_completed_ind_1
                    AND    xrpm7v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm7v.doc_type                  = itp_omso.doc_type
                    AND    xrpm7v.line_id                   = itp_omso.line_id
-- 08/07/08 Y.Yamamoto ADD v1.14 Start
                    AND    xrpm7v.lot_number                = ilm_omso.lot_no
                    AND    itp_omso.item_id                 = ilm_omso.item_id
                    AND    itp_omso.lot_id                  = ilm_omso.lot_id
-- 08/07/08 Y.Yamamoto ADD v1.14 End
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"PROD"（生産）の抽出
                    UNION ALL  -- 文書タイプ"PROD"（生産）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_prod.whse_code
                          ,itp_prod.location
                          ,itp_prod.item_id
                          ,itp_prod.lot_id
                          ,itp_prod.trans_date
                          ,itp_prod.trans_qty
                          ,xrpm2v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst2_v      xrpm2v     -- 受払区分情報VIEW生産
                          ,ic_tran_pnd               itp_prod   -- OPM保留在庫トランザクション
                    WHERE  itp_prod.doc_type                = gc_doc_type_prod
                    AND    itp_prod.completed_ind           = gc_completed_ind_1
                    AND    xrpm2v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm2v.doc_type                  = itp_prod.doc_type
                    AND    xrpm2v.doc_id                    = itp_prod.doc_id
                    AND    xrpm2v.doc_line                  = itp_prod.doc_line
                    AND    xrpm2v.line_type                 = itp_prod.line_type
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 文書タイプ"PORC"（発注）の抽出
                    UNION ALL  -- 文書タイプ"PORC"（発注）の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT itp_porc.whse_code
                          ,itp_porc.location
                          ,itp_porc.item_id
                          ,itp_porc.lot_id
                          ,itp_porc.trans_date
                          ,itp_porc.trans_qty
                          ,xrpm8v.rcv_pay_div
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
                          ,0  AS month_stock_be                 -- 前月末在庫数
                          ,0  AS cargo_stock_be                 -- 前月積送中在庫数
                          ,0  AS month_stock_nw                 -- 当月末在庫数
                          ,0  AS cargo_stock_nw                 -- 当月積送中在庫数
                          ,0  AS case_amt                       -- 棚卸ケース数
                          ,0  AS loose_amt                      -- 棚卸バラ
-- 08/05/07 Y.Yamamoto ADD v1.1 End
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,1  AS trans_cnt                      -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_rcv_pay_mst8_v      xrpm8v     -- 受払区分情報VIEW_PORC
                          ,ic_tran_pnd               itp_porc   -- OPM保留在庫トランザクション
                    WHERE  itp_porc.doc_type                = gc_doc_type_porc
                    AND    itp_porc.completed_ind           = gc_completed_ind_1
                    AND    xrpm8v.use_div_invent            = gc_use_div_invent_y
                    AND    xrpm8v.doc_type                  = itp_porc.doc_type
                    AND    xrpm8v.doc_id                    = itp_porc.doc_id
                    AND    xrpm8v.doc_line                  = itp_porc.doc_line
-- 08/05/07 Y.Yamamoto ADD v1.1 Start
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 前月末在庫の抽出
                    UNION ALL  -- 前月末在庫の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_be.whse_code
                          ,xilv_be.segment1                        AS location
                          ,xsims_be.item_id
                          ,xsims_be.lot_id
                          ,gd_date_ym_first      AS trans_date       -- 前月のデータなので結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,SUM( NVL( xsims_be.monthly_stock, 0 ) ) AS month_stock_be  -- 月末在庫数
                          ,SUM( NVL( xsims_be.cargo_stock,   0 ) ) AS cargo_stock_be  -- 積送中在庫数
                          ,0                     AS month_stock_nw   -- 当月末在庫数
                          ,0                     AS cargo_stock_nw   -- 当月積送中在庫数
                          ,0                     AS case_amt         -- 棚卸ケース数
                          ,0                     AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_be   -- 棚卸月末在庫テーブル
                          ,xxcmn_item_locations_v xilv_be
                    WHERE  xsims_be.invent_ym = gv_date_ym_before    -- 棚卸年月前月のもの
                    AND    xilv_be.whse_code = xsims_be.whse_code
                    AND    xilv_be.segment1 = ( SELECT MIN( x.segment1 )
                                                FROM   xxcmn_item_locations_v x
                                                WHERE  x.whse_code = xsims_be.whse_code )
                    GROUP BY xsims_be.whse_code                      -- 倉庫コード
                            ,xilv_be.segment1
                            ,xsims_be.item_id                        -- 品目ID
                            ,xsims_be.lot_id                         -- ロットID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 月末在庫の抽出
                    UNION ALL  -- 月末在庫の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsims_nw.whse_code
                          ,xilv_nw.segment1                        AS location
                          ,xsims_nw.item_id
                          ,xsims_nw.lot_id
                          ,gd_date_ym_first      AS trans_date       -- 結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- 月末在庫数
                          ,0                     AS cargo_stock_be   -- 積送中在庫数
                          ,SUM( NVL( xsims_nw.monthly_stock, 0 ) ) AS month_stock_nw  -- 当月末在庫数
                          ,SUM( NVL( xsims_nw.cargo_stock,   0 ) ) AS cargo_stock_nw  -- 当月積送中在庫数
                          ,0                     AS case_amt         -- 棚卸ケース数
                          ,0                     AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_month_stck xsims_nw   -- 棚卸月末在庫テーブル
                          ,xxcmn_item_locations_v xilv_nw
                    WHERE  xsims_nw.invent_ym = TO_CHAR( gd_date_ym_first, gc_char_ym_format ) -- 棚卸年月当月のもの
                    AND    xilv_nw.whse_code = xsims_nw.whse_code
                    AND    xilv_nw.segment1 = ( SELECT MIN( y.segment1 )
                                                FROM   xxcmn_item_locations_v y
                                                WHERE  y.whse_code = xsims_nw.whse_code )
                    GROUP BY xsims_nw.whse_code                      -- 倉庫コード
                            ,xilv_nw.segment1
                            ,xsims_nw.item_id                        -- 品目ID
                            ,xsims_nw.lot_id                         -- ロットID
-- 08/06/07 Y.Yamamoto Update v2.1 Start
--                    UNION  -- 棚卸結果情報の抽出
                    UNION ALL  -- 棚卸結果情報の抽出
-- 08/06/07 Y.Yamamoto Update v2.1 End
                    SELECT xsir.invent_whse_code AS whse_code
                          ,xilv_sir.segment1                       AS location
                          ,xsir.item_id
-- 08/05/09 Y.Yamamoto Update v1.3 Start
--                          ,xsir.lot_id
                          ,NVL( xsir.lot_id, 0 ) AS lot_id
-- 08/05/09 Y.Yamamoto Update v1.3 End
                          ,gd_date_ym_first      AS trans_date       -- 結合するため
                          ,0                     AS trans_qty
                          ,NULL                  AS rcv_pay_div
                          ,0                     AS month_stock_be   -- 月末在庫数
                          ,0                     AS cargo_stock_be   -- 積送中在庫数
                          ,0                     AS month_stock_nw   -- 当月末在庫数
                          ,0                     AS cargo_stock_nw   -- 当月積送中在庫数
                          ,SUM( xsir.case_amt )  AS case_amt         -- 棚卸ケース数
                          ,SUM( xsir.loose_amt ) AS loose_amt        -- 棚卸バラ
-- 08/07/09 Y.Yamamoto ADD v1.14 Start
                          ,0                     AS trans_cnt        -- トランザクション系データの抽出確認用
-- 08/07/09 Y.Yamamoto ADD v1.14 End
                    FROM   xxinv_stc_inventory_result xsir                     -- 棚卸結果テーブル
                          ,xxcmn_item_locations_v xilv_sir
                    WHERE  xsir.invent_date      BETWEEN gd_date_ym_first      -- パラメータの対象年月の１日から
                                                 AND     gd_date_ym_last       -- 月末日で取得
                    AND    xilv_sir.whse_code = xsir.invent_whse_code
                    AND    xilv_sir.segment1 = ( SELECT MIN( z.segment1 )
                                                 FROM   xxcmn_item_locations_v z
                                                 WHERE  z.whse_code = xsir.invent_whse_code )
                    GROUP BY xsir.invent_whse_code                             -- 棚卸倉庫
                            ,xilv_sir.segment1
                            ,xsir.item_id                                      -- 品目ID
                            ,xsir.lot_id                                       -- ロットID
-- 08/05/07 Y.Yamamoto ADD v1.1 End
                  ) xrpmv
           )                                         xrpm       -- 在庫トラン情報
-- 08/05/20 mod v1.5 start
--          ,( SELECT DISTINCT    ccd.item_id
--             FROM   cm_cmpt_dtl ccd
           ,(SELECT distinct item_id,cost_manage_code
             FROM (
               --標準
               SELECT ccd.item_id,gc_cost_manage_code_hyozyun cost_manage_code
               FROM   cm_cmpt_dtl ccd
                     ,xxcmn_item_mst2_v ximv
               WHERE nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) = gc_cost_manage_code_hyozyun
               AND ccd.item_id = ximv.item_id
               --標準以外
               union all
               SELECT ximv.item_id,gc_cost_manage_code_jissei cost_manage_code
               FROM   xxcmn_item_mst2_v ximv
               WHERE  nvl(ximv.cost_manage_code,gc_cost_manage_code_jissei) != gc_cost_manage_code_hyozyun
             )
-- 08/05/20 mod v1.5 end
           )                                         ccd_item        -- 品目原価マスタ
    WHERE  ccd_item.item_id             = ximv.item_id
-- 08/05/20 add v1.5 start
    AND    DECODE(ximv.cost_manage_code
                   ,gc_cost_manage_code_hyozyun,gc_cost_manage_code_hyozyun
                                               ,gc_cost_manage_code_jissei) = ccd_item.cost_manage_code
-- 08/05/20 add v1.5 end
    AND    xicv.item_id                 = ximv.item_id
    AND    ilm.item_id                  = ximv.item_id
    AND    gd_date_ym_first       BETWEEN ximv.start_date_active
                                      AND ximv.end_date_active
    AND    xicv.prod_class_code         = in_item_class
    AND    xicv.item_class_code         = in_item_div
    AND    gd_date_ym_first       BETWEEN xilv.date_from
                                      AND NVL( xilv.date_to, gd_max_date )
    -- ここから在庫トランとの結合
    AND    xrpm.whse_code               = xilv.whse_code
    AND  ( xrpm.location                = xilv.segment1
-- 08/05/08 Y.Yamamoto Update v1.1 Start
--        OR xrpm.lot_id                  = 0 )
        OR (ximv.lot_ctl                = 0
          AND xilv.segment1 = ( SELECT MIN( zz.segment1 )
                                FROM   xxcmn_item_locations_v zz
                                WHERE  zz.whse_code = xilv.whse_code ) ) )
-- 08/05/08 Y.Yamamoto Update v1.1 End
    AND    xrpm.item_id                 = ximv.item_id
    AND    xrpm.lot_id                  = ilm.lot_id
    AND    xrpm.trans_date        BETWEEN gd_date_ym_first
                                      AND gd_date_ym_last
    -- ここからパラメータ条件との結合
--mod start 2.2
/*
    AND (((( xilv.whse_code             = in_whse_code1  )
      OR  (  xilv.whse_code             = in_whse_code2  )
      OR  (  xilv.whse_code             = in_whse_code3  ) )
     OR  ((  xilv.distribution_block    = in_block_code1 )
      OR  (  xilv.distribution_block    = in_block_code2 )
      OR  (  xilv.distribution_block    = in_block_code3 ) ) )
     OR   (  in_whse_code1  IS NULL AND in_whse_code2  IS NULL AND in_whse_code3  IS NULL
         AND in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL ) )
-- 08/05/09 Y.Yamamoto Update v1.2 Start
--    AND  ((( in_whse_dept1             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept1 ) )
--     AND ( ( in_whse_dept2             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept2 ) )
--     AND ( ( in_whse_dept3             IS NULL )
--        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
--    AND  ((( in_item_no1               IS NULL )
--        OR ( ximv.item_no               = in_item_no1 ) )
--     AND ( ( in_item_no2               IS NULL )
--        OR ( ximv.item_no               = in_item_no2 ) )
--     AND ( ( in_item_no3               IS NULL )
--        OR ( ximv.item_no               = in_item_no3 ) ) )
--    AND  ((( in_lot_no1                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no1 ) )
--     AND ( ( in_lot_no2                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no2 ) )
--     AND ( ( in_lot_no3                IS NULL )
--        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
--    AND  ((( in_create_date1           IS NULL )
--        OR ( ilm.attribute1             = in_create_date1 ) )
--     AND ( ( in_create_date2           IS NULL )
--        OR ( ilm.attribute1             = in_create_date2 ) )
--     AND ( ( in_create_date3           IS NULL )
--        OR ( ilm.attribute1             = in_create_date3 ) ) )
    AND  ((( in_whse_dept1             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept1 ) )
     OR  ( ( in_whse_dept2             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept2 ) )
     OR  ( ( in_whse_dept3             IS NULL )
        OR ( xilv.whse_department       = in_whse_dept3 ) ) )
    AND  ((( in_item_no1               IS NULL )
        OR ( ximv.item_no               = in_item_no1 ) )
     OR  ( ( in_item_no2               IS NULL )
        OR ( ximv.item_no               = in_item_no2 ) )
     OR  ( ( in_item_no3               IS NULL )
        OR ( ximv.item_no               = in_item_no3 ) ) )
    AND  ((( in_lot_no1                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no1 ) )
     OR  ( ( in_lot_no2                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no2 ) )
     OR  ( ( in_lot_no3                IS NULL )
        OR ( ilm.lot_no                 = in_lot_no3 ) ) )
    AND  ((( in_create_date1           IS NULL )
        OR ( ilm.attribute1             = in_create_date1 ) )
     OR  ( ( in_create_date2           IS NULL )
        OR ( ilm.attribute1             = in_create_date2 ) )
     OR  ( ( in_create_date3           IS NULL )
        OR ( ilm.attribute1             = in_create_date3 ) ) )
-- 08/05/09 Y.Yamamoto Update v1.2 End
*/
    --倉庫管理部署による絞込み
    AND (in_whse_dept1 IS NULL AND in_whse_dept2 IS NULL AND in_whse_dept3 IS NULL
      OR xilv.whse_department IN (in_whse_dept1,in_whse_dept2,in_whse_dept3)
    )
    --倉庫コードによる絞込み
    AND (in_whse_code1 IS NULL AND in_whse_code2 IS NULL AND in_whse_code3 IS NULL
      OR xilv.whse_code IN (in_whse_code1,in_whse_code2,in_whse_code3)
    )
    --物流ブロックによる絞込み
    AND (in_block_code1 IS NULL AND in_block_code2 IS NULL AND in_block_code3 IS NULL
      OR xilv.distribution_block IN (in_block_code1,in_block_code2,in_block_code3)
    )
    --品目コードによる絞込み
    AND (in_item_no1 IS NULL AND in_item_no2 IS NULL AND in_item_no3 IS NULL
      OR ximv.item_no IN (in_item_no1,in_item_no2,in_item_no3)
    )
    --製造年月日による絞込み
    AND (in_create_date1 IS NULL AND in_create_date2 IS NULL AND in_create_date3 IS NULL
      OR ilm.attribute1 IN (in_create_date1,in_create_date2,in_create_date3)
    )
    --ロットNoによる絞込み
    AND (in_lot_no1 IS NULL AND in_lot_no2 IS NULL AND in_lot_no3 IS NULL
      OR ilm.lot_no IN (in_lot_no1,in_lot_no2,in_lot_no3)
    )
--mod end 2.2
    GROUP BY  xilv.whse_code                                                 -- 倉庫コード
             ,ximv.item_id                                                   -- 品目ID
             ,ximv.item_no                                                   -- 品目コード
             ,ilm.lot_no                                                     -- ロットNo
             ,ilm.lot_id                                                     -- ロットID
             ,ilm.attribute1                                                 -- 製造年月日
             ,ilm.attribute3                                                 -- 賞味期限
             ,ilm.attribute2                                                 -- 固有記号
             ,ximv.item_um                                                   -- 単位
             ,ximv.conv_unit                                                 -- 入出庫換算単位
-- 08/05/21 v1.7 start
    HAVING NOT (     SUM( NVL(xrpm.month_stock_be,0 )) = 0                   -- 前月末在庫数
                 AND SUM( NVL(xrpm.cargo_stock_be,0 )) = 0                   -- 前月積送中在庫数
                 AND SUM( NVL(xrpm.month_stock_nw,0 )) = 0                   -- 当月末在庫数
                 AND SUM( NVL(xrpm.cargo_stock_nw,0 )) = 0                   -- 当月積送中在庫数
                 AND SUM( NVL(xrpm.case_amt,0  )) = 0                        -- 棚卸ケース数
                 AND SUM( NVL(xrpm.loose_amt,0 )) = 0                        -- 棚卸バラ
-- 08/07/08 Y.Yamamoto Update v1.14 Start
--                 AND SUM( NVL(xrpm.stock_quantity,0)) = 0                    -- 取引数量（入庫数）
--                 AND SUM( NVL(xrpm.leaving_quantity,0)) = 0                  -- 取引数量（出庫数）
--               )
               )
               OR SUM( NVL(xrpm.trans_cnt,0)) > 0                            -- トラン系のデータがあるときは0より大
-- 08/07/08 Y.Yamamoto Update v1.14 End
-- 08/05/21 v1.7 end
    ORDER BY xilv.whse_code                                                  -- 倉庫コード
             ,ximv.item_no                                                   -- 品目コード
             ,ilm.lot_no                                                     -- ロットNo
    ;
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
    -- データ抽出
    -- ====================================================
    IF (  ir_param.iv_item_div = gc_item_div_seihin ) THEN
      -- カーソルオープン
      -- 品目区分（製品）
      OPEN cur_main_data_seihin
        (
          ir_param.iv_whse_dept1          -- 倉庫管理部署1
         ,ir_param.iv_whse_dept2          -- 倉庫管理部署2
         ,ir_param.iv_whse_dept3          -- 倉庫管理部署3
         ,ir_param.iv_whse_code1          -- 倉庫コード1
         ,ir_param.iv_whse_code2          -- 倉庫コード2
         ,ir_param.iv_whse_code3          -- 倉庫コード3
         ,ir_param.iv_block_code1         -- ブロック1
         ,ir_param.iv_block_code2         -- ブロック2
         ,ir_param.iv_block_code3         -- ブロック3
         ,ir_param.iv_item_class          -- 商品区分
         ,ir_param.iv_um_class            -- 単位
         ,ir_param.iv_item_div            -- 品目区分
         ,ir_param.iv_item_no1            -- 品目コード1
         ,ir_param.iv_item_no2            -- 品目コード2
         ,ir_param.iv_item_no3            -- 品目コード3
         ,ir_param.iv_create_date1        -- 製造年月日1
         ,ir_param.iv_create_date2        -- 製造年月日2
         ,ir_param.iv_create_date3        -- 製造年月日3
         ,ir_param.iv_lot_no1             -- ロットNo1
         ,ir_param.iv_lot_no2             -- ロットNo2
         ,ir_param.iv_lot_no3             -- ロットNo3
        ) ;
      -- バルクフェッチ
      FETCH cur_main_data_seihin BULK COLLECT INTO ot_data_rec ;
      -- カーソルクローズ
      CLOSE cur_main_data_seihin ;
    ELSE
      -- 品目区分（製品）以外
      -- カーソルオープン
      OPEN cur_main_data_etc
        (
          ir_param.iv_whse_dept1          -- 倉庫管理部署1
         ,ir_param.iv_whse_dept2          -- 倉庫管理部署2
         ,ir_param.iv_whse_dept3          -- 倉庫管理部署3
         ,ir_param.iv_whse_code1          -- 倉庫コード1
         ,ir_param.iv_whse_code2          -- 倉庫コード2
         ,ir_param.iv_whse_code3          -- 倉庫コード3
         ,ir_param.iv_block_code1         -- ブロック1
         ,ir_param.iv_block_code2         -- ブロック2
         ,ir_param.iv_block_code3         -- ブロック3
         ,ir_param.iv_item_class          -- 商品区分
         ,ir_param.iv_um_class            -- 単位
         ,ir_param.iv_item_div            -- 品目区分
         ,ir_param.iv_item_no1            -- 品目コード1
         ,ir_param.iv_item_no2            -- 品目コード2
         ,ir_param.iv_item_no3            -- 品目コード3
         ,ir_param.iv_create_date1        -- 製造年月日1
         ,ir_param.iv_create_date2        -- 製造年月日2
         ,ir_param.iv_create_date3        -- 製造年月日3
         ,ir_param.iv_lot_no1             -- ロットNo1
         ,ir_param.iv_lot_no2             -- ロットNo2
         ,ir_param.iv_lot_no3             -- ロットNo3
        ) ;
      -- バルクフェッチ
      FETCH cur_main_data_etc BULK COLLECT INTO ot_data_rec ;
      -- カーソルクローズ
      CLOSE cur_main_data_etc ;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_main_data_seihin%ISOPEN THEN
        CLOSE cur_main_data_seihin ;
      END IF ;
      IF cur_main_data_etc%ISOPEN THEN
        CLOSE cur_main_data_etc ;
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
   * Description      : ＸＭＬデータ作成(A-4)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      iox_xml_data IN OUT NOCOPY XML_DATA
     ,ir_param          IN  rec_param_data    -- 01.レコード  ：パラメータ
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
    lc_break_init          VARCHAR2(5)  := '*****';
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_loc_code            mtl_item_locations.segment1%TYPE;                   -- 入庫倉庫コード
    lv_item_no_key         ic_item_mst_b.item_no%TYPE;                         -- 品目コード
--
    -- 対象月度の出力編集用
    lv_date_ym             VARCHAR2(12);
    -- 出力編集用
    lv_whse_name           ic_whse_mst.whse_name%TYPE;                         -- 倉庫名
    lv_item_k_name         mtl_categories_tl.description%TYPE;                 -- 品目区分名称
    lv_item_short_name     xxcmn_item_mst_b.item_short_name%TYPE;              -- 品目略称
    ln_lot_ctl             ic_item_mst_b.lot_ctl%TYPE;                         -- ロット管理区分
    lv_last_item_um        ic_item_mst_b.attribute24%TYPE;                     -- 最後のデータの単位
--add start 2.0
    lv_prev_lot_ctl        VARCHAR2(10);                                       -- 前レコードのロット管理区分
--add end 2.0
--
    -- 計算用、表示用数値項目
    ln_loct_onhand         ic_loct_inv.loct_onhand%TYPE;                       -- 手持手数料
-- 08/05/07 Y.Yamamoto Delete v1.1 Start
--    ln_month_stock_nw      xxinv_stc_inventory_month_stck.monthly_stock%TYPE;  -- 当月末在庫
--    ln_cargo_stock_nw      xxinv_stc_inventory_month_stck.cargo_stock%TYPE;    -- 当月末積送中在庫
--    ln_month_stock_be      xxinv_stc_inventory_month_stck.monthly_stock%TYPE;  -- 前月末在庫
--    ln_cargo_stock_be      xxinv_stc_inventory_month_stck.cargo_stock%TYPE;    -- 前月末積送中在庫
--    ln_case_amt            xxinv_stc_inventory_result.case_amt%TYPE;           -- 棚卸ケース数
--    ln_loose_amt           xxinv_stc_inventory_result.loose_amt%TYPE;          -- 棚卸バラ
-- 08/05/07 Y.Yamamoto Delete v1.1 End
    ln_quantity            NUMBER;                                             -- 入数
    ln_month_start_stock   NUMBER;                                             -- 月初在庫数
    ln_stock_quantity      NUMBER;                                             -- 当月入庫数
    ln_leaving_quantity    NUMBER;                                             -- 当月出庫数
    ln_logic_month_stock   NUMBER;                                             -- 論理月末在庫数
    ln_invent_month_stock  NUMBER;                                             -- 実棚月末在庫数
    ln_invent_cargo_stock  NUMBER;                                             -- 実棚積送在庫数
    ln_month_stock         NUMBER;                                             -- 差異数
    ln_stock_unit_price    NUMBER;                                             -- 在庫単価
    ln_logic_stock_amount  NUMBER;                                             -- 論理在庫金額
    ln_invent_stock_amount NUMBER;                                             -- 実棚在庫金額
    ln_month_stock_amount  NUMBER;                                             -- 差異金額
    ln_num_of_cases        NUMBER;                                             -- ケース入数
    lv_cost_manage_code    ic_item_mst_b.attribute15%TYPE;                     -- 原価管理区分
--
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    lv_data_out            VARCHAR2(1);                                        -- 出力実行フラグ
    lv_no_data_msg         VARCHAR2(5000) ;                                    --「データはありません」
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- *** ローカル・例外処理 ***
    no_data_expt   EXCEPTION ;   -- 取得レコードなし
--
  BEGIN
--
    -- =====================================================
    -- ブレイクキー初期化
    -- =====================================================
    lv_loc_code    := lc_break_init;
    lv_item_no_key := lc_break_init;
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- 初期化
    -- =====================================================
    lv_data_out    := '0';
-- 08/05/09 Y.Yamamoto ADD v1.2 End
--
    -- =====================================================
    -- 項目データ抽出処理
    -- =====================================================
    prc_get_report_data
      (
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
    -- =====================================================
    -- 品目区分（名称）取得
    -- =====================================================
    BEGIN
      SELECT SUBSTRB( MAX( xicv.description ), 1, 6 )
      INTO   lv_item_k_name
      FROM   xxcmn_item_categories2_v xicv
      WHERE  xicv.category_set_name = gc_cat_item_class_hinmoku
      AND    xicv.segment1          = ir_param.iv_item_div
      AND    xicv.enabled_flag      = gc_enabled_flag_y
      AND    xicv.disable_date     IS NULL
      AND    xicv.inactive_ind     <> gc_inactive_ind_mukou
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_item_k_name := NULL ;
    END ;
--
    -- -----------------------------------------------------
    -- データＧ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'root',      NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 倉庫Ｇ開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, 'g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- 帳票Ｇデータタグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- 帳票ＩＤ
    insert_xml_plsql_table(iox_xml_data, 'report_id', gc_report_id, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 実施日
    insert_xml_plsql_table(iox_xml_data, 'exec_date', TO_CHAR( gd_exec_date, gc_char_dt_format ), 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 対象月度
    -- 対象月度の編集
    lv_date_ym := TO_CHAR( gd_date_ym_first, gc_char_ym_out_format );
    insert_xml_plsql_table(iox_xml_data, 'date_ym', lv_date_ym, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 担当部署
    insert_xml_plsql_table(iox_xml_data, 'department_code', gv_department_code, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 担当者
    insert_xml_plsql_table(iox_xml_data, 'department_name', gv_department_name, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 品目区分（コード）
    insert_xml_plsql_table(iox_xml_data, 'item_div_code', ir_param.iv_item_div, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
    -- 品目区分（名称）
    insert_xml_plsql_table(iox_xml_data, 'item_div_name', lv_item_k_name, 
                                                        gc_tag_type_data, gc_tag_value_type_char);
--
    -- -----------------------------------------------------
    -- 帳票Ｇデータ終了タグ
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/report_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
    -- =====================================================
    -- 項目データ抽出・出力処理
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- 紐付けデータ取得
      -- =====================================================
      -- 品目略称の取得
      BEGIN
        SELECT ximv.item_short_name                                -- 品目略称
              ,ximv.lot_ctl                                        -- ロット管理区分
        INTO   lv_item_short_name
              ,ln_lot_ctl
        FROM   xxcmn_item_mst2_v  ximv                             -- OPM品目情報VIEW2
        WHERE  ximv.item_id     = gt_main_data(i).item_id
        AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                AND     ximv.end_date_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_item_short_name := NULL;
          ln_lot_ctl         := 0;
      END;
--
      -- 手持数量
      BEGIN
        SELECT SUM( ili.loct_onhand ) loct_onhand                  -- 手持数量
        INTO   ln_loct_onhand
        FROM   ic_loct_inv ili                                     -- OPM手持数量
        WHERE  ili.item_id   = gt_main_data(i).item_id
        AND    ili.whse_code = gt_main_data(i).whse_code
        AND    ili.lot_id    = gt_main_data(i).lot_id
        GROUP BY ili.item_id                                       -- 品目ID
                ,ili.whse_code                                     -- 倉庫コード
                ,ili.lot_id                                        -- ロットID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_loct_onhand := 0;
      END;
--
-- 08/05/07 Y.Yamamoto Delete v1.1 Start
      -- 前月末在庫
--      BEGIN
--        SELECT SUM( NVL( xsims.monthly_stock, 0 ) ) monthly_stock  -- 月末在庫数
--              ,SUM( NVL( xsims.cargo_stock,   0 ) )   cargo_stock  -- 積送中在庫数
--        INTO   ln_month_stock_be
--              ,ln_cargo_stock_be
--        FROM   xxinv_stc_inventory_month_stck xsims                -- 棚卸月末在庫テーブル
--        WHERE  xsims.whse_code = gt_main_data(i).whse_code
--        AND    xsims.item_id   = gt_main_data(i).item_id
--        AND   (   xsims.lot_id IS NULL
--               OR xsims.lot_id = gt_main_data(i).lot_id )
--        AND    xsims.invent_ym = gv_date_ym_before                 -- 棚卸年月前月のもの
--        GROUP BY xsims.item_id                                     -- 品目ID
--                ,xsims.whse_code                                   -- 倉庫コード
--                ,xsims.lot_id                                      -- ロットID
--                ,xsims.invent_ym                                   -- 棚卸年月
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_month_stock_be := 0;
--          ln_cargo_stock_be := 0;
--      END;
--
      -- 月末在庫
--      BEGIN
--        SELECT SUM( NVL( xsims.monthly_stock, 0 ) ) monthly_stock  -- 月末在庫数
--              ,SUM( NVL( xsims.cargo_stock,   0 ) )   cargo_stock  -- 積送中在庫数
--        INTO   ln_month_stock_nw
--              ,ln_cargo_stock_nw
--        FROM   xxinv_stc_inventory_month_stck xsims                -- 棚卸月末在庫テーブル
--        WHERE  xsims.whse_code = gt_main_data(i).whse_code
--        AND    xsims.item_id   = gt_main_data(i).item_id
--        AND   (   xsims.lot_id IS NULL
--               OR xsims.lot_id = gt_main_data(i).lot_id )
--        AND    xsims.invent_ym = ir_param.iv_date_ym               -- 棚卸年月当月のもの
--        GROUP BY xsims.item_id                                     -- 品目ID
--                ,xsims.whse_code                                   -- 倉庫コード
--                ,xsims.lot_id                                      -- ロットID
--                ,xsims.invent_ym                                   -- 棚卸年月
--        ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_month_stock_nw := 0;
--          ln_cargo_stock_nw := 0;
--      END;
--
      -- 棚卸結果情報 データが取得できないときは０
--      BEGIN
--        SELECT SUM( xsir.case_amt )  case_amt                      -- 棚卸ケース数
--              ,SUM( xsir.loose_amt ) loose_amt                     -- 棚卸バラ
--        INTO   ln_case_amt 
--              ,ln_loose_amt
--        FROM   xxinv_stc_inventory_result xsir                     -- 棚卸結果テーブル
--        WHERE  xsir.invent_whse_code = gt_main_data(i).whse_code
--        AND    xsir.item_id          = gt_main_data(i).item_id
--        AND    xsir.lot_id           = gt_main_data(i).lot_id
--        AND    xsir.invent_date      BETWEEN gd_date_ym_first      -- パラメータの対象年月の１日から
--                                     AND     gd_date_ym_last       -- 月末日で取得
--        GROUP BY xsir.item_id                                      -- 品目ID
--                ,xsir.invent_whse_code                             -- 棚卸倉庫
--                ,xsir.lot_id                                       -- ロットID
--      ;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_case_amt  := 0;
--          ln_loose_amt := 0;
--      END;
-- 08/05/07 Y.Yamamoto Delete v1.1 End
--
      -- -----------------------------------------------------
      -- 区分明細計算処理
      -- -----------------------------------------------------
      -- 入数
      BEGIN
        IF (    ir_param.iv_item_div = gc_item_div_seihin ) THEN
          -- 品目区分（製品）
          SELECT TO_NUMBER( NVL( ximv.num_of_cases, '0' ) )          -- ケース入数
          INTO   ln_quantity
          FROM   xxcmn_item_mst2_v  ximv                             -- OPM品目情報VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        ELSIF ( ir_param.iv_item_div = gc_item_div_hanseihin ) 
           OR ( ir_param.iv_item_div = gc_item_div_genryo ) THEN
          -- 品目区分（半製品）もしくは、品目区分（原料）
          SELECT TO_NUMBER( NVL( ilm.attribute6, '0' ) )             -- 在庫入数
          INTO   ln_quantity
          FROM   ic_lots_mst ilm
          WHERE  ilm.item_id = gt_main_data(i).item_id
          AND    ilm.lot_id  = gt_main_data(i).lot_id
          AND    ilm.lot_no  = gt_main_data(i).lot_no
          ;
        ELSIF ( ir_param.iv_item_div = gc_item_div_sizai ) THEN
          -- 品目区分（資材）
          SELECT TO_NUMBER( NVL( ximv.frequent_qty, '0' ) )          -- 代表入数
          INTO   ln_quantity
          FROM   xxcmn_item_mst2_v  ximv                             -- OPM品目情報VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_quantity := 0;
      END;
--
      -- 月初在庫数
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_month_start_stock := ROUND( ln_month_stock_be + ln_cargo_stock_be, 3 );
        ln_month_start_stock := ROUND( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_month_start_stock := ROUND( ( ln_month_stock_be + ln_cargo_stock_be ) / 1, 3 );
          ln_month_start_stock := ROUND( ( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be ) / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_month_start_stock := ROUND( ( ln_month_stock_be + ln_cargo_stock_be ) / ln_quantity, 3 );
          ln_month_start_stock := ROUND( ( gt_main_data(i).month_stock_be + gt_main_data(i).cargo_stock_be ) / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- 当月入庫数
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
        ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity, 3 ) );
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
          ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity / 1, 3 ) );
        ELSE
          ln_stock_quantity := ABS( ROUND( gt_main_data(i).stock_quantity / ln_quantity, 3 ) );
        END IF;
      END IF;
--
      -- 当月出庫数
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
        ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity, 3 ) );
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
          ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity / 1, 3 ) );
        ELSE
          ln_leaving_quantity := ABS( ROUND( gt_main_data(i).leaving_quantity / ln_quantity, 3 ) );
        END IF;
      END IF;
--
      -- 論理月末在庫数
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_logic_month_stock := ROUND( ln_month_stock_nw + ln_cargo_stock_nw, 3 );
        ln_logic_month_stock := ROUND( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_logic_month_stock := ROUND( ( ln_month_stock_nw + ln_cargo_stock_nw ) / 1, 3 );
          ln_logic_month_stock := ROUND( ( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw ) / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_logic_month_stock := ROUND( ( ln_month_stock_nw + ln_cargo_stock_nw ) / ln_quantity, 3 );
          ln_logic_month_stock := ROUND( ( gt_main_data(i).month_stock_nw + gt_main_data(i).cargo_stock_nw ) / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- 実棚月末在庫数
      IF ( ln_quantity = 0 ) THEN
        BEGIN
-- 08/05/21 v1.8 mod start
--          SELECT ROUND( TO_NUMBER( NVL( ximv.num_of_cases, '0' ) ), 3 ) -- ケース入数
          SELECT ROUND( TO_NUMBER( NVL( ximv.num_of_cases, '1' ) ), 3 ) -- ケース入数
-- 08/05/21 v1.8 mod end
          INTO   ln_num_of_cases
          FROM   xxcmn_item_mst2_v  ximv                                -- OPM品目情報VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_num_of_cases := 0;
        END;
      END IF;
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
        IF ( ln_quantity = 0 ) THEN
-- 08/05/21 v1.8 mod start
--          ln_invent_month_stock := ln_num_of_cases;
          ln_invent_month_stock := ROUND( ( ln_num_of_cases * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt, 3 );
-- 08/05/21 v1.8 mod end
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_month_stock := ROUND( ( ln_quantity * ln_case_amt ) + ln_loose_amt, 3 );
          ln_invent_month_stock := ROUND( ( ln_quantity * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
-- 08/05/21 v1.8 mod start
--          ln_invent_month_stock := ln_num_of_cases;
          ln_invent_month_stock := ROUND( ( ( ln_num_of_cases * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt )
                                                                          / ln_num_of_cases, 3 );
-- 08/05/21 v1.8 mod end
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_month_stock := ROUND( ( ( ln_quantity * ln_case_amt ) + ln_loose_amt )
--                                                                          / ln_quantity, 3 );
          ln_invent_month_stock := ROUND( ( ( ln_quantity * gt_main_data(i).case_amt ) + gt_main_data(i).loose_amt )
                                                                          / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- 実棚積送在庫数
      IF (    ir_param.iv_um_class = gc_um_class_honsu ) THEN
        -- 単位区分（本数）
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--        ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw, 3 );
        ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
      ELSIF ( ir_param.iv_um_class = gc_um_class_case ) THEN
        -- 単位区分（ケース）
        IF ( ln_quantity = 0 ) THEN
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw / 1, 3 );
          ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw / 1, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        ELSE
-- 08/05/07 Y.Yamamoto Update v1.1 Start
--          ln_invent_cargo_stock := ROUND( ln_cargo_stock_nw / ln_quantity, 3 );
          ln_invent_cargo_stock := ROUND( gt_main_data(i).cargo_stock_nw / ln_quantity, 3 );
-- 08/05/07 Y.Yamamoto Update v1.1 End
        END IF;
      END IF;
--
      -- 差異数
      ln_month_stock := ROUND( ROUND( ln_logic_month_stock - ln_invent_month_stock, 3 )
                                                           - ln_invent_cargo_stock, 3 );
--
      -- 在庫単価、在庫金額の算出（外部ユーザーは行わない）
      IF ( gv_employee_div = gc_employee_div_out ) THEN
        ln_stock_unit_price    := NULL;                               -- 在庫単価
        ln_logic_stock_amount  := NULL;                               -- 論理在庫金額
        ln_invent_stock_amount := NULL;                               -- 実棚在庫金額
        ln_month_stock_amount  := NULL;                               -- 差異金額
      ELSE
        -- 在庫単価
        BEGIN
          SELECT ximv.cost_manage_code                                -- 原価管理区分
          INTO   lv_cost_manage_code
          FROM   xxcmn_item_mst2_v ximv                               -- OPM品目情報VIEW2
          WHERE  ximv.item_id     = gt_main_data(i).item_id
          AND    ximv.item_no     = gt_main_data(i).item_no
          AND    gd_date_ym_first BETWEEN ximv.start_date_active
                                  AND     ximv.end_date_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_cost_manage_code := 0;
        END;
--
        BEGIN
          IF (    lv_cost_manage_code = gc_cost_manage_code_hyozyun ) THEN
            -- 原価管理区分（標準）
            SELECT ROUND( SUM( ccd.cmpnt_cost ), 2 )                    -- コンポーネント原価
            INTO   ln_stock_unit_price
            FROM   cm_cmpt_dtl       ccd                                -- 品目原価マスタ
                  ,cm_cldr_dtl       ccld                               -- 原価カレンダ明細
            WHERE  ccd.item_id        = gt_main_data(i).item_id
            AND    ccd.whse_code      = FND_PROFILE.VALUE(gc_cost_whse_code)
            AND    ccd.cost_mthd_code = FND_PROFILE.VALUE(gc_cost_div)
            AND    ccd.calendar_code  = ccld.calendar_code
            AND    ccd.period_code    = ccld.period_code
            AND    gd_date_ym_first   BETWEEN ccld.start_date
                                      AND     ccld.end_date
            GROUP BY ccd.item_id
            ;
          ELSIF ( lv_cost_manage_code = gc_cost_manage_code_jissei ) THEN
            -- 原価管理区分（実勢）
            SELECT ROUND( TO_NUMBER( NVL( ilm.attribute7, '0' ) ), 2 )  -- 在庫単価
            INTO   ln_stock_unit_price
            FROM   ic_lots_mst ilm                                      -- OPMロットマスタ
            WHERE  ilm.item_id = gt_main_data(i).item_id
            AND    ilm.lot_id  = gt_main_data(i).lot_id
            AND    ilm.lot_no  = gt_main_data(i).lot_no
            ;
          ELSE
            ln_stock_unit_price := 0;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_stock_unit_price := 0;
        END;
--
        -- 論理在庫金額
        ln_logic_stock_amount  := ROUND( ln_logic_month_stock  * ln_stock_unit_price );
--
        -- 実棚在庫金額
        ln_invent_stock_amount := ROUND( ln_invent_month_stock * ln_stock_unit_price );
--
        -- 差異金額
        ln_month_stock_amount  := ln_logic_stock_amount - ln_invent_stock_amount;
      END IF;
--
      IF  ( ir_param.iv_output_ctl = gc_output_ctl_all ) 
       OR ( ir_param.iv_output_ctl = gc_output_ctl_sel AND ln_month_stock <> 0 ) THEN
        -- 差異区分（ALL）もしくは差異区分（差異があるもの）で差異数が発生しているものを出力
        -- =====================================================
        -- 入庫倉庫ブレイク
        -- =====================================================
        -- 入庫倉庫が切り替わったとき
        IF ( gt_main_data(i).whse_code <> lv_loc_code ) THEN
          -- -----------------------------------------------------
          -- 入庫倉庫明細Ｇ終了タグ出力
          -- -----------------------------------------------------
          -- 最初のレコードのときは出力しない
          IF ( lv_loc_code <> lc_break_init ) THEN
            -- -----------------------------------------------------
            -- 単位開始タグ出力
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- 単位データタグ出力
            -- -----------------------------------------------------
            -- 単位
--mod start 1.9
--            insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( gt_main_data(i).item_um, 1, 4 ),
            insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
--mod end 1.9
                                                                gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
            -- -----------------------------------------------------
            -- ロット管理区分データタグ出力
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                                gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
            -- -----------------------------------------------------
            -- 単位終了タグ出力
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- 区分明細Ｇ終了タグ出力
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
            -- -----------------------------------------------------
            -- 入庫倉庫明細Ｇ終了タグ出力
            -- -----------------------------------------------------
            insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          END IF;
          -- -----------------------------------------------------
          -- 入庫倉庫明細Ｇ開始タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 入庫倉庫明細Ｇデータタグ出力
          -- -----------------------------------------------------
          -- 入庫倉庫コード
          insert_xml_plsql_table(iox_xml_data, 'whse_code', SUBSTRB( gt_main_data(i).whse_code, 1, 4 ),
                                                              gc_tag_type_data, gc_tag_value_type_char);
--
          -- 入庫倉庫名取得
          BEGIN
            SELECT SUBSTRB( MAX( xilv.whse_name ), 1, 20 )
            INTO   lv_whse_name
            FROM   xxcmn_item_locations2_v xilv
            WHERE  xilv.whse_code     = gt_main_data(i).whse_code
            AND    xilv.disable_date IS NULL
            AND    gd_date_ym_first  BETWEEN xilv.date_from
                                         AND NVL( xilv.date_to, gd_max_date )
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_whse_name := NULL;
          END;
--
          -- 入庫倉庫先名
          insert_xml_plsql_table(iox_xml_data, 'whse_name', lv_whse_name,
                                                              gc_tag_type_data, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 区分明細Ｇ開始タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 入庫倉庫ブレイクキー更新
          -- -----------------------------------------------------
          lv_loc_code := gt_main_data(i).whse_code;
          -- -----------------------------------------------------
          -- 品目コードブレイクキー更新
          -- -----------------------------------------------------
          lv_item_no_key := gt_main_data(i).item_no;
        END IF;
--
        -- =====================================================
        -- 品目コードブレイク
        -- =====================================================
        -- 品目コードが切り替わったとき
        IF ( gt_main_data(i).item_no <> lv_item_no_key ) THEN
          -- -----------------------------------------------------
          -- 単位開始タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 単位データタグ出力
          -- -----------------------------------------------------
          -- 単位
--mod start 1.9
--          insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( gt_main_data(i).item_um, 1, 4 ),
          insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
--mod end 1.9
                                                              gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
          -- -----------------------------------------------------
          -- ロット管理区分データタグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                              gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
          -- -----------------------------------------------------
          -- 単位終了タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 品目明細Ｇ終了タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 品目明細Ｇ開始タグ出力
          -- -----------------------------------------------------
          insert_xml_plsql_table(iox_xml_data, 'g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
          -- -----------------------------------------------------
          -- 品目コードブレイクキー更新
          -- -----------------------------------------------------
          lv_item_no_key := gt_main_data(i).item_no;
        END IF;
--
        -- -----------------------------------------------------
        -- 区分明細Ｇ開始タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, 'g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 区分明細Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 品目（コード）
        insert_xml_plsql_table(iox_xml_data, 'item_code', SUBSTRB( TO_CHAR( gt_main_data(i).item_no ), 1, 7 ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 品目（名）
        insert_xml_plsql_table(iox_xml_data, 'item_name', lv_item_short_name, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- ロットNo
        IF ( ln_lot_ctl = gc_lot_ctl_1 ) THEN
          -- ロット管理品
          insert_xml_plsql_table(iox_xml_data, 'lot_no', gt_main_data(i).lot_no, 
                                                              gc_tag_type_data, gc_tag_value_type_char);
        ELSE
          -- ロット非管理品
          insert_xml_plsql_table(iox_xml_data, 'lot_no', NULL, 
                                                              gc_tag_type_data, gc_tag_value_type_char);
        END IF;
        -- 製造年月日
        insert_xml_plsql_table(iox_xml_data, 'manufacture_date', gt_main_data(i).manufacture_date, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 賞味期限
        insert_xml_plsql_table(iox_xml_data, 'expiration_date', gt_main_data(i).expiration_date, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 固有記号
        insert_xml_plsql_table(iox_xml_data, 'uniqe_sign', gt_main_data(i).uniqe_sign, 
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- 入数
        insert_xml_plsql_table(iox_xml_data, 'quantity', TO_CHAR( ln_quantity ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 月初在庫数
        insert_xml_plsql_table(iox_xml_data, 'month_start_stock', TO_CHAR( ln_month_start_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 当月入庫数
        insert_xml_plsql_table(iox_xml_data, 'stock_quantity', TO_CHAR( ln_stock_quantity ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 当月出庫数
        insert_xml_plsql_table(iox_xml_data, 'leaving_quantity', TO_CHAR( ln_leaving_quantity ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- 論理月末在庫数
        insert_xml_plsql_table(iox_xml_data, 'logic_month_stock', TO_CHAR( ln_logic_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 実棚月末在庫数
        insert_xml_plsql_table(iox_xml_data, 'invent_month_stock', TO_CHAR( ln_invent_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 実棚積送在庫数
        insert_xml_plsql_table(iox_xml_data, 'invent_cargo_stock', TO_CHAR( ln_invent_cargo_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 差異数
        insert_xml_plsql_table(iox_xml_data, 'month_stock', TO_CHAR( ln_month_stock ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
--
        -- 在庫単価
        insert_xml_plsql_table(iox_xml_data, 'stock_unit_price', TO_CHAR( ln_stock_unit_price ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 論理在庫金額
        insert_xml_plsql_table(iox_xml_data, 'logic_stock_amount', TO_CHAR( ln_logic_stock_amount ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 実棚在庫金額
        insert_xml_plsql_table(iox_xml_data, 'invent_stock_amount', TO_CHAR( ln_invent_stock_amount ),
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- 差異金額
        insert_xml_plsql_table(iox_xml_data, 'month_stock_amount', TO_CHAR( ln_month_stock_amount ), 
                                                            gc_tag_type_data, gc_tag_value_type_char);
        -- -----------------------------------------------------
        -- 区分明細Ｇ終了タグ出力
        -- -----------------------------------------------------
        insert_xml_plsql_table(iox_xml_data, '/g_ic_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
        -- =====================================================
        -- 明細のデータを出力したのでフラグON
        -- =====================================================
        lv_data_out := '1';
-- 08/05/09 Y.Yamamoto ADD v1.2 End
      END IF;
--
      -- -----------------------------------------------------
      -- 単位保存
      -- -----------------------------------------------------
      lv_last_item_um := gt_main_data(i).item_um;
--add start 2.0
      lv_prev_lot_ctl := TO_CHAR(ln_lot_ctl);
--add end 2.0
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- 明細の出力を行っていない時には「データはありません」メッセージを出力
    -- =====================================================
    IF ( lv_data_out = '0' ) THEN
      -- -----------------------------------------------------
      -- 入庫倉庫明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      insert_xml_plsql_table(iox_xml_data, 'g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
      -- -----------------------------------------------------
      -- データ無メッセージ出力
      -- -----------------------------------------------------
      lv_no_data_msg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                 ,gc_xxcmn_10122 ) ;
      insert_xml_plsql_table(iox_xml_data, 'msg', lv_no_data_msg,
                                                  gc_tag_type_data, gc_tag_value_type_char);
    ELSE
      -- 以下は明細の出力
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- -----------------------------------------------------
    -- 単位開始タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 単位データタグ出力
    -- -----------------------------------------------------
    -- 単位
    insert_xml_plsql_table(iox_xml_data, 'item_um', SUBSTRB( lv_last_item_um, 1, 4 ),
                                                        gc_tag_type_data, gc_tag_value_type_char);
--add start 2.0
    -- -----------------------------------------------------
    -- ロット管理区分データタグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, 'lot_ctl', lv_prev_lot_ctl,
                                                        gc_tag_type_data, gc_tag_value_type_char);
--add end 2.0
    -- -----------------------------------------------------
    -- 単位終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_ic_total', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 区分明細Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_il_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
-- 08/05/09 Y.Yamamoto ADD v1.2 Start
    -- =====================================================
    -- 明細の出力時、ここまで
    -- =====================================================
    END IF;
-- 08/05/09 Y.Yamamoto ADD v1.2 End
    -- -----------------------------------------------------
    -- 入庫倉庫明細Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc_dtl', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- 倉庫Ｇ終了タグ出力
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/g_itemloc',            NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/lg_itemlocation_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    -- -----------------------------------------------------
    -- データＧ終了タグ
    -- -----------------------------------------------------
    insert_xml_plsql_table(iox_xml_data, '/data_info', NULL, gc_tag_type_tag, gc_tag_value_type_char);
    insert_xml_plsql_table(iox_xml_data, '/root', NULL, gc_tag_type_tag, gc_tag_value_type_char);
--
  EXCEPTION
    -- *** 取得データ０件 ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn
                                             ,gc_xxcmn_10122 ) ;
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
  PROCEDURE submain
    (
      iv_date_ym            IN     VARCHAR2         --   01 : 対象年月
     ,iv_whse_dept1         IN     VARCHAR2         --   02 : 倉庫管理部署1
     ,iv_whse_dept2         IN     VARCHAR2         --   03 : 倉庫管理部署2
     ,iv_whse_dept3         IN     VARCHAR2         --   04 : 倉庫管理部署3
     ,iv_whse_code1         IN     VARCHAR2         --   05 : 倉庫コード1
     ,iv_whse_code2         IN     VARCHAR2         --   06 : 倉庫コード2
     ,iv_whse_code3         IN     VARCHAR2         --   07 : 倉庫コード3
     ,iv_block_code1        IN     VARCHAR2         --   08 : ブロック1
     ,iv_block_code2        IN     VARCHAR2         --   09 : ブロック2
     ,iv_block_code3        IN     VARCHAR2         --   10 : ブロック3
     ,iv_item_class         IN     VARCHAR2         --   11 : 商品区分
     ,iv_um_class           IN     VARCHAR2         --   12 : 単位区分
     ,iv_item_div           IN     VARCHAR2         --   13 : 品目区分
     ,iv_item_no1           IN     VARCHAR2         --   14 : 品目コード1
     ,iv_item_no2           IN     VARCHAR2         --   15 : 品目コード2
     ,iv_item_no3           IN     VARCHAR2         --   16 : 品目コード3
     ,iv_create_date1       IN     VARCHAR2         --   17 : 製造年月日1
     ,iv_create_date2       IN     VARCHAR2         --   18 : 製造年月日2
     ,iv_create_date3       IN     VARCHAR2         --   19 : 製造年月日3
     ,iv_lot_no1            IN     VARCHAR2         --   20 : ロットNo1
     ,iv_lot_no2            IN     VARCHAR2         --   21 : ロットNo2
     ,iv_lot_no3            IN     VARCHAR2         --   22 : ロットNo3
     ,iv_output_ctl         IN     VARCHAR2         --   23 : 差異データ区分
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
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain' ; -- プログラム名
    -- ======================================================
    -- ローカル変数
    -- ======================================================
    lv_errbuf   VARCHAR2(5000) ;                      --   エラー・メッセージ
    lv_retcode  VARCHAR2(1) ;                         --   リターン・コード
    lv_errmsg   VARCHAR2(5000) ;                      --   ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ======================================================
    -- ユーザー宣言部
    -- ======================================================
    -- *** ローカル変数 ***
    lr_param_rec     rec_param_data ;          -- パラメータ受渡し用
--
    xml_data_table   XML_DATA;
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
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
    gd_exec_date                 := SYSDATE ;               -- 実施日
    -- パラメータ格納
    lr_param_rec.iv_date_ym      := iv_date_ym ;            -- 対象年月
    lr_param_rec.iv_whse_dept1   := iv_whse_dept1 ;         -- 倉庫管理部署1
    lr_param_rec.iv_whse_dept2   := iv_whse_dept2 ;         -- 倉庫管理部署2
    lr_param_rec.iv_whse_dept3   := iv_whse_dept3 ;         -- 倉庫管理部署3
    lr_param_rec.iv_whse_code1   := iv_whse_code1 ;         -- 倉庫コード1
    lr_param_rec.iv_whse_code2   := iv_whse_code2 ;         -- 倉庫コード2
    lr_param_rec.iv_whse_code3   := iv_whse_code3 ;         -- 倉庫コード3
    lr_param_rec.iv_block_code1  := iv_block_code1 ;        -- ブロック1
    lr_param_rec.iv_block_code2  := iv_block_code2 ;        -- ブロック2
    lr_param_rec.iv_block_code3  := iv_block_code3 ;        -- ブロック3
    lr_param_rec.iv_item_class   := iv_item_class ;         -- 商品区分
    lr_param_rec.iv_um_class     := iv_um_class ;           -- 単位区分
    lr_param_rec.iv_item_div     := iv_item_div ;           -- 品目区分
    lr_param_rec.iv_item_no1     := iv_item_no1 ;           -- 品目コード1
    lr_param_rec.iv_item_no2     := iv_item_no2 ;           -- 品目コード2
    lr_param_rec.iv_item_no3     := iv_item_no3 ;           -- 品目コード3
-- UPDATE START 2008/5/20 YTabata --
    lr_param_rec.iv_create_date1                            -- 製造年月日1
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date1 ),gc_char_d_format);
    lr_param_rec.iv_create_date2                            -- 製造年月日2
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date2 ),gc_char_d_format);
    lr_param_rec.iv_create_date3                            -- 製造年月日3
      :=  TO_CHAR(FND_DATE.CANONICAL_TO_DATE(iv_create_date3 ),gc_char_d_format);
/**
    lr_param_rec.iv_create_date1 := iv_create_date1 ;       -- 製造年月日1
    lr_param_rec.iv_create_date2 := iv_create_date2 ;       -- 製造年月日2
    lr_param_rec.iv_create_date3 := iv_create_date3 ;       -- 製造年月日3
**/
-- UPDATE END 2008/5/20 YTabata --
    lr_param_rec.iv_lot_no1      := iv_lot_no1 ;            -- ロットNo1
    lr_param_rec.iv_lot_no2      := iv_lot_no2 ;            -- ロットNo2
    lr_param_rec.iv_lot_no3      := iv_lot_no3 ;            -- ロットNo3
    lr_param_rec.iv_output_ctl   := iv_output_ctl ;         -- 差異データ区分
    -- 最大日付設定
    gd_max_date                  := FND_DATE.STRING_TO_DATE( gc_max_date_d, gc_char_d_format );
--
    -- ====================================================
    -- 担当部署取得
    -- ====================================================
    gv_department_code := SUBSTRB( xxcmn_common_pkg.get_user_dept( FND_GLOBAL.USER_ID ), 1, 10 ) ;
--
    -- ====================================================
    -- 担当者取得
    -- ====================================================
    gv_department_name := SUBSTRB( xxcmn_common_pkg.get_user_name( FND_GLOBAL.USER_ID ), 1, 14 ) ;
--
    -- ====================================================
    -- 従業員区分取得
    -- ====================================================
    SELECT papf.attribute3
    INTO   gv_employee_div
    FROM   fnd_user         fu
          ,per_all_people_f papf
    WHERE  fu.user_id     = FND_GLOBAL.USER_ID
    AND    papf.person_id = fu.employee_id
-- 08/05/20 add v1.5 start
-- 08/07/16 Y.Yamamoto Update v1.14 Start
--    AND    SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,SYSDATE)
    AND    TRUNC( SYSDATE ) BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,TRUNC( SYSDATE ))
-- 08/07/16 Y.Yamamoto Update v1.14 Start
-- 08/05 20 add v1.5 end
    ;
--
    -- =====================================================
    -- パラメータチェック(A-1)
    -- =====================================================
    prc_check_param_info
      (
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
    -- 棚卸スナップショット作成プログラム呼出(A-2)
    -- =====================================================
    prc_call_xxinv550004c
      (
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
    -- 帳票データ出力(A-3,4)
    -- =====================================================
    prc_create_xml_data
      (
        xml_data_table
       ,ir_param          => lr_param_rec       -- 入力パラメータレコード
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- ＸＭＬ出力(A-5)
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <msg>'        || lv_errmsg       || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </g_itemloc_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_itemloc>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_itemlocation_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- --------------------------------------------------
    -- 帳票データが出力できた場合
    -- --------------------------------------------------
    ELSE
      --XMLデータ部出力
      <<xml_loop>>
      FOR i IN 1 .. xml_data_table.COUNT LOOP
        -- 編集したデータをタグに変換
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => xml_data_table(i).tag_name    -- タグネーム
                           ,iv_value  => xml_data_table(i).tag_value   -- タグデータ
                           ,ic_type   => xml_data_table(i).tag_type    -- タグタイプ
                          ) ;
        -- ＸＭＬタグ出力
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_loop ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_date_ym            IN     VARCHAR2         -- 01 : 対象年月
     ,iv_whse_dept1         IN     VARCHAR2         -- 02 : 倉庫管理部署1
     ,iv_whse_dept2         IN     VARCHAR2         -- 03 : 倉庫管理部署2
     ,iv_whse_dept3         IN     VARCHAR2         -- 04 : 倉庫管理部署3
     ,iv_whse_code1         IN     VARCHAR2         -- 05 : 倉庫コード1
     ,iv_whse_code2         IN     VARCHAR2         -- 06 : 倉庫コード2
     ,iv_whse_code3         IN     VARCHAR2         -- 07 : 倉庫コード3
     ,iv_block_code1        IN     VARCHAR2         -- 08 : ブロック1
     ,iv_block_code2        IN     VARCHAR2         -- 09 : ブロック2
     ,iv_block_code3        IN     VARCHAR2         -- 10 : ブロック3
     ,iv_item_class         IN     VARCHAR2         -- 11 : 商品区分
     ,iv_um_class           IN     VARCHAR2         -- 12 : 単位区分
     ,iv_item_div           IN     VARCHAR2         -- 13 : 品目区分
     ,iv_item_no1           IN     VARCHAR2         -- 14 : 品目コード1
     ,iv_item_no2           IN     VARCHAR2         -- 15 : 品目コード2
     ,iv_item_no3           IN     VARCHAR2         -- 16 : 品目コード3
     ,iv_create_date1       IN     VARCHAR2         -- 17 : 製造年月日1
     ,iv_create_date2       IN     VARCHAR2         -- 18 : 製造年月日2
     ,iv_create_date3       IN     VARCHAR2         -- 19 : 製造年月日3
     ,iv_lot_no1            IN     VARCHAR2         -- 20 : ロットNo1
     ,iv_lot_no2            IN     VARCHAR2         -- 21 : ロットNo2
     ,iv_lot_no3            IN     VARCHAR2         -- 22 : ロットNo3
     ,iv_output_ctl         IN     VARCHAR2         -- 23 : 差異データ区分
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
    submain
      (
        iv_date_ym         => iv_date_ym          -- 01 : 対象年月
       ,iv_whse_dept1      => iv_whse_dept1       -- 02 : 倉庫管理部署1
       ,iv_whse_dept2      => iv_whse_dept2       -- 03 : 倉庫管理部署2
       ,iv_whse_dept3      => iv_whse_dept3       -- 04 : 倉庫管理部署3
       ,iv_whse_code1      => iv_whse_code1       -- 05 : 倉庫コード1
       ,iv_whse_code2      => iv_whse_code2       -- 06 : 倉庫コード2
       ,iv_whse_code3      => iv_whse_code3       -- 07 : 倉庫コード3
       ,iv_block_code1     => iv_block_code1      -- 08 : ブロック1
       ,iv_block_code2     => iv_block_code2      -- 09 : ブロック2
       ,iv_block_code3     => iv_block_code3      -- 10 : ブロック3
       ,iv_item_class      => iv_item_class       -- 11 : 商品区分
       ,iv_um_class        => iv_um_class         -- 12 : 単位区分
       ,iv_item_div        => iv_item_div         -- 13 : 品目区分
       ,iv_item_no1        => iv_item_no1         -- 14 : 品目コード1
       ,iv_item_no2        => iv_item_no2         -- 15 : 品目コード2
       ,iv_item_no3        => iv_item_no3         -- 16 : 品目コード3
       ,iv_create_date1    => iv_create_date1     -- 17 : 製造年月日1
       ,iv_create_date2    => iv_create_date2     -- 18 : 製造年月日2
       ,iv_create_date3    => iv_create_date3     -- 19 : 製造年月日3
       ,iv_lot_no1         => iv_lot_no1          -- 20 : ロットNo1
       ,iv_lot_no2         => iv_lot_no2          -- 21 : ロットNo2
       ,iv_lot_no3         => iv_lot_no3          -- 22 : ロットNo3
       ,iv_output_ctl      => iv_output_ctl       -- 23 : 差異データ区分
       ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode          -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
     ) ;
--
--###########################  固定部 START   #####################################################
--
    -- ======================================================
    -- エラー・メッセージ出力
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxinv550001c ;
/
