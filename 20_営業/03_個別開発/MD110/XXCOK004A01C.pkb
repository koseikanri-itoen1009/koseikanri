CREATE OR REPLACE PACKAGE BODY XXCOK004A01C
AS
 /*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK004A01C(body)
 * Description      : 顧客移行日に顧客マスタの釣銭金額に基づき仕訳情報を作成します。
 * MD.050           : VD釣銭の振替仕訳作成 (MD050_COK_004_A01)
 * Version          : 1.3
 *
 * Program List
 * ----------------------- ----------------------------------------------------------
 *  Name                    Description
 * ----------------------- ----------------------------------------------------------
 *  init                    初期処理                        (A-1)
 *  get_cust_shift_info     顧客移行情報取得                (A-2)
 *  lock_cust_shift_info    顧客移行情報ロック取得          (A-3)
 *  distinct_target_cust_f  振替仕訳作成対象顧客判別        (A-4)
 *  chk_acctg_target        会計期間チェック                (A-5)
 *  get_gl_data_info        GL連携データ付加情報の取得      (A-6)
 *  ins_gl_oif              一般会計OIF登録                 (A-7)
 *  upd_cust_shift_info     顧客移行情報更新                (A-8)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   K.Motohashi      新規作成
 *  2009/02/02    1.1   K.Suenaga        [障害COK_002]夜バッチ対応/言語取得
 *  2009/06/09    1.2   K.Yamaguchi      [障害T1_1335]貸借逆修正
 *  2009/10/06    1.3   S.Moriyama       [障害E_T3_00632]伝票入力者対応
 * 
 *****************************************************************************************/
-- ====================
-- グローバル定数宣言部
-- ====================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCOK004A01C';                      -- パッケージ名
--
  --ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warning           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- 異常:2
--
  --WHOカラム
  cn_created_by               CONSTANT NUMBER        := fnd_global.user_id;                  -- 作成者のユーザーID
  cn_last_updated_by          CONSTANT NUMBER        := fnd_global.user_id;                  -- 最終更新者のユーザーID
  cn_last_update_login        CONSTANT NUMBER        := fnd_global.login_id;                 -- 最終更新者のログインID
  cn_request_id               CONSTANT NUMBER        := fnd_global.conc_request_id;          -- 要求ID
  cn_program_application_id   CONSTANT NUMBER        := fnd_global.prog_appl_id;             -- コンカレントアプリID
  cn_program_id               CONSTANT NUMBER        := fnd_global.conc_program_id;          -- コンカレントID
--
  -- *** 定数(メッセージ) ***
  cv_msg_ccp1_90000           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';                  -- 対象件数出力
  cv_msg_ccp1_90001           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';                  -- 成功件数出力
  cv_msg_ccp1_90002           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';                  -- エラー件数出力
  cv_msg_ccp1_90004           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_ccp1_90005           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';                  -- 警告終了メッセージ
  cv_msg_ccp1_90006           CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';                  -- エラー終了メッセージ
  cv_msg_cok1_00003           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';                  -- プロファイル値取得不可
  cv_msg_cok1_00008           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00008';                  -- 会計帳簿情報取得不可エラー
  cv_msg_cok1_00011           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00011';                  -- 会計カレンダ取得不可
  cv_msg_cok1_00024           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00024';                  -- グループID取得エラー
  cv_msg_cok1_00025           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00025';                  -- 伝票番号取得エラー
  cv_msg_cok1_00028           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';                  -- 業務処理日付取得エラー
  cv_msg_cok1_00049           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00049';                  -- ロック取得エラー
  cv_msg_cok1_10208           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10208';                  -- 会計期間クローズエラー
  cv_msg_cok1_10386           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10386';                  -- 釣銭仕訳作成対象外件数出力
  cv_msg_cok1_00078           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00078';                  -- システム稼働日取得エラー
  cv_msg_cok1_00076           CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00076';                  -- 起動区分出力用メッセージ
--
  -- *** 定数(プロファイル) ***
  cv_prof_company_code        CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';          -- 会社コード
  cv_prof_aff3_change         CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF3_CHANGE';                -- 勘定科目_仮払金（釣銭)
  cv_prof_subacct_dummy       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF4_SUBACCT_DUMMY';         -- 補助科目_ダミー値
  cv_prof_company_dummy       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF6_COMPANY_DUMMY';         -- 企業コード_ダミー値
  cv_prof_preliminary1_dummy  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';    -- 予備コード１_ダミー値
  cv_prof_preliminary2_dummy  CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';    -- 予備コード2_ダミー値
  cv_prof_gl_category_change  CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_CATEGORY_CHANGE';         -- 仕訳カテゴリ_釣銭振替
  cv_prof_gl_source_cok       CONSTANT VARCHAR2(50)  := 'XXCOK1_GL_SOURCE_COK';              -- 仕訳ソース_個別開発
  cv_prof_aff2_dept_fin       CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF2_DEPT_FIN';              -- 部門コード_財務経理部
--
  -- *** 定数(アプリケーション短縮名) ***
  cv_appl_name_sqlgl          CONSTANT VARCHAR2(5)   := 'SQLGL';                             -- SQLGL
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                             -- XXCCP
  cv_appl_name_xxcok          CONSTANT VARCHAR2(10)  := 'XXCOK';                             -- XXCOK
--
  -- *** 定数(トークン) ***
  cv_tkn_output               CONSTANT VARCHAR2(10)  := 'OUTPUT';                            -- OUTPUT
  cv_tkn_cust_code            CONSTANT VARCHAR2(10)  := 'CUST_CODE';                         -- CUST_CODE
  cv_tkn_period               CONSTANT VARCHAR2(10)  := 'PERIOD';                            -- PERIOD
  cv_tkn_profile              CONSTANT VARCHAR2(10)  := 'PROFILE';                           -- PROFILE
  cv_tkn_errmsg               CONSTANT VARCHAR2(10)  := 'ERRMSG';                            -- ERRMSG
  cv_tkn_count                CONSTANT VARCHAR2(10)  := 'COUNT';                             -- COUNT
  cv_tkn_proc_date            CONSTANT VARCHAR2(10)  := 'PROC_DATE';                         -- PROC_DATE
  cv_tkn_process_flag         CONSTANT VARCHAR2(12)  := 'PROCESS_FLAG';                      -- PROCESS_FLAG
