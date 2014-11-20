CREATE OR REPLACE FORCE VIEW XXCFR_RECEIPT_CUST_ACCOUNTS_V (
/*************************************************************************
 * 
 * View Name       : XXCFR_RECEIPT_CUST_ACCOUNTS_V
 * Description     : ������ڋq�r���[�i�x���ʒm�f�[�^�_�E�����[�h�p�j
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/11/27    1.0  SCS ���� ��   ����쐬
 ************************************************************************/
  type,                                   -- �^�C�v
  account_number,                         -- �ڋq�R�[�h
  party_name                              -- �ڋq��
) AS
-- �G���[�f�[�^���o�p
SELECT '1'                type,           -- �^�C�v
       'Error'            account_number, -- �ڋq�R�[�h
       '�G���['           party_name      -- �ڋq��
  FROM dual
UNION
SELECT 
       '2'                  type                         -- �^�C�v
      ,cash_account_number                               --������ڋq�R�[�h    �F(������ڋq)
      ,xxcfr_common_pkg.get_cust_account_name(cash_account_number, 0) --������ڋq����      �F(������ڋq)
  FROM (
    --�@������ڋq�i���|���Ǘ���ڋq�j
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --������ڋqID        �F(������ڋq)
          ,hca.account_number        cash_account_number     --������ڋq�R�[�h    �F(������ڋq)
    FROM
         hz_cust_accounts          hca              --������ڋq�}�X�^
        ,hz_cust_acct_sites_all    hcasa            --������ڋq���ݒn
        ,hz_cust_site_uses_all     hcsua            --������ڋq�g�p�ړI
        ,hz_customer_profiles      hcp              --������ڋq�v���t�@�C��
    WHERE 
          hca.customer_class_code = '14'                        --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara           --�ڋq�֘A�}�X�^(�����֘A)
                WHERE hcara.related_cust_account_id = hca.cust_account_id   --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
                  AND hcara.status                  = 'A'                   --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                  AND hcara.attribute1              = '2'                   --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --������ڋq���ݒn.�g�DID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
      AND hcsua.site_use_code     = 'BILL_TO'                   --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
      AND hca.cust_account_id     = hcp.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq�v���t�@�C��.�ڋqID
      AND hcp.site_use_id         IS NULL                       --������ڋq�v���t�@�C��.�g�p�ړI IS NULL
    UNION ALL
    --�A������ڋq��������ڋq���o�א�ڋq
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --������ڋqID        �F(������ڋq)
          ,hca.account_number        cash_account_number     --������ڋq�R�[�h    �F(������ڋq)
    FROM 
         hz_cust_accounts          hca              --�o�א�ڋq�}�X�^�@��������E������܂�
        ,hz_cust_acct_sites_all    hcasa            --������ڋq���ݒn
        ,hz_cust_site_uses_all     hcsua            --������ڋq�g�p�ړI
        ,hz_customer_profiles      hcp              --������ڋq�v���t�@�C��
    WHERE 
          hca.customer_class_code = '10'                        --������ڋq.�ڋq�敪 = '10'(�ڋq)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara2           --�ڋq�֘A�}�X�^
                WHERE 
                     (hcara2.cust_account_id         = hca.cust_account_id   --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                   OR hcara2.related_cust_account_id = hca.cust_account_id)  --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
                  AND hcara2.status                  = 'A'                   --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --������ڋq���ݒn.�g�DID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
      AND hcsua.site_use_code     = 'BILL_TO'                   --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
      AND hca.cust_account_id     = hcp.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq�v���t�@�C��.�ڋqID
      AND hcp.site_use_id         IS NULL                       --������ڋq�v���t�@�C��.�g�p�ړI IS NULL
  )  xxcfr_receipt_cust_account
;
--
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.type                IS '�^�C�v';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.account_number      IS '�ڋq�R�[�h';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.party_name          IS '�ڋq��';
--
COMMENT ON TABLE  xxcfr_receipt_cust_accounts_v IS '������ڋq�r���[�i�x���ʒm�f�[�^�_�E�����[�h�p�j';
