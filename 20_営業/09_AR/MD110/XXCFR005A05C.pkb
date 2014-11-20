CREATE OR REPLACE PACKAGE BODY XXCFR005A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A05C(body)
 * Description      : ロックボックス消込処理
 * MD.050           : MD050_CFR_005_A05_ロックボックス消込処理
 * MD.070           : MD050_CFR_005_A05_ロックボックス消込処理
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  start_apply_api        入金消込API起動処理 (A-4)
 *  delete_rockbox_wk      ロックボックス入金消込ワークテーブル削除 (A-5)
 *  submain                メイン処理プロシージャ
 *                           ロックボックス入金消込ワークテーブル取得 (A-2)
 *                           対象取引データ取得処理 (A-3)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/14    1.00 SCS 石渡 賢和    初回作成
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  --*** ロックエラー例外ハンドラ ***
  global_lock_err_expt          EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCFR005A05C';         -- パッケージ名
  cv_msg_kbn_cfr        CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_005a05_003     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003';      -- ロックエラー
  cv_msg_005a05_004     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004';      -- プロファイル取得エラー
  cv_msg_005a05_007     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007';      -- データ削除エラー(OTHERS)
  cv_msg_005a05_024     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024';      -- 対象データなしメッセージ
  cv_msg_005a05_025     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00025';      -- 警告件数メッセージ
  cv_msg_005a05_104     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00036';      -- 入金消込APIエラー
  cv_msg_005a05_108     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00108';      -- 入力パラメータ「パラレル実行区分」未設定エラー
  cv_msg_005a05_109     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00109';      -- 対象債権データなしエラー
  cv_msg_005a05_112     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00112';      -- 処理対象外件数
  cv_msg_005a05_125     CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00125';      -- 入力パラメータ「パラレル実行区分」数値チェックエラー
--
-- トークン
  cv_tkn_prof           CONSTANT VARCHAR2(15) := 'PROF_NAME';             -- プロファイル名
  cv_tkn_table          CONSTANT VARCHAR2(15) := 'TABLE';                 -- テーブル名
  cv_tkn_receipt_number CONSTANT VARCHAR2(15) := 'RECEIPT_NUMBER';        -- 入金番号
  cv_tkn_account_number CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';          -- 顧客コード
  cv_tkn_receipt_method CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';       -- 支払方法
  cv_tkn_receipt_date   CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';          -- 入金日
  cv_tkn_amount         CONSTANT VARCHAR2(15) := 'AMOUNT';                -- 金額
  cv_tkn_trx_number     CONSTANT VARCHAR2(15) := 'TRX_NUMBER';            -- 請求書番号
  cv_tkn_count          CONSTANT VARCHAR2(15) := 'COUNT';                 -- 件数
--
--
  -- テーブル名
  cv_tkn_t_tab          CONSTANT VARCHAR2(30) := 'XXCFR_ROCKBOX_WK';      -- ロックボックス入金消込ワークテーブル
--
--
  --プロファイル
  cv_limit_of_count     CONSTANT VARCHAR2(30) := 'XXCFR1_LIMIT_OF_COUNT'; -- XXCFR:対象件数閾値
--
  -- ファイル出力
  cv_file_type_out      CONSTANT VARCHAR2(10) := 'OUTPUT';                -- メッセージ出力
  cv_file_type_log      CONSTANT VARCHAR2(10) := 'LOG';                   -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- 日付フォーマット（年月日）
--
  -- リテラル値
  cv_one                CONSTANT VARCHAR2(10) := '1';                     -- 消込要否フラグ(要)
  cn_parallel_type_0    CONSTANT NUMBER       :=  0;                      -- パラレル実行区分「0」
  cv_y                  CONSTANT VARCHAR2(10) := 'Y';                     -- 文字列「Y」
  cv_n                  CONSTANT VARCHAR2(10) := 'N';                     -- 文字列「N」
