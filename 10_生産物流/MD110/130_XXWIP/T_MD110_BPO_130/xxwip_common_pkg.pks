CREATE OR REPLACE PACKAGE xxwip_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip_common_pkg(SPEC)
 * Description            : ���ʊ֐�(XXWIP)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.9
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  update_duty_status     P          �Ɩ��X�e�[�^�X�X�V�֐�
 *  insert_material_line   P          �������גǉ��֐�
 *  update_material_line   P          �������׍X�V�֐�
 *  delete_material_line   P          �������׍폜�֐�
 *  get_batch_no           F   VAR    �o�b�`No�擾�֐�
 *  lot_execute            P          ���b�g�ǉ��E�X�V�֐�
 *  insert_line_allocation P          ���׊����ǉ��֐�
 *  update_line_allocation P          ���׊����X�V�֐�
 *  delete_line_allocation P          ���׊����폜�֐�
 *  update_lot_dff_api     P          ���b�g�}�X�^DFF�X�V(���Y�o�b�`�p)
 *  update_inv_price       P          �݌ɒP���X�V�֐�
 *  update_trust_price     P          �ϑ����H��X�V�֐�
 *  get_business_date      P          �c�Ɠ��擾
 *  make_qt_inspection     P          �i�������˗����쐬
 *  get_can_stock_qty      F          �莝�݌ɐ��ʎZ�oAPI(�������їp)
 *
 * Change Record
 * ------------ ----- ------------------ -----------------------------------------------
 *  Date         Ver.  Editor             Description
 * ------------ ----- ------------------ -----------------------------------------------
 *  2007/11/13   1.0   H.Itou             �V�K�쐬
 *  2008/05/28   1.1   Oracle ��r ���   �����e�X�g�s��Ή�(�ϑ����H��X�V�֐��C��)
 *  2008/06/02   1.2   Oracle ��r ���   �����ύX�v��#130(�ϑ����H��X�V�֐��C��)
 *  2008/06/12   1.3   Oracle ��r ���   �V�X�e���e�X�g�s��Ή�#78(�ϑ����H��X�V�֐��C��)
 *  2008/06/25   1.4   Oracle ��r ���   �V�X�e���e�X�g�s��Ή�#75
 *  2008/06/27   1.5   Oracle ��r ���   �����e�X�g�s��Ή�(�����ǉ��֐��C��)
 *  2008/07/02   1.6   Oracle �ɓ��ЂƂ�  �V�X�e���e�X�g�s��Ή�#343(�r���������擾�֐��C��)
 *  2008/07/10   1.7   Oracle ��r ���   �V�X�e���e�X�g�s��Ή�#315(�݌ɒP���擾�֐��C��)
 *  2008/07/14   1.8   Oracle �ɓ��ЂƂ�  �����s� �w�E2�Ή�  �i�������˗����쐬�ōX�V�̏ꍇ�A�����\����E���ʂ��X�V���Ȃ��B
 *  2008/08/25   1.9   Oracle �ɓ��ЂƂ�  �����ύX�v��#189�Ή�(�i�������˗����쐬�C��)�X�V�E�폜�Ō����˗�No��NULL�̏ꍇ�A�������s��Ȃ��B
 *****************************************************************************************/
