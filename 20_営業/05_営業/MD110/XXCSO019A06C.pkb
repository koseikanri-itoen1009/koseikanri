CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A06C(body)
 * Description      :  指定した営業員の指定した日を含む1週間の訪問計画(訪問先顧客名)
 *                    を日別にPDFへ出力します。
 *                     顧客は同一のルートNoごとにまとめ、週間訪問回数の多いルートNoから
 *                    順に表示します。(ルートNoを表示します。)
 *                     日付欄の右端に1日の件数を表示します。
 * MD.050           : MD050_CSO_019_A06_訪問総合管理表
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_param              パラメータチェック(A-2)
 *  header_process         帳票ヘッダ処理(A-3)
 *  ins_upd_lines          配列の追加、更新(A-5)
 *  insert_row             ワークテーブルデータ登録(A-6)
 *  act_svf                SVF起動(A-7)
 *  delete_row             ワークテーブルデータ削除(A-8)
 *  submain                メイン処理プロシージャ
 *                           データ取得(A-4)
 *                           SVF起動APIエラーチェック(A-9)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-10)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-16    1.0   Mio.Maruyama     新規作成
 *  2009-03-02    1.0   Mio.Maruyama     成功件数カウントアップエラー修正
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF起動API埋め込み
 *  2009-03-11    1.1   Kazuyo.Hosoi     【障害対応047】顧客区分、ステータス抽出条件変更
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-05-11    1.3   Kazuo.Satomura   T1_0926対応
 *  2009-05-20    1.4   Makoto.Ohtsuki   ＳＴ障害対応(T1_0696)
 *  2018-03-08    1.5   Kazuhiro.Nara    E_本稼動_14884対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A06C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ログイン組織ＩＤ
  --
  cv_report_id           CONSTANT VARCHAR2(30)  := 'XXCSO019A06C';  -- 帳票ID
  -- 日付書式
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- 日付フォーマット（年月日）
  cv_format_get_dayname  CONSTANT VARCHAR2(3)   := 'DAY';           -- 曜日取得用フォーマット
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00129';  -- パラメータ出力(基準年月日)
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00131';  -- パラメータ出力(従業員コード)
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00132';  -- 年月日の型違いエラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00133';  -- 必須項目未選択エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00134';  -- 権限外のオペレーションエラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- APIエラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- ＤＢ登録・更新エラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- 明細0件メッセージ
  -- トークンコード
  cv_tkn_entry           CONSTANT VARCHAR2(20)  := 'ENTRY';
  cv_thn_table           CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20)  := 'API_NAME';
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_act             CONSTANT VARCHAR2(20)  := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERRMSG';
--
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)   := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)   := ')';
--
  cn_user_id             CONSTANT NUMBER        := fnd_global.user_id;   -- ユーザーID
  cn_resp_id             CONSTANT NUMBER        := fnd_global.resp_id;   -- 職責ID
  cd_work_date            CONSTANT DATE         := xxcso_util_common_pkg.get_online_sysdate;  -- 現在日付
  cd_now_date            CONSTANT DATE          := SYSDATE;  -- 現在日付
  cv_rep_tp              CONSTANT VARCHAR2(1)   := '1';                  -- 帳票タイプ
  cv_true                CONSTANT VARCHAR2(4)   := 'TRUE';               -- 戻り値判断用
  cv_false               CONSTANT VARCHAR2(5)   := 'FALSE';              -- 戻り値判断用
--
  -- ワークテーブルへの曜日格納用
  cv_week_1              CONSTANT VARCHAR2(2)   := '月';
  cv_week_2              CONSTANT VARCHAR2(2)   := '火';
  cv_week_3              CONSTANT VARCHAR2(2)   := '水';
  cv_week_4              CONSTANT VARCHAR2(2)   := '木';
  cv_week_5              CONSTANT VARCHAR2(2)   := '金';
  cv_week_6              CONSTANT VARCHAR2(2)   := '土';
  cv_week_7              CONSTANT VARCHAR2(2)   := '日';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_total_count         NUMBER(10) DEFAULT 0;         -- 総軒数
  gn_total_count_1       NUMBER(10) DEFAULT 0;         -- 月曜日-総軒数
  gn_total_count_2       NUMBER(10) DEFAULT 0;         -- 火曜日-総軒数
  gn_total_count_3       NUMBER(10) DEFAULT 0;         -- 水曜日-総軒数
  gn_total_count_4       NUMBER(10) DEFAULT 0;         -- 木曜日-総軒数
  gn_total_count_5       NUMBER(10) DEFAULT 0;         -- 金曜日-総軒数
  gn_total_count_6       NUMBER(10) DEFAULT 0;         -- 土曜日-総軒数
  gn_total_count_7       NUMBER(10) DEFAULT 0;         -- 日曜日-総軒数
--
  gd_day_1               DATE;                         -- 月曜日-日
  gd_day_2               DATE;                         -- 火曜日-日
  gd_day_3               DATE;                         -- 水曜日-日
  gd_day_4               DATE;                         -- 木曜日-日
  gd_day_5               DATE;                         -- 金曜日-日
  gd_day_6               DATE;                         -- 土曜日-日
  gd_day_7               DATE;                         -- 日曜日-日
--
  /* 2009.05.11 K.Satomura T1_0926対応 START */
  --gn_cnt                 NUMBER DEFAULT 0;             -- 配列用カウンタ
  gn_cnt                 NUMBER DEFAULT 1;             -- 配列用カウンタ
  /* 2009.05.11 K.Satomura T1_0926対応 END */
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 営業員別日別訪問計画 レコード型定義
  TYPE g_prsn_dt_vst_pln_rtype IS RECORD(
     account_number         xxcso_cust_accounts_v.account_number%TYPE   -- 顧客コード
    ,party_name             xxcso_cust_accounts_v.party_name%TYPE       -- 顧客名称
    ,route_no               xxcso_cust_routes_v2.route_number%TYPE      -- ルートNo
  );
