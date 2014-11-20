CREATE OR REPLACE PACKAGE BODY xxcmn_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common2_pkg(BODY)
 * Description            : ���ʊ֐�2(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_�����\���Z�o�i�⑫�����j.doc
 * Version                : 1.8
 *
 * Program List
 *  ---------------------------- ---- ----- --------------------------------------------------
 *   Name                        Type  Ret   Description
 *  ---------------------------- ---- ----- --------------------------------------------------
 *  get_inv_onhand_lot            p   �Ȃ�  ���b�g    I0  EBS�莝�݌�
 *  get_inv_lot_in_inout_rpt_qty  p   �Ȃ�  ���b�g    I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
 *  get_inv_lot_in_in_rpt_qty     p   �Ȃ�  ���b�g    I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
 *  get_inv_lot_out_inout_rpt_qty p   �Ȃ�  ���b�g    I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
 *  get_inv_lot_out_out_rpt_qty   p   �Ȃ�  ���b�g    I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
 *  get_inv_lot_ship_qty          p   �Ȃ�  ���b�g    I5  ���і���݌ɐ�  �o��
 *  get_inv_lot_provide_qty       p   �Ȃ�  ���b�g    I6  ���і���݌ɐ�  �x��
 *  get_sup_lot_inv_in_qty        p   �Ȃ�  ���b�g    S1  ������  �ړ����ɗ\��
 *  get_sup_lot_order_qty         p   �Ȃ�  ���b�g    S2  ������  ��������\��
 *  get_sup_lot_produce_qty       p   �Ȃ�  ���b�g    S3  ������  ���Y���ɗ\��
 *  get_sup_lot_inv_out_qty       p   �Ȃ�  ���b�g    S4  ������  ���ьv��ς̈ړ��o�Ɏ���
 *  get_dem_lot_ship_qty          p   �Ȃ�  ���b�g    D1  ���v��  ���і��v��̏o�׈˗��iID�x�[�X�j
 *  get_dem_lot_ship_qty2         p   �Ȃ�  ���b�g    D1  ���v��  ���і��v��̏o�׈˗��iCODE�x�[�X�j
 *  get_dem_lot_provide_qty       p   �Ȃ�  ���b�g    D2  ���v��  ���і��v��̎x���w���iID�x�[�X�j
 *  get_dem_lot_provide_qty2      p   �Ȃ�  ���b�g    D2  ���v��  ���і��v��̎x���w���iCODE�x�[�X�j
 *  get_dem_lot_inv_out_qty       p   �Ȃ�  ���b�g    D3  ���v��  ���і��v��̈ړ��w��
 *  get_dem_lot_inv_in_qty        p   �Ȃ�  ���b�g    D4  ���v��  ���ьv��ς̈ړ����Ɏ���
 *  get_dem_lot_produce_qty       p   �Ȃ�  ���b�g    D5  ���v��  ���і��v��̐��Y�����\��
 *  get_dem_lot_order_qty         p   �Ȃ�  ���b�g    D6  ���v��  ���і��v��̑����q�ɔ������ɗ\��
 *  get_inv_onhand                p   �Ȃ�  �񃍃b�g  I0  EBS�莝�݌�
 *  get_inv_in_inout_rpt_qty      p   �Ȃ�  �񃍃b�g  I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
 *  get_inv_in_in_rpt_qty         p   �Ȃ�  �񃍃b�g  I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
 *  get_inv_out_inout_rpt_qty     p   �Ȃ�  �񃍃b�g  I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
 *  get_inv_out_out_rpt_qty       p   �Ȃ�  �񃍃b�g  I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
 *  get_inv_ship_qty              p   �Ȃ�  �񃍃b�g  I5  ���і���݌ɐ�  �o��
 *  get_inv_provide_qty           p   �Ȃ�  �񃍃b�g  I6  ���і���݌ɐ�  �x��
 *  get_sup_inv_in_qty            p   �Ȃ�  �񃍃b�g  S1  ������  �ړ����ɗ\��
 *  get_sup_order_qty             p   �Ȃ�  �񃍃b�g  S2  ������  ��������\��
 *  get_sup_inv_out_qty           p   �Ȃ�  �񃍃b�g  S4  ������  ���ьv��ς̈ړ��o�Ɏ���
 *  get_dem_ship_qty              p   �Ȃ�  �񃍃b�g  D1  ���v��  ���і��v��̏o�׈˗�
 *  get_dem_provide_qty           p   �Ȃ�  �񃍃b�g  D2  ���v��  ���і��v��̎x���w��
 *  get_dem_inv_out_qty           p   �Ȃ�  �񃍃b�g  D3  ���v��  ���і��v��̈ړ��w��
 *  get_dem_inv_in_qty            p   �Ȃ�  �񃍃b�g  D4  ���v��  ���ьv��ς̈ړ����Ɏ���
 *  get_dem_produce_qty           p   �Ȃ�  �񃍃b�g  D5  ���v��  ���і��v��̐��Y�����\��
 *  get_can_enc_total_qty         F   NUM   �������\���Z�oAPI(�p�~�F�L�����x�[�X�����\���Z�oAPI�ő�p)
 *  get_can_enc_in_time_qty       F   NUM   �L�����x�[�X�����\���Z�oAPI
 *  get_stock_qty                 F   NUM   �莝�݌ɐ��ʎZ�oAPI
 *  get_can_enc_qty               F   NUM   �����\���Z�oAPI
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2007/12/26   1.0   oracle �ۉ�     �V�K�쐬
 *
 *  2008/02/04   ���o���̃e�[�u���́A�r���[���g�p���Ȃ����Ƃ���B
 *  2008/04/03   1.1   oracle �ۉ�     �����ύX�v��#32 get_stock_qty�C��
 *  2008/05/22   1.2   oracle �Ŗ�     �����ύX�v��#98�Ή�
 *  2008/06/19   1.3   oracle �g�c     �����e�X�g�s��Ή�(D6 �����ݒ�̕ϐ�(�i�ڃR�[�h)�ύX)
 *  2008/06/24   1.4   oracle �|�{     �����e�X�g�s��Ή�(I5,I6 �����ݒ�̕ϐ�(�i�ڃR�[�h)�ύX)
 *  2008/06/24   1.4   oracle �V��     �V�X�e���e�X�g�s��Ή�#75(D5)
 *  2008/07/16   1.5   oracle �k����   �ύX�v��#93�Ή�
 *  2008/07/25   1.6   oracle �k����   �����e�X�g�s��Ή�
 *  2008/09/09   1.7   oracle �Ŗ�     PT 6-1_28 �w�E44 �Ή�
 *  2008/09/09   1.8   oracle �Ŗ�     PT 6-1_28 �w�E44 �C��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcmn_common2_pkg'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : get_inv_onhand_lot
   * Description      : ���b�g I0)EBS�莝�݌Ɏ擾�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE get_inv_onhand_lot(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_whse_id     OUT NOCOPY NUMBER,       -- �ۊǑq��ID
    on_item_id     OUT NOCOPY NUMBER,       -- �i��ID
    on_lot_id      OUT NOCOPY NUMBER,       -- ���b�gID
    on_onhand      OUT NOCOPY NUMBER,       -- �莝����
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- �ۊǑq�ɃR�[�h
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- ��\�q��
    ov_item_code   OUT NOCOPY VARCHAR2,     -- �i�ڃR�[�h
    ov_lot_no      OUT NOCOPY VARCHAR2,     -- ���b�gNO
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_onhand_lot'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT mst_data.whse_code,
           mst_data.rep_wheh,
           mst_data.wheh_code,
           mst_data.item_id,
           mst_data.item_no,
           mst_data.lot_no,
           mst_data.lot_id,
           NVL(ili.loct_onhand,0)
    INTO ov_whse_code,
         ov_rep_whse,
         on_whse_id,
         on_item_id,
         ov_item_code,
         ov_lot_no,
         on_lot_id,
         on_onhand
    FROM
    (
      SELECT  mil.segment1                AS whse_code,
              mil.attribute5              AS rep_wheh,
              mil.inventory_location_id   AS wheh_code,
              iimb.item_id                AS item_id,
              iimb.item_no                AS item_no,
              ilm.lot_id                  AS lot_id,
              ilm.lot_no                  AS lot_no
      FROM  ic_item_mst_b       iimb,   -- OPM�i�ڃ}�X�^
            ic_lots_mst         ilm,    -- OPM���b�g�}�X�^
            mtl_item_locations  mil,    -- �ۊǏꏊ
            ic_whse_mst         iwm     -- �q��
      WHERE iimb.item_id              = in_item_id
      AND   ilm.item_id               = iimb.item_id
      AND   ilm.lot_id                = in_lot_id
      AND   mil.inventory_location_id = in_whse_id
      AND   mil.organization_id       = iwm.mtl_organization_id
    ) mst_data,
      ic_loct_inv ili  -- �莝����
    WHERE mst_data.whse_code  = ili.location(+)
    AND   mst_data.item_id    = ili.item_id(+)
    AND   mst_data.lot_id     = ili.lot_id(+) ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_error;
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_onhand_lot;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_in_inout_rpt_qty
   * Description      : ���b�g I1)���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_lot_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_in_inout_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- ���Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- ���o�ɕ񍐗L
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_in_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_in_in_rpt_qty
   * Description      : ���b�g I2)���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_lot_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_in_in_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- ���Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- ���ɕ񍐗L
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_in_in_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_out_inout_rpt_qty
   * Description      : ���b�g I3)���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_lot_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_out_inout_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- �o�Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- ���o�ɕ񍐗L
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_out_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_out_out_rpt_qty
   * Description      : ���b�g I4)���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_lot_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_out_out_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- �o�Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- �o�ɕ񍐗L
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_out_out_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_ship_qty
   * Description      : ���b�g I5)���і���݌ɐ�  �o��
   ***********************************************************************************/
  PROCEDURE get_inv_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_ship_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '04';      -- �o�׎��ьv���
    cv_doc_type       CONSTANT VARCHAR2(2)  := '10';      -- �o�׈˗�
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- �o�Ɏ���
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '1';       -- �o�׈˗�
    cv_warehouse_type CONSTANT VARCHAR2(1)  := '3';       -- �q��
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- ��
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- �ԕi
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        mld.actual_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        mld.actual_quantity * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           IN (cv_ship_pro_type, cv_warehouse_type)
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_lot_provide_qty
   * Description      : ���b�g I6)���і���݌ɐ�  �x��
   ***********************************************************************************/
  PROCEDURE get_inv_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_lot_provide_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '08';      -- �o�׎��ьv���
    cv_doc_type       CONSTANT VARCHAR2(2)  := '30';      -- �x���w��
    cv_rec_type       CONSTANT VARCHAR2(2)  := '20';      -- �o�Ɏ���
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '2';       -- �x���˗�
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- ��
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- �ԕi
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        mld.actual_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        mld.actual_quantity * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     mld.item_id               = in_item_id
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_lot_provide_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_inv_in_qty
   * Description      : ���b�g S1)������  �ړ����ɗ\��
   ***********************************************************************************/
  PROCEDURE get_sup_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_inv_in_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- �˗��ς�
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- ������
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status
              IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_arrival_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_lot_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_order_qty
   * Description      : ���b�g S2)������  ��������\��
   ***********************************************************************************/
  PROCEDURE get_sup_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    iv_lot_no      IN VARCHAR2,             -- ���b�gNO
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_order_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- �����쐬��
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- �������
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(pla.quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b msib,
            po_lines_all       pla,
            po_headers_all     pha
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute1         = iv_lot_no
    AND     pla.attribute13        = cv_flag_off -- ���ʊm��t���O
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute5         = iv_whse_code
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- �[����
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_lot_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_produce_qty
   * Description      : ���b�g S3)������  ���Y���ɗ\��
   ***********************************************************************************/
  PROCEDURE get_sup_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_produce_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- �ۗ�
    cn_line_type_product    CONSTANT NUMBER(5,0) := 1;     -- �����i
    cn_line_type_byproduct  CONSTANT NUMBER(5,0) := 2;     -- ���Y��
    cv_doc_type             CONSTANT VARCHAR2(2) := '40';  -- ���Y�w��
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- �w��
    ln_not_yet              CONSTANT NUMBER(1,0) := 0;     -- ������
    lv_tran_doc_type        CONSTANT VARCHAR2(4) := 'PROD';
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- ���Y�o�b�`
            gme_material_details  gmd, -- ���Y�����ڍ�
            ic_tran_pnd           itp, -- OPM�ۗ��݌Ƀg�����U�N�V����
            xxinv_mov_lot_details mld, -- �ړ����b�g�ڍׁi�A�h�I���j
            gmd_routings_b        grb  -- �H���}�X�^
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type         IN (cn_line_type_product, cn_line_type_byproduct)
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = itp.line_id
    AND     itp.completed_ind      = ln_not_yet        -- ������
    AND     itp.doc_type           = lv_tran_doc_type
    AND     itp.lot_id             = in_lot_id
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- �[�i�ꏊ
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_lot_produce_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_lot_inv_out_qty
   * Description      : ���b�g S4)������  ���ьv��ς̈ړ��o�Ɏ���
   ***********************************************************************************/
  PROCEDURE get_sup_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_lot_inv_out_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '20';  -- �o�Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- �o�ɕ񍐂���
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.schedule_arrival_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_lot_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_ship_qty
   * Description      : ���b�g D1)���v��  ���і��v��̏o�׈˗�
   ***********************************************************************************/
  PROCEDURE get_dem_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- �i��ID
    in_item_code   IN VARCHAR2,               -- �i��
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- �i��ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_ship_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- ���ߍς�
    cv_doc_type       CONSTANT VARCHAR2(2) := '10';  -- �o�׈˗�
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- �o�׈˗�
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    AND     mld.item_id               = in_item_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
-- 2008/09/09 v1.7 UPDATE END
*/
    AND     mld.item_id               = in_item_id
-- 2008/09/10 v1.8 UPDATE END
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_ship_qty;
--
-- 2008/09/10 v1.8 ADD START
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_ship_qty2
   * Description      : ���b�g D1)���v��  ���і��v��̏o�׈˗��iCODE�x�[�X�j
   ***********************************************************************************/
  PROCEDURE get_dem_lot_ship_qty2(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_code   IN VARCHAR2,             -- �i��
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_ship_qty2'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- ���ߍς�
    cv_doc_type       CONSTANT VARCHAR2(2) := '10';  -- �o�׈˗�
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- �o�׈˗�
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_ship_qty2;
--
-- 2008/09/10 v1.8 ADD END
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_provide_qty
   * Description      : ���b�g D2)���v��  ���і��v��̎x���w��
   ***********************************************************************************/
  PROCEDURE get_dem_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- �i��ID
    in_item_code   IN VARCHAR2,               -- �i��
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- �i��ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_provide_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- ��̍ς�
    cv_doc_type       CONSTANT VARCHAR2(2) := '30';  -- �x���w��
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- �x���˗�
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
-- 2008/09/10 v1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    AND     mld.item_id               = in_item_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
-- 2008/09/09 v1.7 UPDATE END
*/
    AND     mld.item_id               = in_item_id
-- 2008/09/10 v1.8 UPDATE END
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_provide_qty;
--
-- 2008/09/10 v1.8 ADD START
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_provide_qty2
   * Description      : ���b�g D2)���v��  ���і��v��̎x���w���iCODE�x�[�X�j
   ***********************************************************************************/
  PROCEDURE get_dem_lot_provide_qty2(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_code   IN VARCHAR2,             -- �i��
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_provide_qty2'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- ��̍ς�
    cv_doc_type       CONSTANT VARCHAR2(2) := '30';  -- �x���w��
    cv_rec_type       CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- �x���˗�
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            xxinv_mov_lot_details      mld,  -- �ړ����b�g�ڍׁi�A�h�I���j
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     ola.order_line_id         = mld.mov_line_id
    AND     ola.shipping_item_code    = mld.item_code
    AND     ola.shipping_item_code    = in_item_code
    AND     mld.lot_id                = in_lot_id
    AND     mld.document_type_code    = cv_doc_type
    AND     mld.record_type_code      = cv_rec_type
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_provide_qty2;
--
-- 2008/09/10 v1.8 ADD END
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_inv_out_qty
   * Description      : ���b�g D3)���v��  ���і��v��̈ړ��w��
   ***********************************************************************************/
  PROCEDURE get_dem_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_inv_out_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '10';  -- �w��
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- �˗��ς�
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- ������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status
              IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_ship_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_inv_in_qty
   * Description      : ���b�g D4)���v��  ���ьv��ς̈ړ����Ɏ���
   ***********************************************************************************/
  PROCEDURE get_dem_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_inv_in_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���萔 ***
    cv_doc_type    CONSTANT VARCHAR2(2) := '20';  -- �ړ�
    cv_rec_type    CONSTANT VARCHAR2(2) := '30';  -- ���Ɏ���
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- ���ɕ񍐂���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril,   -- �ړ��˗�/�w�����ׁi�A�h�I���j
            xxinv_mov_lot_details       mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.schedule_ship_date  <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.mov_line_id        = mld.mov_line_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mld.item_id             = in_item_id
    AND     mld.lot_id              = in_lot_id
    AND     mld.document_type_code  = cv_doc_type
    AND     mld.record_type_code    = cv_rec_type
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_produce_qty
   * Description      : ���b�g D5)���v��  ���і��v��̐��Y�����\��
   ***********************************************************************************/
  PROCEDURE get_dem_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_produce_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- �ۗ�
    cn_line_type            CONSTANT NUMBER(5,0) := -1;    -- �����i
    cv_doc_type             CONSTANT VARCHAR2(2) := '40';  -- ���Y�w��
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- �w��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- ���Y�o�b�`
            gme_material_details  gmd, -- ���Y�����ڍ�
            xxinv_mov_lot_details mld, -- �ړ����b�g�ڍׁi�A�h�I���j
            gmd_routings_b        grb, -- �H���}�X�^
            ic_tran_pnd           itp  -- �ۗ��݌Ƀg�����U�N�V����
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_type
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- �[�i�ꏊ
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
    AND     itp.line_id            = gmd.material_detail_id 
    AND     itp.item_id            = gmd.item_id
    AND     itp.lot_id             = mld.lot_id
    AND     itp.completed_ind      = 0
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_produce_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_lot_order_qty
   * Description      : ���b�g D6)���v��  ���і��v��̑����q�ɔ������ɗ\��
   ***********************************************************************************/
  PROCEDURE get_dem_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_lot_order_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- �����쐬��
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- �������
    cv_doc_type             CONSTANT VARCHAR2(2) := '50';  -- ����
    cv_rec_type             CONSTANT VARCHAR2(2) := '10';  -- �w��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mld.actual_quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b    msib,   -- �i�ڃ}�X�^
            po_lines_all          pla,    -- ��������
            po_headers_all        pha,    -- �����w�b�_
            xxinv_mov_lot_details mld     -- �ړ����b�g�ڍׁi�A�h�I���j
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off  -- ���ʊm��t���O
    AND     pla.cancel_flag        = cv_flag_off
    AND     pla.attribute12        = iv_whse_code -- �����݌ɓ��ɐ�
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- �[����
    AND     pla.po_line_id         = mld.mov_line_id
    AND     mld.lot_id             = in_lot_id
    AND     mld.document_type_code = cv_doc_type
    AND     mld.record_type_code   = cv_rec_type
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_lot_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_onhand
   * Description      : �񃍃b�g  I0)EBS�莝�݌�
   ***********************************************************************************/
  PROCEDURE get_inv_onhand(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_whse_id     OUT NOCOPY NUMBER,       -- �ۊǑq��ID
    on_item_id     OUT NOCOPY NUMBER,       -- �i��ID
    on_onhand      OUT NOCOPY NUMBER,       -- �莝����
    ov_whse_code   OUT NOCOPY VARCHAR2,     -- �ۊǑq�ɃR�[�h
    ov_rep_whse    OUT NOCOPY VARCHAR2,     -- ��\�q��
    ov_item_code   OUT NOCOPY VARCHAR2,     -- �i�ڃR�[�h
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_onhand'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ln_no_lot_ctl    CONSTANT NUMBER(1,0) := 0;   -- �񃍃b�g�Ǘ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT mst_data.whse_code,
           mst_data.rep_wheh,
           mst_data.wheh_code,
           mst_data.item_id,
           mst_data.item_no,
           NVL(ili.loct_onhand,0)
    INTO ov_whse_code,
         ov_rep_whse,
         on_whse_id,
         on_item_id,
         ov_item_code,
         on_onhand
    FROM
    (
      SELECT  mil.segment1                AS whse_code,
              mil.attribute5              AS rep_wheh,
              mil.inventory_location_id   AS wheh_code,
              iimb.item_id                AS item_id,
              iimb.item_no                AS item_no
      FROM  ic_item_mst_b       iimb,   -- OPM�i�ڃ}�X�^
            mtl_item_locations  mil,    -- �ۊǏꏊ
            ic_whse_mst         iwm     -- �q��
      WHERE iimb.item_id              = in_item_id
      AND   iimb.lot_ctl              = ln_no_lot_ctl
      AND   mil.inventory_location_id = in_whse_id
      AND   mil.organization_id       = iwm.mtl_organization_id
    ) mst_data,
      ic_loct_inv ili  -- �莝����
    WHERE mst_data.whse_code  = ili.location(+)
    AND   mst_data.item_id    = ili.item_id(+);
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_error;
      ov_errmsg  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_onhand;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_in_inout_rpt_qty
   * Description      : �񃍃b�g  I1)���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_in_inout_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- ���o�ɕ񍐗L
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_in_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_in_in_rpt_qty
   * Description      : �񃍃b�g  I2)���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_in_in_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- ���ɕ񍐗L
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_in_in_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_out_inout_rpt_qty
   * Description      : �񃍃b�g  I3)���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_out_inout_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '06';  -- ���o�ɕ񍐗L
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_out_inout_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_out_out_rpt_qty
   * Description      : �񃍃b�g  I4)���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
   ***********************************************************************************/
  PROCEDURE get_inv_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_out_out_rpt_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- �o�ɕ񍐗L
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_out_out_rpt_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_ship_qty
   * Description      : �񃍃b�g  I5  ���і���݌ɐ�  �o��
   ***********************************************************************************/
  PROCEDURE get_inv_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_ship_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '04';      -- �o�׎��ьv���
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '1';       -- �o�׈˗�
    cv_warehouse_type CONSTANT VARCHAR2(1)  := '3';       -- �q��
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- ��
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- �ԕi
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        ola.shipped_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        ola.shipped_quantity * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            mtl_system_items_b        msib,  -- �i�ڃ}�X�^
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           IN (cv_ship_pro_type, cv_warehouse_type)
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_provide_qty
   * Description      : �񃍃b�g  I6)���і���݌ɐ�  �x��
   ***********************************************************************************/
  PROCEDURE get_inv_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_provide_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1)  := 'N';       -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1)  := 'Y';       -- ON
    cv_req_status     CONSTANT VARCHAR2(2)  := '08';      -- �o�׎��ьv���
    cv_ship_pro_type  CONSTANT VARCHAR2(1)  := '2';       -- �x���˗�
    cv_cate_order     CONSTANT VARCHAR2(10) := 'ORDER';   -- ��
    cv_cate_return    CONSTANT VARCHAR2(10) := 'RETURN';  -- �ԕi
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(CASE
                      WHEN (otta.order_category_code = cv_cate_order) THEN
                        ola.shipped_quantity
                      WHEN (otta.order_category_code = cv_cate_return) THEN
                        ola.shipped_quantity * -1
                    END), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            mtl_system_items_b        msib,  -- �i�ڃ}�X�^
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inv_provide_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_inv_in_qty
   * Description      : �񃍃b�g  S1)������  �ړ����ɗ\��
   ***********************************************************************************/
  PROCEDURE get_sup_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_inv_in_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- �˗��ς�
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- ������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.instruct_qty), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status            IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_arrival_date <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_order_qty
   * Description      : �񃍃b�g  S2)������  ��������\��
   ***********************************************************************************/
  PROCEDURE get_sup_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_order_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_po_status_order_fin  CONSTANT VARCHAR2(2) := '20';  -- �����쐬��
    cv_po_status_accept     CONSTANT VARCHAR2(2) := '25';  -- �������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(pla.quantity), 0)
    INTO    on_qty
    FROM    mtl_system_items_b msib,
            po_lines_all       pla,
            po_headers_all     pha
    WHERE   msib.segment1          = iv_item_code
    AND     msib.organization_id   = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id = pla.item_id
    AND     pla.attribute13        = cv_flag_off -- ���ʊm��t���O
    AND     pla.po_header_id       = pha.po_header_id
    AND     pha.attribute1        IN (cv_po_status_order_fin, cv_po_status_accept)
    AND     pha.attribute5         = iv_whse_code
    AND     pha.attribute4        <= TO_CHAR(id_eff_date, 'YYYY/MM/DD') -- �[����
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_order_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_sup_inv_out_qty
   * Description      : �񃍃b�g  S4)������  ���ьv��ς̈ړ��o�Ɏ���
   ***********************************************************************************/
  PROCEDURE get_sup_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sup_inv_out_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '04';  -- �o�ɕ񍐂���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.shipped_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.ship_to_locat_id       = in_whse_id
    AND     mrih.comp_actual_flg        = cv_flag_off
    AND     mrih.status                 = cv_move_status
    AND     mrih.schedule_arrival_date <= id_eff_date
    AND     mrih.mov_hdr_id             = mril.mov_hdr_id
    AND     mril.delete_flg             = cv_flag_off
    AND     mril.item_id                = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sup_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_ship_qty
   * Description      : �񃍃b�g  D1)���v��  ���і��v��̏o�׈˗�
   ***********************************************************************************/
  PROCEDURE get_dem_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ������
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_ship_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '03';  -- ���ߍς�
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '1';   -- �o�׈˗�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(ola.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            mtl_system_items_b        msib,  -- �i�ڃ}�X�^
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_ship_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_provide_qty
   * Description      : �񃍃b�g  D2)���v��  ���і��v��̎x���w��
   ***********************************************************************************/
  PROCEDURE get_dem_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ������
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_provide_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off       CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_flag_on        CONSTANT VARCHAR2(1) := 'Y';   -- ON
    cv_req_status     CONSTANT VARCHAR2(2) := '07';  -- ��̍�
    cv_ship_pro_type  CONSTANT VARCHAR2(1) := '2';   -- �x���˗�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(ola.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxwsh_order_headers_all    oha,  -- �󒍃w�b�_�i�A�h�I���j
            xxwsh_order_lines_all      ola,  -- �󒍖��ׁi�A�h�I���j
            mtl_system_items_b        msib,  -- �i�ڃ}�X�^
            oe_transaction_types_all  otta   -- �󒍃^�C�v
    WHERE   msib.segment1             = iv_item_code
    AND     msib.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND     msib.inventory_item_id    = ola.shipping_inventory_item_id
    AND     oha.deliver_from_id       = in_whse_id
    AND     oha.req_status            = cv_req_status
    AND     oha.actual_confirm_class  = cv_flag_off
    AND     oha.latest_external_flag  = cv_flag_on
    AND     oha.schedule_ship_date   <= id_eff_date
    AND     oha.order_header_id       = ola.order_header_id
    AND     ola.delete_flag           = cv_flag_off
    AND     otta.attribute1           = cv_ship_pro_type
    AND     otta.transaction_type_id  = oha.order_type_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_provide_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_inv_out_qty
   * Description      : �񃍃b�g  D3)���v��  ���і��v��̈ړ��w��
   ***********************************************************************************/
  PROCEDURE get_dem_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ������
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_inv_out_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off            CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status_req_fin CONSTANT VARCHAR2(2) := '02';  -- �˗��ς�
    cv_move_status_adjust  CONSTANT VARCHAR2(2) := '03';  -- ������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.reserved_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status            IN (cv_move_status_req_fin, cv_move_status_adjust)
    AND     mrih.schedule_ship_date <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_inv_out_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_inv_in_qty
   * Description      : �񃍃b�g  D4)���v��  ���ьv��ς̈ړ����Ɏ���
   ***********************************************************************************/
  PROCEDURE get_dem_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_inv_in_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off    CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cv_move_status CONSTANT VARCHAR2(2) := '05';  -- ���ɕ񍐗L
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(mril.ship_to_quantity), 0)
    INTO    on_qty
    FROM    xxinv_mov_req_instr_headers mrih,   -- �ړ��˗�/�w���w�b�_�i�A�h�I���j
            xxinv_mov_req_instr_lines   mril    -- �ړ��˗�/�w�����ׁi�A�h�I���j
    WHERE   mrih.shipped_locat_id   = in_whse_id
    AND     mrih.comp_actual_flg    = cv_flag_off
    AND     mrih.status             = cv_move_status
    AND     mrih.schedule_ship_date <= id_eff_date
    AND     mrih.mov_hdr_id         = mril.mov_hdr_id
    AND     mril.delete_flg         = cv_flag_off
    AND     mril.item_id            = in_item_id
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_inv_in_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_dem_produce_qty
   * Description      : �񃍃b�g  D5)���v��  ���і��v��̐��Y�����\��
   ***********************************************************************************/
  PROCEDURE get_dem_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dem_produce_qty'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_flag_off             CONSTANT VARCHAR2(1) := 'N';   -- OFF
    cn_batch_status_wip     CONSTANT NUMBER(5,0) := 2;     -- WIP
    cn_batch_status_reserv  CONSTANT NUMBER(5,0) := 1;     -- �ۗ�
    cn_line_type            CONSTANT NUMBER(5,0) := -1;    -- �����i
    cv_plan_type            CONSTANT VARCHAR2(1) := '4';   -- ����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  NVL(SUM(xmd.instructions_qty), 0)
    INTO    on_qty
    FROM    gme_batch_header      gbh, -- ���Y�o�b�`
            gme_material_details  gmd, -- ���Y�����ڍ�
            xxwip_material_detail xmd, -- ���Y�����ڍׁi�A�h�I���j
            gmd_routings_b        grb  -- �H���}�X�^
    WHERE   gbh.batch_status      IN (cn_batch_status_wip, cn_batch_status_reserv)
    AND     gbh.plan_start_date   <= id_eff_date
    AND     gbh.batch_id           = gmd.batch_id
    AND     gmd.line_type          = cn_line_type
    AND     gmd.item_id            = in_item_id
    AND     gmd.material_detail_id = xmd.material_detail_id
    AND     xmd.plan_type          = cv_plan_type
    AND     gbh.routing_id         = grb.routing_id
    AND     grb.attribute9         = iv_whse_code       -- �[�i�ꏊ
    AND     xmd.invested_qty       = 0
    ;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_dem_produce_qty;
--
--
--  /**********************************************************************************
--   * Function Name    : get_can_enc_total_qty
--   * Description      : �������\���Z�oAPI
--   ***********************************************************************************/
--  FUNCTION get_can_enc_total_qty(
--    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
--    in_item_id          IN NUMBER,                    -- OPM�i��ID
--    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
--    RETURN NUMBER
--  IS
--    -- ===============================
--    -- �Œ胍�[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_total_qty'; --�v���O������
--    -- ===============================
--    -- ���[�U�[�錾��
--    -- ===============================
--    -- *** ���[�J���萔 ***
--    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX���t'; --�v���t�@�C����
----
--    -- *** ���[�J���ϐ� ***
--    ld_eff_date    DATE;          -- �L����
--    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
----
--    -- ===============================
--    -- ���[�U�[��`��O
--    -- ===============================
--    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
----
--  BEGIN
----
--    -- ***********************************************
--    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
--    -- ***********************************************
--    -- MAX���t���擾
--    ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),'YYYY/MM/DD');
--    IF (ld_eff_date IS NULL) THEN
--      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN', 'APP-XXCMN-10002', 'NG_PROFILE', cv_prf_max_date_name);
--      RAISE process_exp;
--    END IF;
----
--    -- �������\��
--    RETURN get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id, ld_eff_date);
----
--  EXCEPTION
--    WHEN process_exp THEN
--      RAISE_APPLICATION_ERROR
--        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
----
----###############################  �Œ��O������ START   ###################################
----
--    WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
----
----###################################  �Œ蕔 END   #########################################
----
--  END get_can_enc_total_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_in_time_qty
   * Description      : �L�����x�[�X�����\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE   DEFAULT NULL)       -- �L����
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_in_time_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���ϐ� ***
    ln_whse_id     NUMBER;        -- �ۊǑq��ID
    ln_item_id     NUMBER;        -- �i��ID
    ln_lot_id      NUMBER;        -- ���b�gID
    ln_item_code   VARCHAR2(40);  -- �i�ڃR�[�h
    lv_whse_code   VARCHAR2(40);  -- �ۊǑq�ɃR�[�h
    lv_rep_whse    VARCHAR2(150); -- ��\�q��
    lv_item_code   VARCHAR2(32);  -- �i�ڃR�[�h
    lv_lot_no      VARCHAR2(32);  -- ���b�gNO
    ld_eff_date    DATE;          -- �L����
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���萔 ***
    cv_prf_max_date_name CONSTANT VARCHAR2(15)  := 'MAX���t'; --�v���t�@�C����
--
    ln_inv_lot_onhand             NUMBER; -- ���b�g I0)���ʐ���
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ���b�g I1)���ʐ���
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ���b�g I2)���ʐ���
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ���b�g I3)���ʐ���
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ���b�g I4)���ʐ���
    ln_inv_lot_ship_qty           NUMBER; -- ���b�g I5)���ʐ���
    ln_inv_lot_provide_qty        NUMBER; -- ���b�g I6)���ʐ���
    ln_inv_onhand                 NUMBER; -- �񃍃b�g I0)���ʐ���
    ln_inv_in_inout_rpt_qty       NUMBER; -- �񃍃b�g I1)���ʐ���
    ln_inv_in_in_rpt_qty          NUMBER; -- �񃍃b�g I2)���ʐ���
    ln_inv_out_inout_rpt_qty      NUMBER; -- �񃍃b�g I3)���ʐ���
    ln_inv_out_out_rpt_qty        NUMBER; -- �񃍃b�g I4)���ʐ���
    ln_inv_ship_qty               NUMBER; -- �񃍃b�g I5)���ʐ���
    ln_inv_provide_qty            NUMBER; -- �񃍃b�g I6)���ʐ���
    ln_sup_lot_inv_in_qty         NUMBER; -- ���b�g S1)���ʐ���
    ln_sup_lot_order_qty          NUMBER; -- ���b�g S2)���ʐ���
    ln_sup_lot_produce_qty        NUMBER; -- ���b�g S3)���ʐ���
    ln_sup_lot_inv_out_qty        NUMBER; -- ���b�g S4)���ʐ���
    ln_dem_lot_ship_qty           NUMBER; -- ���b�g D1)���ʐ���
    ln_dem_lot_provide_qty        NUMBER; -- ���b�g D2)���ʐ���
    ln_dem_lot_inv_out_qty        NUMBER; -- ���b�g D3)���ʐ���
    ln_dem_lot_inv_in_qty         NUMBER; -- ���b�g D4)���ʐ���
    ln_dem_lot_produce_qty        NUMBER; -- ���b�g D5)���ʐ���
    ln_dem_lot_order_qty          NUMBER; -- ���b�g D6)���ʐ���
    ln_sup_inv_in_qty             NUMBER; -- �񃍃b�g S1)���ʐ���
    ln_sup_order_qty              NUMBER; -- �񃍃b�g S2)���ʐ���
    ln_sup_inv_out_qty            NUMBER; -- �񃍃b�g S4)���ʐ���
    ln_dem_ship_qty               NUMBER; -- �񃍃b�g D1)���ʐ���
    ln_dem_provide_qty            NUMBER; -- �񃍃b�g D2)���ʐ���
    ln_dem_inv_out_qty            NUMBER; -- �񃍃b�g D3)���ʐ���
    ln_dem_inv_in_qty             NUMBER; -- �񃍃b�g D4)���ʐ���
    ln_dem_produce_qty            NUMBER; -- �񃍃b�g D5)���ʐ���
--
    ln_stock_qty  NUMBER; -- �݌ɐ�
    ln_supply_qty NUMBER; -- ������
    ln_demand_qty NUMBER; -- ���v��
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_stock_qty  := 0;
    ln_supply_qty := 0;
    ln_demand_qty := 0;
--
    -- �L�������擾
    IF (in_active_date IS NULL) THEN
        -- MAX���t���擾
      ld_eff_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),'YYYY/MM/DD');
      IF (ld_eff_date IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN',
                                              'APP-XXCMN-10002',
                                              'NG_PROFILE',
                                              cv_prf_max_date_name);
        RAISE process_exp;
      END IF;
    ELSE
      ld_eff_date := in_active_date;
    END IF;
--
    --���b�g�Ǘ��̏ꍇ
    IF (in_lot_id IS NOT NULL) THEN
      -- ���b�g I0 EBS�莝�݌�
      get_inv_onhand_lot(
        in_whse_id,
        in_item_id,
        in_lot_id,
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_lot_no,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I1 ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
      get_inv_lot_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I2 ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
      get_inv_lot_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I3 ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
      get_inv_lot_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I4 ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
      get_inv_lot_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I5 ���і���݌ɐ�  �o��
      get_inv_lot_ship_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I6 ���і���݌ɐ�  �x��
      get_inv_lot_provide_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g S1)������  �ړ����ɗ\��
     get_sup_lot_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g S2)������  ��������\��
     get_sup_lot_order_qty(
        lv_whse_code,
        lv_item_code,
        lv_lot_no,
        ld_eff_date,
        ln_sup_lot_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g S3)������  ���Y���ɗ\��
     get_sup_lot_produce_qty(
        lv_whse_code,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g S4)������  ���ьv��ς̈ړ��o�Ɏ���
     get_sup_lot_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_sup_lot_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D1)���v��  ���і��v��̏o�׈˗�
