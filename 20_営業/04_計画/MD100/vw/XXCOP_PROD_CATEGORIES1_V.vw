/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_PROD_CATEGORIES1_V
 * Description     : 計画_カテゴリビュー1
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-10-30    1.0   SCS.Kikuchi     新規作成
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_PROD_CATEGORIES1_V
  ( "PROD_CLASS_CODE"							-- 商品区分
  , "PROD_CLASS_NAME"							-- 商品区分名
  )
AS 
  SELECT  mcb.segment1    AS prod_class_code	-- 商品区分
  ,       mct.description AS prod_class_name	-- 商品区分名
  FROM    mtl_categories_b      mcb				-- 品目カテゴリマスタ
  ,       mtl_categories_tl     mct				-- 品目カテゴリマスタ日本語
  ,       mtl_category_sets_b   mcsb			-- 品目カテゴリセット
  ,       mtl_category_sets_tl  mcst			-- 品目カテゴリセット日本語
  WHERE   mcst.category_set_name = '商品区分'
  AND     mcst.language          = USERENV('LANG')
  AND     mcst.source_lang       = USERENV('LANG')
  AND     mcsb.category_set_id   = mcst.category_set_id
  AND     mcsb.structure_id      = mcb.structure_id
  AND     mct.category_id        = mcb.category_id
  AND     mct.language           = USERENV('LANG')
  AND     mct.source_lang        = USERENV('LANG')
  ;
--
COMMENT ON TABLE XXCOP_PROD_CATEGORIES1_V IS '計画_カテゴリビュー1'
/
--
COMMENT ON COLUMN XXCOP_PROD_CATEGORIES1_V.prod_class_code IS '商品区分'
/
COMMENT ON COLUMN XXCOP_PROD_CATEGORIES1_V.prod_class_name IS '商品区分名'
/