--  -- 訪問総合管理帳票ワークテーブル レコード型定義
  TYPE g_rep_vst_rt_mng_rtype IS RECORD(
     line_num               xxcso_rep_visit_route_mng.line_num%TYPE               -- 行番号
    ,report_id              xxcso_rep_visit_route_mng.report_id%TYPE              -- 帳票ＩＤ
    ,report_name            xxcso_rep_visit_route_mng.report_name%TYPE            -- 帳票タイトル
    ,output_date            xxcso_rep_visit_route_mng.output_date%TYPE            -- 出力日時
    ,base_date              xxcso_rep_visit_route_mng.base_date%TYPE              -- 基準年月日
    ,base_date_start        xxcso_rep_visit_route_mng.base_date_start%TYPE        -- 基準日START
    ,base_date_end          xxcso_rep_visit_route_mng.base_date_end%TYPE          -- 基準日END
    ,base_code              xxcso_rep_visit_route_mng.base_code%TYPE              -- 拠点コード
    ,hub_name               xxcso_rep_visit_route_mng.hub_name%TYPE               -- 拠点名称
    ,employee_number        xxcso_rep_visit_route_mng.employee_number%TYPE        -- 営業員コード
    ,employee_name          xxcso_rep_visit_route_mng.employee_name%TYPE          -- 営業員名
    ,total_count            xxcso_rep_visit_route_mng.total_count%TYPE            -- 総軒数
    ,day_1                  xxcso_rep_visit_route_mng.day_1%TYPE                  -- 月曜日-日
    ,week_1                 xxcso_rep_visit_route_mng.week_1%TYPE                 -- 月曜日-曜日
    ,total_count_1          xxcso_rep_visit_route_mng.total_count_1%TYPE          -- 月曜日-総軒数
    ,account_number_1       xxcso_rep_visit_route_mng.account_number_1%TYPE       -- 月曜日-顧客コード
    ,route_no_1             xxcso_rep_visit_route_mng.route_no_1%TYPE             -- 月曜日-ルートNo.
    ,customer_name_1        xxcso_rep_visit_route_mng.customer_name_1%TYPE        -- 月曜日-顧客名
    ,day_2                  xxcso_rep_visit_route_mng.day_2%TYPE                  -- 火曜日-日
    ,week_2                 xxcso_rep_visit_route_mng.week_2%TYPE                 -- 火曜日-曜日
    ,total_count_2          xxcso_rep_visit_route_mng.total_count_2%TYPE          -- 火曜日-総軒数
    ,account_number_2       xxcso_rep_visit_route_mng.account_number_2%TYPE       -- 火曜日-顧客コード
    ,route_no_2             xxcso_rep_visit_route_mng.route_no_2%TYPE             -- 火曜日-ルートNo.
    ,customer_name_2        xxcso_rep_visit_route_mng.customer_name_2%TYPE        -- 火曜日-顧客名
    ,day_3                  xxcso_rep_visit_route_mng.day_3%TYPE                  -- 水曜日-日
    ,week_3                 xxcso_rep_visit_route_mng.week_3%TYPE                 -- 水曜日-曜日
    ,total_count_3          xxcso_rep_visit_route_mng.total_count_3%TYPE          -- 水曜日-総軒数
    ,account_number_3       xxcso_rep_visit_route_mng.account_number_3%TYPE       -- 水曜日-顧客コード
    ,route_no_3             xxcso_rep_visit_route_mng.route_no_3%TYPE             -- 水曜日-ルートNo.
    ,customer_name_3        xxcso_rep_visit_route_mng.customer_name_3%TYPE        -- 水曜日-顧客名
    ,day_4                  xxcso_rep_visit_route_mng.day_4%TYPE                  -- 木曜日-日
    ,week_4                 xxcso_rep_visit_route_mng.week_4%TYPE                 -- 木曜日-曜日
    ,total_count_4          xxcso_rep_visit_route_mng.total_count_4%TYPE          -- 木曜日-総軒数
    ,account_number_4       xxcso_rep_visit_route_mng.account_number_4%TYPE       -- 木曜日-顧客コード
    ,route_no_4             xxcso_rep_visit_route_mng.route_no_4%TYPE             -- 木曜日-ルートNo.
    ,customer_name_4        xxcso_rep_visit_route_mng.customer_name_4%TYPE        -- 木曜日-顧客名
    ,day_5                  xxcso_rep_visit_route_mng.day_5%TYPE                  -- 金曜日-日
    ,week_5                 xxcso_rep_visit_route_mng.week_5%TYPE                 -- 金曜日-曜日
    ,total_count_5          xxcso_rep_visit_route_mng.total_count_5%TYPE          -- 金曜日-総軒数
    ,account_number_5       xxcso_rep_visit_route_mng.account_number_5%TYPE       -- 金曜日-顧客コード
    ,route_no_5             xxcso_rep_visit_route_mng.route_no_5%TYPE             -- 金曜日-ルートNo.
    ,customer_name_5        xxcso_rep_visit_route_mng.customer_name_5%TYPE        -- 金曜日-顧客名
    ,day_6                  xxcso_rep_visit_route_mng.day_6%TYPE                  -- 土曜日-日
    ,week_6                 xxcso_rep_visit_route_mng.week_6%TYPE                 -- 土曜日-曜日
    ,total_count_6          xxcso_rep_visit_route_mng.total_count_6%TYPE          -- 土曜日-総軒数
    ,account_number_6       xxcso_rep_visit_route_mng.account_number_6%TYPE       -- 土曜日-顧客コード
    ,route_no_6             xxcso_rep_visit_route_mng.route_no_6%TYPE             -- 土曜日-ルートNo.
    ,customer_name_6        xxcso_rep_visit_route_mng.customer_name_6%TYPE        -- 土曜日-顧客名
    ,day_7                  xxcso_rep_visit_route_mng.day_7%TYPE                  -- 日曜日-日
    ,week_7                 xxcso_rep_visit_route_mng.week_7%TYPE                 -- 日曜日-曜日
    ,total_count_7          xxcso_rep_visit_route_mng.total_count_7%TYPE          -- 日曜日-総軒数
    ,account_number_7       xxcso_rep_visit_route_mng.account_number_7%TYPE       -- 日曜日-顧客コード
    ,route_no_7             xxcso_rep_visit_route_mng.route_no_7%TYPE             -- 日曜日-ルートNo.
    ,customer_name_7        xxcso_rep_visit_route_mng.customer_name_7%TYPE        -- 日曜日-顧客名
    ,created_by             xxcso_rep_visit_route_mng.created_by%TYPE             -- 作成者
    ,creation_date          xxcso_rep_visit_route_mng.creation_date%TYPE          -- 作成日
    ,last_updated_by        xxcso_rep_visit_route_mng.last_updated_by%TYPE        -- 最終更新者
    ,last_update_date       xxcso_rep_visit_route_mng.last_update_date%TYPE       -- 最終更新日
    ,last_update_login      xxcso_rep_visit_route_mng.last_update_login%TYPE      -- 最終更新ログイン
    ,request_id             xxcso_rep_visit_route_mng.request_id%TYPE             -- 要求ID
    ,program_application_id xxcso_rep_visit_route_mng.program_application_id%TYPE -- コンカレント・プログラム・アプリケーションID
    ,program_id             xxcso_rep_visit_route_mng.program_id%TYPE             -- コンカレント・プログラムID
    ,program_update_date    xxcso_rep_visit_route_mng.program_update_date%TYPE    -- プログラム更新日
  );
  -- 営業員別訪問実績表帳票ワークテーブル テーブル型定義
  TYPE g_rep_vst_rt_mng_ttype IS TABLE OF g_rep_vst_rt_mng_rtype INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_rep_vst_rt_mng_tab      g_rep_vst_rt_mng_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_standard_date    IN  VARCHAR2         -- 基準年月日
    ,iv_employee_number  IN  VARCHAR2         -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg_stnd_dt  VARCHAR2(5000);
    lv_msg_bs_num   VARCHAR2(5000);
    lv_msg_emp_num  VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 入力パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- メッセージ取得(基準年月日)
    lv_msg_stnd_dt  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_01    --メッセージコード
                         ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                         ,iv_token_value1 => iv_standard_date    --トークン値1
                       );
    -- メッセージ取得(従業員コード)
    lv_msg_emp_num  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_02    --メッセージコード
                         ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                         ,iv_token_value1 => iv_employee_number  --トークン値1
                       );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_stnd_dt
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_emp_num
    );
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
   * Procedure Name   : chk_param
   * Description      : パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
     iv_standard_date    IN  VARCHAR2         -- 基準年月日
    ,iv_employee_number  IN  VARCHAR2         -- 従業員コード
    ,od_standard_date    OUT DATE             -- 基準年月日(DATE型)
    ,ov_full_name        OUT NOCOPY VARCHAR2  -- 漢字氏名
    ,ov_work_base_code     OUT NOCOPY VARCHAR2                           -- 勤務地拠点コード
    ,ov_hub_name         OUT NOCOPY VARCHAR2  -- 勤務地拠点名
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'chk_param';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_stnd_dt           CONSTANT VARCHAR2(20) := '基準年月日';
    cv_bs_nm             CONSTANT VARCHAR2(20) := '拠点コード';
    cv_emp_nm            CONSTANT VARCHAR2(20) := '従業員コード';
    -- *** ローカル変数 ***
    ld_standard_date     DATE;                                     -- 基準年月日(DATE型)
    lt_employee_number   xxcso_resources_v2.employee_number%TYPE;  -- 従業員コード
    lt_last_name         xxcso_resources_v2.last_name%TYPE;        -- 漢字姓
    lt_first_name        xxcso_resources_v2.first_name%TYPE;       -- 漢字名
    lv_work_base_code    VARCHAR2(150);                            -- 勤務地拠点コード
    lv_work_base_name    VARCHAR2(4000);                           -- 勤務地拠点名
    lv_retcd             VARCHAR2(5);                              -- 共通関数戻り値格納
    -- *** ローカル例外 ***
    chk_param_expt       EXCEPTION;  -- 見積ヘッダーＩＤ未入力エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- パラメータ必須チェック
    -- ===========================
    -- パラメータ基準年月日が未入力
    IF (iv_standard_date IS NULL) THEN
      -- エラーメッセージ取得(基準年月日)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_04  --メッセージコード
                     ,iv_token_name1  => cv_tkn_entry      --トークンコード1
                     ,iv_token_value1 => cv_stnd_dt        --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- パラメータ従業員コードが未入力
    IF (iv_employee_number IS NULL) THEN
      -- エラーメッセージ取得(従業員コード)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_04  --メッセージコード
                     ,iv_token_name1  => cv_tkn_entry      --トークンコード1
                     ,iv_token_value1 => cv_emp_nm         --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ================================
    -- パラメータ(基準年月日)チェック
    -- ================================
