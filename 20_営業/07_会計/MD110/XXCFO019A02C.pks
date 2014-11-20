CREATE OR REPLACE PACKAGE APPS.XXCFO019A02C
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A02C(spec)
 * Description      : �d�q����d��̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A02_�d�q����d��̏��n�V�X�e���A�g
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
 *  2012-08-29    1.0   K.Onotsuka      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_ins_upd_kbn        IN         VARCHAR2          -- �ǉ��X�V�敪
   ,iv_file_name          IN         VARCHAR2          -- �t�@�C����
   ,iv_period_name        IN         VARCHAR2          -- ��v����
   ,iv_doc_seq_value_from IN         VARCHAR2          -- �d�󕶏��ԍ��iFrom�j
   ,iv_doc_seq_value_to   IN         VARCHAR2          -- �d�󕶏��ԍ��iTo�j
   ,iv_exec_kbn           IN         VARCHAR2          -- ����蓮�敪
  );
END XXCFO019A02C;
/
