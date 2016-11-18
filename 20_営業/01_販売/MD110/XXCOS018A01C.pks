CREATE OR REPLACE PACKAGE APPS.XXCOS018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS018A01C(spec)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�̔����сj
 * MD.050           : MD050_COS_018_A01_CSV�f�[�^�A�b�v���[�h�i�̔����сj
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
 *  2016/10/12    1.0   S.Niki            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf             OUT VARCHAR2   -- �G���[���b�Z�[�W #�Œ�#
    , retcode            OUT VARCHAR2   -- �G���[�R�[�h     #�Œ�#
    , in_get_file_id     IN  NUMBER     -- �t�@�C��ID
    , iv_get_format_pat  IN  VARCHAR2   -- �t�H�[�}�b�g�p�^�[��
  );
END XXCOS018A01C;
/
