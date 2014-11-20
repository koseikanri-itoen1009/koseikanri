CREATE OR REPLACE PACKAGE APPS.XXCSO014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A10C(spec)
 * Description      : )�K��\��t�@�C����HHT�֘A�g���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_IPO_CSO_014_A10_HHT-EBS�C���^�[�t�F�[�X�F(OUT)�K��\��t�@�C��
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  chk_parm_date               �p�����[�^�`�F�b�N (A-2)
 *  get_profile_info            �v���t�@�C���l�擾 (A-3)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-4)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-6)
 *  create_csv_rec              �K��\��f�[�^CSV�o�� (A-7)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                                �K��\��f�[�^���o���� (A-5)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-18    1.0   Syoei.Kin        �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_value            IN VARCHAR2                 --   �������s��(YYYYMMDD)
  );
END XXCSO014A10C;
/