-- 2008/09/10 v1.8 UPDATE START
--      get_dem_lot_ship_qty(
      get_dem_lot_ship_qty2(
-- 2008/09/10 v1.8 UPDATE END
        ln_whse_id,
-- 2008/09/09 v1.7 UPDATE START
--        ln_item_id,
        lv_item_code,
-- 2008/09/09 v1.7 UPDATE END
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D2)���v��  ���і��v��̎x���w��
-- 2008/09/10 v1.8 UPDATE START
--      get_dem_lot_provide_qty(
      get_dem_lot_provide_qty2(
-- 2008/09/10 v1.8 UPDATE END
        ln_whse_id,
-- 2008/09/09 v1.7 UPDATE START
--        ln_item_id,
        lv_item_code,
-- 2008/09/09 v1.7 UPDATE END
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D3)���v��  ���і��v��̈ړ��w��
      get_dem_lot_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D4)���v��  ���ьv��ς̈ړ����Ɏ���
      get_dem_lot_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D5)���v��  ���і��v��̐��Y�����\��
      get_dem_lot_produce_qty(
        lv_whse_code,
        ln_item_id,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g D6)���v��  ���і��v��̑����q�ɔ������ɗ\��
      get_dem_lot_order_qty(
        lv_whse_code,
        lv_item_code,
        ln_lot_id,
        ld_eff_date,
        ln_dem_lot_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g�Ǘ��i�݌ɐ�
      ln_stock_qty := ln_inv_lot_onhand 
                    + ln_inv_lot_in_inout_rpt_qty
                    + ln_inv_lot_in_in_rpt_qty
                    - ln_inv_lot_out_inout_rpt_qty
                    - ln_inv_lot_out_out_rpt_qty
                    - ln_inv_lot_ship_qty
                    - ln_inv_lot_provide_qty;
--
      -- ���b�g�Ǘ��i������
      ln_supply_qty := ln_sup_lot_inv_in_qty
                     + ln_sup_lot_order_qty
                     + ln_sup_lot_produce_qty
                     + ln_sup_lot_inv_out_qty;
--
      -- ���b�g�Ǘ��i���v��
      ln_demand_qty := ln_dem_lot_ship_qty
                     + ln_dem_lot_provide_qty
                     + ln_dem_lot_inv_out_qty
                     + ln_dem_lot_inv_in_qty 
                     + ln_dem_lot_produce_qty
                     + ln_dem_lot_order_qty;
--
    ELSE
      --�񃍃b�g  I0  EBS�莝�݌�
      get_inv_onhand(
        in_whse_id,
        in_item_id,
        ln_whse_id,
        ln_item_id,
        ln_inv_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
      get_inv_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
      get_inv_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
      get_inv_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
      get_inv_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I5  ���і���݌ɐ�  �o��
      get_inv_ship_qty(
        ln_whse_id,
-- 2008.06.24 mod S.Takemoto start
--        ln_item_id,
        lv_item_code,
-- 2008.06.24 mod S.Takemoto end
        ln_inv_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I6  ���і���݌ɐ�  �x��
      get_inv_provide_qty(
        ln_whse_id,
-- 2008.06.24 mod S.Takemoto start
--        ln_item_id,
        lv_item_code,
-- 2008.06.24 mod S.Takemoto end
        ln_inv_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  S1)������  �ړ����ɗ\��
      get_sup_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_sup_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  S2)������  ��������\��
      get_sup_order_qty(
        lv_whse_code,
        lv_item_code,
        ld_eff_date,
        ln_sup_order_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  S4)������  ���ьv��ς̈ړ��o�Ɏ���
      get_sup_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_sup_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  D1)���v��  ���і��v��̏o�׈˗�
      get_dem_ship_qty(
        ln_whse_id,
        lv_item_code,
        ld_eff_date,
        ln_dem_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  D2)���v��  ���і��v��̎x���w��
      get_dem_provide_qty(
        ln_whse_id,
        lv_item_code,
        ld_eff_date,
        ln_dem_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  D3)���v��  ���і��v��̈ړ��w��
      get_dem_inv_out_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_dem_inv_out_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  D4)���v��  ���ьv��ς̈ړ����Ɏ���
      get_dem_inv_in_qty(
        ln_whse_id,
        ln_item_id,
        ld_eff_date,
        ln_dem_inv_in_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  D5)���v��  ���і��v��̐��Y�����\��
      get_dem_produce_qty(
        lv_whse_code,
        ln_item_id,
        ld_eff_date,
        ln_dem_produce_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g�Ǘ��i�݌ɐ�
      ln_stock_qty := ln_inv_onhand
                    + ln_inv_in_inout_rpt_qty
                    + ln_inv_in_in_rpt_qty
                    - ln_inv_out_inout_rpt_qty
                    - ln_inv_out_out_rpt_qty
                    - ln_inv_ship_qty
                    - ln_inv_provide_qty;
--
      -- �񃍃b�g�Ǘ��i������
      ln_supply_qty := ln_sup_inv_in_qty
                     + ln_sup_order_qty
                     + ln_sup_inv_out_qty;
--
      -- �񃍃b�g�Ǘ��i���v��
      ln_demand_qty := ln_dem_ship_qty
                     + ln_dem_provide_qty
                     + ln_dem_inv_out_qty
                     + ln_dem_inv_in_qty
                     + ln_dem_produce_qty;
--
    END IF;
--
    -- �L�����x�[�X�����\��
    RETURN ln_stock_qty + ln_supply_qty - ln_demand_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_in_time_qty;
--
  /**********************************************************************************
   * Function Name    : get_stock_qty
   * Description      : �莝�݌ɐ��ʎZ�oAPI
   ***********************************************************************************/
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_qty'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_whse_id     NUMBER;        -- �ۊǑq��ID
    ln_item_id     NUMBER;        -- �i��ID
    ln_lot_id      NUMBER;        -- ���b�gID
    lv_whse_code   VARCHAR2(40);  -- �ۊǑq�ɃR�[�h
    lv_rep_whse    VARCHAR2(150); -- ��\�q��
    lv_item_code   VARCHAR2(32);  -- �i�ڃR�[�h
    lv_lot_no      VARCHAR2(32);  -- ���b�gNO
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_inv_lot_onhand             NUMBER; -- ���b�g I0)���ʐ���
    ln_inv_lot_in_inout_rpt_qty   NUMBER; -- ���b�g I1)���ʐ���
    ln_inv_lot_in_in_rpt_qty      NUMBER; -- ���b�g I2)���ʐ���
    ln_inv_lot_out_inout_rpt_qty  NUMBER; -- ���b�g I3)���ʐ���
    ln_inv_lot_out_out_rpt_qty    NUMBER; -- ���b�g I4)���ʐ���
    ln_inv_lot_ship_qty           NUMBER; -- ���b�g I5)���ʐ���
    ln_inv_lot_provide_qty        NUMBER; -- ���b�g I6)���ʐ���
    ln_inv_onhand                 NUMBER; -- �񃍃b�g I0)���ʐ���
    ln_inv_in_inout_rpt_qty       NUMBER; -- �񃍃b�g I1)���ʐ���
    ln_inv_in_in_rpt_qty          NUMBER; -- �񃍃b�g I2)���ʐ���
    ln_inv_out_inout_rpt_qty      NUMBER; -- �񃍃b�g I3)���ʐ���
    ln_inv_out_out_rpt_qty        NUMBER; -- �񃍃b�g I4)���ʐ���
    ln_inv_ship_qty               NUMBER; -- �񃍃b�g I5)���ʐ���
    ln_inv_provide_qty            NUMBER; -- �񃍃b�g I6)���ʐ���
