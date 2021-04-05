CREATE OR REPLACE PACKAGE XXCMM004A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A15C(spec)
 * Description      : CSV�`���̃f�[�^�t�@�C������ADisc�i�ڃA�h�I���̍X�V���s���܂��B
 * MD.050           : �i�ڈꊇ�X�V CMM_004_A15
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
 *  2021/03/12    1.0   H.Futamura       �V�K�쐬
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
END XXCMM004A15C;
/
