CREATE OR REPLACE PACKAGE BODY APPS.XXCOS018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS018A01C(body)
 * Description      : CSVデータアップロード（販売実績）
 * MD.050           : MD050_COS_018_A01_CSVデータアップロード（販売実績）
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_upload_data        ファイルアップロードIF取得(A-2)
 *  del_upload_data        データ削除処理(A-3)
 *  split_sales_data       販売実績データの項目分割処理(A-4)
 *  item_check             項目チェック(A-5)
 *  get_master_data        マスタ情報の取得処理(A-6)
 *  security_check         セキュリティチェック処理(A-7)
 *  set_sales_bp_data      取引先販売実績データ設定処理(A-8)
 *  set_sales_data         販売実績データ設定処理(A-9)
 *  ins_sales_bp_data      取引先販売実績データ登録処理(A-10)
 *  ins_sales_data         販売実績データ登録処理(A-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/11/01    1.0   S.Niki           新規作成
 *  2016/12/19    1.1   S.Niki           E_本稼動_13879追加対応
 *  2019/06/20    1.2   S.Kuwako         E_本稼動_15472軽減税率対応
 *  2019/07/25    1.3   N.Koyama         E_本稼動_15472軽減税率対応(障害対応)
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
  global_proc_date_err_expt         EXCEPTION;    -- 業務日付取得例外ハンドラ
  global_get_profile_expt           EXCEPTION;    -- プロファイル取得例外ハンドラ
  global_get_org_id_expt            EXCEPTION;    -- 在庫組織ID取得例外ハンドラ
  global_get_file_id_lock_expt      EXCEPTION;    -- ファイルIDの取得ハンドラ
  global_get_file_id_data_expt      EXCEPTION;    -- ファイルIDの取得ハンドラ
  global_get_f_uplod_name_expt      EXCEPTION;    -- ファイルアップロード名称の取得ハンドラ
  global_get_f_csv_name_expt        EXCEPTION;    -- CSVファイル名の取得ハンドラ
  global_get_upload_data_expt       EXCEPTION;    -- 販売実績情報データ取得ハンドラ
  global_cut_sales_data_expt        EXCEPTION;    -- ファイルレコード項目数不一致ハンドラ
  global_item_check_expt            EXCEPTION;    -- 項目チェックハンドラ
  global_security_check_expt        EXCEPTION;    -- セキュリティチェックエラーハンドラ
  global_ins_sales_data_expt        EXCEPTION;    -- レコード登録例外ハンドラ
  global_del_sales_data_expt        EXCEPTION;    -- レコード削除例外ハンドラ
--
  global_data_lock_expt             EXCEPTION;    -- データロック例外
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCOS018A01C';   --パッケージ名
  --アプリケーション短縮名
  cv_xxcos_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCOS';          --販物短縮アプリ名
  cv_xxccp_appl_short_name          CONSTANT VARCHAR2(100) := 'XXCCP';          --共通
--
  --メッセージ
  cv_msg_get_f_uplod_name           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';    --ファイルアップロード名称取得エラー
  cv_msg_get_f_csv_name             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';    --CSVファイル名取得エラー
  cv_msg_get_rep_h1                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11289';    --フォーマットパターンメッセージ
  cv_msg_get_rep_h2                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11290';    --CSVファイル名メッセージ
  cv_msg_process_date_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00014';    --業務日付取得エラー
  cv_msg_get_profile_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';    --プロファイル取得エラー
  cv_msg_get_org_id_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';    --在庫組織ID取得エラーメッセージ
  cv_msg_get_data_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';    --データ抽出エラーメッセージ
  cv_msg_get_lock_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';    --ロックエラー
  cv_msg_insert_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';    --データ登録エラーメッセージ
  cv_msg_delete_data_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00012';    --データ削除エラーメッセージ
  cv_msg_chk_rec_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';    --ファイルレコード不一致エラーメッセージ
  cv_msg_get_format_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15101';    --項目フォーマットエラーメッセージ
  cv_msg_mst_chk_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15102';    --マスタチェックエラーメッセージ
  cv_msg_dlv_date_chk_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15103';    --納品日未来日付エラーメッセージ
  cv_msg_cust_sts_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15104';    --顧客ステータスエラーメッセージ
  cv_msg_sale_base_code_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15105';    --顧客の売上拠点コードエラーメッセージ
  cv_msg_null_or_get_data_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15106';    --未設定または取得エラーメッセージ
  cv_msg_sales_target_chk_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15108';    --売上対象区分エラーメッセージ
  cv_msg_item_sts_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15109';    --品目ステータスエラーメッセージ
  cv_msg_security_chk_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15110';    --セキュリティチェックエラーメッセージ
  cv_msg_req_cond_err               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15117';    --条件付き必須チェックエラーメッセージ
  cv_msg_overlap_err                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15118';    --重複レコード取得エラーメッセージ
  cv_msg_bp_com_code_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15120';    --取引先コードエラーメッセージ
  cv_msg_get_h_count                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11287';    --件数メッセージ
-- Ver.1.2 ADD START
  cv_msg_common_pkg_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15123';      --共通関数エラーメッセージ
-- Ver.1.2 ADD END
--
  --メッセージ用文字列
  cv_msg_file_up_load               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';    --ファイルアップロードIF
  cv_msg_salse_unit                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';    --MO:営業単位
  cv_get_bks_id                     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';    --GL会計帳簿ID
  cv_msg_max_date                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';    --XXCOS:MAX日付
  cv_msg_org_code                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';    --XXCOI:在庫組織コード
-- Ver.1.1 ADD START
  cv_msg_bp_sales_dlv_ptn_cls       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15122';    --XXCOS:取引先販売実績データ作成用納品形態区分
-- Ver.1.1 ADD END
  cv_msg_cust_mst                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';    --顧客マスタ
  cv_msg_lkp_code                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';    --クイックコード
  cv_msg_base_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';    --拠点コード
  cv_msg_cd_sale_cls                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10042';    --カード売区分
  cv_msg_employee_code              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14360';    --担当営業員
  cv_msg_tax_class                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00189';    --消費税区分
  cv_msg_tax_view                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';    --消費税view
  cv_msg_tax_rate                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10175';    --消費税率
  cv_msg_offset_cust_code           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15107';    --相殺用顧客コード
  cv_msg_item_mst                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';    --品目マスタ
  cv_msg_sales_head                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00086';    --販売実績ヘッダ
  cv_msg_sales_line                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00087';    --販売実績明細
  cv_msg_data_created               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15111';    --データ作成日時
  cv_msg_sales_bp                   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15112';    --取引先販売実績
  cv_msg_cust_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15113';    --伊藤園顧客コード
  cv_msg_bp_cust_code               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15114';    --取引先顧客コード
  cv_msg_item_code                  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15115';    --伊藤園品名コード
  cv_msg_bp_item_code               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15116';    --取引先品名コード
  cv_msg_bp_company_code            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15119';    --取引先コード
  cv_msg_bp_item_mst                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-15121';    --取引先品目アドオン
--
  --トークン
  cv_tkn_file_id                    CONSTANT VARCHAR2(50)  := 'FILE_ID ';            --ファイルID
  cv_tkn_profile                    CONSTANT VARCHAR2(30)  := 'PROFILE';             --プロファイル名
  cv_tkn_org_code                   CONSTANT VARCHAR2(30)  := 'ORG_CODE_TOK';        --在庫組織コード
  cv_tkn_table                      CONSTANT VARCHAR2(30)  := 'TABLE';               --テーブル名
  cv_tkn_key_data                   CONSTANT VARCHAR2(30)  := 'KEY_DATA';            --キー情報
  cv_tkn_table_name                 CONSTANT VARCHAR2(30)  := 'TABLE_NAME';          --テーブル名
  cv_tkn_data                       CONSTANT VARCHAR2(30)  := 'DATA';                --レコードデータ
  cv_tkn_param1                     CONSTANT VARCHAR2(30)  := 'PARAM1';              --パラメータ1
  cv_tkn_param2                     CONSTANT VARCHAR2(30)  := 'PARAM2';              --パラメータ2
  cv_tkn_param3                     CONSTANT VARCHAR2(30)  := 'PARAM3';              --パラメータ3
  cv_tkn_param4                     CONSTANT VARCHAR2(30)  := 'PARAM4';              --パラメータ4
  cv_tkn_column                     CONSTANT VARCHAR2(30)  := 'COLUMN';              --項目名
-- Ver.1.2 ADD START
  cv_tkn_common                     CONSTANT VARCHAR2(30)  := 'LINE_NO';             --行番号
  cv_tkn_common_name                CONSTANT VARCHAR2(30)  := 'FUNC_NAME';           --共通関数名
  cv_tkn_common_info                CONSTANT VARCHAR2(30)  := 'INFO';
-- Ver.1.2 ADD END
--
  --プロファイル
  cv_prf_org_id                     CONSTANT VARCHAR2(50)  := 'ORG_ID';                      --MO:営業単位
  cv_prf_bks_id                     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';            --GL会計帳簿ID
  cv_prf_max_date                   CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';             --XXCOS:MAX日付
  cv_prf_org_code                   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';    --XXCOI:在庫組織コード
-- Ver.1.1 ADD START
  cv_prf_bp_sales_dlv_ptn_cls       CONSTANT VARCHAR2(50)  := 'XXCOS1_BP_SALES_DLV_PTN_CLS'; --XXCOS:取引先販売実績データ作成用納品形態区分
-- Ver.1.1 ADD END
--
  --クイックコード
  cv_look_file_upload_obj           CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';           --ファイルアップロードオブジェクト
  cv_look_card_sale_class           CONSTANT VARCHAR2(50)  := 'XXCOS1_CARD_SALE_CLASS';           --カード売区分
  cv_look_cus_sts                   CONSTANT VARCHAR2(50)  := 'XXCOS1_CUS_STATUS_MST_001_A01';    --顧客ステータス
  cv_look_cus_sts_a01               CONSTANT VARCHAR2(50)  := 'XXCOS_001_A01_%';                  --顧客ステータス：コード
  cv_look_tax_class                 CONSTANT VARCHAR2(50)  := 'XXCOS1_TAX_CLASS';                 --消費税区分
  cv_look_item_status               CONSTANT VARCHAR2(50)  := 'XXCOS1_ITEM_STATUS_MST_001_A01';   --品目ステータス
  cv_look_item_sts_a01              CONSTANT VARCHAR2(50)  := 'XXCOS_001_A01_%';                  --品目ステータス：コード
--
  cv_comma                          CONSTANT VARCHAR2(1)   := ',';         --区切り文字
  cv_dobule_quote                   CONSTANT VARCHAR2(1)   := '"';         --括り文字
  cv_line_feed                      CONSTANT VARCHAR2(1)   := CHR(10);     --改行コード
  cn_c_header                       CONSTANT NUMBER        := 15;          --ファイル項目数
  cn_begin_line                     CONSTANT NUMBER        := 2;           --最初の行
  cn_line_zero                      CONSTANT NUMBER        := 0;           --0行
  cn_item_header                    CONSTANT NUMBER        := 1;           --項目名
  cv_msg_comma                      CONSTANT VARCHAR2(2)   := '、';        --メッセージ用区切り文字
  ct_user_lang                      CONSTANT fnd_lookup_values.language%TYPE
                                                           := USERENV( 'LANG' );
--
  --CSVレイアウト（レイアウト順序を定義）
  cn_bp_company_code                CONSTANT NUMBER        := 1;           --取引先コード
  cn_dlv_inv_num                    CONSTANT NUMBER        := 2;           --納品伝票番号
  cn_base_code                      CONSTANT NUMBER        := 3;           --拠点コード
  cn_delivery_date                  CONSTANT NUMBER        := 4;           --納品日
  cn_card_sale_class                CONSTANT NUMBER        := 5;           --カード売区分
  cn_cust_code                      CONSTANT NUMBER        := 6;           --伊藤園顧客コード
  cn_bp_cust_code                   CONSTANT NUMBER        := 7;           --取引先顧客コード
  cn_tax_class                      CONSTANT NUMBER        := 8;           --消費税区分
  cn_line_number                    CONSTANT NUMBER        := 9;           --明細番号
  cn_item_code                      CONSTANT NUMBER        := 10;          --伊藤園品名コード
  cn_bp_item_code                   CONSTANT NUMBER        := 11;          --取引先品名コード
  cn_dlv_qty                        CONSTANT NUMBER        := 12;          --数量
  cn_unit_price                     CONSTANT NUMBER        := 13;          --売単価
  cn_cash_and_card                  CONSTANT NUMBER        := 14;          --現金・カード併用額
  cn_data_created                   CONSTANT NUMBER        := 15;          --データ作成日時
--
  --項目長（各項目の項目長を定義）
  cn_bp_company_code_length         CONSTANT NUMBER        := 9;           --取引先コード
  cn_dlv_inv_num_length             CONSTANT NUMBER        := 9;           --納品伝票番号
  cn_base_code_length               CONSTANT NUMBER        := 4;           --拠点コード
  cn_delivery_date_length           CONSTANT NUMBER        := 8;           --納品日
  cn_card_sale_class_length         CONSTANT NUMBER        := 1;           --カード売区分
  cn_cust_code_length               CONSTANT NUMBER        := 9;           --伊藤園顧客コード
  cn_bp_cust_code_length            CONSTANT NUMBER        := 15;          --取引先顧客コード
  cn_tax_class_length               CONSTANT NUMBER        := 1;           --消費税区分
  cn_line_number_length             CONSTANT NUMBER        := 2;           --明細番号
  cn_item_code_length               CONSTANT NUMBER        := 7;           --伊藤園品名コード
  cn_bp_item_code_length            CONSTANT NUMBER        := 15;          --取引先品名コード
  cn_dlv_qty_length                 CONSTANT NUMBER        := 5;           --数量
  cn_dlv_qty_point                  CONSTANT NUMBER        := 2;           --数量（小数点以下）
  cn_unit_price_length              CONSTANT NUMBER        := 7;           --売単価
  cn_cash_and_card_length           CONSTANT NUMBER        := 11;          --現金・カード併用額
  cn_data_created_length            CONSTANT NUMBER        := 19;          --データ作成日時
  cn_priod                          CONSTANT NUMBER        := 0;           --小数点以下が0の場合にセット
--
  --顧客区分
  cv_cust_class_base                CONSTANT VARCHAR2(1)   := '1';         --拠点
  cv_cust_class_cust                CONSTANT VARCHAR2(2)   := '10';        --顧客
  cv_cust_class_user                CONSTANT VARCHAR2(2)   := '12';        --上様
--
  --売上対象区分
  cv_sales_target_off               CONSTANT VARCHAR2(1)   := '0';         --売上対象外
--
  --相殺用顧客区分
  cv_offset_cust_div_on             CONSTANT VARCHAR2(1)   := '1';         --相殺用顧客
--
  --納品伝票区分
  cv_dlv_inv_cls_dlv                CONSTANT VARCHAR2(1)   := '1';         --納品
--
  --売上区分
  cv_sales_class_vd                 CONSTANT VARCHAR2(1)   := '3';         --VD売上
--
  --作成元区分
  cv_create_cls_sls_upload          CONSTANT VARCHAR2(1)   := '0';         --CSVデータアップロード（販売実績）
--
  --消費税区分
  cv_tax_class_tax                  CONSTANT VARCHAR(10)   := '0';         --非課税
  cv_tax_class_out                  CONSTANT VARCHAR(10)   := '1';         --外税
  cv_tax_class_ins_slip             CONSTANT VARCHAR(10)   := '2';         --内税（伝票課税）
  cv_tax_class_ins_bid              CONSTANT VARCHAR(10)   := '3';         --内税（単価込み）
--
  --端数処理区分
  cv_tax_rounding_rule_up           CONSTANT VARCHAR2(10)  := 'UP';        --切り上げ
  cv_tax_rounding_rule_down         CONSTANT VARCHAR2(10)  := 'DOWN';      --切り捨て
  cv_tax_rounding_rule_nearest      CONSTANT VARCHAR2(10)  := 'NEAREST';   --四捨五入
--
  --顧客品目
  cv_cust_item_def_level            CONSTANT VARCHAR2(1)   := '1';         --顧客品目：定義レベル
  cv_inactive_flag_no               CONSTANT VARCHAR2(1)   := 'N';         --顧客品目：有効
--
  --日付フォーマット
  cv_fmt_std                        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_fmt_hh24miss                   CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_mm                         CONSTANT VARCHAR2(2)   := 'MM';
--
  --赤黒フラグ
  cv_red_black_flag_r               CONSTANT VARCHAR2(1)   := '0';         --赤
  cv_red_black_flag_b               CONSTANT VARCHAR2(1)   := '1';         --黒
--
  --有効フラグ
  cv_enabled_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';         --有効
--
  --処理済フラグ
  cv_complete_flag_y                CONSTANT VARCHAR2(1)   := 'Y';         --処理済
  cv_complete_flag_n                CONSTANT VARCHAR2(1)   := 'N';         --未処理
  cv_complete_flag_s                CONSTANT VARCHAR2(1)   := 'S';         --対象外
--
  --HHT受信フラグ
  cv_hht_rcv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';         --HHT受信外
--
  --ダミー金額
  cn_amt_dummy                      CONSTANT NUMBER(1)     := 0;           --ダミー金額
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --販売実績データ BLOB型
  gt_sales_data                     xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;        --1次元配列
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;          --2次元配列
  gr_sales_work_data                gt_var_data2;                                              --分活用変数
--
  TYPE g_tab_sales_head_rec         IS TABLE OF xxcos_sales_exp_headers%ROWTYPE  INDEX BY PLS_INTEGER;  --販売実績ヘッダ
  TYPE g_tab_sales_line_rec         IS TABLE OF xxcos_sales_exp_lines%ROWTYPE    INDEX BY PLS_INTEGER;  --販売実績明細
  TYPE g_tab_sales_bp_rec           IS TABLE OF xxcos_sales_bus_partners%ROWTYPE INDEX BY PLS_INTEGER;  --取引先販売実績
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                      INDEX BY PLS_INTEGER;  --自拠点
--
  gr_sales_head_data1               g_tab_sales_head_rec;            --販売実績ヘッダ
  gr_sales_line_data1               g_tab_sales_line_rec;            --販売実績明細
  gr_sales_head_data2               g_tab_sales_head_rec;            --販売実績ヘッダ（相殺）
  gr_sales_line_data2               g_tab_sales_line_rec;            --販売実績明細（相殺）
  gr_sales_bp_data                  g_tab_sales_bp_rec;              --取引先販売実績
  gr_g_login_base_info              g_tab_login_base_info_rec;       --自拠点
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_upload_file_name               VARCHAR2(128);                                      --ファイルアップロード名称
  gv_csv_file_name                  VARCHAR2(256);                                      --CSVファイル名
  gd_process_date                   DATE;                                               --業務日付
  gt_file_id                        xxccp_mrp_file_ul_interface.file_id%TYPE;           --ファイルID
--
  --シーケンス用
  gt_sales_exp_header_id1           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;   --販売実績ヘッダID
  gt_sales_exp_header_id2           xxcos_sales_exp_headers.sales_exp_header_id%TYPE;   --販売実績ヘッダID（相殺）
  gt_sales_exp_line_id1             xxcos_sales_exp_lines.sales_exp_line_id%TYPE;       --販売実績明細ID
  gt_sales_exp_line_id2             xxcos_sales_exp_lines.sales_exp_line_id%TYPE;       --販売実績明細ID（相殺）
  gt_dlv_invoice_number_os          xxcos_sales_exp_headers.dlv_invoice_number%TYPE;    --取引先納品伝票番号
--
  --金額合計用
  gt_sale_amount_sum                xxcos_sales_exp_headers.sale_amount_sum%TYPE;       --売上金額合計
  gt_pure_amount_sum                xxcos_sales_exp_headers.pure_amount_sum%TYPE;       --本体金額合計
  gt_tax_amount_sum                 xxcos_sales_exp_headers.tax_amount_sum%TYPE;        --消費税金額合計
--
  --プロファイル値格納用
  gv_salse_unit                     VARCHAR2(50);                --営業単位ID
  gn_bks_id                         NUMBER;                      --会計帳簿ID
  gd_max_date                       DATE;                        --MAX日付
  gv_org_code                       VARCHAR2(50);                --在庫組織コード
  gn_org_id                         NUMBER;                      --在庫組織ID
-- Ver.1.1 ADD START
  gv_prf_bp_sales_dlv_ptn_cls       VARCHAR2(50);                --取引先販売実績データ作成用納品形態区分
-- Ver.1.1 ADD END
--
  --カウンタ他制御用
  gn_get_counter_data               NUMBER;                                             --データ数
  gn_hed_cnt1                       NUMBER;                                             --ヘッダカウンター
  gn_line_cnt1                      NUMBER;                                             --明細カウンター
  gn_hed_cnt2                       NUMBER;                                             --ヘッダカウンター
  gn_line_cnt2                      NUMBER;                                             --明細カウンター
  gn_bp_cnt                         NUMBER;                                             --取引先販売実績カウンター
  gn_hed_suc_cnt                    NUMBER;                                             --成功ヘッダカウンター
  gn_line_suc_cnt                   NUMBER;                                             --成功明細カウンター
  gt_bp_com_code                    xxcos_sales_bus_partners.bp_company_code%TYPE;      --取引先会社コード
  gt_dlv_inv_num                    xxcos_sales_bus_partners.dlv_invoice_number%TYPE;   --納品伝票番号
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_get_format     IN  VARCHAR2  -- 入力フォーマットパターン
    ,in_file_id        IN  NUMBER    -- ファイルID
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_key_info      VARCHAR2(5000);  --key情報
    lv_max_date      VARCHAR2(5000);  --MAX日付
    lv_tab_name      VARCHAR2(500);   --テーブル名
--
    -- *** ローカル・カーソル ***
    CURSOR get_login_base_cur
    IS
      SELECT lbi.base_code   AS base_code
        FROM xxcos_login_base_info_v lbi   --ログインユーザ拠点ビュー
      ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ****************************
    -- ***  入力パラメータ出力  ***
    -- ****************************
--
    ------------------------------------
    --ファイルアップロード名称取得
    ------------------------------------
    BEGIN
      SELECT flv.meaning    AS upload_file_name
        INTO gv_upload_file_name
        FROM fnd_lookup_types  flt    --クイックタイプ
            ,fnd_application   fa     --アプリケーション
            ,fnd_lookup_values flv    --クイックコード
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = cv_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = cv_look_file_upload_obj
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = ct_user_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    --CSVファイル名取得
    ------------------------------------
    BEGIN
      SELECT xmf.file_name  AS csv_file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf  --ファイルアップロードIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE global_get_f_csv_name_expt;
    END;
--
    ------------------------------------
    --パラメータ出力
    ------------------------------------
    --コンカレントプログラム入力項目の出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcos_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h1
                  ,iv_token_name1   => cv_tkn_param1                 --パラメータ１
                  ,iv_token_value1  => in_file_id                    --ファイルID
                  ,iv_token_name2   => cv_tkn_param2                 --パラメータ２
                  ,iv_token_value2  => iv_get_format                 --フォーマットパターン
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --アップロードファイル名の出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_xxcos_appl_short_name
                  ,iv_name          => cv_msg_get_rep_h2
                  ,iv_token_name1   => cv_tkn_param3                 --ファイルアップロード名称(メッセージ文字列)
                  ,iv_token_value1  => gv_upload_file_name           --ファイルアップロード名称
                  ,iv_token_name2   => cv_tkn_param4                 --CSVファイル名(メッセージ文字列)
                  ,iv_token_value2  => gv_csv_file_name              --CSVファイル名
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- **********************
    -- ***  業務日付取得  ***
    -- **********************
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    -- ****************************
    -- ***  プロファイル値取得  ***
    -- ****************************
--
    ------------------------------------
    -- MO:営業単位
    ------------------------------------
    gv_salse_unit := FND_PROFILE.VALUE( cv_prf_org_id );
    -- プロファイル値が取得できない場合
    IF ( gv_salse_unit IS NULL ) THEN
      --キー情報の編集処理
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_salse_unit
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 会計帳簿ID
    ------------------------------------
    gn_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );
    -- プロファイル値が取得できない場合
    IF ( gn_bks_id IS NULL ) THEN
      --キー情報の編集処理
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_get_bks_id
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- XXCOS:MAX日付
    ------------------------------------
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
    -- プロファイル値が取得できない場合
    IF ( lv_max_date IS NULL ) THEN
      --キー情報の編集処理
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_max_date
                     );
      RAISE global_get_profile_expt;
    END IF;
    -- 日付型に変換
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_std );
--
    ------------------------------------
    -- XXCOI:在庫組織コード
    ------------------------------------
    gv_org_code := FND_PROFILE.VALUE( cv_prf_org_code );
    -- プロファイル値が取得できない場合
    IF ( gv_org_code IS NULL ) THEN
      --キー情報の編集処理
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_org_code
                     );
      RAISE global_get_profile_expt;
    END IF;
