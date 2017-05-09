CREATE OR REPLACE PACKAGE APPS.XXCOS003A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A08C (spec)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�������i�\�j
 * MD.050           : CSV�f�[�^�A�b�v���[�h�i�������i�\�j MD050_COS_003_A08
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
 *  2017/03/02    1.0   S.Yamashita      �V�K�쐬
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode           OUT NOCOPY VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<�t�H�[�}�b�g�p�^�[��>
  );
--
END XXCOS003A08C;
/
