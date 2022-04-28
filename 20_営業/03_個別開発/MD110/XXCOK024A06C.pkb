CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A06C (body)
 * Description      : 販売控除情報より仕訳情報を作成し、一般会計OIFに連携する処理
 * MD.050           : 販売控除データGL連携 MD050_COK_024_A06
 * Version          : 1.4
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
-- *  roundup                切上関数
 *  init                   A-1.初期処理
 *  get_data               A-2.販売控除データ抽出
 *  edit_work_data         A-3.一般会計OIF集約処理
 *  edit_gl_data           A-4.一般会計OIFデータ作成
 *  insert_gl_data         A-5.一般会計OIF登録処理
 *  update_deduction_data  A-6.販売控除情報更新処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理A-7を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/11/24    1.0   H.Ishii          新規作成
 *  2021/05/19    1.1   K.Yoshikawa      グループID追加対応
 *  2021/06/25    1.2   K.Tomie          E_本稼働_17279対応
 *  2021/08/26    1.3   H.Futamura       E_本稼動_17468対応
 *  2022/04/25    1.4   K.Yoshikawa      E_本稼動_18146対応
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
  gv_out_msg       VARCHAR2(2000);                       -- 出力メッセージ
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- 一般会計OIFに作成した件数
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- 販売控除情報の処理対象となる件数
  gn_error_cnt     NUMBER   DEFAULT 0;                   -- エラー件数
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A06C';                     -- パッケージ名
  -- アプリケーション短縮名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                            -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                 -- 業務日付取得エラー
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                 -- 対象データなしエラーメッセージ
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';                 -- ロックエラーメッセージ（販売控除TB）
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10586';                 -- データ登録エラーメッセージ
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10587';                 -- データ更新エラーメッセージ
  cv_tkn_deduction_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10588';                 -- 販売控除情報
  cv_tkn_gloif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10589';                 -- 一般会計OIF
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10578';                 -- 会計帳簿ID
  cv_pro_bks_nm             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10579';                 -- 会計帳簿名称
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10580';                 -- 会社コード
  cv_pro_dept_fin_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10624';                 -- 部門コード（財務経理部）
  cv_pro_customer_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10625';                 -- 顧客コード_ダミー値
  cv_pro_comp_cd            CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10626';                 -- 企業コード_ダミー値
  cv_pro_preliminary1_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10627';                 -- 予備１_ダミー値
  cv_pro_preliminary2_cd    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10628';                 -- 予備２_ダミー値
  cv_pro_category_cd        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10629';                 -- 仕訳カテゴリ
  cv_pro_source_cd          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10630';                 -- 仕訳ソース
  cv_sales_deduction        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10650';                 -- 販売控除情報
  cv_period_name_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00059';                 -- 会計期間情報取得エラーメッセージ
  cv_account_error_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10681';                 -- 税情報取得エラーメッセージ
  cv_pro_org_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10669';                 -- 組織ID
--2021/05/19 add start
  cv_group_id_msg           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00024';                 -- グループID取得エラー
--2021/05/19 add end
--
  -- トークン
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';                         -- プロファイル
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';                      -- テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';                        -- キー項目
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';                               -- フラグ値:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';                               -- フラグ値:N
  cv_r_flag                 CONSTANT  VARCHAR2(1)  := 'R';                               -- フラグ値:R
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';                               -- フラグ値:S
  cv_t_flag                 CONSTANT  VARCHAR2(1)  := 'T';                               -- フラグ値:T
  cv_u_flag                 CONSTANT  VARCHAR2(1)  := 'U';                               -- フラグ値:U
  cv_v_flag                 CONSTANT  VARCHAR2(1)  := 'V';                               -- フラグ値:V
  cv_f_flag                 CONSTANT  VARCHAR2(1)  := 'F';                               -- フラグ値:F
  cv_dummy_code             CONSTANT  VARCHAR2(5)  := 'DUMMY';                           -- DUMMY値
  cv_date_format            CONSTANT  VARCHAR2(6)  := 'YYYYMM';                          -- 書式フォーマットYYYYMM
  cv_teigaku_code           CONSTANT  VARCHAR2(3)  := '070';                             -- 控除タイプ_定額控除
  -- クイックコード
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';      -- 控除データ種類
  cv_lookup_tax_conv_code   CONSTANT  VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';    -- 消費税コード変換マスタ
  cv_period_set_name        CONSTANT  VARCHAR2(30) := 'SALES_CALENDAR';                  -- 会計カレンダ
  -- 一般会計OIFテーブルに設定する固定値
  cv_status                 CONSTANT  VARCHAR2(3)  := 'NEW';                             -- ステータス
  cv_currency_code          CONSTANT  VARCHAR2(3)  := 'JPY';                             -- 通貨コード
  cv_actual_flag            CONSTANT  VARCHAR2(1)  := 'A';                               -- 残高タイプ
  cv_underbar               CONSTANT  VARCHAR2(1)  := '_';                               -- 項目区切り用
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 販売控除ワークテーブル定義
  TYPE gr_deductions_exp_rec IS RECORD(
      sales_deduction_id        xxcok_sales_deduction.sales_deduction_id%TYPE             -- 販売控除ID
    , accounting_base           xxcok_condition_lines.accounting_base%TYPE                -- 拠点コード(定額控除)
    , past_sale_base_code       xxcok_sales_deduction.base_code_from%TYPE                 -- 拠点コード(定額控除以外)
    , account                   fnd_lookup_values.attribute4%TYPE                         -- 勘定科目
    , sub_account               fnd_lookup_values.attribute5%TYPE                         -- 補助科目
    , deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- 控除額
    , tax_code                  xxcok_sales_deduction.tax_code%TYPE                       -- 税コード
    , deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- 控除税額
    , corp_code                 fnd_lookup_values.attribute1%TYPE                         -- 企業コード
    , customer_code             fnd_lookup_values.attribute4%TYPE                         -- 顧客コード
  );
--
  -- 負債控除ワークテーブル定義
  TYPE gr_deductions_debt_exp_rec IS RECORD(
      account                   fnd_lookup_values.attribute6%TYPE                         -- 勘定科目
    , sub_account               fnd_lookup_values.attribute7%TYPE                         -- 補助科目
    , deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- 控除額
  );
--
-- Ver 1.3 del start
--  -- 販売控除ロック用ワークテーブル定義
--  TYPE gr_deductions_lock_rec IS RECORD(
--      sales_deduction_id        xxcok_sales_deduction.sales_deduction_id%TYPE             -- 販売控除ID
--  );
-- Ver 1.3 del end
--
  -- ワークテーブル型定義
  -- 販売控除データ
  TYPE g_deductions_exp_ttype       IS TABLE OF gr_deductions_exp_rec INDEX BY BINARY_INTEGER;
    gt_deductions_exp_tbl        g_deductions_exp_ttype;
--
  -- 販売控除負債データ
  TYPE g_deductions_debt_exp_ttype  IS TABLE OF gr_deductions_debt_exp_rec INDEX BY BINARY_INTEGER;
    gt_deductions_debt_exp_tbl   g_deductions_debt_exp_ttype;
--
-- Ver 1.3 del start
--  -- 販売控除ロック用データ
--  TYPE g_deductions_lock_ttype  IS TABLE OF gr_deductions_lock_rec INDEX BY BINARY_INTEGER;
--    gt_deduction_lock_tbl        g_deductions_lock_ttype;
-- Ver 1.3 del end
--
  -- 販売控除データ
  TYPE g_deductions_ttype           IS TABLE OF xxcok_sales_deduction%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_deduction_tbl             g_deductions_ttype;
--
-- 一般会計OIF
  TYPE g_gl_oif_ttype               IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_gl_interface_tbl          g_gl_oif_ttype;
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --初期取得
  gd_process_date                     DATE;                                         -- 業務日付
  gd_from_date                        DATE;                                         -- 取得条件となる日付(From)
  gv_period                           VARCHAR2(30);                                 -- 会計期間
  gv_set_bks_id                       VARCHAR2(30);                                 -- 会計帳簿ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- 会計帳簿名称
  gv_company_code                     VARCHAR2(30);                                 -- 会社コード
  gv_dept_fin_code                    VARCHAR2(30);                                 -- 部門コード（財務経理部）
  gv_account_code                     VARCHAR2(30);                                 -- 勘定科目コード_負債（引当等）
  gv_sub_account_code                 VARCHAR2(30);                                 -- 補助科目コード_負債（引当等）
  gv_customer_code                    VARCHAR2(30);                                 -- 顧客コード
  gv_comp_code                        VARCHAR2(30);                                 -- 企業コード
  gv_preliminary1_code                VARCHAR2(30);                                 -- 予備１
  gv_preliminary2_code                VARCHAR2(30);                                 -- 予備２
  gv_category_code                    VARCHAR2(30);                                 -- 仕訳カテゴリ
  gv_source_code                      VARCHAR2(30);                                 -- 仕訳ソース
  gn_org_id                           NUMBER;                                       -- 組織ID
