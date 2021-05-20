CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A18C (body)
 * Description      : 控除額の支払・入金相殺データが承認されたデータを対象に、控除消込情報を基に、
 *                    控除情報から消込仕訳情報を抽出してGL仕訳の作成し、一般会計OIFに連携する処理
 * MD.050           : 控除データ決済仕訳情報取得 MD050_COK_024_A18
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_data               A-2.販売控除データ抽出
 *  edit_work_data         A-3.一般会計OIF集約処理
 *  edit_gl_data           A-4.GL一般会計OIFデータ作成
 *  insert_gl_data         A-5.GL一般会計OIFデータインサート処理
 *  up_ded_recon_data      A-6.控除消込ヘッダー情報更新処理
 *  get_gl_cancel_data     A-7.GL仕訳データ抽出（取消）
 *  insert_gl_cancel_data  A-8.GL一般会計OIFデータインサート処理（取消）
 *  up_recon_cancel_data   A-9.控除消込ヘッダー情報更新処理（取消）
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(終了処理A-10を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/11/24    1.0   H.Ishii          新規作成
 *  2021/05/18    1.1   SCSK K.Yoshikawa GROUP_ID追加対応
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
  gn_normal_cnt    NUMBER   DEFAULT 0;                   -- 承認済みとなった支払伝票単位の件数
  gn_target_cnt    NUMBER   DEFAULT 0;                   -- 一般会計OIFに作成した支払伝票単位の件数
  gn_cancel_cnt    NUMBER   DEFAULT 0;                   -- 一般会計OIFに作成した取消する支払伝票単位の件数
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A18C';                     -- パッケージ名
  -- アプリケーション短縮名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                            -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                 -- 業務日付取得エラー
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';                 -- プロファイル取得エラー
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
  cv_pro_category_cd_2      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10690';                 -- 仕訳カテゴリ（控除消込）
  cv_sales_deduction        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10650';                 -- 販売控除情報
  cv_tax_account_error_msg  CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10681';                 -- 税情報取得エラーメッセージ
  cv_pro_org_id             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10669';                 -- 組織ID
--2021/05/18 add start
  cv_group_id_msg           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00024';                 -- グループID取得エラー
--2021/05/18 add end
--
  -- トークン
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';                         -- プロファイル
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';                      -- テーブル名称
  cv_tkn_key_data           CONSTANT  VARCHAR2(20) := 'KEY_DATA';                        -- キー項目
  -- フラグ・区分定数
  cv_recon_status_ad        CONSTANT  VARCHAR2(2)  := 'AD';                              -- 承認済:AD
  cv_recon_status_cd        CONSTANT  VARCHAR2(2)  := 'CD';                              -- 取消済:CD
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';                               -- フラグ値:Y
  cv_d_flag                 CONSTANT  VARCHAR2(1)  := 'D';                               -- フラグ値:D
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';                               -- フラグ値:N
  cv_o_flag                 CONSTANT  VARCHAR2(1)  := 'O';                               -- フラグ値:O
  cv_r_flag                 CONSTANT  VARCHAR2(1)  := 'R';                               -- フラグ値:R
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';                               -- フラグ値:S
  cv_t_flag                 CONSTANT  VARCHAR2(1)  := 'T';                               -- フラグ値:T
  cv_u_flag                 CONSTANT  VARCHAR2(1)  := 'U';                               -- フラグ値:U
  cv_f_flag                 CONSTANT  VARCHAR2(1)  := 'F';                               -- フラグ値:F
  cv_c_flag                 CONSTANT  VARCHAR2(1)  := 'C';                               -- フラグ値:C
  cv_syuyaku_flag           CONSTANT  VARCHAR2(1)  := '*';                               -- フラグ値:*
  cv_date_format_1          CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';                      -- 書式フォーマットYYYY/MM/DD
  cv_dummy_date             CONSTANT  VARCHAR2(10) := '9999/12/31';                      -- DUMMY日付
  cv_date_format            CONSTANT  VARCHAR2(6)  := 'YYYYMM';                          -- 書式フォーマットYYYYMM
  cv_source_name            CONSTANT  VARCHAR2(10) := '控除作成';                        -- ソース名
  -- クイックコード
  cv_lookup_dedu_code       CONSTANT  VARCHAR2(30) := 'XXCOK1_DEDUCTION_DATA_TYPE';      -- 控除データ種類
  cv_lookup_tax_conv_code   CONSTANT  VARCHAR2(30) := 'XXCOK1_CONSUMP_TAX_CODE_CONV';    -- 消費税コード変換マスタ
  cv_period_set_name        CONSTANT  VARCHAR2(30) := 'SALES_CALENDAR';                  -- 会計カレンダ
  cv_lookup_chain_code      CONSTANT  VARCHAR2(20) := 'XXCMM_CHAIN_CODE';                -- チェーンコードマスタ
  -- 一般会計OIFテーブルに設定する固定値
  cv_status                 CONSTANT  VARCHAR2(3)  := 'NEW';                             -- ステータス
  cv_currency_code          CONSTANT  VARCHAR2(3)  := 'JPY';                             -- 通貨コード
  cv_actual_flag            CONSTANT  VARCHAR2(1)  := 'A';                               -- 残高タイプ
  cv_underbar               CONSTANT  VARCHAR2(1)  := '_';                               -- 項目区切り用
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 控除消込取消ワークテーブル定義
  TYPE gr_recon_dedu_cancel_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE
     ,recon_slip_num            xxcok_deduction_recon_head.recon_slip_num%TYPE
     ,gl_date                   xxcok_deduction_recon_head.gl_date%TYPE
     ,b_name                    gl_je_batches.name%TYPE
     ,b_description             gl_je_batches.description%TYPE
     ,h_name                    gl_je_headers.name%TYPE
     ,h_description             gl_je_headers.description%TYPE
     ,period_name               gl_je_headers.period_name%TYPE
     ,user_je_source_name       gl_je_sources_tl.user_je_source_name%TYPE
     ,user_je_category_name     gl_je_categories_tl.user_je_category_name%TYPE
     ,segment1                  gl_code_combinations.segment1%TYPE
     ,segment2                  gl_code_combinations.segment2%TYPE
     ,segment3                  gl_code_combinations.segment3%TYPE
     ,segment4                  gl_code_combinations.segment4%TYPE
     ,segment5                  gl_code_combinations.segment5%TYPE
     ,segment6                  gl_code_combinations.segment6%TYPE
     ,segment7                  gl_code_combinations.segment7%TYPE
     ,segment8                  gl_code_combinations.segment8%TYPE
     ,l_description             gl_je_lines.description%TYPE
     ,entered_dr                gl_je_lines.entered_dr%TYPE
     ,entered_cr                gl_je_lines.entered_cr%TYPE
     ,tax_code                  gl_je_lines.attribute1%TYPE
     ,recon_slip_num_1          gl_je_lines.attribute3%TYPE
     ,context                   gl_je_lines.context%TYPE
  );
--
  -- 販売控除消込情報ワークテーブル定義
  TYPE gr_recon_deductions_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- 控除消込ヘッダーID
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- 支払伝票番号
     ,interface_div             xxcok_deduction_recon_head.interface_div%TYPE             -- 連携先
     ,data_type                 fnd_lookup_values.attribute2%TYPE                         -- 控除タイプ
     ,gl_date                   xxcok_deduction_recon_head.gl_date%TYPE                   -- GL記帳日
     ,period_name               gl_periods.period_name%TYPE                               -- 会計期間
     ,recon_base_code           xxcok_sales_deduction.recon_base_code%TYPE                -- 消込時計上拠点
     ,deduction_amount          xxcok_sales_deduction.deduction_amount%TYPE               -- 控除額
     ,tax_code                  fnd_lookup_values.attribute1%TYPE                         -- 税コード
     ,tax_rate                  xxcok_sales_deduction.tax_rate%TYPE                       -- 税率
     ,deduction_tax_amount      xxcok_sales_deduction.deduction_tax_amount%TYPE           -- 控除税額
     ,source_category           xxcok_sales_deduction.source_category%TYPE                -- 作成元区分
     ,meaning                   fnd_lookup_values.meaning%TYPE                            -- 内容（データ種類名）
     ,account                   fnd_lookup_values.attribute4%TYPE                         -- 勘定科目
     ,sub_account               fnd_lookup_values.attribute5%TYPE                         -- 補助科目
     ,corp_code                 fnd_lookup_values.attribute1%TYPE                         -- 企業コード
     ,customer_code             fnd_lookup_values.attribute4%TYPE                         -- 顧客コード

  );
--
  -- 差額調整情報ワークテーブル定義
  TYPE gr_recon_dedu_debt_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- 支払伝票番号
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- 支払伝票番号
     ,gl_date                   gl_periods.end_date%TYPE                                  -- GL記帳日
     ,period_name               gl_periods.period_name%TYPE                               -- 会計期間
     ,meaning                   fnd_lookup_values.meaning%TYPE                            -- 内容
     ,debt_account              fnd_lookup_values.attribute6%TYPE                         -- 負債勘定科目
     ,debt_sub_account          fnd_lookup_values.attribute7%TYPE                         -- 負債補助科目
     ,interface_div             xxcok_deduction_recon_head.interface_div%TYPE             -- 連携先
     ,debt_deduction_amount     xxcok_sales_deduction.deduction_amount%TYPE               -- 負債額
  );
--
  TYPE gr_recon_work_rec IS RECORD(
      deduction_recon_head_id   xxcok_deduction_recon_head.deduction_recon_head_id%TYPE   -- 控除消込ヘッダーID
     ,carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE         -- 支払伝票番号
     ,period_name               gl_interface.period_name%TYPE                             -- 会計期間
     ,accounting_date           gl_interface.accounting_date%TYPE                         -- 記帳日
     ,category_name             gl_interface.user_je_category_name%TYPE                   -- カテゴリ
     ,base_code                 gl_interface.segment2%TYPE                                -- 部門
     ,account                   fnd_lookup_values.attribute4%TYPE                         -- 勘定科目
     ,sub_account               fnd_lookup_values.attribute5%TYPE                         -- 補助科目
     ,corp_code                 gl_interface.segment6%TYPE                                -- 企業コード
     ,customer_code             gl_interface.segment5%TYPE                                -- 顧客コード
     ,entered_dr                gl_interface.entered_dr%TYPE                              -- 借方金額
     ,entered_cr                gl_interface.entered_cr%TYPE                              -- 貸方金額
     ,tax_code                  gl_interface.attribute1%TYPE                              -- 税コード
     ,reference10               gl_interface.reference10%TYPE                             -- 仕訳明細摘要
  );
--
  -- ワークテーブル型定義
  -- 控除消込データ
  TYPE g_recon_deductions_ttype     IS TABLE OF gr_recon_deductions_rec INDEX BY BINARY_INTEGER;
    gt_recon_deductions_tbl         g_recon_deductions_ttype;
--
  -- 控除消込負債データ
  TYPE g_recon_dedu_debt_ttype      IS TABLE OF gr_recon_dedu_debt_rec INDEX BY BINARY_INTEGER;
    gt_recon_dedu_debt_tbl        g_recon_dedu_debt_ttype;
--
  -- 控除消込ワークデータ
  TYPE g_recon_work_ttype           IS TABLE OF gr_recon_work_rec INDEX BY BINARY_INTEGER;
    gt_recon_work_tbl               g_recon_work_ttype;
