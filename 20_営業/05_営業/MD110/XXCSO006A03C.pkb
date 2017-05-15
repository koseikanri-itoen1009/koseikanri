CREATE OR REPLACE PACKAGE BODY APPS.XXCSO006A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCSO006A03C(body)
 * Description      : 訪問実績データワークテーブル（アドオン）に取り込まれた訪問実績データから、
 *                    タスクテーブルの登録／更新を行ないます。
 * MD.050           : MD050_CSO_006_A03_eSM-EBSインタフェース：（IN）訪問実績データ
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_visit_data              訪問実績データ取得処理                          (A-2)
 *  data_proper_check           データ妥当性チェック処理                        (A-3)
 *  get_visit_same_data         同一訪問実績データ取得処理                      (A-4)
 *  insert_visit_data           訪問実績データ登録処理                          (A-6)
 *  update_visit_data           訪問実績データ更新処理                          (A-7)
 *  delete_work_data            ワークテーブル削除処理                          (A-8)
 *  submain                     メイン処理プロシージャ
 *                              セーブポイント発行処理                          (A-5)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                              終了処理                                        (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/03/09    1.0   K.Kiriu          新規作成
 *  2017/04/20    1.1   N.Watanabe       E_本稼動_14025対応
 *
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
-- #######################  固定グローバル定数宣言部 END   #########################
--
-- #######################  固定グローバル変数宣言部 START #########################
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
-- #######################  固定グローバル変数宣言部 END   #########################
--
-- #######################  固定共通例外宣言部 START       #########################
--
  --*** 処理部共通例外 ***
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  固定共通例外宣言部 END         #########################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCSO006A03C';      -- パッケージ名
  cv_app_name                   CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
  cv_app_name_ccp               CONSTANT VARCHAR2(5)   := 'XXCCP';             -- アドオン：共通・IF領域
--
  -- メッセージコード
  cv_msg_ccp_90008              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  cv_msg_cso_00011              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_cso_00175              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- プロファイル取得エラー
  cv_msg_cso_00804              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00804';  -- 時刻書式エラー
  cv_msg_cso_00805              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00805';  -- マスタ存在なしエラー
  cv_msg_cso_00806              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00806';  -- 処理失敗エラー
  cv_msg_cso_00807              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00807';  -- 会計期間クローズエラー
  cv_msg_cso_00808              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00808';  -- 活動内容エラー
  cv_msg_cso_00809              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00809';  -- タスク存在エラー
  cv_msg_cso_00810              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00810';  -- ロック中エラー
  cv_msg_cso_00811              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00811';  -- 削除エラー
  -- メッセージコード(トークン用)
  cv_msg_cso_00707              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';  -- 「顧客コード」
  cv_msg_cso_00812              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00812';  -- 「社員コード」
  cv_msg_cso_00813              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00813';  -- 「リソースマスタビュー」
  cv_msg_cso_00814              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00814';  -- 「顧客マスタビュー」
  cv_msg_cso_00815              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00815';  -- 「訪問実績データワークテーブル」
  cv_msg_cso_00702              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00702';  -- 「登録」
  cv_msg_cso_00703              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- 「更新」
  cv_msg_cso_00715              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00715';  -- 「抽出」
  cv_msg_cso_00816              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00816';  -- 「活動内容１」
  cv_msg_cso_00817              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00817';  -- 「活動内容２」
  cv_msg_cso_00818              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00818';  -- 「活動内容３」
  cv_msg_cso_00819              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00819';  -- 「活動内容４」
  cv_msg_cso_00820              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00820';  -- 「活動内容５」
  cv_msg_cso_00821              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00821';  -- 「活動内容６」
  cv_msg_cso_00822              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00822';  -- 「活動内容７」
  cv_msg_cso_00823              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00823';  -- 「活動内容８」
  cv_msg_cso_00824              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00824';  -- 「活動内容９」
  cv_msg_cso_00825              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00825';  -- 「活動内容１０」
  cv_msg_cso_00826              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00826';  -- 「活動内容１１」
  cv_msg_cso_00827              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00827';  -- 「活動内容１２」
  cv_msg_cso_00828              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00828';  -- 「活動内容１３」
  cv_msg_cso_00829              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00829';  -- 「活動内容１４」
  cv_msg_cso_00830              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00830';  -- 「活動内容１５」
  cv_msg_cso_00831              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00831';  -- 「活動内容１６」
  cv_msg_cso_00832              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00832';  -- 「活動内容１７」
  cv_msg_cso_00833              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00833';  -- 「活動内容１８」
  cv_msg_cso_00834              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00834';  -- 「活動内容１９」
  cv_msg_cso_00835              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00835';  -- 「活動内容２０」
  cv_msg_cso_00836              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00836';  -- 「タスクテーブル」
  cv_msg_cso_00837              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00837';  -- 「削除エラー(成功0件)」
  cv_msg_cso_00838              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00838';  -- 「訪問開始時刻」
  cv_msg_cso_00839              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00839';  -- 「訪問終了時刻」
  -- トークンコード
  cv_tkn_profile                CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_item                   CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_table                  CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_table2                 CONSTANT VARCHAR2(20)  := 'TABLE2';
  cv_tkn_process                CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_emp_code               CONSTANT VARCHAR2(20)  := 'EMP_CODE';
  cv_tkn_cust_code              CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_tkn_visit_date             CONSTANT VARCHAR2(20)  := 'VISIT_DATE';
  cv_tkn_visit_time             CONSTANT VARCHAR2(20)  := 'VISIT_TIME';
  cv_tkn_visit_time_end         CONSTANT VARCHAR2(20)  := 'VISIT_TIME_END';
  cv_tkn_err_msg                CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_lookup_code                CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';
  -- 日付フォーマット
  cv_format_date_time           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_format_date_minute         CONSTANT VARCHAR2(18)  := 'YYYY/MM/DD HH24:MI';
  cv_format_date                CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_format_minute              CONSTANT VARCHAR2(7)   := 'HH24:MI';
  -- プロファイル
  cv_task_open                  CONSTANT VARCHAR2(26)  := 'XXCSO1_TASK_STATUS_OPEN_ID';    -- XXCSO:タスクステータス（オープン）
  cv_task_close                 CONSTANT VARCHAR2(28)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';  -- XXCSO:タスクステータス（クローズ）
  -- 参照タイプ
  cv_kubun_lookup_type          CONSTANT VARCHAR2(22)  := 'XXCSO_ASN_HOUMON_KUBUN';        -- 訪問区分(Task DFF)
  -- 活動内容の番号
  cv_activity_content01         CONSTANT VARCHAR2(1)   := '1';  -- 活動内容１
  cv_activity_content02         CONSTANT VARCHAR2(1)   := '2';  -- 活動内容２
  cv_activity_content03         CONSTANT VARCHAR2(1)   := '3';  -- 活動内容３
  cv_activity_content04         CONSTANT VARCHAR2(1)   := '4';  -- 活動内容４
  cv_activity_content05         CONSTANT VARCHAR2(1)   := '5';  -- 活動内容５
  cv_activity_content06         CONSTANT VARCHAR2(1)   := '6';  -- 活動内容６
  cv_activity_content07         CONSTANT VARCHAR2(1)   := '7';  -- 活動内容７
  cv_activity_content08         CONSTANT VARCHAR2(1)   := '8';  -- 活動内容８
  cv_activity_content09         CONSTANT VARCHAR2(1)   := '9';  -- 活動内容９
  cv_activity_content10         CONSTANT VARCHAR2(2)   := '10'; -- 活動内容１０
  cv_activity_content11         CONSTANT VARCHAR2(2)   := '11'; -- 活動内容１１
  cv_activity_content12         CONSTANT VARCHAR2(2)   := '12'; -- 活動内容１２
  cv_activity_content13         CONSTANT VARCHAR2(2)   := '13'; -- 活動内容１３
  cv_activity_content14         CONSTANT VARCHAR2(2)   := '14'; -- 活動内容１４
  cv_activity_content15         CONSTANT VARCHAR2(2)   := '15'; -- 活動内容１５
  cv_activity_content16         CONSTANT VARCHAR2(2)   := '16'; -- 活動内容１６
  cv_activity_content17         CONSTANT VARCHAR2(2)   := '17'; -- 活動内容１７
  cv_activity_content18         CONSTANT VARCHAR2(2)   := '18'; -- 活動内容１８
  cv_activity_content19         CONSTANT VARCHAR2(2)   := '19'; -- 活動内容１９
  cv_activity_content20         CONSTANT VARCHAR2(2)   := '20'; -- 活動内容２０
  -- 顧客区分
  ct_cust_class_code_cust       CONSTANT VARCHAR2(2)   := '10'; -- 顧客
  ct_cust_class_code_cyclic     CONSTANT VARCHAR2(2)   := '15'; -- 店舗営業
  ct_cust_class_code_tonya      CONSTANT VARCHAR2(2)   := '16'; -- 問屋帳合先
  -- 顧客ステータス
  ct_cust_status_mc_candidate   CONSTANT VARCHAR2(2)   := '10'; -- ＭＣ候補
  ct_cust_status_mc             CONSTANT VARCHAR2(2)   := '20'; -- ＭＣ
  ct_cust_status_sp_decision    CONSTANT VARCHAR2(2)   := '25'; -- ＳＰ決裁済
  ct_cust_status_approved       CONSTANT VARCHAR2(2)   := '30'; -- 承認済
  ct_cust_status_customer       CONSTANT VARCHAR2(2)   := '40'; -- 顧客
  ct_cust_status_break          CONSTANT VARCHAR2(2)   := '50'; -- 休止
  ct_cust_status_abort_approved CONSTANT VARCHAR2(2)   := '90'; -- 中止決裁済
  ct_cust_status_not_applicable CONSTANT VARCHAR2(2)   := '99'; -- 対象外
  -- タスク取得
  cv_code_employee              CONSTANT VARCHAR2(11)  := 'RS_EMPLOYEE';
  cv_code_party                 CONSTANT VARCHAR2(5)   := 'PARTY';
  -- 汎用
  cv_0                          CONSTANT VARCHAR2(1)   := '0';      -- 0:CHAR型
  cv_1                          CONSTANT VARCHAR2(1)   := '1';      -- 1:CHAR型
  cv_6                          CONSTANT VARCHAR2(1)   := '6';      -- 6:CHAR型
  cv_yes                        CONSTANT VARCHAR2(1)   := 'Y';      -- Y:YES
  cv_no                         CONSTANT VARCHAR2(1)   := 'N';      -- Y:NO
  cv_false                      CONSTANT VARCHAR2(5)   := 'FALSE';  -- FALSE:CHAR型
  cb_true                       CONSTANT BOOLEAN       := TRUE;     -- TRUE:BOOLEAN型
  cb_false                      CONSTANT BOOLEAN       := FALSE;    -- FALSE:BOOLEAN型
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル値
  gn_task_open                  NUMBER;  -- タスクステータス（オープン）
  gn_task_close                 NUMBER;  -- タスクステータス（クローズ）
  -- 業務日付
  gd_process_date               DATE;    -- 業務日付
  gb_rollback_flag              BOOLEAN; -- ロールバック要フラグ

  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR g_visit_work_cur
  IS
    SELECT xivd.seq_no                    seq_no                   -- シーケンス番号
          ,xivd.base_name                 base_name                -- 部署名
          ,xivd.employee_number           employee_number          -- 社員コード
          ,xivd.account_number            account_number           -- 顧客コード
          ,xivd.business_type             business_type            -- 業務タイプ
          ,xivd.visit_date                visit_date               -- 訪問日
          ,xivd.visit_time                visit_time               -- 訪問開始時刻
          ,xivd.visit_time_end            visit_time_end           -- 訪問終了時刻
          ,xivd.detail                    detail                   -- 詳細内容
          ,xivd.activity_content1         activity_content1        -- 活動内容１
          ,xivd.activity_content2         activity_content2        -- 活動内容２
          ,xivd.activity_content3         activity_content3        -- 活動内容３
          ,xivd.activity_content4         activity_content4        -- 活動内容４
          ,xivd.activity_content5         activity_content5        -- 活動内容５
          ,xivd.activity_content6         activity_content6        -- 活動内容６
          ,xivd.activity_content7         activity_content7        -- 活動内容７
          ,xivd.activity_content8         activity_content8        -- 活動内容８
          ,xivd.activity_content9         activity_content9        -- 活動内容９
          ,xivd.activity_content10        activity_content10       -- 活動内容１０
          ,xivd.activity_content11        activity_content11       -- 活動内容１１
          ,xivd.activity_content12        activity_content12       -- 活動内容１２
          ,xivd.activity_content13        activity_content13       -- 活動内容１３
          ,xivd.activity_content14        activity_content14       -- 活動内容１４
          ,xivd.activity_content15        activity_content15       -- 活動内容１５
          ,xivd.activity_content16        activity_content16       -- 活動内容１６
          ,xivd.activity_content17        activity_content17       -- 活動内容１７
          ,xivd.activity_content18        activity_content18       -- 活動内容１８
          ,xivd.activity_content19        activity_content19       -- 活動内容１９
          ,xivd.activity_content20        activity_content20       -- 活動内容２０
          ,xivd.activity_time1            activity_time1           -- 活動時間１（分）
          ,xivd.activity_time2            activity_time2           -- 活動時間２（分）
          ,xivd.activity_time3            activity_time3           -- 活動時間３（分）
          ,xivd.activity_time4            activity_time4           -- 活動時間４（分）
          ,xivd.activity_time5            activity_time5           -- 活動時間５（分）
          ,xivd.activity_time6            activity_time6           -- 活動時間６（分）
          ,xivd.activity_time7            activity_time7           -- 活動時間７（分）
          ,xivd.activity_time8            activity_time8           -- 活動時間８（分）
          ,xivd.activity_time9            activity_time9           -- 活動時間９（分）
          ,xivd.activity_time10           activity_time10          -- 活動時間１０（分）
          ,xivd.activity_time11           activity_time11          -- 活動時間１１（分）
          ,xivd.activity_time12           activity_time12          -- 活動時間１２（分）
          ,xivd.activity_time13           activity_time13          -- 活動時間１３（分）
          ,xivd.activity_time14           activity_time14          -- 活動時間１４（分）
          ,xivd.activity_time15           activity_time15          -- 活動時間１５（分）
          ,xivd.activity_time16           activity_time16          -- 活動時間１６（分）
          ,xivd.activity_time17           activity_time17          -- 活動時間１７（分）
          ,xivd.activity_time18           activity_time18          -- 活動時間１８（分）
          ,xivd.activity_time19           activity_time19          -- 活動時間１９（分）
          ,xivd.activity_time20           activity_time20          -- 活動時間２０（分）
          ,xivd.esm_input_date            esm_input_date           -- eSM入力日時
    FROM   xxcso_in_visit_data  xivd  -- 訪問実績データワークテーブル
    ;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- タスク登録・更新用
  TYPE g_visit_data_rtype IS RECORD(
     employee_number      per_people_f.employee_number%TYPE         -- 社員コード
    ,account_number       hz_cust_accounts.account_number%TYPE      -- 顧客コード
    ,visit_date           jtf_tasks_b.actual_end_date%TYPE          -- 訪問日時
    ,planned_end_date     jtf_tasks_b.planned_end_date%TYPE         -- データ入力日時
    ,description          jtf_tasks_tl.description%TYPE             -- 詳細内容
    ,task_status_id       jtf_tasks_b.task_status_id%TYPE           -- タスクステータス
    ,dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分１
    ,dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分２
    ,dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分３
    ,dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分４
    ,dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分５
    ,dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分６
    ,dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分７
    ,dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分８
    ,dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分９
    ,dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE     -- 訪問区分１０
    ,resource_id          jtf_rs_resource_extns.resource_id%TYPE    -- リソースID
    ,party_id             hz_parties.party_id%TYPE                  -- パーティID
    ,party_name           hz_parties.party_name%TYPE                -- パーティ名称
    ,customer_status      hz_parties.duns_number_c%TYPE             -- 顧客ステータス
  );
--
  -- 活動内容
  TYPE g_act_content_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY PLS_INTEGER;
  -- 訪問実績ワークデータ
  TYPE g_visit_work_ttype  IS TABLE OF g_visit_work_cur%ROWTYPE              INDEX BY PLS_INTEGER;
--
  g_visit_work_tab  g_visit_work_ttype;
  g_visit_data_rec  g_visit_data_rtype;
  g_act_content_tab g_act_content_ttype;
--
  -- *** ユーザー定義グローバル例外 ***
  global_skip_error_expt EXCEPTION;
  global_lock_expt       EXCEPTION;                                -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf           OUT  VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT  VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT  VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_pam_msg  VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- パラメータ出力
    -- =======================
    -- パラメータなし
    lv_pam_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_ccp   -- アプリケーション短縮名
                   ,iv_name         => cv_msg_ccp_90008  -- メッセージコード
                 );
   -- ログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_pam_msg
    );
   -- 出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_pam_msg
    );
