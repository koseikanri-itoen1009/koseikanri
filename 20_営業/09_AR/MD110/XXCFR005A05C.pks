CREATE OR REPLACE PACKAGE XXCFR005A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR005A05C(spec)
 * Description      : ���b�N�{�b�N�X��������
 * MD.050           : MD050_CFR_005_A05_���b�N�{�b�N�X��������
 * MD.070           : MD050_CFR_005_A05_���b�N�{�b�N�X��������
 * Version          : 1.00
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
 *  2010/10/14    1.00 SCS �Γn ���a    ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_parallel_type       IN      VARCHAR2,         --   �p���������s�敪
    iv_lmt_of_cnt_flg      IN      VARCHAR2          --   �Ώی���臒l�g�p�t���O
  );
END XXCFR005A05C;
/
