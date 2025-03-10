CREATE OR REPLACE VIEW xxcfr_all_bill_customers_v
/*************************************************************************
 * 
 * View Name       : XXCFR_ALL_BILL_CUSTOMERS_V
 * Description     : ¿æÚqr[ALL
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2009/12/24    1.0  SCS Àì q   ñì¬
 ************************************************************************/
(
  customer_id,                       -- ÚqID
  customer_code,                     -- ÚqR[h
  customer_name,                     -- Úq¼
  receiv_code1,                      -- |R[h1
  inv_prt_type,                      -- ¿oÍ`®
  cons_inv_flag                      -- ê¿­stO
)
AS
  SELECT hzca.cust_account_id customer_id
        ,hzca.account_number customer_code
        ,hzpa.party_name customer_name
        ,hcsu.attribute4 receiv_code1
        ,hcsu.attribute7 inv_prt_type
        ,hzcp.cons_inv_flag cons_inv_flag
  FROM hz_cust_accounts hzca
      ,hz_parties hzpa
      ,hz_cust_acct_sites hcas
      ,hz_cust_site_uses hcsu
      ,hz_customer_profiles hzcp
  WHERE hzca.party_id = hzpa.party_id
  AND   hzca.cust_account_id = hcas.cust_account_id
  AND   hcas.cust_acct_site_id = hcsu.cust_acct_site_id
  AND   hcsu.site_use_code = 'BILL_TO'
  AND   hcsu.primary_flag = 'Y'
  AND   hcsu.status = 'A'
  AND   hcsu.site_use_id = hzcp.site_use_id
  AND   hzca.cust_account_id = hzcp.cust_account_id
;

COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_id            IS 'ÚqID';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_code          IS 'ÚqR[h';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_name          IS 'Úq¼';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.receiv_code1           IS '|R[h1';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.inv_prt_type           IS '¿oÍ`®';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.cons_inv_flag          IS 'ê¿­stO';

COMMENT ON TABLE  xxcfr_all_bill_customers_v IS '¿æÚqr[ALL';
