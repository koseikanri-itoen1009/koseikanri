CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS011A11C (body)
 * Description      : 個別商品販売実績ＥＤＩデータ作成
 * MD.050           : 個別商品販売実績ＥＤＩデータ作成 MD050_COS_011_A11
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                 初期処理(A-1)
 *  get_busines_date     対象業務日付算出処理(A-2)
 *  output_header        ファイル初期処理(A-3)
 *  get_sales_exp_data   販売実績情報抽出(A-4)
 *  make_sale_data       ファイルデータ成型処理(A-5、A-6)
 *  output_footer        ファイル終了処理(A-7)
 *  update_sale_header   販売実績ヘッダテーブルフラグ更新(A-8)
 *  update_sale_cancel   販売実績ヘッダテーブルフラグ更新「解除」(A-9)
 *  submain              メイン処理プロシージャ
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/02/25    1.0   Oukou            新規作成
 *  2011/03/25    1.1   Oukou            [E_本稼動_06945]個別商品販売実績作成の内容の対応
 *  2011/04/07    1.2   Oukou            [E_本稼動_07120]見本データを対象外にする対応
 *****************************************************************************************/
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  -- 日付
  cd_sysdate                CONSTANT DATE        := SYSDATE;                            -- システム日付
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS011A11C';                 -- パッケージ名
--
  cv_xxcos_short_name             CONSTANT VARCHAR2(10)  := 'XXCOS';                        -- アプリケーション名
--
  --プロファイル
  ct_prf_max_linesize             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';     -- XXCOS:ファイルに出力する1行のMAX桁サイズ
  ct_prf_outbound_dir             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_OUTBOUND_OM_DIR';  -- XXCOS:EDI受注系アウトバウンド用ディレクトリパス
  ct_prf_item_file                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_ITEM_FILE';   -- XXCOS:個別商品販売実績ファイル名
  ct_prf_comp_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_COMP_CODE';   -- XXCOS:個別商品販売実績会社コード
  ct_prf_org_code                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_ORG_CODE';    -- XXCOS:個別商品販売実績組織コード
  ct_prf_start_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_START_DATE';  -- XXCOS:個別商品販売実績対象開始日付
  ct_prf_past_day                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_PAST_DAY';    -- XXCOS:個別商品販売実績対象日数
  cv_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                      -- MO:営業単位
/* 2011/03/25 Ver1.1 ADD Start */
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';            -- XXCCP:IFレコード区分_ヘッダ
  ct_prf_dept_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BIZ_MAN_DEPT_CODE';    -- XXCOS:業務管理部コード
  ct_prf_specific_chain_code      CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_CHAIN_CODE';  -- XXCOS:個別商品販売実績用チェーン店コード
  ct_prf_parallel_process_num     CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_PARALLEL_PROCESS_NUM'; -- XXCOS:個別商品販売実績用並列処理番号
/* 2011/03/25 Ver1.1 ADD End   */
  --
  --メッセージ
  ct_msg_param_out_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14151';  -- パラメータ出力メッセージ
  ct_msg_param_date_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14152';  -- パラメータ日付書式エラーメッセージ
  ct_msg_param_mode_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14153';  -- パラメータ実行区分エラーメッセージ
  ct_msg_outbound_dir             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14154';  -- メッセージ用文字列.ディレクトリパス
  ct_msg_item_file                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14155';  -- メッセージ用文字列.ファイル名
  ct_msg_max_linesize             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14156';  -- メッセージ用文字列.UTL_MAX行サイズ
  ct_msg_comp_code                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14157';  -- メッセージ用文字列.会社コード
  ct_msg_org_code                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14158';  -- メッセージ用文字列.組織コード
  ct_msg_start_date               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14159';  -- メッセージ用文字列.対象開始日付
  ct_msg_past_day                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14160';  -- メッセージ用文字列.対象日数
  ct_msg_file                     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14161';  -- メッセージ用文字列.個別商品販売実績ファイル
  ct_msg_mst_chk_warm             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14162';  -- マスタ項目未設定警告メッセージ
  ct_msg_data_count               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14163';  -- 処理件数メッセージ
  ct_msg_non_business_date        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11601';  -- 業務日付取得エラー
  ct_msg_notfound_profile         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';  -- プロファイル取得エラー
  cv_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00044';  -- ファイル名出力
  cv_msg_lock_err                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';  -- ロックエラー
  cv_msg_file_o_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';  -- ファイルオープンエラー
  cv_msg_data_get_err             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013';  -- データ抽出エラー
  cv_msg_no_target_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';  -- 対象データなしエラー
  cv_msg_sale_exp_head_tab        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12364';  -- 販売実績ヘッダテーブル(文言)
  cv_msg_upd_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';  -- データ更新エラー
  cv_msg_non_business_date        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11601';  -- 業務日付取得エラー
  cv_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';  -- MO:営業単位
/* 2011/03/25 Ver1.1 ADD Start */
  ct_msg_f_h                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00104';  -- XXCCP:IFレコード区分_ヘッダ(文言)
  ct_msg_dept_c                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12358';  -- XXCOS:業務管理部コード(文言)
  ct_msg_specific_chain_code      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14164';  -- XXCOS:個別商品販売実績用チェーン店コード(文言)
  ct_msg_parallel_process_num     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14165';  -- XXCOS:個別商品販売実績用並列処理番号(文言)
  ct_msg_base_code_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00035';  -- 拠点情報取得エラー
  ct_msg_chain_inf_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00036';  -- チェーン店情報取得エラー
  ct_msg_proc_err                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00037';  -- 共通関数エラー
  ct_msg_table_tkn1               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00046';  -- クイックコード(文言)
  ct_msg_data_type_c              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12362';  -- データ種コード(文言)
  ct_msg_mst_chk_err              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10002';  -- マスタチェックエラー
/* 2011/03/25 Ver1.1 ADD End   */
  --
  -- トークン
  cv_tkn_profile                  CONSTANT VARCHAR2(20)  := 'PROFILE';           -- プロファイル名
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';         -- ファイル名
  cv_tkn_table                    CONSTANT VARCHAR2(20)  := 'TABLE';             -- テーブル
  cv_tkn_table_name               CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- テーブル名
  cv_tkn_key_data                 CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- キー情報
  cv_tkn_customer_code            CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';     -- 顧客コード
  cv_tkn_delivery_date            CONSTANT VARCHAR2(20)  := 'DELIVERY_DATE';     -- 納品日
  cv_tkn_item_code                CONSTANT VARCHAR2(20)  := 'ITEM_CODE';         -- 品目コード
  cv_tkn_address                  CONSTANT VARCHAR2(20)  := 'ADDRESS';           -- 地区コード
  cv_tkn_industry_div             CONSTANT VARCHAR2(20)  := 'INDUSTRY_DIV';      -- 業種
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';            -- 入力パラメータ1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';            -- 入力パラメータ2
  cv_tkn_count1                   CONSTANT VARCHAR2(20)  := 'COUNT1';            -- 処理件数1
  cv_tkn_count2                   CONSTANT VARCHAR2(20)  := 'COUNT2';            -- 処理件数2
  cv_tkn_count3                   CONSTANT VARCHAR2(20)  := 'COUNT3';            -- 処理件数3
  cv_tkn_count4                   CONSTANT VARCHAR2(20)  := 'COUNT4';            -- 処理件数4
/* 2011/03/25 Ver1.1 ADD Start */
  cv_tkn_base_code                CONSTANT VARCHAR2(20)  := 'CODE';              -- 拠点コード
  cv_tkn_chain_code               CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';   -- チェーン店コード
  cv_tkn_column                   CONSTANT VARCHAR2(20)  := 'COLMUN';            -- カラム名
  cv_tkn_err_msg                  CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- エラーメッセージ名
