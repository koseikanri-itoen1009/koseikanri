CREATE OR REPLACE PACKAGE APPS.XXCOP003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP003A01C(spec)
 * Description      : �A�b�v���[�h�t�@�C������̎捞�i�����Z�b�g�j
 * MD.050           : �A�b�v���[�h�t�@�C������̎捞�i�����Z�b�g�j MD050_COP_003_A01
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
 *  2008/11/11    1.0   Y.Goto           �V�K�쐬
 *  2009/02/25    1.1   SCS.Uda          �����e�X�g�d�l�ύX�i������QNo.016,017�j
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id    IN     NUMBER,           --   �t�@�C��ID
    iv_format     IN     VARCHAR2          --   �t�@�C����������
  );
END XXCOP003A01C;
/
