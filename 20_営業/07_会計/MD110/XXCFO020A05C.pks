CREATE OR REPLACE PACKAGE XXCFO020A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A05C(spec)
 * Description      : �󕥁i�o�ׁj�d��IF�쐬
 * MD.050           : �󕥁i�o�ׁj�d��IF�쐬<MD050_CFO_020_A05>
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
 *  2014-10-03    1.0   SCSK Y.Shoji     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_period_name      IN     VARCHAR2          -- 1.��v����
  );
END XXCFO020A05C;
/