--
    -- =======================
    -- 業務日付取得
    -- =======================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付が取得できない場合
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name    -- アプリケーション短縮名
                     ,iv_name        => cv_msg_cso_00011  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =======================
    -- プロファイル値取得 
    -- =======================
    -- XXCSO: タスクステータス（オープン）
    BEGIN
      gn_task_open := FND_PROFILE.VALUE(cv_task_open);
    EXCEPTION
      -- プロファイル：XXCSO: タスクステータス（オープン）の値が不正な場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                      , iv_name         => cv_msg_cso_00175     -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_task_open         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- プロファイル：XXCSO: タスクステータス（オープン）が取得出来ない場合
    IF ( gn_task_open IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- アプリケーション短縮名
                    , iv_name         => cv_msg_cso_00175     -- メッセージコード
                    , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                    , iv_token_value1 => cv_task_open         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXCSO:タスクステータス（クローズ）
    BEGIN
      gn_task_close := FND_PROFILE.VALUE(cv_task_close);
    EXCEPTION
      -- プロファイル：XXCSO:タスクステータス（クローズ）の値が不正な場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                      , iv_name         => cv_msg_cso_00175     -- メッセージコード
                      , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                      , iv_token_value1 => cv_task_close         -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- プロファイル：XXCSO:タスクステータス（クローズ）が取得出来ない場合
    IF ( gn_task_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- アプリケーション短縮名
                    , iv_name         => cv_msg_cso_00175     -- メッセージコード
                    , iv_token_name1  => cv_tkn_profile       -- トークンコード1
                    , iv_token_value1 => cv_task_close         -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : 訪問実績データ取得処理 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_visit_data(
     ov_errbuf            OUT  VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT  VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT  VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
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
    -- 対象データ取得
    OPEN  g_visit_work_cur;
    FETCH g_visit_work_cur BULK COLLECT INTO g_visit_work_tab;
    CLOSE g_visit_work_cur;
--
    -- 対象件数取得
    gn_target_cnt := g_visit_work_tab.COUNT;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : データ妥当性チェック処理 (A-3)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     in_cnt              IN   PLS_INTEGER      -- 当該行データの添え字
    ,ov_errbuf           OUT  VARCHAR2         -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode          OUT  VARCHAR2         -- リターン・コード             -- # 固定 #
    ,ov_errmsg           OUT  VARCHAR2         -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);      -- リターン・コード
    lv_errmsg   VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lb_return                 BOOLEAN;                                -- リターンステータス(レコード単位)
    lb_func_return            BOOLEAN;                                -- リターンステータス(活動内容)
    ln_dff_cnt                NUMBER;                                 -- 活動あり件数
    lt_dff_cd                 fnd_lookup_values_vl.lookup_code%TYPE;  -- 訪問区分
--
    -- *** プライベート・ファンクション ***
    -- 活動内容のチェック用ファンクション
    FUNCTION activity_content_check(
       it_num       IN  fnd_lookup_values_vl.lookup_code%TYPE  -- 活動内容の番号
      ,iv_err_code  IN  VARCHAR2                               -- エラー時のメッセージコード(トークン)
      ,ot_dff_cd    OUT fnd_lookup_values_vl.lookup_code%TYPE  -- 訪問区分
    ) RETURN BOOLEAN
    IS
      cn_length CONSTANT NUMBER(1) := 2;  --訪問区分の最大桁数
    BEGIN
      BEGIN
        -- 訪問区分を取得
        SELECT flv.lookup_code  dff_cd
        INTO   ot_dff_cd
        FROM   fnd_lookup_values_vl flv
        WHERE  flv.lookup_type    = cv_kubun_lookup_type
        AND    gd_process_date    BETWEEN flv.start_date_active
                                  AND     NVL( flv.end_date_active, gd_process_date)
        AND    flv.enabled_flag  = cv_yes
        AND    flv.attribute3    = it_num
        ;
      EXCEPTION
        WHEN OTHERS THEN
         RAISE global_process_expt;
      END;
      -- 取得した訪問区分が2桁以上の場合、エラー
      IF ( LENGTHB(ot_dff_cd) > cn_length ) THEN
       RAISE global_process_expt;
      END IF;
      -- 正常
      RETURN cb_true;
    EXCEPTION
      WHEN global_process_expt THEN
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00808                                                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                                                      -- トークンコード1
                       ,iv_token_value1 => iv_err_code                                                      -- トークン値1
                       ,iv_token_name2  => cv_tkn_emp_code                                                  -- トークンコード2
                       ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                         -- トークン値2
                       ,iv_token_name3  => cv_tkn_cust_code                                                 -- トークンコード3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                          -- トークン値3
                       ,iv_token_name4  => cv_tkn_visit_date                                                -- トークンコード4
                       ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )   -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_time                                                -- トークンコード5
                       ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                              -- トークン値5
                       ,iv_token_name6  => cv_lookup_code                                                   -- トークンコード6
                       ,iv_token_value6 => it_num                                                           -- トークン値6
                     );
        -- メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- 訪問区分にNULLを設定。
        ot_dff_cd := NULL;
        -- 警告
        RETURN cb_false;
    END activity_content_check;
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- 変数初期化
    lb_return      := cb_true;
    ln_dff_cnt     := 0;
