CREATE OR REPLACE PACKAGE BODY xxpo780001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo780001c(body)
 * Description      : 月次〆切処理（有償支給相殺）
 * MD.050/070       : 月次〆切処理（有償支給相殺）Issue1.0  (T_MD050_BPO_780)
 *                    請求書兼有償支給相殺確認書（伊藤園）  (T_MD070_BPO_78A)
 * Version          : 1.9
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
 *  prc_ins_data              PROCEDURE : TEMPテーブルデータ登録(A-6)
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
 *  2019/09/11    1.8  N.Abe             E_本稼動_15601（生産_軽減税率対応）
 *                                       コンカレント名を変更：計算書 ⇒ 請求書兼有償支給相殺確認書（伊藤園）
 *  2019/10/18    1.9  N.Abe             E_本稼動_15601対応（追加対応）
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
-- 2019/09/11 Ver1.8 Add Start
  gn_request_id           CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/10/18 Ver1.9 Add Start
  gc_lkup_acct_pay              CONSTANT VARCHAR2(20)  := 'XXPO_ACCOUNT_PAYABLE'; -- 振込先
  gc_lkup_mean_acct_pay         CONSTANT VARCHAR2(20)  := '振込先情報';
-- 2019/10/18 Ver1.9 Add End
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
-- 2019/09/11 Ver1.8 Add Start
     ,item_class          xxwsh_order_headers_all.item_class%TYPE                   -- 品目区分
     ,out_file_type       VARCHAR2(1)                                               -- 出力ファイル形式(未入力:0,PDF:1,CSV:2)
     ,out_rep_type        VARCHAR2(1)                                               -- 出力帳票形式(未入力:0,鑑:1,明細:2)
     ,browser             VARCHAR2(1)                                               -- 閲覧者(伊藤園:1,取引先:2)
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
     ,item_class_name       mtl_categories_tl.description%TYPE      -- 品目区分（日本語）
-- 2019/09/11 Ver1.8 Add End
     ,arrival_date          xxwsh_order_headers_all.arrival_date%TYPE         -- 着荷日
-- S 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- S --
--     ,request_no            xxwsh_order_headers_all.request_no%TYPE
     ,request_no            VARCHAR2(13)                                      -- 依頼No（伝票番号）
-- E 2008/03/10 mod by m.ikeda Ver1.2 --------------------------------------------------------- E --
     ,item_code             xxwsh_order_lines_all.shipping_item_code%TYPE     -- 品目コード
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE             -- 品目名称
     ,unit_price            xxwsh_order_lines_all.unit_price%TYPE             -- 単価
-- 2019/09/11 Ver1.8 Mod Start
--     ,tax_rate              fnd_lookup_values.lookup_code%TYPE                -- 消費税率
     ,tax_rate              xxcmm_item_tax_rate_v.tax%TYPE                    -- 消費税率
-- 2019/09/11 Ver1.8 Mod End
-- add start ver1.6
     ,amount                NUMBER                                            -- 金額
     ,tax                   NUMBER                                            -- 消費税
-- add end ver1.6
     ,quantity              xxwsh_order_lines_all.quantity%TYPE               -- 出荷実績数量
-- 2019/09/11 Ver1.8 Add Start
     ,lot_no                xxinv_mov_lot_details.lot_no%TYPE                 -- ロットNo
-- 2019/10/18 Ver1.9 Del Start
--     ,bank_name             ap_bank_branches.bank_name%TYPE                   -- 金融機関名
--     ,bank_bra_name         ap_bank_branches.bank_branch_name%TYPE            -- 支店名
--     ,bank_acct_type        xxcmn_lookup_values2_v.meaning%TYPE               -- 預金区分名
--     ,bank_acct_num         ap_bank_accounts_all.bank_account_num%TYPE        -- 口座No
--     ,bank_acct_name_alt    ap_bank_accounts_all.account_holder_name_alt%TYPE -- 口座名義ｶﾅ
-- 2019/10/18 Ver1.9 Del End
     ,s_vendor_code         po_vendors.segment1%TYPE                          -- 取引先：仕入先コード
     ,tax_type_code         fnd_lookup_values_vl.lookup_code%TYPE             -- 税区分（コード）
     ,tax_type_name         fnd_lookup_values_vl.description%TYPE             -- 税区分（名称）
     ,sikyu_date            VARCHAR2(7)                                       -- 有償支給年月
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
     ,billing_office        xxcmn_locations_all.location_name%TYPE            -- 請求先事業所
-- 2019/10/18 Ver1.9 Add End
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
-- 2019/09/11 Ver1.8 Add Start
  gv_tax_type_10            fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_8             fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_old_8         fnd_lookup_values.lookup_code%TYPE;
  gv_tax_type_no_tax        fnd_lookup_values.lookup_code%TYPE;
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
  gv_l_zip                  fnd_lookup_values.attribute1%TYPE;
  gv_l_address              fnd_lookup_values.attribute2%TYPE;
  gv_l_phone                fnd_lookup_values.attribute3%TYPE;
  gv_l_fax                  fnd_lookup_values.attribute4%TYPE;
  gv_l_dept                 fnd_lookup_values.attribute5%TYPE;
  gv_bank_name              fnd_lookup_values.attribute6%TYPE;
  gv_bank_bra_name          fnd_lookup_values.attribute7%TYPE;
  gv_bank_acct_type         fnd_lookup_values.attribute8%TYPE;
  gv_bank_acct_num          fnd_lookup_values.attribute9%TYPE;
  gv_bank_acct_name_alt     fnd_lookup_values.attribute10%TYPE;