-- Ver.1.1 ADD START
--
    ------------------------------------
    -- XXCOS:取引先販売実績データ作成用納品形態区分
    ------------------------------------
    gv_prf_bp_sales_dlv_ptn_cls := FND_PROFILE.VALUE( cv_prf_bp_sales_dlv_ptn_cls );
    -- プロファイル値が取得できない場合
    IF ( gv_prf_bp_sales_dlv_ptn_cls IS NULL ) THEN
      --キー情報の編集処理
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_bp_sales_dlv_ptn_cls
                     );
      RAISE global_get_profile_expt;
    END IF;
-- Ver.1.1 ADD END
--
    -- ************************
    -- ***  在庫組織ID取得  ***
    -- ************************
--
    gn_org_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
    -- 在庫組織ID取得エラーの場合
    IF ( gn_org_id IS NULL ) THEN
      RAISE global_get_org_id_expt;
    END IF;
--
    -- ********************
    -- ***  自拠点取得  ***
    -- ********************
--
    OPEN  get_login_base_cur;
    -- バルクフェッチ
    FETCH get_login_base_cur BULK COLLECT INTO gr_g_login_base_info;
    -- カーソルCLOSE
    CLOSE get_login_base_cur;
--
  EXCEPTION
--
    --*** ファイルアップロード名称取得ハンドラ ***
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_f_uplod_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => iv_get_format
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** CSVファイル名取得ハンドラ ***
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_f_csv_name
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_name
                      ,iv_name          =>  cv_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
    --*** プロファイル取得例外ハンドラ ***
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** 在庫組織ID取得例外ハンドラ ***
    WHEN global_get_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_org_id_err
                    ,iv_token_name1  => cv_tkn_org_code
                    ,iv_token_value1 => gv_org_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIF取得(A-2)
   ***********************************************************************************/
   PROCEDURE get_upload_data (
     in_file_id            IN  NUMBER       -- FILE_ID
    ,on_get_counter_data   OUT NUMBER       -- データ数
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
   )
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
--
    -- *** ローカル変数 ***
--
    lv_key_info   VARCHAR2(5000);  --key情報
    lv_tab_name   VARCHAR2(500);   --テーブル名
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
    ------------------------------------
    -- ロック取得
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_id   AS file_id
        INTO gt_file_id
        FROM xxccp_mrp_file_ul_interface xmf  --ファイルアップロードIF
       WHERE xmf.file_id = in_file_id   --ファイルID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_file_up_load
                       );
        RAISE global_get_file_id_data_expt;
      --*** ロック取得エラーハンドラ ***
      WHEN global_data_lock_expt THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => cv_xxcos_appl_short_name
                                ,iv_name        => cv_msg_file_up_load
                               );
        RAISE global_data_lock_expt;
    END;
--
    ------------------------------------
    -- 販売実績情報データ取得
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id           -- ファイルＩＤ
     ,ov_file_data => gt_sales_data        -- 販売実績情報データ(配列型)
     ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --戻り値チェック
    IF ( lv_retcode = cv_status_error ) THEN
      --キー情報の編集処理
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      RAISE global_get_upload_data_expt;
    END IF;
    --
    -- 販売実績情報データの取得ができない場合のエラー編集
    IF ( gt_sales_data.LAST < cn_begin_line ) THEN
      --キー情報の編集処理
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => cv_xxcos_appl_short_name
                      ,iv_name        => cv_msg_file_up_load
                     );
      RAISE global_get_upload_data_expt;
    END IF;
--
    ------------------------------------
    -- データ数件数の取得
    ------------------------------------
    --データ数件数
    on_get_counter_data := gt_sales_data.COUNT;
    gn_target_cnt       := gt_sales_data.COUNT - 1;
--
  EXCEPTION
--
    --*** 販売実績情報データ取得ハンドラ ***
    WHEN global_get_upload_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** ファイルID取得ハンドラ ***
    WHEN global_get_file_id_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** ロック取得エラーハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_lock_err
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => lv_tab_name
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : データ削除処理(A-3)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     in_file_id    IN  NUMBER   -- 1.FILE_ID
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_upload_data'; -- プログラム名
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
    lv_tab_name   VARCHAR2(100);    --テーブル名
    lv_key_info   VARCHAR2(100);    --キー情報
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
    -- ************************************
    -- ***  販売実績情報データ削除処理  ***
    -- ************************************
--
    BEGIN
      DELETE
        FROM xxccp_mrp_file_ul_interface xmf  --ファイルアップロードIF
       WHERE xmf.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_file_up_load
                     );
        lv_key_info := SQLERRM;
        RAISE global_del_sales_data_expt;
    END;
--
  EXCEPTION
--
    --*** レコード削除例外ハンドラ ***
    WHEN global_del_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_delete_data_err
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => lv_tab_name
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : split_sales_data
   * Description      : 販売実績データの項目分割処理(A-4)
   ***********************************************************************************/
  PROCEDURE split_sales_data(
     in_cnt        IN  NUMBER    -- データ数
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'split_sales_data'; -- プログラム名
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_rec_data     VARCHAR2(32765);
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
    <<get_sales_item_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- 全項目数チェック
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_sales_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_sales_data(i), cv_comma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --エラー
        lv_rec_data := gt_sales_data(i);
        RAISE global_cut_sales_data_expt;
      END IF;
      --カラム分割
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- 項目分割
        ------------------------------------
        gr_sales_work_data(i)(j) := TRIM( REPLACE( xxccp_common_pkg.char_delim_partition(
                                                     iv_char     => gt_sales_data(i)
                                                    ,iv_delim    => cv_comma
                                                    ,in_part_num => j
                                          ) ,cv_dobule_quote, NULL )
                                    );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP;
--
    END LOOP get_sales_item_loop;
--
  EXCEPTION
--
    -- *** ファイルレコード項目数不一致ハンドラ ***
    WHEN global_cut_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_chk_rec_err
                    ,iv_token_name1  => cv_tkn_data
                    ,iv_token_value1 => lv_rec_data
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END split_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : 項目チェック(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
     in_cnt                   IN  NUMBER    -- データカウンタ
    ,ov_bp_company_code       OUT VARCHAR2  -- 取引先コード
    ,ov_dlv_inv_num           OUT VARCHAR2  -- 納品伝票番号
    ,ov_base_code             OUT VARCHAR2  -- 拠点コード
    ,od_delivery_date         OUT DATE      -- 納品日
    ,ov_card_sale_class       OUT VARCHAR2  -- カード売区分
    ,ov_customer_code         OUT VARCHAR2  -- 伊藤園顧客コード
    ,ov_bp_customer_code      OUT VARCHAR2  -- 取引先顧客コード
    ,ov_tax_class             OUT VARCHAR2  -- 消費税区分
    ,on_line_number           OUT NUMBER    -- 明細番号
    ,ov_item_code             OUT VARCHAR2  -- 伊藤園品名コード
    ,ov_bp_item_code          OUT VARCHAR2  -- 取引先品名コード
    ,on_dlv_qty               OUT NUMBER    -- 数量
    ,on_unit_price            OUT NUMBER    -- 売単価
    ,on_cash_and_card         OUT NUMBER    -- 現金・カード併用額
    ,od_data_created          OUT DATE      -- データ作成日時
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_check'; -- プログラム名
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
    lv_err_msg         VARCHAR2(32767);  --エラーメッセージ
    ld_data_created    DATE;             --データ作成日時
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
    --初期化
    lv_err_msg := NULL;
--
    -- **********************
    -- ***  取引先コード  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_company_code)     -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_company_code)             -- 2.項目の値
     ,in_item_len     => cn_bp_company_code_length                                  -- 3.項目の長さ
     ,in_item_decimal => cn_priod                                                   -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_company_code)    --取引先コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_bp_company_code := gr_sales_work_data(in_cnt)(cn_bp_company_code);
    END IF;
--
    -- **********************
    -- ***  納品伝票番号  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_dlv_inv_num)         -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                 -- 2.項目の値
     ,in_item_len     => cn_dlv_inv_num_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_priod                                                   -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_dlv_inv_num)        --納品伝票番号
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_dlv_inv_num := gr_sales_work_data(in_cnt)(cn_dlv_inv_num);
    END IF;
--
    -- ********************
    -- ***  拠点コード  ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_base_code)           -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_base_code)                   -- 2.項目の値
     ,in_item_len     => cn_base_code_length                                        -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_base_code)          --拠点コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_base_code := gr_sales_work_data(in_cnt)(cn_base_code);
    END IF;
--
    -- ****************
    -- ***  納品日  ***
    -- ****************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_delivery_date)       -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_delivery_date)               -- 2.項目の値
     ,in_item_len     => cn_delivery_date_length                                    -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_dat                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_delivery_date)      --納品日
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      od_delivery_date := TO_DATE( gr_sales_work_data(in_cnt)(cn_delivery_date) ,cv_fmt_std );
    END IF;
--
    -- **********************
    -- ***  カード売区分  ***
    -- **********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_card_sale_class)     -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_card_sale_class)             -- 2.項目の値
     ,in_item_len     => cn_card_sale_class_length                                  -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_card_sale_class)    --カード売区分
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_card_sale_class := gr_sales_work_data(in_cnt)(cn_card_sale_class);
    END IF;
--
    -- **************************
    -- ***  伊藤園顧客コード  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_cust_code)           -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_cust_code)                   -- 2.項目の値
     ,in_item_len     => cn_cust_code_length                                        -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_cust_code)          --伊藤園顧客コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_customer_code := gr_sales_work_data(in_cnt)(cn_cust_code);
    END IF;
