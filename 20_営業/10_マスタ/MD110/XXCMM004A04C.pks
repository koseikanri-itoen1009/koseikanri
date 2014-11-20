CREATE OR REPLACE PACKAGE      xxcmm004a04c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcmm004a04c(spec)
 * Description      : Disc�i�ڕύX�����A�h�I���}�X�^�ɂĕύX�\��Ǘ�����Ă��鍀�ڂ�
 *                  : �K�p�������������^�C�~���O�Ŋe�i�ڏ��ɔ��f���܂��B
 * MD.050           : �ύX�\��K�p    MD050_CMM_004_A04
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
 *  2009/01/06    1.0   H.Yoshikawa      main�V�K�쐬
 *  2009/01/20    1.1   H.Yoshikawa      �P�̃e�X�g�s��ɂ��C��
 *  2009/01/27    1.2   H.Yoshikawa      �W�������o�^�܂��̏C��
 *                                       �i���������ׂēo�^����悤�C���j
 *  2009/01/29    1.3   H.Yoshikawa      �e�i�ڂ̉��o�^�ύX���Ɂu���敪�v��K�{���ڂɒǉ�
 *  2009/01/30    1.4   H.Yoshikawa      �����g�D�ύX�ɂ��C��
 *
*****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_boot_flag   IN     VARCHAR2         --   �N����ʁy1:�I�����C���A2�F��ԁz
  );
END xxcmm004a04c;
/