--2021/05/19 add start
  gn_group_id                         NUMBER         DEFAULT NULL;                  -- グループID
--2021/05/19 add end
--Ver 1.2 add start
  gv_parallel_group                   VARCHAR2(2);                                  -- GL連携パラレル実行グループ
--Ver 1.2 add end
--
  CURSOR deductions_data_cur
  IS
    SELECT temp.sales_deduction_id          sales_deduction_id
          ,temp.accounting_base             accounting_base
          ,temp.past_sale_base_code         past_sale_base_code
          ,temp.account                     account
          ,temp.sub_account                 sub_account
          ,temp.deduction_amount            deduction_amount
          ,temp.tax_code                    tax_code
          ,temp.deduction_tax_amount        deduction_tax_amount
          ,temp.corp_code                   corp_code
          ,temp.customer_code               customer_code
    FROM   XXCOK_XXCOK024A06C_TEMP  temp
    ORDER BY
           temp.tax_code
          ,temp.accounting_base
          ,temp.past_sale_base_code
          ,temp.account
          ,temp.sub_account
          ,temp.corp_code
          ,temp.customer_code
    ;
--
-- Ver 1.3 del start
--  CURSOR deductions_data_lock_cur
--  IS
----Ver 1.2 mod start
----    SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
--    SELECT /*+ LEADING(flv XSD)
--               INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
--               USE_HASH(XSD)*/
----Ver 1.2 mod end
--           xsd.sales_deduction_id      sales_deduction_id    -- 販売控除ID
--    FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
----Ver 1.2 mod start
----    WHERE  TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)  -- 売上日
--          ,fnd_lookup_values         flv                     -- クイックコード
--    WHERE  flv.lookup_code                          = xsd.data_type                                 -- データ種類
--    AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- 控除データ種類
--    AND    flv.enabled_flag                         = cv_y_flag                                     -- 使用可能：Y
--    AND    flv.language                             = USERENV('LANG')                               -- 言語：USERENV('LANG')
--    AND    flv.attribute13                          = gv_parallel_group                             -- GL連携パラレル実行グループ
----Ver 1.2 mod end
--    AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                 -- GL連携フラグ N：未連携、R：再送
--    AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag       -- 作成元区分 S:販売実績、T:売上実績振替(EDI)、V:売上実績振替(振替割合)
--                                                     , cv_u_flag, cv_f_flag)                 -- 作成元区分 U:アップロード、F:定額控除
--    FOR UPDATE OF sales_deduction_id NOWAIT
--    ;
-- Ver 1.3 del end
--
  CURSOR deductions_debt_data_cur
  IS
    SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
           flv.attribute6                                account                -- 勘定科目
          ,flv.attribute7                                sub_account            -- 補助科目
          ,SUM(CASE
                 WHEN xsd.gl_if_flag = cv_n_flag THEN
                   xsd.deduction_amount
                 ELSE
                   xsd.deduction_amount * -1
                 END
               )                                         deduction_amount       -- 控除額
    FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
          ,fnd_lookup_values         flv                     -- クイックコード
    WHERE  flv.lookup_code                          = xsd.data_type                                 -- データ種類
    AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- 控除データ種類
    AND    flv.enabled_flag                         = cv_y_flag                                     -- 使用可能：Y
    AND    flv.language                             = USERENV('LANG')                               -- 言語：USERENV('LANG')
--Ver 1.2 add start
    AND    flv.attribute13                          = gv_parallel_group                             -- GL連携パラレル実行グループ
--Ver 1.2 add end
    AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- 売上日
    AND    xsd.gl_if_flag                          IN (cv_n_flag,cv_r_flag)                         -- GL連携フラグ N：未連携、R：再送
    AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag              -- 作成元区分 S:販売実績、T:売上実績振替(EDI)、V:売上実績振替(振替割合)
                                                     , cv_u_flag, cv_f_flag)                        -- 作成元区分 U:アップロード、F:定額控除
    GROUP BY
           flv.attribute6
          ,flv.attribute7
    ORDER BY
           flv.attribute6
          ,flv.attribute7
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.初期処理
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                , ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                , ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';                     -- プログラム名
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
    cv_pro_bks_id_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_ID';                 -- 会計帳簿ID
    cv_pro_bks_nm_1             CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_NAME';               -- 会計帳簿名称
    cv_pro_company_cd_1         CONSTANT VARCHAR2(40) := 'XXCOK1_AFF1_COMPANY_CODE';         -- XXCOK:会社コード
    cv_pro_dept_fin_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF2_DEPT_FIN';             -- XXCOK:部門コード_財務経理部
    cv_pro_customer_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- XXCOK:顧客コード_ダミー値
    cv_pro_comp_cd_1            CONSTANT VARCHAR2(40) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- XXCOK:企業コード_ダミー値
    cv_pro_preliminary1_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- XXCOK:予備１_ダミー値:0
    cv_pro_preliminary2_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- XXCOK:予備２_ダミー値:0
    cv_pro_category_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_GL_CATEGORY_CONDITION1';    -- XXCOK:仕訳カテゴリ
    cv_pro_source_cd_1          CONSTANT VARCHAR2(40) := 'XXCOK1_GL_SOURCE_CONDITION';       -- XXCOK:仕訳ソース_控除作成
    cv_pro_org_id_1             CONSTANT VARCHAR2(40) := 'ORG_ID';                           -- XXCOK:組織ID
    cn_024a06_start_months      CONSTANT NUMBER       := -1;                                 -- XXCOK:販売控除データGL連携会計期間
--
    -- *** ローカル変数 ***
    lv_profile_name                   VARCHAR2(50);                                    -- プロファイル名
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
    --==================================
    -- １．業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務日付取得エラーの場合はエラー
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                            , cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ２．販売控除データGL連携会計期間取得
    --==================================
    --業務日付よりGL記帳日を取得
    gd_from_date := LAST_DAY(TRUNC(ADD_MONTHS(gd_process_date, cn_024a06_start_months)));
