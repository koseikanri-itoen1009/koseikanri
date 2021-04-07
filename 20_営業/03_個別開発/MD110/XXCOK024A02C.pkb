CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A02C (body)
 * Description      : 控除マスタCSV出力
 * MD.050           : 控除マスタCSV出力 MD050_COK_024_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_order_list_cond    控除マスタ抽出(A-2)
 *  output_data            データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/21    1.0   Y.Nakajima       新規作成
 *  2021/04/06    1.1   K.Yoshikawa      定額控除複数明細対応
 
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;  -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数警告例外 ***
  global_api_warn_expt      EXCEPTION;
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
  --*** 出力日 日付逆転チェック例外 ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                    -- 区切り文字
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                     -- 空文字
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                    -- スペース
  cv_full_space               CONSTANT  VARCHAR2(4)   := '　';                   -- 全角スペース
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                    -- 'Y'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                    -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );      -- 言語
  -- プロファイル
  cv_item_div                 CONSTANT  VARCHAR2(30)  := 'XXCOS1_ITEM_DIV_H';    -- 本社商品区分
  -- 数値
  cn_zero                     CONSTANT  NUMBER        := 0;                      -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                      -- 1
  cv_min_date                 CONSTANT  VARCHAR2(10)  := '1900/01/01';           -- 最小日付
  cv_max_date                 CONSTANT  VARCHAR2(10)  := '9999/12/31';           -- 最大日付
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A02C';         -- パッケージ名
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                -- 販物領域短縮アプリ名
  -- 書式マスク
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- 日付書式
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- 日付書式(日時)
  -- 参照タイプ
  cv_type_business_type       CONSTANT  VARCHAR2(30)  := 'XX03_BUSINESS_TYPE';            -- 企業コード
  cv_type_chain_code          CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';              -- 控除用チェーンコード
  cv_type_header              CONSTANT  VARCHAR2(30)  := 'XXCOK1_EXCEL_OUTPUT_HEADER_1';  -- 控除マスタ出力用見出し
  cv_type_dec_pri_base        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- 控除マスタ特権拠点
  cv_type_dec_del_dept        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_DEL_PRI_DEPT';       -- 控除マスタ削除特権部署
  cv_type_deduction_data      CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- 控除データ種類
  cv_type_deduction_1_kbn     CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_1_KBN';        -- 対象区分
  --メッセージ
  cv_msg_para_code_null_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10679';     -- 必須パラメータ未設定エラー（企業コード、控除用チェーンコード、顧客コード）
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';     -- 日付逆転エラー
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';     -- 業務日付取得エラーメッセージ
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10570';     -- パラメータ出力メッセージ
  cv_msg_parameter2           CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10571';     -- パラメータ出力メッセージ2
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';     -- ユーザーID取得エラーメッセージ
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';     -- 所属拠点コード取得エラーメッセージ
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';     -- 対象データなしエラーメッセージ
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     -- プロファイル取得エラーメッセージ
  --トークン名
  cv_tkn_nm_date_from         CONSTANT  VARCHAR2(100) := 'DATE_FROM';            -- 開始日
  cv_tkn_nm_date_to           CONSTANT  VARCHAR2(100) := 'DATE_TO';              -- 終了日
  cv_tkn_nm_deduction_no      CONSTANT  VARCHAR2(100) := 'DEDUCTION_NO';         -- 控除番号
  cv_tkn_nm_corp_code         CONSTANT  VARCHAR2(100) := 'CORP_CODE';            -- 企業コード
  cv_tkn_nm_intoduction_code  CONSTANT  VARCHAR2(100) := 'CHAIN_CODE';           -- 控除用チェーンコード
  cv_tkn_ship_cust_code       CONSTANT  VARCHAR2(100) := 'CUST_CODE';            -- 顧客コード
  cv_tkn_nm_date_type         CONSTANT  VARCHAR2(100) := 'DATE_TYPE';            -- データ種類
  cv_tkn_nm_tax_code          CONSTANT  VARCHAR2(100) := 'TAX_CODE';             -- 税コード
  cv_tkn_nm_content           CONSTANT  VARCHAR2(100) := 'CONTENT';              -- 内容
  cv_tkn_nm_decision_no       CONSTANT  VARCHAR2(100) := 'DECISION_NO';          -- 決裁No
  cv_tkn_nm_agreemen_no       CONSTANT  VARCHAR2(100) := 'AGREEMENT_NO';         -- 契約番号
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';              -- ユーザーID
  cv_tkn_nm_last_update       CONSTANT  VARCHAR2(100) := 'LAST_UPDATE';          -- 最終更新日
  cv_profile_tok              CONSTANT  VARCHAR2(20)  := 'PROFILE';              -- プロファイル名
  --トークン値
  -- 控除タイプ
  cv_condition_type_sale      CONSTANT  VARCHAR2(3)   := '020';                  -- 控除タイプ(販売数量×金額)
  cv_condition_type_spons     CONSTANT  VARCHAR2(3)   := '050';                  -- 控除タイプ(定額協賛金)
  cv_condition_type_pre_spons CONSTANT  VARCHAR2(3)   := '060';                  -- 控除タイプ(対象数量予測協賛金)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE;                                                -- 業務日付
  gn_user_id                NUMBER;                                              -- ユーザーID
  gv_user_base_code         VARCHAR2(150);                                       -- 所属拠点コード
  gn_privilege_dept         NUMBER;                                              -- 削除権限（0：権限なし、1：権限あり）
  gn_privilege_base         NUMBER;                                              -- 登録・更新特権（0：特権なし、1：特権あり）
  gv_privilege_flag         VARCHAR2(1);                                         -- 特権ユーザー判断フラグ
  gv_data_type              VARCHAR2(10);                                        -- データ種類
  gv_item_div_h             VARCHAR2(20);                                        -- 本社商品区分
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  CURSOR get_deduction_list_data_cur (
           iv_order_deduction_no           VARCHAR2  -- 控除番号
          ,iv_corp_code                    VARCHAR2  -- 企業コード
          ,iv_introduction_code            VARCHAR2  -- 控除用チェーンコード
          ,iv_ship_cust_code               VARCHAR2  -- 顧客コード
          ,iv_data_type                    VARCHAR2  -- データ種類
          ,iv_tax_code                     VARCHAR2  -- 税コード
          ,iv_order_list_date_from         VARCHAR2  -- 開始日
          ,iv_order_list_date_to           VARCHAR2  -- 終了日
          ,iv_content                      VARCHAR2  -- 内容
          ,iv_decision_no                  VARCHAR2  -- 決裁No
          ,iv_agreement_no                 VARCHAR2  -- 契約番号
          ,iv_last_update_date             VARCHAR2  -- 最終更新日
          )
  IS
    SELECT 
            /*+ LEADING(mst@a)
            NO_PUSH_PRED(mst@a)
            USE_NL(mst@a xch)
            INDEX(XCH XXCOK_CONDITION_HEADER_PK) */
           xch.condition_no                             AS condition_no                            -- 控除番号
          ,xch.corp_code                                AS corp_code                               -- 企業コード
          ,xch.deduction_chain_code                     AS deduction_chain_code                    -- 控除用チェーンコード
          ,xch.customer_code                            AS customer_code                           -- 顧客コード
          ,flvv2.meaning                                AS data_type                               -- データ種類
          ,xch.start_date_active                        AS start_date_active                       -- 開始日
          ,xch.end_date_active                          AS end_date_active                         -- 終了日
          ,xch.content                                  AS content                                 -- 内容
          ,xch.decision_no                              AS decision_no                             -- 決裁No
          ,xch.agreement_no                             AS agreement_no                            -- 契約番号
          ,xcl.detail_number                            AS detail_number                           -- 明細番号
          ,flv.meaning                                  AS target_category                         -- 対象区分
          ,pro.product_class                            AS product_class                           -- 商品区分
          ,xcl.item_code                                AS item_code                               -- 品目コード
          ,xcl.uom_code                                 AS uom_code                                -- 単位
          ,xcl.shop_pay_1                               AS shop_pay_1                              -- 店納(%)
          ,xcl.material_rate_1                          AS material_rate                           -- 料率(%)
          ,xcl.demand_en_3                              AS demand_en                               -- 請求(円)
          ,xcl.shop_pay_en_3                            AS shop_pay_en                             -- 店納(円)
          ,xcl.dl_wholesale_margin_en                   AS wholesale_margin_en                     -- DL用問屋マージン(円)
          ,xcl.dl_wholesale_margin_per                  AS wholesale_margin_per                    -- DL用問屋マージン(％)
          ,xcl.normal_shop_pay_en_4                     AS normal_shop_pay_en                      -- 通常店納(円)
          ,xcl.just_shop_pay_en_4                       AS just_shop_pay_en                        -- 今回店納(円)
          ,xcl.dl_wholesale_adj_margin_en               AS wholesale_adj_margin_en                 -- DL用問屋マージン修正(円)
          ,xcl.dl_wholesale_adj_margin_per              AS wholesale_adj_margin_per                -- DL用問屋マージン修正(％)
          ,CASE
             -- 控除タイプが'050'の場合
             WHEN  flvv2.attribute2 = cv_condition_type_spons THEN
                xcl.prediction_qty_5
             -- 控除タイプが'060'の場合
             WHEN  flvv2.attribute2 = cv_condition_type_pre_spons THEN
                xcl.prediction_qty_6
             END                                        AS prediction_qty                          -- 予測数量(本)
          ,xcl.support_amount_sum_en_5                  AS support_amount_sum_en                   -- 協賛金合計(円)
          ,CASE
             -- 控除タイプが'020'の場合
             WHEN  flvv2.attribute2 = cv_condition_type_sale THEN
                xcl.condition_unit_price_en_2
             -- 控除タイプが'060'の場合
             WHEN  flvv2.attribute2 = cv_condition_type_pre_spons THEN
                xcl.condition_unit_price_en_6
             END                                        AS condition_unit_price_en                 -- 条件単価(円)
          
          ,xcl.target_rate_6                            AS target_rate6                            -- 対象率(％)
          ,xcl.accounting_base                          AS accounting_base                         -- 計上拠点
