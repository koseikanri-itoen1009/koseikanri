CREATE OR REPLACE PACKAGE XXCSO014A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A04C(spec)
 * Description      : ���[�g��񃏁[�N�e�[�u��(�A�h�I��)�Ɏ�荞�܂ꂽ���[�g�����A
 *                    �ڋq���Ɗ֘A�t����EBS��̌ڋq�}�X�^�ɓo�^���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A04_HHT-EBS�C���^�[�t�F�[�X�F(IN�j���[�g���
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
 *  2009-1-16    1.0   Kenji.Sai        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO014A04C;
/
