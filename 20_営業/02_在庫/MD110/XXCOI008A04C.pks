CREATE OR REPLACE PACKAGE XXCOI008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A04C(spec)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS�̕ۊǏꏊ(�W��)��CSV�t�@�C���ɏo��
 * MD.050           : �ۊǏꏊ���n�A�g <MD050_COI_008_A01>
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           �ۊǏꏊ�}�X�^CSV�̍쐬(A-4)
 *  onhand_cur_p           �ۊǏꏊ���̒��o(A-3)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���I�[�v��(A-2)
 *                           �E�t�@�C���N���[�Y(A-5) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   S.Kanda          �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
  );
--
END XXCOI008A04C;
/