--
    BEGIN
      SELECT TO_DATE(iv_standard_date,cv_format_date_ymd1) standard_date -- INパラメータ基準年月日
      INTO   ld_standard_date
      FROM   dual;
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => cv_stnd_dt          --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
    END;
    -- ===========================
    -- 従業員コードチェック
    -- ===========================
    -- ログインユーザーの職責チェック
    lv_retcd   := xxcso_util_common_pkg.chk_responsibility(
                    in_user_id     => cn_user_id       -- ログインユーザＩＤ
                   ,in_resp_id     => cn_resp_id       -- 職位ＩＤ
                   ,iv_report_type => cv_rep_tp        -- 帳票タイプ（1:営業員別、2:営業員グループ別、その他は指定不可）
                  );
--
    BEGIN
      SELECT  xrv2.employee_number  employee_number -- 従業員コード
             ,xrv2.last_name        last_name       -- 漢字姓
             ,xrv2.first_name       first_name      -- 漢字名
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_code_new  -- 勤務地拠点コード（新）
                    ELSE
                      xrv2.work_base_code_old  -- 勤務地拠点コード（旧）
                    END
               ) work_base_code                -- 勤務地拠点コード
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_name_new  -- 勤務地拠点名（新）
                    ELSE
                      xrv2.work_base_name_old  -- 勤務地拠点名（旧）
                    END
               ) work_base_name                -- 勤務地拠点名
      INTO    lt_employee_number
             ,lt_last_name
             ,lt_first_name
             ,lv_work_base_code
             ,lv_work_base_name
      FROM   xxcso_resources_v2 xrv2           -- リソースマスタ(最新)VIEW
      WHERE (CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                    xrv2.work_base_code_new  -- 勤務地拠点コード（新）
                  ELSE
                    xrv2.work_base_code_old  -- 勤務地拠点コード（旧）
                  END
             ) = ( SELECT (CASE WHEN xrv.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                                  xrv.work_base_code_new  -- 勤務地拠点コード（新）
                                ELSE
                                  xrv.work_base_code_old  -- 勤務地拠点コード（旧）
                                END
                           ) work_base_code2
                   FROM    xxcso_resources_v2 xrv
                   WHERE   xrv.user_id = cn_user_id
                  )
        AND xrv2.employee_number = iv_employee_number
        AND ((lv_retcd  =  cv_true
               AND xrv2.user_id = cn_user_id
              )
            OR (lv_retcd  =  cv_false
               AND 1 = 1
              ));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_05    --メッセージコード
                       ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                       ,iv_token_value1 => iv_employee_number  --トークン値1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
    -- OUTパラメータの設定
    od_standard_date   := ld_standard_date;   -- 基準日(DATE型)
    ov_full_name       := SUBSTRB(lt_last_name || lt_first_name, 1, 40);  -- 漢字氏名
    ov_work_base_code  := lv_work_base_code;  -- 勤務地拠点コード
    ov_hub_name        := lv_work_base_name;  -- 勤務地拠点名
