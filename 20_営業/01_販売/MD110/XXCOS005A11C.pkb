CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOS005A11C (body)
 * Description      : CSVデータアップロード（価格表）
 * MD.050           : CSVデータアップロード（価格表） MD050_COS_005_A11
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                      (A-1)
 *  get_if_data            ファイルアップロードIF取得    (A-2)
 *  item_split             項目分割処理                  (A-3)
 *  item_check             項目チェック                  (A-4)
 *  ins_work_table         一時表登録処理                (A-5)
 *  data_insert            価格表反映処理                (A-6)
 *                         終了処理                      (A-7)
 * ---------------------- ----------------------------------------------------------
 *  submain                サブメイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/09/16    1.0   R.Oikawa         新規作成
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
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  --*** 処理対象データロック例外 ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS005A11C';      -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCOS'; -- 販物短縮アプリ名
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCCP'; -- 共通
  --プロファイル
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                    -- 営業単位
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';  -- 在庫組織コード
  ct_prof_min_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MIN_DATE';           -- XXCOS:MIN日付
  ct_prof_max_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';           -- XXCOS:MAX日付
  --クイックコードタイプ
  ct_lookup_type_upload_name     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ';             -- ファイルアップロード名マスタ
  ct_lookup_type_all_base        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_005A11_ALL_BASE_CD';          -- 価格表アップロード全拠点対象
  --クイックコード
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語コード
  --文字列
  cv_str_file_id                 CONSTANT VARCHAR2(128) := 'FILE_ID';             -- FILE_ID
  cv_format                      CONSTANT VARCHAR2(10)  := 'FM00000';             -- 行No出力
  --フォーマット
  cv_msg_part                    CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3)   := '.';
  cv_c_kanma                     CONSTANT VARCHAR2(1)   := ',';                     -- カンマ
  cn_c_header                    CONSTANT NUMBER        := 16;                      -- 項目数
  cv_yyyy_mm_dd                  CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD';            --YYYY/MM/DD型
  cv_yyyy_mm_ddhh24miss          CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS'; --YYYY/MM/DD HH24:MI:SS型
  --ファイルレイアウト
  cn_proc_kbn                    CONSTANT NUMBER        := 1;                     -- 処理区分
  cn_name                        CONSTANT NUMBER        := 2;                     -- 名称
  cn_active_flag                 CONSTANT NUMBER        := 3;                     -- 有効
  cn_description                 CONSTANT NUMBER        := 4;                     -- 摘要
  cn_rounding_factor             CONSTANT NUMBER        := 5;                     -- 丸め処理先
  cn_date_from                   CONSTANT NUMBER        := 6;                     -- 有効日(From)
  cn_date_to                     CONSTANT NUMBER        := 7;                     -- 有効日(To)
  cn_comments                    CONSTANT NUMBER        := 8;                     -- 注釈
  cn_attribute1                  CONSTANT NUMBER        := 9;                     -- 所有拠点
  cn_product_attr_value          CONSTANT NUMBER        := 10;                    -- 製品値
  cn_product_uom_code            CONSTANT NUMBER        := 11;                    -- 単位
  cn_primary_uom_flag            CONSTANT NUMBER        := 12;                    -- 基準単位
  cn_operand                     CONSTANT NUMBER        := 13;                    -- 値
  cn_start_date_active           CONSTANT NUMBER        := 14;                    -- 開始日
  cn_end_date_active             CONSTANT NUMBER        := 15;                    -- 終了日
  cn_product_precedence          CONSTANT NUMBER        := 16;                    -- 優先
  --汎用
  cv_y                           CONSTANT VARCHAR2(10)  := 'Y';                   -- 汎用：Y
  cv_n                           CONSTANT VARCHAR2(10)  := 'N';                   -- 汎用：N
  cv_i                           CONSTANT VARCHAR2(10)  := 'I';                   -- 汎用：I(登録)
  cv_u                           CONSTANT VARCHAR2(10)  := 'U';                   -- 汎用：U(更新)
