CREATE OR REPLACE PACKAGE      XXCMM004A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A11C(spec)
 * Description      : �i�ڃ}�X�^IF�o�́i���n�j
 *                      ���ׂĂ̕i�ڂ𒊏o���A���n������CSV�t�@�C����񋟂��܂��B
 * MD.050           : �i�ڃ}�X�^IF�o�́i���n�j CMM_004_A11
 * Version          : Draft2D
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
 *  2008/12/26    1.0   R.Takigawa       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  );
END XXCMM004A11C;
/
