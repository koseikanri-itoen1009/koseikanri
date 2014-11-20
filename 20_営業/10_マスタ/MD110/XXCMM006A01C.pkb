CREATE OR REPLACE PACKAGE BODY XXCMM006A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A01C(body)
 * Description      : 倉庫マスタIF出力(HHT)
 * MD.050           : 倉庫マスタIF出力(HHT) MD050_CMM_006_A01
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_souko_data         保管場所マスタ情報取得プロシージャ(A-2)
 *  get_item_group_sum     商品別売上集計マスタ取得(A-5)
 *  output_csv             CSVファイル出力プロシージャ(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   SCS 福間 貴子    初回作成
 *  2013/05/15    1.1   SCSK 石渡 賢和   [E_本稼動_10735]対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM006A01C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';         -- HHTCSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A01_OUT_FILE';     -- 連携用CSVファイル名
  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A01_SYS_CAL_CODE'; -- システム稼働日カレンダコード値
/* 2013/05/15 Ver1.1 Add Start */
  -- 参照タイプ
  cv_item_group_summary     CONSTANT VARCHAR2(30)  := 'XXCMM1_ITEM_GROUP_SUMMARY';   -- 商品別売上集計マスタ
/* 2013/05/15 Ver1.1 Add End   */
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := 'システム稼働日カレンダコード値';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := '名称';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- パラメータ名
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '最終更新日(開始)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '最終更新日(終了)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '入力パラメータ';
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- パラメータ値
/* 2013/05/15 Ver1.1 Add Start */
  cv_tkn_input              CONSTANT VARCHAR2(10)  := 'INPUT';                      -- トークンINPUT
  cv_tkn_item               CONSTANT VARCHAR2(10)  := 'ITEM';                       -- トークンITEM
/* 2013/05/15 Ver1.1 Add End   */
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_00038              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00038';           -- 入力パラメータ出力メッセージ
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00035              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00035';           -- 前のシステム稼働日取得エラー
  cv_msg_00030              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00030';           -- 対象期間制限エラー
  cv_msg_00019              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00019';           -- 対象期間指定エラー
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
/* 2013/05/15 Ver1.1 Add Start */
  cv_msg_10318              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10318';           -- 全角チェック
  cv_msg_10114              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10114';           -- NUMBER型チェックエラー
  cv_msg_00602              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00602';           -- 目標管理項目コード
  cv_msg_00603              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00603';           -- 見出し・明細名称
  cv_target_rec_msg2        CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00604';           -- 商品別売上集計マスタ対象件数
  cv_success_rec_msg2       CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00605';           -- 商品別売上集計マスタ成功件数
  cv_skip_rec_msg2          CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00606';           -- スキップ件数メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';           -- 警告終了メッセージ
/* 2013/05/15 Ver1.1 Add End   */
  -- 固定値(設定値、抽出条件)
  cv_kbn_souko              CONSTANT VARCHAR2(1)   := '1';                          -- 保管場所区分(倉庫)
/* 2013/05/15 Ver1.1 Add Start */
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';                          -- フラグ「Y」
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';                          -- フラグ「N」
/* 2013/05/15 Ver1.1 Add End   */
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
  gv_cal_code               VARCHAR2(30);         -- システム稼働日カレンダコード値
  gd_process_date           DATE;                 -- 業務日付
  gd_select_start_date      DATE;                 -- 取得開始日
  gd_select_start_datetime  DATE;                 -- 取得開始日(時刻 00:00:00)
  gd_select_end_date        DATE;                 -- 取得終了日
  gd_select_end_datetime    DATE;                 -- 取得終了日(時刻 23:59:59)
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gv_update_sdate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(開始)
  gv_update_edate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(終了)
  gv_param_output_flg       VARCHAR2(1);          -- 入力パラメータ出力フラグ(出力前:0、出力後:1)
/* 2013/05/15 Ver1.1 Add Start */
  gn_warn_cnt               NUMBER;               -- スキップ件数
  gn_target_cnt2            NUMBER;               -- 対象件数(商品別売上集計マスタ)
  gn_normal_cnt2            NUMBER;               -- 正常件数(商品別売上集計マスタ)
  gd_min_start_date         DATE;                 -- 最小有効開始日
  gd_max_end_date           DATE;                 -- 最大有効終了日
/* 2013/05/15 Ver1.1 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_souko_data_cur
  IS
    SELECT   SUBSTRB(secondary_inventory_name,1,10) AS name,
             SUBSTRB(description,1,20) AS description,
             NVL(TO_CHAR(disable_date,'YYYYMMDD'),0) AS disable_date,
             TO_CHAR(last_update_date,'YYYY/MM/DD HH24:MI:SS') AS last_update_date
    FROM     mtl_secondary_inventories
    WHERE    attribute1 = cv_kbn_souko
    AND      last_update_date >= gd_select_start_datetime
    AND      last_update_date <= gd_select_end_datetime
  ;
  TYPE g_souko_data_ttype IS TABLE OF get_souko_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_souko_data            g_souko_data_ttype;
/* 2013/05/15 Ver1.1 Add Start */
  CURSOR get_item_group_sum_cur
  IS
    SELECT   SUBSTRB(flv.lookup_code,1,9)                       AS sales_target_sum_code, -- 目標管理項目コード
             SUBSTRB(TO_MULTI_BYTE(flv.description),1,20)       AS description,           -- 見出し・明細名称(マルチバイト変換済み)
             NULL                                               AS disable_date,          -- 適用開始日
             TO_CHAR(flv.last_update_date,'YYYY/MM/DD HH24:MI:SS')  AS last_update_date   -- ファイル作成日
    FROM     fnd_lookup_values flv
    WHERE    flv.lookup_type        = cv_item_group_summary                               -- 商品別売上集計マスタ
    AND      flv.language           = userenv('LANG')                                     -- 有効なもののみ
    AND      flv.enabled_flag       = cv_y                                                -- 有効なもののみ
    AND      flv.attribute3        <> cv_n                                                -- 出力対象外は除く
  ;
  TYPE g_item_group_sum_ttype IS TABLE OF get_item_group_sum_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_item_group_sum       g_item_group_sum_ttype;
/* 2013/05/15 Ver1.1 Add End   */
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
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- =========================================================
    -- 入力パラメータの最終更新日(開始)に値がセットされなかった場合は、
    -- プロファイル(システム稼働日カレンダのカレンダコード値)を取得
    -- =========================================================
    IF (gv_update_sdate IS NULL) THEN
      gv_cal_code := fnd_profile.value(cv_cal_code);
      IF (gv_cal_code IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                        ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                        ,iv_token_value1 => cv_tkn_cal_code      -- プロファイル名(システム稼働日カレンダコード値)
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    -- =========================================================
    --  取得開始日、取得終了日の取得
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
    -- 取得開始日の取得
    IF (gv_update_sdate IS NULL) THEN
      -- 業務日付の前のシステム稼働日の次の日をセット
      gd_select_start_date := xxccp_common_pkg2.get_working_day(gd_process_date,-1,gv_cal_code)+1;
      IF (gd_select_start_date IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                        ,iv_name         => cv_msg_00035         -- 前のシステム稼働日取得エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      -- 最終更新日(開始)をセット
      gd_select_start_date := TO_DATE(gv_update_sdate,'YYYY/MM/DD');

    END IF;
    -- 取得終了日の取得
    IF (gv_update_edate IS NULL) THEN
      -- 業務日付をセット
      gd_select_end_date := gd_process_date;
    ELSE
      -- 最終更新日(終了)をセット
      gd_select_end_date := TO_DATE(gv_update_edate,'YYYY/MM/DD');
    END IF;
    -- 検索条件用に時刻をセット
    gd_select_start_datetime := TO_DATE(TO_CHAR(gd_select_start_date,'YYYY/MM/DD') || ' 00:00:00','YYYY/MM/DD HH24:MI:SS');
    gd_select_end_datetime := TO_DATE(TO_CHAR(gd_select_end_date,'YYYY/MM/DD') || ' 23:59:59','YYYY/MM/DD HH24:MI:SS');
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
    -- 空行挿入
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
    IF (gd_select_start_date > gd_process_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    IF (gd_select_end_date > gd_process_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00030           -- 対象期間制限エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
    -- 空行挿入
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
   * Procedure Name   : get_souko_data
   * Description      : 保管場所マスタ情報取得プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE get_souko_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_souko_data';       -- プログラム名
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
   -- カーソルオープン
    OPEN get_souko_data_cur;
--
    -- データの一括取得
    FETCH get_souko_data_cur BULK COLLECT INTO gt_souko_data;
--
    -- 対象件数をセット
    gn_target_cnt := gt_souko_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_souko_data_cur;
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
  END get_souko_data;
/* 2013/05/15 Ver1.1 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : get_item_group_sum
   * Description      : 商品別売上集計マスタ取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_item_group_sum(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_group_sum';       -- プログラム名
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
    cv_paren1           CONSTANT VARCHAR2(2)  := '( ';    -- 左カッコ
    cv_paren2           CONSTANT VARCHAR2(2)  := ' )';    -- 右カッコ
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                          -- ループカウンタ
    lv_err_flg          VARCHAR2(1);                     -- エラーフラグ
    lv_msg_00602        VARCHAR2(150);                   -- メッセージ文言格納変数
    lv_msg_00603        VARCHAR2(150);                   -- メッセージ文言格納変数
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
    -- エラーフラグ初期化
    lv_err_flg  := '0';
    --
    --==============================================================
    -- 1. 商品別売上集計マスタ情報の取得
    --==============================================================
    -- カーソルオープン
    OPEN get_item_group_sum_cur;
--
    -- データの一括取得
    FETCH get_item_group_sum_cur BULK COLLECT INTO gt_item_group_sum;
--
    -- 対象件数をセット
    gn_target_cnt2 := gt_item_group_sum.COUNT;
--
    -- カーソルクローズ
    CLOSE get_item_group_sum_cur;
--
    IF( gn_target_cnt2 > 0 ) THEN
      --==============================================================
      -- 2. 項目の型チェック
      --==============================================================
      --
      <<chk_loop>>
      FOR ln_loop_cnt IN gt_item_group_sum.FIRST..gt_item_group_sum.LAST LOOP
        -- (1) 目標管理項目コード
        IF( xxccp_common_pkg.chk_number( gt_item_group_sum(ln_loop_cnt).sales_target_sum_code ) = FALSE )
        THEN
          --固定文字抽出
          lv_msg_00602 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                          ,iv_name         => cv_msg_00602           -- 入力パラメータ出力メッセージ
                         );
          --エラーメッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                          ,iv_name         => cv_msg_10114           -- 入力パラメータ出力メッセージ
                          ,iv_token_name1  => cv_tkn_item            -- トークン(ITEM)
                          ,iv_token_value1 => lv_msg_00602 || cv_paren1
                                              || gt_item_group_sum(ln_loop_cnt).sales_target_sum_code || cv_paren2
                         );
          IF ( gn_warn_cnt = 0 ) THEN
            -- 空行挿入
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff => ''
            );
          END IF;
          --エラー出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff => lv_errmsg --エラーメッセージ
          );
          -- エラーフラグ更新
          lv_err_flg := '1';
          -- スキップ件数カウントアップ
          gn_warn_cnt := gn_warn_cnt + 1;
          --
        END IF;
        --
        -- (2) 見出し・明細名称
        IF( xxccp_common_pkg.chk_double_byte( gt_item_group_sum(ln_loop_cnt).description ) = FALSE )
        THEN
          --固定文字抽出
          lv_msg_00603 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                          ,iv_name         => cv_msg_00603           -- 入力パラメータ出力メッセージ
                         );
          --エラーメッセージ生成
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                          ,iv_name         => cv_msg_10318           -- 入力パラメータ出力メッセージ
                          ,iv_token_name1  => cv_tkn_input            -- トークン(INPUT)
                          ,iv_token_value1 => lv_msg_00603 || cv_paren1
                                              || gt_item_group_sum(ln_loop_cnt).description || cv_paren2
                         );
          IF ( gn_warn_cnt = 0 ) THEN
            -- 空行挿入
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff => ''
            );
          END IF;
          --エラー出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff => lv_errmsg --エラーメッセージ
          );
          -- エラーフラグ更新
          lv_err_flg := '1';
          -- スキップ件数カウントアップ
          gn_warn_cnt := gn_warn_cnt + 1;
          --
        END IF;
      END LOOP chk_loop;
    END IF;
    --
    --==============================================================
    -- 3. エラー時配列初期化
    --==============================================================
    IF( lv_err_flg = '1' ) THEN
      gt_item_group_sum.delete;
      ov_retcode   := cv_status_warn;
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
  END get_item_group_sum;
/* 2013/05/15 Ver1.1 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-3)
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
/* 2013/05/15 Ver1.1 Add Start */
    IF (gn_target_cnt > 0) THEN
/* 2013/05/15 Ver1.1 Add End */
    <<out_loop>>
    FOR ln_loop_cnt IN gt_souko_data.FIRST..gt_souko_data.LAST LOOP
      lv_csv_text := cv_enclosed || gt_souko_data(ln_loop_cnt).name || cv_enclosed || cv_delimiter    -- 保管場所コード
        || cv_enclosed || gt_souko_data(ln_loop_cnt).description || cv_enclosed || cv_delimiter       -- 保管場所名
        || gt_souko_data(ln_loop_cnt).disable_date || cv_delimiter                                    -- 無効日
        || cv_enclosed || gt_souko_data(ln_loop_cnt).last_update_date || cv_enclosed                  -- 更新日時
      ;
      BEGIN
        -- ファイル書き込み
        UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
      EXCEPTION
        -- ファイルアクセス権限エラー
        WHEN UTL_FILE.INVALID_OPERATION THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                          ,iv_name         => cv_msg_00007                           -- ファイルアクセス権限エラー
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        --
        -- CSVデータ出力エラー
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                          ,iv_name         => cv_msg_00009                           -- CSVデータ出力エラー
                          ,iv_token_name1  => cv_tkn_word                            -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD
                          ,iv_token_name2  => cv_tkn_data                            -- トークン(NG_DATA)
                          ,iv_token_value2 => gt_souko_data(ln_loop_cnt).name        -- NG_WORDのDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      --
      -- 処理件数のカウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP out_loop;
/* 2013/05/15 Ver1.1 Add Start */
    END IF;
/* 2013/05/15 Ver1.1 Add End */
/* 2013/05/15 Ver1.1 Add Start */
    IF ( gt_item_group_sum.COUNT > 0 ) THEN
      <<out_loop2>>
      FOR ln_loop_cnt IN gt_item_group_sum.FIRST..gt_item_group_sum.LAST LOOP
        lv_csv_text
          := cv_enclosed || gt_item_group_sum(ln_loop_cnt).sales_target_sum_code || cv_enclosed || cv_delimiter    -- 目標管理項目コード
          || cv_enclosed || gt_item_group_sum(ln_loop_cnt).description           || cv_enclosed || cv_delimiter    -- 見出し・明細名称
          || gt_item_group_sum(ln_loop_cnt).disable_date                                        || cv_delimiter    -- 無効日
          || cv_enclosed || gt_item_group_sum(ln_loop_cnt).last_update_date      || cv_enclosed                    -- 更新日時
        ;
        BEGIN
          -- ファイル書き込み
          UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
        EXCEPTION
          -- ファイルアクセス権限エラー
          WHEN UTL_FILE.INVALID_OPERATION THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00007                           -- ファイルアクセス権限エラー
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          --
          -- CSVデータ出力エラー
          WHEN UTL_FILE.WRITE_ERROR THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00009                           -- CSVデータ出力エラー
                            ,iv_token_name1  => cv_tkn_word                            -- トークン(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD
                            ,iv_token_name2  => cv_tkn_data                            -- トークン(NG_DATA)
                            ,iv_token_value2 => gt_item_group_sum(ln_loop_cnt).sales_target_sum_code        -- NG_WORDのDATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        --
        -- 処理件数のカウント
        gn_normal_cnt2 := gn_normal_cnt2 + 1;
      END LOOP out_loop2;
    END IF;
/* 2013/05/15 Ver1.1 Add End   */
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
/* 2013/05/15 Ver1.1 Add Start */
    gn_warn_cnt    := 0;
    gn_target_cnt2 := 0;
    gn_normal_cnt2 := 0;
/* 2013/05/15 Ver1.1 Add End   */
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
    --  保管場所マスタ情報取得プロシージャ(A-2)
    -- =====================================================
    get_souko_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
/* 2013/05/15 Ver1.1 Add Start */
    -- =====================================================
    --  商品別売上集計マスタ取得(A-5)
    -- =====================================================
    get_item_group_sum(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_warn ) THEN
       ov_errbuf   :=  lv_errbuf;
       ov_retcode  :=  lv_retcode;
       ov_errmsg   :=  lv_errmsg;
    END IF;
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
/* 2013/05/15 Ver1.1 Add End   */
    -- =====================================================
    --  CSVファイル出力プロシージャ(A-3)
    -- =====================================================
/* 2013/05/15 Ver1.1 Mod Start */
--    IF (gn_target_cnt > 0) THEN
    IF ((gn_target_cnt > 0) OR (gt_item_group_sum.COUNT > 0)) THEN
/* 2013/05/15 Ver1.1 Mod End   */
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
    --  終了処理プロシージャ(A-4)
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
    iv_date_from  IN  VARCHAR2,      --   1.最終更新日(開始)
    iv_date_to    IN  VARCHAR2       --   2.最終更新日(終了)
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
      lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 入力パラメータ出力後は、エラーメッセージとの間に空行挿入
      IF (gv_param_output_flg = '1') THEN
        -- 空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
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
/* 2013/05/15 Ver1.1 Add Start */
    ELSIF( lv_retcode = cv_status_warn ) THEN
      --警告の場合、メッセージのあとに１行加える
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
/* 2013/05/15 Ver1.1 Add End   */
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
/* 2013/05/15 Ver1.1 Add Start */
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm
                    ,iv_name         => cv_target_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt2)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm
                    ,iv_name         => cv_success_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt2)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cmm
                    ,iv_name         => cv_skip_rec_msg2
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2013/05/15 Ver1.1 Add End   */
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
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
/* 2013/05/15 Ver1.1 Add Start */
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
/* 2013/05/15 Ver1.1 Add End   */
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
END XXCMM006A01C;
/
