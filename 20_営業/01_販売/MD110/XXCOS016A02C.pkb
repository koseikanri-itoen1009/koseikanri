CREATE OR REPLACE PACKAGE BODY XXCOS016A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS016A02C (body)
 * Description      : 人事システム向け、販売実績データ作成処理
 * MD.050           : 人事システム向け販売実績データの作成（月次・賞与） COS_016_A03
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
 *  2008/11/17    1.0   T.kitajima       新規作成
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
  
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS016A02C';                  -- パッケージ名
  --アプリケーション短縮名
  cv_current_appl_short_nm            fnd_application.application_short_name%TYPE
                                      :=  'XXCOS';                    --販物短縮アプリ名
  --販物メッセージ
  cv_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00004';   --プロファイル取得エラー
  cv_msg_file_open_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00009';   --ファイルオープンエラー
  cv_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00013';   --データ取得エラーメッセージ
  cv_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00017';   --API呼出エラーメッセージ
  cv_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-00018';   --明細0件用メッセージ
  cv_msg_file_nm            CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13401';   --ファイル名メッセージ
  cv_msg_mem1_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13402';   --メッセージ用文字列
  cv_msg_mem2_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13403';   --メッセージ用文字列
  cv_msg_mem3_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                      :=  'APP-XXCOS1-13404';   --メッセージ用文字列
  --トークン
  cv_tkn_profile            CONSTANT  VARCHAR2(100) :=  'PROFILE';          --プロファイル
  cv_tkn_date_to            CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';       --テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(100) :=  'KEY_DATA';         --キーデータ
  cv_tkn_api_name           CONSTANT  VARCHAR2(100) :=  'API_NAME';         --ＡＰＩ名称
  cv_tkn_file_name          CONSTANT  VARCHAR2(100) :=  'FILE_NAME';        --ファイルパス
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
  --プロファイル名称
  cv_Profile_dir            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_OUTBOUND_PERSONNEL_DIR';       -- I/F出力先ディレクトリ
  cv_Profile_file           CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      :=  'XXCOS1_PERSONNEL_BONUS_FILE';         -- I/Fファイル名
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_nothing_msg
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
--
    --==============================================
    -- 2.人事システム向け賞与ファイル名
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
--#####################  固定ローカル変数宣言部 START   ########################
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
  END get_common;
