CREATE OR REPLACE PACKAGE APPS.XXCOS007A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS007A03C(spec)
 * Description      : �󒍃N���[�Y�Ώۏ��e�[�u���̏�񂩂�󒍃��[�N���X�g�̃X�e�[�^�X��
 *                    �X�V���܂��B
 * MD.050           : MD050_COS_007_A03_�󒍖���WF�N���[�Y
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-09-01    1.0   Kazuo.Satomura   �V�K�쐬
 *
 *****************************************************************************************/
  --
  -- ���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf     OUT NOCOPY VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    ,retcode    OUT NOCOPY VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    ,in_exe_div IN         NUMBER   -- ���s�敪
  );
  --
END XXCOS007A03C;
/
