CREATE OR REPLACE PACKAGE XXCMM004A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A12C(spec)
 * Description      : �i�ڃ}�X�^IF�o�́iHHT�j
 *                      �c�ƕi�ڂƂ��ēo�^���ꂽ�i�ځi�J�e�S���}�X�^�̏��i���i�敪��2:���i�j�݂̂𒊏o���A
 *                      HHT������CSV�t�@�C����񋟂��܂��B
 * MD.050           : �i�ڃ}�X�^IF�o�́iHHT�j CMM_004_A12
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
 *  2008/12/25    1.0  R.Takigawa       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_date_from   IN     VARCHAR2         --   �ŏI�X�V���i�J�n�j
   ,iv_date_to     IN     VARCHAR2         --   �ŏI�X�V���i�I���j
  );
END XXCMM004A12C;
/