--
  /**********************************************************************************
   * Procedure Name   : <file_open>
   * Description      : ファイル作成(A-3)
   ***********************************************************************************/
  PROCEDURE file_open(
    ot_handle     OUT UTL_FILE.FILE_TYPE,   --   ファイルハンドル
    ov_errbuf     OUT VARCHAR2,             --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,             --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_csv   CONSTANT VARCHAR2(1) := ','; -- カンマ
    cv_sla   CONSTANT VARCHAR2(1) := '/'; -- スラッシュ
    cv_dub   CONSTANT VARCHAR2(1) := '"'; -- ダブルクォート
    -- *** ローカル変数 ***
--
    lv_key_info VARCHAR2(5000);      --key情報
    lv_output   VARCHAR2(5000);      -- ファイル出力用
    lt_handle UTL_FILE.FILE_TYPE;    -- ファイルハンドル
    ln_count    NUMBER;              -- 処理件数
    -- *** ローカル・カーソル ***
    --人事賞与テーブルデータ取得用
    CURSOR data_cur
    IS
      SELECT employee_code                    as employee_code,      --従業員コード
             results_date                     as results_date,       --年月
             base_code                        as base_code,          --拠点コード
             division_code                    as division_code,      --本部コード
             NULL                             as NULL1,              --予備1
             NULL                             as NULL2,              --予備2
             NULL                             as NULL3,              --予備3
             NULL                             as NULL4,              --予備4
             p_sale_gross                     as p_sale_gross,       --個売上粗利
             p_current_profit                 as p_current_profit,   --個経常利益
             NULL                             as NULL5,              --空白1
             NULL                             as NULL6,              --空白2
             NULL                             as NULL7,              --空白3
             NULL                             as NULL8,              --空白4
             p_visit_count                    as p_visit_count,      --個訪問件数
             NULL                             as NULL9,              --空白5
             NULL                             as NULL10,             --空白6
             NULL                             as NULL11,             --空白7
             g_sale_gross                     as g_sale_gross,       --小売上粗利
             g_current_profit                 as g_current_profit,   --小経常利益
             NULL                             as NULL12,             --空白8
             NULL                             as NULL13,             --空白9
             NULL                             as NULL14,             --空白10
             NULL                             as NULL15,             --空白11
             g_visit_count                    as g_visit_count,      --小訪問件数
             NULL                             as NULL16,             --空白12
             NULL                             as NULL17,             --空白13
             NULL                             as NULL18,             --空白14
             b_sale_gross                     as b_sale_gross,       --拠売上粗利
             b_current_profit                 as b_current_profit,   --拠経常利益
             NULL                             as NULL19,             --空白15
             NULL                             as NULL20,             --空白16
             NULL                             as NULL21,             --空白17
             b_visit_count                    as b_visit_count,      --拠訪問件数
             NULL                             as NULL22,             --空白18
             NULL                             as NULL23,             --空白19
             NULL                             as NULL24,             --空白20
             a_sale_gross                     as a_sale_gross,       --地売上粗利
             a_current_profit                 as a_current_profit,   --地経常利益
             NULL                             as NULL25,             --空白21
             NULL                             as NULL26,             --空白22
             NULL                             as NULL27,             --空白23
             a_visit_count                    as a_visit_count,      --地訪問件数
             NULL                             as NULL28,             --空白24
             NULL                             as NULL29,             --空白25
             NULL                             as NULL30,             --空白26
             d_sale_gross                     as d_sale_gross,       --本売上粗利
             d_current_profit                 as d_current_profit,   --本経常利益
             NULL                             as NULL31,             --空白27
             NULL                             as NULL32,             --空白28
             NULL                             as NULL33,             --空白29
             d_visit_count                    as d_visit_count,      --本訪問件数
             NULL                             as NULL34,             --空白30
             NULL                             as NULL35,             --空白31
             NULL                             as NULL36,             --空白32
             s_sale_gross                     as s_sale_gross,       --全売上粗利
             s_current_profit                 as s_current_profit,   --全経常利益
             NULL                             as NULL37,             --空白33
             NULL                             as NULL38,             --空白34
             NULL                             as NULL39,             --空白35
             s_visit_count                    as s_visit_count,      --全訪問件数
             NULL                             as NULL40,             --空白36
             NULL                             as NULL41,             --空白37
             NULL                             as NULL42              --空白38
      FROM xxcos_for_adps_bonus_if
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
    --==============================================
    -- A-3. ファイル作成処理
    --==============================================
    file_open(
      ot_handle               =>  lt_handle,                  --ファイルハンドル
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
      lv_output := lv_output || cv_dub || l_data_rec.employee_code      || cv_dub || cv_csv;  --従業員コード
      lv_output := lv_output || cv_dub || l_data_rec.results_date       || cv_dub || cv_csv;  --年月
      lv_output := lv_output || cv_dub || l_data_rec.base_code          || cv_dub || cv_csv;  --拠点コード
      lv_output := lv_output || cv_dub || l_data_rec.division_code      || cv_dub || cv_csv;  --本部コード
      lv_output := lv_output || cv_dub || l_data_rec.NULL1              || cv_dub || cv_csv;  --予備1
      lv_output := lv_output || cv_dub || l_data_rec.NULL2              || cv_dub || cv_csv;  --予備2
      lv_output := lv_output || cv_dub || l_data_rec.NULL3              || cv_dub || cv_csv;  --予備3
      lv_output := lv_output || cv_dub || l_data_rec.NULL4              || cv_dub || cv_csv;  --予備4
      lv_output := lv_output ||           l_data_rec.p_sale_gross                 || cv_csv;  --個売上粗利
      lv_output := lv_output ||           l_data_rec.p_current_profit             || cv_csv;  --個経常利益
      lv_output := lv_output ||           l_data_rec.NULL5                        || cv_csv;  --空白1
      lv_output := lv_output ||           l_data_rec.NULL6                        || cv_csv;  --空白2
      lv_output := lv_output ||           l_data_rec.NULL7                        || cv_csv;  --空白3
      lv_output := lv_output ||           l_data_rec.NULL8                        || cv_csv;  --空白4
      lv_output := lv_output ||           l_data_rec.p_visit_count                || cv_csv;  --個訪問件数
      lv_output := lv_output ||           l_data_rec.NULL9                        || cv_csv;  --空白5
      lv_output := lv_output ||           l_data_rec.NULL10                       || cv_csv;  --空白6
      lv_output := lv_output ||           l_data_rec.NULL11                       || cv_csv;  --空白7
      lv_output := lv_output ||           l_data_rec.g_sale_gross                 || cv_csv;  --小売上粗利
      lv_output := lv_output ||           l_data_rec.g_current_profit             || cv_csv;  --小経常利益
      lv_output := lv_output ||           l_data_rec.NULL12                       || cv_csv;  --空白8
      lv_output := lv_output ||           l_data_rec.NULL13                       || cv_csv;  --空白9
      lv_output := lv_output ||           l_data_rec.NULL14                       || cv_csv;  --空白10
      lv_output := lv_output ||           l_data_rec.NULL15                       || cv_csv;  --空白11
      lv_output := lv_output ||           l_data_rec.g_visit_count                || cv_csv;  --小訪問件数
      lv_output := lv_output ||           l_data_rec.NULL16                       || cv_csv;  --空白12
      lv_output := lv_output ||           l_data_rec.NULL17                       || cv_csv;  --空白13
      lv_output := lv_output ||           l_data_rec.NULL18                       || cv_csv;  --空白14
      lv_output := lv_output ||           l_data_rec.b_sale_gross                 || cv_csv;  --拠売上粗利
      lv_output := lv_output ||           l_data_rec.b_current_profit             || cv_csv;  --拠経常利益
      lv_output := lv_output ||           l_data_rec.NULL19                       || cv_csv;  --空白15
      lv_output := lv_output ||           l_data_rec.NULL20                       || cv_csv;  --空白16
      lv_output := lv_output ||           l_data_rec.NULL21                       || cv_csv;  --空白17
      lv_output := lv_output ||           l_data_rec.b_visit_count                || cv_csv;  --拠訪問件数
      lv_output := lv_output ||           l_data_rec.NULL22                       || cv_csv;  --空白18
      lv_output := lv_output ||           l_data_rec.NULL23                       || cv_csv;  --空白19
      lv_output := lv_output ||           l_data_rec.NULL24                       || cv_csv;  --空白20
      lv_output := lv_output ||           l_data_rec.a_sale_gross                 || cv_csv;  --地売上粗利
      lv_output := lv_output ||           l_data_rec.a_current_profit             || cv_csv;  --地経常利益
      lv_output := lv_output ||           l_data_rec.NULL25                       || cv_csv;  --空白21
      lv_output := lv_output ||           l_data_rec.NULL26                       || cv_csv;  --空白22
      lv_output := lv_output ||           l_data_rec.NULL27                       || cv_csv;  --空白23
      lv_output := lv_output ||           l_data_rec.a_visit_count                || cv_csv;  --地訪問件数
      lv_output := lv_output ||           l_data_rec.NULL28                       || cv_csv;  --空白24
      lv_output := lv_output ||           l_data_rec.NULL29                       || cv_csv;  --空白25
      lv_output := lv_output ||           l_data_rec.NULL30                       || cv_csv;  --空白26
      lv_output := lv_output ||           l_data_rec.d_sale_gross                 || cv_csv;  --本売上粗利
      lv_output := lv_output ||           l_data_rec.d_current_profit             || cv_csv;  --本経常利益
      lv_output := lv_output ||           l_data_rec.NULL31                       || cv_csv;  --空白27
      lv_output := lv_output ||           l_data_rec.NULL32                       || cv_csv;  --空白28
      lv_output := lv_output ||           l_data_rec.NULL33                       || cv_csv;  --空白29
      lv_output := lv_output ||           l_data_rec.d_visit_count                || cv_csv;  --本訪問件数
      lv_output := lv_output ||           l_data_rec.NULL34                       || cv_csv;  --空白30
      lv_output := lv_output ||           l_data_rec.NULL35                       || cv_csv;  --空白31
      lv_output := lv_output ||           l_data_rec.NULL36                       || cv_csv;  --空白32
      lv_output := lv_output ||           l_data_rec.s_sale_gross                 || cv_csv;  --全売上粗利
      lv_output := lv_output ||           l_data_rec.s_current_profit             || cv_csv;  --全経常利益
      lv_output := lv_output ||           l_data_rec.NULL37                       || cv_csv;  --空白33
      lv_output := lv_output ||           l_data_rec.NULL38                       || cv_csv;  --空白34
      lv_output := lv_output ||           l_data_rec.NULL39                       || cv_csv;  --空白35
      lv_output := lv_output ||           l_data_rec.s_visit_count                || cv_csv;  --全訪問件数
      lv_output := lv_output ||           l_data_rec.NULL40                       || cv_csv;  --空白36
      lv_output := lv_output ||           l_data_rec.NULL41                       || cv_csv;  --空白37
      lv_output := lv_output ||           l_data_rec.NULL42;                                  --空白38
--
      UTL_FILE.PUT_LINE(lt_handle,lv_output);
--
    END LOOP for_loop;
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
      gn_normal_cnt := ln_count;
      gn_target_cnt := ln_count;
    END IF;
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
    WHEN global_common_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
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
--
    -- *** 対象データ０件エラー ***
    WHEN global_no_data_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_current_appl_short_nm,
        iv_name               =>  cv_msg_nodata_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
--
--###########################  固定部 END   #######################################################
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
END XXCOS016A02C;
/
