CREATE OR REPLACE PACKAGE BODY XXCFR004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A01C(body)
 * Description      : 支払通知データ抽出
 * MD.050           : MD050_CFR_004_A01_支払通知データ抽出
 * MD.070           : MD050_CFR_004_A01_支払通知データ抽出
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  get_process_date       p 業務処理日付取得処理                    (A-4)
 *  delete_payment_notes   p 支払通知テーブルデータ削除処理          (A-5)
 *  get_payment_notes      p 支払通知データ取得処理                  (A-6)
 *  convert_cust_code      p 顧客コード読替処理                      (A-7)
 *  insert_payment_notes   p 支払通知データテーブル登録処理          (A-8)
 *  put_log_error          p 読替エラーログ出力処理                  (A-9)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/24    1.00 SCS 中村 博      初回作成
 *  2009/02/24    1.1  SCS T.KANEDA     [障害COK_016] 顧客コード読替不具合対応
 *  2009/04/10    1.2  SCS S.KAYAHARA   T1_0129対応
 *  2009/04/24    1.3  SCS S.KAYAHARA   T1_0128対応
 *  2009/05/14    1.4  SCS S.KAYAHARA   T1_0955対応
 *  2009/06/10    1.5  SCS S.KAYAHARA   T1_1355対応
 *  2011/09/28    1.6  SCS S.NIKI       [E_本稼動_07906]流通BMS対応
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  file_not_exists_expt  EXCEPTION;      -- ファイル存在エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR004A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
--
  cv_msg_004a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_004a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --ファイル名出力メッセージ
  cv_msg_004a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付取得エラーメッセージ
  cv_msg_004a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --ロックエラーメッセージ
  cv_msg_004a01_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; --データ削除エラーメッセージ
  cv_msg_004a01_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00005'; --店コード変換エラー
  cv_msg_004a01_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; --ファイルなしエラー
  cv_msg_004a01_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00040'; --テキストバッファエラー
  cv_msg_004a01_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00041'; --数値型変換エラー
  cv_msg_004a01_019  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --テーブル挿入エラー
  cv_msg_004a01_020  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --ファイルの場所が無効メッセージ
  cv_msg_004a01_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --ファイルをオープンできないメッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- ファイル名
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- ファイルパス
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
-- Modify 2009.04.10 Ver1.2 Start
  cv_tkn_chcd        CONSTANT VARCHAR2(15) := 'CH_TEN_CODE';      -- チェーン店コード
-- Modify 2009.04.10 Ver1.2 End
  cv_tkn_tencd       CONSTANT VARCHAR2(15) := 'TEN_CODE';         -- 店コード
  cv_tkn_tennm       CONSTANT VARCHAR2(15) := 'TEN_NAME';         -- 店舗名称
  cv_tkn_col_num     CONSTANT VARCHAR2(15) := 'COL_NUM';          -- 項目Ｎｏ
  cv_tkn_col_val     CONSTANT VARCHAR2(15) := 'COL_VALUE';        -- 項目値
--
  --プロファイル
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
  cv_reserve_day     CONSTANT VARCHAR2(35) := 'XXCFR1_PAYMENT_NOTE_RESERVE_DAY';
                                                                  -- XXCFR:支払通知データ保存期間
  cv_payment_note_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_PAYMENT_NOTE_FILEPATH';
                                                                  -- XXCFR:支払通知データファイル格納パス
