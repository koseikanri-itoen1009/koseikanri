CREATE OR REPLACE PACKAGE APPS.XXCSO011A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A06C(spec)
 * Description      : ������p���̏�ԂɍX�V���܂��B
 * MD.050           : �p���\��CSV�A�b�v���[�h (MD050_CSO_011A06)
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
 *  2015/08/07    1.0   S.Yamashita      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf        OUT    VARCHAR2       --   �G���[���b�Z�[�W #�Œ�#
    ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
    ,iv_file_id    IN     VARCHAR2       -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN     VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCSO011A06C;
/
