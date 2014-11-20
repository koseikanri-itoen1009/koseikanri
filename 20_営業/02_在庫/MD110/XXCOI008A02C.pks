CREATE OR REPLACE PACKAGE XXCOI008A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A02C(body)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̎��ގ���i�W���j��CSV�t�@�C���ɏo��
 * MD.050           : ���o�ɏ��n�A�g <MD050_COI_008_A02>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_transaction_id     �f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�擾(A-2)
 *  create_csv_p           ���o�Ƀg����CSV�̍쐬(A-5)
 *  recept_month_cur_p     ���ގ�����̒��o(A-4)
 *  upd_transaction_id     �f�[�^�A�g���䃏�[�N�e�[�u���̎��ID�X�V(A-6)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���̃I�[�v������(A-3)
 *                           �E�t�@�C���̃N���[�Y����(A-7) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0   S.Kanda          �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
  );
--
END XXCOI008A02C;
/
