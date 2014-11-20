CREATE OR REPLACE PACKAGE XXCSO014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A08C(spec)
 * Description      : ���ʔ���v��t�@�C����HHT�֘A�g���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_IPO_CSO_014_A08_HHT-EBS�C���^�[�t�F�[�X�F(OUT)���ʔ���v��
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
 *  create_csv_rec              CSV�t�@�C���o�� (A-7)
 *  close_csv_file              CSV�t�@�C���N���[�Y (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                                �ڋq�ʓ��ʔ���v��f�[�^���o (A-6)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-25    1.0   Syoei.Kin        �V�K�쐬
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
END XXCSO014A08C;
/
