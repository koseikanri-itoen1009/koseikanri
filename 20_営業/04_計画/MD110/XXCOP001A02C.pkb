CREATE OR REPLACE PACKAGE BODY XXCOP001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A02C(body)
 * Description      : 基準計画の取込
 * MD.050           : 基準計画の取込 MD050_COP_001_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_xmsi            基準計画I/F表(アドオン)データ削除(A-7)
 *  delete_msi             基準計画OIFデータ削除(A-6)
 *  judge_msi              登録確認処理(A-5)
 *  entry_msi              基準計画登録処理(A-4)
 *  entry_msii             品目属性更新処理(A-3)
 *  get_xmsi               対象データ抽出(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   Y.Goto           新規作成
 *  2009/08/21    1.1   S.Moriyama       0001134対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  format_ptn_validate_expt  EXCEPTION;     -- アップロード名称取得エラー
  profile_validate_expt     EXCEPTION;     -- プロファイル妥当性エラー
  resource_busy_expt        EXCEPTION;     -- デッドロックエラー
  lower_rows_expt           EXCEPTION;     -- データなし例外
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP001A02C';           -- パッケージ名
  --メッセージ共通
  gv_msg_appl_cont          CONSTANT VARCHAR2(100) := 'XXCOP';                  -- アプリケーション短縮名
  --言語
  gv_lang                   CONSTANT VARCHAR2(100) := USERENV('LANG');
  --プログラム実行年月日
  gd_sysdate                CONSTANT DATE := TRUNC(SYSDATE);                    -- システム日付（年月日）
  --メッセージ名
  gv_msg_00002              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- プロファイル値取得失敗
  gv_msg_00003              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';       -- 対象データなし
  gv_msg_00005              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';       -- パラメータエラーメッセージ
  gv_msg_00007              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';       -- テーブルロックエラーメッセージ
  gv_msg_00026              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00026';       -- 登録処理タイムアウトエラーメッセージ
  gv_msg_00027              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00027';       -- 登録処理エラーメッセージ
  gv_msg_00031              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00031';       -- アップロードＩＦデータ削除エラーメッセージ
  gv_msg_00036              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';       -- アップロードファイル出力メッセージ
  gv_msg_00042              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00042';       -- 削除処理エラーメッセージ
  gv_msg_10011              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10011';       -- 更新処理エラー
  gv_msg_10012              CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10012';       -- コンカレント発行エラー
  --メッセージトークン
  gv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_msg_00005_token_1      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_msg_00005_token_2      CONSTANT VARCHAR2(100) := 'VALUE';
  gv_msg_00007_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00026_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00027_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00031_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00031_token_2      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_1      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_2      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_msg_00036_token_3      CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_msg_00036_token_4      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00042_token_1      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_10011_token_1      CONSTANT VARCHAR2(100) := 'REQUEST_ID';
  gv_msg_10011_token_2      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_10012_token_1      CONSTANT VARCHAR2(100) := 'SYORI';
  --メッセージトークン値
  gv_msg_table_msib         CONSTANT VARCHAR2(100) := '品目マスタ';              --
  gv_msg_table_mism         CONSTANT VARCHAR2(100) := '品目OIF';                 --
  gv_msg_table_msi          CONSTANT VARCHAR2(100) := '基準計画OIF';             --
  gv_msg_table_xmsi         CONSTANT VARCHAR2(100) := '基準計画I/Fテーブル';     --
  gv_msg_conc_incoin        CONSTANT VARCHAR2(100) := '品目インポート';          --
  gv_msg_conc_msi           CONSTANT VARCHAR2(100) := '基準計画';                --
  gv_msg_param_format       CONSTANT VARCHAR2(100) := 'フォーマットパターン';    --
  --プロファイル
  gv_profile_baseline       CONSTANT VARCHAR2(100) := 'XXCOP1_SCHEDULE_BASELINE';--確定日基準日数
  gv_profile_name_baseline  CONSTANT VARCHAR2(100) := 'XXCOP：確定日基準日数';   --確定日基準日数
  gv_profile_timeout        CONSTANT VARCHAR2(100) := 'XXCOP1_CONC_TIMEOUT';     --タイムアウト時間
  gv_profile_name_timeout   CONSTANT VARCHAR2(100) := 'XXCOP：タイムアウト時間'; --タイムアウト時間
  gv_profile_interval       CONSTANT VARCHAR2(100) := 'XXCOP1_CONC_INTERVAL';    --処理間隔
  gv_profile_name_interval  CONSTANT VARCHAR2(100) := 'XXCOP：処理間隔';         --処理間隔
  gv_profile_master_org_id  CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';     --マスタ組織ID
--★
  gv_profile_name_m_org_id  CONSTANT VARCHAR2(100) := 'XXCMN:マスタ組織';        --マスタ組織ID
--★
  --日付型フォーマット
  gv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';              -- 年月日
  --クイックコードタイプ
  gv_lookup_type            CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';  -- ファイルアップロードオブジェクト
  gv_enable                 CONSTANT VARCHAR2(100) := 'Y';                       -- 有効
  --計画マネージャ処理ステータス
  gn_status_wait            CONSTANT NUMBER        := 2;                         -- Waiting to be processed
  gn_status_processing      CONSTANT NUMBER        := 3;                         -- Being processed
  gn_status_error           CONSTANT NUMBER        := 4;                         -- Error
  gn_status_processed       CONSTANT NUMBER        := 5;                         -- Processed
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_lock_column_ttype  IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;           -- 行No
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_fixed_baseline         NUMBER;
  gn_conc_interval          NUMBER;
  gn_conc_timeout           NUMBER;
--★
  gn_master_org_id          NUMBER;
--★
  gv_debug_mode             VARCHAR2(256);
--
  /**********************************************************************************
   * Procedure Name   : delete_xmsi
   * Description      : 基準計画I/F表(アドオン)データ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xmsi(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_xmsi'; -- プログラム名
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
    l_row_no_tab              g_lock_column_ttype;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --基準計画I/F表のロック取得
      SELECT xmsi.row_no
      BULK COLLECT INTO l_row_no_tab
      FROM  xxcop_mrp_schedule_interface xmsi
      WHERE xmsi.file_id = in_file_id
      FOR UPDATE OF xmsi.row_no NOWAIT;
--
      --基準計画I/F表削除
      DELETE xxcop_mrp_schedule_interface xmsi
      WHERE  xmsi.file_id = in_file_id;
    EXCEPTION
      WHEN resource_busy_expt THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00007
                              ,iv_token_name1  => gv_msg_00007_token_1
                              ,iv_token_value1 => gv_msg_table_xmsi
                              );
        RAISE global_api_expt;
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00031
                              ,iv_token_name1  => gv_msg_00031_token_1
                              ,iv_token_value1 => gv_msg_table_xmsi
                              ,iv_token_name2  => gv_msg_00031_token_2
                              ,iv_token_value3 => in_file_id
                              );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_xmsi;
--
  /**********************************************************************************
   * Procedure Name   : delete_msi
   * Description      : 基準計画OIFデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE delete_msi(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_msi'; -- プログラム名
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
    l_file_id_tab          g_lock_column_ttype;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --基準計画OIFのロック取得
      SELECT msi.attribute4  file_id
      BULK COLLECT INTO l_file_id_tab
      FROM  mrp_schedule_interface msi
      WHERE msi.attribute4 = in_file_id
      FOR UPDATE OF msi.attribute4 NOWAIT;
--
      --基準計画OIF削除
      DELETE mrp_schedule_interface msi
      WHERE msi.process_status = gn_status_processed
        AND msi.attribute4     = in_file_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN resource_busy_expt THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00007
                              ,iv_token_name1  => gv_msg_00007_token_1
                              ,iv_token_value1 => gv_msg_table_msi
                              );
        RAISE global_api_expt;
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_00042
                              ,iv_token_name1  => gv_msg_00042_token_1
                              ,iv_token_value1 => gv_msg_table_msi
                              );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_msi;
--
  /**********************************************************************************
   * Procedure Name   : judge_msi
   * Description      : 登録確認処理(A-5)
   ***********************************************************************************/
  PROCEDURE judge_msi(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'judge_msi'; -- プログラム名
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
    ln_wait_cnt               NUMBER;                                              -- 未処理件数
    ln_processing_cnt         NUMBER;                                              -- 処理中件数
    ln_error_cnt              NUMBER;                                              -- エラー件数
    ln_processed_cnt          NUMBER;                                              -- 正常件数
    ln_entry_cnt              NUMBER;                                              -- OIF登録件数
    ld_init_time              NUMBER;                                              -- コンカレント起動時間
    lv_timeout                VARCHAR2(1);                                         -- タイムアウト判定
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
      lv_timeout := gv_status_error;
    IF ( gn_conc_timeout > 0 ) THEN
      --処理開始時間を取得
      ld_init_time := dbms_utility.get_time;
    END IF;
    <<waiting_loop>>
    LOOP
      --基準計画OIFの処理ステータスを確認
      SELECT SUM( DECODE( process_status, gn_status_wait      , 1, 0 ) ) wait_cnt
            ,SUM( DECODE( process_status, gn_status_processing, 1, 0 ) ) processing_cnt
            ,SUM( DECODE( process_status, gn_status_error     , 1, 0 ) ) error_cnt
            ,SUM( DECODE( process_status, gn_status_processed , 1, 0 ) ) processed_cnt
            ,COUNT('X')                                                  entry_cnt
      INTO   ln_wait_cnt
            ,ln_processing_cnt
            ,ln_error_cnt
            ,ln_processed_cnt
            ,ln_entry_cnt
      FROM  mrp_schedule_interface msi
      WHERE msi.attribute4 = in_file_id;
--
      --計画マネージャの終了判定
      IF ( ( ln_error_cnt + ln_processed_cnt ) = ln_entry_cnt ) THEN
        lv_timeout := gv_status_normal;
        EXIT waiting_loop;
      END IF;
      --タイムアウト時間の終了判定
      IF ( (( dbms_utility.get_time - ld_init_time ) / 100 ) > gn_conc_timeout ) THEN
        EXIT waiting_loop;
      END IF;
      --処理間隔秒の間待機
      dbms_lock.sleep( gn_conc_interval );
    END LOOP waiting_loop;
--
    --タイムアウトの判定
    IF ( lv_timeout = gv_status_error ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => gv_msg_appl_cont
                            ,iv_name         => gv_msg_00026
                            ,iv_token_name1  => gv_msg_00026_token_1
                            ,iv_token_value1 => gv_msg_conc_msi
                            );
      RAISE global_api_expt;
    END IF;
    --処理件数の判定
    IF ( ln_processed_cnt <> ln_entry_cnt ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                             iv_application  => gv_msg_appl_cont
                            ,iv_name         => gv_msg_00027
                            ,iv_token_name1  => gv_msg_00027_token_1
                            ,iv_token_value1 => gv_msg_conc_msi
                            );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END judge_msi;
--
  /**********************************************************************************
   * Procedure Name   : entry_msi
   * Description      : 基準計画登録処理(A-4)
   ***********************************************************************************/
  PROCEDURE entry_msi(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_msi'; -- プログラム名
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
    --計画オープンインターフェーステーブル定数
    cn_schedule_level         CONSTANT NUMBER        := 2;                         --
    cv_insert_action          CONSTANT VARCHAR2(1)   := 'I';                       -- 追加
    cv_delete_action          CONSTANT VARCHAR2(1)   := 'D';                       -- 削除
    cv_update_action          CONSTANT VARCHAR2(1)   := 'U';                       -- 更新
--
    -- *** ローカル変数 ***
    ln_target_cnt             NUMBER;          -- 対象件数
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --データインサート
      INSERT INTO mrp_schedule_interface (
         inventory_item_id
        ,schedule_designator
        ,organization_id
        ,last_update_date
        ,last_updated_by
        ,creation_date
        ,created_by
        ,last_update_login
        ,schedule_date
        ,schedule_quantity
        ,transaction_id
        ,process_status
        ,program_application_id
        ,program_id
        ,program_update_date
        ,attribute1
        ,attribute2
        ,attribute3
        ,attribute4
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
        ,attribute5
        ,attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
        ,action
      )
      SELECT inventory_item_id                 inventory_item_id
            ,schedule_designator               schedule_designator
            ,organization_id                   organization_id
            ,gd_last_update_date               last_update_date
            ,gn_last_updated_by                last_updated_by
            ,gd_creation_date                  creation_date
            ,gn_created_by                     created_by
            ,gn_last_update_login              last_update_login
            ,schedule_date                     schedule_date
            ,schedule_quantity                 schedule_quantity
            ,transaction_id                    transaction_id
            ,gn_status_wait                    process_status
            ,gn_program_application_id         program_application_id
            ,gn_program_id                     program_id
            ,gd_program_update_date            program_update_date
            ,attribute1                        attribute1
            ,attribute2                        attribute2
            ,attribute3                        attribute3
            ,in_file_id                        attribute4
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
            ,attribute5                        attribute5
            ,attribute6                        attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
            ,action                            action
      FROM (
        WITH xmsi_vw AS (
          SELECT xmsi.row_no                   row_no
                ,xmsi.schedule_designator      schedule_designator
                ,xmsi.item_code                item_code
                ,xmsi.schedule_date            schedule_date
                ,xmsi.schedule_quantity        schedule_quantity
                ,msib.inventory_item_id        inventory_item_id
                ,mp.organization_id            organization_id
                ,xmsi.schedule_prod_flg        schedule_prod_flg
                ,xmsi.deliver_from             deliver_from
                ,xmsi.shipment_date            shipment_date
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
                ,xmsi.schedule_type            schedule_type
                ,xmsi.schedule_prod_date       schedule_prod_date
                ,xmsi.prod_purchase_flg        prod_purchase_flg
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
          FROM   xxcop_mrp_schedule_interface  xmsi
                ,mrp_schedule_designators      msd
                ,mtl_system_items_b            msib
                ,mtl_parameters                mp
          WHERE msd.schedule_designator      = xmsi.schedule_designator
            AND msd.organization_id          = mp.organization_id
            AND msib.segment1                = xmsi.item_code
            AND msib.organization_id         = mp.organization_id
            AND mp.organization_code         = xmsi.organization_code
            AND xmsi.file_id                 = in_file_id
        )
        , msds_vw AS (
          SELECT msds.inventory_item_id        inventory_item_id
                ,msds.schedule_designator      schedule_designator
                ,msds.organization_id          organization_id
                ,msds.schedule_date            schedule_date
                ,msds.schedule_quantity        schedule_quantity
                ,msds.mps_transaction_id       mps_transaction_id
                --★↓2009/01/21 追加
                ,msds.attribute2               deliver_from
                --★↑2009/01/21 追加
          FROM   mrp_schedule_dates            msds
          WHERE msds.schedule_date           > gd_sysdate + gn_fixed_baseline
            AND msds.schedule_level          = cn_schedule_level
            AND EXISTS (
              SELECT 'x'
              FROM   xmsi_vw                   xmsiv
              WHERE msds.schedule_designator = xmsiv.schedule_designator
--20090821_Ver1.1_0001134_SCS.Moriyama_MOD_START
--                AND msds.organization_id     = xmsiv.organization_id
--                AND msds.inventory_item_id   = xmsiv.inventory_item_id
--                --★↓2009/01/21 追加
--                AND ( ( msds.attribute2 IS NULL AND xmsiv.deliver_from IS NULL)
--                   OR ( msds.attribute2 = xmsiv.deliver_from ) )
--                --★↑2009/01/21 追加
--                AND msds.inventory_item_id   = xmsiv.inventory_item_id
                AND(( xmsiv.schedule_type = 2
                    AND msds.attribute2 = xmsiv.deliver_from)
                OR  (xmsiv.schedule_type != 2
                    AND msds.organization_id = xmsiv.organization_id )
                )
--20090821_Ver1.1_0001134_SCS.Moriyama_MOD_END
            )
        )
        SELECT NVL( xmsiv.inventory_item_id  , msdsv.inventory_item_id )   inventory_item_id
              ,NVL( xmsiv.schedule_designator, msdsv.schedule_designator ) schedule_designator
              ,NVL( xmsiv.organization_id    , msdsv.organization_id )     organization_id
              ,NVL( xmsiv.schedule_date      , msdsv.schedule_date )       schedule_date
              ,NVL( xmsiv.schedule_quantity  , msdsv.schedule_quantity )   schedule_quantity
              ,msdsv.mps_transaction_id                                    transaction_id
              ,xmsiv.schedule_prod_flg                                     attribute1
              ,xmsiv.deliver_from                                          attribute2
              ,TO_CHAR( xmsiv.shipment_date  , gv_date_format )            attribute3
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_START
              ,TO_CHAR( xmsiv.schedule_prod_date , gv_date_format )        attribute5
              ,xmsiv.prod_purchase_flg                                     attribute6
--20090821_Ver1.1_0001134_SCS.Moriyama_ADD_END
              ,CASE
                  WHEN msdsv.mps_transaction_id IS NULL THEN cv_insert_action
                  WHEN xmsiv.row_no IS NULL THEN cv_delete_action
                  ELSE cv_update_action
               END                                                         action
        FROM   msds_vw msdsv
                  FULL OUTER JOIN xmsi_vw xmsiv
                ON (  xmsiv.schedule_designator  = msdsv.schedule_designator
                  AND xmsiv.organization_id      = msdsv.organization_id
                  AND xmsiv.inventory_item_id    = msdsv.inventory_item_id
                  AND xmsiv.schedule_date        = msdsv.schedule_date
                  --★↓2009/01/21 追加
                  AND xmsiv.deliver_from         = msdsv.deliver_from
                  --★↑2009/01/21 追加
                )
      );
      ln_target_cnt := SQL%ROWCOUNT;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '基準計画OIF  データ件数：' || ln_target_cnt
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00027
                             ,iv_token_name1  => gv_msg_00027_token_1
                             ,iv_token_value1 => gv_msg_table_msi
                             );
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        RAISE global_api_expt;
    END;
    --計画マネージャ起動のためコミット
    COMMIT;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_msi;
--
  /**********************************************************************************
   * Procedure Name   : entry_msii
   * Description      : 品目属性更新処理(A-3)
   ***********************************************************************************/
  PROCEDURE entry_msii(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_msii'; -- プログラム名
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
    --品目インポートテーブル定数
    cn_msii_process_flag      CONSTANT NUMBER        := 1;                         -- Pending
    cv_msii_transaction_type  CONSTANT VARCHAR2(6)   := 'UPDATE';                  -- 更新
    cn_mrp_planning_code      CONSTANT NUMBER        := 8;                         -- MPS/MPP計画
    --品目インポートコンカレント定数
    cv_application            CONSTANT VARCHAR2(3)   := 'INV';                     --
    cv_program                CONSTANT VARCHAR2(6)   := 'INCOIN';                  -- 品目インポート
    cn_all_org_flag           CONSTANT NUMBER        := 1;                         -- 全組織
    cn_validate_flag          CONSTANT NUMBER        := 1;                         -- 品目の検証    :YES
    cn_process_flag           CONSTANT NUMBER        := 1;                         -- 品目処理      :YES
    cn_delete_flag            CONSTANT NUMBER        := 1;                         -- 処理済行の削除:YES
    cn_action_type            CONSTANT NUMBER        := 2;                         -- 更新
    --コンカレント要求待機定数
    cv_complete_phase         CONSTANT VARCHAR2(8)   := 'COMPLETE';                -- 完了
    cv_successful_status      CONSTANT VARCHAR2(8)   := 'NORMAL';                  -- 正常
--
    -- *** ローカル変数 ***
    ln_target_cnt             NUMBER;          -- 対象件数
    ln_process_set            NUMBER;          -- 処理セット
    ln_request_id             NUMBER;          -- 品目インポート要求ID
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  fnd_lookups.meaning%TYPE;
    lv_status                 fnd_lookups.meaning%TYPE;
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                fnd_concurrent_requests.completion_text%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    BEGIN
      --処理セットの取得
      SELECT xxcop_item_import_row_no_s1.NEXTVAL
      INTO   ln_process_set
      FROM DUAL;
      --データインサート
      INSERT INTO mtl_system_items_interface (
         inventory_item_id
        ,organization_id
        ,process_flag
        ,transaction_type
        ,transaction_id
        ,set_process_id
        ,mrp_planning_code
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )
      SELECT msib.inventory_item_id        inventory_item_id
            ,msib.organization_id          organization_id
            ,cn_msii_process_flag          process_flag
            ,cv_msii_transaction_type      transaction_type
            ,NULL                          transaction_id
            ,ln_process_set                set_process_id
            ,cn_mrp_planning_code          mrp_planning_code
            ,gn_last_updated_by            last_updated_by
            ,gd_last_update_date           last_update_date
            ,gn_last_update_login          last_update_login
            ,gn_request_id                 request_id
            ,gn_program_application_id     program_application_id
            ,gn_program_id                 program_id
            ,gd_program_update_date        program_update_date
      FROM   mtl_system_items_b            msib
      WHERE msib.mrp_planning_code      <> cn_mrp_planning_code
        AND EXISTS (
          SELECT 'x'
          FROM   xxcop_mrp_schedule_interface  xmsi
                ,mrp_schedule_designators      msd
                ,mtl_parameters                mp
          WHERE msib.segment1               =  xmsi.item_code
            AND msib.organization_id        =  mp.organization_id
            AND msd.schedule_designator     =  xmsi.schedule_designator
            AND msd.organization_id         =  mp.organization_id
            AND mp.organization_code        =  xmsi.organization_code
            AND xmsi.file_id                =  in_file_id
        );
      ln_target_cnt := SQL%ROWCOUNT;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '品目OIF      データ件数：' || ln_target_cnt
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00027
                             ,iv_token_name1  => gv_msg_00027_token_1
                             ,iv_token_value1 => gv_msg_table_mism
                             );
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        RAISE global_api_expt;
    END;
    IF ( ln_target_cnt > 0 ) THEN
      --品目インポートコンカレント起動
      ln_request_id := fnd_request.submit_request(
                          application  => cv_application
                         ,program      => cv_program
--★
--                         ,argument1    => fnd_profile.value(gv_profile_master_org_id)
                         ,argument1    => TO_CHAR(gn_master_org_id)
--★
                         ,argument2    => cn_all_org_flag
                         ,argument3    => cn_validate_flag
                         ,argument4    => cn_process_flag
                         ,argument5    => cn_delete_flag
                         ,argument6    => ln_process_set
                         ,argument7    => cn_action_type
                       );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '品目インポート起動 =>  ：' || ln_request_id
      );
      IF ( ln_request_id = 0 ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10012
                              ,iv_token_name1  => gv_msg_10012_token_1
                              ,iv_token_value1 => gv_msg_conc_incoin
                              );
        RAISE global_api_expt;
      END IF;
--
      --品目インポートコンカレント起動のためコミット
      COMMIT;
--
      --品目インポートコンカレントの終了待機
      lb_wait_result := fnd_concurrent.wait_for_request(
                           request_id   => ln_request_id
                          ,interval     => gn_conc_interval
                          ,max_wait     => gn_conc_timeout
                          ,phase        => lv_phase
                          ,status       => lv_status
                          ,dev_phase    => lv_dev_phase
                          ,dev_status   => lv_dev_status
                          ,message      => lv_message
                        );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '品目インポートSTATUS'
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  フェーズ             ：' || lv_phase
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  ステータス           ：' || lv_status
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  DEVフェーズ          ：' || lv_dev_phase
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  DEVステータス        ：' || lv_dev_status
      );
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '  メッセージ           ：' || lv_message
      );
      --品目インポートコンカレントの異常終了
      IF ( lv_dev_phase  NOT IN ( cv_complete_phase )
        OR lv_dev_status NOT IN ( cv_successful_status ) )
      THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                               iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10011
                              ,iv_token_name1  => gv_msg_10011_token_1
                              ,iv_token_value1 => ln_request_id
                              ,iv_token_name2  => gv_msg_10011_token_2
                              ,iv_token_value2 => gv_msg_table_msib
                             );
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END entry_msii;
--
  /**********************************************************************************
   * Procedure Name   : get_xmsi
   * Description      : 対象データ抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_xmsi(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xmsi'; -- プログラム名
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
    l_row_no_tab              g_lock_column_ttype;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --基準計画I/F表のロック取得
    BEGIN
      SELECT xmsi.row_no
      BULK COLLECT INTO l_row_no_tab
      FROM  xxcop_mrp_schedule_interface xmsi
      WHERE xmsi.file_id = in_file_id
      FOR UPDATE OF xmsi.row_no NOWAIT;
      --対象件数の設定
      gn_target_cnt := l_row_no_tab.COUNT;
    EXCEPTION
      WHEN resource_busy_expt THEN
        ov_retcode   := gv_status_error;
        ov_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00007
                             ,iv_token_name1  => gv_msg_00007_token_1
                             ,iv_token_value1 => gv_msg_table_xmsi
                             );
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_xmsi;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    cv_format_validate   CONSTANT VARCHAR2(1) := '1';
    cv_lower_rows        CONSTANT VARCHAR2(1) := '2';
--
    -- *** ローカル変数 ***
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- ファイルアップロード名称
    lv_file_name         xxcop_mrp_schedule_interface.file_name%TYPE;     -- ファイル名
    lv_param_name        VARCHAR2(100);   -- パラメータ名
    lv_param_value       VARCHAR2(100);   -- パラメータ値
    lv_value             VARCHAR2(100);   -- プロファイル値
    lv_profile_name      VARCHAR2(100);   -- プロファイル名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --アップロード名称
    BEGIN
      SELECT flv.meaning  meaning
      INTO   lv_upload_name
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type        = gv_lookup_type
        AND  flv.lookup_code        = iv_format
        AND  flv.language           = gv_lang
        AND  flv.source_lang        = gv_lang
        AND  flv.enabled_flag       = gv_enable
        AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                            AND NVL(flv.end_date_active  ,gd_sysdate);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := cv_format_validate;
    END;
--
    --ファイル名
    BEGIN
      SELECT xmsi.file_name   file_name
      INTO   lv_file_name
      FROM   xxcop_mrp_schedule_interface xmsi
      WHERE  xmsi.file_id = in_file_id
        AND  ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_retcode := cv_lower_rows;
    END;
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --アップロード情報出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_appl_cont
                   ,iv_name         => gv_msg_00036
                   ,iv_token_name1  => gv_msg_00036_token_1
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_msg_00036_token_2
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_msg_00036_token_3
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_msg_00036_token_4
                   ,iv_token_value4 => lv_file_name
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
    --空白行を挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
    IF ( lv_retcode = cv_format_validate ) THEN
      --ファイルアップロード名称の取得に失敗した場合
      RAISE format_ptn_validate_expt;
    ELSIF ( lv_retcode = cv_lower_rows ) THEN
      --対象レコードがない場合
      RAISE lower_rows_expt;
    END IF;
    --プロファイルの取得
    --確定日基準日数
    lv_value := fnd_profile.value( gv_profile_baseline );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_baseline;
      RAISE profile_validate_expt;
    END IF;
    gn_fixed_baseline := TO_NUMBER(lv_value);
    --タイムアウト時間
    lv_value := fnd_profile.value( gv_profile_timeout );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_timeout;
      RAISE profile_validate_expt;
    END IF;
    gn_conc_timeout := TO_NUMBER(lv_value);
    --処理間隔
    lv_value := fnd_profile.value( gv_profile_interval );
    IF ( lv_value IS NULL ) THEN
      lv_profile_name := gv_profile_name_interval;
      RAISE profile_validate_expt;
    END IF;
    gn_conc_interval := TO_NUMBER(lv_value);
--★
    ---------------------------------------------------
    --  マスタ品目組織の取得
    ---------------------------------------------------
    BEGIN
      gn_master_org_id  :=  TO_NUMBER(fnd_profile.value(gv_profile_master_org_id));
    EXCEPTION
      WHEN OTHERS THEN
        gn_master_org_id  :=  NULL;
    END;
    -- プロファイル：マスタ品目組織が取得出来ない＆エラーとなる場合
    IF ( gn_master_org_id IS NULL ) THEN
      lv_profile_name := gv_profile_name_m_org_id;
      RAISE profile_validate_expt;
    END IF;
--★
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00002
                     ,iv_token_name1  => gv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
      ov_retcode := gv_status_error;
    WHEN format_ptn_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00005
                     ,iv_token_name1  => gv_msg_00005_token_1
                     ,iv_token_value1 => gv_msg_param_format
                     ,iv_token_name2  => gv_msg_00005_token_2
                     ,iv_token_value2 => iv_format
                   );
      ov_retcode := gv_status_error;
    WHEN lower_rows_expt THEN                           --*** <例外コメント> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00003
                   );
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ov_retcode := gv_status_normal;
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
    BEGIN
      -- ===============================
      -- A-1．初期処理
      -- ===============================
      init(
         in_file_id                     -- ファイルID
        ,iv_format                      -- フォーマットパターン
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-2．対象データ抽出処理
      -- ===============================
      get_xmsi(
         in_file_id                     -- ファイルID
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => '基準計画I/F  データ件数：' || gn_target_cnt
      );
      -- ===============================
      -- A-3．品目属性更新処理
      -- ===============================
      entry_msii(
         in_file_id                   -- ファイルID
        ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                   -- リターン・コード             --# 固定 #
        ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-4．基準計画登録処理
      -- ===============================
      entry_msi(
         in_file_id                   -- ファイルID
        ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                   -- リターン・コード             --# 固定 #
        ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- A-5．登録確認処理
      -- ===============================
      judge_msi(
         in_file_id                   -- ファイルID
        ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                   -- リターン・コード             --# 固定 #
        ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
    --終了ステータスがエラーの場合、ロールバックする。
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      gn_error_cnt := 1;
        --エラーメッセージを出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
    END IF;
--
    -- ===============================
    -- A-6．基準計画OIFデータ削除
    -- ===============================
    delete_msi(
       in_file_id                   -- ファイルID
      ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                   -- リターン・コード             --# 固定 #
      ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- A-7．基準計画I/F表(アドオン)データ削除
    -- ===============================
    delete_xmsi(
       in_file_id                   -- ファイルID
      ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                   -- リターン・コード             --# 固定 #
      ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
--
    IF ( ov_retcode = gv_status_normal ) THEN
      --終了ステータスが正常の場合、成功件数をセットする。
      gn_normal_cnt := gn_target_cnt;
    ELSE
      --終了ステータスがエラーの場合、コミットする。
      COMMIT;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    in_file_id    IN  NUMBER,        -- 1.ファイルID
    iv_format     IN  VARCHAR2       -- 2.フォーマットパターン
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --異常終了メッセージ
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_file_id  -- ファイルID
      ,iv_format   -- フォーマットパターン
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => lv_errmsg --ユーザー・エラーメッセージ
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => lv_errbuf --エラーメッセージ
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP001A02C;
/
