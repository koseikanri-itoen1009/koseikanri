CREATE OR REPLACE PACKAGE BODY APPS.XXCSO020A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO020A07C (spec)
 * Description      : SP専決書情報CSV出力
 * MD.050           : SP専決書情報CSV出力 (MD050_CSO_020A07)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_sp_data         SP専決書情報出力(A-2)
 *  output_csv             CSVファイル出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2015/02/23    1.0   S.Yamashita      新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  init_err_expt               EXCEPTION;      -- 初期処理エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCSO020A07C';              -- パッケージ名
--
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcso          CONSTANT VARCHAR2(10)  := 'XXCSO';                     -- XXCSO
  -- 日付書式
  cv_format_fmt1              CONSTANT VARCHAR2(50)  := 'YYYYMMDD';
  cv_format_fmt2              CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  --
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                         -- 文字列括り
  cv_comma                    CONSTANT VARCHAR2(1)   := ',';                         -- カンマ
  cv_colon                    CONSTANT VARCHAR2(2)   := '：';                        -- コロン
  cv_prt_line                 CONSTANT VARCHAR2(4)   := ' － ';                      -- ハイフン
  -- メッセージコード
  cv_msg_cso_00011            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';          -- 業務処理日付取得エラー
  cv_msg_cso_00671            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00671';          -- 入力パラメータ用文字列
  cv_msg_cso_00644            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00644';          -- 抽出対象日期間大小チェックエラー
  cv_msg_cso_00723            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00723';          -- SP専決書情報CSVヘッダ1
  cv_msg_cso_00724            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00724';          -- SP専決書情報CSVヘッダ2
  cv_msg_cso_00731            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00731';          -- 年
  cv_msg_cso_00732            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00732';          -- 月
  cv_msg_cso_00733            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00733';          -- 日
  cv_msg_cso_00734            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00734';          -- 有
  cv_msg_cso_00735            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00735';          -- 無
--
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                -- 項目名
  cv_tkn_param_value          CONSTANT VARCHAR2(20)  := 'PARAM_VALUE';               -- 項目値
  cv_tkn_date_from            CONSTANT VARCHAR2(20)  := 'DATE_FROM';                 -- 対象日(FROM)
  cv_tkn_date_to              CONSTANT VARCHAR2(20)  := 'DATE_TO';                   -- 対象日(TO)
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                     -- 件数
--
  cv_tkn_val_00697            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00697';          -- 売上拠点
  cv_tkn_val_00707            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00707';          -- 顧客コード
  cv_tkn_val_00725            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00725';          -- 申請拠点
  cv_tkn_val_00726            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00726';          -- 申請日(FROM)
  cv_tkn_val_00727            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00727';          -- 申請日(TO)
  cv_tkn_val_00728            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00728';          -- ステータス
  cv_tkn_val_00729            CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00729';          -- 判定区分
--
  -- 参照タイプ名
  cv_lookup_type_01           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STATUS_CD';          -- SP専決ステータス
  cv_lookup_type_02           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_APPLICATION_TYPE';   -- SP専決申請区分
  cv_lookup_type_03           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';        -- 業態小分類
  cv_lookup_type_04           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';        -- 業態区分
  cv_lookup_type_05           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_VD_SECCHI_BASYO';   -- 設置場所
  cv_lookup_type_06           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_OPEN_CLOSE_TYPE';    -- SP専決物件オープンクローズ区分
  cv_lookup_type_07           CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_KOKYAKU_STATUS';    -- 顧客ステータス
  cv_lookup_type_08           CONSTANT VARCHAR2(30)  := 'XXCSO1_CSI_JOB_KBN';           -- 作業区分タイプ
  cv_lookup_type_09           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_STANDARD_TYPE';      -- SP専決規格内外区分
  cv_lookup_type_10           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_BUSINESS_COND';      -- SP専決取引条件区分
  cv_lookup_type_11           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ALL_CONTAINER_TYPE'; -- SP専決全容器区分
  cv_lookup_type_12           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_BIDDING_ITEM_TYPE';  -- SP専決入札案件区分
  cv_lookup_type_13           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_PRESENCE_OR_ABSENCE';-- SP専決有無区分
  cv_lookup_type_14           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_TAX_DIVISION';       -- SP専決税区分
  cv_lookup_type_15           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_INST_SUPP_PAY_TYPE'; -- SP専決支払条件（設置協賛金）
  cv_lookup_type_16           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ERECTRIC_PRESENCE';  -- SP専決有無区分（電気代）
  cv_lookup_type_17           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELECTRIC_PAY_TYPE';  -- SP専決支払条件（電気代）
  cv_lookup_type_18           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELEC_PAY_CNG_TYPE';  -- SP専決支払条件（変動電気代）
  cv_lookup_type_19           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELECTRIC_BILL_TYPE'; -- SP専決電気代区分
  cv_lookup_type_20           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_ELEC_PAY_CYCLE';     -- SP専決支払サイクル（電気代）
  cv_lookup_type_21           CONSTANT VARCHAR2(30)  := 'XXCSO1_MONTHS_TYPE';           -- 月タイプ
  cv_lookup_type_22           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_INTRO_CHG_PAY_TYPE'; -- SP専決支払条件（紹介手数料）
  cv_lookup_type_23           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_TRANSFER_FEE_TYPE';  -- SP専決振込手数料負担区分
  cv_lookup_type_24           CONSTANT VARCHAR2(30)  := 'XXCSO1_DETAILS_OF_PAYMENT';    -- 支払明細書タイプ
  cv_lookup_type_25           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_WORK_REQUEST_TYPE';  -- SP専決作業依頼区分
  cv_lookup_type_26           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_APPROVAL_STATE_TYPE';-- SP専決回送状態区分
  cv_lookup_type_27           CONSTANT VARCHAR2(30)  := 'XXCSO1_SP_DECISION_CONTENT';   -- SP専決決裁内容
--
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- 有効
  cv_output_log               CONSTANT VARCHAR2(3)   := 'LOG';                       -- 出力区分：ログ
