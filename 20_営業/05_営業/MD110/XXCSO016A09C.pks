CREATE OR REPLACE PACKAGE XXCSO016A09C
AS
/*****************************************************************************************
 * Copyright(c)2022,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO016A09C(spec)
 * Description      : ���̋@�ڋq�ʎx���Ǘ������n�V�X�e���֘A�g���邽�߂�
 *                    �b�r�u�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_016_A09_���n-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)���̋@�ڋq�ʎx���Ǘ�
 *                    
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
 *  2022-07-21    1.0   K.Tomie         �V�K�쐬 E_�{�ғ�_18060
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_target_yyyymm_from IN         VARCHAR2          -- �Ώ۔N��(From)
   ,iv_target_yyyymm_to   IN         VARCHAR2          -- �Ώ۔N��(To)
  );
END XXCSO016A09C;
/
