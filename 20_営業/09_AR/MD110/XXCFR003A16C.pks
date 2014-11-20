CREATE OR REPLACE PACKAGE XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(spec)
 * Description      : �W���������ō�
 * MD.050           : MD050_CFR_003_A16_�W���������Ŕ�
 * MD.070           : MD050_CFR_003_A16_�W���������Ŕ�
 * Version          : 1.3
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
 *  2009/09/25    1.3  SCS �A�� �^���l  [���ʉۑ�IE535] ���������Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
-- Modify 2009.09.25 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2          -- ���|�R�[�h�P(������)
    iv_custome_cd          IN      VARCHAR2,         -- �ڋq�ԍ�(�ڋq)
    iv_invoice_cd          IN      VARCHAR2,         -- �ڋq�ԍ�(�����p)
    iv_payment_cd          IN      VARCHAR2          -- �ڋq�ԍ�(���|�Ǘ���)
-- Modify 2009.09.25 Ver1.3 End
  );
END XXCFR003A16C;
/
