/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_SUBINVENTORY_INFO_V
 * Description     : �ۊǏꏊ���r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/17    1.0   SCS S.Moriyama   �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_SUBINVENTORY_INFO_V
  (organization_id                                                    -- �݌ɑg�DID
  ,subinventory_code                                                  -- �ۊǏꏊ�R�[�h
  ,subinventory_name                                                  -- �ۊǏꏊ����
  ,management_base_code                                               -- �Ǌ����_�R�[�h
  ,store_code                                                         -- �q�ɃR�[�h
  ,shop_code                                                          -- �X�܃R�[�h
  ,subinventory_class                                                 -- �ۊǏꏊ�敪
  ,delivery_code                                                      -- �z����R�[�h
  ,employee_code                                                      -- �c�ƈ��R�[�h
  ,customer_code                                                      -- �ڋq�R�[�h
  ,invetory_class                                                     -- �I���敪
  ,main_store_class                                                   -- ���C���q�ɋ敪
  ,base_code                                                          -- ���Ə��R�[�h
  ,sold_out_time                                                      -- ����؂ꎞ��
  ,replenishment_rate                                                 -- ��[��
  ,hot_inventory                                                      -- �z�b�g�݌�
  ,auto_confirmation_flag                                             -- �������Ɋm�F
  ,chain_shop_code                                                    -- �`�F�[���X�R�[�h
  ,subinventory_type                                                  -- �ۊǏꏊ����
  ,disable_date                                                       -- ������
  ,material_account                                                   -- ���ڍޗ���CCID 
  )
AS
SELECT msi.organization_id                                            -- �݌ɑg�DID
      ,msi.secondary_inventory_name                                   -- �ۊǏꏊ�R�[�h
      ,msi.description                                                -- �ۊǏꏊ����
      ,SUBSTRB(msi.secondary_inventory_name,2,4)                      -- �Ǌ����_�R�[�h
      ,DECODE(msi.attribute1,1,SUBSTRB(msi.secondary_inventory_name,6,2) 
                            ,4,SUBSTRB(msi.secondary_inventory_name,6,2) 
                              ,NULL)                                  -- �q�ɃR�[�h
      ,DECODE(msi.attribute13,9,SUBSTRB(msi.secondary_inventory_name,6,5)
                               ,NULL)                                 -- �X�܃R�[�h
      ,msi.attribute1                                                 -- �ۊǏꏊ�敪
      ,msi.attribute2                                                 -- �z����R�[�h
      ,msi.attribute3                                                 -- �c�ƈ��R�[�h
      ,msi.attribute4                                                 -- �ڋq�R�[�h
      ,msi.attribute5                                                 -- �I���敪
      ,msi.attribute6                                                 -- ���C���q�ɋ敪
      ,msi.attribute7                                                 -- ���Ə��R�[�h
      ,msi.attribute8                                                 -- ����؂ꎞ��
      ,msi.attribute9                                                 -- ��[��
      ,msi.attribute10                                                -- �z�b�g�݌�
      ,msi.attribute11                                                -- �������Ɋm�F
      ,msi.attribute12                                                -- �`�F�[���X�R�[�h
      ,msi.attribute13                                                -- �ۊǏꏊ����
      ,msi.disable_date                                               -- ������
      ,msi.material_account                                           -- ���ڍޗ���CCID 
FROM   mtl_secondary_inventories msi                                  -- �ۊǏꏊ�}�X�^
/
COMMENT ON TABLE xxcoi_subinventory_info_v IS '�ۊǏꏊ���r���[';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_code IS '�ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_name IS '�ۊǏꏊ����';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.management_base_code IS '�Ǘ����_�R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.store_code IS '�q�ɃR�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.shop_code IS '�X�܃R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_class IS '�ۊǏꏊ�敪';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.delivery_code IS '�z����R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.employee_code IS '�c�ƈ��R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.customer_code IS '�ڋq�R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.invetory_class IS '�I���敪';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.main_store_class IS '���C���q�ɋ敪';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.base_code IS '���Ə��R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.sold_out_time IS '����؂ꎞ��';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.replenishment_rate IS '��[��';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.hot_inventory IS '�z�b�g�݌�';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.auto_confirmation_flag IS '�������Ɋm�F';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.chain_shop_code IS '�`�F�[���X�R�[�h';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.subinventory_type IS '�ۊǏꏊ����';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.disable_date IS '������';
/
COMMENT ON COLUMN xxcoi_subinventory_info_v.material_account IS '���ڍޗ���CCID';
/
