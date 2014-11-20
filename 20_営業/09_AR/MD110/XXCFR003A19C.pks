create or replace PACKAGE XXCFR003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A19C(spec)
 * Description      : �W���������ō�(�X�ܕʓ���)
 * MD.050           : MD050_CFR_003_A19_�W���������Ŕ�(�X�ܕʓ���)
 * MD.070           : MD050_CFR_003_A19_�W���������Ŕ�(�X�ܕʓ���)
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
 *  2009/09/17    1.00 SCS ���� �q��  ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2          -- ���|�Ǘ���ڋq
  );
END XXCFR003A19C;
