CREATE OR REPLACE PACKAGE XXCOK021A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A05C(spec)
 * Description      : AP�C���^�[�t�F�C�X
 * MD.050           : AP�C���^�[�t�F�[�X MD050_COK_021_A05
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
 *  2009/01/14    1.0   S.Tozawa         �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , retcode       OUT VARCHAR2     -- ���^�[���E�R�[�h
  );
--
END XXCOK021A05C;
/