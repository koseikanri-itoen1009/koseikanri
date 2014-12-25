CREATE OR REPLACE PACKAGE XXCFR003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A05C(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : MD050_FR_003_A05_�������z�ꗗ�\�o��
 * MD.070           : MD050_FR_003_A05_�������z�ꗗ�\�o��
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
 *  2008/12/17    1.00 SCS ��� �b      ����쐬
 *  2014/10/25    1.1  SCSK �|��        E_�{�ғ�_12310�Ή�
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
-- ADD Ver1.1 Start
    iv_output_kbn     IN     VARCHAR2,         --   �o�͊
-- ADD Ver1.1 End
    iv_target_date    IN     VARCHAR2,         --   ����
    iv_bill_cust_code IN     VARCHAR2          --   ������ڋq�R�[�h
  );
END XXCFR003A05C;
/
