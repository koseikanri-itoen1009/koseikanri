CREATE OR REPLACE PACKAGE BODY XXCFR003A23C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFR003A23C_pkb(body)
 * Description      : 消費税差額作成処理
 * MD.050           : MD050_CFR_003_A23_消費税差額作成処理.doc
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_invoice_p          請求ヘッダ情報抽出(A-2)
 *  transfer_to_ar_p       AR連係処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023/07/25    1.0   R.Oikawa         新規作成(E_本稼動_18983)
 *  2023/11/14    1.1   M.Akachi         E_本稼動_19546 サイクル跨ぎ対応
 *
 *****************************************************************************************/
--
  -- ==============================
  -- グローバル定数
  -- ==============================
  -- ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_user_id                  CONSTANT NUMBER               := fnd_global.user_id;                  -- USER_ID
  cn_login_id                 CONSTANT NUMBER               := fnd_global.login_id;                 -- LOGIN_ID
  cn_conc_request_id          CONSTANT NUMBER               := fnd_global.conc_request_id;          -- CONC_REQUEST_ID
  cn_prog_appl_id             CONSTANT NUMBER               := fnd_global.prog_appl_id;             -- PROG_APPL_ID
  cn_conc_program_id          CONSTANT NUMBER               := fnd_global.conc_program_id;          -- CONC_PROGRAM_ID
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCFR003A23C';                      -- パッケージ名
  cv_msg_kbn_cfr              CONSTANT VARCHAR2(5)          := 'XXCFR';
--
  -- プロファイル
  cv_ra_trx_type_tax          CONSTANT VARCHAR2(30)         := 'XXCFR1_RA_TRX_TYPE_TAX';            -- 取引タイプ_消費税差額作成
  cv_other_tax_code           CONSTANT VARCHAR2(30)         := 'XXCFR1_OTHER_TAX_CODE';             -- 対象外消費税コード
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF1_COMPANY_CODE';          -- 会社コード
  cv_aff2_dept_fin            CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF2_DEPT_FIN';              -- 部門コード_財務経理部
  cv_aff3_receive_excise_tax  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_RECEIVE_EXCISE_TAX';    -- 勘定科目_仮受消費税等
  cv_aff3_account_receivable  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_ACCOUNT_RECEIVABLE';    -- 勘定科目_売掛金
  cv_aff4_subacct_dummy       CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_SUBACCT_DUMMY';         -- 補助科目_ダミー値
  cv_aff5_customer_dummy      CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF5_CUSTOMER_DUMMY';        -- 顧客コード_ダミー値
  cv_aff6_company_dummy       CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF6_COMPANY_DUMMY';         -- 企業コード_ダミー値
  cv_aff7_preliminary1_dummy  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF7_PRELIMINARY1_DUMMY';    -- 予備１_ダミー値
  cv_aff8_preliminary2_dummy  CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF8_PRELIMINARY2_DUMMY';    -- 予備２_ダミー値
  cv_org_id                   CONSTANT VARCHAR2(30)         := 'ORG_ID';                            -- 営業単位
  cv_description              CONSTANT VARCHAR2(30)         := 'XXCFR1_DESCRIPTION';                -- 品目明細摘要_税差額
  cv_header_attribute5        CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_DPT';                  -- 起票部門_消費税差額
  cv_header_attribute6        CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_USER';                 -- 伝票入力者_消費税差額
  cv_description_inv          CONSTANT VARCHAR2(30)         := 'XXCFR1_DESCRIPTION_INV';            -- 品目明細摘要_本体差額
  cv_header_attribute5_inv    CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_DPT_INV';              -- 起票部門_本体差額
  cv_header_attribute6_inv    CONSTANT VARCHAR2(30)         := 'XXCFR1_INPUT_USER_INV';             -- 伝票入力者_本体差額
  cv_aff3_rec_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_REC_INV';               -- 勘定科目_本体差額REC
  cv_aff3_rev_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_REV_INV';               -- 勘定科目_本体差額REV
  cv_aff3_tax_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF3_TAX_INV';               -- 勘定科目_本体差額TAX
  cv_aff4_rec_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_REC_INV';               -- 補助科目_本体差額REC
  cv_aff4_rev_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_REV_INV';               -- 補助科目_本体差額REV
  cv_aff4_tax_inv             CONSTANT VARCHAR2(30)         := 'XXCFR1_AFF4_TAX_INV';               -- 補助科目_本体差額TAX
--
  -- アプリケーション短縮名
  cv_appli_xxcfr_name         CONSTANT VARCHAR2(15)         := 'XXCFR';                             -- アプリケーション短縮名
  -- メッセージ
  cv_msg_cfr_00056            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00056';                  -- システムエラーメッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- 対象件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- 成功件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- エラー件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_cfr_00004            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00004';                  -- プロファイル取得エラー
  cv_msg_cfr_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00003';                  -- ロックエラー
--
  -- ファイル出力
  cv_file_type_log            CONSTANT VARCHAR2(10)         := 'LOG';                               -- ログ出力
  -- トークン名
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- 件数のトークン名
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROF_NAME';                         -- プロファイル名のトークン名
  cv_tkn_table                CONSTANT VARCHAR2(15)         := 'TABLE';                             -- テーブル名のトークン名
  -- 記号
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
  -- DFF
  cv_hold                     CONSTANT VARCHAR2(4)          := 'HOLD';
  cv_waiting                  CONSTANT VARCHAR2(7)          := 'WAITING';
  -- 日付フォーマット
  cv_yyyy_mm_dd               CONSTANT VARCHAR2(10)         := 'YYYY/MM/DD';
  cv_yyyymmdd                 CONSTANT VARCHAR2(10)         := 'YYYYMMDD';
  -- 消費税差額作成フラグ
  cv_not_created              CONSTANT VARCHAR2(1)          := '0';                                 -- 未作成
  cv_created                  CONSTANT VARCHAR2(1)          := '1';                                 -- 作成済
  -- 
  cn_0                        CONSTANT NUMBER               := 0;
  cn_1                        CONSTANT NUMBER               := 1;
  cn_2                        CONSTANT NUMBER               := 2;
  cn_100                      CONSTANT NUMBER               := 100;
  cv_line                     CONSTANT VARCHAR2(4)          := 'LINE';
  cv_tax                      CONSTANT VARCHAR2(3)          := 'TAX';
  cv_rev                      CONSTANT VARCHAR2(3)          := 'REV';
  cv_rec                      CONSTANT VARCHAR2(3)          := 'REC';
  cv_tx                       CONSTANT VARCHAR2(2)          := 'TX';                                 -- 伝票番号接頭(税差額)
  cv_ne                       CONSTANT VARCHAR2(2)          := 'NE';                                 -- 伝票番号接頭(本体差額)
  cv_currency_code            CONSTANT VARCHAR2(3)          := 'JPY';                                -- 通貨
  cv_user                     CONSTANT VARCHAR2(4)          := 'User';                               -- 換算タイプ
  cv_table_name               CONSTANT VARCHAR2(30)         := 'XXCFR_INVOICE_HEADERS';              -- テーブル名
