CREATE OR REPLACE PACKAGE XXCOK008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A04C(spec)
 * Description      : ����U�֊����̓o�^
 * MD.050           : ����U�֊����̓o�^ MD050_COK_008_A04
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/28    1.0   S.Sasaki         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,   --�G���[���b�Z�[�W
    retcode           OUT  VARCHAR2,   --�G���[�R�[�h
    iv_file_id        IN   VARCHAR2,   --�t�@�C��ID
    iv_format_pattern IN   VARCHAR2    --�t�H�[�}�b�g�p�^�[��
  );
END XXCOK008A04C;
/
