CREATE OR REPLACE PACKAGE BODY XXCFR004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A02C(body)
 * Description      : 支払通知データダウンロード
 * MD.050           : MD050_CFR_004_A02_支払通知データダウンロード
 * MD.070           : MD050_CFR_004_A02_支払通知データダウンロード
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  check_parameter        p 入力パラメータ値チェック処理            (A-2)
 *  get_profile_value      p プロファイル取得処理                    (A-3)
 *  insert_work_table      p ワークテーブルデータ登録                (A-4)
 *  put_out_file           p 支払通知データCSV作成処理               (A-5)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/19    1.00 SCS 中村 博      初回作成
 *  2011/09/28    1.1  SCS S.NIKI       [E_本稼動_07906]流通BMS対応
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR004A02C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
  cv_msg_004a02_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; --システムエラーメッセージ
--
  cv_msg_004a02_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_004a02_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00009'; --コンカレントパラメータ値大小チェックエラー
  cv_msg_004a02_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; --テーブル挿入エラー
  cv_msg_004a02_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --対象データ0件警告メッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_paranm_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- パラメータ名FROM
  cv_tkn_paranm_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- パラメータ名TO
  cv_tkn_paravl_from CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- パラメータ値FROM
  cv_tkn_paravl_to   CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- パラメータ値TO
--
  -- 参照タイプ名
  cv_lookup_type_pn  CONSTANT VARCHAR2(100) := 'XXCFR1_004A02_DATA';   -- CSV出力用参照タイプ
--
  --プロファイル
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP';  -- テーブル名
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_format_date_ymd    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';        -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- 日付フォーマット（年月日時分秒）
--
  cv_error_string    CONSTANT VARCHAR2(30) := 'Error';            -- エラー用店コード文字列
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id             NUMBER;             -- 組織ID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receipt_cust_code   IN      VARCHAR2,         --    入金先顧客
    iv_due_date_from       IN      VARCHAR2,         --    支払年月日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払年月日(TO)
    iv_received_date_from  IN      VARCHAR2,         --    受信日(FROM)
    iv_received_date_to    IN      VARCHAR2,         --    受信日(TO)
    ov_errbuf              OUT     VARCHAR2,         --    エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --    リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --    ユーザー・エラー・メッセージ --# 固定 #
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
       iv_which        => cv_file_type_log      -- ログ出力
      ,iv_conc_param1  => iv_receipt_cust_code  -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_due_date_from      -- コンカレントパラメータ２
      ,iv_conc_param3  => iv_due_date_to        -- コンカレントパラメータ３
      ,iv_conc_param4  => iv_received_date_from -- コンカレントパラメータ４
      ,iv_conc_param5  => iv_received_date_to   -- コンカレントパラメータ５
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : check_parameter
   * Description      : 入力パラメータ値チェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_receipt_cust_code   IN      VARCHAR2,         --    入金先顧客
    iv_due_date_from       IN      VARCHAR2,         --    支払年月日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払年月日(TO)
    iv_received_date_from  IN      VARCHAR2,         --    受信日(FROM)
    iv_received_date_to    IN      VARCHAR2,         --    受信日(TO)
    ov_errbuf              OUT     VARCHAR2,         --    エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --    リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --    ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- プログラム名
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
    cv_conc_prefix     CONSTANT VARCHAR2(6)  := '$SRS$.';    -- コンカレント短縮名プリフィックス
    cv_const_yes       CONSTANT VARCHAR2(1)  := 'Y';         -- 使用可能='Y'
--
    -- *** ローカル変数 ***
    ld_due_date_from       date;   -- 支払年月日(FROM)
    ld_due_date_to         date;   -- 支払年月日(TO)
    ld_received_date_from  date;   -- 受信日(FROM)
    ld_received_date_to    date;   -- 受信日(TO)
--
    ln_target_cnt   NUMBER;         -- 重複している件数
--
    -- *** ローカル・カーソル ***
--
    -- コンカレントパラメータ名抽出
    CURSOR conc_param_name_cur1 IS
    SELECT fdfc.column_seq_num,
           fdfc.end_user_column_name,
           fdfc.description
      FROM fnd_concurrent_programs_vl  fcpv,
           fnd_descr_flex_col_usage_vl fdfc
     WHERE fdfc.application_id                = fnd_global.prog_appl_id  -- コンカレント・プログラムのアプリケーションID
       AND fdfc.descriptive_flexfield_name    = cv_conc_prefix || fcpv.concurrent_program_name
       AND fdfc.enabled_flag                  = cv_const_yes
       AND fdfc.application_id                = fcpv.application_id
       AND fcpv.concurrent_program_id         = fnd_global.conc_program_id  -- コンカレント・プログラムのプログラムID 
     ORDER BY fdfc.column_seq_num
    ;
