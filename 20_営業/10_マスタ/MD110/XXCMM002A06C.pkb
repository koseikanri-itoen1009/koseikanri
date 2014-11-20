CREATE OR REPLACE PACKAGE BODY XXCMM002A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A06C(body)
 * Description      : 社員マスタIF出力(HHT)
 * MD.050           : 社員マスタIF出力(HHT) MD050_CMM_002_A06
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_rs_data            リソースマスタ情報取得プロシージャ(A-2)
 *  output_csv             CSVファイル出力プロシージャ(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS 福間 貴子    初回作成
 *  2009/04/24    1.1   Yutaka.Kuboshima 障害T1_0799の対応
 *  2009/06/08    1.2   H.Yoshikawa      障害T1_1135の対応
 *  2009/06/17    1.3   H.Yoshikawa      障害T1_1481の対応(営業員番号の設定誤り修正)
 *  2009/08/04    1.4   Yutaka.Kuboshima 障害0000890の対応
 *  2010/05/17    1.5   Yutaka.Kuboshima 障害E_本稼動_02749の対応(管理元拠点の取得位置の変更)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM002A06C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';         -- HHTCSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A06_OUT_FILE';     -- 連携用CSVファイル名
-- Ver1.2  2009/06/08  Del  不要なため削除
--  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A06_SYS_CAL_CODE'; -- システム稼働日カレンダコード値
-- End 1.2
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
-- Ver1.2  2009/06/08  Del  不要なため削除
--  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := 'システム稼働日カレンダコード値';
-- End 1.2
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(10)  := '営業員番号';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_param              CONSTANT VARCHAR2(5)   := 'PARAM';                      -- パラメータ名
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '最終更新日(開始)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '最終更新日(終了)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '入力パラメータ';
  cv_tkn_value              CONSTANT VARCHAR2(5)   := 'VALUE';                      -- パラメータ値
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- 入力パラメータ出力メッセージ
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
-- Ver1.2  2009/06/08  Del  不要なため削除
--  cv_msg_00035              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00035';           -- 前のシステム稼働日取得エラー
--  cv_msg_00036              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00036';           -- 次のシステム稼働日取得エラー
--  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- 対象期間制限エラー
-- End 1.2
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- 対象期間指定エラー
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
-- Ver1.2  2009/06/08  Add  パラメータ最終更新日（終了）を業務日付に固定のため
  cv_msg_00220              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00220';           -- 最終更新日（終了）指定エラー
-- End1.2
  -- 固定値(設定値、抽出条件)
  cv_kbn_souko              CONSTANT VARCHAR2(1)   := '1';                          -- 保管場所区分(倉庫)
  cv_category               CONSTANT VARCHAR2(10)  := 'EMPLOYEE';                   -- カテゴリ
--
-- 2009/08/04 Ver1.4 add start by Yutaka.Kuboshima
  cv_base                   CONSTANT VARCHAR2(1)   := '1';                          -- 顧客区分(拠点)
  cv_dept_div_mult          CONSTANT VARCHAR2(1)   := '1';                          -- 百貨店HHT区分(拠点複)
-- 2009/08/04 Ver1.4 add end by Yutaka.Kuboshima
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
-- Ver1.2  2009/06/08  Del  不要なため削除
--  gv_cal_code               VARCHAR2(30);         -- システム稼働日カレンダコード値
-- End 1.2
  gd_process_date           DATE;                 -- 業務日付
  gd_select_start_date      DATE;                 -- 取得開始日
-- Ver1.2  2009/06/08  Del  抽出条件変更に伴う削除
--  gd_select_start_datetime  DATE;                 -- 取得開始日(時刻 00:00:00)
-- End 1.2
  gd_select_end_date        DATE;                 -- 取得終了日
-- Ver1.2  2009/06/08  Del  抽出条件変更に伴う削除
--  gd_select_end_datetime    DATE;                 -- 取得終了日(時刻 23:59:59)
--  gd_select_next_date       DATE;                 -- 取得次のシステム稼働日
-- End 1.2
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gv_update_sdate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(開始)
  gv_update_edate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(終了)
  gv_attribute1             VARCHAR2(4);          -- 拠点コード
  gv_param_output_flg       VARCHAR2(1);          -- 入力パラメータ出力フラグ(出力前:0、出力後:1)
  --
-- Ver1.2  2009/06/08  Add  抽出条件変更に伴う追加
  gd_active_start_date      DATE;
  gd_active_end_date        DATE;
  gd_inactive_start_date    DATE;
  gd_inactive_end_date      DATE;
  --
  cv_flag_active            VARCHAR(1) := '1';    -- 有効データ
  cv_flag_inactive          VARCHAR(1) := '2';    -- 無効データ
-- End 1.2
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
-- Ver1.2  2009/06/08  Del  抽出SQLを全改修、get_rs_data へ移動のため削除
--  CURSOR get_rs_data_cur
--  IS
--    SELECT   SUBSTRB(r.source_number,1,5) AS source_number,
--             SUBSTRB(r.source_name,1,20) AS source_name,
--             TO_CHAR(s.actual_termination_date,'YYYYMMDD') AS actual_termination_date,
--             TO_CHAR(r.last_update_date,'YYYY/MM/DD HH24:MI:SS') AS last_update_date,
--             r.resource_id AS resource_id
--    FROM     per_periods_of_service s,
--             (SELECT   ss.person_id AS person_id,
--                       MAX(ss.date_start) as date_start
--              FROM     per_periods_of_service ss
--              GROUP BY ss.person_id) ss,
---- 2009/04/24 Ver1.1 modify start by Yutaka.Kuboshima
----             jtf_rs_defresources_vl r
--             jtf_rs_resource_extns r,
--             jtf_rs_salesreps jrs
---- 2009/04/24 Ver1.1 modify end by Yutaka.Kuboshima
--    WHERE    r.category = cv_category
--    AND      r.last_update_date >= gd_select_start_datetime
--    AND      r.last_update_date <= gd_select_end_datetime
--    AND      r.source_id = ss.person_id
--    AND      ss.person_id = s.person_id
--    AND      ss.date_start = s.date_start
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--    AND      jrs.resource_id = r.resource_id(+)
--    AND      jrs.org_id      = FND_GLOBAL.ORG_ID
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--    UNION
--    SELECT   SUBSTRB(r.source_number,1,5) AS source_number,
--             SUBSTRB(r.source_name,1,20) AS source_name,
--             TO_CHAR(s.actual_termination_date,'YYYYMMDD') AS actual_termination_date,
--             TO_CHAR(r.last_update_date,'YYYY/MM/DD HH24:MI:SS') AS last_update_date,
--             r.resource_id AS resource_id
---- 2009/04/24 Ver1.1 modify start by Yutaka.Kuboshima
----    FROM     jtf_rs_defresources_vl r,
--    FROM     jtf_rs_resource_extns r,
--             jtf_rs_salesreps jrs,
---- 2009/04/24 Ver1.1 modify end by Yutaka.Kuboshima
--             per_periods_of_service s,
--             (SELECT   ss.person_id AS person_id,
--                       MAX(ss.date_start) as date_start
--              FROM     per_periods_of_service ss
--              GROUP BY ss.person_id) ss
--    WHERE    ss.person_id = s.person_id
--    AND      ss.date_start = s.date_start
--    AND      s.actual_termination_date >= gd_select_end_date
--    AND      s.actual_termination_date < gd_select_next_date
--    AND      r.source_id = s.person_id
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--    AND      jrs.resource_id = r.resource_id(+)
--    AND      jrs.org_id      = FND_GLOBAL.ORG_ID
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--  ;
--  TYPE g_rs_data_ttype IS TABLE OF get_rs_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
--  gt_rs_data            g_rs_data_ttype;
-- End 1.2
--
  -- 出力するリソース情報を格納するレコードを定義
  TYPE g_rs_data_rtype IS RECORD(
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--    resource_number                VARCHAR2(5)          -- 営業員コード
    source_number                  VARCHAR2(5)          -- 営業員コード
-- End1.3
   ,resource_name                  VARCHAR2(20)         -- 営業員名
   ,resource_department            VARCHAR2(4)          -- 拠点コード
   ,inactive_date                  VARCHAR2(8)          -- 無効日
   ,last_update_date               VARCHAR2(19)         -- 更新日時
  );
  -- 出力するリソース情報を格納する配列を定義
  TYPE g_rs_data_ttype IS TABLE OF g_rs_data_rtype INDEX BY BINARY_INTEGER;
  -- 出力するリソース情報を格納する配列変数
  g_rs_data_tab                    g_rs_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- プログラム名
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
    -- ファイルオープンモード
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- 上書き
--
    -- *** ローカル変数 ***
    lb_fexists              BOOLEAN;              -- ファイルが存在するかどうか
    ln_file_size            NUMBER;               -- ファイルの長さ
    ln_block_size           NUMBER;               -- ファイルシステムのブロックサイズ
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
-- Ver1.2  2009/06/08  Del  不要なため削除
--    -- =========================================================
--    -- プロファイル(システム稼働日カレンダのカレンダコード値)を取得
--    -- =========================================================
--    gv_cal_code := fnd_profile.value(cv_cal_code);
--    IF (gv_cal_code IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
--                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
--                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
--                      ,iv_token_value1 => cv_tkn_cal_code      -- プロファイル名(システム稼働日カレンダコード値)
--                      );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
-- End 1.2
    --
    -- =========================================================
    --  取得開始日、取得終了日、取得次のシステム稼働日の取得
    -- =========================================================
    -- 業務日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00018           -- 業務処理日付取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Ver1.2  2009/06/08  Mod  条件修正のため
--    -- 取得開始日の取得
--    IF (gv_update_sdate IS NULL) THEN
--      -- 業務日付の前のシステム稼働日の次の日をセット
--      gd_select_start_date := xxccp_common_pkg2.get_working_day(gd_process_date,-1,gv_cal_code) + 1;
--      IF (gd_select_start_date IS NULL) THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
--                        ,iv_name         => cv_msg_00035         -- 前のシステム稼働日取得エラー
--                       );
--        lv_errbuf := lv_errmsg;
--        RAISE global_api_expt;
--      END IF;
--    -- 取得終了日の取得
--    IF (gv_update_edate IS NULL) THEN
--      -- 業務日付をセット
--      gd_select_end_date := gd_process_date;
--    ELSE
--      -- 最終更新日(終了)をセット
--      gd_select_end_date := TO_DATE(gv_update_edate,'YYYY/MM/DD');
--    END IF;
--    -- 検索条件用に時刻をセット
--    gd_select_start_datetime := TO_DATE(TO_CHAR(gd_select_start_date,'YYYY/MM/DD') || ' 00:00:00','YYYY/MM/DD HH24:MI:SS');
--    gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
--    -- 取得次のシステム稼働日を取得
--    gd_select_next_date := xxccp_common_pkg2.get_working_day(gd_select_end_date,1,gv_cal_code);
--    IF (gd_select_next_date IS NULL) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
--                      ,iv_name         => cv_msg_00036         -- 次のシステム稼働日取得エラー
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
    --
    -- 取得開始日の取得
    IF  ( gv_update_sdate IS NULL )
    AND ( gv_update_edate IS NULL ) THEN
      -- 有効期間(開始)と有効期間(終了)に業務日付+1をセット
      gd_active_start_date   := gd_process_date + 1;
      gd_active_end_date     := gd_process_date + 1;
      -- 最終更新日(開始)と最終更新日(終了)に業務日付～業務日付+1をセット
      gd_select_start_date   := gd_process_date;
      gd_select_end_date     := gd_process_date;
    ELSE
      -- 有効期間(開始)に指定日をセット
      gd_active_start_date   := TO_DATE( gv_update_sdate, 'RRRR/MM/DD' );
      -- 有効期間(終了)に業務日付をセット
      gd_active_end_date     := TO_DATE( gv_update_edate, 'RRRR/MM/DD' );
      -- 最終更新日(開始)と最終更新日(終了)に有効期間と同じ値をセット
      gd_select_start_date   := gd_active_start_date;
      gd_select_end_date     := gd_active_end_date;
    END IF;
    --
    gd_inactive_start_date := gd_active_start_date - 1;
    gd_inactive_end_date   := gd_active_end_date - 1;
    --
