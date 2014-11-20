CREATE OR REPLACE PACKAGE BODY xxpo780001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo780001c(body)
 * Description      : 月次〆切処理（有償支給相殺）
 * MD.050/070       : 月次〆切処理（有償支給相殺）Issue1.0  (T_MD050_BPO_780)
 *                    計算書                                (T_MD070_BPO_78A)
 * Version          : 1.7
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : ＸＭＬタグに変換する。
 *  prc_check_param_info      PROCEDURE : パラメータチェック(A-1)
 *  prc_initialize            PROCEDURE : 前処理(A-2)
 *  prc_get_report_data       PROCEDURE : 明細データ取得(A-3)
 *  prc_create_xml_data       PROCEDURE : ＸＭＬデータ作成(A-4)
 *  submain                   PROCEDURE : メイン処理プロシージャ
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/03    1.0   Masayuki Ikeda   新規作成
 *  2008/02/06    1.1   Masayuki Ikeda   ・受注明細アドオンと品目マスタを紐付ける場合、ＩＮＶ
 *                                         品目マスタを仲介する。
 *                                       ・メッセージコードを修正
 *  2008/03/10    1.2   Masayuki Ikeda   ・変更要求No.81対応
 *  2008/06/20    1.3  Yasuhisa Yamamoto ST不具合対応#135
 *  2008/07/29    1.4   Satoshi Yunba    禁則文字対応
 *  2008/12/05    1.5  Tsuyoki Yoshimoto 本番障害#446
 *  2008/12/25    1.6  Takao Ohashi      本番障害#848,850
 *  2009/03/04    1.7  Akiyoshi Shiina   本番障害#1266対応
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
  gv_pkg_name             CONSTANT VARCHAR2(20) := 'xxpo780001c' ;   -- パッケージ名
--
  ------------------------------
  -- クイックコード関連
  ------------------------------
  gc_language_code              CONSTANT VARCHAR2(2)   := 'JA' ;
  gc_enable_flag                CONSTANT VARCHAR2(2)   := 'Y' ;
  gc_lookup_type_shikyu_class   CONSTANT VARCHAR2(100) := 'XXWSH_SHIPPING_SHIKYU_CLASS' ;
  gc_lookup_type_fix_class      CONSTANT VARCHAR2(100) := 'XXWSH_AMOUNT_FIX_CLASS' ;
  gc_lookup_type_tax_rate       CONSTANT VARCHAR2(100) := 'XXCMN_CONSUMPTION_TAX_RATE' ;
  gc_lookup_meaning_shikyu_irai CONSTANT VARCHAR2(100) := '支給依頼' ;
  gc_lookup_meaning_kakutei     CONSTANT VARCHAR2(100) := '確定' ;
--
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
  gc_ship_rcv_pay_ctg_mhn       CONSTANT VARCHAR2(2)   := '01' ;    -- 見本出庫
  gc_ship_rcv_pay_ctg_hik       CONSTANT VARCHAR2(2)   := '02' ;    -- 廃棄出庫
  gc_ship_rcv_pay_ctg_kra       CONSTANT VARCHAR2(2)   := '03' ;    -- 倉替入庫
  gc_ship_rcv_pay_ctg_hen       CONSTANT VARCHAR2(2)   := '04' ;    -- 返品入庫
  gc_ship_rcv_pay_ctg_ysy       CONSTANT VARCHAR2(2)   := '05' ;    -- 有償出荷
  gc_ship_rcv_pay_ctg_yhe       CONSTANT VARCHAR2(2)   := '06' ;    -- 有償返品
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
--
  ------------------------------
  -- 品目カテゴリ関連
  ------------------------------
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '品目区分' ;
--
  ------------------------------
  -- エラーメッセージ関連
  ------------------------------
  gc_application_cmn      CONSTANT VARCHAR2(5)  := 'XXCMN' ;            -- アプリケーション（XXCMN）
  gc_application_po       CONSTANT VARCHAR2(5)  := 'XXPO' ;             -- アプリケーション（XXPO）
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  gc_jp_yy                CONSTANT VARCHAR2(2)  := '年' ;
  gc_jp_mm                CONSTANT VARCHAR2(2)  := '月' ;
  gc_jp_dd                CONSTANT VARCHAR2(2)  := '日' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