--
  -- ==============================
  -- グローバル変数
  -- ==============================
  gv_out_msg                           VARCHAR2(2000);
  gn_target_cnt                        NUMBER               := 0;                                   -- 対象件数
  gn_normal_cnt                        NUMBER               := 0;                                   -- 正常件数
  gn_error_cnt                         NUMBER               := 0;                                   -- エラー件数
--
  gv_ra_trx_type_tax                   VARCHAR2(30);                                                -- 取引タイプ_消費税差額作成
  gv_other_tax_code                    VARCHAR2(30);                                                -- 対象外消費税コード
  gn_org_id                            NUMBER;                                                      -- 営業単位
  gv_aff1_company_code                 VARCHAR2(30);                                                -- 会社コード
  gv_aff2_dept_fin                     VARCHAR2(30);                                                -- 部門コード_財務経理部
  gv_aff3_receive_excise_tax           VARCHAR2(30);                                                -- 勘定科目_仮受消費税等
  gv_aff3_account_receivable           VARCHAR2(30);                                                -- 勘定科目_売掛金
  gv_aff4_subacct_dummy                VARCHAR2(30);                                                -- 補助科目_ダミー値
  gv_aff5_customer_dummy               VARCHAR2(30);                                                -- 顧客コード_ダミー値
  gv_aff6_company_dummy                VARCHAR2(30);                                                -- 企業コード_ダミー値
  gv_aff7_preliminary1_dummy           VARCHAR2(30);                                                -- 予備１_ダミー値
  gv_aff8_preliminary2_dummy           VARCHAR2(30);                                                -- 予備２_ダミー値
  gv_description                       VARCHAR2(30);                                                -- 品目明細摘要_税差額
  gv_header_attribute5                 VARCHAR2(30);                                                -- 起票部門_消費税差額
  gv_header_attribute6                 VARCHAR2(30);                                                -- 伝票入力者_消費税差額
  gv_description_inv                   VARCHAR2(30);                                                -- 品目明細摘要_本体差額
  gv_header_attribute5_inv             VARCHAR2(30);                                                -- 起票部門_本体差額
  gv_header_attribute6_inv             VARCHAR2(30);                                                -- 伝票入力者_本体差額
  gv_aff3_rec_inv                      VARCHAR2(30);                                                -- 勘定科目_本体差額REC
  gv_aff3_rev_inv                      VARCHAR2(30);                                                -- 勘定科目_本体差額REV
  gv_aff3_tax_inv                      VARCHAR2(30);                                                -- 勘定科目_本体差額TAX
  gv_aff4_rec_inv                      VARCHAR2(30);                                                -- 補助科目_本体差額REC
  gv_aff4_rev_inv                      VARCHAR2(30);                                                -- 補助科目_本体差額REV
  gv_aff4_tax_inv                      VARCHAR2(30);                                                -- 補助科目_本体差額TAX
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
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** 処理対象データロック例外 ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
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
    -- プロファイル値の取得
    -- ============================================================
    -- 取引タイプ_消費税差額作成
    gv_ra_trx_type_tax := FND_PROFILE.VALUE( cv_ra_trx_type_tax );
    IF gv_ra_trx_type_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象外消費税コード
    gv_other_tax_code := FND_PROFILE.VALUE( cv_other_tax_code );
    IF gv_other_tax_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_other_tax_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 会社コード
    gv_aff1_company_code := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF gv_aff1_company_code IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff2_dept_fin
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_仮受消費税等
    gv_aff3_receive_excise_tax := FND_PROFILE.VALUE( cv_aff3_receive_excise_tax );
    IF gv_aff3_receive_excise_tax IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_receive_excise_tax
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_売掛金
    gv_aff3_account_receivable := FND_PROFILE.VALUE( cv_aff3_account_receivable );
    IF gv_aff3_account_receivable IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
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
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff8_preliminary2_dummy
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 品目明細摘要_税差額
    gv_description := FND_PROFILE.VALUE( cv_description );
    IF gv_description IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_description
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 営業単位
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    IF gn_org_id IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_org_id
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 起票部門_消費税差額
    gv_header_attribute5 := FND_PROFILE.VALUE( cv_header_attribute5 );
    IF gv_header_attribute5 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute5
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 伝票入力者_消費税差額
    gv_header_attribute6 := FND_PROFILE.VALUE( cv_header_attribute6 );
    IF gv_header_attribute6 IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute6
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 品目明細摘要_本体差額
    gv_description_inv := FND_PROFILE.VALUE( cv_description_inv );
    IF gv_description_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_description_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 起票部門_本体差額
    gv_header_attribute5_inv := FND_PROFILE.VALUE( cv_header_attribute5_inv );
    IF gv_header_attribute5_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute5_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 伝票入力者_本体差額
    gv_header_attribute6_inv := FND_PROFILE.VALUE( cv_header_attribute6_inv );
    IF gv_header_attribute6_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_header_attribute6_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_本体差額REC
    gv_aff3_rec_inv := FND_PROFILE.VALUE( cv_aff3_rec_inv );
    IF gv_aff3_rec_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_rec_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_本体差額REV
    gv_aff3_rev_inv := FND_PROFILE.VALUE( cv_aff3_rev_inv );
    IF gv_aff3_rev_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_rev_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 勘定科目_本体差額TAX
    gv_aff3_tax_inv := FND_PROFILE.VALUE( cv_aff3_tax_inv );
    IF gv_aff3_tax_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff3_tax_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 補助科目_本体差額REC
    gv_aff4_rec_inv := FND_PROFILE.VALUE( cv_aff4_rec_inv );
    IF gv_aff4_rec_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_rec_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 補助科目_本体差額REV
    gv_aff4_rev_inv := FND_PROFILE.VALUE( cv_aff4_rev_inv );
    IF gv_aff4_rev_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_rev_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 補助科目_本体差額TAX
    gv_aff4_tax_inv := FND_PROFILE.VALUE( cv_aff4_tax_inv );
    IF gv_aff4_tax_inv IS NULL THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00004
                     ,cv_tkn_profile
                     ,cv_aff4_tax_inv
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : transfer_to_ar_p
   * Description      : AR連係処理(A-3)
   ***********************************************************************************/
  PROCEDURE transfer_to_ar_p(
    ov_errbuf                   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode                  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  , in_invoice_id               IN  NUMBER    -- 一括請求書ID
  , in_set_of_books_id          IN  NUMBER    -- 会計帳簿ID
  , in_inv_gap_amount           IN  NUMBER    -- 本体差額
  , in_tax_gap_amount           IN  NUMBER    -- 税差額
  , iv_term_name                IN  VARCHAR2  -- 支払条件
  , in_bill_cust_account_id     IN  NUMBER    -- 請求先顧客ID
  , in_bill_cust_acct_site_id   IN  NUMBER    -- 請求先顧客所在地ID
  , id_cutoff_date              IN  DATE      -- 締日
  , iv_receipt_location_code    IN  VARCHAR2  -- 入金拠点コード
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'transfer_to_ar_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf                           VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                          VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg                           VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
    lv_interface_line_attribute1        VARCHAR2(30);                           -- 伝票番号(税差額)
    lv_interface_line_atr1_inv          VARCHAR2(30);                           -- 伝票番号(本体差額)
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- 税差額が発生している場合AROIFを作成
    IF ( NVL(in_tax_gap_amount,0) <> 0 ) THEN
      -- ============================================================
      -- 伝票番号取得
      -- ============================================================
      SELECT  cv_tx || TO_CHAR(id_cutoff_date, cv_yyyymmdd) || LPAD(xxcfr_slip_number_tx_s01.NEXTVAL, 8, 0)
      INTO    lv_interface_line_attribute1
      FROM    dual;
--
      -- ============================================================
      -- 税差額のAR請求取引OIF登録【本体行】
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- 取引明細コンテキスト
        interface_line_attribute1                 , -- 取引明細DFF1(伝票番号)
        interface_line_attribute2                 , -- 取引明細DFF2(明細行番号)
        batch_source_name                         , -- 取引ソース
        set_of_books_id                           , -- 会計帳簿ID
        line_type                                 , -- 明細タイプ
        description                               , -- 品目明細摘要
        currency_code                             , -- 通貨コード
        amount                                    , -- 明細金額
        cust_trx_type_name                        , -- 取引タイプ
        term_name                                 , -- 支払条件
        orig_system_bill_customer_id              , -- 請求先顧客ID
        orig_system_bill_address_id               , -- 請求先顧客所在地参照ID
        link_to_line_context                      , -- リンク明細コンテキスト
        link_to_line_attribute1                   , -- リンク明細DFF1
        link_to_line_attribute2                   , -- リンク明細DFF2
        conversion_type                           , -- 換算タイプ
        conversion_rate                           , -- 換算レート
        trx_date                                  , -- 取引日
        gl_date                                   , -- GL記帳日
        trx_number                                , -- 伝票番号
        quantity                                  , -- 数量
        unit_selling_price                        , -- 販売単価
        tax_code                                  , -- 税金コード
        header_attribute_category                 , -- ヘッダーDFFカテゴリ
        header_attribute5                         , -- ヘッダーDFF5(起票部門)
        header_attribute6                         , -- ヘッダーDFF6(伝票入力者)
        header_attribute7                         , -- ヘッダーDFF7(請求書保留ステータス)
        header_attribute8                         , -- ヘッダーDFF8(個別請求書印刷)
        header_attribute9                         , -- ヘッダーDFF9(一括請求書印刷)
        header_attribute11                        , -- ヘッダーDFF11(入金拠点)
        header_attribute14                        , -- ヘッダーDFF14(伝票番号)
        header_attribute15                        , -- ヘッダーDFF15(GL記帳日)
        created_by                                , -- 作成者
        creation_date                             , -- 作成日
        last_updated_by                           , -- 最終更新者
        last_update_date                          , -- 最終更新日
        last_update_login                         , -- 最終更新ログイン
        org_id                                      -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- 取引明細コンテキスト
        lv_interface_line_attribute1              , -- 取引明細DFF1(伝票番号)
        cn_1                                      , -- 取引明細DFF2(明細行番号)
        gv_ra_trx_type_tax                        , -- 取引ソース
        in_set_of_books_id                        , -- 会計帳簿ID
        cv_line                                   , -- 明細タイプ
        gv_description                            , -- 品目明細摘要
        cv_currency_code                          , -- 通貨コード
        in_tax_gap_amount                         , -- 明細金額
        gv_ra_trx_type_tax                        , -- 取引タイプ
        iv_term_name                              , -- 支払条件
        in_bill_cust_account_id                   , -- 請求先顧客ID
        in_bill_cust_acct_site_id                 , -- 請求先顧客所在地参照ID
        NULL                                      , -- リンク明細コンテキスト
        NULL                                      , -- リンク明細DFF1
        NULL                                      , -- リンク明細DFF2
        cv_user                                   , -- 換算タイプ
        cn_1                                      , -- 換算レート
        id_cutoff_date                            , -- 取引日
        id_cutoff_date                            , -- GL記帳日
        lv_interface_line_attribute1              , -- 伝票番号
        cn_1                                      , -- 数量
        in_tax_gap_amount                         , -- 販売単価
        gv_other_tax_code                         , -- 税金コード
        gn_org_id                                 , -- ヘッダーDFFカテゴリ
        gv_header_attribute5                      , -- ヘッダーDFF5(起票部門)
        gv_header_attribute6                      , -- ヘッダーDFF6(伝票入力者)
        cv_hold                                   , -- ヘッダーDFF7(請求書保留ステータス)
        cv_waiting                                , -- ヘッダーDFF8(個別請求書印刷)
        cv_waiting                                , -- ヘッダーDFF9(一括請求書印刷)
        iv_receipt_location_code                  , -- ヘッダーDFF11(入金拠点)
        in_invoice_id                             , -- ヘッダーDFF14(伝票番号)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- ヘッダーDFF15(GL記帳日)
        cn_user_id                                , -- 作成者
        SYSDATE                                   , -- 作成日
        cn_user_id                                , -- 最終更新者
        SYSDATE                                   , -- 最終更新日
        cn_login_id                               , -- 最終更新ログイン
        gn_org_id                                   -- 営業単位ID
        );