--
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** パラメータチェックエラー ***
    WHEN chk_param_expt THEN
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : header_process
   * Description      : 帳票ヘッダ処理(A-3)
   ***********************************************************************************/
  PROCEDURE header_process(
     id_standard_date       IN  DATE             -- 基準日(DATE型)
    ,od_start_date          OUT DATE             -- 基準日初日
    ,od_end_date            OUT DATE             -- 基準日末日
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'header_process';     -- プログラム名
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
    cv_strt_dt_nm  CONSTANT VARCHAR2(20) := '月曜日';  -- 月曜日(基準日初日の曜日)
    cv_end_dt_nm   CONSTANT VARCHAR2(20) := '日曜日';  -- 日曜日(基準日末日の曜日)
    -- *** ローカル変数 ***
    lv_dayname     VARCHAR2(20);  -- 基準日曜日格納用
    ld_start_date  DATE;          -- 基準日初日
    ld_end_date    DATE;          -- 基準日末日
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- 集計対象期間 導出
    -- ======================
    lv_dayname := TO_CHAR(id_standard_date,cv_format_get_dayname);  -- 基準日の曜日を取得
--
    IF (lv_dayname = cv_strt_dt_nm) THEN            -- 基準日が月曜日の場合
      ld_start_date := id_standard_date;            -- 基準日初日
      
      SELECT NEXT_DAY(id_standard_date,cv_end_dt_nm) end_date    -- 基準日末日
      INTO   ld_end_date
      FROM dual
      ;
--
    ELSIF (lv_dayname = cv_end_dt_nm) THEN  -- 基準日が日曜日の場合
      SELECT NEXT_DAY(id_standard_date,cv_strt_dt_nm)-7 start_date -- 基準日初日
      INTO   ld_start_date
      FROM dual
      ;
      ld_end_date := id_standard_date;      -- 基準日末日
--
    ELSIF ((lv_dayname <> cv_strt_dt_nm)    -- どちらでもない場合
      AND (lv_dayname <> cv_end_dt_nm))
    THEN
      SELECT NEXT_DAY(id_standard_date,cv_strt_dt_nm)-7 start_date -- 基準日初日
      INTO   ld_start_date
      FROM dual
      ;
      
      SELECT NEXT_DAY(id_standard_date,cv_end_dt_nm) end_date    -- 基準日末日
      INTO   ld_end_date
      FROM dual
      ;
    END IF;
--
    -- OUTパラメータの設定
    od_start_date  := ld_start_date;  -- 基準日初日
    od_end_date    := ld_end_date;    -- 基準日末日
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END header_process;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lines
   * Description      : 配列の追加、更新(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upd_lines(
     id_base_date           IN  DATE                     -- ループ用基準日
    ,i_prsn_dt_vst_pln_rec  IN  g_prsn_dt_vst_pln_rtype  -- 営業員別日別訪問計画データ
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ins_upd_lines';     -- プログラム名
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
    -- 訪問曜日
    cv_visit_dayname_mon  CONSTANT VARCHAR(20) := '月曜日';
    cv_visit_dayname_tue  CONSTANT VARCHAR(20) := '火曜日';
    cv_visit_dayname_wed  CONSTANT VARCHAR(20) := '水曜日';
    cv_visit_dayname_thu  CONSTANT VARCHAR(20) := '木曜日';
    cv_visit_dayname_fri  CONSTANT VARCHAR(20) := '金曜日';
    cv_visit_dayname_sat  CONSTANT VARCHAR(20) := '土曜日';
    cv_visit_dayname_sun  CONSTANT VARCHAR(20) := '日曜日';
    -- *** ローカル変数 ***
    lv_visit_dayname  VARCHAR(20);
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
    -- ======================
    -- 訪問曜日の導出
    -- ======================
    SELECT TO_CHAR(id_base_date, cv_format_get_dayname)  dayname -- 訪問曜日
    INTO   lv_visit_dayname
    FROM   dual
    ;
--
    -- ======================
    -- 軒数計の更新
    -- ======================
    -- 総件数のカウントアップ
    /* 2009.05.11 K.Satomura T1_0926対応 START */
    --gn_total_count := gn_total_count + 1;
    IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
      gn_total_count := gn_total_count + 1;
      --
    END IF;
    /* 2009.05.11 K.Satomura T1_0926対応 END */
--
    -- 軒数計のカウントアップ
    -- 月曜日の場合
    IF (lv_visit_dayname = cv_visit_dayname_mon) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_1 := gn_total_count_1 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_1;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_1 := gn_total_count_1 + 1;
        gn_cnt           := gn_total_count_1;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_1                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_1 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_1       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_1  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 火曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_tue) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_2 := gn_total_count_2 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_2;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_2 := gn_total_count_2 + 1;
        gn_cnt           := gn_total_count_2;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_2                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_2 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_2       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_2  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 水曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_wed) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_3 := gn_total_count_3 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_3;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_3 := gn_total_count_3 + 1;
        gn_cnt           := gn_total_count_3;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_3                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_3 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_3       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_3  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 木曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_thu) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_4 := gn_total_count_4 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_4;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_4 := gn_total_count_4 + 1;
        gn_cnt           := gn_total_count_4;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_4                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_4 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_4       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_4  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 金曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_fri) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_5 := gn_total_count_5 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_5;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_5 := gn_total_count_5 + 1;
        gn_cnt           := gn_total_count_5;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_5                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_5 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_5       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_5  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 土曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_sat) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_6 := gn_total_count_6 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_6;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_6 := gn_total_count_6 + 1;
        gn_cnt           := gn_total_count_6;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_6                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_6 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_6       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_6  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
