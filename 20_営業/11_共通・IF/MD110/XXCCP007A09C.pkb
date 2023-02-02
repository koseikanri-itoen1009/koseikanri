CREATE OR REPLACE PACKAGE BODY APPS.XXCCP007A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCCP007A09C(body)
 * Description      : GL未承認データ抽出
 * MD.070           : GL未承認データ抽出 (MD070_IPO_CCP_007_A09)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/01/24    1.0   R.Oikawa      [E_本稼動_19039]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
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
  gn_warn_cnt      NUMBER;                    -- 警告件数
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
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP007A09C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_gl_date_from       IN  VARCHAR2      --   計上日（自）
   ,iv_gl_date_to         IN  VARCHAR2      --   計上日（至）
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
    ld_gl_date_from    DATE;
    ld_gl_date_to      DATE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ● GLの未承認伝票抽出
    CURSOR main_cur1
    IS
       SELECT
           xjs.entry_department                               entry_department          -- 起票部門
          ,xjs.requestor_person_name                          requestor_person_name     -- 申請者名
          ,xjs.approver_person_name                           approver_person_name      -- 承認者名
          ,xjs.journal_num                                    journal_num               -- 伝票番号
          ,REPLACE(
                   REPLACE(
                           REPLACE(xjs.description, ',', '')
                          , CHR(13), '')
                  , CHR(10), '')                              description               -- 備考
          ,TO_CHAR(xjs.entry_date, 'YYYY/MM/DD')              entry_date                -- 起票日
          ,TO_CHAR(xjs.gl_date, 'YYYY/MM/DD')                 gl_date                   -- 計上日
          ,xjs.period_name                                    period_name               -- 会計期間
          ,xjs.total_entered_dr                               total_entered_dr          -- 借方合計金額
          ,xjs.total_entered_cr                               total_entered_cr          -- 貸方合計金額
       FROM
           XX03.xx03_journal_slips xjs
       WHERE
           xjs.wf_status           = '30'
       AND ld_gl_date_from        <= xjs.gl_date
       AND ld_gl_date_to          >= xjs.gl_date
       ORDER BY xjs.entry_department
               ,xjs.requestor_person_name
               ,xjs.journal_num
       ;
    -- メインカーソルレコード型
    main_rec1  main_cur1%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init部
    -- ===============================
--
    ld_gl_date_from := TO_DATE(iv_gl_date_from,'YYYY/MM/DD HH24:MI:SS')  ;
    ld_gl_date_to   := TO_DATE(iv_gl_date_to,'YYYY/MM/DD HH24:MI:SS')  ;
    -- 計上日（自）出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '計上日（自）：'|| TO_CHAR(ld_gl_date_from,'YYYY/MM/DD')
    );
    --
    -- 計上日（至）出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '計上日（至）：'|| TO_CHAR(ld_gl_date_to,'YYYY/MM/DD')
    );
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '起票部門,申請者,承認者,伝票番号,備考,起票日,計上日,会計期間,借方合計金額,貸方合計金額'
    );
--
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    -- データ部出力
    FOR main_rec1 IN main_cur1 LOOP
      --件数セット
      gn_target_cnt := gn_target_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '"' || main_rec1.entry_department           || '"'  -- 起票部門
                   ||  ',"' || main_rec1.requestor_person_name || '"'  -- 申請者
                   ||  ',"' || main_rec1.approver_person_name  || '"'  -- 承認者
                   ||  ',"' || main_rec1.journal_num           || '"'  -- 伝票番号
                   ||  ',"' || main_rec1.description           || '"'  -- 備考
                   ||  ',"' || main_rec1.entry_date            || '"'  -- 起票日
                   ||  ',"' || main_rec1.gl_date               || '"'  -- 計上日
                   ||  ',"' || main_rec1.period_name           || '"'  -- 会計期間
                   ||  ','  || main_rec1.total_entered_dr              -- 借方合計金額
                   ||  ','  || main_rec1.total_entered_cr              -- 貸方合計金額
      );
    END LOOP;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
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
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_gl_date_from       IN  VARCHAR2      --   計上日（自）
   ,iv_gl_date_to         IN  VARCHAR2      --   計上日（至）
  )
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- エラー終了メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_gl_date_from                             -- 計上日（自）
      ,iv_gl_date_to                               -- 計上日（至）
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数設定
      gn_error_cnt := 1;
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP007A09C;
/
