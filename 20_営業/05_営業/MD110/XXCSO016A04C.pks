CREATE OR REPLACE PACKAGE APPS.XXCSO016A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A04C(spec)
 * Description      : EBS�ɓo�^���ꂽ�K����уf�[�^�����n�V�X�e���ɘA�g���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           :  MD050_CSO_016_A04_���n-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)�K����уf�[�^
 * Version          : 1.1
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
 *  2008-12-19    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-02-26    1.1   K.Sai            ���r���[���ʔ��f 
 *  2009-03-05    1.1   Mio.Maruyama     �̔����уe�[�u���d�l�ύX�ɂ��
 *                                       �f�[�^���o�����ύX�Ή�
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_from_value IN  VARCHAR2                 --   �p�����[�^�X�V�� FROM
   ,iv_to_value   IN  VARCHAR2                 --   �p�����[�^�X�V�� TO
  );
END XXCSO016A04C;
/
