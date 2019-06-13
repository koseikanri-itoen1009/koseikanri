CREATE OR REPLACE VIEW XXCMM_OPMMTL_ITEMS_V
AS
SELECT    o_itm.item_id                               AS  item_id                        -- OPM品目 品目ID
         ,o_itm.item_no                               AS  item_no                        -- OPM品目 品目コード
         ,o_itm.item_desc1                            AS  item_desc1                     -- OPM品目 摘要
         ,o_itm.attribute1                            AS  crowd_code_old                 -- OPM品目 旧群コード
         ,o_itm.attribute2                            AS  crowd_code_new                 -- OPM品目 新群コード
         ,TO_DATE(o_itm.attribute3, 'RRRR/MM/DD')     AS  crowd_code_apply_date          -- OPM品目 群コード適用開始日
         ,o_itm.attribute26                           AS  sales_div                      -- OPM品目 売上対象区分
         ,TO_NUMBER(o_itm.attribute11)                AS  num_of_cases                   -- OPM品目 ケース入数
         ,TO_NUMBER(o_itm.attribute12)                AS  net                            -- OPM品目 NET
-- ↓2009/03/19 Add Start
--         ,TO_NUMBER(o_itm.attribute25)                AS  unit                           -- OPM品目 重量
         ,DECODE( o_itm.attribute10
                 ,'1', TO_NUMBER(o_itm.attribute25)   -- 重量容積区分=1：重量  重量(ATTRIBUTE25)を設定
                 ,'2', TO_NUMBER(o_itm.attribute16)   -- 重量容積区分=2：容積  容積(ATTRIBUTE16)を設定
--                 ,NULL )                              AS  unit                           -- OPM品目 重量
                 ,TO_NUMBER(o_itm.attribute25) )      AS  unit                           -- OPM品目 重量
-- ↑2009/03/19 Add End
         ,o_itm.attribute21                           AS  jan_code                       -- OPM品目 JANコード
         ,TO_DATE(o_itm.attribute13, 'RRRR/MM/DD')    AS  sell_start_date                -- OPM品目 発売（製造）開始日
         ,o_itm.item_um                               AS  item_um                        -- OPM品目 単位
         ,o_itm.attribute22                           AS  itf_code                       -- OPM品目 ITFコード
         ,TO_NUMBER(o_itm.attribute4)                 AS  price_old                      -- OPM品目 定価（旧）
         ,TO_NUMBER(o_itm.attribute5)                 AS  price_new                      -- OPM品目 定価（新）
         ,TO_DATE(o_itm.attribute6, 'RRRR/MM/DD')     AS  price_apply_date               -- OPM品目 定価適用開始日
         ,TO_NUMBER(o_itm.attribute7)                 AS  opt_cost_old                   -- OPM品目 営業原価（旧）
         ,TO_NUMBER(o_itm.attribute8)                 AS  opt_cost_new                   -- OPM品目 営業原価（新）
         ,TO_DATE(o_itm.attribute9, 'RRRR/MM/DD')     AS  opt_cost_apply_date            -- OPM品目 営業原価適用開始日
         ,o_itm.last_update_date                      AS  last_update_date               -- OPM品目 最終更新日
         ,ximb.start_date_active                      AS  start_date_active              -- OPM品目アドオン 適用開始日
         ,ximb.end_date_active                        AS  end_date_active                -- OPM品目アドオン 適用終了日
         ,ximb.active_flag                            AS  active_flag                    -- OPM品目アドオン 適用済フラグ
         ,ximb.item_name                              AS  item_name                      -- OPM品目アドオン 正式名
         ,ximb.item_short_name                        AS  item_short_name                -- OPM品目アドオン 略称
         ,ximb.item_name_alt                          AS  item_name_alt                  -- OPM品目アドオン カナ名
         ,ximb.rate_class                             AS  rate_class                     -- OPM品目アドオン 率区分
         ,ximb.parent_item_id                         AS  parent_item_id                 -- OPM品目アドオン 親品目ID
         ,ximb.obsolete_class                         AS  obsolete_class                 -- OPM品目アドオン 廃止区分
         ,ximb.obsolete_date                          AS  obsolete_date                  -- OPM品目アドオン 廃止日（製造中止日）
         ,ximb.palette_max_cs_qty                     AS  palette_max_cs_qty             -- OPM品目アドオン 配数
         ,ximb.palette_max_step_qty                   AS  palette_max_step_qty           -- OPM品目アドオン パレット当り最大段数
         ,ximb.palette_step_qty                       AS  palette_step_qty               -- OPM品目アドオン パレット段（旧・率区分）
         ,ximb.product_class                          AS  product_class                  -- OPM品目アドオン 商品分類
         ,xsib.item_code                              AS  item_code                      -- Disc品目アドオン 品名コード
         ,xsib.sp_supplier_code                       AS  sp_supplier_code               -- Disc品目アドオン 専門店仕入先コード
         ,xsib.nets                                   AS  nets                           -- Disc品目アドオン 内容量
         ,xsib.nets_uom_code                          AS  nets_uom_code                  -- Disc品目アドオン 内容量単位
         ,xsib.inc_num                                AS  inc_num                        -- Disc品目アドオン 内訳入数
         ,xsib.vessel_group                           AS  vessel_group                   -- Disc品目アドオン 容器群
         ,xsib.acnt_group                             AS  acnt_group                     -- Disc品目アドオン 経理群
         ,xsib.acnt_vessel_group                      AS  acnt_vessel_group              -- Disc品目アドオン 経理容器群
         ,xsib.brand_group                            AS  brand_group                    -- Disc品目アドオン ブランド群
         ,xsib.baracha_div                            AS  baracha_div                    -- Disc品目アドオン バラ茶区分
         ,xsib.new_item_div                           AS  new_item_div                   -- Disc品目アドオン 新商品区分
         ,xsib.bowl_inc_num                           AS  bowl_inc_num                   -- Disc品目アドオン ボール入数
         ,xsib.case_jan_code                          AS  case_jan_code                  -- Disc品目アドオン ケースJANコード
         ,xsib.item_status                            AS  item_status                    -- Disc品目アドオン 品目ステータス
         ,xsib.renewal_item_code                      AS  renewal_item_code              -- Disc品目アドオン リニューアル元商品コード
         ,xsib.search_update_date                     AS  search_update_date             -- Disc品目アドオン 検索対象日時
