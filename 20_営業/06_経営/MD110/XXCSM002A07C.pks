CREATE OR REPLACE PACKAGE XXCSM002A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A07C(body)
 * Description      : ���i�v��Q�ʃ`�F�b�N���X�g�o��
 * MD.050           : ���i�v��Q�ʃ`�F�b�N���X�g�o�� MD050_CSM_002_A07
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
 *  2008-12-17    1.0   K.Yamada         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT VARCHAR2,          --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT VARCHAR2,          --   �G���[�R�[�h     #�Œ�#
    iv_yyyy       IN  VARCHAR2,          -- 1.�Ώ۔N�x
    iv_kyoten_cd  IN  VARCHAR2           -- 2.���_�R�[�h
  );
END XXCSM002A07C;
/
