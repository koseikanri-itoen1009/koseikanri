CREATE OR REPLACE PACKAGE XXCFR001A04C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR001A04C
 * Description     : AR����C���|�[�g�`�F�b�N
 * MD.050          : MD050_CFR_001_A04_AR����C���|�[�g�`�F�b�N
 * MD.070          : MD050_CFR_001_A04_AR����C���|�[�g�`�F�b�N
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
 *  2009-10-01    1.0  SCS ����      ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCFR001A04C;
/
