CREATE OR REPLACE PACKAGE XXCMM003A36C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A36C(spec)
 * Description      : �e���}�X�^�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A36_�e���}�X�^�A�gIF�f�[�^�쐬
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
 *  2009-02-11    1.0   Akinori.Takeshita   �V�K�쐬
 *  2009-03-09    1.1   Yutaka.Kuboshima    �t�@�C���o�͐�̃v���t�@�C���̕ύX
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���i�e���}�X�^�A�gIF�f�[�^�쐬�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2      --�G���[�R�[�h    #�Œ�#
  );
END XXCMM003A36C;
/