/* 2011/03/25 Ver1.1 ADD End   */
  --
  -- クイックコードタイプ
  cv_lt_edi_specific_item         CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_ITEM';      -- 品目コード
  cv_lt_edi_specific_industry     CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_INDUSTRY';  -- 業種コード
/* 2011/04/07 Ver1.2 ADD Start */
  cv_lt_edi_specific_sale_class   CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_SALE_CLASS';  -- 個別商品販売実績売上区分
/* 2011/04/07 Ver1.2 ADD END   */
  --
  -- その他
  cv_lang                         CONSTANT VARCHAR2(5)   := USERENV('LANG');     -- 言語
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                 -- UTL_FILE.オープンモード
  cv_date_format_sl               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- 日付フォーマット(年月日スラッシュ付き)
  cv_date_format                  CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- 日付フォーマット
  cv_blank                        CONSTANT VARCHAR2(1)   := '';                  -- 空文字
  cv_y                            CONSTANT VARCHAR2(1)   := 'Y';                 -- 固定値：Y
  cv_n                            CONSTANT VARCHAR2(1)   := 'N';                 -- 固定値：N
  cn_x                            CONSTANT VARCHAR2(1)   := 'X';                 -- 固定値：46(NUMBER)
  cv_0                            CONSTANT VARCHAR2(1)   := '0';                 -- 固定値：0
/* 2011/03/25 Ver1.1 ADD Start */
  cv_1                            CONSTANT VARCHAR2(1)   := '1';                 -- 固定値：1
  -- 顧客マスタ取得用固定値
  cv_cust_code_chain              CONSTANT VARCHAR2(2)   := '18';                -- 顧客区分(チェーン店)
  cv_status_a                     CONSTANT VARCHAR2(1)   := 'A';                 -- ステータス
  cv_data_type                    CONSTANT VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';    -- データ種
  cv_data_type_code               CONSTANT VARCHAR2(3)   := '180';                      -- 販売実績
/* 2011/03/25 Ver1.1 ADD End   */ 
  cv_run_class_cd_create          CONSTANT VARCHAR2(1)   := '1';                 -- 実行区分：「作成」
  cv_run_class_cd_cancel          CONSTANT VARCHAR2(1)   := '2';                 -- 実行区分：「解除」
  cv_run_class_cd_resend          CONSTANT VARCHAR2(1)   := '3';                 -- 実行区分：「再送信」
  cv_cust_status                  CONSTANT VARCHAR2(1)   := 'A';                 -- 顧客所在地ステータス「A」
  cv_industry_div                 CONSTANT VARCHAR2(2)   := '00';                -- 業種：「00」
  cn_0                            CONSTANT NUMBER        := 0;                   -- 固定値：0(NUMBER)
  cn_1                            CONSTANT NUMBER        := 1;                   -- 固定値：1(NUMBER)
  cn_46                           CONSTANT NUMBER        := 46;                  -- 固定値：46(NUMBER)
--
  -- ===================================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===================================
  -- 販売実績情報
  TYPE g_sales_data_rtype IS RECORD(
     orig_delivery_date          xxcos_sales_exp_headers.orig_delivery_date%TYPE
    ,ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    ,item_code                   xxcos_sales_exp_lines.item_code%TYPE
    ,standard_qty                xxcos_sales_exp_lines.standard_qty%TYPE
    ,address3                    hz_locations.address3%TYPE
    ,industry_div_flg            xxcmm_cust_accounts.industry_div%TYPE
    ,industry_div                xxcmm_cust_accounts.industry_div%TYPE
    ,item_name                   fnd_lookup_values.meaning%TYPE
    );
  -- 販売実績情報（更新）
  TYPE g_sales_update_rtype IS RECORD(
     orig_delivery_date          xxcos_sales_exp_headers.orig_delivery_date%TYPE
    ,ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    );
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  -- 販売実績情報
  TYPE g_sales_data_ttype    IS TABLE OF g_sales_data_rtype INDEX BY BINARY_INTEGER;
  -- 販売実績ヘッダ更新
  TYPE g_sales_update_ttype  IS TABLE OF g_sales_update_rtype INDEX BY BINARY_INTEGER;
  TYPE g_header_id_ttype     IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_cust_code_ttype     IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_business_date                DATE;                                                     -- 業務日付
  gd_business_date_start          DATE;                                                     -- 対象開始業務日付
  gd_business_date_end            DATE;                                                     -- 対象終了業務日付
  gf_file_handle                  UTL_FILE.FILE_TYPE;                                       -- ファイルハンドル
  gt_max_linesize                 fnd_profile_option_values.profile_option_value%TYPE;      -- MAXレコードサイズ
  gt_org_id                       fnd_profile_option_values.profile_option_value%TYPE;      -- 営業単位
  gt_outbound_dir                 fnd_profile_option_values.profile_option_value%TYPE;      -- 出力先ディレクトリ
  gt_item_file                    fnd_profile_option_values.profile_option_value%TYPE;      -- 出力ファイル名
  gt_org_code                     fnd_profile_option_values.profile_option_value%TYPE;      -- 組織コード
  gt_comp_code                    fnd_profile_option_values.profile_option_value%TYPE;      -- 会社コード
  gt_start_date                   fnd_profile_option_values.profile_option_value%TYPE;      -- 個別商品販売実績対象開始日付
  gt_past_day                     fnd_profile_option_values.profile_option_value%TYPE;      -- 個別商品販売実績対象日数
  gt_sale_data_tbl                g_sales_data_ttype;                                       -- 販売実績抽出データ格納
  gt_sale_update_tbl              g_sales_update_ttype;                                     -- 販売実績更新データ格納
  gt_sale_update_rec              g_sales_update_rtype;                                     -- 販売実績更新データ格納
  gt_update_header_id             g_header_id_ttype;                                        -- 販売実績更新データ格納（ヘッダID）
  gt_update_cust_code             g_cust_code_ttype;                                        -- 販売実績更新データ格納（顧客コード）
/* 2011/03/25 Ver1.1 ADD Start */
  gt_if_header                    fnd_profile_option_values.profile_option_value%TYPE;      -- IFレコード区分_ヘッダ
  gt_dept_code                    fnd_profile_option_values.profile_option_value%TYPE;      -- 業務管理部コード
  gt_specific_chain_code          fnd_profile_option_values.profile_option_value%TYPE;      -- 個別商品販売実績用チェーン店コード
  gt_parallel_process_num         fnd_profile_option_values.profile_option_value%TYPE;      -- 個別商品販売実績用並列処理番号
  gt_sales_base_name              hz_parties.party_name%TYPE;                               -- 拠点名
  gt_chain_name                   hz_parties.party_name%TYPE;                               -- チェーン店名
  gt_data_type_code               xxcos_lookup_values_v.lookup_code%TYPE;                   -- データ種コード
  gt_from_series                  xxcos_lookup_values_v.attribute1%TYPE;                    -- IF元業務系列コード
/* 2011/03/25 Ver1.1 ADD End   */
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  -- レコードロックエラー
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_act_mode   IN  VARCHAR2     -- 実行区分：「1:作成」「2:解除」「3:再送信」
   ,iv_date       IN  VARCHAR2     -- 送信日
   ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_profile_name   VARCHAR2(100) DEFAULT NULL;  -- プロファイル名
/* 2011/03/25 Ver1.1 ADD Start */
    lv_tkn_name1      VARCHAR2(50)  DEFAULT NULL;  -- トークン取得用1
    lv_tkn_name2      VARCHAR2(50)  DEFAULT NULL;  -- トークン取得用2
