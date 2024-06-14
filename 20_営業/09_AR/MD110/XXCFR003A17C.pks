CREATE OR REPLACE PACKAGE XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(spec)
 * Description      : �C�Z�g�[�������f�[�^�쐬
 * MD.050           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * MD.070           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * Version          : 1.2
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
 *  2009-02-23    1.00  SCS ���� �K��     �V�K�쐬
 *  2009-09-29    1.10  SCS ���� �q��     ���ʉۑ�uIE535�v�Ή�
 *  2024-03-06    1.2   SCSK ��R �m��    E_�{�ғ�_19496 �O���[�v��Г����Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
-- Modify 2009-09-29 Ver1.10 Start
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2          -- ���|�Ǘ���ڋq
-- Modify 2009-09-29 Ver1.10 End
-- Ver1.2 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ��ЃR�[�h
-- Ver1.2 ADD END
  );
END XXCFR003A17C;
/
