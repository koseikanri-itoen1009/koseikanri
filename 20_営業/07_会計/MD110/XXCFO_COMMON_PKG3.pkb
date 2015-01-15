CREATE OR REPLACE PACKAGE BODY XXCFO_COMMON_PKG3
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg3(body)
 * Description      : 共通関数（会計）
 * MD.070           : MD070_IPO_CFO_001_共通関数定義書
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  init_proc                 P           共通初期処理
 *  chk_period_status         P           仕訳作成用会計期間チェック
 *  chk_gl_if_status          P           仕訳作成用GL連携チェック
 *  chk_ap_period_status      P           AP請求書作成用会計期間チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           新規作成
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCFO_COMMON_PKG3';  -- パッケージ名
--
  cv_msg_kbn_ccp         CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfo         CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN';
  -- メッセージ
  cv_msg_cfo_00001       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';  -- プロファイル取得エラーメッセージ
  cv_msg_cfo_00015       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';  -- 業務日付取得エラーメッセージ
  cv_msg_cfo_00032       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00032';  -- データ取得エラーメッセージ
  cv_msg_cfo_10038       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10038';  -- 在庫会計期間チェックエラーメッセージ
  cv_msg_cfo_10039       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10039';  -- AP会計期間チェックエラーメッセージ
  cv_msg_cfo_10044       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10044';  -- GL会計期間チェックエラーメッセージ
  cv_msg_cfo_10045       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10045';  -- GL連携チェックエラーメッセージ
  --トークン
  cv_tkn_prof            CONSTANT VARCHAR2(10)  := 'PROF_NAME';         -- プロファイルチェック
  cv_tkn_data            CONSTANT VARCHAR2(10)  := 'DATA';              -- エラーデータの説明
  cv_tkn_param           CONSTANT VARCHAR2(10)  := 'PARAM';             -- 入力パラメータ
  --
  cv_set_of_bks_name     CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11156';  -- 会計帳簿名
  --
  ct_sqlgl               CONSTANT fnd_application.application_short_name%TYPE    := 'SQLGL'; --GLアプリ短縮名
  ct_sqlap               CONSTANT fnd_application.application_short_name%TYPE    := 'SQLAP'; --APアプリ短縮名
  ct_closing_status_o    CONSTANT gl_period_statuses.closing_status%TYPE         := 'O';     --O:オープン
  ct_adjust_flag_n       CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N';     --N:調整期間以外
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 共通初期処理
   ***********************************************************************************/
  PROCEDURE init_proc(
      ov_company_code_mfg         OUT VARCHAR2  -- 会社コード（工場）
    , ov_aff5_customer_dummy      OUT VARCHAR2  -- 顧客コード_ダミー値
    , ov_aff6_company_dummy       OUT VARCHAR2  -- 企業コード_ダミー値
    , ov_aff7_preliminary1_dummy  OUT VARCHAR2  -- 予備1_ダミー値
    , ov_aff8_preliminary2_dummy  OUT VARCHAR2  -- 予備2_ダミー値
    , ov_je_invoice_source_mfg    OUT VARCHAR2  -- 仕訳ソース_生産システム
    , on_org_id_mfg               OUT NUMBER    -- 生産ORG_ID
    , on_sales_set_of_bks_id      OUT NUMBER    -- 営業システム会計帳簿ID
    , ov_sales_set_of_bks_name    OUT VARCHAR2  -- 営業システム会計帳簿名
    , ov_currency_code            OUT VARCHAR2  -- 営業システム機能通貨コード
    , od_process_date             OUT DATE      -- 業務日付
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
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
    cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF1_COMPANY_CODE_MFG';    -- 会社コード（工場）
    cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF5_CUSTOMER_DUMMY';      -- 顧客コード_ダミー値
    cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF6_COMPANY_DUMMY';       -- 企業コード_ダミー値
    cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF7_PRELIMINARY1_DUMMY';  -- 予備1_ダミー値
    cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCFO1_AFF8_PRELIMINARY2_DUMMY';  -- 予備2_ダミー値
    cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_INVOICE_SOURCE_MFG';    -- 仕訳ソース_生産システム
    cv_profile_name_07          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';               -- 生産ORG_ID
    cv_profile_name_08          CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                -- 営業システム会計帳簿ID
--
    -- *** ローカル変数 ***
    ln_sales_set_of_bks_id            NUMBER(15);
    lv_name                           VARCHAR2(30);
    lv_currency_code                  VARCHAR2(15);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 2-1.  プロファイル値の取得（カスタム・プロファイル）
    --==============================================================
    -- 会社コード（工場）
    ov_company_code_mfg          := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF ( ov_company_code_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_01 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 顧客コード_ダミー値
    ov_aff5_customer_dummy       := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF ( ov_aff5_customer_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_02 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 企業コード_ダミー値
    ov_aff6_company_dummy        := FND_PROFILE.VALUE( cv_profile_name_03 );
    IF ( ov_aff6_company_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_03 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 予備1_ダミー値
    ov_aff7_preliminary1_dummy   := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF ( ov_aff7_preliminary1_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_04 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 予備2_ダミー値
    ov_aff8_preliminary2_dummy   := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF ( ov_aff8_preliminary2_dummy IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_05 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 仕訳ソース_生産システム
    ov_je_invoice_source_mfg     := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF ( ov_je_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_06 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-2.  プロファイル値の取得（共通）
    --==============================================================
    -- 生産ORG_ID
    on_org_id_mfg                := TO_NUMBER(FND_PROFILE.VALUE( cv_profile_name_07 ));
    IF ( on_org_id_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_07 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 営業システム会計帳簿ID
    ln_sales_set_of_bks_id       := TO_NUMBER(FND_PROFILE.VALUE( cv_profile_name_08 ));
    on_sales_set_of_bks_id       := ln_sales_set_of_bks_id;
    IF ( on_sales_set_of_bks_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_00001     -- メッセージ：APP-XXCFO1-00001
                                           ,iv_token_name1  => cv_tkn_prof          -- トークンコード
                                           ,iv_token_value1 => cv_profile_name_08 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-4.  会計帳簿名、機能通貨コードの取得
    --==============================================================
    BEGIN
      SELECT name                              --会計帳簿名
            ,currency_code                     --機能通貨コード
        INTO lv_name
            ,lv_currency_code
        FROM gl_sets_of_books
       WHERE set_of_books_id = ln_sales_set_of_bks_id;
--
      -- 営業システム会計帳簿名
      ov_sales_set_of_bks_name   := lv_name;
      -- 営業システム機能通貨コード
      ov_currency_code           := lv_currency_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                            ,cv_msg_cfo_00032  -- データ取得エラー
                                            ,cv_tkn_data       -- トークン'DATA'
                                            ,cv_set_of_bks_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    --==============================================================
    -- 2-5.  業務日付の取得
    --==============================================================
    -- 業務日付
    od_process_date              := xxccp_common_pkg2.get_process_date;
--
    IF ( od_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- アプリケーション短縮名
                                            ,cv_msg_cfo_00015);    -- メッセージ：APP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : chk_period_status
   * Description      : 仕訳作成用会計期間チェック
   ***********************************************************************************/
  -- 仕訳作成用会計期間チェック
  PROCEDURE chk_period_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_status'; -- プログラム名
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
    lv_close_date                     VARCHAR2(6);  -- OPM在庫会計期間CLOSE年月(yyyymm)
    lv_in_period_name                 VARCHAR2(6);  -- 会計期間年月(yyyymm)
    lv_status_code                    VARCHAR2(1);  -- GL会計期間のステータス
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
    -- 2.  共通関数（OPM在庫会計期間CLOSE年月取得関数）
    --==============================================================
    -- 共通関数からOPM在庫会計期間CLOSE年月を取得
    lv_close_date          := xxcmn_common_pkg.get_opminv_close_period;
--
    -- INパラメータの会計期間（YYYY-MM)を"YYYYMM"形式に変更
    lv_in_period_name      := REPLACE(iv_period_name,'-');
--
    -- 会計期間が一致しない場合、エラーメッセージを出力
    IF ( lv_close_date <> lv_in_period_name ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_10038     -- メッセージ：APP-XXCFO1-10038
                                           ,iv_token_name1  => cv_tkn_param         -- トークンコード
                                           ,iv_token_value1 => iv_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.  会計期間ステータスを確認
    --==============================================================
    BEGIN
      SELECT gps.closing_status         AS status  -- ステータス
      INTO   lv_status_code
      FROM   gl_period_statuses gps                -- 会計期間ステータス
            ,fnd_application    fa                 -- アプリケーション
      WHERE  gps.application_id         = fa.application_id
      AND    fa.application_short_name  = ct_sqlgl                -- アプリケーション短縮名「SQLGL」
      AND    gps.adjustment_period_flag = ct_adjust_flag_n        -- 調整フラグが'N'
      AND    gps.set_of_books_id        = in_sales_set_of_bks_id  -- INパラ会計帳簿ID
      AND    gps.period_name            = iv_period_name          -- 会計期間
      ;
--
      -- ステータスが「オープン」でない場合、エラーメッセージを出力
      IF ( lv_status_code <> ct_closing_status_o ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_cfo_10044     -- メッセージ：APP-XXCFO1-10044
                                             ,iv_token_name1  => cv_tkn_param         -- トークンコード
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
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
  END chk_period_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_gl_if_status
   * Description      : 仕訳作成用GL連携チェック
   ***********************************************************************************/
  -- 仕訳作成用GL連携チェック
  PROCEDURE chk_gl_if_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , iv_func_name                IN  VARCHAR2  -- 機能名（コンカレント短縮名）
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gl_if_status'; -- プログラム名
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
    cv_flag_y                    CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ローカル変数 ***
    ln_count                     NUMBER DEFAULT 0;
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
    -- 2.  仕訳連携情報を確認
    --==============================================================
    BEGIN
      SELECT COUNT(1)
      INTO   ln_count
      FROM   xxcfo_mfg_if_control xmic             -- 連携管理テーブル
      WHERE  xmic.program_name           = iv_func_name            -- INパラ機能名
      AND    xmic.set_of_books_id        = in_sales_set_of_bks_id  -- INパラ会計帳簿ID
      AND    xmic.period_name            = iv_period_name          -- INパラ会計期間
      AND    xmic.gl_process_flag        = cv_flag_y               -- 処理済
      ;
--
      -- 該当データが取得出来た場合、エラーメッセージを出力
      IF ( ln_count <> 0 ) THEN 
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_cfo_10045     -- メッセージ：APP-XXCFO1-10045
                                             ,iv_token_name1  => cv_tkn_param         -- トークンコード
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
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
  END chk_gl_if_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_ap_period_status
   * Description      : AP請求書作成用会計期間チェック
   ***********************************************************************************/
  PROCEDURE chk_ap_period_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ap_period_status'; -- プログラム名
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
    lv_close_date                     VARCHAR2(6);  -- OPM在庫会計期間CLOSE年月(yyyymm)
    lv_in_period_name                 VARCHAR2(6);  -- 会計期間年月(yyyymm)
    lv_status_code                    VARCHAR2(1);  -- AP会計期間のステータス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 2.  共通関数（OPM在庫会計期間CLOSE年月取得関数）
    --==============================================================
    -- 共通関数からOPM在庫会計期間CLOSE年月を取得
    lv_close_date          := xxcmn_common_pkg.get_opminv_close_period;
--
    -- INパラメータの会計期間（YYYY-MM)を"YYYYMM"形式に変更
    lv_in_period_name      := REPLACE(iv_period_name,'-');
--
    -- 会計期間が一致しない場合、エラーメッセージを出力
    IF ( lv_close_date <> lv_in_period_name ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                           ,iv_name         => cv_msg_cfo_10038     -- メッセージ：APP-XXCFO1-10038
                                           ,iv_token_name1  => cv_tkn_param         -- トークンコード
                                           ,iv_token_value1 => iv_period_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4.  会計期間ステータスを確認
    --==============================================================
    BEGIN
      SELECT gps.closing_status         AS status  -- ステータス
      INTO   lv_status_code
      FROM   gl_period_statuses gps                -- 会計期間ステータス
            ,fnd_application    fa                 -- アプリケーション
      WHERE  gps.application_id         = fa.application_id
      AND    fa.application_short_name  = ct_sqlap                -- アプリケーション短縮名「SQLAP」
      AND    gps.adjustment_period_flag = ct_adjust_flag_n        -- 調整フラグが'N'
      AND    gps.set_of_books_id        = in_sales_set_of_bks_id  -- INパラ会計帳簿ID
      AND    gps.period_name            = iv_period_name          -- 会計期間
      ;
--
      -- ステータスが「オープン」でない場合、エラーメッセージを出力
      IF ( lv_status_code <> ct_closing_status_o ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                             ,iv_name         => cv_msg_cfo_10039     -- メッセージ：APP-XXCFO1-10039
                                             ,iv_token_name1  => cv_tkn_param         -- トークンコード
                                             ,iv_token_value1 => iv_period_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END;
--
  EXCEPTION
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
  END chk_ap_period_status;
--
END XXCFO_COMMON_PKG3;
/