--
    -- **************************
    -- ***  取引先顧客コード  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_cust_code)        -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_cust_code)                -- 2.項目の値
     ,in_item_len     => cn_bp_cust_code_length                                     -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_cust_code)       --取引先顧客コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_bp_customer_code:= gr_sales_work_data(in_cnt)(cn_bp_cust_code);
    END IF;
--
    -- ********************
    -- ***  消費税区分  ***
    -- ********************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_tax_class)           -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_tax_class)                   -- 2.項目の値
     ,in_item_len     => cn_tax_class_length                                        -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_tax_class)          --消費税区分
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_tax_class := gr_sales_work_data(in_cnt)(cn_tax_class);
    END IF;
--
    -- ******************
    -- ***  明細番号  ***
    -- ******************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_line_number)         -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_line_number)                 -- 2.項目の値
     ,in_item_len     => cn_line_number_length                                      -- 3.項目の長さ
     ,in_item_decimal => cn_priod                                                   -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_line_number)        --明細番号
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_line_number := gr_sales_work_data(in_cnt)(cn_line_number);
    END IF;
--
    -- **************************
    -- ***  伊藤園品名コード  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_item_code)           -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_item_code)                   -- 2.項目の値
     ,in_item_len     => cn_item_code_length                                        -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_item_code)          --伊藤園品名コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_item_code := gr_sales_work_data(in_cnt)(cn_item_code);
    END IF;
--
    -- **************************
    -- ***  取引先品名コード  ***
    -- **************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_bp_item_code)        -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_bp_item_code)                -- 2.項目の値
     ,in_item_len     => cn_bp_cust_code_length                                     -- 3.項目の長さ
     ,in_item_decimal => NULL                                                       -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ok                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_bp_item_code)       --取引先品名コード
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      ov_bp_item_code := gr_sales_work_data(in_cnt)(cn_bp_item_code);
    END IF;
--
    -- **************
    -- ***  数量  ***
    -- **************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_dlv_qty)             -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_dlv_qty)                     -- 2.項目の値
     ,in_item_len     => cn_dlv_qty_length                                          -- 3.項目の長さ
     ,in_item_decimal => cn_dlv_qty_point                                           -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_dlv_qty)            --数量
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_dlv_qty := gr_sales_work_data(in_cnt)(cn_dlv_qty);
    END IF;
--
    -- ****************
    -- ***  売単価  ***
    -- ****************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_unit_price)          -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_unit_price)                  -- 2.項目の値
     ,in_item_len     => cn_unit_price_length                                       -- 3.項目の長さ
     ,in_item_decimal => cn_priod                                                   -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_unit_price)         --売単価
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_unit_price := gr_sales_work_data(in_cnt)(cn_unit_price);
    END IF;
--
    -- ****************************
    -- ***  現金・カード併用額  ***
    -- ****************************
--
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_sales_work_data(cn_item_header)(cn_cash_and_card)       -- 1.項目名称
     ,iv_item_value   => gr_sales_work_data(in_cnt)(cn_cash_and_card)               -- 2.項目の値
     ,in_item_len     => cn_cash_and_card_length                                    -- 3.項目の長さ
     ,in_item_decimal => cn_priod                                                   -- 4.項目の長さ(小数点以下)
     ,iv_item_nullflg => xxccp_common_pkg2.gv_null_ng                               -- 5.必須フラグ
     ,iv_item_attr    => xxccp_common_pkg2.gv_attr_num                              -- 6.項目属性
     ,ov_errbuf       => lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode  -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_cash_and_card)      --現金・カード併用額
                    ) || cv_line_feed;
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --値を返却
      on_cash_and_card := gr_sales_work_data(in_cnt)(cn_cash_and_card);
    END IF;
--
    -- ************************
    -- ***  データ作成日時  ***
    -- ************************
--
    IF ( gr_sales_work_data(in_cnt)(cn_data_created) IS NULL ) THEN
      --NULLの場合エラー
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_appl_short_name
                     ,iv_name          => cv_msg_get_format_err
                     ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                     ,iv_token_value1  => in_cnt                                                    --行番号
                     ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                     ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                     ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                     ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                     ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                     ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_data_created)       --データ作成日時
                    ) || cv_line_feed;
    ELSE
      --日付型以外の場合エラー
      BEGIN
        ld_data_created := TO_DATE( gr_sales_work_data(in_cnt)(cn_data_created) ,cv_fmt_hh24miss );
        --値を返却
        od_data_created := ld_data_created;
      EXCEPTION
        -- *** 項目チェックエラーハンドラ ***
        WHEN OTHERS THEN
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_appl_short_name
                         ,iv_name          => cv_msg_get_format_err
                         ,iv_token_name1   => cv_tkn_param1                                             --パラメータ1(トークン)
                         ,iv_token_value1  => in_cnt                                                    --行番号
                         ,iv_token_name2   => cv_tkn_param2                                             --パラメータ2(トークン)
                         ,iv_token_value2  => gr_sales_work_data(in_cnt)(cn_dlv_inv_num)                --納品伝票番号
                         ,iv_token_name3   => cv_tkn_param3                                             --パラメータ3(トークン)
                         ,iv_token_value3  => gr_sales_work_data(in_cnt)(cn_line_number)                --行No
                         ,iv_token_name4   => cv_tkn_column                                             --項目名(トークン)
                         ,iv_token_value4  => gr_sales_work_data(cn_item_header)(cn_data_created)       --データ作成日時
                        ) || cv_line_feed;
      END;
    END IF;
--
    --ワーニングメッセージ確認
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 項目チェックエラーハンドラ ***
    WHEN global_item_check_expt THEN
      ov_errmsg := RTRIM(lv_err_msg, cv_line_feed);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : get_master_data
   * Description      : マスタ情報の取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
     in_cnt                     IN  NUMBER      -- データカウンタ
    ,iv_bp_company_code         IN  VARCHAR2    -- 取引先コード
    ,iv_dlv_inv_num             IN  VARCHAR2    -- 納品伝票番号
    ,iv_base_code               IN  VARCHAR2    -- 拠点コード
    ,id_delivery_date           IN  DATE        -- 納品日
    ,iv_card_sale_class         IN  VARCHAR2    -- カード売区分
    ,iv_customer_code           IN  VARCHAR2    -- 伊藤園顧客コード
    ,iv_bp_customer_code        IN  VARCHAR2    -- 取引先顧客コード
    ,iv_tax_class               IN  VARCHAR2    -- 消費税区分
    ,in_line_number             IN  NUMBER      -- 明細番号
    ,iv_item_code               IN  VARCHAR2    -- 伊藤園品名コード
    ,iv_bp_item_code            IN  VARCHAR2    -- 取引先品名コード
    ,ov_sales_base_code         OUT VARCHAR2    -- 売上拠点コード
    ,ov_receiv_base_code        OUT VARCHAR2    -- 入金拠点コード
    ,ov_bill_tax_round_rule     OUT VARCHAR2    -- 税金－端数処理
    ,ov_conv_customer_code      OUT VARCHAR2    -- 変換後顧客コード
    ,ov_offset_cust_code        OUT VARCHAR2    -- 相殺用顧客コード
    ,ov_employee_number         OUT VARCHAR2    -- 担当営業員
    ,ov_cust_gyotai_sho         OUT VARCHAR2    -- 業態（小分類）
    ,on_tax_rate                OUT NUMBER      -- 消費税率
    ,ov_tax_code                OUT VARCHAR2    -- 税金コード
    ,ov_consumption_tax_class   OUT VARCHAR2    -- 消費税区分
    ,ov_conv_item_code          OUT VARCHAR2    -- 変換後品目コード
    ,ov_uom_code                OUT VARCHAR2    -- 基準単位
    ,on_business_cost           OUT NUMBER      -- 営業原価
    ,ov_item_status             OUT VARCHAR2    -- 品目ステータス
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_master_data'; -- プログラム名
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
-- Ver.1.2 ADD START
    cv_common_pkg_name             CONSTANT VARCHAR2(128) := 'XXCOS_COMMON_PKG.GET_TAX_RATE_INFO';   --共通関数名
    cv_view_name                   CONSTANT VARCHAR2(30)  := 'XXCOS_REDUCED_TAX_RATE_V';             --XXCOS品目別消費税率ビュー
    cv_tax_view_txt                CONSTANT VARCHAR2(100) := 'XXCOS_TAX_V';
    cv_tax_class_txt               CONSTANT VARCHAR2(100) := 'TAX_CLASS';                            
-- Ver.1.2 ADD END
--
    -- *** ローカル変数 ***
    lv_bp_company_code             VARCHAR2(9);      --取引先コード
    lv_base_code                   VARCHAR2(4);      --拠点コード
    lv_card_sale_class             VARCHAR2(1);      --カード売区分
    lv_customer_status             VARCHAR2(2);      --顧客ステータス
    lv_tax_class                   VARCHAR2(1);      --消費税区分
    ld_process_month               DATE;             --業務日付月
    ld_delivery_month              DATE;             --納品月
    lv_customer_code               VARCHAR2(9);      --顧客コード
    lv_customer_status_chk         VARCHAR2(2);      --顧客ステータス_チェック用
    lv_item_code                   VARCHAR2(7);      --品名コード
    lv_sales_target                VARCHAR2(1);      --売上対象区分
    lv_item_status                 VARCHAR2(2);      --品目ステータス
-- Ver.1.2 ADD START
    lv_class_for_variable_tax      VARCHAR2(4);      -- 軽減税率用税種別
    lv_tax_name                    VARCHAR2(80);     -- 税率キー名称
    lv_tax_description             VARCHAR2(240);    -- 摘要
    lv_tax_histories_code          VARCHAR2(80);     -- 消費税履歴コード
    lv_tax_histories_description   VARCHAR2(240);    -- 消費税履歴名称
    ld_tax_start_date              DATE;             -- 税率キー_開始日
    ld_tax_end_date                DATE;             -- 税率キー_終了日
    ld_tax_start_date_histories    DATE;             -- 消費税履歴_開始日
    ld_tax_end_date_histories      DATE;             -- 消費税履歴_終了日
    lv_tax_class_suppliers_outside VARCHAR2(150);    -- 税区分_仕入外税
    lv_tax_class_suppliers_inside  VARCHAR2(150);    -- 税区分_仕入内税
    lv_tax_class_sales_outside     VARCHAR2(150);    -- 税区分_売上外税
    lv_tax_class_sales_inside      VARCHAR2(150);    -- 税区分_売上内税
-- Ver.1.2 ADD END
--
    lv_tab_name                    VARCHAR2(100);    --テーブル名
    lv_col_name                    VARCHAR2(100);    --項目名
    lv_key_info1                   VARCHAR2(100);    --key情報1
    lv_key_info2                   VARCHAR2(100);    --key情報2
    lv_key_info                    VARCHAR2(200);    --key情報
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
    -- 業務日付月をセット
    ld_process_month  := TRUNC( gd_process_date ,cv_fmt_mm );
    -- 納品月をセット
    ld_delivery_month := TRUNC( id_delivery_date ,cv_fmt_mm );
--
    -- **********************
    -- ***  取引先コード  ***
    -- **********************
--
    BEGIN
      SELECT xca.customer_code  AS bp_company_code
        INTO lv_bp_company_code
        FROM xxcmm_cust_accounts xca       --顧客追加情報
       WHERE xca.customer_code    = iv_bp_company_code
         AND xca.offset_cust_div  = cv_offset_cust_div_on  --相殺用顧客
      ;
    EXCEPTION
      -- *** 取得エラーハンドラ ***
      WHEN NO_DATA_FOUND THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_bp_company_code                --取引先コード
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                      ,iv_token_value4  => lv_tab_name                           --テーブル名
                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                      ,iv_token_value5  => lv_col_name                           --項目名
                      ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                      ,iv_token_value6  => iv_bp_company_code                    --取引先コード
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ********************
    -- ***  拠点コード  ***
    -- ********************
--
    BEGIN
      SELECT hca.account_number  AS base_code
        INTO lv_base_code
        FROM hz_cust_accounts hca       --顧客マスタ
       WHERE hca.customer_class_code = cv_cust_class_base
         AND hca.account_number      = iv_base_code
      ;
    EXCEPTION
      -- *** 取得エラーハンドラ ***
      WHEN NO_DATA_FOUND THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_base_code                      --拠点コード
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                      ,iv_token_value4  => lv_tab_name                           --テーブル名
                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                      ,iv_token_value5  => lv_col_name                           --項目名
                      ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                      ,iv_token_value6  => iv_base_code                          --拠点コード
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ****************
    -- ***  納品日  ***
    -- ****************
--
    --納品日＞業務日付の場合は、納品日未来日付エラー
    IF ( id_delivery_date > gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_dlv_date_chk_err
                    ,iv_token_name1   => cv_tkn_param1                            --パラメータ1(トークン)
                    ,iv_token_value1  => in_cnt                                   --行番号
                    ,iv_token_name2   => cv_tkn_param2                            --パラメータ2(トークン)
                    ,iv_token_value2  => iv_dlv_inv_num                           --納品伝票番号
                    ,iv_token_name3   => cv_tkn_param3                            --パラメータ3(トークン)
                    ,iv_token_value3  => in_line_number                           --行No
                    ,iv_token_name4   => cv_tkn_param4                            --パラメータ4(トークン)
                    ,iv_token_value4  => TO_CHAR( id_delivery_date ,cv_fmt_std )  --納品日
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- **********************
    -- ***  カード売区分  ***
    -- **********************
--
    BEGIN
      SELECT flv.lookup_code  AS card_sale_class
        INTO lv_card_sale_class
        FROM fnd_lookup_values flv
       WHERE flv.language     = ct_user_lang
         AND flv.lookup_type  = cv_look_card_sale_class
         AND flv.lookup_code  = iv_card_sale_class
         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
         AND flv.enabled_flag = cv_enabled_flag_y
      ;
    EXCEPTION
      -- *** 取得エラーハンドラ ***
      WHEN NO_DATA_FOUND THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_lkp_code                       --クイックコード
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cd_sale_cls                    --カード売区分
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                      ,iv_token_value4  => lv_tab_name                           --テーブル名
                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                      ,iv_token_value5  => lv_col_name                           --項目名
                      ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                      ,iv_token_value6  => iv_card_sale_class                    --カード売区分
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
    END;
--
    -- ********************************************
    -- ***  伊藤園顧客コード／取引先顧客コード  ***
    -- ********************************************
--
    --伊藤園顧客コードが設定されている場合
    IF ( iv_customer_code IS NOT NULL ) THEN
--
      --伊藤園顧客コードをそのままセット
      lv_customer_code := iv_customer_code;
--
    --取引先顧客コードが設定されている場合
    ELSIF ( iv_bp_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- 伊藤園顧客コード取得
      ------------------------------------
      BEGIN
        SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N27) */
               xca.customer_code     AS customer_code    -- 伊藤園顧客コード
          INTO lv_customer_code
          FROM xxcmm_cust_accounts    xca   -- 顧客追加情報
         WHERE xca.bp_customer_code = iv_bp_customer_code
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_bp_cust_code                   --取引先顧客コード
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --顧客マスタ
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --取引先顧客コード
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        --
        -- *** 複数件レコード存在エラーハンドラ ***
        WHEN TOO_MANY_ROWS THEN
            --キー情報の編集処理
            lv_tab_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_cust_mst                     --顧客マスタ
                           );
            lv_col_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_bp_cust_code                 --取引先顧客コード
                           );
            --
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_overlap_err
                          ,iv_token_name1   => cv_tkn_param1                       --パラメータ1(トークン)
                          ,iv_token_value1  => in_cnt                              --行番号
                          ,iv_token_name2   => cv_tkn_param2                       --パラメータ2(トークン)
                          ,iv_token_value2  => iv_dlv_inv_num                      --納品伝票番号
                          ,iv_token_name3   => cv_tkn_param3                       --パラメータ3(トークン)
                          ,iv_token_value3  => in_line_number                      --行No
                          ,iv_token_name4   => cv_tkn_table                        --テーブル名(トークン)
                          ,iv_token_value4  => lv_tab_name                         --テーブル名
                          ,iv_token_name5   => cv_tkn_column                       --項目名(トークン)
                          ,iv_token_value5  => lv_col_name                         --項目名
                          ,iv_token_name6   => cv_tkn_param4                       --パラメータ4(トークン)
                          ,iv_token_value6  => iv_bp_customer_code                 --取引先顧客コード
                         );
            --
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            ov_retcode := cv_status_warn;
      END;
--
    --上記以外の場合は、条件付き必須チェックエラー
    ELSE
--
      --キー情報の編集処理
      lv_key_info1 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_cust_code                     --伊藤園顧客コード
                      );
      lv_key_info2 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_bp_cust_code                  --取引先顧客コード
                      );
      lv_key_info  := lv_key_info1 || cv_msg_comma || lv_key_info2;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_req_cond_err
                    ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                    ,iv_token_value1  => in_cnt                                --行番号
                    ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                    ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                    ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                    ,iv_token_value3  => in_line_number                        --行No
                    ,iv_token_name4   => cv_tkn_key_data                       --キー情報(トークン)
                    ,iv_token_value4  => lv_key_info                           --キー情報
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
--
    END IF;