/* 2011/03/25 Ver1.1 ADD End   */
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
    -- ===============================
    -- コンカレントプログラム入力項目の出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_short_name
         ,ct_msg_param_out_err
         ,cv_tkn_prm1
         ,iv_act_mode        -- 実行区分
         ,cv_tkn_prm2
         ,iv_date            -- 送信日
         );
    --
    -- ===============================
    --  コンカレント・メッセージ出力
    -- ===============================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    -- ===============================
    --  業務日付取得
    -- ===============================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_business_date IS NULL ) THEN
      -- 業務日付が取得できない場合
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => cv_msg_non_business_date    -- メッセージ
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  営業単位
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE(
      name => cv_prf_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(営業単位)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => cv_msg_org_id                -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  出力先ディレクトリ取得
    -- ===============================
    gt_outbound_dir := FND_PROFILE.VALUE(
      name => ct_prf_outbound_dir);
    --
    IF ( gt_outbound_dir IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(出力先ディレクトリ)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_outbound_dir          -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  出力ファイル名取得
    -- ===============================
    gt_item_file := FND_PROFILE.VALUE(
      name => ct_prf_item_file);
    --
    IF ( gt_item_file IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(出力ファイル名)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_item_file             -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  MAXレコードサイズ取得
    -- ===============================
    gt_max_linesize := FND_PROFILE.VALUE(
      name => ct_prf_max_linesize);
    --
    IF ( gt_max_linesize IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(MAXレコードサイズ)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_max_linesize          -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  会社コード取得
    -- ===============================
    gt_comp_code := FND_PROFILE.VALUE(
      name => ct_prf_comp_code);
    --
    IF ( gt_comp_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(会社コード)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_comp_code             -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  組織コード取得
    -- ===============================
    gt_org_code := FND_PROFILE.VALUE(
      name => ct_prf_org_code);
    --
    IF ( gt_org_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(組織コード)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_org_code              -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  個別商品販売実績対象開始日付取得
    -- ===============================
    gt_start_date := FND_PROFILE.VALUE(
      name => ct_prf_start_date);
    --
    IF ( gt_start_date IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(個別商品販売実績対象開始日付)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_start_date            -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  個別商品販売実績対象日数取得
    -- ===============================
    gt_past_day := FND_PROFILE.VALUE(
      name => ct_prf_past_day);
    --
    IF ( gt_past_day IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(会社コード)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_past_day              -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2011/03/25 Ver1.1 ADD Start */
    -- ===============================
    --  IFレコード区分_ヘッダ取得
    -- ===============================
    gt_if_header := FND_PROFILE.VALUE(
      name => ct_prf_if_header);
    --
    IF ( gt_if_header IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(IFレコード区分_ヘッダ)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_f_h                   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 業務管理部コード取得
    -- ===============================
    gt_dept_code := FND_PROFILE.VALUE(
      name => ct_prf_dept_code);
    --
    IF ( gt_dept_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(業務管理部コード)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_dept_c                -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 個別商品販売実績用チェーン店コード
    -- ===============================
    gt_specific_chain_code := FND_PROFILE.VALUE(
      name => ct_prf_specific_chain_code);
    --
    IF ( gt_specific_chain_code IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(個別商品販売実績用チェーン店コード)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_specific_chain_code   -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 個別商品販売実績用並列処理番号
    -- ===============================
    gt_parallel_process_num := FND_PROFILE.VALUE(
      name => ct_prf_parallel_process_num);
    --
    IF ( gt_parallel_process_num IS NULL ) THEN
      -- プロファイルが取得できない場合
      -- プロファイル名取得(個別商品販売実績用並列処理番号)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- アプリケーション短縮名
        ,iv_name        => ct_msg_parallel_process_num  -- メッセージID
      );
      -- メッセージ作成
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- アプリケーション短縮名
        ,iv_name         => ct_msg_notfound_profile     -- メッセージ
        ,iv_token_name1  => cv_tkn_profile              -- トークン1名
        ,iv_token_value1 => lv_profile_name);           -- トークン1値
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 拠点情報取得
    -- ===============================
    BEGIN
      SELECT  hp.party_name       sales_base_name      -- 拠点名
      INTO    gt_sales_base_name
      FROM    hz_cust_accounts    hca                  -- 拠点(顧客)
             ,hz_parties          hp                   -- 拠点(パーティ)
      WHERE   hca.party_id             = hp.party_id   -- 結合(拠点(顧客) = 拠点(パーティ))
      AND     hca.account_number       = gt_dept_code  -- 業務管理部コード
      AND     hca.customer_class_code  = cv_1          -- 顧客区分=1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name      -- アプリケーション
          ,iv_name         => ct_msg_base_code_err     -- 拠点情報取得エラー
          ,iv_token_name1  => cv_tkn_base_code         -- トークンコード1
          ,iv_token_value1 => gt_dept_code);           -- 業務管理部コード
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ===============================
    -- チェーン店情報取得
    -- ===============================
    BEGIN
      SELECT  hp.party_name                chain_name              -- チェーン店名
      INTO    gt_chain_name
      FROM    hz_cust_accounts             hca                     -- 顧客マスタ
             ,xxcmm_cust_accounts          xca                     -- 顧客アドオンマスタ
             ,hz_parties                   hp                      -- パーティマスタ
      WHERE   hca.cust_account_id       =  xca.customer_id         -- 結合(顧客 = 顧客アドオン)
      AND     hca.party_id              =  hp.party_id             -- 結合(顧客 = パーティ)
      AND     xca.edi_chain_code        =  gt_specific_chain_code  -- チェーン店コード
      AND     hca.customer_class_code   =  cv_cust_code_chain      -- 顧客区分(チェーン店)
      AND     hca.status                =  cv_status_a             -- ステータス(有効)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name        -- アプリケーション
          ,iv_name         => ct_msg_chain_inf_err       -- チェーン店情報取得エラー
          ,iv_token_name1  => cv_tkn_chain_code          -- トークンコード1
          ,iv_token_value1 => gt_specific_chain_code);   -- チェーン店コード
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ===============================
    -- データ種情報取得
    -- ===============================
    BEGIN
      SELECT  xlvv.meaning     meaning                       -- データ種
             ,xlvv.attribute1  attribute1                    -- IF元業務系列コード
      INTO    gt_data_type_code
             ,gt_from_series
      FROM    xxcos_lookup_values_v xlvv
      WHERE   xlvv.lookup_type  = cv_data_type               -- データ種
      AND     xlvv.lookup_code  = cv_data_type_code          -- 「180」
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= gd_business_date )
              )
      AND     (
                ( xlvv.end_date_active   IS NULL )
                OR
                ( xlvv.end_date_active >= gd_business_date )
              )  -- 業務日付がFROM-TO内
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application =>  cv_xxcos_short_name
                          ,iv_name        =>  ct_msg_data_type_c    --「データ種コード」
                        );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_name
                          ,iv_name         => ct_msg_table_tkn1     --「クイックコード」
                        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name     -- アプリケーション
                        ,iv_name         => ct_msg_mst_chk_err      -- マスタチェックエラー
                        ,iv_token_name1  => cv_tkn_column           -- トークンコード１
                        ,iv_token_value1 => lv_tkn_name1            -- データ種コード
                        ,iv_token_name2  => cv_tkn_table            -- トークンコード２
                        ,iv_token_value2 => lv_tkn_name2            -- クイックコードテーブル
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2011/03/25 Ver1.1 ADD End   */
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_busines_date
   * Description      : 対象業務日付算出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_busines_date(
    iv_act_mode      IN  VARCHAR2,     -- 実行区分：「1:作成」「2:解除」「3:再送信」
    iv_date          IN  VARCHAR2,     -- 送信日
    ov_errbuf        OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_busines_date'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    IF ( iv_act_mode = cv_run_class_cd_create ) THEN
      -- パラメータ.実行区分が「1:作成」の場合
      IF ( iv_date IS NULL ) THEN
        -- パラメータ.送信日がNULLの場合
        gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
        gd_business_date_end   := gd_business_date;
      ELSE
        -- パラメータ.送信日がNULL以外の場合
        gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
        gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);      
      END IF;
    ELSIF ( iv_act_mode = cv_run_class_cd_cancel ) THEN
      -- パラメータ.実行区分が「2:解除」の場合
      gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
      gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);        
    ELSE
      -- パラメータ.実行区分が「3:再送信」の場合
      gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
      gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);          
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
  END get_busines_date;
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : ファイル初期処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_header(
    ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header';           -- プログラム名
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
    lv_header_output  VARCHAR2(5000) DEFAULT NULL;        --IFヘッダー出力用
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
    -- ===============================
        -- 出力ファイル名の出力
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
          cv_xxcos_short_name
         ,cv_msg_file_name
         ,cv_tkn_filename
         ,gt_item_file
         );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
--
    -- ===============================
    -- ファイルオープン
    -- ===============================
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          gt_outbound_dir
                         ,gt_item_file
                         ,cv_utl_file_mode
                         ,gt_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_xxcos_short_name
                      ,cv_msg_file_o_err
                      ,cv_tkn_filename
                      ,gt_item_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    --
/* 2011/03/25 Ver1.1 ADD Start */
    -- ===============================
    -- 共通関数呼び出し
    -- ===============================
    --EDIヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gt_if_header             --付与区分
     ,iv_from_series     =>  gt_from_series           --IF元業務系列コード
     ,iv_base_code       =>  gt_dept_code             --拠点コード(業務処理部コード)
     ,iv_base_name       =>  gt_sales_base_name       --拠点名称
     ,iv_chain_code      =>  gt_specific_chain_code   --チェーン店コード
     ,iv_chain_name      =>  gt_chain_name            --チェーン店名称
     ,iv_data_kind       =>  gt_data_type_code        --データ種コード
     ,iv_row_number      =>  gt_parallel_process_num  --並列処理番号
     ,in_num_of_records  =>  NULL                     --レコード件数
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name   --アプリケーション
        ,iv_name         => ct_msg_proc_err       --共通関数エラー
        ,iv_token_name1  => cv_tkn_err_msg        --トークンコード１
        ,iv_token_value1 => lv_errmsg);           --共通関数のエラーメッセージ
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- 共通関数呼び出し
    -- ===============================
    UTL_FILE.PUT_LINE(
      file   => gf_file_handle    --ファイルハンドル
     ,buffer => lv_header_output  --出力文字(データ)
    );
/* 2011/03/25 Ver1.1 ADD End   */
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
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_data
   * Description      : 販売実績情報抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_data(
    iv_act_mode      IN  VARCHAR2,     -- 実行区分：「1:作成」「2:解除」「3:再送信」
    iv_date          IN  VARCHAR2,     -- 送信日
    ov_errbuf        OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_data'; -- プログラム名
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
    lv_table_name       VARCHAR2(50);    -- テーブル名
--
    -- *** ローカル・カーソル ***
    -- 販売実績情報(作成)
    CURSOR sale_data_create_cur
    IS
      SELECT /*+ LEADING(xseh)
             INDEX(xseh xxcos_sales_exp_headers_n06)
             USE_NL(xseh xsel flv)
             USE_NL(xseh hca)
             USE_NL(hca xca hcas hps hpa hlo flv1) */
             xseh.orig_delivery_date            orig_delivery_date         -- 納品日
            ,xseh.ship_to_customer_code         ship_to_customer_code      -- 顧客コード
            ,xsel.item_code                     item_code                  -- 品目コード
            ,NVL(xsel.standard_qty, cn_0)       standard_qty               -- 数量
            ,hlo.address3                       address3                   -- 地区コード
            ,DECODE(xca.industry_div, NULL, xca.industry_div,
                    NVL(flv1.description1, cv_industry_div))
                                                industry_div_flg           -- 業種識別フラグ
            ,xca.industry_div                   industry_div               -- 業種
            ,SUBSTRB(flv.meaning, cn_1, cn_46)  item_name                  -- 品名
      FROM   hz_cust_accounts                   hca                        -- 顧客マスタ
            ,hz_cust_acct_sites_all             hcas                       -- 顧客サイトマスタ
            ,hz_parties                         hpa                        -- パーティマスタ
            ,hz_party_sites                     hps                        -- パーティサイトマスタ
            ,hz_locations                       hlo                        -- 顧客事業所マスタ
            ,xxcmm_cust_accounts                xca                        -- 顧客アドオン
            ,fnd_lookup_values                  flv                        -- LookUp参照テーブル
            ,xxcos_sales_exp_headers            xseh                       -- 販売実績ヘッダ
            ,xxcos_sales_exp_lines              xsel                       -- 販売実績明細
            ,(
              SELECT flv2.lookup_code  lookup_code1
                    ,flv2.meaning      meaning1
                    ,flv2.description  description1
              FROM   fnd_lookup_values flv2
              WHERE  flv2.lookup_type     = cv_lt_edi_specific_industry
                AND  flv2.language        = cv_lang
                AND  flv2.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv2.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv2.end_date_active, gd_business_date)
             )  flv1
/* 2011/04/07 Ver1.2 ADD Start */
            ,(
              SELECT flv4.lookup_code  lookup_code      -- 売上区分
              FROM   fnd_lookup_values flv4
              WHERE  flv4.lookup_type     = cv_lt_edi_specific_sale_class
                AND  flv4.language        = cv_lang
                AND  flv4.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv4.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv4.end_date_active, gd_business_date)
             )  flv3