--
      -- ============================================================
      -- 税差額のAR会計配分OIF登録【本体行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- 取引明細コンテキスト
        interface_line_attribute1        , -- 取引明細DFF1
        interface_line_attribute2        , -- 取引明細DFF2
        account_class                    , -- 勘定科目区分(配分タイプ)
        amount                           , -- 金額(明細金額)
        percent                          , -- パーセント(割合)
        segment1                         , -- 会社セグメント
        segment2                         , -- 部門セグメント
        segment3                         , -- 勘定科目セグメント
        segment4                         , -- 補助科目セグメント
        segment5                         , -- 顧客セグメント
        segment6                         , -- 企業セグメント
        segment7                         , -- 予備１セグメント
        segment8                         , -- 予備２セグメント
        attribute_category               , -- 仕訳明細カテゴリ
        created_by                       , -- 作成者
        creation_date                    , -- 作成日
        last_updated_by                  , -- 最終更新者
        last_update_date                 , -- 最終更新日
        last_update_login                , -- 最終更新ログイン
        org_id                             -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- 取引明細コンテキスト
        lv_interface_line_attribute1     , -- 取引明細DFF1(伝票番号)
        cn_1                             , -- 取引明細DFF2(明細行番号)
        cv_rev                           , -- 勘定科目区分(配分タイプ)
        in_tax_gap_amount                , -- 金額(明細金額)
        cn_100                           , -- パーセント(割合)
        gv_aff1_company_code             , -- 会社セグメント
        gv_aff2_dept_fin                 , -- 部門セグメント
        gv_aff3_receive_excise_tax       , -- 勘定科目セグメント
        gv_aff4_subacct_dummy            , -- 補助科目セグメント
        gv_aff5_customer_dummy           , -- 顧客セグメント
        gv_aff6_company_dummy            , -- 企業セグメント
        gv_aff7_preliminary1_dummy       , -- 予備１セグメント
        gv_aff8_preliminary2_dummy       , -- 予備２セグメント
        gn_org_id                        , -- 明細DFFカテゴリ
        cn_user_id                       , -- 作成者
        SYSDATE                          , -- 作成日
        cn_user_id                       , -- 最終更新者
        SYSDATE                          , -- 最終更新日
        cn_login_id                      , -- 最終更新ログイン
        gn_org_id                          -- 営業単位ID
      );
