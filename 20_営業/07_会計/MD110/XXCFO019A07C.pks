CREATE OR REPLACE PACKAGE XXCFO019A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A07C(spec)
 * Description      : �d�q����AR�����̏��n�V�X�e���A�g
 * MD.050           : �d�q����AR�����̏��n�V�X�e���A�g<MD050_CFO_019_A07>
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
 *  2012-09-07    1.0   N.Sugiura      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                  OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_ins_upd_kbn           IN     VARCHAR2,         -- 1.�ǉ��X�V�敪
    iv_file_name             IN     VARCHAR2,         -- 2.�t�@�C����
    iv_id_from               IN     VARCHAR2,         -- 3.��������ID�iFrom�j
    iv_id_to                 IN     VARCHAR2,         -- 4.��������ID�iTo�j
    iv_doc_seq_value         IN     VARCHAR2,         -- 5.���������ԍ�
    iv_exec_kbn              IN     VARCHAR2          -- 6.����蓮�敪
  );
END XXCFO019A07C;
/