--
  --メッセージ
  ct_msg_cos_00001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; -- ロックエラー
  ct_msg_cos_00003   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003'; -- 対象データ無しエラー
  ct_msg_cos_00004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  ct_msg_cos_00012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; -- データ削除エラーメッセージ
  ct_msg_cos_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  ct_msg_cos_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  ct_msg_cos_10024   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10024'; -- 在庫組織ID取得エラーメッセージ
  ct_msg_cos_10181   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10181'; -- 拠点未設定エラー
  ct_msg_cos_11289   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11289'; -- フォーマットパターンメッセージ
  ct_msg_cos_11290   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11290'; -- CSVファイル名メッセージ
  ct_msg_cos_11293   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11293'; -- ファイルアップロード名称取得エラー
  ct_msg_cos_11294   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11294'; -- CSVファイル名取得エラー
  ct_msg_cos_11295   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11295'; -- ファイルレコード不一致エラーメッセージ
  ct_msg_cos_15151   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15151'; -- 必須チェックエラー
  ct_msg_cos_15365   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15365'; -- 処理区分エラー
  ct_msg_cos_15366   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15366'; -- 有効不正エラー
  ct_msg_cos_15367   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15367'; -- 数値エラー
  ct_msg_cos_15368   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15368'; -- 丸め処理先不正エラー
  ct_msg_cos_15369   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15369'; -- 日付書式エラー
  ct_msg_cos_15370   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15370'; -- 日付逆転エラー
  ct_msg_cos_15371   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15371'; -- 所有拠点マスタ存在エラー
  ct_msg_cos_15372   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15372'; -- 品目マスタ存在エラー
  ct_msg_cos_15373   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15373'; -- 単位マスタ存在エラー
  ct_msg_cos_15374   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15374'; -- 基準単位不正エラー
  ct_msg_cos_15375   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15375'; -- 所有拠点セキュリティエラー
  ct_msg_cos_15376   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15376'; -- 値不正エラー
  ct_msg_cos_15377   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15377'; -- 営業単位セキュリティエラー
  ct_msg_cos_15378   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15378'; -- 重複エラー(ファイル内)
  ct_msg_cos_15379   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15379'; -- 重複エラー(登録済)
  ct_msg_cos_15380   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15380'; -- 更新対象なしエラー
  ct_msg_cos_15381   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15381'; -- 一時表登録エラー
  ct_msg_cos_15382   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15382'; -- API登録エラー
  --メッセージ文字列
  ct_msg_cos_11282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11282'; -- ファイルアップロードIF(メッセージ文字列)
  ct_msg_cos_11636   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11636'; -- 名称(メッセージ文字列)
  ct_msg_cos_15152   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15152'; -- 処理区分(メッセージ文字列)
  ct_msg_cos_15356   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15356'; -- 丸め処理先(メッセージ文字列)
  ct_msg_cos_15357   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15357'; -- 所有拠点(メッセージ文字列)
  ct_msg_cos_15358   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15358'; -- 製品値(メッセージ文字列)
  ct_msg_cos_15359   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15359'; -- 単位(メッセージ文字列)
  ct_msg_cos_15360   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15360'; -- 値(メッセージ文字列)
  ct_msg_cos_15361   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15361'; -- 有効日FROM(メッセージ文字列)
  ct_msg_cos_15362   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15362'; -- 有効日TO(メッセージ文字列)
  ct_msg_cos_15363   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15363'; -- 開始日(メッセージ文字列)
  ct_msg_cos_15364   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15364'; -- 終了日(メッセージ文字列)
  ct_msg_cos_15383   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15383'; -- 優先(メッセージ文字列)
  --トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            -- プロファイル名
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              -- テーブル名
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           -- キー内容をコメント
  cv_tkn_proc_kbn                CONSTANT VARCHAR2(512) := 'PROC_KBN';           -- 処理区分
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            -- 行番号
  cv_tkn_item                    CONSTANT VARCHAR2(512) := 'ITEM';               -- 項目
  cv_tkn_item2                   CONSTANT VARCHAR2(512) := 'ITEM2';              -- 項目2
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          -- 品目コード
  cv_tkn_date                    CONSTANT VARCHAR2(512) := 'DATE';               -- 日付
  cv_tkn_date_from               CONSTANT VARCHAR2(512) := 'DATE_FROM';          -- 期間(From)
  cv_tkn_date_to                 CONSTANT VARCHAR2(512) := 'DATE_TO';            -- 期間(To)
  cv_tkn_start_date              CONSTANT VARCHAR2(512) := 'START_DATE';         -- 開始日
  cv_tkn_start_date2             CONSTANT VARCHAR2(512) := 'START_DATE2';        -- 開始日
  cv_tkn_end_date                CONSTANT VARCHAR2(512) := 'END_DATE';           -- 終了日
  cv_tkn_end_date2               CONSTANT VARCHAR2(512) := 'END_DATE2';          -- 終了日
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         -- テーブル名
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            -- エラーメッセージ
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               -- レコードデータ
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             -- パラメータ
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             -- パラメータ
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             -- パラメータ
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             -- パラメータ
  cv_tkn_active_flag             CONSTANT VARCHAR2(512) := 'ACTIVE_FLAG';        -- 有効
  cv_tkn_value                   CONSTANT VARCHAR2(512) := 'VALUE';              -- 項目
  cv_tkn_rounding                CONSTANT VARCHAR2(512) := 'ROUNDING';           -- 丸め処理先
  cv_tkn_base_code               CONSTANT VARCHAR2(512) := 'BASE_CODE';          -- 拠点
  cv_tkn_uom_code                CONSTANT VARCHAR2(512) := 'UOM_CODE';           -- 単位
  cv_tkn_uom_flag                CONSTANT VARCHAR2(512) := 'UOM_FLAG';           -- 基準単位
  cv_tkn_name                    CONSTANT VARCHAR2(512) := 'NAME';               -- 名称
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- BLOB型
  g_upload_if_tab   xxccp_common_pkg2.g_file_data_tbl;
  --
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date                 DATE;                                               -- 業務日付
  gv_inv_org_code                 VARCHAR2(128);                                      -- 在庫組織コード
  gn_org_id                       NUMBER;                                             -- 営業単位
  gn_inv_org_id                   NUMBER;                                             -- 在庫組織ID
  gv_all_base_flg                 VARCHAR2(1);                                        -- 価格表全拠点有効フラグ
  gn_get_counter_data             NUMBER;                                             -- データ数
  gv_login_user_base_code         xxcos_login_own_base_info_v.base_code%TYPE;         -- ログインユーザ拠点
  gd_min_date                     DATE;                                               -- MIN日付
  gd_max_date                     DATE;                                               -- MAX日付
  --
  g_item_work_tab                 g_var2_ttype;                                       -- 価格表データ(分割処理後)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER    -- FILE_ID
   ,iv_get_format IN  VARCHAR2  -- 入力フォーマットパターン
   ,ov_errbuf     OUT NOCOPY VARCHAR2  -- 1.エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2  -- 2.リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2  -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lt_meaning               fnd_lookup_values.meaning%TYPE;             -- ファイルアップロード名称
    lt_csv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE; -- CSVファイル名称
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
    --==================================
    --  業務日付取得
    --==================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00014   -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- パラメータ出力
    --==================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name
                  ,iv_name          => ct_msg_cos_11289        -- フォーマットパターンメッセージ
                  ,iv_token_name1   => cv_tkn_param1           -- パラメータ１
                  ,iv_token_value1  => TO_CHAR( in_file_id )   -- ファイルID
                  ,iv_token_name2   => cv_tkn_param2           -- パラメータ２
                  ,iv_token_value2  => iv_get_format           -- フォーマットパターン
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => gv_out_msg
    );
