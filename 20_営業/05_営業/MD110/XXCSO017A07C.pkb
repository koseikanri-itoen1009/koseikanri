CREATE OR REPLACE PACKAGE BODY XXCSO017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO017A07C(body)
 * Description      : 見積書アップロード
 * MD.050           : 見積書アップロード MD050_CSO_017_A07
 * Version          : 1.1
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      初期処理(A-1)
 *  get_upload_data           ファイルアップロードIFデータ抽出(A-2)
 *  get_check_spec            入力データチェック仕様取得(A-3)
 *  fnc_check_data            入力データチェック処理(A-3)
 *  check_input_data          入力データチェック(A-3)
 *  insert_quote_upload_work  見積書アップロード中間テーブル登録(A-4)
 *  get_business_check_spec   業務チェック仕様取得(A-6)
 *  calc_below_cost           原価割れ計算(A-6)
 *  calc_margin               マージン計算(A-6)
 *  business_data_check       業務エラーチェック(A-6)
 *  insert_quote_header       見積ヘッダ登録(A-7)
 *  insert_quote_line         見積明細登録(A-7)
 *  create_quote_data         見積データ作成(A-7)
 *  delete_file_ul_if         ファイルアップロードIFデータ削除(A-8)
 *  delete_quote_upload_work  見積書アップロード中間テーブルデータ削除(A-9)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/01/26    1.0   Y.Horikawa       新規作成
 *  2012/06/20    1.1   K.Kiriu          [T4障害]見積区分のチェック修正
 *
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  global_lock_expt                EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCSO017A07C'; -- パッケージ名
--
  cv_app_name                         CONSTANT VARCHAR2(30) := 'XXCSO';  --アプリケーション短縮名
--
  -- メッセージ
  cv_msg_err_get_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00554';  -- データ抽出エラー
  cv_msg_file_id                      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00271';  -- ファイルID
  cv_msg_fmt_ptn                      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00275';  -- フォーマットパターン
  cv_msg_file_ul_name                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_msg_file_name                    CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00152';  -- CSVファイル名
  cv_msg_param_required               CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00325';  -- パラメータ必須エラー
  cv_msg_err_get_proc_date            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_err_get_data_ul              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00274';  -- ファイルアップロード名称抽出エラー
  cv_msg_err_get_lock                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00278';  -- ロックエラー
  cv_msg_err_get_profile              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_msg_err_no_data                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00399';  -- 対象件数0件メッセージ
  cv_msg_err_file_fmt                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00620';  -- 見積CSVフォーマットエラー
  cv_msg_err_required                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00403';  -- 必須項目エラー（複数行）
  cv_msg_err_invalid                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00622';  -- 型・桁数チェックエラーメッセージ
  cv_msg_err_below_cost               CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00626';  -- 原価割れチェックエラー（通常）
  cv_msg_err_below_cost_sp            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00627';  -- 原価割れチェックエラー（特売）
  cv_msg_err_data_div_check           CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00621';  -- データ区分チェックエラー
  cv_msg_err_del_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00270';  -- データ削除エラー
  cv_msg_err_inc_num                  CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00625';  -- 入数エラー
  cv_msg_err_input_check              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00623';  -- 入力チェックエラー
  cv_msg_err_ins_data                 CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00471';  -- データ登録エラー
  cv_msg_err_margin_rate              CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00633';  -- マージン率チェックエラー
  cv_msg_err_param_valuel             CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00252';  -- パラメータ妥当性チェックエラー
  cv_msg_err_quote_enable_start       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00630';  -- 見積期間（開始日）有効チェックエラー
  cv_msg_err_quote_enable_end         CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00631';  -- 見積期間（終了日）有効チェックエラー（通常）
  cv_msg_err_quote_enable_end_sp      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00632';  -- 見積期間（終了日）有効チェックエラー（特売）
  cv_msg_err_this_time_price_no       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00628';  -- 今回価格入力不可エラー
  cv_msg_err_this_time_price_req      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00629';  -- 今回価格入力要エラー
  cv_msg_create_quote_sale            CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00634';  -- 見積作成メッセージ（販売先）
  cv_msg_create_quote_sale_wh         CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00635';  -- 見積作成メッセージ（販売先＋帳合問屋）
  cv_msg_err_unavailable_cust_cd      CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00624';  -- 顧客コード利用不可エラー
  cv_msg_err_invld_negative_num       CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00410';  -- マイナスチェックエラー
  cv_msg_err_qt_ul_not_allowed        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00637';  -- 見積CSVアップロード不可エラーメッセージ
  cv_msg_err_too_many_data_div        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00636';  -- データ区分複数種類指定エラーメッセージ
  cv_msg_err_profile_data_type        CONSTANT VARCHAR2(30) := 'APP-XXCSO1-00121';  -- プロファイルデータ型エラーメッセージ
--
  --メッセージトークン
  cv_tkn_param_name         CONSTANT VARCHAR2(30) := 'PARAM_NAME';
  cv_tkn_file_id            CONSTANT VARCHAR2(30) := 'FILE_ID';
  cv_tkn_table              CONSTANT VARCHAR2(30) := 'TABLE';
  cv_tkn_err_msg            CONSTANT VARCHAR2(30) := 'ERR_MSG';
  cv_tkn_index              CONSTANT VARCHAR2(30) := 'INDEX';
  cv_tkn_column             CONSTANT VARCHAR2(30) := 'COLUMN';
  cv_tkn_fmt_ptn            CONSTANT VARCHAR2(30) := 'FORMAT_PATTERN';
  cv_tkn_file_ul_name       CONSTANT VARCHAR2(30) := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name          CONSTANT VARCHAR2(30) := 'CSV_FILE_NAME';
  cv_tkn_action             CONSTANT VARCHAR2(30) := 'ACTION';
  cv_tkn_col_val1           CONSTANT VARCHAR2(30) := 'COL_VAL1';
  cv_tkn_col_val2           CONSTANT VARCHAR2(30) := 'COL_VAL2';
  cv_tkn_col_val3           CONSTANT VARCHAR2(30) := 'COL_VAL3';
  cv_tkn_col1               CONSTANT VARCHAR2(30) := 'COL1';
  cv_tkn_col2               CONSTANT VARCHAR2(30) := 'COL2';
  cv_tkn_col3               CONSTANT VARCHAR2(30) := 'COL3';
  cv_tkn_data_div_val       CONSTANT VARCHAR2(30) := 'DATA_DIV_VAL';
  cv_tkn_day                CONSTANT VARCHAR2(30) := 'DAY';
  cv_tkn_emp_num            CONSTANT VARCHAR2(30) := 'EMP_NUM';
  cv_tkn_error_message      CONSTANT VARCHAR2(30) := 'ERROR_MESSAGE';
  cv_tkn_item               CONSTANT VARCHAR2(30) := 'ITEM';
  cv_tkn_margin_rate        CONSTANT VARCHAR2(30) := 'MARGIN_RATE';
  cv_tkn_num                CONSTANT VARCHAR2(30) := 'NUM';
  cv_tkn_profile_name       CONSTANT VARCHAR2(30) := 'PROF_NAME';
  cv_tkn_profile_value      CONSTANT VARCHAR2(30) := 'PROF_VALUE';
  cv_tkn_quote_div          CONSTANT VARCHAR2(30) := 'QUOTE_DIV';
  cv_tkn_quote_num          CONSTANT VARCHAR2(30) := 'QUOTE_NUM';
  cv_tkn_quote_num1         CONSTANT VARCHAR2(30) := 'QUOTE_NUM1';
  cv_tkn_quote_num2         CONSTANT VARCHAR2(30) := 'QUOTE_NUM2';
--
  -- トークン値
  cv_tbl_nm_file_ul_if      CONSTANT VARCHAR2(50) := 'ファイルアップロードIF';
  cv_tbl_nm_emp_v           CONSTANT VARCHAR2(50) := '従業員マスタ（最新）ビュー';
  cv_tbl_nm_quote_ul_work   CONSTANT VARCHAR2(50) := '見積書アップロード中間';
  cv_tbl_nm_tax_rate        CONSTANT VARCHAR2(50) := '見積用仮払税率取得ビュー';
  cv_tbl_nm_quote_header    CONSTANT VARCHAR2(50) := '見積ヘッダ';
  cv_tbl_nm_quote_line      CONSTANT VARCHAR2(50) := '見積明細';
  cv_prof_nm_period_day     CONSTANT VARCHAR2(50) := 'XXCSO:見積期間(開始日)の有効範囲';
  cv_prof_nm_margin_rate    CONSTANT VARCHAR2(50) := 'XXCSO:異常マージン率';
  cv_input_param_nm_file_id CONSTANT VARCHAR2(50) := 'ファイルID';
  cv_input_param_nm_fmt_ptn CONSTANT VARCHAR2(50) := 'フォーマットパターン';
--
  cv_profile_period_day     CONSTANT VARCHAR2(50) := 'XXCSO1_PERIOD_DAY_017_A01';  -- XXCSO:見積期間(開始日)の有効範囲
  cv_profile_margin_rate    CONSTANT VARCHAR2(50) := 'XXCSO1_ERR_MARGIN_RATE';     -- XXCSO:異常マージン率
  cv_lkup_file_ul_obj       CONSTANT VARCHAR2(50) := 'XXCCP1_FILE_UPLOAD_OBJ';     -- 参照タイプ：ファイルアップロードOBJ
  cv_lkup_tax_type          CONSTANT VARCHAR2(50) := 'XXCSO1_TAX_DIVISION';        -- 参照タイプ：税区分（営業）
  cv_lkup_unit_price_div    CONSTANT VARCHAR2(50) := 'XXCSO1_UNIT_PRICE_DIVISION'; -- 参照タイプ：単価区分
  cv_lkup_quote_div         CONSTANT VARCHAR2(50) := 'XXCSO1_QUOTE_DIVISION';      -- 参照タイプ：見積区分
--
  cv_fmt_ptn_ul_sale_only     CONSTANT VARCHAR2(10):= '660';  -- フォーマットパターン：見積書アップロード（販売先用）
  cv_data_div_sale_warehouse  CONSTANT VARCHAR2(1) := '0';  -- データ区分：販売先＋帳合問屋
  cv_data_div_sale_only       CONSTANT VARCHAR2(1) := '1';  -- データ区分：販売先
--
  cv_torihiki_form_tonya      CONSTANT VARCHAR2(1) := '2';  -- 取引形態（帳合問屋）
