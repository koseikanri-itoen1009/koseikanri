CREATE OR REPLACE VIEW XXCMM_OPMMTL_ITEMS_V
AS
SELECT    o_itm.item_id                               AS  item_id                        -- OPM�i�� �i��ID
         ,o_itm.item_no                               AS  item_no                        -- OPM�i�� �i�ڃR�[�h
         ,o_itm.item_desc1                            AS  item_desc1                     -- OPM�i�� �E�v
         ,o_itm.attribute1                            AS  crowd_code_old                 -- OPM�i�� ���Q�R�[�h
         ,o_itm.attribute2                            AS  crowd_code_new                 -- OPM�i�� �V�Q�R�[�h
         ,TO_DATE(o_itm.attribute3, 'RRRR/MM/DD')     AS  crowd_code_apply_date          -- OPM�i�� �Q�R�[�h�K�p�J�n��
         ,o_itm.attribute26                           AS  sales_div                      -- OPM�i�� ����Ώۋ敪
         ,TO_NUMBER(o_itm.attribute11)                AS  num_of_cases                   -- OPM�i�� �P�[�X����
         ,TO_NUMBER(o_itm.attribute12)                AS  net                            -- OPM�i�� NET
-- ��2009/03/19 Add Start
--         ,TO_NUMBER(o_itm.attribute25)                AS  unit                           -- OPM�i�� �d��
         ,DECODE( o_itm.attribute10
                 ,'1', TO_NUMBER(o_itm.attribute25)   -- �d�ʗe�ϋ敪=1�F�d��  �d��(ATTRIBUTE25)��ݒ�
                 ,'2', TO_NUMBER(o_itm.attribute16)   -- �d�ʗe�ϋ敪=2�F�e��  �e��(ATTRIBUTE16)��ݒ�
--                 ,NULL )                              AS  unit                           -- OPM�i�� �d��
                 ,TO_NUMBER(o_itm.attribute25) )      AS  unit                           -- OPM�i�� �d��
-- ��2009/03/19 Add End
         ,o_itm.attribute21                           AS  jan_code                       -- OPM�i�� JAN�R�[�h
         ,TO_DATE(o_itm.attribute13, 'RRRR/MM/DD')    AS  sell_start_date                -- OPM�i�� �����i�����j�J�n��
         ,o_itm.item_um                               AS  item_um                        -- OPM�i�� �P��
         ,o_itm.attribute22                           AS  itf_code                       -- OPM�i�� ITF�R�[�h
         ,TO_NUMBER(o_itm.attribute4)                 AS  price_old                      -- OPM�i�� �艿�i���j
         ,TO_NUMBER(o_itm.attribute5)                 AS  price_new                      -- OPM�i�� �艿�i�V�j
         ,TO_DATE(o_itm.attribute6, 'RRRR/MM/DD')     AS  price_apply_date               -- OPM�i�� �艿�K�p�J�n��
         ,TO_NUMBER(o_itm.attribute7)                 AS  opt_cost_old                   -- OPM�i�� �c�ƌ����i���j
         ,TO_NUMBER(o_itm.attribute8)                 AS  opt_cost_new                   -- OPM�i�� �c�ƌ����i�V�j
         ,TO_DATE(o_itm.attribute9, 'RRRR/MM/DD')     AS  opt_cost_apply_date            -- OPM�i�� �c�ƌ����K�p�J�n��
         ,o_itm.last_update_date                      AS  last_update_date               -- OPM�i�� �ŏI�X�V��
         ,ximb.start_date_active                      AS  start_date_active              -- OPM�i�ڃA�h�I�� �K�p�J�n��
         ,ximb.end_date_active                        AS  end_date_active                -- OPM�i�ڃA�h�I�� �K�p�I����
         ,ximb.active_flag                            AS  active_flag                    -- OPM�i�ڃA�h�I�� �K�p�σt���O
         ,ximb.item_name                              AS  item_name                      -- OPM�i�ڃA�h�I�� ������
         ,ximb.item_short_name                        AS  item_short_name                -- OPM�i�ڃA�h�I�� ����
         ,ximb.item_name_alt                          AS  item_name_alt                  -- OPM�i�ڃA�h�I�� �J�i��
         ,ximb.rate_class                             AS  rate_class                     -- OPM�i�ڃA�h�I�� ���敪
         ,ximb.parent_item_id                         AS  parent_item_id                 -- OPM�i�ڃA�h�I�� �e�i��ID
         ,ximb.obsolete_class                         AS  obsolete_class                 -- OPM�i�ڃA�h�I�� �p�~�敪
         ,ximb.obsolete_date                          AS  obsolete_date                  -- OPM�i�ڃA�h�I�� �p�~���i�������~���j
         ,ximb.palette_max_cs_qty                     AS  palette_max_cs_qty             -- OPM�i�ڃA�h�I�� �z��
         ,ximb.palette_max_step_qty                   AS  palette_max_step_qty           -- OPM�i�ڃA�h�I�� �p���b�g����ő�i��
         ,ximb.palette_step_qty                       AS  palette_step_qty               -- OPM�i�ڃA�h�I�� �p���b�g�i�i���E���敪�j
         ,ximb.product_class                          AS  product_class                  -- OPM�i�ڃA�h�I�� ���i����
         ,xsib.item_code                              AS  item_code                      -- Disc�i�ڃA�h�I�� �i���R�[�h
         ,xsib.sp_supplier_code                       AS  sp_supplier_code               -- Disc�i�ڃA�h�I�� ���X�d����R�[�h
         ,xsib.nets                                   AS  nets                           -- Disc�i�ڃA�h�I�� ���e��
         ,xsib.nets_uom_code                          AS  nets_uom_code                  -- Disc�i�ڃA�h�I�� ���e�ʒP��
         ,xsib.inc_num                                AS  inc_num                        -- Disc�i�ڃA�h�I�� �������
         ,xsib.vessel_group                           AS  vessel_group                   -- Disc�i�ڃA�h�I�� �e��Q
         ,xsib.acnt_group                             AS  acnt_group                     -- Disc�i�ڃA�h�I�� �o���Q
         ,xsib.acnt_vessel_group                      AS  acnt_vessel_group              -- Disc�i�ڃA�h�I�� �o���e��Q
         ,xsib.brand_group                            AS  brand_group                    -- Disc�i�ڃA�h�I�� �u�����h�Q
         ,xsib.baracha_div                            AS  baracha_div                    -- Disc�i�ڃA�h�I�� �o�����敪
         ,xsib.new_item_div                           AS  new_item_div                   -- Disc�i�ڃA�h�I�� �V���i�敪
         ,xsib.bowl_inc_num                           AS  bowl_inc_num                   -- Disc�i�ڃA�h�I�� �{�[������
         ,xsib.case_jan_code                          AS  case_jan_code                  -- Disc�i�ڃA�h�I�� �P�[�XJAN�R�[�h
         ,xsib.item_status                            AS  item_status                    -- Disc�i�ڃA�h�I�� �i�ڃX�e�[�^�X
         ,xsib.renewal_item_code                      AS  renewal_item_code              -- Disc�i�ڃA�h�I�� ���j���[�A�������i�R�[�h
         ,xsib.search_update_date                     AS  search_update_date             -- Disc�i�ڃA�h�I�� �����Ώۓ���
         ,d_itm.inventory_item_id                     AS  inventory_item_id              -- Disc�i�� �i��ID
         ,d_itm.organization_id                       AS  organization_id                -- Disc�i�� �g�DID
         ,d_itm.description                           AS  description                    -- Disc�i�� �E�v
         ,d_itm.purchasing_item_flag                  AS  purchasing_item_flag           -- Disc�i�� �w���i��
         ,d_itm.shippable_item_flag                   AS  shippable_item_flag            -- Disc�i�� �o�׉\
         ,d_itm.customer_order_flag                   AS  customer_order_flag            -- Disc�i�� �ڋq��
         ,d_itm.purchasing_enabled_flag               AS  purchasing_enabled_flag        -- Disc�i�� �w���\
         ,d_itm.internal_order_enabled_flag           AS  internal_order_enabled_flag    -- Disc�i�� �Г�����
         ,d_itm.so_transactions_flag                  AS  so_transactions_flag           -- Disc�i�� OE����\
         ,d_itm.reservable_type                       AS  reservable_type                -- Disc�i�� �\��\
FROM      ic_item_mst_b                   o_itm    -- OPM�i�ڃ}�X�^
         ,xxcmn_item_mst_b                ximb     -- OPM�i�ڃA�h�I��
         ,xxcmm_system_items_b            xsib     -- Disc�i�ڃA�h�I��
         ,mtl_system_items_b              d_itm    -- Disc�i�ڃ}�X�^
-- Ver1.2  2009/04/08  Add H.Yoshikawa  ��QNo.T1_0184 �Ή�
         ,mtl_parameters                  mp
-- End
         ,financials_system_parameters    fsp      -- ��v�V�X�e���p�����[�^
WHERE     o_itm.item_id          =  ximb.item_id
AND       d_itm.segment1         =  o_itm.item_no
-- Ver1.2  2009/04/08  Add H.Yoshikawa  ��QNo.T1_0184 �Ή�
--AND       d_itm.organization_id  =  fsp.inventory_organization_id
AND       mp.organization_id     =  fsp.inventory_organization_id
AND       d_itm.organization_id  =  mp.master_organization_id
-- End
AND       xsib.item_code         =  o_itm.item_no
/
COMMENT ON TABLE XXCMM_OPMMTL_ITEMS_V IS 'OPM_Disc�i�ڌ����r���['
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_ID IS 'OPM�i�� �i��ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NO IS 'OPM�i�� �i�ڃR�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_DESC1 IS 'OPM�i�� �E�v'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_OLD IS 'OPM�i�� ���Q�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_NEW IS 'OPM�i�� �V�Q�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CROWD_CODE_APPLY_DATE IS 'OPM�i�� �Q�R�[�h�K�p�J�n��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SALES_DIV IS 'OPM�i�� ����Ώۋ敪'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NUM_OF_CASES IS 'OPM�i�� �P�[�X����'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NET IS 'OPM�i�� NET'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.UNIT IS 'OPM�i�� �d��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.JAN_CODE IS 'OPM�i�� JAN�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SELL_START_DATE IS 'OPM�i�� �����i�����j�J�n��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_UM IS 'OPM�i�� �P��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITF_CODE IS 'OPM�i�� ITF�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_OLD IS 'OPM�i�� �艿�i���j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_NEW IS 'OPM�i�� �艿�i�V�j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRICE_APPLY_DATE IS 'OPM�i�� �艿�K�p�J�n��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_OLD IS 'OPM�i�� �c�ƌ����i���j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_NEW IS 'OPM�i�� �c�ƌ����i�V�j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OPT_COST_APPLY_DATE IS 'OPM�i�� �c�ƌ����K�p�J�n��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.LAST_UPDATE_DATE IS 'OPM�i�� �ŏI�X�V��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.START_DATE_ACTIVE IS 'OPM�i�ڃA�h�I�� �K�p�J�n��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.END_DATE_ACTIVE IS 'OPM�i�ڃA�h�I�� �K�p�I����'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACTIVE_FLAG IS 'OPM�i�ڃA�h�I�� �K�p�σt���O'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NAME IS 'OPM�i�ڃA�h�I�� ������'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_SHORT_NAME IS 'OPM�i�ڃA�h�I�� ����'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_NAME_ALT IS 'OPM�i�ڃA�h�I�� �J�i��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RATE_CLASS IS 'OPM�i�ڃA�h�I�� ���敪'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PARENT_ITEM_ID IS 'OPM�i�ڃA�h�I�� �e�i��ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OBSOLETE_CLASS IS 'OPM�i�ڃA�h�I�� �p�~�敪'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.OBSOLETE_DATE IS 'OPM�i�ڃA�h�I�� �p�~���i�������~���j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_MAX_CS_QTY IS 'OPM�i�ڃA�h�I�� �z��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_MAX_STEP_QTY IS 'OPM�i�ڃA�h�I�� �p���b�g����ő�i��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PALETTE_STEP_QTY IS 'OPM�i�ڃA�h�I�� �p���b�g�i�i���E���敪�j'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PRODUCT_CLASS IS 'OPM�i�ڃA�h�I�� ���i����'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_CODE IS 'Disc�i�ڃA�h�I�� �i���R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SP_SUPPLIER_CODE IS 'Disc�i�ڃA�h�I�� ���X�d����R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NETS IS 'Disc�i�ڃA�h�I�� ���e��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NETS_UOM_CODE IS 'Disc�i�ڃA�h�I�� ���e�ʒP��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INC_NUM IS 'Disc�i�ڃA�h�I�� �������'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.VESSEL_GROUP IS 'Disc�i�ڃA�h�I�� �e��Q'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACNT_GROUP IS 'Disc�i�ڃA�h�I�� �o���Q'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ACNT_VESSEL_GROUP IS 'Disc�i�ڃA�h�I�� �o���e��Q'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BRAND_GROUP IS 'Disc�i�ڃA�h�I�� �u�����h�Q'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BARACHA_DIV IS 'Disc�i�ڃA�h�I�� �o�����敪'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.NEW_ITEM_DIV IS 'Disc�i�ڃA�h�I�� �V���i�敪'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.BOWL_INC_NUM IS 'Disc�i�ڃA�h�I�� �{�[������'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CASE_JAN_CODE IS 'Disc�i�ڃA�h�I�� �P�[�XJAN�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ITEM_STATUS IS 'Disc�i�ڃA�h�I�� �i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RENEWAL_ITEM_CODE IS 'Disc�i�ڃA�h�I�� ���j���[�A�������i�R�[�h'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SEARCH_UPDATE_DATE IS 'Disc�i�ڃA�h�I�� �����Ώۓ���'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INVENTORY_ITEM_ID IS 'Disc�i�� �i��ID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.ORGANIZATION_ID IS 'Disc�i�� �g�DID'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.DESCRIPTION IS 'Disc�i�� �E�v'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PURCHASING_ITEM_FLAG IS 'Disc�i�� �w���i��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SHIPPABLE_ITEM_FLAG IS 'Disc�i�� �o�׉\'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.CUSTOMER_ORDER_FLAG IS 'Disc�i�� �ڋq��'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.PURCHASING_ENABLED_FLAG IS 'Disc�i�� �w���\'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.INTERNAL_ORDER_ENABLED_FLAG IS 'Disc�i�� �Г�����'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.SO_TRANSACTIONS_FLAG IS 'Disc�i�� OE����\'
/
COMMENT ON COLUMN XXCMM_OPMMTL_ITEMS_V.RESERVABLE_TYPE IS 'Disc�i�� �\��\'
/
