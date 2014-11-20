CREATE OR REPLACE PACKAGE BODY XXCMM003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A16C(body)
 * Description      : AFF顧客マスタ更新
 * MD.050           : MD050_CMM_003_A16_AFF顧客マスタ更新
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2)
 *  output_cust_data       処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-5 終了処理)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/06    1.0   Takuya Kaihara   新規作成
 *  2009/03/09    1.1   Takuya Kaihara   プロファイル値共通化
 *  2009/04/07    1.2   Yutaka.Kuboshima 障害T1_0320の対応
 *  2009/12/08    1.3   Yutaka.Kuboshima 障害E_本稼動_00382の対応
 *  2010/01/05    1.4   Yutaka.Kuboshima 障害E_本稼動_00069の対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  gv_xxcmm_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMM'; --メッセージ区分
  gv_xxccp_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCCP'; --メッセージ区分
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_out_file_dir  VARCHAR2(100);
  gv_out_file_file VARCHAR2(100);
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
  init_err_expt                  EXCEPTION; --初期処理エラー
  fopen_err_expt                 EXCEPTION; --ファイルオープンエラー
  no_date_expt                   EXCEPTION; --対象データ0件
  file_close_err                 EXCEPTION; --ファイルクローズエラー
  write_failure_expt             EXCEPTION; --CSVデータ出力エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(12)  := 'XXCMM003A16C';                 --パッケージ名
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';
  cv_dqu                     CONSTANT VARCHAR2(1)   := '"';                            --文字列括り
--
  cv_fnd_date                CONSTANT VARCHAR2(10)  := 'YYYYMMDD';                     --日付書式
  cv_fnd_slash_date          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                   --日付書式(YYYY/MM/DD)
  cv_fnd_sytem_date          CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';        --システム日付
  cv_proc_date_from          CONSTANT VARCHAR2(50)  := '新規登録日又は更新日（開始）'; --新規登録日又は更新日（開始）
  cv_proc_date_to            CONSTANT VARCHAR2(50)  := '新規登録日又は更新日（終了）'; --新規登録日又は更新日（終了）
--
-- 2009/12/07 Ver1.3 E_本稼動_00382 add start by Yutaka.Kuboshima
  cv_min_date                CONSTANT VARCHAR2(15)  := ' 00:00:00';                    --最小時刻
  cv_max_date                CONSTANT VARCHAR2(15)  := ' 23:59:59';                    --最大時刻
-- 2009/12/07 Ver1.3 E_本稼動_00382 add end by Yutaka.Kuboshima
--
--
  --メッセージ
  cv_file_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';             --ファイル名ノート
  cv_parameter_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00038';             --入力パラメータノート
  cv_no_data_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00301';             --対象データ無し
--
  --エラーメッセージ
  cv_profile_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';             --プロファイル取得エラー
  cv_file_path_invalid_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00003';             --ファイルパス不正エラー
  cv_write_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00304';             --LDTデータ出力エラー
  cv_term_spec_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00302';             --期間指定エラー
  cv_emsg_file_close         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';             --ファイルクローズエラー
  --トークン
  cv_ng_profile              CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                   --プロファイル取得失敗トークン
  cv_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';                    --ファイル名トークン
  cv_ng_word                 CONSTANT VARCHAR2(7)   := 'NG_WORD';                      --CSV出力エラートークン・NG_WORD
  cv_ng_data                 CONSTANT VARCHAR2(7)   := 'NG_DATA';                      --CSV出力エラートークン・NG_DATA
  cv_param                   CONSTANT VARCHAR2(5)   := 'PARAM';                        --パラメータトークン
  cv_value                   CONSTANT VARCHAR2(5)   := 'VALUE';                        --パラメータ値トークン
  cv_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';                      --値トークン
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_user_name      VARCHAR2(2000);
  gn_status_error   NUMBER;              --メッセージ重複チェック
  gn_customer_count NUMBER;              --全件出力件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_from  IN  VARCHAR2,     --   コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to    IN  VARCHAR2,     --   コンカレント・パラメータ処理日(TO)
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_out_file_dir  CONSTANT VARCHAR2(30) := 'XXCMM1_TMP_OUT';               --XXCMM:中間OUTファイル用CSVファイル出力先
    cv_out_file_file CONSTANT VARCHAR2(30) := 'XXCMM1_003A16_OUT_FILE_FILE';  --XXCMM: 情報系連携IFデータ作成用CSVファイル名
    cv_invalid_path  CONSTANT VARCHAR2(25) := 'CSV出力ディレクトリ';          --プロファイル取得失敗（ディレクトリ）
    cv_invalid_name  CONSTANT VARCHAR2(20) := 'CSV出力ファイル名';            --プロファイル取得失敗（ファイル名）
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
    --CSV出力ディレクトリをプロファイルより取得。失敗時はエラー
    gv_out_file_dir := FND_PROFILE.VALUE(cv_out_file_dir);
    IF (gv_out_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_path);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --CSV出力ファイル名をプロファイルより取得。失敗時はエラー
    gv_out_file_file := FND_PROFILE.VALUE(cv_out_file_file);
    IF (gv_out_file_file IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_profile_err_msg,
                                            cv_ng_profile,
                                            cv_invalid_name);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- パラメータチェック
    IF ( iv_proc_date_from > iv_proc_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_term_spec_msg);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --ユーザ名を取得
    gv_user_name := FND_GLOBAL.USER_NAME;
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理例外 ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --初期処理例外時、対象件数、エラー件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : file_open
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
    -- *** ローカル定数 ***
    cn_record_byte CONSTANT NUMBER      := 2047;  --ファイル読み込み文字数
    cv_file_mode   CONSTANT VARCHAR2(1) := 'W';   --書き込みモードで開く