--
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_parallel_type      NUMBER;             -- パラレル実行区分(NUMBER型)
  gn_limit_of_count     NUMBER;             -- 対象件数閾値
  --
  gn_no_target_cnt      NUMBER;             -- 処理対象外件数
  --
  gn_api_sucs_cnt       NUMBER;             -- 消込成功債権件数
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_parallel_type       IN      VARCHAR2,         -- パラレル実行区分
    iv_lmt_of_cnt_flg      IN      VARCHAR2,         -- 対象件数閾値使用フラグ
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・例外 ***
    in_param_null_expt       EXCEPTION;  -- 入力パラメータ「パラレル実行区分」未設定例外
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
    -- コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,iv_conc_param1  => iv_parallel_type   -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_lmt_of_cnt_flg  -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUTファイル出力
      ,iv_conc_param1  => iv_parallel_type   -- コンカレントパラメータ１
      ,iv_conc_param2  => iv_lmt_of_cnt_flg  -- コンカレントパラメータ２
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 入力パラメータ「パラレル実行区分」が未設定の場合
    IF ( iv_parallel_type IS NULL ) THEN
      RAISE in_param_null_expt;
    ELSE
      -- 入力パラメータ「パラレル実行区分」数値チェック
      BEGIN
        gn_parallel_type := TO_NUMBER( iv_parallel_type );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- アプリケーション短縮名
                                               ,iv_name         => cv_msg_005a05_125);  -- メッセージ
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
    --
--
    --==============================================================
    -- プロファイルオプション値の取得
    --==============================================================
    -- プロファイル：XXCFR:対象件数閾値
    gn_limit_of_count := TO_NUMBER( FND_PROFILE.VALUE(cv_limit_of_count) );
    -- 取得エラー時
    IF (gn_limit_of_count IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_005a05_004    -- メッセージ
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_limit_of_count);  -- トークン：XXCFR1_LIMIT_OF_COUNT
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 入力パラメータ「パラレル実行区分」未設定例外ハンドラ ***
    WHEN in_param_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr      -- アプリケーション短縮名
                                            ,iv_name         => cv_msg_005a05_108); -- メッセージ
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : start_apply_api
   * Description      : 入金消込API起動処理 (A-4)
   ***********************************************************************************/
  PROCEDURE start_apply_api(
    in_cash_receipt_id       IN  NUMBER,   --   入金ID
    iv_receipt_number        IN  VARCHAR2, --   入金番号
    id_receipt_date          IN  DATE,     --   入金日
    in_amount                IN  NUMBER,   --   入金額
    iv_receipt_method        IN  VARCHAR2, --   支払方法
    iv_account_number        IN  VARCHAR2, --   顧客コード
    in_customer_trx_id       IN  NUMBER,   --   取引ヘッダID
    iv_trx_number            IN  VARCHAR2, --   取引番号
    in_amount_due_remaining  IN  NUMBER,   --   未回収残高
    ov_errbuf                OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_apply_api'; -- プログラム名
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
    --
    PRAGMA AUTONOMOUS_TRANSACTION; -- 自律型トランザクション 
    --
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- 入金消込API起動
    ar_receipt_api_pub.apply(
       p_api_version     =>  1.0
      ,p_init_msg_list   =>  FND_API.G_TRUE
      ,p_commit          =>  FND_API.G_FALSE
      ,x_return_status   =>  lv_return_status
      ,x_msg_count       =>  ln_msg_count
      ,x_msg_data        =>  lv_msg_data
      ,p_customer_trx_id =>  in_customer_trx_id        -- 取引ヘッダID
      ,p_cash_receipt_id =>  in_cash_receipt_id        -- 入金ID
      ,p_amount_applied  =>  in_amount_due_remaining   -- 消込金額
      ,p_apply_date      =>  id_receipt_date           -- 消込日
      ,p_apply_gl_date   =>  id_receipt_date           -- GL記帳日
      );
--
    IF    (lv_return_status  = 'S') THEN
      -- 正常ならばコミット
      COMMIT;
    ELSE
      --エラー処理
      --入金消込APIエラーメッセージ出力
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr                                 -- 'XXCFR'
                     ,iv_name         => cv_msg_005a05_104                              -- 入金消込API
                     ,iv_token_name1  => cv_tkn_receipt_number                          -- トークン'RECEIPT_NUMBER'
                     ,iv_token_value1 => iv_receipt_number                              -- 入金番号
                     ,iv_token_name2  => cv_tkn_account_number                          -- トークン'ACCOUNT_NUMBER'
                     ,iv_token_value2 => iv_account_number                              -- 顧客コード
                     ,iv_token_name3  => cv_tkn_receipt_method                          -- トークン'RECEIPT_MEATHOD'
                     ,iv_token_value3 => iv_receipt_method                              -- 支払方法
                     ,iv_token_name4  => cv_tkn_receipt_date                            -- トークン'RECEIPT_DATE'
                     ,iv_token_value4 => TO_CHAR(id_receipt_date, cv_format_date_ymd)   -- 入金日
                     ,iv_token_name5  => cv_tkn_amount                                  -- トークン'AMOUNT'
                     ,iv_token_value5 => in_amount                                      -- 入金額
                     ,iv_token_name6  => cv_tkn_trx_number                              -- トークン'TRX_NUMBER'
                     ,iv_token_value6 => iv_trx_number );                               -- 取引番号
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API標準エラーメッセージ出力
      IF (ln_msg_count = 1) THEN
        -- API標準エラーメッセージが１件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || lv_msg_data
        );
