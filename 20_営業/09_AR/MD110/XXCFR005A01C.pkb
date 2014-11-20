CREATE OR REPLACE PACKAGE BODY XXCFR005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A01C(body)
 * Description      : ロックボックスインポート処理自動化
 * MD.050           : MD050_CFR_005_A01_ロックボックスインポート処理自動化
 * MD.070           : MD050_CFR_005_A01_ロックボックスインポート処理自動化
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 入力パラメータ値ログ出力処理  (A-1)
 *  get_profile_value      p プロファイル取得処理          (A-2)
 *  conf_fb_file_date      p FBファイル内データ確認処理    (A-3)
 *  put_fb_file_info       p FBファイル情報ログ処理        (A-4)
 *  gd_process_date        p 業務処理日付取得処理理        (A-5)
 *  change_fb_file_name    p FBファイル名変更処理          (A-6)
 *  start_concurrent       p ロックボックス処理起動処理    (A-7)
 *  conf_lockbox_data      p FBファイルデータ取込確認処理  (A-8)
 *  delete_fb_file         p FBファイル削除処理            (A-9)
----------------------------------------------
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.00 SCS 金田 拓朗    初回作成
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
  file_not_exists_expt  EXCEPTION;      -- ファイル存在エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR005A01C';    -- パッケージ名
  cv_pg_name         CONSTANT VARCHAR2(100) := 'ARLPLB';          -- 起動するコンカレント名
  cv_msg_kbn_ar      CONSTANT VARCHAR2(5)   := 'AR';              -- アプリケーション短縮名：AR
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';           -- アプリケーション短縮名：XXCFR
--
  -- メッセージ番号
  cv_msg_005a01_004  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_005a01_006  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; -- 業務処理日付取得エラーメッセージ
  cv_msg_005a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00012'; -- コンカレント起動エラーメッセージ
  cv_msg_005a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00013'; -- 要求監視エラーメッセージ
  cv_msg_005a01_021  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00021'; -- コンカレント正常終了メッセージ
  cv_msg_005a01_027  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00027'; -- ロックボックス警告メッセージ
  cv_msg_005a01_028  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00028'; -- ロックボックスエラーメッセージ
  cv_msg_005a01_032  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00032'; -- ファイル名出力メッセージ
  cv_msg_005a01_039  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00039'; -- ファイルなしエラー
  cv_msg_005a01_061  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00061'; -- ファイル複製エラーメッセージ
  cv_msg_005a01_062  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00062'; -- ファイル削除エラーメッセージ
  cv_msg_005a01_063  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00063'; -- FBデータ取込エラー
  cv_msg_005a01_064  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00064'; -- ファイル名変更エラーメッセージ
  cv_msg_005a01_066  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00066'; -- 取込エラー退避用ファイル名出力メッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- ファイル名
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- ファイルパス
  cv_tkn_type        CONSTANT VARCHAR2(15) := 'FILE_TYPE';        -- ファイルタイプ
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_NUMBER';   -- 口座番号
  cv_tkn_prog_name   CONSTANT VARCHAR2(30) := 'PROGRAM_NAME';     -- コンカレントプログラム名
  cv_tkn_request     CONSTANT VARCHAR2(15) := 'REQUEST_ID';       -- 要求ID
  cv_tkn_file_name   CONSTANT VARCHAR2(15) := 'FB_FILE_NAME';     -- 対象の伝送名
  cv_tkn_dev_phase   CONSTANT VARCHAR2(15) := 'DEV_PHASE';        -- DEV_PHASE
  cv_tkn_dev_status  CONSTANT VARCHAR2(15) := 'DEV_STATUS';       -- DEV_STATUS
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(15) := 'SQLERRM';          -- SQLERRM
--
  --プロファイル
  cv_org_id                   CONSTANT VARCHAR2(31) := 'ORG_ID';                           -- 組織ID
  cv_fb_file_path             CONSTANT VARCHAR2(31) := 'XXCFR1_FB_FILEPATH';               -- XXCFR:FBファイル格納パス
  cv_prof_name_wait_interval  CONSTANT VARCHAR2(31) := 'XXCFR1_GENERAL_RECEIPT_INTERVAL';
                                                                       -- XXCFR:ロックボックス要求完了チェック待機秒数
  cv_prof_name_wait_max       CONSTANT VARCHAR2(31) := 'XXCFR1_GENERAL_RECEIPT_MAX_WAIT';
                                                                           -- XXCFR:ロックボックス要求完了待機最大秒数