--
    --==================================
    -- ファイルアップロード名称取得
    --==================================
    BEGIN
      SELECT flv.meaning AS meaning
      INTO   lt_meaning
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type    = ct_lookup_type_upload_name
      AND    flv.lookup_code    = iv_get_format
      AND    flv.enabled_flag   = cv_y
      AND    flv.language       = ct_lang
      AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date
      AND  NVL(flv.end_date_active, gd_process_date)   >= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11293   -- ファイルアップロード名称取得エラー
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => iv_get_format
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- CSVファイル名称取得(ロック取得)
    --==================================
    BEGIN
      SELECT xmfui.file_name AS file_name
      INTO   lt_csv_file_name
      FROM   xxccp_mrp_file_ul_interface  xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11294   -- CSVファイル名取得エラー
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => TO_CHAR( in_file_id )
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN global_data_lock_expt THEN
        -- ロックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_00001     -- ロックエラー
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => ct_msg_cos_11282
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- ファイル名称出力
    --==================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => ct_xxcos_appl_short_name
                   ,iv_name          => ct_msg_cos_11290         -- CSVファイル名メッセージ
                   ,iv_token_name1   => cv_tkn_param3            -- ファイルアップロード名称(メッセージ文字列)
                   ,iv_token_value1  => lt_meaning               -- ファイルアップロード名称
                   ,iv_token_name2   => cv_tkn_param4            -- CSVファイル名(メッセージ文字列)
                   ,iv_token_value2  => lt_csv_file_name         -- CSVファイル名
                  );
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
    --==================================
    -- 営業単位の取得
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- XXCOI:在庫組織コードの取得
    --==================================
    gv_inv_org_code := FND_PROFILE.VALUE( ct_inv_org_code );
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_inv_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 在庫組織IDの取得
    --==================================
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_inv_org_code
                           );
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_10024   -- 在庫組織ID取得エラーメッセージ
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MIN日付取得処理
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( ct_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_min_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MAX日付取得処理
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( ct_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_max_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --===============================
    -- ログインユーザ拠点取得
    --===============================
    BEGIN
      SELECT xlob.base_code  AS base_code        -- 拠点コード
      INTO   gv_login_user_base_code
      FROM   xxcos_login_own_base_info_v xlob    -- ログインユーザ自拠点ビュー
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_10181   -- 拠点未設定エラーメッセージ
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --===============================
    -- 全拠点更新対象か判断
    --===============================
    BEGIN
      SELECT  cv_y    AS  cv_y                -- 全拠点更新対象
      INTO    gv_all_base_flg
      FROM    fnd_lookup_values_vl    flv     -- 参照コード
      WHERE   flv.lookup_type                            =  ct_lookup_type_all_base
      AND     flv.lookup_code                            =  gv_login_user_base_code
      AND     TRUNC(NVL(flv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND     TRUNC(NVL(flv.end_date_active, SYSDATE))   >= TRUNC(SYSDATE)
      AND     flv.enabled_flag                           =  cv_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_all_base_flg := cv_n;
    END;

--
  EXCEPTION
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
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIF取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data (
    in_file_id          IN  NUMBER          -- file_id
   ,ov_errbuf           OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
   ,ov_errmsg           OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    lv_key_info               VARCHAR2(5000); -- key情報
--
    -- *** ローカル・カーソル ***
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
    --==================================
    -- 価格表データ取得
    --==================================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id         -- file_id
     ,ov_file_data => g_upload_if_tab    -- 価格表データ(配列型)
     ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ            --# 固定 #
     ,ov_retcode   => lv_retcode         -- リターン・コード              --# 固定 #
     ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      --キー情報
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf      -- エラー・メッセージ
       ,ov_retcode     => lv_retcode     -- リターンコード
       ,ov_errmsg      => lv_errmsg      -- ユーザ・エラー・メッセージ
       ,ov_key_info    => lv_key_info    -- 編集されたキー情報
       ,iv_item_name1  => cv_str_file_id
       ,iv_data_value1 => TO_CHAR( in_file_id )
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00013   -- データ抽出エラーメッセージ
                    ,iv_token_name1  => cv_tkn_table_name
                    ,iv_token_value1 => ct_msg_cos_11282   -- ファイルアップロードIF(メッセージ文字列)
                    ,iv_token_name2  => cv_tkn_key_data
                    ,iv_token_value2 => lv_key_info
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- データ件数の設定
    --==================================
    gn_get_counter_data := g_upload_if_tab.COUNT;
    gn_target_cnt       := g_upload_if_tab.COUNT - 1;
--
    --==================================
    -- ファイルアップロードIFデータ削除処理
    --==================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_00012   -- データ削除エラーメッセージ
                      ,iv_token_name1  => cv_tkn_table_name
                      ,iv_token_value1 => ct_msg_cos_11282   -- ファイルアップロードIF(メッセージ文字列)
                      ,iv_token_name2  => cv_tkn_key_data
                      ,iv_token_value2 => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  COMMIT;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : item_split
   * Description      : 項目分割処理(A-3)
   ***********************************************************************************/
  PROCEDURE item_split(
    ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード             --# 固定 #
   ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_split'; -- プログラム名
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
    -- *** ローカル変数 ***
    -- *** ローカル・カーソル ***
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
    -- データ取得ループ
    <<get_if_row_loop>>
    FOR i IN 2 .. gn_get_counter_data LOOP
    --
      --==================================
      -- 項目数チェック
      --==================================
      -- カンマの数が項目数-1であることを確認
      IF ( (LENGTH( g_upload_if_tab(i) ) - LENGTH( REPLACE( g_upload_if_tab(i), cv_c_kanma, NULL ))) <> ( cn_c_header - 1 ) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_11295  -- ファイルレコード不一致エラーメッセージ
                      ,iv_token_name1  => cv_tkn_data
                      ,iv_token_value1 => g_upload_if_tab(i)
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --カラム分割ループ
      <<get_if_col_loop>>
      FOR j IN 1 .. cn_c_header LOOP
        --==================================
        -- 項目分割
        --==================================
        g_item_work_tab(i)(j) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     => g_upload_if_tab(i)
                                  ,iv_delim    => cv_c_kanma
                                  ,in_part_num => j
                                 );
      END LOOP get_if_col_loop;
--
    END LOOP get_if_row_loop;
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
  END item_split;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_table
   * Description      : 一時表登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_table(
    in_line_no              IN  NUMBER          -- 行No
   ,in_list_header_id       IN  NUMBER          -- ヘッダーID
   ,in_list_line_id         IN  NUMBER          -- 明細ID
   ,in_product_attr_value   IN  NUMBER          -- 製品値
   ,ov_errbuf               OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
   ,ov_errmsg               OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_work_table'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
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
    --==================================
    -- 一時表登録
    --==================================
    BEGIN
      INSERT INTO xxcos_tmp_price_lists(
         line_no                      -- 行No
        ,proc_kbn                     -- 処理区分
        ,name                         -- 名称
        ,active_flag                  -- 有効
        ,description                  -- 摘要
        ,rounding_factor              -- 丸め処理先
        ,start_date_active_h          -- 有効日FROM
        ,end_date_active_h            -- 有効日TO
        ,comments                     -- 注釈
        ,base_code                    -- 所有拠点
        ,product_attr_value           -- 製品値
        ,product_uom_code             -- 単位
        ,primary_uom_flag             -- 基準単位
        ,operand                      -- 値
        ,start_date_active_l          -- 開始日
        ,end_date_active_l            -- 終了日
        ,product_precedence           -- 優先
        ,list_header_id               -- ヘッダーID
        ,list_line_id                 -- 明細ID
      )VALUES(
        in_line_no                                                                      -- 行No
        ,g_item_work_tab(in_line_no)(cn_proc_kbn)                                       -- 処理区分
        ,g_item_work_tab(in_line_no)(cn_name)                                           -- 名称
        ,g_item_work_tab(in_line_no)(cn_active_flag)                                    -- 有効
        ,g_item_work_tab(in_line_no)(cn_description)                                    -- 摘要
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_rounding_factor))                    -- 丸め処理先
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_date_from), cv_yyyy_mm_dd )            -- 有効日FROM
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_date_to), cv_yyyy_mm_dd )              -- 有効日TO
        ,g_item_work_tab(in_line_no)(cn_comments)                                       -- 注釈
        ,g_item_work_tab(in_line_no)(cn_attribute1)                                     -- 所有拠点
        ,TO_CHAR(in_product_attr_value)                                                 -- 製品値
        ,g_item_work_tab(in_line_no)(cn_product_uom_code)                               -- 単位
        ,g_item_work_tab(in_line_no)(cn_primary_uom_flag)                               -- 基準単位
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_operand))                            -- 値
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_start_date_active), cv_yyyy_mm_dd )    -- 開始日
        ,TO_DATE( g_item_work_tab(in_line_no)(cn_end_date_active), cv_yyyy_mm_dd )      -- 終了日
        ,TO_NUMBER( g_item_work_tab(in_line_no)(cn_product_precedence))                 -- 優先
        ,in_list_header_id                                                              -- ヘッダーID
        ,in_list_line_id                                                                -- 明細ID
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_15381   -- 一時表登録エラー
                      ,iv_token_name1  => cv_tkn_line_no
                      ,iv_token_value1 => TO_CHAR( in_line_no, cv_format ) -- 行No
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM    -- エラー内容
                     );
        lv_errbuf := lv_errmsg;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_work_table;
