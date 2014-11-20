CREATE OR REPLACE PACKAGE XXCFO019A05C--��<package_name>�͑啶���ŋL�q���ĉ������B
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A05C.pks
 * Description      : �d�q����AP�x���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A05_�d�q����AP�x���̏��n�V�X�e���A�g
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
 * 2012/09/25     1.0   M.Kitajima       ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- �ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2,                                       -- �t�@�C����
    it_doc_sequence_val   IN  ap_checks_all.doc_sequence_value%TYPE,          -- �؜ߔԍ�
    it_invoice_pay_id_fr  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- �����x��ID(From)
    it_invoice_pay_id_to  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- �����x��ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- ����蓮�敪
   );
END XXCFO019A05C;
/