--
    -- GL記帳日から会計期間を取得
    BEGIN
      SELECT gp.period_name  period_name   -- 会計期間
      INTO   gv_period
      FROM   gl_periods      gp            -- 会計期間情報
      WHERE  gp.period_set_name        = cv_period_set_name -- 会計カレンダ
      AND    gd_from_date        BETWEEN gp.start_date      -- 会計期間有効開始日
                                     AND gp.end_date        -- 会計期間有効終了日
      AND    gp.adjustment_period_flag = cv_n_flag          -- 調整機関：N
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
      -- 会計期間が取得出来ない場合
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                              , cv_period_name_msg
                                               );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- ３．プロファイル取得：会計帳簿ID
    -- ===============================
    gv_set_bks_id := FND_PROFILE.VALUE( cv_pro_bks_id_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_set_bks_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_bks_id                   -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ４．プロファイル取得：会計帳簿名称
    -- ===============================
    gv_set_bks_nm := FND_PROFILE.VALUE( cv_pro_bks_nm_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_set_bks_nm IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_bks_nm                   -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ５．プロファイル取得：会社コード
    --==================================
    gv_company_code := FND_PROFILE.VALUE( cv_pro_company_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_company_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_company_cd               -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ６．プロファイル取得：部門コード（財務経理部）
    --==================================
    gv_dept_fin_code := FND_PROFILE.VALUE( cv_pro_dept_fin_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_dept_fin_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_dept_fin_cd              -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ７．プロファイル取得：顧客コード_ダミー値
    --==================================
    gv_customer_code := FND_PROFILE.VALUE( cv_pro_customer_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_customer_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_customer_cd              -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ８．プロファイル取得：企業コード_ダミー値
    --==================================
    gv_comp_code := FND_PROFILE.VALUE( cv_pro_comp_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_comp_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_comp_cd                  -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- ９．プロファイル取得：予備１_ダミー値
    --==================================
    gv_preliminary1_code := FND_PROFILE.VALUE( cv_pro_preliminary1_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_preliminary1_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_preliminary1_cd          -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- １０．プロファイル取得：予備２_ダミー値
    --==================================
    gv_preliminary2_code := FND_PROFILE.VALUE( cv_pro_preliminary2_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_preliminary2_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_preliminary2_cd          -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- １１．プロファイル取得：仕訳カテゴリ
    --==================================
    gv_category_code := FND_PROFILE.VALUE( cv_pro_category_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_category_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_category_cd              -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- １２．プロファイル取得：仕訳ソース
    --==================================
    gv_source_code := FND_PROFILE.VALUE( cv_pro_source_cd_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_source_code IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_source_cd                -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- １３．プロファイル取得：組織ID
    --==================================
    gn_org_id := FND_PROFILE.VALUE( cv_pro_org_id_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_org_id                   -- メッセージID
                                                  );
      lv_errmsg       := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                                 , iv_name         => cv_pro_msg
                                                 , iv_token_name1  => cv_tkn_pro
                                                 , iv_token_value1 => lv_profile_name
                                                  );
      lv_errbuf       := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--2021/05/19 add start
--
    --==============================================================
    --１４．グループIDを取得
    --==============================================================
    SELECT gjs.attribute1         AS group_id -- グループID
    INTO   gn_group_id
    FROM   gl_je_sources             gjs      -- 仕訳ソースマスタ
    WHERE  gjs.user_je_source_name = gv_source_code;
--
    IF ( gn_group_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_xxcok_short_nm
                                          , cv_group_id_msg
                                           );
      RAISE global_api_expt;
    END IF;

--2021/05/19 add end
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
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
--#################################  固定例外処理部 END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-2.販売控除データ抽出
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
                    , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
                    , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_table_name             VARCHAR2(255);                                  -- テーブル名
--
    -- *** ローカル例外 ***
    lock_expt                 EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);  -- ロックエラー
    no_data_expt              EXCEPTION;    -- 対象データ0件エラー
    -- *** ローカル・カーソル (販売控除データ抽出)***
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    --==================================
    -- 販売控除データ抽出（一時表退避）
    --==================================
    INSERT INTO XXCOK_XXCOK024A06C_TEMP
    SELECT sales_deduction_id          sales_deduction_id
          ,accounting_base             accounting_base
          ,past_sale_base_code         past_sale_base_code
          ,account                     account
          ,sub_account                 sub_account
          ,deduction_amount            deduction_amount
          ,tax_code                    tax_code
          ,deduction_tax_amount        deduction_tax_amount
          ,corp_code                   corp_code
          ,customer_code               customer_code
    FROM (
          -- 顧客
--Ver 1.2 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
          SELECT /*+ LEADING(flv XSD xca flv2 flv1)
                     INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
                     USE_HASH(XSD)
                     USE_HASH(flv1)
                     USE_HASH(flv2)*/
--Ver 1.2 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- 販売控除ID
                ,CASE
                   WHEN flv.attribute2 = cv_teigaku_code THEN
                     xsd.base_code_from
                   ELSE
                     NULL
                 END                            accounting_base       -- 拠点コード(定額控除)
                ,CASE
                   WHEN xsd.source_category = cv_u_flag THEN
                     xsd.base_code_from
                   ELSE
                     xca.past_sale_base_code
                 END                            past_sale_base_code   -- 拠点コード(定額控除以外)、作成元区分が「U:アップロード」の場合、振替元拠点
                ,flv.attribute4                 account               -- 勘定科目
                ,flv.attribute5                 sub_account           -- 補助科目
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- 控除額
                ,flv1.attribute1                tax_code              -- 税コード
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- 控除税額
                ,NVL(flv2.attribute1,gv_comp_code)     corp_code      -- 企業コード
                ,NVL(DECODE(xca.torihiki_form,'2',xsd.customer_code_to,flv2.attribute4),gv_customer_code) customer_code
                                                                        -- 顧客コード
          FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
                ,xxcmm_cust_accounts       xca                     -- 顧客追加情報
                ,fnd_lookup_values         flv                     -- クイックコード(データ種類)
                ,fnd_lookup_values         flv1                    -- クイックコード(税コード変換)
                ,fnd_lookup_values         flv2                    -- クイックコード(チェーン)
          WHERE  xsd.customer_code_to                     = xca.customer_code                             -- 振替先顧客コード
          AND    flv.lookup_code                          = xsd.data_type                                 -- データ種類
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- 控除データ種類
          AND    flv.enabled_flag                         = cv_y_flag                                     -- 使用可能：Y
          AND    flv.language                             = USERENV('LANG')                               -- 言語：USERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL連携パラレル実行グループ
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- 税コード
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- 消費税コード変換マスタ
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- 使用可能：Y
          AND    flv1.language                            = USERENV('LANG')                               -- 言語：USERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- 売上日
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL連携フラグ N：未連携、R：再送
          AND    xsd.source_category                     IN (cv_s_flag, cv_t_flag, cv_v_flag              -- 作成元区分 S:販売実績、T:売上実績振替(EDI)、V:売上実績振替(振替割合)
                                                           , cv_u_flag, cv_f_flag)                        -- 作成元区分 U:アップロード、F:定額控除
          AND    flv2.lookup_type(+)                      = 'XXCMM_CHAIN_CODE'                            -- 控除用チェーンコード
          AND    flv2.lookup_code(+)                      = xca.intro_chain_code2                         -- 顧客コード
          AND    flv2.language(+)                         = USERENV('LANG')                               -- 言語：USERENV('LANG')
          AND    flv2.enabled_flag(+)                     = cv_y_flag                                     -- 使用可能：Y
          AND    xsd.customer_code_to                    IS NOT NULL                                      -- 振替先顧客コード
          UNION ALL
          -- チェーン
--Ver 1.2 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
-- Ver 1.4 mod start
--          SELECT /*+ LEADING(flv XSD flv2 flv1)
--                     INDEX(XSD XXCOK_SALES_DEDUCTION_N04)
--                     USE_HASH(XSD)
--                     USE_HASH(flv1)
--                     USE_HASH(flv2)*/
          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N08)*/
-- Ver 1.4 mod end
--Ver 1.2 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- 販売控除ID
                ,CASE
                   WHEN flv.attribute2 = cv_teigaku_code THEN
                     xsd.base_code_from
                   ELSE
                     NULL
                 END                            accounting_base       -- 拠点コード(定額控除)
                ,xsd.base_code_from             past_sale_base_code   -- 振替元拠点
                ,flv.attribute4                 account               -- 勘定科目
                ,flv.attribute5                 sub_account           -- 補助科目
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- 控除額
                ,flv1.attribute1                tax_code              -- 税コード
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- 控除税額
                ,NVL(flv2.attribute1,gv_comp_code)     corp_code      -- 企業コード
                ,NVL(flv2.attribute4,gv_customer_code) customer_code  -- 顧客コード
          FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
                ,fnd_lookup_values         flv                     -- クイックコード(データ種類)
                ,fnd_lookup_values         flv1                    -- クイックコード(税コード変換)
                ,fnd_lookup_values         flv2                    -- クイックコード(チェーン)
          WHERE  flv.lookup_code                          = xsd.data_type                                 -- データ種類
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- 控除データ種類
          AND    flv.enabled_flag                         = cv_y_flag                                     -- 使用可能：Y
          AND    flv.language                             = USERENV('LANG')                               -- 言語：USERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL連携パラレル実行グループ
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- 税コード
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- 消費税コード変換マスタ
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- 使用可能：Y
          AND    flv1.language                            = USERENV('LANG')                               -- 言語：USERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- 売上日
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL連携フラグ N：未連携、R：再送
          AND    xsd.source_category                     IN (cv_u_flag, cv_f_flag)                        -- 作成元区分 U:アップロード、F:定額控除
          AND    flv2.lookup_type                         = 'XXCMM_CHAIN_CODE'                            -- 控除用チェーンコード
          AND    flv2.lookup_code                         = xsd.deduction_chain_code                      -- チェーンコード
          AND    flv2.language                            = USERENV('LANG')                               -- 言語：USERENV('LANG')
          AND    flv2.enabled_flag                        = cv_y_flag                                     -- 使用可能：Y
          AND    xsd.deduction_chain_code                IS NOT NULL                                      -- チェーンコード
-- Ver 1.4 add start
          AND    xsd.customer_code_to                    IS NULL                                          -- 振替先顧客コード
-- Ver 1.4 add end
          UNION ALL
          -- 企業
-- Ver 1.4 mod start
--          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N04) */
          SELECT /*+ INDEX(XSD XXCOK_SALES_DEDUCTION_N08) */
-- Ver 1.4 mod end
                 xsd.sales_deduction_id         sales_deduction_id    -- 販売控除ID
                ,CASE
                   WHEN flv.attribute2 = cv_teigaku_code THEN
                     xsd.base_code_from
                   ELSE
                     NULL
                 END                            accounting_base       -- 拠点コード(定額控除)
                ,xsd.base_code_from             past_sale_base_code   -- 振替元拠点
                ,flv.attribute4                 account               -- 勘定科目
                ,flv.attribute5                 sub_account           -- 補助科目
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_amount
                   ELSE
                     xsd.deduction_amount * -1
                 END                            deduction_amount      -- 控除額
                ,flv1.attribute1                tax_code              -- 税コード
                ,CASE
                   WHEN xsd.gl_if_flag = cv_n_flag THEN
                     xsd.deduction_tax_amount
                   ELSE
                     xsd.deduction_tax_amount * -1
                   END                          deduction_tax_amount  -- 控除税額
                ,xsd.corp_code                  corp_code             -- 企業コード
                ,gv_customer_code               customer_code         -- 顧客コード
          FROM   xxcok_sales_deduction     xsd                     -- 販売控除情報
                ,fnd_lookup_values         flv                     -- クイックコード(データ種類)
                ,fnd_lookup_values         flv1                    -- クイックコード(税コード変換)
          WHERE  flv.lookup_code                          = xsd.data_type                                 -- データ種類
          AND    flv.lookup_type                          = cv_lookup_dedu_code                           -- 控除データ種類
          AND    flv.enabled_flag                         = cv_y_flag                                     -- 使用可能：Y
          AND    flv.language                             = USERENV('LANG')                               -- 言語：USERENV('LANG')
--Ver 1.2 add start
          AND    flv.attribute13                          = gv_parallel_group                             -- GL連携パラレル実行グループ
--Ver 1.2 add end
          AND    flv1.lookup_code                         = xsd.tax_code                                  -- 税コード
          AND    flv1.lookup_type                         = cv_lookup_tax_conv_code                       -- 消費税コード変換マスタ
          AND    flv1.enabled_flag                        = cv_y_flag                                     -- 使用可能：Y
          AND    flv1.language                            = USERENV('LANG')                               -- 言語：USERENV('LANG')
          AND    TO_CHAR(xsd.record_date,cv_date_format) <= TO_CHAR(gd_from_date, cv_date_format)         -- 売上日
          AND    xsd.gl_if_flag                          IN (cv_n_flag, cv_r_flag)                        -- GL連携フラグ N：未連携、R：再送
          AND    xsd.source_category                     IN (cv_u_flag, cv_f_flag)                        -- 作成元区分 U:アップロード、F:定額控除
          AND    xsd.corp_code                           IS NOT NULL                                      -- 企業コード
-- Ver 1.4 add start
          AND    xsd.deduction_chain_code                IS NULL                                          -- チェーンコード
          AND    xsd.customer_code_to                    IS NULL                                          -- 振替先顧客コード
-- Ver 1.4 add end
         ) ;

    --==================================
    -- 販売控除データ抽出
    --==================================
    OPEN  deductions_data_cur;
    FETCH deductions_data_cur BULK COLLECT INTO gt_deductions_exp_tbl;
    CLOSE deductions_data_cur;
--
    --==================================
    -- 販売控除データ_負債科目・金額の取得
    --==================================
    OPEN  deductions_debt_data_cur;
    FETCH deductions_debt_data_cur BULK COLLECT INTO gt_deductions_debt_exp_tbl;
    CLOSE deductions_debt_data_cur;
--
      -- 取得データが０件の場合
    IF ( gt_deductions_exp_tbl.COUNT = 0 OR gt_deductions_debt_exp_tbl.COUNT = 0 ) THEN
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- アプリケーション短縮名
                                               , iv_name         => cv_tkn_deduction_msg           -- メッセージID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_data_get_msg
                                                );
      lv_errbuf       := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    --==================================
    -- 販売控除データのロック
    --==================================
-- Ver 1.3 del start
--    OPEN  deductions_data_lock_cur;
--    FETCH deductions_data_lock_cur BULK COLLECT INTO gt_deduction_lock_tbl;
--    CLOSE deductions_data_lock_cur;
-- Ver 1.3 del end
--
  EXCEPTION
    -- データ取得エラー（データ0件） ***
    WHEN no_data_expt THEN
      ov_retcode := cv_status_warn;
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
      );
 --
    -- ロックエラー
    WHEN lock_expt THEN
      -- ロックエラーメッセージ
      lv_table_name := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm              -- アプリケーション短縮名
                                               , iv_name         => cv_tkn_deduction_msg           -- メッセージID
                                                );
      lv_errmsg     := xxccp_common_pkg.get_msg( iv_application   => cv_xxcok_short_nm
                                               , iv_name          => cv_table_lock_msg
                                                );
      lv_errbuf       := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- カーソルクローズ
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- カーソルクローズ
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( deductions_data_cur%ISOPEN ) THEN
        CLOSE deductions_data_cur;
      END IF;
      -- カーソルクローズ
      IF ( deductions_debt_data_cur%ISOPEN ) THEN
        CLOSE deductions_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_gl_data
   * Description      : A-4.一般会計OIFデータ作成
   ***********************************************************************************/
  PROCEDURE edit_gl_data( ov_errbuf          OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
                        , ov_retcode         OUT VARCHAR2         -- リターン・コード             --# 固定 #
                        , ov_errmsg          OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
                        , in_gl_idx          IN  NUMBER           -- GL OIF データインデックス
                        , iv_accounting_base IN  VARCHAR2         -- 拠点コード(定額控除)
                        , iv_base_code       IN  VARCHAR2         -- 拠点コード(定額控除以外)
                        , iv_gl_segment3     IN  VARCHAR2         -- 勘定科目コード
                        , iv_gl_segment4     IN  VARCHAR2         -- 補助科目コード
                        , iv_tax_code        IN  VARCHAR2         -- 税コード
                        , iv_corp_code       IN  VARCHAR2         -- 企業コード
                        , iv_customer_code   IN  VARCHAR2         -- 顧客コード
                        , in_entered_dr      IN  NUMBER           -- 借方金額
                        , in_entered_cr      IN  NUMBER           -- 貸方金額
                        , in_gl_contact_id   IN  NUMBER           -- GL紐付ID
                        , iv_reference10     IN  VARCHAR2 )       -- reference10
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'edit_gl_data';      -- プログラム名
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCFO';             -- 共通領域短縮アプリ名
    cv_ccid_chk_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10052';  -- 勘定科目ID（CCID）取得エラーメッセージ
--
    -- CCID
    cv_tkn_pro_date    CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';      -- トークン：処理日
    cv_tkn_com_code    CONSTANT VARCHAR2(20)  := 'COM_CODE';          -- トークン：会社コード
    cv_tkn_dept_code   CONSTANT VARCHAR2(20)  := 'DEPT_CODE';         -- トークン：部門コード
    cv_tkn_acc_code    CONSTANT VARCHAR2(20)  := 'ACC_CODE';          -- トークン：勘定科目コード
    cv_tkn_ass_code    CONSTANT VARCHAR2(20)  := 'ASS_CODE';          -- トークン：補助科目コード
    cv_tkn_cust_code   CONSTANT VARCHAR2(20)  := 'CUST_CODE';         -- トークン：顧客コード
    cv_tkn_ent_code    CONSTANT VARCHAR2(20)  := 'ENT_CODE';          -- トークン：企業コード
    cv_tkn_res1_code   CONSTANT VARCHAR2(20)  := 'RES1_CODE';         -- トークン：予備１コード
    cv_tkn_res2_code   CONSTANT VARCHAR2(20)  := 'RES2_CODE';         -- トークン：予備２コード

--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);               -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                  -- リターン・コード
    lv_errmsg  VARCHAR2(5000);               -- ユーザー・エラー・メッセージ
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
    ln_ccid_check  NUMBER;
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
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --==============================================================
    --  一般会計OIFデータ作成(A-4)
    --==============================================================
--
    ln_ccid_check := NULL;
    --==============================================================
    -- CCID存在チェック
    --==============================================================
    ln_ccid_check := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_process_date                       -- 処理日
                             , iv_segment1  => gv_company_code                       -- 会社コード
                             , iv_segment2  => NVL(iv_accounting_base,iv_base_code)  -- 部門コード
                             , iv_segment3  => iv_gl_segment3                        -- 勘定科目コード
                             , iv_segment4  => iv_gl_segment4                        -- 補助科目コード
                             , iv_segment5  => iv_customer_code                      -- 顧客コードダミー値
                             , iv_segment6  => iv_corp_code                          -- 企業コードダミー値
                             , iv_segment7  => gv_preliminary1_code                  -- 予備1ダミー値
                             , iv_segment8  => gv_preliminary2_code                  -- 予備2ダミー値
                             );
--
    IF ( ln_ccid_check IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxccp_appl_name
                      , iv_name         => cv_ccid_chk_msg                       -- 勘定科目ID（CCID）取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_pro_date
                      , iv_token_value1 => gd_process_date                       -- 処理日
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => gv_company_code                       -- 会社コード
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => NVL(iv_accounting_base,iv_base_code)  -- 部門コード
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => iv_gl_segment3                        -- 勘定科目コード
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => iv_gl_segment4                        -- 補助科目コード
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => iv_customer_code                      -- 顧客コードダミー値
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => iv_corp_code                          -- 企業コードダミー値
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_preliminary1_code                  -- 予備1ダミー値
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_preliminary2_code                  -- 予備2ダミー値
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 一般会計OIFの値セット
    gt_gl_interface_tbl( in_gl_idx ).status                := cv_status;                                                -- ステータス
    gt_gl_interface_tbl( in_gl_idx ).set_of_books_id       := TO_NUMBER(gv_set_bks_id);                                 -- 会計帳簿ID
    gt_gl_interface_tbl( in_gl_idx ).accounting_date       := gd_from_date;                                             -- 記帳日
    gt_gl_interface_tbl( in_gl_idx ).currency_code         := cv_currency_code;                                         -- 通貨コード
    gt_gl_interface_tbl( in_gl_idx ).actual_flag           := cv_actual_flag;                                           -- 残高タイプ
    gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := gv_category_code;                                         -- 仕訳カテゴリ名
    gt_gl_interface_tbl( in_gl_idx ).user_je_source_name   := gv_source_code;                                           -- 仕訳ソース名
    gt_gl_interface_tbl( in_gl_idx ).segment1              := gv_company_code;                                          -- (会社)
--
    -- 拠点コード(定額控除) が設定されていない場合は、拠点コード(定額控除以外)を登録
    IF iv_accounting_base IS NULL THEN
      gt_gl_interface_tbl( in_gl_idx ).segment2            := iv_base_code;                                             -- (部門)
    ELSE
      -- 拠点コード(定額控除) が設定されている場合は、拠点コード(定額控除)を登録
      gt_gl_interface_tbl( in_gl_idx ).segment2            := iv_accounting_base;                                       -- (部門)
    END IF;
--
    gt_gl_interface_tbl( in_gl_idx ).segment3              := iv_gl_segment3;                                           -- (勘定科目)
    gt_gl_interface_tbl( in_gl_idx ).segment4              := iv_gl_segment4;                                           -- (補助科目)
    gt_gl_interface_tbl( in_gl_idx ).segment5              := iv_customer_code;                                         -- (顧客コード)
    gt_gl_interface_tbl( in_gl_idx ).segment6              := iv_corp_code;                                             -- (企業コード)
    gt_gl_interface_tbl( in_gl_idx ).segment7              := gv_preliminary1_code;                                     -- (予備１)
    gt_gl_interface_tbl( in_gl_idx ).segment8              := gv_preliminary2_code;                                     -- (予備２)
--
    -- 売上控除金額がプラスの場合はそのまま登録
    IF (in_entered_dr >= 0 AND in_entered_cr IS NULL) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_dr;                                            -- 借方金額
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_cr;                                            -- 貸方金額
    -- 売上控除金額がマイナスの場合は貸借を入れ替え登録
    ELSIF (in_entered_dr < 0 AND in_entered_cr IS NULL ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_cr;                                            -- 借方金額
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := (in_entered_dr * -1);                                     -- 貸方金額
    -- 負債額がプラスの場合はそのまま登録
    ELSIF (in_entered_dr IS NULL AND in_entered_cr >= 0 ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := in_entered_dr;                                            -- 借方金額
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_cr;                                            -- 貸方金額
    -- 負債額がマイナスの場合は貸借を入れ替登録
    ELSIF (in_entered_dr IS NULL AND in_entered_cr < 0 ) THEN
      gt_gl_interface_tbl( in_gl_idx ).entered_dr          := (in_entered_cr * -1);                                     -- 借方金額
      gt_gl_interface_tbl( in_gl_idx ).entered_cr          := in_entered_dr;                                            -- 貸方金額
    END IF;
--
    gt_gl_interface_tbl( in_gl_idx ).reference1            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- リファレンス1（バッチ名）
    gt_gl_interface_tbl( in_gl_idx ).reference2            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- リファレンス2（バッチ摘要）
    gt_gl_interface_tbl( in_gl_idx ).reference4            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- リファレンス4（仕訳名）
    gt_gl_interface_tbl( in_gl_idx ).reference5            := TO_CHAR( gv_category_code ) || cv_underbar || gv_period;  -- リファレンス5（仕訳名摘要）
    gt_gl_interface_tbl( in_gl_idx ).reference10           := iv_reference10;                                           -- リファレンス10（仕訳明細摘要）
    gt_gl_interface_tbl( in_gl_idx ).period_name           := gv_period;                                                -- 会計期間
--2021/05/18 add start
    gt_gl_interface_tbl( in_gl_idx ).group_id              := gn_group_id;                                              -- グループID
--2021/05/18 add end
    gt_gl_interface_tbl( in_gl_idx ).attribute1            := iv_tax_code;                                              -- 属性1（消費税コード）
    gt_gl_interface_tbl( in_gl_idx ).attribute8            := in_gl_contact_id;                                         -- 属性8（GL紐付ID）
    gt_gl_interface_tbl( in_gl_idx ).context               := gv_set_bks_nm;                                            -- コンテキスト
    gt_gl_interface_tbl( in_gl_idx ).created_by            := cn_created_by;                                            -- 新規作成者
    gt_gl_interface_tbl( in_gl_idx ).date_created          := cd_creation_date;                                         -- 新規作成日
    gt_gl_interface_tbl( in_gl_idx ).request_id            := cn_request_id;                                            -- 要求ID
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
--
--#####################################  固定部 END  #####################################
--
  END edit_gl_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_work_data
   * Description      : A-3.一般会計OIF集約処理
   ***********************************************************************************/
  PROCEDURE edit_work_data( ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           -- # 固定 #
                          , ov_retcode    OUT VARCHAR2            -- リターン・コード             -- # 固定 #
                          , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ -- # 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_work_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_deduction_amount          NUMBER DEFAULT 0;                               -- 売上控除:控除額集計金額
    ln_deduction_tax_amount      NUMBER DEFAULT 0;                               -- 仮払消費税:控除税額集計金額
    ln_gl_contact_id             NUMBER;                                         -- GL連携ID
--
    ln_gl_idx                    NUMBER DEFAULT 0;                               -- GL OIFのインデックス
    ln_loop_index1               NUMBER DEFAULT 0;                               -- ワークテーブル販売控除インデックス
    ln_loop_index2               NUMBER DEFAULT 0;                               -- ワークテーブル販売控除負債インデックス
    ln_loop_cnt                  NUMBER DEFAULT 0;                               -- 定額控除確認用件数
    lv_account_code              VARCHAR2(5);                                    -- 税コード勘定科目用
    lv_sub_account_code          VARCHAR2(5);                                    -- 税コード補助科目用
    lv_debt_account_code         VARCHAR2(5);                                    -- 税コード勘定科目用
    lv_debt_sub_account_code     VARCHAR2(5);                                    -- 税コード補助科目用
--
    -- 集計キー
    lt_accounting_base           xxcok_condition_lines.accounting_base%TYPE;     -- 集計キー：拠点コード(定額控除)
    lt_past_sale_base_code       xxcmm_cust_accounts.past_sale_base_code%TYPE;   -- 集計キー：拠点コード(定額控除以外)
    lt_account                   fnd_lookup_values.attribute4%TYPE;              -- 集計キー：勘定科目
    lt_sub_account               fnd_lookup_values.attribute5%TYPE;              -- 集計キー：補助科目
    lt_tax_code                  xxcok_sales_deduction.tax_code%TYPE;            -- 集計キー：税コード
    lt_corp_code                 fnd_lookup_values.attribute1%TYPE;              -- 集計キー：企業コード
    lt_customer_code             fnd_lookup_values.attribute4%TYPE;              -- 集計キー：顧客コード
--
    -- *** ローカル例外 ***
    edit_gl_expt                 EXCEPTION;                                      -- 一般会計作成エラー
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --=====================================
    -- 1.仕訳パターンの取得
    --=====================================
    -- ブレイク用集約キーの初期化
    lt_accounting_base      := gt_deductions_exp_tbl(1).accounting_base;      -- 拠点コード(定額控除)
    lt_past_sale_base_code  := gt_deductions_exp_tbl(1).past_sale_base_code;  -- 拠点コード(定額控除以外)
    lt_account              := gt_deductions_exp_tbl(1).account;              -- 勘定科目
    lt_sub_account          := gt_deductions_exp_tbl(1).sub_account;          -- 補助科目
    lt_tax_code             := gt_deductions_exp_tbl(1).tax_code;             -- 税コード
    lt_corp_code            := gt_deductions_exp_tbl(1).corp_code;            -- 企業コード
    lt_customer_code        := gt_deductions_exp_tbl(1).customer_code;        -- 顧客コード
--
    -- 控除額/消費税/負債消費税のループスタート
    <<main_data_loop>>
    FOR ln_loop_index1 IN 1..gt_deductions_exp_tbl.COUNT LOOP
--
      -- ==========================
      --  レコードブレイク判定
      -- ==========================
--
      -- 定額控除の場合
      IF ( lt_accounting_base IS NOT NULL) THEN
        -- 拠点コード(定額控除)/勘定科目/補助科目/税コードのいずれかが前処理データ異なった場合
        IF ( lt_accounting_base   <> NVL(gt_deductions_exp_tbl(ln_loop_index1).accounting_base,cv_dummy_code) )
          OR  ( lt_account               <> gt_deductions_exp_tbl(ln_loop_index1).account )
          OR  ( lt_sub_account           <> gt_deductions_exp_tbl(ln_loop_index1).sub_account )
          OR  ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code )
          OR  ( lt_corp_code             <> gt_deductions_exp_tbl(ln_loop_index1).corp_code )
          OR  ( lt_customer_code         <> gt_deductions_exp_tbl(ln_loop_index1).customer_code ) THEN

--
          --販売控除データの集約(費用)
          ln_gl_idx := ln_gl_idx + 1;
--
          edit_gl_data( ov_errbuf                 => lv_errbuf                 -- エラー・メッセージ
                      , ov_retcode                => lv_retcode                -- リターン・コード
                      , ov_errmsg                 => lv_errmsg                 -- ユーザー・エラー・メッセージ
                      , in_gl_idx                 => ln_gl_idx                 -- GL OIF データインデックス
                      , iv_accounting_base        => lt_accounting_base        -- 拠点コード(定額控除)
                      , iv_base_code              => lt_past_sale_base_code    -- 拠点コード(定額控除以外)
                      , iv_gl_segment3            => lt_account                -- 勘定科目コード
                      , iv_gl_segment4            => lt_sub_account            -- 補助科目コード
                      , iv_tax_code               => lt_tax_code               -- 税コード
                      , iv_corp_code              => lt_corp_code              -- 企業コード
                      , iv_customer_code          => lt_customer_code          -- 顧客コード
                      , in_entered_dr             => ln_deduction_amount       -- 借方金額
                      , in_entered_cr             => NULL                      -- 貸方金額
                      , in_gl_contact_id          => ln_gl_contact_id          -- GL紐付ID
                      , iv_reference10            => gv_category_code || cv_underbar || gv_period
                                                                               -- reference10
                       );
--
--Ver 1.2 add start
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_gl_expt;
          END IF;
--
--Ver 1.2 add end
          --控除額集約初期化
          ln_deduction_amount := 0;
--
          ln_loop_cnt := 0;
--
        END IF;
--
      -- 定額控除以外の場合
      ELSE
        -- 拠点コード(定額控除以外)/勘定科目/補助科目/税コードのいずれかが前処理データ異なった場合
        IF ( lt_past_sale_base_code   <> gt_deductions_exp_tbl(ln_loop_index1).past_sale_base_code )
          OR  ( lt_account               <> gt_deductions_exp_tbl(ln_loop_index1).account )
          OR  ( lt_sub_account           <> gt_deductions_exp_tbl(ln_loop_index1).sub_account )
          OR  ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code )
          OR  ( lt_corp_code             <> gt_deductions_exp_tbl(ln_loop_index1).corp_code )
          OR  ( lt_customer_code         <> gt_deductions_exp_tbl(ln_loop_index1).customer_code ) THEN
--
          --販売控除データの集約(費用)
          ln_gl_idx := ln_gl_idx + 1;
--
          edit_gl_data( ov_errbuf                 => lv_errbuf                 -- エラー・メッセージ
                      , ov_retcode                => lv_retcode                -- リターン・コード
                      , ov_errmsg                 => lv_errmsg                 -- ユーザー・エラー・メッセージ
                      , in_gl_idx                 => ln_gl_idx                 -- GL OIF データインデックス
                      , iv_accounting_base        => lt_accounting_base        -- 拠点コード(定額控除)
                      , iv_base_code              => lt_past_sale_base_code    -- 拠点コード(定額控除以外)
                      , iv_gl_segment3            => lt_account                -- 勘定科目コード
                      , iv_gl_segment4            => lt_sub_account            -- 補助科目コード
                      , iv_tax_code               => lt_tax_code               -- 税コード
                      , iv_corp_code              => lt_corp_code              -- 企業コード
                      , iv_customer_code          => lt_customer_code          -- 顧客コード
                      , in_entered_dr             => ln_deduction_amount       -- 借方金額
                      , in_entered_cr             => NULL                      -- 貸方金額
                      , in_gl_contact_id          => ln_gl_contact_id          -- GL紐付ID
                      , iv_reference10            => gv_category_code || cv_underbar || gv_period
                                                                               -- reference10
                       );
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_gl_expt;
          END IF;
--
          --控除額集約初期化
          ln_deduction_amount := 0;
--
          ln_loop_cnt := 0;
--
        END IF;
--
      END IF;
--
      -- 税コードが前処理データ異なった場合
      IF ( lt_tax_code              <> gt_deductions_exp_tbl(ln_loop_index1).tax_code ) THEN
--
        --税コードマスタより税コードを引き渡して勘定科目、補助科目を取得
        BEGIN
          SELECT gcc.segment3            -- 税額_勘定科目
                ,gcc.segment4            -- 税額_補助科目
                ,tax.attribute5          -- 負債税額_勘定科目
                ,tax.attribute6          -- 負債税額_補助科目
          INTO   lv_account_code
                ,lv_sub_account_code
                ,lv_debt_account_code
                ,lv_debt_sub_account_code
          FROM   apps.ap_tax_codes_all     tax  -- AP税コードマスタ
                ,apps.gl_code_combinations gcc  -- 勘定組合情報
          WHERE  tax.set_of_books_id     = TO_NUMBER(gv_set_bks_id)       -- SET_OF_BOOKS_ID
          and    tax.org_id              = gn_org_id                      -- ORG_ID
          and    gcc.code_combination_id = tax.tax_code_combination_id    -- 税CCID
          and    tax.name                = lt_tax_code                    -- 税コード
          AND    tax.enabled_flag        = cv_y_flag                      -- 有効
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
          -- 勘定科目が取得出来ない場合
            lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                  , cv_account_error_msg
                                                   );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        --販売控除データの集約(税・費用)
        ln_gl_idx := ln_gl_idx + 1;
--
        edit_gl_data( ov_errbuf                 => lv_errbuf                       -- エラー・メッセージ
                    , ov_retcode                => lv_retcode                      -- リターン・コード
                    , ov_errmsg                 => lv_errmsg                       -- ユーザー・エラー・メッセージ
                    , in_gl_idx                 => ln_gl_idx                       -- GL OIF データインデックス
                    , iv_accounting_base        => NULL                            -- 拠点コード(定額控除)
                    , iv_base_code              => gv_dept_fin_code                -- 拠点コード(定額控除以外)
                    , iv_gl_segment3            => lv_account_code                 -- 勘定科目コード
                    , iv_gl_segment4            => lv_sub_account_code             -- 補助科目コード
                    , iv_tax_code               => lt_tax_code                     -- 税コード
                    , iv_corp_code              => gv_comp_code                    -- 企業コード
                    , iv_customer_code          => gv_customer_code                -- 顧客コード
                    , in_entered_dr             => ln_deduction_tax_amount         -- 借方金額
                    , in_entered_cr             => NULL                            -- 貸方金額
                    , in_gl_contact_id          => NULL                            -- GL紐付ID
                    , iv_reference10            => '消費税行' || cv_underbar || lt_tax_code
                                                                                   -- reference10
                     );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE edit_gl_expt;
        END IF;
--
        --販売控除データの集約(税・負債)
        ln_gl_idx := ln_gl_idx + 1;
--
        edit_gl_data( ov_errbuf                 => lv_errbuf                     -- エラー・メッセージ
                    , ov_retcode                => lv_retcode                    -- リターン・コード
                    , ov_errmsg                 => lv_errmsg                     -- ユーザー・エラー・メッセージ
                    , in_gl_idx                 => ln_gl_idx                     -- GL OIF データインデックス
                    , iv_accounting_base        => NULL                          -- 拠点コード(定額控除)
                    , iv_base_code              => gv_dept_fin_code              -- 拠点コード(定額控除以外)
                    , iv_gl_segment3            => lv_debt_account_code          -- 勘定科目コード
                    , iv_gl_segment4            => lv_debt_sub_account_code      -- 補助科目コード
                    , iv_tax_code               => NULL                          -- 税コード
                    , iv_corp_code              => gv_comp_code                  -- 企業コード
                    , iv_customer_code          => gv_customer_code              -- 顧客コード
                    , in_entered_dr             => NULL                          -- 借方金額
                    , in_entered_cr             => ln_deduction_tax_amount       -- 貸方金額
                    , in_gl_contact_id          => NULL                          -- GL紐付ID
                    , iv_reference10            => '負債税行' || cv_underbar || lt_tax_code
                                                                                   -- reference10
                     );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE edit_gl_expt;
        END IF;
--
        --消費税額集約初期化
        ln_deduction_tax_amount := 0;
--
      END IF;
--
      --出力用金額の集約
      -- 控除額の集約
      ln_deduction_amount      := NVL(ln_deduction_amount,0)     + NVL(gt_deductions_exp_tbl(ln_loop_index1).deduction_amount,0);
      -- 消費税額の集約
      ln_deduction_tax_amount  := NVL(ln_deduction_tax_amount,0) + NVL(gt_deductions_exp_tbl(ln_loop_index1).deduction_tax_amount,0);
--
      -- ブレイク用集約キーセット
      lt_accounting_base       := gt_deductions_exp_tbl(ln_loop_index1).accounting_base;       -- 拠点コード(定額控除)
      lt_past_sale_base_code   := gt_deductions_exp_tbl(ln_loop_index1).past_sale_base_code;   -- 拠点コード(定額控除以外)
      lt_account               := gt_deductions_exp_tbl(ln_loop_index1).account;               -- 勘定科目
      lt_sub_account           := gt_deductions_exp_tbl(ln_loop_index1).sub_account;           -- 補助科目
      lt_tax_code              := gt_deductions_exp_tbl(ln_loop_index1).tax_code;              -- 税コード
      lt_corp_code             := gt_deductions_exp_tbl(ln_loop_index1).corp_code;             -- 企業コード
      lt_customer_code         := gt_deductions_exp_tbl(ln_loop_index1).customer_code;         -- 顧客コード
--
      --処理件数を取得
      gn_target_cnt             := gn_target_cnt + 1;
--
      --更新処理用に販売控除ID、GL計上拠点を取得
      gt_deduction_tbl( ln_loop_index1 ).sales_deduction_id := gt_deductions_exp_tbl(ln_loop_index1).sales_deduction_id;
      gt_deduction_tbl( ln_loop_index1 ).gl_base_code       := NVL(gt_deductions_exp_tbl(ln_loop_index1).accounting_base,
                                                                   gt_deductions_exp_tbl(ln_loop_index1).past_sale_base_code);

--
      IF ( ln_loop_cnt = 0 ) THEN
        --GL紐付ID取得
        SELECT xxcok_gl_interface_seq_s01.NEXTVAL gl_seq
        INTO   ln_gl_contact_id
        FROM   DUAL
        ;
--
        ln_loop_cnt := 1;
--
      END IF;
--
      -- 更新処理用にGL紐付IDを取得
      gt_deduction_tbl( ln_loop_index1 ).gl_interface_id := ln_gl_contact_id;
--
    END LOOP main_data_loop ;
--
    --最終レコード出力
    IF ( gt_deductions_exp_tbl.COUNT > 0 ) THEN
--
      --販売控除データの集約
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                 -- エラー・メッセージ
                  , ov_retcode                => lv_retcode                -- リターン・コード
                  , ov_errmsg                 => lv_errmsg                 -- ユーザー・エラー・メッセージ
                  , in_gl_idx                 => ln_gl_idx                 -- GL OIF データインデックス
                  , iv_accounting_base        => lt_accounting_base        -- 拠点コード(定額控除)
                  , iv_base_code              => lt_past_sale_base_code    -- 拠点コード(定額控除以外)
                  , iv_gl_segment3            => lt_account                -- 勘定科目コード
                  , iv_gl_segment4            => lt_sub_account            -- 補助科目コード
                  , iv_tax_code               => lt_tax_code               -- 税コード
                  , iv_corp_code              => lt_corp_code              -- 企業コード
                  , iv_customer_code          => lt_customer_code          -- 顧客コード
                  , in_entered_dr             => ln_deduction_amount       -- 借方金額
                  , in_entered_cr             => NULL                      -- 貸方金額
                  , in_gl_contact_id          => ln_gl_contact_id          -- GL紐付ID
                  , iv_reference10            => gv_category_code || cv_underbar || gv_period
                                                                           -- reference10
                 );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
      --税コードマスタより税コードを引き渡して勘定科目、補助科目を取得
      BEGIN
        SELECT gcc.segment3            -- 税額_勘定科目
              ,gcc.segment4            -- 税額_補助科目
              ,tax.attribute5          -- 負債税額_勘定科目
              ,tax.attribute6          -- 負債税額_補助科目
        INTO   lv_account_code
              ,lv_sub_account_code
              ,lv_debt_account_code
              ,lv_debt_sub_account_code
        FROM   apps.ap_tax_codes_all     tax  -- AP税コードマスタ
              ,apps.gl_code_combinations gcc  -- 勘定組合情報
        WHERE  tax.set_of_books_id     = TO_NUMBER(gv_set_bks_id)       -- SET_OF_BOOKS_ID
        and    tax.org_id              = gn_org_id                      -- ORG_ID
        and    gcc.code_combination_id = tax.tax_code_combination_id    -- 税CCID
        and    tax.name                = lt_tax_code                    -- 税コード
        AND    tax.enabled_flag        = cv_y_flag                      -- 有効
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
        -- 勘定科目が取得出来ない場合
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                , cv_account_error_msg
                                                 );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      --販売控除データの集約
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                       -- エラー・メッセージ
                  , ov_retcode                => lv_retcode                      -- リターン・コード
                  , ov_errmsg                 => lv_errmsg                       -- ユーザー・エラー・メッセージ
                  , in_gl_idx                 => ln_gl_idx                       -- GL OIF データインデックス
                  , iv_accounting_base        => NULL                            -- 拠点コード(定額控除)
                  , iv_base_code              => gv_dept_fin_code                -- 拠点コード(定額控除以外)
                  , iv_gl_segment3            => lv_account_code                 -- 勘定科目コード
                  , iv_gl_segment4            => lv_sub_account_code             -- 補助科目コード
                  , iv_tax_code               => lt_tax_code                     -- 税コード
                  , iv_corp_code              => gv_comp_code                    -- 企業コード
                  , iv_customer_code          => gv_customer_code                -- 顧客コード
                  , in_entered_dr             => ln_deduction_tax_amount         -- 借方金額
                  , in_entered_cr             => NULL                            -- 貸方金額
                  , in_gl_contact_id          => NULL                            -- GL紐付ID
                  , iv_reference10            => '消費税行' || cv_underbar || lt_tax_code
                                                                                 -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
      --販売控除データの集約
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                     -- エラー・メッセージ
                  , ov_retcode                => lv_retcode                    -- リターン・コード
                  , ov_errmsg                 => lv_errmsg                     -- ユーザー・エラー・メッセージ
                  , in_gl_idx                 => ln_gl_idx                     -- GL OIF データインデックス
                  , iv_accounting_base        => NULL                          -- 拠点コード(定額控除)
                  , iv_base_code              => gv_dept_fin_code              -- 拠点コード(定額控除以外)
                  , iv_gl_segment3            => lv_debt_account_code          -- 勘定科目コード
                  , iv_gl_segment4            => lv_debt_sub_account_code      -- 補助科目コード
                  , iv_tax_code               => NULL                          -- 税コード
                  , iv_corp_code              => gv_comp_code                  -- 企業コード
                  , iv_customer_code          => gv_customer_code              -- 顧客コード
                  , in_entered_dr             => NULL                          -- 借方金額
                  , in_entered_cr             => ln_deduction_tax_amount       -- 貸方金額
                  , in_gl_contact_id          => NULL                          -- GL紐付ID
                  , iv_reference10            => '負債税行' || cv_underbar || lt_tax_code
                                                                               -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
    END IF;
