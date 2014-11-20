CREATE OR REPLACE PACKAGE XXCFR003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A02C(spec)
 * Description      : �����w�b�_�f�[�^�쐬
 * MD.050           : MD050_CFR_003_A02_�����w�b�_�f�[�^�쐬
 * MD.070           : MD050_CFR_003_A02_�����w�b�_�f�[�^�쐬
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
 *  2008/11/11    1.00 SCS ���� �א�    ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_target_date          IN      VARCHAR2,         -- ����
    iv_bill_acct_code       IN      VARCHAR2,         -- ������ڋq�R�[�h
    iv_batch_on_judge_type  IN      VARCHAR2          -- ��Ԏ蓮���f�敪
  );
END XXCFR003A02C;--(�ύX)
/
