CREATE OR REPLACE PACKAGE APPS.XXCOK024A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A01C (spec)
 * Description      : �T���}�X�^CSV�A�b�v���[�h
 * MD.050           : �T���}�X�^CSV�A�b�v���[�h MD050_COS_024_A01
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
 *  2019/12/23    1.0   Y.Sasaki         main�V�K�쐬
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
END XXCOK024A01C;
/
