CREATE OR REPLACE PACKAGE APPS.XXCOP004A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A09C(spec)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^�i����v��j
 * MD.050           : MD050_COP_004_A09_�A�b�v���[�h�t�@�C������̓o�^�i����v��j
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
 *  2013/09/11    1.0   S.Niki            main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf     OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode    OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  );
END XXCOP004A09C;
/