--
      -- ============================================================
      -- 税差額のAR請求取引OIF登録【税金行】
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- 取引明細コンテキスト
        interface_line_attribute1                 , -- 取引明細DFF1(伝票番号)
        interface_line_attribute2                 , -- 取引明細DFF2(明細行番号)
        batch_source_name                         , -- 取引ソース
        set_of_books_id                           , -- 会計帳簿ID
        line_type                                 , -- 明細タイプ
        description                               , -- 品目明細摘要
        currency_code                             , -- 通貨コード
        amount                                    , -- 明細金額
        cust_trx_type_name                        , -- 取引タイプ
        term_name                                 , -- 支払条件
        orig_system_bill_customer_id              , -- 請求先顧客ID
        orig_system_bill_address_id               , -- 請求先顧客所在地参照ID
        link_to_line_context                      , -- リンク明細コンテキスト
        link_to_line_attribute1                   , -- リンク明細DFF1
        link_to_line_attribute2                   , -- リンク明細DFF2
        conversion_type                           , -- 換算タイプ
        conversion_rate                           , -- 換算レート
        trx_date                                  , -- 取引日
        gl_date                                   , -- GL記帳日
        trx_number                                , -- 伝票番号
        quantity                                  , -- 数量
        unit_selling_price                        , -- 販売単価
        tax_code                                  , -- 税金コード
        header_attribute_category                 , -- ヘッダーDFFカテゴリ
        header_attribute5                         , -- ヘッダーDFF5(起票部門)
        header_attribute6                         , -- ヘッダーDFF6(伝票入力者)
        header_attribute7                         , -- ヘッダーDFF7(請求書保留ステータス)
        header_attribute8                         , -- ヘッダーDFF8(個別請求書印刷)
        header_attribute9                         , -- ヘッダーDFF9(一括請求書印刷)
        header_attribute11                        , -- ヘッダーDFF11(入金拠点)
        header_attribute14                        , -- ヘッダーDFF14(伝票番号)
        header_attribute15                        , -- ヘッダーDFF15(GL記帳日)
        created_by                                , -- 作成者
        creation_date                             , -- 作成日
        last_updated_by                           , -- 最終更新者
        last_update_date                          , -- 最終更新日
        last_update_login                         , -- 最終更新ログイン
        org_id                                      -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- 取引明細コンテキスト
        lv_interface_line_attribute1              , -- 取引明細DFF1(伝票番号)
        cn_2                                      , -- 取引明細DFF2(明細行番号)
        gv_ra_trx_type_tax                        , -- 取引ソース
        in_set_of_books_id                        , -- 会計帳簿ID
        cv_tax                                    , -- 明細タイプ
        gv_description                            , -- 品目明細摘要
        cv_currency_code                          , -- 通貨コード
        cn_0                                      , -- 明細金額
        gv_ra_trx_type_tax                        , -- 取引タイプ
        iv_term_name                              , -- 支払条件
        in_bill_cust_account_id                   , -- 請求先顧客ID
        in_bill_cust_acct_site_id                 , -- 請求先顧客所在地参照ID
        gv_ra_trx_type_tax                        , -- リンク明細コンテキスト
        lv_interface_line_attribute1              , -- リンク明細DFF1
        cn_1                                      , -- リンク明細DFF2
        cv_user                                   , -- 換算タイプ
        cn_1                                      , -- 換算レート
        id_cutoff_date                            , -- 取引日
        NULL                                      , -- GL記帳日
        lv_interface_line_attribute1              , -- 伝票番号
        NULL                                      , -- 数量
        NULL                                      , -- 販売単価
        gv_other_tax_code                         , -- 税金コード
        gn_org_id                                 , -- ヘッダーDFFカテゴリ
        gv_header_attribute5                      , -- ヘッダーDFF5(起票部門)
        gv_header_attribute6                      , -- ヘッダーDFF6(伝票入力者)
        cv_hold                                   , -- ヘッダーDFF7(請求書保留ステータス)
        cv_waiting                                , -- ヘッダーDFF8(個別請求書印刷)
        cv_waiting                                , -- ヘッダーDFF9(一括請求書印刷)
        iv_receipt_location_code                  , -- ヘッダーDFF11(入金拠点)
        in_invoice_id                             , -- ヘッダーDFF14(伝票番号)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- ヘッダーDFF15(GL記帳日)
        cn_user_id                                , -- 作成者
        SYSDATE                                   , -- 作成日
        cn_user_id                                , -- 最終更新者
        SYSDATE                                   , -- 最終更新日
        cn_login_id                               , -- 最終更新ログイン
        gn_org_id                                   -- 営業単位ID
        );
