CREATE OR REPLACE PACKAGE BODY APPS.XXCCP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP005A01C(body)
 * Description      : 他システムからのIFファイルにおける、ヘッダ・フッタ削除します。
 * MD.050           : MD050_CCP_005_A01_IFファイルヘッダ・フッタ削除処理
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  file_open              ファイルオープン処理(A-2,A-5)
 *  file_close             ファイルクローズ処理(A-4,A-7)
 *  file_read              ファイル読み込み処理(A-3)
 *  file_write             ファイル書き込み処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-21    1.0   Yutaka.Kuboshima 新規作成
 *  2008-12-01    1.1   Yutaka.Kuboshima スキップ件数出力処理を追加
 *  2009-02-25    1.2   T.Matsumoto      ファイル読み込み時の文字列バッファ長不足暫定対応(2047 ⇒ 30000)
 *  2009-02-26    1.3   T.Matsumoto      出力ログ不正対応
 *  2009-05-01    1.4   Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
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
  init_err_expt             EXCEPTION;     -- 初期処理エラー
  fopen_err_expt            EXCEPTION;     -- ファイルオープンエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCCP005A01C';      -- パッケージ名
--
  gv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCCP';             -- メッセージ区分
--
  --エラーメッセージ
  gv_cnst_msg_if_proh  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10101';  -- プロファイル取得エラー(ヘッダ)
  gv_cnst_msg_if_prod  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10102';  -- プロファイル取得エラー(データ)
  gv_cnst_msg_if_prof  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10103';  -- プロファイル取得エラー(フッタ)
  gv_cnst_msg_if_para1 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10104';  -- 入力項目NULLエラー(ファイル名)
  gv_cnst_msg_if_para2 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10105';  -- 入力項目NULLエラー(相手システム名)
  gv_cnst_msg_if_para3 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10106';  -- 入力項目NULLエラー(ファイルディレクトリ)
  gv_cnst_msg_if_para4 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10107';  -- 入力項目不正エラー(相手システム名)
  gv_cnst_msg_if_para5 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10108';  -- 入力項目不正エラー(ファイル名)
  gv_cnst_msg_if_para6 CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10109';  -- 入力項目不正エラー(ファイルディレクトリ)
  gv_cnst_msg_if_acc   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10110';  -- ファイルアクセス権限エラー
  --コンカレントメッセージ
  gv_cnst_msg_if_ifna  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05101';  -- 処理対象ファイル名メッセージ
  gv_cnst_msg_if_fnam  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';  -- ファイル名メッセージ
  gv_cnst_msg_if_osys  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05103';  -- 相手システム名メッセージ
  gv_cnst_msg_if_fdir  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05104';  -- ファイルディレクトリメッセージ
  --トークン
  gv_cnst_tkn_fname    CONSTANT VARCHAR2(15)  := 'FILE_NAME';         -- トークン(ファイル名)
  gv_cnst_tkn_osystem  CONSTANT VARCHAR2(15)  := 'OTHER_SYSTEM';      -- トークン(相手システム名)
  gv_cnst_tkn_fdir     CONSTANT VARCHAR2(15)  := 'FILE_DIR';          -- トークン(ファイルディレクトリ)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.START