-- add start ver1.6
  ------------------------------
  -- 参照コード
  ------------------------------
  -- 移動ロット詳細アドオン：文書タイプ
  gc_doc_type_prov        CONSTANT VARCHAR2(2)  := '30';    -- 支給指示
  -- 移動ロット詳細アドオン：レコードタイプ
  gc_rec_type_stck        CONSTANT VARCHAR2(2)  := '20';    -- 出庫実績
-- add end ver1.6
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納用レコード変数
  TYPE rec_param_data  IS RECORD 
    (
      fiscal_ym           VARCHAR2(6)                                               -- 〆切年月
     ,dept_code           xxwsh_order_headers_all.performance_management_dept%TYPE  -- 請求管理部署
     ,vendor_code         xxwsh_order_headers_all.vendor_code%TYPE                  -- 取引先
    ) ;
--
  -- 計算書データ格納用レコード変数
  TYPE rec_data_type_dtl  IS RECORD 
    (
-- mod start ver1.6
--      v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- 取引先：取引先名称
      vendor_code           xxwsh_order_headers_all.vendor_code%TYPE -- 取引先：取引先コード
     ,v_vendor_name         xxcmn_vendors.vendor_name%TYPE          -- 取引先：取引先名称
-- mod end ver1.6
     ,v_zip                 xxcmn_vendors.zip%TYPE                  -- 取引先：郵便番号
     ,v_address_line1       xxcmn_vendors.address_line1%TYPE        -- 取引先：住所１
     ,v_address_line2       xxcmn_vendors.address_line2%TYPE        -- 取引先：住所２
     ,l_location_name       xxcmn_locations_all.location_name%TYPE  -- 事業所：事業所名称
     ,l_zip                 xxcmn_locations_all.zip%TYPE            -- 事業所：郵便番号
     ,l_address_line1       xxcmn_locations_all.address_line1%TYPE  -- 事業所：住所１
     ,l_phone               xxcmn_locations_all.phone%TYPE          -- 事業所：電話番号
     ,l_fax                 xxcmn_locations_all.fax%TYPE            -- 事業所：ＦＡＸ番号
     ,item_class            xxwsh_order_headers_all.item_class%TYPE           -- 品目区分
     ,arrival_date          xxwsh_order_headers_all.arrival_date%TYPE         -- 着荷日
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--     ,request_no            xxwsh_order_headers_all.request_no%TYPE
     ,request_no            VARCHAR2(13)                                      -- 依頼No（伝票番号）
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
     ,item_code             xxwsh_order_lines_all.shipping_item_code%TYPE     -- 品目コード
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE             -- 品目名称
     ,unit_price            xxwsh_order_lines_all.unit_price%TYPE             -- 単価
     ,tax_rate              fnd_lookup_values.lookup_code%TYPE                -- 消費税率
-- add start ver1.6
     ,amount                NUMBER                                            -- 金額
     ,tax                   NUMBER                                            -- 消費税
-- add end ver1.6
     ,quantity              xxwsh_order_lines_all.quantity%TYPE               -- 出荷実績数量
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  ------------------------------
  -- ＳＱＬ条件用
  ------------------------------
  gn_sales_class            oe_transaction_types_all.org_id%type ;  -- 営業単位
  gd_fiscal_date_from       DATE ;                                  -- 対象年月日From
  gv_fiscal_date_from_char  VARCHAR2(14) ;                          -- 対象年月日From（和暦）
  gd_fiscal_date_to         DATE ;                                  -- 対象年月日To
  gv_fiscal_date_to_char    VARCHAR2(14) ;                          -- 対象年月日To（和暦）
--
  ------------------------------
  -- ＸＭＬ用
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- 帳票ID
  gd_exec_date              DATE         ;    -- 実施日
--
  gt_main_data              tab_data_type_dtl ;       -- 取得レコード表
  gt_xml_data_table         XML_DATA ;                -- ＸＭＬデータタグ表
  gl_xml_idx                NUMBER ;                  -- ＸＭＬデータタグ表のインデックス
  ------------------------------
  -- ルックアップ用
  ------------------------------
  gv_fix_class              fnd_lookup_values.lookup_code%TYPE ;
  gv_shikyu_class           fnd_lookup_values.lookup_code%TYPE ;
--
  ------------------------------
  -- プロファイル用
  ------------------------------
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
  gc_prof_mst_org_id        CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID' ; -- 品目マスタ組織
  gn_prof_mst_org_id        NUMBER ;              -- 品目マスタ組織ID
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
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
  FUNCTION fnc_conv_xml
    (
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
    -- 対象年月
    -- ====================================================
    -- 日付変換チェック
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.fiscal_ym ) ;
    IF ( ln_ret_num = 1 ) THEN
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00004' ;
--      lv_err_code := 'APP-XXPO-10004' ;
      lv_err_code := 'APP-XXPO-10211' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE parameter_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** パラメータチェック例外 ***
    WHEN parameter_check_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_po
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
   * Procedure Name   : prc_initialize
   * Description      : 前処理(A-2)
   ***********************************************************************************/
  PROCEDURE prc_initialize
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
    ln_data_cnt           NUMBER := 0 ;   -- データ件数取得用
    lv_err_code           VARCHAR2(100) ; -- エラーコード格納用
    lv_token_name1        VARCHAR2(100) ;      -- メッセージトークン名１
    lv_token_name2        VARCHAR2(100) ;      -- メッセージトークン名２
    lv_token_value1       VARCHAR2(100) ;      -- メッセージトークン値１
    lv_token_value2       VARCHAR2(100) ;      -- メッセージトークン値２
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
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00005' ;
--      lv_err_code := 'APP-XXPO-10005' ;
      lv_err_code := 'APP-XXPO-10212' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 対象年月取得
    -- ====================================================
    -- 対象年月日From
    gd_fiscal_date_from       := FND_DATE.CANONICAL_TO_DATE( ir_param.fiscal_ym || '01' ) ;
    gv_fiscal_date_from_char  := TO_CHAR( gd_fiscal_date_from, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_from, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_from, 'DD' )   || gc_jp_dd ;
    -- 対象年月日To
    gd_fiscal_date_to         := LAST_DAY( gd_fiscal_date_from ) ;
    gv_fiscal_date_to_char    := TO_CHAR( gd_fiscal_date_to, 'YYYY' ) || gc_jp_yy
                              || TO_CHAR( gd_fiscal_date_to, 'MM' )   || gc_jp_mm
                              || TO_CHAR( gd_fiscal_date_to, 'DD' )   || gc_jp_dd ;
--
    -- ====================================================
    -- 消費税取得
    -- ====================================================
    SELECT COUNT( lookup_code )
    INTO   ln_data_cnt
    FROM fnd_lookup_values
    WHERE gd_fiscal_date_from BETWEEN NVL( START_DATE_ACTIVE, gd_fiscal_date_from )
                              AND     NVL( END_DATE_ACTIVE  , gd_fiscal_date_from )
    AND   enabled_flag        = gc_enable_flag
    AND   language            = gc_language_code
    AND   source_lang         = gc_language_code
    AND   lookup_type         = gc_lookup_type_tax_rate
    ;
    IF ( ln_data_cnt = 0 ) THEN
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      lv_err_code := 'APP-XXPO-00005' ;
--      lv_err_code := 'APP-XXPO-10006' ;
      lv_err_code := 'APP-XXPO-10213' ;
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- 固定項目の抽出
    -- ====================================================
    -- 確定フラグ取得
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_fix_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_kakutei
      AND   flv.lookup_type   = gc_lookup_type_fix_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_fix_class  ;
        lv_token_value2 := gc_lookup_meaning_kakutei ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
    -- 出荷支給区分
    BEGIN
      SELECT flv.lookup_code
      INTO   gv_shikyu_class
      FROM fnd_lookup_values flv
      WHERE gd_exec_date      BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.meaning       = gc_lookup_meaning_shikyu_irai
      AND   flv.lookup_type   = gc_lookup_type_shikyu_class
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lookup_type_shikyu_class  ;
        lv_token_value2 := gc_lookup_meaning_shikyu_irai ;
    END ;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
--
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--
    -- ====================================================
    -- プロファイル取得
    -- ====================================================
    ------------------------------
    -- 品目マスタ組織ＩＤ
    ------------------------------
    gn_prof_mst_org_id := FND_PROFILE.VALUE( gc_prof_mst_org_id ) ;
    IF ( gn_prof_mst_org_id IS NULL ) THEN
      lv_err_code     := 'APP-XXCMN-10002' ;
      lv_token_name1  := 'NG_PROFILE' ;
      lv_token_value1 := gc_prof_mst_org_id  ;
      RAISE get_value_expt ;
    END IF ;
--
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
--
  EXCEPTION
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                     ,iv_token_name1    => lv_token_name1
                     ,iv_token_name2    => lv_token_name2
                     ,iv_token_value1   => lv_token_value1
                     ,iv_token_value2   => lv_token_value2
                    ) ;
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
    -- *** ローカル・カーソル ***
    CURSOR cur_main_data
      (
        in_vendor_code      xxwsh_order_headers_all.vendor_code%TYPE
       ,in_dept_code        xxwsh_order_headers_all.performance_management_dept%TYPE
      )
    IS