--
      ELSE
        -- API標準エラーメッセージが複数件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          --
        END LOOP while_loop;
--
      END IF;
      -- 警告ならばロールバック
      ROLLBACK;
      -- 警告セット
      ov_retcode := cv_status_warn;
    END IF;
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
  END start_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_rockbox_wk
   * Description      : ロックボックス入金消込ワークテーブル削除 (A-5)
   ***********************************************************************************/
  PROCEDURE delete_rockbox_wk(
    in_parallel_type   IN      NUMBER,           -- パラレル実行区分
    iv_lmt_of_cnt_flg  IN      VARCHAR2,         -- 対象件数閾値使用フラグ
    ov_errbuf          OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg          OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rockbox_wk'; -- プログラム名
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
    -- ロックボックス入金消込ワークテーブルの削除
    BEGIN
      DELETE FROM xxcfr_rockbox_wk
      WHERE  ((   in_parallel_type    <> cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0以外の場合
              AND parallel_type    = in_parallel_type              -- 入力パラメータ「パラレル実行区分」が一致
              -- 対象件数閾値使用フラグ = 'Y'
              AND ((   iv_lmt_of_cnt_flg  = cv_y
                   AND apply_trx_count   <= gn_limit_of_count      -- 消込対象件数 ＜= A-1で取得した対象件数閾値
                   )
                  OR ( iv_lmt_of_cnt_flg  = cv_n )
                  )
              )
             OR
              (   in_parallel_type     = cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0の場合
              ))
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfr     -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_005a05_007  -- メッセージ
                                             ,iv_token_name1  => cv_tkn_table       -- トークンコード
                                             ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_t_tab)
                                                                                    -- トークン：ロックボックス入金消込ワークテーブル
                                             );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END delete_rockbox_wk;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_parallel_type       IN      VARCHAR2,         -- パラレル実行区分
    iv_lmt_of_cnt_flg      IN      VARCHAR2,         -- 対象件数閾値使用フラグ
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
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
    cv_account_class_rec CONSTANT VARCHAR2(10) := 'REC';      -- アカウントクラス
