/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_ITEM_CATEGORIES2_V
 * Description     : �v��_�i�ڃJ�e�S���r���[2
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-11-09    1.0   SCS.Hokkanji     �V�K�쐬(I_E_637�Ή�)
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW XXCOP_ITEM_CATEGORIES2_V
  ( "INVENTORY_ITEM_ID"           -- INV�i��ID
  , "ORGANIZATION_ID"             -- �g�DID
  , "ITEM_ID"                     -- OPM�i��ID
  , "ITEM_NO"                     -- �i��NO
  , "START_DATE_ACTIVE"           -- �K�p�J�n��
  , "END_DATE_ACTIVE"             -- �K�p�I����
  , "ITEM_SHORT_NAME"             -- �i�ڗ���
  , "PROD_CLASS_CODE"             -- ���i�敪
  , "PROD_CLASS_NAME"             -- ���i�敪��
  , "CROWD_CLASS_CODE"            -- �Q�R�[�h
  , "CROWD_CLASS_NAME"            -- �Q�R�[�h��
  , "NUM_OF_CASES"                -- �P�[�X����
  , "PARENT_INVENTORY_ITEM_ID"    -- INV�e�i��ID
  , "PARENT_ITEM_ID"              -- OPM�e�i��ID
  , "PARENT_ITEM_NO"              -- �e�i��NO
  , "INACTIVE_IND"                -- ����
  , "INVENTORY_ITEM_STATUS_CODE"  -- �i�ڃX�e�[�^�X
  , "OBSOLETE_CLASS"              -- �p�~�敪
  )
AS 
SELECT /*+ USE_NL(iimb gic_bp gic_ip gic_ic gic_cc mcsv_bp mcsv_ip mcv_bp mcv_ip) */
       iimb.inventory_item_id             -- INV�i��ID
      ,iimb.organization_id               -- �g�DID
      ,iimb.item_id                       -- OPM�i��ID
      ,iimb.item_no                       -- �i��NO
      ,iimb.start_date_active             -- �K�p�J�n��
      ,iimb.end_date_active               -- �K�p�I����
      ,iimb.item_short_name               -- �i�ڗ���
      ,mcv_bp.segment1                    -- ���i�敪
      ,mcv_bp.description                 -- ���i�敪��
      ,gic_cc.segment1                    -- �Q�R�[�h
      ,gic_cc.description                 -- �Q�R�[�h��
      ,iimb.case_qty                      -- �P�[�X����
      ,iimb.p_inventory_item_id           -- INV�e�i��ID
      ,iimb.p_item_id                     -- OPM�e�i��ID
      ,iimb.p_item_no                     -- �e�i��NO
      ,iimb.inactive_ind                  -- ����
      ,iimb.inventory_item_status_code    -- �i�ڃX�e�[�^�X
      ,iimb.obsolete_class                -- �p�~�敪
FROM   gmi_item_categories      gic_bp    -- OPM�i�ڃJ�e�S������
      ,mtl_category_sets_vl     mcsv_bp   -- �i�ڃJ�e�S���Z�b�g
      ,mtl_categories_vl        mcv_bp    -- �i�ڃJ�e�S��
      ,gmi_item_categories      gic_ip    -- OPM�i�ڃJ�e�S������
      ,mtl_category_sets_vl     mcsv_ip   -- �i�ڃJ�e�S���Z�b�g
      ,mtl_categories_vl        mcv_ip    -- �i�ڃJ�e�S��
      ,(SELECT /*+ LEADING(iimb ximb iimb_p disc disc_p xsib) USE_NL(iimb ximb iimb_p disc disc_p xsib) */
                iimb.item_id                     item_id                     -- OPM�i��ID
               ,iimb.item_no                     item_no                     -- �i��NO
               ,iimb.attribute11                 case_qty                    -- �P�[�X����
               ,iimb.inactive_ind                inactive_ind                -- ����
               ,ximb.item_short_name             item_short_name             -- �i�ڗ���
               ,iimb_p.item_id                   p_item_id                   -- OPM�e�i��ID
               ,iimb_p.item_no                   p_item_no                   -- �e�i��NO
               ,ximb.start_date_active           start_date_active           -- �K�p�J�n��
               ,ximb.end_date_active             end_date_active             -- �K�p�I����
               ,ximb.obsolete_class              obsolete_class              -- �p�~�敪
               ,disc.inventory_item_id           inventory_item_id           -- DISC�i��ID
               ,disc.organization_id             organization_id             -- �g�DID
               ,disc_p.inventory_item_id         p_inventory_item_id         -- DISC�i��ID(�e�i��)
               ,disc.inventory_item_status_code  inventory_item_status_code  -- �i�ڃX�e�[�^�X
        FROM    ic_item_mst_b         iimb    -- OPM�i�ڃ}�X�^
               ,xxcmn_item_mst_b      ximb    -- OPM�i�ڃA�h�I���}�X�^
               ,ic_item_mst_b         iimb_p  -- OPM�i�ڃ}�X�^(�e�i�ڎ擾)
               ,mtl_system_items_b    disc    -- DISC�i�ڃ}�X�^
               ,mtl_system_items_b    disc_p  -- DISC�i�ڃ}�X�^(�e�i�ڎ擾)
               ,xxcmm_system_items_b  xsib    -- DISC�i�ڃA�h�I���}�X�^
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
       )                        iimb      -- �i�ڏ��i���C���j
      ,(SELECT  /*+ USE_NL(mcsv gic mcv) */
                gic.item_id                   -- OPM�i��ID
               ,mcv.segment1                  -- �J�e�S���R�[�h
               ,mcv.description               -- �J�e�S������
        FROM    gmi_item_categories     gic   -- OPM�i�ڃJ�e�S������
               ,mtl_category_sets_vl    mcsv  -- �i�ڃJ�e�S���Z�b�g
               ,mtl_categories_vl       mcv   -- �i�ڃJ�e�S��
        WHERE   gic.category_set_id    = mcsv.category_set_id
        AND     gic.category_id        = mcv.category_id
        AND     mcsv.category_set_name = '����Q�R�[�h'
       )                         gic_cc    -- �i�ڃJ�e�S��(����Q�R�[�h)
      ,(SELECT  /*+ USE_NL(mcsv gic mcv) */
                gic.item_id                 -- OPM�i��ID
               ,mcv.description
        FROM    gmi_item_categories   gic   -- OPM�i�ڃJ�e�S������
               ,mtl_category_sets_vl  mcsv  -- �i�ڃJ�e�S���Z�b�g
               ,mtl_categories_vl     mcv   -- �i�ڃJ�e�S��
        WHERE   gic.category_set_id    = mcsv.category_set_id
        AND     gic.category_id        = mcv.category_id
        AND     mcsv.category_set_name = '�i�ڋ敪'
        )                        gic_ic    -- �i�ڃJ�e�S��(�i�ڋ敪�R�[�h)
WHERE   iimb.item_id              = gic_cc.item_id(+)
AND     iimb.item_id              = gic_ic.item_id(+)
AND     iimb.item_id              = gic_ip.item_id
AND     gic_ip.category_set_id    = mcsv_ip.category_set_id
AND     gic_ip.category_id        = mcv_ip.category_id
AND     mcsv_ip.category_set_name = '���i���i�敪'
AND     mcv_ip.description        = '���i'
AND     iimb.item_id              = gic_bp.item_id
AND     gic_bp.category_set_id    = mcsv_bp.category_set_id
AND     gic_bp.category_id        = mcv_bp.category_id
AND     mcsv_bp.category_set_name = '�{�Џ��i�敪'
AND     (   gic_ic.description    = '���i'
         OR gic_ic.description   IS NULL)
;
--
COMMENT ON TABLE XXCOP_ITEM_CATEGORIES2_V IS '�v��_�i�ڃJ�e�S���r���[2'
/
--
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INVENTORY_ITEM_ID          IS 'INV�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ORGANIZATION_ID            IS '�g�DID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_ID                    IS 'OPM�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_NO                    IS '�i��NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.START_DATE_ACTIVE          IS '�K�p�J�n��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.END_DATE_ACTIVE            IS '�K�p�I����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.ITEM_SHORT_NAME            IS '�i�ڗ���'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PROD_CLASS_CODE            IS '���i�敪'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PROD_CLASS_NAME            IS '���i�敪��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.CROWD_CLASS_CODE           IS '�Q�R�[�h'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.CROWD_CLASS_NAME           IS '�Q�R�[�h��'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.NUM_OF_CASES               IS '�P�[�X����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_INVENTORY_ITEM_ID   IS 'INV�e�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_ITEM_ID             IS 'OPM�e�i��ID'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.PARENT_ITEM_NO             IS '�e�i��NO'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INACTIVE_IND               IS '����'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.INVENTORY_ITEM_STATUS_CODE IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN XXCOP_ITEM_CATEGORIES2_V.OBSOLETE_CLASS             IS '�p�~�敪'
/