-- 2021/04/06 Ver1.1 ADD Start
          ,xcl.accounting_customer_code                 AS accounting_customer_code                -- 計上顧客
-- 2021/04/06 Ver1.1 ADD End
          ,xcl.deduction_amount                         AS deduction_amount                        -- 控除額(本体)
          ,xch.tax_code                                 AS tax_code                                -- 税コード
          ,xcl.deduction_tax_amount                     AS deduction_tax_amount                    -- 控除税額
          ,xch.last_update_date                         AS head_last_update_date                   -- ヘッダ最終更新日
          ,papf.employee_number                         AS head_employee_number                    -- ヘッダ最終更新者従業員番号
          ,papf.per_information18                       AS head_last_update_by_last                -- ヘッダ最終更新者姓
          ,papf.per_information19                       AS head_last_update_by_first               -- ヘッダ最終更新者名
          ,xcl.last_update_date                         AS line_last_update_date                   -- 明細最終更新日
          ,papf2.employee_number                        AS line_employee_number                    -- 明細最終更新者従業員番号
          ,papf2.per_information18                      AS line_last_update_by_last                -- 明細最終更新者姓
          ,papf2.per_information19                      AS line_last_update_by_first               -- 明細最終更新者名
    FROM xxcok_condition_header       xch                                                          -- 控除条件テーブル
        ,xxcok_condition_lines        xcl                                                          -- 控除詳細テーブル
        ,fnd_flex_values_vl           ffvv                                                         -- 企業マスタ
        ,fnd_lookup_values_vl         flvv1                                                        -- チェーンマスタ
        ,xxcmm_cust_accounts          xca                                                          -- 顧客マスタ