--
    -- *** ローカル変数 ***
    lv_lmt_of_cnt_flg   VARCHAR2(1);                          -- 対象件数閾値使用フラグ
    ln_total_cash_cnt   NUMBER;                               -- 全入金データ件数
    ln_cust_trx_cnt     NUMBER;                               -- 対象取引データ件数
    ln_cust_trx_err_cnt NUMBER;                               -- 消込失敗債権件数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --ロックボックス入金消込ワークテーブルロック用カーソル
    CURSOR get_lock_rockbox_wk_cur
    IS
    SELECT 'X'
    FROM   xxcfr_rockbox_wk xrw                                  -- ロックボックス入金消込ワークテーブル
    WHERE  ((   gn_parallel_type    <> cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0以外の場合
            AND xrw.parallel_type    = gn_parallel_type          -- 入力パラメータ「パラレル実行区分」が一致
            -- 対象件数閾値使用フラグ = 'Y'
            AND ((   lv_lmt_of_cnt_flg    = cv_y
                 AND xrw.apply_trx_count <= gn_limit_of_count    -- 消込対象件数 ＜= A-1で取得した対象件数閾値
                 )
                OR ( lv_lmt_of_cnt_flg    = cv_n )
                )
            )
           OR
            (   gn_parallel_type     = cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0の場合
            ))
    FOR UPDATE NOWAIT
    ;
--
    --ロックボックス入金消込ワークテーブル取得カーソル
    CURSOR get_rockbox_wk_cur
    IS
      SELECT  xrw.cash_receipt_id     cash_receipt_id              -- 入金内部ID
             ,xrw.account_number      cash_acct_number             -- 顧客番号
             ,xrw.cust_account_id     cash_cust_acct_id            -- 入金先顧客ID
             ,xrw.receipt_number      receipt_number               -- 入金番号
             ,xrw.receipt_date        receipt_date                 -- 入金日
             ,xrw.amount              receipt_amount               -- 入金額
             ,xrw.receipt_method_name receipt_method_name          -- 支払方法名
      FROM    xxcfr_rockbox_wk        xrw                          -- ロックボックス入金消込ワークテーブル
      WHERE  ((   gn_parallel_type     <> cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0以外の場合
              AND xrw.parallel_type     = gn_parallel_type          -- 入力パラメータ「パラレル実行区分」が一致
              AND xrw.apply_flag        = cv_one                    -- 消込要否フラグ＝ '1'(要)
              -- 対象件数閾値使用フラグ = 'Y'
              AND ((   lv_lmt_of_cnt_flg    = cv_y
                   AND xrw.apply_trx_count <= gn_limit_of_count    -- 消込対象件数 ＜= A-1で取得した対象件数閾値
                   )
                  OR ( lv_lmt_of_cnt_flg    = cv_n )
                  )
              )
             OR
              (   gn_parallel_type      = cn_parallel_type_0        -- 入力パラメータ「パラレル実行区分」が 0の場合
              AND xrw.apply_flag        = cv_one ))                 -- 消込要否フラグ＝ '1'(要)
    ;
--
    lt_rockbox_wk_rec   get_rockbox_wk_cur%ROWTYPE;
--
    --対象取引データ取得カーソル
    CURSOR ra_customer_trx_cur(
      in_pay_from_customer NUMBER) --入金先顧客ID
    IS
      SELECT 
            xrctmv.customer_trx_id       customer_trx_id           -- 取引ヘッダID
           ,xrctmv.trx_number            trx_number                -- 取引番号
           ,xrctmv.amount_due_remaining  amount_due_remaining      -- 未回収残高
      FROM  xxcfr_rock_cust_trx_mv   xrctmv                        -- 顧客債権マテリアライズドビュー
           ,xxcfr_cust_hierarchy_mv  xchmv                         -- 顧客階層マテリアライズドビュー
      WHERE xrctmv.bill_to_customer_id = xchmv.bill_account_id
        AND xchmv.cash_account_id      = in_pay_from_customer      -- 入金先顧客ID
      ORDER BY xrctmv.amount_due_remaining
    ;
