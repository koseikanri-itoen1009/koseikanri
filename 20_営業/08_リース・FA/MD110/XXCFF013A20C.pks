CREATE OR REPLACE PACKAGE XXCFF013A20C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A20(spec)
 * Description      : FA�A�h�I��IF
 * MD.050           : MD050_CFF_013_A20_FA�A�h�I��IF
 * Version          : 1.12
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
 *  2008/12/01    1.00  SCS�n�ӊw        �V�K�쐬
 *  2018/09/07    1.12  SCSK���H         [E_�{�ғ�_14830]IFRS���[�X�ǉ��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    iv_period_name IN     VARCHAR2          -- 1.��v���Ԗ�
    iv_period_name    IN     VARCHAR2,      -- 1.��v���Ԗ�
    iv_book_type_code IN     VARCHAR2       -- 2.�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
  );
END XXCFF013A20C;
/
