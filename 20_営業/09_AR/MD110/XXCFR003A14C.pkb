CREATE OR REPLACE PACKAGE BODY XXCFR003A14C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFR003A14C
 * Description     : 汎用請求起動処理
 * MD.050          : MD050_CFR_003_A14_汎用請求起動処理
 * MD.070          : MD050_CFR_003_A14_汎用請求起動処理
 * Version         : 1.1
 *
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  get_conc_name   P         発行対象コンカレントプログラム名取得プロシージャ
 *  submit_request  P         コンカレント発行プロシージャ
 *  wait_request    P         コンカレント監視プロシージャ
 *  end_proc        P         終了処理プロシージャ
 *  submain         P         汎用請求起動処理実行部
 *  main            P         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-04    1.0  SCS 安川 智博 初回作成
 *  2009-09-18    1.1  SCS 萱原 伸哉 AR仕様変更IE535対応
 ************************************************************************/

--
--#######################  固定グローバル定数宣言部 START   #######################
--

  cv_status_normal   CONSTANT VARCHAR2(1) := '0';  -- 正常終了
  cv_status_warn     CONSTANT VARCHAR2(1) := '1';   --警告
  cv_status_error    CONSTANT VARCHAR2(1) := '2';   --エラー
  cv_msg_part        CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont        CONSTANT VARCHAR2(3) := '.';

  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A14C';  -- パッケージ名

