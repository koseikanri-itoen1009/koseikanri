CREATE OR REPLACE PACKAGE XXCFR004A02C--(�ύX)
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR004A02C(spec)
 * Description      : �x���ʒm�f�[�^�_�E�����[�h
 * MD.050           : MD050_CFR_004_A02_�x���ʒm�f�[�^�_�E�����[�h
 * MD.070           : MD050_CFR_004_A02_�x���ʒm�f�[�^�_�E�����[�h
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
 *  2008/11/19    1.00 SCS ���� ��      ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         --    �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_receipt_cust_code   IN      VARCHAR2,         --    ������ڋq
    iv_due_date_from       IN      VARCHAR2,         --    �x���N����(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x���N����(TO)
    iv_received_date_from  IN      VARCHAR2,         --    ��M��(FROM)
    iv_received_date_to    IN      VARCHAR2          --    ��M��(TO)
  );
END XXCFR004A02C;--(�ύX)
/
