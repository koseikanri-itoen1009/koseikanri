CREATE OR REPLACE PACKAGE XXCSM002A13C AS

/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A13C(spec)
 * Description      : ���i�v�惊�X�g(���n��_�{���P��)�o��
 * MD.050           : ���i�v�惊�X�g(���n��_�{���P��)�o�� MD050_CSM_002_A13
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                �y���������zA-1
 *
 *  do_check            �y�`�F�b�N�����zA-2~A-3
 *
 *  deal_item_data      �y���i�P�ʂ̏����zA-4~A-6
 *
 *  deal_group4_data    �y���i�Q�P�ʂ̏����zA-7~A-9
 *
 *  deal_group1_data    �y���i�敪�P�ʂ̏����zA-10~A-12
 *
 *  deal_sum_data       �y���i���v�P�ʂ̏����zA-13~A-15
 *
 *  deal_down_data      �y���i�l���P�ʂ̏����zA-16~A-17
 *
 *  deal_kyoten_data    �y���_�P�ʂ̏����zA-18~A-20
 *
 *  deal_all_data       �y���_���X�g�P�ʂ̏����zA-2~A-20
 *
 *  get_col_data        �y�e���ڃf�[�^�̎擾�zA-21
 *     
 *  deal_csv_data        �y�o�̓{�f�B���̎擾�zA-21
 *  
 *  write_csv_file      �y�o�͏����zA-22
 *  
 *  submain             �y���������zA-1~A-23
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���zA-1~A-23
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ohshikyo        �V�K�쐬
 *  2012/12/19    1.1   SCSK K.Taniguchi [E_�{�ғ�_09949] �V�������I���\�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf           OUT    NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W
      retcode          OUT    NOCOPY VARCHAR2,         --   �G���[�R�[�h
      iv_taisyo_ym     IN     VARCHAR2,                --   �Ώ۔N�x
      iv_kyoten_cd     IN     VARCHAR2,                --   ���_�R�[�h
      iv_cost_kind     IN     VARCHAR2,                --   �������
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--      iv_kyoten_kaisou IN     VARCHAR2                 --   �K�w
      iv_kyoten_kaisou IN     VARCHAR2,                --   �K�w
      iv_new_old_cost_class
                       IN     VARCHAR2                 --   �V�������敪
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
  );
END XXCSM002A13C;
/
