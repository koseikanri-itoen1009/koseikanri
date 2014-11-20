/*************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 * 
 * View Name       : XXCOP_ALL_CATEGORIES_V
 * Description     : 計画_全品目カテゴリビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2013/11/26    1.0   S.Niki       初回作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCOP_ALL_CATEGORIES_V
( category_set_id
, category_set_name
, category_id
, segment1
, description
)
AS
  SELECT  mcsb.category_set_id    AS category_set_id    -- カテゴリセットID
  ,       mcst.category_set_name  AS category_set_name  -- カテゴリセット名
  ,       mcb.category_id         AS category_id        -- カテゴリID
  ,       mcb.segment1            AS segment1           -- カテゴリ値
  ,       mct.description         AS description        -- 摘要
  FROM    mtl_categories_b      mcb    -- 品目カテゴリマスタ
  ,       mtl_categories_tl     mct    -- 品目カテゴリマスタ日本語
  ,       mtl_category_sets_b   mcsb   -- 品目カテゴリセット
  ,       mtl_category_sets_tl  mcst   -- 品目カテゴリセット日本語
  WHERE   mcst.language          = USERENV('LANG')
  AND     mcst.source_lang       = USERENV('LANG')
  AND     mcsb.category_set_id   = mcst.category_set_id
  AND     mcsb.structure_id      = mcb.structure_id
  AND     mct.category_id        = mcb.category_id
  AND     mct.language           = USERENV('LANG')
  AND     mct.source_lang        = USERENV('LANG')
  AND   ( mcb.disable_date       IS NULL
    OR    mcb.disable_date       > xxccp_common_pkg2.get_process_date )
  ORDER BY mcst.category_set_name
  ,        mcb.segment1
  ;
--
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_set_id       IS 'カテゴリセットID';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_set_name     IS 'カテゴリセット名';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_id           IS 'カテゴリID';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.segment1              IS 'カテゴリ値';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.description           IS 'カテゴリ摘要';
--
COMMENT ON TABLE  XXCOP_ALL_CATEGORIES_V                       IS '計画_全品目カテゴリビュー';
