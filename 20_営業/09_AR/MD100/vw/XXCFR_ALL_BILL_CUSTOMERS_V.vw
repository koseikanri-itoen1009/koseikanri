CREATE OR REPLACE VIEW xxcfr_all_bill_customers_v
/*************************************************************************
 * 
 * View Name       : XXCFR_ALL_BILL_CUSTOMERS_V
 * Description     : 請求先顧客ビューALL
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2009/12/24    1.0  SCS 安川 智博   初回作成
 ************************************************************************/
(
  customer_id,                       -- 顧客ID
  customer_code,                     -- 顧客コード
  customer_name,                     -- 顧客名
  receiv_code1,                      -- 売掛コード1
  inv_prt_type,                      -- 請求書出力形式
  cons_inv_flag                      -- 一括請求書発行フラグ
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

COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_id            IS '顧客ID';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_code          IS '顧客コード';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.customer_name          IS '顧客名';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.receiv_code1           IS '売掛コード1';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.inv_prt_type           IS '請求書出力形式';
COMMENT ON COLUMN  xxcfr_all_bill_customers_v.cons_inv_flag          IS '一括請求書発行フラグ';

COMMENT ON TABLE  xxcfr_all_bill_customers_v IS '請求先顧客ビューALL';
