CREATE OR REPLACE PACKAGE BODY APPS.XXCOK001A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOK001A06C(body)
 * Description      : 年次顧客移行情報csvアップロード
 * MD.050           : MD050_COK_001_A06_年次顧客移行情報csvアップロード
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_file_upload_data   ファイルアップロードデータ取得処理(A-2)
 *  conv_file_upload_data  ファイルアップロードデータ変換処理(A-3)
 *  ins_tmp_001a06c_upload 年次顧客移行情報csvアップロード一時表登録処理(A-4)
 *  chk_validate_item      妥当性チェック処理(A-5)
 *  ins_cust_shift_info    顧客移行情報一括登録処理(A-6)
 *  upd_cust_shift_info    顧客移行情報一括更新処理(A-7)
 *  out_error_message      エラーメッセージ出力処理(A-8)
 *  del_file_upload_data   ファイルアップロードデータ削除処理(A-9)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/02/07    1.0   K.Nakamura       新規作成
 *  2013/03/13    1.1   K.Nakamura       機能名を「年次顧客移行情報csvアップロード一時表」に変更
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
  global_lock_expt          EXCEPTION; -- ロック例外
  global_chk_item_expt      EXCEPTION; -- 妥当性チェック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOK001A06C';            -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOK';                   -- アプリケーション
  -- プロファイル
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';        -- 会計帳簿ID
  -- クイックコード
  cv_yearly_cust_shift_item   CONSTANT VARCHAR2(30) := 'XXCOK1_YEARLY_CUST_SHIFT_ITEM'; -- 年次顧客移行情報csvアップロード項目チェック
  cv_cust_shift_status        CONSTANT VARCHAR2(30) := 'XXCOK1_CUST_SHIFT_STATUS';      -- 顧客移行情報ステータス
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';        -- ファイルアップロード情報
  -- メッセージ
  cv_msg_xxcok_00005          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00005';        -- 従業員取得エラーメッセージ
  cv_msg_xxcok_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00006';        -- ファイル名出力用メッセージ
  cv_msg_xxcok_00008          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00008';        -- 会計帳簿情報取得エラーメッセージ
  cv_msg_xxcok_00015          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015';        -- クイックコード取得エラーメッセージ
  cv_msg_xxcok_00016          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';        -- ファイルID出力用メッセージ
  cv_msg_xxcok_00017          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';        -- ファイルパターン出力用メッセージ
  cv_msg_xxcok_00028          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';        -- 業務処理日付取得エラーメッセージ
  cv_msg_xxcok_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';        -- BLOBデータ変換エラーメッセージ
  cv_msg_xxcok_00061          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';        -- ファイルアップロードロックエラーメッセージ
  cv_msg_xxcok_00062          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';        -- ファイルアップロードIF削除エラーメッセージ
  cv_msg_xxcok_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00065';        -- 会計帳期間情報取得エラーメッセージ
  cv_msg_xxcok_00066          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00066';        -- 翌会計年度取得エラーメッセージ
  cv_msg_xxcok_00106          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00106';        -- ファイルアップロード名称出力用メッセージ
  cv_msg_xxcok_10507          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10507';        -- 顧客移行情報一括アップロード一時表登録エラーメッセージ
  cv_msg_xxcok_10508          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10508';        -- 顧客移行情報一括アップロード一時表更新エラーメッセージ
  cv_msg_xxcok_10509          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10509';        -- 顧客移行情報登録エラーメッセージ
  cv_msg_xxcok_10510          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10510';        -- 顧客移行情報更新エラーメッセージ
  cv_msg_xxcok_10511          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10511';        -- 顧客移行情報ロックエラーメッセージ
  cv_msg_xxcok_10512          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10512';        -- 顧客移行情報必須エラーメッセージ
  cv_msg_xxcok_10513          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10513';        -- 顧客移行情報ステータスエラーメッセージ
  cv_msg_xxcok_10514          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10514';        -- 顧客移行情報拠点コード設定エラーメッセージ
  cv_msg_xxcok_10515          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10515';        -- 顧客移行情報確定済みエラーメッセージ
  cv_msg_xxcok_10516          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10516';        -- 顧客移行情報登録済みエラーメッセージ
  cv_msg_xxcok_10517          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10517';        -- 顧客移行情報取消済みエラーメッセージ
  cv_msg_xxcok_10518          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10518';        -- 顧客移行情報登録済み（期中）エラーメッセージ
  cv_msg_xxcok_10519          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10519';        -- 顧客移行情報取消対象なしエラーメッセージ
  cv_msg_xxcok_10520          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10520';        -- 顧客移行情報新拠点変更不可エラーメッセージ
  cv_msg_xxcok_10521          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10521';        -- 顧客移行情報同一ファイル内前レコードエラーメッセージ
  cv_msg_xxcok_10522          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10522';        -- 顧客移行情報同一ファイル内重複エラーメッセージ
  cv_msg_xxcok_10523          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10523';        -- 顧客移行情報顧客コード存在チェックエラーメッセージ
  cv_msg_xxcok_10524          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10524';        -- 顧客移行情報旧拠点コードエラーメッセージ
  cv_msg_xxcok_10525          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10525';        -- 顧客移行情報新拠点コード存在チェックエラーメッセージ
  cv_msg_xxcok_10526          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10526';        -- 顧客移行情報新拠点コード有効範囲外エラーメッセージ
  cv_msg_xxcok_10527          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10527';        -- 顧客移行情報空行エラーメッセージ
  cv_msg_xxcok_10528          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10528';        -- 顧客移行情報項目数相違エラーメッセージ
  cv_msg_xxcok_10529          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10529';        -- 顧客移行情報項目不備エラーメッセージ
  -- トークンコード
  cv_tkn_cust_code            CONSTANT VARCHAR2(20) := 'CUST_CODE';               -- 顧客コード
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';                  -- エラー内容詳細
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';                 -- ファイルID
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';               -- ファイル名称
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';                  -- フォーマット
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';                    -- 項目
  cv_tkn_lookup_value_set     CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';        -- タイプ
  cv_tkn_new_base_code        CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE';           -- 新拠点コード
  cv_tkn_new_base_code_from   CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE_FROM';      -- 新拠点コード開始日
  cv_tkn_new_base_code_to     CONSTANT VARCHAR2(20) := 'NEW_BASE_CODE_TO';        -- 新拠点コード終了日
  cv_tkn_prev_base_code       CONSTANT VARCHAR2(20) := 'PREV_BASE_CODE';          -- 旧拠点コード
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- プロファイル
  cv_tkn_record_no            CONSTANT VARCHAR2(20) := 'RECORD_NO';               -- レコードNo
  cv_tkn_status               CONSTANT VARCHAR2(20) := 'STATUS';                  -- ステータス
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';           -- ファイルアップロード名称
  -- 移行区分
  cv_shift_type_1             CONSTANT VARCHAR2(1)  := '1';                       -- 年次
  -- ステータス（顧客移行情報／年次顧客移行情報csvアップロード一時表）
  cv_status_a                 CONSTANT VARCHAR2(1)  := 'A';                       -- 確定
  cv_status_c                 CONSTANT VARCHAR2(1)  := 'C';                       -- 取消
  cv_status_i                 CONSTANT VARCHAR2(1)  := 'I';                       -- 入力中
  cv_status_w                 CONSTANT VARCHAR2(1)  := 'W';                       -- 確定前
  -- 釣銭仕訳作成フラグ
  cv_create_chg_je_flag_0     CONSTANT VARCHAR2(1)  := '0';                       -- 未作成
  cv_create_chg_je_flag_2     CONSTANT VARCHAR2(1)  := '2';                       -- 対象外
  -- VD在庫保管場所転送ステータス
  cv_vd_inv_trnsfr_status_0   CONSTANT VARCHAR2(1)  := '0';                       -- 未転送
  cv_vd_inv_trnsfr_status_3   CONSTANT VARCHAR2(1)  := '3';                       -- 対象外
  -- 営業自販機連携フラグ
  cv_business_vd_if_flag_0    CONSTANT VARCHAR2(1)  := '0';                       -- 未連携
  -- 営業FA連携フラグ
  cv_business_fa_if_flag_0    CONSTANT VARCHAR2(1)  := '0';                       -- 未連携
  -- アップロード判定フラグ
  cv_upload_dicide_flag_i     CONSTANT VARCHAR2(1)  := 'I';                       -- 登録
  cv_upload_dicide_flag_u     CONSTANT VARCHAR2(1)  := 'U';                       -- 更新
  cv_upload_dicide_flag_w     CONSTANT VARCHAR2(1)  := 'W';                       -- 警告
  -- 顧客区分
  cv_customer_class_code_10   CONSTANT VARCHAR2(2)  := '10';                      -- 顧客
  cv_customer_class_code_12   CONSTANT VARCHAR2(2)  := '12';                      -- 上様顧客
  cv_customer_class_code_14   CONSTANT VARCHAR2(2)  := '14';                      -- 売掛管理先顧客
  cv_customer_class_code_15   CONSTANT VARCHAR2(2)  := '15';                      -- 店舗営業
  -- 顧客ステータス
  cv_cust_status_20           CONSTANT VARCHAR2(2)  := '20';                      -- MC
  -- 情報抽出用
  cv_appl_short_name_gl       CONSTANT VARCHAR2(5)  := 'SQLGL';                   -- GL
  cv_adjustment_period_flag_n CONSTANT VARCHAR2(1)  := 'N';                       -- 調整期間フラグ（調整期間なし）
  cv_yyyymmdd                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- 年月日書式
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                       -- 'Y'
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
  -- 文字列
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                       -- 文字区切り
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                       -- 文字括り
  -- 数値
  cn_zero                     CONSTANT NUMBER       := 0;                         -- 0
  cn_one                      CONSTANT NUMBER       := 1;                         -- 1
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目チェック格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1              fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2              fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3              fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4              fnd_lookup_values.attribute4%TYPE -- 属性
  );
  -- テーブルタイプ
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- テーブル型
  gt_csv_data_old             xxcok_common_pkg.g_split_csv_tbl;  -- CSV分割データ（文字区切り処理前）
  gt_csv_data                 xxcok_common_pkg.g_split_csv_tbl;  -- CSV分割データ（文字区切り処理後）
  gt_file_data_all            xxccp_common_pkg2.g_file_data_tbl; -- 変換後VARCHAR2データ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_employee_code            VARCHAR2(5)  DEFAULT NULL;  -- 従業員コード
  gv_status_c                 VARCHAR2(10) DEFAULT NULL;  -- 取消
  gv_status_i                 VARCHAR2(10) DEFAULT NULL;  -- 入力中
  gv_status_w                 VARCHAR2(10) DEFAULT NULL;  -- 確定前
  gn_set_of_books_id          NUMBER       DEFAULT NULL;  -- 会計帳簿ID
  gn_item_cnt                 NUMBER       DEFAULT 0;     -- CSV項目数
  gn_line_cnt                 NUMBER       DEFAULT 0;     -- CSV処理行カウンタ
  gn_record_no                NUMBER       DEFAULT 0;     -- レコードNo
  gn_target_acctg_year        NUMBER       DEFAULT NULL;  -- 翌会計年度
  gn_ins_cnt                  NUMBER       DEFAULT 0;     -- 登録件数
  gn_upd_cnt_i                NUMBER       DEFAULT 0;     -- 更新件数（ステータス：入力中）
  gn_upd_cnt_w                NUMBER       DEFAULT 0;     -- 更新件数（ステータス：確定前）
  gn_upd_cnt_c                NUMBER       DEFAULT 0;     -- 更新件数（ステータス：取消）
  gd_process_date             DATE         DEFAULT NULL;  -- 業務日付
  gd_cust_shift_date          DATE         DEFAULT NULL;  -- 翌会計年度期首
  gb_ins_record_flg           BOOLEAN      DEFAULT TRUE;  -- 登録対象レコードフラグ
  -- テーブル変数
  g_chk_item_tab              g_chk_item_ttype;        -- 項目チェック
