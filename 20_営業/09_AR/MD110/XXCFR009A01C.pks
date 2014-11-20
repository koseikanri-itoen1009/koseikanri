CREATE OR REPLACE PACKAGE XXCFR009A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR009A01C(spec)
 * Description      : �c�ƈ��ʕ����ʓ����\��\
 * MD.050           : MD050_CFR_009_A01_�c�ƈ��ʕ����ʓ����\��\
 * MD.070           : MD050_CFR_009_A01_�c�ƈ��ʕ����ʓ����\��\
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
 *  2008/11/17    1.00 SCS ���� ��      ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         --    �G���[���b�Z�[�W #�Œ�#
    retcode                OUT     VARCHAR2,         --    �G���[�R�[�h     #�Œ�#
--    ��IN �����Ұ�������ꍇ�͓K�X�ҏW���ĉ������B
    iv_receive_base_code   IN      VARCHAR2,         --    �������_
    iv_sales_rep           IN      VARCHAR2,         --    �c�ƒS����
    iv_due_date_from       IN      VARCHAR2,         --    �x������(FROM)
    iv_due_date_to         IN      VARCHAR2,         --    �x������(TO)
    iv_receipt_class1      IN      VARCHAR2,         --    �����敪�P
    iv_receipt_class2      IN      VARCHAR2,         --    �����敪�Q
    iv_receipt_class3      IN      VARCHAR2,         --    �����敪�R
    iv_receipt_class4      IN      VARCHAR2,         --    �����敪�S
    iv_receipt_class5      IN      VARCHAR2          --    �����敪�T
  );
END XXCFR009A01C;--(�ύX)
/
