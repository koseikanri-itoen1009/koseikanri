CREATE OR REPLACE PACKAGE XXCOI003A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A14C(spec)
 * Description      : ���̑�����f�[�^OIF�X�V
 * MD.050           : ���̑�����f�[�^OIF�X�V�iHHT���o�Ƀf�[�^�j MD050_COI_003_A14 
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
 *  2009/01/19   1.0   H.Nakajima        main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCOI003A14C;
/
