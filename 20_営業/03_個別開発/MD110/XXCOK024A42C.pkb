CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A42C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A42C(body)
 * Description      : 入金相殺自動消込処理
 * MD.050           : MD050_COK_024_A42_入金相殺自動消込処理
 *
 * Version          : 1.2
 *
 * Program List
 * ------------------------  -------------------------------------------------------------
 *  Name                     Description
 * ------------------------- --------------------------------------------------------------
 *  init                     初期処理(A-1)
 *  get_receivable_slips_key AR部門入力（未消込）のキー情報取得(A-2)
 *                           販売控除情報（未消込）取得(A-3)
 *                           AR部門入力（未消込）の明細情報取得(A-4)
 *                           AR部門入力更新(A-6)
 *                           販売控除データ更新(A-7)
 *                           控除消込ヘッダー情報作成(A-8)
 *  ins_sales_deduction      差額調整控除データ作成(A-5)
 *  submain                  メイン処理プロシージャ
 *  main                     実行ファイル登録プロシージャ
 *                           終了処理(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2022/12/13    1.0   M.Akachi         新規作成 E_本稼動_18519 入金相殺の消込（AR連携）
 *  2023/07/26    1.1   M.Akachi         E_本稼動_19275 入金相殺消込の14番顧客のチェック
 *                                       E_本稼動_19333 入金相殺消込におけるEDI実績振替控除の消込不良
 *  2024/03/12    1.2   SCSK Y.Koh       [E_本稼動_19496] グループ会社統合対応
 *
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  固定部 END   ##################################
  --
  --#######################  固定グローバル変数宣言部 START   #######################
  --
  gv_out_msg    VARCHAR2(2000) DEFAULT NULL;
  gn_target_cnt NUMBER   := 0; -- 対象件数
  gn_normal_cnt NUMBER   := 0; -- 正常件数
  gn_error_cnt  NUMBER   := 0; -- エラー件数
  gn_warn_cnt   NUMBER   := 0; -- スキップ件数
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  -- *** ロック取得エラー例外 ***
  global_lock_failure_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_lock_failure_expt, -54 );
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOK024A42C';                      -- パッケージ名
  cv_appl_short_name_xxcok  CONSTANT VARCHAR2(10)  := 'XXCOK';                             -- アプリケーション短縮名
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                 -- フラグY
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                 -- フラグOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                 -- フラグON
  cv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                        -- 日付書式
-- Ver1.1 Add Start
  cv_date_format2           CONSTANT VARCHAR2(10)  := 'YYYYMMDD';                          -- 日付書式
-- Ver1.1 Add End
  cv_year_format            CONSTANT VARCHAR2(10)  := 'YYYY';                              -- 日付書式(年)
  cv_month_format           CONSTANT VARCHAR2(10)  := 'MM';                                -- 日付書式(日)
  ct_deduction_data_type    CONSTANT fnd_lookup_values.lookup_type%TYPE  := 'XXCOK1_DEDUCTION_DATA_TYPE';  -- 控除データ種類
  cv_flag_d                 CONSTANT VARCHAR2(1)   := 'D';                                 -- 作成元区分(差額調整)
  cv_flag_v                 CONSTANT VARCHAR2(1)   := 'V';                                 -- 作成元区分 売上実績振替（振替割合）
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                                 -- ステータス(新規) / 取消フラグ(未取消)
  cv_flag_o                 CONSTANT VARCHAR2(1)   := 'O';                                 -- 作成元区分(繰越調整) / GL連携フラグ(対象外) 
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                                 -- 入金相殺消込ステータス(Y：消込済)
-- 2024/03/12 Ver1.2 DEL Start
--  cv_slip_type_80300        CONSTANT VARCHAR2(5)   := '80300';                             -- 伝票種別:入金相殺
-- 2024/03/12 Ver1.2 DEL End
  cv_ar_status_appr         CONSTANT VARCHAR2(2)   := '80';                                -- 承認済
  cv_lang                   CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );                  -- 言語
  --
  -- メッセージコード
  cv_msg_cok_00028          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_cok_00003          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_msg_cok_10732          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10732';  -- ロックエラーメッセージ
  cv_msg_cok_10857          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10857';  -- 対象控除データなしメッセージ
  cv_msg_cok_10858          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10858';  -- 支払条件名エラーメッセージ
  --
  --メッセージ文字列
  ct_msg_cok_10855          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10855'; -- 販売控除情報(メッセージ文字列)
  ct_msg_cok_10856          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOK1-10856'; -- AR部門入力明細(メッセージ文字列)
  -- トークンコード
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';
  cv_tkn_table              CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_receivable_num     CONSTANT VARCHAR2(20) := 'RECEIVABLE_NUM';
  cv_tkn_line_number        CONSTANT VARCHAR2(20) := 'LINE_NUMBER';
  cv_tkn_terms_name         CONSTANT VARCHAR2(20) := 'TERMS_NAME';
  --
  --プロファイル
  cv_standard_date             CONSTANT VARCHAR2(100) := 'XXCOK1_DEDU_OFFSET_FROM_DATE';  -- 入金相殺伝票抽出基準日
  cv_trans_type_name_var_cons  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOK1_RA_TRX_TYPE_VARIABLE_CONS'; -- 取引タイプ名
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date                 DATE     DEFAULT NULL;   -- 業務日付
  gd_before_month_last_date    DATE     DEFAULT NULL;   -- 業務日付の前月末日
  gd_standard_date             DATE     DEFAULT NULL;   -- 入金相殺伝票抽出基準日
  gv_trans_type_name_var_cons  xx03_receivable_slips.trans_type_name%TYPE;  -- 変動対価相殺
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_token_value  VARCHAR2(100)  DEFAULT NULL; -- トークン名
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    --
    --===============================
    --ローカル例外
    --===============================
    profile_expt  EXCEPTION;  -- プロファイル取得エラー
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ======================
    -- 業務日付チェック
    -- ======================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    IF ( gd_proc_date IS NULL ) THEN
      -- 業務日付の取得に失敗した場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name_xxcok  -- アプリケーション短縮名
                    ,iv_name       => cv_msg_cok_00028           -- メッセージコード
                    );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- 業務日付の前月末日
    gd_before_month_last_date := TRUNC( LAST_DAY( ADD_MONTHS( gd_proc_date, -1 ) ) );
    --
    --===================================
    -- XXCOK:入金相殺伝票抽出基準日の取得
    --===================================
    gd_standard_date := TO_DATE( FND_PROFILE.VALUE( cv_standard_date ), cv_date_format ); -- 入金相殺伝票抽出基準日
    --
    IF( gd_standard_date IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_standard_date );
      RAISE profile_expt;
    END IF;
    --
    --====================================
    -- XXCOK:取引タイプ_変動対価相殺の取得
    --====================================
    gv_trans_type_name_var_cons := FND_PROFILE.VALUE( cv_trans_type_name_var_cons );
    --
    IF ( gv_trans_type_name_var_cons IS NULL ) THEN
      lv_token_value := cv_trans_type_name_var_cons;
      RAISE profile_expt;
    END IF;