--
  cv_presence_kbn_0           CONSTANT VARCHAR2(1)   := '0';                         -- 有無区分:0（無）
  cv_kbn_1                    CONSTANT VARCHAR2(1)   := '1';                         -- 判定区分:1
  cv_kbn_2                    CONSTANT VARCHAR2(1)   := '2';                         -- 判定区分:2
  cv_status_3                 CONSTANT VARCHAR2(1)   := '3';                         -- SP専決ステータス:3（有効）
  cv_cust_class_1             CONSTANT VARCHAR2(1)   := '1';                         -- 顧客区分:1
  cv_cust_class_2             CONSTANT VARCHAR2(1)   := '2';                         -- 顧客区分:2
  cv_cust_class_3             CONSTANT VARCHAR2(1)   := '3';                         -- 顧客区分:3
  cv_cust_class_4             CONSTANT VARCHAR2(1)   := '4';                         -- 顧客区分:4
  cv_cust_class_5             CONSTANT VARCHAR2(1)   := '5';                         -- 顧客区分:5
  cv_decision_sends_10        CONSTANT VARCHAR2(2)   := '10';                        -- 回送先:10（確認者）
  cv_decision_sends_20        CONSTANT VARCHAR2(2)   := '20';                        -- 回送先:20（承認者）
  cv_decision_sends_30        CONSTANT VARCHAR2(2)   := '30';                        -- 回送先:30（地区営業管理課長）
  cv_decision_sends_40        CONSTANT VARCHAR2(2)   := '40';                        -- 回送先:40（地区営業部長）
  cv_decision_sends_50        CONSTANT VARCHAR2(2)   := '50';                        -- 回送先:50（関係先）
  cv_decision_sends_60        CONSTANT VARCHAR2(2)   := '60';                        -- 回送先:60（自販機部課長）
  cv_decision_sends_70        CONSTANT VARCHAR2(2)   := '70';                        -- 回送先:70（自販機部長）
  cv_decision_sends_80        CONSTANT VARCHAR2(2)   := '80';                        -- 回送先:80（拠点管理部長）
  cv_decision_sends_90        CONSTANT VARCHAR2(2)   := '90';                        -- 回送先:90（営業本部長）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_base_code                xxcso_sp_decision_headers.app_base_code%TYPE; -- 申請(売上)拠点
  gd_date_from                DATE;                                         -- 申請日(FROM)
  gd_date_to                  DATE;                                         -- 申請日(TO)
  gt_status                   xxcso_sp_decision_headers.status%TYPE;        -- ステータス
  gt_customer_cd              xxcso_cust_accounts_v.account_number%TYPE;    -- 顧客コード
  gv_kbn                      VARCHAR2(1);                                  -- 判定区分
  gd_process_date             DATE;                                         -- 業務日付
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  -- SP専決書情報カーソル
  CURSOR get_sp_cur
  IS
    SELECT /*+ INDEX(xsdh XXCSO_SP_DECISION_HEADERS_N01) */
     TO_CHAR(xsdh.last_update_date,cv_format_fmt2)           AS last_update_date              -- 最終更新日時
    ,xsdh.sp_decision_number                                 AS sp_decision_number            -- SP専決書番号
    ,xsdh.status                                             AS status                        -- ステータス
    ,xsdh.application_type                                   AS application_type              -- 申請区分
    ,TO_CHAR(xsdh.application_date,cv_format_fmt2)           AS application_date              -- 申請日
    ,TO_CHAR(xsdh.approval_complete_date,cv_format_fmt2)     AS approval_complete_date        -- 承認完了日
    ,xsdh.application_code                                   AS application_code              -- 申請者
    ,xsdh.app_base_code                                      AS app_base_code                 -- 申請拠点
    ,xca.account_number                                      AS account_number                -- 顧客コード
    ,DECODE(xsdh.status,cv_status_3,xca.party_name
                                   ,xsdc1.party_name)        AS account_name                  -- 顧客名
    ,DECODE(xsdh.status,cv_status_3,xca.organization_name_phonetic
                                   ,xsdc1.party_name_alt)    AS account_name_alt              -- 顧客名カナ
    ,DECODE(xsdh.status,cv_status_3,xca.established_site_name
                                   ,xsdc1.install_name)      AS install_name                  -- 設置先名
    ,DECODE(xsdh.status,cv_status_3,hl.postal_code
                                   ,xsdc1.postal_code)       AS install_postal_code           -- 設置先郵便番号
    ,DECODE(xsdh.status,cv_status_3,hl.state
                                   ,xsdc1.state)             AS install_state                 -- 設置先都道府県
    ,DECODE(xsdh.status,cv_status_3,hl.city
                                   ,xsdc1.city)              AS install_city                  -- 設置先市・区
    ,DECODE(xsdh.status,cv_status_3,hl.address1
                                   ,xsdc1.address1)          AS install_address1              -- 設置先住所1
    ,DECODE(xsdh.status,cv_status_3,hl.address2
                                   ,xsdc1.address2)          AS install_address2              -- 設置先住所2
    ,DECODE(xsdh.status,cv_status_3,hl.address_lines_phonetic
                             ,xsdc1.address_lines_phonetic)  AS install_phone_number          -- 設置先電話番号
    ,DECODE(xsdh.status,cv_status_3,xca.business_low_type
                            ,xsdc1.business_condition_type)  AS business_low_type             -- 業態（小分類）
    ,DECODE(xsdh.status,cv_status_3,xca.industry_div
                                  ,xsdc1.business_type)      AS business_type                 -- 業種
    ,DECODE(xsdh.status,cv_status_3,xca.establishment_location
                                    ,xsdc1.install_location) AS install_location              -- 設置場所
    ,DECODE(xsdh.status,cv_status_3,xca.open_close_div
                        ,xsdc1.external_reference_opcl_type) AS open_close_div                -- オープン/クローズ
    ,DECODE(xsdh.status,cv_status_3,xca.employees
                                   ,xsdc1.employee_number)   AS employee                      -- 社員数
    ,DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                                   ,xsdc1.publish_base_code) AS sale_base_code                -- 担当拠点
    ,TO_CHAR(xsdh.install_date,cv_format_fmt2)               AS install_date                  -- 設置日
    ,xsdh.lease_company                                      AS lease_company                 -- リース仲介会社
    ,xca.customer_status                                     AS customer_status               -- 顧客ステータス
    ,(SELECT employee_number AS employee_number
      FROM   xxcso_cust_resources_v2 xcrv2
      WHERE  xcrv2.cust_account_id = xca.cust_account_id
      )                                                      AS sale_employee_number          -- 担当営業員コード
    ,(SELECT full_name AS full_name
      FROM   xxcso_employees_v2 xev2
      WHERE  xev2.user_name = (SELECT employee_number AS employee_number
                               FROM   xxcso_cust_resources_v2 xcrv2
                               WHERE  xcrv2.cust_account_id = xca.cust_account_id
                               )
      )                                                      AS sale_employee_name            -- 担当営業員名
    ,xcc.contract_number                                     AS contract_number               -- 契約先コード
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.party_name,
                                   xcc.contract_name)        AS contract_name                 -- 契約先名
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.party_name_alt,
                                   xcc.contract_name_kana)   AS contract_name_alt             -- 契約先名カナ
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.postal_code,
                                   xcc.post_code)            AS contract_post_code            -- 契約先郵便番号
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.state,
                                   xcc.prefectures)          AS contract_state                -- 契約先都道府県
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.city,
                                   xcc.city_ward)            AS contract_city                 -- 契約先市・区
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address1,
                                   xcc.address_1)            AS contract_address_1            -- 契約先住所1
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address2,
                                   xcc.address_2)            AS contract_address_2            -- 契約先住所2
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.address_lines_phonetic,
                                   xcc.phone_number)         AS contract_phone_number         -- 契約先電話番号
    ,DECODE(xsdc2.customer_id,NULL,xsdc2.representative_name,
                                   xcc.delegate_name)        AS contract_delegate_name        -- 契約先代表者名
    ,xsdh.newold_type                                        AS newold_type                   -- 新台旧台区分
    ,xsdh.maker_code                                         AS maker_code                    -- メーカーコード
    ,xsdh.un_number                                          AS un_number                     -- 機種コード
    ,xsdh.sele_number                                        AS sele_number                   -- セレ数
    ,xsdh.standard_type                                      AS standard_type                 -- 規格内外区分
    ,xsdh.condition_business_type                            AS condition_business_type       -- 取引条件区分
    ,xsdh.all_container_type                                 AS all_container_type            -- 全容器区分
    ,xsdh.contract_year_date                                 AS contract_year_date            -- 契約年数
    ,xsdh.contract_year_month                                AS contract_year_month           -- 契約月数
    ,xsdh.contract_start_year                                AS contract_start_year           -- 契約期間開始（年）
    ,xsdh.contract_start_month                               AS contract_start_month          -- 契約期間開始（月）
    ,xsdh.contract_end_year                                  AS contract_end_year             -- 契約期間終了（年）
    ,xsdh.contract_end_month                                 AS contract_end_month            -- 契約期間終了（月）
    ,xsdh.bidding_item                                       AS bidding_item                  -- 入札案件
    ,xsdh.cancell_before_maturity                            AS cancell_before_maturity       -- 中途解約条項
    ,xsdh.ad_assets_type                                     AS ad_assets_type                -- 行政財産使用料
    ,xsdh.ad_assets_amt                                      AS ad_assets_amt                 -- 行政財産使用料総額
    ,xsdh.ad_assets_this_time                                AS ad_assets_this_time           -- 行政財産使用料（今回支払）
    ,xsdh.ad_assets_payment_year                             AS ad_assets_payment_year        -- 行政財産使用料年目
    ,TO_CHAR(xsdh.ad_assets_payment_date,cv_format_fmt2)     AS ad_assets_payment_date        -- 行政財産使用料支払期日
    ,xsdh.tax_type                                           AS tax_type                      -- 覚書情報税区分
    ,xsdh.install_supp_type                                  AS install_supp_type             -- 設置協賛金
    ,xsdh.install_supp_payment_type                          AS install_supp_payment_type     -- 設置協賛金区分
    ,xsdh.install_supp_amt                                   AS install_supp_amt              -- 設置協賛金総額
    ,xsdh.install_supp_this_time                             AS install_supp_this_time        -- 設置協賛金（今回支払）
    ,xsdh.install_supp_payment_year                          AS install_supp_payment_year     -- 設置協賛金年目
    ,TO_CHAR(xsdh.install_supp_payment_date,cv_format_fmt2)  AS install_supp_payment_date     -- 設置協賛金支払期日
    ,xsdh.electricity_type                                   AS electricity_type              -- 電気代
    ,xsdh.electric_payment_type                              AS electric_payment_type         -- 電気代契約先
    ,xsdh.electric_payment_change_type                       AS electric_payment_change_type  -- 電気代区分
    ,xsdh.electricity_amount                                 AS electricity_amount            -- 電気代金額
    ,xsdh.electricity_type                                   AS electricity_change_type       -- 電気代変動区分
    ,xsdh.electric_payment_cycle                             AS electric_payment_cycle        -- 電気代支払サイクル
    ,xsdh.electric_closing_date                              AS electric_closing_date         -- 電気代締め日
    ,xsdh.electric_trans_month                               AS electric_trans_month          -- 電気代振込月
    ,xsdh.electric_trans_date                                AS electric_trans_date           -- 電気代振込日
    ,xsdh.electric_trans_name                                AS electric_trans_name           -- 電気代契約先以外名
    ,xsdh.electric_trans_name_alt                            AS electric_trans_name_alt       -- 電気代契約先以外名（カナ）
    ,xsdh.intro_chg_type                                     AS intro_chg_type                -- 紹介手数料
    ,xsdh.intro_chg_payment_type                             AS cust_cointro_chg_payment_type -- 紹介手数料区分
    ,xsdh.intro_chg_amt                                      AS intro_chg_amt                 -- 紹介手数料総額
    ,xsdh.intro_chg_this_time                                AS intro_chg_this_time           -- 紹介手数料（今回支払）
    ,xsdh.intro_chg_payment_year                             AS intro_chg_payment_year        -- 紹介手数料年目
    ,TO_CHAR(xsdh.intro_chg_payment_date,cv_format_fmt2)     AS intro_chg_payment_date        -- 紹介手数料支払期日
    ,xsdh.intro_chg_per_sales_price                          AS intro_chg_per_sales_price     -- 紹介手数料％
    ,xsdh.intro_chg_per_piece                                AS intro_chg_per_piece           -- 紹介手数料円
    ,xsdh.intro_chg_closing_date                             AS intro_chg_closing_date        -- 紹介手数料締め日
    ,xsdh.intro_chg_trans_month                              AS intro_chg_trans_month         -- 紹介手数料振込月
    ,xsdh.intro_chg_trans_date                               AS intro_chg_trans_date          -- 紹介手数料振込日
    ,xsdh.intro_chg_trans_name                               AS intro_chg_trans_name          -- 紹介手数料契約先以外名
    ,xsdh.intro_chg_trans_name_alt                           AS intro_chg_trans_name_alt      -- 紹介手数料契約先以外名（カナ）
    ,xsdh.condition_reason                                   AS condition_reason              -- 特別条件の理由
    ,xsdh.bm1_send_type                                      AS bm1_send_type                 -- BM1送付先区分
    ,pv1.segment1                                            AS bm1_send_code                 -- BM1送付先コード
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.party_name,
                                   pvs1.attribute1)          AS bm1_send_name                 -- BM1送付先名
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.party_name_alt,
                                   pv1.vendor_name_alt)      AS bm1_send_name_alt             -- BM1送付先カナ
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.postal_code,
                                   pvs1.zip)                 AS bm1_postal_code               -- BM1郵便番号
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address1,
                                   pvs1.address_line1)       AS bm1_address1                  -- BM1住所1
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address2,
                                   pvs1.address_line2)       AS bm1_address2                  -- BM1住所2
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.address_lines_phonetic,
                                   pvs1.phone)               AS bm1_phone_number              -- BM1電話番号
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.transfer_commission_type
                                  ,pvs1.bank_charge_bearer)  AS bm1_bank_charge_bearer        -- BM1振込手数料負担
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.bm_payment_type
                                  ,pvs1.attribute4)          AS bm1_bm_payment_type           -- BM1支払方法・明細書
    ,DECODE(xsdc3.customer_id,NULL,xsdc3.inquiry_base_code,
                                   pvs1.attribute5)          AS bm1_inquiry_base_code         -- BM1問合せ担当拠点コード
    ,pv2.segment1                                            AS bm2_send_code                 -- BM2送付先コード
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.party_name,
                                   pvs2.attribute1)          AS bm2_send_name                 -- BM2送付先名
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.party_name_alt,
                                   pv2.vendor_name_alt)      AS bm2_send_name_alt             -- BM2送付先カナ
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.postal_code,
                                   pvs2.zip)                 AS bm2_postal_code               -- BM2郵便番号
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address1,
                                   pvs2.address_line1)       AS bm2_address1                  -- BM2住所1
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address2,
                                   pvs2.address_line2)       AS bm2_address2                  -- BM2住所2
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.address_lines_phonetic,
                                   pvs2.phone)               AS bm2_phone_number              -- BM2電話番号
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.transfer_commission_type
                                  ,pvs2.bank_charge_bearer)  AS bm2_bank_charge_bearer        -- BM2振込手数料負担
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.bm_payment_type
                                  ,pvs2.attribute4)          AS bm2_bm_payment_type           -- BM2支払方法・明細書
    ,DECODE(xsdc4.customer_id,NULL,xsdc4.inquiry_base_code,
                                   pvs2.attribute5)          AS bm2_inquiry_base_code         -- BM2問合せ担当拠点コード
    ,pv3.segment1                                            AS bm3_send_code                 -- BM3送付先コード
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.party_name,
                                   pvs3.attribute1)          AS bm3_send_name                 -- BM3送付先名
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.party_name_alt,
                                   pv3.vendor_name_alt)      AS bm3_send_name_alt             -- BM3送付先カナ
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.postal_code,
                                   pvs3.zip)                 AS bm3_postal_code               -- BM3郵便番号
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address1,
                                   pvs3.address_line1)       AS bm3_address1                  -- BM3住所1
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address2,
                                   pvs3.address_line2)       AS bm3_address2                  -- BM3住所2
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.address_lines_phonetic,
                                   pvs3.phone)               AS bm3_phone_number              -- BM3電話番号
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.transfer_commission_type
                                  ,pvs3.bank_charge_bearer)  AS bm3_bank_charge_bearer        -- BM3振込手数料負担
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.bm_payment_type
                                  ,pvs3.attribute4)          AS bm3_bm_payment_type           -- BM3支払方法・明細書
    ,DECODE(xsdc5.customer_id,NULL,xsdc5.inquiry_base_code,
                                   pvs3.attribute5)          AS bm3_inquiry_base_code         -- BM3問合せ担当拠点コード
    ,xsdh.sales_month                                        AS sales_month                   -- 月間売上
    ,xsdh.sales_year                                         AS sales_year                    -- 年間売上
    ,xsdh.sales_gross_margin_rate                            AS sales_gross_margin_rate       -- 売上粗利率
    ,xsdh.year_gross_margin_amt                              AS year_gross_margin_amt         -- 年間粗利金額
    ,xsdh.bm_rate                                            AS bm_rate                       -- ＢＭ率
    ,xsdh.vd_sales_charge                                    AS vd_sales_charge               -- ＶＤ販売手数料
    ,xsdh.install_support_amt_year                           AS install_support_amt_year      -- 設置協賛金／年
    ,xsdh.lease_charge_month                                 AS lease_charge_month            -- リース料（月額）
    ,xsdh.construction_charge                                AS construction_charge           -- 工事費
    ,xsdh.vd_lease_charge                                    AS vd_lease_charge               -- ＶＤリース料
    ,xsdh.electricity_amt_month                              AS electricity_amt_month         -- 電気代（月）
    ,xsdh.electricity_amt_year                               AS electricity_amt_year          -- 電気代（年）
    ,xsdh.transportation_charge                              AS transportation_charge         -- 運送費Ａ
    ,xsdh.labor_cost_other                                   AS labor_cost_other              -- 人件費他
    ,xsdh.total_cost                                         AS total_cost                    -- 費用合計
    ,xsdh.operating_profit                                   AS operating_profit              -- 営業利益
    ,xsdh.operating_profit_rate                              AS operating_profit_rate         -- 営業利益率
    ,xsdh.break_even_point                                   AS break_even_point              -- 損益分岐点
    ,xsds1.approve_code                                      AS approve_code_10               -- 承認者コード(確認者)
    ,xsds1.work_request_type                                 AS work_request_type_10          -- 作業依頼区分(確認者)
    ,xsds1.approval_state_type                               AS approval_state_type_10        -- 決裁状態区分(確認者)
    ,TO_CHAR(xsds1.approval_date,cv_format_fmt2)             AS approval_date_10              -- 決裁日(確認者)
    ,xsds1.approval_content                                  AS approval_content_10           -- 決裁内容(確認者)
    ,xsds1.approval_comment                                  AS approval_comment_10           -- 承認コメント(確認者)
    ,xsds2.approve_code                                      AS approve_code_20               -- 承認者コード(承認者)
    ,xsds2.work_request_type                                 AS work_request_type_20          -- 作業依頼区分(承認者)
    ,xsds2.approval_state_type                               AS approval_state_type_20        -- 決裁状態区分(承認者)
    ,TO_CHAR(xsds2.approval_date,cv_format_fmt2)             AS approval_date_20              -- 決裁日(承認者)
    ,xsds2.approval_content                                  AS approval_content_20           -- 決裁内容(承認者)
    ,xsds2.approval_comment                                  AS approval_comment_20           -- 承認コメント(承認者)
    ,xsds3.approve_code                                      AS approve_code_30               -- 承認者コード(地区営業管理課長)
    ,xsds3.work_request_type                                 AS work_request_type_30          -- 作業依頼区分(地区営業管理課長)
    ,xsds3.approval_state_type                               AS approval_state_type_30        -- 決裁状態区分(地区営業管理課長)
    ,TO_CHAR(xsds3.approval_date,cv_format_fmt2)             AS approval_date_30              -- 決裁日(地区営業管理課長)
    ,xsds3.approval_content                                  AS approval_content_30           -- 決裁内容(地区営業管理課長)
    ,xsds3.approval_comment                                  AS approval_comment_30           -- 承認コメント(地区営業管理課長)
    ,xsds4.approve_code                                      AS approve_code_40               -- 承認者コード(地区営業部長)
    ,xsds4.work_request_type                                 AS work_request_type_40          -- 作業依頼区分(地区営業部長)
    ,xsds4.approval_state_type                               AS approval_state_type_40        -- 決裁状態区分(地区営業部長)
    ,TO_CHAR(xsds4.approval_date,cv_format_fmt2)             AS approval_date_40              -- 決裁日(地区営業部長)
    ,xsds4.approval_content                                  AS approval_content_40           -- 決裁内容(地区営業部長)
    ,xsds4.approval_comment                                  AS approval_comment_40           -- 承認コメント(地区営業部長)
    ,xsds5.approve_code                                      AS approve_code_50               -- 承認者コード(関係先)
    ,xsds5.work_request_type                                 AS work_request_type_50          -- 作業依頼区分(関係先)
    ,xsds5.approval_state_type                               AS approval_state_type_50        -- 決裁状態区分(関係先)
    ,TO_CHAR(xsds5.approval_date,cv_format_fmt2)             AS approval_date_50              -- 決裁日(関係先)
    ,xsds5.approval_content                                  AS approval_content_50           -- 決裁内容(関係先)
    ,xsds5.approval_comment                                  AS approval_comment_50           -- 承認コメント(関係先)
    ,xsds6.approve_code                                      AS approve_code_60               -- 承認者コード(自販機部課長)
    ,xsds6.work_request_type                                 AS work_request_type_60          -- 作業依頼区分(自販機部課長)
    ,xsds6.approval_state_type                               AS approval_state_type_60        -- 決裁状態区分(自販機部課長)
    ,TO_CHAR(xsds6.approval_date,cv_format_fmt2)             AS approval_date_60              -- 決裁日(自販機部課長)
    ,xsds6.approval_content                                  AS approval_content_60           -- 決裁内容(自販機部課長)
    ,xsds6.approval_comment                                  AS approval_comment_60           -- 承認コメント(自販機部課長)
    ,xsds7.approve_code                                      AS approve_code_70               -- 承認者コード(自販機部長)
    ,xsds7.work_request_type                                 AS work_request_type_70          -- 作業依頼区分(自販機部長)
    ,xsds7.approval_state_type                               AS approval_state_type_70        -- 決裁状態区分(自販機部長)
    ,TO_CHAR(xsds7.approval_date,cv_format_fmt2)             AS approval_date_70              -- 決裁日(自販機部長)
    ,xsds7.approval_content                                  AS approval_content_70           -- 決裁内容(自販機部長)
    ,xsds7.approval_comment                                  AS approval_comment_70           -- 承認コメント(自販機部長)
    ,xsds8.approve_code                                      AS approve_code_80               -- 承認者コード(拠点管理部長)
    ,xsds8.work_request_type                                 AS work_request_type_80          -- 作業依頼区分(拠点管理部長)
    ,xsds8.approval_state_type                               AS approval_state_type_80        -- 決裁状態区分(拠点管理部長)
    ,TO_CHAR(xsds8.approval_date,cv_format_fmt2)             AS approval_date_80              -- 決裁日(拠点管理部長)
    ,xsds8.approval_content                                  AS approval_content_80           -- 決裁内容(拠点管理部長)
    ,xsds8.approval_comment                                  AS approval_comment_80           -- 承認コメント(拠点管理部長)
    ,xsds9.approve_code                                      AS approve_code_90               -- 承認者コード(営業本部長)
    ,xsds9.work_request_type                                 AS work_request_type_90          -- 作業依頼区分(営業本部長)
    ,xsds9.approval_state_type                               AS approval_state_type_90        -- 決裁状態区分(営業本部長)
    ,TO_CHAR(xsds9.approval_date,cv_format_fmt2)             AS approval_date_90              -- 決裁日(営業本部長)
    ,xsds9.approval_content                                  AS approval_content_90           -- 決裁内容(営業本部長)
    ,xsds9.approval_comment                                  AS approval_comment_90           -- 承認コメント(営業本部長)
  FROM
    xxcso_sp_decision_headers  xsdh   -- SP専決ヘッダテーブル
   ,xxcso_sp_decision_custs    xsdc1  -- SP専決顧客テーブル（設置先）
   ,xxcso_sp_decision_custs    xsdc2  -- SP専決顧客テーブル（契約先）
   ,xxcso_sp_decision_custs    xsdc3  -- SP専決顧客テーブル（ＢＭ１）
   ,xxcso_sp_decision_custs    xsdc4  -- SP専決顧客テーブル（ＢＭ２）
   ,xxcso_sp_decision_custs    xsdc5  -- SP専決顧客テーブル（ＢＭ３）
   ,xxcso_cust_accounts_v      xca    -- 顧客マスタビュー
   ,hz_party_sites             hps    -- パーティサイトマスタ
   ,hz_locations               hl     -- 顧客所在地マスタ
   ,xxcso_contract_customers   xcc    -- 契約先テーブル
   ,po_vendors                 pv1    -- 仕入先マスタ（ＢＭ１）
   ,po_vendors                 pv2    -- 仕入先マスタ（ＢＭ２）
   ,po_vendors                 pv3    -- 仕入先マスタ（ＢＭ３）
   ,po_vendor_sites_all        pvs1   -- 仕入先サイトマスタ（ＢＭ１）
   ,po_vendor_sites_all        pvs2   -- 仕入先サイトマスタ（ＢＭ２）
   ,po_vendor_sites_all        pvs3   -- 仕入先サイトマスタ（ＢＭ３）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_10
    )                                xsds1  -- SP専決回送先テーブル（確認者）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_20
    )                                xsds2  -- SP専決回送先テーブル（承認者）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_30
    )                                xsds3  -- SP専決回送先テーブル（地区営業管理課長）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_40
    )                                xsds4  -- SP専決回送先テーブル（地区営業部長）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_50
    )                                xsds5  -- SP専決回送先テーブル（関係先）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_60
    )                                xsds6  -- SP専決回送先テーブル（自販機部課長）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_70
    )                                xsds7 -- SP専決回送先テーブル（自販機部長）
   ,(SELECT/*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_80
    )                                xsds8  -- SP専決回送先テーブル（拠点管理部長）
   ,(SELECT /*+ INDEX(xsds XXCSO_SP_DECISION_SENDS_U01) */
            xsds.sp_decision_header_id sp_decision_header_id
           ,xsds.approve_code          approve_code
           ,xsds.work_request_type     work_request_type
           ,xsds.approval_state_type   approval_state_type
           ,xsds.approval_date         approval_date
           ,xsds.approval_content      approval_content
           ,xsds.approval_comment      approval_comment
     FROM   xxcso_sp_decision_sends xsds
     WHERE  xsds.approval_authority_number = cv_decision_sends_90
    )                                xsds9 -- SP専決回送先テーブル（営業本部長）
  WHERE
      xsdc1.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP専決ヘッダID
  AND xsdc1.sp_decision_customer_class = cv_cust_class_1               -- 顧客区分
  AND xsdc1.customer_id                = xca.cust_account_id           -- 顧客ID
  AND hps.party_id                     = xca.party_id                  -- パーティID
  AND hl.location_id                   = hps.location_id               -- 設置先ID
  AND xsdc2.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP専決ヘッダID
  AND xsdc2.sp_decision_customer_class = cv_cust_class_2               -- 顧客区分
  AND xsdc2.customer_id                = xcc.contract_customer_id(+)   -- 顧客ID
  AND xsdc3.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP専決ヘッダID
  AND xsdc3.sp_decision_customer_class = cv_cust_class_3               -- 顧客区分
  AND xsdc3.customer_id                = pv1.vendor_id(+)              -- 仕入先ID
  AND xsdc3.customer_id                = pvs1.vendor_id(+)             -- 仕入先ID
  AND xsdc4.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP専決ヘッダID
  AND xsdc4.sp_decision_customer_class = cv_cust_class_4               -- 顧客区分
  AND xsdc4.customer_id                = pv2.vendor_id(+)              -- 仕入先ID
  AND xsdc4.customer_id                = pvs2.vendor_id(+)             -- 仕入先ID
  AND xsdc5.sp_decision_header_id      = xsdh.sp_decision_header_id    -- SP専決ヘッダID
  AND xsdc5.sp_decision_customer_class = cv_cust_class_5               -- 顧客区分
  AND xsdc5.customer_id                = pv3.vendor_id(+)              -- 仕入先ID
  AND xsdc5.customer_id                = pvs3.vendor_id(+)             -- 仕入先ID
  AND xsdh.sp_decision_header_id       = xsds1.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds2.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds3.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds4.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds5.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds6.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds7.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds8.sp_decision_header_id   -- SP専決ヘッダID
  AND xsdh.sp_decision_header_id       = xsds9.sp_decision_header_id   -- SP専決ヘッダID
  AND (((gv_kbn = cv_kbn_1)                                                 -- 判定区分が'1'の場合
      AND ((gt_base_code IS NOT NULL AND xsdh.app_base_code = gt_base_code) -- 入力パラメータ.申請(売上)拠点がNOT NULLの場合
        OR (gt_base_code IS NULL                                            -- 入力パラメータ.申請(売上)拠点がNULLの場合
              AND gt_customer_cd IS NULL                                    -- 入力パラメータ.顧客コードがNULLの場合
              AND EXISTS(SELECT 'X'
                         FROM   xxcso_sp_sec_base_info_v xssbi
                         WHERE  xsdh.app_base_code = xssbi.base_code
                         )                                                  -- SP専決セキュリティ拠点ビューの拠点を取得
           )
        OR (gt_base_code IS NULL AND gt_customer_cd IS NOT NULL)            -- 顧客のみ指定された場合
          )
         )
     OR ((gv_kbn = cv_kbn_2)                                                -- 判定区分が'2'の場合
      AND ((gt_base_code IS NOT NULL                                        -- 入力パラメータ.申請(売上)拠点がNOT NULLの場合
             AND DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                                   ,xsdc1.publish_base_code) = gt_base_code)
       OR (gt_base_code IS NULL                                             -- 入力パラメータ.申請(売上)拠点がNULLの場合
            AND gt_customer_cd IS NULL                                      -- 入力パラメータ.顧客コードがNULLの場合
            AND EXISTS(SELECT 'X'
                       FROM   xxcso_sp_sec_base_info_v xssbi
                       WHERE  (DECODE(xsdh.status,cv_status_3,xca.sale_base_code
                             ,xsdc1.publish_base_code) = xssbi.base_code)   -- SP専決セキュリティ拠点ビューの拠点を取得
                      )
          )
       OR (gt_base_code IS NULL AND gt_customer_cd IS NOT NULL)             -- 顧客のみ指定された場合
         )
        )
      )
  AND xsdh.application_date >= gd_date_from       -- 申請日（FROM)
  AND xsdh.application_date <= gd_date_to         -- 申請日（TO)
  AND ((gt_status IS NOT NULL                     -- 入力パラメータ.ステータスがNOT NULLの場合
          AND xsdh.status = gt_status)
       OR (gt_status IS NULL)                     -- 入力パラメータ.ステータスがNULLの場合
      )
  AND ((gt_customer_cd IS NOT NULL                -- 入力パラメータ.顧客コードがNOT NULLの場合
          AND xca.account_number = gt_customer_cd)
       OR (gt_customer_cd IS NULL)                -- 入力パラメータ.顧客コードがNULLの場合
      )
  ORDER BY xsdh.sp_decision_number ASC
  ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code     IN  VARCHAR2     -- 申請(売上)拠点
   ,iv_app_date_from IN  VARCHAR2     -- 申請日(FROM)
   ,iv_app_date_to   IN  VARCHAR2     -- 申請日(TO)
   ,iv_status        IN  VARCHAR2     -- ステータス
   ,iv_customer_cd   IN  VARCHAR2     -- 顧客コード
   ,iv_kbn           IN  VARCHAR2     -- 判定区分
   ,ov_errbuf        OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode       OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg        OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_base_code       VARCHAR2(1000);  -- 1.申請(売上)拠点
    lv_app_date_from   VARCHAR2(1000);  -- 2.申請日(FROM)
    lv_app_date_to     VARCHAR2(1000);  -- 3.申請日(TO)
    lv_status          VARCHAR2(1000);  -- 4.ステータス
    lv_customer_cd     VARCHAR2(1000);  -- 5.顧客コード
    lv_kbn             VARCHAR2(1000);  -- 6.判定区分
    lv_csv_header      VARCHAR2(5000);  -- CSVヘッダ項目出力用