--
      -- ============================================================
      -- 税差額のAR会計配分OIF登録【税金行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- 取引明細コンテキスト
        interface_line_attribute1        , -- 取引明細DFF1
        interface_line_attribute2        , -- 取引明細DFF2
        account_class                    , -- 勘定科目区分(配分タイプ)
        amount                           , -- 金額(明細金額)
        percent                          , -- パーセント(割合)
        segment1                         , -- 会社セグメント
        segment2                         , -- 部門セグメント
        segment3                         , -- 勘定科目セグメント
        segment4                         , -- 補助科目セグメント
        segment5                         , -- 顧客セグメント
        segment6                         , -- 企業セグメント
        segment7                         , -- 予備１セグメント
        segment8                         , -- 予備２セグメント
        attribute_category               , -- 仕訳明細カテゴリ
        created_by                       , -- 作成者
        creation_date                    , -- 作成日
        last_updated_by                  , -- 最終更新者
        last_update_date                 , -- 最終更新日
        last_update_login                , -- 最終更新ログイン
        org_id                             -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- 取引明細コンテキスト
        lv_interface_line_attribute1     , -- 取引明細DFF1(伝票番号)
        cn_2                             , -- 取引明細DFF2(明細行番号)
        cv_tax                           , -- 勘定科目区分(配分タイプ)
        cn_0                             , -- 金額(明細金額)
        cn_100                           , -- パーセント(割合)
        gv_aff1_company_code             , -- 会社セグメント
        gv_aff2_dept_fin                 , -- 部門セグメント
        gv_aff3_receive_excise_tax       , -- 勘定科目セグメント
        gv_aff4_subacct_dummy            , -- 補助科目セグメント
        gv_aff5_customer_dummy           , -- 顧客セグメント
        gv_aff6_company_dummy            , -- 企業セグメント
        gv_aff7_preliminary1_dummy       , -- 予備１セグメント
        gv_aff8_preliminary2_dummy       , -- 予備２セグメント
        gn_org_id                        , -- 明細DFFカテゴリ
        cn_user_id                       , -- 作成者
        SYSDATE                          , -- 作成日
        cn_user_id                       , -- 最終更新者
        SYSDATE                          , -- 最終更新日
        cn_login_id                      , -- 最終更新ログイン
        gn_org_id                          -- 営業単位ID
      );
--
      -- ============================================================
      -- 税差額のAR会計配分OIF登録【債権行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
          interface_line_context           , -- 取引明細コンテキスト
          interface_line_attribute1        , -- 取引明細DFF1
          interface_line_attribute2        , -- 取引明細DFF2
          account_class                    , -- 勘定科目区分(配分タイプ)
          amount                           , -- 金額(明細金額)
          percent                          , -- パーセント(割合)
          segment1                         , -- 会社セグメント
          segment2                         , -- 部門セグメント
          segment3                         , -- 勘定科目セグメント
          segment4                         , -- 補助科目セグメント
          segment5                         , -- 顧客セグメント
          segment6                         , -- 企業セグメント
          segment7                         , -- 予備１セグメント
          segment8                         , -- 予備２セグメント
          attribute_category               , -- 仕訳明細カテゴリ
          created_by                       , -- 作成者
          creation_date                    , -- 作成日
          last_updated_by                  , -- 最終更新者
          last_update_date                 , -- 最終更新日
          last_update_login                , -- 最終更新ログイン
          org_id                             -- 営業単位ID
          )
        VALUES(
          gv_ra_trx_type_tax               , -- 取引明細コンテキスト
          lv_interface_line_attribute1     , -- 取引明細DFF1(伝票番号)
          cn_1                             , -- 取引明細DFF2(明細行番号)
          cv_rec                           , -- 勘定科目区分(配分タイプ)
          NULL                             , -- 金額(明細金額)
          cn_100                           , -- パーセント(割合)
          gv_aff1_company_code             , -- 会社セグメント
          gv_aff2_dept_fin                 , -- 部門セグメント
          gv_aff3_account_receivable       , -- 勘定科目セグメント
          gv_aff4_subacct_dummy            , -- 補助科目セグメント
          gv_aff5_customer_dummy           , -- 顧客セグメント
          gv_aff6_company_dummy            , -- 企業セグメント
          gv_aff7_preliminary1_dummy       , -- 予備１セグメント
          gv_aff8_preliminary2_dummy       , -- 予備２セグメント
          gn_org_id                        , -- 明細DFFカテゴリ
          cn_user_id                       , -- 作成者
          SYSDATE                          , -- 作成日
          cn_user_id                       , -- 最終更新者
          SYSDATE                          , -- 最終更新日
          cn_login_id                      , -- 最終更新ログイン
          gn_org_id                          -- 営業単位ID
        );
    END IF;
--
--
    -- 本体差額が発生している場合AROIFを作成
    IF ( NVL(in_inv_gap_amount,0) <> 0 ) THEN
      -- ============================================================
      -- 伝票番号取得
      -- ============================================================
      SELECT  cv_ne || TO_CHAR(id_cutoff_date, cv_yyyymmdd) || LPAD(xxcfr_slip_number_ne_s01.NEXTVAL, 8, 0)
      INTO    lv_interface_line_atr1_inv
      FROM    dual;