--
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
        -- *** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      cv_appl_short_name_xxcok
                    , cv_msg_cok_00003
                    , cv_tkn_profile
                    , lv_token_value
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END init;
  --
  /**********************************************************************************
   * Procedure Name   : ins_sales_deduction
   * Description      : 差額調整控除データ作成(A-5)
   ***********************************************************************************/
  PROCEDURE ins_sales_deduction(
     in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- 顧客コード
    ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 入金相殺消込用請求内容
    ,in_deduction_amt_sum      IN xxcok_sales_deduction.deduction_amount%TYPE          -- 控除額合計
    ,in_deduction_tax_amt_sum  IN xxcok_sales_deduction.deduction_tax_amount%TYPE      -- 控除税額合計
    ,id_derivation_record_date IN DATE                                                 -- 対象計上日導出ロジックで導出した日付
    ,iv_receivable_num         IN xx03_receivable_slips.receivable_num%TYPE            -- 対象レコードの伝票番号
    ,iv_line_number            IN xx03_receivable_slips_line.line_number%TYPE          -- 対象レコードの明細番号
    ,iv_receivable_num_1       IN xx03_receivable_slips.receivable_num%TYPE            -- 1レコード目の伝票番号
    ,iv_line_number_1          IN xx03_receivable_slips_line.line_number%TYPE          -- 1レコード目の明細番号
    ,ln_difference_amt         IN NUMBER                                               -- 差額
    ,ln_difference_tax_amt     IN NUMBER                                               -- 税差額
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                     -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                     -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT    VARCHAR2(100) := 'ins_sales_deduction'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- *** ローカル変数 ***
    l_xxcok_sales_deduction_rec xxcok_sales_deduction%ROWTYPE;                    -- 販売控除情報
--
    lt_difference_amt_rest      xxcok_sales_deduction.deduction_amount%TYPE;      -- 調整差額(税抜)_残額
    lt_difference_tax_rest      xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- 調整差額(消費税)_残額
    --
    -- *** ローカル・カーソル ( 販売控除情報（未消込）)***
    CURSOR xxcok_sales_deduction_s_cur(
        in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- A-2-1で取得した顧客コード
       ,iv_receivable_num_1       IN xx03_receivable_slips.receivable_num%TYPE            -- A-4-1で取得した1レコード目の伝票番号
       ,iv_line_number_1          IN xx03_receivable_slips_line.line_number%TYPE          -- A-4-1で取得した1レコード目の明細番号
       ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- A-2-1で取得した入金相殺消込用請求内容
       ,id_derivation_record_date IN DATE                                                 -- 対象計上日導出ロジックで導出した日付
    )
    IS
      SELECT  /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
              xsd.customer_code_to          AS customer_code_to        -- 振替先顧客コード
             ,xsd.deduction_chain_code      AS deduction_chain_code    -- 控除用チェーンコード
             ,xsd.corp_code                 AS corp_code               -- 企業コード
             ,xsd.condition_id              AS condition_id            -- 控除条件ID
             ,xsd.condition_no              AS condition_no            -- 控除番号
             ,xsd.data_type                 AS data_type               -- データ種類
             ,xsd.item_code                 AS item_code               -- 品目コード
             ,xsd.tax_code                  AS tax_code                -- 税コード
             ,CASE  
               WHEN  xsd.source_category IN  ( 'F', 'U' ) THEN
                     xsd.base_code_to
               ELSE
                     xca.past_sale_base_code
              END                           AS recon_base_code         -- 消込時計上拠点
             ,SUM(xsd.deduction_amount)     AS deduction_amount        -- 控除額合計
             ,SUM(xsd.deduction_tax_amount) AS deduction_tax_amount    -- 控除税額合計
      FROM    xxcok_sales_deduction xsd                                -- 販売控除情報
             ,xxcmm_cust_accounts   xca                                -- 顧客追加情報
      WHERE
      ( xsd.recon_slip_num IS NULL OR xsd.recon_slip_num = iv_receivable_num_1 || '-' || iv_line_number_1 )  -- 支払伝票番号
      AND xsd.status = cv_flag_n                                                            -- ステータス:N(新規)
      AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number     -- 振替元顧客コード
                                      FROM   xxcfr_cust_hierarchy_v xchv
                                      WHERE  xchv.cash_account_number = in_account_number
                                      OR     xchv.bill_account_number = in_account_number
                                      OR     xchv.ship_account_number = in_account_number )
      AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                        -- データ種類
                                      FROM   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = ct_deduction_data_type
                                      AND    flv.language     = cv_lang
                                      AND    flv.enabled_flag = cv_flag_yes
                                      AND    flv.attribute14 = iv_slip_line_type_name )
      AND xsd.source_category <> cv_flag_d                                                    -- 作成元区分 <> D:差額調整
      AND xsd.record_date <= id_derivation_record_date                                        -- 対象計上日導出ロジックで導出した日付
-- Ver1.1 Mod Start
--      AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )     -- (作成元区分 = V:売上実績振替（振替割合）AND 速報確定フラグ:1(実績振替確定済み)
--            OR                                                                                --  OR
--            ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )       --  作成元区分 <> V:売上実績振替（振替割合）AND 速報確定フラグ IS NULL)
      AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )       -- 速報確定フラグ:1(実績振替確定済み)またはNULL
-- Ver1.1 Mod End
      AND xsd.customer_code_to = xca.customer_code
      GROUP BY  xsd.customer_code_to      -- 振替先顧客コード
               ,xsd.deduction_chain_code  -- 控除用チェーンコード
               ,xsd.corp_code             -- 企業コード
               ,xsd.condition_id          -- 控除条件ID
               ,xsd.condition_no          -- 控除番号
               ,xsd.data_type             -- データ種類
               ,xsd.item_code             -- 品目コード
               ,xsd.tax_code              -- 税コード
               ,CASE  
                  WHEN  xsd.source_category IN  ( 'F', 'U' ) THEN
                        xsd.base_code_to
                  ELSE
                        xca.past_sale_base_code
                END     
      ORDER BY  xsd.customer_code_to
               ,xsd.item_code
      ;
--
    TYPE xxcok_sales_deduction_s_ttype  IS TABLE OF xxcok_sales_deduction_s_cur%ROWTYPE;
    xxcok_sales_deduction_s_tab         xxcok_sales_deduction_s_ttype;
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
    -- 変数初期化
    lt_difference_amt_rest  :=  ln_difference_amt;
    lt_difference_tax_rest  :=  ln_difference_tax_amt;
--
    OPEN  xxcok_sales_deduction_s_cur( in_account_number, iv_receivable_num_1, iv_line_number_1, iv_slip_line_type_name, id_derivation_record_date );
    FETCH xxcok_sales_deduction_s_cur BULK COLLECT INTO xxcok_sales_deduction_s_tab;
    CLOSE xxcok_sales_deduction_s_cur;
--
    FOR i IN 1..xxcok_sales_deduction_s_tab.COUNT LOOP
      -- 最終レコードの場合は、調整差額_残、調整差額(消費税)_残を設定
      IF i = xxcok_sales_deduction_s_tab.COUNT THEN
        l_xxcok_sales_deduction_rec.deduction_amount         :=  lt_difference_amt_rest;
        l_xxcok_sales_deduction_rec.deduction_tax_amount     :=  lt_difference_tax_rest;
      ELSE
        -- 控除額合計が0の場合は、控除額 = 0 を設定
        IF in_deduction_amt_sum = 0 THEN
          l_xxcok_sales_deduction_rec.deduction_amount       :=  0;
        ELSE
          l_xxcok_sales_deduction_rec.deduction_amount       :=  ROUND( ln_difference_amt
                                                                        * xxcok_sales_deduction_s_tab(i).deduction_amount
                                                                        / in_deduction_amt_sum );
        END IF;
        -- 控除税額合計が0の場合は、控除税額 = 0を設定
        IF in_deduction_tax_amt_sum = 0 THEN
          l_xxcok_sales_deduction_rec.deduction_tax_amount   :=  0;
        ELSE
          l_xxcok_sales_deduction_rec.deduction_tax_amount   :=  ROUND( ln_difference_tax_amt
                                                                        * xxcok_sales_deduction_s_tab(i).deduction_tax_amount
                                                                        / in_deduction_tax_amt_sum );
        END IF;
      END IF;
