CREATE OR REPLACE FORCE VIEW XXCFR_RECEIPT_CUST_ACCOUNTS_V (
/*************************************************************************
 * 
 * View Name       : XXCFR_RECEIPT_CUST_ACCOUNTS_V
 * Description     : üàæÚqr[ix¥Êmf[^_E[hpj
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/11/27    1.0  SCS º    ñì¬
 *  2010/01/29    1.1  SCS Àì q áQuE__{Ò®_01503vÎ
 ************************************************************************/
  type,                                   -- ^Cv
  account_number,                         -- ÚqR[h
  party_name                              -- Úq¼
) AS
-- G[f[^op
SELECT '1'                type,           -- ^Cv
       'Error'            account_number, -- ÚqR[h
       'G['           party_name      -- Úq¼
  FROM dual
UNION
SELECT 
       '2'                  type                         -- ^Cv
      ,cash_account_number                               --üàæÚqR[h    F(üàæÚq)
      ,xxcfr_common_pkg.get_cust_account_name(cash_account_number, 0) --üàæÚq¼Ì      F(üàæÚq)
  FROM (
    --@üàæÚqi|àÇæÚqj
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --üàæÚqID        F(üàæÚq)
          ,hca.account_number        cash_account_number     --üàæÚqR[h    F(üàæÚq)
    FROM
         hz_cust_accounts          hca              --¿æÚq}X^
        ,hz_cust_acct_sites_all    hcasa            --¿æÚqÝn
        ,hz_cust_site_uses_all     hcsua            --¿æÚqgpÚI
        ,hz_customer_profiles      hcp              --¿æÚqvt@C
    WHERE 
          hca.customer_class_code = '14'                        --¿æÚq.Úqæª = '14'(|ÇæÚq)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara           --ÚqÖA}X^(üàÖA)
                WHERE hcara.related_cust_account_id = hca.cust_account_id   --ÚqÖA}X^(üàÖA).ÖAæÚqID = ¿æÚq}X^.ÚqID
                  AND hcara.status                  = 'A'                   --ÚqÖA}X^(üàÖA).Xe[^X = eAf
                  AND hcara.attribute1              = '2'                   --ÚqÖA}X^(üàÖA).ÖAªÞ = e2f (üà)
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --¿æÚqÝn.gDID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
      AND hcsua.site_use_code     = 'BILL_TO'                   --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
-- Add 2010/01/29 Yasukawa Start
      AND hcsua.status            = 'A'                         --¿æÚqgpÚI.Xe[^X = 'A'
-- Add 2010/01/29 Yasukawa End
      AND hca.cust_account_id     = hcp.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqvt@C.ÚqID
      AND hcp.site_use_id         IS NULL                       --¿æÚqvt@C.gpÚI IS NULL
    UNION ALL
    --AüàæÚq¿æÚqo×æÚq
    SELECT DISTINCT
           hca.cust_account_id       cash_account_id         --üàæÚqID        F(üàæÚq)
          ,hca.account_number        cash_account_number     --üàæÚqR[h    F(üàæÚq)
    FROM 
         hz_cust_accounts          hca              --o×æÚq}X^@¦üàæE¿æÜÞ
        ,hz_cust_acct_sites_all    hcasa            --¿æÚqÝn
        ,hz_cust_site_uses_all     hcsua            --¿æÚqgpÚI
        ,hz_customer_profiles      hcp              --¿æÚqvt@C
    WHERE 
          hca.customer_class_code = '10'                        --¿æÚq.Úqæª = '10'(Úq)
      AND NOT EXISTS (
                SELECT ROWNUM
                FROM hz_cust_acct_relate_all hcara2           --ÚqÖA}X^
                WHERE 
                     (hcara2.cust_account_id         = hca.cust_account_id   --ÚqÖA}X^(¿ÖA).ÚqID = o×æÚq}X^.ÚqID
                   OR hcara2.related_cust_account_id = hca.cust_account_id)  --ÚqÖA}X^(¿ÖA).ÖAæÚqID = o×æÚq}X^.ÚqID
                  AND hcara2.status                  = 'A'                   --ÚqÖA}X^(¿ÖA).Xe[^X = eAf
              )
      AND hca.cust_account_id     = hcasa.cust_account_id       --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
      AND hcasa.org_id            = fnd_profile.value('ORG_ID') --¿æÚqÝn.gDID = 
      AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
      AND hcsua.site_use_code     = 'BILL_TO'                   --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
-- Add 2010/01/29 Yasukawa Start
      AND hcsua.status            = 'A'                         --¿æÚqgpÚI.Xe[^X = 'A'
-- Add 2010/01/29 Yasukawa End
      AND hca.cust_account_id     = hcp.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqvt@C.ÚqID
      AND hcp.site_use_id         IS NULL                       --¿æÚqvt@C.gpÚI IS NULL
  )  xxcfr_receipt_cust_account
;
--
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.type                IS '^Cv';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.account_number      IS 'ÚqR[h';
COMMENT ON COLUMN xxcfr_receipt_cust_accounts_v.party_name          IS 'Úq¼';
--
COMMENT ON TABLE  xxcfr_receipt_cust_accounts_v IS 'üàæÚqr[ix¥Êmf[^_E[hpj';
