CREATE OR REPLACE PACKAGE XXCMM004A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A05C(body)
 * Description      : �i�ڈꊇ�o�^���[�N�e�[�u���Ɏ捞�܂ꂽ�i�ڈꊇ�o�^�f�[�^��i�ڃe�[�u���ɓo�^���܂��B
 * MD.050           : �i�ڈꊇ�o�^ CMM_004_A05
 * Version          : Draft2B
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
 *  2008/12/01    1.0   K.Ito            main�V�K�쐬
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
END XXCMM004A05C;
/
