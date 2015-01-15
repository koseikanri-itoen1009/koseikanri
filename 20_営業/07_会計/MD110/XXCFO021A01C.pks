CREATE OR REPLACE PACKAGE XXCFO021A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO021A02C(spec)
 * Description      : �d�q����󕥂��̑����ю���̏��n�V�X�e���A�g
 * MD.050           : �d�q����󕥂��̑����ю���̏��n�V�X�e���A�g<MD050_CFO_021_A01>
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
 *  2014-10-20    1.0   A.Uchida        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name             IN     VARCHAR2,         -- 1.�t�@�C����
    iv_period_name           IN     VARCHAR2,         -- 2.��v����
    iv_exec_kbn              IN     VARCHAR2          -- 3.����蓮�敪
  );
END XXCFO021A01C;
/