-- 2021/04/06 Ver1.1 ADD Start
        ,xxcmm_cust_accounts          xca2                                                         -- 顧客マスタ2
-- 2021/04/06 Ver1.1 ADD End
        ,fnd_lookup_values_vl         flvv2                                                        -- 控除データ種類
        ,fnd_user                     fu                                                           -- ユーザーマスタ
        ,fnd_user                     fu2                                                          -- ユーザーマスタ2
        ,per_all_people_f             papf                                                         -- 従業員マスタ
        ,per_all_people_f             papf2                                                        -- 従業員マスタ2
        ,fnd_lookup_values            flv                                                          -- 対象区分
       ,(SELECT /*+ QB_NAME(a) */
                mst2.CONDITION_ID AS CONDITION_ID
         FROM
         (-- 1.企業指定時
          SELECT /*+ INDEX(xch1 XXCOK_CONDITION_HEADER_N01) */
                 xch1.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch1
          WHERE  iv_corp_code                     IS NOT NULL
          AND    xch1.corp_code                 = iv_corp_code
          UNION
          -- 2.チェーン指定時
          SELECT /*+ INDEX(xch2 XXCOK_CONDITION_HEADER_N02) */
                 xch2.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch2
          WHERE  iv_introduction_code             IS NOT NULL
          AND    xch2.deduction_chain_code   = iv_introduction_code
          UNION
          -- 3.顧客指定時
          SELECT /*+ INDEX(xch3 XXCOK_CONDITION_HEADER_N03) */
                 xch3.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch3
          WHERE  iv_ship_cust_code                IS NOT NULL
          AND    xch3.customer_code             = iv_ship_cust_code
          UNION
          -- 4.控除番号のみ指定時
          SELECT /*+ INDEX(xch4 XXCOK_CONDITION_HEADER_N04) */
                 xch4.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch4
          WHERE  iv_order_deduction_no IS NOT NULL                  -- 控除番号
          AND    iv_corp_code          IS NULL                      -- 企業コード
          AND    iv_introduction_code  IS NULL                      -- 控除用チェーンコード
          AND    iv_ship_cust_code     IS NULL                      -- 顧客コード
          AND    iv_last_update_date   IS NULL                      -- 最終更新日
          AND    xch4.condition_no     = iv_order_deduction_no
          UNION
          -- 「5.最終更新日のみ」or「6.最終更新日と控除番号のみ」指定時
          SELECT /*+ INDEX(xch5 XXCOK_CONDITION_HEADER_N05) */
                 xch5.condition_id            AS condition_id
          FROM   xxcok_condition_header       xch5
          WHERE  iv_corp_code          IS NULL                      -- 企業コード
          AND    iv_introduction_code  IS NULL                      -- 控除用チェーンコード
          AND    iv_ship_cust_code     IS NULL                      -- 顧客コード
          AND    iv_last_update_date   IS NOT NULL                  -- 最終更新日
          AND    xch5.last_update_date >= TO_DATE(iv_last_update_date,cv_date_format)
          ) mst2
        ) mst                                                          -- パラメータ判別用インラインビュー
       ,(SELECT mcv.segment1     product_class_code
               ,mcv.description  product_class
         FROM   mtl_categories_vl    mcv
               ,mtl_category_sets_vl mcsv
         WHERE  mcsv.structure_id      = mcv.structure_id
         AND    mcsv.category_set_name = gv_item_div_h
        )                             pro
    WHERE 1 = 1
    AND    mst.condition_id                       = xch.condition_id                               -- インラインビュー.控除条件ID ＝ 控除条件.控除条件ID
    AND    xch.condition_id                       = xcl.condition_id                               -- 控除条件.控除条件ID         ＝ 控除詳細.控除条件ID
    AND    xch.enabled_flag_h                     = cv_const_y                                     -- 控除条件.有効フラグ         ＝ Y
    AND    xcl.enabled_flag_l                     = cv_const_y                                     -- 控除詳細.有効フラグ         ＝ Y
    -- 控除データ種類
    AND    xch.data_type                          = flvv2.lookup_code
    AND    flvv2.lookup_type                      = cv_type_deduction_data
    -- 企業
    AND    xch.corp_code                          = ffvv.flex_value(+)                             -- 控除条件.企業コード         ＝ 企業マスタ.企業コード
    AND    ffvv.value_category(+)                 = cv_type_business_type
    -- チェーン
    AND    xch.deduction_chain_code               = flvv1.lookup_code(+)                           -- 控除条件.控除用チェーンコード     ＝ チェーンマスタ.控除用チェーンコード
    AND    flvv1.lookup_type(+)                   = cv_type_chain_code
    -- 顧客
    AND    xch.customer_code                      = xca.customer_code(+)                           -- 控除条件.顧客コード         ＝ 顧客マスタ.顧客コード
    -- 計上顧客
    AND    xcl.accounting_customer_code           = xca2.customer_code(+)                          -- 控除詳細.計上顧客コード     ＝ 顧客マスタ2.顧客コード
    -- パラメータ
    AND    (iv_order_deduction_no     IS NULL                                                                                                -- パラメータ.控除番号         IS NULL
      OR    xch.condition_no          = iv_order_deduction_no)                                                                               -- 控除条件.控除番号           ＝ パラメータ.控除番号
    AND    (iv_data_type              IS NULL                                                                                                -- パラメータ.データ種類       IS NULL
      OR    flvv2.meaning             = iv_data_type)                                                                                        -- 控除データ種類.内容         ＝ パラメータ.データ種類
    AND    (iv_tax_code               IS NULL                                                                                                -- パラメータ.税コード         IS NULL
      OR    xch.tax_code              = iv_tax_code)                                                                                         -- 控除条件.税コード           ＝ パラメータ.税コード
    AND    xch.end_date_active        >= NVL(TO_DATE(iv_order_list_date_from,cv_date_format),TO_DATE(cv_min_date,cv_date_format))            -- 控除条件.終了日             >= パラメータ.開始日
    AND    xch.start_date_active      <= NVL(TO_DATE(iv_order_list_date_to,  cv_date_format),TO_DATE(cv_max_date,cv_date_format))            -- 控除条件.開始日             <= パラメータ.終了日
    AND    (iv_content                IS NULL                                                                                                -- パラメータ.内容             IS NULL
      OR    xch.content               LIKE cv_perc||iv_content||cv_perc)                                                                     -- 控除条件.内容             LIKE パラメータ.内容
    AND    (iv_decision_no            IS NULL                                                                                                -- パラメータ.決裁No           IS NULL
      OR    xch.decision_no           = iv_decision_no)                                                                                      -- 控除条件.決裁No             ＝ パラメータ.決裁No
    AND    (iv_agreement_no           IS NULL                                                                                                -- パラメータ.契約番号         IS NULL
      OR    xch.agreement_no          = iv_agreement_no)                                                                                     -- 控除条件.契約番号           ＝ パラメータ.契約番号
    AND    (iv_last_update_date       IS NULL                                                                                                -- パラメータ.最終更新日       IS NULL
      OR    xch.last_update_date      >= TO_DATE(iv_last_update_date,cv_date_format))                                                        -- 控除条件.最終更新日         ＝ パラメータ.最終更新日
    -- 拠点制御
    AND     (gv_privilege_flag         = cv_const_y                                     -- 特権ユーザー判断フラグ      ＝ 'Y'
      OR     ffvv.attribute2           = gv_user_base_code                              -- 企業マスタ.本部担当拠点     ＝ 所属拠点コード
      OR     flvv1.attribute3          = gv_user_base_code                              -- チェーンマスタ.本部担当拠点 ＝ 所属拠点コード
      OR     xca.sale_base_code        = gv_user_base_code                              -- 顧客.売上担当拠点           ＝ 所属拠点コード
-- 2021/04/06 Ver1.1 MOD Start
--      OR     xcl.accounting_base       = gv_user_base_code                              -- 控除詳細.計上拠点           ＝ 所属拠点コード
      OR     xca2.sale_base_code       = gv_user_base_code                              -- 控除詳細.計上顧客           ＝ 所属拠点コード
-- 2021/04/06 Ver1.1 MOD End
             )
    -- ヘッダ従業員情報
    AND    fu.user_id                  = xch.last_updated_by
    AND    papf.person_id              = fu.employee_id
    AND    papf.current_employee_flag  = cv_const_y
    AND    papf.effective_start_date   IN (SELECT MAX(papf3.effective_start_date) effective_start_date
                                           FROM   per_all_people_f  papf3
                                           WHERE  papf3.current_employee_flag = cv_const_y
                                           AND    papf3.person_id             = papf.person_id)
    -- 明細従業員情報
    AND    fu2.user_id                 = xcl.last_updated_by
    AND    papf2.person_id             = fu2.employee_id
    AND    papf2.current_employee_flag = cv_const_y
    AND    papf2.effective_start_date  IN (SELECT MAX(papf4.effective_start_date) effective_start_date
                                           FROM   per_all_people_f  papf4
                                           WHERE  papf4.current_employee_flag = cv_const_y
                                           AND    papf4.person_id             = papf2.person_id)
    -- 対象区分
    AND   flv.language(+)                 = cv_lang
    AND   flv.lookup_type(+)              = cv_type_deduction_1_kbn
    AND   flv.lookup_code(+)              = xcl.target_category
    -- 商品区分
    AND   xcl.product_class               = pro.product_class_code(+)
    ORDER BY
           xch.corp_code                  -- 企業コード
          ,xch.deduction_chain_code       -- 控除用チェーンコード
          ,xch.customer_code              -- 顧客コード
          ,xch.data_type                  -- データ種類
          ,xch.condition_no               -- 控除番号
          ,xcl.detail_number              -- 明細番号
  ;
