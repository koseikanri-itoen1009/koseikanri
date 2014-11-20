CREATE OR REPLACE PACKAGE XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(spec)
 * Description      : �W���������ō�
 * MD.050           : MD050_CFR_003_A16_�W���������Ŕ�
 * MD.070           : MD050_CFR_003_A16_�W���������Ŕ�
 * Version          : 1.00
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.00 SCS ��� �b      ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_ar_code1            IN      VARCHAR2          -- ���|�R�[�h�P(������)
  );
END XXCFR003A16C;
/