/* 2011/04/07 Ver1.2 ADD END   */
      WHERE xseh.sales_exp_header_id       = xsel.sales_exp_header_id
        AND xseh.item_sales_send_flag      IS NULL
        AND xseh.business_date             >= gd_business_date_start
        AND xseh.business_date             <= gd_business_date_end
        AND xseh.orig_delivery_date        >= TO_DATE(gt_start_date, cv_date_format_sl)
        AND flv.lookup_type                = cv_lt_edi_specific_item
        AND flv.language                   = cv_lang
        AND flv.enabled_flag               = cv_y
        AND gd_business_date               >= NVL(flv.start_date_active, gd_business_date)
        AND gd_business_date               <= NVL(flv.end_date_active, gd_business_date)
        AND xsel.item_code                 = flv.lookup_code
        AND hca.account_number             = xseh.ship_to_customer_code
        AND hca.cust_account_id            = xca.customer_id
        AND hca.party_id                   = hpa.party_id
        AND hpa.party_id                   = hps.party_id
        AND hca.cust_account_id            = hcas.cust_account_id
        AND hcas.party_site_id             = hps.party_site_id
        AND hcas.org_id                    = gt_org_id
        AND hcas.status                    = cv_cust_status
        AND hps.location_id                = hlo.location_id
        AND xca.industry_div               = flv1.lookup_code1(+)
/* 2011/04/07 Ver1.2 ADD Start */
        AND xsel.sales_class                = flv3.lookup_code
