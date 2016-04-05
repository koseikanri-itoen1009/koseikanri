CREATE OR REPLACE PACKAGE APPS.XXCCP003A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP003A02C(spec)
 * Description      : �≮���m��f�[�^�o��
 * MD.070           : �≮���m��f�[�^�o�� (MD070_IPO_CCP_003_A02)
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
 *  2016/03/16    1.0   H.Okada          [E_�{�ғ�_11084]�V�K�쐬
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
END XXCCP003A02C;
/
