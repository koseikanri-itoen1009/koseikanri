CREATE OR REPLACE PACKAGE APPS.XXCSO014A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A07C(spec)
 * Description      : �K��敪�}�X�^��HHT�ɑ��M���邽�߂�
 *                    CSV�t�@�C�����쐬���܂��B 
 * MD.050           : MD050_CSO_014_A07_HHT-EBS�C���^�[�t�F�[�X�F
 *                    (OUT)�K��敪�}�X�^_Draft2.0C
 * Version          : 1.0
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
 *  2008-12-14    1.0   Seirin.Kin        �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
 --
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_value          IN         VARCHAR2          -- �p�����[�^������
  );
END XXCSO014A07C;
/
