CREATE OR REPLACE PACKAGE xxcmm003a10c
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : xxcmm003a10c(spec)
 * Description     : ������q�`�F�b�N���X�g
 * MD.050          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * MD.070          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 * main              P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- -------------- ------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------- ------------------------------------
 *  2009-02-04    1.0  SCS K.Shirasuna  ����쐬
 *  2009-03-09    1.1  Yutaka.Kuboshima �t�@�C���o�͐�̃v���t�@�C���̍폜
 *                                      �����}�X�^�R�[�h�擾�̒��o������ύX
 *
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                     OUT NOCOPY VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT NOCOPY VARCHAR2,         --    �G���[�R�[�h        --# �Œ� #
    iv_cust_status             IN         VARCHAR2,         --    �ڋq�X�e�[�^�X
    iv_sale_base_code          IN         VARCHAR2          --    ���_�R�[�h
  );
END xxcmm003a10c;
/