--
    -- *** ローカル変数 ***
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
      --ファイルオープン
      of_file_handler := UTL_FILE.FOPEN(gv_out_file_dir,
                                        gv_out_file_file,
                                        cv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --ファイルパスエラー
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_file_path_invalid_msg);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
--
  EXCEPTION
    WHEN fopen_err_expt THEN                           --*** ファイルオープンエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --ファイルオープンエラー時、対象件数、エラー件数は1件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : output_cust_data
   * Description      : 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE output_cust_data(
    iv_proc_date_from       IN  VARCHAR2,               --   コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to         IN  VARCHAR2,               --   コンカレント・パラメータ処理日(TO)
    io_file_handler         IN OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf               OUT VARCHAR2,               --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,               --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)               --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_cust_data'; -- プログラム名
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
    -- *** ローカル定数 ***
    --固定部
    cv_fix_partchr        CONSTANT VARCHAR2(10)     := '';
    cv_fix_part001        CONSTANT VARCHAR2(100)    := '# $Header$';
    cv_fix_part003        CONSTANT VARCHAR2(200)    := '# dbdrv: exec fnd bin FNDLOAD bin &phase=daa+56 checkfile:~PROD:~PATH:~FILE &ui_apps 0 Y UPLOAD @FND:patch/115/import/afffload.lct @~PROD:~PATH/~FILE';
    cv_fix_part004        CONSTANT VARCHAR2(50)     := 'LANGUAGE = "JA"';
    cv_fix_part005        CONSTANT VARCHAR2(100)    := 'LDRCONFIG = "afffload.lct 115.32"';
    cv_fix_part007        CONSTANT VARCHAR2(100)    := '#Source Database ebsd03';
    cv_fix_part009        CONSTANT VARCHAR2(100)    := '#RELEASE_NAME 11.5.10.2';
    cv_fix_part011        CONSTANT VARCHAR2(100)    := '# -- Begin Entity Definitions -- ';
    cv_fix_part013        CONSTANT VARCHAR2(100)    := 'DEFINE VALUE_SET';
    cv_fix_part014        CONSTANT VARCHAR2(100)    := '  KEY   FLEX_VALUE_SET_NAME             VARCHAR2(60)';
    cv_fix_part015        CONSTANT VARCHAR2(100)    := '  CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part016        CONSTANT VARCHAR2(100)    := '  CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part017        CONSTANT VARCHAR2(100)    := '  BASE  VALIDATION_TYPE                 VARCHAR2(1)';
    cv_fix_part018        CONSTANT VARCHAR2(100)    := '  BASE  PROTECTED_FLAG                  VARCHAR2(1)';
    cv_fix_part019        CONSTANT VARCHAR2(100)    := '  BASE  SECURITY_ENABLED_FLAG           VARCHAR2(1)';
    cv_fix_part020        CONSTANT VARCHAR2(100)    := '  BASE  LONGLIST_FLAG                   VARCHAR2(1)';
    cv_fix_part021        CONSTANT VARCHAR2(100)    := '  BASE  FORMAT_TYPE                     VARCHAR2(1)';
    cv_fix_part022        CONSTANT VARCHAR2(100)    := '  BASE  MAXIMUM_SIZE                    VARCHAR2(50)';
    cv_fix_part023        CONSTANT VARCHAR2(100)    := '  BASE  NUMBER_PRECISION                VARCHAR2(50)';
    cv_fix_part024        CONSTANT VARCHAR2(100)    := '  BASE  ALPHANUMERIC_ALLOWED_FLAG       VARCHAR2(1)';
    cv_fix_part025        CONSTANT VARCHAR2(100)    := '  BASE  UPPERCASE_ONLY_FLAG             VARCHAR2(1)';
    cv_fix_part026        CONSTANT VARCHAR2(100)    := '  BASE  NUMERIC_MODE_ENABLED_FLAG       VARCHAR2(1)';
    cv_fix_part027        CONSTANT VARCHAR2(100)    := '  BASE  MINIMUM_VALUE                   VARCHAR2(150)';
    cv_fix_part028        CONSTANT VARCHAR2(100)    := '  BASE  MAXIMUM_VALUE                   VARCHAR2(150)';
    cv_fix_part029        CONSTANT VARCHAR2(100)    := '  BASE  PARENT_FLEX_VALUE_SET_NAME      VARCHAR2(60)';
    cv_fix_part030        CONSTANT VARCHAR2(100)    := '  BASE  DEPENDANT_DEFAULT_VALUE         VARCHAR2(60)';
    cv_fix_part031        CONSTANT VARCHAR2(100)    := '  BASE  DEPENDANT_DEFAULT_MEANING       VARCHAR2(240)';
    cv_fix_part032        CONSTANT VARCHAR2(100)    := '  TRANS DESCRIPTION                     VARCHAR2(240)';
    cv_fix_part034        CONSTANT VARCHAR2(100)    := '  DEFINE VSET_VALUE';
    cv_fix_part035        CONSTANT VARCHAR2(100)    := '    KEY   PARENT_FLEX_VALUE_LOW           VARCHAR2(60)';
    cv_fix_part036        CONSTANT VARCHAR2(100)    := '    KEY   FLEX_VALUE                      VARCHAR2(150)';
    cv_fix_part037        CONSTANT VARCHAR2(100)    := '    CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part038        CONSTANT VARCHAR2(100)    := '    CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part039        CONSTANT VARCHAR2(100)    := '    BASE  ENABLED_FLAG                    VARCHAR2(1)';
    cv_fix_part040        CONSTANT VARCHAR2(100)    := '    BASE  SUMMARY_FLAG                    VARCHAR2(1)';
    cv_fix_part041        CONSTANT VARCHAR2(100)    := '    BASE  START_DATE_ACTIVE               VARCHAR2(50)';
    cv_fix_part042        CONSTANT VARCHAR2(100)    := '    BASE  END_DATE_ACTIVE                 VARCHAR2(50)';
    cv_fix_part043        CONSTANT VARCHAR2(100)    := '    BASE  PARENT_FLEX_VALUE_HIGH          VARCHAR2(60)';
    cv_fix_part044        CONSTANT VARCHAR2(100)    := '    BASE  ROLLUP_HIERARCHY_CODE           VARCHAR2(30)';
    cv_fix_part045        CONSTANT VARCHAR2(100)    := '    BASE  HIERARCHY_LEVEL                 VARCHAR2(50)';
    cv_fix_part046        CONSTANT VARCHAR2(100)    := '    BASE  COMPILED_VALUE_ATTRIBUTES       VARCHAR2(2000)';
    cv_fix_part047        CONSTANT VARCHAR2(100)    := '    BASE  VALUE_CATEGORY                  VARCHAR2(30)';
    cv_fix_part048        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE1                      VARCHAR2(240)';
    cv_fix_part049        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE2                      VARCHAR2(240)';
    cv_fix_part050        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE3                      VARCHAR2(240)';
    cv_fix_part051        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE4                      VARCHAR2(240)';
    cv_fix_part052        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE5                      VARCHAR2(240)';
    cv_fix_part053        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE6                      VARCHAR2(240)';
    cv_fix_part054        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE7                      VARCHAR2(240)';
    cv_fix_part055        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE8                      VARCHAR2(240)';
    cv_fix_part056        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE9                      VARCHAR2(240)';
    cv_fix_part057        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE10                     VARCHAR2(240)';
    cv_fix_part058        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE11                     VARCHAR2(240)';
    cv_fix_part059        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE12                     VARCHAR2(240)';
    cv_fix_part060        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE13                     VARCHAR2(240)';
    cv_fix_part061        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE14                     VARCHAR2(240)';
    cv_fix_part062        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE15                     VARCHAR2(240)';
    cv_fix_part063        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE16                     VARCHAR2(240)';
    cv_fix_part064        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE17                     VARCHAR2(240)';
    cv_fix_part065        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE18                     VARCHAR2(240)';
    cv_fix_part066        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE19                     VARCHAR2(240)';
    cv_fix_part067        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE20                     VARCHAR2(240)';
    cv_fix_part068        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE21                     VARCHAR2(240)';
    cv_fix_part069        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE22                     VARCHAR2(240)';
    cv_fix_part070        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE23                     VARCHAR2(240)';
    cv_fix_part071        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE24                     VARCHAR2(240)';
    cv_fix_part072        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE25                     VARCHAR2(240)';
    cv_fix_part073        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE26                     VARCHAR2(240)';
    cv_fix_part074        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE27                     VARCHAR2(240)';
    cv_fix_part075        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE28                     VARCHAR2(240)';
    cv_fix_part076        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE29                     VARCHAR2(240)';
    cv_fix_part077        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE30                     VARCHAR2(240)';
    cv_fix_part078        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE31                     VARCHAR2(240)';
    cv_fix_part079        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE32                     VARCHAR2(240)';
    cv_fix_part080        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE33                     VARCHAR2(240)';
    cv_fix_part081        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE34                     VARCHAR2(240)';
    cv_fix_part082        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE35                     VARCHAR2(240)';
    cv_fix_part083        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE36                     VARCHAR2(240)';
    cv_fix_part084        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE37                     VARCHAR2(240)';
    cv_fix_part085        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE38                     VARCHAR2(240)';
    cv_fix_part086        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE39                     VARCHAR2(240)';
    cv_fix_part087        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE40                     VARCHAR2(240)';
    cv_fix_part088        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE41                     VARCHAR2(240)';
    cv_fix_part089        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE42                     VARCHAR2(240)';
    cv_fix_part090        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE43                     VARCHAR2(240)';
    cv_fix_part091        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE44                     VARCHAR2(240)';
    cv_fix_part092        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE45                     VARCHAR2(240)';
    cv_fix_part093        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE46                     VARCHAR2(240)';
    cv_fix_part094        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE47                     VARCHAR2(240)';
    cv_fix_part095        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE48                     VARCHAR2(240)';
    cv_fix_part096        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE49                     VARCHAR2(240)';
    cv_fix_part097        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE50                     VARCHAR2(240)';
    cv_fix_part098        CONSTANT VARCHAR2(100)    := '    BASE  ATTRIBUTE_SORT_ORDER            VARCHAR2(50)';
    cv_fix_part099        CONSTANT VARCHAR2(100)    := '    TRANS FLEX_VALUE_MEANING              VARCHAR2(150)';
    cv_fix_part100        CONSTANT VARCHAR2(100)    := '    TRANS DESCRIPTION                     VARCHAR2(240)';
    cv_fix_part102        CONSTANT VARCHAR2(100)    := '    DEFINE VSET_VALUE_QUAL_VALUE';
    cv_fix_part103        CONSTANT VARCHAR2(100)    := '      KEY   ID_FLEX_APPLICATION_SHORT_NAME  VARCHAR2(50)';
    cv_fix_part104        CONSTANT VARCHAR2(100)    := '      KEY   ID_FLEX_CODE                    VARCHAR2(4)';
    cv_fix_part105        CONSTANT VARCHAR2(100)    := '      KEY   SEGMENT_ATTRIBUTE_TYPE          VARCHAR2(30)';
    cv_fix_part106        CONSTANT VARCHAR2(100)    := '      KEY   VALUE_ATTRIBUTE_TYPE            VARCHAR2(30)';
    cv_fix_part107        CONSTANT VARCHAR2(100)    := '      CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part108        CONSTANT VARCHAR2(100)    := '      CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part109        CONSTANT VARCHAR2(100)    := '      BASE  COMPILED_VALUE_ATTRIBUTE_VALUE  VARCHAR2(2000)';
    cv_fix_part110        CONSTANT VARCHAR2(100)    := '    END VSET_VALUE_QUAL_VALUE';
    cv_fix_part112        CONSTANT VARCHAR2(100)    := '      DEFINE VSET_VALUE_HIERARCHY';
    cv_fix_part113        CONSTANT VARCHAR2(100)    := '        KEY   RANGE_ATTRIBUTE                 VARCHAR2(1)';
    cv_fix_part114        CONSTANT VARCHAR2(100)    := '        KEY   CHILD_FLEX_VALUE_LOW            VARCHAR2(60)';
    cv_fix_part115        CONSTANT VARCHAR2(100)    := '        KEY   CHILD_FLEX_VALUE_HIGH           VARCHAR2(60)';
    cv_fix_part116        CONSTANT VARCHAR2(100)    := '        CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part117        CONSTANT VARCHAR2(100)    := '        CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part118        CONSTANT VARCHAR2(100)    := '        BASE  START_DATE_ACTIVE               VARCHAR2(50)';
    cv_fix_part119        CONSTANT VARCHAR2(100)    := '        BASE  END_DATE_ACTIVE                 VARCHAR2(50)';
    cv_fix_part120        CONSTANT VARCHAR2(100)    := '      END VSET_VALUE_HIERARCHY';
    cv_fix_part121        CONSTANT VARCHAR2(100)    := '  END VSET_VALUE';
    cv_fix_part123        CONSTANT VARCHAR2(100)    := '    DEFINE VSET_QUALIFIER';
    cv_fix_part124        CONSTANT VARCHAR2(100)    := '      KEY   ID_FLEX_APPLICATION_SHORT_NAME  VARCHAR2(50)';
    cv_fix_part125        CONSTANT VARCHAR2(100)    := '      KEY   ID_FLEX_CODE                    VARCHAR2(4)';
    cv_fix_part126        CONSTANT VARCHAR2(100)    := '      KEY   SEGMENT_ATTRIBUTE_TYPE          VARCHAR2(30)';
    cv_fix_part127        CONSTANT VARCHAR2(100)    := '      KEY   VALUE_ATTRIBUTE_TYPE            VARCHAR2(30)';
    cv_fix_part128        CONSTANT VARCHAR2(100)    := '      CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part129        CONSTANT VARCHAR2(100)    := '      CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part130        CONSTANT VARCHAR2(100)    := '      BASE  ASSIGNMENT_ORDER                VARCHAR2(50)';
    cv_fix_part131        CONSTANT VARCHAR2(100)    := '      BASE  ASSIGNMENT_DATE                 VARCHAR2(50)';
    cv_fix_part132        CONSTANT VARCHAR2(100)    := '    END VSET_QUALIFIER';
    cv_fix_part134        CONSTANT VARCHAR2(100)    := '      DEFINE VSET_ROLLUP_GROUP';
    cv_fix_part135        CONSTANT VARCHAR2(100)    := '        KEY   HIERARCHY_CODE                  VARCHAR2(30)';
    cv_fix_part136        CONSTANT VARCHAR2(100)    := '        CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part137        CONSTANT VARCHAR2(100)    := '        CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part138        CONSTANT VARCHAR2(100)    := '        TRANS HIERARCHY_NAME                  VARCHAR2(30)';
    cv_fix_part139        CONSTANT VARCHAR2(100)    := '        TRANS DESCRIPTION                     VARCHAR2(240)';
    cv_fix_part140        CONSTANT VARCHAR2(100)    := '      END VSET_ROLLUP_GROUP';
    cv_fix_part142        CONSTANT VARCHAR2(100)    := '        DEFINE VSET_SECURITY_RULE';
    cv_fix_part143        CONSTANT VARCHAR2(100)    := '          KEY   FLEX_VALUE_RULE_NAME            VARCHAR2(30)';
    cv_fix_part144        CONSTANT VARCHAR2(100)    := '          KEY   PARENT_FLEX_VALUE_LOW           VARCHAR2(60)';
    cv_fix_part145        CONSTANT VARCHAR2(100)    := '          CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part146        CONSTANT VARCHAR2(100)    := '          CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part147        CONSTANT VARCHAR2(100)    := '          BASE  PARENT_FLEX_VALUE_HIGH          VARCHAR2(60)';
    cv_fix_part148        CONSTANT VARCHAR2(100)    := '          TRANS ERROR_MESSAGE                   VARCHAR2(240)';
    cv_fix_part149        CONSTANT VARCHAR2(100)    := '          TRANS DESCRIPTION                     VARCHAR2(240)';
    cv_fix_part151        CONSTANT VARCHAR2(100)    := '          DEFINE VSET_SECURITY_USAGE';
    cv_fix_part152        CONSTANT VARCHAR2(100)    := '            KEY   APPLICATION_SHORT_NAME          VARCHAR2(50)';
    cv_fix_part153        CONSTANT VARCHAR2(100)    := '            KEY   RESPONSIBILITY_KEY              VARCHAR2(30)';
    cv_fix_part154        CONSTANT VARCHAR2(100)    := '            CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part155        CONSTANT VARCHAR2(100)    := '            CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part156        CONSTANT VARCHAR2(100)    := '            BASE  PARENT_FLEX_VALUE_HIGH          VARCHAR2(60)';
    cv_fix_part157        CONSTANT VARCHAR2(100)    := '          END VSET_SECURITY_USAGE';
    cv_fix_part159        CONSTANT VARCHAR2(100)    := '            DEFINE VSET_SECURITY_LINE';
    cv_fix_part160        CONSTANT VARCHAR2(100)    := '              KEY   INCLUDE_EXCLUDE_INDICATOR       VARCHAR2(1)';
    cv_fix_part161        CONSTANT VARCHAR2(100)    := '              KEY   FLEX_VALUE_LOW                  VARCHAR2(60)';
    cv_fix_part162        CONSTANT VARCHAR2(100)    := '              KEY   FLEX_VALUE_HIGH                 VARCHAR2(60)';
    cv_fix_part163        CONSTANT VARCHAR2(100)    := '              CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part164        CONSTANT VARCHAR2(100)    := '              CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part165        CONSTANT VARCHAR2(100)    := '              BASE  PARENT_FLEX_VALUE_HIGH          VARCHAR2(60)';
    cv_fix_part166        CONSTANT VARCHAR2(100)    := '            END VSET_SECURITY_LINE';
    cv_fix_part167        CONSTANT VARCHAR2(100)    := '        END VSET_SECURITY_RULE';
    cv_fix_part169        CONSTANT VARCHAR2(100)    := '          DEFINE VSET_EVENT';
    cv_fix_part170        CONSTANT VARCHAR2(100)    := '            KEY   EVENT_CODE                      VARCHAR2(1)';
    cv_fix_part171        CONSTANT VARCHAR2(100)    := '            CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part172        CONSTANT VARCHAR2(100)    := '            CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part173        CONSTANT VARCHAR2(100)    := '            BASE  USER_EXIT                       VARCHAR2(32000)';
    cv_fix_part174        CONSTANT VARCHAR2(100)    := '          END VSET_EVENT';
    cv_fix_part176        CONSTANT VARCHAR2(100)    := '            DEFINE VSET_TABLE';
    cv_fix_part177        CONSTANT VARCHAR2(100)    := '              CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part178        CONSTANT VARCHAR2(100)    := '              CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part179        CONSTANT VARCHAR2(100)    := '              BASE  TABLE_APPLICATION_SHORT_NAME    VARCHAR2(50)';
    cv_fix_part180        CONSTANT VARCHAR2(100)    := '              BASE  APPLICATION_TABLE_NAME          VARCHAR2(240)';
    cv_fix_part181        CONSTANT VARCHAR2(100)    := '              BASE  SUMMARY_ALLOWED_FLAG            VARCHAR2(1)';
    cv_fix_part182        CONSTANT VARCHAR2(100)    := '              BASE  VALUE_COLUMN_NAME               VARCHAR2(240)';
    cv_fix_part183        CONSTANT VARCHAR2(100)    := '              BASE  VALUE_COLUMN_TYPE               VARCHAR2(1)';
    cv_fix_part184        CONSTANT VARCHAR2(100)    := '              BASE  VALUE_COLUMN_SIZE               VARCHAR2(50)';
    cv_fix_part185        CONSTANT VARCHAR2(100)    := '              BASE  ID_COLUMN_NAME                  VARCHAR2(240)';
    cv_fix_part186        CONSTANT VARCHAR2(100)    := '              BASE  ID_COLUMN_TYPE                  VARCHAR2(1)';
    cv_fix_part187        CONSTANT VARCHAR2(100)    := '              BASE  ID_COLUMN_SIZE                  VARCHAR2(50)';
    cv_fix_part188        CONSTANT VARCHAR2(100)    := '              BASE  MEANING_COLUMN_NAME             VARCHAR2(240)';
    cv_fix_part189        CONSTANT VARCHAR2(100)    := '              BASE  MEANING_COLUMN_TYPE             VARCHAR2(1)';
    cv_fix_part190        CONSTANT VARCHAR2(100)    := '              BASE  MEANING_COLUMN_SIZE             VARCHAR2(50)';
    cv_fix_part191        CONSTANT VARCHAR2(100)    := '              BASE  ENABLED_COLUMN_NAME             VARCHAR2(240)';
    cv_fix_part192        CONSTANT VARCHAR2(100)    := '              BASE  COMPILED_ATTRIBUTE_COLUMN_NAME  VARCHAR2(240)';
    cv_fix_part193        CONSTANT VARCHAR2(100)    := '              BASE  HIERARCHY_LEVEL_COLUMN_NAME     VARCHAR2(240)';
    cv_fix_part194        CONSTANT VARCHAR2(100)    := '              BASE  START_DATE_COLUMN_NAME          VARCHAR2(240)';
    cv_fix_part195        CONSTANT VARCHAR2(100)    := '              BASE  END_DATE_COLUMN_NAME            VARCHAR2(240)';
    cv_fix_part196        CONSTANT VARCHAR2(100)    := '              BASE  SUMMARY_COLUMN_NAME             VARCHAR2(240)';
    cv_fix_part197        CONSTANT VARCHAR2(100)    := '              BASE  ADDITIONAL_WHERE_CLAUSE         VARCHAR2(32000)';
    cv_fix_part198        CONSTANT VARCHAR2(100)    := '              BASE  ADDITIONAL_QUICKPICK_COLUMNS    VARCHAR2(240)';
    cv_fix_part199        CONSTANT VARCHAR2(100)    := '            END VSET_TABLE';
    cv_fix_part201        CONSTANT VARCHAR2(100)    := '              DEFINE VSET_DEPENDS_ON';
    cv_fix_part202        CONSTANT VARCHAR2(100)    := '                KEY   IND_FLEX_VALUE_SET_NAME         VARCHAR2(60)';
    cv_fix_part203        CONSTANT VARCHAR2(100)    := '                CTX   OWNER                           VARCHAR2(4000)';
    cv_fix_part204        CONSTANT VARCHAR2(100)    := '                CTX   LAST_UPDATE_DATE                VARCHAR2(50)';
    cv_fix_part205        CONSTANT VARCHAR2(100)    := '                BASE  IND_VALIDATION_TYPE             VARCHAR2(1)';
    cv_fix_part206        CONSTANT VARCHAR2(100)    := '                BASE  DEP_VALIDATION_TYPE             VARCHAR2(1)';
    cv_fix_part207        CONSTANT VARCHAR2(100)    := '              END VSET_DEPENDS_ON';
    cv_fix_part208        CONSTANT VARCHAR2(100)    := 'END VALUE_SET';
    cv_fix_part210        CONSTANT VARCHAR2(100)    := '# -- End Entity Definitions -- ';
