CREATE OR REPLACE PACKAGE XXCFO002A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2013. All rights reserved.
 *
 * Package Name     : XXCFO002A02C(spec)
 * Description      : �����F�o��x���˗��f�[�^���o
 * MD.050           : �����F�o��x���˗��f�[�^���o MD050_CFO_002_A02
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
 *  2013/09/13    1.0  SCSK ���� �O��    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_invoice_date_from  IN     VARCHAR2,         --   ���������t(from)
    iv_invoice_date_to    IN     VARCHAR2          --   ���������t(to)
  );
END XXCFO002A02C;
/
