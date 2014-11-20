CREATE OR REPLACE PACKAGE xxwip200001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip200001(SPEC)
 * Description            : ���Y�o�b�`���b�g�ڍ׉�ʃf�[�^�\�[�X�p�b�P�[�W(SPEC)
 * MD.050                 : T_MD050_BPO_200_���Y�o�b�`.doc
 * MD.070                 : T_MD070_BPO_20A_���Y�o�b�`�ꗗ���.doc
 * Version                : 1.5
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    �f�[�^�擾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/08/28   1.0   D.Nihei          �V�K�쐬
 *  2008/10/07   1.1   D.Nihei          ������Q#123�Ή��iPT 6-2_31�j
 *  2008/10/22   1.2   D.Nihei          ������Q#123�Ή��iPT 6-2_31�j(���b�g�X�e�[�^�XVIEW�ӏ��C��)
 *  2008/10/29   1.3   D.Nihei          ������Q#481�Ή��iORDER BY��ҏW) 
 *  2008/11/19   1.4   D.Nihei          ������Q#681�Ή��i�����ǉ�) 
 *  2008/12/02   1.5   D.Nihei          �{�ԏ�Q#251�Ή��i�����ǉ�) 
*****************************************************************************************/
--
  --#######################  �p�b�P�[�W�ϐ��錾�� START   #######################
--
  -- ���Y�o�b�`���b�g�ڍ׉�ʊ�b�\�ƂȂ郌�R�[�h��`
  TYPE rec_ilm_block IS RECORD(
    storehouse_id               xxcmn_item_locations_v.inventory_location_id%TYPE     -- �ۊǑq��ID
  , storehouse_code             xxcmn_item_locations_v.segment1%TYPE                  -- �ۊǑq�ɃR�[�h
  , storehouse_name             xxcmn_item_locations_v.short_name%TYPE                -- �ۊǑq�ɖ���
  , batch_id                    gme_batch_header.batch_id%TYPE                        -- �o�b�`ID
  , material_detail_id          gme_material_details.material_detail_id%TYPE          -- ���Y�����ڍ�ID
  , mtl_detail_addon_id         xxwip_material_detail.mtl_detail_addon_id%TYPE        -- ���Y�����ڍ׃A�h�I��ID
  , mov_lot_dtl_id              xxinv_mov_lot_details.mov_lot_dtl_id%TYPE             -- ���b�g�ڍ�ID
  , trans_id                    ic_tran_pnd.trans_id%TYPE                             -- �g�����U�N�V����ID
  , item_id                     xxcmn_item_mst_v.item_id%TYPE                         -- �i��ID
  , item_no                     xxcmn_item_mst_v.item_no%TYPE                         -- �i�ڃR�[�h
  , lot_id                      ic_lots_mst.lot_id%TYPE                               -- ���b�gID
  , lot_no                      ic_lots_mst.lot_no%TYPE                               -- ���b�gNo
  , lot_create_type             ic_lots_mst.attribute24%TYPE                          -- �쐬�敪
  , instructions_qty            xxwip_material_detail.instructions_qty%TYPE           -- �w������
  , instructions_qty_orig       xxwip_material_detail.instructions_qty%TYPE           -- ���w������
  , stock_qty                   NUMBER                                                -- �݌ɑ���
-- 2008/10/07 D.Nihei ADD START
  , inbound_qty                 NUMBER                                                -- ���ɗ\�萔
  , outbound_qty                NUMBER                                                -- �o�ɗ\�萔
-- 2008/10/07 D.Nihei ADD END
  , enabled_qty                 NUMBER                                                -- �\��
  , entity_inner                NUMBER                                                -- �݌ɓ���
  , unit_price                  NUMBER                                                -- �P��
  , orgn_code                   xxcmn_vendors_v.segment1%TYPE                         -- �����R�[�h
  , orgn_name                   xxcmn_vendors_v.vendor_short_name%TYPE                -- ����於��
  , stocking_form               xxcmn_lookup_values_v.meaning%TYPE                    -- �d���`��
  , tea_season_type             xxcmn_lookup_values_v.meaning%TYPE                    -- �����敪
  , period_of_year              ic_lots_mst.attribute11%TYPE                          -- �N�x
  , producing_area              xxcmn_lookup_values_v.meaning%TYPE                    -- �Y�n
  , package_type                xxcmn_lookup_values_v.meaning%TYPE                    -- �^�C�v
  , rank1                       ic_lots_mst.attribute14%TYPE                          -- R1
  , rank2                       ic_lots_mst.attribute15%TYPE                          -- R2
  , rank3                       ic_lots_mst.attribute19%TYPE                          -- R3
  , maker_date                  ic_lots_mst.attribute1%TYPE                           -- ������
  , use_by_date                 ic_lots_mst.attribute3%TYPE                           -- �ܖ�������
  , unique_sign                 ic_lots_mst.attribute2%TYPE                           -- �ŗL�L��
  , dely_date                   ic_lots_mst.attribute4%TYPE                           -- �[�����i����j
  , slip_type_name              xxcmn_lookup_values_v.meaning%TYPE                    -- �`�[�敪(����)
  , routing_no                  gmd_routings_vl.routing_no%TYPE                       -- ���C��No
  , routing_name                gmd_routings_vl.attribute1%TYPE                       -- ���C������
  , remarks_column              ic_lots_mst.attribute18%TYPE                          -- �E�v
  , record_type                 NUMBER                                                -- ���R�[�h�^�C�v
  , created_by                  ic_lots_mst.created_by%TYPE                           -- �쐬��(OPM���b�g�}�X�^)
  , creation_date               ic_lots_mst.creation_date%TYPE                        -- �쐬��(OPM���b�g�}�X�^)
  , last_updated_by             ic_lots_mst.last_updated_by%TYPE                      -- �X�V��(OPM���b�g�}�X�^)
  , last_update_date            ic_lots_mst.last_update_date%TYPE                     -- �X�V��(OPM���b�g�}�X�^)
  , last_update_login           ic_lots_mst.last_update_login%TYPE                    -- �ŏI���O�C��(OPM���b�g�}�X�^)
  , xmd_last_update_date        xxwip_material_detail.last_update_date%TYPE           -- �ŏI�X�V��(���Y�����ڍ׃A�h�I��)
  , whse_inside_outside_div     xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- ���O�q�ɋ敪
  );
--
  -- ���Y�o�b�`���b�g�ڍ׉�ʊ�b�\�ƂȂ�����t�����R�[�h
  TYPE tbl_ilm_block IS TABLE OF rec_ilm_block
  INDEX BY BINARY_INTEGER;
--
  --#######################  �p�b�P�[�W�ϐ��錾�� END   #######################
--
  --#######################  �p�b�P�[�W�v���V�[�W���錾�� START   #######################
--
  PROCEDURE blk_ilm_qry(
    ior_ilm_data           IN OUT NOCOPY tbl_ilm_block
  , in_material_detail_id  IN gme_material_details.material_detail_id%TYPE   -- ���Y�����ڍ�ID
  , id_material_date       IN DATE                                           -- �������ɗ\���
  );
--
  --#######################  �p�b�P�[�W�v���V�[�W���錾�� END   #######################
--
  --#######################  �p�b�P�[�W�t�@���N�V�����錾�� START   #######################
--
  --#######################  �p�b�P�[�W�t�@���N�V�����錾�� END   #######################
--
END xxwip200001;
/
