CREATE OR REPLACE PACKAGE XXCMM002A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM002A07C(spec)
 * Description      : �Ј��}�X�^�A�g�ieSM�j
 * MD.050           : MD050_CMM_002_A07_�Ј��}�X�^�A�g�ieSM�j
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
 *  2017/02/08    1.0   S.Niki           �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2   -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                   OUT    VARCHAR2   -- �G���[�R�[�h     #�Œ�#
   ,iv_update_from            IN     VARCHAR2   -- �ŏI�X�V���i�J�n�j
   ,iv_update_to              IN     VARCHAR2   -- �ŏI�X�V���i�I���j
  );
END XXCMM002A07C;
/
