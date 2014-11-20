/*************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 * 
 * View Name       : XXCOP_ALL_CATEGORIES_V
 * Description     : �v��_�S�i�ڃJ�e�S���r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2013/11/26    1.0   S.Niki       ����쐬
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
  SELECT  mcsb.category_set_id    AS category_set_id    -- �J�e�S���Z�b�gID
  ,       mcst.category_set_name  AS category_set_name  -- �J�e�S���Z�b�g��
  ,       mcb.category_id         AS category_id        -- �J�e�S��ID
  ,       mcb.segment1            AS segment1           -- �J�e�S���l
  ,       mct.description         AS description        -- �E�v
  FROM    mtl_categories_b      mcb    -- �i�ڃJ�e�S���}�X�^
  ,       mtl_categories_tl     mct    -- �i�ڃJ�e�S���}�X�^���{��
  ,       mtl_category_sets_b   mcsb   -- �i�ڃJ�e�S���Z�b�g
  ,       mtl_category_sets_tl  mcst   -- �i�ڃJ�e�S���Z�b�g���{��
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
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_set_id       IS '�J�e�S���Z�b�gID';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_set_name     IS '�J�e�S���Z�b�g��';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.category_id           IS '�J�e�S��ID';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.segment1              IS '�J�e�S���l';
COMMENT ON COLUMN XXCOP_ALL_CATEGORIES_V.description           IS '�J�e�S���E�v';
--
COMMENT ON TABLE  XXCOP_ALL_CATEGORIES_V                       IS '�v��_�S�i�ڃJ�e�S���r���[';
