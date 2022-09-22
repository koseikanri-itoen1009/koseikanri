CREATE OR REPLACE PACKAGE APPS.XXCOS005A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOS005A11C (spec)
 * Description      : CSV�f�[�^�A�b�v���[�h�i���i�\�j
 * MD.050           : CSV�f�[�^�A�b�v���[�h�i���i�\�j MD050_COS_005_A11
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
 *  2022/08/30    1.0   R.Oikawa      �V�K�쐬
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
END XXCOS005A11C;
/