--
  /**********************************************************************************
   * Procedure Name   : item_check
   * Description      : 項目チェック(A-4)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER   -- ループカウンタ
   ,ov_errbuf               OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
   ,ov_errmsg               OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_status                      VARCHAR2(1);      -- 終了ステータス
    ln_cnt                         NUMBER;           -- 件数
    ln_chk_cnt                     NUMBER;           -- チェック件数
    ln_number                      NUMBER;           -- 数値チェック用
    lt_inventory_item_id           mtl_system_items_b.inventory_item_id%TYPE;         -- 品目ID
    lt_orig_org_id                 qp_list_headers_b.orig_org_id%TYPE;                -- 営業単位
    lt_header_base_code            qp_list_headers_b.attribute1%TYPE;                 -- 拠点コード(登録データ)
    lt_list_header_id              qp_list_headers_tl.list_header_id%TYPE;            -- ヘッダID
    lt_list_line_id                qp_list_lines.list_line_id%TYPE;                   -- 明細ID
    lt_base_code                   xxcmm_cust_accounts.customer_code%TYPE;            -- 自拠点
    lt_attribute1                  fnd_flex_values_vl.flex_value%TYPE;                -- 所有拠点
    lt_uom_code                    mtl_units_of_measure_tl.uom_code%TYPE;             -- 単位
    ld_start_date_active_h         xxcos_tmp_price_lists.start_date_active_h%TYPE;    -- 有効日FROM
    ld_end_date_active_h           xxcos_tmp_price_lists.end_date_active_h%TYPE;      -- 有効日TO
    ld_start_date_active_l         xxcos_tmp_price_lists.start_date_active_l%TYPE;    -- 開始日
    ld_end_date_active_l           xxcos_tmp_price_lists.end_date_active_l%TYPE;      -- 終了日
--
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    ln_cnt                 := 0;
    ln_chk_cnt             := 0;
    ln_number              := 0;
    lt_inventory_item_id   := NULL;
    ld_start_date_active_h := NULL;
    ld_end_date_active_h   := NULL;
    ld_start_date_active_l := NULL;
    ld_end_date_active_l   := NULL;
--
    --===============================
    -- 必須チェック
    --===============================
    -- 処理区分
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15152             -- 処理区分(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 名称
    IF ( g_item_work_tab(in_cnt)(cn_name) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_11636             -- 名称(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 丸め処理先
    IF ( g_item_work_tab(in_cnt)(cn_rounding_factor) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15356             -- 丸め処理先(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 所有拠点
    IF ( g_item_work_tab(in_cnt)(cn_attribute1) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15357             -- 所有拠点(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 製品値
    IF ( g_item_work_tab(in_cnt)(cn_product_attr_value) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15358             -- 製品値(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 単位
    IF ( g_item_work_tab(in_cnt)(cn_product_uom_code) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15359             -- 単位(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 値
    IF ( g_item_work_tab(in_cnt)(cn_operand) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151             -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_15360             -- 値(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --===============================
    -- 入力値チェック
    --===============================
    -- 処理区分が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NOT NULL ) THEN
      --===============================
      -- 処理区分チェック
      --===============================
      -- I:登録 U:更新 以外の場合はエラー
      IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) NOT IN (cv_i, cv_u) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15365 -- 処理区分エラー
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                      ,iv_token_name2   => cv_tkn_proc_kbn
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_proc_kbn) -- 処理区分
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
    END IF;
--
    -- 有効が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_active_flag) IS NOT NULL ) THEN
      --===============================
      -- 有効チェック
      --===============================
      -- 「Y」,「N」以外の場合はエラー
      IF ( g_item_work_tab(in_cnt)(cn_active_flag) NOT IN (cv_y, cv_n) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15366 -- 有効不正エラー
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                      ,iv_token_name2   => cv_tkn_active_flag
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_active_flag) -- 有効
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
    ELSE
      -- 未設定は「Y」を設定
      g_item_work_tab(in_cnt)(cn_active_flag) := cv_y;
    END IF;
--
    -- 丸め処理先が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_rounding_factor) IS NOT NULL ) THEN
      --===============================
      -- 数値形式チェック
      --===============================
      BEGIN
        -- 数値形式チェック
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_rounding_factor) );
--
        --===============================
        -- 丸め処理先不正チェック
        --===============================
        IF ( g_item_work_tab(in_cnt)(cn_rounding_factor) < -3 ) THEN
          -- 丸め処理先不正エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15368  -- 丸め処理先不正エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_rounding
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_rounding_factor) -- 丸め処理先
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- 数値形式エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367  -- 数値形式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15356             -- 丸め処理先(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15356             -- 丸め処理先(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_rounding_factor) -- 丸め処理先
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
    END IF;
--
    -- 有効日(FROM)が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL ) THEN
      --===============================
      -- 日付形式チェック
      --===============================
      BEGIN
         ld_start_date_active_h := TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369             -- 日付書式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15361             -- 有効日FROM(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15361             -- 有効日FROM(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_date_from) -- 有効日(FROM)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_start_date_active_h := NULL;
      END;
    END IF;
--
    -- 有効日(TO)が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_date_to) IS NOT NULL ) THEN
      --===============================
      -- 日付形式チェック
      --===============================
      BEGIN
         ld_end_date_active_h := TO_DATE( g_item_work_tab(in_cnt)(cn_date_to), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                    -- 日付書式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )        -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15362                    -- 有効日TO(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15362                    -- 有効日TO(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_date_to) -- 有効日(TO)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_end_date_active_h := NULL;
      END;
    END IF;
--
    IF (  ld_start_date_active_h IS NOT NULL
      AND ld_end_date_active_h IS NOT NULL ) THEN
       --===============================
       -- 日付逆転チェック
       --===============================
       IF ( ld_start_date_active_h > ld_end_date_active_h ) THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name
                       ,iv_name          => ct_msg_cos_15370                      -- 日付逆転エラー
                       ,iv_token_name1   => cv_tkn_line_no
                       ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- 行No
                       ,iv_token_name2   => cv_tkn_start_date
                       ,iv_token_value2  => ct_msg_cos_15361                      -- 有効日FROM(メッセージ文字列)
                       ,iv_token_name3   => cv_tkn_end_date
                       ,iv_token_value3  => ct_msg_cos_15362                      -- 有効日TO(メッセージ文字列)
                       ,iv_token_name4   => cv_tkn_start_date2
                       ,iv_token_value4  => ct_msg_cos_15361                      -- 有効日FROM(メッセージ文字列)
                       ,iv_token_name5   => cv_tkn_date_from
                       ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_date_from) -- 有効日(FROM)
                       ,iv_token_name6   => cv_tkn_end_date2
                       ,iv_token_value6  => ct_msg_cos_15362                      -- 有効日TO(メッセージ文字列)
                       ,iv_token_name7   => cv_tkn_date_to
                       ,iv_token_value7  => g_item_work_tab(in_cnt)(cn_date_to)   -- 有効日(TO)
                      );
         FND_FILE.PUT_LINE(
           which => FND_FILE.OUTPUT
          ,buff  => lv_errmsg
         );
         lv_status := cv_status_warn;
       END IF;
    END IF;
--
    -- 所有拠点が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_attribute1) IS NOT NULL ) THEN
      --===============================
      -- 部門マスタ存在チェック
      --===============================
      BEGIN
        SELECT ffvv.flex_value      AS flex_value     -- 拠点コード
        INTO   lt_attribute1
        FROM   fnd_flex_values_vl ffvv,
               fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
        AND    ffvs.flex_value_set_id   = ffvv.flex_value_set_id
        AND    ffvv.summary_flag        = cv_n
        AND    ffvv.enabled_flag        = cv_y
        AND    TRUNC(SYSDATE) BETWEEN NVL( ffvv.start_date_active, TRUNC(SYSDATE)) AND NVL(ffvv.end_date_active, TRUNC(SYSDATE))
        AND    ffvv.flex_value          = g_item_work_tab(in_cnt)(cn_attribute1) -- 所有拠点
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15371                        -- 所有拠点マスタ存在エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )            -- 行No
                        ,iv_token_name2   => cv_tkn_base_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_attribute1)  -- 所有拠点
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- 製品値が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_product_attr_value) IS NOT NULL ) THEN
      --===============================
      -- 品目マスタ存在チェック
      --===============================
      BEGIN
        SELECT msiv.inventory_item_id     AS inventory_item_id              -- 品目ID
        INTO   lt_inventory_item_id
        FROM   mtl_system_items_vl msiv
        WHERE  msiv.segment1        = g_item_work_tab(in_cnt)(cn_product_attr_value) -- 製品値
        AND    msiv.organization_id = gn_inv_org_id
        AND    msiv.enabled_flag    = cv_y
        AND    ( NVL( customer_order_flag, cv_y ) = cv_y )
        AND    TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss) BETWEEN  NVL(TRUNC( msiv.start_date_active),TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss)) 
                   AND    NVL(TRUNC( msiv.end_date_active), TO_DATE(SYSDATE, cv_yyyy_mm_ddhh24miss)) 
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15372                               -- 品目マスタ存在エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_item_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- 製品値
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- 単位が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_product_uom_code) IS NOT NULL ) THEN
      --===============================
      -- 単位マスタ存在チェック
      --===============================
      BEGIN
        SELECT  miuv.uom_code            AS uom_code                                   -- 単位
        INTO    lt_uom_code
        FROM    mtl_item_uoms_view  miuv
        WHERE   miuv.organization_id   = gn_inv_org_id
        AND     miuv.inventory_item_id = lt_inventory_item_id
        AND     miuv.uom_code          = g_item_work_tab(in_cnt)(cn_product_uom_code)  -- 単位
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15373                               -- 単位マスタ存在エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_uom_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- 単位
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- 基準単位が「Y」、「NULL」以外の場合
    IF ( g_item_work_tab(in_cnt)(cn_primary_uom_flag) IS NOT NULL
      AND  g_item_work_tab(in_cnt)(cn_primary_uom_flag) != cv_y ) THEN
      --===============================
      -- 基準単位チェック
      --===============================
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15374                             -- 基準単位不正エラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                 -- 行No
                    ,iv_token_name2   => cv_tkn_uom_flag
                    ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_primary_uom_flag) -- 基準単位
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 値が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_operand) IS NOT NULL ) THEN
      --===============================
      -- 数値形式チェック
      --===============================
      BEGIN
        -- 数値形式チェック
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_operand) );
--
        --===============================
        -- 値不正チェック
        --===============================
        IF (  ln_number < 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15376                      -- 値不正エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- 行No
                        ,iv_token_name2   => cv_tkn_value
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_operand)   -- 値
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- 数値形式エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367                    -- 数値形式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )        -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15360                    -- 値(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15360                    -- 値(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_operand) -- 値
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    -- 開始日が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_start_date_active) IS NOT NULL ) THEN
      --===============================
      -- 日付形式チェック
      --===============================
      BEGIN
         ld_start_date_active_l := TO_DATE( g_item_work_tab(in_cnt)(cn_start_date_active), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                              -- 日付書式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                  -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15363                              -- 開始日(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15363                              -- 開始日(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_start_date_active) -- 開始日
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
          ld_start_date_active_l := NULL;
      END;
    END IF;
--
    -- 終了日が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_end_date_active) IS NOT NULL ) THEN
      --===============================
      -- 日付形式チェック
      --===============================
      BEGIN
         ld_end_date_active_l := TO_DATE( g_item_work_tab(in_cnt)(cn_end_date_active), cv_yyyy_mm_dd );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15369                             -- 日付書式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                 -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15364                             -- 終了日(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15364                             -- 終了日(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_date
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_end_date_active)  -- 終了日
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status  := cv_status_warn;
          ld_end_date_active_l := NULL;
      END;
    END IF;
--
    IF (  ld_start_date_active_l IS NOT NULL
      AND ld_end_date_active_l IS NOT NULL ) THEN
       --===============================
       -- 日付逆転チェック
       --===============================
       IF ( ld_start_date_active_l > ld_end_date_active_l ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15370                              -- 日付逆転エラー
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                  -- 行No
                      ,iv_token_name2   => cv_tkn_start_date
                      ,iv_token_value2  => ct_msg_cos_15363                              -- 開始日(メッセージ文字列)
                      ,iv_token_name3   => cv_tkn_end_date
                      ,iv_token_value3  => ct_msg_cos_15364                              -- 終了日(メッセージ文字列)
                      ,iv_token_name4   => cv_tkn_start_date2
                      ,iv_token_value4  => ct_msg_cos_15363                              -- 開始日(メッセージ文字列)
                      ,iv_token_name5   => cv_tkn_date_from
                      ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active) -- 開始日
                      ,iv_token_name6   => cv_tkn_end_date2
                      ,iv_token_value6  => ct_msg_cos_15364                              -- 終了日(メッセージ文字列)
                      ,iv_token_name7   => cv_tkn_date_to
                      ,iv_token_value7  => g_item_work_tab(in_cnt)(cn_end_date_active)   -- 終了日
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
       END IF;
    END IF;
--
    -- 優先が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_product_precedence) IS NOT NULL ) THEN
      --===============================
      -- 数値形式チェック
      --===============================
      BEGIN
        -- 数値形式チェック
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_product_precedence) );
      EXCEPTION
        WHEN OTHERS THEN
          -- 数値形式エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15367                               -- 数値形式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_item
                        ,iv_token_value2  => ct_msg_cos_15383                               -- 優先(メッセージ文字列)
                        ,iv_token_name3   => cv_tkn_item2
                        ,iv_token_value3  => ct_msg_cos_15383                               -- 優先(メッセージ文字列)
                        ,iv_token_name4   => cv_tkn_value
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_precedence) -- 優先
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    END IF;
--
    --===============================
    -- ヘッダID,ORG_ID取得
    --===============================
    BEGIN
      SELECT qlht.list_header_id    AS list_header_id,      -- ヘッダーID
             qlhb.orig_org_id       AS orig_org_id,         -- ORG_ID
             qlhb.attribute1        AS base_code            -- 拠点
      INTO   lt_list_header_id,
             lt_orig_org_id,
             lt_header_base_code
      FROM   qp_list_headers_tl qlht,
             qp_list_headers_b  qlhb
      WHERE  qlht.name     = g_item_work_tab(in_cnt)(cn_name)
      AND    qlht.language = ct_lang
      AND    qlht.list_header_id = qlhb.list_header_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_list_header_id   := NULL;
        lt_orig_org_id      := NULL;
        lt_header_base_code := NULL;
    END;
--
    -- 処理区分＝「I＝登録」
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) = cv_i ) THEN
      --===============================
      -- 重複チェック(ファイル内)
      --===============================
      SELECT COUNT(1) AS cnt
      INTO   ln_chk_cnt
      FROM   xxcos_tmp_price_lists  xtpl     -- 価格表一時表
      WHERE  xtpl.name                = g_item_work_tab(in_cnt)(cn_name)                  -- 名称
      AND    xtpl.product_attr_value  = lt_inventory_item_id                              -- 製品値(品目ID)
      AND    xtpl.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- 単位
      AND    ( NVL( ld_start_date_active_l, gd_min_date)  BETWEEN NVL( xtpl.start_date_active_l, gd_min_date) AND NVL( xtpl.end_date_active_l,gd_max_date)   -- 開始日
               OR NVL( ld_end_date_active_l,gd_max_date)  BETWEEN NVL( xtpl.start_date_active_l, gd_min_date) AND NVL( xtpl.end_date_active_l,gd_max_date)   -- 終了日
             OR ( NVL( xtpl.start_date_active_l, gd_min_date)  BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)  -- 開始日
               OR NVL( xtpl.end_date_active_l,gd_max_date)     BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)) -- 終了日
             )
      ;
--
      IF ( ln_chk_cnt > 0 ) THEN
          -- 重複エラー(ファイル内)
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15378                               -- 重複エラー(ファイル内)
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- 名称
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- 製品値
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- 単位
                        ,iv_token_name5   => cv_tkn_start_date
                        ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active)  -- 開始日
                        ,iv_token_name6   => cv_tkn_end_date
                        ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_end_date_active)    -- 終了日
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END IF;
--
      -- 変数初期化
      ln_chk_cnt := 0;
      --===============================
      -- 重複エラー(登録済)
      --===============================
      SELECT COUNT(1) AS cnt
      INTO   ln_chk_cnt
      FROM   qp_list_lines         line,
             qp_pricing_attributes attr
      WHERE  line.list_header_id      = lt_list_header_id
      AND    line.list_header_id      = attr.list_header_id
      AND    line.list_line_id        = attr.list_line_id
      AND    attr.product_attr_value  = lt_inventory_item_id                              -- 製品値(品目ID)
      AND    attr.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- 単位
      AND    ( NVL( ld_start_date_active_l, gd_min_date)  BETWEEN NVL( line.start_date_active, gd_min_date) AND NVL( line.end_date_active,gd_max_date)   -- 開始日
               OR NVL( ld_end_date_active_l,gd_max_date)  BETWEEN NVL( line.start_date_active, gd_min_date) AND NVL( line.end_date_active,gd_max_date)   -- 終了日
             OR ( NVL( line.start_date_active, gd_min_date)  BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)  -- 開始日
               OR NVL( line.end_date_active,gd_max_date)     BETWEEN NVL( ld_start_date_active_l, gd_min_date) AND NVL( ld_end_date_active_l,gd_max_date)) -- 終了日
             )
      ;
--
      -- 価格表に存在している
      IF ( ln_chk_cnt > 0 ) THEN
        -- 変数初期化
        ln_chk_cnt := 0;
--
        -- 価格表一時表に更新データが存在するか
        SELECT COUNT(1) AS cnt
        INTO   ln_chk_cnt
        FROM   xxcos_tmp_price_lists  xtpl     -- 価格表一時表
        WHERE  xtpl.proc_kbn            = cv_u                                              -- 処理区分
        AND    xtpl.name                = g_item_work_tab(in_cnt)(cn_name)                  -- 名称
        AND    xtpl.product_attr_value  = lt_inventory_item_id                              -- 製品値(品目ID)
        AND    xtpl.product_uom_code    = g_item_work_tab(in_cnt)(cn_product_uom_code)      -- 単位
        ;
--
        IF ( ln_chk_cnt = 0) THEN
          -- 価格表一時表に期間を更新するデータが存在しない
          -- 重複エラー(登録済)
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15379                               -- 重複エラー(登録済)
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- 名称
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- 製品値
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- 単位
                        ,iv_token_name5   => cv_tkn_start_date
                        ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_start_date_active)  -- 開始日
                        ,iv_token_name6   => cv_tkn_end_date
                        ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_end_date_active)    -- 終了日
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
      END IF;
--
    -- 処理区分＝「U＝更新」
    ELSIF ( g_item_work_tab(in_cnt)(cn_proc_kbn) = cv_u ) THEN
      --===============================
      -- 更新対象チェック
      --===============================
      -- 更新対象の明細ID取得
      BEGIN
        SELECT line.list_line_id     AS list_line_id
        INTO   lt_list_line_id
        FROM   qp_list_lines         line,
               qp_pricing_attributes attr
        WHERE  line.list_header_id                       = lt_list_header_id
        AND    line.list_header_id                       = attr.list_header_id
        AND    line.list_line_id                         = attr.list_line_id
        AND    attr.product_attr_value                   = lt_inventory_item_id                          -- 製品値(品目ID)
        AND    attr.product_uom_code                     = g_item_work_tab(in_cnt)(cn_product_uom_code)  -- 単位
        AND    NVL( line.start_date_active, gd_min_date) = NVL( ld_start_date_active_l, gd_min_date)     -- 開始日
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 更新対象なしエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15380                               -- 更新対象なしエラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )                   -- 行No
                        ,iv_token_name2   => cv_tkn_name
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_name)               -- 名称
                        ,iv_token_name3   => cv_tkn_item_code
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_product_attr_value) -- 製品値
                        ,iv_token_name4   => cv_tkn_uom_code
                        ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_product_uom_code)   -- 単位
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
      --===============================
      -- 営業単位セキュリティチェック
      --===============================
      -- 営業単位(OU)が異なっている
      IF ( gn_org_id <> lt_orig_org_id ) THEN
        -- 営業単位セキュリティエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15377                -- 営業単位セキュリティエラー
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )    -- 行No
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
--
      --===============================
      -- 更新セキュリティチェック(拠点)
      --===============================
      -- 全拠点対象以外の場合
      IF ( gv_all_base_flg = cv_n ) THEN
        -- 所有拠点と自拠点が違う場合
        IF ( gv_login_user_base_code <> g_item_work_tab(in_cnt)(cn_attribute1) ) THEN
            -- ログインユーザが管理元拠点
          BEGIN
            SELECT  xlbiv.base_code   AS base_code      -- 拠点コード
            INTO    lt_base_code
            FROM    xxcos_login_base_info_v xlbiv
            WHERE   xlbiv.base_code   = lt_header_base_code  -- 所有拠点コード
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- 所有拠点セキュリティエラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15375                        -- 所有拠点セキュリティエラー
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )            -- 行No
                            ,iv_token_name2   => cv_tkn_base_code
                            ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_attribute1)  -- 所有拠点コード
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
          END;
        END IF;
      END IF;
    END IF;
--
    -- エラーが発生していない場合
    IF ( lv_status = cv_status_normal ) THEN
      --==================================
      -- 一時表登録処理(A-5)
      --==================================
      ins_work_table(
        in_line_no              => in_cnt                  -- 行No
       ,in_list_header_id       => lt_list_header_id       -- ヘッダーID
       ,in_list_line_id         => lt_list_line_id         -- 明細ID
       ,in_product_attr_value   => lt_inventory_item_id    -- 製品値
       ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
       ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF ( lv_status = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : data_insert
   * Description      : 価格表反映処理(A-6)
   ***********************************************************************************/
  PROCEDURE data_insert(
    ov_errbuf         OUT NOCOPY VARCHAR2 -- 1.エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT NOCOPY VARCHAR2 -- 2.リターン・コード             --# 固定 #
   ,ov_errmsg         OUT NOCOPY VARCHAR2 -- 3.ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_insert'; -- プログラム名
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
    cv_list_type_code              VARCHAR2(3)   := 'PRL';
    cv_currency_code               VARCHAR2(3)   := 'JPY';
    cv_context                     VARCHAR2(4)   := '2424';
    cv_list_line_type_code         VARCHAR2(3)   := 'PLL';
    cv_arithmetic_operator         VARCHAR2(10)  := 'UNIT_PRICE';
    cv_product_attribute_context   VARCHAR2(4)   := 'ITEM';
    cv_product_attribute           VARCHAR2(18)  := 'PRICING_ATTRIBUTE1';
    cv_excluder_flag               VARCHAR2(1)   := 'N';
    cv_encoded                     VARCHAR2(1)   := 'F';
    cn_api_version_number          NUMBER        := 1;
    cn_index                       NUMBER        := 1;
--
    -- *** ローカル変数 ***
    ln_chk_cnt                     NUMBER;          -- チェック件数
    ln_del_cnt                     NUMBER;          -- 削除件数
    lv_message                     VARCHAR2(32765); -- メッセージ
    lv_status                      VARCHAR2(1);     -- ステータス
    lv_pre_status                  VARCHAR2(1);     -- 前レコードステータス
    lv_return_status               VARCHAR2(1);
    lv_msg_data                    VARCHAR2(2000);
    ln_msg_count                   NUMBER;
    lv_operation_header            VARCHAR2(10);    -- 処理モード(ヘッダー)
    lv_operation_line              VARCHAR2(10);    -- 処理モード(明細)
    lv_operation_attr              VARCHAR2(10);    -- 処理モード(アトリビュート)
    lt_list_header_id              qp_list_headers_tl.list_header_id%TYPE;           -- ヘッダーID
    lt_list_line_id                qp_list_lines.list_line_id%TYPE;                  -- 明細ID
    lt_pricing_attribute_id        qp_pricing_attributes.pricing_attribute_id%TYPE;  -- 属性ID
    --API Specific Parameters.
    lt_price_list_rec              qp_price_list_pub.price_list_rec_type;
    lt_price_list_line_tbl         qp_price_list_pub.price_list_line_tbl_type;
    lt_pricing_attr_tbl            qp_price_list_pub.pricing_attr_tbl_type;
    lt_ppr_price_list_rec          qp_price_list_pub.price_list_rec_type;
    lt_price_list_val_rec          qp_price_list_pub.price_list_val_rec_type;
    lt_ppr_price_list_line_tbl     qp_price_list_pub.price_list_line_tbl_type;
    lt_price_list_line_val_tbl     qp_price_list_pub.price_list_line_val_tbl_type;
    lt_qualifiers_tbl              qp_qualifier_rules_pub.qualifiers_tbl_type;
    lt_qualifiers_val_tbl          qp_qualifier_rules_pub.qualifiers_val_tbl_type;
    lt_ppr_pricing_attr_tbl        qp_price_list_pub.pricing_attr_tbl_type;
    lt_pricing_attr_val_tbl        qp_price_list_pub.pricing_attr_val_tbl_type;
    -- *** ローカル・カーソル ***
--
    -- 価格表一時表取得カーソル
    CURSOR get_price_lists_cur
    IS
      SELECT 
             xtpl.line_no                AS line_no              -- 行No
            ,xtpl.proc_kbn               AS proc_kbn             -- 処理区分
            ,xtpl.name                   AS name                 -- 名称
            ,xtpl.active_flag            AS active_flag          -- 有効
            ,xtpl.description            AS description          -- 摘要
            ,xtpl.rounding_factor        AS rounding_factor      -- 丸め処理先
            ,xtpl.start_date_active_h    AS start_date_active_h  -- 有効日FROM
            ,xtpl.end_date_active_h      AS end_date_active_h    -- 有効日TO
            ,xtpl.comments               AS comments             -- 注釈
            ,xtpl.base_code              AS base_code            -- 所有拠点
            ,xtpl.product_attr_value     AS product_attr_value   -- 製品値
            ,xtpl.product_uom_code       AS product_uom_code     -- 単位
            ,xtpl.primary_uom_flag       AS primary_uom_flag     -- 基準単位
            ,xtpl.operand                AS operand              -- 値
            ,xtpl.start_date_active_l    AS start_date_active_l  -- 開始日
            ,xtpl.end_date_active_l      AS end_date_active_l    -- 終了日
            ,xtpl.product_precedence     AS product_precedence   -- 優先
            ,xtpl.list_header_id         AS list_header_id       -- ヘッダーID
            ,xtpl.list_line_id           AS list_line_id         -- 明細ID
      FROM   xxcos_tmp_price_lists  xtpl                         -- 価格表一時表
      ORDER BY
             xtpl.line_no                                        -- 行No
      ;
--
    -- カーソルレコード型
    get_price_lists_rec  get_price_lists_cur%ROWTYPE;
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数初期化
    lv_pre_status    := cv_status_normal;
--
    -- カーソル取得
    <<main_loop>>
    FOR get_price_lists_rec IN get_price_lists_cur LOOP
--
      -- 変数初期化
      lv_status  := cv_status_normal; -- ステータス
      ln_chk_cnt := 0;  -- チェック件数
      ln_del_cnt := 0;  -- 削除件数
--
      IF ( get_price_lists_rec.proc_kbn = cv_i ) THEN
        --===============================
        -- ヘッダID取得
        --===============================
        BEGIN
          SELECT qlht.list_header_id    AS list_header_id      -- ヘッダーID
          INTO   lt_list_header_id
          FROM   qp_list_headers_tl qlht
          WHERE  qlht.name        = get_price_lists_rec.name   -- 名称
          AND    qlht.language    = ct_lang
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_list_header_id := NULL;
        END;
--
        IF ( lt_list_header_id IS NULL ) THEN
          --  ヘッダー、明細追加
          lv_operation_header        := qp_globals.g_opr_create;                  -- 処理モード(ヘッダー)
          lv_operation_line          := qp_globals.g_opr_create;                  -- 処理モード(明細)
          lv_operation_attr          := qp_globals.g_opr_create;                  -- 処理モード(アトリビュート)
          --
          lt_list_header_id          := fnd_api.g_miss_num;                       -- ヘッダーID
          lt_list_line_id            := fnd_api.g_miss_num;                       -- 明細ID
          lt_pricing_attribute_id    := fnd_api.g_miss_num;                       -- 属性ID
        ELSE
          -- ヘッダー登録済で明細追加
          lv_operation_header        := qp_globals.g_opr_update;                  -- 処理モード(ヘッダー)
          lv_operation_line          := qp_globals.g_opr_create;                  -- 処理モード(明細)
          lv_operation_attr          := qp_globals.g_opr_create;                  -- 処理モード(アトリビュート)
          --
          lt_list_line_id            := fnd_api.g_miss_num;                       -- 明細ID
          lt_pricing_attribute_id    := fnd_api.g_miss_num;                       -- 属性ID
        END IF;
      ELSIF ( get_price_lists_rec.proc_kbn = cv_u ) THEN
        lv_operation_header          := qp_globals.g_opr_update;                  -- 処理モード(ヘッダー)
        lv_operation_line            := qp_globals.g_opr_update;                  -- 処理モード(明細)
        lv_operation_attr            := qp_globals.g_opr_update;                  -- 処理モード(アトリビュート)
        --
        lt_list_header_id            := get_price_lists_rec.list_header_id;       -- ヘッダーID
        lt_list_line_id              := get_price_lists_rec.list_line_id;         -- 明細ID
      END IF;
--
      -- Price List Header
      lt_price_list_rec.list_header_id                           := lt_list_header_id;
      lt_price_list_rec.name                                     := get_price_lists_rec.name;
      lt_price_list_rec.list_type_code                           := cv_list_type_code;
      lt_price_list_rec.description                              := get_price_lists_rec.description;
      lt_price_list_rec.currency_code                            := cv_currency_code;
      lt_price_list_rec.rounding_factor                          := get_price_lists_rec.rounding_factor;
      lt_price_list_rec.comments                                 := get_price_lists_rec.comments;
      lt_price_list_rec.end_date_active                          := get_price_lists_rec.end_date_active_h;
      lt_price_list_rec.start_date_active                        := get_price_lists_rec.start_date_active_h;
      lt_price_list_rec.active_flag                              := get_price_lists_rec.active_flag;
      lt_price_list_rec.attribute1                               := get_price_lists_rec.base_code;
      lt_price_list_rec.context                                  := cv_context;
      lt_price_list_rec.operation                                := lv_operation_header;
      -- Price List Line
      lt_price_list_line_tbl( cn_index ).list_line_id            := lt_list_line_id;
      lt_price_list_line_tbl( cn_index ).list_line_type_code     := cv_list_line_type_code;
      lt_price_list_line_tbl( cn_index ).operation               := lv_operation_line;
      lt_price_list_line_tbl( cn_index ).operand                 := get_price_lists_rec.operand;
      lt_price_list_line_tbl( cn_index ).arithmetic_operator     := cv_arithmetic_operator;
      lt_price_list_line_tbl( cn_index ).end_date_active         := get_price_lists_rec.end_date_active_l;
      lt_price_list_line_tbl( cn_index ).start_date_active       := get_price_lists_rec.start_date_active_l;
      lt_price_list_line_tbl( cn_index ).primary_uom_flag        := get_price_lists_rec.primary_uom_flag;
      lt_price_list_line_tbl( cn_index ).product_precedence      := get_price_lists_rec.product_precedence;
--
      IF ( get_price_lists_rec.proc_kbn = cv_i ) THEN
        -- Product Attributes
        lt_pricing_attr_tbl( cn_index ).pricing_attribute_id       := lt_pricing_attribute_id;
        lt_pricing_attr_tbl( cn_index ).list_line_id               := lt_list_line_id;
        lt_pricing_attr_tbl( cn_index ).product_attribute_context  := cv_product_attribute_context;
        lt_pricing_attr_tbl( cn_index ).product_attribute          := cv_product_attribute;
        lt_pricing_attr_tbl( cn_index ).product_attr_value         := get_price_lists_rec.product_attr_value;
        lt_pricing_attr_tbl( cn_index ).product_uom_code           := get_price_lists_rec.product_uom_code;
        lt_pricing_attr_tbl( cn_index ).excluder_flag              := cv_excluder_flag;
        lt_pricing_attr_tbl( cn_index ).attribute_grouping_no      := fnd_api.g_miss_num;
        lt_pricing_attr_tbl( cn_index ).price_list_line_index      := cn_index;
        lt_pricing_attr_tbl( cn_index ).operation                  := lv_operation_attr;
      END IF;
--
      -- Call QP_PRICE_LIST_PUB.PROCESS_PRICE_LIST API
      qp_price_list_pub.process_price_list(
        p_api_version_number            => cn_api_version_number
      , p_init_msg_list                 => fnd_api.g_false
      , p_return_values                 => fnd_api.g_false
      , p_commit                        => fnd_api.g_false
      , x_return_status                 => lv_retcode
      , x_msg_count                     => ln_msg_count
      , x_msg_data                      => lv_msg_data
      , p_price_list_rec                => lt_price_list_rec
      , p_price_list_line_tbl           => lt_price_list_line_tbl
      , p_pricing_attr_tbl              => lt_pricing_attr_tbl
      , x_price_list_rec                => lt_ppr_price_list_rec
      , x_price_list_val_rec            => lt_price_list_val_rec
      , x_price_list_line_tbl           => lt_ppr_price_list_line_tbl
      , x_price_list_line_val_tbl       => lt_price_list_line_val_tbl
      , x_qualifiers_tbl                => lt_qualifiers_tbl
      , x_qualifiers_val_tbl            => lt_qualifiers_val_tbl
      , x_pricing_attr_tbl              => lt_ppr_pricing_attr_tbl
      , x_pricing_attr_val_tbl          => lt_pricing_attr_val_tbl
      );
      -- API内エラー
      IF ( ln_msg_count > 0 ) THEN
        FOR l_index IN 1..ln_msg_count LOOP
         lv_msg_data := SUBSTRB( oe_msg_pub.get( p_msg_index => l_index
                                                ,p_encoded   => cv_encoded
                                               ),1 ,2000
                                );
         --
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_cos_15382                                  -- 一時表登録エラー
                       ,iv_token_name1  => cv_tkn_line_no
                       ,iv_token_value1 => TO_CHAR( get_price_lists_rec.line_no, cv_format ) -- 行No
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => lv_msg_data                                       -- エラー内容
                      );
         lv_errbuf := lv_errmsg;
         RAISE global_api_expt;
        END LOOP;
      END IF;
