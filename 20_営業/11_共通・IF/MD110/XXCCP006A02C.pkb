CREATE OR REPLACE PACKAGE BODY XXCCP006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A02C(body)
 * Description      : 動的パラメータコンカレント対応
 * MD.050           : 動的パラメータコンカレント対応 MD050_CCP_006_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_profile_name       プロファイル名取得プロシージャ
 *  last                   終了処理
 *  get_format_info        フォーマット情報取得
 *  submit_concurrent      コンカレント起動処理
 *  edit_param_processdate パラメータ編集処理(processdate!)
 *  edit_param_asterisk    パラメータ編集処理(*)
 *  edit_param_time        パラメータ編集処理(デフォルトタイプ：現在時刻)
 *  edit_param_date        パラメータ編集処理(デフォルトタイプ：現在日)
 *  edit_param_sql         パラメータ編集処理(デフォルトタイプ：SQL文)
 *  get_edit_param_info    動的パラメータ値算出処理
 *  init                   初期処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2009/01/13     1.0  Masakazu Yamashita  main新規作成
 *  2009/03/10     1.1  Masayuki.Sano       結合テスト動作不正対応
 *                                          ・メッセージ表示不正対応
 *                                          ・コンカレントの起動パラメータ98以上時の処理変更
 *                                          ・*DEFAULT*時の処理追加
 *                                          ・$FLEX$の対応
 *                                          ・取得したWHERE句の先頭が"WHERE "で始まる場合、
 *                                            "WHERE "を削除
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP006A02C'; -- パッケージ名
--
  -- システム日付
  cd_sysdate       CONSTANT DATE := SYSDATE;
--
  ------------------------------
  -- メッセージ関連
  ------------------------------
  -- メッセージコード
  cv_application                 CONSTANT VARCHAR2(10) := 'XXCCP';                   -- アドオン：共通・IF領域
-- 2009/03/10 UPDATE START
--  cv_msg_app_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10002';        -- アプリケーション短縮名メッセージ出力
--  cv_msg_prg_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10003';        -- コンカレント短縮名メッセージ出力
--  cv_msg_param                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10005';        -- 引数メッセージ出力
--  cv_msg_target_req              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10006';        -- 起動対象要求IDメッセージ出力
  cv_msg_app_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00002';        -- アプリケーション短縮名メッセージ出力
  cv_msg_prg_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00003';        -- コンカレント短縮名メッセージ出力
  cv_msg_param                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00005';        -- 引数メッセージ出力
  cv_msg_target_req              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00006';        -- 起動対象要求IDメッセージ出力
-- 2009/03/10 UPDATE END
  cv_msg_target_status_abnormal  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10026';        -- コンカレントステータス異常終了
  cv_msg_target_status_err       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10028';        -- コンカレントエラー終了
  cv_msg_target_status_warning   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10030';        -- コンカレントエラー終了
  cv_msg_concurrent_fail         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10022';        -- 起動対象コンカレントの起動失敗エラー
  cv_msg_concurrent_status_fail  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10023';        -- コンカレントステータス取得失敗エラー
  cv_msg_no_data_value_set       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10035';        -- 表検証の値失敗メッセージ
  cv_msg_too_many_value_set      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10036';        -- 表検証の値複数件メッセージ
  cv_msg_no_data_default_value   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10033';        -- デフォルト値０件メッセージ
  cv_msg_too_many_default_value  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10034';        -- デフォルト値複数件メッセージ
  cv_msg_param_not_found         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10038';        -- パラメータ0個エラー
-- 2009/03/10 ADD START
  cv_msg_param_max_over          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10059';        -- パラメータ制限数超過エラーメッセージ
-- 2009/03/10 ADD END
  cv_msg_app_name_err            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10020';        -- アプリケーション未入力エラー
  cv_msg_prg_name_err            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10021';        -- コンカレント未入力エラー
  cv_msg_no_found_profile        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10032';        -- プロファイル取得エラーメッセージ2
  cv_msg_no_format_data          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10058';        -- デフォルトタイプ：現在日・現在時刻の日付書式取得エラー
  cv_msg_target_rec              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';        -- 対象件数メッセージ
  cv_msg_success_rec             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';        -- 成功件数メッセージ
  cv_msg_error_rec               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';        -- エラー件数メッセージ
  cv_msg_warn_rec                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00001';        -- 警告件数メッセージ
  cv_msg_normal                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';        -- 正常終了メッセージ
  cv_msg_warn                    CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';        -- 警告終了メッセージ
  cv_msg_error                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10008';        -- エラー終了メッセージ
  -- メッセージトークン
  cv_msg_tkn1                    CONSTANT VARCHAR2(20) := 'COLUMN_SEQ_NUM';
  cv_msg_tkn2                    CONSTANT VARCHAR2(20) := 'DYNAM_SQL';
  cv_msg_tkn3                    CONSTANT VARCHAR2(20) := 'REQ_ID';
  cv_msg_tkn4                    CONSTANT VARCHAR2(20) := 'PHASE';
  cv_msg_tkn5                    CONSTANT VARCHAR2(20) := 'STATUS';
  cv_msg_tkn6                    CONSTANT VARCHAR2(20) := 'PROFILE_NAME';
  cv_msg_tkn7                    CONSTANT VARCHAR2(20) := 'NUMBER';
  cv_msg_tkn8                    CONSTANT VARCHAR2(20) := 'PARAM_VALUE';
  cv_msg_tkn9                    CONSTANT VARCHAR2(20) := 'AP_SHORT_NAME';
  cv_msg_tkn10                   CONSTANT VARCHAR2(20) := 'CONC_SHORT_NAME';
  cv_msg_cnt_token               CONSTANT VARCHAR2(20) := 'COUNT';
  ------------------------------
  -- コンカレント待機関数ステータス
  ------------------------------
  cv_phase_complete              CONSTANT VARCHAR2(20) := 'COMPLETE';                -- フェーズ：完了
  cv_phase_normal                CONSTANT VARCHAR2(20) := 'NORMAL';                  -- フェーズ：正常
  cv_phase_error                 CONSTANT VARCHAR2(20) := 'ERROR';                   -- フェーズ：エラー
  cv_phase_warning               CONSTANT VARCHAR2(20) := 'WARNING';                 -- フェーズ：警告
  ------------------------------
  -- 入力パラメータ値
  ------------------------------
  cv_default                     CONSTANT VARCHAR2(20) := 'DEFAULT';
  cv_datetime                    CONSTANT VARCHAR2(20) := 'DATETIME';
  cv_date                        CONSTANT VARCHAR2(20) := 'DATE';
  cv_time                        CONSTANT VARCHAR2(20) := 'TIME';
  cv_asterisk                    CONSTANT VARCHAR2(20)  := '*';
  cv_processdate                 CONSTANT VARCHAR2(20) := 'PROCESSDATE!';
  ------------------------------
  -- デフォルトタイプ
  ------------------------------
  cv_default_type_sql            CONSTANT VARCHAR2(20) := 'S';                       -- SQL文
  cv_default_type_pro            CONSTANT VARCHAR2(20) := 'P';                       -- プロファイル
  cv_default_type_date           CONSTANT VARCHAR2(20) := 'D';                       -- 現在日
  cv_default_type_time           CONSTANT VARCHAR2(20) := 'T';                       -- 現在時刻
  ------------------------------
  -- プロファイル名
  ------------------------------
  -- XXCCP:動的パラメータコンカレントステータス監視間隔
  cv_profile_watch_time          CONSTANT VARCHAR2(30) := 'XXCCP1_DYNAM_CONC_WATCH_TIME';
  ------------------------------
  -- 固定文字
  ------------------------------
  cv_profile                     CONSTANT VARCHAR2(20) := ':$PROFILES$.';
  cv_srs                         CONSTANT VARCHAR2(20) := '$SRS$.';
