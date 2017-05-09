CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A08C (body)
 * Description      : CSVデータアップロード（特売価格表）
 * MD.050           : CSVデータアップロード（特売価格表） MD050_COS_003_A08
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
 *  data_insert            特売価格表反映処理            (A-6)
 *                         終了処理                      (A-7)
 * ---------------------- ----------------------------------------------------------
 *  submain                サブメイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/04/14    1.0   S.Yamashita      新規作成
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
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS003A08C';      -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCOS'; -- 販物短縮アプリ名
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE  := 'XXCCP'; -- 共通
  --プロファイル
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                    -- 営業単位
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';  -- 在庫組織コード
  ct_prof_all_spl_enable_flg     CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ALL_SPL_ENABLE_FLG'; -- 特売価格表全拠点有効フラグ
  --クイックコードタイプ
  ct_lookup_type_cust_status     CONSTANT fnd_lookup_values.lookup_code%TYPE := 'XXCOS1_CUS_STATUS_MST_001_A01';      -- 顧客ステータスチェック用
  ct_lookup_type_upload_name     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCCP1_FILE_UPLOAD_OBJ';             -- ファイルアップロード名マスタ
  --クイックコード
  cv_lookup_code_a01             CONSTANT VARCHAR2(30)  := 'XXCOS_001_A01_%';                 -- 顧客ステータスチェック用
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語コード
  --文字列
  cv_str_file_id                 CONSTANT VARCHAR2(128) := 'FILE_ID';             -- FILE_ID
  cv_format                      CONSTANT VARCHAR2(10)  := 'FM00000';             -- 行No出力
--
  cv_c_kanma                     CONSTANT VARCHAR2(1)   := ',';                   -- カンマ
  cn_c_header                    CONSTANT NUMBER        := 8;                     -- 項目数
--
  cn_proc_kbn                    CONSTANT NUMBER        := 1;                     -- 処理区分
  cn_cust_code                   CONSTANT NUMBER        := 2;                     -- 顧客コード
  cn_cust_name                   CONSTANT NUMBER        := 3;                     -- 顧客名
  cn_item_code                   CONSTANT NUMBER        := 4;                     -- 品目コード
  cn_item_name                   CONSTANT NUMBER        := 5;                     -- 品目名
  cn_price                       CONSTANT NUMBER        := 6;                     -- 価格
  cn_date_from                   CONSTANT NUMBER        := 7;                     -- 期間(From)
  cn_date_to                     CONSTANT NUMBER        := 8;                     -- 期間(To)
  cn_cust_id                     CONSTANT NUMBER        := 9;                     -- 顧客ID
  cn_item_id                     CONSTANT NUMBER        := 10;                    -- 品目ID
--
  cv_y                           CONSTANT VARCHAR2(10)  := 'Y';                   -- 汎用：Y
  cv_n                           CONSTANT VARCHAR2(10)  := 'N';                   -- 汎用：N
  cv_i                           CONSTANT VARCHAR2(10)  := 'I';                   -- 汎用：I(登録)
  cv_d                           CONSTANT VARCHAR2(10)  := 'D';                   -- 汎用：D(削除)