--
    --固定部END
    cv_fix_part_end       CONSTANT VARCHAR2(130)    := 'END VALUE_SET';
--
    --可変部ヘッダ
    cv_hvar_partchr       CONSTANT VARCHAR2(100)    := '';
    cv_hvar_partchr2      CONSTANT VARCHAR2(10)     := '  ';
    cv_hvar_part001       CONSTANT VARCHAR2(100)    := 'BEGIN VALUE_SET "XX03_PARTNER"';
    cv_hvar_part002       CONSTANT VARCHAR2(100)    := '  OWNER = ';
    cv_hvar_part003       CONSTANT VARCHAR2(100)    := '  LAST_UPDATE_DATE = ';
    cv_hvar_part004       CONSTANT VARCHAR2(100)    := '  VALIDATION_TYPE = "I"';
    cv_hvar_part005       CONSTANT VARCHAR2(100)    := '  PROTECTED_FLAG = "N"';
    cv_hvar_part006       CONSTANT VARCHAR2(100)    := '  SECURITY_ENABLED_FLAG = "Y"';
    cv_hvar_part007       CONSTANT VARCHAR2(100)    := '  LONGLIST_FLAG = "N"';
    cv_hvar_part008       CONSTANT VARCHAR2(100)    := '  FORMAT_TYPE = "C"';
    cv_hvar_part009       CONSTANT VARCHAR2(100)    := '  MAXIMUM_SIZE = "10"';
    cv_hvar_part010       CONSTANT VARCHAR2(100)    := '  ALPHANUMERIC_ALLOWED_FLAG = "Y"';
    cv_hvar_part011       CONSTANT VARCHAR2(100)    := '  UPPERCASE_ONLY_FLAG = "N"';
    cv_hvar_part012       CONSTANT VARCHAR2(100)    := '  NUMERIC_MODE_ENABLED_FLAG = "N"';
    cv_hvar_part013       CONSTANT VARCHAR2(100)    := '  DESCRIPTION = "顧客コード"';
    cv_hvar_part020       CONSTANT VARCHAR2(100)    := '  BEGIN VSET_QUALIFIER "SQLGL" "GL#" "GL_GLOBAL" "DETAIL_BUDGETING_ALLOWED"';
    cv_hvar_part021       CONSTANT VARCHAR2(100)    := '    OWNER = ';
    cv_hvar_part022       CONSTANT VARCHAR2(100)    := '    LAST_UPDATE_DATE = ';
    cv_hvar_part023       CONSTANT VARCHAR2(100)    := '    ASSIGNMENT_ORDER = "1"';
    cv_hvar_part024       CONSTANT VARCHAR2(100)    := '    ASSIGNMENT_DATE = ';
    cv_hvar_part025       CONSTANT VARCHAR2(100)    := '  END VSET_QUALIFIER';
    cv_hvar_part027       CONSTANT VARCHAR2(100)    := '  BEGIN VSET_QUALIFIER "SQLGL" "GL#" "GL_GLOBAL" "DETAIL_POSTING_ALLOWED"';
    cv_hvar_part028       CONSTANT VARCHAR2(100)    := '    OWNER = ';
    cv_hvar_part029       CONSTANT VARCHAR2(100)    := '    LAST_UPDATE_DATE = ';
    cv_hvar_part030       CONSTANT VARCHAR2(100)    := '    ASSIGNMENT_ORDER = "2"';
    cv_hvar_part031       CONSTANT VARCHAR2(100)    := '    ASSIGNMENT_DATE =';
    cv_hvar_part032       CONSTANT VARCHAR2(100)    := '  END VSET_QUALIFIER';
