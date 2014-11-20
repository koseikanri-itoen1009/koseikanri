CREATE OR REPLACE PACKAGE XXCSM001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM001A02C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�N�Ԍv��f�[�^��
 *                  : �̔��v��e�[�u��(�A�h�I��)�Ɏ捞�݂܂��B
 * MD.050           : �\�Z�f�[�^�`�F�b�N�捞(�N�Ԍv��)
 * Version          :  Draft2.0E.doc
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
 *  2008/11/18    1.0   M.Ohtsuki         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    NOCOPY VARCHAR2                                                            -- �G���[���b�Z�[�W
   ,retcode       OUT    NOCOPY VARCHAR2                                                            -- �G���[�R�[�h
   ,iv_file_id    IN     VARCHAR2                                                                   -- �t�@�C��ID
   ,iv_format     IN     VARCHAR2                                                                   -- �t�H�[�}�b�g
  );
END XXCSM001A02C;
/
