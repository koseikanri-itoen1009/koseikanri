CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A14 (spec)
 * Description      : 控除消込作成API(AP支払)
 * MD.050           : 控除消込作成API(AP支払) MD050_COK_024_A14
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      初期処理(A-1)
 *  sales_dedu_get            販売控除データ抽出(A-2)
 *  insert_dedu_recon_head    控除消込ヘッダー作成(A-3)
 *  insert_dedu_num_recon     控除No別消込情報作成(A-4)
 *  insert_dedu_recon_line_ap 控除消込明細情報(AP申請)作成(A-5)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/11    1.0   Y.Nakajima       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
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
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER        DEFAULT 0;      -- 対象件数
  gn_normal_cnt    NUMBER        DEFAULT 0;      -- 正常件数
  gn_error_cnt     NUMBER        DEFAULT 0;      -- 異常件数
  gn_skip_cnt      NUMBER        DEFAULT 0;      -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
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
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A14C';                -- パッケージ名
  -- アプリケーション短縮名
  cv_msg_kbn_cok            CONSTANT VARCHAR2(5)  := 'XXCOK';                       -- アドオン：個別開発
  -- メッセージ名称
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';            -- 対象データなしエラーメッセージ
  cv_rock_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';            -- ロックエラーメッセージ
  -- 数値
  cn_zero                   CONSTANT NUMBER       := 0;                             -- 0
  cn_one                    CONSTANT NUMBER       := 1;                             -- 1
  -- 有効フラグ
  cv_enable                 CONSTANT VARCHAR2(1)  := 'Y';
  -- 言語コード
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  -- 参照タイプ
  cv_chain_code             CONSTANT VARCHAR2(50) := 'XXCMM_CHAIN_CODE';            -- 控除用チェーンコード
  cv_deduction_data_type    CONSTANT VARCHAR2(50) := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- 控除データ種類
  cv_target_data_type       CONSTANT VARCHAR2(50) := 'XXCOK1_TARGET_DATA_TYPE';     -- 対象データ種類
  --
  cv_ap                     CONSTANT VARCHAR2(4)  :=  'AP';                         -- AP
  cv_one                    CONSTANT VARCHAR2(1)  :=  '1';                          -- '1'
  cv_status_n               CONSTANT VARCHAR2(1)  :=  'N';                          -- 'N' (新規)
  -- 控除消込ヘッダ用
  cv_recon_status           CONSTANT VARCHAR2(2)  :=  'EG';                         -- 'EG'(作成中)
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_line_ap
   * Description      : 控除消込明細情報(AP申請)作成(A-5)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_line_ap(
    iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_line_ap'; -- プログラム名
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
    ln_deduction_amt      NUMBER;
    ln_deduction_tax      NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 控除No別消込情報の抽出
    SELECT   SUM(xdnr.deduction_amt)
           , SUM(xdnr.deduction_tax)
    INTO     ln_deduction_amt           -- 控除額(税抜)
           , ln_deduction_tax           -- 控除額(消費税)
    FROM   xxcok_deduction_num_recon    xdnr
    WHERE  xdnr.recon_slip_num = iv_recon_slip_num
    ;
--
    -- 控除消込明細情報(AP申請)の登録
    INSERT INTO xxcok_deduction_recon_line_ap(
      deduction_recon_line_id                     -- 控除消込明細ID
    , recon_slip_num                              -- 支払伝票番号
    , deduction_line_num                          -- 消込明細番号
    , recon_line_status                           -- 入力ステータス
    , deduction_chain_code                        -- 控除用チェーンコード
    , prev_carryover_amt                          -- 前月繰越額(税抜)
    , prev_carryover_tax                          -- 前月繰越額(消費税)
    , deduction_amt                               -- 控除額(税抜)
    , deduction_tax                               -- 控除額(消費税)
    , payment_amt                                 -- 支払額(税抜)
    , payment_tax                                 -- 支払額(消費税)
    , difference_amt                              -- 調整差額(税抜)
    , difference_tax                              -- 調整差額(消費税)
    , next_carryover_amt                          -- 翌月繰越額(税抜)
    , next_carryover_tax                          -- 翌月繰越額(消費税)
    , created_by                                  -- 作成者
    , creation_date                               -- 作成日
    , last_updated_by                             -- 最終更新者
    , last_update_date                            -- 最終更新日
    , last_update_login                           -- 最終更新ログイン
    , request_id                                  -- 要求ID
    , program_application_id                      -- コンカレント・プログラム･アプリケーションID
    , program_id                                  -- コンカレント･プログラムID
    , program_update_date                         -- プログラム更新日
    )
    VALUES(
      xxcok_deduction_recon_line_s01.nextval      -- 控除消込明細ID
    , iv_recon_slip_num                           -- 支払伝票番号
    , cn_one                                      -- 消込明細番号
    , cv_recon_status                             -- 入力ステータス
    , NULL                                        -- 控除用チェーンコード
    , cn_zero                                     -- 前月繰越額(税抜)
    , cn_zero                                     -- 前月繰越額(消費税)
    , ln_deduction_amt                            -- 控除額(税抜)
    , ln_deduction_tax                            -- 控除額(消費税)
    , cn_zero                                     -- 支払額(税抜)
    , cn_zero                                     -- 支払額(消費税)
    , ln_deduction_amt                            -- 調整差額(税抜)
    , ln_deduction_tax                            -- 調整差額(消費税)
    , cn_zero                                     -- 翌月繰越額(税抜)
    , cn_zero                                     -- 翌月繰越額(消費税)
    , cn_created_by                               -- 作成者
    , SYSDATE                                     -- 作成日
    , cn_last_updated_by                          -- 最終更新者
    , SYSDATE                                     -- 最終更新日
    , cn_last_update_login                        -- 最終更新ログイン
    , cn_request_id                               -- 要求ID
    , cn_program_application_id                   -- コンカレント・プログラム･アプリケーションID
    , cn_program_id                               -- コンカレント･プログラムID
    , SYSDATE                                     -- プログラム更新日
    )
    ;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_line_ap;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_num_recon
   * Description      : 控除No別消込情報作成(A-4)
   **********************************************************************************/
  PROCEDURE insert_dedu_num_recon(
    iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_num_recon'; -- プログラム名
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
    -- 明細インクリメント用
    deduction_line_num_cnt        xxcok_deduction_num_recon.deduction_line_num%TYPE;       -- 控除明細番号
--
    -- *** ローカル・カーソル ***
    -- 販売控除情報抽出
    CURSOR sales_dedu_cur
    IS
      SELECT  xsd.data_type                   AS data_type              -- データ種類
            , xsd.condition_no                AS condition_no           -- 控除番号
            , xsd.tax_code                    AS tax_code               -- 税コード
            , SUM(xsd.deduction_amount)       AS deduction_amount       -- 控除額
            , SUM(xsd.deduction_tax_amount)   AS deduction_tax_amount   -- 控除消費額
      FROM    xxcok_sales_deduction    xsd    -- 販売控除情報テーブル
      WHERE   xsd.recon_slip_num = iv_recon_slip_num
      GROUP BY   xsd.data_type
               , xsd.condition_no
               , xsd.tax_code
      ORDER BY   xsd.condition_no
               , xsd.tax_code
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    deduction_line_num_cnt := 0;
--
--###########################  固定部 END   ############################
--
    -- 控除No別消込情報の登録処理
    <<dedu_num_recon_ins_loop>>
    FOR sales_dedu_inline_rec IN sales_dedu_cur LOOP
      -- 控除明細番号をインクリメント
      deduction_line_num_cnt := deduction_line_num_cnt + 1;
      -- 控除No別消込情報の登録
      INSERT INTO xxcok_deduction_num_recon(
        deduction_num_recon_id                      -- 控除No別消込ID
      , recon_slip_num                              -- 支払伝票番号
      , recon_line_num                              -- 消込明細番号
      , deduction_chain_code                        -- 控除用チェーンコード
      , deduction_line_num                          -- 控除明細番号
      , data_type                                   -- データ種類
      , target_flag                                 -- 対象フラグ
      , condition_no                                -- 控除番号
      , tax_code                                    -- 消費税コード
      , prev_carryover_amt                          -- 前月繰越額(税抜)
      , prev_carryover_tax                          -- 前月繰越額(消費税)
      , deduction_amt                               -- 控除額(税抜)
      , deduction_tax                               -- 控除額(消費税)
      , carryover_pay_off_flg                       -- 繰越額全額精算フラグ
      , payment_tax_code                            -- 支払時税コード
      , payment_amt                                 -- 支払額(税抜)
      , payment_tax                                 -- 支払額(消費税)
      , difference_amt                              -- 調整差額(税抜)
      , difference_tax                              -- 調整差額(消費税)
      , next_carryover_amt                          -- 翌月繰越額(税抜)
      , next_carryover_tax                          -- 翌月繰越額(消費税)
      , remarks                                     -- 摘要
      , created_by                                  -- 作成者
      , creation_date                               -- 作成日
      , last_updated_by                             -- 最終更新者
      , last_update_date                            -- 最終更新日
      , last_update_login                           -- 最終更新ログイン
      , request_id                                  -- 要求ID
      , program_application_id                      -- コンカレント・プログラム･アプリケーションID
      , program_id                                  -- コンカレント･プログラムID
      , program_update_date                         -- プログラム更新日
      )
      VALUES(
        xxcok_deduction_num_recon_s01.nextval       -- 控除No別消込ID
      , iv_recon_slip_num                           -- 支払伝票番号
      , cn_one                                      -- 消込明細番号
      , NULL                                        -- 控除用チェーンコード
      , deduction_line_num_cnt                      -- 控除明細番号
      , sales_dedu_inline_rec.data_type             -- データ種類
      , cv_status_n                                 -- 対象フラグ
      , sales_dedu_inline_rec.condition_no          -- 控除番号
      , sales_dedu_inline_rec.tax_code              -- 消費税コード
      , cn_zero                                     -- 前月繰越額(税抜)
      , cn_zero                                     -- 前月繰越額(消費税)
      , sales_dedu_inline_rec.deduction_amount      -- 控除額(税抜)
      , sales_dedu_inline_rec.deduction_tax_amount  -- 控除額(消費税)
      , cv_enable                                   -- 繰越額全額精算フラグ
      , sales_dedu_inline_rec.tax_code              -- 支払時税コード
      , cn_zero                                     -- 支払額(税抜)
      , cn_zero                                     -- 支払額(消費税)
      , sales_dedu_inline_rec.deduction_amount      -- 調整差額(税抜)
      , sales_dedu_inline_rec.deduction_tax_amount  -- 調整差額(消費税)
      , cn_zero                                     -- 翌月繰越額(税抜)
      , cn_zero                                     -- 翌月繰越額(消費税)
      , NULL                                        -- 摘要
      , cn_created_by                               -- 作成者
      , SYSDATE                                     -- 作成日
      , cn_last_updated_by                          -- 最終更新者
      , SYSDATE                                     -- 最終更新日
      , cn_last_update_login                        -- 最終更新ログイン
      , cn_request_id                               -- 要求ID
      , cn_program_application_id                   -- コンカレント・プログラム･アプリケーションID
      , cn_program_id                               -- コンカレント･プログラムID
      , SYSDATE                                     -- プログラム更新日
      );
--
    END LOOP dedu_num_recon_ins_loop;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_num_recon;
--
  /**********************************************************************************
   * Procedure Name   : insert_dedu_recon_head
   * Description      : 控除消込ヘッダー作成(A-3)
   **********************************************************************************/
  PROCEDURE insert_dedu_recon_head(
    iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,id_target_date_end              IN     DATE              -- 対象期間(TO)
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_deduction_chain_code         IN     VARCHAR2          -- 控除用チェーンコード
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客コード
   ,iv_invoice_number               IN     VARCHAR2          -- 受領請求書番号
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,iv_recon_slip_num               IN     VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_dedu_recon_head'; -- プログラム名
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
  -- 
    INSERT INTO xxcok_deduction_recon_head(
      deduction_recon_head_id                     -- 控除消込ヘッダーID
    , recon_base_code                             -- 支払請求拠点
    , recon_slip_num                              -- 支払伝票番号 
    , recon_status                                -- 消込スタータス 
    , application_date                            -- 申請日
    , approval_date                               -- 承認日
    , cancellation_date                           -- 取消日
    , recon_due_date                              -- 支払予定日
    , gl_date                                     -- GL記帳日
    , target_date_end                             -- 対象期間(TO)
    , interface_div                               -- 連携先
    , payee_code                                  -- 支払先コード
    , corp_code                                   -- 企業コード
    , deduction_chain_code                        -- 控除用チェーンコード
    , cust_code                                   -- 顧客コード
    , invoice_number                              -- 問屋請求書番号
    , target_data_type                            -- 対象データ種類
    , applicant                                   -- 申請者
    , approver                                    -- 承認者
    , ap_ar_if_flag                               -- AP/AR連携フラグ
    , gl_if_flag                                  -- 消込GL連携フラグ
    , terms_name                                  -- 支払条件
    , invoice_date                                -- 請求書日付
    , created_by                                  -- 作成者
    , creation_date                               -- 作成日
    , last_updated_by                             -- 最終更新者
    , last_update_date                            -- 最終更新日
    , last_update_login                           -- 最終更新ログイン
    , request_id                                  -- 要求ID
    , program_application_id                      -- コンカレント・プログラム･アプリケーションID
    , program_id                                  -- コンカレント･プログラムID
    , program_update_date                         -- プログラム更新日
    )
    VALUES(
      xxcok_deduction_recon_head_s01.nextval      -- 控除消込ヘッダーID
    , iv_recon_base_code                          -- 支払請求拠点
    , iv_recon_slip_num                           -- 支払伝票番号 
    , cv_recon_status                             -- 消込スタータス 
    , NULL                                        -- 申請日
    , NULL                                        -- 承認日
    , NULL                                        -- 取消日
    , id_recon_due_date                           -- 支払予定日
    , id_gl_date                                  -- GL記帳日
    , id_target_date_end                          -- 対象期間(TO)
    , cv_ap                                       -- 連携先
    , iv_payee_code                               -- 支払先コード
    , iv_corp_code                                -- 企業コード
    , iv_deduction_chain_code                     -- 控除用チェーンコード
    , iv_cust_code                                -- 顧客コード
    , iv_invoice_number                           -- 問屋請求書番号
    , iv_target_data_type                         -- 対象データ種類
    , xxcok_common_pkg.get_emp_code_f(cn_created_by)
                                                  -- 申請者
    , NULL                                        -- 承認者
    , cv_status_n                                 -- AP/AR連携フラグ
    , cv_status_n                                 -- 消込GL連携フラグ
    , iv_terms_name                               -- 支払条件
    , id_invoice_date                             -- 請求書日付
    , cn_created_by                               -- 作成者
    , SYSDATE                                     -- 作成日
    , cn_last_updated_by                          -- 最終更新者
    , SYSDATE                                     -- 最終更新日
    , cn_last_update_login                        -- 最終更新ログイン
    , cn_request_id                               -- 要求ID
    , cn_program_application_id                   -- コンカレント・プログラム･アプリケーションID
    , cn_program_id                               -- コンカレント･プログラムID
    , SYSDATE                                     -- プログラム更新日
    );
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_dedu_recon_head;
--
  /**********************************************************************************
   * Procedure Name   : sales_dedu_get
   * Description      : 販売控除データ抽出(A-2)
   **********************************************************************************/
  PROCEDURE sales_dedu_get(
    id_target_date_end              IN     DATE       -- 対象期間(TO)
   ,iv_corp_code                    IN     VARCHAR2   -- 企業コード
   ,iv_deduction_chain_code         IN     VARCHAR2   -- 控除用チェーンコード
   ,iv_cust_code                    IN     VARCHAR2   -- 顧客コード
   ,iv_target_data_type             IN     VARCHAR2   -- 対象データ種類
   ,iv_recon_slip_num               IN     VARCHAR2   -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2   -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sales_dedu_get'; -- プログラム名
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
    result_count  NUMBER;
--
    -- *** ローカルカーソル ***
    CURSOR l_recon_slip_num_up_cur
    IS
      WITH 
        target_data_type  AS
        ( SELECT  /*+ MATERIALIZED */
                  flvd.lookup_code  AS  lookup_code
          FROM    fnd_lookup_values flvd,                 -- 控除データ種類
                  fnd_lookup_values flvt                  -- 対象データ種類
          WHERE   flvt.lookup_type  =     cv_target_data_type
          AND     flvt.description  =     iv_target_data_type
          AND     flvt.language     =     ct_lang
          AND     flvt.enabled_flag =     cv_enable
          AND     flvd.lookup_type  =     cv_deduction_data_type
          AND     flvd.lookup_code  LIKE  flvt.attribute1
          AND     flvd.language     =     ct_lang
          AND     flvd.enabled_flag =     cv_enable
          AND     flvd.attribute3   =     cv_ap                   )
      SELECT  xsd.sales_deduction_id
      FROM    xxcok_sales_deduction     xsd
      WHERE   xsd.sales_deduction_id    IN
              ( SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IN
                        ( SELECT  xca.customer_code
                          FROM    fnd_lookup_values       flv,
                                  xxcmm_cust_accounts     xca
                          WHERE ( xca.customer_code       =   iv_cust_code            or  iv_cust_code            IS  NULL )
                          AND   ( xca.intro_chain_code2   =   iv_deduction_chain_code or  iv_deduction_chain_code IS  NULL )
                          AND     flv.lookup_type(+)      =   cv_chain_code
                          AND     flv.lookup_code(+)      =   xca.intro_chain_code2
                          AND     flv.language(+)         =   ct_lang
                          AND     flv.enabled_flag(+)     =   cv_enable
                          AND   ( flv.attribute1          =   iv_corp_code            or  iv_corp_code            IS  NULL )  )
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IN
                        ( SELECT  flv.lookup_code
                          FROM    fnd_lookup_values   flv
                          WHERE   flv.lookup_type     =   cv_chain_code
                          AND     flv.language        =   ct_lang
                          AND     flv.enabled_flag    =   cv_enable
                          AND   ( flv.lookup_code     =   iv_deduction_chain_code     OR  flv.attribute1          =   iv_corp_code )  )
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n
                UNION ALL
                SELECT  /*+ INDEX(xsd xxcok_sales_deduction_n08) */
                        xsd.sales_deduction_id      AS  sales_deduction_id
                FROM    xxcok_sales_deduction       xsd
                WHERE   xsd.customer_code_to        IS  NULL
                AND     xsd.deduction_chain_code    IS  NULL
                AND     xsd.corp_code               =   iv_corp_code
                AND     xsd.recon_slip_num          IS  NULL
                AND     xsd.record_date             <=  id_target_date_end
                AND     xsd.data_type               IN  ( SELECT tdt.lookup_code FROM target_data_type tdt )
                AND   ( xsd.report_decision_flag IS NULL OR xsd.report_decision_flag = cv_one )
                AND     xsd.status                  =   cv_status_n                                           )
      FOR UPDATE  NOWAIT;
--
    recon_slip_num_up_rec          l_recon_slip_num_up_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode   := cv_status_normal;
    result_count := 0;
--
--###########################  固定部 END   ############################
--
    -- 販売控除情報更新
    FOR recon_slip_num_up_rec IN l_recon_slip_num_up_cur LOOP
      UPDATE  xxcok_sales_deduction       xsd
      SET     xsd.recon_slip_num            = iv_recon_slip_num         , -- 支払伝票番号
              xsd.carry_payment_slip_num    = iv_recon_slip_num         , -- 繰越時支払伝票番号
              xsd.last_updated_by           = cn_last_updated_by        ,
              xsd.last_update_date          = SYSDATE                   ,
              xsd.last_update_login         = cn_last_update_login      ,
              xsd.request_id                = cn_request_id             ,
              xsd.program_application_id    = cn_program_application_id ,
              xsd.program_id                = cn_program_id             ,
              xsd.program_update_date       = SYSDATE
      WHERE  xsd.sales_deduction_id      = recon_slip_num_up_rec.sales_deduction_id
      ;
      -- 実行結果件数を取得
      result_count := result_count + 1;
    --
    END LOOP;
    --
--
  -- 対象件数が０件の場合終了処理
    IF result_count = 0 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_msg_kbn_cok
                     ,iv_name         =>  cv_data_get_msg  -- 対象データなしエラーメッセージ
                   );
      RAISE global_api_warn_expt;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      -- ロックエラーメッセージ
      ov_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cok
                                            ,cv_rock_err_msg
                                             );
      ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( l_recon_slip_num_up_cur%ISOPEN ) THEN
        CLOSE l_recon_slip_num_up_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END sales_dedu_get;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   **********************************************************************************/
  PROCEDURE init(
    ov_recon_slip_num     OUT  VARCHAR2   --   支払伝票番号
   ,ov_errbuf             OUT  VARCHAR2   --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT  VARCHAR2   --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT  VARCHAR2   --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
      lv_recon_slip_num         VARCHAR2(20);    -- 支払伝票番号
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 支払伝票番号取得
    lv_recon_slip_num := xxcok_deduction_slip_num_s01.nextval;
    --
    ov_recon_slip_num := TO_CHAR(lv_recon_slip_num,'FM0000000000');
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,id_target_date_end              IN     DATE              -- 対象期間(TO)
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_deduction_chain_code         IN     VARCHAR2          -- 控除用チェーンコード
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客コード
   ,iv_invoice_number               IN     VARCHAR2          -- 受領請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
   ,ov_recon_slip_num               OUT    VARCHAR2          -- 支払伝票番号
   ,ov_errbuf                       OUT    VARCHAR2          -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2          -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2          -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_recon_slip_num  VARCHAR2(20); -- 支払伝票番号
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
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_error_cnt         := 0; -- エラー件数
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       lv_recon_slip_num -- 支払伝票番号ID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    ov_recon_slip_num := lv_recon_slip_num;
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．販売控除データ抽出
    -- ============================================
    sales_dedu_get(
       id_target_date_end     -- 対象期間(TO)
      ,iv_corp_code           -- 企業コード
      ,iv_deduction_chain_code-- 控除用チェーンコード
      ,iv_cust_code           -- 顧客コード
      ,iv_target_data_type    -- 対象データ種類
      ,lv_recon_slip_num      -- 支払伝票番号
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3． 控除消込ヘッダー作成
    -- ============================================
    insert_dedu_recon_head(
       iv_recon_base_code     -- 支払請求拠点
      ,id_recon_due_date      -- 支払予定日
      ,id_gl_date             -- GL記帳日
      ,id_target_date_end     -- 対象期間(TO)
      ,id_invoice_date        -- 請求書日付
      ,iv_payee_code          -- 支払先コード
      ,iv_corp_code           -- 企業コード
      ,iv_deduction_chain_code-- 控除用チェーンコード
      ,iv_cust_code           -- 顧客コード
      ,iv_invoice_number      -- 受領請求書番号
      ,iv_target_data_type    -- 対象データ種類
      ,iv_terms_name          -- 支払条件
      ,lv_recon_slip_num      -- 支払伝票番号
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．控除No別消込情報作成
    -- ============================================
    insert_dedu_num_recon(
       lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5．控除消込明細情報(AP申請)作成
    -- ============================================
    insert_dedu_recon_line_ap(
       lv_recon_slip_num   -- 支払伝票番号
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- 支払伝票番号
   ,iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,id_target_date_end              IN     DATE              -- 対象期間(TO)
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_deduction_chain_code         IN     VARCHAR2          -- 控除用チェーンコード
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客コード
   ,iv_invoice_number               IN     VARCHAR2          -- 受領請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  :=  'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)   :=  'XXCCP';            -- アドオン：共通・IF領域
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    lv_recon_slip_num  VARCHAR2(20);    -- 支払伝票番号
    --
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_recon_base_code        -- 支払請求拠点
      ,id_recon_due_date         -- 支払予定日
      ,id_gl_date                -- GL記帳日
      ,id_target_date_end        -- 対象期間(TO)
      ,id_invoice_date           -- 請求書日付
      ,iv_payee_code             -- 支払先コード
      ,iv_corp_code              -- 企業コード
      ,iv_deduction_chain_code   -- 控除用チェーンコード
      ,iv_cust_code              -- 顧客コード
      ,iv_invoice_number         -- 受領請求書番号
      ,iv_terms_name             -- 支払条件
      ,iv_target_data_type       -- 対象データ種類
      ,lv_recon_slip_num         -- 支払伝票番号
      ,lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                -- リターン・コード             --# 固定 #
      ,lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- A-1で採番した支払い伝票番号を反映
    ov_recon_slip_num := lv_recon_slip_num;
    -- 終了ステータスを反映
    retcode           := lv_retcode;
--
    --  正常終了以外の場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      errbuf := lv_errbuf;
      -- ロールバックを発行
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf      :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode     :=  cv_status_error;
      gv_out_msg  :=  0;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
END XXCOK024A14C;
/
