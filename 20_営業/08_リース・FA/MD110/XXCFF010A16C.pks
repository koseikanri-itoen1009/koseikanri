CREATE OR REPLACE PACKAGE XXCFF010A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF010A16(spec)
 * Description      : ���[�X�d��쐬
 * MD.050           : MD050_CFF_010_A16_���[�X�d��쐬
 * Version          : 1.00
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
 *  2009/01/05    1.00  SCS�n�ӊw        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_period_name IN     VARCHAR2          -- 1.��v���Ԗ�
  );
END XXCFF010A16C;
/
