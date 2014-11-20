/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_ITEM_CATEGORIES1_V
 * Description     : �v��_�i�ڃJ�e�S���r���[1
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
CREATE OR REPLACE FORCE VIEW XXCOP_ITEM_CATEGORIES1_V
  ( "INVENTORY_ITEM_ID"							-- INV�i��ID
  , "ORGANIZATION_ID"							-- �g�D�h�c
  , "ITEM_ID"									-- OPM�i��ID
  , "ITEM_NO"									-- �i��NO
  , "START_DATE_ACTIVE"							-- �K�p�J�n��
  , "END_DATE_ACTIVE"							-- �K�p�I����
  , "ITEM_SHORT_NAME"							-- �i�ڗ���
  , "PROD_CLASS_CODE"							-- ���i�敪
  , "PROD_CLASS_NAME"							-- ���i�敪��
  , "CROWD_CLASS_CODE"							-- �Q�R�[�h
  , "CROWD_CLASS_NAME"							-- �Q�R�[�h��
  , "NUM_OF_CASES"								-- �P�[�X����
  , "PARENT_INVENTORY_ITEM_ID"					-- INV�e�i��ID
  , "PARENT_ITEM_ID"							-- OPM�e�i��ID
  , "PARENT_ITEM_NO"							-- �e�i��NO
  , "INACTIVE_IND"								-- ����
  , "INVENTORY_ITEM_STATUS_CODE"				-- �i�ڃX�e�[�^�X
  , "OBSOLETE_CLASS"							-- �p�~�敪
  )
AS 
SELECT msib.inventory_item_id					-- INV�i��ID
     , msib.organization_id						-- �g�D�h�c
     , iimb.item_id								-- OPM�i��ID
     , iimb.item_no								-- �i��NO
     , ximb.start_date_active					-- �K�p�J�n��
     , ximb.end_date_active						-- �K�p�I����
     , ximb.item_short_name						-- �i�ڗ���
     , mcb_s.segment1    AS prod_class_code		-- ���i�敪
     , mct_s.description AS prod_class_name		-- ���i�敪��
     , mcb_h.segment1    AS crowd_class_code	-- �Q�R�[�h
     , mct_h.description AS crowd_class_name	-- �Q�R�[�h��
     , iimb.attribute11							-- �P�[�X����
     , msib_p.inventory_item_id					-- INV�e�i��ID
     , iimb_p.item_id							-- OPM�e�i��ID
     , iimb_p.item_no							-- �e�i��NO
     , iimb.inactive_ind						-- ����
     , msib.inventory_item_status_code			-- �i�ڃX�e�[�^�X
     , ximb.obsolete_class						-- �p�~�敪
  FROM ic_item_mst_b          iimb				-- OPM�i�ڃ}�X�^
     , mtl_system_items_b     msib				-- Disc�i�ڃ}�X�^
     , xxcmn_item_mst_b       ximb				-- OPM�i�ڃA�h�I���}�X�^
     , gmi_item_categories    gic_s				-- OPM�i�ڃJ�e�S������
     , mtl_categories_b       mcb_s				-- �i�ڃJ�e�S���}�X�^
     , mtl_categories_tl      mct_s				-- �i�ڃJ�e�S���}�X�^���{��
     , mtl_category_sets_b    mcsb_s			-- �i�ڃJ�e�S���Z�b�g
     , mtl_category_sets_tl   mcst_s			-- �i�ڃJ�e�S���Z�b�g���{��
     , gmi_item_categories    gic_h				-- OPM�i�ڃJ�e�S������
     , mtl_categories_b       mcb_h				-- �i�ڃJ�e�S���}�X�^
     , mtl_categories_tl      mct_h				-- �i�ڃJ�e�S���}�X�^���{��
     , mtl_category_sets_b    mcsb_h			-- �i�ڃJ�e�S���Z�b�g
     , mtl_category_sets_tl   mcst_h			-- �i�ڃJ�e�S���Z�b�g���{��
     , mtl_system_items_b     msib_p			-- Disc�i�ڃ}�X�^
     , ic_item_mst_b          iimb_p			-- OPM�i�ڃ}�X�^
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
--  AND  mcst_s.category_set_name = '���i�敪'
  AND  mcst_s.category_set_name = '�{�Џ��i�敪'
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
--  AND  mcst_h.category_set_name = '�Q�R�[�h'
  AND  mcst_h.category_set_name = '����Q�R�[�h'
--20090610_Ver1.1_T1_1386_SCS.Kikuchi_MOD_END
  AND  mcsb_h.category_set_id   = mcst_h.category_set_id
  AND  gic_h.category_set_id    = mcsb_h.category_set_id
  AND  iimb_p.item_id           = ximb.parent_item_id
  AND  msib_p.segment1          = iimb_p.item_no
  AND  msib_p.organization_id   = fnd_profile.value('XXCMN_MASTER_ORG_ID')
  ;
--
COMMENT ON TABLE XXCOP_ITEM_CATEGORIES1_V IS '�v��_�i�ڃJ�e�S���r���[1'
/
--
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INVENTORY_ITEM_ID          IS 'INV�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ORGANIZATION_ID            IS '�g�D�h�c'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_ID                    IS 'OPM�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_NO                    IS '�i��NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.START_DATE_ACTIVE          IS '�K�p�J�n��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.END_DATE_ACTIVE            IS '�K�p�I����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.ITEM_SHORT_NAME            IS '�i�ڗ���'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PROD_CLASS_CODE            IS '���i�敪'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PROD_CLASS_NAME            IS '���i�敪��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.CROWD_CLASS_CODE           IS '�Q�R�[�h'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.CROWD_CLASS_NAME           IS '�Q�R�[�h��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.NUM_OF_CASES               IS '�P�[�X����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_INVENTORY_ITEM_ID   IS 'INV�e�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_ITEM_ID             IS 'OPM�e�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.PARENT_ITEM_NO             IS '�e�i��NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INACTIVE_IND               IS '����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.INVENTORY_ITEM_STATUS_CODE IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES1_V.OBSOLETE_CLASS             IS '�p�~�敪'
/
