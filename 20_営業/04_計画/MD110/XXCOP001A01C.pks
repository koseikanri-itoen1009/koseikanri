CREATE OR REPLACE PACKAGE XXCOP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP001A01C(spec)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^�i��v��j
 * MD.050           : �A�b�v���[�h�t�@�C������̓o�^�i��v��j MD050_COP_001_A01
 * Version          : ver1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/21    1.0  SCS.Uchida       main�V�K�쐬
 *  2009/04/03    1.1  SCS.Goto         T1_0237�AT1_0270�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id    IN     NUMBER,           --   FILE_ID
    iv_format     IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
--
END XXCOP001A01C;
/