--
  cv_price_inc_tax            CONSTANT VARCHAR2(1) := '2';  -- 税込価格
--
  cv_cust_class_cust          CONSTANT VARCHAR2(2) := '10'; -- 顧客タイプ：顧客
  cv_cust_class_tonya         CONSTANT VARCHAR2(2) := '16'; -- 顧客タイプ：帳合問屋
--
  cv_cust_stat_mc             CONSTANT VARCHAR2(2) := '20'; -- 顧客ステータス：MC
  cv_cust_stat_sp             CONSTANT VARCHAR2(2) := '25'; -- 顧客ステータス：SP
  cv_cust_stat_approved       CONSTANT VARCHAR2(2) := '30'; -- 顧客ステータス：承認済み
  cv_cust_stat_cust           CONSTANT VARCHAR2(2) := '40'; -- 顧客ステータス：顧客
  cv_cust_stat_pause          CONSTANT VARCHAR2(2) := '50'; -- 顧客ステータス：休止
  cv_cust_stat_stop           CONSTANT VARCHAR2(2) := '90'; -- 顧客ステータス：中止
  cv_cust_stat_other          CONSTANT VARCHAR2(2) := '99'; -- 顧客ステータス：対象外
--
  cv_item_stat_pre_input      CONSTANT VARCHAR2(2) := '20'; -- 品目ステータス：仮登録
  cv_item_stat_reg            CONSTANT VARCHAR2(2) := '30'; -- 品目ステータス：本登録
  cv_item_stat_no_plan        CONSTANT VARCHAR2(2) := '40'; -- 品目ステータス：廃
  cv_item_stat_no_rma         CONSTANT VARCHAR2(2) := '50'; -- 品目ステータス：D'
--
  cv_unit_type_case           CONSTANT VARCHAR2(8) := 'C/S';    -- 単位区分：ケース
  cv_unit_type_bowl           CONSTANT VARCHAR2(8) := 'ボール'; -- 単位区分：ボール
--
  cv_quote_div_normal         CONSTANT VARCHAR2(10) := '通常';  -- 見積区分：通常
  cv_quote_div_special_sale   CONSTANT VARCHAR2(10) := '特売';  -- 見積区分：特売
--
  cv_quote_type_sale          CONSTANT VARCHAR2(1) := '1';  -- 見積タイプ：販売先
  cv_quote_type_warehouse     CONSTANT VARCHAR2(1) := '2';  -- 見積タイプ：帳合問屋
  cv_enabled                  CONSTANT VARCHAR2(1) := 'Y';            -- 有効
  cv_date_fmt                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- 日付フォーマット
--
  cn_date_range_normal        CONSTANT NUMBER := 12;  -- 通常見積有効範囲（月）
  cn_date_range_special       CONSTANT NUMBER := 3;   -- 特売見積有効範囲（月）
  cn_after_year               CONSTANT NUMBER := 12;  -- 見積ヘッダ有効範囲（月）
--
  cn_header_rec               CONSTANT NUMBER := 1;  -- CSVファイルヘッダ行
--
  cv_get_num_type_quote       CONSTANT VARCHAR2(1) := '1';  -- 採番タイプ：見積
--
  --CSVファイルの項目位置
  cn_col_pos_data_div                    CONSTANT NUMBER := 1;   -- データ区分
  cn_col_pos_cust_code_warehouse         CONSTANT NUMBER := 2;   -- 顧客（帳合問屋）コード
  cn_col_pos_deliv_place                 CONSTANT NUMBER := 3;   -- 納入場所
  cn_col_pos_payment_condition           CONSTANT NUMBER := 4;   -- 支払条件
  cn_col_pos_store_price_tax             CONSTANT NUMBER := 5;   -- 小売価格税区分
  cn_col_pos_deliv_price_tax             CONSTANT NUMBER := 6;   -- 店納価格税区分
  cn_col_pos_special_note                CONSTANT NUMBER := 7;   -- 特記事項
  cn_col_pos_quote_submit_name           CONSTANT NUMBER := 8;   -- 見積書提出先名
  cn_col_pos_unit_type                   CONSTANT NUMBER := 9;   -- 単価区分
  cn_col_pos_cust_code_sale              CONSTANT NUMBER := 10;  -- 顧客（販売先）コード
  cn_col_pos_item_code                   CONSTANT NUMBER := 11;  -- 商品コード
  cn_col_pos_quote_div                   CONSTANT NUMBER := 12;  -- 見積区分
  cn_col_pos_quotation_price             CONSTANT NUMBER := 13;  -- 建値
  cn_col_pos_sales_discount              CONSTANT NUMBER := 14;  -- 売上値引
  cn_col_pos_usually_deliv_price         CONSTANT NUMBER := 15;  -- 通常店納価格
  cn_col_pos_this_time_dlv_price         CONSTANT NUMBER := 16;  -- 今回店納価格
  cn_col_pos_usuall_net_price            CONSTANT NUMBER := 17;  -- 通常NET価格
  cn_col_pos_this_time_net_price         CONSTANT NUMBER := 18;  -- 今回NET価格
  cn_col_pos_quote_start_date            CONSTANT NUMBER := 19;  -- 期間（開始）
  cn_col_pos_quote_end_date              CONSTANT NUMBER := 20;  -- 期間（終了）
  cn_col_pos_remarks                     CONSTANT NUMBER := 21;  -- 備考
  cn_col_pos_usually_store_sale          CONSTANT NUMBER := 22;  -- 通常店頭売価
  cn_col_pos_this_time_str_sale          CONSTANT NUMBER := 23;  -- 今回店頭売価
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- アップロードデータ分割取得用
  TYPE gt_col_data_ttype    IS TABLE OF VARCHAR(5000) INDEX BY BINARY_INTEGER;      --1次元配列（項目）
  TYPE gt_rec_data_ttype    IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;  --2次元配列（レコード）（項目）
--
  -- 見積作成用データ保持
  TYPE gt_ins_quote_rtype IS RECORD(
    line_no                     xxcso_quote_upload_work.line_no%TYPE,                     -- 行番号
    data_div                    xxcso_quote_upload_work.data_div%TYPE,                    -- データ区分
    cust_code_warehouse         xxcso_quote_upload_work.cust_code_warehouse%TYPE,         -- 顧客（帳合問屋）コード
    deliv_place                 xxcso_quote_upload_work.deliv_place%TYPE,                 -- 納入場所
    payment_condition           xxcso_quote_upload_work.payment_condition%TYPE,           -- 支払条件
    store_price_tax_type        xxcso_quote_upload_work.store_price_tax_type%TYPE,        -- 小売価格税区分
    deliv_price_tax_type        xxcso_quote_upload_work.deliv_price_tax_type%TYPE,        -- 店納価格税区分
    special_note                xxcso_quote_upload_work.special_note%TYPE,                -- 特記事項
    quote_submit_name           xxcso_quote_upload_work.quote_submit_name%TYPE,           -- 見積書提出先名
    unit_type                   xxcso_quote_upload_work.unit_type%TYPE,                   -- 単価区分
    cust_code_sale              xxcso_quote_upload_work.cust_code_sale%TYPE,              -- 顧客（販売先）コード
    item_code                   xxcso_quote_upload_work.item_code%TYPE,                   -- 商品コード
    quote_div                   xxcso_quote_upload_work.quote_div%TYPE,                   -- 見積区分
    quotation_price             xxcso_quote_upload_work.quotation_price%TYPE,             -- 建値
    sales_discount_price        xxcso_quote_upload_work.sales_discount_price%TYPE,        -- 売上値引
    usually_deliv_price         xxcso_quote_upload_work.usually_deliv_price%TYPE,         -- 通常店納価格
    this_time_deliv_price       xxcso_quote_upload_work.this_time_deliv_price%TYPE,       -- 今回店納価格
    usuall_net_price            xxcso_quote_upload_work.usuall_net_price%TYPE,            -- 通常NET価格
    this_time_net_price         xxcso_quote_upload_work.this_time_net_price%TYPE,         -- 今回NET価格
    quote_start_date            xxcso_quote_upload_work.quote_start_date%TYPE,            -- 期間（開始）
    quote_end_date              xxcso_quote_upload_work.quote_end_date%TYPE,              -- 期間（終了）
    remarks                     xxcso_quote_upload_work.remarks%TYPE,                     -- 備考
    usually_store_sale_price    xxcso_quote_upload_work.usually_store_sale_price%TYPE,    -- 通常店頭売価
    this_time_store_sale_price  xxcso_quote_upload_work.this_time_store_sale_price%TYPE,  -- 今回店頭売価
    store_price_tax_type_code   xxcso_quote_headers.store_price_tax_type%TYPE,            -- 小売価格税区分コード
    deliv_price_tax_type_code   xxcso_quote_headers.deliv_price_tax_type%TYPE,            -- 店納価格税区分コード
    unit_type_code              xxcso_quote_headers.unit_type%TYPE,                       -- 単価区分コード
    inventory_item_id           xxcso_quote_lines.inventory_item_id%TYPE,                 -- 品目ID
    quote_div_code              xxcso_quote_lines.quote_div%TYPE,                         -- 見積区分コード
    margin_amt                  xxcso_quote_lines.amount_of_margin%TYPE,                  -- マージン額
    margin_rate                 xxcso_quote_lines.margin_rate%TYPE,                       -- マージン率
    business_price              xxcso_quote_lines.business_price%TYPE                     -- 営業原価
  );
  TYPE gt_ins_quote_data_ttype IS TABLE OF gt_ins_quote_rtype INDEX BY BINARY_INTEGER;
