CREATE OR REPLACE PACKAGE BODY XXCMM006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A02C(body)
 * Description      : 管理マスタIF出力(HHT)
 * MD.050           : 管理マスタIF出力(HHT) MD050_CMM_006_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_tax_data           税コードマスタ情報取得プロシージャ(A-3)
 *  output_csv             CSVファイル出力プロシージャ(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/25    1.0   SCS 福間 貴子    初回作成
 *  2013/07/19    1.1   SCSK 渡辺良介    E_本稼動_10937 対応
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
  gn_normal_cnt    NUMBER;                    -- 成功件数
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM006A02C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_HHT_OUT_DIR';         -- HHTCSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A02_OUT_FILE';     -- 連携用CSVファイル名
  cv_cal_code               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A02_SYS_CAL_CODE'; -- システム稼働日カレンダコード値
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
  cv_tkn_cal_code           CONSTANT VARCHAR2(30)  := 'システム稼働日カレンダコード値';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := '消費税率';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
  cv_tkn_param              CONSTANT VARCHAR2(10)  := 'PARAM';                      -- パラメータ名
  cv_tkn_param1             CONSTANT VARCHAR2(20)  := '最終更新日(開始)';
  cv_tkn_param2             CONSTANT VARCHAR2(20)  := '最終更新日(終了)';
  cv_tkn_param3             CONSTANT VARCHAR2(20)  := '入力パラメータ';
  cv_tkn_value              CONSTANT VARCHAR2(10)  := 'VALUE';                      -- パラメータ値
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
  cv_msg_00020              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00020';           -- 課税売上(外税)のデータ無し
  cv_msg_00600              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00600';           -- 税率制限エラー
  cv_msg_00601              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00601';           -- 税率小数点制限エラー
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
  -- 固定値(設定値、抽出条件)
  cv_tax_flg                CONSTANT VARCHAR2(1)   := '0';                          -- 税フラグ
  cv_where_name             CONSTANT VARCHAR2(2)   := '21';                         -- 抽出対象レコード(課税売上(外税)のレコード)
  cv_on_flg                 CONSTANT VARCHAR2(1)   := 'Y';
  cv_off_flg                CONSTANT VARCHAR2(1)   := 'N';
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
  gn_new_tax                NUMBER(4,2);          -- 消費税率(新)
  gn_old_tax                NUMBER(4,2);          -- 消費税率(旧)
  gd_start_date             DATE;                 -- 変更日
  gd_last_update_date       DATE;                 -- 最終更新日
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gv_update_sdate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(開始)
  gv_update_edate           VARCHAR2(10);         -- 入力パラメータ：最終更新日(終了)
  gn_all_cnt                NUMBER;               -- 取得データ件数
  gv_warn_flg               VARCHAR2(1);          -- 警告フラグ
  gv_param_output_flg       VARCHAR2(1);          -- 入力パラメータ出力フラグ(出力前:0、出力後:1)
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_tax_data_cur
  IS
    SELECT   tax_rate,
-- 2013/07/19 v1.1 R.Watanabe Mod Start E_本稼動_10937
--             start_date,
             TO_DATE(attribute3,'YYYYMMDD') start_date,    --有効日（自）
-- 2013/07/19 v1.1 R.Watanabe Mod End E_本稼動_10937
             last_update_date
    FROM     ap_tax_codes_all
    WHERE    name LIKE cv_where_name || '%'
    AND      enabled_flag = cv_on_flg
-- 2013/07/19 v1.1 R.Watanabe Mod Start E_本稼動_10937
--    ORDER BY start_date DESC
    ORDER BY attribute3 DESC
-- 2013/07/19 v1.1 R.Watanabe Mod End E_本稼動_10937
  ;
  TYPE g_tax_data_ttype IS TABLE OF get_tax_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_tax_data            g_tax_data_ttype;
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
      gd_select_start_date := xxccp_common_pkg2.get_working_day(gd_process_date,-1,gv_cal_code) + 1;
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
   * Procedure Name   : get_tax_data
   * Description      : 税コードマスタ情報取得プロシージャ(A-3)
   ***********************************************************************************/
  PROCEDURE get_tax_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tax_data';       -- プログラム名
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
    OPEN get_tax_data_cur;
--
    -- データの一括取得
    FETCH get_tax_data_cur BULK COLLECT INTO gt_tax_data;
--
    -- 取得データ件数をセット
    gn_all_cnt := gt_tax_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_tax_data_cur;
--
    -- 処理対象となるデータが存在するかをチェック
    IF (gn_all_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                      ,iv_name         => cv_msg_00020           -- 課税売上(外税)のデータ無し
                     );
      lv_errbuf := lv_errmsg;
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
  END get_tax_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-5)
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
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
    ln_new_tax          NUMBER;                   -- 消費税率(新)
    ln_old_tax          NUMBER;                   -- 消費税率(旧)
    ld_start_date       DATE;                     -- 変更日
    ld_last_update_date DATE;                     -- 最終更新日
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
    -- =========================================================
    --  税コードマスタ情報抽出(A-4)
    -- =========================================================
    -- 消費税率新
    IF (gt_tax_data(1).tax_rate >= 100) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm             -- 'XXCMM'
                      ,iv_name         => cv_msg_00600               -- 税率制限エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    IF ((gt_tax_data(1).tax_rate - TRUNC(gt_tax_data(1).tax_rate * 100) / 100) > 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm             -- 'XXCMM'
                      ,iv_name         => cv_msg_00601               -- 税率小数点制限エラー
                      ,iv_token_name1  => cv_tkn_word                -- トークン(NG_WORD)
                      ,iv_token_value1 => cv_tkn_word1               -- NG_WORD
                      ,iv_token_name2  => cv_tkn_data                -- トークン(NG_DATA)
                      ,iv_token_value2 => gt_tax_data(1).tax_rate    -- NG_DATA
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    ln_new_tax := gt_tax_data(1).tax_rate;
    -- 消費税率旧
    IF (gn_all_cnt > 1) THEN
      IF (gt_tax_data(2).tax_rate >= 100) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00600             -- 税率制限エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      IF ((gt_tax_data(2).tax_rate - TRUNC(gt_tax_data(2).tax_rate * 100) / 100) > 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00601             -- 税率小数点制限エラー
                        ,iv_token_name1  => cv_tkn_word              -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1             -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data              -- トークン(NG_DATA)
                        ,iv_token_value2 => gt_tax_data(2).tax_rate  -- NG_DATA
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      ln_old_tax := gt_tax_data(2).tax_rate;
    END IF;
    ld_start_date := gt_tax_data(1).start_date;
    ld_last_update_date := gt_tax_data(1).last_update_date;
    -- =========================================================
    --  CSVファイル出力
    -- =========================================================
    lv_csv_text := ln_new_tax || cv_delimiter                                                -- 消費税率新
      || ln_old_tax || cv_delimiter                                                          -- 消費税率旧
      || TO_CHAR(ld_start_date,'YYYYMMDD') || cv_delimiter                                   -- 変更日
      || cv_enclosed || cv_tax_flg || cv_enclosed || cv_delimiter                            -- 税フラグ
      || cv_enclosed || TO_CHAR(ld_last_update_date,'YYYY/MM/DD HH24:MI:SS') || cv_enclosed  -- 更新日時
    ;
    BEGIN
      -- ファイル書き込み
      UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
    EXCEPTION
      -- ファイルアクセス権限エラー
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00007             -- ファイルアクセス権限エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      --
      -- CSVデータ出力エラー
      WHEN UTL_FILE.WRITE_ERROR THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                        ,iv_name         => cv_msg_00009             -- CSVデータ出力エラー
                        ,iv_token_name1  => cv_tkn_word              -- トークン(NG_WORD)
                        ,iv_token_value1 => cv_tkn_word1             -- NG_WORD
                        ,iv_token_name2  => cv_tkn_data              -- トークン(NG_DATA)
                        ,iv_token_value2 => gn_new_tax);             -- NG_DATA
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    -- 対象件数、成功件数を取得
    IF (gn_all_cnt > 1) THEN
      gn_target_cnt := 2;
      gn_normal_cnt := 2;
    ELSE
      gn_target_cnt := 1;
      gn_normal_cnt := 1;
    END IF;
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
    lc_flg     CHAR(1);         -- 対象データ存在フラグ
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
    --  対象データ存在チェック(A-2)
    -- =====================================================
    BEGIN
      -- 対象データ存在フラグをオン
      SELECT '1' INTO lc_flg
      FROM   ap_tax_codes_all
      WHERE  last_update_date >= gd_select_start_datetime
      AND    last_update_date <= gd_select_end_datetime
      AND    enabled_flag = cv_on_flg
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 対象データ存在フラグをオフ
        lc_flg := '0';
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- 対象データ存在フラグがオフの場合は、終了処理へ遷移
    IF (lc_flg = '1') THEN
      -- 対象データが存在した場合
      -- =====================================================
      --  税コードマスタ情報取得プロシージャ(A-3)
      -- =====================================================
      get_tax_data(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      -- =====================================================
      --  CSVファイル出力プロシージャ(A-5)
      -- =====================================================
      output_csv(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- =====================================================
    --  終了処理プロシージャ(A-6)
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
      -- 空行挿入(処理件数部の上)
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- 入力パラメータ出力後は、エラーメッセージとの間に空行挿入
      IF (gv_param_output_flg = '1') THEN
        -- 空行挿入(ログの入力パラメータの下)
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
END XXCMM006A02C;
/