--

    --可変部
    cv_var_partchr        CONSTANT VARCHAR2(100)    := '';
    cv_var_partchr2       CONSTANT VARCHAR2(100)    := '  ';
    cv_var_partchr4       CONSTANT VARCHAR2(100)    := '    ';
    cv_var_part001        CONSTANT VARCHAR2(100)    := '  BEGIN VSET_VALUE "" ';
    cv_var_part002        CONSTANT VARCHAR2(100)    := '    OWNER = ';
    cv_var_part003        CONSTANT VARCHAR2(100)    := '    LAST_UPDATE_DATE = ';
    cv_var_part004        CONSTANT VARCHAR2(100)    := '    ENABLED_FLAG = "Y"';
    cv_var_part005        CONSTANT VARCHAR2(100)    := '    SUMMARY_FLAG = "N"';
    cv_var_part006        CONSTANT VARCHAR2(100)    := '    COMPILED_VALUE_ATTRIBUTES = "N\n\';
    cv_var_part007        CONSTANT VARCHAR2(100)    := '  Y"';
    cv_var_part008        CONSTANT VARCHAR2(100)    := '    DESCRIPTION = ';
    cv_var_part011        CONSTANT VARCHAR2(100)    := '    BEGIN VSET_VALUE_QUAL_VALUE "SQLGL" "GL#" "GL_GLOBAL"';
    cv_var_part012        CONSTANT VARCHAR2(100)    := '     "DETAIL_BUDGETING_ALLOWED"';
    cv_var_part013        CONSTANT VARCHAR2(100)    := '      OWNER = ';
    cv_var_part014        CONSTANT VARCHAR2(100)    := '      LAST_UPDATE_DATE = ';
    cv_var_part015        CONSTANT VARCHAR2(100)    := '      COMPILED_VALUE_ATTRIBUTE_VALUE = "N"';
    cv_var_part016        CONSTANT VARCHAR2(100)    := '    END VSET_VALUE_QUAL_VALUE';
    cv_var_part018        CONSTANT VARCHAR2(100)    := '    BEGIN VSET_VALUE_QUAL_VALUE "SQLGL" "GL#" "GL_GLOBAL"';
    cv_var_part019        CONSTANT VARCHAR2(100)    := '     "DETAIL_POSTING_ALLOWED"';
    cv_var_part020        CONSTANT VARCHAR2(100)    := '      OWNER = ';
    cv_var_part021        CONSTANT VARCHAR2(100)    := '      LAST_UPDATE_DATE = ';
    cv_var_part022        CONSTANT VARCHAR2(100)    := '      COMPILED_VALUE_ATTRIBUTE_VALUE = "Y"';
    cv_var_part023        CONSTANT VARCHAR2(100)    := '    END VSET_VALUE_QUAL_VALUE';
    cv_var_part025        CONSTANT VARCHAR2(100)    := '  END VSET_VALUE';
