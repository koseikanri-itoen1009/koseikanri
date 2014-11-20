CREATE OR REPLACE PACKAGE xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(spec)
 * Description            :
 * MD.110                 : MD110_CMM_�ڋq_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check  F           �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
 *  update_hz_party           P           �p�[�e�B�}�X�^�X�V�֐�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009-01-30    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009-02-26    1.1  Yutaka.Kuboshima �p�[�e�B�}�X�^�X�V�֐��ǉ�
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
END xxcmm_003common_pkg;
/
