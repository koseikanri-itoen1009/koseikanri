CREATE OR REPLACE PACKAGE BODY APPS.XXCCP006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A01C(body)
 * Description      : 親子コンカレント終了ステータス監視
 * MD.050           : MD050_CCP_006_A01_親子コンカレント終了ステータス監視
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  chk_conc_status        コンカレントステータスチェック処理(共通処理)
 *  init                   初期処理(A-1)
 *  get_parent_conc_info   親コンカレント情報取得処理(A-2)
 *  exe_parent_conc        親コンカレント起動処理(A-3)
 *  wait_for_child_conc    子コンカレント終了待ち処理(A-4)
 *  end_conc               終了処理(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/15    1.0   Yohei Takayama   新規作成
 *  2009/03/11    1.1   Masayuki Sano    メッセージ表示不正対応
 *  2009/04/20    1.2   Masayuki Sano    障害対応T1_0443
 *                                       ・2階層目⇒3階層目まで参照可能となるように修正。
 *  2009/05/01    1.3   Masayuki.Sano    障害番号T1_0910対応(スキーマ名付加)
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
  --<exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP006A01C'; -- パッケージ名
  cv_flg_y         CONSTANT VARCHAR2(1)   := 'Y';            -- フラグ判断用'Y'
  cn_param_max_cnt CONSTANT NUMBER        := 97;             -- 親コンカレントパラメータの最大数
  cv_conc_p_flg    CONSTANT VARCHAR2(1)   := '1';            -- 親コンカレント
  cv_conc_c_flg    CONSTANT VARCHAR2(1)   := '2';            -- 子コンカレント
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- コンカレント引数情報格納用
  TYPE g_arg_info_ttype IS TABLE OF FND_CONCURRENT_REQUESTS.ARGUMENT1%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_err_msg_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_errmsg_tab          g_err_msg_ttype;        -- エラーメッセージ格納用
  gn_errmsg_cnt         NUMBER;                 -- エラーバッファ件数
  g_errbuf_tab          g_err_msg_ttype;        -- エラーバッファ格納用
  gn_errbuf_cnt         NUMBER;                 -- エラーメッセージ件数
  g_in_arg_info_tab     g_arg_info_ttype;       -- 入力項目：引数格納用
  gv_exe_request_id     VARCHAR2(5000);         -- 起動対象要求ID格納用
  gv_normal_request_id  VARCHAR2(5000);         -- 正常終了要求ID格納用
  gv_warning_request_id VARCHAR2(5000);         -- 警告終了要求ID格納用
  gv_error_request_id   VARCHAR2(5000);         -- エラー終了要求ID格納用
--
  /**********************************************************************************
   * Procedure Name   : chk_conc_status
   * Description      : コンカレントステータスチェック処理(共通処理)
   ***********************************************************************************/
  PROCEDURE chk_conc_status(
    iv_conc_flg   IN  VARCHAR2,     -- 1.チェック対象が親か子かの判断フラグ
    in_request_id IN  NUMBER,       -- 2.チェック対象要求ID
    in_interval   IN  NUMBER,       -- 3.ステータス監視間隔
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_conc_status'; -- プログラム名
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
    cv_appl_short_name    CONSTANT  VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_get_sts_err1_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10023';  -- ステータス取得失敗エラー1
    cv_expt_sts_err1_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10026';  -- ステータス異常終了エラー1
    cv_err_sts_err1_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10028';  -- エラー終了メッセージ1
    cv_warn_sts_err1_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10030';  -- 警告終了メッセージ1
    cv_get_sts_err2_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10024';  -- ステータス取得失敗エラー2
    cv_expt_sts_err2_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10027';  -- ステータス異常終了エラー2
    cv_err_sts_err2_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10029';  -- エラー終了メッセージ2
    cv_warn_sts_err2_msg  CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10031';  -- 警告終了メッセージ2
    cv_req_id_tkn         CONSTANT  VARCHAR2(10)  := 'REQ_ID';            -- トークン
    cv_phase_tkn          CONSTANT  VARCHAR2(10)  := 'PHASE';             -- トークン
    cv_status_tkn         CONSTANT  VARCHAR2(10)  := 'STATUS';            -- トークン
    cv_dev_pahse_complete CONSTANT  VARCHAR2(10)  := 'COMPLETE';          -- 処理結果フェーズ
    cv_dev_status_err     CONSTANT  VARCHAR2(10)  := 'ERROR';             -- 処理結果ステータス
    cv_dev_status_warn    CONSTANT  VARCHAR2(10)  := 'WARNING';           -- 処理結果ステータス
    cv_dev_status_norm    CONSTANT  VARCHAR2(10)  := 'NORMAL';            -- 処理結果ステータス
--
    -- *** ローカル変数 ***
    lv_get_sts_err_msg     VARCHAR2(100);   -- ステータス取得失敗エラー
    lv_expt_sts_err_msg    VARCHAR2(100);   -- ステータス異常終了エラー
    lv_err_sts_err_msg    VARCHAR2(100);   -- エラー終了メッセージ
    lv_warn_sts_err_msg   VARCHAR2(100);   -- 警告終了メッセージ
    lv_phase               VARCHAR2(100);   -- 要求フェーズ
    lv_status              VARCHAR2(100);   -- 要求ステータス
    lv_dev_phase           VARCHAR2(100);   -- 処理結果フェーズ
    lv_dev_status          VARCHAR2(100);   -- 処理結果ステータス
    lv_message             VARCHAR2(5000);  -- 処理結果メッセージ
    lb_result              BOOLEAN;         -- 待機処理結果
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    get_sts_err_expt       EXCEPTION;       -- ステータス取得失敗エラー
    sts_err_expt           EXCEPTION;       -- エラー終了例外(継続)
    sts_warn_expt          EXCEPTION;       -- 警告終了例外(継続)
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
    -- *****************************************************
    -- チェック対象判断フラグによりメッセージコードの設定
    -- *****************************************************
    -- 親コンカレントのチェックの場合
    IF ( iv_conc_flg = cv_conc_p_flg ) THEN
      lv_get_sts_err_msg   := cv_get_sts_err1_msg;   -- ステータス取得失敗エラー
      lv_expt_sts_err_msg  := cv_expt_sts_err1_msg;  -- ステータス異常終了エラー
      lv_err_sts_err_msg  := cv_err_sts_err1_msg;    -- エラー終了メッセージ
      lv_warn_sts_err_msg := cv_warn_sts_err1_msg;   -- 警告終了メッセージ
    -- 子コンカレントのチェックの場合
    ELSE
      lv_get_sts_err_msg   := cv_get_sts_err2_msg;   -- ステータス取得失敗エラー
      lv_expt_sts_err_msg  := cv_expt_sts_err2_msg;  -- ステータス異常終了エラー
      lv_err_sts_err_msg  := cv_err_sts_err2_msg;    -- エラー終了メッセージ
      lv_warn_sts_err_msg := cv_warn_sts_err2_msg;   -- 警告終了メッセージ
    END IF;
--
    -- コンカレントの終了ステータス取得
    lb_result :=  FND_CONCURRENT.WAIT_FOR_REQUEST(
                    request_id   => in_request_id
                    ,interval    => in_interval
                    ,max_wait    => NULL
                    ,phase       => lv_phase
                    ,status      => lv_status
                    ,dev_phase   => lv_dev_phase
                    ,dev_status  => lv_dev_status
                    ,message     => lv_message
                  );
--
    -- ステータス取得に失敗した場合(ステータス取得の成功/失敗判断)
    IF ( NOT lb_result ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => lv_get_sts_err_msg
                      ,iv_token_name1  => cv_req_id_tkn
                      ,iv_token_value1 => TO_CHAR(in_request_id)
                    );
      lv_errbuf := lv_errmsg;
--
      -- 親コンカレントのチェックの場合
      IF ( iv_conc_flg = cv_conc_p_flg ) THEN
        -- 処理終了
        RAISE get_sts_err_expt;
      -- 子コンカレントのチェックの場合
      ELSE
        -- 処理継続
        RAISE sts_err_expt;
      END IF;
--
    -- ステータス取得に成功した場合(ステータス取得の成功/失敗判断)
    ELSE
      -- 処理結果フェーズが完了以外の場合(処理結果フェーズ・処理結果ステータスの判断)
      IF (lv_dev_phase <> cv_dev_pahse_complete ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_expt_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      -- 処理結果フェーズが完了 かつ 処理結果ステータスがエラーの場合(処理結果フェーズ・処理結果ステータスの判断)
      ELSIF ( lv_dev_status = cv_dev_status_err ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_err_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      -- 処理結果フェーズが完了 かつ 処理結果ステータスが警告の場合(処理結果フェーズ・処理結果ステータスの判断)
      ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_warn_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_warn_expt;
--
      -- 処理結果フェーズが完了 かつ 処理結果ステータスが正常の場合(処理結果フェーズ・処理結果ステータスの判断)
      ELSIF ( lv_dev_status = cv_dev_status_norm ) THEN
        -- 正常件数のカウント
        gn_normal_cnt := gn_normal_cnt + 1;
        -- 正常終了要求IDの設定
        IF ( gv_normal_request_id IS NULL ) THEN
          gv_normal_request_id := TO_CHAR(in_request_id);
        ELSE
          gv_normal_request_id := gv_normal_request_id || ' , ' || TO_CHAR(in_request_id);
        END IF;
--
      -- 処理結果フェーズが完了 かつ 処理結果ステータスが上記以外の場合(処理結果フェーズ・処理結果ステータスの判断)
      ELSE
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => lv_expt_sts_err_msg
                        ,iv_token_name1  => cv_req_id_tkn
                        ,iv_token_value1 => TO_CHAR(in_request_id)
                        ,iv_token_name2  => cv_phase_tkn
                        ,iv_token_value2 => lv_dev_phase
                        ,iv_token_name3  => cv_status_tkn
                        ,iv_token_value3 => lv_dev_status
                      );
        lv_errbuf := lv_errmsg;
        RAISE sts_err_expt;
--
      END IF;    -- (処理結果フェーズ・処理結果ステータスの判断)
--
    END IF;  -- (ステータス取得の成功/失敗判断)
--
  EXCEPTION
    WHEN get_sts_err_expt THEN                           --*** ステータス取得失敗エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
--
    WHEN sts_err_expt THEN                               --*** エラー終了例外(継続) ***
      -- *** 任意で例外処理を記述する ****
      -- **************************************************
      -- 処理を継続するため、当処理を正常終了させる
      -- **************************************************
      -- エラー件数のカウント
      gn_error_cnt := gn_error_cnt + 1;
      -- エラー終了要求IDの設定
      IF ( gv_error_request_id IS NULL ) THEN
        gv_error_request_id := TO_CHAR(in_request_id);
      ELSE
        gv_error_request_id := gv_error_request_id || ' , ' || TO_CHAR(in_request_id);
      END IF;
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--
    WHEN sts_warn_expt THEN                              --*** 警告終了例外(継続) ***
      -- *** 任意で例外処理を記述する ****
      -- **************************************************
      -- 処理を継続するため、当処理を正常終了させる
      -- **************************************************
      -- 警告件数のカウント
      gn_warn_cnt := gn_warn_cnt + 1;
      -- 警告終了要求IDの設定
      IF ( gv_warning_request_id IS NULL ) THEN
        gv_warning_request_id := TO_CHAR(in_request_id);
      ELSE
        gv_warning_request_id := gv_warning_request_id || ' , ' || TO_CHAR(in_request_id);
      END IF;
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_conc_status;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_exe_appl_short_name IN VARCHAR2,  -- 1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name IN VARCHAR2,  -- 2.起動対象コンカレント短縮名
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_appl_short_name_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10020'; -- アプリケーション未入力エラー
    cv_conc_short_name_err_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10021'; -- コンカレント未入力エラー
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    required_err_expt     EXCEPTION;
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
    -- 起動対象アプリケーション短縮名の必須チェック
    IF ( iv_exe_appl_short_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_appl_short_name_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE required_err_expt;
    END IF;
--
    -- 起動対象コンカレント短縮名の必須チェック
    IF ( iv_exe_conc_short_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_conc_short_name_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE required_err_expt;
    END IF;
--
  EXCEPTION
    WHEN required_err_expt THEN                           --*** 必須エラー ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : get_parent_conc_info
   * Description      : 親コンカレント情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_parent_conc_info(
    iv_exe_appl_short_name   IN  VARCHAR2,           --1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name   IN  VARCHAR2,           --2.起動対象コンカレント短縮名
    on_parent_param_cnt      OUT NUMBER,             --3.親コンカレントパラメータ数
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parent_conc_info'; -- プログラム名
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
    cv_conc_param_field_nm   CONSTANT VARCHAR2(100) := '$SRS$.';  -- コンカレントパラメータのフィールド名
    cv_appl_short_name       CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_max_para_err_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10059'; -- コンカレントパラメータ最大件数超過ワーニング
--
    -- *** ローカル変数 ***
    ln_param_cnt        NUMBER;    -- 親コンカレントパラメータ数
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
    -- 親コンカレントのパラメータ数を取得
    BEGIN
      SELECT   COUNT(fdfcuv.descriptive_flexfield_name) param_cnt
      INTO     ln_param_cnt
      FROM     fnd_concurrent_programs_vl  fcpv                              -- コンカレントマスタ
              ,fnd_descr_flex_col_usage_vl fdfcuv                            -- コンカレントパラメータマスタ
              ,fnd_application_vl          fav                               -- アプリケーションマスタ
      WHERE   fav.application_short_name        = iv_exe_appl_short_name     -- アプリケーション短縮名
      AND     fav.application_id                = fcpv.application_id        -- アプリケーションID
      AND     fcpv.concurrent_program_name      = iv_exe_conc_short_name     -- コンカレントプログラム名
      AND     fcpv.application_id               = fdfcuv.application_id      -- アプリケーションID
      AND     fdfcuv.descriptive_flexfield_name = cv_conc_param_field_nm || fcpv.concurrent_program_name -- フィールド名
      AND     fdfcuv.enabled_flag               = cv_flg_y               -- 有効フラグ
      GROUP BY fdfcuv.application_id, fdfcuv.descriptive_flexfield_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_param_cnt := 0;
    END;
--
-- 2009/03/11 UPDATE START
--    on_parent_param_cnt := ln_param_cnt;
    IF ( ln_param_cnt > cn_param_max_cnt ) THEN
      -- 件数を最大件数へ修正
      on_parent_param_cnt := cn_param_max_cnt;
-- 2009/04/20 Ver.1.2 DELETE By Masayuki.Sano Start
--      -- 例外処理
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application => cv_appl_short_name
--                     ,iv_name        => cv_max_para_err_msg
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
-- 2009/04/20 Ver.1.2 DELETE By Masayuki.Sano End
    ELSE
      on_parent_param_cnt := ln_param_cnt;
    END IF;
-- 2009/03/11 UPDATE END
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
  END get_parent_conc_info;
--
  /**********************************************************************************
   * Procedure Name   : exe_parent_conc
   * Description      : 親コンカレント起動処理(A-3)
   ***********************************************************************************/
  PROCEDURE exe_parent_conc(
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.起動対象アプリケーション短縮名
    in_parent_param_cnt     IN   NUMBER,              -- 3.親コンカレントパラメータ数
    on_request_id           OUT  NUMBER,              -- 4.親コンカレント要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_parent_conc'; -- プログラム名
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
    -- プロファイル「XXCCP:親コンカレントステータス監視間隔」
    cv_parent_conc_time_pf_nm  CONSTANT VARCHAR2(100) := 'XXCCP1_CONC_WATCH_TIME';
    cv_appl_short_name         CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_profile_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10032'; -- プロファイル取得エラー
    cv_exe_conc_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10022'; -- コンカレントの起動失敗エラー
    cv_profile_name_tkn        CONSTANT VARCHAR2(100) := 'PROFILE_NAME';     -- トークン
--
    -- *** ローカル変数 ***
    lv_parent_conc_time  VARCHAR2(5000);               -- プロファイル「XXCCP:親コンカレントステータス監視間隔」格納用
    lt_request_id        fnd_concurrent_requests.request_id%TYPE;  -- 要求ID
    l_ed_arg_info_tab    g_arg_info_ttype;             -- 親コンカレント発行用引数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    sub_process_expt       EXCEPTION;         -- 処理部共通例外
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
    -- プロファイル「XXCCP:親コンカレントステータス監視間隔」の取得
    lv_parent_conc_time :=  FND_PROFILE.VALUE(
                              name => cv_parent_conc_time_pf_nm
                            );
    -- 取得したプロファイルの必須チェック
    IF ( lv_parent_conc_time IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_profile_name_tkn
                      ,iv_token_value1 => cv_parent_conc_time_pf_nm
                    );
      lv_errbuf := lv_errmsg;
      RAISE sub_process_expt;
    END IF;
--
    -- 親コンカレント発行用変数の初期化(CHR(0)を格納)
    <<ed_arg_init_loop>>
    FOR i IN 1..cn_param_max_cnt LOOP
      l_ed_arg_info_tab(i) := CHR(0);
    END LOOP ed_arg_init_loop;
--
    -- 親コンカレント発行用変数に作業用変数を格納
    IF ( in_parent_param_cnt > 0 ) THEN
      <<ed_arg_set_loop>>
      FOR i IN 1..in_parent_param_cnt LOOP
        l_ed_arg_info_tab(i) := g_in_arg_info_tab(i);
      END LOOP ed_arg_set_loop;
    END IF;
--
    -- 親コンカレントの実行
    lt_request_id :=  FND_REQUEST.SUBMIT_REQUEST(
                        application  => iv_exe_appl_short_name,
                        program      => iv_exe_conc_short_name,
                        description  => NULL,
                        start_time   => NULL,
                        sub_request  => NULL,
                        argument1    => l_ed_arg_info_tab(1),
                        argument2    => l_ed_arg_info_tab(2),
                        argument3    => l_ed_arg_info_tab(3),
                        argument4    => l_ed_arg_info_tab(4),
                        argument5    => l_ed_arg_info_tab(5),
                        argument6    => l_ed_arg_info_tab(6),
                        argument7    => l_ed_arg_info_tab(7),
                        argument8    => l_ed_arg_info_tab(8),
                        argument9    => l_ed_arg_info_tab(9),
                        argument10   => l_ed_arg_info_tab(10),
                        argument11   => l_ed_arg_info_tab(11),
                        argument12   => l_ed_arg_info_tab(12),
                        argument13   => l_ed_arg_info_tab(13),
                        argument14   => l_ed_arg_info_tab(14),
                        argument15   => l_ed_arg_info_tab(15),
                        argument16   => l_ed_arg_info_tab(16),
                        argument17   => l_ed_arg_info_tab(17),
                        argument18   => l_ed_arg_info_tab(18),
                        argument19   => l_ed_arg_info_tab(19),
                        argument20   => l_ed_arg_info_tab(20),
                        argument21   => l_ed_arg_info_tab(21),
                        argument22   => l_ed_arg_info_tab(22),
                        argument23   => l_ed_arg_info_tab(23),
                        argument24   => l_ed_arg_info_tab(24),
                        argument25   => l_ed_arg_info_tab(25),
                        argument26   => l_ed_arg_info_tab(26),
                        argument27   => l_ed_arg_info_tab(27),
                        argument28   => l_ed_arg_info_tab(28),
                        argument29   => l_ed_arg_info_tab(29),
                        argument30   => l_ed_arg_info_tab(30),
                        argument31   => l_ed_arg_info_tab(31),
                        argument32   => l_ed_arg_info_tab(32),
                        argument33   => l_ed_arg_info_tab(33),
                        argument34   => l_ed_arg_info_tab(34),
                        argument35   => l_ed_arg_info_tab(35),
                        argument36   => l_ed_arg_info_tab(36),
                        argument37   => l_ed_arg_info_tab(37),
                        argument38   => l_ed_arg_info_tab(38),
                        argument39   => l_ed_arg_info_tab(39),
                        argument40   => l_ed_arg_info_tab(40),
                        argument41   => l_ed_arg_info_tab(41),
                        argument42   => l_ed_arg_info_tab(42),
                        argument43   => l_ed_arg_info_tab(43),
                        argument44   => l_ed_arg_info_tab(44),
                        argument45   => l_ed_arg_info_tab(45),
                        argument46   => l_ed_arg_info_tab(46),
                        argument47   => l_ed_arg_info_tab(47),
                        argument48   => l_ed_arg_info_tab(48),
                        argument49   => l_ed_arg_info_tab(49),
                        argument50   => l_ed_arg_info_tab(50),
                        argument51   => l_ed_arg_info_tab(51),
                        argument52   => l_ed_arg_info_tab(52),
                        argument53   => l_ed_arg_info_tab(53),
                        argument54   => l_ed_arg_info_tab(54),
                        argument55   => l_ed_arg_info_tab(55),
                        argument56   => l_ed_arg_info_tab(56),
                        argument57   => l_ed_arg_info_tab(57),
                        argument58   => l_ed_arg_info_tab(58),
                        argument59   => l_ed_arg_info_tab(59),
                        argument60   => l_ed_arg_info_tab(60),
                        argument61   => l_ed_arg_info_tab(61),
                        argument62   => l_ed_arg_info_tab(62),
                        argument63   => l_ed_arg_info_tab(63),
                        argument64   => l_ed_arg_info_tab(64),
                        argument65   => l_ed_arg_info_tab(65),
                        argument66   => l_ed_arg_info_tab(66),
                        argument67   => l_ed_arg_info_tab(67),
                        argument68   => l_ed_arg_info_tab(68),
                        argument69   => l_ed_arg_info_tab(69),
                        argument70   => l_ed_arg_info_tab(70),
                        argument71   => l_ed_arg_info_tab(71),
                        argument72   => l_ed_arg_info_tab(72),
                        argument73   => l_ed_arg_info_tab(73),
                        argument74   => l_ed_arg_info_tab(74),
                        argument75   => l_ed_arg_info_tab(75),
                        argument76   => l_ed_arg_info_tab(76),
                        argument77   => l_ed_arg_info_tab(77),
                        argument78   => l_ed_arg_info_tab(78),
                        argument79   => l_ed_arg_info_tab(79),
                        argument80   => l_ed_arg_info_tab(80),
                        argument81   => l_ed_arg_info_tab(81),
                        argument82   => l_ed_arg_info_tab(82),
                        argument83   => l_ed_arg_info_tab(83),
                        argument84   => l_ed_arg_info_tab(84),
                        argument85   => l_ed_arg_info_tab(85),
                        argument86   => l_ed_arg_info_tab(86),
                        argument87   => l_ed_arg_info_tab(87),
                        argument88   => l_ed_arg_info_tab(88),
                        argument89   => l_ed_arg_info_tab(89),
                        argument90   => l_ed_arg_info_tab(90),
                        argument91   => l_ed_arg_info_tab(91),
                        argument92   => l_ed_arg_info_tab(92),
                        argument93   => l_ed_arg_info_tab(93),
                        argument94   => l_ed_arg_info_tab(94),
                        argument95   => l_ed_arg_info_tab(95),
                        argument96   => l_ed_arg_info_tab(96),
                        argument97   => l_ed_arg_info_tab(97)
                      );
    -- 親コンカレントの発行に失敗した場合
    IF ( lt_request_id <= 0 ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application   => cv_appl_short_name
                      ,iv_name         => cv_exe_conc_err_msg
                    );
      lv_errbuf := lv_errmsg;
      RAISE sub_process_expt;
    END IF;
--
    -- コミット
    COMMIT;
    -- 対象件数のカウントアップ
    gn_target_cnt := gn_target_cnt + 1;
    -- 起動対象要求IDの格納
    gv_exe_request_id := TO_CHAR(lt_request_id);
    on_request_id     := lt_request_id;
--
    -- コンカレントステータスチェック処理(共通処理)の呼び出し
    chk_conc_status(
      iv_conc_flg      =>  cv_conc_p_flg
      ,in_request_id   =>  lt_request_id
      ,in_interval     =>  TO_NUMBER(lv_parent_conc_time)
      ,ov_errbuf       =>  lv_errbuf
      ,ov_retcode      =>  lv_retcode
      ,ov_errmsg       =>  lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE sub_process_expt;
    END IF;
--
  EXCEPTION
    WHEN sub_process_expt THEN                           --*** 処理部共通例外処理 ***
      -- *** 任意で例外処理を記述する ****
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
  END exe_parent_conc;
--
  /**********************************************************************************
   * Procedure Name   : wait_for_child_conc
   * Description      : 子コンカレント終了待ち処理(A-4)
   ***********************************************************************************/
  PROCEDURE wait_for_child_conc(
    in_request_id       IN NUMBER,     -- 1.親コンカレント要求ID
    iv_child_conc_time  IN VARCHAR2,   -- 2.子コンカレントステータス監視間隔
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_for_child_conc'; -- プログラム名
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
    cv_appl_short_name         CONSTANT VARCHAR2(10)   := 'XXCCP';             -- アドオン：共通・IF領域
    cv_child_conc_err_msg      CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-10025';  --子コンカレント未起動エラー
--
    -- *** ローカル変数 ***
    ln_conc_time       NUMBER;           -- 子コンカレントステータス監視間隔格納用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 子コンカレント要求ID取得カーソル
    CURSOR get_child_conc_cur
    IS
      SELECT  request_id  request_id                 -- 要求ID(2階層目)
      FROM    fnd_concurrent_requests  fcq           -- 要求管理マスタ
      WHERE   fcq.parent_request_id = in_request_id  -- 親要求ID
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano Start
      UNION ALL
      SELECT  fcq3.request_id                        -- 要求ID(3階層目)
      FROM    fnd_concurrent_requests  fcq2          -- 要求管理マスタ(2階層目)
             ,fnd_concurrent_requests  fcq3          -- 要求管理マスタ(3階層目)
      WHERE   fcq2.parent_request_id = in_request_id -- 親要求ID
      AND     fcq3.parent_request_id = fcq2.request_id
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano End
      ORDER BY request_id
      ;
    -- 子コンカレント要求IDレコード型
    get_child_conc_rec  get_child_conc_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
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
    -- 子コンカレント要求IDの取得
    OPEN  get_child_conc_cur;
    FETCH get_child_conc_cur INTO get_child_conc_rec;
--
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano Start
--    -- 子コンカレント要求IDが0件の場合
--    IF ( get_child_conc_cur%NOTFOUND ) THEN
--      -- カーソルのクローズ
--      CLOSE get_child_conc_cur;
--      -- メッセージ取得
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_child_conc_err_msg
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_process_expt;
--    END IF;
-- 2009/04/20 Ver.1.2 Add By Masayuki.Sano End
--
    -- ******************************************************
    -- 子コンカレントについて、ステータスチェックを行う。
    -- ******************************************************
    -- 子コンカレントステータス監視間隔の設定
    IF ( iv_child_conc_time IS NULL ) THEN
      ln_conc_time := 3;
    ELSE
      ln_conc_time := TO_NUMBER(iv_child_conc_time);
    END IF;
--
    <<get_child_conc_loop>>
    WHILE get_child_conc_cur%FOUND LOOP
      -- 対象件数のカウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
      -- コンカレントステータスチェック処理(共通機能)の呼び出し
      chk_conc_status(
        iv_conc_flg      =>  cv_conc_c_flg
        ,in_request_id   =>  get_child_conc_rec.request_id
        ,in_interval     =>  ln_conc_time
        ,ov_errbuf       =>  lv_errbuf
        ,ov_retcode      =>  lv_retcode
        ,ov_errmsg       =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        -- カーソルのクローズ
        CLOSE  get_child_conc_cur;
        RAISE global_process_expt;
      END IF;
--
      -- 次レコードの取得
      FETCH get_child_conc_cur INTO get_child_conc_rec;
--
    END LOOP get_child_conc_loop;
--
    -- カーソルのクローズ
    CLOSE  get_child_conc_cur;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END wait_for_child_conc;
--
  /**********************************************************************************
   * Procedure Name   : end_conc
   * Description      : 終了処理(A-5)
   ***********************************************************************************/
  PROCEDURE end_conc(
    iv_retcode              IN  VARCHAR2,                     -- 1.処理ステータス
    iv_exe_appl_short_name  IN  VARCHAR2,                     -- 2.起動対象アプリケーション短縮名
    iv_exe_conc_short_name  IN  VARCHAR2,                     -- 3.起動対象コンカレント短縮名
    iv_child_conc_time      IN  VARCHAR2,                     -- 4.子コンカレントステータス監視間隔
    in_parent_param_cnt     IN  NUMBER,                       -- 5.親コンカレントパラメータ数
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_conc'; -- プログラム名
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
    cv_appl_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';
-- 2009/03/11 UPDATE START
--    cv_appl_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10002';  -- アプリケーション短縮名メッセージ
--    cv_conc_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10003';  -- コンカレント短縮名メッセージ
--    cv_child_conc_tm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10004';  -- 子コンカレント監視間隔メッセージ
--    cv_in_arg_msg            CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10005';  -- 引数メッセージ
--    cv_exe_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10006';  -- 起動対象要求IDメッセージ
--    cv_norm_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10007';  -- 正常終了要求IDメッセージ
--    cv_warn_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00008';  -- 警告終了要求IDメッセージ
--    cv_err_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-10009';  -- エラー終了要求IDメッセージ
    cv_appl_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00002';  -- アプリケーション短縮名メッセージ
    cv_conc_short_nm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00003';  -- コンカレント短縮名メッセージ
    cv_child_conc_tm_msg     CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00004';  -- 子コンカレント監視間隔メッセージ
    cv_in_arg_msg            CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00005';  -- 引数メッセージ
    cv_exe_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00006';  -- 起動対象要求IDメッセージ
    cv_norm_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00007';  -- 正常終了要求IDメッセージ
    cv_warn_request_id_msg   CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00008';  -- 警告終了要求IDメッセージ
    cv_err_request_id_msg    CONSTANT  VARCHAR2(100) := 'APP-XXCCP1-00009';  -- エラー終了要求IDメッセージ
-- 2009/03/11 UPDATE END
    cv_target_rec_msg        CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg       CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg         CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token             CONSTANT VARCHAR2(10)   := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg            CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg              CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_warn_rec_msg          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-00001';  -- 警告件数メッセージ
    cv_err_msg               CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-10008';  -- エラー終了メッセージ
--
    cv_ap_short_name_tkn     CONSTANT  VARCHAR2(100) := 'AP_SHORT_NAME';     -- トークン
    cv_conc_short_name_tkn   CONSTANT  VARCHAR2(100) := 'CONC_SHORT_NAME';   -- トークン
    cv_time_tkn              CONSTANT  VARCHAR2(100) := 'TIME';              -- トークン
    cv_number_tkn            CONSTANT  VARCHAR2(100) := 'NUMBER';            -- トークン
    cv_param_value_tkn       CONSTANT  VARCHAR2(100) := 'PARAM_VALUE';       -- トークン
    cv_req_id_tkn            CONSTANT  VARCHAR2(100) := 'REQ_ID';            -- トークン
--
    -- *** ローカル変数 ***
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
    -- **********************************************
    -- 入力項目のレポート出力
    -- **********************************************
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 起動対象アプリケーション短縮名
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_appl_short_nm_msg
                    ,iv_token_name1  => cv_ap_short_name_tkn
                    ,iv_token_value1 => iv_exe_appl_short_name
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- 起動対象コンカレント短縮名
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_conc_short_nm_msg
                    ,iv_token_name1  => cv_conc_short_name_tkn
                    ,iv_token_value1 => iv_exe_conc_short_name
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- 子コンカレントステータス監視間隔
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_child_conc_tm_msg
                    ,iv_token_name1  => cv_time_tkn
                    ,iv_token_value1 => iv_child_conc_time
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => lv_errmsg
    );
    -- 引数
    IF (in_parent_param_cnt > 0 ) THEN
      <<output_in_info_loop>>
      FOR i IN 1..in_parent_param_cnt LOOP
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application   => cv_appl_short_name
                        ,iv_name         => cv_in_arg_msg
                        ,iv_token_name1  => cv_number_tkn
                        ,iv_token_value1 => TO_CHAR(i)
                        ,iv_token_name2  => cv_param_value_tkn
                        ,iv_token_value2 => g_in_arg_info_tab(i)
                      );
        FND_FILE.PUT_LINE(
            which   => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
            which   => FND_FILE.LOG
            ,buff   => lv_errmsg
        );
      END LOOP output_in_info_loop;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG
        ,buff   => ''
    );
--
    -- *************************************************
    -- 終了ステータスの設定(ステータスチェックで発生した警告やエラーの判断)
    -- エラー中止以外の場合のみステータスを設定
    -- *************************************************
    IF ( iv_retcode = cv_status_normal ) THEN
      -- エラー件数が1件以上の場合
      IF ( gn_error_cnt >= 1 ) THEN
        lv_retcode := cv_status_error;
      -- エラー件数が0件 かつ 警告件数が1件以上の場合
      ELSIF ( gn_warn_cnt >= 1 ) THEN
        lv_retcode := cv_status_warn;
      ELSE
        lv_retcode := iv_retcode;
      END IF;
    ELSE
      lv_retcode := iv_retcode;
    END IF;
--
    -- **********************************************
    -- 要求ID項目のレポート出力
    -- **********************************************
    -- 起動対象要求IDメッセージ
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_exe_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_exe_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- 正常終了要求IDメッセージ
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_norm_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_normal_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- 警告終了要求IDメッセージ
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_warn_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_warning_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    -- エラー終了要求IDメッセージ
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                    iv_application   => cv_appl_short_name
                    ,iv_name         => cv_err_request_id_msg
                    ,iv_token_name1  => cv_req_id_tkn
                    ,iv_token_value1 => gv_error_request_id
                  );
    FND_FILE.PUT_LINE(
        which   => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- **********************************************
    -- エラーメッセージ出力
    -- **********************************************
    --エラー出力
    IF ( gn_errmsg_cnt > 0 ) THEN
      <<output_err_msg_loop>>
      FOR i IN 1..gn_errmsg_cnt LOOP
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
          ,buff   => g_errmsg_tab(i) --ユーザー・エラーメッセージ
        );
      END LOOP output_err_msg_loop;
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
--
    IF ( gn_errbuf_cnt > 0 ) THEN
      <<output_err_buf_loop>>
      FOR i IN 1..gn_errbuf_cnt LOOP
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => g_errbuf_tab(i) --エラーメッセージ
        );
      END LOOP output_err_buf_loop;
    END IF;
--
    -- **********************************************
    -- 件数のレポート出力
    -- **********************************************
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_err_msg;
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
--
    ov_retcode := lv_retcode;
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
  END end_conc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.起動対象コンカレント短縮名
    iv_child_conc_time      IN   VARCHAR2,            -- 3.子コンカレントステータス監視間隔
    iv_param1               IN   VARCHAR2,            -- 4.引数1
    iv_param2               IN   VARCHAR2,            -- 5.引数2
    iv_param3               IN   VARCHAR2,            -- 6.引数3
    iv_param4               IN   VARCHAR2,            -- 7.引数4
    iv_param5               IN   VARCHAR2,            -- 8.引数5
    iv_param6               IN   VARCHAR2,            -- 9.引数6
    iv_param7               IN   VARCHAR2,            -- 10.引数7
    iv_param8               IN   VARCHAR2,            -- 11.引数8
    iv_param9               IN   VARCHAR2,            -- 12.引数9
    iv_param10              IN   VARCHAR2,            -- 13.引数10
    iv_param11              IN   VARCHAR2,            -- 14.引数11
    iv_param12              IN   VARCHAR2,            -- 15.引数12
    iv_param13              IN   VARCHAR2,            -- 16.引数13
    iv_param14              IN   VARCHAR2,            -- 17.引数14
    iv_param15              IN   VARCHAR2,            -- 18.引数15
    iv_param16              IN   VARCHAR2,            -- 19.引数16
    iv_param17              IN   VARCHAR2,            -- 20.引数17
    iv_param18              IN   VARCHAR2,            -- 21.引数18
    iv_param19              IN   VARCHAR2,            -- 22.引数19
    iv_param20              IN   VARCHAR2,            -- 23.引数20
    iv_param21              IN   VARCHAR2,            -- 24.引数21
    iv_param22              IN   VARCHAR2,            -- 25.引数22
    iv_param23              IN   VARCHAR2,            -- 26.引数23
    iv_param24              IN   VARCHAR2,            -- 27.引数24
    iv_param25              IN   VARCHAR2,            -- 28.引数25
    iv_param26              IN   VARCHAR2,            -- 29.引数26
    iv_param27              IN   VARCHAR2,            -- 30.引数27
    iv_param28              IN   VARCHAR2,            -- 31.引数28
    iv_param29              IN   VARCHAR2,            -- 32.引数29
    iv_param30              IN   VARCHAR2,            -- 33.引数30
    iv_param31              IN   VARCHAR2,            -- 34.引数31
    iv_param32              IN   VARCHAR2,            -- 35.引数32
    iv_param33              IN   VARCHAR2,            -- 36.引数33
    iv_param34              IN   VARCHAR2,            -- 37.引数34
    iv_param35              IN   VARCHAR2,            -- 38.引数35
    iv_param36              IN   VARCHAR2,            -- 39.引数36
    iv_param37              IN   VARCHAR2,            -- 40.引数37
    iv_param38              IN   VARCHAR2,            -- 41.引数38
    iv_param39              IN   VARCHAR2,            -- 42.引数39
    iv_param40              IN   VARCHAR2,            -- 43.引数40
    iv_param41              IN   VARCHAR2,            -- 44.引数41
    iv_param42              IN   VARCHAR2,            -- 45.引数42
    iv_param43              IN   VARCHAR2,            -- 46.引数43
    iv_param44              IN   VARCHAR2,            -- 47.引数44
    iv_param45              IN   VARCHAR2,            -- 48.引数45
    iv_param46              IN   VARCHAR2,            -- 49.引数46
    iv_param47              IN   VARCHAR2,            -- 50.引数47
    iv_param48              IN   VARCHAR2,            -- 51.引数48
    iv_param49              IN   VARCHAR2,            -- 52.引数49
    iv_param50              IN   VARCHAR2,            -- 53.引数50
    iv_param51              IN   VARCHAR2,            -- 54.引数51
    iv_param52              IN   VARCHAR2,            -- 55.引数52
    iv_param53              IN   VARCHAR2,            -- 56.引数53
    iv_param54              IN   VARCHAR2,            -- 57.引数54
    iv_param55              IN   VARCHAR2,            -- 58.引数55
    iv_param56              IN   VARCHAR2,            -- 59.引数56
    iv_param57              IN   VARCHAR2,            -- 60.引数57
    iv_param58              IN   VARCHAR2,            -- 61.引数58
    iv_param59              IN   VARCHAR2,            -- 62.引数59
    iv_param60              IN   VARCHAR2,            -- 63.引数60
    iv_param61              IN   VARCHAR2,            -- 64.引数61
    iv_param62              IN   VARCHAR2,            -- 65.引数62
    iv_param63              IN   VARCHAR2,            -- 66.引数63
    iv_param64              IN   VARCHAR2,            -- 67.引数64
    iv_param65              IN   VARCHAR2,            -- 68.引数65
    iv_param66              IN   VARCHAR2,            -- 69.引数66
    iv_param67              IN   VARCHAR2,            -- 70.引数67
    iv_param68              IN   VARCHAR2,            -- 71.引数68
    iv_param69              IN   VARCHAR2,            -- 72.引数69
    iv_param70              IN   VARCHAR2,            -- 73.引数70
    iv_param71              IN   VARCHAR2,            -- 74.引数71
    iv_param72              IN   VARCHAR2,            -- 75.引数72
    iv_param73              IN   VARCHAR2,            -- 76.引数73
    iv_param74              IN   VARCHAR2,            -- 77.引数74
    iv_param75              IN   VARCHAR2,            -- 78.引数75
    iv_param76              IN   VARCHAR2,            -- 79.引数76
    iv_param77              IN   VARCHAR2,            -- 80.引数77
    iv_param78              IN   VARCHAR2,            -- 81.引数78
    iv_param79              IN   VARCHAR2,            -- 82.引数79
    iv_param80              IN   VARCHAR2,            -- 83.引数80
    iv_param81              IN   VARCHAR2,            -- 84.引数81
    iv_param82              IN   VARCHAR2,            -- 85.引数82
    iv_param83              IN   VARCHAR2,            -- 86.引数83
    iv_param84              IN   VARCHAR2,            -- 87.引数84
    iv_param85              IN   VARCHAR2,            -- 88.引数85
    iv_param86              IN   VARCHAR2,            -- 89.引数86
    iv_param87              IN   VARCHAR2,            -- 90.引数87
    iv_param88              IN   VARCHAR2,            -- 91.引数88
    iv_param89              IN   VARCHAR2,            -- 92.引数89
    iv_param90              IN   VARCHAR2,            -- 93.引数90
    iv_param91              IN   VARCHAR2,            -- 94.引数91
    iv_param92              IN   VARCHAR2,            -- 95.引数92
    iv_param93              IN   VARCHAR2,            -- 96.引数93
    iv_param94              IN   VARCHAR2,            -- 97.引数94
    iv_param95              IN   VARCHAR2,            -- 98.引数95
    iv_param96              IN   VARCHAR2,            -- 99.引数96
    iv_param97              IN   VARCHAR2,            -- 100.引数97
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_parent_param_cnt        NUMBER;                                   -- 親コンカレントパラメータ数
    lt_parent_request_id       fnd_concurrent_requests.request_id%TYPE;  -- 親コンカレント要求ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- グローバル変数の初期化
    gv_exe_request_id     := NULL;         -- 起動対象要求ID格納用
    gv_normal_request_id  := NULL;         -- 正常終了要求ID格納用
    gv_warning_request_id := NULL;         -- 警告終了要求ID格納用
    gv_error_request_id   := NULL;         -- エラー終了要求ID格納用
    gn_errmsg_cnt         := 0;            -- エラーメッセージ件数
    gn_errbuf_cnt         := 0;            -- エラーバッファ件数
--
    -- 入力項目：引数を作業用変数に格納
    g_in_arg_info_tab(1)   := iv_param1;
    g_in_arg_info_tab(2)   := iv_param2;
    g_in_arg_info_tab(3)   := iv_param3;
    g_in_arg_info_tab(4)   := iv_param4;
    g_in_arg_info_tab(5)   := iv_param5;
    g_in_arg_info_tab(6)   := iv_param6;
    g_in_arg_info_tab(7)   := iv_param7;
    g_in_arg_info_tab(8)   := iv_param8;
    g_in_arg_info_tab(9)   := iv_param9;
    g_in_arg_info_tab(10)  := iv_param10;
    g_in_arg_info_tab(11)  := iv_param11;
    g_in_arg_info_tab(12)  := iv_param12;
    g_in_arg_info_tab(13)  := iv_param13;
    g_in_arg_info_tab(14)  := iv_param14;
    g_in_arg_info_tab(15)  := iv_param15;
    g_in_arg_info_tab(16)  := iv_param16;
    g_in_arg_info_tab(17)  := iv_param17;
    g_in_arg_info_tab(18)  := iv_param18;
    g_in_arg_info_tab(19)  := iv_param19;
    g_in_arg_info_tab(20)  := iv_param20;
    g_in_arg_info_tab(21)  := iv_param21;
    g_in_arg_info_tab(22)  := iv_param22;
    g_in_arg_info_tab(23)  := iv_param23;
    g_in_arg_info_tab(24)  := iv_param24;
    g_in_arg_info_tab(25)  := iv_param25;
    g_in_arg_info_tab(26)  := iv_param26;
    g_in_arg_info_tab(27)  := iv_param27;
    g_in_arg_info_tab(28)  := iv_param28;
    g_in_arg_info_tab(29)  := iv_param29;
    g_in_arg_info_tab(30)  := iv_param30;
    g_in_arg_info_tab(31)  := iv_param31;
    g_in_arg_info_tab(32)  := iv_param32;
    g_in_arg_info_tab(33)  := iv_param33;
    g_in_arg_info_tab(34)  := iv_param34;
    g_in_arg_info_tab(35)  := iv_param35;
    g_in_arg_info_tab(36)  := iv_param36;
    g_in_arg_info_tab(37)  := iv_param37;
    g_in_arg_info_tab(38)  := iv_param38;
    g_in_arg_info_tab(39)  := iv_param39;
    g_in_arg_info_tab(40)  := iv_param40;
    g_in_arg_info_tab(41)  := iv_param41;
    g_in_arg_info_tab(42)  := iv_param42;
    g_in_arg_info_tab(43)  := iv_param43;
    g_in_arg_info_tab(44)  := iv_param44;
    g_in_arg_info_tab(45)  := iv_param45;
    g_in_arg_info_tab(46)  := iv_param46;
    g_in_arg_info_tab(47)  := iv_param47;
    g_in_arg_info_tab(48)  := iv_param48;
    g_in_arg_info_tab(49)  := iv_param49;
    g_in_arg_info_tab(50)  := iv_param50;
    g_in_arg_info_tab(51)  := iv_param51;
    g_in_arg_info_tab(52)  := iv_param52;
    g_in_arg_info_tab(53)  := iv_param53;
    g_in_arg_info_tab(54)  := iv_param54;
    g_in_arg_info_tab(55)  := iv_param55;
    g_in_arg_info_tab(56)  := iv_param56;
    g_in_arg_info_tab(57)  := iv_param57;
    g_in_arg_info_tab(58)  := iv_param58;
    g_in_arg_info_tab(59)  := iv_param59;
    g_in_arg_info_tab(60)  := iv_param60;
    g_in_arg_info_tab(61)  := iv_param61;
    g_in_arg_info_tab(62)  := iv_param62;
    g_in_arg_info_tab(63)  := iv_param63;
    g_in_arg_info_tab(64)  := iv_param64;
    g_in_arg_info_tab(65)  := iv_param65;
    g_in_arg_info_tab(66)  := iv_param66;
    g_in_arg_info_tab(67)  := iv_param67;
    g_in_arg_info_tab(68)  := iv_param68;
    g_in_arg_info_tab(69)  := iv_param69;
    g_in_arg_info_tab(70)  := iv_param70;
    g_in_arg_info_tab(71)  := iv_param71;
    g_in_arg_info_tab(72)  := iv_param72;
    g_in_arg_info_tab(73)  := iv_param73;
    g_in_arg_info_tab(74)  := iv_param74;
    g_in_arg_info_tab(75)  := iv_param75;
    g_in_arg_info_tab(76)  := iv_param76;
    g_in_arg_info_tab(77)  := iv_param77;
    g_in_arg_info_tab(78)  := iv_param78;
    g_in_arg_info_tab(79)  := iv_param79;
    g_in_arg_info_tab(80)  := iv_param80;
    g_in_arg_info_tab(81)  := iv_param81;
    g_in_arg_info_tab(82)  := iv_param82;
    g_in_arg_info_tab(83)  := iv_param83;
    g_in_arg_info_tab(84)  := iv_param84;
    g_in_arg_info_tab(85)  := iv_param85;
    g_in_arg_info_tab(86)  := iv_param86;
    g_in_arg_info_tab(87)  := iv_param87;
    g_in_arg_info_tab(88)  := iv_param88;
    g_in_arg_info_tab(89)  := iv_param89;
    g_in_arg_info_tab(90)  := iv_param90;
    g_in_arg_info_tab(91)  := iv_param91;
    g_in_arg_info_tab(92)  := iv_param92;
    g_in_arg_info_tab(93)  := iv_param93;
    g_in_arg_info_tab(94)  := iv_param94;
    g_in_arg_info_tab(95)  := iv_param95;
    g_in_arg_info_tab(96)  := iv_param96;
    g_in_arg_info_tab(97)  := iv_param97;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_exe_appl_short_name   =>  iv_exe_appl_short_name    -- 起動対象アプリケーション短縮名
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name    -- 起動対象コンカレント短縮名
      ,ov_errbuf               =>  lv_errbuf
      ,ov_retcode              =>  lv_retcode
      ,ov_errmsg               =>  lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      gn_errmsg_cnt := gn_errmsg_cnt + 1;
      g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
      gn_errbuf_cnt := gn_errbuf_cnt + 1;
      g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
    END IF;
--
    -- ===============================
    -- 親コンカレント情報取得処理(A-2)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      get_parent_conc_info(
        iv_exe_appl_short_name   =>  iv_exe_appl_short_name    -- 起動対象アプリケーション短縮名
        ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name    -- 起動対象コンカレント短縮名
        ,on_parent_param_cnt     =>  ln_parent_param_cnt       -- 親コンカレントパラメータ数
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(エラー処理)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- 親コンカレント起動処理(A-3)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      exe_parent_conc(
        iv_exe_appl_short_name  =>  iv_exe_appl_short_name           -- 1.起動対象アプリケーション短縮名
        ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name          -- 2.起動対象アプリケーション短縮名
        ,in_parent_param_cnt     =>  ln_parent_param_cnt             -- 3.親コンカレントパラメータ数
        ,on_request_id           =>  lt_parent_request_id            -- 4.親コンカレント要求ID
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(エラー処理)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000); 
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- 子コンカレント終了待ち処理(A-4)
    -- ===============================
    IF ( lv_retcode = cv_status_normal ) THEN
      wait_for_child_conc(
        in_request_id            =>  lt_parent_request_id  -- 親コンカレント要求ID
        ,iv_child_conc_time      =>  iv_child_conc_time    -- 子コンカレントステータス監視間隔
        ,ov_errbuf               =>  lv_errbuf
        ,ov_retcode              =>  lv_retcode
        ,ov_errmsg               =>  lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        --(エラー処理)
        gn_errmsg_cnt := gn_errmsg_cnt + 1;
        g_errmsg_tab(gn_errmsg_cnt) := lv_errmsg;
        gn_errbuf_cnt := gn_errbuf_cnt + 1;
        g_errbuf_tab(gn_errbuf_cnt) := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
    END IF;
--
    -- ===============================
    -- 終了処理(A-5)
    -- ===============================
    end_conc(
      iv_retcode               =>  lv_retcode
      ,iv_exe_appl_short_name  =>  iv_exe_appl_short_name
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name
      ,iv_child_conc_time      =>  iv_child_conc_time
      ,in_parent_param_cnt     =>  ln_parent_param_cnt
      ,ov_errbuf               =>  lv_errbuf
      ,ov_retcode              =>  lv_retcode
      ,ov_errmsg               =>  lv_errmsg
    );
--
    ov_retcode := lv_retcode;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_exe_appl_short_name  IN   VARCHAR2,            -- 1.起動対象アプリケーション短縮名
    iv_exe_conc_short_name  IN   VARCHAR2,            -- 2.起動対象コンカレント短縮名
    iv_child_conc_time      IN   VARCHAR2,            -- 3.子コンカレントステータス監視間隔
    iv_param1               IN   VARCHAR2  DEFAULT NULL,            -- 4.引数1
    iv_param2               IN   VARCHAR2  DEFAULT NULL,            -- 5.引数2
    iv_param3               IN   VARCHAR2  DEFAULT NULL,            -- 6.引数3
    iv_param4               IN   VARCHAR2  DEFAULT NULL,            -- 7.引数4
    iv_param5               IN   VARCHAR2  DEFAULT NULL,            -- 8.引数5
    iv_param6               IN   VARCHAR2  DEFAULT NULL,            -- 9.引数6
    iv_param7               IN   VARCHAR2  DEFAULT NULL,            -- 10.引数7
    iv_param8               IN   VARCHAR2  DEFAULT NULL,            -- 11.引数8
    iv_param9               IN   VARCHAR2  DEFAULT NULL,            -- 12.引数9
    iv_param10              IN   VARCHAR2  DEFAULT NULL,            -- 13.引数10
    iv_param11              IN   VARCHAR2  DEFAULT NULL,            -- 14.引数11
    iv_param12              IN   VARCHAR2  DEFAULT NULL,            -- 15.引数12
    iv_param13              IN   VARCHAR2  DEFAULT NULL,            -- 16.引数13
    iv_param14              IN   VARCHAR2  DEFAULT NULL,            -- 17.引数14
    iv_param15              IN   VARCHAR2  DEFAULT NULL,            -- 18.引数15
    iv_param16              IN   VARCHAR2  DEFAULT NULL,            -- 19.引数16
    iv_param17              IN   VARCHAR2  DEFAULT NULL,            -- 20.引数17
    iv_param18              IN   VARCHAR2  DEFAULT NULL,            -- 21.引数18
    iv_param19              IN   VARCHAR2  DEFAULT NULL,            -- 22.引数19
    iv_param20              IN   VARCHAR2  DEFAULT NULL,            -- 23.引数20
    iv_param21              IN   VARCHAR2  DEFAULT NULL,            -- 24.引数21
    iv_param22              IN   VARCHAR2  DEFAULT NULL,            -- 25.引数22
    iv_param23              IN   VARCHAR2  DEFAULT NULL,            -- 26.引数23
    iv_param24              IN   VARCHAR2  DEFAULT NULL,            -- 27.引数24
    iv_param25              IN   VARCHAR2  DEFAULT NULL,            -- 28.引数25
    iv_param26              IN   VARCHAR2  DEFAULT NULL,            -- 29.引数26
    iv_param27              IN   VARCHAR2  DEFAULT NULL,            -- 30.引数27
    iv_param28              IN   VARCHAR2  DEFAULT NULL,            -- 31.引数28
    iv_param29              IN   VARCHAR2  DEFAULT NULL,            -- 32.引数29
    iv_param30              IN   VARCHAR2  DEFAULT NULL,            -- 33.引数30
    iv_param31              IN   VARCHAR2  DEFAULT NULL,            -- 34.引数31
    iv_param32              IN   VARCHAR2  DEFAULT NULL,            -- 35.引数32
    iv_param33              IN   VARCHAR2  DEFAULT NULL,            -- 36.引数33
    iv_param34              IN   VARCHAR2  DEFAULT NULL,            -- 37.引数34
    iv_param35              IN   VARCHAR2  DEFAULT NULL,            -- 38.引数35
    iv_param36              IN   VARCHAR2  DEFAULT NULL,            -- 39.引数36
    iv_param37              IN   VARCHAR2  DEFAULT NULL,            -- 40.引数37
    iv_param38              IN   VARCHAR2  DEFAULT NULL,            -- 41.引数38
    iv_param39              IN   VARCHAR2  DEFAULT NULL,            -- 42.引数39
    iv_param40              IN   VARCHAR2  DEFAULT NULL,            -- 43.引数40
    iv_param41              IN   VARCHAR2  DEFAULT NULL,            -- 44.引数41
    iv_param42              IN   VARCHAR2  DEFAULT NULL,            -- 45.引数42
    iv_param43              IN   VARCHAR2  DEFAULT NULL,            -- 46.引数43
    iv_param44              IN   VARCHAR2  DEFAULT NULL,            -- 47.引数44
    iv_param45              IN   VARCHAR2  DEFAULT NULL,            -- 48.引数45
    iv_param46              IN   VARCHAR2  DEFAULT NULL,            -- 49.引数46
    iv_param47              IN   VARCHAR2  DEFAULT NULL,            -- 50.引数47
    iv_param48              IN   VARCHAR2  DEFAULT NULL,            -- 51.引数48
    iv_param49              IN   VARCHAR2  DEFAULT NULL,            -- 52.引数49
    iv_param50              IN   VARCHAR2  DEFAULT NULL,            -- 53.引数50
    iv_param51              IN   VARCHAR2  DEFAULT NULL,            -- 54.引数51
    iv_param52              IN   VARCHAR2  DEFAULT NULL,            -- 55.引数52
    iv_param53              IN   VARCHAR2  DEFAULT NULL,            -- 56.引数53
    iv_param54              IN   VARCHAR2  DEFAULT NULL,            -- 57.引数54
    iv_param55              IN   VARCHAR2  DEFAULT NULL,            -- 58.引数55
    iv_param56              IN   VARCHAR2  DEFAULT NULL,            -- 59.引数56
    iv_param57              IN   VARCHAR2  DEFAULT NULL,            -- 60.引数57
    iv_param58              IN   VARCHAR2  DEFAULT NULL,            -- 61.引数58
    iv_param59              IN   VARCHAR2  DEFAULT NULL,            -- 62.引数59
    iv_param60              IN   VARCHAR2  DEFAULT NULL,            -- 63.引数60
    iv_param61              IN   VARCHAR2  DEFAULT NULL,            -- 64.引数61
    iv_param62              IN   VARCHAR2  DEFAULT NULL,            -- 65.引数62
    iv_param63              IN   VARCHAR2  DEFAULT NULL,            -- 66.引数63
    iv_param64              IN   VARCHAR2  DEFAULT NULL,            -- 67.引数64
    iv_param65              IN   VARCHAR2  DEFAULT NULL,            -- 68.引数65
    iv_param66              IN   VARCHAR2  DEFAULT NULL,            -- 69.引数66
    iv_param67              IN   VARCHAR2  DEFAULT NULL,            -- 70.引数67
    iv_param68              IN   VARCHAR2  DEFAULT NULL,            -- 71.引数68
    iv_param69              IN   VARCHAR2  DEFAULT NULL,            -- 72.引数69
    iv_param70              IN   VARCHAR2  DEFAULT NULL,            -- 73.引数70
    iv_param71              IN   VARCHAR2  DEFAULT NULL,            -- 74.引数71
    iv_param72              IN   VARCHAR2  DEFAULT NULL,            -- 75.引数72
    iv_param73              IN   VARCHAR2  DEFAULT NULL,            -- 76.引数73
    iv_param74              IN   VARCHAR2  DEFAULT NULL,            -- 77.引数74
    iv_param75              IN   VARCHAR2  DEFAULT NULL,            -- 78.引数75
    iv_param76              IN   VARCHAR2  DEFAULT NULL,            -- 79.引数76
    iv_param77              IN   VARCHAR2  DEFAULT NULL,            -- 80.引数77
    iv_param78              IN   VARCHAR2  DEFAULT NULL,            -- 81.引数78
    iv_param79              IN   VARCHAR2  DEFAULT NULL,            -- 82.引数79
    iv_param80              IN   VARCHAR2  DEFAULT NULL,            -- 83.引数80
    iv_param81              IN   VARCHAR2  DEFAULT NULL,            -- 84.引数81
    iv_param82              IN   VARCHAR2  DEFAULT NULL,            -- 85.引数82
    iv_param83              IN   VARCHAR2  DEFAULT NULL,            -- 86.引数83
    iv_param84              IN   VARCHAR2  DEFAULT NULL,            -- 87.引数84
    iv_param85              IN   VARCHAR2  DEFAULT NULL,            -- 88.引数85
    iv_param86              IN   VARCHAR2  DEFAULT NULL,            -- 89.引数86
    iv_param87              IN   VARCHAR2  DEFAULT NULL,            -- 90.引数87
    iv_param88              IN   VARCHAR2  DEFAULT NULL,            -- 91.引数88
    iv_param89              IN   VARCHAR2  DEFAULT NULL,            -- 92.引数89
    iv_param90              IN   VARCHAR2  DEFAULT NULL,            -- 93.引数90
    iv_param91              IN   VARCHAR2  DEFAULT NULL,            -- 94.引数91
    iv_param92              IN   VARCHAR2  DEFAULT NULL,            -- 95.引数92
    iv_param93              IN   VARCHAR2  DEFAULT NULL,            -- 96.引数93
    iv_param94              IN   VARCHAR2  DEFAULT NULL,            -- 97.引数94
    iv_param95              IN   VARCHAR2  DEFAULT NULL,            -- 98.引数95
    iv_param96              IN   VARCHAR2  DEFAULT NULL,            -- 99.引数96
    iv_param97              IN   VARCHAR2  DEFAULT NULL             -- 100.引数97
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
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_err_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- エラー終了メッセージ
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
      iv_exe_appl_short_name   =>  iv_exe_appl_short_name          -- 1.起動対象アプリケーション短縮名
      ,iv_exe_conc_short_name  =>  iv_exe_conc_short_name          -- 2.起動対象アプリケーション短縮名
      ,iv_child_conc_time      =>  iv_child_conc_time              -- 3.子コンカレントステータス監視間隔
      ,iv_param1               =>  iv_param1                       -- 4.引数1
      ,iv_param2               =>  iv_param2                       -- 5.引数2
      ,iv_param3               =>  iv_param3                       -- 6.引数3
      ,iv_param4               =>  iv_param4                       -- 7.引数4
      ,iv_param5               =>  iv_param5                       -- 8.引数5
      ,iv_param6               =>  iv_param6                       -- 9.引数6
      ,iv_param7               =>  iv_param7                       -- 10.引数7
      ,iv_param8               =>  iv_param8                       -- 11.引数8
      ,iv_param9               =>  iv_param9                       -- 12.引数9
      ,iv_param10              =>  iv_param10                      -- 13.引数10
      ,iv_param11              =>  iv_param11                      -- 14.引数11
      ,iv_param12              =>  iv_param12                      -- 15.引数12
      ,iv_param13              =>  iv_param13                      -- 16.引数13
      ,iv_param14              =>  iv_param14                      -- 17.引数14
      ,iv_param15              =>  iv_param15                      -- 18.引数15
      ,iv_param16              =>  iv_param16                      -- 19.引数16
      ,iv_param17              =>  iv_param17                      -- 20.引数17
      ,iv_param18              =>  iv_param18                      -- 21.引数18
      ,iv_param19              =>  iv_param19                      -- 22.引数19
      ,iv_param20              =>  iv_param20                      -- 23.引数20
      ,iv_param21              =>  iv_param21                      -- 24.引数21
      ,iv_param22              =>  iv_param22                      -- 25.引数22
      ,iv_param23              =>  iv_param23                      -- 26.引数23
      ,iv_param24              =>  iv_param24                      -- 27.引数24
      ,iv_param25              =>  iv_param25                      -- 28.引数25
      ,iv_param26              =>  iv_param26                      -- 29.引数26
      ,iv_param27              =>  iv_param27                      -- 30.引数27
      ,iv_param28              =>  iv_param28                      -- 31.引数28
      ,iv_param29              =>  iv_param29                      -- 32.引数29
      ,iv_param30              =>  iv_param30                      -- 33.引数30
      ,iv_param31              =>  iv_param31                      -- 34.引数31
      ,iv_param32              =>  iv_param32                      -- 35.引数32
      ,iv_param33              =>  iv_param33                      -- 36.引数33
      ,iv_param34              =>  iv_param34                      -- 37.引数34
      ,iv_param35              =>  iv_param35                      -- 38.引数35
      ,iv_param36              =>  iv_param36                      -- 39.引数36
      ,iv_param37              =>  iv_param37                      -- 40.引数37
      ,iv_param38              =>  iv_param38                      -- 41.引数38
      ,iv_param39              =>  iv_param39                      -- 42.引数39
      ,iv_param40              =>  iv_param40                      -- 43.引数40
      ,iv_param41              =>  iv_param41                      -- 44.引数41
      ,iv_param42              =>  iv_param42                      -- 45.引数42
      ,iv_param43              =>  iv_param43                      -- 46.引数43
      ,iv_param44              =>  iv_param44                      -- 47.引数44
      ,iv_param45              =>  iv_param45                      -- 48.引数45
      ,iv_param46              =>  iv_param46                      -- 49.引数46
      ,iv_param47              =>  iv_param47                      -- 50.引数47
      ,iv_param48              =>  iv_param48                      -- 51.引数48
      ,iv_param49              =>  iv_param49                      -- 52.引数49
      ,iv_param50              =>  iv_param50                      -- 53.引数50
      ,iv_param51              =>  iv_param51                      -- 54.引数51
      ,iv_param52              =>  iv_param52                      -- 55.引数52
      ,iv_param53              =>  iv_param53                      -- 56.引数53
      ,iv_param54              =>  iv_param54                      -- 57.引数54
      ,iv_param55              =>  iv_param55                      -- 58.引数55
      ,iv_param56              =>  iv_param56                      -- 59.引数56
      ,iv_param57              =>  iv_param57                      -- 60.引数57
      ,iv_param58              =>  iv_param58                      -- 61.引数58
      ,iv_param59              =>  iv_param59                      -- 62.引数59
      ,iv_param60              =>  iv_param60                      -- 63.引数60
      ,iv_param61              =>  iv_param61                      -- 64.引数61
      ,iv_param62              =>  iv_param62                      -- 65.引数62
      ,iv_param63              =>  iv_param63                      -- 66.引数63
      ,iv_param64              =>  iv_param64                      -- 67.引数64
      ,iv_param65              =>  iv_param65                      -- 68.引数65
      ,iv_param66              =>  iv_param66                      -- 69.引数66
      ,iv_param67              =>  iv_param67                      -- 70.引数67
      ,iv_param68              =>  iv_param68                      -- 71.引数68
      ,iv_param69              =>  iv_param69                      -- 72.引数69
      ,iv_param70              =>  iv_param70                      -- 73.引数70
      ,iv_param71              =>  iv_param71                      -- 74.引数71
      ,iv_param72              =>  iv_param72                      -- 75.引数72
      ,iv_param73              =>  iv_param73                      -- 76.引数73
      ,iv_param74              =>  iv_param74                      -- 77.引数74
      ,iv_param75              =>  iv_param75                      -- 78.引数75
      ,iv_param76              =>  iv_param76                      -- 79.引数76
      ,iv_param77              =>  iv_param77                      -- 80.引数77
      ,iv_param78              =>  iv_param78                      -- 81.引数78
      ,iv_param79              =>  iv_param79                      -- 82.引数79
      ,iv_param80              =>  iv_param80                      -- 83.引数80
      ,iv_param81              =>  iv_param81                      -- 84.引数81
      ,iv_param82              =>  iv_param82                      -- 85.引数82
      ,iv_param83              =>  iv_param83                      -- 86.引数83
      ,iv_param84              =>  iv_param84                      -- 87.引数84
      ,iv_param85              =>  iv_param85                      -- 88.引数85
      ,iv_param86              =>  iv_param86                      -- 89.引数86
      ,iv_param87              =>  iv_param87                      -- 90.引数87
      ,iv_param88              =>  iv_param88                      -- 91.引数88
      ,iv_param89              =>  iv_param89                      -- 92.引数89
      ,iv_param90              =>  iv_param90                      -- 93.引数90
      ,iv_param91              =>  iv_param91                      -- 94.引数91
      ,iv_param92              =>  iv_param92                      -- 95.引数92
      ,iv_param93              =>  iv_param93                      -- 96.引数93
      ,iv_param94              =>  iv_param94                      -- 97.引数94
      ,iv_param95              =>  iv_param95                      -- 98.引数95
      ,iv_param96              =>  iv_param96                      -- 99.引数96
      ,iv_param97              =>  iv_param97                      -- 100.引数97
      ,ov_errbuf               =>  lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode              =>  lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg               =>  lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
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
END XXCCP006A01C;
/