-- Ver1.3  2009/05/07  Add H.Yoshikawa  障害No.T1_0906 対応
         ,xsib.case_conv_inc_num                      AS  case_conv_inc_num              -- Disc品目アドオン ケース換算入数
-- End
-- Ver1.4 2019/06/04 Add Start
         ,xsib.class_for_variable_tax                 AS  class_for_variable_tax         -- Disc品目アドオン 軽減税率用税種別
-- Ver1.4 2019/06/04 Add End
         ,d_itm.inventory_item_id                     AS  inventory_item_id              -- Disc品目 品目ID
         ,d_itm.organization_id                       AS  organization_id                -- Disc品目 組織ID
         ,d_itm.description                           AS  description                    -- Disc品目 摘要
         ,d_itm.purchasing_item_flag                  AS  purchasing_item_flag           -- Disc品目 購買品目
         ,d_itm.shippable_item_flag                   AS  shippable_item_flag            -- Disc品目 出荷可能
         ,d_itm.customer_order_flag                   AS  customer_order_flag            -- Disc品目 顧客受注
         ,d_itm.purchasing_enabled_flag               AS  purchasing_enabled_flag        -- Disc品目 購買可能
         ,d_itm.internal_order_enabled_flag           AS  internal_order_enabled_flag    -- Disc品目 社内発注
         ,d_itm.so_transactions_flag                  AS  so_transactions_flag           -- Disc品目 OE取引可能
         ,d_itm.reservable_type                       AS  reservable_type                -- Disc品目 予約可能
FROM      ic_item_mst_b                   o_itm    -- OPM品目マスタ
         ,xxcmn_item_mst_b                ximb     -- OPM品目アドオン
         ,xxcmm_system_items_b            xsib     -- Disc品目アドオン
         ,mtl_system_items_b              d_itm    -- Disc品目マスタ
-- Ver1.2  2009/04/08  Add H.Yoshikawa  障害No.T1_0184 対応
         ,mtl_parameters                  mp
-- End
         ,financials_system_parameters    fsp      -- 会計システムパラメータ
