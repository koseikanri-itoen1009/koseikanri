CREATE OR REPLACE PACKAGE XXCSO015A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A04C(spec)
 * Description      : ���_�������ɂ��ڋq�}�X�^�̋��_�R�[�h���ύX�ɂȂ��������𕨌��}�X�^���璊�o���A
 *                        ���̋@�Ǘ��V�X�e���ɘA�g���܂��B
 *                    
 * MD.050           : MD050_CSO_015_A04_���̋@-EBS�C���^�t�F�[�X�F�iOUT�j�����}�X�^���
 *                    
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  get_profile_info            �v���t�@�C���l�擾 (A-2)
 *  open_csv_file               CSV�t�@�C���I�[�v�� (A-3)
 *  chk_str                     �֑������`�F�b�N (A-6,A-10)
 *  create_csv_rec              CSV�t�@�C���o�� (A-8,A-13)
 *  update_wk_reqst_tbl         ��ƈ˗��^������񏈗����ʃe�[�u���X�V(A-12)
 *  close_csv_file              CSV�t�@�C���N���[�Y���� (A-14)
 *  submain                     ���C�������v���V�[�W��
 *                                �Z�[�u�|�C���g(�t�@�C���N���[�Y���s�p)���s(A-4)
 *                                ���_�ύX�����}�X�^��񒊏o (A-5)
 *                                �p����ƈ˗����f�[�^���o(A-9)
 *                                �Z�[�u�|�C���g(�p����ƈ˗����A�g���s)���s(A-11)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-28    1.0   kyo              �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT NOCOPY VARCHAR2         -- �G���[�R�[�h     #�Œ�#
   ,iv_csv_process_kbn  IN VARCHAR2                 -- ���_�ύX�E�p�����CSV�o�͏����敪
   ,iv_date_value       IN VARCHAR2                 -- �������t
  );
END XXCSO015A04C;
/