--
  -- �X�e�[�^�X�X�V�֐�
  PROCEDURE update_duty_status(
    in_batch_id           IN  NUMBER,      -- 1.�X�V�Ώۂ̃o�b�`ID
    iv_duty_status        IN  VARCHAR2,    -- 2.�X�V�X�e�[�^�X
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �o�b�`No�擾�֐�
  FUNCTION get_batch_no(
    it_batch_id    gme_batch_header.batch_id%TYPE)      -- 1.�X�V�Ώۂ̃o�b�`ID
  RETURN NUMBER;
--
  -- �������גǉ��֐�
  PROCEDURE insert_material_line(
    ir_material_detail    IN  gme_material_details%ROWTYPE,
    or_material_detail    OUT NOCOPY gme_material_details%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �������׍X�V�֐�
  PROCEDURE update_material_line(
    ir_material_detail    IN  gme_material_details%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �������׍폜�֐�
  PROCEDURE delete_material_line(
    in_batch_id           IN  NUMBER,     -- ���Y�o�b�`ID
    in_mtl_dtl_id         IN  NUMBER,     -- ���Y�����ڍ�ID
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  -- ���b�g�ǉ��E�X�V�֐�
  PROCEDURE lot_execute(
    ir_lot_mst            IN  ic_lots_mst%ROWTYPE,                 -- OPM���b�g�}�X�^
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,          -- �i�ڃR�[�h
    it_line_type          IN  gme_material_details.line_type%TYPE, -- ���C���^�C�v
    it_item_class_code    IN  mtl_categories_b.segment1%TYPE,      -- �i�ڋ敪
    it_lot_no_prod        IN  ic_lots_mst.lot_no%TYPE,             -- �����i�̃��b�gNo
    or_lot_mst            OUT NOCOPY ic_lots_mst%ROWTYPE,          -- OPM���b�g�}�X�^
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- ���׊����ǉ��֐�
  PROCEDURE insert_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- ���׊����X�V�֐�
  PROCEDURE update_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- ���׊����폜�֐�
  PROCEDURE delete_line_allocation(
    ir_tran_row_in        IN  gme_inventory_txns_gtmp%ROWTYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �݌ɒP���X�V�֐�
  PROCEDURE update_inv_price(
    it_batch_id           IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  -- �ϑ����H��X�V�֐�
  PROCEDURE update_trust_price(
    it_batch_id           IN  gme_batch_header.batch_id%TYPE,
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �c�Ɠ��擾
  PROCEDURE get_business_date(
    id_date               IN  DATE,        -- IN  1.���t
    in_period             IN  NUMBER,      -- IN  2.����
    od_business_date      OUT NOCOPY DATE,        -- OUT 1.���t�́����c�Ɠ���̓��t
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �i�������˗����쐬
  PROCEDURE make_qt_inspection(
    it_division          IN  xxwip_qt_inspection.division%TYPE,         -- IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
    iv_disposal_div      IN  VARCHAR2,                                  -- IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
    it_lot_id            IN  xxwip_qt_inspection.lot_id%TYPE,           -- IN  3.���b�gID     �K�{
    it_item_id           IN  xxwip_qt_inspection.item_id%TYPE,          -- IN  4.�i��ID       �K�{
    iv_qt_object         IN  VARCHAR2,                                  -- IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
    it_batch_id          IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  6.���Y�o�b�`ID �����敪3�ȊO���敪:1�̂ݕK�{
    it_batch_po_id       IN  xxwip_qt_inspection.batch_po_id%TYPE,      -- IN  7.���הԍ�     �����敪3�ȊO���敪:2�̂ݕK�{
    it_qty               IN  xxwip_qt_inspection.qty%TYPE,              -- IN  8.����         �����敪3�ȊO���敪:2�̂ݕK�{
    it_prod_dely_date    IN  xxwip_qt_inspection.prod_dely_date%TYPE,   -- IN  9.�[����       �����敪3�ȊO���敪:2�̂ݕK�{
    it_vendor_line       IN  xxwip_qt_inspection.vendor_line%TYPE,      -- IN 10.�d����R�[�h �����敪3�ȊO���敪:2�̂ݕK�{
    it_qt_inspect_req_no IN  xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{
    ot_qt_inspect_req_no OUT NOCOPY xxwip_qt_inspection.qt_inspect_req_no%TYPE,-- OUT 1.�����˗�No
    ov_errbuf            OUT NOCOPY VARCHAR2,                                  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,                                  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2                                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �莝�݌ɐ��ʎZ�oAPI(�������їp)
  FUNCTION get_can_stock_qty(
    in_batch_id         IN NUMBER,                    -- �o�b�`ID
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
  RETURN NUMBER;
--
  -- �������t�X�V�֐�
  PROCEDURE change_trans_date_all(
    in_batch_id           IN  NUMBER,             -- ���Y�o�b�`ID
    ov_errbuf             OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
END xxwip_common_pkg;
/