--
      -- ============================================================
      -- 本体差額のAR請求取引OIF登録【本体行】
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- 取引明細コンテキスト
        interface_line_attribute1                 , -- 取引明細DFF1(伝票番号)
        interface_line_attribute2                 , -- 取引明細DFF2(明細行番号)
        batch_source_name                         , -- 取引ソース
        set_of_books_id                           , -- 会計帳簿ID
        line_type                                 , -- 明細タイプ
        description                               , -- 品目明細摘要
        currency_code                             , -- 通貨コード
        amount                                    , -- 明細金額
        cust_trx_type_name                        , -- 取引タイプ
        term_name                                 , -- 支払条件
        orig_system_bill_customer_id              , -- 請求先顧客ID
        orig_system_bill_address_id               , -- 請求先顧客所在地参照ID
        link_to_line_context                      , -- リンク明細コンテキスト
        link_to_line_attribute1                   , -- リンク明細DFF1
        link_to_line_attribute2                   , -- リンク明細DFF2
        conversion_type                           , -- 換算タイプ
        conversion_rate                           , -- 換算レート
        trx_date                                  , -- 取引日
        gl_date                                   , -- GL記帳日
        trx_number                                , -- 伝票番号
        quantity                                  , -- 数量
        unit_selling_price                        , -- 販売単価
        tax_code                                  , -- 税金コード
        header_attribute_category                 , -- ヘッダーDFFカテゴリ
        header_attribute5                         , -- ヘッダーDFF5(起票部門)
        header_attribute6                         , -- ヘッダーDFF6(伝票入力者)
        header_attribute7                         , -- ヘッダーDFF7(請求書保留ステータス)
        header_attribute8                         , -- ヘッダーDFF8(個別請求書印刷)
        header_attribute9                         , -- ヘッダーDFF9(一括請求書印刷)
        header_attribute11                        , -- ヘッダーDFF11(入金拠点)
        header_attribute14                        , -- ヘッダーDFF14(伝票番号)
        header_attribute15                        , -- ヘッダーDFF15(GL記帳日)
        created_by                                , -- 作成者
        creation_date                             , -- 作成日
        last_updated_by                           , -- 最終更新者
        last_update_date                          , -- 最終更新日
        last_update_login                         , -- 最終更新ログイン
        org_id                                      -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- 取引明細コンテキスト
        lv_interface_line_atr1_inv                , -- 取引明細DFF1(伝票番号)
        cn_1                                      , -- 取引明細DFF2(明細行番号)
        gv_ra_trx_type_tax                        , -- 取引ソース
        in_set_of_books_id                        , -- 会計帳簿ID
        cv_line                                   , -- 明細タイプ
        gv_description_inv                        , -- 品目明細摘要
        cv_currency_code                          , -- 通貨コード
        in_inv_gap_amount                         , -- 明細金額
        gv_ra_trx_type_tax                        , -- 取引タイプ
        iv_term_name                              , -- 支払条件
        in_bill_cust_account_id                   , -- 請求先顧客ID
        in_bill_cust_acct_site_id                 , -- 請求先顧客所在地参照ID
        NULL                                      , -- リンク明細コンテキスト
        NULL                                      , -- リンク明細DFF1
        NULL                                      , -- リンク明細DFF2
        cv_user                                   , -- 換算タイプ
        cn_1                                      , -- 換算レート
        id_cutoff_date                            , -- 取引日
        id_cutoff_date                            , -- GL記帳日
        lv_interface_line_atr1_inv                , -- 伝票番号
        cn_1                                      , -- 数量
        in_inv_gap_amount                         , -- 販売単価
        gv_other_tax_code                         , -- 税金コード
        gn_org_id                                 , -- ヘッダーDFFカテゴリ
        gv_header_attribute5_inv                  , -- ヘッダーDFF5(起票部門)
        gv_header_attribute6_inv                  , -- ヘッダーDFF6(伝票入力者)
        cv_hold                                   , -- ヘッダーDFF7(請求書保留ステータス)
        cv_waiting                                , -- ヘッダーDFF8(個別請求書印刷)
        cv_waiting                                , -- ヘッダーDFF9(一括請求書印刷)
        iv_receipt_location_code                  , -- ヘッダーDFF11(入金拠点)
        in_invoice_id                             , -- ヘッダーDFF14(伝票番号)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- ヘッダーDFF15(GL記帳日)
        cn_user_id                                , -- 作成者
        SYSDATE                                   , -- 作成日
        cn_user_id                                , -- 最終更新者
        SYSDATE                                   , -- 最終更新日
        cn_login_id                               , -- 最終更新ログイン
        gn_org_id                                   -- 営業単位ID
        );
--
      -- ============================================================
      -- 本体差額のAR会計配分OIF登録【本体行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- 取引明細コンテキスト
        interface_line_attribute1        , -- 取引明細DFF1
        interface_line_attribute2        , -- 取引明細DFF2
        account_class                    , -- 勘定科目区分(配分タイプ)
        amount                           , -- 金額(明細金額)
        percent                          , -- パーセント(割合)
        segment1                         , -- 会社セグメント
        segment2                         , -- 部門セグメント
        segment3                         , -- 勘定科目セグメント
        segment4                         , -- 補助科目セグメント
        segment5                         , -- 顧客セグメント
        segment6                         , -- 企業セグメント
        segment7                         , -- 予備１セグメント
        segment8                         , -- 予備２セグメント
        attribute_category               , -- 仕訳明細カテゴリ
        created_by                       , -- 作成者
        creation_date                    , -- 作成日
        last_updated_by                  , -- 最終更新者
        last_update_date                 , -- 最終更新日
        last_update_login                , -- 最終更新ログイン
        org_id                             -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- 取引明細コンテキスト
        lv_interface_line_atr1_inv       , -- 取引明細DFF1(伝票番号)
        cn_1                             , -- 取引明細DFF2(明細行番号)
        cv_rev                           , -- 勘定科目区分(配分タイプ)
        in_inv_gap_amount                , -- 金額(明細金額)
        cn_100                           , -- パーセント(割合)
        gv_aff1_company_code             , -- 会社セグメント
        gv_header_attribute5_inv         , -- 部門セグメント
        gv_aff3_rev_inv                  , -- 勘定科目セグメント
        gv_aff4_rev_inv                  , -- 補助科目セグメント
        gv_aff5_customer_dummy           , -- 顧客セグメント
        gv_aff6_company_dummy            , -- 企業セグメント
        gv_aff7_preliminary1_dummy       , -- 予備１セグメント
        gv_aff8_preliminary2_dummy       , -- 予備２セグメント
        gn_org_id                        , -- 明細DFFカテゴリ
        cn_user_id                       , -- 作成者
        SYSDATE                          , -- 作成日
        cn_user_id                       , -- 最終更新者
        SYSDATE                          , -- 最終更新日
        cn_login_id                      , -- 最終更新ログイン
        gn_org_id                          -- 営業単位ID
      );