--
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- 妥当性チェックカーソル
  CURSOR chk_cur
  IS
    SELECT xt0u.record_no      AS record_no      -- レコードNo
         , xt0u.cust_code      AS cust_code      -- 顧客コード
         , xt0u.prev_base_code AS prev_base_code -- 旧拠点コード
         , xt0u.new_base_code  AS new_base_code  -- 新拠点コード
         , xt0u.status         AS status         -- ステータス
    FROM   xxcok_tmp_001a06c_upload xt0u         -- 年次顧客移行情報csvアップロード一時表
    WHERE  xt0u.cust_code IS NOT NULL
    ORDER BY
           xt0u.cust_code                        -- 顧客コード
         , xt0u.status    ASC NULLS FIRST        -- ステータス
         , xt0u.record_no                        -- レコードNo
  ;
  -- レコード定義
  chk_rec                     chk_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマット
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL; -- メッセージ
    lv_curr_period_name       VARCHAR2(10)   DEFAULT NULL; -- 現会計期間名
    lv_curr_closing_status    VARCHAR2(1)    DEFAULT NULL; -- 現会計期間ステータス
    ln_curr_period_year       NUMBER         DEFAULT NULL; -- 現会計年度
    lb_retcode                BOOLEAN;                     -- メッセージ戻り値
--
    -- *** ローカルカーソル ***
    -- 項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- 項目名称
           , flv.attribute1    AS attribute1  -- 項目の長さ
           , flv.attribute2    AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3    AS attribute3  -- 必須フラグ
           , flv.attribute4    AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_yearly_cust_shift_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    --==============================================================
    -- １．コンカレント入力パラメータメッセージ出力
    --==============================================================
    -- ファイルIDメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00016
                    , iv_token_name1  => cv_tkn_file_id
                    , iv_token_value1 => iv_file_id
                  );
    -- ファイルIDメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    -- フォーマットパターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00017
                    , iv_token_name1  => cv_tkn_format
                    , iv_token_value1 => iv_format
                  );
    -- フォーマットパターンメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
