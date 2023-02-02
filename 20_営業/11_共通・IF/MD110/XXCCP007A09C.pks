CREATE OR REPLACE PACKAGE APPS.XXCCP007A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCCP007A09C(spec)
 * Description      : GL�����F�f�[�^���o
 * MD.070           : GL�����F�f�[�^���o (MD070_IPO_CCP_007_A09)
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
 *  2023/01/20    1.0   R.Oikawa      [E_�{�ғ�_19039]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_gl_date_from    IN     VARCHAR2      --   �v����i���j
   ,iv_gl_date_to      IN     VARCHAR2      --   �v����i���j
  );
END XXCCP007A09C;
/
