/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_order_number_v
 * Description     : �L���ώ󒍔ԍ��擾
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Atsushiba      �V�K�쐬
 *  2009/06/04    1.1   T.Miyata         T1_1314�Ή�
 *  2009/07/07    1.2   T.Miyata         0000478�Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_order_number_v (
  order_number,                         -- �󒍔ԍ�
  shipping_instructions                 -- �o�׎w��
)
AS
  SELECT DISTINCT
         ooha.order_number                               order_number
         ,SUBSTRB( ooha.shipping_instructions, 1, 20 )   shipping_instructions
  FROM   oe_order_headers_all                   ooha               -- �󒍃w�b�_
        ,oe_order_lines_all                     oola               -- �󒍖���
        ,hz_cust_accounts                       hca                -- �ڋq�}�X�^
        ,mtl_system_items_b                     msib               -- �i�ڃ}�X�^
        ,oe_transaction_types_tl                ottah              -- �󒍎���^�C�v�i�󒍃w�b�_�p�j
        ,oe_transaction_types_tl                ottal              -- �󒍎���^�C�v�i�󒍖��חp�j
        ,mtl_secondary_inventories              msi                -- �ۊǏꏊ�}�X�^
        ,xxcmn_item_categories5_v               xicv               -- ���i�敪View
        ,xxcmm_cust_accounts                    xca                -- �ڋq�ǉ����
        ,hz_cust_acct_sites_all                 sites              -- �ڋq���ݒn
        ,hz_cust_site_uses_all                  uses               -- �ڋq�g�p�ړI
        ,hz_party_sites                         hps                -- �p�[�e�B�T�C�g�}�X�^
        ,hz_locations                           hl                 -- �p�[�e�B�T�C�g�}�X�^
        ,fnd_lookup_values                      flv_tran           -- LookUp�Q�ƃe�[�u��(����.�󒍃^�C�v)
        ,fnd_lookup_values                      flv_hokan          -- LookUp�Q�ƃe�[�u��(�ۊǏꏊ)
        ,hr_operating_units                     hou                -- �c�ƒP�ʃ}�X�^
  WHERE ooha.header_id                          = oola.header_id                         -- �w�b�_�[ID
  AND   ooha.booked_flag                        = 'Y'                                    -- �X�e�[�^�X(�L��)
  AND   oola.flow_status_code                   NOT IN ('CANCELLED','CLOSED')            -- �X�e�[�^�X(����)
  AND   ooha.sold_to_org_id                     = hca.cust_account_id                    -- �ڋqID
  AND   ooha.order_type_id                      = ottah.transaction_type_id              -- ����^�C�vID(�w�b�_�[)
  AND   ottah.language                          = USERENV('LANG')
  AND   ottah.name                              = flv_tran.attribute1                    -- ����^�C�v��(�w�b�_�[)
  AND   oola.line_type_id                       = ottal.transaction_type_id              -- ����^�C�vID(����)
  AND   ottal.language                          = USERENV('LANG')
  AND   ottal.name                              = flv_tran.attribute2                    -- ����^�C�v��(����)
  AND   oola.subinventory                       = msi.secondary_inventory_name           -- �ۊǏꏊ
  AND   msi.attribute13                         = flv_hokan.meaning                      -- �ۊǏꏊ�敪
  AND   oola.packing_instructions               IS NULL
  AND   NVL(oola.attribute6,oola.ordered_item) 
            NOT IN ( SELECT flv_non_inv.lookup_code
                     FROM   fnd_lookup_values             flv_non_inv
                     WHERE  flv_non_inv.lookup_type       = 'XXCOS1_NO_INV_ITEM_CODE'
                     AND    flv_non_inv.language          = USERENV('LANG')
                     AND    flv_non_inv.enabled_flag      = 'Y')
  AND   NVL(oola.attribute6,oola.ordered_item) 
            NOT IN ( SELECT flv_err.lookup_code
                     FROM   fnd_lookup_values             flv_err
                     WHERE  flv_err.lookup_type           = 'XXCOS1_EDI_ITEM_ERR_TYPE'
                     AND    flv_err.language              = USERENV('LANG')
                     AND    flv_err.enabled_flag          = 'Y')
  AND   xca.customer_id = hca.cust_account_id
  AND   oola.org_id                             = FND_PROFILE.VALUE('ORG_ID')               -- �c�ƒP��
  AND   oola.ordered_item                       = msib.segment1                             -- �i�ڃR�[�h
  AND   xicv.item_no                            = msib.segment1                             -- �i�ڃR�[�h
  AND   msib.organization_id                    = oola.ship_from_org_id                     -- �g�DID
  AND   hca.cust_account_id                     = sites.cust_account_id                     -- �ڋqID
  AND   sites.cust_acct_site_id                 = uses.cust_acct_site_id                    -- �ڋq�T�C�gID
  AND   hca.customer_class_code                 = '10'                                      -- �ڋq�敪
  AND   uses.site_use_code                      = 'SHIP_TO'                                 -- �g�p�ړI
  AND   sites.org_id                            = hou.organization_id                       -- ���Y�c�ƒP��
  AND   uses.org_id                             = hou.organization_id                       -- ���Y�c�ƒP��
--****************************** 2009/07/07 1.2 T.Miyata ADD  START ******************************--
  AND   sites.status                            = 'A'                                       -- �ڋq���ݒn.�X�e�[�^�X
--****************************** 2009/07/07 1.2 T.Miyata ADD  END   ******************************--
  AND   sites.party_site_id                     = hps.party_site_id                         -- �p�[�e�B�T�C�gID
  AND   hps.location_id                         = hl.location_id                            -- ���Ə�ID
  AND   hca.account_number                      IS NOT NULL                                 -- �A�J�E���g�ԍ�
  AND   hl.province                             IS NOT NULL                                 -- �z����R�[�h
  AND   hou.name                                = FND_PROFILE.VALUE('XXCOS1_ITOE_OU_MFG')   -- ���Y�c�ƒP��
  AND   flv_tran.lookup_type                    = 'XXCOS1_TRAN_TYPE_MST_008_A01'
  AND   flv_tran.language                       = USERENV('LANG')
  AND   flv_tran.enabled_flag                   = 'Y'
  AND   flv_hokan.lookup_type                   = 'XXCOS1_HOKAN_DIRECT_TYPE_MST'
  AND   flv_hokan.lookup_code                   = 'XXCOS_DIRECT_11'
  AND   flv_hokan.language                      = USERENV('LANG')
  AND   flv_hokan.enabled_flag                  = 'Y'
  ;
COMMENT ON  COLUMN  xxcos_order_number_v.order_number           IS  '�󒍔ԍ�';
COMMENT ON  COLUMN  xxcos_order_number_v.shipping_instructions  IS  '�o�׎w��';
--
COMMENT ON  TABLE   xxcos_order_number_v                        IS  '�L���ώ󒍔ԍ��擾';