--  TYPE g_file_data_ttype IS TABLE OF VARCHAR2(2047) INDEX BY BINARY_INTEGER;  -- ファイルデータを格納する配列
  TYPE g_file_data_ttype IS TABLE OF VARCHAR2(30000) INDEX BY BINARY_INTEGER;  -- ファイルデータを格納する配列
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.END
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_if_header   VARCHAR2(10);  -- IFレコード区分_ヘッダ
  gv_if_data     VARCHAR2(10);  -- IFレコード区分_データ
  gv_if_footer   VARCHAR2(10);  -- IFレコード区分_フッタ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_name    IN  VARCHAR2,     --   ファイル名
    iv_other_system IN  VARCHAR2,     --   相手システム名
    iv_file_dir     IN  VARCHAR2,     --   ファイルディレクトリ
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_if_header    CONSTANT VARCHAR2(50) := 'XXCCP1_IF_HEADER';  -- プロファイル名(IFレコード区分ヘッダ)
    cv_if_data      CONSTANT VARCHAR2(50) := 'XXCCP1_IF_DATA';    -- プロファイル名(IFレコード区分データ)
    cv_if_footer    CONSTANT VARCHAR2(50) := 'XXCCP1_IF_FOOTER';  -- プロファイル名(IFレコード区分フッタ)
    cv_para_osystem CONSTANT VARCHAR2(5)  := 'EDI';               -- 相手システム名
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
    --IFレコード区分_ヘッダ取得
    gv_if_header := FND_PROFILE.VALUE(cv_if_header);
    --IFレコード区分_ヘッダチェック
    IF (gv_if_header IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_proh);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --IFレコード区分_データ取得
    gv_if_data := FND_PROFILE.VALUE(cv_if_data);
    --IFレコード区分_データチェック
    IF (gv_if_data IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_prod);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --IFレコード区分_フッタ取得
    gv_if_footer := FND_PROFILE.VALUE(cv_if_footer);
    --IFレコード区分_フッタチェック
    IF (gv_if_footer IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_prof);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --ファイル名NULLチェック
    IF (iv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para1);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --相手システム名NULLチェック
    IF (iv_other_system IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para2);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --ファイルディレクトリNULLチェック
    IF (iv_file_dir IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para3);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --相手システム名不正チェック
    IF (iv_other_system <> cv_para_osystem) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                            gv_cnst_msg_if_para4);
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    WHEN init_err_expt THEN                           --*** 初期処理エラー ***
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
   * Procedure Name   : file_open
   * Description      : ファイルオープン処理(A-2,A-5)
   ***********************************************************************************/
  PROCEDURE file_open(
    iv_file_name    IN  VARCHAR2,            --   ファイル名
    iv_file_dir     IN  VARCHAR2,            --   ファイルディレクトリ
    iv_file_mode    IN  VARCHAR2,            --   ファイルモード(R:読み取り W:書き込み)
    of_file_handler OUT UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.START 
--    cn_record_byte CONSTANT NUMBER := 2047;  --ファイル読み込み文字数
    cn_record_byte CONSTANT NUMBER := 30000;  --ファイル読み込み文字数
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.END
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
    BEGIN
      --ファイルオープン
      of_file_handler := UTL_FILE.FOPEN(iv_file_dir,
                                        iv_file_name,
                                        iv_file_mode,
                                        cn_record_byte);
    EXCEPTION
      --ファイル名エラー
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_para5);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      --ファイルパスエラー
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_para6);
        lv_errbuf := lv_errmsg;
        RAISE fopen_err_expt;
      --アクセス権限エラー
      WHEN UTL_FILE.ACCESS_DENIED THEN
        lv_errmsg := xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                              gv_cnst_msg_if_acc);
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ処理(A-4,A-7)
   ***********************************************************************************/
  PROCEDURE file_close(
    iof_file_handler IN OUT UTL_FILE.FILE_TYPE, --   ファイルハンドラ
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.START
--    ov_errbuf           OUT VARCHAR2,           --   エラー・メッセージ           --# 固定 #
--    ov_retcode          OUT VARCHAR2,           --   リターン・コード             --# 固定 #
--    ov_errmsg           OUT VARCHAR2)           --   ユーザー・エラー・メッセージ --# 固定 #
    ov_errbuf        IN OUT VARCHAR2,           --   エラー・メッセージ           --# 固定 #
    ov_retcode       IN OUT VARCHAR2,           --   リターン・コード             --# 固定 #
    ov_errmsg        IN OUT VARCHAR2)           --   ユーザー・エラー・メッセージ --# 固定 #
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.END
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_close'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    --☆
    iof_file_handler_test UTL_FILE.FILE_TYPE ;
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto DEL.START
--    ov_retcode := cv_status_normal;
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto DEL.END
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --ファイルクローズ
    UTL_FILE.FCLOSE(iof_file_handler);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.START
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.START
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errbuf  := ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.START
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_errbuf  := ov_errbuf || cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- 2009/02/26 v1.3 出力ログ不正対応 T.Matsumoto MOD.END
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : file_read
   * Description      : ファイル読み込み処理(A-3)
   ***********************************************************************************/
  PROCEDURE file_read(
    if_file_handler  IN  UTL_FILE.FILE_TYPE, --   ファイルハンドラ
    o_file_data_tab  OUT g_file_data_ttype,  --   ファイルデータ
    ov_errbuf        OUT VARCHAR2,           --   エラー・メッセージ                  --# 固定 #
    ov_retcode       OUT VARCHAR2,           --   リターン・コード                    --# 固定 #
    ov_errmsg        OUT VARCHAR2)           --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_read'; -- プログラム名
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
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.START
--    lv_data  VARCHAR2(2047);  --ファイルデータ
    lv_data  VARCHAR2(30000);  --ファイルデータ
-- 2009/02/25 v1.2 ファイル読み込み時の文字列バッファ長不足暫定対応 T.Matsumoto MOD.END
    ln_cnt   NUMBER;          --配列の添字
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --初期化
    lv_data := NULL;
    ln_cnt  := 1;
    BEGIN
    --ループ処理
      <<file_read>>
      LOOP
        UTL_FILE.GET_LINE(if_file_handler,lv_data);
        IF (SUBSTR(lv_data,1,1) = gv_if_data) THEN
          --配列に格納
          o_file_data_tab(ln_cnt) := lv_data;
          ln_cnt := ln_cnt + 1;
        END IF;
        --対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;
      END LOOP file_read;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_read;