--
  cv_error_string    CONSTANT VARCHAR2(30) := 'Error';            -- エラー用店コード文字列
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_PAYMENT_NOTES';
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE g_cust_account_number_ttype       IS TABLE OF xxcfr_payment_notes.ebs_cust_account_number%type INDEX BY PLS_INTEGER;
  TYPE g_record_type_ttype               IS TABLE OF xxcfr_payment_notes.record_type%type INDEX BY PLS_INTEGER;
  TYPE g_record_number_ttype             IS TABLE OF xxcfr_payment_notes.record_number%type INDEX BY PLS_INTEGER;
  TYPE g_chain_shop_code_ttype           IS TABLE OF xxcfr_payment_notes.chain_shop_code%type INDEX BY PLS_INTEGER;
  TYPE g_process_date_ttype              IS TABLE OF xxcfr_payment_notes.process_date%type INDEX BY PLS_INTEGER;
  TYPE g_process_time_ttype              IS TABLE OF xxcfr_payment_notes.process_time%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_code_ttype               IS TABLE OF xxcfr_payment_notes.vendor_code%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_name_ttype               IS TABLE OF xxcfr_payment_notes.vendor_name%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_name_alt_ttype           IS TABLE OF xxcfr_payment_notes.vendor_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_company_code_ttype              IS TABLE OF xxcfr_payment_notes.company_code%type INDEX BY PLS_INTEGER;
  TYPE g_period_from_ttype               IS TABLE OF xxcfr_payment_notes.period_from%type INDEX BY PLS_INTEGER;
  TYPE g_period_to_ttype                 IS TABLE OF xxcfr_payment_notes.period_to%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_close_date_ttype        IS TABLE OF xxcfr_payment_notes.invoice_close_date%type INDEX BY PLS_INTEGER;
  TYPE g_payment_date_ttype              IS TABLE OF xxcfr_payment_notes.payment_date%type INDEX BY PLS_INTEGER;
  TYPE g_site_month_ttype                IS TABLE OF xxcfr_payment_notes.site_month%type INDEX BY PLS_INTEGER;
  TYPE g_note_count_ttype                IS TABLE OF xxcfr_payment_notes.note_count%type INDEX BY PLS_INTEGER;
  TYPE g_credit_note_count_ttype         IS TABLE OF xxcfr_payment_notes.credit_note_count%type INDEX BY PLS_INTEGER;
  TYPE g_rem_acceptance_count_ttype      IS TABLE OF xxcfr_payment_notes.rem_acceptance_count%type INDEX BY PLS_INTEGER;
  TYPE g_vendor_record_count_ttype       IS TABLE OF xxcfr_payment_notes.vendor_record_count%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_number_ttype            IS TABLE OF xxcfr_payment_notes.invoice_number%type INDEX BY PLS_INTEGER;
  TYPE g_invoice_type_ttype              IS TABLE OF xxcfr_payment_notes.invoice_type%type INDEX BY PLS_INTEGER;
  TYPE g_payment_type_ttype              IS TABLE OF xxcfr_payment_notes.payment_type%type INDEX BY PLS_INTEGER;
  TYPE g_payment_method_type_ttype       IS TABLE OF xxcfr_payment_notes.payment_method_type%type INDEX BY PLS_INTEGER;
  TYPE g_due_type_ttype                  IS TABLE OF xxcfr_payment_notes.due_type%type INDEX BY PLS_INTEGER;
  TYPE g_shop_code_ttype                 IS TABLE OF xxcfr_payment_notes.shop_code%type INDEX BY PLS_INTEGER;
  TYPE g_shop_name_ttype                 IS TABLE OF xxcfr_payment_notes.shop_name%type INDEX BY PLS_INTEGER;
  TYPE g_shop_name_alt_ttype             IS TABLE OF xxcfr_payment_notes.shop_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_amount_sign_ttype               IS TABLE OF xxcfr_payment_notes.amount_sign%type INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype                    IS TABLE OF xxcfr_payment_notes.amount%type INDEX BY PLS_INTEGER;
  TYPE g_tax_type_ttype                  IS TABLE OF xxcfr_payment_notes.tax_type%type INDEX BY PLS_INTEGER;
  TYPE g_tax_rate_ttype                  IS TABLE OF xxcfr_payment_notes.tax_rate%type INDEX BY PLS_INTEGER;
  TYPE g_tax_amount_ttype                IS TABLE OF xxcfr_payment_notes.tax_amount%type INDEX BY PLS_INTEGER;
  TYPE g_tax_diff_flag_ttype             IS TABLE OF xxcfr_payment_notes.tax_diff_flag%type INDEX BY PLS_INTEGER;
  TYPE g_diff_calc_flag_ttype            IS TABLE OF xxcfr_payment_notes.diff_calc_flag%type INDEX BY PLS_INTEGER;
  TYPE g_match_type_ttype                IS TABLE OF xxcfr_payment_notes.match_type%type INDEX BY PLS_INTEGER;
  TYPE g_unmatch_accoumt_amount_ttype    IS TABLE OF xxcfr_payment_notes.unmatch_accoumt_amount%type INDEX BY PLS_INTEGER;
  TYPE g_double_type_ttype               IS TABLE OF xxcfr_payment_notes.double_type%type INDEX BY PLS_INTEGER;
  TYPE g_acceptance_date_ttype           IS TABLE OF xxcfr_payment_notes.acceptance_date%type INDEX BY PLS_INTEGER;
  TYPE g_max_month_ttype                 IS TABLE OF xxcfr_payment_notes.max_month%type INDEX BY PLS_INTEGER;
  TYPE g_note_number_ttype               IS TABLE OF xxcfr_payment_notes.note_number%type INDEX BY PLS_INTEGER;
  TYPE g_line_number_ttype               IS TABLE OF xxcfr_payment_notes.line_number%type INDEX BY PLS_INTEGER;
  TYPE g_note_type_ttype                 IS TABLE OF xxcfr_payment_notes.note_type%type INDEX BY PLS_INTEGER;
  TYPE g_class_code_ttype                IS TABLE OF xxcfr_payment_notes.class_code%type INDEX BY PLS_INTEGER;
  TYPE g_div_code_ttype                  IS TABLE OF xxcfr_payment_notes.div_code%type INDEX BY PLS_INTEGER;
  TYPE g_sec_code_ttype                  IS TABLE OF xxcfr_payment_notes.sec_code%type INDEX BY PLS_INTEGER;
  TYPE g_return_type_ttype               IS TABLE OF xxcfr_payment_notes.return_type%type INDEX BY PLS_INTEGER;
  TYPE g_nitiriu_type_ttype              IS TABLE OF xxcfr_payment_notes.nitiriu_type%type INDEX BY PLS_INTEGER;
  TYPE g_sp_sale_type_ttype              IS TABLE OF xxcfr_payment_notes.sp_sale_type%type INDEX BY PLS_INTEGER;
  TYPE g_shipment_ttype                  IS TABLE OF xxcfr_payment_notes.shipment%type INDEX BY PLS_INTEGER;
  TYPE g_order_date_ttype                IS TABLE OF xxcfr_payment_notes.order_date%type INDEX BY PLS_INTEGER;
  TYPE g_delivery_date_ttype             IS TABLE OF xxcfr_payment_notes.delivery_date%type INDEX BY PLS_INTEGER;
  TYPE g_product_code_ttype              IS TABLE OF xxcfr_payment_notes.product_code%type INDEX BY PLS_INTEGER;
  TYPE g_product_name_ttype              IS TABLE OF xxcfr_payment_notes.product_name%type INDEX BY PLS_INTEGER;
  TYPE g_product_name_alt_ttype          IS TABLE OF xxcfr_payment_notes.product_name_alt%type INDEX BY PLS_INTEGER;
  TYPE g_delivery_quantity_ttype         IS TABLE OF xxcfr_payment_notes.delivery_quantity%type INDEX BY PLS_INTEGER;
  TYPE g_cost_unit_price_ttype           IS TABLE OF xxcfr_payment_notes.cost_unit_price%type INDEX BY PLS_INTEGER;
  TYPE g_cost_price_ttype                IS TABLE OF xxcfr_payment_notes.cost_price%type INDEX BY PLS_INTEGER;
  TYPE g_desc_code_ttype                 IS TABLE OF xxcfr_payment_notes.desc_code%type INDEX BY PLS_INTEGER;
  TYPE g_chain_orig_desc_ttype           IS TABLE OF xxcfr_payment_notes.chain_orig_desc%type INDEX BY PLS_INTEGER;
  TYPE g_sum_amount_ttype                IS TABLE OF xxcfr_payment_notes.sum_amount%type INDEX BY PLS_INTEGER;
  TYPE g_discount_sum_amount_ttype       IS TABLE OF xxcfr_payment_notes.discount_sum_amount%type INDEX BY PLS_INTEGER;
  TYPE g_return_sum_amount_ttype         IS TABLE OF xxcfr_payment_notes.return_sum_amount%type INDEX BY PLS_INTEGER;
