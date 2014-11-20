CREATE OR REPLACE PACKAGE xxinv540001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxinv540001(SPEC)
 * Description            : �݌ɏƉ��ʃf�[�^�\�[�X�p�b�P�[�W(SPEC)
 * MD.050                 : T_MD050_BPO_540_�݌ɏƉ�Issue1.0.doc
 * MD.070                 : T_MD070_BPO_54A_�݌ɏƉ���Draft1A.doc
 * Version                : 1.17
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    �f�[�^�擾
 *  get_parent_item_id      F   NUM   �e�i��ID�擾
 *  get_attribute5          F   VAR   ��\�q�Ɏ擾
 *  get_organization_id     F   NUM   �݌ɑg�DID�擾
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/16   1.0   Jun.Komatsu      �V�K�쐬
 *  2008/03/13   1.1   Jun.Komatsu      �ύX�v��#15�A#7�Ή�
 *  2008/04/18   1.3   Jun.Komatsu      �ύX�v��#43�A#51�Ή�
 *  2008/05/26   1.4   Kazuo.Kumamoto   �ύX�v��##119�Ή�
 *  2008/06/13   1.5   Yuko.Kawano      �����e�X�g�s��Ή�
 *  2008/06/25   1.6   S.Takemoto       �ύX�v��##93�Ή�
 *  2008/09/03   1.7   N.Yoshida        PT�Ή�(�N�[�Ȃ�)
 *  2008/09/24   1.8   T.Ohashi         PT 1-1_2 �w�E39,�ύX#139�Ή�
 *  2008/10/29   1.9   T.Ohashi         PT 1-1_2�đΉ�
 *  2008/11/19   1.10  T.Ohashi         �w�E681�Ή�
 *  2008/12/02   1.11  D.Nihei          �{�ԏ�Q#251�Ή��i�����ǉ��j
 *  2008/12/15   1.12  H.Itou           �{�ԏ�Q#645�Ή��iD4�AS4�擾���͗\����łȂ����ѓ�����Ƃ���B�j
 *  2008/12/19   1.13  H.Itou           �{�ԏ�Q#648�Ή��iI5�AI6�擾���ʂ͎��ѐ��ʁ|�O�񐔗ʁj
 *  2008/12/24   1.14  T.Ohashi         �{�ԏ�Q#836�Ή��i�����ǉ��j
 *  2009/01/20   1.15  N.Yoshida        �{�ԏ�Q#1056�Ή�
 *  2009/01/21   1.16  N.Yoshida        �{�ԏ�Q#1050�Ή�
 *  2009/02/02   1.17  Y.Yamamoto       �{�ԏ�Q#1084�Ή�
 *****************************************************************************************/
--
  --#######################  �p�b�P�[�W�ϐ��錾�� START   #######################
--
  -- �݌ɏƉ��ʊ�b�\�ƂȂ郌�R�[�h��`
  TYPE rec_ilm_block IS RECORD(
         rec_no                     NUMBER,
         xilv_segment1              xxcmn_item_locations_v.segment1%TYPE,
         xilv_description           xxcmn_item_locations_v.short_name%TYPE,
         xilv_inventory_location_id xxcmn_item_locations_v.inventory_location_id%TYPE,
         ximv_item_id               xxcmn_item_mst_v.item_id%TYPE,
         ximv_item_no               xxcmn_item_mst_v.item_no%TYPE,
         ximv_item_short_name       xxcmn_item_mst_v.item_short_name%TYPE,
         ilm_lot_no                 ic_lots_mst.lot_no%TYPE,
         ilm_lot_id                 ic_lots_mst.lot_id%TYPE,
         ilm_attribute1             DATE,
         ilm_attribute3             DATE,
         ilm_attribute2             ic_lots_mst.attribute2%TYPE,
         ilm_attribute4             DATE,
         ilm_attribute5             DATE,
         ilm_attribute6             NUMBER,
         ilm_attribute7             NUMBER,
         ilm_attribute8             ic_lots_mst.attribute8%TYPE,
         xvv_vendor_short_name      xxcmn_vendors_v.vendor_short_name%TYPE,
         ilm_attribute9             ic_lots_mst.attribute9%TYPE,
         xlvv_xl5_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute10            ic_lots_mst.attribute10%TYPE,
         xlvv_xl6_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute11            ic_lots_mst.attribute11%TYPE,
         ilm_attribute12            ic_lots_mst.attribute12%TYPE,
         xlvv_xl7_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute13            ic_lots_mst.attribute13%TYPE,
         xlvv_xl8_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute14            ic_lots_mst.attribute14%TYPE,
         ilm_attribute15            ic_lots_mst.attribute15%TYPE,
         ilm_attribute19            ic_lots_mst.attribute19%TYPE,
         ilm_attribute16            ic_lots_mst.attribute16%TYPE,
         xlvv_xl3_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ilm_attribute17            ic_lots_mst.attribute17%TYPE,
         grb_routing_desc           gmd_routings_b.routing_desc%TYPE,
         ilm_attribute18            ic_lots_mst.attribute18%TYPE,
         ilm_attribute23            ic_lots_mst.attribute23%TYPE,
         xqi_qt_inspect_req_no      xxwip_qt_inspection.qt_inspect_req_no%TYPE,
         xlvv_xqs_meaning           xxcmn_lookup_values_v.meaning%TYPE,
         ili_loct_onhand            ic_loct_inv.loct_onhand%TYPE,
         inv_stock_vol              NUMBER,
         subtractable               NUMBER,
         supply_stock_plan          NUMBER,
         take_stock_plan            NUMBER,
         ilm_created_by             ic_lots_mst.created_by%TYPE,
         ilm_creation_date          ic_lots_mst.creation_date%TYPE,
         ilm_last_updated_by        ic_lots_mst.last_updated_by%TYPE,
         ilm_last_update_date       ic_lots_mst.last_update_date%TYPE,
         ilm_last_update_login      ic_lots_mst.last_update_login%TYPE,
         xilv_frequent_whse         xxcmn_item_locations_v.frequent_whse%TYPE,
         ximv_num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE);
--
  -- �݌ɏƉ��ʊ�b�\�ƂȂ�����t�����R�[�h
  TYPE tbl_ilm_block IS TABLE OF rec_ilm_block
  INDEX BY BINARY_INTEGER;
--
  --#######################  �p�b�P�[�W�ϐ��錾�� END   #######################
--
  --#######################  �p�b�P�[�W�v���V�[�W���錾�� START   #######################
--
  PROCEDURE blk_ilm_qry(
              ior_ilm_data              IN OUT NOCOPY tbl_ilm_block,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,          --�i��ID
              iv_parent_div             IN VARCHAR2,                               --�e�R�[�h�敪
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
                                                                                   --�ۊǑq��ID
              iv_deleg_house            IN VARCHAR2,                               --��\�q�ɏƉ�
              iv_ext_warehouse          IN VARCHAR2,                               --�q�ɒ��o�t���O
              iv_item_div_code          IN xxcmn_item_categories_v.segment1%TYPE,  --�i�ڋ敪�R�[�h
              iv_prod_div_code          IN xxcmn_item_categories_v.segment1%TYPE,  --���i�敪�R�[�h
              iv_unit_div               IN VARCHAR2,                               --�P�ʋ敪
              iv_qt_status_code         IN xxwip_qt_inspection.qt_effect1%TYPE,    --�i�����茋��
              id_manu_date_from         IN DATE,                                   --�����N����From
              id_manu_date_to           IN DATE,                                   --�����N����To
              iv_prop_sign              IN ic_lots_mst.attribute2%TYPE,            --�ŗL�L��
              id_consume_from           IN DATE,                                   --�ܖ�����From
              id_consume_to             IN DATE,                                   --�ܖ�����To
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,                --���b�g��
              iv_register_code          IN xxcmn_item_locations_v.customer_stock_whse%TYPE,
                                                                                   --���`�R�[�h
              id_effective_date         IN DATE,                                   --�L�����t
              iv_ext_show               IN VARCHAR2);                              --�݌ɗL�����\��
--
  --#######################  �p�b�P�[�W�v���V�[�W���錾�� END   #######################
--
  --#######################  �p�b�P�[�W�t�@���N�V�����錾�� START   #######################
--
  FUNCTION  get_parent_item_id(
              in_parent_item_id         IN xxcmn_item_mst_v.item_id%TYPE)
              RETURN NUMBER;
--
  FUNCTION  get_attribute5(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN VARCHAR2;
--
  FUNCTION  get_organization_id(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE)
              RETURN NUMBER;
--
  --#######################  �p�b�P�[�W�t�@���N�V�����錾�� END   #######################
--
END xxinv540001;
/