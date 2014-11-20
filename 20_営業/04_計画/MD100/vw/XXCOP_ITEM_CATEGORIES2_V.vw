/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_ITEM_CATEGORIES2_V
 * Description     : 計画_品目カテゴリビュー2
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-11-09    1.0   SCS.Hokkanji     新規作成(I_E_637対応)
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_ITEM_CATEGORIES2_V
  ( "INVENTORY_ITEM_ID"           -- INV品目ID
  , "ORGANIZATION_ID"             -- 組織ID
  , "ITEM_ID"                     -- OPM品目ID
  , "ITEM_NO"                     -- 品目NO
  , "START_DATE_ACTIVE"           -- 適用開始日
  , "END_DATE_ACTIVE"             -- 適用終了日
  , "ITEM_SHORT_NAME"             -- 品目略称
  , "PROD_CLASS_CODE"             -- 商品区分
  , "PROD_CLASS_NAME"             -- 商品区分名
  , "CROWD_CLASS_CODE"            -- 群コード
  , "CROWD_CLASS_NAME"            -- 群コード名
  , "NUM_OF_CASES"                -- ケース入数
  , "PARENT_INVENTORY_ITEM_ID"    -- INV親品目ID
  , "PARENT_ITEM_ID"              -- OPM親品目ID
  , "PARENT_ITEM_NO"              -- 親品目NO
  , "INACTIVE_IND"                -- 無効
  , "INVENTORY_ITEM_STATUS_CODE"  -- 品目ステータス
  , "OBSOLETE_CLASS"              -- 廃止区分
  )
AS 
SELECT /*+ USE_NL(iimb gic_bp gic_ip gic_ic gic_cc mcsv_bp mcsv_ip mcv_bp mcv_ip) */
       iimb.inventory_item_id             -- INV品目ID
      ,iimb.organization_id               -- 組織ID
      ,iimb.item_id                       -- OPM品目ID
      ,iimb.item_no                       -- 品目NO
      ,iimb.start_date_active             -- 適用開始日
      ,iimb.end_date_active               -- 適用終了日
      ,iimb.item_short_name               -- 品目略称
      ,mcv_bp.segment1                    -- 商品区分
      ,mcv_bp.description                 -- 商品区分名
      ,gic_cc.segment1                    -- 群コード
      ,gic_cc.description                 -- 群コード名
      ,iimb.case_qty                      -- ケース入数
      ,iimb.p_inventory_item_id           -- INV親品目ID
      ,iimb.p_item_id                     -- OPM親品目ID
      ,iimb.p_item_no                     -- 親品目NO
      ,iimb.inactive_ind                  -- 無効
      ,iimb.inventory_item_status_code    -- 品目ステータス
      ,iimb.obsolete_class                -- 廃止区分
