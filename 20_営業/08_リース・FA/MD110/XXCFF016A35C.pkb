CREATE OR REPLACE PACKAGE BODY XXCFF016A35C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A35C(body)
 * Description      : リース契約メンテナンス
 * MD.050           : MD050_CFF_016_A35_リース契約メンテナンス
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  chk_input_param        入力パラメータチェック処理(A-2)
 *  upd_comments           件名更新処理(A-3)
 *  submit_csv_conc        ＣＳＶ出力処理(A-4)
 *  ins_bk_table           データバックアップ処理(A-5)
 *  upd_contract_headers   リース契約ヘッダ更新処理(A-6)
 *  get_contract_data      リース契約明細データ取得処理(A-7)
 *  upd_contract_lines     リース種類判定／リース契約明細更新処理(A-8)
 *  ins_contract_histories リース契約明細履歴登録処理(A-9)
 *  create_pay_planning    支払計画再作成／フラグ更新処理(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   SCSK谷口         新規作成
 *  2013/02/12    1.1   SCSK中野         「E_本稼動_09967」対応
 *  2013/02/27    1.2   SCSK中村         「E_本稼動_09967」対応 入力パラメータチェック追加
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
  -- ユーザー定義例外
  -- ===============================
  data_lock_expt            EXCEPTION;        -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCFF016A35C';           -- パッケージ名
  cv_appl_short_name_xxcff        CONSTANT VARCHAR2(100) := 'XXCFF';                  -- アプリケーション短縮名（アドオン：会計・リース・FA領域）
  cv_appl_short_name_xxccp        CONSTANT VARCHAR2(100) := 'XXCCP';                  -- アプリケーション短縮名（アドオン：共通・IF領域）
  cv_which_log                    CONSTANT VARCHAR2(100) := 'LOG';                    -- コンカレントログ出力先
  cv_format_datetime              CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- 日時書式
  cv_format_date                  CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- 日付書式
  cv_wide_space                   CONSTANT VARCHAR2(100) := '　';                     -- 全角スペース
  cv_lease_kind_code_fin          CONSTANT VARCHAR2(100) := '0';                      -- リース種類コード：Finリース
  cv_contract_status_contract     CONSTANT VARCHAR2(100) := '202';                    -- 契約ステータス：契約
  cv_contract_status_release      CONSTANT VARCHAR2(100) := '203';                    -- 契約ステータス：再リース
  cv_contract_status_maintenance  CONSTANT VARCHAR2(100) := '210';                    -- 契約ステータス：データメンテナンス
  cv_payment_type_month           CONSTANT VARCHAR2(100) := '0';                      -- 頻度：月
  cv_payment_type_year            CONSTANT VARCHAR2(100) := '1';                      -- 頻度：年
  cn_max_payment_frequency_year   CONSTANT NUMBER := 50;                              -- 最大支払回数（頻度：年）
  cn_max_payment_frequency_month  CONSTANT NUMBER := 600;                             -- 最大支払回数（頻度：月）
  cv_conc_dev_status_error        CONSTANT VARCHAR2(100) := 'ERROR';                  -- コンカレントステータス：異常
  cv_conc_dev_status_warning      CONSTANT VARCHAR2(100) := 'WARNING';                -- コンカレントステータス：警告
  cv_trunc_format_month           CONSTANT VARCHAR2(100) := 'MM';                     -- TRUNC書式（月で切り捨て（月初））
  cv_acct_if_flag_not_send        CONSTANT VARCHAR2(100) := '1';                      -- 会計ＩＦフラグ：未送信
  cv_acct_if_flag_sent            CONSTANT VARCHAR2(100) := '2';                      -- 会計ＩＦフラグ：送信済
  cv_payment_match_flag_matched   CONSTANT VARCHAR2(100) := '1';                      -- 照合済フラグ：照合済
  cv_pay_plan_shori_type_create   CONSTANT VARCHAR2(100) := '1';                      -- 支払計画作成処理区分：登録
-- Add 2013/02/27 Ver1.2 Start
  cv_payment_frequency_3          CONSTANT NUMBER := 3;                               -- 支払回数（最終支払日導出用の3回）
-- Add 2013/02/27 Ver1.2 End
  -- メッセージ
  cv_msg_param_output             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00206';       -- パラメータ出力用
  cv_msg_common_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00094';       -- 共通関数エラー
  cv_msg                          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00095';       -- エラーメッセージ
  cv_msg_period_name_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00186';       -- 会計期間取得エラー
  cv_msg_profile_err              CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00020';       -- プロファイル取得エラー
  cv_msg_null_err                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00157';       -- 必須チェックエラー
  cv_msg_all_null_err             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00207';       -- メンテナンス項目値未入力エラー
  cv_msg_param_type_err           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00200';       -- パラメータ型・桁数エラー
  cv_msg_date_format_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00118';       -- 日付論理エラー
  cv_msg_data_notfound_err        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00062';       -- 取得対象データ無し
  cv_msg_lease_date_err           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00201';       -- リース開始日・リース終了日相関エラー
  cv_msg_payment_frequency_err    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00202';       -- 支払回数妥当性チェックエラー
  cv_msg_date_context_err         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00203';       -- 日付妥当性チェックエラー
  cv_msg_second_payment_date_err  CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00204';       -- 2回目支払日妥当性チェックエラー
  cv_msg_data_lock_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00007';       -- ロックエラー
  cv_msg_update_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00205';       -- 更新エラー
  cv_msg_conc_submit_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00197';       -- コンカレント発行エラー
  cv_msg_conc_wait_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00198';       -- コンカレント待機エラー
  cv_msg_conc_proc_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00199';       -- コンカレント処理エラー
  cv_msg_insert_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00102';       -- 登録エラー
  cv_msg_select_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00101';       -- 取得エラー
  cv_msg_process_date_err         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00092';       -- 業務日付取得エラー
-- Add 2013/02/27 Ver1.2 Start
  cv_msg_last_payment_date_err    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00031';       -- 支払日妥当性エラー（最終支払日）
-- Add 2013/02/27 Ver1.2 End
  -- トークン
  cv_tkn_param_name               CONSTANT VARCHAR2(100) := 'PARAM_NAME';             -- パラメータ論理名
  cv_tkn_param_val                CONSTANT VARCHAR2(100) := 'PARAM_VAL';              -- パラメータ入力値
  cv_tkn_func_name                CONSTANT VARCHAR2(100) := 'FUNC_NAME';              -- 関数名
  cv_tkn_err_msg                  CONSTANT VARCHAR2(100) := 'ERR_MSG';                -- エラーメッセージ
  cv_tkn_prof_name                CONSTANT VARCHAR2(100) := 'PROF_NAME';              -- プロファイル名
  cv_tkn_input                    CONSTANT VARCHAR2(100) := 'INPUT';                  -- 入力値
  cv_tkn_frequency                CONSTANT VARCHAR2(100) := 'FREQUENCY';              -- 回数
  cv_tkn_date_object1             CONSTANT VARCHAR2(100) := 'DATE_OBJECT1';           -- 日付項目１
  cv_tkn_date_object2             CONSTANT VARCHAR2(100) := 'DATE_OBJECT2';           -- 日付項目２
  cv_tkn_onward                   CONSTANT VARCHAR2(100) := 'ONWARD';                 -- ～以降
  cv_tkn_table_name               CONSTANT VARCHAR2(100) := 'TABLE_NAME';             -- テーブル論理名
  cv_tkn_syori                    CONSTANT VARCHAR2(100) := 'SYORI';                  -- コンカレント論理名
  cv_tkn_request_id               CONSTANT VARCHAR2(100) := 'REQUEST_ID';             -- 要求ID
  cv_tkn_info                     CONSTANT VARCHAR2(100) := 'INFO';                   -- 情報
  -- トークン値
  cv_val_api_nm_put_log_param     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50210';       -- コンカレントパラメータ出力処理
  cv_val_api_nm_lease_kind        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50207';       -- リース種類判定
  cv_val_api_nm_create_pay_plan   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50209';       -- リース支払計画作成
  cv_val_contract_number          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50040';       -- 契約番号
  cv_val_lease_company            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50043';       -- リース会社
  cv_val_update_reason            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50199';       -- 更新事由
  cv_val_lease_start_date         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50046';       -- リース開始日
  cv_val_lease_end_date           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50051';       -- リース終了日
  cv_val_payment_frequency        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50033';       -- 支払回数
  cv_val_contract_date            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50134';       -- リース契約日
  cv_val_first_payment_date       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50052';       -- 初回支払日
  cv_val_second_payment_date      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50053';       -- 2回目支払日
  cv_val_third_payment_date       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50054';       -- 3回目以降支払日
  cv_val_comments                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50045';       -- 件名
  cv_val_contract_number_colon    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50211';       -- 契約番号：
  cv_val_lease_company_colon      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50212';       -- リース会社：
  cv_val_contract_hdr_id_colon    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50213';       -- 契約内部ID：
  cv_val_contract_line_id_colon   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50214';       -- 契約明細内部ID：
  cv_val_period_name_colon        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50215';       -- 会計期間：
  cv_val_process_date             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50216';       -- 業務日付
  cv_val_two_months_after         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50217';       -- 翌々月
  cv_val_nex_year                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50218';       -- 翌年度
  cv_val_cont_hdr_tab_nm          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50219';       -- リース契約ヘッダ
  cv_val_cont_line_tab_nm         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50220';       -- リース契約明細
  cv_val_cont_hdr_bk_tab_nm       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50221';       -- リース契約ヘッダBK
  cv_val_cont_line_bk_tab_nm      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50200';       -- リース契約明細BK
  cv_val_pay_plan_bk_tab_nm       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50201';       -- リース支払計画BK
  cv_val_cont_line_hist_tab_nm    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50094';       -- リース契約明細履歴
  cv_val_pay_plan_tab_nm          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50088';       -- リース支払計画
  cv_val_prg_contract_csv         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50203';       -- リース契約データCSV出力
  cv_val_prg_object_csv           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50204';       -- リース物件データCSV出力
  cv_val_prg_pay_planning_csv     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50205';       -- リース支払計画データCSV出力
  cv_val_prg_accounting_csv       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50206';       -- リース会計基準情報CSV出力
  -- プロファイル
  cv_prof_interval                CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';        -- XXCOS:待機間隔
  cv_prof_max_wait                CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';        -- XXCOS:最大待機時間
  -- プログラム
  cv_prg_contract_csv             CONSTANT VARCHAR2(100) := 'XXCCP008A01C';           -- リース契約データCSV出力
  cv_prg_object_csv               CONSTANT VARCHAR2(100) := 'XXCCP008A02C';           -- リース物件データCSV出力
  cv_prg_pay_planning_csv         CONSTANT VARCHAR2(100) := 'XXCCP008A03C';           -- リース支払計画データCSV出力
  cv_prg_accounting_csv           CONSTANT VARCHAR2(100) := 'XXCCP008A04C';           -- リース会計基準情報CSV出力
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 入力パラメータ格納用
  gv_param_contract_number      xxcff_contract_headers.contract_number%TYPE;          -- 1. 契約番号  （必須）
  gv_param_lease_company        xxcff_contract_headers.lease_company%TYPE;            -- 2. リース会社（必須）
  gv_param_update_reason        xxcff_contract_histories.update_reason%TYPE;          -- 3. 更新事由  （必須）
  gd_param_lease_start_date     xxcff_contract_headers.lease_start_date%TYPE;         -- 4. リース開始日
  gd_param_lease_end_date       xxcff_contract_headers.lease_end_date%TYPE;           -- 5. リース終了日
  gn_param_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;        -- 6. 支払回数
  gd_param_contract_date        xxcff_contract_headers.contract_date%TYPE;            -- 7. 契約日
  gd_param_first_payment_date   xxcff_contract_headers.first_payment_date%TYPE;       -- 8. 初回支払日
  gd_param_second_payment_date  xxcff_contract_headers.second_payment_date%TYPE;      -- 9. ２回目支払日
  gn_param_third_payment_date   xxcff_contract_headers.third_payment_date%TYPE;       -- 10.３回目以降支払日
  gv_param_comments             xxcff_contract_headers.comments%TYPE;                 -- 11.件名
  --
  gv_period_name                fa_deprn_periods.period_name%TYPE;                    -- リース台帳オープン期間
  gd_calendar_period_close_date fa_deprn_periods.calendar_period_close_date%TYPE;     -- リース台帳オープン期間のカレンダ終了日
  gn_interval                   NUMBER;                                               -- コンカレント待機間隔
  gn_max_wait                   NUMBER;                                               -- コンカレント最大待機時間
  gd_process_date               DATE;                                                 -- 業務日付
  gn_rec_no                     NUMBER;                                               -- リース契約明細情報テーブルループカウンタ
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- リース契約ヘッダ情報
  CURSOR g_cont_hdr_cur(
    iv_contract_number  IN  VARCHAR2  -- 契約番号
   ,iv_lease_company    IN  VARCHAR2  -- リース会社
  )
  IS
    SELECT  xch.contract_header_id    AS  contract_header_id  -- 契約内部ID
           ,xch.contract_number       AS  contract_number     -- 契約番号
           ,xch.lease_company         AS  lease_company       -- リース会社
-- Add 2013/02/12 Ver1.1 Start
           ,xch.contract_date         AS  contract_date       -- リース契約日
-- Add 2013/02/12 Ver1.1 End
           ,xch.payment_frequency     AS  payment_frequency   -- 支払回数
           ,xch.payment_type          AS  payment_type        -- 頻度
           ,xch.lease_start_date      AS  lease_start_date    -- リース開始日
           ,xch.lease_end_date        AS  lease_end_date      -- リース終了日
           ,xch.first_payment_date    AS  first_payment_date  -- 初回支払日
           ,xch.second_payment_date   AS  second_payment_date -- 2回目支払日
    FROM    xxcff_contract_headers    xch                     -- リース契約ヘッダ
    WHERE   xch.contract_number     = iv_contract_number      -- 契約番号
    AND     xch.lease_company       = iv_lease_company        -- リース会社
    AND     EXISTS
              ( SELECT  'X'
                FROM    xxcff_contract_lines    xcl           -- リース契約明細
                WHERE   xcl.contract_header_id  = xch.contract_header_id            -- 契約内部ID
                AND     xcl.contract_status     IN  ( cv_contract_status_contract
                                                    , cv_contract_status_release )  -- 契約ステータス（契約, 再リース）
              )
    AND     ROWNUM = 1  -- ヘッダ情報のみ取得するため取得レコードは１件
  ;
  -- リース契約ヘッダ情報レコード型
  g_cont_hdr_rec      g_cont_hdr_cur%ROWTYPE;
--
  -- リース契約明細情報
  CURSOR g_cont_line_cur(
    in_contract_header_id   IN  NUMBER  -- 契約内部ID
  )
  IS
    SELECT  xch.contract_header_id    AS  contract_header_id    -- 契約内部ID
           ,xch.contract_number       AS  contract_number       -- 契約番号
           ,xch.lease_company         AS  lease_company         -- リース会社
           ,xch.contract_date         AS  contract_date         -- リース契約日
           ,xch.payment_frequency     AS  payment_frequency     -- 支払回数
           ,xcl.contract_line_id      AS  contract_line_id      -- 契約明細内部ID
           ,xcl.first_charge          AS  first_charge          -- 初回月額リース料_リース料
           ,xcl.first_tax_charge      AS  first_tax_charge      -- 初回消費税額_リース料
           ,xcl.second_charge         AS  second_charge         -- 2回目以降月額リース料_リース料
           ,xcl.first_deduction       AS  first_deduction       -- 初回月額リース料_控除額
           ,xcl.second_deduction      AS  second_deduction      -- 2回目以降月額リース料_控除額
           ,xcl.estimated_cash_price  AS  estimated_cash_price  -- 見積現金購入価額
           ,xcl.life_in_months        AS  life_in_months        -- 法定耐用年数
           ,xoh.object_header_id      AS  object_header_id      -- 物件内部ID
           ,xoh.object_code           AS  object_code           -- 物件コード
           ,xoh.lease_type            AS  lease_type            -- リース区分
    FROM    xxcff_contract_headers    xch                       -- リース契約ヘッダ
           ,xxcff_contract_lines      xcl                       -- リース契約明細
           ,xxcff_object_headers      xoh                       -- リース物件
    WHERE   xch.contract_header_id    = xcl.contract_header_id  -- 契約内部ID
    AND     xcl.object_header_id      = xoh.object_header_id    -- 物件内部ID
    AND     xch.contract_header_id    = in_contract_header_id   -- 契約内部ID
    AND     xcl.contract_status       IN  ( cv_contract_status_contract
                                          , cv_contract_status_release )  -- 契約ステータス（契約, 再リース
    FOR UPDATE OF xcl.contract_line_id NOWAIT                   -- リース契約明細ロック
  ;
  -- リース契約明細情報レコード型
  g_cont_line_rec     g_cont_line_cur%ROWTYPE;
  -- リース契約明細情報テーブル型
  TYPE g_cont_line_ttype IS TABLE OF g_cont_line_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_cont_line_tab     g_cont_line_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number      IN  VARCHAR2    -- 1. 契約番号
   ,iv_lease_company        IN  VARCHAR2    -- 2. リース会社
   ,iv_update_reason        IN  VARCHAR2    -- 3. 更新事由
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. リース開始日
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. リース終了日
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. 支払回数
   ,iv_contract_date        IN  VARCHAR2    -- 7. 契約日
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. 初回支払日
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. ２回目支払日
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.３回目以降支払日
   ,iv_comments             IN  VARCHAR2    -- 11.件名
   ,ov_errbuf               OUT VARCHAR2    --    エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT VARCHAR2    --    リターン・コード             --# 固定 #
   ,ov_errmsg               OUT VARCHAR2)   --    ユーザー・エラー・メッセージ --# 固定 #
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
    lv_msg     VARCHAR2(5000);  -- メッセージ
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
    -- ============================================
    -- コンカレントパラメータ出力処理
    --
    -- ※共通関数：xxcff_common1_pkg.put_log_paramでは
    --   パラメータ数10までしか出力できないため、自前で出力する
    -- ============================================
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
    --
    -- 1. 契約番号
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_contract_number       -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_contract_number           -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 2. リース会社
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_lease_company         -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_lease_company             -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 3. 更新事由
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_update_reason         -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_update_reason             -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 4. リース開始日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_lease_start_date      -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_lease_start_date, cv_format_datetime), cv_format_date)  -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 5. リース終了日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_lease_end_date        -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_lease_end_date, cv_format_datetime), cv_format_date)  -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 6. 支払回数
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_payment_frequency     -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_payment_frequency         -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 7. 契約日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_contract_date         -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_contract_date, cv_format_datetime), cv_format_date) -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 8. 初回支払日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_first_payment_date    -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_first_payment_date, cv_format_datetime), cv_format_date)  -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 9. ２回目支払日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_second_payment_date   -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_second_payment_date, cv_format_datetime), cv_format_date) -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 10.３回目以降支払日
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_third_payment_date    -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_third_payment_date        -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 11.件名
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                  ,iv_name          => cv_msg_param_output          -- メッセージコード
                  ,iv_token_name1   => cv_tkn_param_name            -- トークンコード1
                  ,iv_token_value1  => cv_val_comments              -- トークン値1
                  ,iv_token_name2   => cv_tkn_param_val             -- トークンコード2
                  ,iv_token_value2  => iv_comments                  -- トークン値2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
