create or replace PACKAGE XXCFR003A06C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A06C
 * Description     : �ėp�X�ʐ����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * Version         : 1.1
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
 *  2008-12-19    1.0  SCS �g�� ���i  ����쐬
 *  2009-09-16    1.1  SCS ���� �K��  AR�ۑ�Ή�
************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009/09/16 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
    iv_cust_class    IN  VARCHAR2     -- �ڋq�敪
-- Modify 2009/09/16 Ver1.1 End   ----------------------------------------------
  );
END  XXCFR003A06C;
/
