CREATE OR REPLACE PACKAGE APPS.XXCSO016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A07C(spec)
 * Description      : ���_�ʉc�Ɛl�������n�V�X�e���֘A�g���邽�߂�
 *                    �b�r�u�t�@�C�����쐬���܂��B
 * MD.050           :  MD050_CSO_016_A07_���n-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)���_�ʉc�Ɛl��
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
 *  2008-03-02    1.0   Mio.Maruyama     �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO016A07C;
/
