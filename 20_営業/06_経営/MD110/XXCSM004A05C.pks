CREATE OR REPLACE PACKAGE XXCSM004A05C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A05C(spec)
 * Description      : ���i�|�C���g�E�V�K�l���|�C���g���n�V�X�e��I/F
 * MD.050           : ���i�|�C���g�E�V�K�l���|�C���g���n�V�X�e��I/F MD050_CSM_004_A05
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  main                �y�R���J�����g���s�t�@�C���o�^�v���V�[�W���z
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   S.son        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT    NOCOPY VARCHAR2,         --   �G���[���b�Z�[�W
    retcode                OUT    NOCOPY VARCHAR2          --   �G���[�R�[�h
  );
END XXCSM004A05C;
/