-- mod start ver1.6
--      SELECT xv.vendor_name     AS v_vendor_name    -- 取引先：取引先名称
      SELECT xoha.vendor_code   AS vendor_code      -- 取引先：取引先コード
            ,xv.vendor_name     AS v_vendor_name    -- 取引先：取引先名称
-- mod end ver1.6
            ,xv.zip             AS v_zip            -- 取引先：郵便番号
            ,xv.address_line1   AS v_address_line1  -- 取引先：住所１
            ,xv.address_line2   AS v_address_line2  -- 取引先：住所２
            ,xla.location_name  AS l_location_name  -- 事業所：事業所名称
            ,xla.zip            AS l_zip            -- 事業所：郵便番号
            ,xla.address_line1  AS l_address_line1  -- 事業所：住所１
            ,xla.phone          AS l_phone          -- 事業所：電話番号
            ,xla.fax            AS l_fax            -- 事業所：ＦＡＸ番号
            ,mcb.segment1                   AS item_class -- 品目区分
            ,xoha.arrival_date              AS arrival_date -- 着荷日
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--            ,xoha.request_no                AS request_no   -- 依頼No（伝票番号）
            ,CASE otta.attribute11
               WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
               ELSE                              xoha.request_no
             END                AS request_no   -- 依頼No（伝票番号）
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
            ,xola.shipping_item_code        AS item_code    -- 品目コード
            ,ximb.item_short_name           AS item_name    -- 品目名称
            ,xola.unit_price                AS unit_price   -- 単価
            ,TO_NUMBER( flv.lookup_code )   AS tax_rate     -- 消費税率