-- Add 2011/09/28 Ver1.6 Start
  -- 流通ＢＭＳヘッダデータ
  TYPE g_bms_header_data_ttype           IS TABLE OF xxcfr_payment_notes.bms_header_data%type INDEX BY PLS_INTEGER;
  -- 流通ＢＭＳ明細データ
  TYPE g_bms_line_data_ttype             IS TABLE OF xxcfr_payment_notes.bms_line_data%type INDEX BY PLS_INTEGER;
-- Add 2011/09/28 Ver1.6 End
  gt_pn_ebs_cust_account_number         g_cust_account_number_ttype;
  gt_pn_record_type                     g_record_type_ttype;
  gt_pn_record_number                   g_record_number_ttype;
  gt_pn_chain_shop_code                 g_chain_shop_code_ttype;
  gt_pn_process_date                    g_process_date_ttype;
  gt_pn_process_time                    g_process_time_ttype;
  gt_pn_vendor_code                     g_vendor_code_ttype;
  gt_pn_vendor_name                     g_vendor_name_ttype;
  gt_pn_vendor_name_alt                 g_vendor_name_alt_ttype;
  gt_pn_company_code                    g_company_code_ttype;
  gt_pn_period_from                     g_period_from_ttype;
  gt_pn_period_to                       g_period_to_ttype;
  gt_pn_invoice_close_date              g_invoice_close_date_ttype;
  gt_pn_payment_date                    g_payment_date_ttype;
  gt_pn_site_month                      g_site_month_ttype;
  gt_pn_note_count                      g_note_count_ttype;
  gt_pn_credit_note_count               g_credit_note_count_ttype;
  gt_pn_rem_acceptance_count            g_rem_acceptance_count_ttype;
  gt_pn_vendor_record_count             g_vendor_record_count_ttype;
  gt_pn_invoice_number                  g_invoice_number_ttype;
  gt_pn_invoice_type                    g_invoice_type_ttype;
  gt_pn_payment_type                    g_payment_type_ttype;
  gt_pn_payment_method_type             g_payment_method_type_ttype;
  gt_pn_due_type                        g_due_type_ttype;
  gt_pn_shop_code                       g_shop_code_ttype;
  gt_pn_shop_name                       g_shop_name_ttype;
  gt_pn_shop_name_alt                   g_shop_name_alt_ttype;
  gt_pn_amount_sign                     g_amount_sign_ttype;
  gt_pn_amount                          g_amount_ttype;
  gt_pn_tax_type                        g_tax_type_ttype;
  gt_pn_tax_rate                        g_tax_rate_ttype;
  gt_pn_tax_amount                      g_tax_amount_ttype;
  gt_pn_tax_diff_flag                   g_tax_diff_flag_ttype;
  gt_pn_diff_calc_flag                  g_diff_calc_flag_ttype;
  gt_pn_match_type                      g_match_type_ttype;
  gt_pn_unmatch_accoumt_amount          g_unmatch_accoumt_amount_ttype;
  gt_pn_double_type                     g_double_type_ttype;
  gt_pn_acceptance_date                 g_acceptance_date_ttype;
  gt_pn_max_month                       g_max_month_ttype;
  gt_pn_note_number                     g_note_number_ttype;
  gt_pn_line_number                     g_line_number_ttype;
  gt_pn_note_type                       g_note_type_ttype;
  gt_pn_class_code                      g_class_code_ttype;
  gt_pn_div_code                        g_div_code_ttype;
  gt_pn_sec_code                        g_sec_code_ttype;
  gt_pn_return_type                     g_return_type_ttype;
  gt_pn_nitiriu_type                    g_nitiriu_type_ttype;
  gt_pn_sp_sale_type                    g_sp_sale_type_ttype;
  gt_pn_shipment                        g_shipment_ttype;
  gt_pn_order_date                      g_order_date_ttype;
  gt_pn_delivery_date                   g_delivery_date_ttype;
  gt_pn_product_code                    g_product_code_ttype;
  gt_pn_product_name                    g_product_name_ttype;
  gt_pn_product_name_alt                g_product_name_alt_ttype;
  gt_pn_delivery_quantity               g_delivery_quantity_ttype;
  gt_pn_cost_unit_price                 g_cost_unit_price_ttype;
  gt_pn_cost_price                      g_cost_price_ttype;
  gt_pn_desc_code                       g_desc_code_ttype;
  gt_pn_chain_orig_desc                 g_chain_orig_desc_ttype;
  gt_pn_sum_amount                      g_sum_amount_ttype;
  gt_pn_discount_sum_amount             g_discount_sum_amount_ttype;
  gt_pn_return_sum_amount               g_return_sum_amount_ttype;
-- Add 2011/09/28 Ver1.6 Start
  gt_pn_bms_header_data                 g_bms_header_data_ttype;         -- 流通ＢＭＳヘッダデータ
  gt_pn_bms_line_data                   g_bms_line_data_ttype;           -- 流通ＢＭＳ明細データ
