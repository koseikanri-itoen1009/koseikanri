CREATE OR REPLACE PACKAGE XXCFO008A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO008A01C
 * Description     : �ڋq�}�X�^VD�ޑK��z�̍X�V
 * MD.050          : MD050_CFO_008_A01_�ڋq�}�X�^VD�ޑK��z�̍X�V
 * MD.070          : MD050_CFO_008_A01_�ڋq�}�X�^VD�ޑK��z�̍X�V
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
 *  2008-11-07    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
--
--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf              OUT     VARCHAR2,         --    �G���[���b�Z�[�W #�Œ�#
    retcode             OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_operation_date   IN      VARCHAR2          --    �^�p��
  );
END XXCFO008A01C;
/
