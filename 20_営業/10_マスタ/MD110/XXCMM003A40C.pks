CREATE OR REPLACE PACKAGE XXCMM003A40C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A40C(spec)
 * Description      : �ڋq�ꊇ�o�^���[�N�e�[�u���Ɏ捞�ς݂̃f�[�^����ڋq���R�[�h��o�^���܂��B
 * MD.050           : �ڋq�ꊇ�o�^ MD050_CMM_003_A40
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
 *  2010/10/05    1.0   Shigeto.Niki     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
   ,iv_file_id    IN     VARCHAR2       --   �t�@�C��ID
   ,iv_format     IN     VARCHAR2       --   �t�H�[�}�b�g
  );
END XXCMM003A40C;
/
