CREATE OR REPLACE PACKAGE XXCSM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A06C(spec)
 * Description      : EBS(�t�@�C���A�b�v���[�hIF)�Ɏ捞�܂ꂽ�Y��|�C���g�f�[�^��
 *                  : �V�K�l���|�C���g�ڋq�ʗ����e�[�u���Ɏ捞�݂܂��B
 * MD.050           : MD050_CSM_004_A06_�Y��|�C���g�ꊇ�捞
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
 *  2009/03/03    1.0   M.Ohtsuki         main�V�K�쐬
 *  2009/04/22    1.1   M.Ohtsuki        �m��QT1_0735�n�v���O�����̖�����/��ǉ�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    NOCOPY VARCHAR2                                                            -- �G���[���b�Z�[�W
   ,retcode       OUT    NOCOPY VARCHAR2                                                            -- �G���[�R�[�h
   ,iv_file_id    IN     VARCHAR2                                                                   -- �t�@�C��ID
   ,iv_format     IN     VARCHAR2                                                                   -- �t�H�[�}�b�g
  );
END XXCSM004A06C;
/
