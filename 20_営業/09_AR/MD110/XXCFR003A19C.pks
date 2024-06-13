create or replace PACKAGE XXCFR003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A19C(spec)
 * Description      : �W���������ō�(�X�ܕʓ���)
 * MD.050           : MD050_CFR_003_A19_�W���������Ŕ�(�X�ܕʓ���)
 * MD.070           : MD050_CFR_003_A19_�W���������Ŕ�(�X�ܕʓ���)
 * Version          : 1.51
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
 *  2010/12/10    1.30 SCS �Γn ���a    ��Q�[�uE_�{�ғ�_05401�v�Ή�
 *  2013/11/25    1.40 SCSK �ː� �a�K   ��Q�[�uE_�{�ғ�_11330�v�Ή�
 *  2014/03/27    1.50 SCSK �R�� �đ�   ��Q�[ [E_�{�ғ�_11617] �Ή�
 *  2023/11/20    1.51 SCSK ��R �m��   ��Q�[�uE_�{�ғ�_19496�v�O���[�v��Г����Ή�
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
-- Add 2010.12.10 Ver1.30 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- ���������s�T�C�N��
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.11.25 Ver1.40 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- �ŕʓ���o�͋敪
-- Add 2013.11.25 Ver1.40 End
-- Add 2014.03.27 Ver1.50 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- �������o�͌`��
-- Add 2014.03.27 Ver1.50 End
-- Ver1.51 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ��ЃR�[�h
-- Ver1.51 ADD END
  );
END XXCFR003A19C;
/
