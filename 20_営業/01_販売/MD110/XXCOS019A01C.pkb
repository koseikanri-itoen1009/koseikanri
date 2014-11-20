CREATE OR REPLACE PACKAGE BODY APPS.XXCOS019A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS019A01C (body)
 * Description      : 重複タスク情報の削除を行う
 * MD.050           : 重複タスク削除処理 (MD050_COS_019_A01)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_dup_task           重複タスク検索処理(A-2)
 *  del_dup_task           重複タスク削除処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/07    1.0   K.NARAHARA       新規作成
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  global_period_err_expt   EXCEPTION;   -- 会計期間取得エラー例外ハンドラ
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOS019A01C';      -- パッケージ名
--
  cv_application             CONSTANT VARCHAR2(5)   := 'XXCOS';             -- アプリケーション名
--
  -- メッセージコード
  cv_msg_period              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00026';  -- 会計期間取得エラー
  cv_msg_nodata              CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- 対象データ無しエラー
  cv_msg_del                 CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14201';  -- 削除メッセージ
  cv_msg_count               CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14202';  -- 件数メッセージ
--
  -- トークン
  cv_tkn_acct_name           CONSTANT VARCHAR2(20)  := 'ACCOUNT_NAME';      -- 会計期間区分値
  cv_tkn_cust_code           CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';     -- 顧客コード
  cv_tkn_cust_name           CONSTANT VARCHAR2(20)  := 'CUSTOMER_NAME';     -- 顧客名
  cv_tkn_actual_date         CONSTANT VARCHAR2(20)  := 'ACTUAL_DATE';       -- 実績日
  cv_tkn_visit_kbn           CONSTANT VARCHAR2(20)  := 'VISIT_KBN';         -- 有効訪問区分
  cv_tkn_count1              CONSTANT VARCHAR2(20)  := 'COUNT1';            -- 対象件数
  cv_tkn_count2              CONSTANT VARCHAR2(20)  := 'COUNT2';            -- 削除件数
  cv_tkn_count3              CONSTANT VARCHAR2(20)  := 'COUNT3';            -- エラー件数
--
  -- その他定数
  cv_ar_class                CONSTANT VARCHAR2(20)  := '02';                -- 02:AR会計期間区分値
  cv_ar                      CONSTANT VARCHAR2(20)  := 'AR';                -- 会計期間区分値：AR
  cv_entry_type3             CONSTANT VARCHAR2(20)  := '3';                 -- 登録区分：3（納品情報）
  cv_entry_type4             CONSTANT VARCHAR2(20)  := '4';                 -- 登録区分：4（集金情報）
  cv_entry_type5             CONSTANT VARCHAR2(20)  := '5';                 -- 登録区分：5（消化VD情報）
  cv_n                       CONSTANT VARCHAR2(20)  := 'N';                 -- フラグ：N
  cv_party                   CONSTANT VARCHAR2(20)  := 'PARTY';             -- ソースオブジェクトコード：PARTY
  cv_rs_employee             CONSTANT VARCHAR2(20)  := 'RS_EMPLOYEE';       -- タスク所有者タイプコード：RS_EMPLOYEE
  cv_date_format             CONSTANT VARCHAR2(20)  := 'YYYY/MM/DD';        -- 日付書式
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 重複タスクデータ格納用レコード
  TYPE g_rec_dup_task_data   IS RECORD
    (
      account_number         hz_cust_accounts.account_number%TYPE,          -- 顧客番号
      party_name             hz_parties.party_name%TYPE,                    -- 顧客名
      task_id                jtf_tasks_b.task_id%TYPE,                      -- タスクID
      owner_id               jtf_tasks_b.owner_id%TYPE,                     -- タスク所有者ID
      source_object_id       jtf_tasks_b.source_object_id%TYPE,             -- ソースオブジェクトID
      actual_end_date        jtf_tasks_b.actual_end_date%TYPE,              -- 実績日
      attribute11            jtf_tasks_b.attribute11%TYPE,                  -- 有効訪問区分
      creation_date          jtf_tasks_b.creation_date%TYPE,                -- 作成日
      object_version_number  jtf_tasks_b.object_version_number%TYPE         -- オブジェクトヴァージョン番号
    );
--
  -- 重複タスクデータ格納用テーブル
  TYPE g_tab_dup_task_data   IS TABLE OF g_rec_dup_task_data INDEX BY PLS_INTEGER;