--
    lv_status_name     VARCHAR2(30);    -- SP専決ステータス名
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
    --入力パラメータをグローバル変数に格納
    --==============================================================
    gt_base_code   := iv_base_code;
    gd_date_from   := TO_DATE( iv_app_date_from , cv_format_fmt1 );
    gd_date_to     := TO_DATE( iv_app_date_to   , cv_format_fmt1 );
    gt_status      := iv_status;
    gt_customer_cd := iv_customer_cd;
    gv_kbn         := iv_kbn;
    --==============================================================
    --ローカル変数を初期化
    --==============================================================
    lv_base_code     := NULL;
    lv_app_date_from := NULL;
    lv_app_date_to   := NULL;
    lv_status        := NULL;
    lv_customer_cd   := NULL;
    lv_kbn           := NULL;
    lv_csv_header    := NULL;
    lv_status_name   := NULL;
--
    --==================================================
    -- 業務日付取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date ;
    -- 業務日付の取得に失敗した場合はエラー
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00011
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- SP専決ステータス名を取得
    --==================================================
    IF ( gt_status IS NOT NULL ) THEN
      BEGIN
        SELECT flvv.meaning AS status_name  -- SP専決ステータス名
        INTO   lv_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type  = cv_lookup_type_01  -- SP専決ステータス
        AND    flvv.enabled_flag = cv_flag_y
        AND    gd_process_date  >= NVL(flvv.start_date_active, gd_process_date)
        AND    gd_process_date  <= NVL(flvv.end_date_active  , gd_process_date)
        AND    flvv.lookup_code  = gt_status
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_status_name := NULL;
      END;
