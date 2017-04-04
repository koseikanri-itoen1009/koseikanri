CREATE OR REPLACE PACKAGE APPS.XXCMM003A43C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM003A43C(spec)
 * Description      : �X�܏��}�X�^�A�g�ieSM�j
 * MD.050           : �X�܏��}�X�^�A�g�ieSM�j MD050_CMM_003_A43
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
 *  2017/02/07    1.0   S.Yamashita      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode         OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_update_from  IN     VARCHAR2         --   1.�ŏI�X�V���i�J�n�j
   ,iv_update_to    IN     VARCHAR2         --   2.�ŏI�X�V���i�I���j
  );
END XXCMM003A43C;
/