-- 2019/10/18 Ver1.9 Add End
--
  ------------------------------
  -- プロファイル用
  ------------------------------
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
  gc_prof_mst_org_id        CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID' ; -- 品目マスタ組織
  gn_prof_mst_org_id        NUMBER ;              -- 品目マスタ組織ID
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
-- 2019/09/11 Ver1.8 Add Start
  gc_prof_title_ito         CONSTANT VARCHAR2(30) := 'XXPO_REP_TITLE_ITO';
  gc_prof_title_ven         CONSTANT VARCHAR2(30) := 'XXPO_REP_TITLE_VEN';
  gv_title_ito              fnd_profile_option_values.profile_option_value%TYPE;
  gv_title_ven              fnd_profile_option_values.profile_option_value%TYPE;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
    -- *** ローカルカーソル ***
    CURSOR tax_type_cur
    IS
      SELECT flvv.lookup_code     tax_type_code
            ,flvv.description     tax_type_name
            ,flvv.attribute1      sort
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type   = 'XXPO_TAX_TYPE_CALC'
      AND    gd_fiscal_date_from BETWEEN NVL( flvv.start_date_active, gd_fiscal_date_from )
                                 AND     NVL( flvv.end_date_active  , gd_fiscal_date_from )
      AND    flvv.enabled_flag  = 'Y'
      ORDER BY flvv.attribute1
    ;
--
    -- *** ローカルレコード ***
    tax_type_rec  tax_type_cur%ROWTYPE;
--
-- 2019/09/11 Ver1.8 Add End
    -- *** ローカル・例外処理 ***
    get_value_expt        EXCEPTION ;     -- 値取得エラー
-- 2019/09/11 Ver1.8 Add Start
    tax_type_expt         EXCEPTION;      -- 税区分取得エラー
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Del Start
--    -- ====================================================
--    -- 消費税取得
--    -- ====================================================
--    SELECT COUNT( lookup_code )
--    INTO   ln_data_cnt
--    FROM fnd_lookup_values
--    WHERE gd_fiscal_date_from BETWEEN NVL( START_DATE_ACTIVE, gd_fiscal_date_from )
--                              AND     NVL( END_DATE_ACTIVE  , gd_fiscal_date_from )
--    AND   enabled_flag        = gc_enable_flag
--    AND   language            = gc_language_code
--    AND   source_lang         = gc_language_code
--    AND   lookup_type         = gc_lookup_type_tax_rate
--    ;
--    IF ( ln_data_cnt = 0 ) THEN
---- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
----      lv_err_code := 'APP-XXPO-00005' ;
----      lv_err_code := 'APP-XXPO-10006' ;
--      lv_err_code := 'APP-XXPO-10213' ;
---- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
--      RAISE get_value_expt ;
--    END IF ;
-- 2019/09/11 Ver1.8 Del End
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
-- 2019/10/18 Ver1.9 Add Start
    BEGIN
      SELECT attribute1  AS l_zip                 -- 郵便番号
            ,attribute2  AS l_address             -- 住所
            ,attribute3  AS l_phone               -- TEL
            ,attribute4  AS l_fax                 -- FAX
            ,attribute5  AS l_dept                -- 拠点（部署）
            ,attribute6  AS bank_name             -- 金融機関名
            ,attribute7  AS bank_bra_name         -- 支店名
            ,attribute8  AS bank_acct_type        -- 預金区分
            ,attribute9  AS bank_acct_num         -- 口座No
            ,attribute10 AS bank_acct_name_alt    -- 口座名義
      INTO   gv_l_zip
            ,gv_l_address
            ,gv_l_phone
            ,gv_l_fax
            ,gv_l_dept
            ,gv_bank_name
            ,gv_bank_bra_name
            ,gv_bank_acct_type
            ,gv_bank_acct_num
            ,gv_bank_acct_name_alt
      FROM   fnd_lookup_values flv
      WHERE  gd_exec_date     BETWEEN NVL( flv.start_date_active, gd_exec_date )
                              AND     NVL( flv.end_date_active  , gd_exec_date )
      AND   flv.enabled_flag  = gc_enable_flag
      AND   flv.lookup_type   = gc_lkup_acct_pay
      AND   flv.language      = gc_language_code
      AND   flv.source_lang   = gc_language_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_err_code     := 'APP-XXCMN-10121' ;
        lv_token_name1  := 'LOOKUP_TYPE' ;
        lv_token_name2  := 'MEANING' ;
        lv_token_value1 := gc_lkup_acct_pay  ;
        lv_token_value2 := gc_lkup_mean_acct_pay ;
    END;
    IF ( lv_err_code IS NOT NULL ) THEN
      RAISE get_value_expt ;
    END IF ;
-- 2019/10/18 Ver1.9 Add End
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
-- 2019/09/11 Ver1.8 Add Start
    ------------------------------
    -- 表題（伊藤園）
    ------------------------------
    gv_title_ito := FND_PROFILE.VALUE( gc_prof_title_ito );
    IF ( gv_title_ito IS NULL ) THEN
      lv_err_code     := 'APP-XXPO-40053';
      lv_token_name1  := 'NG_PROFILE';
      lv_token_value1 := gc_prof_title_ito;
      RAISE get_value_expt;
    END IF;
--
    ------------------------------
    -- 表題（取引先）
    ------------------------------
    gv_title_ven := FND_PROFILE.VALUE( gc_prof_title_ven );
    IF ( gv_title_ven IS NULL ) THEN
      lv_err_code     := 'APP-XXPO-40053';
      lv_token_name1  := 'NG_PROFILE';
      lv_token_value1 := gc_prof_title_ven;
      RAISE get_value_expt;
    END IF;
