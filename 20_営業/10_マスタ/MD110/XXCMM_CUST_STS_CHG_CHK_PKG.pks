CREATE OR REPLACE PACKAGE XXCMM_CUST_STS_CHG_CHK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM_CUST_STS_CHK_PKG(spec)
 * Description      : �ڋq�X�e�[�^�X���u���~�v�ɕύX����ہA�X�e�[�^�X�ύX���\��������s���܂��B
 * MD.050           : MD050_CMM_003_A11_�ڋq�X�e�[�^�X�ύX�`�F�b�N
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-08    1.0   Takuya.Kaihara   main�V�K�쐬
 *
 *****************************************************************************************/
--
  --���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    in_cust_id      IN  NUMBER,       --   �ڋqID
    iv_gtai_syo     IN  VARCHAR2,     --   �Ƒԕ��ށi�����ށj
    ov_check_status OUT VARCHAR2,     --   �`�F�b�N�X�e�[�^�X
    ov_err_message  OUT VARCHAR2      --   �G���[���b�Z�[�W
  );
END XXCMM_CUST_STS_CHG_CHK_PKG;
/
