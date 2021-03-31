CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A16C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A16C (body)
 * Description      : 控除額の支払画面より入力された承認済の問屋への支払情報を
 *                  : APへ連携します。また、承認後APに連携済の支払伝票が取消された場合、
 *                  : 赤伝票をAPへ連携します。
 * MD.050           : 問屋控除支払AP連携 MD050_COK_024_A16
 * Version          : 1.00
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
 *  get_cancel_header      A-7.取消ヘッダー情報取得
 *  get_cancel_line        A-8.取消明細情報取得
 *  ins_cancel_header      A-9.取消ヘッダー登録処理
 *  ins_cancel_line        A-10.取消明細登録処理
 *  update_cabcel_data     A-11.取消データ更新
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/08/25    1.0   N.Abe            新規作成
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
  gn_c_target_cnt  NUMBER;                    -- 対象件数（取消）
  gn_c_normal_cnt  NUMBER;                    -- 正常件数（取消）
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
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A16C';                     -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- 共通領域短縮アプリ名
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_msg_xxcok_00003     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_msg_xxcok_00028     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- 業務処理日付取得エラー
  cv_msg_xxcok_00034     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00034';                 -- 勘定科目情報取得エラー
  cv_msg_xxcok_00059     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00059';                 -- 会計期間取得エラー
  cv_msg_xxcok_10632     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10632';                 -- ロックエラーメッセージ
  cv_msg_xxccp_90000     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- 対象件数メッセージ
  cv_msg_xxccp_90001     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- 成功件数メッセージ
  cv_msg_xxccp_90002     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- エラー件数メッセージ
  cv_msg_xxccp_90004     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_msg_xxccp_90006     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- エラー終了全ロールバック
  cv_msg_xxcok_10714     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10714';                 -- 取消対象件数
  cv_msg_xxcok_10717     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10717';                 -- 取消成功件数
  cv_msg_xxcok_00032     CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00032';                 -- 支払条件取得エラー
  -- トークン
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- プロファイル名
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- 件数メッセージ用トークン名
  -- プロファイル
  cv_prof_set_of_bks_id  CONSTANT VARCHAR2(16) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_prof_org_id         CONSTANT VARCHAR2(6)  := 'ORG_ID';                           -- 営業単位
  cv_prof_comp_code      CONSTANT VARCHAR2(24) := 'XXCOK1_AFF1_COMPANY_CODE';         -- 会社コード
  cv_prof_dept_fin       CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_FIN';             -- 部門コード_財務経理部
  cv_prof_payable        CONSTANT VARCHAR2(19) := 'XXCOK1_AFF3_PAYABLE';              -- 勘定科目_未払金
  cv_prof_sub_acct_dummy CONSTANT VARCHAR2(25) := 'XXCOK1_AFF4_SUBACCT_DUMMY';        -- 補助科目_ダミー値
  cv_prof_cust_dummy     CONSTANT VARCHAR2(26) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- 顧客コード_ダミー値
  cv_prof_comp_dummy     CONSTANT VARCHAR2(25) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- 企業コード_ダミー値
  cv_prof_pre1_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- 予備１_ダミー値
  cv_prof_pre2_dummy     CONSTANT VARCHAR2(30) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- 予備２_ダミー値
  cv_prof_souce_dedu     CONSTANT VARCHAR2(26) := 'XXCOK1_INVOICE_SOURCE_DEDU';       -- 請求書ソース（販売控除）
  -- クイックコード
  cv_lkup_dedu_type      CONSTANT VARCHAR2(26) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- 控除データ種類
  cv_lkup_tax_conv       CONSTANT VARCHAR2(28) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- 消費税コード変換マスタ
  cv_lkup_chain_code     CONSTANT VARCHAR2(16) := 'XXCMM_CHAIN_CODE';                 -- チェーン店情報
  -- 言語
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- 言語
  -- 消込ステータス
  cv_ad                  CONSTANT VARCHAR2(2)  := 'AD';                               -- 承認済
  cv_cd                  CONSTANT VARCHAR2(2)  := 'CD';                               -- 取消済
  -- 連携先
  cv_wp                  CONSTANT VARCHAR2(2)  := 'WP';                               -- AP問屋
  -- 明細タイプ
  cv_item                CONSTANT VARCHAR2(4)  := 'ITEM';                             -- 明細タイプ（明細）
  cv_tax                 CONSTANT VARCHAR2(3)  := 'TAX';                              -- 明細タイプ（税）
  -- 税コード
  cv_0000                CONSTANT VARCHAR2(4)  := '0000';                             -- 税コード（ダミー）
  -- 取引タイプ
  cv_standard            CONSTANT VARCHAR2(8)  := 'STANDARD';                         -- 金額（正）
  cv_credit              CONSTANT VARCHAR2(6)  := 'CREDIT';                           -- 金額（負）
  -- 支払条件
  cv_99_99_99            CONSTANT VARCHAR2(9)  := '99_99_99';                         -- 支払条件
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
      ,terms_name               xxcok_deduction_recon_head.terms_name%TYPE                -- 支払条件
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
      ,tax_code                 VARCHAR2(150)         -- 税コード
      ,line_type                VARCHAR2(4)           -- 明細タイプ
      ,dept_code                VARCHAR2(4)           -- 部門コード
      ,acct_code                VARCHAR2(150)         -- 勘定科目
      ,sub_acct_code            VARCHAR2(150)         -- 補助科目
      ,comp_code                VARCHAR2(150)         -- 企業コード
      ,cust_code                VARCHAR2(150)         -- 顧客コード
      ,ccid                     NUMBER                -- CCID
  );
  -- 消込明細情報ワークテーブル型定義
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- 消込明細情報テーブル型変数
  g_recon_line_tbl        g_recon_line_ttype;         -- 消込明細情報取得