--
  -- ファイル出力
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';            -- メッセージ出力
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';               -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';         -- 日付フォーマット（年月日）
--
  -- コンカレントdevフェーズ
  cv_dev_phase_complete       CONSTANT VARCHAR2(30) := 'COMPLETE';          -- '完了'
  -- コンカレントdevステータス
  cv_dev_status_normal        CONSTANT VARCHAR2(30) := 'NORMAL';            -- '正常'
  cv_dev_status_warn          CONSTANT VARCHAR2(30) := 'WARNING';           -- '警告'
  cv_dev_status_err           CONSTANT VARCHAR2(30) := 'ERROR';             -- 'エラー';
--
  -- リテラル値
  cv_flag_y                   CONSTANT VARCHAR2(10) := 'Y';                 -- フラグ値：Y
  cv_flag_n                   CONSTANT VARCHAR2(10) := 'N';                 -- フラグ値：N
  cv_1                        CONSTANT VARCHAR2(10) := '1';                 -- '1'
  cv_slash                    CONSTANT VARCHAR2(10) := '/';                 -- '/'
  cv_arzeng                   CONSTANT VARCHAR2(10) := 'arzeng';            -- 'arzeng'
  cv_zengin                   CONSTANT VARCHAR2(10) := '102';               -- 'ZENGIN'
  cv_a                        CONSTANT VARCHAR2(10) := 'A';                 -- 'A'
  cv_period                   CONSTANT VARCHAR2(1)  := '.';                 -- ピリオド
  cv_under_bar                CONSTANT VARCHAR2(1)  := '_';                 -- '_'
  cv_txt                      CONSTANT VARCHAR2(4)  := '.txt';              -- ファイルの拡張子
  cn_1                        CONSTANT NUMBER       := 1;                   -- 1
--
  -- 日本語辞書
  cv_dict_cfr005a01001        CONSTANT VARCHAR2(100) := 'CFR005A01001';     -- '対象あり'
  cv_dict_cfr005a01002        CONSTANT VARCHAR2(100) := 'CFR005A01002';     -- '対象なし'
  cv_dict_cfr005a01003        CONSTANT VARCHAR2(100) := 'CFR005A01003';     -- 'ロックボックス処理'
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_fb_filepath        fnd_profile_option_values.profile_option_value%TYPE;  -- FBファイル格納パス
  gv_wait_interval      fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視間隔
  gv_wait_max           fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視最大時間
  gn_org_id             NUMBER;                                               -- 組織ID
  gd_process_date       DATE;                                                 -- 業務処理日付
  gv_fb_file_copy       VARCHAR2(100);                                        -- 複製したFBファイル名を格納する
  gv_transmission_name  ar_transmissions_all.transmission_name%TYPE;          -- 伝送名
  gn_request_id         fnd_concurrent_requests.request_id%TYPE;              -- ロックボックス処理起動時の要求ID
  gv_fb_file_err        VARCHAR2(100);                                        -- ※	取込エラー退避用のFBファイル名を格納する
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_fb_file        IN      VARCHAR2,    -- FBファイル名
    ov_errbuf         OUT     VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT     VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg         OUT     VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,iv_conc_param1  => iv_fb_file         -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUTファイル出力
      ,iv_conc_param1  => iv_fb_file         -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理 (A-2)
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
    -- プロファイルからXXCFR:FBファイル格納パスを取得
    gv_fb_filepath := FND_PROFILE.VALUE(cv_fb_file_path);
    -- 取得エラー時
    IF (gv_fb_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_fb_file_path))
                                                       -- XXCFR:FBファイル格納パス
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:ロックボックス要求完了チェック待機秒数を取得
    gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
    -- 取得エラー時
    IF (gv_wait_interval IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval))
                                                       -- XXCFR:ロックボックス要求完了チェック待機秒数
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:ロックボックス要求完了待機最大秒数を取得
    gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
    -- 取得エラー時
    IF (gv_wait_max IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max))
                                                       -- XXCFR:ロックボックス要求完了待機最大秒数
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織IDを取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_004 -- プロファイル取得エラー
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Procedure Name   : conf_fb_file_date
   * Description      : FBファイル内データ確認処理 (A-3)
   ***********************************************************************************/
  PROCEDURE conf_fb_file_date(
    iv_fb_file              IN  VARCHAR2,           -- FBファイル名
    ov_exist_file_data      OUT VARCHAR2,           -- ファイル内にデータが存在するか判定（Y：存在する、N：存在しない）
    ov_errbuf               OUT NOCOPY VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conf_fb_file_date'; -- プログラム名
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
    lv_csv_text         VARCHAR2(32000) ;       -- ファイル内データ受取用変数
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
    -- 
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
    -- アウトパラメータの初期化
    ov_exist_file_data := 'N';
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_fb_filepath,
                      iv_fb_file,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- ファイル存在なし
    IF not(lb_fexists) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_005a01_039 -- ファイルなし
                                                    ,cv_tkn_file
                                                    ,iv_fb_file
                                                    ,cv_tkn_path
                                                    ,gv_fb_filepath)
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE file_not_exists_expt;
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                    (
                      gv_fb_filepath
                     ,iv_fb_file
                     ,cv_open_mode_r
                    ) ;