--
    --==============================================================
    -- ２．業務日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- アプリケーション短縮名
                     , iv_name        => cv_msg_xxcok_00028 -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ３．プロファイル取得
    --==============================================================
    --
    BEGIN
      -- 会計帳簿ID
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00008 -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00008 -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ４．クイックコード(項目チェック用定義情報)取得
    --==============================================================
    -- カーソルオープン
    OPEN chk_item_cur;
    -- データの一括取得
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- カーソルクローズ
    CLOSE chk_item_cur;
    -- クイックコードが取得できない場合
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- 参照タイプ取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application            -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00015        -- メッセージコード
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- トークンコード1
                     , iv_token_value1 => cv_yearly_cust_shift_item -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ５．クイックコード(項目チェック用定義情報の件数)取得
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
--
    --==============================================================
    -- ６．クイックコード(顧客移行情報ステータスの文字列)取得
    --==============================================================
    -- 取消
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_c
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_c
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- クイックコードが取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- 参照タイプ取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00015      -- メッセージコード
                       , iv_token_name1  => cv_tkn_lookup_value_set -- トークンコード1
                       , iv_token_value1 => cv_cust_shift_status    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    -- 入力中
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_i
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_i
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- クイックコードが取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- 参照タイプ取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00015      -- メッセージコード
                       , iv_token_name1  => cv_tkn_lookup_value_set -- トークンコード1
                       , iv_token_value1 => cv_cust_shift_status    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    -- 確定前
    BEGIN
      SELECT flv.meaning       AS meaning
      INTO   gv_status_w
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_cust_shift_status
      AND    flv.lookup_code  = cv_status_w
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active, gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
    EXCEPTION
      -- クイックコードが取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- 参照タイプ取得エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application          -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00015      -- メッセージコード
                       , iv_token_name1  => cv_tkn_lookup_value_set -- トークンコード1
                       , iv_token_value1 => cv_cust_shift_status    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- ７．会計カレンダ取得
    --==============================================================
    xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                   -- エラーバッファ
      , ov_retcode                => lv_retcode                  -- リターンコード
      , ov_errmsg                 => lv_errmsg                   -- エラーメッセージ
      , in_set_of_books_id        => gn_set_of_books_id          -- 会計帳簿ID
      , iv_application_short_name => cv_appl_short_name_gl       -- アプリケーション短縮名
      , id_object_date            => gd_process_date             -- 対象日
      , iv_adjustment_period_flag => cv_adjustment_period_flag_n -- 調整フラグ
      , on_period_year            => ln_curr_period_year         -- 会計年度
      , ov_period_name            => lv_curr_period_name         -- 会計期間名
      , ov_closing_status         => lv_curr_closing_status      -- ステータス
    );
    -- リターンコードがエラーまたは会計年度がNULLの場合
    IF ( ( lv_retcode = cv_status_error ) OR ( ln_curr_period_year IS NULL ) ) THEN
      -- 会計帳期間情報取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00065 -- メッセージコード
                     , iv_token_name1  => cv_tkn_errmsg      -- トークンコード1
                     , iv_token_value1 => SQLERRM            -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ８．翌会計年度期首日取得
    --==============================================================
    xxcok_common_pkg.get_next_year_p(
        ov_errbuf           => lv_errbuf            -- エラーバッファ
      , ov_retcode          => lv_retcode           -- リターンコード
      , ov_errmsg           => lv_errmsg            -- エラーメッセージ
      , in_set_of_books_id  => gn_set_of_books_id   -- 会計帳簿ID
      , in_period_year      => ln_curr_period_year  -- 会計年度
      , on_next_period_year => gn_target_acctg_year -- 翌会計年度
      , od_next_start_date  => gd_cust_shift_date   -- 翌会計年度期首
    );
    -- リターンコードがエラーまたは会計年度がNULLの場合
    IF ( ( lv_retcode = cv_status_error ) OR ( gn_target_acctg_year IS NULL ) ) THEN
      -- 翌会計年度期首日取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00066 -- メッセージコード
                     , iv_token_name1  => cv_tkn_errmsg      -- トークンコード1
                     , iv_token_value1 => SQLERRM            -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ９．従業員コード取得
    --==============================================================
    BEGIN
      gv_employee_code := xxcok_common_pkg.get_emp_code_f( cn_created_by );
    EXCEPTION
      -- 従業員コードが取得できない場合
      WHEN OTHERS THEN
      -- 従業員コード取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- アプリケーション短縮名
                     , iv_name        => cv_msg_xxcok_00005 -- メッセージコード
                   );
      ov_errmsg  := lv_errmsg;
      RAISE global_api_others_expt;
    END;
--
  EXCEPTION
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
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_data
   * Description      : ファイルアップロードデータ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_upload_data(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_upload_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_out_msg                VARCHAR2(2000) DEFAULT NULL; -- メッセージ
    lb_retcode                BOOLEAN;                     -- メッセージ戻り値
    -- *** ローカルカーソル ***
    -- アップロードファイルデータカーソル
    CURSOR xmfui_cur( in_file_id NUMBER )
    IS
      SELECT  xmfui.file_name             AS file_name     -- ファイル名
            , flv.meaning                 AS upload_object -- ファイルアップロード名称
      FROM    xxccp_mrp_file_ul_interface xmfui            -- ファイルアップロードIFテーブル
            , fnd_lookup_values           flv              -- クイックコード
      WHERE   xmfui.file_id    = in_file_id
      AND     flv.lookup_type  = cv_file_upload_obj
      AND     flv.lookup_code  = xmfui.file_content_type
      AND     gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                              AND     NVL( flv.end_date_active, gd_process_date )
      AND     flv.enabled_flag = cv_flag_y
      AND     flv.language     = ct_lang
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
    -- レコード定義
    xmfui_rec                 xmfui_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- １．ファイルアップロードIFテーブルロック取得
    --==============================================================
    BEGIN
      -- オープン
      OPEN xmfui_cur( TO_NUMBER(iv_file_id) );
      -- フェッチ
      FETCH xmfui_cur INTO xmfui_rec;
      -- クローズ
      CLOSE xmfui_cur;
      --
    EXCEPTION
      -- ロック取得例外ハンドラ
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00061 -- メッセージコード
                       , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                       , iv_token_value1 => iv_file_id         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ２．ファイルアップロード名称、ファイル名の出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00106 
                    , iv_token_name1  => cv_tkn_upload_object
                    , iv_token_value1 => xmfui_rec.upload_object
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_zero         -- 改行
                  );
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_msg_xxcok_00006
                    , iv_token_name1  => cv_tkn_file_name
                    , iv_token_value1 => xmfui_rec.file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG    -- 出力区分
                    , iv_message      => lv_out_msg      -- メッセージ
                    , in_new_line     => cn_one          -- 改行
                  );
--
    --==============================================================
    -- ３．BLOBデータ変換処理
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- ファイルID
      , ov_file_data => gt_file_data_all      -- 変換後VARCHAR2データ
      , ov_errbuf    => lv_errbuf             -- エラー・メッセージ
      , ov_retcode   => lv_retcode            -- リターン・コード
      , ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ 
    );
    -- リターンコードがエラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      -- BLOBデータ変換エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_00041 -- メッセージコード
                     , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                     , iv_token_value1 => iv_file_id         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : conv_file_upload_data
   * Description      : ファイルアップロードデータ変換処理(A-3)
   ***********************************************************************************/
  PROCEDURE conv_file_upload_data(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conv_file_upload_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_col_cnt                NUMBER  DEFAULT 0;     -- CSV項目数
    lb_blank_line_flag        BOOLEAN DEFAULT FALSE; -- 空行フラグ
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
    lb_blank_line_flag := FALSE;
    gb_ins_record_flg  := TRUE;
    gt_csv_data_old.DELETE;
    gt_csv_data.DELETE;
   -- カウントアップ
   gn_line_cnt := gn_line_cnt + 1;
--
    --==============================================================
    -- １．CSV文字列分割
    --==============================================================
    xxcok_common_pkg.split_csv_data_p(
        iv_csv_data      => gt_file_data_all(gn_line_cnt) -- CSV文字列
      , on_csv_col_cnt   => ln_col_cnt                    -- CSV項目数
      , ov_split_csv_tab => gt_csv_data_old               -- CSV分割データ
      , ov_errbuf        => lv_errbuf                     -- エラー・メッセージ
      , ov_retcode       => lv_retcode                    -- リターン・コード
      , ov_errmsg        => lv_errmsg                     -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    --==============================================================
    -- ２．レコードNo採番
    --==============================================================
    -- レコードNo
    gn_record_no  := gn_record_no + 1;
    -- 対象件数（CSVのレコード数）設定
    gn_target_cnt := gn_target_cnt + 1;
    --
    --==============================================================
    -- ３．項目数相違確認
    --==============================================================
    -- 項目数が異なる場合
    IF ( gn_item_cnt <> ln_col_cnt ) THEN
      -- 年次顧客移行情報項目数相違エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_10528 -- メッセージコード
                     , iv_token_name1  => cv_tkn_record_no   -- トークンコード1
                     , iv_token_value1 => gn_record_no       -- トークン値1
                   );
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
      --
    END IF;
    --
    --==============================================================
    -- ４．全項目未設定確認
    --==============================================================
    -- 全ての項目が未設定の場合
    IF ( TRIM( REPLACE( REPLACE( gt_file_data_all(gn_line_cnt), cv_comma, NULL ), cv_dobule_quote, NULL ) ) IS NULL ) THEN
      -- 年次顧客移行情報空行エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcok_10527 -- メッセージコード
                     , iv_token_name1  => cv_tkn_record_no   -- トークンコード1
                     , iv_token_value1 => gn_record_no       -- トークン値1
                   );
      -- 空行フラグON
      lb_blank_line_flag := TRUE;
      -- 妥当性チェック例外
      RAISE global_chk_item_expt;
      --
    END IF;
    --
    --==============================================================
    -- ５．項目チェック
    --==============================================================
    -- 項目チェックループ
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      -- 文字括りが存在する場合は削除
      gt_csv_data(i) := TRIM( REPLACE( gt_csv_data_old(i), cv_dobule_quote, NULL ) );
      --
      -- 項目チェック共通関数
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- 項目名称
        , iv_item_value   => gt_csv_data(i)               -- 項目の値
        , in_item_len     => g_chk_item_tab(i).attribute1 -- 項目の長さ
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- 項目の長さ(小数点以下)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- 必須フラグ
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- 項目属性
        , ov_errbuf       => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode                   -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- リターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 年次顧客移行情報項目不備エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_10529        -- メッセージコード
                       , iv_token_name1  => cv_tkn_item               -- トークンコード1
                       , iv_token_value1 => g_chk_item_tab(i).meaning -- トークン値1
                       , iv_token_name2  => cv_tkn_record_no          -- トークンコード2
                       , iv_token_value2 => gn_record_no              -- トークン値2
                       , iv_token_name3  => cv_tkn_errmsg             -- トークンコード3
                       , iv_token_value3 => lv_errmsg                 -- トークン値3
                     );
        -- 妥当性チェック例外
        RAISE global_chk_item_expt;
        --
      END IF;
      --
    END LOOP item_check_loop;
