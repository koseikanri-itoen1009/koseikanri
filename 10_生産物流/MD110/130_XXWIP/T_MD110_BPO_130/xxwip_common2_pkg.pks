CREATE OR REPLACE PACKAGE xxwip_common2_pkg
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxwip_common2_pkg(SPEC)
 * Description            : ���Y�o�b�`�ꗗ��ʗp�֐�
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.1
 *
 * Program List
 * ---------------------- ---- ----- --------------------------------------------------
 *  Name                  Type  Ret   Description
 * ---------------------- ---- ----- --------------------------------------------------
 * save_batch              P         �o�b�`�Z�[�uAPI�ďo ��ʗp
 * create_batch            P         �o�b�`�쐬API�ďo ��ʗp
 * create_lot              P         ���b�g�̔ԁE���b�g�쐬API�ďo ��ʗp
 * insert_line_allocation  P         ���׊����ǉ�API�ďo ��ʗp
 * insert_material_line    P         ���Y�����ڍגǉ�API�ďo ��ʗp
 * delete_material_line    P         ���Y�����ڍ׍폜API�ďo ��ʗp
 * reschedule_batch        P         �o�b�`�ăX�P�W���[��
 * update_lot_dff          P         ���b�g�}�X�^�X�VAPI�ďo ��ʗp
 * update_line_allocation  P         ���׊����X�VAPI�ďo ��ʗp
 * delete_line_allocation  P         ���׊����폜API�ďo ��ʗp
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/08   1.0   T.Oikawa         �V�K�쐬
 *  2008/12/22   1.1   Oracle ��r ��� �{�ԏ�Q#743�Ή�(���b�g�ǉ��E�X�V�֐�)
 *****************************************************************************************/
AS
--
  PROCEDURE save_batch(
    it_batch_id                     IN  gme_batch_header.batch_id%TYPE
  , ov_retcode                      OUT VARCHAR2
  );
--
  PROCEDURE create_batch(
    it_plan_start_date              IN  gme_batch_header.plan_start_date          %TYPE
  , it_plan_cmplt_date              IN  gme_batch_header.plan_cmplt_date          %TYPE
  , it_recipe_validity_rule_id      IN  gme_batch_header.recipe_validity_rule_id  %TYPE     -- �Ó������[��ID
  , it_plant_code                   IN  gme_batch_header.plant_code               %TYPE
  , it_wip_whse_code                IN  gme_batch_header.wip_whse_code            %TYPE
  , in_batch_size                   IN  NUMBER
  , iv_batch_size_uom               IN  VARCHAR2
  , ot_batch_id                     OUT gme_batch_header.batch_id                 %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE create_lot(
    it_item_id                      IN         ic_item_mst_b.item_id%TYPE                   -- �i��ID
  , it_item_no                      IN         ic_item_mst_b.item_no%TYPE                   -- �i�ڃR�[�h
  , ot_lot_id                       OUT NOCOPY ic_lots_mst.lot_id   %TYPE                   -- ���b�gID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE insert_line_allocation(
    it_item_id                      IN         gme_inventory_txns_gtmp.item_id            %TYPE
  , it_whse_code                    IN         gme_inventory_txns_gtmp.whse_code          %TYPE
  , it_lot_id                       IN         gme_inventory_txns_gtmp.lot_id             %TYPE
  , it_location                     IN         gme_inventory_txns_gtmp.location           %TYPE
  , it_doc_id                       IN         gme_inventory_txns_gtmp.doc_id             %TYPE
  , it_trans_date                   IN         gme_inventory_txns_gtmp.trans_date         %TYPE
  , it_trans_qty                    IN         gme_inventory_txns_gtmp.trans_qty          %TYPE
  , it_completed_ind                IN         gme_inventory_txns_gtmp.completed_ind      %TYPE
  , it_material_detail_id           IN         gme_inventory_txns_gtmp.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE insert_material_line(
    it_batch_id                     IN         gme_material_details.batch_id           %TYPE  -- �o�b�`ID
  , it_item_id                      IN         gme_material_details.item_id            %TYPE  -- �i��ID
  , it_item_um                      IN         gme_material_details.item_um            %TYPE  -- �P��
  , it_slit                         IN         gme_material_details.attribute8         %TYPE  -- ������
  , it_attribute5                   IN         gme_material_details.attribute5         %TYPE  -- �ō��敪
  , it_attribute7                   IN         gme_material_details.attribute7         %TYPE  -- �˗�����
  , it_attribute13                  IN         gme_material_details.attribute13        %TYPE  -- �o�q�ɃR�[�h�P
  , it_attribute18                  IN         gme_material_details.attribute18        %TYPE  -- �o�q�ɃR�[�h�Q
  , it_attribute19                  IN         gme_material_details.attribute19        %TYPE  -- �o�q�ɃR�[�h�R
  , it_attribute20                  IN         gme_material_details.attribute20        %TYPE  -- �o�q�ɃR�[�h�S
  , it_attribute21                  IN         gme_material_details.attribute21        %TYPE  -- �o�q�ɃR�[�h�T
  , ot_material_detail_id           OUT        gme_material_details.material_detail_id %TYPE  -- ���Y�����ڍ�ID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                       -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                       -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE delete_material_line(
    it_batch_id                     IN         gme_material_details.item_id            %TYPE
  , it_material_detail_id           IN         gme_material_details.material_detail_id %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE reschedule_batch(
    it_batch_id                     IN         gme_batch_header.batch_id         %TYPE
  , it_plan_start_date              IN         gme_batch_header.plan_start_date  %TYPE
  , it_plan_cmplt_date              IN         gme_batch_header.plan_cmplt_date  %TYPE
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE update_lot_dff(
    it_item_id                      IN         ic_lots_mst.item_id     %TYPE              -- �i��ID
  , it_lot_id                       IN         ic_lots_mst.lot_id      %TYPE              -- ���b�gID
  , it_attribute2                   IN         ic_lots_mst.attribute2  %TYPE DEFAULT NULL -- �ŗL�L��
  , it_attribute13                  IN         ic_lots_mst.attribute13 %TYPE DEFAULT NULL -- �^�C�v
  , it_attribute14                  IN         ic_lots_mst.attribute14 %TYPE DEFAULT NULL -- �����N1
  , it_attribute15                  IN         ic_lots_mst.attribute15 %TYPE DEFAULT NULL -- �����N2
  , it_attribute16                  IN         ic_lots_mst.attribute16 %TYPE DEFAULT NULL -- �`�[�敪
  , it_attribute17                  IN         ic_lots_mst.attribute17 %TYPE DEFAULT NULL -- ���C��No
  , it_attribute18                  IN         ic_lots_mst.attribute18 %TYPE DEFAULT NULL -- �E�v
  , it_attribute23                  IN         ic_lots_mst.attribute23 %TYPE DEFAULT NULL -- ���b�g�X�e�[�^�X
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                   -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                   -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE update_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE             -- �o�b�`ID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE             -- �ۗ��݌�TrID
  , it_trans_qty                    IN         ic_tran_pnd.trans_qty      %TYPE             -- �w������
  , it_completed_ind                IN         ic_tran_pnd.completed_ind  %TYPE             -- �����t���O
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
  PROCEDURE delete_line_allocation(
    it_batch_id                     IN         gme_batch_header.batch_id  %TYPE             -- �o�b�`ID
  , it_trans_id                     IN         ic_tran_pnd.trans_id       %TYPE             -- �ۗ��݌�TrID
  , ov_errbuf                       OUT NOCOPY VARCHAR2                                     -- �G���[�E���b�Z�[�W
  , ov_retcode                      OUT NOCOPY VARCHAR2                                     -- ���^�[���E�R�[�h
  , ov_errmsg                       OUT NOCOPY VARCHAR2                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
--
END xxwip_common2_pkg;
/
