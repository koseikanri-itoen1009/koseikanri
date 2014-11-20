create or replace PACKAGE XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ2(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 2.4
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.品目情報取得処理
 * get_num_of_shipped        11.鮮度条件別出荷実績取得
 * get_num_of_forecast       12.出荷予測取得処理
 * get_stock_plan            13.入庫予定取得処理
 * get_onhand_qty            14.手持在庫取得処理
 * get_deliv_lead_time       15.配送リードタイム取得処理
 * get_working_days          16.稼働日数取得処理
 * upd_assignment            17.割当セットAPI起動
 * get_loct_info             18.倉庫情報取得処理
 * get_critical_date_f       19.鮮度条件基準日取得処理
 * get_delivery_unit         20.配送単位取得処理
 * get_receipt_date          21.着日取得処理
 * get_shipment_date         22.出荷日取得処理(廃止予定)
 * get_item_category_f       23.品目カテゴリ取得
 * get_last_arrival_date_f   24.最終入庫日取得
 * get_last_purchase_date_f  25.最終購入日取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   新規作成
 *  2009/04/08    1.1  SCS.Kikuchi      T1_0272,T1_0279,T1_0282,T1_0284対応
 *  2009/05/08    1.2  SCS.Kikuchi      T1_0918,T1_0919対応
 *  2009/07/23    1.3  SCS.Fukada       0000670対応(共通課題：I_E_479)
 *  2009/08/24    2.0  SCS.Fukada       0000669対応(共通課題：I_E_479)、変更履歴削除
 *  2009/12/01    2.1  SCS.Goto         I_E_479_020 アプリPT対応
 *  2009/12/01    2.4  SCS.Goto         I_E_479_022 割当セットAPI起動修正
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_char_ttype IS TABLE OF VARCHAR2(256)   INDEX BY BINARY_INTEGER;    -- 警告メッセージ
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目情報取得処理
   ***********************************************************************************/
  PROCEDURE get_item_info(
    id_target_date             IN  DATE        -- 対象日付
   ,in_organization_id         IN  NUMBER      -- 組織ID
   ,in_inventory_item_id       IN  NUMBER      -- 在庫品目ID
   ,on_item_id                 OUT NUMBER      -- OPM品目ID
   ,ov_item_no                 OUT VARCHAR2    -- 品目コード
   ,ov_item_name               OUT VARCHAR2    -- 品目名称
   ,on_num_of_case             OUT NUMBER      -- ケース入数
   ,on_palette_max_cs_qty      OUT NUMBER      -- 配数
   ,on_palette_max_step_qty    OUT NUMBER      -- 段数
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_shipment_result
   * Description      : 出荷実績取得
   ***********************************************************************************/
  PROCEDURE get_shipment_result(
    in_deliver_from_id         IN  NUMBER      -- OPM保管場所ID
   ,in_item_id                 IN  NUMBER      -- OPM品目ID
   ,id_shipment_date_from      IN  DATE        -- 出荷実績期間FROM
   ,id_shipment_date_to        IN  DATE        -- 出荷実績期間TO
   ,iv_freshness_condition     IN  VARCHAR2    -- 鮮度条件
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_START
   ,in_inventory_item_id       IN  NUMBER      -- INV品目ID
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_END
   ,on_shipped_quantity        OUT NUMBER      -- 出荷実績数
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : 鮮度条件別出荷実績取得
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    in_deliver_from_id         IN  NUMBER      -- OPM保管場所ID
   ,in_item_id                 IN  NUMBER      -- OPM品目ID
   ,id_shipment_date_from      IN  DATE        -- 出荷実績期間FROM
   ,id_shipment_date_to        IN  DATE        -- 出荷実績期間TO
   ,iv_freshness_condition     IN  VARCHAR2    -- 鮮度条件
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_START
   ,in_inventory_item_id       IN  NUMBER      -- INV品目ID
--20091201_Ver2.1_I_E_479_020_SCS.Goto_ADD_END
   ,on_shipped_quantity        OUT NUMBER      -- 出荷実績数
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_num_of_forecast
   * Description      : 出荷予測取得処理
   ***********************************************************************************/
--  PROCEDURE get_num_of_forecast(
--    in_organization_id         IN  NUMBER
--   ,in_inventory_item_id       IN  NUMBER
--   ,id_plan_date_from          IN  DATE
--   ,id_plan_date_to            IN  DATE
--   ,on_quantity                OUT NUMBER
--   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
--   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
--   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
--
  PROCEDURE get_num_of_forecast(
    in_organization_id   IN  NUMBER       -- 在庫組織ID
   ,in_inventory_item_id IN  NUMBER       -- 在庫品目ID
   ,id_plan_date_from    IN  DATE         -- 出荷予測取得期間FROM
   ,id_plan_date_to      IN  DATE         -- 出荷予測取得期間TO
   ,in_loct_id           IN  NUMBER       -- OPM保管場所ID
   ,on_quantity          OUT  NUMBER      -- 出荷予測数量
   ,ov_errbuf            OUT  VARCHAR2    -- エラー・メッセージ
   ,ov_retcode           OUT  VARCHAR2    -- リターン・コード
   ,ov_errmsg            OUT  VARCHAR2);  -- ユーザー・エラー・メッセージ
--
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : 入庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_loct_id                 IN  NUMBER      -- 保管場所ID
   ,in_item_id                 IN  NUMBER      -- 品目ID
   ,id_plan_date_from          IN  DATE        -- 計画期間From
   ,id_plan_date_to            IN  DATE        -- 計画期間To
   ,on_quantity                OUT NUMBER      -- 計画数
   ,ov_errbuf                  OUT VARCHAR2    -- エラーバッファ
   ,ov_retcode                 OUT VARCHAR2    -- エラー・メッセージ
   ,ov_errmsg                  OUT VARCHAR2);  -- リターン・コード
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : 手持在庫取得処理
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    in_loct_id                 IN  NUMBER      -- 保管場所ID
   ,in_item_id                 IN  NUMBER      -- 品目ID
   ,id_target_date             IN  DATE        -- 対象日付
   ,id_allocated_date          IN  DATE        -- 引当済日
   ,on_quantity                OUT NUMBER      -- 手持在庫数量
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ          
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード            
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : 配送リードタイム取得処理
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    id_target_date             IN  DATE        -- 対象日付
   ,iv_from_loct_code          IN  VARCHAR2    -- 出荷保管倉庫コード
   ,iv_to_loct_code            IN  VARCHAR2    -- 受入保管倉庫コード
   ,on_delivery_lt             OUT NUMBER      -- リードタイム(日)
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_working_days
   * Description      : 稼働日数取得処理
   ***********************************************************************************/
  PROCEDURE get_working_days(
    iv_calendar_code           IN  VARCHAR2    -- 製造カレンダコード
   ,in_organization_id         IN  NUMBER      -- 組織ID
   ,in_loct_id                 IN  NUMBER      -- 保管倉庫ID
   ,id_from_date               IN  DATE        -- 基点日付
   ,id_to_date                 IN  DATE        -- 終点日付
   ,on_working_days            OUT NUMBER      -- 稼働日
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : 移動依頼・割当セットAPI起動
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_mov_num                 IN  VARCHAR2    -- 移動ヘッダID
   ,iv_process_type            IN  VARCHAR2    -- 処理区分(0：加算、1：減算)
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : 倉庫情報取得処理
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    id_target_date             IN  DATE        -- 対象日付
   ,in_organization_id         IN  NUMBER      -- 組織ID
   ,ov_organization_code       OUT VARCHAR2    -- 組織コード
   ,ov_organization_name       OUT VARCHAR2    -- 組織名称
   ,on_loct_id                 OUT NUMBER      -- 保管倉庫ID
   ,ov_loct_code               OUT VARCHAR2    -- 保管倉庫コード
   ,ov_loct_name               OUT VARCHAR2    -- 保管倉庫名称
   ,ov_calendar_code           OUT VARCHAR2    -- カレンダコード
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Procedure Name   : get_critical_date_f
   * Description      : 鮮度条件基準日取得処理
   ***********************************************************************************/
  FUNCTION get_critical_date_f(
     iv_freshness_class        IN VARCHAR2     -- 鮮度条件分類
    ,in_freshness_check_value  IN NUMBER       -- 鮮度条件チェック値
    ,in_freshness_adjust_value IN NUMBER       -- 鮮度条件調整値
    ,in_max_stock_days         IN NUMBER       -- 最大在庫日数
    ,in_freshness_buffer_days  IN NUMBER       -- 鮮度条件バッファ日数
    ,id_manufacture_date       IN DATE         -- 製造年月日
    ,id_expiration_date        IN DATE         -- 賞味期限
  ) RETURN DATE;
  /**********************************************************************************
   * Procedure Name   : get_delivery_unit
   * Description      : 配送単位取得処理
   ***********************************************************************************/
  PROCEDURE get_delivery_unit(
     in_shipping_pace          IN  NUMBER      -- 出荷ペース
    ,in_palette_max_cs_qty     IN  NUMBER      -- 配数
    ,in_palette_max_step_qty   IN  NUMBER      -- 段数
    ,ov_unit_delivery          OUT VARCHAR2    -- 配送単位
    ,ov_errbuf                 OUT VARCHAR2    -- エラー・メッセージ
    ,ov_retcode                OUT VARCHAR2    -- リターン・コード
    ,ov_errmsg                 OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Function Name   : get_receipt_date
   * Description      : 着日取得処理
   ***********************************************************************************/
  PROCEDURE get_receipt_date(
    iv_calendar_code           IN  VARCHAR2    -- 製造カレンダコード
   ,in_organization_id         IN  NUMBER      -- 組織ID
   ,in_loct_id                 IN  NUMBER      -- 保管倉庫ID
   ,id_shipment_date           IN  DATE        -- 出荷日
   ,in_lead_time               IN  NUMBER      -- 配送リードタイム
   ,od_receipt_date            OUT DATE        -- 着日
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Function Name   : get_shipment_date
   * Description      : 出荷日取得処理
   ***********************************************************************************/
  PROCEDURE get_shipment_date(
    iv_calendar_code           IN  VARCHAR2    -- 製造カレンダコード
   ,in_organization_id         IN  NUMBER      -- 組織ID
   ,in_loct_id                 IN  NUMBER      -- 保管倉庫ID
   ,id_receipt_date            IN  DATE        -- 着日
   ,in_lead_time               IN  NUMBER      -- 配送リードタイム
   ,od_shipment_date           OUT DATE        -- 出荷日
   ,ov_errbuf                  OUT VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT VARCHAR2);  -- ユーザー・エラー・メッセージ
  /**********************************************************************************
   * Function Name   : get_item_category_f
   * Description      : 品目カテゴリ取得
   ***********************************************************************************/
  FUNCTION get_item_category_f(
     iv_category_set           IN  VARCHAR2    -- 品目カテゴリ名
    ,in_item_id                IN  NUMBER      -- 品目ID
  ) RETURN VARCHAR2;
  /**********************************************************************************
   * Function Name   : get_last_arrival_date_f
   * Description      : 最終入庫日取得
   ***********************************************************************************/
  FUNCTION get_last_arrival_date_f(
    in_rcpt_loct_id            IN  NUMBER      -- 移動先保管倉庫ID
   ,in_ship_loct_id            IN  NUMBER      -- 移動元保管倉庫ID
   ,in_item_id                 IN  NUMBER      -- 品目ID
  ) RETURN DATE;
  /**********************************************************************************
   * Function Name   : get_last_purchase_date_f
   * Description      : 最終購入日取得
   ***********************************************************************************/
  FUNCTION get_last_purchase_date_f(
    in_loct_id              IN     NUMBER,     --   保管倉庫ID
    in_item_id              IN     NUMBER      --   品目ID
  ) RETURN DATE;
--
END XXCOP_COMMON_PKG2;
/
