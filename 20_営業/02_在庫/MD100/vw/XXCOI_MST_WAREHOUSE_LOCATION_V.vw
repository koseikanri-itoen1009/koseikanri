/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_MST_WAREHOUSE_LOCATION_V
 * Description     : �q�Ƀ��P�[�V�����}�X�^�Ǘ���ʗp�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/12/01    1.0   R.Oikawa           �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_MST_WAREHOUSE_LOCATION_V
  (  warehouse_location_id                                            -- �q�Ƀ��P�[�V�����}�X�^ID
    ,organization_id                                                  -- �݌ɑg�DID
    ,base_code                                                        -- ���_�R�[�h
    ,subinventory_code                                                -- �ۊǏꏊ�R�[�h
    ,location_code                                                    -- ���P�[�V�����R�[�h
    ,location_name                                                    -- ���P�[�V��������
    ,location_type                                                    -- ���P�[�V�����^�C�v
    ,location_type_name                                               -- ���P�[�V�����^�C�v����
    ,priority                                                         -- �D�揇��
    ,disable_date                                                     -- ������
    ,parent_item_id                                                   -- �e�i��ID
    ,parent_item_code                                                 -- �e�i�ڃR�[�h
    ,parent_item_name                                                 -- �e�i�ږ���
    ,item_id                                                          -- �q�i��ID
    ,item_code                                                        -- �q�i�ڃR�[�h
    ,item_name                                                        -- �q�i�ږ���
    ,attribute1                                                       -- DFF1
    ,created_by                                                       -- �쐬��
    ,creation_date                                                    -- �쐬��
    ,last_updated_by                                                  -- �ŏI�X�V��
    ,last_update_date                                                 -- �ŏI�X�V��
    ,last_update_login                                                -- �ŏI�X�V���O�C��
  )
AS
  SELECT   xmwl.warehouse_location_id                                 -- �q�Ƀ��P�[�V�����}�X�^ID
         , xmwl.organization_id                                       -- �݌ɑg�DID
         , xmwl.base_code                                             -- ���_�R�[�h
         , xmwl.subinventory_code                                     -- �ۊǏꏊ�R�[�h
         , xmwl.location_code                                         -- ���P�[�V�����R�[�h
         , xmwl.location_name                                         -- ���P�[�V��������
         , xmwl.location_type                                         -- ���P�[�V�����^�C�v
         , xmwl.location_type_name                                    -- ���P�[�V�����^�C�v����
         , xmwl.priority                                              -- �D�揇��
         , xmwl.disable_date                                          -- ������
         , msib_p.inventory_item_id                                   -- �e�i��ID
         , msib_p.segment1                                            -- �e�i�ڃR�[�h
         , ximb_p.item_short_name                                     -- �e�i�ږ���
         , xmwl.child_item_id                                         -- �q�i��ID
         , msib_c.segment1                                            -- �q�i�ڃR�[�h
         , ximb_c.item_short_name                                     -- �q�i�ږ���
         , flv.attribute1                                             -- DFF1
         , xmwl.created_by                                            -- �쐬��
         , xmwl.creation_date                                         -- �쐬��
         , xmwl.last_updated_by                                       -- �ŏI�X�V��
         , xmwl.last_update_date                                      -- �ŏI�X�V��
         , xmwl.last_update_login                                     -- �ŏI�X�V���O�C��
  FROM     xxcoi_mst_warehouse_location    xmwl
         , ic_item_mst_b                   iimb_p
         , xxcmn_item_mst_b                ximb_p
         , ic_item_mst_b                   iimb_c
         , xxcmn_item_mst_b                ximb_c
         , mtl_system_items_b              msib_p
         , mtl_system_items_b              msib_c
         , fnd_lookup_values               flv
  WHERE    xmwl.organization_id      = msib_c.organization_id
  AND      xmwl.child_item_id        = msib_c.inventory_item_id
  AND      msib_c.segment1           = iimb_c.item_no
  AND      iimb_c.item_id            = ximb_c.item_id
  AND      xxccp_common_pkg2.get_process_date BETWEEN ximb_c.start_date_active
    AND ximb_c.end_date_active
  AND      ximb_c.parent_item_id     = ximb_p.item_id
  AND      xxccp_common_pkg2.get_process_date BETWEEN ximb_p.start_date_active
    AND ximb_p.end_date_active
  AND      ximb_p.item_id            = iimb_p.item_id
  AND      iimb_p.item_no            = msib_p.segment1
  AND      xmwl.organization_id      = msib_p.organization_id
  AND      flv.lookup_type           = 'XXCOI1_LOCATION_TYPE_NAME'
  AND      flv.lookup_code           = '1'
  AND      flv.enabled_flag          = 'Y'
  AND      xxccp_common_pkg2.get_process_date BETWEEN flv.start_date_active
    AND NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date)
  AND      flv.language              = USERENV('LANG')
  AND      xmwl.location_type        = flv.lookup_code
UNION ALL
  SELECT   xmwl.warehouse_location_id                                 -- �q�Ƀ��P�[�V�����}�X�^ID
         , xmwl.organization_id                                       -- �݌ɑg�DID
         , xmwl.base_code                                             -- ���_�R�[�h
         , xmwl.subinventory_code                                     -- �ۊǏꏊ�R�[�h
         , xmwl.location_code                                         -- ���P�[�V�����R�[�h
         , xmwl.location_name                                         -- ���P�[�V��������
         , xmwl.location_type                                         -- ���P�[�V�����^�C�v
         , xmwl.location_type_name                                    -- ���P�[�V�����^�C�v����
         , xmwl.priority                                              -- �D�揇��
         , xmwl.disable_date                                          -- ������
         , NULL                                                       -- �e�i��ID
         , NULL                                                       -- �e�i�ڃR�[�h
         , NULL                                                       -- �e�i�ږ���
         , NULL                                                       -- �q�i��ID
         , NULL                                                       -- �q�i�ڃR�[�h
         , NULL                                                       -- �q�i�ږ���
         , flv.attribute1                                             -- DFF1
         , xmwl.created_by                                            -- �쐬��
         , xmwl.creation_date                                         -- �쐬��
         , xmwl.last_updated_by                                       -- �ŏI�X�V��
         , xmwl.last_update_date                                      -- �ŏI�X�V��
         , xmwl.last_update_login                                     -- �ŏI�X�V���O�C��
  FROM     xxcoi_mst_warehouse_location    xmwl
         , fnd_lookup_values               flv
  WHERE    flv.lookup_type           = 'XXCOI1_LOCATION_TYPE_NAME'
  AND      flv.lookup_code           <> '1'
  AND      flv.enabled_flag          = 'Y'
  AND      xxccp_common_pkg2.get_process_date BETWEEN flv.start_date_active
    AND NVL(flv.end_date_active, xxccp_common_pkg2.get_process_date)
  AND      flv.language              = USERENV('LANG')
  AND      xmwl.location_type        = flv.lookup_code
/
COMMENT ON TABLE xxcoi_mst_warehouse_location_v IS '�q�Ƀ��P�[�V�����}�X�^�Ǘ���ʗp�r���[';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.warehouse_location_id IS '�q�Ƀ��P�[�V�����}�X�^ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.base_code IS '���_�R�[�h';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.subinventory_code IS '�ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_code IS '���P�[�V�����R�[�h';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_name IS '���P�[�V��������';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_type IS '���P�[�V�����^�C�v';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.location_type_name IS '���P�[�V�����^�C�v����';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.priority IS '�D�揇��';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.disable_date IS '������';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_id IS '�e�i��ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_code IS '�e�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.parent_item_name IS '�e�i�ږ���';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_id IS '�q�i��ID';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_code IS '�q�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.item_name IS '�q�i�ږ���';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.attribute1 IS 'DFF1';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_update_date IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_mst_warehouse_location_v.last_update_login IS '�ŏI�X�V���O�C��';
/
