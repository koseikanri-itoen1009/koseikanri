CREATE OR REPLACE PACKAGE XXCFR003A09C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A09C
 * Description     : �ėp���i�i�P�i���j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A09_�ėp���i�i�P�i���j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A09_�ėp���i�i�P�i���j�����f�[�^�쐬
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
 *  2008-12-10    1.0   SCS ���� �^�I ����쐬
 *  2009-10-02    1.1   SCS ���� �L�� AR�d�l�ύXIE535�Ή�
 ************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009/10/02 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
    iv_cust_class    IN  VARCHAR2     -- �ڋq�敪
-- Modify 2009/10/02 Ver1.1 End ----------------------------------------------
  );
END  XXCFR003A09C;
/
