CREATE OR REPLACE PACKAGE XXCFO010A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO010A01C
 * Description     : ���n�V�X�e���ւ̃f�[�^�A�g�i����Ȗږ��ׁj
 * MD.050          : MD050_CFO_010_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����Ȗږ��ׁj
 * MD.070          : MD050_CFO_010_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����Ȗږ��ׁj
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
 *  2008-11-18    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_period_name  IN     VARCHAR2          --   ��v����
  );
END XXCFO010A01C;
/
