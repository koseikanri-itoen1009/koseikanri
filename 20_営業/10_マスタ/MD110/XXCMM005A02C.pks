CREATE OR REPLACE PACKAGE XXCMM005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A02C(spec)
 * Description      : �g�D�}�X�^IF�o�́i���n�j
 * MD.050           : �g�D�}�X�^IF�o�́i���n�j CMM_005_A02
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init_proc            ��������(A-1)
 *
 *  create_aff_date_proc ���擾�v���V�[�W��(A-4)
 *
 *  output_aff_date_proc ��񏑂����݃v���V�[�W��(A-5)
 *
 *  fin_proc             �I�������v���V�[�W��(A-6)
 *
 *  submain              ���C�������v���V�[�W��(A-1�`A-5)
 *                          �E��������(A-1)�Ăяo��
 *                          �E�t�@�C���I�[�v������(A-2)���s
 *                          �E�ŏ�ʕ��匏���擾���f����(A-3)���s
 *                          �E���擾�v���V�[�W��(A-4)�Ăяo��
 *                          �E��񏑂����݃v���V�[�W��(A-5)�Ăяo��
 *
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain(A-1�`A-5)�Ăяo��
 *                          �E�I�������v���V�[�W��(A-6)�Ăяo��
 *                          �EROLLBACK�̎��s���f�{���s
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0  T.Matsumoto       main�V�K�쐬
 *  2009/03/09    1.1  Takuya Kaihara   �v���t�@�C���l���ʉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT    VARCHAR2                                                   -- �G���[���b�Z�[�W #�Œ�#
   ,retcode             OUT    VARCHAR2                                                   -- �G���[�R�[�h     #�Œ�#
  );
  --
END XXCMM005A02C;
/
