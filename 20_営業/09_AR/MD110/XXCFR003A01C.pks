CREATE OR REPLACE PACKAGE XXCFR003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A01C(spec)
 * Description      : �����f�[�^�폜
 * MD.050           : MD050_CFR_003_A01_�����f�[�^�폜
 * MD.070           : MD050_CFR_003_A01_�����f�[�^�폜
 * Version          : 1.01
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
 *  2008/10/24    1.00 SCS ��� �b      ����쐬
 *  2013/05/13    1.01 SCSK ���� �O��   E_�{�ғ�_09964�đΉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
-- Modify 2013.05.13 Ver1.01 start
--    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_del_target_type  IN      VARCHAR2   --   �폜�Ώ۔��f�敪
-- Modify 2013.05.13 Ver1.01 end
  );
END XXCFR003A01C;
/
