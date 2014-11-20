CREATE OR REPLACE PACKAGE XXCFO019A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A11C(spec)
 * Description      : �d�q���뎑�Y�Ǘ��̏��n�V�X�e���A�g
 * MD.050           : �d�q���뎑�Y�Ǘ��̏��n�V�X�e���A�g<MD050_CFO_019_A11>
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
 *  2012-09-20    1.0   N.Sugiura      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_ins_upd_kbn           IN     VARCHAR2,         -- 1.�ǉ��X�V�敪
    iv_file_name             IN     VARCHAR2,         -- 2.�t�@�C����
    iv_period_name           IN     VARCHAR2,         -- 3.��v����
    iv_exec_kbn              IN     VARCHAR2          -- 4.����蓮�敪
  );
END XXCFO019A11C;
/
