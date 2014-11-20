CREATE OR REPLACE PACKAGE BODY XXCOS016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A01C (body)
 * Description      : 人事システム向け、販売実績月次データ(I/F)作成処理
 * MD.050           : 人事システム向け販売実績データの作成（月次） COS_016_A01
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  get_common             共通値取得処理(A-1)
 *  file_open              ファイル作成(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   T.kitajima       新規作成
 *  2009/02/17    1.1   T.kitajima       get_msgのパッケージ名修正
 *  2009/02/24    1.2   T.kitajima       パラメータのログファイル出力対応
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
--
  global_get_profile_expt   EXCEPTION;  --プロファイル取得例外
  global_make_file_expt     EXCEPTION;  --ファイルオープン例外
  global_no_data_expt       EXCEPTION;  --対象データ０件エラー
  global_common_expt        EXCEPTION;  --共通例外
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS016A01C';        -- パッケージ名
--
  --アプリケーション短縮名
  cv_current_appl_short_nm            fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';             --販物短縮アプリ名
  --販物メッセージ
  cv_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00004';  --プロファイル取得エラー
  cv_msg_file_open_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00009';   --ファイルオープンエラー
  cv_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';   --データ取得エラーメッセージ
  cv_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';   --API呼出エラーメッセージ
  cv_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';   --明細0件用メッセージ
  cv_msg_file_nm            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13351';   --ファイル名メッセージ
  cv_msg_mem1_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13352';   --メッセージ用文字列
  cv_msg_mem2_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13353';   --メッセージ用文字列
  cv_msg_mem3_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-13354';   --メッセージ用文字列
  --トークン
  cv_tkn_profile            CONSTANT  VARCHAR2(10)  := 'PROFILE';           --プロファイル
  cv_tkn_date_to            CONSTANT  VARCHAR2(10)  := 'TABLE_NAME';        --テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(10)  := 'KEY_DATA';          --キーデータ
  cv_tkn_api_name           CONSTANT  VARCHAR2(10)  := 'API_NAME';          --ＡＰＩ名称
  cv_tkn_file_name          CONSTANT  VARCHAR2(10)  := 'FILE_NAME';         --ファイルパス
  --メッセージ用文字列
  cv_str_profile_nm         CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem1_date
                                                      );
  cv_str_request_id_nm      CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem2_date
                                                      );
  cv_str_file_name          CONSTANT  VARCHAR2(50)  := xxccp_common_pkg.get_msg(
                                                         iv_application        =>  cv_current_appl_short_nm
                                                        ,iv_name               =>  cv_msg_mem3_date
                                                      );
  cv_csv                    CONSTANT  VARCHAR2(1)   := ','; -- カンマ
  cv_sla                    CONSTANT  VARCHAR2(1)   := '/'; -- スラッシュ
  cv_dub                    CONSTANT  VARCHAR2(1)   := '"'; -- ダブルクォート
  --プロファイル名称
  cv_Profile_dir            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_OUTBOUND_PERSONNEL_DIR';  -- I/F出力先ディレクトリ
  cv_Profile_file           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_PERSONNEL_MONTHS_FILE';   -- I/Fファイル名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_output_dir             VARCHAR2(255);                                 --  人事向けアウトバウンド用ディレクトリパス
  gv_output_file            VARCHAR2(255);                                 --  人事向けアウトバウンド用ファイル名
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_nothing_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし
    --
    -- *** ローカル変数 ***
