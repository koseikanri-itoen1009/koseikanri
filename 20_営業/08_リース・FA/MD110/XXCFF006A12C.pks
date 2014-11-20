CREATE OR REPLACE PACKAGE XXCFF006A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF006A12C(spec)
 * Description      : ���[�X�_����A�g
 * MD.050           : ���[�X�_����A�g MD050_CFF_006_A12
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���[�X�_����CSV�t�@�C���쐬
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   SCS����          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_object_code_from   IN    VARCHAR2,        -- 1.�����R�[�h(FROM)
    iv_object_code_to     IN    VARCHAR2         -- 2.�����R�[�h(TO)
  );
--
END XXCFF006A12C;
/