--
      -- コロンを追加
      IF ( lv_status_name IS NOT NULL ) THEN
        lv_status_name := cv_colon || lv_status_name;
      END IF;
    END IF;
--
    --==================================================
    --入力パラメータをメッセージ出力
    --==================================================
    -- 売上(申請)拠点
    IF ( gv_kbn = cv_cust_class_1 ) THEN
      -- 申請拠点
      lv_base_code   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_val_00725              -- トークン値1
                         ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                         ,iv_token_value2 => iv_base_code                  -- トークン値2
                        );
    ELSE
      -- 売上拠点
      lv_base_code   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_val_00697              -- トークン値1
                         ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                         ,iv_token_value2 => iv_base_code                  -- トークン値2
                        );
    END IF;
    -- 申請日(FROM)
    lv_app_date_from := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_00726              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_app_date_from              -- トークン値2
                      );
    -- 申請日(TO)
    lv_app_date_to := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_00727              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_app_date_to                -- トークン値2
                      );
    -- ステータス
      lv_status      := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                         ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                         ,iv_token_value1 => cv_tkn_val_00728              -- トークン値1
                         ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                         ,iv_token_value2 => iv_status                     -- トークン値2
                        ) || lv_status_name
                        ;
    -- 顧客コード
    lv_customer_cd := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_00707              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_customer_cd                -- トークン値2
                      );
    -- 判定区分
    lv_kbn         := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                       ,iv_name         => cv_msg_cso_00671              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_param_name             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_00729              -- トークン値1
                       ,iv_token_name2  => cv_tkn_param_value            -- トークンコード2
                       ,iv_token_value2 => iv_kbn                        -- トークン値2
                      );
--
    -- ログに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''               || CHR(10) ||
                 lv_base_code     || CHR(10) ||      -- 1.申請(売上)拠点
                 lv_app_date_from || CHR(10) ||      -- 2.申請日(FROM)
                 lv_app_date_to   || CHR(10) ||      -- 3.申請日(TO)
                 lv_status        || CHR(10) ||      -- 4.ステータス
                 lv_customer_cd   || CHR(10) ||      -- 5.顧客コード
                 lv_kbn                              -- 6.判定区分
    );
--
    --==================================================
    -- 日付逆転チェック
    --==================================================
    -- 申請日(TO)と申請日(TO)の比較
    IF ( gd_date_from > gd_date_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00644
         ,iv_token_name1  => cv_tkn_date_from
         ,iv_token_value1 => cv_tkn_val_00726
         ,iv_token_name2  => cv_tkn_date_to
         ,iv_token_value2 => cv_tkn_val_00727
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    --==================================================
    -- CSVヘッダ項目出力
    --==================================================
    lv_csv_header := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00723
                     ) ||
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00724
                     )
                     ;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
  EXCEPTION
    -- *** エラー終了 ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################--
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
   * Procedure Name   : output_sp_data
   * Description      : SP専決書情報取得・出力(A-2,A-3)
   ***********************************************************************************/
  PROCEDURE output_sp_data(
    ov_errbuf          OUT NOCOPY VARCHAR2      -- エラー・メッセージ                  --# 固定 #
   ,ov_retcode         OUT NOCOPY VARCHAR2      -- リターン・コード                    --# 固定 #
   ,ov_errmsg          OUT NOCOPY VARCHAR2      -- ユーザー・エラー・メッセージ        --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_sp_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_output_str                     VARCHAR2(5000);-- 出力文字列格納用変数
    -- 項目編集用変数
    lv_status                         VARCHAR2(100); -- ステータス
    lv_application_type               VARCHAR2(100); -- 申請区分
    lv_application_code               VARCHAR2(360); -- 申請者
    lv_app_base_code                  VARCHAR2(100); -- 申請拠点
    lv_business_low_type              VARCHAR2(100); -- 業態（小分類）
    lv_business_type                  VARCHAR2(100); -- 業種
    lv_install_location               VARCHAR2(100); -- 設置場所
    lv_open_close_div                 VARCHAR2(100); -- オープン/クローズ
    lv_sale_base_code                 VARCHAR2(100); -- 担当拠点
    lv_customer_status                VARCHAR2(200); -- 顧客ステータス
    lv_newold_type                    VARCHAR2(100); -- 新台旧台区分
    lv_standard_type                  VARCHAR2(100); -- 規格内外区分
    lv_condition_business_type        VARCHAR2(100); -- 取引条件区分
    lv_all_container_type             VARCHAR2(100); -- 全容器区分
    lv_contract_period                VARCHAR2(100); -- 契約期間
    lv_bidding_item                   VARCHAR2(100); -- 入札案件
    lv_cancell_before_maturity        VARCHAR2(100); -- 中途解約条項
    lv_ad_assets_type                 VARCHAR2(100); -- 行政財産使用料
    lv_tax_type                       VARCHAR2(100); -- 覚書情報税区分
    lv_install_supp_type              VARCHAR2(100); -- 設置協賛金
    lv_install_supp_payment_type      VARCHAR2(100); -- 設置協賛金区分
    lv_electricity_type               VARCHAR2(100); -- 電気代
    lv_electric_payment_type          VARCHAR2(100); -- 電気代契約先
    lv_electric_pay_change_type       VARCHAR2(100); -- 電気代区分
    lv_electricity_change_type        VARCHAR2(100); -- 電気代変動区分
    lv_electric_payment_cycle         VARCHAR2(100); -- 電気代支払サイクル
    lv_electric_trans_date            VARCHAR2(100); -- 電気代振込日
    lv_intro_chg_type                 VARCHAR2(100); -- 紹介手数料
    lv_cust_cointro_chg_pay_type      VARCHAR2(100); -- 紹介手数料区分
    lv_intro_chg_trans_date           VARCHAR2(100); -- 紹介手数料振込日
    lv_bm1_bank_charge_bearer         VARCHAR2(100); -- BM1振込手数料負担
    lv_bm1_bm_payment_type            VARCHAR2(100); -- BM1支払方法・明細書
    lv_bm2_bank_charge_bearer         VARCHAR2(100); -- BM2振込手数料負担
    lv_bm2_bm_payment_type            VARCHAR2(100); -- BM2支払方法・明細書
    lv_bm3_bank_charge_bearer         VARCHAR2(100); -- BM3振込手数料負担
    lv_bm3_bm_payment_type            VARCHAR2(100); -- BM3支払方法・明細書
    lv_approve_10                     VARCHAR2(300); -- 回送先・確認者
    lv_approve_20                     VARCHAR2(300); -- 回送先・承認者
    lv_approve_30                     VARCHAR2(300); -- 回送先・地区営業管理課長
    lv_approve_40                     VARCHAR2(300); -- 回送先・地区営業部長
    lv_approve_50                     VARCHAR2(300); -- 回送先・関係先
    lv_approve_60                     VARCHAR2(300); -- 回送先・自販機部課長
    lv_approve_70                     VARCHAR2(300); -- 回送先・自販機部長
    lv_approve_80                     VARCHAR2(300); -- 回送先・拠点管理部長
    lv_approve_90                     VARCHAR2(300); -- 回送先・営業本部長
--
    -- 参照タイプ取得値格納用変数
    lv_status_name                    VARCHAR2(100); -- ステータス名
    lv_application_type_name          VARCHAR2(100); -- 申請区分名
    lv_application_code_name          VARCHAR2(360); -- 申請者名
    lv_app_base_code_name             VARCHAR2(100); -- 申請拠点名
    lv_business_low_type_name         VARCHAR2(100); -- 業態（小分類）名
    lv_business_type_name             VARCHAR2(100); -- 業種名
    lv_install_location_name          VARCHAR2(100); -- 設置場所名
    lv_open_close_div_name            VARCHAR2(100); -- オープン/クローズ名
    lv_sale_base_code_name            VARCHAR2(100); -- 担当拠点名
    lv_customer_status_name           VARCHAR2(200); -- 顧客ステータス名
    lv_newold_type_name               VARCHAR2(100); -- 新台旧台区分名
    lv_standard_type_name             VARCHAR2(100); -- 規格内外区分名
    lv_condition_business_tp_name     VARCHAR2(100); -- 取引条件区分名
    lv_all_container_type_name        VARCHAR2(100); -- 全容器区分名
    lv_bidding_item_name              VARCHAR2(100); -- 入札案件名
    lv_cancell_before_matur_name      VARCHAR2(100); -- 中途解約条項名
    lv_ad_assets_type_name            VARCHAR2(100); -- 行政財産使用料名
    lv_tax_type_name                  VARCHAR2(100); -- 覚書情報税区分名
    lv_install_supp_type_name         VARCHAR2(100); -- 設置協賛金名
    lv_install_supp_pay_type_name     VARCHAR2(100); -- 設置協賛金区分名
    lv_electric_pay_type_name         VARCHAR2(100); -- 電気代契約先名
    lv_electric_pay_change_tp_name    VARCHAR2(100); -- 電気代区分名
    lv_electricity_change_tp_name     VARCHAR2(100); -- 電気代変動区分名
    lv_electric_pay_cycle_name        VARCHAR2(100); -- 電気代支払サイクル名
    lv_electric_trans_date_name       VARCHAR2(100); -- 電気代振込日名
    lv_intro_chg_type_name            VARCHAR2(100); -- 紹介手数料名
    lv_cust_intro_chg_pay_tp_name     VARCHAR2(100); -- 紹介手数料区分名
    lv_intro_chg_trans_date_name      VARCHAR2(100); -- 紹介手数料振込日名
    lv_bm1_bank_charge_bearer_name    VARCHAR2(100); -- BM1振込手数料負担名
    lv_bm1_bm_payment_type_name       VARCHAR2(100); -- BM1支払方法・明細書名
    lv_bm2_bank_charge_bearer_name    VARCHAR2(100); -- BM2振込手数料負担名
    lv_bm2_bm_payment_type_name       VARCHAR2(100); -- BM2支払方法・明細書名
    lv_bm3_bank_charge_bearer_name    VARCHAR2(100); -- BM3振込手数料負担名
    lv_bm3_bm_payment_type_name       VARCHAR2(100); -- BM3支払方法・明細書名
    lv_work_request_type_name_10      VARCHAR2(100); -- 作業依頼区分名(確認者)
    lv_approval_state_type_name_10    VARCHAR2(100); -- 決裁状態区分(確認者)
    lv_approval_content_name_10       VARCHAR2(100); -- 決裁内容(確認者)
    lv_work_request_type_name_20      VARCHAR2(100); -- 作業依頼区分名(承認者)
    lv_approval_state_type_name_20    VARCHAR2(100); -- 決裁状態区分(承認者)
    lv_approval_content_name_20       VARCHAR2(100); -- 決裁内容(承認者)
    lv_work_request_type_name_30      VARCHAR2(100); -- 作業依頼区分名(地区営業管理課長)
    lv_approval_state_type_name_30    VARCHAR2(100); -- 決裁状態区分(地区営業管理課長)
    lv_approval_content_name_30       VARCHAR2(100); -- 決裁内容(地区営業管理課長)
    lv_work_request_type_name_40      VARCHAR2(100); -- 作業依頼区分名(地区営業部長)
    lv_approval_state_type_name_40    VARCHAR2(100); -- 決裁状態区分(地区営業部長)
    lv_approval_content_name_40       VARCHAR2(100); -- 決裁内容(地区営業部長)
    lv_work_request_type_name_50      VARCHAR2(100); -- 作業依頼区分名(関係先)
    lv_approval_state_type_name_50    VARCHAR2(100); -- 決裁状態区分(関係先)
    lv_approval_content_name_50       VARCHAR2(100); -- 決裁内容(関係先)
    lv_work_request_type_name_60      VARCHAR2(100); -- 作業依頼区分名(自販機部課長)
    lv_approval_state_type_name_60    VARCHAR2(100); -- 決裁状態区分(自販機部課長)
    lv_approval_content_name_60       VARCHAR2(100); -- 決裁内容(自販機部課長)
    lv_work_request_type_name_70      VARCHAR2(100); -- 作業依頼区分名(自販機部長)
    lv_approval_state_type_name_70    VARCHAR2(100); -- 決裁状態区分(自販機部長)
    lv_approval_content_name_70       VARCHAR2(100); -- 決裁内容(自販機部長)
    lv_work_request_type_name_80      VARCHAR2(100); -- 作業依頼区分名(拠点管理部長)
    lv_approval_state_type_name_80    VARCHAR2(100); -- 決裁状態区分(拠点管理部長)
    lv_approval_content_name_80       VARCHAR2(100); -- 決裁内容(拠点管理部長)
    lv_work_request_type_name_90      VARCHAR2(100); -- 作業依頼区分名(営業本部長)
    lv_approval_state_type_name_90    VARCHAR2(100); -- 決裁状態区分(営業本部長)
    lv_approval_content_name_90       VARCHAR2(100); -- 決裁内容(営業本部長)
--
    lv_year                           VARCHAR2(2);   -- 文字列:年
    lv_month                          VARCHAR2(2);   -- 文字列:月
    lv_day                            VARCHAR2(2);   -- 文字列:日
    lv_ari                            VARCHAR2(2);   -- 文字列:有
    lv_nashi                          VARCHAR2(2);   -- 文字列:無
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 出力用のメッセージを取得
    -- 文字列：年
    lv_year := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00731              -- メッセージコード
                        );
    -- 文字列：月
    lv_month := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00732              -- メッセージコード
                        );
    -- 文字列：日
    lv_day  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00733              -- メッセージコード
                        );
    -- 文字列：有
    lv_ari  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00734              -- メッセージコード
                        );
    -- 文字列：無
    lv_nashi := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcso            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00735              -- メッセージコード
                        );
