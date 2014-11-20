/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_TXN_ENABLE_ITEM_INFO_V
 * Description     : 在庫取引可能品目ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-03    1.0   SCS M.Yoshioka   新規作成
 *  2008-12-26    1.1   SCS H.Nakajima   Disc品目アドオンの結合条件を変更
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_TXN_ENABLE_ITEM_INFO_V
  (row_id
  ,inventory_item_id                                                  -- 品目ID
  ,organization_id                                                    -- 在庫組織ID
  ,item_code                                                          -- 品目コード
  ,item_short_name                                                    -- 品目略称
  ,primary_uom_code                                                   -- 基準単位
  ,policy_group_apply_date                                            -- 群ｺｰﾄﾞ適用開始日
  ,policy_group_new                                                   -- 群コード(新)
  ,policy_group_old                                                   -- 旧群コード
  ,discrete_cost_apply_date                                           -- 営業原価適用開始日
  ,discrete_cost_new                                                  -- 営業原価(新)
  ,discrete_cost_old                                                  -- 旧営業原価
  ,fixed_price_apply_date                                             -- 定価適用開始日
  ,fixed_price_new                                                    -- 定価(新)
  ,fixed_price_old                                                    -- 旧定価
  ,case_in_qty                                                        -- ケース入数
  ,start_date_active                                                  -- OPM適用開始日
  ,end_date_active                                                    -- OPM適用終了日
  ,active_flag                                                        -- OPM適用済フラグ
  ,baracha_div                                                        -- バラ茶区分
  )
AS
SELECT msib.rowid                                                     -- rowid
      ,msib.inventory_item_id                                         -- 品目ID
      ,msib.organization_id                                           -- 在庫組織ID
      ,msib.segment1                                                  -- 品目コード
      ,ximb.item_short_name                                           -- 品目略称
      ,msib.primary_uom_code                                          -- 基準単位
      ,iimb.attribute3                                                -- 群ｺｰﾄﾞ適用開始日
      ,iimb.attribute2                                                -- 群コード(新)
      ,iimb.attribute1                                                -- 旧群コード
      ,iimb.attribute9                                                -- 営業原価適用開始日
      ,iimb.attribute8                                                -- 営業原価(新)
      ,iimb.attribute7                                                -- 旧営業原価
      ,iimb.attribute6                                                -- 定価適用開始日
      ,iimb.attribute5                                                -- 定価(新)
      ,iimb.attribute4                                                -- 旧定価
      ,iimb.attribute11                                               -- ケース入数
      ,ximb.start_date_active                                         -- 適用開始日
      ,ximb.end_date_active                                           -- 適用終了日
      ,ximb.active_flag                                               -- 適用済フラグ
      ,xsib.baracha_div                                               -- バラ茶区分
FROM   mtl_system_items_b   msib                                      -- Disc品目
      ,ic_item_mst_b        iimb                                      -- OPM品目
      ,xxcmn_item_mst_b     ximb                                      -- OPM品目アドオン
      ,xxcmm_system_items_b xsib                                      -- Disc品目アドオン
WHERE msib.segment1 = iimb.item_no
  AND msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
  AND msib.inventory_item_status_code <> 'Inactive'
  AND msib.customer_order_enabled_flag = 'Y'
  AND msib.mtl_transactions_enabled_flag = 'Y'
  AND msib.stock_enabled_flag = 'Y'
  AND msib.returnable_flag = 'Y'
  AND iimb.item_id = ximb.item_id
  AND iimb.item_id = xsib.item_id 
  AND iimb.attribute26 = '1'
/
COMMENT ON TABLE xxcoi_txn_enable_item_info_v IS '在庫取引可能品目ビュー'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.inventory_item_id IS '品目ID'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.organization_id IS '在庫組織ID'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.item_code IS '品目コード'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.item_short_name IS '品目略称'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.primary_uom_code IS '基準単位'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_apply_date IS '群ｺｰﾄﾞ適用開始日'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_new IS '群コード(新)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.policy_group_old IS '旧群コード'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_apply_date IS '営業原価適用開始日'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_new IS '営業原価(新)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.discrete_cost_old IS '旧営業原価'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_apply_date IS '定価適用開始日'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_new IS '定価(新)'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.fixed_price_old IS '旧定価'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.case_in_qty IS 'ケース入数'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.start_date_active IS 'OPM適用開始日'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.end_date_active IS 'OPM適用終了日'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.active_flag IS 'OPM適用済フラグ'
/
COMMENT ON COLUMN xxcoi_txn_enable_item_info_v.baracha_div IS 'バラ茶区分'
/