--
  --メッセージ
  ct_msg_cos_00012   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012'; -- データ削除エラーメッセージ
  ct_msg_cos_00014   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014'; -- 業務日付取得エラー
  ct_msg_cos_11289   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11289'; -- フォーマットパターンメッセージ
  ct_msg_cos_11293   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11293'; -- ファイルアップロード名称取得エラー
  ct_msg_cos_11294   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11294'; -- CSVファイル名取得エラー
  ct_msg_cos_00001   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001'; -- ロックエラー
  ct_msg_cos_11290   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11290'; -- CSVファイル名メッセージ
  ct_msg_cos_00004   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004'; -- プロファイル取得エラー
  ct_msg_cos_10024   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10024'; -- 在庫組織ID取得エラーメッセージ
  ct_msg_cos_00013   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013'; -- データ抽出エラーメッセージ
  ct_msg_cos_00003   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003'; -- 対象データ無しエラー
  ct_msg_cos_11295   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11295'; -- ファイルレコード不一致エラーメッセージ
  ct_msg_cos_15151   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15151'; -- 必須チェックエラー
  ct_msg_cos_15153   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15153'; -- 価格情報設定エラー
  ct_msg_cos_15154   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15154'; -- 顧客コード不正エラー
  ct_msg_cos_15155   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15155'; -- 顧客ステータス不正エラー
  ct_msg_cos_15156   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15156'; -- 顧客区分不正エラー
  ct_msg_cos_15157   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15157'; -- 品目コード不正エラー
  ct_msg_cos_15158   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15158'; -- 顧客セキュリティエラー
  ct_msg_cos_15159   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15159'; -- 日付逆転エラー
  ct_msg_cos_15160   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15160'; -- 一時表登録エラー
  ct_msg_cos_15161   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15161'; -- 処理区分・期間重複エラー
  ct_msg_cos_15162   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15162'; -- 特売価格表削除エラー
  ct_msg_cos_15163   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15163'; -- 特売価格表登録エラー
  ct_msg_cos_15164   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15164'; -- 削除対象なしエラー
  ct_msg_cos_15165   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15165'; -- 特売価格表登録済エラー
  ct_msg_cos_15166   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15166'; -- 処理区分エラー
  ct_msg_cos_15167   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15167'; -- 数値形式エラー
  ct_msg_cos_15168   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15168'; -- 特売価格表顧客登録済エラー
  ct_msg_cos_15169   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15169'; -- 価格情報未設定レコード登録済エラー
  ct_msg_cos_15170   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15170'; -- 日付形式エラー
  --メッセージ文字列
  ct_msg_cos_11282   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11282'; -- ファイルアップロードIF(メッセージ文字列)
  ct_msg_cos_15152   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-15152'; -- 処理区分(メッセージ文字列)
  ct_msg_cos_00053   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00053'; -- 顧客コード(メッセージ文字列)
  --トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            -- プロファイル名
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              -- テーブル名
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           -- キー内容をコメント
  cv_tkn_proc_kbn                CONSTANT VARCHAR2(512) := 'PROC_KBN';           -- 処理区分
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            -- 行番号
  cv_tkn_item                    CONSTANT VARCHAR2(512) := 'ITEM';               -- 項目
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          -- 品目コード
  cv_tkn_date_from               CONSTANT VARCHAR2(512) := 'DATE_FROM';          -- 期間(From)
  cv_tkn_date_to                 CONSTANT VARCHAR2(512) := 'DATE_TO';            -- 期間(To)
  cv_tkn_price                   CONSTANT VARCHAR2(512) := 'PRICE';              -- 価格
  cv_tkn_cust_code               CONSTANT VARCHAR2(512) := 'CUST_CODE';          -- 顧客コード
  cv_tkn_cust_status             CONSTANT VARCHAR2(512) := 'CUST_STATUS';        -- 顧客ステータス
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         -- テーブル名
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            -- エラーメッセージ
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               -- レコードデータ
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             -- パラメータ
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             -- パラメータ
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             -- パラメータ
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             -- パラメータ
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
  gv_all_base_flg                 VARCHAR2(1);                                        -- 特売価格表全拠点有効フラグ
  gn_get_counter_data             NUMBER;                                             -- データ数
  --
  g_item_work_tab                 g_var2_ttype;   -- 特売価格表データ(分割処理後)
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
    --==================================
    -- XXCOS:特売価格表全拠点有効フラグの取得
    --==================================
    gv_all_base_flg := FND_PROFILE.VALUE( ct_prof_all_spl_enable_flg );
    IF ( gv_all_base_flg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_cos_00004   -- プロファイル取得エラー
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => ct_prof_all_spl_enable_flg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
    -- 特売価格表データ取得
    --==================================
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id         -- file_id
     ,ov_file_data => g_upload_if_tab    -- 特売価格表データ(配列型)
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
    lv_status            VARCHAR2(1);      -- 終了ステータス
    ln_cnt               NUMBER;           -- 件数
    ln_number            NUMBER;           -- 数値チェック用
    ld_date              DATE;             -- 日付チェック用
    lt_item_code         mtl_system_items_b.segment1%TYPE;      -- 品目コード
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
    ln_cnt       := 0;
    ln_number    := 0;
    ld_date      := NULL;
    lt_item_code := NULL;
--
    --===============================
    -- 必須チェック
    --===============================
    -- 処理区分
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151  -- 必須チェックエラー
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
    -- 顧客コード
    IF ( g_item_work_tab(in_cnt)(cn_cust_code) IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15151  -- 必須チェックエラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                    ,iv_token_name2   => cv_tkn_item
                    ,iv_token_value2  => ct_msg_cos_00053             -- 顧客コード(メッセージ文字列)
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 価格情報
    -- 価格情報が全てNULL、または全て設定されている場合のみ正常とする
    IF ( (  g_item_work_tab(in_cnt)(cn_item_code)  IS NULL   -- 品目コード
        AND g_item_work_tab(in_cnt)(cn_date_from)  IS NULL   -- 期間(From)
        AND g_item_work_tab(in_cnt)(cn_date_to)    IS NULL   -- 期間(To)
        AND g_item_work_tab(in_cnt)(cn_price)      IS NULL   -- 価格
         )
      OR
         (  g_item_work_tab(in_cnt)(cn_item_code) IS NOT NULL   -- 品目コード
        AND g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL   -- 期間(From)
        AND g_item_work_tab(in_cnt)(cn_date_to)   IS NOT NULL   -- 期間(To)
        AND g_item_work_tab(in_cnt)(cn_price)     IS NOT NULL   -- 価格
         )
    )
    THEN
      NULL;
--
    -- 価格情報の一部が設定されている場合
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name
                    ,iv_name          => ct_msg_cos_15153 -- 価格情報設定エラー
                    ,iv_token_name1   => cv_tkn_line_no
                    ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- 行No
                    ,iv_token_name2   => cv_tkn_cust_code
                    ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_cust_code) -- 顧客コード
                    ,iv_token_name3   => cv_tkn_item_code
                    ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_item_code) -- 品目コード
                    ,iv_token_name4   => cv_tkn_price
                    ,iv_token_value4  => g_item_work_tab(in_cnt)(cn_price)     -- 価格
                    ,iv_token_name5   => cv_tkn_date_from
                    ,iv_token_value5  => g_item_work_tab(in_cnt)(cn_date_from) -- 期間(From)
                    ,iv_token_name6   => cv_tkn_date_to
                    ,iv_token_value6  => g_item_work_tab(in_cnt)(cn_date_to)   -- 期間(To)

                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    -- 処理区分が設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) IS NOT NULL ) THEN
      --===============================
      -- 処理区分チェック
      --===============================
      -- I:登録 D:削除 以外の場合はエラー
      IF ( g_item_work_tab(in_cnt)(cn_proc_kbn) NOT IN (cv_i, cv_d) ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15166 -- 処理区分エラー
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
    -- 顧客コードが設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_cust_code) IS NOT NULL ) THEN
      --===============================
      -- 顧客コード桁数チェック
      --===============================
      IF ( LENGTHB(g_item_work_tab(in_cnt)(cn_cust_code)) <> 9 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => ct_xxcos_appl_short_name
                      ,iv_name          => ct_msg_cos_15154 -- 顧客コード不正エラー
                      ,iv_token_name1   => cv_tkn_line_no
                      ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                      ,iv_token_name2   => cv_tkn_cust_code
                      ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_cust_code) -- 顧客コード
                     );
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => lv_errmsg
        );
        lv_status := cv_status_warn;
      END IF;