--
      IF  l_xxcok_sales_deduction_rec.deduction_amount  !=  0 OR  l_xxcok_sales_deduction_rec.deduction_tax_amount  !=0 THEN
        l_xxcok_sales_deduction_rec.sales_deduction_id       :=  xxcok_sales_deduction_s01.NEXTVAL                   ;   -- 販売控除ID
        l_xxcok_sales_deduction_rec.base_code_from           :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替元拠点
        l_xxcok_sales_deduction_rec.base_code_to             :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 振替先拠点
        l_xxcok_sales_deduction_rec.customer_code_from       :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替元顧客コード
        l_xxcok_sales_deduction_rec.customer_code_to         :=  xxcok_sales_deduction_s_tab(i).customer_code_to     ;   -- 振替先顧客コード
        l_xxcok_sales_deduction_rec.deduction_chain_code     :=  xxcok_sales_deduction_s_tab(i).deduction_chain_code ;   -- 控除用チェーンコード
        l_xxcok_sales_deduction_rec.corp_code                :=  xxcok_sales_deduction_s_tab(i).corp_code            ;   -- 企業コード
        l_xxcok_sales_deduction_rec.record_date              :=  id_derivation_record_date                           ;   -- 計上日
        l_xxcok_sales_deduction_rec.source_category          :=  cv_flag_d                                           ;   -- 作成元区分
        l_xxcok_sales_deduction_rec.source_line_id           :=  NULL      	                                         ;   -- 作成元明細ID
        l_xxcok_sales_deduction_rec.condition_id             :=  xxcok_sales_deduction_s_tab(i).condition_id         ;   -- 控除条件ID
        l_xxcok_sales_deduction_rec.condition_no             :=  xxcok_sales_deduction_s_tab(i).condition_no         ;   -- 控除番号
        l_xxcok_sales_deduction_rec.condition_line_id        :=  NULL                                                ;   -- 控除詳細ID
        l_xxcok_sales_deduction_rec.data_type                :=  xxcok_sales_deduction_s_tab(i).data_type            ;   -- データ種類
        l_xxcok_sales_deduction_rec.status                   :=  cv_flag_n                                           ;   -- ステータス
        l_xxcok_sales_deduction_rec.item_code                :=  xxcok_sales_deduction_s_tab(i).item_code            ;   -- 品目コード
        l_xxcok_sales_deduction_rec.sales_uom_code           :=  NULL                                                ;   -- 販売単位
        l_xxcok_sales_deduction_rec.sales_unit_price         :=  NULL                                                ;   -- 販売単価
        l_xxcok_sales_deduction_rec.sales_quantity           :=  NULL                                                ;   -- 販売数量
        l_xxcok_sales_deduction_rec.sale_pure_amount         :=  NULL                                                ;   -- 売上本体金額
        l_xxcok_sales_deduction_rec.sale_tax_amount          :=  NULL                                                ;   -- 売上消費税額
        l_xxcok_sales_deduction_rec.deduction_uom_code       :=  NULL                                                ;   -- 控除単位
        l_xxcok_sales_deduction_rec.deduction_unit_price     :=  NULL                                                ;   -- 控除単価
        l_xxcok_sales_deduction_rec.deduction_quantity       :=  NULL                                                ;   -- 控除数量
--      l_xxcok_sales_deduction_rec.deduction_amount         :=  (上記で算出済)                                      ;   -- 控除額
        l_xxcok_sales_deduction_rec.compensation             :=  NULL                                                ;   -- 補填
        l_xxcok_sales_deduction_rec.margin                   :=  NULL                                                ;   -- 問屋マージン
        l_xxcok_sales_deduction_rec.sales_promotion_expenses :=  NULL                                                ;   -- 拡売
        l_xxcok_sales_deduction_rec.margin_reduction         :=  NULL                                                ;   -- 問屋マージン減額
        l_xxcok_sales_deduction_rec.tax_code                 :=  xxcok_sales_deduction_s_tab(i).tax_code             ;   -- 税コード
        l_xxcok_sales_deduction_rec.tax_rate                 :=  NULL                                                ;   -- 税率
        l_xxcok_sales_deduction_rec.recon_tax_code           :=  xxcok_sales_deduction_s_tab(i).tax_code             ;   -- 消込時税コード
        l_xxcok_sales_deduction_rec.recon_tax_rate           :=  NULL                                                ;   -- 消込時税率
--      l_xxcok_sales_deduction_rec.deduction_tax_amount     :=  (上記で算出済)                                      ;   -- 控除税額
        l_xxcok_sales_deduction_rec.remarks                  :=  NULL                                                ;   -- 備考
        l_xxcok_sales_deduction_rec.application_no           :=  NULL                                                ;   -- 申請書No.
        l_xxcok_sales_deduction_rec.gl_if_flag               :=  cv_flag_o                                           ;   -- GL連携フラグ
        l_xxcok_sales_deduction_rec.gl_base_code             :=  NULL                                                ;   -- GL計上拠点
        l_xxcok_sales_deduction_rec.gl_date                  :=  NULL                                                ;   -- GL記帳日
        l_xxcok_sales_deduction_rec.recovery_date            :=  NULL                                                ;   -- リカバリデータ追加時日付
        l_xxcok_sales_deduction_rec.recovery_add_request_id  :=  NULL                                                ;   -- リカバリデータ追加時要求ID
        l_xxcok_sales_deduction_rec.recovery_del_date        :=  NULL                                                ;   -- リカバリデータ削除時日付
        l_xxcok_sales_deduction_rec.recovery_del_request_id  :=  NULL                                                ;   -- リカバリデータ削除時要求ID
        l_xxcok_sales_deduction_rec.cancel_flag              :=  cv_flag_n                                           ;   -- 取消フラグ
        l_xxcok_sales_deduction_rec.cancel_base_code         :=  NULL                                                ;   -- 取消時計上拠点
        l_xxcok_sales_deduction_rec.cancel_gl_date           :=  NULL                                                ;   -- 取消GL記帳日
        l_xxcok_sales_deduction_rec.cancel_user              :=  NULL                                                ;   -- 取消実施ユーザ
        l_xxcok_sales_deduction_rec.recon_base_code          :=  xxcok_sales_deduction_s_tab(i).recon_base_code      ;   -- 消込時計上拠点
        l_xxcok_sales_deduction_rec.recon_slip_num           :=  iv_receivable_num || '-' || iv_line_number          ;   -- 支払伝票番号
        l_xxcok_sales_deduction_rec.carry_payment_slip_num   :=  iv_receivable_num || '-' || iv_line_number          ;   -- 繰越時支払伝票番号
        l_xxcok_sales_deduction_rec.report_decision_flag     :=  NULL                                                ;   -- 速報確定フラグ
        l_xxcok_sales_deduction_rec.gl_interface_id          :=  NULL                                                ;   -- GL連携ID
        l_xxcok_sales_deduction_rec.cancel_gl_interface_id   :=  NULL                                                ;   -- 取消GL連携ID
        l_xxcok_sales_deduction_rec.created_by               :=  cn_created_by                                       ;   -- 作成者
        l_xxcok_sales_deduction_rec.creation_date            :=  cd_creation_date                                    ;   -- 作成日
        l_xxcok_sales_deduction_rec.last_updated_by          :=  cn_last_updated_by                                  ;   -- 最終更新者
        l_xxcok_sales_deduction_rec.last_update_date         :=  cd_last_update_date                                 ;   -- 最終更新日
        l_xxcok_sales_deduction_rec.last_update_login        :=  cn_last_update_login                                ;   -- 最終更新ログイン
        l_xxcok_sales_deduction_rec.request_id               :=  cn_request_id                                       ;   -- 要求ID
        l_xxcok_sales_deduction_rec.program_application_id   :=  cn_program_application_id                           ;   -- コンカレント・プログラム・アプリケーションID
        l_xxcok_sales_deduction_rec.program_id               :=  cn_program_id                                       ;   -- コンカレント・プログラムID
        l_xxcok_sales_deduction_rec.program_update_date      :=  cd_program_update_date                              ;   -- プログラム更新日
