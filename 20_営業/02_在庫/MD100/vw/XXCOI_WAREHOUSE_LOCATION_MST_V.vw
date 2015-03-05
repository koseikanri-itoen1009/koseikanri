/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_WAREHOUSE_LOCATION_MST_V
 * Description     : �q�Ƀ��P�[�V�����}�X�^�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/12/04    1.0   SCSK Koh        �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_warehouse_location_mst_v
  (  warehouse_location_id              -- �q�Ƀ��P�[�V�����}�X�^ID
    ,organization_id                    -- �݌ɑg�DID
    ,base_code                          -- ���_�R�[�h
    ,subinventory_code                  -- �ۊǏꏊ�R�[�h
    ,location_type                      -- ���P�[�V�����^�C�v
    ,location_type_name                 -- ���P�[�V�����^�C�v����
    ,location_code                      -- ���P�[�V�����R�[�h
    ,location_name                      -- ���P�[�V��������
  )
AS
  SELECT   xmwl1.warehouse_location_id  -- �q�Ƀ��P�[�V�����}�X�^ID
          ,xmwl1.organization_id
          ,xmwl1.base_code
          ,xmwl1.subinventory_code
          ,xmwl1.location_type
          ,xmwl1.location_type_name
          ,xmwl1.location_code
          ,xmwl1.location_name
  FROM    xxcoi_mst_warehouse_location  xmwl1
  WHERE   warehouse_location_id   =
  (
  SELECT  MIN(warehouse_location_id)
  FROM    xxcoi_mst_warehouse_location  xmwl2
  WHERE   xmwl2.organization_id   = xmwl1.organization_id
  AND     xmwl2.base_code         = xmwl1.base_code
  AND     xmwl2.subinventory_code = xmwl1.subinventory_code
  AND     xmwl2.location_code     = xmwl1.location_code
  )
/
COMMENT ON TABLE xxcoi_warehouse_location_mst_v IS '�q�Ƀ��P�[�V�����}�X�^�Ǘ���ʗp�r���[';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.warehouse_location_id IS '�q�Ƀ��P�[�V�����}�X�^ID';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.base_code IS '���_�R�[�h';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.subinventory_code IS '�ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_type IS '���P�[�V�����^�C�v';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_type_name IS '���P�[�V�����^�C�v����';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_code IS '���P�[�V�����R�[�h';
/
COMMENT ON COLUMN xxcoi_warehouse_location_mst_v.location_name IS '���P�[�V��������';
/
