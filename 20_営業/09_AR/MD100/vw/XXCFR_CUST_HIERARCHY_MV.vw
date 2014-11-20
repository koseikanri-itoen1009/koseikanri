/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCFR_CUST_HIERARCHY_MV
 * Description     : 請求顧客階層マテリアライズドビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010-10-27    1.0   SCS.Hirose      新規作成
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
  --①入金先顧客＆請求先顧客－出荷先顧客
SELECT temp.cash_account_id     AS cash_account_id    
      ,temp.cash_account_number AS cash_account_number
      ,temp.bill_account_id     AS bill_account_id    
      ,temp.bill_account_number AS bill_account_number
FROM  (
    SELECT bill_hzca_1.cust_account_id         AS cash_account_id         --入金先顧客ID        
          ,bill_hzca_1.account_number          AS cash_account_number     --入金先顧客コード    
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --請求先顧客ID        
          ,bill_hzca_1.account_number          AS bill_account_number     --請求先顧客コード    
    FROM   hz_cust_accounts          bill_hzca_1              --請求先顧客マスタ
          ,hz_cust_acct_sites_all    bill_hasa_1              --請求先顧客所在地
          ,hz_cust_site_uses_all     bill_hsua_1              --請求先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_1              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_1              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_1              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_1              --請求先顧客プロファイル
          ,hz_cust_accounts          ship_hzca_1              --出荷先顧客マスタ
          ,hz_cust_acct_sites_all    ship_hasa_1              --出荷先顧客所在地
          ,hz_cust_site_uses_all     ship_hsua_1              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       ship_hzad_1              --出荷先顧客追加情報
          ,hz_cust_acct_relate_all   bill_hcar_1              --顧客関連マスタ(請求関連)
          ,hr_all_organization_units org_units                --組織単位
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    bill_hzca_1.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    bill_hcar_1.status = 'A'                                          --顧客関連マスタ.ステータス = ‘A’
    AND    bill_hcar_1.attribute1 = '1'                                      --顧客関連マスタ.関連分類 = ‘1’ (請求)
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    bill_hsua_1.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    ship_hsua_1.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    AND    bill_hasa_1.org_id = org_units.organization_id
    AND    bill_hsua_1.org_id = org_units.organization_id
    AND    ship_hasa_1.org_id = org_units.organization_id
    AND    ship_hsua_1.org_id = org_units.organization_id
    AND    bill_hcar_1.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    AND NOT EXISTS (
                SELECT 'X'
                FROM   hz_cust_acct_relate_all   cash_hcar_1  --顧客関連マスタ(入金関連)
                      ,hr_all_organization_units org_units    --組織単位
                WHERE  cash_hcar_1.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                AND    cash_hcar_1.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
                AND    cash_hcar_1.org_id = org_units.organization_id
                AND    org_units.name = 'SALES-OU'
                     )
    UNION ALL
    --②入金先顧客－請求先顧客－出荷先顧客
    SELECT cash_hzca_2.cust_account_id           AS cash_account_id         --入金先顧客ID        
          ,cash_hzca_2.account_number            AS cash_account_number     --入金先顧客コード    
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --請求先顧客ID        
          ,bill_hzca_2.account_number            AS bill_account_number     --請求先顧客コード    
    FROM   hz_cust_accounts          cash_hzca_2              --入金先顧客マスタ
          ,hz_cust_acct_sites_all    cash_hasa_2              --入金先顧客所在地
          ,xxcmm_cust_accounts       cash_hzad_2              --入金先顧客追加情報
          ,hz_cust_accounts          bill_hzca_2              --請求先顧客マスタ
          ,hz_cust_acct_sites_all    bill_hasa_2              --請求先顧客所在地
          ,hz_cust_site_uses_all     bill_hsua_2              --請求先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_2              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_2              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_2              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_2              --請求先顧客プロファイル      
          ,hz_cust_accounts          ship_hzca_2              --出荷先顧客マスタ
          ,hz_cust_acct_sites_all    ship_hasa_2              --出荷先顧客所在地
          ,hz_cust_site_uses_all     ship_hsua_2              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       ship_hzad_2              --出荷先顧客追加情報
          ,hz_cust_acct_relate_all   cash_hcar_2              --顧客関連マスタ(入金関連)
          ,hz_cust_acct_relate_all   bill_hcar_2              --顧客関連マスタ(請求関連)
          ,hr_all_organization_units org_units                --組織単位
    WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
    AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
    AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
    AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ(請求関連).顧客ID
    AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    cash_hzca_2.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    ship_hzca_2.customer_class_code = '10'                            --請求先顧客.顧客区分 = '10'(顧客)
    AND    cash_hcar_2.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
    AND    cash_hcar_2.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
    AND    bill_hcar_2.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
    AND    bill_hcar_2.attribute1 = '1'                                      --顧客関連マスタ(請求関連).関連分類 = ‘1’ (請求)
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    bill_hsua_2.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    ship_hsua_2.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    AND    cash_hasa_2.org_id = org_units.organization_id
    AND    bill_hasa_2.org_id = org_units.organization_id
    AND    bill_hsua_2.org_id = org_units.organization_id
    AND    ship_hasa_2.org_id = org_units.organization_id
    AND    ship_hsua_2.org_id = org_units.organization_id
    AND    cash_hcar_2.org_id = org_units.organization_id
    AND    bill_hcar_2.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --③入金先顧客－請求先顧客＆出荷先顧客
    SELECT cash_hzca_3.cust_account_id             AS cash_account_id         --入金先顧客ID        
          ,cash_hzca_3.account_number              AS cash_account_number     --入金先顧客コード    
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --請求先顧客ID        
          ,ship_hzca_3.account_number              AS bill_account_number     --請求先顧客コード    
    FROM   hz_cust_accounts          cash_hzca_3              --入金先顧客マスタ
          ,hz_cust_acct_sites_all    cash_hasa_3              --入金先顧客所在地
          ,xxcmm_cust_accounts       cash_hzad_3              --入金先顧客追加情報
          ,hz_cust_accounts          ship_hzca_3              --出荷先顧客マスタ　※請求先含む
          ,hz_cust_acct_sites_all    bill_hasa_3              --請求先顧客所在地
          ,hz_cust_site_uses_all     bill_hsua_3              --請求先顧客使用目的
          ,hz_cust_site_uses_all     ship_hsua_3              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_3              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_3              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_3              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_3              --請求先顧客プロファイル 
          ,hz_cust_acct_relate_all   cash_hcar_3              --顧客関連マスタ(入金関連)
          ,hr_all_organization_units org_units                --組織単位
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    cash_hzca_3.customer_class_code = '14'                            --入金先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    ship_hzca_3.customer_class_code = '10'                            --請求先顧客.顧客区分 = '10'(顧客)
    AND    cash_hcar_3.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
    AND    cash_hcar_3.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_3       --顧客関連マスタ(請求関連)
                     ,hr_all_organization_units   org_units       --組織単位
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_3.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
               AND    ex_hcar_3.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    bill_hsua_3.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
    AND    ship_hsua_3.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    AND    cash_hasa_3.org_id = org_units.organization_id
    AND    bill_hasa_3.org_id = org_units.organization_id
    AND    bill_hsua_3.org_id = org_units.organization_id
    AND    ship_hsua_3.org_id = org_units.organization_id
    AND    cash_hcar_3.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --④入金先顧客＆請求先顧客＆出荷先顧客
    SELECT ship_hzca_4.cust_account_id               AS cash_account_id         --入金先顧客ID        
          ,ship_hzca_4.account_number                AS cash_account_number     --入金先顧客コード    
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --請求先顧客ID        
          ,ship_hzca_4.account_number                AS bill_account_number     --請求先顧客コード    
    FROM   hz_cust_accounts          ship_hzca_4              --出荷先顧客マスタ　※入金先・請求先含む
          ,hz_cust_acct_sites_all    bill_hasa_4              --請求先顧客所在地
          ,hz_cust_site_uses_all     bill_hsua_4              --請求先顧客使用目的
          ,hz_cust_site_uses_all     ship_hsua_4              --出荷先顧客使用目的
          ,xxcmm_cust_accounts       bill_hzad_4              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_4              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_4              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_4              --請求先顧客プロファイル
          ,hr_all_organization_units org_units                --組織単位
    WHERE  ship_hzca_4.customer_class_code = '10'             --請求先顧客.顧客区分 = '10'(顧客)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_4       --顧客関連マスタ
                     ,hr_all_organization_units   org_units       --組織単位
               WHERE 
                     (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_4.status = 'A'                                            --顧客関連マスタ(請求関連).ステータス = ‘A’
               AND    ex_hcar_4.attribute1 = '2'                                        --顧客関連マスタ(請求関連).関連区分 = ‘2’(入金)
               AND    ex_hcar_4.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
    AND    bill_hsua_4.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    ship_hsua_4.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
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
COMMENT ON MATERIALIZED VIEW apps.xxcfr_cust_hierarchy_mv IS '請求顧客階層マテリアライズドビュー'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_id     IS '入金先顧客ID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_number IS '入金先顧客番号'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_id     IS '請求先顧客ID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_number IS '請求先顧客番号'
/