-- add start ver1.6
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price))        AS amount       -- 金額
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price * TO_NUMBER( flv.lookup_code ) / 100)) AS tax -- 消費税
-- add start ver1.6
-- mod start ver1.6
--            ,CASE
            ,SUM(CASE
-- 2008/12/05 v1.5 T.Yoshimoto Mod Start 本番#446
              --WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.quantity
--              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xola.shipped_quantity
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
-- 2008/12/05 v1.5 T.Yoshimoto Mod End 本番#446
--              WHEN ( otta.order_category_code = 'RETURN' ) THEN xola.quantity * -1
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
--             END quantity                           -- 出荷実績数量
             END) quantity                           -- 出荷実績数量
-- mod end ver1.6
      FROM xxwsh_order_headers_all    xoha    -- 受注ヘッダアドオン
          ,oe_transaction_types_all   otta    -- 受注タイプ
          ,xxcmn_vendors              xv      -- 仕入先アドオン
          ,hr_locations_all           hla     -- 事業所マスタ
          ,xxcmn_locations_all        xla     -- 事業所アドオン
          ,xxwsh_order_lines_all      xola    -- 受注明細アドオン
-- add start ver1.6
          ,xxinv_mov_lot_details      xmld    -- 移動ロット詳細アドオン
-- add end ver1.6
          ,xxcmn_item_mst_b           ximb    -- 品目アドオン
          ,gmi_item_categories        gic     -- 品目カテゴリ割当
          ,mtl_categories_b           mcb     -- 品目カテゴリ
          ,mtl_category_sets_b        mcsb    -- 品目カテゴリセット
          ,mtl_category_sets_tl       mcst    -- 品目カテゴリセット（日本語）
          ,fnd_lookup_values          flv     -- クイックコード（消費税）
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
          ,ic_item_mst_b              iimb    -- ＯＰＭ品目マスタ
          ,mtl_system_items_b         msib    -- ＩＮＶ品目マスタ
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      WHERE mcsb.structure_id     = mcb.structure_id
      AND   gic.category_id       = mcb.category_id
      ---------------------------------------------------------------------------------------------
      -- 品目カテゴリセットの絞込み条件
      AND   mcst.category_set_name    = gc_cat_set_item_class
      AND   mcst.source_lang          = gc_language_code
      AND   mcst.language             = gc_language_code
      AND   mcsb.category_set_id      = mcst.category_set_id
      AND   gic.category_set_id       = mcsb.category_set_id
      AND   ximb.item_id              = gic.item_id
      ---------------------------------------------------------------------------------------------
      -- クイックコード（消費税）の絞込み条件
      AND   xoha.arrival_date         BETWEEN NVL( flv.start_date_active, xoha.arrival_date )
                                      AND     NVL( flv.end_date_active  , xoha.arrival_date )
      AND   flv.language              = gc_language_code
      AND   flv.source_lang           = gc_language_code
      AND   flv.lookup_type           = gc_lookup_type_tax_rate
      ---------------------------------------------------------------------------------------------
      -- 品目アドオンの絞込み条件
      AND   xoha.arrival_date         BETWEEN ximb.start_date_active  -- 着荷日で有効なデータ
                                      AND     ximb.end_date_active    -- 
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
--      AND   xola.shipping_inventory_item_id = ximb.item_id
      AND   iimb.item_id                    = ximb.item_id
      AND   msib.segment1                   = iimb.item_no
      AND   msib.organization_id            = gn_prof_mst_org_id
      AND   xola.shipping_inventory_item_id = msib.inventory_item_id
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
      AND   xola.delete_flag          = 'N'
      AND   xoha.order_header_id      = xola.order_header_id
