CREATE OR REPLACE PACKAGE XXCSM002A14C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A14C(spec)
 * Description      : ���i�v��w�b�_�e�[�u���A�y�я��i�v�斾�׃e�[�u�����
 *                    �Ώۗ\�Z�N�x�̏��i�v��f�[�^�𒊏o���A���n�V�X�e����
 *                    �A�g���邽�߂�I/F�t�@�C�����쐬���܂��B
 * MD.050           : MD050_CSM_002_A14_�N�ԏ��i�v����n�V�X�e��IF
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   T.Shimoji        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSM002A14C;
/