--
    -- ====================================================
    -- ファイル取り込み
    -- ====================================================
    UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text );
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
--
    -- FBファイルデータは存在する
    ov_exist_file_data := 'Y';
--
  EXCEPTION
--
    WHEN file_not_exists_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN NO_DATA_FOUND THEN
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand ) ;
      END IF;
--
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
  END conf_fb_file_date;
--
  /**********************************************************************************
   * Procedure Name   : put_fb_file_info
   * Description      : FBファイル情報ログ処理 (A-4)
   ***********************************************************************************/
  PROCEDURE put_fb_file_info(
    iv_fb_file              IN         VARCHAR2,            -- FBファイル名
    iv_exist_file_data      IN         VARCHAR2,            -- ファイル内にデータが存在するか判定（Y：存在する、N：存在しない）
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_fb_file_info'; -- プログラム名
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
    lv_token  VARCHAR2(1000);  -- メッセージトークンの戻り値を格納する
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
    -- ファイル内にデータがあり／なしによって、出力するメッセージを変更する
    IF (iv_exist_file_data = cv_flag_y) THEN -- （Y：存在する、N：存在しない）
      lv_token := xxcfr_common_pkg.lookup_dictionary(
                                                     cv_msg_kbn_cfr
                                                    ,cv_dict_cfr005a01001 
                                                   );
    ELSE
      lv_token := xxcfr_common_pkg.lookup_dictionary(
                                                     cv_msg_kbn_cfr
                                                    ,cv_dict_cfr005a01002 
                                                   );
    END IF;
--
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_005a01_032 -- ファイル名出力メッセージ
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                  ,iv_fb_file        -- ファイル名
                                                  ,cv_tkn_type       -- トークン'FILE_TYPE'
                                                  ,lv_token          -- データあり／データなし
                                                  )
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
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
  END put_fb_file_info;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理(A-5)
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
                                                    ,cv_msg_005a01_006 -- 業務処理日付取得エラー
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Procedure Name   : change_fb_file_name
   * Description      : FBファイル名変更処理 (A-6)
   ***********************************************************************************/
  PROCEDURE change_fb_file_name(
    iv_fb_file              IN  VARCHAR2,                   -- FBファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'change_fb_file_name'; -- プログラム名
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
    -- FBファイル名変更
    -- ====================================================
    -- 複製するファイル名の編集
    gv_fb_file_copy :=   substrb( iv_fb_file ,cn_1 ,instrb(iv_fb_file,cv_period) - cn_1 )
                       ||cv_under_bar
                       ||TO_CHAR( gd_process_date ,cv_format_date_ymd )
                       ||substrb( iv_fb_file ,instrb(iv_fb_file,cv_period) ,lengthb(iv_fb_file) - instrb(iv_fb_file ,cv_period) + cn_1 );
--
    -- ファイルの複製
    UTL_FILE.FCOPY(gv_fb_filepath,
                   iv_fb_file,
                   gv_fb_filepath,
                   gv_fb_file_copy);
--
    -- 複製ファイル情報を出力
    lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                          iv_name => cv_msg_005a01_064,
                                          iv_token_name1 => cv_tkn_file,
                                          iv_token_value1 => gv_fb_file_copy
                                         );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      lv_errmsg
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
      --↓FBファイル名変更エラー処理部分を追加
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                     ,cv_msg_005a01_061    -- ファイル名変更エラーメッセージ
                                                     ,cv_tkn_file          -- トークン'FILE_NAME'
                                                     ,iv_fb_file)
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END change_fb_file_name;
--
  /**********************************************************************************
   * Procedure Name   : start_concurrent
   * Description      : ロックボックス処理起動処理 (A-7)
   ***********************************************************************************/
  PROCEDURE start_concurrent(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_concurrent'; -- プログラム名
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
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
--
    -- *** ローカル・カーソル ***
    -- ディレクトリパス取得
    CURSOR directoriey_cur
    IS
      SELECT directory_path   directoriey_path  -- ディレクトリパス
      FROM all_directories      ad              -- ディレクトリオブジェクト格納テーブル
      WHERE ad.directory_name = gv_fb_filepath  -- ディレクトリオブジェクト名
    ;
    l_directoriey_rec   directoriey_cur%ROWTYPE;
--
    -- ===============================
    -- ローカル例外
    -- ===============================
    submit_request_expt    EXCEPTION;  -- コンカレント発行エラー例外
    wait_for_request_expt  EXCEPTION;  -- コンカレント監視エラー例外
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
    -- 伝送名に今回対象のファイル名をセットする
    gv_transmission_name := gv_fb_file_copy;
--
    -- 物理ディレクトリパスを取得する
    OPEN directoriey_cur;
    FETCH directoriey_cur INTO l_directoriey_rec;
    CLOSE directoriey_cur;
--
    -- コンカレント発行
    gn_request_id := 
    FND_REQUEST.SUBMIT_REQUEST( application => cv_msg_kbn_ar                             -- アプリケーション短縮名
                               ,program     => cv_pg_name                                -- コンカレントプログラム名
                               ,argument1   => cv_flag_y                                 -- 新規伝送
                               ,argument2   => NULL                                      -- 伝送ID
                               ,argument3   => NULL                                      -- 当初要求ID
                               ,argument4   => gv_transmission_name                      -- 伝送名
                               ,argument5   => cv_flag_y                                 -- インポートの発行
                               ,argument6   =>   l_directoriey_rec.directoriey_path
                                               ||cv_slash
                                               ||gv_fb_file_copy                         -- データ・ファイル
                               ,argument7   => cv_arzeng                                 -- 管理ファイル
                               ,argument8   => cv_zengin                                 -- 伝送フォーマットID
                               ,argument9   => cv_flag_n                                 -- 検証の発行
                               ,argument10  => NULL                                      -- 無関連請求書支払
                               ,argument11  => NULL                                      -- ロックボックスID
                               ,argument12  => NULL                                      -- GL記帳日
                               ,argument13  => NULL                                      -- レポート・フォーマット
                               ,argument14  => NULL                                      -- 完了パッチのみ
                               ,argument15  => cv_flag_n                                 -- パッチ転記の発行
                               ,argument16  => cv_a                                      -- カナ検索オプション
                               ,argument17  => NULL                                      -- 一部金額の転記または全入金の拒否
                               ,argument18  => NULL                                      -- USSGL取引コード
                               ,argument19  => gn_org_id                                 -- 組織ID
                              );
--
    IF (gn_request_id = 0) THEN
      RAISE submit_request_expt;
    ELSE
      COMMIT;
    END IF;
--
    -- コンカレント要求監視
    lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST( request_id => gn_request_id    -- 要求ID
                                                       ,interval   => gv_wait_interval -- コンカレント監視間隔
                                                       ,max_wait   => gv_wait_max      -- コンカレント監視最大時間
                                                       ,phase      => lv_phase         -- 要求フェーズ
                                                       ,status     => lv_status        -- 要求ステータス
                                                       ,dev_phase  => lv_dev_phase     -- 要求フェーズコード
                                                       ,dev_status => lv_dev_status    -- 要求ステータスコード
                                                       ,message    => lv_message       -- 完了メッセージ
                                                      );
    IF (lb_wait_request) THEN
      IF    (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_normal)
      THEN
        -- 正常終了の場合
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                              iv_name => cv_msg_005a01_021,
                                              iv_token_name1 => cv_tkn_prog_name,
                                              iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      )
                                             );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSIF (lv_dev_phase = cv_dev_phase_complete)
        AND (lv_dev_status = cv_dev_status_warn)
      THEN
        -- 警告終了の場合
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr        -- 'XXCFR'
                              ,cv_msg_005a01_027
                              ,cv_tkn_request        -- トークン'REQUEST_ID'
                              ,gn_request_id         -- 要求ID
                              ,cv_tkn_file_name      -- トークン'FB_FILE_NAME'
                              ,gv_transmission_name  -- 対象の伝送名
                              ,cv_tkn_dev_phase      -- トークン'DEV_PHASE'
                              ,lv_dev_phase          -- DEV_PHASE
                              ,cv_tkn_dev_status     -- トークン'DEV_STATUS'
                              ,lv_dev_status         -- DEV_STATUS
                            )
                           ,1
                           ,5000
                          );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      ELSE
        -- エラー終了の場合
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr        -- 'XXCFR'
                              ,cv_msg_005a01_028
                              ,cv_tkn_request        -- トークン'REQUEST_ID'
                              ,gn_request_id         -- 要求ID
                              ,cv_tkn_file_name      -- トークン'FB_FILE_NAME'
                              ,gv_transmission_name  -- 対象の伝送名
                              ,cv_tkn_dev_phase      -- トークン'DEV_PHASE'
                              ,lv_dev_phase          -- DEV_PHASE
                              ,cv_tkn_dev_status     -- トークン'DEV_STATUS'
                              ,lv_dev_status         -- DEV_STATUS
                            )
                           ,1
                           ,5000
                          );
        --１行改行
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '' --ユーザー・エラーメッセージ
        );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          lv_errmsg
                         );
        lv_errmsg := '';
      END IF;
    ELSE
      RAISE wait_for_request_expt;
    END IF;
