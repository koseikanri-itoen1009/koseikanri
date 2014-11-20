CREATE OR REPLACE PACKAGE APPS.XXCSO016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A03C(spec)
 * Description      : ���σw�b�_�A���ϖ��׃f�[�^�����n�V�X�e���ɑ��M���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           :  MD050_CSO_016_A03_���n-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)���Ϗ��f�[�^
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
 *  2008-12-09    1.0   Kazuyo.Hosoi     �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
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
END XXCSO016A03C;
/
