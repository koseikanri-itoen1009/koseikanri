CREATE OR REPLACE PACKAGE XXCSM004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A04C(spec)
 * Description      : �ڋq�}�X�^����V�K�l�������ڋq�𒊏o���A�V�K�l���|�C���g�ڋq�ʗ����e�[�u��
 *                  : �Ƀf�[�^��o�^���܂��B
 * MD.050           : �V�K�l���|�C���g�W�v�i�V�K�l���|�C���g�W�v�����jMD050_CSM_004_A04
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-27    1.0   n.izumi          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCSM004A04C;
/