--
  EXCEPTION
--
    -- *** 要求発行失敗時 ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.SUBMIT_REQUESTでスタックされたエラーメッセージがあれば取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a01_012,   -- コンカレント起動エラーメッセージ
                                            iv_token_name1  => cv_tkn_prog_name,    -- トークン'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      )
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
--
    -- *** 要求監視失敗時 ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.WAIT_FOR_REQUESTでスタックされたエラーメッセージがあれば取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr,      -- 'XXCFR'
                                            iv_name         => cv_msg_005a01_013,   -- 要求監視エラーメッセージ
                                            iv_token_name1  => cv_tkn_prog_name,    -- トークン'PROGRAM_NAME'
                                            iv_token_value1 => xxcfr_common_pkg.lookup_dictionary(
                                                                                       cv_msg_kbn_cfr
                                                                                      ,cv_dict_cfr005a01003 
                                                                                      ),
                                            iv_token_name2  => cv_tkn_sqlerrm,      -- トークン'SQLERRM'
                                            iv_token_value2 => SQLERRM
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
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
  END start_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : conf_lockbox_data
   * Description      : FBファイルデータ取込確認処理 (A-8)
   ***********************************************************************************/
  PROCEDURE conf_lockbox_data(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'conf_lockbox_data'; -- プログラム名
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
--
    -- *** ローカル変数 ***
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言（読込時用）
    lf_err_file_hand    UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言（書込時用）
    lv_csv_text         VARCHAR2(32000) ;       -- ファイル内データ受取用変数
    -- 
--
    -- *** ローカル・カーソル ***
    -- 口座番号存在チェック
    CURSOR account_chk_cur(
      iv_origination IN VARCHAR2
    ) 
    IS
      SELECT 'EXISTS' account_chk
      FROM ar_payments_interface_all  apia -- ロックボックスIF
          ,ar_transmissions_all       ata  -- ロックボックスデータ伝送履歴テーブル
          ,ar_lockboxes_all           al   -- ロックボックステーブル
          ,ar_batch_sources           bs   -- 入金ソーステーブル
          ,ap_bank_accounts           ba   -- 銀行口座テーブル
      WHERE ata.transmission_name            = gv_transmission_name         -- 伝送名
        AND ata.org_id                       = gn_org_id                    -- 組織ID
        AND ata.transmission_request_id      = apia.transmission_request_id -- 当初リクエストID
        AND apia.record_type                 = cv_1                         -- レコード識別子（1：ヘッダ）
        AND apia.origination                 = al.bank_origination_number   -- 銀行採番番号
        AND al.batch_source_id               = bs.batch_source_id           -- 入金ソースID
        AND bs.default_remit_bank_account_id = ba.bank_account_id           -- 銀行口座ID
        AND lpad(ba.bank_account_num,10,'0') = iv_origination               -- 口座番号
    ;
--
    l_account_chk_rec   account_chk_cur%ROWTYPE;
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
    -- ＵＴＬファイルオープン（読込時用）
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                    (
                      gv_fb_filepath
                     ,gv_fb_file_copy
                     ,cv_open_mode_r
                    ) ;
--
    -- ====================================================
    -- 複製したFBファイル内を最初の行から最後の行まで順に読込み
    -- ファイル上の取引口座番号が、ロックボックスIF上に存在するか確認します
    -- ====================================================
    <<account_loop>>
    LOOP
      BEGIN
        -- ====================================================
        -- ファイル読み込み
        -- ====================================================
        UTL_FILE.GET_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- データ区分(1桁目の1byte)が'1'（ヘッダ）の場合チェック対象
        -- ====================================================
        IF (SUBSTRB(lv_csv_text,1,1) = cv_1) THEN -- レコード識別子（1：ヘッダ）
--
          -- 対象件数を集計する
          gn_target_cnt := gn_target_cnt + 1;
          -- ====================================================
          -- 口座番号がロックボックスIFに存在するかチェック
          -- ====================================================
          -- 変数初期化
          l_account_chk_rec.account_chk := '';
          --
          OPEN account_chk_cur(SUBSTRB(lv_csv_text,64,10));
          FETCH account_chk_cur INTO l_account_chk_rec;
          IF (account_chk_cur%FOUND) THEN
            -- ====================================================
            -- 正常に取込まれている場合
            -- ====================================================
            -- 成功件数を集計する
            gn_normal_cnt := gn_normal_cnt + 1;
--
          ELSE
            -- エラー件数を集計する
            gn_error_cnt := gn_error_cnt + 1;
            -- ====================================================
            -- ＵＴＬファイルオープン（書込用）
            -- このループに入った１回目のみファイルオープンする
            -- （ov_retcodeが警告ステータスになっていない時）
            -- ====================================================
            IF (ov_retcode <> cv_status_warn) THEN
              -- 取込エラー退避用ファイル名の編集
              gv_fb_file_err :=   TO_CHAR(gn_request_id)
                                ||cv_under_bar
                                ||TO_CHAR( gd_process_date ,cv_format_date_ymd )
                                ||cv_txt
                                ;
--
              --１行改行
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => '' --ユーザー・エラーメッセージ
              );
              -- 取込エラー退避用ファイル情報を出力
              lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_005a01_066,
                                            iv_token_name1 => cv_tkn_file,
                                            iv_token_value1 => gv_fb_file_err
                                           );
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                                lv_errmsg
                                );
