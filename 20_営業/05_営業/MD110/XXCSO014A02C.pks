CREATE OR REPLACE PACKAGE XXCSO014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A01C(spec)
 * Description      : ���ʔ���v��f�[�^���ڋq�ʔ���v��e�[�u���֓o�^�܂��͍X�V���܂��B
 *                    
 * MD.050           : MD050_CSO_014_A02_HHT-EBS�C���^�[�t�F�[�X�F(IN�j����v�����
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
 *  2008-12-24    1.0   Kenji.Sai        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO014A02C;
/
