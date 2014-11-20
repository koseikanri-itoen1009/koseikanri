CREATE OR REPLACE PACKAGE XXCFO019A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A10C(spec)
 * Description      : �d�q���냊�[�X����̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A10_�d�q���냊�[�X����̏��n�V�X�e���A�g
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
 *  2012-09-20    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf           OUT VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
    , retcode          OUT VARCHAR2         -- �G���[�R�[�h     #�Œ�#
    , iv_ins_upd_kbn   IN  VARCHAR2         -- �ǉ��X�V�敪
    , iv_file_name     IN  VARCHAR2         -- �t�@�C����
    , iv_period_name   IN  VARCHAR2         -- ��v����
    , iv_exec_kbn      IN  VARCHAR2         -- ����蓮�敪
  );
END XXCFO019A10C;
/
