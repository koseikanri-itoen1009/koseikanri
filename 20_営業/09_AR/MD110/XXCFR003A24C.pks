CREATE OR REPLACE PACKAGE XXCFR003A24C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCFR003A24C(spec)
 * Description      : �������א�����ڋq���f
 * MD.050           : MD050_CFR_003_A24_�������א�����ڋq���f
 * MD.070           : MD050_CFR_003_A24_�������א�����ڋq���f
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
 *  2023/10/20    1.00  SCSK �Ԓn �w     ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date          IN      VARCHAR2,         -- ����
    iv_bill_acct_code       IN      VARCHAR2         -- ������ڋq�R�[�h
  );
END XXCFR003A24C;--(�ύX)
/
