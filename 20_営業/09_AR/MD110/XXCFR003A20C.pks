CREATE OR REPLACE PACKAGE APPS.XXCFR003A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFR003A20C(spec)
 * Description      : �X�ܕʖ��׏o��
 * MD.050           : MD050_CFR_003_A20_�X�ܕʖ��׏o��
 * MD.070           : MD050_CFR_003_A20_�X�ܕʖ��׏o��
 * Version          : 1.1
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
 *  2015/07/23    1.0   SCSK ���H ���O   �V�K�쐬
 *  2023/11/20    1.1   SCSK ��R �m��   [E_�{�ғ�_19496] �O���[�v��Г����Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                OUT     VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_report_type         IN      VARCHAR2          -- ���[�敪
   ,iv_bill_type           IN      VARCHAR2          -- �������^�C�v
   ,in_org_request_id      IN      NUMBER            -- ���s���v��ID
   ,in_target_cnt          IN      NUMBER            -- �Ώی���
-- Ver1.1 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ��ЃR�[�h
-- Ver1.1 ADD END
  );
END XXCFR003A20C;
/
