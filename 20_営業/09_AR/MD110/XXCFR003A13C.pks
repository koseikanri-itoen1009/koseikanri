CREATE OR REPLACE PACKAGE XXCFR003A13C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A13C
 * Description     : �ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A13_�ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A13_�ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
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
 *  2008-12-17    1.0  SCS �_�� ���� ����쐬
 *  2009-10-05    1.1  SCS �A���^���l ���ʉۑ�IE535�Ή�
 ************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009.10.05 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
    iv_cust_class    IN  VARCHAR2     -- �ڋq�敪
-- Modify 2009.10.05 Ver1.1 End
  );
END  XXCFR003A13C;
/
