/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_ITEM_CATEGORIES1_V
 * Description     : 計画_品目カテゴリビュー1
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-10-30    1.0   SCS.Kikuchi     新規作成
 *  2009-06-10    1.1   SCS.Kikuchi     抽出条件：カテゴリ名称修正(障害T1_1386)
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_ITEM_CATEGORIES1_V
  ( "INVENTORY_ITEM_ID"							-- INV品目ID
  , "ORGANIZATION_ID"							-- 組織ＩＤ
  , "ITEM_ID"									-- OPM品目ID
  , "ITEM_NO"									-- 品目NO
  , "START_DATE_ACTIVE"							-- 適用開始日
  , "END_DATE_ACTIVE"							-- 適用終了日
  , "ITEM_SHORT_NAME"							-- 品目略称
  , "PROD_CLASS_CODE"							-- 商品区分
  , "PROD_CLASS_NAME"							-- 商品区分名
  , "CROWD_CLASS_CODE"							-- 群コード
  , "CROWD_CLASS_NAME"							-- 群コード名
  , "NUM_OF_CASES"								-- ケース入数
  , "PARENT_INVENTORY_ITEM_ID"					-- INV親品目ID
  , "PARENT_ITEM_ID"							-- OPM親品目ID
  , "PARENT_ITEM_NO"							-- 親品目NO
  , "INACTIVE_IND"								-- 無効
  , "INVENTORY_ITEM_STATUS_CODE"				-- 品目ステータス
  , "OBSOLETE_CLASS"							-- 廃止区分
  )
AS 
SELECT msib.inventory_item_id					-- INV品目ID
     , msib.organization_id						-- 組織ＩＤ
     , iimb.item_id								-- OPM品目ID
     , iimb.item_no								-- 品目NO
     , ximb.start_date_active					-- 適用開始日
     , ximb.end_date_active						-- 適用終了日
     , ximb.item_short_name						-- 品目略称
     , mcb_s.segment1    AS prod_class_code		-- 商品区分
     , mct_s.description AS prod_class_name		-- 商品区分名
     , mcb_h.segment1    AS crowd_class_code	-- 群コード
     , mct_h.description AS crowd_class_name	-- 群コード名
     , iimb.attribute11							-- ケース入数
     , msib_p.inventory_item_id					-- INV親品目ID
     , iimb_p.item_id							-- OPM親品目ID
     , iimb_p.item_no							-- 親品目NO
     , iimb.inactive_ind						-- 無効
     , msib.inventory_item_status_code			-- 品目ステータス
     , ximb.obsolete_class						-- 廃止区分
  FROM ic_item_mst_b          iimb				-- OPM品目マスタ
     , mtl_system_items_b     msib				-- Disc品目マスタ
     , xxcmn_item_mst_b       ximb				-- OPM品目アドオンマスタ
     , gmi_item_categories    gic_s				-- OPM品目カテゴリ割当
     , mtl_categories_b       mcb_s				-- 品目カテゴリマスタ
     , mtl_categories_tl      mct_s				-- 品目カテゴリマスタ日本語
     , mtl_category_sets_b    mcsb_s			-- 品目カテゴリセット
     , mtl_category_sets_tl   mcst_s			-- 品目カテゴリセット日本語
     , gmi_item_categories    gic_h				-- OPM品目カテゴリ割当
     , mtl_categories_b       mcb_h				-- 品目カテゴリマスタ
     , mtl_categories_tl      mct_h				-- 品目カテゴリマスタ日本語
     , mtl_category_sets_b    mcsb_h			-- 品目カテゴリセット
     , mtl_category_sets_tl   mcst_h			-- 品目カテゴリセット日本語
     , mtl_system_items_b     msib_p			-- Disc品目マスタ
     , ic_item_mst_b          iimb_p			-- OPM品目マスタ
 WHERE msib.segment1            = iimb.item_no
  AND  msib.organization_id     = fnd_profile.value('XXCMN_MASTER_ORG_ID')
  AND  ximb.item_id             = iimb.item_id
  AND  iimb.item_id             = gic_s.item_id
  AND  mct_s.source_lang        = USERENV('LANG')
  AND  mct_s.language           = USERENV('LANG')
  AND  mcb_s.category_id        = mct_s.category_id
  AND  mcsb_s.structure_id      = mcb_s.structure_id
  AND  gic_s.category_id        = mcb_s.category_id
  AND  mcst_s.source_lang       = USERENV('LANG')
  AND  mcst_s.language          = USERENV('LANG')
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_START
--  AND  mcst_s.category_set_name = '商品区分'
  AND  mcst_s.category_set_name = '本社商品区分'
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_END
  AND  mcsb_s.category_set_id   = mcst_s.category_set_id
  AND  gic_s.category_set_id    = mcsb_s.category_set_id
  AND  gic_s.item_id            = gic_h.item_id
  AND  mct_h.source_lang        = USERENV('LANG')
  AND  mct_h.language           = USERENV('LANG')
  AND  mcb_h.category_id        = mct_h.category_id
  AND  mcsb_h.structure_id      = mcb_h.structure_id
  AND  gic_h.category_id        = mcb_h.category_id
  AND  mcst_h.source_lang       = USERENV('LANG')
  AND  mcst_h.language          = USERENV('LANG')
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_START
--  AND  mcst_h.category_set_name = '群コード'
  AND  mcst_h.category_set_name = '政策群コード'
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_END
  AND  mcsb_h.category_set_id   = mcst_h.category_set_id
  AND  gic_h.category_set_id    = mcsb_h.category_set_id
  AND  iimb_p.item_id           = ximb.parent_item_id
  AND  msib_p.segment1          = iimb_p.item_no
  AND  msib_p.organization_id   = fnd_profile.value('XXCMN_MASTER_ORG_ID')
  ;
--
COMMENT ON TABLE XXCOP_ITEM_CATEGORIES1_V IS '計画_品目カテゴリビュー1'
/
--
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INVENTORY_ITEM_ID          IS 'INV品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ORGANIZATION_ID            IS '組織ＩＤ'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_ID                    IS 'OPM品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_NO                    IS '品目NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.START_DATE_ACTIVE          IS '適用開始日'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.END_DATE_ACTIVE            IS '適用終了日'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_SHORT_NAME            IS '品目略称'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PROD_CLASS_CODE            IS '商品区分'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PROD_CLASS_NAME            IS '商品区分名'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.CROWD_CLASS_CODE           IS '群コード'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.CROWD_CLASS_NAME           IS '群コード名'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.NUM_OF_CASES               IS 'ケース入数'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_INVENTORY_ITEM_ID   IS 'INV親品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_ITEM_ID             IS 'OPM親品目ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_ITEM_NO             IS '親品目NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INACTIVE_IND               IS '無効'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INVENTORY_ITEM_STATUS_CODE IS '品目ステータス'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.OBSOLETE_CLASS             IS '廃止区分'
/
