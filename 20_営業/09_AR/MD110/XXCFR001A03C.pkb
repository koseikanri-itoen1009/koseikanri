CREATE OR REPLACE PACKAGE BODY XXCFR001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A03C(body)
 * Description      : 入金情報データ連携
 * MD.050           : MD050_CFR_001_A03_入金情報データ連携
 * MD.070           : MD050_CFR_001_A03_入金情報データ連携
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  get_last_close_period_name p 最後にクローズした会計期間名取得    (A-4)
 *  get_cash_receipts_data p 入金情報データ取得                      (A-5)
 *  put_cash_receipts_data p 入金情報データＣＳＶ作成処理            (A-6)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.00 SCS 中村 博      初回作成
 *  2009/02/27    1.1  SCS T.KANEDA     [障害CFR_001] 金額取得不具合対応
 *  2010/01/06    1.2  SCS 安川 智博    障害「E_本稼動_00753」対応
 *  2010/03/08    1.3  SCS 安川 智博    障害「E_本稼動_01859」対応
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A03C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
--
  cv_msg_001a03_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_001a03_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --ファイル名出力メッセージ
  cv_msg_001a03_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --対象データが0件メッセージ
  cv_msg_001a03_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --会計期間名取得なしエラーメッセージ
  cv_msg_001a03_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --ファイルの場所が無効メッセージ
  cv_msg_001a03_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --ファイルをオープンできないメッセージ
  cv_msg_001a03_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; --ファイルに書込みできないメッセー
  cv_msg_001a03_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00050'; --ファイルが存在しているメッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- ファイル名
  cv_tkn_path        CONSTANT VARCHAR2(15) := 'FILE_PATH';        -- ファイルパス
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- データ
--
  --プロファイル
  cv_org_id            CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
  cv_set_of_bks_id     CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_receipt_filename  CONSTANT VARCHAR2(35) := 'XXCFR1_CASH_RECEIPTS_DATA_FILENAME';
                                                                    -- XXCFR:入金情報データファイル名
  cv_receipt_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_CASH_RECEIPTS_DATA_FILEPATH';
                                                                    -- XXCFR: 入金情報データファイル格納パス
--
  -- 日本語辞書
  cv_dict_peroid_name  CONSTANT VARCHAR2(100) := 'CFR001A03001';    -- 最後にクローズした会計期間名
--
  -- 改行コード
  cv_cr              CONSTANT VARCHAR2(1) := CHR(10);      -- 改行コード
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- フラグ（Ｙ）
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- フラグ（Ｎ）
--
    cv_format_date_ym CONSTANT VARCHAR2(6)      := 'YYYYMM';            -- 日付フォーマット（年月）
    cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- 日付フォーマット（年月日時分秒）
--
-- Modify 2010.03.08 Ver1.3 Start
  cv_receivable_status_unid CONSTANT ar_receivable_applications_all.status%TYPE := 'UNID'; -- 不明入金ステータス
  cv_receivable_source_table CONSTANT ar_distributions_all.source_table%TYPE := 'CRH'; -- 会計情報内ソーステーブル名
-- Modify 2010.03.08 Ver1.3 End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id                NUMBER;            -- 組織ID
  gn_set_of_bks_id         NUMBER;            -- 会計帳簿ID
  gv_receipt_filename      VARCHAR2(100);     -- 入金情報データファイル名
  gv_receipt_filepath      VARCHAR2(500);     -- 入金情報データファイル格納パス
  gv_period_name           gl_period_statuses.period_name%TYPE;  -- 会計期間名
  gv_start_date_yymm       VARCHAR2(6);       -- 会計期間年月
-- Modify 2009.02.27 Ver1.1 Start
  gd_start_date            DATE;              -- 会計期間開始日
  gd_end_date              DATE;              -- 会計期間終了日
-- Modify 2009.02.27 Ver1.1 End
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
    -- 抽出
    CURSOR get_cash_receipts_cur
    IS
