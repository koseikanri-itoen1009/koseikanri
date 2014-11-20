CREATE OR REPLACE PACKAGE xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_�ڋq_���ʊ֐�
 * Version                : 1.3
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check   F          �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
 *  update_hz_party            P          �p�[�e�B�}�X�^�X�V�p�֐�
 *  cust_name_kana_check       F          �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *  cust_site_check            F          �ڋq���ݒn�S�p���p�`�F�b�N
 *  cust_required_check        P          �ڋq�K�{���ڃ`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009/01/30    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009/02/26    1.1  Yutaka.Kuboshima �p�[�e�B�}�X�^�X�V�֐��ǉ�
 *  2009/03/26    1.2  Yutaka.Kuboshima �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *                                      �ڋq���ݒn�S�p���p�`�F�b�N�ǉ�
 *  2009/05/22    1.3  Yutaka.Kuboshima �ڋq�K�{���ڃ`�F�b�N�ǉ�
 *  2009/06/19    1.4  Yutaka.Kuboshima ��QT1_1500�Ή�
 *****************************************************************************************/
 --
  --�ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
  FUNCTION cust_status_update_allow(iv_cust_class        IN VARCHAR2  -- �ڋq�敪
                                   ,iv_cust_status       IN VARCHAR2  -- �ڋq�X�e�[�^�X�i�ύX�O�j
                                   ,iv_cust_will_status  IN VARCHAR2) -- �ڋq�X�e�[�^�X�i�ύX��j
    RETURN VARCHAR2;
  --�p�[�e�B�}�X�^�X�V�p�֐�
  PROCEDURE update_hz_party(in_party_id    IN  NUMBER,    -- �p�[�e�BID
                            iv_cust_status IN  VARCHAR2,  -- �ڋq�X�e�[�^�X
                            ov_errbuf      OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ov_retcode     OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
                            ov_errmsg      OUT VARCHAR2); -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  --�ڋq���́E�ڋq���̃J�i�`�F�b�N
  FUNCTION cust_name_kana_check(iv_cust_name_mir           IN VARCHAR2   -- �ڋq����
                               ,iv_cust_name_phonetic_mir  IN VARCHAR2)  -- �ڋq���̃J�i
    RETURN VARCHAR2;
  --�ڋq���ݒn�S�p���p�`�F�b�N
  FUNCTION cust_site_check(iv_cust_site  IN VARCHAR2)   -- �ڋq���ݒn������
    RETURN VARCHAR2;
-- 2009/05/22 Ver1.3 add start by Yutaka.Kuboshima
  --�ڋq�K�{���ڃ`�F�b�N
  PROCEDURE cust_required_check(
-- 2009/06/19 Ver1.4 modify start by Yutaka.Kuboshima
--                                iv_customer_number  IN  VARCHAR2,  -- �ڋq�ԍ�
                                in_customer_id      IN  NUMBER,    -- �ڋqID
-- 2009/06/19 Ver1.4 modify end by Yutaka.Kuboshima
                                iv_cust_status      IN  VARCHAR2,  -- �ڋq�X�e�[�^�X�i�ύX�O�j
                                iv_cust_will_status IN  VARCHAR2,  -- �ڋq�X�e�[�^�X�i�ύX��j
                                ov_retcode          OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
                                ov_errmsg           OUT VARCHAR2); -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- 2009/05/22 Ver1.3 add end by Yutaka.Kuboshima
END xxcmm_003common_pkg;
/
