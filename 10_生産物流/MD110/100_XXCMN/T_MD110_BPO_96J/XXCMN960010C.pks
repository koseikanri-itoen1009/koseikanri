CREATE OR REPLACE PACKAGE XXCMN960010C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN960010C(spec)
 * Description      : �󒍃p�[�W���s
 * MD.050           : T_MD050_BPO_96J_�󒍃p�[�W���s
 * Version          : 1.00
 *
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/04    1.00  SCSK �{�{���� �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCMN960010C;
/