--
        INSERT  INTO  xxcok_sales_deduction VALUES  l_xxcok_sales_deduction_rec;
--
        lt_difference_amt_rest  :=  lt_difference_amt_rest  - l_xxcok_sales_deduction_rec.deduction_amount;
        lt_difference_tax_rest  :=  lt_difference_tax_rest  - l_xxcok_sales_deduction_rec.deduction_tax_amount;
      END IF;
    END LOOP;
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END ins_sales_deduction;
  --
   /**********************************************************************************
   * Procedure Name   : get_receivable_slips_key
   * Description      : AR部門入力（未消込）のキー情報取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_receivable_slips_key(
     ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_receivable_slips_key'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
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
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル (AR部門入力ロック情報)***
    CURSOR receivable_slips_lock_cur
    IS
       SELECT xrsl.receivable_line_id  AS receivable_line_id
       FROM xx03_receivable_slips xrs1                                      -- AR部門入力
           ,xx03_receivable_slips_line xrsl                                 -- AR部門入力明細
           ,ar_memo_lines_vl amlv                                           -- メモ明細
       WHERE
       xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--       AND xrs1.slip_type = cv_slip_type_80300                              -- 伝票種別:80300(入金相殺)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
       AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- 取引タイプ名(変動対価相殺)
--       AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- 取引タイプ名(変動対価相殺)
-- 2024/03/12 Ver1.2 MOD End
       AND xrsl.slip_line_type_name = amlv.name                             -- 請求内容
       AND amlv.attribute3 IS NOT NULL                                      -- メモ明細.入金相殺消込用請求内容に値あり
       AND xrs1.wf_status = cv_ar_status_appr                               -- ステータス:80(承認済)
       AND NOT EXISTS ( SELECT *                                            -- 伝票取消済みは除外
                        FROM   xx03_receivable_slips xrs2
                        WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR部門入力.伝票番号= AR部門入力2.修正元伝票番号
                        AND    xrs2.wf_status = cv_ar_status_appr )         -- 部門入力2.ステータス = 80(承認済)
       AND xrs1.orig_invoice_num IS NULL                                    -- 取消伝票は抽出対象外
       AND xrsl.attribute8 IS NULL                                          -- 入金相殺消込ステータス(未消込)
       AND xrs1.gl_date >= gd_standard_date
       AND xrs1.gl_date <= gd_before_month_last_date
       FOR UPDATE OF xrsl.receivable_line_id NOWAIT
       ;
     receivable_slips_line_lock_rec         receivable_slips_lock_cur%ROWTYPE;
--
    -- *** ローカル・カーソル (AR部門入力（未消込）のキー情報)***
    CURSOR receivable_slips_key_cur
    IS
      SELECT
      DISTINCT
       hca.account_number           AS account_number                      -- 顧客コード
      ,xrs1.customer_id             AS customer_id                         -- 顧客ID
      ,xrs1.invoice_date            AS invoice_date                        -- 請求書日付
      ,xrs1.payment_scheduled_date  AS payment_scheduled_date              -- 入金予定日
      ,xrs1.terms_name              AS terms_name                          -- 支払条件名
      ,amlv.attribute3              AS slip_line_type_name                 -- 入金相殺消込用請求内容
-- Ver1.1 Add Start
      ,(SELECT distinct 1
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number <> hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div1 -- 出荷先顧客コード
      ,(SELECT distinct 2
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div2 -- 出荷先顧客コード
      ,(SELECT distinct 3
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number <> hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div3 -- 請求先顧客コード
      ,(SELECT distinct 4
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number = hca.account_number )  AS div4 -- 入金先顧客コード
      ,(SELECT distinct 5
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number = hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div5 -- 入金先顧客コード
      ,(SELECT distinct 6
        FROM  xxcfr_cust_hierarchy_v xchv
        WHERE xchv.cash_account_number = hca.account_number
        AND   xchv.bill_account_number <> hca.account_number
        AND   xchv.ship_account_number <> hca.account_number ) AS div6 -- 入金先顧客コード
-- Ver1.1 Add End
      FROM xx03_receivable_slips xrs1                                      -- AR部門入力
          ,xx03_receivable_slips_line xrsl                                 -- AR部門入力明細
          ,hz_cust_accounts hca                                            -- 顧客マスタ
          ,ar_memo_lines_vl amlv                                           -- メモ明細
      WHERE
      xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--      AND xrs1.slip_type = cv_slip_type_80300                              -- 伝票種別:80300(入金相殺)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
      AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- 取引タイプ名(変動対価相殺)
--      AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- 取引タイプ名(変動対価相殺)
-- 2024/03/12 Ver1.2 MOD End
      AND xrsl.slip_line_type_name  = amlv.name                            -- AR部門入力明細. 請求内容 = メモ明細.名称
      AND amlv.attribute3 IS NOT NULL                                      -- メモ明細.入金相殺消込用請求内容に値あり
      AND xrs1.wf_status = cv_ar_status_appr                               -- ステータス:80(承認済)
      AND NOT EXISTS ( SELECT *                                            -- 伝票取消済みは除外
                       FROM   xx03_receivable_slips xrs2
                       WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR部門入力.伝票番号= AR部門入力2.修正元伝票番号
                       AND    xrs2.wf_status = cv_ar_status_appr )         -- 部門入力2.ステータス = 80(承認済)
      AND xrs1.orig_invoice_num IS NULL                                    -- 取消伝票は抽出対象外
      AND xrsl.attribute8 IS NULL                                          -- 入金相殺消込ステータス(未消込)
      AND hca.cust_account_id = xrs1.customer_id
      AND xrs1.gl_date >= gd_standard_date
      AND xrs1.gl_date <= gd_before_month_last_date
-- Ver1.1 Mod Start
--      ORDER BY xrs1.invoice_date ASC
      ORDER BY div1 ASC
              ,div2 ASC
              ,div3 ASC
              ,div4 ASC
              ,div5 ASC
              ,div6 ASC
              ,xrs1.invoice_date ASC
-- Ver1.1 Mod End
      ;
--
    -- *** ローカル・カーソル (販売控除情報ロック情報)***
    CURSOR sales_deduction_lock_cur(
      in_account_number         IN hz_cust_accounts.account_number%TYPE                 -- A-2-1で取得した顧客コード
     ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 1.2.1で取得した入金相殺消込用請求内容
     ,id_derivation_record_date IN DATE
    )
    IS
      SELECT /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
             xsd.sales_deduction_id   AS sales_deduction_id
      FROM   xxcok_sales_deduction xsd                                                   -- 販売控除情報
      WHERE
      xsd.recon_slip_num IS NULL                                                         -- 支払伝票番号
      AND xsd.status = cv_flag_n                                                         -- ステータス:N(新規)
      AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- 振替元顧客コード
                                      FROM   xxcfr_cust_hierarchy_v xchv
                                      WHERE  xchv.cash_account_number = in_account_number
                                      OR     xchv.bill_account_number = in_account_number
                                      OR     xchv.ship_account_number = in_account_number )
      AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- データ種類
                                      FROM   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = ct_deduction_data_type
                                      AND    flv.language     = cv_lang
                                      AND    flv.enabled_flag = cv_flag_yes
                                      AND    flv.attribute14  = iv_slip_line_type_name )
      AND xsd.record_date <= id_derivation_record_date                                     -- 対象計上日導出ロジックで導出した日付
      AND xsd.source_category <> cv_flag_d                                                 -- 作成元区分 <> D:差額調整
-- Ver1.1 Mod Start
--      AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- (作成元区分 = V:売上実績振替（振替割合）AND 速報確定フラグ:1(実績振替確定済み)
--            OR                                                                             --  OR
--            ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --  作成元区分 <> V:売上実績振替（振替割合）AND 速報確定フラグ IS NULL)
      AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )    -- 速報確定フラグ:1(実績振替確定済み)またはNULL
-- Ver1.1 Mod End
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・カーソル (AR部門入力（未消込）の明細情報)***
    CURSOR receivable_slips_cur(
        in_customer_id            IN xx03_receivable_slips.customer_id%TYPE               -- 顧客ID
       ,id_invoice_date           IN xx03_receivable_slips.invoice_date%TYPE              -- 請求書日付
       ,id_payment_scheduled_date IN xx03_receivable_slips.payment_scheduled_date%TYPE    -- 入金予定日
       ,iv_terms_name             IN xx03_receivable_slips.terms_name%TYPE                -- 支払条件名
       ,iv_slip_line_type_name    IN xx03_receivable_slips_line.slip_line_type_name%TYPE  -- 入金相殺消込用請求内容
       ,id_standard_day           IN DATE                                                 -- 入金相殺伝票抽出基準日
       ,id_before_month_last_date IN DATE                                                 -- 業務日付の前月の末日
    )
    IS
      SELECT
       xrs1.receivable_num        AS receivable_num                        -- AR部門入力.伝票番号
      ,xrsl.receivable_line_id    AS receivable_line_id                    -- AR部門入力明細.明細ID
      ,xrsl.line_number           AS line_number                           -- AR部門入力明細.明細No
      ,xrsl.slip_line_type_name   AS slip_line_type_name                   -- AR部門入力明細.請求内容
      ,xrsl.tax_code              AS tax_code                              -- AR部門入力明細.税コード
      ,xrsl.entered_item_amount   AS entered_item_amount                   -- AR部門入力明細.本体金額
      ,xrsl.entered_tax_amount    AS entered_tax_amount                    -- AR部門入力明細.消費税額
      ,xrs1.requestor_person_id   AS requestor_person_id                   -- AR部門入力.申請者
      ,xrs1.approver_person_id    AS approver_person_id                    -- AR部門入力.承認者
      ,xrs1.request_date          AS request_date                          -- AR部門入力.申請日
      ,xrs1.approval_date         AS approval_date                         -- AR部門入力.承認日
      ,xrs1.entry_department      AS entry_department                      -- AR部門入力.起票部門
      ,xrs1.gl_date               AS gl_date                               -- AR部門入力.計上日
      FROM xx03_receivable_slips xrs1                                      -- AR部門入力
          ,xx03_receivable_slips_line xrsl                                 -- AR部門入力明細
      WHERE
      xrs1.receivable_id = xrsl.receivable_id
-- 2024/03/12 Ver1.2 DEL Start
--      AND xrs1.slip_type = cv_slip_type_80300                              -- 伝票種別:80300(入金相殺)
-- 2024/03/12 Ver1.2 DEL End
-- 2024/03/12 Ver1.2 MOD Start
      AND xrs1.trans_type_name LIKE gv_trans_type_name_var_cons || '%'     -- 取引タイプ名(変動対価相殺)
--      AND xrs1.trans_type_name = gv_trans_type_name_var_cons               -- 取引タイプ名(変動対価相殺)
-- 2024/03/12 Ver1.2 MOD End
      AND xrs1.customer_id = in_customer_id                                -- 顧客ID
      AND xrs1.invoice_date = id_invoice_date                              -- 請求書日付
      AND xrs1.payment_scheduled_date = id_payment_scheduled_date          -- 入金予定日
      AND xrs1.terms_name = iv_terms_name                                  -- 支払条件名
      AND xrsl.slip_line_type_name IN ( SELECT amlv.name                   -- 請求内容
                                        FROM   ar_memo_lines_vl amlv
                                        WHERE  amlv.attribute3 = iv_slip_line_type_name )
      AND xrs1.wf_status = cv_ar_status_appr                               -- ステータス:80(承認済)
      AND NOT EXISTS ( SELECT *                                            -- 伝票取消済みは除外
                       FROM   xx03_receivable_slips xrs2
                       WHERE  xrs1.receivable_num = xrs2.orig_invoice_num  -- AR部門入力.伝票番号= AR部門入力2.修正元伝票番号
                       AND    xrs2.wf_status = cv_ar_status_appr )         -- 部門入力2.ステータス = 80(承認済)
      AND xrs1.orig_invoice_num IS NULL                                    -- 取消伝票は抽出対象外
      AND xrsl.attribute8 IS NULL                                          -- 入金相殺消込ステータス(未消込)
      AND xrs1.gl_date >= id_standard_day
      AND xrs1.gl_date <= id_before_month_last_date
      ORDER BY xrs1.invoice_date   ASC                                     -- 請求書日付
              ,xrs1.receivable_num ASC                                     -- 伝票番号
              ,xrsl.line_number    ASC                                     -- 明細No
      ;
--
    TYPE receivable_slips_ttype  IS TABLE OF receivable_slips_cur%ROWTYPE;
    receivable_slips_tab         receivable_slips_ttype;
--
    -- *** ローカル変数 ***
    lt_deduction_amt_sum           xxcok_sales_deduction.deduction_amount%TYPE;      -- 控除額合計
    lt_deduction_tax_amt_sum       xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- 控除税額合計
    lt_deduction_amt_sum_calc      xxcok_sales_deduction.deduction_amount%TYPE;      -- 控除額合計(計算用)
    lt_deduction_tax_amt_sum_calc  xxcok_sales_deduction.deduction_tax_amount%TYPE;  -- 控除税額合計(計算用)
    lt_receivable_num_1            xx03_receivable_slips.receivable_num%TYPE;        -- A-4で取得したAR部門入力（未消込）1レコード目の伝票番号
    lt_line_number_1               xx03_receivable_slips_line.line_number%TYPE;      -- A-4で取得したAR部門入力（未消込）1レコード目の明細番号
    ln_difference_amt              NUMBER  DEFAULT NULL;                             -- 差額
    ln_difference_tax_amt          NUMBER  DEFAULT NULL;                             -- 税差額
    ln_derivation_month            NUMBER  DEFAULT NULL;                             -- 計上日導出用の月
    ln_derivation_date             NUMBER  DEFAULT NULL;                             -- 計上日導出用の日
    ld_derivation_record_date      DATE    DEFAULT NULL;                             -- 計上日導出ロジックで導出した日付
    lb_derivation_err_flg          BOOLEAN DEFAULT FALSE;                            -- 計上日導出フラグ エラーの場合、TRUE
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- AR部門入力明細のロック取得
    OPEN  receivable_slips_lock_cur;
    FETCH receivable_slips_lock_cur INTO receivable_slips_line_lock_rec;
    CLOSE receivable_slips_lock_cur;
    --
    -- AR部門入力（未消込）のキー情報
    <<receivable_slips_key_loop>>
    FOR lt_receivable_slips_key_rec IN receivable_slips_key_cur LOOP
      --
      -- ==============================
      -- A-3.販売控除情報（未消込）取得
      -- ==============================
      --
      -- 変数の初期化
      lt_deduction_amt_sum          := NULL;
      lt_deduction_tax_amt_sum      := NULL;
      lt_deduction_amt_sum_calc     := NULL;
      lt_deduction_tax_amt_sum_calc := NULL;
      lt_receivable_num_1           := NULL;
      lt_line_number_1              := NULL;
      ln_derivation_month           := NULL;
      ln_derivation_date            := NULL;
      ld_derivation_record_date     := NULL;
      --
      -- 対象計上日導出
      IF ( lt_receivable_slips_key_rec.terms_name = '00_00_00' ) THEN
      -- 支払条件名が「00_00_00」の場合、A-2で取得した請求書日付を対象計上日とする。
        ld_derivation_record_date := lt_receivable_slips_key_rec.invoice_date;
      ELSE
        BEGIN
          ln_derivation_month := TO_NUMBER( SUBSTR( lt_receivable_slips_key_rec.terms_name, 7, 2 ) );
          ln_derivation_date  := TO_NUMBER( SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) );
        EXCEPTION
          WHEN VALUE_ERROR THEN
          ld_derivation_record_date := NULL;
          lb_derivation_err_flg     := TRUE;
        END;
        --
        IF ( lb_derivation_err_flg = FALSE ) THEN
          -- 入金予定日から1で取得した月を減算する。
          ld_derivation_record_date := ADD_MONTHS( lt_receivable_slips_key_rec.payment_scheduled_date, -ln_derivation_month );
          --
          IF ( ln_derivation_date = 30 ) THEN
            -- 日が30の場合、減算した入金予定日の月末日を設定する。
            ld_derivation_record_date := TRUNC( LAST_DAY( ld_derivation_record_date ) );
          ELSE
            -- 日が30以外の場合、減算した入金予定日に2で取得した日を設定する。
            ld_derivation_record_date := TO_DATE( TO_CHAR( ld_derivation_record_date, cv_year_format )
                                                  || TO_CHAR( ld_derivation_record_date, cv_month_format )
-- Ver1.1 Mod Start
--                                                  || SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) , cv_date_format );
                                                  || SUBSTR( lt_receivable_slips_key_rec.terms_name, 1, 2 ) , cv_date_format2 );
-- Ver1.1 Mod End
          END IF;
        END IF;
      END IF;
      --
      -- 対象計上日導出結果
      IF ( lb_derivation_err_flg = FALSE ) THEN
        -- 販売控除情報のロック取得
        BEGIN
          OPEN  sales_deduction_lock_cur(
              in_account_number         => lt_receivable_slips_key_rec.account_number
             ,iv_slip_line_type_name    => lt_receivable_slips_key_rec.slip_line_type_name
             ,id_derivation_record_date => ld_derivation_record_date
            );
          CLOSE sales_deduction_lock_cur;
        EXCEPTION
          -- ロックエラー
          WHEN global_lock_failure_expt THEN
            IF ( sales_deduction_lock_cur%ISOPEN ) THEN
              CLOSE sales_deduction_lock_cur;
            END IF;
            --
            -- ロックエラーメッセージ
            lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                                       ,iv_name          => cv_msg_cok_10732
                                                       ,iv_token_name1   => cv_tkn_table
                                                       ,iv_token_value1  => ct_msg_cok_10855            -- 文字列「販売控除情報」
                                                       );
            lv_errbuf      := lv_errmsg;
            ov_errmsg      := lv_errmsg;
            ov_errbuf      := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
            RAISE global_api_expt;
        END;
        --
        BEGIN
          SELECT /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
             SUM(xsd.deduction_amount)     AS deduction_amount             -- 控除額合計
            ,SUM(xsd.deduction_tax_amount) AS deduction_tax_amount         -- 控除税額合計
          INTO
             lt_deduction_amt_sum
            ,lt_deduction_tax_amt_sum
          FROM    xxcok_sales_deduction xsd                                -- 販売控除情報
          WHERE
          xsd.recon_slip_num IS NULL                                                         -- 支払伝票番号
          AND xsd.status = cv_flag_n                                                         -- ステータス:N(新規)
          AND xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- 振替元顧客コード
                                          FROM   xxcfr_cust_hierarchy_v xchv
                                          WHERE  xchv.cash_account_number = lt_receivable_slips_key_rec.account_number
                                          OR     xchv.bill_account_number = lt_receivable_slips_key_rec.account_number
                                          OR     xchv.ship_account_number = lt_receivable_slips_key_rec.account_number )
          AND xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- データ種類
                                          FROM   fnd_lookup_values flv
                                          WHERE  flv.lookup_type  = ct_deduction_data_type
                                          AND    flv.language     = cv_lang
                                          AND    flv.enabled_flag = cv_flag_yes
                                          AND    flv.attribute14  = lt_receivable_slips_key_rec.slip_line_type_name )
          AND xsd.record_date <= ld_derivation_record_date                                     -- 対象計上日導出ロジックで導出した日付
          AND xsd.source_category <> cv_flag_d                                                 -- 作成元区分 <> D:差額調整
-- Ver1.1 Mod Start
--          AND ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- ( 作成元区分 = V:売上実績振替（振替割合）AND 速報確定フラグ:1(実績振替確定済み)
--                OR                                                                             --   OR
--                ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --   作成元区分 <> V:売上実績振替（振替割合）AND 速報確定フラグ IS NULL )
          AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )    -- 速報確定フラグ:1(実績振替確定済み)またはNULL
-- Ver1.1 Mod End
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_deduction_amt_sum := NULL;
            lt_deduction_tax_amt_sum := NULL;
        END;
      --
      END IF;
      --
      -- ======================================
      -- A-4.AR部門入力（未消込）の明細情報取得
      -- ======================================
      --
      OPEN  receivable_slips_cur( lt_receivable_slips_key_rec.customer_id
                                 ,lt_receivable_slips_key_rec.invoice_date
                                 ,lt_receivable_slips_key_rec.payment_scheduled_date
                                 ,lt_receivable_slips_key_rec.terms_name
                                 ,lt_receivable_slips_key_rec.slip_line_type_name
                                 ,gd_standard_date
                                 ,gd_before_month_last_date
                                 );
      FETCH receivable_slips_cur BULK COLLECT INTO receivable_slips_tab;
      CLOSE receivable_slips_cur;
      -- 
      -- 処理件数
      gn_target_cnt := gn_target_cnt + receivable_slips_tab.COUNT;
      --
      -- A-3で取得した控除額合計がNULLの場合、A-4-1で取得した明細分の警告メッセージを出力し、処理をスキップします。
      IF ( lt_deduction_amt_sum IS NULL AND lb_derivation_err_flg = FALSE ) THEN
        FOR i IN 1..receivable_slips_tab.COUNT LOOP
          -- スキップ件数
          gn_warn_cnt := gn_warn_cnt + cn_number_one;
          --
          lv_errmsg   := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                       ,iv_name          => cv_msg_cok_10857
                                       ,iv_token_name1   => cv_tkn_receivable_num
                                       ,iv_token_value1  => receivable_slips_tab(i).receivable_num
                                       ,iv_token_name2   => cv_tkn_line_number
                                       ,iv_token_value2  => receivable_slips_tab(i).line_number
                                      );
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errbuf
          );
        END LOOP;
        CONTINUE;
      END IF;
      -- A-3の対象計上日導出ロジックで支払条件名が想定外の場合、A-4-1で取得した明細分の警告メッセージを出力し、処理をスキップします。
      IF ( lb_derivation_err_flg = TRUE ) THEN
        FOR i IN 1..receivable_slips_tab.COUNT LOOP
          -- スキップ件数
          gn_warn_cnt := gn_warn_cnt + cn_number_one;
          --
          lv_errmsg   := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                       ,iv_name          => cv_msg_cok_10858
                                       ,iv_token_name1   => cv_tkn_receivable_num
                                       ,iv_token_value1  => receivable_slips_tab(i).receivable_num
                                       ,iv_token_name2   => cv_tkn_line_number
                                       ,iv_token_value2  => receivable_slips_tab(i).line_number
                                       ,iv_token_name3   => cv_tkn_terms_name
                                       ,iv_token_value3  => lt_receivable_slips_key_rec.terms_name
                                      );
          lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errbuf
          );
        END LOOP;
        CONTINUE;
      END IF;
      --
      -- 控除額合計(計算用)、控除税額合計(計算用)の値を初期化
      lt_deduction_amt_sum_calc     := lt_deduction_amt_sum;
      lt_deduction_tax_amt_sum_calc := lt_deduction_tax_amt_sum;
      --
      FOR i IN 1..receivable_slips_tab.COUNT LOOP
        -- 変数の初期化
        ln_difference_amt          := NULL;
        ln_difference_tax_amt      := NULL;
        --
        IF i = 1 THEN
        -- 1レコード目の伝票番号、明細番号を保持
          lt_receivable_num_1 := receivable_slips_tab(i).receivable_num;
          lt_line_number_1    := receivable_slips_tab(i).line_number;
        END IF;
        -- ２レコード目からは控除額合計、控除税額合計を0円に設定する
        IF i > 1 THEN
          lt_deduction_amt_sum     := cn_number_zero;
          lt_deduction_tax_amt_sum := cn_number_zero;
        END IF;
        --
        -- AR部門入力明細金額と販売控除データの控除額の差額を計算
        ln_difference_amt     := lt_deduction_amt_sum + receivable_slips_tab(i).entered_item_amount;
        ln_difference_tax_amt := lt_deduction_tax_amt_sum + receivable_slips_tab(i).entered_tax_amount;
        --
        -- 控除消込明細情報(AR入金相殺)テーブルにレコードを登録
        INSERT INTO xxcok_deduction_recon_line_ar(
           deduction_recon_line_id      -- 控除消込明細ID
          ,recon_slip_num               -- 入金相殺伝票番号
          ,deduction_line_num           -- 消込明細番号
          ,recon_line_status            -- 入力ステータス
          ,cust_code                    -- 顧客コード
          ,memo_line_name               -- 請求内容
          ,tax_code                     -- 税コード
          ,deduction_amt                -- 控除額(税抜)
          ,deduction_tax                -- 控除額(消費税)
          ,payment_amt                  -- 支払額(税抜)
          ,payment_tax                  -- 支払額(消費税)
          ,difference_amt               -- 調整差額(税抜)
          ,difference_tax               -- 調整差額(消費税)
          ,created_by                   -- 作成者
          ,creation_date                -- 作成日
          ,last_updated_by              -- 最終更新者
          ,last_update_date             -- 最終更新日
          ,last_update_login            -- 最終更新ログイン
          ,request_id                   -- 要求ID
          ,program_application_id       -- コンカレント・プログラム・アプリケーションID
          ,program_id                   -- コンカレント・プログラムID
          ,program_update_date          -- プログラム更新日
        )
        VALUES(
          xxcok_dedu_recon_ar_s01.NEXTVAL
         ,receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number
         ,cn_number_one
         ,'ED'
         ,lt_receivable_slips_key_rec.account_number
         ,receivable_slips_tab(i).slip_line_type_name
         ,receivable_slips_tab(i).tax_code
         ,lt_deduction_amt_sum
         ,lt_deduction_tax_amt_sum
         ,receivable_slips_tab(i).entered_item_amount
         ,receivable_slips_tab(i).entered_tax_amount
         ,ln_difference_amt
         ,ln_difference_tax_amt
         ,cn_created_by                                  -- created_by
         ,cd_creation_date                               -- creation_date
         ,cn_last_updated_by                             -- last_updated_by
         ,cd_last_update_date                            -- last_update_date
         ,cn_last_update_login                           -- last_update_login
         ,cn_request_id                                  -- request_id
         ,cn_program_application_id                      -- program_application_id
         ,cn_program_id                                  -- program_id
         ,cd_program_update_date                         -- program_update_date
        );
        -- 差額ありの場合
        IF ( ln_difference_amt != 0 OR ln_difference_tax_amt != 0 ) THEN
          --
          -- ==========================
          -- A-5.差額調整控除データ登録
          -- ==========================
          ins_sales_deduction(
             in_account_number         => lt_receivable_slips_key_rec.account_number        -- 顧客コード
            ,iv_slip_line_type_name    => lt_receivable_slips_key_rec.slip_line_type_name   -- 入金相殺消込用請求内容
            ,in_deduction_amt_sum      => lt_deduction_amt_sum_calc                         -- 控除額合計(計算用)
            ,in_deduction_tax_amt_sum  => lt_deduction_tax_amt_sum_calc                     -- 控除税額合計(計算用)
            ,id_derivation_record_date => ld_derivation_record_date                         -- 対象計上日導出ロジックで導出した日付
            ,iv_receivable_num         => receivable_slips_tab(i).receivable_num            -- 対象レコードの伝票番号
            ,iv_line_number            => receivable_slips_tab(i).line_number               -- 対象レコードの明細番号
            ,iv_receivable_num_1       => lt_receivable_num_1                               -- 1レコード目の伝票番号
            ,iv_line_number_1          => lt_line_number_1                                  -- 1レコード目の明細番号
            ,ln_difference_amt         => -1 * ln_difference_amt                            -- 差額
            ,ln_difference_tax_amt     => -1 * ln_difference_tax_amt                        -- 税差額
            ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
            ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
            ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
             RAISE global_process_expt;
               --
          END IF;
        END IF;
        --
        -- ===================
        -- A-6  AR部門入力更新
        -- ===================
        UPDATE xx03_receivable_slips_line xrsl
        SET    xrsl.attribute8               = cv_flag_y                        -- 入金相殺自動消込フラグ
              ,xrsl.last_updated_by          = cn_last_updated_by               -- 最終更新者
              ,xrsl.last_update_date         = cd_last_update_date              -- 最終更新日
              ,xrsl.last_update_login        = cn_last_update_login             -- 最終更新ログイン
              ,xrsl.request_id               = cn_request_id                    -- 要求ID
              ,xrsl.program_application_id   = cn_program_application_id        -- コンカレント・プログラム・アプリケーションID
              ,xrsl.program_id               = cn_program_id                    -- コンカレント・プログラムID
              ,xrsl.program_update_date      = cd_program_update_date           -- プログラム更新日
        WHERE  xrsl.receivable_line_id       = receivable_slips_tab(i).receivable_line_id
        ;
        -- AR部門入力明細更新の更新件数
        gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
        -- =======================
        -- A-7  販売控除データ更新
        -- =======================
        UPDATE /*+ USE_INVISIBLE_INDEXES INDEX(xxcok_sales_deduction_n10) */
               xxcok_sales_deduction xsd
        SET    xsd.recon_slip_num          = receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number  -- 支払伝票番号
              ,xsd.carry_payment_slip_num  = receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number  -- 繰越時支払伝票番号
              ,xsd.last_updated_by         = cn_last_updated_by                             -- 最終更新者
              ,xsd.last_update_date        = cd_last_update_date                            -- 最終更新日
              ,xsd.last_update_login       = cn_last_update_login                           -- 最終更新ログイン
              ,xsd.request_id              = cn_request_id                                  -- 要求ID
              ,xsd.program_application_id  = cn_program_application_id                      -- コンカレント・プログラム・アプリケーションID
              ,xsd.program_id              = cn_program_id                                  -- コンカレント・プログラムID
              ,xsd.program_update_date     = cd_program_update_date                         -- プログラム更新日
        WHERE  xsd.recon_slip_num IS NULL                                                   -- 支払伝票番号
        AND  xsd.status = cv_flag_n                                                         -- ステータス:N(新規)
        AND  xsd.customer_code_from IN ( SELECT ship_account_number AS ship_account_number  -- 振替元顧客コード
                                         FROM   xxcfr_cust_hierarchy_v xchv
                                         WHERE  xchv.cash_account_number = lt_receivable_slips_key_rec.account_number
                                         OR     xchv.bill_account_number = lt_receivable_slips_key_rec.account_number
                                         OR     xchv.ship_account_number = lt_receivable_slips_key_rec.account_number )
        AND  xsd.data_type          IN ( SELECT flv.lookup_code AS code                     -- データ種類
                                         FROM   fnd_lookup_values flv
                                         WHERE  flv.lookup_type  = ct_deduction_data_type
                                         AND    flv.language     = cv_lang
                                         AND    flv.enabled_flag = cv_flag_yes
                                         AND    flv.attribute14  = lt_receivable_slips_key_rec.slip_line_type_name )
        AND  xsd.record_date <= ld_derivation_record_date                                     -- 対象計上日導出ロジックで導出した日付
        AND  xsd.source_category <> cv_flag_d                                                 -- 作成元区分 <> D:差額調整