--
      -- ============================================================
      -- 本体差額のAR請求取引OIF登録【税金行】
      -- ============================================================
      INSERT  INTO  ra_interface_lines_all(
        interface_line_context                    , -- 取引明細コンテキスト
        interface_line_attribute1                 , -- 取引明細DFF1(伝票番号)
        interface_line_attribute2                 , -- 取引明細DFF2(明細行番号)
        batch_source_name                         , -- 取引ソース
        set_of_books_id                           , -- 会計帳簿ID
        line_type                                 , -- 明細タイプ
        description                               , -- 品目明細摘要
        currency_code                             , -- 通貨コード
        amount                                    , -- 明細金額
        cust_trx_type_name                        , -- 取引タイプ
        term_name                                 , -- 支払条件
        orig_system_bill_customer_id              , -- 請求先顧客ID
        orig_system_bill_address_id               , -- 請求先顧客所在地参照ID
        link_to_line_context                      , -- リンク明細コンテキスト
        link_to_line_attribute1                   , -- リンク明細DFF1
        link_to_line_attribute2                   , -- リンク明細DFF2
        conversion_type                           , -- 換算タイプ
        conversion_rate                           , -- 換算レート
        trx_date                                  , -- 取引日
        gl_date                                   , -- GL記帳日
        trx_number                                , -- 伝票番号
        quantity                                  , -- 数量
        unit_selling_price                        , -- 販売単価
        tax_code                                  , -- 税金コード
        header_attribute_category                 , -- ヘッダーDFFカテゴリ
        header_attribute5                         , -- ヘッダーDFF5(起票部門)
        header_attribute6                         , -- ヘッダーDFF6(伝票入力者)
        header_attribute7                         , -- ヘッダーDFF7(請求書保留ステータス)
        header_attribute8                         , -- ヘッダーDFF8(個別請求書印刷)
        header_attribute9                         , -- ヘッダーDFF9(一括請求書印刷)
        header_attribute11                        , -- ヘッダーDFF11(入金拠点)
        header_attribute14                        , -- ヘッダーDFF14(伝票番号)
        header_attribute15                        , -- ヘッダーDFF15(GL記帳日)
        created_by                                , -- 作成者
        creation_date                             , -- 作成日
        last_updated_by                           , -- 最終更新者
        last_update_date                          , -- 最終更新日
        last_update_login                         , -- 最終更新ログイン
        org_id                                      -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax                        , -- 取引明細コンテキスト
        lv_interface_line_atr1_inv                , -- 取引明細DFF1(伝票番号)
        cn_2                                      , -- 取引明細DFF2(明細行番号)
        gv_ra_trx_type_tax                        , -- 取引ソース
        in_set_of_books_id                        , -- 会計帳簿ID
        cv_tax                                    , -- 明細タイプ
        gv_description_inv                        , -- 品目明細摘要
        cv_currency_code                          , -- 通貨コード
        cn_0                                      , -- 明細金額
        gv_ra_trx_type_tax                        , -- 取引タイプ
        iv_term_name                              , -- 支払条件
        in_bill_cust_account_id                   , -- 請求先顧客ID
        in_bill_cust_acct_site_id                 , -- 請求先顧客所在地参照ID
        gv_ra_trx_type_tax                        , -- リンク明細コンテキスト
        lv_interface_line_atr1_inv                , -- リンク明細DFF1
        cn_1                                      , -- リンク明細DFF2
        cv_user                                   , -- 換算タイプ
        cn_1                                      , -- 換算レート
        id_cutoff_date                            , -- 取引日
        NULL                                      , -- GL記帳日
        lv_interface_line_atr1_inv                , -- 伝票番号
        NULL                                      , -- 数量
        NULL                                      , -- 販売単価
        gv_other_tax_code                         , -- 税金コード
        gn_org_id                                 , -- ヘッダーDFFカテゴリ
        gv_header_attribute5_inv                  , -- ヘッダーDFF5(起票部門)
        gv_header_attribute6_inv                  , -- ヘッダーDFF6(伝票入力者)
        cv_hold                                   , -- ヘッダーDFF7(請求書保留ステータス)
        cv_waiting                                , -- ヘッダーDFF8(個別請求書印刷)
        cv_waiting                                , -- ヘッダーDFF9(一括請求書印刷)
        iv_receipt_location_code                  , -- ヘッダーDFF11(入金拠点)
        in_invoice_id                             , -- ヘッダーDFF14(伝票番号)
        TO_CHAR(id_cutoff_date, cv_yyyy_mm_dd)    , -- ヘッダーDFF15(GL記帳日)
        cn_user_id                                , -- 作成者
        SYSDATE                                   , -- 作成日
        cn_user_id                                , -- 最終更新者
        SYSDATE                                   , -- 最終更新日
        cn_login_id                               , -- 最終更新ログイン
        gn_org_id                                   -- 営業単位ID
        );
--
      -- ============================================================
      -- 本体差額のAR会計配分OIF登録【税金行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
        interface_line_context           , -- 取引明細コンテキスト
        interface_line_attribute1        , -- 取引明細DFF1
        interface_line_attribute2        , -- 取引明細DFF2
        account_class                    , -- 勘定科目区分(配分タイプ)
        amount                           , -- 金額(明細金額)
        percent                          , -- パーセント(割合)
        segment1                         , -- 会社セグメント
        segment2                         , -- 部門セグメント
        segment3                         , -- 勘定科目セグメント
        segment4                         , -- 補助科目セグメント
        segment5                         , -- 顧客セグメント
        segment6                         , -- 企業セグメント
        segment7                         , -- 予備１セグメント
        segment8                         , -- 予備２セグメント
        attribute_category               , -- 仕訳明細カテゴリ
        created_by                       , -- 作成者
        creation_date                    , -- 作成日
        last_updated_by                  , -- 最終更新者
        last_update_date                 , -- 最終更新日
        last_update_login                , -- 最終更新ログイン
        org_id                             -- 営業単位ID
        )
      VALUES(
        gv_ra_trx_type_tax               , -- 取引明細コンテキスト
        lv_interface_line_atr1_inv       , -- 取引明細DFF1(伝票番号)
        cn_2                             , -- 取引明細DFF2(明細行番号)
        cv_tax                           , -- 勘定科目区分(配分タイプ)
        cn_0                             , -- 金額(明細金額)
        cn_100                           , -- パーセント(割合)
        gv_aff1_company_code             , -- 会社セグメント
        gv_aff2_dept_fin                 , -- 部門セグメント
        gv_aff3_tax_inv                  , -- 勘定科目セグメント
        gv_aff4_tax_inv                  , -- 補助科目セグメント
        gv_aff5_customer_dummy           , -- 顧客セグメント
        gv_aff6_company_dummy            , -- 企業セグメント
        gv_aff7_preliminary1_dummy       , -- 予備１セグメント
        gv_aff8_preliminary2_dummy       , -- 予備２セグメント
        gn_org_id                        , -- 明細DFFカテゴリ
        cn_user_id                       , -- 作成者
        SYSDATE                          , -- 作成日
        cn_user_id                       , -- 最終更新者
        SYSDATE                          , -- 最終更新日
        cn_login_id                      , -- 最終更新ログイン
        gn_org_id                          -- 営業単位ID
      );
