/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_INV_ADJ_INFO_V
 * Description     : �݌ɒ�������ʃr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/27    1.0   Y.Nagasue        �V�K�쐬
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW xxcoi_inv_adj_info_v(
   organization_id                                                                       -- �݌ɑg�DID
  ,base_code                                                                             -- ���_�R�[�h
  ,subinventory_code                                                                     -- �ۊǏꏊ�R�[�h
  ,location_code                                                                         -- ���P�[�V����
  ,location_name                                                                         -- ���P�[�V������
  ,parent_item_id                                                                        -- �e�i��ID
  ,parent_item_code                                                                      -- �e�i��
  ,parent_item_name                                                                      -- �e�i�ږ�
  ,child_item_id                                                                         -- �q�i��ID
  ,child_item_code                                                                       -- �q�i��
  ,child_item_name                                                                       -- �q�i�ږ�
  ,lot                                                                                   -- ���b�g(�ܖ�����)
  ,difference_summary_code                                                               -- �ŗL�L��
  ,case_in_qty                                                                           -- ����
  ,case_qty                                                                              -- �P�[�X��
  ,singly_qty                                                                            -- �o����
  ,adj_qty                                                                               -- ��������
  ,production_date                                                                       -- ������
  ,created_by                                                                            -- �쐬��
  ,creation_date                                                                         -- �쐬��
  ,last_updated_by                                                                       -- �ŏI�X�V��
  ,last_update_date                                                                      -- �ŏI�X�V��
  ,last_update_login                                                                     -- �ŏI�X�V���O�C��
 )AS
   SELECT /*+ INDEX(xloq xxcoi_lot_onhand_quantites_n01) */
          xloq.organization_id                                   organization_id         -- �݌ɑg�DID
         ,xloq.base_code                                         base_code               -- ���_�R�[�h
         ,xloq.subinventory_code                                 subinventory_code       -- �ۊǏꏊ
         ,xloq.location_code                                     location_code           -- ���P�[�V����
         ,xwlmv.location_name                                    location_name           -- ���P�[�V������
         ,msib_oya.inventory_item_id                             parent_item_id          -- �e�i��ID
         ,msib_oya.segment1                                      parent_item_code        -- �e�i��
         ,ximb_oya.item_short_name                               parent_item_name        -- �e�i�ږ�
         ,msib_ko.inventory_item_id                              child_item_id           -- �q�i��ID
         ,msib_ko.segment1                                       child_item_code         -- �q�i��
         ,ximb_ko.item_short_name                                child_item_name         -- �q�i�ږ�
         ,xloq.lot                                               lot                     -- ���b�g(�ܖ�����)
         ,xloq.difference_summary_code                           difference_summary_code -- �ŗL�L��
         ,xloq.case_in_qty                                       case_in_qty             -- ����
         ,xloq.case_qty                                          case_qty                -- �P�[�X��
         ,xloq.singly_qty                                        singly_qty              -- �o����
         ,( xloq.case_in_qty * xloq.case_qty ) + xloq.singly_qty adj_qty                 -- ��������
         ,xloq.production_date                                   production_date         -- ������
         ,xloq.created_by                                        created_by              -- �쐬��
         ,xloq.creation_date                                     creation_date           -- �쐬��
         ,xloq.last_updated_by                                   last_updated_by         -- �ŏI�X�V��
         ,xloq.last_update_date                                  last_update_date        -- �ŏI�X�V��
         ,xloq.last_update_login                                 last_update_login       -- �ŏI�X�V���O�C��
   FROM   xxcoi_lot_onhand_quantites     xloq
         ,xxcoi_warehouse_location_mst_v xwlmv
         ,mtl_system_items_b             msib_oya
         ,mtl_system_items_b             msib_ko
         ,ic_item_mst_b                  iimb_oya
         ,ic_item_mst_b                  iimb_ko
         ,xxcmn_item_mst_b               ximb_oya
         ,xxcmn_item_mst_b               ximb_ko
   WHERE  xloq.organization_id   = xwlmv.organization_id
   AND    xloq.base_code         = xwlmv.base_code
   AND    xloq.subinventory_code = xwlmv.subinventory_code
   AND    xloq.location_code     = xwlmv.location_code
   AND    xloq.organization_id   = msib_ko.organization_id
   AND    xloq.child_item_id     = msib_ko.inventory_item_id
   AND    msib_ko.segment1       = iimb_ko.item_no
   AND    iimb_ko.item_id        = ximb_ko.item_id
   AND    xxccp_common_pkg2.get_process_date 
            BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active
   AND    ximb_ko.parent_item_id = ximb_oya.item_id
   AND    xxccp_common_pkg2.get_process_date
            BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
   AND    ximb_oya.item_id       = iimb_oya.item_id
   AND    iimb_oya.item_no       = msib_oya.segment1
   AND    xloq.organization_id   = msib_oya.organization_id
/
COMMENT ON TABLE xxcoi_inv_adj_info_v IS '�݌ɒ�������ʃr���[';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.organization_id IS '�݌ɑg�DID';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.base_code IS '���_�R�[�h';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.subinventory_code IS '�ۊǏꏊ';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.location_code IS '���P�[�V����';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.location_name IS '���P�[�V������';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.parent_item_id IS '�e�i��ID';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.parent_item_code IS '�e�i��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.parent_item_name IS '�e�i�ږ�';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.child_item_id IS '�q�i��ID';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.child_item_code IS '�q�i��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.child_item_name IS '�q�i�ږ�';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.lot IS '���b�g(�ܖ�����)';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.difference_summary_code IS '�ŗL�L��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.case_in_qty IS '����';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.case_qty IS '�P�[�X��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.singly_qty IS '�o����';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.adj_qty IS '��������';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.production_date IS '������';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.created_by IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.creation_date IS '�쐬��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.last_updated_by IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.last_update_date IS '�ŏI�X�V��';
/
COMMENT ON COLUMN xxcoi_inv_adj_info_v.last_update_login IS '�ŏI�X�V���O�C��';
/