--
      -- 配列のクリア
      lt_price_list_rec.list_header_id     := NULL;
      lt_price_list_rec.name               := NULL;
      lt_price_list_rec.description        := NULL;
      lt_price_list_rec.rounding_factor    := NULL;
      lt_price_list_rec.comments           := NULL;
      lt_price_list_rec.end_date_active    := NULL;
      lt_price_list_rec.start_date_active  := NULL;
      lt_price_list_rec.active_flag        := NULL;
      lt_price_list_rec.attribute1         := NULL;
      lt_price_list_line_tbl.DELETE;
      lt_pricing_attr_tbl.DELETE;
--
      IF ( lv_status = cv_status_warn ) THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        -- ステータス：警告
        ov_retcode := cv_status_warn;
      ELSIF ( lv_status = cv_status_normal ) THEN
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
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
  END data_insert;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<フォーマットパターン>
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_temp_status           VARCHAR2(1);    -- 終了ステータス（１レコード毎用）
    lv_status                VARCHAR2(1);    -- 終了ステータス（レコード全体用）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode      := cv_status_normal;
    lv_temp_status  := cv_status_normal;
    lv_status       := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
--
    --==================================
    -- 初期処理(A-1)
    --==================================
    init(
      in_file_id    => in_get_file_id    -- FILE_ID
     ,iv_get_format => iv_get_format_pat -- フォーマットパターン
     ,ov_errbuf     => lv_errbuf         -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode        -- リターン・コード             --# 固定 #
     ,ov_errmsg     => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      --==================================
      -- ファイルアップロードIFデータ削除処理
      --==================================
      BEGIN
        DELETE FROM xxccp_mrp_file_ul_interface xmfui
        WHERE xmfui.file_id = in_get_file_id
        ;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name
                        ,iv_name         => ct_msg_cos_00012   -- データ削除エラーメッセージ
                        ,iv_token_name1  => cv_tkn_table_name
                        ,iv_token_value1 => ct_msg_cos_11282   -- ファイルアップロードIF(メッセージ文字列)
                        ,iv_token_name2  => cv_tkn_key_data
                        ,iv_token_value2 => NULL
                       );
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          RAISE global_process_expt;
      END;
