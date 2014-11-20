CREATE OR REPLACE PACKAGE XXCMM007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM007A01C(spec)
 * Description      : �ڋq�̕W����ʂ�胁���e�i���X���ꂽ���́E�Z�������A
 *                  : �p�[�e�B�A�h�I���}�X�^�֔��f���A���e�̓������s���܂��B
 * MD.050           : ���Y�ڋq��񓯊� MD050_CMM_005_A04
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
 *  2009/02/12    1.0   Masayuki.Sano    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_proc_date_from     IN     VARCHAR2,        --   1.������(FROM)
    iv_proc_date_to       IN     VARCHAR2         --   2.������(TO)
  );
END XXCMM007A01C;
/
