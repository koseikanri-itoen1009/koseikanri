CREATE OR REPLACE PACKAGE      XXCMM004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A07C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�c�ƌ����f�[�^��
 *                  : Disc�i�ڕύX�����e�[�u��(�A�h�I��)�Ɏ捞�݂܂��B
 * MD.050           : �c�ƌ����ꊇ����    MD050_CMM_004_A07
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
 *  2008/12/17    1.0   H.Yoshikawa      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT      VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,retcode           OUT      VARCHAR2                                        -- ���^�[���E�R�[�h
   ,iv_file_id        IN       VARCHAR2                                        -- �t�@�C��ID
   ,iv_format         IN       VARCHAR2                                        -- �t�H�[�}�b�g�p�^�[��
  );
END XXCMM004A07C;
/