--
    --伊藤園顧客コードが取得できる場合
    IF ( lv_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- 顧客マスタ情報取得
      ------------------------------------
      BEGIN
        SELECT hca.account_number          AS conv_customer_code    -- 変換後顧客コード
              ,CASE
                 WHEN ld_process_month > ld_delivery_month THEN
                   xca.past_sale_base_code
                 ELSE
                   xca.sale_base_code
               END                         AS sales_base_code       -- 売上拠点コード
              ,xch.cash_receiv_base_code   AS cash_receiv_base_code -- 入金拠点コード
              ,xch.bill_tax_round_rule     AS bill_tax_round_rule   -- 税金－端数処理
              ,xca.offset_cust_code        AS offset_cust_code      -- 相殺用顧客コード
              ,xca.business_low_type       AS cust_gyotai_sho       -- 業態（小分類）
              ,hp.duns_number_c            AS customer_status       -- 顧客ステータス
          INTO ov_conv_customer_code
              ,ov_sales_base_code
              ,ov_receiv_base_code
              ,ov_bill_tax_round_rule
              ,ov_offset_cust_code
              ,ov_cust_gyotai_sho
              ,lv_customer_status
          FROM hz_cust_accounts       hca   -- 顧客マスタ
              ,hz_parties             hp    -- パーティ
              ,xxcmm_cust_accounts    xca   -- 顧客追加情報
              ,xxcos_cust_hierarchy_v xch   -- 顧客階層ビュー
         WHERE hca.party_id            = hp.party_id
           AND hca.cust_account_id     = xca.customer_id
           AND xch.ship_account_number = hca.account_number
           AND hca.customer_class_code IN ( cv_cust_class_cust   --顧客
                                          , cv_cust_class_user   --上様
                                          )
           AND hca.account_number      = lv_customer_code
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_code                      --伊藤園顧客コード
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_mst_chk_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --テーブル名
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --項目名
                        ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value6  => lv_customer_code                      --伊藤園顧客コード
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
    --変換後顧客コードが取得できる場合
    IF ( ov_conv_customer_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- 顧客ステータスチェック
      ------------------------------------
      BEGIN
        SELECT flv.meaning   AS customer_status
          INTO lv_customer_status_chk
          FROM fnd_lookup_values flv
         WHERE flv.language     = ct_user_lang
           AND flv.lookup_type  = cv_look_cus_sts
           AND flv.lookup_code  LIKE cv_look_cus_sts_a01
           AND flv.meaning      = lv_customer_status
           AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
           AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
           AND flv.enabled_flag = cv_enabled_flag_y
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_cust_sts_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value4  => ov_conv_customer_code                 --変換後顧客コード
                        ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                        ,iv_token_value5  => lv_customer_status                    --顧客ステータス
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
      END;
--
      ------------------------------------
      -- 売上拠点コードチェック
      ------------------------------------
      -- 拠点コードが取得できる場合
      IF ( lv_base_code IS NOT NULL ) THEN
        --拠点コードと売上拠点コードが不一致の場合はエラー
        IF ( lv_base_code != ov_sales_base_code ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_sale_base_code_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value4  => ov_conv_customer_code                 --変換後顧客コード
                        ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                        ,iv_token_value5  => ov_sales_base_code                    --売上拠点コード
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      ------------------------------------
      -- 相殺用顧客コードチェック
      ------------------------------------
      --相殺用顧客コードがNULLの場合はエラー
      IF ( ov_offset_cust_code IS NULL ) THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_offset_cust_code               --相殺用顧客コード
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_null_or_get_data_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                      ,iv_token_value4  => lv_tab_name                           --顧客マスタ
                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                      ,iv_token_value5  => lv_col_name                           --相殺用顧客コード
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
--
      ELSE
--
        ------------------------------------
        -- 取引先コードチェック
        ------------------------------------
        --取引先コードと相殺用顧客コードが不一致の場合はエラー
        IF ( lv_bp_company_code != ov_offset_cust_code ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_bp_com_code_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value4  => lv_bp_company_code                    --取引先コード
                        ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                        ,iv_token_value5  => ov_offset_cust_code                   --相殺用顧客コード
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      ------------------------------------
      -- 担当営業員取得
      ------------------------------------
      BEGIN
        SELECT xsv.employee_number  AS employee_number
          INTO ov_employee_number
          FROM xxcos_salesreps_v  xsv    --担当営業員ビュー
         WHERE xsv.account_number = ov_conv_customer_code
           AND id_delivery_date  >= NVL( xsv.effective_start_date ,id_delivery_date )
           AND id_delivery_date  <= NVL( xsv.effective_end_date ,gd_max_date )
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_cust_mst                       --顧客マスタ
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_employee_code                  --担当営業員
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --顧客マスタ
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --担当営業員
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        --
        -- *** 複数件レコード存在エラーハンドラ ***
        WHEN TOO_MANY_ROWS THEN
            --キー情報の編集処理
            lv_tab_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_cust_mst                     --顧客マスタ
                           );
            lv_col_name := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_name
                            ,iv_name        => cv_msg_employee_code                --担当営業員
                           );
            --
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_overlap_err
                          ,iv_token_name1   => cv_tkn_param1                       --パラメータ1(トークン)
                          ,iv_token_value1  => in_cnt                              --行番号
                          ,iv_token_name2   => cv_tkn_param2                       --パラメータ2(トークン)
                          ,iv_token_value2  => iv_dlv_inv_num                      --納品伝票番号
                          ,iv_token_name3   => cv_tkn_param3                       --パラメータ3(トークン)
                          ,iv_token_value3  => in_line_number                      --行No
                          ,iv_token_name4   => cv_tkn_table                        --テーブル名(トークン)
                          ,iv_token_value4  => lv_tab_name                         --テーブル名
                          ,iv_token_name5   => cv_tkn_column                       --項目名(トークン)
                          ,iv_token_value5  => lv_col_name                         --項目名
                          ,iv_token_name6   => cv_tkn_param4                       --パラメータ4(トークン)
                          ,iv_token_value6  => NULL                                --担当営業員
                         );
            --
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
-- Ver.1.2 DEL START
    -- ********************
    -- ***  消費税区分  ***
    -- ********************
--
--    BEGIN
--      SELECT flv.attribute1   AS tax_class
--        INTO lv_tax_class
--        FROM fnd_lookup_values flv
--       WHERE flv.language     = ct_user_lang
--         AND flv.lookup_type  = cv_look_tax_class
--         AND flv.attribute1   = iv_tax_class
--         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
--         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
--         AND flv.enabled_flag = cv_enabled_flag_y
--      ;
--    EXCEPTION
--     -- *** 取得エラーハンドラ ***
--      WHEN NO_DATA_FOUND THEN
--       --キー情報の編集処理
--        lv_tab_name := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_appl_short_name
--                        ,iv_name        => cv_msg_lkp_code                       --クイックコード
--                       );
--        lv_col_name := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_appl_short_name
--                        ,iv_name        => cv_msg_tax_class                      --消費税区分
--                       );
--        --
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application   => cv_xxcos_appl_short_name
--                      ,iv_name          => cv_msg_mst_chk_err
--                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
--                      ,iv_token_value1  => in_cnt                                --行番号
--                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
--                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
--                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
--                      ,iv_token_value3  => in_line_number                        --行No
--                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
--                      ,iv_token_value4  => lv_tab_name                           --テーブル名
--                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
--                      ,iv_token_value5  => lv_col_name                           --項目名
--                      ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
--                      ,iv_token_value6  => iv_tax_class                          --消費税区分
--                     );
--        --
--        FND_FILE.PUT_LINE(
--          which  => FND_FILE.OUTPUT
--         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--        );
--        ov_retcode := cv_status_warn;
--    END;
--
--    --消費税区分が取得できる場合
--    IF ( lv_tax_class IS NOT NULL ) THEN
--
--      ------------------------------------
--      -- 消費税情報取得
--      ------------------------------------
--      BEGIN
--        SELECT xtv.tax_rate   AS tax_rate                -- 消費税率
--              ,xtv.tax_code   AS tax_code                -- 消費税コード
--              ,xtv.tax_class  AS consumption_tax_class   -- 販売実績連携消費税区分
--          INTO on_tax_rate
--              ,ov_tax_code
--              ,ov_consumption_tax_class
--          FROM xxcos_tax_v  xtv   -- 消費税view
--         WHERE xtv.hht_tax_class     = lv_tax_class
--           AND xtv.set_of_books_id   = gn_bks_id
--           AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
--           AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
--        ;
--      EXCEPTION
--        -- *** 取得エラーハンドラ ***
--        WHEN NO_DATA_FOUND THEN
--          --キー情報の編集処理
--          lv_tab_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_appl_short_name
--                          ,iv_name        => cv_msg_tax_view                       --消費税view
--                         );
--          lv_col_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_appl_short_name
--                          ,iv_name        => cv_msg_tax_rate                       --消費税率
--                         );
--          --
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application   => cv_xxcos_appl_short_name
--                        ,iv_name          => cv_msg_null_or_get_data_err
--                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
--                       ,iv_token_value1  => in_cnt                                --行番号
--                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
--                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
--                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
--                        ,iv_token_value3  => in_line_number                        --行No
--                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
--                        ,iv_token_value4  => lv_tab_name                           --テーブル名
--                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
--                        ,iv_token_value5  => lv_col_name                           --項目名
--                       );
--          --
--          FND_FILE.PUT_LINE(
--            which  => FND_FILE.OUTPUT
--           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--          );
--          ov_retcode := cv_status_warn;
--      END;
--
--    END IF;
--
-- Ver.1.2 DEL END
--
  -- ********************************************
  -- ***  伊藤園品名コード／取引先品名コード  ***
  -- ********************************************
--
    --伊藤園品名コードが設定されている場合
    IF ( iv_item_code IS NOT NULL ) THEN
--
      --伊藤園品名コードをそのままセット
      lv_item_code := iv_item_code;
--
    --取引先品名コードが設定されている場合
    ELSIF ( iv_bp_item_code IS NOT NULL ) THEN
--
      --取引先コードが取得できる場合
      IF ( lv_bp_company_code IS NOT NULL ) THEN
--
        --取引先コードチェックがOKの場合
        IF ( lv_bp_company_code = ov_offset_cust_code ) THEN
--
          ------------------------------------
          -- 伊藤園品名コード取得
          ------------------------------------
          BEGIN
            SELECT xbpi.item_code    AS item_code  -- 伊藤園品名コード
              INTO lv_item_code
              FROM xxcmm_bus_partner_items   xbpi   -- 取引先品目アドオン
             WHERE xbpi.bp_company_code  = lv_bp_company_code
               AND xbpi.bp_item_code     = iv_bp_item_code
               AND xbpi.enabled_flag     = cv_enabled_flag_y
            ;
          EXCEPTION
            -- *** 取得エラーハンドラ ***
            WHEN NO_DATA_FOUND THEN
              --キー情報の編集処理
              lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcos_appl_short_name
                              ,iv_name        => cv_msg_bp_item_mst                    --取引先品目アドオン
                             );
              lv_col_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_xxcos_appl_short_name
                              ,iv_name        => cv_msg_bp_item_code                   --取引先品名コード
                             );
              --
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => cv_xxcos_appl_short_name
                            ,iv_name          => cv_msg_mst_chk_err
                            ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                            ,iv_token_value1  => in_cnt                                --行番号
                            ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                            ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                            ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                            ,iv_token_value3  => in_line_number                        --行No
                            ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                            ,iv_token_value4  => lv_tab_name                           --テーブル名
                            ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                            ,iv_token_value5  => lv_col_name                           --項目名
                            ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                            ,iv_token_value6  => iv_bp_item_code                       --取引先品名コード
                           );
              --
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg --ユーザー・エラーメッセージ
              );
              ov_retcode := cv_status_warn;
          END;
--
        END IF;
--
      END IF;
--
    --上記以外の場合は、条件付き必須チェックエラー
    ELSE
--
      --キー情報の編集処理
      lv_key_info1 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_item_code                     --伊藤園品名コード
                      );
      lv_key_info2 := xxccp_common_pkg.get_msg(
                        iv_application => cv_xxcos_appl_short_name
                       ,iv_name        => cv_msg_bp_item_code                  --取引先品名コード
                      );
      lv_key_info  := lv_key_info1 || cv_msg_comma || lv_key_info2;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_req_cond_err
                    ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                    ,iv_token_value1  => in_cnt                                --行番号
                    ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                    ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                    ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                    ,iv_token_value3  => in_line_number                        --行No
                    ,iv_token_name4   => cv_tkn_key_data                       --キー情報(トークン)
                    ,iv_token_value4  => lv_key_info                           --キー情報
                   );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
--
    END IF;
--
    --伊藤園品名コードが取得できる場合
    IF ( lv_item_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- 品目マスタ情報取得
      ------------------------------------
      BEGIN
        SELECT iimb.item_no                  AS conv_item_code  -- 変換後品名コード
              ,msib.primary_unit_of_measure  AS uom_code        -- 基準単位
              ,CASE
                 WHEN TO_DATE( iimb.attribute9, cv_fmt_std ) > id_delivery_date THEN
                   TO_NUMBER(iimb.attribute7)  -- 営業原価(旧)
                 ELSE
                   TO_NUMBER(iimb.attribute8)  -- 営業原価(新)
               END                           AS business_cost   -- 営業原価
              ,iimb.attribute26              AS sales_target    -- 売上対象区分
              ,ximb.item_status              AS item_status     -- 品目ステータス
          INTO ov_conv_item_code
              ,ov_uom_code
              ,on_business_cost
              ,lv_sales_target
              ,lv_item_status
          FROM ic_item_mst_b         iimb   -- OPM品目マスタ
              ,mtl_system_items_b    msib   -- DISC品目マスタ
              ,xxcmm_system_items_b  ximb   -- DISC品目アドオン
         WHERE iimb.item_no          = msib.segment1
           AND msib.organization_id  = gn_org_id
           AND iimb.item_no          = ximb.item_code
           AND iimb.item_no          = lv_item_code
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_item_mst                       --品目マスタ
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_item_code                      --伊藤園品名コード
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_mst_chk_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --テーブル名
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --項目名
                        ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value6  => lv_item_code                          --伊藤園品名コード
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
    --変換後品名コードが取得できる場合
    IF ( ov_conv_item_code IS NOT NULL ) THEN
--
      ------------------------------------
      -- 売上対象区分チェック
      ------------------------------------
      --売上対象外の場合はエラー
      IF ( lv_sales_target = cv_sales_target_off ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_sales_target_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                      ,iv_token_value4  => ov_conv_item_code                     --変換後品名コード
                      ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                      ,iv_token_value5  => lv_sales_target                       --売上対象区分
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      END IF;
--
      ------------------------------------
      -- 品目ステータスチェック
      ------------------------------------
      BEGIN
        SELECT flv.meaning  AS item_status
          INTO ov_item_status
          FROM fnd_lookup_values flv
         WHERE flv.language     = ct_user_lang
           AND flv.lookup_type  = cv_look_item_status
           AND flv.lookup_code  LIKE cv_look_item_sts_a01
           AND flv.meaning      = lv_item_status
           AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
           AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
           AND flv.enabled_flag = cv_enabled_flag_y
        ;
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_item_sts_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                        ,iv_token_value4  => ov_conv_item_code                     --変換後品名コード
                        ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                        ,iv_token_value5  => lv_item_status                        --品目ステータス
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
      END;
--
    END IF;
--
-- Ver.1.2 ADD START
    -- ********************
    -- ***  消費税区分  ***
    -- ********************
--
    BEGIN
      SELECT flv.attribute1   AS tax_class
        INTO lv_tax_class
        FROM fnd_lookup_values flv
       WHERE flv.language     = ct_user_lang
         AND flv.lookup_type  = cv_look_tax_class
         AND flv.attribute1   = iv_tax_class
         AND gd_process_date >= NVL( flv.start_date_active ,gd_process_date )
         AND gd_process_date <= NVL( flv.end_date_active ,gd_max_date )
         AND flv.enabled_flag = cv_enabled_flag_y
      ;
    EXCEPTION
     -- *** 取得エラーハンドラ ***
      WHEN NO_DATA_FOUND THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_lkp_code                       --クイックコード
                       );
        lv_col_name := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_name
                        ,iv_name        => cv_msg_tax_class                      --消費税区分
                       );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_xxcos_appl_short_name
                      ,iv_name          => cv_msg_mst_chk_err
                      ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                      ,iv_token_value1  => in_cnt                                --行番号
                      ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                      ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                      ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                      ,iv_token_value3  => in_line_number                        --行No
                      ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                      ,iv_token_value4  => lv_tab_name                           --テーブル名
                      ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                      ,iv_token_value5  => lv_col_name                           --項目名
                      ,iv_token_name6   => cv_tkn_param4                         --パラメータ4(トークン)
                      ,iv_token_value6  => iv_tax_class                          --消費税区分
                     );
        --
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg           --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
    END;
--
    --消費税区分が取得できる場合
    IF ( lv_tax_class IS NOT NULL ) THEN