--
  -- 業務チェック実行要否
  TYPE gt_business_check_spec_rtype IS RECORD(
    cust_code_warehouse    BOOLEAN,  -- 顧客（帳合問屋）コード
    store_price_tax_type   BOOLEAN,  -- 小売価格税区分
    deliv_price_tax_type   BOOLEAN,  -- 店納価格税区分
    unit_type              BOOLEAN,  -- 単価区分
    cust_code_sale         BOOLEAN,  -- 顧客（販売先）コード
    item_code              BOOLEAN,  -- 商品コード
    quote_div              BOOLEAN,  -- 見積区分
    usually_deliv_price    BOOLEAN,  -- 通常店納価格
    this_time_deliv_price  BOOLEAN,  -- 今回店納価格
    usuall_net_price       BOOLEAN,  -- 通常NET価格
    this_time_net_price    BOOLEAN,  -- 今回NET価格
    quote_start_date       BOOLEAN,  -- 期間（開始）
    quote_end_date         BOOLEAN,  -- 期間（終了）
    margin_rate            BOOLEAN   -- マージン率
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date  DATE;    -- 業務処理日付
  gn_period_day    NUMBER;  -- 見積期間（開始）の有効範囲
  gn_margin_rate   NUMBER;  -- 異常マージン率
  gv_emp_number    xxcso_employees_v2.employee_number%TYPE;     -- ログイン者の従業員番号
  gv_base_code     xxcso_employees_v2.work_base_code_new%TYPE;  -- ログイン者の所属拠点コード
  gn_tax_rate      xxcso_qt_ap_tax_rate_v.ap_tax_rate%TYPE;     -- 仮払税率
  gv_file_ul_name  fnd_lookup_values.meaning%TYPE;              -- ファイルアップロード名称
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2,  -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.フォーマットパターン
    on_file_id    OUT NUMBER,    -- 3.ファイルID（型変換後）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_msg           VARCHAR2(5000);  --メッセージ
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    ln_file_id       NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ファイルIDメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_id
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                 );
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- フォーマットパターンメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_fmt_ptn
                   ,iv_token_name1  => cv_tkn_fmt_ptn
                   ,iv_token_value1 => iv_fmt_ptn
                 );
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    -- パラメータ．ファイルIDの必須入力チェック
    IF (iv_file_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- パラメータ．ファイルIDの型チェック(数値型に変換できない場合はエラー
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => cv_input_param_nm_file_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    ln_file_id := TO_NUMBER(iv_file_id);
--
    -- パラメータ．フォーマットパターンの必須入力チェック
    IF (iv_fmt_ptn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => cv_input_param_nm_fmt_ptn
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --業務処理日付
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --業務処理日付取得チェック
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      -- ファイルアップロード名称
      SELECT flv.meaning meaning
      INTO   gv_file_ul_name
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type = cv_lkup_file_ul_obj
      AND   flv.lookup_code = iv_fmt_ptn
      AND   flv.language = USERENV('LANG')
      AND   flv.enabled_flag = cv_enabled
      AND   gd_process_date BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ファイルアップロード名称メッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name
                   ,iv_name         => cv_msg_file_ul_name
                   ,iv_token_name1  => cv_tkn_file_ul_name
                   ,iv_token_value1 => TO_CHAR(gv_file_ul_name)
                 );
    -- ファイルアップロード名称メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --CSVファイル名
      SELECT xmfui.file_name file_name
      INTO   lv_file_name
      FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = ln_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSVファイル名メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_file_name
                     ,iv_token_name1  => cv_tkn_file_name
                     ,iv_token_value1 => TO_CHAR(lv_file_name)
                   );
      -- CSVファイル名メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN -- ロック取得失敗
        --ロックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --プロファイルオプション取得
--
    IF (NOT xxcop_common_pkg.chk_number_format(FND_PROFILE.VALUE(cv_profile_period_day))) THEN
      --見積期間（開始）の有効範囲 数値チェック
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_profile_data_type
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_period_day
                     ,iv_token_name2  => cv_tkn_profile_value
                     ,iv_token_value2 => FND_PROFILE.VALUE(cv_profile_period_day)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --見積期間（開始）の有効範囲
    gn_period_day := TO_NUMBER(FND_PROFILE.VALUE(cv_profile_period_day));
    --見積期間（開始）の有効範囲データチェック
    IF (gn_period_day IS NULL) THEN
      --プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_period_day
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (NOT xxcop_common_pkg.chk_number_format(FND_PROFILE.VALUE(cv_profile_margin_rate))) THEN
      --異常マージン率 数値チェック
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_profile_data_type
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_margin_rate
                     ,iv_token_name2  => cv_tkn_profile_value
                     ,iv_token_value2 => FND_PROFILE.VALUE(cv_profile_margin_rate)
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --異常マージン率
    gn_margin_rate := TO_NUMBER(FND_PROFILE.VALUE(cv_profile_margin_rate));
    --異常マージン率データチェック
    IF (gn_margin_rate IS NULL) THEN
      --プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_profile
                     ,iv_token_name1  => cv_tkn_profile_name
                     ,iv_token_value1 => cv_prof_nm_margin_rate
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      --ログイン者情報取得
      SELECT xev.employee_number employee_number
            ,xxcso_util_common_pkg.get_emp_parameter(
                xev.work_base_code_new
               ,xev.work_base_code_old
               ,xev.issue_date
               ,gd_process_date
             ) base_code
      INTO gv_emp_number
          ,gv_base_code
      FROM xxcso_employees_v2 xev
      WHERE xev.user_id = fnd_global.user_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_emp_v
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      --仮払税率
      SELECT xqatrv.ap_tax_rate ap_tax_rate
      INTO gn_tax_rate
      FROM xxcso_qt_ap_tax_rate_v xqatrv
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_tax_rate
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => ln_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    on_file_id := ln_file_id;
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id         IN  NUMBER,             -- 1.ファイルID
    ot_quote_data_tab  OUT gt_rec_data_ttype,  -- 見積データ配列
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    cv_col_separator     CONSTANT VARCHAR2(10) := ',';  -- 項目区切文字
    cn_csv_file_col_num  CONSTANT NUMBER := 23;         -- CSVファイル項目数
--
     -- *** ローカル変数 ***
    ln_col_num     NUMBER;
    ln_line_cnt    NUMBER;
    ln_column_cnt  NUMBER;
--
    -- *** ローカル・レコード ***
    l_file_data_tab         xxccp_common_pkg2.g_file_data_tbl;  -- 行単位データ格納用配列
    l_quote_data_tab        gt_rec_data_ttype;                  -- 見積データ配列
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --データ抽出エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => cv_tbl_nm_file_ul_if
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      --ヘッダ行を除いたデータが0行の場合
      --対象件数0件メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      --対象件数0件メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode := cv_status_warn;
      --データ無しのため以下の処理は行わない。
      RETURN;
    END IF;
--
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --項目数取得
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        --見積CSVフォーマットエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        --見積CSVフォーマットエラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode := cv_status_warn;
      ELSE
        <<column_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割
          l_quote_data_tab(ln_line_cnt)(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(
                                                             iv_char     => l_file_data_tab(ln_line_cnt)
                                                            ,iv_delim    => cv_col_separator
                                                            ,in_part_num => ln_column_cnt
                                                          );
        END LOOP column_loop;
      END IF;
    END LOOP line_loop;
--
    ot_quote_data_tab := l_quote_data_tab;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : get_check_spec
   * Description      : 入力データチェック仕様取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_check_spec(
    in_col_pos         IN  NUMBER,    -- 項目位置
    iv_data_div_val    IN  VARCHAR2,  -- データ区分
    ov_allow_null      OUT VARCHAR2,  -- NULL許可
    ov_data_type       OUT VARCHAR2,  -- データ型
    on_length          OUT NUMBER,    -- 項目長
    on_length_decimal  OUT NUMBER,    -- 項目長（小数点以下）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_check_spec'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    CASE in_col_pos
    WHEN cn_col_pos_data_div THEN
      -- データ区分チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 1;
      on_length_decimal := NULL;
    WHEN cn_col_pos_cust_code_warehouse THEN
       -- 顧客（帳合問屋）コードチェック仕様
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 9;
      on_length_decimal := NULL;
    WHEN cn_col_pos_deliv_place THEN
       -- 納入場所チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_payment_condition THEN
       -- 支払条件チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_store_price_tax THEN
       -- 小売価格税区分チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_deliv_price_tax THEN
       -- 店納価格税区分チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_special_note THEN
       -- 特記事項チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 100;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_submit_name THEN
       -- 見積書提出先名チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 40;
      on_length_decimal := NULL;
    WHEN cn_col_pos_unit_type THEN
       -- 単価区分チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 6;
      on_length_decimal := NULL;
    WHEN cn_col_pos_cust_code_sale THEN
       -- 顧客（販売先）コードチェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 9;
      on_length_decimal := NULL;
    WHEN cn_col_pos_item_code THEN
       -- 商品コードチェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 7;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_div THEN
       -- 見積区分チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 8;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quotation_price THEN
       -- 建値チェック仕様
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_sales_discount THEN
       -- 売上値引チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_usually_deliv_price THEN
       -- 通常店納価格チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_dlv_price THEN
       -- 今回店納価格チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_usuall_net_price THEN
       -- 通常NET価格チェック仕様
      IF (iv_data_div_val = cv_data_div_sale_only) THEN
        ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ELSE
        ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      END IF;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_net_price THEN
       -- 今回NET価格チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 7;
      on_length_decimal := 2;
    WHEN cn_col_pos_quote_start_date THEN
       -- 期間（開始）チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_dat;
      on_length         := 10;
      on_length_decimal := NULL;
    WHEN cn_col_pos_quote_end_date THEN
       -- 期間（終了）チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ng;
      ov_data_type      := xxccp_common_pkg2.gv_attr_dat;
      on_length         := 10;
      on_length_decimal := NULL;
    WHEN cn_col_pos_remarks THEN
       -- 備考チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_vc2;
      on_length         := 20;
      on_length_decimal := NULL;
    WHEN cn_col_pos_usually_store_sale THEN
       -- 通常店頭売価チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 8;
      on_length_decimal := 2;
    WHEN cn_col_pos_this_time_str_sale THEN
       -- 今回店頭売価チェック仕様
      ov_allow_null     := xxccp_common_pkg2.gv_null_ok;
      ov_data_type      := xxccp_common_pkg2.gv_attr_num;
      on_length         := 8;
      on_length_decimal := 2;
    END CASE;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : fnc_check_data
   * Description      : 入力データチェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE fnc_check_data(
    in_line_cnt        IN  NUMBER,    -- 行番号
    iv_column          IN  VARCHAR2,  -- 項目名
    iv_col_val         IN  VARCHAR2,  -- 項目値
    iv_allow_null      IN  VARCHAR2,  -- 必須チェック
    iv_data_type       IN  VARCHAR2,  -- データ型
    in_length          IN  NUMBER,    -- 項目長
    in_length_decimal  IN  NUMBER,    -- 項目長（小数点以下）
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'fnc_check_data'; -- プログラム名
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
    lb_invalid_err_flag  BOOLEAN;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lb_invalid_err_flag := FALSE;
--
    IF (iv_allow_null = xxccp_common_pkg2.gv_null_ng) THEN
      -- 必須入力チェック
      IF (iv_col_val IS NULL) THEN
        -- 必須項目エラー（複数行）
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_required
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- 必須項目エラー（複数行）エラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END IF;
--
    IF (iv_col_val IS NOT NULL) THEN
      --属性チェック
      CASE iv_data_type
      WHEN xxccp_common_pkg2.gv_attr_num THEN
        -- 数値型チェック
        IF (NOT xxcop_common_pkg.chk_number_format(iv_col_val)) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      WHEN xxccp_common_pkg2.gv_attr_dat THEN
        -- 日付型チェック
        IF (NOT xxcop_common_pkg.chk_date_format(iv_col_val, cv_date_fmt)) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      ELSE
        NULL;
      END CASE;
--
      --桁数チェック
      IF (NOT lb_invalid_err_flag) THEN
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => iv_column,                     -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => iv_col_val,                    -- 2.項目の値                   -- 任意
          in_item_len     => in_length,                     -- 3.項目の長さ                 -- 必須
          in_item_decimal => in_length_decimal,             -- 4.項目の長さ(小数点以下)     -- 条件付必須
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,  -- 5.必須フラグ                 -- 必須
          iv_item_attr    => iv_data_type,                  -- 6.項目属性                   -- 必須
          ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
          ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          lb_invalid_err_flag := TRUE;
        END IF;
      END IF;
--
      IF (lb_invalid_err_flag) THEN
        -- 型・桁数チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invalid
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- 型・桁数チェックエラーメッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
      IF (NOT lb_invalid_err_flag
        AND iv_data_type = xxccp_common_pkg2.gv_attr_num
        AND TO_NUMBER(iv_col_val) < 0)
      THEN
        -- 数値の場合、負数はエラー
        -- 数値の入力値チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_invld_negative_num
                       ,iv_token_name1  => cv_tkn_column
                       ,iv_token_value1 => iv_column
                       ,iv_token_name2  => cv_tkn_index
                       ,iv_token_value2 => in_line_cnt
                     );
        -- メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
    END IF;
--
  EXCEPTION
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
  END fnc_check_data;
--
  /**********************************************************************************
   * Procedure Name   : check_input_data
   * Description      : 入力データチェック(A-3)
   ***********************************************************************************/
  PROCEDURE check_input_data(
    iv_fmt_ptn         IN  VARCHAR2,           -- フォーマットパターン
    it_quote_data_tab  IN  gt_rec_data_ttype,  -- 見積データ配列
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_input_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_line_cnt               NUMBER;
    ln_col_cnt                NUMBER;
    lv_allow_null             VARCHAR2(30);
    lv_data_type              VARCHAR2(30);
    ln_length                 NUMBER;
    ln_length_decimal         NUMBER;
    lv_frst_rec_data_div_val  VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<chk_line_loop>>
    FOR ln_line_cnt IN 2 .. it_quote_data_tab.COUNT LOOP
      <<chk_col_loop>>
      FOR ln_col_cnt IN 1 .. it_quote_data_tab(ln_line_cnt).COUNT LOOP
        -- 項目チェック仕様（必須・型・桁数）取得
        get_check_spec(
          ln_col_cnt,
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_data_div),
          lv_allow_null,
          lv_data_type,
          ln_length,
          ln_length_decimal,
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- チェック処理
        fnc_check_data(
          ln_line_cnt - 1,
          it_quote_data_tab(cn_header_rec)(ln_col_cnt),
          it_quote_data_tab(ln_line_cnt)(ln_col_cnt),
          lv_allow_null,
          lv_data_type,
          ln_length,
          ln_length_decimal,
          lv_errbuf,
          lv_retcode,
          lv_errmsg
        );
        IF (lv_retcode = cv_status_warn) THEN
          ov_retcode := lv_retcode;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        IF (ln_col_cnt = cn_col_pos_data_div) THEN
          -- データ区分は、値の内容もチェック
          IF (it_quote_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_data_div_sale_only
            AND  it_quote_data_tab(ln_line_cnt)(ln_col_cnt) <> cv_data_div_sale_warehouse)
          THEN
            -- データ区分チェックエラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_data_div_check
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt - 1
                          );
            -- データ区分チェックエラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := lv_retcode;
          END IF;
--
          IF (iv_fmt_ptn = cv_fmt_ptn_ul_sale_only
            AND it_quote_data_tab(ln_line_cnt)(ln_col_cnt) = cv_data_div_sale_warehouse)
          THEN
            -- 見積書アップロード（販売先）から実行した場合、データ区分0（販売先＋帳合問屋）はエラー
            -- 見積CSVアップロード不可エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_qt_ul_not_allowed
                            ,iv_token_name1  => cv_tkn_file_ul_name
                            ,iv_token_value1 => gv_file_ul_name
                            ,iv_token_name2  => cv_tkn_data_div_val
                            ,iv_token_value2 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name3  => cv_tkn_index
                            ,iv_token_value3 => ln_line_cnt - 1
                          );
            -- 見積CSVアップロード不可エラーメッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
          IF (ln_line_cnt = 2) THEN
            -- データ区分値の混在チェック用に最初の値を保持
            lv_frst_rec_data_div_val := it_quote_data_tab(ln_line_cnt)(ln_col_cnt);
          END IF;
          IF (lv_frst_rec_data_div_val <> it_quote_data_tab(ln_line_cnt)(ln_col_cnt)) THEN
            -- アップロードされたファイル内にデータ区分値が複数存在する場合はエラー
            -- データ区分複数種類指定エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                            ,iv_name         => cv_msg_err_too_many_data_div
                            ,iv_token_name1  => cv_tkn_data_div_val
                            ,iv_token_value1 => it_quote_data_tab(ln_line_cnt)(ln_col_cnt)
                            ,iv_token_name2  => cv_tkn_index
                            ,iv_token_value2 => ln_line_cnt -1
                          );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END LOOP chk_col_loop;
    END LOOP chk_line_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END check_input_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_upload_work
   * Description      : 見積書アップロード中間テーブル登録(A-4)
   ***********************************************************************************/
  PROCEDURE insert_quote_upload_work(
    in_file_id         IN  NUMBER,             -- ファイルID
    it_quote_data_tab  IN  gt_rec_data_ttype,  -- 見積データ配列
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_upload_work'; -- プログラム名
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
    ln_line_cnt  NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<ins_line_loop>>
    FOR ln_line_cnt IN 2 .. it_quote_data_tab.COUNT LOOP
      BEGIN
        INSERT INTO xxcso_quote_upload_work(
          file_id,
          line_no,
          data_div,
          cust_code_warehouse,
          deliv_place,
          payment_condition,
          store_price_tax_type,
          deliv_price_tax_type,
          special_note,
          quote_submit_name,
          unit_type,
          cust_code_sale,
          item_code,
          quote_div,
          quotation_price,
          sales_discount_price,
          usually_deliv_price,
          this_time_deliv_price,
          usuall_net_price,
          this_time_net_price,
          quote_start_date,
          quote_end_date,
          remarks,
          usually_store_sale_price,
          this_time_store_sale_price,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          last_update_login,
          request_id,
          program_application_id,
          program_id,
          program_update_date
        ) VALUES (
          in_file_id,
          ln_line_cnt - 1,
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_data_div),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_cust_code_warehouse),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_deliv_place),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_payment_condition),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_store_price_tax),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_deliv_price_tax),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_special_note),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_submit_name),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_unit_type),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_cust_code_sale),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_item_code),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_div),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quotation_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_sales_discount)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usually_deliv_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_dlv_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usuall_net_price)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_net_price)),
          TO_DATE(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_start_date), cv_date_fmt),
          TO_DATE(it_quote_data_tab(ln_line_cnt)(cn_col_pos_quote_end_date), cv_date_fmt),
          it_quote_data_tab(ln_line_cnt)(cn_col_pos_remarks),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_usually_store_sale)),
          TO_NUMBER(it_quote_data_tab(ln_line_cnt)(cn_col_pos_this_time_str_sale)),
          cn_created_by,
          cd_creation_date,
          cn_last_updated_by,
          cd_last_update_date,
          cn_last_update_login,
          cn_request_id,
          cn_program_application_id,
          cn_program_id,
          cd_program_update_date
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- データ登録エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_ins_data
                         ,iv_token_name1  => cv_tkn_action
                         ,iv_token_value1 => cv_tbl_nm_quote_ul_work
                         ,iv_token_name2  => cv_tkn_error_message
                         ,iv_token_value2 => SQLERRM
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP ins_line_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END insert_quote_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : get_business_check_spec
   * Description      : 業務チェック仕様取得(A-6)
   ***********************************************************************************/
  PROCEDURE get_business_check_spec(
    iv_data_div             IN  NUMBER,                        -- データ区分
    ot_business_check_spec  OUT gt_business_check_spec_rtype,  -- 業務チェック仕様
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_business_check_spec'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 項目チェック要否の設定
    -- 顧客（帳合問屋）コード
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.cust_code_warehouse   := FALSE;
    ELSE
      ot_business_check_spec.cust_code_warehouse   := TRUE;
    END IF;
    -- 小売価格税区分
    ot_business_check_spec.store_price_tax_type  := TRUE;
    -- 店納価格税区分
    ot_business_check_spec.deliv_price_tax_type  := TRUE;
    -- 単価区分
    ot_business_check_spec.unit_type             := TRUE;
    -- 顧客（販売先）コード
    ot_business_check_spec.cust_code_sale        := TRUE;
    -- 商品コード
    ot_business_check_spec.item_code             := TRUE;
    -- 見積区分
    ot_business_check_spec.quote_div             := TRUE;
    -- 通常店納価格
    ot_business_check_spec.usually_deliv_price   := TRUE;
    -- 今回店納価格
    ot_business_check_spec.this_time_deliv_price := TRUE;
    -- 通常NET価格
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.usuall_net_price      := FALSE;
    ELSE
      ot_business_check_spec.usuall_net_price      := TRUE;
    END IF;
    -- 今回NET価格
    IF (iv_data_div = cv_data_div_sale_only) THEN
      ot_business_check_spec.this_time_net_price   := FALSE;
    ELSE
      ot_business_check_spec.this_time_net_price   := TRUE;
    END IF;
    -- 期間（開始）
    ot_business_check_spec.quote_start_date      := TRUE;
    -- 期間（終了）
    ot_business_check_spec.quote_end_date        := TRUE;
    -- マージン率
    IF (iv_data_div =cv_data_div_sale_only) THEN
      ot_business_check_spec.margin_rate           := FALSE;
    ELSE
      ot_business_check_spec.margin_rate           := TRUE;
    END IF;
--
  EXCEPTION
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
  END get_business_check_spec;
--
  /**********************************************************************************
   * Procedure Name   : calc_below_cost
   * Description      : 原価割れ計算(A-6)
   ***********************************************************************************/
  PROCEDURE calc_below_cost(
    in_price      IN  NUMBER,  -- 価格
    in_inc_num    IN  NUMBER,  -- 入数
    in_cost       IN  NUMBER,  -- 営業原価
    in_tax_rate   IN  NUMBER,  -- 仮払税率
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_below_cost'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (in_cost IS NOT NULL) THEN
      IF (in_price / NVL(in_inc_num, 1) <= in_cost * in_tax_rate) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
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
  END calc_below_cost;
--
  /**********************************************************************************
   * Procedure Name   : calc_margin
   * Description      : マージン計算(A-6)
   ***********************************************************************************/
  PROCEDURE calc_margin(
    in_deliv_price  IN  NUMBER,  -- 店納価格
    in_net_price    IN  NUMBER,  -- NET価格
    in_inc_num      IN  NUMBER,  -- 入数
    on_margin_amt   OUT NUMBER,  -- マージン額
    on_margin_rate  OUT NUMBER,  -- マージン率
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_margin'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル定数 ***
    cn_max_margin_rate         CONSTANT NUMBER := 100;
    cn_min_margin_rate         CONSTANT NUMBER := -100;
    cn_replace_max_margin_rate CONSTANT NUMBER := 99.99;
    cn_replace_min_margin_rate CONSTANT NUMBER := -99.99;
    -- *** ローカル変数 ***
    ln_margin_amt  NUMBER;
    ln_margin_rate NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- マージ額
    ln_margin_amt := ROUND(in_deliv_price / in_inc_num, 2) - ROUND(in_net_price / in_inc_num, 2);
    -- マージン率
    ln_margin_rate := ROUND(ROUND(ln_margin_amt / ROUND(in_deliv_price / in_inc_num, 2), 6) * 100, 2);
--
    IF (ln_margin_rate > cn_max_margin_rate) THEN
      -- マージン率（最大値へ置き換え）
      ln_margin_rate := cn_replace_max_margin_rate;
    END IF;
    IF (ln_margin_rate < cn_min_margin_rate) THEN
      -- マージン率（最小値へ置き換え）
      ln_margin_rate := cn_replace_min_margin_rate;
    END IF;
--
    on_margin_amt := ln_margin_amt;
    on_margin_rate := ln_margin_rate;
--
  EXCEPTION
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
  END calc_margin;
--
  /**********************************************************************************
   * Procedure Name   : business_data_check
   * Description      : 業務エラーチェック(A-6)
   ***********************************************************************************/
  PROCEDURE business_data_check(
    in_file_id                 IN  NUMBER,                   -- ファイルID
    it_quote_header_data       IN  gt_col_data_ttype,        -- 見積ファイルヘッダ情報
    ot_for_ins_quote_data_tab  OUT gt_ins_quote_data_ttype,  --見積作成用データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'business_data_check'; -- プログラム名
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
    cn_default_tax_rate        CONSTANT NUMBER := 1;
--
    -- *** ローカル変数 ***
    lt_account_number          xxcso_cust_accounts_v.account_number%TYPE;
    lt_for_ins_quote_data_tab  gt_ins_quote_data_ttype;
    lt_store_price_tax_type    xxcso_quote_headers.store_price_tax_type%TYPE;
    lt_deliv_price_tax_type    xxcso_quote_headers.deliv_price_tax_type%TYPE;
    lt_unit_type               xxcso_quote_headers.unit_type%TYPE;
    lt_quote_div               xxcso_quote_lines.quote_div%TYPE;
    lt_tax_rate                xxcso_qt_ap_tax_rate_v.ap_tax_rate%TYPE;
    ln_inc_num                 NUMBER;
    lt_case_inc_num            xxcso_inventory_items_v2.case_inc_num%TYPE;
    lt_bowl_inc_num            xxcso_inventory_items_v2.bowl_inc_num%TYPE;
    lt_inventory_item_id       xxcso_inventory_items_v2.inventory_item_id%TYPE;
    lt_business_price          xxcso_inventory_items_v2.business_price%TYPE;
    ln_margin_amt              NUMBER;
    ln_margin_rate             NUMBER;
--
    CURSOR get_quote_upload_work_cur
    IS
      SELECT xquw.line_no                     line_no
            ,xquw.data_div                    data_div
            ,xquw.cust_code_warehouse         cust_code_warehouse
            ,xquw.deliv_place                 deliv_place
            ,xquw.payment_condition           payment_condition
            ,xquw.store_price_tax_type        store_price_tax_type
            ,xquw.deliv_price_tax_type        deliv_price_tax_type
            ,xquw.special_note                special_note
            ,xquw.quote_submit_name           quote_submit_name
            ,xquw.unit_type                   unit_type
            ,xquw.cust_code_sale              cust_code_sale
            ,xquw.item_code                   item_code
            ,xquw.quote_div                   quote_div
            ,xquw.quotation_price             quotation_price
            ,xquw.sales_discount_price        sales_discount_price
            ,xquw.usually_deliv_price         usually_deliv_price
            ,xquw.this_time_deliv_price       this_time_deliv_price
            ,xquw.usuall_net_price            usuall_net_price
            ,xquw.this_time_net_price         this_time_net_price
            ,xquw.quote_start_date            quote_start_date
            ,xquw.quote_end_date              quote_end_date
            ,xquw.remarks                     remarks
            ,xquw.usually_store_sale_price    usually_store_sale_price
            ,xquw.this_time_store_sale_price  this_time_store_sale_price
      FROM xxcso_quote_upload_work xquw
      WHERE xquw.file_id = in_file_id
      ORDER BY xquw.cust_code_sale
              ,xquw.cust_code_warehouse
              ,xquw.line_no
      ;
--
    CURSOR get_lookup_code_cur (
      iv_lookup_type  VARCHAR2,
      iv_meaning      VARCHAR2)
    IS
      SELECT flv.lookup_code lookup_code
      FROM fnd_lookup_values flv
      WHERE flv.lookup_type = iv_lookup_type
      AND   flv.meaning = iv_meaning
      AND   flv.language = USERENV('LANG')
      AND   flv.enabled_flag = cv_enabled
      AND   gd_process_date BETWEEN TRUNC(flv.start_date_active) AND NVL(flv.end_date_active, gd_process_date)
      ;
--
    -- *** ローカル・レコード ***
    get_quote_upload_work_rec  get_quote_upload_work_cur%ROWTYPE;
    pre_quote_upload_work_rec  get_quote_upload_work_cur%ROWTYPE;
    lt_business_check_spec     gt_business_check_spec_rtype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<business_data_check_loop>>
    FOR get_quote_upload_work_rec IN get_quote_upload_work_cur LOOP
--
      -- 業務チェックの要否取得
      get_business_check_spec(
         get_quote_upload_work_rec.data_div
        ,lt_business_check_spec
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF (lt_business_check_spec.cust_code_warehouse) THEN
        IF (get_quote_upload_work_rec.cust_code_warehouse <> pre_quote_upload_work_rec.cust_code_warehouse
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.cust_code_warehouse IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          --顧客（帳合問屋）コード
          BEGIN
            SELECT xcav.account_number account_number
            INTO   lt_account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_warehouse
            AND   xcav.torihiki_form = cv_torihiki_form_tonya
            AND   xrcv.employee_number = gv_emp_number
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.cust_code_warehouse := get_quote_upload_work_rec.cust_code_warehouse;
/* 2012/06/20 Ver1.1 Add End   */
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 顧客コード利用不可エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_unavailable_cust_cd
                              ,iv_token_name1  => cv_tkn_emp_num
                              ,iv_token_value1 => gv_emp_number
                              ,iv_token_name2  => cv_tkn_col1
                              ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                              ,iv_token_name3  => cv_tkn_col_val1
                              ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => get_quote_upload_work_rec.line_no
                            );
              -- メッセージ出力
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.store_price_tax_type) THEN
        IF (get_quote_upload_work_rec.store_price_tax_type <> pre_quote_upload_work_rec.store_price_tax_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.store_price_tax_type IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- 初期化
          lt_store_price_tax_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- 小売価格税区分
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_tax_type,
                                       get_quote_upload_work_rec.store_price_tax_type)
          LOOP
            lt_store_price_tax_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_store_price_tax_type IS NULL) THEN
            --入力チェックエラーメッセージ（小売価格税区分）
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_store_price_tax)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_store_price_tax)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.store_price_tax_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.store_price_tax_type := get_quote_upload_work_rec.store_price_tax_type ;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.deliv_price_tax_type) THEN
        IF (get_quote_upload_work_rec.deliv_price_tax_type <> pre_quote_upload_work_rec.deliv_price_tax_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.deliv_price_tax_type IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- 初期化
          lt_deliv_price_tax_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- 店納価格税区分
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_tax_type,
                                       get_quote_upload_work_rec.deliv_price_tax_type)
          LOOP
            lt_deliv_price_tax_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_deliv_price_tax_type IS NULL) THEN
            --入力チェックエラーメッセージ（店納価格税区分）
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_deliv_price_tax)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_deliv_price_tax)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.deliv_price_tax_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.deliv_price_tax_type := get_quote_upload_work_rec.deliv_price_tax_type;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
          -- 仮払税率の決定
          IF (lt_deliv_price_tax_type = cv_price_inc_tax) THEN
            lt_tax_rate := gn_tax_rate;
          ELSE
            lt_tax_rate := cn_default_tax_rate;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.unit_type) THEN
        IF (get_quote_upload_work_rec.unit_type <> pre_quote_upload_work_rec.unit_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.unit_type IS NULL )
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- 初期化
          lt_unit_type := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- 単価区分
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_unit_price_div,
                                       get_quote_upload_work_rec.unit_type)
          LOOP
            lt_unit_type := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_unit_type IS NULL) THEN
            --入力チェックエラーメッセージ（単価区分）
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_unit_type)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_unit_type)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.unit_type
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.unit_type := get_quote_upload_work_rec.unit_type;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.cust_code_sale) THEN
        IF (get_quote_upload_work_rec.cust_code_sale <> pre_quote_upload_work_rec.cust_code_sale
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.cust_code_sale IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          -- 顧客（販売先）コード
          BEGIN
            SELECT xcav.account_number account_number
            INTO lt_account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_sale
            AND   (xcav.customer_class_code = cv_cust_class_cust
              OR   xcav.customer_class_code IS NULL)
            AND   xcav.customer_status IN (cv_cust_stat_mc, cv_cust_stat_sp, cv_cust_stat_approved, cv_cust_stat_cust, cv_cust_stat_pause)
            UNION
            SELECT xcav.account_number account_number
            FROM xxcso_cust_accounts_v xcav,
                 xxcso_resource_custs_v2 xrcv
            WHERE xrcv.account_number = xcav.account_number
            AND   xcav.account_number = get_quote_upload_work_rec.cust_code_sale
            AND   xcav.customer_class_code = cv_cust_class_tonya
            AND   xcav.customer_status IN (cv_cust_stat_stop, cv_cust_stat_other)
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.cust_code_sale := get_quote_upload_work_rec.cust_code_sale;
/* 2012/06/20 Ver1.1 Add End   */
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 顧客コード利用不可エラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name
                              ,iv_name         => cv_msg_err_unavailable_cust_cd
                              ,iv_token_name1  => cv_tkn_emp_num
                              ,iv_token_value1 => gv_emp_number
                              ,iv_token_name2  => cv_tkn_col1
                              ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                              ,iv_token_name3  => cv_tkn_col_val1
                              ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                              ,iv_token_name4  => cv_tkn_index
                              ,iv_token_value4 => get_quote_upload_work_rec.line_no
                            );
              -- メッセージ出力
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.item_code) THEN
        IF (get_quote_upload_work_rec.item_code <> pre_quote_upload_work_rec.item_code
          OR get_quote_upload_work_rec.unit_type <> pre_quote_upload_work_rec.unit_type
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.item_code IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
          -- 商品コード
          BEGIN
            SELECT xiiv.inventory_item_id inventory_item_id,
                   xiiv.case_inc_num case_inc_num,
                   xiiv.bowl_inc_num bowl_inc_num,
                   xiiv.business_price business_price
            INTO lt_inventory_item_id,
                 lt_case_inc_num,
                 lt_bowl_inc_num,
                 lt_business_price
            FROM xxcso_inventory_items_v2 xiiv
            WHERE xiiv.inventory_item_code = get_quote_upload_work_rec.item_code
            AND   xiiv.item_status IN (cv_item_stat_pre_input, cv_item_stat_reg, cv_item_stat_no_plan, cv_item_stat_no_rma)
            ;
/* 2012/06/20 Ver1.1 Add Start */
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.item_code := get_quote_upload_work_rec.item_code;
/* 2012/06/20 Ver1.1 Add End   */
  --
            -- 入数チェック
            IF (get_quote_upload_work_rec.unit_type = cv_unit_type_case) THEN
              ln_inc_num := lt_case_inc_num;
            ELSIF (get_quote_upload_work_rec.unit_type = cv_unit_type_bowl) THEN
              ln_inc_num := lt_bowl_inc_num;
            ELSE
              ln_inc_num := 1;
            END IF;
  --
            IF (NVL(ln_inc_num, 0) = 0 ) THEN
              -- 入数チェックエラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name
                             ,iv_name         => cv_msg_err_inc_num
                             ,iv_token_name1  => cv_tkn_col1
                             ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                             ,iv_token_name2  => cv_tkn_col_val1
                             ,iv_token_value2 => get_quote_upload_work_rec.cust_code_sale
                             ,iv_token_name3  => cv_tkn_col2
                             ,iv_token_value3 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name4  => cv_tkn_col_val2
                             ,iv_token_value4 => get_quote_upload_work_rec.item_code
                             ,iv_token_name5  => cv_tkn_col3
                             ,iv_token_value5 => it_quote_header_data(cn_col_pos_unit_type)
                             ,iv_token_name6  => cv_tkn_col_val3
                             ,iv_token_value6 => get_quote_upload_work_rec.unit_type
                             ,iv_token_name7  => cv_tkn_index
                             ,iv_token_value7 => get_quote_upload_work_rec.line_no
                           );
                -- メッセージ出力
                fnd_file.put_line(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 入力チェックエラーメッセージ
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name
                             ,iv_name         => cv_msg_err_input_check
                             ,iv_token_name1  => cv_tkn_column
                             ,iv_token_value1 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name2  => cv_tkn_col1
                             ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                             ,iv_token_name3  => cv_tkn_col_val1
                             ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                             ,iv_token_name4  => cv_tkn_col2
                             ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                             ,iv_token_name5  => cv_tkn_col_val2
                             ,iv_token_value5 => get_quote_upload_work_rec.item_code
                             ,iv_token_name6  => cv_tkn_index
                             ,iv_token_value6 => get_quote_upload_work_rec.line_no
                           );
              -- メッセージ出力
              fnd_file.put_line(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--
              gn_warn_cnt := gn_warn_cnt + 1;
              ov_retcode := cv_status_warn;
            WHEN OTHERS THEN
              RAISE;
          END;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_div) THEN
        IF (get_quote_upload_work_rec.quote_div <> pre_quote_upload_work_rec.quote_div
/* 2012/06/20 Ver1.1 Mod Start */
--          OR get_quote_upload_work_cur%ROWCOUNT = 1)
          OR pre_quote_upload_work_rec.quote_div IS NULL)
