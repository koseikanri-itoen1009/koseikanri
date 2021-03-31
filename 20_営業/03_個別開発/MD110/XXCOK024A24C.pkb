CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A24C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A24C (body)
 * Description      : 控除額の支払画面の申請ボタン押下時に、
 *                  : 作成された控除消込情報をAP部門入力へ連携します
 * MD.050           : AP部門入力連携 MD050_COK_024_A24
 * Version          : 1.00
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_recon_header       A-2.消込ヘッダ情報抽出
 *  get_recon_line         A-3.消込明細情報抽出
 *  ins_pay_slip_header    A-4.支払伝票ヘッダ登録
 *  ins_pay_slip_line      A-5.支払伝票明細登録
 *  import_ap_depart       A-6.AP部門入力インポート
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-7.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/05/07    1.0   M.Sato           新規作成
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
  cv_pkg_name            CONSTANT VARCHAR2(20) := 'XXCOK024A24C';                     -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name     CONSTANT VARCHAR2(10) := 'XXCCP';                            -- 共通領域短縮アプリ名
  cv_xxcok_short_nm      CONSTANT VARCHAR2(10) := 'XXCOK';                            -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_data_get_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- 対象データなしエラーメッセージ
  cv_profile_get_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_ap_terms_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00032';                 -- 支払条件取得エラーメッセージ
  cv_table_lock_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                 -- ロックエラーメッセージ
  cv_ap_imp_billing_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10683';                 -- 部門入力（AP）データインポート発行エラー
  cv_ap_imp_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10684';                 -- 部門入力（AP）データインポートエラー
  cv_slip_type_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10686';                 -- 伝票種別名取得エラー
  cv_slip_num_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10688';                 -- 連携支払伝票番号
  cv_po_vendor_site      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10689';                 -- 仕入先サイトマスタ設定不備
  cv_target_rec_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';                 -- 対象件数メッセージ
  cv_success_rec_msg     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';                 -- 成功件数メッセージ
  cv_error_rec_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                 -- エラー件数メッセージ
  cv_normal_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                 -- 正常終了メッセージ
  cv_error_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                 -- エラー終了全ロールバック
  -- トークン
  cv_tkn_profile         CONSTANT VARCHAR2(20) := 'PROFILE';                          -- プロファイル名
  cv_tkn_vendor          CONSTANT VARCHAR2(20) := 'VENDOR_CODE';                      -- 支払先コード
  cv_tkn_request_id      CONSTANT VARCHAR2(20) := 'REQUEST_ID';                       -- 要求ID
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';                           -- ステータス
  cv_tkn_slip_num        CONSTANT VARCHAR2(20) := 'SLIP_NUM';                         -- 支払伝票番号
  cv_cnt_token           CONSTANT VARCHAR2(20) := 'COUNT';                            -- 件数メッセージ用トークン名
  -- プロファイル
  cv_recon_line_summ_ded CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_DEDU';
                                                                                      -- 消込明細_摘要_控除税額
  cv_recon_line_summ_acc CONSTANT VARCHAR2(50) := 'XXCOK1_AP_RECON_LINE_SUMMARY_ACCOUNT';
                                                                                      -- 消込明細_摘要_科目支払
  cv_set_of_bks_id       CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
  cv_org_id              CONSTANT VARCHAR2(15) := 'ORG_ID';                           -- 営業単位
  cv_other_tax           CONSTANT VARCHAR2(50) := 'XXCOK1_OTHER_TAX_CODE';            -- 対象外消費税コード
  cv_com_code            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF1_COMPANY_CODE';         -- 会社コード
  cv_dept_fin            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF2_DEPT_FIN';             -- 部門コード_財務経理部
  cv_cus_dummy           CONSTANT VARCHAR2(50) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- 顧客コード_ダミー値
  cv_com_dummy           CONSTANT VARCHAR2(50) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- 企業コード_ダミー値
  cv_pre1_dummy          CONSTANT VARCHAR2(50) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- 予備１_ダミー値
  cv_pre2_dummy          CONSTANT VARCHAR2(50) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- 予備２_ダミー値
  -- クイックコード
  cv_lookup_slip_type    CONSTANT VARCHAR2(30) := 'XX03_SLIP_TYPES';                  -- 伝票種別
  cv_lookup_sls_dedu     CONSTANT VARCHAR2(10) := '30000';                            -- 販売控除
  cv_lookup_dedu_type    CONSTANT VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';       -- 控除データ種類
  cv_lookup_tax_conv     CONSTANT VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';     -- 消費税コード変換マスタ
  -- フラグ・区分定数
  cv_y_flag              CONSTANT VARCHAR2(1) := 'Y';                                 -- フラグ値:Y
  cv_n_flag              CONSTANT VARCHAR2(1) := 'N';                                 -- フラグ値:N
  cv_lang                CONSTANT VARCHAR2(30) := USERENV( 'LANG' );                  -- 言語
  -- 消込明細_摘要コード
  cv_dedu_pay            CONSTANT VARCHAR2(5) := '30001';                             -- 控除支払
  cv_account_pay         CONSTANT VARCHAR2(5) := '30002';                             -- 科目支払
  -- AP部門入力一時表へ登録する固定値
  cv_wf_status           CONSTANT VARCHAR2(2) := '00';                                -- ステータス
  cv_currency_jpy        CONSTANT VARCHAR2(3) := 'JPY';                               -- 通貨
  -- コンカレント発行
  cv_conc_appl           CONSTANT VARCHAR2(4):=  'XX03';                              -- 短縮アプリ名
  cv_conc_prog           CONSTANT VARCHAR2(20):= 'XX034DD001C';                       -- 部門入力（AP）データインポート
  -- 控除消込ヘッダーステータス
  cv_recon_status_eg     CONSTANT VARCHAR2(2):=  'EG';                                -- 入力中
  cv_recon_status_sg     CONSTANT VARCHAR2(2):=  'SG';                                -- 送信中
  cv_recon_status_sd     CONSTANT VARCHAR2(2):=  'SD';                                -- 送信済
  -- ロックステータス
  cv_lock_status_normal  CONSTANT VARCHAR2(1):=  '0';                                -- ロックステータス:正常
  cv_lock_status_error   CONSTANT VARCHAR2(1):=  '1';                                -- ロックステータス:エラー
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 控除消込ヘッダレコード型定義
  TYPE g_recon_header_rtype IS RECORD(
       recon_base_code              xxcok_deduction_recon_head.recon_base_code%TYPE   -- 支払請求拠点
      ,recon_slip_num               xxcok_deduction_recon_head.recon_slip_num%TYPE    -- 支払伝票番号
      ,recon_due_date               xxcok_deduction_recon_head.recon_due_date%TYPE    -- 支払予定日
      ,gl_date                      xxcok_deduction_recon_head.gl_date%TYPE           -- GL記帳日
      ,payee_code                   xxcok_deduction_recon_head.payee_code%TYPE        -- 支払先コード
      ,applicant                    xxcok_deduction_recon_head.applicant%TYPE         -- 申請者
      ,approver                     xxcok_deduction_recon_head.approver%TYPE          -- 承認者
      ,invoice_date                 xxcok_deduction_recon_head.invoice_date%TYPE      -- 請求書日付
      ,terms_name                   xxcok_deduction_recon_head.terms_name%TYPE        -- 支払条件
      ,invoice_number               xxcok_deduction_recon_head.invoice_number%TYPE    -- 受領請求書番号
      ,vendor_site_code             po_vendor_sites_all.vendor_site_code%TYPE         -- 仕入先サイトコード
      ,pay_group_lookup_code        po_vendor_sites_all.pay_group_lookup_code%TYPE    -- 支払グループ
  );
  -- 控除消込ヘッダワークテーブル型定義
  TYPE g_recon_head_ttype    IS TABLE OF g_recon_header_rtype INDEX BY BINARY_INTEGER;
  -- 控除消込ヘッダテーブル型変数
  g_recon_head_tbl        g_recon_head_ttype;                                         -- 控除消込ヘッダ抽出