--
    --*** ローカル定数 ***
    cv_language_ja        CONSTANT VARCHAR2(2)      := 'JA';                     --言語(日本語)
    cv_gyotai_syo         CONSTANT VARCHAR2(25)     := 'XXCMM_CUST_GYOTAI_SHO';  --業態分類(小分類)
    cv_enabled_flag       CONSTANT VARCHAR2(1)      := 'Y';                      --使用可能
    cv_par_lookup_cd      CONSTANT VARCHAR2(2)      := '11';                     --業態中分類：VD
-- 2009/04/07 Ver1.2 modify start by Yutaka.Kuboshima
--    cv_lookup_cd_syo      CONSTANT VARCHAR2(2)      := '11';                     --業態小分類：問屋帳合
    cv_lookup_cd_syo      CONSTANT VARCHAR2(2)      := '12';                     --業態小分類：帳合問屋
-- 2009/04/07 Ver1.2 modify end by Yutaka.Kuboshima
--
-- 2010/01/05 Ver1.4 E_本稼動_00069 add start by Yutaka.Kuboshima
    cv_tonya_wholesaler   CONSTANT VARCHAR2(1)      := '2';                      --取引形態：問屋帳合
-- 2010/01/05 Ver1.4 E_本稼動_00069 add end by Yutaka.Kuboshima
--
    cv_fset_name          CONSTANT VARCHAR2(15)     := 'XX03_PARTNER';           --値セット名
