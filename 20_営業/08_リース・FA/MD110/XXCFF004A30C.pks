create or replace
PACKAGE XXCFF004A30C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A30C(spec)
 * Description      : ���[�X�����ꕔ�C���E�ړ��E���A�b�v���[�h
 * MD.050           : MD050_CFF_004_A30_���[�X�����ꕔ�C���E�ړ��E���A�b�v���[�h
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
 *  2009/01/09    1.00  SCS ���c         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    in_file_id       IN    NUMBER,          -- 1.�t�@�C��ID(�K�{)
    iv_file_format   IN    VARCHAR2         -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
  );
END XXCFF004A30C;
/