-- Ver1.1 Mod Start
--        AND  ( ( xsd.source_category = cv_flag_v AND xsd.report_decision_flag = cv_flag_on )  -- ( 作成元区分 = V:売上実績振替（振替割合）AND 速報確定フラグ:1(実績振替確定済み)
--               OR                                                                             --   OR
--               ( xsd.source_category <> cv_flag_v AND xsd.report_decision_flag IS NULL ) )    --   作成元区分 <> V:売上実績振替（振替割合）AND 速報確定フラグ IS NULL )
        AND ( xsd.report_decision_flag = cv_flag_on OR xsd.report_decision_flag IS NULL )     -- 速報確定フラグ:1(実績振替確定済み)またはNULL
-- Ver1.1 Mod End
        ;
        -- ==========================
        --A-8  控除消込ヘッダ情報作成
        -- ==========================
        INSERT INTO xxcok_deduction_recon_head(
           deduction_recon_head_id      -- 控除消込ヘッダーID
          ,recon_base_code              -- 支払請求拠点
          ,recon_slip_num               -- 支払伝票番号
          ,recon_status                 -- 消込ステータス
          ,application_date             -- 申請日
          ,approval_date                -- 承認日
          ,cancellation_date            -- 取消日
          ,recon_due_date               -- 支払予定日
          ,gl_date                      -- GL記帳日
          ,cancel_gl_date               -- 取消GL記帳日
          ,target_date_end              -- 対象期間(TO)
          ,interface_div                -- 連携先
          ,payee_code                   -- 支払先コード
          ,corp_code                    -- 企業コード
          ,deduction_chain_code         -- 控除用チェーンコード
          ,cust_code                    -- 顧客コード
          ,condition_no                 -- 控除番号
          ,invoice_number               -- 問屋請求書番号
          ,target_data_type             -- 対象データ種類
          ,applicant                    -- 申請者
          ,approver                     -- 承認者
          ,ap_ar_if_flag                -- AP/AR連携フラグ
          ,gl_if_flag                   -- 消込GL連携フラグ
          ,terms_name                   -- 支払条件
          ,invoice_date                 -- 請求書日付
          ,created_by                   -- 作成者
          ,creation_date                -- 作成日
          ,last_updated_by              -- 最終更新者
          ,last_update_date             -- 最終更新日
          ,last_update_login            -- 最終更新ログイン
          ,request_id                   -- 要求ID
          ,program_application_id       -- コンカレント・プログラム・アプリケーションID
          ,program_id                   -- コンカレント・プログラムID
          ,program_update_date          -- プログラム更新日
        )
        VALUES(
           xxcok_deduction_recon_head_s01.NEXTVAL
          ,receivable_slips_tab(i).entry_department
          ,receivable_slips_tab(i).receivable_num || '-' || receivable_slips_tab(i).line_number
          ,'AD'
          ,receivable_slips_tab(i).request_date
          ,receivable_slips_tab(i).approval_date
          ,NULL
          ,lt_receivable_slips_key_rec.payment_scheduled_date
          ,gd_before_month_last_date
          ,NULL
          ,ld_derivation_record_date
          ,'AR'
          ,lt_receivable_slips_key_rec.account_number
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,NULL
          ,receivable_slips_tab(i).requestor_person_id
          ,receivable_slips_tab(i).approver_person_id
          ,NULL
          ,'N'
          ,lt_receivable_slips_key_rec.terms_name
          ,lt_receivable_slips_key_rec.invoice_date
          ,cn_created_by                                  -- created_by
          ,cd_creation_date                               -- creation_date
          ,cn_last_updated_by                             -- last_updated_by
          ,cd_last_update_date                            -- last_update_date
          ,cn_last_update_login                           -- last_update_login
          ,cn_request_id                                  -- request_id
          ,cn_program_application_id                      -- program_application_id
          ,cn_program_id                                  -- program_id
          ,cd_program_update_date                         -- program_update_date
        ); 
        --
      END LOOP;
    END LOOP receivable_slips_key_loop;
    --
  EXCEPTION
  --
    -- ロックエラー
    WHEN global_lock_failure_expt THEN
      IF ( receivable_slips_lock_cur%ISOPEN ) THEN
        CLOSE receivable_slips_lock_cur;
      END IF;