-- add start ver1.6
      AND   xola.order_line_id        = xmld.mov_line_id
      AND   xmld.document_type_code   = gc_doc_type_prov
      AND   xmld.record_type_code     = gc_rec_type_stck
-- add end ver1.6
      ---------------------------------------------------------------------------------------------
      -- 事業所アドオンの絞込み条件
      AND   xoha.arrival_date         BETWEEN xla.start_date_active     -- 着荷日で有効なデータ
                                      AND     xla.end_date_active       -- 
      AND   hla.location_id           = xla.location_id
-- 2009/03/04 v1.7 UPDATE START
--      AND   xoha.performance_management_dept
      AND xxcmn_common_pkg.get_user_dept_code(FND_GLOBAL.USER_ID)
-- 2009/03/04 v1.7 UPDATE END
                                      = hla.location_code
      ---------------------------------------------------------------------------------------------
      -- 仕入先アドオンの絞込み条件
      AND   xoha.arrival_date         BETWEEN xv.start_date_active(+)   -- 着荷日で有効なデータ
                                      AND     xv.end_date_active(+)     -- 
      AND   xoha.vendor_id            = xv.vendor_id(+)
      ---------------------------------------------------------------------------------------------
      -- 受注タイプの絞込み条件
      AND   otta.org_id               = gn_sales_class              -- 営業単位    ＝Profile
      AND   otta.attribute1           = gv_shikyu_class             -- 出荷支給区分＝支給依頼
      AND   xoha.order_type_id        = otta.transaction_type_id
      ---------------------------------------------------------------------------------------------
      -- 受注ヘッダアドオンの絞込み条件
      AND   (  in_dept_code          IS NULL                        -- 事業所＝指定の事業所
            OR xoha.performance_management_dept                     -- 
                                      = in_dept_code )              -- 
      AND   (  in_vendor_code        IS NULL                        -- 取引先＝指定の取引先
            OR xoha.vendor_code       = in_vendor_code )            -- 
      AND   xoha.amount_fix_class     = gv_fix_class                -- 有償金額確定区分＝確定
      AND   xoha.latest_external_flag = 'Y'                         -- 最新フラグ      ＝最新
      AND   xoha.arrival_date         BETWEEN gd_fiscal_date_from   -- 着荷日が〆切年月に含まれる
                                      AND     gd_fiscal_date_to     -- 
-- add start ver1.6
      GROUP BY xoha.vendor_code         -- 取引先：取引先コード
              ,xv.vendor_name           -- 取引先：取引先名称
              ,xv.zip                   -- 取引先：郵便番号
              ,xv.address_line1         -- 取引先：住所１
              ,xv.address_line2         -- 取引先：住所２
              ,xla.location_name        -- 事業所：事業所名称
              ,xla.zip                  -- 事業所：郵便番号
              ,xla.address_line1        -- 事業所：住所１
              ,xla.phone                -- 事業所：電話番号
              ,xla.fax                  -- 事業所：ＦＡＸ番号
              ,mcb.segment1             -- 品目区分
              ,xoha.arrival_date        -- 着荷日
              ,CASE otta.attribute11
                WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
                ELSE           xoha.request_no
               END                          -- 依頼No（伝票番号）
              ,xola.shipping_item_code      -- 品目コード
              ,ximb.item_short_name         -- 品目名称
              ,xola.unit_price              -- 単価
              ,TO_NUMBER( flv.lookup_code ) -- 消費税率
