CREATE OR REPLACE PACKAGE XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(spec)
 * Description      : �W���������ō�
 * MD.050           : MD050_CFR_003_A16_�W���������Ŕ�
 * MD.070           : MD050_CFR_003_A16_�W���������Ŕ�
 * Version          : 1.10
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
 *  2010/12/10    1.7  SCS �Γn ���a    [E_�{�ғ�_05401] �p�����[�^�u���������s�T�C�N���v�̒ǉ�
 *  2013/11/25    1.8  SCSK �ː� �a�K   [E_�{�ғ�_11330] �ŕʓ���o�͑Ή�
 *  2014/03/27    1.9  SCSK �R�� �đ�   [E_�{�ғ�_11617] �������o�͌`�����Ǝ҈ϑ��̌ڋq�Ή�
 *  2023/11/20    1.10 SCSK ��R �m��   [E_�{�ғ�_19496] �O���[�v��Г����Ή�
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
-- Add 2010.12.10 Ver1.7 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.7 End
-- Add 2013.11.25 Ver1.8 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- �ŕʓ���o�͋敪
-- Add 2013.11.25 Ver1.8 End
-- Add 2014.03.27 Ver1.9 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- �������o�͌`��
-- Add 2014.03.27 Ver1.9 End
-- Ver1.10 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ��ЃR�[�h
-- Ver1.10 ADD END
  );
END XXCFR003A16C;
/
