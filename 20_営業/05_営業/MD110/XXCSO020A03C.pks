CREATE OR REPLACE PACKAGE APPS.XXCSO020A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A03C(spec)
 * Description      : �t���x���_�[�p�r�o�ꌈ�E�o�^��ʂɂ���ēo�^���ꂽ�V�K�ڋq�����ڋq
 *                    �}�X�^�A�_���}�X�^�ɓo�^���܂��B�܂��A�t���x���_�[�p�r�o�ꌈ�E�o�^
 *                    ��ʂɂĕύX���ꂽ�����ڋq�����ڋq�}�X�^�ɔ��f���܂��B
 * MD.050           : MD050_CSO_020_A03_�e��}�X�^���f�����@�\
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuo.Satomura   �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
  --
  --���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT NOCOPY VARCHAR2                                             -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                  OUT NOCOPY VARCHAR2                                             -- �G���[�R�[�h     #�Œ�#
   ,it_sp_decision_header_id IN         xxcso_sp_decision_headers.sp_decision_header_id%TYPE -- �r�o�ꌈ�w�b�_�h�c
   ,ot_cust_account_id       OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE                -- �ڋq�h�c
   ,ot_contract_customer_id  OUT NOCOPY xxcso_contract_customers.contract_customer_id%TYPE   -- �_���h�c
  );
  --
END XXCSO020A03C;
/
