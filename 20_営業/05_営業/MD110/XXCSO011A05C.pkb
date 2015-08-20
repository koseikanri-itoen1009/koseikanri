CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A05C (body)
 * Description      : 通信モデム設置可／不可変更処理
 * MD.050           : 通信モデム設置可／不可変更処理 (MD050_CSO_011A05)
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  data_validation        妥当性チェック(A-2)
 *  upd_install_base       物件マスタ更新(A-3)
 *  upd_hht_tran           HHT集配信連携トランザクション更新(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/06/25    1.0   S.Yamashita      main新規作成
 *  2015/08/19    1.1   S.Yamashita      [E_本稼動_12984]T4障害対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
  init_err_expt               EXCEPTION;  -- 初期処理エラー
  g_lock_expt                 EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT( g_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO011A05C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- 書式
  cv_format_ymd               CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  -- メッセージコード
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- 業務処理日付取得エラー
  cv_msg_cso_00014            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00014';          -- プロファイル取得エラー
  cv_msg_cso_00072            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00072';          -- データ削除エラーメッセージ
  cv_msg_cso_00278            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00278';          -- ロックエラーメッセージ
  cv_msg_cso_00329            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00329';          -- データ取得エラー
  cv_msg_cso_00330            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00330';          -- データ登録エラー
  cv_msg_cso_00337            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00337';          -- データ更新エラー
  cv_msg_cso_00343            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00343';          -- 取引タイプID抽出エラーメッセージ
  cv_msg_cso_00504            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00504';          -- 物件マスタ更新時エラー
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- 入力パラメータ用文字列
  cv_msg_cso_00696            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00696';          -- メッセージ用文字列(物件コード)
  cv_msg_cso_00707            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00707';          -- メッセージ用文字列(顧客コード)
  cv_msg_cso_00711            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00711';          -- メッセージ用文字列(取引タイプの取引タイプID)
  cv_msg_cso_00714            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00714';          -- メッセージ用文字列(物件マスタ)
  cv_msg_cso_00729            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00729';          -- メッセージ用文字列(判定区分)
  cv_msg_cso_00757            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00757';          -- メッセージ用文字列(HHT集配信連携トランザクション)
  cv_msg_cso_00762            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00762';          -- メッセージ用文字列(引揚物件コード)
  cv_msg_cso_00763            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00763';          -- メッセージ用文字列(顧客マスタ)
  cv_msg_cso_00764            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00764';          -- メッセージ用文字列(インスタンスパーティマスタ)
  cv_msg_cso_00765            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00765';          -- メッセージ用文字列(インスタンスアカウントマスタ)
  cv_msg_cso_00766            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00766';          -- メッセージ用文字列(物件マスタ更新)
  cv_msg_cso_00761            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00761';          -- 対象物件取得エラー
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 入力パラメータ名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 入力パラメータ値
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';                 -- プロファイル名
  cv_tkn_task_name            CONSTANT VARCHAR2(20)  := 'TASK_NAME';                 -- 項目名
  cv_tkn_action               CONSTANT VARCHAR2(20)  := 'ACTION';                    -- 実行している処理
  cv_tkn_key_name             CONSTANT VARCHAR2(20)  := 'KEY_NAME';                  -- 項目名
  cv_tkn_key_id               CONSTANT VARCHAR2(20)  := 'KEY_ID';                    -- 項目値
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';                 -- 顧客コード
  cv_tkn_install_code         CONSTANT VARCHAR2(20)  := 'INSTALL_CODE';              -- 物件コード
  cv_tkn_src_tran_type        CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';             -- ソーストランザクションタイプ
  cv_tkn_err_msg              CONSTANT VARCHAR2(20)  := 'ERR_MSG';                   -- SQLエラー
  cv_tkn_api_name             CONSTANT VARCHAR2(20)  := 'API_NAME';                  -- API名
  cv_tkn_api_msg              CONSTANT VARCHAR2(20)  := 'API_MSG';                   -- APIエラーメッセージ
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                     -- テーブル名
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
  cv_tkn_error_message        CONSTANT VARCHAR2(20)  := 'ERROR_MESSAGE';             -- エラーメッセージ
  cv_tkn_err_message          CONSTANT VARCHAR2(20)  := 'ERR_MESSAGE';               -- エラーメッセージ
  -- プロファイル名
  cv_prof_modem_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_MODEM_BASE_CODE';    -- XXCSO: 通信モデム拠点コード
  -- フラグ
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- 'N'
  -- 判定区分
  cv_kbn_1                    CONSTANT VARCHAR2(1)   := '1';                         -- '1'（設置可能→不可能）
  cv_kbn_2                    CONSTANT VARCHAR2(1)   := '2';                         -- '2'（設置不可能→可能）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;              -- 業務日付
  gv_modem_base_code          VARCHAR2(4);       -- 通信モデム拠点コード
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cust_code      IN  VARCHAR2      --   顧客コード
   ,iv_install_code   IN  VARCHAR2      --   引揚物件コード
   ,iv_kbn            IN  VARCHAR2      --   判定区分
   ,ov_errbuf         OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_cust_code       VARCHAR2(1000);  -- 顧客コード（メッセージ出力用）
    lv_install_code    VARCHAR2(1000);  -- 引揚物件コード（メッセージ出力用）
    lv_kbn             VARCHAR2(1000);  -- 判定区分（メッセージ出力用）
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
    -- ローカル変数初期化
    lv_cust_code    := NULL; -- 顧客コード
    lv_install_code := NULL; -- 引揚物件コード
    lv_kbn          := NULL; -- 判定区分
--
    --==============================================================
    -- 1.入力パラメータ出力
    --==============================================================
    -- 顧客コード
    lv_cust_code   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00707              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_cust_code                  -- トークン値2
                      );
    -- 判定区分が1（設置可能→不可能）の場合
    IF ( iv_kbn = cv_kbn_1 ) THEN
      -- 引揚物件コード
      lv_install_code := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                         ,iv_token_value1 => cv_msg_cso_00762              -- トークン値1
                         ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                         ,iv_token_value2 => iv_install_code               -- トークン値2
                        );
    END IF;
    -- 判定区分
    lv_kbn            := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00729              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_kbn                        -- トークン値2
                      );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''              || CHR(10) ||
                 lv_cust_code    || CHR(10) ||      -- 顧客コード
                 lv_install_code || CHR(10) ||      -- 引揚物件コード
                 lv_kbn                             -- 判定区分
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- 出力に出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''              || CHR(10) ||
                 lv_cust_code    || CHR(10) ||      -- 顧客コード
                 lv_install_code || CHR(10) ||      -- 引揚物件コード
                 lv_kbn                             -- 判定区分
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================================
    -- 2.プロファイル値取得
    --==================================================
    gv_modem_base_code := FND_PROFILE.VALUE( cv_prof_modem_base_code );
    -- プロファイルの取得に失敗した場合はエラー
    IF( gv_modem_base_code IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00014         -- メッセージコード
         ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
         ,iv_token_value1 => cv_prof_modem_base_code  -- トークン値1
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- 3.業務日付取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 業務日付の取得に失敗した場合はエラー
    IF( gd_process_date IS NULL )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00011     -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
   * Procedure Name   : data_validation
   * Description      : 妥当性チェック(A-2)
   ***********************************************************************************/
  PROCEDURE data_validation(
    iv_cust_code       IN  VARCHAR2      --   顧客コード
   ,iv_install_code    IN  VARCHAR2      --   引揚物件コード
   ,iv_kbn             IN  VARCHAR2      --   判定区分
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lt_cust_account_id hz_cust_accounts.cust_account_id%TYPE;  -- 顧客ID
    ln_count   NUMBER;   -- 件数カウント用
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    lt_cust_account_id := NULL;
    ln_count := 0;
--
    --==============================================================
    -- 1.顧客ID取得
    --==============================================================
    BEGIN
      SELECT hca.cust_account_id AS cust_account_id -- 顧客ID
      INTO   lt_cust_account_id
      FROM   hz_cust_accounts hca  -- 顧客マスタ
      WHERE  hca.account_number = iv_cust_code -- 顧客コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
           ,iv_name         => cv_msg_cso_00329     -- メッセージコード
           ,iv_token_name1  => cv_tkn_action        -- トークンコード1
           ,iv_token_value1 => cv_msg_cso_00763     -- トークン値1
           ,iv_token_name2  => cv_tkn_key_name      -- トークンコード2
           ,iv_token_value2 => cv_msg_cso_00707     -- トークン値2
           ,iv_token_name3  => cv_tkn_key_id        -- トークンコード3
           ,iv_token_value3 => iv_cust_code         -- トークン値3
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 判定区分が1（設置可能→不可能）の場合
    IF ( iv_kbn = cv_kbn_1 ) THEN
    --==============================================================
    -- 2.物件マスタ取得
    --==============================================================
      SELECT COUNT(*) AS cnt -- 件数
      INTO   ln_count
      FROM   csi_item_instances cii -- 物件マスタ
      WHERE  cii.owner_party_account_id = lt_cust_account_id  -- 顧客ID
      AND    cii.external_reference     = iv_install_code     -- 物件コード
      ;
--
      -- 取得できない場合
      IF ( ln_count = 0 ) THEN
        -- 対象物件取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
            iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
           ,iv_name         => cv_msg_cso_00761     -- メッセージコード
           ,iv_token_name1  => cv_tkn_action        -- トークンコード1
           ,iv_token_value1 => cv_msg_cso_00714     -- トークン値1
           ,iv_token_name2  => cv_tkn_cust_code     -- トークンコード2
           ,iv_token_value2 => iv_cust_code         -- トークン値2
           ,iv_token_name3  => cv_tkn_install_code  -- トークンコード3
           ,iv_token_value3 => iv_install_code      -- トークン値3
        );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 件数初期化
    ln_count := 0;
--
    --==============================================================
    -- 2.HHT集配信連携トランザクション取得
    --==============================================================
    -- 判定区分が1（設置可能→不可能）の場合
    IF ( iv_kbn = cv_kbn_1 ) THEN
      SELECT COUNT(*) AS cnt -- 件数
      INTO   ln_count
      FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT集配信連携トランザクション
      WHERE  xhcdct.account_number = iv_cust_code    -- 顧客コード
      AND    xhcdct.install_code   = iv_install_code -- 物件コード
      AND    xhcdct.cooperate_flag = cv_flag_y       -- 連携フラグ
      AND    xhcdct.install_psid   IS NOT NULL       -- 設置PSID
      ;
    -- 判定区分が2（設置不可能→可能）の場合
    ELSIF ( iv_kbn = cv_kbn_2 ) THEN
      SELECT COUNT(*) AS cnt -- 件数
      INTO   ln_count
      FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT集配信連携トランザクション
      WHERE  xhcdct.account_number       = iv_cust_code  -- 顧客コード
      AND    xhcdct.creating_source_code = cv_pkg_name   -- 発生元ソースコード
      AND    xhcdct.cooperate_flag       = cv_flag_y     -- 連携フラグ
      AND    xhcdct.withdraw_psid        IS NOT NULL     -- 引揚PSID
      ;
    END IF;
--
    -- 取得できない場合
    IF ( ln_count = 0 ) THEN
      -- 対象物件取得エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
         ,iv_name         => cv_msg_cso_00761     -- メッセージコード
         ,iv_token_name1  => cv_tkn_action        -- トークンコード1
         ,iv_token_value1 => cv_msg_cso_00757     -- トークン値1
         ,iv_token_name2  => cv_tkn_cust_code     -- トークンコード2
         ,iv_token_value2 => iv_cust_code         -- トークン値2
         ,iv_token_name3  => cv_tkn_install_code  -- トークンコード3
         ,iv_token_value3 => iv_install_code      -- トークン値3
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数設定
    gn_target_cnt := ln_count;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : upd_install_base
   * Description      : 物件マスタ更新(A-3)
   ***********************************************************************************/
  PROCEDURE upd_install_base(
    iv_cust_code       IN  VARCHAR2      --   顧客コード
   ,iv_install_code    IN  VARCHAR2      --   引揚物件コード
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_install_base'; -- プログラム名
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
    cv_relationship_type_code CONSTANT VARCHAR2(100) := 'OWNER';          -- リレーションタイプコード
    cv_src_tran_type          CONSTANT VARCHAR2(5)   := 'IB_UI';          -- 取引タイプ
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';     -- パーティソーステーブル
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES'; -- ロケーションタイプコード
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';       -- 追加属性(地区コード)
    cn_one                    CONSTANT NUMBER        := 1;
    cn_api_version            CONSTANT NUMBER        := 1.0;
--
    -- *** ローカル変数 ***
    ln_count                      NUMBER;                                         -- 件数カウント用
    lt_instance_id                csi_item_instances.instance_id%TYPE;            -- インスタンスID
    lt_instance_object_vnum       csi_item_instances.object_version_number%TYPE;  -- オブジェクトバージョン番号
    lt_instance_party_id          csi_i_parties.instance_party_id%TYPE;           -- インスタンスパーティID
    lt_instance_party_object_vnum csi_i_parties.object_version_number%TYPE;       -- オブジェクトバージョン番号
    lt_ip_account_id              csi_ip_accounts.ip_account_id%TYPE;             -- インスタンスアカウントID
    lt_instance_acct_object_vnum  csi_ip_accounts.object_version_number%TYPE;     -- オブジェクトバージョン番号
    lt_transaction_type_id        csi_txn_types.transaction_type_id%TYPE;         -- 取引タイプID
    lt_withdraw_account_id        hz_cust_accounts.cust_account_id%TYPE;          -- 引揚先顧客ID
    lt_party_id                   hz_party_sites.party_id%TYPE;                   -- パーティID
    lt_party_site_id              hz_party_sites.party_site_id%TYPE;              -- パーティサイトID
    lt_area_code                  hz_locations.address3%TYPE;                     -- 地区コード
    -- 物件情報更新用ＡＰＩ 
    lt_instance_rec          csi_datastructures_pub.instance_rec;
    lt_ext_attrib_values_tbl csi_datastructures_pub.extend_attrib_values_tbl;
    lt_party_tbl             csi_datastructures_pub.party_tbl;
    lt_account_tbl           csi_datastructures_pub.party_account_tbl;
    lt_pricing_attrib_tbl    csi_datastructures_pub.pricing_attribs_tbl;
    lt_org_assignments_tbl   csi_datastructures_pub.organization_units_tbl;
    lt_asset_assignment_tbl  csi_datastructures_pub.instance_asset_tbl;
    lt_txn_rec               csi_datastructures_pub.transaction_rec;
    lt_instance_id_lst       csi_datastructures_pub.id_tbl;
    lv_return_status         VARCHAR2(1);
    ln_msg_count             NUMBER;
    lv_msg_data              VARCHAR2(5000);
    -- 追加属性更新用
    l_ext_attrib_rec         csi_iea_values%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    ln_count := 0; -- 件数カウント用
    lt_instance_id                := NULL; -- インスタンスID
    lt_instance_object_vnum       := NULL; -- オブジェクトバージョン番号
    lt_instance_party_id          := NULL; -- インスタンスパーティID
    lt_instance_party_object_vnum := NULL; -- オブジェクトバージョン番号
    lt_ip_account_id              := NULL; -- インスタンスアカウントID
    lt_instance_acct_object_vnum  := NULL; -- オブジェクトバージョン番号
    lt_transaction_type_id        := NULL; -- 取引タイプID
    lt_withdraw_account_id        := NULL; -- 引揚先顧客ID
    lt_party_id                   := NULL; -- パーティID
    lt_party_site_id              := NULL; -- パーティサイトID
    lt_area_code                  := NULL; -- 地区コード
--
    --==============================================================
    -- 1.インスタンスID・オブジェクトバージョン番号取得
    --==============================================================
    BEGIN
      SELECT cii.instance_id           AS instance_id           -- インスタンスＩＤ
            ,cii.object_version_number AS object_version_number -- オブジェクトバージョン番号
      INTO   lt_instance_id
            ,lt_instance_object_vnum
      FROM   csi_item_instances cii -- 物件マスタ
      WHERE  cii.external_reference = iv_install_code -- 引揚物件コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00329         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00714         -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00696         -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => iv_install_code          -- トークン値3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 2.インスタンスパーティ情報取得
    --==============================================================
    BEGIN
      SELECT cip.instance_party_id     AS instance_party_id     -- インスタンスパーティＩＤ
            ,cip.object_version_number AS object_version_number -- オブジェクトバージョン番号
      INTO   lt_instance_party_id
            ,lt_instance_party_object_vnum
      FROM   csi_i_parties cip -- インスタンスパーティマスタ
      WHERE  cip.instance_id = lt_instance_id -- インスタンスID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00329         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00764         -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00696         -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => iv_install_code          -- トークン値3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 3.インスタンスアカウント情報取得
    --==============================================================
    BEGIN
      SELECT cia.ip_account_id         AS ip_account_id         -- インスタンスアカウントＩＤ
            ,cia.object_version_number AS object_version_number -- オブジェクトバージョン番号
      INTO   lt_ip_account_id
            ,lt_instance_acct_object_vnum
      FROM   csi_ip_accounts cia -- インスタンスアカウントマスタ
      WHERE  cia.instance_party_id = lt_instance_party_id -- インスタンスパーティID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00329         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00765         -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00696         -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => iv_install_code          -- トークン値3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 4.引揚先顧客情報取得
    --==============================================================
    BEGIN
      SELECT hca.cust_account_id AS cust_account_id -- 引揚先顧客ID
            ,hps.party_id        AS party_id        -- パーティＩＤ
            ,hps.party_site_id   AS party_site_id   -- パーティサイトID
            ,hl.address3         AS address3        -- 地区コード
      INTO   lt_withdraw_account_id
            ,lt_party_id
            ,lt_party_site_id
            ,lt_area_code
      FROM   hz_cust_accounts hca -- 顧客マスタ
            ,hz_party_sites   hps -- パーティサイトマスタ
            ,hz_locations     hl  -- 顧客事業所マスタ
            ,hz_cust_acct_sites hcas  --顧客所在地
      WHERE  hca.account_number  = gv_modem_base_code    -- 顧客コード
      AND    hca.party_id        = hps.party_id          -- パーティID
      AND    hps.location_id     = hl.location_id        -- ロケーションID
      AND    hca.cust_account_id = hcas.cust_account_id  -- 顧客ID
      AND    hps.party_site_id   = hcas.party_site_id    -- パーティサイトID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ取得エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00329         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00763         -- トークン値1
                       ,iv_token_name2  => cv_tkn_key_name          -- トークンコード2
                       ,iv_token_value2 => cv_msg_cso_00707         -- トークン値2
                       ,iv_token_name3  => cv_tkn_key_id            -- トークンコード3
                       ,iv_token_value3 => gv_modem_base_code       -- トークン値3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 5.取引タイプID取得
    --==============================================================
    BEGIN
      SELECT ctt.transaction_type_id AS transaction_type_id -- 取引タイプID
      INTO   lt_transaction_type_id
      FROM   csi_txn_types ctt -- 取引タイプテーブル
      WHERE  ctt.source_transaction_type = cv_src_tran_type -- 取引タイプ:'IB_UI'
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 取引タイプID抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00343         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00711         -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type     -- トークンコード2
                       ,iv_token_value2 => cv_src_tran_type         -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg           -- トークンコード3
                       ,iv_token_value3 => SQLERRM                  -- トークン値3
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 6.更新用レコード編集
    --==============================================================
    -- インスタンスレコード設定
    lt_instance_rec.instance_id                      := lt_instance_id;                -- インスタンスID
    lt_instance_rec.attribute4                       := cv_flag_n;                     -- 作業依頼中フラグ
    lt_instance_rec.attribute8                       := NULL;                          -- 作業依頼中購買依頼No/顧客CD
    lt_instance_rec.location_type_code               := cv_location_type_code;         -- ロケーションタイプコード
    lt_instance_rec.location_id                      := lt_party_site_id;              -- ロケーションID
    lt_instance_rec.object_version_number            := lt_instance_object_vnum;       -- オブジェクトバージョン番号
    lt_instance_rec.request_id                       := cn_request_id;                 -- 要求ID
    lt_instance_rec.program_application_id           := cn_program_application_id;     -- コンカレント・プログラム・アプリケーションID
    lt_instance_rec.program_id                       := cn_program_id;                 -- コンカレント・プログラムID
    lt_instance_rec.program_update_date              := cd_program_update_date;        -- プログラム更新日
    -- パーティレコード設定
    lt_party_tbl(cn_one).instance_party_id           := lt_instance_party_id;          -- インスタンスパーティID
    lt_party_tbl(cn_one).party_source_table          := cv_party_source_table;         -- パーティソーステーブル
    lt_party_tbl(cn_one).party_id                    := lt_party_id;                   -- パーティID
    lt_party_tbl(cn_one).relationship_type_code      := cv_relationship_type_code;     -- リレーションタイプコード
    lt_party_tbl(cn_one).contact_flag                := cv_flag_n;                     -- コンタクトフラグ
    lt_party_tbl(cn_one).object_version_number       := lt_instance_party_object_vnum; -- オブジェクトバージョン番号
    -- アカウントレコード設定
    lt_account_tbl(cn_one).ip_account_id             := lt_ip_account_id;              -- インスタンスアカウントID
    lt_account_tbl(cn_one).instance_party_id         := lt_instance_party_id;          -- インスタンスパーティID
    lt_account_tbl(cn_one).parent_tbl_index          := cn_one;                        -- PARENT_TBL_INDEX
    lt_account_tbl(cn_one).party_account_id          := lt_withdraw_account_id;        -- パーティアカウントID
    lt_account_tbl(cn_one).relationship_type_code    := cv_relationship_type_code;     -- リレーションタイプコード
    lt_account_tbl(cn_one).object_version_number     := lt_instance_acct_object_vnum;  -- オブジェクトバージョン番号
    -- 取引レコード設定
    lt_txn_rec.transaction_date                      := cd_creation_date;              -- 取引日
    lt_txn_rec.source_transaction_date               := cd_creation_date;              -- ソース取引日
    lt_txn_rec.transaction_type_id                   := lt_transaction_type_id;        -- トランザクションタイプID
--
    --==============================================================
    -- 7.追加属性ID取得
    --==============================================================
    -- 追加属性ID(地区コード)取得
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
                           lt_instance_id
                          ,cv_chiku_cd
                        );
--
    -- 追加属性レコード設定
    IF ( l_ext_attrib_rec.attribute_value_id IS NOT NULL ) THEN 
      lt_ext_attrib_values_tbl(cn_one).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      lt_ext_attrib_values_tbl(cn_one).attribute_value       := lt_area_code;
      lt_ext_attrib_values_tbl(cn_one).attribute_id          := l_ext_attrib_rec.attribute_id;
      lt_ext_attrib_values_tbl(cn_one).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    --==============================================================
    -- 8.インスタンス情報更新ＡＰＩ呼出し
    --==============================================================
    ------------------------------
    -- IB更新用標準API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => fnd_api.g_false
      , p_init_msg_list         => fnd_api.g_true
      , p_validation_level      => fnd_api.g_valid_level_full
      , p_instance_rec          => lt_instance_rec
      , p_ext_attrib_values_tbl => lt_ext_attrib_values_tbl
      , p_party_tbl             => lt_party_tbl
      , p_account_tbl           => lt_account_tbl
      , p_pricing_attrib_tbl    => lt_pricing_attrib_tbl
      , p_org_assignments_tbl   => lt_org_assignments_tbl
      , p_asset_assignment_tbl  => lt_asset_assignment_tbl
      , p_txn_rec               => lt_txn_rec
      , x_instance_id_lst       => lt_instance_id_lst
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
--
    -- APIが正常終了でない場合
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      IF (ln_msg_count > 1) THEN
        lv_msg_data := fnd_msg_pub.get(
                         p_msg_index => cn_one
                        ,p_encoded   => fnd_api.g_true
                       );
      END IF;
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                     ,iv_name         => cv_msg_cso_00504         -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name          -- トークンコード1
                     ,iv_token_value1 => cv_msg_cso_00766         -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg           -- トークンコード2
                     ,iv_token_value2 => lv_msg_data              -- トークン値2
                  );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_install_base;
