CREATE OR REPLACE PACKAGE XXCFR003A12C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A12C
 * Description     : �ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
 * MD.050          : MD050_CFR_003_A12_�ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
 * MD.070          : MD050_CFR_003_A12_�ėp���i�i�X�P�����W�v�j�����f�[�^�쐬
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
 *  2009-01-30    1.0  SCS ��� �b   ����쐬
 *  2009-10-13    1.1  SCS ���� �K�� IE535 �ڋq�敪�ǉ��Ή�
 ************************************************************************/

--===============================================================
-- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,    -- �G���[���b�Z�[�W
    retcode          OUT VARCHAR2,    -- �G���[�R�[�h
    iv_target_date   IN  VARCHAR2,    -- ����
-- Modify 2009/10/13 Ver1.4 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2     -- ���|�R�[�h�P(������)
    iv_cust_code     IN  VARCHAR2,    -- �ڋq�R�[�h
    iv_cust_class    IN  VARCHAR2     -- �ڋq�敪
-- Modify 2009/10/13 Ver1.4 End   ----------------------------------------------
  );
END  XXCFR003A12C;
/
