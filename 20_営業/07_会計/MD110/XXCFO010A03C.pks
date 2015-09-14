CREATE OR REPLACE PACKAGE XXCFO010A03C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 * 
 * Package Name    : XXCFO010A03C
 * Description     : GLIF�O���[�vID�X�V
 * MD.050          : MD050_CFO_010_A03_GLIF�O���[�vID�X�V
 * MD.070          : MD050_CFO_010_A03_GLIF�O���[�vID�X�V
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2015-08-07    1.0  SCSK ���H���O  ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT   VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT   VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_je_source_name   IN    VARCHAR2,      -- �d��\�[�X��
    iv_group_id         IN    VARCHAR2       -- �O���[�vID
  );
END XXCFO010A03C;
/
