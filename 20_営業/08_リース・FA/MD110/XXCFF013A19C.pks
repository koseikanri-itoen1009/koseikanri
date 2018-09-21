create or replace
PACKAGE XXCFF013A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A19C(spec)
 * Description      : ���[�X�_�񌎎��X�V
 * MD.050           : MD050_CFF_013_A19_���[�X�_�񌎎��X�V
 * Version          : 1.6
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
 *  2008/12/12    1.0   SCS ���c         �V�K�쐬
 *  2018/09/07    1.6   SCSK ���H        [E_�{�ғ�_14830]IFRS�ǉ��Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--    iv_period_name   IN    VARCHAR2         -- 1.��v���Ԗ�
    iv_period_name    IN   VARCHAR2,        -- 1.��v���Ԗ�
    iv_book_type_code IN   VARCHAR2         -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
  );
END XXCFF013A19C;
/
