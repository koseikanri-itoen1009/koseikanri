/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_SUBINVENTORY_INFO_V
 * Description     : ÛÇêîñr[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/17    1.0   SCS S.Moriyama   VKì¬
 *  2017/01/23    1.1   SCSK S.Yamashita E_{Ò®_13965Î
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_SUBINVENTORY_INFO_V
  (organization_id                                                    -- ÝÉgDID
  ,subinventory_code                                                  -- ÛÇêR[h
  ,subinventory_name                                                  -- ÛÇê¼Ì
  ,management_base_code                                               -- Ç_R[h
  ,store_code                                                         -- qÉR[h
  ,shop_code                                                          -- XÜR[h
  ,subinventory_class                                                 -- ÛÇêæª
  ,delivery_code                                                      -- zæR[h
  ,employee_code                                                      -- cÆõR[h
  ,customer_code                                                      -- ÚqR[h
  ,invetory_class                                                     -- Iµæª
  ,main_store_class                                                   -- CqÉæª
  ,base_code                                                          -- ÆR[h
  ,sold_out_time                                                      -- èØêÔ
  ,replenishment_rate                                                 -- â[¦
  ,hot_inventory                                                      -- zbgÝÉ
  ,auto_confirmation_flag                                             -- ©®üÉmF
  ,chain_shop_code                                                    -- `F[XR[h
  ,subinventory_type                                                  -- ÛÇêªÞ
  ,disable_date                                                       -- ³øú
  ,material_account                                                   -- ¼ÚÞ¿ïCCID 
-- Ver.1.1 S.Yamashita ADD Start
  ,warehouse_flag                                                     -- qÉÇÎÛæª
-- Ver.1.1 S.Yamashita ADD End
  )
AS
SELECT msi.organization_id                                            -- ÝÉgDID
      ,msi.secondary_inventory_name                                   -- ÛÇêR[h
      ,msi.description                                                -- ÛÇê¼Ì
      ,SUBSTRB(msi.secondary_inventory_name,2,4)                      -- Ç_R[h
      ,DECODE(msi.attribute1,1,SUBSTRB(msi.secondary_inventory_name,6,2) 
                            ,4,SUBSTRB(msi.secondary_inventory_name,6,2) 
                              ,NULL)                                  -- qÉR[h
      ,DECODE(msi.attribute13,9,SUBSTRB(msi.secondary_inventory_name,6,5)
                               ,NULL)                                 -- XÜR[h
      ,msi.attribute1                                                 -- ÛÇêæª
      ,msi.attribute2                                                 -- zæR[h
      ,msi.attribute3                                                 -- cÆõR[h
      ,msi.attribute4                                                 -- ÚqR[h
      ,msi.attribute5                                                 -- Iµæª
      ,msi.attribute6                                                 -- CqÉæª
      ,msi.attribute7                                                 -- ÆR[h
      ,msi.attribute8                                                 -- èØêÔ
      ,msi.attribute9                                                 -- â[¦
      ,msi.attribute10                                                -- zbgÝÉ
      ,msi.attribute11                                                -- ©®üÉmF
      ,msi.attribute12                                                -- `F[XR[h
      ,msi.attribute13                                                -- ÛÇêªÞ
      ,msi.disable_date                                               -- ³øú
      ,msi.material_account                                           -- ¼ÚÞ¿ïCCID 
-- Ver.1.1 S.Yamashita ADD Start
      ,msi.attribute14                                                -- qÉÇÎÛæª
-- Ver.1.1 S.Yamashita ADD End
FROM   mtl_secondary_inventories msi                                  -- ÛÇê}X^
/
COMMENT ON TABLE xxcoi_subinventory_info_v IS 'ÛÇêîñr[';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.organization_id IS 'ÝÉgDID';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_code IS 'ÛÇêR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_name IS 'ÛÇê¼Ì';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.management_base_code IS 'Ç_R[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.store_code IS 'qÉR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.shop_code IS 'XÜR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_class IS 'ÛÇêæª';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.delivery_code IS 'zæR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.employee_code IS 'cÆõR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.customer_code IS 'ÚqR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.invetory_class IS 'Iµæª';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.main_store_class IS 'CqÉæª';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.base_code IS 'ÆR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.sold_out_time IS 'èØêÔ';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.replenishment_rate IS 'â[¦';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.hot_inventory IS 'zbgÝÉ';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.auto_confirmation_flag IS '©®üÉmF';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.chain_shop_code IS '`F[XR[h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_type IS 'ÛÇêªÞ';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.disable_date IS '³øú';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.material_account IS '¼ÚÞ¿ïCCID';
/
-- Ver.1.1 S.Yamashita ADD Start
COMMENT ON COLUMN xxcoi_subinventory_info_v.warehouse_flag IS 'qÉÇÎÛæª';
/
-- Ver.1.1 S.Yamashita ADD End