--
--##############################  固定部 END   ####################################
--

  --===============================================================
  -- グローバル定数
  --===============================================================

  cv_xxcfr_app_name  CONSTANT VARCHAR2(10) := 'XXCFR';  -- アドオン会計 AR のアプリケーション短縮名
  cv_xxccp_app_name  CONSTANT VARCHAR2(10) := 'XXCCP';  -- アドオン：共通・IF領域のアプリケーション短縮名

  -- メッセージ番号
  cv_msg_cfr_00002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00002';
  cv_msg_cfr_00004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00004';
  cv_msg_cfr_00012  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00012';
  cv_msg_cfr_00013  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00013';
  cv_msg_cfr_00014  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00014';
  cv_msg_cfr_00020  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00020';
  cv_msg_cfr_00021  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00021';
  cv_msg_cfr_00022  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00022';
  cv_msg_cfr_00025  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFR1-00025';

  cv_msg_ccp_90000  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90000';
  cv_msg_ccp_90001  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90001';
  cv_msg_ccp_90002  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90002';
  cv_msg_ccp_90004  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90004';
  cv_msg_ccp_90006  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90006';
  cv_msg_ccp_90007  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCCP1-90007';

  -- メッセージトークン
  cv_tkn_param_name CONSTANT VARCHAR2(30) := 'PARAM_NAME';   -- コンカレントパラメータ名
  cv_tkn_param_val  CONSTANT VARCHAR2(30) := 'PARAM_VAL';    -- コンカレントパラメータ値
  cv_tkn_prof_name  CONSTANT VARCHAR2(30) := 'PROF_NAME';    -- プロファイルオプション名
  cv_tkn_prog_name  CONSTANT VARCHAR2(30) := 'PROGRAM_NAME'; -- コンカレントプログラム名
  cv_tkn_sqlerrm    CONSTANT VARCHAR2(30) := 'SQLERRM';      -- エラーメッセージ
  cv_tkn_req_id     CONSTANT VARCHAR2(30) := 'REQ_ID';       -- コンカレント要求ID
  cv_tkn_count      CONSTANT VARCHAR2(30) := 'COUNT';        -- 処理件数

  -- プロファイルオプション
  cv_prof_name_wait_interval  CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCFR1_GENERAL_INVOICE_INTERVAL';
  cv_prof_name_wait_max       CONSTANT fnd_profile_options_tl.profile_option_name%TYPE := 'XXCFR1_GENERAL_INVOICE_MAX_WAIT';

  -- 発行対象コンカレントプログラム短縮名
  cv_003A06C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A06C';  -- 汎用店別請求
  cv_003A07C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A07C';  -- 汎用伝票別請求
  cv_003A08C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A08C';  -- 汎用商品（全明細）
  cv_003A09C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A09C';  -- 汎用商品（単品毎集計）
  cv_003A10C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A10C';  -- 汎用商品（店単品毎集計）
  cv_003A11C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A11C';  -- 汎用商品（単価毎集計）
  cv_003A12C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A12C';  -- 汎用商品（店単価毎集計）
  cv_003A13C_name  CONSTANT fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXCFR003A13C';  -- 汎用（店コラム毎集計）

  -- コンカレントパラメータ値'Y/N'
  cv_conc_param_y CONSTANT VARCHAR2(1) := 'Y';
  cv_conc_param_n CONSTANT VARCHAR2(1) := 'N';

  -- コンカレントdevフェーズ
  cv_dev_phase_complete CONSTANT VARCHAR2(30) := 'COMPLETE';  -- '完了'

  -- コンカレントdevステータス
  cv_dev_status_normal  CONSTANT VARCHAR2(30) := 'NORMAL';   -- '正常'
  cv_dev_status_warn    CONSTANT VARCHAR2(30) := 'WARNING';  -- '警告'
  cv_dev_status_err     CONSTANT VARCHAR2(30) := 'ERROR';    -- 'エラー';

  --===============================================================
  -- グローバル変数
  --===============================================================
  gv_wait_interval       fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視間隔
  gv_wait_max            fnd_profile_option_values.profile_option_value%TYPE;  -- コンカレント監視最大時間

  gn_target_count        PLS_INTEGER := 0;  -- 処理対象件数
  gn_normal_count        PLS_INTEGER := 0;  -- 正常終了件数
  gn_warn_count          PLS_INTEGER := 0;  -- 警告終了件数
  gn_err_count           PLS_INTEGER := 0;  -- エラー終了件数

  --===============================================================
  -- グローバルレコードタイプ
  --===============================================================
  -- 実行コンカレント一覧・レコードタイプ
  TYPE g_conc_list_rtype IS RECORD(
    conc_prog_name      fnd_concurrent_programs.concurrent_program_name%TYPE,          -- コンカレントプログラム短縮名
    user_conc_prog_name fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE,  -- ユーザ・コンカレントプログラム名
    request_id          NUMBER,                                                        -- コンカレント要求ID
    dev_phase           VARCHAR2(100),                                                 -- コンカレントプログラム実行フェーズ
    dev_status          VARCHAR2(100)                                                  -- コンカレントプログラム終了ステータス
  );

  --===============================================================
  -- グローバルテーブルタイプ
  --===============================================================
  -- 実行コンカレント一覧・テーブルタイプ
  TYPE g_conc_list_ttype IS TABLE OF g_conc_list_rtype INDEX BY PLS_INTEGER;

  --===============================================================
  -- グローバルテーブル
  --===============================================================
  -- 実行コンカレント一覧テーブル
  g_conc_list_tab g_conc_list_ttype;

  --===============================================================
  -- グローバル例外
  --===============================================================
  global_process_expt       EXCEPTION; -- 関数例外
  global_api_expt           EXCEPTION; -- 共通関数例外
  global_api_others_expt    EXCEPTION; -- 共通関数OTHERS例外
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000); -- 共通関数例外(ORA-20000)とglobal_api_others_exptをマッピング

  /**********************************************************************************
   * Procedure Name   : get_conc_name
   * Description      : コンカレントプログラム名取得処理
   ***********************************************************************************/
  PROCEDURE get_conc_name(
    iv_exec_003A06C  IN  VARCHAR2,    -- 汎用店別請求
    iv_exec_003A07C  IN  VARCHAR2,    -- 汎用伝票別請求
    iv_exec_003A08C  IN  VARCHAR2,    -- 汎用商品（全明細）
    iv_exec_003A09C  IN  VARCHAR2,    -- 汎用商品（単品毎集計）
    iv_exec_003A10C  IN  VARCHAR2,    -- 汎用商品（店単品毎集計）
    iv_exec_003A11C  IN  VARCHAR2,    -- 汎用商品（単価毎集計）
    iv_exec_003A12C  IN  VARCHAR2,    -- 汎用商品（店単価毎集計）
    iv_exec_003A13C  IN  VARCHAR2,    -- 汎用（店コラム毎集計）
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS

--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_conc_name';  -- プログラム名
--
--##############################  固定部 END   ##################################
--

    --===============================================================
    -- ローカル変数
    --===============================================================
    ln_tab_count  PLS_INTEGER := 0;  -- 実行コンカレント一覧テーブル索引

    --===============================================================
    -- ローカルカーソル
    --===============================================================
    -- コンカレント名取得カーソル
    CURSOR get_conc_prog_name_cur(
      iv_conc_prog_name IN VARCHAR2
    )
    IS
      SELECT fcpv.user_concurrent_program_name user_concurrent_program_name
      FROM fnd_application fa,
           fnd_concurrent_programs_vl fcpv
      WHERE fa.application_short_name = cv_xxcfr_app_name
        AND fcpv.concurrent_program_name = iv_conc_prog_name
        AND fcpv.application_id = fcpv.application_id;


  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    IF (iv_exec_003A06C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A06C_name;
      OPEN get_conc_prog_name_cur(cv_003A06C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A07C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A07C_name;
      OPEN get_conc_prog_name_cur(cv_003A07C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A08C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A08C_name;
      OPEN get_conc_prog_name_cur(cv_003A08C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A09C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A09C_name;
      OPEN get_conc_prog_name_cur(cv_003A09C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A10C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A10C_name;
      OPEN get_conc_prog_name_cur(cv_003A10C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A11C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A11C_name;
      OPEN get_conc_prog_name_cur(cv_003A11C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A12C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A12C_name;
      OPEN get_conc_prog_name_cur(cv_003A12C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;
    IF (iv_exec_003A13C = cv_conc_param_y) THEN
      ln_tab_count := ln_tab_count + 1;
      g_conc_list_tab(ln_tab_count).conc_prog_name := cv_003A13C_name;
      OPEN get_conc_prog_name_cur(cv_003A13C_name);
      FETCH get_conc_prog_name_cur INTO g_conc_list_tab(ln_tab_count).user_conc_prog_name;
      CLOSE get_conc_prog_name_cur;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END get_conc_name;

  /**********************************************************************************
   * Procedure Name   : submit_request
   * Description      : コンカレント発行プロシージャ
   ***********************************************************************************/
  PROCEDURE submit_request(
    iv_target_date      IN  VARCHAR2,
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1         IN  VARCHAR2,
    iv_cust_code        IN  VARCHAR2,
-- Modify 2009.09.18 Ver1.1 End
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request';  -- プログラム名
--
--##############################  固定部 END   ##################################
--

--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--

    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_request_id  NUMBER;      -- コンカレント要求ID
    ln_tab_ind     PLS_INTEGER := 0; -- 実行コンカレント一覧テーブル索引
-- Add 2009.09.18 Ver1.1 Start
    lv_cust_class  VARCHAR2(30); --顧客区分取得用変数
-- Add 2009.09.18 Ver1.1 End

    -- ===============================
    -- ローカル例外
    -- ===============================
    submit_request_expt  EXCEPTION;  -- コンカレント発行エラー例外

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
-- Modify 2009.09.18 Ver1.1 Start
    --顧客区分取得
    SELECT hca.customer_class_code
    INTO lv_cust_class
    FROM hz_cust_accounts    hca
        ,xxcmm_cust_accounts  xxca
    WHERE hca.cust_account_id  = xxca.customer_id
      AND xxca.customer_code = iv_cust_code;

-- Modify 2009.09.18 Ver1.1 End
    <<submit_request_loop>>
    FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
      ln_tab_ind := ln_tab_ind + 1;

      -- コンカレント発行
      ln_request_id :=
      FND_REQUEST.SUBMIT_REQUEST(application => cv_xxcfr_app_name,                  -- アプリケーション短縮名
                                 program     => g_conc_list_tab(i).conc_prog_name,  -- コンカレントプログラム名
                                 argument1   => iv_target_date,                     -- コンカレントパラメータ(締日)
-- Modify 2009.09.18 Ver1.1 Start
--                                 argument2   => iv_ar_code1                         -- コンカレントパラメータ(売掛コード（請求書）)
                                 argument2   => iv_cust_code,                       -- コンカレントパラメータ(顧客コード)
                                 argument3   => lv_cust_class                       -- コンカレントパラメータ(顧客区分)
-- Modify 2009.09.18 Ver1.1 Start
                                );

      IF (ln_request_id = 0) THEN
        RAISE submit_request_expt;
      ELSE
        COMMIT;
        g_conc_list_tab(i).request_id := ln_request_id;

        -- 要求発行メッセージ出力
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                          xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                   iv_name => cv_msg_cfr_00020,
                                                   iv_token_name1 => cv_tkn_prog_name,
                                                   iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name,
                                                   iv_token_name2 => cv_tkn_req_id,
                                                   iv_token_value2 => g_conc_list_tab(i).request_id
                                                  )
                         );
      END IF;

    END LOOP submit_request_loop;

  EXCEPTION
    -- *** 要求発行失敗時 ***
    WHEN submit_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_REQUEST.SUBMIT_REQUESTでスタックされたエラーメッセージを取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00012,
                                            iv_token_name1 => cv_tkn_prog_name,
                                            iv_token_value1 => g_conc_list_tab(ln_tab_ind).user_conc_prog_name
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submit_request;

  /**********************************************************************************
   * Procedure Name   : wait_request
   * Description      : コンカレント監視プロシージャ
   ***********************************************************************************/
  PROCEDURE wait_request(
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wait_request';  -- プログラム名
--
--##############################  固定部 END   ##################################
--

--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--

    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_tab_ind      PLS_INTEGER := 0; -- 実行コンカレント一覧テーブル索引
    lb_wait_request BOOLEAN;          -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_phase        VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_status       VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_phase    VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_dev_status   VARCHAR2(100);    -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数
    lv_message      VARCHAR2(5000);   -- FND_CONCURRENT.WAIT_FOR_REQUESTの戻り値格納用変数

    -- ===============================
    -- ローカル例外
    -- ===============================
    wait_for_request_expt  EXCEPTION;  -- コンカレント監視エラー例外

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    <<wait_request_loop>>
    FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
      ln_tab_ind := ln_tab_ind + 1;

      -- コンカレント要求監視
      lb_wait_request := FND_CONCURRENT.WAIT_FOR_REQUEST(request_id => g_conc_list_tab(i).request_id,
                                                         interval => gv_wait_interval,
                                                         max_wait => gv_wait_max,
                                                         phase => lv_phase,
                                                         status => lv_status,
                                                         dev_phase => lv_dev_phase,
                                                         dev_status => lv_dev_status,
                                                         message => lv_message
                                                        );

      IF (lb_wait_request) THEN
        g_conc_list_tab(i).dev_phase := lv_dev_phase;
        g_conc_list_tab(i).dev_status := lv_dev_status;

        IF (lv_dev_phase = cv_dev_phase_complete)
          AND (lv_dev_status = cv_dev_status_normal)
        THEN
          -- 正常終了の場合
          gn_normal_count := gn_normal_count + 1;
          -- 正常終了メッセージ出力
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00021,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          lv_errmsg := '';
        ELSIF (lv_dev_phase = cv_dev_phase_complete)
          AND (lv_dev_status = cv_dev_status_warn)
        THEN
          -- 警告終了の場合
          gn_warn_count := gn_warn_count + 1;
          -- 警告終了メッセージ出力
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00022,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            lv_errmsg
                           );
          lv_errmsg := '';
        ELSE
          -- その他(エラー終了)の場合
          gn_err_count := gn_err_count + 1;
          -- エラー終了メッセージ出力
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                iv_name => cv_msg_cfr_00014,
                                                iv_token_name1 => cv_tkn_prog_name,
                                                iv_token_value1 => g_conc_list_tab(i).user_conc_prog_name
                                               );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                            lv_errmsg
                           );
          FND_FILE.PUT_LINE(FND_FILE.LOG,
                            lv_errmsg
                           );
          lv_errmsg := '';
        END IF;
      ELSE
        RAISE wait_for_request_expt;
      END IF;
    END LOOP wait_request_loop;

  EXCEPTION
    -- *** 要求監視失敗時 ***
    WHEN wait_for_request_expt THEN
      lv_errbuf := FND_MESSAGE.GET; -- FND_CONCURRENT.WAIT_FOR_REQUESTでスタックされたエラーメッセージがあれば取得
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00013,
                                            iv_token_name1 => cv_tkn_prog_name,
                                            iv_token_value1 => g_conc_list_tab(ln_tab_ind).user_conc_prog_name
                                           );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END wait_request;

  /**********************************************************************************
   * Procedure Name   : end_proc
   * Description      : 終了処理プロシージャ
   ***********************************************************************************/
  PROCEDURE end_proc(
    iv_retcode          IN  VARCHAR2,
    ov_errbuf           OUT VARCHAR2,
    ov_retcode          OUT VARCHAR2,
    ov_errmsg           OUT VARCHAR2
  )
  IS

--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_proc';  -- プログラム名
--
--##############################  固定部 END   ##################################
--

--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--

    -- ===============================
    -- ローカル変数
    -- ===============================
    lb_submited_request BOOLEAN := FALSE; -- 発行済みコンカレント存在チェック

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    -- 対象件数出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90000,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => g_conc_list_tab.COUNT
                                              )
                     );

    -- 成功件数出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90001,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_normal_count
                                              )
                     );

    -- 警告件数出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                                     iv_name => cv_msg_cfr_00025,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_warn_count
                                              )
                     );

    -- エラー件数出力
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                      xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                     iv_name => cv_msg_ccp_90002,
                                                     iv_token_name1 => cv_tkn_count,
                                                     iv_token_value1 => gn_err_count
                                              )
                     );

    -- コンカレント発行確認
    IF g_conc_list_tab.EXISTS(1) THEN
      <<submit_request_loop>>
      FOR i IN g_conc_list_tab.FIRST .. g_conc_list_tab.LAST LOOP
        IF (g_conc_list_tab(i).request_id IS NOT NULL) THEN
          lb_submited_request := TRUE;
          EXIT;
        END IF;
      END LOOP submit_request_loop;
    END IF;

    IF  (gn_err_count > 0)
     OR ((iv_retcode = cv_status_error)
     AND (lb_submited_request))
    THEN
      -- エラー終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90007
                                                )
                       );
    ELSIF (iv_retcode = cv_status_error)
    AND (NOT lb_submited_request)
    THEN
      -- エラー終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90006
                                                )
                       );
    ELSE
      -- 正常終了メッセージ出力
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        xxccp_common_pkg.get_msg(iv_application => cv_xxccp_app_name,
                                                 iv_name => cv_msg_ccp_90004
                                                )
                       );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END end_proc;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : 汎用請求起動処理実行部
   ***********************************************************************************/
  PROCEDURE submain(
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
-- Modify 2009.09.18 Ver1.1 Start
    iv_exec_003A06C  IN  VARCHAR2,    -- 汎用店別請求
    iv_exec_003A07C  IN  VARCHAR2,    -- 汎用伝票別請求
    iv_exec_003A08C  IN  VARCHAR2,    -- 汎用商品（全明細）
    iv_exec_003A09C  IN  VARCHAR2,    -- 汎用商品（単品毎集計）
    iv_exec_003A10C  IN  VARCHAR2,    -- 汎用商品（店単品毎集計）
    iv_exec_003A11C  IN  VARCHAR2,    -- 汎用商品（単価毎集計）
    iv_exec_003A12C  IN  VARCHAR2,    -- 汎用商品（店単価毎集計）
    iv_exec_003A13C  IN  VARCHAR2,    -- 汎用（店コラム毎集計）
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';  -- プログラム名
--
--##############################  固定部 END   ##################################
--
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_log        CONSTANT VARCHAR2(10)  := 'LOG';      -- パラメータ出力関数 ログ出力時のiv_which値
    cv_output     CONSTANT VARCHAR2(10)  := 'OUTPUT';   -- パラメータ出力関数 レポート出力時のiv_which値

--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--

    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_pkg_name VARCHAR2(100); -- 共通関数パッケージ名
    lv_prg_name VARCHAR2(100); -- 共通関数プロシージャ/ファンクション名

    -- ===============================
    -- ローカル例外
    -- ===============================
    prof_wait_interval_expt  EXCEPTION; -- プロファイルオプション「汎用請求要求完了チェック待機秒数」取得例外
    prof_wait_max_expt       EXCEPTION; -- プロファイルオプション「汎用請求要求完了待機最大秒数」取得例外

  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    -- コンカレントパラメータログ出力
    xxcfr_common_pkg.put_log_param(iv_which => cv_log,
                                   iv_conc_param1 => iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                                   iv_conc_param2 => iv_ar_code1,
                                   iv_conc_param2 => iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                                   iv_conc_param3 => iv_exec_003A06C,
                                   iv_conc_param4 => iv_exec_003A07C,
                                   iv_conc_param5 => iv_exec_003A08C,
                                   iv_conc_param6 => iv_exec_003A09C,
                                   iv_conc_param7 => iv_exec_003A10C,
                                   iv_conc_param8 => iv_exec_003A11C,
                                   iv_conc_param9 => iv_exec_003A12C,
                                   iv_conc_param10 => iv_exec_003A13C,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    -- コンカレントパラメータOUTファイル出力
    xxcfr_common_pkg.put_log_param(iv_which => cv_output,
                                   iv_conc_param1 => iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                                   iv_conc_param2 => iv_ar_code1,
                                   iv_conc_param2 => iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                                   iv_conc_param3 => iv_exec_003A06C,
                                   iv_conc_param4 => iv_exec_003A07C,
                                   iv_conc_param5 => iv_exec_003A08C,
                                   iv_conc_param6 => iv_exec_003A09C,
                                   iv_conc_param7 => iv_exec_003A10C,
                                   iv_conc_param8 => iv_exec_003A11C,
                                   iv_conc_param9 => iv_exec_003A12C,
                                   iv_conc_param10 => iv_exec_003A13C,
                                   ov_errbuf => lv_errbuf,
                                   ov_retcode => lv_retcode,
                                   ov_errmsg => lv_errmsg
                                  );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    IF NOT (iv_exec_003A06C = cv_conc_param_n AND
            iv_exec_003A07C = cv_conc_param_n AND
            iv_exec_003A08C = cv_conc_param_n AND
            iv_exec_003A09C = cv_conc_param_n AND
            iv_exec_003A10C = cv_conc_param_n AND
            iv_exec_003A11C = cv_conc_param_n AND
            iv_exec_003A12C = cv_conc_param_n AND
            iv_exec_003A13C = cv_conc_param_n)
    THEN
      --===============================================================
      -- A-2．プロファイル取得処理
      --===============================================================
      gv_wait_interval := FND_PROFILE.VALUE(cv_prof_name_wait_interval);
      IF (gv_wait_interval IS NULL) THEN
        RAISE prof_wait_interval_expt;
      END IF;

      gv_wait_max := FND_PROFILE.VALUE(cv_prof_name_wait_max);
      IF (gv_wait_max IS NULL) THEN
        RAISE prof_wait_max_expt;
      END IF;

      --===============================================================
      -- A-3．コンカレント・プログラム名取得処理
      --===============================================================
      get_conc_name(iv_exec_003A06C,
                    iv_exec_003A07C,
                    iv_exec_003A08C,
                    iv_exec_003A09C,
                    iv_exec_003A10C,
                    iv_exec_003A11C,
                    iv_exec_003A12C,
                    iv_exec_003A13C,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg
                   );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

      --===============================================================
      -- A-4．コンカレント起動処理
      --===============================================================
      submit_request(iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--                     iv_ar_code1,
                     iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg
                    );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

      --===============================================================
      -- A-5．コンカレントステータス取得処理
      --===============================================================
      wait_request(lv_errbuf,
                   lv_retcode,
                   lv_errmsg
                  );
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;

    END IF;

  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** プロファイル「汎用請求要求完了チェック待機秒数」取得エラー発生時 ***
    WHEN prof_wait_interval_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00004,
                                            iv_token_name1 => cv_tkn_prof_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_interval));
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** プロファイル「汎用請求要求完了待機最大秒数」取得エラー発生時 ***
    WHEN prof_wait_max_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_xxcfr_app_name,
                                            iv_name => cv_msg_cfr_00004,
                                            iv_token_name1 => cv_tkn_prof_name,
                                            iv_token_value1 => xxcfr_common_pkg.get_user_profile_name(cv_prof_name_wait_max));
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
    WHEN OTHERS THEN
      ov_errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg := '';
  END submain;

  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   ***********************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- 締日