--
    -- 日曜日の場合
    ELSIF (lv_visit_dayname = cv_visit_dayname_sun) THEN
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --gn_total_count_7 := gn_total_count_7 + 1;
      ---- 配列用カウンタへ格納
      --gn_cnt := gn_total_count_7;
      IF (i_prsn_dt_vst_pln_rec.account_number IS NOT NULL) THEN
        gn_total_count_7 := gn_total_count_7 + 1;
        gn_cnt           := gn_total_count_7;
        --
      ELSE
        gn_cnt := 1;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- 配列へのデータ格納
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- 行番号
      gd_day_7                                      := id_base_date;                          -- 日
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_7 := i_prsn_dt_vst_pln_rec.account_number;  -- 顧客コード
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_7       := i_prsn_dt_vst_pln_rec.route_no;        -- ルートNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_7  := i_prsn_dt_vst_pln_rec.party_name;      -- 顧客名称
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upd_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ワークテーブルデータ登録(A-6)
   ***********************************************************************************/
  PROCEDURE insert_row(
     id_standard_date       IN  DATE                               -- 基準年月日(DATE型)
    ,id_start_date          IN  DATE                               -- 基準日初日
    ,id_end_date            IN  DATE                               -- 基準日末日
    ,iv_work_base_code      IN  VARCHAR2                           -- 拠点コード
    ,iv_hub_name            IN  VARCHAR2                           -- 拠点名称
    ,iv_employee_number     IN  VARCHAR2                           -- 従業員コード
    ,iv_full_name           IN  VARCHAR2                           -- 漢字氏名
    ,ov_errbuf              OUT NOCOPY VARCHAR2                    -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2                    -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                    -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- プログラム名
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
    cv_report_name      CONSTANT VARCHAR2(40)  := '≪訪問総合管理表≫'; -- 帳票タイトル
    cv_tkn_tbl_nm       CONSTANT VARCHAR2(100) := '訪問総合管理表帳票ワークテーブルの登録';
    -- *** ローカル変数 ***
    -- *** ローカル例外 ***
    insert_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
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
      <<insert_row_loop>>
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      --FOR i IN 1..g_rep_vst_rt_mng_tab.COUNT LOOP
      FOR i IN g_rep_vst_rt_mng_tab.FIRST..g_rep_vst_rt_mng_tab.LAST LOOP
      /* 2009.05.11 K.Satomura T1_0926対応 END */
        -- ======================
        -- ワークテーブルデータ登録
        -- ======================
        INSERT INTO xxcso_rep_visit_route_mng xrvrm  -- 訪問総合管理表帳票ワークテーブル
          ( line_num                -- 行番号
           ,report_id               -- 帳票ＩＤ
           ,report_name             -- 帳票タイトル
           ,output_date             -- 出力日時
           ,base_date               -- 基準年月日
           ,base_date_start         -- 基準日START
           ,base_date_end           -- 基準日END
           ,base_code               -- 拠点コード
           ,hub_name                -- 拠点名称
           ,employee_number         -- 営業員コード
           ,employee_name           -- 営業員名
           ,total_count             -- 総軒数
           ,day_1                   -- 月曜日-日
           ,week_1                  -- 月曜日-曜日
           ,total_count_1           -- 月曜日-総軒数
           ,account_number_1        -- 月曜日-顧客コード
           ,route_no_1              -- 月曜日-ルートNo.
           ,customer_name_1         -- 月曜日-顧客名
           ,day_2                   -- 火曜日-日
           ,week_2                  -- 火曜日-曜日
           ,total_count_2           -- 火曜日-総軒数
           ,account_number_2        -- 火曜日-顧客コード
           ,route_no_2              -- 火曜日-ルートNo.
           ,customer_name_2         -- 火曜日-顧客名
           ,day_3                   -- 水曜日-日
           ,week_3                  -- 水曜日-曜日
           ,total_count_3           -- 水曜日-総軒数
           ,account_number_3        -- 水曜日-顧客コード
           ,route_no_3              -- 水曜日-ルートNo.
           ,customer_name_3         -- 水曜日-顧客名
           ,day_4                   -- 木曜日-日
           ,week_4                  -- 木曜日-曜日
           ,total_count_4           -- 木曜日-総軒数
           ,account_number_4        -- 木曜日-顧客コード
           ,route_no_4              -- 木曜日-ルートNo.
           ,customer_name_4         -- 木曜日-顧客名
           ,day_5                   -- 金曜日-日
           ,week_5                  -- 金曜日-曜日
           ,total_count_5           -- 金曜日-総軒数
           ,account_number_5        -- 金曜日-顧客コード
           ,route_no_5              -- 金曜日-ルートNo.
           ,customer_name_5         -- 金曜日-顧客名
           ,day_6                   -- 土曜日-日
           ,week_6                  -- 土曜日-曜日
           ,total_count_6           -- 土曜日-総軒数
           ,account_number_6        -- 土曜日-顧客コード
           ,route_no_6              -- 土曜日-ルートNo.
           ,customer_name_6         -- 土曜日-顧客名
           ,day_7                   -- 日曜日-日
           ,week_7                  -- 日曜日-曜日
           ,total_count_7           -- 日曜日-総軒数
           ,account_number_7        -- 日曜日-顧客コード
           ,route_no_7              -- 日曜日-ルートNo.
           ,customer_name_7         -- 日曜日-顧客名
           ,created_by              -- 作成者
           ,creation_date           -- 作成日
           ,last_updated_by         -- 最終更新者
           ,last_update_date        -- 最終更新日
           ,last_update_login       -- 最終更新ログイン
           ,request_id              -- 要求ID
           ,program_application_id  -- コンカレント・プログラム・アプリケーションID
           ,program_id              -- コンカレント・プログラムID
           ,program_update_date     -- プログラム更新日
          )
        VALUES
         (  g_rep_vst_rt_mng_tab(i).line_num          -- 行番号
           ,cv_report_id                              -- 帳票ＩＤ
           ,cv_report_name                            -- 帳票タイトル
           ,cd_now_date                               -- 出力日時
           ,id_standard_date                          -- 基準年月日
           ,id_start_date                             -- 基準日START
           ,id_end_date                               -- 基準日END
           ,iv_work_base_code                         -- 拠点コード
           ,iv_hub_name                               -- 拠点名称
           ,iv_employee_number                        -- 営業員コード
           ,iv_full_name                              -- 営業員名
           ,gn_total_count                            -- 総軒数
           ,gd_day_1                                  -- 月曜日-日
           ,cv_week_1                                 -- 月曜日-曜日
           ,gn_total_count_1                          -- 月曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_1  -- 月曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_1        -- 月曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_1   -- 月曜日-顧客名
           ,gd_day_2                                  -- 火曜日-日
           ,cv_week_2                                 -- 火曜日-曜日
           ,gn_total_count_2                          -- 火曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_2  -- 火曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_2        -- 火曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_2   -- 火曜日-顧客名
           ,gd_day_3                                  -- 水曜日-日
           ,cv_week_3                                 -- 水曜日-曜日
           ,gn_total_count_3                          -- 水曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_3  -- 水曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_3        -- 水曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_3   -- 水曜日-顧客名
           ,gd_day_4                                  -- 木曜日-日
           ,cv_week_4                                 -- 木曜日-曜日
           ,gn_total_count_4                          -- 木曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_4  -- 木曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_4        -- 木曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_4   -- 木曜日-顧客名
           ,gd_day_5                                  -- 金曜日-日
           ,cv_week_5                                 -- 金曜日-曜日
           ,gn_total_count_5                          -- 金曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_5  -- 金曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_5        -- 金曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_5   -- 金曜日-顧客名
           ,gd_day_6                                  -- 土曜日-日
           ,cv_week_6                                 -- 土曜日-曜日
           ,gn_total_count_6                          -- 土曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_6  -- 土曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_6        -- 土曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_6   -- 土曜日-顧客名
           ,gd_day_7                                  -- 日曜日-日
           ,cv_week_7                                 -- 日曜日-曜日
           ,gn_total_count_7                          -- 日曜日-総軒数
           ,g_rep_vst_rt_mng_tab(i).account_number_7  -- 日曜日-顧客コード
           ,g_rep_vst_rt_mng_tab(i).route_no_7        -- 日曜日-ルートNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_7   -- 日曜日-顧客名
           ,cn_created_by                             -- 作成者
           ,cd_creation_date                          -- 作成日
           ,cn_last_updated_by                        -- 最終更新者
           ,cd_last_update_date                       -- 最終更新日
           ,cn_last_update_login                      -- 最終更新ログイン
           ,cn_request_id                             -- 要求ID
           ,cn_program_application_id                 -- コンカレント・プログラム・アプリケーションID
           ,cn_program_id                             -- コンカレント・プログラムID
           ,cd_program_update_date                    -- プログラム更新日
         );
      END LOOP insert_row_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_07        --メッセージコード
                 ,iv_token_name1  => cv_tkn_act              --トークンコード1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_row_expt THEN
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-7)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf        OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode       OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg        OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)   := 'act_svf';     -- プログラム名
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A06S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A06S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- SVF起動処理 
    -- ======================
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => lv_file_id            -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_tkn_number_06        --メッセージコード
                 ,iv_token_name1  => cv_tkn_api_nm           --トークンコード1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --トークン値1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ワークテーブルデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf   OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode  OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg   OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100)   := 'delete_row';     -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- ワークテーブルデータ削除
    -- ==========================
    DELETE FROM xxcso_rep_visit_route_mng xrvrm -- 訪問総合管理表帳票ワークテーブル
    WHERE xrvrm.request_id = cn_request_id;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
