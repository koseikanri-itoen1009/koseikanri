CREATE OR REPLACE PACKAGE XXCOK016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A01C(spec)
 * Description      : �g�ݖ߂��E�c������E�ۗ����(CSV�t�@�C��)�̎捞����
 * MD.050           : �c���X�VExcel�A�b�v���[�h MD050_COK_016_A01
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �g�ݖ߂��E�c������E�ۗ����(CSV�t�@�C��)�̎捞����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25     1.0   K.Ezaki         �V�K�쐬
 *  2009/03/25     1.1   S.Kayahara      �ŏI�s�ɃX���b�V���ǉ�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- �G���[���b�Z�[�W
    ,retcode    OUT VARCHAR2 -- �G���[�R�[�h
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  );
END XXCOK016A01C;
/