--
      -- ============================================================
      -- 本体差額のAR会計配分OIF登録【債権行】
      -- ============================================================
      INSERT  INTO  ra_interface_distributions_all(
          interface_line_context           , -- 取引明細コンテキスト
          interface_line_attribute1        , -- 取引明細DFF1
          interface_line_attribute2        , -- 取引明細DFF2
          account_class                    , -- 勘定科目区分(配分タイプ)
          amount                           , -- 金額(明細金額)
          percent                          , -- パーセント(割合)
          segment1                         , -- 会社セグメント
          segment2                         , -- 部門セグメント
          segment3                         , -- 勘定科目セグメント
          segment4                         , -- 補助科目セグメント
          segment5                         , -- 顧客セグメント
          segment6                         , -- 企業セグメント
          segment7                         , -- 予備１セグメント
          segment8                         , -- 予備２セグメント
          attribute_category               , -- 仕訳明細カテゴリ
          created_by                       , -- 作成者
          creation_date                    , -- 作成日
          last_updated_by                  , -- 最終更新者
          last_update_date                 , -- 最終更新日
          last_update_login                , -- 最終更新ログイン
          org_id                             -- 営業単位ID
          )
        VALUES(
          gv_ra_trx_type_tax               , -- 取引明細コンテキスト
          lv_interface_line_atr1_inv       , -- 取引明細DFF1(伝票番号)
          cn_1                             , -- 取引明細DFF2(明細行番号)
          cv_rec                           , -- 勘定科目区分(配分タイプ)
          NULL                             , -- 金額(明細金額)
          cn_100                           , -- パーセント(割合)
          gv_aff1_company_code             , -- 会社セグメント
          gv_aff2_dept_fin                 , -- 部門セグメント
          gv_aff3_rec_inv                  , -- 勘定科目セグメント
          gv_aff4_rec_inv                  , -- 補助科目セグメント
          gv_aff5_customer_dummy           , -- 顧客セグメント
          gv_aff6_company_dummy            , -- 企業セグメント
          gv_aff7_preliminary1_dummy       , -- 予備１セグメント
          gv_aff8_preliminary2_dummy       , -- 予備２セグメント
          gn_org_id                        , -- 明細DFFカテゴリ
          cn_user_id                       , -- 作成者
          SYSDATE                          , -- 作成日
          cn_user_id                       , -- 最終更新者
          SYSDATE                          , -- 最終更新日
          cn_login_id                      , -- 最終更新ログイン
          gn_org_id                          -- 営業単位ID
        );
    END IF;
--
    -- 登録件数カウント
    gn_normal_cnt :=  gn_normal_cnt + 1;
--
    -- ============================================================
    -- 請求ヘッダ情報更新(A-4)
    -- ============================================================
    UPDATE  xxcfr_invoice_headers xih
    SET     xih.tax_diff_amount_create_flg = cv_created        , -- 作成済
            xih.last_updated_by            = cn_user_id        , -- 最終更新者
            xih.last_update_date           = SYSDATE           , -- 最終更新日
            xih.last_update_login          = cn_login_id       , -- 最終更新ログイン
            xih.request_id                 = cn_conc_request_id, -- 要求ID
            xih.program_application_id     = cn_prog_appl_id   , -- コンカレント・プログラム・アプリケーションID
            xih.program_id                 = cn_conc_program_id, -- コンカレント・プログラムID
            xih.program_update_date        = SYSDATE             -- プログラム更新日
    WHERE   xih.invoice_id  = in_invoice_id;
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
   * Procedure Name   : get_invoice_p
   * Description      : 請求ヘッダ情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_invoice_p(
    ov_errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2  -- リターン・コード
  , ov_errmsg   OUT VARCHAR2  -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_invoice_p'; -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- AR連係対象請求データ
    CURSOR l_target_inv_cur
    IS
      SELECT  xih.invoice_id                 AS invoice_id                    -- 一括請求書ID
             ,xih.set_of_books_id            AS set_of_books_id               -- 会計帳簿ID
-- Mod Ver1.1 Start
             ,xih.inv_gap_amount  - NVL(xih.inv_gap_amount_sent, 0)
                                             AS inv_gap_amount                -- 本体差額
             ,xih.tax_gap_amount  - NVL(xih.tax_gap_amount_sent, 0)
                                             AS tax_gap_amount                -- 税差額
--             ,xih.inv_gap_amount             AS inv_gap_amount                -- 本体差額
--             ,xih.tax_gap_amount             AS tax_gap_amount                -- 税差額
-- Mod Ver1.1 End
             ,xih.term_name                  AS term_name                     -- 支払条件
             ,xih.bill_cust_account_id       AS bill_cust_account_id          -- 請求先顧客ID
             ,xih.bill_cust_acct_site_id     AS bill_cust_acct_site_id        -- 請求先顧客所在地ID
             ,xih.cutoff_date                AS cutoff_date                   -- 締日
             ,xih.receipt_location_code      AS receipt_location_code         -- 入金拠点コード
      FROM    xxcfr_invoice_headers xih
      WHERE   xih.tax_diff_amount_create_flg = cv_not_created                 -- 未作成
      FOR UPDATE NOWAIT
      ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 請求ヘッダ情報抽出
    -- ============================================================
    FOR l_target_inv_rec IN  l_target_inv_cur LOOP
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ============================================================
      -- AR連係処理(A-3)の呼び出し
      -- ============================================================
      transfer_to_ar_p(
        ov_errbuf                   =>  lv_errbuf                                   -- エラー・メッセージ
      , ov_retcode                  =>  lv_retcode                                  -- リターン・コード
      , ov_errmsg                   =>  lv_errmsg                                   -- ユーザー・エラー・メッセージ
      , in_invoice_id               =>  l_target_inv_rec.invoice_id                 -- 一括請求書ID
      , in_set_of_books_id          =>  l_target_inv_rec.set_of_books_id            -- 会計帳簿ID
      , in_inv_gap_amount           =>  l_target_inv_rec.inv_gap_amount             -- 本体差額
      , in_tax_gap_amount           =>  l_target_inv_rec.tax_gap_amount             -- 税差額
      , iv_term_name                =>  l_target_inv_rec.term_name                  -- 支払条件
      , in_bill_cust_account_id     =>  l_target_inv_rec.bill_cust_account_id       -- 請求先顧客ID
      , in_bill_cust_acct_site_id   =>  l_target_inv_rec.bill_cust_acct_site_id     -- 請求先顧客所在地ID
      , id_cutoff_date              =>  l_target_inv_rec.cutoff_date                -- 締日
      , iv_receipt_location_code    =>  l_target_inv_rec.receipt_location_code      -- 入金拠点コード
      );
--
      IF ( lv_retcode  = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
  EXCEPTION
    WHEN global_data_lock_expt THEN
      -- ロックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_xxcfr_name
                    ,iv_name         => cv_msg_cfr_00003     -- ロックエラー
                    ,iv_token_name1  => cv_tkn_table
                    ,iv_token_value1 => cv_table_name
                   );
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
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
  END get_invoice_p;
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
      gn_error_cnt  :=  1;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 請求ヘッダ情報抽出(A-2)の呼び出し
    -- ============================================================
    get_invoice_p(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode  = cv_status_error ) THEN
      gn_error_cnt  :=  1;
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
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
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
    -- ============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf   -- エラー・メッセージ
    , ov_retcode => lv_retcode  -- リターン・コード
    , ov_errmsg  => lv_errmsg   -- ユーザー・エラー・メッセージ
    );
--
--###########################  固定部 START   #####################################################
--
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_cfr_00056
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
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
                    ,iv_token_name1  => cv_tkn_count
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
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
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
    fnd_file.put_line(
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
END XXCFR003A23C;
/