/* 2012/06/20 Ver1.1 Mod End   */
        THEN
/* 2012/06/20 Ver1.1 Add Start */
          -- 初期化
          lt_quote_div := NULL;
/* 2012/06/20 Ver1.1 Add End   */
          -- 見積区分
          FOR get_lookup_code_rec IN get_lookup_code_cur(
                                       cv_lkup_quote_div,
                                       get_quote_upload_work_rec.quote_div)
          LOOP
            lt_quote_div := get_lookup_code_rec.lookup_code;
            EXIT;
          END LOOP;
          IF (lt_quote_div IS NULL) THEN
            --入力チェックエラーメッセージ（見積区分）
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_input_check
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_quote_div)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
/* 2012/06/20 Ver1.1 Add Start */
          ELSE
            --チェックOKとなったデータを保持
            pre_quote_upload_work_rec.quote_div := get_quote_upload_work_rec.quote_div;
/* 2012/06/20 Ver1.1 Add End   */
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.usually_deliv_price) THEN
        -- 通常店納価格
        IF (get_quote_upload_work_rec.quote_div IN(cv_quote_div_normal, cv_quote_div_special_sale)) THEN
          -- 原価割れチェック
          calc_below_cost(
             get_quote_upload_work_rec.usually_deliv_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usually_deliv_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.this_time_deliv_price) THEN
        -- 今回店納価格
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_deliv_price IS NOT NULL)
        THEN
          -- 今回価格入力不可メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_no
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
--
        IF (get_quote_upload_work_rec.quote_div <> cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_deliv_price IS NULL)
        THEN
          -- 今回価格入力必要メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_req
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
--
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_special_sale) THEN
          -- 原価割れチェック
          calc_below_cost(
             get_quote_upload_work_rec.this_time_deliv_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost_sp
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_deliv_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.usuall_net_price) THEN
        -- 通常NET価格
        IF (get_quote_upload_work_rec.quote_div IN(cv_quote_div_normal, cv_quote_div_special_sale)) THEN
            -- 原価割れチェック
          calc_below_cost(
             get_quote_upload_work_rec.usuall_net_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usuall_net_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.this_time_net_price) THEN
        -- 今回NET価格
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_net_price IS NOT NULL)
        THEN
          -- 今回価格入力不可メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_no
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
  --
        IF (get_quote_upload_work_rec.quote_div <> cv_quote_div_normal
          AND get_quote_upload_work_rec.this_time_net_price IS NULL)
        THEN
          -- 今回価格入力要メッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_this_time_price_req
                         ,iv_token_name1  => cv_tkn_column
                         ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_quote_div)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.quote_div
                         ,iv_token_name6  => cv_tkn_index
                         ,iv_token_value6 => get_quote_upload_work_rec.line_no
                       );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
  --
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_special_sale) THEN
          -- 原価割れチェック
          calc_below_cost(
             get_quote_upload_work_rec.this_time_net_price
            ,ln_inc_num
            ,lt_business_price
            ,lt_tax_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_below_cost_sp
                           ,iv_token_name1  => cv_tkn_column
                           ,iv_token_value1 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_net_price
                           ,iv_token_name8  => cv_tkn_index
                           ,iv_token_value8 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_start_date) THEN
        -- 期間（開始）
        IF (get_quote_upload_work_rec.quote_start_date < gd_process_date - gn_period_day) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_err_quote_enable_start
                         ,iv_token_name1  => cv_tkn_day
                         ,iv_token_value1 => gn_period_day
                         ,iv_token_name2  => cv_tkn_col1
                         ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                         ,iv_token_name3  => cv_tkn_col_val1
                         ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                         ,iv_token_name4  => cv_tkn_col2
                         ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                         ,iv_token_name5  => cv_tkn_col_val2
                         ,iv_token_value5 => get_quote_upload_work_rec.item_code
                         ,iv_token_name6  => cv_tkn_col3
                         ,iv_token_value6 => it_quote_header_data(cn_col_pos_quote_start_date)
                         ,iv_token_name7  => cv_tkn_col_val3
                         ,iv_token_value7 => get_quote_upload_work_rec.quote_start_date
                         ,iv_token_name8  => cv_tkn_index
                         ,iv_token_value8 => get_quote_upload_work_rec.line_no
                       );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