--
  -- *** 定数(セパレータ) ***
  cv_msg_part                 CONSTANT VARCHAR2(3)   := ' : ';                               -- コロン
  cv_msg_cont                 CONSTANT VARCHAR2(3)   := '.';                                 -- ドット
--
  -- *** 定数(数値) ***
  cn_number_0                 CONSTANT NUMBER        := 0;                                   -- 0
  cn_number_1                 CONSTANT NUMBER        := 1;                                   -- 1
--
  -- *** 定数(取得レコード数) ***
  cn_rownum_0                 CONSTANT NUMBER        := 0;                                   -- 0
  cn_rownum_1                 CONSTANT NUMBER        := 1;                                   -- 1
--
  -- *** 定数(調整期間フラグ) ***
  cv_adjust_flag_n            CONSTANT VARCHAR2(1)   := 'N';                                 -- N
--
  -- *** 定数(一般会計OIF登録値) ***
  cv_glif_status              CONSTANT VARCHAR2(3)   := 'NEW';                               -- ステータス
  cv_glif_actual_flag         CONSTANT VARCHAR2(1)   := 'A';                                 -- 残高タイプ
--
  -- *** 定数(釣銭仕訳作成フラグ) ***
  cv_chg_je_flag_yet          CONSTANT VARCHAR2(1)   := '0';                                 -- 未作成
  cv_chg_je_flag_finish       CONSTANT VARCHAR2(1)   := '1';                                 -- 作成済
  cv_chg_je_flag_out          CONSTANT VARCHAR2(1)   := '2';                                 -- 対象外
--
  -- *** 定数(顧客移行情報のステータス) ***
  cv_xcsi_status_desist       CONSTANT VARCHAR2(1)   := 'A';                                 -- 確定
--
  -- *** 定数(会計期間のステータス) ***
  cv_closing_status_o         CONSTANT VARCHAR2(1)   := 'O';                                 -- O
--
  -- *** 定数(参照タイプ) ***
  cv_lt_glif_chng_vd          CONSTANT VARCHAR2(30)  := 'XXCOK1_GLIF_CHANGE_VD';             -- 釣銭振替仕訳対象顧客
  cv_lt_glif_chng_status      CONSTANT VARCHAR2(30)  := 'XXCOK1_GLIF_CHANGE_STATUS';         -- 釣銭振替仕訳対象ステータス
  cv_lt_enabled_flag_y        CONSTANT VARCHAR2(1)   := 'Y';                                 -- 有効フラグ'Y'
--
  -- *** 定数(ブール型の値) ***
  cb_bool_true                CONSTANT BOOLEAN       := TRUE;                                -- TRUE
  cb_bool_false               CONSTANT BOOLEAN       := FALSE;                               -- FALSE
--
  -- *** 定数(起動区分)  ***
  cv_normal_type              CONSTANT VARCHAR2(1)   := '1';                                 -- 起動区分(通常起動)
  --*** 稼動日取得関数 ***
  cn_cal_type_one             CONSTANT NUMBER        := 1;   -- カレンダー区分(システム稼働日カレンダー)
  cn_aft                      CONSTANT NUMBER        := 2;   -- 処理区分(2)
  cn_plus_days                CONSTANT NUMBER        := 1;   -- 日数
-- ==============
-- 共通例外宣言部
-- ==============
  --*** 処理部共通例外 ***
  global_process_expt        EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt            EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt     EXCEPTION;
  --*** ロック取得例外 ***
  global_resouce_busy_expt   EXCEPTION;
--
  -- ========
  -- プラグマ
  -- ========
  --*** 共通関数例外 ***
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ロック取得例外 ***
  PRAGMA EXCEPTION_INIT( global_resouce_busy_expt, -54 );
--
  -- ==============
  -- グローバル変数
  -- ==============
  gn_target_cnt               NUMBER         DEFAULT NULL;  -- 対象件数
  gn_normal_cnt               NUMBER         DEFAULT NULL;  -- 正常件数
  gn_warning_cnt              NUMBER         DEFAULT NULL;  -- 警告件数
  gn_error_cnt                NUMBER         DEFAULT NULL;  -- エラー件数
  gn_off_chg_je_cnt           NUMBER         DEFAULT NULL;  -- 釣銭仕訳作成対象外件数
--
  gv_prof_company_code        VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：会社コード
  gv_prof_aff3_change         VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：仮払金（釣銭）勘定科目
  gv_prof_subacct_dummy       VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：補助科目のダミー値
  gv_prof_company_dummy       VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：企業コードのダミー値
  gv_prof_preliminary1_dummy  VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：予備１のダミー値
  gv_prof_preliminary2_dummy  VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：予備2のダミー値
  gv_prof_category_change     VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：釣銭振替の仕訳カテゴリ
  gv_prof_source_cok          VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：個別開発の仕訳ソース
  gv_prof_aff2_dept_fin       VARCHAR2(50)   DEFAULT NULL;  -- プロファイル：財務経理部の部門コード
--
  gd_process_date             DATE           DEFAULT NULL;  -- 業務処理日付
  gn_set_of_books_id          NUMBER         DEFAULT NULL;  -- 会計帳簿ID
  gv_set_of_books_name        VARCHAR2(15)   DEFAULT NULL;  -- 会計帳簿名
  gn_chart_acct_id            NUMBER(15)     DEFAULT NULL;  -- 勘定体系ID
  gv_period_set_name          VARCHAR2(15)   DEFAULT NULL;  -- カレンダ名
  gn_aff_segment_cnt          NUMBER         DEFAULT NULL;  -- AFFセグメント定義数
  gv_currency_code            VARCHAR2(15)   DEFAULT NULL;  -- 機能通貨コード
  gv_batch_name               VARCHAR2(100)  DEFAULT NULL;  -- バッチ名
  gv_group_id                 VARCHAR2(150)  DEFAULT NULL;  -- グループID
