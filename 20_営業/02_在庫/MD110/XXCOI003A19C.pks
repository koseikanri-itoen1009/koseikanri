CREATE OR REPLACE PACKAGE APPS.XXCOI003A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCOI003A19C (spec)
 * Description      : �o�Ɉ˗�CSV�A�b�v���[�h�i�c�Ǝԁj
 * MD.050           : �o�Ɉ˗�CSV�A�b�v���[�h�i�c�Ǝԁj MD050_COI_003_A19
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
 *  2019/11/15    1.0   T.Nakano         �V�K�쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT VARCHAR2  -- �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT VARCHAR2  -- �G���[�R�[�h     #�Œ�#
   ,iv_file_id        IN  VARCHAR2  -- 1.<�t�@�C��ID>
   ,iv_file_format    IN  VARCHAR2  -- 2.<�t�H�[�}�b�g�p�^�[��>
  );
--
END XXCOI003A19C;
/