CREATE OR REPLACE PACKAGE XXCFO014A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO014A01C
 * Description     : ���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
 * MD.050          : MD050_CFO_014_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
 * MD.070          : MD050_CFO_014_A01_���n�V�X�e���ւ̃f�[�^�A�g�i����ʑ��v�\�Z�j
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
 *  2008-11-20    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCFO014A01C;
/
