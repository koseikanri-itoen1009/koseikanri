/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_TRAN_CHILD_ITEM_V
 * Description     : �q�ɊǗ��V�X�e�����b�g����q�i�ڃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/04    1.0   Y.Umino          �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_lot_tran_child_item_v
  (  organization_id                                             -- �݌ɑg�DID
   , parent_item_id                                              -- �e�i��ID(DISC)
   , child_item_id                                               -- �q�i��ID(DISC)
   , child_item_no                                               -- �q�i�ڃR�[�h
   , child_item_short_name                                       -- �q�i�ږ���
  )
AS
  SELECT msib_c.organization_id      AS organization_id
       , msib_p.inventory_item_id    AS parent_item_id
       , msib_c.inventory_item_id    AS child_item_id
       , msib_c.segment1             AS child_item_no
       , ximb.item_short_name        AS child_item_short_name
  FROM mtl_system_items_b   msib_p
      ,ic_item_mst_b        iimb_p
      ,xxcmn_item_mst_b     ximb
      ,mtl_system_items_b   msib_c
      ,ic_item_mst_b        iimb_c
      ,xxcmm_system_items_b xsib
  WHERE xsib.item_status      IN ( '30' ,'40' ,'50' )
    AND iimb_c.item_id         = xsib.item_id
    AND msib_c.segment1        = iimb_c.item_no
    AND msib_c.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
    AND ximb.item_id           = iimb_c.item_id
    AND xxccp_common_pkg2.get_process_date
          BETWEEN ximb.start_date_active AND ximb.end_date_active
    AND iimb_p.item_id         = ximb.parent_item_id
    AND msib_p.segment1        = iimb_p.item_no
    AND msib_p.organization_id = xxcoi_common_pkg.get_organization_id(FND_PROFILE.VALUE('XXCOI1_ORGANIZATION_CODE'))
/
COMMENT ON TABLE xxcoi_lot_tran_child_item_v IS '�q�ɊǗ��V�X�e�����b�g����q�i�ڃr���[';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.parent_item_id IS '�e�i��ID(DISC)';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_id IS '�q�i��ID(DISC)';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_no IS '�q�i�ڃR�[�h';
/
COMMENT ON COLUMN xxcoi_lot_tran_child_item_v.child_item_short_name IS '�q�i�ږ���';
/