--
    ------------------------------
    -- 税区分取得
    ------------------------------
    FOR tax_type_rec IN tax_type_cur LOOP
      IF (tax_type_rec.sort = '1') THEN                     -- 標準税率(10%)
        gv_tax_type_10 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '2') THEN                  -- 軽減税率(8%)
        gv_tax_type_8 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '3') THEN                  -- 旧標準税率(8%)
        gv_tax_type_old_8 := tax_type_rec.tax_type_code;
      ELSIF (tax_type_rec.sort = '4') THEN                  -- 課税対象外
        gv_tax_type_no_tax := tax_type_rec.tax_type_code;
      END IF;
    END LOOP;
--
    -- 税区分が取得できない場合
    IF    gv_tax_type_10     IS NULL
      OR  gv_tax_type_8      IS NULL
      OR  gv_tax_type_old_8  IS NULL
      OR  gv_tax_type_no_tax IS NULL
    THEN
      lv_err_code     := 'APP-XXPO-40050';
      RAISE tax_type_expt;
    END IF;
-- 2019/09/11 Ver1.8 Add End
--
  EXCEPTION
-- 2019/09/11 Ver1.8 Add Start
    --*** 税区分取得エラー例外 ***
    WHEN tax_type_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
                    ( iv_application    => gc_application_po
                     ,iv_name           => lv_err_code
                    ) ;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
-- 2019/09/11 Ver1.8 Add End
    --*** 値取得エラー例外 ***
    WHEN get_value_expt THEN
      -- メッセージセット
      lv_errmsg := xxcmn_common_pkg.get_msg
-- 2019/10/18 Ver1.9 Mod Start
--                    ( iv_application    => gc_application_po
                    ( iv_application    => gc_application_cmn
-- 2019/10/18 Ver1.9 Mod End
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
-- 2019/09/11 Ver1.8 Add Start
       ,in_item_class       mtl_categories_b.segment1%TYPE
-- 2019/09/11 Ver1.8 Add End
      )
    IS
-- mod start ver1.6
--      SELECT xv.vendor_name     AS v_vendor_name    -- 取引先：取引先名称
-- 2019/09/11 Ver1.8 Mod Start
--      SELECT xoha.vendor_code   AS vendor_code      -- 取引先：取引先コード
      SELECT /*+ push_pred(xitrv) */
             xoha.vendor_code   AS vendor_code      -- 取引先：取引先コード
-- 2019/09/11 Ver1.8 Mod End
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
-- 2019/09/11 Ver1.8 Add Start
            ,mct.description                AS item_class_name  -- 品目区分（日本語）
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Mod Start
--            ,TO_NUMBER( flv.lookup_code )   AS tax_rate     -- 消費税率
            ,TO_NUMBER( xitrv.tax )         AS tax_rate     -- 消費税率
-- 2019/09/11 Ver1.8 Mod End
-- add start ver1.6
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
             END * xola.unit_price))        AS amount       -- 金額
            ,SUM(ROUND(CASE
              WHEN ( otta.order_category_code = 'ORDER'  ) THEN xmld.actual_quantity
              WHEN ( otta.order_category_code = 'RETURN' ) THEN xmld.actual_quantity * -1
-- 2019/09/11 Ver1.8 Mod Start
--             END * xola.unit_price * TO_NUMBER( flv.lookup_code ) / 100)) AS tax -- 消費税
             END * xola.unit_price * TO_NUMBER( xitrv.tax ) / 100)) AS tax -- 消費税
-- 2019/09/11 Ver1.8 Mod End
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
-- 2019/09/11 Ver1.8 Add Start
            ,xmld.lot_no                    AS lot_no                   -- ロットNo
-- 2019/10/18 Ver1.9 Del Start
--            ,abb.bank_name                  AS bank_name                -- 金融機関名
--            ,abb.bank_branch_name           AS bank_branch_name         -- 支店名
--            ,flv.meaning                    AS bank_account_type        -- 預金区分名
--            ,aba.bank_account_num           AS bank_account_num         -- 口座No
--            ,aba.account_holder_name_alt    AS bank_account_name_alt    -- 口座名義ｶﾅ
-- 2019/10/18 Ver1.9 Del End
            ,pv.segment1                    AS s_vendor_code            -- 取引先：仕入先コード
            ,flvv.lookup_code               AS tax_type_code            -- 税区分（コード）
            ,flvv.description               AS tax_type_name            -- 税区分（名称）
            ,TO_CHAR(xoha.sikyu_return_date, 'YYYY/MM')
                                            AS sikyu_date               -- 有償支給年月
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
            ,xla2.location_name             AS billing_office           -- 請求先事業所
-- 2019/10/18 Ver1.9 Add End
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
-- 2019/09/11 Ver1.8 Del Start
--          ,fnd_lookup_values          flv     -- クイックコード（消費税）
-- 2019/09/11 Ver1.8 Del End
-- S 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- S --
          ,ic_item_mst_b              iimb    -- ＯＰＭ品目マスタ
          ,mtl_system_items_b         msib    -- ＩＮＶ品目マスタ
-- E 2008/02/06 mod by m.ikeda ---------------------------------------------------------------- E --
-- 2019/09/11 Ver1.8 Add Start
          ,xxcmm_item_tax_rate_v      xitrv       -- 消費税率VIEW