--
  -- 取得データ格納変数定義 (全出力)
  TYPE g_out_file_ttype IS TABLE OF get_deduction_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_deduction_no           IN     VARCHAR2     -- 控除番号
   ,iv_corp_code                    IN     VARCHAR2     -- 企業コード
   ,iv_introduction_code            IN     VARCHAR2     -- 控除用チェーンコード
   ,iv_ship_cust_code               IN     VARCHAR2     -- 顧客コード
   ,iv_data_type                    IN     VARCHAR2     -- データ種類
   ,iv_tax_code                     IN     VARCHAR2     -- 税コード
   ,iv_order_list_date_from         IN     VARCHAR2     -- 開始日
   ,iv_order_list_date_to           IN     VARCHAR2     -- 終了日
   ,iv_content                      IN     VARCHAR2     -- 内容
   ,iv_decision_no                  IN     VARCHAR2     -- 決裁No
   ,iv_agreement_no                 IN     VARCHAR2     -- 契約番号
   ,iv_last_update_date             IN     VARCHAR2     -- 最終更新日
   ,ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_para_msg                     VARCHAR2(5000);     -- パラメータ出力メッセージ
    lv_para_msg2                    VARCHAR2(5000);     -- パラメータ出力メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
    gn_privilege_dept := cn_zero;
    gn_privilege_base := cn_zero;