/* 2011/04/07 Ver1.2 ADD END   */
      ORDER BY xseh.orig_delivery_date
               ,hlo.address3
               ,DECODE(xca.industry_div, NULL, xca.industry_div,
                       NVL(flv1.description1, cv_industry_div))
               ,xsel.item_code
               ,xseh.ship_to_customer_code
      FOR UPDATE OF xseh.sales_exp_header_id NOWAIT
      ;
    --
    -- 販売実績情報(再送信)
    CURSOR sale_data_resend_cur(id_date  IN  DATE)
    IS
      SELECT /*+ LEADING(xseh)
             INDEX(xseh xxcos_sales_exp_headers_n06)
             USE_NL(xseh xsel flv)
             USE_NL(xseh hca)
             USE_NL(hca xca hcas hps hpa hlo flv1) */
             xseh.orig_delivery_date            orig_delivery_date         -- 納品日
            ,xseh.ship_to_customer_code         ship_to_customer_code      -- 顧客コード
            ,xsel.item_code                     item_code                  -- 品目コード
            ,NVL(xsel.standard_qty, cn_0)       standard_qty               -- 数量
            ,hlo.address3                       address3                   -- 地区コード
            ,DECODE(xca.industry_div, NULL, xca.industry_div,
                    NVL(flv1.description1, cv_industry_div))
                                                industry_div_flg           -- 業種識別フラグ
            ,xca.industry_div                   industry_div               -- 業種
            ,SUBSTRB(flv.meaning, cn_1, cn_46)  item_name                  -- 品名
      FROM   hz_cust_accounts                   hca                        -- 顧客マスタ
            ,hz_cust_acct_sites_all             hcas                       -- 顧客サイトマスタ
            ,hz_parties                         hpa                        -- パーティマスタ
            ,hz_party_sites                     hps                        -- パーティサイトマスタ
            ,hz_locations                       hlo                        -- 顧客事業所マスタ
            ,xxcmm_cust_accounts                xca                        -- 顧客アドオン
            ,fnd_lookup_values                  flv                        -- LookUp参照テーブル
            ,xxcos_sales_exp_headers            xseh                       -- 販売実績ヘッダ
            ,xxcos_sales_exp_lines              xsel                       -- 販売実績明細
            ,(
              SELECT flv2.lookup_code  lookup_code1
                    ,flv2.meaning      meaning1
                    ,flv2.description  description1
              FROM   fnd_lookup_values flv2
              WHERE  flv2.lookup_type     = cv_lt_edi_specific_industry
                AND  flv2.language        = cv_lang
                AND  flv2.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv2.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv2.end_date_active, gd_business_date)
             )  flv1
/* 2011/04/07 Ver1.2 ADD Start */
            ,(
              SELECT flv4.lookup_code  lookup_code
              FROM   fnd_lookup_values flv4
              WHERE  flv4.lookup_type     = cv_lt_edi_specific_sale_class
                AND  flv4.language        = cv_lang
                AND  flv4.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv4.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv4.end_date_active, gd_business_date)
             )  flv3
/* 2011/04/07 Ver1.2 ADD END   */
      WHERE xseh.sales_exp_header_id       = xsel.sales_exp_header_id
        AND xseh.item_sales_send_flag      IS NULL
        AND xseh.business_date             >= gd_business_date_start
        AND xseh.business_date             <= gd_business_date_end
        AND xseh.orig_delivery_date        >= TO_DATE(gt_start_date, cv_date_format_sl)
        AND flv.lookup_type                = cv_lt_edi_specific_item
        AND flv.language                   = cv_lang
        AND flv.enabled_flag               = cv_y
        AND gd_business_date               >= NVL(flv.start_date_active, gd_business_date)
        AND gd_business_date               <= NVL(flv.end_date_active, gd_business_date)
        AND xsel.item_code                 = flv.lookup_code
        AND hca.account_number             = xseh.ship_to_customer_code
        AND hca.cust_account_id            = xca.customer_id
        AND hca.party_id                   = hpa.party_id
        AND hpa.party_id                   = hps.party_id
        AND hca.cust_account_id            = hcas.cust_account_id
        AND hcas.party_site_id             = hps.party_site_id
        AND hcas.org_id                    = gt_org_id
        AND hcas.status                    = cv_cust_status
        AND hps.location_id                = hlo.location_id
        AND xca.industry_div               = flv1.lookup_code1(+)
        AND xseh.item_sales_send_date      = id_date
/* 2011/04/07 Ver1.2 ADD Start */
        AND xsel.sales_class                = flv3.lookup_code