-- Add 2011/09/28 Ver1.6 End
--
  TYPE c_payment_note_len_ttype IS TABLE OF NUMBER;
  gt_payment_note_len_data  c_payment_note_len_ttype := c_payment_note_len_ttype ( 
-- Modify 2009.04.22 Ver1.3 Start
--    1,    -- レコード区分
-- Modify 2009.04.22 Ver1.3 End
    7,    -- レコード通番
    4,    -- チェーン店コード
    8,    -- データ作成日／データ処理日付／データ日付／伝送日付
    6,    -- データ作成時刻／データ処理時刻
    8,    -- 仕入先コード/取引先コード
    30,   -- 仕入先名称/取引先名称（漢字）
    30,   -- 仕入先名称/取引先名称（カナ）
    6,    -- 社コード
    8,    -- 対象期間・自
    8,    -- 対象期間・至
    8,    -- 請求締年月日
    8,    -- 支払年月日
    2,    -- サイト月数
    6,    -- 伝票枚数
    6,    -- 訂正伝票枚数
    6,    -- 未検収伝票枚数
    7,    -- 取引先内レコード通番
    11,   -- 請求書№／請求番号
    2,    -- 請求区分
    2,    -- 支払区分
    2,    -- 支払方法区分
    2,    -- 発行区分
-- Modify 2009.04.22 Ver1.3 Start
--    8,    -- 店コード
--    80,   -- 店舗名称（漢字）
--    80,   -- 店舗名称（カナ）
    10,   -- 店コード
    100,  -- 店舗名称（漢字）
    50,   -- 店舗名称（カナ）
-- Modify 2009.04.22 Ver1.3 End
    1,    -- 請求金額符号／請求消費税額符号
    15,   -- 請求金額／支払金額
    1,    -- 消費税区分
-- Modify 2009.04.22 Ver1.3 Start
--    2,    -- 消費税率
    4,    --消費税率
-- Modify 2009.04.22 Ver1.3 End
    15,   -- 請求消費税額／支払消費税額
    1,    -- 消費税差額フラグ
    2,    -- 違算区分
    2,    -- マッチ区分
    15,   -- アンマッチ買掛計上金額
    2,    -- ダブリ区分
    8,    -- 検収日
    8,    -- 月限
-- Modify 2009.04.22 Ver1.3 Start
--    20,   -- 伝票番号
--    15,   -- 行№
    12,   -- 伝票番号
    3,    -- 行No.
-- Modify 2009.04.22 Ver1.3 End
    2,    -- 伝票区分／伝票種別
    4,    -- 分類コード
    6,    -- 部門コード
    4,    -- 課コード
    2,    -- 売上返品区分
    2,    -- ニチリウ経由区分
    2,    -- 特売区分
-- Modify 2009.04.22 Ver1.3 Start
--    6,    -- 便
    3,    -- 便
-- Modify 2009.04.22 Ver1.3 End
    8,    -- 発注日
    8,    -- 納品日/返品日
    7,    -- 商品コード
    60,   -- 商品名（漢字）
    30,   -- 商品名（カナ）
    15,   -- 納品数量
-- Modify 2009.04.22 Ver1.3 Start
--    15,   -- 原価単価
--    15,   -- 原価金額
    12,   -- 原価単価
    10,   -- 原価金額
-- Modify 2009.04.22 Ver1.3 End
    4,    -- 備考コード
    300,  -- チェーン固有エリア
    15,   -- 請求合計金額/支払合計金額
    15,   -- 値引合計金額
-- Modify 2011/09/28 Ver1.6 Start
--    15    -- 返品合計金額
    15,   -- 返品合計金額
    49,   -- 予備エリア
    2000, -- 流通ＢＭＳヘッダデータ
    1500  -- 流通ＢＭＳ明細データ
-- Modify 2011/09/28 Ver1.6 End
  )
  ;

  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_reserve_day        NUMBER;             -- 支払通知データ保存期間
  gn_org_id             NUMBER;             -- 組織ID
  gd_process_date       DATE;               -- 業務処理日付
  gv_payment_note_filepath VARCHAR2(500);   -- 支払通知データファイル格納パス
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_filename             IN  VARCHAR2,     --    支払通知データファイル名
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,iv_conc_param1  => iv_filename        -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,iv_conc_param1  => iv_filename        -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- プロファイルからXXCFR:支払通知データ保存期間取得
    gn_reserve_day := TO_NUMBER(FND_PROFILE.VALUE(cv_reserve_day));
    -- 取得エラー時
    IF (gn_reserve_day IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_reserve_day))
                                                       -- XXCFR:支払通知データ保存期間
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR: 支払通知データファイル格納パス取得
    gv_payment_note_filepath := FND_PROFILE.VALUE(cv_payment_note_filepath);
    -- 取得エラー時
    IF (gv_payment_note_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_payment_note_filepath))
                                                       -- XXCFR:支払通知データファイル格納パス
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理 (A-4)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 業務処理日付取得処理
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- 取得エラー時
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_012 -- 業務処理日付取得エラー
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : delete_payment_notes
   * Description      : 支払通知テーブルデータ削除処理 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_payment_notes(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_payment_notes'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR del_payment_note_cur
    IS
      SELECT xpn.ROWID        ln_rowid
      FROM xxcfr_payment_notes  xpn
      WHERE xpn.org_id                         = gn_org_id  -- 組織ID
        AND xpn.ebs_posted_date                < gd_process_date - gn_reserve_day
                                                 -- 業務日付 - 支払通知データ保存期間
      FOR UPDATE NOWAIT
    ;
--
    TYPE g_del_payment_note_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_payment_note_data    g_del_payment_note_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN del_payment_note_cur;
--
    -- データの一括取得
    FETCH del_payment_note_cur BULK COLLECT INTO lt_del_payment_note_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_del_payment_note_data.COUNT;
--
    -- カーソルクローズ
    CLOSE del_payment_note_cur;
--
    -- 対象データが存在する場合レコードを削除する
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<null_data_loop1>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_payment_notes
          WHERE ROWID = lt_del_payment_note_data(ln_loop_cnt);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_004a01_014 -- データ削除エラー
                                                        ,cv_tkn_table         -- トークン'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                       -- 支払通知情報テーブル
                                                        ,1
                                                        ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_004a01_013    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- 支払通知情報テーブル
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : get_payment_notes
   * Description      : 支払通知データ取得処理 (A-6)
   ***********************************************************************************/
  PROCEDURE get_payment_notes(
    iv_filename             IN  VARCHAR2,            -- 支払通知データファイル名
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment_notes'; -- プログラム名
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
    cv_open_mode_r    CONSTANT VARCHAR2(10) := 'r';     -- ファイルオープンモード（読み込み）
--
    -- *** ローカル変数 ***
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;       -- 
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
    -- 
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
    ln_text_pos     NUMBER;         -- ファイル走査位置
-- Modify 2011/09/28 Ver1.6 Start
--    lv_col_value    VARCHAR2(1000) ;-- 項目値 
    lv_col_value    VARCHAR2(2000) ;-- 項目値
-- Modify 2011/09/28 Ver1.6 End
    ln_col_num      NUMBER;         -- カラムＮＯ
-- Add 2011/09/28 Ver1.6 Start
    ln_utl_max_size NUMBER := 32767;-- 最大レコード数
-- Add 2011/09/28 Ver1.6 End
--
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_payment_note_filepath,
                      iv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- ファイル存在なし
    IF not(lb_fexists) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_016 -- ファイルなし
                                                    ,cv_tkn_file
                                                    ,iv_filename
                                                    ,cv_tkn_path
                                                    ,gv_payment_note_filepath)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE file_not_exists_expt;
    END IF;
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_payment_note_filepath
                       ,iv_filename
                       ,cv_open_mode_r
-- Add 2011/09/28 Ver1.6 Start
                       ,ln_utl_max_size
-- Add 2011/09/28 Ver1.6 End
                      ) ;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    gt_pn_record_type(1)             := 'B';
    <<out_loop>>
    LOOP
      BEGIN
        -- ====================================================
        -- ファイル取り込み
        -- ====================================================
        UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- 処理件数カウントアップ
        -- ====================================================
        ln_target_cnt := ln_target_cnt + 1 ;