--
--###########################  固定部 END   ############################
--
    --========================================
    -- 1.パラメータ出力処理
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- アプリ短縮名
                                               ,iv_name               =>  cv_msg_parameter              -- パラメータ出力メッセージ
                                               ,iv_token_name1        =>  cv_tkn_nm_deduction_no        -- トークン：控除番号
                                               ,iv_token_value1       =>  iv_order_deduction_no         -- 控除番号
                                               ,iv_token_name2        =>  cv_tkn_nm_corp_code           -- トークン：企業コード
                                               ,iv_token_value2       =>  iv_corp_code                  -- 企業コード
                                               ,iv_token_name3        =>  cv_tkn_nm_intoduction_code    -- トークン：控除用チェーンコード
                                               ,iv_token_value3       =>  iv_introduction_code          -- 控除用チェーンコード
                                               ,iv_token_name4        =>  cv_tkn_ship_cust_code         -- トークン：顧客コード
                                               ,iv_token_value4       =>  iv_ship_cust_code             -- 顧客コード
                                               ,iv_token_name5        =>  cv_tkn_nm_date_type           -- トークン：データ種類
                                               ,iv_token_value5       =>  iv_data_type                  -- データ種類
                                               ,iv_token_name6        =>  cv_tkn_nm_tax_code            -- トークン：税コード
                                               ,iv_token_value6       =>  iv_tax_code                   -- 税コード
                                               ,iv_token_name7        =>  cv_tkn_nm_date_from           -- トークン：開始日
                                               ,iv_token_value7       =>  iv_order_list_date_from       -- 開始日
                                               ,iv_token_name8        =>  cv_tkn_nm_date_to             -- トークン：終了日
                                               ,iv_token_value8       =>  iv_order_list_date_to         -- 終了日
                                               ,iv_token_name9        =>  cv_tkn_nm_content             -- トークン：内容
                                               ,iv_token_value9       =>  iv_content                    -- 内容
                                               ,iv_token_name10       =>  cv_tkn_nm_decision_no         -- トークン：決裁No
                                               ,iv_token_value10      =>  iv_decision_no                -- 決裁No
                                               );
