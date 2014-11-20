CREATE OR REPLACE PACKAGE BODY XXCCP009A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP009A02C(body)
 * Description      : 対向システムジョブ状況テーブル(アドオン)の更新を行います。
 * MD.050           : MD050_CCP_009_A02_対向システムジョブ状況更新処理
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  update_status          ステータス更新処理(A-2)
 *  submain                メイン処理プロシージャ(A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ(A-3)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Koji.Oomata      main新規作成
 *  2009-04-01    1.1   Masayuki.Sano    [障害番号：T1-0521]
 *                                       ・更新処理の検索条件の変更(列名変更)
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  --WHOカラム
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
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
  init_err_expt             EXCEPTION;     -- 初期処理エラー
  fopen_err_expt            EXCEPTION;     -- ファイルオープンエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name          CONSTANT VARCHAR2(100) := 'XXCCP009A02C';      -- パッケージ名
--
  cv_cnst_msg_kbn      CONSTANT VARCHAR2(5)   := 'XXCCP';             -- メッセージ区分
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_pk_request_id_val IN  VARCHAR2     -- 処理順付要求ID
    ,iv_status_code       IN  VARCHAR2     -- ステータスコード
    ,ov_errbuf            OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_required_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10004';  --必須項目未設定エラー
    cv_required_token     CONSTANT VARCHAR2(10)  := 'ITEM';              --必須項目未設定エラー用トークン
    cv_required_token_v1  CONSTANT VARCHAR2(10)  := 'REQUEST_ID';        --必須項目未設定エラー用トークン値1
    cv_required_token_v2  CONSTANT VARCHAR2(10)  := 'STATUS';            --必須項目未設定エラー用トークン値2
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
-- 
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --パラメータ必須チェック
    --処理順付要求ID
    IF (iv_pk_request_id_val IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name
                     ,cv_required_msg
                     ,cv_required_token
                     ,cv_required_token_v1
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --
    --ステータスコード
    IF (iv_status_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name
                     ,cv_required_msg
                     ,cv_required_token
                     ,cv_required_token_v2
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_err_expt;
    END IF;
    --
--
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : update_status
   * Description      : ステータス更新処理(A-2)
   ***********************************************************************************/
  PROCEDURE update_status(
     iv_pk_request_id_val IN  VARCHAR2     -- 処理順付要求ID
    ,iv_status_code       IN  VARCHAR2     -- ステータスコード
    ,ov_errbuf            OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_status'; -- プログラム名
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
    --対象件数+1
    gn_target_cnt := gn_target_cnt + 1;
    --
    --ステータス更新処理
    UPDATE xxccp_if_job_status xijs
    SET    xijs.status_code            = iv_status_code             --ステータス
          ,xijs.last_updated_by        = cn_last_updated_by         --最終更新者
          ,xijs.last_update_date       = cd_last_update_date        --最終更新日
          ,xijs.last_update_login      = cn_last_update_login       --最終更新ログインID
          ,xijs.request_id             = cn_request_id              --要求ID
          ,xijs.program_application_id = cn_program_application_id  --コンカレント・プログラム・アプリケーションID
          ,xijs.program_id             = cn_program_id              --コンカレント・プログラムID
          ,xijs.program_update_date    = cd_program_update_date     --プログラム更新日
--    WHERE  xijs.pk_request_id_val = iv_pk_request_id_val  --処理順付要求ID
    WHERE  xijs.request_id_val = iv_pk_request_id_val  --処理順付要求ID
    ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_status;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_pk_request_id_val IN  VARCHAR2     -- 処理順付要求ID
    ,iv_status_code       IN  VARCHAR2     -- ステータスコード
    ,ov_errbuf            OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2     -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
       iv_pk_request_id_val  -- 処理順付要求ID
      ,iv_status_code        -- ステータスコード
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <ステータス更新処理>
    -- ===============================
    update_status(
       iv_pk_request_id_val  -- 処理順付要求ID
      ,iv_status_code        -- ステータスコード
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      --エラー件数+1
      gn_error_cnt := gn_error_cnt + 1;
      --(エラー処理)
      RAISE global_process_expt;
    ELSE
      --成功件数+1
      gn_normal_cnt := gn_normal_cnt + 1;
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
    errbuf                  OUT    VARCHAR2,         -- エラーメッセージ #固定#
    retcode                 OUT    VARCHAR2,         -- エラーコード     #固定#
    iv_pk_request_id_val    IN     VARCHAR2,         -- 処理順付要求ID
    iv_status_code          IN     VARCHAR2          -- ステータスコード
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバックメッセージ
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_request_id_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00021'; -- 要求IDメッセージ
    cv_request_id_token CONSTANT VARCHAR2(10)  := 'REQ_ID';           -- 要求IDメッセージ用トークン
    cv_status_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00022'; -- ステータスメッセージ
    cv_status_token     CONSTANT VARCHAR2(10)  := 'STATUS';           -- ステータスメッセージ用トークン
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
       iv_pk_request_id_val  -- 処理順付要求ID
      ,iv_status_code        -- ステータスコード
      ,lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,lv_retcode           -- リターン・コード             --# 固定 #
      ,lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --入力パラメータ出力
    --要求ID
    --レポート出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_request_id_msg
                   ,cv_request_id_token
                   ,iv_pk_request_id_val
                 )
    );
    --ログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_request_id_msg
                   ,cv_request_id_token
                   ,iv_pk_request_id_val
                 )
    );
    --ステータス
    --レポート出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_status_msg
                   ,cv_status_token
                   ,iv_status_code
                 )
    );
    --ログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => xxccp_common_pkg.get_msg(
                    cv_cnst_msg_kbn
                   ,cv_status_msg
                   ,cv_status_token
                   ,iv_status_code
                 )
    );
    --空行挿入
    --レポート出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --ログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
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
    --空行挿入
    --レポート出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --ログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
END XXCCP009A02C;
/
