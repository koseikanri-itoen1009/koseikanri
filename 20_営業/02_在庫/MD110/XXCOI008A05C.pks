CREATE OR REPLACE PACKAGE XXCOI008A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI008A05C(spec)
 * Description      : ���n�V�X�e���ւ̘A�g�ׁ̈AEBS��VD�R�����}�X�^(�A�h�I��)��CSV�t�@�C���ɏo��
 * MD.050           : VD�R�����}�X�^���n�A�g <MD050_COI_008_A05>
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_csv_p           VD�R�����}�X�^CSV�̍쐬(A-4)
 *  onhand_cur_p           VD�R�����}�X�^���̒��o(A-3)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���I�[�v��(A-2)
 *                           �E�t�@�C���N���[�Y(A-5) 
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   S.Kanda          �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,      --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
  );
--
END XXCOI008A05C;
/