FROM   gmi_item_categories      gic_bp    -- OPM品目カテゴリ割当
      ,mtl_category_sets_vl     mcsv_bp   -- 品目カテゴリセット
      ,mtl_categories_vl        mcv_bp    -- 品目カテゴリ
      ,gmi_item_categories      gic_ip    -- OPM品目カテゴリ割当
      ,mtl_category_sets_vl     mcsv_ip   -- 品目カテゴリセット
      ,mtl_categories_vl        mcv_ip    -- 品目カテゴリ
      ,(SELECT /*+ LEADING(iimb ximb iimb_p disc disc_p xsib) USE_NL(iimb ximb iimb_p disc disc_p xsib) */
                iimb.item_id                     item_id                     -- OPM品目ID
               ,iimb.item_no                     item_no                     -- 品目NO
               ,iimb.attribute11                 case_qty                    -- ケース入数
               ,iimb.inactive_ind                inactive_ind                -- 無効
               ,ximb.item_short_name             item_short_name             -- 品目略称
               ,iimb_p.item_id                   p_item_id                   -- OPM親品目ID
               ,iimb_p.item_no                   p_item_no                   -- 親品目NO
               ,ximb.start_date_active           start_date_active           -- 適用開始日
               ,ximb.end_date_active             end_date_active             -- 適用終了日
               ,ximb.obsolete_class              obsolete_class              -- 廃止区分
               ,disc.inventory_item_id           inventory_item_id           -- DISC品目ID
               ,disc.organization_id             organization_id             -- 組織ID
               ,disc_p.inventory_item_id         p_inventory_item_id         -- DISC品目ID(親品目)
               ,disc.inventory_item_status_code  inventory_item_status_code  -- 品目ステータス
        FROM    ic_item_mst_b         iimb    -- OPM品目マスタ
               ,xxcmn_item_mst_b      ximb    -- OPM品目アドオンマスタ
               ,ic_item_mst_b         iimb_p  -- OPM品目マスタ(親品目取得)
               ,mtl_system_items_b    disc    -- DISC品目マスタ
               ,mtl_system_items_b    disc_p  -- DISC品目マスタ(親品目取得)
               ,xxcmm_system_items_b  xsib    -- DISC品目アドオンマスタ
        WHERE   iimb.item_id   = ximb.item_id
        AND     iimb_p.item_id = ximb.parent_item_id
        AND     ((    (ximb.item_id     = ximb.parent_item_id)
                  AND (iimb.attribute26 = '1')
                 )
                 OR
                 (ximb.item_id <> ximb.parent_item_id)
                )
        AND     iimb.attribute18             = '1'
        AND     ximb.obsolete_class          = '0'
        AND     iimb_p.item_no               = disc_p.segment1
        AND     iimb.item_no                 = disc.segment1
        AND     disc.segment1                = xsib.item_code
        AND     disc.organization_id         = fnd_profile.value('XXCMN_MASTER_ORG_ID')
        AND     disc_p.organization_id       = fnd_profile.value('XXCMN_MASTER_ORG_ID')
        AND     xsib.item_status             IN ('20', '30', '40')
        AND     xsib.item_status_apply_date <=  SYSDATE
       )                        iimb      -- 品目情報（メイン）
      ,(SELECT  /*+ USE_NL(mcsv gic mcv) */
                gic.item_id                   -- OPM品目ID
               ,mcv.segment1                  -- カテゴリコード
               ,mcv.description               -- カテゴリ名称
        FROM    gmi_item_categories     gic   -- OPM品目カテゴリ割当
               ,mtl_category_sets_vl    mcsv  -- 品目カテゴリセット
               ,mtl_categories_vl       mcv   -- 品目カテゴリ
        WHERE   gic.category_set_id    = mcsv.category_set_id
        AND     gic.category_id        = mcv.category_id
        AND     mcsv.category_set_name = '政策群コード'
       )                         gic_cc    -- 品目カテゴリ(政策群コード)
      ,(SELECT  /*+ USE_NL(mcsv gic mcv) */
                gic.item_id                 -- OPM品目ID
               ,mcv.description
        FROM    gmi_item_categories   gic   -- OPM品目カテゴリ割当
               ,mtl_category_sets_vl  mcsv  -- 品目カテゴリセット
               ,mtl_categories_vl     mcv   -- 品目カテゴリ
        WHERE   gic.category_set_id    = mcsv.category_set_id
        AND     gic.category_id        = mcv.category_id
        AND     mcsv.category_set_name = '品目区分'
        )                        gic_ic    -- 品目カテゴリ(品目区分コード)
WHERE   iimb.item_id              = gic_cc.item_id(+)
AND     iimb.item_id              = gic_ic.item_id(+)
AND     iimb.item_id              = gic_ip.item_id
AND     gic_ip.category_set_id    = mcsv_ip.category_set_id
AND     gic_ip.category_id        = mcv_ip.category_id
AND     mcsv_ip.category_set_name = '商品製品区分'
AND     mcv_ip.description        = '製品'
AND     iimb.item_id              = gic_bp.item_id
AND     gic_bp.category_set_id    = mcsv_bp.category_set_id
AND     gic_bp.category_id        = mcv_bp.category_id
AND     mcsv_bp.category_set_name = '本社商品区分'
AND     (   gic_ic.description    = '製品'
         OR gic_ic.description   IS NULL)
;
--
COMMENT ON TABLE XXCOP_ITEM_CATEGORIES2_V IS '計画_品目カテゴリビュー2'
/
--
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INVENTORY_ITEM_ID          IS 'INV品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ORGANIZATION_ID            IS '組織ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_ID                    IS 'OPM品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_NO                    IS '品目NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.START_DATE_ACTIVE          IS '適用開始日'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.END_DATE_ACTIVE            IS '適用終了日'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_SHORT_NAME            IS '品目略称'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PROD_CLASS_CODE            IS '商品区分'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PROD_CLASS_NAME            IS '商品区分名'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.CROWD_CLASS_CODE           IS '群コード'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.CROWD_CLASS_NAME           IS '群コード名'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.NUM_OF_CASES               IS 'ケース入数'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_INVENTORY_ITEM_ID   IS 'INV親品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_ITEM_ID             IS 'OPM親品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_ITEM_NO             IS '親品目NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INACTIVE_IND               IS '無効'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INVENTORY_ITEM_STATUS_CODE IS '品目ステータス'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.OBSOLETE_CLASS             IS '廃止区分'
/
