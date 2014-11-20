/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_021A02_HEADERS_V
 * Description : �≮�������Ϗ��˂����킹��ʁi�w�b�_�j�r���[
 * Version     : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *  2009/02/02    1.1   K.Yamaguchi      [��QCOK_004] ���o�����ɉc�ƒP�ʂ�ǉ�
 *                                       [��QCOK_004] ���o�����Ɏd����T�C�g�}�X�^�̖�������ǉ�
 *  2010/02/23    1.2   K.Yamaguchi      [E_�{�ғ�_01176] ������ʂ̎擾���ύX
 *  2012/03/08    1.3   S.Niki           [E_�{�ғ�_08315] �w�b�_�ɔ���Ώ۔N����ǉ�
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_021a02_headers_v(
  row_id
, wholesale_bill_header_id
, base_code
, base_name
, cust_code
, cust_name
, wholesale_ctrl_code
, wholesale_ctrl_name
, expect_payment_date
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD START
, selling_month
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD END
, supplier_code
, supplier_name
, bank_name
, bank_branch_name
, bank_account_type_name
, bank_account_num
, management_base_code
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
SELECT xwbh.ROWID                       AS row_id                     -- ROW_ID
     , xwbh.wholesale_bill_header_id    AS wholesale_bill_header_id   -- �≮�������w�b�_ID
     , xwbh.base_code                   AS base_code                  -- ���_�R�[�h
     , hp1.party_name                   AS base_name                  -- ���_��
     , xwbh.cust_code                   AS cust_code                  -- �ڋq�R�[�h
     , hp2.party_name                   AS cust_name                  -- �ڋq��
     , xca2.wholesale_ctrl_code         AS wholesale_ctrl_code        -- �≮�Ǘ��R�[�h
     , flv.meaning                      AS wholesale_ctrl_name        -- �≮�Ǘ���
     , xwbh.expect_payment_date         AS expect_payment_date        -- �x���\���
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD START
     , line.selling_month               AS selling_month              -- ����Ώ۔N��
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD END
     , xwbh.supplier_code               AS supplier_code              -- �d����R�[�h
     , pv.vendor_name                   AS supplier_name              -- �d���於
     , abb.bank_name                    AS bank_name                  -- �U����s��
     , abb.bank_branch_name             AS bank_branch_name           -- �x�X��
     , hl.meaning                       AS bank_account_type_name     -- ���
     , abaa.bank_account_num            AS bank_account_num           -- �����ԍ�
     , xca1.management_base_code        AS management_base_code       -- �Ǘ������_�R�[�h
     , xwbh.created_by                  AS created_by                 -- �쐬��
     , xwbh.creation_date               AS creation_date              -- �쐬��
     , xwbh.last_updated_by             AS last_updated_by            -- �ŏI�X�V��
     , xwbh.last_update_date            AS last_update_date           -- �ŏI�X�V��
     , xwbh.last_update_login           AS last_update_login          -- �ŏI�X�V���O�C��
FROM xxcok_wholesale_bill_head     xwbh      -- �≮�������w�b�_�e�[�u��
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD START
   , ( SELECT xwbl.wholesale_bill_header_id      AS wholesale_bill_header_id  -- �≮�������w�b�_ID
            , xwbl.selling_month                 AS selling_month             -- ����Ώ۔N��
       FROM   xxcok_wholesale_bill_line  xwbl  -- �≮���������׃e�[�u��
       GROUP BY xwbl.wholesale_bill_header_id
              , xwbl.selling_month
     )                             line      -- �≮���������׃e�[�u��
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD END
   , hz_cust_accounts              hca1      -- �ڋq�}�X�^�i���_�j
   , hz_cust_accounts              hca2      -- �ڋq�}�X�^�i�ڋq�j
   , hz_parties                    hp1       -- �p�[�e�B�}�X�^�i���_�j
   , hz_parties                    hp2       -- �p�[�e�B�}�X�^�i�ڋq�j
   , xxcmm_cust_accounts           xca2      -- �ڋq�ǉ����i�ڋq�j
   , xxcmm_cust_accounts           xca1      -- �ڋq�ǉ����i���_�j
   , fnd_lookup_values             flv       -- �N�C�b�N�R�[�h�i�≮�Ǘ��R�[�h�j
   , po_vendors                    pv        -- �d����}�X�^
   , po_vendor_sites_all           pvsa      -- �d����T�C�g�}�X�^
   , ap_bank_account_uses_all      abaua     -- ��s�����g�p���
   , ap_bank_accounts_all          abaa      -- ��s�����}�X�^
   , ap_bank_branches              abb       -- ��s�x�X�}�X�^
   , hr_lookups                    hl        -- �N�C�b�N�R�[�h�i������ʁj
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki MOD START
--WHERE xwbh.base_code                    = hca1.account_number
WHERE line.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
  AND xwbh.base_code                    = hca1.account_number
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki MOD END
  AND xwbh.cust_code                    = hca2.account_number
  AND hca1.party_id                     = hp1.party_id
  AND hca2.party_id                     = hp2.party_id
  AND hca1.cust_account_id              = xca1.customer_id
  AND hca2.cust_account_id              = xca2.customer_id
  AND xca2.wholesale_ctrl_code          = flv.lookup_code
  AND flv.lookup_type                   = 'XXCMM_TONYA_CODE'
  AND flv.language                      = USERENV( 'LANG' )
  AND xwbh.supplier_code                = pv.segment1
  AND pv.vendor_id                      = pvsa.vendor_id
  AND pvsa.vendor_id                    = abaua.vendor_id
  AND pvsa.vendor_site_id               = abaua.vendor_site_id
  AND abaua.external_bank_account_id    = abaa.bank_account_id
  AND abaa.bank_branch_id               = abb.bank_branch_id
  AND abaa.bank_account_type            = hl.lookup_code
  AND abaua.primary_flag                = 'Y'
  AND ( abaua.start_date <= xxccp_common_pkg2.get_process_date OR abaua.start_date IS NULL )
  AND ( abaua.end_date   >= xxccp_common_pkg2.get_process_date OR abaua.end_date   IS NULL )
-- 2010/02/23 Ver.1.2 [E_�{�ғ�_01176] SCS K.Yamaguchi REPAIR START
--  AND hl.lookup_type                    = 'JP_BANK_ACCOUNT_TYPE'
  AND hl.lookup_type                    = 'XXCSO1_KOZA_TYPE'
-- 2010/02/23 Ver.1.2 [E_�{�ғ�_01176] SCS K.Yamaguchi REPAIR END
  AND pvsa.org_id                       = abaua.org_id
  AND pvsa.org_id                       = abaa.org_id
  AND pvsa.org_id                       = TO_NUMBER( FND_PROFILE.VALUE( 'ORG_ID' ) )
  AND ( pvsa.inactive_date > xxccp_common_pkg2.get_process_date OR pvsa.inactive_date IS NULL )
/
COMMENT ON TABLE  apps.xxcok_021a02_headers_v                              IS '�≮�������Ϗ��˂����킹��ʁi�w�b�_�j�r���['
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.row_id                       IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_bill_header_id     IS '�≮�������w�b�_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.base_code                    IS '���_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.base_name                    IS '���_��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.cust_code                    IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.cust_name                    IS '�ڋq��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_ctrl_code          IS '�≮�Ǘ��R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.wholesale_ctrl_name          IS '�≮�Ǘ���'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.expect_payment_date          IS '�x���\���'
/
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD START
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.selling_month                IS '����Ώ۔N��'
/
-- 2012/03/08 Ver.1.3 [��QE_�{�ғ�_08315] SCSK S.Niki ADD END
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.supplier_code                IS '�d����R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.supplier_name                IS '�d���於'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_name                    IS '�U����s��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_branch_name             IS '�x�X��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_account_type_name       IS '���'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.bank_account_num             IS '�����ԍ�'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.management_base_code         IS '�Ǘ������_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.created_by                   IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.creation_date                IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_updated_by              IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_update_date             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_021a02_headers_v.last_update_login            IS '�ŏI�X�V���O�C��'
/
