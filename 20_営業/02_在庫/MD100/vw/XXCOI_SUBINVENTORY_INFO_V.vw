/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_SUBINVENTORY_INFO_V
 * Description     : 保管場所情報ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/17    1.0   SCS S.Moriyama   新規作成
 *  2017/01/23    1.1   SCSK S.Yamashita E_本稼動_13965対応
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_SUBINVENTORY_INFO_V
  (organization_id                                                    -- 在庫組織ID
  ,subinventory_code                                                  -- 保管場所コード
  ,subinventory_name                                                  -- 保管場所名称
  ,management_base_code                                               -- 管轄拠点コード
  ,store_code                                                         -- 倉庫コード
  ,shop_code                                                          -- 店舗コード
  ,subinventory_class                                                 -- 保管場所区分
  ,delivery_code                                                      -- 配送先コード
  ,employee_code                                                      -- 営業員コード
  ,customer_code                                                      -- 顧客コード
  ,invetory_class                                                     -- 棚卸区分
  ,main_store_class                                                   -- メイン倉庫区分
  ,base_code                                                          -- 事業所コード
  ,sold_out_time                                                      -- 売り切れ時間
  ,replenishment_rate                                                 -- 補充率
  ,hot_inventory                                                      -- ホット在庫
  ,auto_confirmation_flag                                             -- 自動入庫確認
  ,chain_shop_code                                                    -- チェーン店コード
  ,subinventory_type                                                  -- 保管場所分類
  ,disable_date                                                       -- 無効日
  ,material_account                                                   -- 直接材料費CCID 
-- Ver.1.1 S.Yamashita ADD Start
  ,warehouse_flag                                                     -- 倉庫管理対象区分
-- Ver.1.1 S.Yamashita ADD End
  )
AS
SELECT msi.organization_id                                            -- 在庫組織ID
      ,msi.secondary_inventory_name                                   -- 保管場所コード
      ,msi.description                                                -- 保管場所名称
      ,SUBSTRB(msi.secondary_inventory_name,2,4)                      -- 管轄拠点コード
      ,DECODE(msi.attribute1,1,SUBSTRB(msi.secondary_inventory_name,6,2) 
                            ,4,SUBSTRB(msi.secondary_inventory_name,6,2) 
                              ,NULL)                                  -- 倉庫コード
      ,DECODE(msi.attribute13,9,SUBSTRB(msi.secondary_inventory_name,6,5)
                               ,NULL)                                 -- 店舗コード
      ,msi.attribute1                                                 -- 保管場所区分
      ,msi.attribute2                                                 -- 配送先コード
      ,msi.attribute3                                                 -- 営業員コード
      ,msi.attribute4                                                 -- 顧客コード
      ,msi.attribute5                                                 -- 棚卸区分
      ,msi.attribute6                                                 -- メイン倉庫区分
      ,msi.attribute7                                                 -- 事業所コード
      ,msi.attribute8                                                 -- 売り切れ時間
      ,msi.attribute9                                                 -- 補充率
      ,msi.attribute10                                                -- ホット在庫
      ,msi.attribute11                                                -- 自動入庫確認
      ,msi.attribute12                                                -- チェーン店コード
      ,msi.attribute13                                                -- 保管場所分類
      ,msi.disable_date                                               -- 無効日
      ,msi.material_account                                           -- 直接材料費CCID 
-- Ver.1.1 S.Yamashita ADD Start
      ,msi.attribute14                                                -- 倉庫管理対象区分
-- Ver.1.1 S.Yamashita ADD End
FROM   mtl_secondary_inventories msi                                  -- 保管場所マスタ
/
COMMENT ON TABLE xxcoi_subinventory_info_v IS '保管場所情報ビュー';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_code IS '保管場所コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_name IS '保管場所名称';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.management_base_code IS '管理拠点コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.store_code IS '倉庫コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.shop_code IS '店舗コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_class IS '保管場所区分';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.delivery_code IS '配送先コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.employee_code IS '営業員コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.customer_code IS '顧客コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.invetory_class IS '棚卸区分';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.main_store_class IS 'メイン倉庫区分';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.base_code IS '事業所コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.sold_out_time IS '売り切れ時間';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.replenishment_rate IS '補充率';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.hot_inventory IS 'ホット在庫';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.auto_confirmation_flag IS '自動入庫確認';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.chain_shop_code IS 'チェーン店コード';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_type IS '保管場所分類';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.disable_date IS '無効日';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.material_account IS '直接材料費CCID';
/
-- Ver.1.1 S.Yamashita ADD Start
COMMENT ON COLUMN xxcoi_subinventory_info_v.warehouse_flag IS '倉庫管理対象区分';
/
-- Ver.1.1 S.Yamashita ADD End