CREATE OR REPLACE PACKAGE BODY XXCCP009A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A10C(body)
 * Description      : AR-不明入金仮受金（貸方）詳細取得
 * MD.070           : AR-不明入金仮受金（貸方）詳細取得 (MD070_IPO_CCP_009_A10)
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP009A10C'; -- パッケージ名
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
    iv_period_name  IN  VARCHAR2,     --   会計期間
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- AR-不明入金仮受金（貸方）取得
    CURSOR unid_sus_receipt_cur
      IS
        SELECT /*+ USE_NL(acra arm arc fu papf base_hp base_hc gcc araa)
               */
           acra.creation_date             AS creation_date           -- 入金作成日
          ,acra.receipt_number            AS receipt_number          -- 入金番号
          ,acra.doc_sequence_value        AS doc_sequence_value      -- 文書番号
          ,acra.receipt_date              AS receipt_date            -- 入金日
          ,acra.amount                    AS amount                  -- 入金額
          ,(SELECT cash_hc.account_number
            FROM   hz_parties       cash_hp
                  ,hz_cust_accounts cash_hc
            WHERE  acra.pay_from_customer = cash_hc.cust_account_id
            AND    cash_hc.party_id = cash_hp.party_id
            AND    cash_hc.status   = 'A'
           )                              AS pay_from_cust_code      -- 入金顧客番号
          ,(SELECT cash_hp.party_name
            FROM   hz_parties       cash_hp
                  ,hz_cust_accounts cash_hc
            WHERE  acra.pay_from_customer = cash_hc.cust_account_id
            AND    cash_hc.party_id = cash_hp.party_id
            AND    cash_hc.status   = 'A'
           )                              AS pay_from_cust_name      -- 入金顧客名
          ,DECODE( acra.status
                  ,'CCRR'    , 'クレジット・カード返済戻し処理'
                  ,'NSF'     , '銀行決済不可'
                  ,'STOP'    , '支払停止'
                  ,'APP'     , '消込済'
                  ,'UNID'    , '不明'
                  ,'UNAPP'   , '未消込'
                  ,'REV'     , '戻し処理-ユーザー・エラー')
                                          AS receipt_status          -- 入金ステータス
          ,arc.name                       AS receipt_class           -- 入金区分
          ,arm.name                       AS receipt_method          -- 支払方法
          ,acra.attribute1                AS kana_name               -- 振込人カナ名
          ,papf.full_name                 AS last_updated_name       -- 最終更新者
          ,acra.last_update_date          AS last_update_date        -- 最終更新日
          ,base_hc.account_number         AS base_code               -- 拠点コード
          ,base_hp.party_name             AS base_name               -- 拠点名
          ,NVL(araa.amount_applied,0)     AS amount_applied          -- 消込額
        FROM   ar_cash_receipts_all       acra       -- AR入金テーブル
          ,ar_receipt_methods             arm        -- AR支払方法テーブル
          ,ar_receipt_classes             arc        -- AR入金区分テーブル
          ,fnd_user                       fu         -- ユーザーマスタ
          ,per_all_people_f               papf       -- 従業員マスタ
          ,hz_parties                     base_hp    -- パーティ情報マスタ
          ,hz_cust_accounts               base_hc    -- 顧客マスタ
          ,ar_receivable_applications_all araa       -- 入金消込テーブル
          ,gl_code_combinations           gcc        -- 勘定科目組合せマスタ
        WHERE  1 = 1
        --AND    acra.org_id            = 2424
        AND    acra.receipt_method_id = arm.receipt_method_id
        AND    arm.receipt_class_id   = arc.receipt_class_id
        AND    acra.last_updated_by   = fu.user_id
        AND    fu.employee_id         = papf.person_id
        AND    papf.current_employee_flag = 'Y'
        AND    acra.last_update_date BETWEEN papf.effective_start_date AND papf.effective_end_date
        AND    papf.attribute28       = base_hc.account_number
        AND    base_hc.party_id       = base_hp.party_id
        AND    base_hc.customer_class_code = '1'
        AND    base_hc.status              = 'A'
        AND   araa.gl_date >= TO_DATE(iv_period_name, 'YYYY-MM')
        AND   araa.gl_date <= ADD_MONTHS(TO_DATE(iv_period_name, 'YYYY-MM'),1) -1
        AND   araa.application_type = 'CASH'
        AND   araa.amount_applied   > 0                           -- 仮受金 プラス=貸方 (マイナス金額=借方)
        AND   araa.code_combination_id = gcc.code_combination_id
        AND   gcc.segment3          IN ('41803')                  -- 仮受金
        AND   araa.status           = 'UNID'
        AND   araa.cash_receipt_id  = acra.cash_receipt_id
        ;
    -- レコード型
    unid_sus_receipt_rec unid_sus_receipt_cur%ROWTYPE;
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
      ,buff   => '"入金作成日","入金番号","文書番号","入金日","入金額","入金顧客番号","入金顧客名","入金ステータス","入金区分","支払方法","振込人カナ名","最終更新者","最終更新日","拠点コード","拠点名","消込額"'
    );
    -- データ部出力(CSV)
    FOR unid_sus_receipt_rec IN unid_sus_receipt_cur
     LOOP
       --件数セット
       gn_target_cnt := gn_target_cnt + 1;
       --変更する項目及びキー情報を出力
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => '"'|| TO_CHAR(unid_sus_receipt_rec.creation_date, 'YYYY/MM/DD HH24:MI:SS')              || '","'
                       || unid_sus_receipt_rec.receipt_number                                               || '","'
                       || unid_sus_receipt_rec.doc_sequence_value                                           || '","'
                       || TO_CHAR(unid_sus_receipt_rec.receipt_date, 'YYYY/MM/DD HH24:MI:SS')               || '","'
                       || unid_sus_receipt_rec.amount                                                       || '","'
                       || unid_sus_receipt_rec.pay_from_cust_code                                           || '","'
                       || unid_sus_receipt_rec.pay_from_cust_name                                           || '","'
                       || unid_sus_receipt_rec.receipt_status                                               || '","'
                       || unid_sus_receipt_rec.receipt_class                                                || '","'
                       || unid_sus_receipt_rec.receipt_method                                               || '","'
                       || unid_sus_receipt_rec.kana_name                                                    || '","'
                       || unid_sus_receipt_rec.last_updated_name                                            || '","'
                       || TO_CHAR(unid_sus_receipt_rec.last_update_date, 'YYYY/MM/DD HH24:MI:SS')           || '","'
                       || unid_sus_receipt_rec.base_code                                                    || '","'
                       || unid_sus_receipt_rec.base_name                                                    || '","'
                       || unid_sus_receipt_rec.amount_applied                                               || '"'
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
END XXCCP009A10C;
/
