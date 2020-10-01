CREATE OR REPLACE PACKAGE APPS.XXCOK024A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A20C (spec)
 * Description      : �T���f�[�^�A�b�v���[�h
 * MD.050           : �T���f�[�^�A�b�v���[�h MD050_COK_024_A20
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
 *  2020/02/04    1.0   Y.Nakajima       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_file_id                      IN     VARCHAR2          -- 1.�t�@�C��ID(�K�{)
   ,iv_file_format                  IN     VARCHAR2          -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
  );
END XXCOK024A20C;
/
