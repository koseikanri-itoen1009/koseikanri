CREATE OR REPLACE PACKAGE APPS.XXCCP010A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP010A03C(spec)
 * Description      : �⍇���S�����_�X�V�A�b�v���[�h
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
 *  2016/04/20    1.0   Y.Shoji          [E_�{�ғ�_08373]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id    IN     VARCHAR2          -- 1.�t�@�C��ID
   ,iv_fmt_ptn    IN     VARCHAR2          -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCCP010A03C;
/
