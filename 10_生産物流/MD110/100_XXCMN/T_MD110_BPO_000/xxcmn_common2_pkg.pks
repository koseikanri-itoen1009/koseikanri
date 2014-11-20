CREATE OR REPLACE PACKAGE xxcmn_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common2_pkg(SPEC)
 * Description            : ���ʊ֐�2(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_�����\���Z�o�i�⑫�����j.doc
 * Version                : 1.5
 *
 * Program List
 *  --------------------------- ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------------- ---- ----- --------------------------------------------------
 *  get_inv_onhand_lot            P   �Ȃ�  ���b�g    I0  EBS�莝�݌�
 *  get_inv_lot_in_inout_rpt_qty  P   �Ȃ�  ���b�g    I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
 *  get_inv_lot_in_in_rpt_qty     P   �Ȃ�  ���b�g    I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
 *  get_inv_lot_out_inout_rpt_qty P   �Ȃ�  ���b�g    I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
 *  get_inv_lot_out_out_rpt_qty   P   �Ȃ�  ���b�g    I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
 *  get_inv_lot_ship_qty          P   �Ȃ�  ���b�g    I5  ���і���݌ɐ�  �o��
 *  get_inv_lot_provide_qty       P   �Ȃ�  ���b�g    I6  ���і���݌ɐ�  �x��
 *  get_sup_lot_inv_in_qty        P   �Ȃ�  ���b�g    S1  ������  �ړ����ɗ\��
 *  get_sup_lot_order_qty         P   �Ȃ�  ���b�g    S2  ������  ��������\��
 *  get_sup_lot_produce_qty       P   �Ȃ�  ���b�g    S3  ������  ���Y���ɗ\��
 *  get_sup_lot_inv_out_qty       P   �Ȃ�  ���b�g    S4  ������  ���ьv��ς̈ړ��o�Ɏ���
 *  get_dem_lot_ship_qty          P   �Ȃ�  ���b�g    D1  ���v��  ���і��v��̏o�׈˗�
 *  get_dem_lot_provide_qty       P   �Ȃ�  ���b�g    D2  ���v��  ���і��v��̎x���w��
 *  get_dem_lot_inv_out_qty       P   �Ȃ�  ���b�g    D3  ���v��  ���і��v��̈ړ��w��
 *  get_dem_lot_inv_in_qty        P   �Ȃ�  ���b�g    D4  ���v��  ���ьv��ς̈ړ����Ɏ���
 *  get_dem_lot_produce_qty       P   �Ȃ�  ���b�g    D5  ���v��  ���і��v��̐��Y�����\��
 *  get_dem_lot_order_qty         P   �Ȃ�  ���b�g    D6  ���v��  ���і��v��̑����q�ɔ������ɗ\��
 *  get_inv_onhand                P   �Ȃ�  �񃍃b�g  I0  EBS�莝�݌�
 *  get_inv_in_inout_rpt_qty      P   �Ȃ�  �񃍃b�g  I1  ���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
 *  get_inv_in_in_rpt_qty         P   �Ȃ�  �񃍃b�g  I2  ���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
 *  get_inv_out_inout_rpt_qty     P   �Ȃ�  �񃍃b�g  I3  ���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
 *  get_inv_out_out_rpt_qty       P   �Ȃ�  �񃍃b�g  I4  ���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
 *  get_inv_ship_qty              P   �Ȃ�  �񃍃b�g  I5  ���і���݌ɐ�  �o��
 *  get_inv_provide_qty           P   �Ȃ�  �񃍃b�g  I6  ���і���݌ɐ�  �x��
 *  get_sup_inv_in_qty            P   �Ȃ�  �񃍃b�g  S1  ������  �ړ����ɗ\��
 *  get_sup_order_qty             P   �Ȃ�  �񃍃b�g  S2  ������  ��������\��
 *  get_sup_inv_out_qty           P   �Ȃ�  �񃍃b�g  S4  ������  ���ьv��ς̈ړ��o�Ɏ���
 *  get_dem_ship_qty              P   �Ȃ�  �񃍃b�g  D1  ���v��  ���і��v��̏o�׈˗�
 *  get_dem_provide_qty           P   �Ȃ�  �񃍃b�g  D2  ���v��  ���і��v��̎x���w��
 *  get_dem_inv_out_qty           P   �Ȃ�  �񃍃b�g  D3  ���v��  ���і��v��̈ړ��w��
 *  get_dem_inv_in_qty            P   �Ȃ�  �񃍃b�g  D4  ���v��  ���ьv��ς̈ړ����Ɏ���
 *  get_dem_produce_qty           P   �Ȃ�  �񃍃b�g  D5  ���v��  ���і��v��̐��Y�����\��
 *  get_can_enc_total_qty         F   NUM   �������\���Z�oAPI
 *  get_can_enc_in_time_qty       F   NUM   �L�����x�[�X�����\���Z�oAPI
 *  get_stock_qty                 F   NUM   �莝�݌ɐ��ʎZ�oAPI
 *  get_can_enc_qty               F   NUM   �����\���Z�oAPI
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 * 2007/12/26   1.0   oracle �ۉ�       �V�K�쐬
 *
 * 2008/02/04   ���o���̃e�[�u���́A�r���[���g�p���Ȃ����Ƃ���B
 * 2008/04/03   1.1   oracle �ۉ�       �����ύX�v��#32 get_stock_qty�C��
 * 2008/05/22   1.2   oracle �Ŗ�       �����ύX�v��#98�Ή�
 * 2008/06/19   1.3   oracle �g�c       �����e�X�g�s��Ή�(D6 �����ݒ�̕ϐ�(�i�ڃR�[�h)�ύX)
 * 2008/06/24   1.4   oracle �|�{       �����e�X�g�s��Ή�(I5,I6 �����ݒ�̕ϐ�(�i�ڃR�[�h)�ύX)
 * 2008/06/24   1.4   oracle �V��       �V�X�e���e�X�g�s��Ή�#75(D5)
 * 2008/07/16   1.5   oracle �k����     �ύX�v��#93�Ή�
 *
 *****************************************************************************************/
--
  -- ���b�g I0)EBS�莝�݌Ɏ擾�v���V�[�W��
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
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I1)���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
  PROCEDURE get_inv_lot_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I2)���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
  PROCEDURE get_inv_lot_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I3)���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
  PROCEDURE get_inv_lot_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I4)���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
  PROCEDURE get_inv_lot_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I5)���і���݌ɐ�  �o��
  PROCEDURE get_inv_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I6)���і���݌ɐ�  �x��
  PROCEDURE get_inv_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g S1)������  �ړ����ɗ\��
  PROCEDURE get_sup_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g S2)������  ��������\��
  PROCEDURE get_sup_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    iv_lot_no      IN VARCHAR2,             -- ���b�gNO
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g S3)������  ���Y���ɗ\��
  PROCEDURE get_sup_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g S4)������  ���ьv��ς̈ړ��o�Ɏ���
  PROCEDURE get_sup_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D1)���v��  ���і��v��̏o�׈˗�
  PROCEDURE get_dem_lot_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D2)���v��  ���і��v��̎x���w��
  PROCEDURE get_dem_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D3)���v��  ���і��v��̈ړ��w��
  PROCEDURE get_dem_lot_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D4)���v��  ���ьv��ς̈ړ����Ɏ���
  PROCEDURE get_dem_lot_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D5)���v��  ���і��v��̐��Y�����\��
  PROCEDURE get_dem_lot_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g D6)���v��  ���і��v��̑����q�ɔ������ɗ\��
  PROCEDURE get_dem_lot_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I0)EBS�莝�݌�
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
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I1)���і���݌ɐ�  �ړ����Ɂi���o�ɕ񍐗L�j
  PROCEDURE get_inv_in_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I2)���і���݌ɐ�  �ړ����Ɂi���ɕ񍐗L�j
  PROCEDURE get_inv_in_in_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I3)���і���݌ɐ�  �ړ��o�Ɂi���o�ɕ񍐗L�j
  PROCEDURE get_inv_out_inout_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I4)���і���݌ɐ�  �ړ��o�Ɂi�o�ɕ񍐗L�j
  PROCEDURE get_inv_out_out_rpt_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I5  ���і���݌ɐ�  �o��
  PROCEDURE get_inv_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I6)���і���݌ɐ�  �x��
  PROCEDURE get_inv_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  S1)������  �ړ����ɗ\��
  PROCEDURE get_sup_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  S2)������  ��������\��
  PROCEDURE get_sup_order_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  S4)������  ���ьv��ς̈ړ��o�Ɏ���
  PROCEDURE get_sup_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  D1)���v��  ���і��v��̏o�׈˗�
  PROCEDURE get_dem_ship_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  D2)���v��  ���і��v��̎x���w��
  PROCEDURE get_dem_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    iv_item_code   IN VARCHAR2,             -- �i�ڃR�[�h
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  D3)���v��  ���і��v��̈ړ��w��
  PROCEDURE get_dem_inv_out_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  D4)���v��  ���ьv��ς̈ړ����Ɏ���
  PROCEDURE get_dem_inv_in_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  D5)���v��  ���і��v��̐��Y�����\��
  PROCEDURE get_dem_produce_qty(
    iv_whse_code   IN VARCHAR2,             -- �ۊǑq�ɃR�[�h
    in_item_id     IN NUMBER,               -- �i��ID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--  �L�����x�[�X�����\���Z�oAPI�Ɠ���
--  -- �������\���Z�oAPI
--  FUNCTION get_can_enc_total_qty(
--    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
--    in_item_id          IN NUMBER,                    -- OPM�i��ID
--    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
--    RETURN NUMBER;                                    -- �������\��
----
  -- �L�����x�[�X�����\���Z�oAPI
  FUNCTION get_can_enc_in_time_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE    DEFAULT NULL)      -- �L����
    RETURN NUMBER;                                    -- �����\��
--
  -- �莝�݌ɐ��ʎZ�oAPI
  FUNCTION get_stock_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL)       -- ���b�gID
    RETURN NUMBER;                                    -- �莝�݌ɐ���
--
  -- �����\���Z�oAPI
  FUNCTION get_can_enc_qty(
    in_whse_id          IN NUMBER,                    -- OPM�ۊǑq��ID
    in_item_id          IN NUMBER,                    -- OPM�i��ID
    in_lot_id           IN NUMBER DEFAULT NULL,       -- ���b�gID
    in_active_date      IN DATE)                      -- �L����
    RETURN NUMBER;                                    -- �����\��
--
END xxcmn_common2_pkg;
/