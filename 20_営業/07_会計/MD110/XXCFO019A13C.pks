CREATE OR REPLACE PACKAGE XXCFO019A13C
AS
/*****************************************************************************************
 * Copyright(c)2021,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A13C(spec)
 * Description      : �d�q���됿���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A13_�d�q���됿���̏��n�V�X�e���A�g
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
 *  2021-12-16    1.0   K.Tomie         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_cutoff_date        IN         VARCHAR2          -- ����
   ,iv_file_name          IN         VARCHAR2          -- �t�@�C����
  );
END XXCFO019A13C;
/