--
              lf_err_file_hand := UTL_FILE.FOPEN
                                  (
                                    gv_fb_filepath
                                   ,gv_fb_file_err
                                   ,cv_open_mode_w
                                   );
            END IF;
--
            -- 警告終了ステータス
            ov_retcode := cv_status_warn;
            -- FBデータ取込エラーメッセージ
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfr      -- 'XXCFR'
                                    ,cv_msg_005a01_063
                                    ,cv_tkn_account   -- トークン'ACCOUNT_NUMBER'
                                    ,SUBSTRB(lv_csv_text,64,10)
                                  )
                                 ,1
                                 ,5000
                                );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
          END IF;
          CLOSE account_chk_cur;
--
        END IF;
--
        -- 口座番号が取得できていない場合（口座取得用のカーソルで値を取得できていない場合）
        IF (l_account_chk_rec.account_chk <> 'EXISTS') THEN
          -- ====================================================
          -- ファイル書き込み
          -- ====================================================
          UTL_FILE.PUT_LINE( lf_err_file_hand, lv_csv_text ) ;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          EXIT;
      END;
--
    END LOOP account_loop ;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ（読込時用）
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand );
    -- ====================================================
    -- ＵＴＬファイルクローズ（書込時用）
    -- ====================================================
    UTL_FILE.FCLOSE( lf_err_file_hand );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      UTL_FILE.FCLOSE_ALL;
      --↓カーソルクローズ関数を追加
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      UTL_FILE.FCLOSE_ALL;
      --↓カーソルクローズ関数を追加
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      UTL_FILE.FCLOSE_ALL;
      --↓カーソルクローズ関数を追加
      IF account_chk_cur%ISOPEN THEN
        CLOSE account_chk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END conf_lockbox_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_fb_file
   * Description      : FBファイル削除処理 (A-9)
   ***********************************************************************************/
  PROCEDURE delete_fb_file(
    ov_errbuf               OUT NOCOPY VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_fb_file'; -- プログラム名
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
    -- 複製したFBファイルの削除
    -- ====================================================
    UTL_FILE.FREMOVE(gv_fb_filepath,
                     gv_fb_file_copy);
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
      --↓FBファイル削除エラー処理部分を追加
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_msg_kbn_cfr       -- 'XXCFR'
                                                     ,cv_msg_005a01_062    -- ファイル削除エラーメッセージ
                                                     ,cv_tkn_file          -- トークン'FILE_NAME'
                                                     ,gv_fb_file_copy)
                          ,1
                          ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_fb_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_fb_file             IN      VARCHAR2,         --   FBファイル名
    ov_errbuf              OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_exist_file_data VARCHAR2(1);     -- ファイル内にデータが存在するか判定（Y：存在する、N：存在しない）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_fb_file             -- FBファイル名
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
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
    --  FBファイル内データ確認処理 (A-3)
    -- =====================================================
    conf_fb_file_date(
       iv_fb_file             -- FBファイル名
      ,lv_exist_file_data     -- ファイル内にデータが存在するか判定（Y：存在する、N：存在しない）
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  FBファイル情報ログ処理(A-4)
    -- =====================================================
    put_fb_file_info(
       iv_fb_file             -- FBファイル名
      ,lv_exist_file_data     -- ファイル内にデータが存在するか判定（Y：存在する、N：存在しない）
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  対象ファイルにデータが存在しない場合、後続の処理は行わない
    -- =====================================================
    IF (lv_exist_file_data = cv_flag_y) THEN -- （Y：存在する、N：存在しない）
--
      -- =====================================================
      --  業務処理日付取得処理 (A-5)
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
      --  FBファイル名変更処理 (A-6)
      -- =====================================================
      change_fb_file_name(
         iv_fb_file             -- FBファイル名
        ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,lv_retcode             -- リターン・コード             --# 固定 #
        ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  ロックボックス処理起動処理 (A-7)
      -- =====================================================
      start_concurrent(
         lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,lv_retcode             -- リターン・コード             --# 固定 #
        ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  FBファイルデータ取込確認処理 (A-8)
      -- =====================================================
      conf_lockbox_data(
         lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,lv_retcode             -- リターン・コード             --# 固定 #
        ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        --(警告処理)
        ov_retcode := cv_status_warn;
      END IF;
--
      -- =====================================================
      --  FBファイル削除処理 (A-9)
      -- =====================================================
      delete_fb_file(
         lv_errbuf              -- エラー・メッセージ           --# 固定 #
        ,lv_retcode             -- リターン・コード             --# 固定 #
        ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
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
    errbuf                 OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_fb_file             IN      VARCHAR2          --    FBファイル名
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
       iv_fb_file       -- FBファイル名
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
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
END XXCFR005A01C;
/
