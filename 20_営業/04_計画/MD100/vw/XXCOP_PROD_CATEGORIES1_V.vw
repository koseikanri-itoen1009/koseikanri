/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_PROD_CATEGORIES1_V
 * Description     : �v��_�J�e�S���r���[1
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-10-30    1.0   SCS.Kikuchi     �V�K�쐬
 *  2009-06-10    1.1   SCS.Kikuchi     ���o�����F�J�e�S�����̏C��(��QT1_1386)
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_PROD_CATEGORIES1_V
  ( "PROD_CLASS_CODE"							-- ���i�敪
  , "PROD_CLASS_NAME"							-- ���i�敪��
  )
AS 
  SELECT  mcb.segment1    AS prod_class_code	-- ���i�敪
  ,       mct.description AS prod_class_name	-- ���i�敪��
  FROM    mtl_categories_b      mcb				-- �i�ڃJ�e�S���}�X�^
  ,       mtl_categories_tl     mct				-- �i�ڃJ�e�S���}�X�^���{��
  ,       mtl_category_sets_b   mcsb			-- �i�ڃJ�e�S���Z�b�g
  ,       mtl_category_sets_tl  mcst			-- �i�ڃJ�e�S���Z�b�g���{��
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_START
--  WHERE   mcst.category_set_name = '���i�敪'
  WHERE   mcst.category_set_name = '�{�Џ��i�敪'
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_END
  AND     mcst.language          = USERENV('LANG')
  AND     mcst.source_lang       = USERENV('LANG')
  AND     mcsb.category_set_id   = mcst.category_set_id
  AND     mcsb.structure_id      = mcb.structure_id
  AND     mct.category_id        = mcb.category_id
  AND     mct.language           = USERENV('LANG')
  AND     mct.source_lang        = USERENV('LANG')
  ;
--
COMMENT ON TABLE XXCOP_PROD_CATEGORIES1_V IS '�v��_�J�e�S���r���[1'
/
--
COMMENT ON COLUMN XXCOP_PROD_CATEGORIES1_V.prod_class_code IS '���i�敪'
/
COMMENT ON COLUMN XXCOP_PROD_CATEGORIES1_V.prod_class_name IS '���i�敪��'
/
