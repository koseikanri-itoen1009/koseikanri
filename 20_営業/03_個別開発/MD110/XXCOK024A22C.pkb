CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A22C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A22C (body)
 * Description      : 売上実績振替情報と控除マスタ元に顧客、商品、控除条件ごとに
 *                  : 控除データの控除金額を算出し、販売控除情報へ登録します。
 * MD.050           : 実績振替・販売控除データの作成（EDI） MD050_COK_024_A22
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.初期処理
 *  get_data               A-2.実績振替データ抽出
 *  sell_trns_cul          A-3.実績振替控除データ算出
 *  insert_deduction       A-4.販売控除データ登録
 *  update_sls_dedu_ctrl   A-5.販売控除管理情報更新
 *  submain                メイン処理プロシージャ
 *  main                   販売控除データ作成プロシージャ(A-6.終了処理を含む)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/04/14    1.0   M.Sato           新規作成
 *  2020/12/03    1.1   SCSK Y.Koh       [E_本稼動_16026]
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
  gv_out_msg       VARCHAR2(2000);            -- 出力メッセージ
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A22C';             -- パッケージ名
  -- アプリケーション短縮名
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                    -- 共通領域短縮アプリ名
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                    -- 個別開発領域短縮アプリ名
  -- メッセージ名称
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';         -- 対象データなしエラーメッセージ
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';         -- 業務日付取得エラー
  cv_last_process_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10592';         -- 前回処理ID取得エラー
  cv_dedc_calc_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10685';         -- 控除額算出エラー
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10632';         -- ロックエラーメッセージ
  cv_target_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';         -- 対象件数メッセージ
  cv_success_rec_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';         -- 成功件数メッセージ
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';         -- エラー件数メッセージ
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';         -- スキップ件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';         -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';         -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';         -- エラー終了全ロールバック
  -- トークン
  cv_tkn_condition_no       CONSTANT VARCHAR2(20) := 'CONDITION_NO';             -- 控除番号
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                    -- 件数メッセージ用トークン名
  cv_tkn_line_id            CONSTANT VARCHAR2(15) := 'SOURCE_TRAN_ID';           -- 売上実績振替情報IDのトークン名
  cv_tkn_item_code          CONSTANT VARCHAR2(15) := 'ITEM_CODE';                -- 品目コードのトークン名
  cv_tkn_sales_uom_code     CONSTANT VARCHAR2(15) := 'SALES_UOM_CODE';           -- 販売単位のトークン名
  cv_tkn_base_code          CONSTANT VARCHAR2(15) := 'BASE_CODE';                -- 担当拠点のトークン名
  cv_tkn_errmsg             CONSTANT VARCHAR2(15) := 'ERRMSG';                   -- エラーメッセージのトークン名
  -- フラグ・区分定数
  cv_y_flag                 CONSTANT VARCHAR2(1) := 'Y';                         -- フラグ値:Y
  -- 販売控除連携管理情報に使用する固定値
  cv_control_flag           CONSTANT VARCHAR2(1) := 'T';                         -- 管理情報フラグ
  -- 実績振替情報データ抽出で使用する固定値
  cv_cate_set_name          CONSTANT VARCHAR2(20) := '本社商品区分';             -- 品目カテゴリセット名
  cv_sls_dedc_tgt           CONSTANT VARCHAR2(1) := 'Y';                         -- 販売控除作成対象
  cv_rep_deci_flag          CONSTANT VARCHAR2(1) := '1';                         -- 速報確定フラグ
  cv_sell_trns_type         CONSTANT VARCHAR2(1) := '1';                         -- 実績振替区分
  cv_ded_type_010           CONSTANT VARCHAR2(3) := '010';                       -- 控除タイプ
  -- 販売控除情報テーブルに設定する固定値
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'T';                        -- 作成元区分
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                        -- ステータス
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- GL連携フラグ
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- 取消フラグ
  cv_ins_rep_deci_flag      CONSTANT  VARCHAR2(1) := '1';                        -- 速報確定フラグ
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期取得
  gn_last_process_id          NUMBER;                                            -- 前回売上実績振替情報ID
  --
  gn_max_selling_trns_info_id NUMBER;                                            -- 売上実績振替情報IDの最大値                                                                                    -- 前回売上実績振替情報ID最大値
  -- 
  gv_deduction_uom_code       VARCHAR2(3);                                       -- 控除単位
  gn_deduction_unit_price     NUMBER;                                            -- 控除単価
  gn_deduction_quantity       NUMBER;                                            -- 控除数量
  gn_deduction_amount         NUMBER;                                            -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation             NUMBER;                                            -- 補填
  gn_margin                   NUMBER;                                            -- 問屋マージン
  gn_sales_promotion_expenses NUMBER;                                            -- 拡売
  gn_margin_reduction         NUMBER;                                            -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount     NUMBER;                                            -- 控除税額
  gv_tax_code                 VARCHAR2(4);                                       -- 税コード
  gn_tax_rate                 NUMBER;                                            -- 税率
  --
  -- ===============================
  -- ユーザー定義グローバルカーソル (実績振替情報データ抽出)
  -- ===============================
  CURSOR g_selling_trns_cur
  IS
  WITH
   flvc1 AS
      ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
        FROM   fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_TYPE'  -- 控除タイプ
        AND   flvc.language     = 'JA'
        AND   flvc.enabled_flag = cv_y_flag
        AND   flvc.attribute1   = cv_y_flag            )   -- 販売控除作成対象
   ,flvc3 AS
      ( SELECT /*+ MATERIALIZED */ lookup_code AS lookup_code
        FROM   fnd_lookup_values flvc
        WHERE   flvc.lookup_type  = 'XXCMM_CUST_GYOTAI_SHO'  -- 業態(小分類)
        AND   flvc.language     = 'JA'
        AND   flvc.enabled_flag = cv_y_flag
        AND   flvc.attribute2   = cv_sls_dedc_tgt      )   -- 販売控除作成対象外
    SELECT /*+ leading(xsi)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                 AS base_code                    -- 振替先拠点
          ,xsi.cust_code                 AS cust_code                    -- 振替先顧客
          ,xsi.selling_date              AS selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                 AS item_code                    -- 品目コード
          ,xsi.unit_type                 AS unit_type                    -- 納品単位
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- 納品単価
          ,xsi.qty                       AS qty                          -- 数量
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                  AS tax_code_trn                 -- 消費税コード
          ,xsi.tax_rate                  AS tax_rate_trn                 -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- 消費税額
          ,xch.condition_id              AS condition_id                 -- 控除条件ID
          ,xch.condition_no              AS condition_no                 -- 控除番号
          ,xch.corp_code                 AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code      AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code             AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                 AS data_type                    -- データ種類
          ,xch.tax_code                  AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                  AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                AS attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code            AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id         AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class             AS product_class                -- 商品区分
          ,xcl.item_code                 AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                  AS uom_code                     -- 単位(条件)
          ,xcl.target_category           AS target_category              -- 対象区分
          ,xcl.shop_pay_1                AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1           AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2               AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- 売上実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- チェーン店
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code(+)            = xca.intro_chain_code2
           AND   flv.language(+)               = 'JA'
           AND   flv.enabled_flag(+)           = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   xsi.cust_code                 = xch.customer_code
           AND   xch.customer_code        IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    UNION ALL
    SELECT /*+ leading(xsi)
           use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                 AS base_code                    -- 振替先拠点
          ,xsi.cust_code                 AS cust_code                    -- 振替先顧客
          ,xsi.selling_date              AS selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                 AS item_code                    -- 品目コード
          ,xsi.unit_type                 AS unit_type                    -- 納品単位
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- 納品単価
          ,xsi.qty                       AS qty                          -- 数量
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                  AS tax_code_trn                 -- 消費税コード
          ,xsi.tax_rate                  AS tax_rate_trn                 -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- 消費税額
          ,xch.condition_id              AS condition_id                 -- 控除条件ID
          ,xch.condition_no              AS condition_no                 -- 控除番号
          ,xch.corp_code                 AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code      AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code             AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                 AS data_type                    -- データ種類
          ,xch.tax_code                  AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                  AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                AS attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code            AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id         AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class             AS product_class                -- 商品区分
          ,xcl.item_code                 AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                  AS uom_code                     -- 単位(条件)
          ,xcl.target_category           AS target_category              -- 対象区分
          ,xcl.shop_pay_1                AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1           AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2               AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- 売上実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- チェーン店
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code(+)            = xca.intro_chain_code2
           AND   flv.language(+)               = 'JA'
           AND   flv.enabled_flag(+)           = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   xca.intro_chain_code2         = xch.deduction_chain_code
           AND   xch.deduction_chain_code IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    UNION ALL
    SELECT /*+ leading(xsi)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl) 
           */
           xsi.delivery_base_code        AS delivery_base_code           -- 振替元拠点
          ,xsi.selling_from_cust_code    AS selling_from_cust_code       -- 振替元顧客
          ,xsi.base_code                 AS base_code                    -- 振替先拠点
          ,xsi.cust_code                 AS cust_code                    -- 振替先顧客
          ,xsi.selling_date              AS selling_date                 -- 売上計上日
          ,xsi.selling_trns_info_id      AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xsi.item_code                 AS item_code                    -- 品目コード
          ,xsi.unit_type                 AS unit_type                    -- 納品単位
          ,xsi.delivery_unit_price       AS delivery_unit_price          -- 納品単価
          ,xsi.qty                       AS qty                          -- 数量
          ,xsi.selling_amt_no_tax        AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xsi.tax_code                  AS tax_code_trn                 -- 消費税コード
          ,xsi.tax_rate                  AS tax_rate_trn                 -- 消費税率
          ,xsi.selling_amt - xsi.selling_amt_no_tax
                                         AS tax_amount                   -- 消費税額
          ,xch.condition_id              AS condition_id                 -- 控除条件ID
          ,xch.condition_no              AS condition_no                 -- 控除番号
          ,xch.corp_code                 AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code      AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code             AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                 AS data_type                    -- データ種類
          ,xch.tax_code                  AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                  AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                AS attribute3                   -- 本部担当拠点(チェーン店)
          ,xca.sale_base_code            AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id         AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class             AS product_class                -- 商品区分
          ,xcl.item_code                 AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                  AS uom_code                     -- 単位(条件)
          ,xcl.target_category           AS target_category              -- 対象区分
          ,xcl.shop_pay_1                AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1           AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2 AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3              AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3         AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3     AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4              AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4       AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4 AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5 AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6 AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2               AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_edi_sell_trns      xsi                             -- 売上実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- チェーン店
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,flvc1                         d_typ
          ,flvc3                         gyotai_sho
           WHERE xsi.selling_trns_info_id      > gn_last_process_id
           AND   xsi.report_decision_flag      = cv_rep_deci_flag
           AND   xsi.selling_trns_type         = cv_sell_trns_type
           AND   xca.customer_code             = xsi.cust_code
           AND   xca.business_low_type         = gyotai_sho.lookup_code
           AND   flv.lookup_type               = 'XXCMM_CHAIN_CODE'
           AND   flv.lookup_code               = xca.intro_chain_code2
           AND   flv.language                  = 'JA'
           AND   flv.enabled_flag              = cv_y_flag
           AND   xch.enabled_flag_h            = cv_y_flag
           AND   flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
           AND   flv2.lookup_code              = xch.data_type
           AND   flv2.language                 = 'JA'
           AND   flv2.enabled_flag             = cv_y_flag
           AND   flv2.attribute2               = d_typ.lookup_code
           AND   flv.attribute1                = xch.corp_code
           AND   xch.corp_code            IS NOT NULL
           AND   xsi.selling_date        BETWEEN xch.start_date_active
                                             AND xch.end_date_active
           AND   xcl.condition_id              = xch.condition_id
           AND   xcl.enabled_flag_l            = cv_y_flag
           AND ( xsi.item_code                 = xcl.item_code
           OR    xsi.product_class             = xcl.product_class )
    ;
    -- カーソルレコード取得用
    g_selling_trns_rec          g_selling_trns_cur%ROWTYPE;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.初期処理
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                      -- プログラム名
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
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
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
    -- 売上実績振替情報ID取得
    --==================================
    --
    BEGIN
      -- 前回処理済みの売上実績振替情報IDを取得
      SELECT xsds.last_processing_id          AS last_processing_id
      INTO   gn_last_process_id
      FROM
             xxcok_sales_deduction_control    xsds
      WHERE  xsds.control_flag                = cv_control_flag
      FOR UPDATE OF xsds.last_processing_id NOWAIT
      ;
