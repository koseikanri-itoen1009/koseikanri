CREATE OR REPLACE PACKAGE APPS.XXCOI003A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI003A18C (spec)
 * Description      : ���_�ԑq��CSV�A�b�v���[�h
 * MD.050           : ���_�ԑq��CSV�A�b�v���[�h MD050_COI_003_A18
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
 *  2015/06/24    1.0   S.Yamashita      �V�K�쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT VARCHAR2,   -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT VARCHAR2,   -- �G���[�R�[�h     #�Œ�#
    iv_file_id        IN  VARCHAR2,   -- 1.<�t�@�C��ID>
    iv_file_format    IN  VARCHAR2    -- 2.<�t�H�[�}�b�g�p�^�[��>
  );
--
END XXCOI003A18C;
/