--
  -- 控除消込取消データ
  TYPE g_recon_dedu_cancel_ttype    IS TABLE OF gr_recon_dedu_cancel_rec INDEX BY BINARY_INTEGER;
    gt_recon_dedu_cancel_tbl        g_recon_dedu_cancel_ttype;
--
  -- 販売控除更新用ワークデータ
  TYPE g_deductions_ttype           IS TABLE OF xxcok_sales_deduction%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_deduction_tbl                g_deductions_ttype;
--
-- 一般会計OIF
  TYPE g_gl_oif_ttype               IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_gl_interface_tbl             g_gl_oif_ttype;
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
  gn_org_id                           NUMBER;                                       -- 組織ID
  gn_set_bks_id                       NUMBER;                                       -- 会計帳簿ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- 会計帳簿名称
  gv_company_code                     VARCHAR2(30);                                 -- 会社コード
  gv_dept_fin_code                    VARCHAR2(30);                                 -- 部門コード（財務経理部）
  gv_account_code                     VARCHAR2(30);                                 -- 勘定科目コード_負債（引当等）
  gv_sub_account_code                 VARCHAR2(30);                                 -- 補助科目コード_負債（引当等）
  gv_customer_code                    VARCHAR2(30);                                 -- 顧客コード
  gv_comp_code                        VARCHAR2(30);                                 -- 企業コード
  gv_preliminary1_code                VARCHAR2(30);                                 -- 予備１
  gv_preliminary2_code                VARCHAR2(30);                                 -- 予備２
  gv_category_code2                   VARCHAR2(30);                                 -- 仕訳カテゴリ（控除消込）
  gv_accrued_account                  VARCHAR2(30);                                 -- 経過勘定科目
  gv_accrued_sub_account              VARCHAR2(30);                                 -- 経過勘定補助科目
--2021/05/18 add start
  gn_group_id                         NUMBER         DEFAULT NULL;                  -- グループID
--2021/05/18 add end
--
  -- 販売控除消込情報
  CURSOR recon_deductions_data_cur
  IS
    SELECT decode(source_category,cv_d_flag,deduction_recon_head_id,1)                                  deduction_recon_head_id  -- 控除消込ヘッダーID
          ,carry_payment_slip_num                                                                       carry_payment_slip_num   -- 支払伝票番号
          ,decode(source_category,cv_d_flag,interface_div,cv_syuyaku_flag)                              interface_div            -- 連携先
          ,decode(source_category,cv_d_flag,data_type,cv_syuyaku_flag)                                  data_type                -- 控除タイプ
          ,decode(source_category,cv_d_flag,gl_date,TO_DATE(cv_dummy_date,cv_date_format_1))            gl_date                  -- GL記帳日
          ,decode(source_category,cv_d_flag,period_name,cv_syuyaku_flag)                                period_name              -- 会計期間
          ,decode(source_category,cv_d_flag,recon_base_code,cv_syuyaku_flag)                            recon_base_code          -- 消込時計上拠点
          ,SUM(NVL(deduction_amount,0))                                                                 deduction_amount         -- 控除額
          ,decode(source_category,cv_d_flag,tax_code,cv_syuyaku_flag)                                   tax_code                 -- 税コード
          ,decode(source_category,cv_d_flag,tax_rate,1)                                                 tax_rate                 -- 税率
          ,SUM(NVL(deduction_tax_amount,0))                                                             deduction_tax_amount     -- 控除税額
          ,decode(source_category,cv_d_flag,source_category,cv_o_flag,source_category,cv_syuyaku_flag)  source_category          -- 作成元区分
          ,decode(source_category,cv_d_flag,meaning,cv_syuyaku_flag)                                    meaning                  -- データ種類名
          ,decode(source_category,cv_d_flag,account,cv_syuyaku_flag)                                    account                  -- 勘定科目
          ,decode(source_category,cv_d_flag,sub_account,cv_syuyaku_flag)                                sub_account              -- 補助科目
          ,decode(source_category,cv_d_flag,corp_code,cv_syuyaku_flag)                                  corp_code                -- 企業コード
          ,decode(source_category,cv_d_flag,customer_code,cv_syuyaku_flag)                              customer_code            -- 顧客コード
    FROM (
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- 控除消込ヘッダーID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- 支払伝票番号
                ,drh.interface_div                             interface_div            -- 連携先
                ,flv1.attribute2                               data_type                -- データ種類
                ,gp.end_date                                   gl_date                  -- GL記帳日
                ,gp.period_name                                period_name              -- 会計期間
                ,xsd.recon_base_code                           recon_base_code          -- 消込時計上拠点
                ,xsd.deduction_amount                          deduction_amount         -- 控除額
                ,flv2.attribute1                               tax_code                 -- 税コード
                ,xsd.tax_rate                                  tax_rate                 -- 税率
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- 控除税額
                ,xsd.source_category                           source_category          -- 作成元区分
                ,flv1.meaning                                  meaning                  -- データ種類名
                ,flv1.attribute4                               account                  -- 勘定科目
                ,flv1.attribute5                               sub_account              -- 補助科目
                ,NVL(flv3.attribute1,gv_comp_code)             corp_code                -- 企業コード
                ,NVL(DECODE(xca.torihiki_form,'2',xsd.customer_code_to,flv3.attribute4),gv_customer_code)
                                                               customer_code            -- 顧客コード
          FROM   xxcok_deduction_recon_head drh         -- 控除消込ヘッダー情報
                ,xxcok_sales_deduction      xsd         -- 販売控除情報
                ,fnd_lookup_values          flv1        -- クイックコード(データ種類)
                ,xxcmm_cust_accounts        xca         -- 顧客追加情報
                ,fnd_lookup_values          flv2        -- クイックコード(税コード変換)
                ,fnd_lookup_values          flv3        -- クイックコード(チェーンマスタ)
                ,gl_periods                 gp          -- 会計期間情報
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- 消込ステータス：承認済
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- 支払伝票番号
          AND    drh.gl_if_flag                            = cv_n_flag                      -- 消込GL連携フラグ：N
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- 控除データ種類
          AND    flv1.lookup_code                          = xsd.data_type                  -- データ種類
          AND    flv1.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv1.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    xsd.customer_code_to                      = xca.customer_code              -- 振替先顧客コード
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- 消費税コード変換マスタ
          AND    flv2.lookup_code                          = xsd.tax_code                   -- 税コード
          AND    flv2.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv2.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- 有効開始日
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- 有効終了日
          AND    flv3.lookup_type(+)                       = cv_lookup_chain_code           -- チェーンコード
          AND    flv3.lookup_code(+)                       = xca.intro_chain_code2          -- チェーンコード
          AND    flv3.enabled_flag(+)                      = cv_y_flag                      -- 使用可能：Y
          AND    flv3.language(+)                          = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    NVL(flv3.start_date_active,drh.gl_date)  <= drh.gl_date                    -- 有効開始日
          AND    NVL(flv3.end_date_active,drh.gl_date)    >= drh.gl_date                    -- 有効終了日
          AND    gp.period_set_name                        = cv_period_set_name             -- 会計カレンダ
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- 会計期間有効開始日
                                                         AND gp.end_date                    -- 会計期間有効終了日
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- 調整期間：N
          AND    xsd.customer_code_to                 IS NOT NULL
          UNION ALL
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- 控除消込ヘッダーID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- 支払伝票番号
                ,drh.interface_div                             interface_div            -- 連携先
                ,flv1.attribute2                               data_type                -- データ種類
                ,gp.end_date                                   gl_date                  -- GL記帳日
                ,gp.period_name                                period_name              -- 会計期間
                ,xsd.recon_base_code                           recon_base_code          -- 消込時計上拠点
                ,xsd.deduction_amount                          deduction_amount         -- 控除額
                ,flv2.attribute1                               tax_code                 -- 税コード
                ,xsd.tax_rate                                  tax_rate                 -- 税率
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- 控除税額
                ,xsd.source_category                           source_category          -- 作成元区分
                ,flv1.meaning                                  meaning                  -- データ種類名
                ,flv1.attribute4                               account                  -- 勘定科目
                ,flv1.attribute5                               sub_account              -- 補助科目
                ,NVL(flv3.attribute1,gv_comp_code)             corp_code                -- 企業コード
                ,NVL(flv3.attribute4,gv_customer_code)         customer_code            -- 顧客コード
          FROM   xxcok_deduction_recon_head drh         -- 控除消込ヘッダー情報
                ,xxcok_sales_deduction      xsd         -- 販売控除情報
                ,fnd_lookup_values          flv1        -- クイックコード(データ種類)
                ,fnd_lookup_values          flv2        -- クイックコード(税コード変換)
                ,fnd_lookup_values          flv3        -- クイックコード(チェーンマスタ)
                ,gl_periods                 gp          -- 会計期間情報
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- 消込ステータス：承認済
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- 支払伝票番号
          AND    drh.gl_if_flag                            = cv_n_flag                      -- 消込GL連携フラグ：N
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- 控除データ種類
          AND    flv1.lookup_code                          = xsd.data_type                  -- データ種類
          AND    flv1.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv1.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- 消費税コード変換マスタ
          AND    flv2.lookup_code                          = xsd.tax_code                   -- 税コード
          AND    flv2.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv2.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- 有効開始日
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- 有効終了日
          AND    flv3.lookup_type                          = cv_lookup_chain_code           -- チェーンコード
          AND    flv3.lookup_code                          = xsd.deduction_chain_code       -- チェーンコード
          AND    flv3.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv3.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    NVL(flv3.start_date_active,drh.gl_date)  <= drh.gl_date                    -- 有効開始日
          AND    NVL(flv3.end_date_active,drh.gl_date)    >= drh.gl_date                    -- 有効終了日
          AND    gp.period_set_name                        = cv_period_set_name             -- 会計カレンダ
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- 会計期間有効開始日
                                                         AND gp.end_date                    -- 会計期間有効終了日
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- 調整期間：N
          AND    xsd.deduction_chain_code IS NOT NULL
          UNION ALL
          SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- 控除消込ヘッダーID
                ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- 支払伝票番号
                ,drh.interface_div                             interface_div            -- 連携先
                ,flv1.attribute2                               data_type                -- データ種類
                ,gp.end_date                                   gl_date                  -- GL記帳日
                ,gp.period_name                                period_name              -- 会計期間
                ,xsd.recon_base_code                           recon_base_code          -- 消込時計上拠点
                ,xsd.deduction_amount                          deduction_amount         -- 控除額
                ,flv2.attribute1                               tax_code                 -- 税コード
                ,xsd.tax_rate                                  tax_rate                 -- 税率
                ,xsd.deduction_tax_amount                      deduction_tax_amount     -- 控除税額
                ,xsd.source_category                           source_category          -- 作成元区分
                ,flv1.meaning                                  meaning                  -- データ種類名
                ,flv1.attribute4                               account                  -- 勘定科目
                ,flv1.attribute5                               sub_account              -- 補助科目
                ,xsd.corp_code                                 corp_code                -- 企業コード
                ,gv_customer_code                              customer_code            -- 顧客コード
          FROM   xxcok_deduction_recon_head drh         -- 控除消込ヘッダー情報
                ,xxcok_sales_deduction      xsd         -- 販売控除情報
                ,fnd_lookup_values          flv1        -- クイックコード(データ種類)
                ,fnd_lookup_values          flv2        -- クイックコード(税コード変換)
                ,gl_periods                 gp          -- 会計期間情報
          WHERE  drh.recon_status                          = cv_recon_status_ad             -- 消込ステータス：承認済
          AND    drh.recon_slip_num                        = xsd.carry_payment_slip_num     -- 支払伝票番号
          AND    drh.gl_if_flag                            = cv_n_flag                      -- 消込GL連携フラグ：N
          AND    flv1.lookup_type                          = cv_lookup_dedu_code            -- 控除データ種類
          AND    flv1.lookup_code                          = xsd.data_type                  -- データ種類
          AND    flv1.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv1.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    flv2.lookup_type                          = cv_lookup_tax_conv_code        -- 消費税コード変換マスタ
          AND    flv2.lookup_code                          = xsd.tax_code                   -- 税コード
          AND    flv2.enabled_flag                         = cv_y_flag                      -- 使用可能：Y
          AND    flv2.language                             = USERENV('LANG')                -- 言語：USERENV('LANG')
          AND    NVL(flv2.start_date_active,drh.gl_date)  <= drh.gl_date                    -- 有効開始日
          AND    NVL(flv2.end_date_active,drh.gl_date)    >= drh.gl_date                    -- 有効終了日
          AND    gp.period_set_name                        = cv_period_set_name             -- 会計カレンダ
          AND    drh.gl_date                         BETWEEN gp.start_date                  -- 会計期間有効開始日
                                                         AND gp.end_date                    -- 会計期間有効終了日
          AND    gp.adjustment_period_flag                 = cv_n_flag                      -- 調整期間：N
          AND    xsd.corp_code            IS NOT NULL
          )
    GROUP BY
           decode(source_category,cv_d_flag,deduction_recon_head_id,1)                                   -- 控除消込ヘッダーID
          ,carry_payment_slip_num                                                                        -- 支払伝票番号
          ,decode(source_category,cv_d_flag,interface_div,cv_syuyaku_flag)                               -- 連携先
          ,decode(source_category,cv_d_flag,data_type,cv_syuyaku_flag)                                   -- 控除タイプ
          ,decode(source_category,cv_d_flag,gl_date,TO_DATE(cv_dummy_date,cv_date_format_1))             -- GL記帳日
          ,decode(source_category,cv_d_flag,period_name,cv_syuyaku_flag)                                 -- 会計期間
          ,decode(source_category,cv_d_flag,recon_base_code,cv_syuyaku_flag)                             -- 消込時計上拠点
          ,decode(source_category,cv_d_flag,tax_code,cv_syuyaku_flag)                                    -- 税コード
          ,decode(source_category,cv_d_flag,tax_rate,1)                                                  -- 税率
          ,decode(source_category,cv_d_flag,source_category,cv_o_flag,source_category,cv_syuyaku_flag)   -- 作成元区分
          ,decode(source_category,cv_d_flag,meaning,cv_syuyaku_flag)                                     -- データ種類名
          ,decode(source_category,cv_d_flag,account,cv_syuyaku_flag)                                     -- 勘定科目
          ,decode(source_category,cv_d_flag,sub_account,cv_syuyaku_flag)                                 -- 補助科目
          ,decode(source_category,cv_d_flag,corp_code,cv_syuyaku_flag)                                   -- 企業コード
          ,decode(source_category,cv_d_flag,customer_code,cv_syuyaku_flag)                               -- 顧客コード
    ORDER BY
           DECODE(source_category,cv_d_flag,1,2)                -- 作成元区分
          ,carry_payment_slip_num                               -- 支払伝票番号
          ,tax_code                                             -- 税コード
          ,data_type                                            -- データ種類
          ,recon_base_code                                      -- 消込時拠点コード
          ,account                                              -- 勘定科目
          ,sub_account                                          -- 補助科目
          ,corp_code                                            -- 企業コード
          ,customer_code                                        -- 顧客コード
    ;
