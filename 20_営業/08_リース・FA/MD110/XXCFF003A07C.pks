create or replace
PACKAGE XXCFF003A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff003a07C(spec)
 * Description      : ���[�X�_��E�����A�b�v���[�h
 * MD.050           : MD050_CFF_003_A07_���[�X�_��E�����A�b�v���[�h.doc
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
 *  2009-1-15     1.0   SCS�E��S��      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                  OUT VARCHAR2       -- �G���[�E���b�Z�[�W  --# �Œ� #
   , retcode                 OUT VARCHAR2       -- ���^�[���E�R�[�h    --# �Œ� #
   , in_file_id              IN  NUMBER         -- 1.�t�@�C��ID
   , in_file_upload_code     IN  NUMBER         -- 2.�t�@�C���A�b�v���[�h�R�[�h
  );
END XXCFF003A07C;
/