-- 2019/10/18 Ver1.9 Del Start
--          ,ap_bank_account_uses_all   abaua       -- 口座使用情報テーブル
--          ,ap_bank_accounts_all       aba         -- 銀行口座
--          ,ap_bank_branches           abb         -- 銀行支店
-- 2019/10/18 Ver1.9 Del End
          ,po_vendors                 pv          -- 仕入先
          ,po_vendor_sites_all        pvsa_sales  -- 仕入先サイト(営業)
          ,po_vendor_sites_all        pvsa_mfg    -- 仕入先サイト(生産)
-- 2019/10/18 Ver1.9 Del Start
--          ,xxcmn_lookup_values2_v     flv         -- クイックコード（口座種別）
-- 2019/10/18 Ver1.9 Del End
          ,mtl_categories_tl          mct         -- 品目カテゴリ（日本語）
          ,fnd_lookup_values_vl       flvv        -- クイックコード（税区分）
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
          ,hr_locations_all           hla2    -- 事業所マスタ（請求管理部署）
          ,xxcmn_locations_all        xla2    -- 事業所アドオン（請求管理部署）
-- 2019/10/18 Ber1.9 Add End
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
-- 2019/09/11 Ver1.8 Add Start
      AND   mcb.category_id           = mct.category_id
      AND   mct.source_lang           = gc_language_code
      AND   mct.language              = gc_language_code
      AND   (  in_item_class          IS NULL                        -- 品目区分 = NULL
            OR mcb.segment1           = in_item_class )              -- 品目区分
-- 2019/09/11 Ver1.8 Add End
      ---------------------------------------------------------------------------------------------
-- 2019/09/11 Ver1.8 Mod Start
--      -- クイックコード（消費税）の絞込み条件
--      AND   xoha.arrival_date         BETWEEN NVL( flv.start_date_active, xoha.arrival_date )
--                                      AND     NVL( flv.end_date_active  , xoha.arrival_date )
--      AND   flv.language              = gc_language_code
--      AND   flv.source_lang           = gc_language_code
--      AND   flv.lookup_type           = gc_lookup_type_tax_rate
      -- 消費税率VIEWの絞込み条件
      AND   NVL( xoha.sikyu_return_date, xoha.arrival_date )  BETWEEN NVL( xitrv.start_date_active, NVL( xoha.sikyu_return_date, xoha.arrival_date ) )
                                                              AND     NVL( xitrv.end_date_active  , NVL( xoha.sikyu_return_date, xoha.arrival_date ) )
      AND   msib.segment1             = xitrv.item_no
-- 2019/09/11 Ver1.8 Mod End
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
-- 2019/09/11 Ver1.8 Add Start
      ---------------------------------------------------------------------------------------------
      -- 振込先情報の絞込み条件
-- 2019/10/18 Ver1.9 Del Start
--      AND   abaua.external_bank_account_id = aba.bank_account_id
--      AND   aba.bank_branch_id             = abb.bank_branch_id
--      AND   xoha.arrival_date              BETWEEN abaua.start_date
--                                           AND     NVL(abaua.end_date ,xoha.arrival_date)
--      AND   abaua.vendor_id                = pv.vendor_id
--      AND   abaua.vendor_id                = pvsa_sales.vendor_id
--      AND   abaua.vendor_site_id           = pvsa_sales.vendor_site_id
-- 2019/10/18 Ver1.9 Del End
-- 2019/10/18 Ver1.9 Add Start
      AND   pv.vendor_id                   = pvsa_sales.vendor_id
-- 2019/10/18 Ver1.9 Add End
      AND   pvsa_sales.org_id              = FND_PROFILE.VALUE( 'XXCMN_SALES_ORG_ID' )
      AND   pvsa_sales.vendor_site_code    = pvsa_mfg.attribute5
      AND   pvsa_mfg.org_id                = gn_sales_class
      AND   pvsa_mfg.vendor_site_code      = xoha.vendor_site_code
-- 2019/10/18 Ver1.9 Del Start
--      AND   aba.bank_account_type          = flv.lookup_code
--      AND   flv.lookup_type                = 'XXCSO1_KOZA_TYPE'
--      AND   xoha.arrival_date              BETWEEN flv.start_date_active
--                                           AND     NVL(flv.end_date_active ,xoha.arrival_date)
-- 2019/10/18 Ver1.9 Del End
      ---------------------------------------------------------------------------------------------
      -- 税区分の絞込み条件
      AND   flvv.lookup_type               = 'XXPO_TAX_TYPE_CALC'    -- 税区分（名称用）
      AND   flvv.lookup_code               = xitrv.tax_code_ex       -- 仕入・外税
      AND   flvv.enabled_flag              = 'Y'
      AND   xoha.arrival_date              BETWEEN flvv.start_date_active   -- 着荷日で有効なデータ
                                           AND     NVL(flvv.end_date_active, xoha.arrival_date)   -- 
-- 2019/09/11 Ver1.8 Add End
-- 2019/10/18 Ver1.9 Add Start
      ---------------------------------------------------------------------------------------------
      -- 請求先事業所の条件
      AND   hla2.location_code        = xoha.performance_management_dept  -- 成績管理部署
      AND   hla2.location_id          = xla2.location_id
      AND   xoha.arrival_date         BETWEEN xla2.start_date_active      -- 着荷日で有効なデータ
                                      AND     xla2.end_date_active
-- 2019/10/18 Ver1.9 Add End
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
-- 2019/09/11 Ver1.8 Add Start
              ,mct.description          -- 品目区分（名称）
