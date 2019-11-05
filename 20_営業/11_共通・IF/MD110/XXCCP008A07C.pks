CREATE OR REPLACE PACKAGE XXCCP008A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A07C(spec)
 * Description      : ���Y�ڊǏC���A�b�v���[�h����
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
 *  2019/10/10    1.0   Y.Ohishi        E_�{�ғ�_15982  �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_file_id    IN     VARCHAR2,         -- �t�@�C��ID
    iv_fmt_ptn    IN     VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  );
END XXCCP008A07C;
/