/* 2011/04/07 Ver1.2 ADD END   */
      ORDER BY xseh.orig_delivery_date
               ,hlo.address3
               ,DECODE(xca.industry_div, NULL, xca.industry_div,
                       NVL(flv1.description1, cv_industry_div))
               ,xsel.item_code
               ,xseh.ship_to_customer_code
      FOR UPDATE OF xseh.sales_exp_header_id NOWAIT
      ;
  --
      -- *** ローカル・レコード ***
  --
      -- *** ローカル例外 ***
      sale_data_expt              EXCEPTION;   -- データ抽出エラー
      lock_expt                   EXCEPTION;   -- ロックエラー
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
        IF ( iv_act_mode = cv_run_class_cd_create ) THEN
          -- パラメータ.実行区分が「1:作成」の場合
          -- カーソルオープン
          OPEN sale_data_create_cur;
          --
          -- レコード読込み
          FETCH sale_data_create_cur BULK COLLECT INTO gt_sale_data_tbl;
          --
          -- 抽出件数設定
          gn_target_cnt := gt_sale_data_tbl.COUNT;
          --
          -- カーソル・クローズ
          CLOSE sale_data_create_cur;
        ELSIF ( iv_act_mode = cv_run_class_cd_resend ) THEN
          -- パラメータ.実行区分が「3:再送信」の場合
          -- カーソルオープン
          OPEN sale_data_resend_cur(TO_DATE(iv_date, cv_date_format_sl));
          --
          -- レコード読込み
          FETCH sale_data_resend_cur BULK COLLECT INTO gt_sale_data_tbl;
          --
          -- 抽出件数設定
          gn_target_cnt := gt_sale_data_tbl.COUNT;
          --
          -- カーソル・クローズ
          CLOSE sale_data_resend_cur;
        END IF;
      EXCEPTION
        -- ロックエラー
        WHEN record_lock_expt THEN
          RAISE lock_expt;
        WHEN OTHERS THEN
          -- 抽出に失敗した場合
          lv_errbuf := SQLERRM;
          RAISE sale_data_expt;
      END;
      --
      -- 抽出件数チェック
      IF ( gn_target_cnt = cn_0 ) THEN
        -- 抽出データが無い場合
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- メッセージ作成
        gv_out_msg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_no_target_err
        );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
        );
      END IF;
  --
    EXCEPTION
  --
      WHEN lock_expt THEN
        --*** ロックエラー ***
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- メッセージ文字列取得
        lv_table_name := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_sale_exp_head_tab
        );
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_lock_err
         ,iv_token_name1  => cv_tkn_table
         ,iv_token_value1 => lv_table_name
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# 任意 #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
        ov_retcode := cv_status_error;                                            --# 任意 #
        --
      WHEN sale_data_expt THEN
        --*** データ抽出エラー ***
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- メッセージ文字列取得
        lv_table_name := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_sale_exp_head_tab
        );
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_data_get_err
         ,iv_token_name1  => cv_tkn_table_name
         ,iv_token_value1 => lv_table_name
         ,iv_token_name2  => cv_tkn_key_data
         ,iv_token_value2 => cv_blank
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# 任意 #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : make_sale_data
   * Description      : ファイルデータ成型処理(A-5、A-6)
   ***********************************************************************************/
  PROCEDURE make_sale_data(
    ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sale_data'; -- プログラム名
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
    cv_minus         CONSTANT VARCHAR2(1)  := '-';                                   -- マイナス
    cv_space_1       CONSTANT VARCHAR2(1)  := SUBSTRB(LPAD('X', 2, ' '), 1, 1);      -- 1文字スペース
    cv_space_2       CONSTANT VARCHAR2(2)  := SUBSTRB(LPAD('X', 3, ' '), 1, 2);      -- 2文字スペース
    cv_space_4       CONSTANT VARCHAR2(4)  := SUBSTRB(LPAD('X', 5, ' '), 1, 4);      -- 4文字スペース
    cv_space_14      CONSTANT VARCHAR2(14) := SUBSTRB(LPAD('X', 15, ' '), 1, 14);    -- 14文字スペース
    cv_space_40      CONSTANT VARCHAR2(40) := SUBSTRB(LPAD('X', 41, ' '), 1, 40);    -- 40文字スペース
    cv_space_46      CONSTANT VARCHAR2(46) := SUBSTRB(LPAD('X', 47, ' '), 1, 46);    -- 46文字スペース
    cv_zero_7        CONSTANT VARCHAR2(7)  := '0000000';                             -- 7桁0
    cv_zero_5        CONSTANT VARCHAR2(5)  := '00000';                               -- 5桁0
--
    -- *** ローカル変数 ***
    ln_quantity      NUMBER;                              -- 合計数量
    ln_seq           NUMBER;                              -- 添字用(A-8の処理用)
    ln_cnt           NUMBER;                              -- 更新顧客件数
    ln_normal_cnt    NUMBER;                              -- 成功件数
    ln_warn_cnt      NUMBER;                              -- 警告件数
    lv_upd_flg       VARCHAR2(1);                         -- データ編集フラグ
    lv_data_record   VARCHAR2(32767);                     -- 編集後のデータ取得用
    l_date_rec       g_sales_data_rtype;                  -- 出力データレコード
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
    ln_seq        := cn_0;
    ln_normal_cnt := cn_0;
    ln_warn_cnt   := cn_0;
    l_date_rec    := gt_sale_data_tbl(cn_1);
    -- 合計数量
    ln_quantity   := NVL(l_date_rec.standard_qty, 0);
    -- 更新対象顧客編集
    ln_cnt := cn_1;
    gt_update_cust_code(ln_cnt) := l_date_rec.ship_to_customer_code;
    --
    -- 販売実績データ取得
    <<sale_loop>>
    FOR ln_idx IN 2..gt_sale_data_tbl.COUNT LOOP
      IF ( l_date_rec.address3 = cv_zero_5
           OR l_date_rec.address3 IS NULL
           OR l_date_rec.industry_div_flg IS NULL ) THEN
        -- 地区コードが’00000’また地区コード、業種が設定されていない場合
        IF (( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) != NVL(l_date_rec.address3, cn_x)
             OR gt_sale_data_tbl(ln_idx).industry_div_flg != l_date_rec.industry_div_flg
             OR gt_sale_data_tbl(ln_idx).orig_delivery_date != l_date_rec.orig_delivery_date
             OR gt_sale_data_tbl(ln_idx).item_code != l_date_rec.item_code )
            OR
            ( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) = NVL(l_date_rec.address3, cn_x)
             AND gt_sale_data_tbl(ln_idx).industry_div_flg = l_date_rec.industry_div_flg
             AND gt_sale_data_tbl(ln_idx).orig_delivery_date = l_date_rec.orig_delivery_date
             AND gt_sale_data_tbl(ln_idx).item_code = l_date_rec.item_code 
             AND gt_sale_data_tbl(ln_idx).ship_to_customer_code != l_date_rec.ship_to_customer_code )) THEN
          -- 顧客コードが前レコードデータと同一の場合
          -- メッセージ作成(マスタ項目未設定)
          gv_out_msg := xxccp_common_pkg.get_msg(
            iv_application  => cv_xxcos_short_name
           ,iv_name         => ct_msg_mst_chk_warm
           ,iv_token_name1  => cv_tkn_customer_code
           ,iv_token_value1 => l_date_rec.ship_to_customer_code
           ,iv_token_name2  => cv_tkn_delivery_date
           ,iv_token_value2 => TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format_sl)
           ,iv_token_name3  => cv_tkn_item_code
           ,iv_token_value3 => l_date_rec.item_code
           ,iv_token_name4  => cv_tkn_address
           ,iv_token_value4 => l_date_rec.address3
           ,iv_token_name5  => cv_tkn_industry_div
           ,iv_token_value5 => l_date_rec.industry_div
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- 警告件数加算
          ln_warn_cnt := ln_warn_cnt + cn_1;
        END IF;
        -- 合計数量
        ln_quantity := gt_sale_data_tbl(ln_idx).standard_qty;
        -- 更新対象顧客編集
        ln_cnt := cn_1;
        gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
      ELSE
        IF ( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) = NVL(l_date_rec.address3, cn_x)
             AND gt_sale_data_tbl(ln_idx).industry_div_flg = l_date_rec.industry_div_flg
             AND gt_sale_data_tbl(ln_idx).orig_delivery_date = l_date_rec.orig_delivery_date
             AND gt_sale_data_tbl(ln_idx).item_code = l_date_rec.item_code) THEN
          -- 地区コード、業種、納品日、品目が前レコードと同一の場合
          -- 合計数量
          ln_quantity := ln_quantity + gt_sale_data_tbl(ln_idx).standard_qty;
          -- 
          IF ( gt_sale_data_tbl(ln_idx).ship_to_customer_code != l_date_rec.ship_to_customer_code ) THEN
            -- 更新対象顧客編集
            ln_cnt := ln_cnt + cn_1;
            gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
          END IF;
        ELSE
          -- 合計数量が0以外
          IF ( ln_quantity != cn_0 ) THEN
            -- ===============================
            -- データ成型(A-5)
            -- ===============================
            --
            lv_data_record := NULL;
            --出力データ設定
            lv_data_record := RPAD(gt_comp_code, 12, cv_space_1)                          ||      -- 会社コード
                              RPAD(gt_org_code, 8, cv_space_1)                            ||      -- 組織コード
                              cv_space_4                                                  ||      -- 予備１
                              cv_space_14                                                 ||      -- 会社名称
                              cv_space_14                                                 ||      -- 組織名称
                              RPAD(l_date_rec.address3, 12, cv_space_1)                   ||      -- 得意先コード
                              cv_space_2                                                  ||      -- 予備２
                              cv_space_14                                                 ||      -- 電話番号
                              cv_space_40                                                 ||      -- 得意先名称
                              cv_space_46                                                 ||      -- 得意先住所
                              RPAD(l_date_rec.item_code, 16, cv_space_1)                  ||      -- 商品コード
                              RPAD(l_date_rec.item_name, 46, cv_space_1)                  ||      -- 商品名称
                              TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format)      ||      -- 納品日
                              RPAD(l_date_rec.industry_div_flg, 2, cv_space_1)            ||      -- 識別フラグ
                              cv_space_1                                                  ||      -- ケース数量符号
                              cv_zero_7                                                   ||      -- ケース数量
                              CASE 
                                WHEN ln_quantity < cn_0 THEN cv_minus ELSE cv_space_1
                              END                                                         ||      -- バラ数量符号
                              LPAD(TO_CHAR(ABS(ln_quantity)), 7, cv_0)                    ||      -- バラ数量
                              cv_space_2                                                          -- 予備３
            ;
            -- ===============================
            -- ファイル出力(A-6)
            -- ===============================
            UTL_FILE.PUT_LINE(
              file   => gf_file_handle  --ファイルハンドル
             ,buffer => lv_data_record  --出力文字(データ)
            );
            --
            -- 成功件数加算
            ln_normal_cnt := ln_normal_cnt + cn_1;
            --
          END IF;
          --
          -- 更新処理(A-8)で使用するデータの編集
          FOR i IN 1..ln_cnt LOOP
            lv_upd_flg := cv_y;
            FOR j IN 1..ln_seq LOOP
              IF ( gt_sale_update_tbl(j).orig_delivery_date = l_date_rec.orig_delivery_date 
                   AND gt_sale_update_tbl(j).ship_to_customer_code = gt_update_cust_code(i) ) THEN
                lv_upd_flg := cv_n;
                EXIT;
              END IF;
            END LOOP;
            IF ( lv_upd_flg = cv_y ) THEN
              ln_seq := ln_seq + cn_1;
              gt_sale_update_rec.ship_to_customer_code := gt_update_cust_code(i);
              gt_sale_update_rec.orig_delivery_date := l_date_rec.orig_delivery_date;
              gt_sale_update_tbl(ln_seq) := gt_sale_update_rec;
            END IF;
          END LOOP;
          -- 合計数量
          ln_quantity := gt_sale_data_tbl(ln_idx).standard_qty;
          -- 更新対象顧客編集
          ln_cnt := cn_1;
          gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
        END IF;
      END IF;
      --
      l_date_rec := gt_sale_data_tbl(ln_idx);
    END LOOP sale_loop;
    --
    IF ( l_date_rec.address3 = cv_zero_5
         OR l_date_rec.address3 IS NULL 
         OR l_date_rec.industry_div_flg IS NULL ) THEN
      -- 地区コードが’00000’また地区コード、業種が設定されていない場合
      -- メッセージ作成(マスタ項目未設定)
      gv_out_msg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => ct_msg_mst_chk_warm
       ,iv_token_name1  => cv_tkn_customer_code
       ,iv_token_value1 => l_date_rec.ship_to_customer_code
       ,iv_token_name2  => cv_tkn_delivery_date
       ,iv_token_value2 => TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format_sl)
       ,iv_token_name3  => cv_tkn_item_code
       ,iv_token_value3 => l_date_rec.item_code
       ,iv_token_name4  => cv_tkn_address
       ,iv_token_value4 => l_date_rec.address3
       ,iv_token_name5  => cv_tkn_industry_div
       ,iv_token_value5 => l_date_rec.industry_div
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- 警告件数加算
      ln_warn_cnt := ln_warn_cnt + cn_1;
    ELSE
      IF ( ln_quantity != cn_0 ) THEN
        -- 合計数量が0以外
        -- ===============================
        -- データ成型(A-5)
        -- ===============================
        lv_data_record := NULL;
        --出力データ設定
        lv_data_record := RPAD(gt_comp_code, 12, cv_space_1)                          ||      -- 会社コード
                          RPAD(gt_org_code, 8, cv_space_1)                            ||      -- 組織コード
                          cv_space_4                                                  ||      -- 予備１
                          cv_space_14                                                 ||      -- 会社名称
                          cv_space_14                                                 ||      -- 組織名称
                          RPAD(l_date_rec.address3, 12, cv_space_1)                   ||      -- 得意先コード
                          cv_space_2                                                  ||      -- 予備２
                          cv_space_14                                                 ||      -- 電話番号
                          cv_space_40                                                 ||      -- 得意先名称
                          cv_space_46                                                 ||      -- 得意先住所
                          RPAD(l_date_rec.item_code, 16, cv_space_1)                  ||      -- 商品コード
                          RPAD(l_date_rec.item_name, 46, cv_space_1)                  ||      -- 商品名称
                          TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format)      ||      -- 納品日
                          RPAD(l_date_rec.industry_div_flg, 2, cv_space_1)            ||      -- 識別フラグ
                          cv_space_1                                                  ||      -- ケース数量符号
                          cv_zero_7                                                   ||      -- ケース数量
                          CASE 
                            WHEN ln_quantity < cn_0 THEN cv_minus ELSE cv_space_1
                          END                                                         ||      -- バラ数量符号
                          LPAD(TO_CHAR(ABS(ln_quantity)), 7, cv_0)                    ||      -- バラ数量
                          cv_space_2                                                          -- 予備３
        ;
        -- ===============================
        -- ファイル出力(A-6)
        -- ===============================
        UTL_FILE.PUT_LINE(
          file   => gf_file_handle  --ファイルハンドル
         ,buffer => lv_data_record  --出力文字(データ)
        );
        -- 成功件数加算
        ln_normal_cnt := ln_normal_cnt + cn_1;
        --
      END IF;
      --
      -- 更新処理(A-8)で使用するデータの編集
      FOR i IN 1..ln_cnt LOOP
        lv_upd_flg := cv_y;
        FOR j IN 1..ln_seq LOOP
          IF ( gt_sale_update_tbl(j).orig_delivery_date = l_date_rec.orig_delivery_date 
               AND gt_sale_update_tbl(j).ship_to_customer_code = gt_update_cust_code(i) ) THEN
            lv_upd_flg := cv_n;
            EXIT;
          END IF;
        END LOOP;
        IF ( lv_upd_flg = cv_y ) THEN
          ln_seq := ln_seq + cn_1;
          gt_sale_update_rec.ship_to_customer_code := gt_update_cust_code(i);
          gt_sale_update_rec.orig_delivery_date := l_date_rec.orig_delivery_date;
          gt_sale_update_tbl(ln_seq) := gt_sale_update_rec;
        END IF;
      END LOOP;
    END IF;
    --
    -- 成功件数の設定
    gn_normal_cnt := ln_normal_cnt;
    -- 警告件数の設定
    gn_warn_cnt   := ln_warn_cnt;
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
      -- 成功件数の設定
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END make_sale_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : ファイル初期処理(A-7)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer';           -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    --ファイルクローズ
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gf_file_handle
    );
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
      -- 成功件数の設定
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : update_sale_header
   * Description      : 販売実績ヘッダテーブルフラグ更新「送信済」(A-8)
   ***********************************************************************************/
  PROCEDURE update_sale_header(
    iv_act_mode   IN  VARCHAR2     -- 実行区分：「1:作成」「2:解除」「3:再送信」
   ,iv_date       IN  VARCHAR2     -- 送信日
   ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sale_header';           -- プログラム名
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
    lv_tkn_name fnd_new_messages.message_text%TYPE;     --トークン取得用
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
      -- 販売実績ヘッダTBLフラグ更新（送信済）
      <<sale_update>>
      FOR i IN  1.. gt_sale_update_tbl.COUNT LOOP
        UPDATE  xxcos_sales_exp_headers         xseh  --販売実績ヘッダ
        SET     xseh.item_sales_send_date       = DECODE(iv_act_mode,
                                                         cv_run_class_cd_create, gd_business_date,
                                                         cv_run_class_cd_resend, TO_DATE(iv_date, cv_date_format_sl))
                                                                             -- 商品別販売実績送信日
               ,xseh.item_sales_send_flag       = cv_y                       -- 商品別販売実績送信済フラグ
               ,xseh.last_updated_by            = cn_last_updated_by         -- 最終更新者
               ,xseh.last_update_date           = cd_last_update_date        -- 最終更新日
               ,xseh.last_update_login          = cn_last_update_login       -- 最終更新ログイン
               ,xseh.request_id                 = cn_request_id              -- 要求ID
               ,xseh.program_application_id     = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
               ,xseh.program_id                 = cn_program_id              -- コンカレント・プログラムID
               ,xseh.program_update_date        = cd_program_update_date     -- プログラム更新日
        WHERE   xseh.item_sales_send_flag       IS NULL
        AND     xseh.ship_to_customer_code      = gt_sale_update_tbl(i).ship_to_customer_code
        AND     xseh.orig_delivery_date         = gt_sale_update_tbl(i).orig_delivery_date
        AND     xseh.business_date              >= gd_business_date_start
        AND     xseh.business_date              <= gd_business_date_end
        AND     xseh.orig_delivery_date         >= TO_DATE(gt_start_date, cv_date_format_sl)
        ;
      END LOOP sale_update;
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- アプリケーション
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- 販売実績ヘッダテーブル
                       );
        --メッセージ作成
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name  -- アプリケーション
                         ,iv_name         => cv_msg_upd_err       -- データ更新エラー
                         ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                         ,iv_token_value1 => lv_tkn_name          -- 販売実績ヘッダ
                         ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                         ,iv_token_value2 => NULL                 -- NULL
                       );
        lv_errbuf   := SQLERRM;
        -- 空行出力
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => NULL
        );
        -- 成功件数の設定
        gn_normal_cnt := cn_0;
        --
        RAISE global_api_expt;
    END;
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
      -- 成功件数の設定
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_sale_header;
--
  /**********************************************************************************
   * Procedure Name   : update_sale_cancel
   * Description      : 販売実績ヘッダテーブルフラグ更新「解除」(A-9)
   ***********************************************************************************/
  PROCEDURE update_sale_cancel(
    iv_act_mode   IN  VARCHAR2     -- 実行区分：「1:作成」「2:解除」「3:再送信」
   ,iv_date       IN  VARCHAR2     -- 送信日
   ,ov_errbuf     OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sale_cancel';           -- プログラム名
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
    lv_tkn_name fnd_new_messages.message_text%TYPE;     --トークン取得用
--
    -- *** ローカル・カーソル ***
    --送信済の販売実績情報
    CURSOR sale_update_data_cur
    IS
      SELECT  /*+ INDEX(xseh xxcos_sales_exp_headers_n06) */
              xseh.sales_exp_header_id  header_id   --ヘッダID
      FROM    xxcos_sales_exp_headers   xseh        --販売実績ヘッダ
      WHERE   xseh.item_sales_send_flag  = cv_y                                         -- 商品別販売実績送信済フラグ
      AND     xseh.item_sales_send_date  = TO_DATE(iv_date, cv_date_format_sl)    -- 商品別販売実績送信日
      AND     xseh.business_date         >= gd_business_date_start
      AND     xseh.business_date         <= gd_business_date_end
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    upd_sale_data_expt          EXCEPTION;   -- データ更新エラー
    lock_expt                   EXCEPTION;   -- ロックエラー
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
      -- ロック取得、データ取得
      OPEN  sale_update_data_cur;
      FETCH sale_update_data_cur BULK COLLECT INTO gt_update_header_id;
      -- 抽出件数取得
      gn_target_cnt := sale_update_data_cur%ROWCOUNT;
      -- クローズ
      CLOSE sale_update_data_cur;
      -- 抽出件数チェック
      IF ( gn_target_cnt = cn_0 ) THEN
        -- 抽出データが無い場合
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        -- メッセージ作成
        gv_out_msg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_no_target_err
        );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
        );
      ELSE     
        -- 販売実績ヘッダTBLフラグ更新（送信済）
        UPDATE  /*+ INDEX(xseh xxcos_sales_exp_headers_n06) */
                xxcos_sales_exp_headers      xseh  --販売実績ヘッダ
        SET     xseh.item_sales_send_flag    = NULL                       -- 商品別販売実績送信済フラグ
               ,xseh.last_updated_by         = cn_last_updated_by         -- 最終更新者
               ,xseh.last_update_date        = cd_last_update_date        -- 最終更新日
               ,xseh.last_update_login       = cn_last_update_login       -- 最終更新ログイン
               ,xseh.request_id              = cn_request_id              -- 要求ID
               ,xseh.program_application_id  = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
               ,xseh.program_id              = cn_program_id              -- コンカレント・プログラムID
               ,xseh.program_update_date     = cd_program_update_date     -- プログラム更新日
         WHERE xseh.item_sales_send_flag     = cv_y                                      -- 商品別販売実績送信済フラグ
           AND xseh.item_sales_send_date     = TO_DATE(iv_date, cv_date_format_sl)    -- 商品別販売実績送信日
           AND xseh.business_date            >= gd_business_date_start
           AND xseh.business_date            <= gd_business_date_end
        ;
      END IF; 
    EXCEPTION
      WHEN record_lock_expt THEN
        --*** ロックエラー ***
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- アプリケーション
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- 販売実績ヘッダテーブル
                       );
        -- メッセージ作成
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_lock_err
         ,iv_token_name1  => cv_tkn_table
         ,iv_token_value1 => lv_tkn_name
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# 任意 #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
        ov_retcode := cv_status_error;                                            --# 任意 #
        --
      WHEN OTHERS THEN
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        --トークン取得
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- アプリケーション
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- 販売実績ヘッダテーブル
                       );
        --メッセージ作成
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name  -- アプリケーション
                         ,iv_name         => cv_msg_upd_err       -- データ更新エラー
                         ,iv_token_name1  => cv_tkn_table_name    -- トークンコード１
                         ,iv_token_value1 => lv_tkn_name          -- 販売実績ヘッダ
                         ,iv_token_name2  => cv_tkn_key_data      -- トークンコード２
                         ,iv_token_value2 => NULL                 -- NULL
                       );
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;                                        --# 任意 #
    END;