--
  -- 控除消込明細ワークテーブル定義
  TYPE g_recon_line_rtype IS RECORD(
       sort_key                     VARCHAR2(50)                                      -- ソートキー
      ,summary_code                 VARCHAR2(5)                                       -- 摘要コード
      ,body_amount                  NUMBER                                            -- 本体金額
      ,tax_amount                   NUMBER                                            -- 消費税額
      ,summary                      VARCHAR2(300)                                     -- 摘要
      ,tax_class_code               VARCHAR2(40)                                      -- 税区分コード
      ,dept                         VARCHAR2(40)                                      -- 部門
      ,account                      VARCHAR2(150)                                     -- 勘定科目
      ,sub_account                  VARCHAR2(150)                                     -- 補助科目
  );
  -- 控除消込明細ワークテーブル型定義
  TYPE g_recon_line_ttype    IS TABLE OF g_recon_line_rtype INDEX BY BINARY_INTEGER;
  -- 控除消込明細テーブル型変数
  g_recon_line_tbl        g_recon_line_ttype;                                         -- 控除消込明細抽出
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gv_recon_line_summ_ded      VARCHAR2(40);                                           -- 消込明細_摘要_控除税額
  gv_recon_line_summ_acc      VARCHAR2(40);                                           -- 消込明細_摘要_科目支払
  gn_set_of_bks_id            NUMBER;                                                 -- 会計帳簿ID
  gn_org_id                   NUMBER;                                                 -- 営業単位
  gv_other_tax                VARCHAR2(40);                                           -- 対象外消費税コード
  gv_com_code                 VARCHAR2(40);                                           -- 会社コード
  gv_dept_fin                 VARCHAR2(40);                                           -- 部門コード_財務経理部
  gv_cus_dummy                VARCHAR2(40);                                           -- 顧客コード_ダミー値
  gv_com_dummy                VARCHAR2(40);                                           -- 企業コード_ダミー値
  gv_pre1_dummy               VARCHAR2(40);                                           -- 予備１_ダミー値
  gv_pre2_dummy               VARCHAR2(40);                                           -- 予備２_ダミー値
  gv_slip_type                VARCHAR2(240);                                          -- 伝票種別名
  --
  gn_recon_head_id            NUMBER;                                                 -- 入力パラメータ.控除消込ヘッダID
  gv_lock_status              VARCHAR2(1);                                            -- ロックステータス
  gd_recon_due_date           xxcok_deduction_recon_head.recon_due_date%TYPE;         -- 支払予定日
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
    -- 消込明細_摘要_控除税額のプロファイル値を取得
    -- ============================================================
    gv_recon_line_summ_ded := FND_PROFILE.VALUE( cv_recon_line_summ_ded ); -- 消込明細_摘要_控除税額
    -- 消込明細_摘要_控除税額がNULLならエラー終了
    IF gv_recon_line_summ_ded IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_recon_line_summ_ded
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 消込明細_摘要_科目支払のプロファイル値を取得
    -- ============================================================
    gv_recon_line_summ_acc := FND_PROFILE.VALUE( cv_recon_line_summ_acc ); -- 消込明細_摘要_科目支払
    -- 消込明細_摘要_科目支払がNULLならエラー終了
    IF gv_recon_line_summ_acc IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_recon_line_summ_acc
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 会計帳簿IDのプロファイル値を取得
    -- ============================================================
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id )); -- 会計帳簿ID
    -- 会計帳簿IDがNULLならエラー終了
    IF gn_set_of_bks_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_set_of_bks_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 営業単位のプロファイル値を取得
    -- ============================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ));               -- 営業単位
    -- 営業単位がNULLならエラー終了
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 対象外消費税コードのプロファイル値を取得
    -- ============================================================
    gv_other_tax := FND_PROFILE.VALUE( cv_other_tax );                     -- 対象外消費税コード
    -- 対象外消費税コードがNULLならエラー終了
    IF gv_other_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_other_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 会社コードのプロファイル値を取得
    -- ============================================================
    gv_com_code := FND_PROFILE.VALUE( cv_com_code );                       -- 会社コード
    -- 会社コードがNULLならエラー終了
    IF gv_com_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_com_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 部門コード_財務経理部のプロファイル値を取得
    -- ============================================================
    gv_dept_fin := FND_PROFILE.VALUE( cv_dept_fin );                       -- 部門コード_財務経理部
    -- 部門コード_財務経理部がNULLならエラー終了
    IF gv_dept_fin IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 顧客コード_ダミー値のプロファイル値を取得
    -- ============================================================
    gv_cus_dummy := FND_PROFILE.VALUE( cv_cus_dummy );                     -- 顧客コード_ダミー値
    -- 顧客コード_ダミー値がNULLならエラー終了
    IF gv_cus_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_cus_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 企業コード_ダミー値のプロファイル値を取得
    -- ============================================================
    gv_com_dummy := FND_PROFILE.VALUE( cv_com_dummy );                     -- 企業コード_ダミー値
    -- 企業コード_ダミー値がNULLならエラー終了
    IF gv_com_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_com_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 予備１_ダミー値のプロファイル値を取得
    -- ============================================================
    gv_pre1_dummy := FND_PROFILE.VALUE( cv_pre1_dummy );                   -- 予備１_ダミー値
    -- 予備１_ダミー値がNULLならエラー終了
    IF gv_pre1_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_pre1_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 予備２_ダミー値のプロファイル値を取得
    -- ============================================================
    gv_pre2_dummy := FND_PROFILE.VALUE( cv_pre2_dummy );                   -- 予備２_ダミー値
    -- 予備２_ダミー値がNULLならエラー終了
    IF gv_pre2_dummy IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_profile_get_msg
                     ,cv_tkn_profile
                     ,cv_pre2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 伝票種別名の取得
    -- ============================================================
    BEGIN
    --
      SELECT  flv.description    AS description      -- 摘要
      INTO    gv_slip_type                           -- 伝票種別名
      FROM    fnd_lookup_values  flv                 -- 伝票種別
      WHERE   flv.lookup_type  = cv_lookup_slip_type
      AND     flv.lookup_code  = cv_lookup_sls_dedu
      AND     flv.language     = cv_lang
      AND     flv.enabled_flag = cv_y_flag
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- 伝票種別名取得エラーメッセージ
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_slip_type_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
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
   * Description      : A-2.消込ヘッダ情報抽出
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
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lv_ap_terms     xx03_ap_terms_v.attribute1%TYPE;        -- 支払予定日変更フラグ
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
    -- *** ローカル・カーソル ***
    -- 控除消込ヘッダ抽出カーソル
    CURSOR recon_head_cur
    IS
      SELECT xdrh.recon_base_code          AS recon_base_code        -- 支払請求拠点
            ,xdrh.recon_slip_num           AS recon_slip_num         -- 支払伝票番号
            ,xdrh.recon_due_date           AS recon_due_date         -- 支払予定日
            ,xdrh.gl_date                  AS gl_date                -- GL記帳日
            ,xdrh.payee_code               AS payee_code             -- 支払先コード
            ,xdrh.applicant                AS applicant              -- 申請者
            ,xdrh.approver                 AS approver               -- 承認者
            ,xdrh.invoice_date             AS invoice_date           -- 請求書日付
            ,xdrh.terms_name               AS terms_name             -- 支払条件
            ,xdrh.invoice_number           AS invoice_number         -- 受領請求書番号
            ,pvsa.vendor_site_code         AS vendor_site_code       -- 仕入先サイト
            ,pvsa.pay_group_lookup_code    AS pay_group_lookup_code  -- 支払グループ
      FROM   xxcok_deduction_recon_head    xdrh                      -- 控除消込ヘッダー情報
            ,po_vendor_sites_all           pvsa                      -- 仕入先サイト
            ,po_vendors                    pv                        -- 仕入先
      WHERE  xdrh.deduction_recon_head_id  = gn_recon_head_id
      AND    xdrh.recon_status             = cv_recon_status_sg
      AND    pv.segment1(+)                = xdrh.payee_code
      AND    pvsa.vendor_id(+)             = pv.vendor_id
      AND    pvsa.org_id(+)                = gn_org_id
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
    -- 変数の初期化
    lv_ap_terms := NULL;
    -- ============================================================
    -- 1.処理対象消込ヘッダ情報取得
    -- ============================================================
    -- カーソルオープン
    OPEN  recon_head_cur;
    -- データ取得
    FETCH recon_head_cur BULK COLLECT INTO g_recon_head_tbl;
    -- カーソルクローズ
    CLOSE recon_head_cur;
    -- 取得件数が0件だった場合
    IF ( g_recon_head_tbl.COUNT = 0 ) THEN
      -- 対象なしメッセージでエラー終了
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    -- 取得件数が2件以上もしくは支払いグループがNULLだった場合
    ELSIF ( g_recon_head_tbl.COUNT >= 2 OR
            g_recon_head_tbl(1).pay_group_lookup_code IS NULL )
    THEN
      -- 仕入先サイトマスタ設定不備でエラー終了
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_po_vendor_site
                     ,cv_tkn_vendor
                     ,g_recon_head_tbl(1).payee_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 2.支払条件の支払予定日変更フラグを取得
    -- ============================================================
    BEGIN
    --
      SELECT xatv.attribute1            AS recon_due_date_flag        -- 支払予定日変更フラグ
      INTO   lv_ap_terms
      FROM   xx03_ap_terms_v            xatv                          -- 支払条件ビュー
      WHERE  xatv.name                  = g_recon_head_tbl(1).terms_name
      AND    xatv.enabled_flag          = cv_y_flag
      AND    NVL( xatv.start_date_active, TO_DATE( '1000/01/01' , 'YYYY/MM/DD' ))
                                       <= TRUNC( SYSDATE )
      AND    NVL( xatv.end_date_active, TO_DATE( '4712/12/31' , 'YYYY/MM/DD' ))
                                        > TRUNC( SYSDATE )
      ;
    --
    EXCEPTION
      WHEN  OTHERS THEN
        -- 支払条件取得エラーメッセージ
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_ap_terms_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ============================================================
    -- 3.支払予定日変更フラグがNの場合、支払予定日をNULLとする
    -- ============================================================
    IF ( lv_ap_terms = cv_n_flag ) THEN
      gd_recon_due_date := NULL;                                      -- 支払予定日
    ELSE
      -- Yの場合は取得した支払予定日を格納
      gd_recon_due_date := g_recon_head_tbl(1).recon_due_date;        -- 支払予定日
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
                                                 ,cv_table_lock_msg
                                                 );
      -- ロックステータスにエラーを格納
      gv_lock_status := cv_lock_status_error;
      --
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode     := cv_status_error;
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
   * Description      : A-3.消込明細情報抽出
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
    -- 消込明細情報抽出カーソル
    CURSOR recon_line_cur
    IS
      -- 控除支払_本体
      SELECT '1' || xdnr.condition_no || xdnr.data_type     AS sort_key          -- ソートキー
             ,cv_dedu_pay                                   AS summary_code      -- 摘要コード
             ,xdnr.payment_amt                              AS body_amount       -- 本体金額
             ,0                                             AS tax_amount        -- 消費税額
             ,xdnr.condition_no || cv_msg_part || flv.meaning || cv_msg_part || xdnr.remarks
                                                            AS summary           -- 摘要
             ,gv_other_tax                                  AS tax_class_code    -- 税区分コード
             ,gv_dept_fin                                   AS dept              -- 部門
             ,flv.attribute6                                AS account           -- 勘定科目
             ,flv.attribute7                                AS sub_account       -- 補助科目
      FROM    xxcok_deduction_num_recon     xdnr                                 -- 控除No別消込情報
             ,fnd_lookup_values             flv                                  -- データ種類
      WHERE   xdnr.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND     xdnr.target_flag              = cv_y_flag
      AND     xdnr.payment_amt             != 0
      AND     flv.lookup_type               = cv_lookup_dedu_type
      AND     flv.lookup_code               = xdnr.data_type
      AND     flv.language                  = cv_lang
      AND     flv.enabled_flag              = cv_y_flag
      -- 控除支払_税
      UNION ALL
      SELECT '2' || xdnr.payment_tax_code                   AS sort_key          -- ソートキー
             ,cv_dedu_pay                                   AS summary_code      -- 摘要コード
             ,SUM( payment_tax )                            AS body_amount       -- 本体金額
             ,0                                             AS tax_amount        -- 消費税額
             ,gv_recon_line_summ_ded || xdnr.payment_tax_code
                                                            AS summary           -- 摘要
             ,gv_other_tax                                  AS tax_class_code    -- 税区分コード
             ,gv_dept_fin                                   AS dept              -- 部門
             ,atca.attribute5                               AS account           -- 勘定科目
             ,atca.attribute6                               AS sub_account       -- 補助科目
      FROM    xxcok_deduction_num_recon     xdnr                                 -- 控除No別消込情報
             ,ap_tax_codes_all              atca                                 -- AP税マスタ
      WHERE   xdnr.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND     xdnr.target_flag              = cv_y_flag
      AND     atca.name                     = xdnr.payment_tax_code
      AND     atca.set_of_books_id          = gn_set_of_bks_id
      AND     atca.org_id                   = gn_org_id
      GROUP BY
              xdnr.payment_tax_code                                              -- 消費税コード
             ,atca.attribute5                                                    -- 勘定科目(負債)
             ,atca.attribute6                                                    -- 補助科目(負債)
      HAVING
              SUM( payment_tax )           != 0                                  -- 請求消費税額
      -- 科目支払
      UNION ALL
      SELECT '3' || TO_CHAR( xapi.account_payment_num,'0999999999' )
                                                            AS sort_key          -- ソートキー
             ,cv_account_pay                                AS summary_code      -- 摘要コード
             ,xapi.payment_amt                              AS body_amount       -- 本体金額
             ,xapi.payment_tax                              AS tax_amount        -- 消費税額
             ,gv_recon_line_summ_acc || flv.meaning || cv_msg_part || xapi.remarks
                                                            AS summary           -- 摘要
             ,flv2.attribute1                               AS tax_class_code    -- 税区分コード
             ,g_recon_head_tbl(1).recon_base_code           AS dept              -- 部門
             ,flv.attribute4                                AS account           -- 勘定科目
             ,flv.attribute5                                AS sub_account       -- 補助科目
      FROM    xxcok_account_payment_info    xapi                                 -- 科目支払情報
             ,fnd_lookup_values             flv                                  -- データ種類
             ,fnd_lookup_values             flv2                                 -- 消費税コード変換マスタ
      WHERE   xapi.recon_slip_num           = g_recon_head_tbl(1).recon_slip_num
      AND   ( xapi.payment_amt             != 0 OR
              xapi.payment_tax             != 0   )
      AND     flv.lookup_type               = cv_lookup_dedu_type
      AND     flv.lookup_code               = xapi.data_type
      AND     flv.language                  = cv_lang
      AND     flv.enabled_flag              = cv_y_flag
      AND     flv2.lookup_type              = cv_lookup_tax_conv
      AND     flv2.lookup_code              = xapi.payment_tax_code
      AND     flv2.language                 = cv_lang
      AND     flv2.enabled_flag             = cv_y_flag
      ORDER BY
              sort_key ASC
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
    -- 取得した伝票明細数を対象件数に格納
    gn_target_cnt := g_recon_line_tbl.COUNT;        -- 対象件数
    -- 対象件数が0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象なしメッセージでエラー終了
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_data_get_msg
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
   * Procedure Name   : ins_pay_slip_header
   * Description      : A-4.支払伝票ヘッダ登録
   ***********************************************************************************/
  PROCEDURE ins_pay_slip_header(
                      ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pay_slip_header';              -- プログラム名
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
    -- AP部門入力一時表へ登録処理
    -- ============================================================
    INSERT INTO xx03_payment_slips_if(
         interface_id                                        -- インターフェイスID
        ,source                                              -- 作成元
        ,invoice_id                                          -- 請求書ID
        ,wf_status                                           -- ステータス
        ,slip_type_name                                      -- 伝票種別
        ,entry_date                                          -- 入力日
        ,requestor_person_number                             -- 登録者(従業員番号)
        ,approver_person_number                              -- 承認者(従業員番号)
        ,invoice_date                                        -- 請求書日付
        ,vendor_code                                         -- 仕入先コード
        ,vendor_site_code                                    -- 仕入先サイト
        ,invoice_currency_code                               -- 通貨
        ,exchange_rate                                       -- レート
        ,exchange_rate_type_name                             -- レートタイプ
        ,terms_name                                          -- 支払条件
        ,description                                         -- 摘要
        ,vendor_invoice_num                                  -- 仕入先請求書番号
        ,entry_person_number                                 -- 入力者(従業員番号)
        ,pay_group_lookup_name                               -- 支払グループ
        ,gl_date                                             -- 計上日
        ,prepay_num                                          -- 前払伝票番号
        ,terms_date                                          -- 支払予定日
        ,org_id                                              -- 営業単位
        ,created_by                                          -- 作成者
        ,creation_date                                       -- 作成日
        ,last_updated_by                                     -- 最終更新者
        ,last_update_date                                    -- 最終更新日
        ,last_update_login                                   -- 最終更新ログイン
        ,request_id                                          -- 要求ID
        ,program_application_id                              -- コンカレント・プログラム・アプリケーションID
        ,program_id                                          -- コンカレント・プログラムID
        ,program_update_date                                 -- プログラム更新日
        )VALUES(
         gn_recon_head_id                                    -- インターフェイスID
        ,gv_slip_type                                        -- 作成元
        ,NULL                                                -- 請求書ID
        ,cv_wf_status                                        -- ステータス
        ,gv_slip_type                                        -- 伝票種別
        ,SYSDATE                                             -- 入力日
        ,g_recon_head_tbl(1).applicant                       -- 登録者(従業員番号)
        ,g_recon_head_tbl(1).approver                        -- 承認者(従業員番号)
        ,g_recon_head_tbl(1).invoice_date                    -- 請求書日付
        ,g_recon_head_tbl(1).payee_code                      -- 仕入先コード
        ,g_recon_head_tbl(1).vendor_site_code                -- 仕入先サイト
        ,cv_currency_jpy                                     -- 通貨
        ,NULL                                                -- レート
        ,NULL                                                -- レートタイプ
        ,g_recon_head_tbl(1).terms_name                      -- 支払条件
        ,g_recon_head_tbl(1).recon_slip_num                  -- 摘要
        ,g_recon_head_tbl(1).invoice_number                  -- 仕入先請求書番号
        ,g_recon_head_tbl(1).applicant                       -- 入力者(従業員番号)
        ,g_recon_head_tbl(1).pay_group_lookup_code           -- 支払グループ
        ,g_recon_head_tbl(1).gl_date                         -- 計上日
        ,NULL                                                -- 前払伝票番号
        ,gd_recon_due_date                                   -- 支払予定日
        ,gn_org_id                                           -- 営業単位
        ,cn_created_by                                       -- 作成者
        ,cd_creation_date                                    -- 作成日
        ,cn_last_updated_by                                  -- 最終更新者
        ,cd_last_update_date                                 -- 最終更新日
        ,cn_last_update_login                                -- 最終更新ログイン
        ,cn_request_id                                       -- 要求ID
        ,cn_program_application_id                           -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                                       -- コンカレント・プログラムID
        ,cd_program_update_date                              -- プログラム更新日
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
  END ins_pay_slip_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_pay_slip_line
   * Description      : A-5.支払伝票明細登録
   ***********************************************************************************/
  PROCEDURE ins_pay_slip_line(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_pay_slip_line';      -- プログラム名
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
    -- AP部門入力明細一時表登録ループ
    -- ============================================================
    <<ins_line_loop>>
    FOR ln_ins_line IN 1..g_recon_line_tbl.COUNT LOOP
      -- AP部門入力明細一時表への登録
      INSERT INTO xx03_payment_slip_lines_if(
           interface_id                                        -- インターフェイスID
          ,source                                              -- 作成元
          ,line_number                                         -- 明細番号
          ,slip_line_type                                      -- 摘要コード
          ,entered_item_amount                                 -- 本体金額
          ,entered_tax_amount                                  -- 消費税額
          ,description                                         -- 摘要
          ,amount_includes_tax_flag                            -- 内税(Y/N)
          ,tax_code                                            -- 税区分コード
          ,segment1                                            -- 会社
          ,segment2                                            -- 部門
          ,segment3                                            -- 勘定科目
          ,segment4                                            -- 補助科目
          ,segment5                                            -- 顧客コード
          ,segment6                                            -- 企業コード
          ,segment7                                            -- 予備１
          ,segment8                                            -- 予備２
          ,incr_decr_reason_code                               -- 増減事由
          ,recon_reference                                     -- 消し込み参照
          ,org_id                                              -- 営業単位
          ,created_by                                          -- 作成者
          ,creation_date                                       -- 作成日
          ,last_updated_by                                     -- 最終更新者
          ,last_update_date                                    -- 最終更新日
          ,last_update_login                                   -- 最終更新ログイン
          ,request_id                                          -- 要求ID
          ,program_application_id                              -- コンカレント・プログラム・アプリケーションID
          ,program_id                                          -- コンカレント・プログラムID
          ,program_update_date                                 -- プログラム更新日
          )VALUES(
           gn_recon_head_id                                    -- インターフェイスID
          ,gv_slip_type                                        -- 作成元
          ,ln_ins_line                                         -- 明細番号
          ,g_recon_line_tbl(ln_ins_line).summary_code          -- 摘要コード
          ,g_recon_line_tbl(ln_ins_line).body_amount           -- 本体金額
          ,g_recon_line_tbl(ln_ins_line).tax_amount            -- 消費税額
          ,g_recon_line_tbl(ln_ins_line).summary               -- 摘要
          ,cv_y_flag                                           -- 内税(Y/N)
          ,g_recon_line_tbl(ln_ins_line).tax_class_code        -- 税区分コード
          ,gv_com_code                                         -- 会社
          ,g_recon_line_tbl(ln_ins_line).dept                  -- 部門
          ,g_recon_line_tbl(ln_ins_line).account               -- 勘定科目
          ,g_recon_line_tbl(ln_ins_line).sub_account           -- 補助科目
          ,gv_cus_dummy                                        -- 顧客コード
          ,gv_com_dummy                                        -- 企業コード
          ,gv_pre1_dummy                                       -- 予備１
          ,gv_pre2_dummy                                       -- 予備２
          ,NULL                                                -- 増減事由
          ,NULL                                                -- 消し込み参照
          ,gn_org_id                                           -- 営業単位
          ,cn_created_by                                       -- 作成者
          ,cd_creation_date                                    -- 作成日
          ,cn_last_updated_by                                  -- 最終更新者
          ,cd_last_update_date                                 -- 最終更新日
          ,cn_last_update_login                                -- 最終更新ログイン
          ,cn_request_id                                       -- 要求ID
          ,cn_program_application_id                           -- コンカレント・プログラム・アプリケーションID
          ,cn_program_id                                       -- コンカレント・プログラムID
          ,cd_program_update_date                              -- プログラム更新日
      );
      -- 正常件数にループカウンタを格納
      gn_normal_cnt := ln_ins_line;       -- 正常件数
    END LOOP ins_line_loop;
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
  END ins_pay_slip_line;
--
  /**********************************************************************************
   * Procedure Name   : import_ap_depart
   * Description      : A-6.AP部門入力インポート
   ***********************************************************************************/
  PROCEDURE import_ap_depart(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'import_ap_depart';      -- プログラム名
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
    ln_request_id     NUMBER;               -- 戻り値：要求ID
    lb_result         BOOLEAN;              -- 戻り値：待機結果
    lv_phase          VARCHAR2(5000);       -- フェーズ（ユーザ）
    lv_status         VARCHAR2(5000);       -- ステータス（ユーザ）
    lv_dev_phase      VARCHAR2(5000);       -- フェーズ
    lv_dev_status     VARCHAR2(5000);       -- ステータス
    lv_message        VARCHAR2(5000);       -- メッセージ
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
    -- 1.コンカレント「部門入力（AP）データインポート」を発行
    -- ============================================================
    ln_request_id := fnd_request.submit_request( cv_conc_appl
                                                ,cv_conc_prog
                                                ,NULL
                                                ,NULL
                                                ,FALSE
                                                ,gv_slip_type
                                                ,cn_request_id
                                                );
    -- 要求IDが0以外の場合コミットを発行
    IF ln_request_id != 0 THEN
      COMMIT;
    -- 0であればエラーメッセージ
    ELSE
      -- 部門入力（AP）データインポート発行エラーメッセージ
      lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                             ,cv_ap_imp_billing_msg
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 2.発行コンカレントの終了を待機
    -- ============================================================
    lb_result := fnd_concurrent.wait_for_request( ln_request_id
                                                 ,5
                                                 ,0
                                                 ,lv_phase
                                                 ,lv_status
                                                 ,lv_dev_phase
                                                 ,lv_dev_status
                                                 ,lv_message
                                                 );
    -- ============================================================
    -- 3.一時表作成データの削除
    -- ============================================================
    -- AP部門入力一時表の作成データ削除
    DELETE
    FROM    xx03_payment_slips_if       xpsi              -- AP部門入力一時表
    WHERE   xpsi.interface_id    = gn_recon_head_id
    ;
    -- AP部門入力明細一時表の作成データ削除
    DELETE
    FROM    xx03_payment_slip_lines_if  xpsli             -- AP部門入力明細一時表
    WHERE   xpsli.interface_id   = gn_recon_head_id
    ;
    -- ============================================================
    -- 4.部門入力（AP）データインポート結果の確認
    -- ============================================================
    -- インポート結果のステータスがエラーであればメッセージ出力
    IF lv_dev_status = 'ERROR' THEN
      -- 部門入力（AP）データインポートエラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            ,cv_ap_imp_msg
                                            ,cv_tkn_request_id
                                            ,ln_request_id
                                            ,cv_tkn_status
                                            ,lv_status
                                            );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- ============================================================
    -- 5.控除消込ヘッダーステータス更新
    -- ============================================================
    UPDATE  xxcok_deduction_recon_head   xdrh                             -- 控除消込ヘッダー情報
    SET     xdrh.recon_status            = cv_recon_status_sd             -- 消込スタータス(送信済)
           ,xdrh.application_date        = TRUNC( SYSDATE )               -- 申請日
           ,xdrh.last_updated_by         = cn_last_updated_by             -- 最終更新者
           ,xdrh.last_update_date        = cd_last_update_date            -- 最終更新日
           ,xdrh.last_update_login       = cn_last_update_login           -- 最終更新ログイン
           ,xdrh.request_id              = cn_request_id                  -- 要求ID
           ,xdrh.program_application_id  = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
           ,xdrh.program_id              = cn_program_id                  -- コンカレント・プログラムID
           ,xdrh.program_update_date     = cd_program_update_date         -- プログラム更新日
    WHERE   xdrh.deduction_recon_head_id = gn_recon_head_id
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
  END import_ap_depart;
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
    gv_lock_status                := cv_lock_status_normal; -- ロックステータス
    gd_recon_due_date             := NULL;                  -- 支払予定日
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
    -- A-2.消込ヘッダ情報抽出
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
    -- A-3.消込明細情報抽出
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
    -- ===============================
    -- A-4.支払伝票ヘッダ登録
    -- ===============================
    ins_pay_slip_header(
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
    -- A-5.支払伝票明細登録
    -- ===============================
    ins_pay_slip_line(
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
    -- A-6.AP部門入力インポート
    -- ===============================
    import_ap_depart(
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
    -- A-7.終了処理
    -- ===============================
    -- 終了ステータスがエラーの場合
    IF (lv_retcode = cv_status_error) THEN
      -- 処理件数の設定
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
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
    -- 終了ステータスがエラーかつロックステータスが正常の場合
    IF ( lv_retcode = cv_status_error AND
         gv_lock_status = cv_lock_status_normal )
    THEN
      -- 控除消込ヘッダーステータスを入力中に更新
      UPDATE  xxcok_deduction_recon_head   xdrh                             -- 控除消込ヘッダー情報
      SET     xdrh.recon_status            = cv_recon_status_eg             -- 消込スタータス(入力中)
             ,xdrh.last_updated_by         = cn_last_updated_by             -- 最終更新者
             ,xdrh.last_update_date        = cd_last_update_date            -- 最終更新日
             ,xdrh.last_update_login       = cn_last_update_login           -- 最終更新ログイン
             ,xdrh.request_id              = cn_request_id                  -- 要求ID
             ,xdrh.program_application_id  = cn_program_application_id      -- コンカレント・プログラム・アプリケーションID
             ,xdrh.program_id              = cn_program_id                  -- コンカレント・プログラムID
             ,xdrh.program_update_date     = cd_program_update_date         -- プログラム更新日
      WHERE   xdrh.deduction_recon_head_id = gn_recon_head_id
      AND     xdrh.recon_status            = cv_recon_status_sg
      ;
      -- 更新をコミット
      COMMIT;
    END IF;
--
    -- ===============================
    -- 1.処理件数メッセージ出力
    -- ===============================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
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
                                           ,iv_name         => cv_success_rec_msg
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
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ===============================
    -- 2.支払伝票番号出力
    -- ===============================
    -- 支払伝票番号が取得され(消込ヘッダ情報が1件抽出できていた場合)、ステータスが正常の場合
    IF ( g_recon_head_tbl.COUNT = 1 AND
         lv_retcode = cv_status_normal )
    THEN
      -- 支払伝票番号を出力する
      gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                             ,iv_name         => cv_slip_num_msg
                                             ,iv_token_name1  => cv_tkn_slip_num
                                             ,iv_token_value1 => g_recon_head_tbl(1).recon_slip_num
                                             );
      FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT
         ,buff  => gv_out_msg
      );
    END IF;
    -- ===============================
    -- 3.処理終了メッセージ
    -- ===============================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
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
END XXCOK024A24C;
/
