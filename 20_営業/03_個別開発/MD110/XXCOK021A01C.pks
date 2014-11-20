CREATE OR REPLACE PACKAGE XXCOK021A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A01C(spec)
 * Description      : �≮�̔�����������Excel�A�b�v���[�h
 * MD.050           : �≮�̔�����������Excel�A�b�v���[�h MD050_COK_021_A01
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
 *  2008/11/11    1.0   S.Sasaki         main�V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --�G���[���b�Z�[�W #�Œ�#
    retcode           OUT  VARCHAR2,   --�G���[�R�[�h     #�Œ�#
    iv_file_id        IN   VARCHAR2,   --�t�@�C��ID
    iv_format_pattern IN   VARCHAR2    --�t�H�[�}�b�g�p�^�[��
  );
END XXCOK021A01C;
/