-- Modify 2009.02.27 Ver1.1 Start
--      SELECT hca_b.account_number           bill_to_account_number,     -- 顧客コード（請求先顧客コード）
--             gcc.segment1                   company_code,               -- 会社コード
--             sum ( jzabv.begin_bal_entered_dr
--                 - jzabv.begin_bal_entered_cr
--                 + jzabv.period_net_entered_dr ) amount_due_remaining,  -- 入金予定額
--             sum ( jzabv.period_net_entered_cr ) amount_applied         -- 入金実績額
--      FROM jg_zz_ar_balances_v         jzabv,                           -- JG顧客残高テーブル
--           hz_cust_accounts            hca_b,                           -- 顧客マスタ（請求先）
--           gl_code_combinations        gcc                              -- 勘定科目組合せマスタ
--      WHERE jzabv.period_name          = gv_period_name
--        AND jzabv.set_of_books_id      = gn_set_of_bks_id
--        AND (( jzabv.begin_bal_entered_dr - jzabv.begin_bal_entered_cr <> 0 )
--            OR jzabv.period_net_entered_dr <> 0
--            OR jzabv.period_net_entered_cr <> 0 )
--        AND jzabv.customer_id          = hca_b.cust_account_id(+)
--        AND jzabv.code_combination_id  = gcc.code_combination_id
--      GROUP BY
--        gcc.segment1,
--        hca_b.account_number
--      ORDER BY 
--        hca_b.account_number
-- Modify 2010.03.08 Ver1.3 Start
/*
      SELECT sub_bal.bill_to_account_number                bill_to_account_number -- 顧客コード（請求先顧客コード）
            ,sub_bal.customer_id                           customer_id            -- 顧客ＩＤ
            ,sub_bal.company_code                          company_code           -- 会社コード
            ,( sub_bal.amount_due_remaining
                 - NVL(sub_unapp.unapp_entered_dr ,0) )    amount_due_remaining   -- 入金予定額
            ,( sub_bal.amount_applied
                 - NVL( sub_unapp.unapp_entered_cr ,0) )   amount_applied         -- 入金実績額
       FROM
            (
             SELECT hca_b.account_number           bill_to_account_number,     -- 顧客コード（請求先顧客コード）
                    jzabv.customer_id              customer_id,                -- 会社コード
                    gcc.segment1                   company_code,               -- 会社コード
                    SUM(  jzabv.begin_bal_entered_dr
                        - jzabv.begin_bal_entered_cr
                        + jzabv.period_net_entered_dr ) amount_due_remaining,  -- 入金予定額
                    SUM(  jzabv.period_net_entered_cr ) amount_applied         -- 入金実績額
             FROM jg_zz_ar_balances_v         jzabv,                           -- JG顧客残高テーブル
                  hz_cust_accounts            hca_b,                           -- 顧客マスタ（請求先）
                  gl_code_combinations        gcc                              -- 勘定科目組合せマスタ
             WHERE jzabv.period_name          = gv_period_name
               AND jzabv.set_of_books_id      = gn_set_of_bks_id
               AND (( jzabv.begin_bal_entered_dr - jzabv.begin_bal_entered_cr <> 0 )
                   OR jzabv.period_net_entered_dr <> 0
                   OR jzabv.period_net_entered_cr <> 0 )
-- Modify 2010.01.06 Ver1.2 Start
--               AND jzabv.customer_id          = hca_b.cust_account_id(+)
               AND jzabv.customer_id          = hca_b.cust_account_id
-- Modify 2010.01.06 Ver1.2 Start
               AND jzabv.code_combination_id  = gcc.code_combination_id
             GROUP BY
               gcc.segment1,
               hca_b.account_number,
               jzabv.customer_id
             ) sub_bal,
            (
             SELECT sum(nvl(jzatd.entered_dr,0)) unapp_entered_dr,
                    sum(nvl(jzatd.entered_cr,0)) unapp_entered_cr,
                    jzatd.customer_id            customer_id
               FROM jg_zz_ar_tmp_detail jzatd
              WHERE jzatd.set_of_books_id = gn_set_of_bks_id
                AND jzatd.accounting_date BETWEEN gd_start_date
                                              AND gd_end_date
                AND jzatd.account_class = 'UNAPP'
              GROUP BY jzatd.customer_id
            ) sub_unapp
       WHERE sub_bal.customer_id = sub_unapp.customer_id(+)
       ORDER BY sub_bal.bill_to_account_number
    ;
*/
      SELECT hca_b.account_number                          bill_to_account_number, -- 顧客コード（請求先顧客コード）
             jzabv.customer_id                             customer_id,            -- 会社コード
             gcc.segment1                                  company_code,           -- 会社コード
             (
              SELECT 
              SUM( NVL(ada.amount_dr,0) - NVL(ada.amount_cr,0)) amount_applied
              FROM 
              ar_cash_receipts_all acra,
              ar_cash_receipt_history acrh,
              ar_distributions_all ada
              WHERE acra.pay_from_customer = jzabv.customer_id
                AND acra.set_of_books_id = gn_set_of_bks_id
                AND acra.org_id = gn_org_id
                AND acra.cash_receipt_id = acrh.cash_receipt_id
                AND acrh.gl_date >= gd_start_date
                AND acrh.gl_date <= gd_end_date
                AND ada.source_table = cv_receivable_source_table
                AND ada.source_id = acrh.cash_receipt_history_id
             ) amount_receive,                                                     -- ①当月入金額
             (
              SELECT 
              SUM( NVL(araa.amount_applied,0))
              FROM 
              ar_cash_receipts_all acra,
              ar_receivable_applications_all araa
              WHERE acra.pay_from_customer = jzabv.customer_id
                AND acra.set_of_books_id = gn_set_of_bks_id
                AND acra.org_id = gn_org_id
                AND araa.cash_receipt_id = acra.cash_receipt_id
                AND araa.status = cv_receivable_status_unid
                AND araa.gl_date >= gd_start_date
                AND araa.gl_date <= gd_end_date
             ) amount_uid,                                                         -- ②不明入金当月紐付け分
             SUM(  jzabv.begin_bal_entered_dr
                 - jzabv.begin_bal_entered_cr
                 + jzabv.period_net_entered_dr
                 - jzabv.period_net_entered_cr) amount_balance                     -- ③月末残高
      FROM jg_zz_ar_balances_v         jzabv,                           -- JG顧客残高テーブル
           hz_cust_accounts            hca_b,                           -- 顧客マスタ（請求先）
           gl_code_combinations        gcc                              -- 勘定科目組合せマスタ
      WHERE jzabv.period_name = gv_period_name
        AND jzabv.set_of_books_id = gn_set_of_bks_id
        AND (( jzabv.begin_bal_entered_dr - jzabv.begin_bal_entered_cr <> 0 )
            OR jzabv.period_net_entered_dr <> 0
            OR jzabv.period_net_entered_cr <> 0 )
        AND jzabv.customer_id = hca_b.cust_account_id
        AND jzabv.code_combination_id = gcc.code_combination_id
      GROUP BY gcc.segment1,
               hca_b.account_number,
               jzabv.customer_id
      ORDER BY hca_b.account_number;