--
    -- 登録・更新用のレコードに格納
    g_visit_data_rec.employee_number  := g_visit_work_tab(in_cnt).employee_number;  -- 社員コード
    g_visit_data_rec.account_number   := g_visit_work_tab(in_cnt).account_number;   -- 顧客コード
    g_visit_data_rec.description      := g_visit_work_tab(in_cnt).detail;           -- 詳細内容
    g_visit_data_rec.planned_end_date := g_visit_work_tab(in_cnt).esm_input_date;   -- データ入力日時
    -- 訪問日が未来日付の場合
    IF ( g_visit_work_tab(in_cnt).visit_date > gd_process_date ) THEN
      g_visit_data_rec.task_status_id := gn_task_open;                              -- タスクステータス(オープン)
    ELSE
      g_visit_data_rec.task_status_id := NULL;                                      -- タスクステータス(クローズ) 
    END IF;
--
    -- ============================
    -- 1.データ型（時刻）のチェック
    -- ============================
    -- 訪問開始時刻
    IF ( xxcso_util_common_pkg.check_date( g_visit_work_tab(in_cnt).visit_time, cv_format_minute ) = cb_false ) THEN
      --メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00804                                                -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                                                     -- トークンコード1
                     ,iv_token_value1 => cv_msg_cso_00838                                                -- トークン値1
                     ,iv_token_name2  => cv_tkn_emp_code                                                 -- トークンコード2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値2
                     ,iv_token_name3  => cv_tkn_cust_code                                                -- トークンコード3
                     ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                         -- トークン値3
                     ,iv_token_name4  => cv_tkn_visit_date                                               -- トークンコード4
                     ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値4
                     ,iv_token_name5  => cv_tkn_visit_time                                               -- トークンコード5
                     ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値5
                     ,iv_token_name6  => cv_tkn_visit_time_end                                           -- トークンコード6
                     ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time_end                         -- トークン値6
                   );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- レコード単位で警告
      lb_return      := cb_false;
    ELSE
      -- 登録・更新用のレコードにセット
      g_visit_data_rec.visit_date := TO_DATE(
                                                 TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )
                                       || ' ' || g_visit_work_tab(in_cnt).visit_time, cv_format_date_minute );  --訪問日（訪問日時）
    END IF;