--
  -- 削除メッセージ格納用テーブル
  TYPE g_tab_del_msg_data    IS TABLE OF VARCHAR(1000) INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_chk_start_date          DATE;                                          -- チェック開始日付
  gt_dup_task_data           g_tab_dup_task_data;                           -- 重複タスクデータ
  gt_del_msg_data            g_tab_del_msg_data;                            -- 削除メッセージ
  gn_dup_cnt                 NUMBER;                                        -- 重複件数
  gn_del_cnt                 NUMBER;                                        -- 削除件数
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
--
    -- *** ローカル変数 ***
    lv_status        VARCHAR2(5);       -- 会計期間情報：ステータス
    ld_from_date     DATE;              -- 会計期間情報：開始年月日
    ld_to_date       DATE;              -- 会計期間情報：終了年月日
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
    -- 共通関数＜会計期間情報取得＞
    xxcos_common_pkg.get_account_period(
      cv_ar_class         -- 02:AR会計期間区分値
     ,NULL                -- 基準日
     ,lv_status           -- ステータス
     ,ld_from_date        -- 開始年月日
     ,ld_to_date          -- 終了年月日
     ,lv_errbuf           -- エラー・メッセージ
     ,lv_retcode          -- リターン・コード
     ,lv_errmsg           -- ユーザー・エラー・メッセージ
      );
--
    -- エラーチェック
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_period_err_expt;
    END IF;
--
    -- 取得した開始日をチェック開始日付に設定
    gd_chk_start_date := ld_from_date;  -- チェック開始日付
--
  EXCEPTION
--
    -- 会計期間取得エラー
    WHEN global_period_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_period,     -- 会計期間取得エラー
                     iv_token_name1  => cv_tkn_acct_name,  -- トークン：ACCOUNT_NAME
                     iv_token_value1 => cv_ar              -- 会計期間区分値：AR
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;