--
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- ファイルアップロードIF取得(A-2)
    --==================================
    get_if_data (
      in_file_id          => in_get_file_id      -- FILE_ID
     ,ov_errbuf           => lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode          => lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg           => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 対象データ存在チェック
    --==================================
    IF ( g_upload_if_tab.COUNT < 2 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00003   -- 対象データ無しエラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 項目分割処理(A-3)
    --==================================
    item_split(
      ov_errbuf         => lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<item_check_loop>>
    FOR i IN 2 .. gn_get_counter_data LOOP
      --==================================
      -- 項目チェック(A-4)
      --==================================
      item_check(
        in_cnt                  => i                       -- ループカウンタ
       ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
       ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        -- ステータス保持
        lv_temp_status := cv_status_warn;
      END IF;
    END LOOP item_check_loop;
--
    -- エラーが発生していない場合
    IF ( lv_temp_status = cv_status_normal ) THEN
      --==================================
      -- 価格表反映処理(A-6)
      --==================================
      data_insert(
        ov_errbuf                   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
       ,ov_retcode                  => lv_retcode           -- リターン・コード             --# 固定 #
       ,ov_errmsg                   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- ステータス保持
        lv_temp_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- 警告エラーが発生している場合
    IF ( lv_temp_status = cv_status_warn ) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => NULL
      );
      ov_retcode := cv_status_warn;
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
    errbuf            OUT NOCOPY VARCHAR2  --   エラー・メッセージ  --# 固定 #
   ,retcode           OUT NOCOPY VARCHAR2  --   リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
   ,in_get_file_id    IN  NUMBER    --   file_id
   ,iv_get_format_pat IN  VARCHAR2  --   フォーマットパターン
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token        CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out   CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log   CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      in_get_file_id     -- file_id
     ,iv_get_format_pat  -- フォーマットパターン
     ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,lv_retcode         -- リターン・コード             --# 固定 #
     ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    IF ( lv_retcode = cv_status_error ) THEN
      --エラーの場合
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --エラーメッセージ
      );
    ELSIF( lv_retcode = cv_status_warn ) THEN
      -- 警告の場合（チェックエラーが発生している場合）
      gn_normal_cnt := 0;
      lv_retcode := cv_status_error;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => NULL
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
--
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS005A11C;
/
