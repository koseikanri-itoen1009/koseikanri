CREATE OR REPLACE PACKAGE XXCSO020A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A06C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽSP�ꌈWF���F�g�D
 *                    �}�X�^�f�[�^��WF���F�g�D�}�X�^�e�[�u���Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_020_A06_SP-WF���F�g�D�}�X�^���ꊇ�捞
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
 *  2008-01-06    1.0   Maruyama.Mio     �V�K�쐬
 *  2008-01-30    1.0   Maruyama.Mio     IN�p�����[�^�t�@�C��ID�ϐ����ύX(�L�q���[���Q�l)
 *  2008-02-25    1.1   Maruyama.Mio     �y��Q�Ή�028�z�L�����ԏd���`�F�b�N�s��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode              OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,in_file_id           IN         NUMBER            -- �t�@�C��ID
   ,iv_fmt_ptn           IN         VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
  );
END XXCSO020A06C;
/
