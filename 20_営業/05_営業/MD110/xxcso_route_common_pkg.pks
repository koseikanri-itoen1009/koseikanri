CREATE OR REPLACE PACKAGE APPS.xxcso_route_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_ROUTE_COMMON_PKG(spec)
 * Description      : ROUTE関連共通関数（営業）
 * MD.050           : XXCSO_View・共通関数一覧
 * Version          : 1.2
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  validate_route_no      F     B     ルートＮｏ妥当性チェック
 *  distribute_sales_plan  P     -     売上計画日別配分処理
 *  calc_visit_times       F     N     ルートＮｏ訪問回数算出処理
 *  validate_route_no_p    P     -     ルートＮｏ妥当性チェック(プロシージャ)
 *  isCustomerVendor       F     B     ＶＤ業態判定関数
 *  calc_visit_times_f     F     N     ルートＮｏ訪問回数算出処理
 *  get_visit_rank_f       F     V     訪問ランク取得
 *  get_number_of_visits_f F     N     計画訪問回数取得取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/16    1.0   Kenji.Sai       新規作成
 *  2008/12/12          Kazuo.Satomura  ルートＮｏ訪問回数算出処理追加
 *  2008/12/17          Noriyuki.Yabuki ルートＮｏ妥当性チェックの出力項目(エラー理由)追加
 *  2009/01/09          Kazumoto.Tomio  ルートＮｏ妥当性チェック(プロシージャ)追加
 *  2009/01/20          T.Maruyama      ＶＤ業態判定関数追加
 *  2009/02/19    1.0   Mio.Maruyama    ルートＮｏ訪問回数算出処理追加
 *  2009-05-01    1.1   Tomoko.Mori     T1_0897対応
 *  2024-10-23    1.2   Toru.Okuyama    E_本稼動_20170対応：訪問ランク取得、計画訪問回数取得取得の追加
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 曜日を格納する配列
  TYPE g_day_of_week_ttype IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Function Name    : validate_route_no
   * Description      : ルートＮｏ妥当性チェック
   ***********************************************************************************/
  FUNCTION validate_route_no(
    iv_route_number  IN  VARCHAR2,    -- ルートＮｏ
    ov_error_reason  OUT VARCHAR2     -- エラー理由
  ) RETURN BOOLEAN;
--   
-- 
  /**********************************************************************************
   * Procedure Name   : distribute_sales_plan
   * Description      : 売上計画日別配分処理
   ***********************************************************************************/
  PROCEDURE distribute_sales_plan(
    iv_year_month                  IN VARCHAR2,                                            -- 年月（書式：YYYYMM）
    it_sales_plan_amt              IN xxcso_in_sales_plan_month.sales_plan_amt%TYPE,       -- 月間売上計画金額
    it_route_number                IN xxcso_in_route_no.route_no%TYPE,                     -- ルートＮｏ 
    on_day_on_month                OUT NUMBER,                                             -- 該当月の日数
    on_visit_daytimes              OUT NUMBER,                                             -- 当該月の訪問日数
    ot_sales_plan_day_amt_1        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 1日目日別売上計画金額
    ot_sales_plan_day_amt_2        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 2日目日別売上計画金額
    ot_sales_plan_day_amt_3        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 3日目日別売上計画金額
    ot_sales_plan_day_amt_4        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 4日目日別売上計画金額
    ot_sales_plan_day_amt_5        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 5日目日別売上計画金額
    ot_sales_plan_day_amt_6        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 6日目日別売上計画金額
    ot_sales_plan_day_amt_7        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 7日目日別売上計画金額
    ot_sales_plan_day_amt_8        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 8日目日別売上計画金額
    ot_sales_plan_day_amt_9        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 9日目日別売上計画金額
    ot_sales_plan_day_amt_10       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 10日目日別売上計画金額
    ot_sales_plan_day_amt_11       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 11日目日別売上計画金額
    ot_sales_plan_day_amt_12       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 12日目日別売上計画金額
    ot_sales_plan_day_amt_13       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 13日目日別売上計画金額
    ot_sales_plan_day_amt_14       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 14日目日別売上計画金額
    ot_sales_plan_day_amt_15       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 15日目日別売上計画金額
    ot_sales_plan_day_amt_16       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 16日目日別売上計画金額
    ot_sales_plan_day_amt_17       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 17日目日別売上計画金額
    ot_sales_plan_day_amt_18       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 18日目日別売上計画金額
    ot_sales_plan_day_amt_19       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 19日目日別売上計画金額
    ot_sales_plan_day_amt_20       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 20日目日別売上計画金額
    ot_sales_plan_day_amt_21       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 21日目日別売上計画金額
    ot_sales_plan_day_amt_22       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 22日目日別売上計画金額
    ot_sales_plan_day_amt_23       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 23日目日別売上計画金額
    ot_sales_plan_day_amt_24       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 24日目日別売上計画金額
    ot_sales_plan_day_amt_25       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 25日目日別売上計画金額
    ot_sales_plan_day_amt_26       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 26日目日別売上計画金額
    ot_sales_plan_day_amt_27       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 27日目日別売上計画金額
    ot_sales_plan_day_amt_28       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 28日目日別売上計画金額
    ot_sales_plan_day_amt_29       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 29日目日別売上計画金額
    ot_sales_plan_day_amt_30       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 30日目日別売上計画金額
    ot_sales_plan_day_amt_31       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 31日目日別売上計画金額
    ov_errbuf                      OUT NOCOPY VARCHAR2,   -- エラー・メッセージ            --# 固定 #
    ov_retcode                     OUT NOCOPY VARCHAR2,   -- リターン・コード              --# 固定 #
    ov_errmsg                      OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ  --# 固定 #
  );