--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_dup_task
   * Description      : 重複タスク検索処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_dup_task(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dup_task'; -- プログラム名
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
    -- 重複タスク検索カーソル
    CURSOR get_dup_task_data_cur
    IS
    SELECT   /*+ USE_NL(task jtb_2 hca hp)*/
             hca.account_number            account_number,         -- 顧客番号
             hp.party_name                 party_name,             -- 顧客名
             jtb_2.task_id                 task_id,                -- タスクID
             jtb_2.owner_id                owner_id,               -- タスク所有者ID
             jtb_2.source_object_id        source_object_id,       -- ソースオブジェクトID
             TRUNC(jtb_2.actual_end_date)  actual_end_date,        -- 実績日
             jtb_2.attribute11             attribute11,            -- 有効訪問区分
             jtb_2.creation_date           creation_date,          -- 作成日
             jtb_2.object_version_number   object_version_number   -- オブジェクトヴァージョン番号
    FROM     hz_cust_accounts              hca,
             hz_parties                    hp,
             jtf_tasks_b                   jtb_2,
             (
             SELECT   /*+ INDEX_DESC(jtb XXCSO_JTF_TASKS_B_N20) */
                      jtb.owner_id                 owner_id,            -- タスク所有者ID
                      jtb.source_object_id         source_object_id,    -- ソースオブジェクトID
                      TRUNC(jtb.actual_end_date)   actual_end_date,     -- 実績日
                      COUNT(1)
             FROM     jtf.jtf_tasks_b              jtb
             WHERE    jtb.source_object_type_code  = cv_party           -- PARTY
             AND      jtb.attribute12              IN (cv_entry_type3,  -- 登録区分：3（納品情報）
                                                       cv_entry_type4,  -- 登録区分：4（集金情報）
                                                       cv_entry_type5)  -- 登録区分：5（消化VD情報）
             AND      jtb.deleted_flag             = cv_n               -- N
             AND      jtb.owner_type_code          = cv_rs_employee     -- RS_EMPLOYEE
             AND      TRUNC(jtb.actual_end_date)  >= gd_chk_start_date  -- チェック開始日付
             GROUP BY jtb.owner_id,                                     -- 所有者ID
                      jtb.source_object_id,                             -- ソースオブジェクトID
                      TRUNC(jtb.actual_end_date)                        -- 実績日
             HAVING   COUNT(1) > 1
             )                             task
    WHERE    hp.party_id                   = hca.party_id
    AND      hca.party_id                  = jtb_2.source_object_id
    AND      jtb_2.owner_id                = task.owner_id
    AND      jtb_2.source_object_id        = task.source_object_id
    AND      TRUNC(jtb_2.actual_end_date)  = task.actual_end_date
    AND      jtb_2.attribute12             IN (cv_entry_type3,  -- 登録区分：3（納品情報）
                                               cv_entry_type4,  -- 登録区分：4（集金情報）
                                               cv_entry_type5)  -- 登録区分：5（消化VD情報）
    AND      jtb_2.deleted_flag            = cv_n               -- N
    ORDER BY jtb_2.owner_id,
             jtb_2.source_object_id,
             TRUNC(jtb_2.actual_end_date),
             jtb_2.attribute11 DESC,
             jtb_2.task_id;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 重複タスクデータ取得
    --==============================================================
    -- カーソルOPEN
    OPEN  get_dup_task_data_cur;
    -- バルクフェッチ
    FETCH get_dup_task_data_cur BULK COLLECT INTO gt_dup_task_data;
    -- 重複件数セット
    gn_dup_cnt := get_dup_task_data_cur%ROWCOUNT;
    -- カーソルCLOSE
    CLOSE Get_Dup_Task_Data_Cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_dup_task;
--
  /***********************************************************************************
   * Procedure Name   : del_dup_task
   * Description      : 重複タスク削除処理(A-3)
   ***********************************************************************************/
  PROCEDURE del_dup_task(
    ov_errbuf         OUT VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_dup_task'; -- プログラム名
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
    -- *** ローカル型   ***
--
    -- *** ローカル・レコード ***
    -- 削除対象タスクデータ格納用レコード
    TYPE l_rec_del_task_data IS RECORD(
      task_id                jtf_tasks_b.task_id%TYPE,                 -- タスクID
      object_version_number  jtf_tasks_b.object_version_number%TYPE,   -- オブジェクトヴァージョン番号
      account_number         hz_cust_accounts.account_number%TYPE,     -- 顧客コード
      party_name             hz_parties.party_name%TYPE,               -- 顧客名
      actual_end_date        jtf_tasks_b.actual_end_date%TYPE,         -- 実績日
      attribute11            jtf_tasks_b.attribute11%TYPE              -- 有効訪問区分
    );
--
    -- 削除対象タスクデータ格納用テーブル
    TYPE l_tab_del_task_data    IS TABLE OF l_rec_del_task_data INDEX BY PLS_INTEGER;
--
    -- *** ローカル変数 ***
    lt_owner_id              jtf_tasks_b.owner_id%TYPE;                -- 所有者id
    lt_source_object_id      jtf_tasks_b.source_object_id%TYPE;        -- ソースオブジェクトid
    lt_actual_end_date       jtf_tasks_b.actual_end_date%TYPE;         -- 実績日
    ln_cnt                   NUMBER;                                   -- 配列用添え字
    lt_del_task_data         l_tab_del_task_data;                      -- 削除対象タスクデータ
--
    -- *** ローカル・カーソル ***
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
    -- 変数初期化
    lt_owner_id         := 0;
    lt_source_object_id := 0;
    lt_actual_end_date  := TO_DATE( '1900/01/01', cv_date_format);
    ln_cnt              := 0;
--
    -- 重複件数分ループ
    FOR i IN 1..gn_dup_cnt LOOP
      -- 前レコードと所有者ID、ソースオブジェクトID、実績日が等しい場合、削除対象とする
      IF  ( ( lt_owner_id         = gt_dup_task_data(i).owner_id )
        AND ( lt_source_object_id = gt_dup_task_data(i).source_object_id )
        AND ( lt_actual_end_date  = gt_dup_task_data(i).actual_end_date ) ) THEN
--
        -- 削除対象タスクデータを格納
        ln_cnt := ln_cnt + 1;
        lt_del_task_data(ln_cnt).task_id               := gt_dup_task_data(i).task_id;                -- タスクID
        lt_del_task_data(ln_cnt).object_version_number := gt_dup_task_data(i).object_version_number;  -- オブジェクトヴァージョン番号
        lt_del_task_data(ln_cnt).account_number        := gt_dup_task_data(i).account_number;         -- 顧客コード
        lt_del_task_data(ln_cnt).party_name            := gt_dup_task_data(i).party_name;             -- 顧客名
        lt_del_task_data(ln_cnt).actual_end_date       := gt_dup_task_data(i).actual_end_date;        -- 実績日
        lt_del_task_data(ln_cnt).attribute11           := gt_dup_task_data(i).attribute11;            -- 有効訪問区分
--
      END IF;
--
      -- 次レコードと比較するため現在のレコード情報を格納
      lt_owner_id         := gt_dup_task_data(i).owner_id;            -- 所有者ID
      lt_source_object_id := gt_dup_task_data(i).source_object_id;    -- ソースオブジェクトID
      lt_actual_end_date  := gt_dup_task_data(i).actual_end_date;     -- 実績日
--
    END LOOP;
--
    -- 削除対象件数セット
    gn_target_cnt := ln_cnt;
--
    -- 削除対象件数分ループ
    FOR i IN 1..gn_target_cnt LOOP
      -- 共通関数＜タスク削除＞
      xxcso_task_common_pkg.delete_task(
         in_task_id     => lt_del_task_data(i).task_id                -- タスクID
        ,in_obj_ver_num => lt_del_task_data(i).object_version_number  -- オブジェクトヴァージョン番号
        ,ov_errbuf      => lv_errbuf                                  -- エラーバッファー
        ,ov_retcode     => lv_retcode                                 -- エラーコード
        ,ov_errmsg      => lv_errmsg                                  -- エラーメッセージ
      );
      -- エラーチェック
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 削除件数カウントアップ
      gn_del_cnt := gn_del_cnt + 1;
      -- 削除メッセージ格納
      gt_del_msg_data(i) := xxccp_common_pkg.get_msg(
                              iv_application => cv_application,
                              iv_name        => cv_msg_del,                                                   -- 削除メッセージ
                              iv_token_name1 => cv_tkn_cust_code,                                             -- トークン：CUSTOMER_CODE
                              iv_token_value1=> lt_del_task_data(i).account_number,                           -- 顧客コード
                              iv_token_name2 => cv_tkn_cust_name,                                             -- トークン：CUSTOMER_NAME
                              iv_token_value2=> lt_del_task_data(i).party_name,                               -- 顧客名
                              iv_token_name3 => cv_tkn_actual_date,                                           -- トークン：ACTUAL_DATE
                              iv_token_value3=> TO_CHAR(lt_del_task_data(i).actual_end_date, cv_date_format), -- 実績日
                              iv_token_name4 => cv_tkn_visit_kbn,                                             -- トークン：VISIT_KBN
                              iv_token_value4=> lt_del_task_data(i).attribute11                               -- 有効訪問区分
                            );
--
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END del_dup_task;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
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
    gn_dup_cnt    := 0;
    gn_del_cnt    := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 重複タスク検索処理(A-2)
    -- ============================================
    get_dup_task(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 重複件数が1件以上存在する場合のみ削除処理を実行
    IF ( gn_dup_cnt >= 1 ) THEN
      -- ============================================
      -- 重複タスク削除処理(A-3)
      -- ============================================
      del_dup_task(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF ( lv_retcode != cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    Errbuf        Out Varchar2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- リターンコードが正常の場合
    IF ( lv_retcode = cv_status_normal ) THEN
      -- 重複件数が0件の場合
      IF ( gn_dup_cnt = 0 ) THEN
        -- 対象データなしメッセージを出力
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_nodata
                       );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        lv_message_code := cv_normal_msg;       -- 終了メッセージ：正常
        lv_retcode      := cv_status_normal;    -- リターンコード：正常
--
      -- 削除件数が1件以上存在する場合
      ELSIF ( gn_del_cnt >= 1 ) THEN
        -- 削除メッセージを出力
        FOR ck_no IN 1..gn_del_cnt LOOP
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => gt_del_msg_data(ck_no)
          );
          --空行挿入
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END LOOP;
        lv_message_code := cv_warn_msg;         -- 終了メッセージ：警告
        lv_retcode      := cv_status_warn;      -- リターンコード：警告
--
      END IF;
--
    -- リターンコードが正常以外の場合
    ELSE
      gn_del_cnt   := 0;    -- 削除件数初期化
      gn_error_cnt := 1;    -- エラー件数1件
      -- メッセージ出力
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
      lv_message_code := cv_error_msg;        -- 終了メッセージ：エラー
      lv_retcode      := cv_status_error;     -- リターンコード：エラー
--
    END IF;
--
    -- 件数メッセージを出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count
                    ,iv_token_name1  => cv_tkn_count1             -- トークン：COUNT1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)    -- 対象件数
                    ,iv_token_name2  => cv_tkn_count2             -- トークン：COUNT2
                    ,iv_token_value2 => TO_CHAR(gn_del_cnt)       -- 削除件数
                    ,iv_token_name3  => cv_tkn_count3             -- トークン：COUNT3
                    ,iv_token_value3 => TO_CHAR(gn_error_cnt)     -- エラー件数
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 終了メッセージを出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
END XXCOS019A01C;