--
    cv_err_cust_code_msg  CONSTANT VARCHAR2(20)     := '顧客コード';             --CSV出力エラー文字列
--
    -- *** ローカル変数 ***
    ln_output_cnt                  NUMBER           := 0;                        --出力件数
    lv_system_date                 VARCHAR2(25)     := NULL;                     --システム日付
-- 2009/12/08 Ver1.3 E_本稼動_00382 add start by Yutaka.Kuboshima
    ld_proc_date_from              DATE;
    ld_proc_date_to                DATE;
-- 2009/12/08 Ver1.3 E_本稼動_00382 add end by Yutaka.Kuboshima
--
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- AFF顧客マスタ更新カーソル
-- 2009/12/07 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
-- カーソル変数の追加
--    CURSOR cust_data_cur
    CURSOR cust_data_cur(
      p_proc_date_from IN DATE
     ,p_proc_date_to   IN DATE)
-- 2009/12/07 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
    IS
      SELECT hca.account_number       customer_code,    --顧客コード
             hca.account_name         customer_name     --顧客名称
      FROM   hz_cust_accounts     hca,                  --顧客マスタ
             xxcmm_cust_accounts  xca                   --顧客追加情報マスタ
      WHERE  hca.cust_account_id  = xca.customer_id
-- 2010/01/05 Ver1.4 E_本稼動_00069 modify start by Yutaka.Kuboshima
--      AND    xca.business_low_type IN (SELECT flvs.lookup_code
--                                       FROM   fnd_lookup_values flvs
--                                       WHERE  flvs.language     = cv_language_ja
--                                       AND    flvs.lookup_type  = cv_gyotai_syo
--                                       AND    flvs.enabled_flag = cv_enabled_flag
--                                       AND    (flvs.attribute1  = cv_par_lookup_cd
--                                       OR     flvs.lookup_code  = cv_lookup_cd_syo ))
-- 抽出対象条件を業態(中分類)が'11'(VD)または、取引形態が'2'(問屋帳合)に変更
      AND   (xca.business_low_type IN (SELECT flvs.lookup_code
                                       FROM   fnd_lookup_values flvs
                                       WHERE  flvs.language     = cv_language_ja
                                       AND    flvs.lookup_type  = cv_gyotai_syo
                                       AND    flvs.enabled_flag = cv_enabled_flag
                                       AND    flvs.attribute1   = cv_par_lookup_cd)
        OR   xca.torihiki_form = cv_tonya_wholesaler)
-- 2010/01/05 Ver1.4 E_本稼動_00069 modify end by Yutaka.Kuboshima
--
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
--      AND    (TO_DATE(TO_CHAR(hca.last_update_date, cv_fnd_slash_date), cv_fnd_slash_date)
--             BETWEEN TO_DATE(iv_proc_date_from, cv_fnd_slash_date) AND TO_DATE(iv_proc_date_to, cv_fnd_slash_date))
      AND   ((hca.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to)
        OR   (xca.last_update_date BETWEEN p_proc_date_from AND p_proc_date_to))
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
      AND    (NOT EXISTS (SELECT 1
                         FROM   fnd_flex_value_sets  ffvs,
                                fnd_flex_values      ffvv,
                                fnd_flex_values_tl   ffvt
                         WHERE  hca.account_number          =  ffvv.flex_value
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
-- アカウント名がNULLの場合、必ず抽出対象となるので修正
--                         AND    hca.account_name            =  ffvt.description
                         AND    NVL(hca.account_name, 'X')  =  NVL(ffvt.description, 'X')
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
                         AND    ffvs.flex_value_set_name    =  cv_fset_name
                         AND    ffvs.flex_value_set_id      =  ffvv.flex_value_set_id
                         AND    ffvv.flex_value_id          =  ffvt.flex_value_id
                         AND    ffvt.language               =  cv_language_ja));
--
    -- 顧客一括更新情報カーソルレコード型
    cust_data_rec cust_data_cur%ROWTYPE;
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
--
    --システム日付取得
    lv_system_date := TO_CHAR(sysdate, cv_fnd_sytem_date);
