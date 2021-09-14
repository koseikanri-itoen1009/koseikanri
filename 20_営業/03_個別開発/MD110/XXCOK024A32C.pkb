CREATE OR REPLACE PACKAGE BODY XXCOK024A32C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A32C_pkg(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：入金時値引処理 MD050_COK_024_A32
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_deduction_p        販売控除情報抽出(A-2)
 *  ins_cust_inf_p         入金時値引対象顧客情報追加(A-3)
 *  get_cust_inf_p         入金時値引対象顧客情報抽出(A-4)
 *  upd_cust_inf_p         入金時値引対象顧客情報更新(A-5)
 *  get_target_cust_p      AR連係対象顧客抽出(A-6)
 *  transfer_to_ar_p       AR連係処理(A-7)
 *  upd_control_p          販売控除管理情報更新(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/22    1.0   Y.Koh            新規作成
 *  2021/06/03    1.1   SCSK Y.Koh       [E_本稼動_16026] 消費税明細対応
 *  2021/06/21    1.2   SCSK T.Nishikawa [E_本稼動_17278] 処理対象から売上実績振替分を除く
 *  2021/09/10    1.3   SCSK K.Yoshikawa [E_本稼動_17505] 入金時値引処理の実行日の変更
 *
 *****************************************************************************************/
--
  -- ==============================
  -- グローバル定数
  -- ==============================
  -- ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A32C';                      -- パッケージ名
--
  -- プロファイル
  cv_gl_category_bm           CONSTANT VARCHAR2(30)         := 'XXCOK1_GL_CATEGORY_BM';             -- 仕訳カテゴリ_販売手数料
  cv_gl_category_condition1   CONSTANT VARCHAR2(30)         := 'XXCOK1_GL_CATEGORY_CONDITION1';     -- 仕訳カテゴリ_販売控除
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(30)         := 'GL_SET_OF_BKS_ID';                  -- GL会計帳簿ID
  cv_ra_trx_type_general      CONSTANT VARCHAR2(30)         := 'XXCOK1_RA_TRX_TYPE_GENERAL';        -- 取引タイプ_入金値引_一般店
  cv_other_tax_code           CONSTANT VARCHAR2(30)         := 'XXCOK1_OTHER_TAX_CODE';             -- 対象外消費税コード
  cv_org_id                   CONSTANT VARCHAR2(30)         := 'ORG_ID';                            -- 営業単位
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF1_COMPANY_CODE';          -- 会社コード
  cv_aff2_dept_fin            CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF2_DEPT_FIN';              -- 部門コード_財務経理部
  cv_aff3_account_receivable  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF3_ACCOUNT_RECEIVABLE';    -- 勘定科目_売掛金
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- 補助科目_ダミー値
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF5_CUSTOMER_DUMMY';        -- 顧客コード_ダミー値
  cv_aff6_company_dummy       CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- 企業コード_ダミー値
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- 予備１_ダミー値
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- 予備２_ダミー値
  cv_instantly_term_name      CONSTANT VARCHAR2(30)         := 'XXCOK1_INSTANTLY_TERM_NAME';        -- 支払条件_即時払い
--
  -- アプリケーション短縮名
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- アプリケーション短縮名
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- アプリケーション短縮名
  -- メッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- 対象件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- 成功件数メッセージ
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- スキップ件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- エラー件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- 警告終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- エラー終了全ロールバックメッセージ
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- プロファイル取得エラー
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- 業務処理日付取得エラー
  cv_msg_cok_10592            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10592';                  -- 前回処理ID取得エラー
  cv_msg_cok_10790            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10790';                  -- 請求先顧客未設定エラー
  cv_msg_cok_10791            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10791';                  -- 支払条件未設定エラー
  cv_msg_cok_10792            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-10792';                  -- 請求書発行サイクル未設定エラー
--
  -- トークン名
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- 件数のトークン名
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- プロファイル名のトークン名
  cv_tkn_customer             CONSTANT VARCHAR2(15)         := 'CUSTOMER_CODE';                     -- 顧客コードのトークン名
  -- フラグ
  cv_flag_n                   CONSTANT VARCHAR2(1)          := 'N';                                 -- 作成元区分 N
  -- 記号
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  -- ==============================
  -- グローバル変数
  -- ==============================
  gn_target_cnt               NUMBER                        := 0;                                   -- 対象件数
  gn_normal_cnt               NUMBER                        := 0;                                   -- 正常件数
  gn_skip_cnt                 NUMBER                        := 0;                                   -- スキップ件数
  gn_error_cnt                NUMBER                        := 0;                                   -- エラー件数
--
  gd_process_date             DATE;                                                                 -- 業務処理日付
  gv_gl_category_bm           VARCHAR2(30);                                                         -- 仕訳カテゴリ_販売手数料
  gv_gl_category_condition1   VARCHAR2(30);                                                         -- 仕訳カテゴリ_販売控除
  gn_gl_set_of_bks_id         NUMBER;                                                               -- GL会計帳簿ID
  gv_ra_trx_type_general      VARCHAR2(30);                                                         -- 取引タイプ_入金値引_一般店
  gv_other_tax_code           VARCHAR2(30);                                                         -- 対象外消費税コード
  gn_org_id                   NUMBER;                                                               -- 営業単位
  gv_aff1_company_code        VARCHAR2(30);                                                         -- 会社コード
  gv_aff2_dept_fin            VARCHAR2(30);                                                         -- 部門コード_財務経理部
  gv_aff3_account_receivable  VARCHAR2(30);                                                         -- 勘定科目_売掛金
  gv_aff4_subacct_dummy       VARCHAR2(30);                                                         -- 補助科目_ダミー値
  gv_aff5_customer_dummy      VARCHAR2(30);                                                         -- 顧客コード_ダミー値
  gv_aff6_company_dummy       VARCHAR2(30);                                                         -- 企業コード_ダミー値
  gv_aff7_preliminary1_dummy  VARCHAR2(30);                                                         -- 予備１_ダミー値
  gv_aff8_preliminary2_dummy  VARCHAR2(30);                                                         -- 予備２_ダミー値
  gv_instantly_term_name      VARCHAR2(30);                                                         -- 支払条件_即時払い
  gv_currency_code            VARCHAR2(30);                                                         -- 通貨コード
  gv_invoice_hold_status      VARCHAR2(30);                                                         -- 請求書保留ステータス
--
  gn_target_deduction_id_st   NUMBER;                                                               -- 販売実績明細ID (自)
  gn_target_deduction_id_ed   NUMBER;                                                               -- 販売実績明細ID (至)
--
  -- ==============================
  -- グローバル例外
  -- ==============================
  -- *** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 業務処理日付の取得
    -- ============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_appli_xxcok_name
                                             ,cv_msg_cok_00028
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ============================================================
    -- プロファイル値の取得
    -- ============================================================
--
    -- 仕訳カテゴリ_販売手数料
    gv_gl_category_bm := FND_PROFILE.VALUE( cv_gl_category_bm );
    IF gv_gl_category_bm IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_category_bm
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 仕訳カテゴリ_販売控除
    gv_gl_category_condition1 := FND_PROFILE.VALUE( cv_gl_category_condition1 );
    IF gv_gl_category_condition1 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_category_condition1
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- GL会計帳簿ID
    gn_gl_set_of_bks_id := FND_PROFILE.VALUE( cv_gl_set_of_bks_id );
    IF gn_gl_set_of_bks_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_gl_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 取引タイプ_入金値引_一般店
    gv_ra_trx_type_general := FND_PROFILE.VALUE( cv_ra_trx_type_general );
    IF gv_ra_trx_type_general IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象外消費税コード
    gv_other_tax_code := FND_PROFILE.VALUE( cv_other_tax_code );
    IF gv_other_tax_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_other_tax_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 営業単位
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 会社コード
    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF gv_aff1_company_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff1_company_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 部門コード_財務経理部
    gv_aff2_dept_fin := FND_PROFILE.VALUE( cv_aff2_dept_fin );
    IF gv_aff2_dept_fin IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff2_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_売掛金
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );
    IF gv_aff3_account_receivable IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff3_account_receivable
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 補助科目_ダミー値
    gv_aff4_subacct_dummy := FND_PROFILE.VALUE( cv_aff4_subacct_dummy );
    IF gv_aff4_subacct_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff4_subacct_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 顧客コード_ダミー値
    gv_aff5_customer_dummy := FND_PROFILE.VALUE( cv_aff5_customer_dummy );
    IF gv_aff5_customer_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff5_customer_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 企業コード_ダミー値
    gv_aff6_company_dummy := FND_PROFILE.VALUE( cv_aff6_company_dummy );
    IF gv_aff6_company_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff6_company_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 予備１_ダミー値
    gv_aff7_preliminary1_dummy := FND_PROFILE.VALUE( cv_aff7_preliminary1_dummy );
    IF gv_aff7_preliminary1_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff7_preliminary1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 予備２_ダミー値
    gv_aff8_preliminary2_dummy := FND_PROFILE.VALUE( cv_aff8_preliminary2_dummy );
    IF gv_aff8_preliminary2_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff8_preliminary2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 支払条件_即時払い
    gv_instantly_term_name := FND_PROFILE.VALUE( cv_instantly_term_name );
    IF gv_instantly_term_name IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_instantly_term_name
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 通貨コードの取得
    -- ============================================================
    SELECT  currency_code
    INTO    gv_currency_code
    FROM    gl_sets_of_books gsob
    WHERE   gsob.set_of_books_id = gn_gl_set_of_bks_id;
--
    -- ============================================================
    -- 請求書保留ステータスの取得
    -- ============================================================
    SELECT  DECODE(rctt.attribute1,'Y','OPEN','HOLD')
    INTO    gv_invoice_hold_status
    FROM    ra_cust_trx_types_all rctt
    WHERE   rctt.name   = gv_ra_trx_type_general
    AND     rctt.org_id = gn_org_id;
--
    -- ============================================================
    -- 処理対象範囲の販売実績ヘッダーIDの取得
    -- ============================================================
    BEGIN
--
      SELECT  xsdc.last_processing_id + 1
      INTO    gn_target_deduction_id_st
      FROM    xxcok_sales_deduction_control xsdc
      WHERE   xsdc.control_flag = cv_flag_n;
--
    EXCEPTION
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_10592
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    SELECT  MAX(xsd.sales_deduction_id)
    INTO    gn_target_deduction_id_ed
    FROM    xxcok_sales_deduction xsd
    WHERE   xsd.sales_deduction_id  >=  gn_target_deduction_id_st;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_inf_p
   * Description      : 入金時値引対象顧客情報追加(A-3)
   ***********************************************************************************/
  PROCEDURE ins_cust_inf_p(
    ov_errbuf           OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode          OUT VARCHAR2  -- リターン・コード
  , ov_errmsg           OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_customer_code_to IN  VARCHAR2  -- 振替先顧客コード
  , id_max_record_date  IN  DATE      -- 最終計上日
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_cust_inf_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf                 VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg                 VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    ld_last_record_date       DATE;                                   -- 最終計上日
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    BEGIN
--
      SELECT  xdci.last_record_date as  last_record_date
      INTO    ld_last_record_date
      FROM    xxcok_discounted_cust_inf xdci
      WHERE   xdci.ship_to_customer_code  = iv_customer_code_to;
--
    EXCEPTION
      WHEN  OTHERS THEN
        ld_last_record_date :=  NULL;
    END;
--
    IF  ld_last_record_date IS  NULL  THEN
--
      -- ============================================================
      -- 入金時値引対象顧客情報登録
      -- ============================================================
      INSERT  INTO  xxcok_discounted_cust_inf(
        ship_to_customer_code , -- 納品先顧客
        last_record_date      , -- 最終計上日
        last_closing_date     , -- 前回締日
        created_by            , -- 作成者
        creation_date         , -- 作成日
        last_updated_by       , -- 最終更新者
        last_update_date      , -- 最終更新日
        last_update_login     , -- 最終更新ログイン
        request_id            , -- 要求ID
        program_application_id, -- コンカレント・プログラム・アプリケーションID
        program_id            , -- コンカレント・プログラムID
        program_update_date   ) -- プログラム更新日
      VALUES(
        iv_customer_code_to   , -- 納品先顧客
        id_max_record_date    , -- 最終計上日
        gd_process_date - 1   , -- 前回締日
        cn_user_id            , -- 作成者
        SYSDATE               , -- 作成日
        cn_user_id            , -- 最終更新者
        SYSDATE               , -- 最終更新日
        cn_login_id           , -- 最終更新ログイン
        cn_conc_request_id    , -- 要求ID
        cn_prog_appl_id       , -- コンカレント・プログラム・アプリケーションID
        cn_conc_program_id    , -- コンカレント・プログラムID
        SYSDATE               );-- プログラム更新日
--
    ELSIF ld_last_record_date < id_max_record_date  THEN
--
      UPDATE  xxcok_discounted_cust_inf xdci
      SET     xdci.last_record_date       = id_max_record_date, -- 最終計上日
              xdci.last_updated_by        = cn_user_id        , -- 最終更新者
              xdci.last_update_date       = SYSDATE           , -- 最終更新日
              xdci.last_update_login      = cn_login_id       , -- 最終更新ログイン
              xdci.request_id             = cn_conc_request_id, -- 要求ID
              xdci.program_application_id = cn_prog_appl_id   , -- コンカレント・プログラム・アプリケーションID
              xdci.program_id             = cn_conc_program_id, -- コンカレント・プログラムID
              xdci.program_update_date    = SYSDATE             -- プログラム更新日
      WHERE   xdci.ship_to_customer_code  = iv_customer_code_to;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END ins_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : get_deduction_p
   * Description      : 販売控除情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_deduction_p(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_deduction_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- 販売控除情報
    CURSOR l_deduction_cur
    IS
      WITH
        flvc1 AS
        ( SELECT  /*+ MATERIALIZED */ lookup_code
          FROM    fnd_lookup_values flvc
          WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
          AND     flvc.language     = 'JA'
          AND     flvc.enabled_flag = 'Y'
          AND     flvc.attribute10  = 'Y'
        )
      SELECT  xsd.customer_code_to  AS  customer_code_to,
              MAX(xsd.record_date)  AS  max_record_date
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.sales_deduction_id  BETWEEN gn_target_deduction_id_st AND gn_target_deduction_id_ed
      AND     xsd.data_type           =   flv.lookup_code
      AND     xsd.status              =   'N'
      AND     xsd.recon_slip_num      IS  NULL
      AND     xsd.customer_code_to    IS NOT NULL
-- 2021/06/21 Ver1.2 ADD Start
      AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
      GROUP BY xsd.customer_code_to;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除情報抽出
    -- ============================================================
    FOR l_deduction_rec IN  l_deduction_cur LOOP
--
      -- ============================================================
      -- 入金時値引対象顧客情報追加(A-3)の呼び出し
      -- ============================================================
      ins_cust_inf_p(
        ov_errbuf             =>  lv_errbuf                         -- エラー・メッセージ
      , ov_retcode            =>  lv_retcode                        -- リターン・コード
      , ov_errmsg             =>  lv_errmsg                         -- ユーザー・エラー・メッセージ
      , iv_customer_code_to   =>  l_deduction_rec.customer_code_to  -- 振替先顧客コード
      , id_max_record_date    =>  l_deduction_rec.max_record_date   -- 最終計上日
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_deduction_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_cust_inf_p
   * Description      : 入金時値引対象顧客情報更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_cust_inf_p(
    ov_errbuf                 OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode                OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                 OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_ship_to_customer_code  IN  VARCHAR2  -- 納品先顧客
  , id_last_record_date       IN  DATE      -- 最終計上日
  , last_closing_date         IN  DATE      -- 前回締日
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_cust_inf_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    ln_ship_to_customer_id              NUMBER;                                 -- 納品先顧客ID
    ln_ship_to_customer_site_id         NUMBER;                                 -- 納品先顧客サイトID
    lv_billing_customer_code            VARCHAR2(09);                           -- 請求先顧客
    ln_billing_customer_id              NUMBER;                                 -- 請求先顧客ID
    ln_billing_customer_site_id         NUMBER;                                 -- 請求先顧客サイトID
    lv_payment_terms_1                  VARCHAR2(15);                           -- 支払条件1
    lv_payment_terms_2                  VARCHAR2(15);                           -- 支払条件2
    lv_payment_terms_3                  VARCHAR2(15);                           -- 支払条件3
    ln_invoice_issue_cycle              NUMBER;                                 -- 請求書発行サイクル
    ld_next_closing_date                DATE;                                   -- 今回締日
    lv_next_payment_term                VARCHAR2(15);                           -- 今回支払条件
--
    ld_close_date                       DATE;                                   -- 締め日
    ld_pay_date                         DATE;                                   -- 支払日
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    IF  id_last_record_date < gd_process_date - 365 THEN
      DELETE
      FROM    xxcok_discounted_cust_inf xdci
      WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
    ELSE
--
      -- ============================================================
      -- 顧客情報取得
      -- ============================================================
      BEGIN
--
        SELECT  ship_hca.cust_account_id    AS  ship_to_customer_id     , -- 納品先顧客ID
                ship_hcas.cust_acct_site_id AS  ship_to_customer_site_id, -- 納品先顧客サイトID
                bill_hca.account_number     AS  billing_customer_code   , -- 請求先顧客
                bill_hca.cust_account_id    AS  billing_customer_id     , -- 請求先顧客ID
                bill_hcas.cust_acct_site_id AS  billing_customer_site_id, -- 請求先顧客サイトID
                rtt1.name                   AS  payment_terms_1         , -- 支払条件1
                rtt2.name                   AS  payment_terms_2         , -- 支払条件2
                rtt3.name                   AS  payment_terms_3         , -- 支払条件3
                bill_hcsa.attribute8        AS  invoice_issue_cycle       -- 請求書発行サイクル
        INTO    ln_ship_to_customer_id      , -- 納品先顧客ID
                ln_ship_to_customer_site_id , -- 納品先顧客サイトID
                lv_billing_customer_code    , -- 請求先顧客
                ln_billing_customer_id      , -- 請求先顧客ID
                ln_billing_customer_site_id , -- 請求先顧客サイトID
                lv_payment_terms_1          , -- 支払条件1
                lv_payment_terms_2          , -- 支払条件2
                lv_payment_terms_3          , -- 支払条件3
                ln_invoice_issue_cycle        -- 請求書発行サイクル
        FROM    hz_cust_accounts        ship_hca  , -- 納品先_顧客マスタ
                hz_cust_acct_sites_all  ship_hcas , -- 納品先_顧客サイトマスタ
                hz_cust_site_uses_all   ship_hcsa , -- 納品先_顧客使用目的
                hz_cust_accounts        bill_hca  , -- 請求先_顧客マスタ
                hz_cust_acct_sites_all  bill_hcas , -- 請求先_顧客サイトマスタ
                hz_cust_site_uses_all   bill_hcsa , -- 請求先_顧客使用目的
                ra_terms_tl             rtt1      , -- 支払条件1
                ra_terms_tl             rtt2      , -- 支払条件2
                ra_terms_tl             rtt3        -- 支払条件3
        WHERE   ship_hca.account_number     = iv_ship_to_customer_code
        AND     ship_hcas.cust_account_id   = ship_hca.cust_account_id
        AND     ship_hcas.org_id            = gn_org_id
        AND     ship_hcsa.cust_acct_site_id = ship_hcas.cust_acct_site_id
        AND     ship_hcsa.site_use_code     = 'SHIP_TO'
        AND     ship_hcsa.status            = 'A'
        AND     bill_hcsa.site_use_id       = ship_hcsa.bill_to_site_use_id
        AND     bill_hcsa.site_use_code     = 'BILL_TO'
        AND     bill_hcsa.status            = 'A'
        AND     bill_hcas.cust_acct_site_id = bill_hcsa.cust_acct_site_id
        AND     bill_hca.cust_account_id    = bill_hcas.cust_account_id
        AND     rtt1.term_id(+)             = bill_hcsa.payment_term_id
        AND     rtt1.language(+)            = 'JA'
        AND     rtt2.term_id(+)             = bill_hcsa.attribute2
        AND     rtt2.language(+)            = 'JA'
        AND     rtt3.term_id(+)             = bill_hcsa.attribute3
        AND     rtt3.language(+)            = 'JA';
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_billing_customer_code  :=  NULL;
      END;
--
      IF  lv_billing_customer_code  IS  NULL  THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                       ,cv_msg_cok_10790
                       ,cv_tkn_customer
                       ,iv_ship_to_customer_code
                      );
        ov_errmsg :=  lv_errmsg;
        gn_skip_cnt :=  gn_skip_cnt + 1;
        ov_retcode  :=  cv_status_warn;
      ELSE
        IF  lv_payment_terms_1  IS  NULL  AND
            lv_payment_terms_2  IS  NULL  AND
            lv_payment_terms_3  IS  NULL  THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                         ,cv_msg_cok_10791
                         ,cv_tkn_customer
                         ,iv_ship_to_customer_code
                        );
          ov_errmsg :=  lv_errmsg;
          gn_skip_cnt :=  gn_skip_cnt + 1;
          ov_retcode  :=  cv_status_warn;
        END IF;
--
        IF  ln_invoice_issue_cycle  IS  NULL  THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          cv_appli_xxcok_name
                         ,cv_msg_cok_10792
                         ,cv_tkn_customer
                         ,iv_ship_to_customer_code
                        );
          ov_errmsg :=  lv_errmsg;
          gn_skip_cnt :=  gn_skip_cnt + 1;
          ov_retcode  :=  cv_status_warn;
        END IF;
      END IF;
--
      IF  ov_retcode  = cv_status_normal  THEN
--
        -- ============================================================
        -- 今回締日取得
        -- ============================================================
        IF  lv_payment_terms_1  = gv_instantly_term_name  OR
            lv_payment_terms_2  = gv_instantly_term_name  OR
            lv_payment_terms_3  = gv_instantly_term_name  THEN
          ld_next_closing_date  :=  gd_process_date;
          lv_next_payment_term  :=  gv_instantly_term_name;
          ln_invoice_issue_cycle := 0;
        ELSE
--
          IF  lv_payment_terms_1  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- エラー・メッセージ
              ov_retcode    =>  lv_retcode          , -- リターン・コード
              ov_errmsg     =>  lv_errmsg           , -- ユーザー・エラー・メッセージ
              id_proc_date  =>  last_closing_date   , -- 処理日
              iv_pay_cond   =>  lv_payment_terms_1  , -- 支払条件
              od_close_date =>  ld_close_date       , -- 締め日
              od_pay_date   =>  ld_pay_date           -- 支払日
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- エラー・メッセージ
                ov_retcode    =>  lv_retcode                      , -- リターン・コード
                ov_errmsg     =>  lv_errmsg                       , -- ユーザー・エラー・メッセージ
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- 処理日
                iv_pay_cond   =>  lv_payment_terms_1              , -- 支払条件
                od_close_date =>  ld_close_date                   , -- 締め日
                od_pay_date   =>  ld_pay_date                       -- 支払日
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_1;
            END IF;
--
          END IF;
--
          IF  lv_payment_terms_2  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- エラー・メッセージ
              ov_retcode    =>  lv_retcode          , -- リターン・コード
              ov_errmsg     =>  lv_errmsg           , -- ユーザー・エラー・メッセージ
              id_proc_date  =>  last_closing_date   , -- 処理日
              iv_pay_cond   =>  lv_payment_terms_2  , -- 支払条件
              od_close_date =>  ld_close_date       , -- 締め日
              od_pay_date   =>  ld_pay_date           -- 支払日
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- エラー・メッセージ
                ov_retcode    =>  lv_retcode                      , -- リターン・コード
                ov_errmsg     =>  lv_errmsg                       , -- ユーザー・エラー・メッセージ
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- 処理日
                iv_pay_cond   =>  lv_payment_terms_2              , -- 支払条件
                od_close_date =>  ld_close_date                   , -- 締め日
                od_pay_date   =>  ld_pay_date                       -- 支払日
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_2;
            END IF;
--
          END IF;
--
          IF  lv_payment_terms_3  IS  NOT NULL  THEN
--
            xxcok_common_pkg.get_close_date_p(
              ov_errbuf     =>  lv_errbuf           , -- エラー・メッセージ
              ov_retcode    =>  lv_retcode          , -- リターン・コード
              ov_errmsg     =>  lv_errmsg           , -- ユーザー・エラー・メッセージ
              id_proc_date  =>  last_closing_date   , -- 処理日
              iv_pay_cond   =>  lv_payment_terms_3  , -- 支払条件
              od_close_date =>  ld_close_date       , -- 締め日
              od_pay_date   =>  ld_pay_date           -- 支払日
            );
            IF  lv_retcode  = cv_status_error THEN
              RAISE global_api_expt;
            END IF;
--
            IF  ld_close_date <=  last_closing_date THEN
              xxcok_common_pkg.get_close_date_p(
                ov_errbuf     =>  lv_errbuf                       , -- エラー・メッセージ
                ov_retcode    =>  lv_retcode                      , -- リターン・コード
                ov_errmsg     =>  lv_errmsg                       , -- ユーザー・エラー・メッセージ
                id_proc_date  =>  ADD_MONTHS(last_closing_date,1) , -- 処理日
                iv_pay_cond   =>  lv_payment_terms_3              , -- 支払条件
                od_close_date =>  ld_close_date                   , -- 締め日
                od_pay_date   =>  ld_pay_date                       -- 支払日
              );
              IF  lv_retcode  = cv_status_error THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
            IF  ld_next_closing_date  <=  ld_close_date THEN
              NULL;
            ELSE
              ld_next_closing_date  :=  ld_close_date;
              lv_next_payment_term  :=  lv_payment_terms_3;
            END IF;
--
          END IF;
--
        END IF;
--
        -- ============================================================
        -- 入金時値引対象顧客情報更新
        -- ============================================================
        UPDATE  xxcok_discounted_cust_inf xdci
        SET     xdci.ship_to_customer_id      = ln_ship_to_customer_id      , -- 納品先顧客ID
                xdci.ship_to_customer_site_id = ln_ship_to_customer_site_id , -- 納品先顧客サイトID
                xdci.billing_customer_code    = lv_billing_customer_code    , -- 請求先顧客
                xdci.billing_customer_id      = ln_billing_customer_id      , -- 請求先顧客ID
                xdci.billing_customer_site_id = ln_billing_customer_site_id , -- 請求先顧客サイトID
                xdci.payment_terms_1          = lv_payment_terms_1          , -- 支払条件1
                xdci.payment_terms_2          = lv_payment_terms_2          , -- 支払条件2
                xdci.payment_terms_3          = lv_payment_terms_3          , -- 支払条件3
                xdci.invoice_issue_cycle      = ln_invoice_issue_cycle      , -- 請求書発行サイクル
                xdci.next_closing_date        = ld_next_closing_date        , -- 今回締日
                xdci.next_payment_term        = lv_next_payment_term        , -- 今回支払条件
                xdci.last_updated_by          = cn_user_id                  , -- 最終更新者
                xdci.last_update_date         = SYSDATE                     , -- 最終更新日
                xdci.last_update_login        = cn_login_id                 , -- 最終更新ログイン
                xdci.request_id               = cn_conc_request_id          , -- 要求ID
                xdci.program_application_id   = cn_prog_appl_id             , -- コンカレント・プログラム・アプリケーションID
                xdci.program_id               = cn_conc_program_id          , -- コンカレント・プログラムID
                xdci.program_update_date      = SYSDATE                       -- プログラム更新日
        WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_inf_p
   * Description      : 入金時値引対象顧客情報抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_cust_inf_p(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_cust_inf_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- 入金時値引対象顧客情報
    CURSOR l_cust_inf_cur
    IS
      SELECT  xdci.ship_to_customer_code  AS  ship_to_customer_code ,
              xdci.last_record_date       AS  last_record_date      ,
              xdci.last_closing_date      AS  last_closing_date
      FROM    xxcok_discounted_cust_inf   xdci;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 入金時値引対象顧客情報抽出
    -- ============================================================
    FOR l_cust_inf_rec  IN  l_cust_inf_cur  LOOP
--
      -- ============================================================
      -- 入金時値引対象顧客情報更新(A-5)の呼び出し
      -- ============================================================
      upd_cust_inf_p(
        ov_errbuf                 =>  lv_errbuf                             -- エラー・メッセージ
      , ov_retcode                =>  lv_retcode                            -- リターン・コード
      , ov_errmsg                 =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
      , iv_ship_to_customer_code  =>  l_cust_inf_rec.ship_to_customer_code  -- 納品先顧客
      , id_last_record_date       =>  l_cust_inf_rec.last_record_date       -- 最終計上日
      , last_closing_date         =>  l_cust_inf_rec.last_closing_date      -- 前回締日
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
--
        lb_retcode := xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT    -- 出力区分
                      , lv_errmsg          -- メッセージ
                      , 1                  -- 改行
                      );
--
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_cust_inf_p;
--
  /**********************************************************************************
   * Procedure Name   : transfer_to_ar_p
   * Description      : AR連係処理(A-7)
   ***********************************************************************************/
  PROCEDURE transfer_to_ar_p(
    ov_errbuf                   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode                  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , iv_ship_to_customer_code    IN  VARCHAR2  -- 納品先顧客
  , in_ship_to_customer_id      IN  NUMBER    -- 納品先顧客ID
  , in_ship_to_customer_site_id IN  NUMBER    -- 納品先顧客サイトID
  , iv_billing_customer_code    IN  VARCHAR2  -- 請求先顧客
  , in_billing_customer_id      IN  NUMBER    -- 請求先顧客ID
  , in_billing_customer_site_id IN  NUMBER    -- 請求先顧客サイトID
  , id_next_closing_date        IN  DATE      -- 今回締日
  , iv_next_payment_term        IN  VARCHAR2  -- 今回支払条件
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'transfer_to_ar_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    ln_count                            NUMBER;                                 -- 件数
    lv_interface_line_attribute1        VARCHAR2(30);                           -- 伝票番号
    ln_interface_line_attribute2        NUMBER              :=  0;              -- 明細行番号
    lv_header_attribute5                VARCHAR2(150);                          -- 起票部門
    lv_header_attribute6                VARCHAR2(150);                          -- 伝票入力者
    lv_header_attribute11               VARCHAR2(150);                          -- 入金拠点
    lv_header_attribute13               VARCHAR2(150);                          -- 納品先顧客名
--
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- 販売控除情報【本体行用】
    CURSOR l_sales_deduction_d_cur
    IS
      SELECT  SUM(xsd.deduction_amount) AS  deduction_amount,
              flv.meaning               AS  meaning         ,
              flv.attribute6            AS  attribute6      ,
              flv.attribute7            AS  attribute7
      FROM    fnd_lookup_values     flv ,
              xxcok_sales_deduction xsd
      WHERE   xsd.recon_slip_num  = lv_interface_line_attribute1
      AND     flv.lookup_type     = 'XXCOK1_DEDUCTION_DATA_TYPE'
      AND     flv.lookup_code     = xsd.data_type
      AND     flv.language        = 'JA'
      AND     flv.enabled_flag    = 'Y'
      GROUP BY  flv.meaning   ,
                flv.attribute6,
                flv.attribute7
      ORDER BY  flv.meaning;
--
    -- 販売控除情報【税金行用】
    CURSOR l_sales_deduction_t_cur
    IS
      SELECT  SUM(xsd.deduction_tax_amount) AS  deduction_tax_amount,
              atca.name                     AS  name        ,
              atca.description              AS  description ,
              atca.attribute5               AS  attribute5  ,
              atca.attribute6               AS  attribute6
      FROM    ap_tax_codes_all      atca,
              xxcok_sales_deduction xsd
      WHERE   xsd.recon_slip_num    = lv_interface_line_attribute1
      AND     atca.name             = xsd.tax_code
      AND     atca.set_of_books_id  = gn_gl_set_of_bks_id
      GROUP BY  atca.name       ,
                atca.description,
                atca.attribute5 ,
                atca.attribute6
      ORDER BY  atca.name;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除情報の有無確認
    -- ============================================================
    WITH
      flvc1 AS
      ( SELECT  /*+ MATERIALIZED */ lookup_code
        FROM    fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
        AND     flvc.language     = 'JA'
        AND     flvc.enabled_flag = 'Y'
        AND     flvc.attribute10  = 'Y'
      )
    SELECT  COUNT(*)
    INTO    ln_count
    FROM    xxcok_sales_deduction   xsd
    WHERE   xsd.customer_code_to    =   iv_ship_to_customer_code
    AND     xsd.record_date         <=  id_next_closing_date
    AND     xsd.data_type           IN  ( SELECT  lookup_code FROM  flvc1 )
    AND     xsd.status              =   'N'
    AND     xsd.recon_slip_num      IS  NULL
-- 2021/06/21 Ver1.2 ADD Start
    AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
    ;
--
    IF  ln_count  > 0 THEN
--
      gn_target_cnt :=  gn_target_cnt + 1;
--
      -- ============================================================
      -- 伝票番号採番
      -- ============================================================
      lv_interface_line_attribute1  :=  xxcok_common_pkg.get_slip_number_f(
                                          iv_package_name =>  cv_pkg_name
                                        );
--
      -- ============================================================
      -- 販売控除情報更新
      -- ============================================================
      UPDATE  xxcok_sales_deduction xsd
      SET     xsd.recon_slip_num          = lv_interface_line_attribute1, -- 支払伝票番号
              xsd.carry_payment_slip_num  = lv_interface_line_attribute1, -- 繰越時支払伝票番号
              xsd.last_updated_by         = cn_user_id                  , -- 最終更新者
              xsd.last_update_date        = SYSDATE                     , -- 最終更新日
              xsd.last_update_login       = cn_login_id                 , -- 最終更新ログイン
              xsd.request_id              = cn_conc_request_id          , -- 要求ID
              xsd.program_application_id  = cn_prog_appl_id             , -- コンカレント・プログラム・アプリケーションID
              xsd.program_id              = cn_conc_program_id          , -- コンカレント・プログラムID
              xsd.program_update_date     = SYSDATE                       -- プログラム更新日
      WHERE   xsd.customer_code_to    =   iv_ship_to_customer_code
      AND     xsd.record_date         <=  id_next_closing_date
      AND     xsd.data_type           IN  (
                                            SELECT  lookup_code
                                            FROM    fnd_lookup_values flvc
                                            WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
                                            AND     flvc.language     = 'JA'
                                            AND     flvc.enabled_flag = 'Y'
                                            AND     flvc.attribute10  = 'Y'
                                          )
      AND     xsd.status              =   'N'
      AND     xsd.recon_slip_num      IS  NULL
-- 2021/06/21 Ver1.2 ADD Start
      AND     xsd.source_category     NOT IN ('T' ,'V')
-- 2021/06/21 Ver1.2 ADD End
      ;
--
      -- ============================================================
      -- 顧客情報取得
      -- ============================================================
--
      -- 起票部門
      BEGIN
--
        SELECT  CASE
                  WHEN  TRUNC(id_next_closing_date,'MM')  = TRUNC(gd_process_date,'MM')
                  THEN
                    xca.sale_base_code
                  ELSE
                    xca.past_sale_base_code
                END as  sale_base_code
        INTO    lv_header_attribute5
        FROM    xxcmm_cust_accounts xca
        WHERE   xca.customer_code = iv_ship_to_customer_code;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_header_attribute5  :=  NULL;
      END;
--
      -- 伝票入力者
      lv_header_attribute6  :=  xxcok_common_pkg.get_sales_staff_code_f(
                                  iv_customer_code  =>  iv_ship_to_customer_code,
                                  id_proc_date      =>  id_next_closing_date
                                );
--
      -- 入金拠点
      BEGIN
--
        SELECT  xchv.cash_receiv_base_code  as  cash_receiv_base_code
        INTO    lv_header_attribute11
        FROM    xxcfr_cust_hierarchy_v  xchv
        WHERE   xchv.bill_account_number  = iv_billing_customer_code
        AND     xchv.ship_account_number  = iv_ship_to_customer_code;
--
      EXCEPTION
        WHEN  OTHERS THEN
          lv_header_attribute11 :=  NULL;
      END;
--
      -- 納品先顧客名
      lv_header_attribute13 :=  xxcfr_common_pkg.get_cust_account_name(
                                  iv_account_number   =>  iv_ship_to_customer_code,
                                  iv_kana_judge_type  =>  '0'
                                );
--
      -- ============================================================
      -- 販売控除情報抽出【本体行】
      -- ============================================================
      FOR l_sales_deduction_d_rec in  l_sales_deduction_d_cur LOOP
--
        ln_interface_line_attribute2  :=  ln_interface_line_attribute2  + 1;
--
        -- ============================================================
        -- AR請求取引OIF登録【本体行】
        -- ============================================================
        INSERT  INTO  ra_interface_lines_all(
          interface_line_context      , -- 取引明細コンテキスト
          interface_line_attribute1   , -- 取引明細DFF1(伝票番号)
          interface_line_attribute2   , -- 取引明細DFF2(明細行番号)
          batch_source_name           , -- 取引ソース
          set_of_books_id             , -- 会計帳簿ID
          line_type                   , -- 明細タイプ
          description                 , -- 品目明細摘要
          currency_code               , -- 通貨コード
          amount                      , -- 明細金額
          cust_trx_type_name          , -- 取引タイプ
          term_name                   , -- 支払条件
          orig_system_bill_customer_id, -- 請求先顧客ID
          orig_system_bill_address_id , -- 請求先顧客所在地参照ID
          orig_system_ship_customer_id, -- 出荷先顧客ID
          orig_system_ship_address_id , -- 出荷先顧客所在地参照ID
          conversion_type             , -- 換算タイプ
          conversion_rate             , -- 換算レート
          trx_date                    , -- 取引日
          gl_date                     , -- GL記帳日
          trx_number                  , -- 伝票番号
          quantity                    , -- 数量
          unit_selling_price          , -- 販売単価
          tax_code                    , -- 税金コード
          header_attribute_category   , -- ヘッダーDFFカテゴリ
          header_attribute5           , -- ヘッダーDFF5(起票部門)
          header_attribute6           , -- ヘッダーDFF6(伝票入力者)
          header_attribute7           , -- ヘッダーDFF7(請求書保留ステータス)
          header_attribute8           , -- ヘッダーDFF8(個別請求書印刷)
          header_attribute9           , -- ヘッダーDFF9(一括請求書印刷)
          header_attribute11          , -- ヘッダーDFF11(入金拠点)
          header_attribute12          , -- ヘッダーDFF12(納品先顧客コード)
          header_attribute13          , -- ヘッダーDFF13(納品先顧客名)
          header_attribute14          , -- ヘッダーDFF14(伝票番号)
          header_attribute15          , -- ヘッダーDFF15(GL記帳日)
          creation_date               , -- 作成日
          org_id                      , -- 営業単位ID
          amount_includes_tax_flag    ) -- 内税フラグ
        VALUES(
          gv_gl_category_bm                         , -- 取引明細コンテキスト
          lv_interface_line_attribute1              , -- 取引明細DFF1(伝票番号)
          ln_interface_line_attribute2              , -- 取引明細DFF2(明細行番号)
          gv_gl_category_condition1                 , -- 取引ソース
          gn_gl_set_of_bks_id                       , -- 会計帳簿ID
          'LINE'                                    , -- 明細タイプ
          l_sales_deduction_d_rec.meaning           , -- 品目明細摘要
          gv_currency_code                          , -- 通貨コード
          - l_sales_deduction_d_rec.deduction_amount, -- 明細金額
          gv_ra_trx_type_general                    , -- 取引タイプ
          iv_next_payment_term                      , -- 支払条件
          in_billing_customer_id                    , -- 請求先顧客ID
          in_billing_customer_site_id               , -- 請求先顧客所在地参照ID
          in_ship_to_customer_id                    , -- 出荷先顧客ID
          in_ship_to_customer_site_id               , -- 出荷先顧客所在地参照ID
          'User'                                    , -- 換算タイプ
          1                                         , -- 換算レート
          id_next_closing_date                      , -- 取引日
          id_next_closing_date                      , -- GL記帳日
          lv_interface_line_attribute1              , -- 伝票番号
          1                                         , -- 数量
          - l_sales_deduction_d_rec.deduction_amount, -- 販売単価
          gv_other_tax_code                         , -- 税金コード
          gn_org_id                                 , -- ヘッダーDFFカテゴリ
          lv_header_attribute5                      , -- ヘッダーDFF5(起票部門)
          lv_header_attribute6                      , -- ヘッダーDFF6(伝票入力者)
          gv_invoice_hold_status                    , -- ヘッダーDFF7(請求書保留ステータス)
          'WAITING'                                 , -- ヘッダーDFF8(個別請求書印刷)
          'WAITING'                                 , -- ヘッダーDFF9(一括請求書印刷)
          lv_header_attribute11                     , -- ヘッダーDFF11(入金拠点)
          iv_ship_to_customer_code                  , -- ヘッダーDFF12(納品先顧客コード)
          lv_header_attribute13                     , -- ヘッダーDFF13(納品先顧客名)
          lv_interface_line_attribute1              , -- ヘッダーDFF14(伝票番号)
          TO_CHAR(id_next_closing_date,'YYYY/MM/DD'), -- ヘッダーDFF15(GL記帳日)
          SYSDATE                                   , -- 作成日
          gn_org_id                                 , -- 営業単位ID
          'N'                                       );-- 内税フラグ
--
        -- ============================================================
        -- AR会計配分OIF登録【本体行】
        -- ============================================================
        INSERT  INTO  ra_interface_distributions_all(
          interface_line_context    , -- 取引明細コンテキスト
          interface_line_attribute1 , -- 取引明細DFF1
          interface_line_attribute2 , -- 取引明細DFF2
          account_class             , -- 勘定科目区分(配分タイプ)
          amount                    , -- 金額(明細金額)
          percent                   , -- パーセント(割合)
          segment1                  , -- 会社セグメント
          segment2                  , -- 部門セグメント
          segment3                  , -- 勘定科目セグメント
          segment4                  , -- 補助科目セグメント
          segment5                  , -- 顧客セグメント
          segment6                  , -- 企業セグメント
          segment7                  , -- 予備１セグメント
          segment8                  , -- 予備２セグメント
          attribute_category        , -- 仕訳明細カテゴリ
          creation_date             , -- 作成日
          org_id                    ) -- 営業単位ID
        VALUES(
          gv_gl_category_bm                         , -- 取引明細コンテキスト
          lv_interface_line_attribute1              , -- 取引明細DFF1(伝票番号)
          ln_interface_line_attribute2              , -- 取引明細DFF2(明細行番号)
          'REV'                                     , -- 勘定科目区分(配分タイプ)
          - l_sales_deduction_d_rec.deduction_amount, -- 金額(明細金額)
          100                                       , -- パーセント(割合)
          gv_aff1_company_code                      , -- 会社セグメント
          gv_aff2_dept_fin                          , -- 部門セグメント
          l_sales_deduction_d_rec.attribute6        , -- 勘定科目セグメント
          l_sales_deduction_d_rec.attribute7        , -- 補助科目セグメント
          gv_aff5_customer_dummy                    , -- 顧客セグメント
          gv_aff6_company_dummy                     , -- 企業セグメント
          gv_aff7_preliminary1_dummy                , -- 予備１セグメント
          gv_aff8_preliminary2_dummy                , -- 予備２セグメント
          gn_org_id                                 , -- 明細DFFカテゴリ
          SYSDATE                                   , -- 作成日
          gn_org_id                                 );-- 営業単位ID
--
      END LOOP;
--
      -- ============================================================
      -- 販売控除情報抽出【税金行】
      -- ============================================================
      FOR l_sales_deduction_t_rec in  l_sales_deduction_t_cur LOOP
--
        ln_interface_line_attribute2  :=  ln_interface_line_attribute2  + 1;
--
        -- ============================================================
        -- AR請求取引OIF登録【税金行】
        -- ============================================================
        INSERT  INTO  ra_interface_lines_all(
          interface_line_context      , -- 取引明細コンテキスト
          interface_line_attribute1   , -- 取引明細DFF1(伝票番号)
          interface_line_attribute2   , -- 取引明細DFF2(明細行番号)
          batch_source_name           , -- 取引ソース
          set_of_books_id             , -- 会計帳簿ID
          line_type                   , -- 明細タイプ
          description                 , -- 品目明細摘要
          currency_code               , -- 通貨コード
          amount                      , -- 明細金額
          cust_trx_type_name          , -- 取引タイプ
          term_name                   , -- 支払条件
          orig_system_bill_customer_id, -- 請求先顧客ID
          orig_system_bill_address_id , -- 請求先顧客所在地参照ID
          orig_system_ship_customer_id, -- 出荷先顧客ID
          orig_system_ship_address_id , -- 出荷先顧客所在地参照ID
-- 2021/06/03 Ver1.1 ADD Start
          link_to_line_context        , -- リンク明細コンテキスト
          link_to_line_attribute1     , -- リンク明細DFF1
          link_to_line_attribute2     , -- リンク明細DFF2
-- 2021/06/03 Ver1.1 ADD End
          conversion_type             , -- 換算タイプ
          conversion_rate             , -- 換算レート
          trx_date                    , -- 取引日
          gl_date                     , -- GL記帳日
          trx_number                  , -- 伝票番号
          quantity                    , -- 数量
          unit_selling_price          , -- 販売単価
          tax_code                    , -- 税金コード
          header_attribute_category   , -- ヘッダーDFFカテゴリ
          header_attribute5           , -- ヘッダーDFF5(起票部門)
          header_attribute6           , -- ヘッダーDFF6(伝票入力者)
          header_attribute7           , -- ヘッダーDFF7(請求書保留ステータス)
          header_attribute8           , -- ヘッダーDFF8(個別請求書印刷)
          header_attribute9           , -- ヘッダーDFF9(一括請求書印刷)
          header_attribute11          , -- ヘッダーDFF11(入金拠点)
          header_attribute12          , -- ヘッダーDFF12(納品先顧客コード)
          header_attribute13          , -- ヘッダーDFF13(納品先顧客名)
          header_attribute14          , -- ヘッダーDFF14(伝票番号)
          header_attribute15          , -- ヘッダーDFF15(GL記帳日)
          creation_date               , -- 作成日
          org_id                      , -- 営業単位ID
          amount_includes_tax_flag    ) -- 内税フラグ
        VALUES(
          gv_gl_category_bm                             , -- 取引明細コンテキスト
          lv_interface_line_attribute1                  , -- 取引明細DFF1(伝票番号)
          ln_interface_line_attribute2                  , -- 取引明細DFF2(明細行番号)
          gv_gl_category_condition1                     , -- 取引ソース
          gn_gl_set_of_bks_id                           , -- 会計帳簿ID
-- 2021/06/03 Ver1.1 MOD Start
          'TAX'                                         , -- 明細タイプ
--          'LINE'                                        , -- 明細タイプ
-- 2021/06/03 Ver1.1 MOD End
          l_sales_deduction_t_rec.description           , -- 品目明細摘要
          gv_currency_code                              , -- 通貨コード
          - l_sales_deduction_t_rec.deduction_tax_amount, -- 明細金額
          gv_ra_trx_type_general                        , -- 取引タイプ
          iv_next_payment_term                          , -- 支払条件
          in_billing_customer_id                        , -- 請求先顧客ID
          in_billing_customer_site_id                   , -- 請求先顧客所在地参照ID
          in_ship_to_customer_id                        , -- 出荷先顧客ID
          in_ship_to_customer_site_id                   , -- 出荷先顧客所在地参照ID
-- 2021/06/03 Ver1.1 ADD Start
          gv_gl_category_bm                             , -- 取引明細コンテキスト
          lv_interface_line_attribute1                  , -- 取引明細DFF1(伝票番号)
          1                                             , -- 取引明細DFF2(明細行番号)
-- 2021/06/03 Ver1.1 ADD End
          'User'                                        , -- 換算タイプ
          1                                             , -- 換算レート
          id_next_closing_date                          , -- 取引日
          id_next_closing_date                          , -- GL記帳日
          lv_interface_line_attribute1                  , -- 伝票番号
          1                                             , -- 数量
          - l_sales_deduction_t_rec.deduction_tax_amount, -- 販売単価
          gv_other_tax_code                             , -- 税金コード
          gn_org_id                                     , -- ヘッダーDFFカテゴリ
          lv_header_attribute5                          , -- ヘッダーDFF5(起票部門)
          lv_header_attribute6                          , -- ヘッダーDFF6(伝票入力者)
          gv_invoice_hold_status                        , -- ヘッダーDFF7(請求書保留ステータス)
          'WAITING'                                     , -- ヘッダーDFF8(個別請求書印刷)
          'WAITING'                                     , -- ヘッダーDFF9(一括請求書印刷)
          lv_header_attribute11                         , -- ヘッダーDFF11(入金拠点)
          iv_ship_to_customer_code                      , -- ヘッダーDFF12(納品先顧客コード)
          lv_header_attribute13                         , -- ヘッダーDFF13(納品先顧客名)
          lv_interface_line_attribute1                  , -- ヘッダーDFF14(伝票番号)
          TO_CHAR(id_next_closing_date,'YYYY/MM/DD')    , -- ヘッダーDFF15(GL記帳日)
          SYSDATE                                       , -- 作成日
          gn_org_id                                     , -- 営業単位ID
          'N'                                           );-- 内税フラグ
--
        -- ============================================================
        -- AR会計配分OIF登録【税金行】
        -- ============================================================
        INSERT  INTO  ra_interface_distributions_all(
          interface_line_context    , -- 取引明細コンテキスト
          interface_line_attribute1 , -- 取引明細DFF1
          interface_line_attribute2 , -- 取引明細DFF2
          account_class             , -- 勘定科目区分(配分タイプ)
          amount                    , -- 金額(明細金額)
          percent                   , -- パーセント(割合)
          segment1                  , -- 会社セグメント
          segment2                  , -- 部門セグメント
          segment3                  , -- 勘定科目セグメント
          segment4                  , -- 補助科目セグメント
          segment5                  , -- 顧客セグメント
          segment6                  , -- 企業セグメント
          segment7                  , -- 予備１セグメント
          segment8                  , -- 予備２セグメント
          attribute_category        , -- 仕訳明細カテゴリ
          creation_date             , -- 作成日
          org_id                    ) -- 営業単位ID
        VALUES(
          gv_gl_category_bm                             , -- 取引明細コンテキスト
          lv_interface_line_attribute1                  , -- 取引明細DFF1(伝票番号)
          ln_interface_line_attribute2                  , -- 取引明細DFF2(明細行番号)
-- 2021/06/03 Ver1.1 MOD Start
          'TAX'                                         , -- 勘定科目区分(配分タイプ)
--          'REV'                                         , -- 勘定科目区分(配分タイプ)
-- 2021/06/03 Ver1.1 MOD End
          - l_sales_deduction_t_rec.deduction_tax_amount, -- 金額(明細金額)
          100                                           , -- パーセント(割合)
          gv_aff1_company_code                          , -- 会社セグメント
          gv_aff2_dept_fin                              , -- 部門セグメント
          l_sales_deduction_t_rec.attribute5            , -- 勘定科目セグメント
          l_sales_deduction_t_rec.attribute6            , -- 補助科目セグメント
          gv_aff5_customer_dummy                        , -- 顧客セグメント
          gv_aff6_company_dummy                         , -- 企業セグメント
          gv_aff7_preliminary1_dummy                    , -- 予備１セグメント
          gv_aff8_preliminary2_dummy                    , -- 予備２セグメント
          gn_org_id                                     , -- 明細DFFカテゴリ
          SYSDATE                                       , -- 作成日
          gn_org_id                                     );-- 営業単位ID
--
      END LOOP;
--
      -- ============================================================
      -- AR会計配分OIF登録【債権行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context    , -- 取引明細コンテキスト
        interface_line_attribute1 , -- 取引明細DFF1
        interface_line_attribute2 , -- 取引明細DFF2
        account_class             , -- 勘定科目区分(配分タイプ)
        percent                   , -- パーセント(割合)
        segment1                  , -- 会社セグメント
        segment2                  , -- 部門セグメント
        segment3                  , -- 勘定科目セグメント
        segment4                  , -- 補助科目セグメント
        segment5                  , -- 顧客セグメント
        segment6                  , -- 企業セグメント
        segment7                  , -- 予備１セグメント
        segment8                  , -- 予備２セグメント
        attribute_category        , -- 仕訳明細カテゴリ
        creation_date             , -- 作成日
        org_id                    ) -- 営業単位ID
      VALUES(
        gv_gl_category_bm           , -- 取引明細コンテキスト
        lv_interface_line_attribute1, -- 取引明細DFF1(伝票番号)
        1                           , -- 取引明細DFF2(明細行番号)
        'REC'                       , -- 勘定科目区分(配分タイプ)
        100                         , -- パーセント(割合)
        gv_aff1_company_code        , -- 会社セグメント
        gv_aff2_dept_fin            , -- 部門セグメント
        gv_aff3_account_receivable  , -- 勘定科目セグメント
        gv_aff4_subacct_dummy       , -- 補助科目セグメント
        gv_aff5_customer_dummy      , -- 顧客セグメント
        gv_aff6_company_dummy       , -- 企業セグメント
        gv_aff7_preliminary1_dummy  , -- 予備１セグメント
        gv_aff8_preliminary2_dummy  , -- 予備２セグメント
        gn_org_id                   , -- 明細DFFカテゴリ
        SYSDATE                     , -- 作成日
        gn_org_id                   );-- 営業単位ID
--
      gn_normal_cnt :=  gn_normal_cnt + 1;
--
    END IF;
--
    -- ============================================================
    -- 入金時値引対象顧客情報更新
    -- ============================================================
    UPDATE  xxcok_discounted_cust_inf xdci
    SET     xdci.last_closing_date  = xdci.next_closing_date
    WHERE   xdci.ship_to_customer_code  = iv_ship_to_customer_code;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END transfer_to_ar_p;
--
  /**********************************************************************************
   * Procedure Name   : get_target_cust_p
   * Description      : AR連係対象顧客抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_target_cust_p(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_target_cust_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- AR連係対象顧客
    CURSOR l_target_cust_cur
    IS
      SELECT  xdci.ship_to_customer_code    ,
              xdci.ship_to_customer_id      ,
              xdci.ship_to_customer_site_id ,
              xdci.billing_customer_code    ,
              xdci.billing_customer_id      ,
              xdci.billing_customer_site_id ,
              xdci.next_closing_date        ,
              xdci.next_payment_term        
-- 2021/09/10 Ver1.3 MOD Start
--      FROM    xxcok_discounted_cust_inf   xdci
      FROM    xxcok_discounted_cust_inf   xdci,
              bom_calendar_dates          bcd2,
              bom_calendar_dates          bcd1
-- 2021/09/10 Ver1.3 MOD End
-- 2021/09/10 Ver1.3 MOD Start
--      WHERE   xdci.next_closing_date  + xdci.invoice_issue_cycle  <=  gd_process_date;
      WHERE   bcd1.calendar_code  =   'SALES_CAL'
      AND     bcd1.calendar_date  =   xdci.next_closing_date
      AND     bcd2.calendar_code  =   'SALES_CAL'
      AND     bcd2.seq_num        =   NVL(bcd1.seq_num,bcd1.prior_seq_num)  + xdci.invoice_issue_cycle
      AND     bcd2.calendar_date  <=  gd_process_date;
-- 2021/09/10 Ver1.3 MOD End
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- AR連係対象顧客抽出
    -- ============================================================
    FOR l_target_cust_rec IN  l_target_cust_cur LOOP
--
      -- ============================================================
      -- AR連係処理(A-7)の呼び出し
      -- ============================================================
      transfer_to_ar_p(
        ov_errbuf                   =>  lv_errbuf                                   -- エラー・メッセージ
      , ov_retcode                  =>  lv_retcode                                  -- リターン・コード
      , ov_errmsg                   =>  lv_errmsg                                   -- ユーザー・エラー・メッセージ
      , iv_ship_to_customer_code    =>  l_target_cust_rec.ship_to_customer_code     -- 納品先顧客
      , in_ship_to_customer_id      =>  l_target_cust_rec.ship_to_customer_id       -- 納品先顧客ID
      , in_ship_to_customer_site_id =>  l_target_cust_rec.ship_to_customer_site_id  -- 納品先顧客サイトID
      , iv_billing_customer_code    =>  l_target_cust_rec.billing_customer_code     -- 請求先顧客
      , in_billing_customer_id      =>  l_target_cust_rec.billing_customer_id       -- 請求先顧客ID
      , in_billing_customer_site_id =>  l_target_cust_rec.billing_customer_site_id  -- 請求先顧客サイトID
      , id_next_closing_date        =>  l_target_cust_rec.next_closing_date         -- 今回締日
      , iv_next_payment_term        =>  l_target_cust_rec.next_payment_term         -- 今回支払条件
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_target_cust_p;
--
  /**********************************************************************************
   * Procedure Name   : upd_control_p
   * Description      : 販売控除管理情報更新(A-8)
   ***********************************************************************************/
  PROCEDURE upd_control_p(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'upd_control_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 販売控除管理情報更新
    -- ============================================================
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = NVL(gn_target_deduction_id_ed, last_processing_id),
            last_updated_by         = cn_user_id                                        ,
            last_update_date        = SYSDATE                                           ,
            last_update_login       = cn_login_id                                       ,
            request_id              = cn_conc_request_id                                ,
            program_application_id  = cn_prog_appl_id                                   ,
            program_id              = cn_conc_program_id                                ,
            program_update_date     = SYSDATE
    WHERE   control_flag  = cv_flag_n;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END upd_control_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- グローバル変数の初期化
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- 初期処理(A-1)の呼び出し
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 販売控除情報抽出(A-2)の呼び出し
    -- ============================================================
    get_deduction_p(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 入金時値引対象顧客情報抽出(A-4)の呼び出し
    -- ============================================================
    get_cust_inf_p(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_warn  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- AR連係対象顧客抽出(A-6)の呼び出し
    -- ============================================================
    get_target_cust_p(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 販売控除管理情報更新の呼び出し
    -- ============================================================
    upd_control_p(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- エラー・メッセージ
  , retcode OUT VARCHAR2                                    -- リターン・コード
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ変数
--
  BEGIN
--
    -- ============================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
--
    -- ============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ
    , ov_retcode => lv_retcode  -- リターン・コード
    , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
--
    -- ============================================================
    -- エラー出力
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- 出力区分
                      , lv_errmsg       -- メッセージ
                      , 1               -- 改行
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- 出力区分
                      , lv_errbuf       -- メッセージ
                      , 0               -- 改行
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- 対象件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- 成功件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- スキップ件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- エラー件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 1                 -- 改行
                    );
--
    -- ============================================================
    -- 終了メッセージ
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A32C;
/
