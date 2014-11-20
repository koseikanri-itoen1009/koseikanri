CREATE OR REPLACE PACKAGE XXCSO016A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A05C(spec)
 * Description      : ����(���̋@)�̈ړ������������n�V�X�e���ɑ��M���邽�߂�CSV�t�@�C�����쐬���܂��B
 *                    
 * MD.050           : MD050_CSO_016_A06_���n-EBS�C���^�[�t�F�[�X�F(OUT)�Y��ړ�����
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
 *  get_profile_info            �v���t�@�C���l�擾 (A-4)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-5)
 *  get_csv_data                CSV�t�@�C���ɏo�͂���֘A���擾 (A-7)
 *  create_csv_rec              CSV�t�@�C���o�� (A-8)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-9)
 *  submain                     ���C�������v���V�[�W��
 *                                �Y��ړ����׃f�[�^���o (A-6)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Syoei.Kin        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         -- �G���[�R�[�h     #�Œ�#
   ,iv_from_value       IN VARCHAR2                 -- �X�V��FROM(YYYYMMDD)
   ,iv_to_value         IN VARCHAR2                 -- �X�V��TO(YYYYMMDD)
  );
END XXCSO016A06C;
/