--
    -- 負債額のループスタート
    <<debt_data_loop>>
    FOR ln_loop_index2 IN 1..gt_deductions_debt_exp_tbl.COUNT LOOP
--
      --販売控除データの集約
      ln_gl_idx := ln_gl_idx + 1;
--
      edit_gl_data( ov_errbuf                 => lv_errbuf                                                    -- エラー・メッセージ
                  , ov_retcode                => lv_retcode                                                   -- リターン・コード
                  , ov_errmsg                 => lv_errmsg                                                    -- ユーザー・エラー・メッセージ
                  , in_gl_idx                 => ln_gl_idx                                                    -- GL OIF データインデックス
                  , iv_accounting_base        => NULL                                                         -- 拠点コード(定額控除)
                  , iv_base_code              => gv_dept_fin_code                                             -- 拠点コード(定額控除以外)
                  , iv_gl_segment3            => gt_deductions_debt_exp_tbl(ln_loop_index2).account           -- 勘定科目コード
                  , iv_gl_segment4            => gt_deductions_debt_exp_tbl(ln_loop_index2).sub_account       -- 補助科目コード
                  , iv_tax_code               => NULL                                                         -- 税コード
                  , iv_corp_code              => gv_comp_code                                                 -- 企業コード
                  , iv_customer_code          => gv_customer_code                                             -- 顧客コード
                  , in_entered_dr             => NULL                                                         -- 借方金額
                  , in_entered_cr             => gt_deductions_debt_exp_tbl(ln_loop_index2).deduction_amount  -- 貸方金額
                  , in_gl_contact_id          => NULL                                                         -- GL紐付ID
                  , iv_reference10            => gv_category_code || cv_underbar || gv_period                 -- reference10
                   );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_gl_expt;
      END IF;
