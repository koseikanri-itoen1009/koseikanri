CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A45C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Package Name     : XXCOK024A45C (body)
 * Description      : 控除額の支払画面より入力された申請中の控除支払情報をAPへ連携します。
 * MD.050           : 控除支払AP連携 MD050_COK_024_A45
 * Version          : 1.0
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_recon_header       A-2.消込ヘッダー情報取得
 *  get_recon_line         A-3.消込明細情報取得
 *  ins_detail_data        A-4.請求書明細登録処理
 *  ins_header_data        A-5.請求書ヘッダー登録処理
 *  update_recon_data      A-6.消込ヘッダー更新処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-7.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2024/12/16    1.0   Y.Koh            新規作成
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
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--###############################  固定共通例外宣言部 END  ###############################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A45C';                     -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- 共通領域短縮アプリ名
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_msg_xxcok_00003     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_msg_xxcok_00028     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- 業務処理日付取得エラー
  cv_msg_xxcok_00034     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034';                 -- 勘定科目情報取得エラー
  cv_msg_xxcok_10632     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10632';                 -- ロックエラーメッセージ
  cv_msg_xxccp_90000     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- 対象件数メッセージ
  cv_msg_xxccp_90001     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- 成功件数メッセージ
  cv_msg_xxccp_90002     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- エラー件数メッセージ
  cv_msg_xxccp_90004     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_msg_xxccp_90006     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- エラー終了全ロールバック
  cv_msg_xxcok_00032     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032';                 -- 支払条件取得エラー
  cv_data_get_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- 対象データなしエラーメッセージ
  cv_po_vendor_site      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10689';                 -- 仕入先サイトマスタ設定不備
  -- トークン
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- プロファイル名
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- 件数メッセージ用トークン名
  cv_tkn_vendor          CONSTANT VARCHAR2(20) := 'VENDOR_CODE';                      -- 支払先コード
  -- プロファイル
  cv_prof_set_of_bks_id  CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_prof_org_id         CONSTANT VARCHAR2(6)  := 'ORG_ID';                           -- 営業単位
  cv_prof_payable        CONSTANT VARCHAR2(19) := 'XXCOK1_AFF3_PAYABLE';              -- 勘定科目_未払金
  cv_prof_sub_acct_dummy CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- 補助科目_ダミー値
  cv_prof_cust_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- 顧客コード_ダミー値
  cv_prof_comp_dummy     CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- 企業コード_ダミー値
  cv_prof_pre1_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- 予備１_ダミー値
  cv_prof_pre2_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- 予備２_ダミー値
  cv_prof_source_dedu_ap CONSTANT VARCHAR2(30) := 'XXCOK1_INVOICE_SOURCE_DEDU_AP';    -- 請求書ソース（AP控除支払）
  cv_prof_tax_remark     CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_DEDU';-- 消込情報明細_摘要_控除税額
  -- クイックコード
  cv_lkup_dedu_type      CONSTANT VARCHAR2(26) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- 控除データ種類
  cv_lkup_tax_conv       CONSTANT VARCHAR2(28) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- 消費税コード変換マスタ
  -- 言語
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- 言語
  -- 明細タイプ
  cv_item                CONSTANT VARCHAR2(4)  := 'ITEM';                             -- 明細タイプ（明細）
  -- 税コード
  cv_0000                CONSTANT VARCHAR2(4)  := '0000';                             -- 税コード（ダミー）
  -- 取引タイプ
  cv_standard            CONSTANT VARCHAR2(8)  := 'STANDARD';                         -- 金額（正）
  cv_credit              CONSTANT VARCHAR2(6)  := 'CREDIT';                           -- 金額（負）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 控除消込ヘッダレコード型定義
  TYPE g_recon_header_rtype IS RECORD(
       recon_slip_num           xxcok_deduction_recon_head.recon_slip_num%TYPE            -- 支払伝票番号
      ,recon_base_code          xxcok_deduction_recon_head.recon_base_code%TYPE           -- 支払請求拠点
      ,applicant                xxcok_deduction_recon_head.applicant%TYPE                 -- 申請者
      ,deduction_chain_code     xxcok_deduction_recon_head.deduction_chain_code%TYPE      -- 控除用チェーンコード
      ,recon_due_date           xxcok_deduction_recon_head.recon_due_date%TYPE            -- 支払予定日
      ,gl_date                  xxcok_deduction_recon_head.gl_date%TYPE                   -- GL記帳日
      ,invoice_date             xxcok_deduction_recon_head.invoice_date%TYPE              -- 請求書日付
      ,vendor_code              xxcok_deduction_recon_head.payee_code%TYPE                -- 仕入先コード
      ,vendor_site_code         po_vendor_sites_all.vendor_site_code%TYPE                 -- 仕入先サイトコード
      ,header_id                xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- 控除消込ヘッダーID
      ,invoice_number           xxcok_deduction_recon_head.invoice_number%TYPE            -- 受領請求書番号
      ,drafting_company         fnd_lookup_values_vl.lookup_code%TYPE                     -- 伝票作成会社
      ,fin_dept_code            fnd_lookup_values_vl.attribute1%TYPE                      -- 管理部門コード
      ,terms_name               xxcok_deduction_recon_head.terms_name%TYPE                -- 支払条件
      ,invoice_ele_data         xxcok_deduction_recon_head.invoice_ele_data%TYPE          -- 電子データ受領
      ,invoice_t_num            xxcok_deduction_recon_head.invoice_t_num%TYPE             -- 適格請求書
  );
  -- 控除消込ヘッダワークテーブル型定義
  TYPE g_recon_head_ttype    IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- 控除消込ヘッダテーブル型変数
  g_recon_head_tbl        g_recon_head_ttype;         -- 控除消込ヘッダ取得