--
  /**********************************************************************************
   * Procedure Name   : upd_hht_tran
   * Description      : HHT集配信連携トランザクション更新(A-4)
   ***********************************************************************************/
  PROCEDURE upd_hht_tran(
    iv_cust_code       IN  VARCHAR2      --   顧客コード
   ,iv_install_code    IN  VARCHAR2      --   引揚物件コード
   ,iv_kbn             IN  VARCHAR2      --   判定区分
   ,ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_hht_tran'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lr_row_id  ROWID;   -- 更新用
    lt_install_psid          xxcso_hht_col_dlv_coop_trn.install_psid%TYPE;    -- 設置PSID
    lt_line_number           xxcso_hht_col_dlv_coop_trn.line_number%TYPE;     -- 回線番号
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 判定区分が1（設置可能→不可能）の場合
    IF ( iv_kbn = cv_kbn_1 ) THEN
      --==============================================================
      -- 1.前回データ取得
      --==============================================================
      BEGIN
-- 2015/08/19 S.Yamashita Mod Start
--        SELECT xhcdct.rowid         AS rowid        -- ROWID
        SELECT xhcdct.rowid         AS row_id        -- ROWID
-- 2015/08/19 S.Yamashita Mod End
              ,xhcdct.install_psid  AS install_psid    -- 設置PSID
              ,xhcdct.line_number   AS line_number     -- 回線番号
        INTO   lr_row_id
              ,lt_install_psid
              ,lt_line_number
        FROM   xxcso_hht_col_dlv_coop_trn xhcdct -- HHT集配信連携トランザクション
        WHERE  xhcdct.account_number = iv_cust_code    -- 顧客コード
        AND    xhcdct.install_code   = iv_install_code -- 物件コード
        AND    xhcdct.cooperate_flag = cv_flag_y       -- 連携フラグ
        AND    xhcdct.install_psid   IS NOT NULL       -- 設置PSID
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN g_lock_expt THEN
          -- ロックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00278         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table             -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00757         -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg           -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                     );
          lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --==============================================================
      -- 2.前回データ更新
      --==============================================================
      BEGIN
        UPDATE xxcso_hht_col_dlv_coop_trn xhcdct -- HHT集配信連携トランザクション
        SET    xhcdct.cooperate_flag         = cv_flag_n                 -- 連携フラグ
              ,xhcdct.last_updated_by        = cn_last_updated_by        -- 最終更新者
              ,xhcdct.last_update_date       = cd_last_update_date       -- 最終更新日
              ,xhcdct.last_update_login      = cn_last_update_login      -- 最終更新ログイン
              ,xhcdct.request_id             = cn_request_id             -- 要求ID
              ,xhcdct.program_application_id = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
              ,xhcdct.program_id             = cn_program_id             -- コンカレント・プログラムID
              ,xhcdct.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE  xhcdct.rowid   = lr_row_id -- ROWID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- データ更新エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso       -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00337         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_action            -- トークンコード1
                       ,iv_token_value1 => cv_msg_cso_00757         -- トークン値1
                       ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                    );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      -- 3.今回データ（引揚データ）登録
      --==============================================================
      BEGIN
        INSERT INTO xxcso_hht_col_dlv_coop_trn(
          account_number         -- 顧客コード
         ,install_code           -- 物件コード
         ,creating_source_code   -- 発生元ソースコード
         ,install_psid           -- 設置PSID
         ,withdraw_psid          -- 引揚PSID
         ,line_number            -- 回線番号
         ,cooperate_flag         -- 連携フラグ
         ,approval_date          -- 承認日
         ,cooperate_date         -- 連携日
         ,created_by             -- 作成者
         ,creation_date          -- 作成日
         ,last_updated_by        -- 最終更新者
         ,last_update_date       -- 最終更新日
         ,last_update_login      -- 最終更新ログイン
         ,request_id             -- 要求ID
         ,program_application_id -- コンカレント・プログラム・アプリケーションID
         ,program_id             -- コンカレント・プログラムID
         ,program_update_date    -- プログラム更新日
         )
         VALUES(
          iv_cust_code                 -- 顧客コード
         ,iv_install_code              -- 物件コード
         ,cv_pkg_name                  -- 発生元ソースコード
         ,NULL                         -- 設置PSID
         ,lt_install_psid              -- 引揚PSID
         ,lt_line_number               -- 回線番号
         ,cv_flag_y                    -- 連携フラグ
         ,TRUNC(cd_creation_date)      -- 承認日
         ,gd_process_date              -- 連携日
         ,cn_created_by                -- 作成者
         ,cd_creation_date             -- 作成日
         ,cn_last_updated_by           -- 最終更新者
         ,cd_last_update_date          -- 最終更新日
         ,cn_last_update_login         -- 最終更新ログイン
         ,cn_request_id                -- 要求ID
         ,cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
         ,cn_program_id                -- コンカレント・プログラムID
         ,cd_program_update_date       -- プログラム更新日
         );
      EXCEPTION
        WHEN OTHERS THEN
          -- データ登録エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00330     -- メッセージコード
                         ,iv_token_name1  => cv_tkn_action        -- トークンコード1
                         ,iv_token_value1 => cv_msg_cso_00757     -- トークン値1
                         ,iv_token_name2  => cv_tkn_error_message     -- トークンコード2
                         ,iv_token_value2 => SQLERRM                  -- トークン値2
                      );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- 判定区分が2（設置不可能→可能）の場合
    ELSIF ( iv_kbn = cv_kbn_2 ) THEN
      BEGIN
        DELETE FROM xxcso_hht_col_dlv_coop_trn xhcdct
        WHERE  xhcdct.account_number       = iv_cust_code  -- 顧客コード
        AND    xhcdct.creating_source_code = cv_pkg_name   -- 発生元ソースコード
        AND    xhcdct.cooperate_flag       = cv_flag_y     -- 連携フラグ
        AND    xhcdct.withdraw_psid        IS NOT NULL     -- 引揚PSID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- データ削除エラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso   -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00072     -- メッセージコード
                         ,iv_token_name1  => cv_tkn_table         -- トークンコード1
                         ,iv_token_value1 => cv_msg_cso_00757     -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_message   -- トークンコード2
                         ,iv_token_value2 => SQLERRM              -- トークン値2
                      );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_hht_tran;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_cust_code       IN  VARCHAR2     -- 顧客コード
   ,iv_install_code    IN  VARCHAR2     -- 引揚物件コード
   ,iv_kbn             IN  VARCHAR2     -- 判定区分
   ,ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ov_retcode := cv_status_normal;
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_cust_code       => iv_cust_code     -- 顧客コード
     ,iv_install_code    => iv_install_code  -- 引揚物件コード
     ,iv_kbn             => iv_kbn           -- 判定区分
     ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 妥当性チェック(A-2)
    -- ===============================
    data_validation(
      iv_cust_code       => iv_cust_code     -- 顧客コード
     ,iv_install_code    => iv_install_code  -- 引揚物件コード
     ,iv_kbn             => iv_kbn           -- 判定区分
     ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 判定区分が1（設置可能→不可能）の場合
    IF ( iv_kbn = cv_kbn_1 ) THEN
      -- ===============================
      -- 物件マスタ更新(A-3)
      -- ===============================
      upd_install_base(
        iv_cust_code       => iv_cust_code     -- 顧客コード
       ,iv_install_code    => iv_install_code  -- 引揚物件コード
       ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
       ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
       ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- HHT集配信連携トランザクション更新(A-4)
    -- ===============================
    upd_hht_tran(
      iv_cust_code       => iv_cust_code     -- 顧客コード
     ,iv_install_code    => iv_install_code  -- 引揚物件コード
     ,iv_kbn             => iv_kbn           -- 判定区分
     ,ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 成功件数設定
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
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
    errbuf             OUT VARCHAR2     -- エラー・メッセージ  --# 固定 #
   ,retcode            OUT VARCHAR2     -- リターン・コード    --# 固定 #
   ,iv_cust_code       IN  VARCHAR2     -- 顧客コード
   ,iv_install_code    IN  VARCHAR2     -- 引揚物件コード
   ,iv_kbn             IN  VARCHAR2     -- 判定区分
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
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
       iv_cust_code    => iv_cust_code     -- 顧客コード
      ,iv_install_code => iv_install_code  -- 引揚物件コード
      ,iv_kbn          => iv_kbn           -- 判定区分
      ,ov_errbuf       => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode       -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 件数を設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- エラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errbuf                  --エラーメッセージ
      );
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCSO011A05C;
/
