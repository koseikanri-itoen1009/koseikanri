CREATE OR REPLACE PACKAGE XXCOP004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A01C(spec)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^(���[�t�ցj
 * MD.050           : �A�b�v���[�h�t�@�C������̓o�^(���[�t�ցj MD050_COP_004_A01
 * Version          : 1.00
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
 *  2008/11/05    1.00  SCS.Tsubomatsu   main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT VARCHAR2,           --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,           --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id        IN  VARCHAR2,           --   FILE_ID
    in_format_pattern IN  VARCHAR2            --   �t�H�[�}�b�g�E�p�^�[��
  );

END XXCOP004A01C;
/
