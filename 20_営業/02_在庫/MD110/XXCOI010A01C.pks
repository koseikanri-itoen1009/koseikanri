CREATE OR REPLACE PACKAGE XXCOI010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A01C(body)
 * Description      : �c�ƈ��݌�IF�o��
 * MD.050           : �c�ƈ��݌�IF�o�� MD050_COI_010_A01
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
 *  2008/12/18    1.0   T.Nakamura       �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf          OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
    , retcode         OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    , iv_target_date  IN     VARCHAR2          --   �����Ώۓ�
  );
END XXCOI010A01C;
/