--
  -- 取消ヘッダレコード型定義
  TYPE g_cancel_header_rtype IS RECORD(
       invoice_id               ap_invoices_all.invoice_id%TYPE                           -- 請求書ID
      ,type_code                ap_invoices_all.invoice_type_lookup_code%TYPE             -- 取引タイプ
      ,invoice_date             ap_invoices_all.invoice_date%TYPE                         -- 請求書日付
      ,vendor_id                ap_invoices_all.vendor_id%TYPE                            -- 仕入先ID
      ,vendor_site_id           ap_invoices_all.vendor_site_id%TYPE                       -- 仕入先サイトID
      ,invoice_amount           ap_invoices_all.invoice_amount%TYPE                       -- 請求金額
      ,terms_id                 ap_invoices_all.terms_id%TYPE                             -- 支払条件ID
      ,description              ap_invoices_all.description%TYPE                          -- 摘要
      ,attribute_category       ap_invoices_all.attribute_category%TYPE                   -- DFFコンテキスト
      ,attribute2               ap_invoices_all.attribute2%TYPE                           -- 請求書番号
      ,attribute3               ap_invoices_all.attribute3%TYPE                           -- 起票部門
      ,attribute4               ap_invoices_all.attribute4%TYPE                           -- 伝票入力者
      ,source                   ap_invoices_all.source%TYPE                               -- 請求書ソース
      ,gl_date                  ap_invoices_all.gl_date%TYPE                              -- 仕訳計上日
      ,ccid                     ap_invoices_all.accts_pay_code_combination_id%TYPE        -- 負債勘定CCID
      ,org_id                   ap_invoices_all.org_id%TYPE                               -- 組織ID
      ,terms_date               ap_invoices_all.terms_date%TYPE                           -- 支払起算日
      ,header_id                xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- 控除消込ヘッダーID
  );
  -- 取消ヘッダワークテーブル型定義
  TYPE g_cancel_head_ttype    IS TABLE OF g_cancel_header_rtype INDEX BY BINARY_INTEGER;
  -- 取消ヘッダテーブル型変数
  g_cancel_head_tbl        g_cancel_head_ttype;         -- 取消ヘッダ取得
--
  -- 取消明細ワークテーブル定義
  TYPE g_cancel_line_rtype IS RECORD(
       line_num                 ap_invoice_distributions_all.distribution_line_number%TYPE  -- 明細番号
      ,line_type                ap_invoice_distributions_all.line_type_lookup_code%TYPE     -- 明細タイプ
      ,amount                   ap_invoice_distributions_all.amount%TYPE                    -- 明細金額
      ,description              ap_invoice_distributions_all.description%TYPE               -- 摘要
      ,tax_code                 ap_tax_codes_all.name%TYPE                                  -- 税区分
      ,ccid                     ap_invoice_distributions_all.dist_code_combination_id%TYPE  -- CCID
  );
  -- 取消明細情報ワークテーブル型定義
  TYPE g_cancel_line_ttype    IS TABLE OF g_cancel_line_rtype INDEX BY BINARY_INTEGER;
  -- 取消明細情報テーブル型変数
  g_cancel_line_tbl        g_cancel_line_ttype;         -- 取消明細情報取得

  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gd_process_date             DATE;                                                   -- 業務処理費輔
  gn_set_bks_id               NUMBER;                                                 -- 会計帳簿ID
  gn_org_id                   NUMBER;                                                 -- 営業単位
  gv_comp_code                VARCHAR2(40);                                           -- 会社コード
  gv_dept_fin                 VARCHAR2(40);                                           -- 部門コード_財務経理部
  gv_payable                  VARCHAR2(40);                                           -- 勘定科目_未払金
  gv_asst_dummy               VARCHAR2(40);                                           -- 補助科目_ダミー値
  gv_cust_dummy               VARCHAR2(40);                                           -- 顧客コード_ダミー値
  gv_comp_dummy               VARCHAR2(40);                                           -- 企業コード_ダミー値
  gv_pre1_dummy               VARCHAR2(40);                                           -- 予備１_ダミー値
  gv_pre2_dummy               VARCHAR2(40);                                           -- 予備２_ダミー値
  gv_source_dedu              VARCHAR2(40);                                           -- 請求書ソース（販売控除）
  gn_invoice_id               NUMBER;                                                 -- 請求書ID
  gn_debt_acct_ccid           NUMBER;                                                 -- CCID（ヘッダ）
  gn_detail_ccid              NUMBER;                                                 -- CCID（明細）
  --
  gn_head_cnt                 NUMBER  DEFAULT 1;                                      -- 消込ヘッダー用カウンタ
  gn_line_cnt                 NUMBER  DEFAULT 1;                                      -- 消込明細用カウンタ
  gn_c_head_cnt               NUMBER  DEFAULT 1;                                      -- 取消ヘッダー用カウンタ
  gn_c_line_cnt               NUMBER  DEFAULT 1;                                      -- 消込明細用カウンタ
  --
  gn_invoice_amount           NUMBER  DEFAULT 0;                                      -- 明細金額集計用
  gn_detail_num               NUMBER  DEFAULT 1;                                      -- 連番（明細）
  gv_bk_slip_num              xxcok_deduction_recon_head.recon_slip_num%TYPE;         -- 伝票番号比較用
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
    -- 会社コード
    gv_comp_code := FND_PROFILE.VALUE( cv_prof_comp_code );