--
  -- 差額調整情報
  CURSOR recon_dedu_debt_data_cur
  IS
    SELECT drh.deduction_recon_head_id                   deduction_recon_head_id  -- 控除消込ヘッダーID
          ,xsd.carry_payment_slip_num                    carry_payment_slip_num   -- 支払伝票番号
          ,gp.end_date                                   gl_date                  -- GL記帳日
          ,gp.period_name                                period_name              -- 会計期間
          ,flv1.meaning                                  meaning                  -- データ種類名
          ,flv1.attribute6                               debt_account             -- 負債勘定科目
          ,flv1.attribute7                               debt_sub_account         -- 負債補助科目
          ,drh.interface_div                             interface_div            -- 連携先
          ,SUM(xsd.deduction_amount)                     debt_deducation_amount   -- 負債額
    FROM   xxcok_deduction_recon_head drh         -- 控除消込ヘッダー情報
          ,xxcok_sales_deduction      xsd         -- 販売控除情報
          ,fnd_lookup_values          flv1        -- クイックコード(データ種類)
          ,gl_periods                 gp          -- 会計期間情報
    WHERE  drh.recon_status           = cv_recon_status_ad             -- 消込スタータス：承認済
    AND    drh.recon_slip_num         = xsd.carry_payment_slip_num     -- 支払伝票番号
    AND    drh.gl_if_flag             = cv_n_flag                      -- 消込GL連携フラグ：N
    AND    xsd.source_category        = cv_d_flag                            -- 作成元区分:D(差額調整)
    AND    flv1.lookup_type           = cv_lookup_dedu_code            -- 控除データ種類
    AND    flv1.lookup_code           = xsd.data_type                  -- データ種類
    AND    flv1.enabled_flag          = cv_y_flag                      -- 使用可能：Y
    AND    flv1.language              = USERENV('LANG')                -- 言語：USERENV('LANG')
    AND    gp.period_set_name         = cv_period_set_name             -- 会計カレンダ
    AND    drh.gl_date          BETWEEN gp.start_date                  -- 会計期間有効開始日
                                    AND gp.end_date                    -- 会計期間有効終了日
    AND    gp.adjustment_period_flag  = cv_n_flag                      -- 調整期間：N
    GROUP BY
           drh.deduction_recon_head_id                     -- 控除消込ヘッダーID
          ,xsd.carry_payment_slip_num                      -- 支払伝票番号
          ,gp.end_date                                     -- GL記帳日
          ,gp.period_name                                  -- 会計期間
          ,flv1.attribute6                                 -- 負債勘定科目
          ,flv1.attribute7                                 -- 負債補助科目
          ,flv1.meaning                                    -- データ種類名
          ,drh.interface_div                               -- 連携先

    ORDER BY
           xsd.carry_payment_slip_num                      -- 支払伝票番号
          ,flv1.attribute6                                 -- 負債勘定科目
          ,flv1.attribute7                                 -- 負債補助科目
          ,flv1.meaning                                    -- データ種類名
    ;
