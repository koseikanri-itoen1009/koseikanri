CREATE OR REPLACE PACKAGE xxcmm004a08c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A08C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�W�������f�[�^��
 *                  : OPM�W�������e�[�u���ɔ��f���܂��B
 * MD.050           : �W�������ꊇ����    MD050_CMM_004_A08
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
 *  2008/12/19    1.0   H.Yoshikawa      main�V�K�쐬
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
END xxcmm004a08c;
/