--
    -- 訪問終了時刻
    IF ( xxcso_util_common_pkg.check_date( g_visit_work_tab(in_cnt).visit_time_end, cv_format_minute ) = cb_false ) THEN
      --メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00804                                                -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                                                     -- トークンコード1
                     ,iv_token_value1 => cv_msg_cso_00839                                                -- トークン値1
                     ,iv_token_name2  => cv_tkn_emp_code                                                 -- トークンコード2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値2
                     ,iv_token_name3  => cv_tkn_cust_code                                                -- トークンコード3
                     ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                         -- トークン値3
                     ,iv_token_name4  => cv_tkn_visit_date                                               -- トークンコード4
                     ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値4
                     ,iv_token_name5  => cv_tkn_visit_time                                               -- トークンコード5
                     ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値5
                     ,iv_token_name6  => cv_tkn_visit_time_end                                           -- トークンコード6
                     ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time_end                         -- トークン値6
                   );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- レコード単位で警告
      lb_return      := cb_false;
    END IF;
--
    -- ============================
    -- 2.マスタの存在チェック
    -- ============================
    -- 社員コード（リソースマスタビュー）
    BEGIN
      SELECT xrv.resource_id  resource_id  -- リソースID
      INTO   g_visit_data_rec.resource_id
      FROM   xxcso_resources_v xrv
      WHERE  xrv.employee_number = g_visit_work_tab(in_cnt).employee_number
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.employee_start_date)
                                                    AND     TRUNC(NVL(xrv.employee_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.resource_start_date)
                                                    AND     TRUNC(NVL(xrv.resource_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.assign_start_date)
                                                    AND     TRUNC(NVL(xrv.assign_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.start_date)
                                                    AND     TRUNC(NVL(xrv.end_date, g_visit_work_tab(in_cnt).visit_date));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00805                                                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                                                     -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00812                                                -- トークン値1
                       ,iv_token_name2  => cv_tkn_table                                                    -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00813                                                -- トークン値2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- トークンコード3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- トークンコード4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- トークンコード6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値6
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位で警告
        lb_return      := cb_false;
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00806                                                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                                                    -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00813                                                -- トークン値1
                       ,iv_token_name2  => cv_tkn_process                                                  -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00715                                                -- トークン値2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- トークンコード3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- トークンコード4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- トークンコード6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値6
                       ,iv_token_name7  => cv_tkn_err_msg                                                  -- トークンコード7
                       ,iv_token_value7 => SQLERRM                                                         -- トークン値7
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位で警告
        lb_return      := cb_false;
    END;
--
    -- 顧客マスタ（顧客マスタ）
    BEGIN
      SELECT xcav.party_id            party_id          -- パーティID
            ,xcav.party_name          party_name        -- パーティ名称
            ,xcav.customer_status     customer_status   -- 顧客ステータス
       INTO  g_visit_data_rec.party_id
            ,g_visit_data_rec.party_name
            ,g_visit_data_rec.customer_status
       FROM  xxcso_cust_accounts_v  xcav
       WHERE xcav.account_number = g_visit_work_tab(in_cnt).account_number
       AND   (
                -- 顧客区分がNULLまたは'10'、かつ顧客ステータスが'10','20','25','30','40','50'
               (      NVL( xcav.customer_class_code ,ct_cust_class_code_cust ) = ct_cust_class_code_cust  -- 顧客
                  AND xcav.customer_status IN (  ct_cust_status_mc_candidate  -- ＭＣ候補
                                                ,ct_cust_status_mc            -- ＭＣ
                                                ,ct_cust_status_sp_decision   -- ＳＰ決裁済
                                                ,ct_cust_status_approved      -- 承認済
                                                ,ct_cust_status_customer      -- 顧客
                                                ,ct_cust_status_break         -- 休止
                                              )
               )
               -- 顧客区分が'15','16'、かつ顧客ステータスが'90','99'
               OR
               (
                     xcav.customer_class_code IN (  ct_cust_class_code_cyclic  -- 店舗営業
                                                   ,ct_cust_class_code_tonya   -- 問屋帳合先
                                                 )
                 AND xcav.customer_status IN (  ct_cust_status_abort_approved  -- 中止決裁済
                                               ,ct_cust_status_not_applicable  -- 対象外
                                             )
               )
             )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00805                                                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                                                     -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00707                                                -- トークン値1
                       ,iv_token_name2  => cv_tkn_table                                                    -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00814                                                -- トークン値2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- トークンコード3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- トークンコード4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- トークンコード6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値6
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位で警告
        lb_return      := cb_false;
      WHEN OTHERS THEN
        --メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00806                                                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                                                    -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00814                                                -- トークン値1
                       ,iv_token_name2  => cv_tkn_process                                                  -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00715                                                -- トークン値2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- トークンコード3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- トークン値3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- トークンコード4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- トークン値5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- トークンコード6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- トークン値6
                       ,iv_token_name7  => cv_tkn_err_msg                                                  -- トークンコード7
                       ,iv_token_value7 => SQLERRM                                                         -- トークン値7
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位で警告
        lb_return := cb_false;
    END;
--
    -- ============================
    -- 3.AR会計期間のチェック
    -- ============================
    -- 訪問日時点のAR会計期間チェック
    IF ( xxcso_util_common_pkg.check_ar_gl_period_status( g_visit_work_tab(in_cnt).visit_date ) = cv_false ) THEN
      --メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                      -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00807                                                 -- メッセージコード
                     ,iv_token_name1  => cv_tkn_emp_code                                                  -- トークンコード1
                     ,iv_token_value1 => g_visit_work_tab(in_cnt).employee_number                         -- トークン値1
                     ,iv_token_name2  => cv_tkn_cust_code                                                 -- トークンコード2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).account_number                          -- トークン値2
                     ,iv_token_name3  => cv_tkn_visit_date                                                -- トークンコード3
                     ,iv_token_value3 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )   -- トークン値3
                     ,iv_token_name4  => cv_tkn_visit_time                                                -- トークンコード4
                     ,iv_token_value4 => g_visit_work_tab(in_cnt).visit_time                              -- トークン値4
                   );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- レコード単位で警告
      lb_return := cb_false;
    END IF;
