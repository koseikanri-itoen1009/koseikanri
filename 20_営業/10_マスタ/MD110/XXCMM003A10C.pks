CREATE OR REPLACE PACKAGE xxcmm003a10c
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : xxcmm003a10c(spec)
 * Description     : ������q�`�F�b�N���X�g
 * MD.050          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * MD.070          : MD050_CMM_003_A10_������q�`�F�b�N���X�g
 * Version         : 1.2
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
 *  2017-01-17    1.2  S.Niki           ��QE_�{�ғ�_13983�Ή�
 *
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                     OUT NOCOPY VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT NOCOPY VARCHAR2,         --    �G���[�R�[�h        --# �Œ� #
    iv_cust_status             IN         VARCHAR2,         --    �ڋq�X�e�[�^�X
-- Ver1.2 modify start
--    iv_sale_base_code          IN         VARCHAR2          --    ���_�R�[�h
    iv_sale_base_code          IN         VARCHAR2,         --    ���_�R�[�h
    iv_vd_output_div           IN         VARCHAR2          --    �o�͋敪
-- Ver1.2 modify end
  );
END xxcmm003a10c;
/