--
    -- ============================================
    -- リース台帳オープン期間取得
    -- ============================================
    BEGIN
      SELECT  fdp.period_name             AS  period_name                 -- 期間名称
             ,calendar_period_close_date  AS  calendar_period_close_date  -- カレンダ終了日
      INTO    gv_period_name                                  -- リース台帳オープン期間
             ,gd_calendar_period_close_date                   -- リース台帳オープン期間のカレンダ終了日
      FROM    fa_deprn_periods      fdp                       -- 減価償却期間
             ,xxcff_lease_kind_v    xlkv                      -- リース種類ビュー
      WHERE   fdp.book_type_code    = xlkv.book_type_code     -- 資産台帳コード
      AND     xlkv.lease_kind_code  = cv_lease_kind_code_fin  -- リース種類コード（Finリース）
      AND     fdp.period_close_date IS NULL                   -- オープン期間
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_period_name_err     -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- プロファイル値の取得
    -- ============================================
    -- XXCOS:待機間隔
    gn_interval := TO_NUMBER(fnd_profile.value(cv_prof_interval));
    --
    IF (gn_interval IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_profile_err         -- メッセージコード
                    ,iv_token_name1   => cv_tkn_prof_name           -- トークンコード1
                    ,iv_token_value1  => cv_prof_interval           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- XXCOS:最大待機時間
    gn_max_wait := TO_NUMBER(fnd_profile.value(cv_prof_max_wait));
    --
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_profile_err         -- メッセージコード
                    ,iv_token_name1   => cv_tkn_prof_name           -- トークンコード1
                    ,iv_token_value1  => cv_prof_max_wait           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 業務日付取得
    -- ============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_process_date_err    -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : chk_input_param
   * Description      : 入力パラメータチェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    iv_contract_number      IN  VARCHAR2    -- 1. 契約番号
   ,iv_lease_company        IN  VARCHAR2    -- 2. リース会社
   ,iv_update_reason        IN  VARCHAR2    -- 3. 更新事由
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. リース開始日
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. リース終了日
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. 支払回数
   ,iv_contract_date        IN  VARCHAR2    -- 7. 契約日
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. 初回支払日
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. ２回目支払日
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.３回目以降支払日
   ,iv_comments             IN  VARCHAR2    -- 11.件名
   ,ov_errbuf               OUT VARCHAR2    --    エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT VARCHAR2    --    リターン・コード             --# 固定 #
   ,ov_errmsg               OUT VARCHAR2)   --    ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- プログラム名
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
    ln_db_cnt             NUMBER;
-- Add 2013/02/27 Ver1.2 Start
    ld_last_payment_date      DATE; -- 最終支払日
    lt_param_lease_start_date xxcff_contract_headers.lease_start_date%TYPE;
    lt_param_lease_end_date   xxcff_contract_headers.lease_end_date%TYPE;