--
      ------------------------------------
      -- 消費税情報取得
      ------------------------------------
      BEGIN
        -- 消費税区分が非課税である場合
        IF ( lv_tax_class = cv_tax_class_tax ) THEN
           SELECT xtv.tax_rate   AS tax_rate                -- 消費税率
                 ,xtv.tax_code   AS tax_code                -- 消費税コード
           INTO   on_tax_rate
                 ,ov_tax_code
           FROM   xxcos_tax_v  xtv
           WHERE  xtv.hht_tax_class  = cv_tax_class_tax
           AND xtv.set_of_books_id   = gn_bks_id
           AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
           AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
           ;
-- Ver.1.3 INS START
           lv_retcode := cv_status_normal;
-- Ver.1.3 INS START
        -- 
        ELSE
        
          -- 品目別消費税率取得関数コール
          xxcos_common_pkg.get_tax_rate_info(
            iv_item_code                    => ov_conv_item_code               -- 変換後品目コード
           ,id_base_date                    => id_delivery_date                -- 基準日（納品日）
           ,ov_class_for_variable_tax       => lv_class_for_variable_tax       -- 軽減税率用税種別
           ,ov_tax_name                     => lv_tax_name                     -- 税率キー名称
           ,ov_tax_description              => lv_tax_description              -- 摘要
           ,ov_tax_histories_code           => lv_tax_histories_code           -- 消費税履歴コード
           ,ov_tax_histories_description    => lv_tax_histories_description    -- 消費税履歴名称
           ,od_start_date                   => ld_tax_start_date               -- 税率キー_開始日
           ,od_end_date                     => ld_tax_end_date                 -- 税率キー_終了日
           ,od_start_date_histories         => ld_tax_start_date_histories     -- 消費税履歴_開始日
           ,od_end_date_histories           => ld_tax_end_date_histories       -- 消費税履歴_終了日
           ,on_tax_rate                     => on_tax_rate                     -- 税率
           ,ov_tax_class_suppliers_outside  => lv_tax_class_suppliers_outside  -- 税区分_仕入外税
           ,ov_tax_class_suppliers_inside   => lv_tax_class_suppliers_inside   -- 税区分_仕入内税
           ,ov_tax_class_sales_outside      => lv_tax_class_sales_outside      -- 税区分_売上外税
           ,ov_tax_class_sales_inside       => lv_tax_class_sales_inside       -- 税区分_売上内税
           ,ov_errbuf                       => lv_errbuf                       -- エラー・メッセージエラー       #固定#
           ,ov_retcode                      => lv_retcode                      -- リターン・コード               #固定#
           ,ov_errmsg                       => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
          );
          
        -- 税金コード設定
           CASE lv_tax_class WHEN cv_tax_class_out      THEN                 -- 外税の場合
                               ov_tax_code  := lv_tax_class_sales_outside;
                             WHEN cv_tax_class_ins_slip THEN                 -- 内税（伝票課税）
                               ov_tax_code  := lv_tax_class_sales_inside;
                             WHEN cv_tax_class_ins_bid  THEN                 -- 内税（単価込み）
                               ov_tax_code  := lv_tax_class_sales_inside;
                             ELSE NULL;
           END CASE;
          
        END IF;
        
        -- 戻り値チェック(共通関数)
        IF ( lv_retcode = cv_status_error ) THEN
          --エラーメッセージの編集処理
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_common_pkg_err
                          ,iv_token_name1   => cv_tkn_common
                          ,iv_token_value1  => in_cnt                                --行番号
                          ,iv_token_name2   => cv_tkn_common_name
                          ,iv_token_value2  => cv_common_pkg_name                    --共通関数名
                          ,iv_token_name3   => cv_tkn_common_info
                          ,iv_token_value3  => lv_errmsg                             --共通関数エラーメッセージ
                          );
          
          RAISE global_api_expt;
        
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --キー情報の編集処理
          SELECT dtc.comments     AS view_name
          INTO   lv_tab_name
          FROM   dba_tab_comments  dtc
          WHERE  dtc.table_name = cv_view_name                           --XXCOS品目別消費税率ビュー
          ;
          
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_tax_rate                       --消費税率
                         );
--
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_appl_short_name
                          ,iv_name          => cv_msg_null_or_get_data_err
                          ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                          ,iv_token_value1  => in_cnt                                --行番号
                          ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                          ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                          ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                          ,iv_token_value3  => in_line_number                        --行No
                          ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                          ,iv_token_value4  => lv_tab_name                           --テーブル名
                          ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                          ,iv_token_value5  => lv_col_name                           --項目名
                         );
--
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg                                                      --ユーザー・エラーメッセージ
          );
          
          ov_retcode := cv_status_warn;
        
        END IF;
--
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_lkp_code                       --消費税view
                         );
          lv_col_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_tax_rate                       --消費税率
                         );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --テーブル名
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --項目名
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
      END;
--
      BEGIN
        
        -- 品目別消費税率取得関数で警告または異常が発生していない場合
        IF ( lv_retcode NOT IN ( cv_status_error,cv_status_warn )) THEN
          -- 販売実績連携消費税区分の取得
          SELECT xtv.tax_class  AS consumption_tax_class   -- 販売実績連携消費税区分
            INTO ov_consumption_tax_class
            FROM xxcos_tax_v  xtv                          -- 消費税view
           WHERE xtv.hht_tax_class     = lv_tax_class
             AND xtv.set_of_books_id   = gn_bks_id
-- Ver.1.3 Del START
--             AND xtv.tax_rate          = on_tax_rate
-- Ver.1.3 Del END
             AND id_delivery_date     >= NVL( xtv.start_date_active ,id_delivery_date )
             AND id_delivery_date     <= NVL( xtv.end_date_active ,gd_max_date )
          ;
          
        END IF;
--
      EXCEPTION
        -- *** 取得エラーハンドラ ***
        WHEN NO_DATA_FOUND THEN
          --キー情報の編集処理
          lv_tab_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_name
                          ,iv_name        => cv_msg_lkp_code                       --消費税view
                         );

          SELECT  dcc.comments       AS col_coment     -- 項目名
            INTO  lv_col_name
            FROM  dba_col_comments  dcc
           WHERE  dcc.table_name = cv_tax_view_txt
             AND  dcc.column_name = cv_tax_class_txt                                    --販売実績連携消費税区分
           ;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_xxcos_appl_short_name
                        ,iv_name          => cv_msg_null_or_get_data_err
                        ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                        ,iv_token_value1  => in_cnt                                --行番号
                        ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                        ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                        ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                        ,iv_token_value3  => in_line_number                        --行No
                        ,iv_token_name4   => cv_tkn_table                          --テーブル名(トークン)
                        ,iv_token_value4  => lv_tab_name                           --テーブル名
                        ,iv_token_name5   => cv_tkn_column                         --項目名(トークン)
                        ,iv_token_value5  => lv_col_name                           --項目名
                       );
          --
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
--
      END;
--
    END IF;
-- Ver.1.2 ADD START
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
  END get_master_data;
--
  /**********************************************************************************
   * Procedure Name   : security_check
   * Description      : セキュリティチェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE security_check(
     in_cnt                IN  NUMBER    -- データカウンタ
    ,iv_dlv_inv_num        IN  VARCHAR2  -- 納品伝票番号
    ,in_line_number        IN  NUMBER    -- 明細番号
    ,iv_customer_code      IN  VARCHAR2  -- 顧客コード
    ,iv_sales_base_code    IN VARCHAR2   -- 売上拠点コード
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'security_check'; -- プログラム名
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
    lv_key_info    VARCHAR2(5000);  --key情報
    ln_flg         NUMBER;          --ローカルフラグ
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
    -- 初期化
    ln_flg := 0;
--
    <<sec_chk_loop>>
    FOR i IN 1 .. gr_g_login_base_info.COUNT LOOP
      IF ( gr_g_login_base_info(i) = iv_sales_base_code ) THEN
        ln_flg := 1;
      END IF;
    END LOOP sec_chk_loop;
--
    --売上拠点コードと自拠点が相違ある場合
    IF ( ln_flg = 0 ) THEN
      RAISE global_security_check_expt;
    END IF;
--
  EXCEPTION
    -- *** セキュリティチェックエラーハンドラ ***
    WHEN global_security_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_xxcos_appl_short_name
                    ,iv_name          => cv_msg_security_chk_err
                    ,iv_token_name1   => cv_tkn_param1                         --パラメータ1(トークン)
                    ,iv_token_value1  => in_cnt                                --行番号
                    ,iv_token_name2   => cv_tkn_param2                         --パラメータ2(トークン)
                    ,iv_token_value2  => iv_dlv_inv_num                        --納品伝票番号
                    ,iv_token_name3   => cv_tkn_param3                         --パラメータ3(トークン)
                    ,iv_token_value3  => in_line_number                        --行No
                    ,iv_token_name4   => cv_tkn_param4                         --パラメータ4(トークン)
                    ,iv_token_value4  => iv_customer_code                      --変換後顧客コード
                    ,iv_token_name5   => cv_tkn_key_data                       --キー情報(トークン)
                    ,iv_token_value5  => iv_sales_base_code                    --売上拠点コード
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END security_check;
--
  /**********************************************************************************
   * Procedure Name   : set_sales_bp_data
   * Description      : 取引先販売実績データ設定処理(A-8)
   ***********************************************************************************/
  PROCEDURE set_sales_bp_data(
     in_cnt                     IN  NUMBER      -- データカウンタ
    ,iv_bp_company_code         IN  VARCHAR2    -- 取引先コード
    ,iv_dlv_inv_num             IN  VARCHAR2    -- 納品伝票番号
    ,iv_base_code               IN  VARCHAR2    -- 拠点コード
    ,id_delivery_date           IN  DATE        -- 納品日
    ,iv_card_sale_class         IN  VARCHAR2    -- カード売区分
    ,iv_customer_code           IN  VARCHAR2    -- 伊藤園顧客コード
    ,iv_bp_customer_code        IN  VARCHAR2    -- 取引先顧客コード
    ,iv_tax_class               IN  VARCHAR2    -- 消費税区分
    ,in_line_number             IN  NUMBER      -- 明細番号
    ,iv_item_code               IN  VARCHAR2    -- 伊藤園品名コード
    ,iv_bp_item_code            IN  VARCHAR2    -- 取引先品名コード
    ,in_dlv_qty                 IN  NUMBER      -- 数量
    ,in_unit_price              IN  NUMBER      -- 売単価
    ,in_cash_and_card           IN  NUMBER      -- 現金・カード併用額
    ,id_data_created            IN  DATE        -- データ作成日時
    ,iv_conv_customer_code      IN  VARCHAR2    -- 変換後顧客コード
    ,iv_offset_cust_code        IN  VARCHAR2    -- 相殺用顧客コード
    ,iv_employee_number         IN  VARCHAR2    -- 担当営業員
    ,iv_conv_item_code          IN  VARCHAR2    -- 変換後品名コード
    ,iv_item_status             IN  VARCHAR2    -- 品目ステータス
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sales_bp_data'; -- プログラム名
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
    --シーケンス用
    lt_sales_bus_partners_id   xxcos_sales_bus_partners.sales_bus_partners_id%TYPE;     --取引先販売実績ID
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
    ------------------------------------
    -- 取引先販売実績ID取得
    ------------------------------------
    SELECT xxcos_sales_bus_partners_s01.NEXTVAL  AS sales_bus_partners_id
      INTO lt_sales_bus_partners_id
      FROM DUAL
    ;
    --カウント
    gn_bp_cnt := gn_bp_cnt + 1;
--
  -- **************************************
  -- ***  取引先販売実績データ設定処理  ***
  -- **************************************
--
    gr_sales_bp_data(gn_bp_cnt).sales_bus_partners_id             := lt_sales_bus_partners_id;    --取引先販売実績ID
    gr_sales_bp_data(gn_bp_cnt).bp_company_code                   := iv_bp_company_code;          --取引先コード
    gr_sales_bp_data(gn_bp_cnt).dlv_invoice_number                := iv_dlv_inv_num;              --納品伝票番号
    gr_sales_bp_data(gn_bp_cnt).base_code                         := iv_base_code;                --拠点コード
    gr_sales_bp_data(gn_bp_cnt).delivery_date                     := id_delivery_date;            --納品日
    gr_sales_bp_data(gn_bp_cnt).card_sale_class                   := iv_card_sale_class;          --カード売区分
    gr_sales_bp_data(gn_bp_cnt).customer_code                     := iv_customer_code;            --伊藤園顧客コード
    gr_sales_bp_data(gn_bp_cnt).bp_customer_code                  := iv_bp_customer_code;         --取引先顧客コード
    gr_sales_bp_data(gn_bp_cnt).tax_class                         := iv_tax_class;                --消費税区分
    gr_sales_bp_data(gn_bp_cnt).line_number                       := in_line_number;              --明細番号
    gr_sales_bp_data(gn_bp_cnt).item_code                         := iv_item_code;                --伊藤園品名コード
    gr_sales_bp_data(gn_bp_cnt).bp_item_code                      := iv_bp_item_code;             --取引先品名コード
    gr_sales_bp_data(gn_bp_cnt).dlv_qty                           := in_dlv_qty;                  --数量
    gr_sales_bp_data(gn_bp_cnt).unit_price                        := in_unit_price;               --売単価
    gr_sales_bp_data(gn_bp_cnt).cash_and_card                     := in_cash_and_card;            --現金・カード併用額
    gr_sales_bp_data(gn_bp_cnt).data_created                      := id_data_created;             --データ作成日時
    gr_sales_bp_data(gn_bp_cnt).conv_customer_code                := iv_conv_customer_code;       --変換後顧客コード
    gr_sales_bp_data(gn_bp_cnt).offset_cust_code                  := iv_offset_cust_code;         --相殺用顧客コード
    gr_sales_bp_data(gn_bp_cnt).employee_number                   := iv_employee_number;          --担当営業員
    gr_sales_bp_data(gn_bp_cnt).conv_item_code                    := iv_conv_item_code;           --変換後品名コード
    gr_sales_bp_data(gn_bp_cnt).item_status                       := iv_item_status;              --品目ステータス
    gr_sales_bp_data(gn_bp_cnt).csv_file_name                     := gv_csv_file_name;            --CSVファイル名
    gr_sales_bp_data(gn_bp_cnt).created_by                        := cn_created_by;               --作成者
    gr_sales_bp_data(gn_bp_cnt).creation_date                     := cd_creation_date;            --作成日
    gr_sales_bp_data(gn_bp_cnt).last_updated_by                   := cn_last_updated_by;          --最終更新者
    gr_sales_bp_data(gn_bp_cnt).last_update_date                  := cd_last_update_date;         --最終更新日
    gr_sales_bp_data(gn_bp_cnt).last_update_login                 := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
    gr_sales_bp_data(gn_bp_cnt).request_id                        := cn_request_id;               --要求ID
    gr_sales_bp_data(gn_bp_cnt).program_application_id            := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_sales_bp_data(gn_bp_cnt).program_id                        := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_sales_bp_data(gn_bp_cnt).program_update_date               := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
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
  END set_sales_bp_data;
--
  /**********************************************************************************
   * Procedure Name   : set_sales_data
   * Description      : 販売実績データ設定処理(A-9)
   ***********************************************************************************/
  PROCEDURE set_sales_data(
     in_cnt                     IN  NUMBER      -- データカウンタ
    ,iv_bp_company_code         IN  VARCHAR2    -- 取引先コード
    ,iv_dlv_inv_num             IN  VARCHAR2    -- 納品伝票番号
    ,iv_base_code               IN  VARCHAR2    -- 拠点コード
    ,id_delivery_date           IN  DATE        -- 納品日
    ,iv_card_sale_class         IN  VARCHAR2    -- カード売区分
    ,iv_customer_code           IN  VARCHAR2    -- 顧客コード
    ,iv_tax_class               IN  VARCHAR2    -- 消費税区分
    ,in_line_number             IN  NUMBER      -- 明細番号
    ,iv_item_code               IN  VARCHAR2    -- 品名コード
    ,in_dlv_qty                 IN  NUMBER      -- 数量
    ,in_unit_price              IN  NUMBER      -- 売単価
    ,iv_sales_base_code         IN  VARCHAR2    -- 売上拠点コード
    ,iv_receiv_base_code        IN  VARCHAR2    -- 入金拠点コード
    ,iv_bill_tax_round_rule     IN  VARCHAR2    -- 税金－端数処理
    ,iv_offset_cust_code        IN  VARCHAR2    -- 相殺用顧客コード
    ,iv_results_employee_code   IN  VARCHAR2    -- 成績計上者コード
    ,iv_cust_gyotai_sho         IN  VARCHAR2    -- 業態（小分類）
    ,in_tax_rate                IN  NUMBER      -- 消費税率
    ,iv_tax_code                IN  VARCHAR2    -- 税金コード
    ,iv_consumption_tax_class   IN  VARCHAR2    -- 消費税区分
    ,iv_uom_code                IN  VARCHAR2    -- 基準単位
    ,in_business_cost           IN  NUMBER      -- 営業原価
    ,in_cash_and_card           IN  NUMBER      -- 現金・カード併用額
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sales_data'; -- プログラム名
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
    ln_tax_data               NUMBER;                                                  --税込額計算用
    lt_sale_amount            xxcos_sales_exp_lines.sale_amount%TYPE;                  --売上金額
    lt_stand_unit_price_excl  xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --税抜基準単価
    lt_pure_amount            xxcos_sales_exp_lines.pure_amount%TYPE;                  --本体金額
    lt_tax_amount             xxcos_sales_exp_lines.tax_amount%TYPE;                   --消費税金額
    ln_amount                 NUMBER;                                                  --金額計算用変数
    lt_red_black_flag1        xxcos_sales_exp_lines.red_black_flag%TYPE;               --赤黒フラグ
    lt_red_black_flag2        xxcos_sales_exp_lines.red_black_flag%TYPE;               --赤黒フラグ（相殺）
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
    -- ローカル変数の初期化
    ln_tax_data               := 0;   --税込額計算用
    lt_sale_amount            := 0;   --売上金額
    lt_stand_unit_price_excl  := 0;   --税抜基準単価
    lt_pure_amount            := 0;   --本体金額
    lt_tax_amount             := 0;   --消費税金額
--
    --初回レコード、または前レコードと取引先コードか納品伝票番号が異なる場合
    IF ( gt_bp_com_code IS NULL ) OR
       ( gt_bp_com_code != iv_bp_company_code ) OR
       ( gt_dlv_inv_num != iv_dlv_inv_num ) THEN
--
      --金額合計の初期化
      gt_sale_amount_sum  := 0;  --売上金額合計
      gt_pure_amount_sum  := 0;  --本体金額合計
      gt_tax_amount_sum   := 0;  --消費税金額合計
      ------------------------------------
      -- 販売実績ヘッダID取得
      ------------------------------------
      SELECT xxcos_sales_exp_headers_s01.NEXTVAL  AS sales_exp_header_id1
        INTO gt_sales_exp_header_id1
        FROM DUAL
      ;
      --
      SELECT xxcos_sales_exp_headers_s01.NEXTVAL  AS sales_exp_header_id2
        INTO gt_sales_exp_header_id2
        FROM DUAL
      ;
      --ヘッダカウント
      gn_hed_cnt1 := gn_hed_cnt1 + 1;
      gn_hed_cnt2 := gn_hed_cnt2 + 1;
--
      ------------------------------------
      -- 取引先納品伝票番号取得
      ------------------------------------
      SELECT xxcos_dlv_inv_num_os_s01.NEXTVAL  AS dlv_invoice_number_os
        INTO gt_dlv_invoice_number_os
        FROM DUAL
      ;
    END IF;
--
    ------------------------------------
    -- 販売実績明細ID取得
    ------------------------------------
    SELECT xxcos_sales_exp_lines_s01.NEXTVAL  AS sales_exp_line_id1
      INTO gt_sales_exp_line_id1
      FROM DUAL
    ;
    --
    SELECT xxcos_sales_exp_lines_s01.NEXTVAL  AS sales_exp_line_id2
      INTO gt_sales_exp_line_id2
      FROM DUAL
    ;
    --明細カウント
    gn_line_cnt1 := gn_line_cnt1 + 1;
    gn_line_cnt2 := gn_line_cnt2 + 1;
--
    ------------------------------------
    --明細金額算出
    ------------------------------------
    --税込額計算用変数のセット
    ln_tax_data := ( ( 100 + in_tax_rate ) / 100 );
--
    --消費税区分が「非課税」の場合
    IF ( iv_tax_class = cv_tax_class_tax ) THEN
      --【売上金額】
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【税抜基準単価】
      lt_stand_unit_price_excl := in_unit_price;
      --【本体金額】
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【消費税金額】
      lt_tax_amount            := 0;
--
    --消費税区分が「外税」の場合
    ELSIF ( iv_tax_class = cv_tax_class_out ) THEN
--
      --【売上金額】
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【税抜基準単価】
      lt_stand_unit_price_excl := in_unit_price;
      --【本体金額】
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【消費税金額】
      lt_tax_amount            := ROUND( lt_pure_amount * ( ln_tax_data - 1 ) );
--
    --消費税区分が「内税（伝票課税）」の場合
    ELSIF ( iv_tax_class = cv_tax_class_ins_slip ) THEN
--
      --【売上金額】
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【税抜基準単価】
      lt_stand_unit_price_excl := in_unit_price;
      --【本体金額】
      lt_pure_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【消費税金額】
      lt_tax_amount            := ROUND( lt_pure_amount * ( ln_tax_data - 1 ) );
--
    --消費税区分が「内税（単価込み）」の場合
    ELSIF ( iv_tax_class = cv_tax_class_ins_bid ) THEN
--
      --【売上金額】
      lt_sale_amount           := TRUNC( in_unit_price * in_dlv_qty );
      --【税抜基準単価】
      lt_stand_unit_price_excl := ROUND( ( in_unit_price / ( 100 + in_tax_rate ) * 100 ) , 2 );
      --【本体金額】
      --本体金額（仮）
      ln_amount := ( in_unit_price * in_dlv_qty ) - ( ( in_unit_price * in_dlv_qty ) / ln_tax_data );
      --本体金額（仮）に端数がある場合
      IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
        --端数処理区分が「切り上げ」の場合
        IF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_up ) THEN
          IF ( SIGN (ln_amount) <> -1 ) THEN
            lt_pure_amount     := TRUNC( ( in_unit_price * in_dlv_qty ) - ( TRUNC( ln_amount ) + 1 ) );
          ELSE
            lt_pure_amount     := TRUNC( ( in_unit_price * in_dlv_qty ) - ( TRUNC( ln_amount ) - 1 ) );
          END IF;
        --端数処理区分が「切り捨て」の場合
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_down ) THEN
          lt_pure_amount       := TRUNC( ( in_unit_price * in_dlv_qty ) - TRUNC( ln_amount ) );
        --端数処理区分が「四捨五入」の場合
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_nearest ) THEN
          lt_pure_amount       := TRUNC( ( in_unit_price * in_dlv_qty ) - ROUND( ln_amount ) );
        END IF;
      --本体金額（仮）に端数がない場合
      ELSE
        lt_pure_amount         := TRUNC( ( in_unit_price * in_dlv_qty ) - ln_amount );
      END IF;
      --【消費税金額】
      --消費税金額（仮）
      ln_amount := ( ( in_unit_price * in_dlv_qty ) /  ( ln_tax_data * 100 ) ) * in_tax_rate;
      --消費税金額（仮）に端数がある場合
      IF ( ln_amount <> TRUNC( ln_amount ) ) THEN
        --端数処理区分が「切り上げ」の場合
        IF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_up ) THEN
          IF ( SIGN (ln_amount) <> -1 ) THEN
            lt_tax_amount      := TRUNC( ln_amount ) + 1;
          ELSE
            lt_tax_amount      := TRUNC( ln_amount ) - 1;
          END IF;
        --端数処理区分が「切り捨て」の場合
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_down ) THEN
          lt_tax_amount        := TRUNC( ln_amount );
        --端数処理区分が「四捨五入」の場合
        ELSIF ( iv_bill_tax_round_rule = cv_tax_rounding_rule_nearest ) THEN
          lt_tax_amount        := ROUND( ln_amount );
        END IF;
      --消費税金額（仮）に端数がない場合
      ELSE
        lt_tax_amount          := ln_amount;
      END IF;
