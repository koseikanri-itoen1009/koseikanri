create or replace PACKAGE BODY XX034DI002C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name     : XX034DI002C(body)
 * Description      : 仕訳伝票データのインポート、及び入力チェックを行います。
 * MD.050           : 部門入力バッチ処理(GL)    OCSJ/BFAFIN/MD050/F602
 * MD.070           : 部門入力（GL）インポート  OCSJ/BFAFIN/MD070/F602/01
 * Version          : 11.5.10.2.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  call_ldr_xx034dl002c   仕訳伝票データの読み込み、書き込み (C-1)
 *  set_distinct_data      一時表のデータ整理 (C-2)
 *  call_xx034dd002c       仕訳伝票テーブルへのデータコピー、入力チェック (C-3)
 *  chk_concurrent         コンカレントチェック処理
 *  upd_load_data          ロードデータ更新処理
 *  del_interface_table    インターフェーステーブル削除
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/11/12   1.0            新規作成
 *  2005/03/10   1.1            不具合対応
 *  2005/05/31   11.5.10.1.2    xx00_global_pkg.application_short_nameの誤使用修正
 *  2005/08/22   11.5.10.1.4    ロードデータ更新不具合修正
 *  2005/09/02   11.5.10.1.5    パフォーマンス改善対応
 *  2006/09/05   11.5.10.2.5    アップロード処理で複数ユーザの同時実行可能とする
 *                              制御の誤り、データ削除処理の誤り修正
 *  2007/08/01   11.5.10.2.10   エラー時のデータクリア処理でcommitが抜けており
 *                              ロールバックでデータが復活することの修正
 *  2023/10/03   11.5.10.2.11   [E_本稼働_19542]対応 SQLLDRのDB接続先を修正
 *
 *****************************************************************************************/
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  -- *** グローバル定数 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --結果出力用日付形式1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --結果出力用日付形式2
--
  -- xx00_concurrent_pkg.wait_for_request用
  cv_error            CONSTANT VARCHAR2(20) := 'ERROR';      --ステータス(ERROR)
  cv_dateted          CONSTANT VARCHAR2(20) := 'DELETED';    --ステータス(DELETED)
  cv_terminated       CONSTANT VARCHAR2(20) := 'TERMINATED'; --ステータス(TERMINATED)
  cv_warning          CONSTANT VARCHAR2(20) := 'WARNING';    --ステータス(WARNING)
  cv_standby          CONSTANT VARCHAR2(20) := 'STANDBY';    --ステータス(STANDBY)
  cv_complete         CONSTANT VARCHAR2(8)  := 'COMPLETE';   --コンカレント終了フェーズ
  cv_inactive         CONSTANT VARCHAR2(8)  := 'INACTIVE';   --コンカレント終了フェーズ
--
  cv_source_name      CONSTANT VARCHAR2(20) := 'EXCEL';
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  data_load_fail_expt    EXCEPTION;              -- データロード失敗エラー
  chk_concurrent_expt    EXCEPTION;              -- コンカレント失敗エラー