--
    lv_para_msg2  :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- アプリ短縮名
                                               ,iv_name               =>  cv_msg_parameter2             -- パラメータ出力メッセージ
                                               ,iv_token_name1        =>  cv_tkn_nm_agreemen_no         -- トークン：契約番号
                                               ,iv_token_value1       =>  iv_agreement_no               -- 契約番号
                                               ,iv_token_name2        =>  cv_tkn_nm_last_update         -- トークン：最終更新日
                                               ,iv_token_value2       =>  iv_last_update_date           -- 最終更新日
                                               );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg2
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.必須パラメータ入力チェック
    --========================================
    -- 控除番号、企業コード、控除用チェーンコード、顧客コード、最終更新日のいずれも入力されていない場合エラー
    IF ( iv_order_deduction_no IS NULL AND iv_corp_code IS NULL AND iv_introduction_code IS NULL AND iv_ship_cust_code IS NULL AND iv_last_update_date IS NULL) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_para_code_null_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.日付逆転チェック
    --========================================
    IF ( iv_order_list_date_from > iv_order_list_date_to ) THEN
      RAISE global_date_rever_old_chk_expt;
    END IF;
--
    --========================================
    -- 4.業務日付取得処理
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.ユーザーID取得処理
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_id_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.所属拠点コード取得処理
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_proc_date,
      in_user_id              =>  gn_user_id
      );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_base_code_err,
        iv_token_name1        =>  cv_tkn_nm_user_id,
        iv_token_value1       =>  gn_user_id
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 7.特権ユーザー確認処理
    --========================================
    -- 7-1 削除権限のあるユーザーか確認
    BEGIN
      SELECT  COUNT(1)              AS privilege_dept_cnt
      INTO    gn_privilege_dept
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type    = cv_type_dec_del_dept
      AND     flv.lookup_code    = gv_user_base_code
      AND     flv.enabled_flag   = cv_const_y
      AND     flv.language       = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 7-2 特権拠点の所属ユーザーか確認
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    gn_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 7-3 削除権限ユーザーか特権拠点ユーザーの判別
    IF ((gn_privilege_dept >= cn_one) OR (gn_privilege_base >= cn_one)) THEN
      gv_privilege_flag  := cv_const_y;
    END IF;
--
    --==============================================================
    -- 8.本社商品区分の取得
    --==============================================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div );
    -- 取得できない場合
    IF ( gv_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_xxcok_short_name
                     ,iv_name         =>  cv_msg_profile_err
                     ,iv_token_name1  =>  cv_profile_tok
                     ,iv_token_value1 =>  cv_item_div   -- プロファイル：本社商品区分
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--
  EXCEPTION
--
    -- ***開始日終了日 日付逆転チェック例外ハンドラ ***
    WHEN global_date_rever_old_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_date_rever_err
      );  
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_order_list_cond
   * Description      : 控除マスタデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_order_deduction_no           IN     VARCHAR2     -- 控除番号
   ,iv_corp_code                    IN     VARCHAR2     -- 企業コード
   ,iv_introduction_code            IN     VARCHAR2     -- 控除用チェーンコード
   ,iv_ship_cust_code               IN     VARCHAR2     -- 顧客コード
   ,iv_data_type                    IN     VARCHAR2     -- データ種類
   ,iv_tax_code                     IN     VARCHAR2     -- 税コード
   ,iv_order_list_date_from         IN     VARCHAR2     -- 開始日
   ,iv_order_list_date_to           IN     VARCHAR2     -- 出力基準日
   ,iv_content                      IN     VARCHAR2     -- 内容
   ,iv_decision_no                  IN     VARCHAR2     -- 決裁No
   ,iv_agreement_no                 IN     VARCHAR2     -- 契約番号
   ,iv_last_update_date             IN     VARCHAR2     -- 最終更新日
   ,ov_errbuf                       OUT    VARCHAR2     -- エラー・メッセージ           --# 固定 #
   ,ov_retcode                      OUT    VARCHAR2     -- リターン・コード             --# 固定 #
   ,ov_errmsg                       OUT    VARCHAR2     -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- プログラム名
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
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  固定部 END   ############################
--
    -- 対象データ取得
    OPEN get_deduction_list_data_cur (
           iv_order_deduction_no           -- 控除番号
          ,iv_corp_code                    -- 企業コード
          ,iv_introduction_code            -- 控除用チェーンコード
          ,iv_ship_cust_code               -- 顧客コード
          ,iv_data_type                    -- データ種類
          ,iv_tax_code                     -- 税コード
          ,iv_order_list_date_from         -- 開始日
          ,iv_order_list_date_to           -- 終了日
          ,iv_content                      -- 内容
          ,iv_decision_no                  -- 決裁No
          ,iv_agreement_no                 -- 契約番号
          ,iv_last_update_date             -- 最終更新日
          );
    FETCH get_deduction_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_deduction_list_data_cur;
    -- 処理件数カウント
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- 抽出データが0件だった場合警告
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
      IF get_deduction_list_data_cur%ISOPEN THEN
        CLOSE get_deduction_list_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);     -- リターン・コード
    lv_errmsg     VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_code_eoh_024a02    CONSTANT  VARCHAR2(100)                       := '024A02%';                       -- クイックコード（控除マスタ出力用見出し）