--
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.quote_end_date) THEN
        -- 期間（終了）
        IF (get_quote_upload_work_rec.quote_div = cv_quote_div_normal) THEN
          IF (get_quote_upload_work_rec.quote_end_date > ADD_MONTHS(get_quote_upload_work_rec.quote_start_date, cn_date_range_normal)
            OR get_quote_upload_work_rec.quote_end_date < get_quote_upload_work_rec.quote_start_date)
          THEN
            -- 期間（開始） <= 期間（終了） <= 期間（開始）の1年後 とならない場合はエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_quote_enable_end
                           ,iv_token_name1  => cv_tkn_quote_div
                           ,iv_token_value1 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        ELSE
          IF (get_quote_upload_work_rec.quote_end_date > ADD_MONTHS(get_quote_upload_work_rec.quote_start_date, cn_date_range_special)
            OR get_quote_upload_work_rec.quote_end_date < get_quote_upload_work_rec.quote_start_date)
          THEN
            -- 期間（開始） <= 期間（終了） <= 期間（開始）の3ヶ月後 とならない場合はエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_quote_enable_end_sp
                           ,iv_token_name1  => cv_tkn_quote_div
                           ,iv_token_value1 => get_quote_upload_work_rec.quote_div
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_sale)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_sale
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_item_code)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.item_code
                           ,iv_token_name6  => cv_tkn_index
                           ,iv_token_value6 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
      IF (lt_business_check_spec.margin_rate) THEN
        -- マージン率
        IF (get_quote_upload_work_rec.this_time_deliv_price IS NULL) THEN
          -- マージン計算
          calc_margin(
             get_quote_upload_work_rec.usually_deliv_price
            ,get_quote_upload_work_rec.usuall_net_price
            ,ln_inc_num
            ,ln_margin_amt
            ,ln_margin_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          IF (ln_margin_rate >= gn_margin_rate) THEN
            -- 異常マージン率メッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_margin_rate
                           ,iv_token_name1  => cv_tkn_margin_rate
                           ,iv_token_value1 => gn_margin_rate
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_usually_deliv_price)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.usually_deliv_price
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_usuall_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.usuall_net_price
                           ,iv_token_name8  => cv_tkn_num
                           ,iv_token_value8 => ln_inc_num
                           ,iv_token_name9  => cv_tkn_index
                           ,iv_token_value9 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        ELSE
          -- マージン計算
          calc_margin(
             get_quote_upload_work_rec.this_time_deliv_price
            ,get_quote_upload_work_rec.this_time_net_price
            ,ln_inc_num
            ,ln_margin_amt
            ,ln_margin_rate
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          IF (ln_margin_rate >= gn_margin_rate) THEN
            -- 異常マージン率メッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_err_margin_rate
                           ,iv_token_name1  => cv_tkn_margin_rate
                           ,iv_token_value1 => gn_margin_rate
                           ,iv_token_name2  => cv_tkn_col1
                           ,iv_token_value2 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                           ,iv_token_name3  => cv_tkn_col_val1
                           ,iv_token_value3 => get_quote_upload_work_rec.cust_code_warehouse
                           ,iv_token_name4  => cv_tkn_col2
                           ,iv_token_value4 => it_quote_header_data(cn_col_pos_this_time_dlv_price)
                           ,iv_token_name5  => cv_tkn_col_val2
                           ,iv_token_value5 => get_quote_upload_work_rec.this_time_deliv_price
                           ,iv_token_name6  => cv_tkn_col3
                           ,iv_token_value6 => it_quote_header_data(cn_col_pos_this_time_net_price)
                           ,iv_token_name7  => cv_tkn_col_val3
                           ,iv_token_value7 => get_quote_upload_work_rec.this_time_net_price
                           ,iv_token_name8  => cv_tkn_num
                           ,iv_token_value8 => ln_inc_num
                           ,iv_token_name9  => cv_tkn_index
                           ,iv_token_value9 => get_quote_upload_work_rec.line_no
                         );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
