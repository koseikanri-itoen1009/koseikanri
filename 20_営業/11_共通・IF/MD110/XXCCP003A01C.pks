CREATE OR REPLACE PACKAGE APPS.XXCCP003A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP003A01C(spec)
 * Description      : �≮�����f�[�^�o��
 * MD.070           : �≮�����f�[�^�o�� (MD070_IPO_CCP_003_A01)
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
 *  2015/09/08     1.0  S.Yamashita      [E_�{�ғ�_11083]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_payment_date_from  IN     VARCHAR2      --   1.�x���\���FROM
   ,iv_payment_date_to    IN     VARCHAR2      --   2.�x���\���TO
  );
END XXCCP003A01C;
/