--
    END IF;
--
    -- 品目コードが設定されている場合
    IF ( g_item_work_tab(in_cnt)(cn_item_code) IS NOT NULL ) THEN
      --===============================
      -- 品目マスタ存在チェック
      --===============================
      BEGIN
        SELECT  msib.segment1                     AS item_code
               ,TO_CHAR( msib.inventory_item_id ) AS item_id
        INTO    lt_item_code
               ,g_item_work_tab(in_cnt)(cn_item_id)
        FROM    mtl_system_items_b   msib    -- DISC品目マスタ
        WHERE   msib.organization_id  = gn_inv_org_id
        AND     msib.segment1         = g_item_work_tab(in_cnt)(cn_item_code) -- 品目コード
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15157 -- 品目コード不正エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_item_code
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_item_code) -- 品目コード
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
    ELSE
      -- 品目コードがNULLの場合は、品目IDにNULLをセット
      g_item_work_tab(in_cnt)(cn_item_id) := NULL;
    END IF;
--
    -- 価格が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_price) IS NOT NULL ) THEN
      --===============================
      -- 数値形式チェック
      --===============================
      BEGIN
        -- 数値形式チェック
        ln_number := TO_NUMBER( g_item_work_tab(in_cnt)(cn_price), 'FM9999.99' );
        -- 範囲チェック
        IF ( ln_number <= 0 ) THEN
          RAISE VALUE_ERROR;
        END IF;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          -- 数値形式エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15167  -- 数値形式エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_price
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_price) -- 価格
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
    -- 期間(From)、期間(To)が設定されている場合
    IF (  g_item_work_tab(in_cnt)(cn_date_from) IS NOT NULL
      AND g_item_work_tab(in_cnt)(cn_date_to)   IS NOT NULL )
    THEN
      --===============================
      -- 日付形式チェック
      --===============================
      BEGIN
         ld_date := TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' );
         ld_date := TO_DATE( g_item_work_tab(in_cnt)(cn_date_to)  , 'YYYY/MM/DD' );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15170
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- 行No
                        ,iv_token_name2   => cv_tkn_date_from
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_date_from) -- 期間(From)
                        ,iv_token_name3   => cv_tkn_date_to
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_date_to)   -- 期間(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
      END;
--
      -- 日付形式エラーが発生していない場合
      IF (lv_status = cv_status_normal ) THEN
        --===============================
        -- 日付逆転チェック
        --===============================
        IF ( TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' )
               > TO_DATE( g_item_work_tab(in_cnt)(cn_date_to), 'YYYY/MM/DD' ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15159
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( in_cnt, cv_format )          -- 行No
                        ,iv_token_name2   => cv_tkn_date_from
                        ,iv_token_value2  => g_item_work_tab(in_cnt)(cn_date_from) -- 期間(From)
                        ,iv_token_name3   => cv_tkn_date_to
                        ,iv_token_value3  => g_item_work_tab(in_cnt)(cn_date_to)   -- 期間(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
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
--
  /**********************************************************************************
   * Procedure Name   : ins_work_table
   * Description      : 一時表登録処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_table(
    in_cnt                  IN  NUMBER   -- ループカウンタ
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
      INSERT INTO xxcos_tmp_sale_plice_lists(
        line_no         -- 行No
       ,proc_kbn        -- 処理区分
       ,customer_code   -- 顧客コード
       ,item_id         -- 品目ID
       ,item_code       -- 品目コード
       ,price           -- 価格
       ,date_from       -- 期間(From)
       ,date_to         -- 期間(To)
      )VALUES(
        in_cnt                                             -- 行No
       ,g_item_work_tab(in_cnt)(cn_proc_kbn)               -- 処理区分
       ,g_item_work_tab(in_cnt)(cn_cust_code)              -- 顧客コード
       ,TO_NUMBER( g_item_work_tab(in_cnt)(cn_item_id) )   -- 品目ID
       ,g_item_work_tab(in_cnt)(cn_item_code)              -- 品目コード
       ,TO_NUMBER( g_item_work_tab(in_cnt)(cn_price) )     -- 価格
       ,TO_DATE( g_item_work_tab(in_cnt)(cn_date_from), 'YYYY/MM/DD' ) -- 期間(From)
       ,TO_DATE( g_item_work_tab(in_cnt)(cn_date_to)  , 'YYYY/MM/DD' ) -- 期間(To)
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name
                      ,iv_name         => ct_msg_cos_15160   -- 一時表登録エラー
                      ,iv_token_name1  => cv_tkn_line_no
                      ,iv_token_value1 => TO_CHAR( in_cnt, cv_format ) -- 行No
                      ,iv_token_name2  => cv_tkn_err_msg
                      ,iv_token_value2 => SQLERRM    -- エラー内容
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
--
  /**********************************************************************************
   * Procedure Name   : data_insert
   * Description      : 特売価格表反映処理(A-6)
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
    cv_ship_to                VARCHAR2(10) := 'SHIP_TO'; -- 出荷先
    -- *** ローカル変数 ***
    ln_chk_cnt                NUMBER;          -- チェック件数
    ln_del_cnt                NUMBER;          -- 削除件数
    lv_message                VARCHAR2(32765); -- メッセージ
    lv_status                 VARCHAR2(1);     -- ステータス
    lv_pre_status             VARCHAR2(1);     -- 前レコードステータス
    ln_sale_price_lists_s01   NUMBER;          -- 特売価格表シーケンス
    lt_pre_cust_code          hz_cust_accounts.account_number%TYPE;   -- 顧客コード(前レコード)
    lt_customer_id            hz_cust_accounts.cust_account_id%TYPE;  -- 顧客ID
    -- *** ローカル・カーソル ***
--
    -- 特売価格表一時表取得カーソル
    CURSOR get_sale_price_lists_cur
    IS
      SELECT xtspl.line_no       AS line_no       -- 行No
            ,xtspl.proc_kbn      AS proc_kbn      -- 処理区分
            ,xtspl.customer_code AS customer_code -- 顧客コード
            ,xtspl.item_id       AS item_id       -- 品目ID
            ,xtspl.item_code     AS item_code     -- 品目コード
            ,xtspl.price         AS price         -- 価格
            ,xtspl.date_from     AS date_from     -- 期間(From)
            ,xtspl.date_to       AS date_to       -- 期間(To)
      FROM   xxcos_tmp_sale_plice_lists  xtspl    -- 特売価格表一時表
      ORDER BY
             xtspl.proc_kbn      -- 処理区分
            ,xtspl.customer_code -- 顧客コード
    ;
--
    -- カーソルレコード型
    get_sale_price_lists_rec  get_sale_price_lists_cur%ROWTYPE;
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
    lt_pre_cust_code := NULL;
    lt_customer_id   := NULL;
--
    -- カーソル取得
    <<main_loop>>
    FOR get_sale_price_lists_rec IN get_sale_price_lists_cur LOOP
--
      -- 変数初期化
      lv_status  := cv_status_normal; -- ステータス
      ln_chk_cnt := 0;  -- チェック件数
      ln_del_cnt := 0;  -- 削除件数
--
      -- 1レコード目、または前レコードと顧客が異なる場合
      IF ( (lt_pre_cust_code IS NULL) OR (lt_pre_cust_code <> get_sale_price_lists_rec.customer_code) ) THEN
        --===============================
        -- 顧客マスタ存在チェック
        --===============================
        BEGIN
          SELECT hca.cust_account_id  AS csut_account_id -- 顧客ID
          INTO   lt_customer_id
          FROM   hz_cust_accounts       hca
          WHERE  hca.account_number = get_sale_price_lists_rec.customer_code -- 顧客コード
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => ct_xxcos_appl_short_name
                          ,iv_name          => ct_msg_cos_15154 -- 顧客コード不正エラー
                          ,iv_token_name1   => cv_tkn_line_no
                          ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                          ,iv_token_name2   => cv_tkn_cust_code
                          ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- 顧客コード
                         );
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT
             ,buff  => lv_errmsg
            );
            lv_status := cv_status_warn;
        END;
--
        -- 顧客コードを保持
        lt_pre_cust_code := get_sale_price_lists_rec.customer_code;
--
        -- 顧客エラーが発生していない場合
        IF ( lv_status = cv_status_normal ) THEN
--
          -- 処理区分が「I：登録」の場合
          IF ( get_sale_price_lists_rec.proc_kbn = cv_i ) THEN
            --===============================
            -- 顧客ステータスチェック
            --===============================
            -- 顧客ステータスチェック用のクイックコードに存在するか確認
            SELECT COUNT (1) AS cnt
            INTO   ln_chk_cnt
            FROM   hz_cust_accounts   hca
                  ,hz_parties         hp
                  ,fnd_lookup_values  flv
            WHERE  hca.party_id       = hp.party_id
            AND    hca.account_number = get_sale_price_lists_rec.customer_code -- 顧客コード
            AND    flv.lookup_type    = ct_lookup_type_cust_status
            AND    flv.lookup_code LIKE cv_lookup_code_a01
            AND    flv.language       = ct_lang
            AND    gd_process_date   >= NVL( flv.start_date_active ,gd_process_date )
            AND    gd_process_date   <= NVL( flv.end_date_active   ,gd_process_date )
            AND    flv.enabled_flag   = cv_y
            AND    flv.meaning        = hp.duns_number_c
            ;
--
            IF ( ln_chk_cnt = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15155 -- 顧客ステータス不正エラー
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                            ,iv_token_name2   => cv_tkn_cust_code
                            ,iv_token_value2  => get_sale_price_lists_rec.customer_code   -- 顧客コード
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
          END IF;
--
          --===============================
          -- 顧客区分チェック
          --===============================
          ln_chk_cnt := 0;
--
          SELECT COUNT(1) AS cnt
          INTO   ln_chk_cnt
          FROM   hz_cust_accounts hca
                ,hz_cust_acct_sites_all hcas
                ,hz_cust_site_uses_all  hcsu
          WHERE  hcas.cust_account_id   = hca.cust_account_id
          AND    hcas.org_id            = gn_org_id
          AND    hcsu.cust_acct_site_id = hcas.cust_acct_site_id
          AND    hcsu.org_id            = hcas.org_id
          AND    hcsu.site_use_code     = cv_ship_to        -- 出荷先
          AND    hca.account_number     = get_sale_price_lists_rec.customer_code -- 顧客コード
          ;
          IF ( ln_chk_cnt = 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => ct_xxcos_appl_short_name
                          ,iv_name          => ct_msg_cos_15156 -- 顧客区分不正エラー
                          ,iv_token_name1   => cv_tkn_line_no
                          ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                          ,iv_token_name2   => cv_tkn_cust_code
                          ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- 顧客コード
                         );
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT
             ,buff  => lv_errmsg
            );
            lv_status := cv_status_warn;
          END IF;
--
          --===============================
          -- 顧客セキュリティチェック
          --===============================
          -- プロファイル「特売価格表全拠点有効フラグ」がNの場合
          IF ( gv_all_base_flg = cv_n ) THEN
            ln_chk_cnt := 0;
--
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcmm_cust_accounts     xca  -- 顧客追加情報
                  ,xxcos_login_base_info_v xlbi -- ログインユーザ拠点ビュー
            WHERE  xca.customer_code = get_sale_price_lists_rec.customer_code
            AND   (   xlbi.base_code = xca.sale_base_code
                   OR xlbi.base_code = xca.delivery_base_code
                   OR xlbi.base_code = xca.sales_head_base_code
                  )
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15158 -- 顧客セキュリティエラー
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                            ,iv_token_name2   => cv_tkn_cust_code
                            ,iv_token_value2  => get_sale_price_lists_rec.customer_code -- 顧客コード
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
          END IF;
        END IF;
      ELSE
        -- 前レコードと同一顧客の場合
        IF( lv_pre_status = cv_status_warn ) THEN
          lv_status := cv_status_warn;
        END IF;
      END IF;
--
      -- 顧客チェックでエラーが発生していない場合
      IF ( lv_status = cv_status_normal ) THEN
        -- ステータス設定
        lv_pre_status := cv_status_normal;
--
        --==================================
        -- 処理区分・期間重複チェック
        --==================================
        ln_chk_cnt := 0;
--
        IF ( get_sale_price_lists_rec.item_id IS NULL ) THEN
--
          -- 価格情報がNULLの場合、処理区分、顧客が重複する場合はエラー
          SELECT COUNT(1) AS cnt
          INTO   ln_chk_cnt
          FROM   xxcos_tmp_sale_plice_lists  xtspl    -- 特売価格表一時表
          WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn     -- 処理区分
          AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code  -- 顧客コード
          ;
        ELSE
          -- 価格情報がNULLでない場合
          IF ( get_sale_price_lists_rec.proc_kbn = cv_d ) THEN
            -- 削除の場合
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcos_tmp_sale_plice_lists  xtspl    -- 特売価格表一時表
            WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn      -- 処理区分
            AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code -- 顧客コード
            AND    xtspl.item_id       = get_sale_price_lists_rec.item_id       -- 品目ID
            AND    xtspl.date_from     = get_sale_price_lists_rec.date_from     -- 期間(From)
            AND    xtspl.date_to       = get_sale_price_lists_rec.date_to       -- 期間(To)
            ;
          ELSE
            -- 登録の場合
            SELECT COUNT(1) AS cnt
            INTO   ln_chk_cnt
            FROM   xxcos_tmp_sale_plice_lists  xtspl     -- 特売価格表一時表
            WHERE  xtspl.proc_kbn      = get_sale_price_lists_rec.proc_kbn      -- 処理区分
            AND    xtspl.customer_code = get_sale_price_lists_rec.customer_code -- 顧客コード
            AND  ( xtspl.item_id IS NULL                 -- 価格情報がNULLの場合
              OR ( xtspl.item_id IS NOT NULL             -- 価格情報がNULLでない場合
                   AND xtspl.item_id = get_sale_price_lists_rec.item_id       -- 品目ID
                   AND (
                         (   get_sale_price_lists_rec.date_from  BETWEEN xtspl.date_from AND xtspl.date_to  -- 期間(From)
                          OR get_sale_price_lists_rec.date_to    BETWEEN xtspl.date_from AND xtspl.date_to) -- 期間(To)
                      OR (   xtspl.date_from  BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to  -- 期間(From)
                          OR xtspl.date_to    BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to) -- 期間(To)
                       )
                 )
                 )
            ;
          END IF;
        END IF;
--
        -- 重複レコードが存在する場合
        IF ( ln_chk_cnt <> 1 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name
                        ,iv_name          => ct_msg_cos_15161  -- 処理区分・期間重複エラー
                        ,iv_token_name1   => cv_tkn_line_no
                        ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                        ,iv_token_name2   => cv_tkn_proc_kbn
                        ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- 処理区分
                        ,iv_token_name3   => cv_tkn_cust_code
                        ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- 顧客コード
                        ,iv_token_name4   => cv_tkn_item_code
                        ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- 品目コード
                        ,iv_token_name5   => cv_tkn_price
                        ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- 価格
                        ,iv_token_name6   => cv_tkn_date_from
                        ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- 期間(From)
                        ,iv_token_name7   => cv_tkn_date_to
                        ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- 期間(To)
                       );
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT
           ,buff  => lv_errmsg
          );
          lv_status := cv_status_warn;
        END IF;
--
        -- エラーが発生していない場合
        IF ( lv_status = cv_status_normal ) THEN
          --==================================
          -- 特売価格表反映
          --==================================
          -- 削除の場合
          IF ( get_sale_price_lists_rec.proc_kbn = cv_d ) THEN
--
            BEGIN
              -- 特売価格表削除
              DELETE FROM xxcos_sale_price_lists xspl  -- 特売価格表
              WHERE  lt_customer_id = xspl.customer_id  -- 顧客ID
              AND  ((get_sale_price_lists_rec.item_id IS NULL                 -- 価格情報がNULLの場合
                     AND xspl.item_id           IS NULL  -- 品目ID
                     AND xspl.start_date_active IS NULL  -- 期間(From)
                     AND xspl.end_date_active   IS NULL  -- 期間(To)
                    )
                OR ( get_sale_price_lists_rec.item_id IS NOT NULL             -- 価格情報がNULLでない場合
                     AND get_sale_price_lists_rec.item_id   = xspl.item_id            -- 品目ID
                     AND get_sale_price_lists_rec.date_from = xspl.start_date_active  -- 期間(From)
                     AND get_sale_price_lists_rec.date_to   = xspl.end_date_active    -- 期間(To)
                   )
                   )
              ;
              -- 削除件数を保持
              ln_del_cnt := SQL%ROWCOUNT;
--
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => ct_xxcos_appl_short_name
                              ,iv_name         => ct_msg_cos_15162   -- 特売価格表削除エラー
                              ,iv_token_name1  => cv_tkn_line_no
                              ,iv_token_value1 => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                              ,iv_token_name2  => cv_tkn_err_msg
                              ,iv_token_value2 => SQLERRM    -- エラー内容
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_api_expt;
            END;
--
            -- 削除件数が0件の場合
            IF (ln_del_cnt = 0) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application   => ct_xxcos_appl_short_name
                            ,iv_name          => ct_msg_cos_15164  -- 削除対象なしエラー
                            ,iv_token_name1   => cv_tkn_line_no
                            ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                            ,iv_token_name2   => cv_tkn_proc_kbn
                            ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- 処理区分
                            ,iv_token_name3   => cv_tkn_cust_code
                            ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- 顧客コード
                            ,iv_token_name4   => cv_tkn_item_code
                            ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- 品目コード
                            ,iv_token_name5   => cv_tkn_price
                            ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- 価格
                            ,iv_token_name6   => cv_tkn_date_from
                            ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- 期間(From)
                            ,iv_token_name7   => cv_tkn_date_to
                            ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- 期間(To)
                           );
              FND_FILE.PUT_LINE(
                which => FND_FILE.OUTPUT
               ,buff  => lv_errmsg
              );
              lv_status := cv_status_warn;
            END IF;
--
          -- 登録の場合
          ELSE
            --==================================
            -- 特売価格表重複チェック
            --==================================
            -- 価格情報がNULLの場合
            IF ( get_sale_price_lists_rec.item_id IS NULL ) THEN
              -- 同一顧客のレコードが存在する場合
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists  xspl -- 特売価格表
              WHERE  xspl.customer_id = lt_customer_id -- 顧客ID
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15168  -- 特売価格表顧客登録済エラー
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn      -- 処理区分
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code -- 顧客コード
                             );
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT
                 ,buff  => lv_errmsg
                );
                lv_status := cv_status_warn;
              END IF;
            ELSE
            -- 価格情報がNULLでない場合
              -- 価格情報NULLのレコードが既に存在する場合
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists xspl    -- 特売価格表
              WHERE  xspl.customer_id = lt_customer_id -- 顧客ID
              AND    xspl.item_id     IS NULL                                -- 品目ID
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15169  -- 価格情報未設定レコード登録済エラー
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn      -- 処理区分
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code -- 顧客コード
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
--
              -- 期間が重複するレコードが存在する場合
              SELECT COUNT(1) AS cnt
              INTO   ln_chk_cnt
              FROM   xxcos_sale_price_lists  xspl    -- 特売価格表
              WHERE  xspl.customer_id       = lt_customer_id   -- 顧客ID
              AND    xspl.item_id           = get_sale_price_lists_rec.item_id       -- 品目ID
              AND  (
                     (  get_sale_price_lists_rec.date_from BETWEEN xspl.start_date_active AND xspl.end_date_active   -- 期間(From)
                     OR get_sale_price_lists_rec.date_to   BETWEEN xspl.start_date_active AND xspl.end_date_active   -- 期間(To)
                     )
                 OR  (  xspl.start_date_active BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to -- 期間(From)
                     OR xspl.end_date_active   BETWEEN get_sale_price_lists_rec.date_from AND get_sale_price_lists_rec.date_to  -- 期間(To)
                     )
                   )
              ;
--
              IF ( ln_chk_cnt <> 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application   => ct_xxcos_appl_short_name
                              ,iv_name          => ct_msg_cos_15165  -- 特売価格表登録済エラー
                              ,iv_token_name1   => cv_tkn_line_no
                              ,iv_token_value1  => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                              ,iv_token_name2   => cv_tkn_proc_kbn
                              ,iv_token_value2  => get_sale_price_lists_rec.proc_kbn         -- 処理区分
                              ,iv_token_name3   => cv_tkn_cust_code
                              ,iv_token_value3  => get_sale_price_lists_rec.customer_code    -- 顧客コード
                              ,iv_token_name4   => cv_tkn_item_code
                              ,iv_token_value4  => get_sale_price_lists_rec.item_code        -- 品目コード
                              ,iv_token_name5   => cv_tkn_price
                              ,iv_token_value5  => TO_CHAR( get_sale_price_lists_rec.price ) -- 価格
                              ,iv_token_name6   => cv_tkn_date_from
                              ,iv_token_value6  => TO_CHAR( get_sale_price_lists_rec.date_from, 'YYYY/MM/DD' ) -- 期間(From)
                              ,iv_token_name7   => cv_tkn_date_to
                              ,iv_token_value7  => TO_CHAR( get_sale_price_lists_rec.date_to  , 'YYYY/MM/DD' ) -- 期間(To)
                             );
                FND_FILE.PUT_LINE(
                  which => FND_FILE.OUTPUT
                 ,buff  => lv_errmsg
                );
                lv_status := cv_status_warn;
--
              END IF;
            END IF;
--
            -- エラーが発生していない場合
            IF ( lv_status = cv_status_normal ) THEN
--
              BEGIN
                -- 特売価格表登録
                INSERT INTO xxcos_sale_price_lists(
                  sale_price_list_id     -- 特売価格表ID
                 ,customer_id            -- 顧客ID
                 ,item_id                -- 品目ID
                 ,price                  -- 価格
                 ,start_date_active      -- 有効開始日
                 ,end_date_active        -- 有効終了日
                 ,created_by             -- 作成者
                 ,creation_date          -- 作成日
                 ,last_updated_by        -- 最終更新者
                 ,last_update_date       -- 最終更新日
                 ,last_update_login      -- 最終更新ログイン
                 ,request_id             -- 要求ID
                 ,program_application_id -- コンカレント・プログラム・アプリケーションID
                 ,program_id             -- コンカレント・プログラムID
                 ,program_update_date    -- プログラム更新日
                )VALUES(
                  xxcos_sale_price_lists_s01.NEXTVAL   -- 特売価格表ID
                 ,lt_customer_id                       -- 顧客ID
                 ,get_sale_price_lists_rec.item_id     -- 品目ID
                 ,get_sale_price_lists_rec.price       -- 価格
                 ,get_sale_price_lists_rec.date_from   -- 有効開始日
                 ,get_sale_price_lists_rec.date_to     -- 有効開始日
                 ,cn_created_by                        -- 作成者
                 ,cd_creation_date                     -- 作成日
                 ,cn_last_updated_by                   -- 最終更新者
                 ,cd_last_update_date                  -- 最終更新日
                 ,cn_last_update_login                 -- 最終更新ログイン
                 ,cn_request_id                        -- 要求ID
                 ,cn_program_application_id            -- コンカレント・プログラム・アプリケーションID
                 ,cn_program_id                        -- コンカレント・プログラムID
                 ,cd_program_update_date               -- プログラム更新日
                );
              EXCEPTION
                WHEN OTHERS THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => ct_xxcos_appl_short_name
                                ,iv_name         => ct_msg_cos_15163   -- 特売価格表登録エラー
                                ,iv_token_name1  => cv_tkn_line_no
                                ,iv_token_value1 => TO_CHAR( get_sale_price_lists_rec.line_no, cv_format ) -- 行No
                                ,iv_token_name2  => cv_tkn_err_msg
                                ,iv_token_value2 => SQLERRM    -- エラー内容
                               );
                  lv_errbuf := lv_errmsg;
                  RAISE global_api_expt;
              END;
            END IF;
          END IF;
        END IF;
      ELSE
        -- 顧客チェックエラーが発生している場合
        lv_pre_status := cv_status_warn;
      END IF;
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
--
      <<ins_work_table_loop>>
      FOR i IN 2 .. gn_get_counter_data LOOP
        --==================================
        -- 一時表登録処理(A-5)
        --==================================
        ins_work_table(
          in_cnt                  => i                       -- ループカウンタ
         ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
         ,ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
         ,ov_errmsg               => lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP ins_work_table_loop;
--
      --==================================
      -- 特売価格表反映処理(A-6)
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
END XXCOS003A08C;
/
