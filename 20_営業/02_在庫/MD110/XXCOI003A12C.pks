CREATE OR REPLACE PACKAGE XXCOI003A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A12C(spec)
 * Description      : HHT���o�Ƀf�[�^���o
 * MD.050           : HHT���o�Ƀf�[�^���o MD050_COI_003_A12
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
 *  2008/12/08    1.0   H.Nakajima       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT  nocopy  VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT  nocopy  VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCOI003A12C;
/
