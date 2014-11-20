CREATE OR REPLACE PACKAGE xxcmn_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxcmn_common2_pkg(SPEC)
 * Description            : ���ʊ֐�2(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_�����\���Z�o�i�⑫�����j.doc
 * Version                : 1.18
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
 *  get_inv_lot_in_inout_cor_qty  P   �Ȃ�  ���b�g    I7  ���і���݌ɐ�  �ړ����ɒ����i���o�ɕ񍐗L�j
 *  get_inv_lot_out_inout_cor_qty P   �Ȃ�  ���b�g    I8  ���і���݌ɐ�  �ړ��o�ɒ����i���o�ɕ񍐗L�j
 *  get_sup_lot_inv_in_qty        P   �Ȃ�  ���b�g    S1  ������  �ړ����ɗ\��
 *  get_sup_lot_order_qty         P   �Ȃ�  ���b�g    S2  ������  ��������\��
 *  get_sup_lot_produce_qty       P   �Ȃ�  ���b�g    S3  ������  ���Y���ɗ\��
 *  get_sup_lot_inv_out_qty       P   �Ȃ�  ���b�g    S4  ������  ���ьv��ς̈ړ��o�Ɏ���
 *  get_dem_lot_ship_qty          p   �Ȃ�  ���b�g    D1  ���v��  ���і��v��̏o�׈˗��iID�x�[�X�j
 *  get_dem_lot_ship_qty2         p   �Ȃ�  ���b�g    D1  ���v��  ���і��v��̏o�׈˗��iCODE�x�[�X�j
 *  get_dem_lot_provide_qty       p   �Ȃ�  ���b�g    D2  ���v��  ���і��v��̎x���w���iID�x�[�X�j
 *  get_dem_lot_provide_qty2      p   �Ȃ�  ���b�g    D2  ���v��  ���і��v��̎x���w���iCODE�x�[�X�j
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
 *  get_inv_in_inout_cor_qty      P   �Ȃ�  �񃍃b�g  I7  ���і���݌ɐ�  �ړ����ɒ����i���o�ɕ񍐗L�j
 *  get_inv_out_inout_cor_qty     P   �Ȃ�  �񃍃b�g  I8  ���і���݌ɐ�  �ړ��o�ɒ����i���o�ɕ񍐗L�j
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
 *  2008/09/11   1.9   oracle �Ŗ�     PT 6-1_28 �w�E73 �Ή�
 *  2008/07/18   1.10  oracle �k����   TE080_BPO540�w�E5�Ή�
 *  2008/09/16   1.11  oracle �Ŗ�     TE080_BPO540�w�E5�C��
 *  2008/09/17   1.12  oracle �Ŗ�     PT 6-1_28 �w�E73 �ǉ��C��
 *  2008/11/19   1.13  oracle �ɓ�     �����e�X�g�w�E681�C��
 *  2008/12/02   1.14  oracle ��r     �{�ԏ�Q#251�Ή��i�����ǉ�) 
 *  2008/12/15   1.15  oracle �ɓ�     �{�ԏ�Q#645�Ή� D4,S4 �\����łȂ����ѓ��Ŏ擾����B
 *  2008/12/18   1.16  oracle �ɓ�     �{�ԏ�Q#648�Ή� I5,I6 �����O���� - ���ѐ��ʂ�Ԃ��B
 *  2008/12/24   1.17  oracle �R�{     �{�ԏ�Q#836�Ή� S3    ���Y���ɗ\�蒊�o�����ǉ�
 *  2009/03/31   1.18  �쑺            �{�ԏ�Q#1346�Ή�
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
  -- ���b�g I7)���і���݌ɐ�  �ړ����ɒ����i���o�ɕ񍐗L�j
  PROCEDURE get_inv_lot_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_before_qty  OUT NOCOPY NUMBER,       -- �����O����
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���b�g I8)���і���݌ɐ�  �ړ��o�ɒ����i���o�ɕ񍐗L�j
  PROCEDURE get_inv_lot_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    in_lot_id      IN NUMBER,               -- ���b�gID
    on_before_qty  OUT NOCOPY NUMBER,       -- �����O����
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
-- 2008/09/10 V1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- �i��ID
    in_item_code   IN VARCHAR2,             -- �i��
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- �i��ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2008/09/10 v1.8 ADD START
  -- ���b�g D1)���v��  ���і��v��̏o�׈˗��iCODE�x�[�X�j
  PROCEDURE get_dem_lot_ship_qty2(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_code   IN VARCHAR2,             -- �i��
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2008/09/10 v1.8 ADD END
  -- ���b�g D2)���v��  ���і��v��̎x���w��
  PROCEDURE get_dem_lot_provide_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
-- 2008/09/10 V1.8 UPDATE START
/*
-- 2008/09/09 v1.7 UPDATE START
--    in_item_id     IN NUMBER,               -- �i��ID
    in_item_code   IN VARCHAR2,             -- �i��
-- 2008/09/09 v1.7 UPDATE END
*/
    in_item_id     IN NUMBER,               -- �i��ID
-- 2008/09/10 v1.8 UPDATE END
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2008/09/10 v1.8 ADD START
  -- ���b�g D2)���v��  ���і��v��̎x���w���iCODE�x�[�X�j
  PROCEDURE get_dem_lot_provide_qty2(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_code   IN VARCHAR2,             -- �i��
    in_lot_id      IN NUMBER,               -- ���b�gID
    id_eff_date    IN DATE,                 -- �L�����t
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2008/09/10 v1.8 ADD END
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
  -- �񃍃b�g  I7)���і���݌ɐ�  �ړ����ɒ����i���o�ɕ񍐗L�j
  PROCEDURE get_inv_in_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_before_qty  OUT NOCOPY NUMBER,       -- �����O����
    on_qty         OUT NOCOPY NUMBER,       -- ����
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �񃍃b�g  I8)���і���݌ɐ�  �ړ��o�ɒ����i���o�ɕ񍐗L�j
  PROCEDURE get_inv_out_inout_cor_qty(
    in_whse_id     IN NUMBER,               -- �ۊǑq��ID
    in_item_id     IN NUMBER,               -- �i��ID
    on_before_qty  OUT NOCOPY NUMBER,       -- �����O����
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
