CREATE OR REPLACE PACKAGE APPS.XXCFF019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A01C(spec)
 * Description      : �Œ莑�Y�f�[�^�A�b�v���[�h
 * MD.050           : MD050_CFF_019_A01_�Œ莑�Y�f�[�^�A�b�v���[�h
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
 *  2017/08/30    1.0   S.Niki           E_�{�ғ�_14502�Ή��i�V�K�쐬�j
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    in_file_id       IN    NUMBER,          --   1.�t�@�C��ID
    iv_file_format   IN    VARCHAR2         --   2.�t�@�C���t�H�[�}�b�g
  );
END XXCFF019A01C;
/
