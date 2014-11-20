CREATE OR REPLACE PACKAGE XXCSM002A02C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A02C(spec)
 * Description      : ���i�v��Q�ʌv�掑���o��
 * MD.050           : ���i�v��Q�ʌv�掑���o�� MD050_CSM_002_A02
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 * init                 �y���������z�FA-1
 *
 * do_check             �y�`�F�b�N�����z�FA-2
 * 
 * deal_group4_data     �y���i�Q4���f�[�^�̏ڍ׏����zA-3,A-4,A-5
 *
 * deal_group3_data     �y���i�Q3���f�[�^�̏ڍ׏����zA-6,A-7,A-8
 * 
 * write_line_info      �y���i�Q4���P�ʂŃf�[�^�̏o�́zA-9
 * 
 * write_csv_file       �y���i�v��Q�ʌv�掑���o�̓f�[�^��CSV�t�@�C���֏o�́zA-9
 *  
 * final                �y�I�������zA-10
 *  
 * submain              �y���������z
 *
 * main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   ohshikyo        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT    NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W
    retcode          OUT    NOCOPY VARCHAR2,         --   �G���[�R�[�h
    iv_taisyo_ym     IN     VARCHAR2,                --   �Ώ۔N�x
    iv_kyoten_cd     IN     VARCHAR2                 --   ���_�R�[�h
  );
END XXCSM002A02C;
/
