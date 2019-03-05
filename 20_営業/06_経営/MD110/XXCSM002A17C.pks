CREATE OR REPLACE PACKAGE APPS.XXCSM002A17C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSM002A17C(spec)
 * Description      : CSV�f�[�^�A�b�v���[�h�i�N�ԏ��i�v��j
 * MD.050           : MD050_CSM_002_A17_CSV�f�[�^�A�b�v���[�h�i�N�ԏ��i�v��j
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
 *  2018/11/05    1.0   N.Koyama          main�V�K�쐬
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
END XXCSM002A17C;
/
