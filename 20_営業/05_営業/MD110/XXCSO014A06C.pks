CREATE OR REPLACE PACKAGE XXCSO014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A06C(spec)
 * Description      : �c�ƈ��Ǘ��t�@�C����HHT�ɑ��M���邽�߂� 
 *                    CSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSO_014_A06_HHT-EBS�C���^�[�t�F�[�X�F
 *                     (OUT)�c�ƈ��Ǘ��t�@�C��_Draft2.0B.doc
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  
 * submain              
 * main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-28    1.0   Seirin.Kin        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSO014A06C;
/