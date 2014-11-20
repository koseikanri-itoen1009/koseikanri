CREATE OR REPLACE PACKAGE XXCFR003A14C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A14C
 * Description     : �ėp�����N������
 * MD.050          : MD050_CFR_003_A14_�ėp�����N������
 * MD.070          : MD050_CFR_003_A14_�ėp�����N������
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
 *  2008-11-04    1.0  SCS ���� �q�� ����쐬
 ************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2,    -- ���|�R�[�h�P(������)
    iv_exec_003A06C  IN  VARCHAR2,    -- �ėp�X�ʐ���
    iv_exec_003A07C  IN  VARCHAR2,    -- �ėp�`�[�ʐ���
    iv_exec_003A08C  IN  VARCHAR2,    -- �ėp���i�i�S���ׁj
    iv_exec_003A09C  IN  VARCHAR2,    -- �ėp���i�i�P�i���W�v�j
    iv_exec_003A10C  IN  VARCHAR2,    -- �ėp���i�i�X�P�i���W�v�j
    iv_exec_003A11C  IN  VARCHAR2,    -- �ėp���i�i�P�����W�v�j
    iv_exec_003A12C  IN  VARCHAR2,    -- �ėp���i�i�X�P�����W�v�j
    iv_exec_003A13C  IN  VARCHAR2     -- �ėp�i�X�R�������W�v�j
  );
END  XXCFR003A14C;
/