--
    END LOOP debt_data_loop ;
--
    --一般会計OIFに作成した件数を取得
    gn_normal_cnt := ln_gl_idx;
--
  EXCEPTION
    WHEN edit_gl_expt THEN
--Ver 1.2 del start
--      lv_errbuf  := lv_errmsg;
--Ver 1.2 del end
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--################################  固定例外処理部 START  ################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
--
  END edit_work_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : A-5.一般会計OIF登録処理
   ***********************************************************************************/
  PROCEDURE insert_gl_data( ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
                          , ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
                          , ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_tbl_nm           VARCHAR2(255);                -- テーブル名
--
    -- *** ローカル例外 ***
    insert_data_expt    EXCEPTION ;                   -- 登録処理エラー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --==============================================================
    -- 一般会計OIFテーブルへデータ登録
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_gl_interface_tbl.COUNT
        INSERT INTO
          gl_interface
        VALUES
          gt_gl_interface_tbl(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE insert_data_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN insert_data_expt THEN
      -- 登録に失敗した場合
      -- エラー件数設定
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm               -- アプリ短縮名
                      , iv_name              => cv_tkn_gloif_msg                -- メッセージID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcok_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_gl_data;
--
  /***********************************************************************************
   * Procedure Name   : update_deduction_data
   * Description      : 販売控除情報更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE update_deduction_data( ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
                                  ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
                                  ,ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(25) := 'update_deduction_data'; -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode VARCHAR2(1);                 -- リターン・コード
    lv_errmsg  VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--#####################################  固定部 END  #####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER DEFAULT 0;      -- ループカウント用変数
--
    -- *** ローカル例外 ***
    update_data_expt    EXCEPTION ;            -- 更新処理エラー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --==============================================================
    -- 販売控除情報更新処理
    --==============================================================
--
    -- 処理対象データのGL連携フラグを一括更新する
    IF ( gt_deductions_exp_tbl.COUNT > 0 ) THEN
      -- 正常データ更新
      --再送の場合は取消GL記帳日の更新を行う
--
      BEGIN
        FORALL ln_loop_cnt IN 1..gt_deduction_tbl.COUNT
          UPDATE xxcok_sales_deduction     xsd                                                   -- 販売控除情報
          SET    xsd.gl_if_flag             = cv_y_flag                                          -- GLインタフェース済フラグ
                ,xsd.gl_date                = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  gd_from_date
                                                ELSE
                                                  xsd.gl_date
                                              END                                                -- GL記帳日
                ,xsd.gl_base_code           = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  gt_deduction_tbl(ln_loop_cnt).gl_base_code
                                                ELSE
                                                  xsd.gl_base_code
                                              END                                                -- GL計上拠点
                ,xsd.cancel_gl_date         = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  xsd.cancel_gl_date
                                                ELSE
                                                  gd_from_date
                                              END                                                -- 取消GL記帳日
                ,xsd.cancel_base_code       = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  xsd.cancel_base_code
                                                ELSE
                                                  gt_deduction_tbl(ln_loop_cnt).gl_base_code
                                              END                                                -- 取消時計上拠点
                ,xsd.gl_interface_id        = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  gt_deduction_tbl(ln_loop_cnt).gl_interface_id
                                                ELSE
                                                   xsd.gl_interface_id
                                              END                                                -- GL紐付ID
                ,xsd.cancel_gl_interface_id = CASE
                                                WHEN xsd.gl_if_flag = cv_n_flag  THEN
                                                  xsd.cancel_gl_interface_id
                                                ELSE
                                                  gt_deduction_tbl(ln_loop_cnt).gl_interface_id
                                                END                                              -- 取消GL紐付ID
                ,xsd.last_updated_by        = cn_last_updated_by                                 -- 最終更新者
                ,xsd.last_update_date       = cd_last_update_date                                -- 最終更新日
                ,xsd.last_update_login      = cn_last_update_login                               -- 最終更新ログイン
                ,xsd.request_id             = cn_request_id                                      -- 要求ID
                ,xsd.program_application_id = cn_program_application_id                          -- コンカレント・プログラム・アプリID
                ,xsd.program_id             = cn_program_id                                      -- コンカレント・プログラムID
                ,xsd.program_update_date    = cd_program_update_date                             -- プログラム更新日
          WHERE xsd.sales_deduction_id      = gt_deduction_tbl(ln_loop_cnt).sales_deduction_id   -- 販売控除ID
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf := SQLERRM;
            RAISE update_data_expt;
      END;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN update_data_expt THEN
      -- 更新に失敗した場合
      -- エラー件数設定
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => cv_sales_deduction
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => gt_deduction_tbl(ln_loop_cnt).sales_deduction_id
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END update_deduction_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
                   , ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
                   , ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_normal_cnt    := 0;                 -- 登録件数
    gn_target_cnt    := 0;                 -- 対象件数
    gn_error_cnt     := 0;                 -- エラー件数
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
        , ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
        , ov_errmsg  => lv_errmsg );         -- ユーザー・エラー・メッセージ -- # 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.販売控除データ抽出
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
      , ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
      , ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ステータスが正常（データが1件以上抽出）であればA-3以降を実行する
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================
      -- A-3.一般会計OIF集約処理 (A-4 処理の呼出を含め)
      -- ===============================
      edit_work_data(
           ov_errbuf  => lv_errbuf           -- エラー・メッセージ           --# 固定 #
         , ov_retcode => lv_retcode          -- リターン・コード             --# 固定 #
         , ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.一般会計OIFデータ登録処理
      -- ===============================
      insert_gl_data(
            ov_errbuf       => lv_errbuf     -- エラー・メッセージ
          , ov_retcode      => lv_retcode    -- リターン・コード
          , ov_errmsg       => lv_errmsg     -- ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-6.販売控除情報更新処理
      -- ===============================
      update_deduction_data(
          ov_errbuf  => lv_errbuf            -- エラー・メッセージ
        , ov_retcode => lv_retcode           -- リターン・コード
        , ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ
        );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      ov_retcode := lv_retcode;
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
  PROCEDURE main( errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
--Ver 1.2 mod start
--                , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
                , retcode     OUT VARCHAR2               -- リターン・コード    --# 固定 #
                , parallel_group IN VARCHAR2 )           -- GL連携パラレル実行グループ
--Ver 1.2 mod end
                
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- 共通領域短縮アプリ名
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 登録件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--#####################################  固定部 END  #####################################
--
--Ver 1.2 add start
    -- GL連携パラレル実行グループ設定
    gv_parallel_group := parallel_group;
--Ver 1.2 add end
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- エラー・メッセージ           --# 固定 #
           , ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
           , ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    --エラー出力
    IF (lv_retcode = cv_status_error ) THEN
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
    -- A-7.終了処理
    -- ===============================
    --空行挿入
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    --エラーの場合、成功件数クリア、エラー件数設定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --処理対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_target_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_success_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                          , iv_name         => cv_error_rec_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --終了メッセージ
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                          , iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
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
  END main;
--
--#####################################  固定部 END  #####################################
--
END XXCOK024A06C;
/
