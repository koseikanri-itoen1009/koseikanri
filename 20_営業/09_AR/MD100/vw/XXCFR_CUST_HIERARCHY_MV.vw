/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCFR_CUST_HIERARCHY_MV
 * Description     : ¿ÚqKw}eACYhr[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010-10-27    1.0   SCS.Hirose      VKì¬
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCFR_CUST_HIERARCHY_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE 
  USING INDEX 
  REFRESH COMPLETE ON DEMAND 
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
  --@üàæÚq¿æÚq|o×æÚq
SELECT temp.cash_account_id     AS cash_account_id    
      ,temp.cash_account_number AS cash_account_number
      ,temp.bill_account_id     AS bill_account_id    
      ,temp.bill_account_number AS bill_account_number
FROM  (
    SELECT bill_hzca_1.cust_account_id         AS cash_account_id         --üàæÚqID        
          ,bill_hzca_1.account_number          AS cash_account_number     --üàæÚqR[h    
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --¿æÚqID        
          ,bill_hzca_1.account_number          AS bill_account_number     --¿æÚqR[h    
    FROM   hz_cust_accounts          bill_hzca_1              --¿æÚq}X^
          ,hz_cust_acct_sites_all    bill_hasa_1              --¿æÚqÝn
          ,hz_cust_site_uses_all     bill_hsua_1              --¿æÚqgpÚI
          ,xxcmm_cust_accounts       bill_hzad_1              --¿æÚqÇÁîñ
          ,hz_party_sites            bill_hzps_1              --¿æp[eBTCg  
          ,hz_locations              bill_hzlo_1              --¿æÚqÆ      
          ,hz_customer_profiles      bill_hzcp_1              --¿æÚqvt@C
          ,hz_cust_accounts          ship_hzca_1              --o×æÚq}X^
          ,hz_cust_acct_sites_all    ship_hasa_1              --o×æÚqÝn
          ,hz_cust_site_uses_all     ship_hsua_1              --o×æÚqgpÚI
          ,xxcmm_cust_accounts       ship_hzad_1              --o×æÚqÇÁîñ
          ,hz_cust_acct_relate_all   bill_hcar_1              --ÚqÖA}X^(¿ÖA)
          ,hr_all_organization_units org_units                --gDPÊ
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --¿æÚq}X^.ÚqID = ÚqÖA}X^.ÚqID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --ÚqÖA}X^.ÖAæÚqID = o×æÚq}X^.ÚqID
    AND    bill_hzca_1.customer_class_code = '14'                            --¿æÚq.Úqæª = '14'(|ÇæÚq)
    AND    bill_hcar_1.status = 'A'                                          --ÚqÖA}X^.Xe[^X = eAf
    AND    bill_hcar_1.attribute1 = '1'                                      --ÚqÖA}X^.ÖAªÞ = e1f (¿)
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --¿æÚq}X^.ÚqID = ÚqÇÁîñ.ÚqID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
    AND    bill_hsua_1.status = 'A'                                          --¿æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --o×æÚq}X^.ÚqID = o×æÚqÝn.ÚqID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --o×æÚqÝn.ÚqÝnID = o×æÚqgpÚI.ÚqÝnID
    AND    ship_hsua_1.status = 'A'                                          --o×æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --o×æÚqgpÚI.¿æÆID = ¿æÚqgpÚI.gpÚIID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --o×æÚq}X^.ÚqID = o×æÚqÇÁîñ.ÚqID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --¿æÚqÝn.p[eBTCgID = ¿æp[eBTCg.p[eBTCgID  
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --¿æp[eBTCg.ÆID = ¿æÚqÆ.ÆID                  
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --¿æÚqgpÚI.gpÚIID = ¿æÚqvt@C.gpÚIID
    AND    bill_hasa_1.org_id = org_units.organization_id
    AND    bill_hsua_1.org_id = org_units.organization_id
    AND    ship_hasa_1.org_id = org_units.organization_id
    AND    ship_hsua_1.org_id = org_units.organization_id
    AND    bill_hcar_1.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    AND NOT EXISTS (
                SELECT 'X'
                FROM   hz_cust_acct_relate_all   cash_hcar_1  --ÚqÖA}X^(üàÖA)
                      ,hr_all_organization_units org_units    --gDPÊ
                WHERE  cash_hcar_1.status = 'A'                                          --ÚqÖA}X^(üàÖA).Xe[^X = eAf
                AND    cash_hcar_1.attribute1 = '2'                                      --ÚqÖA}X^(üàÖA).ÖAªÞ = e2f (üà)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --ÚqÖA}X^(üàÖA).ÖAæÚqID = ¿æÚq}X^.ÚqID
                AND    cash_hcar_1.org_id = org_units.organization_id
                AND    org_units.name = 'SALES-OU'
                     )
    UNION ALL
    --AüàæÚq|¿æÚq|o×æÚq
    SELECT cash_hzca_2.cust_account_id           AS cash_account_id         --üàæÚqID        
          ,cash_hzca_2.account_number            AS cash_account_number     --üàæÚqR[h    
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --¿æÚqID        
          ,bill_hzca_2.account_number            AS bill_account_number     --¿æÚqR[h    
    FROM   hz_cust_accounts          cash_hzca_2              --üàæÚq}X^
          ,hz_cust_acct_sites_all    cash_hasa_2              --üàæÚqÝn
          ,xxcmm_cust_accounts       cash_hzad_2              --üàæÚqÇÁîñ
          ,hz_cust_accounts          bill_hzca_2              --¿æÚq}X^
          ,hz_cust_acct_sites_all    bill_hasa_2              --¿æÚqÝn
          ,hz_cust_site_uses_all     bill_hsua_2              --¿æÚqgpÚI
          ,xxcmm_cust_accounts       bill_hzad_2              --¿æÚqÇÁîñ
          ,hz_party_sites            bill_hzps_2              --¿æp[eBTCg  
          ,hz_locations              bill_hzlo_2              --¿æÚqÆ      
          ,hz_customer_profiles      bill_hzcp_2              --¿æÚqvt@C      
          ,hz_cust_accounts          ship_hzca_2              --o×æÚq}X^
          ,hz_cust_acct_sites_all    ship_hasa_2              --o×æÚqÝn
          ,hz_cust_site_uses_all     ship_hsua_2              --o×æÚqgpÚI
          ,xxcmm_cust_accounts       ship_hzad_2              --o×æÚqÇÁîñ
          ,hz_cust_acct_relate_all   cash_hcar_2              --ÚqÖA}X^(üàÖA)
          ,hz_cust_acct_relate_all   bill_hcar_2              --ÚqÖA}X^(¿ÖA)
          ,hr_all_organization_units org_units                --gDPÊ
    WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --üàæÚq}X^.ÚqID = ÚqÖA}X^(üàÖA).ÚqID
    AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --üàæÚq}X^.ÚqID = üàæÚqÇÁîñ.ÚqID
    AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --ÚqÖA}X^(üàÖA).ÖAæÚqID = ¿æÚq}X^.ÚqID
    AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --¿æÚq}X^.ÚqID = ÚqÖA}X^(¿ÖA).ÚqID
    AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --ÚqÖA}X^(¿ÖA).ÖAæÚqID = o×æÚq}X^.ÚqID
    AND    cash_hzca_2.customer_class_code = '14'                            --¿æÚq.Úqæª = '14'(|ÇæÚq)
    AND    ship_hzca_2.customer_class_code = '10'                            --¿æÚq.Úqæª = '10'(Úq)
    AND    cash_hcar_2.status = 'A'                                          --ÚqÖA}X^(üàÖA).Xe[^X = eAf
    AND    cash_hcar_2.attribute1 = '2'                                      --ÚqÖA}X^(üàÖA).ÖAªÞ = e2f (üà)
    AND    bill_hcar_2.status = 'A'                                          --ÚqÖA}X^(¿ÖA).Xe[^X = eAf
    AND    bill_hcar_2.attribute1 = '1'                                      --ÚqÖA}X^(¿ÖA).ÖAªÞ = e1f (¿)
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --¿æÚq}X^.ÚqID = ÚqÇÁîñ.ÚqID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
    AND    bill_hsua_2.status = 'A'                                          --¿æÚqgpÚI.Xe[^X = 'A'
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --üàæÚq}X^.ÚqID = üàæÚqÝn.ÚqID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --o×æÚq}X^.ÚqID = o×æÚqÇÁîñ.ÚqID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --o×æÚq}X^.ÚqID = o×æÚqÝn.ÚqID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --o×æÚqÝn.ÚqÝnID = o×æÚqgpÚI.ÚqÝnID
    AND    ship_hsua_2.status = 'A'                                          --o×æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --o×æÚqgpÚI.¿æÆID = ¿æÚqgpÚI.gpÚIID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --¿æÚqÝn.p[eBTCgID = ¿æp[eBTCg.p[eBTCgID  
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --¿æp[eBTCg.ÆID = ¿æÚqÆ.ÆID                  
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --¿æÚqgpÚI.gpÚIID = ¿æÚqvt@C.gpÚIID
    AND    cash_hasa_2.org_id = org_units.organization_id
    AND    bill_hasa_2.org_id = org_units.organization_id
    AND    bill_hsua_2.org_id = org_units.organization_id
    AND    ship_hasa_2.org_id = org_units.organization_id
    AND    ship_hsua_2.org_id = org_units.organization_id
    AND    cash_hcar_2.org_id = org_units.organization_id
    AND    bill_hcar_2.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --BüàæÚq|¿æÚqo×æÚq
    SELECT cash_hzca_3.cust_account_id             AS cash_account_id         --üàæÚqID        
          ,cash_hzca_3.account_number              AS cash_account_number     --üàæÚqR[h    
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --¿æÚqID        
          ,ship_hzca_3.account_number              AS bill_account_number     --¿æÚqR[h    
    FROM   hz_cust_accounts          cash_hzca_3              --üàæÚq}X^
          ,hz_cust_acct_sites_all    cash_hasa_3              --üàæÚqÝn
          ,xxcmm_cust_accounts       cash_hzad_3              --üàæÚqÇÁîñ
          ,hz_cust_accounts          ship_hzca_3              --o×æÚq}X^@¦¿æÜÞ
          ,hz_cust_acct_sites_all    bill_hasa_3              --¿æÚqÝn
          ,hz_cust_site_uses_all     bill_hsua_3              --¿æÚqgpÚI
          ,hz_cust_site_uses_all     ship_hsua_3              --o×æÚqgpÚI
          ,xxcmm_cust_accounts       bill_hzad_3              --¿æÚqÇÁîñ
          ,hz_party_sites            bill_hzps_3              --¿æp[eBTCg  
          ,hz_locations              bill_hzlo_3              --¿æÚqÆ      
          ,hz_customer_profiles      bill_hzcp_3              --¿æÚqvt@C 
          ,hz_cust_acct_relate_all   cash_hcar_3              --ÚqÖA}X^(üàÖA)
          ,hr_all_organization_units org_units                --gDPÊ
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --üàæÚq}X^.ÚqID = ÚqÖA}X^(üàÖA).ÚqID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --üàæÚq}X^.ÚqID = üàæÚqÇÁîñ.ÚqID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --ÚqÖA}X^(üàÖA).ÖAæÚqID = o×æÚq}X^.ÚqID
    AND    cash_hzca_3.customer_class_code = '14'                            --üàæÚq.Úqæª = '14'(|ÇæÚq)
    AND    ship_hzca_3.customer_class_code = '10'                            --¿æÚq.Úqæª = '10'(Úq)
    AND    cash_hcar_3.status = 'A'                                          --ÚqÖA}X^(üàÖA).Xe[^X = eAf
    AND    cash_hcar_3.attribute1 = '2'                                      --ÚqÖA}X^(üàÖA).ÖAªÞ = e2f (üà)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_3       --ÚqÖA}X^(¿ÖA)
                     ,hr_all_organization_units   org_units       --gDPÊ
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --ÚqÖA}X^(¿ÖA).ÚqID = o×æÚq}X^.ÚqID
               AND    ex_hcar_3.status = 'A'                                          --ÚqÖA}X^(¿ÖA).Xe[^X = eAf
               AND    ex_hcar_3.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --¿æÚq}X^.ÚqID = ÚqÇÁîñ.ÚqID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = o×æÚqgpÚI.ÚqÝnID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
    AND    bill_hsua_3.status = 'A'                                          --¿æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hsua_3.status = 'A'                                          --o×æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --o×æÚqgpÚI.¿æÆID = ¿æÚqgpÚI.gpÚIID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --üàæÚq}X^.ÚqID = üàæÚqÝn.ÚqID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --¿æÚqÝn.p[eBTCgID = ¿æp[eBTCg.p[eBTCgID  
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --¿æp[eBTCg.ÆID = ¿æÚqÆ.ÆID                  
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --¿æÚqgpÚI.gpÚIID = ¿æÚqvt@C.gpÚIID
    AND    cash_hasa_3.org_id = org_units.organization_id
    AND    bill_hasa_3.org_id = org_units.organization_id
    AND    bill_hsua_3.org_id = org_units.organization_id
    AND    ship_hsua_3.org_id = org_units.organization_id
    AND    cash_hcar_3.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --CüàæÚq¿æÚqo×æÚq
    SELECT ship_hzca_4.cust_account_id               AS cash_account_id         --üàæÚqID        
          ,ship_hzca_4.account_number                AS cash_account_number     --üàæÚqR[h    
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --¿æÚqID        
          ,ship_hzca_4.account_number                AS bill_account_number     --¿æÚqR[h    
    FROM   hz_cust_accounts          ship_hzca_4              --o×æÚq}X^@¦üàæE¿æÜÞ
          ,hz_cust_acct_sites_all    bill_hasa_4              --¿æÚqÝn
          ,hz_cust_site_uses_all     bill_hsua_4              --¿æÚqgpÚI
          ,hz_cust_site_uses_all     ship_hsua_4              --o×æÚqgpÚI
          ,xxcmm_cust_accounts       bill_hzad_4              --¿æÚqÇÁîñ
          ,hz_party_sites            bill_hzps_4              --¿æp[eBTCg  
          ,hz_locations              bill_hzlo_4              --¿æÚqÆ      
          ,hz_customer_profiles      bill_hzcp_4              --¿æÚqvt@C
          ,hr_all_organization_units org_units                --gDPÊ
    WHERE  ship_hzca_4.customer_class_code = '10'             --¿æÚq.Úqæª = '10'(Úq)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_4       --ÚqÖA}X^
                     ,hr_all_organization_units   org_units       --gDPÊ
               WHERE 
                     (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --ÚqÖA}X^(¿ÖA).ÚqID = o×æÚq}X^.ÚqID
               OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --ÚqÖA}X^(¿ÖA).ÖAæÚqID = o×æÚq}X^.ÚqID
               AND    ex_hcar_4.status = 'A'                                            --ÚqÖA}X^(¿ÖA).Xe[^X = eAf
               AND    ex_hcar_4.attribute1 = '2'                                        --ÚqÖA}X^(¿ÖA).ÖAæª = e2f(üà)
               AND    ex_hcar_4.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --¿æÚq}X^.ÚqID = ÚqÇÁîñ.ÚqID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --¿æÚq}X^.ÚqID = ¿æÚqÝn.ÚqID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = ¿æÚqgpÚI.ÚqÝnID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --¿æÚqÝn.ÚqÝnID = o×æÚqgpÚI.ÚqÝnID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --¿æÚqgpÚI.gpÚI = 'BILL_TO'(¿æ)
    AND    bill_hsua_4.status = 'A'                                          --¿æÚqgpÚI.Xe[^X = 'A'
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --o×æÚqgpÚI.¿æÆID = ¿æÚqgpÚI.gpÚIID
    AND    ship_hsua_4.status = 'A'                                          --o×æÚqgpÚI.Xe[^X = 'A'
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --¿æÚqÝn.p[eBTCgID = ¿æp[eBTCg.p[eBTCgID  
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --¿æp[eBTCg.ÆID = ¿æÚqÆ.ÆID                  
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --¿æÚqgpÚI.gpÚIID = ¿æÚqvt@C.gpÚIID
    AND    bill_hasa_4.org_id = org_units.organization_id
    AND    bill_hsua_4.org_id = org_units.organization_id
    AND    ship_hsua_4.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
) temp
GROUP BY temp.cash_account_id       
        ,temp.cash_account_number   
        ,temp.bill_account_id       
        ,temp.bill_account_number   
;
COMMENT ON MATERIALIZED VIEW apps.xxcfr_cust_hierarchy_mv IS '¿ÚqKw}eACYhr['
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_id     IS 'üàæÚqID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_number IS 'üàæÚqÔ'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_id     IS '¿æÚqID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_number IS '¿æÚqÔ'
/
