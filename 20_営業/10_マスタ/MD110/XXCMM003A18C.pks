CREATE OR REPLACE PACKAGE XXCMM003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A18C(spec)
 * Description      : ���n�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A18_���n�A�gIF�f�[�^�쐬
 * Version          : 1.2
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
 *  2009-01-28    1.0   Takuya.Kaihara   �V�K�쐬
 *  2009/02/23    1.1   Takuya Kaihara   �t�@�C���N���[�Y�����C��
 *  2009/03/09    1.2   Takuya Kaihara   �v���t�@�C���l���ʉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���i���n�A�gIF�f�[�^�쐬�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2      --�G���[�R�[�h     #�Œ�#
  );
END XXCMM003A18C;
/
