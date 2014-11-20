CREATE OR REPLACE PACKAGE XXCMM003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A19C(spec)
 * Description      : HHT�A�gIF�f�[�^�쐬
 * MD.050           : MD050_CMM_003_A19_HHT�n�A�gIF�f�[�^�쐬
 * Version          : 1.1
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
 *  2009-02-18    1.0   Takuya.Kaihara   �V�K�쐬
 *  2009/03/09    1.1   Takuya Kaihara   �v���t�@�C���l���ʉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���iHHT�n�A�gIF�f�[�^�쐬�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,     --�G���[�R�[�h     #�Œ�#
    iv_proc_date_from         IN     VARCHAR2,     --�ŏI�X�V���i�J�n�j
    iv_proc_date_to           IN     VARCHAR2      --�ŏI�X�V���i�I���j
  );
END XXCMM003A19C;
/
