create or replace
PACKAGE XXCFF016A37C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFF016A37C(spec)
 * Description      : �ă��[�X�҃����e�i���X�A�b�v���[�h
 * MD.050           : MD050_CFF_016_A37_�ă��[�X�҃����e�i���X�A�b�v���[�h
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
 *  2015/12/09    1.0   SCSK ���H        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    in_file_id                IN    NUMBER,     --   1.�t�@�C��ID(�K�{)
    iv_file_format            IN    VARCHAR2    --   2.�t�@�C���t�H�[�}�b�g(�K�{)
  );
END XXCFF016A37C;
/