--
-- 
  /**********************************************************************************
   * Function Name    : calc_visit_times
   * Description      : ルートＮｏ訪問回数算出処理
   ***********************************************************************************/
  PROCEDURE calc_visit_times(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ルートＮｏ
    ,on_times        OUT NOCOPY NUMBER                          -- 訪問回数
    ,ov_errbuf       OUT NOCOPY VARCHAR2                        -- エラー・メッセージ            --# 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2                        -- リターン・コード              --# 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                        -- ユーザー・エラー・メッセージ  --# 固定 #
  );
-- 
--
  /**********************************************************************************
   * Function Name    : validate_route_no_p
   * Description      : ルートＮｏ妥当性チェック(プロシージャ)
   ***********************************************************************************/
  PROCEDURE validate_route_no_p(
     iv_route_number  IN  VARCHAR2            -- ルートＮｏ
    ,ov_retcode       OUT NOCOPY VARCHAR2     -- リターン・コード  --# 固定 #
    ,ov_error_reason  OUT VARCHAR2            -- エラー理由
  );
--
--
  /**********************************************************************************
   * Function Name    : isCustomerVendor
   * Description      : ＶＤ業態判定関数
   ***********************************************************************************/
  FUNCTION isCustomerVendor(
     iv_cust_gyoutai  IN  VARCHAR2            -- 業態（小分類）
  ) RETURN VARCHAR2;
--
--
  /**********************************************************************************
   * Function Name    : calc_visit_times_f
   * Description      : 訪問回数算出処理
   ***********************************************************************************/
  FUNCTION calc_visit_times_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ルートＮｏ
  ) RETURN NUMBER;
--
-- Ver 1.2 Add Start
  /**********************************************************************************
   * Function Name    : get_visit_rank_f
   * Description      : 訪問ランク取得
   ***********************************************************************************/
  FUNCTION get_visit_rank_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ルートＮｏ
  ) RETURN VARCHAR2;
--
  /**********************************************************************************
   * Function Name    : get_number_of_visits_f
   * Description      : 計画訪問回数取得取得
   ***********************************************************************************/
  FUNCTION get_number_of_visits_f(
     iv_route_number     IN  xxcso_in_route_no.route_no%TYPE, -- ルートＮｏ
     id_year_month       IN  DATE,                            -- 基準月初日
     in_day_offset       IN  NUMBER                           -- 月初からのオフセット日数
  ) RETURN NUMBER;
-- Ver 1.2 Add End
--
END xxcso_route_common_pkg;
/
