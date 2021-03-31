CREATE OR REPLACE PACKAGE APPS.XXCOK024A29C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A29C(spec)
 * Description      : �≮�̔�����������Excel�A�b�v���[�h�i���v�F���j
 * MD.050           : �≮�̔�����������Excel�A�b�v���[�h�i���v�F���j MD050_COK_024_A29
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
 *  2020/06/18    1.0   N.Abe            main�V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --�G���[���b�Z�[�W #�Œ�#
    retcode           OUT  VARCHAR2,   --�G���[�R�[�h     #�Œ�#
    iv_file_id        IN   VARCHAR2,   --�t�@�C��ID
    iv_format_pattern IN   VARCHAR2    --�t�H�[�}�b�g�p�^�[��
  );
END XXCOK024A29C;
/
