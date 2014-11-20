CREATE OR REPLACE PACKAGE XXCFO019A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A09C(spec)
 * Description      : �d�q����݌ɊǗ��̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A09_�d�q����݌ɊǗ��̏��n�V�X�e���A�g
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
 *  2012-08-31    1.0   K.Nakamura       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf           OUT VARCHAR2         -- �G���[���b�Z�[�W #�Œ�#
    , retcode          OUT VARCHAR2         -- �G���[�R�[�h     #�Œ�#
    , iv_ins_upd_kbn   IN  VARCHAR2         -- �ǉ��X�V�敪
    , iv_file_name     IN  VARCHAR2         -- �t�@�C����
    , iv_tran_id_from  IN  VARCHAR2         -- ���ގ��ID�iFrom�j
    , iv_tran_id_to    IN  VARCHAR2         -- ���ގ��TO�iTo�j
    , iv_batch_id_from IN  VARCHAR2         -- GL�o�b�`ID�iFrom�j
    , iv_batch_id_to   IN  VARCHAR2         -- GL�o�b�`ID�iTo�j
    , iv_exec_kbn      IN  VARCHAR2         -- ����蓮�敪
  );
END XXCFO019A09C;
/