--
    END IF;
--
    ------------------------------------
    --明細金額合計
    ------------------------------------
    gt_sale_amount_sum         := gt_sale_amount_sum + lt_sale_amount;     --売上金額合計
    gt_pure_amount_sum         := gt_pure_amount_sum + lt_pure_amount;     --本体金額合計
    gt_tax_amount_sum          := gt_tax_amount_sum  + lt_tax_amount;      --消費税金額合計
--
    ------------------------------------
    --赤黒フラグ判定
    ------------------------------------
    IF ( in_dlv_qty < 0 ) THEN
      lt_red_black_flag1       := cv_red_black_flag_r;  --赤黒フラグ
      lt_red_black_flag2       := cv_red_black_flag_b;  --赤黒フラグ（相殺）
    ELSE
      lt_red_black_flag1       := cv_red_black_flag_b;  --赤黒フラグ
      lt_red_black_flag2       := cv_red_black_flag_r;  --赤黒フラグ（相殺）
    END IF;
--
  -- ************************************
  -- ***  販売実績明細データ設定処理  ***
  -- ************************************
--
    gr_sales_line_data1(gn_line_cnt1).sales_exp_line_id              := gt_sales_exp_line_id1;       --販売実績明細ID
    gr_sales_line_data1(gn_line_cnt1).sales_exp_header_id            := gt_sales_exp_header_id1;     --販売実績ヘッダID
    gr_sales_line_data1(gn_line_cnt1).dlv_invoice_number             := iv_dlv_inv_num;              --納品伝票番号
    gr_sales_line_data1(gn_line_cnt1).dlv_invoice_line_number        := in_line_number;              --納品明細番号
    gr_sales_line_data1(gn_line_cnt1).order_invoice_line_number      := NULL;                        --注文明細番号
    gr_sales_line_data1(gn_line_cnt1).sales_class                    := cv_sales_class_vd;           --売上区分：VD売上
-- Ver.1.1 MOD START
--    gr_sales_line_data1(gn_line_cnt1).delivery_pattern_class         := NULL;                        --納品形態区分
    gr_sales_line_data1(gn_line_cnt1).delivery_pattern_class         := gv_prf_bp_sales_dlv_ptn_cls; --納品形態区分
-- Ver.1.1 MOD END
    gr_sales_line_data1(gn_line_cnt1).red_black_flag                 := lt_red_black_flag1;          --赤黒フラグ
    gr_sales_line_data1(gn_line_cnt1).item_code                      := iv_item_code;                --品目コード
    gr_sales_line_data1(gn_line_cnt1).dlv_qty                        := in_dlv_qty;                  --納品数量
    gr_sales_line_data1(gn_line_cnt1).standard_qty                   := in_dlv_qty;                  --基準数量
    gr_sales_line_data1(gn_line_cnt1).dlv_uom_code                   := iv_uom_code;                 --納品単位
    gr_sales_line_data1(gn_line_cnt1).standard_uom_code              := iv_uom_code;                 --基準単位
    gr_sales_line_data1(gn_line_cnt1).dlv_unit_price                 := in_unit_price;               --納品単価
    gr_sales_line_data1(gn_line_cnt1).standard_unit_price_excluded   := lt_stand_unit_price_excl;    --税抜基準単価
    gr_sales_line_data1(gn_line_cnt1).standard_unit_price            := in_unit_price;               --基準単価
    gr_sales_line_data1(gn_line_cnt1).business_cost                  := in_business_cost;            --営業原価
    gr_sales_line_data1(gn_line_cnt1).sale_amount                    := lt_sale_amount;              --売上金額
    gr_sales_line_data1(gn_line_cnt1).pure_amount                    := lt_pure_amount;              --本体金額
    gr_sales_line_data1(gn_line_cnt1).tax_amount                     := lt_tax_amount;               --消費税金額
-- Ver.1.2 ADD START
    gr_sales_line_data1(gn_line_cnt1).tax_code                       := iv_tax_code;                 --税金コード
    gr_sales_line_data1(gn_line_cnt1).tax_rate                       := in_tax_rate;                 --消費税率
-- Ver.1.2 ADD END
    gr_sales_line_data1(gn_line_cnt1).cash_and_card                  := in_cash_and_card;            --現金・カード併用額
    gr_sales_line_data1(gn_line_cnt1).ship_from_subinventory_code    := NULL;                        --出荷元保管場所
    gr_sales_line_data1(gn_line_cnt1).delivery_base_code             := iv_sales_base_code;          --納品拠点コード
    gr_sales_line_data1(gn_line_cnt1).hot_cold_class                 := NULL;                        --Ｈ＆Ｃ
    gr_sales_line_data1(gn_line_cnt1).column_no                      := NULL;                        --コラムNo
    gr_sales_line_data1(gn_line_cnt1).sold_out_class                 := NULL;                        --売切区分
    gr_sales_line_data1(gn_line_cnt1).sold_out_time                  := NULL;                        --売切時間
    gr_sales_line_data1(gn_line_cnt1).to_calculate_fees_flag         := cv_complete_flag_n;          --手数料計算インタフェース済フラグ：N
    gr_sales_line_data1(gn_line_cnt1).unit_price_mst_flag            := cv_complete_flag_s;          --単価マスタ作成済フラグ：S
    gr_sales_line_data1(gn_line_cnt1).inv_interface_flag             := cv_complete_flag_s;          --INVインタフェース済フラグ：S
    gr_sales_line_data1(gn_line_cnt1).goods_prod_cls                 := NULL;                        --品目区分
    gr_sales_line_data1(gn_line_cnt1).created_by                     := cn_created_by;               --作成者
    gr_sales_line_data1(gn_line_cnt1).creation_date                  := cd_creation_date;            --作成日
    gr_sales_line_data1(gn_line_cnt1).last_updated_by                := cn_last_updated_by;          --最終更新者
    gr_sales_line_data1(gn_line_cnt1).last_update_date               := cd_last_update_date;         --最終更新日
    gr_sales_line_data1(gn_line_cnt1).last_update_login              := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
    gr_sales_line_data1(gn_line_cnt1).request_id                     := cn_request_id;               --要求ID
    gr_sales_line_data1(gn_line_cnt1).program_application_id         := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_sales_line_data1(gn_line_cnt1).program_id                     := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_sales_line_data1(gn_line_cnt1).program_update_date            := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
--
  -- ********************************************
  -- ***  販売実績明細データ（相殺）設定処理  ***
  -- ********************************************
--
    gr_sales_line_data2(gn_line_cnt2).sales_exp_line_id              := gt_sales_exp_line_id2;       --販売実績明細ID（相殺）
    gr_sales_line_data2(gn_line_cnt2).sales_exp_header_id            := gt_sales_exp_header_id2;     --販売実績ヘッダID（相殺）
    gr_sales_line_data2(gn_line_cnt2).dlv_invoice_number             := gt_dlv_invoice_number_os;    --納品伝票番号
    gr_sales_line_data2(gn_line_cnt2).dlv_invoice_line_number        := in_line_number;              --納品明細番号
    gr_sales_line_data2(gn_line_cnt2).order_invoice_line_number      := NULL;                        --注文明細番号
    gr_sales_line_data2(gn_line_cnt2).sales_class                    := cv_sales_class_vd;           --売上区分：VD売上
-- Ver.1.1 MOD START
--    gr_sales_line_data2(gn_line_cnt2).delivery_pattern_class         := NULL;                        --納品形態区分
    gr_sales_line_data2(gn_line_cnt2).delivery_pattern_class         := gv_prf_bp_sales_dlv_ptn_cls; --納品形態区分
-- Ver.1.1 MOD END
    gr_sales_line_data2(gn_line_cnt2).red_black_flag                 := lt_red_black_flag2;          --赤黒フラグ
    gr_sales_line_data2(gn_line_cnt2).item_code                      := iv_item_code;                --品目コード
    gr_sales_line_data2(gn_line_cnt2).dlv_qty                        := in_dlv_qty * -1;             --納品数量
    gr_sales_line_data2(gn_line_cnt2).standard_qty                   := in_dlv_qty * -1;             --基準数量
    gr_sales_line_data2(gn_line_cnt2).dlv_uom_code                   := iv_uom_code;                 --納品単位
    gr_sales_line_data2(gn_line_cnt2).standard_uom_code              := iv_uom_code;                 --基準単位
    gr_sales_line_data2(gn_line_cnt2).dlv_unit_price                 := in_unit_price;               --納品単価
    gr_sales_line_data2(gn_line_cnt2).standard_unit_price_excluded   := lt_stand_unit_price_excl;    --税抜基準単価
    gr_sales_line_data2(gn_line_cnt2).standard_unit_price            := in_unit_price;               --基準単価
    gr_sales_line_data2(gn_line_cnt2).business_cost                  := in_business_cost;            --営業原価
    gr_sales_line_data2(gn_line_cnt2).sale_amount                    := lt_sale_amount * -1;         --売上金額
    gr_sales_line_data2(gn_line_cnt2).pure_amount                    := lt_pure_amount * -1;         --本体金額
    gr_sales_line_data2(gn_line_cnt2).tax_amount                     := lt_tax_amount * -1;          --消費税金額
-- Ver.1.2 ADD START
    gr_sales_line_data2(gn_line_cnt2).tax_code                       := iv_tax_code;                 --税金コード
    gr_sales_line_data2(gn_line_cnt2).tax_rate                       := in_tax_rate;                 --消費税率