--
      SELECT MAX(xsti.selling_trns_info_id) AS max_selling_trns_info_id
      INTO   gn_max_selling_trns_info_id
      FROM   xxcok_dedu_edi_sell_trns  xsti
      WHERE  xsti.selling_trns_info_id  > gn_last_process_id
      ;
--
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        -- ロックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                              ,cv_table_lock_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      --
      WHEN  OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                               ,cv_last_process_msg
                                               );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
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
--#################################  固定例外処理部 END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : sell_trns_cul
   * Description      : A-3.実績振替控除データ算出
   ***********************************************************************************/
  PROCEDURE sell_trns_cul(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'sell_trns_cul';                                 -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_base_code    VARCHAR2(100);                          -- 控除額算出エラーメッセージ用
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
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
    -- ============================================================
    -- 共通関数 控除額算出
    -- ============================================================
    xxcok_common2_pkg.calculate_deduction_amount_p(
      ov_errbuf                     =>  lv_errbuf                                     -- エラーバッファ
     ,ov_retcode                    =>  lv_retcode                                    -- リターンコード
     ,ov_errmsg                     =>  lv_errmsg                                     -- エラーメッセージ
     ,iv_item_code                  =>  g_selling_trns_rec.item_code                  -- 品目コード
     ,iv_sales_uom_code             =>  g_selling_trns_rec.unit_type                  -- 販売単位
     ,in_sales_quantity             =>  g_selling_trns_rec.qty                        -- 販売数量
     ,in_sale_pure_amount           =>  g_selling_trns_rec.selling_amt_no_tax         -- 売上本体金額
     ,iv_tax_code_trn               =>  g_selling_trns_rec.tax_code_trn               -- 税コード(TRN)
     ,in_tax_rate_trn               =>  g_selling_trns_rec.tax_rate_trn               -- 税率(TRN)
     ,iv_deduction_type             =>  g_selling_trns_rec.attribute2                 -- 控除タイプ
     ,iv_uom_code                   =>  g_selling_trns_rec.uom_code                   -- 単位(条件)
     ,iv_target_category            =>  g_selling_trns_rec.target_category            -- 対象区分
     ,in_shop_pay_1                 =>  g_selling_trns_rec.shop_pay_1                 -- 店納(％)
     ,in_material_rate_1            =>  g_selling_trns_rec.material_rate_1            -- 料率(％)
     ,in_condition_unit_price_en_2  =>  g_selling_trns_rec.condition_unit_price_en_2  -- 条件単価２(円)
     ,in_accrued_en_3               =>  g_selling_trns_rec.accrued_en_3               -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
     ,in_compensation_en_3          =>  g_selling_trns_rec.compensation_en_3          -- 補填(円)
     ,in_wholesale_margin_en_3      =>  g_selling_trns_rec.wholesale_margin_en_3      -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
     ,in_accrued_en_4               =>  g_selling_trns_rec.accrued_en_4               -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
     ,in_just_condition_en_4        =>  g_selling_trns_rec.just_condition_en_4        -- 今回条件(円)
     ,in_wholesale_adj_margin_en_4  =>  g_selling_trns_rec.wholesale_adj_margin_en_4  -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
     ,in_condition_unit_price_en_5  =>  g_selling_trns_rec.condition_unit_price_en_5  -- 条件単価５(円)
     ,in_deduction_unit_price_en_6  =>  g_selling_trns_rec.deduction_unit_price_en_6  -- 控除単価(円)
     ,iv_tax_code_mst               =>  g_selling_trns_rec.tax_code_mst               -- 税コード(MST)
     ,in_tax_rate_mst               =>  g_selling_trns_rec.tax_rate_mst               -- 税率(MST)
     ,ov_deduction_uom_code         =>  gv_deduction_uom_code                         -- 控除単位
     ,on_deduction_unit_price       =>  gn_deduction_unit_price                       -- 控除単価
     ,on_deduction_quantity         =>  gn_deduction_quantity                         -- 控除数量
     ,on_deduction_amount           =>  gn_deduction_amount                           -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
     ,on_compensation               =>  gn_compensation                               -- 補填
     ,on_margin                     =>  gn_margin                                     -- 問屋マージン
     ,on_sales_promotion_expenses   =>  gn_sales_promotion_expenses                   -- 拡売
     ,on_margin_reduction           =>  gn_margin_reduction                           -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
     ,on_deduction_tax_amount       =>  gn_deduction_tax_amount                       -- 控除税額
     ,ov_tax_code                   =>  gv_tax_code                                   -- 税コード
     ,on_tax_rate                   =>  gn_tax_rate                                   -- 税率
    );
--
    -- 控除額算出が正常終了でない場合
    IF ( lv_retcode  !=  cv_status_normal ) THEN
      -- 企業コードがNULL以外の場合
      IF ( g_selling_trns_rec.corp_code IS  NOT NULL ) THEN
        SELECT  MAX(ffv.attribute2) AS base_code                                      -- 本部担当拠点(企業)
        INTO    lv_base_code
        FROM    fnd_flex_values     ffv
               ,fnd_flex_value_sets ffvs
        WHERE   ffvs.flex_value_set_name  = 'XX03_BUSINESS_TYPE'
        AND     ffv.flex_value_set_id     = ffvs.flex_value_set_id
        AND     ffv.flex_value            = g_selling_trns_rec.corp_code;
      -- 控除用チェーンコードがNULL以外の場合
      ELSIF ( g_selling_trns_rec.deduction_chain_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.attribute3;                              -- 本部担当拠点(チェーン店)
      -- 顧客コード(条件)がNULL以外の場合
      ELSIF ( g_selling_trns_rec.customer_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.sale_base_code;                          -- 売上拠点(顧客)
      END IF;
      -- 控除額算出エラーメッセージの出力
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_xxcok_short_nm
                     ,cv_dedc_calc_msg
                     ,cv_tkn_line_id
                     ,g_selling_trns_rec.selling_trns_info_id
                     ,cv_tkn_item_code
                     ,g_selling_trns_rec.item_code
                     ,cv_tkn_sales_uom_code
                     ,g_selling_trns_rec.unit_type
                     ,cv_tkn_condition_no
                     ,g_selling_trns_rec.condition_no
                     ,cv_tkn_base_code
                     ,lv_base_code
                     ,cv_tkn_errmsg
                     ,lv_errmsg
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg                --ユーザー・エラーメッセージ
        );
--
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
  END sell_trns_cul;
--
  /**********************************************************************************
   * Procedure Name   : insert_deduction
   * Description      : A-4.販売控除データ登録
   ***********************************************************************************/
  PROCEDURE insert_deduction(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_deduction';          -- プログラム名
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
--
    -- *** ローカル変数 ***
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
    -- 販売控除データを登録する
    INSERT INTO xxcok_sales_deduction(
         sales_deduction_id                                               -- 販売控除ID
        ,base_code_from                                                   -- 振替元拠点
        ,base_code_to                                                     -- 振替先拠点
        ,customer_code_from                                               -- 振替元顧客コード
        ,customer_code_to                                                 -- 振替先顧客コード
-- 2020/12/03 Ver1.1 ADD Start
        ,deduction_chain_code                                             -- 控除用チェーンコード
        ,corp_code                                                        -- 企業コード
-- 2020/12/03 Ver1.1 ADD End
        ,record_date                                                      -- 計上日
        ,source_category                                                  -- 作成元区分
        ,source_line_id                                                   -- 作成元明細ID
        ,condition_id                                                     -- 控除条件ID
        ,condition_no                                                     -- 控除番号
        ,condition_line_id                                                -- 控除詳細ID
        ,data_type                                                        -- データ種類
        ,status                                                           -- ステータス
        ,item_code                                                        -- 品目コード
        ,sales_uom_code                                                   -- 販売単位
        ,sales_unit_price                                                 -- 販売単価
        ,sales_quantity                                                   -- 販売数量
        ,sale_pure_amount                                                 -- 売上本体金額
        ,sale_tax_amount                                                  -- 売上消費税額
        ,deduction_uom_code                                               -- 控除単位
        ,deduction_unit_price                                             -- 控除単価
        ,deduction_quantity                                               -- 控除数量
        ,deduction_amount                                                 -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
        ,compensation                                                     -- 補填
        ,margin                                                           -- 問屋マージン
        ,sales_promotion_expenses                                         -- 拡売
        ,margin_reduction                                                 -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
        ,tax_code                                                         -- 税コード
        ,tax_rate                                                         -- 税率
        ,recon_tax_code                                                   -- 消込時税コード
        ,recon_tax_rate                                                   -- 消込時税率
        ,deduction_tax_amount                                             -- 控除税額
        ,remarks                                                          -- 備考
        ,application_no                                                   -- 申請書No.
        ,gl_if_flag                                                       -- GL連携フラグ
        ,gl_base_code                                                     -- GL計上拠点
        ,gl_date                                                          -- GL記帳日
-- 2020/12/03 Ver1.1 MOD Start
        ,recovery_date                                                    -- リカバリデータ追加時日付
        ,recovery_add_request_id                                          -- リカバリデータ追加時要求ID
        ,recovery_del_date                                                -- リカバリデータ削除時日付
        ,recovery_del_request_id                                          -- リカバリデータ削除時要求ID
--        ,recovery_date                                                    -- リカバリー日付
-- 2020/12/03 Ver1.1 MOD End
        ,cancel_flag                                                      -- 取消フラグ
        ,cancel_base_code                                                 -- 取消時計上拠点
        ,cancel_gl_date                                                   -- 取消GL記帳日
        ,cancel_user                                                      -- 取消実施ユーザ
        ,recon_base_code                                                  -- 消込時計上拠点
        ,recon_slip_num                                                   -- 支払伝票番号
        ,carry_payment_slip_num                                           -- 繰越時支払伝票番号
        ,report_decision_flag                                             -- 速報確定フラグ
        ,gl_interface_id                                                  -- GL連携ID
        ,cancel_gl_interface_id                                           -- 取消GL連携ID
        ,created_by                                                       -- 作成者
        ,creation_date                                                    -- 作成日
        ,last_updated_by                                                  -- 最終更新者
        ,last_update_date                                                 -- 最終更新日
        ,last_update_login                                                -- 最終更新ログイン
        ,request_id                                                       -- 要求ID
        ,program_application_id                                           -- コンカレント・プログラム・アプリケーションID
        ,program_id                                                       -- コンカレント・プログラムID
        ,program_update_date                                              -- プログラム更新日
      )VALUES(
         xxcok_sales_deduction_s01.nextval                                -- 販売控除ID
        ,g_selling_trns_rec.delivery_base_code                            -- 振替元拠点
        ,g_selling_trns_rec.base_code                                     -- 振替先拠点
        ,g_selling_trns_rec.selling_from_cust_code                        -- 振替元顧客コード
        ,g_selling_trns_rec.cust_code                                     -- 振替先顧客コード
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- 控除用チェーンコード
        ,NULL                                                             -- 企業コード
-- 2020/12/03 Ver1.1 ADD End
        ,g_selling_trns_rec.selling_date                                  -- 計上日
        ,cv_created_sec                                                   -- 作成元区分
        ,g_selling_trns_rec.selling_trns_info_id                          -- 作成元明細ID
        ,g_selling_trns_rec.condition_id                                  -- 控除条件ID
        ,g_selling_trns_rec.condition_no                                  -- 控除番号
        ,g_selling_trns_rec.condition_line_id                             -- 控除詳細ID
        ,g_selling_trns_rec.data_type                                     -- データ種類
        ,cv_status                                                        -- ステータス
        ,g_selling_trns_rec.item_code                                     -- 品目コード
        ,g_selling_trns_rec.unit_type                                     -- 販売単位
        ,g_selling_trns_rec.delivery_unit_price                           -- 販売単価
        ,g_selling_trns_rec.qty                                           -- 販売数量
        ,g_selling_trns_rec.selling_amt_no_tax                            -- 売上本体金額
        ,g_selling_trns_rec.tax_amount                                    -- 売上消費税額
        ,gv_deduction_uom_code                                            -- 控除単位
        ,gn_deduction_unit_price                                          -- 控除単価
        ,gn_deduction_quantity                                            -- 控除数量
        ,gn_deduction_amount                                              -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
        ,gn_compensation                                                  -- 補填
        ,gn_margin                                                        -- 問屋マージン
        ,gn_sales_promotion_expenses                                      -- 拡売
        ,gn_margin_reduction                                              -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
        ,gv_tax_code                                                      -- 税コード
        ,gn_tax_rate                                                      -- 税率
        ,NULL                                                             -- 消込時税コード
        ,NULL                                                             -- 消込時税率
        ,gn_deduction_tax_amount                                          -- 控除税額
        ,NULL                                                             -- 備考
        ,NULL                                                             -- 申請書No.
        ,cv_gl_rel_flag                                                   -- GL連携フラグ
        ,NULL                                                             -- GL計上拠点
        ,NULL                                                             -- GL記帳日
-- 2020/12/03 Ver1.1 MOD Start
        ,NULL                                                             -- リカバリデータ追加時日付
        ,NULL                                                             -- リカバリデータ追加時要求ID
        ,NULL                                                             -- リカバリデータ削除時日付
        ,NULL                                                             -- リカバリデータ削除時要求ID
--        ,NULL                                                             -- リカバリー日付
-- 2020/12/03 Ver1.1 MOD End
        ,cv_cancel_flag                                                   -- 取消フラグ
        ,NULL                                                             -- 取消時計上拠点
        ,NULL                                                             -- 取消GL記帳日
        ,NULL                                                             -- 取消実施ユーザ
        ,NULL                                                             -- 消込時計上拠点
        ,NULL                                                             -- 支払伝票番号
        ,NULL                                                             -- 繰越時支払伝票番号
        ,cv_ins_rep_deci_flag                                             -- 速報確定フラグ
        ,NULL                                                             -- GL連携ID
        ,NULL                                                             -- 取消GL連携ID
        ,cn_created_by                                                    -- 作成者
        ,cd_creation_date                                                 -- 作成日
        ,cn_last_updated_by                                               -- 最終更新者
        ,cd_last_update_date                                              -- 最終更新日
        ,cn_last_update_login                                             -- 最終更新ログイン
        ,cn_request_id                                                    -- 要求ID
        ,cn_program_application_id                                        -- コンカレント・プログラム・アプリケーションID
        ,cn_program_id                                                    -- コンカレント・プログラムID
        ,cd_program_update_date                                           -- プログラム更新日
    );
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
--#################################  固定例外処理部 END  #################################
--
  END insert_deduction;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-2.実績振替データ抽出
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                     ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                     ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data';                  -- プログラム名
--
--############################  固定ローカル変数宣言部 START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode VARCHAR2(1);          -- リターン・コード
    lv_errmsg  VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#############################  固定ローカル変数宣言部 END  #############################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル***
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
    OPEN  g_selling_trns_cur;
    -- データ取得
    FETCH g_selling_trns_cur INTO g_selling_trns_rec;
--
    -- 取得データが０件の場合
    IF ( g_selling_trns_cur%NOTFOUND )  THEN
      -- 警告ステータスの格納
      ov_retcode := cv_status_warn;
      -- 対象なしメッセージの出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
      );
    END IF;
--
    LOOP
      EXIT  WHEN  g_selling_trns_cur%NOTFOUND;
      --
      lv_retcode  :=  cv_status_normal;                   -- ステータスを初期化
      -- 対象件数をインクリメント
      gn_target_cnt :=  gn_target_cnt + 1;
      -- ============================================================
      -- A-3.販売控除データ算出の呼び出し
      -- ============================================================
      sell_trns_cul(
        ov_errbuf   =>  lv_errbuf                       -- エラー・メッセージ
       ,ov_retcode  =>  lv_retcode                      -- リターン・コード
       ,ov_errmsg   =>  lv_errmsg                       -- ユーザー・エラー・メッセージ
       );
--
      -- 販売控除データ算出が正常終了した場合
      IF ( lv_retcode  = cv_status_normal ) THEN
        -- ============================================================
        -- A-4.販売控除データ登録の呼び出し
        -- ============================================================
        insert_deduction(
          ov_errbuf   =>  lv_errbuf                     -- エラー・メッセージ
         ,ov_retcode  =>  lv_retcode                    -- リターン・コード
         ,ov_errmsg   =>  lv_errmsg                     -- ユーザー・エラー・メッセージ
         );
--
        -- データ登録が正常終了した場合
        IF ( lv_retcode = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
      -- 販売控除データ算出で警告発生時
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt   + 1;
      ELSE
        RAISE global_process_expt;
      END IF;
      -- 次のデータを取得
      FETCH g_selling_trns_cur INTO g_selling_trns_rec;
    --
    END LOOP;
    -- カーソルをクローズ
    CLOSE g_selling_trns_cur;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( g_selling_trns_cur%ISOPEN ) THEN
        CLOSE g_selling_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : update_sls_dedu_ctrl
   * Description      : A-5.販売控除管理情報更新
   ***********************************************************************************/
  PROCEDURE update_sls_dedu_ctrl(
                  ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
                 ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sls_dedu_ctrl';      -- プログラム名
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
--
    -- *** ローカル変数 ***
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
    -- 販売控除連携管理情報を更新
    UPDATE  xxcok_sales_deduction_control
    SET     last_processing_id      = gn_max_selling_trns_info_id         -- 前回処理ID
           ,last_updated_by         = cn_last_updated_by                  -- 最終更新者
           ,last_update_date        = cd_last_update_date                 -- 最終更新日
           ,last_update_login       = cn_last_update_login                -- 最終更新ログイン
           ,request_id              = cn_request_id                       -- 要求ID
           ,program_application_id  = cn_program_application_id           -- コンカレント・プログラム・アプリケーションID
           ,program_id              = cn_program_id                       -- コンカレント・プログラムID
           ,program_update_date     = cd_program_update_date              -- プログラム更新日
    WHERE   control_flag  = cv_control_flag
    ;
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
--#################################  固定例外処理部 END  #################################
--
  END update_sls_dedu_ctrl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   エラー・メッセージ           --# 固定 #
                    ,ov_retcode   OUT VARCHAR2             --   リターン・コード             --# 固定 #
                    ,ov_errmsg    OUT VARCHAR2 )           --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt                 := 0;      -- 対象件数
    gn_normal_cnt                 := 0;      -- 正常件数
    gn_error_cnt                  := 0;      -- エラー件数
    gn_warn_cnt                   := 0;      -- スキップ件数
    gn_max_selling_trns_info_id   := NULL;   -- 売上実績振替情報IDの最大値
    gv_deduction_uom_code         := NULL;   -- 控除単位
    gn_deduction_unit_price       := NULL;   -- 控除単価
    gn_deduction_quantity         := NULL;   -- 控除数量
    gn_deduction_amount           := NULL;   -- 控除額
    gv_tax_code                   := NULL;   -- 税コード
    gn_tax_rate                   := NULL;   -- 税率
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.実績振替データ抽出
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- エラー・メッセージ           -- # 固定 #
       ,ov_retcode => lv_retcode           -- リターン・コード             -- # 固定 #
       ,ov_errmsg  => lv_errmsg            -- ユーザー・エラー・メッセージ -- # 固定 #
    );
--
    IF ( lv_retcode  = cv_status_warn ) THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 売上実績振替情報IDの最大値が取得できていた場合
    IF ( gn_max_selling_trns_info_id IS NOT NULL ) THEN
      -- ===============================
      -- A-5.販売控除管理情報更新
      -- ===============================
      update_sls_dedu_ctrl(
          ov_errbuf  => lv_errbuf          -- エラー・メッセージ           -- # 固定 #
         ,ov_retcode => lv_retcode         -- リターン・コード             -- # 固定 #
         ,ov_errmsg  => lv_errmsg          -- ユーザー・エラー・メッセージ -- # 固定 #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
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
   * Description      : 販売控除データの作成プロシージャ(A-6.終了処理を含む)
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- エラー・メッセージ  --# 固定 #
                 ,retcode     OUT VARCHAR2 )             -- リターン・コード    --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
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
       ,ov_errbuf  => lv_errbuf
       ,ov_errmsg  => lv_errmsg
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
            ,ov_retcode => lv_retcode             -- リターン・コード             --# 固定 #
            ,ov_errmsg  => lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
    -- ===============================
    -- A-6.終了処理
    -- ===============================
--
    -- エラー発生時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_warn_cnt     := 0;
      gn_error_cnt    := 1;
    END IF;
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --登録成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_success_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_skip_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
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
--
--#####################################  固定部 END  #####################################
--
  END main;
--
END XXCOK024A22C;
/