--
  EXCEPTION
    -- 妥当性チェック例外ハンドラ
    WHEN global_chk_item_expt THEN
      -- 登録対象レコードフラグOFF
      gb_ins_record_flg := FALSE;
      -- 空行は警告にしない（メッセージ表示のみ）
      IF ( lb_blank_line_flag = FALSE ) THEN
        -- 警告件数設定
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
      --==============================================================
      -- ６．チェックエラー時の一時表登録処理
      --==============================================================
      BEGIN
        INSERT INTO xxcok_tmp_001a06c_upload(
            file_id                 -- ファイルID
          , record_no               -- レコードNo
          , cust_code               -- 顧客コード
          , prev_base_code          -- 旧拠点コード
          , new_base_code           -- 新拠点コード
          , status                  -- ステータス
          , cust_shift_id           -- 顧客移行情報ID
          , customer_class_code     -- 顧客区分
          , upload_dicide_flag      -- アップロード判定フラグ
          , error_message           -- エラーメッセージ
        ) VALUES (
            TO_NUMBER(iv_file_id)   -- ファイルID
          , gn_record_no            -- レコードNo
          , NULL                    -- 顧客コード
          , NULL                    -- 旧拠点コード
          , NULL                    -- 新拠点コード
          , NULL                    -- ステータス
          , NULL                    -- 顧客移行情報ID
          , NULL                    -- 顧客区分
          , cv_upload_dicide_flag_w -- アップロード判定フラグ
          , lv_errmsg               -- エラーメッセージ
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcok_10507 -- メッセージコード
                         , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                         , iv_token_value1 => iv_file_id         -- トークン値1
                         , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END conv_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_tmp_001a06c_upload
   * Description      : 年次顧客移行情報csvアップロード一時表登録処理(A-4)
   ***********************************************************************************/
  PROCEDURE ins_tmp_001a06c_upload(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_tmp_001a06c_upload'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_status                 VARCHAR2(1) DEFAULT NULL; -- ステータス
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ステータスが確定前
    IF ( gt_csv_data(4) = gv_status_w ) THEN
      lv_status := cv_status_w;
    -- ステータスが入力中
    ELSIF ( gt_csv_data(4) = gv_status_i ) THEN
      lv_status := cv_status_i;
    -- ステータスが取消
    ELSIF ( gt_csv_data(4) = gv_status_c ) THEN
      lv_status := cv_status_c;
    -- ステータスが上記以外
    ELSE
      lv_status := NULL;
    END IF;
    --
    --==============================================================
    -- 年次顧客移行情報csvアップロード一時表登録処理
    --==============================================================
    BEGIN
      INSERT INTO xxcok_tmp_001a06c_upload(
          file_id               -- ファイルID
        , record_no             -- レコードNo
        , cust_code             -- 顧客コード
        , prev_base_code        -- 旧拠点コード
        , new_base_code         -- 新拠点コード
        , status                -- ステータス
        , cust_shift_id         -- 顧客移行情報ID
        , customer_class_code   -- 顧客区分
        , upload_dicide_flag    -- アップロード判定フラグ
        , error_message         -- エラーメッセージ
      ) VALUES (
          TO_NUMBER(iv_file_id) -- ファイルID
        , gn_record_no          -- レコードNo
        , gt_csv_data(1)        -- 顧客コード
        , gt_csv_data(2)        -- 旧拠点コード
        , gt_csv_data(3)        -- 新拠点コード
        , lv_status             -- ステータス
        , NULL                  -- 顧客移行情報ID
        , NULL                  -- 顧客区分
        , NULL                  -- アップロード判定フラグ
        , NULL                  -- エラーメッセージ
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_10507 -- メッセージコード
                       , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                       , iv_token_value1 => iv_file_id         -- トークン値1
                       , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_tmp_001a06c_upload;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : 妥当性チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_message_code           VARCHAR2(20) DEFAULT NULL;  -- メッセージコード
    lv_customer_class_code    VARCHAR2(2)  DEFAULT NULL;  -- 顧客区分
    lv_sales_base_code        VARCHAR2(4)  DEFAULT NULL;  -- 売上拠点
    lv_aff_department_code    VARCHAR2(4)  DEFAULT NULL;  -- 部門コード
    lv_new_base_code          VARCHAR2(4)  DEFAULT NULL;  -- 新拠点コード
    lv_status                 VARCHAR2(1)  DEFAULT NULL;  -- ステータス
    lv_upload_dicide_flag     VARCHAR2(1)  DEFAULT NULL;  -- アップロード判定フラグ
    lv_upload_dicide_flag_upd VARCHAR2(1)  DEFAULT NULL;  -- アップロード判定フラグ（一時表更新用）
    lv_err_status             VARCHAR2(10) DEFAULT NULL;  -- エラー時ステータス
    ln_cust_shift_id          NUMBER       DEFAULT NULL;  -- 顧客移行情報ID
    ln_chk_cnt                NUMBER       DEFAULT 0;     -- チェック用件数
    ln_dummy                  NUMBER       DEFAULT 0;     -- ダミー値
    ld_start_date_active      DATE         DEFAULT NULL;  -- 開始日
    ld_end_date_active        DATE         DEFAULT NULL;  -- 終了日
    ld_cust_shift_date        DATE         DEFAULT NULL;  -- 顧客移行日
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
    lv_message_code           := NULL; -- メッセージコード
    lv_customer_class_code    := NULL; -- 顧客区分
    lv_sales_base_code        := NULL; -- 売上拠点
    lv_aff_department_code    := NULL; -- 部門コード
    lv_new_base_code          := NULL; -- 新拠点コード
    lv_status                 := NULL; -- ステータス
    lv_upload_dicide_flag     := NULL; -- アップロード判定フラグ
    lv_upload_dicide_flag_upd := NULL; -- アップロード判定フラグ（一時表更新用）
    ln_cust_shift_id          := NULL; -- 顧客移行情報ID
    ln_chk_cnt                := 0;    -- チェック用件数
    ln_dummy                  := 0;    -- ダミー値
    ld_start_date_active      := NULL; -- 開始日
    ld_end_date_active        := NULL; -- 終了日
    ld_cust_shift_date        := NULL; -- 顧客移行日
--
    --==============================================================
    -- １．ステータスチェック
    --==============================================================
    -- ステータスがNULLの場合
    IF ( chk_rec.status IS NULL ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10513;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- ２．同一顧客ステータスチェック１
    --==============================================================
    -- ①ステータスが取消の場合
    IF ( chk_rec.status = cv_status_c ) THEN
      -- 同一顧客ステータスチェックチェックカーソル
      SELECT COUNT(1)                 AS cnt     -- チェック件数
      INTO   ln_chk_cnt
      FROM   xxcok_tmp_001a06c_upload xt0u       -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.status     = cv_status_c       -- ステータス（取消）
      AND    xt0u.record_no <> chk_rec.record_no -- レコードNo
      AND    xt0u.cust_code  = chk_rec.cust_code -- 顧客コード
      ;
      -- 同一顧客で取消レコードが複数存在する場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- メッセージコードを設定して例外処理
        lv_message_code := cv_msg_xxcok_10522;
        RAISE global_chk_item_expt;
      END IF;
    -- ②ステータスが取消以外の場合
    ELSE
      -- 同一顧客ステータスチェックチェックカーソル
      SELECT COUNT(1)                 AS cnt     -- チェック件数
      INTO   ln_chk_cnt
      FROM   xxcok_tmp_001a06c_upload xt0u       -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.status    <> cv_status_c       -- ステータス（取消）
      AND    xt0u.record_no <> chk_rec.record_no -- レコードNo
      AND    xt0u.cust_code  = chk_rec.cust_code -- 顧客コード
      ;
      -- 同一顧客で取消以外のレコードが複数存在する場合
      IF ( ln_chk_cnt > 0 ) THEN
        -- メッセージコードを設定して例外処理
        lv_message_code := cv_msg_xxcok_10522;
        RAISE global_chk_item_expt;
      END IF;
      --
    END IF;
--
    --==============================================================
    -- ３．同一顧客ステータスチェック２
    --==============================================================
    -- 同一顧客ステータスチェックチェックカーソル
    SELECT COUNT(1)                 AS cnt                   -- チェック件数
    INTO   ln_chk_cnt
    FROM   xxcok_tmp_001a06c_upload xt0u                     -- 年次顧客移行情報csvアップロード一時表
    WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_w -- アップロード判定フラグ（警告）
    AND    xt0u.record_no         <> chk_rec.record_no       -- レコードNo
    AND    xt0u.cust_code          = chk_rec.cust_code       -- 顧客コード
    ;
    -- 同一顧客で既に警告レコードが存在する場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10521;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- ４．旧拠点コード、新拠点コード不一致チェック
    --==============================================================
    -- 旧拠点コードと新拠点コードが同一コードの場合
    IF ( chk_rec.prev_base_code = chk_rec.new_base_code ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10514;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- ５．顧客コード、旧拠点コードチェック
    --==============================================================
    BEGIN
      SELECT hca.customer_class_code AS customer_class_code           -- 顧客区分
           , xca.sale_base_code      AS sale_base_code                -- 売上拠点
      INTO   lv_customer_class_code
           , lv_sales_base_code
      FROM   hz_cust_accounts        hca                              -- 顧客マスタ
           , hz_parties              hp                               -- パーティ
           , xxcmm_cust_accounts     xca                              -- 顧客追加情報
      WHERE  hca.party_id            = hp.party_id                    -- パーティID
      AND    hca.cust_account_id     = xca.customer_id                -- 顧客ID
      AND (  hca.customer_class_code IN ( cv_customer_class_code_10
                                        , cv_customer_class_code_12
                                        , cv_customer_class_code_14
                                        , cv_customer_class_code_15 ) -- 顧客区分
        OR ( ( hca.customer_class_code IS NULL )                      -- 顧客区分
        AND  ( hp.duns_number_c = cv_cust_status_20 ) ) )             -- 顧客ステータス
      AND    hca.account_number      = chk_rec.cust_code              -- 顧客コード
      ;
    EXCEPTION
      -- ①取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- メッセージコードを設定して例外処理
        lv_message_code := cv_msg_xxcok_10523;
        RAISE global_chk_item_expt;
    END;
    --
    -- ②売上拠点が旧拠点コードと一致しない場合
    IF ( lv_sales_base_code <> chk_rec.prev_base_code ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10524;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- ６．新拠点コードチェック
    --==============================================================
    BEGIN
      SELECT xadv.aff_department_code AS aff_department_code -- 部門コード
           , xadv.start_date_active   AS start_date_active   -- 開始日
           , xadv.end_date_active     AS end_date_active     -- 終了日
      INTO   lv_aff_department_code
           , ld_start_date_active
           , ld_end_date_active
      FROM   xxcok_base_all_v         xbav                   -- 拠点ビュー
           , xxcok_aff_department_v   xadv                   -- 部門ビュー
      WHERE  xbav.base_code = xadv.aff_department_code(+)    -- 拠点コード
      AND    xbav.base_code = chk_rec.new_base_code          -- 拠点コード
      ;
    EXCEPTION
      -- ①取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- メッセージコードを設定して例外処理
        lv_message_code := cv_msg_xxcok_10525;
        RAISE global_chk_item_expt;
    END;
    --
    -- ①取得した部門コードがNULLの場合
    IF ( lv_aff_department_code IS NULL ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10525;
      RAISE global_chk_item_expt;
    END IF;
    --
    -- ②翌会計年度期首日が開始日～終了日の範囲内にない場合
    IF ( ( NVL( ld_start_date_active, gd_cust_shift_date ) > gd_cust_shift_date )
      OR ( NVL( ld_end_date_active, gd_cust_shift_date )   < gd_cust_shift_date ) ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10526;
      RAISE global_chk_item_expt;
    END IF;
--
    --==============================================================
    -- ７．確定済チェック、取消不可チェック
    --==============================================================
    -- ①顧客移行情報取得
    SELECT COUNT(1)              AS cnt              -- 存在チェック用件数
    INTO   ln_chk_cnt
    FROM   xxcok_cust_shift_info xcsi                -- 顧客移行情報
    WHERE  xcsi.cust_shift_date > gd_process_date    -- 顧客移行日＞業務日付
    AND    xcsi.cust_shift_date < gd_cust_shift_date -- 顧客移行日＜翌会計年度期首日
    AND    xcsi.status         <> cv_status_c        -- ステータス（取消）
    AND    xcsi.cust_code       = chk_rec.cust_code  -- 顧客コード
    ;
    -- 取得された場合
    IF ( ln_chk_cnt > 0 ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10518;
      RAISE global_chk_item_expt;
    END IF;
    -- 取得されない場合は継続
    -- ②翌会計年度期首日の顧客移行情報取得
    BEGIN
      SELECT xcsi1.cust_shift_id   AS cust_shift_id      -- 顧客移行情報ID
           , xcsi1.new_base_code   AS new_base_code      -- 新拠点コード
           , xcsi1.cust_shift_date AS cust_shift_date    -- 顧客移行日
           , xcsi1.status          AS status             -- ステータス
      INTO   ln_cust_shift_id
           , lv_new_base_code
           , ld_cust_shift_date
           , lv_status
      FROM   xxcok_cust_shift_info xcsi1                 -- 顧客移行情報
      WHERE  xcsi1.cust_shift_id = (
                                     SELECT MAX(xcsi2.cust_shift_id)
                                     FROM   xxcok_cust_shift_info xcsi2                -- 顧客移行情報
                                     WHERE  xcsi2.cust_shift_date = gd_cust_shift_date -- 顧客移行日＝翌会計年度期首日
                                     AND    xcsi2.cust_code       = chk_rec.cust_code  -- 顧客コード
                                   )
      ;
    EXCEPTION
      -- ③顧客移行情報が取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- Ⅰ．一時表のステータスが取消以外は継続
        -- Ⅱ．一時表のステータスが取消の場合
        IF ( chk_rec.status = cv_status_c ) THEN
          -- メッセージコードを設定して例外処理
          lv_message_code := cv_msg_xxcok_10519;
          RAISE global_chk_item_expt;
        END IF;
    END;
    --
    -- ④顧客移行情報のステータスが確定の場合
    IF ( lv_status = cv_status_a ) THEN
      -- メッセージコードを設定して例外処理
      lv_message_code := cv_msg_xxcok_10515;
      RAISE global_chk_item_expt;
    -- ⑤顧客移行情報のステータスが取消以外は継続
    -- ⑥顧客移行情報のステータスが取消の場合
    ELSIF ( lv_status = cv_status_c ) THEN
      -- Ⅰ．一時表のステータスが取消以外の場合は継続
      -- Ⅱ．一時表のステータスが取消の場合
      IF ( chk_rec.status = cv_status_c ) THEN
        -- メッセージコードを設定して例外処理
        lv_message_code := cv_msg_xxcok_10517;
        RAISE global_chk_item_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- ８．取込ファイル内チェック
    --==============================================================
    BEGIN
      SELECT xt0u.new_base_code      AS new_base_code      -- 新拠点コード
           , xt0u.status             AS status             -- ステータス
           , xt0u.upload_dicide_flag AS upload_dicide_flag -- アップロード判定フラグ
      INTO   lv_new_base_code
           , lv_status
           , lv_upload_dicide_flag
      FROM   xxcok_tmp_001a06c_upload xt0u                 -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.upload_dicide_flag IS NOT NULL           -- アップロード判定フラグ
      AND    xt0u.cust_code          = chk_rec.cust_code   -- 顧客コード
      ORDER BY
             xt0u.status -- ステータス
      ;
    EXCEPTION
      -- ①取得できない場合
      WHEN NO_DATA_FOUND THEN
        -- Ⅰ．顧客移行情報が取得できていない場合
        IF ( ln_cust_shift_id IS NULL ) THEN
          -- 初回登録：アップロード判定フラグ（一時表更新用）を登録として設定
          lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
          --
        -- Ⅱ． 顧客移行情報が登録済で新拠点コードが一致の場合
        ELSIF ( ( ln_cust_shift_id IS NOT NULL )
          AND   ( chk_rec.new_base_code = lv_new_base_code ) ) THEN
          -- 1. ステータスが不一致の場合
          IF ( chk_rec.status <> lv_status ) THEN
            -- ステータス更新：アップロード判定フラグ（一時表更新用）を更新として設定
            lv_upload_dicide_flag_upd := cv_upload_dicide_flag_u;
          -- 2. ステータスが一致の場合
          ELSE
            -- メッセージコードを設定して例外処理
            lv_message_code := cv_msg_xxcok_10516;
            RAISE global_chk_item_expt;
          END IF;
        -- Ⅲ．顧客移行情報が登録済で新拠点コードが不一致の場合
        ELSIF ( ( ln_cust_shift_id IS NOT NULL )
          AND   ( chk_rec.new_base_code <> lv_new_base_code ) ) THEN
          -- 1. ステータスが取消の場合
          IF ( lv_status = cv_status_c ) THEN
            -- 取消された顧客の登録：アップロード判定フラグ（一時表更新用）を登録として設定
            lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
          -- 2. ステータスが取消以外の場合
          ELSE
            -- メッセージコードを設定して例外処理
            lv_message_code := cv_msg_xxcok_10520;
            RAISE global_chk_item_expt;
          END IF;
          --
        END IF;
    END;
    -- アップロード判定フラグ（一時表更新用）が設定されている場合は継続
    IF ( lv_upload_dicide_flag_upd IS NULL ) THEN
      -- ②取得できたステータスが取消の場合
      IF ( lv_status = cv_status_c ) THEN
        -- 取消された顧客の登録：アップロード判定フラグ（一時表更新用）を登録として設定
        lv_upload_dicide_flag_upd := cv_upload_dicide_flag_i;
      -- ③ステータスが取消以外の場合
      ELSE
        -- ステータス更新：アップロード判定フラグ（一時表更新用）を更新として設定
        lv_upload_dicide_flag_upd := cv_upload_dicide_flag_u;
      END IF;
    END IF;
--
    --==============================================================
    -- ９．顧客移行情報ロック取得
    --==============================================================
    -- 更新の場合
    IF ( lv_upload_dicide_flag_upd = cv_upload_dicide_flag_u ) THEN
      BEGIN
        SELECT xcsi.cust_shift_id    AS dummy        -- 顧客移行情報ID
        INTO   ln_dummy
        FROM   xxcok_cust_shift_info xcsi            -- 顧客移行情報
        WHERE  xcsi.cust_shift_id = ln_cust_shift_id -- 顧客移行情報ID
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        -- 取得できない場合
        WHEN global_lock_expt THEN
          -- メッセージコードを設定して例外処理
          lv_message_code := cv_msg_xxcok_10511;
          RAISE global_chk_item_expt;
      END;
    END IF;
--
    --==============================================================
    -- １０．年次顧客移行情報csvアップロード一時表更新
    --==============================================================
    BEGIN
      UPDATE xxcok_tmp_001a06c_upload xt0u                        -- 年次顧客移行情報csvアップロード一時表
      SET    xt0u.cust_shift_id       = ln_cust_shift_id          -- 顧客移行情報ID
           , xt0u.customer_class_code = lv_customer_class_code    -- 顧客区分
           , xt0u.upload_dicide_flag  = lv_upload_dicide_flag_upd -- アップロード判定フラグ
           , xt0u.error_message       = NULL                      -- エラーメッセージ
      WHERE  xt0u.record_no           = chk_rec.record_no         -- レコードNo
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_10508 -- メッセージコード
                       , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                       , iv_token_value1 => iv_file_id         -- トークン値1
                       , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
--
  EXCEPTION
--
    -- 妥当性チェック例外ハンドラ
    WHEN global_chk_item_expt THEN
      -- ステータスが確定前
      IF ( chk_rec.status = cv_status_w ) THEN
        lv_err_status := gv_status_w;
      -- ステータスが入力中
      ELSIF ( chk_rec.status = cv_status_i ) THEN
        lv_err_status := gv_status_i;
      -- ステータスが取消
      ELSIF ( chk_rec.status = cv_status_c ) THEN
        lv_err_status := gv_status_c;
      -- ステータスが上記以外
      ELSE
        lv_err_status := NULL;
      END IF;
      --
      -- メッセージコードがAPP-XXCOK1-10513の場合
      IF ( lv_message_code = cv_msg_xxcok_10513 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application         -- アプリケーション短縮名
                       , iv_name         => lv_message_code        -- メッセージコード
                       , iv_token_name1  => cv_tkn_record_no       -- トークンコード1
                       , iv_token_value1 => chk_rec.record_no      -- トークン値1
                       , iv_token_name2  => cv_tkn_cust_code       -- トークンコード2
                       , iv_token_value2 => chk_rec.cust_code      -- トークン値2
                       , iv_token_name3  => cv_tkn_prev_base_code  -- トークンコード3
                       , iv_token_value3 => chk_rec.prev_base_code -- トークン値3
                       , iv_token_name4  => cv_tkn_new_base_code   -- トークンコード4
                       , iv_token_value4 => chk_rec.new_base_code  -- トークン値4
                     );
      -- メッセージコードがAPP-XXCOK1-10526の場合
      ELSIF ( lv_message_code = cv_msg_xxcok_10526 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application                             -- アプリケーション短縮名
                       , iv_name         => lv_message_code                            -- メッセージコード
                       , iv_token_name1  => cv_tkn_record_no                           -- トークンコード1
                       , iv_token_value1 => chk_rec.record_no                          -- トークン値1
                       , iv_token_name2  => cv_tkn_cust_code                           -- トークンコード2
                       , iv_token_value2 => chk_rec.cust_code                          -- トークン値2
                       , iv_token_name3  => cv_tkn_prev_base_code                      -- トークンコード3
                       , iv_token_value3 => chk_rec.prev_base_code                     -- トークン値3
                       , iv_token_name4  => cv_tkn_new_base_code                       -- トークンコード4
                       , iv_token_value4 => chk_rec.new_base_code                      -- トークン値4
                       , iv_token_name5  => cv_tkn_status                              -- トークンコード5
                       , iv_token_value5 => lv_err_status                              -- トークン値5
                       , iv_token_name6  => cv_tkn_new_base_code_from                  -- トークンコード6
                       , iv_token_value6 => TO_CHAR(ld_start_date_active, cv_yyyymmdd) -- トークン値6
                       , iv_token_name7  => cv_tkn_new_base_code_to                    -- トークンコード7
                       , iv_token_value7 => TO_CHAR(ld_end_date_active, cv_yyyymmdd)   -- トークン値7
                     );
      -- メッセージコードが上記以外の場合
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application         -- アプリケーション短縮名
                       , iv_name         => lv_message_code        -- メッセージコード
                       , iv_token_name1  => cv_tkn_record_no       -- トークンコード1
                       , iv_token_value1 => chk_rec.record_no      -- トークン値1
                       , iv_token_name2  => cv_tkn_cust_code       -- トークンコード2
                       , iv_token_value2 => chk_rec.cust_code      -- トークン値2
                       , iv_token_name3  => cv_tkn_prev_base_code  -- トークンコード3
                       , iv_token_value3 => chk_rec.prev_base_code -- トークン値3
                       , iv_token_name4  => cv_tkn_new_base_code   -- トークンコード4
                       , iv_token_value4 => chk_rec.new_base_code  -- トークン値4
                       , iv_token_name5  => cv_tkn_status          -- トークンコード5
                       , iv_token_value5 => lv_err_status          -- トークン値5
                     );
      END IF;
      -- 警告件数設定
      gn_warn_cnt := gn_warn_cnt + 1;
      --==============================================================
      -- １０．年次顧客移行情報csvアップロード一時表更新（チェックエラー時）
      --==============================================================
      BEGIN
        UPDATE xxcok_tmp_001a06c_upload xt0u                      -- 年次顧客移行情報csvアップロード一時表
        SET    xt0u.cust_shift_id       = ln_cust_shift_id        -- 顧客移行情報ID
             , xt0u.customer_class_code = lv_customer_class_code  -- 顧客区分
             , xt0u.upload_dicide_flag  = cv_upload_dicide_flag_w -- アップロード判定フラグ
             , xt0u.error_message       = lv_errmsg               -- エラーメッセージ
        WHERE  xt0u.record_no           = chk_rec.record_no       -- レコードNo
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application     -- アプリケーション短縮名
                          , iv_name         => cv_msg_xxcok_10508 -- メッセージコード
                          , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                          , iv_token_value1 => iv_file_id         -- トークン値1
                          , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                          , iv_token_value2 => SQLERRM            -- トークン値2
                        );
          lv_errbuf  := lv_errmsg;
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_shift_info
   * Description      : 顧客移行情報一括登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE ins_cust_shift_info(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_shift_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    --==============================================================
    -- 一括登録処理
    --==============================================================
    BEGIN
      INSERT INTO xxcok_cust_shift_info(
          cust_shift_id          -- 顧客移行情報ID
        , cust_code              -- 顧客コード
        , prev_base_code         -- 旧拠点コード
        , new_base_code          -- 新拠点コード
        , cust_shift_date        -- 顧客移行日
        , target_acctg_year      -- 対象会計年度
        , emp_code               -- 入力者
        , input_date             -- 入力日
        , status                 -- ステータス
        , shift_type             -- 移行区分
        , create_chg_je_flag     -- 釣銭仕訳作成フラグ
        , org_slip_number        -- 元伝票番号
        , vd_inv_trnsfr_status   -- VD在庫保管場所転送ステータス
        , base_split_flag        -- 拠点分割情報連携フラグ
        , business_vd_if_flag    -- 営業自販機連携フラグ
        , business_fa_if_flag    -- 営業FA連携フラグ
        , created_by             -- 作成者
        , creation_date          -- 作成日
        , last_updated_by        -- 最終更新者
        , last_update_date       -- 最終更新日
        , last_update_login      -- 最終更新ログイン
        , request_id             -- 要求ID
        , program_application_id -- プログラムアプリケーションID
        , program_id             -- プログラムID
        , program_update_date    -- プログラム更新日
      )
      SELECT
             xxcok_cust_shift_info_s01.NEXTVAL AS cust_shift_id          -- 顧客移行情報ID
           , xt0u.cust_code                    AS cust_code              -- 顧客コード
           , xt0u.prev_base_code               AS prev_base_code         -- 旧拠点コード
           , xt0u.new_base_code                AS new_base_code          -- 新拠点コード
           , gd_cust_shift_date                AS cust_shift_date        -- 顧客移行日
           , gn_target_acctg_year              AS target_acctg_year      -- 対象会計年度
           , gv_employee_code                  AS emp_code               -- 入力者
           , SYSDATE                           AS input_date             -- 入力日
           , xt0u.status                       AS status                 -- ステータス
           , cv_shift_type_1                   AS shift_type             -- 移行区分
           , CASE WHEN xt0u.customer_class_code IN ( cv_customer_class_code_12, cv_customer_class_code_14 )
                  THEN cv_create_chg_je_flag_2
                  ELSE cv_create_chg_je_flag_0
             END                               AS create_chg_je_flag     -- 釣銭仕訳作成フラグ
           , NULL                              AS org_slip_number        -- 元伝票番号
           , CASE WHEN xt0u.customer_class_code IN ( cv_customer_class_code_12, cv_customer_class_code_14 )
                  THEN cv_vd_inv_trnsfr_status_3
                  ELSE cv_vd_inv_trnsfr_status_0
             END                               AS vd_inv_trnsfr_status   -- VD在庫保管場所転送ステータス
           , NULL                              AS base_split_flag        -- 拠点分割情報連携フラグ
           , cv_business_vd_if_flag_0          AS business_vd_if_flag    -- 営業自販機連携フラグ
           , cv_business_fa_if_flag_0          AS business_fa_if_flag    -- 営業FA連携フラグ
           , cn_created_by                     AS created_by             -- 作成者
           , cd_creation_date                  AS creation_date          -- 作成日
           , cn_last_updated_by                AS last_updated_by        -- 最終更新者
           , cd_last_update_date               AS last_update_date       -- 最終更新日
           , cn_last_update_login              AS last_update_login      -- 最終更新ログイン
           , cn_request_id                     AS request_id             -- 要求ID
           , cn_program_application_id         AS program_application_id -- プログラムアプリケーションID
           , cn_program_id                     AS program_id             -- プログラムID
           , cd_program_update_date            AS program_update_date    -- プログラム更新日
      FROM   xxcok_tmp_001a06c_upload          xt0u                      -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_i           -- アップロード判定フラグ
      ;
      -- 登録件数設定
      gn_ins_cnt := SQL%ROWCOUNT;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_10509 -- メッセージコード
                       , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                       , iv_token_value1 => iv_file_id         -- トークン値1
                       , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_cust_shift_info
   * Description      : 顧客移行情報一括更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE upd_cust_shift_info(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_cust_shift_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_cnt                    NUMBER DEFAULT 0; -- ループ用件数
    --
    -- *** ローカルカーソル ***
    -- 更新対象取得カーソル
    CURSOR upd_data_cur
    IS
      SELECT xt0u.cust_shift_id       AS cust_shift_id         -- 顧客移行情報ID
           , xt0u.status              AS status                -- ステータス
      FROM   xxcok_tmp_001a06c_upload xt0u                     -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_u -- アップロード判定フラグ
    ;
    -- レコード定義
    upd_data_rec              upd_data_cur%ROWTYPE;
    --
    -- テーブルタイプ
    TYPE l_cust_shift_id_ttype IS TABLE OF xxcok_cust_shift_info.cust_shift_id%TYPE INDEX BY PLS_INTEGER;
    TYPE l_status_ttype        IS TABLE OF xxcok_cust_shift_info.status%TYPE        INDEX BY PLS_INTEGER;
    l_cust_shift_id_tab        l_cust_shift_id_ttype;
    l_status_tab               l_status_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- １．更新対象取得処理
    --==============================================================
    -- カーソルオープン
    OPEN upd_data_cur;
    -- 妥当性チェックループ
    << upd_data_loop >>
    LOOP
      -- フェッチ
      FETCH upd_data_cur INTO upd_data_rec;
      EXIT WHEN upd_data_cur%NOTFOUND;
      --
      ln_cnt := ln_cnt + 1;
      -- 更新データ設定
      l_cust_shift_id_tab(ln_cnt) := upd_data_rec.cust_shift_id;
      l_status_tab(ln_cnt)        := upd_data_rec.status;
      -- 更新件数設定
      IF ( l_status_tab(ln_cnt) = cv_status_i ) THEN
        gn_upd_cnt_i := gn_upd_cnt_i + 1;
      ELSIF ( l_status_tab(ln_cnt) = cv_status_w ) THEN
        gn_upd_cnt_w := gn_upd_cnt_w + 1;
      ELSIF ( l_status_tab(ln_cnt) = cv_status_c ) THEN
        gn_upd_cnt_c := gn_upd_cnt_c + 1;
      END IF;
    --
    END LOOP upd_data_loop;
    -- カーソルクローズ
    CLOSE upd_data_cur;
--
    --==============================================================
    -- ２．一括更新処理
    --==============================================================
    -- 更新データが存在する場合
    IF ( ln_cnt > 0 ) THEN
      BEGIN
        FORALL ln_cnt IN l_cust_shift_id_tab.FIRST .. l_cust_shift_id_tab.COUNT
          UPDATE xxcok_cust_shift_info  xcsi
          SET    xcsi.emp_code               = gv_employee_code            -- 入力者
               , xcsi.input_date             = SYSDATE                     -- 入力日
               , xcsi.status                 = l_status_tab(ln_cnt)        -- ステータス
               , xcsi.last_updated_by        = cn_last_updated_by          -- 最終更新者
               , xcsi.last_update_date       = cd_last_update_date         -- 最終更新日
               , xcsi.last_update_login      = cn_last_update_login        -- 最終更新ログイン
               , xcsi.request_id             = cn_request_id               -- 要求ID
               , xcsi.program_application_id = cn_program_application_id   -- プログラムアプリケーションID
               , xcsi.program_id             = cn_program_id               -- プログラムID
               , xcsi.program_update_date    = cd_program_update_date      -- プログラム更新日
          WHERE  xcsi.cust_shift_id          = l_cust_shift_id_tab(ln_cnt) -- 顧客移行情報
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcok_10510 -- メッセージコード
                         , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                         , iv_token_value1 => iv_file_id         -- トークン値1
                         , iv_token_name2  => cv_tkn_errmsg      -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( upd_data_cur%ISOPEN ) THEN
        CLOSE upd_data_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END upd_cust_shift_info;
--
  /**********************************************************************************
   * Procedure Name   : out_error_message
   * Description      : エラーメッセージ出力処理(A-8)
   ***********************************************************************************/
  PROCEDURE out_error_message(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_error_message'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカルカーソル ***
    -- エラーメッセージカーソル
    CURSOR out_err_msg_cur
    IS
      SELECT xt0u.record_no           AS record_no             -- レコードNo
           , xt0u.error_message       AS error_message         -- エラーメッセージ
      FROM   xxcok_tmp_001a06c_upload xt0u                     -- 年次顧客移行情報csvアップロード一時表
      WHERE  xt0u.upload_dicide_flag = cv_upload_dicide_flag_w -- アップロード判定フラグ
      ORDER BY
             xt0u.record_no
    ;
    --
    -- レコード定義
    out_err_msg_rec           out_err_msg_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- エラーメッセージ出力処理
    --==============================================================
    -- オープン
    OPEN out_err_msg_cur;
    -- エラーメッセージ出力ループ
    << out_loop >>
    LOOP
      -- フェッチ
      FETCH out_err_msg_cur INTO out_err_msg_rec;
      EXIT WHEN out_err_msg_cur%NOTFOUND;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => out_err_msg_rec.error_message
      );
    END LOOP out_loop;
    -- クローズ
    CLOSE out_err_msg_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( out_err_msg_cur%ISOPEN ) THEN
        CLOSE out_err_msg_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END out_error_message;
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : ファイルアップロードデータ削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
      iv_file_id IN  VARCHAR2 -- ファイルID
    , ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    --==============================================================
    -- ファイルアップロード削除
    --==============================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui     -- ファイルアップロードIFテーブル
      WHERE       xmfui.file_id = TO_NUMBER(iv_file_id) -- ファイルID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcok_00062 -- メッセージコード
                       , iv_token_name1  => cv_tkn_file_id     -- トークンコード1
                       , iv_token_value1 => iv_file_id         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    , ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    , ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
    , iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマット
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_ins_cnt     := 0;
    gn_upd_cnt_i   := 0;
    gn_upd_cnt_w   := 0;
    gn_upd_cnt_c   := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
        iv_file_id => iv_file_id -- ファイルID
      , iv_format  => iv_format  -- フォーマット
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードデータ取得処理(A-2)
    -- ===============================================
    get_file_upload_data(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 年次顧客移行情報csvアップロード一時表登録ループ
    << ins_tmp_loop >>
    FOR i IN gt_file_data_all.FIRST .. gt_file_data_all.COUNT LOOP
      -- ===============================================
      -- ファイルアップロードデータ変換処理(A-3)
      -- ===============================================
      conv_file_upload_data(
          iv_file_id => iv_file_id -- ファイルID
        , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 登録対象レコードフラグがONの場合のみ登録
      IF ( gb_ins_record_flg = TRUE ) THEN
        -- ===============================================
        -- 年次顧客移行情報csvアップロード一時表登録処理(A-4)
        -- ===============================================
        ins_tmp_001a06c_upload(
            iv_file_id => iv_file_id -- ファイルID
          , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
          , ov_retcode => lv_retcode -- リターン・コード
          , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      --
    END LOOP ins_tmp_loop;
--
    -- カーソルオープン
    OPEN chk_cur;
    -- 妥当性チェックループ
    << chk_validate_loop >>
    LOOP
      -- フェッチ
      FETCH chk_cur INTO chk_rec;
      EXIT WHEN chk_cur%NOTFOUND;
      -- ===============================================
      -- 妥当性チェック処理(A-5)
      -- ===============================================
      chk_validate_item(
          iv_file_id => iv_file_id -- ファイルID
        , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
        , ov_retcode => lv_retcode -- リターン・コード
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP chk_validate_loop;
    -- カーソルクローズ
    CLOSE chk_cur;
--
    -- ===============================================
    -- 顧客移行情報一括登録処理(A-6)
    -- ===============================================
    ins_cust_shift_info(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 顧客移行情報一括更新処理(A-7)
    -- ===============================================
    upd_cust_shift_info(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- エラーメッセージ出力処理(A-8)
    -- ===============================================
    out_error_message(
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
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
      IF ( chk_cur%ISOPEN ) THEN
        CLOSE chk_cur;
      END IF;
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
      errbuf     OUT VARCHAR2 -- エラー・メッセージ #固定#
    , retcode    OUT VARCHAR2 -- リターン・コード   #固定#
    , iv_file_id IN  VARCHAR2 -- ファイルID
    , iv_format  IN  VARCHAR2 -- フォーマット
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
    -- アプリケーション短縮名
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    -- メッセージ
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_msg_xxcok_10530 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10530'; -- 登録件数メッセージ
    cv_msg_xxcok_10531 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10531'; -- 更新件数（ステータス：入力中）メッセージ
    cv_msg_xxcok_10532 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10532'; -- 更新件数（ステータス：確定前）メッセージ
    cv_msg_xxcok_10533 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10533'; -- 更新件数（ステータス：取消）メッセージ
    cv_msg_xxcok_10534 CONSTANT VARCHAR2(16)  := 'APP-XXCOK1-10534'; -- 警告件数メッセージ
    -- トークン
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
--
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
        ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      , iv_file_id => iv_file_id -- ファイルID
      , iv_format  => iv_format  -- フォーマット
    );
--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- ファイルアップロードデータ削除処理(A-9)
    -- ===============================================
    del_file_upload_data(
        iv_file_id => iv_file_id -- ファイルID
      , ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      , ov_retcode => lv_retcode -- リターン・コード
      , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- エラー時のROLLBACK
      ROLLBACK;
      -- エラー件数設定
      gn_error_cnt := 1;
    END IF;
    -- ファイルアップロードデータ削除後のCOMMIT
    COMMIT;
--
    -- エラー件数が存在する場合
    IF ( gn_error_cnt > 0 ) THEN
      -- エラー時の件数設定
      gn_target_cnt := 0;
      gn_ins_cnt    := 0;
      gn_upd_cnt_i  := 0;
      gn_upd_cnt_w  := 0;
      gn_upd_cnt_c  := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
      -- 終了ステータスをエラーにする
      lv_retcode := cv_status_error;
    -- エラー以外で警告件数が存在する場合
    ELSIF ( ( gn_error_cnt = 0 ) AND ( gn_warn_cnt > 0 ) ) THEN
      -- 終了ステータスを警告にする
      lv_retcode := cv_status_warn;
    -- エラー件数、警告件数が存在しない場合
    ELSIF ( ( gn_error_cnt = 0 ) AND ( gn_warn_cnt = 0 ) ) THEN
      -- 終了ステータスを正常にする
      lv_retcode := cv_status_normal;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- 対象件数出力
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
    -- 登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10530
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ins_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 更新件数（ステータス：入力中）出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10531
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_i)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 更新件数（ステータス：確定前）出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10532
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_w)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 更新件数（ステータス：取消）出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10533
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_upd_cnt_c)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- 警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_xxcok_10534
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- エラー件数出力
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
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
END XXCOK001A06C;
/
