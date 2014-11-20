CREATE OR REPLACE PACKAGE XXCFR003A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A04C(spec)
 * Description      : EDI�������f�[�^�쐬
 * MD.050           : MD050_CFR_003_A04_EDI�������f�[�^�쐬
 * MD.070           : MD050_CFR_003_A04_EDI�������f�[�^�쐬
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
 *  2009/01/21    1.00 SCS ��� �b      ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT    VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT    VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date         IN     VARCHAR2,         -- ����
    iv_ar_code1            IN     VARCHAR2,         -- ���|�R�[�h�P(������)
    iv_start_mode          IN     VARCHAR2          -- �N���敪
  );
END XXCFR003A04C;
/
