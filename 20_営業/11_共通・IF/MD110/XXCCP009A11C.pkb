CREATE OR REPLACE PACKAGE BODY XXCCP009A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A11C(body)
 * Description      : 売掛未収金残高（顧客別補助科目別サマリ）取得
 * MD.070           : 売掛未収金残高（顧客別補助科目別サマリ）取得(MD070_IPO_CCP_009_A11)
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
 *  2014/12/16     1.0  SCSK K.Nakatsu   [E_本稼動_12777]新規作成
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP009A11C'; -- パッケージ名
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
    iv_period_name  IN  jg_zz_ar_balances.period_name%TYPE,     --   会計期間
    ov_errbuf       OUT VARCHAR2,                               --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,                               --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)                               --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 売掛未収金残高（顧客別補助科目別サマリ）取得
    CURSOR jg_balance_cur
      IS
        SELECT 
           /*+ 
               FIRST_ROWS
               LEADING(a hca hcp gcc)
           */
           hca.account_number                                             AS account_number               -- 顧客番号
          ,hcp.party_name                                                 AS party_name                   -- 顧客名
          ,jgblc.period_name                                              AS period_name                  -- 会計期間
          ,gcc.segment3                                                   AS aff_account_code             -- 勘定科目
          ,(SELECT a.aff_account_name
            FROM xxcff_aff_account_v a
            WHERE gcc.segment3 = a.aff_account_code)                      AS aff_account_name             -- 勘定科目名
          ,gcc.segment4                                                   AS aff_sub_account_cooe         -- 補助科目
          ,(SELECT a.aff_sub_account_name
            FROM xxcff_aff_sub_account_v a
            WHERE gcc.segment4 = a.aff_sub_account_code
            AND gcc.segment3   = a.aff_account_name)                      AS aff_sub_account_name         -- 補助科目名
          ,SUM(NVL(jgblc.begin_bal_accounted_dr,0))                       AS sum_begin_bal_accounted_dr   -- 期首借方
          ,SUM(NVL(jgblc.begin_bal_accounted_cr,0))                       AS sum_begin_bal_accounted_cr   -- 期首貸方
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 NVL(jgblc.begin_bal_accounted_dr,0) - NVL(jgblc.begin_bal_accounted_cr,0)
               ELSE
                 NVL(jgblc.begin_bal_accounted_cr,0) - NVL(jgblc.begin_bal_accounted_dr,0)
               END)                                                       AS remain_begin_bal_accounted   -- 期首残
          ,SUM(NVL(jgblc.period_net_accounted_dr,0))                      AS sum_period_net_accounted_dr  -- 期中借方
          ,SUM(NVL(jgblc.period_net_accounted_cr,0))                      AS sum_period_net_accounted_cr  -- 期中貸方
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 NVL(jgblc.period_net_accounted_dr,0) - NVL(jgblc.period_net_accounted_cr,0)
               ELSE
                 NVL(jgblc.period_net_accounted_cr,0) - NVL(jgblc.period_net_accounted_dr,0)
               END)                                                       AS remain_period_net_accounted  -- 期中残
          ,SUM(CASE
               WHEN gcc.account_type IN ('A','E') THEN
                 (NVL(jgblc.begin_bal_accounted_dr,0) - NVL(jgblc.begin_bal_accounted_cr,0)) + (NVL(jgblc.period_net_accounted_dr,0) - NVL(jgblc.period_net_accounted_cr,0))
               ELSE
                 (NVL(jgblc.begin_bal_accounted_cr,0) - NVL(jgblc.begin_bal_accounted_dr,0)) + (NVL(jgblc.period_net_accounted_cr,0) - NVL(jgblc.period_net_accounted_dr,0))
               END)                                                       AS remain_end_bal_accounted     -- 期末残
        FROM   
           jg_zz_ar_balances        jgblc    -- JG顧客残高テーブル
          ,hz_cust_accounts         hca      -- 顧客マスタ
          ,hz_parties               hcp      -- パーティ情報マスタ
          ,gl_code_combinations     gcc      -- 勘定科目組合せマスタ
        WHERE  1 = 1
        AND    jgblc.customer_id         = hca.cust_account_id(+)
        AND    hca.party_id              = hcp.party_id(+)
        AND    jgblc.set_of_books_id     = 2001
        AND    jgblc.currency_code       = 'JPY'
        -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        --  条件指定
        --■会計期間
        AND    jgblc.period_name         = iv_period_name
        --■勘定科目
        AND    gcc.segment3              = '14500'--未収入金
        -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        AND    jgblc.code_combination_id = gcc.code_combination_id
        GROUP BY
         hca.account_number
        ,hcp.party_name
        ,jgblc.period_name
        ,gcc.segment3
        ,gcc.segment4
        ORDER BY
         hca.account_number
        ,gcc.segment3
        ;
    -- レコード型
    jg_balance_rec jg_balance_cur%ROWTYPE;
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
    -- init部
    -- ===============================
      -- ★パラメータ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '対象期間: ' || iv_period_name
      );
      -- 空行出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => NULL
      );
      -- ★各処理で必要なプロファイル値、クイックコード値を固定値で設定
  --
      -- ===============================
      -- 処理部
      -- ===============================
  --
      -- 項目名出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => '"顧客番号","顧客名","会計期間","勘定科目","勘定科目名","補助科目","補助科目名","期首借方","期首貸方","期首残","期中借方","期中貸方","期中残","期末残"'
      );
      -- データ部出力(CSV)
      FOR jg_balance_rec IN jg_balance_cur
       LOOP
         --件数セット
         gn_target_cnt := gn_target_cnt + 1;
         --変更する項目及びキー情報を出力
         FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => '"'|| jg_balance_rec.account_number               || '","'
                         || jg_balance_rec.party_name                   || '","'
                         || jg_balance_rec.period_name                  || '","'
                         || jg_balance_rec.aff_account_code             || '","'
                         || jg_balance_rec.aff_account_name             || '","'
                         || jg_balance_rec.aff_sub_account_cooe         || '","'
                         || jg_balance_rec.aff_sub_account_name         || '","'
                         || jg_balance_rec.sum_begin_bal_accounted_dr   || '","'
                         || jg_balance_rec.sum_begin_bal_accounted_cr   || '","'
                         || jg_balance_rec.remain_begin_bal_accounted   || '","'
                         || jg_balance_rec.sum_period_net_accounted_dr  || '","'
                         || jg_balance_rec.sum_period_net_accounted_cr  || '","'
                         || jg_balance_rec.remain_period_net_accounted  || '","'
                         || jg_balance_rec.remain_end_bal_accounted     || '"'
         );
      END LOOP;
  --
      -- 成功件数＝対象件数
      gn_normal_cnt  := gn_target_cnt;
      -- 対象件数=0であれば警告
      IF (gn_target_cnt = 0) THEN
        gn_warn_cnt    := 1;
        ov_retcode     := cv_status_warn;
      END IF;
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
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode         OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name  IN  VARCHAR2       --   会計期間
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
       iv_period_name -- 会計期間
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
      gn_error_cnt := 1;
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
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
--###########################  固定部 END   #######################################################
--
END XXCCP009A11C;
/
