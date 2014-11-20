CREATE OR REPLACE PACKAGE XXCFR003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A05C(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : MD050_FR_003_A05_�������z�ꗗ�\�o��
 * MD.070           : MD050_FR_003_A05_�������z�ꗗ�\�o��
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
 *  2008/12/17    1.00 SCS ��� �b      ����쐬
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_target_date    IN     VARCHAR2,         --   ����
    iv_bill_cust_code IN     VARCHAR2          --   ������ڋq�R�[�h
  );
END XXCFR003A05C;
/