--
-- 2009/12/07 Ver1.3 E_本稼動_00382 add start by Yutaka.Kuboshima
    -- パラメータ(FROM)に' 00:00:00'を付与してDATE型に変換
    ld_proc_date_from := TO_DATE(iv_proc_date_from || cv_min_date, cv_fnd_sytem_date);
    -- パラメータ(TO)に' 23:59:59'を付与してDATE型に変換
    ld_proc_date_to   := TO_DATE(iv_proc_date_to   || cv_max_date, cv_fnd_sytem_date);
    -- パラメータ(TO)を + 1
    -- ※夜間バッチ処理で顧客更新処理(顧客最終訪問日更新等)で
    --   対象となった顧客のWHOカラム更新はシステム日付で更新するため
    --   業務日付の内での差分では抽出対象とならないため + 1日とする
    ld_proc_date_to   := ld_proc_date_to + 1;
-- 2009/12/07 Ver1.3 E_本稼動_00382 add start by Yutaka.Kuboshima
--
    SELECT NVL(COUNT(hca.account_number), 0)
    INTO   gn_customer_count                          --該当顧客件数
    FROM   hz_cust_accounts     hca,                  --顧客マスタ
           xxcmm_cust_accounts  xca                   --顧客追加情報マスタ
    WHERE  hca.cust_account_id  = xca.customer_id
-- 2010/01/05 Ver1.4 E_本稼動_00069 modify start by Yutaka.Kuboshima
--    AND    xca.business_low_type IN (SELECT flvs.lookup_code
--                                     FROM   fnd_lookup_values flvs
--                                     WHERE  flvs.language     = cv_language_ja
--                                     AND    flvs.lookup_type  = cv_gyotai_syo
--                                     AND    flvs.enabled_flag = cv_enabled_flag
--                                     AND    (flvs.attribute1  = cv_par_lookup_cd
--                                     OR     flvs.lookup_code  = cv_lookup_cd_syo ))
-- 抽出対象条件を業態(中分類)が'11'(VD)または、取引形態が'2'(問屋帳合)に変更
      AND   (xca.business_low_type IN (SELECT flvs.lookup_code
                                       FROM   fnd_lookup_values flvs
                                       WHERE  flvs.language     = cv_language_ja
                                       AND    flvs.lookup_type  = cv_gyotai_syo
                                       AND    flvs.enabled_flag = cv_enabled_flag
                                       AND    flvs.attribute1   = cv_par_lookup_cd)
        OR   xca.torihiki_form = cv_tonya_wholesaler)
-- 2010/01/05 Ver1.4 E_本稼動_00069 modify end by Yutaka.Kuboshima
--
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
--    AND    (TO_DATE(TO_CHAR(hca.last_update_date, cv_fnd_slash_date), cv_fnd_slash_date)
--           BETWEEN TO_DATE(iv_proc_date_from, cv_fnd_slash_date) AND TO_DATE(iv_proc_date_to, cv_fnd_slash_date))
      AND   ((hca.last_update_date BETWEEN ld_proc_date_from AND ld_proc_date_to)
        OR   (xca.last_update_date BETWEEN ld_proc_date_from AND ld_proc_date_to))
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
    AND    (NOT EXISTS (SELECT 1
                       FROM   fnd_flex_value_sets  ffvs,
                              fnd_flex_values      ffvv,
                              fnd_flex_values_tl   ffvt
                       WHERE  hca.account_number          =  ffvv.flex_value
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
-- アカウント名がNULLの場合、必ず抽出対象となるので修正
--                       AND    hca.account_name            =  ffvt.description
                       AND    NVL(hca.account_name, 'X')  =  NVL(ffvt.description, 'X')
-- 2009/12/08 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
                       AND    ffvs.flex_value_set_name    =  cv_fset_name
                       AND    ffvs.flex_value_set_id      =  ffvv.flex_value_set_id
                       AND    ffvv.flex_value_id          =  ffvt.flex_value_id
                       AND    ffvt.language               =  cv_language_ja));
--
    --固定部：文字列出力
    BEGIN
      --CSVファイル出力
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part001);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part003);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part004);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part005);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part007);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part009);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part011);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part013);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part014);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part015);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part016);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part017);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part018);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part019);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part020);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part021);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part022);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part023);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part024);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part025);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part026);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part027);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part028);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part029);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part030);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part031);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part032);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part034);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part035);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part036);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part037);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part038);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part039);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part040);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part041);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part042);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part043);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part044);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part045);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part046);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part047);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part048);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part049);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part050);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part051);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part052);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part053);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part054);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part055);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part056);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part057);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part058);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part059);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part060);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part061);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part062);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part063);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part064);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part065);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part066);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part067);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part068);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part069);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part070);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part071);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part072);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part073);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part074);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part075);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part076);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part077);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part078);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part079);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part080);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part081);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part082);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part083);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part084);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part085);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part086);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part087);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part088);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part089);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part090);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part091);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part092);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part093);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part094);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part095);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part096);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part097);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part098);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part099);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part100);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part102);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part103);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part104);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part105);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part106);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part107);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part108);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part109);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part110);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part112);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part113);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part114);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part115);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part116);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part117);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part118);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part119);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part120);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part121);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part123);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part124);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part125);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part126);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part127);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part128);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part129);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part130);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part131);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part132);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part134);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part135);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part136);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part137);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part138);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part139);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part140);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part142);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part143);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part144);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part145);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part146);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part147);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part148);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part149);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part151);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part152);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part153);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part154);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part155);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part156);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part157);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part159);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part160);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part161);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part162);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part163);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part164);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part165);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part166);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part167);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part169);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part170);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part171);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part172);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part173);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part174);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part176);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part177);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part178);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part179);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part180);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part181);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part182);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part183);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part184);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part185);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part186);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part187);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part188);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part189);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part190);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part191);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part192);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part193);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part194);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part195);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part196);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part197);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part198);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part199);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part201);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part202);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part203);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part204);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part205);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part206);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part207);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part208);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part210);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_fix_partchr);
      --可変部ヘッダ文字列出力
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part001);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part002 || cv_dqu || gv_user_name   || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part003 || cv_dqu || lv_system_date || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part004);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part005);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part006);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part007);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part008);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part009);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part010);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part011);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part012);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part013);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part020);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part021 || cv_dqu || gv_user_name   || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part022 || cv_dqu || lv_system_date || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part023);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part024 || cv_dqu || lv_system_date || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part025);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr2);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part027);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part028 || cv_dqu || gv_user_name   || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part029 || cv_dqu || lv_system_date || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part030);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part031 || cv_dqu || lv_system_date || cv_dqu);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_part032);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
      UTL_FILE.PUT_LINE(io_file_handler, cv_hvar_partchr);
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_write_err_msg,
                                              cv_ng_word,
                                              cv_err_cust_code_msg,
                                              cv_ng_data,
                                              cust_data_rec.customer_code);
        lv_errbuf := lv_errmsg;
      RAISE write_failure_expt;
    END;