-- Add 2013/02/27 Ver1.2 End
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
    -- ============================================
    -- 必須チェック
    -- ============================================
    -- 1. 契約番号
    IF (iv_contract_number IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_null_err            -- メッセージコード
                    ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                    ,iv_token_value1  => cv_val_contract_number     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 2. リース会社
    IF (iv_lease_company IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_null_err            -- メッセージコード
                    ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                    ,iv_token_value1  => cv_val_lease_company       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 3. 更新事由
    IF (iv_update_reason IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_null_err            -- メッセージコード
                    ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                    ,iv_token_value1  => cv_val_update_reason       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- メンテナンス項目がすべて未入力の場合
    IF (  iv_lease_start_date     IS NULL   -- 4. リース開始日
      AND iv_lease_end_date       IS NULL   -- 5. リース終了日
      AND iv_payment_frequency    IS NULL   -- 6. 支払回数
      AND iv_contract_date        IS NULL   -- 7. 契約日
      AND iv_first_payment_date   IS NULL   -- 8. 初回支払日
      AND iv_second_payment_date  IS NULL   -- 9. ２回目支払日
      AND iv_third_payment_date   IS NULL   -- 10.３回目以降支払日
      AND iv_comments             IS NULL   -- 11.件名
    )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_all_null_err            -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

--
    -- ============================================
    -- 型／桁数チェック
    -- （チェックと同時に入力パラメータをグローバル変数へ格納する）
    -- ============================================
    -- 1. 契約番号
    BEGIN
      gv_param_contract_number := iv_contract_number;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_contract_number     -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 2. リース会社
    BEGIN
      gv_param_lease_company := iv_lease_company;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_lease_company       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 3. 更新事由
    BEGIN
      gv_param_update_reason := iv_update_reason;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_update_reason       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 4. リース開始日
    BEGIN
      gd_param_lease_start_date := TO_DATE(iv_lease_start_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_format_err     -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_lease_start_date    -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 5. リース終了日
    BEGIN
      gd_param_lease_end_date := TO_DATE(iv_lease_end_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_format_err     -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_lease_end_date      -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 6. 支払回数
    BEGIN
      gn_param_payment_frequency := iv_payment_frequency;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_payment_frequency   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 7. 契約日
    BEGIN
      gd_param_contract_date := TO_DATE(iv_contract_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_format_err     -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_contract_date       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 8. 初回支払日
    BEGIN
      gd_param_first_payment_date := TO_DATE(iv_first_payment_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_format_err     -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_first_payment_date  -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 9. ２回目支払日
    BEGIN
      gd_param_second_payment_date := TO_DATE(iv_second_payment_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_format_err     -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_second_payment_date -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 10.３回目以降支払日
    BEGIN
      gn_param_third_payment_date := iv_third_payment_date;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_third_payment_date  -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 11.件名
    BEGIN
      gv_param_comments := iv_comments;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_param_type_err      -- メッセージコード
                      ,iv_token_name1   => cv_tkn_input               -- トークンコード1
                      ,iv_token_value1  => cv_val_comments            -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- 存在チェック／対象データ取得
    -- ============================================
    -- リース契約ヘッダ情報の取得
    OPEN  g_cont_hdr_cur(
      iv_contract_number  =>  gv_param_contract_number  -- 契約番号
     ,iv_lease_company    =>  gv_param_lease_company    -- リース会社
    );
    FETCH g_cont_hdr_cur INTO  g_cont_hdr_rec;
    ln_db_cnt := g_cont_hdr_cur%ROWCOUNT;
    CLOSE g_cont_hdr_cur;
    --
    -- 対象データなし
    IF (ln_db_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                    ,iv_name          => cv_msg_data_notfound_err     -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 「リース開始日」／「リース終了日」相関チェック
    -- ============================================
    -- いずれも入力がある場合、エラー
    IF (    ( gd_param_lease_start_date IS NOT NULL )
       AND  ( gd_param_lease_end_date   IS NOT NULL ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                    ,iv_name          => cv_msg_lease_date_err        -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 「支払回数」妥当性チェック
    -- ============================================
    -- 支払回数に入力あり
    IF (gn_param_payment_frequency IS NOT NULL) THEN
--
      -- 頻度 ＝ 年の場合、支払回数 ＞ 50 でエラー
      IF (    ( g_cont_hdr_rec.payment_type = cv_payment_type_year )
         AND  ( gn_param_payment_frequency  > cn_max_payment_frequency_year ) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff                 -- アプリケーション短縮名
                      ,iv_name          => cv_msg_payment_frequency_err             -- メッセージコード
                      ,iv_token_name1   => cv_tkn_frequency                         -- トークンコード1
                      ,iv_token_value1  => TO_CHAR(cn_max_payment_frequency_year)   -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- 頻度 ＝ 月の場合、支払回数 ＞ 600 でエラー
      ELSIF (   ( g_cont_hdr_rec.payment_type = cv_payment_type_month )
            AND ( gn_param_payment_frequency  > cn_max_payment_frequency_month ) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff                 -- アプリケーション短縮名
                      ,iv_name          => cv_msg_payment_frequency_err             -- メッセージコード
                      ,iv_token_name1   => cv_tkn_frequency                         -- トークンコード1
                      ,iv_token_value1  => TO_CHAR(cn_max_payment_frequency_month)  -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      ELSE
        NULL;
      END IF;
    END IF;
--
-- Add 2013/02/27 Ver1.2 Start
    -- ============================================
    -- 「リース開始日」または「リース終了日」の導出
    -- ============================================
    -- 入力パラメータ「リース開始日」「リース終了日」「支払回数」のいずれか１つでも設定されている場合のみ
    IF ( ( gd_param_lease_start_date  IS NOT NULL )
      OR ( gd_param_lease_end_date    IS NOT NULL )
      OR ( gn_param_payment_frequency IS NOT NULL ) )
    THEN
      -- 入力パラメータ退避
      lt_param_lease_start_date := gd_param_lease_start_date;
      lt_param_lease_end_date   := gd_param_lease_end_date;
      --
      -- 入力パラメータ「リース開始日」≠NULLの場合
      IF ( gd_param_lease_start_date IS NOT NULL ) THEN
        -- リース終了日
        gd_param_lease_end_date := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                     WHEN cv_payment_type_month THEN     -- 月
                                       ( ADD_MONTHS(gd_param_lease_start_date, NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency)) - 1 )
                                     WHEN cv_payment_type_year  THEN     -- 年
                                       ( ADD_MONTHS(gd_param_lease_start_date, 12 * NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency)) - 1 )
                                   END;
      -- 入力パラメータ「リース開始日」＝NULLの場合
      ELSE
        --
        -- 入力パラメータ「支払回数」≠NULLの場合
        IF ( gn_param_payment_frequency IS NOT NULL ) THEN
          --
          -- 入力パラメータ「リース終了日」≠NULLの場合
          IF ( gd_param_lease_end_date IS NOT NULL ) THEN
            -- リース開始日
            gd_param_lease_start_date := CASE g_cont_hdr_rec.payment_type     -- 頻度
                                          WHEN cv_payment_type_month THEN     -- 月
                                            ( ADD_MONTHS(gd_param_lease_end_date, -1  * gn_param_payment_frequency) + 1 )
                                          WHEN cv_payment_type_year  THEN     -- 年
                                            ( ADD_MONTHS(gd_param_lease_end_date, -12 * gn_param_payment_frequency) + 1 )
                                         END;
          -- 入力パラメータ「リース終了日」＝NULLの場合
          ELSE
            -- リース開始日
            gd_param_lease_start_date := g_cont_hdr_rec.lease_start_date;
            -- リース終了日
            gd_param_lease_end_date   := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                           WHEN cv_payment_type_month THEN     -- 月
                                             ( ADD_MONTHS(gd_param_lease_start_date, gn_param_payment_frequency) - 1 )
                                           WHEN cv_payment_type_year  THEN     -- 年
                                             ( ADD_MONTHS(gd_param_lease_start_date, 12 * gn_param_payment_frequency) - 1 )
                                         END;
          END IF;
        -- 入力パラメータ「支払回数」＝NULLの場合
        ELSE
          --
          -- 入力パラメータ「リース終了日」≠NULLの場合
          IF ( gd_param_lease_end_date IS NOT NULL ) THEN
            -- リース開始日
            gd_param_lease_start_date := CASE g_cont_hdr_rec.payment_type     -- 頻度
                                          WHEN cv_payment_type_month THEN     -- 月
                                            ( ADD_MONTHS(gd_param_lease_end_date, -1  * g_cont_hdr_rec.payment_frequency) + 1 )
                                          WHEN cv_payment_type_year  THEN     -- 年
                                            ( ADD_MONTHS(gd_param_lease_end_date, -12 * g_cont_hdr_rec.payment_frequency) + 1 )
                                         END;
          -- 入力パラメータ「リース終了日」＝NULLの場合
          ELSE
            -- リース開始日
            gd_param_lease_start_date := g_cont_hdr_rec.lease_start_date;
            -- リース終了日
            gd_param_lease_end_date   := g_cont_hdr_rec.lease_end_date;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END IF;
-- Add 2013/02/27 Ver1.2 End
--
    -- ============================================
    -- 「リース契約日」妥当性チェック
    -- ============================================
    -- リース契約日に入力あり
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_contract_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
--
      -- リース契約日 ＞ 業務日付 の場合、エラー
      IF (gd_param_contract_date > gd_process_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_context_err    -- メッセージコード
                      ,iv_token_name1   => cv_tkn_date_object1        -- トークンコード1
                      ,iv_token_value1  => cv_val_contract_date       -- トークン値1
                      ,iv_token_name2   => cv_tkn_date_object2        -- トークンコード2
                      ,iv_token_value2  => cv_val_process_date        -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- リース契約日 ＞ リース開始日 の場合、エラー
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_contract_date >
      IF (NVL(gd_param_contract_date, g_cont_hdr_rec.contract_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_lease_start_date, g_cont_hdr_rec.lease_start_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_context_err    -- メッセージコード
                      ,iv_token_name1   => cv_tkn_date_object1        -- トークンコード1
                      ,iv_token_value1  => cv_val_contract_date       -- トークン値1
                      ,iv_token_name2   => cv_tkn_date_object2        -- トークンコード2
                      ,iv_token_value2  => cv_val_lease_start_date    -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- リース契約日 ＞ 初回支払日 の場合、エラー
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_contract_date >
      IF (NVL(gd_param_contract_date, g_cont_hdr_rec.contract_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_context_err    -- メッセージコード
                      ,iv_token_name1   => cv_tkn_date_object1        -- トークンコード1
                      ,iv_token_value1  => cv_val_contract_date       -- トークン値1
                      ,iv_token_name2   => cv_tkn_date_object2        -- トークンコード2
                      ,iv_token_value2  => cv_val_first_payment_date  -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
--
    -- ============================================
    -- 「初回支払日」妥当性チェック
    -- ============================================
    -- 初回支払日に入力あり
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_first_payment_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
-- Add 2013/02/27 Ver1.2 Start
    -- リース開始日 ＞ 初回支払日 の場合、エラー
    IF ( NVL(gd_param_lease_start_date, g_cont_hdr_rec.lease_start_date) >
           NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_date_context_err    -- メッセージコード
                    ,iv_token_name1   => cv_tkn_date_object1        -- トークンコード1
                    ,iv_token_value1  => cv_val_lease_start_date    -- トークン値1
                    ,iv_token_name2   => cv_tkn_date_object2        -- トークンコード2
                    ,iv_token_value2  => cv_val_first_payment_date  -- トークン値2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Add 2013/02/27 Ver1.2 End
--
      -- 初回支払日 ＞ ２回目支払日 の場合、エラー
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_first_payment_date >
      IF ( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_date_context_err    -- メッセージコード
                      ,iv_token_name1   => cv_tkn_date_object1        -- トークンコード1
                      ,iv_token_value1  => cv_val_first_payment_date  -- トークン値1
                      ,iv_token_name2   => cv_tkn_date_object2        -- トークンコード2
                      ,iv_token_value2  => cv_val_second_payment_date -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
--
    -- ============================================
    -- 「２回目支払日」妥当性チェック
    -- ============================================
    -- ２回目支払日に入力あり
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_second_payment_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
--
      -- 頻度 ＝ 月の場合
      IF (g_cont_hdr_rec.payment_type = cv_payment_type_month) THEN
--
        -- ２回目支払日が初回支払日の翌々月以降でエラー
-- Mod 2013/02/12 Ver1.1 Start
--        IF ( gd_param_second_payment_date >=
        IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) >=
-- Mod 2013/02/12 Ver1.1 End
               ADD_MONTHS( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date), 2 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff         -- アプリケーション短縮名
                        ,iv_name          => cv_msg_second_payment_date_err   -- メッセージコード
                        ,iv_token_name1   => cv_tkn_onward                    -- トークンコード1
                        ,iv_token_value1  => cv_val_two_months_after          -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
      -- 頻度 ＝ 年の場合
      ELSIF (g_cont_hdr_rec.payment_type = cv_payment_type_year) THEN
--
        -- ２回目支払日が初回支払日の翌年度以降でエラー
-- Mod 2013/02/12 Ver1.1 Start
--        IF ( gd_param_second_payment_date >=
        IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) >=
-- Mod 2013/02/12 Ver1.1 End
               ADD_MONTHS( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date), 12 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff         -- アプリケーション短縮名
                        ,iv_name          => cv_msg_second_payment_date_err   -- メッセージコード
                        ,iv_token_name1   => cv_tkn_onward                    -- トークンコード1
                        ,iv_token_value1  => cv_val_nex_year                  -- トークン値1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
      END IF;
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
-- Add 2013/02/27 Ver1.2 Start
    -- 支払回数＜3の場合
    IF ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) < cv_payment_frequency_3 ) THEN
      -- 最終支払日
      ld_last_payment_date := NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date);
    ELSE
      -- 月末日以外の場合
      IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) <>
             LAST_DAY(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date)) )
      THEN
        -- 最終支払日
        ld_last_payment_date := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                  WHEN cv_payment_type_month THEN     -- 月
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) )
                                  WHEN cv_payment_type_year  THEN     -- 年
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) * 12 ) )
                                END;
      --月末日
      ELSE
        -- 最終支払日
        ld_last_payment_date := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                  WHEN cv_payment_type_month THEN     -- 月
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) )
                                  WHEN cv_payment_type_year  THEN     -- 年
                                    ( LAST_DAY(ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) * 12 ) ) )
                                END;
      END IF;
      --
    END IF;
    --
    -- 最終支払日がリース終了日より後でエラー
    IF ( ld_last_payment_date > NVL(gd_param_lease_end_date, g_cont_hdr_rec.lease_end_date) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                    ,iv_name          => cv_msg_last_payment_date_err -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 入力パラメータ戻し
    gd_param_lease_start_date := lt_param_lease_start_date;
    gd_param_lease_end_date   := lt_param_lease_end_date;
-- Add 2013/02/27 Ver1.2 End
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END chk_input_param;
--
  /**********************************************************************************
   * Procedure Name   : upd_comments
   * Description      : 件名更新処理(A-3)
   ***********************************************************************************/
  PROCEDURE upd_comments(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_comments'; -- プログラム名
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
    ln_upd_cnt          NUMBER;           -- 更新件数
--
    -- *** ローカル・カーソル ***
--
    -- リース契約ヘッダロックカーソル
    CURSOR cont_hdr_lock_cur(
      in_contract_header_id   IN  NUMBER  -- 契約内部ID
    )
    IS
      SELECT  'X'
      FROM    xxcff_contract_headers  xch                     -- リース契約ヘッダ
      WHERE   xch.contract_header_id  = in_contract_header_id -- 契約内部ID
      FOR UPDATE NOWAIT
    ;
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
    -- 対象件数設定
    gn_target_cnt := 1;
--
    -- ============================================
    -- リース契約ヘッダロック
    -- ============================================
    BEGIN
      OPEN  cont_hdr_lock_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id    -- 契約内部ID
      );
      CLOSE cont_hdr_lock_cur;
    --
    EXCEPTION
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_data_lock_err         -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- リース契約ヘッダ.件名 更新
    -- ============================================
    BEGIN
      UPDATE  xxcff_contract_headers  -- リース契約ヘッダ
      SET     comments                = gv_param_comments         -- 件名
             ,last_updated_by         = cn_last_updated_by        -- 最終更新者
             ,last_update_date        = cd_last_update_date       -- 最終更新日
             ,last_update_login       = cn_last_update_login      -- 最終更新ログイン
             ,request_id              = cn_request_id             -- 要求ID
             ,program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
             ,program_id              = cn_program_id             -- コンカレント・プログラムID
             ,program_update_date     = cd_program_update_date    -- プログラム更新日
      WHERE   contract_header_id      = g_cont_hdr_rec.contract_header_id -- 契約内部ID
      ;
      -- 処理件数設定
      ln_upd_cnt    := SQL%ROWCOUNT;
      gn_normal_cnt := ln_upd_cnt;    -- 正常件数
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_update_err            -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                  -- トークンコード2
                      ,iv_token_value2  => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END upd_comments;
--
  /**********************************************************************************
   * Procedure Name   : submit_csv_conc
   * Description      : ＣＳＶ出力処理(A-4)
   ***********************************************************************************/
  PROCEDURE submit_csv_conc(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_csv_conc'; -- プログラム名
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
    ln_request_id             NUMBER;          -- 要求ID
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- ============================================
    -- ① リース契約データCSV出力 起動
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_contract_csv       -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. 契約番号
     ,argument2    => gv_param_lease_company    -- 2. リース会社
     ,argument3    => NULL                      -- 3. 物件コード1
     ,argument4    => NULL                      -- 4. 物件コード2
     ,argument5    => NULL                      -- 5. 物件コード3
     ,argument6    => NULL                      -- 6. 物件コード4
     ,argument7    => NULL                      -- 7. 物件コード5
     ,argument8    => NULL                      -- 8. 物件コード6
     ,argument9    => NULL                      -- 9. 物件コード7
     ,argument10   => NULL                      -- 10.物件コード8
     ,argument11   => NULL                      -- 11.物件コード9
     ,argument12   => NULL                      -- 12.物件コード10
    );
--
    -- 起動失敗
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_submit_err     -- メッセージコード
                    ,iv_token_name1   => cv_tkn_syori               -- トークンコード1
                    ,iv_token_value1  => cv_val_prg_contract_csv    -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- コンカレント待機失敗
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_wait_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント異常終了
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_proc_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ② リース物件データCSV出力 起動
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_object_csv         -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. 契約番号
     ,argument2    => gv_param_lease_company    -- 2. リース会社
     ,argument3    => NULL                      -- 3. 物件コード1
     ,argument4    => NULL                      -- 4. 物件コード2
     ,argument5    => NULL                      -- 5. 物件コード3
     ,argument6    => NULL                      -- 6. 物件コード4
     ,argument7    => NULL                      -- 7. 物件コード5
     ,argument8    => NULL                      -- 8. 物件コード6
     ,argument9    => NULL                      -- 9. 物件コード7
     ,argument10   => NULL                      -- 10.物件コード8
     ,argument11   => NULL                      -- 11.物件コード9
     ,argument12   => NULL                      -- 12.物件コード10
    );
--
    -- 起動失敗
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_submit_err     -- メッセージコード
                    ,iv_token_name1   => cv_tkn_syori               -- トークンコード1
                    ,iv_token_value1  => cv_val_prg_object_csv      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- コンカレント待機失敗
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_wait_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント異常終了
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_proc_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ③ リース支払計画データCSV出力 起動
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_pay_planning_csv   -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. 契約番号
     ,argument2    => gv_param_lease_company    -- 2. リース会社
     ,argument3    => NULL                      -- 3. 物件コード1
     ,argument4    => NULL                      -- 4. 物件コード2
     ,argument5    => NULL                      -- 5. 物件コード3
     ,argument6    => NULL                      -- 6. 物件コード4
     ,argument7    => NULL                      -- 7. 物件コード5
     ,argument8    => NULL                      -- 8. 物件コード6
     ,argument9    => NULL                      -- 9. 物件コード7
     ,argument10   => NULL                      -- 10.物件コード8
     ,argument11   => NULL                      -- 11.物件コード9
     ,argument12   => NULL                      -- 12.物件コード10
    );
--
    -- 起動失敗
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_submit_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_syori                 -- トークンコード1
                    ,iv_token_value1  => cv_val_prg_pay_planning_csv  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- コンカレント待機失敗
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_wait_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント異常終了
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_proc_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ④ リース会計基準情報CSV出力 起動
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_accounting_csv     -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. 契約番号
     ,argument2    => gv_param_lease_company    -- 2. リース会社
     ,argument3    => NULL                      -- 3. 物件コード1
     ,argument4    => NULL                      -- 4. 物件コード2
     ,argument5    => NULL                      -- 5. 物件コード3
     ,argument6    => NULL                      -- 6. 物件コード4
     ,argument7    => NULL                      -- 7. 物件コード5
     ,argument8    => NULL                      -- 8. 物件コード6
     ,argument9    => NULL                      -- 9. 物件コード7
     ,argument10   => NULL                      -- 10.物件コード8
     ,argument11   => NULL                      -- 11.物件コード9
     ,argument12   => NULL                      -- 12.物件コード10
    );
--
    -- 起動失敗
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_submit_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_syori                 -- トークンコード1
                    ,iv_token_value1  => cv_val_prg_accounting_csv    -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- コンカレント待機失敗
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_wait_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント異常終了
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_conc_proc_err       -- メッセージコード
                    ,iv_token_name1   => cv_tkn_request_id          -- トークンコード1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END submit_csv_conc;
--
  /**********************************************************************************
   * Procedure Name   : ins_bk_table
   * Description      : データバックアップ処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_bk_table(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bk_table'; -- プログラム名
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
    ln_run_line_num         xxcff_contract_headers_bk.run_line_num%TYPE;  -- 最大実行枝番＋１
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
    -- ============================================
    -- ① 「リース契約ヘッダ」バックアップ処理
    -- ============================================
--
    -- 実行会計期間，契約ごとの「最大実行枝番＋１」を取得
    SELECT  NVL(MAX(xchb.run_line_num), 0) + 1  AS  run_line_num          -- 実行枝番
    INTO    ln_run_line_num                                               -- 最大実行枝番＋１
    FROM    xxcff_contract_headers_bk   xchb                              -- リース契約ヘッダＢＫ
    WHERE   xchb.run_period_name      = gv_period_name                    -- 実行会計期間
    AND     xchb.contract_header_id   = g_cont_hdr_rec.contract_header_id -- 契約内部ID
    ;
--
    -- リース契約ヘッダＢＫ 登録処理
    BEGIN
      INSERT INTO xxcff_contract_headers_bk   -- リース契約ヘッダＢＫ
      (
        contract_header_id      -- 契約内部ID
       ,contract_number         -- 契約番号
       ,lease_class             -- リース種別
       ,lease_type              -- リース区分
       ,lease_company           -- リース会社
       ,re_lease_times          -- 再リース回数
       ,comments                -- 件名
       ,contract_date           -- リース契約日
       ,payment_frequency       -- 支払回数
       ,payment_type            -- 頻度
       ,payment_years           -- 年数
       ,lease_start_date        -- リース開始日
       ,lease_end_date          -- リース終了日
       ,first_payment_date      -- 初回支払日
       ,second_payment_date     -- 2回目支払日
       ,third_payment_date      -- 3回目以降支払日
       ,start_period_name       -- 費用計上開始会計期間
       ,lease_payment_flag      -- リース支払計画完了フラグ
       ,tax_code                -- 税金コード
       ,run_period_name         -- 実行会計期間
       ,run_line_num            -- 実行枝番
       ,created_by              -- 作成者
       ,creation_date           -- 作成日
       ,last_updated_by         -- 最終更新者
       ,last_update_date        -- 最終更新日
       ,last_update_login       -- 最終更新ログイン
       ,request_id              -- 要求ID
       ,program_application_id  -- コンカレント・プログラム・アプリケーションID
       ,program_id              -- コンカレント・プログラムID
       ,program_update_date     -- プログラム更新日
      )
      SELECT
          xch.contract_header_id        -- 契約内部ID
         ,xch.contract_number           -- 契約番号
         ,xch.lease_class               -- リース種別
         ,xch.lease_type                -- リース区分
         ,xch.lease_company             -- リース会社
         ,xch.re_lease_times            -- 再リース回数
         ,xch.comments                  -- 件名
         ,xch.contract_date             -- リース契約日
         ,xch.payment_frequency         -- 支払回数
         ,xch.payment_type              -- 頻度
         ,xch.payment_years             -- 年数
         ,xch.lease_start_date          -- リース開始日
         ,xch.lease_end_date            -- リース終了日
         ,xch.first_payment_date        -- 初回支払日
         ,xch.second_payment_date       -- 2回目支払日
         ,xch.third_payment_date        -- 3回目以降支払日
         ,xch.start_period_name         -- 費用計上開始会計期間
         ,xch.lease_payment_flag        -- リース支払計画完了フラグ
         ,xch.tax_code                  -- 税金コード
         ,gv_period_name                -- 実行会計期間
         ,ln_run_line_num               -- 実行枝番
         ,xch.created_by                -- 作成者
         ,xch.creation_date             -- 作成日
         ,xch.last_updated_by           -- 最終更新者
         ,xch.last_update_date          -- 最終更新日
         ,xch.last_update_login         -- 最終更新ログイン
         ,xch.request_id                -- 要求ID
         ,xch.program_application_id    -- コンカレント・プログラム・アプリケーションID
         ,xch.program_id                -- コンカレント・プログラムID
         ,xch.program_update_date       -- プログラム更新日
      FROM
          xxcff_contract_headers  xch   -- リース契約ヘッダ
      WHERE
          xch.contract_header_id  = g_cont_hdr_rec.contract_header_id   -- 契約内部ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_insert_err          -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name          -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_hdr_bk_tab_nm  -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                -- トークンコード2
                      ,iv_token_value2  => SQLERRM                    -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- ② 「リース契約明細」バックアップ処理
    -- ============================================
    BEGIN
      INSERT INTO xxcff_contract_lines_bk -- リース契約明細ＢＫ
      (
        contract_line_id              -- 契約明細内部ID
       ,contract_header_id            -- 契約内部ID
       ,contract_line_num             -- 契約枝番
       ,contract_status               -- 契約ステータス
       ,first_charge                  -- 初回月額リース料_リース料
       ,first_tax_charge              -- 初回消費税額_リース料
       ,first_total_charge            -- 初回計_リース料
       ,second_charge                 -- 2回目以降月額リース料_リース料
       ,second_tax_charge             -- 2回目以降消費税額_リース料
       ,second_total_charge           -- 2回目以降計_リース料
       ,first_deduction               -- 初回月額リース料_控除額
       ,first_tax_deduction           -- 初回月額消費税額_控除額
       ,first_total_deduction         -- 初回計_控除額
       ,second_deduction              -- 2回目以降月額リース料_控除額
       ,second_tax_deduction          -- 2回目以降消費税額_控除額
       ,second_total_deduction        -- 2回目以降計_控除額
       ,gross_charge                  -- 総額リース料_リース料
       ,gross_tax_charge              -- 総額消費税_リース料
       ,gross_total_charge            -- 総額計_リース料
       ,gross_deduction               -- 総額リース料_控除額
       ,gross_tax_deduction           -- 総額消費税_控除額
       ,gross_total_deduction         -- 総額計_控除額
       ,lease_kind                    -- リース種類
       ,estimated_cash_price          -- 見積現金購入価額
       ,present_value_discount_rate   -- 現在価値割引率
       ,present_value                 -- 現在価値
       ,life_in_months                -- 法定耐用年数
       ,original_cost                 -- 取得価額
       ,calc_interested_rate          -- 計算利子率
       ,object_header_id              -- 物件内部ID
       ,asset_category                -- 資産種類
       ,expiration_date               -- 満了日
       ,cancellation_date             -- 中途解約日
       ,vd_if_date                    -- リース契約情報連携日
       ,info_sys_if_date              -- リース管理情報連携日
       ,first_installation_address    -- 初回設置場所
       ,first_installation_place      -- 初回設置先
       ,run_period_name               -- 実行会計期間
       ,run_line_num                  -- 実行枝番
       ,created_by                    -- 作成者
       ,creation_date                 -- 作成日
       ,last_updated_by               -- 最終更新者
       ,last_update_date              -- 最終更新日
       ,last_update_login             -- 最終更新ログイン
       ,request_id                    -- 要求ID
       ,program_application_id        -- コンカレント・プログラム・アプリケーションID
       ,program_id                    -- コンカレント・プログラムID
       ,program_update_date           -- プログラム更新日
      )
      SELECT
          xcl.contract_line_id              -- 契約明細内部ID
         ,xcl.contract_header_id            -- 契約内部ID
         ,xcl.contract_line_num             -- 契約枝番
         ,xcl.contract_status               -- 契約ステータス
         ,xcl.first_charge                  -- 初回月額リース料_リース料
         ,xcl.first_tax_charge              -- 初回消費税額_リース料
         ,xcl.first_total_charge            -- 初回計_リース料
         ,xcl.second_charge                 -- 2回目以降月額リース料_リース料
         ,xcl.second_tax_charge             -- 2回目以降消費税額_リース料
         ,xcl.second_total_charge           -- 2回目以降計_リース料
         ,xcl.first_deduction               -- 初回月額リース料_控除額
         ,xcl.first_tax_deduction           -- 初回月額消費税額_控除額
         ,xcl.first_total_deduction         -- 初回計_控除額
         ,xcl.second_deduction              -- 2回目以降月額リース料_控除額
         ,xcl.second_tax_deduction          -- 2回目以降消費税額_控除額
         ,xcl.second_total_deduction        -- 2回目以降計_控除額
         ,xcl.gross_charge                  -- 総額リース料_リース料
         ,xcl.gross_tax_charge              -- 総額消費税_リース料
         ,xcl.gross_total_charge            -- 総額計_リース料
         ,xcl.gross_deduction               -- 総額リース料_控除額
         ,xcl.gross_tax_deduction           -- 総額消費税_控除額
         ,xcl.gross_total_deduction         -- 総額計_控除額
         ,xcl.lease_kind                    -- リース種類
         ,xcl.estimated_cash_price          -- 見積現金購入価額
         ,xcl.present_value_discount_rate   -- 現在価値割引率
         ,xcl.present_value                 -- 現在価値
         ,xcl.life_in_months                -- 法定耐用年数
         ,xcl.original_cost                 -- 取得価額
         ,xcl.calc_interested_rate          -- 計算利子率
         ,xcl.object_header_id              -- 物件内部ID
         ,xcl.asset_category                -- 資産種類
         ,xcl.expiration_date               -- 満了日
         ,xcl.cancellation_date             -- 中途解約日
         ,xcl.vd_if_date                    -- リース契約情報連携日
         ,xcl.info_sys_if_date              -- リース管理情報連携日
         ,xcl.first_installation_address    -- 初回設置場所
         ,xcl.first_installation_place      -- 初回設置先
         ,gv_period_name                    -- 実行会計期間
         ,ln_run_line_num                   -- 実行枝番
         ,xcl.created_by                    -- 作成者
         ,xcl.creation_date                 -- 作成日
         ,xcl.last_updated_by               -- 最終更新者
         ,xcl.last_update_date              -- 最終更新日
         ,xcl.last_update_login             -- 最終更新ログイン
         ,xcl.request_id                    -- 要求ID
         ,xcl.program_application_id        -- コンカレント・プログラム・アプリケーションID
         ,xcl.program_id                    -- コンカレント・プログラムID
         ,xcl.program_update_date           -- プログラム更新日
      FROM
          xxcff_contract_lines    xcl       -- リース契約明細
      WHERE
          xcl.contract_header_id  = g_cont_hdr_rec.contract_header_id   -- 契約内部ID
      AND xcl.contract_status     IN  ( cv_contract_status_contract
                                      , cv_contract_status_release )    -- 契約ステータス（契約, 再リース）
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_insert_err          -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name          -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_line_bk_tab_nm -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                -- トークンコード2
                      ,iv_token_value2  => SQLERRM                    -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- ③ 「リース支払計画」バックアップ処理
    -- ============================================
    BEGIN
      INSERT INTO xxcff_pay_planning_bk   -- リース支払計画ＢＫ
      (
        contract_line_id        -- 契約明細内部ID
       ,payment_frequency       -- 支払回数
       ,contract_header_id      -- 契約内部ID
       ,period_name             -- 会計期間
       ,payment_date            -- 支払日
       ,lease_charge            -- リース料
       ,lease_tax_charge        -- リース料_消費税
       ,lease_deduction         -- リース控除額
       ,lease_tax_deduction     -- リース控除額_消費税
       ,op_charge               -- ＯＰリース料
       ,op_tax_charge           -- ＯＰリース料額_消費税
       ,fin_debt                -- ＦＩＮリース債務額
       ,fin_tax_debt            -- ＦＩＮリース債務額_消費税
       ,fin_interest_due        -- ＦＩＮリース支払利息
       ,fin_debt_rem            -- ＦＩＮリース債務残
       ,fin_tax_debt_rem        -- ＦＩＮリース債務残_消費税
       ,accounting_if_flag      -- 会計ＩＦフラグ
       ,payment_match_flag      -- 照合済フラグ
       ,run_period_name         -- 実行会計期間
       ,run_line_num            -- 実行枝番
       ,created_by              -- 作成者
       ,creation_date           -- 作成日
       ,last_updated_by         -- 最終更新者
       ,last_update_date        -- 最終更新日
       ,last_update_login       -- 最終更新ログイン
       ,request_id              -- 要求ID
       ,program_application_id  -- コンカレント・プログラム・アプリケーションID
       ,program_id              -- コンカレント・プログラムID
       ,program_update_date     -- プログラム更新日
      )
      SELECT
          xpp.contract_line_id        -- 契約明細内部ID
         ,xpp.payment_frequency       -- 支払回数
         ,xpp.contract_header_id      -- 契約内部ID
         ,xpp.period_name             -- 会計期間
         ,xpp.payment_date            -- 支払日
         ,xpp.lease_charge            -- リース料
         ,xpp.lease_tax_charge        -- リース料_消費税
         ,xpp.lease_deduction         -- リース控除額
         ,xpp.lease_tax_deduction     -- リース控除額_消費税
         ,xpp.op_charge               -- ＯＰリース料
         ,xpp.op_tax_charge           -- ＯＰリース料額_消費税
         ,xpp.fin_debt                -- ＦＩＮリース債務額
         ,xpp.fin_tax_debt            -- ＦＩＮリース債務額_消費税
         ,xpp.fin_interest_due        -- ＦＩＮリース支払利息
         ,xpp.fin_debt_rem            -- ＦＩＮリース債務残
         ,xpp.fin_tax_debt_rem        -- ＦＩＮリース債務残_消費税
         ,xpp.accounting_if_flag      -- 会計ＩＦフラグ
         ,xpp.payment_match_flag      -- 照合済フラグ
         ,gv_period_name              -- 実行会計期間
         ,ln_run_line_num             -- 実行枝番
         ,xpp.created_by              -- 作成者
         ,xpp.creation_date           -- 作成日
         ,xpp.last_updated_by         -- 最終更新者
         ,xpp.last_update_date        -- 最終更新日
         ,xpp.last_update_login       -- 最終更新ログイン
         ,xpp.request_id              -- 要求ID
         ,xpp.program_application_id  -- コンカレント・プログラム・アプリケーションID
         ,xpp.program_id              -- コンカレント・プログラムID
         ,xpp.program_update_date     -- プログラム更新日
      FROM
          xxcff_pay_planning    xpp   -- リース支払計画
      WHERE
          EXISTS
            (  SELECT  'X'
               FROM    xxcff_contract_lines    xcl   -- リース契約明細
               WHERE   xcl.contract_line_id    = xpp.contract_line_id               -- 契約明細内部ID
               AND     xcl.contract_header_id  = g_cont_hdr_rec.contract_header_id  -- 契約内部ID
               AND     xcl.contract_status     IN  ( cv_contract_status_contract
                                                   , cv_contract_status_release )   -- 契約ステータス（契約, 再リース）
            )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                      ,iv_name          => cv_msg_insert_err          -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name          -- トークンコード1
                      ,iv_token_value1  => cv_val_pay_plan_bk_tab_nm -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                -- トークンコード2
                      ,iv_token_value2  => SQLERRM                    -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END ins_bk_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_headers
   * Description      : リース契約ヘッダ更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE upd_contract_headers(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_headers'; -- プログラム名
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
    ld_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;   -- リース開始日
    ln_payment_frequency      xxcff_contract_headers.payment_frequency%TYPE;  -- 支払回数
    ld_lease_end_date         xxcff_contract_headers.lease_end_date%TYPE;     -- リース終了日
    --
    ln_payment_years          xxcff_contract_headers.payment_years%TYPE;      -- 年数
--
    -- *** ローカル・カーソル ***
    -- リース契約ヘッダロックカーソル
    CURSOR cont_hdr_lock_cur(
      in_contract_header_id   IN  NUMBER  -- 契約内部ID
    )
    IS
      SELECT  'X'
      FROM    xxcff_contract_headers  xch                     -- リース契約ヘッダ
      WHERE   xch.contract_header_id  = in_contract_header_id -- 契約内部ID
      FOR UPDATE NOWAIT
    ;
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
    -- ============================================
    -- 更新値を変数に格納
    -- （リース開始日、支払回数、リース終了日）
    -- ============================================
--
    -- 入力パラメータ「リース開始日」≠NULLの場合
    IF (gd_param_lease_start_date IS NOT NULL) THEN
--
      -- 入力パラメータ「支払回数」≠NULLの場合
      IF (gn_param_payment_frequency IS NOT NULL) THEN
--
        -- リース開始日
        ld_lease_start_date  := gd_param_lease_start_date;
        -- 支払回数
        ln_payment_frequency := gn_param_payment_frequency;
        -- リース終了日
        ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                  WHEN cv_payment_type_month THEN     -- 月
                                    ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                  WHEN cv_payment_type_year  THEN     -- 年
                                    ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                END;
--
      -- 入力パラメータ「支払回数」＝NULLの場合
      ELSE
--
        -- リース開始日
        ld_lease_start_date  := gd_param_lease_start_date;
        -- 支払回数
        ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
        -- リース終了日
        ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                  WHEN cv_payment_type_month THEN     -- 月
                                    ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                  WHEN cv_payment_type_year  THEN     -- 年
                                    ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                END;
      END IF;
--
    -- 入力パラメータ「リース開始日」＝NULLの場合
    ELSE
--
      -- 入力パラメータ「支払回数」≠NULLの場合
      IF (gn_param_payment_frequency IS NOT NULL) THEN
--
        -- 入力パラメータ「リース終了日」≠NULLの場合
        IF (gd_param_lease_end_date IS NOT NULL) THEN
--
          -- リース開始日
          ld_lease_start_date  := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                    WHEN cv_payment_type_month THEN     -- 月
                                      ( ADD_MONTHS(gd_param_lease_end_date, -1  * gn_param_payment_frequency) + 1 )
                                    WHEN cv_payment_type_year  THEN     -- 年
                                      ( ADD_MONTHS(gd_param_lease_end_date, -12 * gn_param_payment_frequency) + 1 )
                                  END;
          -- 支払回数
          ln_payment_frequency := gn_param_payment_frequency;
          -- リース終了日
          ld_lease_end_date    := gd_param_lease_end_date;
--
        -- 入力パラメータ「リース終了日」＝NULLの場合
        ELSE
--
          -- リース開始日
          ld_lease_start_date  := g_cont_hdr_rec.lease_start_date;
          -- 支払回数
          ln_payment_frequency := gn_param_payment_frequency;
          -- リース終了日
          ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                    WHEN cv_payment_type_month THEN     -- 月
                                      ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                    WHEN cv_payment_type_year  THEN     -- 年
                                      ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                  END;
        END IF;
--
      -- 入力パラメータ「支払回数」＝NULLの場合
      ELSE
--
        -- 入力パラメータ「リース終了日」≠NULLの場合
        IF (gd_param_lease_end_date IS NOT NULL) THEN
--
          -- リース開始日
          ld_lease_start_date  := CASE g_cont_hdr_rec.payment_type      -- 頻度
                                    WHEN cv_payment_type_month THEN     -- 月
                                      ( ADD_MONTHS(gd_param_lease_end_date, -1  * g_cont_hdr_rec.payment_frequency) + 1 )
                                    WHEN cv_payment_type_year  THEN     -- 年
                                      ( ADD_MONTHS(gd_param_lease_end_date, -12 * g_cont_hdr_rec.payment_frequency) + 1 )
                                  END;
          -- 支払回数
          ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
          -- リース終了日
          ld_lease_end_date    := gd_param_lease_end_date;
--
        -- 入力パラメータ「リース終了日」＝NULLの場合
        ELSE
--
          -- リース開始日
          ld_lease_start_date  := g_cont_hdr_rec.lease_start_date;
          -- 支払回数
          ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
          -- リース終了日
          ld_lease_end_date    := g_cont_hdr_rec.lease_end_date;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ============================================
    -- 更新値を変数に格納（年数）
    -- ============================================
    -- 年数
    ln_payment_years := CASE g_cont_hdr_rec.payment_type    -- 頻度
                          WHEN cv_payment_type_month THEN   -- 月
                            CEIL(ln_payment_frequency / 12) -- 支払回数÷１２（小数点以下切り上げ）
                          WHEN cv_payment_type_year  THEN   -- 年
                            ln_payment_frequency            -- 支払回数
                        END;
--
--
    -- ============================================
    -- リース契約ヘッダロック処理
    -- ============================================
    BEGIN
      OPEN  cont_hdr_lock_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id    -- 契約内部ID
      );
      CLOSE cont_hdr_lock_cur;
    --
    EXCEPTION
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_data_lock_err         -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- リース契約ヘッダ 更新処理
    -- ============================================
    BEGIN
      UPDATE
          xxcff_contract_headers  -- リース契約ヘッダ
      SET
          comments                = NVL(gv_param_comments, comments)                        -- 件名
         ,contract_date           = NVL(gd_param_contract_date, contract_date)              -- リース契約日
         ,payment_frequency       = ln_payment_frequency                                    -- 支払回数
         ,payment_years           = ln_payment_years                                        -- 年数
         ,lease_start_date        = ld_lease_start_date                                     -- リース開始日
         ,lease_end_date          = ld_lease_end_date                                       -- リース終了日
         ,first_payment_date      = NVL(gd_param_first_payment_date,  first_payment_date)   -- 初回支払日
         ,second_payment_date     = NVL(gd_param_second_payment_date, second_payment_date)  -- 2回目支払日
         ,third_payment_date      = NVL(gn_param_third_payment_date,  third_payment_date)   -- 3回目以降支払日
         ,last_updated_by         = cn_last_updated_by                                      -- 最終更新者
         ,last_update_date        = cd_last_update_date                                     -- 最終更新日
         ,last_update_login       = cn_last_update_login                                    -- 最終更新ログイン
         ,request_id              = cn_request_id                                           -- 要求ID
         ,program_application_id  = cn_program_application_id                               -- コンカレント・プログラム・アプリケーションID
         ,program_id              = cn_program_id                                           -- コンカレント・プログラムID
         ,program_update_date     = cd_program_update_date                                  -- プログラム更新日
      WHERE
          contract_header_id      = g_cont_hdr_rec.contract_header_id -- 契約内部ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_update_err            -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                  -- トークンコード2
                      ,iv_token_value2  => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END upd_contract_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data
   * Description      : リース契約明細データ取得処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ============================================
    -- リース契約明細情報取得
    -- （リース契約明細ロックも行なう）
    -- ============================================
    BEGIN
      OPEN  g_cont_line_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id  -- 契約内部ID
      );
      FETCH g_cont_line_cur BULK COLLECT INTO g_cont_line_tab;
      CLOSE g_cont_line_cur;
    --
    EXCEPTION
      -- リース契約明細ロックエラー
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_data_lock_err         -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_line_tab_nm      -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 対象データなし
    IF (g_cont_line_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- アプリケーション短縮名
                    ,iv_name          => cv_msg_data_notfound_err       -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_lines
   * Description      : リース種類判定／リース契約明細更新処理(A-8)
   ***********************************************************************************/
  PROCEDURE upd_contract_lines(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_lines'; -- プログラム名
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
    ln_first_charge                 xxcff_contract_lines.first_charge%TYPE;   -- 初回月額リース料（控除後）
    ln_second_charge                xxcff_contract_lines.second_charge%TYPE;  -- ２回目以降月額リース料（控除後）
    ld_contract_ym                  DATE;                                     -- 契約年月
    --
    lv_lease_kind                   VARCHAR2(1000);    -- 8.リース種類
    ln_present_value_discount_rate  NUMBER;            -- 9.現在価値割引率
    ln_present_value                NUMBER;            -- 10.現在価値
    ln_original_cost                NUMBER;            -- 11.取得価額
    ln_calc_interested_rate         NUMBER;            -- 12.計算利子率
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
    -- ============================================
    -- 控除後リース料算出
    -- ============================================
    -- 初回月額リース料（控除後）
    ln_first_charge  := g_cont_line_tab(gn_rec_no).first_charge  - NVL(g_cont_line_tab(gn_rec_no).first_deduction, 0);
    -- ２回目以降月額リース料（控除後）
    ln_second_charge := g_cont_line_tab(gn_rec_no).second_charge - NVL(g_cont_line_tab(gn_rec_no).second_deduction, 0);
--
    -- ============================================
    -- 契約年月算出
    -- ============================================
    -- 契約年月 ＝ リース契約日の月初
    ld_contract_ym := TRUNC(g_cont_line_tab(gn_rec_no).contract_date, cv_trunc_format_month);
--
--
    -- ============================================
    -- リース種類判定処理
    -- ============================================
    XXCFF003A03C.main(
      iv_lease_type                  => g_cont_line_tab(gn_rec_no).lease_type           -- 1. リース区分（原契約，再リース契約）
     ,in_payment_frequency           => g_cont_line_tab(gn_rec_no).payment_frequency    -- 2. 支払回数
     ,in_first_charge                => ln_first_charge                                 -- 3. 初回月額リース料
     ,in_second_charge               => ln_second_charge                                -- 4. 2回目以降月額リース料
     ,in_estimated_cash_price        => g_cont_line_tab(gn_rec_no).estimated_cash_price -- 5. 見積現金購入価額
     ,in_life_in_months              => g_cont_line_tab(gn_rec_no).life_in_months       -- 6. 法定耐用年数
     ,id_contract_ym                 => ld_contract_ym                                  -- 7. 契約年月
     --
     ,ov_lease_kind                  => lv_lease_kind                                   -- 8. リース種類（Finリース，Opリース，旧Finリース）
     ,on_present_value_discount_rate => ln_present_value_discount_rate                  -- 9. 現在価値割引率
     ,on_present_value               => ln_present_value                                -- 10.現在価値
     ,on_original_cost               => ln_original_cost                                -- 11.取得価額
     ,on_calc_interested_rate        => ln_calc_interested_rate                         -- 12.計算利子率
     ,ov_errbuf                      => lv_errbuf                                       -- エラー・メッセージ
     ,ov_retcode                     => lv_retcode                                      -- リターン・コード
     ,ov_errmsg                      => lv_errmsg                                       -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg_common_err          -- メッセージコード
                    ,iv_token_name1   => cv_tkn_func_name           -- トークンコード1
                    ,iv_token_value1  => cv_val_api_nm_lease_kind   -- トークン値1
                   )
                || xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- アプリケーション短縮名
                    ,iv_name          => cv_msg                     -- メッセージコード
                    ,iv_token_name1   => cv_tkn_err_msg             -- トークンコード1
                    ,iv_token_value1  => lv_errbuf                  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- リース契約明細更新
    -- （リース種類判定結果の反映と金額情報の更新）
    -- ============================================
    BEGIN
      UPDATE
          xxcff_contract_lines        -- リース契約明細
      SET
          -- 総額リース料_リース料
          gross_charge                = first_charge + second_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          -- 総額消費税_リース料
         ,gross_tax_charge            = first_tax_charge + second_tax_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          -- 総額計_リース料
         ,gross_total_charge          = first_total_charge + second_total_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          --
         ,present_value               = ln_present_value                -- 現在価値
         ,original_cost               = ln_original_cost                -- 取得価額
         ,calc_interested_rate        = ln_calc_interested_rate         -- 計算利子率
         ,present_value_discount_rate = ln_present_value_discount_rate  -- 現在価値割引率
          --
         ,last_updated_by             = cn_last_updated_by              -- 最終更新者
         ,last_update_date            = cd_last_update_date             -- 最終更新日
         ,last_update_login           = cn_last_update_login            -- 最終更新ログイン
         ,request_id                  = cn_request_id                   -- 要求ID
         ,program_application_id      = cn_program_application_id       -- コンカレント・プログラム・アプリケーションID
         ,program_id                  = cn_program_id                   -- コンカレント・プログラムID
         ,program_update_date         = cd_program_update_date          -- プログラム更新日
      WHERE
          contract_header_id          = g_cont_line_tab(gn_rec_no).contract_header_id   -- 契約内部ID
      AND contract_line_id            = g_cont_line_tab(gn_rec_no).contract_line_id     -- 契約明細内部ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_update_err            -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_line_tab_nm      -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                  -- トークンコード2
                      ,iv_token_value2  => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END upd_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_contract_histories
   * Description      : リース契約明細履歴登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_contract_histories(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_contract_histories'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ============================================
    -- リース契約明細履歴登録
    -- ============================================
    BEGIN
      INSERT INTO xxcff_contract_histories  -- リース契約明細履歴
      (
        contract_header_id            -- 契約内部ID
       ,contract_line_id              -- 契約明細内部ID
       ,history_num                   -- 変更履歴NO
       ,contract_status               -- 契約ステータス
       ,first_charge                  -- 初回月額リース料_リース料
       ,first_tax_charge              -- 初回消費税額_リース料
       ,first_total_charge            -- 初回計_リース料
       ,second_charge                 -- 2回目以降月額リース料_リース料
       ,second_tax_charge             -- 2回目以降消費税額_リース料
       ,second_total_charge           -- 2回目以降計_リース料
       ,first_deduction               -- 初回月額リース料_控除額
       ,first_tax_deduction           -- 初回月額消費税額_控除額
       ,first_total_deduction         -- 初回計_控除額
       ,second_deduction              -- 2回目以降月額リース料_控除額
       ,second_tax_deduction          -- 2回目以降消費税額_控除額
       ,second_total_deduction        -- 2回目以降計_控除額
       ,gross_charge                  -- 総額リース料_リース料
       ,gross_tax_charge              -- 総額消費税_リース料
       ,gross_total_charge            -- 総額計_リース料
       ,gross_deduction               -- 総額リース料_控除額
       ,gross_tax_deduction           -- 総額消費税_控除額
       ,gross_total_deduction         -- 総額計_控除額
       ,lease_kind                    -- リース種類
       ,estimated_cash_price          -- 見積現金購入価額
       ,present_value_discount_rate   -- 現在価値割引率
       ,present_value                 -- 現在価値
       ,life_in_months                -- 法定耐用年数
       ,original_cost                 -- 取得価額
       ,calc_interested_rate          -- 計算利子率
       ,object_header_id              -- 物件内部ID
       ,asset_category                -- 資産種類
       ,expiration_date               -- 満了日
       ,cancellation_date             -- 中途解約日
       ,vd_if_date                    -- リース契約情報連携日
       ,info_sys_if_date              -- リース管理情報連携日
       ,first_installation_address    -- 初回設置場所
       ,first_installation_place      -- 初回設置先
       ,accounting_date               -- 計上日
       ,accounting_if_flag            -- 会計ＩＦフラグ
       ,description                   -- 摘要
       ,update_reason                 -- 更新事由
       ,period_name                   -- 会計期間
       ,created_by                    -- 作成者
       ,creation_date                 -- 作成日
       ,last_updated_by               -- 最終更新者
       ,last_update_date              -- 最終更新日
       ,last_update_login             -- 最終更新ログイン
       ,request_id                    -- 要求ID
       ,program_application_id        -- コンカレント・プログラム・アプリケーションID
       ,program_id                    -- コンカレント・プログラムID
       ,program_update_date           -- プログラム更新日
      )
      SELECT
          xcl.contract_header_id                -- 契約内部ID
         ,xcl.contract_line_id                  -- 契約明細内部ID
         ,xxcff_contract_histories_s1.NEXTVAL   -- 変更履歴NO
         ,cv_contract_status_maintenance        -- 契約ステータス（210：データメンテナンス）
         ,xcl.first_charge                      -- 初回月額リース料_リース料
         ,xcl.first_tax_charge                  -- 初回消費税額_リース料
         ,xcl.first_total_charge                -- 初回計_リース料
         ,xcl.second_charge                     -- 2回目以降月額リース料_リース料
         ,xcl.second_tax_charge                 -- 2回目以降消費税額_リース料
         ,xcl.second_total_charge               -- 2回目以降計_リース料
         ,xcl.first_deduction                   -- 初回月額リース料_控除額
         ,xcl.first_tax_deduction               -- 初回月額消費税額_控除額
         ,xcl.first_total_deduction             -- 初回計_控除額
         ,xcl.second_deduction                  -- 2回目以降月額リース料_控除額
         ,xcl.second_tax_deduction              -- 2回目以降消費税額_控除額
         ,xcl.second_total_deduction            -- 2回目以降計_控除額
         ,xcl.gross_charge                      -- 総額リース料_リース料
         ,xcl.gross_tax_charge                  -- 総額消費税_リース料
         ,xcl.gross_total_charge                -- 総額計_リース料
         ,xcl.gross_deduction                   -- 総額リース料_控除額
         ,xcl.gross_tax_deduction               -- 総額消費税_控除額
         ,xcl.gross_total_deduction             -- 総額計_控除額
         ,xcl.lease_kind                        -- リース種類
         ,xcl.estimated_cash_price              -- 見積現金購入価額
         ,xcl.present_value_discount_rate       -- 現在価値割引率
         ,xcl.present_value                     -- 現在価値
         ,xcl.life_in_months                    -- 法定耐用年数
         ,xcl.original_cost                     -- 取得価額
         ,xcl.calc_interested_rate              -- 計算利子率
         ,xcl.object_header_id                  -- 物件内部ID
         ,xcl.asset_category                    -- 資産種類
         ,xcl.expiration_date                   -- 満了日
         ,xcl.cancellation_date                 -- 中途解約日
         ,xcl.vd_if_date                        -- リース契約情報連携日
         ,xcl.info_sys_if_date                  -- リース管理情報連携日
         ,xcl.first_installation_address        -- 初回設置場所
         ,xcl.first_installation_place          -- 初回設置先
         ,gd_calendar_period_close_date         -- 計上日（リース台帳オープン期間のカレンダ終了日）
         ,cv_acct_if_flag_sent                  -- 会計ＩＦフラグ（2：送信済）
         ,NULL                                  -- 摘要
         ,gv_param_update_reason                -- 更新事由（パラメータ「更新事由」）
         ,gv_period_name                        -- 会計期間（リース台帳オープン期間）
         ,xcl.created_by                        -- 作成者
         ,xcl.creation_date                     -- 作成日
         ,xcl.last_updated_by                   -- 最終更新者
         ,xcl.last_update_date                  -- 最終更新日
         ,xcl.last_update_login                 -- 最終更新ログイン
         ,xcl.request_id                        -- 要求ID
         ,xcl.program_application_id            -- コンカレント・プログラム・アプリケーションID
         ,xcl.program_id                        -- コンカレント・プログラムID
         ,xcl.program_update_date               -- プログラム更新日
      FROM
          xxcff_contract_lines    xcl           -- リース契約明細
      WHERE
          xcl.contract_header_id  = g_cont_line_tab(gn_rec_no).contract_header_id   -- 契約内部ID
      AND xcl.contract_line_id    = g_cont_line_tab(gn_rec_no).contract_line_id     -- 契約明細内部ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff       -- アプリケーション短縮名
                      ,iv_name          => cv_msg_insert_err              -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name              -- トークンコード1
                      ,iv_token_value1  => cv_val_cont_line_hist_tab_nm   -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                    -- トークンコード2
                      ,iv_token_value2  => SQLERRM                        -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END ins_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : create_pay_planning
   * Description      : 支払計画再作成／フラグ更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE create_pay_planning(
    ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_pay_planning'; -- プログラム名
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
    lv_payment_match_flag       xxcff_pay_planning.payment_match_flag%TYPE; -- 照合済フラグ（現会計期間）
    --
    lv_str_contract_line_id     VARCHAR2(100);
    lv_str_period_name          VARCHAR2(100);
    lv_error_key                VARCHAR2(5000);
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
    -- ============================================
    -- オープン期間の支払計画.照合済フラグを退避
    -- ============================================
    BEGIN
      SELECT  xpp.payment_match_flag  AS  payment_match_flag  -- 照合済フラグ
      INTO    lv_payment_match_flag                           -- 照合済フラグ（現会計期間）
      FROM    xxcff_pay_planning      xpp                     -- リース支払計画
      WHERE   xpp.contract_line_id    = g_cont_line_tab(gn_rec_no).contract_line_id -- 契約明細内部ID
      AND     xpp.period_name         = gv_period_name                              -- 会計期間
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- オープン期間の支払計画データが存在しない場合も処理続行
        lv_payment_match_flag := NULL;
    END;
--
    -- ============================================
    -- 支払計画作成処理
    -- ============================================
    XXCFF003A05C.main(
      iv_shori_type       => cv_pay_plan_shori_type_create                -- 1.処理区分
     ,in_contract_line_id => g_cont_line_tab(gn_rec_no).contract_line_id  -- 2.契約明細内部ID
     ,ov_errbuf           => lv_errbuf                                    -- エラー・メッセージ
     ,ov_retcode          => lv_retcode                                   -- リターン・コード
     ,ov_errmsg           => lv_errmsg                                    -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- アプリケーション短縮名
                    ,iv_name          => cv_msg_common_err              -- メッセージコード
                    ,iv_token_name1   => cv_tkn_func_name               -- トークンコード1
                    ,iv_token_value1  => cv_val_api_nm_create_pay_plan  -- トークン値1
                   )
                || xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- アプリケーション短縮名
                    ,iv_name          => cv_msg                         -- メッセージコード
                    ,iv_token_name1   => cv_tkn_err_msg                 -- トークンコード1
                    ,iv_token_value1  => lv_errbuf                      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 支払計画「会計ＩＦフラグ」「照合済フラグ」更新処理
    -- ============================================
--
    -- オープン期間の支払計画データが存在する場合
    IF (lv_payment_match_flag IS NOT NULL) THEN
--
      -- ①オープン期間の支払計画更新
      BEGIN
        UPDATE
            xxcff_pay_planning      -- リース支払計画
        SET
            accounting_if_flag      = cv_acct_if_flag_not_send  -- 会計ＩＦフラグ（1：未送信）
           ,payment_match_flag      = lv_payment_match_flag     -- 照合済フラグ（更新前の値）
           ,last_updated_by         = cn_last_updated_by        -- 最終更新者
           ,last_update_date        = cd_last_update_date       -- 最終更新日
           ,last_update_login       = cn_last_update_login      -- 最終更新ログイン
           ,request_id              = cn_request_id             -- 要求ID
           ,program_application_id  = cn_program_application_id -- コンカレント・プログラム・アプリケーションID
           ,program_id              = cn_program_id             -- コンカレント・プログラムID
           ,program_update_date     = cd_program_update_date    -- プログラム更新日
        WHERE
            contract_line_id        = g_cont_line_tab(gn_rec_no).contract_line_id -- 契約明細内部ID
        AND period_name             = gv_period_name                              -- 会計期間（オープン期間）
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                        ,iv_name          => cv_msg_update_err            -- メッセージコード
                        ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                        ,iv_token_value1  => cv_val_pay_plan_tab_nm       -- トークン値1
                        ,iv_token_name2   => cv_tkn_info                  -- トークンコード2
                        ,iv_token_value2  => SQLERRM                      -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END IF;
--
    -- ②オープン期間より前の支払計画更新
    BEGIN
      UPDATE
          xxcff_pay_planning      -- リース支払計画
      SET
          accounting_if_flag      = cv_acct_if_flag_sent          -- 会計ＩＦフラグ（2：送信済）
         ,payment_match_flag      = cv_payment_match_flag_matched -- 照合済フラグ（1：照合済）
         ,last_updated_by         = cn_last_updated_by            -- 最終更新者
         ,last_update_date        = cd_last_update_date           -- 最終更新日
         ,last_update_login       = cn_last_update_login          -- 最終更新ログイン
         ,request_id              = cn_request_id                 -- 要求ID
         ,program_application_id  = cn_program_application_id     -- コンカレント・プログラム・アプリケーションID
         ,program_id              = cn_program_id                 -- コンカレント・プログラムID
         ,program_update_date     = cd_program_update_date        -- プログラム更新日
      WHERE
          contract_line_id        = g_cont_line_tab(gn_rec_no).contract_line_id -- 契約明細内部ID
      AND period_name             < gv_period_name                              -- 会計期間（オープン期間より前）
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- アプリケーション短縮名
                      ,iv_name          => cv_msg_update_err            -- メッセージコード
                      ,iv_token_name1   => cv_tkn_table_name            -- トークンコード1
                      ,iv_token_value1  => cv_val_pay_plan_tab_nm       -- トークン値1
                      ,iv_token_name2   => cv_tkn_info                  -- トークンコード2
                      ,iv_token_value2  => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END create_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_contract_number      IN  VARCHAR2    -- 1. 契約番号  （必須）
   ,iv_lease_company        IN  VARCHAR2    -- 2. リース会社（必須）
   ,iv_update_reason        IN  VARCHAR2    -- 3. 更新事由  （必須）
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. リース開始日
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. リース終了日
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. 支払回数
   ,iv_contract_date        IN  VARCHAR2    -- 7. 契約日
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. 初回支払日
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. ２回目支払日
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.３回目以降支払日
   ,iv_comments             IN  VARCHAR2    -- 11.件名
   ,ov_errbuf               OUT VARCHAR2    --    エラー・メッセージ           --# 固定 #
   ,ov_retcode              OUT VARCHAR2    --    リターン・コード             --# 固定 #
   ,ov_errmsg               OUT VARCHAR2)   --    ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;   -- 対象件数
    gn_normal_cnt := 0;   -- 正常件数
    gn_error_cnt  := 0;   -- エラー件数
    gn_warn_cnt   := 0;   -- スキップ件数
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
       iv_contract_number     =>  iv_contract_number      -- 1. 契約番号
      ,iv_lease_company       =>  iv_lease_company        -- 2. リース会社
      ,iv_update_reason       =>  iv_update_reason        -- 3. 更新事由
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. リース開始日
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. リース終了日
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. 支払回数
      ,iv_contract_date       =>  iv_contract_date        -- 7. 契約日
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. 初回支払日
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. ２回目支払日
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.３回目以降支払日
      ,iv_comments            =>  iv_comments             -- 11.件名
      ,ov_errbuf              =>  lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             =>  lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg              =>  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- 入力パラメータチェック処理(A-2)
    -- ===============================================
    chk_input_param(
       iv_contract_number     =>  iv_contract_number      -- 1. 契約番号
      ,iv_lease_company       =>  iv_lease_company        -- 2. リース会社
      ,iv_update_reason       =>  iv_update_reason        -- 3. 更新事由
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. リース開始日
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. リース終了日
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. 支払回数
      ,iv_contract_date       =>  iv_contract_date        -- 7. 契約日
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. 初回支払日
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. ２回目支払日
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.３回目以降支払日
      ,iv_comments            =>  iv_comments             -- 11.件名
      ,ov_errbuf              =>  lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             =>  lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg              =>  lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- 「件名」のみのデータメンテナンスの場合
    IF (  gd_param_lease_start_date     IS NULL       -- 4. リース開始日
      AND gd_param_lease_end_date       IS NULL       -- 5. リース終了日
      AND gn_param_payment_frequency    IS NULL       -- 6. 支払回数
      AND gd_param_contract_date        IS NULL       -- 7. 契約日
      AND gd_param_first_payment_date   IS NULL       -- 8. 初回支払日
      AND gd_param_second_payment_date  IS NULL       -- 9. ２回目支払日
      AND gn_param_third_payment_date   IS NULL       -- 10.３回目以降支払日
      AND gv_param_comments             IS NOT NULL   -- 11.件名
    )
    THEN
--
      -- ===============================================
      -- 件名更新処理(A-3)
      -- ===============================================
      upd_comments(
        ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSE
        -- 更新に成功した場合、以降の処理は行なわずプログラムを終了する
        RETURN;
      END IF;
    END IF;
--
--
    -- ===============================================
    -- ＣＳＶ出力処理（メンテナンス実施前）(A-4)
    -- ===============================================
    submit_csv_conc(
      ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- データバックアップ処理(A-5)
    -- ===============================================
    ins_bk_table(
      ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- リース契約ヘッダ更新処理(A-6)
    -- ===============================================
    upd_contract_headers(
      ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- リース契約明細データ取得処理(A-7)
    -- ===============================================
    get_contract_data(
      ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数格納
    gn_target_cnt := g_cont_line_tab.COUNT;
--
--
    -- リース契約明細データループ
    <<contract_line_loop>>
    FOR i IN 1..g_cont_line_tab.COUNT LOOP
--
      -- カウンタをグローバル変数に格納
      gn_rec_no := i;
--
      -- ===============================================
      -- リース種類判定／リース契約明細更新処理(A-8)
      -- ===============================================
      upd_contract_lines(
        ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- リース契約明細履歴登録処理(A-9)
      -- ===============================================
      ins_contract_histories(
        ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- 支払計画再作成／フラグ更新処理(A-10)
      -- ===============================================
      create_pay_planning(
        ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
       ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
       ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP contract_line_loop;
--
--
    -- ===============================================
    -- ＣＳＶ出力処理（メンテナンス実施後）(A-11)
    -- ===============================================
    submit_csv_conc(
      ov_errbuf   => lv_errbuf    --   エラー・メッセージ           --# 固定 #
     ,ov_retcode  => lv_retcode   --   リターン・コード             --# 固定 #
     ,ov_errmsg   => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
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
    errbuf                  OUT VARCHAR2,   --    エラー・メッセージ  --# 固定 #
    retcode                 OUT VARCHAR2,   --    リターン・コード    --# 固定 #
    iv_contract_number      IN  VARCHAR2,   -- 1. 契約番号  （必須）
    iv_lease_company        IN  VARCHAR2,   -- 2. リース会社（必須）
    iv_update_reason        IN  VARCHAR2,   -- 3. 更新事由  （必須）
    iv_lease_start_date     IN  VARCHAR2,   -- 4. リース開始日
    iv_lease_end_date       IN  VARCHAR2,   -- 5. リース終了日
    iv_payment_frequency    IN  VARCHAR2,   -- 6. 支払回数
    iv_contract_date        IN  VARCHAR2,   -- 7. 契約日
    iv_first_payment_date   IN  VARCHAR2,   -- 8. 初回支払日
    iv_second_payment_date  IN  VARCHAR2,   -- 9. ２回目支払日
    iv_third_payment_date   IN  VARCHAR2,   -- 10.３回目以降支払日
    iv_comments             IN  VARCHAR2    -- 11.件名
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
       iv_which   => cv_which_log
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
       iv_contract_number     =>  iv_contract_number      -- 1. 契約番号
      ,iv_lease_company       =>  iv_lease_company        -- 2. リース会社
      ,iv_update_reason       =>  iv_update_reason        -- 3. 更新事由
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. リース開始日
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. リース終了日
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. 支払回数
      ,iv_contract_date       =>  iv_contract_date        -- 7. 契約日
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. 初回支払日
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. ２回目支払日
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.３回目以降支払日
      ,iv_comments            =>  iv_comments             -- 11.件名
      ,ov_errbuf              =>  lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             =>  lv_retcode    -- リターン・コード             --# 固定 #
      ,ov_errmsg              =>  lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理(A-12)
    -- ===============================================
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー件数（固定値：1）
      gn_error_cnt := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
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
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
    FND_FILE.PUT_LINE(
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
END XXCFF016A35C;
/
