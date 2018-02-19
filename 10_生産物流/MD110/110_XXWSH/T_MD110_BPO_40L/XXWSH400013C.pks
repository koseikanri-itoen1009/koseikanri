CREATE OR REPLACE PACKAGE APPS.XXWSH400013C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXWSH400013C(spec)
 * Description      : �o�׈˗��X�V�A�b�v���[�h
 * MD.050           : �o�׈˗� <MD050_BPO_401>
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
 *  2018/01/11    1.0   K.Kiriu          main�V�K�쐬(E_�{�ғ�_14672)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_id    IN     VARCHAR2,         --   1.�t�@�C���h�c
    iv_format     IN     VARCHAR2          --   2.�t�H�[�}�b�g�p�^�[��
  );
END XXWSH400013C;
/