--
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
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
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_nothing_msg
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
  EXCEPTION
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
   * Procedure Name   : get_common
   * Description      : 共通データ取得(A-1)
   ***********************************************************************************/
  PROCEDURE get_common(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_common'; -- プログラム名
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
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);  --key情報
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
    --==============================================
    -- 1.人事向けアウトバウンド用ディレクトリパス
    --==============================================
    gv_output_dir := FND_PROFILE.VALUE(cv_Profile_dir);
    --ディレクト未取得
    IF ( gv_output_dir IS NULL ) THEN
      --キー情報編集
      XXCOS_COMMON_PKG.makeup_key_info(
                                     ov_errbuf      =>  lv_errbuf          --エラー・メッセージ
                                    ,ov_retcode     =>  lv_retcode         --リターンコード
                                    ,ov_errmsg      =>  lv_errmsg          --ユーザ・エラー・メッセージ
                                    ,ov_key_info    =>  lv_key_info        --編集されたキー情報
                                    ,iv_item_name1  =>  cv_str_profile_nm
                                    ,iv_data_value1 =>  cv_Profile_dir
                                    );
      --メッセージ
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --==============================================
    -- 2.人事システム向け月次ファイル名
    --==============================================
    --
    gv_output_file := FND_PROFILE.VALUE(cv_Profile_file);
    --ファイル名未取得
    IF ( gv_output_file IS NULL ) THEN
      --キー情報編集
      XXCOS_COMMON_PKG.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf          --エラー・メッセージ
                                       ,ov_retcode     =>  lv_retcode         --リターンコード
                                       ,ov_errmsg      =>  lv_errmsg          --ユーザ・エラー・メッセージ
                                       ,ov_key_info    =>  lv_key_info        --編集されたキー情報
                                       ,iv_item_name1  =>  cv_str_profile_nm
                                       ,iv_data_value1 =>  cv_Profile_file
                                      );
      --メッセージ
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_profile_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_current_appl_short_nm
                    ,iv_name         => cv_msg_file_nm
                    ,iv_token_name1  => cv_tkn_file_name
                    ,iv_token_value1 => gv_output_file
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
  EXCEPTION
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END get_common;
--
  /**********************************************************************************
   * Procedure Name   : <file_open>
   * Description      : ファイル作成(A-3)
   ***********************************************************************************/
  PROCEDURE file_open(
    ot_handle     OUT UTL_FILE.FILE_TYPE,   --   ファイルハンドル
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'file_open'; -- プログラム名
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
--
  BEGIN
----
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
    ot_handle := UTL_FILE.FOPEN(gv_output_dir, gv_output_file, 'W');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END file_open;
--
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
    lv_output   VARCHAR2(5000);      -- ファイル出力用
    lt_handle   UTL_FILE.FILE_TYPE;  -- ファイルハンドル
    ln_count    NUMBER;              -- 処理件数
    lv_key_info VARCHAR2(5000);      -- key情報
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --人事月次テーブルデータ取得用(A-2)
    CURSOR data_cur
    IS
      SELECT employee_code                    as employee_code,              --従業員コード
             results_date                     as results_date,               --年月
             base_code                        as base_code,                  --拠点コード
             division_code                    as division_code,              --本部コード
             NULL                             as NULL1,                      --予備1
             NULL                             as NULL2,                      --予備2
             NULL                             as NULL3,                      --予備3
             NULL                             as NULL4,                      --予備4
             p_sale_norma                     as p_sale_norma,               --個売上ノルマ
             p_sale_amount                    as p_sale_amount,              --個売上金額
             p_sale_achievement_rate          as p_sale_achievement_rate,    --個売上達成率
             p_new_contribution_sale          as p_new_contribution_sale,    --個新規貢献売上
             p_new_norma                      as p_new_norma,                --個新規ノルマ
             p_new_achievement_rate           as p_new_achievement_rate,     --個新規達成率
             p_new_count_sum                  as p_new_count_sum,            --個新規件数合計
             p_new_count_vd                   as p_new_count_vd,             --個新規件数ベンダー
             p_position_point                 as p_position_point,           --個資格POINT
             p_new_point                      as p_new_point,                --個新規POINT
             g_sale_norma                     as g_sale_norma,               --小売上ノルマ
             g_sale_amount                    as g_sale_amount,              --小売上金額
             g_sale_achievement_rate          as g_sale_achievement_rate,    --小売上達成率
             g_new_contribution_sale          as g_new_contribution_sale,    --小新規貢献売上
             g_new_norma                      as g_new_norma,                --小新規ノルマ
             g_new_achievement_rate           as g_new_achievement_rate,     --小新規達成率
             g_new_count_sum                  as g_new_count_sum,            --小新規件数合計
             g_new_count_vd                   as g_new_count_vd,             --小新規件数ベンダー
             g_position_point                 as g_position_point,           --小資格POINT
             g_new_point                      as g_new_point,                --小新規POINT
             b_sale_norma                     as b_sale_norma,               --拠売上ノルマ
             b_sale_amount                    as b_sale_amount,              --拠売上金額
             b_sale_achievement_rate          as b_sale_achievement_rate,    --拠売上達成率
             b_new_contribution_sale          as b_new_contribution_sale,    --拠新規貢献売上
             b_new_norma                      as b_new_norma,                --拠新規ノルマ
             b_new_count_sum                  as b_new_count_sum,            --拠新規件数合計
             b_new_count_vd                   as b_new_count_vd,             --拠新規件数ベンダー
             b_position_point                 as b_position_point,           --拠資格POINT
             b_new_point                      as b_new_point,                --拠新規POINT
             a_sale_norma                     as a_sale_norma,               --地売上ノルマ
             a_sale_amount                    as a_sale_amount,              --地売上金額
             a_sale_achievement_rate          as a_sale_achievement_rate,    --地売上達成率
             a_new_contribution_sale          as a_new_contribution_sale,    --地新規貢献売上
             a_new_norma                      as a_new_norma,                --地新規ノルマ
             a_new_count_sum                  as a_new_count_sum,            --地新規件数合計
             a_new_count_vd                   as a_new_count_vd,             --地新規件数ベンダー
             a_position_point                 as a_position_point,           --地資格POINT
             a_new_point                      as a_new_point,                --地新規POINT
             d_sale_norma                     as d_sale_norma,               --本売上ノルマ
             d_sale_amount                    as d_sale_amount,              --本売上金額
             d_sale_achievement_rate          as d_sale_achievement_rate,    --本売上達成率
             d_new_contribution_sale          as d_new_contribution_sale,    --本新規貢献売上
             d_new_norma                      as d_new_norma,                --本新規ノルマ
             d_new_count_sum                  as d_new_count_sum,            --本新規件数合計
             d_new_count_vd                   as d_new_count_vd,             --本新規件数ベンダー
             d_position_point                 as d_position_point,           --本資格POINT
             d_new_point                      as d_new_point,                --本新規POINT
             s_sale_norma                     as s_sale_norma,               --全売上ノルマ
             s_sale_amount                    as s_sale_amount,              --全売上金額
             s_sale_achievement_rate          as s_sale_achievement_rate,    --全売上達成率
             s_new_contribution_sale          as s_new_contribution_sale,    --全新規貢献売上
             s_new_norma                      as s_new_norma,                --全新規ノルマ
             s_new_count_sum                  as s_new_count_sum,            --全新規件数合計
             s_new_count_vd                   as s_new_count_vd,             --全新規件数ベンダー
             s_position_point                 as s_position_point,           --全資格POINT
             s_new_point                      as s_new_point                 --全新規POINT
      FROM xxcos_for_adps_monthly_if
    ;
--
    -- *** ローカル・レコード ***
    l_data_rec               data_cur%ROWTYPE;
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
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- A-0.初期処理
    -- ===============================
    init(
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_api_others_expt;
    END IF;
    -- ===============================
    -- A-1.共通データ取得
    -- ===============================
    get_common(
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_common_expt;
    END IF;
--
    --==============================================
    -- A-3. ファイル作成処理
    --==============================================
    file_open(
      ot_handle               =>  lt_handle,                  -- ファイルハンドル
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      XXCOS_COMMON_PKG.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf          --エラー・メッセージ
                                       ,ov_retcode     =>  lv_retcode         --リターンコード
                                       ,ov_errmsg      =>  lv_errmsg          --ユーザ・エラー・メッセージ
                                       ,ov_key_info    =>  lv_key_info        --編集されたキー情報
                                       ,iv_item_name1  =>  cv_str_file_name
                                       ,iv_data_value1 =>  gv_output_dir || cv_sla || gv_output_file
                                      );
        RAISE global_make_file_expt;
    END IF;
    --==============================================
    -- A-4. データ出力処理
    --==============================================
    ln_count := 0;
    <<for_loop>>
    FOR l_data_rec IN data_cur LOOP
      --初期化
      lv_output := NULL;
      ln_count  := ln_count + 1;
      --変数に設定(カンマ区切り)
      lv_output := lv_output || cv_dub || l_data_rec.employee_code           || cv_dub || cv_csv;  --従業員コード
      lv_output := lv_output || cv_dub || l_data_rec.results_date            || cv_dub || cv_csv;  --年月
      lv_output := lv_output || cv_dub || l_data_rec.base_code               || cv_dub || cv_csv;  --拠点コード
      lv_output := lv_output || cv_dub || l_data_rec.division_code           || cv_dub || cv_csv;  --本部コード
      lv_output := lv_output || cv_dub || l_data_rec.NULL1                   || cv_dub || cv_csv;  --予備1
      lv_output := lv_output || cv_dub || l_data_rec.NULL2                   || cv_dub || cv_csv;  --予備2
      lv_output := lv_output || cv_dub || l_data_rec.NULL3                   || cv_dub || cv_csv;  --予備3
      lv_output := lv_output || cv_dub || l_data_rec.NULL4                   || cv_dub || cv_csv;  --予備4
      lv_output := lv_output ||           l_data_rec.p_sale_norma                      || cv_csv;  --個売上ノルマ
      lv_output := lv_output ||           l_data_rec.p_sale_amount                     || cv_csv;  --個売上金額
      lv_output := lv_output ||           l_data_rec.p_sale_achievement_rate           || cv_csv;  --個売上達成率
      lv_output := lv_output ||           l_data_rec.p_new_contribution_sale           || cv_csv;  --個新規貢献売上
      lv_output := lv_output ||           l_data_rec.p_new_norma                       || cv_csv;  --個新規ノルマ
      lv_output := lv_output ||           l_data_rec.p_new_achievement_rate            || cv_csv;  --個新規達成率
      lv_output := lv_output ||           l_data_rec.p_new_count_sum                   || cv_csv;  --個新規件数合計
      lv_output := lv_output ||           l_data_rec.p_new_count_vd                    || cv_csv;  --個新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.p_position_point                  || cv_csv;  --個資格POINT
      lv_output := lv_output ||           l_data_rec.p_new_point                       || cv_csv;  --個新規POINT
      lv_output := lv_output ||           l_data_rec.g_sale_norma                      || cv_csv;  --小売上ノルマ
      lv_output := lv_output ||           l_data_rec.g_sale_amount                     || cv_csv;  --小売上金額
      lv_output := lv_output ||           l_data_rec.g_sale_achievement_rate           || cv_csv;  --小売上達成率
      lv_output := lv_output ||           l_data_rec.g_new_contribution_sale           || cv_csv;  --小新規貢献売上
      lv_output := lv_output ||           l_data_rec.g_new_norma                       || cv_csv;  --小新規ノルマ
      lv_output := lv_output ||           l_data_rec.g_new_achievement_rate            || cv_csv;  --小新規達成率
      lv_output := lv_output ||           l_data_rec.g_new_count_sum                   || cv_csv;  --小新規件数合計
      lv_output := lv_output ||           l_data_rec.g_new_count_vd                    || cv_csv;  --小新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.g_position_point                  || cv_csv;  --小資格POINT
      lv_output := lv_output ||           l_data_rec.g_new_point                       || cv_csv;  --小新規POINT
      lv_output := lv_output ||           l_data_rec.b_sale_norma                      || cv_csv;  --拠売上ノルマ
      lv_output := lv_output ||           l_data_rec.b_sale_amount                     || cv_csv;  --拠売上金額
      lv_output := lv_output ||           l_data_rec.b_sale_achievement_rate           || cv_csv;  --拠売上達成率
      lv_output := lv_output ||           l_data_rec.b_new_contribution_sale           || cv_csv;  --拠新規貢献売上
      lv_output := lv_output ||           l_data_rec.b_new_norma                       || cv_csv;  --拠新規ノルマ
      lv_output := lv_output ||           l_data_rec.b_new_count_sum                   || cv_csv;  --拠新規件数合計
      lv_output := lv_output ||           l_data_rec.b_new_count_vd                    || cv_csv;  --拠新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.b_position_point                  || cv_csv;  --拠資格POINT
      lv_output := lv_output ||           l_data_rec.b_new_point                       || cv_csv;  --拠新規POINT
      lv_output := lv_output ||           l_data_rec.a_sale_norma                      || cv_csv;  --地売上ノルマ
      lv_output := lv_output ||           l_data_rec.a_sale_amount                     || cv_csv;  --地売上金額
      lv_output := lv_output ||           l_data_rec.a_sale_achievement_rate           || cv_csv;  --地売上達成率
      lv_output := lv_output ||           l_data_rec.a_new_contribution_sale           || cv_csv;  --地新規貢献売上
      lv_output := lv_output ||           l_data_rec.a_new_norma                       || cv_csv;  --地新規ノルマ
      lv_output := lv_output ||           l_data_rec.a_new_count_sum                   || cv_csv;  --地新規件数合計
      lv_output := lv_output ||           l_data_rec.a_new_count_vd                    || cv_csv;  --地新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.a_position_point                  || cv_csv;  --地資格POINT
      lv_output := lv_output ||           l_data_rec.a_new_point                       || cv_csv;  --地新規POINT
      lv_output := lv_output ||           l_data_rec.d_sale_norma                      || cv_csv;  --本売上ノルマ
      lv_output := lv_output ||           l_data_rec.d_sale_amount                     || cv_csv;  --本売上金額
      lv_output := lv_output ||           l_data_rec.d_sale_achievement_rate           || cv_csv;  --本売上達成率
      lv_output := lv_output ||           l_data_rec.d_new_contribution_sale           || cv_csv;  --本新規貢献売上
      lv_output := lv_output ||           l_data_rec.d_new_norma                       || cv_csv;  --本新規ノルマ
      lv_output := lv_output ||           l_data_rec.d_new_count_sum                   || cv_csv;  --本新規件数合計
      lv_output := lv_output ||           l_data_rec.d_new_count_vd                    || cv_csv;  --本新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.d_position_point                  || cv_csv;  --本資格POINT
      lv_output := lv_output ||           l_data_rec.d_new_point                       || cv_csv;  --本新規POINT
      lv_output := lv_output ||           l_data_rec.s_sale_norma                      || cv_csv;  --全売上ノルマ
      lv_output := lv_output ||           l_data_rec.s_sale_amount                     || cv_csv;  --全売上金額
      lv_output := lv_output ||           l_data_rec.s_sale_achievement_rate           || cv_csv;  --全売上達成率
      lv_output := lv_output ||           l_data_rec.s_new_contribution_sale           || cv_csv;  --全新規貢献売上
      lv_output := lv_output ||           l_data_rec.s_new_norma                       || cv_csv;  --全新規ノルマ
      lv_output := lv_output ||           l_data_rec.s_new_count_sum                   || cv_csv;  --全新規件数合計
      lv_output := lv_output ||           l_data_rec.s_new_count_vd                    || cv_csv;  --全新規件数ベンダー
      lv_output := lv_output ||           l_data_rec.s_position_point                  || cv_csv;  --全資格POINT
      lv_output := lv_output ||           l_data_rec.s_new_point;                                  --全新規POINT
--
      UTL_FILE.PUT_LINE(lt_handle,lv_output);
--
    END LOOP for_loop;
--
    --==============================================
    -- A-5.ファイル終了処理
    --==============================================
    UTL_FILE.FFLUSH(lt_handle);
    UTL_FILE.FCLOSE(lt_handle);
    --処理件数確認
    IF ( ln_count = 0 ) THEN
      --明細0件警告
      RAISE global_no_data_expt;
    ELSE
      --正常メッセージ用
      gn_normal_cnt := ln_count; -- 正常件数
      gn_target_cnt := ln_count; -- 対象件数
    END IF;
--
  EXCEPTION
    -- *** 対象データ０件エラー ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ファイルオープン例外 ***
    WHEN global_make_file_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_file_open_err,
        iv_token_name1        =>  cv_tkn_file_name,
        iv_token_value1       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
  )
--
--
--###########################  固定部 START   #####################################################
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
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
    --スキップ件数出力
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
    errbuf := lv_errbuf;
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
END XXCOS016A01C;
/
