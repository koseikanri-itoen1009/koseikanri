CREATE OR REPLACE PACKAGE XXCSO017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO017A07C(spec)
 * Description      : ���Ϗ��A�b�v���[�h
 * MD.050           : ���Ϗ��A�b�v���[�h MD050_CSO_017_A07
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
 *  2012/01/26    1.0   Y.Horikawa       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_id    IN     VARCHAR2,         -- 1.�t�@�C��ID
    iv_fmt_ptn    IN     VARCHAR2          -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCSO017A07C;
/
