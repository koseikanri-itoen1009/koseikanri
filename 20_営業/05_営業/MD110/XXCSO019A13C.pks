CREATE OR REPLACE PACKAGE APPS.XXCSO019A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A12C(spec)
 * Description      : ���[�gNo�^�c�ƈ��ꊇ�X�V�A�b�v���[�h
 * MD.050           : ���[�gNo�^�c�ƈ��ꊇ�X�V�A�b�v���[�h (MD050_CSO_019A13)
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
 *  2018/04/03    1.0   K.Kiriu          main�V�K�쐬�iE_�{�ғ�_14722�j
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf        OUT    VARCHAR2       --   �G���[���b�Z�[�W #�Œ�#
    ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
    ,iv_file_id    IN     VARCHAR2       -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN     VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCSO019A13C;
/