--
    --SP専決書情報カーソルループ
    << sp_loop >>
    FOR get_sp_rec IN get_sp_cur
    LOOP
      -- 変数初期化
      lv_output_str                   := NULL; -- 出力文字列格納用変数
      lv_status                       := NULL; -- SP専決ステータス
      lv_application_type             := NULL; -- 申請区分
      lv_application_code             := NULL; -- 申請者
      lv_app_base_code                := NULL; -- 申請拠点
      lv_business_low_type            := NULL; -- 業態（小分類）
      lv_business_type                := NULL; -- 業種
      lv_install_location             := NULL; -- 設置場所
      lv_open_close_div               := NULL; -- オープン/クローズ
      lv_sale_base_code               := NULL; -- 担当拠点
      lv_customer_status              := NULL; -- 顧客ステータス
      lv_newold_type                  := NULL; -- 新台旧台区分
      lv_standard_type                := NULL; -- 規格内外区分
      lv_condition_business_type      := NULL; -- 取引条件区分
      lv_all_container_type           := NULL; -- 全容器区分
      lv_contract_period              := NULL; -- 契約期間
      lv_bidding_item                 := NULL; -- 入札案件
      lv_cancell_before_maturity      := NULL; -- 中途解約条項
      lv_ad_assets_type               := NULL; -- 行政財産使用料
      lv_tax_type                     := NULL; -- 覚書情報税区分
      lv_install_supp_type            := NULL; -- 設置協賛金
      lv_install_supp_payment_type    := NULL; -- 設置協賛金区分
      lv_electricity_type             := NULL; -- 電気代
      lv_electric_payment_type        := NULL; -- 電気代契約先
      lv_electric_pay_change_type     := NULL; -- 電気代区分
      lv_electricity_change_type      := NULL; -- 電気代変動区分
      lv_electric_payment_cycle       := NULL; -- 電気代支払サイクル
      lv_electric_trans_date          := NULL; -- 電気代振込日
      lv_intro_chg_type               := NULL; -- 紹介手数料
      lv_cust_cointro_chg_pay_type    := NULL; -- 紹介手数料区分
      lv_intro_chg_trans_date         := NULL; -- 紹介手数料振込日
      lv_bm1_bank_charge_bearer       := NULL; -- BM1振込手数料負担
      lv_bm1_bm_payment_type          := NULL; -- BM1支払方法・明細書
      lv_bm2_bank_charge_bearer       := NULL; -- BM2振込手数料負担
      lv_bm2_bm_payment_type          := NULL; -- BM2支払方法・明細書
      lv_bm3_bank_charge_bearer       := NULL; -- BM3振込手数料負担
      lv_bm3_bm_payment_type          := NULL; -- BM3支払方法・明細書
      lv_approve_10                   := NULL; -- 回送先・確認者
      lv_approve_20                   := NULL; -- 回送先・承認者
      lv_approve_30                   := NULL; -- 回送先・地区営業管理課長
      lv_approve_40                   := NULL; -- 回送先・地区営業部長
      lv_approve_50                   := NULL; -- 回送先・関係先
      lv_approve_60                   := NULL; -- 回送先・自販機部課長
      lv_approve_70                   := NULL; -- 回送先・自販機部長
      lv_approve_80                   := NULL; -- 回送先・拠点管理部長
      lv_approve_90                   := NULL; -- 回送先・営業本部長
--
      lv_status_name                  := NULL; -- SP専決ステータス名
      lv_application_type_name        := NULL; -- 申請区分名
      lv_application_code_name        := NULL; -- 申請者名
      lv_app_base_code_name           := NULL; -- 申請拠点名
      lv_business_low_type_name       := NULL; -- 業態（小分類）名
      lv_business_type_name           := NULL; -- 業種名
      lv_install_location_name        := NULL; -- 設置場所名
      lv_open_close_div_name          := NULL; -- オープン/クローズ区分名
      lv_sale_base_code_name          := NULL; -- 担当拠点名
      lv_customer_status_name         := NULL; -- 顧客ステータス名
      lv_newold_type_name             := NULL; -- 新台旧台区分名
      lv_standard_type_name           := NULL; -- 規格内外区分名
      lv_condition_business_tp_name   := NULL; -- 取引条件区分名
      lv_all_container_type_name      := NULL; -- 全容器区分名
      lv_bidding_item_name            := NULL; -- 入札案件区分名
      lv_cancell_before_matur_name    := NULL; -- 中途解約条項有無
      lv_ad_assets_type_name          := NULL; -- 行政財産使用料有無
      lv_tax_type_name                := NULL; -- 覚書情報税区分名
      lv_install_supp_type_name       := NULL; -- 設置協賛金有無
      lv_install_supp_pay_type_name   := NULL; -- 設置協賛金区分名
      lv_electric_pay_type_name       := NULL; -- 電気代契約先区分名
      lv_electric_pay_change_tp_name  := NULL; -- 電気代区分名
      lv_electricity_change_tp_name   := NULL; -- 電気代変動区分名
      lv_electric_pay_cycle_name      := NULL; -- 電気代支払サイクル名
      lv_electric_trans_date_name     := NULL; -- 電気代振込日タイプ
      lv_intro_chg_type_name          := NULL; -- 紹介手数料有無
      lv_cust_intro_chg_pay_tp_name   := NULL; -- 紹介手数料区分名
      lv_intro_chg_trans_date_name    := NULL; -- 紹介手数料振込日タイプ
      lv_bm1_bank_charge_bearer_name  := NULL; -- BM1振込手数料負担名
      lv_bm1_bm_payment_type_name     := NULL; -- BM1支払方法・明細書名
      lv_bm2_bank_charge_bearer_name  := NULL; -- BM2振込手数料負担名
      lv_bm2_bm_payment_type_name     := NULL; -- BM2支払方法・明細書名
      lv_bm3_bank_charge_bearer_name  := NULL; -- BM3振込手数料負担名
      lv_bm3_bm_payment_type_name     := NULL; -- BM3支払方法・明細書名
      lv_work_request_type_name_10    := NULL; -- 作業依頼区分名(確認者)
      lv_approval_state_type_name_10  := NULL; -- 決裁状態区分名(確認者)
      lv_approval_content_name_10     := NULL; -- 決裁内容名(確認者)
      lv_work_request_type_name_20    := NULL; -- 作業依頼区分名(承認者)
      lv_approval_state_type_name_20  := NULL; -- 決裁状態区分名(承認者)
      lv_approval_content_name_20     := NULL; -- 決裁内容名(承認者)
      lv_work_request_type_name_30    := NULL; -- 作業依頼区分名(地区営業管理課長)
      lv_approval_state_type_name_30  := NULL; -- 決裁状態区分名(地区営業管理課長)
      lv_approval_content_name_30     := NULL; -- 決裁内容名(地区営業管理課長)
      lv_work_request_type_name_40    := NULL; -- 作業依頼区分名(地区営業部長)
      lv_approval_state_type_name_40  := NULL; -- 決裁状態区分名(地区営業部長)
      lv_approval_content_name_40     := NULL; -- 決裁内容名(地区営業部長)
      lv_work_request_type_name_50    := NULL; -- 作業依頼区分名(関係先)
      lv_approval_state_type_name_50  := NULL; -- 決裁状態区分名(関係先)
      lv_approval_content_name_50     := NULL; -- 決裁内容名(関係先)
      lv_work_request_type_name_60    := NULL; -- 作業依頼区分名(自販機部課長)
      lv_approval_state_type_name_60  := NULL; -- 決裁状態区分名(自販機部課長)
      lv_approval_content_name_60     := NULL; -- 決裁内容名(自販機部課長)
      lv_work_request_type_name_70    := NULL; -- 作業依頼区分名(自販機部長)
      lv_approval_state_type_name_70  := NULL; -- 決裁状態区分名(自販機部長)
      lv_approval_content_name_70     := NULL; -- 決裁内容名(自販機部長)
      lv_work_request_type_name_80    := NULL; -- 作業依頼区分名(拠点管理部長)
      lv_approval_state_type_name_80  := NULL; -- 決裁状態区分名(拠点管理部長)
      lv_approval_content_name_80     := NULL; -- 決裁内容名(拠点管理部長)
      lv_work_request_type_name_90    := NULL; -- 作業依頼区分名(営業本部長)
      lv_approval_state_type_name_90  := NULL; -- 決裁状態区分名(営業本部長)
      lv_approval_content_name_90     := NULL; -- 決裁内容名(営業本部長)
--
      -- ===============================
      -- 参照タイプより項目名称を取得
      -- ===============================
      -- SP専決ステータス名
      BEGIN
        SELECT meaning AS status_name
        INTO   lv_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_01
        AND    flvv.lookup_code = get_sp_rec.status
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_status_name := NULL;
      END;
--
      -- 申請区分名
      BEGIN
        SELECT meaning AS application_type_name
        INTO   lv_application_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_02
        AND    flvv.lookup_code = get_sp_rec.application_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_application_type_name := NULL;
      END;
--
      -- 申請者名
      BEGIN
        SELECT full_name AS full_name
        INTO   lv_application_code_name
        FROM   xxcso_employees_v2 xev2
        WHERE  xev2.user_name = get_sp_rec.application_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_application_code_name := NULL;
      END;
--
      -- 申請拠点名
      BEGIN
        SELECT location_name AS location_name
        INTO   lv_app_base_code_name
        FROM   xxcso_locations_v2 xlv2
        WHERE  xlv2.dept_code = get_sp_rec.app_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_app_base_code_name := NULL;
      END;
--
      -- 業態（小分類）名
      BEGIN
        SELECT meaning AS business_low_type_name
        INTO   lv_business_low_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_03
        AND    flvv.lookup_code = get_sp_rec.business_low_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_business_low_type_name := NULL;
      END;
