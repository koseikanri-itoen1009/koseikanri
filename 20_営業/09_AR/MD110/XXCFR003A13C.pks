CREATE OR REPLACE PACKAGE XXCFR003A13C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A13C
 * Description     : �ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A13_�ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A13_�ėp���i�i�X�R�������W�v�j�����f�[�^�쐬
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
 *  2008-12-17    1.0  SCS �_�� ���� ����쐬
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
END  XXCFR003A13C;
/