WHERE     o_itm.item_id          =  ximb.item_id
AND       d_itm.segment1         =  o_itm.item_no
-- Ver1.2  2009/04/08  Add H.Yoshikawa  障害No.T1_0184 対応
--AND       d_itm.organization_id  =  fsp.inventory_organization_id
AND       mp.organization_id     =  fsp.inventory_organization_id
AND       d_itm.organization_id  =  mp.master_organization_id
-- End
AND       xsib.item_code         =  o_itm.item_no
/
COMMENT ON TABLE XXCMM_OPMMTL_ITEMS_V IS 'OPM_Disc品目結合ビュー'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_ID IS 'OPM品目 品目ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NO IS 'OPM品目 品目コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_DESC1 IS 'OPM品目 摘要'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_OLD IS 'OPM品目 旧群コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_NEW IS 'OPM品目 新群コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_APPLY_DATE IS 'OPM品目 群コード適用開始日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SALES_DIV IS 'OPM品目 売上対象区分'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NUM_OF_CASES IS 'OPM品目 ケース入数'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NET IS 'OPM品目 NET'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.UNIT IS 'OPM品目 重量'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.JAN_CODE IS 'OPM品目 JANコード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SELL_START_DATE IS 'OPM品目 発売（製造）開始日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_UM IS 'OPM品目 単位'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITF_CODE IS 'OPM品目 ITFコード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_OLD IS 'OPM品目 定価（旧）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_NEW IS 'OPM品目 定価（新）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_APPLY_DATE IS 'OPM品目 定価適用開始日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_OLD IS 'OPM品目 営業原価（旧）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_NEW IS 'OPM品目 営業原価（新）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_APPLY_DATE IS 'OPM品目 営業原価適用開始日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.LAST_UPDATE_DATE IS 'OPM品目 最終更新日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.START_DATE_ACTIVE IS 'OPM品目アドオン 適用開始日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.END_DATE_ACTIVE IS 'OPM品目アドオン 適用終了日'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACTIVE_FLAG IS 'OPM品目アドオン 適用済フラグ'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NAME IS 'OPM品目アドオン 正式名'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_SHORT_NAME IS 'OPM品目アドオン 略称'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NAME_ALT IS 'OPM品目アドオン カナ名'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RATE_CLASS IS 'OPM品目アドオン 率区分'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PARENT_ITEM_ID IS 'OPM品目アドオン 親品目ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OBSOLETE_CLASS IS 'OPM品目アドオン 廃止区分'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OBSOLETE_DATE IS 'OPM品目アドオン 廃止日（製造中止日）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_MAX_CS_QTY IS 'OPM品目アドオン 配数'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_MAX_STEP_QTY IS 'OPM品目アドオン パレット当り最大段数'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_STEP_QTY IS 'OPM品目アドオン パレット段（旧・率区分）'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRODUCT_CLASS IS 'OPM品目アドオン 商品分類'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_CODE IS 'Disc品目アドオン 品名コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SP_SUPPLIER_CODE IS 'Disc品目アドオン 専門店仕入先コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NETS IS 'Disc品目アドオン 内容量'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NETS_UOM_CODE IS 'Disc品目アドオン 内容量単位'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INC_NUM IS 'Disc品目アドオン 内訳入数'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.VESSEL_GROUP IS 'Disc品目アドオン 容器群'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACNT_GROUP IS 'Disc品目アドオン 経理群'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACNT_VESSEL_GROUP IS 'Disc品目アドオン 経理容器群'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BRAND_GROUP IS 'Disc品目アドオン ブランド群'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BARACHA_DIV IS 'Disc品目アドオン バラ茶区分'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NEW_ITEM_DIV IS 'Disc品目アドオン 新商品区分'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BOWL_INC_NUM IS 'Disc品目アドオン ボール入数'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CASE_JAN_CODE IS 'Disc品目アドオン ケースJANコード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_STATUS IS 'Disc品目アドオン 品目ステータス'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RENEWAL_ITEM_CODE IS 'Disc品目アドオン リニューアル元商品コード'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SEARCH_UPDATE_DATE IS 'Disc品目アドオン 検索対象日時'
/
-- Ver1.3  2009/05/07  Add H.Yoshikawa  障害No.T1_0906 対応
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CASE_CONV_INC_NUM IS 'Disc品目アドオン ケース換算入数'
/
-- End
-- Ver1.4 2019/06/04 Add Start
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CLASS_FOR_VARIABLE_TAX IS 'Disc品目アドオン 軽減税率用税種別'
/
-- Ver1.4 2019/06/04 Add End
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INVENTORY_ITEM_ID IS 'Disc品目 品目ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ORGANIZATION_ID IS 'Disc品目 組織ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.DESCRIPTION IS 'Disc品目 摘要'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PURCHASING_ITEM_FLAG IS 'Disc品目 購買品目'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SHIPPABLE_ITEM_FLAG IS 'Disc品目 出荷可能'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CUSTOMER_ORDER_FLAG IS 'Disc品目 顧客受注'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PURCHASING_ENABLED_FLAG IS 'Disc品目 購買可能'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INTERNAL_ORDER_ENABLED_FLAG IS 'Disc品目 社内発注'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SO_TRANSACTIONS_FLAG IS 'Disc品目 OE取引可能'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RESERVABLE_TYPE IS 'Disc品目 予約可能'
/
