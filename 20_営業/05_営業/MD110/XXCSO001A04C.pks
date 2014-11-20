CREATE OR REPLACE PACKAGE XXCSO001A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO001A04C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ����v���
 *                    ���_�ʌ��ʌv��e�[�u��,�c�ƈ��ʌ��ʌv��e�[�u���Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_001_A04_����v��i�[�y���ʁz
 *                    
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
 *  2009-01-14    1.0   Maruyama.Mio     �V�K�쐬
 *  2009-01-27    1.0   Maruyama.Mio     �P�̃e�X�g������������r���[���ʔ��f
 *  2009-02-27    1.1   Maruyama.Mio     �y��Q�Ή�036�z�G���[�����J�E���g�s��Ή�
 *  2009-02-27    1.1   Maruyama.Mio     �y��Q�Ή�037�z��6�c�Ɠ��߂��G���[���b�Z�[�W�s��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode              OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,in_file_id           IN         NUMBER            -- �t�@�C��ID
   ,in_fmt_ptn           IN         NUMBER          -- �t�H�[�}�b�g�p�^�[��
  );
END XXCSO001A04C;
/