--
    --正常件数の設定
    gn_normal_cnt := gn_target_cnt;
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
  END update_sale_cancel;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_act_mode       IN  VARCHAR2,  -- 実行区分：「1:作成」「2:解除」「3:再送信」
    iv_date           IN  VARCHAR2,  -- 送信日
    ov_errbuf         OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_no_target_msg      VARCHAR2(5000);  --対象なしメッセージ取得用
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
    -- ==============================================================
    -- 初期処理(A1)
    -- ==============================================================
    init(
      iv_act_mode   =>  iv_act_mode
     ,iv_date       =>  iv_date
     ,ov_errbuf     =>  lv_errbuf
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ==============================================================
    -- 対象業務日付算出処理(A2)
    -- ==============================================================
    get_busines_date(
      iv_act_mode   =>  iv_act_mode
     ,iv_date       =>  iv_date
     ,ov_errbuf     =>  lv_errbuf
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( iv_act_mode = cv_run_class_cd_create OR iv_act_mode = cv_run_class_cd_resend ) THEN
      -- パラメータ.実行区分が「1:作成」または「3:再送信」の場合
      --
      -- ==============================================================
      -- ファイル初期処理(A-3)
      -- ==============================================================
      output_header(
        ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ==============================================================
      -- 販売実績情報抽出(A-4)
      -- ==============================================================
      get_sales_exp_data(
        iv_act_mode   =>  iv_act_mode
       ,iv_date       =>  iv_date
       ,ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
      IF ( gn_target_cnt != cn_0) THEN
        -- 対象データが抽出された場合
        --
        -- ==============================================================
        -- ファイルデータ成型処理(A-5、A-6)
        -- ==============================================================
        make_sale_data(
          ov_errbuf     =>  lv_errbuf
         ,ov_retcode    =>  lv_retcode
         ,ov_errmsg     =>  lv_errmsg
        );
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ==============================================================
        -- 販売実績ヘッダテーブルフラグ更新「送信済」(A-8)
        -- ==============================================================
        update_sale_header(
          iv_act_mode   =>  iv_act_mode
         ,iv_date       =>  iv_date
         ,ov_errbuf     =>  lv_errbuf
         ,ov_retcode    =>  lv_retcode
         ,ov_errmsg     =>  lv_errmsg
        );
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      -- ==============================================================
      -- ファイル終了処理(A-7)
      -- ==============================================================
      output_footer(
        ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    ELSE
      -- パラメータ.実行区分が「2:解除」の場合
      --
      -- ==============================================================
      -- 販売実績ヘッダテーブルフラグ更新「解除」(A-9)
      -- ==============================================================
      update_sale_cancel(
        iv_act_mode   =>  iv_act_mode
       ,iv_date       =>  iv_date
       ,ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
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
    errbuf           OUT    VARCHAR2,         -- エラー・メッセージ  --# 固定 #
    retcode          OUT    VARCHAR2,         -- リターン・コード    --# 固定 #
    iv_act_mode      IN     VARCHAR2,         -- 1.実行区分（作成/解除/再送信）
    iv_date          IN     VARCHAR2          -- 2.送信日
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
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
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_act_mode        -- 実行区分（作成/解除/再送信）
      ,iv_date            -- 送信日
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー件数を設定
      gn_error_cnt := cn_1;
    ELSE
      IF (gn_warn_cnt > 0) THEN
        lv_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    -- 処理件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => ct_msg_data_count
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR(gn_warn_cnt)
                    ,iv_token_name4  => cv_tkn_count4
                    ,iv_token_value4 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージ
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
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCOS011A11C;
/