--
    TYPE conc_param_name_tbl1 IS TABLE OF conc_param_name_cur1%ROWTYPE INDEX BY PLS_INTEGER;
    lt_conc_param_name_data1    conc_param_name_tbl1;
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
    -- 日付型の変換
    ld_due_date_from      := xxcfr_common_pkg.get_date_param_trans( iv_due_date_from );
    ld_due_date_to        := xxcfr_common_pkg.get_date_param_trans( iv_due_date_to );
    ld_received_date_from := xxcfr_common_pkg.get_date_param_trans( iv_received_date_from );
    ld_received_date_to   := xxcfr_common_pkg.get_date_param_trans( iv_received_date_to );
--
    --==============================================================
    --エラーメッセージ用にパラメータ名取得
    --==============================================================
    -- カーソルオープン
    OPEN conc_param_name_cur1;
--
    -- データの一括取得
    FETCH conc_param_name_cur1 BULK COLLECT INTO lt_conc_param_name_data1;
--
    -- 処理件数のセット
    ln_target_cnt := lt_conc_param_name_data1.COUNT;
--
    -- カーソルクローズ
    CLOSE conc_param_name_cur1;
--
    IF ( ld_due_date_from > ld_due_date_to ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_011 -- パラメータ値大小チェックエラー
                                                    ,cv_tkn_paranm_from -- トークン'PARAM_NAME_FROM'
                                                    ,lt_conc_param_name_data1(2).description -- 支払年月日(FROM)
                                                    ,cv_tkn_paranm_to   -- トークン'PARAM_NAME_TO'
                                                    ,lt_conc_param_name_data1(3).description -- 支払年月日(TO)
                                                    ,cv_tkn_paravl_from -- トークン'PARAM_VAL_FROM'
                                                    ,TO_CHAR( ld_due_date_from, cv_format_date_ymd )
                                                    ,cv_tkn_paravl_to   -- トークン'PARAM_VAL_TO'
                                                    ,TO_CHAR( ld_due_date_to, cv_format_date_ymd ))
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
    END IF;
--
    IF ( ld_received_date_from > ld_received_date_to ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_011 -- パラメータ値大小チェックエラー
                                                    ,cv_tkn_paranm_from -- トークン'PARAM_NAME_FROM'
                                                    ,lt_conc_param_name_data1(4).description -- 受信日(FROM)
                                                    ,cv_tkn_paranm_to   -- トークン'PARAM_NAME_TO'
                                                    ,lt_conc_param_name_data1(5).description -- 受信日(TO)
                                                    ,cv_tkn_paravl_from -- トークン'PARAM_VAL_FROM'
                                                    ,TO_CHAR( ld_received_date_from, cv_format_date_ymd )
                                                    ,cv_tkn_paravl_to   -- トークン'PARAM_VAL_TO'
                                                    ,TO_CHAR( ld_received_date_to, cv_format_date_ymd ))
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
    END IF;
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-3)
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
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_004a02_010 -- プロファイル取得エラー
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-4)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_receipt_cust_code    IN  VARCHAR2,            -- 入金先顧客
    iv_due_date_from        IN  VARCHAR2,            -- 支払年月日(FROM)
    iv_due_date_to          IN  VARCHAR2,            -- 支払年月日(TO)
    iv_received_date_from   IN  VARCHAR2,            -- 受信日(FROM)
    iv_received_date_to     IN  VARCHAR2,            -- 受信日(TO)
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- プログラム名
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
    cv_rounding_rule_n   CONSTANT VARCHAR2(10) := 'NEAREST';  -- 四捨五入
    cv_rounding_rule_u   CONSTANT VARCHAR2(10) := 'UP';       -- 切上げ
    cv_rounding_rule_d   CONSTANT VARCHAR2(10) := 'DOWN';     -- 切捨て
    cv_bill_to           CONSTANT VARCHAR2(10) := 'BILL_TO';  -- 使用目的：請求先
    cv_status_op         CONSTANT VARCHAR2(10) := 'OP';       -- ステータス：オープン
    cv_status_enabled    CONSTANT VARCHAR2(10) := 'A';        -- ステータス：有効
    cv_relate_class      CONSTANT VARCHAR2(10) := '1';        -- 関連分類：入金
    cv_lookup_tax_type   CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN';   -- 消費税区分
    cv_sales_rep_attr    CONSTANT VARCHAR2(30) := 'RESOURCE' ; -- 担当営業員属性
    cv_db_space          CONSTANT VARCHAR2(2)  := CHR(33088); -- 全角スペース
    cv_format_ymd        CONSTANT VARCHAR2(10) := 'YYYYMMDD'; -- 日付フォーマット（年月日）
