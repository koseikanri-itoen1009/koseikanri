CREATE OR REPLACE PACKAGE XXCMN980003C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCMN980003C(spec)
 * Description      : ���Y�o�b�`�i�W���j�o�b�N�A�b�v
 * MD.050           : T_MD050_BPO_98C_���Y�o�b�`�i�W���j�o�b�N�A�b�v
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/26   1.00  T.Makuta          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_proc_date  IN     VARCHAR2          --   1.������
  );
END XXCMN980003C;
/