-- Modify 2010.03.08 Ver1.3 End
-- Modify 2009.02.27 Ver1.1 End
--
    TYPE g_cash_receipts_ttype IS TABLE OF get_cash_receipts_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_cash_receipts_data      g_cash_receipts_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
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
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- 会計帳簿ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR:入金情報データファイル名取得
    gv_receipt_filename := FND_PROFILE.VALUE(cv_receipt_filename);
    -- 取得エラー時
    IF (gv_receipt_filename IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_receipt_filename))
                                                       -- XXCFR:入金情報データファイル名
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルからXXCFR: 入金情報データファイル格納パス取得
    gv_receipt_filepath := FND_PROFILE.VALUE(cv_receipt_filepath);
    -- 取得エラー時
    IF (gv_receipt_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_receipt_filepath))
                                                       -- XXCFR: 入金情報データファイル格納パス
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
-- Modify 2010.03.08 Ver1.3 Start
    -- プロファイルから組織IDを取得
    gn_org_id := FND_PROFILE.VALUE(cv_org_id);
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 会計帳簿ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
-- Modify 2010.03.08 Ver1.3 End
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_last_close_period_name
   * Description      : 最後にクローズした会計期間名取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_last_close_period_name(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_last_close_period_name'; -- プログラム名
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
    cv_gl_short_name   CONSTANT VARCHAR2(5)   := 'SQLGL';    -- アプリケーション短縮名（ＧＬ)
    cv_flag_no         CONSTANT VARCHAR2(1)   := 'N';        -- フラグ（Ｎ）
    cv_close_status_c  CONSTANT VARCHAR2(1)   := 'C';        -- クローズステータス（クローズ)
    cv_close_status_p  CONSTANT VARCHAR2(1)   := 'P';        -- クローズステータス（永久クローズ)
