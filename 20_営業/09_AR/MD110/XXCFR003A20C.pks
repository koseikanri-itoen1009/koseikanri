CREATE OR REPLACE PACKAGE APPS.XXCFR003A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFR003A20C(spec)
 * Description      : �X�ܕʖ��׏o��
 * MD.050           : MD050_CFR_003_A20_�X�ܕʖ��׏o��
 * MD.070           : MD050_CFR_003_A20_�X�ܕʖ��׏o��
 * Version          : 1.0
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
  );
END XXCFR003A20C;
/