--
  -- ==============================
  -- ユーザー定義グローバルカーソル
  -- 顧客移行情報取得カーソル(A-2)
  -- ==============================
  CURSOR get_cust_info_cur(
    id_process_date  IN DATE )
  IS
    SELECT xcsi.cust_shift_id     AS xcsi_cust_shift_id         -- 顧客移行情報ID
         , xcsi.prev_base_code    AS xcsi_prev_base_code        -- 旧担当拠点
         , xcsi.new_base_code     AS xcsi_new_base_code         -- 新担当拠点
         , xcsi.cust_code         AS xcsi_cust_code             -- 顧客コード
         , xcsi.cust_shift_date   AS xcsi_cust_shift_date       -- 顧客移行日
         , xca.change_amount      AS xca_change_amount          -- 釣銭
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD START
         , xcsi.emp_code          AS xcsi_emp_code              -- 顧客移行登録従業員
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama ADD END
      FROM xxcok_cust_shift_info  xcsi                          -- 顧客移行情報テーブル
         , hz_cust_accounts       hca                           -- 顧客マスタ
         , xxcmm_cust_accounts    xca                           -- 顧客マスタアドオン
     WHERE xcsi.status             =  cv_xcsi_status_desist     -- ステータス='A'
       AND xcsi.cust_shift_date    <= TRUNC( id_process_date )  -- 顧客移行日=業務処理日付
       AND xcsi.create_chg_je_flag =  cv_chg_je_flag_yet        -- 釣銭仕訳作成フラグ=未作成
       AND xcsi.cust_code          =  hca.account_number        -- 顧客コード
       AND hca.cust_account_id     =  xca.customer_id;          -- 顧客ID
--
  -- =============================
  -- グローバルテーブル
  -- 顧客移行情報取得カーソル(A-2)
  -- =============================
  TYPE t_A2_ttype IS TABLE OF get_cust_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  g_cust_info_tab t_A2_ttype;