--
    -- *** ローカル変数 ***
    ln_target_cnt     NUMBER;         -- 対象件数
    ln_loop_cnt       NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 最後にクローズした会計期間名抽出
    CURSOR get_period_name_cur
    IS
      SELECT gps.period_name                                period_name,    -- 会計期間名
-- Modify 2009.02.27 Ver1.1 Start
             gps.start_date                                 start_date,     -- 会計期間開始日
             gps.end_date                                   end_date,       -- 会計期間終了日
-- Modify 2009.02.27 Ver1.1 End
             TO_CHAR ( gps.start_date, cv_format_date_ym )  start_date_yymm -- 会計期間年月
      FROM gl_period_statuses             gps,          -- GL会計期間ステータス
           gl_sets_of_books               gsob,         -- GL会計帳簿
           fnd_application                fa            -- 会計アプリケーション
      WHERE gps.application_id            = fa.application_id
        AND fa.application_short_name     = cv_gl_short_name   -- ＧＬ
        AND gps.adjustment_period_flag    = cv_flag_no         -- 調整期間でない
        AND gps.set_of_books_id           = gsob.set_of_books_id
        -- AND gps.closing_status            IN ( 'O','C','P' )   -- クローズ、永久クローズ
        AND gps.closing_status            IN ( cv_close_status_c, cv_close_status_p )  -- クローズ、永久クローズ
        AND gsob.set_of_books_id          = gn_set_of_bks_id
      ORDER BY gps.start_date desc
    ;
--
    TYPE l_period_name_ttype IS TABLE OF get_period_name_cur%ROWTYPE INDEX BY PLS_INTEGER;
    lt_period_name_data      l_period_name_ttype;
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
    -- カーソルオープン
    OPEN get_period_name_cur;
--
    -- データの一括取得
    FETCH get_period_name_cur BULK COLLECT INTO lt_period_name_data;
--
    -- 処理件数のセット
    ln_target_cnt := lt_period_name_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_period_name_cur;
--
    -- 対象データありの場合は１件目をグローバル変数に設定
    IF (ln_target_cnt > 0) THEN
--
      gv_period_name      := lt_period_name_data(1).period_name;
      gv_start_date_yymm  := lt_period_name_data(1).start_date_yymm;
-- Modify 2009.02.27 Ver1.1 Start
      gd_start_date       := lt_period_name_data(1).start_date;
      gd_end_date         := TO_DATE(TO_CHAR(lt_period_name_data(1).end_date,'yyyymmdd')||'235959','yyyymmddhh24miss');
-- Modify 2009.02.27 Ver1.1 End
--
    -- 対象データなしの場合は、エラーメッセージを設定
    ELSE
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_013 -- 会計期間名取得なしエラー
                                                    ,cv_tkn_data
                                                    ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfr
                                                      ,cv_dict_peroid_name 
                                                     )
                                                   )
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
--
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
  END get_last_close_period_name;
