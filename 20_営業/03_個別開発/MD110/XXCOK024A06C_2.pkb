CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A06C_2
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCOK024A06C_2 (body)
 * Description      : 販売控除データGL連携を並列に呼び出す処理
 * MD.050           : 販売控除データGL連携 MD050_COK_024_A06
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2021/06/24    1.0   H.Futamura       新規作成
 *
 *****************************************************************************************/
--
--###########################  固定グローバル定数宣言部 START  ###########################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  固定グローバル定数宣言部 END  ############################
--
--###########################  固定グローバル変数宣言部 START  ###########################
--
  gv_out_msg       VARCHAR2(2000);                       -- 出力メッセージ
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- コンカレント成功件数
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- 処理件数
  gn_error_cnt     NUMBER   DEFAULT 0;                   -- コンカレントエラー件数
--
--############################  固定グローバル変数宣言部 END  ############################
--
--##############################  固定共通例外宣言部 START  ##############################
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
--###############################  固定共通例外宣言部 END  ###############################
--
  gd_process_date           DATE     DEFAULT NULL;   -- 業務処理日付
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCOK024A06C_2';               -- パッケージ名
  -- アプリケーション短縮名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10)  := 'XXCOK';                        -- 個別開発領域短縮アプリ名
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10)  := 'XXCCP';                        -- 共通・IF領域短縮アプリ名
  -- メッセージ名称
  cv_process_date_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00028';             -- 業務日付取得エラー
  -- クイックコード
  cv_lookup_dedu_code       CONSTANT VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';   -- 控除データ種類
  -- 有効フラグ
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
                   , ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
                   , ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_program                  CONSTANT VARCHAR2(20) := 'XXCOK024A06C'; -- コンカレント:販売控除データGL連携
    cb_sub_request              CONSTANT BOOLEAN      := FALSE;
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- GL連携パラレル実行グループ取得ワークテーブル
    TYPE gr_deductions_para_group_rec IS RECORD(
        para_group        fnd_lookup_values_vl.attribute13%TYPE             -- GL連携パラレル実行グループ
    );
  -- GL連携パラレル実行グループ取得
    TYPE g_deductions_para_group_ttype  IS TABLE OF gr_deductions_para_group_rec INDEX BY BINARY_INTEGER;
      g_deductions_para_group_tab        g_deductions_para_group_ttype;
--
    -- *** ローカル変数 ***
    ln_request_id            NUMBER;
--
    -- *** ローカル例外 ***
    submit_err_expt          EXCEPTION;
--
    -- *** ローカル・カーソル ***
    --GL連携パラレル実行グループ取得
    CURSOR deductions_para_group_cur
    IS
      SELECT  distinct flvv.attribute13 para_group
      FROM    fnd_lookup_values_vl flvv
      WHERE   flvv.lookup_type   = cv_lookup_dedu_code
      AND     flvv.enabled_flag  = cv_yes
      AND     NVL( flvv.start_date_active, gd_process_date ) <= gd_process_date
      AND     NVL( flvv.end_date_active,   gd_process_date ) >= gd_process_date
      ORDER BY flvv.attribute13
      ;
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    --==================================
    -- １．業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付取得エラーの場合はエラー
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            , cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --カーソルオープン
    OPEN  deductions_para_group_cur;
    FETCH deductions_para_group_cur BULK COLLECT INTO g_deductions_para_group_tab;
    CLOSE deductions_para_group_cur;
--
    -- 対象件数カウント
    gn_target_cnt := g_deductions_para_group_tab.COUNT;
--
    <<para_group_loop>>
    FOR i IN 1..g_deductions_para_group_tab.COUNT LOOP
      --==================================
      -- ２．販売控除データGL連携起動
      --==================================
      ln_request_id := fnd_request.submit_request(
                         application  => cv_xxcok_short_nm,
                         program      => cv_program,
                         description  => NULL,
                         start_time   => NULL,
                         sub_request  => cb_sub_request,
                         argument1    => g_deductions_para_group_tab( i ).para_group -- 実行グループ
                       );
      --コンカレント起動のためコミット
      COMMIT;
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP para_group_loop;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
      IF (deductions_para_group_cur %ISOPEN)THEN
        CLOSE deductions_para_group_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 END  #################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
                , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
                
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- 共通領域短縮アプリ名
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 登録件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-10008';  -- エラー終了メッセージ
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);         -- リターン・コード
    lv_errmsg          VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);       -- 終了メッセージコード
--
--#####################################  固定部 END  #####################################
--
  BEGIN
--
--####################################  固定部 START  ####################################
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  固定部 END  #####################################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
           , ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
           , ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    --エラー出力
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --エラーメッセージ
      );
    END IF;
--
    -- ===============================
    -- 終了処理
    -- ===============================
    --空行挿入
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    --処理対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_target_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                          );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_success_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                          );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                          , iv_name        => lv_message_code
                                          );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
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
--#####################################  固定部 END  #####################################
--
END XXCOK024A06C_2;
/