--
      -- ロックエラーメッセージ
      lv_errmsg      := xxccp_common_pkg.get_msg( iv_application   => cv_appl_short_name_xxcok
                                                 ,iv_name          => cv_msg_cok_10732
                                                 ,iv_token_name1   => cv_tkn_table
                                                 ,iv_token_value1  => ct_msg_cok_10856            -- 文字列「AR部門入力明細」
                                                 );
      lv_errbuf      := lv_errmsg;
      ov_errmsg      := lv_errmsg;
      ov_errbuf      := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode     := cv_status_error;
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_receivable_slips_key;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ============
    -- A-1.初期処理
    -- ============
    init(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ======================================
    -- A-2.AR部門入力（未消込）のキー情報取得
    -- ======================================
    get_receivable_slips_key(
       ov_errbuf                 => lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                => lv_retcode  -- リターン・コード             --# 固定 #
      ,ov_errmsg                 => lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    --
    END IF;
    --
    IF ( gn_warn_cnt > cn_number_zero ) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    --
    COMMIT;
    --
  EXCEPTION
 --
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ --# 固定 #
    ,retcode OUT NOCOPY VARCHAR2 -- リターン・コード   --# 固定 #
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
    lv_message_code VARCHAR2(100);   -- 終了メッセージコード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    --
    -- *** ローカル変数 ***
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --###########################  固定部 END   #############################
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
       -- エラー出力
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --エラーメッセージ
       );
       --
    END IF;
    --
    -- =======================
    -- A-6.終了処理
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    --エラーの場合、処理件数、成功件数、スキップ件数クリア、エラー件数固定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := cn_number_zero;
      gn_normal_cnt := cn_number_zero;
      gn_error_cnt  := cn_number_one;
      gn_warn_cnt   := cn_number_zero;
    END IF;
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ステータスセット
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
    --
    --###########################  固定部 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  固定部 END   #######################################################
  --
END XXCOK024A42C;
/