-- add end ver1.6
      ORDER BY xoha.vendor_code         -- 取引先コード
              ,mcb.segment1             -- 品目区分
              ,xoha.arrival_date        -- 着荷日
              ,xola.shipping_item_code  -- 品目コード
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
    -- カーソルオープン
    OPEN cur_main_data
      (
        ir_param.vendor_code    -- 取引先コード
       ,ir_param.dept_code      -- 請求管理部署
      ) ;
    -- バルクフェッチ
    FETCH cur_main_data BULK COLLECT INTO ot_data_rec ;
    -- カーソルクローズ
    CLOSE cur_main_data ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF cur_main_data%ISOPEN THEN
        CLOSE cur_main_data ;
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
  PROCEDURE prc_create_xml_data
    (
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
    lc_break_init           VARCHAR2(100) := '*' ;  -- 取引先名
    lc_break_null           VARCHAR2(100) := '**' ;  -- 品目区分
--
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_vendor_name          VARCHAR2(100) := '*' ;  -- 取引先名
    lv_item_class           VARCHAR2(100) := '*' ;  -- 品目区分
--
    -- 金額計算用
    ln_amount               NUMBER := 0 ;         -- 計算用：金額
    ln_tax                  NUMBER := 0 ;         -- 計算用：消費税
    ln_balance              NUMBER := 0 ;         -- 計算用：有償額
    ln_ttl_amount           NUMBER := 0 ;         -- 今回有償金額
    ln_ttl_tax              NUMBER := 0 ;         -- 今回消費税等
    ln_ttl_balance          NUMBER := 0 ;         -- 今回有償額
--
    -- *** ローカル・例外処理 ***
    no_data_expt            EXCEPTION ;           -- 取得レコードなし
--  
  BEGIN
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
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_vender_info' ;
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
      IF ( NVL( gt_main_data(i).v_vendor_name, lc_break_null ) <> lv_vendor_name ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- 明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目区分ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 集計値出力
          ------------------------------
          -- 今回有償金額
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
          -- 今回消費税等
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
          -- 今回有償額
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
          ------------------------------
          -- 取引先Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
--
        -- 取引先が取得できない場合、ステータスを警告に設定
        IF ( gt_main_data(i).v_vendor_name IS NULL ) THEN
          ov_retcode := gv_status_warn ;
        END IF ;

        -- -----------------------------------------------------
        -- 取引先Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_vender' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 取引先Ｇデータタグ出力
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
--
        -- 取引先：郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_zip ;
        -- 取引先：住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line1 ;
        -- 取引先：住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line2 ;
        -- 取引先：取引先名称１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 ) ;
        -- 取引先：取引先名称２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 ) ;
--
        -- 期間From
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_from' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_from_char ;
        -- 期間To
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'period_to' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_to_char ;
        -- 事業所：郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_zip_code' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        -- 事業所：住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).l_address_line1,  1, 15 ) ;
        -- 事業所：住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).l_address_line1, 16, 15 ) ;
        -- 事業所：電話番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_phone_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        -- 事業所：ＦＡＸ番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        -- 事業所：事業所名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.6
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name ;
        gt_xml_data_table(gl_xml_idx).tag_value 
                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
-- mod end ver1.6
--
        ------------------------------
        -- 明細ＬＧ開始タグ
        ------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_class_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_vendor_name  := NVL( gt_main_data(i).v_vendor_name, lc_break_null )  ;
        lv_item_class   := lc_break_init ;
        -- 集計変数０クリア
        ln_ttl_amount   := 0 ;  -- 今回有償金額
        ln_ttl_tax      := 0 ;  -- 今回消費税等
        ln_ttl_balance  := 0 ;  -- 今回有償額
--
      END IF ;