--
    --AFF顧客マスタ更新カーソルループ
    << cust_for_loop >>
-- 2009/12/07 Ver1.3 E_本稼動_00382 modify start by Yutaka.Kuboshima
--    FOR cust_data_rec IN cust_data_cur
    FOR cust_data_rec IN cust_data_cur(ld_proc_date_from, ld_proc_date_to)
-- 2009/12/07 Ver1.3 E_本稼動_00382 modify end by Yutaka.Kuboshima
    LOOP
        -- ===============================
        -- 可変部の取得
        -- ===============================
      BEGIN
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part001 || cv_dqu || SUBSTRB(cust_data_rec.customer_code, 1, 160) || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part002 || cv_dqu || gv_user_name   || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part003 || cv_dqu || lv_system_date || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part004);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part005);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part006);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part007);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part008 || cv_dqu || SUBSTRB(cust_data_rec.customer_name, 1, 240) || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_partchr2);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_partchr2);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part011);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part012);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part013 || cv_dqu || gv_user_name   || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part014 || cv_dqu || lv_system_date || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part015);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part016);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_partchr4);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part018);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part019);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part020 || cv_dqu || gv_user_name   || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part021 || cv_dqu || lv_system_date || cv_dqu );
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part022);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part023);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_partchr4);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_part025);
        UTL_FILE.PUT_LINE(io_file_handler, cv_var_partchr);
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN  --*** ファイル書き込みエラー ***
          lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                                cv_write_err_msg,
                                                cv_ng_word,
                                                cv_err_cust_code_msg,
                                                cv_ng_data,
                                                cust_data_rec.customer_code);
          lv_errbuf  := lv_errmsg;
        RAISE write_failure_expt;
      END;
--
      --出力件数カウント
      ln_output_cnt := ln_output_cnt + 1;
--
    END LOOP cust_for_loop;
--
    --固定部END
    UTL_FILE.PUT_LINE(io_file_handler, cv_fix_part_end);
--
    gn_target_cnt := ln_output_cnt;
    gn_normal_cnt := ln_output_cnt;
--
    --対象データ0件
    IF (ln_output_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                            cv_no_data_msg);
      lv_errbuf := lv_errmsg;
      RAISE no_date_expt;
    END IF;
--
  EXCEPTION
    WHEN no_date_expt THEN                             --*** 対象データなし (正常終了) ***
      ov_retcode := cv_status_normal;
      --対象データが0件の時、件数は0件固定とする
      gn_target_cnt := 0;
      gn_error_cnt  := 0;
      --コンカレント出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
--
    WHEN write_failure_expt THEN                       --*** CSVデータ出力エラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --LDTデータ出力エラー時、対象件数、エラー件数は全件対象とする
      gn_target_cnt := gn_customer_count;
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_customer_count;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_cust_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_from         IN  VARCHAR2,     -- コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to           IN  VARCHAR2,     -- コンカレント・パラメータ処理日(TO)
    ov_errbuf                 OUT VARCHAR2,     --エラー・メッセージ           --# 固定 #
    ov_retcode                OUT VARCHAR2,     --リターン・コード             --# 固定 #
    ov_errmsg                 OUT VARCHAR2)     --ユーザー・エラー・メッセージ --# 固定 #
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
    lf_file_handler   UTL_FILE.FILE_TYPE;  --ファイルハンドラ
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
    gn_target_cnt     := 0;
    gn_normal_cnt     := 0;
    gn_error_cnt      := 0;
    gn_warn_cnt       := 0;
    gn_status_error   := 0;
    gn_customer_count := 0;
--
    --パラメータ出力
    --新規登録日又は更新日（開始）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_from
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_from
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --新規登録日又は更新日（終了）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxcmm_msg_kbn
                    ,iv_name         => cv_parameter_msg
                    ,iv_token_name1  => cv_param
                    ,iv_token_value1 => cv_proc_date_to
                    ,iv_token_name2  => cv_value
                    ,iv_token_value2 => iv_proc_date_to
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
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_proc_date_from   -- コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to    -- コンカレント・パラメータ処理日(TO)
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    --初期処理エラー時は処理を中断
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    --I/Fファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => gv_xxccp_msg_kbn
                    ,iv_name         => cv_file_name_msg
                    ,iv_token_name1  => cv_file_name
                    ,iv_token_value1 => gv_out_file_file
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
--
    -- ===============================
    -- ファイルオープン処理(A-2)
    -- ===============================
    file_open(
       lf_file_handler    -- ファイルハンドラ
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --エラー処理
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 処理対象データ抽出処理(A-3)・抽出情報出力処理(A-4)
    -- ===============================
    output_cust_data(
      iv_proc_date_from        -- コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to         -- コンカレント・パラメータ処理日(TO)
      ,lf_file_handler         -- ファイルハンドラ
      ,lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,lv_retcode              -- リターン・コード             --# 固定 #
      ,lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    --ファイルクローズ処理
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
      gn_status_error := 1;
    END IF;
--
    BEGIN
      --ファイルクローズ
      UTL_FILE.FCLOSE(lf_file_handler);
    EXCEPTION
      WHEN file_close_err THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_xxcmm_msg_kbn,
                                              cv_emsg_file_close,
                                              cv_sqlerrm,
                                              SQLERRM);
        lv_errbuf  := lv_errmsg;
        RAISE file_close_err;
    END;
--
    IF (lv_retcode = cv_status_error)
      OR (lv_retcode = cv_status_normal AND gn_target_cnt = 0)
    THEN
      --ファイル削除
      UTL_FILE.FREMOVE(gv_out_file_dir,gv_out_file_file);
      --エラー処理
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN file_close_err THEN                           --*** ファイルクローズエラー ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --ファイルクローズエラー、対象件数、エラー件数は全件対象とする
      gn_target_cnt := gn_customer_count;
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_customer_count;
      gn_status_error := 0;
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
    errbuf                    OUT VARCHAR2,     --エラー・メッセージ  --# 固定 #
    retcode                   OUT VARCHAR2,     --リターン・コード    --# 固定 #
    iv_proc_date_from         IN  VARCHAR2,     -- コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to           IN  VARCHAR2      -- コンカレント・パラメータ処理日(TO)
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
      iv_proc_date_from          -- コンカレント・パラメータ処理日(FROM)
      ,iv_proc_date_to           -- コンカレント・パラメータ処理日(TO)
      ,lv_errbuf                 --エラー・メッセージ           --# 固定 #
      ,lv_retcode                --リターン・コード             --# 固定 #
      ,lv_errmsg                 --ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error AND gn_status_error = 0) THEN
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
END XXCMM003A16C;
/
