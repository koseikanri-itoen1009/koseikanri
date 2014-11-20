CREATE OR REPLACE PACKAGE APPS.XXCOK001A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOK001A06C(spec)
 * Description      : �N���ڋq�ڍs���Excel�A�b�v���[�h
 * MD.050           : MD050_COK_001_A06_�N���ڋq�ڍs���Excel�A�b�v���[�h
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
 *  2013/02/07    1.0   K.Nakamura       main�V�K�쐬
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
END XXCOK001A06C;
/
