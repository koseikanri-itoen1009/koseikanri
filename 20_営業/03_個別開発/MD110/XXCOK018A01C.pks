CREATE OR REPLACE PACKAGE XXCOK018A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK018A01C(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���FAR�C���^�[�t�F�C�X�iAR I/F�j�̔����� MD050_COK_018_A01
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
 *  2009/1/14     1.0   K.Suenaga        �V�K�쐬
 *
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf  OUT VARCHAR2         -- �G���[���b�Z�[�W
  , retcode OUT VARCHAR2         -- �G���[�R�[�h
  );
END XXCOK018A01C;
/