-- #####################################  固定部 END   ##########################################
--
  END delete_row;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_standard_date    IN  VARCHAR2          -- 基準年月日
    ,iv_employee_number  IN  VARCHAR2          -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    -- データ抽出用(カーソルにて使用)
    cv_rt_num_hd_st   CONSTANT VARCHAR2(2) := '0';   -- 抽出ルートNo頭文字分岐処理用(最小値)
    cv_rt_num_hd_end  CONSTANT VARCHAR2(2) := '3';   -- 抽出ルートNo頭文字分岐処理用(最大値)
    cv_rt_num_mnth    CONSTANT VARCHAR2(2) := '5';   -- 抽出ルートNo頭文字分岐処理用(月単位訪問)
    cv_srtng_grp_a    CONSTANT VARCHAR2(2) := 'A';   -- 抽出ルートNo頭文字分岐処理グルーピング用(A)
    cv_srtng_grp_b    CONSTANT VARCHAR2(2) := 'B';   -- 抽出ルートNo頭文字分岐処理グルーピング用(B)
    cv_srtng_grp_c    CONSTANT VARCHAR2(2) := 'C';   -- 抽出ルートNo頭文字分岐処理グルーピング用(C)
    cn_dflt_vst_tm    CONSTANT NUMBER      := -999;  -- 抽出ルートNo頭文字分岐処理訪問回数設定用
    cv_date_plan      CONSTANT VARCHAR2(2) := '2';   -- 顧客別売上計画テーブル.月日区分「2」日別計画
-- Ver.1.5 [E_本稼動_14884] MOD START
--    cv_visit_target   CONSTANT VARCHAR2(2) := '1';   -- 顧客マスタ.訪問対象区分「1」訪問対象(取引含む)
    cv_visit_target_posi    CONSTANT VARCHAR2(1) := '1';   -- 顧客マスタ.訪問対象区分「1」(訪問対象・商談可)
    cv_visit_target_imposi  CONSTANT VARCHAR2(1) := '2';   -- 顧客マスタ.訪問対象区分「2」(訪問対象・商談不可)
    cv_visit_target_vd      CONSTANT VARCHAR2(1) := '5';   -- 顧客マスタ.訪問対象区分「5」(訪問対象・VD)
