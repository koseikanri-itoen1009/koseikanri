CREATE OR REPLACE PACKAGE XXCFR003A22C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFR003A22C(spec)
 * Description      : ����VD�������o�́i�P���ʁj
 * MD.050           : MD050_CFR_003_A22_����VD�������o�́i�P���ʁj
 * MD.070           : MD050_CFR_003_A22_����VD�������o�́i�P���ʁj
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
 *  2022/01/06    1.0   SCSK �y�] �L��   �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                OUT     VARCHAR2         -- �G���[�R�[�h     #�Œ�#
   ,iv_target_date         IN      VARCHAR2         -- ����
   ,iv_custome_cd          IN      VARCHAR2         -- �ڋq�ԍ�(�ڋq)
   ,iv_payment_cd          IN      VARCHAR2         -- �ڋq�ԍ�(���|�Ǘ���)
   ,iv_bill_pub_cycle      IN      VARCHAR2         -- ���������s�T�C�N��
   ,iv_tax_output_type     IN      VARCHAR2         -- �ŕʓ���o�͋敪
   ,iv_bill_invoice_type   IN      VARCHAR2         -- �������o�͌`��
  );
END XXCFR003A22C;
/