--
  -- 控除消込明細ワークテーブル定義
  TYPE g_recon_line_rtype IS RECORD(
       payment_amt              NUMBER                -- 支払金額
      ,remarks                  VARCHAR2(240)         -- 摘要
      ,acct_code                VARCHAR2(150)         -- 勘定科目
      ,sub_acct_code            VARCHAR2(150)         -- 補助科目
  );
  -- 消込明細情報ワークテーブル型定義
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- 消込明細情報テーブル型変数
  g_recon_line_tbl        g_recon_line_ttype;         -- 消込明細情報取得
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gd_process_date             DATE;                                                   -- 業務処理日付
  gn_set_bks_id               NUMBER;                                                 -- 会計帳簿ID
  gn_org_id                   NUMBER;                                                 -- 営業単位
  gv_payable                  VARCHAR2(40);                                           -- 勘定科目_未払金
  gv_asst_dummy               VARCHAR2(40);                                           -- 補助科目_ダミー値
  gv_cust_dummy               VARCHAR2(40);                                           -- 顧客コード_ダミー値
  gv_comp_dummy               VARCHAR2(40);                                           -- 企業コード_ダミー値
  gv_pre1_dummy               VARCHAR2(40);                                           -- 予備１_ダミー値
  gv_pre2_dummy               VARCHAR2(40);                                           -- 予備２_ダミー値
  gv_source_dedu_ap           VARCHAR2(40);                                           -- 請求書ソース（AP控除支払）
  gv_tax_remark               VARCHAR2(40);                                           -- 消込明細_摘要_控除税額
  gn_invoice_id               NUMBER;                                                 -- 請求書ID
  gn_debt_acct_ccid           NUMBER;                                                 -- CCID（ヘッダ）
  gn_detail_ccid              NUMBER;                                                 -- CCID（明細）
  --
  gn_head_cnt                 NUMBER  DEFAULT 1;                                      -- 消込ヘッダー用カウンタ
  gn_line_cnt                 NUMBER  DEFAULT 1;                                      -- 消込明細用カウンタ
  --
  gn_invoice_amount           NUMBER DEFAULT 0;                                       -- 明細金額集計用
  gn_detail_num               NUMBER DEFAULT 1;                                       -- 連番（明細）
  gn_recon_head_id            NUMBER;                                                 -- 入力パラメータ.控除消込ヘッダID
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.初期処理
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ            --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード              --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                      -- プログラム名
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
--
    -- *** ローカル変数 ***
    gd_acct_period    DATE;   -- 会計期間
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
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
    -- ==============================================================
    -- 1.業務処理日付取得
    -- ==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00028
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 2.プロファイルの取得
    -- ==============================================================
    -- 会計帳簿ID
    gn_set_bks_id := FND_PROFILE.VALUE( cv_prof_set_of_bks_id );
