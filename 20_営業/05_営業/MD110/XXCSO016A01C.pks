CREATE OR REPLACE PACKAGE XXCSO016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A01C(spec)
 * Description      : �c�ƈ��ʌv��f�[�^�����n�V�X�e���֘A�g���邽�߂�
 *                    �b�r�u�t�@�C�����쐬���܂��B
 * MD.050           :  MD050_CSO_016_A01_���n-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)�c�ƈ��ʌv��f�[�^
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
 *  2008-11-05    1.0   Kazuyo.Hosoi     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO016A01C;
/