-- Ver.1.5 [E_本稼動_14884] MOD END
    cv_replace_char   CONSTANT VARCHAR2(2) := '-';   -- ルートNoをNUMBER型へ変換するためのリプレイス文字
    --
    cv_cstmr_cls_cd10      CONSTANT VARCHAR(2) := '10';      -- 顧客区分:10 (顧客)
    cv_cstmr_cls_cd15      CONSTANT VARCHAR(2) := '15';      -- 顧客区分:15 (巡回)
    cv_cstmr_cls_cd16      CONSTANT VARCHAR(2) := '16';      -- 顧客区分:16 (問屋帳合先)
    --
    cv_cstmr_sttus25       CONSTANT VARCHAR(2) := '25';      -- 顧客ステータス:25 (SP決済済)
    cv_cstmr_sttus30       CONSTANT VARCHAR(2) := '30';      -- 顧客ステータス:30 (承認済)
    cv_cstmr_sttus40       CONSTANT VARCHAR(2) := '40';      -- 顧客ステータス:40 (顧客)
    cv_cstmr_sttus50       CONSTANT VARCHAR(2) := '50';      -- 顧客ステータス:50 (休止)
    cv_cstmr_sttus99       CONSTANT VARCHAR(2) := '99';      -- 顧客ステータス:99 (対象外)
    -- *** ローカル変数 ***
    -- ループカウンタ
    ln_loop_cnt       NUMBER DEFAULT 1;
    -- OUTパラメータ格納用
    ld_standard_date  DATE;             -- 基準年月日(DATE型)
    ld_start_date     DATE;             -- 基準日初日
    ld_end_date       DATE;             -- 基準日末日
    ld_base_date      DATE;             -- ループ用基準日
    lv_full_name      VARCHAR(40);      -- 漢字氏名
    lv_work_base_code VARCHAR2(150);    -- 勤務地拠点コード
    lv_hub_name       VARCHAR2(4000);   -- 勤務地拠点名
    -- メッセージ格納用
    lv_msg            VARCHAR2(5000);
    -- SVF起動API戻り値格納用
    lv_errbuf_svf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode_svf    VARCHAR2(1);      -- リターン・コード
    lv_errmsg_svf     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
    /* 2009.05.11 K.Satomura T1_0926対応 START */
    ln_day_count      NUMBER; -- 各曜日単位の訪問件数
    /* 2009.05.11 K.Satomura T1_0926対応 END */
    -- *** ローカル・カーソル ***
    -- 営業員別時間別訪問実績 抽出カーソル 
    CURSOR get_prsn_dt_vst_pln_cur(
              id_base_date        IN  DATE     -- ループ用基準日
             ,iv_employee_number  IN VARCHAR2  -- 従業員コード
             ,iv_rt_num_hd_st     IN VARCHAR2  -- 抽出ルートNo頭文字処理分岐用(最小値)
             ,iv_rt_num_hd_end    IN VARCHAR2  -- 抽出ルートNo頭文字処理分岐用(最大値)
             ,iv_rt_num_mnth      IN VARCHAR2  -- 抽出ルートNo頭文字処理分岐用(月単位訪問)
             ,iv_srtng_grp_a      IN VARCHAR2  -- 抽出ルートNo頭文字分岐処理グルーピング用(A)
             ,iv_srtng_grp_b      IN VARCHAR2  -- 抽出ルートNo頭文字分岐処理グルーピング用(B)
             ,iv_srtng_grp_c      IN VARCHAR2  -- 抽出ルートNo頭文字分岐処理グルーピング用(C)
             ,in_dflt_vst_tm      IN NUMBER    -- 抽出ルートNo頭文字分岐処理訪問回数設定用
             ,iv_date_plan        IN VARCHAR2  -- 顧客別売上計画テーブル.月日区分「2」日別計画
-- Ver.1.5 [E_本稼動_14884] DEL START
--             ,iv_visit_target     IN VARCHAR2  -- 顧客マスタ.訪問対象区分「1」訪問対象(取引含む)
-- Ver.1.5 [E_本稼動_14884] DEL END
             ,iv_format_date_ymd1 IN VARCHAR2  -- 日付書式
             ,iv_replace_char     IN VARCHAR2  -- ルートNoをNUMBER型へ変換するためのリプレイス文字
           )
    IS
      SELECT   xca.account_number  account_number  -- 顧客コード
              ,xca.party_name      party_name      -- 顧客名称
              ,xcr2.route_number   route_number    -- ルートNo
              ,(CASE 
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN iv_srtng_grp_a
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN iv_srtng_grp_b
                ELSE iv_srtng_grp_c
                END) group_name                  -- 頭文字によるグループ(ソート用)
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE in_dflt_vst_tm
                END) visit_times                 -- 訪問回数(ソート用)
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                ELSE 1 / TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                END) rt_nmbr_fr_srtng            -- ルートNo(ソート用) 
      FROM     xxcso_cust_accounts_v xca         -- 顧客マスタビュー
              ,xxcso_account_sales_plans xasp    -- 顧客別売上計画テーブル
              ,xxcso_resource_custs_v2 xrc2      -- 営業員担当顧客（最新）ビュー
              ,xxcso_cust_routes_v2 xcr2         -- 顧客ルートNo（最新）ビュー
      WHERE   xrc2.employee_number    = iv_employee_number
        AND   xrc2.account_number     = xasp.account_number
        AND   xasp.plan_date          = TO_CHAR(id_base_date,iv_format_date_ymd1)
        AND   xasp.month_date_div     = iv_date_plan
        AND   xasp.sales_plan_day_amt > 0
        AND   xasp.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
-- Ver.1.5 [E_本稼動_14884] MOD START
--        AND   xca.vist_target_div     = iv_visit_target
        AND   xca.vist_target_div     IN (cv_visit_target_posi, cv_visit_target_imposi, cv_visit_target_vd)
-- Ver.1.5 [E_本稼動_14884] MOD END
        AND   xcr2.route_number IS NOT NULL
        AND   ((xca.customer_class_code    = cv_cstmr_cls_cd10
                AND xca.customer_status    IN (cv_cstmr_sttus25, cv_cstmr_sttus30,
                                                  cv_cstmr_sttus40, cv_cstmr_sttus50))
          OR  (xca.customer_class_code    = cv_cstmr_cls_cd15
                AND xca.customer_status    = cv_cstmr_sttus99)
          OR  (xca.customer_class_code    = cv_cstmr_cls_cd16
                AND xca.customer_status    = cv_cstmr_sttus99)
              )
      ORDER BY
         group_name          ASC
        ,visit_times         DESC
        ,rt_nmbr_fr_srtng    DESC
        ,xca.account_number  ASC
    ;
--
    -- *** ローカル・レコード ***
    l_prsn_dt_vst_pln_cur_rec  get_prsn_dt_vst_pln_cur%ROWTYPE;
    l_prsn_dt_vst_pln_rec      g_prsn_dt_vst_pln_rtype;
