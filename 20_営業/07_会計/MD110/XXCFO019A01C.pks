CREATE OR REPLACE PACKAGE APPS.XXCFO019A01C
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A01C(spec)
 * Description      : �d�q����c���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A01_�d�q����c���̏��n�V�X�e���A�g
 *                    
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
 *  2012-09-26    1.0   K.Onotsuka      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_ins_upd_kbn        IN         VARCHAR2          -- �ǉ��X�V�敪
   ,iv_file_name          IN         VARCHAR2          -- �t�@�C����
   ,iv_period_name_from   IN         VARCHAR2          -- ��v����(From)
   ,iv_period_name_to     IN         VARCHAR2          -- ��v����(To)
   ,iv_exec_kbn           IN         VARCHAR2          -- ����蓮�敪
  );
END XXCFO019A01C;
/