--
      -- =====================================================
      -- 品目区分ブレイク
      -- =====================================================
      -- 品目区分が切り替わった場合
      IF ( gt_main_data(i).item_class <> lv_item_class ) THEN
        -- -----------------------------------------------------
        -- 終了タグ出力
        -- -----------------------------------------------------
        -- 初回レコードの場合は終了タグを出力しない。
        IF ( lv_item_class <> lc_break_init ) THEN
          ------------------------------
          -- 明細ＬＧ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
          ------------------------------
          -- 品目Ｇ終了タグ
          ------------------------------
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
          gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        END IF ;
        -- -----------------------------------------------------
        -- 品目区分Ｇ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item_class' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- 取引先Ｇデータタグ出力
        -- -----------------------------------------------------
        -- 品目区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class ;
        -- -----------------------------------------------------
        -- 明細ＬＧ開始タグ
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_item_info' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
        -- -----------------------------------------------------
        -- キーブレイク時の初期処理
        -- -----------------------------------------------------
        -- キーブレイク用変数退避
        lv_item_class   := gt_main_data(i).item_class ;
--
      END IF ;
--
      -- =====================================================
      -- 明細データ出力
      -- =====================================================
      -- -----------------------------------------------------
      -- 計算項目の算出
      -- -----------------------------------------------------
      -- 個別計算項目
-- mod start ver1.6
--      ln_amount   := ROUND( gt_main_data(i).quantity * gt_main_data(i).unit_price ) ;
--      ln_tax      := ROUND( ln_amount * gt_main_data(i).tax_rate / 100 ) ;
      ln_amount   := gt_main_data(i).amount;
      ln_tax      := gt_main_data(i).tax;
-- mod end ver1.6
-- 2008/06/20 v1.3 Y.Yamamoto Update Start
--      ln_balance  := ln_amount - ln_tax ;
      ln_balance  := ln_amount + ln_tax ;
-- 2008/06/20 v1.3 Y.Yamamoto Update End
--
      -- 集計項目
      ln_ttl_amount  := ln_ttl_amount  + ln_amount ;  -- 今回有償金額
      ln_ttl_tax     := ln_ttl_tax     + ln_tax ;     -- 今回消費税等
      ln_ttl_balance := ln_ttl_balance + ln_balance ; -- 今回有償額
--
      -- -----------------------------------------------------
      -- 明細Ｇ開始タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
      -- -----------------------------------------------------
      -- 明細Ｇデータタグ出力
      -- -----------------------------------------------------
      -- 着荷日
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'date' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).arrival_date, gc_char_d_format ) ;
      -- 伝票番号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'slip_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
      -- 品目コード
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_code' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_code ;
      -- 品目名称
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_name' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_name ;
      -- 出荷実績数量
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'quant' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).quantity ;
      -- 単価
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'price' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).unit_price ;
      -- 金額
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'amount' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := ln_amount ;
      -- -----------------------------------------------------
      -- 明細Ｇ終了タグ出力
      -- -----------------------------------------------------
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- 終了処理
    -- =====================================================
    ------------------------------
    -- 明細ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目区分Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_item_class' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 品目区分ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_item_class_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 集計値出力
    ------------------------------
    -- 今回有償金額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
    -- 今回消費税等
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
    -- 今回有償額
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
    ------------------------------
    -- 取引先Ｇ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_vender' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- 取引先ＬＧ終了タグ
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_vender_info' ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_fiscal_ym          IN     VARCHAR2         --   01 : 〆切年月
     ,iv_dept_code          IN     VARCHAR2         --   02 : 請求管理部署
     ,iv_vendor_code        IN     VARCHAR2         --   03 : 取引先
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
    gv_report_id              := 'XXPO780001T' ;      -- 帳票ID
    gd_exec_date              := SYSDATE ;            -- 実施日
    -- パラメータ格納
    lr_param_rec.fiscal_ym    := iv_fiscal_ym ;       -- 〆切年月
    lr_param_rec.dept_code    := iv_dept_code ;       -- 請求管理部署
    lr_param_rec.vendor_code  := iv_vendor_code ;     -- 取引先
--
    -- =====================================================
    -- パラメータチェック
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
    -- 前処理
    -- =====================================================
    prc_initialize
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
    -- 帳票データ出力
    -- =====================================================
    prc_create_xml_data
      (
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_vender>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_item_class>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_item_class_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_vender>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_vender_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : 〆切年月
     ,iv_dept_code          IN     VARCHAR2         --   02 : 請求管理部署
     ,iv_vendor_code        IN     VARCHAR2         --   03 : 取引先
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
        iv_fiscal_ym      => iv_fiscal_ym       --   01 : 〆切年月
       ,iv_dept_code      => iv_dept_code       --   02 : 請求管理部署
       ,iv_vendor_code    => iv_vendor_code     --   03 : 取引先
       ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode         -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
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
END xxpo780001c ;
/