-- 2019/09/11 Ver1.8 Add End
              ,xoha.arrival_date        -- 着荷日
              ,CASE otta.attribute11
                WHEN gc_ship_rcv_pay_ctg_yhe THEN xoha.request_no || '*'
                ELSE           xoha.request_no
               END                          -- 依頼No（伝票番号）
              ,xola.shipping_item_code      -- 品目コード
              ,ximb.item_short_name         -- 品目名称
              ,xola.unit_price              -- 単価
-- 2019/09/11 Ver1.8 Mod Start
--              ,TO_NUMBER( flv.lookup_code ) -- 消費税率
              ,TO_NUMBER( xitrv.tax )       -- 消費税率
-- 2019/09/11 Ver1.8 Mod End
-- 2019/09/11 Ver1.8 Add Start
              ,xmld.lot_no                  -- ロットNo
-- 2019/10/18 Ver1.9 Del Start
--              ,abb.bank_name                -- 金融機関名
--              ,abb.bank_branch_name         -- 支店名
--              ,flv.meaning                  -- 預金区分名
--              ,aba.bank_account_num         -- 口座No
--              ,aba.account_holder_name_alt  -- 口座名義ｶﾅ
-- 2019/10/18 Ver1.9 Del End
              ,pv.segment1                  -- 取引先：仕入先コード
              ,flvv.lookup_code             -- 税区分
              ,flvv.description             -- 税区分（名称）
              ,TO_CHAR(xoha.sikyu_return_date, 'YYYY/MM')
                                            -- 有償支給年月
-- 2019/10/18 Ver1.9 Add Start
              ,xla2.location_name           -- 請求先事業所