--
  /**********************************************************************************
   * Procedure Name   : file_write
   * Description      : ファイル書き込み処理(A-6)
   ***********************************************************************************/
  PROCEDURE file_write(
    if_file_handler IN  UTL_FILE.FILE_TYPE,  --   ファイルハンドラ
    i_file_data_tab IN  g_file_data_ttype,   --   ファイルデータ
    ov_errbuf       OUT VARCHAR2,            --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,            --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)            --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_write'; -- プログラム名
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
    ln_cnt   NUMBER;          --配列の添字
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --初期化
    ln_cnt  := 1;
    BEGIN
      --ループ処理
      <<file_write>>
      LOOP
        --ファイル書き込み
        UTL_FILE.PUT_LINE(if_file_handler,SUBSTR(i_file_data_tab(ln_cnt),2));
        --配列添字カウント
        ln_cnt        := ln_cnt + 1;
        --成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END LOOP file_write;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    --スキップ件数カウント
    gn_warn_cnt := gn_target_cnt - gn_normal_cnt;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END file_write;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name    IN  VARCHAR2,     --   ファイル名
    iv_other_system IN  VARCHAR2,     --   相手システム名
    iv_file_dir     IN  VARCHAR2,     --   ファイルディレクトリ
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_file_mode_r    CONSTANT VARCHAR2(1) := 'R';   -- ファイルモード(読み込み)
    cv_file_mode_w    CONSTANT VARCHAR2(1) := 'W';   -- ファイルモード(書き込み)
--
    -- *** ローカル変数 ***
    lf_file_handler   UTL_FILE.FILE_TYPE;            -- ファイルハンドル
    l_file_data_tab   g_file_data_ttype;             -- ファイルデータを格納する配列
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
    -- ===============================
    -- <初期処理>
    -- ===============================
    init(
      iv_file_name,      -- ファイル名
      iv_other_system,   -- 相手システム名
      iv_file_dir,       -- ファイルディレクトリ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイルオープン処理>
    -- ===============================
    file_open(
      iv_file_name,      -- ファイル名
      iv_file_dir,       -- ファイルディレクトリ
      cv_file_mode_r,    -- ファイルモード
      lf_file_handler,   -- ファイルハンドラ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイル読み込み処理>
    -- ===============================
    file_read(
      lf_file_handler,   -- ファイルハンドラ
      l_file_data_tab,   -- ファイルデータ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --ファイルクローズ処理
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- ===============================
        -- <ファイルクローズ処理>
        -- ===============================
        file_close(
          lf_file_handler,   -- ファイルハンドラ
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイルクローズ処理>
    -- ===============================
    file_close(
      lf_file_handler,   -- ファイルハンドラ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイルオープン処理>
    -- ===============================
    file_open(
      iv_file_name,      -- ファイル名
      iv_file_dir,       -- ファイルディレクトリ
      cv_file_mode_w,    -- ファイルモード
      lf_file_handler,   -- ファイルハンドラ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイル書き込み処理>
    -- ===============================
    file_write(
      lf_file_handler,   -- ファイルハンドラ
      l_file_data_tab,   -- ファイルデータ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --ファイルクローズ処理
      IF (UTL_FILE.IS_OPEN(lf_file_handler)) THEN
        -- ===============================
        -- <ファイルクローズ処理>
        -- ===============================
        file_close(
          lf_file_handler,   -- ファイルハンドラ
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ファイルクローズ処理>
    -- ===============================
    file_close(
      lf_file_handler,   -- ファイルハンドラ
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
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
    errbuf          OUT    VARCHAR2,         --   エラー・メッセージ  --# 固定 #
    retcode         OUT    VARCHAR2,         --   リターン・コード    --# 固定 #
    iv_file_name    IN     VARCHAR2,         --   ファイル名
    iv_other_system IN     VARCHAR2,         --   相手システム名
    iv_file_dir     IN     VARCHAR2          --   ファイルディレクトリ
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
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    cv_if_error_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- エラー終了メッセージ
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
       iv_file_name     -- ファイル名
      ,iv_other_system  -- 相手システム名
      ,iv_file_dir      -- ファイルディレクトリ
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --入力パラメータ出力
    --ファイル名
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_fnam,
                                          gv_cnst_tkn_fname,
                                          iv_file_name)
    );
    --相手システム名
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_osys,
                                          gv_cnst_tkn_osystem,
                                          iv_other_system)
    );
    --ファイルディレクトリ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_fdir,
                                          gv_cnst_tkn_fdir,
                                          iv_file_dir)
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --I/Fファイル名出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(gv_cnst_msg_kbn,
                                          gv_cnst_msg_if_ifna,
                                          gv_cnst_tkn_fname,
                                          iv_file_name)
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_if_error_msg;
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
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP005A01C;
/
