CREATE OR REPLACE PACKAGE APPS.XXCFO016A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO016A04C(spec)
 * Description      : ���Ə��}�X�^�A�g�f�[�^���o_EBS�R���J�����g
 * MD.050           : T_MD050_CFO_016_A04_���Ə��}�X�^�A�g�f�[�^���o_EBS�R���J�����g
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
 *  2022/10/27    1.0   N.Fujiwara       �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                     OUT  VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode                    OUT  VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_proc_date_for_recovery  IN   VARCHAR2 -- 1.�Ɩ����t(���J�o���p)
  );
END XXCFO016A04C;
/
