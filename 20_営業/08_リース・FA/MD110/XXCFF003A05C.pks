create or replace
PACKAGE XXCFF003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A05C(spec)
 * Description      : �x���v��쐬
 * MD.050           : MD050_CFF_003_A05_�x���v��쐬.doc
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
 *  2008-12-03    1.0   SCS�E��S��       �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    iv_shori_type              IN VARCHAR2            -- 1.�����敪
   ,in_contract_line_id        IN NUMBER              -- 2.�_�񖾍ד���ID  
   ,ov_errbuf                  OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
END XXCFF003A05C;
/