--
  -- 消込仕訳取消用カーソル
  CURSOR recon_dedu_cancel_data_cur
  IS
    SELECT drh.deduction_recon_head_id  deduction_recon_head_id  -- 控除消込ヘッダーID
          ,drh.recon_slip_num           recon_slip_num           -- 支払伝票番号
          ,LAST_DAY(drh.gl_date)        gl_date                  -- GL記帳日
          ,gjb.name                     b_name                   -- バッチ名
          ,gjb.description              b_description            -- バッチ摘要
          ,gjh.name                     h_name                   -- 仕訳名
          ,gjh.description              h_description            -- 仕訳摘要
          ,gjh.period_name              period_name              -- 会計期間
          ,gjs.user_je_source_name      user_je_source_name      -- 仕訳ソース名
          ,gjc.user_je_category_name    user_je_category_name    -- 仕訳カテゴリ名
          ,gcc.segment1                 segment1                 -- 会社コード
          ,gcc.segment2                 segment2                 -- 部門コード
          ,gcc.segment3                 segment3                 -- 勘定科目
          ,gcc.segment4                 segment4                 -- 補助科目
          ,gcc.segment5                 segment5                 -- 顧客コード
          ,gcc.segment6                 segment6                 -- 企業コード
          ,gcc.segment7                 segment7                 -- 予備１
          ,gcc.segment8                 segment8                 -- 予備２
          ,gjl.description              l_description            -- 仕訳明細摘要
          ,gjl.entered_dr               entered_dr               -- 借方金額
          ,gjl.entered_cr               entered_cr               -- 貸方金額
          ,gjl.attribute1               tax_code                 -- 税コード
          ,gjl.attribute3               recon_slip_num_1         -- 支払伝票番号
          ,gjl.context                  context                  -- コンテキスト
    FROM   xxcok_deduction_recon_head drh
          ,gl_je_batches              gjb
          ,gl_je_headers              gjh
          ,gl_je_lines                gjl
          ,gl_code_combinations       gcc
          ,gl_je_sources_tl           gjs
          ,gl_je_categories_tl        gjc
          ,gl_periods                 gp
    WHERE  drh.recon_status             = cv_recon_status_cd              -- 消込スタータス：取消済
    AND    drh.gl_if_flag              IN (cv_y_flag)                     -- 消込GL連携フラグ
    AND    gjh.set_of_books_id          = gn_set_bks_id                   -- 会計帳簿ID
    AND    gjl.code_combination_id      = gcc.code_combination_id         -- 勘定科目組合ID
    AND    gjh.je_header_id             = gjl.je_header_id                -- 仕訳ヘッダーID
    AND    drh.deduction_recon_head_id  = gjl.attribute8                  -- 控除消込ヘッダーID
    AND    gjh.je_source                = gjs.je_source_name              -- ソース名
    AND    gjs.language                 = USERENV('LANG')
    AND    gjh.je_category              = gjc.je_category_name
    AND    gjc.language                 = USERENV('LANG')
    AND    gjh.je_batch_id              = gjb.je_batch_id
    AND    gjs.user_je_source_name      = cv_source_name
    AND    gjc.user_je_category_name    = gv_category_code2
    AND    gp.period_set_name           = cv_period_set_name             -- 会計カレンダ
    AND    drh.gl_date            BETWEEN gp.start_date                  -- 会計期間有効開始日
                                      AND gp.end_date                    -- 会計期間有効終了日
    AND    gp.adjustment_period_flag    = cv_n_flag                      -- 調整期間：N
    AND    gp.period_name               = gjh.period_name                -- 会計期間
    FOR UPDATE OF drh.deduction_recon_head_id NOWAIT
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
    cv_pro_org_id_1             CONSTANT VARCHAR2(40) := 'ORG_ID';                           -- XXCOK:組織ID
    cv_pro_company_cd_1         CONSTANT VARCHAR2(40) := 'XXCOK1_AFF1_COMPANY_CODE';         -- XXCOK:会社コード
    cv_pro_dept_fin_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF2_DEPT_FIN';             -- XXCOK:部門コード_財務経理部
    cv_pro_customer_cd_1        CONSTANT VARCHAR2(40) := 'XXCOK1_AFF5_CUSTOMER_DUMMY';       -- XXCOK:顧客コード_ダミー値
    cv_pro_comp_cd_1            CONSTANT VARCHAR2(40) := 'XXCOK1_AFF6_COMPANY_DUMMY';        -- XXCOK:企業コード_ダミー値
    cv_pro_preliminary1_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF7_PRELIMINARY1_DUMMY';   -- XXCOK:予備１_ダミー値:0
    cv_pro_preliminary2_cd_1    CONSTANT VARCHAR2(40) := 'XXCOK1_AFF8_PRELIMINARY2_DUMMY';   -- XXCOK:予備２_ダミー値:0
    cv_pro_category_cd_1_2      CONSTANT VARCHAR2(40) := 'XXCOK1_GL_CATEGORY_CONDITION2';    -- XXCOK:仕訳カテゴリ（控除消込）
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
    -- ２．プロファイル取得：組織ID
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
--
    -- ===============================
    -- ３．プロファイル取得：会計帳簿ID
    -- ===============================
    gn_set_bks_id := FND_PROFILE.VALUE( cv_pro_bks_id_1 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gn_set_bks_id IS NULL ) THEN
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
    -- １１．プロファイル取得：仕訳カテゴリ（控除消込）
    --==================================
    gv_category_code2 := FND_PROFILE.VALUE( cv_pro_category_cd_1_2 );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gv_category_code2 IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg( iv_application => cv_xxcok_short_nm               -- アプリケーション短縮名
                                                 , iv_name        => cv_pro_category_cd_2            -- メッセージID
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
--2021/05/18 add start
    --==============================================================
    --１２．グループIDを取得
    --==============================================================
    SELECT gjs.attribute1         AS group_id -- グループID
    INTO   gn_group_id
    FROM   gl_je_sources             gjs      -- 仕訳ソースマスタ
    WHERE  gjs.user_je_source_name = cv_source_name;
--
    IF ( gn_group_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(cv_xxcok_short_nm
                                          , cv_group_id_msg
                                           );
      RAISE global_api_expt;
    END IF;

--2021/05/18 add end
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
--
    -- *** ローカル・カーソル (販売控除データ抽出)***
   -- 控除消込ロック情報
   CURSOR l_recon_dedu_lock_data_cur
   IS
      SELECT drh.deduction_recon_head_id
      FROM   xxcok_deduction_recon_head drh
            ,xxcok_sales_deduction      xsd
      WHERE  drh.recon_status   = cv_recon_status_ad
      AND    drh.gl_if_flag     = cv_n_flag
      AND    drh.recon_slip_num = xsd.carry_payment_slip_num
      FOR UPDATE OF drh.deduction_recon_head_id NOWAIT
      ;
    recon_dedu_lock_data_rec         l_recon_dedu_lock_data_cur%ROWTYPE;

--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- 販売控除消込情報カーソルオープン
    OPEN  recon_deductions_data_cur;
    -- データ取得
    FETCH recon_deductions_data_cur BULK COLLECT INTO gt_recon_deductions_tbl;
    -- カーソルクローズ
    CLOSE recon_deductions_data_cur;
--
    -- 差額調整情報カーソルオープン
    OPEN  recon_dedu_debt_data_cur;
    -- データ取得
    FETCH recon_dedu_debt_data_cur BULK COLLECT INTO gt_recon_dedu_debt_tbl;
    -- カーソルクローズ
    CLOSE recon_dedu_debt_data_cur;
--
    OPEN  l_recon_dedu_lock_data_cur;
    FETCH l_recon_dedu_lock_data_cur INTO recon_dedu_lock_data_rec;
    CLOSE l_recon_dedu_lock_data_cur;
--
  EXCEPTION
 --
    -- ロックエラー
    WHEN lock_expt THEN
      IF ( l_recon_dedu_lock_data_cur%ISOPEN ) THEN
        CLOSE l_recon_dedu_lock_data_cur;
      END IF;
--
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
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_deductions_data_cur%ISOPEN ) THEN
        CLOSE recon_deductions_data_cur;
      END IF;
      IF ( recon_dedu_debt_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_debt_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END get_data;
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
    lv_tax_dr                    CONSTANT VARCHAR2(10) := '消費税行';
    lv_tax_cr                    CONSTANT VARCHAR2(10) := '負債税行';
--
    -- *** ローカル変数 ***
    ln_deduction_amount_1        NUMBER DEFAULT 0;                               -- 売上控除:実際の売上控除額集計
    ln_deduction_tax_amount_1    NUMBER DEFAULT 0;                               -- 仮払消費税:実際の仮払消費税額集計
--
    ln_loop_index1               NUMBER DEFAULT 0;                               -- ワークテーブル販売控除インデックス
    ln_loop_index2               NUMBER DEFAULT 0;                               -- 更新用販売控除インデックス
    lv_account_code1             VARCHAR2(5);                                    -- 実際の税コード勘定科目用
    lv_sub_account_code1         VARCHAR2(5);                                    -- 実際の税コード補助科目用
    lv_debt_account_code1        VARCHAR2(5);                                    -- 実際の税コード負債勘定科目用
    lv_debt_sub_account_code1    VARCHAR2(5);                                    -- 実際の税コード負債補助科目用
--
    -- 集計キー
    lt_dedu_recon_head_id        xxcok_deduction_recon_head.deduction_recon_head_id%TYPE;     -- 集計キー：拠点コード(消込ヘッダーID)
    lt_recon_base_code           xxcok_sales_deduction.recon_base_code%TYPE;                  -- 集計キー：拠点コード(消込時計上拠点)
    lt_gl_date                   xxcok_deduction_recon_head.gl_date%TYPE;                     -- 集計キー：GL記帳日
    lt_gl_period                 gl_periods.period_name%TYPE;                                 -- 集計キー：会計期間
    lt_account                   fnd_lookup_values.attribute4%TYPE;                           -- 集計キー：勘定科目
    lt_sub_account               fnd_lookup_values.attribute5%TYPE;                           -- 集計キー：補助科目
    lt_corp_code                 fnd_lookup_values.attribute1%TYPE;                           -- 集計キー：企業コード
    lt_customer_code             fnd_lookup_values.attribute4%TYPE;                           -- 集計キー：顧客コード
    lt_tax_code                  xxcok_sales_deduction.tax_code%TYPE;                         -- 集計キー：税コード
    lt_tax_rate                  xxcok_sales_deduction.tax_rate%TYPE;                         -- 集計キー：税率
    lt_interface_div             xxcok_deduction_recon_head.interface_div%TYPE;               -- 集計キー：連携先
    lt_data_type                 fnd_lookup_values.attribute2%TYPE;                           -- 集計キー：データ種類
    lt_carry_payment_slip_num    xxcok_sales_deduction.carry_payment_slip_num%TYPE;           -- 集計キー：支払伝票番号
    lt_meaning                   fnd_lookup_values.meaning%TYPE;                              -- 集計キー：摘要
    lt_source_category           xxcok_sales_deduction.source_category%TYPE;                  -- 集計キー：作成元区分
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
    lt_dedu_recon_head_id      := gt_recon_deductions_tbl(1).deduction_recon_head_id;            -- 消込ヘッダーID
    lt_recon_base_code         := gt_recon_deductions_tbl(1).recon_base_code;                    -- 消込時計上拠点
    lt_gl_date                 := gt_recon_deductions_tbl(1).gl_date;                            -- GL記帳日
    lt_gl_period               := gt_recon_deductions_tbl(1).period_name;                        -- 会計期間
    lt_account                 := gt_recon_deductions_tbl(1).account;                            -- 勘定科目
    lt_sub_account             := gt_recon_deductions_tbl(1).sub_account;                        -- 補助科目
    lt_corp_code               := gt_recon_deductions_tbl(1).corp_code;                          -- 企業コード
    lt_customer_code           := gt_recon_deductions_tbl(1).customer_code;                      -- 顧客コード
    lt_tax_code                := gt_recon_deductions_tbl(1).tax_code;                           -- 税コード
    lt_tax_rate                := gt_recon_deductions_tbl(1).tax_rate;                           -- 税率
    lt_interface_div           := gt_recon_deductions_tbl(1).interface_div;                      -- 連携先
    lt_data_type               := gt_recon_deductions_tbl(1).data_type;                          -- 控除タイプ
    lt_carry_payment_slip_num  := gt_recon_deductions_tbl(1).carry_payment_slip_num;             -- 支払伝票番号
    lt_meaning                 := gt_recon_deductions_tbl(1).meaning;                            -- データ種類名
    lt_source_category         := gt_recon_deductions_tbl(1).source_category;                    -- 作成元区分
--
    -- 消込控除データループスタート
    <<main_data_loop>>
    FOR i IN 1..gt_recon_deductions_tbl.COUNT LOOP
--
      -- 処理件数取得
      IF gn_target_cnt = 0 THEN
        gn_target_cnt     := gn_target_cnt + 1;
      ELSE
        IF  lt_carry_payment_slip_num != gt_recon_deductions_tbl(i).carry_payment_slip_num THEN
          IF  gt_recon_deductions_tbl(i).source_category != cv_syuyaku_flag THEN
            gn_target_cnt   := gn_target_cnt + 1;
          END IF;
        END IF;
      END IF;
--
      IF gt_recon_deductions_tbl(i).source_category = cv_o_flag THEN
        IF ln_loop_index2 = 0 THEN
          ln_loop_index2  := ln_loop_index2 + 1;
          gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num := gt_recon_deductions_tbl(i).carry_payment_slip_num;
        ELSE
          IF (gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num != gt_recon_deductions_tbl(i).carry_payment_slip_num) THEN
            ln_loop_index2  := ln_loop_index2 + 1;
             gt_deduction_tbl( ln_loop_index2 ).carry_payment_slip_num := gt_recon_deductions_tbl(i).carry_payment_slip_num;
          END IF;
        END IF;
      END IF;
      -- 差額調整データ以外の場合
      IF (lt_source_category != cv_d_flag ) THEN
        NULL;
--
      -- 差額調整データ、残高調整データ(立替払い)の場合
      ELSE
        -- ==========================
        --  レコードブレイク判定
        -- ==========================
        -- 消込時拠点コード/勘定科目/補助科目/企業コード/顧客コード/税コード/控除タイプ/支払伝票番号のいずれかが前処理データ異なった場合
        IF ( lt_recon_base_code  <> gt_recon_deductions_tbl(i).recon_base_code )               -- 消込時拠点コード
          OR  ( lt_account                <> gt_recon_deductions_tbl(i).account )                 -- 勘定科目
          OR  ( lt_sub_account            <> gt_recon_deductions_tbl(i).sub_account )             -- 補助科目
          OR  ( lt_corp_code              <> gt_recon_deductions_tbl(i).corp_code )               -- 企業コード
          OR  ( lt_customer_code          <> gt_recon_deductions_tbl(i).customer_code )           -- 顧客コード
          OR  ( lt_tax_code               <> gt_recon_deductions_tbl(i).tax_code )                -- 税コード
          OR  ( lt_data_type              <> gt_recon_deductions_tbl(i).data_type )               -- 控除タイプ
          OR  ( lt_carry_payment_slip_num <> gt_recon_deductions_tbl(i).carry_payment_slip_num )  -- 支払伝票番号
          OR  ( lt_source_category        <> gt_recon_deductions_tbl(i).source_category ) THEN    -- 作成元区分
--
          ln_loop_index1 := ln_loop_index1 + 1;
--
          -- 控除消込の差額調整額データをワークテーブルに退避
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := lt_recon_base_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lt_account;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lt_sub_account;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := lt_corp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := lt_customer_code;
          IF ( ln_deduction_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr           := ln_deduction_amount_1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr           := NULL;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr           := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr           := NVL(ln_deduction_amount_1,0) * -1;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lt_recon_base_code || cv_underbar || lt_meaning
                                                                                           || cv_underbar || lt_tax_code;
--
          -- 控除消込の差額調整額集約値初期化
          ln_deduction_amount_1 := 0;
--
        END IF;
--
        -- ==========================
        --  税コードブレイク判定
        -- ==========================
        -- 税コード/支払伝票番号のいずれかが前処理データと異なる場合
        IF ( lt_tax_code                   <> gt_recon_deductions_tbl(i).tax_code )                -- 税コード
          OR  ( lt_carry_payment_slip_num  <> gt_recon_deductions_tbl(i).carry_payment_slip_num )  -- 支払伝票番号
          OR  ( lt_source_category         <> gt_recon_deductions_tbl(i).source_category ) THEN    -- 作成元区分
--
          -- 税勘定科目を取得(実際の税勘定科目、税補助科目)
          BEGIN
            SELECT gcc.segment3            -- 税額_勘定科目
                  ,gcc.segment4            -- 税額_補助科目
                  ,tax.attribute5          -- 負債税額_勘定科目
                  ,tax.attribute6          -- 負債税額_補助科目
            INTO   lv_account_code1
                  ,lv_sub_account_code1
                  ,lv_debt_account_code1
                  ,lv_debt_sub_account_code1
            FROM   apps.ap_tax_codes_all     tax  -- AP税コードマスタ
                  ,apps.gl_code_combinations gcc  -- 勘定組合情報
            WHERE  tax.set_of_books_id     = gn_set_bks_id                  -- SET_OF_BOOKS_ID
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
                                                    , cv_tax_account_error_msg
                                                     );
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
          END;
--
          ln_loop_index1 := ln_loop_index1 + 1;
--
          -- 控除消込の差額調整仮払消費税をワークテーブルに退避
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lv_account_code1;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_sub_account_code1;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
          IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_tax_amount_1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_tax_amount_1,0) * -1;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_dr || cv_underbar || lt_tax_code;
--
          ln_loop_index1 := ln_loop_index1 + 1;

          -- 差額調整分の負債（引当等）_消費税をワークテーブルに退避
          gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
          gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
          gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
          gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
          gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
          gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
          gt_recon_work_tbl(ln_loop_index1).account                  := lv_debt_account_code1;
          gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_debt_sub_account_code1;
          gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
          gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
          IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := ln_deduction_tax_amount_1;
          ELSE
            gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(ln_deduction_tax_amount_1,0) * -1;
            gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
          END IF;
          gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
          gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_cr || cv_underbar || lt_tax_code;
--
          -- 控除消込の差額調整仮払消費税集約値初期化
          ln_deduction_tax_amount_1 := 0;
--
        END IF;
--
        -- 差額調整データの場合、控除消込の差額調整額、控除消込の差額調整仮払消費税を加算
        ln_deduction_amount_1      := ln_deduction_amount_1     + gt_recon_deductions_tbl(i).deduction_amount;
        ln_deduction_tax_amount_1  := ln_deduction_tax_amount_1 + gt_recon_deductions_tbl(i).deduction_tax_amount;
--
      END IF;
--
      -- ブレイク用集約キーセット
      lt_dedu_recon_head_id      := gt_recon_deductions_tbl(i).deduction_recon_head_id; -- 控除消込ヘッダーID
      lt_recon_base_code         := gt_recon_deductions_tbl(i).recon_base_code;         -- 消込時計上拠点
      lt_gl_date                 := gt_recon_deductions_tbl(i).gl_date;                 -- GL記帳日
      lt_gl_period               := gt_recon_deductions_tbl(i).period_name;             -- 会計期間
      lt_account                 := gt_recon_deductions_tbl(i).account;                 -- 勘定科目
      lt_sub_account             := gt_recon_deductions_tbl(i).sub_account;             -- 補助科目
      lt_corp_code               := gt_recon_deductions_tbl(i).corp_code;               -- 企業コード
      lt_customer_code           := gt_recon_deductions_tbl(i).customer_code;           -- 顧客コード
      lt_tax_code                := gt_recon_deductions_tbl(i).tax_code;                -- 税コード
      lt_tax_rate                := gt_recon_deductions_tbl(i).tax_rate;                -- 税率
      lt_data_type               := gt_recon_deductions_tbl(i).data_type;               -- 控除タイプ
      lt_source_category         := gt_recon_deductions_tbl(i).source_category;         -- 作成元区分
      lt_meaning                 := gt_recon_deductions_tbl(i).meaning;                 -- データ種類名
      lt_carry_payment_slip_num  := gt_recon_deductions_tbl(i).carry_payment_slip_num;  -- 支払伝票番号
      lt_interface_div           := gt_recon_deductions_tbl(i).interface_div;           -- 連携先
--
    END LOOP main_data_loop;
--
    IF (lt_source_category = cv_d_flag ) THEN
      -- 最終行出力
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- 控除消込の差額調整額データをワークテーブルに退避
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := lt_recon_base_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lt_account;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lt_sub_account;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := lt_corp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := lt_customer_code;
      IF ( ln_deduction_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_amount_1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_amount_1,0) * -1;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lt_recon_base_code || cv_underbar || lt_meaning
                                                                                       || cv_underbar || lt_tax_code;
--
      -- 税勘定科目を取得(実際の税勘定科目、税補助科目)
      BEGIN
        SELECT gcc.segment3            -- 税額_勘定科目
              ,gcc.segment4            -- 税額_補助科目
              ,tax.attribute5          -- 負債税額_勘定科目
              ,tax.attribute6          -- 負債税額_補助科目
        INTO   lv_account_code1
              ,lv_sub_account_code1
              ,lv_debt_account_code1
              ,lv_debt_sub_account_code1
        FROM   apps.ap_tax_codes_all     tax  -- AP税コードマスタ
              ,apps.gl_code_combinations gcc  -- 勘定組合情報
        WHERE  tax.set_of_books_id     = gn_set_bks_id                  -- SET_OF_BOOKS_ID
        and    tax.org_id              = gn_org_id                      -- ORG_ID
        and    gcc.code_combination_id = tax.tax_code_combination_id    -- 税CCID
        and    tax.name                = lt_tax_code                    -- 税コード
        and    tax.enabled_flag        = cv_y_flag                      -- 有効
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
        -- 勘定科目が取得出来ない場合
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                                , cv_tax_account_error_msg
                                                 );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- 控除消込の差額調整仮払消費税をワークテーブルに退避
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lv_account_code1;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_sub_account_code1;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := ln_deduction_tax_amount_1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NVL(ln_deduction_tax_amount_1,0) * -1;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := lt_tax_code;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_dr || cv_underbar || lt_tax_code;
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- 差額調整分の負債（引当等）_消費税をワークテーブルに退避
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := lt_dedu_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := lt_carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := lt_gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := lt_gl_period;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := lv_debt_account_code1;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := lv_debt_sub_account_code1;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( ln_deduction_tax_amount_1 >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := ln_deduction_tax_amount_1;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(ln_deduction_tax_amount_1,0) * -1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
      gt_recon_work_tbl(ln_loop_index1).reference10              := lv_tax_cr || cv_underbar || lt_tax_code;
    END IF;
--
    -- 差額調整情報のループスタート
    <<recon_dedu_debt_loop>>
    FOR j IN 1..gt_recon_dedu_debt_tbl.COUNT LOOP
--
      ln_loop_index1 := ln_loop_index1 + 1;
--
      -- 差額調整分の負債(引当等)をワークテーブルに退避
      gt_recon_work_tbl(ln_loop_index1).deduction_recon_head_id  := gt_recon_dedu_debt_tbl(j).deduction_recon_head_id;
      gt_recon_work_tbl(ln_loop_index1).carry_payment_slip_num   := gt_recon_dedu_debt_tbl(j).carry_payment_slip_num;
      gt_recon_work_tbl(ln_loop_index1).accounting_date          := gt_recon_dedu_debt_tbl(j).gl_date;
      gt_recon_work_tbl(ln_loop_index1).period_name              := gt_recon_dedu_debt_tbl(j).period_name;
      gt_recon_work_tbl(ln_loop_index1).category_name            := gv_category_code2;
      gt_recon_work_tbl(ln_loop_index1).base_code                := gv_dept_fin_code;
      gt_recon_work_tbl(ln_loop_index1).account                  := gt_recon_dedu_debt_tbl(j).debt_account;
      gt_recon_work_tbl(ln_loop_index1).sub_account              := gt_recon_dedu_debt_tbl(j).debt_sub_account;
      gt_recon_work_tbl(ln_loop_index1).corp_code                := gv_comp_code;
      gt_recon_work_tbl(ln_loop_index1).customer_code            := gv_customer_code;
      IF ( gt_recon_dedu_debt_tbl(j).debt_deduction_amount >= 0 ) THEN
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NULL;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := gt_recon_dedu_debt_tbl(j).debt_deduction_amount;
      ELSE
        gt_recon_work_tbl(ln_loop_index1).entered_dr             := NVL(gt_recon_dedu_debt_tbl(j).debt_deduction_amount,0) * -1;
        gt_recon_work_tbl(ln_loop_index1).entered_cr             := NULL;
      END IF;
      gt_recon_work_tbl(ln_loop_index1).tax_code                 := NULL;
      gt_recon_work_tbl(ln_loop_index1).reference10              := gt_recon_dedu_debt_tbl(j).meaning;
--
    END LOOP recon_dedu_debt_loop;
--
  EXCEPTION
    WHEN edit_gl_expt THEN
      lv_errbuf  := lv_errmsg;
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
   * Procedure Name   : edit_gl_data
   * Description      : A-4.一般会計OIFデータ作成
   ***********************************************************************************/
  PROCEDURE edit_gl_data( ov_errbuf          OUT VARCHAR2         -- エラー・メッセージ           --# 固定 #
                        , ov_retcode         OUT VARCHAR2         -- リターン・コード             --# 固定 #
                        , ov_errmsg          OUT VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
                         )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'edit_gl_data';      -- プログラム名
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCFO';             -- 共通領域短縮アプリ名
    cv_ccid_chk_msg    CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10052';  -- 勘定科目ID（CCID）取得エラーメッセージ
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
--
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
    ln_ccid_check            NUMBER;
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
    ov_retcode := cv_status_normal;
--
--#####################################  固定部 END  #####################################
--
    --==============================================================
    --  一般会計OIFデータ作成
    --==============================================================
--
    <<insert_data_loop>>
    FOR i IN 1..gt_recon_work_tbl.COUNT LOOP
--
      ln_ccid_check := NULL;
      --==============================================================
      -- CCID存在チェック
      --==============================================================
      ln_ccid_check := xxcok_common_pkg.get_code_combination_id_f(
                                 id_proc_date => gd_process_date                       -- 処理日
                               , iv_segment1  => gv_company_code                       -- 会社コード
                               , iv_segment2  => gt_recon_work_tbl(i).base_code        -- 部門コード
                               , iv_segment3  => gt_recon_work_tbl(i).account          -- 勘定科目コード
                               , iv_segment4  => gt_recon_work_tbl(i).sub_account      -- 補助科目コード
                               , iv_segment5  => gt_recon_work_tbl(i).customer_code    -- 顧客コード
                               , iv_segment6  => gt_recon_work_tbl(i).corp_code        -- 企業コード
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
                        , iv_token_value3 => gt_recon_work_tbl(i).base_code        -- 部門コード
                        , iv_token_name4  => cv_tkn_acc_code
                        , iv_token_value4 => gt_recon_work_tbl(i).account          -- 勘定科目コード
                        , iv_token_name5  => cv_tkn_ass_code
                        , iv_token_value5 => gt_recon_work_tbl(i).sub_account      -- 補助科目コード
                        , iv_token_name6  => cv_tkn_cust_code
                        , iv_token_value6 => gt_recon_work_tbl(i).customer_code    -- 顧客コード
                        , iv_token_name7  => cv_tkn_ent_code
                        , iv_token_value7 => gt_recon_work_tbl(i).corp_code        -- 企業コード
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
      gt_gl_interface_tbl(i).status                := cv_status;                                                     -- ステータス
      gt_gl_interface_tbl(i).set_of_books_id       := gn_set_bks_id;                                                 -- 会計帳簿ID
      gt_gl_interface_tbl(i).accounting_date       := gt_recon_work_tbl(i).accounting_date;                          -- 記帳日
      gt_gl_interface_tbl(i).currency_code         := cv_currency_code;                                              -- 通貨コード
      gt_gl_interface_tbl(i).actual_flag           := cv_actual_flag;                                                -- 残高タイプ
      gt_gl_interface_tbl(i).user_je_category_name := gt_recon_work_tbl(i).category_name;                            -- 仕訳カテゴリ名
      gt_gl_interface_tbl(i).user_je_source_name   := cv_source_name;                                                -- 仕訳ソース名
      gt_gl_interface_tbl(i).segment1              := gv_company_code;                                               -- (会社)
      gt_gl_interface_tbl(i).segment2              := gt_recon_work_tbl(i).base_code;                                -- (部門)
      gt_gl_interface_tbl(i).segment3              := gt_recon_work_tbl(i).account;                                  -- (勘定科目)
      gt_gl_interface_tbl(i).segment4              := gt_recon_work_tbl(i).sub_account;                              -- (補助科目)
      gt_gl_interface_tbl(i).segment5              := gt_recon_work_tbl(i).customer_code;                            -- (顧客コード)
      gt_gl_interface_tbl(i).segment6              := gt_recon_work_tbl(i).corp_code;                                -- (企業コード)
      gt_gl_interface_tbl(i).segment7              := gv_preliminary1_code;                                          -- (予備１)
      gt_gl_interface_tbl(i).segment8              := gv_preliminary2_code;                                          -- (予備２)
      gt_gl_interface_tbl(i).entered_dr            := gt_recon_work_tbl(i).entered_dr;                               -- 借方金額
      gt_gl_interface_tbl(i).entered_cr            := gt_recon_work_tbl(i).entered_cr;                               -- 貸方金額
      gt_gl_interface_tbl(i).reference1            := cv_source_name                      || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name    || cv_underbar ||
                                                      TO_CHAR(gd_process_date);                                      -- リファレンス1（バッチ名）
      gt_gl_interface_tbl(i).reference2            := cv_source_name                      || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name    || cv_underbar ||
                                                      TO_CHAR(gd_process_date);                                      -- リファレンス2（バッチ摘要）
      gt_gl_interface_tbl(i).reference4            := gt_recon_work_tbl(i).carry_payment_slip_num || cv_underbar ||
                                                      gt_recon_work_tbl(i).category_name          || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name;                              -- リファレンス4（仕訳名）
      gt_gl_interface_tbl(i).reference5            := gt_recon_work_tbl(i).carry_payment_slip_num || cv_underbar ||
                                                      gt_recon_work_tbl(i).category_name          || cv_underbar ||
                                                      gt_recon_work_tbl(i).period_name;                              -- リファレンス5（仕訳名摘要）
      gt_gl_interface_tbl(i).reference10           := gt_recon_work_tbl(i).reference10;                              -- リファレンス10（仕訳明細摘要）
      gt_gl_interface_tbl(i).period_name           := gt_recon_work_tbl(i).period_name;                              -- 会計期間
--2021/05/18 add start
      gt_gl_interface_tbl(i).group_id              := gn_group_id;                                                   -- グループID
--2021/05/18 add end
      gt_gl_interface_tbl(i).attribute1            := gt_recon_work_tbl(i).tax_code;                                 -- 属性1（消費税コード）
      gt_gl_interface_tbl(i).attribute3            := gt_recon_work_tbl(i).carry_payment_slip_num;                   -- 属性3（支払伝票番号）
      gt_gl_interface_tbl(i).attribute8            := gt_recon_work_tbl(i).deduction_recon_head_id;                  -- 属性8（控除消込ヘッダーID）
      gt_gl_interface_tbl(i).context               := gv_set_bks_nm;                                                 -- コンテキスト
      gt_gl_interface_tbl(i).created_by            := cn_created_by;                                                 -- 新規作成者
      gt_gl_interface_tbl(i).date_created          := cd_creation_date;                                              -- 新規作成日
      gt_gl_interface_tbl(i).request_id            := cn_request_id;                                                 -- 要求ID
--
   END LOOP insert_data_loop;
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
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : A-5.GL一般会計OIFデータインサート処理
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
    -- 一般会計OIFに作成した件数を取得
    SELECT COUNT(DISTINCT gi.reference4)
    INTO   gn_normal_cnt
    FROM   gl_interface   gi
    WHERE  gi.request_id = cn_request_id
    ;
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
                      , iv_token_name2       => cv_tkn_key_data
                      , iv_token_value2      => NULL
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
   * Procedure Name   : up_ded_recon_data
   * Description      : A-6.控除消込ヘッダー情報更新処理
   ***********************************************************************************/
  PROCEDURE up_ded_recon_data( ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
                              ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
                              ,ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(25) := 'up_ded_recon_data'; -- プログラム名
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
    ln_loop_cnt2         NUMBER DEFAULT 0;     -- ループカウント用変数
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
    -- 控除消込ヘッダー情報更新処理
    --==============================================================
--
    -- 処理対象データのGL連携フラグを更新
--
    -- 正常データ更新
    BEGIN
      UPDATE xxcok_deduction_recon_head     xdrh                                                                -- 控除消込ヘッダー情報
      SET    xdrh.gl_if_flag               = cv_y_flag                                                          -- 消込GL連携フラグ
            ,xdrh.last_updated_by          = cn_last_updated_by                                                 -- 最終更新者
            ,xdrh.last_update_date         = cd_last_update_date                                                -- 最終更新日
            ,xdrh.last_update_login        = cn_last_update_login                                               -- 最終更新ログイン
            ,xdrh.request_id               = cn_request_id                                                      -- 要求ID
            ,xdrh.program_application_id   = cn_program_application_id                                          -- コンカレント・プログラム・アプリID
            ,xdrh.program_id               = cn_program_id                                                      -- コンカレント・プログラムID
            ,xdrh.program_update_date      = cd_program_update_date                                             -- プログラム更新日
      WHERE  xdrh.recon_status             = cv_recon_status_ad                                                 -- 消込ステータス:AD
      AND    xdrh.gl_if_flag               = cv_n_flag                                                          -- 消込GL連携フラグ:N
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_data_expt;
    END;
--
    -- 販売控除情報の繰越時支払伝票番号の更新
    BEGIN
      FORALL ln_loop_cnt2 IN 1..gt_deduction_tbl.COUNT
        UPDATE xxcok_sales_deduction xsd                         -- 販売控除情報
        SET    xsd.carry_payment_slip_num  = NULL                                                      -- 繰越時支払伝票番号
              ,xsd.last_updated_by         = cn_last_updated_by                                        -- 最終更新者
              ,xsd.last_update_date        = cd_last_update_date                                       -- 最終更新日
              ,xsd.last_update_login       = cn_last_update_login                                      -- 最終更新ログイン
              ,xsd.request_id              = cn_request_id                                             -- 要求ID
              ,xsd.program_application_id  = cn_program_application_id                                 -- コンカレント・プログラム・アプリID
              ,xsd.program_id              = cn_program_id                                             -- コンカレント・プログラムID
              ,xsd.program_update_date     = cd_program_update_date                                    -- プログラム更新日
        WHERE  xsd.carry_payment_slip_num  = gt_deduction_tbl(ln_loop_cnt2).carry_payment_slip_num     -- 繰越時支払伝票番号
        AND    xsd.source_category         = cv_o_flag                                                 -- 作成元区分：繰越調整
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_data_expt;
    END;
--
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
                        , iv_token_value2 => NULL
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
  END up_ded_recon_data;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_cancel_data
   * Description      : A-7.GL仕訳データ抽出（取消）
   ***********************************************************************************/
  PROCEDURE get_gl_cancel_data( ov_errbuf     OUT VARCHAR2            -- エラー・メッセージ           --# 固定 #
                              , ov_retcode    OUT VARCHAR2            -- リターン・コード             --# 固定 #
                              , ov_errmsg     OUT VARCHAR2 )          -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_gl_cancel_data'; -- プログラム名
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

--
  BEGIN
--
--############################  固定ステータス初期化部 START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  固定ステータス初期化部 END  #############################
--
    -- カーソルオープン
    OPEN  recon_dedu_cancel_data_cur;
    -- データ取得
    FETCH recon_dedu_cancel_data_cur BULK COLLECT INTO gt_recon_dedu_cancel_tbl;
    -- カーソルクローズ
    CLOSE recon_dedu_cancel_data_cur;
--
--
  EXCEPTION
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
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( recon_dedu_cancel_data_cur%ISOPEN ) THEN
        CLOSE recon_dedu_cancel_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END get_gl_cancel_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_cancel_data
   * Description      : A-8.GL一般会計OIFデータインサート処理（取消）
   ***********************************************************************************/
  PROCEDURE insert_gl_cancel_data( ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
                                 , ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
                                 , ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_cancel_data'; -- プログラム名
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
    lv_cancel  CONSTANT VARCHAR2(100) := '取消_'; -- 取消
--
    -- *** ローカル変数 ***
    lv_tbl_nm           VARCHAR2(255);                -- テーブル名
    lv_closing_status   VARCHAR2(1) DEFAULT NULL;     -- クロージングステータス
    lv_period_name      VARCHAR2(8) DEFAULT NULL;     -- 会計期間
    ld_gl_date          DATE;                         -- 会計日付
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
    <<recon_dedu_loop>>
    FOR i IN 1..gt_recon_dedu_cancel_tbl.COUNT LOOP
--
      -- 会計期間よりクロージングステータスを取得
      SELECT gps.closing_status
      INTO   lv_closing_status
      FROM   gl_period_statuses  gps
      WHERE  gps.set_of_books_id        = gn_set_bks_id
      AND    gps.period_name            = gt_recon_dedu_cancel_tbl(i).period_name
      AND    gps.application_id         = 101
      AND    gps.adjustment_period_flag = cv_n_flag
      ;
--
      -- クロージングステータスが「C:クローズ」の場合
      IF (lv_closing_status = cv_c_flag) THEN
--
        -- 直近のオープンしている会計期間、終了日を取得
        SELECT MIN(gps.period_name)
              ,MIN(gps.end_date)
        INTO   lv_period_name
              ,ld_gl_date
        FROM   gl_period_statuses  gps
        WHERE  gps.set_of_books_id        = gn_set_bks_id
        AND    gps.end_date               > gt_recon_dedu_cancel_tbl(i).gl_date
        AND    gps.application_id         = 101
        AND    gps.adjustment_period_flag = cv_n_flag
        AND    gps.closing_status         = cv_o_flag
        ;
      ELSE
        lv_period_name  := gt_recon_dedu_cancel_tbl(i).period_name;
        ld_gl_date      := gt_recon_dedu_cancel_tbl(i).gl_date;
      END IF;
--
      BEGIN
        INSERT INTO gl_interface(
          status                             -- STATUS
         ,set_of_books_id                    -- SET_OF_BOOKS_ID
         ,accounting_date                    -- ACCOUNTING_DATE
         ,currency_code                      -- CURRENCY_CODE
         ,date_created                       -- DATE_CREATED
         ,created_by                         -- CREATED_BY
         ,actual_flag                        -- ACTUAL_FLAG
         ,user_je_category_name              -- USER_JE_CATEGORY_NAME
         ,user_je_source_name                -- USER_JE_SOURCE_NAME
         ,currency_conversion_date           -- CURRENCY_CONVERSION_DATE
         ,encumbrance_type_id                -- ENCUMBRANCE_TYPE_ID
         ,budget_version_id                  -- BUDGET_VERSION_ID
         ,user_currency_conversion_type      -- USER_CURRENCY_CONVERSION_TYPE
         ,currency_conversion_rate           -- CURRENCY_CONVERSION_RATE
         ,average_journal_flag               -- AVERAGE_JOURNAL_FLAG
         ,originating_bal_seg_value          -- ORIGINATING_BAL_SEG_VALUE
         ,segment1                           -- SEGMENT1
         ,segment2                           -- SEGMENT2
         ,segment3                           -- SEGMENT3
         ,segment4                           -- SEGMENT4
         ,segment5                           -- SEGMENT5
         ,segment6                           -- SEGMENT6
         ,segment7                           -- SEGMENT7
         ,segment8                           -- SEGMENT8
         ,segment9                           -- SEGMENT9
         ,segment10                          -- SEGMENT10
         ,segment11                          -- SEGMENT11
         ,segment12                          -- SEGMENT12
         ,segment13                          -- SEGMENT13
         ,segment14                          -- SEGMENT14
         ,segment15                          -- SEGMENT15
         ,segment16                          -- SEGMENT16
         ,segment17                          -- SEGMENT17
         ,segment18                          -- SEGMENT18
         ,segment19                          -- SEGMENT19
         ,segment20                          -- SEGMENT20
         ,segment21                          -- SEGMENT21
         ,segment22                          -- SEGMENT22
         ,segment23                          -- SEGMENT23
         ,segment24                          -- SEGMENT24
         ,segment25                          -- SEGMENT25
         ,segment26                          -- SEGMENT26
         ,segment27                          -- SEGMENT27
         ,segment28                          -- SEGMENT28
         ,segment29                          -- SEGMENT29
         ,segment30                          -- SEGMENT30
         ,entered_dr                         -- ENTERED_DR
         ,entered_cr                         -- ENTERED_CR
         ,accounted_dr                       -- ACCOUNTED_DR
         ,accounted_cr                       -- ACCOUNTED_CR
         ,transaction_date                   -- TRANSACTION_DATE
         ,reference1                         -- REFERENCE1
         ,reference2                         -- REFERENCE2
         ,reference3                         -- REFERENCE3
         ,reference4                         -- REFERENCE4
         ,reference5                         -- REFERENCE5
         ,reference6                         -- REFERENCE6
         ,reference7                         -- REFERENCE7
         ,reference8                         -- REFERENCE8
         ,reference9                         -- REFERENCE9
         ,reference10                        -- REFERENCE10
         ,reference11                        -- REFERENCE11
         ,reference12                        -- REFERENCE12
         ,reference13                        -- REFERENCE13
         ,reference14                        -- REFERENCE14
         ,reference15                        -- REFERENCE15
         ,reference16                        -- REFERENCE16
         ,reference17                        -- REFERENCE17
         ,reference18                        -- REFERENCE18
         ,reference19                        -- REFERENCE19
         ,reference20                        -- REFERENCE20
         ,reference21                        -- REFERENCE21
         ,reference22                        -- REFERENCE22
         ,reference23                        -- REFERENCE23
         ,reference24                        -- REFERENCE24
         ,reference25                        -- REFERENCE25
         ,reference26                        -- REFERENCE26
         ,reference27                        -- REFERENCE27
         ,reference28                        -- REFERENCE28
         ,reference29                        -- REFERENCE29
         ,reference30                        -- REFERENCE30
         ,je_batch_id                        -- JE_BATCH_ID
         ,period_name                        -- PERIOD_NAME
         ,je_header_id                       -- JE_HEADER_ID
         ,je_line_num                        -- JE_LINE_NUM
         ,chart_of_accounts_id               -- CHART_OF_ACCOUNTS_ID
         ,functional_currency_code           -- FUNCTIONAL_CURRENCY_CODE
         ,code_combination_id                -- CODE_COMBINATION_ID
         ,date_created_in_gl                 -- DATE_CREATED_IN_GL
         ,warning_code                       -- WARNING_CODE
         ,status_description                 -- STATUS_DESCRIPTION
         ,stat_amount                        -- STAT_AMOUNT
         ,group_id                           -- GROUP_ID
         ,request_id                         -- REQUEST_ID
         ,subledger_doc_sequence_id          -- SUBLEDGER_DOC_SEQUENCE_ID
         ,subledger_doc_sequence_value       -- SUBLEDGER_DOC_SEQUENCE_VALUE
         ,attribute1                         -- ATTRIBUTE1
         ,attribute2                         -- ATTRIBUTE2
         ,gl_sl_link_id                      -- GL_SL_LINK_ID
         ,gl_sl_link_table                   -- GL_SL_LINK_TABLE
         ,attribute3                         -- ATTRIBUTE3
         ,attribute4                         -- ATTRIBUTE4
         ,attribute5                         -- ATTRIBUTE5
         ,attribute6                         -- ATTRIBUTE6
         ,attribute7                         -- ATTRIBUTE7
         ,attribute8                         -- ATTRIBUTE8
         ,attribute9                         -- ATTRIBUTE9
         ,attribute10                        -- ATTRIBUTE10
         ,attribute11                        -- ATTRIBUTE11
         ,attribute12                        -- ATTRIBUTE12
         ,attribute13                        -- ATTRIBUTE13
         ,attribute14                        -- ATTRIBUTE14
         ,attribute15                        -- ATTRIBUTE15
         ,attribute16                        -- ATTRIBUTE16
         ,attribute17                        -- ATTRIBUTE17
         ,attribute18                        -- ATTRIBUTE18
         ,attribute19                        -- ATTRIBUTE19
         ,attribute20                        -- ATTRIBUTE20
         ,context                            -- CONTEXT
         ,context2                           -- CONTEXT2
         ,invoice_date                       -- INVOICE_DATE
         ,tax_code                           -- TAX_CODE
         ,invoice_identifier                 -- INVOICE_IDENTIFIER
         ,invoice_amount                     -- INVOICE_AMOUNT
         ,context3                           -- CONTEXT3
         ,ussgl_transaction_code             -- USSGL_TRANSACTION_CODE
         ,descr_flex_error_message           -- DESCR_FLEX_ERROR_MESSAGE
         ,jgzz_recon_ref                     -- JGZZ_RECON_REF
         ,reference_date                     -- REFERENCE_DATE
        )VALUES(
          cv_status                                               -- STATUS
         ,gn_set_bks_id                                           -- SET_OF_BOOKS_ID
         ,ld_gl_date                                              -- ACCOUNTING_DATE
         ,cv_currency_code                                        -- CURRENCY_CODE
         ,cd_creation_date                                        -- DATE_CREATED
         ,cn_created_by                                           -- CREATED_BY
         ,cv_actual_flag                                          -- ACTUAL_FLAG
         ,gt_recon_dedu_cancel_tbl(i).user_je_category_name       -- USER_JE_CATEGORY_NAME
         ,gt_recon_dedu_cancel_tbl(i).user_je_source_name         -- USER_JE_SOURCE_NAME
         ,NULL                                                    -- CURRENCY_CONVERSION_DATE
         ,NULL                                                    -- ENCUMBRANCE_TYPE_ID
         ,NULL                                                    -- BUDGET_VERSION_ID
         ,NULL                                                    -- USER_CURRENCY_CONVERSION_TYPE
         ,NULL                                                    -- CURRENCY_CONVERSION_RATE
         ,NULL                                                    -- AVERAGE_JOURNAL_FLAG
         ,NULL                                                    -- ORIGINATING_BAL_SEG_VALUE
         ,gt_recon_dedu_cancel_tbl(i).segment1                    -- SEGMENT1
         ,gt_recon_dedu_cancel_tbl(i).segment2                    -- SEGMENT2
         ,gt_recon_dedu_cancel_tbl(i).segment3                    -- SEGMENT3
         ,gt_recon_dedu_cancel_tbl(i).segment4                    -- SEGMENT4
         ,gt_recon_dedu_cancel_tbl(i).segment5                    -- SEGMENT5
         ,gt_recon_dedu_cancel_tbl(i).segment6                    -- SEGMENT6
         ,gt_recon_dedu_cancel_tbl(i).segment7                    -- SEGMENT7
         ,gt_recon_dedu_cancel_tbl(i).segment8                    -- SEGMENT8
         ,NULL                                                    -- SEGMENT9
         ,NULL                                                    -- SEGMENT10
         ,NULL                                                    -- SEGMENT11
         ,NULL                                                    -- SEGMENT12
         ,NULL                                                    -- SEGMENT13
         ,NULL                                                    -- SEGMENT14
         ,NULL                                                    -- SEGMENT15
         ,NULL                                                    -- SEGMENT16
         ,NULL                                                    -- SEGMENT17
         ,NULL                                                    -- SEGMENT18
         ,NULL                                                    -- SEGMENT19
         ,NULL                                                    -- SEGMENT20
         ,NULL                                                    -- SEGMENT21
         ,NULL                                                    -- SEGMENT22
         ,NULL                                                    -- SEGMENT23
         ,NULL                                                    -- SEGMENT24
         ,NULL                                                    -- SEGMENT25
         ,NULL                                                    -- SEGMENT26
         ,NULL                                                    -- SEGMENT27
         ,NULL                                                    -- SEGMENT28
         ,NULL                                                    -- SEGMENT29
         ,NULL                                                    -- SEGMENT30
         ,gt_recon_dedu_cancel_tbl(i).entered_cr                  -- ENTERED_DR
         ,gt_recon_dedu_cancel_tbl(i).entered_dr                  -- ENTERED_CR
         ,NULL                                                    -- ACCOUNTED_DR
         ,NULL                                                    -- ACCOUNTED_CR
         ,NULL                                                    -- TRANSACTION_DATE
         ,gt_recon_dedu_cancel_tbl(i).b_description               -- REFERENCE1
         ,gt_recon_dedu_cancel_tbl(i).b_description               -- REFERENCE2
         ,NULL                                                    -- REFERENCE3
         ,lv_cancel ||gt_recon_dedu_cancel_tbl(i).h_description   -- REFERENCE4
         ,lv_cancel ||gt_recon_dedu_cancel_tbl(i).h_description   -- REFERENCE5
         ,NULL                                                    -- REFERENCE6
         ,NULL                                                    -- REFERENCE7
         ,NULL                                                    -- REFERENCE8
         ,NULL                                                    -- REFERENCE9
         ,gt_recon_dedu_cancel_tbl(i).l_description               -- REFERENCE10
         ,NULL                                                    -- REFERENCE11
         ,NULL                                                    -- REFERENCE12
         ,NULL                                                    -- REFERENCE13
         ,NULL                                                    -- REFERENCE14
         ,NULL                                                    -- REFERENCE15
         ,NULL                                                    -- REFERENCE16
         ,NULL                                                    -- REFERENCE17
         ,NULL                                                    -- REFERENCE18
         ,NULL                                                    -- REFERENCE19
         ,NULL                                                    -- REFERENCE20
         ,NULL                                                    -- REFERENCE21
         ,NULL                                                    -- REFERENCE22
         ,NULL                                                    -- REFERENCE23
         ,NULL                                                    -- REFERENCE24
         ,NULL                                                    -- REFERENCE25
         ,NULL                                                    -- REFERENCE26
         ,NULL                                                    -- REFERENCE27
         ,NULL                                                    -- REFERENCE28
         ,NULL                                                    -- REFERENCE29
         ,NULL                                                    -- REFERENCE30
         ,NULL                                                    -- JE_BATCH_ID
         ,lv_period_name                                          -- PERIOD_NAME
         ,NULL                                                    -- JE_HEADER_ID
         ,NULL                                                    -- JE_LINE_NUM
         ,NULL                                                    -- CHART_OF_ACCOUNTS_ID
         ,NULL                                                    -- FUNCTIONAL_CURRENCY_CODE
         ,NULL                                                    -- CODE_COMBINATION_ID
         ,NULL                                                    -- DATE_CREATED_IN_GL
         ,NULL                                                    -- WARNING_CODE
         ,NULL                                                    -- STATUS_DESCRIPTION
         ,NULL                                                    -- STAT_AMOUNT
--2021/05/18 mod start
--         ,NULL                                                    -- GROUP_ID
         ,gn_group_id                                             -- GROUP_ID
--2021/05/18 mod end
         ,cn_request_id                                           -- REQUEST_ID
         ,NULL                                                    -- SUBLEDGER_DOC_SEQUENCE_ID
         ,NULL                                                    -- SUBLEDGER_DOC_SEQUENCE_VALUE
         ,gt_recon_dedu_cancel_tbl(i).tax_code                    -- ATTRIBUTE1
         ,NULL                                                    -- ATTRIBUTE2
         ,NULL                                                    -- GL_SL_LINK_ID
         ,NULL                                                    -- GL_SL_LINK_TABLE
         ,gt_recon_dedu_cancel_tbl(i).recon_slip_num_1            -- ATTRIBUTE3
         ,NULL                                                    -- ATTRIBUTE4
         ,NULL                                                    -- ATTRIBUTE5
         ,NULL                                                    -- ATTRIBUTE6
         ,NULL                                                    -- ATTRIBUTE7
         ,gt_recon_dedu_cancel_tbl(i).deduction_recon_head_id     -- ATTRIBUTE8
         ,NULL                                                    -- ATTRIBUTE9
         ,NULL                                                    -- ATTRIBUTE10
         ,NULL                                                    -- ATTRIBUTE11
         ,NULL                                                    -- ATTRIBUTE12
         ,NULL                                                    -- ATTRIBUTE13
         ,NULL                                                    -- ATTRIBUTE14
         ,NULL                                                    -- ATTRIBUTE15
         ,NULL                                                    -- ATTRIBUTE16
         ,NULL                                                    -- ATTRIBUTE17
         ,NULL                                                    -- ATTRIBUTE18
         ,NULL                                                    -- ATTRIBUTE19
         ,NULL                                                    -- ATTRIBUTE20
         ,gt_recon_dedu_cancel_tbl(i).context                     -- CONTEXT
         ,NULL                                                    -- CONTEXT2
         ,NULL                                                    -- INVOICE_DATE
         ,NULL                                                    -- TAX_CODE
         ,NULL                                                    -- INVOICE_IDENTIFIER
         ,NULL                                                    -- INVOICE_AMOUNT
         ,NULL                                                    -- CONTEXT3
         ,NULL                                                    -- USSGL_TRANSACTION_CODE
         ,NULL                                                    -- DESCR_FLEX_ERROR_MESSAGE
         ,NULL                                                    -- JGZZ_RECON_REF
         ,NULL                                                    -- REFERENCE_DATE
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SQLERRM;
          RAISE insert_data_expt;
      END;
--
    END LOOP recon_dedu_loop;
--
    -- 一般会計OIFに作成した件数を取得
    SELECT COUNT(DISTINCT gi.reference4)
    INTO   gn_cancel_cnt
    FROM   gl_interface   gi
    WHERE  gi.request_id                = cn_request_id
    AND    SUBSTR(gi.reference4,1,3)    = lv_cancel
    ;
--
    -- 処理対象伝票件数に一般会計OIFに作成した件数を加算
    gn_target_cnt := gn_target_cnt + gn_cancel_cnt;
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
  END insert_gl_cancel_data;
--
  /***********************************************************************************
   * Procedure Name   : up_recon_cancel_data
   * Description      : 控除消込ヘッダー情報更新処理（取消）(A-9)
   ***********************************************************************************/
  PROCEDURE up_recon_cancel_data( ov_errbuf         OUT VARCHAR2          -- エラー・メッセージ           --# 固定 #
                                 ,ov_retcode        OUT VARCHAR2          -- リターン・コード             --# 固定 #
                                 ,ov_errmsg         OUT VARCHAR2 )        -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(25) := 'up_recon_cancel_data'; -- プログラム名
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
    ln_recon_head_id    NUMBER DEFAULT 0;      -- 多重更新会費用
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
    -- 控除消込ヘッダー情報更新処理
    --==============================================================
--
    -- 処理対象データのGL連携フラグを一括更新する
    IF ( gt_recon_dedu_cancel_tbl.COUNT > 0 ) THEN
      -- 正常データ更新
--
      <<cancel_data_loop>>
      FOR ln_loop_cnt IN 1..gt_recon_dedu_cancel_tbl.COUNT LOOP
        IF (gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id != nvl(ln_recon_head_id,0)) THEN

          UPDATE xxcok_deduction_recon_head     xdrh                                             -- 控除消込ヘッダー情報
          SET    xdrh.gl_if_flag               = CASE
                                                   WHEN xdrh.gl_if_flag = cv_y_flag THEN
                                                     cv_r_flag
                                                   ELSE
                                                     cv_u_flag
                                                 END                                                            -- 消込GL連携フラグ
                ,xdrh.last_updated_by          = cn_last_updated_by                                             -- 最終更新者
                ,xdrh.last_update_date         = cd_last_update_date                                            -- 最終更新日
                ,xdrh.last_update_login        = cn_last_update_login                                           -- 最終更新ログイン
                ,xdrh.request_id               = cn_request_id                                                  -- 要求ID
                ,xdrh.program_application_id   = cn_program_application_id                                      -- コンカレント・プログラム・アプリID
                ,xdrh.program_id               = cn_program_id                                                  -- コンカレント・プログラムID
                ,xdrh.program_update_date      = cd_program_update_date                                         -- プログラム更新日
          WHERE  xdrh.deduction_recon_head_id  = gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id  -- 控除消込ヘッダーID
          ;
--
          ln_recon_head_id := gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id;
--
        END IF;
--
      END LOOP cancel_data_loop;
--
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- 更新に失敗した場合
    WHEN update_data_expt THEN
      -- エラー件数設定
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => cv_sales_deduction
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => gt_recon_dedu_cancel_tbl(ln_loop_cnt).deduction_recon_head_id
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
  END up_recon_cancel_data;
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
    gn_normal_cnt    := 0;                 -- 処理件数
    gn_target_cnt    := 0;                 -- 登録対象件数
    gn_cancel_cnt    := 0;                 -- 削除対象件数
    gn_error_cnt     := 0;                 -- エラー件数
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
        , ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
        , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ -- # 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.販売控除データ抽出
    -- ===============================
    get_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
            , ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
            , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ -- # 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- データが1件以上あればA-3～A-6を実行する
    IF ( gt_recon_deductions_tbl.COUNT != 0 ) THEN
      -- ===============================
      -- A-3.一般会計OIF集約処理
      -- ===============================
      edit_work_data( ov_errbuf  => lv_errbuf           -- エラー・メッセージ           --# 固定 #
                    , ov_retcode => lv_retcode          -- リターン・コード             --# 固定 #
                    , ov_errmsg  => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-4.GL一般会計OIFデータ作成
      -- ===============================
      edit_gl_data( ov_errbuf       => lv_errbuf     -- エラー・メッセージ
                  , ov_retcode      => lv_retcode    -- リターン・コード
                  , ov_errmsg       => lv_errmsg);   -- ユーザー・エラー・メッセージ
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-5.GL一般会計OIFデータインサート処理
      -- ===============================
      insert_gl_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ
                    , ov_retcode => lv_retcode           -- リターン・コード
                    , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-6.控除消込ヘッダー情報更新処理
      -- ===============================
      up_ded_recon_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ
                       , ov_retcode => lv_retcode           -- リターン・コード
                       , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- A-7.GL仕訳データ抽出（取消）
    -- ===============================
    get_gl_cancel_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ
                      , ov_retcode => lv_retcode           -- リターン・コード
                      , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gt_recon_dedu_cancel_tbl.COUNT != 0) THEN
      -- ===============================
      -- A-8.GL一般会計OIFデータインサート処理（取消）
      -- ===============================
      insert_gl_cancel_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ
                           , ov_retcode => lv_retcode           -- リターン・コード
                           , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.控除消込ヘッダー情報更新処理（取消）
      -- ===============================
      up_recon_cancel_data( ov_errbuf  => lv_errbuf            -- エラー・メッセージ
                          , ov_retcode => lv_retcode           -- リターン・コード
                          , ov_errmsg  => lv_errmsg);          -- ユーザー・エラー・メッセージ
--
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
                , retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
                
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_xxccp_appl_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- 共通領域短縮アプリ名
    cv_target_cnt_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10733';  -- 処理対象伝票件数メッセージ
    cv_add_cnt_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10734';  -- 登録対象伝票件数メッセージ
    cv_del_cnt_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10735';  -- 取消対象伝票件数メッセージ
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
    -- A-10.終了処理
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
      gn_cancel_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --処理対象伝票件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_target_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録対象伝票件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_add_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --取消対象伝票件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxcok_short_nm
                                          , iv_name         => cv_del_cnt_msg
                                          , iv_token_name1  => cv_cnt_token
                                          , iv_token_value1 => TO_CHAR ( gn_cancel_cnt )
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
    ELSIF ( retcode = cv_status_error ) THEN
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
END XXCOK024A18C;
/
