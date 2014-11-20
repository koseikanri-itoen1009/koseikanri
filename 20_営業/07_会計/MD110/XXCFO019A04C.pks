CREATE OR REPLACE PACKAGE XXCFO019A04C--��<package_name>�͑啶���ŋL�q���ĉ������B
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A04C.pks
 * Description      : �d�q����AP�d�������̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A04_�d�q����AP�d�������̏��n�V�X�e���A�g
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
 * 2012/08/31     1.0   M.Kitajima       ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode               OUT NOCOPY VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- �ǉ��X�V�敪
    iv_file_name          IN  VARCHAR2,                                       -- �t�@�C����
    it_invoice_num        IN  ap_invoices_all.invoice_num%TYPE,               -- �������ԍ�
    it_invoice_dist_id_fr IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- �������z��ID(From)
    it_invoice_dist_id_to IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- �������z��ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- ����蓮�敪
   );
END XXCFO019A04C;
/
