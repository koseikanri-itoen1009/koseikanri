CREATE OR REPLACE PACKAGE xxcmn810003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn810003c(spec)
 * Description      : OPM�i�ڃg���K�[�N���R���J�����g
 * MD.050           : OPM�i�ڃg���K�[�N���R���J�����g
 * MD.070           : OPM�i�ڃg���K�[�N���R���J�����g
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
 *  2008/09/16    1.0   Y.Suzuki         �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode         OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_item_no      IN     VARCHAR2          --   OPM�i��NO
  );
END xxcmn810003c;
/
