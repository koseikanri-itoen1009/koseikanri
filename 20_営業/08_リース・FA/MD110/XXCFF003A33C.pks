CREATE OR REPLACE PACKAGE XXCFF003A33C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A33C(spec)
 * Description      : ���[�X�����R�[�h����
 * MD.050           : MD050_CFF_003_A33_���[�X�����R�[�h����
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
 *  2009-01-14    1.0   SCS ���q �G�K    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_obj_code1  IN     VARCHAR2,        --   1.�����R�[�h1
    iv_obj_code2  IN     VARCHAR2         --   2.�����R�[�h2
  );
END XXCFF003A33C;
/