--
--
  /**********************************************************************************
  * Procedure Name   : upd_cust_shift_info
  * Description      : 顧客移行情報更新（A-8）
  ***********************************************************************************/
  PROCEDURE upd_cust_shift_info(
    ov_errbuf              OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode             OUT VARCHAR2        -- リターン・コード
  , ov_errmsg              OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_slip_number         IN  VARCHAR2        -- 伝票番号
  , in_idx                 IN  BINARY_INTEGER  -- コレクションのインデックス
  , iv_create_chg_je_flag  IN  VARCHAR2 )      -- 釣銭振替仕訳作成フラグ
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'upd_cust_shift_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ================
    -- 顧客移行情報更新
    -- ================
    UPDATE xxcok_cust_shift_info xcsi
       SET xcsi.create_chg_je_flag     = iv_create_chg_je_flag                 -- 釣銭振替仕訳作成フラグ
         , xcsi.org_slip_number        = iv_slip_number                        -- 伝票番号
         , xcsi.last_updated_by        = cn_last_updated_by                    -- ユーザID
         , xcsi.last_update_date       = SYSDATE                               -- システム日付
         , xcsi.last_update_login      = cn_last_update_login                  -- ログインID
         , xcsi.request_id             = cn_request_id                         -- 要求ID
         , xcsi.program_application_id = cn_program_application_id             -- プログラム・アプリケーションID
         , xcsi.program_id             = cn_program_id                         -- プログラムID
         , xcsi.program_update_date    = SYSDATE                               -- プログラム更新日
     WHERE xcsi.cust_shift_id = g_cust_info_tab( in_idx ).xcsi_cust_shift_id;  -- 顧客移行情報ID
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END upd_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : ins_gl_oif
  * Description      : 一般会計OIF登録（A-7）
  ***********************************************************************************/
  PROCEDURE ins_gl_oif(
    ov_errbuf       OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode      OUT VARCHAR2        -- リターン・コード
  , ov_errmsg       OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , in_idx          IN  BINARY_INTEGER  -- コレクションのインデックス
  , iv_slip_number  IN  VARCHAR2        -- 伝票番号
  , iv_period_name  IN  VARCHAR2 )      -- 会計期間名
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'ins_gl_oif';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =======================
    -- 一般会計OIF(借方)の登録
    -- =======================
    INSERT ALL INTO gl_interface(
      status                                          -- ステータス
    , set_of_books_id                                 -- 会計帳簿ID
    , accounting_date                                 -- 仕訳有効日付
    , currency_code                                   -- 通貨コード
    , date_created                                    -- 新規作成日付
    , created_by                                      -- 新規作成者ID
    , actual_flag                                     -- 残高タイプ
    , user_je_category_name                           -- 仕訳カテゴリ名
    , user_je_source_name                             -- 仕訳ソース名
    , segment1                                        -- 会社
    , segment2                                        -- 部門
    , segment3                                        -- 勘定科目
    , segment4                                        -- 補助科目
    , segment5                                        -- 顧客コード
    , segment6                                        -- 企業コード
    , segment7                                        -- 予備1
    , segment8                                        -- 予備2
    , entered_cr                                      -- 貸方金額
    , entered_dr                                      -- 借方金額
    , reference1                                      -- バッチ名
    , reference4                                      -- 仕訳名
    , period_name                                     -- 会計期間名
    , group_id                                        -- グループID
    , attribute1                                      -- 税区分
    , attribute3                                      -- 伝票番号
    , attribute4                                      -- 起票部門
    , attribute5                                      -- 伝票入力者
    , context )                                       -- DFFコンテキスト
    VALUES(
      cv_glif_status                                  -- NEW
    , gn_set_of_books_id                              -- 会計帳簿ID
    , g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- 顧客移行日
    , gv_currency_code                                -- 機能通貨コード
    , SYSDATE                                         -- システム日付
    , cn_created_by                                   -- ログイン情報のユーザID
    , cv_glif_actual_flag                             -- 'A'
    , gv_prof_category_change                         -- 釣銭振替の仕訳カテゴリ
    , gv_prof_source_cok                              -- 個別開発の仕訳ソース
    , gv_prof_company_code                            -- 会社コード
-- 2009/06/09 Ver.1.2 [障害T1_1335] SCS K.Yamaguchi REPAIR START
--    , g_cust_info_tab( in_idx ).xcsi_prev_base_code   -- 旧担当拠点
    , g_cust_info_tab( in_idx ).xcsi_new_base_code    -- 新担当拠点
-- 2009/06/09 Ver.1.2 [障害T1_1335] SCS K.Yamaguchi REPAIR END
    , gv_prof_aff3_change                             -- 仮払金（釣銭）勘定科目
    , gv_prof_subacct_dummy                           -- 補助科目のダミー値
    , g_cust_info_tab( in_idx ).xcsi_cust_code        -- 顧客コード
    , gv_prof_company_dummy                           -- 企業コードのダミー値
    , gv_prof_preliminary1_dummy                      -- 予備１のダミー値
    , gv_prof_preliminary2_dummy                      -- 予備２のダミー値
    , NULL                                            -- NULL
    , g_cust_info_tab( in_idx ).xca_change_amount     -- 釣銭
    , gv_batch_name                                   -- バッチ名
    , iv_slip_number                                  -- 伝票番号
    , iv_period_name                                  -- 会計期間名
    , TO_NUMBER( gv_group_id )                        -- グループID
    , NULL                                            -- 税区分
    , iv_slip_number                                  -- 伝票番号
    , gv_prof_aff2_dept_fin                           -- 財務経理部の部門コード
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD START
--    , TO_CHAR( cn_last_updated_by )                   -- ログイン情報のユーザID
    , g_cust_info_tab( in_idx ).xcsi_emp_code         -- 顧客移行登録従業員
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD START
    , gv_set_of_books_name )                          -- 会計帳簿名
    -- =======================
    -- 一般会計OIF(貸方)の登録
    -- =======================
    INTO gl_interface(
      status                                          -- ステータス
    , set_of_books_id                                 -- 会計帳簿ID
    , accounting_date                                 -- 仕訳有効日付
    , currency_code                                   -- 通貨コード
    , date_created                                    -- 新規作成日付
    , created_by                                      -- 新規作成者ID
    , actual_flag                                     -- 残高タイプ
    , user_je_category_name                           -- 仕訳カテゴリ名
    , user_je_source_name                             -- 仕訳ソース名
    , segment1                                        -- 会社
    , segment2                                        -- 部門
    , segment3                                        -- 勘定科目
    , segment4                                        -- 補助科目
    , segment5                                        -- 顧客コード
    , segment6                                        -- 企業コード
    , segment7                                        -- 予備1
    , segment8                                        -- 予備2
    , entered_cr                                      -- 貸方金額
    , entered_dr                                      -- 借方金額
    , reference1                                      -- バッチ名
    , reference4                                      -- 仕訳名
    , period_name                                     -- 会計期間名
    , group_id                                        -- グループID
    , attribute1                                      -- 税区分
    , attribute3                                      -- 伝票番号
    , attribute4                                      -- 起票部門
    , attribute5                                      -- 伝票入力者
    , context )                                       -- DFFコンテキスト
    VALUES(
      cv_glif_status                                  -- NEW
    , gn_set_of_books_id                              -- 会計帳簿ID
    , g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- 顧客移行日
    , gv_currency_code                                -- 機能通貨コード
    , SYSDATE                                         -- システム日付
    , cn_created_by                                   -- ログイン情報のユーザID
    , cv_glif_actual_flag                             -- 'A'
    , gv_prof_category_change                         -- 釣銭振替の仕訳カテゴリ
    , gv_prof_source_cok                              -- 個別開発の仕訳ソース
    , gv_prof_company_code                            -- 会社コード
-- 2009/06/09 Ver.1.2 [障害T1_1335] SCS K.Yamaguchi REPAIR START
--    , g_cust_info_tab( in_idx ).xcsi_new_base_code    -- 新担当拠点
    , g_cust_info_tab( in_idx ).xcsi_prev_base_code   -- 旧担当拠点
-- 2009/06/09 Ver.1.2 [障害T1_1335] SCS K.Yamaguchi REPAIR START
    , gv_prof_aff3_change                             -- 仮払金（釣銭）勘定科目
    , gv_prof_subacct_dummy                           -- 補助科目のダミー値
    , g_cust_info_tab( in_idx ).xcsi_cust_code        -- 顧客コード
    , gv_prof_company_dummy                           -- 企業コードのダミー値
    , gv_prof_preliminary1_dummy                      -- 予備１のダミー値
    , gv_prof_preliminary2_dummy                      -- 予備２のダミー値
    , g_cust_info_tab( in_idx ).xca_change_amount     -- 釣銭
    , NULL                                            -- NULL
    , gv_batch_name                                   -- バッチ名
    , iv_slip_number                                  -- 伝票番号
    , iv_period_name                                  -- 会計期間名
    , TO_NUMBER( gv_group_id )                        -- グループID
    , NULL                                            -- 税区分
    , iv_slip_number                                  -- 伝票番号
    , gv_prof_aff2_dept_fin                           -- 財務経理部の部門コード
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD START
--    , TO_CHAR( cn_last_updated_by )                   -- ログイン情報のユーザID
    , g_cust_info_tab( in_idx ).xcsi_emp_code         -- 顧客移行登録従業員
-- 2009/10/06 Ver.1.3 [障害E_T3_00632] SCS S.Moriyama UPD START
    , gv_set_of_books_name )                          -- 会計帳簿名
    SELECT 'X' FROM DUAL;
--
      -- ====================
      -- 出力パラメータの設定
      -- ====================
      ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END ins_gl_oif;
--
--
  /**********************************************************************************
  * Procedure Name   : get_gl_data_info
  * Description      : GL連携データ付加情報の取得（A-6）
  ***********************************************************************************/
  PROCEDURE get_gl_data_info(
    ov_errbuf       OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode      OUT VARCHAR2        -- リターン・コード
  , ov_errmsg       OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , in_idx          IN  BINARY_INTEGER  -- コレクションのインデックス
  , ov_slip_number  OUT VARCHAR2 )      -- 伝票番号
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_gl_data_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
    -- ============
    -- ローカル例外
    -- ============
    get_gl_data_expt            EXCEPTION;     -- 付加情報取得例外
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =================================
    -- 伝票番号取得APIより伝票番号を取得
    -- =================================
    ov_slip_number := xxcok_common_pkg.get_slip_number_f(
                        iv_package_name  =>  cv_pkg_name
                      );
