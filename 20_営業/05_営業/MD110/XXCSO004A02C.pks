CREATE OR REPLACE PACKAGE XXCSO004A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO004A02C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hI/F)�Ɏ捞�܂ꂽ���_�ʉc�Ɛl���ꗗ
 *                    �f�[�^�����_�ʉc�Ɛl���i�A�h�I���j�Ɏ捞�݂܂��B
 *                    
 * MD.050           : MD050_CSO_004_A02_���_�ʉc�Ɛl���ꗗ�i�[
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
 *  2009-02-17    1.0   kyo     �V�K�쐬
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
END XXCSO004A02C;
/