--    -- *** ローカル・例外 ***
----
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カウンタの初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    /* 2009.05.11 K.Satomura T1_0926対応 START */
    g_rep_vst_rt_mng_tab.DELETE;
    /* 2009.05.11 K.Satomura T1_0926対応 END */
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
       iv_standard_date    => iv_standard_date       -- 基準年月日
      ,iv_employee_number  => iv_employee_number     -- 従業員コード
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.パラメータチェック
    -- ========================================
    chk_param(
       iv_standard_date    => iv_standard_date       -- 基準年月日
      ,iv_employee_number  => iv_employee_number     -- 従業員コード
      ,od_standard_date    => ld_standard_date       -- 基準年月日(DATE型)
      ,ov_full_name        => lv_full_name           -- 漢字氏名
      ,ov_work_base_code   => lv_work_base_code      -- 勤務地拠点コード
      ,ov_hub_name         => lv_hub_name            -- 勤務地拠点名
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.帳票ヘッダ処理
    -- ========================================
    header_process(
       id_standard_date    => ld_standard_date       -- 基準年月日(DATE型)
      ,od_start_date       => ld_start_date          -- 基準日初日
      ,od_end_date         => ld_end_date            -- 基準日末日
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.データ取得
    -- ========================================
--
    <<get_prsn_dt_vst_pln_loop1>>
    LOOP
      -- 8回目にEXIT
      EXIT WHEN ln_loop_cnt >= 8;
--
      IF ln_loop_cnt = 1 THEN
        -- 1回目：カーソルに渡すループ用基準日に、基準日初日を設定
        ld_base_date := ld_start_date;
      ELSIF ln_loop_cnt >= 2 THEN
        -- 2回目以降：カーソルに渡すループ用基準日をカウントアップ
        ld_base_date := ld_base_date + 1;
      END IF;
--
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      ln_day_count := 0;
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- カーソルオープン
      OPEN  get_prsn_dt_vst_pln_cur(
               id_base_date        => ld_base_date        -- ループ用基準日
              ,iv_employee_number  => iv_employee_number  -- 従業員コード
              ,iv_rt_num_hd_st     => cv_rt_num_hd_st     -- 抽出ルートNo頭文字処理分岐用(最小値)
              ,iv_rt_num_hd_end    => cv_rt_num_hd_end    -- 抽出ルートNo頭文字処理分岐用(最大値)
              ,iv_rt_num_mnth      => cv_rt_num_mnth      -- 抽出ルートNo頭文字処理分岐用(月単位訪問)
              ,iv_srtng_grp_a      => cv_srtng_grp_a      -- 抽出ルートNo頭文字分岐処理グルーピング用(A)
              ,iv_srtng_grp_b      => cv_srtng_grp_b      -- 抽出ルートNo頭文字分岐処理グルーピング用(B)
              ,iv_srtng_grp_c      => cv_srtng_grp_c      -- 抽出ルートNo頭文字分岐処理グルーピング用(C)
              ,in_dflt_vst_tm      => cn_dflt_vst_tm      -- 抽出ルートNo頭文字分岐処理訪問回数設定用
              ,iv_date_plan        => cv_date_plan        -- 顧客別売上計画テーブル.月日区分「2」日別計画
-- Ver.1.5 [E_本稼動_14884] DEL START
--              ,iv_visit_target     => cv_visit_target     -- 顧客マスタ.訪問対象区分「1」訪問対象(取引含む)
-- Ver.1.5 [E_本稼動_14884] DEL END
              ,iv_format_date_ymd1 => cv_format_date_ymd1 -- 日付書式'YYYYMMDD'
              ,iv_replace_char     => cv_replace_char     -- ルートNoをNUMBER型へ変換するためのリプレイス文字
            );
--
      <<get_prsn_dt_vst_pln_loop2>>
      LOOP
--
        FETCH get_prsn_dt_vst_pln_cur INTO l_prsn_dt_vst_pln_cur_rec;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur%ROWCOUNT = 0;
--
        -- 処理対象件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        /* 2009.05.11 K.Satomura T1_0926対応 START */
        ln_day_count  := ln_day_count + 1;
        /* 2009.05.11 K.Satomura T1_0926対応 END */
--
        -- レコード変数初期化
        l_prsn_dt_vst_pln_rec := NULL;
--
        -- 取得データを格納
        l_prsn_dt_vst_pln_rec.account_number  := l_prsn_dt_vst_pln_cur_rec.account_number;   -- 顧客コード
        l_prsn_dt_vst_pln_rec.party_name      := l_prsn_dt_vst_pln_cur_rec.party_name;       -- 顧客名称
        l_prsn_dt_vst_pln_rec.route_no        := l_prsn_dt_vst_pln_cur_rec.route_number;     -- ルートNo
--
        -- ========================================
        -- A-5.配列の追加、更新
        -- ========================================
        ins_upd_lines(
           id_base_date           => ld_base_date           -- ループ用基準日
          ,i_prsn_dt_vst_pln_rec  => l_prsn_dt_vst_pln_rec  -- 営業員別日別訪問計画データ
          ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
          ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
          ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP get_prsn_dt_vst_pln_loop2;
      -- カーソルクローズ
      CLOSE get_prsn_dt_vst_pln_cur;
      /* 2009.05.11 K.Satomura T1_0926対応 START */
      IF (ln_day_count = 0) THEN
        -- 現在対象となっている曜日の訪問実績が存在しない場合、日付のみ出力する。
        l_prsn_dt_vst_pln_rec := NULL;
        --
        -- ========================================
        -- A-5.配列の追加、更新
        -- ========================================
        ins_upd_lines(
           id_base_date           => ld_base_date          -- ループ用基準日
          ,i_prsn_dt_vst_pln_rec  => l_prsn_dt_vst_pln_rec -- 営業員別日別訪問計画データ
          ,ov_errbuf              => lv_errbuf             -- エラー・メッセージ            --# 固定 #
          ,ov_retcode             => lv_retcode            -- リターン・コード              --# 固定 #
          ,ov_errmsg              => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
      --
      /* 2009.05.11 K.Satomura T1_0926対応 END */
      -- LOOP件数をカウントアップ
      ln_loop_cnt := ln_loop_cnt + 1;
--
    END LOOP get_prsn_dt_vst_pln_loop1;
--
    -- 処理対象データが0件の場合
    IF gn_target_cnt = 0 THEN
      -- 0件メッセージ出力
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name         --アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_09    --メッセージコード
                );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                 --ユーザー・エラーメッセージ
      );
--
      ov_retcode := cv_status_normal;
    ELSE
      -- ========================================
      -- A-6.ワークテーブルデータ登録
      -- ========================================
      insert_row(
         id_standard_date    => ld_standard_date       -- 基準年月日(DATE型)
        ,id_start_date       => ld_start_date          -- 基準日初日
        ,id_end_date         => ld_end_date            -- 基準日末日
        ,iv_work_base_code   => lv_work_base_code      -- 拠点コード
        ,iv_hub_name         => lv_hub_name            -- 拠点名称
        ,iv_employee_number  => iv_employee_number     -- 従業員コード
        ,iv_full_name        => lv_full_name           -- 漢字氏名
        ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
        ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
        ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-7.SVF起動
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode_svf               -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg_svf                -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := gn_total_count;
      END IF;
--
      -- ========================================
      -- A-8.ワークテーブルデータ削除
      -- ========================================
      delete_row(
         ov_errbuf     => lv_errbuf                    -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode                   -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg                    -- ユーザー・エラー・メッセージ  --# 固定 #
      );

      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-9.SVF起動APIエラーチェック
      -- ========================================
      IF (lv_retcode_svf = cv_status_error) THEN
        lv_errmsg := lv_errmsg_svf;
        lv_errbuf := lv_errbuf_svf;
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf             OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode            OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_standard_date   IN  VARCHAR2           --   基準年月日
    ,iv_employee_number IN  VARCHAR2           --   従業員コード
  )
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
--
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--    cv_log_msg         CONSTANT VARCHAR2(100) := 'システムエラーが発生しました。システム管理者に確認してください。';
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
    -- エラーメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- コンカレントヘッダメッセージ出力 出力区分
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
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
       iv_standard_date    => iv_standard_date   -- 基準年月日
      ,iv_employee_number  => iv_employee_number -- 従業員コード
      ,ov_errbuf           => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.LOG
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
         ,buff   => SUBSTRB(
                    cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf,1,5000
                    )
    /* 2009.05.20 M.Ohtsuki T1_0696対応 END */
       );
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => SUBSTRB(
--                      cv_log_msg ||cv_msg_prnthss_l||
--                      cv_pkg_name||cv_msg_cont||
--                      cv_prg_name||cv_msg_part||
--                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
--                    )
--       );                                                     --エラーメッセージ
    /* 2009.05.20 M.Ohtsuki T1_0696対応 START */
    END IF;
--
    -- =======================
    -- A-10.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
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
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO019A06C;
/