--
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode := cv_status_warn;
          END IF;
        END IF;
      END IF;
--
/* 2012/06/20 Ver1.1 Del Start */
--      pre_quote_upload_work_rec := get_quote_upload_work_rec;
/* 2012/06/20 Ver1.1 Del End   */
--
      -- 見積作成用データ配列保持
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).line_no                    := get_quote_upload_work_rec.line_no;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).data_div                   := get_quote_upload_work_rec.data_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).cust_code_warehouse        := get_quote_upload_work_rec.cust_code_warehouse;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_place                := get_quote_upload_work_rec.deliv_place;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).payment_condition          := get_quote_upload_work_rec.payment_condition;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).store_price_tax_type       := get_quote_upload_work_rec.store_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_price_tax_type       := get_quote_upload_work_rec.deliv_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).special_note               := get_quote_upload_work_rec.special_note;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_submit_name          := get_quote_upload_work_rec.quote_submit_name;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).unit_type                  := get_quote_upload_work_rec.unit_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).cust_code_sale             := get_quote_upload_work_rec.cust_code_sale;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).item_code                  := get_quote_upload_work_rec.item_code;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_div                  := get_quote_upload_work_rec.quote_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quotation_price            := get_quote_upload_work_rec.quotation_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).sales_discount_price       := get_quote_upload_work_rec.sales_discount_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usually_deliv_price        := get_quote_upload_work_rec.usually_deliv_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_deliv_price      := get_quote_upload_work_rec.this_time_deliv_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usuall_net_price           := get_quote_upload_work_rec.usuall_net_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_net_price        := get_quote_upload_work_rec.this_time_net_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_start_date           := get_quote_upload_work_rec.quote_start_date;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_end_date             := get_quote_upload_work_rec.quote_end_date;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).remarks                    := get_quote_upload_work_rec.remarks;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).usually_store_sale_price   := get_quote_upload_work_rec.usually_store_sale_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).this_time_store_sale_price := get_quote_upload_work_rec.this_time_store_sale_price;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).store_price_tax_type_code  := lt_store_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).deliv_price_tax_type_code  := lt_deliv_price_tax_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).unit_type_code             := lt_unit_type;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).inventory_item_id          := lt_inventory_item_id;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).quote_div_code             := lt_quote_div;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).margin_amt                 := ln_margin_amt;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).margin_rate                := ln_margin_rate;
      ot_for_ins_quote_data_tab(get_quote_upload_work_cur%ROWCOUNT).business_price             := lt_business_price;
    END LOOP;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END business_data_check;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_header
   * Description      : 見積ヘッダ登録(A-7)
   ***********************************************************************************/
  PROCEDURE insert_quote_header(
    iv_quote_type                 IN  VARCHAR2,            -- 見積タイプ
    iv_quote_number               IN  VARCHAR2,            -- 見積番号
    iv_ref_quote_number           IN  VARCHAR2,            -- 参照見積番号
    in_ref_quote_header_id        IN  NUMBER,              -- 参照見積ヘッダID
    it_for_insert_quote_data_rec  IN  gt_ins_quote_rtype,  -- 見積データ作成用配列
    on_quote_header_id            OUT NUMBER,              -- 作成した見積ヘッダID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_header'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル定数 ***
    cv_status_input          CONSTANT VARCHAR2(10) := '1';  -- 見積ステータス：入力済み
    cn_quote_revision_number CONSTANT NUMBER := 1;          -- 版
    -- *** ローカル変数 ***
    lt_account_number        xxcso_quote_headers.account_number%TYPE;
    lt_store_price_tax_type  xxcso_quote_headers.store_price_tax_type%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (iv_quote_type = cv_quote_type_sale) THEN
      lt_account_number := it_for_insert_quote_data_rec.cust_code_sale;
      lt_store_price_tax_type := it_for_insert_quote_data_rec.store_price_tax_type_code;
    ELSIF (iv_quote_type = cv_quote_type_warehouse) THEN
      lt_account_number := it_for_insert_quote_data_rec.cust_code_warehouse;
      lt_store_price_tax_type := NULL;
    END IF;
--
    BEGIN
      INSERT INTO xxcso_quote_headers(
         quote_header_id
        ,quote_type
        ,quote_number
        ,quote_revision_number
        ,reference_quote_number
        ,reference_quote_header_id
        ,publish_date
        ,account_number
        ,employee_number
        ,base_code
        ,deliv_place
        ,payment_condition
        ,quote_submit_name
        ,status
        ,deliv_price_tax_type
        ,store_price_tax_type
        ,unit_type
        ,special_note
        ,quote_info_start_date
        ,quote_info_end_date
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcso_quote_headers_s01.NEXTVAL
        ,iv_quote_type
        ,iv_quote_number
        ,cn_quote_revision_number
        ,iv_ref_quote_number
        ,in_ref_quote_header_id
        ,gd_process_date
        ,lt_account_number
        ,gv_emp_number
        ,gv_base_code
        ,it_for_insert_quote_data_rec.deliv_place
        ,it_for_insert_quote_data_rec.payment_condition
        ,it_for_insert_quote_data_rec.quote_submit_name
        ,cv_status_input
        ,it_for_insert_quote_data_rec.deliv_price_tax_type_code
        ,lt_store_price_tax_type
        ,it_for_insert_quote_data_rec.unit_type_code
        ,it_for_insert_quote_data_rec.special_note
        ,gd_process_date
        ,ADD_MONTHS(gd_process_date, cn_after_year)
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      ) RETURNING quote_header_id INTO on_quote_header_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_ins_data
                       ,iv_token_name1  => cv_tkn_action
                       ,iv_token_value1 => cv_tbl_nm_quote_header
                       ,iv_token_name2  => cv_tkn_error_message
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END insert_quote_header;
--
  /**********************************************************************************
   * Procedure Name   : insert_quote_line
   * Description      : 見積明細登録(A-7)
   ***********************************************************************************/
  PROCEDURE insert_quote_line(
    iv_quote_type                 IN  VARCHAR2,            -- 見積タイプ
    in_quote_header_id            IN  NUMBER,              -- 見積ヘッダID
    in_ref_quote_line_id          IN  NUMBER,              -- 参照見積明細ID
    it_for_insert_quote_data_rec  IN  gt_ins_quote_rtype,  -- 見積作成用配列
    on_quote_line_id              OUT NUMBER,              -- 作成した見積明細ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_quote_line'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    lt_usually_store_sale_price   xxcso_quote_lines.usually_store_sale_price%TYPE;
    lt_this_time_store_sale_price xxcso_quote_lines.this_time_store_sale_price%TYPE;
    lt_quotation_price            xxcso_quote_lines.quotation_price%TYPE;
    lt_sales_discount_price       xxcso_quote_lines.sales_discount_price%TYPE;
    lt_usuall_net_price           xxcso_quote_lines.usuall_net_price%TYPE;
    lt_this_time_net_price        xxcso_quote_lines.this_time_net_price%TYPE;
    lt_amount_of_margin           xxcso_quote_lines.amount_of_margin%TYPE;
    lt_margin_rate                xxcso_quote_lines.margin_rate%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF (iv_quote_type = cv_quote_type_sale) THEN
      lt_usually_store_sale_price := it_for_insert_quote_data_rec.usually_store_sale_price;
      lt_this_time_store_sale_price := it_for_insert_quote_data_rec.this_time_store_sale_price;
      lt_quotation_price := NULL;
      lt_sales_discount_price := NULL;
      lt_usuall_net_price := NULL;
      lt_this_time_net_price := NULL;
      lt_amount_of_margin := NULL;
      lt_margin_rate := NULL;
    ELSIF (iv_quote_type = cv_quote_type_warehouse) THEN
      lt_usually_store_sale_price := NULL;
      lt_this_time_store_sale_price := NULL;
      lt_quotation_price := it_for_insert_quote_data_rec.quotation_price;
      lt_sales_discount_price := it_for_insert_quote_data_rec.sales_discount_price;
      lt_usuall_net_price := it_for_insert_quote_data_rec.usuall_net_price;
      lt_this_time_net_price := it_for_insert_quote_data_rec.this_time_net_price;
      lt_amount_of_margin := it_for_insert_quote_data_rec.margin_amt;
      lt_margin_rate := it_for_insert_quote_data_rec.margin_rate;
    END IF;
--
    BEGIN
      INSERT INTO xxcso_quote_lines(
         quote_line_id
        ,quote_header_id
        ,reference_quote_line_id
        ,inventory_item_id
        ,quote_div
        ,usually_deliv_price
        ,usually_store_sale_price
        ,this_time_deliv_price
        ,this_time_store_sale_price
        ,quotation_price
        ,sales_discount_price
        ,usuall_net_price
        ,this_time_net_price
        ,amount_of_margin
        ,margin_rate
        ,quote_start_date
        ,quote_end_date
        ,remarks
        ,line_order
        ,business_price
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcso_quote_lines_s01.NEXTVAL
        ,in_quote_header_id
        ,in_ref_quote_line_id
        ,it_for_insert_quote_data_rec.inventory_item_id
        ,it_for_insert_quote_data_rec.quote_div_code
        ,it_for_insert_quote_data_rec.usually_deliv_price
        ,lt_usually_store_sale_price
        ,it_for_insert_quote_data_rec.this_time_deliv_price
        ,lt_this_time_store_sale_price
        ,lt_quotation_price
        ,lt_sales_discount_price
        ,lt_usuall_net_price
        ,lt_this_time_net_price
        ,lt_amount_of_margin
        ,lt_margin_rate
        ,it_for_insert_quote_data_rec.quote_start_date
        ,it_for_insert_quote_data_rec.quote_end_date
        ,it_for_insert_quote_data_rec.remarks
        ,NULL
        ,it_for_insert_quote_data_rec.business_price
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      ) RETURNING quote_line_id INTO on_quote_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_ins_data
                       ,iv_token_name1  => cv_tkn_action
                       ,iv_token_value1 => cv_tbl_nm_quote_line
                       ,iv_token_name2  => cv_tkn_error_message
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END insert_quote_line;
--
  /**********************************************************************************
   * Procedure Name   : create_quote_data
   * Description      : 見積データ作成(A-7)
   ***********************************************************************************/
  PROCEDURE create_quote_data(
    it_quote_header_data          IN  gt_col_data_ttype,        -- 見積ファイルヘッダ情報
    it_for_insert_quote_data_tab  IN  gt_ins_quote_data_ttype,  -- 見積作成データ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_quote_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    lv_msg                          VARCHAR2(5000);
    lt_pre_data_rec                 gt_ins_quote_rtype;
    lt_sale_quote_number            xxcso_quote_headers.quote_number%TYPE;
    lt_sale_quote_header_id         xxcso_quote_headers.quote_header_id%TYPE;
    lt_sale_quote_line_id           xxcso_quote_lines.quote_line_id%TYPE;
    lt_warehouse_quote_number       xxcso_quote_headers.quote_number%TYPE;
    lt_warehouse_quote_header_id    xxcso_quote_headers.quote_header_id%TYPE;
    lt_warehouse_quote_line_id      xxcso_quote_lines.quote_line_id%TYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<create_quote_loop>>
    FOR ln_line_cnt IN 1 .. it_for_insert_quote_data_tab.COUNT LOOP
      IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div IN (cv_data_div_sale_warehouse, cv_data_div_sale_only)) THEN
        IF (ln_line_cnt = 1
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale <> lt_pre_data_rec.cust_code_sale
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse <> lt_pre_data_rec.cust_code_warehouse)
        THEN
          -- 見積番号採番（販売先分）
          lt_sale_quote_number := xxcso_auto_code_assign_pkg.auto_code_assign(
                                     cv_get_num_type_quote
                                    ,gv_base_code
                                    ,gd_process_date
                                  );
          -- 見積ヘッダ登録（販売先分）
          insert_quote_header(
             cv_quote_type_sale
            ,lt_sale_quote_number
            ,NULL
            ,NULL
            ,it_for_insert_quote_data_tab(ln_line_cnt)
            ,lt_sale_quote_header_id
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_only) THEN
            -- 見積作成メッセージ
            lv_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_create_quote_sale
                        ,iv_token_name1  => cv_tkn_col1
                        ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                        ,iv_token_name2  => cv_tkn_col_val1
                        ,iv_token_value2 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale
                        ,iv_token_name3  => cv_tkn_quote_num
                        ,iv_token_value3 => lt_sale_quote_number
                      );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
          END IF;
        END IF;
--
        -- 見積明細登録（販売先分）
        insert_quote_line(
           cv_quote_type_sale
          ,lt_sale_quote_header_id
          ,NULL
          ,it_for_insert_quote_data_tab(ln_line_cnt)
          ,lt_sale_quote_line_id
          ,lv_errbuf
          ,lv_retcode
          ,lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_warehouse) THEN
        IF (ln_line_cnt = 1
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale <> lt_pre_data_rec.cust_code_sale
          OR it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse <> lt_pre_data_rec.cust_code_warehouse)
        THEN
          -- 見積番号採番（帳合問屋分）
          lt_warehouse_quote_number := xxcso_auto_code_assign_pkg.auto_code_assign(
                                          cv_get_num_type_quote
                                         ,gv_base_code
                                         ,gd_process_date
                                       );
          -- 見積ヘッダ登録（帳合問屋分）
          insert_quote_header(
             cv_quote_type_warehouse
            ,lt_warehouse_quote_number
            ,lt_sale_quote_number
            ,lt_sale_quote_header_id
            ,it_for_insert_quote_data_tab(ln_line_cnt)
            ,lt_warehouse_quote_header_id
            ,lv_errbuf
            ,lv_retcode
            ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          IF (it_for_insert_quote_data_tab(ln_line_cnt).data_div = cv_data_div_sale_warehouse) THEN
            -- 見積作成メッセージ
            lv_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_create_quote_sale_wh
                        ,iv_token_name1  => cv_tkn_col1
                        ,iv_token_value1 => it_quote_header_data(cn_col_pos_cust_code_sale)
                        ,iv_token_name2  => cv_tkn_col_val1
                        ,iv_token_value2 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_sale
                        ,iv_token_name3  => cv_tkn_col2
                        ,iv_token_value3 => it_quote_header_data(cn_col_pos_cust_code_warehouse)
                        ,iv_token_name4  => cv_tkn_col_val2
                        ,iv_token_value4 => it_for_insert_quote_data_tab(ln_line_cnt).cust_code_warehouse
                        ,iv_token_name5  => cv_tkn_quote_num1
                        ,iv_token_value5 => lt_sale_quote_number
                        ,iv_token_name6  => cv_tkn_quote_num2
                        ,iv_token_value6 => lt_warehouse_quote_number
                      );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
          END IF;
        END IF;
--
        -- 見積明細登録（帳合問屋分）
        insert_quote_line(
           cv_quote_type_warehouse
          ,lt_warehouse_quote_header_id
          ,lt_sale_quote_line_id
          ,it_for_insert_quote_data_tab(ln_line_cnt)
          ,lt_warehouse_quote_line_id
          ,lv_errbuf
          ,lv_retcode
          ,lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      lt_pre_data_rec := it_for_insert_quote_data_tab(ln_line_cnt);
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP create_quote_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END create_quote_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : ファイルアップロードIFデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- データ削除エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_file_ul_if
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => in_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : delete_quote_upload_work
   * Description      : 見積書アップロード中間テーブルデータ削除(A-9)
   ***********************************************************************************/
  PROCEDURE delete_quote_upload_work(
    in_file_id    IN  NUMBER,    -- ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_quote_upload_work'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
      DELETE FROM xxcso_quote_upload_work xquw
      WHERE xquw.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- データ削除エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => cv_tbl_nm_quote_ul_work
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => in_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END delete_quote_upload_work;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2,  -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2,  -- 2.フォーマットパターン
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
--
    -- *** ローカル変数 ***
    lt_quote_data_tab             gt_rec_data_ttype;
    lt_for_insert_quote_data_tab  gt_ins_quote_data_ttype;
    ln_file_id                    NUMBER;
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
    -- 初期処理
    init(
       iv_file_id
      ,iv_fmt_ptn
      ,ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロードIFデータ抽出
    get_upload_data(
       ln_file_id
      ,lt_quote_data_tab
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- 入力データチェック
      check_input_data(
         iv_fmt_ptn
        ,lt_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- 見積書アップロード中間テーブル登録
      insert_quote_upload_work(
         ln_file_id
        ,lt_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 業務エラーチェック
      business_data_check(
         ln_file_id
        ,lt_quote_data_tab(cn_header_rec)
        ,lt_for_insert_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- 見積データ作成
      create_quote_data(
         lt_quote_data_tab(cn_header_rec)
        ,lt_for_insert_quote_data_tab
        ,lv_errbuf
        ,lv_retcode
        ,lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ファイルアップロードIFデータ削除
    delete_file_ul_if(
       ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 見積書アップロード中間テーブルデータ削除
    delete_quote_upload_work(
       ln_file_id
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_id    IN  VARCHAR2,      -- 1.ファイルID
    iv_fmt_ptn    IN  VARCHAR2       -- 2.フォーマットパターン
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
    -- ローカル定数
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
       iv_file_id
      ,iv_fmt_ptn
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_error_cnt := gn_error_cnt + 1;
      gn_normal_cnt := 0;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    FND_FILE.PUT_LINE(
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
END XXCSO017A07C;
/
