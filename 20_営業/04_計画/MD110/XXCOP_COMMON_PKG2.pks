create or replace PACKAGE XXCOP_COMMON_PKG2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(spec)
 * Description      : 共通関数パッケージ2(計画)
 * MD.050           : 共通関数    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 * get_item_info             10.品目情報取得処理
 * get_org_info              11.組織情報取得処理
 * get_num_of_shipped        12.出荷実績取得処理
 * get_num_of_forcast        13.出荷予測取得処理
 * get_stock_plan            14.入庫予定取得処理
 * get_onhand_qty            15.手持在庫取得処理
 * get_deliv_lead_time       16.配送リードタイム取得処理
 * get_unit_delivery         17.配送単位取得処理
 * get_working_days          18.稼働日数取得処理
 * chk_item_exists           19.在庫品目チェック
 * get_scheduled_trans       20.入出庫予定取得処理
 * upd_assignment            21.移動依頼・割当セットAPI起動
 * get_loct_info             22.倉庫情報取得処理
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0                   新規作成
 *
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
    in_inventory_item_id IN  NUMBER,
    on_item_id           OUT  NUMBER,
    ov_item_no           OUT  VARCHAR2,
    ov_item_name         OUT  VARCHAR2,
    ov_prod_class_code   OUT  VARCHAR2,
    on_num_of_case       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_org_info
   * Description      : 組織情報取得処理
   ***********************************************************************************/
  PROCEDURE get_org_info(
    in_organization_id   IN  NUMBER,
    ov_organization_code OUT  VARCHAR2,
    ov_whse_name         OUT  VARCHAR2,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_num_of_shipped
   * Description      : 出荷実績取得処理
   ***********************************************************************************/
  PROCEDURE get_num_of_shipped(
    iv_organization_code IN  VARCHAR2,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_num_of_forcast
   * Description      : 出荷予測取得処理
   ***********************************************************************************/
  PROCEDURE get_num_of_forcast(
    in_organization_id   IN  NUMBER,
    in_inventory_item_id IN  NUMBER,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);   --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_stock_plan
   * Description      : 入庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_stock_plan(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_plan_date_from    IN  DATE,
    id_plan_date_to      IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_onhand_qty
   * Description      : 手持在庫取得処理
   ***********************************************************************************/
  PROCEDURE get_onhand_qty(
    iv_organization_code IN  VARCHAR2,
    in_item_id           IN  NUMBER,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_deliv_lead_time
   * Description      : 配送リードタイム取得処理
   ***********************************************************************************/
  PROCEDURE get_deliv_lead_time(
    iv_from_org_code     IN  VARCHAR2,
    iv_to_org_code       IN  VARCHAR2,
    id_product_date      IN  DATE,
    on_delivery_lt       OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_unit_delivery
   * Description      : 配送単位取得処理
   ***********************************************************************************/
  PROCEDURE get_unit_delivery(
    in_item_id           IN  NUMBER,
    id_ship_date         IN  DATE,
    on_palette_max_cs_qty        OUT  NUMBER,
    on_palette_max_step_qty    OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_working_days
   * Description      : 稼働日数取得処理
   ***********************************************************************************/
  PROCEDURE get_working_days(
    in_organization_id   IN  NUMBER,
    id_from_date     IN     DATE,           --   基点日付
    id_to_date       IN     DATE,           --   終点日付
    on_working_days  OUT    NUMBER,
    ov_errbuf        OUT    VARCHAR2,       --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT    VARCHAR2,       --   リターン・コード             --# 固定 #
    ov_errmsg        OUT    VARCHAR2        --   ユーザー・エラー・メッセージ --# 固定 #
  );
  /**********************************************************************************
   * Procedure Name   : chk_item_exists
   * Description      : 在庫品目チェック
   ***********************************************************************************/
  PROCEDURE chk_item_exists(
    in_inventory_item_id IN  NUMBER,
    in_organization_id   IN  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);
  /**********************************************************************************
   * Procedure Name   : get_scheduled_trans
   * Description      : 入出庫予定取得処理
   ***********************************************************************************/
  PROCEDURE get_scheduled_trans(
    in_organization_id   IN  NUMBER,
    iv_item_no           IN  VARCHAR2,
    id_date_from         IN  DATE,
    id_date_to           IN  DATE,
    on_quantity          OUT  NUMBER,
    ov_errbuf            OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode           OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg            OUT  VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : upd_assignment
   * Description      : 移動依頼・割当セットAPI起動
   ***********************************************************************************/
  PROCEDURE upd_assignment(
    iv_ship_to_locat_code   IN  VARCHAR2,     -- 入庫先
    iv_item_code            IN  VARCHAR2,     -- 品目
    in_quantity             IN  NUMBER,       -- 移動数(0以上:加算、0未満:減算)
    iv_design_prod_date     IN  VARCHAR2,     -- 指定製造日
    iv_sche_arriv_date      IN  VARCHAR2,     -- 着日
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
  /**********************************************************************************
   * Procedure Name   : get_loct_info
   * Description      : 倉庫情報取得処理
   ***********************************************************************************/
  PROCEDURE get_loct_info(
    iv_organization_code    IN  VARCHAR2,     -- 組織コード
    ov_loct_code            OUT VARCHAR2,     -- 倉庫コード
    ov_loct_name            OUT VARCHAR2,     -- 倉庫名
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2);    --   ユーザー・エラー・メッセージ --# 固定 #
--
END XXCOP_COMMON_PKG2;
/