-- Ver.1.2 ADD END
    gr_sales_line_data2(gn_line_cnt2).cash_and_card                  := in_cash_and_card;            --現金・カード併用額
    gr_sales_line_data2(gn_line_cnt2).ship_from_subinventory_code    := NULL;                        --出荷元保管場所
    gr_sales_line_data2(gn_line_cnt2).delivery_base_code             := iv_sales_base_code;          --納品拠点コード
    gr_sales_line_data2(gn_line_cnt2).hot_cold_class                 := NULL;                        --Ｈ＆Ｃ
    gr_sales_line_data2(gn_line_cnt2).column_no                      := NULL;                        --コラムNo
    gr_sales_line_data2(gn_line_cnt2).sold_out_class                 := NULL;                        --売切区分
    gr_sales_line_data2(gn_line_cnt2).sold_out_time                  := NULL;                        --売切時間
    gr_sales_line_data2(gn_line_cnt2).to_calculate_fees_flag         := cv_complete_flag_y;          --手数料計算インタフェース済フラグ：Y
    gr_sales_line_data2(gn_line_cnt2).unit_price_mst_flag            := cv_complete_flag_s;          --単価マスタ作成済フラグ：S
    gr_sales_line_data2(gn_line_cnt2).inv_interface_flag             := cv_complete_flag_s;          --INVインタフェース済フラグ：S
    gr_sales_line_data2(gn_line_cnt2).goods_prod_cls                 := NULL;                        --品目区分
    gr_sales_line_data2(gn_line_cnt2).created_by                     := cn_created_by;               --作成者
    gr_sales_line_data2(gn_line_cnt2).creation_date                  := cd_creation_date;            --作成日
    gr_sales_line_data2(gn_line_cnt2).last_updated_by                := cn_last_updated_by;          --最終更新者
    gr_sales_line_data2(gn_line_cnt2).last_update_date               := cd_last_update_date;         --最終更新日
    gr_sales_line_data2(gn_line_cnt2).last_update_login              := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
    gr_sales_line_data2(gn_line_cnt2).request_id                     := cn_request_id;               --要求ID
    gr_sales_line_data2(gn_line_cnt2).program_application_id         := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
    gr_sales_line_data2(gn_line_cnt2).program_id                     := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
    gr_sales_line_data2(gn_line_cnt2).program_update_date            := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
--
    --初回レコード、または前レコードと取引先コードか納品伝票番号が異なる場合
    IF ( gt_bp_com_code IS NULL ) OR
       ( gt_bp_com_code != iv_bp_company_code ) OR
       ( gt_dlv_inv_num != iv_dlv_inv_num ) THEN
--
  -- **************************************
  -- ***  販売実績ヘッダデータ設定処理  ***
  -- **************************************
--
      gr_sales_head_data1(gn_hed_cnt1).sales_exp_header_id           := gt_sales_exp_header_id1;     --販売実績ヘッダID
      gr_sales_head_data1(gn_hed_cnt1).dlv_invoice_number            := iv_dlv_inv_num;              --納品伝票番号
      gr_sales_head_data1(gn_hed_cnt1).order_invoice_number          := NULL;                        --注文伝票番号
      gr_sales_head_data1(gn_hed_cnt1).order_number                  := NULL;                        --受注番号
      gr_sales_head_data1(gn_hed_cnt1).order_no_hht                  := NULL;                        --受注No（HHT)
      gr_sales_head_data1(gn_hed_cnt1).digestion_ln_number           := NULL;                        --納品伝票番号枝番
      gr_sales_head_data1(gn_hed_cnt1).order_connection_number       := NULL;                        --受注関連番号
      gr_sales_head_data1(gn_hed_cnt1).dlv_invoice_class             := cv_dlv_inv_cls_dlv;          --納品伝票区分：納品
      gr_sales_head_data1(gn_hed_cnt1).cancel_correct_class          := NULL;                        --取消・訂正区分
      gr_sales_head_data1(gn_hed_cnt1).input_class                   := NULL;                        --入力区分
      gr_sales_head_data1(gn_hed_cnt1).cust_gyotai_sho               := iv_cust_gyotai_sho;          --業態小分類
      gr_sales_head_data1(gn_hed_cnt1).delivery_date                 := id_delivery_date;            --納品日
      gr_sales_head_data1(gn_hed_cnt1).orig_delivery_date            := id_delivery_date;            --オリジナル納品日
      gr_sales_head_data1(gn_hed_cnt1).inspect_date                  := id_delivery_date;            --検収日
      gr_sales_head_data1(gn_hed_cnt1).orig_inspect_date             := id_delivery_date;            --オリジナル検収日
      gr_sales_head_data1(gn_hed_cnt1).ship_to_customer_code         := iv_customer_code;            --顧客【納品先】
      gr_sales_head_data1(gn_hed_cnt1).consumption_tax_class         := iv_consumption_tax_class;    --消費税区分
      gr_sales_head_data1(gn_hed_cnt1).tax_code                      := iv_tax_code;                 --税金コード
      gr_sales_head_data1(gn_hed_cnt1).tax_rate                      := in_tax_rate;                 --消費税率
      gr_sales_head_data1(gn_hed_cnt1).results_employee_code         := iv_results_employee_code;    --成績計上者コード
      gr_sales_head_data1(gn_hed_cnt1).sales_base_code               := iv_sales_base_code;          --売上拠点コード
      gr_sales_head_data1(gn_hed_cnt1).receiv_base_code              := iv_receiv_base_code;         --入金拠点コード
      gr_sales_head_data1(gn_hed_cnt1).order_source_id               := NULL;                        --受注ソースID
      gr_sales_head_data1(gn_hed_cnt1).card_sale_class               := iv_card_sale_class;          --カード売区分
      gr_sales_head_data1(gn_hed_cnt1).invoice_class                 := NULL;                        --伝票区分
      gr_sales_head_data1(gn_hed_cnt1).invoice_classification_code   := NULL;                        --伝票分類コード
      gr_sales_head_data1(gn_hed_cnt1).change_out_time_100           := NULL;                        --つり銭切れ時間１００円
      gr_sales_head_data1(gn_hed_cnt1).change_out_time_10            := NULL;                        --つり銭切れ時間１０円
      gr_sales_head_data1(gn_hed_cnt1).ar_interface_flag             := cv_complete_flag_s;          --ARインタフェース済フラグ：S
      gr_sales_head_data1(gn_hed_cnt1).gl_interface_flag             := cv_complete_flag_s;          --GLインタフェース済フラグ：S
      gr_sales_head_data1(gn_hed_cnt1).dwh_interface_flag            := cv_complete_flag_n;          --情報システムインタフェース済フラグ：N
      gr_sales_head_data1(gn_hed_cnt1).edi_interface_flag            := cv_complete_flag_s;          --EDI送信済みフラグ：S
      gr_sales_head_data1(gn_hed_cnt1).edi_send_date                 := NULL;                        --EDI送信日時
      gr_sales_head_data1(gn_hed_cnt1).hht_dlv_input_date            := NULL;                        --HHT納品入力日時
      gr_sales_head_data1(gn_hed_cnt1).dlv_by_code                   := NULL;                        --納品者コード
      gr_sales_head_data1(gn_hed_cnt1).create_class                  := cv_create_cls_sls_upload;    --作成元区分：CSVデータアップロード（販売実績）
      gr_sales_head_data1(gn_hed_cnt1).business_date                 := gd_process_date;             --登録業務日付
      gr_sales_head_data1(gn_hed_cnt1).head_sales_branch             := NULL;                        --管轄拠点
      gr_sales_head_data1(gn_hed_cnt1).item_sales_send_flag          := cv_complete_flag_y;          --商品別販売実績送信済フラグ：Y
      gr_sales_head_data1(gn_hed_cnt1).item_sales_send_date          := gd_process_date;             --商品別販売実績送信日
      gr_sales_head_data1(gn_hed_cnt1).total_sales_amt               := cn_amt_dummy;                --総販売金額
      gr_sales_head_data1(gn_hed_cnt1).cash_total_sales_amt          := cn_amt_dummy;                --現金売りトータル販売金額
      gr_sales_head_data1(gn_hed_cnt1).ppcard_total_sales_amt        := cn_amt_dummy;                --PPカードトータル販売金額
      gr_sales_head_data1(gn_hed_cnt1).idcard_total_sales_amt        := cn_amt_dummy;                --IDカードトータル販売金額
      gr_sales_head_data1(gn_hed_cnt1).hht_received_flag             := cv_hht_rcv_flag_n;           --HHT受信フラグ
      gr_sales_head_data1(gn_hed_cnt1).created_by                    := cn_created_by;               --作成者
      gr_sales_head_data1(gn_hed_cnt1).creation_date                 := cd_creation_date;            --作成日
      gr_sales_head_data1(gn_hed_cnt1).last_updated_by               := cn_last_updated_by;          --最終更新者
      gr_sales_head_data1(gn_hed_cnt1).last_update_date              := cd_last_update_date;         --最終更新日
      gr_sales_head_data1(gn_hed_cnt1).last_update_login             := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
      gr_sales_head_data1(gn_hed_cnt1).request_id                    := cn_request_id;               --要求ID
      gr_sales_head_data1(gn_hed_cnt1).program_application_id        := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      gr_sales_head_data1(gn_hed_cnt1).program_id                    := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      gr_sales_head_data1(gn_hed_cnt1).program_update_date           := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
--
  -- **********************************************
  -- ***  販売実績ヘッダデータ（相殺）設定処理  ***
  -- **********************************************
--
      gr_sales_head_data2(gn_hed_cnt2).sales_exp_header_id           := gt_sales_exp_header_id2;     --販売実績ヘッダID（相殺）
      gr_sales_head_data2(gn_hed_cnt2).dlv_invoice_number            := gt_dlv_invoice_number_os;    --納品伝票番号
      gr_sales_head_data2(gn_hed_cnt2).order_invoice_number          := NULL;                        --注文伝票番号
      gr_sales_head_data2(gn_hed_cnt2).order_number                  := NULL;                        --受注番号
      gr_sales_head_data2(gn_hed_cnt2).order_no_hht                  := NULL;                        --受注No（HHT)
      gr_sales_head_data2(gn_hed_cnt2).digestion_ln_number           := NULL;                        --納品伝票番号枝番
      gr_sales_head_data2(gn_hed_cnt2).order_connection_number       := NULL;                        --受注関連番号
      gr_sales_head_data2(gn_hed_cnt2).dlv_invoice_class             := cv_dlv_inv_cls_dlv;          --納品伝票区分：納品
      gr_sales_head_data2(gn_hed_cnt2).cancel_correct_class          := NULL;                        --取消・訂正区分
      gr_sales_head_data2(gn_hed_cnt2).input_class                   := NULL;                        --入力区分
      gr_sales_head_data2(gn_hed_cnt2).cust_gyotai_sho               := iv_cust_gyotai_sho;          --業態小分類
      gr_sales_head_data2(gn_hed_cnt2).delivery_date                 := id_delivery_date;            --納品日
      gr_sales_head_data2(gn_hed_cnt2).orig_delivery_date            := id_delivery_date;            --オリジナル納品日
      gr_sales_head_data2(gn_hed_cnt2).inspect_date                  := id_delivery_date;            --検収日
      gr_sales_head_data2(gn_hed_cnt2).orig_inspect_date             := id_delivery_date;            --オリジナル検収日
      gr_sales_head_data2(gn_hed_cnt2).ship_to_customer_code         := iv_offset_cust_code;         --顧客【納品先】
      gr_sales_head_data2(gn_hed_cnt2).consumption_tax_class         := iv_consumption_tax_class;    --消費税区分
      gr_sales_head_data2(gn_hed_cnt2).tax_code                      := iv_tax_code;                 --税金コード
      gr_sales_head_data2(gn_hed_cnt2).tax_rate                      := in_tax_rate;                 --消費税率
      gr_sales_head_data2(gn_hed_cnt2).results_employee_code         := iv_results_employee_code;    --成績計上者コード
      gr_sales_head_data2(gn_hed_cnt2).sales_base_code               := iv_sales_base_code;          --売上拠点コード
      gr_sales_head_data2(gn_hed_cnt2).receiv_base_code              := iv_receiv_base_code;         --入金拠点コード
      gr_sales_head_data2(gn_hed_cnt2).order_source_id               := NULL;                        --受注ソースID
      gr_sales_head_data2(gn_hed_cnt2).card_sale_class               := iv_card_sale_class;          --カード売区分
      gr_sales_head_data2(gn_hed_cnt2).invoice_class                 := NULL;                        --伝票区分
      gr_sales_head_data2(gn_hed_cnt2).invoice_classification_code   := NULL;                        --伝票分類コード
      gr_sales_head_data2(gn_hed_cnt2).change_out_time_100           := NULL;                        --つり銭切れ時間１００円
      gr_sales_head_data2(gn_hed_cnt2).change_out_time_10            := NULL;                        --つり銭切れ時間１０円
      gr_sales_head_data2(gn_hed_cnt2).ar_interface_flag             := cv_complete_flag_s;          --ARインタフェース済フラグ：S
      gr_sales_head_data2(gn_hed_cnt2).gl_interface_flag             := cv_complete_flag_s;          --GLインタフェース済フラグ：S
      gr_sales_head_data2(gn_hed_cnt2).dwh_interface_flag            := cv_complete_flag_n;          --情報システムインタフェース済フラグ：N
      gr_sales_head_data2(gn_hed_cnt2).edi_interface_flag            := cv_complete_flag_s;          --EDI送信済みフラグ：S
      gr_sales_head_data2(gn_hed_cnt2).edi_send_date                 := NULL;                        --EDI送信日時
      gr_sales_head_data2(gn_hed_cnt2).hht_dlv_input_date            := NULL;                        --HHT納品入力日時
      gr_sales_head_data2(gn_hed_cnt2).dlv_by_code                   := NULL;                        --納品者コード
      gr_sales_head_data2(gn_hed_cnt2).create_class                  := cv_create_cls_sls_upload;    --作成元区分：CSVデータアップロード（販売実績）
      gr_sales_head_data2(gn_hed_cnt2).business_date                 := gd_process_date;             --登録業務日付
      gr_sales_head_data2(gn_hed_cnt2).head_sales_branch             := NULL;                        --管轄拠点
      gr_sales_head_data2(gn_hed_cnt2).item_sales_send_flag          := cv_complete_flag_y;          --商品別販売実績送信済フラグ：Y
      gr_sales_head_data2(gn_hed_cnt2).item_sales_send_date          := gd_process_date;             --商品別販売実績送信日
      gr_sales_head_data2(gn_hed_cnt2).total_sales_amt               := cn_amt_dummy;                --総販売金額
      gr_sales_head_data2(gn_hed_cnt2).cash_total_sales_amt          := cn_amt_dummy;                --現金売りトータル販売金額
      gr_sales_head_data2(gn_hed_cnt2).ppcard_total_sales_amt        := cn_amt_dummy;                --PPカードトータル販売金額
      gr_sales_head_data2(gn_hed_cnt2).idcard_total_sales_amt        := cn_amt_dummy;                --IDカードトータル販売金額
      gr_sales_head_data2(gn_hed_cnt2).hht_received_flag             := cv_hht_rcv_flag_n;           --HHT受信フラグ
      gr_sales_head_data2(gn_hed_cnt2).created_by                    := cn_created_by;               --作成者
      gr_sales_head_data2(gn_hed_cnt2).creation_date                 := cd_creation_date;            --作成日
      gr_sales_head_data2(gn_hed_cnt2).last_updated_by               := cn_last_updated_by;          --最終更新者
      gr_sales_head_data2(gn_hed_cnt2).last_update_date              := cd_last_update_date;         --最終更新日
      gr_sales_head_data2(gn_hed_cnt2).last_update_login             := cn_last_update_login;        --最終更新ﾛｸﾞｲﾝ
      gr_sales_head_data2(gn_hed_cnt2).request_id                    := cn_request_id;               --要求ID
      gr_sales_head_data2(gn_hed_cnt2).program_application_id        := cn_program_application_id;   --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      gr_sales_head_data2(gn_hed_cnt2).program_id                    := cn_program_id;               --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      gr_sales_head_data2(gn_hed_cnt2).program_update_date           := cd_program_update_date;      --ﾌﾟﾛｸﾞﾗﾑ更新日
--
    END IF;
--
    ------------------------------------
    --明細金額合計をセット
    ------------------------------------
    --販売実績データ
    gr_sales_head_data1(gn_hed_cnt1).sale_amount_sum                 := gt_sale_amount_sum;          --売上金額合計
    gr_sales_head_data1(gn_hed_cnt1).pure_amount_sum                 := gt_pure_amount_sum;          --本体金額合計
    gr_sales_head_data1(gn_hed_cnt1).tax_amount_sum                  := gt_tax_amount_sum;           --消費税金額合計
    --販売実績データ（相殺）
    gr_sales_head_data2(gn_hed_cnt2).sale_amount_sum                 := gt_sale_amount_sum * -1;     --売上金額合計
    gr_sales_head_data2(gn_hed_cnt2).pure_amount_sum                 := gt_pure_amount_sum * -1;     --本体金額合計
    gr_sales_head_data2(gn_hed_cnt2).tax_amount_sum                  := gt_tax_amount_sum * -1;      --消費税金額合計
