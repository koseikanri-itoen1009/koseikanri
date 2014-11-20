CREATE OR REPLACE PACKAGE XXCSM002A03C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A03C(spec)
 * Description      : ���i�v��Q�l�����o��(���i��2���N����)
 * MD.050           : ���i�v��Q�l�����o��(���i��2���N����) MD050_CSM_002_A03
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                �y���������zA-1
 *
 *  do_check            �y�`�F�b�N�����zA-2
 *
 *  deal_result_data    �y���уf�[�^�̏ڍ׏����zA-3,A-4,A-5,A-6,A-7
 *
 *  deal_plan_data      �y�v��f�[�^�̏ڍ׏����zA-3,A-4,A-8,A-9,A-10
 *
 *  write_line_info     �y���i�P�ʂł̃f�[�^�o�́zA-11
 *
 *  write_csv_file      �y���i�v��Q�l�����f�[�^��CSV�t�@�C���֏o�́zA-11
 *
 *  submain             �y���������zA-1�`A-11
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���zA-1�`A-12
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/04    1.0   ohshikyo        �V�K�쐬
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
END XXCSM002A03C;
/