--
    IF ( gn_set_bks_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 営業単位
    gn_org_id := FND_PROFILE.VALUE( cv_prof_org_id );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_未払金
    gv_payable := FND_PROFILE.VALUE( cv_prof_payable );
--
    IF ( gv_payable IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_payable
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 補助科目_ダミー値
    gv_asst_dummy := FND_PROFILE.VALUE( cv_prof_sub_acct_dummy );
--
    IF ( gv_asst_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_sub_acct_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 顧客コード_ダミー値
    gv_cust_dummy := FND_PROFILE.VALUE( cv_prof_cust_dummy );
--
    IF ( gv_cust_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_cust_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 企業コード_ダミー値
    gv_comp_dummy := FND_PROFILE.VALUE( cv_prof_comp_dummy );
--
    IF ( gv_comp_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_comp_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 予備１_ダミー値
    gv_pre1_dummy := FND_PROFILE.VALUE( cv_prof_pre1_dummy );
--
    IF ( gv_pre1_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_pre1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 予備２_ダミー値
    gv_pre2_dummy := FND_PROFILE.VALUE( cv_prof_pre2_dummy );
--
    IF ( gv_pre2_dummy IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_pre2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 請求書ソース（AP控除支払）
    gv_source_dedu_ap := FND_PROFILE.VALUE( cv_prof_source_dedu_ap );
--
    IF ( gv_source_dedu_ap IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_source_dedu_ap
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 消込情報明細_摘要_控除税額
    gv_tax_remark := FND_PROFILE.VALUE( cv_prof_tax_remark );
--
    IF ( gv_tax_remark IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_tax_remark
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--#################################  固定例外処理部 END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_header
   * Description      : A-2.消込ヘッダー情報取得
   ***********************************************************************************/
  PROCEDURE get_recon_header(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_header';                                 -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
    -- *** ローカル・カーソル ***
    -- 控除消込ヘッダ抽出カーソル
    CURSOR recon_head_cur
    IS
      SELECT /*+ index(xdrh xxcok_deduction_recon_head_n01) */
             xdrh.recon_slip_num          AS recon_slip_num       -- 支払伝票番号
            ,xdrh.recon_base_code         AS recon_base_code      -- 支払請求拠点
            ,xdrh.applicant               AS applicant            -- 申請者
            ,xdrh.deduction_chain_code    AS deduction_chain_code -- 控除用チェーンコード
            ,xdrh.recon_due_date          AS recon_due_date       -- 支払予定日
            ,xdrh.gl_date                 AS gl_date              -- GL記帳日
            ,xdrh.invoice_date            AS invoice_date         -- 請求書日付
            ,pv.segment1                  AS vendor_code          -- 仕入先
            ,pvsa.vendor_site_code        AS vendor_site_code     -- 仕入先サイト
            ,xdrh.deduction_recon_head_id AS header_id            -- 控除消込ヘッダーID
            ,xdrh.invoice_number          AS invoice_number       -- 受領請求書番号
            ,flvv_comp.lookup_code        AS drafting_company     -- 伝票作成会社
            ,flvv_comp.attribute1         AS fin_dept_code        -- 管理部門コード
            ,xdrh.terms_name              AS terms_name           -- 支払条件
            ,xdrh.invoice_ele_data        AS invoice_ele_data     -- 電子データ受領
            ,xdrh.invoice_t_num           AS invoice_t_num        -- 適格請求書
      FROM   xxcok_deduction_recon_head   xdrh                    -- 控除消込ヘッダー情報
            ,po_vendor_sites_all          pvsa                    -- 仕入先サイト
            ,po_vendors                   pv                      -- 仕入先
            ,fnd_lookup_values_vl         flvv_conv               -- 参照表ビュー(XXCMM_CONV_COMPANY_CODE)
            ,fnd_lookup_values_vl         flvv_comp               -- 参照表ビュー(XXCFO1_DRAFTING_COMPANY)
      WHERE  xdrh.deduction_recon_head_id =       gn_recon_head_id
      AND    pv.segment1(+)               =       xdrh.payee_code
      AND    pvsa.vendor_id(+)            =       pv.vendor_id
      AND    pvsa.org_id(+)               =       gn_org_id
      AND    flvv_conv.lookup_type        =       'XXCMM_CONV_COMPANY_CODE'
      AND    flvv_conv.attribute1         =       NVL(pvsa.attribute11, '001')
      AND    xdrh.gl_date                 BETWEEN flvv_conv.start_date_active
                                          AND     NVL(flvv_conv.end_date_active, xdrh.gl_date)
      AND    flvv_comp.lookup_type        =       'XXCFO1_DRAFTING_COMPANY'
      AND    flvv_comp.lookup_code        =       flvv_conv.attribute2
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
      ;
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
    -- ============================================================
    -- 1.処理対象消込ヘッダ情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  recon_head_cur;
    -- データ取得
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- カーソルクローズ
    CLOSE recon_head_cur;
    -- 取得した伝票数を対象件数に格納
    gn_target_cnt := g_recon_head_tbl.COUNT;        -- 対象件数
    -- 取得件数が0件だった場合
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象なしメッセージでエラー終了
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    -- 取得件数が2件以上だった場合
    ELSIF ( gn_target_cnt >= 2 ) THEN
      -- 仕入先サイトマスタ設定不備でエラー終了
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_po_vendor_site
                     ,cv_tkn_vendor
                     ,g_recon_head_tbl(1).vendor_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                 ,cv_msg_xxcok_10632
                                                 );
      --
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_head_cur%ISOPEN ) THEN
        CLOSE recon_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 END  #################################
--
  END get_recon_header;
--
  /**********************************************************************************
   * Procedure Name   : get_recon_line
   * Description      : A-3.消込明細情報取得
   ***********************************************************************************/
  PROCEDURE get_recon_line(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_recon_line';          -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
    -- 消込明細情報取得カーソル
    CURSOR recon_line_cur
    IS
      -- 控除No別消込情報_本体
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              xdnr.payment_amt  AS  payment_amt       -- 支払額
             ,SUBSTRB(xdnr.condition_no || cv_msg_part || flv.meaning || cv_msg_part || xch.content || cv_msg_part || xdnr.remarks, 1, 240)
                                    AS  remarks       -- 摘要
             ,flv.attribute6        AS  acct_code     -- 勘定科目
             ,flv.attribute7        AS  sub_acct_code -- 補助科目
      FROM    xxcok_deduction_num_recon xdnr          -- 控除No別消込情報
             ,fnd_lookup_values         flv           -- データ種類
             ,xxcok_condition_header    xch           -- 控除条件テーブル
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_dedu_type
      AND     flv.lookup_code       = xdnr.data_type
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     xch.condition_no(+)   = xdnr.condition_no
      UNION ALL
      -- 控除No別消込情報_税
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              SUM(xdnr.payment_tax) AS  payment_amt   -- 支払額
             ,gv_tax_remark || xdnr.payment_tax_code
                                    AS  remarks       -- 摘要
             ,atca.attribute5       AS  acct_code     -- 勘定科目
             ,atca.attribute6       AS  sub_acct_code -- 補助科目
      FROM    xxcok_deduction_num_recon xdnr          -- 控除No別消込情報
             ,ap_tax_codes_all          atca          -- AP税コードマスタ
             ,fnd_lookup_values         flv           -- 税コード変換マスタ
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xdnr.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      GROUP BY gv_tax_remark || xdnr.payment_tax_code
              ,atca.attribute5
              ,atca.attribute6
    ;
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
    -- ============================================================
    -- 消込明細情報の取得
    -- ============================================================
    -- カーソルオープン
    OPEN  recon_line_cur;
    -- データ取得
    FETCH recon_line_cur BULK COLLECT INTO g_recon_line_tbl;
    -- カーソルクローズ
    CLOSE recon_line_cur;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_line_cur%ISOPEN ) THEN
        CLOSE recon_line_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
--
  END get_recon_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_data
   * Description      : A-4.請求書明細登録処理
   ***********************************************************************************/
  PROCEDURE ins_detail_data(
                      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_data';              -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- ============================================================
    -- 4-1.請求書ID取得
    -- ============================================================
    -- 明細作成の初回
    IF ( gn_invoice_id IS NULL ) THEN
      -- シーケンスから請求書IDを取得
      SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    END IF;
    -- ============================================================
    -- 4-2.CCID取得
    -- ============================================================
    gn_detail_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                                 -- 処理日
                      , iv_segment1  => g_recon_head_tbl(gn_head_cnt).drafting_company  -- 会社コード(伝票作成会社)
                      , iv_segment2  => g_recon_head_tbl(gn_head_cnt).fin_dept_code     -- 部門コード(伝票作成会社の管理部門)
                      , iv_segment3  => g_recon_line_tbl(gn_line_cnt).acct_code         -- 勘定科目コード
                      , iv_segment4  => g_recon_line_tbl(gn_line_cnt).sub_acct_code     -- 補助科目コード
                      , iv_segment5  => gv_cust_dummy                                   -- 顧客コード
                      , iv_segment6  => gv_comp_dummy                                   -- 企業コード
                      , iv_segment7  => gv_pre1_dummy                                   -- 予備１コード
                      , iv_segment8  => gv_pre2_dummy                                   -- 予備２コード
                      );
    IF ( gn_detail_ccid IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00034
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 4-3.請求書明細OIF登録
    -- ============================================================
    INSERT INTO ap_invoice_lines_interface(
      invoice_id                                        -- 請求書ID
    , invoice_line_id                                   -- 請求書明細ID
    , line_number                                       -- 明細行番号
    , line_type_lookup_code                             -- 明細タイプ
    , amount                                            -- 明細金額
    , description                                       -- 摘要
    , tax_code                                          -- 税区分
    , dist_code_combination_id                          -- CCID
    , last_updated_by                                   -- 最終更新者
    , last_update_date                                  -- 最終更新日
    , last_update_login                                 -- 最終ログインID
    , created_by                                        -- 作成者
    , creation_date                                     -- 作成日
    , attribute_category                                -- DFFコンテキスト
    , attribute10                                       -- DFF10(電子データ受領)
    , attribute13                                       -- DFF13(適格請求書)
    , attribute15                                       -- DFF15(伝票作成会社)
    , org_id                                            -- 組織ID
    )
    VALUES (
      gn_invoice_id                                     -- 請求書ID
    , ap_invoice_lines_interface_s.NEXTVAL              -- 請求書明細ID
    , gn_detail_num                                     -- 明細行番号
    , cv_item                                           -- 明細タイプ
    , g_recon_line_tbl(gn_line_cnt).payment_amt         -- 明細金額
    , g_recon_line_tbl(gn_line_cnt).remarks             -- 摘要
    , cv_0000                                           -- 税区分
    , gn_detail_ccid                                    -- CCID
    , cn_last_updated_by                                -- 最終更新者
    , SYSDATE                                           -- 最終更新日
    , cn_last_update_login                              -- 最終ログインID
    , cn_created_by                                     -- 作成者
    , SYSDATE                                           -- 作成日
    , gn_org_id                                         -- DFFコンテキスト
    , g_recon_head_tbl(gn_head_cnt).invoice_ele_data    -- DFF10(電子データ受領)
    , g_recon_head_tbl(gn_head_cnt).invoice_t_num       -- DFF13(適格請求書)
    , g_recon_head_tbl(gn_head_cnt).drafting_company    -- DFF15(伝票作成会社)
    , gn_org_id                                         -- 組織ID
    );
    -- ヘッダー用に金額を集計する
    gn_invoice_amount := gn_invoice_amount + NVL(g_recon_line_tbl(gn_line_cnt).payment_amt,0);
    -- 連番をカウントアップ
    gn_detail_num := gn_detail_num + 1;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--#################################  固定例外処理部 END  #################################
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_header_data
   * Description      : A-5.請求書ヘッダー登録処理
   ***********************************************************************************/
  PROCEDURE ins_header_data(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_header_data';      -- プログラム名
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
--
    -- *** ローカル変数 ***
    lt_attribute1   ap_terms_v.attribute1%TYPE;
    lt_term_id      ap_terms_v.term_id%TYPE;
    ln_debt_acct_ccid         NUMBER;             -- 負債勘定CCID
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
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
    -- ============================================================
    -- 5-1.負債勘定CCID取得
    -- ============================================================
    ln_debt_acct_ccid := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date   -- 処理日
                         , iv_segment1  => g_recon_head_tbl(gn_head_cnt).drafting_company  -- 会社コード(伝票作成会社)
                         , iv_segment2  => g_recon_head_tbl(gn_head_cnt).fin_dept_code     -- 部門コード(伝票作成会社の管理部門)
                         , iv_segment3  => gv_payable        -- 勘定科目コード(未払金)
                         , iv_segment4  => gv_asst_dummy     -- 補助科目コード(ダミー値)
                         , iv_segment5  => gv_cust_dummy     -- 顧客コード(ダミー値)
                         , iv_segment6  => gv_comp_dummy     -- 企業コード(ダミー値)
                         , iv_segment7  => gv_pre1_dummy     -- 予備１コード(ダミー値)
                         , iv_segment8  => gv_pre2_dummy     -- 予備２コード(ダミー値)
                       );
    -- 5-2
    IF ( ln_debt_acct_ccid IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00034
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 5-3.支払条件情報取得
    -- ============================================================
    BEGIN
      SELECT atv.attribute1   AS  attribute1
            ,atv.term_id      AS  term_id
      INTO   lt_attribute1
            ,lt_term_id
      FROM   ap_terms_v   atv
      WHERE  atv.name = g_recon_head_tbl(gn_head_cnt).terms_name
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00032
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF    ( lt_attribute1 IS NULL )
      OR  ( lt_term_id  IS NULL )
    THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00032
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 5-5.請求書ヘッダー登録
    -- ============================================================
--
    INSERT INTO ap_invoices_interface (
      invoice_id                              -- 請求書ID
    , invoice_num                             -- 請求書番号
    , invoice_type_lookup_code                -- 取引タイプ
    , invoice_date                            -- 請求日付
    , vendor_num                              -- 仕入先コード
    , vendor_site_code                        -- 仕入先サイトコード
    , invoice_amount                          -- 請求金額
    , terms_id                                -- 支払条件ID
    , description                             -- 摘要
    , last_update_date                        -- 最終更新日
    , last_updated_by                         -- 最終更新者
    , last_update_login                       -- 最終ログインID
    , creation_date                           -- 作成日
    , created_by                              -- 作成者
    , attribute_category                      -- DFFコンテキスト
    , attribute2                              -- 請求書番号
    , attribute3                              -- 起票部門
    , attribute4                              -- 伝票入力者
    , source                                  -- ソース
    , gl_date                                 -- 仕訳計上日
    , accts_pay_code_combination_id           -- 負債勘定CCID
    , org_id                                  -- 組織ID
    , terms_date                              -- 支払起算日
    )
    VALUES (
      gn_invoice_id                                     -- 請求書ID
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- 請求書番号
    , CASE
        WHEN gn_invoice_amount >= 0 THEN
          cv_standard
        WHEN gn_invoice_amount < 0 THEN
          cv_credit
      END                                               -- 取引タイプ
    , g_recon_head_tbl(gn_head_cnt).invoice_date        -- 請求書日付
    , g_recon_head_tbl(gn_head_cnt).vendor_code         -- 仕入先コード
    , g_recon_head_tbl(gn_head_cnt).vendor_site_code    -- 仕入先サイトコード
    , gn_invoice_amount                                 -- 請求金額
    , lt_term_id                                        -- 支払条件ID
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- 摘要
    , SYSDATE                                           -- 最終更新日
    , cn_last_updated_by                                -- 最終更新者
    , cn_last_update_login                              -- 最終ログインID
    , SYSDATE                                           -- 作成日
    , cn_created_by                                     -- 作成者
    , gn_org_id                                         -- 組織ID
    , g_recon_head_tbl(gn_head_cnt).invoice_number      -- 受領請求書番号
    , g_recon_head_tbl(gn_head_cnt).recon_base_code     -- 起票部門
    , g_recon_head_tbl(gn_head_cnt).applicant           -- 伝票入力者
    , gv_source_dedu_ap                                 -- 請求書ソース
    , g_recon_head_tbl(gn_head_cnt).gl_date             -- 仕訳計上日
    , ln_debt_acct_ccid                                 -- 負債勘定CCID
    , gn_org_id                                         -- 組織ID
    , CASE
        WHEN lt_attribute1 = 'Y' THEN
          g_recon_head_tbl(gn_head_cnt).recon_due_date
        WHEN lt_attribute1 = 'N' THEN
          g_recon_head_tbl(gn_head_cnt).invoice_date
      END                                               -- 支払起算日
    );
--
    --正常件数をカウントアップ
    gn_normal_cnt := gn_normal_cnt + 1;
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--#################################  固定例外処理部 END  #################################
--
  END ins_header_data;
--
  /**********************************************************************************
   * Procedure Name   : update_recon_data
   * Description      : A-6.消込データ更新
   ***********************************************************************************/
  PROCEDURE update_recon_data(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_recon_data';      -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
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
    -- ============================================================
    -- 6-1.消込ヘッダー更新
    -- ============================================================
    UPDATE xxcok_deduction_recon_head
    SET    ap_ar_if_flag            = 'Y'
          ,last_updated_by          = cn_last_updated_by
          ,last_update_date         = SYSDATE
          ,last_update_login        = cn_last_update_login
          ,request_id               = cn_request_id
          ,program_application_id   = cn_program_application_id
          ,program_id               = cn_program_id
          ,program_update_date      = SYSDATE
    WHERE  deduction_recon_head_id  = g_recon_head_tbl(gn_head_cnt).header_id
    ;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--#################################  固定例外処理部 END  #################################
--
  END update_recon_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
                    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
                    ,ov_errmsg       OUT VARCHAR2 )        --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg  VARCHAR2(5000);                                        -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
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
    -- <カーソル名>
--
    -- <カーソル名>レコード型
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    -- グローバル変数の初期化
    gn_target_cnt                 := 0;                     -- 対象件数
    gn_normal_cnt                 := 0;                     -- 正常件数
    gn_error_cnt                  := 0;                     -- エラー件数
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.消込ヘッダー情報取得
    -- ===============================
    get_recon_header(
        ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
   -- ===============================
   -- A-3.消込明細情報取得
   -- ===============================
   get_recon_line(
       ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
      ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
      ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
   );
--
   IF ( lv_retcode = cv_status_error ) THEN
     RAISE global_process_expt;
   END IF;
--
   <<recon_line_loop>>
   FOR rl IN 1..g_recon_line_tbl.COUNT LOOP
     -- ===============================
     -- A-4.請求書明細登録処理
     -- ===============================
     ins_detail_data(
         ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
        ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
        ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
     );
--
     IF ( lv_retcode = cv_status_error ) THEN
       RAISE global_process_expt;
     END IF;
--
     gn_line_cnt := gn_line_cnt + 1;
--
   END LOOP recon_line_loop;
   -- ===============================
   -- A-5.請求書ヘッダー登録処理
   -- ===============================
   ins_header_data(
       ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
      ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
      ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
   );
--
   IF ( lv_retcode = cv_status_error ) THEN
     RAISE global_process_expt;
   END IF;
--
   -- ===============================
   -- A-6.消込ヘッダー更新処理
   -- ===============================
   update_recon_data(
       ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
      ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
      ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
   );
--
   IF ( lv_retcode = cv_status_error ) THEN
     RAISE global_process_expt;
   END IF;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#####################################  固定部 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main( errbuf           OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
                 ,retcode          OUT VARCHAR2               -- リターン・コード    --# 固定 #
                 ,in_recon_head_id IN  NUMBER    )            -- 控除消込ヘッダーID
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
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
--####################################  固定部 START  ####################################--
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
--
--#####################################  固定部 END  #####################################
--
    -- 入力パラメータを変数に格納
    gn_recon_head_id              := in_recon_head_id;     -- 入力パラメータ.控除消込ヘッダID
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf        => lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,ov_retcode       => lv_retcode        -- リターン・コード             --# 固定 #
            ,ov_errmsg        => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    -- ===============================
    -- A-12.終了処理
    -- ===============================
    -- 終了ステータスがエラーの場合
    IF (lv_retcode = cv_status_error) THEN
      -- 処理件数の設定
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
--
      -- エラー出力
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
    -- 1.処理件数メッセージ出力
    -- ===============================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90000
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90001
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_msg_xxccp_90002
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.処理終了メッセージ
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
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
--
--#####################################  固定部 END  #####################################
--
  END main;
--
END XXCOK024A45C;
/