--
    ln_stock_qty NUMBER;
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
    ln_stock_qty := 0;
--
    IF (in_lot_id IS NOT NULL) THEN
      -- ���b�g I0 EBS�莝�݌�
      get_inv_onhand_lot(
        in_whse_id,
        in_item_id,
        in_lot_id,
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_lot_no,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I1 ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
      get_inv_lot_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I2 ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
      get_inv_lot_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I3 ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
      get_inv_lot_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I4 ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
      get_inv_lot_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I5 ���і���݌ɐ�  �o��
      get_inv_lot_ship_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- ���b�g I6 ���і���݌ɐ�  �x��
      get_inv_lot_provide_qty(
        ln_whse_id,
        ln_item_id,
        ln_lot_id,
        ln_inv_lot_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      ln_stock_qty := ln_inv_lot_onhand 
                    + ln_inv_lot_in_inout_rpt_qty
                    + ln_inv_lot_in_in_rpt_qty
                    - ln_inv_lot_out_inout_rpt_qty
                    - ln_inv_lot_out_out_rpt_qty
                    - ln_inv_lot_ship_qty
                    - ln_inv_lot_provide_qty;
--
    ELSE
      --�񃍃b�g  I0  EBS�莝�݌�
      get_inv_onhand(
        in_whse_id,
        in_item_id,
        ln_whse_id,
        ln_item_id,
        ln_inv_onhand,
        lv_whse_code,
        lv_rep_whse,
        lv_item_code,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
      get_inv_in_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
      get_inv_in_in_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_in_in_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
      get_inv_out_inout_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_inout_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
      get_inv_out_out_rpt_qty(
        ln_whse_id,
        ln_item_id,
        ln_inv_out_out_rpt_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I5  ���і���݌ɐ�  �o��
      get_inv_ship_qty(
        ln_whse_id,
        lv_item_code,
        ln_inv_ship_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      -- �񃍃b�g  I6  ���і���݌ɐ�  �x��
      get_inv_provide_qty(
        ln_whse_id,
        lv_item_code,
        ln_inv_provide_qty,
        lv_errbuf,
        lv_retcode,
        lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        -- �G���[���b�Z�[�W�͐ݒ�ς�
        RAISE process_exp;
      END IF;
--
      ln_stock_qty := ln_inv_onhand
                    + ln_inv_in_inout_rpt_qty
                    + ln_inv_in_in_rpt_qty
                    - ln_inv_out_inout_rpt_qty
                    - ln_inv_out_out_rpt_qty
                    - ln_inv_ship_qty
                    - ln_inv_provide_qty;
--
    END IF;
--
    RETURN ln_stock_qty;
--
  EXCEPTION
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_stock_qty;
--
  /**********************************************************************************
   * Function Name    : get_can_enc_qty
   * Description      : �����\���Z�oAPI
   ***********************************************************************************/
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER                                     -- �����\��
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_can_enc_qty'; --�v���O������
-- Ver1.6 M.Hokkanji Start
    cv_xxcmn                CONSTANT VARCHAR2(10)  := 'XXCMN';
    cv_dummy_frequent_whse  CONSTANT VARCHAR2(100) := 'XXCMN_DUMMY_FREQUENT_WHSE';
    cv_error_10002          CONSTANT VARCHAR2(30)  := 'APP-XXCMN-10002'; --�v���t�@�C���擾�G���[
    cv_tkn_ng_profile       CONSTANT VARCHAR2(30)  := 'NG_PROFILE'; --�g�[�N��
-- Ver1.6 M.Hokkanji End
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_whse_id     NUMBER;        -- �ۊǑq��ID
    ln_item_id     NUMBER;        -- �i��ID
    ln_lot_id      NUMBER;        -- ���b�gID
    lv_whse_code   VARCHAR2(40);  -- �ۊǑq�ɃR�[�h
    lv_rep_whse    VARCHAR2(150); -- ��\�q��
    lv_item_code   VARCHAR2(32);  -- �i�ڃR�[�h
    lv_lot_no      VARCHAR2(32);  -- ���b�gNO
    ld_eff_date    DATE;          -- �L����
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_all_enc_qty      NUMBER;     -- �Ώۂ̑������\��
    ln_in_time_enc_qty  NUMBER;     -- �Ώۂ̗L�����x�[�X�����\��
    ln_enc_qty          NUMBER;     -- �����\��
    ln_ref_all_enc_qty      NUMBER; -- �Ώېe��q�̑������\��
    ln_ref_in_time_enc_qty  NUMBER; -- �Ώېe��q�̗L�����x�[�X�����\��
    lt_inventory_location_id mtl_item_locations.inventory_location_id%TYPE; -- �ۊǑq��ID
-- Ver1.6 M.Hokkanji Start
    lt_dummy_frequent_whse  mtl_item_locations.segment1%TYPE; --�_�~�[��\�q��
-- Ver1.6 M.Hokkanji End
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    process_exp               EXCEPTION;     -- �e�����ŃG���[�����������ꍇ
-- Ver1.6 M.Hokkanji Start
    profile_exp               EXCEPTION;     -- �v���t�@�C���擾���s
-- Ver1.6 M.Hokkanji End
    PRAGMA EXCEPTION_INIT(process_exp, -20001);
-- Ver1.6 M.Hokkanji Start
    PRAGMA EXCEPTION_INIT(profile_exp, -20002);
-- Ver1.6 M.Hokkanji End
--
  BEGIN
--
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- ���ʂ̏�����
    ln_all_enc_qty     := 0;
    ln_in_time_enc_qty := 0;
--
    BEGIN
      -- ��\�q�ɂ��擾
      SELECT  mil.segment1,              -- �ۊǑq�ɃR�[�h
              mil.attribute5             -- ��\�q��
      INTO    lv_whse_code,
              lv_rep_whse
      FROM    mtl_item_locations  mil   -- �ۊǏꏊ
      WHERE   mil.inventory_location_id = in_whse_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE process_exp;
    END;
--
    -- �P�̂̈����\�����Z�o
    ln_all_enc_qty     := get_can_enc_in_time_qty(in_whse_id, in_item_id, in_lot_id);
    ln_in_time_enc_qty := get_can_enc_in_time_qty(in_whse_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date);
--
    -- ��\�q�ɂłȂ��ꍇ
    IF (lv_rep_whse IS NULL) THEN
      ln_ref_all_enc_qty      := 0;
      ln_ref_in_time_enc_qty  := 0;
--
    -- ��\�q�Ɂi�e�j�̏ꍇ
    ELSIF (lv_rep_whse = lv_whse_code) THEN
      -- ��\�q�Ɂi�q�j�̍��v���擾
      SELECT  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                              in_item_id,
                                              in_lot_id)),0),
              NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                              in_item_id,
                                              in_lot_id,
                                              in_active_date)),0)
      INTO    ln_ref_all_enc_qty,
              ln_ref_in_time_enc_qty
      FROM    mtl_item_locations  mil    -- �ۊǏꏊ
      WHERE   mil.attribute5            = lv_rep_whse -- ��\�q��
      AND     mil.segment1             <> mil.attribute5;
--
      -- ��������
      ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
--
      -- ��\�q��(�q)(�q�ɁE�i�ڒP��)�̍��v���擾
       SELECT  NVL(SUM(get_can_enc_in_time_qty(xfil.item_location_id,
                                              in_item_id,
                                              in_lot_id)),0),
               NVL(SUM(get_can_enc_in_time_qty(xfil.item_location_id,
                                              in_item_id,
                                              in_lot_id,
                                              in_active_date)),0)
       INTO    ln_ref_all_enc_qty,
               ln_ref_in_time_enc_qty
       FROM    xxwsh_frq_item_locations xfil
       WHERE   xfil.frq_item_location_code = lv_rep_whse -- ��\�q�ɃR�[�h
       AND     xfil.item_id = in_item_id;                -- OPM�i��ID
--
      -- ��������
      ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
--
    -- ��\�q�Ɂi�q�j�̏ꍇ
    ELSE
      -- �_�~�[��\�q�ɂ��擾
      lt_dummy_frequent_whse := FND_PROFILE.VALUE(cv_dummy_frequent_whse);
      -- �擾�Ɏ��s�����ꍇ
      IF (lt_dummy_frequent_whse IS NULL) THEN
        RAISE profile_exp ;
      END IF ;
      IF (lv_rep_whse = lt_dummy_frequent_whse) THEN
        BEGIN
          -- �q�ɕi�ڃ}�X�^���Q��
          SELECT  NVL(SUM(get_can_enc_in_time_qty(xfil.frq_item_location_id,
                                                  in_item_id,
                                                  in_lot_id)),0),
                  NVL(SUM(get_can_enc_in_time_qty(xfil.frq_item_location_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date)),0)
          INTO    ln_ref_all_enc_qty,
                  ln_ref_in_time_enc_qty
          FROM    xxwsh_frq_item_locations xfil
          WHERE   xfil.item_location_code = lv_whse_code         -- ���q��
          AND     xfil.item_id = in_item_id;                     -- OPM�i��ID
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      ELSE
        BEGIN
          -- ��\�q�Ɂi�e�j���擾
          SELECT  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                                  in_item_id,
                                                  in_lot_id)),0),
                  NVL(SUM(get_can_enc_in_time_qty(mil.inventory_location_id,
                                                  in_item_id,
                                                  in_lot_id,
                                                  in_active_date)),0)
          INTO    ln_ref_all_enc_qty,
                  ln_ref_in_time_enc_qty
          FROM    mtl_item_locations  mil    -- �ۊǏꏊ
          WHERE   mil.attribute5            = lv_rep_whse -- ��\�q��
          AND     mil.segment1              = mil.attribute5;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_ref_all_enc_qty := 0;
            ln_ref_in_time_enc_qty := 0;
        END;
      END IF;
      -- �e�P�̂̈����\�����}�C�i�X�̏ꍇ�̂ݑ�������
      IF (ln_ref_all_enc_qty < 0) THEN
        ln_all_enc_qty      := ln_all_enc_qty     + ln_ref_all_enc_qty;
      END IF;
      IF (ln_ref_in_time_enc_qty < 0) THEN
        ln_in_time_enc_qty  := ln_in_time_enc_qty + ln_ref_in_time_enc_qty;
      END IF;
    END IF;
--
    -- ���Ȃ����������\��
    IF (ln_all_enc_qty < ln_in_time_enc_qty) THEN
      ln_enc_qty := ln_all_enc_qty;
    ELSE
      ln_enc_qty := ln_in_time_enc_qty;
    END IF;
--
    -- �����\��
    RETURN ln_enc_qty;
--
  EXCEPTION
-- Ver1.6 M.Hokkanji Start
    WHEN profile_exp THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( cv_xxcmn
                                            ,cv_error_10002
                                            ,cv_tkn_ng_profile
                                            ,cv_dummy_frequent_whse
                                           ) ;
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errmsg,1,5000),TRUE);
-- Ver1.6 M.Hokkanji End
    WHEN process_exp THEN
      RAISE_APPLICATION_ERROR
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_can_enc_qty;
--
END xxcmn_common2_pkg;
/