-- End 1.2
    --
    -- =========================================================
    --  固定出力(入力パラメータ部)
    -- =========================================================
    -- 入力パラメータ
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param3          -- パラメータ名(入力パラメータ)
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => gv_update_sdate || '.' || gv_update_edate
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 取得開始日
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param1          -- パラメータ名(最終更新日(開始))
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => TO_CHAR(gd_select_start_date,'YYYY/MM/DD')
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 取得終了日
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                    ,iv_name         => cv_msg_00038           -- 入力パラメータ出力メッセージ
                    ,iv_token_name1  => cv_tkn_param           -- トークン(PARAM)
                    ,iv_token_value1 => cv_tkn_param2          -- パラメータ名(最終更新日(終了))
                    ,iv_token_name2  => cv_tkn_value           -- トークン(VALUE)
                    ,iv_token_value2 => TO_CHAR(gd_select_end_date,'YYYY/MM/DD')
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    -- 空行挿入(入力パラメータの下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- 入力パラメータ出力フラグに「出力後」をセット
    gv_param_output_flg := '1';
    --
    -- =========================================================
    --  対象期間指定チェック
    -- =========================================================
    IF (gd_select_start_date > gd_select_end_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00019           -- 対象期間指定エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  対象期間制限チェック
    -- =========================================================
-- Ver1.2  2009/06/08  Mod  条件修正のため変更
--    IF (gd_select_start_date > gd_process_date) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--    IF (gd_select_end_date > gd_process_date) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--
--    IF ( gd_select_start_date > gd_process_date ) THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
--                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
--                     );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
    --
    -- 手動起動時の最終更新日（終了）は業務日付のみ指定可能
    IF ( gv_update_sdate IS NOT NULL ) THEN
      -- 取得開始日の取得
      IF ( gv_update_edate IS NULL )
      OR ( gd_select_end_date <> gd_process_date ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        ,iv_name         => cv_msg_00220           -- 最終更新日（終了）エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    --
-- End 1.2
    --
    -- =========================================================
    --  プロファイルの取得(CSVファイル出力先、CSVファイル名)
    -- =========================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile         -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm     -- プロファイル名(CSVファイル出力先)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00002           -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile         -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm     -- プロファイル名(CSVファイル名)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- =========================================================
    --  固定出力(I/Fファイル名部)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- 'XXCCP'
                    ,iv_name         => cv_msg_05102             -- ファイル名出力メッセージ
                    ,iv_token_name1  => cv_tkn_filename          -- トークン(FILE_NAME)
                    ,iv_token_value1 => gv_filename              -- ファイル名
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入(I/Fファイル名の下)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- =========================================================
    --  CSVファイル存在チェック
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00010           -- ファイル作成済みエラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =========================================================
    --  ファイルオープン
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00003         -- ファイルパス不正エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_rs_data
   * Description      : リソースマスタ情報取得プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE get_rs_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_rs_data';       -- プログラム名
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
-- Ver1.2  2009/06/08  Add  変数追加
    ln_stack_cnt          NUMBER;
    ln_resource_id_wk     jtf_rs_resource_extns.resource_id%TYPE;
    lv_re_flag            VARCHAR2(1);
-- End 1.2
--
    -- *** ローカル・カーソル ***
-- Ver1.2  2009/06/08  Add  抽出SQLを全改修 + get_rs_data に移動して追加
    -----------------
    -- 通常起動時用
    -----------------
    CURSOR get_rs_data_cur
    IS
      -- リソースグループ役割有効データ抽出
      SELECT    cv_flag_active      AS  data_div       -- データ区分(有効)
               ,jrrm.denorm_mgr_id                     -- リソースグループ役割ID
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--               ,jrse.resource_number                   -- 営業員番号
               ,papf.employee_number                     -- 営業員番号
-- End1.3
               ,jrrm.resource_id                       -- リソースID
               ,jrrm.group_id                          -- グループID
               ,jrrm.person_id                         -- 従業員ID
               ,papf.per_information18 || papf.per_information19
                                    AS  emp_name       -- 漢字姓 + 漢字名
               ,jrrm.start_date_active                 -- 有効開始日_自
               ,jrrm.end_date_active                   -- 有効開始日_至
               ,jrrm.last_update_date                  -- 最終更新日
               ,jrgv.group_name                        -- グループ名称
               ,jrgv.attribute1     AS  base_code      -- 拠点コード
      FROM      jtf_rs_rep_managers     jrrm           -- リソースグループ役割
               ,per_all_people_f        papf           -- 従業員
               ,jtf_rs_resource_extns   jrse           -- リソース
               ,jtf_rs_salesreps        jrs
               ,jtf_rs_groups_vl        jrgv           -- グループ
               ,xxcso_aff_base_v2       xabv
      WHERE    -- 有効期間_自が指定範囲内、または、最終更新日が指定範囲内
            ( ( jrrm.start_date_active         >= gd_active_start_date )   -- 有効期間_自 >= パラメータ_FROM(JP1:業務日付+1)
           OR ( TRUNC( jrrm.last_update_date ) >= gd_select_start_date     -- 最終更新日  >= パラメータ_FROM(JP1:業務日付)
            AND TRUNC( jrrm.last_update_date ) <= gd_select_end_date ) )   -- 最終更新日  <= パラメータ_TO  (JP1:業務日付)
      -- パラメータTO で有効なもの
      AND       jrrm.start_date_active         <= gd_active_end_date       -- 有効期間_自 <= パラメータ_TO  (JP1:業務日付+1)
      AND       NVL( jrrm.end_date_active, gd_active_end_date )
                                               >= gd_active_end_date       -- 有効期間_至 >= パラメータ_TO  (JP1:業務日付+1)
      AND       jrrm.reports_to_flag            = 'N'
      AND       papf.person_id                  = jrrm.person_id           -- 従業員ID
      AND       papf.effective_end_date        >= gd_active_end_date
      AND       papf.current_emp_or_apl_flag    = 'Y'                      -- 履歴フラグ
      AND       jrse.resource_id                = jrrm.resource_id
      AND       jrse.category                   = cv_category
      AND       jrs.resource_id(+)              = jrse.resource_id
      AND       jrs.org_id(+)                   = FND_GLOBAL.ORG_ID
      AND       jrgv.group_id                   = jrrm.group_id
      AND       xabv.base_code                  = jrgv.attribute1
      --
      UNION ALL
      --
      -- リソースグループ役割無効データ抽出
      SELECT    cv_flag_inactive    AS  data_div       -- データ区分(無効)
               ,jrrm.denorm_mgr_id                     -- リソースグループ役割ID
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--               ,jrse.resource_number                   -- 営業員番号
               ,papf.employee_number                   -- 営業員番号
-- End1.3
               ,jrrm.resource_id                       -- リソースID
               ,jrrm.group_id                          -- グループID
               ,jrrm.person_id                         -- 従業員ID
               ,papf.per_information18 || papf.per_information19
                                    AS  emp_name       -- 漢字姓 + 漢字名
               ,jrrm.start_date_active                 -- 有効開始日_自
               ,jrrm.end_date_active                   -- 有効開始日_至
               ,jrrm.last_update_date                  -- 最終更新日
               ,jrgv.group_name                        -- グループ名称
               ,jrgv.attribute1     AS  base_code      -- 拠点コード
      FROM      jtf_rs_rep_managers     jrrm           -- リソースグループ役割
               ,per_all_people_f        papf           -- 従業員
               ,jtf_rs_resource_extns   jrse           -- リソース
               ,jtf_rs_salesreps        jrs
               ,jtf_rs_groups_vl        jrgv           -- グループ
               ,xxcso_aff_base_v2       xabv
      WHERE     -- 有効期間_至が指定範囲内
            ( ( jrrm.end_date_active           >= gd_inactive_start_date ) -- 有効期間_自 >= パラメータ_FROM(JP1:業務日付)
                -- 最終更新日が指定範囲内で現在有効でない
           OR ( TRUNC( jrrm.last_update_date ) >= gd_select_start_date     -- 最終更新日  >= パラメータ_FROM(JP1:業務日付)
            AND TRUNC( jrrm.last_update_date ) <= gd_select_end_date ) )   -- 最終更新日  <= パラメータ_TO  (JP1:業務日付)
      AND       jrrm.end_date_active           <= gd_inactive_end_date     -- 有効期間_至 <= パラメータ_TO  (JP1:業務日付)
      AND       jrrm.reports_to_flag            = 'N'
      AND       papf.person_id                  = jrrm.person_id           -- 従業員ID
      AND       papf.effective_end_date        >= gd_active_end_date
      AND       papf.current_emp_or_apl_flag    = 'Y'                      -- 履歴フラグ
      AND       jrse.resource_id                = jrrm.resource_id
      AND       jrse.category                   = cv_category
      AND       jrs.resource_id(+)              = jrse.resource_id
      AND       jrs.org_id(+)                   = FND_GLOBAL.ORG_ID
      AND       jrgv.group_id                   = jrrm.group_id
      AND       xabv.base_code                  = jrgv.attribute1
      --
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--      ORDER BY  resource_number
      ORDER BY  employee_number
-- End1.3
               ,data_div
               ,start_date_active  DESC
               ,last_update_date   DESC;
    --
    -- 拠点コード抽出カーソル
    CURSOR get_act_rs_data_cur(
      p_resource_id      jtf_rs_resource_extns.resource_id%TYPE )
    IS
      SELECT    jrrm.denorm_mgr_id
               ,jrrm.last_update_date              -- 最終更新日
               ,jrgv.attribute1     AS  base_code  -- 拠点コード
      FROM      jtf_rs_rep_managers     jrrm       -- リソースグループ役割
               ,jtf_rs_groups_vl        jrgv       -- グループ
               ,xxcso_aff_base_v2       xabv
      WHERE     jrrm.resource_id                = p_resource_id            -- 該当リソース
      AND       jrrm.reports_to_flag            = 'N'
      AND       jrrm.start_date_active         <= gd_active_end_date       -- 有効期間_自 <= パラメータ_TO(JP1:業務日付+1)
      AND       NVL( jrrm.end_date_active, gd_active_end_date )
                                               >= gd_active_end_date       -- 有効期間_至 >= パラメータ_TO(JP1:業務日付+1)
      AND       jrgv.group_id                   = jrrm.group_id
      AND       xabv.base_code                  = jrgv.attribute1
      ORDER BY  jrrm.start_date_active  DESC
               ,jrrm.last_update_date   DESC;
    --
-- 2009/08/04 Ver1.4 add start by Yutaka.Kuboshima
    -- 管理元拠点検索カーソル
    CURSOR management_base_cur(p_base_code IN VARCHAR2)
    IS
      SELECT xca.management_base_code   -- 管理元拠点コード
            ,xca.dept_hht_div           -- 百貨店HHT区分
      FROM   hz_cust_accounts    hca    -- 顧客マスタ
            ,xxcmm_cust_accounts xca    -- 顧客追加情報マスタ
      WHERE  hca.cust_account_id     = xca.customer_id
        AND  hca.customer_class_code = cv_base
        AND  hca.account_number      = p_base_code;
-- 2009/08/04 Ver1.4 add end by Yutaka.Kuboshima
    -- *** ローカル・レコード ***
    -- リソースグループ役割有効データ再抽出カーソルレコードタイプ
    l_act_rs_data_rec     get_act_rs_data_cur%ROWTYPE;
    --
-- End 1.2
--
-- 2009/08/04 Ver1.4 add start by Yutaka.Kuboshima
    -- 管理元拠点検索カーソルレコードタイプ
    l_management_base_rec management_base_cur%ROWTYPE;
-- 2009/08/04 Ver1.4 add start by Yutaka.Kuboshima
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
-- Ver1.2  2009/06/08  Del  データ取得はカーソルFORループに変更、出力情報はすべてこのプロシージャで設定のため全改修
--   -- カーソルオープン
--    OPEN get_rs_data_cur;
----
--    -- データの一括取得
--    FETCH get_rs_data_cur BULK COLLECT INTO gt_rs_data;
----
--    -- 対象件数をセット
--    gn_target_cnt := gt_rs_data.COUNT;
----
--    -- カーソルクローズ
--    CLOSE get_rs_data_cur;
-- End 1.2
--
-- Ver1.2  2009/06/08  Add  全改修のため追加
    ln_stack_cnt := 0;
    --
    <<get_rs_data>>
    FOR l_get_rs_data_rec IN get_rs_data_cur LOOP
      --
      IF ( ln_resource_id_wk IS NULL )
      OR ( ln_resource_id_wk <> l_get_rs_data_rec.resource_id ) THEN
        -- リソースIDの退避
        ln_resource_id_wk := l_get_rs_data_rec.resource_id;
        --
        -- 拠点コード抽出カーソルオープン
        OPEN  get_act_rs_data_cur( ln_resource_id_wk );
        --
        FETCH get_act_rs_data_cur INTO l_act_rs_data_rec;
        --
        IF ( get_act_rs_data_cur%NOTFOUND ) THEN
          -- 出力データ格納(無効分)
          ln_stack_cnt := ln_stack_cnt + 1;
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--          g_rs_data_tab(ln_stack_cnt).resource_number     := SUBSTRB( l_get_rs_data_rec.resource_number, 1, 5 );
          g_rs_data_tab(ln_stack_cnt).source_number       := SUBSTRB( l_get_rs_data_rec.employee_number, 1, 5 );
-- End1.3
          g_rs_data_tab(ln_stack_cnt).resource_name       := SUBSTRB( l_get_rs_data_rec.emp_name, 1, 20 );
          g_rs_data_tab(ln_stack_cnt).resource_department := SUBSTRB( l_get_rs_data_rec.base_code, 1, 4 );
          g_rs_data_tab(ln_stack_cnt).inactive_date       := TO_CHAR( l_get_rs_data_rec.end_date_active, 'YYYYMMDD' );
          g_rs_data_tab(ln_stack_cnt).last_update_date    := TO_CHAR( l_get_rs_data_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS' );
-- 2010/05/17 Ver1.5 add start by Yutaka.Kuboshima
-- 管理元拠点の取得位置を変更
            -- 管理元拠点を取得します
            OPEN management_base_cur(g_rs_data_tab(ln_stack_cnt).resource_department);
            FETCH management_base_cur INTO l_management_base_rec;
            CLOSE management_base_cur;
            -- 百貨店HHT区分が'1'の場合
            IF (l_management_base_rec.dept_hht_div = cv_dept_div_mult) THEN
              -- リソースグループに管理元拠点をセットします
              g_rs_data_tab(ln_stack_cnt).resource_department := SUBSTRB( l_management_base_rec.management_base_code, 1, 4 );
            END IF;
            -- 変数初期化
            l_management_base_rec := NULL;
-- 2010/05/17 Ver1.5 add end by Yutaka.Kuboshima
        ELSE
          -- 有効データ抽出時：有効データ抽出と拠点抽出で同じリソースグループ役割の場合連携対象とする
          -- 無効データ抽出時：拠点抽出で抽出したリソースグループを連携対象とする
          IF  ( l_get_rs_data_rec.denorm_mgr_id = l_act_rs_data_rec.denorm_mgr_id )
          OR  ( l_get_rs_data_rec.data_div = cv_flag_inactive ) THEN
            -- 出力データ格納(有効分)
            ln_stack_cnt := ln_stack_cnt + 1;
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--            g_rs_data_tab(ln_stack_cnt).resource_number     := SUBSTRB( l_get_rs_data_rec.resource_number, 1, 5 );
            g_rs_data_tab(ln_stack_cnt).source_number       := SUBSTRB( l_get_rs_data_rec.employee_number, 1, 5 );
-- End1.3
            g_rs_data_tab(ln_stack_cnt).resource_name       := SUBSTRB( l_get_rs_data_rec.emp_name, 1, 20 );
            g_rs_data_tab(ln_stack_cnt).resource_department := SUBSTRB( l_act_rs_data_rec.base_code, 1, 4 );
            g_rs_data_tab(ln_stack_cnt).inactive_date       := NULL;
            g_rs_data_tab(ln_stack_cnt).last_update_date    := TO_CHAR( l_act_rs_data_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS' );
-- 2010/05/17 Ver1.5 add start by Yutaka.Kuboshima
-- 管理元拠点の取得位置を変更
            -- 管理元拠点を取得します
            OPEN management_base_cur(g_rs_data_tab(ln_stack_cnt).resource_department);
            FETCH management_base_cur INTO l_management_base_rec;
            CLOSE management_base_cur;
            -- 百貨店HHT区分が'1'の場合
            IF (l_management_base_rec.dept_hht_div = cv_dept_div_mult) THEN
              -- リソースグループに管理元拠点をセットします
              g_rs_data_tab(ln_stack_cnt).resource_department := SUBSTRB( l_management_base_rec.management_base_code, 1, 4 );
            END IF;
            -- 変数初期化
            l_management_base_rec := NULL;
-- 2010/05/17 Ver1.5 add end by Yutaka.Kuboshima
          END IF;
        END IF;
        --
        CLOSE get_act_rs_data_cur;
        --
-- 2010/05/17 Ver1.5 delete start by Yutaka.Kuboshima
-- 管理元拠点の取得位置を変更
-- 2009/08/04 Ver1.4 add start by Yutaka.Kuboshima
--        -- 管理元拠点を取得します
--        OPEN management_base_cur(g_rs_data_tab(ln_stack_cnt).resource_department);
--        FETCH management_base_cur INTO l_management_base_rec;
--        CLOSE management_base_cur;
--        -- 百貨店HHT区分が'1'の場合
--        IF (l_management_base_rec.dept_hht_div = cv_dept_div_mult) THEN
--          -- リソースグループに管理元拠点をセットします
--          g_rs_data_tab(ln_stack_cnt).resource_department := SUBSTRB( l_management_base_rec.management_base_code, 1, 4 );
--        END IF;
--        -- 変数初期化
--        l_management_base_rec := NULL;
-- 2009/08/04 Ver1.4 add end by Yutaka.Kuboshima
-- 2010/05/17 Ver1.5 delete end by Yutaka.Kuboshima
      END IF;
    END LOOP get_rs_data;
    --
    gn_target_cnt := ln_stack_cnt;
-- End 1.2
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
-- Ver1.2  2009/06/08  Add  全改修のため追加
      IF ( get_act_rs_data_cur%ISOPEN ) THEN
        CLOSE get_act_rs_data_cur;
      END IF;
-- End 1.2
----#####################################  固定部 END   ##########################################
--
  END get_rs_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- プログラム名
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
    cv_delimiter              CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed               CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt               NUMBER;                   -- ループカウンタ
    lv_csv_text               VARCHAR2(32000);          -- 出力１行分文字列変数
--
-- Ver1.2  2009/06/08  Add  エラー時のSQLERRM退避用に追加
    lv_sql_errm               VARCHAR2(2000);
-- End 1.2
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    put_line_others_expt      EXCEPTION;
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
-- Ver1.2  2009/06/08  Del  出力データの配列への設定は、get_rs_dataで行う
--                          また、変数名の修正もあり全改修
--    <<out_loop>>
--    FOR ln_loop_cnt IN gt_rs_data.FIRST..gt_rs_data.LAST LOOP
--      --==============================================================
--      -- 拠点コードの取得(A-3)
--      --==============================================================
--      BEGIN
--        SELECT   SUBSTRB(g.attribute1,1,4) INTO gv_attribute1
--        FROM     jtf_rs_group_members_vl m,
--                 jtf_rs_groups_vl g
--        WHERE    m.resource_id = gt_rs_data(ln_loop_cnt).resource_id
--        AND      m.DELETE_FLAG = 'N'
--        AND      m.group_id = g.group_id
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--        AND      ROWNUM = 1;
---- 2009/04/24 Ver1.1 add end by Yutaka.Kuboshima
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          gv_attribute1 := NULL;
---- 2009/04/24 Ver1.1 add start by Yutaka.Kuboshima
--        WHEN TOO_MANY_ROWS THEN
--          gv_attribute1 := NULL;
---- 2009/04/24 Ver1.1 add end by Yutaka.Kuboshima
--        WHEN OTHERS THEN
--          RAISE global_api_others_expt;
--      END;
--      lv_csv_text := cv_enclosed || gt_rs_data(ln_loop_cnt).source_number || cv_enclosed || cv_delimiter  -- 営業員コード
--        || cv_enclosed || gt_rs_data(ln_loop_cnt).source_name || cv_enclosed || cv_delimiter              -- 営業員名称
--        || cv_enclosed || gv_attribute1 || cv_enclosed || cv_delimiter                                    -- リソースグループ
--        || gt_rs_data(ln_loop_cnt).actual_termination_date || cv_delimiter                                -- 退職年月日
--        || cv_enclosed || gt_rs_data(ln_loop_cnt).last_update_date || cv_enclosed                         -- 更新日時
--      ;
--      BEGIN
--        -- ファイル書き込み
--        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
--      EXCEPTION
--        -- ファイルアクセス権限エラー
--        WHEN UTL_FILE.INVALID_OPERATION THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(
--                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                          ,iv_name         => cv_msg_00007                             -- ファイルアクセス権限エラー
--                         );
--          lv_errbuf := lv_errmsg;
--          RAISE global_api_expt;
--        --
--        -- CSVデータ出力エラー
--        WHEN UTL_FILE.WRITE_ERROR THEN
--          lv_errmsg := xxcmn_common_pkg.get_msg(
--                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
--                          ,iv_name         => cv_msg_00009                             -- CSVデータ出力エラー
--                          ,iv_token_name1  => cv_tkn_word                              -- トークン(NG_WORD)
--                          ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD
--                          ,iv_token_name2  => cv_tkn_data                              -- トークン(NG_DATA)
--                          ,iv_token_value2 => gt_rs_data(ln_loop_cnt).source_number    -- NG_WORDのDATA
--                         );
--          lv_errbuf := lv_errmsg;
--          RAISE global_api_expt;
--        WHEN OTHERS THEN
--          RAISE global_api_others_expt;
--      END;
--      --
--      -- 処理件数のカウント
--      gn_normal_cnt := gn_normal_cnt + 1;
--    END LOOP out_loop;
-- End 1.2
--
-- Ver1.2  2009/06/08  Add  ファイル出力を全面改修のため追加
    <<output_rs_data_loop>>
    FOR ln_loop_cnt IN g_rs_data_tab.FIRST..g_rs_data_tab.LAST LOOP
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--      lv_csv_text := cv_enclosed || g_rs_data_tab(ln_loop_cnt).resource_number     || cv_enclosed || cv_delimiter  -- 営業員コード
      lv_csv_text := cv_enclosed || g_rs_data_tab(ln_loop_cnt).source_number       || cv_enclosed || cv_delimiter  -- 営業員コード
-- End1.3
                  || cv_enclosed || g_rs_data_tab(ln_loop_cnt).resource_name       || cv_enclosed || cv_delimiter  -- 営業員名
                  || cv_enclosed || g_rs_data_tab(ln_loop_cnt).resource_department || cv_enclosed || cv_delimiter  -- 拠点コード
                                 || g_rs_data_tab(ln_loop_cnt).inactive_date                      || cv_delimiter  -- 無効日
                  || cv_enclosed || g_rs_data_tab(ln_loop_cnt).last_update_date    || cv_enclosed                  -- 更新日時
      ;
      --
      BEGIN
        -- ファイル書き込み
        UTL_FILE.PUT_LINE( gf_file_hand, lv_csv_text );
      EXCEPTION
        -- ファイルアクセス権限エラー
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                          ,iv_name         => cv_msg_00007       -- ファイルアクセス権限エラー
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSVデータ出力エラー
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                          ,iv_name         => cv_msg_00009       -- CSVデータ出力エラー
                          ,iv_token_name1  => cv_tkn_word        -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1       -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data        -- トークン(NG_DATA)
-- Ver1.3  2009/06/17  Mod 営業員番号の抽出誤りを修正
--                          ,iv_token_value2 => g_rs_data_tab(ln_loop_cnt).resource_number
                          ,iv_token_value2 => g_rs_data_tab(ln_loop_cnt).source_number
-- End1.3
                                                                 -- NG_WORDのDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          lv_sql_errm := SQLERRM;
          RAISE put_line_others_expt;
      END;
    END LOOP output_rs_data_loop;
    --
    gn_normal_cnt := g_rs_data_tab.COUNT;
-- End 1.2
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
-- Ver1.2  2009/06/08  Add  ファイル出力時のOTHERSでSQLERRMを出力するため追加
    WHEN put_line_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_sql_errm,1,5000);
      ov_retcode := cv_status_error;
-- End 1.2
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
  END output_csv;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
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
    gv_param_output_flg := '0';
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =====================================================
    --  初期処理プロシージャ(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  リソースマスタ情報取得プロシージャ(A-2)
    -- =====================================================
    get_rs_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSVファイル出力プロシージャ(A-4)
    -- =====================================================
    IF (gn_target_cnt > 0) THEN
      output_csv(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- =====================================================
    --  終了処理プロシージャ(A-5)
    -- =====================================================
    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);
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
   * Description      : コンカレント実行プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_date_from  IN  VARCHAR2,      --   2.有効開始日(開始)
    iv_date_to    IN  VARCHAR2       --   3.有効開始日(終了)
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
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
    -- 入力パラメータの取得
    -- ===============================================
    gv_update_sdate := iv_date_from;
    gv_update_edate := iv_date_to;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入(処理件数部の上)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 入力パラメータ出力後は、エラーメッセージとの間に空行挿入
      IF (gv_param_output_flg = '1') THEN
        -- 空行挿入(入力パラメータとエラーメッセージの間)
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
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
    -- 空行挿入(終了メッセージの上)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
    --
    --CSVファイルがクローズされていなかった場合、クローズする
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
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
END XXCMM002A06C;
/