--
    IF( ov_slip_number IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00025
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE get_gl_data_expt;
    END IF;
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 付加情報取得例外ハンドラ ***
    WHEN get_gl_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_gl_data_info;
--
--
  /**********************************************************************************
  * Procedure Name   : chk_acctg_target
  * Description      : 会計期間チェック（A-5）
  ***********************************************************************************/
  PROCEDURE chk_acctg_target(
    ov_errbuf       OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode      OUT VARCHAR2        -- リターン・コード
  , ov_errmsg       OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , in_idx          IN  BINARY_INTEGER  -- コレクションのインデックス
  , ov_period_name  OUT VARCHAR2 )      -- 会計期間名
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'chk_acctg_target';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg         VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode         BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    ln_period_year     NUMBER(15)      DEFAULT NULL;  -- 会計年度
    lv_closing_status  VARCHAR2(1)     DEFAULT NULL;  -- ステータス
--
    -- ============
    -- ローカル例外
    -- ============
    closing_status_expt EXCEPTION;  -- 会計期間クローズ
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ====================
    -- 会計カレンダ情報取得
    -- ====================
    xxcok_common_pkg.get_acctg_calendar_p(
      ov_errbuf                  =>  lv_errbuf                                       -- エラーバッファ
    , ov_retcode                 =>  lv_retcode                                      -- リターンコード
    , ov_errmsg                  =>  lv_errmsg                                       -- エラーメッセージ
    , in_set_of_books_id         =>  gn_set_of_books_id                              -- 会計帳簿ID
    , iv_application_short_name  =>  cv_appl_name_sqlgl                              -- アプリ短縮名:SQLGL
    , id_object_date             =>  g_cust_info_tab( in_idx ).xcsi_cust_shift_date  -- 対象日(顧客移行日)
    , iv_adjustment_period_flag  =>  cv_adjust_flag_n                                -- 調整フラグ(DEFAULT'N')
    , on_period_year             =>  ln_period_year                                  -- 会計年度
    , ov_period_name             =>  ov_period_name                                  -- 会計期間名
    , ov_closing_status          =>  lv_closing_status                               -- ステータス
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00011
                    , iv_token_name1   =>  cv_tkn_proc_date
                    , iv_token_value1  =>  g_cust_info_tab( in_idx ).xcsi_cust_shift_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE global_api_expt;
    END IF;
--
    -- ===========================================
    -- 取得したステータスが'O'（正常）以外の場合、
    -- 会計期間クローズエラー(警告終了)
    -- ===========================================
    IF( lv_closing_status <> cv_closing_status_o ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_10208
                    , iv_token_name1   =>  cv_tkn_period
                    , iv_token_value1  =>  ov_period_name
                    , iv_token_name2   =>  cv_tkn_cust_code
                    , iv_token_value2  =>  g_cust_info_tab( in_idx ).xcsi_cust_code  -- 顧客コード
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE closing_status_expt;
    END IF;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 会計期間クローズ例外ハンドラ ***
    WHEN closing_status_expt THEN
      ov_retcode := cv_status_warning;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END chk_acctg_target;
--
--
  /**********************************************************************************
  * Function Name   : distinct_target_cust_f
  * Description     : 振替仕訳作成対象顧客判別（A-4）
  ***********************************************************************************/
  FUNCTION distinct_target_cust_f(
    in_idx  BINARY_INTEGER )  -- コレクションのインデックス
  RETURN BOOLEAN              -- 戻り値(TRUE=振替仕訳作成対象/FALSE=作成対象外)
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'distinct_target_cust_f';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf           VARCHAR2(5000)                              DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1)                                 DEFAULT NULL;  -- リターン・コード
    lv_errmsg           VARCHAR2(5000)                              DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg          VARCHAR2(2000)                              DEFAULT NULL;  -- メッセージ
    lb_retcode          BOOLEAN                                     DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lb_A4_flag          BOOLEAN                                     DEFAULT TRUE;  -- 振替仕訳作成対象判別フラグ
    ln_target_cust_cnt  NUMBER                                      DEFAULT NULL;  -- チェック件数
    lt_cust_shift_date  xxcok_cust_shift_info.cust_shift_date%TYPE  DEFAULT NULL;  -- 顧客移行日
    lt_cust_code        xxcok_cust_shift_info.cust_code%TYPE        DEFAULT NULL;  -- 顧客コード
--
  BEGIN
    lt_cust_shift_date := g_cust_info_tab( in_idx ).xcsi_cust_shift_date;  -- 顧客移行日
    lt_cust_code       := g_cust_info_tab( in_idx ).xcsi_cust_code;        -- 顧客コード
--
    -- ============
    -- 存在チェック
    -- ============
    SELECT COUNT( 'X' )         AS dummy
      INTO ln_target_cust_cnt
      FROM hz_cust_accounts     hca                                         -- 顧客マスタ
         , xxcmm_cust_accounts  xca                                         -- 顧客マスタアドオン
         , hz_parties           hp
     WHERE hca.account_number  = lt_cust_code                               -- 顧客コード
       AND hca.cust_account_id = xca.customer_id                            -- 顧客ID
       AND hca.party_id        = hp.party_id                                -- パーティID
       AND EXISTS ( SELECT 'X'                AS dummy
                      FROM fnd_lookup_values  flv                           -- クィックコード
                     WHERE flv.lookup_type       =  cv_lt_glif_chng_vd      -- 参照タイプ
                       AND flv.lookup_code       =  xca.business_low_type   -- 参照コード=業態（小分類）
                       AND flv.start_date_active <= lt_cust_shift_date      -- 有効日(自)=顧客移行日
                       AND ( flv.end_date_active >= lt_cust_shift_date      -- 有効日(至)=顧客移行日
                             OR
                             flv.end_date_active IS NULL )                  -- 有効日(至)=NULL
                       AND flv.enabled_flag = cv_lt_enabled_flag_y )        -- 有効フラグ='Y'
       AND EXISTS ( SELECT 'X'                AS dummy
                      FROM fnd_lookup_values  flv                           -- クィックコード
                     WHERE flv.lookup_type       =  cv_lt_glif_chng_status  -- 参照タイプ
                       AND flv.lookup_code       =  hp.duns_number_c        -- 参照コード=顧客ステータス
                       AND flv.start_date_active <= lt_cust_shift_date      -- 有効日(自)<=顧客移行日
                       AND ( flv.end_date_active >= lt_cust_shift_date      -- 有効日(至)>=顧客移行日
                             OR
                             flv.end_date_active IS NULL )                  -- 有効日(至)=NULL
                       AND flv.enabled_flag = cv_lt_enabled_flag_y )        -- 有効フラグ='Y'
       AND ROWNUM = cn_rownum_1;                                            -- 取得レコード数=1レコード
--
    -- ==========================
    -- 振替仕訳作成対象顧客の判別
    -- ==========================
    IF( ln_target_cust_cnt = cn_rownum_0 ) THEN
      lb_A4_flag := cb_bool_false;
    ELSIF( ln_target_cust_cnt = cn_rownum_1 ) THEN
      lb_A4_flag := cb_bool_true;
    END IF;
--
    RETURN( lb_A4_flag );
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      RAISE_APPLICATION_ERROR (
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
--
  END distinct_target_cust_f;
--
--
  /**********************************************************************************
  * Procedure Name   : lock_cust_shift_info
  * Description      : 顧客移行情報ロック取得(A-3)
  ***********************************************************************************/
  PROCEDURE lock_cust_shift_info(
    ov_errbuf   OUT VARCHAR2          -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2          -- リターン・コード
  , ov_errmsg   OUT VARCHAR2          -- ユーザー・エラー・メッセージ
  , in_idx      IN  BINARY_INTEGER )  -- コレクションのインデックス
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'lock_cust_shift_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    -- ====================
    -- ロック取得用カーソル
    -- ====================
    CURSOR lock_cust_info_cur(
      it_cust_shift_id  IN xxcok_cust_shift_info.cust_shift_id%TYPE )
    IS
      SELECT 'X'                    AS dummy
        FROM xxcok_cust_shift_info  xcsi            -- 顧客移行情報テーブル
       WHERE xcsi.cust_shift_id = it_cust_shift_id  -- 顧客移行情報ID
         FOR UPDATE OF xcsi.cust_shift_id NOWAIT;
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ========================
    -- 顧客移行情報ロックの取得
    -- ========================
    OPEN  lock_cust_info_cur( g_cust_info_tab( in_idx ).xcsi_cust_shift_id );  -- 顧客移行情報ID
    CLOSE lock_cust_info_cur;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** ロック取得エラー例外ハンドラ ***
    WHEN global_resouce_busy_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00049
                    , iv_token_name1   =>  cv_tkn_cust_code
                    , iv_token_value1  =>  TO_CHAR( g_cust_info_tab( in_idx ).xcsi_cust_code )  -- 顧客コード
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_warning;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END lock_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : get_cust_shift_info
  * Description      : 顧客移行情報取得(A-2)
  ***********************************************************************************/
  PROCEDURE get_cust_shift_info(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_cust_shift_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode              VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg              VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode              BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lb_A4_flag              BOOLEAN         DEFAULT TRUE;  -- 振替仕訳作成対象判別フラグ(TRUE=作成対象/FALSE=作成対象外)
    lv_end_retcode          VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_slip_number          VARCHAR2(30)    DEFAULT NULL;  -- 伝票番号
    lv_period_name          VARCHAR2(15)    DEFAULT NULL;  -- 会計期間名
    lv_create_chg_je_flag   VARCHAR2(1)     DEFAULT NULL;  -- 釣銭振替仕訳作成フラグ
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    gn_target_cnt     := cn_number_0;
    gn_normal_cnt     := cn_number_0;
    gn_warning_cnt    := cn_number_0;
    gn_error_cnt      := cn_number_0;
    gn_off_chg_je_cnt := cn_number_0;
    lv_retcode        := cv_status_normal;
    lv_end_retcode    := cv_status_normal;
--
    -- ==================
    -- 顧客移行情報の取得
    -- ==================
    OPEN  get_cust_info_cur( gd_process_date );
    FETCH get_cust_info_cur BULK COLLECT INTO g_cust_info_tab;
    CLOSE get_cust_info_cur;
--
    -- ==================
    -- 対象件数のカウント
    -- ==================
    gn_target_cnt := g_cust_info_tab.COUNT;
--
    -- ======================
    -- 顧客移行情報取得ループ
    -- ======================
    <<get_cust_info_loop>>
    FOR ln_idx IN cn_rownum_1 .. g_cust_info_tab.COUNT LOOP
--
      -- ==============
      -- ネストブロック
      -- ==============
      DECLARE
        warning_expt  EXCEPTION;  -- 警告例外
--
      BEGIN
        -- ==============
        -- セーブポイント
        -- ==============
        SAVEPOINT loop_save;
--
        -- ==========================
        -- A-3:顧客移行情報ロック取得
        -- ==========================
        lock_cust_shift_info(
          ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
        , ov_retcode  =>  lv_retcode  -- リターン・コード
        , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
        , in_idx      =>  ln_idx      -- コレクションのインデックス
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warning ) THEN
          RAISE warning_expt;
        END IF;
--
        -- ============================
        -- A-4:振替仕訳作成対象顧客判別
        -- ============================
        lb_A4_flag := distinct_target_cust_f(
                        in_idx  =>  ln_idx  -- コレクションのインデックス
                      );
--
        IF( lb_A4_flag = cb_bool_true ) THEN
          -- ====================
          -- A-5:会計期間チェック
          -- ====================
          chk_acctg_target(
            ov_errbuf       =>  lv_errbuf       -- エラー・メッセージ
          , ov_retcode      =>  lv_retcode      -- リターン・コード
          , ov_errmsg       =>  lv_errmsg       -- ユーザー・エラー・メッセージ
          , in_idx          =>  ln_idx          -- コレクションのインデックス
          , ov_period_name  =>  lv_period_name  -- 会計期間名
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warning ) THEN
            RAISE warning_expt;
          END IF;
--
          -- ==============================
          -- A-6:GL連携データ付加情報の取得
          -- ==============================
          get_gl_data_info(
            ov_errbuf       =>  lv_errbuf       -- エラー・メッセージ
          , ov_retcode      =>  lv_retcode      -- リターン・コード
          , ov_errmsg       =>  lv_errmsg       -- ユーザー・エラー・メッセージ
          , in_idx          =>  ln_idx          -- コレクションのインデックス
          , ov_slip_number  =>  lv_slip_number  -- 伝票番号
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===================
          -- A-7:一般会計OIF登録
          -- ===================
          ins_gl_oif(
            ov_errbuf       =>  lv_errbuf       -- エラー・メッセージ
          , ov_retcode      =>  lv_retcode      -- リターン・コード
          , ov_errmsg       =>  lv_errmsg       -- ユーザー・エラー・メッセージ
          , in_idx          =>  ln_idx          -- コレクションのインデックス
          , iv_slip_number  =>  lv_slip_number  -- 伝票番号
          , iv_period_name  =>  lv_period_name  -- 会計期間名
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================================
          -- 振替仕訳を作成した場合、釣銭振替仕訳作成フラグを作成済に設定
          -- ============================================================
          lv_create_chg_je_flag  := cv_chg_je_flag_finish;
          gn_normal_cnt          := gn_normal_cnt + cn_number_1;
--
        ELSE
          -- ==============================================================
          -- 振替仕訳作成対象外の場合、釣銭振替仕訳作成フラグを対象外に設定
          -- ==============================================================
          lv_create_chg_je_flag  := cv_chg_je_flag_out;
          gn_off_chg_je_cnt      := gn_off_chg_je_cnt + 1;
          lv_slip_number         := NULL;
--
        END IF;
--
        -- ====================
        -- A-8:顧客移行情報更新
        -- ====================
        upd_cust_shift_info(
          ov_errbuf              =>  lv_errbuf              -- エラー・メッセージ
        , ov_retcode             =>  lv_retcode             -- リターン・コード
        , ov_errmsg              =>  lv_errmsg              -- ユーザー・エラー・メッセージ
        , iv_slip_number         =>  lv_slip_number         -- 伝票番号
        , in_idx                 =>  ln_idx                 -- コレクションのインデックス
        , iv_create_chg_je_flag  =>  lv_create_chg_je_flag  -- 釣銭振替仕訳作成フラグ
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      EXCEPTION
      -- *** 警告終了例外ハンドラ ***
        WHEN warning_expt THEN
          gn_warning_cnt := gn_warning_cnt + cn_number_1;
          lv_end_retcode := cv_status_warning;
          ROLLBACK TO SAVEPOINT loop_save;
      END;
--
    END LOOP get_cust_info_loop;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 機能内プロシージャエラー例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_cust_shift_info;
--
--
  /**********************************************************************************
  * Procedure Name   : init
  * Description      : 初期処理(A-1)
  ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2    -- ユーザー・エラー・メッセージ
  , iv_process_flag IN VARCHAR2   -- 入力項目の起動区分パラメータ
  )
  IS
--
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'init';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf    VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode   VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg    VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg   VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode   BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lv_err_prof  VARCHAR2(50)    DEFAULT NULL;  -- 取得できなかったプロファイルオプション値
--
    -- ============
    -- ローカル例外
    -- ============
    get_profile_expt       EXCEPTION;  -- プロファイル値取得エラー
    get_process_date_expt  EXCEPTION;  -- 業務処理日付取得エラー
    get_group_id_expt      EXCEPTION;  -- グループID取得エラー
    get_operation_date_expt EXCEPTION; -- システム稼働日取得エラー
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --入力パラメータの起動区分の項目をメッセージ出力
    --==============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    cv_appl_name_xxcok
                  , cv_msg_cok1_00076
                  , cv_tkn_process_flag
                  , iv_process_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.LOG       -- 出力区分
                  , lv_out_msg         -- メッセージ
                  , 1                  -- 改行
                  );
    -- ==================
    -- 業務処理日付を取得
    -- ==================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE get_process_date_expt;
    END IF;
    --==============================================================
    --起動区分が通常起動の場合、システム稼動日取得を業務処理日付とする
    --==============================================================
    IF( iv_process_flag = cv_normal_type ) THEN
      gd_process_date := xxcok_common_pkg.get_operating_day_f(
                           gd_process_date  -- 上記で取得した業務処理日付
                         , cn_plus_days     -- 日数
                         , cn_aft           -- 処理区分(2)
                         , cn_cal_type_one  -- カレンダー区分(システム稼働日カレンダー)
                         );
    END IF;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_operation_date_expt;
    END IF;
--
    -- ======================
    -- １：プロファイルの取得
    -- ======================
    gv_prof_company_code := FND_PROFILE.VALUE( cv_prof_company_code );              -- 会社コード
--
    IF( gv_prof_company_code IS NULL ) THEN
      lv_err_prof := cv_prof_company_code;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_aff3_change := FND_PROFILE.VALUE( cv_prof_aff3_change );                -- 仮払金（釣銭）勘定科目）
--
    IF( gv_prof_aff3_change IS NULL ) THEN
      lv_err_prof := cv_prof_aff3_change;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_subacct_dummy := FND_PROFILE.VALUE( cv_prof_subacct_dummy );            -- 補助科目のダミー値
--
    IF( gv_prof_subacct_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_subacct_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_company_dummy := FND_PROFILE.VALUE( cv_prof_company_dummy );            -- 企業コードのダミー値
--
    IF( gv_prof_company_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_company_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_preliminary1_dummy := FND_PROFILE.VALUE( cv_prof_preliminary1_dummy );  -- 予備１のダミー値
--
    IF( gv_prof_preliminary1_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_preliminary1_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_preliminary2_dummy := FND_PROFILE.VALUE( cv_prof_preliminary2_dummy );  -- 予備2のダミー値
--
    IF( gv_prof_preliminary2_dummy IS NULL ) THEN
      lv_err_prof := cv_prof_preliminary2_dummy;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_category_change := FND_PROFILE.VALUE( cv_prof_gl_category_change );     -- 釣銭振替の仕訳カテゴリ
--
    IF( gv_prof_category_change IS NULL ) THEN
      lv_err_prof := cv_prof_gl_category_change;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_source_cok := FND_PROFILE.VALUE( cv_prof_gl_source_cok );               -- 個別開発の仕訳ソース
--
    IF( gv_prof_source_cok IS NULL ) THEN
      lv_err_prof := cv_prof_gl_source_cok;
      RAISE get_profile_expt;
    END IF;
--
    gv_prof_aff2_dept_fin := FND_PROFILE.VALUE( cv_prof_aff2_dept_fin );            -- 財務経理部の部門コード
--
    IF( gv_prof_aff2_dept_fin IS NULL ) THEN
      lv_err_prof := cv_prof_aff2_dept_fin;
      RAISE get_profile_expt;
    END IF;
--
    -- ===============================================
    -- ２：会計帳簿情報取得APIより、会計帳簿情報を取得
    -- ===============================================
    xxcok_common_pkg.get_set_of_books_info_p(
      ov_errbuf             =>  lv_errbuf             -- エラーバッファ
    , ov_retcode            =>  lv_retcode            -- リターンコード
    , ov_errmsg             =>  lv_errmsg             -- エラーメッセージ
    , on_set_of_books_id    =>  gn_set_of_books_id    -- 会計帳簿ID
    , ov_set_of_books_name  =>  gv_set_of_books_name  -- 会計帳簿名
    , on_chart_acct_id      =>  gn_chart_acct_id      -- 勘定体系ID
    , ov_period_set_name    =>  gv_period_set_name    -- カレンダ名
    , on_aff_segment_cnt    =>  gn_aff_segment_cnt    -- AFFセグメント定義数
    , ov_currency_code      =>  gv_currency_code      -- 機能通貨コード
    );
--
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appl_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00008
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      RAISE global_api_expt;
    END IF;
--
    -- ==================
    -- ３：バッチ名の取得
    -- ==================
    gv_batch_name := xxcok_common_pkg.get_batch_name_f(
                       iv_category_name  =>  gv_prof_category_change
                     );
--
    -- ================
    -- ネストブロック
    -- グループIDを取得
    -- ================
    BEGIN
      SELECT gjst.attribute1  AS gjst_group_id               -- グループID
        INTO gv_group_id
        FROM gl_je_sources_tl gjst                           -- 仕訳ソースマスタ
       WHERE gjst.user_je_source_name = gv_prof_source_cok   -- 仕訳ソース名=仕訳ソース
         AND gjst.language = USERENV( 'LANG' );              -- 言語
--
    EXCEPTION
      -- *** グループID取得エラー ***
      WHEN OTHERS THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_appl_name_xxcok
                      , iv_name         =>  cv_msg_cok1_00024
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which     =>  FND_FILE.OUTPUT
                      , iv_message   =>  lv_out_msg
                      , in_new_line  =>  cn_number_1
                      );
        RAISE get_group_id_expt;
--
    END;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** プロファイル値取得不可エラー ***
    WHEN get_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00003
                    , iv_token_name1   =>  cv_tkn_profile
                    , iv_token_value1  =>  lv_err_prof
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_1
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 業務処理日付取得エラー例外ハンドラ ***
    WHEN get_process_date_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** システム稼働日取得エラー例外ハンドラ ***
    WHEN get_operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appl_name_xxcok
                    , cv_msg_cok1_00078
                    );
      lb_retcode := xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT    -- 出力区分
                    , lv_out_msg         -- メッセージ
                    , 0                  -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** グループID取得エラー例外ハンドラ ***
    WHEN get_group_id_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
--
  /**********************************************************************************
  * Procedure Name   : submain
  * Description      : メイン処理プロシージャ
  **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2    -- ユーザー・エラー・メッセージ
  , iv_process_flag IN VARCHAR2 -- 入力項目の起動区分パラメータ
  )
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'submain';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =============
    -- 初期処理(A-1)
    -- =============
    init(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    , iv_process_flag => iv_process_flag -- 入力項目の起動区分パラメータ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =====================
    -- 顧客移行情報取得(A-2)
    -- =====================
    get_cust_shift_info(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
    -- *** 機能内プロシージャエラー例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
--
   /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , retcode  OUT VARCHAR2    -- リターン・コード
  , iv_process_flag IN VARCHAR2 -- 入力項目の起動区分パラメータ
  )
  IS
--
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(30) := 'main';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf        VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg        VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode       BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lv_message_code  VARCHAR2(5000)  DEFAULT NULL;  -- 処理終了メッセージ
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode  := cv_status_normal;
--
    -- ==============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ==============================================
    xxccp_common_pkg.put_log_header(
      iv_which    =>  cv_tkn_output
    , ov_retcode  =>  lv_retcode
    , ov_errbuf   =>  lv_errbuf
    , ov_errmsg   =>  lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ==============================================
    submain(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    , iv_process_flag => iv_process_flag -- 入力項目の起動区分パラメータ
    );
--
    -- ==========
    -- エラー出力
    -- ==========
    IF (lv_retcode <> cv_status_normal) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_errmsg
                    , in_new_line  =>  cn_number_1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.LOG
                    , iv_message   =>  lv_errbuf
                    , in_new_line  =>  cn_number_1
                    );
    END IF;
--
    -- ====================================
    -- リターンコード判定別エラー件数の設定
    -- ====================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_error_cnt      := cn_number_1;
      gn_target_cnt     := cn_number_0;
      gn_normal_cnt     := cn_number_0;
      gn_off_chg_je_cnt := cn_number_0;
    ELSIF( lv_retcode = cv_status_normal ) THEN
      gn_error_cnt := cn_number_0;
    ELSIF( lv_retcode = cv_status_warning ) THEN
      gn_error_cnt := gn_warning_cnt;
    END IF;
--
    -- ============
    -- 対象件数出力
    -- ============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90000
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ============
    -- 成功件数出力
    -- ============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90001
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ==============
    -- エラー件数出力
    -- ==============
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                  , iv_name          =>  cv_msg_ccp1_90002
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ==========================
    -- 釣銭仕訳作成対象外件数出力
    -- ==========================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcok
                  , iv_name          =>  cv_msg_cok1_10386
                  , iv_token_name1   =>  cv_tkn_count
                  , iv_token_value1  =>  TO_CHAR( gn_off_chg_je_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ====================
    -- 終了メッセージの表示
    -- ====================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp1_90004;
    ELSIF( lv_retcode = cv_status_warning ) THEN
      lv_message_code := cv_msg_ccp1_90005;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp1_90006;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appl_name_xxccp
                  , iv_name         =>  lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    -- ======================================
    -- ステータスセット
    -- 終了ステータスがエラーの場合はROLLBACK
    -- ======================================
    retcode := lv_retcode;
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
  END main;
--
END XXCOK004A01C;
/
