CREATE OR REPLACE PACKAGE XXCFF012A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF012A18C(spec)
 * Description      : ���[�X���c�����|�[�g
 * MD.050           : ���[�X���c�����|�[�g MD050_CFF_012_A18
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
 *  2009/01/19    1.0   SCS�R��          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT VARCHAR2,      --   �G���[�R�[�h     #�Œ�#
    iv_period_name       IN  VARCHAR2       -- 1.��v���Ԗ�
  );
END XXCFF012A18C;
/
