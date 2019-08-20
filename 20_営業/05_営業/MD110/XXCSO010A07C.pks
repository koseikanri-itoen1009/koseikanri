CREATE OR REPLACE PACKAGE APPS.XXCSO010A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSO010A07C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ�_��X�V�f�[�^����荞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_010_A07_�_��X�VCSV�A�b�v���[�h
 *                    
 * Version          : 1.00
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
 *  2019-03-28    1.00  T.Kawaguchi      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W
   ,retcode              OUT NOCOPY VARCHAR2          -- �G���[�R�[�h
   ,in_file_id           IN         NUMBER            -- �t�@�C��ID
   ,iv_fmt_ptn           IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  );
END XXCSO010A07C;
/