--
    -- ============================
    -- 4.活動内容のチェック
    -- ============================
    -- 活動内容１
    IF ( g_visit_work_tab(in_cnt).activity_content1 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content01
                          ,iv_err_code => cv_msg_cso_00816
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容２
    IF ( g_visit_work_tab(in_cnt).activity_content2 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content02
                          ,iv_err_code => cv_msg_cso_00817
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容３
    IF ( g_visit_work_tab(in_cnt).activity_content3 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content03
                          ,iv_err_code => cv_msg_cso_00818
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容４
    IF ( g_visit_work_tab(in_cnt).activity_content4 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content04
                          ,iv_err_code => cv_msg_cso_00819
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容５
    IF ( g_visit_work_tab(in_cnt).activity_content5 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content05
                          ,iv_err_code => cv_msg_cso_00820
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容６
    IF ( g_visit_work_tab(in_cnt).activity_content6 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content06
                          ,iv_err_code => cv_msg_cso_00821
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容７
    IF ( g_visit_work_tab(in_cnt).activity_content7 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content07
                          ,iv_err_code => cv_msg_cso_00822
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容８
    IF ( g_visit_work_tab(in_cnt).activity_content8 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content08
                          ,iv_err_code => cv_msg_cso_00823
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容９
    IF ( g_visit_work_tab(in_cnt).activity_content9 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content09
                          ,iv_err_code => cv_msg_cso_00824
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１０
    IF ( g_visit_work_tab(in_cnt).activity_content10 = cv_1 ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content10
                          ,iv_err_code => cv_msg_cso_00825
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１１から２０までは「活動あり」が１０個に満たない場合取得する
--
    -- 活動内容１１
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content11 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content11
                          ,iv_err_code => cv_msg_cso_00826
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１２
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content12 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content12
                          ,iv_err_code => cv_msg_cso_00827
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１３
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content13 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content13
                          ,iv_err_code => cv_msg_cso_00828
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１４
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content14 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content14
                          ,iv_err_code => cv_msg_cso_00829
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１５
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content15 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content15
                          ,iv_err_code => cv_msg_cso_00830
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１６
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content16 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content16
                          ,iv_err_code => cv_msg_cso_00831
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１７
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content17 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content17
                          ,iv_err_code => cv_msg_cso_00832
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１８
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content18 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content18
                          ,iv_err_code => cv_msg_cso_00833
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容１９
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content19 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content19
                          ,iv_err_code => cv_msg_cso_00834
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    --変数初期化
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- 活動内容２０
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content20 = cv_1 )
       ) THEN
      -- 活動内容の存在チェック
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content20
                          ,iv_err_code => cv_msg_cso_00835
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- 活動内容に格納
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- レコード単位で警告
        lb_return := cb_false;
      END IF;
    END IF;
--
    -- 警告判定
    IF ( lb_return = cb_false ) THEN
      --該当レコードはスキップさせる
      RAISE global_skip_error_expt;
    END IF;
--
    -- 初期化
    ln_dff_cnt                := 1;
    g_visit_data_rec.dff1_cd  := NULL;
    g_visit_data_rec.dff2_cd  := NULL;
    g_visit_data_rec.dff3_cd  := NULL;
    g_visit_data_rec.dff4_cd  := NULL;
    g_visit_data_rec.dff5_cd  := NULL;
    g_visit_data_rec.dff6_cd  := NULL;
    g_visit_data_rec.dff7_cd  := NULL;
    g_visit_data_rec.dff8_cd  := NULL;
    g_visit_data_rec.dff9_cd  := NULL;
    g_visit_data_rec.dff10_cd := NULL;
--
    -- 訪問区分の編集（活動ありをDFF1から10につめて設定する）
    << act_loop >>
    WHILE g_act_content_tab.EXISTS(ln_dff_cnt) LOOP
--
      -- DFF1
      IF ( ln_dff_cnt = 1 ) THEN
        g_visit_data_rec.dff1_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF2
      ELSIF ( ln_dff_cnt = 2 ) THEN
        g_visit_data_rec.dff2_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF3
      ELSIF ( ln_dff_cnt = 3 ) THEN
        g_visit_data_rec.dff3_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF4
      ELSIF ( ln_dff_cnt = 4 ) THEN
        g_visit_data_rec.dff4_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF5
      ELSIF ( ln_dff_cnt = 5 ) THEN
        g_visit_data_rec.dff5_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF6
      ELSIF ( ln_dff_cnt = 6 ) THEN
        g_visit_data_rec.dff6_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF7
      ELSIF ( ln_dff_cnt = 7 ) THEN
        g_visit_data_rec.dff7_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF8
      ELSIF ( ln_dff_cnt = 8 ) THEN
        g_visit_data_rec.dff8_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF9
      ELSIF ( ln_dff_cnt = 9 ) THEN
        g_visit_data_rec.dff9_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF10
      ELSIF ( ln_dff_cnt = 10 ) THEN
        g_visit_data_rec.dff10_cd := g_act_content_tab(ln_dff_cnt);
      END IF;
--
      ln_dff_cnt := ln_dff_cnt + 1;
--
    END LOOP act_loop;
--
    --不要な配列の削除
    g_act_content_tab.DELETE;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_same_data
   * Description      : 同一訪問実績データ取得処理(A-4)
   ***********************************************************************************/
--
  PROCEDURE get_visit_same_data(
     on_task_count            OUT  NUMBER                                 -- 同一タスク抽出件数
    ,ot_task_id               OUT  jtf_tasks_b.task_id%TYPE               -- タスクＩＤ
    ,ot_obj_ver_num           OUT  jtf_tasks_b.object_version_number%TYPE -- オブジェクトバージョン番号
    ,ov_errbuf                OUT  VARCHAR2                               -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode               OUT  VARCHAR2                               -- リターン・コード              -- # 固定 #
    ,ov_errmsg                OUT  VARCHAR2                               -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_same_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル・カーソル ***
    -- 未来日のタスク取得
    CURSOR l_task_cur
    IS
      SELECT jtb.task_id                task_id      -- タスクID
            ,jtb.object_version_number  obj_ver_num  -- オブジェクトバージョン番号
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                = g_visit_data_rec.resource_id
      AND    jtb.owner_type_code         = cv_code_employee               -- RS_EMPLOYEE
      AND    jtb.source_object_id        = g_visit_data_rec.party_id
      AND    jtb.source_object_type_code = cv_code_party                  -- PARTY
      AND    jtb.actual_end_date         = g_visit_data_rec.visit_date
      AND    jtb.deleted_flag            = cv_no                          -- 取消されていない
      ORDER BY
             jtb.last_update_date DESC  --最新
      FOR UPDATE OF jtb.task_id NOWAIT;
--
    -- 過去日のタスク取得
    CURSOR l_task_cur2
    IS
      SELECT jtb.task_id               task_id      -- タスクID
            ,jtb.object_version_number obj_ver_num  -- オブジェクトバージョン番号
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                = g_visit_data_rec.resource_id
      AND    jtb.owner_type_code         = cv_code_employee               -- RS_EMPLOYEE
      AND    jtb.source_object_id        = g_visit_data_rec.party_id
      AND    jtb.source_object_type_code = cv_code_party                  -- PARTY
      AND    jtb.actual_end_date         = g_visit_data_rec.visit_date
      AND    jtb.deleted_flag            = cv_no                          -- 取消されていない
      AND    jtb.task_status_id          = gn_task_close                  -- クローズ
      ORDER BY
             jtb.last_update_date DESC  --最新
      FOR UPDATE OF jtb.task_id NOWAIT;
--
    -- *** ローカル・レコード *** 
    l_task_rec l_task_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- *** 1. タスクテーブルからタスクIDとオブジェクトバージョン番号を取得 *** --
    BEGIN
--
      -- 同一タスク件数
      on_task_count := 0;
--
      -- 訪問日が業務日付より未来日付の場合
      IF ( TRUNC( g_visit_data_rec.visit_date ) > gd_process_date ) THEN
--
        -- データ取得（最終更新日の降順で１件のみ）
        OPEN l_task_cur;
        FETCH l_task_cur INTO l_task_rec;
        CLOSE l_task_cur;
--
        -- タスクの存在確認
        IF ( l_task_rec.task_id IS NOT NULL ) THEN
          on_task_count  := 1;
        END IF;
--
        -- タスクが存在する場合
        IF ( on_task_count > 0 ) THEN
          -- タスクIDを返却
          ot_task_id     := l_task_rec.task_id;
          -- オブジェクトバージョン番号を返却
          ot_obj_ver_num := l_task_rec.obj_ver_num;
        END IF;
--
      -- 訪問日時が業務日付を含め過去日の場合
      ELSE
--
        -- データ取得（最終更新日の降順で１件のみ）
        OPEN l_task_cur2;
        FETCH l_task_cur2 INTO l_task_rec;
        CLOSE l_task_cur2;
--
        -- タスクの存在確認
        IF ( l_task_rec.task_id IS NOT NULL ) THEN
          on_task_count  := 1;
        END IF;
--
        -- クローズのタスクが存在する場合
        IF ( on_task_count > 0 ) THEN
          -- 訪問日時が現在を含む過去日付でタスクが存在した場合はスキップ。
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                                              -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00809                                         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_emp_code                                          -- トークンコード1
                         ,iv_token_value1 => g_visit_data_rec.employee_number                         -- トークン値1
                         ,iv_token_name2  => cv_tkn_cust_code                                         -- トークンコード2
                         ,iv_token_value2 => g_visit_data_rec.account_number                          -- トークン値2
                         ,iv_token_name3  => cv_tkn_visit_date                                        -- トークンコード
                         ,iv_token_value3 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- トークン値3
                         ,iv_token_name4  => cv_tkn_visit_time                                        -- トークンコード4
                         ,iv_token_value4 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- トークン値4
                       );
          --メッセージ出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- レコード単位でスキップする
          RAISE global_skip_error_expt;
        END IF;
--
      END IF;
--
    EXCEPTION
      -- 過去日付でタスク存在
      WHEN global_skip_error_expt THEN
        -- ステータスを警告にする
        ov_retcode := cv_status_warn;
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        -- カーソル・クローズ
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                              -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00810                                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                                             -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00836                                          -- トークン値1
                       ,iv_token_name2  => cv_tkn_emp_code                                          -- トークンコード2
                       ,iv_token_value2 => g_visit_data_rec.employee_number                         -- トークン値2
                       ,iv_token_name3  => cv_tkn_cust_code                                         -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.account_number                          -- トークン値3
                       ,iv_token_name4  => cv_tkn_visit_date                                        -- トークンコード4
                       ,iv_token_value4 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_time                                        -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- トークン値5
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位でスキップする
        RAISE global_skip_error_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        -- カーソル・クローズ
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        -- メッセージ編集
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                              -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00806                                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                                             -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00836                                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_process                                           -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00715                                         -- トークン値2
                       ,iv_token_name3  => cv_tkn_emp_code                                          -- トークンコード3
                       ,iv_token_value3 => g_visit_data_rec.employee_number                         -- トークン値3
                       ,iv_token_name4  => cv_tkn_cust_code                                         -- トークンコード4
                       ,iv_token_value4 => g_visit_data_rec.account_number                          -- トークン値4
                       ,iv_token_name5  => cv_tkn_visit_date                                        -- トークンコード5
                       ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- トークン値5
                       ,iv_token_name6  => cv_tkn_visit_time                                        -- トークンコード6
                       ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- トークン値6
                       ,iv_token_name7  => cv_tkn_err_msg                                           -- トークンコード7
                       ,iv_token_value7 => SQLERRM                                                  -- トークン値7
                     );
        --メッセージ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- レコード単位でスキップする
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_visit_same_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : 訪問実績データ登録処理 (A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     ov_errbuf            OUT  VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT  VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT  VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_task_id         jtf_tasks_b.task_id%TYPE;                -- タスクID
    lt_task_status_id  jtf_task_statuses_b.task_status_id%TYPE; -- タスクステータスＩＤ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 訪問実績データ登録 
    -- =======================
    xxcso_task_common_pkg.create_task(
       in_resource_id     => g_visit_data_rec.resource_id     -- リソースID
      ,in_party_id        => g_visit_data_rec.party_id        -- パーティID
      ,iv_party_name      => g_visit_data_rec.party_name      -- パーティ名称
-- Ver1.1 ADD Start
      ,id_input_date      => g_visit_data_rec.planned_end_date -- データ入力日時
-- Ver1.1 ADD End
      ,id_visit_date      => g_visit_data_rec.visit_date      -- 訪問日時
      ,iv_description     => g_visit_data_rec.description     -- 詳細内容
      ,it_task_status_id  => g_visit_data_rec.task_status_id  -- タスクステータスＩＤ
      ,iv_attribute1      => g_visit_data_rec.dff1_cd         -- 訪問区分１
      ,iv_attribute2      => g_visit_data_rec.dff2_cd         -- 訪問区分２
      ,iv_attribute3      => g_visit_data_rec.dff3_cd         -- 訪問区分３
      ,iv_attribute4      => g_visit_data_rec.dff4_cd         -- 訪問区分４
      ,iv_attribute5      => g_visit_data_rec.dff5_cd         -- 訪問区分５
      ,iv_attribute6      => g_visit_data_rec.dff6_cd         -- 訪問区分６
      ,iv_attribute7      => g_visit_data_rec.dff7_cd         -- 訪問区分７
      ,iv_attribute8      => g_visit_data_rec.dff8_cd         -- 訪問区分８
      ,iv_attribute9      => g_visit_data_rec.dff9_cd         -- 訪問区分９
      ,iv_attribute10     => g_visit_data_rec.dff10_cd        -- 訪問区分１０
      ,iv_attribute11     => cv_0                             -- 有効訪問区分:0（訪問）
      ,iv_attribute12     => cv_6                             -- 登録区分:6（訪問実績eSM）
      ,iv_attribute13     => NULL                             -- 登録元ソース番号:NULL
      ,iv_attribute14     => g_visit_data_rec.customer_status -- 顧客ステータス
      ,on_task_id         => lt_task_id
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
    -- 正常ではない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00806                                         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                                             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cso_00836                                         -- トークン値1
                     ,iv_token_name2  => cv_tkn_process                                           -- トークンコード2
                     ,iv_token_value2 => cv_msg_cso_00702                                         -- トークン値2
                     ,iv_token_name3  => cv_tkn_emp_code                                          -- トークンコード3
                     ,iv_token_value3 => g_visit_data_rec.employee_number                         -- トークン値3
                     ,iv_token_name4  => cv_tkn_cust_code                                         -- トークンコード4
                     ,iv_token_value4 => g_visit_data_rec.account_number                          -- トークン値4
                     ,iv_token_name5  => cv_tkn_visit_date                                        -- トークンコード5
                     ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- トークン値5
                     ,iv_token_name6  => cv_tkn_visit_time                                        -- トークンコード6
                     ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- トークン値6
                     ,iv_token_name7  => cv_tkn_err_msg                                           -- トークンコード7
                     ,iv_token_value7 => lv_errmsg                                                -- トークン値7
                   );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- レコード単位でスキップする
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : update_visit_data
   * Description      : 訪問実績データ更新処理 (A-7)
   ***********************************************************************************/
--
  PROCEDURE update_visit_data(
     it_task_id           IN  jtf_tasks_b.task_id%TYPE               -- タスクＩＤ
    ,it_obj_ver_num       IN  jtf_tasks_b.object_version_number%TYPE -- オブジェクトバージョン番号
    ,ov_errbuf            OUT  VARCHAR2                              -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT  VARCHAR2                              -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT  VARCHAR2                              -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_visit_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_task_status_id jtf_task_statuses_b.task_status_id%TYPE; -- タスクステータスＩＤ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 訪問実績データ更新 
    -- =======================
    xxcso_task_common_pkg.update_task(
       in_task_id         => it_task_id                       -- タスクID
      ,in_resource_id     => g_visit_data_rec.resource_id     -- リソースID
      ,in_party_id        => g_visit_data_rec.party_id        -- パーティID
      ,iv_party_name      => g_visit_data_rec.party_name      -- パーティ名称
      ,id_visit_date      => g_visit_data_rec.visit_date      -- 訪問日時
      ,iv_description     => g_visit_data_rec.description     -- 詳細内容
      ,in_obj_ver_num     => it_obj_ver_num                   -- オブジェクト・バージョン・番号
      ,it_task_status_id  => g_visit_data_rec.task_status_id  -- タスクステータスＩＤ
      ,iv_attribute1      => g_visit_data_rec.dff1_cd         -- 訪問区分１
      ,iv_attribute2      => g_visit_data_rec.dff2_cd         -- 訪問区分２
      ,iv_attribute3      => g_visit_data_rec.dff3_cd         -- 訪問区分３
      ,iv_attribute4      => g_visit_data_rec.dff4_cd         -- 訪問区分４
      ,iv_attribute5      => g_visit_data_rec.dff5_cd         -- 訪問区分５
      ,iv_attribute6      => g_visit_data_rec.dff6_cd         -- 訪問区分６
      ,iv_attribute7      => g_visit_data_rec.dff7_cd         -- 訪問区分７
      ,iv_attribute8      => g_visit_data_rec.dff8_cd         -- 訪問区分８
      ,iv_attribute9      => g_visit_data_rec.dff9_cd         -- 訪問区分９
      ,iv_attribute10     => g_visit_data_rec.dff10_cd        -- 訪問区分１０
      ,iv_attribute11     => cv_0                             -- 有効訪問区分:0（訪問）
      ,iv_attribute12     => cv_6                             -- 登録区分:6（訪問実績eSM）
      ,iv_attribute13     => NULL                             -- 登録元ソース番号:NULL
      ,iv_attribute14     => g_visit_data_rec.customer_status
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
    -- 正常ではない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- メッセージ編集
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                              -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00806                                         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_table                                             -- トークンコード1
                     ,iv_token_value1 => cv_msg_cso_00836                                         -- トークン値1
                     ,iv_token_name2  => cv_tkn_process                                           -- トークンコード2
                     ,iv_token_value2 => cv_msg_cso_00703                                         -- トークン値2
                     ,iv_token_name3  => cv_tkn_emp_code                                          -- トークンコード3
                     ,iv_token_value3 => g_visit_data_rec.employee_number                         -- トークン値3
                     ,iv_token_name4  => cv_tkn_cust_code                                         -- トークンコード4
                     ,iv_token_value4 => g_visit_data_rec.account_number                          -- トークン値4
                     ,iv_token_name5  => cv_tkn_visit_date                                        -- トークンコード5
                     ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- トークン値5
                     ,iv_token_name6  => cv_tkn_visit_time                                        -- トークンコード6
                     ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- トークン値6
                     ,iv_token_name7  => cv_tkn_err_msg                                           -- トークンコード7
                     ,iv_token_value7 => lv_errmsg                                                -- トークン値7
                   );
      --メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- レコード単位でスキップする
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** スキップ例外ハンドラ ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_data
   * Description      : ワークテーブル削除処理 (A-8)
   ***********************************************************************************/
--
  PROCEDURE delete_work_data(
     ov_errbuf            OUT  VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT  VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT  VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_work_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
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
    BEGIN
--
      -- 訪問実績ワークテーブルデータ削除
      DELETE FROM xxcso_in_visit_data xivd;
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        -- 成功件数0件以外の場合（タスクに登録・更新されたデータが存在する）
        IF ( gn_normal_cnt <> 0 ) THEN
          -- メッセージ編集
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name       -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00811  -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table      -- トークンコード1
                         ,iv_token_value1 => cv_msg_cso_00815  -- トークン値1
                         ,iv_token_name2  => cv_tkn_table2     -- トークンコード2
                         ,iv_token_value2 => cv_msg_cso_00815  -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg    -- トークンコード3
                         ,iv_token_value3 => SQLERRM           -- トークン値3
                       );
        -- 成功件数0件の場合（タスクに登録・更新されたデータが存在しない）
        ELSE
          -- メッセージ編集
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name       -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00837  -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table      -- トークンコード1
                         ,iv_token_value1 => cv_msg_cso_00815  -- トークン値1
                         ,iv_token_name2  => cv_tkn_table2     -- トークンコード2
                         ,iv_token_value2 => cv_msg_cso_00815  -- トークン値2
                         ,iv_token_name3  => cv_tkn_err_msg    -- トークンコード3
                         ,iv_token_value3 => SQLERRM           -- トークン値3
                       );
        END IF;
        lv_errbuf := lv_errmsg;
        -- エラー終了とする
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
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
  END delete_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT  VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT  VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT  VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_task_count           NUMBER;                                  -- 同一タスク件数
    lt_task_id              jtf_tasks_b.task_id%TYPE;                -- タスクＩＤ
    lt_obj_ver_num          jtf_tasks_b.object_version_number%TYPE;  -- オブジェクトバージョン番号
    -- *** ローカルレコード ***
    g_visit_date_format_rec g_visit_data_rtype;                      -- 初期化用
--
    -- *** ローカル例外 ***
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ================================
    -- 初期処理(A-1)
    -- ================================
    init(
       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              -- # 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- 訪問実績データ取得処理(A-2)
    -- ========================================
    get_visit_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-2で抽出したデータが1件以上の場合
    IF ( g_visit_work_tab.COUNT > 0 ) THEN
--
      << visit_loop >>
      FOR i IN 1..g_visit_work_tab.COUNT LOOP
--
        -- 登録・更新用レコード初期化
        g_visit_data_rec := g_visit_date_format_rec;
        -- ロールバックフラグ初期化
        gb_rollback_flag := cb_false;
--
        BEGIN
--
          -- =============================
          -- データ妥当性チェック処理(A-3)
          -- =============================
          data_proper_check(
             in_cnt           => i                -- 当該行データの添え字
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            -- 処理エラー
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            -- レコード単位でスキップ
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- 同一訪問実績データ取得処理(A-4)
          -- =============================
          get_visit_same_data(
             on_task_count    => ln_task_count    -- 同一タスク抽出件数
            ,ot_task_id       => lt_task_id       -- タスクＩＤ
            ,ot_obj_ver_num   => lt_obj_ver_num   -- オブジェクトバージョン番号
            ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            -- エラー終了
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            -- レコード単位でスキップ
            RAISE global_skip_error_expt;
          END IF;
--
          -- ============================
          -- SAVEPOINT発行処理(A-5)
          -- ============================
          SAVEPOINT visit;
--
          -- 更新対象が存在しない場合
          IF ( ln_task_count = 0 ) THEN
--
            -- =============================
            -- 訪問実績データ登録処理(A-6)
            -- =============================
            insert_visit_data(
               ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
              ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              -- エラー終了
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              -- ロールバックを要としスキップする
              gb_rollback_flag := cb_true;
              RAISE global_skip_error_expt;
            END IF;
--
          -- 更新対象が存在する場合
          ELSE
--
            -- =============================
            -- 訪問実績データ更新処理(A-7)
            -- =============================
            update_visit_data(
               it_task_id       => lt_task_id       -- タスクＩＤ
              ,it_obj_ver_num   => lt_obj_ver_num   -- オブジェクトバージョン番号
              ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
              ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              -- エラー終了
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              -- ロールバックを要としスキップする
              gb_rollback_flag := cb_true;
              RAISE global_skip_error_expt;
            END IF;
          END IF;
--
          -- 成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** スキップ例外ハンドラ ***
          WHEN global_skip_error_expt THEN
            gn_warn_cnt := gn_warn_cnt + 1;       -- 警告件数カウント
            lv_retcode  := cv_status_warn;
            -- ロールバック要の場合
            IF ( gb_rollback_flag = cb_true )THEN
              ROLLBACK TO SAVEPOINT visit;        -- ROLLBACK
            END IF;
        END;
--
      END LOOP get_visit_data_loop;
--
      ov_retcode := lv_retcode;  -- リターン・コード設定
--
    END IF;
--
    -- 登録・更新の確定の為、COMMIT
    COMMIT;
--
    -- =============================
    -- ワークテーブル削除処理(A-8)
    -- =============================
    delete_work_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー終了
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT  VARCHAR2          -- エラー・メッセージ  -- # 固定 #
    ,retcode       OUT  VARCHAR2          -- リターン・コード    -- # 固定 #
  )    
--
-- ###########################  固定部 START   ###########################
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
    cv_error_msg2      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- エラー終了メッセージ

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
-- ###########################  固定部 START   #####################################################
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
-- ###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg    -- ユーザー・エラーメッセージ
       );
       FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf    -- エラーメッセージ
       );
       --エラー件数の設定
       gn_error_cnt  := 1;
    END IF;
--
    -- =======================
    -- 終了処理(A-9)
    -- =======================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 対象件数出力
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
    -- 成功件数出力
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
    -- 警告件数出力
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
    -- エラー件数出力
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
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      -- 1件でも成功した場合
      IF ( gn_normal_cnt <> 0 ) THEN
        -- エラー終了一部処理メッセージ
        lv_message_code := cv_error_msg;
      ELSE
        -- エラー終了メッセージ
        lv_message_code := cv_error_msg2;
      END IF;
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
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCSO006A03C;
/
