CREATE OR REPLACE PACKAGE XXCFO016A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A01C(spec)
 * Description     : �W���������o�͏���
 * MD.050          : MD050_CFO_016_A01_�W���������o�͏���
 * MD.070          : MD050_CFO_016_A01_�W���������o�͏���
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
 *  2008-11-20    1.0  SCS �R�� �D   ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                     OUT NOCOPY VARCHAR2,         --    �G���[���b�Z�[�W #�Œ�#
    retcode                    OUT NOCOPY VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
    iv_po_dept_code            IN         VARCHAR2,         --    �����쐬����
    iv_po_agent_code           IN         VARCHAR2,         --    �����쐬��
    iv_vender_code             IN         VARCHAR2,         --    �d����
    iv_po_num                  IN         VARCHAR2,         --    �����ԍ�
    iv_po_creation_date_from   IN         VARCHAR2,         --    �����쐬��From
    iv_po_creation_date_to     IN         VARCHAR2,         --    �����쐬��To
    iv_po_approved_date_from   IN         VARCHAR2,         --    �������F��From
    iv_po_approved_date_to     IN         VARCHAR2,         --    �������F��To
    iv_reissue_flag            IN         VARCHAR2          --    �Ĕ��s�t���O
  );
END XXCFO016A01C;
/
