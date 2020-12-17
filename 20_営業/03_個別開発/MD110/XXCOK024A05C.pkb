CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A05C (body)
 * Description      : 実績振替・販売控除データの作成/販売控除データの作成（振替割合）
 * MD.050           : 実績振替・販売控除データの作成/販売控除データの作成（振替割合） MD050_COK_024_A05
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(B-1)
 *  reversing_data_create  振戻データ作成処理(販売控除)(B-2)
 *  reversing_data_delite  振戻データ削除処理(B-3)
 *  transfer_data_get      実績振替データ抽出(B-4)
 *  sell_trns_cul          実績振替控除データ算出(B-5)
 *  insert_deduction       販売控除データ登録(B-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/05/12    1.0   Y.Nakajima       新規作成
 *  2020/12/03    1.1   SCSK Y.Koh       [E_本稼動_16026]
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
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
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK024A05C';
  -- アプリケーション短縮名
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  -- ステータス・コード
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- WHOカラム
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_creation_date                 CONSTANT DATE            := SYSDATE;                     -- CREATION_DATE
  cd_last_update_date              CONSTANT DATE            := SYSDATE;                     -- LAST_UPDATE_DATE
  cd_program_update_date           CONSTANT DATE            := SYSDATE;                     -- PROGRAM_UPDATE_DATE
  -- 言語
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_cok_00001                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00001';          -- 対象なしメッセージ
  cv_msg_cok_00023                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00023';          -- 
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';          -- 業務日付取得エラー
  cv_msg_cok_00042                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00042';          -- 会計期間未オープンエラー
  cv_msg_cok_10036                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10036';          -- 情報種別設定エラーメッセージ
  cv_msg_cok_10685                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10685';          -- 控除額算出エラー(実績振替)
  cv_msg_cok_10632                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10632';          -- ロックエラーメッセージ
--
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';          -- 対象件数
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';          -- 成功件数
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';          -- エラー件数
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';          -- エラー件数
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';          -- 正常終了
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';          -- 警告終了
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';          -- エラー終了全ロールバック
  -- トークン
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_info_class                CONSTANT VARCHAR2(30)    := 'INFO_CLASS';
  cv_tkn_item_code                 CONSTANT VARCHAR2(30)    := 'ITEM_CODE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_line_id                   CONSTANT VARCHAR2(15)    := 'SOURCE_TRAN_ID';
  cv_tkn_sales_uom_code            CONSTANT VARCHAR2(15)    := 'SALES_UOM_CODE';
  cv_tkn_condition_no              CONSTANT VARCHAR2(20)    := 'CONDITION_NO';
  cv_tkn_base_code                 CONSTANT VARCHAR2(15)    := 'BASE_CODE';
  cv_tkn_errmsg                    CONSTANT VARCHAR2(15)    := 'ERRMSG';
  -- 入力パラメータ・情報種別
  cv_info_class_news               CONSTANT VARCHAR2(1)     := '0';  -- 速報
  cv_info_class_decision           CONSTANT VARCHAR2(1)     := '1';  -- 確定
  -- 売上実績振替情報テーブル・速報確定フラグ
  cv_xsti_decision_flag_news       CONSTANT VARCHAR2(1)     := '0';  -- 速報
  -- 顧客マスタ有効ステータス
  cv_get_period_inv                CONSTANT VARCHAR2(2)     := '01';   --INV会計期間取得
  cv_period_status                 CONSTANT VARCHAR2(4)     := 'OPEN'; -- 会計期間ステータス(オープン)
  --参照タイプ・有効フラグ
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';         -- 有効
  -- 実績振替情報データ抽出で使用する固定値
  cv_cate_set_name          CONSTANT VARCHAR2(20) := '本社商品区分';             -- 品目カテゴリセット名
  -- 販売控除情報テーブルに設定する固定値
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'V';                        -- 作成元区分
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                        -- ステータス
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- GL連携フラグ
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                        -- 取消フラグ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 初期処理取得値
  gd_process_date                  DATE          DEFAULT NULL;   -- 業務処理日付
  gd_target_date_from              DATE          DEFAULT NULL;   -- 振替対象期間（From）
  gd_target_date_to                DATE          DEFAULT NULL;   -- 振替対象期間（To）
  -- 入力パラメータ
  gv_param_info_class              VARCHAR2(1)   DEFAULT NULL;   -- 情報種別
  --
  gv_deduction_uom_code            VARCHAR2(3);                                       -- 控除単位
  gv_tax_code                      VARCHAR2(4);                                       -- 税コード
  gn_tax_rate                      NUMBER;                                            -- 税率
  gn_deduction_unit_price          NUMBER;                                            -- 控除単価
  gn_deduction_quantity            NUMBER;                                            -- 控除数量
  gn_deduction_amount              NUMBER;                                            -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
  gn_compensation                  NUMBER;                                            -- 補填
  gn_margin                        NUMBER;                                            -- 問屋マージン
  gn_sales_promotion_expenses      NUMBER;                                            -- 拡売
  gn_margin_reduction              NUMBER;                                            -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
  gn_deduction_tax_amount          NUMBER;                                            -- 控除税額
--
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt                  EXCEPTION;
  --==================================================
  -- グローバルカーソル
  --==================================================
  -- 実績振替情報取得
  CURSOR g_actual_trns_cur
  IS
    WITH 
     FLVC1 AS
             (SELECT  /*+ MATERIALIZED */
                      lookup_code
              FROM    fnd_lookup_values flvc
              WHERE   flvc.lookup_type  = 'XXCOK1_DEDUCTION_TYPE'
              AND     flvc.language     = 'JA'
              AND     flvc.enabled_flag = 'Y'
              AND     flvc.attribute1   = 'Y')    -- 販売控除作成対象
    ,FLVC3 AS
             (SELECT  /*+ MATERIALIZED */
                      lookup_code
              FROM    fnd_lookup_values flvc
              WHERE   flvc.lookup_type  = 'XXCMM_CUST_GYOTAI_SHO'
              AND     flvc.language     = 'JA'
              AND     flvc.enabled_flag = 'Y'
              AND     flvc.attribute2   = 'Y')    -- 販売控除作成対象
    SELECT 
           /*+ leading(xdst xca gyotai_sho xch flv2 d_typ xcl flv)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */
           xdst.delivery_base_code                      AS delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                               AS base_code                    -- 振替先拠点
          ,xdst.cust_code                               AS cust_code                    -- 振替先顧客
          ,xdst.selling_date                            AS selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                               AS item_code                    -- 品目コード
          ,xdst.unit_type                               AS unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- 納品単価
          ,xdst.qty                                     AS qty                          -- 数量
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                                AS tax_code                     -- 消費税コード
          ,xdst.tax_rate                                AS tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- 消費税額
          ,xch.condition_id                             AS condition_id                 -- 控除条件ID
          ,xch.condition_no                             AS condition_no                 -- 控除番号
          ,xch.corp_code                                AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code                            AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                                AS data_type                    -- データ種類
          ,xch.tax_code                                 AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                               AS attribute3                   -- 本部担当拠点(控除用チェーン)
          ,xca.sale_base_code                           AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id                        AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class                            AS product_class                -- 商品区分
          ,xcl.item_code                                AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                                 AS uom_code                     -- 単位(条件)
          ,xcl.target_category                          AS target_category              -- 対象区分
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1                          AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                              AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- 控除用チェーン
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,FLVC1                         d_typ
          ,FLVC3                         gyotai_sho
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = cv_lang
    AND    flv.enabled_flag(+)           = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    xdst.cust_code                = xch.customer_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
    UNION ALL
    SELECT 
           /*+ leading(xdst xca gyotai_sho xch flv2 d_typ xcl flv)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */
           xdst.delivery_base_code                      AS delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                               AS base_code                    -- 振替先拠点
          ,xdst.cust_code                               AS cust_code                    -- 振替先顧客
          ,xdst.selling_date                            AS selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                               AS item_code                    -- 品目コード
          ,xdst.unit_type                               AS unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- 納品単価
          ,xdst.qty                                     AS qty                          -- 数量
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                                AS tax_code                     -- 消費税コード
          ,xdst.tax_rate                                AS tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- 消費税額
          ,xch.condition_id                             AS condition_id                 -- 控除条件ID
          ,xch.condition_no                             AS condition_no                 -- 控除番号
          ,xch.corp_code                                AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code                            AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                                AS data_type                    -- データ種類
          ,xch.tax_code                                 AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                               AS attribute3                   -- 本部担当拠点(控除用チェーン)
          ,xca.sale_base_code                           AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id                        AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class                            AS product_class                -- 商品区分
          ,xcl.item_code                                AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                                 AS uom_code                     -- 単位(条件)
          ,xcl.target_category                          AS target_category              -- 対象区分
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1                          AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                              AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- 控除用チェーン
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,FLVC1                         D_TYP
          ,FLVC3                         GYOTAI_SHO
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type(+)            = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code(+)            = xca.intro_chain_code2
    AND    flv.language(+)               = cv_lang
    AND    flv.enabled_flag(+)           = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    xca.intro_chain_code2         = xch.deduction_chain_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
    UNION ALL
    SELECT 
           /*+ leading(xdst xca gyotai_sho flv xch flv2 d_typ xcl)
               use_nl(xca) use_nl(flv) use_nl(xch) use_nl(flv2) use_nl(xcl)
            */            
           xdst.delivery_base_code                      AS delivery_base_code           -- 振替元拠点
          ,xdst.selling_from_cust_code                  AS selling_from_cust_code       -- 振替元顧客
          ,xdst.base_code                               AS base_code                    -- 振替先拠点
          ,xdst.cust_code                               AS cust_code                    -- 振替先顧客
          ,xdst.selling_date                            AS selling_date                 -- 売上計上日
          ,xdst.selling_trns_info_id                    AS selling_trns_info_id         -- 売上実績振替情報ID
          ,xdst.item_code                               AS item_code                    -- 品目コード
          ,xdst.unit_type                               AS unit_type                    -- 納品単位
          ,xdst.delivery_unit_price                     AS delivery_unit_price          -- 納品単価
          ,xdst.qty                                     AS qty                          -- 数量
          ,xdst.selling_amt_no_tax                      AS selling_amt_no_tax           -- 本体金額（税抜き）
          ,xdst.tax_code                                AS tax_code                     -- 消費税コード
          ,xdst.tax_rate                                AS tax_rate                     -- 消費税率
          ,xdst.selling_amt - xdst.selling_amt_no_tax   AS tax_amount                   -- 消費税額
          ,xch.condition_id                             AS condition_id                 -- 控除条件ID
          ,xch.condition_no                             AS condition_no                 -- 控除番号
          ,xch.corp_code                                AS corp_code                    -- 企業コード
          ,xch.deduction_chain_code                     AS deduction_chain_code         -- 控除用チェーンコード
          ,xch.customer_code                            AS customer_code                -- 顧客コード(条件)
          ,xch.data_type                                AS data_type                    -- データ種類
          ,xch.tax_code                                 AS tax_code_mst                 -- 税コード(マスタ)
          ,xch.tax_rate                                 AS tax_rate_mst                 -- 税率(マスタ)
          ,flv.attribute3                               AS attribute3                   -- 本部担当拠点(控除用チェーン)
          ,xca.sale_base_code                           AS sale_base_code               -- 売上拠点(顧客)
          ,xcl.condition_line_id                        AS condition_line_id            -- 控除詳細ID
          ,xcl.product_class                            AS product_class                -- 商品区分
          ,xcl.item_code                                AS item_code_cond               -- 品目コード(条件)
          ,xcl.uom_code                                 AS uom_code                     -- 単位(条件)
          ,xcl.target_category                          AS target_category              -- 対象区分
          ,xcl.shop_pay_1                               AS shop_pay_1                   -- 店納(％)
          ,xcl.material_rate_1                          AS material_rate_1              -- 料率(％)
          ,xcl.condition_unit_price_en_2                AS condition_unit_price_en_2    -- 条件単価２(円)
          ,xcl.accrued_en_3                             AS accrued_en_3                 -- 未収計３(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.compensation_en_3                        AS compensation_en_3            -- 補填(円)
          ,xcl.wholesale_margin_en_3                    AS wholesale_margin_en_3        -- 問屋マージン(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.accrued_en_4                             AS accrued_en_4                 -- 未収計４(円)
-- 2020/12/03 Ver1.1 ADD Start
          ,xcl.just_condition_en_4                      AS just_condition_en_4          -- 今回条件(円)
          ,xcl.wholesale_adj_margin_en_4                AS wholesale_adj_margin_en_4    -- 問屋マージン修正(円)
-- 2020/12/03 Ver1.1 ADD End
          ,xcl.condition_unit_price_en_5                AS condition_unit_price_en_5    -- 条件単価５(円)
          ,xcl.deduction_unit_price_en_6                AS deduction_unit_price_en_6    -- 控除単価(円)
          ,flv2.attribute2                              AS attribute2                   -- 控除タイプ
    FROM
           xxcok_dedu_sell_trns_info     xdst                            -- 控除用実績振替情報
          ,xxcmm_cust_accounts           xca                             -- 顧客追加情報
          ,fnd_lookup_values             flv                             -- 控除用チェーン
          ,xxcok_condition_header        xch                             -- 控除条件
          ,xxcok_condition_lines         xcl                             -- 控除詳細
          ,fnd_lookup_values             flv2                            -- データ種類
          ,FLVC1                         D_TYP
          ,FLVC3                         GYOTAI_SHO
    WHERE  xdst.selling_date       BETWEEN gd_target_date_from
                                       AND gd_target_date_to
    AND    xdst.selling_trns_type        = '0'
    AND    xca.customer_code             = xdst.cust_code
    AND    xca.business_low_type         = GYOTAI_SHO.lookup_code
    AND    flv.lookup_type               = 'XXCMM_CHAIN_CODE'
    AND    flv.lookup_code               = xca.intro_chain_code2
    AND    flv.language                  = cv_lang
    AND    flv.enabled_flag              = cv_enable
    AND    xch.enabled_flag_h            = cv_enable
    AND    flv2.lookup_type              = 'XXCOK1_DEDUCTION_DATA_TYPE'
    AND    flv2.lookup_code              = xch.data_type
    AND    flv2.language                 = cv_lang
    AND    flv2.enabled_flag             = cv_enable
    AND    flv2.attribute2               = D_TYP.lookup_code
    AND    flv.attribute1                = xch.corp_code
    AND    xdst.selling_date       BETWEEN xch.start_date_active
                                       AND xch.end_date_active
    AND    xcl.condition_id              = xch.condition_id
    AND    xcl.enabled_flag_l            = cv_enable
    AND   (xdst.item_code                = xcl.item_code
    OR     xdst.product_class            = xcl.product_class)
  ;
--
  -- カーソルレコード取得用
  g_selling_trns_rec          g_actual_trns_cur%ROWTYPE;
--
  --==================================================
  -- グローバルタイプ
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : insert_deduction
   * Description      : 販売控除データ登録(B-6)
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
        ,condition_id                                                     -- 控除ID
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
-- 2020/12/03 Ver1.1 ADD Start
        ,recon_tax_code                                                   -- 消込時税コード
        ,recon_tax_rate                                                   -- 消込時税率
-- 2020/12/03 Ver1.1 ADD End
        ,deduction_tax_amount                                             -- 控除税額
-- 2020/12/03 Ver1.1 ADD Start
        ,remarks                                                          -- 備考
        ,application_no                                                   -- 申請書No.
-- 2020/12/03 Ver1.1 ADD End
        ,gl_if_flag                                                       -- GL連携フラグ
-- 2020/12/03 Ver1.1 ADD Start
        ,gl_base_code                                                     -- GL計上拠点
        ,gl_date                                                          -- GL記帳日
        ,recovery_date                                                    -- リカバリデータ追加時日付
        ,recovery_add_request_id                                          -- リカバリデータ追加時要求ID
        ,recovery_del_date                                                -- リカバリデータ削除時日付
        ,recovery_del_request_id                                          -- リカバリデータ削除時要求ID
-- 2020/12/03 Ver1.1 ADD End
        ,cancel_flag                                                      -- 取消フラグ
-- 2020/12/03 Ver1.1 ADD Start
        ,cancel_base_code                                                 -- 取消時計上拠点
        ,cancel_gl_date                                                   -- 取消GL記帳日
        ,cancel_user                                                      -- 取消実施ユーザ
        ,recon_base_code                                                  -- 消込時計上拠点
        ,recon_slip_num                                                   -- 支払伝票番号
        ,carry_payment_slip_num                                           -- 繰越時支払伝票番号
-- 2020/12/03 Ver1.1 ADD End
        ,report_decision_flag                                             -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD Start
        ,gl_interface_id                                                  -- GL連携ID
        ,cancel_gl_interface_id                                           -- 取消GL連携ID
-- 2020/12/03 Ver1.1 ADD End
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
        ,g_selling_trns_rec.condition_id                                  -- 控除ID
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
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- 消込時税コード
        ,NULL                                                             -- 消込時税率
-- 2020/12/03 Ver1.1 ADD End
        ,gn_deduction_tax_amount                                          -- 控除税額
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- 備考
        ,NULL                                                             -- 申請書No.
-- 2020/12/03 Ver1.1 ADD End
-- 2020/12/03 Ver1.1 MOD Start
        ,CASE
           WHEN   TRUNC( g_selling_trns_rec.selling_date, 'MM' )
                = TRUNC( gd_process_date                , 'MM' )
           THEN
             'O'
           ELSE
             DECODE(gv_param_info_class,'1','N','O')
         END                                                              -- GL連携フラグ(速報データはGL連携対象外)
--        ,cv_gl_rel_flag                                                   -- GL連携フラグ
-- 2020/12/03 Ver1.1 MOD End
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- GL計上拠点
        ,NULL                                                             -- GL記帳日
        ,NULL                                                             -- リカバリデータ追加時日付
        ,NULL                                                             -- リカバリデータ追加時要求ID
        ,NULL                                                             -- リカバリデータ削除時日付
        ,NULL                                                             -- リカバリデータ削除時要求ID
-- 2020/12/03 Ver1.1 ADD End
        ,cv_cancel_flag                                                   -- 取消フラグ
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- 取消時計上拠点
        ,NULL                                                             -- 取消GL記帳日
        ,NULL                                                             -- 取消実施ユーザ
        ,NULL                                                             -- 消込時計上拠点
        ,NULL                                                             -- 支払伝票番号
        ,NULL                                                             -- 繰越時支払伝票番号
-- 2020/12/03 Ver1.1 ADD End
        ,CASE
           WHEN   TRUNC( g_selling_trns_rec.selling_date, 'MM' )
                = TRUNC( gd_process_date                , 'MM' )
           THEN
             cv_xsti_decision_flag_news
           ELSE
             gv_param_info_class
         END                                                              -- 速報確定フラグ
-- 2020/12/03 Ver1.1 ADD Start
        ,NULL                                                             -- GL連携ID
        ,NULL                                                             -- 取消GL連携ID
-- 2020/12/03 Ver1.1 ADD End
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
   * Procedure Name   : sell_trns_cul
   * Description      : 実績振替控除データ算出(B-5)
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
     ,iv_tax_code_trn               =>  g_selling_trns_rec.tax_code                   -- 税コード(TRN)
     ,in_tax_rate_trn               =>  g_selling_trns_rec.tax_rate                   -- 税率(TRN)
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
        lv_base_code  :=  g_selling_trns_rec.attribute3;                              -- 本部担当拠点(控除用チェーン)
      -- 顧客コード(条件)がNULL以外の場合
      ELSIF ( g_selling_trns_rec.customer_code IS NOT NULL ) THEN
        lv_base_code  :=  g_selling_trns_rec.sale_base_code;                          -- 売上拠点(顧客)
      END IF;
      -- 控除額算出エラーメッセージの出力
      ov_retcode := cv_status_warn;
      lv_out_msg := xxccp_common_pkg.get_msg(
                      cv_appl_short_name_cok
                     ,cv_msg_cok_10685
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
   * Procedure Name   : transfer_data_get
   * Description      : 実績振替データ抽出(B-4)
   ***********************************************************************************/
  PROCEDURE transfer_data_get(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'transfer_data_get';                              -- プログラム名
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
    -- カーソルオープン
    OPEN  g_actual_trns_cur;
    -- データ取得
    FETCH g_actual_trns_cur INTO g_selling_trns_rec;
--
    -- 取得データが０件の場合
    IF ( g_actual_trns_cur%NOTFOUND )  THEN
      -- 警告ステータスの格納
      ov_retcode := cv_status_warn;
      -- 対象なしメッセージの出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cok
                   ,iv_name         => cv_msg_cok_00001
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --ユーザー・エラーメッセージ
      );
    END IF;
--
    LOOP
      EXIT  WHEN  g_actual_trns_cur%NOTFOUND;
        -- 対象件数をインクリメント
        gn_target_cnt :=  gn_target_cnt + 1;
        -- ============================================================
        -- 販売控除データ算出(B-5)
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
          -- 販売控除データ登録(B-6)
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
          gn_skip_cnt := gn_skip_cnt   + 1;
        ELSE
          RAISE global_process_expt;
        END IF;
        -- 次のデータを取得
        FETCH g_actual_trns_cur INTO g_selling_trns_rec;
--
    END LOOP;
    -- カーソルをクローズ
    CLOSE g_actual_trns_cur;
--
  EXCEPTION
--
--################################  固定例外処理部 START  ################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( g_actual_trns_cur%ISOPEN ) THEN
        CLOSE g_actual_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END  #####################################
  END transfer_data_get;
--
  /**********************************************************************************
   * Procedure Name   : reversing_data_delite
   * Description      : 振戻データ削除処理(B-3)
   ***********************************************************************************/
  PROCEDURE reversing_data_delite(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reversing_data_delite';                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
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
    -- *** ローカルカーソル ***
    CURSOR l_sales_dedu_delete_cur
    IS
      SELECT xsd.sales_deduction_id       AS sales_deduction_id
      FROM   xxcok_sales_deduction        xsd
      WHERE  xsd.source_category          = 'V'
      AND    xsd.status                   = 'N'
      AND    xsd.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xsd.report_decision_flag ）
      AND    xsd.record_date             >= gd_target_date_from
      AND    xsd.record_date             <= gd_target_date_to
      FOR UPDATE NOWAIT
    ;
--
    sales_dedu_delete_rec          l_sales_dedu_delete_cur%ROWTYPE;
--
    -- *** ローカル例外 ***
    lock_expt       EXCEPTION;
    PRAGMA EXCEPTION_INIT(lock_expt, -54);                  -- ロックエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    OPEN  l_sales_dedu_delete_cur;
    FETCH l_sales_dedu_delete_cur INTO sales_dedu_delete_rec;
    CLOSE l_sales_dedu_delete_cur;
    -- 振戻データ削除
    DELETE
    FROM   xxcok_sales_deduction    xsd
    WHERE  xsd.source_category          = 'V'
    AND    xsd.status                   = 'N'
    AND    xsd.report_decision_flag     = DECODE(iv_info_class, '0', '0' ,'1',xsd.report_decision_flag ）
    AND    xsd.record_date             >= gd_target_date_from
    AND    xsd.record_date             <= gd_target_date_to
    ;
--

  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      -- カーソルクローズ
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      -- ロックエラーメッセージ
      ov_errmsg := xxccp_common_pkg.get_msg( cv_appl_short_name_cok
                                            ,cv_msg_cok_10632
                                             );
      ov_errbuf :=  cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF ( l_sales_dedu_delete_cur%ISOPEN ) THEN
        CLOSE l_sales_dedu_delete_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END reversing_data_delite;
--
  /**********************************************************************************
   * Procedure Name   : reversing_data_create
   * Description      : 振戻データ作成処理(B-2)
   ***********************************************************************************/
  PROCEDURE reversing_data_create(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'reversing_data_create';                         -- プログラム名
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
    -- *** ローカルカーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================================
    -- 振戻データ作成処理(販売控除)
    --==================================================
      --==================================================
      -- 控除振替振戻テーブル登録
      --==================================================
      INSERT INTO xxcok_dedu_trn_rev(
-- 2020/12/03 Ver1.1 MOD Start
        sales_deduction_id                             -- 販売控除ID
      , base_code_from                                 -- 振替元拠点
--        base_code_from                                 -- 振替元拠点
-- 2020/12/03 Ver1.1 MOD End
      , base_code_to                                   -- 振替先拠点
      , customer_code_from                             -- 振替元顧客コード
      , customer_code_to                               -- 振替先顧客コード
      , record_date                                    -- 計上日
-- 2020/12/03 Ver1.1 ADD Start
      , source_line_id                                 -- 作成元明細ID
      , condition_id                                   -- 控除条件ID
      , condition_no                                   -- 控除番号
      , condition_line_id                              -- 控除詳細ID
      , data_type                                      -- データ種類
-- 2020/12/03 Ver1.1 ADD End
      , item_code                                      -- 品目コード
      , sales_quantity                                 -- 販売数量
      , sales_uom_code                                 -- 販売単位
      , sales_unit_price                               -- 販売単価
      , sale_pure_amount                               -- 売上本体金額
      , sale_tax_amount                                -- 売上消費税額
      , deduction_quantity                             -- 控除数量
      , deduction_uom_code                             -- 控除単位
      , deduction_unit_price                           -- 控除単価
      , deduction_amount                               -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
      , compensation                                   -- 補填
      , margin                                         -- 問屋マージン
      , sales_promotion_expenses                       -- 拡売
      , margin_reduction                               -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
      , tax_code                                       -- 税コード
      , tax_rate                                       -- 税率
-- 2020/12/03 Ver1.1 DEL Start
--      , recon_tax_code                                 -- 消込時税コード
--      , recon_tax_rate                                 -- 消込時税率
-- 2020/12/03 Ver1.1 DEL End
      , deduction_tax_amount                           -- 控除税額
      , created_by                                     -- 作成者
      , creation_date                                  -- 作成日
      , last_updated_by                                -- 最終更新者
      , last_update_date                               -- 最終更新日
      , last_update_login                              -- 最終更新ログイン
      , request_id                                     -- 要求ID
      , program_application_id                         -- コンカレント・プログラム・アプリケーションID
      , program_id                                     -- コンカレント・プログラムID
      , program_update_date                            -- プログラム更新日
      )
      SELECT
-- 2020/12/03 Ver1.1 MOD Start
        xsd.sales_deduction_id                         -- 販売控除ID
      , xsd.base_code_from                             -- 振替元拠点
--        xsd.base_code_from                             -- 振替元拠点
-- 2020/12/03 Ver1.1 MOD End
      , xsd.base_code_to                               -- 振替先拠点
      , xsd.customer_code_from                         -- 振替元顧客コード
      , xsd.customer_code_to                           -- 振替先顧客コード
      , xsd.record_date                                -- 計上日
-- 2020/12/03 Ver1.1 ADD Start
      , xsd.source_line_id                             -- 作成元明細ID
      , xsd.condition_id                               -- 控除条件ID
      , xsd.condition_no                               -- 控除番号
      , xsd.condition_line_id                          -- 控除詳細ID
      , xsd.data_type                                  -- データ種類
-- 2020/12/03 Ver1.1 ADD End
      , xsd.item_code                                  -- 品目コード
      , xsd.sales_quantity * -1                        -- 販売数量
      , xsd.sales_uom_code                             -- 販売単位
      , xsd.sales_unit_price                           -- 販売単価
      , xsd.sale_pure_amount * -1                      -- 売上本体金額
      , xsd.sale_tax_amount  * -1                      -- 売上消費税額
      , xsd.deduction_quantity * -1                    -- 控除数量
      , xsd.deduction_uom_code                         -- 控除単位
      , xsd.deduction_unit_price                       -- 控除単価
      , xsd.deduction_amount * -1                      -- 控除額
-- 2020/12/03 Ver1.1 ADD Start
      , xsd.compensation * -1                          -- 補填
      , xsd.margin * -1                                -- 問屋マージン
      , xsd.sales_promotion_expenses * -1              -- 拡売
      , xsd.margin_reduction * -1                      -- 問屋マージン減額
-- 2020/12/03 Ver1.1 ADD End
      , xsd.tax_code                                   -- 税コード
      , xsd.tax_rate                                   -- 税率
-- 2020/12/03 Ver1.1 DEL Start
--      , xsd.recon_tax_code                             -- 消込時税コード
--      , xsd.recon_tax_rate                             -- 消込時税率
-- 2020/12/03 Ver1.1 DEL End
      , xsd.deduction_tax_amount * -1                  -- 控除税額
      , cn_created_by                                  -- 作成者
      , SYSDATE                                        -- 作成日
      , cn_last_updated_by                             -- 最終更新者
      , SYSDATE                                        -- 最終更新日
      , cn_last_update_login                           -- 最終更新ログイン
      , cn_request_id                                  -- 要求ID
      , cn_program_application_id                      -- コンカレント・プログラム・アプリケーションID
      , cn_program_id                                  -- コンカレント・プログラムID
      , SYSDATE                                        -- プログラム更新日
      FROM    xxcok_sales_deduction    xsd
      WHERE   xsd.source_category       = 'V'
      AND     xsd.report_decision_flag  = '0'
      AND     xsd.record_date          >= gd_target_date_from
      AND     xsd.record_date          <= gd_target_date_to
      ;
--
  EXCEPTION
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
  END reversing_data_create;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    lv_period_status               VARCHAR2(10)   DEFAULT NULL;                 -- 会計期間ステータスチェック用戻り値
    ld_target_date_from            DATE           DEFAULT NULL;                 -- 会計期間関数OUT取得用(ダミー)
    ld_target_date_to              DATE           DEFAULT NULL;                 -- 会計期間関数OUT取得用(ダミー)
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
    --==================================================
    -- プログラム入力項目を出力
    --==================================================
    -- 情報種別
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00023
                  , iv_token_name1          => cv_tkn_info_class
                  , iv_token_value1         => iv_info_class
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message              => lv_outmsg         -- メッセージ
                  , in_new_line             => 0                  -- 改行
                  );
    --==============================================================
    -- 1.情報種別チェック
    --==============================================================
    IF( iv_info_class NOT IN ( cv_info_class_news, cv_info_class_decision ) ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10036
                    , iv_token_name1          => cv_tkn_info_class
                    , iv_token_value1         => iv_info_class
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- プログラム入力項目をグローバル変数へ格納
    --==================================================
    gv_param_info_class := iv_info_class;
--
    --==============================================================
    -- 2.業務日付取得
    --==============================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    --==============================================================
    -- 3.会計期間状態チェック
    --==============================================================
    -- 当月会計期間チェック
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv       -- IN  VARCHAR2 '01'(会計期間INV)
    , id_base_date        => gd_process_date         -- IN  DATE     処理日(対象日)
    , ov_status           => lv_period_status        -- OUT VARCHAR2 ステータス
    , od_start_date       => ld_target_date_from     -- OUT DATE     会計期間(FROM)
    , od_end_date         => ld_target_date_to       -- OUT DATE     会計期間(TO)
    , ov_errbuf           => lv_errbuf               -- OUT VARCHAR2 エラー・メッセージエラー
    , ov_retcode          => lv_retcode              -- OUT VARCHAR2 リターン・コード
    , ov_errmsg           => lv_errmsg               -- OUT VARCHAR2 ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( gd_process_date, 'MM' );
      gd_target_date_to   := gd_process_date;
    ELSE
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00042
                    , iv_token_name1          => cv_tkn_proc_date
                    , iv_token_value1         => TO_CHAR( gd_process_date, 'RRRR/MM' )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
--
    -- 前月会計期間チェック
    xxcos_common_pkg.get_account_period(
      iv_account_period   => cv_get_period_inv                  -- IN  VARCHAR2 '01'(会計期間INV)
    , id_base_date        => ADD_MONTHS( gd_process_date, - 1 ) -- IN  DATE     処理日(対象日)
    , ov_status           => lv_period_status                   -- OUT VARCHAR2 ステータス
    , od_start_date       => ld_target_date_from                -- OUT DATE     会計期間(FROM)
    , od_end_date         => ld_target_date_to                  -- OUT DATE     会計期間(TO)
    , ov_errbuf           => lv_errbuf                          -- OUT VARCHAR2 エラー・メッセージエラー
    , ov_retcode          => lv_retcode                         -- OUT VARCHAR2 リターン・コード
    , ov_errmsg           => lv_errmsg                          -- OUT VARCHAR2 ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_errmsg
                    , in_new_line             => 0
                    );
      lv_end_retcode := lv_retcode;
      RAISE global_process_expt;
    END IF;
    IF( lv_period_status = cv_period_status ) THEN
      gd_target_date_from := TRUNC( ADD_MONTHS( gd_process_date, - 1 ), 'MM' );
      gd_target_date_to   := gd_process_date;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- 初期処理(B-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_info_class           => iv_info_class         -- 情報種別
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
    --==================================================
    -- 振戻データ作成処理(B-2)
    --==================================================
    reversing_data_create(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 振戻データ削除処理(B-3)
    --==================================================
    reversing_data_delite(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_info_class           => iv_info_class         -- 情報種別
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 実績振替データ抽出(B-4)
    --==================================================
    transfer_data_get(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_end_retcode := cv_status_warn;
    END IF;
    --==================================================
    -- 出力パラメータ設定
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- エラーメッセージ
  , retcode                        OUT VARCHAR2        -- エラーコード
  , iv_info_class                  IN  VARCHAR2        -- 情報種別
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- 終了メッセージコード
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
--
  BEGIN
    --==================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- 出力区分
                  , iv_message               => NULL               -- メッセージ
                  , in_new_line              => 1                  -- 改行
                  );
    --==================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- エラー・メッセージ
    , ov_retcode              => lv_retcode            -- リターン・コード
    , ov_errmsg               => lv_errmsg             -- ユーザー・エラー・メッセージ
    , iv_info_class           => iv_info_class         -- 情報種別
    );
    --==================================================
    -- エラー出力
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- 出力区分
                    , iv_message               => lv_errmsg           -- メッセージ
                    , in_new_line              => 1                   -- 改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- 対象件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- 成功件数出力(エラー発生の場合、成功件数:0件 エラー件数:1件  対象件数0件の場合、成功件数:0件)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- スキップ件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- エラー件数出力
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
    --==================================================
    -- 処理終了メッセージ出力
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ステータスセット
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- 終了ステータスエラー時、ロールバック
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK024A05C;
/