--
  /**********************************************************************************
   * Procedure Name   : get_cash_receipts_data
   * Description      : 入金情報データ取得 (A-5)
   ***********************************************************************************/
  PROCEDURE get_cash_receipts_data(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_receipts_data'; -- プログラム名
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
    -- カーソルオープン
    OPEN get_cash_receipts_cur;
--
    -- データの一括取得
    FETCH get_cash_receipts_cur BULK COLLECT INTO gt_cash_receipts_data;
--
    -- 処理件数のセット
    gn_target_cnt := gt_cash_receipts_data.COUNT;
--
    -- カーソルクローズ
    CLOSE get_cash_receipts_cur;
--
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_012 -- 対象データが0件エラー
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_cash_receipts_data;
--
  /**********************************************************************************
   * Procedure Name   : put_cash_receipts_data
   * Description      : 入金情報データＣＳＶ作成処理 (A-6)
   ***********************************************************************************/
  PROCEDURE put_cash_receipts_data(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_cash_receipts_data'; -- プログラム名
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- ファイルオープンモード（上書き）
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV区切り文字
    cv_enclosed       CONSTANT VARCHAR2(2)  := '"';     -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
    -- 
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text         VARCHAR2(32000) ;       -- 出力１行分文字列変数
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
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
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_receipt_filepath,
                      gv_receipt_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- 前回ファイルが存在している
    IF lb_fexists THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_017 -- ファイルが存在している
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_receipt_filepath
                       ,gv_receipt_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
    <<out_loop>>
    FOR ln_loop_cnt IN gt_cash_receipts_data.FIRST..gt_cash_receipts_data.LAST LOOP
--
      -- 出力文字列作成
      lv_csv_text := cv_enclosed || gt_cash_receipts_data(ln_loop_cnt).company_code || cv_enclosed || cv_delimiter
                  || gv_start_date_yymm || cv_delimiter
                  || cv_enclosed || gt_cash_receipts_data(ln_loop_cnt).bill_to_account_number || cv_enclosed || cv_delimiter
-- Modify 2010.03.08 Ver1.3 Start
--                  || TO_CHAR ( gt_cash_receipts_data(ln_loop_cnt).amount_due_remaining ) ||  cv_delimiter
                  -- 入金予定額 = 月末残高 + 当月計上入金額(①当月入金額に②不明入金当月紐付け分を加味)
                  || TO_CHAR ( NVL(gt_cash_receipts_data(ln_loop_cnt).amount_balance,0) 
                             + NVL(gt_cash_receipts_data(ln_loop_cnt).amount_receive,0) 
                             - NVL(gt_cash_receipts_data(ln_loop_cnt).amount_uid,0) )||  cv_delimiter
--                  || TO_CHAR ( gt_cash_receipts_data(ln_loop_cnt).amount_applied ) || cv_delimiter
                  -- 入金実績 = 当月計上入金額(①当月入金額に②不明入金当月紐付け分を加味)
                  || TO_CHAR ( NVL(gt_cash_receipts_data(ln_loop_cnt).amount_receive,0) 
                             - NVL(gt_cash_receipts_data(ln_loop_cnt).amount_uid,0) ) ||  cv_delimiter
-- Modify 2010.03.08 Ver1.3 End
                  || TO_CHAR ( cd_last_update_date, cv_format_date_ymdhns)
      ;
--
      -- ====================================================
      -- ファイル書き込み
      -- ====================================================
      UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- 処理件数カウントアップ
      -- ====================================================
      ln_target_cnt := ln_target_cnt + 1 ;
--
    END LOOP out_loop;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_target_cnt;
--
  EXCEPTION
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_014 -- ファイルの場所が無効
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_015 -- ファイルをオープンできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a03_016 -- ファイルに書込みできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_cash_receipts_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- <カーソル名>
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
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入金情報データファイル情報ログ処理(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_001a03_011 -- ファイル名出力メッセージ
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                  ,gv_receipt_filename)      -- ファイル名
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
--
    -- =====================================================
    --  最後にクローズした会計期間名取得 (A-4)
    -- =====================================================
    get_last_close_period_name(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入金情報データ取得 (A-5)
    -- =====================================================
    get_cash_receipts_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入金情報データＣＳＶ作成処理 (A-6)
    -- =====================================================
    put_cash_receipts_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 正常件数の設定
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
    errbuf        OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode       OUT     VARCHAR2          --    エラーコード     #固定#
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --エラーメッセージが設定されている場合、エラー出力
    IF (lv_errmsg IS NOT NULL) THEN
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    --１行改行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
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
    fnd_file.put_line(
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
END XXCFR001A03C;
/