--
    -- *** ローカル変数 ***
    lv_line_data              VARCHAR2(5000);         -- OUTPUTデータ編集用
--
    -- *** ローカル・カーソル ***
    --見出し取得用カーソル
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                             -- 摘要：出力用見出し
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                     -- 言語
      AND     flv.lookup_type     = cv_type_header                              -- 控除マスタ出力用見出し
      AND     flv.lookup_code  LIKE cv_code_eoh_024a02                          -- クイックコード（控除マスタ出力用見出し）
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_proc_date )  -- 有効開始日
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_proc_date )  -- 有効終了日
      AND     flv.enabled_flag    = cv_const_y                                  -- 使用可能
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --見出し
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------------
    -- 見出しの出力
    ------------------------------------------
    -- データの見出しを取得
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --データの見出しを編集
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --データの見出しを出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- データ出力
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      --データを編集
      lv_line_data :=     cv_null                                                     -- 処理区分
         || cv_delimit || gt_out_file_tab(i).condition_no                             -- 控除番号
         || cv_delimit || gt_out_file_tab(i).corp_code                                -- 企業コード
         || cv_delimit || gt_out_file_tab(i).deduction_chain_code                     -- 控除用チェーンコード
         || cv_delimit || gt_out_file_tab(i).customer_code                            -- 顧客コード
         || cv_delimit || gt_out_file_tab(i).data_type                                -- データ種類
         || cv_delimit || gt_out_file_tab(i).tax_code                                 -- 税コード
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).start_date_active,cv_date_format)  -- 開始日
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).end_date_active,cv_date_format)    -- 終了日
         || cv_delimit || gt_out_file_tab(i).content                                  -- 内容
         || cv_delimit || gt_out_file_tab(i).decision_no                              -- 決裁No
         || cv_delimit || gt_out_file_tab(i).agreement_no                             -- 契約番号
         || cv_delimit || gt_out_file_tab(i).detail_number                            -- 明細番号
         || cv_delimit || gt_out_file_tab(i).target_category                          -- 対象区分
         || cv_delimit || gt_out_file_tab(i).product_class                            -- 商品区分
         || cv_delimit || gt_out_file_tab(i).item_code                                -- 品目コード
         || cv_delimit || gt_out_file_tab(i).uom_code                                 -- 単位
         || cv_delimit || gt_out_file_tab(i).shop_pay_1                               -- 店納(%)
         || cv_delimit || gt_out_file_tab(i).material_rate                            -- 料率(%)
         || cv_delimit || gt_out_file_tab(i).demand_en                                -- 請求(円)
         || cv_delimit || gt_out_file_tab(i).shop_pay_en                              -- 店納(円)
         || cv_delimit || gt_out_file_tab(i).wholesale_margin_en                      -- 問屋マージン(円)
         || cv_delimit || gt_out_file_tab(i).wholesale_margin_per                     -- 問屋マージン(％)
         || cv_delimit || gt_out_file_tab(i).normal_shop_pay_en                       -- 通常店納(円)
         || cv_delimit || gt_out_file_tab(i).just_shop_pay_en                         -- 今回店納(円)
         || cv_delimit || gt_out_file_tab(i).wholesale_adj_margin_en                  -- 問屋マージン修正(円)
         || cv_delimit || gt_out_file_tab(i).wholesale_adj_margin_per                 -- 問屋マージン修正(％)
         || cv_delimit || gt_out_file_tab(i).prediction_qty                           -- 予測数量(本)
         || cv_delimit || gt_out_file_tab(i).support_amount_sum_en                    -- 協賛金合計(円)
         || cv_delimit || gt_out_file_tab(i).condition_unit_price_en                  -- 条件単価(円)
         || cv_delimit || gt_out_file_tab(i).target_rate6                             -- 対象率(％)
-- 2021/04/06 Ver1.1 MOD Start
         --|| cv_delimit || gt_out_file_tab(i).accounting_base                          -- 計上拠点
         || cv_delimit || gt_out_file_tab(i).accounting_customer_code                 -- 計上顧客
