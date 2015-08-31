CREATE OR REPLACE PACKAGE BODY APPS.XXCCP400A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP400A01C(body)
 * Description      : コンカレント結果判定
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  メイン処理プロシージャ
 *  main                     コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/08/25    1.0   N.Koyama         [E_本稼動_13287]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
--
  cv_msg_part                CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3) := '.';
  gv_out_msg                VARCHAR2(2000);
  --例外
  global_api_others_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCCP400A01C';                 -- プログラム名
  cv_normal                 CONSTANT VARCHAR2(1)   := 'C';             -- 正常
  cv_worn                   CONSTANT VARCHAR2(1)   := 'G';             -- 警告
  cv_err                    CONSTANT VARCHAR2(1)   := 'E';             -- エラー
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';             -- Yes
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_check_group IN  VARCHAR2,     --   1.チェック対象グループコード
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
--
  IS
--
    --固定変数
    lv_errbuf                 VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);     -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    --対象コンカレント結果取得カーソル
    CURSOR data_cur
    IS
      SELECT fcr.request_id                                                   AS request_id, 
             fcp.concurrent_program_name                                      AS program_short_name,
             flv.meaning                                                      AS program_name,
             fcr.status_code                                                  AS status_code,
             DECODE(fcr.status_code,'C','正常','G','警告','E','エラー','X','終了','D','取消済',NULL) AS status_name,
             flv.attribute1                                                   AS normal_check,
             flv.attribute2                                                   AS worn_check,
             flv.attribute3                                                   AS err_check
        FROM applsys.fnd_concurrent_programs    fcp,
             applsys.fnd_concurrent_requests    fcr,
             applsys.fnd_lookup_values          flv
       WHERE fcp.application_id                   = fcr.program_application_id 
         AND fcp.concurrent_program_id            = fcr.concurrent_program_id 
         AND fcr.request_date                    >= TRUNC(SYSDATE)                  -- 本日のAM00:00から
         AND fcr.request_date                     < TRUNC(SYSDATE) + 0.25           -- 本日のAM06:00まで
         AND flv.lookup_type                      = 'XXCCP1_STATUS_CHECK_CONC1'
         AND flv.lookup_code                   LIKE iv_check_group || '%'
         AND flv.description                      = fcp.concurrent_program_name
         AND flv.language    = 'JA'
         AND flv.enabled_flag = 'Y'
         AND    TRUNC(SYSDATE) BETWEEN TRUNC(flv.start_date_active) 
                                 AND     NVL(flv.end_date_active, TRUNC(SYSDATE))
         AND ((flv.attribute6 IS NOT NULL
         AND   flv.attribute6 = fcr.argument1)
          OR  (flv.attribute6 IS NULL))
         AND ((flv.attribute7 IS NOT NULL
         AND   flv.attribute7 = fcr.argument2)
          OR  (flv.attribute7 IS NULL))
         AND ((flv.attribute8 IS NOT NULL
         AND   flv.attribute8 = fcr.argument3)
          OR  (flv.attribute8 IS NULL))
         AND ((flv.attribute9 IS NOT NULL
         AND   flv.attribute9 = fcr.argument4)
          OR  (flv.attribute9 IS NULL))
         AND ((flv.attribute10 IS NOT NULL
         AND   flv.attribute10 = fcr.argument5)
          OR  (flv.attribute10 IS NULL))
         AND ((flv.attribute11 IS NOT NULL
         AND   flv.attribute11 = fcr.argument6)
          OR  (flv.attribute11 IS NULL))
         AND ((flv.attribute12 IS NOT NULL
         AND   flv.attribute12 = fcr.argument7)
          OR  (flv.attribute12 IS NULL))
         AND ((flv.attribute13 IS NOT NULL
         AND   flv.attribute13 = fcr.argument8)
          OR  (flv.attribute13 IS NULL))
         AND ((flv.attribute14 IS NOT NULL
         AND   flv.attribute14 = fcr.argument9)
          OR  (flv.attribute14 IS NULL))
         AND ((flv.attribute15 IS NOT NULL
         AND   flv.attribute15 = fcr.argument10)
          OR  (flv.attribute15 IS NULL))
       ORDER BY fcr.request_id
      ;
--
    data_rec data_cur%ROWTYPE;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- パラメータ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => 'チェック対象グループコード: ' || iv_check_group
    );
    -- 空行出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => NULL
    );
--
    --対象データ抽出
    OPEN data_cur;
    LOOP
      FETCH data_cur INTO data_rec;
      EXIT WHEN data_cur%NOTFOUND;
--
      gv_out_msg := '要求ID:'|| data_rec.request_id || ' ' || data_rec.program_short_name || ' ' || data_rec.program_name || ' が' || data_rec.status_name || '終了しました。';
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
      --終了ステータス判定
      CASE data_rec.status_code
      -- 正常時エラー終了
        WHEN cv_normal THEN
          IF ( data_rec.normal_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;
      -- 警告時エラー終了
        WHEN cv_worn THEN
          IF ( data_rec.worn_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;          
      -- エラー時エラー終了
        WHEN cv_err THEN
          IF ( data_rec.err_check = cv_y ) THEN
            ov_retcode := cv_status_error;
          END IF;
      END CASE;
--
    END LOOP;
--
    CLOSE data_cur;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SQLERRM;
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_check_group  IN  VARCHAR2       -- 1.チェック対象グループコード
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
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
       iv_which   => 'LOG'
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
       iv_check_group  -- 1.チェック対象グループコード
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
END XXCCP400A01C;
/
