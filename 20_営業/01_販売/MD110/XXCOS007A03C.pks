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
 * Version          : 1.1
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
 *  2009/09/01    1.0   K.Satomura       �V�K�쐬
 *  2010/08/24    1.1   S.Miyakoshi      [E_�{�ғ�_01763] INV�ւ̔̔����јA�g�̓������Ή�(���̓p�����[�^�F�v��ID�̒ǉ�)
 *
 *****************************************************************************************/
  --
  -- ���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf     OUT NOCOPY VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    ,retcode    OUT NOCOPY VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    ,in_exe_div IN         NUMBER   -- ���s�敪
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD START ************************ --
    ,in_request_id IN      NUMBER   -- �v��ID
-- ************************ 2010/08/24 S.Miyakoshi Var1.1 ADD  END  ************************ --
  );
  --
END XXCOS007A03C;
/
