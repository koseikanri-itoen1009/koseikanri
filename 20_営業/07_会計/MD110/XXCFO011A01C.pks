CREATE OR REPLACE PACKAGE XXCFO011A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO011A01C
 * Description     : �l���V�X�e���f�[�^�A�g
 * MD.050          : MD050_CFO_011_A01_�l���V�X�e���f�[�^�A�g
 * MD.070          : MD050_CFO_011_A01_�l���V�X�e���f�[�^�A�g
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
 *  2008-11-25    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_target_file_name IN     VARCHAR2          --   �A�g�t�@�C����
  );
END XXCFO011A01C;
/