-- 2009/03/10 ADD START
  cv_flex                        CONSTANT VARCHAR2(20) := ':$FLEX$.';
  cv_single_quote                CONSTANT VARCHAR2(2)  := '''';
-- 2009/03/10 ADD END
  ------------------------------
  -- 書式タイプ
  ------------------------------
  cv_format_type_y               CONSTANT VARCHAR2(1) := 'Y';                        -- 標準日時
  cv_format_type_x               CONSTANT VARCHAR2(1) := 'X';                        -- 標準日
  cv_format_type_d               CONSTANT VARCHAR2(1) := 'D';                        -- 日付
  cv_format_type_t               CONSTANT VARCHAR2(1) := 'T';                        -- 日時
  cv_format_type_i               CONSTANT VARCHAR2(1) := 'I';                        -- 時刻
  cv_format_type_c               CONSTANT VARCHAR2(1) := 'C';                        -- 文字
  ------------------------------
  -- 日付書式
  ------------------------------
  cv_format1                     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_format2                     CONSTANT VARCHAR2(30) := 'DD-MON-YYYY HH24:MI:SS';
  cv_format3                     CONSTANT VARCHAR2(30) := 'DD-MON-RR HH24:MI:SS';
  cv_format4                     CONSTANT VARCHAR2(30) := 'DD-MON-YYYY HH24:MI';
  cv_format5                     CONSTANT VARCHAR2(30) := 'DD-MON-RR HH24:MI';
  cv_format6                     CONSTANT VARCHAR2(30) := 'HH24:MI:SS';
  cv_format7                     CONSTANT VARCHAR2(30) := 'HH24:MI';
  cv_format8                     CONSTANT VARCHAR2(30) := 'HH:MI:SS';
  cv_format9                     CONSTANT VARCHAR2(30) := 'HH:MI';
  cv_format10                    CONSTANT VARCHAR2(30) := 'DD-MON-YYYY';
  cv_format11                    CONSTANT VARCHAR2(30) := 'DD-MON-RR';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_args_info_ttype IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER ;        -- 入力パラメータ
  TYPE g_edit_param_info_ttype IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER ;  -- 編集後パラメータ
-- 2009/03/10 ADD START
  TYPE g_param_info_rtype IS RECORD(
     default_type          fnd_descr_flex_col_usage_vl.default_type%TYPE          -- デフォルトタイプ
    ,default_value         fnd_descr_flex_col_usage_vl.default_value%TYPE         -- デフォルト値
    ,set_id                fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE     -- 値セットID
    ,seq_num               fnd_descr_flex_col_usage_vl.column_seq_num%TYPE        -- 順序
    ,flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE           -- 値セット名
  ) ;
  TYPE g_param_info_ttype IS TABLE OF g_param_info_rtype INDEX BY BINARY_INTEGER ;
-- 2009/03/10 ADD END
--
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_target_req_id NUMBER DEFAULT NULL;
--
-- 2009/03/10 ADD START
  /**********************************************************************************
   * Procedure Name   : replace_data
   * Description      : 共通処理：置換処理（$FLEX$用）
  ***********************************************************************************/
  PROCEDURE replace_data(
    iv_before_data           IN  VARCHAR2,                            -- 1.置換前の文字列
    iv_search_val            IN  VARCHAR2,                            -- 2.検索文字列
    iv_replace_val           IN  VARCHAR2,                            -- 3.置換文字列
    ov_after_data            OUT VARCHAR2,                            -- 4.置換後の文字列
    ov_errbuf                OUT VARCHAR2,                            -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                            -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_data'; -- プログラム名
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
    cv_underscore               CONSTANT VARCHAR2(1) := '_';          -- アンダースコア
    cv_space                    CONSTANT VARCHAR2(1) := ' ';          -- 半角スペース
--
    -- *** ローカル変数 ***
    lv_rep_value_tmp            VARCHAR2(5000);                       -- 置換対象の文字列(一時格納用)
    lv_rep_idx                  NUMBER;                               -- 置換開始位置
    lv_rep_next_char            VARCHAR2(1);                          -- 置換対象の次の文字
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期設定
    lv_rep_idx       := 1;
    lv_rep_value_tmp := iv_before_data;
--
    -- 置換処理
    <<replace_loop>>
    WHILE ( INSTRB(lv_rep_value_tmp, iv_search_val, lv_rep_idx) > 0 ) LOOP
      -- 1) ":$FLEX$.<値セット名>"の位置を取得する。
      lv_rep_idx       := INSTRB(lv_rep_value_tmp, iv_search_val, lv_rep_idx);
--
      -- 2) ":$FLEX$.<値セット名>"の位置の次の文字を取得
      lv_rep_next_char := NVL(SUBSTRB(lv_rep_value_tmp, lv_rep_idx + LENGTHB(iv_search_val), 1), cv_space);
--
      -- 3) 入力パラメータへ置換する。(条件：":$FLEX$.<値セット名>"の位置の次の文字＝半角英数,'_'以外)
      IF ( NOT ( xxccp_common_pkg.chk_alphabet_number_only(lv_rep_next_char) OR lv_rep_next_char = cv_underscore ) ) THEN
        lv_rep_value_tmp :=   SUBSTRB(lv_rep_value_tmp, 1 ,lv_rep_idx - 1) 
                           || iv_replace_val
                           || SUBSTRB(lv_rep_value_tmp, lv_rep_idx + LENGTHB(iv_search_val));
      END IF;
--
      -- 4) 位置を+1する
      lv_rep_idx := lv_rep_idx + 1;
    END LOOP replace_loop;
--
    -- 置換結果を出力先に格納
    ov_after_data := lv_rep_value_tmp;
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
  END replace_data;
-- 2009/03/10 ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_profile_name
   * Description      : プロファイル名称取得処理
  ***********************************************************************************/
  PROCEDURE get_profile_name(
    iv_value                 IN  VARCHAR2,                                           -- 1.入力値
    ov_value                 OUT VARCHAR2,                                           -- 2.返却値
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_name'; -- プログラム名
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
    ln_position   NUMBER DEFAULT 0;
    lv_value_wk   VARCHAR2(2000) DEFAULT NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ln_position := INSTR(iv_value, cv_profile);
--
    lv_value_wk := SUBSTR(REPLACE(iv_value, CHR(10), ' '), ln_position + LENGTH(cv_profile));
    ov_value := RTRIM(SUBSTR(lv_value_wk, 1, INSTR(lv_value_wk, ' ') - 1), ')');
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
  END get_profile_name;
--
  /**********************************************************************************
   * Procedure Name   : last
   * Description      : 終了処理
   ***********************************************************************************/
  PROCEDURE last(
    iv_app_name              IN  VARCHAR2,                                           -- 1.起動対象アプリケーション短縮名
    iv_prg_name              IN  VARCHAR2,                                           -- 2.起動対象コンカレント短縮名
    in_target_param_cnt      IN  NUMBER,                                             -- 3.起動対象コンカレントパラメータ数
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 4.編集後パラメータ
    iv_errbuf                IN  VARCHAR2,                                           -- 5.エラー・メッセージ
    iv_retcode               IN  VARCHAR2,                                           -- 6.リターン・コード
    iv_errmsg                IN  VARCHAR2,                                           -- 7.ユーザー・エラー・メッセージ
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'last'; -- プログラム名
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
    lv_message_code    VARCHAR2(100) DEFAULT NULL;   -- 終了メッセージコード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- パラメータ出力
    ------------------------------
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --アプリケーション短縮名メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_app_name
                    ,iv_token_name1  => cv_msg_tkn9
                    ,iv_token_value1 => iv_app_name);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --コンカレント短縮名メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_prg_name
                    ,iv_token_name1  => cv_msg_tkn10
                    ,iv_token_value1 => iv_prg_name);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --引数メッセージ出力
    IF ( in_target_param_cnt > 0 ) THEN
      <<param_cnt_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_param
                        ,iv_token_name1  => cv_msg_tkn7
                        ,iv_token_value1 => TO_CHAR(i)
                        ,iv_token_name2  => cv_msg_tkn8
                        ,iv_token_value2 => i_edit_param_info_tab(i));
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
      END LOOP param_cnt_loop;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    ------------------------------
    -- 起動対象要求ID出力
    ------------------------------
    --起動対象要求IDメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_target_req
                    ,iv_token_name1  => cv_msg_tkn3
                    ,iv_token_value1 => gn_target_req_id);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    ------------------------------
    -- エラー詳細出力
    ------------------------------
    --エラー出力
    IF ( iv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => iv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    ------------------------------
    -- 処理件数出力
    ------------------------------
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_target_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_success_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_error_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_warn_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (iv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_normal;
    ELSIF(iv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_warn;
    ELSIF(iv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_error;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    ov_retcode := iv_retcode;
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
  END last;
--
  /**********************************************************************************
   * Procedure Name   : get_format_info
   * Description      : 書式情報取得
   ***********************************************************************************/
  PROCEDURE get_format_info(
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 1.値セットID
    ot_format_type           OUT fnd_flex_value_sets.format_type%TYPE,               -- 2.書式タイプ
    ot_maximum_size          OUT fnd_flex_value_sets.maximum_size%TYPE,              -- 3.最大サイズ
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_format_info'; -- プログラム名
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
    -- 書式情報の取得
    SELECT ffvs.format_type        AS format_type
          ,ffvs.maximum_size       AS maximum_size
    INTO   ot_format_type
          ,ot_maximum_size
    FROM   fnd_flex_value_sets     ffvs
    WHERE  ffvs.flex_value_set_id  = it_set_id
    ;
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
  END get_format_info;
--
  /**********************************************************************************
   * Procedure Name   : submit_concurrent
   * Description      : コンカレント起動処理
   ***********************************************************************************/
  PROCEDURE submit_concurrent(
    iv_application           IN  VARCHAR2,                                           -- 1.起動対象アプリケーション短縮名
    iv_program               IN  VARCHAR2,                                           -- 2.起動対象コンカレント短縮名
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 3.編集後パラメータ
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_concurrent'; -- プログラム名
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
    ln_req_id                NUMBER DEFAULT 0 ;          -- 要求ID
    lb_complete              BOOLEAN;
    lv_phase                 VARCHAR2(30) DEFAULT NULL;
    lv_status                VARCHAR2(30) DEFAULT NULL;
    lv_dev_phase             VARCHAR2(30) DEFAULT NULL;
    lv_dev_status            VARCHAR2(30) DEFAULT NULL;
    lv_message               VARCHAR2(30) DEFAULT NULL;
--
    lv_watch_time            VARCHAR2(255) DEFAULT NULL;
    -- *** ローカル・例外処理 ***
    submit_err_expt          EXCEPTION;
    submit_warn_expt         EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 動的パラメータコンカレントステータス監視間隔の取得
    lv_watch_time := FND_PROFILE.VALUE(cv_profile_watch_time);
--
    IF ( lv_watch_time IS NULL ) THEN
      -- プロファイル取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_application,
                   iv_name        => cv_msg_no_found_profile,
                   iv_token_name1  => cv_msg_tkn6,
                   iv_token_value1 => cv_profile_watch_time);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    END IF;
--
    -- コンカレント発行
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                   application => iv_application,
                   program     => iv_program,
                   description => NULL,
                   start_time  => NULL,
                   sub_request => NULL,
                   argument1   => i_edit_param_info_tab(1),
                   argument2   => i_edit_param_info_tab(2),
                   argument3   => i_edit_param_info_tab(3),
                   argument4   => i_edit_param_info_tab(4),
                   argument5   => i_edit_param_info_tab(5),
                   argument6   => i_edit_param_info_tab(6),
                   argument7   => i_edit_param_info_tab(7),
                   argument8   => i_edit_param_info_tab(8),
                   argument9   => i_edit_param_info_tab(9),
                   argument10  => i_edit_param_info_tab(10),
                   argument11  => i_edit_param_info_tab(11),
                   argument12  => i_edit_param_info_tab(12),
                   argument13  => i_edit_param_info_tab(13),
                   argument14  => i_edit_param_info_tab(14),
                   argument15  => i_edit_param_info_tab(15),
                   argument16  => i_edit_param_info_tab(16),
                   argument17  => i_edit_param_info_tab(17),
                   argument18  => i_edit_param_info_tab(18),
                   argument19  => i_edit_param_info_tab(19),
                   argument20  => i_edit_param_info_tab(20),
                   argument21  => i_edit_param_info_tab(21),
                   argument22  => i_edit_param_info_tab(22),
                   argument23  => i_edit_param_info_tab(23),
                   argument24  => i_edit_param_info_tab(24),
                   argument25  => i_edit_param_info_tab(25),
                   argument26  => i_edit_param_info_tab(26),
                   argument27  => i_edit_param_info_tab(27),
                   argument28  => i_edit_param_info_tab(28),
                   argument29  => i_edit_param_info_tab(29),
                   argument30  => i_edit_param_info_tab(30),
                   argument31  => i_edit_param_info_tab(31),
                   argument32  => i_edit_param_info_tab(32),
                   argument33  => i_edit_param_info_tab(33),
                   argument34  => i_edit_param_info_tab(34),
                   argument35  => i_edit_param_info_tab(35),
                   argument36  => i_edit_param_info_tab(36),
                   argument37  => i_edit_param_info_tab(37),
                   argument38  => i_edit_param_info_tab(38),
                   argument39  => i_edit_param_info_tab(39),
                   argument40  => i_edit_param_info_tab(40),
                   argument41  => i_edit_param_info_tab(41),
                   argument42  => i_edit_param_info_tab(42),
                   argument43  => i_edit_param_info_tab(43),
                   argument44  => i_edit_param_info_tab(44),
                   argument45  => i_edit_param_info_tab(45),
                   argument46  => i_edit_param_info_tab(46),
                   argument47  => i_edit_param_info_tab(47),
                   argument48  => i_edit_param_info_tab(48),
                   argument49  => i_edit_param_info_tab(49),
                   argument50  => i_edit_param_info_tab(50),
                   argument51  => i_edit_param_info_tab(51),
                   argument52  => i_edit_param_info_tab(52),
                   argument53  => i_edit_param_info_tab(53),
                   argument54  => i_edit_param_info_tab(54),
                   argument55  => i_edit_param_info_tab(55),
                   argument56  => i_edit_param_info_tab(56),
                   argument57  => i_edit_param_info_tab(57),
                   argument58  => i_edit_param_info_tab(58),
                   argument59  => i_edit_param_info_tab(59),
                   argument60  => i_edit_param_info_tab(60),
                   argument61  => i_edit_param_info_tab(61),
                   argument62  => i_edit_param_info_tab(62),
                   argument63  => i_edit_param_info_tab(63),
                   argument64  => i_edit_param_info_tab(64),
                   argument65  => i_edit_param_info_tab(65),
                   argument66  => i_edit_param_info_tab(66),
                   argument67  => i_edit_param_info_tab(67),
                   argument68  => i_edit_param_info_tab(68),
                   argument69  => i_edit_param_info_tab(69),
                   argument70  => i_edit_param_info_tab(70),
                   argument71  => i_edit_param_info_tab(71),
                   argument72  => i_edit_param_info_tab(72),
                   argument73  => i_edit_param_info_tab(73),
                   argument74  => i_edit_param_info_tab(74),
                   argument75  => i_edit_param_info_tab(75),
                   argument76  => i_edit_param_info_tab(76),
                   argument77  => i_edit_param_info_tab(77),
                   argument78  => i_edit_param_info_tab(78),
                   argument79  => i_edit_param_info_tab(79),
                   argument80  => i_edit_param_info_tab(80),
                   argument81  => i_edit_param_info_tab(81),
                   argument82  => i_edit_param_info_tab(82),
                   argument83  => i_edit_param_info_tab(83),
                   argument84  => i_edit_param_info_tab(84),
                   argument85  => i_edit_param_info_tab(85),
                   argument86  => i_edit_param_info_tab(86),
                   argument87  => i_edit_param_info_tab(87),
                   argument88  => i_edit_param_info_tab(88),
                   argument89  => i_edit_param_info_tab(89),
                   argument90  => i_edit_param_info_tab(90),
                   argument91  => i_edit_param_info_tab(91),
                   argument92  => i_edit_param_info_tab(92),
                   argument93  => i_edit_param_info_tab(93),
                   argument94  => i_edit_param_info_tab(94),
                   argument95  => i_edit_param_info_tab(95),
                   argument96  => i_edit_param_info_tab(96),
                   argument97  => i_edit_param_info_tab(97),
                   argument98  => i_edit_param_info_tab(98));
--
    IF ( ln_req_id = 0 ) THEN
--
      -- 起動対象コンカレントの起動失敗エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_application,
                    iv_name        => cv_msg_concurrent_fail);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSE
--
      -- ログ出力用要求IDセット
      gn_target_req_id := ln_req_id;
      -- コミット処理
      COMMIT;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
    END IF;
--
    -- コンカレント完了待ち
    lb_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(
                     request_id      =>  ln_req_id,
                     interval        =>  TO_NUMBER(lv_watch_time),
                     max_wait        =>  NULL,
                     phase           =>  lv_phase,
                     status          =>  lv_status,
                     dev_phase       =>  lv_dev_phase,
                     dev_status      =>  lv_dev_status,
                     message         =>  lv_message);
--
    IF ( lb_complete = FALSE ) THEN
--
      -- コンカレントステータス取得失敗エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_concurrent_status_fail,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSIF ( lv_dev_phase <> cv_phase_complete ) THEN
--
      -- コンカレントステータス異常終了エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_abnormal,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSE
      IF ( lv_dev_status = cv_phase_error ) THEN
        -- コンカレントエラー終了エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_err,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_err_expt;
--
      ELSIF ( lv_dev_status = cv_phase_warning ) THEN
--
        -- コンカレント警告終了エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_warning,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- 警告件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_warn_expt;
--
      ELSIF ( lv_dev_status = cv_phase_normal ) THEN
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
--
        -- コンカレント異常終了エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_abnormal,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_err_expt;
--
      END IF;
    END IF;
--
  EXCEPTION
--
    -- *** コンカレント起動処理例外ハンドラ ***
    WHEN submit_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN submit_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END submit_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_processdate
   * Description      : パラメータ編集処理(PROCESSDATE!の場合)
   ***********************************************************************************/
  PROCEDURE edit_param_processdate(
    iv_args                  IN  VARCHAR2,                                           -- 1.入力パラメータ
    ov_edit_value            OUT VARCHAR2,                                           -- 2.編集後パラメータ
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_processdate'; -- プログラム名
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
    ld_date                  DATE;                               -- 業務日付
    lv_format                VARCHAR2(100) DEFAULT NULL;         -- フォーマット
    ln_position              NUMBER DEFAULT 0;                   -- 検索位置
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務日付取得
    ld_date := xxccp_common_pkg2.get_process_date;
--
    -- 書式取得
    ln_position := INSTR(iv_args, cv_processdate);
    lv_format := REPLACE(REPLACE(SUBSTR(iv_args, ln_position + LENGTH(cv_processdate)),'('),')');
--
    -- 日付算出
    ov_edit_value := TO_CHAR(ld_date, lv_format);
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
  END edit_param_processdate;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_asterisk
   * Description      : パラメータ編集処理(*--*の場合)
   ***********************************************************************************/
  PROCEDURE edit_param_asterisk(
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE,   -- 1.値セットID
    it_seq_num               IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,      -- 2.パラメータ順序
    iv_args                  IN  VARCHAR2,                                             -- 3.入力パラメータ
-- 2009/03/10 ADD START
    i_param_info_tab         IN  g_param_info_ttype,                                   -- 4.パラメータ定義情報
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                              -- 5.編集後パラメータ
    in_target_param_cnt      IN  NUMBER,                                               -- 6.パラメータ数
-- 2009/03/10 ADD END
    ov_edit_value            OUT VARCHAR2,                                             -- 7.編集値
    ov_errbuf                OUT VARCHAR2,                                             -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                             -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_asterisk'; -- プログラム名
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
    -- 表検証情報
    lt_id_column_name           fnd_flex_validation_tables.id_column_name%TYPE;               -- ID名称
    lt_value_column_name        fnd_flex_validation_tables.value_column_name%TYPE;            -- 値名称
    lt_application_table_name   fnd_flex_validation_tables.application_table_name%TYPE;       -- 参照テーブル名
    lt_additional_where_clause  fnd_flex_validation_tables.additional_where_clause%TYPE;      -- WHERE句条件
--
    -- プロファイル情報
    lt_profile_name_t           fnd_profile_options.profile_option_name%TYPE DEFAULT NULL;    -- プロファイル名(参照テーブル)
    lv_profile_value_t          VARCHAR2(255) DEFAULT NULL;                                   -- プロファイル値(参照テーブル)
    lt_profile_name_w           fnd_profile_options.profile_option_name%TYPE DEFAULT NULL;    -- プロファイル名(WHERE条件)
    lv_profile_value_w          VARCHAR2(255) DEFAULT NULL;                                   -- プロファイル値(WHERE条件)
--
    -- 動的SQL用
    lv_edit_select              VARCHAR2(10000) DEFAULT NULL;                                 -- SELECT句
    lv_edit_table               VARCHAR2(10000) DEFAULT NULL;                                 -- 参照テーブル
    lv_edit_where               VARCHAR2(10000) DEFAULT NULL;                                 -- WHERE句条件
    lv_edit_where_tmp           VARCHAR2(10000) DEFAULT NULL;                                 -- WHERE句条件
    lv_sql                      VARCHAR2(32767) DEFAULT NULL;                                 -- SQL文
    li_cid                      INTEGER;
    li_row                      INTEGER;
    l_sql_val_tab               DBMS_SQL.VARCHAR2_TABLE;
--
    -- *** ローカル・例外処理 ***
    edit_param_asterisk_expt    EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- 表検証情報取得
    ------------------------------
    SELECT  ffvt.id_column_name           AS id_column_name              -- ID名称
           ,ffvt.value_column_name        AS value_column_name           -- 値名称
           ,ffvt.application_table_name   AS application_table_name      -- 参照テーブル名
           ,ffvt.additional_where_clause  AS additional_where_clause     -- WHERE句条件
    INTO    lt_id_column_name
           ,lt_value_column_name
           ,lt_application_table_name
           ,lt_additional_where_clause
    FROM   fnd_flex_validation_tables     ffvt                           -- 値セット
    WHERE  ffvt.flex_value_set_id         = it_set_id
    ;
--
    ------------------------------
    -- SQL文生成
    ------------------------------
    -- SELECT句編集
    IF ( lt_id_column_name IS NULL ) THEN
      lv_edit_select := lt_value_column_name;
    ELSE
      lv_edit_select := lt_id_column_name;
    END IF;
--
    -- 参照テーブル名編集
    IF ( INSTR(lt_application_table_name, cv_profile) > 0 ) THEN
      -- プロファイル名称取得
      get_profile_name(
        iv_value         => lt_application_table_name,
        ov_value         => lt_profile_name_t,
        ov_errbuf        => lv_errbuf,
        ov_retcode       => lv_retcode,
        ov_errmsg        => lv_errmsg);
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_param_asterisk_expt;
      END IF;
--
      -- プロファイル値取得
      lv_profile_value_t := FND_PROFILE.VALUE(lt_profile_name_t);
--
      -- 置換処理
      lv_edit_table := REPLACE(lt_application_table_name, cv_profile || lt_profile_name_t, '''' || lv_profile_value_t || '''');
--
    ELSE
      lv_edit_table := lt_application_table_name;
    END IF;
--
    -- WHERE句条件編集
    IF ( lt_additional_where_clause IS NULL ) THEN
--
      lv_edit_where := NULL;
--
    ELSE
--
      lv_edit_where_tmp := REPLACE(SUBSTR(lt_additional_where_clause, 1, 10000), CHR(10), ' ');
--
      IF ( INSTR(UPPER(LTRIM(lv_edit_where_tmp)), 'ORDER BY') = 1 ) THEN
        -- WHERE条件が無く、ORDER BY句のみ設定されている場合
        lv_edit_where := lv_edit_where_tmp;
--
      ELSE
-- 2009/03/10 ADD START
        IF ( INSTR(UPPER(LTRIM(lv_edit_where_tmp)), 'WHERE ') = 1 ) THEN
          -- 先頭に"WHERE "が存在する場合、削除
          lv_edit_where_tmp := SUBSTR(LTRIM(lv_edit_where_tmp), 6);
        END IF;
-- 2009/03/10 ADD END
--
        IF ( INSTR(lv_edit_where_tmp, cv_profile) > 0 ) THEN
          -- プロファイル名称取得
          get_profile_name(
            iv_value         => lv_edit_where_tmp,
            ov_value         => lt_profile_name_w,
            ov_errbuf        => lv_errbuf,
            ov_retcode       => lv_retcode,
            ov_errmsg        => lv_errmsg);
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
--
          -- プロファイル値取得
          lv_profile_value_w := FND_PROFILE.VALUE(lt_profile_name_w);
--
          -- 置換処理
          lv_edit_where := ' AND ' || REPLACE(lv_edit_where_tmp, cv_profile || lt_profile_name_w, lv_profile_value_w);
--
        ELSE
          lv_edit_where := ' AND ' || lv_edit_where_tmp;
        END IF;
--
      END IF;
--
    END IF;
--
-- 2009/03/10 ADD START
    ------------------------------
    -- :$FLEX$.<値セット名>の置換
    ------------------------------
    IF (    ( INSTR(lv_edit_select, cv_flex) > 0 )
         OR ( INSTR(lv_edit_table, cv_flex) > 0 )
         OR ( INSTR(lt_value_column_name, cv_flex) > 0 )
         OR ( INSTR(lv_edit_where, cv_flex) > 0 ) )
    THEN
      <<flex_change_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        -- SELECT句に":$FLEX$.<値セット名>"が存在する場合、編集後の値に置換
        IF ( INSTR(lv_edit_select, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
           -- 置換処理
         replace_data(
             iv_before_data   => lv_edit_select
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_select
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- FROM句に":$FLEX$.<値セット名>"が存在する場合、編集後の値に置換
        IF ( INSTR(lv_edit_table, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- 置換処理
          replace_data(
             iv_before_data   => lv_edit_table
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_table
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- VALUE_COLUMN_NAMEに":$FLEX$.<値セット名>"が存在する場合、編集後の値に置換
        IF ( INSTR(lt_value_column_name, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- 置換処理
          replace_data(
             iv_before_data   => lt_value_column_name
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lt_value_column_name
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- WHERE句以降に":$FLEX$.<値セット名>"が存在する場合、編集後の値に置換
        IF ( INSTR(lv_edit_where, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- 置換処理
          replace_data(
             iv_before_data   => lv_edit_where
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_where
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
      END LOOP flex_change_loop ;
    END IF;
-- 2009/03/10 ADD END
--
    -- SQL作成
    lv_sql :=    ' SELECT '|| lv_edit_select
              || ' FROM '  || lv_edit_table
              || ' WHERE ' || lt_value_column_name || ' = ''' || REPLACE(iv_args, cv_asterisk) || ''''
                           || lv_edit_where;
--
    ------------------------------
    -- SQL文実行
    ------------------------------
    li_cid := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(li_cid, lv_sql, DBMS_SQL.native);
    DBMS_SQL.define_array(li_cid, 1, l_sql_val_tab, 2, 1);
    li_row := DBMS_SQL.execute(li_cid);
    li_row := DBMS_SQL.fetch_rows(li_cid);
    DBMS_SQL.column_value(li_cid, 1, l_sql_val_tab);
--
    IF ( l_sql_val_tab.COUNT = 0 ) THEN
--
      -- 表検証の値失敗エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_data_value_set,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_seq_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_asterisk_expt;
--
    ELSIF ( l_sql_val_tab.COUNT = 1 ) THEN
--
      -- 正常時
      ov_edit_value := l_sql_val_tab(1);
--
    ELSE
--
      -- 表検証の値複数件エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_too_many_value_set,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_seq_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_asterisk_expt;
--
    END IF;
--
    -- カーソルクローズ
    DBMS_SQL.close_cursor(li_cid);
--
  EXCEPTION
    
    -- *** パラメータ編集処理例外ハンドラ ****
    WHEN edit_param_asterisk_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_param_asterisk;
--
  /**********************************************************************************
   * PROCEDURE        : edit_param_time
   * Description      : パラメータ編集処理(デフォルトタイプ：現在時刻)
   ***********************************************************************************/
  PROCEDURE edit_param_time(
    it_no                    IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 1.パラメータ順序
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 2.値セットID
    ov_edit_value            OUT VARCHAR2,                                           -- 3.編集後値
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_time'; -- プログラム名
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
    lt_format_type           fnd_flex_value_sets.format_type%TYPE DEFAULT NULL;      -- 書式タイプ
    lt_maximum_size          fnd_flex_value_sets.maximum_size%TYPE DEFAULT NULL;     -- 最大サイズ
    lv_format                VARCHAR2(100) DEFAULT NULL;                             -- 書式
--
    -- *** ローカル・例外処理 ***
    edit_param_time_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- 書式情報の取得
    ------------------------------
    get_format_info(
      it_set_id        => it_set_id,
      ot_format_type   => lt_format_type,
      ot_maximum_size  => lt_maximum_size,
      ov_errbuf        => lv_errbuf,
      ov_retcode       => lv_retcode,
      ov_errmsg        => lv_errmsg);
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE edit_param_time_expt;
    END IF;
--
    ------------------------------
    -- 日付書式取得
    ------------------------------
    IF ( lt_format_type = cv_format_type_y ) THEN
--
      ov_edit_value := TO_CHAR(cd_sysdate, cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_t ) THEN
--
      IF ( lt_maximum_size = 20 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( lt_maximum_size = 18 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format3);
--
      ELSIF ( lt_maximum_size = 17 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format4);
--
      ELSIF ( lt_maximum_size = 15 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format5);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_i ) THEN
--
      IF ( lt_maximum_size = 8 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format6);
--
      END IF;
--
      IF ( lt_maximum_size = 5 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format7);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_c ) THEN
--
      IF ( lt_maximum_size >= 20 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( lt_maximum_size = 18 OR lt_maximum_size = 19 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format3);
--
      ELSIF ( lt_maximum_size = 17 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format4);
--
      ELSIF ( lt_maximum_size = 15 OR lt_maximum_size = 16 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format5);
--
      ELSIF ( lt_maximum_size >= 8 AND lt_maximum_size <= 14 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format8);
--
      ELSIF ( lt_maximum_size >= 5 AND lt_maximum_size <= 7 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format9);
--
      ELSE
--
        ov_edit_value := NULL;
--
      END IF;
--
    ELSE
--
      -- 日付書式取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_format_data,
                     iv_token_name1  => cv_msg_tkn7,
                     iv_token_value1 => it_no);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_time_expt ;
    END IF;
--
--
  EXCEPTION
    -- *** パラメータ編集処理(デフォルトタイプ：現在時刻)処理例外ハンドラ ****
    WHEN edit_param_time_expt THEN
      ov_errmsg  := lv_errmsg ;
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
  END edit_param_time;
--
  /**********************************************************************************
   * PROCEDURE Name   : edit_param_date
   * Description      : パラメータ編集処理(デフォルトタイプ：現在日)
   ***********************************************************************************/
  PROCEDURE edit_param_date(
    it_no                    IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 1.パラメータ順序
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 2.値セットID
    ov_edit_value            OUT VARCHAR2,                                           -- 3.返却値
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_date'; -- プログラム名
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
    lt_format_type           fnd_flex_value_sets.format_type%TYPE DEFAULT NULL;      -- 書式タイプ
    lt_maximum_size          fnd_flex_value_sets.maximum_size%TYPE DEFAULT NULL;     -- 最大サイズ
    lv_format                VARCHAR2(100) DEFAULT NULL;                             -- 書式
--
    -- *** ローカル・例外処理 ***
    edit_param_date_expt      EXCEPTION;
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
    ------------------------------
    -- 書式情報の取得
    ------------------------------
    get_format_info(
      it_set_id        => it_set_id,
      ot_format_type   => lt_format_type,
      ot_maximum_size  => lt_maximum_size,
      ov_errbuf        => lv_errbuf,
      ov_retcode       => lv_retcode,
      ov_errmsg        => lv_errmsg);
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE edit_param_date_expt;
    END IF;
--
    ------------------------------
    -- 日付書式取得
    ------------------------------
    IF ( lt_format_type = cv_format_type_x ) THEN
--
      ov_edit_value := TO_CHAR(TRUNC(cd_sysdate), cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_y ) THEN
--
      ov_edit_value := TO_CHAR(cd_sysdate, cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_d ) THEN
--
      IF ( lt_maximum_size = 11 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      END IF;
--
      IF ( lt_maximum_size = 9 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format11);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_c ) THEN
--
      IF ( lt_maximum_size >= 11 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      ELSIF ( lt_maximum_size = 9 OR lt_maximum_size = 10 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format11);
--
      ELSE
--
        ov_edit_value := NULL;
--
      END IF;
--
    ELSE
--
      -- 日付書式取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_format_data,
                     iv_token_name1  => cv_msg_tkn7,
                     iv_token_value1 => it_no);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_date_expt ;
--
    END IF;
--
--
  EXCEPTION
    -- *** パラメータ編集処理(デフォルトタイプ：現在日)処理例外ハンドラ ****
    WHEN edit_param_date_expt THEN
      ov_errmsg  := lv_errmsg ;
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
  END edit_param_date;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_sql
   * Description      : パラメータ編集処理(デフォルトタイプ：SQL)
   ***********************************************************************************/
  PROCEDURE edit_param_sql(
    it_default_value         IN  fnd_descr_flex_col_usage_vl.default_value%TYPE,     -- 1.デフォルト値
    it_col_num               IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 2.順序
-- 2009/03/10 ADD START
    i_param_info_tab         IN  g_param_info_ttype,                                 -- 3.パラメータ定義情報
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 4.編集後パラメータ
    in_target_param_cnt      IN  NUMBER,                                             -- 5.パラメータ数
-- 2009/03/10 ADD END
    ov_edit_value            OUT VARCHAR2,                                           -- 6.編集値
    ov_errbuf                OUT VARCHAR2,                                           -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,                                           -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)                                           -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_sql'; -- プログラム名
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
    ln_position_pro          NUMBER DEFAULT 0 ;                                              -- '$PROFILE$'文字列検索位置
    lt_default_value_tmp     fnd_descr_flex_col_usage_vl.default_value%TYPE DEFAULT NULL ;   -- ワークデフォルト値
    lt_profile_name          fnd_profile_options.profile_option_name%TYPE DEFAULT NULL ;     -- プロファイル名
    lv_profile_value         VARCHAR2(255) DEFAULT NULL;                                     -- プロファイル返却値
--
    -- 動的SQL用
    li_cid                   INTEGER;
    li_row                   INTEGER;
    lv_sql                   VARCHAR2(32767) DEFAULT NULL;
    l_sql_val_tab            DBMS_SQL.VARCHAR2_TABLE;
--
    -- *** ローカル・例外処理 ***
    edit_param_sql_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- SQL文生成
    ------------------------------
    ln_position_pro := INSTR(it_default_value, cv_profile) ;
--
    IF ( ln_position_pro > 0 ) THEN
--
      get_profile_name(
        iv_value         => it_default_value,
        ov_value         => lt_profile_name,
        ov_errbuf        => lv_errbuf,
        ov_retcode       => lv_retcode,
        ov_errmsg        => lv_errmsg);
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_param_sql_expt;
      END IF;
--
      -- プロファイル値取得
      lv_profile_value := FND_PROFILE.VALUE(
                            name => lt_profile_name);
      -- SQL文作成
      lv_sql := REPLACE(it_default_value, cv_profile || lt_profile_name, '''' || lv_profile_value || '''');
    ELSE
      lv_sql := it_default_value ;
    END IF ;
-- 2009/03/10 ADD START
    ------------------------------
    -- :$FLEX$.<値セット名>の置換
    ------------------------------
    IF INSTR(lv_sql, cv_flex) > 0 THEN
      <<change_flex_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        -- デフォルトSQLに":$FLEX$.<値セット名>"が存在する場合、編集後の値に置換
        IF ( INSTR(lv_sql, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- 置換処理
          replace_data(
             iv_before_data   => lv_sql
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_sql
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          --エラー処理
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_sql_expt;
          END IF;
        END IF;
      END LOOP change_flex_loop ;
    END IF;
-- 2009/03/10 ADD END
--
    ------------------------------
    -- SQL実行
    ------------------------------
    li_cid := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(li_cid, lv_sql, DBMS_SQL.native);
    DBMS_SQL.define_array(li_cid, 1, l_sql_val_tab, 2, 1);
    li_row := DBMS_SQL.execute(li_cid);
    li_row := DBMS_SQL.fetch_rows(li_cid);
    DBMS_SQL.column_value(li_cid, 1, l_sql_val_tab);
--
    IF ( l_sql_val_tab.COUNT = 0 ) THEN
--
      -- デフォルト値0件エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_data_default_value,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_col_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_sql_expt ;
--
    ELSIF ( l_sql_val_tab.COUNT = 1 ) THEN
--
      ov_edit_value := l_sql_val_tab(1);
--
    ELSE
--
      -- デフォルト値複数件エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_too_many_default_value,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_col_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_sql_expt ;
--
    END IF;
--
    -- カーソルクローズ
    DBMS_SQL.close_cursor(li_cid);
--
  EXCEPTION
    -- *** パラメータ編集処理(デフォルトタイプ：SQL)処理例外ハンドラ ****
    WHEN edit_param_sql_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- カーソルクローズ
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END edit_param_sql;
--
  /**********************************************************************************
   * Procedure Name   : get_edit_param_info
   * Description      : 動的パラメータ値算出処理
   ***********************************************************************************/
  PROCEDURE get_edit_param_info(
    iv_app_name            IN     VARCHAR2,                                          -- 1.起動対象アプリケーション短縮名
    iv_prg_name            IN     VARCHAR2,                                          -- 2.起動対コンカレント短縮名
    i_args_info_tab        IN     g_args_info_ttype,                                 -- 3.入力パラメータ
    io_edit_param_info_tab IN OUT g_edit_param_info_ttype,                           -- 4.編集後パラメータ
    on_target_param_cnt    OUT    NUMBER,                                            -- 5.パラメータ数
    ov_errbuf              OUT    VARCHAR2,                                          -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT    VARCHAR2,                                          -- リターン・コード             --# 固定 #
    ov_errmsg              OUT    VARCHAR2)                                          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edit_param_info'; -- プログラム名
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
    lv_edit_value            VARCHAR2(2000) DEFAULT NULL ;                          -- 編集後パラメータ
--
-- 2009/03/10 UPDATE START
--    TYPE l_param_info_rtype IS RECORD(
--       default_type          fnd_descr_flex_col_usage_vl.default_type%TYPE          -- デフォルトタイプ
--      ,default_value         fnd_descr_flex_col_usage_vl.default_value%TYPE         -- デフォルト値
--      ,set_id                fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE     -- 値セットID
--      ,seq_num               fnd_descr_flex_col_usage_vl.column_seq_num%TYPE        -- 順序
--    ) ;
--    TYPE l_param_info_ttype IS TABLE OF l_param_info_rtype INDEX BY BINARY_INTEGER ;
--    l_param_info_tab         l_param_info_ttype ;
   l_param_info_tab            g_param_info_ttype ;
-- 2009/03/10 UPDATE END
--
    -- *** ローカル・例外処理 ***
    get_param_info_expt      EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- パラメータ定義情報取得
    ------------------------------
    SELECT fdfcuv.default_type              AS default_type                          -- デフォルトタイプ
          ,fdfcuv.default_value             AS default_value                         -- デフォルト値
          ,fdfcuv.flex_value_set_id         AS flex_value_set_id                     -- 値セットID
          ,fdfcuv.column_seq_num            AS column_seq_num                        -- 順序
-- 2009/03/10 ADD START
          ,ffvs.flex_value_set_name         AS flex_value_set_name                   -- 値セット名
-- 2009/03/10 ADD END
--
    BULK COLLECT INTO l_param_info_tab
--
    FROM   fnd_concurrent_programs_vl       fcpv                                     -- コンカレントマスタ
          ,fnd_application_vl               fav                                      -- アプリケーションマスタ
          ,fnd_descr_flex_col_usage_vl      fdfcuv                                   -- コンカレントパラメータマスタ
-- 2009/03/10 ADD START
          ,fnd_flex_value_sets              ffvs                                     -- 値セット定義マスタ
-- 2009/03/10 ADD END
    WHERE fav.application_short_name        = iv_app_name
      AND fav.application_id                = fcpv.application_id
      AND fcpv.concurrent_program_name      = iv_prg_name
      AND fcpv.application_id               = fdfcuv.application_id
      AND fdfcuv.descriptive_flexfield_name = cv_srs || fcpv.concurrent_program_name
      AND fdfcuv.enabled_flag               = 'Y'
-- 2009/03/10 ADD START
      AND fdfcuv.flex_value_set_id          = ffvs.flex_value_set_id
-- 2009/03/10 ADD END
    ORDER BY fdfcuv.column_seq_num
    ;
--
    -- パラメータ数のセット
    on_target_param_cnt := l_param_info_tab.COUNT;
--
    IF ( on_target_param_cnt = 0 ) THEN
--
      -- パラメータ0個エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_param_not_found);
--
      lv_errbuf := lv_errmsg;
--
      RAISE get_param_info_expt ;
    END IF ;
--
-- 2009/03/10 ADD START
    IF ( l_param_info_tab.COUNT > i_args_info_tab.COUNT ) THEN
      -- パラメータ数を引数の個数に変更
      on_target_param_cnt := i_args_info_tab.COUNT;
      -- パラメータ制限数超過エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_param_max_over);
      lv_errbuf := lv_errmsg;
      RAISE get_param_info_expt ;
    END IF;
-- 2009/03/10 ADD END
--
    ------------------------------
    -- パラメータ編集処理
    ------------------------------
    <<param_cnt_loop>>
    FOR i IN 1..l_param_info_tab.COUNT LOOP
--
      -- 初期化
      lv_edit_value := NULL;
--
-- 2009/03/10 UPDATE START
--      IF ( i_args_info_tab(i) = cv_default) THEN
      IF ( i_args_info_tab(i) = cv_default OR i_args_info_tab(i) = cv_asterisk || cv_default || cv_asterisk ) THEN
-- 2009/03/10 UPDATE END
--
        IF ( l_param_info_tab(i).default_type = cv_default_type_sql ) THEN
          -- デフォルトタイプ：SQL
-- 2009/03/10 UPDATE START
--          edit_param_sql(
--            it_default_value => l_param_info_tab(i).default_value,                   -- デフォルト値
--            it_col_num       => l_param_info_tab(i).seq_num,                         -- 引数順序
--            ov_edit_value    => lv_edit_value,                                       -- 編集後パラメータ
--            ov_errbuf        => lv_errbuf,                                           -- エラー・メッセージ           --# 固定 #
--            ov_retcode       => lv_retcode,                                          -- リターン・コード             --# 固定 #
--            ov_errmsg        => lv_errmsg);                                          -- ユーザー・エラー・メッセージ --# 固定 #
          edit_param_sql(
            it_default_value      => l_param_info_tab(i).default_value,              -- デフォルト値
            it_col_num            => l_param_info_tab(i).seq_num,                    -- 引数順序
            ov_edit_value         => lv_edit_value,                                  -- 編集後パラメータ
            i_param_info_tab      => l_param_info_tab,                               -- パラメータ定義情報
            i_edit_param_info_tab => io_edit_param_info_tab,                         -- 編集後パラメータ
            in_target_param_cnt   => i - 1,                                          -- パラメータ数
            ov_errbuf             => lv_errbuf,                                      -- エラー・メッセージ           --# 固定 #
            ov_retcode            => lv_retcode,                                     -- リターン・コード             --# 固定 #
            ov_errmsg             => lv_errmsg);                                     -- ユーザー・エラー・メッセージ --# 固定 #
-- 2009/03/10 UPDATE END
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_pro ) THEN
          -- デフォルトタイプ：プロファイル
          lv_edit_value := FND_PROFILE.VALUE(l_param_info_tab(i).default_value);
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_date ) THEN
          -- デフォルトタイプ：現在日
          edit_param_date(
            it_no            => l_param_info_tab(i).seq_num,                         -- パラメータ順序
            it_set_id        => l_param_info_tab(i).set_id,                          -- 値セットID
            ov_edit_value    => lv_edit_value,                                       -- 編集後パラメータ
            ov_errbuf        => lv_errbuf,                                           -- エラー・メッセージ           --# 固定 #
            ov_retcode       => lv_retcode,                                          -- リターン・コード             --# 固定 #
            ov_errmsg        => lv_errmsg);                                          -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_time ) THEN
          -- デフォルトタイプ：現在時刻
          edit_param_time(
            it_no            => l_param_info_tab(i).seq_num,                         -- パラメータ順序
            it_set_id        => l_param_info_tab(i).set_id,                          -- 値セットID
            ov_edit_value    => lv_edit_value,                                       -- 編集後パラメータ
            ov_errbuf        => lv_errbuf,                                           -- エラー・メッセージ           --# 固定 #
            ov_retcode       => lv_retcode,                                          -- リターン・コード             --# 固定 #
            ov_errmsg        => lv_errmsg);                                          -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        END IF ;
--
      ELSIF ( i_args_info_tab(i) = cv_datetime ) THEN
        -- 引数nの値が'DATETIME'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( i_args_info_tab(i) = cv_date ) THEN
        -- 引数nの値が'DATE'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      ELSIF ( i_args_info_tab(i) = cv_time ) THEN
        -- 引数nの値が'TIME'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format6);
--
-- 2009/03/10 DELETE START
--      ELSIF ( SUBSTR( i_args_info_tab(i), 1, 1) = cv_asterisk AND SUBSTR( i_args_info_tab(i), -1, 1) = cv_asterisk ) THEN
--        -- 引数nの値が'*'で括られている
--        edit_param_asterisk(
--          it_set_id        => l_param_info_tab(i).set_id,                            -- 値セットID
--          it_seq_num       => l_param_info_tab(i).seq_num,                           -- パラメータ順序
--          iv_args          => i_args_info_tab(i),                                    -- 入力パラメータ
--          ov_edit_value    => lv_edit_value,                                         -- 編集後パラメータ
--          ov_errbuf        => lv_errbuf,                                             -- エラー・メッセージ           --# 固定 #
--          ov_retcode       => lv_retcode,                                            -- リターン・コード             --# 固定 #
--          ov_errmsg        => lv_errmsg);                                            -- ユーザー・エラー・メッセージ --# 固定 #
--
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE get_param_info_expt;
--        END IF;
-- 2009/03/10 UPDATE END
--
      ELSIF ( INSTR( i_args_info_tab(i), cv_processdate) = 1 ) THEN
        -- 引数nの値が'PROCESSDATE!'で始まっている
        edit_param_processdate(
          iv_args          => i_args_info_tab(i),                                    -- 入力パラメータ
          ov_edit_value    => lv_edit_value,                                         -- 編集後パラメータ
          ov_errbuf        => lv_errbuf,                                             -- エラー・メッセージ           --# 固定 #
          ov_retcode       => lv_retcode,                                            -- リターン・コード             --# 固定 #
          ov_errmsg        => lv_errmsg);                                            -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
      ELSE
        lv_edit_value := i_args_info_tab(i);
      END IF ;
--
-- 2009/03/10 ADD START
      IF ( SUBSTR( i_args_info_tab(i), 1, 1) = cv_asterisk AND SUBSTR( i_args_info_tab(i), -1, 1) = cv_asterisk ) THEN
        -- 引数nの値が'*'で括られている場合、表検証を実行
        edit_param_asterisk(
          it_set_id             => l_param_info_tab(i).set_id,                     -- 値セットID
          it_seq_num            => l_param_info_tab(i).seq_num,                    -- パラメータ順序
          iv_args               => lv_edit_value,                                  -- 入力パラメータ
          i_param_info_tab      => l_param_info_tab,                               -- パラメータ定義情報
          i_edit_param_info_tab => io_edit_param_info_tab,                         -- 編集後パラメータ
          in_target_param_cnt   => i - 1,                                          -- パラメータ数
          ov_edit_value         => lv_edit_value,                                  -- 編集後パラメータ
          ov_errbuf             => lv_errbuf,                                      -- エラー・メッセージ           --# 固定 #
          ov_retcode            => lv_retcode,                                     -- リターン・コード             --# 固定 #
          ov_errmsg             => lv_errmsg);                                     -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
      END IF ;
-- 2009/03/10 ADD END
      -- 編集後パラメータセット
      io_edit_param_info_tab(i) := lv_edit_value;
--
    END LOOP param_cnt_loop ;
--
--
  EXCEPTION
    -- *** 起動対象コンカレント情報取得処理例外ハンドラ ****
    WHEN get_param_info_expt THEN
      ov_errmsg  := lv_errmsg ;
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
  END get_edit_param_info;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_app_name   IN  VARCHAR2,     --   1.起動対象アプリケーション短縮名
    iv_prg_name   IN  VARCHAR2,     --   2.起動対コンカレント短縮名
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
    -- *** ローカル・例外処理 ***
    param_chk_expt           EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------
    -- 必須チェック
    ------------------------------
    -- 起動対象アプリケーション短縮名
    IF ( iv_app_name IS NULL ) THEN
--
      -- 未入力エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_app_name_err);
--
      lv_errbuf := lv_errmsg;
--
      RAISE param_chk_expt ;
    END IF ;
--
    -- 起動対象コンカレント短縮名
    IF ( iv_prg_name IS NULL ) THEN
--
      -- 未入力エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_prg_name_err);
--
      lv_errbuf := lv_errmsg;
--
      RAISE param_chk_expt ;
    END IF ;
--
  EXCEPTION
    -- *** パラメータチェック例外ハンドラ ****
    WHEN param_chk_expt THEN
      ov_errmsg  := lv_errmsg ;
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_app_name   IN     VARCHAR2,           --  1.起動対象アプリケーション短縮名
    iv_prg_name   IN     VARCHAR2,           --  2.起動対象コンカレント短縮名
    iv_args1      IN     VARCHAR2,           --  3.引数1
    iv_args2      IN     VARCHAR2,           --  4.引数2
    iv_args3      IN     VARCHAR2,           --  5.引数3
    iv_args4      IN     VARCHAR2,           --  6.引数4
    iv_args5      IN     VARCHAR2,           --  7.引数5
    iv_args6      IN     VARCHAR2,           --  8.引数6
    iv_args7      IN     VARCHAR2,           --  9.引数7
    iv_args8      IN     VARCHAR2,           -- 10.引数8
    iv_args9      IN     VARCHAR2,           -- 11.引数9
    iv_args10     IN     VARCHAR2,           -- 12.引数10
    iv_args11     IN     VARCHAR2,           -- 13.引数11
    iv_args12     IN     VARCHAR2,           -- 14.引数12
    iv_args13     IN     VARCHAR2,           -- 15.引数13
    iv_args14     IN     VARCHAR2,           -- 16.引数14
    iv_args15     IN     VARCHAR2,           -- 17.引数15
    iv_args16     IN     VARCHAR2,           -- 18.引数16
    iv_args17     IN     VARCHAR2,           -- 19.引数17
    iv_args18     IN     VARCHAR2,           -- 20.引数18
    iv_args19     IN     VARCHAR2,           -- 21.引数19
    iv_args20     IN     VARCHAR2,           -- 22.引数20
    iv_args21     IN     VARCHAR2,           -- 23.引数21
    iv_args22     IN     VARCHAR2,           -- 24.引数22
    iv_args23     IN     VARCHAR2,           -- 25.引数23
    iv_args24     IN     VARCHAR2,           -- 26.引数24
    iv_args25     IN     VARCHAR2,           -- 27.引数25
    iv_args26     IN     VARCHAR2,           -- 28.引数26
    iv_args27     IN     VARCHAR2,           -- 29.引数27
    iv_args28     IN     VARCHAR2,           -- 30.引数28
    iv_args29     IN     VARCHAR2,           -- 31.引数29
    iv_args30     IN     VARCHAR2,           -- 32.引数30
    iv_args31     IN     VARCHAR2,           -- 33.引数31
    iv_args32     IN     VARCHAR2,           -- 34.引数32
    iv_args33     IN     VARCHAR2,           -- 35.引数33
    iv_args34     IN     VARCHAR2,           -- 36.引数34
    iv_args35     IN     VARCHAR2,           -- 37.引数35
    iv_args36     IN     VARCHAR2,           -- 38.引数36
    iv_args37     IN     VARCHAR2,           -- 39.引数37
    iv_args38     IN     VARCHAR2,           -- 40.引数38
    iv_args39     IN     VARCHAR2,           -- 41.引数39
    iv_args40     IN     VARCHAR2,           -- 42.引数40
    iv_args41     IN     VARCHAR2,           -- 43.引数41
    iv_args42     IN     VARCHAR2,           -- 44.引数42
    iv_args43     IN     VARCHAR2,           -- 45.引数43
    iv_args44     IN     VARCHAR2,           -- 46.引数44
    iv_args45     IN     VARCHAR2,           -- 47.引数45
    iv_args46     IN     VARCHAR2,           -- 48.引数46
    iv_args47     IN     VARCHAR2,           -- 49.引数47
    iv_args48     IN     VARCHAR2,           -- 50.引数48
    iv_args49     IN     VARCHAR2,           -- 51.引数49
    iv_args50     IN     VARCHAR2,           -- 52.引数50
    iv_args51     IN     VARCHAR2,           -- 53.引数51
    iv_args52     IN     VARCHAR2,           -- 54.引数52
    iv_args53     IN     VARCHAR2,           -- 55.引数53
    iv_args54     IN     VARCHAR2,           -- 56.引数54
    iv_args55     IN     VARCHAR2,           -- 57.引数55
    iv_args56     IN     VARCHAR2,           -- 58.引数56
    iv_args57     IN     VARCHAR2,           -- 59.引数57
    iv_args58     IN     VARCHAR2,           -- 60.引数58
    iv_args59     IN     VARCHAR2,           -- 61.引数59
    iv_args60     IN     VARCHAR2,           -- 62.引数60
    iv_args61     IN     VARCHAR2,           -- 63.引数61
    iv_args62     IN     VARCHAR2,           -- 64.引数62
    iv_args63     IN     VARCHAR2,           -- 65.引数63
    iv_args64     IN     VARCHAR2,           -- 66.引数64
    iv_args65     IN     VARCHAR2,           -- 67.引数65
    iv_args66     IN     VARCHAR2,           -- 68.引数66
    iv_args67     IN     VARCHAR2,           -- 69.引数67
    iv_args68     IN     VARCHAR2,           -- 70.引数68
    iv_args69     IN     VARCHAR2,           -- 71.引数69
    iv_args70     IN     VARCHAR2,           -- 72.引数70
    iv_args71     IN     VARCHAR2,           -- 73.引数71
    iv_args72     IN     VARCHAR2,           -- 74.引数72
    iv_args73     IN     VARCHAR2,           -- 75.引数73
    iv_args74     IN     VARCHAR2,           -- 76.引数74
    iv_args75     IN     VARCHAR2,           -- 77.引数75
    iv_args76     IN     VARCHAR2,           -- 78.引数76
    iv_args77     IN     VARCHAR2,           -- 79.引数77
    iv_args78     IN     VARCHAR2,           -- 80.引数78
    iv_args79     IN     VARCHAR2,           -- 81.引数79
    iv_args80     IN     VARCHAR2,           -- 82.引数80
    iv_args81     IN     VARCHAR2,           -- 83.引数81
    iv_args82     IN     VARCHAR2,           -- 84.引数82
    iv_args83     IN     VARCHAR2,           -- 85.引数83
    iv_args84     IN     VARCHAR2,           -- 86.引数84
    iv_args85     IN     VARCHAR2,           -- 87.引数85
    iv_args86     IN     VARCHAR2,           -- 88.引数86
    iv_args87     IN     VARCHAR2,           -- 89.引数87
    iv_args88     IN     VARCHAR2,           -- 90.引数88
    iv_args89     IN     VARCHAR2,           -- 91.引数89
    iv_args90     IN     VARCHAR2,           -- 92.引数90
    iv_args91     IN     VARCHAR2,           -- 93.引数91
    iv_args92     IN     VARCHAR2,           -- 94.引数92
    iv_args93     IN     VARCHAR2,           -- 95.引数93
    iv_args94     IN     VARCHAR2,           -- 96.引数94
    iv_args95     IN     VARCHAR2,           -- 97.引数95
    iv_args96     IN     VARCHAR2,           -- 98.引数96
    iv_args97     IN     VARCHAR2,           -- 99.引数97
    iv_args98     IN     VARCHAR2,           --100.引数98
    ov_errbuf     OUT    VARCHAR2,           -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    VARCHAR2,           -- リターン・コード             --# 固定 #
    ov_errmsg     OUT    VARCHAR2)           -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_target_param_cnt     NUMBER                                                        DEFAULT 0 ;    -- パラメータ数
    lt_app_id               fnd_descr_flex_col_usage_vl.application_id%TYPE               DEFAULT NULL ; -- アプリケーションID
    lt_field_name           fnd_descr_flex_col_usage_vl.descriptive_flexfield_name%TYPE   DEFAULT NULL ; -- フィールド名
    l_args_info_tab         g_args_info_ttype ;                                                          -- 入力パラメータ
    l_edit_param_info_tab   g_edit_param_info_ttype;                                                     -- 編集後パラメータ
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
    -- ===============================
    --  入力パラメータセット
    -- ===============================
    l_args_info_tab(1)  := iv_args1 ;
    l_args_info_tab(2)  := iv_args2 ;
    l_args_info_tab(3)  := iv_args3 ;
    l_args_info_tab(4)  := iv_args4 ;
    l_args_info_tab(5)  := iv_args5 ;
    l_args_info_tab(6)  := iv_args6 ;
    l_args_info_tab(7)  := iv_args7 ;
    l_args_info_tab(8)  := iv_args8 ;
    l_args_info_tab(9)  := iv_args9 ;
    l_args_info_tab(10) := iv_args10 ;
    l_args_info_tab(11) := iv_args11 ;
    l_args_info_tab(12) := iv_args12 ;
    l_args_info_tab(13) := iv_args13 ;
    l_args_info_tab(14) := iv_args14 ;
    l_args_info_tab(15) := iv_args15 ;
    l_args_info_tab(16) := iv_args16 ;
    l_args_info_tab(17) := iv_args17 ;
    l_args_info_tab(18) := iv_args18 ;
    l_args_info_tab(19) := iv_args19 ;
    l_args_info_tab(20) := iv_args20 ;
    l_args_info_tab(21) := iv_args21 ;
    l_args_info_tab(22) := iv_args22 ;
    l_args_info_tab(23) := iv_args23 ;
    l_args_info_tab(24) := iv_args24 ;
    l_args_info_tab(25) := iv_args25 ;
    l_args_info_tab(26) := iv_args26 ;
    l_args_info_tab(27) := iv_args27 ;
    l_args_info_tab(28) := iv_args28 ;
    l_args_info_tab(29) := iv_args29 ;
    l_args_info_tab(30) := iv_args30 ;
    l_args_info_tab(31) := iv_args31 ;
    l_args_info_tab(32) := iv_args32 ;
    l_args_info_tab(33) := iv_args33 ;
    l_args_info_tab(34) := iv_args34 ;
    l_args_info_tab(35) := iv_args35 ;
    l_args_info_tab(36) := iv_args36 ;
    l_args_info_tab(37) := iv_args37 ;
    l_args_info_tab(38) := iv_args38 ;
    l_args_info_tab(39) := iv_args39 ;
    l_args_info_tab(40) := iv_args40 ;
    l_args_info_tab(41) := iv_args41 ;
    l_args_info_tab(42) := iv_args42 ;
    l_args_info_tab(43) := iv_args43 ;
    l_args_info_tab(44) := iv_args44 ;
    l_args_info_tab(45) := iv_args45 ;
    l_args_info_tab(46) := iv_args46 ;
    l_args_info_tab(47) := iv_args47 ;
    l_args_info_tab(48) := iv_args48 ;
    l_args_info_tab(49) := iv_args49 ;
    l_args_info_tab(50) := iv_args50 ;
    l_args_info_tab(51) := iv_args51 ;
    l_args_info_tab(52) := iv_args52 ;
    l_args_info_tab(53) := iv_args53 ;
    l_args_info_tab(54) := iv_args54 ;
    l_args_info_tab(55) := iv_args55 ;
    l_args_info_tab(56) := iv_args56 ;
    l_args_info_tab(57) := iv_args57 ;
    l_args_info_tab(58) := iv_args58 ;
    l_args_info_tab(59) := iv_args59 ;
    l_args_info_tab(60) := iv_args60 ;
    l_args_info_tab(61) := iv_args61 ;
    l_args_info_tab(62) := iv_args62 ;
    l_args_info_tab(63) := iv_args63 ;
    l_args_info_tab(64) := iv_args64 ;
    l_args_info_tab(65) := iv_args65 ;
    l_args_info_tab(66) := iv_args66 ;
    l_args_info_tab(67) := iv_args67 ;
    l_args_info_tab(68) := iv_args68 ;
    l_args_info_tab(69) := iv_args69 ;
    l_args_info_tab(70) := iv_args70 ;
    l_args_info_tab(71) := iv_args71 ;
    l_args_info_tab(72) := iv_args72 ;
    l_args_info_tab(73) := iv_args73 ;
    l_args_info_tab(74) := iv_args74 ;
    l_args_info_tab(75) := iv_args75 ;
    l_args_info_tab(76) := iv_args76 ;
    l_args_info_tab(77) := iv_args77 ;
    l_args_info_tab(78) := iv_args78 ;
    l_args_info_tab(79) := iv_args79 ;
    l_args_info_tab(80) := iv_args80 ;
    l_args_info_tab(81) := iv_args81 ;
    l_args_info_tab(82) := iv_args82 ;
    l_args_info_tab(83) := iv_args83 ;
    l_args_info_tab(84) := iv_args84 ;
    l_args_info_tab(85) := iv_args85 ;
    l_args_info_tab(86) := iv_args86 ;
    l_args_info_tab(87) := iv_args87 ;
    l_args_info_tab(88) := iv_args88 ;
    l_args_info_tab(89) := iv_args89 ;
    l_args_info_tab(90) := iv_args90 ;
    l_args_info_tab(91) := iv_args91 ;
    l_args_info_tab(92) := iv_args92 ;
    l_args_info_tab(93) := iv_args93 ;
    l_args_info_tab(94) := iv_args94 ;
    l_args_info_tab(95) := iv_args95 ;
    l_args_info_tab(96) := iv_args96 ;
    l_args_info_tab(97) := iv_args97 ;
    l_args_info_tab(98) := iv_args98 ;
--
    -- ===============================
    --  変種後パラメータ初期値セット
    -- ===============================
    <<param_zan_loop>>
    FOR j IN 1..98 LOOP
      -- 「CHR(0)」をセット
      l_edit_param_info_tab(j) := CHR(0);
    END LOOP param_zan_loop;
--
    -- ===============================
    --  初期処理
    -- ===============================
    init(
      iv_app_name => iv_app_name,                           -- 起動対象アプリケーション短縮名
      iv_prg_name => iv_prg_name,                           -- 起動対象コンカレント短縮名
      ov_errbuf   => lv_errbuf,                             -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,                            -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg);                            -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    --  動的パラメータ値算出処理
    -- ===============================
    IF (lv_retcode = cv_status_normal) THEN
      get_edit_param_info(
        iv_app_name            => iv_app_name,              -- 起動対象アプリケーション短縮名
        iv_prg_name            => iv_prg_name,              -- 起動対象コンカレント短縮名
        i_args_info_tab        => l_args_info_tab,          -- 入力パラメータ
        io_edit_param_info_tab => l_edit_param_info_tab,    -- 編集後パラメータ
        on_target_param_cnt    => ln_target_param_cnt,      -- パラメータ数
        ov_errbuf              => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
        ov_retcode             => lv_retcode,               -- リターン・コード             --# 固定 #
        ov_errmsg              => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    -- ===============================
    --  コンカレント起動処理
    -- ===============================
    IF (lv_retcode = cv_status_normal) THEN
      submit_concurrent(
        iv_application         => iv_app_name,              -- 起動対象アプリケーション短縮名
        iv_program             => iv_prg_name,              -- 起動対象コンカレント短縮名
        i_edit_param_info_tab  => l_edit_param_info_tab,    -- 編集後パラメータ
        ov_errbuf              => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
        ov_retcode             => lv_retcode,               -- リターン・コード             --# 固定 #
        ov_errmsg              => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    -- ===============================
    --  終了処理
    -- ===============================
    last(
      iv_app_name            => iv_app_name,                -- 起動対象アプリケーション短縮名
      iv_prg_name            => iv_prg_name,                -- 起動対象コンカレント短縮名
      in_target_param_cnt    => ln_target_param_cnt,        -- 起動対象コンカレントパラメータ数
      i_edit_param_info_tab  => l_edit_param_info_tab,      -- 編集後パラメータ
      iv_errbuf              => lv_errbuf,                  -- エラーメッセージ
      iv_retcode             => lv_retcode,                 -- リターン・コード
      iv_errmsg              => lv_errmsg,                  -- ユーザー・エラー・メッセージ
      ov_errbuf              => lv_errbuf,                  -- エラー・メッセージ           --# 固定 #
      ov_retcode             => lv_retcode,                 -- リターン・コード             --# 固定 #
      ov_errmsg              => lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
      ov_retcode := lv_retcode;
--
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
    errbuf        OUT    VARCHAR2,                        --  エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,                        --  エラーコード     #固定#
    iv_app_name   IN     VARCHAR2 DEFAULT NULL,           --  1.起動対象アプリケーション短縮名
    iv_prg_name   IN     VARCHAR2 DEFAULT NULL,           --  2.起動対象コンカレント短縮名
    iv_args1      IN     VARCHAR2 DEFAULT CHR(0),         --  3.引数1
    iv_args2      IN     VARCHAR2 DEFAULT CHR(0),         --  4.引数2
    iv_args3      IN     VARCHAR2 DEFAULT CHR(0),         --  5.引数3
    iv_args4      IN     VARCHAR2 DEFAULT CHR(0),         --  6.引数4
    iv_args5      IN     VARCHAR2 DEFAULT CHR(0),         --  7.引数5
    iv_args6      IN     VARCHAR2 DEFAULT CHR(0),         --  8.引数6
    iv_args7      IN     VARCHAR2 DEFAULT CHR(0),         --  9.引数7
    iv_args8      IN     VARCHAR2 DEFAULT CHR(0),         -- 10.引数8
    iv_args9      IN     VARCHAR2 DEFAULT CHR(0),         -- 11.引数9
    iv_args10     IN     VARCHAR2 DEFAULT CHR(0),         -- 12.引数10
    iv_args11     IN     VARCHAR2 DEFAULT CHR(0),         -- 13.引数11
    iv_args12     IN     VARCHAR2 DEFAULT CHR(0),         -- 14.引数12
    iv_args13     IN     VARCHAR2 DEFAULT CHR(0),         -- 15.引数13
    iv_args14     IN     VARCHAR2 DEFAULT CHR(0),         -- 16.引数14
    iv_args15     IN     VARCHAR2 DEFAULT CHR(0),         -- 17.引数15
    iv_args16     IN     VARCHAR2 DEFAULT CHR(0),         -- 18.引数16
    iv_args17     IN     VARCHAR2 DEFAULT CHR(0),         -- 19.引数17
    iv_args18     IN     VARCHAR2 DEFAULT CHR(0),         -- 20.引数18
    iv_args19     IN     VARCHAR2 DEFAULT CHR(0),         -- 21.引数19
    iv_args20     IN     VARCHAR2 DEFAULT CHR(0),         -- 22.引数20
    iv_args21     IN     VARCHAR2 DEFAULT CHR(0),         -- 23.引数21
    iv_args22     IN     VARCHAR2 DEFAULT CHR(0),         -- 24.引数22
    iv_args23     IN     VARCHAR2 DEFAULT CHR(0),         -- 25.引数23
    iv_args24     IN     VARCHAR2 DEFAULT CHR(0),         -- 26.引数24
    iv_args25     IN     VARCHAR2 DEFAULT CHR(0),         -- 27.引数25
    iv_args26     IN     VARCHAR2 DEFAULT CHR(0),         -- 28.引数26
    iv_args27     IN     VARCHAR2 DEFAULT CHR(0),         -- 29.引数27
    iv_args28     IN     VARCHAR2 DEFAULT CHR(0),         -- 30.引数28
    iv_args29     IN     VARCHAR2 DEFAULT CHR(0),         -- 31.引数29
    iv_args30     IN     VARCHAR2 DEFAULT CHR(0),         -- 32.引数30
    iv_args31     IN     VARCHAR2 DEFAULT CHR(0),         -- 33.引数31
    iv_args32     IN     VARCHAR2 DEFAULT CHR(0),         -- 34.引数32
    iv_args33     IN     VARCHAR2 DEFAULT CHR(0),         -- 35.引数33
    iv_args34     IN     VARCHAR2 DEFAULT CHR(0),         -- 36.引数34
    iv_args35     IN     VARCHAR2 DEFAULT CHR(0),         -- 37.引数35
    iv_args36     IN     VARCHAR2 DEFAULT CHR(0),         -- 38.引数36
    iv_args37     IN     VARCHAR2 DEFAULT CHR(0),         -- 39.引数37
    iv_args38     IN     VARCHAR2 DEFAULT CHR(0),         -- 40.引数38
    iv_args39     IN     VARCHAR2 DEFAULT CHR(0),         -- 41.引数39
    iv_args40     IN     VARCHAR2 DEFAULT CHR(0),         -- 42.引数40
    iv_args41     IN     VARCHAR2 DEFAULT CHR(0),         -- 43.引数41
    iv_args42     IN     VARCHAR2 DEFAULT CHR(0),         -- 44.引数42
    iv_args43     IN     VARCHAR2 DEFAULT CHR(0),         -- 45.引数43
    iv_args44     IN     VARCHAR2 DEFAULT CHR(0),         -- 46.引数44
    iv_args45     IN     VARCHAR2 DEFAULT CHR(0),         -- 47.引数45
    iv_args46     IN     VARCHAR2 DEFAULT CHR(0),         -- 48.引数46
    iv_args47     IN     VARCHAR2 DEFAULT CHR(0),         -- 49.引数47
    iv_args48     IN     VARCHAR2 DEFAULT CHR(0),         -- 50.引数48
    iv_args49     IN     VARCHAR2 DEFAULT CHR(0),         -- 51.引数49
    iv_args50     IN     VARCHAR2 DEFAULT CHR(0),         -- 52.引数50
    iv_args51     IN     VARCHAR2 DEFAULT CHR(0),         -- 53.引数51
    iv_args52     IN     VARCHAR2 DEFAULT CHR(0),         -- 54.引数52
    iv_args53     IN     VARCHAR2 DEFAULT CHR(0),         -- 55.引数53
    iv_args54     IN     VARCHAR2 DEFAULT CHR(0),         -- 56.引数54
    iv_args55     IN     VARCHAR2 DEFAULT CHR(0),         -- 57.引数55
    iv_args56     IN     VARCHAR2 DEFAULT CHR(0),         -- 58.引数56
    iv_args57     IN     VARCHAR2 DEFAULT CHR(0),         -- 59.引数57
    iv_args58     IN     VARCHAR2 DEFAULT CHR(0),         -- 60.引数58
    iv_args59     IN     VARCHAR2 DEFAULT CHR(0),         -- 61.引数59
    iv_args60     IN     VARCHAR2 DEFAULT CHR(0),         -- 62.引数60
    iv_args61     IN     VARCHAR2 DEFAULT CHR(0),         -- 63.引数61
    iv_args62     IN     VARCHAR2 DEFAULT CHR(0),         -- 64.引数62
    iv_args63     IN     VARCHAR2 DEFAULT CHR(0),         -- 65.引数63
    iv_args64     IN     VARCHAR2 DEFAULT CHR(0),         -- 66.引数64
    iv_args65     IN     VARCHAR2 DEFAULT CHR(0),         -- 67.引数65
    iv_args66     IN     VARCHAR2 DEFAULT CHR(0),         -- 68.引数66
    iv_args67     IN     VARCHAR2 DEFAULT CHR(0),         -- 69.引数67
    iv_args68     IN     VARCHAR2 DEFAULT CHR(0),         -- 70.引数68
    iv_args69     IN     VARCHAR2 DEFAULT CHR(0),         -- 71.引数69
    iv_args70     IN     VARCHAR2 DEFAULT CHR(0),         -- 72.引数70
    iv_args71     IN     VARCHAR2 DEFAULT CHR(0),         -- 73.引数71
    iv_args72     IN     VARCHAR2 DEFAULT CHR(0),         -- 74.引数72
    iv_args73     IN     VARCHAR2 DEFAULT CHR(0),         -- 75.引数73
    iv_args74     IN     VARCHAR2 DEFAULT CHR(0),         -- 76.引数74
    iv_args75     IN     VARCHAR2 DEFAULT CHR(0),         -- 77.引数75
    iv_args76     IN     VARCHAR2 DEFAULT CHR(0),         -- 78.引数76
    iv_args77     IN     VARCHAR2 DEFAULT CHR(0),         -- 79.引数77
    iv_args78     IN     VARCHAR2 DEFAULT CHR(0),         -- 80.引数78
    iv_args79     IN     VARCHAR2 DEFAULT CHR(0),         -- 81.引数79
    iv_args80     IN     VARCHAR2 DEFAULT CHR(0),         -- 82.引数80
    iv_args81     IN     VARCHAR2 DEFAULT CHR(0),         -- 83.引数81
    iv_args82     IN     VARCHAR2 DEFAULT CHR(0),         -- 84.引数82
    iv_args83     IN     VARCHAR2 DEFAULT CHR(0),         -- 85.引数83
    iv_args84     IN     VARCHAR2 DEFAULT CHR(0),         -- 86.引数84
    iv_args85     IN     VARCHAR2 DEFAULT CHR(0),         -- 87.引数85
    iv_args86     IN     VARCHAR2 DEFAULT CHR(0),         -- 88.引数86
    iv_args87     IN     VARCHAR2 DEFAULT CHR(0),         -- 89.引数87
    iv_args88     IN     VARCHAR2 DEFAULT CHR(0),         -- 90.引数88
    iv_args89     IN     VARCHAR2 DEFAULT CHR(0),         -- 91.引数89
    iv_args90     IN     VARCHAR2 DEFAULT CHR(0),         -- 92.引数90
    iv_args91     IN     VARCHAR2 DEFAULT CHR(0),         -- 93.引数91
    iv_args92     IN     VARCHAR2 DEFAULT CHR(0),         -- 94.引数92
    iv_args93     IN     VARCHAR2 DEFAULT CHR(0),         -- 95.引数93
    iv_args94     IN     VARCHAR2 DEFAULT CHR(0),         -- 96.引数94
    iv_args95     IN     VARCHAR2 DEFAULT CHR(0),         -- 97.引数95
    iv_args96     IN     VARCHAR2 DEFAULT CHR(0),         -- 98.引数96
    iv_args97     IN     VARCHAR2 DEFAULT CHR(0),         -- 99.引数97
    iv_args98     IN     VARCHAR2 DEFAULT CHR(0)          --100.引数98
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
      iv_app_name,       --  1.起動対象アプリケーション短縮名
      iv_prg_name,       --  2.起動対象コンカレント短縮名
      iv_args1,          --  3.引数1
      iv_args2,          --  4.引数2
      iv_args3,          --  5.引数3
      iv_args4,          --  6.引数4
      iv_args5,          --  7.引数5
      iv_args6,          --  8.引数6
      iv_args7,          --  9.引数7
      iv_args8,          -- 10.引数8
      iv_args9,          -- 11.引数9
      iv_args10,         -- 12.引数10
      iv_args11,         -- 13.引数11
      iv_args12,         -- 14.引数12
      iv_args13,         -- 15.引数13
      iv_args14,         -- 16.引数14
      iv_args15,         -- 17.引数15
      iv_args16,         -- 18.引数16
      iv_args17,         -- 19.引数17
      iv_args18,         -- 20.引数18
      iv_args19,         -- 21.引数19
      iv_args20,         -- 22.引数20
      iv_args21,         -- 23.引数21
      iv_args22,         -- 24.引数22
      iv_args23,         -- 25.引数23
      iv_args24,         -- 26.引数24
      iv_args25,         -- 27.引数25
      iv_args26,         -- 28.引数26
      iv_args27,         -- 29.引数27
      iv_args28,         -- 30.引数28
      iv_args29,         -- 31.引数29
      iv_args30,         -- 32.引数30
      iv_args31,         -- 33.引数31
      iv_args32,         -- 34.引数32
      iv_args33,         -- 35.引数33
      iv_args34,         -- 36.引数34
      iv_args35,         -- 37.引数35
      iv_args36,         -- 38.引数36
      iv_args37,         -- 39.引数37
      iv_args38,         -- 40.引数38
      iv_args39,         -- 41.引数39
      iv_args40,         -- 42.引数40
      iv_args41,         -- 43.引数41
      iv_args42,         -- 44.引数42
      iv_args43,         -- 45.引数43
      iv_args44,         -- 46.引数44
      iv_args45,         -- 47.引数45
      iv_args46,         -- 48.引数46
      iv_args47,         -- 49.引数47
      iv_args48,         -- 50.引数48
      iv_args49,         -- 51.引数49
      iv_args50,         -- 52.引数50
      iv_args51,         -- 53.引数51
      iv_args52,         -- 54.引数52
      iv_args53,         -- 55.引数53
      iv_args54,         -- 56.引数54
      iv_args55,         -- 57.引数55
      iv_args56,         -- 58.引数56
      iv_args57,         -- 59.引数57
      iv_args58,         -- 60.引数58
      iv_args59,         -- 61.引数59
      iv_args60,         -- 62.引数60
      iv_args61,         -- 63.引数61
      iv_args62,         -- 64.引数62
      iv_args63,         -- 65.引数63
      iv_args64,         -- 66.引数64
      iv_args65,         -- 67.引数65
      iv_args66,         -- 68.引数66
      iv_args67,         -- 69.引数67
      iv_args68,         -- 70.引数68
      iv_args69,         -- 71.引数69
      iv_args70,         -- 72.引数70
      iv_args71,         -- 73.引数71
      iv_args72,         -- 74.引数72
      iv_args73,         -- 75.引数73
      iv_args74,         -- 76.引数74
      iv_args75,         -- 77.引数75
      iv_args76,         -- 78.引数76
      iv_args77,         -- 79.引数77
      iv_args78,         -- 80.引数78
      iv_args79,         -- 81.引数79
      iv_args80,         -- 82.引数80
      iv_args81,         -- 83.引数81
      iv_args82,         -- 84.引数82
      iv_args83,         -- 85.引数83
      iv_args84,         -- 86.引数84
      iv_args85,         -- 87.引数85
      iv_args86,         -- 88.引数86
      iv_args87,         -- 89.引数87
      iv_args88,         -- 90.引数88
      iv_args89,         -- 91.引数89
      iv_args90,         -- 92.引数90
      iv_args91,         -- 93.引数91
      iv_args92,         -- 94.引数92
      iv_args93,         -- 95.引数93
      iv_args94,         -- 96.引数94
      iv_args95,         -- 97.引数95
      iv_args96,         -- 98.引数96
      iv_args97,         -- 99.引数97
      iv_args98,         --100.引数98
      lv_errbuf,         -- エラー・メッセージ
      lv_retcode,        -- リターン・コード
      lv_errmsg          -- ユーザー・エラー・メッセージ
    );
--
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
END XXCCP006A02C;
/
