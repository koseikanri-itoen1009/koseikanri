CREATE OR REPLACE PACKAGE XXCOI016A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A10C(spec)
 * Description      : ���b�g�ʎ󕥃f�[�^�쐬(����)
 * MD.050           : MD050_COI_016_A10_���b�g�ʎ󕥃f�[�^�쐬(����).doc
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
 *  2014/10/27    1.0   Y.Nagasue        main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
   ,retcode              OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
   ,iv_login_base_code   IN  VARCHAR2 -- ���_�R�[�h
   ,iv_subinventory_code IN  VARCHAR2 -- �ۊǏꏊ�R�[�h
   ,iv_startup_flg       IN  VARCHAR2 -- �N���t���O
  );
END XXCOI016A10C;
/