-- 2021/04/06 Ver1.1 MOD End
         || cv_delimit || gt_out_file_tab(i).deduction_amount                         -- 控除額(本体)
         || cv_delimit || gt_out_file_tab(i).deduction_tax_amount                     -- 控除税額
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).head_last_update_date,cv_date_format_time)                          -- ヘッダ最終更新日
         || cv_delimit || gt_out_file_tab(i).head_employee_number|| cv_full_space 
         ||gt_out_file_tab(i).head_last_update_by_last || cv_half_space || gt_out_file_tab(i).head_last_update_by_first  -- ヘッダ最終更新者
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).line_last_update_date,cv_date_format_time)                          -- 明細最終更新日
         || cv_delimit || gt_out_file_tab(i).line_employee_number|| cv_full_space 
         ||gt_out_file_tab(i).line_last_update_by_last || cv_half_space || gt_out_file_tab(i).line_last_update_by_first  -- 明細最終更新者
      ;
      -- データを出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      -- 成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( iv_order_deduction_no           IN     VARCHAR2  -- 控除番号
                    ,iv_corp_code                    IN     VARCHAR2  -- 企業コード
                    ,iv_introduction_code            IN     VARCHAR2  -- 控除用チェーンコード
                    ,iv_ship_cust_code               IN     VARCHAR2  -- 顧客コード
                    ,iv_data_type                    IN     VARCHAR2  -- データ種類
                    ,iv_tax_code                     IN     VARCHAR2  -- 税コード
                    ,iv_order_list_date_from         IN     VARCHAR2  -- 開始日
                    ,iv_order_list_date_to           IN     VARCHAR2  -- 終了日
                    ,iv_content                      IN     VARCHAR2  -- 内容
                    ,iv_decision_no                  IN     VARCHAR2  -- 決裁No
                    ,iv_agreement_no                 IN     VARCHAR2  -- 契約番号
                    ,iv_last_update_date             IN     VARCHAR2  -- 最終更新日
                    ,ov_errbuf                       OUT    VARCHAR2  -- エラー・メッセージ           --# 固定 #
                    ,ov_retcode                      OUT    VARCHAR2  -- リターン・コード             --# 固定 #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init( iv_order_deduction_no          -- 控除番号
         ,iv_corp_code                   -- 企業コード
         ,iv_introduction_code           -- 控除用チェーンコード
         ,iv_ship_cust_code              -- 顧客コード
         ,iv_data_type                   -- データ種類
         ,iv_tax_code                    -- 税コード
         ,iv_order_list_date_from        -- 開始日
         ,iv_order_list_date_to          -- 終了日
         ,iv_content                     -- 内容
         ,iv_decision_no                 -- 決裁No
         ,iv_agreement_no                -- 契約番号
         ,iv_last_update_date            -- 最終更新日
         ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
         ,lv_retcode                     -- リターン・コード             --# 固定 #
         ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  控除マスタ抽出
    -- ===============================
    get_order_list_cond( iv_order_deduction_no        -- 控除番号
                        ,iv_corp_code                 -- 企業コード
                        ,iv_introduction_code         -- 控除用チェーンコード
                        ,iv_ship_cust_code            -- 顧客コード
                        ,iv_data_type                 -- データ種類
                        ,iv_tax_code                  -- 税コード
                        ,iv_order_list_date_from      -- 開始日
                        ,iv_order_list_date_to        -- 終了日
                        ,iv_content                   -- 内容
                        ,iv_decision_no               -- 決裁No
                        ,iv_agreement_no              -- 契約番号
                        ,iv_last_update_date          -- 最終更新日
                        ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
                        ,lv_retcode                   -- リターン・コード             --# 固定 #
                        ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
                        );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- A-3  データ出力
    -- ===============================
    output_data(
      lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
      lv_retcode,                   -- リターン・コード             --# 固定 #
      lv_errmsg                     -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    -- *** 警告ハンドラ ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_order_deduction_no           IN     VARCHAR2          -- 控除番号
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_introduction_code            IN     VARCHAR2          -- 控除用チェーンコード
   ,iv_ship_cust_code               IN     VARCHAR2          -- 顧客コード
   ,iv_data_type                    IN     VARCHAR2          -- データ種類
   ,iv_tax_code                     IN     VARCHAR2          -- 税コード
   ,iv_order_list_date_from         IN     VARCHAR2          -- 開始日
   ,iv_order_list_date_to           IN     VARCHAR2          -- 終了日
   ,iv_content                      IN     VARCHAR2          -- 内容
   ,iv_decision_no                  IN     VARCHAR2          -- 決裁No
   ,iv_agreement_no                 IN     VARCHAR2          -- 契約番号
   ,iv_last_update_date             IN     VARCHAR2          -- 最終更新日
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_order_deduction_no           -- 控除番号
      ,iv_corp_code                    -- 企業コード
      ,iv_introduction_code            -- 控除用チェーンコード
      ,iv_ship_cust_code               -- 顧客コード
      ,iv_data_type                    -- データ種類
      ,iv_tax_code                     -- 税コード
      ,iv_order_list_date_from         -- 開始日
      ,iv_order_list_date_to           -- 終了日
      ,iv_content                      -- 内容
      ,iv_decision_no                  -- 決裁No
      ,iv_agreement_no                 -- 契約番号
      ,iv_last_update_date             -- 最終更新日
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================
    -- A-4.終了処理
    -- ===============================
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --エラーの場合成功件数クリア、エラー件数固定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
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
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    IF ( retcode = cv_status_error ) THEN
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
END XXCOK024A02C;
/