--
      -- 業種名
      BEGIN
        SELECT meaning AS business_type_name
        INTO   lv_business_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_04
        AND    flvv.lookup_code = get_sp_rec.business_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_business_type_name := NULL;
      END;
--
      -- 設置場所名
      BEGIN
        SELECT meaning AS install_location_name
        INTO   lv_install_location_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_05
        AND    flvv.lookup_code = get_sp_rec.install_location
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_location_name := NULL;
      END;
--
      -- オープン/クローズ区分名
      BEGIN
        SELECT meaning AS open_close_div
        INTO   lv_open_close_div_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_06
        AND    flvv.lookup_code = get_sp_rec.open_close_div
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_open_close_div_name := NULL;
      END;
--
      -- 担当拠点名
      BEGIN
        SELECT location_name AS sale_base_code_name
        INTO   lv_sale_base_code_name
        FROM   xxcso_locations_v2 xlv2
        WHERE  xlv2.dept_code = get_sp_rec.sale_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_sale_base_code_name := NULL;
      END;
--
      -- 顧客ステータス名
      BEGIN
        SELECT meaning AS customer_status_name
        INTO   lv_customer_status_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_07
        AND    flvv.lookup_code = get_sp_rec.customer_status
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date) 
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_customer_status_name := NULL;
      END;
--
      -- 新台旧台区分名
      BEGIN
        SELECT meaning AS newold_type_name
        INTO   lv_newold_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_08
        AND    flvv.lookup_code = get_sp_rec.newold_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_newold_type_name := NULL;
      END;
--
      -- 規格内外区分名
      BEGIN
        SELECT meaning AS standard_type_name
        INTO   lv_standard_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_09
        AND    flvv.lookup_code = get_sp_rec.standard_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_standard_type_name := NULL;
      END;
--
      -- 取引条件区分名
      BEGIN
        SELECT meaning AS condition_business_type_name
        INTO   lv_condition_business_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_10
        AND    flvv.lookup_code = get_sp_rec.condition_business_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_condition_business_tp_name := NULL;
      END;
--
      -- 全容器区分名
      BEGIN
        SELECT meaning AS all_container_type_name
        INTO   lv_all_container_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_11
        AND    flvv.lookup_code = get_sp_rec.all_container_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_all_container_type_name := NULL;
      END;
--
      -- 入札案件区分名
      BEGIN
        SELECT meaning AS bidding_item_name
        INTO   lv_bidding_item_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_12
        AND    flvv.lookup_code = get_sp_rec.bidding_item
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bidding_item_name := NULL;
      END;
--
      -- 中途解約条項有無
      BEGIN
        SELECT meaning AS cancell_before_maturity_name
        INTO   lv_cancell_before_matur_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.cancell_before_maturity
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_cancell_before_matur_name := NULL;
      END;
--
      -- 行政財産使用料有無
      BEGIN
        SELECT meaning AS ad_assets_type_name
        INTO   lv_ad_assets_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.ad_assets_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_ad_assets_type_name := NULL;
      END;
--
      -- 覚書情報税区分名
      BEGIN
        SELECT meaning AS tax_type_name
        INTO   lv_tax_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_14
        AND    flvv.lookup_code = get_sp_rec.tax_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tax_type_name := NULL;
      END;
--
      -- 設置協賛金有無
      BEGIN
        SELECT meaning AS install_supp_type_name
        INTO   lv_install_supp_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.install_supp_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_supp_type_name := NULL;
      END;
--
      -- 設置協賛金区分名
      BEGIN
        SELECT meaning AS install_supp_payment_type_name
        INTO   lv_install_supp_pay_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_15
        AND    flvv.lookup_code = get_sp_rec.install_supp_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_install_supp_pay_type_name := NULL;
      END;
--
      -- 電気代契約先区分名
      BEGIN
        SELECT meaning AS electric_payment_type_name
        INTO   lv_electric_pay_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_17
        AND    flvv.lookup_code = get_sp_rec.electric_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_type_name := NULL;
      END;