-- Modify 2009.09.18 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- 売掛コード１(請求書)
    iv_cust_code     IN  VARCHAR2,    -- 顧客コード
-- Modify 2009.09.18 Ver1.1 End
    iv_exec_003A06C  IN  VARCHAR2,    -- 汎用店別請求
    iv_exec_003A07C  IN  VARCHAR2,    -- 汎用伝票別請求
    iv_exec_003A08C  IN  VARCHAR2,    -- 汎用商品（全明細）
    iv_exec_003A09C  IN  VARCHAR2,    -- 汎用商品（単品毎集計）
    iv_exec_003A10C  IN  VARCHAR2,    -- 汎用商品（店単品毎集計）
    iv_exec_003A11C  IN  VARCHAR2,    -- 汎用商品（単価毎集計）
    iv_exec_003A12C  IN  VARCHAR2,    -- 汎用商品（店単価毎集計）
    iv_exec_003A13C  IN  VARCHAR2     -- 汎用（店コラム毎集計）
  )
  IS

--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
--##############################  固定部 END   ##################################
--

--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(5000); -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--

  BEGIN

    --===============================================================
    -- A-1．入力パラメータ値ログ出力処理
    --===============================================================
    xxccp_common_pkg.put_log_header(ov_retcode => lv_retcode,
                                    ov_errbuf => lv_errbuf,
                                    ov_errmsg => lv_errmsg
                                   );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;

    submain(iv_target_date,
-- Modify 2009.09.18 Ver1.1 Start
--            iv_ar_code1,
            iv_cust_code,
-- Modify 2009.09.18 Ver1.1 End
            iv_exec_003A06C,
            iv_exec_003A07C,
            iv_exec_003A08C,
            iv_exec_003A09C,
            iv_exec_003A10C,
            iv_exec_003A11C,
            iv_exec_003A12C,
            iv_exec_003A13C,
            lv_errbuf,
            lv_retcode,
            lv_errmsg
           );

    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'');
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;

    -- ステータスをセット
    retcode := lv_retcode;

    --===============================================================
    -- A-6．終了処理
    --===============================================================
    end_proc(iv_retcode => retcode,
             ov_errbuf  => lv_errbuf,
             ov_retcode => lv_retcode,
             ov_errmsg  => lv_errmsg
            );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;

    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
        ROLLBACK;
    END IF;

    -- エラー終了したコンカレントが存在する場合、エラー終了させる
    IF (gn_err_count > 0) THEN
      retcode := cv_status_error;
    END IF;

  EXCEPTION
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** サブプログラムエラー発生時 ***
    WHEN global_process_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      retcode := cv_status_error;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      errbuf := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
END  XXCFR003A14C;
/