--
        -- ====================================================
        -- 固定長ファイル項目別区切り
        -- ====================================================
        ln_text_pos := 1;
        <<col_div_loop>>
        FOR ln_loop_cnt IN gt_payment_note_len_data.FIRST..gt_payment_note_len_data.LAST LOOP
          -- 項目値の取得
          lv_col_value := substrb( lv_csv_text, ln_text_pos, gt_payment_note_len_data(ln_loop_cnt));
          ln_col_num := ln_loop_cnt;
--
--    FND_FILE.PUT_LINE(
--       FND_FILE.LOG
--      ,'項目ループ：' || to_char ( ln_target_cnt ) || ':' || to_char ( ln_loop_cnt )  || ':' || lv_col_value
--    );
--
          -- テーブル型変数への格納
          CASE ln_loop_cnt
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 1 THEN
--            gt_pn_record_type(ln_target_cnt)             := lv_col_value;
--          WHEN 2 THEN
          WHEN 1 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_record_number(ln_target_cnt)           := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 3 THEN
          WHEN 2 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.06.10 Ver1.5 Start
--            gt_pn_chain_shop_code(ln_target_cnt)         := lv_col_value;
            gt_pn_chain_shop_code(ln_target_cnt)         := LTRIM(lv_col_value);
-- Modify 2009.06.10 Ver1.5 End
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 4 THEN
          WHEN 3 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_process_date(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 5 THEN
          WHEN 4 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_process_time(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 6 THEN
          WHEN 5 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_code(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 7 THEN
          WHEN 6 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_name(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 8 THEN
          WHEN 7 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_name_alt(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 9 THEN
          WHEN 8 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_company_code(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 10 THEN
          WHEN 9 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_period_from(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 11 THEN
          WHEN 10 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_period_to(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 12 THEN
          WHEN 11 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_close_date(ln_target_cnt)      := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 13 THEN
          WHEN 12 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_date(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 14 THEN
          WHEN 13 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.05.14 Ver1.4 Start
--            gt_pn_site_month(ln_target_cnt)              := TO_NUMBER(lv_col_value);
            gt_pn_site_month(ln_target_cnt)              := TO_NUMBER(RTRIM(lv_col_value));
-- Modify 2009.05.14 Ver1.4 End            
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 15 THEN
          WHEN 14 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_count(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 16 THEN
          WHEN 15 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_credit_note_count(ln_target_cnt)       := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 17 THEN
          WHEN 16 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_rem_acceptance_count(ln_target_cnt)    := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 18 THEN
          WHEN 17 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_vendor_record_count(ln_target_cnt)     := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 19 THEN
          WHEN 18 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_number(ln_target_cnt)          := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 20 THEN
          WHEN 19 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_invoice_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 21 THEN
          WHEN 20 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 22 THEN
          WHEN 21 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_payment_method_type(ln_target_cnt)     := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 23 THEN
          WHEN 22 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_due_type(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 24 THEN
          WHEN 23 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.06.10 Ver1.5 Start
--            gt_pn_shop_code(ln_target_cnt)               := lv_col_value;
            gt_pn_shop_code(ln_target_cnt)               := LTRIM(lv_col_value);
-- Modify 2009.06.10 Ver1.5 End
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 25 THEN
          WHEN 24 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shop_name(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 26 THEN
          WHEN 25 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shop_name_alt(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 27 THEN
          WHEN 26 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_amount_sign(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 28 THEN
          WHEN 27 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_amount(ln_target_cnt)                  := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 29 THEN
          WHEN 28 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_type(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 30 THEN
          WHEN 29 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_rate(ln_target_cnt)                := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 31 THEN
          WHEN 30 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_amount(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 32 THEN
          WHEN 31 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_tax_diff_flag(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 33 THEN
          WHEN 32 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_diff_calc_flag(ln_target_cnt)          := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 34 THEN
          WHEN 33 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_match_type(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 35 THEN
          WHEN 34 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_unmatch_accoumt_amount(ln_target_cnt)  := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 36 THEN
          WHEN 35 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_double_type(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 37 THEN
          WHEN 36 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_acceptance_date(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 38 THEN
          WHEN 37 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_max_month(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 39 THEN
          WHEN 38 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_number(ln_target_cnt)             := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 40 THEN
          WHEN 39 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_line_number(ln_target_cnt)             := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 41 THEN
          WHEN 40 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_note_type(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 42 THEN
          WHEN 41 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_class_code(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 43 THEN
          WHEN 42 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_div_code(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 44 THEN
          WHEN 43 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sec_code(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 45 THEN
          WHEN 44 THEN
-- Modify 2009.04.22 Ver1.3 End
-- Modify 2009.05.14 Ver1.4 Start
--            gt_pn_return_type(ln_target_cnt)             := TO_NUMBER(lv_col_value);
          gt_pn_return_type(ln_target_cnt)             := TO_NUMBER(RTRIM(lv_col_value));
-- Modify 2009.05.14 Ver1.4 End
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 46 THEN
          WHEN 45 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_nitiriu_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 47 THEN
          WHEN 46 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sp_sale_type(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 48 THEN
          WHEN 47 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_shipment(ln_target_cnt)                := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 49 THEN
          WHEN 48 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_order_date(ln_target_cnt)              := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 50 THEN
          WHEN 49 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_delivery_date(ln_target_cnt)           := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 51 THEN
          WHEN 50 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_code(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 52 THEN
          WHEN 51 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_name(ln_target_cnt)            := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 53 THEN
          WHEN 52 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_product_name_alt(ln_target_cnt)        := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 54 THEN
          WHEN 53 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_delivery_quantity(ln_target_cnt)       := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 55 THEN
          WHEN 54 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_cost_unit_price(ln_target_cnt)         := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 56 THEN
          WHEN 55 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_cost_price(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 57 THEN
          WHEN 56 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_desc_code(ln_target_cnt)               := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 58 THEN
          WHEN 57 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_chain_orig_desc(ln_target_cnt)         := lv_col_value;
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 59 THEN
          WHEN 58 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_sum_amount(ln_target_cnt)              := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 60 THEN
          WHEN 59 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_discount_sum_amount(ln_target_cnt)     := TO_NUMBER(lv_col_value);
-- Modify 2009.04.22 Ver1.3 Start
--          WHEN 61 THEN
          WHEN 60 THEN
-- Modify 2009.04.22 Ver1.3 End
            gt_pn_return_sum_amount(ln_target_cnt)       := TO_NUMBER(lv_col_value);
-- Add 2011/09/28 Ver1.6 Start
          WHEN 62 THEN
            gt_pn_bms_header_data(ln_target_cnt)         := RTRIM(lv_col_value);
          WHEN 63 THEN
            gt_pn_bms_line_data(ln_target_cnt)           := RTRIM(lv_col_value);
-- Add 2011/09/28 Ver1.6 End
          ELSE NULL;
          END CASE;
--
          -- ファイル走査位置移動
          ln_text_pos := ln_text_pos + gt_payment_note_len_data(ln_loop_cnt);
--
        END LOOP col_div_loop;
--
      EXCEPTION
        -- *** 行がバッファに収まらない場合 ***
        WHEN value_error THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_004a01_018
                                                        ,cv_tkn_col_num    -- トークン'COL_NUM'
                                                        ,TO_CHAR(ln_col_num)
                                                        ,cv_tkn_col_val    -- トークン'COL_VALUE'
                                                        ,lv_col_value
                                                        ) -- テキストバッファエラー
                                                       ,1
                                                       ,5000);
          gn_target_cnt := ln_target_cnt;
          gn_error_cnt := ln_target_cnt;
          RAISE global_api_expt;
        -- *** ファイルの終わりに達したため、テキストが読み込まれなかった場合 ***
        WHEN NO_DATA_FOUND THEN
          EXIT;
      END;
--
    END LOOP out_loop ;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_target_cnt := ln_target_cnt;
--
  EXCEPTION
--
    WHEN file_not_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_020 -- ファイルの場所が無効
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a01_021 -- ファイルをオープンできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : convert_cust_code
   * Description      : 顧客コード読替処理 (A-7)
   ***********************************************************************************/
  PROCEDURE convert_cust_code(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_cust_code'; -- プログラム名
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
    ln_loop_cnt     NUMBER; -- ループカウンタ
    ln_error_cnt    NUMBER := 0; -- エラーカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================================
    --  顧客コード読替処理 (A-7)
    -- =====================================================
    <<cust_data_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      -- 顧客コードを読み替える
      BEGIN
        SELECT hca.account_number           account_number
        INTO gt_pn_ebs_cust_account_number(ln_loop_cnt)
        FROM hz_cust_accounts       hca,    -- 顧客マスタ
             xxcmm_cust_accounts    xca     -- 顧客追加情報テーブル
        WHERE hca.cust_account_id        = xca.customer_id
-- Modify 2009.02.24 Ver1.1 Start
--          AND xca.store_code             = gt_pn_shop_code(ln_loop_cnt) -- 店舗コード
          AND xca.store_code             = RTRIM(gt_pn_shop_code(ln_loop_cnt)) -- 店舗コード
-- Modify 2009.04.10 Ver1.2 Start
          AND xca.chain_store_code       = RTRIM(gt_pn_chain_shop_code(ln_loop_cnt)) -- チェーン店コード
-- Modify 2009.04.10 ver1.2 End
-- Modify 2009.02.24 Ver1.1 End	
        ;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
       which  => FND_FILE.log
      ,buff   => SQLERRM
    );
          gt_pn_ebs_cust_account_number(ln_loop_cnt) := cv_error_string;
          ln_error_cnt := ln_error_cnt + 1;
      END;
    END LOOP cust_data_loop;
--
    gn_error_cnt := ln_error_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END convert_cust_code;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_payment_notes
   * Description      : 支払通知データテーブル登録処理 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_payment_notes(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_payment_notes'; -- プログラム名
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
    ln_loop_cnt     NUMBER;        -- ループカウンタ
    ln_normal_cnt   NUMBER := 0;   -- 正常件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================================
    --  支払通知データテーブル登録処理 (A-8)
    -- =====================================================
    BEGIN
      <<inert_loop>>
      FORALL ln_loop_cnt IN 1..gn_target_cnt
        INSERT INTO xxcfr_payment_notes ( 
           payment_note_id
          ,ebs_posted_date
          ,ebs_cust_account_number
          ,record_type
          ,record_number
          ,chain_shop_code
          ,process_date
          ,process_time
          ,vendor_code
          ,vendor_name
          ,vendor_name_alt
          ,company_code
          ,period_from
          ,period_to
          ,invoice_close_date
          ,payment_date
          ,site_month
          ,note_count
          ,credit_note_count
          ,rem_acceptance_count
          ,vendor_record_count
          ,invoice_number
          ,invoice_type
          ,payment_type
          ,payment_method_type
          ,due_type
          ,shop_code
          ,shop_name
          ,shop_name_alt
          ,amount_sign
          ,amount
          ,tax_type
          ,tax_rate
          ,tax_amount
          ,tax_diff_flag
          ,diff_calc_flag
          ,match_type
          ,unmatch_accoumt_amount
          ,double_type
          ,acceptance_date
          ,max_month
          ,note_number
          ,line_number
          ,note_type
          ,class_code
          ,div_code
          ,sec_code
          ,return_type
          ,nitiriu_type
          ,sp_sale_type
          ,shipment
          ,order_date
          ,delivery_date
          ,product_code
          ,product_name
          ,product_name_alt
          ,delivery_quantity
          ,cost_unit_price
          ,cost_price
          ,desc_code
          ,chain_orig_desc
          ,sum_amount
          ,discount_sum_amount
          ,return_sum_amount
          ,org_id
-- Add 2011/09/28 Ver1.6 Start
          ,bms_header_data                           -- 流通ＢＭＳヘッダデータ
          ,bms_line_data                             -- 流通ＢＭＳ明細データ
-- Add 2011/09/28 Ver1.6 End
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login 
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        )
        VALUES ( 
           xxcfr_payment_notes_s1.NEXTVAL
          ,gd_process_date
          ,gt_pn_ebs_cust_account_number(ln_loop_cnt)
-- Modify 2009.04.22 Ver1.3 Start
--          ,gt_pn_record_type(ln_loop_cnt)
          ,NULL
-- Modify 2009.04.22 Ver1.3 End
          ,gt_pn_record_number(ln_loop_cnt)
          ,gt_pn_chain_shop_code(ln_loop_cnt)
          ,gt_pn_process_date(ln_loop_cnt)
          ,gt_pn_process_time(ln_loop_cnt)
          ,gt_pn_vendor_code(ln_loop_cnt)
          ,gt_pn_vendor_name(ln_loop_cnt)
          ,gt_pn_vendor_name_alt(ln_loop_cnt)
          ,gt_pn_company_code(ln_loop_cnt)
          ,gt_pn_period_from(ln_loop_cnt)
          ,gt_pn_period_to(ln_loop_cnt)
          ,gt_pn_invoice_close_date(ln_loop_cnt)
          ,gt_pn_payment_date(ln_loop_cnt)
          ,gt_pn_site_month(ln_loop_cnt)
          ,gt_pn_note_count(ln_loop_cnt)
          ,gt_pn_credit_note_count(ln_loop_cnt)
          ,gt_pn_rem_acceptance_count(ln_loop_cnt)
          ,gt_pn_vendor_record_count(ln_loop_cnt)
          ,gt_pn_invoice_number(ln_loop_cnt)
          ,gt_pn_invoice_type(ln_loop_cnt)
          ,gt_pn_payment_type(ln_loop_cnt)
          ,gt_pn_payment_method_type(ln_loop_cnt)
          ,gt_pn_due_type(ln_loop_cnt)
          ,gt_pn_shop_code(ln_loop_cnt)
          ,gt_pn_shop_name(ln_loop_cnt)
          ,gt_pn_shop_name_alt(ln_loop_cnt)
          ,gt_pn_amount_sign(ln_loop_cnt)
          ,gt_pn_amount(ln_loop_cnt)
          ,gt_pn_tax_type(ln_loop_cnt)
-- Modify 2009.04.22 Ver1.3 Start          
--          ,gt_pn_tax_rate(ln_loop_cnt)
          ,gt_pn_tax_rate(ln_loop_cnt) / 100 -- 消費税率は小数点２桁あり
-- Modify 2009.04.22 Ver1.3 End
          ,gt_pn_tax_amount(ln_loop_cnt)
          ,gt_pn_tax_diff_flag(ln_loop_cnt)
          ,gt_pn_diff_calc_flag(ln_loop_cnt)
          ,gt_pn_match_type(ln_loop_cnt)
          ,gt_pn_unmatch_accoumt_amount(ln_loop_cnt)
          ,gt_pn_double_type(ln_loop_cnt)
          ,gt_pn_acceptance_date(ln_loop_cnt)
          ,gt_pn_max_month(ln_loop_cnt)
          ,gt_pn_note_number(ln_loop_cnt)
          ,gt_pn_line_number(ln_loop_cnt)
          ,gt_pn_note_type(ln_loop_cnt)
          ,gt_pn_class_code(ln_loop_cnt)
          ,gt_pn_div_code(ln_loop_cnt)
          ,gt_pn_sec_code(ln_loop_cnt)
          ,gt_pn_return_type(ln_loop_cnt)
          ,gt_pn_nitiriu_type(ln_loop_cnt)
          ,gt_pn_sp_sale_type(ln_loop_cnt)
          ,gt_pn_shipment(ln_loop_cnt)
          ,gt_pn_order_date(ln_loop_cnt)
          ,gt_pn_delivery_date(ln_loop_cnt)
          ,gt_pn_product_code(ln_loop_cnt)
          ,gt_pn_product_name(ln_loop_cnt)
          ,gt_pn_product_name_alt(ln_loop_cnt)
          ,gt_pn_delivery_quantity(ln_loop_cnt)
          ,gt_pn_cost_unit_price(ln_loop_cnt) / 100  -- 原価単価は小数点２桁あり
          ,gt_pn_cost_price(ln_loop_cnt)
          ,gt_pn_desc_code(ln_loop_cnt)
          ,gt_pn_chain_orig_desc(ln_loop_cnt)
          ,gt_pn_sum_amount(ln_loop_cnt)
          ,gt_pn_discount_sum_amount(ln_loop_cnt)
          ,gt_pn_return_sum_amount(ln_loop_cnt)
          ,gn_org_id
-- Add 2011/09/28 Ver1.6 Start
          ,gt_pn_bms_header_data(ln_loop_cnt)        -- 流通ＢＭＳヘッダデータ
          ,gt_pn_bms_line_data(ln_loop_cnt)          -- 流通ＢＭＳ明細データ
-- Add 2011/09/28 Ver1.6 End
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
    EXCEPTION
      WHEN OTHERS THEN  -- 更新時エラー
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a01_019    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 支払通知情報テーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    gn_normal_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_payment_notes;
--
  /**********************************************************************************
   * Procedure Name   : put_log_error
   * Description      : 読替エラーログ出力処理 (A-9)
   ***********************************************************************************/
  PROCEDURE put_log_error(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_log_error'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    --読替エラー抽出
    CURSOR payment_note_err_cur
    IS
      SELECT distinct
-- Modify 2009.04.10 Ver1.2 Start
             xpn.chain_shop_code    chain_shop_code,
-- Modify 2009.04.10 Ver1.2 End
             xpn.shop_code          shop_code,
             xpn.shop_name          shop_name
      FROM xxcfr_payment_notes  xpn
      WHERE xpn.request_id                     = cn_request_id  -- コンカレント・プログラムの要求ID
        AND xpn.ebs_cust_account_number        = cv_error_string
-- Modify 2009.04.10 Ver1.2 Start
--      ORDER BY xpn.shop_code
      ORDER BY xpn.chain_shop_code
              ,xpn.shop_code
-- Modify 2009.04.10 Ver1.2 End
    ;
--
    TYPE g_payment_note_err_ttype IS TABLE OF payment_note_err_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_payment_note_err_data    g_payment_note_err_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN payment_note_err_cur;
--
    -- データの一括取得
    FETCH payment_note_err_cur BULK COLLECT INTO lt_payment_note_err_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_payment_note_err_data.COUNT;
--
    -- カーソルクローズ
    CLOSE payment_note_err_cur;
--
    -- 顧客コード読替エラーデータをログに出力する
    IF (ln_target_cnt > 0) THEN
      <<null_data_loop1>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(cv_msg_kbn_cfr     -- 'XXCFR'
                                                      ,cv_msg_004a01_015
-- Modify 2009.04.10 Ver1.2 Start
                                                      ,cv_tkn_chcd -- トークン'CH_TEN_CODE'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).chain_shop_code
                                                        -- チェーン店コード
-- Modify 2009.04.10 Ver1.2 End                                                      
                                                      ,cv_tkn_tencd -- トークン'TEN_CODE'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).shop_code
                                                        -- 店コード
                                                      ,cv_tkn_tennm -- トークン'TEN_NAME'
                                                      ,lt_payment_note_err_data(ln_loop_cnt).shop_name)
                                                        -- 店舗名称
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END LOOP null_data_loop1;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_log_error;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_filename   IN  VARCHAR2,     --    支払通知データファイル名
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_filename           -- 支払通知データファイル名
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  支払通知データファイル情報ログ処理(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_004a01_011 -- ファイル名出力メッセージ
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                 ,iv_filename)      -- ファイル名
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
    -- =====================================================
    --  業務処理日付取得処理 (A-4)
    -- =====================================================
    get_process_date(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  支払通知テーブルデータ削除処理 (A-5)
    -- =====================================================
    delete_payment_notes(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  支払通知データ取得処理 (A-6)
    -- =====================================================
    get_payment_notes(
       iv_filename           -- 支払通知データファイル名
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  顧客コード読替処理 (A-7)
    -- =====================================================
    convert_cust_code(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  支払通知データテーブル登録処理 (A-8)
    -- =====================================================
    insert_payment_notes(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  読替エラーログ出力処理 (A-9)
    -- =====================================================
    put_log_error(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 正常件数の設定
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
--
    -- 読替エラーがある場合、警告終了
    IF gn_error_cnt > 0 THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode       OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_filename   IN      VARCHAR2          --    支払通知データファイル名
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_filename   -- 支払通知データファイル名
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --１行改行
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => '' --ユーザー・エラーメッセージ
      );
    END IF;
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR004A01C;
/