--
      -- 電気代区分名
      BEGIN
        SELECT meaning AS electric_change_type_name
        INTO   lv_electric_pay_change_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_18
        AND    flvv.lookup_code = get_sp_rec.electric_payment_change_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(start_date_active),gd_process_date)
                   AND NVL(TRUNC(end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_change_tp_name := NULL;
      END;
--
      -- 電気代変動区分名
      BEGIN
        SELECT meaning AS electricity_change_type_name
        INTO   lv_electricity_change_tp_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_19
        AND    flvv.lookup_code = get_sp_rec.electricity_change_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electricity_change_tp_name := NULL;
      END;
--
      -- 電気代支払サイクル名
      BEGIN
        SELECT meaning AS electric_payment_cycle_name
        INTO   lv_electric_pay_cycle_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_20
        AND    flvv.lookup_code = get_sp_rec.electric_payment_cycle
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_pay_cycle_name := NULL;
      END;
--
      -- 電気代振込日タイプ
      BEGIN
        SELECT meaning AS electric_trans_date_name
        INTO   lv_electric_trans_date_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_21
        AND    flvv.lookup_code = get_sp_rec.electric_trans_month
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_electric_trans_date_name := NULL;
      END;
--
      -- 紹介手数料有無
      BEGIN
        SELECT meaning AS intro_chg_type_name
        INTO   lv_intro_chg_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_13
        AND    flvv.lookup_code = get_sp_rec.intro_chg_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_intro_chg_type_name := NULL;
      END;
--
      -- 紹介手数料区分名
      BEGIN
       SELECT meaning AS cust_payment_type_name
       INTO   lv_cust_intro_chg_pay_tp_name
       FROM   fnd_lookup_values_vl flvv
       WHERE  flvv.lookup_type = cv_lookup_type_22
       AND    flvv.lookup_code = get_sp_rec.cust_cointro_chg_payment_type
       AND    flvv.enabled_flag  = cv_flag_y
       AND    gd_process_date
              BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                  AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_cust_intro_chg_pay_tp_name := NULL;
      END;
--
      -- 紹介手数料振込日タイプ
      BEGIN
        SELECT meaning AS intro_chg_trans_date_name
        INTO   lv_intro_chg_trans_date_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_21
        AND    flvv.lookup_code = get_sp_rec.intro_chg_trans_month
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_intro_chg_trans_date_name := NULL;
      END;
--
      -- BM1振込手数料負担名
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm1_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm1_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_bank_charge_bearer_name := NULL;
      END;
--
      -- BM1支払方法・明細書名
      BEGIN
        SELECT meaning AS bm1_bm_payment_type
        INTO   lv_bm1_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm1_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm1_bm_payment_type_name := NULL;
      END;
--
      -- BM2振込手数料負担名
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm2_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm2_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm2_bank_charge_bearer_name := NULL;
      END;
--
      -- BM2支払方法・明細書名
      BEGIN
        SELECT meaning AS bm2_bm_payment_type
        INTO   lv_bm2_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm2_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm2_bm_payment_type_name := NULL;
      END;
--
      -- BM3振込手数料負担名
      BEGIN
        SELECT meaning AS bm1_bank_charge_bearer
        INTO   lv_bm3_bank_charge_bearer_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_23
        AND    flvv.lookup_code = get_sp_rec.bm3_bank_charge_bearer
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm3_bank_charge_bearer_name := NULL;
      END;
--
      -- BM3支払方法・明細書名
      BEGIN
        SELECT meaning AS bm3_bm_payment_type
        INTO   lv_bm3_bm_payment_type_name
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_24
        AND    flvv.lookup_code = get_sp_rec.bm3_bm_payment_type
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bm3_bm_payment_type_name := NULL;
      END;
--
      -- 作業依頼区分名(確認者)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_10 := NULL;
      END;
--
      -- 決裁状態区分名(確認者)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_10 := NULL;
      END;
--
      -- 決裁内容名(確認者)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_10
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_10
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_10 := NULL;
      END;
--
      -- 作業依頼区分名(承認者)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_20 := NULL;
      END;
--
      -- 決裁状態区分名(承認者)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_20 := NULL;
      END;
--
      -- 決裁内容名(承認者)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_20
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_20
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_20 := NULL;
      END;
--
      -- 作業依頼区分名(地区営業管理課長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_30 := NULL;
      END;
--
      -- 決裁状態区分名(地区営業管理課長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_30 := NULL;
      END;
--
      -- 決裁内容名(地区営業管理課長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_30
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_30
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_30 := NULL;
      END;
--
      -- 作業依頼区分名(地区営業部長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_40 := NULL;
      END;
--
      -- 決裁状態区分名(地区営業部長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_40 := NULL;
      END;
--
      -- 決裁内容名(地区営業部長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_40
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_40
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_40 := NULL;
      END;
--
      -- 作業依頼区分名(関係先)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_50 := NULL;
      END;
--
      -- 決裁状態区分名(関係先)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_50 := NULL;
      END;
--
      -- 決裁内容名(関係先)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_50
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_50
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_50 := NULL;
      END;
--
      -- 作業依頼区分名(自販機部課長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_60 := NULL;
      END;
--
      -- 決裁状態区分名(自販機部課長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_60 := NULL;
      END;
--
      -- 決裁内容名(自販機部課長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_60
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_60
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_60 := NULL;
      END;
--
      -- 作業依頼区分名(自販機部長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_70 := NULL;
      END;
--
      -- 決裁状態区分名(自販機部長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_70 := NULL;
      END;
--
      -- 決裁内容名(自販機部長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_70
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_70
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_70 := NULL;
      END;
--
      -- 作業依頼区分名(拠点管理部長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_80 := NULL;
      END;
--
      -- 決裁状態区分名(拠点管理部長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_80 := NULL;
      END;
--
      -- 決裁内容名(拠点管理部長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_80
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_80
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_80 := NULL;
      END;
--
      -- 作業依頼区分名(営業本部長)
      BEGIN
        SELECT meaning AS work_request_type_name
        INTO   lv_work_request_type_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_25
        AND    flvv.lookup_code = get_sp_rec.work_request_type_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_work_request_type_name_90 := NULL;
      END;
--
      -- 決裁状態区分名(営業本部長)
      BEGIN
        SELECT meaning AS approval_state_type_name
        INTO   lv_approval_state_type_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_26
        AND    flvv.lookup_code = get_sp_rec.approval_state_type_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_state_type_name_90 := NULL;
      END;
--
      -- 決裁内容名(営業本部長)
      BEGIN
        SELECT meaning AS approval_content_name
        INTO   lv_approval_content_name_90
        FROM   fnd_lookup_values_vl flvv
        WHERE  flvv.lookup_type = cv_lookup_type_27
        AND    flvv.lookup_code = get_sp_rec.approval_content_90
        AND    flvv.enabled_flag  = cv_flag_y
        AND    gd_process_date 
               BETWEEN NVL(TRUNC(flvv.start_date_active),gd_process_date)
                   AND NVL(TRUNC(flvv.end_date_active),gd_process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_approval_content_name_90 := NULL;
      END;
--
      -- ===============================
      -- 項目を編集
      -- ===============================
      -- SP専決ステータス
      IF ( get_sp_rec.status IS NOT NULL ) THEN
        lv_status 
          := get_sp_rec.status 
             || cv_colon
             || lv_status_name;
      END IF;
--      
      -- 申請区分
      IF ( get_sp_rec.application_type IS NOT NULL ) THEN
        lv_application_type
          := get_sp_rec.application_type
             || cv_colon
             || lv_application_type_name;
      END IF;
--
      -- 申請者
      IF ( get_sp_rec.application_code IS NOT NULL ) THEN
        lv_application_code
          := get_sp_rec.application_code
             || ' '
             || lv_application_code_name;
      END IF;
--
      -- 申請拠点
      IF ( get_sp_rec.app_base_code IS NOT NULL ) THEN
        lv_app_base_code
          := get_sp_rec.app_base_code
             || ' '
             || lv_app_base_code_name;
      END IF;
--
      -- 業態（小分類）
      IF ( get_sp_rec.business_low_type IS NOT NULL ) THEN
        lv_business_low_type
          := get_sp_rec.business_low_type
             || ' '
             || lv_business_low_type_name;
      END IF;
--
      -- 業種
      IF ( get_sp_rec.business_type IS NOT NULL ) THEN
        lv_business_type
          := get_sp_rec.business_type
             || ' '
             || lv_business_type_name;
      END IF;
--
      -- 設置場所
      IF ( get_sp_rec.install_location IS NOT NULL ) THEN
        lv_install_location
          := get_sp_rec.install_location
             || ' '
             || lv_install_location_name;
      END IF;
--
      -- オープン/クローズ
      IF ( get_sp_rec.open_close_div IS NOT NULL ) THEN
        lv_open_close_div
          := get_sp_rec.open_close_div
             || ' '
             || lv_open_close_div_name;
      END IF;
--
      -- 担当拠点
      IF ( get_sp_rec.sale_base_code IS NOT NULL ) THEN
        lv_sale_base_code
          := get_sp_rec.sale_base_code
              || ' '
              || lv_sale_base_code_name;
      END IF;
--
      -- 顧客ステータス
      IF ( get_sp_rec.customer_status IS NOT NULL ) THEN
        lv_customer_status
          := get_sp_rec.customer_status
             || cv_colon
             || lv_customer_status_name;
      END IF;
--
      -- 新台旧台区分
      IF ( get_sp_rec.newold_type IS NOT NULL ) THEN
        lv_newold_type
          := get_sp_rec.newold_type
             || cv_colon
             || lv_newold_type_name;
      END IF;
--
      -- 規格内外区分
      IF ( get_sp_rec.standard_type IS NOT NULL ) THEN
        lv_standard_type
          := get_sp_rec.standard_type
             || cv_colon
             || lv_standard_type_name;
      END IF;
--
      -- 取引条件区分
      IF ( get_sp_rec.condition_business_type IS NOT NULL ) THEN
        lv_condition_business_type
          := get_sp_rec.condition_business_type
             || cv_colon
             || lv_condition_business_tp_name;
      END IF;
--
      -- 全容器区分
      IF ( get_sp_rec.all_container_type IS NOT NULL ) THEN
        lv_all_container_type
          := get_sp_rec.all_container_type
             || cv_colon
             || lv_all_container_type_name;
      END IF;
--
      -- 契約期間
      IF ( get_sp_rec.contract_start_year IS NOT NULL ) THEN
        lv_contract_period
          := get_sp_rec.contract_start_year
             || lv_year
             || get_sp_rec.contract_start_month
             || lv_month || cv_prt_line
             || get_sp_rec.contract_end_year 
             || lv_year
             || get_sp_rec.contract_end_month
             || lv_month;
      END IF;
--
      -- 入札案件
      IF ( get_sp_rec.bidding_item IS NOT NULL ) THEN
        lv_bidding_item
          := get_sp_rec.bidding_item
             || cv_colon
             || lv_bidding_item_name;
      END IF;
--
      -- 中途解約条項
      IF ( get_sp_rec.cancell_before_maturity IS NOT NULL ) THEN
        lv_cancell_before_maturity
          := get_sp_rec.cancell_before_maturity
             || cv_colon
             || lv_cancell_before_matur_name;
      END IF;
--
      -- 行政財産使用料
      IF ( get_sp_rec.ad_assets_type IS NOT NULL ) THEN
        lv_ad_assets_type
          := get_sp_rec.ad_assets_type
             || cv_colon
             || lv_ad_assets_type_name;
      END IF;
--
      -- 覚書情報税区分
      IF ( get_sp_rec.tax_type IS NOT NULL ) THEN
        lv_tax_type
          := get_sp_rec.tax_type
             || cv_colon
             || lv_tax_type_name;
      END IF;
--
      -- 設置協賛金
      IF ( get_sp_rec.install_supp_type IS NOT NULL ) THEN
        lv_install_supp_type
          := get_sp_rec.install_supp_type
             || cv_colon
             || lv_install_supp_type_name;
      END IF;
--
      -- 設置協賛金区分
      IF ( get_sp_rec.install_supp_payment_type IS NOT NULL ) THEN
        lv_install_supp_payment_type
          := get_sp_rec.install_supp_payment_type
             || cv_colon
             || lv_install_supp_pay_type_name;
      END IF;
--
      -- 電気代
      IF ( get_sp_rec.electricity_type IS NOT NULL ) THEN
        IF ( get_sp_rec.electricity_type =  cv_presence_kbn_0) THEN
          lv_electricity_type
            := get_sp_rec.electricity_type
             || cv_colon
             || lv_nashi;
        ELSE
          lv_electricity_type
            := get_sp_rec.electricity_type
             || cv_colon
             || lv_ari;
        END IF;
      END IF;
--
      -- 電気代契約先
      IF ( get_sp_rec.electric_payment_type IS NOT NULL ) THEN
        lv_electric_payment_type
          := get_sp_rec.electric_payment_type
             || cv_colon
             || lv_electric_pay_type_name;
      END IF;
--
      -- 電気代区分
      IF ( get_sp_rec.electric_payment_change_type IS NOT NULL ) THEN
        lv_electric_pay_change_type
          := get_sp_rec.electric_payment_change_type
             || cv_colon
             || lv_electric_pay_change_tp_name;
      END IF;
--
      -- 電気代変動区分
      IF ( get_sp_rec.electricity_change_type IS NOT NULL ) THEN
        lv_electricity_change_type
          := get_sp_rec.electricity_change_type
             || cv_colon
             || lv_electricity_change_tp_name;
      END IF;
--
      -- 電気代支払サイクル
      IF ( get_sp_rec.electric_payment_cycle IS NOT NULL ) THEN
        lv_electric_payment_cycle
          := get_sp_rec.electric_payment_cycle
             || cv_colon
             || lv_electric_pay_cycle_name;
      END IF;
--
      -- 電気代振込日
      IF ( get_sp_rec.electric_trans_month IS NOT NULL ) THEN
        lv_electric_trans_date
          := lv_electric_trans_date_name
             || get_sp_rec.electric_trans_date
             || lv_day;
      END IF;
--
      -- 紹介手数料
      IF ( get_sp_rec.intro_chg_type IS NOT NULL ) THEN
        lv_intro_chg_type
          := get_sp_rec.intro_chg_type
             || cv_colon
             || lv_intro_chg_type_name;
      END IF;
--
      -- 紹介手数料区分
      IF ( get_sp_rec.cust_cointro_chg_payment_type IS NOT NULL ) THEN
        lv_cust_cointro_chg_pay_type
          := get_sp_rec.cust_cointro_chg_payment_type
             || cv_colon
             || lv_cust_intro_chg_pay_tp_name;
      END IF;
--
      -- 紹介手数料振込日
      IF ( get_sp_rec.intro_chg_trans_month IS NOT NULL ) THEN
        lv_intro_chg_trans_date
          := lv_intro_chg_trans_date_name
             || get_sp_rec.intro_chg_trans_date
             || lv_day;
      END IF;
--
      -- BM1振込手数料負担
      IF ( get_sp_rec.bm1_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm1_bank_charge_bearer
          := lv_bm1_bank_charge_bearer_name;
      END IF;
--
      -- BM1支払方法・明細書
      IF ( get_sp_rec.bm1_bm_payment_type IS NOT NULL ) THEN
        lv_bm1_bm_payment_type
          := get_sp_rec.bm1_bm_payment_type
             || cv_colon
             || lv_bm1_bm_payment_type_name;
      END IF;
--
      -- BM2振込手数料負担
      IF ( get_sp_rec.bm2_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm2_bank_charge_bearer
          := lv_bm2_bank_charge_bearer_name;
      END IF;
--
      -- BM2支払方法・明細書
      IF ( get_sp_rec.bm2_bm_payment_type IS NOT NULL ) THEN
        lv_bm2_bm_payment_type
          := get_sp_rec.bm2_bm_payment_type
             || cv_colon
             || lv_bm2_bm_payment_type_name;
      END IF;
--
      -- BM3振込手数料負担
      IF ( get_sp_rec.bm3_bank_charge_bearer IS NOT NULL ) THEN
        lv_bm3_bank_charge_bearer
          := lv_bm3_bank_charge_bearer_name;
      END IF;
--
      -- BM3支払方法・明細書
      IF ( get_sp_rec.bm3_bm_payment_type IS NOT NULL ) THEN
        lv_bm3_bm_payment_type
          := get_sp_rec.bm3_bm_payment_type
             || cv_colon
             || lv_bm3_bm_payment_type_name;
      END IF;
--
      -- 回送先・確認者
      lv_approve_10
        := get_sp_rec.approve_code_10
           || ' '
           || get_sp_rec.work_request_type_10
           || cv_colon
           || lv_work_request_type_name_10
           || ' '
           || get_sp_rec.approval_state_type_10
           || cv_colon
           || lv_approval_state_type_name_10
           || ' '
           || get_sp_rec.approval_date_10
           || ' '
           || get_sp_rec.approval_content_10
           || cv_colon
           || lv_approval_content_name_10
           || ' '
           || get_sp_rec.approval_comment_10;
--
      -- 回送先・承認者
      lv_approve_20
        := get_sp_rec.approve_code_20
           || ' '
           || get_sp_rec.work_request_type_20
           || cv_colon
           || lv_work_request_type_name_20
           || ' '
           || get_sp_rec.approval_state_type_20
           || cv_colon
           || lv_approval_state_type_name_20
           || ' '
           || get_sp_rec.approval_date_20
           || ' '
           || get_sp_rec.approval_content_20
           || cv_colon
           || lv_approval_content_name_20
           || ' '
           || get_sp_rec.approval_comment_20;
      -- 回送先・地区営業管理課長
      lv_approve_30
        := get_sp_rec.approve_code_30
           || ' '
           || get_sp_rec.work_request_type_30
           || cv_colon
           || lv_work_request_type_name_30
           || ' '
           || get_sp_rec.approval_state_type_30
           || cv_colon
           || lv_approval_state_type_name_30
           || ' '
           || get_sp_rec.approval_date_30
           || ' '
           || get_sp_rec.approval_content_30
           || cv_colon
           || lv_approval_content_name_30
           || ' '
           || get_sp_rec.approval_comment_30;
      -- 回送先・地区営業部長
      lv_approve_40
        := get_sp_rec.approve_code_40
           || ' '
           || get_sp_rec.work_request_type_40
           || cv_colon
           || lv_work_request_type_name_40
           || ' '
           || get_sp_rec.approval_state_type_40
           || cv_colon
           || lv_approval_state_type_name_40
           || ' '
           || get_sp_rec.approval_date_40
           || ' '
           || get_sp_rec.approval_content_40
           || cv_colon
           || lv_approval_content_name_40
           || ' '
           || get_sp_rec.approval_comment_40;
      -- 回送先・関係先
      lv_approve_50
        := get_sp_rec.approve_code_50
           || ' '
           || get_sp_rec.work_request_type_50
           || cv_colon
           || lv_work_request_type_name_50
           || ' '
           || get_sp_rec.approval_state_type_50
           || cv_colon
           || lv_approval_state_type_name_50
           || ' '
           || get_sp_rec.approval_date_50
           || ' '
           || get_sp_rec.approval_content_50
           || cv_colon
           || lv_approval_content_name_50
           || ' '
           || get_sp_rec.approval_comment_50;
      -- 回送先・自販機部課長
      lv_approve_60
        := get_sp_rec.approve_code_60
           || ' '
           || get_sp_rec.work_request_type_60
           || cv_colon
           || lv_work_request_type_name_60
           || ' '
           || get_sp_rec.approval_state_type_60
           || cv_colon
           || lv_approval_state_type_name_60
           || ' '
           || get_sp_rec.approval_date_60
           || ' '
           || get_sp_rec.approval_content_60
           || cv_colon
           || lv_approval_content_name_60
           || ' '
           || get_sp_rec.approval_comment_60;
      -- 回送先・自販機部長
      lv_approve_70
        := get_sp_rec.approve_code_70
           || ' '
           || get_sp_rec.work_request_type_70
           || cv_colon
           || lv_work_request_type_name_70
           || ' '
           || get_sp_rec.approval_state_type_70
           || cv_colon
           || lv_approval_state_type_name_70
           || ' '
           || get_sp_rec.approval_date_70
           || ' '
           || get_sp_rec.approval_content_70
           || cv_colon
           || lv_approval_content_name_70
           || ' '
           || get_sp_rec.approval_comment_70;
      -- 回送先・拠点管理部長
      lv_approve_80
        := get_sp_rec.approve_code_80
           || ' '
           || get_sp_rec.work_request_type_80
           || cv_colon
           || lv_work_request_type_name_80
           || ' '
           || get_sp_rec.approval_state_type_80
           || cv_colon
           || lv_approval_state_type_name_80
           || ' '
           || get_sp_rec.approval_date_80
           || ' '
           || get_sp_rec.approval_content_80
           || cv_colon
           || lv_approval_content_name_80
           || ' '
           || get_sp_rec.approval_comment_80;
      -- 回送先・営業本部長
      lv_approve_90
        := get_sp_rec.approve_code_90
           || ' '
           || get_sp_rec.work_request_type_90
           || cv_colon
           || lv_work_request_type_name_90
           || ' '
           || get_sp_rec.approval_state_type_90
           || cv_colon
           || lv_approval_state_type_name_90
           || ' '
           || get_sp_rec.approval_date_90
           || ' '
           || get_sp_rec.approval_content_90
           || cv_colon
           || lv_approval_content_name_90
           || ' '
           || get_sp_rec.approval_comment_90;
--
      -- ===============================
      -- カンマ区切りでデータ作成
      -- ===============================
      lv_output_str :=                              cv_dqu || get_sp_rec.last_update_date             || cv_dqu ;  -- 最終更新日時
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sp_decision_number           || cv_dqu ;  -- SP専決書番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_status                               || cv_dqu ;  -- ステータス
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_application_type                     || cv_dqu ;  -- 申請区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.application_date             || cv_dqu ;  -- 申請日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.approval_complete_date       || cv_dqu ;  -- 承認完了日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_application_code                     || cv_dqu ;  -- 申請者
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_app_base_code                        || cv_dqu ;  -- 申請拠点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_number               || cv_dqu ;  -- 顧客コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_name                 || cv_dqu ;  -- 顧客名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.account_name_alt             || cv_dqu ;  -- 顧客名カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_name                 || cv_dqu ;  -- 設置先名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_postal_code          || cv_dqu ;  -- 設置先郵便番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_state                || cv_dqu ;  -- 設置先都道府県
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_city                 || cv_dqu ;  -- 設置先市・区
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_address1             || cv_dqu ;  -- 設置先住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_address2             || cv_dqu ;  -- 設置先住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_phone_number         || cv_dqu ;  -- 設置先電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_business_low_type                    || cv_dqu ;  -- 業態（小分類）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_business_type                        || cv_dqu ;  -- 業種
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_location                     || cv_dqu ;  -- 設置場所
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_open_close_div                       || cv_dqu ;  -- オープン/クローズ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.employee                     || cv_dqu ;  -- 社員数
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_sale_base_code                       || cv_dqu ;  -- 担当拠点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_date                 || cv_dqu ;  -- 設置日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.lease_company                || cv_dqu ;  -- リース仲介会社
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_customer_status                      || cv_dqu ;  -- 顧客ステータス
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sale_employee_number         || cv_dqu ;  -- 担当営業員コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sale_employee_name           || cv_dqu ;  -- 担当営業員名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_number              || cv_dqu ;  -- 契約先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_name                || cv_dqu ;  -- 契約先名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_name_alt            || cv_dqu ;  -- 契約先名カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_post_code           || cv_dqu ;  -- 契約先郵便番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_state               || cv_dqu ;  -- 契約先都道府県
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_city                || cv_dqu ;  -- 契約先市・区
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_address_1           || cv_dqu ;  -- 契約先住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_address_2           || cv_dqu ;  -- 契約先住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_phone_number        || cv_dqu ;  -- 契約先電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_delegate_name       || cv_dqu ;  -- 契約先代表者名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_newold_type                          || cv_dqu ;  -- 新台旧台区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.maker_code                   || cv_dqu ;  -- メーカーコード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.un_number                    || cv_dqu ;  -- 機種コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sele_number                  || cv_dqu ;  -- セレ数
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_standard_type                        || cv_dqu ;  -- 規格内外区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_condition_business_type              || cv_dqu ;  -- 取引条件区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_all_container_type                   || cv_dqu ;  -- 全容器区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_year_date           || cv_dqu ;  -- 契約年数
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.contract_year_month          || cv_dqu ;  -- 契約月数
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_contract_period                      || cv_dqu ;  -- 契約期間
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bidding_item                         || cv_dqu ;  -- 入札案件
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_cancell_before_maturity              || cv_dqu ;  -- 中途解約条項
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_ad_assets_type                       || cv_dqu ;  -- 行政財産使用料
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_amt                || cv_dqu ;  -- 行政財産使用料総額
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_this_time          || cv_dqu ;  -- 行政財産使用料（今回支払）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_payment_year       || cv_dqu ;  -- 行政財産使用料年目
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.ad_assets_payment_date       || cv_dqu ;  -- 行政財産使用料支払期日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_tax_type                             || cv_dqu ;  -- 覚書情報税区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_supp_type                    || cv_dqu ;  -- 設置協賛金
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_install_supp_payment_type            || cv_dqu ;  -- 設置協賛金区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_amt             || cv_dqu ;  -- 設置協賛金総額
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_this_time       || cv_dqu ;  -- 設置協賛金（今回支払）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_payment_year    || cv_dqu ;  -- 設置協賛金年目
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_supp_payment_date    || cv_dqu ;  -- 設置協賛金支払期日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electricity_type                     || cv_dqu ;  -- 電気代
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_payment_type                || cv_dqu ;  -- 電気代契約先
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_pay_change_type             || cv_dqu ;  -- 電気代区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amount           || cv_dqu ;  -- 電気代金額
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electricity_change_type              || cv_dqu ;  -- 電気代変動区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_payment_cycle               || cv_dqu ;  -- 電気代支払サイクル
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_closing_date        || cv_dqu ;  -- 電気代締め日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_electric_trans_date                  || cv_dqu ;  -- 電気代振込日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_trans_name          || cv_dqu ;  -- 電気代契約先以外名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electric_trans_name_alt      || cv_dqu ;  -- 電気代契約先以外名（カナ）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_intro_chg_type                       || cv_dqu ;  -- 紹介手数料
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_cust_cointro_chg_pay_type            || cv_dqu ;  -- 紹介手数料区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_amt                || cv_dqu ;  -- 紹介手数料総額
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_this_time          || cv_dqu ;  -- 紹介手数料（今回支払）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_payment_year       || cv_dqu ;  -- 紹介手数料年目
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_payment_date       || cv_dqu ;  -- 紹介手数料支払期日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_per_sales_price    || cv_dqu ;  -- 紹介手数料％
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_per_piece          || cv_dqu ;  -- 紹介手数料円
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_closing_date       || cv_dqu ;  -- 紹介手数料締め日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_intro_chg_trans_date                 || cv_dqu ;  -- 紹介手数料振込日
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_trans_name         || cv_dqu ;  -- 紹介手数料契約先以外名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.intro_chg_trans_name_alt     || cv_dqu ;  -- 紹介手数料契約先以外名（カナ）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.condition_reason             || cv_dqu ;  -- 特別条件の理由
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_type                || cv_dqu ;  -- BM1送付先区分
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_code                || cv_dqu ;  -- BM1送付先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_name                || cv_dqu ;  -- BM1送付先名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_send_name_alt            || cv_dqu ;  -- BM1送付先カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_postal_code              || cv_dqu ;  -- BM1郵便番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_address1                 || cv_dqu ;  -- BM1住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_address2                 || cv_dqu ;  -- BM1住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_phone_number             || cv_dqu ;  -- BM1電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm1_bank_charge_bearer               || cv_dqu ;  -- BM1振込手数料負担
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm1_bm_payment_type                  || cv_dqu ;  -- BM1支払方法・明細書
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm1_inquiry_base_code        || cv_dqu ;  -- BM1問合せ担当拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_code                || cv_dqu ;  -- BM2送付先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_name                || cv_dqu ;  -- BM2送付先名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_send_name_alt            || cv_dqu ;  -- BM2送付先カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_postal_code              || cv_dqu ;  -- BM2郵便番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_address1                 || cv_dqu ;  -- BM2住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_address2                 || cv_dqu ;  -- BM2住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_phone_number             || cv_dqu ;  -- BM2電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm2_bank_charge_bearer               || cv_dqu ;  -- BM2振込手数料負担
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm2_bm_payment_type                  || cv_dqu ;  -- BM2支払方法・明細書
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm2_inquiry_base_code        || cv_dqu ;  -- BM2問合せ担当拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_code                || cv_dqu ;  -- BM3送付先コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_name                || cv_dqu ;  -- BM3送付先名
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_send_name_alt            || cv_dqu ;  -- BM3送付先カナ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_postal_code              || cv_dqu ;  -- BM3郵便番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_address1                 || cv_dqu ;  -- BM3住所1
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_address2                 || cv_dqu ;  -- BM3住所2
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_phone_number             || cv_dqu ;  -- BM3電話番号
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm3_bank_charge_bearer               || cv_dqu ;  -- BM3振込手数料負担
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_bm3_bm_payment_type                  || cv_dqu ;  -- BM3支払方法・明細書
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm3_inquiry_base_code        || cv_dqu ;  -- BM3問合せ担当拠点コード
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_month                  || cv_dqu ;  -- 月間売上
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_year                   || cv_dqu ;  -- 年間売上
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.sales_gross_margin_rate      || cv_dqu ;  -- 売上粗利率
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.year_gross_margin_amt        || cv_dqu ;  -- 年間粗利金額
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.bm_rate                      || cv_dqu ;  -- ＢＭ率
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.vd_sales_charge              || cv_dqu ;  -- ＶＤ販売手数料
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.install_support_amt_year     || cv_dqu ;  -- 設置協賛金／年
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.lease_charge_month           || cv_dqu ;  -- リース料（月額）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.construction_charge          || cv_dqu ;  -- 工事費
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.vd_lease_charge              || cv_dqu ;  -- ＶＤリース料
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amt_month        || cv_dqu ;  -- 電気代（月）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.electricity_amt_year         || cv_dqu ;  -- 電気代（年）
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.transportation_charge        || cv_dqu ;  -- 運送費Ａ
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.labor_cost_other             || cv_dqu ;  -- 人件費他
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.total_cost                   || cv_dqu ;  -- 費用合計
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.operating_profit             || cv_dqu ;  -- 営業利益
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.operating_profit_rate        || cv_dqu ;  -- 営業利益率
      lv_output_str := lv_output_str || cv_comma || cv_dqu || get_sp_rec.break_even_point             || cv_dqu ;  -- 損益分岐点
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_10                           || cv_dqu ;  -- 回送先・確認者
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_20                           || cv_dqu ;  -- 回送先・承認者
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_30                           || cv_dqu ;  -- 回送先・地区営業管理課長
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_40                           || cv_dqu ;  -- 回送先・地区営業部長
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_50                           || cv_dqu ;  -- 回送先・関係先
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_60                           || cv_dqu ;  -- 回送先・自販機部課長
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_70                           || cv_dqu ;  -- 回送先・自販機部長
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_80                           || cv_dqu ;  -- 回送先・拠点管理部長
      lv_output_str := lv_output_str || cv_comma || cv_dqu || lv_approve_90                           || cv_dqu ;  -- 回送先・営業本部長
--
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
--
      -- データ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_output_str
      );
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
  END output_sp_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code       IN  VARCHAR2     -- 申請(売上)拠点
   ,iv_app_date_from   IN  VARCHAR2     -- 申請日(FROM)
   ,iv_app_date_to     IN  VARCHAR2     -- 申請日(TO)
   ,iv_status          IN  VARCHAR2     -- ステータス
   ,iv_customer_cd     IN  VARCHAR2     -- 顧客コード
   ,iv_kbn             IN  VARCHAR2     -- 判定区分
   ,ov_errbuf          OUT VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode         OUT VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg          OUT VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      iv_base_code     => iv_base_code       -- 売上(申請)拠点
     ,iv_app_date_from => iv_app_date_from   -- 申請日(FROM)
     ,iv_app_date_to   => iv_app_date_to     -- 申請日(TO)
     ,iv_status        => iv_status          -- ステータス
     ,iv_customer_cd   => iv_customer_cd     -- 顧客コード
     ,iv_kbn           => iv_kbn             -- 判定区分
     ,ov_errbuf        => lv_errbuf          -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode         -- リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- SP専決書情報取得・出力(A-2,A-3)
    -- ===============================
    output_sp_data(
      ov_errbuf          => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode         => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg          => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
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
    errbuf           OUT    VARCHAR2     -- エラーメッセージ #固定#
   ,retcode          OUT    VARCHAR2     -- エラーコード     #固定#
   ,iv_base_code     IN     VARCHAR2     -- 申請(売上)拠点
   ,iv_app_date_from IN     VARCHAR2     -- 申請日(FROM)
   ,iv_app_date_to   IN     VARCHAR2     -- 申請日(TO)
   ,iv_status        IN     VARCHAR2     -- ステータス
   ,iv_customer_cd   IN     VARCHAR2     -- 顧客コード
   ,iv_kbn           IN     VARCHAR2     -- 判定区分
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
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
       iv_which   => cv_output_log
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
       iv_base_code     => iv_base_code     -- 売上(申請)拠点
      ,iv_app_date_from => iv_app_date_from -- 申請日(FROM)
      ,iv_app_date_to   => iv_app_date_to   -- 申請日(TO)
      ,iv_status        => iv_status        -- ステータス
      ,iv_customer_cd   => iv_customer_cd   -- 顧客コード
      ,iv_kbn           => iv_kbn           -- 判定区分
      ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラーの場合
    IF (lv_retcode = cv_status_error) THEN
      -- エラーメッセージを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 件数を設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================================
    -- 対象件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- 成功件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --==================================================
    -- エラー件数出力
    --==================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- 終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
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
END XXCSO020A07C;
/