--
    -- *** ローカル変数 ***
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    lv_no_data_msg          VARCHAR2(5000); -- 帳票０件メッセージ
    lv_due_date_from        VARCHAR2(8);    -- 支払年月日(FROM)
    lv_due_date_to          VARCHAR2(8);    -- 支払年月日(TO)
    lv_received_date_from   VARCHAR2(8);    -- 受信日(FROM)
    lv_received_date_to     VARCHAR2(8);    -- 受信日(TO)
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
    -- パラメータの型変換
    -- ====================================================
    lv_due_date_from      := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_due_date_from ), cv_format_ymd );
    lv_due_date_to        := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_due_date_to ), cv_format_ymd );
    lv_received_date_from := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_received_date_from ), cv_format_ymd );
    lv_received_date_to   := TO_CHAR( xxcfr_common_pkg.get_date_param_trans( iv_received_date_to ), cv_format_ymd );
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
    BEGIN
--
      INSERT INTO xxcfr_csv_outs_temp ( 
         request_id
        ,seq
        ,col1
        ,col2
        ,col3
        ,col4
        ,col5
        ,col6
        ,col7
        ,col8
        ,col9
        ,col10
        ,col11
        ,col12
        ,col13
        ,col14
        ,col15
        ,col16
        ,col17
        ,col18
        ,col19
        ,col20
        ,col21
        ,col22
        ,col23
        ,col24
        ,col25
        ,col26
        ,col27
        ,col28
        ,col29
        ,col30
        ,col31
        ,col32
        ,col33
        ,col34
        ,col35
        ,col36
        ,col37
        ,col38
        ,col39
        ,col40
        ,col41
        ,col42
        ,col43
        ,col44
        ,col45
        ,col46
        ,col47
        ,col48
        ,col49
        ,col50
        ,col51
        ,col52
        ,col53
        ,col54
        ,col55
        ,col56
        ,col57
        ,col58
        ,col59
        ,col60
-- Add 2011/09/28 Ver1.1 Start
        ,col61
        ,col62
-- Add 2011/09/28 Ver1.1 End
      )
      SELECT
        cn_request_id                         request_id,               -- 要求ID
        ROWNUM                                seq,                      -- 連番
        xpay.chain_shop_code                  chain_shop_code,          -- チェーン店コード
        xpay.process_date                     process_date,             -- データ処理日付
        xpay.process_time                     process_time,             -- データ処理時刻
        xpay.vendor_code                      vendor_code,              -- 仕入先コード
        xpay.vendor_name                      vendor_name,              -- 仕入先名称/取引先名称（漢字）
        xpay.vendor_name_alt                  vendor_name_alt,          -- 仕入先名称/取引先名称（カナ）
        xpay.company_code                     company_code,             -- 社コード
        xpay.period_from                      period_from,              -- 対象期間・自
        xpay.period_to                        period_to,                -- 対象期間・至
        xpay.invoice_close_date               invoice_close_date,       -- 請求締年月日
        xpay.payment_date                     payment_date,             -- 支払年月日
        xpay.site_month                       site_month,               -- サイト月数
        xpay.note_count                       note_count,               -- 伝票枚数
        xpay.credit_note_count                credit_note_count,        -- 訂正伝票枚数
        xpay.rem_acceptance_count             rem_acceptance_count,     -- 未検収伝票枚数
        xpay.vendor_record_count              vendor_record_count,      -- 取引先内レコード通番
        xpay.invoice_number                   invoice_number,           -- 請求番号
        xpay.invoice_type                     invoice_type,             -- 請求区分
        xpay.payment_type                     payment_type,             -- 支払区分
        xpay.payment_method_type              payment_method_type,      -- 支払方法区分
        xpay.due_type                         due_type,                 -- 発行区分
        xpay.ebs_cust_account_number          ebs_cust_account_number,  -- 変換後ＥＢＳ顧客コード
        xpay.shop_code                        shop_code,                -- 店コード
        xpay.shop_name                        shop_name,                -- 店舗名称（漢字）
        xpay.shop_name_alt                    shop_name_alt,            -- 店舗名称（カナ）
        xpay.amount_sign                      amount_sign,              -- 金額符号
        xpay.amount                           amount,                   -- 金額
        xpay.tax_type                         tax_type,                 -- 消費税区分
        xpay.tax_rate                         tax_rate,                 -- 消費税率
        xpay.tax_amount                       tax_amount,               -- 消費税額
        xpay.tax_diff_flag                    tax_diff_flag,            -- 消費税差額フラグ
        xpay.diff_calc_flag                   diff_calc_flag,           -- 違算区分
        xpay.match_type                       match_type,               -- マッチ区分
        xpay.unmatch_accoumt_amount           unmatch_accoumt_amount,   -- アンマッチ買掛計上金額
        xpay.double_type                      double_type,              -- ダブリ区分
        xpay.acceptance_date                  acceptance_date,          -- 検収日
        xpay.max_month                        max_month,                -- 月限
        xpay.note_number                      note_number,              -- 伝票番号
        xpay.line_number                      line_number,              -- 行№
        xpay.note_type                        note_type,                -- 伝票区分
        xpay.class_code                       class_code,               -- 分類コード
        xpay.div_code                         div_code,                 -- 部門コード
        xpay.sec_code                         sec_code,                 -- 課コード
        xpay.return_type                      return_type,              -- 売上返品区分
        xpay.nitiriu_type                     nitiriu_type,             -- ニチリウ経由区分
        xpay.sp_sale_type                     sp_sale_type,             -- 特売区分
        xpay.shipment                         shipment,                 -- 便
        xpay.order_date                       order_date,               -- 発注日
        xpay.delivery_date                    delivery_date,            -- 納品日_返品日
        xpay.product_code                     product_code,             -- 商品コード
        xpay.product_name                     product_name,             -- 商品名（漢字）
        xpay.product_name_alt                 product_name_alt,         -- 商品名（カナ）
        xpay.delivery_quantity                delivery_quantity,        -- 納品数量
        xpay.cost_unit_price                  cost_unit_price,          -- 原価単価
        xpay.cost_price                       cost_price,               -- 原価金額
        xpay.desc_code                        desc_code,                -- 備考コード
        xpay.chain_orig_desc                  chain_orig_desc,          -- チェーン固有エリア
        xpay.sum_amount                       sum_amount,               -- 合計金額
        xpay.discount_sum_amount              discount_sum_amount,      -- 値引合計金額
