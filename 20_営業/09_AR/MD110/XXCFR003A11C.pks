create or replace PACKAGE XXCFR003A11C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A11C
 * Description     : �ėp���i�i�P�����W�v�j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A06_�ėp�X�ʐ����f�[�^�쐬
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- -------------- -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------- -------------------------------------
 *  2009-01-19    1.0  SCS �g�� ���i   ����쐬
 ************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ����
    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
  );
END  XXCFR003A11C;
/