--
    --一時格納用変数にセット
    gt_bp_com_code := iv_bp_company_code;
    gt_dlv_inv_num := iv_dlv_inv_num;
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
  END set_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_bp_data
   * Description      : 取引先販売実績データ登録処理(A-10)
   ***********************************************************************************/
  PROCEDURE ins_sales_bp_data(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_bp_data'; -- プログラム名
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
    ln_i          NUMBER;           --カウンタ
    lv_tab_name   VARCHAR2(100);    --テーブル名
    ln_cnt        NUMBER;
    lv_key_info   VARCHAR2(100);    --キー情報
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
    -- ********************************
    -- ***  取引先販売実績登録処理  ***
    -- ********************************
--
    BEGIN
      FORALL ln_i in 1..gr_sales_bp_data.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_bus_partners
          VALUES gr_sales_bp_data(ln_i)
        ;
      --件数カウント
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_bp
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
  EXCEPTION
    -- *** レコード登録例外ハンドラ ***
    WHEN global_ins_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_sales_bp_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_data
   * Description      : 販売実績データ登録処理(A-11)
   ***********************************************************************************/
  PROCEDURE ins_sales_data(
     ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_data'; -- プログラム名
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
    ln_i          NUMBER;           --カウンタ
    lv_tab_name   VARCHAR2(100);    --テーブル名
    ln_cnt        NUMBER;
    lv_key_info   VARCHAR2(100);    --キー情報
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
    -- ****************************************
    -- ***  販売実績ヘッダテーブル登録処理  ***
    -- ****************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_head_data1.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers
          VALUES gr_sales_head_data1(ln_i)
        ;
      --件数カウント
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_head
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
    -- **************************************
    -- ***  販売実績明細テーブル登録処理  ***
    -- **************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_line_data1.COUNT
        INSERT INTO xxcos_sales_exp_lines
          VALUES gr_sales_line_data1(ln_i)
        ;
      --件数カウント
      gn_line_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_line
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
    END;
--
    -- ************************************************
    -- ***  販売実績ヘッダテーブル登録処理（相殺）  ***
    -- ************************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_head_data2.COUNT SAVE EXCEPTIONS
        INSERT INTO xxcos_sales_exp_headers
          VALUES gr_sales_head_data2(ln_i)
        ;
      --件数カウント
      gn_hed_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_head
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
     END;
--
    -- **********************************************
    -- ***  販売実績明細テーブル登録処理（相殺）  ***
    -- **********************************************
--
    BEGIN
      FORALL ln_i IN 1..gr_sales_line_data2.COUNT
        INSERT INTO xxcos_sales_exp_lines
          VALUES gr_sales_line_data2(ln_i)
        ;
      --件数カウント
      gn_line_suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        --キー情報の編集処理
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                       ,iv_name         => cv_msg_sales_line
                     );
        lv_key_info := SQLERRM;
       RAISE global_ins_sales_data_expt;
    END;
--
  EXCEPTION
    -- *** レコード登録例外ハンドラ ***
    WHEN global_ins_sales_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END ins_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     in_get_file_id    IN  NUMBER    -- ファイルID
    ,iv_get_format_pat IN  VARCHAR2  -- フォーマットパターン
    ,ov_errbuf     OUT VARCHAR2  -- エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2  -- リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ln_cnt           NUMBER;        -- カウンタ
    lv_ret_status    VARCHAR2(1);   -- リターン・ステータス
--
    --取得値の格納変数
    lv_bp_company_code        VARCHAR2(9);                                         -- 取引先コード
    lt_dlv_inv_num            xxcos_sales_exp_headers.dlv_invoice_number%TYPE;     -- 納品伝票番号
    lt_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE;        -- 拠点コード
    lt_delivery_date          xxcos_sales_exp_headers.delivery_date%TYPE;          -- 納品日
    lt_card_sale_class        xxcos_sales_exp_headers.card_sale_class%TYPE;        -- カード売区分
    lt_customer_code          xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- 伊藤園顧客コード
    lv_bp_customer_code       VARCHAR2(15);                                        -- 取引先顧客コード
    lt_conv_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- 変換後顧客コード
    lt_tax_class              xxcos_sales_exp_headers.consumption_tax_class%TYPE;  -- 消費税区分
    lt_line_number            xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE;  -- 明細番号
    lt_item_code              xxcos_sales_exp_lines.item_code%TYPE;                -- 伊藤園品名コード
    lv_bp_item_code           VARCHAR2(15);                                        -- 取引先品名コード
    lt_conv_item_code         xxcos_sales_exp_lines.item_code%TYPE;                -- 変換後品名コード
    lv_item_status            VARCHAR2(2);                                         -- 品目ステータス
    lt_dlv_qty                xxcos_sales_exp_lines.dlv_qty%TYPE;                  -- 数量
    lt_unit_price             xxcos_sales_exp_lines.dlv_unit_price%TYPE;           -- 売単価
    lt_cash_and_card          xxcos_sales_exp_lines.cash_and_card%TYPE;            -- 現金・カード併用額
    lt_sales_base_code        xxcos_sales_exp_headers.sales_base_code%TYPE;        -- 売上拠点コード
    lt_receiv_base_code       xxcos_sales_exp_headers.receiv_base_code%TYPE;       -- 入金拠点コード
    lt_bill_tax_round_rule    xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;     -- 税金－端数処理
    lt_offset_cust_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE;  -- 相殺用顧客コード
    lt_results_employee_code  xxcos_sales_exp_headers.results_employee_code%TYPE;  -- 成績計上者コード
    lt_cust_gyotai_sho        xxcos_sales_exp_headers.cust_gyotai_sho%TYPE;        -- 業態（小分類）
    lt_tax_rate               xxcos_sales_exp_headers.tax_rate%TYPE;               -- 消費税率
    lt_tax_code               xxcos_sales_exp_headers.tax_code%TYPE;               -- 税金コード
    lt_consumption_tax_class  xxcos_sales_exp_headers.consumption_tax_class%TYPE;  -- 消費税区分
    lt_uom_code               xxcos_sales_exp_lines.standard_uom_code%TYPE;        -- 基準単位
    lt_business_cost          xxcos_sales_exp_lines.business_cost%TYPE;            -- 営業原価
    ld_data_created           DATE;                                                -- データ作成日時
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
    --グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --カウンタ
    gn_get_counter_data      := 0;     --データ数
    gn_hed_cnt1              := 0;     --ヘッダカウンター
    gn_line_cnt1             := 0;     --明細カウンター
    gn_hed_cnt2              := 0;     --ヘッダカウンター
    gn_line_cnt2             := 0;     --明細カウンター
    gn_bp_cnt                := 0;     --取引先販売実績カウンター
    gn_hed_suc_cnt           := 0;     --成功ヘッダカウンター
    gn_line_suc_cnt          := 0;     --成功明細カウンター
--
    --取得項目
    gt_sales_exp_header_id1  := NULL;  --販売実績ヘッダID
    gt_sales_exp_header_id2  := NULL;  --販売実績ヘッダID（相殺）
    gt_sales_exp_line_id1    := NULL;  --販売実績明細ID
    gt_sales_exp_line_id2    := NULL;  --販売実績明細ID（相殺）
    gt_dlv_invoice_number_os := NULL;  --取引先納品伝票番号
    gt_sale_amount_sum       := 0;     --売上金額合計
    gt_pure_amount_sum       := 0;     --本体金額合計
    gt_tax_amount_sum        := 0;     --消費税金額合計
--
    --ローカル変数の初期化
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      iv_get_format => iv_get_format_pat -- フォーマットパターン
     ,in_file_id    => in_get_file_id    -- ファイルID
     ,ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードIF取得(A-2)
    -- ===============================================
    get_upload_data(
      in_file_id           => in_get_file_id       -- FILE_ID
     ,on_get_counter_data  => gn_get_counter_data  -- データ数
     ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- データ削除処理(A-3)
    -- ===============================================
    del_upload_data(
      in_file_id  => in_get_file_id   -- ファイルID
     ,ov_errbuf   => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --コミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 販売実績データの項目分割処理(A-4)
    -- ===============================================
    split_sales_data(
      in_cnt            => gn_get_counter_data  -- データ数
     ,ov_errbuf         => lv_errbuf            -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode           -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --初期化
    gt_bp_com_code  := NULL;
    gt_dlv_inv_num  := NULL;
    gn_hed_cnt1     := 0;
    gn_line_cnt1    := 0;
    gn_hed_cnt2     := 0;
    gn_line_cnt2    := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- ===============================================
      -- 項目チェック(A-5)
      -- ===============================================
      item_check(
        in_cnt               => i                    -- データカウンタ
       ,ov_bp_company_code   => lv_bp_company_code   -- 取引先コード
       ,ov_dlv_inv_num       => lt_dlv_inv_num       -- 納品伝票番号
       ,ov_base_code         => lt_base_code         -- 拠点コード
       ,od_delivery_date     => lt_delivery_date     -- 納品日
       ,ov_card_sale_class   => lt_card_sale_class   -- カード売区分
       ,ov_customer_code     => lt_customer_code     -- 伊藤園顧客コード
       ,ov_bp_customer_code  => lv_bp_customer_code  -- 取引先顧客コード
       ,ov_tax_class         => lt_tax_class         -- 消費税区分
       ,on_line_number       => lt_line_number       -- 明細番号
       ,ov_item_code         => lt_item_code         -- 伊藤園品名コード
       ,ov_bp_item_code      => lv_bp_item_code      -- 取引先品名コード
       ,on_dlv_qty           => lt_dlv_qty           -- 数量
       ,on_unit_price        => lt_unit_price        -- 売単価
       ,on_cash_and_card     => lt_cash_and_card     -- 現金・カード併用額
       ,od_data_created      => ld_data_created      -- データ作成日時
       ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode           => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --ワーニング保持
        lv_ret_status := cv_status_warn;
        --書き出し
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- マスタ情報の取得処理(A-6)
        -- ===============================================
        get_master_data(
          in_cnt                     => i                         -- データカウンタ
         ,iv_bp_company_code         => lv_bp_company_code        -- 取引先コード
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- 納品伝票番号
         ,iv_base_code               => lt_base_code              -- 拠点コード
         ,id_delivery_date           => lt_delivery_date          -- 納品日
         ,iv_card_sale_class         => lt_card_sale_class        -- カード売区分
         ,iv_customer_code           => lt_customer_code          -- 伊藤園顧客コード
         ,iv_bp_customer_code        => lv_bp_customer_code       -- 取引先顧客コード
         ,iv_tax_class               => lt_tax_class              -- 消費税区分
         ,in_line_number             => lt_line_number            -- 明細番号
         ,iv_item_code               => lt_item_code              -- 伊藤園品名コード
         ,iv_bp_item_code            => lv_bp_item_code           -- 取引先品名コード
         ,ov_sales_base_code         => lt_sales_base_code        -- 売上拠点コード
         ,ov_receiv_base_code        => lt_receiv_base_code       -- 入金拠点コード
         ,ov_bill_tax_round_rule     => lt_bill_tax_round_rule    -- 税金－端数処理
         ,ov_conv_customer_code      => lt_conv_customer_code     -- 変換後顧客コード
         ,ov_offset_cust_code        => lt_offset_cust_code       -- 相殺用顧客コード
         ,ov_employee_number         => lt_results_employee_code  -- 担当営業員
         ,ov_cust_gyotai_sho         => lt_cust_gyotai_sho        -- 業態（小分類）
         ,on_tax_rate                => lt_tax_rate               -- 消費税率
         ,ov_tax_code                => lt_tax_code               -- 税金コード
         ,ov_consumption_tax_class   => lt_consumption_tax_class  -- 消費税区分
         ,ov_conv_item_code          => lt_conv_item_code         -- 変換後品目コード
         ,ov_uom_code                => lt_uom_code               -- 基準単位
         ,on_business_cost           => lt_business_cost          -- 営業原価
         ,ov_item_status             => lv_item_status            -- 品目ステータス
         ,ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --ワーニング保持
          lv_ret_status := cv_status_warn;
        END IF;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================================
        -- セキュリティチェック処理(A-7)
        -- ===============================================
        security_check(
          in_cnt                     => i                         -- データカウンタ
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- 納品伝票番号
         ,in_line_number             => lt_line_number            -- 明細番号
         ,iv_customer_code           => lt_conv_customer_code     -- 変換後顧客コード
         ,iv_sales_base_code         => lt_sales_base_code        -- 売上拠点コード
         ,ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --ワーニング保持
          lv_ret_status := cv_status_warn;
          --書き出し
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
        END IF;
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
--
        -- ===============================================
        -- 取引先販売実績データ設定処理(A-8)
        -- ===============================================
        set_sales_bp_data(
          in_cnt                     => i                         -- データカウンタ
         ,iv_bp_company_code         => lv_bp_company_code        -- 取引先コード
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- 納品伝票番号
         ,iv_base_code               => lt_base_code              -- 拠点コード
         ,id_delivery_date           => lt_delivery_date          -- 納品日
         ,iv_card_sale_class         => lt_card_sale_class        -- カード売区分
         ,iv_customer_code           => lt_customer_code          -- 伊藤園顧客コード
         ,iv_bp_customer_code        => lv_bp_customer_code       -- 取引先顧客コード
         ,iv_tax_class               => lt_tax_class              -- 消費税区分
         ,in_line_number             => lt_line_number            -- 明細番号
         ,iv_item_code               => lt_item_code              -- 伊藤園品名コード
         ,iv_bp_item_code            => lv_bp_item_code           -- 取引先品名コード
         ,in_dlv_qty                 => lt_dlv_qty                -- 数量
         ,in_unit_price              => lt_unit_price             -- 売単価
         ,in_cash_and_card           => lt_cash_and_card          -- 現金・カード併用額
         ,id_data_created            => ld_data_created           -- データ作成日時
         ,iv_conv_customer_code      => lt_conv_customer_code     -- 変換後顧客コード
         ,iv_offset_cust_code        => lt_offset_cust_code       -- 相殺用顧客コード
         ,iv_employee_number         => lt_results_employee_code  -- 担当営業員
         ,iv_conv_item_code          => lt_conv_item_code         -- 変換後品名コード
         ,iv_item_status             => lv_item_status            -- 品目ステータス
         ,ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================================
        -- 販売実績データ設定処理(A-9)
        -- ===============================================
        set_sales_data(
          in_cnt                     => i                         -- データカウンタ
         ,iv_bp_company_code         => lv_bp_company_code        -- 取引先コード
         ,iv_dlv_inv_num             => lt_dlv_inv_num            -- 納品伝票番号
         ,iv_base_code               => lt_base_code              -- 拠点コード
         ,id_delivery_date           => lt_delivery_date          -- 納品日
         ,iv_card_sale_class         => lt_card_sale_class        -- カード売区分
         ,iv_customer_code           => lt_conv_customer_code     -- 変換後顧客コード
         ,iv_tax_class               => lt_tax_class              -- 消費税区分
         ,in_line_number             => lt_line_number            -- 明細番号
         ,iv_item_code               => lt_conv_item_code         -- 変換後品名コード
         ,in_dlv_qty                 => lt_dlv_qty                -- 数量
         ,in_unit_price              => lt_unit_price             -- 売単価
         ,iv_sales_base_code         => lt_sales_base_code        -- 売上拠点コード
         ,iv_receiv_base_code        => lt_receiv_base_code       -- 入金拠点コード
         ,iv_bill_tax_round_rule     => lt_bill_tax_round_rule    -- 税金－端数処理
         ,iv_offset_cust_code        => lt_offset_cust_code       -- 相殺用顧客コード
         ,iv_results_employee_code   => lt_results_employee_code  -- 成績計上者コード
         ,iv_cust_gyotai_sho         => lt_cust_gyotai_sho        -- 業態（小分類）
         ,in_tax_rate                => lt_tax_rate               -- 消費税率
         ,iv_tax_code                => lt_tax_code               -- 税金コード
         ,iv_consumption_tax_class   => lt_consumption_tax_class  -- 消費税区分
         ,iv_uom_code                => lt_uom_code               -- 基準単位
         ,in_business_cost           => lt_business_cost          -- 営業原価
         ,in_cash_and_card           => lt_cash_and_card          -- 現金・カード併用額
         ,ov_errbuf                  => lv_errbuf   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                 => lv_retcode  -- リターン・コード             --# 固定 #
         ,ov_errmsg                  => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP;
--
  -- ********************************
  -- ***  販売実績データ登録処理  ***
  -- ********************************
--
    --LOOP内でエラーがない場合
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- ===============================================
      -- 取引先販売実績データ登録処理(A-10)
      -- ===============================================
      ins_sales_bp_data(
        ov_errbuf         => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 販売実績データ登録処理(A-11)
      -- ===============================================
      ins_sales_data(
        ov_errbuf         => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode        => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg         => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --LOOPのエラーステータスがノーマルでない場合(ワーニング)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
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
    errbuf            OUT VARCHAR2  -- エラー・メッセージ  --# 固定 #
   ,retcode           OUT VARCHAR2  -- リターン・コード    --# 固定 #
   ,in_get_file_id    IN  NUMBER    -- ファイルID
   ,iv_get_format_pat IN  VARCHAR2  -- フォーマットパターン
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      in_get_file_id     -- ファイルID
     ,iv_get_format_pat  -- フォーマットパターン
     ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
     ,lv_retcode     -- リターン・コード             --# 固定 #
     ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    -- ===============================================
    -- 終了処理(A-12)
    -- ===============================================
    --エラー時処理
    IF ( lv_retcode = cv_status_error ) THEN
      --エラーメッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      --エラー件数設定
      gn_target_cnt   := 0;
      gn_hed_suc_cnt  := 0;
      gn_line_suc_cnt := 0;
      gn_error_cnt    := 1;
      --エラー時のROLLBACK
      ROLLBACK;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
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
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_suc_cnt)
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
--
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
END XXCOS018A01C;
/