-- 2019/10/18 Ver1.9 Add End
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
       ,ir_param.item_class     -- 品目区分
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
  /**********************************************************************************
   * Procedure Name   : prc_ins_data
   * Description      : TEMPテーブルデータ登録(A-6)
   ***********************************************************************************/
  PROCEDURE prc_ins_data
    (
      ir_param      IN  rec_param_data            -- 01.入力パラメータ群
     ,it_data_rec   IN  tab_data_type_dtl         -- 02.取得レコード群
     ,ov_errbuf     OUT VARCHAR2                  --    エラー・メッセージ           --# 固定 #
     ,ov_retcode    OUT VARCHAR2                  --    リターン・コード             --# 固定 #
     ,ov_errmsg     OUT VARCHAR2                  --    ユーザー・エラー・メッセージ --# 固定 #
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_ins_data'; -- プログラム名
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
    -- データ登録
    -- ====================================================
      FOR i IN 1..it_data_rec.count LOOP
        INSERT INTO xxpo_invoice_work(
          request_id                      -- 01.要求ID
         ,vendor_code                     -- 02.取引先コード
         ,vendor_name                     -- 03.取引先名
         ,zip                             -- 04.郵便番号
         ,address                         -- 05.住所
         ,arrival_date                    -- 06.日付
         ,slip_num                        -- 07.伝票No
         ,lot_no                          -- 08.ロットNo
         ,dept_name                       -- 09.請求管理部署
         ,item_class                      -- 10.品目区分
         ,item_class_name                 -- 11.品目区分名称
         ,item_code                       -- 12.品目コード
         ,item_name                       -- 13.品目名称
         ,quantity                        -- 14.数量
         ,unit_price                      -- 15.単価
         ,amount                          -- 16.税抜金額
         ,tax                             -- 17.消費税額
         ,tax_type                        -- 18.税区分
         ,tax_include                     -- 19.税込金額
         ,yusyo_year_month                -- 20.有償年月
        ) VALUES (
          gn_request_id                   -- 01.要求ID
         ,it_data_rec(i).vendor_code      -- 02.取引先：取引先コード
         ,it_data_rec(i).v_vendor_name    -- 03.取引先：取引先名称
         ,it_data_rec(i).v_zip            -- 04.取引先：郵便番号
         ,it_data_rec(i).v_address_line1 || it_data_rec(i).v_address_line2
                                          -- 05.取引先：住所１ || 取引先：住所２
         ,it_data_rec(i).arrival_date     -- 06.着荷日
         ,it_data_rec(i).request_no       -- 07.依頼No（伝票番号）
         ,it_data_rec(i).lot_no           -- 08.ロットNo
-- 2019/10/18 Ver1.9 Del Start
--         ,it_data_rec(i).l_location_name  -- 09.事業所：事業所名称
         ,it_data_rec(i).billing_office   -- 09.請求先事業所
-- 2019/10/18 Ver1.9 Del End
         ,it_data_rec(i).item_class       -- 10.品目区分（日本語）
         ,it_data_rec(i).item_class_name  -- 11.品目区分（日本語）
         ,it_data_rec(i).item_code        -- 12.品目コード
         ,it_data_rec(i).item_name        -- 13.品目名称
         ,it_data_rec(i).quantity         -- 14.数量
         ,it_data_rec(i).unit_price       -- 15.単価
         ,it_data_rec(i).amount           -- 16.金額（税抜）
         ,it_data_rec(i).tax              -- 17.消費税額
         ,it_data_rec(i).tax_type_name    -- 18.税区分（名称）
         ,it_data_rec(i).amount + it_data_rec(i).tax
                                          -- 19.税抜金額 + 消費税額
         ,it_data_rec(i).sikyu_date       -- 20.有償支給年月
        );
      END LOOP;
--
    -- エラーがなければCOMMIT（呼出先でデータ抽出するため）
    COMMIT;
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
  END prc_ins_data ;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
    --要求の発行
    cv_application          CONSTANT VARCHAR2(5)   := 'XXPO';           -- Application
    cv_program              CONSTANT VARCHAR2(13)  := 'XXPO780002C';    -- 請求書兼有償支給相殺確認書CSV出力
    cv_description          CONSTANT VARCHAR2(9)   := NULL;             -- Description
    cv_start_time           CONSTANT VARCHAR2(10)  := NULL;             -- Start_time
    cb_sub_request          CONSTANT BOOLEAN       := FALSE;            -- Sub_request
    -- トークン
    cv_tkn_request_id       CONSTANT VARCHAR2(10)  := 'REQUEST_ID';
-- 2019/09/11 Ver1.8 Add End
    -- *** ローカル変数 ***
    -- キーブレイク判断用
    lv_vendor_name          VARCHAR2(100) := '*' ;  -- 取引先名
    lv_item_class           VARCHAR2(100) := '*' ;  -- 品目区分
--
    -- 金額計算用
    ln_amount               NUMBER := 0 ;         -- 計算用：金額
    ln_tax                  NUMBER := 0 ;         -- 計算用：消費税
-- 2019/09/11 Ver1.8 Del Start
--    ln_balance              NUMBER := 0 ;         -- 計算用：有償額
--    ln_ttl_amount           NUMBER := 0 ;         -- 今回有償金額
--    ln_ttl_tax              NUMBER := 0 ;         -- 今回消費税等
--    ln_ttl_balance          NUMBER := 0 ;         -- 今回有償額
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
    ln_amount_10            NUMBER := 0;          -- 税抜金額（標準税率(10%)）
    ln_tax_10               NUMBER := 0;          -- 消費税額（標準税率(10%)）
    ln_amount_8             NUMBER := 0;          -- 税抜金額（軽減税率(8%)）
    ln_tax_8                NUMBER := 0;          -- 消費税額（軽減税率(8%)）
    ln_amount_old_8         NUMBER := 0;          -- 税抜金額（旧標準税率(8%)）
    ln_tax_old_8            NUMBER := 0;          -- 消費税額（旧標準税率(8%)）
    ln_amount_no_tax        NUMBER := 0;          -- 課税対象外
    ln_no_tax               NUMBER := 0;          -- 課税対象外
    ln_request_id           NUMBER;               -- 要求ID（呼出先）
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
    -- パラメータ.出力ファイル形式が 未入力(0) 又は CSV(2)の場合にA-6、A-7を起動
    IF (  ir_param.out_file_type = '0'
      OR  ir_param.out_file_type = '2')
    THEN
      -- =====================================================
      -- A-6. TEMPテーブルデータ登録
      -- =====================================================
      prc_ins_data(
        ir_param      => ir_param       -- 01.入力パラメータ群
       ,it_data_rec   => gt_main_data   -- 02.取得レコード群
       ,ov_errbuf     => lv_errbuf      --    エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode     --    リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg      --    ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt ;
      END IF;
--
      -- =====================================================
      -- A-7. CSV出力処理起動
      -- =====================================================
--
      -- 請求書兼有償支給相殺確認書CSV出力(XXPO780002C)の起動
      ln_request_id := fnd_request.submit_request(
                          application  => cv_application        -- アプリケーション
                         ,program      => cv_program            -- プログラム
                         ,description  => cv_description        -- 適用
                         ,start_time   => cv_start_time         -- 開始時間
                         ,sub_request  => cb_sub_request        -- サブ要求
                         ,argument1    => gn_request_id         -- 要求ID
                       );
      -- 要求の発行に失敗した場合
      IF ( ln_request_id = 0 ) THEN
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gc_application_po
                       ,iv_name         => 'APP-XXPO-40051'
                       ,iv_token_name1  => cv_tkn_request_id         -- 要求ID
                       ,iv_token_value1 => TO_CHAR( ln_request_id )  -- 要求ID
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --コンカレント起動のためコミット
      COMMIT;
--
    END IF;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Del Start
--          -- 今回有償金額
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
--          -- 今回消費税等
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
--          -- 今回有償額
--          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--          gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
--          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--          gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
          -- 税抜金額(標準税率(10%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_10';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_10;
          -- 消費税額(標準税率(10%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_10';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_10;
          -- 税抜金額(軽減税率(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_8;
          -- 消費税額(軽減税率(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_8;
          -- 税抜金額(旧標準税率(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_old_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_old_8;
          -- 消費税額(旧標準税率(8%))
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_old_8';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_old_8;
          -- 税抜金額(課税対象外)
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_no_tax';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_no_tax;
          -- 消費税額(課税対象外)
          gl_xml_idx := gt_xml_data_table.COUNT + 1;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'no_tax';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
          gt_xml_data_table(gl_xml_idx).tag_value := ln_no_tax;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
        -- ------------------------------------------------------
        -- 鑑用タグ出力
        ---------------------------------------------------------
        -- パラメータ：出力帳票形式
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'p_rep_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := ir_param.out_rep_type;
        -- 鑑タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := CASE ir_param.browser
                                                     WHEN '1' THEN gv_title_ito
                                                     ELSE          gv_title_ven
                                                   END;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 ) ;
                                      := SUBSTRB( gt_main_data(i).v_vendor_name,  1, 40 ) ;
-- 2019/09/11 Ver1.8 Mod End
        -- 取引先：取引先名称２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_name2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 ) ;
                                      := SUBSTRB( gt_main_data(i).v_vendor_name, 41, 20 ) ;
-- 2019/09/11 Ver1.8 Mod End
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
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_zip ;
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_zip;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- 事業所：住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address1' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).l_address_line1,  1, 15 ) ;
                                      := SUBSTRB( gt_main_data(i).l_address_line1,  1, 30 ) ;
-- 2019/09/11 Ver1.8 Mod End
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_l_address,  1, 30 ) ;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- 事業所：住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address2' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value
-- 2019/09/11 Ver1.8 Mod Start
--                                      := SUBSTR( gt_main_data(i).l_address_line1, 16, 15 ) ;
                                      := SUBSTRB( gt_main_data(i).l_address_line1, 31, 30 ) ;
-- 2019/09/11 Ver1.8 Mod End
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := SUBSTRB( gv_l_address, 31, 30 ) ;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- 事業所：電話番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_phone_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_phone ;
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_phone;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- 事業所：ＦＡＸ番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax_num' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_fax ;
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_fax;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
        -- 事業所：事業所名称
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_name' ;
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- mod start ver1.6
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name ;
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value 
--                                     := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
        --【閲覧者：伊藤園】の場合
        IF ( ir_param.browser = '1' ) THEN
          gt_xml_data_table(gl_xml_idx).tag_value 
                                       := xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID);
        ELSE
        --【閲覧者：取引先】の場合
          gt_xml_data_table(gl_xml_idx).tag_value := gv_l_dept;
        END IF;
-- 2019/10/18 Mod Ver1.9 End
-- mod end ver1.6
-- 2019/09/11 Ver1.8 Add Start
        -- 事業所：取引先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_ven_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).vendor_code;
        -- 事業所：仕入先コード
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'ven_s_ven_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).s_vendor_code;
        ------------------------------------------------------
        -- 振込先情報
        ------------------------------------------------------
        -- 金融機関名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_name;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_name;
-- 2019/10/18 Mod Ver1.9 End
        -- 支店名
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_bra_name';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_bra_name;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_bra_name;
-- 2019/10/18 Mod Ver1.9 End
        -- 預金区分
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_type';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_acct_type;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_acct_type;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座No
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_num';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).bank_acct_num;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_bank_acct_num;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座名義ｶﾅ1
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 1, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 1, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座名義ｶﾅ2
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 31, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 31, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座名義ｶﾅ3
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt3';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 61, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 61, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座名義ｶﾅ4
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt4';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 91, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 91, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
        -- 口座名義ｶﾅ5
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'bank_acct_name_alt5';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Mod Ver1.9 Start
--        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gt_main_data(i).bank_acct_name_alt, 121, 30 ) ;
        gt_xml_data_table(gl_xml_idx).tag_value := SUBSTR( gv_bank_acct_name_alt, 121, 30 ) ;
-- 2019/10/18 Mod Ver1.9 End
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Del Start
--        ln_ttl_amount   := 0 ;  -- 今回有償金額
--        ln_ttl_tax      := 0 ;  -- 今回消費税等
--        ln_ttl_balance  := 0 ;  -- 今回有償額
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
        ln_amount_10      := 0;   -- 税抜金額（標準税率(10%)）
        ln_tax_10         := 0;   -- 消費税額（標準税率(10%)）
        ln_amount_8       := 0;   -- 税抜金額（軽減税率(8%)）
        ln_tax_8          := 0;   -- 消費税額（軽減税率(8%)）
        ln_amount_old_8   := 0;   -- 税抜金額（旧標準税率(8%)）
        ln_tax_old_8      := 0;   -- 消費税額（旧標準税率(8%)）
        ln_amount_no_tax  := 0;   -- 課税対象外
        ln_no_tax         := 0;   -- 課税対象外
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
        -- 品目区分(ヘッダ部）
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class_name;
        -- -----------------------------------------------------
        -- 明細ヘッダＬＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_list_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 明細ヘッダＧ開始タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_list';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 明細ヘッダ出力
        -- -----------------------------------------------------
        -- 明細タイトル
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_title_ven;
        -- 帳票ＩＤ
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_report_id';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_report_id;
        -- 実施日
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_exec_date';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR( gd_exec_date, gc_char_dt_format );
        -- 取引先：郵便番号
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_zip_code';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_zip;
        -- 取引先：住所１
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_address1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line1;
        -- 取引先：住所２
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_address2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).v_address_line2;
        -- 取引先：取引先名称１
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_name1';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name,  1, 20 );
        -- 取引先：取引先名称２
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_ven_name2';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value
                                      := SUBSTR( gt_main_data(i).v_vendor_name, 21, 10 );
        -- 期間From
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_period_from';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_from_char;
        -- 期間To
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'list_period_to';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := gv_fiscal_date_to_char;
        -- -----------------------------------------------------
        -- 明細ヘッダＧ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_list';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- -----------------------------------------------------
        -- 明細ヘッダＬＧ終了タグ出力
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_list_info';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
-- 2019/09/11 Ver1.8 Add End
-- 2019/09/11 Ver1.8 Del Start
--        -- -----------------------------------------------------
--        -- 取引先Ｇデータタグ出力
--        -- -----------------------------------------------------
--        -- 品目区分
--        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--        gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class' ;
--        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--        gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class ;
-- 2019/09/11 Ver1.8 Del End
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
-- 2019/09/11 Ver1.8 Del Start
--      ln_amount   := gt_main_data(i).amount;
--      ln_tax      := gt_main_data(i).tax;
---- mod end ver1.6
---- 2008/06/20 v1.3 Y.Yamamoto Update Start
----      ln_balance  := ln_amount - ln_tax ;
--      ln_balance  := ln_amount + ln_tax ;
---- 2008/06/20 v1.3 Y.Yamamoto Update End
----
--      -- 集計項目
--      ln_ttl_amount  := ln_ttl_amount  + ln_amount ;  -- 今回有償金額
--      ln_ttl_tax     := ln_ttl_tax     + ln_tax ;     -- 今回消費税等
--      ln_ttl_balance := ln_ttl_balance + ln_balance ; -- 今回有償額
--
-- 2019/09/11 Ver1.8 Del End
-- 2019/09/11 Ver1.8 Add Start
      -- 集計項目
      -- 税区分が標準税率(10%)
      IF ( gv_tax_type_10 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_10      := ln_amount_10 + gt_main_data(i).amount;
        ln_tax_10         := ln_tax_10 + gt_main_data(i).tax;
      -- 税区分が軽減税率(8%)
      ELSIF ( gv_tax_type_8 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_8       := ln_amount_8 + gt_main_data(i).amount;
        ln_tax_8          := ln_tax_8 + gt_main_data(i).tax;
      -- 税区分が旧標準税率(8%)
      ELSIF ( gv_tax_type_old_8 = gt_main_data(i).tax_type_code ) THEN
        ln_amount_old_8   := ln_amount_old_8 + gt_main_data(i).amount;
        ln_tax_old_8      := ln_tax_old_8 + gt_main_data(i).tax;
      -- 税区分が課税対象外
      ELSIF ( gv_tax_type_no_tax = gt_main_data(i).tax_type_code ) THEN
        ln_amount_no_tax  := ln_amount_no_tax + gt_main_data(i).amount;
        ln_no_tax         := ln_no_tax + gt_main_data(i).tax;
      END IF;
--
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_name  := 'date' ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'arrival_date';
-- 2019/09/11 Ver1.8 Mod End
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value
            := TO_CHAR( gt_main_data(i).arrival_date, gc_char_d_format ) ;
-- 2019/09/11 Ver1.8 Mod Start
      -- 有償年月
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sikyu_date';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).sikyu_date;
-- 2019/09/11 Ver1.8 Mod End
      -- 伝票番号
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'slip_num' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).request_no ;
-- 2019/09/11 Ver1.8 Add Start
      -- 請求管理部署
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'l_location_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
-- 2019/10/18 Ver1.9 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).l_location_name;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).billing_office;
-- 2019/10/18 Ver1.9 Mod End
      -- 品目区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'item_class_name';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).item_class_name;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Mod Start
--      gt_xml_data_table(gl_xml_idx).tag_value := ln_amount ;
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).amount;
-- 2019/09/11 Ver1.8 Mod End
-- 2019/09/11 Ver1.8 Add Start
      -- 消費税額
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tax';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).tax;
      -- 税区分
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_type';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
      gt_xml_data_table(gl_xml_idx).tag_value := gt_main_data(i).tax_type_name;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Mod Start
--    -- 今回有償金額
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_amount' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_amount ;
--    -- 今回消費税等
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_tax' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_tax ;
--    -- 今回有償額
--    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
--    gt_xml_data_table(gl_xml_idx).tag_name  := 'ttl_balance' ;
--    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
--    gt_xml_data_table(gl_xml_idx).tag_value := ln_ttl_balance ;
    -- 有償支給金額(税抜)(標準税率(10%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_10';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_10;
    -- 消費税額(標準税率(10%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_10';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_10;
    -- 有償支給金額(税抜)(軽減税率(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_8;
    -- 消費税額(軽減税率(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_8;
    -- 有償支給金額(税抜)(旧標準税率(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_old_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_old_8;
    -- 消費税額(旧標準税率(8%))
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tax_old_8';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_tax_old_8;
    -- 有償支給金額(税抜)(課税対象外)
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_no_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_amount_no_tax;
    -- 消費税額(課税対象外)
    gl_xml_idx := gt_xml_data_table.COUNT + 1;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'no_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
    gt_xml_data_table(gl_xml_idx).tag_value := ln_no_tax;
-- 2019/09/11 Ver1.8 Mod End
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
-- 2019/09/11 Ver1.8 Add Start
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_out_file_type      IN     VARCHAR2         --   05 : 出力ファイル形式
     ,iv_out_rep_type       IN     VARCHAR2         --   06 : 出力帳票形式
     ,iv_browser            IN     VARCHAR2         --   07 : 閲覧者
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
    lr_param_rec.item_class    := iv_item_class;              -- 品目区分
    lr_param_rec.out_file_type := NVL(iv_out_file_type, '0'); -- 出力ファイル形式
    lr_param_rec.out_rep_type  := NVL(iv_out_rep_type, '0');  -- 出力帳票形式
    lr_param_rec.browser       := iv_browser;                 -- 閲覧者
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <p_rep_type><![CDATA[2]]></p_rep_type>' ) ;
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_out_file_type      IN     VARCHAR2         --   05 : 出力ファイル形式(未入力:0,PDF:1,CSV:2)
     ,iv_out_rep_type       IN     VARCHAR2         --   06 : 出力帳票形式(未入力:0,鑑:1,明細:2)
     ,iv_browser            IN     VARCHAR2         --   07 : 閲覧者(伊藤園:1,取引先:2)
-- 2019/09/11 Ver1.8 Add End
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
-- 2019/09/11 Ver1.8 Add Start
       ,iv_item_class     => iv_item_class      --   04 : 品目区分
       ,iv_out_file_type  => iv_out_file_type   --   05 : 出力ファイル形式
       ,iv_out_rep_type   => iv_out_rep_type    --   06 : 出力帳票形式
       ,iv_browser        => iv_browser         --   07 : 閲覧者
-- 2019/09/11 Ver1.8 Add End
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