--
  /**********************************************************************************
   * Procedure Name   : del_interface_table
   * Description      : インターフェーステーブル削除
   ***********************************************************************************/
  PROCEDURE del_interface_table(
    in_request_no     IN  NUMBER,       -- 1.要求ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_interface_table'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- 部門入力ヘッダインターフェース削除
    DELETE XX03_JOURNAL_SLIPS_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
--
    -- 部門入力明細インターフェース削除
    DELETE XX03_JOURNAL_SLIP_LINES_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
--
-- ver 11.5.10.2.10 Add Start
    commit;
-- ver 11.5.10.2.10 Add End
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END del_interface_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_load_data
   * Description      : ロードデータ更新
   ***********************************************************************************/
  PROCEDURE upd_load_data(
    in_request_no     IN  NUMBER,       -- 1.要求ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_load_data'; -- プログラム名
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
    -- Ver11.5.10.1.4 2005/08/22 Add Start
    lv_person_number VARCHAR2(30);
    -- Ver11.5.10.1.4 2005/08/22 Add End
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    -- 部門入力ヘッダインターフェース更新
    -- Ver11.5.10.1.4 2005/08/22 Add Start
    SELECT employee_number
    INTO   lv_person_number
    FROM   XX03_PER_PEOPLES_V
    WHERE  USER_ID = xx00_global_pkg.user_id
    AND    TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date;
    -- Ver11.5.10.1.4 2005/08/22 Add End
--
    -- ver 11.5.10.2.5 Chg Start
    ---- Ver11.5.10.1.4 2005/08/22 Modify Start
    --UPDATE  xx03_journal_slips_if
    --SET     request_id              = in_request_no,
    --        --entry_person_number     = xx00_global_pkg.user_name,
    --        --requestor_person_number = xx00_global_pkg.user_name,
    --        entry_person_number     = lv_person_number,
    --        requestor_person_number = lv_person_number,
    --        created_by              = xx00_global_pkg.created_by,
    --        last_updated_by         = xx00_global_pkg.last_updated_by,
    --        last_update_login       = xx00_global_pkg.last_update_login,
    --        program_application_id  = xx00_global_pkg.prog_appl_id,
    --        program_id              = xx00_global_pkg.conc_program_id
    --WHERE   source = cv_source_name;
    ---- Ver11.5.10.1.4 2005/08/22 Modify End
    UPDATE  xx03_journal_slips_if
    SET     entry_person_number     = lv_person_number,
            requestor_person_number = lv_person_number,
            created_by              = xx00_global_pkg.created_by,
            last_updated_by         = xx00_global_pkg.last_updated_by,
            last_update_login       = xx00_global_pkg.last_update_login,
            program_application_id  = xx00_global_pkg.prog_appl_id,
            program_id              = xx00_global_pkg.conc_program_id,
            org_id                  = xx00_profile_pkg.value('ORG_ID'),
            set_of_books_id         = xx00_profile_pkg.value('GL_SET_OF_BKS_ID')
    WHERE   request_id = in_request_no
      AND   source     = cv_source_name;
    -- ver 11.5.10.2.5 Chg End
--
    -- 部門入力明細インターフェース更新
    -- ver 11.5.10.2.5 Chg Start
    --UPDATE xx03_journal_slip_lines_if
    --SET     request_id             = in_request_no,
    --        created_by             = xx00_global_pkg.created_by,
    --        last_updated_by        = xx00_global_pkg.last_updated_by,
    --        last_update_login      = xx00_global_pkg.last_update_login,
    --        program_application_id = xx00_global_pkg.prog_appl_id,
    --        program_id             = xx00_global_pkg.conc_program_id
    --WHERE   source = cv_source_name;
    UPDATE xx03_journal_slip_lines_if
    SET     created_by             = xx00_global_pkg.created_by,
            last_updated_by        = xx00_global_pkg.last_updated_by,
            last_update_login      = xx00_global_pkg.last_update_login,
            program_application_id = xx00_global_pkg.prog_appl_id,
            program_id             = xx00_global_pkg.conc_program_id,
            org_id                 = xx00_profile_pkg.value('ORG_ID')
    WHERE   request_id = in_request_no
      AND   source     = cv_source_name;
    -- ver 11.5.10.2.5 Chg End
--
    -- コミット
    COMMIT;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_load_data;
--
  /**********************************************************************************
   * Procedure Name   : call_ldr_xx034dl002c
   * Description      : データロードコンカレント実行 (C-1)
   ***********************************************************************************/
  PROCEDURE call_ldr_xx034dl002c(
    iv_file_name      IN  VARCHAR2,     -- 1.データファイル名(IN)
    on_request_no     OUT NUMBER,       -- 2.要求ID(OUT)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_ldr_xx034dl002c'; -- プログラム名
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
    -- データロードプログラム名
    cv_program_name     CONSTANT  VARCHAR2(11) := 'XX034DL002C';
-- Ver11.5.10.1.2 Add BEGIN
    cv_program_appl_sname CONSTANT  VARCHAR2(4) := 'XX03';
-- Ver11.5.10.1.2 Add END
-- ver 1.1 Change Start
    cv_ctl_file_name    CONSTANT  VARCHAR2(30) := 'LDR_XX03_JOURNAL_SLIPS_IF';
-- Ver11.5.10.2.11 Add Start
--    cv_oracle_sid       CONSTANT  VARCHAR2(30) := XX00_PROFILE_PKG.VALUE('CSF_MAP_DB_SID');
    cv_oracle_sid       CONSTANT  VARCHAR2(30) := XX00_PROFILE_PKG.VALUE('XXCFO1_SQLLDR_CONNECT_DB_NAME');
-- Ver11.5.10.2.11 Add End
    cv_org_id           CONSTANT  VARCHAR2(30) := xx00_profile_pkg.value('ORG_ID');
    cv_books_id         CONSTANT  VARCHAR2(30) := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
-- ver 1.1 Change End
--
    -- *** ローカル変数 ***
    lv_phase          VARCHAR2(240);    -- フェーズ(JA)
    lv_status         VARCHAR2(240);    -- ステータス(JA)
    lv_dev_phase      VARCHAR2(240);    -- フェーズ(US)
    lv_dev_status     VARCHAR2(240);    -- ステータス(US)
    lv_message        VARCHAR2(240);    -- 完了メッセージ
    lb_return         BOOLEAN;          -- 関数戻り値
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
-- ver 1.1 Change Start
--    -- 部門入力データロードの呼び出し
--    on_request_no := xx00_request_pkg.submit_request(
--      xx00_global_pkg.application_short_name,   -- アプリケーション短縮名
--      cv_program_name,                          -- 呼び出しコンカレント名
--      NULL,
--      NULL,
--      FALSE,
--      iv_file_name);
    -- 部門入力データロードの呼び出し
    on_request_no := xx00_request_pkg.submit_request(
-- Ver11.5.10.1.2 Modify BEGIN
      -- xx00_global_pkg.application_short_name,   -- アプリケーション短縮名
      cv_program_appl_sname,
-- Ver11.5.10.1.2 Modify END
      cv_program_name,                          -- 呼び出しコンカレント名
      NULL,
      NULL,
      FALSE,
      cv_ctl_file_name,
      iv_file_name,
      cv_oracle_sid,
      cv_org_id,
      cv_books_id);
-- ver 1.1 Change End
--
    -- 部門入力データロード起動チェック
    IF (NVL(on_request_no,0) = 0) THEN
      --(エラー処理)
      RAISE data_load_fail_expt;
    END IF;
    xx00_file_pkg.log('on_request_no=' || TO_CHAR(on_request_no));
--
    --コミット
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN data_load_fail_expt THEN             --*** データロード失敗エラー ***
      -- *** 任意で例外処理を記述する ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01061',
          'XX03_TOK_FILE_NAME',
          iv_file_name));                     -- データロード失敗メッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
      ROLLBACK;
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END call_ldr_xx034dl002c;
--
  /**********************************************************************************
   * Procedure Name   : set_distinct_data
   * Description      : 一時表のデータ整理 (C-2)
   ***********************************************************************************/
  PROCEDURE set_distinct_data(
    in_request_no     IN  NUMBER,       -- 1.要求ID(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_distinct_data'; -- プログラム名
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
    -- 部門入力インターフェース(ヘッダ)非重複データ取得カーソル
    CURSOR slip_if_head_data_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT    DISTINCT
--                xjsi.interface_id AS interface_id,
--                MAX(xjsi.source) AS source,
--                MAX(xjsi.wf_status) AS wf_status,
--                MAX(xjsi.slip_type_name) AS slip_type_name,
--                MAX(xjsi.entry_date) AS entry_date,
--                MAX(xjsi.requestor_person_number) AS requestor_person_number,
--                MAX(xjsi.approver_person_number) AS approver_person_number,
--                MAX(xjsi.invoice_currency_code) AS invoice_currency_code,
--                MAX(xjsi.exchange_rate) AS exchange_rate,
--                MAX(xjsi.exchange_rate_type_name) AS exchange_rate_type_name,
--                MAX(xjsi.ignore_rate_flag) AS ignore_rate_flag,
--                MAX(xjsi.description) AS description,
--                MAX(xjsi.entry_person_number) AS entry_person_number,
--                MAX(xjsi.period_name) AS period_name,
--                MAX(xjsi.gl_date) AS gl_date,
--                MAX(xjsi.org_id) AS org_id,
--                MAX(xjsi.set_of_books_id) AS set_of_books_id,
--                MAX(xjsi.created_by) AS created_by,
--                MAX(xjsi.creation_date) AS creation_date,
--                MAX(xjsi.last_updated_by) AS last_updated_by,
--                MAX(xjsi.last_update_date) AS last_update_date,
--                MAX(xjsi.last_update_login) AS last_update_login,
--                MAX(xjsi.request_id) AS request_id,
--                MAX(xjsi.program_application_id) AS program_application_id,
--                MAX(xjsi.program_id) AS program_id,
--                MAX(xjsi.program_update_date) AS program_update_date
--      FROM      XX03_JOURNAL_SLIPS_IF xjsi      -- 部門入力インターフェース(ヘッダ)
--      WHERE     xjsi.request_id = in_request_no -- 要求IDはパラメータ指定
--      GROUP BY  xjsi.interface_id
--      ORDER BY  xjsi.interface_id;
      SELECT    DISTINCT
                    xjsi.interface_id             AS interface_id,
                MAX(xjsi.source)                  AS source,
                MAX(xjsi.wf_status)               AS wf_status,
                    xjsi.slip_type_name           AS slip_type_name,
                MAX(xjsi.entry_date)              AS entry_date,
                MAX(xjsi.requestor_person_number) AS requestor_person_number,
                    xjsi.approver_person_number   AS approver_person_number,
                    xjsi.invoice_currency_code    AS invoice_currency_code,
                    xjsi.exchange_rate            AS exchange_rate,
                    xjsi.exchange_rate_type_name  AS exchange_rate_type_name,
                MAX(xjsi.ignore_rate_flag)        AS ignore_rate_flag,
                    xjsi.description              AS description,
                MAX(xjsi.entry_person_number)     AS entry_person_number,
                    xjsi.period_name              AS period_name,
                    xjsi.gl_date                  AS gl_date,
                MAX(xjsi.org_id)                  AS org_id,
                MAX(xjsi.set_of_books_id)         AS set_of_books_id,
                MAX(xjsi.created_by)              AS created_by,
                MAX(xjsi.creation_date)           AS creation_date,
                MAX(xjsi.last_updated_by)         AS last_updated_by,
                MAX(xjsi.last_update_date)        AS last_update_date,
                MAX(xjsi.last_update_login)       AS last_update_login,
                MAX(xjsi.request_id)              AS request_id,
                MAX(xjsi.program_application_id)  AS program_application_id,
                MAX(xjsi.program_id)              AS program_id,
                MAX(xjsi.program_update_date)     AS program_update_date
      FROM      XX03_JOURNAL_SLIPS_IF xjsi      -- 部門入力インターフェース(ヘッダ)
      WHERE     xjsi.request_id = in_request_no -- 要求IDはパラメータ指定
      GROUP BY  xjsi.interface_id,
                xjsi.slip_type_name,
                xjsi.approver_person_number,
                xjsi.invoice_currency_code,
                xjsi.exchange_rate,
                xjsi.exchange_rate_type_name,
                xjsi.description,
                xjsi.period_name,
                xjsi.gl_date
      ORDER BY  xjsi.interface_id;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- *** ローカル・レコード ***
    -- 部門入力インターフェース(ヘッダ)非重複データ取得レコード
    slip_if_head_data_rec slip_if_head_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --部門入力インターフェース(ヘッダ)非重複データ取得
    --カーソルオープン
    OPEN slip_if_head_data_cur;
    -- 部門入力ヘッダインターフェース削除
    DELETE XX03_JOURNAL_SLIPS_IF
    WHERE REQUEST_ID = in_request_no
    AND   source = cv_source_name;
    <<slip_interface_loop>>
    LOOP
      FETCH slip_if_head_data_cur INTO slip_if_head_data_rec;
      --カーソルデータ取得チェック
      IF slip_if_head_data_cur%NOTFOUND THEN
          EXIT slip_interface_loop;
      END IF;
      -- インターフェーステーブルへの挿入
      INSERT INTO xx03_journal_slips_if (
        interface_id,
        source,
        wf_status,
        slip_type_name,
        entry_date,
        requestor_person_number,
        approver_person_number,
        invoice_currency_code,
        exchange_rate,
        exchange_rate_type_name,
        ignore_rate_flag,
        description,
        entry_person_number,
        period_name,
        gl_date,
        org_id,
        set_of_books_id,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date)
      VALUES(
        slip_if_head_data_rec.interface_id,
        slip_if_head_data_rec.source,
        slip_if_head_data_rec.wf_status,
        slip_if_head_data_rec.slip_type_name,
        slip_if_head_data_rec.entry_date,
        slip_if_head_data_rec.requestor_person_number,
        slip_if_head_data_rec.approver_person_number,
        slip_if_head_data_rec.invoice_currency_code,
        slip_if_head_data_rec.exchange_rate,
        slip_if_head_data_rec.exchange_rate_type_name,
        slip_if_head_data_rec.ignore_rate_flag,
        slip_if_head_data_rec.description,
        slip_if_head_data_rec.entry_person_number,
        slip_if_head_data_rec.period_name,
        slip_if_head_data_rec.gl_date,
        slip_if_head_data_rec.org_id,
        slip_if_head_data_rec.set_of_books_id,
        slip_if_head_data_rec.created_by,
        slip_if_head_data_rec.creation_date,
        slip_if_head_data_rec.last_updated_by,
        slip_if_head_data_rec.last_update_date,
        slip_if_head_data_rec.last_update_login,
        slip_if_head_data_rec.request_id,
        slip_if_head_data_rec.program_application_id,
        slip_if_head_data_rec.program_id,
        slip_if_head_data_rec.program_update_date);
--
    END LOOP slip_interface_loop;
    -- カーソルクローズ
    CLOSE slip_if_head_data_cur;
    -- コミット
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END set_distinct_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_concurrent
   * Description      : コンカレントチェック処理
   ***********************************************************************************/
  PROCEDURE chk_concurrent(
    in_request_id       IN  NUMBER,       -- 1.要求ID(IN)
    iv_file_name        IN  VARCHAR2,     -- 2.データファイル名(IN)
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_concurrent'; -- プログラム名
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
    ln_req_chk        BOOLEAN;         --終了ステータスチェック
    lv_phase          VARCHAR2(240);   --要求フェーズ
    lv_status         VARCHAR2(240);   --要求ステータス
    lv_dev_phase      VARCHAR2(240);   --PG上で比較できる要求フェーズ
    lv_dev_status     VARCHAR2(240);   --PG上で比較できる要求ステータス
    lv_message        VARCHAR2(240);   --要求終了時に必要になる終了メッセージ
    ln_wait_interval  NUMBER;          --チェック間隔
    ln_max_wait       NUMBER;          --最大待ち時間
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --チェック間隔
    ln_wait_interval := xx00_profile_pkg.value('XX03_WAIT_INTERVAL');
    --MAX待ち時間
    ln_max_wait := xx00_profile_pkg.value('XX03_MAX_WAIT');
    --コンカレント要求待ち関数
    ln_req_chk := xx00_concurrent_pkg.wait_for_request(
      in_request_id,      -- 要求ID
      ln_wait_interval,   -- チェック間隔
      ln_max_wait,        -- 最大待ち時間
      lv_phase,           -- 要求フェーズJA
      lv_status,          -- 要求ステータスJA
      lv_dev_phase,       -- 要求フェーズUS
      lv_dev_status,      -- 要求ステータスUS
      lv_message);        -- 終了メッセージ
--
    --ログ出力
    xx00_file_pkg.log('ln_wait_interval = '||ln_wait_interval);
    xx00_file_pkg.log('ln_max_wait = '||ln_max_wait);
    xx00_file_pkg.log('lv_phase = '||lv_phase);
    xx00_file_pkg.log('lv_status = '||lv_status);
    xx00_file_pkg.log('lv_dev_phase = '||lv_dev_phase);
    xx00_file_pkg.log('lv_dev_status = '||lv_dev_status);
    xx00_file_pkg.log('lv_message = '||lv_message);
--
    -- コンカレントの戻り値チェック
    IF (ln_req_chk = FALSE) THEN
      ov_retcode := xx00_common_pkg.set_status_error_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    -- コンカレントのフェーズチェック
    IF (lv_dev_phase <> cv_complete)
      AND (lv_dev_phase <> cv_inactive)
    THEN
      ov_retcode := xx00_common_pkg.set_status_error_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    -- コンカレントのステータスチェック
    IF (lv_dev_status = cv_error)
      OR (lv_dev_status = cv_dateted)
      OR (lv_dev_status = cv_terminated)
      OR (lv_dev_status = cv_standby)
      OR (lv_dev_status = cv_warning)
    THEN
--
      -- ver 11.5.10.2.5 Del Start
      ---- インターフェーステーブル削除処理
      ---- 部門入力ヘッダインターフェース削除
      --DELETE XX03_JOURNAL_SLIPS_IF
      --WHERE source = cv_source_name;
      ----
      ---- 部門入力明細インターフェース削除
      --DELETE XX03_JOURNAL_SLIP_LINES_IF
      --WHERE source = cv_source_name;
      -- ver 11.5.10.2.5 Del End
--
      ov_retcode := xx00_common_pkg.set_status_warn_f;
      RAISE chk_concurrent_expt;
    END IF;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_concurrent_expt THEN                    --*** データロード失敗エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01061',
          'XX03_TOK_FILE_NAME',
          iv_file_name));                     -- データロード失敗メッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END chk_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : call_xx034dd002c
   * Description      : 仕訳伝票テーブルへのデータコピー、入力チェック (C-3)
   ***********************************************************************************/
  PROCEDURE call_xx034dd002c(
    iv_source_name     IN  VARCHAR2,     -- 1.ソース名(IN)
    in_req_load_no     IN  NUMBER,       -- 2.ロード処理要求ID(IN)
    on_req_imp_no      OUT NUMBER,       -- 2.インポート要求ID(OUT)
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_xx034dd002c'; -- プログラム名
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
    -- データロードプログラム名
    cv_program_name     CONSTANT  VARCHAR2(11) := 'XX034DD002C';
-- Ver11.5.10.1.2 Add BEGIN
    cv_program_appl_sname CONSTANT  VARCHAR2(4) := 'XX03';
-- Ver11.5.10.1.2 Add END
--
    -- *** ローカル変数 ***
    lv_phase          VARCHAR2(240);    -- フェーズ(JA)
    lv_status         VARCHAR2(240);    -- ステータス(JA)
    lv_dev_phase      VARCHAR2(240);    -- フェーズ(US)
    lv_dev_status     VARCHAR2(240);    -- ステータス(US)
    lv_message        VARCHAR2(240);    -- 完了メッセージ
    lb_return         BOOLEAN;          -- 関数戻り値
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
    -- 部門入力データインポートの呼び出し
    on_req_imp_no := xx00_request_pkg.submit_request(
-- Ver11.5.10.1.2 Add BEGIN
      -- xx00_global_pkg.application_short_name,   -- アプリケーション短縮名
      cv_program_appl_sname,
-- Ver11.5.10.1.2 Add END
      cv_program_name,                          -- 呼び出しコンカレント名
      NULL,
      NULL,
      FALSE,
      iv_source_name,
      in_req_load_no);
--
    -- 部門入力データインポート起動チェック
    IF (NVL(on_req_imp_no,0) = 0) THEN
      xx00_file_pkg.log('0 errror');
      --(エラー処理)
      RAISE data_load_fail_expt;
    END IF;
    xx00_file_pkg.log('on_req_imp_no=' || TO_CHAR(on_req_imp_no));
--
    --コミット
    COMMIT;
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN data_load_fail_expt THEN             --*** データロード失敗エラー ***
      -- *** 任意で例外処理を記述する ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-01062'));                  -- データロード失敗メッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
      ROLLBACK;
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END call_xx034dd002c;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name        IN  VARCHAR2,     -- 1.データファイル名(IN)
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_request_no       NUMBER := 0;         -- データロード処理要求ID
    ln_imp_req_no       NUMBER := 0;         -- インポート要求ID
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =======================================
    -- 仕訳伝票データの読み込み、書き込み (C-1)
    -- =======================================
    call_ldr_xx034dl002c(
      iv_file_name,         -- 1.データファイル名(IN)
      ln_request_no,        -- 2.要求ID(OUT)
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      -- ver 11.5.10.2.5 Add Start
      del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
      -- ver 11.5.10.2.5 Add End
      --(エラー処理)
      RAISE global_process_expt;
    -- 警告ステータス時、処理中断
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
    -- =======================================
    -- コンカレントチェック
    -- =======================================
    chk_concurrent(
      ln_request_no,        -- 1.要求ID(IN)
      iv_file_name,         -- 2.データファイル名(IN)
      lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      lv_retcode,           -- リターン・コード             --# 固定 #
      lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      -- ver 11.5.10.2.5 Add Start
      del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
      -- ver 11.5.10.2.5 Add End
      --(エラー処理)
      RAISE global_process_expt;
      --  警告ステータス時、処理中断
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_normal_f) THEN
      -- 正常ステータス時のみ以降の処理に続く
      -- =======================================
      -- ロードデータ更新処理
      -- =======================================
      upd_load_data(
        ln_request_no,        -- 1.要求ID(IN)
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =======================================
      -- 一時表のデータ整理 (C-2)
      -- =======================================
      set_distinct_data(
        ln_request_no,        -- 1.要求ID(IN)
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- =================================================
      -- 仕訳伝票テーブルへのデータコピー、入力チェック(C-3)
      -- =================================================
      call_xx034dd002c(
        cv_source_name,       -- 1.ソース名(IN)
        ln_request_no,        -- 2.データロード要求ID(IN)
        ln_imp_req_no,        -- 3.インポート要求ID(IN)
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(エラー処理)
        RAISE global_process_expt;
      -- 警告ステータス時、処理中断
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        ov_retcode := xx00_common_pkg.set_status_warn_f;
      END IF;
--
    -- =======================================
      -- コンカレントチェック
      -- =======================================
      chk_concurrent(
        ln_imp_req_no,        -- 1.インポート要求ID(IN)
        iv_file_name,         -- 2.データファイル名(IN)
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        -- ver 11.5.10.2.5 Add Start
        del_interface_table(ln_request_no ,lv_errbuf ,lv_retcode ,lv_errmsg);
        -- ver 11.5.10.2.5 Add End
        --(エラー処理)
        RAISE global_process_expt;
        --  警告ステータス時、処理中断
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        ov_retcode := xx00_common_pkg.set_status_warn_f;
      END IF;
--
    -- ver 11.5.10.2.5 Mov Start
    END IF;
    -- ver 11.5.10.2.5 Mov End
--
      -- =======================================
      -- 終了処理 (C-4)
      -- =======================================
      del_interface_table(
        ln_request_no,        -- 1.要求ID(IN)
        lv_errbuf,            -- エラー・メッセージ           --# 固定 #
        lv_retcode,           -- リターン・コード             --# 固定 #
        lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    -- ver 11.5.10.2.5 Mov Start
    --END IF;
    -- ver 11.5.10.2.5 Mov Start
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
    errbuf              OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_name        IN  VARCHAR2)      -- 1.データファイル名(IN)
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================
    -- ログヘッダの出力
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_file_name,       -- 1.データファイル名(IN)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ログフッタの出力
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** 共通関数OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XX034DI002C;
/