--
    IF ( gv_comp_code IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_comp_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 部門コード_財務経理部
    gv_dept_fin := FND_PROFILE.VALUE( cv_prof_dept_fin );
--
    IF ( gv_dept_fin IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_dept_fin
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
    -- 請求書ソース（販売控除）
    gv_source_dedu := FND_PROFILE.VALUE( cv_prof_souce_dedu );
--
    IF ( gv_source_dedu IS NULL ) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_msg_xxcok_00003
                     ,cv_tkn_profile
                     ,cv_prof_souce_dedu
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================
    -- 3.オープンGL会計期間の取得
    -- ==============================================================
    BEGIN
      SELECT MIN( gps.end_date ) AS acct_period
      INTO   gd_acct_period
      FROM   gl_period_statuses   gps
            ,fnd_application      fa
      WHERE  fa.application_short_name  = 'SQLGL'
      AND    gps.application_id         = fa.application_id
      AND    gps.adjustment_period_flag = 'N'
      AND    gps.closing_status         = 'O'
      AND    gps.set_of_books_id        = gn_set_bks_id
      ;
--
      IF ( gd_acct_period IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00059
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00059
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ==============================================================
    -- 4.負債勘定科目CCID取得
    -- ==============================================================
    gn_debt_acct_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date   -- 処理日
                       ,iv_segment1  => gv_comp_code      -- 会社コード
                       ,iv_segment2  => gv_dept_fin       -- 部門コード
                       ,iv_segment3  => gv_payable        -- 勘定科目コード
                       ,iv_segment4  => gv_asst_dummy     -- 補助科目コード
                       ,iv_segment5  => gv_cust_dummy     -- 顧客コード
                       ,iv_segment6  => gv_comp_dummy     -- 企業コード
                       ,iv_segment7  => gv_pre1_dummy     -- 予備１コード
                       ,iv_segment8  => gv_pre2_dummy     -- 予備２コード
                      );
--
    IF ( gn_debt_acct_ccid IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00034
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
             xdrh.recon_slip_num           AS recon_slip_num          -- 支払伝票番号
            ,xdrh.recon_base_code          AS recon_base_code         -- 支払請求拠点
            ,fu.user_name                  AS applicant               -- 申請者
            ,xdrh.deduction_chain_code     AS deduction_chain_code    -- 控除用チェーンコード
            ,xdrh.recon_due_date           AS recon_due_date          -- 支払予定日
            ,xdrh.gl_date                  AS gl_date                 -- GL記帳日
            ,xdrh.invoice_date             AS invoice_date            -- 請求書日付
            ,pv.segment1                   AS vendor_code             -- 仕入先
            ,pvsa.vendor_site_code         AS vendor_site_code        -- 仕入先サイト
            ,xdrh.deduction_recon_head_id  AS header_id               -- 控除消込ヘッダーID
            ,xdrh.terms_name               AS terms_name              -- 支払条件
      FROM   xxcok_deduction_recon_head    xdrh                       -- 控除消込ヘッダー情報
            ,po_vendor_sites_all           pvsa                       -- 仕入先サイト
            ,po_vendors                    pv                         -- 仕入先
            ,fnd_user                      fu                         -- ユーザーマスタ
            ,per_all_people_f              papf                       -- 従業員マスタ
      WHERE  xdrh.recon_status             =        cv_ad             -- 承認済
      AND    xdrh.interface_div            =        cv_wp             -- AP問屋
      AND    xdrh.ap_ar_if_flag            =        'N'               -- 未連携
      AND    pv.segment1(+)                =        xdrh.payee_code
      AND    pvsa.vendor_id(+)             =        pv.vendor_id
      AND    pvsa.org_id(+)                =        gn_org_id
      AND    xdrh.applicant                =        papf.employee_number(+)
      AND    papf.person_id                =        fu.employee_id(+)
      AND    TRUNC(gd_process_date)        BETWEEN  TRUNC(papf.effective_start_date(+))
                                           AND      TRUNC(NVL(papf.effective_end_date(+), gd_process_date))
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
              xdnr.payment_amt  AS  payment_amt     -- 支払額
             ,xdnr.remarks      AS  remarks         -- 摘要
             ,cv_0000           AS  tax_code        -- 税コード
             ,cv_item           AS  line_type       -- 明細タイプ 
             ,gv_dept_fin       AS  dept_code       -- 部門コード
             ,flv.attribute6    AS  acct_code       -- 勘定科目
             ,flv.attribute7    AS  sub_acct_code   -- 補助科目
             ,gv_comp_dummy     AS  comp_code       -- 企業コード
             ,gv_cust_dummy     AS  cust_code       -- 顧客コード
             ,NULL              AS  ccid            -- ccid
      FROM    xxcok_deduction_num_recon   xdnr  -- 控除No別消込情報
             ,fnd_lookup_values           flv   -- データ種類
      WHERE   xdnr.recon_slip_num = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag    = 'Y'
      AND     flv.lookup_type     = cv_lkup_dedu_type
      AND     flv.lookup_code     = xdnr.data_type
      AND     flv.language        = cv_lang
      AND     flv.enabled_flag    = 'Y'
      UNION ALL
      -- 控除No別消込情報_税
      SELECT  /*+ index(xdhr xxcok_deduction_num_recon_n01) */
              SUM(xdnr.payment_tax) AS  payment_amt     -- 支払額
             ,atca.name             AS  remarks         -- 摘要
             ,cv_0000               AS  tax_code        -- 税コード
             ,cv_item               AS  line_type       -- 明細タイプ 
             ,gv_dept_fin           AS  dept_code       -- 部門コード
             ,atca.attribute5       AS  acct_code       -- 勘定科目
             ,atca.attribute6       AS  sub_acct_code   -- 補助科目
             ,gv_comp_dummy         AS  comp_code       -- 企業コード
             ,gv_cust_dummy         AS  cust_code       -- 顧客コード
             ,NULL                  AS  ccid            -- ccid
      FROM    xxcok_deduction_num_recon   xdnr  -- 控除No別消込情報
             ,ap_tax_codes_all            atca  -- AP税コードマスタ
             ,fnd_lookup_values           flv   -- 税コード変換マスタ
      WHERE   xdnr.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     xdnr.target_flag      = 'Y'
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xdnr.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      GROUP BY atca.name
              ,atca.attribute5
              ,atca.attribute6
      UNION ALL
      -- 販売控除情報_本体
      SELECT  /*+ index(xsd xxcok_sales_deduction_n05) */
              SUM(xsd.deduction_amount) AS  payment_amt     -- 支払額
             ,flv.meaning               AS  remarks         -- 摘要
             ,cv_0000                   AS  tax_code        -- 税コード
             ,cv_item                   AS  line_type       -- 明細タイプ 
             ,gv_dept_fin               AS  dept_code       -- 部門コード
             ,flv.attribute6            AS  acct_code       -- 勘定科目
             ,flv.attribute7            AS  sub_acct_code   -- 補助科目
             ,gv_comp_dummy             AS  comp_code       -- 企業コード
             ,gv_cust_dummy             AS  cust_code       -- 顧客コード
             ,NULL                      AS  ccid            -- ccid
      FROM    xxcok_sales_deduction       xsd   -- 販売控除情報
             ,fnd_lookup_values           flv   -- データ種類
      WHERE   xsd.recon_slip_num    = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_dedu_type
      AND     flv.lookup_code       = xsd.data_type
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     flv.attribute2       IN ('030', '040')
      GROUP BY xsd.data_type
              ,flv.meaning
              ,flv.attribute6
              ,flv.attribute7
      UNION ALL
      -- 販売控除情報_税
      SELECT  /*+ index(xsd xxcok_sales_deduction_n05) */
              SUM(xsd.deduction_tax_amount) AS  payment_amt     -- 支払額
             ,atca.name                     AS  remarks         -- 摘要
             ,cv_0000                       AS  tax_code        -- 税コード
             ,cv_item                       AS  line_type       -- 明細タイプ 
             ,gv_dept_fin                   AS  dept_code       -- 部門コード
             ,atca.attribute5               AS  acct_code       -- 勘定科目
             ,atca.attribute6               AS  sub_acct_code   -- 補助科目
             ,gv_comp_dummy                 AS  comp_code       -- 企業コード
             ,gv_cust_dummy                 AS  cust_code       -- 顧客コード
             ,NULL                          AS  ccid            -- ccid
      FROM    xxcok_sales_deduction       xsd   -- 販売控除情報
             ,ap_tax_codes_all            atca  -- AP税コードマスタ
             ,fnd_lookup_values           flv   -- 税コード変換マスタ
             ,fnd_lookup_values           flv2  -- データ種類
      WHERE   xsd.recon_slip_num    = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xsd.recon_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
      AND     flv2.lookup_type      = cv_lkup_dedu_type
      AND     flv2.lookup_code      = xsd.data_type
      AND     flv2.language         = cv_lang
      AND     flv2.enabled_flag     = 'Y'
      AND     flv2.attribute2      IN ('030', '040')
      GROUP BY atca.name
              ,atca.attribute5
              ,atca.attribute6
      UNION ALL
      -- 科目支払情報_本体
      SELECT  /*+ index(xapi xxcok_account_payment_info_n01) */
              xapi.payment_amt                    AS  payment_amt     -- 支払額
             ,xapi.remarks                        AS  remarks         -- 摘要
             ,flv.attribute1                      AS  tax_code        -- 税コード
             ,cv_item                             AS  line_type       -- 明細タイプ 
             ,xapi.base_code                      AS  dept_code       -- 部門コード
             ,xapi.acct_code                      AS  acct_code       -- 勘定科目
             ,xapi.sub_acct_code                  AS  sub_acct_code   -- 補助科目
             ,NVL(flv2.attribute1, gv_comp_dummy) AS  comp_code       -- 企業コード
             ,NVL(flv2.attribute4, gv_cust_dummy) AS  cust_code       -- 顧客コード
             ,NULL                                AS  ccid            -- ccid
      FROM    xxcok_account_payment_info  xapi  -- 科目支払情報
             ,fnd_lookup_values           flv   -- 税コード変換マスタ
             ,fnd_lookup_values           flv2  -- チェーン店情報
      WHERE   xapi.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xapi.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     flv2.lookup_type(+)   = cv_lkup_chain_code
      AND     flv2.lookup_code(+)   = xapi.deduction_chain_code
      AND     flv2.language(+)      = cv_lang
      AND     flv2.enabled_flag(+)  = 'Y'
      UNION ALL
      -- 科目支払情報_税
      SELECT  /*+ index(xapi xxcok_account_payment_info_n01) */
              xapi.payment_tax              AS  payment_amt     -- 支払額
             ,xapi.remarks                  AS  remarks         -- 摘要
             ,flv.attribute1                AS  tax_code        -- 税コード
             ,cv_tax                        AS  line_type       -- 明細タイプ 
             ,xapi.base_code                AS  dept_code       -- 部門コード
             ,NULL                          AS  acct_code       -- 勘定科目
             ,NULL                          AS  sub_acct_code   -- 補助科目
             ,NULL                          AS  comp_code       -- 企業コード
             ,NULL                          AS  cust_code       -- 顧客コード
             ,atca.tax_code_combination_id  AS  ccid            -- ccid
      FROM    xxcok_account_payment_info  xapi  -- 科目支払情報
             ,ap_tax_codes_all            atca  -- AP税コードマスタ
             ,fnd_lookup_values           flv   -- 税コード変換マスタ
      WHERE   xapi.recon_slip_num   = g_recon_head_tbl(gn_head_cnt).recon_slip_num
      AND     flv.lookup_type       = cv_lkup_tax_conv
      AND     flv.lookup_code       = xapi.payment_tax_code
      AND     flv.language          = cv_lang
      AND     flv.enabled_flag      = 'Y'
      AND     atca.name             = flv.attribute1
      AND     atca.set_of_books_id  = gn_set_bks_id
      AND     atca.org_id           = gn_org_id
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
    -- 前回伝票番号がNULL又は、前回と違う場合取得
    IF    ( gv_bk_slip_num IS NULL )
      OR  ( g_recon_head_tbl(gn_head_cnt).recon_slip_num <> gv_bk_slip_num ) 
    THEN
      -- 比較用変数に格納
      gv_bk_slip_num := g_recon_head_tbl(gn_head_cnt).recon_slip_num;
--
      -- シーケンスから請求書IDを取得
      SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    END IF;
--
    -- ============================================================
    -- 4-2.CCID取得
    -- ============================================================
    -- 明細から取得したCCIDが設定されている場合は、取得しない
    IF ( g_recon_line_tbl(gn_line_cnt).ccid IS NULL ) THEN
      gn_detail_ccid := xxcok_common_pkg.get_code_combination_id_f(
                          id_proc_date => gd_process_date                             -- 処理日
                        , iv_segment1  => gv_comp_code                                -- 会社コード
                        , iv_segment2  => g_recon_line_tbl(gn_line_cnt).dept_code     -- 部門コード
                        , iv_segment3  => g_recon_line_tbl(gn_line_cnt).acct_code     -- 勘定科目コード
                        , iv_segment4  => g_recon_line_tbl(gn_line_cnt).sub_acct_code -- 補助科目コード
                        , iv_segment5  => g_recon_line_tbl(gn_line_cnt).cust_code     -- 顧客コード
                        , iv_segment6  => g_recon_line_tbl(gn_line_cnt).comp_code     -- 企業コード
                        , iv_segment7  => gv_pre1_dummy                               -- 予備１コード
                        , iv_segment8  => gv_pre2_dummy                            -- 予備２コード
                        );
      IF ( gn_detail_ccid IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        cv_xxcok_short_nm
                       ,cv_msg_xxcok_00034
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ============================================================
    -- 4-4.請求書明細OIF登録
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
    , org_id                                            -- 組織ID
    )
    VALUES (
      gn_invoice_id                                             -- 請求書ID
    , ap_invoice_lines_interface_s.NEXTVAL                      -- 請求書明細ID
    , gn_detail_num                                             -- 明細行番号
    , g_recon_line_tbl(gn_line_cnt).line_type                   -- 明細タイプ
    , g_recon_line_tbl(gn_line_cnt).payment_amt                 -- 明細金額
    , g_recon_line_tbl(gn_line_cnt).remarks                     -- 摘要
    , g_recon_line_tbl(gn_line_cnt).tax_code                    -- 税区分
    , NVL( g_recon_line_tbl(gn_line_cnt).ccid, gn_detail_ccid ) -- CCID
    , cn_last_updated_by                                        -- 最終更新者
    , SYSDATE                                                   -- 最終更新日
    , cn_last_update_login                                      -- 最終ログインID
    , cn_created_by                                             -- 作成者
    , SYSDATE                                                   -- 作成日
    , gn_org_id                                                 -- DFFコンテキスト
    , gn_org_id                                                 -- 組織ID
    );
    -- ヘッダー用に金額を集計する
    gn_invoice_amount := gn_invoice_amount + g_recon_line_tbl(gn_line_cnt).payment_amt;
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
    lt_term_id     ap_terms_v.term_id%TYPE;
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
    -- 5-1.支払条件情報取得
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
    -- 5-2.請求書ヘッダー登録
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
    , creation_date                           -- 作成者
    , created_by                              -- 作成日
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
    , xxcok_common_pkg.get_slip_number_f( cv_pkg_name ) -- 請求書番号
    , CASE
        WHEN gn_invoice_amount >= 0 THEN
          cv_standard
        WHEN gn_invoice_amount < 0 THEN
          cv_credit
      END                                               -- 取引タイプ
    , g_recon_head_tbl(gn_head_cnt).invoice_date        -- 業務処理日付
    , g_recon_head_tbl(gn_head_cnt).vendor_code         -- 仕入先コード()
    , g_recon_head_tbl(gn_head_cnt).vendor_site_code    -- 仕入先サイトコード
    , gn_invoice_amount                                 -- 請求金額
    , lt_term_id                                        -- 支払条件ID
    , gv_source_dedu                                    -- 摘要
    , SYSDATE                                           -- 最終更新日
    , cn_last_updated_by                                -- 最終更新者
    , cn_last_update_login                              -- 最終ログインID
    , SYSDATE                                           -- 作成日
    , cn_created_by                                     -- 作成者
    , gn_org_id                                         -- 組織ID
    , g_recon_head_tbl(gn_head_cnt).recon_slip_num      -- 請求書番号
    , g_recon_head_tbl(gn_head_cnt).recon_base_code     -- 起票部門
    , g_recon_head_tbl(gn_head_cnt).applicant           -- 伝票入力者
    , gv_source_dedu                                    -- 請求書ソース
    , g_recon_head_tbl(gn_head_cnt).gl_date             -- 仕訳計上日
    , gn_debt_acct_ccid                                 -- 負債勘定科目CCID
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
   * Procedure Name   : get_cancel_header
   * Description      : A-7.取消ヘッダー情報取得
   ***********************************************************************************/
  PROCEDURE get_cancel_header(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_header';      -- プログラム名
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
--
    -- *** ローカル・カーソル ***
    -- 控除消込ヘッダ抽出カーソル
    CURSOR cancel_head_cur
    IS
      SELECT /*+ index(xdrh xxcok_deduction_recon_head_n02) */
             aia.invoice_id                     AS invoice_id         -- 請求書ID
            ,aia.invoice_type_lookup_code       AS type_code          -- 取引タイプ
            ,aia.invoice_date                   AS invoice_date       -- 請求書日付
            ,aia.vendor_id                      AS vendor_id          -- 仕入先ID
            ,aia.vendor_site_id                 AS vendor_site_id     -- 仕入先サイトID
            ,aia.invoice_amount * -1            AS invoice_amount     -- 請求金額
            ,aia.terms_id                       AS terms_id           -- 支払条件ID
            ,aia.description                    AS description        -- 摘要
            ,aia.attribute_category             AS attribute_category -- DFFコンテキスト
            ,aia.attribute2                     AS attribute2         -- 請求書番号
            ,aia.attribute3                     AS attribute3         -- 起票部門
            ,aia.attribute4                     AS attribute4         -- 伝票入力者
            ,aia.source                         AS source             -- 請求書ソース
            ,aia.gl_date                        AS gl_date            -- 仕訳計上日
            ,aia.accts_pay_code_combination_id  AS ccid               -- 負債勘定CCID
            ,aia.org_id                         AS org_id             -- 組織ID
            ,aia.terms_date                     AS terms_date         -- 支払起算日
            ,xdrh.deduction_recon_head_id       AS header_id          -- 控除消込ヘッダーID
      FROM   xxcok_deduction_recon_head    xdrh                       -- 控除消込ヘッダー情報
            ,ap_invoices_all               aia                        -- 請求書ヘッダー
      WHERE  xdrh.recon_status             = cv_cd                    -- 取消済
      AND    xdrh.interface_div            = cv_wp                    -- AP問屋
      AND    xdrh.ap_ar_if_flag            = 'Y'                      -- 連携済
      AND    aia.gl_date                   = xdrh.gl_date             -- 仕訳計上日
      AND    aia.set_of_books_id           = gn_set_bks_id            -- 会計帳簿ID
      AND    aia.attribute2                = xdrh.recon_slip_num      -- 伝票番号
      FOR UPDATE OF xdrh.deduction_recon_head_id NOWAIT
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
    -- ============================================================
    -- 1.取消ヘッダ情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  cancel_head_cur;
    -- データ取得
    FETCH cancel_head_cur BULK COLLECT INTO g_cancel_head_tbl;
    -- カーソルクローズ
    CLOSE cancel_head_cur;
--
    -- 取得した取消数を対象件数(取消）に格納
    gn_c_target_cnt := g_cancel_head_tbl.COUNT;        -- 対象件数（取消）
--
  EXCEPTION
--
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
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
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( cancel_head_cur%ISOPEN ) THEN
        CLOSE cancel_head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--#################################  固定例外処理部 END  #################################
--
  END get_cancel_header;
--
  /**********************************************************************************
   * Procedure Name   : get_cancel_line
   * Description      : A-8.取消明細情報取得
   ***********************************************************************************/
  PROCEDURE get_cancel_line(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cancel_line';      -- プログラム名
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
    -- 取消明細抽出カーソル
    CURSOR cancel_line_cur
    IS
      SELECT apda.distribution_line_number      AS line_num           -- 明細番号
            ,apda.line_type_lookup_code         AS line_type          -- 明細タイプ
            ,apda.amount * -1                   AS amount             -- 明細金額
            ,apda.description                   AS description        -- 摘要
            ,atca.name                          AS tax_code           -- 税区分
            ,apda.dist_code_combination_id      AS ccid               -- CCID
      FROM   ap_invoice_distributions_all   apda                      -- 請求書配布
            ,ap_tax_codes_all               atca                      -- AP税コードマスタ
      WHERE  apda.invoice_id            = g_cancel_head_tbl(gn_c_head_cnt).invoice_id
      AND    apda.tax_code_id           = atca.tax_id
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
    -- ============================================================
    -- 1.取消明細情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  cancel_line_cur;
    -- データ取得
    FETCH cancel_line_cur BULK COLLECT INTO g_cancel_line_tbl;
    -- カーソルクローズ
    CLOSE cancel_line_cur;
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
  END get_cancel_line;
--
  /**********************************************************************************
   * Procedure Name   : ins_cancel_header
   * Description      : A-9.取消ヘッダー登録処理
   ***********************************************************************************/
  PROCEDURE ins_cancel_header(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cancel_header';      -- プログラム名
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
    -- 9-1.請求書ID取得（取消）
    -- ============================================================
    SELECT ap_invoices_interface_s.nextval INTO gn_invoice_id FROM DUAL;
    -- ============================================================
    -- 9-1.取消ヘッダー登録
    -- ============================================================
--
    INSERT INTO ap_invoices_interface (
      invoice_id                              -- 請求書ID
    , invoice_num                             -- 請求書番号
    , invoice_type_lookup_code                -- 取引タイプ
    , invoice_date                            -- 請求日付
    , vendor_id                               -- 仕入先ID
    , vendor_site_id                          -- 仕入先サイトID
    , invoice_amount                          -- 請求金額
    , terms_id                                -- 支払条件ID
    , description                             -- 摘要
    , last_update_date                        -- 最終更新日
    , last_updated_by                         -- 最終更新者
    , last_update_login                       -- 最終ログインID
    , creation_date                           -- 作成者
    , created_by                              -- 作成日
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
      gn_invoice_id                                                       -- 請求書ID
    , xxcok_common_pkg.get_slip_number_f( cv_pkg_name )                   -- 請求書番号
    , CASE
        WHEN g_cancel_head_tbl(gn_c_head_cnt).invoice_amount >= 0 THEN
          cv_standard
        WHEN g_cancel_head_tbl(gn_c_head_cnt).invoice_amount  < 0 THEN
          cv_credit
      END                                                                 -- 取引タイプ
    , g_cancel_head_tbl(gn_c_head_cnt).invoice_date                       -- 業務処理日付
    , g_cancel_head_tbl(gn_c_head_cnt).vendor_id                          -- 仕入先ID
    , g_cancel_head_tbl(gn_c_head_cnt).vendor_site_ID                     -- 仕入先サイトID
    , g_cancel_head_tbl(gn_c_head_cnt).invoice_amount                     -- 請求金額
      , g_cancel_head_tbl(gn_c_head_cnt).terms_id                           -- 支払条件ID
    , g_cancel_head_tbl(gn_c_head_cnt).description                        -- 摘要
    , SYSDATE                                                             -- 最終更新日
    , cn_last_updated_by                                                  -- 最終更新者
    , cn_last_update_login                                                -- 最終ログインID
    , SYSDATE                                                             -- 作成日
    , cn_created_by                                                       -- 作成者
    , g_cancel_head_tbl(gn_c_head_cnt).attribute_category                 -- DFFコンテキスト
    , g_cancel_head_tbl(gn_c_head_cnt).attribute2                         -- 請求書番号
    , g_cancel_head_tbl(gn_c_head_cnt).attribute3                         -- 起票部門
    , g_cancel_head_tbl(gn_c_head_cnt).attribute4                         -- 伝票入力者
    , g_cancel_head_tbl(gn_c_head_cnt).source                             -- 請求書ソース
    , g_cancel_head_tbl(gn_c_head_cnt).gl_date                            -- 仕訳計上日
    , g_cancel_head_tbl(gn_c_head_cnt).ccid                               -- 負債勘定科目CCID
    , g_cancel_head_tbl(gn_c_head_cnt).org_id                             -- 組織ID
    , g_cancel_head_tbl(gn_c_head_cnt).terms_date                         -- 支払起算日
    );
--
    --正常件数（取消）をカウントアップ
    gn_c_normal_cnt := gn_c_normal_cnt + 1;
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
  END ins_cancel_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_cancel_line
   * Description      : A-10.取消明細登録処理
   ***********************************************************************************/
  PROCEDURE ins_cancel_line(
                      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cancel_line';              -- プログラム名
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
    -- 10-1.取消明細登録
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
    , org_id                                            -- 組織ID
    )
    VALUES (
      gn_invoice_id                                     -- 請求書ID
    , ap_invoice_lines_interface_s.NEXTVAL              -- 請求書明細ID
    , g_cancel_line_tbl(gn_c_line_cnt).line_num         -- 明細行番号
    , g_cancel_line_tbl(gn_c_line_cnt).line_type        -- 明細タイプ
    , g_cancel_line_tbl(gn_c_line_cnt).amount           -- 明細金額
    , g_cancel_line_tbl(gn_c_line_cnt).description      -- 摘要
    , g_cancel_line_tbl(gn_c_line_cnt).tax_code         -- 税区分
    , g_cancel_line_tbl(gn_c_line_cnt).ccid             -- CCID
    , cn_last_updated_by                                -- 最終更新者
    , SYSDATE                                           -- 最終更新日
    , cn_last_update_login                              -- 最終ログインID
    , cn_created_by                                     -- 作成者
    , SYSDATE                                           -- 作成日
    , gn_org_id                                         -- DFFコンテキスト
    , gn_org_id                                         -- 組織ID
    );
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
  END ins_cancel_line;
--
  /**********************************************************************************
   * Procedure Name   : update_cabcel_data
   * Description      : A-11.取消データ更新
   ***********************************************************************************/
  PROCEDURE update_cabcel_data(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cabcel_data';      -- プログラム名
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
    SET    ap_ar_if_flag            = 'C'
          ,last_updated_by          = cn_last_updated_by
          ,last_update_date         = SYSDATE
          ,last_update_login        = cn_last_update_login
          ,request_id               = cn_request_id
          ,program_application_id   = cn_program_application_id
          ,program_id               = cn_program_id
          ,program_update_date      = SYSDATE
    WHERE  deduction_recon_head_id  = g_cancel_head_tbl(gn_c_head_cnt).header_id
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
  END update_cabcel_data;
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
    gn_c_target_cnt               := 0;                     -- 対象件数（取消）
    gn_c_normal_cnt               := 0;                     -- 正常件数（取消）
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
    -- 消込ヘッダーループ
    <<recon_head_loop>>
    FOR rh IN 1..g_recon_head_tbl.COUNT LOOP
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
      -- 変数をクリア
      gn_invoice_amount := 0; -- 明細集計金額
      gn_detail_num := 1;     -- 明細連番
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
      gn_head_cnt := gn_head_cnt + 1;
      gn_line_cnt := 1;
--
    END LOOP recon_head_loop;
--
    -- ===============================
    -- A-7.取消ヘッダー情報取得
    -- ===============================
    get_cancel_header(
        ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<cancel_head_loop>>
    FOR ch IN 1..g_cancel_head_tbl.COUNT LOOP
      -- ===============================
      -- A-8.取消明細情報取得
      -- ===============================
      get_cancel_line(
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
      -- A-9.取消ヘッダー登録処理
      -- ===============================
      ins_cancel_header(
          ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      <<cancel_line_loop>>
      FOR cl IN 1..g_cancel_line_tbl.COUNT LOOP
--
        -- ===============================
        -- A-10.取消明細登録処理
        -- ===============================
        ins_cancel_line(
            ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
           ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
           ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        gn_c_line_cnt := gn_c_line_cnt + 1;
--
      END LOOP cancel_line_loop;
--
      -- ===============================
      -- A-11.取消データ更新
      -- ===============================
      update_cabcel_data(
          ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      gn_c_head_cnt := gn_c_head_cnt + 1;
      gn_c_line_cnt := 1;
--
    END LOOP cancel_head_loop;
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
                 ,retcode          OUT VARCHAR2  )            -- リターン・コード    --# 固定 #
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
      gn_c_target_cnt := 0;
      gn_c_normal_cnt := 0;
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
    --対象件数（取消）出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_xxcok_10714
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_c_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録成功件数（取消）出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                           ,iv_name         => cv_msg_xxcok_10717
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_c_normal_cnt )
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
END XXCOK024A16C;
/
