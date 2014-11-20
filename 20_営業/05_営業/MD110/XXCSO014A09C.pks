CREATE OR REPLACE PACKAGE APPS.XXCSO014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A09C(spec)
 * Description      : ���ʔ���v��t�@�C����HHT�֘A�g���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_IPO_CSO_014_A09_HHT-EBS�C���^�[�t�F�[�X�F(OUT)���ʔ���v��
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  set_parm_def                �p�����[�^�f�t�H���g�Z�b�g (A-2)
 *  chk_parm_date               �p�����[�^�`�F�b�N (A-3)
 *  get_profile_info            �v���t�@�C���l���擾 (A-4)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-5) 
 *  create_csv_rec              CSV�t�@�C���o�� (A-8)
 *  close_csv_file              CSV�t�@�C���N���[�Y (A-9)
 *  submain                     ���C�������v���V�[�W��
 *                                �ڋq�ʌ��ʔ���v��f�[�^���o (A-6)
 *                                CSV�t�@�C���ɏo�͂���֘A���擾 (A-7)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-10    1.0   Syoei.Kin        �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_from_value       IN VARCHAR2                 -- �X�V��FROM(YYYYMMDD)
   ,iv_to_value         IN VARCHAR2                 -- �X�V��TO(YYYYMMDD)
  );
END XXCSO014A09C;
/