--
    lt_ra_customer_trx_rec   ra_customer_trx_cur%ROWTYPE;
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
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
    gn_no_target_cnt := 0;
    gn_api_sucs_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
-- 
    -- =====================================================
    --  初期処理 (A-1)
    -- =====================================================
    init(
       iv_parallel_type   => iv_parallel_type       -- パラレル実行区分
      ,iv_lmt_of_cnt_flg  => iv_lmt_of_cnt_flg      -- 対象件数閾値使用フラグ
      ,ov_errbuf          => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    --
    -- 入力パラメータ「対象件数閾値使用フラグ」が未設定の場合
    lv_lmt_of_cnt_flg := NVL( iv_lmt_of_cnt_flg, cv_n ); -- Nをセット
    --
--
    -- =====================================================
    --  ロックボックス入金消込ワークテーブル取得 (A-2)
    -- =====================================================
    -- ロックの取得
    OPEN  get_lock_rockbox_wk_cur;
    CLOSE get_lock_rockbox_wk_cur;
    --
    -- ロックボックス入金消込ワークテーブルの対象全入金データ件数取得
    SELECT COUNT(1)
    INTO   ln_total_cash_cnt                               -- 全入金データ件数
    FROM   xxcfr_rockbox_wk xrw                            -- ロックボックス入金消込ワークテーブル
    WHERE  ((   gn_parallel_type <> cn_parallel_type_0     -- 入力パラメータ「パラレル実行区分」が 0以外の場合
            AND xrw.parallel_type = gn_parallel_type       -- パラレル実行区分が一致
            AND xrw.apply_flag    = cv_one )               -- 消込要否フラグ＝ '1'(要)
           OR
            (   gn_parallel_type  = cn_parallel_type_0     -- 入力パラメータ「パラレル実行区分」が 0の場合
            AND xrw.apply_flag    = cv_one ))              -- 消込要否フラグ＝ '1'(要)
    ;
    --
    -- 閾値以下のロックボックス入金消込ワークテーブルデータ取得
    BEGIN
      -- カーソルオープン
      OPEN get_rockbox_wk_cur;
--
      -- ロックボックスワークテーブル取得ループ開始
      <<rockbox_wk_loop>>
      LOOP
        -- データの取得
        FETCH get_rockbox_wk_cur INTO lt_rockbox_wk_rec;
        EXIT WHEN get_rockbox_wk_cur%NOTFOUND;
--
        -- =====================================================
        --  対象取引データ取得処理 (A-3)
        -- =====================================================
        -- カーソルオープン
        OPEN ra_customer_trx_cur( lt_rockbox_wk_rec.cash_cust_acct_id );   -- 入金先顧客ID
--
        -- 対象取引データループ内件数初期化
        ln_cust_trx_cnt     := 0;                                          -- 対象取引データ件数
        ln_cust_trx_err_cnt := 0;                                          -- 消込失敗債権件数
--
        -- 対象取引データループ開始
        <<ra_customer_trx_loop>>
        LOOP
          -- データの取得
          FETCH ra_customer_trx_cur INTO lt_ra_customer_trx_rec;
          EXIT WHEN ra_customer_trx_cur%NOTFOUND;
--
          -- =====================================================
          --  入金消込API起動処理 (A-4)
          -- =====================================================
          start_apply_api(
             in_cash_receipt_id      => lt_rockbox_wk_rec.cash_receipt_id            -- 入金ID
            ,iv_receipt_number       => lt_rockbox_wk_rec.receipt_number             -- 入金番号
            ,id_receipt_date         => lt_rockbox_wk_rec.receipt_date               -- 入金日
            ,in_amount               => lt_rockbox_wk_rec.receipt_amount             -- 入金額
            ,iv_receipt_method       => lt_rockbox_wk_rec.receipt_method_name        -- 支払方法
            ,iv_account_number       => lt_rockbox_wk_rec.cash_acct_number           -- 顧客コード
            ,in_customer_trx_id      => lt_ra_customer_trx_rec.customer_trx_id       -- 取引ヘッダID
            ,iv_trx_number           => lt_ra_customer_trx_rec.trx_number            -- 取引番号
            ,in_amount_due_remaining => lt_ra_customer_trx_rec.amount_due_remaining  -- 未回収残高
            ,ov_errbuf               => lv_errbuf                                    -- エラー・メッセージ           --# 固定 #
            ,ov_retcode              => lv_retcode                                   -- リターン・コード             --# 固定 #
            ,ov_errmsg               => lv_errmsg);                                  -- ユーザー・エラー・メッセージ --# 固定 #
        
          -- 正常処理チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            ln_cust_trx_err_cnt := ln_cust_trx_err_cnt + 1;      -- 消込失敗債権件数
          ELSE
            gn_api_sucs_cnt      := gn_api_sucs_cnt    + 1;      -- 消込成功債権件数
          END IF;
--
        -- サブループ終了
        END LOOP ra_customer_trx_loop;
--
        -- 件数を退避
        ln_cust_trx_cnt := ra_customer_trx_cur%ROWCOUNT;
        --
        -- 対象取引データがゼロ件の場合
        IF ( ln_cust_trx_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cfr                                 -- 'XXCFR'
                         ,iv_name         => cv_msg_005a05_109                              -- 入金消込API
                         ,iv_token_name1  => cv_tkn_receipt_number                          -- トークン'RECEIPT_NUMBER'
                         ,iv_token_value1 => lt_rockbox_wk_rec.receipt_number               -- 入金番号
                         ,iv_token_name2  => cv_tkn_account_number                          -- トークン'ACCOUNT_NUMBER'
                         ,iv_token_value2 => lt_rockbox_wk_rec.cash_acct_number             -- 顧客コード
                         ,iv_token_name3  => cv_tkn_receipt_method                          -- トークン'RECEIPT_MEATHOD'
                         ,iv_token_value3 => lt_rockbox_wk_rec.receipt_method_name          -- 支払方法
                         ,iv_token_name4  => cv_tkn_receipt_date                            -- トークン'RECEIPT_DATE'
                         ,iv_token_value4 => TO_CHAR(lt_rockbox_wk_rec.receipt_date
                                                   , cv_format_date_ymd)                    -- 入金日
                         ,iv_token_name5  => cv_tkn_amount                                  -- トークン'AMOUNT'
                         ,iv_token_value5 => lt_rockbox_wk_rec.receipt_amount );            -- 入金額
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
        -- カーソルクローズ
        CLOSE ra_customer_trx_cur;
        --
        -- 債権件数が0件以外の場合
        IF (  ( ln_cust_trx_err_cnt > 0 ) 
           OR ( ln_cust_trx_cnt     = 0 ) )
        THEN
          -- 警告件数カウント
          gn_warn_cnt   := gn_warn_cnt + 1;
        ELSE
          -- 正常件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      -- メインループ終了
      END LOOP ar_cash_receipts_loop;
--
      -- 対象件数カウント
      gn_target_cnt := get_rockbox_wk_cur%ROWCOUNT;
--
      -- カーソルクローズ
      CLOSE get_rockbox_wk_cur;
    --
    -- OTHERS例外処理
    EXCEPTION
      WHEN OTHERS THEN
        -- カーソルのクローズ
        IF( ra_customer_trx_cur%ISOPEN ) THEN
          CLOSE ra_customer_trx_cur;
        END IF;
        IF( get_rockbox_wk_cur%ISOPEN  ) THEN
          CLOSE get_rockbox_wk_cur;
        END IF;
        -- 
        lv_errmsg  := NULL;
        lv_errbuf  := SQLERRM;
        --
        RAISE global_process_expt;
    END;
    --
    -- 処理対象外件数の算出
    gn_no_target_cnt :=  ln_total_cash_cnt - gn_target_cnt;
--
    -- =====================================================
    --  ロックボックス入金消込ワークテーブル削除 (A-5)
    -- =====================================================
    delete_rockbox_wk (
       in_parallel_type  => gn_parallel_type       -- パラレル実行区分
      ,iv_lmt_of_cnt_flg => lv_lmt_of_cnt_flg      -- 対象件数閾値使用フラグ
      ,ov_errbuf         => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode        => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg         => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    -- 正常処理チェック
    IF (lv_retcode <> cv_status_normal) THEN
      -- エラー件数のカウント
      gn_error_cnt := 1;
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --対象データなしメッセージの判定
    IF ( gn_target_cnt = 0 ) THEN
      --
      ov_errmsg := xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr          -- アプリケーション短縮名
                                           ,cv_msg_005a05_024 );    -- メッセージ
      ov_errbuf := ov_errmsg;
    END IF;
    --
    --リターン・コードの設定
    IF (gn_warn_cnt > 0) THEN
      -- 警告セット
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ****
    WHEN global_lock_err_expt THEN
      -- カーソルがOPENしているならばカーソルをCLOSE
      IF( get_rockbox_wk_cur%ISOPEN ) THEN
        CLOSE get_rockbox_wk_cur;
      END IF;
      --
    --取得結果がNULLならばエラー
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr     -- アプリケーション短縮名：XXCFR
                                            ,iv_name         => cv_msg_005a05_003  -- メッセージ：APP-XXCFR1-00003
                                            ,iv_token_name1  => cv_tkn_table       -- トークンコード
                                            ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_tkn_t_tab)
                                                                                   -- トークン：ロックボックス入金消込ワークテーブル
                                           );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                 OUT     VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_parallel_type       IN      VARCHAR2,      --   パラレル実行区分
    iv_lmt_of_cnt_flg      IN      VARCHAR2       --   対象件数閾値使用フラグ
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
    cv_error_part_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- エラー終了一部処理メッセージ
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_parallel_type   => iv_parallel_type  -- パラレル実行区分
      ,iv_lmt_of_cnt_flg  => iv_lmt_of_cnt_flg -- 対象件数閾値使用フラグ
      ,ov_errbuf          => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,ov_retcode         => lv_retcode        -- リターン・コード             --# 固定 #
      ,ov_errmsg          => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー・警告出力
    IF ( ( lv_errmsg IS NOT NULL )
       OR( lv_errbuf IS NOT NULL ) ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                 --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                 --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- =====================================================
    --  終了処理 (A-6)
    -- =====================================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- アプリケーション短縮名
                    ,iv_name         => cv_target_rec_msg            -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)       -- トークン
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --処理対象外件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr               -- アプリケーション短縮名
                    ,iv_name         => cv_msg_005a05_112            -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード
                    ,iv_token_value1 => TO_CHAR(gn_no_target_cnt)    -- トークン
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- アプリケーション短縮名
                    ,iv_name         => cv_success_rec_msg           -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)       -- トークン
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfr               -- アプリケーション短縮名
                    ,iv_name         => cv_msg_005a05_025            -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)         -- トークン
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- アプリケーション短縮名
                    ,iv_name         => cv_error_rec_msg             -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)        -- トークン
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;                              -- 正常終了メッセージ
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;                                -- 警告終了メッセージ
    ELSIF(lv_retcode = cv_status_error) THEN
      -- 消込成功債権件数が1件以上
      IF ( gn_api_sucs_cnt > 0 ) THEN
        lv_message_code := cv_error_part_msg;                        -- エラー終了一部処理メッセージ
      ELSE
        lv_message_code := cv_error_msg;                             -- エラー終了全ロールバック
      END IF;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name           -- アプリケーション短縮名
                    ,iv_name         => lv_message_code              -- メッセージ
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFR005A05C;
/