-- Modify 2011/09/28 Ver1.1 Start
--        xpay.return_sum_amount                return_sum_amount         -- 返品合計金額
        xpay.return_sum_amount                return_sum_amount,        -- 返品合計金額
        xpay.bms_header_data                  bms_header_data,          -- 流通ＢＭＳヘッダデータ
        xpay.bms_line_data                    bms_line_data             -- 流通ＢＭＳ明細データ
-- Modify 2011/09/28 Ver1.1 End
      FROM
        (
        SELECT
          xpn.chain_shop_code                 chain_shop_code,          -- チェーン店コード
          xpn.process_date                    process_date,             -- データ処理日付
          xpn.process_time                    process_time,             -- データ処理時刻
          xpn.vendor_code                     vendor_code,              -- 仕入先コード
          RTRIM( xpn.vendor_name, cv_db_space ) vendor_name,              -- 仕入先名称/取引先名称（漢字）
          RTRIM( xpn.vendor_name_alt )        vendor_name_alt,          -- 仕入先名称/取引先名称（カナ）
          xpn.company_code                    company_code,             -- 社コード
          xpn.period_from                     period_from,              -- 対象期間・自
          xpn.period_to                       period_to,                -- 対象期間・至
          xpn.invoice_close_date              invoice_close_date,       -- 請求締年月日
          xpn.payment_date                    payment_date,             -- 支払年月日
          TO_CHAR( xpn.site_month )           site_month,               -- サイト月数
          TO_CHAR( xpn.note_count )           note_count,               -- 伝票枚数
          TO_CHAR( xpn.credit_note_count )    credit_note_count,        -- 訂正伝票枚数
          TO_CHAR( xpn.rem_acceptance_count ) rem_acceptance_count,     -- 未検収伝票枚数
          TO_CHAR( xpn.vendor_record_count )  vendor_record_count,      -- 取引先内レコード通番
          TO_CHAR( xpn.invoice_number )       invoice_number,           -- 請求番号
          xpn.invoice_type                    invoice_type,             -- 請求区分
          xpn.payment_type                    payment_type,             -- 支払区分
          xpn.payment_method_type             payment_method_type,      -- 支払方法区分
          xpn.due_type                        due_type,                 -- 発行区分
          xpn.ebs_cust_account_number         ebs_cust_account_number,  -- EBS顧客コード
          xpn.shop_code                       shop_code,                -- 店コード
          RTRIM( xpn.shop_name, cv_db_space ) shop_name,                -- 店舗名称（漢字）
          RTRIM( xpn.shop_name_alt )          shop_name_alt,            -- 店舗名称（カナ）
          xpn.amount_sign                     amount_sign,              -- 金額符号
          TO_CHAR( xpn.amount )               amount,                   -- 金額
          xpn.tax_type                        tax_type,                 -- 消費税区分
          TO_CHAR( xpn.tax_rate )             tax_rate,                 -- 消費税率
          TO_CHAR( xpn.tax_amount )           tax_amount,               -- 消費税額
          xpn.tax_diff_flag                   tax_diff_flag,            -- 消費税差額フラグ
          xpn.diff_calc_flag                  diff_calc_flag,           -- 違算区分
          xpn.match_type                      match_type,               -- マッチ区分
          TO_CHAR( xpn.unmatch_accoumt_amount ) unmatch_accoumt_amount, -- アンマッチ買掛計上金額
          xpn.double_type                     double_type,              -- ダブリ区分
          xpn.acceptance_date                 acceptance_date,          -- 検収日
          xpn.max_month                       max_month,                -- 月限
          xpn.note_number                     note_number,              -- 伝票番号
          TO_CHAR( xpn.line_number )          line_number,              -- 行№
          xpn.note_type                       note_type,                -- 伝票区分
          xpn.class_code                      class_code,               -- 分類コード
          xpn.div_code                        div_code,                 -- 部門コード
          xpn.sec_code                        sec_code,                 -- 課コード
          TO_CHAR( xpn.return_type )          return_type,              -- 売上返品区分
          xpn.nitiriu_type                    nitiriu_type,             -- ニチリウ経由区分
          xpn.sp_sale_type                    sp_sale_type,             -- 特売区分
          xpn.shipment                        shipment,                 -- 便
          xpn.order_date                      order_date,               -- 発注日
          xpn.delivery_date                   delivery_date,            -- 納品日_返品日
          xpn.product_code                    product_code,             -- 商品コード
          RTRIM( xpn.product_name, cv_db_space ) product_name,          -- 商品名（漢字）
          RTRIM( xpn.product_name_alt )       product_name_alt,         -- 商品名（カナ）
          TO_CHAR( xpn.delivery_quantity )    delivery_quantity,        -- 納品数量
          TO_CHAR( xpn.cost_unit_price )      cost_unit_price,          -- 原価単価
          TO_CHAR( xpn.cost_price )           cost_price,               -- 原価金額
          xpn.desc_code                       desc_code,                -- 備考コード
          RTRIM( xpn.chain_orig_desc )        chain_orig_desc,          -- チェーン固有エリア
          TO_CHAR( xpn.sum_amount )           sum_amount,               -- 合計金額
          TO_CHAR( xpn.discount_sum_amount )  discount_sum_amount,      -- 値引合計金額
-- Modify 2011/09/28 Ver1.1 Start
--          TO_CHAR( xpn.return_sum_amount )    return_sum_amount         -- 返品合計金額
          TO_CHAR( xpn.return_sum_amount )    return_sum_amount,        -- 返品合計金額
          xpn.bms_header_data                 bms_header_data,          -- 流通ＢＭＳヘッダデータ
          xpn.bms_line_data                   bms_line_data             -- 流通ＢＭＳ明細データ
-- Modify 2011/09/28 Ver1.1 End
        FROM xxcfr_payment_notes        xpn,             -- 支払通知情報テーブル
             xxcfr_cust_hierarchy_v     xchv             -- 顧客階層ビュー
        WHERE ( lv_due_date_from          IS NULL
             OR xpn.payment_date          >= lv_due_date_from )
          AND ( lv_due_date_to            IS NULL
             OR xpn.payment_date          <= lv_due_date_to )
          AND ( lv_received_date_from     IS NULL
             OR xpn.process_date          >= lv_received_date_from )
          AND ( lv_received_date_to       IS NULL
             OR xpn.process_date          <= lv_received_date_to )
          AND xpn.ebs_cust_account_number =  xchv.ship_account_number(+)
          AND ( iv_receipt_cust_code      IS NULL
             OR xchv.cash_account_number  =  iv_receipt_cust_code
             OR ( iv_receipt_cust_code        = cv_error_string
              AND xpn.ebs_cust_account_number = iv_receipt_cust_code ))
          AND xpn.org_id                  =  gn_org_id
        ORDER BY
          xchv.cash_account_number,       -- 入金先顧客コード
          xpn.ebs_cust_account_number,    -- EBS顧客コード
          xpn.acceptance_date,            -- 検収日
          xpn.delivery_date               -- 納品日_返品日
        ) xpay
    ;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
      -- 登録データが１件も存在しない場合、警告終了することとする。
      IF ( gn_target_cnt = 0 ) THEN
        -- 警告終了
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a02_013    -- 対象データ0件警告
                                                      )
                                                      ,1
                                                      ,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_warn;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- 登録時エラー
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_004a02_012    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 営業員別払日別入金予定表帳票ワークテーブル
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- 成功件数の設定
    gn_normal_cnt := gn_target_cnt;
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : put_out_file
   * Description      : 支払通知データCSV作成処理 (A-5)
   ***********************************************************************************/
  PROCEDURE put_out_file(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_out_file'; -- プログラム名
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
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================================
    --  支払通知データCSV作成処理 (A-5)
    -- =====================================================
--
    xxcfr_common_pkg.csv_out(
       in_request_id   => cn_request_id        -- 要求ID
      ,iv_lookup_type  => cv_lookup_type_pn    -- 参照タイプ名（CSVカラム定義）
      ,in_rec_cnt      => gn_target_cnt        -- 対象件数
      ,ov_errbuf       => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- CSV出力用共通関数の呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
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
  END put_out_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_receipt_cust_code   IN      VARCHAR2,         --   入金先顧客
    iv_due_date_from       IN      VARCHAR2,         --   支払年月日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --   支払年月日(TO)
    iv_received_date_from  IN      VARCHAR2,         --   受信日(FROM)
    iv_received_date_to    IN      VARCHAR2,         --   受信日(TO)
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
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
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_receipt_cust_code   -- 入金拠点
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_received_date_from  -- 受信日(FROM)
      ,iv_received_date_to    -- 受信日(TO)
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入力パラメータ値チェック処理(A-2)
    -- =====================================================
    check_parameter(
       iv_receipt_cust_code   -- 入金拠点
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_received_date_from  -- 受信日(FROM)
      ,iv_received_date_to    -- 受信日(TO)
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-3)
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
    --  ワークテーブルデータ登録 (A-4)
    -- =====================================================
    insert_work_table(
       iv_receipt_cust_code   -- 入金拠点
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_received_date_from  -- 受信日(FROM)
      ,iv_received_date_to    -- 受信日(TO)
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --(戻り値の保存)
      ov_errmsg  := lv_errmsg;
      ov_retcode := lv_retcode;
    END IF;
--
    -- =====================================================
    --  支払通知データCSV作成処理 (A-5)
    -- =====================================================
    put_out_file(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
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
    iv_receipt_cust_code   IN      VARCHAR2,         --    入金先顧客
    iv_due_date_from       IN      VARCHAR2,         --    支払年月日(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    支払年月日(TO)
    iv_received_date_from  IN      VARCHAR2,         --    受信日(FROM)
    iv_received_date_to    IN      VARCHAR2          --    受信日(TO)
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
      ,ov_retcode => lv_retcode
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
       iv_receipt_cust_code   -- 入金拠点
      ,iv_due_date_from       -- 支払期日(FROM)
      ,iv_due_date_to         -- 支払期日(TO)
      ,iv_received_date_from  -- 受信日(FROM)
      ,iv_received_date_to    -- 受信日(TO)
      ,lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_004a02_009
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCFR004A02C;
/
