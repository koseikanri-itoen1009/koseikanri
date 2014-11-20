CREATE OR REPLACE PACKAGE XXCOI008A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A01C(spec)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̎莝����(�W��)��CSV�t�@�C���ɏo��
 * MD.050           : �莝���ʏ��n�A�g <MD050_COI_008_A01>
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           �莝����CSV�̍쐬(A-5)
 *  onhand_cur_p           �莝���ʏ��̒��o(A-4)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���I�[�v��(A-3)
 *                           �E�t�@�C���N���[�Y(A-6) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.0   S.Kanda          �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
  );
--
END XXCOI008A01C;
/
