/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_ONHAND_QUANTITES_V
 * Description     : ���P�[�V�����ړ����͉�ʗp�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/10/17    1.0   S.Itou           �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_LOT_ONHAND_QUANTITES_V
  (  organization_id                                                  -- �݌ɑg�DID
    ,base_code                                                        -- ���_�R�[�h
    ,subinventory_code                                                -- �ۊǏꏊ�R�[�h
    ,location_code                                                    -- ���P�[�V�����R�[�h
    ,location_name                                                    -- ���P�[�V��������
    ,parent_item_id                                                   -- �e�i��ID
    ,parent_item_code                                                 -- �e�i�ڃR�[�h
    ,parent_item_name                                                 -- �e�i�ږ���
    ,item_id                                                          -- �q�i��ID
    ,item_code                                                        -- �q�i�ڃR�[�h
    ,item_name                                                        -- �q�i�ږ���
    ,lot                                                              -- ���b�g
    ,difference_summary_code                                          -- �ŗL�L��
    ,case_in_qty                                                      -- ����
    ,case_qty                                                         -- �P�[�X��
    ,singly_qty                                                       -- �o����
    ,summary_qty                                                      -- �������
    ,created_by                                                       -- �쐬��
    ,creation_date                                                    -- �쐬��
    ,last_updated_by                                                  -- �ŏI�X�V��
    ,last_update_date                                                 -- �ŏI�X�V��
  )
AS
  SELECT   xloq.organization_id                                       -- �݌ɑg�DID
         , xloq.base_code                                             -- ���_�R�[�h
         , xloq.subinventory_code                                     -- �ۊǏꏊ�R�[�h
         , xloq.location_code                                         -- ���P�[�V�����R�[�h
         , xmwl.location_name                                         -- ���P�[�V��������
         , msib_p.inventory_item_id                                   -- �e�i��ID
         , msib_p.segment1                                            -- �e�i�ڃR�[�h
         , ximb_p.item_short_name                                     -- �e�i�ږ���
         , xloq.child_item_id                                         -- �q�i��ID
         , msib_c.segment1                                            -- �q�i�ڃR�[�h
         , ximb_c.item_short_name                                     -- �q�i�ږ���
         , xloq.lot                                                   -- ���b�g
         , xloq.difference_summary_code                               -- �ŗL�L��
         , xloq.case_in_qty                                           -- ����
         , xloq.case_qty                                              -- �P�[�X��
         , xloq.singly_qty                                            -- �o����
         , xloq.summary_qty                                           -- �������
         , xloq.created_by                                            -- �쐬��
         , xloq.creation_date                                         -- �쐬��
         , xloq.last_updated_by                                       -- �ŏI�X�V��
         , xloq.last_update_date                                      -- �ŏI�X�V��
  FROM     ic_item_mst_b                   iimb_p
         , xxcmn_item_mst_b                ximb_p
         , ic_item_mst_b                   iimb_c
         , xxcmn_item_mst_b                ximb_c
         , xxcoi_warehouse_location_mst_v  xmwl
         , mtl_system_items_b              msib_p
         , mtl_system_items_b              msib_c
         , xxcoi_lot_onhand_quantites      xloq
  WHERE    xmwl.organization_id      = xloq.organization_id
  AND      xmwl.base_code            = xloq.base_code
  AND      xmwl.subinventory_code    = xloq.subinventory_code
  AND      xmwl.location_code        = xloq.location_code
  AND      msib_c.inventory_item_id  = xloq.child_item_id
  AND      msib_c.organization_id    = xloq.organization_id
  AND      iimb_c.item_no            = msib_c.segment1
  AND      ximb_c.item_id            = iimb_c.item_id
  AND      ximb_c.start_date_active <= xxccp_common_pkg2.get_process_date
  AND      ximb_c.end_date_active   >= xxccp_common_pkg2.get_process_date
  AND      ximb_p.item_id            = ximb_c.parent_item_id
  AND      ximb_p.start_date_active <= xxccp_common_pkg2.get_process_date
  AND      ximb_p.end_date_active   >= xxccp_common_pkg2.get_process_date
  AND      iimb_p.item_id            = ximb_c.parent_item_id
  AND      msib_p.segment1           = iimb_p.item_no
  AND      msib_p.organization_id    = xloq.organization_id
/
COMMENT ON TABLE xxcoi_lot_onhand_quantites_v IS '���P�[�V�����ړ����͉�ʗp�r���[';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.base_code IS '���_�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.subinventory_code IS '�ۊǏꏊ�R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.location_code IS '���P�[�V�����R�[�h';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.location_name IS '���P�[�V��������';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_id IS '�e�i��ID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_code IS '�e�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.parent_item_name IS '�e�i�ږ���';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_id IS '�q�i��ID';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_code IS '�q�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.item_name IS '�q�i�ږ���';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.lot IS '���b�g';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.difference_summary_code IS '�ŗL�L��';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.case_in_qty IS '����';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.case_qty IS '�P�[�X��';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.singly_qty IS '�o����';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.summary_qty IS '�������';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_lot_onhand_quantites_v.last_update_date IS '�ŏI�X�V��';
/
