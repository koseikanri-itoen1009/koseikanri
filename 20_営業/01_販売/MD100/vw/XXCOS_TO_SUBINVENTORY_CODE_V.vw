/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_to_subinventory_code_v
 * Description     : EDI������ۊǏꏊ�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   S.Nakamura       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_to_subinventory_code_v (
  secondary_inventory_name  --�ۊǏꏊ�R�[�h
 ,description               --�K�p
)
AS
  SELECT  DISTINCT
          msi.secondary_inventory_name  secondary_inventory_name  --�ۊǏꏊ�R�[�h
         ,msi.description               description               --�K�p
  FROM    xxcos_login_base_info_v    xlbiv --���O�C�����[�U���_�r���[
         ,xxcmm_cust_accounts        xca   --�ڋq�ǉ����
         ,mtl_secondary_inventories  msi   --�ۊǏꏊ�}�X�^
         ,mtl_parameters             mp    --�݌ɑg�D�}�X�^
         ,fnd_lookup_values_vl       flvv  --�N�C�b�N�R�[�h
  WHERE  xca.delivery_base_code        = xlbiv.base_code                                  --����(�ڋq�ǉ�=���_)
  AND    msi.secondary_inventory_name  = xca.ship_storage_code                            --����(�ۊǏꏊ=�ڋq�ǉ�)
  AND    msi.attribute13               = '3'                                              --�݌Ɍ^�Z���^�[
  AND    mp.organization_id            = msi.organization_id                              --����(�݌ɑg�D=�ۊǏꏊ)
  AND    mp.organization_code          = FND_PROFILE.VALUE( 'XXCOI1_ORGANIZATION_CODE' )  --�݌ɑg�D�R�[�h
  AND    flvv.lookup_type              = 'XXCOS1_EDI_CONTROL_LIST'                        --EDI������
  AND    flvv.attribute1               = xca.chain_store_code                             --����(�N�C�b�N=�ڋq�ǉ�)
  AND    flvv.attribute2               = '22'                                             --���ɗ\��Ώ�
  AND    flvv.attribute3               = '01'                                             --���񏈗��ԍ�('01'�Œ�)
  AND    flvv.enabled_flag             = 'Y'                                              --�L��
  AND    (
           ( flvv.start_date_active IS NULL )
           OR
           ( flvv.start_date_active <= TRUNC(SYSDATE) )
         )
  AND    (
           ( flvv.end_date_active IS NULL )
           OR
           ( flvv.end_date_active >= TRUNC(SYSDATE) )
         )                                                                                --�������t��FROM-TO��
;
COMMENT ON  COLUMN  xxcos_to_subinventory_code_v.secondary_inventory_name  IS  '�ۊǏꏊ�R�[�h';
COMMENT ON  COLUMN  xxcos_to_subinventory_code_v.description               IS  '�K�p';
--
COMMENT ON  TABLE   xxcos_to_subinventory_code_v                           IS  'EDI������ۊǏꏊ�r���[';
