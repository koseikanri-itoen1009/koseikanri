CREATE OR REPLACE PACKAGE BODY XXCFF003A33C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A33C(body)
 * Description      : リース物件コード訂正
 * MD.050           : MD050_CFF_003_A33_リース物件コード訂正
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  init                       初期処理 (A-1)
 *  select_object_headers      リース物件テーブル取得処理 (A-2)
 *  check_contract_condition   契約状況チェック (A-3)
 *  validate_record            整合性チェック (A-4)
 *  update_contract_lines      リース契約明細テーブル更新処理 (A-5)
 *  update_object_headers      リース物件テーブル更新処理 (A-6)
 *  insert_contract_histories  リース契約明細履歴テーブル登録処理 (A-7)
 *  insert_object_histories    リース物件履歴テーブル登録処理 (A-8)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-14    1.0   SCS 増子 秀幸    新規作成
 *  2009-02-09    1.1   SCS 増子 秀幸    [障害CFF_006] ログ出力先不具合対応
 *  2009-02-17    1.2   SCS 増子 秀幸    [障害CFF_034] 履歴設定値不具合対応
 *  2009-02-25    1.3   SCS 増子 秀幸    [障害CFF_055] WHOカラム未設定不具合対応
 *  2013-07-17    1.4   SCSK 中野 徹也   [E_本稼動_10871] 消費税増税対応
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
  record_lock_expt    EXCEPTION;    -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(record_lock_expt,-54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF003A33C';  -- パッケージ名
  cv_app_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';         -- アプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_cff_00007    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00007';  -- ロックエラー
  cv_msg_cff_00094    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00094';  -- 共通関数エラー
  cv_msg_cff_00095    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00095';  -- 共通関数メッセージ
  cv_msg_cff_00142    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00142';  -- 整合性チェックエラー
  cv_msg_cff_00143    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00143';  -- 契約状況エラー
  cv_msg_cff_00182    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-00182';  -- 物件コード指定エラー
--
  -- トークン
  cv_tkn_cff_00007    CONSTANT VARCHAR2(20) := 'TABLE_NAME';          -- テーブル名
  cv_tkn_cff_00094    CONSTANT VARCHAR2(20) := 'FUNC_NAME';           -- 関数名
  cv_tkn_cff_00095    CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- エラーメッセージ
  cv_tkn_cff_00142_01 CONSTANT VARCHAR2(20) := 'OBJECT_CODE';         -- 物件コード
  cv_tkn_cff_00142_02 CONSTANT VARCHAR2(20) := 'O_LEASE_CLASS';       -- 物_リース種別
  cv_tkn_cff_00142_03 CONSTANT VARCHAR2(20) := 'O_RE_LEASE_TIMES';    -- 物_再リース回数
  cv_tkn_cff_00142_04 CONSTANT VARCHAR2(20) := 'O_LEASE_TYPE';        -- 物_リース区分
  cv_tkn_cff_00142_05 CONSTANT VARCHAR2(20) := 'CONTRACT_NUMBER';     -- 契約番号
  cv_tkn_cff_00142_06 CONSTANT VARCHAR2(20) := 'CONTRACT_LINE_NUM ';  -- 契約枝番
  cv_tkn_cff_00142_07 CONSTANT VARCHAR2(20) := 'C_LEASE_CLASS';       -- 契_リース種別
  cv_tkn_cff_00142_08 CONSTANT VARCHAR2(20) := 'C_RE_LEASE_TIMES';    -- 契_再リース回数
  cv_tkn_cff_00142_09 CONSTANT VARCHAR2(20) := 'C_LEASE_TYPE';        -- 契_リース区分
--
  -- トークン値
  cv_msg_cff_50014    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50014';  -- リース物件テーブル
  cv_msg_cff_50030    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50030';  -- リース契約明細テーブル
  cv_msg_cff_50130    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCFF1-50130';  -- 初期処理
--
  -- リース区分
  cv_lease_type_orgn  CONSTANT VARCHAR2(1)  := '1';     -- 原契約
  cv_lease_type_re    CONSTANT VARCHAR2(1)  := '2';     -- 再リース
--
  -- 物件ステータス
  cv_obj_status_101   CONSTANT VARCHAR2(3)   := '101';  -- 未契約
  cv_obj_status_102   CONSTANT VARCHAR2(3)   := '102';  -- 契約済
  cv_obj_status_103   CONSTANT VARCHAR2(3)   := '103';  -- 再リース待
  cv_obj_status_104   CONSTANT VARCHAR2(3)   := '104';  -- 再リース契約済
--
  -- 物件契約ステータス
  cv_cont_status_209  CONSTANT VARCHAR2(3)   := '209';  -- 情報変更
--
  -- 会計IFフラグ
  cv_if_flag_one      CONSTANT VARCHAR2(1)   := '1';    -- 未送信
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
    -- リース物件テーブル取得対象データレコード型
    TYPE g_object_headers_rtype IS RECORD(
      object_code        xxcff_object_headers.object_code%TYPE,        -- 物件コード
      object_header_id   xxcff_object_headers.object_header_id%TYPE,   -- 物件内部ID
      contract_number    xxcff_contract_headers.contract_number%TYPE,  -- 契約番号
      contract_line_num  xxcff_contract_lines.contract_line_num%TYPE,  -- 契約枝番
      contract_line_id   xxcff_contract_lines.contract_line_id%TYPE,   -- 契約明細内部ID
      xch_lease_class    xxcff_contract_headers.lease_class%TYPE,      -- 契_リース種別
      xch_lease_type     xxcff_contract_headers.lease_type%TYPE,       -- 契_リース区分
      xch_re_lease_times xxcff_contract_headers.re_lease_times%TYPE,   -- 契_再リース回数
      xoh_lease_class    xxcff_object_headers.lease_class%TYPE,        -- 物_リース種別
      xoh_lease_type     xxcff_object_headers.lease_type%TYPE,         -- 物_リース区分
      xoh_re_lease_times xxcff_object_headers.re_lease_times%TYPE      -- 物_再リース回数
    );
--
  -- リース物件テーブル取得対象データレコード配列
  TYPE g_object_headers_ttype IS TABLE OF g_object_headers_rtype
  INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gr_init_rec           xxcff_common1_pkg.init_rtype;  -- 初期処理情報
  g_object_headers_tab  g_object_headers_ttype;        -- リース物件テーブル取得対象データ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    lv_which_out VARCHAR2(10) := 'OUTPUT';
    lv_which_log VARCHAR2(10) := 'LOG';
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
    -- コンカレントパラメータの値を表示するメッセージのログ出力
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_out,  -- 出力区分
      ov_retcode => lv_retcode,    -- リターンコード
      ov_errbuf  => lv_errbuf,     -- エラーメッセージ
      ov_errmsg  => lv_errmsg      -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    xxcff_common1_pkg.put_log_param(
      iv_which   => lv_which_log,  -- 出力区分
      ov_retcode => lv_retcode,    -- リターンコード
      ov_errbuf  => lv_errbuf,     -- エラーメッセージ
      ov_errmsg  => lv_errmsg      -- ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 共通関数(初期処理)呼び出し
    xxcff_common1_pkg.init(
      or_init_rec => gr_init_rec,  -- 初期処理情報
      ov_retcode  => lv_retcode,   -- リターンコード
      ov_errbuf   => lv_errbuf,    -- エラーメッセージ
      ov_errmsg   => lv_errmsg     -- ユーザー・エラーメッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00094,  -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00094,  -- トークンコード1
                     iv_token_value1 => cv_msg_cff_50130   -- トークン値1
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                     iv_name         => cv_msg_cff_00095,  -- メッセージコード
                     iv_token_name1  => cv_tkn_cff_00095,  -- トークンコード1
                     iv_token_value1 => lv_errmsg          -- トークン値1
                   );
      lv_errmsg := lv_errbuf || lv_errmsg;
      lv_errbuf := lv_errmsg;
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
   * Procedure Name   : select_object_headers
   * Description      : リース物件テーブル取得処理 (A-2)
   ***********************************************************************************/
  PROCEDURE select_object_headers(
    iv_obj_code1  IN  VARCHAR2,     --   1.物件コード1
    iv_obj_code2  IN  VARCHAR2,     --   2.物件コード2
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'select_object_headers'; -- プログラム名
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
    -- リース物件テーブル取得カーソル
    CURSOR get_object_headers_cur
    IS
      SELECT obj.object_code object_code,               -- 物件コード
             obj.object_header_id object_header_id,     -- 物件内部ID
             cont.contract_number contract_number,      -- 契約番号
             cont.contract_line_num contract_line_num,  -- 契約枝番
             cont.contract_line_id contract_line_id,    -- 契約明細内部ID
             cont.lease_class xch_lease_class,          -- 契_リース種別
             cont.lease_type xch_lease_type,            -- 契_リース区分
             cont.re_lease_times xch_re_lease_times,    -- 契_再リース回数
             obj.lease_class xoh_lease_class,           -- 物_リース種別
             obj.lease_type xoh_lease_type,             -- 物_リース区分
             obj.re_lease_times xoh_re_lease_times      -- 物_再リース回数
      FROM   (SELECT xoh.object_code object_code,              -- 物件コード
                     xoh.object_header_id object_header_id,    -- 物件内部ID
                     xoh.lease_class lease_class,              -- 物_リース種別
                     xoh.lease_type lease_type,                -- 物_リース区分
                     xoh.re_lease_times re_lease_times         -- 物_再リース回数
              FROM   xxcff_object_headers   xoh   -- リース物件
              WHERE  xoh.object_code IN(iv_obj_code1, iv_obj_code2)) obj,
             (SELECT xch.contract_number contract_number,      -- 契約番号
                     xcl.contract_line_num contract_line_num,  -- 契約枝番
                     xcl.contract_line_id contract_line_id,    -- 契約明細内部ID
                     xcl.object_header_id object_header_id,    -- 物件内部ID
                     xch.lease_class lease_class,              -- 契_リース種別
                     xch.lease_type lease_type,                -- 契_リース区分
                     xch.re_lease_times re_lease_times         -- 契_再リース回数
              FROM   xxcff_contract_headers xch,  -- リース契約
                     xxcff_contract_lines   xcl   -- リース契約明細
              WHERE  xch.contract_header_id = xcl.contract_header_id) cont
      WHERE  obj.object_header_id = cont.object_header_id(+)
        AND  obj.re_lease_times   = cont.re_lease_times(+);
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
    -- リース物件テーブル取得
    OPEN  get_object_headers_cur;
    FETCH get_object_headers_cur BULK COLLECT INTO g_object_headers_tab;
    CLOSE get_object_headers_cur;
--
    -- 物件コードチェック
    -- 取得件数が2件より小さい(同一物件コードが指定された)場合、エラー
    IF (g_object_headers_tab.COUNT < 2) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_cff_00182  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
      IF (get_object_headers_cur%ISOPEN) THEN
        CLOSE get_object_headers_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END select_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : check_contract_condition
   * Description      : 契約状況チェック (A-3)
   ***********************************************************************************/
  PROCEDURE check_contract_condition(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_contract_condition'; -- プログラム名
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
    -- 契約番号が処理対象の2件ともNULLの場合、エラー
    IF (  (g_object_headers_tab(1).contract_number IS NULL)
      AND (g_object_headers_tab(2).contract_number IS NULL)  )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_kbn_cff,   -- アプリケーション短縮名
                     iv_name        => cv_msg_cff_00143  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END check_contract_condition;
--
  /**********************************************************************************
   * Procedure Name   : validate_record
   * Description      : 整合性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE validate_record(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_record'; -- プログラム名
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
    ln_i2               INTEGER;        -- 相手方レコードのインデックス
    lv_object_code      VARCHAR2(240);  -- メッセージ出力用物件コード
    lv_o_lease_class    VARCHAR2(240);  -- メッセージ出力用物_リース種別
    lv_o_re_lease_times VARCHAR2(240);  -- メッセージ出力用物_再リース回数
    lv_o_lease_type     VARCHAR2(240);  -- メッセージ出力用物_リース区分
    lv_cont_number      VARCHAR2(240);  -- メッセージ出力用契約番号
    lv_cont_line_num    VARCHAR2(240);  -- メッセージ出力用契約枝番
    lv_c_lease_class    VARCHAR2(240);  -- メッセージ出力用契_リース種別
    lv_c_re_lease_times VARCHAR2(240);  -- メッセージ出力用契_再リース回数
    lv_c_lease_type     VARCHAR2(240);  -- メッセージ出力用契_リース区分
--
    -- *** ローカル・カーソル ***
    -- リース種別名称取得カーソル
    CURSOR get_lease_cls_name_cur(
      iv_lease_cls_code VARCHAR2)
    IS
      SELECT xlcv.lease_class_name lease_class_name  -- リース区分名称
      FROM   xxcff_lease_class_v xlcv
      WHERE  xlcv.lease_class_code = iv_lease_cls_code;
--
    -- リース区分名称取得カーソル
    CURSOR get_lease_type_name_cur(
      iv_lease_type_code VARCHAR2)
    IS
      SELECT xltv.lease_type_name lease_type_name  -- リース種別名称
      FROM   xxcff_lease_type_v xltv
      WHERE  xltv.lease_type_code = iv_lease_type_code;
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
    -- 2つのレコードに対する整合性チェック
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- 相手方レコードのインデックスを算出
      ln_i2 := ABS(i-3);
--
      -- 契約明細内部IDがNULLでない場合、リース物件とリース契約の整合性チェックを行う
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        -- 契約のリース種別・再リース回数・リース区分と、
        -- 相手方の物件のリース種別・再リース回数・リース区分が等しくない場合、エラー
        IF ( (g_object_headers_tab(i).xch_lease_class    != g_object_headers_tab(ln_i2).xoh_lease_class)
          OR (g_object_headers_tab(i).xch_re_lease_times != g_object_headers_tab(ln_i2).xoh_re_lease_times)
          OR (g_object_headers_tab(i).xch_lease_type     != g_object_headers_tab(ln_i2).xoh_lease_type) )
        THEN
          -- メッセージ出力用パラメータの設定
          -- 物件コード
          lv_object_code      := g_object_headers_tab(ln_i2).object_code;
          -- 物_再リース回数
          lv_o_re_lease_times := TO_CHAR(g_object_headers_tab(ln_i2).xoh_re_lease_times);
          -- 契約番号
          lv_cont_number      := g_object_headers_tab(i).contract_number;
          -- 契約枝番
          lv_cont_line_num    := TO_CHAR(g_object_headers_tab(i).contract_line_num);
          -- 契_再リース回数
          lv_c_re_lease_times := TO_CHAR(g_object_headers_tab(i).xch_re_lease_times);
          -- 物_リース種別
          OPEN  get_lease_cls_name_cur(g_object_headers_tab(ln_i2).xoh_lease_class);
          FETCH get_lease_cls_name_cur INTO lv_o_lease_class;
          CLOSE get_lease_cls_name_cur;
          -- 物_リース区分
          OPEN  get_lease_type_name_cur(g_object_headers_tab(ln_i2).xoh_lease_type);
          FETCH get_lease_type_name_cur INTO lv_o_lease_type;
          CLOSE get_lease_type_name_cur;
          -- 契_リース種別
          OPEN  get_lease_cls_name_cur(g_object_headers_tab(i).xch_lease_class);
          FETCH get_lease_cls_name_cur INTO lv_c_lease_class;
          CLOSE get_lease_cls_name_cur;
          -- 契_リース区分
          OPEN  get_lease_type_name_cur(g_object_headers_tab(i).xch_lease_type);
          FETCH get_lease_type_name_cur INTO lv_c_lease_type;
          CLOSE get_lease_type_name_cur;
--
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_kbn_cff,         -- アプリケーション短縮名
                         iv_name         => cv_msg_cff_00142,       -- メッセージコード
                         iv_token_name1  => cv_tkn_cff_00142_01,    -- トークンコード1
                         iv_token_value1 => lv_object_code,         -- トークン値1
                         iv_token_name2  => cv_tkn_cff_00142_02,    -- トークンコード2
                         iv_token_value2 => lv_o_lease_class,       -- トークン値2
                         iv_token_name3  => cv_tkn_cff_00142_03,    -- トークンコード3
                         iv_token_value3 => lv_o_re_lease_times,    -- トークン値3
                         iv_token_name4  => cv_tkn_cff_00142_04,    -- トークンコード4
                         iv_token_value4 => lv_o_lease_type,        -- トークン値4
                         iv_token_name5  => cv_tkn_cff_00142_05,    -- トークンコード5
                         iv_token_value5 => lv_cont_number,         -- トークン値5
                         iv_token_name6  => cv_tkn_cff_00142_06,    -- トークンコード6
                         iv_token_value6 => lv_cont_line_num,       -- トークン値6
                         iv_token_name7  => cv_tkn_cff_00142_07,    -- トークンコード7
                         iv_token_value7 => lv_c_lease_class,       -- トークン値7
                         iv_token_name8  => cv_tkn_cff_00142_08,    -- トークンコード8
                         iv_token_value8 => lv_c_re_lease_times,    -- トークン値8
                         iv_token_name9  => cv_tkn_cff_00142_09,    -- トークンコード9
                         iv_token_value9 => lv_c_lease_type         -- トークン値9
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
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
  END validate_record;
--
  /**********************************************************************************
   * Procedure Name   : update_contract_lines
   * Description      : リース契約明細テーブル更新処理 (A-5)
   ***********************************************************************************/
  PROCEDURE update_contract_lines(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_contract_lines'; -- プログラム名
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
    ln_i2  INTEGER;  -- 相手方レコードのインデックス
--
    -- *** ローカル・カーソル ***
    -- リース契約明細レコードロックカーソル
    CURSOR lock_row_cur(
      in_contract_line_id NUMBER)
    IS
      SELECT xcl.contract_line_id contract_line_id
      FROM   xxcff_contract_lines xcl
      WHERE  xcl.contract_line_id = in_contract_line_id
      FOR UPDATE NOWAIT;
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
    -- 2つのレコードに対するリース契約明細テーブル更新
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- 相手方レコードのインデックスを算出
      ln_i2 := ABS(i-3);
--
      -- 契約明細内部IDがNULLでない場合、リース契約明細の更新を行う
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        BEGIN
          -- 更新対象レコードのロック
          OPEN  lock_row_cur(g_object_headers_tab(i).contract_line_id);
          CLOSE lock_row_cur;
--
          -- リース契約明細の更新
          UPDATE xxcff_contract_lines
          SET    object_header_id       = g_object_headers_tab(ln_i2).object_header_id,
                 last_updated_by        = cn_last_updated_by,
                 last_update_date       = cd_last_update_date,
                 last_update_login      = cn_last_update_login,
                 request_id             = cn_request_id,
                 program_application_id = cn_program_application_id,
                 program_id             = cn_program_id,
                 program_update_date    = cd_program_update_date
          WHERE  contract_line_id = g_object_headers_tab(i).contract_line_id;
--
        EXCEPTION
          -- 更新対象データがロック中の場合、エラー
          WHEN record_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                           iv_name         => cv_msg_cff_00007,  -- メッセージコード
                           iv_token_name1  => cv_tkn_cff_00007,  -- トークンコード1
                           iv_token_value1 => cv_msg_cff_50030   -- トークン値1
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : update_object_headers
   * Description      : リース物件テーブル更新処理 (A-6)
   ***********************************************************************************/
  PROCEDURE update_object_headers(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_object_headers'; -- プログラム名
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
      lv_object_status VARCHAR2(3);  -- 更新用物件ステータス
--
    -- *** ローカル・カーソル ***
    -- リース物件レコードロックカーソル
    CURSOR lock_row_cur(
      in_object_header_id NUMBER)
    IS
      SELECT xoh.object_header_id object_header_id
      FROM   xxcff_object_headers xoh
      WHERE  xoh.object_header_id = in_object_header_id
      FOR UPDATE NOWAIT;
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
    -- 2つのレコードに対するリース物件テーブル更新
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- 物件ステータスの取得
      -- リース区分が'1'(原契約)の場合
      IF (g_object_headers_tab(i).xoh_lease_type = cv_lease_type_orgn) THEN
        -- 契約明細内部IDがNULLの場合、物件ステータスを'102'(契約済)とする
        IF (g_object_headers_tab(i).contract_line_id IS NULL) THEN
          lv_object_status := cv_obj_status_102;
        -- 契約明細内部IDがNOT NULLの場合、物件ステータスを'101'(未契約)とする
        ELSE
          lv_object_status := cv_obj_status_101;
        END IF;
      -- リース区分が'2'(再リース)の場合
      ELSE
        -- 契約明細内部IDがNULLの場合、物件ステータスを'104'(再リース契約済)とする
        IF (g_object_headers_tab(i).contract_line_id IS NULL) THEN
          lv_object_status := cv_obj_status_104;
        -- 契約明細内部IDがNOT NULLの場合、物件ステータスを'103'(再リース待)とする
        ELSE
          lv_object_status := cv_obj_status_103;
        END IF;
      END IF;
--
      BEGIN
        -- 更新対象レコードのロック
        OPEN  lock_row_cur(g_object_headers_tab(i).object_header_id);
        CLOSE lock_row_cur;
--
        -- リース物件の更新
        UPDATE xxcff_object_headers
        SET    object_status          = lv_object_status,
               last_updated_by        = cn_last_updated_by,
               last_update_date       = cd_last_update_date,
               last_update_login      = cn_last_update_login,
               request_id             = cn_request_id,
               program_application_id = cn_program_application_id,
               program_id             = cn_program_id,
               program_update_date    = cd_program_update_date
        WHERE  object_header_id = g_object_headers_tab(i).object_header_id;
--
      EXCEPTION
        -- 更新対象データがロック中の場合、エラー
        WHEN record_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_kbn_cff,    -- アプリケーション短縮名
                         iv_name         => cv_msg_cff_00007,  -- メッセージコード
                         iv_token_name1  => cv_tkn_cff_00007,  -- トークンコード1
                         iv_token_value1 => cv_msg_cff_50014   -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP record_loop;
--
  EXCEPTION
    WHEN global_process_expt THEN
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
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
      IF (lock_row_cur%ISOPEN) THEN
        CLOSE lock_row_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END update_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : insert_contract_histories
   * Description      : リース契約明細履歴テーブル登録処理 (A-7)
   ***********************************************************************************/
  PROCEDURE insert_contract_histories(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_contract_histories'; -- プログラム名
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
    -- 2つのレコードに対するリース契約明細履歴テーブル登録
    <<record_loop>>
    FOR i IN 1..2 LOOP
      -- 契約明細内部IDがNULLでない場合、リース契約明細履歴の登録を行う
      IF (g_object_headers_tab(i).contract_line_id IS NOT NULL) THEN
        INSERT INTO xxcff_contract_histories(
          contract_line_id,                          -- 契約明細内部ID
          contract_header_id,                        -- 契約内部ID
          history_num,                               -- 変更履歴NO
          contract_status,                           -- 契約ステータス
          first_charge,                              -- 初回月額リース料_リース料
          first_tax_charge,                          -- 初回消費税額_リース料
          first_total_charge,                        -- 初回計_リース料
          second_charge,                             -- 2回目以降月額リース料_リース料
          second_tax_charge,                         -- 2回目以降消費税額_リース料
          second_total_charge,                       -- 2回目以降計_リース料
          first_deduction,                           -- 初回月額リース料_控除額
          first_tax_deduction,                       -- 初回月額消費税額_控除額
          first_total_deduction,                     -- 初回計_控除額
          second_deduction,                          -- 2回目以降月額リース料_控除額
          second_tax_deduction,                      -- 2回目以降消費税額_控除額
          second_total_deduction,                    -- 2回目以降計_控除額
          gross_charge,                              -- 総額リース料_リース料
          gross_tax_charge,                          -- 総額消費税_リース料
          gross_total_charge,                        -- 総額計_リース料
          gross_deduction,                           -- 総額リース料_控除額
          gross_tax_deduction,                       -- 総額消費税_控除額
          gross_total_deduction,                     -- 総額計_控除額
          lease_kind,                                -- リース種類
          estimated_cash_price,                      -- 見積現金購入価額
          present_value_discount_rate,               -- 現在価値割引率
          present_value,                             -- 現在価値
          life_in_months,                            -- 法定耐用年数
          original_cost,                             -- 取得価額
          calc_interested_rate,                      -- 計算利子率
          object_header_id,                          -- 物件内部ID
          asset_category,                            -- 資産種類
          expiration_date,                           -- 満了日
          cancellation_date,                         -- 中途解約日
          vd_if_date,                                -- リース契約情報連携日
          info_sys_if_date,                          -- リース管理情報連携日
          first_installation_address,                -- 初回設置場所
          first_installation_place,                  -- 初回設置先
-- 2013/07/17 Ver.1.4 T.Nakano ADD Start
          tax_code,                                  -- 税金コード
-- 2013/07/17 Ver.1.4 T.Nakano ADD END
          accounting_date,                           -- 計上日
          accounting_if_flag,                        -- 会計ＩＦフラグ
          description,                               -- 摘要
          created_by,                                -- 作成者
          creation_date,                             -- 作成日
          last_updated_by,                           -- 最終更新者
          last_update_date,                          -- 最終更新日
          last_update_login,                         -- 最終更新ﾛｸﾞｲﾝ
          request_id,                                -- 要求ID
          program_application_id,                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
          program_id,                                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
          program_update_date)                       -- ﾌﾟﾛｸﾞﾗﾑ更新日
        SELECT xcl.contract_line_id,                 -- 契約明細内部ID
               xcl.contract_header_id,               -- 契約内部ID
               xxcff_contract_histories_s1.NEXTVAL,  -- 契約明細履歴シーケンス
               cv_cont_status_209,                   -- 契約ステータス('209'(情報変更))
               xcl.first_charge,                     -- 初回月額リース料_リース料
               xcl.first_tax_charge,                 -- 初回消費税額_リース料
               xcl.first_total_charge,               -- 初回計_リース料
               xcl.second_charge,                    -- 2回目以降月額リース料_リース料
               xcl.second_tax_charge,                -- 2回目以降消費税額_リース料
               xcl.second_total_charge,              -- 2回目以降計_リース料
               xcl.first_deduction,                  -- 初回月額リース料_控除額
               xcl.first_tax_deduction,              -- 初回月額消費税額_控除額
               xcl.first_total_deduction,            -- 初回計_控除額
               xcl.second_deduction,                 -- 2回目以降月額リース料_控除額
               xcl.second_tax_deduction,             -- 2回目以降消費税額_控除額
               xcl.second_total_deduction,           -- 2回目以降計_控除額
               xcl.gross_charge,                     -- 総額リース料_リース料
               xcl.gross_tax_charge,                 -- 総額消費税_リース料
               xcl.gross_total_charge,               -- 総額計_リース料
               xcl.gross_deduction,                  -- 総額リース料_控除額
               xcl.gross_tax_deduction,              -- 総額消費税_控除額
               xcl.gross_total_deduction,            -- 総額計_控除額
               xcl.lease_kind,                       -- リース種類
               xcl.estimated_cash_price,             -- 見積現金購入価額
               xcl.present_value_discount_rate,      -- 現在価値割引率
               xcl.present_value,                    -- 現在価値
               xcl.life_in_months,                   -- 法定耐用年数
               xcl.original_cost,                    -- 取得価額
               xcl.calc_interested_rate,             -- 計算利子率
               xcl.object_header_id,                 -- 物件内部ID
               xcl.asset_category,                   -- 資産種類
               xcl.expiration_date,                  -- 満了日
               xcl.cancellation_date,                -- 中途解約日
               xcl.vd_if_date,                       -- リース契約情報連携日
               xcl.info_sys_if_date,                 -- リース管理情報連携日
               xcl.first_installation_address,       -- 初回設置場所
               xcl.first_installation_place,         -- 初回設置先
-- 2013/07/17 Ver.1.4 T.Nakano ADD Start
               xcl.tax_code,                         -- 税金コード
-- 2013/07/17 Ver.1.4 T.Nakano ADD END
               gr_init_rec.process_date,             -- 計上日(業務日付)
               cv_if_flag_one,                       -- 会計IFフラグ('1'(未送信))
               NULL,                                 -- 摘要(NULL)
               cn_created_by,                        -- 作成者
               cd_creation_date,                     -- 作成日
               cn_last_updated_by,                   -- 最終更新者
               cd_last_update_date,                  -- 最終更新日
               cn_last_update_login,                 -- 最終更新ﾛｸﾞｲﾝ
               cn_request_id,                        -- 要求ID
               cn_program_application_id,            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               cn_program_id,                        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               cd_program_update_date                -- ﾌﾟﾛｸﾞﾗﾑ更新日
        FROM   xxcff_contract_lines xcl  -- 『リース契約明細』テーブル
        WHERE  xcl.contract_line_id = g_object_headers_tab(i).contract_line_id;
      END IF;
    END LOOP record_loop;
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
  END insert_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : insert_object_histories
   * Description      : リース物件履歴テーブル登録処理 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_object_histories(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_histories'; -- プログラム名
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
    -- 2つのレコードに対するリース物件履歴テーブル登録
    <<record_loop>>
    FOR i IN 1..2 LOOP
      INSERT INTO xxcff_object_histories(
        object_header_id,                        -- 物件内部ID
        history_num,                             -- 変更履歴NO
        object_code,                             -- 物件コード
        lease_class,                             -- リース種別
        lease_type,                              -- リース区分
        re_lease_times,                          -- 再リース回数
        po_number,                               -- 発注番号
        registration_number,                     -- 登録番号
        age_type,                                -- 年式
        model,                                   -- 機種
        serial_number,                           -- 機番
        quantity,                                -- 数量
        manufacturer_name,                       -- メーカー名
        department_code,                         -- 管理部門コード
        owner_company,                           -- 本社／工場
        installation_address,                    -- 現設置場所
        installation_place ,                     -- 現設置先
        chassis_number,                          -- 車台番号
        re_lease_flag,                           -- 再リース要フラグ
        cancellation_type,                       -- 解約区分
        cancellation_date,                       -- 中途解約日
        dissolution_date,                        -- 中途解約キャンセル日
        bond_acceptance_flag,                    -- 証書受領フラグ
        bond_acceptance_date,                    -- 証書受領日
        expiration_date,                         -- 満了日
        object_status,                           -- 物件ステータス
        active_flag,                             -- 物件有効フラグ
        info_sys_if_date,                        -- リース管理情報連携日
        generation_date,                         -- 発生日
        accounting_date,                         -- 計上日
        accounting_if_flag,                      -- 会計ＩＦフラグ
        m_owner_company,                         -- 移動元本社／工場
        m_department_code,                       -- 移動元管理部門
        m_installation_address,                  -- 移動元現設置場所
        m_installation_place ,                   -- 移動元現設置先
        m_registration_number,                   -- 移動元登録番号
        description,                             -- 摘要
        created_by,                              -- 作成者
        creation_date,                           -- 作成日
        last_updated_by,                         -- 最終更新者
        last_update_date,                        -- 最終更新日
        last_update_login,                       -- 最終更新ﾛｸﾞｲﾝ
        request_id,                              -- 要求ID
        program_application_id,                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        program_id,                              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        program_update_date)                     -- ﾌﾟﾛｸﾞﾗﾑ更新日
      SELECT xoh.object_header_id,               -- 物件内部ID
             xxcff_object_histories_s1.NEXTVAL,  -- 物件履歴シーケンス
             xoh.object_code,                    -- 物件コード
             xoh.lease_class,                    -- リース種別
             xoh.lease_type,                     -- リース区分
             xoh.re_lease_times,                 -- 再リース回数
             xoh.po_number,                      -- 発注番号
             xoh.registration_number,            -- 登録番号
             xoh.age_type,                       -- 年式
             xoh.model,                          -- 機種
             xoh.serial_number,                  -- 機番
             xoh.quantity,                       -- 数量
             xoh.manufacturer_name,              -- メーカー名
             xoh.department_code,                -- 管理部門コード
             xoh.owner_company,                  -- 本社／工場
             xoh.installation_address,           -- 現設置場所
             xoh.installation_place ,            -- 現設置先
             xoh.chassis_number,                 -- 車台番号
             xoh.re_lease_flag,                  -- 再リース要フラグ
             xoh.cancellation_type,              -- 解約区分
             xoh.cancellation_date,              -- 中途解約日
             xoh.dissolution_date,               -- 中途解約キャンセル日
             xoh.bond_acceptance_flag,           -- 証書受領フラグ
             xoh.bond_acceptance_date,           -- 証書受領日
             xoh.expiration_date,                -- 満了日
             xoh.object_status,                  -- 物件ステータス
             xoh.active_flag,                    -- 物件有効フラグ
             xoh.info_sys_if_date,               -- リース管理情報連携日
             xoh.generation_date,                -- 発生日
             gr_init_rec.process_date,           -- 計上日(業務日付)
             cv_if_flag_one,                     -- 会計IFフラグ('1'(未送信))
             NULL,                               -- 移動元本社／工場(NULL)
             NULL,                               -- 移動元管理部門(NULL)
             NULL,                               -- 移動元現設置場所(NULL)
             NULL,                               -- 移動元現設置先(NULL)
             NULL,                               -- 移動元登録番号(NULL)
             NULL,                               -- 摘要(NULL)
             cn_created_by,                      -- 作成者
             cd_creation_date,                   -- 作成日
             cn_last_updated_by,                 -- 最終更新者
             cd_last_update_date,                -- 最終更新日
             cn_last_update_login,               -- 最終更新ﾛｸﾞｲﾝ
             cn_request_id,                      -- 要求ID
             cn_program_application_id,          -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             cn_program_id,                      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             cd_program_update_date              -- ﾌﾟﾛｸﾞﾗﾑ更新日
      FROM   xxcff_object_headers xoh  -- 『リース物件』テーブル
      WHERE  xoh.object_header_id = g_object_headers_tab(i).object_header_id;
    END LOOP record_loop;
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
  END insert_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_obj_code1  IN  VARCHAR2,     --   1.物件コード1
    iv_obj_code2  IN  VARCHAR2,     --   2.物件コード2
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
    gn_target_cnt := 2;
    gn_normal_cnt := 0;
    gn_error_cnt  := gn_target_cnt;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  初期処理 (A-1)
    -- =====================================================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  リース物件テーブル取得処理 (A-2)
    -- =====================================================
    select_object_headers(
      iv_obj_code1,      -- 1.物件コード1
      iv_obj_code2,      -- 2.物件コード2
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  契約状況チェック (A-3)
    -- =====================================================
    check_contract_condition(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  整合性チェック (A-4)
    -- =====================================================
    validate_record(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 訂正対象の2物件とも契約済の場合
    IF (  (g_object_headers_tab(1).contract_line_id IS NOT NULL)
      AND (g_object_headers_tab(2).contract_line_id IS NOT NULL)  )
    THEN
      -- =====================================================
      --  リース契約明細テーブル更新処理 (A-5)
      -- =====================================================
      update_contract_lines(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  リース契約明細履歴テーブル登録処理 (A-7)
      -- =====================================================
      insert_contract_histories(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- 訂正対象のいずれかの物件のみ契約済の場合
    ELSE
      -- =====================================================
      --  リース契約明細テーブル更新処理 (A-5)
      -- =====================================================
      update_contract_lines(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  リース物件テーブル更新処理 (A-6)
      -- =====================================================
      update_object_headers(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  リース契約明細履歴テーブル登録処理 (A-7)
      -- =====================================================
      insert_contract_histories(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  リース物件履歴テーブル登録処理 (A-8)
      -- =====================================================
      insert_object_histories(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 正常終了の場合のグローバル変数の設定
    gn_error_cnt  := 0;
    gn_normal_cnt := gn_target_cnt;
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
    iv_obj_code1  IN  VARCHAR2,      --   1.物件コード1
    iv_obj_code2  IN  VARCHAR2       --   2.物件コード2
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
       iv_obj_code1  -- 物件コード1
      ,iv_obj_code2  -- 物件コード2
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
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
END XXCFF003A33C;
/
